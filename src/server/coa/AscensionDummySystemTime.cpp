/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "CellImpl.h"
#include "Creature.h"
#include "DBCStores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <list>
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

template <std::size_t N>
bool HasAnyAura(Unit const* unit, std::array<uint32, N> const& spells)
{
    return std::any_of(spells.begin(), spells.end(), [unit](uint32 spell) { return unit->HasAura(spell); });
}

int32 CustomBasePoints(uint32 spell, int32 amount)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    return amount - (info && info->Effects[EFFECT_0].DieSides ? 1 : 0);
}

struct TimeSet
{
    uint32 Align;
    uint32 Aligned;
    uint32 TimeBind;
    uint32 TimeBound;
    uint32 Synchronize;
    uint32 SynchronizeHeal;
    uint32 Drain;
    uint32 Distortion;
    uint32 EternityBuff;
    uint32 EternityHeal;
    uint32 EternityHealMod;
    int32 EternityMsPerStack;
    bool Granted;
};

constexpr std::array<TimeSet, 3> TIME_SETS = {{
    { 276343, 276349, 276344, 276360, 276345, 276350, 276351, 276346, 276347, 276354, 276353, 600, false },
    { 986163, 986160, 986164, 986161, 986165, 986168, 986169, 986166, 986167, 986173, 986172, 300, true },
    { 1576837, 1576838, 1576859, 276360, 1576880, 1576881, 1576839, 1576886, 1576911, 1576913, 1576887, 300, false },
}};
constexpr std::array<uint32, 2> TEMPORAL_DISTORTION_TALENTS = { 276361, 1576907 };
constexpr std::array<uint32, 2> ETERNITY_TALENTS = { 276362, 1576935 };
constexpr uint32 SYNCHRONIZE_PLUS_THREE_HEAL = 1576881;
constexpr std::size_t SYNCHRONIZE_EXTRA_ALLIES = 3;
constexpr float ALIGN_FREEZE_RANGE = 100.0f;
constexpr uint32 ETERNITY_BUFF_DURATION_INDEX = 39;

TimeSet const* TimeSetBySpell(uint32 id)
{
    for (TimeSet const& set : TIME_SETS)
        if (id == set.Align || id == set.TimeBind || id == set.Synchronize || id == set.SynchronizeHeal ||
            id == set.EternityHeal)
            return &set;
    return nullptr;
}

bool IsTimeBound(Unit const* unit, ObjectGuid caster)
{
    return std::any_of(TIME_SETS.begin(), TIME_SETS.end(),
        [unit, caster](TimeSet const& set) { return unit->HasAura(set.TimeBound, caster); });
}

bool IsAlignedOrTimeBound(Unit const* unit, ObjectGuid caster)
{
    return IsTimeBound(unit, caster) || std::any_of(TIME_SETS.begin(), TIME_SETS.end(),
        [unit, caster](TimeSet const& set) { return unit->HasAura(set.Aligned, caster); });
}

void ReleaseDistortion(Unit* caster, TimeSet const& set, bool eternity)
{
    uint8 stacks = 0;
    if (Aura* distortion = caster->GetAura(set.Distortion))
    {
        stacks = distortion->GetStackAmount();
        distortion->Remove();
    }
    if (!eternity)
        return;

    caster->CastSpell(caster, set.EternityBuff, true);
    if (Aura* buff = caster->GetAura(set.EternityBuff))
    {
        int32 const duration = buff->GetMaxDuration() + stacks * set.EternityMsPerStack;
        buff->SetMaxDuration(duration);
        buff->SetDuration(duration);
    }
    if (stacks)
        if (Aura* mod = caster->AddAura(set.EternityHealMod, caster))
            mod->SetStackAmount(stacks);
    caster->CastSpell(caster, set.EternityHeal, true);
    caster->RemoveAurasDueToSpell(set.EternityHealMod);
}

void DistortTime(Unit* caster, TimeSet const& set, int32 cost, bool timeBoundTarget)
{
    bool const distortion = set.Granted || HasAnyAura(caster, TEMPORAL_DISTORTION_TALENTS);
    bool const eternity = set.Granted || HasAnyAura(caster, ETERNITY_TALENTS);
    if (!distortion && !eternity)
        return;

    if (distortion)
        for (uint8 stack = 0; stack < (timeBoundTarget ? 2 : 1); ++stack)
            caster->CastSpell(caster, set.Distortion, true);

    uint32 const before = caster->GetPower(POWER_ENERGY);
    int32 amount = CustomBasePoints(set.Drain, cost);
    if (amount > 0)
        caster->CastCustomSpell(caster, set.Drain, &amount, nullptr, nullptr, true);
    if (before && !caster->GetPower(POWER_ENERGY))
        ReleaseDistortion(caster, set, eternity);
}

class spell_dummysystem_time_distortion : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_distortion);

    bool Validate(SpellInfo const* info) override
    {
        TimeSet const* set = TimeSetBySpell(info->Id);
        return set && ValidateSpellInfo({ set->Drain, set->Distortion, set->EternityBuff, set->EternityHeal,
            set->EternityHealMod });
    }

    void HandleCost(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        if (_paid)
            return;
        _paid = true;
        Unit* caster = GetCaster();
        TimeSet const* set = TimeSetBySpell(GetSpellInfo()->Id);
        if (!caster || !set)
            return;
        Unit* target = GetExplTargetUnit();
        bool const timeBound = GetSpellInfo()->Id == set->Align && target && IsTimeBound(target, caster->GetGUID());
        DistortTime(caster, *set, GetEffectValue(), timeBound);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_dummysystem_time_distortion::HandleCost, EFFECT_1,
            SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunchTarget += SpellEffectFn(spell_dummysystem_time_distortion::HandleCost, EFFECT_1,
            SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
    }

    bool _paid = false;
};

class spell_dummysystem_time_eternity_heal : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_eternity_heal);

    void PreventModRemoval(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_time_eternity_heal::PreventModRemoval, EFFECT_2,
            SPELL_EFFECT_REMOVE_AURA);
    }
};

class spell_dummysystem_time_eternity_mana : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_eternity_mana);

    void HandleEnergize(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* target = GetHitUnit();
        if (!target || !target->GetMaxPower(POWER_MANA))
            return;
        uint32 const missing = target->GetMaxPower(POWER_MANA) - target->GetPower(POWER_MANA);
        uint32 const gain = CalculatePct(missing, GetEffectValue());
        if (gain)
            GetCaster()->EnergizeBySpell(target, GetSpellInfo()->Id, gain, POWER_MANA);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_time_eternity_mana::HandleEnergize, EFFECT_0,
            SPELL_EFFECT_ENERGIZE_PCT);
    }
};

class spell_dummysystem_time_synchronize_stall : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_synchronize_stall);

    struct Frozen
    {
        ObjectGuid Unit;
        uint32 Spell;
        int32 Remaining;
    };

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        for (Unit* unit : FriendsNear(caster, caster, ALIGN_FREEZE_RANGE))
            for (TimeSet const& set : TIME_SETS)
                if (Aura* aligned = unit->GetAura(set.Aligned, caster->GetGUID()))
                    _frozen.push_back({ unit->GetGUID(), set.Aligned, aligned->GetDuration() });
    }

    void Restore()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        for (Frozen const& frozen : _frozen)
            if (Unit* unit = ObjectAccessor::GetUnit(*caster, frozen.Unit))
                if (Aura* aligned = unit->GetAura(frozen.Spell, caster->GetGUID()))
                    aligned->SetDuration(frozen.Remaining);
    }

    void HandleTick(AuraEffect const* )
    {
        Restore();
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Restore();
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_time_synchronize_stall::HandleApply, EFFECT_0,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_time_synchronize_stall::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_time_synchronize_stall::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }

    std::vector<Frozen> _frozen;
};

class spell_dummysystem_time_synchronize_heal : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_synchronize_heal);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        std::list<WorldObject*> others;
        for (auto itr = targets.begin(); itr != targets.end();)
        {
            Unit* unit = (*itr)->ToUnit();
            if (unit && IsAlignedOrTimeBound(unit, caster->GetGUID()))
            {
                ++itr;
                continue;
            }
            if (unit && unit->IsAlive())
                others.push_back(*itr);
            itr = targets.erase(itr);
        }
        if (GetSpellInfo()->Id != SYNCHRONIZE_PLUS_THREE_HEAL)
            return;
        others.sort([](WorldObject* a, WorldObject* b) { return a->ToUnit()->GetHealthPct() < b->ToUnit()->GetHealthPct(); });
        if (others.size() > SYNCHRONIZE_EXTRA_ALLIES)
            others.resize(SYNCHRONIZE_EXTRA_ALLIES);
        targets.splice(targets.end(), others);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummysystem_time_synchronize_heal::FilterTargets,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
    }
};

class spell_dummysystem_time_bind : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_bind);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        Unit* attacker = damage->GetAttacker();
        if (attacker && attacker->GetCharmerOrOwnerPlayerOrPlayerItself())
            _playerDamage += damage->GetDamage();
        else
            _damage += damage->GetDamage();
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Unit* caster = GetCaster();
        TimeSet const* set = TimeSetBySpell(GetId());
        SpellInfo const* bound = set ? sSpellMgr->GetSpellInfo(set->TimeBound) : nullptr;
        if (!caster || !bound)
            return;
        int32 const share = GetSpellInfo()->Effects[EFFECT_1].CalcValue(caster);
        int32 const playerShare = GetSpellInfo()->Effects[EFFECT_2].CalcValue(caster);
        uint32 const total = CalculatePct(_damage, share) + CalculatePct(_playerDamage, playerShare ? playerShare : share);
        int32 const amplitude = bound->Effects[EFFECT_0].Amplitude;
        int32 const ticks = amplitude > 0 ? std::max(1, bound->GetMaxDuration() / amplitude) : 1;
        int32 perTick = CustomBasePoints(set->TimeBound, int32(total) / ticks);
        if (perTick > 0)
            caster->CastCustomSpell(GetTarget(), set->TimeBound, &perTick, nullptr, nullptr, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_time_bind::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_time_bind::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_time_bind::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }

    uint32 _damage = 0;
    uint32 _playerDamage = 0;
};

struct ArcanistElement
{
    uint32 School;
    uint32 Meteor;
    uint32 MeteorCall;
    uint32 Mote;
    uint32 Resonance;
    uint32 Dampen;
    uint32 Stored;
    uint32 TalentMeteor;
};

constexpr std::array<ArcanistElement, 4> ARCANIST_ELEMENTS = {{
    { SPELL_SCHOOL_MASK_FIRE, 984118, 984394, 984139, 984406, 984410, 271292, 271288 },
    { SPELL_SCHOOL_MASK_NATURE, 984130, 984268, 984142, 984409, 984412, 271295, 271291 },
    { SPELL_SCHOOL_MASK_FROST, 984122, 984266, 984140, 984407, 984395, 271293, 271289 },
    { SPELL_SCHOOL_MASK_ARCANE, 984126, 984267, 984141, 984408, 984411, 271294, 271290 },
}};
constexpr std::array<uint8, 4> MOTE_CYCLE = { 3, 0, 2, 1 };
constexpr uint32 ARCANIST_POTENTIAL = 984138;
constexpr uint32 LEGACY_OF_THE_ARCANIST_TALENT = 271284;
constexpr float METEOR_LANDING_RADIUS = 8.0f;

ArcanistElement const* ArcanistElementOf(SpellInfo const* info)
{
    for (ArcanistElement const& element : ARCANIST_ELEMENTS)
        if (info->GetSchoolMask() & element.School)
            return &element;
    return nullptr;
}

ArcanistElement const* ArcanistElementByResonance(uint32 id)
{
    for (ArcanistElement const& element : ARCANIST_ELEMENTS)
        if (element.Resonance == id)
            return &element;
    return nullptr;
}

bool IsArcanistMeteor(uint32 id)
{
    return std::any_of(ARCANIST_ELEMENTS.begin(), ARCANIST_ELEMENTS.end(),
        [id](ArcanistElement const& element) { return element.Meteor == id || element.TalentMeteor == id; });
}

bool IsArcanistDamage(ProcEventInfo& eventInfo)
{
    SpellInfo const* info = eventInfo.GetSpellInfo();
    DamageInfo* damage = eventInfo.GetDamageInfo();
    return info && damage && damage->GetDamage() && eventInfo.GetProcTarget() && !IsArcanistMeteor(info->Id) &&
        ArcanistElementOf(info);
}

class spell_dummysystem_time_arcanist_meteors : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_arcanist_meteors);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!IsArcanistDamage(eventInfo))
            return false;
        return !GetTarget()->HasAura(ArcanistElementOf(eventInfo.GetSpellInfo())->MeteorCall);
    }

    void HandleMeteor(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        ArcanistElement const& element = *ArcanistElementOf(eventInfo.GetSpellInfo());
        owner->CastSpell(owner, element.MeteorCall, true, nullptr, aurEff);
        owner->CastSpell(eventInfo.GetProcTarget(), element.Meteor, true, nullptr, aurEff);

        if (std::none_of(ARCANIST_ELEMENTS.begin(), ARCANIST_ELEMENTS.end(),
            [owner](ArcanistElement const& other) { return owner->HasAura(other.Mote); }))
        {
            owner->CastSpell(owner, ARCANIST_ELEMENTS[MOTE_CYCLE[_cycle]].Mote, true, nullptr, aurEff);
            _cycle = uint8((_cycle + 1) % MOTE_CYCLE.size());
        }

        Aura* potential = owner->GetAura(ARCANIST_POTENTIAL);
        if (!potential || potential->GetStackAmount() < potential->GetSpellInfo()->StackAmount)
            return;
        potential->Remove();
        for (ArcanistElement const& resonance : ARCANIST_ELEMENTS)
            if (owner->HasAura(resonance.Mote))
            {
                owner->RemoveAurasDueToSpell(resonance.Mote);
                owner->CastSpell(owner, resonance.Resonance, true, nullptr, aurEff);
                owner->CastSpell(owner, resonance.Dampen, true, nullptr, aurEff);
                break;
            }
    }

    void HandleCall(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_time_arcanist_meteors::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_time_arcanist_meteors::HandleMeteor, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_time_arcanist_meteors::HandleCall, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }

    uint8 _cycle = 0;
};

class spell_dummysystem_time_arcanist_resonance : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_arcanist_resonance);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (ArcanistElement const* element = ArcanistElementByResonance(GetId()))
            GetTarget()->RemoveAurasDueToSpell(element->MeteorCall);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_time_arcanist_resonance::HandleRemove, EFFECT_0,
            SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummysystem_time_arcanist_store : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_arcanist_store);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return IsArcanistDamage(eventInfo);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), ArcanistElementOf(eventInfo.GetSpellInfo())->Stored, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_time_arcanist_store::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_time_arcanist_store::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_time_arcanist_unleash : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_arcanist_unleash);

    Unit* LandingTarget(Unit* caster)
    {
        WorldLocation const* dest = GetExplTargetDest();
        if (!dest)
            return GetExplTargetUnit();
        float const range = caster->GetExactDist(dest) + METEOR_LANDING_RADIUS;
        std::list<Unit*> enemies;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(caster, caster, range);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(caster, enemies, check);
        Cell::VisitObjects(caster, searcher, range);
        Unit* nearest = nullptr;
        for (Unit* enemy : enemies)
            if (enemy->GetExactDist(dest) <= METEOR_LANDING_RADIUS && caster->IsValidAttackTarget(enemy) &&
                (!nearest || enemy->GetExactDist(dest) < nearest->GetExactDist(dest)))
                nearest = enemy;
        return nearest;
    }

    void HandleUnleash()
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(LEGACY_OF_THE_ARCANIST_TALENT))
            return;
        Unit* target = LandingTarget(caster);
        if (!target)
            return;
        for (ArcanistElement const& element : ARCANIST_ELEMENTS)
            if (caster->HasAura(element.Stored))
                caster->CastSpell(target, element.TalentMeteor, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummysystem_time_arcanist_unleash::HandleUnleash);
    }
};

constexpr uint32 SPREADING_ROOTS_ENCHANT = 954646;
constexpr uint32 SPREADING_ROOTS_TALENT = 283456;
constexpr std::array<uint32, 2> SPREADING_ROOTS_ICD = { 954645, 283460 };

class spell_dummysystem_time_mass_entanglement_spread : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_mass_entanglement_spread);

    void GateEnchant(AuraEffect const* )
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(SPREADING_ROOTS_ENCHANT))
            PreventDefaultAction();
    }

    void GateTalent(AuraEffect const* )
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(SPREADING_ROOTS_TALENT))
            PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_time_mass_entanglement_spread::GateEnchant, EFFECT_1,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_time_mass_entanglement_spread::GateTalent, EFFECT_2,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_time_spreading_roots : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_spreading_roots);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        ObjectGuid const guid = caster->GetGUID();
        targets.remove_if([guid](WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            return !unit || std::any_of(SPREADING_ROOTS_ICD.begin(), SPREADING_ROOTS_ICD.end(),
                [unit, guid](uint32 icd) { return unit->HasAura(icd, guid); });
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummysystem_time_spreading_roots::FilterTargets,
            EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummysystem_time_spreading_roots::FilterTargets,
            EFFECT_1, TARGET_UNIT_DEST_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummysystem_time_spreading_roots::FilterTargets,
            EFFECT_2, TARGET_UNIT_DEST_AREA_ENEMY);
    }
};

constexpr uint32 AEGIS_OVERDRIVE = 299160;
constexpr uint32 AEGIS_ACTIVATION_ICD = 299161;
constexpr uint32 AEGIS_AVOIDANCE_TRIGGER = 299162;
constexpr uint32 AEGIS_EXPLOSION = 299163;
constexpr ShapeshiftForm MANA_FORGED_BARRIER_FORM = ShapeshiftForm(20);
constexpr uint32 MAGE_MANA_SHIELD_FLAG0 = 0x00008000;

bool IsManaShield(SpellInfo const* info)
{
    return info && info->SpellFamilyName == SPELLFAMILY_MAGE && (info->SpellFamilyFlags[0] & MAGE_MANA_SHIELD_FLAG0) &&
        info->HasAura(SPELL_AURA_MANA_SHIELD);
}

bool AegisReady(Unit const* unit)
{
    return unit->HasAura(AEGIS_OVERDRIVE) && unit->GetShapeshiftForm() == MANA_FORGED_BARRIER_FORM;
}

class spell_dummysystem_time_aegis_overdrive : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_aegis_overdrive);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ AEGIS_ACTIVATION_ICD, AEGIS_AVOIDANCE_TRIGGER, AEGIS_EXPLOSION });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        if (!GetTarget()->HasAura(AEGIS_AVOIDANCE_TRIGGER))
            GetTarget()->AddAura(AEGIS_AVOIDANCE_TRIGGER, GetTarget());
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(AEGIS_AVOIDANCE_TRIGGER);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return IsManaShield(eventInfo.GetSpellInfo()) && AegisReady(GetTarget()) &&
            !GetTarget()->HasAura(AEGIS_ACTIVATION_ICD);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), AEGIS_EXPLOSION, true, nullptr, aurEff);
        GetTarget()->CastSpell(GetTarget(), AEGIS_ACTIVATION_ICD, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_time_aegis_overdrive::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_time_aegis_overdrive::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_time_aegis_overdrive::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_time_aegis_overdrive::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_time_aegis_mana_shield : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_aegis_mana_shield);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        AuraRemoveMode const mode = GetTargetApplication()->GetRemoveMode();
        if ((mode == AURA_REMOVE_BY_EXPIRE || mode == AURA_REMOVE_BY_ENEMY_SPELL) && AegisReady(GetTarget()))
            GetTarget()->CastSpell(GetTarget(), AEGIS_EXPLOSION, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_time_aegis_mana_shield::HandleRemove, EFFECT_0,
            SPELL_AURA_MANA_SHIELD, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummysystem_time_aegis_avoidance : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_aegis_avoidance);

    bool CheckProc(ProcEventInfo& )
    {
        Unit* target = GetTarget();
        if (!AegisReady(target))
            return false;
        Unit::AuraEffectList const& shields = target->GetAuraEffectsByType(SPELL_AURA_MANA_SHIELD);
        return std::any_of(shields.begin(), shields.end(),
            [](AuraEffect const* shield) { return IsManaShield(shield->GetSpellInfo()); });
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_time_aegis_avoidance::CheckProc);
    }
};

constexpr uint32 MANAWELL = 954655;
constexpr uint32 MANAWELL_BUFF = 954666;
constexpr uint8 MANAWELL_LIGHTWELL_CHARGES = 5;

constexpr char ManawellHealsKey[] = "AscensionDummySystemTime.ManawellHeals";

struct ManawellHeals final : DataMap::Base
{
    uint8 Count = 0;
};

class spell_dummysystem_time_manawell : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_manawell);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MANAWELL_BUFF });
    }

    void HandleAfterHit()
    {
        Unit* well = GetCaster();
        Unit* priest = GetOriginalCaster();
        Unit* target = GetHitUnit();
        if (!well || !priest || !target || well == priest || !priest->HasAura(MANAWELL))
            return;
        priest->CastSpell(target, MANAWELL_BUFF, true);

        Creature* creature = well->ToCreature();
        if (!creature)
            return;
        if (++creature->CustomData.GetDefault<ManawellHeals>(ManawellHealsKey)->Count >= MANAWELL_LIGHTWELL_CHARGES)
            creature->DespawnOrUnsummon(Milliseconds(1));
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummysystem_time_manawell::HandleAfterHit);
    }
};

constexpr uint32 FROZEN_CHAOS_CRIT_TRIGGER = 980674;
constexpr uint32 FROZEN_CHAOS = 980675;
constexpr uint32 FROZEN_CHAOS_CONFLAGRATE_TRIGGER = 980677;
constexpr uint32 SPLINTERED_CHAOS = 980678;
constexpr uint32 FROZEN_EMBERS = 980685;
constexpr uint32 FROZEN_CHAOS_PVP = 986074;
constexpr uint8 FROZEN_CHAOS_MAX_CHARGES = 4;
constexpr uint32 FINGERS_OF_FROST_BUFF = 44544;
constexpr std::array<uint32, 8> FINGERS_OF_FROST_TALENTS = { 44543, 44545, 414888, 844543, 844545, 844549, 944543, 944545 };
constexpr std::array<uint32, 3> FROZEN_CHAOS_HELPERS = { FROZEN_CHAOS_CRIT_TRIGGER, FROZEN_CHAOS_CONFLAGRATE_TRIGGER,
    FROZEN_CHAOS_PVP };
constexpr uint32 MAGE_FROSTBOLT_FLAG0 = 0x00000020;
constexpr uint32 MAGE_CONE_OF_COLD_FLAG0 = 0x00000200;
constexpr uint32 MAGE_ICE_LANCE_FLAG0 = 0x00020000;
constexpr uint32 SHAMAN_FROST_SHOCK_FLAG0 = 0x80000000;

class spell_dummysystem_time_frozen_chaos : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_frozen_chaos);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        for (uint32 helper : FROZEN_CHAOS_HELPERS)
            if (!GetTarget()->HasAura(helper))
                GetTarget()->AddAura(helper, GetTarget());
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        for (uint32 helper : FROZEN_CHAOS_HELPERS)
            GetTarget()->RemoveAurasDueToSpell(helper);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_time_frozen_chaos::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_time_frozen_chaos::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummysystem_time_frozen_chaos_crit : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_frozen_chaos_crit);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info)
            return false;
        if (info->SpellFamilyName == SPELLFAMILY_MAGE)
            return (info->SpellFamilyFlags[0] & (MAGE_FROSTBOLT_FLAG0 | MAGE_CONE_OF_COLD_FLAG0 | MAGE_ICE_LANCE_FLAG0)) != 0;
        return info->SpellFamilyName == SPELLFAMILY_SHAMAN && (info->SpellFamilyFlags[0] & SHAMAN_FROST_SHOCK_FLAG0);
    }

    void HandleCharge(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (Aura* chaos = owner->GetAura(FROZEN_CHAOS))
        {
            if (chaos->GetCharges() < FROZEN_CHAOS_MAX_CHARGES)
                chaos->ModCharges(1);
            chaos->RefreshDuration();
            return;
        }
        owner->CastSpell(owner, FROZEN_CHAOS, true, nullptr, aurEff);
        if (Aura* chaos = owner->GetAura(FROZEN_CHAOS))
            chaos->SetCharges(1);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_time_frozen_chaos_crit::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_time_frozen_chaos_crit::HandleCharge, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_time_frozen_chaos_conflagrate : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_time_frozen_chaos_conflagrate);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        if (HasAnyAura(GetTarget(), FINGERS_OF_FROST_TALENTS))
            GetTarget()->CastSpell(GetTarget(), FINGERS_OF_FROST_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectProc += AuraEffectProcFn(spell_dummysystem_time_frozen_chaos_conflagrate::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummysystem_time_frozen_embers : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_time_frozen_embers);

    void HandleAfterHit()
    {
        Unit* caster = GetCaster();
        if (caster && GetHitUnit() && caster->HasAura(SPLINTERED_CHAOS))
            caster->CastSpell(caster, FROZEN_EMBERS, true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummysystem_time_frozen_embers::HandleAfterHit);
    }
};
}

void ApplyAscensionDummySystemTimeContracts(SpellInfo* spellInfo)
{
    switch (spellInfo->Id)
    {
        case 986166:
        case 1576886:
            for (SpellEffIndex effIndex : { EFFECT_0, EFFECT_2 })
                if (!spellInfo->Effects[effIndex].SpellClassMask)
                    spellInfo->Effects[effIndex].SpellClassMask = flag96(0x00000002, 0, 0);
            break;
        case 986167:
            if (!spellInfo->DurationEntry)
                spellInfo->DurationEntry = sSpellDurationStore.LookupEntry(ETERNITY_BUFF_DURATION_INDEX);
            break;
        case 276344:
            spellInfo->AttributesEx5 |= SPELL_ATTR5_LIMIT_N;
            break;
        case 984118:
        case 984122:
        case 984126:
        case 984130:
            spellInfo->AttributesCu |= SPELL_ATTR0_CU_SHARE_DAMAGE;
            break;
        default:
            break;
    }
}

void AddAscensionDummySystemTimeScripts()
{
    RegisterSpellScript(spell_dummysystem_time_distortion);
    RegisterSpellScript(spell_dummysystem_time_eternity_heal);
    RegisterSpellScript(spell_dummysystem_time_eternity_mana);
    RegisterSpellScript(spell_dummysystem_time_synchronize_stall);
    RegisterSpellScript(spell_dummysystem_time_synchronize_heal);
    RegisterSpellScript(spell_dummysystem_time_bind);
    RegisterSpellScript(spell_dummysystem_time_arcanist_meteors);
    RegisterSpellScript(spell_dummysystem_time_arcanist_resonance);
    RegisterSpellScript(spell_dummysystem_time_arcanist_store);
    RegisterSpellScript(spell_dummysystem_time_arcanist_unleash);
    RegisterSpellScript(spell_dummysystem_time_mass_entanglement_spread);
    RegisterSpellScript(spell_dummysystem_time_spreading_roots);
    RegisterSpellScript(spell_dummysystem_time_aegis_overdrive);
    RegisterSpellScript(spell_dummysystem_time_aegis_mana_shield);
    RegisterSpellScript(spell_dummysystem_time_aegis_avoidance);
    RegisterSpellScript(spell_dummysystem_time_manawell);
    RegisterSpellScript(spell_dummysystem_time_frozen_chaos);
    RegisterSpellScript(spell_dummysystem_time_frozen_chaos_crit);
    RegisterSpellScript(spell_dummysystem_time_frozen_chaos_conflagrate);
    RegisterSpellScript(spell_dummysystem_time_frozen_embers);
}
