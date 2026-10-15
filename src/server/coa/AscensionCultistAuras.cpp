/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "AscensionCultistData.h"
#include "DynamicObject.h"
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
using namespace AscensionCultist;
bool First(AuraEffect const* effect)
{
    for (uint8 index = 0; index < effect->GetEffIndex(); ++index)
        if (effect->GetBase()->HasEffect(index))
            return false;
    return true;
}
void Immunity(Player* player, uint32 source, std::initializer_list<uint32> mechanics, bool apply)
{
    for (uint32 mechanic : mechanics)
        player->ApplySpellImmune(source, IMMUNITY_MECHANIC, mechanic, apply);
}
class aura_ascension_cultist_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_cultist_lifecycle);
    void ScaleHerald(AuraEffect const*, AuraEffectHandleModes)
    {
        constexpr uint32 HeraldDisplay = 28844;
        if (GetTarget()->GetDisplayId() == HeraldDisplay && GetTarget()->getTransForm() == Herald)
            GetTarget()->SetObjectScale(0.25f);
    }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes mode)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        GetAura()->SetScriptValue(Insanity, ++State(player).sequence);
        if (id == 500751)
        {
            ObjectGuid previous = State(player).covenant;
            if (!previous.IsEmpty() && previous != target->GetGUID())
                if (Unit* old = ObjectAccessor::GetUnit(*player, previous))
                    old->RemoveAurasDueToSpell(id, player->GetGUID());
            State(player).covenant = target->GetGUID();
            Cast(player, player, 300295);
        }
        for (auto const& family : {std::vector<uint32>{803035, 803037, 803082, 803339},
            std::vector<uint32>{561386, 561387, 561389, 561390, 561391, 561392, 572637, 572791, 572819, 572905, 573067}})
            if (std::find(family.begin(), family.end(), id) != family.end())
                for (uint32 other : family)
                    if (other != id)
                        target->RemoveAurasDueToSpell(other, player->GetGUID());
        if (id == BlackBlood && GetEffect(EFFECT_0))
            Copy(player, target, 570263, std::max(0, GetEffect(EFFECT_0)->GetAmount()));
        if (id == 800432)
        {
            Cast(player, target, 802789);
            Cast(player, target, 803746);
        }
        if (id == 520345)
            Immunity(player, id, {MECHANIC_STUN, MECHANIC_SILENCE}, true);
        if (id == 520450)
            Cast(player, target, 520498);
        if (id == 807216)
            Cast(player, target, 807854);
        if (id == 520450 || id == 520497)
            if (AuraEffect* tick = GetEffect(EFFECT_0))
                tick->SetCritChance(player->GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + SPELL_SCHOOL_SHADOW));
        if (id == 806039)
            Cast(player, target, 520418);
        if (id == 582591 && (mode & AURA_EFFECT_HANDLE_REAPPLY))
        {
            GetEffect(EFFECT_1)->SetAmount(std::min<uint32>(INT32_MAX, player->GetMaxHealth()));
            GetEffect(EFFECT_2)->SetAmount(0);
        }
        if (target != player)
            return;
        if (id == Herald)
        {
            if (player->HasAura(300291))
                Cast(player, player, 301259);
            if (player->HasAura(807128))
            {
                Cast(player, player, 806769);
                Cast(player, player, 807312);
                Immunity(player, id, {MECHANIC_FEAR, MECHANIC_HORROR, MECHANIC_POLYMORPH}, true);
            }
            if (player->HasAura(300290))
                player->UpdateSpeed(MOVE_RUN, true);
        }
        if (id == 681104)
            Immunity(player, id, {MECHANIC_STUN}, true);
        if (id == 255281)
            Cast(player, player, 255283);
        if (id == 520388 && (mode & AURA_EFFECT_HANDLE_REAPPLY))
            GetAura()->SetCharges(5);
        Refresh(player);
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        uint8 index = effect->GetEffIndex();
        if (id == 582591)
        {
            amount = index == 0 ? -1 : index == 1 ? int32(std::min<uint32>(INT32_MAX, player->GetMaxHealth())) : 0;
            recalculate = false;
        }
        if (id == 706910 && index > 0)
        {
            amount = 0;
            recalculate = false;
        }
        if (Named(GetSpellInfo(), 567524) && index == 0)
            amount = player->HasAura(681088) ? -25 : 0;
        if (Named(GetSpellInfo(), 500715) && index == 0 && player->HasAura(301259))
            amount *= 2;
        if (id == 300277 && index == 2)
            amount = player->HasAura(805117) ? Amount(805117) : 0;
        if (id == 804275 && index == 2)
            amount = player->HasAura(524879) ? 0 : 20;
        if (id == 574147 && index == 0)
            amount = int32((player->GetFloatValue(UNIT_FIELD_MINDAMAGE) + player->GetFloatValue(UNIT_FIELD_MAXDAMAGE)) / 2);
        if ((id == 300290 && index == 1) || (id == 300287 && index == 0))
            amount = player->HasAura(Herald) ? amount : 0;
    }
    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetId();
        bool expired = GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE;
        Unit* target = GetTarget();
        if (id == 500751 && State(player).covenant == target->GetGUID())
        {
            State(player).covenant.Clear();
            player->RemoveAurasDueToSpell(300295);
        }
        if (id == 800432)
        {
            target->RemoveAurasDueToSpell(802789, player->GetGUID());
            target->RemoveAurasDueToSpell(803746, player->GetGUID());
        }
        if (id == 520450)
            target->RemoveAurasDueToSpell(520498, player->GetGUID());
        if (id == 807216)
            target->RemoveAurasDueToSpell(807854, player->GetGUID());
        if (id == 520345)
        {
            Immunity(player, id, {MECHANIC_STUN, MECHANIC_SILENCE}, false);
            AuraEffect* allyShield = target->GetAuraEffect(520346, EFFECT_0, player->GetGUID());
            AuraEffect* selfShield = player->GetAuraEffect(520346, EFFECT_1, player->GetGUID());
            if (expired && player->IsAlive() && target->IsAlive() && allyShield && selfShield &&
                allyShield->GetAmount() > 0 && selfShield->GetAmount() > 0 && player->IsInMap(target))
                player->NearTeleportTo(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), player->GetOrientation());
        }
        if (id == 582591 && player->IsAlive())
        {
            uint32 recorded = GetEffect(EFFECT_2) ? std::max(0, GetEffect(EFFECT_2)->GetAmount()) : 0;
            int32 percent = Amount(582591) + (player->HasAura(704881) ? Amount(704881) : 0);
            Copy(player, player, 680769, CalculatePct(recorded, percent));
        }
        if (target != player)
            return;
        if (id == Herald || id == Madness || Named(GetSpellInfo(), 567524))
            Resource(player, Insanity, -100, true);
        if (id == Madness)
            player->RemoveAurasDueToSpell(803060);
        if (id == Herald)
        {
            player->RemoveAurasDueToSpell(806769);
            player->RemoveAurasDueToSpell(807312);
            Immunity(player, id, {MECHANIC_FEAR, MECHANIC_HORROR, MECHANIC_POLYMORPH}, false);
        }
        if (id == 681104)
            Immunity(player, id, {MECHANIC_STUN}, false);
        if (id == 255281)
            player->RemoveAurasDueToSpell(255283);
        if (id == 804275)
        {
            player->RemoveAurasDueToSpell(807124);
            player->RemoveAurasDueToSpell(804277);
        }
        Refresh(player);
    }
    void Tick(AuraEffect const* effect)
    {
        if (GetId() == 800965 && GetTarget()->GetEntry() == 50298)
        {
            PreventDefaultAction();
            return;
        }
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
            return;
        uint32 id = GetId();
        uint8 index = effect->GetEffIndex();
        if (id == 500727 && !index && !player->IsInCombat() && !player->HasAura(706725))
            Resource(player, Insanity, -2, true);
        if (id == 255281 && index == 1)
            Resource(player, Insanity, -1, true);
        if (id == 520345 && !index)
            Cast(player, GetTarget(), 520346);
        if (id == 704476 && !index && player->HasAura(524877))
        {
            Cast(player, GetTarget(), 704473);
            Resource(player, Insanity, 5);
        }
        if (id == 807124 && index == 1)
        {
            PreventDefaultAction();
            Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
            if (channel && channel->GetSpellInfo()->Id == 804275 && channel->IsChannelActive())
                for (Unit* ally : Allies(player, player, Radius(807219)))
                    Cast(player, ally, 807219);
            else
                GetAura()->Remove();
        }
        if (id == 680609 && !index)
        {
            SetHelper(player, 567529, true);
            SetAmount(player, 567529, 0, player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DEFENSE_SKILL));
        }
        if (id == 800430 && index == 1 && GetAura()->GetType() == DYNOBJ_AURA_TYPE)
        {
            PreventDefaultAction();
            float range = Radius(800430);
            float distance = GetAura()->GetDynobjOwner()->GetExactDist2d(GetTarget());
            int32 slow = -int32(std::clamp(80.0f * (1 - distance / range), 0.0f, 80.0f));
            player->CastCustomSpell(802788, SPELLVALUE_BASE_POINT0, slow, GetTarget(), true);
        }
        if (id == 706910 && !index)
        {
            uint32 total = GetEffect(EFFECT_1) ? std::max(0, GetEffect(EFFECT_1)->GetAmount()) : 0;
            uint32 ticks = GetEffect(EFFECT_2) ? std::max(0, GetEffect(EFFECT_2)->GetAmount()) : 0;
            if (ticks)
            {
                uint32 amount = total / ticks;
                const_cast<AuraEffect*>(effect)->SetAmount(amount);
                GetEffect(EFFECT_1)->SetAmount(total - amount);
                GetEffect(EFFECT_2)->SetAmount(ticks - 1);
            }
        }
    }
    void Absorb(AuraEffect* effect, DamageInfo& damage, uint32& amount)
    {
        Player* player = Owner(GetCaster());
        if (!player || GetId() != 582591)
            return;
        uint32 budget = std::max(0, GetEffect(EFFECT_1)->GetAmount());
        uint32 covered = std::min(budget, damage.GetDamage());
        uint32 health = player->GetHealth();
        amount = covered >= health ? covered - health + 1 : 0;
        GetEffect(EFFECT_1)->SetAmount(budget - covered);
        int64 recorded = int64(GetEffect(EFFECT_2)->GetAmount()) + covered;
        GetEffect(EFFECT_2)->SetAmount(int32(std::min<int64>(INT32_MAX, recorded)));
        if (covered == budget)
            effect->SetAmount(amount);
    }
    void AfterAbsorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        Player* player = Owner(GetCaster());
        if (!player || !amount || GetId() == 582591)
            return;
        bool old = State(player).event;
        State(player).event = true;
        if (player->HasAura(681088))
        {
            int32 previous = player->GetAuraEffect(681067, EFFECT_0) ? player->GetAuraEffect(681067, EFFECT_0)->GetAmount() : 0;
            Copy(player, player, 681067, std::max(0, previous) + CalculatePct(amount, Amount(681088, 1)));
        }
        if (Named(GetSpellInfo(), 500715) && GetTarget() != player && player->HasAura(525060) && damage.GetAttacker())
            Copy(player, damage.GetAttacker(), 525062, CalculatePct(amount, Amount(525060)));
        State(player).event = old;
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_cultist_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_cultist_lifecycle::Remove, EFFECT_ALL, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_cultist_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId);
        if (!info)
            return;
        if (info->Id == Herald)
            AfterEffectApply += AuraEffectApplyFn(aura_ascension_cultist_lifecycle::ScaleHerald,
                EFFECT_0, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_SEND_FOR_CLIENT_MASK);
        bool periodic = false;
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            periodic |= info->Effects[i].IsAura() && info->Effects[i].Amplitude;
            if (info->Effects[i].IsAura(SPELL_AURA_SCHOOL_ABSORB))
            {
                if (info->Id == 582591)
                    OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_cultist_lifecycle::Absorb, SpellEffIndex(i));
                AfterEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_cultist_lifecycle::AfterAbsorb, SpellEffIndex(i));
            }
        }
        if (periodic)
            OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_cultist_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
    }
};
}
void AddSC_AscensionCultistAuras()
{
    RegisterSpellScript(aura_ascension_cultist_lifecycle);
}
