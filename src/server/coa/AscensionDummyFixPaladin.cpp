/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "AscensionDummySystemMelee.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "Player.h"
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
#include <mutex>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
struct BeaconRule
{
    uint32 Cast;
    uint32 Aura;
    uint32 Share;
    bool HolyLightFlashOnly;
};

constexpr std::array<BeaconRule, 3> BEACONS = {{
    { 277680, 277682, 277684, false },
    { 979232, 979234, 979236, false },
    { 1277680, 1277682, 1277684, true },
}};

constexpr uint32 PALADIN_HOLY_LIGHT_FLAG = 0x80000000;
constexpr uint32 PALADIN_FLASH_OF_LIGHT_FLAG = 0x40000000;

std::mutex BeaconLock;
std::unordered_map<ObjectGuid, std::unordered_set<ObjectGuid>> BeaconTargets;

BeaconRule const* BeaconByCast(uint32 id)
{
    for (BeaconRule const& rule : BEACONS)
        if (rule.Cast == id)
            return &rule;
    return nullptr;
}

bool BeaconQualifies(BeaconRule const& rule, SpellInfo const* heal)
{
    if (!(heal->GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY))
        return false;
    if (rule.HolyLightFlashOnly)
        return heal->SpellFamilyName == SPELLFAMILY_PALADIN &&
            (heal->SpellFamilyFlags[0] & (PALADIN_HOLY_LIGHT_FLAG | PALADIN_FLASH_OF_LIGHT_FLAG));
    return heal->CastTimeEntry && heal->CastTimeEntry->CastTime > 0;
}

void FilterInjuredAllies(std::list<WorldObject*>& targets, Unit* explicitTarget, SpellInfo const* info)
{
    targets.remove_if([explicitTarget](WorldObject* object)
    {
        Unit* unit = object->ToUnit();
        return !unit || unit == explicitTarget || !unit->IsAlive() || unit->IsFullHealth();
    });
    targets.sort([](WorldObject* a, WorldObject* b) { return a->ToUnit()->GetHealthPct() < b->ToUnit()->GetHealthPct(); });
    std::size_t const extra = info->MaxAffectedTargets > 1 ? info->MaxAffectedTargets - 1 : 0;
    if (targets.size() > extra)
        targets.resize(extra);
}

void BeaconTargetOnHit(Unit* caster, Unit* target, uint32 castId)
{
    if (BeaconRule const* rule = BeaconByCast(castId))
        caster->CastSpell(target, rule->Aura, true);
}

class spell_dummyfix_paladin_beacon_of_virtue_party : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_beacon_of_virtue_party);

    bool Validate(SpellInfo const* info) override
    {
        BeaconRule const* rule = BeaconByCast(info->Id);
        return rule && ValidateSpellInfo({ rule->Aura, rule->Share });
    }

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        FilterInjuredAllies(targets, GetExplTargetUnit(), GetSpellInfo());
    }

    void HandleDummy(SpellEffIndex )
    {
        if (Unit* target = GetHitUnit())
            BeaconTargetOnHit(GetCaster(), target, GetSpellInfo()->Id);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_paladin_beacon_of_virtue_party::FilterTargets,
            EFFECT_0, TARGET_UNIT_LASTTARGET_AREA_PARTY);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_paladin_beacon_of_virtue_party::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_paladin_beacon_of_virtue_ally : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_beacon_of_virtue_ally);

    bool Validate(SpellInfo const* info) override
    {
        BeaconRule const* rule = BeaconByCast(info->Id);
        return rule && ValidateSpellInfo({ rule->Aura, rule->Share });
    }

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        FilterInjuredAllies(targets, GetExplTargetUnit(), GetSpellInfo());
    }

    void HandleDummy(SpellEffIndex )
    {
        if (Unit* target = GetHitUnit())
            BeaconTargetOnHit(GetCaster(), target, GetSpellInfo()->Id);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_paladin_beacon_of_virtue_ally::FilterTargets,
            EFFECT_0, TARGET_UNIT_DEST_AREA_ALLY);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_paladin_beacon_of_virtue_ally::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_paladin_beacon_of_virtue_aura : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_beacon_of_virtue_aura);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        std::lock_guard<std::mutex> lock(BeaconLock);
        BeaconTargets[GetCasterGUID()].insert(GetTarget()->GetGUID());
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        ObjectGuid const caster = GetCasterGUID();
        for (BeaconRule const& rule : BEACONS)
            if (rule.Aura != GetId() && GetTarget()->HasAura(rule.Aura, caster))
                return;
        std::lock_guard<std::mutex> lock(BeaconLock);
        auto const itr = BeaconTargets.find(caster);
        if (itr == BeaconTargets.end())
            return;
        itr->second.erase(GetTarget()->GetGUID());
        if (itr->second.empty())
            BeaconTargets.erase(itr);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_paladin_beacon_of_virtue_aura::HandleApply, EFFECT_0,
            SPELL_AURA_ADD_FLAT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_paladin_beacon_of_virtue_aura::HandleRemove, EFFECT_0,
            SPELL_AURA_ADD_FLAT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

bool IsBeaconShare(SpellInfo const* info)
{
    for (BeaconRule const& rule : BEACONS)
        if (SpellInfo const* share = sSpellMgr->GetSpellInfo(rule.Share))
            if (uint32(share->Effects[EFFECT_0].MiscValue) == info->Id)
                return true;
    return false;
}

void ShareHealWithBeacons(Unit* healer, Unit* receiver, uint32 heal, SpellInfo const* info)
{
    if (IsBeaconShare(info))
        return;
    std::vector<ObjectGuid> beacons;
    {
        std::lock_guard<std::mutex> lock(BeaconLock);
        auto const itr = BeaconTargets.find(healer->GetGUID());
        if (itr == BeaconTargets.end())
            return;
        beacons.assign(itr->second.begin(), itr->second.end());
    }
    for (ObjectGuid const& guid : beacons)
    {
        Unit* beacon = ObjectAccessor::GetUnit(*healer, guid);
        if (!beacon || beacon == receiver || !beacon->IsAlive())
            continue;
        for (BeaconRule const& rule : BEACONS)
        {
            if (!beacon->HasAura(rule.Aura, healer->GetGUID()) || !BeaconQualifies(rule, info))
                continue;
            SpellInfo const* share = sSpellMgr->GetSpellInfo(rule.Share);
            SpellInfo const* beaconHeal = share ? sSpellMgr->GetSpellInfo(uint32(share->Effects[EFFECT_0].MiscValue)) : nullptr;
            if (!beaconHeal || !healer->IsWithinDistInMap(beacon, beaconHeal->GetMaxRange(true)))
                continue;
            int32 amount = int32(CalculatePct(heal, share->Effects[EFFECT_0].CalcValue())) -
                (beaconHeal->Effects[EFFECT_0].DieSides ? 1 : 0);
            if (amount <= 0)
                continue;
            healer->CastCustomSpell(beacon, beaconHeal->Id, &amount, nullptr, nullptr, true);
            break;
        }
    }
}

uint32 SteedMount(uint32 steed)
{
    return steed == 291021 ? 291020 : steed == 991021 ? 991020 : 0;
}

uint32 SteedOfMount(uint32 mount)
{
    return mount == 291020 ? 291021 : mount == 991020 ? 991021 : 0;
}

class spell_dummyfix_paladin_divine_steed : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_divine_steed);

    bool Validate(SpellInfo const* info) override
    {
        return SteedMount(info->Id) && ValidateSpellInfo({ SteedMount(info->Id) });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        uint32 const mount = SteedMount(GetId());
        target->CastSpell(target, mount, true, nullptr, aurEff);
        if (Aura* steed = target->GetAura(mount, target->GetGUID()))
        {
            steed->SetMaxDuration(GetMaxDuration());
            steed->SetDuration(GetDuration());
        }
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(SteedMount(GetId()), GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_paladin_divine_steed::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_paladin_divine_steed::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_paladin_divine_steed_mount : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_divine_steed_mount);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (uint32 const steed = SteedOfMount(GetId()))
            GetTarget()->RemoveAurasDueToSpell(steed, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_paladin_divine_steed_mount::HandleRemove, EFFECT_0,
            SPELL_AURA_MOUNTED, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint8 CRIMSON_CONSUMED_STACKS = 3;
constexpr uint32 CHAMPIONS_WRATH = 273526;
constexpr uint32 CHAMPIONS_PROTECTION = 273527;
constexpr uint32 CRIMSON_JUDGEMENT = 273533;
constexpr uint32 CHAMPIONS_WRATH_REBORN = 1572107;
constexpr uint32 CHAMPIONS_COURAGE_REBORN = 1572109;
constexpr uint32 CRIMSON_DEFENDER_REBORN = 1572103;
constexpr std::array<uint32, 6> JUDGEMENT_CASTS = { 20271, 53407, 53408, 1120271, 1153407, 1153408 };

bool IsShieldOfRighteousness(SpellInfo const* info)
{
    return info->SpellFamilyName == SPELLFAMILY_PALADIN && (info->SpellFamilyFlags[1] & 0x00100000);
}

uint32 CrimsonEmpowerment(uint32 aura, SpellInfo const* info)
{
    if (aura == CRIMSON_DEFENDER_REBORN)
    {
        if (IsShieldOfRighteousness(info))
            return CHAMPIONS_WRATH_REBORN;
        if (info->SpellFamilyName == SPELLFAMILY_PALADIN && (info->SpellFamilyFlags[0] & 0x00004000))
            return CHAMPIONS_COURAGE_REBORN;
        return 0;
    }
    if (IsShieldOfRighteousness(info) ||
        (info->SpellFamilyName == SPELLFAMILY_WARRIOR && (info->SpellFamilyFlags[1] & 0x00000200)))
        return CHAMPIONS_WRATH;
    if (std::find(JUDGEMENT_CASTS.begin(), JUDGEMENT_CASTS.end(), info->Id) != JUDGEMENT_CASTS.end())
        return CRIMSON_JUDGEMENT;
    if (info->SpellFamilyName == SPELLFAMILY_PRIEST && (info->SpellFamilyFlags[0] & 0x00000001))
        return CHAMPIONS_PROTECTION;
    return 0;
}

class spell_dummyfix_paladin_crimson_defender : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_crimson_defender);

    uint32 _empowerment = 0;
    ObjectGuid _target;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ CHAMPIONS_WRATH, CHAMPIONS_PROTECTION, CRIMSON_JUDGEMENT, CHAMPIONS_WRATH_REBORN,
            CHAMPIONS_COURAGE_REBORN });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        _empowerment = 0;
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        if (!info || !spell || GetStackAmount() < CRIMSON_CONSUMED_STACKS)
            return false;
        uint32 const empowerment = CrimsonEmpowerment(GetId(), info);
        if (!empowerment)
            return false;
        Unit* caster = GetTarget();
        if (empowerment == CHAMPIONS_PROTECTION || empowerment == CHAMPIONS_COURAGE_REBORN)
            _target = caster->GetGUID();
        else
        {
            Unit* victim = spell->m_targets.GetUnitTarget();
            if (!victim || !caster->IsValidAttackTarget(victim))
                return false;
            _target = victim->GetGUID();
        }
        _empowerment = empowerment;
        return true;
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        if (!_empowerment)
            return;
        Unit* caster = GetTarget();
        uint32 const empowerment = _empowerment;
        ObjectGuid const targetGuid = _target;
        _empowerment = 0;
        GetAura()->ModStackAmount(-int32(CRIMSON_CONSUMED_STACKS));
        caster->m_Events.AddEventAtOffset([caster, empowerment, targetGuid]()
        {
            Unit* target = ObjectAccessor::GetUnit(*caster, targetGuid);
            if (!target || !caster->IsInWorld())
                return;
            if (empowerment == CRIMSON_JUDGEMENT)
            {
                SpellCastTargets targets;
                targets.SetUnitTarget(target);
                targets.SetDst(*target);
                caster->CastSpell(targets, sSpellMgr->GetSpellInfo(CRIMSON_JUDGEMENT), nullptr, TRIGGERED_FULL_MASK);
                return;
            }
            caster->CastSpell(target, empowerment, true);
        }, 1ms);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_paladin_crimson_defender::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_crimson_defender::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummyfix_paladin_champions_wrath : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_champions_wrath);

    void HandleDamage(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        float const power = float(caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY)) +
            caster->GetTotalAttackPowerValue(BASE_ATTACK);
        SetEffectValue(int32(caster->GetLevel() * 9 + GetEffectValue() * 3 + power * 0.36f));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_paladin_champions_wrath::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_dummyfix_paladin_champions_wrath_reborn : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_champions_wrath_reborn);

    void HandleDamage(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        SetEffectValue(GetEffectValue() + int32(caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY) * 0.2f +
            caster->GetTotalAttackPowerValue(BASE_ATTACK) * 0.15f));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_paladin_champions_wrath_reborn::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_dummyfix_paladin_crimson_judgement : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_crimson_judgement);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        if (Unit* judged = GetExplTargetUnit())
            targets.remove(judged);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_paladin_crimson_judgement::FilterTargets,
            EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
    }
};

constexpr std::array<uint32, 4> SEALS_OF_RIGHTEOUSNESS = { 1121084, 1120154, 21084, 20154 };
constexpr uint32 SEAL_OF_RIGHTEOUSNESS_DAMAGE = 25742;

uint32 ActiveSealOfRighteousness(Unit const* unit)
{
    for (uint32 seal : SEALS_OF_RIGHTEOUSNESS)
        if (unit->HasAura(seal, unit->GetGUID()))
            return seal;
    return 0;
}

class spell_dummyfix_paladin_branding_zeal : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_branding_zeal);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetProcTarget();
        return damage && damage->GetDamage() && target && target->IsAlive() && ActiveSealOfRighteousness(GetTarget());
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* paladin = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        uint32 const seal = ActiveSealOfRighteousness(paladin);
        AuraEffect const* aurEff = seal ? paladin->GetAuraEffect(seal, EFFECT_0, paladin->GetGUID()) : nullptr;
        if (!target || !aurEff)
            return;
        float const ap = paladin->GetTotalAttackPowerValue(BASE_ATTACK);
        int32 const holy = paladin->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY) +
            target->SpellBaseDamageBonusTaken(SPELL_SCHOOL_MASK_HOLY);
        int32 const bp = std::max<int32>(0, int32((ap * 0.022f + 0.044f * holy) * paladin->GetAttackTime(BASE_ATTACK) / 1000));
        paladin->CastCustomSpell(sSpellMgr->GetSpellTwinFor(SEAL_OF_RIGHTEOUSNESS_DAMAGE, seal), SPELLVALUE_BASE_POINT0, bp,
            target, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_paladin_branding_zeal::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_branding_zeal::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 CRUSADERS_JUSTICE_DAMAGE = 985973;
constexpr uint32 CRUSADERS_JUSTICE_HEAL = 985974;

class spell_dummyfix_paladin_crusaders_justice : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_crusaders_justice);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ CRUSADERS_JUSTICE_DAMAGE, CRUSADERS_JUSTICE_HEAL });
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target)
            return;
        if (caster->IsFriendlyTo(target))
            caster->CastSpell(target, CRUSADERS_JUSTICE_HEAL, true);
        else if (caster->IsValidAttackTarget(target))
            caster->CastSpell(target, CRUSADERS_JUSTICE_DAMAGE, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_paladin_crusaders_justice::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_paladin_crusaders_justice_heal : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_crusaders_justice_heal);

    void HandleHeal(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        float const weaponSpeed = caster->GetAttackTime(BASE_ATTACK) / 1000.0f;
        SetEffectValue(int32(1 + weaponSpeed * (0.12f * caster->GetTotalAttackPowerValue(BASE_ATTACK) +
            0.08f * caster->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_HOLY))));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_paladin_crusaders_justice_heal::HandleHeal, EFFECT_0,
            SPELL_EFFECT_HEAL);
    }
};

constexpr std::array<uint32, 2> SPECTRE = { 81186, 281505 };
constexpr uint32 PESTILENT_OPPORTUNIST = 81188;

bool HasOwnBleed(Unit const* target, ObjectGuid caster)
{
    for (auto const& [id, application] : target->GetAppliedAuras())
    {
        Aura const* aura = application->GetBase();
        if (aura->GetCasterGUID() == caster &&
            (aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (uint64(1) << MECHANIC_BLEED)))
            return true;
    }
    return false;
}

enum class BuffCondition : uint8
{
    RageAboveHalf,
    RageNotAboveHalf,
    Swashbuckling,
    InnerFire,
};

struct ConditionalBuff
{
    uint32 Talent;
    uint32 Buff;
    BuffCondition Condition;
};

constexpr std::array<ConditionalBuff, 9> CONDITIONAL_BUFFS = {{
    { 84524, 84525, BuffCondition::RageAboveHalf },
    { 84524, 84526, BuffCondition::RageNotAboveHalf },
    { 282348, 84525, BuffCondition::RageAboveHalf },
    { 282348, 84526, BuffCondition::RageNotAboveHalf },
    { 81221, 81222, BuffCondition::Swashbuckling },
    { 281602, 281603, BuffCondition::Swashbuckling },
    { 81219, 81220, BuffCondition::Swashbuckling },
    { 281597, 81220, BuffCondition::Swashbuckling },
    { 283744, 283747, BuffCondition::InnerFire },
}};

constexpr uint32 PRIEST_INNER_FIRE_FLAG = 0x00000002;

bool IsSwashbuckling(Unit const* unit)
{
    return IsAscensionSwashbuckling(unit);
}

bool HasInnerFire(Unit const* unit)
{
    for (auto const& [id, application] : unit->GetAppliedAuras())
    {
        SpellInfo const* info = application->GetBase()->GetSpellInfo();
        if (info->SpellFamilyName == SPELLFAMILY_PRIEST && (info->SpellFamilyFlags[0] & PRIEST_INNER_FIRE_FLAG) &&
            info->HasAura(SPELL_AURA_MOD_RESISTANCE))
            return true;
    }
    return false;
}

bool ConditionHolds(Unit const* unit, BuffCondition condition)
{
    switch (condition)
    {
        case BuffCondition::RageAboveHalf:
        case BuffCondition::RageNotAboveHalf:
        {
            uint32 const maxRage = unit->GetMaxPower(POWER_RAGE);
            if (!maxRage)
                return false;
            bool const above = unit->GetPower(POWER_RAGE) * 2 > maxRage;
            return condition == BuffCondition::RageAboveHalf ? above : !above;
        }
        case BuffCondition::Swashbuckling:
            return IsSwashbuckling(unit);
        case BuffCondition::InnerFire:
            return HasInnerFire(unit);
    }
    return false;
}

void SyncConditionalBuffs(Unit* unit, uint32 leaving = 0)
{
    std::unordered_map<uint32, bool> wanted;
    for (ConditionalBuff const& rule : CONDITIONAL_BUFFS)
    {
        bool& want = wanted[rule.Buff];
        if (!want && rule.Talent != leaving && unit->HasAura(rule.Talent, unit->GetGUID()) &&
            ConditionHolds(unit, rule.Condition))
            want = true;
    }
    if (leaving != 281602 && unit->HasAura(281602, unit->GetGUID()))
        wanted[81222] = false;
    for (auto const& [buff, want] : wanted)
    {
        bool const has = unit->HasAura(buff, unit->GetGUID());
        if (want && !has)
            unit->CastSpell(unit, buff, true);
        else if (!want && has)
            unit->RemoveAurasDueToSpell(buff, unit->GetGUID());
    }
}

class spell_dummyfix_paladin_conditional_buff : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_conditional_buff);

    bool Validate(SpellInfo const* info) override
    {
        for (ConditionalBuff const& rule : CONDITIONAL_BUFFS)
            if (rule.Talent == info->Id && !ValidateSpellInfo({ rule.Buff }))
                return false;
        return true;
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        SyncConditionalBuffs(GetTarget());
    }

    void HandleTick(AuraEffect const* )
    {
        PreventDefaultAction();
        SyncConditionalBuffs(GetTarget());
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        SyncConditionalBuffs(GetTarget(), GetId());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_paladin_conditional_buff::HandleApply, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_paladin_conditional_buff::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_paladin_conditional_buff::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 ALL_THAT_IS_RIGHT = 277746;
constexpr uint32 ALL_THAT_IS_RIGHT_BUFF = 277747;

class spell_dummyfix_paladin_all_that_is_right : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_all_that_is_right);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ALL_THAT_IS_RIGHT_BUFF });
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        if (!caster || GetHitDamage() <= 0 || !caster->HasAura(ALL_THAT_IS_RIGHT, caster->GetGUID()))
            return;
        Aura const* buff = caster->GetAura(ALL_THAT_IS_RIGHT_BUFF, caster->GetGUID());
        if (buff && buff->GetStackAmount() >= buff->GetSpellInfo()->StackAmount)
            return;
        caster->CastSpell(caster, ALL_THAT_IS_RIGHT_BUFF, true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummyfix_paladin_all_that_is_right::HandleHit);
    }
};

constexpr uint32 DRUID_STARFALL_FLAG1 = 0x00800000;

Aura* OwnStarfall(Unit* unit)
{
    for (auto const& [id, application] : unit->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        SpellInfo const* info = aura->GetSpellInfo();
        if (aura->GetCasterGUID() == unit->GetGUID() && info->SpellFamilyName == SPELLFAMILY_DRUID &&
            (info->SpellFamilyFlags[1] & DRUID_STARFALL_FLAG1) && info->HasAura(SPELL_AURA_PERIODIC_TRIGGER_SPELL))
            return aura;
    }
    return nullptr;
}

class spell_dummyfix_paladin_shooting_stars : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_shooting_stars);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        return info && spell && !info->IsChanneled() && spell->GetCastTime() > 0 && OwnStarfall(GetTarget());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Aura* starfall = OwnStarfall(GetTarget());
        Spell const* spell = eventInfo.GetProcSpell();
        if (!starfall || !spell || starfall->GetDuration() <= 0)
            return;
        int32 const bonus = CalculatePct(spell->GetCastTime(), aurEff->GetAmount());
        if (bonus <= 0)
            return;
        starfall->SetMaxDuration(starfall->GetMaxDuration() + bonus);
        starfall->SetDuration(starfall->GetDuration() + bonus);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_paladin_shooting_stars::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_shooting_stars::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 DAWN_OF_THE_SECOND_DAY = 983950;
constexpr uint32 SECOND_SUNRISE = 983951;
constexpr uint32 CRACK_OF_DAWN = 983955;
constexpr std::array<uint32, 6> INFUSIONS_OF_LIGHT = { 53672, 54149, 1153672, 1154149, 1253672, 1254149 };

class spell_dummyfix_paladin_crack_of_dawn_removal : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_crack_of_dawn_removal);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(CRACK_OF_DAWN, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_paladin_crack_of_dawn_removal::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

struct ElementalSeal
{
    uint32 Seal;
    uint32 Damage;
    SpellSchoolMask School;
};

constexpr std::array<ElementalSeal, 3> ELEMENTAL_SEALS = {{
    { 954425, 954427, SPELL_SCHOOL_MASK_FIRE },
    { 1569826, 272085, SPELL_SCHOOL_MASK_FIRE },
    { 984284, 984286, SPELL_SCHOOL_MASK_ARCANE },
}};

ElementalSeal const* ElementalSealBySpell(uint32 seal)
{
    for (ElementalSeal const& rule : ELEMENTAL_SEALS)
        if (rule.Seal == seal)
            return &rule;
    return nullptr;
}

uint32 FervorDamage(uint32 seal)
{
    ElementalSeal const* rule = ElementalSealBySpell(seal);
    return rule ? rule->Damage : 0;
}

class spell_dummyfix_paladin_seal_of_fervor : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_seal_of_fervor);

    bool Validate(SpellInfo const* info) override
    {
        return FervorDamage(info->Id) && ValidateSpellInfo({ FervorDamage(info->Id) });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!target || !target->IsAlive() || !damage || !damage->GetDamage() || eventInfo.GetTriggerAuraSpell())
            return false;
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        if (!spell)
            return damage->GetAttackType() == BASE_ATTACK;
        return spell->SpellFamilyName == SPELLFAMILY_PALADIN && spell->DmgClass == SPELL_DAMAGE_CLASS_MELEE &&
            spell->Id != FervorDamage(GetId());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        float const attackPower = caster->GetTotalAttackPowerValue(BASE_ATTACK);
        ElementalSeal const* rule = ElementalSealBySpell(GetId());
        if (!rule)
            return;
        int32 const spellPower = caster->SpellBaseDamageBonusDone(rule->School);
        float const weaponSpeed = caster->GetAttackTime(BASE_ATTACK) / 1000.0f;
        int32 const amount = std::max<int32>(1, int32(1 + weaponSpeed * (0.0085f * attackPower + 0.072f * spellPower)));
        caster->CastCustomSpell(rule->Damage, SPELLVALUE_BASE_POINT0, amount, eventInfo.GetProcTarget(), true,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_paladin_seal_of_fervor::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_seal_of_fervor::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummyfix_paladin_judgement_of_fervor : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_judgement_of_fervor);

    void CalcTick(AuraEffect const* , int32& amount, bool& )
    {
        if (Unit* caster = GetCaster())
            amount = int32(1 + 0.1f * caster->GetTotalAttackPowerValue(BASE_ATTACK) +
                0.15f * caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_paladin_judgement_of_fervor::CalcTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_dummyfix_paladin_judgement_of_arcane_wrath : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_paladin_judgement_of_arcane_wrath);

    void HandleDamage(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        SetEffectValue(int32(1 + 0.2f * caster->GetTotalAttackPowerValue(BASE_ATTACK) +
            0.32f * caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE)));
    }

    void HandleSecond(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_paladin_judgement_of_arcane_wrath::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_paladin_judgement_of_arcane_wrath::HandleSecond, EFFECT_1,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 REBORN_BEACON_OF_LIGHT = 1153563;

class spell_dummyfix_paladin_sacred_unity : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_sacred_unity);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        return target && target != GetTarget() && target->IsPlayer() &&
            target->HasAura(REBORN_BEACON_OF_LIGHT, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_paladin_sacred_unity::CheckProc);
    }
};

constexpr uint32 HOUR_OF_JUDGEMENT_ENCHANT = 92568;
constexpr uint32 HOUR_OF_JUDGEMENT = 92570;
constexpr uint32 DIVINE_STORM = 53385;

bool KnowsAnyRankOf(Player const* player, uint32 spell)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spell)); rank;
         rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            return true;
    return false;
}

class spell_dummyfix_paladin_hour_of_judgement : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_hour_of_judgement);

    bool _taught = false;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ HOUR_OF_JUDGEMENT, DIVINE_STORM });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || player->HasSpell(HOUR_OF_JUDGEMENT) || !KnowsAnyRankOf(player, DIVINE_STORM))
            return;
        player->learnSpell(HOUR_OF_JUDGEMENT, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught)
            return;
        _taught = false;
        player->removeSpell(HOUR_OF_JUDGEMENT, SPEC_MASK_ALL, true);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info || info->SpellFamilyName != SPELLFAMILY_PALADIN)
            return false;
        for (SpellEffectInfo const& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE || effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE ||
                effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL || effect.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG ||
                effect.Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE || effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE)
                return true;
        return false;
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_paladin_hour_of_judgement::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_paladin_hour_of_judgement::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_paladin_hour_of_judgement::CheckProc);
    }
};

constexpr uint32 BLESSED_HANDS_CAPSTONE = 53661;
constexpr int32 BLESSED_HANDS_HEALING_PCT = 15;

bool CarriesOwnHand(Unit const* target, ObjectGuid paladin)
{
    for (auto const& [id, application] : target->GetAppliedAuras())
    {
        Aura const* aura = application->GetBase();
        if (aura->GetCasterGUID() == paladin && aura->GetSpellInfo()->GetSpellSpecific() == SPELL_SPECIFIC_HAND)
            return true;
    }
    return false;
}

constexpr uint32 SLAMMIN_MOVEMENT = 979061;
constexpr uint8 IN_SWORD_WE_TRUST_STACKS = 3;

class spell_dummyfix_paladin_in_sword_we_trust : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_in_sword_we_trust);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SLAMMIN_MOVEMENT });
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (GetStackAmount() >= IN_SWORD_WE_TRUST_STACKS)
            owner->CastSpell(owner, SLAMMIN_MOVEMENT, true);
        uint32 const id = GetId();
        ObjectGuid const guid = owner->GetGUID();
        owner->m_Events.AddEventAtOffset([owner, id, guid]() { owner->RemoveAurasDueToSpell(id, guid); }, 1ms);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_in_sword_we_trust::HandleProc, EFFECT_2, SPELL_AURA_DUMMY);
    }
};

class spell_dummyfix_paladin_divine_purpose : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_divine_purpose);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = eventInfo.GetProcTarget();
        SpellInfo const* hand = eventInfo.GetSpellInfo();
        if (!target || !hand || !roll_chance_i(aurEff->GetAmount()) || !target->HasAuraWithMechanic(1 << MECHANIC_STUN))
            return;
        target->RemoveAurasWithMechanic(1 << MECHANIC_STUN, AURA_REMOVE_BY_ENEMY_SPELL, hand->Id);
        target->RemoveAurasDueToSpell(hand->Id, GetTarget()->GetGUID());
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_divine_purpose::HandleProc, EFFECT_2, SPELL_AURA_DUMMY);
    }
};

constexpr float MENDING_HANDS_RADIUS = 8.0f;

class spell_dummyfix_paladin_mending_hands : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_paladin_mending_hands);

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* paladin = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        SpellInfo const* hands = eventInfo.GetSpellInfo();
        if (!target || !hands)
            return;
        std::list<Unit*> allies;
        Acore::AnyFriendlyUnitInObjectRangeCheck check(target, paladin, MENDING_HANDS_RADIUS);
        Acore::UnitListSearcher<Acore::AnyFriendlyUnitInObjectRangeCheck> searcher(target, allies, check);
        Cell::VisitObjects(target, searcher, MENDING_HANDS_RADIUS);
        for (Unit* ally : allies)
            if (ally != target && ally != paladin && ally->IsAlive())
                paladin->CastSpell(ally, hands->Id, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_paladin_mending_hands::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class dummyfix_paladin_unit_hooks : public UnitScript
{
public:
    dummyfix_paladin_unit_hooks() : UnitScript("dummyfix_paladin_unit_hooks", true,
        { UNITHOOK_MODIFY_HEAL_RECEIVED, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_AURA_REMOVE }) { }

    void OnAuraRemove(Unit* unit, AuraApplication* aurApp, AuraRemoveMode mode) override
    {
        if (!unit || !aurApp || (mode != AURA_REMOVE_BY_EXPIRE && mode != AURA_REMOVE_BY_DEFAULT))
            return;
        Aura const* aura = aurApp->GetBase();
        if (std::find(INFUSIONS_OF_LIGHT.begin(), INFUSIONS_OF_LIGHT.end(), aura->GetId()) == INFUSIONS_OF_LIGHT.end() ||
            aura->GetCharges() > 0 || aura->GetCasterGUID() != unit->GetGUID() ||
            !unit->HasAura(DAWN_OF_THE_SECOND_DAY, unit->GetGUID()))
            return;
        unit->CastSpell(unit, SECOND_SUNRISE, true);
    }

    void ModifyHealReceived(Unit* healer, Unit* receiver, uint32& heal, SpellInfo const* info) override
    {
        if (!healer || !receiver || !info || !heal)
            return;
        if ((healer->HasAura(BLESSED_HANDS_CAPSTONE) && CarriesOwnHand(receiver, healer->GetGUID())) ||
            (receiver->HasAura(BLESSED_HANDS_CAPSTONE) && CarriesOwnHand(healer, receiver->GetGUID())))
            AddPct(heal, BLESSED_HANDS_HEALING_PCT);
        if (!healer->IsPlayer())
            return;
        ShareHealWithBeacons(healer, receiver, heal, info);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || !damage)
            return;
        if (attacker->HasStealthAura())
        {
            int32 bonus = 0;
            for (uint32 spectre : SPECTRE)
                if (AuraEffect const* effect = attacker->GetAuraEffect(spectre, EFFECT_0))
                    bonus = std::max(bonus, effect->GetAmount());
            if (bonus > 0)
                AddPct(damage, bonus);
        }
        if (info->Dispel == DISPEL_DISEASE)
            if (AuraEffect const* effect = attacker->GetAuraEffect(PESTILENT_OPPORTUNIST, EFFECT_0))
                if (effect->GetAmount() > 0 && HasOwnBleed(target, attacker->GetGUID()))
                    AddPct(damage, effect->GetAmount());
    }
};
}

void ApplyAscensionDummyFixPaladinContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 853510:
        case 853511:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_SPELL_HEALING_OF_ATTACK_POWER;
                spellInfo->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_ALL;
            }
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_WEAPON_CRIT_PERCENT;
            break;
        case 63646:
        case 63647:
        case 63648:
        {
            int32 const rank = int32(spellInfo->Id - 63646) + 1;
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_SPELL_HEALING_OF_STAT_PERCENT;
                spellInfo->Effects[EFFECT_0].BasePoints = 20 * rank - 1;
                spellInfo->Effects[EFFECT_0].DieSides = 1;
                spellInfo->Effects[EFFECT_0].MiscValue = STAT_STAMINA;
            }
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_HEALING_PCT;
                spellInfo->Effects[EFFECT_1].BasePoints = 4 * rank - 1;
                spellInfo->Effects[EFFECT_1].DieSides = 1;
                spellInfo->Effects[EFFECT_1].MiscValue = 126;
            }
            break;
        }
        case 81221:
        case 281602:
        case 81219:
        case 281597:
        case 283744:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 1000;
            }
            break;
        case 285444:
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_ABILITY_IGNORE_AURASTATE;
                spellInfo->Effects[EFFECT_1].MiscValue = 0;
                spellInfo->Effects[EFFECT_1].SpellClassMask = flag96(0, 0x00000080, 0);
            }
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixPaladinScripts()
{
    RegisterSpellScript(spell_dummyfix_paladin_beacon_of_virtue_party);
    RegisterSpellScript(spell_dummyfix_paladin_beacon_of_virtue_ally);
    RegisterSpellScript(spell_dummyfix_paladin_beacon_of_virtue_aura);
    RegisterSpellScript(spell_dummyfix_paladin_divine_steed);
    RegisterSpellScript(spell_dummyfix_paladin_divine_steed_mount);
    RegisterSpellScript(spell_dummyfix_paladin_crimson_defender);
    RegisterSpellScript(spell_dummyfix_paladin_champions_wrath);
    RegisterSpellScript(spell_dummyfix_paladin_champions_wrath_reborn);
    RegisterSpellScript(spell_dummyfix_paladin_crimson_judgement);
    RegisterSpellScript(spell_dummyfix_paladin_branding_zeal);
    RegisterSpellScript(spell_dummyfix_paladin_crusaders_justice);
    RegisterSpellScript(spell_dummyfix_paladin_crusaders_justice_heal);
    RegisterSpellScript(spell_dummyfix_paladin_conditional_buff);
    RegisterSpellScript(spell_dummyfix_paladin_all_that_is_right);
    RegisterSpellScript(spell_dummyfix_paladin_shooting_stars);
    RegisterSpellScript(spell_dummyfix_paladin_crack_of_dawn_removal);
    RegisterSpellScript(spell_dummyfix_paladin_seal_of_fervor);
    RegisterSpellScript(spell_dummyfix_paladin_judgement_of_fervor);
    RegisterSpellScript(spell_dummyfix_paladin_in_sword_we_trust);
    RegisterSpellScript(spell_dummyfix_paladin_divine_purpose);
    RegisterSpellScript(spell_dummyfix_paladin_mending_hands);
    RegisterSpellScript(spell_dummyfix_paladin_judgement_of_arcane_wrath);
    RegisterSpellScript(spell_dummyfix_paladin_sacred_unity);
    RegisterSpellScript(spell_dummyfix_paladin_hour_of_judgement);
    new dummyfix_paladin_unit_hooks();
}
