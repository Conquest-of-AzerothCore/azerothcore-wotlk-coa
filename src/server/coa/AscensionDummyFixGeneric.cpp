/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "CellImpl.h"
#include "Containers.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "MotionMaster.h"
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
#include "ThreatManager.h"
#include "UnitScript.h"
#include "Pet.h"
#include <algorithm>
#include <array>
#include <list>
#include <vector>

namespace
{
struct FamilyMatch
{
    uint32 Family;
    uint32 Flags0;
    uint32 Flags1;
    uint32 Flags2;
};

bool Matches(SpellInfo const* info, FamilyMatch const& match)
{
    return info && match.Family && info->SpellFamilyName == match.Family &&
        ((info->SpellFamilyFlags[0] & match.Flags0) || (info->SpellFamilyFlags[1] & match.Flags1) ||
            (info->SpellFamilyFlags[2] & match.Flags2));
}

std::list<Unit*> EnemiesNear(WorldObject* center, Unit* caster, float range)
{
    std::list<Unit*> units;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(center, caster, range);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    units.remove_if([caster](Unit* unit) { return !unit->IsAlive() || !caster->IsValidAttackTarget(unit); });
    return units;
}

uint32 HighestKnownRank(Player const* player, uint32 anyRank)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetLastSpellInChain(anyRank)); rank;
         rank = rank->GetPrevRankSpell())
        if (player->HasSpell(rank->Id))
            return rank->Id;
    return 0;
}

constexpr uint32 WARRIOR_CHARGE_FLAG = 0x00000001;
constexpr uint32 DRUID_FERAL_CHARGE_BEAR_FLAG_1 = 0x00000001;
constexpr uint32 DRUID_FERAL_CHARGE_CAT_FLAG_2 = 0x00000020;
constexpr uint32 HUNTER_SCATTER_SHOT_FLAG = 0x00040000;

struct CastOnUse
{
    uint32 Aura;
    std::array<FamilyMatch, 2> Uses;
    uint32 Cast;
    bool OnSelf;
    uint32 AlsoOnTarget;
};

constexpr FamilyMatch CHARGE = { SPELLFAMILY_WARRIOR, WARRIOR_CHARGE_FLAG, 0, 0 };
constexpr FamilyMatch FERAL_CHARGE = { SPELLFAMILY_DRUID, 0, DRUID_FERAL_CHARGE_BEAR_FLAG_1, DRUID_FERAL_CHARGE_CAT_FLAG_2 };
constexpr FamilyMatch SCATTER_SHOT = { SPELLFAMILY_HUNTER, HUNTER_SCATTER_SHOT_FLAG, 0, 0 };
constexpr FamilyMatch NONE = { 0, 0, 0, 0 };

constexpr std::array<CastOnUse, 7> CAST_ON_USE = {{
    { 92252, { CHARGE, NONE }, 92257, false, 0 },
    { 92247, { CHARGE, NONE }, 92253, false, 0 },
    { 92249, { CHARGE, NONE }, 92254, false, 0 },
    { 92250, { CHARGE, NONE }, 92256, false, 0 },
    { 282881, { CHARGE, FERAL_CHARGE }, 282882, true, 0 },
    { 283449, { SCATTER_SHOT, NONE }, 283450, false, 0 },
    { 954641, { SCATTER_SHOT, NONE }, 954642, false, 954665 },
}};

CastOnUse const* CastOnUseRule(uint32 aura)
{
    for (CastOnUse const& rule : CAST_ON_USE)
        if (rule.Aura == aura)
            return &rule;
    return nullptr;
}

class spell_dummyfix_generic_cast_on_use : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_cast_on_use);

    bool Validate(SpellInfo const* info) override
    {
        CastOnUse const* rule = CastOnUseRule(info->Id);
        return rule && ValidateSpellInfo({ rule->Cast }) && (!rule->AlsoOnTarget || ValidateSpellInfo({ rule->AlsoOnTarget }));
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        CastOnUse const* rule = CastOnUseRule(GetId());
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!rule || !info || (!rule->OnSelf && !eventInfo.GetProcTarget()))
            return false;
        return std::any_of(rule->Uses.begin(), rule->Uses.end(),
            [info](FamilyMatch const& use) { return Matches(info, use); });
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        CastOnUse const* rule = CastOnUseRule(GetId());
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        if (!rule)
            return;
        if (rule->OnSelf)
        {
            caster->CastSpell(caster, rule->Cast, true, nullptr, aurEff);
            return;
        }
        if (!target || target == caster)
            return;
        caster->CastSpell(target, rule->Cast, true, nullptr, aurEff);
        if (rule->AlsoOnTarget && target->IsAlive())
            caster->CastSpell(target, rule->AlsoOnTarget, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_cast_on_use::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_cast_on_use::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 MACRO_GRAVITY = 280271;
constexpr uint32 MACRO_GRAVITY_STUN = 280272;
constexpr uint32 SOUL_FRAGMENT = 965899;
constexpr uint32 SHADOW_VISIONS = 965900;

uint8 StackThreshold(uint32 aura)
{
    switch (aura)
    {
        case MACRO_GRAVITY: return 6;
        case SOUL_FRAGMENT: return 9;
        default: return 0;
    }
}

class spell_dummyfix_generic_stack_threshold : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_stack_threshold);

    bool Validate(SpellInfo const* info) override
    {
        return StackThreshold(info->Id) && ValidateSpellInfo({ MACRO_GRAVITY_STUN, SHADOW_VISIONS });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        uint8 const threshold = StackThreshold(GetId());
        if (!threshold || GetStackAmount() < threshold)
            return;
        Unit* target = GetTarget();
        switch (GetId())
        {
            case MACRO_GRAVITY:
            {
                Unit* caster = GetCaster();
                (caster ? caster : target)->CastSpell(target, MACRO_GRAVITY_STUN, true, nullptr, aurEff);
                break;
            }
            case SOUL_FRAGMENT:
                target->CastSpell(target, SHADOW_VISIONS, true, nullptr, aurEff);
                break;
            default:
                return;
        }
        uint32 const id = GetId();
        ObjectGuid const casterGuid = GetCasterGUID();
        target->m_Events.AddEventAtOffset([target, id, casterGuid]()
        {
            target->RemoveAurasDueToSpell(id, casterGuid);
        }, 1ms);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_generic_stack_threshold::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

constexpr uint32 OVERLOADED = 81123;
constexpr uint32 OVERLOADED_STACKS = 10;
constexpr uint32 ASTRAL_TEMPEST_ENCHANT = 81479;
constexpr uint32 OVERLOADED_FROSTSTORM = 81124;
constexpr uint32 ASTRAL_TEMPEST_STORM = 81125;

class spell_dummyfix_generic_overloaded : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_overloaded);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ OVERLOADED, OVERLOADED_FROSTSTORM, ASTRAL_TEMPEST_STORM });
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* struck = eventInfo.GetProcTarget();
        caster->CastSpell(caster, OVERLOADED, true, nullptr, aurEff);
        Aura* stacks = caster->GetAura(OVERLOADED, caster->GetGUID());
        if (!stacks || stacks->GetStackAmount() < OVERLOADED_STACKS)
            return;
        caster->RemoveAura(stacks);
        Unit* at = struck && struck != caster ? struck : caster;
        caster->CastSpell(at->GetPositionX(), at->GetPositionY(), at->GetPositionZ(),
            GetId() == ASTRAL_TEMPEST_ENCHANT ? ASTRAL_TEMPEST_STORM : OVERLOADED_FROSTSTORM, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_overloaded::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 SNIPER = 81167;
constexpr uint32 READY_SET_GO = 81128;
constexpr uint32 READY_SET_GO_BUFF = 81129;

class spell_dummyfix_generic_standing_still : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_standing_still);

    uint8 _still = 0;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SNIPER, READY_SET_GO_BUFF });
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* unit = GetTarget();
        if (GetId() == READY_SET_GO)
        {
            if (unit->IsInCombat() && !unit->isMoving())
                unit->CastSpell(unit, READY_SET_GO_BUFF, true, nullptr, aurEff);
            return;
        }
        if (unit->isMoving())
        {
            _still = 0;
            unit->RemoveAurasDueToSpell(SNIPER, unit->GetGUID());
            return;
        }
        if (Aura* sniper = unit->GetAura(SNIPER, unit->GetGUID()))
            sniper->RefreshDuration();
        if (++_still < 3)
            return;
        _still = 0;
        unit->CastSpell(unit, SNIPER, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_generic_standing_still::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

class spell_dummyfix_generic_shoulder_the_burden : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_shoulder_the_burden);

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* ally = GetHitUnit();
        int32 const pct = std::clamp(GetEffectValue(), 0, 100);
        if (!ally || ally == caster || !pct)
            return;
        std::vector<ThreatReference*> refs;
        for (auto const& [guid, ref] : ally->GetThreatMgr().GetThreatenedByMeList())
            refs.push_back(ref);
        for (ThreatReference* ref : refs)
        {
            Creature* owner = ref->GetOwner();
            float const moved = ref->GetThreat() * float(pct) / 100.0f;
            if (!owner || moved <= 0.0f)
                continue;
            float const before = owner->GetThreatMgr().GetThreat(caster);
            owner->GetThreatMgr().AddThreat(caster, moved, nullptr, true, true);
            if (owner->GetThreatMgr().GetThreat(caster) > before)
                ref->ScaleThreat(1.0f - float(pct) / 100.0f);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_shoulder_the_burden::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 XOROTHIAN_SIGIL_AURA = 280381;

class spell_dummyfix_generic_xorothian_sigil : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_xorothian_sigil);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ XOROTHIAN_SIGIL_AURA });
    }

    void HandleDummy(SpellEffIndex )
    {
        GetCaster()->CastSpell(GetCaster(), XOROTHIAN_SIGIL_AURA, true);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_generic_xorothian_sigil::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 ARCANE_EXPLOSION_FIRST = 1449;
constexpr uint32 BLINK = 1953;
constexpr uint32 ARCANE_BREACH_LISTENER = 299032;
constexpr uint32 WARRIOR_INTERCEPT_FLAG = 0x40000000;

class spell_dummyfix_generic_arcane_breach : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_arcane_breach);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* actor = eventInfo.GetActor();
        return info && actor && actor->GetGUID() == GetCasterGUID() && actor->IsPlayer() &&
            Matches(info, { SPELLFAMILY_WARRIOR, WARRIOR_CHARGE_FLAG | WARRIOR_INTERCEPT_FLAG, 0, 0 });
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Player* player = eventInfo.GetActor()->ToPlayer();
        if (!player)
            return;
        int32 delay = 750;
        int32 blink = 5000;
        if (SpellInfo const* listener = sSpellMgr->GetSpellInfo(ARCANE_BREACH_LISTENER))
        {
            blink = listener->Effects[EFFECT_0].CalcValue();
            delay = listener->Effects[EFFECT_1].CalcValue();
        }
        if (player->HasSpellCooldown(BLINK))
            player->ModifySpellCooldown(BLINK, -blink);
        uint32 const explosion = HighestKnownRank(player, ARCANE_EXPLOSION_FIRST);
        if (!explosion)
            return;
        player->m_Events.AddEventAtOffset([player, explosion]()
        {
            if (player->IsAlive())
                player->CastSpell(player, explosion, true);
        }, Milliseconds(std::max(1, delay)));
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_arcane_breach::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_arcane_breach::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 BONDS_OF_JUSTICE_DAMAGE = 280101;

class spell_dummyfix_generic_bonds_of_justice : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_bonds_of_justice);

    bool _broken = false;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ BONDS_OF_JUSTICE_DAMAGE });
    }

    void Grip()
    {
        _broken = true;
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (!caster || !target->IsAlive() || caster->GetMapId() != target->GetMapId())
            return;
        caster->CastSpell(target, BONDS_OF_JUSTICE_DAMAGE, true);
        Position const landing = caster->GetNearPosition(2.0f, caster->GetRelativeAngle(target));
        float const speedXY = std::max(10.0f, target->GetExactDist2d(landing) * 2.0f);
        target->GetMotionMaster()->MoveJump(
            landing.GetPositionX(), landing.GetPositionY(), landing.GetPositionZ(), speedXY, 10.0f);
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* caster = GetCaster();
        if (_broken || !caster)
            return;
        if (GetTarget()->GetExactDist(caster) >= float(std::max(1, aurEff->GetAmount())))
        {
            Grip();
            GetAura()->SetDuration(0);
        }
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (!_broken && GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
            Grip();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_generic_bonds_of_justice::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_generic_bonds_of_justice::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 MAGE_ARCANE_MISSILE_FLAG = 0x00200000;
constexpr uint32 DRUID_MOONFIRE_FLAG = 0x00000002;

class spell_dummyfix_generic_lunar_spirits : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_lunar_spirits);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* target = eventInfo.GetProcTarget();
        if (!target || target == GetTarget() || !Matches(info, { SPELLFAMILY_MAGE, MAGE_ARCANE_MISSILE_FLAG, 0, 0 }))
            return false;
        return target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_DRUID, DRUID_MOONFIRE_FLAG, 0, 0,
            GetTarget()->GetGUID()) != nullptr;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* target = eventInfo.GetProcTarget())
            GetTarget()->CastSpell(target, aurEff->GetSpellInfo()->Effects[aurEff->GetEffIndex()].TriggerSpell, true,
                nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_lunar_spirits::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_lunar_spirits::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummyfix_generic_lunar_spirits_spread : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_lunar_spirits_spread);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ info->Effects[EFFECT_0].TriggerSpell });
    }

    void HandleDummy(SpellEffIndex effIndex)
    {
        Unit* caster = GetCaster();
        Unit* struck = GetHitUnit();
        if (!struck)
            return;
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[effIndex];
        float const radius = effect.HasRadius() ? effect.CalcRadius(caster) : 10.0f;
        std::list<Unit*> others = EnemiesNear(struck, caster, radius);
        others.remove(struck);
        others.remove(caster);
        uint32 const count = std::max<uint32>(1, GetSpellInfo()->MaxAffectedTargets);
        if (others.size() > count)
            Acore::Containers::RandomResize(others, count);
        for (Unit* other : others)
            caster->CastSpell(other, effect.TriggerSpell, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_lunar_spirits_spread::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 PESTILENT_REPRISAL = 299975;
constexpr uint32 HUNTER_COUNTERATTACK_FLAG_1 = 0x00080000;

int32 PestilentReprisalPct(Unit* target, Unit* attacker, SpellInfo const* info)
{
    if (!target || !attacker || !Matches(info, { SPELLFAMILY_HUNTER, 0, HUNTER_COUNTERATTACK_FLAG_1, 0 }))
        return 0;
    AuraEffect const* buff = attacker->GetAuraEffect(PESTILENT_REPRISAL, EFFECT_0);
    if (!buff)
        return 0;
    int32 diseases = 0;
    for (auto const& [id, application] : target->GetAppliedAuras())
    {
        Aura const* aura = application->GetBase();
        if (aura->GetCasterGUID() == attacker->GetGUID() && aura->GetSpellInfo()->Dispel == DISPEL_DISEASE)
            ++diseases;
    }
    attacker->RemoveAurasDueToSpell(PESTILENT_REPRISAL);
    return buff->GetAmount() * diseases;
}

constexpr uint32 IMPECCABLE_TIMING = 283275;

class spell_dummyfix_generic_impeccable_timing_periodic : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_impeccable_timing_periodic);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ IMPECCABLE_TIMING, info->Effects[EFFECT_0].TriggerSpell });
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* unit = GetTarget();
        uint32 const biding = GetSpellInfo()->Effects[EFFECT_0].TriggerSpell;
        if (unit->HasAura(biding))
            return;
        unit->CastSpell(unit, biding, true, nullptr, aurEff);
        unit->CastSpell(unit, IMPECCABLE_TIMING, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_generic_impeccable_timing_periodic::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

constexpr std::array<FamilyMatch, 2> IMPECCABLE_TIMING_SPELLS = {{
    { SPELLFAMILY_MAGE, 0x00000001 | 0x00000020 | 0x20000000 | 0x80000000, 0x00001000 | 0x00008000, 0 },
    { SPELLFAMILY_DRUID, 0x00000002 | 0x00000004, 0, 0 },
}};

class spell_dummyfix_generic_impeccable_timing : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_impeccable_timing);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return std::any_of(IMPECCABLE_TIMING_SPELLS.begin(), IMPECCABLE_TIMING_SPELLS.end(),
            [info](FamilyMatch const& match) { return Matches(info, match); });
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_impeccable_timing::CheckProc);
    }
};

struct BlessingPool
{
    uint32 Spell;
    uint32 First;
};

constexpr std::array<BlessingPool, 2> BLESSING_POOLS = {{ { 273021, 273022 }, { 965477, 965478 } }};
constexpr uint32 BLESSING_POOL_SIZE = 5;

class spell_dummyfix_generic_blessing_of_the_divines : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_blessing_of_the_divines);

    uint32 First()
    {
        for (BlessingPool const& pool : BLESSING_POOLS)
            if (pool.Spell == GetSpellInfo()->Id)
                return pool.First;
        return 0;
    }

    bool Validate(SpellInfo const* info) override
    {
        for (BlessingPool const& pool : BLESSING_POOLS)
            if (pool.Spell == info->Id)
                return ValidateSpellInfo({ pool.First, pool.First + BLESSING_POOL_SIZE - 1 });
        return false;
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        uint32 const first = First();
        if (!first)
            return;
        Unit* target = GetExplTargetUnit();
        if (!target || !target->IsAlive() || !caster->IsFriendlyTo(target))
            target = caster;
        caster->CastSpell(target, first + urand(0, BLESSING_POOL_SIZE - 1), true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_generic_blessing_of_the_divines::HandleAfterCast);
    }
};

class spell_dummyfix_generic_blessing_of_the_divines_proc : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_blessing_of_the_divines_proc);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        HealInfo const* heal = eventInfo.GetHealInfo();
        if (!info || !heal || !heal->GetHeal() || (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC))
            return false;
        if (!(info->GetSchoolMask() & (SPELL_SCHOOL_MASK_HOLY | SPELL_SCHOOL_MASK_NATURE)))
            return false;
        return info->ManaCost || info->ManaCostPercentage || info->ManaCostPerlevel;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_blessing_of_the_divines_proc::CheckProc);
    }
};

constexpr uint32 BARKSKIN = 22812;

class spell_dummyfix_generic_genesis_barkskin : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_genesis_barkskin);

    void HandleDummy(SpellEffIndex )
    {
        Aura* barkskin = GetCaster()->GetAuraOfRankedSpell(BARKSKIN);
        if (!barkskin || barkskin->GetDuration() <= 0)
            return;
        int32 const duration = barkskin->GetDuration() + 1000;
        if (duration > barkskin->GetMaxDuration())
            barkskin->SetMaxDuration(duration);
        barkskin->SetDuration(duration);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_genesis_barkskin::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_generic_bear_form_proc : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_bear_form_proc);

    bool CheckProc(ProcEventInfo& )
    {
        ShapeshiftForm const form = GetTarget()->GetShapeshiftForm();
        return form == FORM_BEAR || form == FORM_DIREBEAR;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_bear_form_proc::CheckProc);
    }
};

constexpr uint32 INFERNAL_ENTRY = 89;

class spell_dummyfix_generic_raising_hell : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_raising_hell);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Player* player = GetTarget()->ToPlayer();
        Pet* pet = player ? player->GetPet() : nullptr;
        return eventInfo.GetSpellInfo() && pet && pet->IsAlive() && pet->GetEntry() != INFERNAL_ENTRY;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Player* player = GetTarget()->ToPlayer())
            if (Pet* pet = player->GetPet())
                if (!pet->HasAura(eventInfo.GetSpellInfo()->Id))
                    pet->CastSpell(pet, eventInfo.GetSpellInfo()->Id, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_raising_hell::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_raising_hell::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 MOLTEN_CORE = 71165;
constexpr uint32 SHADOW_CORE_ENCHANT = 410604;

class spell_dummyfix_generic_shadow_core : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_shadow_core);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MOLTEN_CORE });
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        if (Aura* core = caster->GetAura(MOLTEN_CORE, caster->GetGUID()))
        {
            uint8 const max = core->CalcMaxCharges();
            if (GetSpellInfo()->Id == SHADOW_CORE_ENCHANT)
            {
                core->SetCharges(max);
                core->RefreshDuration();
            }
            else if (core->GetCharges() < max)
                core->SetCharges(core->GetCharges() + 1);
            return;
        }
        caster->CastSpell(caster, MOLTEN_CORE, true);
        if (Aura* core = caster->GetAura(MOLTEN_CORE, caster->GetGUID()))
            core->SetCharges(1);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_generic_shadow_core::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_generic_void_teleportation : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_void_teleportation);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* ally = eventInfo.GetProcTarget();
        return ally && ally != GetTarget() && ally->IsAlive() && ally->GetMapId() == GetTarget()->GetMapId();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        ObjectGuid const allyGuid = eventInfo.GetProcTarget()->GetGUID();
        caster->m_Events.AddEventAtOffset([caster, allyGuid]()
        {
            Unit* ally = ObjectAccessor::GetUnit(*caster, allyGuid);
            if (!ally || !ally->IsAlive() || !caster->IsAlive())
                return;
            Position const casterAt = caster->GetPosition();
            Position const allyAt = ally->GetPosition();
            caster->NearTeleportTo(allyAt.GetPositionX(), allyAt.GetPositionY(), allyAt.GetPositionZ(),
                caster->GetOrientation());
            ally->NearTeleportTo(casterAt.GetPositionX(), casterAt.GetPositionY(), casterAt.GetPositionZ(),
                ally->GetOrientation());
        }, 1ms);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_void_teleportation::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_void_teleportation::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

constexpr std::array<uint32, 4> HEROIC_LEAPS = { 6544, 86358, 254570, 606544 };

class spell_dummyfix_generic_deadly_leap : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_deadly_leap);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        for (uint32 id : HEROIC_LEAPS)
            if (player->HasSpellCooldown(id))
                player->RemoveSpellCooldown(id, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_generic_deadly_leap::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 CATACLYSMIC_POWER = 289461;
constexpr uint32 MAGE_FIREBALL_FLAG = 0x00000001;
constexpr uint32 WARLOCK_INCINERATE_FLAG_1 = 0x00000040;

int32 CataclysmicPowerPct(Unit* target, Unit* attacker, SpellInfo const* info)
{
    if (!target || (!Matches(info, { SPELLFAMILY_MAGE, MAGE_FIREBALL_FLAG, 0, 0 }) &&
        !Matches(info, { SPELLFAMILY_WARLOCK, 0, WARLOCK_INCINERATE_FLAG_1, 0 })))
        return 0;
    AuraEffect const* talent = attacker->GetAuraEffect(CATACLYSMIC_POWER, EFFECT_0);
    if (!talent)
        return 0;
    std::vector<uint32> burning;
    for (AuraEffect const* dot : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_DAMAGE))
        if (dot->GetCasterGUID() == attacker->GetGUID() && (dot->GetSpellInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_FIRE) &&
            std::find(burning.begin(), burning.end(), dot->GetId()) == burning.end())
            burning.push_back(dot->GetId());
    return talent->GetAmount() * int32(burning.size());
}

constexpr uint32 CHIMERA_SHOT = 53209;

class spell_dummyfix_generic_elemental_reload : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_elemental_reload);

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        if (Player* player = GetTarget()->ToPlayer())
            if (player->HasSpellCooldown(CHIMERA_SHOT))
                player->RemoveSpellCooldown(CHIMERA_SHOT, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_elemental_reload::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 BLOODRAGE = 2687;
constexpr uint32 BLOODRAGE_REGEN = 29131;
constexpr uint32 TITANS_GRIP = 46917;
constexpr uint32 TITANIC_FINALE = 954436;

class spell_dummyfix_generic_finale : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_finale);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Player* player = GetTarget()->ToPlayer();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!player || !info || !info->NeedsComboPoints() || !player->HasSpell(BLOODRAGE) ||
            player->HasAura(BLOODRAGE) || player->HasAura(BLOODRAGE_REGEN))
            return false;
        if (GetId() == TITANIC_FINALE && !player->HasAura(TITANS_GRIP))
            return false;
        int32 const points = player->GetComboPoints();
        return points > 0 && roll_chance_i(20 * points);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), BLOODRAGE, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_finale::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_finale::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct BuffWhile
{
    uint32 Aura;
    uint32 Condition;
    uint32 Buff;
};

constexpr std::array<BuffWhile, 2> BUFF_WHILE = {{ { 299944, 48518, 299945 }, { 299988, 31801, 299989 } }};

BuffWhile const* BuffWhileRule(uint32 aura)
{
    for (BuffWhile const& rule : BUFF_WHILE)
        if (rule.Aura == aura)
            return &rule;
    return nullptr;
}

class spell_dummyfix_generic_buff_while : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_buff_while);

    bool Validate(SpellInfo const* info) override
    {
        BuffWhile const* rule = BuffWhileRule(info->Id);
        return rule && ValidateSpellInfo({ rule->Condition, rule->Buff });
    }

    void Sync()
    {
        BuffWhile const* rule = BuffWhileRule(GetId());
        if (!rule)
            return;
        Unit* unit = GetTarget();
        bool const condition = unit->HasAura(rule->Condition);
        bool const buffed = unit->HasAura(rule->Buff, unit->GetGUID());
        if (condition && !buffed)
            unit->CastSpell(unit, rule->Buff, true);
        else if (!condition && buffed)
            unit->RemoveAurasDueToSpell(rule->Buff, unit->GetGUID());
    }

    void HandleTick(AuraEffect const* )
    {
        PreventDefaultAction();
        Sync();
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (BuffWhile const* rule = BuffWhileRule(GetId()))
            GetTarget()->RemoveAurasDueToSpell(rule->Buff, GetTarget()->GetGUID());
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_generic_buff_while::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_generic_buff_while::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 MOLDED_BY_DARKNESS_BUFF = 299191;
constexpr std::array<FamilyMatch, 4> MOLDED_DOTS = {{
    { SPELLFAMILY_WARLOCK, 0x00000002, 0, 0 },
    { SPELLFAMILY_WARLOCK, 0, 0x00000100, 0 },
    { SPELLFAMILY_PRIEST, 0, 0x00000400, 0 },
    { SPELLFAMILY_PRIEST, 0x00008000, 0, 0 },
}};

int32 MoldedByDarknessPct(Unit* target, Unit* attacker, SpellInfo const* info)
{
    if (!target || !std::any_of(MOLDED_DOTS.begin(), MOLDED_DOTS.end(),
        [info](FamilyMatch const& dot) { return Matches(info, dot); }))
        return 0;
    AuraEffect const* buff = attacker->GetAuraEffect(MOLDED_BY_DARKNESS_BUFF, EFFECT_0);
    if (!buff)
        return 0;
    int32 present = 0;
    for (FamilyMatch const& dot : MOLDED_DOTS)
        for (AuraEffect const* effect : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_DAMAGE))
            if (effect->GetCasterGUID() == attacker->GetGUID() && Matches(effect->GetSpellInfo(), dot))
            {
                ++present;
                break;
            }
    return buff->GetAmount() * present;
}

constexpr uint32 FLAMESTRIKE_FIRST = 2120;

class spell_dummyfix_generic_scorched_ground : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_scorched_ground);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Player* player = GetTarget()->ToPlayer();
        return player && eventInfo.GetProcTarget() && HighestKnownRank(player, FLAMESTRIKE_FIRST);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        Unit* target = eventInfo.GetProcTarget();
        if (!player || !target)
            return;
        if (uint32 const flamestrike = HighestKnownRank(player, FLAMESTRIKE_FIRST))
            player->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), flamestrike, true,
                nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_scorched_ground::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_scorched_ground::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr std::array<uint32, 2> FEL_CLEAVES = { 276066, 984167 };

class spell_dummyfix_generic_tempered_by_chaos : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_tempered_by_chaos);

    bool CheckProc(ProcEventInfo& )
    {
        return GetTarget()->HasAura(MOLTEN_CORE);
    }

    void ResetFelCleave(AuraEffect const* , ProcEventInfo& )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        for (uint32 first : FEL_CLEAVES)
            for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(first); rank; rank = rank->GetNextRankSpell())
                if (player->HasSpellCooldown(rank->Id))
                    player->RemoveSpellCooldown(rank->Id, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_tempered_by_chaos::CheckProc);
        AfterEffectProc += AuraEffectProcFn(spell_dummyfix_generic_tempered_by_chaos::ResetFelCleave, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 VIOLENT_COMBO_POINT = 276313;

class spell_dummyfix_generic_violent_combo : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_violent_combo);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return GetTarget()->IsPlayer() && info && info->NeedsComboPoints() && eventInfo.GetProcTarget() &&
            eventInfo.GetProcTarget() != GetTarget();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* player = GetTarget();
        ObjectGuid const targetGuid = eventInfo.GetProcTarget()->GetGUID();
        player->m_Events.AddEventAtOffset([player, targetGuid]()
        {
            Unit* target = ObjectAccessor::GetUnit(*player, targetGuid);
            if (target && target->IsAlive())
                player->CastSpell(target, VIOLENT_COMBO_POINT, true);
        }, 100ms);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_violent_combo::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_violent_combo::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

bool KnowsAnyRank(Player const* player, uint32 spell)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spell)); rank;
         rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            return true;
    return false;
}

class spell_dummyfix_generic_learn_with : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_learn_with);

    bool _taught = false;

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ uint32(info->Effects[EFFECT_0].MiscValue), uint32(info->Effects[EFFECT_0].MiscValueB) });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        uint32 const required = uint32(aurEff->GetMiscValue());
        uint32 const taught = uint32(GetSpellInfo()->Effects[aurEff->GetEffIndex()].MiscValueB);
        if (!player || player->HasSpell(taught) || !KnowsAnyRank(player, required))
            return;
        player->learnSpell(taught, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught)
            return;
        _taught = false;
        player->removeSpell(uint32(GetSpellInfo()->Effects[aurEff->GetEffIndex()].MiscValueB), SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_generic_learn_with::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_generic_learn_with::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

struct TargetIcd
{
    uint32 Enchant;
    uint32 Marker;
};

constexpr std::array<TargetIcd, 2> TARGET_ICDS = {{ { 965505, 983896 }, { 84506, 983906 } }};

class spell_dummyfix_generic_target_icd : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_target_icd);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        if (!target || target == GetTarget())
            return false;
        for (TargetIcd const& icd : TARGET_ICDS)
            if (icd.Enchant == GetId())
                return !target->HasAura(icd.Marker, GetTarget()->GetGUID());
        return true;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_target_icd::CheckProc);
    }
};

constexpr std::array<uint32, 2> SAVAGE_ROARS = { 52610, 1152610 };

class spell_dummyfix_generic_savage_roar_duration : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_savage_roar_duration);

    void HandleDummy(SpellEffIndex )
    {
        for (uint32 id : SAVAGE_ROARS)
            if (Aura* roar = GetCaster()->GetAura(id, GetCaster()->GetGUID()))
            {
                int32 const duration = roar->GetDuration() + 6000;
                if (duration > roar->GetMaxDuration())
                    roar->SetMaxDuration(duration);
                roar->SetDuration(duration);
            }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_savage_roar_duration::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

constexpr std::array<uint32, 2> SHADOW_DANCES = { 51713, 1151713 };
constexpr uint32 ROGUE_BACKSTAB_FLAG = 0x00000004;

class spell_dummyfix_generic_assuaging_shadows : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_assuaging_shadows);

    void HandleDummy(SpellEffIndex )
    {
        if (Player* player = GetCaster()->ToPlayer())
            for (uint32 id : SHADOW_DANCES)
                if (player->HasSpellCooldown(id))
                    player->ModifySpellCooldown(id, -1000);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_assuaging_shadows::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_generic_assuaging_shadows_proc : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_assuaging_shadows_proc);

    bool CheckBackstab(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        return Matches(eventInfo.GetSpellInfo(), { SPELLFAMILY_ROGUE, ROGUE_BACKSTAB_FLAG, 0, 0 });
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_dummyfix_generic_assuaging_shadows_proc::CheckBackstab, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummyfix_generic_bane_of_the_wicked : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_bane_of_the_wicked);

    Milliseconds _expires = 0ms;

    void HandleApply(AuraEffect const* , AuraEffectHandleModes mode)
    {
        Milliseconds const now = GameTime::GetGameTimeMS();
        if (mode & AURA_EFFECT_HANDLE_REAL)
        {
            _expires = now + Milliseconds(GetDuration());
            return;
        }
        GetAura()->SetDuration(int32(std::max<int64>(1, (_expires - now).count())));
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_generic_bane_of_the_wicked::HandleApply, EFFECT_0,
            SPELL_AURA_MOD_DAMAGE_FROM_CASTER, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

class spell_dummyfix_generic_cauterize : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_cauterize);

    void HandleDummy(SpellEffIndex )
    {
        Unit* ally = GetHitUnit();
        if (!ally)
            return;
        for (auto const& [id, application] : ally->GetAppliedAuras())
        {
            Aura* aura = application->GetBase();
            if (!application->IsPositive() &&
                (aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (1 << MECHANIC_BLEED)))
            {
                ally->RemoveAura(application, AURA_REMOVE_BY_ENEMY_SPELL);
                return;
            }
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_cauterize::HandleDummy, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_generic_stormcloak : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_stormcloak);

    void CalcAmount(AuraEffect const* , int32& amount, bool& )
    {
        amount = -1;
    }

    void Absorb(AuraEffect* , DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        absorbAmount = 0;
        if (dmgInfo.GetDamage() && roll_chance_i(int32(GetSpellInfo()->ProcChance)))
            absorbAmount = CalculatePct(dmgInfo.GetDamage(), GetSpellInfo()->Effects[EFFECT_2].CalcValue());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_generic_stormcloak::CalcAmount, EFFECT_2,
            SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_dummyfix_generic_stormcloak::Absorb, EFFECT_2);
    }
};

class spell_dummyfix_generic_timeguard : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_timeguard);

    uint8 _used = 0;

    void CalcAmount(AuraEffect const* , int32& amount, bool& )
    {
        amount = -1;
    }

    void Absorb(AuraEffect* , DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        absorbAmount = 0;
        Unit* ally = GetTarget();
        if (_used >= 3 || !dmgInfo.GetDamage() || dmgInfo.GetDamageType() == DOT)
            return;
        uint32 const threshold = ally->CountPctFromMaxHealth(GetSpellInfo()->Effects[EFFECT_1].CalcValue());
        if (ally->GetHealth() > dmgInfo.GetDamage() && ally->GetHealth() - dmgInfo.GetDamage() >= threshold)
            return;
        absorbAmount = CalculatePct(dmgInfo.GetDamage(), GetSpellInfo()->Effects[EFFECT_2].CalcValue());
        if (++_used >= 3)
            GetAura()->SetDuration(1);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_generic_timeguard::CalcAmount, EFFECT_2,
            SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_dummyfix_generic_timeguard::Absorb, EFFECT_2);
    }
};

class spell_dummyfix_generic_celestial_form : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_celestial_form);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return GetTarget()->IsPlayer() && !(eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) &&
            eventInfo.GetHealInfo() && eventInfo.GetHealInfo()->GetHeal();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        uint32 const now = GameTime::GetGameTimeMS().count();
        std::vector<std::pair<uint32, int32>> cuts;
        for (auto const& [id, cooldown] : player->GetSpellCooldownMap())
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            if (!info || cooldown.end <= now ||
                !(info->GetSchoolMask() & (SPELL_SCHOOL_MASK_ARCANE | SPELL_SCHOOL_MASK_NATURE)))
                continue;
            int32 const cut = int32(CalculatePct(cooldown.end - now, aurEff->GetAmount()));
            if (cut > 0)
                cuts.emplace_back(id, cut);
        }
        for (auto const& [id, cut] : cuts)
            player->ModifySpellCooldown(id, -cut);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_celestial_form::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_celestial_form::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 THUNDER_AND_LIGHTNING = 954218;
constexpr uint32 LIGHTNING_SHIELD_FIRST = 324;
constexpr std::array<uint32, 2> SHOCKWAVE_DAMAGE = { 846968, 846969 };

int32 ThunderAndLightningPct(Unit* , Unit* attacker, SpellInfo const* info)
{
    if (!Matches(info, { SPELLFAMILY_WARRIOR, 0x00000080, 0x00008000, 0 }) &&
        std::find(SHOCKWAVE_DAMAGE.begin(), SHOCKWAVE_DAMAGE.end(), info->Id) == SHOCKWAVE_DAMAGE.end())
        return 0;
    AuraEffect const* talent = attacker->GetAuraEffect(THUNDER_AND_LIGHTNING, EFFECT_1);
    Aura const* shield = attacker->GetAuraOfRankedSpell(LIGHTNING_SHIELD_FIRST);
    if (!talent || !shield)
        return 0;
    return talent->GetAmount() * int32(shield->GetCharges());
}

constexpr uint32 DIMENSIONAL_DIVERGENCE_SLOW = 281122;
constexpr uint32 DIMENSIONAL_DIVERGENCE_SPEED = 281123;

class spell_dummyfix_generic_dimensional_divergence : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_generic_dimensional_divergence);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DIMENSIONAL_DIVERGENCE_SLOW, DIMENSIONAL_DIVERGENCE_SPEED });
    }

    void HandleSwap(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || target == caster || !target->IsPlayer())
            return;
        if (caster->IsValidAttackTarget(target))
        {
            caster->CastSpell(target, DIMENSIONAL_DIVERGENCE_SLOW, true);
            caster->CastSpell(caster, DIMENSIONAL_DIVERGENCE_SPEED, true);
        }
        ObjectGuid const targetGuid = target->GetGUID();
        caster->m_Events.AddEventAtOffset([caster, targetGuid]()
        {
            Unit* other = ObjectAccessor::GetUnit(*caster, targetGuid);
            if (!other || !other->IsAlive() || !caster->IsAlive())
                return;
            Position const casterAt = caster->GetPosition();
            Position const otherAt = other->GetPosition();
            caster->NearTeleportTo(otherAt.GetPositionX(), otherAt.GetPositionY(), otherAt.GetPositionZ(),
                caster->GetOrientation());
            other->NearTeleportTo(casterAt.GetPositionX(), casterAt.GetPositionY(), casterAt.GetPositionZ(),
                other->GetOrientation());
        }, 1ms);
    }

    void PreventTeleport(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_dimensional_divergence::HandleSwap, EFFECT_0,
            SPELL_EFFECT_DUMMY);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_dimensional_divergence::PreventTeleport, EFFECT_1,
            SPELL_EFFECT_TELEPORT_UNITS);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_generic_dimensional_divergence::PreventTeleport, EFFECT_2,
            SPELL_EFFECT_TELEPORT_UNITS);
    }
};

constexpr uint32 HERO_SHADOW_MARK = 832713;
constexpr uint32 SHADOWS_EMBRACE = 832717;
constexpr uint32 SHADOW_OF_DEATH = 986229;
constexpr uint32 WCR_ASSUAGING_SHADOWS_BUFF = 1571148;
constexpr std::array<uint32, 2> SHADOWSTEPS = { 36554, 1136554 };
constexpr uint32 ROGUE_AMBUSH_FLAG = 0x00000200;
constexpr uint32 DRUID_RAVAGE_FLAG = 0x00010000;

class spell_dummyfix_generic_shadow_mark : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_generic_shadow_mark);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SHADOWS_EMBRACE, SHADOW_OF_DEATH, WCR_ASSUAGING_SHADOWS_BUFF });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* actor = eventInfo.GetActor();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!actor || actor->GetGUID() != GetCasterGUID())
            return false;
        if (Matches(info, { SPELLFAMILY_ROGUE, ROGUE_AMBUSH_FLAG, 0, 0 }))
            return true;
        return GetId() == HERO_SHADOW_MARK && Matches(info, { SPELLFAMILY_DRUID, DRUID_RAVAGE_FLAG, 0, 0 });
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* marker = eventInfo.GetActor();
        if (GetId() != HERO_SHADOW_MARK)
        {
            marker->CastSpell(marker, WCR_ASSUAGING_SHADOWS_BUFF, true);
            return;
        }
        if (Player* player = marker->ToPlayer())
            for (uint32 id : SHADOWSTEPS)
                if (player->HasSpellCooldown(id))
                    player->RemoveSpellCooldown(id, true);
        marker->CastSpell(marker, SHADOWS_EMBRACE, true);
        Unit* target = GetTarget();
        marker->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), SHADOW_OF_DEATH, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_generic_shadow_mark::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_generic_shadow_mark::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
class dummyfix_generic_unit_hooks : public UnitScript
{
public:
    dummyfix_generic_unit_hooks() : UnitScript("dummyfix_generic_unit_hooks", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (damage <= 0 || !attacker || !info)
            return;
        if (int32 const pct = PestilentReprisalPct(target, attacker, info))
            AddPct(damage, pct);
        if (int32 const pct = CataclysmicPowerPct(target, attacker, info))
            AddPct(damage, pct);
        if (int32 const pct = ThunderAndLightningPct(target, attacker, info))
            AddPct(damage, pct);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!damage || !attacker || !info)
            return;
        if (int32 const pct = MoldedByDarknessPct(target, attacker, info))
            AddPct(damage, pct);
    }
};

}

void ApplyAscensionDummyFixGenericContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 280100:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 250;
            }
            break;
        case 299944:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 500;
            }
            break;
        case 299190:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = MOLDED_BY_DARKNESS_BUFF;
            }
            break;
        case 299191:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER)
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            break;
        case 299180:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 299181;
            }
            break;
        case 299181:
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
                !spellInfo->Effects[EFFECT_1].SpellClassMask)
                spellInfo->Effects[EFFECT_1].SpellClassMask = flag96(0x00400000, 0, 0);
            break;
        case 299988:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 500;
            }
            break;
        case 280110:
        case 280120:
            if (spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_SCHOOL_ABSORB;
                spellInfo->Effects[EFFECT_2].MiscValue = SPELL_SCHOOL_MASK_ALL;
            }
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_SCHOOL_ABSORB)
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            break;
        case 84810:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 84808;
            }
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixGenericScripts()
{
    RegisterSpellScript(spell_dummyfix_generic_cast_on_use);
    RegisterSpellScript(spell_dummyfix_generic_stack_threshold);
    RegisterSpellScript(spell_dummyfix_generic_overloaded);
    RegisterSpellScript(spell_dummyfix_generic_standing_still);
    RegisterSpellScript(spell_dummyfix_generic_shoulder_the_burden);
    RegisterSpellScript(spell_dummyfix_generic_xorothian_sigil);
    RegisterSpellScript(spell_dummyfix_generic_arcane_breach);
    RegisterSpellScript(spell_dummyfix_generic_bonds_of_justice);
    RegisterSpellScript(spell_dummyfix_generic_lunar_spirits);
    RegisterSpellScript(spell_dummyfix_generic_lunar_spirits_spread);
    RegisterSpellScript(spell_dummyfix_generic_impeccable_timing_periodic);
    RegisterSpellScript(spell_dummyfix_generic_impeccable_timing);
    RegisterSpellScript(spell_dummyfix_generic_blessing_of_the_divines);
    RegisterSpellScript(spell_dummyfix_generic_blessing_of_the_divines_proc);
    RegisterSpellScript(spell_dummyfix_generic_genesis_barkskin);
    RegisterSpellScript(spell_dummyfix_generic_bear_form_proc);
    RegisterSpellScript(spell_dummyfix_generic_raising_hell);
    RegisterSpellScript(spell_dummyfix_generic_shadow_core);
    RegisterSpellScript(spell_dummyfix_generic_void_teleportation);
    RegisterSpellScript(spell_dummyfix_generic_deadly_leap);
    new dummyfix_generic_unit_hooks();
    RegisterSpellScript(spell_dummyfix_generic_elemental_reload);
    RegisterSpellScript(spell_dummyfix_generic_finale);
    RegisterSpellScript(spell_dummyfix_generic_buff_while);
    RegisterSpellScript(spell_dummyfix_generic_scorched_ground);
    RegisterSpellScript(spell_dummyfix_generic_tempered_by_chaos);
    RegisterSpellScript(spell_dummyfix_generic_violent_combo);
    RegisterSpellScript(spell_dummyfix_generic_learn_with);
    RegisterSpellScript(spell_dummyfix_generic_target_icd);
    RegisterSpellScript(spell_dummyfix_generic_savage_roar_duration);
    RegisterSpellScript(spell_dummyfix_generic_assuaging_shadows);
    RegisterSpellScript(spell_dummyfix_generic_assuaging_shadows_proc);
    RegisterSpellScript(spell_dummyfix_generic_bane_of_the_wicked);
    RegisterSpellScript(spell_dummyfix_generic_cauterize);
    RegisterSpellScript(spell_dummyfix_generic_stormcloak);
    RegisterSpellScript(spell_dummyfix_generic_timeguard);
    RegisterSpellScript(spell_dummyfix_generic_celestial_form);
    RegisterSpellScript(spell_dummyfix_generic_dimensional_divergence);
    RegisterSpellScript(spell_dummyfix_generic_shadow_mark);
}
