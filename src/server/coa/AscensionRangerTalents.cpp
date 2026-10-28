/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionRangerTalents.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
enum RangerTalentSpells : uint32
{
    SPELL_LIGHT_ARROWS = 681292,
    SPELL_HIGHWAYMAN_TRIGGER = 705063,
    SPELL_KNOCKOUT_INCAPACITATE = 706762,
    SPELL_STONEMASONS_SECRET = 524654,
    SPELL_DIRTY_BLADES = 680276,
    SPELL_DIRTY_BLADES_HIT = 520571,
    SPELL_ADVANTAGE = 804329,
    SPELL_EXTEND_DIRTY_BLADES = 524653,
    SPELL_SNATCH = 803115,
    SPELL_SNATCH_DISARM = 803123,
    SPELL_PHOENIX_PLUMES = 705074,
    SPELL_PHOENIX_PLUMES_WAR_FALCON = 520558,
    SPELL_SWIFTSHOT = 705028,
    SPELL_SWIFTSHOT_VULNERABILITY = 800578,
    SPELL_WAR_FALCON_PRESENCE = 680278,
    SPELL_DRAGONHAWK_PRESENCE = 681394,
    SPELL_FRENZY = 520492,
    SPELL_WORN_OUT = 804457,
    SPELL_PILFERING = 705087,
    SPELL_PILFERING_HEAL = 520880,
    SPELL_GUIDANCE = 532261,
    SPELL_BARBED_QUILLS = 800077,
    SPELL_BARBED_QUILLS_BLEED = 801472,
    SPELL_BARBED_QUILLS_SPREAD = 560965,
    SPELL_BARBED_QUILLS_EXTEND = 561161
};

enum RangerTalentRankChains : uint32
{
    CHAIN_SKULLPIERCER = 802036,
    CHAIN_WOODLAND_ARROW = 806368,
    CHAIN_PRECISION_SHOT = 500075
};

enum RangerCompanionEntries : uint32
{
    NPC_WAR_FALCON_FALCONS_CALL = 50264,
    NPC_WAR_FALCON = 50393,
    NPC_DRAGONHAWK = 52393
};

struct WingmanCompanion
{
    uint32 Entry;
    uint32 Presence;
};

constexpr std::array<WingmanCompanion, 3> WingmanCompanions =
{{
    {NPC_WAR_FALCON_FALCONS_CALL, SPELL_WAR_FALCON_PRESENCE},
    {NPC_WAR_FALCON, SPELL_WAR_FALCON_PRESENCE},
    {NPC_DRAGONHAWK, SPELL_DRAGONHAWK_PRESENCE}
}};

constexpr uint8 RANGER_ADVANTAGE_MAX_STACKS = 5;
constexpr int32 WINGMAN_REFRESH_MS = 500;

template <typename Visitor>
void ForEachPresentCompanion(Unit* owner, Visitor&& visit)
{
    for (Unit* controlled : owner->m_Controlled)
    {
        if (!controlled || !controlled->IsAlive() || controlled->GetOwnerGUID() != owner->GetGUID())
            continue;
        for (WingmanCompanion const& companion : WingmanCompanions)
        {
            SpellInfo const* presence = sSpellMgr->GetSpellInfo(companion.Presence);
            if (controlled->GetEntry() == companion.Entry && presence &&
                owner->IsWithinDistInMap(controlled, presence->Effects[EFFECT_0].CalcRadius()))
                visit(presence);
        }
    }
}

class aura_ascension_ranger_barbed_quills : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_barbed_quills);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_BARBED_QUILLS &&
            ValidateSpellInfo({SPELL_BARBED_QUILLS_BLEED, SPELL_BARBED_QUILLS_SPREAD,
                SPELL_BARBED_QUILLS_EXTEND});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* target = event.GetActionTarget();
        SpellInfo const* info = event.GetSpellInfo();
        DamageInfo const* hit = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_RANGER && GetCaster() == owner &&
            event.GetActor() == owner && target && owner->IsValidAttackTarget(target) && hit && hit->GetDamage() &&
            info && info->SpellFamilyName == 27 && (info->SpellFamilyFlags[1] & (256 | 131072 | 4));
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (effect->GetEffIndex() != EFFECT_0)
            return;

        Unit* owner = GetTarget();
        Unit* source = event.GetActionTarget();
        owner->CastSpell(source, SPELL_BARBED_QUILLS_BLEED, true, nullptr, effect);
        if (!(event.GetSpellInfo()->SpellFamilyFlags[1] & 4))
            return;

        SpellInfo const* spread = sSpellMgr->GetSpellInfo(SPELL_BARBED_QUILLS_SPREAD);
        SpellInfo const* extend = sSpellMgr->GetSpellInfo(SPELL_BARBED_QUILLS_EXTEND);
        float const radius = spread->Effects[EFFECT_0].CalcRadius(owner);
        std::list<Unit*> targets;
        Acore::AnyUnitInObjectRangeCheck check(source, radius);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(source, targets, check);
        Cell::VisitObjects(source, search, radius);
        targets.remove_if([owner, source](Unit* unit)
        {
            return unit == source || !unit->IsAlive() || !owner->IsValidAttackTarget(unit) ||
                !source->InSamePhase(unit) || !source->IsWithinLOSInMap(unit);
        });
        targets.sort([source](Unit* first, Unit* second)
        {
            float const firstDistance = source->GetExactDist(first);
            float const secondDistance = source->GetExactDist(second);
            return firstDistance != secondDistance ? firstDistance < secondDistance :
                first->GetGUID() < second->GetGUID();
        });
        if (targets.size() > spread->MaxAffectedTargets)
            targets.resize(spread->MaxAffectedTargets);

        for (auto const& [key, application] : source->GetAppliedAuras())
        {
            Aura* aura = application->GetBase();
            if (aura->GetCasterGUID() != owner->GetGUID() || aura->GetSpellInfo()->SpellFamilyName != 27 ||
                application->IsPositive() || aura->GetDuration() <= 0)
                continue;
            bool periodic = false;
            for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                if (AuraEffect const* original = aura->GetEffect(index); original && original->IsPeriodic())
                    periodic = true;
            if (periodic)
            {
                int32 const duration = int32(std::min<int64>(std::numeric_limits<int32>::max(),
                    int64(aura->GetDuration()) + extend->Effects[EFFECT_0].CalcValue(owner)));
                aura->SetMaxDuration(std::max(aura->GetMaxDuration(), duration));
                aura->SetDuration(duration);
                for (Unit* target : targets)
                    if (Aura* copy = owner->AddAura(aura->GetId(), target))
                    {
                        copy->SetStackAmount(aura->GetStackAmount());
                        copy->SetMaxDuration(aura->GetMaxDuration());
                        copy->SetDuration(duration);
                        for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                            if (AuraEffect const* original = aura->GetEffect(index))
                                if (AuraEffect* copied = copy->GetEffect(index))
                                {
                                    copied->ChangeAmount(original->GetAmount());
                                    copied->SetPeriodicTimer(original->GetPeriodicTimer());
                                    copied->SetCritChance(original->GetCritChance());
                                }
                    }
            }
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ranger_barbed_quills::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_barbed_quills::Proc,
            EFFECT_ALL, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class ranger_wingman_companions : public PlayerScript
{
public:
    ranger_wingman_companions() : PlayerScript("ranger_wingman_companions",
        {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL}) { }

    void OnPlayerAfterGuardianInitStatsForLevel(Player* player, Guardian* guardian) override
    {
        if (!player || player->getClass() != CLASS_RANGER || !IsWingmanCompanion(guardian))
            return;

        CreatureTemplate const* info = guardian->GetCreatureTemplate();
        CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(guardian->GetLevel(), info->unit_class);
        float const damage = stats->GenerateBaseDamage(info);
        for (WeaponAttackType attack : {BASE_ATTACK, OFF_ATTACK, RANGED_ATTACK})
        {
            guardian->SetBaseWeaponDamage(attack, MINDAMAGE, damage);
            guardian->SetBaseWeaponDamage(attack, MAXDAMAGE, damage * 1.5f);
        }
        guardian->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, float(stats->AttackPower));
        guardian->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER_RANGED, BASE_VALUE, float(stats->RangedAttackPower));
        guardian->UpdateAllStats();
    }

    static bool IsWingmanCompanion(Creature const* creature)
    {
        if (!creature)
            return false;

        for (WingmanCompanion const& companion : WingmanCompanions)
            if (creature->GetEntry() == companion.Entry)
                return true;
        return false;
    }
};

bool HasFullAdvantage(Player const* player)
{
    Aura const* advantage = player->GetAura(SPELL_ADVANTAGE);
    return advantage && advantage->GetStackAmount() == RANGER_ADVANTAGE_MAX_STACKS;
}

class spell_ascension_ranger_light_arrows : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_light_arrows);
    int32 _bonus = 0;

    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_RANGER; }

    void Snapshot()
    {
        Unit* target = GetExplTargetUnit();
        if (target && GetCaster()->GetExactDist(target) >= 40.0f)
            if (AuraEffect const* talent = GetCaster()->GetAuraEffect(SPELL_LIGHT_ARROWS, EFFECT_0))
                _bonus = std::max(0, talent->GetAmount());
    }

    void Damage()
    {
        if (_bonus && GetHitDamage() > 0)
            SetHitDamage(int32(std::min<int64>(int64(GetHitDamage()) * (int64(100) + _bonus) / 100,
                std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_ranger_light_arrows::Snapshot);
        OnHit += SpellHitFn(spell_ascension_ranger_light_arrows::Damage);
    }
};

class spell_ascension_ranger_knockout : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_knockout);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_KNOCKOUT_INCAPACITATE}); }
    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_RANGER; }

    void Incapacitate(SpellEffIndex)
    {
        if (Unit* target = GetHitUnit())
            GetCaster()->CastSpell(target, SPELL_KNOCKOUT_INCAPACITATE, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_ranger_knockout::Incapacitate, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

class aura_ascension_ranger_wingman : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_wingman);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_WAR_FALCON_PRESENCE, SPELL_DRAGONHAWK_PRESENCE});
    }

    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        recalculate = true;
        amount = 0;
        ForEachPresentCompanion(GetUnitOwner(), [&amount](SpellInfo const* presence)
        {
            amount += presence->Effects[EFFECT_2].CalcValue();
        });
    }

    void Period(AuraEffect const*, bool& periodic, int32& interval)
    {
        periodic = true;
        interval = WINGMAN_REFRESH_MS;
    }

    void Refresh(AuraEffect const* effect)
    {
        PreventDefaultAction();
        GetAura()->GetEffect(effect->GetEffIndex())->RecalculateAmount();
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_ranger_wingman::Calculate,
            EFFECT_2, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_ranger_wingman::Period,
            EFFECT_2, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ranger_wingman::Refresh,
            EFFECT_2, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN);
    }
};

class aura_ascension_ranger_highwayman : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_highwayman);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_HIGHWAYMAN_TRIGGER});
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* ranger = GetTarget();
        Unit* victim = eventInfo.GetActionTarget();
        return eventInfo.GetActor() == ranger && victim && victim != ranger && eventInfo.GetDamageInfo() &&
            !victim->HasInArc(float(M_PI), ranger);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(eventInfo.GetActionTarget(), SPELL_HIGHWAYMAN_TRIGGER, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ranger_highwayman::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_highwayman::HandleProc, EFFECT_0, SPELL_AURA_ANY);
    }
};

class spell_ascension_ranger_frenzy : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_frenzy);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellEffectInfo const& wornOut = spellInfo->Effects[EFFECT_2];
        return spellInfo->Id == SPELL_FRENZY && wornOut.Effect == SPELL_EFFECT_TRIGGER_SPELL &&
            wornOut.TriggerSpell == SPELL_WORN_OUT && ValidateSpellInfo({SPELL_WORN_OUT});
    }

    void SkipWornOut(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* target)
        {
            Unit* unit = target->ToUnit();
            return !unit || unit->HasAura(SPELL_WORN_OUT);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_ranger_frenzy::SkipWornOut,
            EFFECT_0, TARGET_UNIT_CASTER_AREA_RAID);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_ranger_frenzy::SkipWornOut,
            EFFECT_1, TARGET_UNIT_CASTER_AREA_RAID);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_ranger_frenzy::SkipWornOut,
            EFFECT_2, TARGET_UNIT_CASTER_AREA_RAID);
    }
};

class aura_ascension_ranger_dirty_blades : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_dirty_blades);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo->Id == SPELL_DIRTY_BLADES &&
            spellInfo->Effects[EFFECT_0].IsAura(AuraType(354)) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_DIRTY_BLADES_HIT &&
            ValidateSpellInfo({SPELL_DIRTY_BLADES_HIT});
    }

    bool Load() override
    {
        Unit* ranger = GetUnitOwner();
        return ranger && ranger->IsPlayer() && ranger->getClass() == CLASS_RANGER && GetCaster() == ranger;
    }

    bool CheckProc(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* victim = event.GetActionTarget();
        return event.GetActor() == GetTarget() && victim && GetTarget()->IsValidAttackTarget(victim) &&
            damage && damage->GetDamageType() == DIRECT_DAMAGE &&
            (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) &&
            (event.GetHitMask() & (PROC_HIT_NORMAL | PROC_HIT_CRITICAL | PROC_HIT_ABSORB));
    }

    void Strike(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 const amount = uint64(event.GetDamageInfo()->GetDamage()) *
            uint64(std::max(effect->GetAmount(), 0)) / 100;
        GetTarget()->CastCustomSpell(SPELL_DIRTY_BLADES_HIT, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), event.GetActionTarget(),
            true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ranger_dirty_blades::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_dirty_blades::Strike, EFFECT_0, AuraType(354));
    }
};

class spell_ascension_ranger_dirty_blades : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_dirty_blades);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo->Id == SPELL_DIRTY_BLADES_HIT &&
            ValidateSpellInfo({SPELL_PILFERING, SPELL_PILFERING_HEAL});
    }

    bool Load() override
    {
        Unit* ranger = GetCaster();
        return ranger && ranger->IsPlayer() && ranger->getClass() == CLASS_RANGER;
    }

    void Heal()
    {
        Unit* ranger = GetCaster();
        Unit* victim = GetHitUnit();
        AuraEffect const* pilfering = ranger->GetAuraEffect(SPELL_PILFERING, EFFECT_1);
        if (!pilfering || !victim || ranger->IsFriendlyTo(victim) || GetHitDamage() <= 0)
            return;

        int32 const amount = int32(int64(GetHitDamage()) * std::clamp(pilfering->GetAmount(), 0, 100) / 100);
        if (amount)
            ranger->CastCustomSpell(SPELL_PILFERING_HEAL, SPELLVALUE_BASE_POINT0, amount, ranger,
                true, nullptr, pilfering);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_ranger_dirty_blades::Heal);
    }
};

class aura_ascension_ranger_guidance : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_guidance);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellEffectInfo const& damage = spellInfo->Effects[EFFECT_0];
        return spellInfo->Id == SPELL_GUIDANCE && spellInfo->IsPassive() &&
            damage.IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_DONE) && damage.DieSides == 1 &&
            ValidateSpellInfo({SPELL_WAR_FALCON_PRESENCE, SPELL_DRAGONHAWK_PRESENCE});
    }

    void Calculate(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        amount = 0;
        Unit* owner = GetUnitOwner();
        if (!owner)
            return;

        ForEachPresentCompanion(owner, [&amount](SpellInfo const*) { ++amount; });
    }

    void Period(AuraEffect const*, bool& isPeriodic, int32& timer)
    {
        isPeriodic = true;
        timer = WINGMAN_REFRESH_MS;
    }

    void Refresh(AuraEffect const* effect)
    {
        PreventDefaultAction();
        GetAura()->GetEffect(effect->GetEffIndex())->RecalculateAmount();
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_ranger_guidance::Calculate,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_ranger_guidance::Period,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ranger_guidance::Refresh,
            EFFECT_0, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE);
    }
};

class ranger_swiftshot_hits : public AllSpellScript
{
public:
    ranger_swiftshot_hits() : AllSpellScript("ranger_swiftshot_hits", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || miss != SPELL_MISS_NONE || !damage || !target || target == player || !target->IsAlive() ||
            sSpellMgr->GetFirstSpellInChain(spell->GetSpellInfo()->Id) != CHAIN_PRECISION_SHOT ||
            !player->HasAura(SPELL_SWIFTSHOT))
            return;
        player->CastSpell(target, SPELL_SWIFTSHOT_VULNERABILITY, true);
    }
};
}

void HandleAscensionRangerStonemason(Spell* spell, Player* player)
{
    SpellInfo const* info = spell->GetSpellInfo();
    if (player->getClass() != CLASS_RANGER || info->SpellFamilyName != 27 ||
        !(info->SpellFamilyFlags[1] & (32768 | 134217728)) || !player->HasAura(SPELL_STONEMASONS_SECRET) ||
        !player->HasAura(SPELL_DIRTY_BLADES, player->GetGUID()))
        return;
    if (HasFullAdvantage(player))
        player->CastSpell(player, SPELL_EXTEND_DIRTY_BLADES, true);
}

void HandleAscensionRangerPhoenixPlumes(Spell* spell, Player* player)
{
    uint32 chain = sSpellMgr->GetFirstSpellInChain(spell->GetSpellInfo()->Id);
    if ((chain != CHAIN_SKULLPIERCER && chain != CHAIN_WOODLAND_ARROW) || !player->HasAura(SPELL_PHOENIX_PLUMES) ||
        !HasFullAdvantage(player))
        return;
    if (Unit* target = spell->m_targets.GetUnitTarget())
        player->CastSpell(target, SPELL_PHOENIX_PLUMES_WAR_FALCON, true);
}

void ApplyAscensionRangerTalentContracts(SpellInfo* info)
{
    if (info->Id == SPELL_DIRTY_BLADES_HIT && info->SpellFamilyName == 27)
    {
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AscensionInheritsResolvedAmount = true;
    }
    if (info->Id == SPELL_KNOCKOUT_INCAPACITATE && info->SpellFamilyName == 27)
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    if (info->Id == SPELL_SNATCH_DISARM && info->SpellFamilyName == 27)
        if (SpellInfo const* parent = sSpellMgr->GetSpellInfo(SPELL_SNATCH))
            info->DurationEntry = parent->DurationEntry;
}

void AddSC_AscensionRangerTalents()
{
    RegisterSpellScript(spell_ascension_ranger_light_arrows);
    RegisterSpellScript(spell_ascension_ranger_knockout);
    RegisterSpellScript(aura_ascension_ranger_wingman);
    RegisterSpellScript(aura_ascension_ranger_highwayman);
    RegisterSpellScript(spell_ascension_ranger_frenzy);
    RegisterSpellScript(aura_ascension_ranger_dirty_blades);
    RegisterSpellScript(spell_ascension_ranger_dirty_blades);
    RegisterSpellScript(aura_ascension_ranger_guidance);
    RegisterSpellScript(aura_ascension_ranger_barbed_quills);
    new ranger_wingman_companions();
    new ranger_swiftshot_hits();
}
