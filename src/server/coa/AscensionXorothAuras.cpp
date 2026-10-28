/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionXoroth.h"
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
using namespace AscensionXoroth;
constexpr uint32 SPELL_HELLWRATH = 804014;
bool First(AuraEffect const* effect)
{
    for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
        if (effect->GetBase()->HasEffect(i))
            return false;
    return true;
}
class aura_ascension_xoroth_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_xoroth_lifecycle);
    void Calculate(AuraEffect const* effect, int32& amount, bool&)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (id == 520294 && effect->GetEffIndex() == EFFECT_1)
            amount = int32(amount * (1 + .2f * State(player).blood));
        if (id == 805680 && effect->GetEffIndex() == EFFECT_0)
        {
            float perStack = .2f;
            if (player->HasAura(SPELL_HELLWRATH))
                perStack += Amount(SPELL_HELLWRATH, EFFECT_1) / 100.0f;
            amount = int32(amount * (1 + perStack * State(player).blood));
        }
        if (id == 803889)
            amount = int32(amount * (1 + .2f * State(player).fire));
        if (id == 801063 && effect->GetEffIndex() == EFFECT_2)
            amount = player->HasAura(707232) ? Amount(707232, 0) : 0;
        if (id == 801019 && effect->GetEffIndex() == EFFECT_1)
            amount = player->HasAura(300386) ? Amount(300386, 0) : 0;
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (GetId() == 804703 && effect->GetEffIndex() == EFFECT_1)
            GetTarget()->UpdateSpeed(MOVE_RUN, true);
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (Pestilence(id) || Mark(GetSpellInfo()))
        {
            std::vector<Aura*> old;
            for (auto const& pair : GetTarget()->GetAppliedAuras())
            {
                Aura* aura = pair.second->GetBase();
                if (aura != GetAura() && aura->GetCasterGUID() == player->GetGUID() &&
                    (Pestilence(id) ? Pestilence(aura->GetId()) : Mark(aura->GetSpellInfo())))
                    old.push_back(aura);
            }
            for (Aura* aura : old)
                aura->Remove();
        }
        if (GetTarget() != player)
            return;
        GetAura()->SetScriptValue(500906, ++State(player).sequence);
        if (id == 681184)
            SetRemainingUses(GetAura(), 2);
        if (id == 524913)
            SetRemainingUses(GetAura(), 5);
        if (id == 524920)
            SetRemainingUses(GetAura(), uint8(6 + State(player).fire));
        if (id == 712294)
        {
            if (player->HasAura(706502) && !player->HasSpell(504581))
                player->learnSpell(504581, true);
            Replace(player, 800340, 504581);
        }
        if (id == 800999 || id == 92104)
            player->UpdateMaxHealth();
        if (id == 804703)
            State(player).timers.RescheduleEvent(id, 3s);
        if (id == 805679)
            return;
        Refresh(player);
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        if (id == 804703 && effect->GetEffIndex() == EFFECT_2)
        {
            PreventDefaultAction();
            uint32 maximum = player->GetLevel() >= 40 ? 5 : player->GetLevel() >= 30 ? 3 : 2;
            if (!State(player).timers.HasTimeUntilEvent(id) && !player->HasAura(805746) &&
                Count(player, 804787) < maximum)
                Cast(player, player, 804787);
        }
        if (Pestilence(id) && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            uint32 child = id == 801053 ? 801071 : id == 802344 ? 802347 : id == 804786 ? 804801 : 0;
            if (child)
                for (Unit* enemy : Nearby(player, 10))
                    if (player->IsValidAttackTarget(enemy))
                        if (Aura* aura = player->AddAura(child, enemy))
                            aura->SetDuration(1500);
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
        auto mode = GetTargetApplication()->GetRemoveMode();
        if (Named(GetSpellInfo(), 806965) && mode == AURA_REMOVE_BY_EXPIRE && player->HasAura(802619) &&
            GetTarget()->IsAlive())
        {
            uint64 amount = GetAura()->GetScriptValue(802619) * std::max(0, Amount(802619)) / 100;
            if (amount)
                for (Unit* target : Nearby(GetTarget(), 8))
                    if (player->IsValidAttackTarget(target))
                        Copy(player, target, 802620, uint32(std::min<uint64>(INT32_MAX, amount)));
        }
        if (GetTarget() != player)
            return;
        if (id == 681184 && player->IsAlive() && (mode == AURA_REMOVE_BY_DEFAULT || mode == AURA_REMOVE_BY_EXPIRE))
            Cast(player, player, Highest(player, 800340));
        if (id == 712294)
            Replace(player, 800340, 0);
        if (id == 520295)
            player->RemoveAurasDueToSpell(520752);
        if (id == 800999 || id == 92104)
            player->UpdateMaxHealth();
        if (id == 805746 && mode == AURA_REMOVE_BY_EXPIRE && !player->HasAura(804785))
            player->RemoveAurasDueToSpell(804787);
        if (id == 804703)
        {
            player->RemoveAurasDueToSpell(804787);
            player->RemoveAurasDueToSpell(805746);
        }
        Refresh(player);
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_xoroth_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_xoroth_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_xoroth_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_xoroth_lifecycle::Remove, EFFECT_ALL, SPELL_AURA_ANY,
                                                AURA_EFFECT_HANDLE_REAL);
    }
};
class aura_ascension_xoroth_hellknight : public AuraScript
{
    PrepareAuraScript(aura_ascension_xoroth_hellknight);
    void UpdateMovement(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->UpdateSpeed(MOVE_RUN, true);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_xoroth_hellknight::UpdateMovement, EFFECT_0,
                                              SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_xoroth_hellknight::UpdateMovement, EFFECT_0,
                                                SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
    }
};
class aura_ascension_xoroth_block : public AuraScript
{
    PrepareAuraScript(aura_ascension_xoroth_block);
    void Calculate(AuraEffect const*, int32& amount, bool&)
    {
        amount = -1;
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = damage.GetBlock() ? CalculatePct(damage.GetDamage(), 20) : 0;
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_xoroth_block::Calculate, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_xoroth_block::Absorb, EFFECT_0);
    }
};
}
void AddSC_AscensionXorothAuras()
{
    RegisterSpellScript(aura_ascension_xoroth_lifecycle);
    RegisterSpellScript(aura_ascension_xoroth_hellknight);
    RegisterSpellScript(aura_ascension_xoroth_block);
}
