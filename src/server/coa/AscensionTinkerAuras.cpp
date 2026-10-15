/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTinker.h"
#include "AscensionTinkerData.h"
#include "GameTime.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "ThreatManager.h"
#include <algorithm>
namespace
{
using namespace AscensionTinker;
bool First(AuraEffect const* effect)
{
    for (uint8 slot = 0; slot < effect->GetEffIndex(); ++slot)
        if (effect->GetBase()->HasEffect(slot))
            return false;
    return true;
}
class aura_ascension_tinker_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_lifecycle);
    bool airborne = false, landed = false, rescued = false;
    void Apply(AuraEffect const* effect, AuraEffectHandleModes mode)
    {
        Player* player = Owner(GetCaster());
        if (!player || !First(effect))
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        for (uint32 finite : TinkerFinite)
            if (id == finite)
            {
                if (mode & AURA_EFFECT_HANDLE_REAPPLY)
                    GetAura()->SetCharges(id == 707261 ? 2 : 1);
                GetAura()->SetUsingCharges(false);
                GetAura()->SetScriptValue(Scrap,++State(player).sequence);
            }
        if (id == 805657)
            GetAura()->SetScriptValue(805657,player->GetGUID().GetRawValue());
        if (id == Mechsuit)
            Refresh(player);
        if (Named(GetSpellInfo(),801709))
            player->GetThreatMgr().RegisterRedirectThreat(id,target->GetGUID(),100);
        if (id == 712289 && GetAura()->GetStackAmount() >= 6 && !target->HasAura(712401,player->GetGUID()))
        {
            Cast(player,target,712319);
            target->RemoveAurasDueToSpell(712289,player->GetGUID());
        }
        if (Any(GetSpellInfo(),{801809,801709,502537,801808,803552}) && player->HasAura(560734))
            Cast(player,target,560736);
        if (Named(GetSpellInfo(),801809))
        {
            ObjectGuid previous = State(player).reconstruction;
            State(player).reconstruction = target->GetGUID();
            if (!previous.IsEmpty() && previous != target->GetGUID())
                if (Unit* old = ObjectAccessor::GetUnit(*player,previous))
                {
                    std::list<Aura*> remove;
                    for (auto const& pair : old->GetAppliedAuras())
                        if (Aura* aura = pair.second->GetBase(); aura->GetCasterGUID() == player->GetGUID() &&
                            Named(aura->GetSpellInfo(),801809))
                            remove.push_back(aura);
                    for (Aura* aura : remove)
                        aura->Remove();
                }
        }
        for (uint32 module : TinkerModules)
            if (id == module)
            {
                auto& state = State(player);
                state.moduleTargets.insert(target->GetGUID());
            }
        if (id == 808008)
            for (uint8 slot : {uint8(0),uint8(1)})
                if (AuraEffect* amount = GetAura()->GetEffect(slot))
                    amount->ChangeAmount(int32(std::max(0,player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_ALL)) *
                                               .1f * GetAura()->GetStackAmount()));
        if (id == 706692)
            GetAura()->SetScriptValue(706692,GameTime::GetGameTimeMS().count());
        if (id == 806757)
            for (uint32 helper : {806780,806778})
                if (Aura* aura = target->GetAura(helper,player->GetGUID()))
                {
                    aura->SetMaxDuration(GetAura()->GetMaxDuration());
                    aura->SetDuration(GetAura()->GetDuration());
                }
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Player* player = Owner(GetCaster());
        if (!player || !First(effect))
            return;
        if (GetId() == Mechsuit || GetId() == 803451)
        {
            ExitMechsuit(player);
            Refresh(player);
        }
        if (GetId() == Scrap && !player->HasAura(Scrap))
            ExitMechsuit(player);
        if (GetId() == 801389)
            player->RemoveAurasDueToSpell(801386);
        if (GetId() == 681245)
            Refresh(player);
        if (GetId() == 500213 && GetTarget() == player)
            for (uint32 id : TinkerFinite)
            {
                uint64 generation = GetAura()->GetScriptValue(id);
                GetAura()->SetScriptValue(id,0);
                Spend(player,id,generation);
            }
        if (Named(GetSpellInfo(),801709))
            player->GetThreatMgr().UnregisterRedirectThreat(GetId(),GetTarget()->GetGUID());
        if (GetId() == 806757)
            for (uint32 helper : {806780,806778})
                GetTarget()->RemoveAurasDueToSpell(helper,player->GetGUID());
    }
    void Tick(AuraEffect const* effect)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        if (Named(GetSpellInfo(),801709) && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            auto targets = Nearby(GetTarget(),Radius(573054));
            targets.remove_if([player](Unit* enemy) { return !player->IsValidAttackTarget(enemy); });
            if (SpellInfo const* helper = sSpellMgr->GetSpellInfo(573054); helper && helper->MaxAffectedTargets &&
                targets.size() > helper->MaxAffectedTargets)
                targets.resize(helper->MaxAffectedTargets);
            for (Unit* enemy : targets)
                player->CastCustomSpell(573054,SPELLVALUE_BASE_POINT0,effect->GetAmount(),enemy,true);
        }
        if ((Named(GetSpellInfo(),500232) || GetId() == 504667 || GetId() == 500612) &&
            effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            if (effect->GetTickNumber() == 1)
                player->CastCustomSpell(GetId() == 500612 ? 803639 : 801009,SPELLVALUE_BASE_POINT0,
                    effect->GetAmount(),GetTarget(),true);
        }
        if (GetId() == Mechsuit && effect->GetEffIndex() == EFFECT_2)
        {
            PreventDefaultAction();
            Resource(player,Scrap,-1);
        }
        if (GetId() == 807635 && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            if (player->IsAlive() && player->HasAura(Mechsuit))
                Cast(player,player,504811);
        }
        if (GetId() == 801389 && effect->GetEffIndex() == EFFECT_2)
        {
            if (player->HasUnitMovementFlag(MOVEMENTFLAG_FALLING | MOVEMENTFLAG_FALLING_FAR))
                airborne = true;
            else if (airborne && !landed)
            {
                PreventDefaultAction();
                landed = true;
                Cast(player,player,801390);
                GetAura()->Remove();
            }
        }
    }
    void AmountHook(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        if (GetId() == 707495)
            recalculate = false;
        if (GetId() == 520445)
        {
            amount = -1;
            recalculate = false;
        }
        if (GetId() == 560709 && effect->GetEffIndex() == EFFECT_0)
        {
            amount += int32(GetUnitOwner()->GetStat(STAT_STAMINA));
            recalculate = false;
        }
        if (GetId() == 808008 && effect->GetEffIndex() < EFFECT_2)
        {
            amount = int32(.1f * std::max(0,player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_ALL)));
            recalculate = false;
        }
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        if (GetId() != 520445)
            return;
        amount = 0;
        if (!rescued && damage.GetDamage() >= GetTarget()->GetHealth())
            amount = damage.GetDamage();
    }
    void AfterAbsorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        if (GetId() != 520445 || rescued || !amount || damage.GetDamage() >= GetTarget()->GetHealth())
            return;
        rescued = true;
        GetTarget()->CastSpell(GetTarget(),524780,true);
        GetAura()->Remove();
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_tinker_lifecycle::Apply,EFFECT_ALL,SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_tinker_lifecycle::Remove,EFFECT_ALL,SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_tinker_lifecycle::AmountHook,EFFECT_ALL,SPELL_AURA_ANY);
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId))
            for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            {
                auto const& effect = info->Effects[slot];
                if (effect.IsAura() && effect.Amplitude)
                    OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_tinker_lifecycle::Tick,
                        SpellEffIndex(slot),AuraType(effect.ApplyAuraName));
                if (effect.IsAura(SPELL_AURA_SCHOOL_ABSORB) && info->Id == 520445)
                {
                    OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_tinker_lifecycle::Absorb,SpellEffIndex(slot));
                    AfterEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_tinker_lifecycle::AfterAbsorb,SpellEffIndex(slot));
                }
            }
    }
};
class aura_ascension_tinker_arcanoreflector : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_arcanoreflector);
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        if (!damage.GetSpellInfo())
            amount = 0;
    }
    void Explode(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        if (!amount || !damage.GetSpellInfo())
            return;
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            if (GetSpellInfo()->Effects[slot].IsAura(SPELL_AURA_DUMMY))
                if (AuraEffect const* share = GetAura()->GetEffect(slot))
                    GetTarget()->CastCustomSpell(578346,SPELLVALUE_BASE_POINT0,
                        int32(uint64(amount) * std::max(0,share->GetAmount()) / 100),GetTarget(),true);
        GetAura()->Remove();
    }
    void Register() override
    {
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_tinker_arcanoreflector::Absorb,EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_tinker_arcanoreflector::Explode,EFFECT_0);
    }
};
}
void AddSC_AscensionTinkerAuras()
{
    RegisterSpellScript(aura_ascension_tinker_lifecycle);
    RegisterSpellScript(aura_ascension_tinker_arcanoreflector);
}
