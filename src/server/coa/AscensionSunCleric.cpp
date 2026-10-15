/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunCleric.h"
#include "AscensionSunClericData.h"
#include "CellImpl.h"
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
namespace AscensionSunCleric
{
namespace
{
constexpr uint32 Fortuitous = 561328;
constexpr uint32 FortuitousHelper = 561396;
std::unordered_map<ObjectGuid, std::unique_ptr<SunClericState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    if (!unit)
        return nullptr;
    Player* player = const_cast<Unit*>(unit)->ToPlayer();
    if (!player && unit->GetOwner())
        player = unit->GetOwner()->ToPlayer();
    return player && player->getClass() == CLASS_SUN_CLERIC ? player : nullptr;
}
SunClericState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<SunClericState>()).first->second;
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
        for (uint32 id : SunClericCopies)
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
    if (enabled && id == FortuitousHelper)
        if (Aura* aura = player->GetAura(id))
            if (aura->GetDuration() >= 0 || aura->GetMaxDuration() >= 0)
            {
                aura->SetMaxDuration(-1);
                aura->SetDuration(-1);
            }
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
bool Invocation(SpellInfo const* info)
{
    return Any(info, {800764, 500152, 503651, 806159});
}
bool Gavel(SpellInfo const* info)
{
    return Any(info, {800611, 800614, 800617});
}
Spell* Origin(Player* player, Spell* spell)
{
    if (!spell || spell->GetCaster() != player)
        return spell;
    uint32 id = spell->GetSpellInfo()->Id;
    if (id == 807058 || id == 805639)
        if (Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            if (Named(channel->GetSpellInfo(), id == 807058 ? 806060 : 805629))
                return channel;
    if (Spell* parent = player->GetCurrentSpell(CURRENT_GENERIC_SPELL);
        parent && parent != spell && parent->GetSpellInfo()->SpellFamilyName == 33)
        for (auto const& effect : parent->GetSpellInfo()->Effects)
            if (effect.TriggerSpell == id)
                return parent;
    return spell;
}
void Mana(Player* player, uint32 amount)
{
    if (amount)
        player->EnergizeBySpell(player, 504877, int32(std::min<uint32>(amount, INT32_MAX)), POWER_MANA);
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
void ReducePercent(Player* player, uint32 root, int32 percent)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            player->ModifySpellCooldown(pair.first, -int32(CalculatePct(
                player->GetSpellCooldownDelay(pair.first), std::clamp(percent, 0, 100))));
}
void ReduceInvocations(Player* player, int32 milliseconds)
{
    for (uint32 root : {800764, 500152, 503651, 806159})
        Reduce(player, root, milliseconds);
}
void Extend(Player* player, uint32 id, int32 milliseconds)
{
    Aura* aura = player->GetAura(id);
    if (!aura)
    {
        Cast(player, player, id);
        aura = player->GetAura(id);
        if (aura)
            aura->SetDuration(milliseconds);
    }
    else
        aura->SetDuration(int32(std::min<int64>(INT32_MAX, int64(aura->GetDuration()) + milliseconds)));
    if (aura)
        aura->SetMaxDuration(std::max(aura->GetMaxDuration(), aura->GetDuration()));
}
void StackWithoutRefresh(Player* player, uint32 id)
{
    if (Aura* aura = player->GetAura(id))
    {
        int32 remaining = aura->GetDuration();
        aura->ModStackAmount(1);
        aura->SetDuration(remaining);
    }
    else
        Cast(player, player, id);
}
bool Resource(Player* player, uint32 id, int32 delta)
{
    if (!player || player->getClass() != CLASS_SUN_CLERIC || id != SolarPower)
        return false;
    if (delta > 0 && (player->HasAura(Dawn) || State(player).dawnEvent))
        return true;
    uint32 after = uint32(std::clamp<int64>(int64(Count(player, id)) + delta, 0, 20));
    if (!after)
        player->RemoveAurasDueToSpell(id);
    else if (Aura* aura = player->GetAura(id))
        aura->SetStackAmount(after);
    else if (Aura* added = player->AddAura(id, player))
        added->SetStackAmount(after);
    SetHelper(player, 704396, Count(player, id) == 20 && !player->HasAura(Dawn));
    return true;
}
void ActivateDawn(Player* player)
{
    Resource(player, SolarPower, -20);
    Cast(player, player, Dawn);
    if (Aura* aura = player->GetAura(Dawn))
        aura->SetCharges(10);
    if (AuraEffect* choice = player->GetAuraEffect(Dawn, EFFECT_0))
        choice->SetAmount(1);
    if (player->HasAura(704586))
        Cast(player, player, 805265);
    if (player->HasAura(804625))
        Cast(player, player, 807059);
    if (player->HasAura(561204) || player->HasAura(301301))
        Extend(player, 800054, std::abs(Amount(302907)));
    if (player->HasAura(707414))
        for (uint32 root : {800054, 520024, 805629})
            ReducePercent(player, root, std::abs(Amount(712380)));
    if (player->HasSpell(520639) || player->HasAura(520639))
        for (auto [spec, helper] : {std::pair(800586u, 520641u), std::pair(500207u, 520644u),
                                    std::pair(500209u, 520645u), std::pair(680627u, 520646u)})
            if (player->HasSpell(spec) || player->HasAura(spec))
                Cast(player, player, helper);
    Refresh(player);
}
void Fulfill(Player* player, Spell* spell, Unit* target)
{
    if (!spell || !spell->GetScriptValue(Dawn) || spell->GetScriptValue(807441))
        return;
    spell->SetScriptValue(807441, 1);
    if (player->HasAura(805581))
        Reduce(player, 500154, std::abs(Amount(807445)));
    if (player->HasAura(680622))
        Cast(player, player, 680623);
    if (player->HasAura(704562))
        Cast(player, player, 680672);
    if (player->HasSpell(92136) || player->HasAura(92136))
        for (Unit* ally : Allies(player,player,Radius(704911),sSpellMgr->GetSpellInfo(704911)->MaxAffectedTargets))
            Cast(player, ally, 704911);
    if (player->HasAura(707081) && target && player->IsValidAttackTarget(target))
        Cast(player, target, 657125);
}
void Eclipse(Player* player, Unit* target, uint32 amount)
{
    if (!amount || !target || !player->IsValidAttackTarget(target))
        return;
    if (AuraEffect* effect = target->GetAuraEffect(505340, EFFECT_0, player->GetGUID()))
        effect->SetAmount(int32(std::min<uint64>(INT32_MAX, uint64(std::max(0, effect->GetAmount())) + amount)));
    else
        Copy(player, target, 505340, amount);
    if (player->HasAura(704579) && (!target->ToCreature() || !target->ToCreature()->IsDungeonBoss()))
        Cast(player, target, 505342);
}
bool Daytime()
{
    time_t now = time_t(GameTime::GetGameTime().count());
    tm local{};
#ifdef _WIN32
    localtime_s(&local, &now);
#else
    localtime_r(&now, &local);
#endif
    return local.tm_hour >= 6 && local.tm_hour < 18;
}
void ReleaseSuncharge(Player* player, Unit* target, uint32 stacks)
{
    if (!stacks || !target || !target->IsAlive())
        return;
    uint32 previous = State(player).sunchargeStacks;
    State(player).sunchargeStacks = stacks;
    Cast(player,target,807064);
    State(player).sunchargeStacks = previous;
    target->RemoveAurasDueToSpell(807080,player->GetGUID());
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing || !player->IsInWorld())
        return;
    state.refreshing = true;
    SetHelper(player, 704396, player->IsAlive() && Count(player, SolarPower) == 20 && !player->HasAura(Dawn));
    if (state.blessed.IsEmpty())
        for (Unit* ally : Nearby(player, 100))
            if (ally != player && ally->HasAura(Bless, player->GetGUID()))
            {
                state.blessed = ally->GetGUID();
                break;
            }
    if (!player->IsAlive())
        state.healthyAbove80 = false;
    else if (player->GetHealthPct() > 80)
        state.healthyAbove80 = true;
    else if (player->GetHealthPct() <= 75)
        state.healthyAbove80 = false;
    bool healthy = state.healthyAbove80;
    for (auto [talent, helper] : {std::pair(Fortuitous, FortuitousHelper), std::pair(704585u, 707769u),
                                std::pair(805267u, 807876u), std::pair(300314u, 301341u)})
        SetHelper(player, helper, healthy && player->HasAura(talent));
    bool day = player->IsAlive() && Daytime();
    SetHelper(player, 707768, day && player->HasAura(707078));
    int32 extraHaste = 0;
    for (uint32 id : {300363, 300621, 300626})
        if (player->HasAura(id))
            extraHaste = Amount(id, 1);
    SetHelper(player, 300364, day && extraHaste);
    SetAmount(player, 300364, 0, extraHaste);
    SetHelper(player, 301006, player->HasAura(300334));
    SetAmount(player, 301006, 0, int32(player->GetArmor() * 3.0f / 125));
    SetHelper(player, 707776, player->HasAura(704935));
    SetAmount(player, 707776, 0, int32(player->GetStat(STAT_INTELLECT)));
    SetAmount(player, 561023, 2, int32(player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_SHIELD)));
    SetAmount(player, 680639, 1, int32(5 * player->GetStat(STAT_INTELLECT)));
    for (uint32 id : {803500, 803492, 807750, 807751, 807752, 807446, 805481, 805491, 681471})
        player->RemoveAurasDueToSpell(id);
    bool replacement = player->IsAlive() && player->HasAura(803238) && player->HasSpell(Highest(player, 800231));
    if (replacement && !player->HasSpell(504764))
        player->learnSpell(504764, true);
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), 800231))
            player->SetTemporarySpellReplacement(pair.first, replacement ? 504764 : 0);
    if (!replacement)
        player->removeSpell(504764, SPEC_MASK_ALL, true);
    if (!player->IsInCombat())
        state.firstAttacks.clear();
    state.refreshing = false;
}
}
namespace
{
class sun_cleric_player : public PlayerScript
{
public:
    sun_cleric_player() : PlayerScript("sun_cleric_player", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT}) { }
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        using namespace AscensionSunCleric;
        if (Owner(player) != player)
            return;
        auto& state = State(player);
        state.timers.Update(diff);
        while (state.timers.ExecuteEvent()) { }
        state.scheduler.Update(diff);
        if (!state.timers.HasTimeUntilEvent(SolarPower))
        {
            state.timers.ScheduleEvent(SolarPower, 500ms);
            Refresh(player);
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(AscensionSunCleric::stateMutex);
        AscensionSunCleric::states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionSunCleric()
{
    new sun_cleric_player();
}
