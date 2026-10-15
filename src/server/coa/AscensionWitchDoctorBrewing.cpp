/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchDoctorCompletion.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "ThreatManager.h"
#include <algorithm>

namespace AscensionWitchDoctor
{
void SyncIngredients(Player* player)
{
    DoctorState& state = State(player);
    if (state.swapping)
        return;
    state.swapping = true;
    auto& ingredients = state.ingredients;
    ingredients.erase(
        std::remove_if(ingredients.begin(), ingredients.end(), [player](uint32 id) { return !player->HasAura(id); }),
        ingredients.end());
    for (uint32 id : {Shrooms, Fish, Bones, Thistle})
        if (player->HasAura(id) && std::find(ingredients.begin(), ingredients.end(), id) == ingredients.end())
            ingredients.push_back(id);
    uint32 capacity = player->HasAura(Mixologist) || state.mojoPair ? 2 : 1;
    while (ingredients.size() > capacity)
    {
        uint32 id = ingredients.front();
        ingredients.erase(ingredients.begin());
        player->RemoveAurasDueToSpell(id);
    }
    if (!ingredients.empty() && player->HasAura(Brewer))
    {
        if (!player->HasAura(IngredientMarker))
            Cast(player, player, IngredientMarker);
        player->RemoveAurasDueToSpell(IngredientBlocker);
    }
    else
        player->RemoveAurasDueToSpell(IngredientMarker);
    state.swapping = false;
}
void IngredientChanged(Player* player, uint32 id, bool apply)
{
    auto& state = State(player);
    if (state.swapping)
        return;
    auto& ingredients = state.ingredients;
    ingredients.erase(std::remove(ingredients.begin(), ingredients.end(), id), ingredients.end());
    if (apply)
    {
        state.mojoPair = false;
        ingredients.push_back(id);
    }
    SyncIngredients(player);
}
void Mix(Player* player, uint32 mojo)
{
    auto& state = State(player);
    state.swapping = true;
    for (uint32 id : {Shrooms, Fish, Bones, Thistle})
        player->RemoveAurasDueToSpell(id);
    state.ingredients = mojo == MojoFish      ? std::vector<uint32>{Fish, Bones}
                        : mojo == MojoShrooms ? std::vector<uint32>{Shrooms, Bones}
                                              : std::vector<uint32>{Shrooms, Thistle};
    for (uint32 id : state.ingredients)
        Cast(player, player, id);
    state.mojoPair = true;
    state.swapping = false;
    Reduce(player, Potion, INT32_MAX);
    Reduce(player, Splash, INT32_MAX);
    SyncIngredients(player);
}
uint32 IngredientMask(Player* player)
{
    uint32 result = 0;
    for (uint32 id : State(player).ingredients)
        result |= id == Shrooms ? 1 : id == Fish ? 2 : id == Bones ? 4 : 8;
    return result;
}
void PotionEffects(Player* player, Unit* target, bool splash, uint32 mojo, uint32 ingredients)
{
    if (!target || !target->IsAlive() || !player->IsFriendlyTo(target))
        return;
    uint32 bit = 1;
    for (uint32 ingredient : {Shrooms, Fish, Bones, Thistle})
    {
        bool selected = ingredients & bit;
        bit <<= 1;
        if (!selected)
            continue;
        uint32 id = ingredient == Shrooms ? (splash ? SplashShrooms : PotionShrooms)
                    : ingredient == Fish  ? (splash ? SplashFish : PotionFish)
                    : ingredient == Bones ? (splash ? SplashBones : PotionBones)
                                          : (splash ? SplashThistle : PotionThistle);
        Cast(player, target, id);
        if (ingredient == Shrooms && player->HasAura(MasterConcoctions))
            Cast(player, target, ConcoctionsBuff);
    }
    if (mojo)
        Cast(player, target, mojo == MojoFish ? FishBones : mojo == MojoShrooms ? FrogShrooms : JungleThistle);
}
}

namespace
{
using namespace AscensionWitchDoctor;
class aura_ascension_witch_doctor_beam : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_doctor_beam);
    std::vector<ObjectGuid> _branches;
    uint32 _ticks = 0;

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = Owner(GetCaster()))
        {
            _branches.push_back(GetTarget()->GetGUID());
            Cast(player, player, BeamCost);
            if (Aura* cost = player->GetAura(BeamCost))
                cost->SetDuration(GetDuration());
        }
    }
    uint32 Heal(Player* player, Unit* target, uint32 amount)
    {
        SpellInfo const* info = GetSpellInfo();
        amount = player->SpellHealingBonusDone(target, info, amount, DOT, EFFECT_0);
        amount = target->SpellHealingBonusTaken(player, info, amount, DOT);
        float chance = player->SpellDoneCritChance(target, info, info->GetSchoolMask(), BASE_ATTACK, true);
        bool critical =
            roll_chance_f(target->SpellTakenCritChance(player, info, info->GetSchoolMask(), chance, BASE_ATTACK, true));
        if (critical)
            amount = Unit::SpellCriticalHealingBonus(player, info, amount, target);
        HealInfo heal(player, target, amount, info, info->GetSchoolMask());
        Unit::CalcHealAbsorb(heal);
        player->HealBySpell(heal, critical);
        Unit::ProcSkillsAndAuras(player, target, PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS,
                                 PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_POS,
                                 critical ? PROC_HIT_CRITICAL : PROC_HIT_NORMAL, heal.GetEffectiveHeal(), BASE_ATTACK,
                                 info, nullptr, -1, nullptr, nullptr, &heal);
        uint32 effective = heal.GetEffectiveHeal();
        target->GetThreatMgr().ForwardThreatForAssistingMe(player, float(effective) * 0.5f, info);
        if (effective && player->HasAura(SplashOnEm))
        {
            Reduce(player, Potion, 1000);
            Reduce(player, Splash, 1000);
        }
        if (effective && player->HasAura(Wave))
        {
            auto allies = Allies(player, target, 15.0f);
            allies.remove(target);
            uint32 cap = 2;
            for (Unit* ally : allies)
            {
                Copy(player, ally, WaveHeal, effective / 2);
                if (!--cap)
                    break;
            }
        }
        return effective;
    }
    void Tick(AuraEffect const* effect)
    {
        PreventDefaultAction();
        Player* player = Owner(GetCaster());
        if (!player || !player->IsAlive())
        {
            Remove();
            return;
        }
        Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
        if (!channel || channel->GetSpellInfo()->Id != GetId())
        {
            Remove();
            return;
        }
        _branches.erase(std::remove_if(_branches.begin(), _branches.end(),
                                       [player](ObjectGuid guid)
                                       {
                                           Unit* unit = ObjectAccessor::GetUnit(*player, guid);
                                           return !Friendly(player, unit) || !player->IsWithinDistInMap(unit, 40.0f) ||
                                                  !player->IsWithinLOSInMap(unit);
                                       }),
                        _branches.end());
        ++_ticks;
        uint32 cost = uint32(uint64(std::max(1, GetSpellInfo()->Effects[EFFECT_1].CalcValue(player))) *
                             std::max<size_t>(1, _branches.size()) * (100 + 10 * (_ticks - 1)) / 200);
        if (player->GetPower(POWER_MANA) < int32(cost))
        {
            player->InterruptSpell(CURRENT_CHANNELED_SPELL);
            return;
        }
        player->ModifyPower(POWER_MANA, -int32(cost));
        std::vector<ObjectGuid> previous = _branches;
        for (ObjectGuid guid : previous)
            if (Unit* target = ObjectAccessor::GetUnit(*player, guid))
            {
                Heal(player, target, std::max(0, effect->GetAmount()));
                if (_branches.size() < 8)
                    for (Unit* ally : Allies(player, target, 15.0f))
                        if (std::find(_branches.begin(), _branches.end(), ally->GetGUID()) == _branches.end() &&
                            player->IsWithinDistInMap(ally, 40.0f))
                        {
                            _branches.push_back(ally->GetGUID());
                            Heal(player, ally, std::max(0, effect->GetAmount()));
                            break;
                        }
            }
    }
    void Removed(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = Owner(GetCaster()))
            player->RemoveAurasDueToSpell(BeamCost);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_witch_doctor_beam::Apply, EFFECT_0,
                                              SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic +=
            AuraEffectPeriodicFn(aura_ascension_witch_doctor_beam::Tick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_witch_doctor_beam::Removed, EFFECT_0,
                                                SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};
}
void AddAscensionWitchDoctorBrewingScripts()
{
    RegisterSpellScript(aura_ascension_witch_doctor_beam);
}
