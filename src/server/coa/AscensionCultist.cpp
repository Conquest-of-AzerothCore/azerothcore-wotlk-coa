/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "AscensionCultistData.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <tuple>
#include <unordered_map>
namespace AscensionCultist
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<CultistState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    if (!unit)
        return nullptr;
    Player* player = const_cast<Unit*>(unit)->ToPlayer();
    if (!player && unit->GetOwner())
        player = unit->GetOwner()->ToPlayer();
    return player && player->getClass() == CLASS_CULTIST ? player : nullptr;
}
CultistState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<CultistState>()).first->second;
}
bool Named(SpellInfo const* info, uint32 root)
{
    return info && sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(root);
}
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots)
{
    for (uint32 root : roots)
        if (Named(info, root))
            return true;
    return false;
}
bool Derived(SpellInfo const* info)
{
    if (info)
        for (uint32 id : CultistCopies)
            if (info->Id == id)
                return true;
    return false;
}
uint32 Count(Unit const* unit, uint32 id)
{
    Aura const* aura = unit ? unit->GetAura(id) : nullptr;
    return aura ? aura->GetStackAmount() : 0;
}
int32 Amount(uint32 id, uint8 slot, Unit* caster)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    return info ? info->Effects[slot].CalcValue(caster) : 0;
}
float Radius(uint32 id, uint8 slot)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    return info && info->Effects[slot].RadiusEntry ? info->Effects[slot].CalcRadius() : 10.0f;
}
void Cast(Unit* caster, Unit* target, uint32 id)
{
    if (caster && target && target->IsAlive() && caster->IsInWorld())
        caster->CastSpell(target, id, true);
}
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount)
{
    if (caster && target && target->IsAlive() && amount)
        caster->CastCustomSpell(id, SPELLVALUE_BASE_POINT0, int32(std::min<uint32>(amount, INT32_MAX)), target, true);
}
void Mana(Player* player, uint32 amount)
{
    if (amount)
        player->EnergizeBySpell(player, 520773, int32(std::min<uint32>(amount, INT32_MAX)), POWER_MANA);
}
bool Chance(Player* player, uint32 id, uint32 cooldown)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    float chance = info ? float(info->ProcChance) : 0;
    if ((id == 300313 || id == 706245) && Count(player, Insanity) > 40 && player->HasAura(707753))
        chance += Amount(707753);
    if (!info || !player->HasAura(id) || State(player).timers.HasTimeUntilEvent(id) ||
        !roll_chance_f(std::clamp(chance, 0.0f, 100.0f)))
        return false;
    if (cooldown)
        State(player).timers.ScheduleEvent(id, Milliseconds(cooldown));
    return true;
}
uint32 Highest(Player* player, uint32 root)
{
    uint32 result = root;
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root) &&
            sSpellMgr->GetSpellInfo(pair.first)->SpellLevel >= sSpellMgr->GetSpellInfo(result)->SpellLevel)
            result = pair.first;
    return result;
}
void Reduce(Player* player, uint32 root, int32 milliseconds)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
        {
            if (milliseconds == INT32_MAX)
                player->RemoveSpellCooldown(pair.first, true);
            else
                player->ModifySpellCooldown(pair.first, -milliseconds);
        }
}
void RestoreBlade(Player* player)
{
    player->RestoreSpellCharge(Highest(player, 500720));
}
void SetHelper(Player* player, uint32 id, bool enabled)
{
    if (enabled && !player->HasAura(id))
        Cast(player, player, id);
    else if (!enabled)
        player->RemoveAurasDueToSpell(id);
}
void SetAmount(Player* player, uint32 id, uint8 slot, int32 amount)
{
    if (AuraEffect* effect = player->GetAuraEffect(id, slot))
        if (effect->GetAmount() != amount)
            effect->ChangeAmount(amount);
}
bool Resource(Player* player, uint32 id, int32 delta, bool force)
{
    if (!player || player->getClass() != CLASS_CULTIST || id != Insanity)
        return false;
    if (delta < 0 && player->HasAura(Madness) && !force)
        return true;
    uint32 before = Count(player, id);
    uint32 after = uint32(std::clamp<int64>(int64(before) + delta, 0, 100));
    if (!after)
        player->RemoveAurasDueToSpell(id);
    else if (Aura* aura = player->GetAura(id))
        aura->SetStackAmount(after);
    else if (Aura* added = player->AddAura(id, player))
        added->SetStackAmount(after);
    after = Count(player, id);
    if (before < 60 && after >= 60 && player->HasAura(300307))
        Cast(player, player, 573285);
    if (after == 100 && before < 100 && !player->HasSpell(92131) && !player->HasSpell(805120) &&
        !player->HasSpell(680750))
        Cast(player, player, 803060);
    Refresh(player);
    return true;
}
std::list<Unit*> Nearby(Unit* center, float range)
{
    std::list<Unit*> result;
    if (!center || !center->IsInWorld())
        return result;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, result, check);
    Cell::VisitObjects(center, search, range);
    result.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    result.sort([](Unit* a, Unit* b) { return a->GetGUID() < b->GetGUID(); });
    return result;
}
std::list<Unit*> Allies(Player* player, Unit* center, float range, uint32 count)
{
    auto result = Nearby(center, range);
    if (center->IsAlive() && std::find(result.begin(), result.end(), center) == result.end())
        result.push_back(center);
    result.remove_if([player](Unit* unit)
    {
        return (unit != player && !player->IsInRaidWith(unit)) || !player->IsFriendlyTo(unit);
    });
    result.sort([](Unit* a, Unit* b)
    {
        return a->GetHealthPct() == b->GetHealthPct() ? a->GetGUID() < b->GetGUID()
                                                   : a->GetHealthPct() < b->GetHealthPct();
    });
    if (count && result.size() > count)
        result.resize(count);
    return result;
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing || !player->IsInWorld())
        return;
    state.refreshing = true;
    if (state.covenant.IsEmpty())
        for (Unit* ally : Nearby(player, 100))
            if (ally->HasAura(500751, player->GetGUID()))
            {
                state.covenant = ally->GetGUID();
                SetHelper(player, 300295, true);
                break;
            }
    uint32 stacks = Count(player, Insanity);
    for (auto [marker, required] : {std::pair(680601u, 20u), std::pair(680602u, 40u),
                                     std::pair(680603u, 60u), std::pair(680604u, 80u)})
        SetHelper(player, marker, player->IsAlive() && stacks >= required);
    for (auto [talent, helper, required] : CultistThresholds)
        SetHelper(player, helper, player->IsAlive() && player->HasAura(talent) && stacks > required);
    if (stacks < 20)
    {
        player->RemoveAurasDueToSpell(255281);
        player->RemoveAurasDueToSpell(255283);
    }
    if (player->HasAura(680555))
        SetAmount(player, 680555, 0, Amount(680555) * (stacks > 60 ? 2 : 1));
    if (player->HasAura(Insanity))
    {
        SetAmount(player, Insanity, 2, player->HasAura(681106) ? int32(stacks) * Amount(681106) : 0);
        SetAmount(player, Insanity, 1, 0);
    }
    SetHelper(player, 805606, player->HasSpell(92130));
    SetHelper(player, 680556, player->HasAura(680557) && player->GetAuraOfRankedSpell(567524));
    SetHelper(player, 573315, stacks > 60);
    SetAmount(player, 680574, 1, Amount(680574, 1) * (stacks > 60 ? 2 : 1));
    SetAmount(player, 680607, 0, stacks / 20);
    SetAmount(player, 574147, 0, int32((player->GetFloatValue(UNIT_FIELD_MINDAMAGE) +
        player->GetFloatValue(UNIT_FIELD_MAXDAMAGE)) / 2));
    SetAmount(player, 300290, 1, player->HasAura(Herald) ? Amount(300290, 1) : 0);
    SetAmount(player, 300287, 0, player->HasAura(Herald) ? Amount(300287) : 0);
    if (player->HasAura(680579))
    {
        SetHelper(player, 681476, true);
        SetAmount(player, 681476, 0, player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DODGE) +
                                       player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_PARRY));
    }
    else
        SetHelper(player, 681476, false);
    if (player->HasAura(806264))
    {
        SetHelper(player, 807883, true);
        SetAmount(player, 807883, 0, int32(2.5f * player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_CRIT_SPELL)));
    }
    else
        SetHelper(player, 807883, false);
    SetHelper(player, 500727, player->IsAlive() && (stacks || player->HasSpell(Insanity)));
    for (auto [root, replacement, active] : {std::tuple(804670u, 804711u, player->HasAura(706182)),
             std::tuple(800416u, 504719u, player->HasAura(255070)),
             std::tuple(500110u, 680576u, player->HasAura(681794)),
             std::tuple(524876u, 255282u, player->HasAura(255281))})
    {
        active = active && player->IsAlive() && player->HasSpell(Highest(player, root));
        if (active && !player->HasSpell(replacement))
            player->learnSpell(replacement, true);
        for (auto const& pair : player->GetSpellMap())
            if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
                player->SetTemporarySpellReplacement(pair.first, active ? replacement : 0);
        if (!active)
            player->removeSpell(replacement, SPEC_MASK_ALL, true);
    }
    state.refreshing = false;
}
void Accumulate(Player* player, Unit* target, uint32 id, uint32 total)
{
    Aura* existing = target->GetAura(id, player->GetGUID());
    uint64 pending = total;
    if (existing && existing->GetEffect(EFFECT_1))
        pending += std::max(0, existing->GetEffect(EFFECT_1)->GetAmount());
    int32 next = existing && existing->GetEffect(EFFECT_0) ? existing->GetEffect(EFFECT_0)->GetPeriodicTimer() : -1;
    Cast(player, target, id);
    if (Aura* aura = target->GetAura(id, player->GetGUID()))
    {
        if (AuraEffect* budget = aura->GetEffect(EFFECT_1))
            budget->SetAmount(int32(std::min<uint64>(INT32_MAX, pending)));
        if (AuraEffect* ticks = aura->GetEffect(EFFECT_2))
            ticks->SetAmount(std::max(1, (aura->GetDuration() + int32(aura->GetEffect(EFFECT_0)->GetAmplitude()) - 1) /
                int32(aura->GetEffect(EFFECT_0)->GetAmplitude())));
        if (AuraEffect* tick = aura->GetEffect(EFFECT_0); tick && next >= 0)
            tick->SetPeriodicTimer(next);
    }
}
}
namespace
{
class cultist_player : public PlayerScript
{
public:
    cultist_player() : PlayerScript("cultist_player", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT}) { }
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        using namespace AscensionCultist;
        if (Owner(player) != player)
            return;
        auto& state = State(player);
        state.timers.Update(diff);
        while (state.timers.ExecuteEvent()) { }
        state.scheduler.Update(diff);
        UpdateDash(player, diff);
        if (!state.timers.HasTimeUntilEvent(Insanity))
        {
            state.timers.ScheduleEvent(Insanity, 500ms);
            Refresh(player);
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(AscensionCultist::stateMutex);
        AscensionCultist::states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionCultist()
{
    new cultist_player();
}
