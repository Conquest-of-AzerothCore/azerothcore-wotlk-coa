/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionVenomancer.h"
#include "AscensionVenomancerData.h"
#include "CellImpl.h"
#include "DynamicObject.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <tuple>
#include <unordered_map>
namespace AscensionVenomancer
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<VenomancerState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    if (!unit)
        return nullptr;
    Player* player = const_cast<Unit*>(unit)->ToPlayer();
    if (!player && unit->GetOwner())
        player = unit->GetOwner()->ToPlayer();
    return player && player->getClass() == CLASS_PROPHET ? player : nullptr;
}
VenomancerState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<VenomancerState>()).first->second;
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
        for (uint32 id : VenomancerCopies)
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
bool Spender(SpellInfo const* info)
{
    return Any(info, {804961, 800871, 804977});
}
bool Poison(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 35 && (info->Dispel == DISPEL_POISON ||
        Any(info, {804982,804983,800871,804977,706962,800882,803195,705985,805896}));
}
bool Venom(SpellInfo const* info)
{
    return Any(info, {630869,805894,805895,805896,805897,706000});
}
bool HasDispel(Unit const* target, uint32 dispel)
{
    if (target)
        for (auto const& pair : target->GetAppliedAuras())
            if (pair.second->GetBase()->GetSpellInfo()->Dispel == dispel)
                return true;
    return false;
}
float HealingFactor(Player* player, Unit* target, SpellInfo const* info)
{
    if (!info || !target || info->SpellFamilyName != 35 || Derived(info))
        return 1;
    float factor = 1;
    if (player->HasAura(706015) && (target->GetHealthPct() < 35 || HasDispel(target,DISPEL_POISON)))
        factor *= 1 + Amount(706015) / 100.0f;
    if (Any(info,{800870,800902,504342}) || info->Id == 803529)
        if (auto* talent = player->GetAuraEffectOfRankedSpell(706009,EFFECT_0))
            factor *= 1 + talent->GetAmount() / 100.0f;
    return factor;
}
bool CrossesLair(Unit const* attacker, Unit const* target)
{
    if (!attacker || !target || attacker == target || !attacker->IsInWorld() || !target->IsInWorld() ||
        !attacker->IsInMap(target))
        return false;
    for (Unit const* unit : {attacker,target})
        for (auto const& pair : unit->GetAppliedAuras())
            if (Aura* aura = pair.second->GetBase(); aura->GetId() == 804978)
                if (Unit* caster = aura->GetCaster(); caster && caster->IsHostileTo(attacker))
                    if (DynamicObject* lair = caster->GetDynObject(804978))
                        if (lair->IsWithinDistInMap(attacker,lair->GetRadius()) !=
                            lair->IsWithinDistInMap(target,lair->GetRadius()))
                            return true;
    return false;
}
void AddFungic(Player* player, Unit* target, uint32 damage)
{
    uint32 previous = 0;
    if (Aura* aura = target->GetAura(706456,player->GetGUID()))
        if (AuraEffect* effect = aura->GetEffect(aura->GetStackAmount() > 1 ? EFFECT_2 : EFFECT_1))
            previous = uint32(std::max(0,effect->GetAmount()));
    Copy(player,target,706456,1);
    if (Aura* aura = target->GetAura(706456,player->GetGUID()))
    {
        aura->SetStackAmount(previous ? 2 : 1);
        aura->GetEffect(EFFECT_1)->SetAmount(previous ? int32(previous) : int32(damage/5));
        aura->GetEffect(EFFECT_2)->SetAmount(previous ? int32(damage/5) : 0);
        aura->GetEffect(EFFECT_0)->SetAmount(0);
    }
}
void Mana(Player* player, uint32 amount)
{
    if (amount)
        player->EnergizeBySpell(player, 681318, int32(std::min<uint32>(amount, INT32_MAX)), POWER_MANA);
}
bool Chance(Player* player, uint32 id, uint32 cooldown)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    if (!info || !player->HasAura(id) || State(player).timers.HasTimeUntilEvent(id) ||
        !roll_chance_i(std::min<uint32>(100, info->ProcChance)))
        return false;
    if (cooldown)
        State(player).timers.ScheduleEvent(id, Milliseconds(cooldown));
    return true;
}
bool Resource(Player* player, uint32 id, int32 delta)
{
    if (!player || player->getClass() != CLASS_PROPHET || id != Brood)
        return false;
    uint32 maximum = sSpellMgr->GetSpellInfo(Brood)->CalcMaxAuraStacks(player);
    uint32 after = uint32(std::clamp<int64>(int64(Count(player, Brood)) + delta, 0, maximum));
    if (!after)
        player->RemoveAurasDueToSpell(Brood);
    else if (Aura* aura = player->GetAura(Brood))
        aura->SetStackAmount(after);
    else if (Aura* added = player->AddAura(Brood, player))
        added->SetStackAmount(after);
    return true;
}
float BroodMultiplier(uint32 count, int32 effectiveness)
{
    constexpr float multipliers[] = {1, 1.25f, 1.60f, 2.05f, 2.60f, 3.50f};
    return 1 + (multipliers[std::min(count, 5u)] - 1) * (1 + effectiveness / 100.0f);
}
void Expose(Player* player, uint32 stacks, bool molt)
{
    uint32 maximum = sSpellMgr->GetSpellInfo(Exposed)->CalcMaxAuraStacks(player);
    uint32 current = Count(player, Exposed);
    uint32 after = molt ? 15 : std::max(current, std::min(maximum, current + stacks));
    if (Aura* aura = player->GetAura(Exposed))
    {
        aura->RefreshTimers();
        aura->SetStackAmount(after);
    }
    else if (Aura* added = player->AddAura(Exposed, player))
        added->SetStackAmount(after);
    uint32 applied = Count(player, Exposed);
    if (applied > current && player->HasAura(CharmOfWarding))
    {
        SpellInfo const* talent = sSpellMgr->GetSpellInfo(CharmOfWarding);
        HealInfo heal(player, player, player->CountPctFromMaxHealth((applied - current) * Amount(CharmOfWarding)),
            talent, talent->GetSchoolMask());
        player->HealBySpell(heal);
    }
    if (!molt)
        player->EnergizeBySpell(player, 805100, Amount(805100), POWER_RAGE);
}
uint32 ClearExposed(Player* player)
{
    uint32 stacks = Count(player, Exposed);
    player->RemoveAurasDueToSpell(Exposed);
    if (stacks && player->HasAura(805103) && player->HasAura(Beetle))
        Copy(player, player, 805348, stacks * uint32(std::max(0, Amount(805348, 0, player))));
    return stacks;
}
void ReducePercent(Player* player, uint32 root, int32 percent)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            player->ModifySpellCooldown(pair.first, -int32(CalculatePct(
                player->GetSpellCooldownDelay(pair.first), std::clamp(percent, 0, 100))));
}
void ExtendOwned(Player* player, Unit* target, uint32 root, int32 milliseconds)
{
    for (auto const& pair : target->GetAppliedAuras())
    {
        Aura* aura = pair.second->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID() || !Named(aura->GetSpellInfo(), root) || aura->GetDuration() <= 0)
            continue;
        int32 duration = int32(std::clamp<int64>(int64(aura->GetDuration()) + milliseconds, 0, INT32_MAX));
        aura->SetMaxDuration(std::max(aura->GetMaxDuration(), duration));
        aura->SetDuration(duration);
        return;
    }
}
void Spread(Player* player, Unit* source, Unit* target, uint32 root)
{
    if (!source || !target || source == target)
        return;
    for (auto const& pair : source->GetAppliedAuras())
    {
        Aura* aura = pair.second->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID() || !Named(aura->GetSpellInfo(), root) || aura->GetDuration() <= 0)
            continue;
        Cast(player, target, aura->GetId());
        if (Aura* added = target->GetAura(aura->GetId(), player->GetGUID()))
        {
            added->SetStackAmount(aura->GetStackAmount());
            added->SetMaxDuration(aura->GetMaxDuration());
            added->SetDuration(aura->GetDuration());
            for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                if (AuraEffect* effect = added->GetEffect(slot); effect && aura->GetEffect(slot))
                {
                    effect->SetAmount(aura->GetEffect(slot)->GetAmount());
                    effect->SetPctMods(aura->GetEffect(slot)->GetPctMods());
                    effect->SetCritChance(aura->GetEffect(slot)->GetCritChance());
                    effect->SetPeriodicTimer(aura->GetEffect(slot)->GetPeriodicTimer());
                }
        }
        return;
    }
}
void ApplyVenoms(Player* player, Unit* target, bool fromSpiderling)
{
    for (auto [activation, helper] : {std::pair(630868u,630869u), std::pair(805731u,805895u),
        std::pair(805775u,805894u), std::pair(805776u,805896u), std::pair(805777u,805897u), std::pair(805778u,706000u)})
        if (player->HasAura(activation))
        {
            if (fromSpiderling && helper == 706000)
            {
                SpellInfo const* info = sSpellMgr->GetSpellInfo(helper);
                if (!info || !player->IsInWorld() || !target || !target->IsAlive())
                    continue;
                SpellCastTargets targets;
                targets.SetUnitTarget(target);
                Spell* venom = new Spell(player, info, TRIGGERED_FULL_MASK);
                venom->SetScriptValue(SpiderlingVenomSource, 1);
                venom->prepare(&targets);
            }
            else if (helper == 805894)
                Cast(player, player, helper);
            else if (helper == 630869)
                player->CastSpell(target->GetPositionX(),target->GetPositionY(),target->GetPositionZ(),helper,true);
            else
                Cast(player, target, helper);
        }
}
void UpdateSpiderLordDisplay(Player* player)
{
    bool spiderLord = player->HasAura(Beetle) && player->HasAura(SpiderLord);
    uint32 beetleDisplay = player->GetModelForForm(player->GetShapeshiftForm(), Beetle);
    if (spiderLord && beetleDisplay && player->GetDisplayId() == beetleDisplay)
    {
        float boundingRadius = player->GetFloatValue(UNIT_FIELD_BOUNDINGRADIUS);
        float combatReach = player->GetCombatReach();
        player->SetDisplayId(SpiderLordDisplay);
        player->SetFloatValue(UNIT_FIELD_BOUNDINGRADIUS, boundingRadius);
        player->SetFloatValue(UNIT_FIELD_COMBATREACH, combatReach);
    }
    else if (!spiderLord && player->GetDisplayId() == SpiderLordDisplay)
        player->RestoreDisplayId();
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing || !player->IsInWorld())
        return;
    state.refreshing = true;
    bool spider = player->IsAlive() && player->HasAura(Spider);
    bool beetle = player->IsAlive() && player->HasAura(Beetle);
    SetHelper(player, 803216, beetle);
    SetHelper(player, 807726, beetle);
    SetHelper(player, 805098, beetle && (player->HasAura(92144) || player->HasSpell(92144)));
    SetHelper(player, 804981, player->IsAlive() && player->HasAura(804980));
    SetHelper(player, 560281, player->IsAlive() && player->HasAura(800912));
    SetHelper(player, 800293, spider && player->HasAura(805104));
    SetHelper(player, 800389, spider && player->HasAura(805140));
    SetHelper(player, 805139, beetle && player->HasAura(SpiderLord));
    UpdateSpiderLordDisplay(player);
    SetHelper(player, 504792, player->HasAura(503856));
    SetAmount(player, 803216, 1, int32(5 * (player->GetStat(STAT_INTELLECT) + player->GetStat(STAT_AGILITY))));
    SetAmount(player, 705970, 0, beetle ? Amount(705970) : 0);
    float attributes = 0;
    for (uint8 stat = 0; stat < MAX_STATS; ++stat)
        attributes += player->GetStat(Stats(stat));
    SetAmount(player, 705970, 1, int32(attributes * Amount(705970, 1) / 100.0f));
    if (!spider)
        player->RemoveAurasDueToSpell(804962);
    if (!beetle)
    {
        player->RemoveAurasDueToSpell(800892);
        player->RemoveAurasDueToSpell(800960);
        player->RemoveAurasDueToSpell(805931);
    }
    if (player->HasAura(Skulk) && player->HasAura(706026))
    {
        SetHelper(player, 707358, true);
        if (Aura* aura = player->GetAura(707358))
            aura->SetDuration(4000);
    }
    for (auto [talent, active] : {std::pair(706940u,804980u), std::pair(504798u,800912u),
                                 std::pair(805238u,681056u)})
    {
        bool enabled = player->HasAura(talent) || player->HasSpell(talent);
        if (enabled && !player->HasSpell(active))
            player->learnSpell(active, true);
        else if (!enabled)
            player->removeSpell(active, SPEC_MASK_ALL, true);
    }
    bool widowsKiss = player->HasAura(807600);
    for (auto [root, replacement, known, enabled] : {std::tuple(800880u,504705u,widowsKiss,
             widowsKiss && Count(player,807244) >= 2),
             std::tuple(800887u,504706u,player->HasAura(630932),player->HasAura(630932))})
    {
        if (known && !player->HasSpell(replacement))
            player->learnSpell(replacement, true);
        for (auto const& pair : player->GetSpellMap())
            if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first),root))
                player->SetTemporarySpellReplacement(pair.first,enabled ? replacement : 0);
        if (!known)
            player->removeSpell(replacement,SPEC_MASK_ALL,true);
    }
    if (!state.host.IsEmpty())
    {
        Unit* host = ObjectAccessor::GetUnit(*player,state.host);
        if (host && host->IsAlive() && player->IsInMap(host))
        {
            state.exit.Relocate(*host);
            if (player->HasAura(800921) && player->GetDistance(host) > 2)
                player->NearTeleportTo(host->GetPositionX(),host->GetPositionY(),host->GetPositionZ(),host->GetOrientation());
        }
        else
            player->RemoveAurasDueToSpell(800921);
    }
    state.refreshing = false;
}
}
namespace
{
class venomancer_player : public PlayerScript
{
public:
    venomancer_player() : PlayerScript("venomancer_player", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT}) { }
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        using namespace AscensionVenomancer;
        if (Owner(player) != player)
            return;
        auto& state = State(player);
        state.timers.Update(diff);
        while (state.timers.ExecuteEvent()) { }
        state.scheduler.Update(diff);
        if (!state.timers.HasTimeUntilEvent(Brood))
        {
            state.timers.ScheduleEvent(Brood, 500ms);
            Refresh(player);
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        using namespace AscensionVenomancer;
        if (Owner(player) == player)
            ExitParasite(player);
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetGUID());
    }
};
class venomancer_unit : public UnitScript
{
public:
    venomancer_unit() : UnitScript("venomancer_unit", true, {UNITHOOK_ON_DISPLAYID_CHANGE}) { }
    void OnDisplayIdChange(Unit* unit, uint32) override
    {
        if (Player* player = AscensionVenomancer::Owner(unit); player == unit)
            AscensionVenomancer::UpdateSpiderLordDisplay(player);
    }
};
}
void AddSC_AscensionVenomancer()
{
    new venomancer_player();
    new venomancer_unit();
}
