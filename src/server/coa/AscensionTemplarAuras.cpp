/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include <algorithm>

namespace
{
using namespace AscensionTemplar;
class aura_ascension_templar_stagger : public AuraScript
{
    PrepareAuraScript(aura_ascension_templar_stagger);
    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        absorb = 0;
        Player* player = Owner(GetTarget());
        if (!player || damage.GetDamageType() == DOT || damage.GetAttacker() == player ||
            (GetId() == 803149 && player->HasAura(92109)))
            return;
        absorb = uint64(damage.GetDamage()) * 40 / 100;
        Delay(player, absorb);
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_templar_stagger::Calculate, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_templar_stagger::Absorb, EFFECT_0);
    }
};

class aura_ascension_templar_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_templar_lifecycle);
    bool First(AuraEffect const* effect) const
    {
        for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
            if (GetEffect(i))
                return false;
        return true;
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        uint8 index = uint8(effect->GetEffIndex());
        if (id == 805422 && index == 1)
            amount = int32(std::min(player->GetMaxHealth(), uint32(INT32_MAX)));
        if (id == 301283 && index == 0)
            amount = int32(player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DODGE) * .1f);
        if (id == 706583 && index == 0)
            amount = int32(125 + .3f * player->GetStat(STAT_STAMINA) +
                           .25f * (player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DODGE) +
                                   player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_PARRY)));
        if (id == 801409 && index == 0)
            amount = player->HasAura(705287) ? int32(player->GetStat(STAT_AGILITY) + player->GetStat(STAT_STAMINA)) : 0;
        if (id == 705299 && index == 0)
            amount -= int32(.1f * player->GetStat(STAT_STAMINA));
        if (id == 301369 && index == 0)
            if (AuraEffect const* source = player->GetAuraEffect(301310, EFFECT_2))
                amount = int32(source->GetAmount() * player->GetStat(STAT_INTELLECT) / 100.f);
        if (id == 803237)
            recalculate = false;
        if (id == 801205 && index == 1 && player->HasAura(807004))
            GetAura()->SetScriptValue(807004, 1);
        if (Named(GetSpellInfo(), 805409) && index == 0)
        {
            int32 bonus = 0;
            for (uint32 oath : {804904, 804922, 804924, 805332})
                if (AuraEffect const* breaker = player->GetAuraEffect(oath, EFFECT_2))
                    bonus += std::max(0, breaker->GetAmount());
            GetAura()->SetScriptValue(805409, uint64(bonus));
        }
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (id == 801205 && effect->GetEffIndex() == EFFECT_1 && GetAura()->GetScriptValue(807004))
            const_cast<AuraEffect*>(effect)->SetPeriodicTimer(0);
        if (!First(effect))
            return;
        if (id == 527023)
        {
            if (GetTarget()->IsPlayer() && !GetTarget()->IsMounted() && !GetTarget()->HasAura(300513))
            {
                Cast(player, GetTarget(), 527272);
                Cast(player, GetTarget(), 527270);
            }
            return;
        }
        if (id == 527272)
        {
            GetTarget()->Mount(14584);
            return;
        }
        if (id == 300513)
        {
            GetTarget()->RemoveAurasByType(SPELL_AURA_MOUNTED);
            GetTarget()->RemoveAurasDueToSpell(527272);
            GetTarget()->UpdateSpeed(MOVE_RUN, true);
        }
        if (GetTarget() != player)
            return;
        for (uint32 selected : {806354, 807004, 561156, 681136, 712378, 524766, 806523, 524617})
            if (id == selected)
            {
                GetAura()->SetCharges(id == 806523 ? 2 : 1);
                GetAura()->SetScriptValue(704576, ++State(player).sequence);
            }
        if (id == 805422)
        {
            Reduce(player, 805417, INT32_MAX);
            Reduce(player, 801205, INT32_MAX);
            Cast(player, player, 806354);
            Cast(player, player, 807004);
        }
        if (id == 805390)
        {
            uint64 duration = GetAura()->GetScriptValue(805390);
            if (duration)
                GetAura()->SetDuration(std::min(GetAura()->GetDuration(), int32(duration)));
            if (GetAura()->GetStackAmount() >= 6)
            {
                Cast(player, player, 806517);
                GetAura()->Remove();
            }
        }
        if (id == 801202)
        {
            player->RemoveAurasDueToSpell(803843);
            player->RemoveAurasDueToSpell(807903);
        }
        if (id == 301172)
            Replacement(player, 804929, 807035);
        if (id == 563270 && GetAura()->GetStackAmount() >= 10)
        {
            GetAura()->Remove();
            Cast(player, player, 563269);
        }
        if (id == 563269)
            Replacement(player, 801446, 500689);
        if (Named(GetSpellInfo(), 805409) && player->HasAura(300504))
        {
            Cast(player, player, 301340);
            if (Aura* aura = player->GetAura(301340))
                aura->SetDuration(GetAura()->GetDuration());
        }
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
            return;
        uint32 id = GetId();
        if (id == 803237 && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            uint32 remaining = std::max(0, effect->GetAmount());
            uint32 ticks = std::max(1, GetAura()->GetDuration() / 1000 + 1);
            uint32 amount = (remaining + ticks - 1) / ticks;
            const_cast<AuraEffect*>(effect)->ChangeAmount(remaining - amount);
            uint32 applied =
                Unit::DealDamage(player, player, amount, nullptr, DOT, SPELL_SCHOOL_MASK_NORMAL, GetSpellInfo(), false);
            player->SendSpellNonMeleeDamageLog(player, GetSpellInfo(), applied, SPELL_SCHOOL_MASK_NORMAL, 0, 0, false,
                                               0);
        }
        if (id == 527270 && effect->GetEffIndex() == EFFECT_2)
        {
            PreventDefaultAction();
            if (!DivineSteed(GetTarget()))
            {
                GetAura()->Remove();
                return;
            }
            for (Unit* enemy : Nearby(GetTarget(), 5.0f))
                if (player->IsValidAttackTarget(enemy))
                {
                    Cast(player, enemy, 527269);
                    Cast(player, enemy, 527271);
                }
        }
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        uint32 id = GetId();
        if (id == 300513)
            GetTarget()->UpdateSpeed(MOVE_RUN, true);
        if (id == 527272)
        {
            if (GetTarget()->GetMountID() == 14584)
                GetTarget()->Dismount();
            GetTarget()->RemoveAurasDueToSpell(527270, GetCasterGUID());
        }
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        if (GetTarget() != player)
            return;
        if (id == 706583 && effect->GetAmount() <= 0 &&
            GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_ENEMY_SPELL &&
            player->IsAlive() && player->HasAura(804930))
            Cast(player, player, 801546);
        if (id == 704576 && !State(player).oath)
            ClearOaths(player);
        if (id == 801482 && GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE && player->IsAlive())
            Cast(player, player, 801483);
        if (id == 301172)
            Replacement(player, 804929, 0);
        if (id == 563269)
            Replacement(player, 801446, 0);
        if (Named(GetSpellInfo(), 805409))
        {
            player->RemoveAurasDueToSpell(301340);
            if (!State(player).oath)
                ClearOaths(player);
        }
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_templar_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_templar_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_templar_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_templar_lifecycle::Remove, EFFECT_ALL, SPELL_AURA_ANY,
                                                AURA_EFFECT_HANDLE_REAL);
    }
};
}
void AddSC_AscensionTemplarAuras()
{
    RegisterSpellScript(aura_ascension_templar_stagger);
    RegisterSpellScript(aura_ascension_templar_lifecycle);
}
