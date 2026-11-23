/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "GameTime.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Timer.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <limits>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace
{
constexpr uint32 MAGE_FROSTBOLT_FLAG0 = 0x00000020;
constexpr uint32 MAGE_CONE_OF_COLD_FLAG0 = 0x00000200;
constexpr uint32 MAGE_ICE_LANCE_FLAG0 = 0x00020000;
constexpr uint32 MAGE_FROSTFIRE_BOLT_FLAG1 = 0x00001000;
constexpr uint32 MAGE_ARCANE_BARRAGE_FLAG1 = 0x00008000;
constexpr uint32 MAGE_DEEP_FREEZE_FLAG1 = 0x00100000;
constexpr uint32 DRUID_MOONFIRE_FLAG0 = 0x00000002;
constexpr uint32 DRUID_INSECT_SWARM_FLAG0 = 0x00200000;

int32 DbcPlusBonus(SpellInfo const* info, uint8 effect, float bonus)
{
    return info->Effects[effect].BasePoints + int32(bonus);
}

int32 ExactAmount(SpellInfo const* info, uint8 effect, int32 amount)
{
    return amount - (info->Effects[effect].DieSides == 1 ? 1 : 0);
}

void CastAtTargetAndPosition(Unit* caster, Unit* target, SpellInfo const* info, int32 bp0, AuraEffect const* aurEff)
{
    SpellCastTargets targets;
    targets.SetUnitTarget(target);
    targets.SetDst(*target);
    CustomSpellValues values;
    values.AddSpellMod(SPELLVALUE_BASE_POINT0, bp0);
    caster->CastSpell(targets, info, &values, TRIGGERED_FULL_MASK, nullptr, aurEff);
}

struct FrostBombRule
{
    uint32 Bomb;
    uint32 Explosion;
    int32 PlayerDurationMs;
};

constexpr std::array<FrostBombRule, 3> FROST_BOMBS = {{
    { 271936, 271949, 0 },
    { 954263, 954270, 0 },
    { 1569556, 1569559, 4000 },
}};

FrostBombRule const* FrostBombByBomb(uint32 id)
{
    for (FrostBombRule const& rule : FROST_BOMBS)
        if (rule.Bomb == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_mage_frost_bomb : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_frost_bomb);

    bool Validate(SpellInfo const* info) override
    {
        FrostBombRule const* rule = FrostBombByBomb(info->Id);
        return rule && ValidateSpellInfo({ rule->Explosion });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        FrostBombRule const* rule = FrostBombByBomb(GetId());
        if (!rule || !rule->PlayerDurationMs || !GetTarget()->IsPlayer() || GetMaxDuration() <= rule->PlayerDurationMs)
            return;
        SetMaxDuration(rule->PlayerDurationMs);
        SetDuration(rule->PlayerDurationMs);
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        AuraRemoveMode const removeMode = GetTargetApplication()->GetRemoveMode();
        if (removeMode != AURA_REMOVE_BY_ENEMY_SPELL && removeMode != AURA_REMOVE_BY_EXPIRE)
            return;
        FrostBombRule const* rule = FrostBombByBomb(GetId());
        if (Unit* caster = GetCaster(); rule && caster)
            caster->CastSpell(GetTarget(), rule->Explosion, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_mage_frost_bomb::HandleApply, EFFECT_FIRST_FOUND,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_mage_frost_bomb::HandleRemove, EFFECT_FIRST_FOUND,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 FIRE_WALK_TALENT = 283296;
constexpr uint32 FIRE_WALK_ENCHANT = 952120;
constexpr uint32 FLAMEBURST_FIRST = 283012;
constexpr uint32 FLAMEBURST_LAST = 283020;

bool CastingFlameburst(Unit* caster)
{
    for (CurrentSpellTypes type : { CURRENT_GENERIC_SPELL, CURRENT_CHANNELED_SPELL })
        if (Spell const* spell = caster->GetCurrentSpell(type))
            if (spell->GetSpellInfo()->Id >= FLAMEBURST_FIRST && spell->GetSpellInfo()->Id <= FLAMEBURST_LAST)
                return true;
    return false;
}

class spell_dummyfix_mage_fire_walk_with_me : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_fire_walk_with_me);

    void HandleSpeedArea(SpellEffIndex effIndex)
    {
        Unit* caster = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        if (caster->HasAura(FIRE_WALK_TALENT) || (caster->HasAura(FIRE_WALK_ENCHANT) && !CastingFlameburst(caster)))
            return;
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_mage_fire_walk_with_me::HandleSpeedArea, EFFECT_1,
            SPELL_EFFECT_PERSISTENT_AREA_AURA);
    }
};

struct StoredBombRule
{
    uint32 Bomb;
    uint32 Explosion;
    uint32 Restore;
    uint32 StoredPct;
};

constexpr std::array<StoredBombRule, 2> STORED_BOMBS = {{
    { 284591, 982483, 0, 50 },
    { 1587677, 1587678, 1587679, 50 },
}};

StoredBombRule const* StoredBombByBomb(uint32 id)
{
    for (StoredBombRule const& rule : STORED_BOMBS)
        if (rule.Bomb == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_mage_stored_bomb : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_stored_bomb);

    uint64 _stored = 0;

    bool Validate(SpellInfo const* info) override
    {
        StoredBombRule const* rule = StoredBombByBomb(info->Id);
        return rule && ValidateSpellInfo({ rule->Explosion }) && (!rule->Restore || ValidateSpellInfo({ rule->Restore }));
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && (damage->GetSchoolMask() & SPELL_SCHOOL_MASK_ARCANE) &&
            eventInfo.GetActor() && eventInfo.GetActor()->GetGUID() == GetCasterGUID();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (StoredBombRule const* rule = StoredBombByBomb(GetId()))
            _stored += CalculatePct(uint64(eventInfo.GetDamageInfo()->GetDamage()), rule->StoredPct);
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        StoredBombRule const* rule = StoredBombByBomb(GetId());
        Unit* caster = GetCaster();
        if (!rule || !caster)
            return;
        if (rule->Restore)
            caster->CastSpell(caster, rule->Restore, true, nullptr, aurEff);
        SpellInfo const* explosion = sSpellMgr->GetSpellInfo(rule->Explosion);
        if (!_stored || !explosion)
            return;
        int32 const amount = int32(std::min<uint64>(_stored, uint64(std::numeric_limits<int32>::max())));
        CastAtTargetAndPosition(caster, GetTarget(), explosion, ExactAmount(explosion, EFFECT_0, amount), aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_stored_bomb::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_stored_bomb::HandleProc, EFFECT_1, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_mage_stored_bomb::HandleRemove, EFFECT_1, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 TIME_BOMB = 284591;
constexpr uint32 TIME_BOMB_COOLDOWN = 284592;

constexpr uint32 ICE_BARRAGE_ICICLES = 985180;
constexpr uint32 ICE_BARRAGE_ICICLE = 830445;
constexpr std::array<uint32, 3> RAY_OF_FROST = { 965680, 984513, 984514 };
constexpr Milliseconds ICICLE_INTERVAL = 200ms;

constexpr char IciclesLaunchingKey[] = "AscensionDummyFixMage.IciclesLaunching";

struct IciclesLaunching final : DataMap::Base
{
};

bool IsIceBarrageGenerator(SpellInfo const* info)
{
    if (std::find(RAY_OF_FROST.begin(), RAY_OF_FROST.end(), info->Id) != RAY_OF_FROST.end())
        return true;
    return info->SpellFamilyName == SPELLFAMILY_MAGE &&
        ((info->SpellFamilyFlags[0] & (MAGE_FROSTBOLT_FLAG0 | MAGE_CONE_OF_COLD_FLAG0)) ||
         (info->SpellFamilyFlags[1] & (MAGE_FROSTFIRE_BOLT_FLAG1 | MAGE_DEEP_FREEZE_FLAG1)));
}

bool IsIceLance(SpellInfo const* info)
{
    return info->SpellFamilyName == SPELLFAMILY_MAGE && (info->SpellFamilyFlags[0] & MAGE_ICE_LANCE_FLAG0);
}

void LaunchIcicles(Unit* mage, ObjectGuid targetGuid, uint8 left)
{
    Unit* target = ObjectAccessor::GetUnit(*mage, targetGuid);
    SpellInfo const* icicle = sSpellMgr->GetSpellInfo(ICE_BARRAGE_ICICLE);
    if (target && icicle && target->IsAlive() && mage->IsAlive() && mage->IsValidAttackTarget(target))
    {
        float const bonus = mage->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FROST) * 0.33f +
            mage->GetTotalAttackPowerValue(BASE_ATTACK) * 0.2145f;
        int32 const bp = DbcPlusBonus(icicle, EFFECT_0, bonus);
        mage->CastCustomSpell(target, ICE_BARRAGE_ICICLE, &bp, nullptr, nullptr, true);
    }
    if (left > 1)
    {
        mage->m_Events.AddEventAtOffset([mage, targetGuid, left]() { LaunchIcicles(mage, targetGuid, left - 1); },
            ICICLE_INTERVAL);
        return;
    }
    mage->CustomData.Erase(IciclesLaunchingKey);
}

class spell_dummyfix_mage_ice_barrage : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_ice_barrage);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ICE_BARRAGE_ICICLES, ICE_BARRAGE_ICICLE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return damage && damage->GetDamage() && info && eventInfo.GetActionTarget() &&
            (IsIceLance(info) || IsIceBarrageGenerator(info));
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* mage = GetTarget();
        if (mage->CustomData.Get<IciclesLaunching>(IciclesLaunchingKey))
            return;
        if (IsIceLance(eventInfo.GetSpellInfo()))
        {
            Aura* icicles = mage->GetAura(ICE_BARRAGE_ICICLES, mage->GetGUID());
            if (!icicles)
                return;
            uint8 const stored = icicles->GetStackAmount();
            icicles->Remove();
            mage->CustomData.GetDefault<IciclesLaunching>(IciclesLaunchingKey);
            LaunchIcicles(mage, eventInfo.GetActionTarget()->GetGUID(), stored);
            return;
        }
        mage->CastSpell(mage, ICE_BARRAGE_ICICLES, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_ice_barrage::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_ice_barrage::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr std::array<uint32, 2> TIMED_CHARGE = { 283434, 954636 };
constexpr uint32 TIMED_CHARGE_EXPLOSION = 954637;

class TimedChargeEvent final : public BasicEvent
{
public:
    TimedChargeEvent(Unit* mage, uint8 tries) : _mage(mage), _tries(tries) { }

    bool Execute(uint64 , uint32 ) override
    {
        if (!_mage->IsInWorld() || !_mage->IsAlive())
            return true;
        Player* player = _mage->ToPlayer();
        if (player && player->IsBeingTeleportedNear() && _tries > 0)
        {
            _mage->m_Events.AddEventAtOffset(new TimedChargeEvent(_mage, _tries - 1), 100ms);
            return true;
        }
        _mage->CastSpell(_mage, TIMED_CHARGE_EXPLOSION, true);
        return true;
    }

private:
    Unit* _mage;
    uint8 _tries;
};

class spell_dummyfix_mage_timed_charge : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_timed_charge);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TIMED_CHARGE_EXPLOSION });
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Unit* mage = GetTarget();
        if (std::none_of(TIMED_CHARGE.begin(), TIMED_CHARGE.end(), [mage](uint32 id) { return mage->HasAura(id); }))
            return;
        mage->m_Events.AddEventAtOffset(new TimedChargeEvent(mage, 20), 100ms);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_mage_timed_charge::HandleRemove, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_mage_timed_charge_damage : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_timed_charge_damage);

    void HandleDamage(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        SetEffectValue(GetEffectValue() + int32(caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE) * 0.16f +
            caster->GetTotalAttackPowerValue(BASE_ATTACK) * 0.104f));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_mage_timed_charge_damage::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 ELECTROCUTE_DAMAGE = 954385;
constexpr uint32 ELECTROCUTE_INCAPACITATE = 954387;

std::mutex ElectrocuteLock;
std::unordered_map<ObjectGuid, uint32> ElectrocuteIncapacitated;

bool ElectrocuteIncapacitateReady(ObjectGuid target, uint32 lockoutMs)
{
    std::lock_guard<std::mutex> lock(ElectrocuteLock);
    uint32 const now = getMSTime();
    for (auto itr = ElectrocuteIncapacitated.begin(); itr != ElectrocuteIncapacitated.end();)
    {
        if (getMSTimeDiff(itr->second, now) >= lockoutMs)
            itr = ElectrocuteIncapacitated.erase(itr);
        else
            ++itr;
    }
    if (ElectrocuteIncapacitated.count(target))
        return false;
    ElectrocuteIncapacitated[target] = now;
    return true;
}

class spell_dummyfix_mage_doused : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_doused);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ELECTROCUTE_DAMAGE, ELECTROCUTE_INCAPACITATE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetActor() &&
            eventInfo.GetActor()->GetGUID() == GetCasterGUID();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* mage = GetCaster();
        Unit* target = GetTarget();
        SpellInfo const* electrocute = sSpellMgr->GetSpellInfo(ELECTROCUTE_DAMAGE);
        if (!mage || !electrocute || !target->IsAlive())
            return;
        float const bonus = mage->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE) * 0.144f +
            mage->GetTotalAttackPowerValue(BASE_ATTACK) * 0.094f;
        int32 const bp = DbcPlusBonus(electrocute, EFFECT_0, bonus);
        mage->CastCustomSpell(target, ELECTROCUTE_DAMAGE, &bp, nullptr, nullptr, true, nullptr, aurEff);
        if (target->IsAlive() && ElectrocuteIncapacitateReady(target->GetGUID(), uint32(std::max(GetMaxDuration(), 0))))
            mage->CastSpell(target, ELECTROCUTE_INCAPACITATE, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_doused::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_doused::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 CRITICAL_CYCLES_TALENT = 283770;
constexpr uint32 CRITICAL_CYCLES_NATURE = 283772;
constexpr uint32 CRITICAL_CYCLES_ARCANE = 283773;
constexpr uint32 CRITICAL_CYCLES_ENCHANT = 977782;
constexpr int32 CRITICAL_CYCLES_ENCHANT_PCT = 50;
constexpr int32 CRITICAL_CYCLES_ENCHANT_PVP_PCT = 10;
constexpr std::array<uint32, 2> ECLIPSE_SOLAR = { 48517, 1148517 };
constexpr std::array<uint32, 2> ECLIPSE_LUNAR = { 48518, 1148518 };

bool HasAny(Unit const* unit, std::array<uint32, 2> const& auras)
{
    return std::any_of(auras.begin(), auras.end(), [unit](uint32 id) { return unit->HasAura(id); });
}

int32 CriticalCyclesBonus(Unit* target, Unit* attacker, SpellInfo const* info)
{
    bool const solar = HasAny(attacker, ECLIPSE_SOLAR);
    bool const lunar = HasAny(attacker, ECLIPSE_LUNAR);
    if (!solar && !lunar)
        return 0;
    int32 bonus = 0;
    if (attacker->HasAura(CRITICAL_CYCLES_TALENT))
    {
        bool const druid = info->SpellFamilyName == SPELLFAMILY_DRUID;
        uint32 const source = druid && solar && (info->SpellFamilyFlags[0] & DRUID_INSECT_SWARM_FLAG0) ?
            CRITICAL_CYCLES_NATURE : druid && lunar && (info->SpellFamilyFlags[0] & DRUID_MOONFIRE_FLAG0) ?
            CRITICAL_CYCLES_ARCANE : 0;
        if (SpellInfo const* value = source ? sSpellMgr->GetSpellInfo(source) : nullptr)
            bonus += value->Effects[EFFECT_0].CalcValue();
    }
    if (attacker->HasAura(CRITICAL_CYCLES_ENCHANT) && info->SpellFamilyName == SPELLFAMILY_DRUID &&
        ((solar && (info->SpellFamilyFlags[0] & DRUID_INSECT_SWARM_FLAG0)) ||
         (lunar && (info->SpellFamilyFlags[0] & DRUID_MOONFIRE_FLAG0))))
        bonus += target->IsPlayer() ? CRITICAL_CYCLES_ENCHANT_PVP_PCT : CRITICAL_CYCLES_ENCHANT_PCT;
    return bonus;
}

constexpr uint32 BATTLE_GLAIVE_STACK = 277556;
constexpr uint32 BATTLE_GLAIVE_READY = 277557;

class spell_dummyfix_mage_battle_glaive : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_battle_glaive);

    uint32 _lastSpellId = 0;
    int64 _lastSpellMs = 0;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ BATTLE_GLAIVE_STACK, BATTLE_GLAIVE_READY });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!info || !damage || !damage->GetDamage() || info->SpellFamilyName != SPELLFAMILY_WARRIOR ||
            info->HasAttribute(SPELL_ATTR0_ON_NEXT_SWING) || info->HasAttribute(SPELL_ATTR0_ON_NEXT_SWING_NO_DAMAGE))
            return false;
        return info->Id != _lastSpellId || GameTime::GetGameTimeMS().count() != _lastSpellMs;
    }

    void HandleCounter(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        _lastSpellId = eventInfo.GetSpellInfo()->Id;
        _lastSpellMs = GameTime::GetGameTimeMS().count();
        Unit* warrior = GetTarget();
        SpellInfo const* counter = sSpellMgr->GetSpellInfo(BATTLE_GLAIVE_STACK);
        Aura* stacks = warrior->GetAura(BATTLE_GLAIVE_STACK, warrior->GetGUID());
        if (stacks && stacks->GetStackAmount() >= std::max<uint32>(counter->StackAmount, 1))
        {
            stacks->Remove();
            warrior->CastSpell(warrior, BATTLE_GLAIVE_READY, true);
            return;
        }
        warrior->CastSpell(warrior, BATTLE_GLAIVE_STACK, true);
    }

    void HandleReady(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_battle_glaive::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_battle_glaive::HandleCounter, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_battle_glaive::HandleReady, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint64 FINAL_SHIELD_CC_MECHANICS = (1ULL << MECHANIC_CHARM) | (1ULL << MECHANIC_DISORIENTED) |
    (1ULL << MECHANIC_FEAR) | (1ULL << MECHANIC_SLEEP) | (1ULL << MECHANIC_STUN) | (1ULL << MECHANIC_FREEZE) |
    (1ULL << MECHANIC_KNOCKOUT) | (1ULL << MECHANIC_POLYMORPH) | (1ULL << MECHANIC_BANISH) |
    (1ULL << MECHANIC_SHACKLE) | (1ULL << MECHANIC_TURN) | (1ULL << MECHANIC_HORROR) | (1ULL << MECHANIC_SAPPED);
constexpr float FINAL_SHIELD_HEALTH_PCT = 20.0f;

class spell_dummyfix_mage_final_shield : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_final_shield);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* ally = eventInfo.GetActionTarget();
        return ally && ally != GetTarget() && ally->IsAlive() && ally->GetHealthPct() < FINAL_SHIELD_HEALTH_PCT &&
            GetTarget()->IsFriendlyTo(ally);
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* ally = eventInfo.GetActionTarget())
            ally->RemoveAurasWithMechanic(FINAL_SHIELD_CC_MECHANICS, AURA_REMOVE_BY_ENEMY_SPELL);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_final_shield::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_final_shield::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr std::array<uint32, 3> SHADOW_DANCE = { 51713, 1151713, 1251713 };

class spell_dummyfix_mage_dancer_in_the_dark : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_dancer_in_the_dark);

    void HandleTick(AuraEffect const* aurEff)
    {
        Player* rogue = GetTarget()->ToPlayer();
        if (!rogue || !rogue->HasStealthAura())
            return;
        int32 const step = -int32(aurEff->GetAmplitude()) * std::max(aurEff->GetAmount(), 1);
        for (uint32 dance : SHADOW_DANCE)
            if (rogue->HasSpellCooldown(dance))
                rogue->ModifySpellCooldown(dance, step);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_mage_dancer_in_the_dark::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

constexpr uint32 NATURAL_DESTRUCTION_TALENT = 283031;
constexpr uint32 NATURAL_DESTRUCTION_TALENT_BUFF = 283033;
constexpr uint32 NATURAL_DESTRUCTION_ENCHANT = 410400;
constexpr std::array<uint32, 2> NATURES_GRACE_BUFF = { 16886, 116886 };

class spell_dummyfix_mage_natures_grace_enchant_gate : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_natures_grace_enchant_gate);

    bool CheckEnchantEffect(AuraEffect const* , ProcEventInfo& )
    {
        return GetTarget()->HasAura(NATURAL_DESTRUCTION_ENCHANT);
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_dummyfix_mage_natures_grace_enchant_gate::CheckEnchantEffect,
            EFFECT_1, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 MAGE_FIRE_WARD_FLAG0 = 0x00000008;
constexpr uint32 MAGE_FROST_WARD_FLAG0 = 0x00000100;
constexpr std::array<uint32, 3> PRESENCE_OF_MIND = { 12043, 1112043, 1212043 };

class spell_dummyfix_mage_abjurers_ward_arcane : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_abjurers_ward_arcane);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!damage || !damage->GetAbsorb())
            return false;
        Unit* mage = GetTarget();
        for (AuraEffect const* ward : mage->GetAuraEffectsByType(SPELL_AURA_SCHOOL_ABSORB))
        {
            SpellInfo const* info = ward->GetSpellInfo();
            if (info->SpellFamilyName == SPELLFAMILY_MAGE &&
                (info->SpellFamilyFlags[0] & (MAGE_FIRE_WARD_FLAG0 | MAGE_FROST_WARD_FLAG0)) &&
                (uint32(ward->GetMiscValue()) & uint32(damage->GetSchoolMask())))
                return true;
        }
        return false;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Player* mage = GetTarget()->ToPlayer();
        if (!mage)
            return;
        for (uint32 pom : PRESENCE_OF_MIND)
            if (mage->HasSpellCooldown(pom))
                mage->ModifySpellCooldown(pom, aurEff->GetAmount());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_abjurers_ward_arcane::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_abjurers_ward_arcane::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 CLAD_IN_FROST_BUFF = 276011;
constexpr uint32 CLAD_IN_FROST_COOLDOWN = 299151;
constexpr std::array<uint32, 2> CLAD_IN_FROST_STANCES = { 48263, 1148263 };
constexpr ShapeshiftForm MANA_FORGED_BARRIER_FORM = ShapeshiftForm(20);
constexpr uint32 DK_ICEBOUND_FORTITUDE_FLAG0 = 0x00100000;
constexpr uint32 MAGE_ICE_BARRIER_FLAG1 = 0x00000001;

class spell_dummyfix_mage_clad_in_frost : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_clad_in_frost);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ CLAD_IN_FROST_BUFF });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info)
            return false;
        bool const iceBarrier = info->SpellFamilyName == SPELLFAMILY_MAGE &&
            (info->SpellFamilyFlags[1] & MAGE_ICE_BARRIER_FLAG1);
        bool const icebound = info->SpellFamilyName == SPELLFAMILY_DEATHKNIGHT &&
            (info->SpellFamilyFlags[0] & DK_ICEBOUND_FORTITUDE_FLAG0);
        Unit* owner = GetTarget();
        return (iceBarrier || icebound) && (owner->GetShapeshiftForm() == MANA_FORGED_BARRIER_FORM ||
            std::any_of(CLAD_IN_FROST_STANCES.begin(), CLAD_IN_FROST_STANCES.end(),
                [owner](uint32 id) { return owner->HasAura(id); }));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), CLAD_IN_FROST_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_clad_in_frost::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_clad_in_frost::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummyfix_mage_clad_in_frost_buff : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_clad_in_frost_buff);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ CLAD_IN_FROST_COOLDOWN });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_FROST);
    }

    void HandleProc(ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), CLAD_IN_FROST_COOLDOWN, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_clad_in_frost_buff::CheckProc);
        OnProc += AuraProcFn(spell_dummyfix_mage_clad_in_frost_buff::HandleProc);
    }
};

constexpr uint32 GROWING_LIGHT_BEACON_BONUS = 977990;
constexpr std::array<uint32, 4> BEACON_OF_LIGHT = { 53563, 1153563, 1253563, 1567798 };

class spell_dummyfix_mage_growing_light : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_growing_light);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ GROWING_LIGHT_BEACON_BONUS });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        ObjectGuid const paladin = GetTarget()->GetGUID();
        return target && std::any_of(BEACON_OF_LIGHT.begin(), BEACON_OF_LIGHT.end(),
            [target, paladin](uint32 id) { return target->HasAura(id, paladin); });
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* target = eventInfo.GetActionTarget())
            GetTarget()->CastSpell(target, GROWING_LIGHT_BEACON_BONUS, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_growing_light::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_growing_light::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 GLYPH_OF_MIRROR_IMAGE_CLASSLESS = 118704;
constexpr uint32 GLYPH_OF_MIRROR_IMAGE_STOCK = 63093;
constexpr uint32 MIRROR_IMAGE_EXTRA_COPY = 65047;

class spell_dummyfix_mage_mirror_image_glyph : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_mirror_image_glyph);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MIRROR_IMAGE_EXTRA_COPY });
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (caster->HasAura(GLYPH_OF_MIRROR_IMAGE_CLASSLESS) && !caster->HasAura(GLYPH_OF_MIRROR_IMAGE_STOCK))
            caster->CastSpell(caster, MIRROR_IMAGE_EXTRA_COPY, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_mage_mirror_image_glyph::HandleAfterCast);
    }
};

constexpr uint32 GLYPH_OF_ARCANE_BLAST_MOD = 118658;
constexpr uint32 MAGE_ARCANE_BLAST_BUFF_FLAG2 = 0x00000004;

Aura* ArcaneBlastBuff(Unit* mage)
{
    for (auto const& [id, application] : mage->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        SpellInfo const* info = aura->GetSpellInfo();
        if (aura->GetCasterGUID() == mage->GetGUID() && info->SpellFamilyName == SPELLFAMILY_MAGE &&
            (info->SpellFamilyFlags[2] & MAGE_ARCANE_BLAST_BUFF_FLAG2) && !info->IsPassive() && aura->GetDuration() > 0)
            return aura;
    }
    return nullptr;
}

class spell_dummyfix_mage_glyph_of_arcane_blast : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_glyph_of_arcane_blast);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ GLYPH_OF_ARCANE_BLAST_MOD });
    }

    static void Sync(Unit* mage)
    {
        Aura* buff = ArcaneBlastBuff(mage);
        if (!buff)
            return;
        Aura* mod = mage->GetAura(GLYPH_OF_ARCANE_BLAST_MOD, mage->GetGUID());
        if (!mod)
            mod = mage->AddAura(GLYPH_OF_ARCANE_BLAST_MOD, mage);
        if (!mod)
            return;
        mod->SetMaxDuration(buff->GetMaxDuration());
        mod->SetDuration(buff->GetDuration());
        if (AuraEffect* cut = mod->GetEffect(EFFECT_0))
            cut->ChangeAmount(cut->GetSpellInfo()->Effects[EFFECT_0].CalcValue() * int32(buff->GetStackAmount()));
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* mage = GetTarget();
        mage->m_Events.AddEventAtOffset([mage]() { Sync(mage); }, 200ms);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_glyph_of_arcane_blast::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 ECLIPSE_BOMBER = 275014;
constexpr uint32 SOLAR_BOMBER = 274985;
constexpr uint32 LUNAR_BOMBER = 274984;
constexpr uint32 LUNAR_FLAMES = 274983;
constexpr uint32 SOLAR_FLAMES = 275002;

constexpr uint32 FROSTFLAME_SHOCK_TALENT = 272446;
constexpr uint32 FROSTFLAME_SHOCK_BRAIN_FREEZE = 272448;
constexpr std::array<uint32, 6> FIREBALL_BANG = { 57761, 301119, 1157761, 1257761, 1579137, 1579163 };

constexpr uint32 FURY_OF_THE_LIGHT = 275463;
constexpr uint32 FURY_OF_THE_LIGHT_BONUS = 275429;
constexpr std::array<uint32, 4> DIVINE_ILLUMINATION = { 31842, 1131842, 1231842, 1575125 };

constexpr uint32 SPELLSTORM = 271709;
constexpr uint32 ARCANE_EVOKED = 271710;
constexpr uint32 FIRE_EVOKED = 271713;
constexpr std::array<uint32, 4> MISSILE_BARRAGE_BUFF = { 44401, 274595, 983720, 1144401 };

template <std::size_t N>
bool IsOneOf(uint32 id, std::array<uint32, N> const& ids)
{
    return std::find(ids.begin(), ids.end(), id) != ids.end();
}

struct OverridePair
{
    uint32 Enchant;
    uint8 Effect;
    uint32 Original;
    uint32 Replacement;
};

constexpr std::array<OverridePair, 6> MAGE_OVERRIDES = {{
    { 979775, 0, 30482, 978700 },
    { 979778, 0, 6117, 978701 },
    { 978724, 0, 2565, 922565 },
    { 997129, 0, 6343, 92806 },
    { 997129, 1, 324, 92815 },
    { 997129, 2, 17364, 92826 },
}};

constexpr uint32 BULWARK_ENCHANT = 978724;
constexpr uint32 BULWARK_ENERGY = 5;
constexpr uint32 BULWARK_COOLDOWN_MS = 1000;
std::mutex BulwarkLock;
std::unordered_map<ObjectGuid, uint32> BulwarkLastEnergize;

bool BulwarkReady(ObjectGuid player)
{
    std::lock_guard<std::mutex> lock(BulwarkLock);
    uint32 const now = getMSTime();
    auto const itr = BulwarkLastEnergize.find(player);
    if (itr != BulwarkLastEnergize.end() && getMSTimeDiff(itr->second, now) < BULWARK_COOLDOWN_MS)
        return false;
    BulwarkLastEnergize[player] = now;
    return true;
}

constexpr uint32 LEI_SHENS_LEGACY = 997129;
constexpr uint32 VOLATILE_DISCHARGE = 92832;

constexpr uint32 HYDRICLES = 982726;
constexpr uint32 FROSTBOLT_FIRST_RANK = 116;
constexpr uint32 FINGERS_OF_FROST_BUFF = 74396;

class spell_dummyfix_mage_hydricles_enchant : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_hydricles_enchant);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ HYDRICLES, FROSTBOLT_FIRST_RANK });
    }

    static bool KnowsFrostbolt(Player const* player)
    {
        for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(FROSTBOLT_FIRST_RANK); rank; rank = rank->GetNextRankSpell())
            if (player->HasSpell(rank->Id))
                return true;
        return false;
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (player && !player->HasSpell(HYDRICLES) && KnowsFrostbolt(player))
            player->learnSpell(HYDRICLES, true);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (Player* player = GetTarget()->ToPlayer())
            player->removeSpell(HYDRICLES, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_mage_hydricles_enchant::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_mage_hydricles_enchant::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_mage_hydricles : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_hydricles);

    void HandleAfterCast()
    {
        GetCaster()->RemoveAurasDueToSpellOrTwin(FINGERS_OF_FROST_BUFF);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_mage_hydricles::HandleAfterCast);
    }
};

class spell_dummyfix_mage_carbon_buildup : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_carbon_buildup);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Spell const* spell = eventInfo.GetProcSpell();
        return spell && eventInfo.GetSpellInfo() && spell->m_targets.GetUnitTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = eventInfo.GetProcSpell()->m_targets.GetUnitTarget();
        if (target && target->IsAlive())
            GetTarget()->CastSpell(target, eventInfo.GetSpellInfo()->Id, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_carbon_buildup::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_carbon_buildup::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 ARCANE_THUNDER_SEER = 997055;

constexpr std::array<uint32, 4> EARTHQUAKE_STUN_ICD = { 954528, 284617, 1589073, 2304528 };
constexpr uint8 TREMBLING_STUN_STACKS = 3;

class spell_dummyfix_mage_earthquake_tick : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_earthquake_tick);

    void HandleStun(SpellEffIndex effIndex)
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        if (!target)
            return;
        bool const icd = std::any_of(EARTHQUAKE_STUN_ICD.begin(), EARTHQUAKE_STUN_ICD.end(),
            [target](uint32 id) { return target->HasAura(id); });
        uint32 const tremblingId = GetSpellInfo()->Effects[EFFECT_1].TriggerSpell;
        Aura const* trembling = target->GetAura(tremblingId, caster->GetGUID());
        SpellInfo const* tremblingInfo = sSpellMgr->GetSpellInfo(tremblingId);
        uint8 const needed = tremblingInfo && tremblingInfo->StackAmount ? uint8(tremblingInfo->StackAmount) :
            TREMBLING_STUN_STACKS;
        if (icd || !trembling || trembling->GetStackAmount() < needed)
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_mage_earthquake_tick::HandleStun, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
    }
};

constexpr uint32 FROSTBITE_FREEZE = 12494;
constexpr uint32 FROSTBITE_FINAL_RANK = 12497;

class spell_dummyfix_mage_glacial_spike : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_glacial_spike);

    std::unordered_set<ObjectGuid> _outOfCombat;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FROSTBITE_FREEZE });
    }

    void SelectTargets(std::list<WorldObject*>& targets)
    {
        for (WorldObject* object : targets)
            if (Unit* unit = object->ToUnit(); unit && !unit->IsInCombat())
                _outOfCombat.insert(unit->GetGUID());
    }

    void HandleHit(SpellEffIndex )
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetCaster();
        if (!target || !caster || !_outOfCombat.count(target->GetGUID()))
            return;
        if (caster->GetAuraEffectOfRankedSpellOrTwin(FROSTBITE_FINAL_RANK, EFFECT_0) ||
            caster->HasAura(FROSTBITE_FINAL_RANK))
            caster->CastSpell(target, FROSTBITE_FREEZE, true);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_mage_glacial_spike::SelectTargets,
            EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_mage_glacial_spike::HandleHit, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 LICHPLAGUE = 280500;

int32 LichplagueBonus(Unit const* target, Unit const* attacker)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(LICHPLAGUE);
    if (!info)
        return 0;
    int32 diseases = 0;
    for (auto const& [id, application] : target->GetAppliedAuras())
    {
        Aura const* aura = application->GetBase();
        if (id != LICHPLAGUE && aura->GetCasterGUID() == attacker->GetGUID() &&
            aura->GetSpellInfo()->Dispel == DISPEL_DISEASE)
            ++diseases;
    }
    return diseases * info->Effects[EFFECT_1].CalcValue();
}

constexpr uint32 FOCUS_MAGIC_REBORN_PROC = 1154648;

class spell_dummyfix_mage_focus_magic_reborn : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_focus_magic_reborn);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FOCUS_MAGIC_REBORN_PROC });
    }

    bool CheckProc(ProcEventInfo& )
    {
        Unit* caster = GetCaster();
        return caster && caster->IsAlive() && caster != GetTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        if (Unit* caster = GetCaster())
            GetTarget()->CastSpell(caster, FOCUS_MAGIC_REBORN_PROC, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_focus_magic_reborn::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_focus_magic_reborn::HandleProc, EFFECT_0,
            SPELL_AURA_MOD_SPELL_CRIT_CHANCE);
    }
};

constexpr uint32 FLAMES_OF_THE_APOSTATE = 271206;
constexpr uint32 CLEANSING_FLAMES_OF_THE_APOSTATE = 271210;
constexpr std::size_t FIERY_SHIELD_MAX_ALLIES = 5;

class spell_dummyfix_mage_fiery_shield : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_fiery_shield);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        SpellInfo const* flames = sSpellMgr->GetSpellInfo(FLAMES_OF_THE_APOSTATE);
        Aura const* stacks = caster->GetAura(FLAMES_OF_THE_APOSTATE);
        if (!flames || !stacks || stacks->GetStackAmount() < std::max<uint32>(flames->StackAmount, 1))
        {
            targets.clear();
            return;
        }
        if (targets.size() > FIERY_SHIELD_MAX_ALLIES)
            targets.resize(FIERY_SHIELD_MAX_ALLIES);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_mage_fiery_shield::FilterTargets, EFFECT_0,
            TARGET_UNIT_DEST_AREA_ALLY);
    }
};

class spell_dummyfix_mage_cauterizing_embers : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_cauterizing_embers);

    void HandleArea(SpellEffIndex effIndex)
    {
        Unit* caster = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        if (!caster->HasAura(CLEANSING_FLAMES_OF_THE_APOSTATE))
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_mage_cauterizing_embers::HandleArea, EFFECT_0,
            SPELL_EFFECT_PERSISTENT_AREA_AURA);
    }
};

constexpr uint32 FROST_WARDING_ENCHANT = 1328332;
constexpr uint32 FROST_WARDING_TALENT = 11189;
constexpr uint32 FROST_WARDING_MANA_REBORN = 1157776;

class spell_dummyfix_mage_frost_warding_enchant : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_frost_warding_enchant);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FROST_WARDING_ENCHANT, FROST_WARDING_MANA_REBORN });
    }

    void HandleAbsorb(AuraEffect* aurEff, DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        Unit* target = GetTarget();
        AuraEffect const* enchant = target->GetAuraEffect(FROST_WARDING_ENCHANT, EFFECT_0);
        if (!enchant || target->GetAuraEffectOfRankedSpellOrTwin(FROST_WARDING_TALENT, EFFECT_0) || !dmgInfo.GetDamage())
            return;
        if (!roll_chance_i(enchant->GetSpellInfo()->Effects[EFFECT_1].CalcValue()))
            return;
        int32 bp = int32(dmgInfo.GetDamage());
        target->CastCustomSpell(target, FROST_WARDING_MANA_REBORN, &bp, nullptr, nullptr, true, nullptr, aurEff);
        absorbAmount = 0;
        dmgInfo.AbsorbDamage(bp);
        PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_dummyfix_mage_frost_warding_enchant::HandleAbsorb, EFFECT_0);
    }
};

constexpr uint32 ESOTERIC_POWER_DAMAGE = 1556016;
constexpr int32 ESOTERIC_POWER_CHANCE_PER_STACK = 10;

class spell_dummyfix_mage_esoteric_power : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_esoteric_power);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ESOTERIC_POWER_DAMAGE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Aura const* buff = ArcaneBlastBuff(GetTarget());
        return damage && damage->GetDamage() && eventInfo.GetActionTarget() && buff &&
            roll_chance_i(ESOTERIC_POWER_CHANCE_PER_STACK * int32(buff->GetStackAmount()));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SpellInfo const* bonus = sSpellMgr->GetSpellInfo(ESOTERIC_POWER_DAMAGE);
        int32 const amount = int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEff->GetAmount()));
        if (!bonus || amount <= 0)
            return;
        int32 const bp = ExactAmount(bonus, EFFECT_0, amount);
        GetTarget()->CastCustomSpell(eventInfo.GetActionTarget(), ESOTERIC_POWER_DAMAGE, &bp, nullptr, nullptr, true,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_esoteric_power::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_esoteric_power::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 DOOMHAMMERS_FURY = 271580;
constexpr uint32 MAGE_PYROBLAST_FLAG0 = 0x00400000;
constexpr uint32 SHAMAN_LAVA_BURST_FLAG1 = 0x00001000;

constexpr uint32 CRITICAL_TIME = 275398;
constexpr uint32 CHAIN_REACTION = 275400;

class spell_dummyfix_mage_living_bomb_explosion : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_mage_living_bomb_explosion);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ CHAIN_REACTION });
    }

    void HandleHit(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        if (Unit* target = GetHitUnit(); target && caster->HasAura(CRITICAL_TIME))
            caster->CastSpell(target, CHAIN_REACTION, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_mage_living_bomb_explosion::HandleHit, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 SHATTERED_BARRIER = 854787;
constexpr uint32 SHATTERED_BARRIER_SLOW = 55080;
constexpr uint32 SHATTERED_BARRIER_HASTE = 997627;

constexpr uint32 SABER_FANGS_COUNTER = 984697;
constexpr uint32 SABER_FANGS = 984698;

class spell_dummyfix_mage_saber_fangs : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_saber_fangs);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SABER_FANGS_COUNTER, SABER_FANGS });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetActionTarget() && eventInfo.GetActionTarget()->IsAlive();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* druid = GetTarget();
        Unit* enemy = eventInfo.GetActionTarget();
        SpellInfo const* counterInfo = sSpellMgr->GetSpellInfo(SABER_FANGS_COUNTER);
        Aura* counter = enemy->GetAura(SABER_FANGS_COUNTER, druid->GetGUID());
        if (counter && counter->GetStackAmount() >= std::max<uint32>(counterInfo->StackAmount, 1))
        {
            counter->Remove();
            if (!enemy->HasAura(SABER_FANGS, druid->GetGUID()))
                druid->CastSpell(enemy, SABER_FANGS, true, nullptr, aurEff);
            return;
        }
        druid->CastSpell(enemy, SABER_FANGS_COUNTER, true, nullptr, aurEff);
    }

    void HandleCounterEffect(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_mage_saber_fangs::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_saber_fangs::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_mage_saber_fangs::HandleCounterEffect, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 SPELL_SLINGER = 965503;
constexpr uint32 SPELL_SLINGER_BURST = 965509;
constexpr std::array<uint32, 6> MAGE_CLEARCASTING = { 12536, 983908, 983909, 1112536, 1212536, 1586519 };

void SpellSlingerBurst(Unit* mage)
{
    Player* player = mage->ToPlayer();
    SpellInfo const* burst = sSpellMgr->GetSpellInfo(SPELL_SLINGER_BURST);
    Unit* target = player ? player->GetSelectedUnit() : mage->GetVictim();
    if (!burst || !target || !target->IsAlive() || !mage->IsValidAttackTarget(target))
        return;
    float const bonus = mage->GetTotalAttackPowerValue(BASE_ATTACK) * 0.5f +
        mage->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE) * 0.7f;
    int32 const bp = DbcPlusBonus(burst, EFFECT_0, bonus);
    mage->CastCustomSpell(target, SPELL_SLINGER_BURST, &bp, nullptr, nullptr, true);
}

constexpr std::array<uint32, 2> FIERY_PAYBACK_LOW_HEALTH = { 44440, 44441 };
constexpr float FIERY_PAYBACK_HEALTH_PCT = 35.0f;

class spell_dummyfix_mage_fiery_payback_low_health : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_mage_fiery_payback_low_health);

    void CalcAmount(AuraEffect const* , int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        if (Unit* owner = GetUnitOwner(); owner && !owner->HealthBelowPct(int32(FIERY_PAYBACK_HEALTH_PCT)))
            amount = 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_mage_fiery_payback_low_health::CalcAmount, EFFECT_ALL,
            SPELL_AURA_ANY);
    }
};

void SyncFieryPayback(Unit* unit)
{
    bool const low = unit->HealthBelowPct(int32(FIERY_PAYBACK_HEALTH_PCT));
    for (uint32 id : FIERY_PAYBACK_LOW_HEALTH)
        if (Aura* aura = unit->GetAura(id))
            for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                if (AuraEffect* effect = aura->GetEffect(i))
                {
                    int32 const want = low ? aura->GetSpellInfo()->Effects[i].CalcValue(unit) : 0;
                    if (effect->GetAmount() != want)
                        effect->ChangeAmount(want);
                }
}

constexpr uint32 SCARED_STIFF = 978740;

class dummyfix_mage_unit_hooks : public UnitScript
{
public:
    dummyfix_mage_unit_hooks() : UnitScript("dummyfix_mage_unit_hooks", true,
        { UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_ON_AURA_APPLY,
          UNITHOOK_ON_AURA_REMOVE, UNITHOOK_ON_BLOCK, UNITHOOK_ON_HEALTH_CHANGED }) { }

    void OnHealthChanged(Unit* unit) override
    {
        if (unit && (unit->HasAura(FIERY_PAYBACK_LOW_HEALTH[0]) || unit->HasAura(FIERY_PAYBACK_LOW_HEALTH[1])))
            SyncFieryPayback(unit);
    }

    void OnBlock(Unit* victim, Unit* ) override
    {
        if (victim && victim->IsPlayer() && victim->HasAura(BULWARK_ENCHANT) && BulwarkReady(victim->GetGUID()))
            victim->EnergizeBySpell(victim, BULWARK_ENCHANT, BULWARK_ENERGY, POWER_ENERGY);
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (!unit || !aura)
            return;
        uint32 const id = aura->GetId();
        if (IsOneOf(id, NATURES_GRACE_BUFF) && unit->HasAura(NATURAL_DESTRUCTION_TALENT))
            unit->CastSpell(unit, NATURAL_DESTRUCTION_TALENT_BUFF, true);
        if (IsOneOf(id, ECLIPSE_SOLAR))
        {
            unit->RemoveAurasDueToSpell(LUNAR_FLAMES, unit->GetGUID());
            if (unit->HasAura(ECLIPSE_BOMBER))
                unit->CastSpell(unit, SOLAR_BOMBER, true);
        }
        if (IsOneOf(id, ECLIPSE_LUNAR))
        {
            unit->RemoveAurasDueToSpell(SOLAR_FLAMES, unit->GetGUID());
            if (unit->HasAura(ECLIPSE_BOMBER))
                unit->CastSpell(unit, LUNAR_BOMBER, true);
        }
        if (AuraEffect const* stiff = unit->GetAuraEffect(SCARED_STIFF, EFFECT_0); stiff && !aura->IsPassive() &&
            aura->GetMaxDuration() > 0 && (aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (1ULL << MECHANIC_FEAR)))
        {
            int32 const duration = int32(aura->GetMaxDuration() * (100 + stiff->GetAmount()) / 100);
            aura->SetMaxDuration(duration);
            aura->SetDuration(duration);
        }
        if (IsOneOf(id, FIREBALL_BANG) && unit->HasAura(FROSTFLAME_SHOCK_TALENT))
            unit->CastSpell(unit, FROSTFLAME_SHOCK_BRAIN_FREEZE, true);
        if (IsOneOf(id, DIVINE_ILLUMINATION) && unit->HasAura(FURY_OF_THE_LIGHT))
            unit->AddAura(FURY_OF_THE_LIGHT_BONUS, unit);
        if (IsOneOf(id, MISSILE_BARRAGE_BUFF) && unit->HasAura(ARCANE_THUNDER_SEER))
            unit->m_Events.AddEventAtOffset([unit, id]() { unit->RemoveAurasDueToSpell(id); }, 1ms);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* aurApp, AuraRemoveMode mode) override
    {
        if (!unit || !aurApp)
            return;
        Aura const* aura = aurApp->GetBase();
        uint32 const id = aura->GetId();
        if (IsOneOf(id, ECLIPSE_SOLAR) && !HasAny(unit, ECLIPSE_SOLAR))
            unit->RemoveAurasDueToSpell(SOLAR_BOMBER, unit->GetGUID());
        if (IsOneOf(id, ECLIPSE_LUNAR) && !HasAny(unit, ECLIPSE_LUNAR))
            unit->RemoveAurasDueToSpell(LUNAR_BOMBER, unit->GetGUID());
        if (IsOneOf(id, DIVINE_ILLUMINATION) && std::none_of(DIVINE_ILLUMINATION.begin(), DIVINE_ILLUMINATION.end(),
            [unit](uint32 di) { return unit->HasAura(di); }))
            unit->RemoveAurasDueToSpell(FURY_OF_THE_LIGHT_BONUS, unit->GetGUID());
        if (aura->GetCasterGUID() == unit->GetGUID() && aura->GetSpellInfo()->SpellFamilyName == SPELLFAMILY_MAGE &&
            (aura->GetSpellInfo()->SpellFamilyFlags[2] & MAGE_ARCANE_BLAST_BUFF_FLAG2) && !aura->IsPassive())
            unit->RemoveAurasDueToSpell(GLYPH_OF_ARCANE_BLAST_MOD, unit->GetGUID());
        bool const consumed = mode != AURA_REMOVE_BY_CANCEL && mode != AURA_REMOVE_BY_DEATH &&
            mode != AURA_REMOVE_BY_EXPIRE && aura->GetDuration() > 0;
        if (consumed && IsOneOf(id, MAGE_CLEARCASTING) && unit->HasAura(SPELL_SLINGER))
            SpellSlingerBurst(unit);
        if (mode == AURA_REMOVE_BY_ENEMY_SPELL && aura->GetSpellInfo()->SpellFamilyName == SPELLFAMILY_MAGE &&
            (aura->GetSpellInfo()->SpellFamilyFlags[1] & MAGE_ICE_BARRIER_FLAG1) &&
            aura->GetSpellInfo()->HasAura(SPELL_AURA_SCHOOL_ABSORB) && unit->HasAura(SHATTERED_BARRIER))
        {
            unit->CastSpell(unit, SHATTERED_BARRIER_SLOW, true);
            unit->CastSpell(unit, SHATTERED_BARRIER_HASTE, true);
        }
        if (consumed && unit->HasAura(SPELLSTORM))
        {
            if (IsOneOf(id, MISSILE_BARRAGE_BUFF))
                unit->CastSpell(unit, ARCANE_EVOKED, true);
            else if (IsOneOf(id, FIREBALL_BANG))
                unit->CastSpell(unit, FIRE_EVOKED, true);
        }
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || !damage)
            return;
        if (int32 const bonus = CriticalCyclesBonus(target, attacker, info); bonus > 0)
            AddPct(damage, bonus);
        if (info->Id == LICHPLAGUE)
            if (int32 const bonus = LichplagueBonus(target, attacker); bonus > 0)
                AddPct(damage, bonus);
    }

    void ModifySpellDamageTaken(Unit* , Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (attacker && info && damage > 0 &&
            ((info->SpellFamilyName == SPELLFAMILY_MAGE && (info->SpellFamilyFlags[0] & MAGE_PYROBLAST_FLAG0)) ||
             (info->SpellFamilyName == SPELLFAMILY_SHAMAN && (info->SpellFamilyFlags[1] & SHAMAN_LAVA_BURST_FLAG1))))
            if (AuraEffect const* fury = attacker->GetAuraEffect(DOOMHAMMERS_FURY, EFFECT_0))
                AddPct(damage, fury->GetAmount());
        if (attacker && info && damage > 0 && info->SpellFamilyName == SPELLFAMILY_DRUID &&
            (attacker->GetShapeshiftForm() == FORM_BEAR || attacker->GetShapeshiftForm() == FORM_DIREBEAR) &&
            attacker->HasAura(LEI_SHENS_LEGACY))
            attacker->CastSpell(attacker, VOLATILE_DISCHARGE, true);
        if (!attacker || !info || damage <= 0 || info->SpellFamilyName != SPELLFAMILY_MAGE ||
            !(info->SpellFamilyFlags[1] & MAGE_ARCANE_BARRAGE_FLAG1))
            return;
        Player* mage = attacker->ToPlayer();
        if (mage && mage->HasSpell(TIME_BOMB))
            mage->CastSpell(mage, TIME_BOMB_COOLDOWN, true);
    }
};
}

void ApplyAscensionDummyFixMageContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    for (OverridePair const& pair : MAGE_OVERRIDES)
    {
        if (pair.Enchant != spellInfo->Id)
            continue;
        SpellEffectInfo& effect = spellInfo->Effects[pair.Effect];
        if (effect.ApplyAuraName != SPELL_AURA_DUMMY || effect.MiscValue != int32(pair.Original))
            continue;
        effect.ApplyAuraName = SPELL_AURA_ASCENSION_OVERRIDE_SPELL;
        effect.BasePoints = int32(pair.Replacement);
        effect.MiscValueB = 0;
        effect.DieSides = 0;
        effect.RealPointsPerLevel = 0.0f;
        effect.PointsPerComboPoint = 0.0f;
    }

    switch (spellInfo->Id)
    {
        case 812592:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
                spellInfo->Effects[EFFECT_0].MiscValue = SPELLMOD_RANGE;
            }
            break;
        case 978432:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
                spellInfo->Effects[EFFECT_0].MiscValue = SPELLMOD_DOT;
                spellInfo->Effects[EFFECT_0].SpellClassMask = flag96(0, 0x00000400, 0);
            }
            break;
        case FURY_OF_THE_LIGHT_BONUS:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_CRIT_DAMAGE_BONUS)
                spellInfo->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_HOLY;
            break;
        case 273379:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_MELEE_HASTE;
            break;
        case 102224:
        case 102225:
        case 102226:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
                spellInfo->Effects[EFFECT_0].MiscValue = SPELLMOD_EFFECT1;
                spellInfo->Effects[EFFECT_0].SpellClassMask = flag96(0x00008000, 0, 0);
            }
            break;
        case 979764:
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
                spellInfo->Effects[EFFECT_1].MiscValue = SPELLMOD_CRIT_DAMAGE_BONUS;
                spellInfo->Effects[EFFECT_1].SpellClassMask = spellInfo->Effects[EFFECT_0].SpellClassMask;
            }
            break;
        case 44440:
        case 44441:
            spellInfo->CasterAuraState = 0;
            break;
        case 978740:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MECHANIC_DURATION_MOD;
                spellInfo->Effects[EFFECT_0].BasePoints = 49;
                spellInfo->Effects[EFFECT_0].DieSides = 1;
            }
            break;
        case TIMED_CHARGE_EXPLOSION:
            spellInfo->SchoolMask = SPELL_SCHOOL_MASK_ARCANE;
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixMageScripts()
{
    RegisterSpellScript(spell_dummyfix_mage_frost_bomb);
    RegisterSpellScript(spell_dummyfix_mage_fire_walk_with_me);
    RegisterSpellScript(spell_dummyfix_mage_stored_bomb);
    RegisterSpellScript(spell_dummyfix_mage_ice_barrage);
    RegisterSpellScript(spell_dummyfix_mage_timed_charge);
    RegisterSpellScript(spell_dummyfix_mage_timed_charge_damage);
    RegisterSpellScript(spell_dummyfix_mage_doused);
    RegisterSpellScript(spell_dummyfix_mage_battle_glaive);
    RegisterSpellScript(spell_dummyfix_mage_final_shield);
    RegisterSpellScript(spell_dummyfix_mage_dancer_in_the_dark);
    RegisterSpellScript(spell_dummyfix_mage_natures_grace_enchant_gate);
    RegisterSpellScript(spell_dummyfix_mage_abjurers_ward_arcane);
    RegisterSpellScript(spell_dummyfix_mage_clad_in_frost);
    RegisterSpellScript(spell_dummyfix_mage_clad_in_frost_buff);
    RegisterSpellScript(spell_dummyfix_mage_growing_light);
    RegisterSpellScript(spell_dummyfix_mage_mirror_image_glyph);
    RegisterSpellScript(spell_dummyfix_mage_glyph_of_arcane_blast);
    RegisterSpellScript(spell_dummyfix_mage_hydricles_enchant);
    RegisterSpellScript(spell_dummyfix_mage_hydricles);
    RegisterSpellScript(spell_dummyfix_mage_carbon_buildup);
    RegisterSpellScript(spell_dummyfix_mage_earthquake_tick);
    RegisterSpellScript(spell_dummyfix_mage_glacial_spike);
    RegisterSpellScript(spell_dummyfix_mage_focus_magic_reborn);
    RegisterSpellScript(spell_dummyfix_mage_fiery_shield);
    RegisterSpellScript(spell_dummyfix_mage_cauterizing_embers);
    RegisterSpellScript(spell_dummyfix_mage_frost_warding_enchant);
    RegisterSpellScript(spell_dummyfix_mage_esoteric_power);
    RegisterSpellScript(spell_dummyfix_mage_living_bomb_explosion);
    RegisterSpellScript(spell_dummyfix_mage_saber_fangs);
    RegisterSpellScript(spell_dummyfix_mage_fiery_payback_low_health);
    new dummyfix_mage_unit_hooks();
}
