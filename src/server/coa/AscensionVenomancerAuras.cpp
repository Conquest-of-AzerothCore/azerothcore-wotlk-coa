/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionVenomancer.h"
#include "AscensionVenomancerData.h"
#include "DynamicObject.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace
{
using namespace AscensionVenomancer;
bool First(AuraEffect const* effect)
{
    for (uint8 slot = 0; slot < effect->GetEffIndex(); ++slot)
        if (effect->GetBase()->HasEffect(slot))
            return false;
    return true;
}
class aura_ascension_venomancer_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_venomancer_lifecycle);
    void Apply(AuraEffect const* effect, AuraEffectHandleModes mode)
    {
        Player* player = Owner(GetCaster());
        if (!player || !First(effect))
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        GetAura()->SetScriptValue(Brood,++State(player).sequence);
        if (id == 504737 || id == 505203 || id == 808083 || id == 504341)
        {
            if (mode & AURA_EFFECT_HANDLE_REAPPLY)
                GetAura()->SetCharges(id == 504737 ? 2 : id == 505203 ? 5 : id == 808083 ? 12 : 1);
            GetAura()->SetUsingCharges(false);
        }
        if (Named(GetSpellInfo(),804983) && (mode & AURA_EFFECT_HANDLE_REAPPLY))
            GetAura()->GetEffect(EFFECT_2)->SetAmount(0);
        if (Named(GetSpellInfo(),706962))
        {
            if (mode & AURA_EFFECT_HANDLE_REAPPLY)
                GetAura()->GetEffect(EFFECT_2)->SetAmount(0);
            if (AuraEffect* base = GetAura()->GetEffect(EFFECT_1))
                if (!base->GetAmount() || (mode & AURA_EFFECT_HANDLE_REAPPLY))
                    base->SetAmount(GetAura()->GetEffect(EFFECT_0)->GetAmount());
            if (player->HasAura(805104) && player->HasAura(Spider))
                player->CastSpell(target->GetPositionX(),target->GetPositionY(),target->GetPositionZ(),570208,true);
        }
        if (id == 800921)
        {
            if (Unit* host = ObjectAccessor::GetUnit(*player,State(player).host))
            {
                Cast(player,host,804003);
                State(player).exit.Relocate(*host);
            }
            if (!player->HasSpell(803537))
                player->learnSpell(803537,true);
            player->AttackStop();
            player->SetControlled(true,UNIT_STATE_ROOT);
        }
        if (id == Skulk)
        {
            Cast(player,player,800906);
            Cast(player,player,520890);
        }
        if (id == Spider || id == Beetle)
            Cast(player,player,803184);
        if (id == 806154)
        {
            Cast(player,player,806152);
            if (!player->HasSpell(806217))
                player->learnSpell(806217,true);
            Cast(player,player,806164);
            if (player->HasAura(800878) && player->HasAura(Spider))
                Cast(player,player,Skulk);
        }
        if (id == 504867)
        {
            uint64 budget = 0;
            std::list<Aura*> remove;
            for (auto const& pair : target->GetAppliedAuras())
            {
                Aura* aura = pair.second->GetBase();
                if (aura->GetCasterGUID() != player->GetGUID() || !Poison(aura->GetSpellInfo()))
                    continue;
                for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                    if (AuraEffect* tick = aura->GetEffect(slot); tick && tick->GetAuraType() == SPELL_AURA_PERIODIC_DAMAGE &&
                        tick->GetAmplitude() && aura->GetDuration() >= tick->GetPeriodicTimer())
                    {
                        uint32 ticks = 1 + (aura->GetDuration()-std::max(0,tick->GetPeriodicTimer())) / tick->GetAmplitude();
                        if (Named(aura->GetSpellInfo(),706962) && aura->GetEffect(EFFECT_1) && aura->GetEffect(EFFECT_2))
                        {
                            uint32 done = uint32(aura->GetEffect(EFFECT_2)->GetAmount()) >> 8;
                            for (uint32 n = 1; n <= ticks; ++n)
                                budget += uint64(std::max(0,aura->GetEffect(EFFECT_1)->GetAmount())) * std::min(15u,done+n);
                        }
                        else
                            budget += uint64(std::max(0,tick->GetAmount())) * ticks;
                    }
                remove.push_back(aura);
            }
            if (AuraEffect* stored = GetAura()->GetEffect(EFFECT_1))
                stored->SetAmount(int32(std::min<uint64>(INT32_MAX,budget)));
            for (Aura* aura : remove)
                aura->Remove();
        }
        if (id == Spider || id == Beetle || id == 804980 || id == 800912 || id == 705970 || id == 805140 ||
            id == 805104 || id == 704264 || id == 706940 || id == 504798 || id == 805238 || id == 630932)
            Refresh(player);
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        uint8 slot = effect->GetEffIndex();
        if ((id == 808082 || id == 504867) && slot == 1)
        {
            amount = 0;
            recalculate = false;
        }
        if (id == 808083 || (Named(GetSpellInfo(),706962) && slot == 1))
            recalculate = false;
        if ((Any(GetSpellInfo(),{800871,804977,706962,804983}) && slot == 2) ||
            (id == 807153 && slot == 0) || (id == 706456 && slot > 0))
        {
            amount = 0;
            recalculate = false;
        }
        if (Named(GetSpellInfo(),800901) && slot > 0)
            amount = player->HasAura(706014) ? Amount(800903) : 0;
        if (Named(GetSpellInfo(),800926) && slot == 1 && player->HasAura(504356))
            if (Aura* stacks = GetTarget()->GetAura(806454,player->GetGUID()))
                AddPct(amount,stacks->GetStackAmount() * Amount(504356,1));
        if (id == 803216 && slot == 1)
            amount = int32(5 * (player->GetStat(STAT_INTELLECT) + player->GetStat(STAT_AGILITY)));
        if (id == 705970 && slot == 0 && !player->HasAura(Beetle))
            amount = 0;
        if (id == 705970 && slot == 1)
        {
            float attributes = 0;
            for (uint8 stat = 0; stat < MAX_STATS; ++stat)
                attributes += player->GetStat(Stats(stat));
            amount = int32(attributes * Amount(705970,1) / 100.0f);
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
        Unit* target = GetTarget();
        bool expired = GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE;
        if (id == 681291 && expired && !GetAura()->GetScriptValue(681301))
        {
            GetAura()->SetScriptValue(681301,1);
            DynamicObject* ring = GetAura()->GetDynobjOwner();
            uint32 left = sSpellMgr->GetSpellInfo(681301)->MaxAffectedTargets;
            for (Unit* ally : Allies(player,target,ring ? 2 * ring->GetRadius() : 0))
                if (ring && ring->IsWithinDistInMap(ally,ring->GetRadius()))
                {
                    Cast(player,ally,681301);
                    if (left && !--left)
                        break;
                }
        }
        if (Named(GetSpellInfo(),804983))
            target->RemoveAurasDueToSpell(807153,player->GetGUID());
        if (Named(GetSpellInfo(),706962) && expired && player->HasAura(807243))
            Cast(player,target,807342);
        if (id == 707234 && expired)
            for (auto const& pair : target->GetAppliedAuras())
                if (Aura* aura = pair.second->GetBase(); aura->GetCasterGUID() == player->GetGUID() &&
                    Named(aura->GetSpellInfo(),804983))
                {
                    Mushroom(player,*target,.125f);
                    break;
                }
        if (id == 808082 && expired)
        {
            int32 stored = GetAura()->GetEffect(EFFECT_1)->GetAmount();
            Cast(player,target,808083);
            if (Aura* release = target->GetAura(808083,player->GetGUID()))
            {
                release->SetCharges(12);
                release->SetUsingCharges(false);
                if (AuraEffect* value = release->GetEffect(EFFECT_0))
                    value->SetAmount(stored);
            }
        }
        if (id == 504867 && expired)
            Copy(player,target,504869,uint32(std::max(0,GetAura()->GetEffect(EFFECT_1)->GetAmount())));
        if (id == 800921)
            ExitParasite(player);
        if (id == 806154)
        {
            player->RemoveAurasDueToSpell(806152);
            player->RemoveAurasDueToSpell(806164);
            player->removeSpell(806217,SPEC_MASK_ALL,true);
        }
        if (id == Skulk && player->HasAura(706026))
        {
            Cast(player,player,707358);
            if (Aura* aura = player->GetAura(707358))
                aura->SetDuration(4000);
        }
        if (id == Skulk)
            player->RemoveAurasDueToSpell(520890);
        if ((id == Spider || id == Beetle) && !player->HasAura(Spider) && !player->HasAura(Beetle))
            player->RemoveAurasDueToSpell(803184);
        if (id == 800892)
            player->RemoveAurasDueToSpell(800960);
        if (id == 800848 && expired && GetAura()->GetStackAmount() < 3)
            player->AddSpellCooldown(800848, 0, 40 * IN_MILLISECONDS, true);
        if (id == Spider || id == Beetle || id == 804980 || id == 800912 || id == 705970 ||
            id == 805104 || id == 805140 || id == 704264 || id == 630932)
            Refresh(player);
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        uint8 slot = effect->GetEffIndex();
        if (id == 800878 && slot == 1)
        {
            PreventDefaultAction();
            if (player->HasAura(Skulk))
                Reduce(player,806154,std::abs(Amount(802825)));
        }
        if (Named(GetSpellInfo(),800901))
            for (uint8 resistance : {uint8(1),uint8(2)})
                if (AuraEffect* resist = GetAura()->GetEffect(resistance))
                    resist->ChangeAmount(player->HasAura(706014) ? Amount(800903) : 0);
        if (id == 800892 && slot == 2)
        {
            PreventDefaultAction();
            if (Aura* harden = player->GetAura(800960))
            {
                Cast(player,player,680839);
                harden->ModStackAmount(-1);
            }
            else
                GetAura()->Remove();
        }
        if (id == 803206 && slot == 1)
        {
            PreventDefaultAction();
            Cast(player,target,680854);
        }
        if (id == 805931 && slot == 1)
        {
            PreventDefaultAction();
            uint32 stacks = GetAura()->GetStackAmount();
            int32 cost = std::max(0,Amount(805931,2) + (player->HasAura(705999) ? Amount(705999) : 0));
            cost *= stacks;
            if (player->GetPower(POWER_RAGE) < uint32(cost))
            {
                GetAura()->Remove();
                return;
            }
            player->ModifyPower(POWER_RAGE,-cost);
            player->CastCustomSpell(805932,SPELLVALUE_BASE_POINT0,Amount(802325)*stacks,player,true);
        }
        if (id == 807153 || (Named(GetSpellInfo(),804983) && slot == 2))
        {
            PreventDefaultAction();
            if (!effect->GetAmount())
            {
                GetAura()->GetEffect(effect->GetEffIndex())->SetAmount(1);
                Mushroom(player,*target);
            }
        }
        if (Named(GetSpellInfo(),800870) && slot == 2)
        {
            PreventDefaultAction();
            if (player->HasAura(681047))
            {
                switch (target->getPowerType())
                {
                    case POWER_MANA:
                        target->EnergizeBySpell(target,800874,CalculatePct(target->GetMaxPower(POWER_MANA),Amount(800874)),POWER_MANA);
                        break;
                    case POWER_ENERGY: case POWER_FOCUS:
                        target->EnergizeBySpell(target,800874,Amount(800874,1),target->getPowerType());
                        break;
                    case POWER_RAGE:
                        target->EnergizeBySpell(target,800874,Amount(800874,2),POWER_RAGE);
                        break;
                    case POWER_RUNIC_POWER:
                        target->EnergizeBySpell(target,567591,Amount(567591),POWER_RUNIC_POWER);
                        break;
                    default: break;
                }
            }
        }
        if (Named(GetSpellInfo(),800902) && slot == 1)
        {
            PreventDefaultAction();
            constexpr uint32 BookOfShadra = 705957;
            constexpr uint32 GreenSalveSeekHeal = 803529;
            bool seekEveryTick = player->HasAura(BookOfShadra);
            if (seekEveryTick || !GetAura()->GetScriptValue(GreenSalveSeekHeal))
            {
                GetAura()->SetScriptValue(GreenSalveSeekHeal,1);
                auto allies = Allies(player,target,Radius(GreenSalveSeekHeal));
                allies.remove(target);
                if (!allies.empty())
                    player->CastCustomSpell(GreenSalveSeekHeal,SPELLVALUE_BASE_POINT0,
                        effect->GetAmount(),allies.front(),true);
            }
        }
        if (Named(GetSpellInfo(),706962) && slot == 1)
            PreventDefaultAction();
        if (id == 707234 && slot == 2)
            PreventDefaultAction();
        if (id == 681291 && slot == 1)
            PreventDefaultAction();
        if (id == 806154)
        {
            PreventDefaultAction();
            SetHelper(player,806152,true);
        }
    }
    void Period(AuraEffect const* effect, bool&, int32& amplitude)
    {
        if (effect->GetEffIndex() == 0 && Any(GetSpellInfo(),{800871,804977,706962}))
            if (AuraEffect* snapshot = GetAura()->GetEffect(EFFECT_2))
                amplitude = std::max(1,CalculatePct(amplitude,100 -
                    (uint32(snapshot->GetAmount()) & 255u) * std::abs(Amount(806602,1))));
    }
    void UpdateTick(AuraEffect* effect)
    {
        if (Named(GetSpellInfo(),706962) && effect->GetEffIndex() == 0)
            if (AuraEffect* base = GetAura()->GetEffect(EFFECT_1))
            {
                AuraEffect* snapshot = GetAura()->GetEffect(EFFECT_2);
                uint32 saved = uint32(snapshot->GetAmount());
                uint32 ticks = std::min(15u,(saved >> 8) + 1);
                effect->SetAmount(int32(std::min<int64>(INT32_MAX,int64(base->GetAmount()) *
                    ticks)));
                snapshot->SetAmount(int32((saved & 255u) | (ticks << 8)));
            }
        if (GetId() == 706456 && effect->GetEffIndex() == 0)
        {
            uint32 ticks = 1 + uint32(std::max(0,GetAura()->GetDuration())) / uint32(std::max(1,int32(effect->GetAmplitude())));
            uint64 total = 0;
            for (uint8 slot : {uint8(1),uint8(2)})
            {
                AuraEffect* budget = GetAura()->GetEffect(slot);
                uint32 value = uint32(std::max(0,budget->GetAmount())) / ticks;
                budget->SetAmount(budget->GetAmount()-int32(value));
                total += value;
            }
            effect->SetAmount(int32(std::min<uint64>(INT32_MAX,total)));
        }
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_venomancer_lifecycle::Apply,EFFECT_ALL,SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_venomancer_lifecycle::Remove,EFFECT_ALL,SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_venomancer_lifecycle::Calculate,EFFECT_ALL,SPELL_AURA_ANY);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_venomancer_lifecycle::Period,EFFECT_ALL,SPELL_AURA_ANY);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_venomancer_lifecycle::Tick,EFFECT_ALL,SPELL_AURA_ANY);
        OnEffectUpdatePeriodic += AuraEffectUpdatePeriodicFn(aura_ascension_venomancer_lifecycle::UpdateTick,EFFECT_ALL,SPELL_AURA_ANY);
    }
};
}
void AddSC_AscensionVenomancerAuras()
{
    RegisterSpellScript(aura_ascension_venomancer_lifecycle);
}