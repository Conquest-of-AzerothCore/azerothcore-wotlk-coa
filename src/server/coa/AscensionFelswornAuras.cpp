/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>

namespace
{
using namespace AscensionFelsworn;
bool First(AuraEffect const* effect)
{
    Aura const* aura = effect->GetBase();
    for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
        if (aura->HasEffect(i))
            return false;
    return true;
}
class aura_ascension_felsworn_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_felsworn_lifecycle);
    void Calculate(AuraEffect const* effect, int32& amount, bool&)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        if (GetId() == 800206 && effect->GetEffIndex() == EFFECT_1)
            amount = player->HasAura(704611) ? std::min<uint64>(10, GetAura()->GetScriptValue(800206)) : 0;
        if (GetId() == 807163 && effect->GetEffIndex() == EFFECT_0)
            amount = 30;
        if (GetId() == 807424 && effect->GetEffIndex() == EFFECT_1)
            amount = 0;
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (Bane(GetSpellInfo()) || (Pact(GetSpellInfo()) && GetTarget() == player))
        {
            std::vector<Aura*> remove;
            for (auto const& pair : GetTarget()->GetAppliedAuras())
                if (Aura* aura = pair.second->GetBase();
                    aura != GetAura() && aura->GetCasterGUID() == player->GetGUID() &&
                    (Bane(GetSpellInfo()) ? Bane(aura->GetSpellInfo()) : Pact(aura->GetSpellInfo())))
                    remove.push_back(aura);
            for (Aura* aura : remove)
                aura->Remove();
        }
        if (id == 712483)
            GetAura()->SetScriptValue(id, 0);
        if (id == 707902)
            GetAura()->SetScriptValue(id, 3);
        if (GetTarget() != player)
            return;
        for (uint32 sid : {706269, 705146, 300486, 525027, 555277, 807424, 806128, 801902})
            if (id == sid)
                GetAura()->SetScriptValue(800058, ++State(player).sequence);
        if (id == 803904)
        {
            uint32 charges = 5;
            player->ApplySpellMod(id, SPELLMOD_CHARGES, charges);
            GetAura()->SetScriptValue(id, charges);
        }
        if (id == 807163)
            GetAura()->SetScriptValue(id, 10);
        if (id == 800206)
        {
            GetAura()->SetScriptValue(id, 0);
            GetAura()->SetScriptValue(560087, State(player).spenderCrit);
            player->RemoveAurasDueToSpell(803716);
        }
        if (id == 804216 || id == 520252 || id == 520253)
        {
            for (uint32 talent : {520252, 520253})
                if (AuraEffect* hide = player->GetAuraEffect(talent, EFFECT_0))
                    hide->ChangeAmount(hide->CalculateAmount(player));
            RefreshUnphased(player);
            player->UpdateArmor();
        }
        if (id == 804216 || id == 574140 || id == 802108 || id == 705122 || id == 805236)
            Refresh(player);
        if (id == 804823)
        {
            GetAura()->SetScriptValue(id, 0);
            GetAura()->SetScriptValue(804824, 0);
            for (Unit* enemy : Nearby(player, 10.0f))
                if (player->IsValidAttackTarget(enemy))
                    Cast(player, enemy, 704233);
        }
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
            return;
        uint32 id = GetId();
        if (id == BurningCommander && effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            Cast(player, player, 500531);
        }
        if (id == 800206 && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            uint32 ticks = std::min<uint64>(10, GetAura()->GetScriptValue(id) + 1);
            GetAura()->SetScriptValue(id, ticks);
            if (AuraEffect* dodge = GetAura()->GetEffect(EFFECT_1))
                dodge->ChangeAmount(player->HasAura(704611) ? ticks : 0);
        }
        if (id == 561216 && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            uint32 ticks = GetAura()->GetScriptValue(id);
            if (ticks >= 6)
                return;
            auto enemies = Nearby(player, 15.0f);
            enemies.remove_if([player](Unit* unit) {
                return !player->IsValidAttackTarget(unit) || !player->CanSeeOrDetect(unit) ||
                       unit->HasAuraType(SPELL_AURA_MOD_STEALTH) || !player->IsWithinLOSInMap(unit);
            });
            if (enemies.empty())
            {
                GetAura()->Remove();
                return;
            }
            auto it = enemies.begin();
            std::advance(it, ticks % enemies.size());
            Unit* enemy = *it;
            Position position = enemy->GetNearPosition(1.5f, enemy->GetAngle(player) - enemy->GetOrientation());
            player->NearTeleportTo(position.GetPositionX(), position.GetPositionY(), position.GetPositionZ(),
                                   player->GetAngle(enemy));
            uint32 main = 808303, off = 808304;
            for (auto const& pair : player->GetSpellMap())
                if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), 801901))
                {
                    SpellInfo const* slice = sSpellMgr->GetSpellInfo(pair.first);
                    main = slice->Effects[0].TriggerSpell;
                    off = slice->Effects[1].TriggerSpell;
                }
            Cast(player, enemy, main);
            if (player->GetWeaponForAttack(OFF_ATTACK, true))
                Cast(player, enemy, off);
            Gain(player, 1);
            GetAura()->SetScriptValue(id, ticks + 1);
        }
        if (Named(GetSpellInfo(), 704368) && effect->GetAuraType() == SPELL_AURA_PERIODIC_DUMMY)
        {
            PreventDefaultAction();
            if (Inner(player))
                Cast(player, GetTarget(), 802676);
        }
        if (id >= 552210 && id <= 552213 && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            Unit* target = GetTarget();
            uint32 drained = -target->ModifyPower(POWER_MANA, -std::max(0, effect->GetAmount()));
            if (drained)
            {
                HealInfo heal(player, player, drained, GetSpellInfo(), GetSpellInfo()->GetSchoolMask());
                player->HealBySpell(heal);
            }
        }
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        AuraRemoveMode mode = GetTargetApplication()->GetRemoveMode();
        if (id == 712483 && mode == AURA_REMOVE_BY_EXPIRE && GetTarget()->IsAlive())
        {
            uint64 count = GetAura()->GetScriptValue(id);
            Copy(
                player, GetTarget(), 807554,
                uint32(std::min<uint64>(INT32_MAX, count * std::max(0, GetSpellInfo()->Effects[0].CalcValue(player)))));
        }
        if (GetTarget() != player)
            return;
        bool alive = player->IsAlive() && mode != AURA_REMOVE_BY_DEATH;
        if (id == 804216)
        {
            Refresh(player);
            for (uint32 talent : {520252, 520253})
                if (AuraEffect* hide = player->GetAuraEffect(talent, EFFECT_0))
                    hide->ChangeAmount(hide->CalculateAmount(player));
            RefreshUnphased(player);
            player->UpdateArmor();
        }
        if (id == 806109 && alive)
            Cast(player, player, 806128);
        if (Named(GetSpellInfo(), 705129) && player->HasAura(560822) && alive)
            Cast(player, player, 561203);
        if (id == 555738 && player->HasAura(704602) && alive)
            Cast(player, player, 806096);
        if (id == 800206 && alive)
        {
            uint32 ticks = std::min<uint64>(10, GetAura()->GetScriptValue(id));
            bool full = mode == AURA_REMOVE_BY_EXPIRE;
            if (full)
                ticks = 10;
            State(player).carveSteps = ticks;
            uint32 oldCrit = State(player).spenderCrit;
            State(player).spenderCrit = uint32(GetAura()->GetScriptValue(560087));
            uint32 count = 0;
            for (Unit* enemy : Nearby(player, 8.0f))
                if (player->IsValidAttackTarget(enemy) && player->HasInArc(float(M_PI), enemy) &&
                    player->IsWithinLOSInMap(enemy))
                {
                    float percent =
                        (20.0f + ticks * (15.0f + .265306f * player->GetLevel())) * std::max(.2f, 1.0f - .1f * count++);
                    for (WeaponAttackType hand : {BASE_ATTACK, OFF_ATTACK})
                        if (hand == BASE_ATTACK || player->GetWeaponForAttack(hand, true))
                        {
                            CustomSpellValues values;
                            values.AddSpellMod(SPELLVALUE_BASE_POINT0, int32(percent));
                            values.AddSpellMod(SPELLVALUE_MELEE_ATTACK_TYPE, hand);
                            player->CastCustomSpell(803715, values, enemy, TRIGGERED_FULL_MASK);
                        }
                    if (Inner(player))
                        Cast(player, enemy, 578317);
                    if (count >= 25)
                        break;
                }
            State(player).carveSteps = 0;
            State(player).spenderCrit = oldCrit;
            if (full && player->HasAura(520831))
                Gain(player, 2);
            if (player->HasAura(707444))
            {
                Cast(player, player, 807424);
                if (Aura* aura = player->GetAura(807424))
                    aura->SetScriptValue(id, ticks);
            }
            player->RemoveAurasDueToSpell(803716);
        }
        if (id == 804823 && alive)
        {
            uint32 hits = std::min<uint64>(100, GetAura()->GetScriptValue(id));
            uint32 amount = player->CountPctFromMaxHealth(std::min(50u, hits));
            for (Unit* enemy : Nearby(player, 10.0f))
                if (player->IsValidAttackTarget(enemy) && player->IsWithinLOSInMap(enemy))
                    Copy(player, enemy, 807347, amount);
        }
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_felsworn_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_felsworn_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_felsworn_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_felsworn_lifecycle::Remove, EFFECT_ALL, SPELL_AURA_ANY,
                                                AURA_EFFECT_HANDLE_REAL);
    }
};
class aura_ascension_felsworn_stagger : public AuraScript
{
    PrepareAuraScript(aura_ascension_felsworn_stagger);
    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = 0;
        Player* player = Owner(GetTarget());
        Unit* attacker = damage.GetAttacker();
        if (!player || !attacker || !attacker->IsCreature() || attacker->IsControlledByPlayer() ||
            !(damage.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) || damage.GetDamageType() == NODAMAGE)
            return;
        amount = damage.GetDamage() / 4;
        if (amount)
        {
            auto& state = State(player);
            state.debt.push_back({amount, 5});
            if (!state.timers.HasTimeUntilEvent(807727))
                state.timers.ScheduleEvent(807727, 1s);
        }
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_felsworn_stagger::Calculate, EFFECT_2, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_felsworn_stagger::Absorb, EFFECT_2);
    }
};
class aura_ascension_felsworn_resolve : public AuraScript
{
    PrepareAuraScript(aura_ascension_felsworn_resolve);
    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = 0;
        Player* player = Owner(GetTarget());
        if (!player || !damage.GetDamage())
            return;
        uint64 spent = GetAura()->GetScriptValue(804824);
        uint64 cap = player->GetMaxHealth();
        amount = uint32(std::min<uint64>(damage.GetDamage() / 2, cap > spent ? cap - spent : 0));
        GetAura()->SetScriptValue(804824, spent + amount);
        GetAura()->SetScriptValue(804823, GetAura()->GetScriptValue(804823) + 1);
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_felsworn_resolve::Calculate, EFFECT_1, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_felsworn_resolve::Absorb, EFFECT_1);
    }
};
}
void AddSC_AscensionFelswornAuras()
{
    RegisterSpellScript(aura_ascension_felsworn_lifecycle);
    RegisterSpellScript(aura_ascension_felsworn_stagger);
    RegisterSpellScript(aura_ascension_felsworn_resolve);
}
