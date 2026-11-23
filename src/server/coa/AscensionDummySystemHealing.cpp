/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "CellImpl.h"
#include "Containers.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DynamicObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "GameTime.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <array>
#include <list>
#include <set>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace
{
std::list<Unit*> FriendsNear(WorldObject* center, Unit* caster, float range)
{
    std::list<Unit*> units;
    Acore::AnyFriendlyUnitInObjectRangeCheck check(center, caster, range);
    Acore::UnitListSearcher<Acore::AnyFriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    return units;
}

std::list<Unit*> EnemiesNear(WorldObject* center, Unit* caster, float range)
{
    std::list<Unit*> units;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(center, caster, range);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    return units;
}

bool Named(SpellInfo const* info, std::string_view name)
{
    return info && info->SpellName[LOCALE_enUS] && name == info->SpellName[LOCALE_enUS];
}

Aura* AuraNamed(Unit* unit, std::string_view name, ObjectGuid caster = ObjectGuid::Empty)
{
    for (auto const& [id, application] : unit->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (Named(aura->GetSpellInfo(), name) && (!caster || aura->GetCasterGUID() == caster))
            return aura;
    }
    return nullptr;
}

uint32 HighestKnownRank(Player const* player, uint32 firstRank)
{
    uint32 known = 0;
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(firstRank); rank; rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            known = rank->Id;
    return known;
}

bool IsDirectHeal(ProcEventInfo const& eventInfo)
{
    return eventInfo.GetHealInfo() && eventInfo.GetHealInfo()->GetSpellInfo() &&
        !(eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
}

int32 CustomBasePoints(uint32 spell, int32 amount)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    return amount - (info && info->Effects[EFFECT_0].DieSides ? 1 : 0);
}

constexpr uint32 CLOUDBURST_BUFF = 760010;
constexpr uint32 CLOUDBURST_BUFF_REBORN = 2110010;

uint32 CloudburstBuffOf(uint32 release)
{
    return release == 2110008 ? CLOUDBURST_BUFF_REBORN : CLOUDBURST_BUFF;
}

class spell_dummysystem_healing_cloudburst_release : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_cloudburst_release);

    void HandleRelease(SpellEffIndex )
    {
        if (Unit* caster = GetCaster())
            caster->RemoveAurasDueToSpell(CloudburstBuffOf(GetSpellInfo()->Id), caster->GetGUID());
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummysystem_healing_cloudburst_release::HandleRelease, EFFECT_1,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummysystem_healing_cloudburst_store : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_cloudburst_store);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        HealInfo const* heal = eventInfo.GetHealInfo();
        return heal && heal->GetHeal() && heal->GetSpellInfo() && heal->GetTarget();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        HealInfo const* heal = eventInfo.GetHealInfo();
        Unit* shaman = GetTarget();
        bool const reborn = GetId() == CLOUDBURST_BUFF_REBORN;
        bool const nature = heal->GetSpellInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NATURE;
        bool const periodic = eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC;
        bool const shared = nature && (periodic || heal->GetTarget() == shaman);
        if (shared || (!nature && !reborn) || heal->GetSpellInfo()->Id == 760011 || heal->GetSpellInfo()->Id == 2110011)
            return;
        int32 const pct = reborn && GetSpellInfo()->Effects[EFFECT_2].CalcValue() > 0 ?
            GetSpellInfo()->Effects[EFFECT_2].CalcValue() : 30;
        if (AuraEffect* stored = GetAura()->GetEffect(EFFECT_0))
            stored->ChangeAmount(stored->GetAmount() + int32(CalculatePct(heal->GetHeal(), pct)), false);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_cloudburst_store::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_cloudburst_store::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

constexpr uint32 FLAMETONGUE_ATTACK_FLAG = 0x00200000;
constexpr uint32 WINDFURY_ATTACK_FLAG = 0x00800000;
constexpr uint32 FROSTBRAND_ATTACK_FLAG = 0x01000000;

struct PackSet
{
    uint32 Passive;
    std::array<uint32, 3> Commands;
    std::array<uint32, 3> PetAuras;
};

constexpr std::array<PackSet, 3> PACK_SETS = {{
    { 277190, { 277193, 277194, 277195 }, { 277196, 277197, 277198 } },
    { 984626, { 984629, 984630, 984631 }, { 984632, 984633, 984634 } },
    { 1578906, { 1578909, 277194, 277195 }, { 1578912, 277197, 277198 } },
}};

PackSet const* PackSetOf(uint32 passive)
{
    for (PackSet const& set : PACK_SETS)
        if (set.Passive == passive)
            return &set;
    return nullptr;
}

int32 CommandIndex(SpellInfo const* info)
{
    if (!info || info->SpellFamilyName != SPELLFAMILY_SHAMAN)
        return -1;
    if (info->SpellFamilyFlags[0] & FLAMETONGUE_ATTACK_FLAG)
        return 0;
    if (info->SpellFamilyFlags[0] & FROSTBRAND_ATTACK_FLAG)
        return 1;
    if (info->SpellFamilyFlags[0] & WINDFURY_ATTACK_FLAG)
        return 2;
    return -1;
}

class spell_dummysystem_healing_pack_enhancement : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_pack_enhancement);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && CommandIndex(damage->GetSpellInfo()) >= 0;
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        PackSet const* set = PackSetOf(GetId());
        int32 const index = CommandIndex(eventInfo.GetDamageInfo()->GetSpellInfo());
        if (set && index >= 0)
            GetTarget()->CastSpell(GetTarget(), set->Commands[index], true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_pack_enhancement::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_pack_enhancement::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_healing_pack_feral_spirit : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_pack_feral_spirit);

    std::vector<Creature*> Wolves(Unit* caster)
    {
        std::vector<Creature*> wolves;
        for (SpellEffectInfo const& effect : GetSpellInfo()->Effects)
        {
            if (effect.Effect != SPELL_EFFECT_SUMMON || effect.MiscValue <= 0)
                continue;
            std::list<Creature*> found;
            caster->GetCreatureListWithEntryInGrid(found, uint32(effect.MiscValue), 50.0f);
            for (Creature* wolf : found)
                if (wolf->IsAlive() && wolf->GetOwnerGUID() == caster->GetGUID() &&
                    wolf->GetUInt32Value(UNIT_CREATED_BY_SPELL) == GetSpellInfo()->Id)
                    wolves.push_back(wolf);
        }
        return wolves;
    }

    void Consume()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        std::vector<Creature*> const wolves = Wolves(caster);
        for (PackSet const& set : PACK_SETS)
        {
            if (!caster->HasAura(set.Passive))
                continue;
            for (std::size_t index = 0; index < set.Commands.size(); ++index)
            {
                Aura* command = caster->GetAura(set.Commands[index]);
                if (!command)
                    continue;
                uint8 const stacks = command->GetStackAmount();
                command->Remove();
                for (Creature* wolf : wolves)
                    if (Aura* empowered = caster->AddAura(set.PetAuras[index], wolf))
                        empowered->SetStackAmount(stacks);
            }
        }
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummysystem_healing_pack_feral_spirit::Consume);
    }
};

constexpr uint32 TREE_OF_WRATH_FORM = 86435;
constexpr uint32 LIGHTNING_ROD = 86439;
constexpr uint32 LIGHTNING_BOLT = 403;
constexpr uint32 CHAIN_HEAL = 1064;
constexpr std::array<uint32, 8> LIVING_LIGHTNING = { 86441, 86442, 86443, 86444, 86445, 86446, 86447, 86448 };
constexpr int32 LIVING_LIGHTNING_CDR_MS = 2000;

uint32 LivingLightningFor(Player const* player)
{
    uint8 rank = 0;
    for (SpellInfo const* heal = sSpellMgr->GetSpellInfo(CHAIN_HEAL); heal; heal = heal->GetNextRankSpell())
        if (player->HasSpell(heal->Id))
            rank = heal->GetRank();
    return rank ? LIVING_LIGHTNING[std::min<std::size_t>(rank, LIVING_LIGHTNING.size()) - 1] : 0;
}

class spell_dummysystem_healing_tree_of_wrath : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_tree_of_wrath);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        _granted = LivingLightningFor(player);
        if (_granted && !player->HasSpell(_granted))
            player->learnSpell(_granted, true);
        else
            _granted = 0;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (Player* player = GetTarget()->ToPlayer())
            if (_granted)
                player->removeSpell(_granted, SPEC_MASK_ALL, true);
        _granted = 0;
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_healing_tree_of_wrath::HandleApply, EFFECT_1,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_healing_tree_of_wrath::HandleRemove, EFFECT_1,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }

    uint32 _granted = 0;
};

bool IsLivingLightning(uint32 id)
{
    return std::find(LIVING_LIGHTNING.begin(), LIVING_LIGHTNING.end(), id) != LIVING_LIGHTNING.end();
}

class spell_dummysystem_healing_tree_of_wrath_passive : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_tree_of_wrath_passive);

    static bool IsLightningBoltDamage(ProcEventInfo const& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        SpellInfo const* info = damage ? damage->GetSpellInfo() : nullptr;
        return info && damage->GetDamage() && Named(info, "Lightning Bolt");
    }

    static bool IsCriticalNatureHeal(ProcEventInfo const& eventInfo)
    {
        return IsDirectHeal(eventInfo) && (eventInfo.GetHitMask() & PROC_HIT_CRITICAL) &&
            (eventInfo.GetHealInfo()->GetSpellInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NATURE);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return IsLightningBoltDamage(eventInfo) || IsCriticalNatureHeal(eventInfo);
    }

    void HandleRod(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        if (!IsLightningBoltDamage(eventInfo))
            PreventDefaultAction();
    }

    void HandleCriticalHeal(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (!IsCriticalNatureHeal(eventInfo))
            return;
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->HasAura(TREE_OF_WRATH_FORM))
            return;
        SpellInfo const* heal = eventInfo.GetHealInfo()->GetSpellInfo();

        for (Aura* aura : player->GetSingleCastAuras())
        {
            if (aura->GetId() != LIGHTNING_ROD)
                continue;
            Unit* rod = aura->GetOwner()->ToUnit();
            if (rod && rod->IsAlive() && player->IsValidAttackTarget(rod))
            {
                uint32 const bolt = HighestKnownRank(player, LIGHTNING_BOLT);
                player->CastSpell(rod, bolt ? bolt : LIGHTNING_BOLT, true);
            }
            break;
        }

        if (!IsLivingLightning(heal->Id) &&
            (Named(heal, "Lesser Healing Wave") || Named(heal, "Healing Wave") || Named(heal, "Chain Heal")))
            for (uint32 living : LIVING_LIGHTNING)
                player->ModifySpellCooldown(living, -LIVING_LIGHTNING_CDR_MS);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_tree_of_wrath_passive::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_tree_of_wrath_passive::HandleCriticalHeal, EFFECT_0,
            SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_tree_of_wrath_passive::HandleRod, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_healing_living_lightning_rod : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_living_lightning_rod);

    void HandleDamage(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;
        if (AuraEffect const* rod = target->GetAuraEffect(LIGHTNING_ROD, EFFECT_0, caster->GetGUID()))
            SetHitDamage(GetHitDamage() + int32(CalculatePct(GetHitDamage(), rod->GetAmount())));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_healing_living_lightning_rod::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 FLAMES_OF_THE_APOSTATE = 997000;

class spell_dummysystem_healing_flames_of_the_apostate : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_flames_of_the_apostate);

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        GetAura()->SetDuration(0);
    }

    void Register() override
    {
        AfterEffectProc += AuraEffectProcFn(spell_dummysystem_healing_flames_of_the_apostate::HandleProc, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 DOMINANT_WORD_SHIELD = 81472;
constexpr int32 DOMINANT_HEALTH_PCT = 75;

uint32 DominantShieldOf(uint32 passive)
{
    return passive == DOMINANT_WORD_SHIELD ? 881472 : 1567671;
}

class spell_dummysystem_healing_dominant_word_shield : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_dominant_word_shield);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* target = eventInfo.GetProcTarget();
        return info && target && Named(info, "Power Word: Shield") && target->HealthBelowPct(DOMINANT_HEALTH_PCT);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        AuraEffect const* shield = target->GetAuraEffect(eventInfo.GetSpellInfo()->Id, EFFECT_0, caster->GetGUID());
        if (!shield || shield->GetAmount() <= 0)
            return;
        uint32 const extraSpell = DominantShieldOf(GetId());
        int32 extra = CustomBasePoints(extraSpell, CalculatePct(shield->GetAmount(), aurEff->GetMiscValue()));
        if (extra > 0)
            caster->CastCustomSpell(target, extraSpell, &extra, nullptr, nullptr, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_dominant_word_shield::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_dominant_word_shield::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_healing_dominant_rapture : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_dominant_rapture);

    void HandleEnergize(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        if (caster && caster->HasAura(DOMINANT_WORD_SHIELD))
            SetEffectValue(GetEffectValue() * 2);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_healing_dominant_rapture::HandleEnergize, EFFECT_0,
            SPELL_EFFECT_ENERGIZE);
    }
};

constexpr uint32 ADORNED = 986001;
constexpr uint32 HAND_OF_THE_ADORNED = 986003;
constexpr uint32 ADORNED_SPREAD = 991031;
constexpr float ADORNED_RANGE = 15.0f;
constexpr std::size_t ADORNED_SPREAD_TARGETS = 2;
constexpr std::size_t ADORNED_HOLY_SHOCK_HEALS = 3;

std::vector<Unit*> MostInjuredAllies(Unit* caster, Unit* center, float range, std::size_t count, Unit* exclude)
{
    std::vector<Unit*> allies;
    for (Unit* unit : FriendsNear(center, caster, range))
        if (unit != exclude && unit->IsAlive() && !unit->IsFullHealth() && !unit->IsTotem())
            allies.push_back(unit);
    std::sort(allies.begin(), allies.end(), [](Unit* a, Unit* b) { return a->GetHealthPct() < b->GetHealthPct(); });
    if (allies.size() > count)
        allies.resize(count);
    return allies;
}

class spell_dummysystem_healing_adorned_by_light : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_adorned_by_light);

    static bool IsHolyShock(SpellInfo const* info)
    {
        return Named(info, "Holy Shock");
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info || info->Id == ADORNED || info->Id == ADORNED_SPREAD)
            return false;
        return IsDirectHeal(eventInfo) || (IsHolyShock(info) && eventInfo.GetDamageInfo());
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* target = eventInfo.GetProcTarget();

        bool spread = false;
        if (IsHolyShock(info))
            if (Aura* hand = caster->GetAura(HAND_OF_THE_ADORNED); hand && hand->GetStackAmount() >= hand->GetSpellInfo()->StackAmount)
            {
                hand->Remove();
                spread = true;
                std::vector<Unit*> allies;
                for (Unit* unit : FriendsNear(caster, caster, ADORNED_RANGE))
                    if (unit != caster && unit->IsAlive() && !unit->IsTotem() &&
                        !unit->HasAura(ADORNED, caster->GetGUID()))
                        allies.push_back(unit);
                if (allies.size() > ADORNED_SPREAD_TARGETS)
                    allies.resize(ADORNED_SPREAD_TARGETS);
                for (Unit* ally : allies)
                    caster->AddAura(ADORNED, ally);
            }

        if (!IsDirectHeal(eventInfo) || !target || target == caster)
            return;
        bool const adorned = target->HasAura(ADORNED, caster->GetGUID());
        if (adorned)
            caster->CastSpell(target, ADORNED, true);
        else
            caster->AddAura(ADORNED, target);
        if (!spread)
            caster->CastSpell(caster, HAND_OF_THE_ADORNED, true);
        if (adorned && IsHolyShock(info))
            for (Unit* ally : MostInjuredAllies(caster, target, ADORNED_RANGE, ADORNED_HOLY_SHOCK_HEALS, target))
                caster->CastSpell(ally, ADORNED, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_adorned_by_light::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_adorned_by_light::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

constexpr uint32 BEACON_OF_DIVINITY_HEAL = 986085;
constexpr uint32 BEACON_OF_DIVINITY_CDR = 986087;
constexpr float BEACON_OF_DIVINITY_RANGE = 20.0f;
constexpr std::size_t BEACON_OF_DIVINITY_TARGETS = 5;
constexpr uint32 FAVOR_SPENT_WINDOW_MS = 1000;

struct SpentFavor
{
    uint32 At;
    time_t Applied;
};

constexpr char SpentFavorKey[] = "AscensionDummySystemHealing.SpentFavor";

struct SpentFavorData final : DataMap::Base
{
    SpentFavor Favor{};
};

class spell_dummysystem_healing_beacon_of_divinity : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_beacon_of_divinity);

    static time_t DivineFavor(Unit* caster)
    {
        if (Aura const* favor = AuraNamed(caster, "Divine Favor", caster->GetGUID()))
            return favor->GetApplyTime();
        SpentFavorData const* spent = caster->CustomData.Get<SpentFavorData>(SpentFavorKey);
        if (spent && GameTime::GetGameTimeMS().count() - spent->Favor.At <= FAVOR_SPENT_WINDOW_MS)
            return spent->Favor.Applied;
        return 0;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!IsDirectHeal(eventInfo) || AuraNamed(GetTarget(), "Natural Zeal"))
            return false;
        SpellInfo const* info = eventInfo.GetHealInfo()->GetSpellInfo();
        return info->Id != BEACON_OF_DIVINITY_HEAL && !Named(info, "Beacon of Light");
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        HealInfo const* heal = eventInfo.GetHealInfo();
        SpellInfo const* info = heal->GetSpellInfo();
        Unit* target = heal->GetTarget();

        if (Named(info, "Holy Light") && heal->GetEffectiveHeal())
            caster->m_Events.AddEventAtOffset([caster]() { caster->CastSpell(caster, BEACON_OF_DIVINITY_CDR, true); },
                100ms);

        if (!target || !(info->GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY) || !AuraNamed(target, "Beacon of Light", caster->GetGUID()))
            return;
        time_t const favor = DivineFavor(caster);
        if (!favor || favor == _spentFavor)
            return;
        _spentFavor = favor;
        int32 const amount = int32(CalculatePct(heal->GetHeal(), aurEff->GetAmount()));
        if (amount <= 0)
            return;
        std::vector<Unit*> allies = MostInjuredAllies(caster, target, BEACON_OF_DIVINITY_RANGE, BEACON_OF_DIVINITY_TARGETS,
            target);
        allies.insert(allies.begin(), target);
        SpellInfo const* radiance = sSpellMgr->GetSpellInfo(BEACON_OF_DIVINITY_HEAL);
        if (!radiance)
            return;
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, CustomBasePoints(BEACON_OF_DIVINITY_HEAL, amount));
        for (Unit* ally : allies)
        {
            SpellCastTargets targets;
            targets.SetUnitTarget(ally);
            targets.SetDst(*ally);
            caster->CastSpell(targets, radiance, &values, TRIGGERED_FULL_MASK);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_beacon_of_divinity::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_beacon_of_divinity::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }

    time_t _spentFavor = 0;
};

class spell_dummysystem_healing_divine_favor_spent : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_divine_favor_spent);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE && GetAura()->GetMaxDuration() > 0 &&
            GetAura()->GetDuration() <= 0)
            return;
        GetTarget()->CustomData.GetDefault<SpentFavorData>(SpentFavorKey)->Favor =
            { uint32(GameTime::GetGameTimeMS().count()), GetAura()->GetApplyTime() };
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_healing_divine_favor_spent::HandleRemove, EFFECT_0,
            SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummysystem_healing_beacon_of_divinity_heal : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_beacon_of_divinity_heal);

    void Filter(std::list<WorldObject*>& targets)
    {
        Unit* explicitTarget = GetExplTargetUnit();
        targets.clear();
        if (explicitTarget)
            targets.push_back(explicitTarget);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
            spell_dummysystem_healing_beacon_of_divinity_heal::Filter, EFFECT_0, TARGET_UNIT_DEST_AREA_ALLY);
    }
};

constexpr uint32 CONSECRATION = 26573;
constexpr uint32 CONSECRATION_REBORN = 1126573;
constexpr int32 HOLY_GROUND_RADIATE_PCT = 5;
constexpr std::size_t HOLY_GROUND_RADIATE_TARGETS = 5;
constexpr float HOLY_GROUND_RADIATE_RANGE = 8.0f;

struct HolyGroundRank
{
    uint32 Passive;
    uint32 Standing;
};

constexpr std::array<HolyGroundRank, 3> HOLY_GROUND = {{ { 81315, 983813 }, { 281788, 983813 }, { 1580965, 1580967 } }};

HolyGroundRank const* HolyGroundOf(Unit const* paladin)
{
    for (HolyGroundRank const& rank : HOLY_GROUND)
        if (paladin->HasAura(rank.Passive))
            return &rank;
    return nullptr;
}

class spell_dummysystem_healing_holy_ground : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_holy_ground);

    void HandlePeriodic(AuraEffect const* )
    {
        Unit* paladin = GetTarget();
        uint32 standing = 0;
        for (HolyGroundRank const& rank : HOLY_GROUND)
            if (rank.Passive == GetId())
                standing = rank.Standing;
        if (!standing)
            return;
        for (uint32 first : { CONSECRATION, CONSECRATION_REBORN })
            for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(first); rank; rank = rank->GetNextRankSpell())
                if (DynamicObject* consecration = paladin->GetDynObject(rank->Id))
                    for (Unit* ally : FriendsNear(consecration, paladin, consecration->GetRadius()))
                        if (ally->IsAlive() && !ally->IsTotem())
                            paladin->CastSpell(ally, standing, true);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_healing_holy_ground::HandlePeriodic, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

class AscensionDummySystemHealingUnit : public UnitScript
{
public:
    AscensionDummySystemHealingUnit() : UnitScript("AscensionDummySystemHealingUnit", true,
        { UNITHOOK_MODIFY_HEAL_RECEIVED }) { }

    void ModifyHealReceived(Unit* first, Unit* second, uint32& heal, SpellInfo const* info) override
    {
        if (!first || !second || !info || !heal || _radiating)
            return;
        for (auto [healer, receiver] : { std::pair{ first, second }, std::pair{ second, first } })
        {
            HolyGroundRank const* rank = HolyGroundOf(healer);
            AuraEffect const* standing = rank ? receiver->GetAuraEffect(rank->Standing, EFFECT_0, healer->GetGUID()) :
                nullptr;
            if (!standing)
                continue;
            AddPct(heal, standing->GetAmount());
            if (healer == first && info->HasEffect(SPELL_EFFECT_HEAL))
                Radiate(healer, receiver, *rank, heal);
            return;
        }
    }

private:
    static void Radiate(Unit* paladin, Unit* center, HolyGroundRank const& rank, uint32 heal)
    {
        uint32 const amount = CalculatePct(heal, HOLY_GROUND_RADIATE_PCT);
        SpellInfo const* passive = sSpellMgr->GetSpellInfo(rank.Passive);
        if (!amount || !passive)
            return;
        std::vector<Unit*> allies;
        for (Unit* unit : FriendsNear(center, paladin, HOLY_GROUND_RADIATE_RANGE))
            if (unit != center && unit->IsAlive() && !unit->IsTotem())
                allies.push_back(unit);
        std::sort(allies.begin(), allies.end(),
            [center](Unit* a, Unit* b) { return center->GetExactDist(a) < center->GetExactDist(b); });
        if (allies.size() > HOLY_GROUND_RADIATE_TARGETS)
            allies.resize(HOLY_GROUND_RADIATE_TARGETS);
        _radiating = true;
        for (Unit* ally : allies)
        {
            HealInfo radiated(paladin, ally, amount, passive, SPELL_SCHOOL_MASK_HOLY);
            paladin->HealBySpell(radiated);
        }
        _radiating = false;
    }

    static inline thread_local bool _radiating = false;
};

constexpr std::array<uint32, 2> GUARDIANS_OF_THE_GROVE = { 81467, 270495 };
constexpr std::array<uint32, 2> ROOTS_OF_THE_FOREST = { 81466, 282024 };
constexpr int32 GROVE_HEALTH_REDUCTION_PCT = 66;
constexpr float GROVE_HEAL_THRESHOLD_PCT = 90.0f;
constexpr float GROVE_HEAL_RANGE = 40.0f;
constexpr float ROOTS_SEARCH_RANGE = 30.0f;
constexpr uint32 ENTANGLING_ROOTS_FLAG = 0x00000200;
constexpr std::array<uint32, 6> GROVE_HEALS = { 774, 33763, 48438, 8936, 50464, 5185 };

template <std::size_t N>
bool HasAnyAura(Unit const* unit, std::array<uint32, N> const& spells)
{
    return std::any_of(spells.begin(), spells.end(), [unit](uint32 spell) { return unit->HasAura(spell); });
}

bool RootedBy(Unit const* unit, ObjectGuid druid)
{
    for (AuraEffect const* root : unit->GetAuraEffectsByType(SPELL_AURA_MOD_ROOT))
        if (root->GetCasterGUID() == druid && root->GetSpellInfo()->SpellFamilyName == SPELLFAMILY_DRUID &&
            (root->GetSpellInfo()->SpellFamilyFlags[0] & ENTANGLING_ROOTS_FLAG))
            return true;
    return false;
}

class TreantBrain : public BasicEvent
{
public:
    TreantBrain(Creature* treant, ObjectGuid owner, bool healer) : _treant(treant), _owner(owner), _healer(healer) { }

    bool Execute(uint64 , uint32 ) override
    {
        if (!_treant->IsAlive() || !_treant->IsInWorld())
            return true;
        Player* owner = ObjectAccessor::GetPlayer(*_treant, _owner);
        if (owner)
        {
            if (_healer)
                Heal(owner);
            else if (HasAnyAura(owner, ROOTS_OF_THE_FOREST))
                PreferRooted(owner);
        }
        _treant->m_Events.AddEventAtOffset(this, 1s);
        return false;
    }

private:
    void Heal(Player* owner)
    {
        if (_treant->GetVictim())
            _treant->AttackStop();
        if (_treant->HasUnitState(UNIT_STATE_CASTING))
            return;
        Unit* patient = nullptr;
        for (Unit* unit : FriendsNear(_treant, owner, GROVE_HEAL_RANGE))
        {
            Unit* controller = unit->GetCharmerOrOwnerOrSelf();
            if (!unit->IsAlive() || unit->IsTotem() || unit->GetHealthPct() >= GROVE_HEAL_THRESHOLD_PCT ||
                !controller || !(controller == owner || controller->IsInRaidWith(owner)))
                continue;
            if (!patient || unit->GetHealthPct() < patient->GetHealthPct())
                patient = unit;
        }
        if (!patient)
            return;
        bool const instantOnly = _treant->GetMap()->IsBattlegroundOrArena();
        for (uint32 first : GROVE_HEALS)
        {
            uint32 const spell = HighestKnownRank(owner, first);
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            if (!info || (instantOnly && info->CalcCastTime()) || patient->HasAura(spell, _treant->GetGUID()))
                continue;
            _treant->CastSpell(patient, spell, TriggerCastFlags(TRIGGERED_IGNORE_POWER_AND_REAGENT_COST |
                TRIGGERED_IGNORE_GCD | TRIGGERED_IGNORE_SHAPESHIFT));
            return;
        }
    }

    void PreferRooted(Player* owner)
    {
        Unit* victim = _treant->GetVictim();
        if (!victim || RootedBy(victim, owner->GetGUID()) || !_treant->AI())
            return;
        Unit* rooted = nullptr;
        for (Unit* enemy : EnemiesNear(_treant, owner, ROOTS_SEARCH_RANGE))
            if (enemy->IsAlive() && RootedBy(enemy, owner->GetGUID()) && _treant->IsValidAttackTarget(enemy) &&
                (!rooted || _treant->GetExactDist(enemy) < _treant->GetExactDist(rooted)))
                rooted = enemy;
        if (rooted)
            _treant->AI()->AttackStart(rooted);
    }

    Creature* _treant;
    ObjectGuid _owner;
    bool _healer;
};

class spell_dummysystem_healing_force_of_nature : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_force_of_nature);

    std::vector<Creature*> Treants(Unit* caster)
    {
        std::vector<Creature*> treants;
        for (SpellEffectInfo const& effect : GetSpellInfo()->Effects)
        {
            if (effect.Effect != SPELL_EFFECT_SUMMON || effect.MiscValue <= 0)
                continue;
            std::list<Creature*> found;
            caster->GetCreatureListWithEntryInGrid(found, uint32(effect.MiscValue), 50.0f);
            for (Creature* treant : found)
                if (treant->IsAlive() && treant->GetOwnerGUID() == caster->GetGUID())
                    treants.push_back(treant);
        }
        return treants;
    }

    void Remember()
    {
        if (Unit* caster = GetCaster())
            for (Creature* treant : Treants(caster))
                _before.insert(treant->GetGUID());
    }

    void Empower()
    {
        Player* owner = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!owner)
            return;
        bool const healer = HasAnyAura(owner, GUARDIANS_OF_THE_GROVE);
        if (!healer && !HasAnyAura(owner, ROOTS_OF_THE_FOREST))
            return;
        for (Creature* treant : Treants(owner))
        {
            if (_before.count(treant->GetGUID()))
                continue;
            if (healer)
            {
                treant->ApplyStatPctModifier(UNIT_MOD_HEALTH, TOTAL_PCT, float(-GROVE_HEALTH_REDUCTION_PCT));
                treant->UpdateMaxHealth();
                treant->SetHealth(treant->GetMaxHealth());
                treant->SetReactState(REACT_PASSIVE);
                treant->AttackStop();
            }
            treant->m_Events.AddEventAtOffset(new TreantBrain(treant, owner->GetGUID(), healer), 500ms);
        }
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_dummysystem_healing_force_of_nature::Remember);
        AfterCast += SpellCastFn(spell_dummysystem_healing_force_of_nature::Empower);
    }

    std::set<ObjectGuid> _before;
};

enum class Element : uint8 { Fire, Water, Air, Earth, Other };

constexpr std::array<uint32, 5> POWER_OF_THE_ELEMENTS = { 423785, 423822, 423823, 423824, 423825 };
constexpr std::array<uint32, 5> ELEMENT_AURA_BASE = { 420100, 420110, 420120, 420130, 420140 };
constexpr std::array<uint32, 6> FIRE_FAMILIES = { 303, 315, 320, 328, 335, 342 };
constexpr std::array<uint32, 6> WATER_FAMILIES = { 304, 316, 321, 329, 336, 343 };
constexpr std::array<uint32, 6> AIR_FAMILIES = { 301, 313, 317, 326, 333, 340 };
constexpr std::array<uint32, 6> EARTH_FAMILIES = { 302, 314, 318, 327, 334, 341 };

Pet* TetheredElemental(Unit* shaman)
{
    Player* player = shaman->ToPlayer();
    Pet* pet = player ? player->GetPet() : nullptr;
    if (!pet || !pet->IsAlive() || pet->getPetType() != HUNTER_PET || pet->GetCreatureType() != CREATURE_TYPE_ELEMENTAL)
        return nullptr;
    return pet;
}

Element ElementOf(Pet const* pet)
{
    uint32 const family = pet->GetCreatureTemplate()->family;
    auto in = [family](auto const& families) { return std::find(families.begin(), families.end(), family) != families.end(); };
    if (in(FIRE_FAMILIES))
        return Element::Fire;
    if (in(WATER_FAMILIES))
        return Element::Water;
    if (in(AIR_FAMILIES))
        return Element::Air;
    if (in(EARTH_FAMILIES))
        return Element::Earth;
    return Element::Other;
}

class spell_dummysystem_healing_power_of_the_elements : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_power_of_the_elements);

    uint32 RankIndex() const
    {
        auto const itr = std::find(POWER_OF_THE_ELEMENTS.begin(), POWER_OF_THE_ELEMENTS.end(), GetId());
        return uint32(itr - POWER_OF_THE_ELEMENTS.begin());
    }

    void Sync(bool active)
    {
        Unit* shaman = GetTarget();
        uint32 wanted = 0;
        if (active)
            if (Pet* pet = TetheredElemental(shaman))
                wanted = ELEMENT_AURA_BASE[uint8(ElementOf(pet))] + RankIndex();
        Pet* pet = TetheredElemental(shaman);
        for (uint32 base : ELEMENT_AURA_BASE)
            if (base + RankIndex() != wanted)
            {
                shaman->RemoveAurasDueToSpell(base + RankIndex(), shaman->GetGUID());
                if (pet)
                    pet->RemoveAurasDueToSpell(base + RankIndex(), shaman->GetGUID());
            }
        if (wanted && !shaman->HasAura(wanted, shaman->GetGUID()))
            shaman->CastSpell(shaman, wanted, true);
        if (wanted && pet && !pet->HasAura(wanted, shaman->GetGUID()))
            shaman->AddAura(wanted, pet);
    }

    void HandlePeriodic(AuraEffect const* )
    {
        Sync(true);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Sync(false);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_healing_power_of_the_elements::HandlePeriodic, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_healing_power_of_the_elements::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 ELEMENTAL_LORD = 990200;
constexpr std::array<uint32, 3> ELEMENTAL_LORD_EMPOWERMENTS = { 990201, 990202, 990203 };
constexpr uint32 SHOCK_FLAGS = 0x00100000 | 0x10000000 | 0x80000000;

class spell_dummysystem_healing_elemental_lord : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_elemental_lord);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && eventInfo.GetDamageInfo() && (eventInfo.GetHitMask() & PROC_HIT_CRITICAL) &&
            (Named(info, "Elemental Blast") || Named(info, "Lava Burst"));
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        std::vector<uint32> shocks;
        for (auto const& [spell, cooldown] : player->GetSpellCooldownMap())
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(spell))
                if (info->SpellFamilyName == SPELLFAMILY_SHAMAN && (info->SpellFamilyFlags[0] & SHOCK_FLAGS))
                    shocks.push_back(spell);
        for (uint32 shock : shocks)
            player->RemoveSpellCooldown(shock, true);
        if (TetheredElemental(player))
            player->CastSpell(player, Acore::Containers::SelectRandomContainerElement(ELEMENTAL_LORD_EMPOWERMENTS), true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_elemental_lord::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_elemental_lord::HandleProc, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_healing_elemental_blast : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_elemental_blast);

    void HandleEmpowerment(SpellEffIndex effIndex)
    {
        if (GetCaster() && GetCaster()->HasAura(ELEMENTAL_LORD))
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_healing_elemental_blast::HandleEmpowerment, EFFECT_1,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_healing_elemental_blast::HandleEmpowerment, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
    }
};

constexpr uint32 PENITENT_BLESSING = 272888;
constexpr float PENITENT_BLESSING_RANGE = 8.0f;
constexpr std::size_t PENITENT_BLESSING_TARGETS = 5;
constexpr uint8 PENANCE_BOLTS = 3;

class spell_dummysystem_healing_divine_guidance : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_divine_guidance);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return IsDirectHeal(eventInfo) && Named(eventInfo.GetHealInfo()->GetSpellInfo(), "Penance");
    }

    void HandleRadiate(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* priest = GetTarget();
        Unit* bolt = eventInfo.GetHealInfo()->GetTarget();
        if (!bolt)
            return;
        std::vector<Unit*> allies;
        for (Unit* unit : FriendsNear(bolt, priest, PENITENT_BLESSING_RANGE))
            if (unit != bolt && unit->IsAlive() && !unit->IsTotem())
                allies.push_back(unit);
        std::sort(allies.begin(), allies.end(),
            [bolt](Unit* a, Unit* b) { return bolt->GetExactDist(a) < bolt->GetExactDist(b); });
        if (allies.size() > PENITENT_BLESSING_TARGETS)
            allies.resize(PENITENT_BLESSING_TARGETS);
        for (Unit* ally : allies)
            priest->CastSpell(ally, PENITENT_BLESSING, true);
    }

    void HandleSpent(AuraEffect const* , ProcEventInfo& )
    {
        if (++_bolts >= PENANCE_BOLTS)
            GetAura()->SetDuration(0);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_healing_divine_guidance::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_healing_divine_guidance::HandleRadiate, EFFECT_1,
            SPELL_AURA_DUMMY);
        AfterEffectProc += AuraEffectProcFn(spell_dummysystem_healing_divine_guidance::HandleSpent, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }

    uint8 _bolts = 0;
};

constexpr std::array<uint32, 2> TENTACLES_OF_THE_OLD_GODS = { 965447, 50272 };
constexpr float TENTACLE_CONTROL_RANGE = 100.0f;
constexpr float TENTACLE_NEARBY_RANGE = 30.0f;
constexpr std::array<uint32, 3> FORBIDDEN_POWER = { 272963, 986245, 1571332 };

struct GraspSet
{
    uint32 Power;
    float Range;
};

GraspSet GraspSetOf(uint32 channel)
{
    if (channel == 986248)
        return { 986245, TENTACLE_NEARBY_RANGE };
    if (channel == 1571356)
        return { 1571332, TENTACLE_CONTROL_RANGE };
    return { 272963, TENTACLE_CONTROL_RANGE };
}

uint8 TentaclesOf(Unit* priest, float range)
{
    uint32 count = 0;
    for (uint32 entry : TENTACLES_OF_THE_OLD_GODS)
    {
        std::list<Creature*> tentacles;
        priest->GetCreatureListWithEntryInGrid(tentacles, entry, range);
        for (Creature* tentacle : tentacles)
            if (tentacle->IsAlive() && (tentacle->GetOwnerGUID() == priest->GetGUID() ||
                tentacle->GetCreatorGUID() == priest->GetGUID() ||
                (tentacle->IsSummon() && tentacle->ToTempSummon()->GetSummonerGUID() == priest->GetGUID())))
                ++count;
    }
    return uint8(std::min<uint32>(count, 255));
}

void EmpowerGrasp(Unit* priest, GraspSet const& set)
{
    uint8 const tentacles = TentaclesOf(priest, set.Range);
    if (!tentacles)
    {
        priest->RemoveAurasDueToSpell(set.Power, priest->GetGUID());
        return;
    }
    Aura* power = priest->GetAura(set.Power, priest->GetGUID());
    if (!power)
        power = priest->AddAura(set.Power, priest);
    if (power)
    {
        power->SetStackAmount(uint8(std::min<uint32>(tentacles, std::max<uint32>(power->GetSpellInfo()->StackAmount, 1))));
        power->RefreshDuration();
    }
}

class spell_dummysystem_healing_grasp_channel : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_healing_grasp_channel);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        if (Unit* priest = GetCaster())
            EmpowerGrasp(priest, GraspSetOf(GetId()));
    }

    void HandleTick(AuraEffect const* )
    {
        if (Unit* priest = GetCaster())
            EmpowerGrasp(priest, GraspSetOf(GetId()));
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (Unit* priest = GetCaster())
            priest->RemoveAurasDueToSpell(GraspSetOf(GetId()).Power, priest->GetGUID());
    }

    void Register() override
    {
        if (m_scriptSpellId == 1571356)
        {
            AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_healing_grasp_channel::HandleApply, EFFECT_0,
                SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_healing_grasp_channel::HandleRemove, EFFECT_0,
                SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
            return;
        }
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_healing_grasp_channel::HandleApply, EFFECT_1,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_healing_grasp_channel::HandleTick, EFFECT_2,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_healing_grasp_channel::HandleRemove, EFFECT_1,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummysystem_healing_grasp_tick : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_healing_grasp_tick);

    void HandleDamage(SpellEffIndex )
    {
        Unit* priest = GetCaster();
        if (!priest)
            return;
        for (uint32 power : FORBIDDEN_POWER)
            if (AuraEffect const* bonus = priest->GetAuraEffect(power, EFFECT_0, priest->GetGUID()))
            {
                int32 damage = GetHitDamage();
                AddPct(damage, bonus->GetAmount());
                SetHitDamage(damage);
                return;
            }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_healing_grasp_tick::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
}

void ApplyAscensionDummySystemHealingContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 86438:
        {
            SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
            if (effect.ApplyAuraName == SPELL_AURA_DUMMY && effect.MiscValue == 33891)
            {
                effect.ApplyAuraName = SPELL_AURA_ASCENSION_OVERRIDE_SPELL;
                effect.BasePoints = int32(TREE_OF_WRATH_FORM);
                effect.MiscValueB = 0;
                effect.DieSides = 0;
                effect.RealPointsPerLevel = 0.0f;
                effect.PointsPerComboPoint = 0.0f;
            }
            break;
        }
        case LIGHTNING_ROD:
            spellInfo->AttributesEx5 |= SPELL_ATTR5_LIMIT_N;
            break;
        case 997007:
            if (!spellInfo->DurationEntry || !spellInfo->GetDuration())
                spellInfo->DurationEntry = sSpellDurationStore.LookupEntry(105);
            break;
        case BEACON_OF_DIVINITY_HEAL:
            spellInfo->MaxAffectedTargets = 0;
            break;
        case 81315:
        case 281788:
        case 1580965:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 1000;
            }
            break;
        case 983813:
        case 1580967:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_HEALING_RECEIVED)
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            spellInfo->ProcCharges = 0;
            break;
        case 423785:
        case 423822:
        case 423823:
        case 423824:
        case 423825:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 1000;
            }
            break;
        case 272885:
            if (!spellInfo->Effects[EFFECT_0].SpellClassMask)
                spellInfo->Effects[EFFECT_0].SpellClassMask = flag96(0, 0x00010000, 0);
            spellInfo->ProcCharges = 0;
            break;
        case 272963:
            spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_CRIT_DAMAGE_BONUS;
            spellInfo->Effects[EFFECT_1].MiscValue = SPELL_SCHOOL_MASK_SHADOW;
            break;
        case 986245:
        case 1571332:
            spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_SPELL_CRIT_CHANCE_SCHOOL;
            spellInfo->Effects[EFFECT_1].MiscValue = SPELL_SCHOOL_MASK_SHADOW;
            break;
        default:
            break;
    }
}

void AddAscensionDummySystemHealingScripts()
{
    RegisterSpellScript(spell_dummysystem_healing_cloudburst_release);
    RegisterSpellScript(spell_dummysystem_healing_cloudburst_store);
    RegisterSpellScript(spell_dummysystem_healing_pack_enhancement);
    RegisterSpellScript(spell_dummysystem_healing_pack_feral_spirit);
    RegisterSpellScript(spell_dummysystem_healing_tree_of_wrath);
    RegisterSpellScript(spell_dummysystem_healing_tree_of_wrath_passive);
    RegisterSpellScript(spell_dummysystem_healing_living_lightning_rod);
    RegisterSpellScript(spell_dummysystem_healing_flames_of_the_apostate);
    RegisterSpellScript(spell_dummysystem_healing_dominant_word_shield);
    RegisterSpellScript(spell_dummysystem_healing_dominant_rapture);
    RegisterSpellScript(spell_dummysystem_healing_adorned_by_light);
    RegisterSpellScript(spell_dummysystem_healing_beacon_of_divinity);
    RegisterSpellScript(spell_dummysystem_healing_beacon_of_divinity_heal);
    RegisterSpellScript(spell_dummysystem_healing_divine_favor_spent);
    RegisterSpellScript(spell_dummysystem_healing_holy_ground);
    RegisterSpellScript(spell_dummysystem_healing_force_of_nature);
    RegisterSpellScript(spell_dummysystem_healing_power_of_the_elements);
    RegisterSpellScript(spell_dummysystem_healing_elemental_lord);
    RegisterSpellScript(spell_dummysystem_healing_elemental_blast);
    RegisterSpellScript(spell_dummysystem_healing_divine_guidance);
    RegisterSpellScript(spell_dummysystem_healing_grasp_channel);
    RegisterSpellScript(spell_dummysystem_healing_grasp_tick);
    new AscensionDummySystemHealingUnit();
}
