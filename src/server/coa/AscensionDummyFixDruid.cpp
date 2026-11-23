/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <list>

namespace
{
constexpr uint32 DRUID_HEALING_TOUCH_FLAG = 0x00000020;
constexpr uint32 DRUID_RAKE_FLAG = 0x00001000;
constexpr uint32 DRUID_RIP_FLAG = 0x00800000;

std::list<Unit*> GroupedNear(WorldObject* center, Unit* member, float range)
{
    std::list<Unit*> units;
    Acore::AnyGroupedUnitInObjectRangeCheck check(center, member, range, true);
    Acore::UnitListSearcher<Acore::AnyGroupedUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    return units;
}

std::list<Unit*> FriendsNear(WorldObject* center, Unit* caster, float range)
{
    std::list<Unit*> units;
    Acore::AnyFriendlyUnitInObjectRangeCheck check(center, caster, range);
    Acore::UnitListSearcher<Acore::AnyFriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    return units;
}

struct OverflowRule
{
    uint32 Aura;
    float Range;
    bool HealingTouchOnly;
};

constexpr std::array<OverflowRule, 2> OVERFLOWS = {{
    { 273415, 8.0f, false },
    { 977710, 12.0f, true },
}};
constexpr uint32 OVERFLOW_HEAL = 954283;

OverflowRule const* OverflowByAura(uint32 id)
{
    for (OverflowRule const& rule : OVERFLOWS)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_druid_overflow : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_overflow);

    bool Validate(SpellInfo const* info) override
    {
        return OverflowByAura(info->Id) && ValidateSpellInfo({ OVERFLOW_HEAL });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        OverflowRule const* rule = OverflowByAura(GetId());
        HealInfo* heal = eventInfo.GetHealInfo();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!rule || !heal || !heal->GetHeal() || !info || info->Id == OVERFLOW_HEAL || !eventInfo.GetProcTarget())
            return false;
        if ((eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) || !(info->GetSchoolMask() & SPELL_SCHOOL_MASK_NATURE))
            return false;
        if (rule->HealingTouchOnly)
            return info->SpellFamilyName == SPELLFAMILY_DRUID && (info->SpellFamilyFlags[0] & DRUID_HEALING_TOUCH_FLAG);
        return info->CastTimeEntry && info->CastTimeEntry->CastTime > 0;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        OverflowRule const* rule = OverflowByAura(GetId());
        Unit* healer = GetTarget();
        Unit* healed = eventInfo.GetProcTarget();
        HealInfo* heal = eventInfo.GetHealInfo();
        SpellInfo const* overflow = sSpellMgr->GetSpellInfo(OVERFLOW_HEAL);
        if (!rule || !healed || !heal || !overflow)
            return;
        std::list<Unit*> members = GroupedNear(healed, healer, rule->Range);
        members.remove_if([healed](Unit* unit) { return unit == healed || !unit->IsAlive(); });
        if (members.empty())
            return;
        Unit* extra = *std::min_element(members.begin(), members.end(),
            [](Unit* a, Unit* b) { return a->GetHealthPct() < b->GetHealthPct(); });
        int32 amount = int32(CalculatePct(heal->GetHeal(), aurEff->GetAmount())) -
            (overflow->Effects[EFFECT_0].DieSides ? 1 : 0);
        if (amount <= 0)
            return;
        healer->CastCustomSpell(extra, OVERFLOW_HEAL, &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_overflow::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_overflow::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 LIVING_SEED = 48504;
constexpr uint32 LIVING_SEED_HEAL = 48503;

struct GardenRule
{
    uint32 Aura;
    uint8 Stacks;
    float Range;
};

constexpr std::array<GardenRule, 2> GARDENS = {{
    { 84376, 3, 20.0f },
    { 282189, 2, 30.0f },
}};

GardenRule const* GardenByAura(uint32 id)
{
    for (GardenRule const& rule : GARDENS)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_druid_garden_of_growth : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_garden_of_growth);

    bool _bloomed = false;

    bool Validate(SpellInfo const* info) override
    {
        return GardenByAura(info->Id) && ValidateSpellInfo({ LIVING_SEED, LIVING_SEED_HEAL });
    }

    void HandleStacks(AuraEffect const* , AuraEffectHandleModes )
    {
        GardenRule const* rule = GardenByAura(GetId());
        if (!rule)
            return;
        if (GetStackAmount() < rule->Stacks)
        {
            _bloomed = false;
            return;
        }
        if (_bloomed)
            return;
        _bloomed = true;
        Unit* carrier = GetTarget();
        Unit* druid = GetCaster();
        if (!druid)
            return;
        ObjectGuid const druidGuid = druid->GetGUID();
        std::list<Unit*> units = FriendsNear(carrier, druid, rule->Range);
        if (std::find(units.begin(), units.end(), carrier) == units.end())
            units.push_back(carrier);
        for (Unit* unit : units)
        {
            if (!unit->IsAlive())
                continue;
            AuraEffect const* seed = unit->GetAuraEffect(LIVING_SEED, EFFECT_0, druidGuid);
            if (!seed || seed->GetAmount() <= 0)
                continue;
            unit->CastCustomSpell(LIVING_SEED_HEAL, SPELLVALUE_BASE_POINT0, seed->GetAmount(), unit, true, nullptr, seed,
                druidGuid);
        }
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_druid_garden_of_growth::HandleStacks, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

constexpr uint32 FURY_OF_THE_KING_STACKS = 278661;
constexpr uint32 FURY_OF_THE_KING_DAMAGE = 278662;
constexpr int32 FURY_OF_THE_KING_PLAYER_PCT = 25;

class spell_dummyfix_druid_fury_of_the_king : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_fury_of_the_king);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FURY_OF_THE_KING_STACKS, FURY_OF_THE_KING_DAMAGE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* target = eventInfo.GetProcTarget();
        if (!damage || !damage->GetDamage() || !info || !target || !target->IsAlive())
            return false;
        if (info->SpellFamilyName != SPELLFAMILY_DRUID || !(info->SpellFamilyFlags[0] & (DRUID_RAKE_FLAG | DRUID_RIP_FLAG)) ||
            info->GetSchoolMask() != SPELL_SCHOOL_MASK_NORMAL)
            return false;
        Aura const* stacks = GetTarget()->GetAura(FURY_OF_THE_KING_STACKS, GetTarget()->GetGUID());
        SpellInfo const* stackInfo = sSpellMgr->GetSpellInfo(FURY_OF_THE_KING_STACKS);
        if (!stacks || !stackInfo)
            return false;
        float const chance = float(stackInfo->Effects[EFFECT_2].CalcValue()) * stacks->GetStackAmount();
        return roll_chance_f(chance);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = eventInfo.GetProcTarget();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        SpellInfo const* extra = sSpellMgr->GetSpellInfo(FURY_OF_THE_KING_DAMAGE);
        if (!target || !damage || !extra)
            return;
        int32 const pct = target->IsControlledByPlayer() ? FURY_OF_THE_KING_PLAYER_PCT : aurEff->GetAmount();
        int32 amount = int32(CalculatePct(damage->GetDamage(), pct)) - (extra->Effects[EFFECT_0].DieSides ? 1 : 0);
        if (amount <= 0)
            return;
        GetTarget()->CastCustomSpell(target, FURY_OF_THE_KING_DAMAGE, &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_fury_of_the_king::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_fury_of_the_king::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr std::array<uint32, 2> WORGEN_FORMS = { 275737, 982807 };

class spell_dummyfix_druid_goldrinns_guile : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_goldrinns_guile);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ info->Effects[EFFECT_0].TriggerSpell });
    }

    bool InWorgenForm() const
    {
        Unit* owner = GetTarget();
        return std::any_of(WORGEN_FORMS.begin(), WORGEN_FORMS.end(), [owner](uint32 form) { return owner->HasAura(form); });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Player* player = GetTarget()->ToPlayer();
        if (!info || !player || !info->NeedsComboPoints())
            return false;
        uint8 const points = player->GetComboPoints();
        if (!points)
            return false;
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[InWorgenForm() ? EFFECT_1 : EFFECT_0];
        return roll_chance_f(effect.PointsPerComboPoint * points);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), GetSpellInfo()->Effects[EFFECT_0].TriggerSpell, true, nullptr, aurEff);
    }

    void PreventSecond(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_goldrinns_guile::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_goldrinns_guile::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_goldrinns_guile::PreventSecond, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 NATURES_FERVOR = 272293;

class spell_dummyfix_druid_natures_fervor : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_natures_fervor);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ NATURES_FERVOR });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* target = eventInfo.GetProcTarget();
        if (!info || !target)
            return false;
        Aura const* lacerate = target->GetAura(info->Id, GetTarget()->GetGUID());
        return lacerate && info->StackAmount > 1 && lacerate->GetStackAmount() >= info->StackAmount;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), NATURES_FERVOR, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_natures_fervor::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_natures_fervor::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct EclipseBuff
{
    uint32 Eclipse;
    uint32 Talent;
    uint32 Buff;
    bool EndsWithEclipse;
};

constexpr uint32 OWLKIN_FRENZY = 48391;
constexpr std::array<EclipseBuff, 5> ECLIPSE_BUFFS = {{
    { 48517, 271680, 271675, true },
    { 48517, 272256, 272251, true },
    { 48518, 272255, 272250, true },
    { 48517, 272247, OWLKIN_FRENZY, false },
    { 48518, 272247, OWLKIN_FRENZY, false },
}};

class spell_dummyfix_druid_eclipse : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_eclipse);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ 271675, 272251, 272250, OWLKIN_FRENZY });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Unit* owner = GetTarget();
        for (EclipseBuff const& buff : ECLIPSE_BUFFS)
            if (buff.Eclipse == GetId() && owner->HasAura(buff.Talent))
                owner->CastSpell(owner, buff.Buff, true, nullptr, aurEff);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* owner = GetTarget();
        for (EclipseBuff const& buff : ECLIPSE_BUFFS)
            if (buff.Eclipse == GetId() && buff.EndsWithEclipse)
                owner->RemoveAurasDueToSpell(buff.Buff, owner->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_druid_eclipse::HandleApply, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_druid_eclipse::HandleRemove, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr std::array<uint32, 3> LIVING_SEED_RANKS = { 48500, 48499, 48496 };

class spell_dummyfix_druid_healing_seeds : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_healing_seeds);

    AuraEffect const* _rank = nullptr;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ LIVING_SEED });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        _rank = nullptr;
        HealInfo* heal = eventInfo.GetHealInfo();
        if (!heal || !heal->GetHeal() || !eventInfo.GetProcTarget() || (eventInfo.GetHitMask() & PROC_HIT_CRITICAL))
            return false;
        for (uint32 rank : LIVING_SEED_RANKS)
            if (AuraEffect const* effect = GetTarget()->GetAuraEffect(rank, EFFECT_0))
            {
                if (!roll_chance_i(effect->GetSpellInfo()->ProcChance))
                    return false;
                _rank = effect;
                return true;
            }
        return false;
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        AuraEffect const* rank = _rank;
        _rank = nullptr;
        if (!rank || !eventInfo.GetHealInfo())
            return;
        int32 const amount = CalculatePct(int32(eventInfo.GetHealInfo()->GetHeal()), rank->GetAmount());
        GetTarget()->CastCustomSpell(LIVING_SEED, SPELLVALUE_BASE_POINT0, amount, eventInfo.GetProcTarget(), true, nullptr,
            rank);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_healing_seeds::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_healing_seeds::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 LIFEBLOOM_FAMILY_FLAG_1 = 0x00000010;
constexpr uint32 LIFEBLOOM_FINAL_HEAL = 33778;

class spell_dummyfix_druid_photosynthesis : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_photosynthesis);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ LIFEBLOOM_FINAL_HEAL });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        HealInfo* heal = eventInfo.GetHealInfo();
        return target && heal && target != GetTarget() &&
            target->GetAuraEffect(SPELL_AURA_DUMMY, SPELLFAMILY_DRUID, 0, LIFEBLOOM_FAMILY_FLAG_1, 0, GetTarget()->GetGUID());
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* druid = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        AuraEffect* bloom = target ? target->GetAuraEffect(SPELL_AURA_DUMMY, SPELLFAMILY_DRUID, 0, LIFEBLOOM_FAMILY_FLAG_1, 0,
            druid->GetGUID()) : nullptr;
        SpellInfo const* finalHeal = sSpellMgr->GetSpellInfo(LIFEBLOOM_FINAL_HEAL);
        if (!bloom || !finalHeal)
            return;
        uint32 const stack = bloom->GetBase()->GetStackAmount();
        int32 heal = int32(druid->SpellHealingBonusDone(target, finalHeal, bloom->GetAmount(), HEAL, bloom->GetEffIndex(),
            0.0f, stack));
        heal = int32(target->SpellHealingBonusTaken(druid, finalHeal, heal, HEAL, stack));
        target->CastCustomSpell(target, LIFEBLOOM_FINAL_HEAL, &heal, nullptr, nullptr, true, nullptr, bloom, druid->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_photosynthesis::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_photosynthesis::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct LearnWith
{
    uint32 Aura;
    uint32 Required;
    uint32 Taught;
};

constexpr std::array<LearnWith, 4> LEARN_WITH = {{
    { 977954, 853, 977953 },
    { 990287, 47897, 990280 },
    { 977807, 33891, 977808 },
    { 954550, 12323, 954509 },
}};

LearnWith const* LearnWithByAura(uint32 id)
{
    for (LearnWith const& rule : LEARN_WITH)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

bool KnowsAnyRank(Player const* player, uint32 spell)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spell)); rank;
         rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            return true;
    return false;
}

class spell_dummyfix_druid_learn_with : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_learn_with);

    bool _taught = false;

    bool Validate(SpellInfo const* info) override
    {
        LearnWith const* rule = LearnWithByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->Required, rule->Taught });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        LearnWith const* rule = LearnWithByAura(GetId());
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !player || player->HasSpell(rule->Taught) || !KnowsAnyRank(player, rule->Required))
            return;
        player->learnSpell(rule->Taught, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        LearnWith const* rule = LearnWithByAura(GetId());
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !player || !_taught)
            return;
        _taught = false;
        player->removeSpell(rule->Taught, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_druid_learn_with::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_druid_learn_with::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 NATURES_GRACE_FINAL_RANK = 61346;
constexpr uint32 NATURES_GRACE_BUFF = 16886;
constexpr uint32 DRUID_ENTANGLING_ROOTS_FLAG = 0x00000200;
constexpr uint32 DRUID_NATURES_GRASP_FLAG = 0x00100000;
constexpr std::array<uint32, 7> MASS_ENTANGLEMENT_AND_HYPNOSIS = { 688428, 688429, 688430, 688431, 688513, 954507, 955072 };

class spell_dummyfix_druid_providing_for_nature : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_providing_for_nature);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ NATURES_GRACE_BUFF });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info || !GetTarget()->HasAura(NATURES_GRACE_FINAL_RANK))
            return false;
        if (info->SpellFamilyName == SPELLFAMILY_DRUID &&
            (info->SpellFamilyFlags[0] & (DRUID_ENTANGLING_ROOTS_FLAG | DRUID_NATURES_GRASP_FLAG)))
            return true;
        uint32 const first = info->GetFirstRankSpell()->Id;
        return std::find(MASS_ENTANGLEMENT_AND_HYPNOSIS.begin(), MASS_ENTANGLEMENT_AND_HYPNOSIS.end(), first) !=
            MASS_ENTANGLEMENT_AND_HYPNOSIS.end() || std::find(MASS_ENTANGLEMENT_AND_HYPNOSIS.begin(),
            MASS_ENTANGLEMENT_AND_HYPNOSIS.end(), info->Id) != MASS_ENTANGLEMENT_AND_HYPNOSIS.end();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), NATURES_GRACE_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_providing_for_nature::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_providing_for_nature::HandleProc, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SUFFOCATING_ROOTS = 84378;

class spell_dummyfix_druid_entangling_roots : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_entangling_roots);

    void HandleDispel(DispelInfo* dispelInfo)
    {
        Unit* caster = GetCaster();
        Unit* dispeller = dispelInfo->GetDispeller();
        if (!caster || !dispeller || dispeller == GetUnitOwner() || !caster->HasAura(SUFFOCATING_ROOTS) ||
            !dispeller->IsAlive() || !caster->IsValidAttackTarget(dispeller))
            return;
        caster->CastSpell(dispeller, GetId(), true);
    }

    void Register() override
    {
        AfterDispel += AuraDispelFn(spell_dummyfix_druid_entangling_roots::HandleDispel);
    }
};

constexpr uint32 EVERLIVING_PROC = 415014;

class spell_dummyfix_druid_swiftmend : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_druid_swiftmend);

    void HandleAfterHit()
    {
        GetCaster()->RemoveAurasDueToSpell(EVERLIVING_PROC);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummyfix_druid_swiftmend::HandleAfterHit);
    }
};

struct BloomRule
{
    uint32 Bloom;
    uint32 Seed;
    bool Consumes;
};

constexpr std::array<BloomRule, 2> BLOOMS = {{
    { 273348, 273347, true },
    { 1571884, 1571864, false },
}};

BloomRule const* BloomBySpell(uint32 id)
{
    for (BloomRule const& rule : BLOOMS)
        if (rule.Bloom == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_druid_bloom : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_druid_bloom);

    bool Validate(SpellInfo const* info) override
    {
        BloomRule const* rule = BloomBySpell(info->Id);
        return rule && ValidateSpellInfo({ rule->Seed });
    }

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        BloomRule const* rule = BloomBySpell(GetSpellInfo()->Id);
        ObjectGuid const caster = GetCaster()->GetGUID();
        targets.remove_if([rule, caster](WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            return !rule || !unit || !unit->HasAura(rule->Seed, caster);
        });
    }

    void HandleHeal(SpellEffIndex )
    {
        BloomRule const* rule = BloomBySpell(GetSpellInfo()->Id);
        if (rule && rule->Consumes)
            if (Unit* target = GetHitUnit())
                target->RemoveAurasDueToSpell(rule->Seed, GetCaster()->GetGUID());
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_druid_bloom::FilterTargets, EFFECT_0,
            TARGET_UNIT_SRC_AREA_ALLY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_druid_bloom::FilterTargets, EFFECT_1,
            TARGET_UNIT_SRC_AREA_ALLY);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_druid_bloom::HandleHeal, EFFECT_1, SPELL_EFFECT_HEAL);
    }
};

constexpr std::array<uint32, 3> FERAL_AGGRESSION = { 16858, 16859, 16860 };

class spell_dummyfix_druid_feral_aggression : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_feral_aggression);

    void CalcAmount(AuraEffect const* , int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        Unit* owner = GetUnitOwner();
        amount = owner && owner->IsInFeralForm() ? int32(owner->GetLevel()) * amount / 100 : 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_druid_feral_aggression::CalcAmount, EFFECT_1,
            SPELL_AURA_MOD_ATTACK_POWER);
    }
};

class dummyfix_druid_shapeshift_hooks : public UnitScript
{
public:
    dummyfix_druid_shapeshift_hooks() : UnitScript("dummyfix_druid_shapeshift_hooks", true,
        { UNITHOOK_ON_UNIT_SET_SHAPESHIFT_FORM }) { }

    void OnUnitSetShapeshiftForm(Unit* unit, uint8 ) override
    {
        if (!unit || !unit->IsPlayer())
            return;
        for (uint32 rank : FERAL_AGGRESSION)
            if (AuraEffect* effect = unit->GetAuraEffect(rank, EFFECT_1))
                effect->RecalculateAmount();
    }
};

constexpr uint32 ECLIPSE_SOLAR_ID = 48517;
constexpr uint32 ECLIPSE_LUNAR_ID = 48518;

class spell_dummyfix_druid_chosen_of_elune : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_chosen_of_elune);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ECLIPSE_SOLAR_ID, ECLIPSE_LUNAR_ID });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Unit* owner = GetTarget();
        owner->CastSpell(owner, ECLIPSE_SOLAR_ID, true, nullptr, aurEff);
        owner->CastSpell(owner, ECLIPSE_LUNAR_ID, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_druid_chosen_of_elune::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_druid_carnage_incarnate : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_carnage_incarnate);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        ShapeshiftForm const form = GetTarget()->GetShapeshiftForm();
        if (form != FORM_BEAR && form != FORM_DIREBEAR)
            return;
        SetMaxDuration(GetMaxDuration() * 2);
        SetDuration(GetMaxDuration());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_druid_carnage_incarnate::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr std::array<uint32, 2> ORACLE_RESETS = { 20473, 61295 };

class spell_dummyfix_druid_oracles_blessing : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_druid_oracles_blessing);

    void HandleAfterCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;
        for (uint32 first : ORACLE_RESETS)
            for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(first); rank; rank = rank->GetNextRankSpell())
                player->RemoveSpellCooldown(rank->Id, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_druid_oracles_blessing::HandleAfterCast);
    }
};

constexpr uint32 CATACLYSMIC_ENTRANCE = 274378;
constexpr uint32 CATACLYSM = 274356;
constexpr uint8 CATACLYSMIC_ENTRANCE_STACKS = 5;

class spell_dummyfix_druid_cat_form : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_druid_cat_form);

    bool _empowered = false;

    void HandleBeforeCast()
    {
        Aura const* stacks = GetCaster()->GetAura(CATACLYSMIC_ENTRANCE);
        _empowered = stacks && stacks->GetStackAmount() >= CATACLYSMIC_ENTRANCE_STACKS;
    }

    void HandleAfterCast()
    {
        if (!_empowered)
            return;
        Unit* caster = GetCaster();
        if (Player* player = caster->ToPlayer())
        {
            player->GetGlobalCooldownMgr().CancelGlobalCooldown(GetSpellInfo());
            uint32 const spellId = GetSpellInfo()->Id;
            player->m_Events.AddEventAtOffset([player, spellId]()
            {
                if (SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId))
                    player->GetGlobalCooldownMgr().CancelGlobalCooldown(info);
            }, 1ms);
        }
        caster->RemoveAurasDueToSpell(CATACLYSMIC_ENTRANCE);
        caster->CastSpell(caster, CATACLYSM, true);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_dummyfix_druid_cat_form::HandleBeforeCast);
        AfterCast += SpellCastFn(spell_dummyfix_druid_cat_form::HandleAfterCast);
    }
};

constexpr uint32 INSECT_SWARM_FIRST = 5570;

class spell_dummyfix_druid_faerie_swarm : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_faerie_swarm);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return eventInfo.GetProcTarget() && GetTarget()->IsPlayer();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        Unit* target = eventInfo.GetProcTarget();
        uint32 known = 0;
        for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(INSECT_SWARM_FIRST); rank; rank = rank->GetNextRankSpell())
            if (player->HasSpell(rank->Id))
                known = rank->Id;
        if (known && target)
            player->CastSpell(target, known, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_druid_faerie_swarm::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_druid_faerie_swarm::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 TEMPORAL_SHIFT = 977972;
constexpr uint32 TEMPORAL_BLAST = 930451;
constexpr uint32 TEMPORAL_SHIFT_VALUES = 990256;
constexpr uint32 DRUID_MOONFIRE_FLAG = 0x00000002;
constexpr uint32 DRUID_STARFIRE_FLAG = 0x00000004;
constexpr uint32 DRUID_STARSURGE_FLAG_2 = 0x00080000;

class spell_dummyfix_druid_temporal_shift : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_temporal_shift);

    bool _taught = false;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TEMPORAL_BLAST, TEMPORAL_SHIFT_VALUES });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || player->HasSpell(TEMPORAL_BLAST))
            return;
        player->learnSpell(TEMPORAL_BLAST, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught)
            return;
        _taught = false;
        player->removeSpell(TEMPORAL_BLAST, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_druid_temporal_shift::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_druid_temporal_shift::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

int32 TemporalShiftPct(Unit const* attacker, Unit const* target, SpellInfo const* info)
{
    if (!attacker || !target || !info || info->SpellFamilyName != SPELLFAMILY_DRUID ||
        !attacker->HasAura(TEMPORAL_SHIFT) || !attacker->HasAura(ECLIPSE_LUNAR_ID))
        return 0;
    if (!(info->SpellFamilyFlags[0] & (DRUID_MOONFIRE_FLAG | DRUID_STARFIRE_FLAG)) &&
        !(info->SpellFamilyFlags[2] & DRUID_STARSURGE_FLAG_2))
        return 0;
    SpellInfo const* values = sSpellMgr->GetSpellInfo(TEMPORAL_SHIFT_VALUES);
    if (!values)
        return 0;
    return values->Effects[target->IsControlledByPlayer() ? EFFECT_1 : EFFECT_0].CalcValue();
}

constexpr uint32 STELLAR_AMPLIFICATION = 278131;

constexpr std::array<uint32, 2> GROUP_THINK = { 282009, 81453 };
constexpr uint32 BERSERK = 50334;
constexpr int32 GROUP_THINK_PCT = 20;
constexpr uint32 NPC_WILD_IMP = 855350;
constexpr uint32 DEMONIC_PERSISTENCE_IMPS = 1577297;

class dummyfix_druid_unit_hooks : public UnitScript
{
public:
    dummyfix_druid_unit_hooks() : UnitScript("dummyfix_druid_unit_hooks", true,
        { UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (damage > 0)
            if (int32 const pct = TemporalShiftPct(attacker, target, info))
                AddPct(damage, pct);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (damage)
            if (int32 const pct = TemporalShiftPct(attacker, target, info))
                AddPct(damage, pct);
        if (!target || !attacker || !info || !damage || info->SpellFamilyName != SPELLFAMILY_DRUID ||
            !(info->GetSchoolMask() & (SPELL_SCHOOL_MASK_ARCANE | SPELL_SCHOOL_MASK_NATURE)))
            return;
        Aura* amplification = target->GetAura(STELLAR_AMPLIFICATION, attacker->GetGUID());
        if (!amplification || !amplification->GetEffect(EFFECT_0))
            return;
        AddPct(damage, amplification->GetEffect(EFFECT_0)->GetAmount());
        amplification->DropCharge();
    }

    void OnDamage(Unit* attacker, Unit* , uint32& damage) override
    {
        if (!attacker || !damage || !attacker->IsCreature())
            return;
        Unit* master = attacker->GetCharmerOrOwner();
        Player* owner = master ? master->ToPlayer() : nullptr;
        if (!owner)
            return;
        if ((attacker->IsPet() || attacker->IsCharmed()) && owner->HasAura(BERSERK))
        {
            bool const talent = owner->HasAura(GROUP_THINK[0]);
            bool const enchant = owner->HasAura(GROUP_THINK[1]) && attacker->IsHunterPet();
            if (talent || enchant)
                AddPct(damage, GROUP_THINK_PCT);
        }
        if (attacker->GetEntry() == NPC_WILD_IMP)
            if (Aura const* persistence = owner->GetAura(DEMONIC_PERSISTENCE_IMPS))
                if (AuraEffect const* effect = persistence->GetEffect(EFFECT_0))
                    AddPct(damage, effect->GetAmount());
    }
};

constexpr std::array<uint32, 2> HIGH_WINDS = { 283355, 954126 };
constexpr uint32 HIGH_WINDS_DEBUFF = 954127;

class spell_dummyfix_druid_cyclone : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_cyclone);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ HIGH_WINDS_DEBUFF });
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (!caster || !target->IsAlive() || GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH)
            return;
        if (std::none_of(HIGH_WINDS.begin(), HIGH_WINDS.end(), [caster](uint32 id) { return caster->HasAura(id); }))
            return;
        ObjectGuid const targetGuid = target->GetGUID();
        caster->m_Events.AddEventAtOffset([caster, targetGuid]()
        {
            Unit* victim = ObjectAccessor::GetUnit(*caster, targetGuid);
            if (victim && victim->IsAlive() && caster->IsInWorld())
                caster->CastSpell(victim, HIGH_WINDS_DEBUFF, true);
        }, 1ms);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_druid_cyclone::HandleRemove, EFFECT_0, SPELL_AURA_MOD_STUN,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr std::array<uint32, 2> URSOCS_BLESSING = { 282004, 81446 };
constexpr int32 URSOCS_BLESSING_MS = 3000;

class spell_dummyfix_druid_bear_form_passive : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_bear_form_passive);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        if (GetMaxDuration() > 0 || !target->IsAlive() || GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH)
            return;
        if (std::none_of(URSOCS_BLESSING.begin(), URSOCS_BLESSING.end(), [target](uint32 id) { return target->HasAura(id); }))
            return;
        uint32 const passive = GetId();
        ObjectGuid const guid = target->GetGUID();
        target->m_Events.AddEventAtOffset([target, passive, guid]()
        {
            if (!target->IsInWorld() || !target->IsAlive() || target->GetGUID() != guid || target->HasAura(passive))
                return;
            Aura* copy = target->AddAura(passive, target);
            if (!copy)
                return;
            copy->SetMaxDuration(URSOCS_BLESSING_MS);
            copy->SetDuration(URSOCS_BLESSING_MS);
            if (AuraEffect* attackPower = copy->GetEffect(EFFECT_2))
                attackPower->ChangeAmount(0);
        }, 1ms);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_druid_bear_form_passive::HandleRemove, EFFECT_1,
            SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 ECLIPSE_SOLAR_AURA = 48517;
constexpr uint32 ECLIPSE_LUNAR_AURA = 48518;
constexpr uint32 ECLIPSE_LUNAR_COOLDOWN = 48520;

class spell_dummyfix_druid_lunar_fire : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_druid_lunar_fire);

    bool CheckEffect(AuraEffect const* , ProcEventInfo& )
    {
        Unit* owner = GetTarget();
        return !owner->HasAura(ECLIPSE_LUNAR_COOLDOWN) && !owner->HasAura(ECLIPSE_SOLAR_AURA) &&
            !owner->HasAura(ECLIPSE_LUNAR_AURA);
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_dummyfix_druid_lunar_fire::CheckEffect, EFFECT_ALL,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 GLYPH_OF_NOURISH_CLASSLESS = 118849;

class spell_dummyfix_druid_nourish : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_druid_nourish);

    void HandleHeal(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        AuraEffect const* glyph = caster->GetAuraEffect(GLYPH_OF_NOURISH_CLASSLESS, EFFECT_0);
        if (!target || !glyph)
            return;
        uint32 hots = 0;
        for (AuraEffect const* hot : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_HEAL))
            if (hot->GetCasterGUID() == caster->GetGUID())
                ++hots;
        int32 heal = GetHitHeal();
        AddPct(heal, glyph->GetAmount() * int32(hots));
        SetHitHeal(heal);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_druid_nourish::HandleHeal, EFFECT_0, SPELL_EFFECT_HEAL);
    }
};
}

void ApplyAscensionDummyFixDruidContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 284006:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 284007;
            }
            break;
        case 16858:
        case 16859:
        case 16860:
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_ATTACK_POWER;
            break;
        case 977940:
        case 977939:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ASCENSION_OVERRIDE_SPELL;
                spellInfo->Effects[EFFECT_0].BasePoints = spellInfo->Id == 977940 ? 978704 : 978702;
                spellInfo->Effects[EFFECT_0].DieSides = 0;
                spellInfo->Effects[EFFECT_0].MiscValueB = 0;
                spellInfo->Effects[EFFECT_0].RealPointsPerLevel = 0.0f;
                spellInfo->Effects[EFFECT_0].PointsPerComboPoint = 0.0f;
            }
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixDruidScripts()
{
    RegisterSpellScript(spell_dummyfix_druid_overflow);
    RegisterSpellScript(spell_dummyfix_druid_garden_of_growth);
    RegisterSpellScript(spell_dummyfix_druid_fury_of_the_king);
    RegisterSpellScript(spell_dummyfix_druid_goldrinns_guile);
    RegisterSpellScript(spell_dummyfix_druid_natures_fervor);
    RegisterSpellScript(spell_dummyfix_druid_eclipse);
    RegisterSpellScript(spell_dummyfix_druid_healing_seeds);
    RegisterSpellScript(spell_dummyfix_druid_photosynthesis);
    RegisterSpellScript(spell_dummyfix_druid_cyclone);
    RegisterSpellScript(spell_dummyfix_druid_bear_form_passive);
    RegisterSpellScript(spell_dummyfix_druid_lunar_fire);
    RegisterSpellScript(spell_dummyfix_druid_nourish);
    RegisterSpellScript(spell_dummyfix_druid_learn_with);
    RegisterSpellScript(spell_dummyfix_druid_providing_for_nature);
    RegisterSpellScript(spell_dummyfix_druid_entangling_roots);
    RegisterSpellScript(spell_dummyfix_druid_swiftmend);
    RegisterSpellScript(spell_dummyfix_druid_bloom);
    RegisterSpellScript(spell_dummyfix_druid_feral_aggression);
    RegisterSpellScript(spell_dummyfix_druid_chosen_of_elune);
    RegisterSpellScript(spell_dummyfix_druid_carnage_incarnate);
    RegisterSpellScript(spell_dummyfix_druid_oracles_blessing);
    RegisterSpellScript(spell_dummyfix_druid_cat_form);
    RegisterSpellScript(spell_dummyfix_druid_faerie_swarm);
    RegisterSpellScript(spell_dummyfix_druid_temporal_shift);
    new dummyfix_druid_shapeshift_hooks();
    new dummyfix_druid_unit_hooks();
}
