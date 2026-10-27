/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRealmClock.h"
#include "AscensionWitchHunterCompletion.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
using namespace AscensionWitchHunter;

void Tracking(Player* player, bool night)
{
    uint32 tracking = 0;
    for (AuraEffect const* effect : player->GetAuraEffectsByType(SPELL_AURA_TRACK_CREATURES))
        if (effect->GetMiscValue() > 0 && effect->GetMiscValue() <= 32)
            tracking |= 1u << (effect->GetMiscValue() - 1);
    if (night && player->HasAura(562225))
        tracking |= 36 | 64;
    player->SetUInt32Value(PLAYER_TRACK_CREATURES, tracking);
}

constexpr uint32 SPELL_UNBROKEN = 707407;
constexpr uint32 SPELL_UNBROKEN_BUFF = 707487;
constexpr int32 UNBROKEN_AP_PERCENT = 20;
constexpr int32 UNBROKEN_TICK = 1000;
constexpr int32 UNBROKEN_BUFF_DURATION = 6000;

struct UnbrokenDecay
{
    int32 percent;
    uint32 ticks;
};
constexpr std::array<UnbrokenDecay, 3> UNBROKEN_DECAY = {{{20, 50}, {10, 5}, {5, 10}}};

class aura_ascension_witch_hunter_unbroken : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_hunter_unbroken);
    int32 _amount = 0;
    uint32 _ticks = 0;

    bool First(AuraEffect const* effect) const
    {
        for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
            if (GetEffect(i))
                return false;
        return true;
    }

    int32 Cap() const
    {
        Unit* owner = GetUnitOwner();
        return owner ? int32(owner->GetMaxHealth() * UNBROKEN_AP_PERCENT / 100) : 0;
    }

    void Refresh(Unit* owner, int32 amount)
    {
        if (!owner)
            return;
        if (amount <= 0)
        {
            owner->RemoveAurasDueToSpell(SPELL_UNBROKEN_BUFF);
            return;
        }
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, amount);
        values.AddSpellMod(SPELLVALUE_BASE_POINT1, amount);
        values.AddSpellMod(SPELLVALUE_AURA_DURATION, UNBROKEN_BUFF_DURATION);
        Unit* caster = GetCaster() ? GetCaster() : owner;
        caster->CastCustomSpell(SPELL_UNBROKEN_BUFF, values, owner, TRIGGERED_FULL_MASK);
    }

    bool Validate(SpellInfo const* spellInfo) override
    {
        std::array<int32, 3> misc = {5, 10, 20};
        if (!spellInfo || spellInfo->Id != SPELL_UNBROKEN || spellInfo->ProcFlags || !spellInfo->IsPassive() ||
            spellInfo->SpellFamilyName != uint32(CLASS_WITCH_HUNTER) + 6)
            return false;
        for (uint8 i = EFFECT_0; i <= EFFECT_2; ++i)
            if (!spellInfo->Effects[i].IsAura(SPELL_AURA_DUMMY) ||
                spellInfo->Effects[i].MiscValue != misc[i - EFFECT_0])
                return false;
        return ValidateSpellInfo({SPELL_UNBROKEN_BUFF});
    }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        _amount = 0;
        _ticks = 0;
        GetTarget()->RemoveAurasDueToSpell(SPELL_UNBROKEN_BUFF);
    }

    void Periodic(AuraEffect const* effect, bool& periodic, int32& amplitude)
    {
        if (!First(effect))
            return;
        periodic = true;
        amplitude = UNBROKEN_TICK;
    }

    void Tick(AuraEffect const* effect)
    {
        if (!First(effect))
            return;
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (!owner || !owner->IsAlive() || _amount <= 0)
            return;
        int32 cap = Cap();
        int32 percent = cap > 0 ? _amount * 100 / cap : 0;
        UnbrokenDecay const* decay = &UNBROKEN_DECAY.back();
        for (UnbrokenDecay const& row : UNBROKEN_DECAY)
            if (percent >= row.percent)
            {
                decay = &row;
                break;
            }
        if (++_ticks >= decay->ticks)
        {
            _ticks = 0;
            _amount = std::max(0, _amount - cap * decay->percent / 100);
        }
        Refresh(owner, _amount);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* owner = GetUnitOwner();
        return owner && damage && damage->GetDamage() && damage->GetVictim() == owner && damage->GetAttacker() &&
            damage->GetAttacker() != owner && !(eventInfo.GetTypeMask() & PROC_FLAG_TAKEN_PERIODIC);
    }

    void Proc(ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* owner = GetUnitOwner();
        int32 cap = Cap();
        if (!owner || !owner->IsAlive() || cap <= 0)
            return;
        _amount = cap;
        _ticks = 0;
        Refresh(owner, _amount);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_witch_hunter_unbroken::Apply, EFFECT_ALL,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_witch_hunter_unbroken::Periodic, EFFECT_ALL,
            SPELL_AURA_DUMMY);
        OnEffectPeriodic +=
            AuraEffectPeriodicFn(aura_ascension_witch_hunter_unbroken::Tick, EFFECT_ALL, SPELL_AURA_DUMMY);
        DoCheckProc += AuraCheckProcFn(aura_ascension_witch_hunter_unbroken::CheckProc);
        OnProc += AuraProcFn(aura_ascension_witch_hunter_unbroken::Proc);
    }
};

class aura_ascension_witch_hunter_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_hunter_lifecycle);
    std::array<uint64, 5> _debt = {};
    uint8 _tick = 0;
    bool _paying = false;
    uint32 _elapsed = 0;

    bool First(AuraEffect const* effect) const
    {
        for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
            if (GetEffect(i))
                return false;
        return true;
    }

    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        if ((GetId() == 807733 && effect->GetEffIndex() == EFFECT_1) || GetId() == 680492)
        {
            amount = -1;
            recalculate = false;
        }
        if (GetId() == 562225 && effect->GetEffIndex() == EFFECT_1)
            amount = AscensionRealmClock::IsNight() ? 100 : 0;
        if (Family(GetSpellInfo(), 2, 4) && effect->GetEffIndex() == EFFECT_0)
            if (Unit* caster = GetCaster())
                if (Player* modOwner = caster->GetSpellModOwner())
                    modOwner->ApplySpellMod(GetId(), SPELLMOD_DOT, amount);
    }

    void Periodic(AuraEffect const* effect, bool& periodic, int32& amplitude)
    {
        uint32 id = GetId();
        if ((id == 807733 && effect->GetEffIndex() == EFFECT_1) ||
            (First(effect) &&
             (id == 804185 || id == 562225 || id == 804068 || id == 807682 || (id >= 807705 && id <= 807710))))
        {
            periodic = true;
            amplitude = id == 804068 ? 1000 : 500;
            if (id == 807733)
                amplitude = 1000;
        }
    }

    void Pay(uint64 amount)
    {
        Unit* owner = GetTarget();
        if (!amount || !owner->IsAlive() || !owner->IsInWorld())
            return;
        _paying = true;
        Unit::DealDamage(owner, owner, uint32(std::min<uint64>(amount, std::numeric_limits<uint32>::max())), nullptr,
                         DOT, SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
        _paying = false;
    }

    void Tick(AuraEffect const* effect)
    {
        uint32 id = GetId();
        if (id == 807733 && effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            uint64 payment = _debt[_tick];
            _debt[_tick] = 0;
            _tick = (_tick + 1) % _debt.size();
            Pay(payment);
            return;
        }
        if (!First(effect))
            return;
        Unit* owner = GetTarget();
        Player* player = Owner(owner);
        if (id == 804185 && player)
        {
            PreventDefaultAction();
            bool night = AscensionRealmClock::IsNight();
            player->RemoveAurasDueToSpell(night ? 807231 : 807198);
            if (Aura* aura = player->GetAura(night ? 807198 : 807231))
                aura->RefreshDuration();
            else
                Cast(player, player, night ? 807198 : 807231);
        }
        if (id == 562225 && player)
        {
            PreventDefaultAction();
            Tracking(player, AscensionRealmClock::IsNight());
            GetEffect(EFFECT_1)->ChangeAmount(AscensionRealmClock::IsNight() ? 100 : 0);
        }
        if (id == 804068)
        {
            PreventDefaultAction();
            _elapsed = std::min(99u, _elapsed + 1);
            GetEffect(EFFECT_0)->ChangeAmount(int32(std::min(100u, 3u * (_elapsed + 1))));
        }
        if (id == 807682 || (id >= 807705 && id <= 807710))
        {
            PreventDefaultAction();
            if (owner->HealthBelowPct(10))
                if (Unit* caster = GetCaster())
                {
                    int32 base = effect->GetAmount();
                    Remove();
                    caster->CastCustomSpell(SPELL_BRAND_OF_THE_DAMNED_DAMAGE, SPELLVALUE_BASE_POINT0, base, owner,
                        TRIGGERED_FULL_MASK);
                }
        }
        if (Family(GetSpellInfo(), 2, 4))
            Cast(owner, owner, 681086);
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        if (GetId() != 807733 && GetId() != 680492)
            return;
        absorb = 0;
        Unit* owner = GetTarget();
        if (GetId() == 807733)
        {
            Unit* attacker = damage.GetAttacker();
            if (_paying || !attacker || attacker == owner || attacker->IsControlledByPlayer() ||
                !(damage.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL))
                return;
            absorb = damage.GetDamage() / 4;
            for (uint8 i = 0; i < _debt.size(); ++i)
                _debt[(_tick + i) % _debt.size()] += absorb / 5 + (i < absorb % 5 ? 1 : 0);
        }
        else if (GetId() == 680492)
        {
            Player* player = Owner(owner);
            if (!player || damage.GetDamage() < owner->GetHealth() || player->HasSpellCooldown(680492))
                return;
            absorb = damage.GetDamage();
            owner->SetHealth(1);
            player->AddSpellCooldown(680492, 0, 120000);
            Cast(owner, owner, 680493);
        }
    }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Unit* owner = GetTarget();
        Player* player = Owner(owner);
        uint32 id = GetId();
        if (MainBrand(GetSpellInfo()))
        {
            std::vector<uint32> remove;
            for (auto const& [key, application] : owner->GetAppliedAuras())
            {
                Aura* aura = application->GetBase();
                if (aura->GetId() != id && aura->GetCasterGUID() == GetCasterGUID() && MainBrand(aura->GetSpellInfo()))
                    remove.push_back(aura->GetId());
            }
            for (uint32 spell : remove)
                owner->RemoveAurasDueToSpell(spell, GetCasterGUID());
        }
        if (id == 501380 && owner->IsPlayer())
            GetAura()->SetDuration(std::min(GetAura()->GetDuration(), 8000));
        if (id == 804068)
        {
            _elapsed = 0;
            GetEffect(EFFECT_0)->ChangeAmount(3);
            Cast(GetCaster(), owner, 804073);
            owner->RemoveAurasByType(SPELL_AURA_MOD_STEALTH);
        }
        if (id == 805751 && player && player->HasSpell(805767))
            player->CastCustomSpell(805766, SPELLVALUE_AURA_DURATION, GetAura()->GetDuration(), player,
                                    TRIGGERED_FULL_MASK);
        if (id == 504790 && player)
            player->UpdateSpeed(MOVE_RUN, true);
        if (Family(GetSpellInfo(), 1, 4194304) && player)
            player->RemoveAurasDueToSpell(706241);
        if (id == 805770)
            owner->ApplySpellImmune(id, IMMUNITY_SCHOOL, 126, true);
        if (id == 92091 && player)
            Cast(player, player, 500570);
        if (id == 681453 && player)
        {
            if (!player->HasSpell(9116))
                player->learnSpell(9116, true);
            if (!player->HasSpell(520865))
                player->learnSpell(520865, true);
        }
        if (id == 707230 && player)
            Replacement(player, 1, 536870912, 803333);
        if (id == 807797 && player)
        {
            if (!player->HasSpell(802006))
                player->learnSpell(802006, true);
            player->SetTemporarySpellReplacement(500085, 802006);
        }
        if (id == 803166 && player)
            player->ModifyAuraState(AURA_STATE_DEFENSE, true);
    }

    void Removed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Unit* owner = GetTarget();
        Player* player = Owner(owner);
        uint32 id = GetId();
        if (id == 807733)
        {
            uint64 debt = 0;
            for (uint64 amount : _debt)
                debt += amount;
            _debt = {};
            Pay(debt);
        }
        if (id == 804068)
            owner->RemoveAurasDueToSpell(804073, GetCasterGUID());
        if (id == 684330)
            owner->RemoveAurasDueToSpell(504472, GetCasterGUID());
        if (id == 805751)
            owner->RemoveAurasDueToSpell(805766, GetCasterGUID());
        if (id == 504790)
            owner->UpdateSpeed(MOVE_RUN, true);
        if (Family(GetSpellInfo(), 1, 4194304))
            owner->RemoveAurasDueToSpell(706241);
        if (id == 805770)
            owner->ApplySpellImmune(id, IMMUNITY_SCHOOL, 126, false);
        if (!player)
            return;
        switch (id)
        {
            case 503664:
                for (uint32 stack : {503658, 504713})
                    if (Aura* aura = player->GetAura(stack))
                        if (aura->GetStackAmount() > 10)
                            aura->SetStackAmount(10);
                break;
            case 802281:
                player->RestoreDisplayId();
                break;
            case 92091:
                player->RemoveAurasDueToSpell(500570);
                break;
            case 804185:
                player->RemoveAurasDueToSpell(807198);
                player->RemoveAurasDueToSpell(807231);
                break;
            case 562225:
                Tracking(player, false);
                break;
            case 681499:
                ClearReplacement(player, 0, 1024);
                break;
            case 680513:
                player->RemoveAurasDueToSpell(681499);
                break;
            case 500569:
                ClearReplacement(player, 0, 64);
                player->RemoveAurasDueToSpell(500604);
                break;
            case 500567:
                player->RemoveAurasDueToSpell(500569);
                player->removeSpell(807364, SPEC_MASK_ALL, true);
                break;
            case 681453:
                player->removeSpell(520865, SPEC_MASK_ALL, true);
                player->removeSpell(9116, SPEC_MASK_ALL, true);
                break;
            case 707230:
                ClearReplacement(player, 1, 536870912);
                player->removeSpell(803333, SPEC_MASK_ALL, true);
                break;
            case 807797:
                player->SetTemporarySpellReplacement(500085, 0);
                player->removeSpell(802006, SPEC_MASK_ALL, true);
                break;
            case 803166:
                player->ModifyAuraState(AURA_STATE_DEFENSE, false);
                break;
        }
    }

    bool Check(ProcEventInfo& event)
    {
        return event.GetActor() == GetTarget() &&
               (event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_RANGED_AUTO_ATTACK |
                                       PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS |
                                       PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG | PROC_FLAG_DONE_PERIODIC));
    }

    void Proc(ProcEventInfo&)
    {
        PreventDefaultAction();
        Remove();
    }

    void Register() override
    {
        if (m_scriptSpellId == 807733 || m_scriptSpellId == 680492)
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_witch_hunter_lifecycle::Calculate, EFFECT_ALL,
                                                         SPELL_AURA_SCHOOL_ABSORB);
            OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_witch_hunter_lifecycle::Absorb, EFFECT_ALL);
        }
        if (m_scriptSpellId == 562225)
            DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_witch_hunter_lifecycle::Calculate, EFFECT_1,
                                                         SPELL_AURA_MOD_STEALTH_DETECT);
        if (Family(sSpellMgr->GetSpellInfo(m_scriptSpellId), 2, 4))
            DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_witch_hunter_lifecycle::Calculate, EFFECT_0,
                                                         SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE);
        DoEffectCalcPeriodic +=
            AuraEffectCalcPeriodicFn(aura_ascension_witch_hunter_lifecycle::Periodic, EFFECT_ALL, SPELL_AURA_ANY);
        OnEffectPeriodic +=
            AuraEffectPeriodicFn(aura_ascension_witch_hunter_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_witch_hunter_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_witch_hunter_lifecycle::Removed, EFFECT_ALL,
                                                SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        if (m_scriptSpellId == 680494 || (m_scriptSpellId >= 681218 && m_scriptSpellId <= 681221) ||
            m_scriptSpellId == 681540)
        {
            DoCheckProc += AuraCheckProcFn(aura_ascension_witch_hunter_lifecycle::Check);
            OnProc += AuraProcFn(aura_ascension_witch_hunter_lifecycle::Proc);
        }
    }
};

class witch_hunter_state : public UnitScript
{
  public:
    witch_hunter_state()
        : UnitScript("witch_hunter_state", true,
                     {UNITHOOK_ON_UNIT_UPDATE, UNITHOOK_ON_DAMAGE, UNITHOOK_ON_AURA_APPLY, UNITHOOK_IF_NORMAL_REACTION,
                      UNITHOOK_CAN_UNIT_ATTACK})
    {
    }

    bool CanUnitAttack(Unit const* attacker, Unit const* target, SpellInfo const* spell) override
    {
        return (spell && spell->IsAffectingArea()) || !InSmoke(attacker, target);
    }

    void OnUnitUpdate(Unit* unit, uint32) override
    {
        Player* player = Owner(unit);
        if (!player || !player->IsInWorld() || !player->IsAlive())
            return;
        if (!player->HasAura(681181))
            Cast(player, player, 681181);
        if (!player->HasAura(706240))
            player->RemoveAurasDueToSpell(706241);
        if (Hound(player))
        {
            if (!player->HasAura(578336))
                Cast(player, player, 578336);
        }
        else if (player->HasAura(578336))
            player->RemoveAurasDueToSpell(578336);
        if (player->HasAura(802138) && player->HealthBelowPct(20))
            player->RemoveAurasDueToSpell(802138);
        if (player->HasAura(802281) && player->IsMounted())
            player->RemoveAurasDueToSpell(802281);
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!damage)
            return;
        if (attacker)
            for (auto const& [key, application] : attacker->GetAppliedAuras())
                if (Family(application->GetBase()->GetSpellInfo(), 1, 16384))
                {
                    application->GetBase()->Remove();
                    damage = 0;
                    return;
                }
        if (attacker)
            attacker->RemoveAurasDueToSpell(802281);
        Player* player = Owner(victim);
        if (player && player->HasAura(681173) && !player->HasSpellCooldown(681173) &&
            uint64(damage) + player->CountPctFromMaxHealth(35) >= player->GetHealth())
        {
            player->AddSpellCooldown(681173, 0, 120000);
            SummonHounds(player, 3, sSpellMgr->GetSpellInfo(681172)->GetDuration(), 681172, attacker);
            Reset(player, 500085);
        }
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = Owner(unit);
        if (!player || !player->HasAura(803638) || aura->GetSpellInfo()->Dispel != DISPEL_CURSE ||
            aura->GetCasterGUID() == player->GetGUID() || aura->GetSpellInfo()->IsPositive())
            return;
        uint32 count = 0;
        for (auto const& [key, application] : player->GetAppliedAuras())
            if (!application->IsPositive() && application->GetBase()->GetSpellInfo()->Dispel == DISPEL_CURSE)
                ++count;
        SpellInfo const* info = sSpellMgr->GetSpellInfo(704570);
        int32 percent =
            std::min(95, std::abs(info->Effects[EFFECT_0].CalcValue(player)) + 5 * int32(count > 0 ? count - 1 : 0));
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, -percent);
        values.AddSpellMod(SPELLVALUE_AURA_DURATION, info->GetDuration() + 2000 * count);
        player->CastCustomSpell(704570, values, player, TRIGGERED_FULL_MASK);
    }

    bool IfNormalReaction(Unit const* unit, Unit const* target, ReputationRank& reaction) override
    {
        auto disguise = [](Unit const* player, Unit const* creature)
        {
            return player->IsPlayer() && player->getClass() == CLASS_WITCH_HUNTER && player->HasAura(802281) &&
                   creature->IsCreature() && !creature->IsControlledByPlayer();
        };
        if (unit && target && (disguise(unit, target) || disguise(target, unit)))
        {
            reaction = REP_NEUTRAL;
            return false;
        }
        return true;
    }
};
}

void AddAscensionWitchHunterDefenseScripts()
{
    new witch_hunter_state();
    RegisterSpellScript(aura_ascension_witch_hunter_unbroken);
    RegisterSpellScript(aura_ascension_witch_hunter_lifecycle);
}
