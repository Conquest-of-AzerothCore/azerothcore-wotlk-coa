/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPyromancer.h"
#include "AscensionPyromancerData.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "MotionMaster.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <unordered_map>
namespace AscensionPyromancer
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<PyromancerState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    if (!unit)
        return nullptr;
    Player* player = const_cast<Unit*>(unit)->ToPlayer();
    if (!player && unit->GetOwner())
        player = unit->GetOwner()->ToPlayer();
    return player && player->getClass() == CLASS_PYROMANCER ? player : nullptr;
}
PyromancerState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<PyromancerState>()).first->second;
}
bool Named(SpellInfo const* info, uint32 root)
{
    if (info && root == 802174 &&
        std::find(std::begin(PyromancerEchoRanks), std::end(PyromancerEchoRanks), info->Id) !=
            std::end(PyromancerEchoRanks))
        return true;
    return info && sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(root);
}
bool Any(SpellInfo const* info, std::initializer_list<uint32> roots)
{
    for (uint32 root : roots)
        if (Named(info, root))
            return true;
    return false;
}
bool Spender(SpellInfo const* info)
{
    return Any(info, {800792, 802174, 801915, 805500, 800818, 520019, 680369, 704278, 706854, 802791});
}
bool Derived(SpellInfo const* info)
{
    return info && Any(info, {503864, 704817, 804103, 680962, 704274, 707892, 707595, 807403});
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
void Mana(Player* player, uint32 amount, uint32 spell)
{
    if (amount)
        player->EnergizeBySpell(player, spell, int32(std::min<uint32>(amount, INT32_MAX)), POWER_MANA);
}
bool Chance(Player* player, uint32 id, uint32 cooldown)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    if (!info || !player->HasAura(id) || State(player).timers.HasTimeUntilEvent(id))
        return false;
    float chance = float(info->ProcChance);
    player->ApplySpellMod(id, SPELLMOD_CHANCE_OF_SUCCESS, chance);
    if (!roll_chance_f(std::clamp(chance, 0.0f, 100.0f)))
        return false;
    if (cooldown)
        State(player).timers.ScheduleEvent(id, Milliseconds(cooldown));
    return true;
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
void ReducePercent(Player* player, uint32 root, uint32 percent)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            player->ModifySpellCooldown(pair.first,
                                        -int32(CalculatePct(player->GetSpellCooldownDelay(pair.first), percent)));
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
void SyncActionBars(Player* player)
{
    bool changed = false;
    bool const converted = player->HasAura(520937);
    uint32 const echo = converted ? Highest(player, 802174) : 0;
    uint32 fallback = 0;
    if (!converted)
        for (auto const& pair : player->GetSpellMap())
            if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), 800792) &&
                (!fallback ||
                    sSpellMgr->GetSpellInfo(pair.first)->SpellLevel < sSpellMgr->GetSpellInfo(fallback)->SpellLevel))
                fallback = pair.first;
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        if (!action || action->GetType() != ACTION_BUTTON_SPELL)
            continue;
        uint32 const current = action->GetAction();
        uint32 desired = current;
        if (converted && player->HasSpell(current) && Named(sSpellMgr->GetSpellInfo(current), 800792))
            desired = echo;
        else if (!converted && fallback &&
            std::find(std::begin(PyromancerEchoRanks), std::end(PyromancerEchoRanks), current) !=
                std::end(PyromancerEchoRanks))
            desired = fallback;
        if (desired != current && desired && player->HasSpell(desired) &&
            player->addActionButton(button, desired, ACTION_BUTTON_SPELL))
            changed = true;
    }
    if (changed)
        player->SendActionButtons(1);
}
void Flames(Player* player, uint32 count)
{
    Aura* old = player->GetAura(FlamecastingAura);
    int32 remaining = old ? old->GetDuration() : -1;
    uint32 stacks = old ? old->GetStackAmount() : 0;
    if (Aura* aura = player->AddAura(FlamecastingAura, player))
    {
        aura->SetStackAmount(std::min<uint32>(aura->GetSpellInfo()->CalcMaxAuraStacks(player), stacks + count));
        if (remaining >= 0)
            aura->SetDuration(remaining);
    }
}
void Generated(Player* player, uint32 count)
{
    for (uint32 i = 0; i < std::min(5u, count); ++i)
    {
        if (Chance(player, 681196))
            Cast(player, player, 681366);
        if (player->HasAura(704849))
            Cast(player, player, 707480);
        if (player->HasAura(704862))
            Cast(player, player, 680367);
    }
}
void Spent(Player* player, uint32 count)
{
    for (uint32 i = 0; i < std::min(5u, count); ++i)
    {
        if (Chance(player, 681196))
            Cast(player, player, 681366);
        if (player->HasAura(503915))
            Cast(player, player, 806783);
        if (player->HasAura(504394))
            for (uint32 root : {803950, 805496})
                ReducePercent(player, root, std::max(0, Amount(572807)));
        if (player->HasAura(681334))
            Cast(player, player, 681517);
        if (player->HasAura(807126))
            Mana(player, CalculatePct(player->GetMaxPower(POWER_MANA), Amount(807220)), 807220);
        if (Chance(player, 802164))
            for (Unit* target : Nearby(player, 60))
                if (target->GetAuraOfRankedSpell(805500, player->GetGUID()) && player->IsValidAttackTarget(target))
                    Cast(player, target, 802173);
        if (Chance(player, 704823))
            Resource(player, EmberAura, 1);
        if (Chance(player, 707217))
        {
            Reduce(player, 802107, INT32_MAX);
            Reduce(player, 801905, INT32_MAX);
            Cast(player, player, 520823);
        }
    }
}
bool Resource(Player* player, uint32 id, int32 delta)
{
    if (!player || player->getClass() != CLASS_PYROMANCER || (id != HeatAura && id != EmberAura))
        return false;
    int32 before = Count(player, id);
    int64 total = std::max<int64>(0, int64(before) + delta);
    int32 after = int32(id == HeatAura ? total % 100 : std::min<int64>(5, total));
    if (!after)
        player->RemoveAurasDueToSpell(id);
    else if (Aura* aura = player->GetAura(id))
        aura->SetStackAmount(after);
    else if (Aura* created = player->AddAura(id, player))
        created->SetStackAmount(after);
    after = Count(player, id);
    if (id == EmberAura)
    {
        if (after > before)
            Generated(player, after - before);
        if (after < before)
            Spent(player, before - after);
        Refresh(player);
    }
    else if (delta > 0)
    {
        if (Chance(player, 804300))
            Flames(player);
        if (Chance(player, 520381, 1000))
            for (uint32 root : {802119, 802120})
                ReducePercent(player, root, std::max(0, Amount(520824)));
        if (total >= 100)
            Resource(player, EmberAura, int32(std::min<int64>(5, total / 100)));
    }
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
                     { return (unit != player && !player->IsInRaidWith(unit)) || !player->IsFriendlyTo(unit); });
    result.sort(
        [](Unit* a, Unit* b)
        {
            return a->GetHealthPct() == b->GetHealthPct() ? a->GetGUID() < b->GetGUID()
                                                          : a->GetHealthPct() < b->GetHealthPct();
        });
    if (count && result.size() > count)
        result.resize(count);
    return result;
}
uint32 Burning(Player* player, Unit* target)
{
    uint32 result = 0;
    if (target)
        for (auto const& pair : target->GetAppliedAuras())
        {
            Aura* aura = pair.second->GetBase();
            if (aura->GetCasterGUID() == player->GetGUID() && aura->GetSpellInfo()->SpellFamilyName == 30 &&
                aura->GetSpellInfo()->HasAura(SPELL_AURA_PERIODIC_DAMAGE))
                ++result;
        }
    return result;
}
void ExtendOwned(Player* player, Unit* target, uint32 root, uint32 milliseconds, uint32 cap)
{
    if (Aura* aura = target->GetAuraOfRankedSpell(root, player->GetGUID()))
    {
        uint32 used = uint32(std::min<uint64>(UINT32_MAX, aura->GetScriptValue(704856)));
        bool stoke = Any(aura->GetSpellInfo(), {800791, 706874}) && cap == 12000;
        if (stoke && aura->GetEffect(EFFECT_1))
            used = std::max(0, aura->GetEffect(EFFECT_1)->GetAmount());
        uint32 extra = std::min(milliseconds, cap > used ? cap - used : 0);
        aura->SetScriptValue(704856, used + extra);
        if (stoke && aura->GetEffect(EFFECT_1))
            aura->GetEffect(EFFECT_1)->SetAmount(used + extra);
        aura->SetMaxDuration(int32(std::min<int64>(INT32_MAX, int64(aura->GetMaxDuration()) + extra)));
        aura->SetDuration(int32(std::min<int64>(INT32_MAX, int64(aura->GetDuration()) + extra)));
    }
}
void Spread(Player* player, Unit* source, std::initializer_list<uint32> roots, uint32 count, float radius)
{
    if (!source || !count)
        return;
    for (Unit* target : Nearby(source, radius))
    {
        if (target == source || !player->IsValidAttackTarget(target) || !player->IsWithinLOSInMap(target))
            continue;
        bool copied = false;
        for (uint32 root : roots)
            if (Aura* aura = source->GetAuraOfRankedSpell(root, player->GetGUID()))
            {
                if (Aura* old = target->GetAura(aura->GetId(), player->GetGUID());
                    old && old->GetDuration() >= aura->GetDuration())
                    continue;
                if (Aura* copy = player->AddAura(aura->GetId(), target))
                {
                    copy->SetStackAmount(aura->GetStackAmount());
                    copy->SetMaxDuration(aura->GetMaxDuration());
                    copy->SetDuration(aura->GetDuration());
                    for (uint32 key : {704856u, aura->GetId(), aura->GetId() + 1})
                        copy->SetScriptValue(key, aura->GetScriptValue(key));
                    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                        if (AuraEffect* effect = aura->GetEffect(i))
                            if (AuraEffect* next = copy->GetEffect(i))
                            {
                                next->ChangeAmount(effect->GetAmount());
                                next->SetCritChance(effect->GetCritChance());
                                next->SetPctMods(effect->GetPctMods());
                                next->SetPeriodicTimer(effect->GetPeriodicTimer());
                            }
                    copied = true;
                }
            }
        if (copied && !--count)
            break;
    }
}
uint32 Remaining(Aura const* aura)
{
    AuraEffect const* effect = aura ? aura->GetEffect(0) : nullptr;
    if (!effect || !effect->GetAmplitude() || aura->GetDuration() < effect->GetPeriodicTimer())
        return 0;
    if (Any(aura->GetSpellInfo(), {680962, 807403, 520826}) && aura->GetEffect(EFFECT_2) &&
        aura->GetEffect(EFFECT_2)->GetAmount() > 0)
        return std::max(0, aura->GetEffect(EFFECT_1)->GetAmount());
    uint32 ticks = 1 + (aura->GetDuration() - effect->GetPeriodicTimer()) / effect->GetAmplitude();
    return uint32(std::min<uint64>(INT32_MAX, uint64(std::max(0, effect->GetAmount())) * ticks));
}
void Accumulate(Player* player, Unit* target, uint32 id, uint32 total)
{
    if (!total || !target)
        return;
    if (Aura* old = target->GetAura(id, player->GetGUID()))
        total = uint32(std::min<uint64>(INT32_MAX, uint64(total) + Remaining(old)));
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    uint32 ticks = info ? std::max(1, info->GetDuration() / int32(std::max(1u, info->Effects[0].Amplitude))) : 1;
    Copy(player, target, id, std::max(1u, total / ticks));
    if (Aura* aura = target->GetAura(id, player->GetGUID()))
    {
        if (aura->GetEffect(EFFECT_1) && aura->GetEffect(EFFECT_2))
        {
            aura->GetEffect(EFFECT_1)->SetAmount(total);
            aura->GetEffect(EFFECT_2)->SetAmount(ticks);
        }
        aura->SetScriptValue(id, total);
        aura->SetScriptValue(id + 1, ticks);
    }
}
void Aspect(Player* player, Unit* target, uint32 damage, bool guaranteed)
{
    if (!damage || (!guaranteed && !Chance(player, 504750)))
        return;
    bool previous = State(player).event;
    State(player).event = true;
    for (uint32 index = 0; index < 4 && target->IsAlive(); ++index)
    {
        damage = CalculatePct(damage, Amount(504750));
        State(player).aspectDamage = 0;
        Copy(player, target, 503864, damage);
        damage = State(player).aspectDamage;
        if (damage && player->HasAura(707479))
            Copy(player, player, 707595, CalculatePct(damage, Amount(707479)));
        if (!damage || !Chance(player, 504750))
            break;
    }
    State(player).event = previous;
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing)
        return;
    state.refreshing = true;
    if (player->HasAura(92128) && !player->HasSpell(802117))
        player->learnSpell(802117, true);
    if (!player->HasAura(92128))
        player->removeSpell(802117, SPEC_MASK_ALL, true);
    if (player->HasAura(520937))
        for (uint32 id : PyromancerEchoRanks)
            if (sSpellMgr->GetSpellInfo(id)->SpellLevel <= player->GetLevel() && !player->HasSpell(id))
                player->learnSpell(id);
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), 800792))
            player->SetTemporarySpellReplacement(pair.first, player->HasAura(520937) ? Highest(player, 802174) : 0);
    if (!player->HasAura(520937))
        for (uint32 id : PyromancerEchoRanks)
            player->removeSpell(id, SPEC_MASK_ALL, false);
    SyncActionBars(player);
    if (player->HasAura(300751) && Count(player, EmberAura))
    {
        if (!player->HasAura(807542))
            Cast(player, player, 807542);
        if (Aura* aura = player->GetAura(807542))
            if (AuraEffect* effect = aura->GetEffect(0))
                effect->ChangeAmount(-int32(Count(player, EmberAura)) * std::abs(Amount(300751)));
    }
    else
        player->RemoveAurasDueToSpell(807542);
    if (player->HasAura(300755))
    {
        if (!player->HasAura(900755))
            Cast(player, player, 900755);
        if (Aura* aura = player->GetAura(900755))
            if (AuraEffect* effect = aura->GetEffect(0))
                effect->ChangeAmount(player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_CRIT_SPELL));
    }
    else
        player->RemoveAurasDueToSpell(900755);
    state.refreshing = false;
}
void StartDash(Player* player)
{
    auto& state = State(player);
    state.dashPrevious = player->GetPosition();
    state.dashMs = 2000;
    state.dashHits.clear();
    player->RemoveMovementImpairingAuras(true);
    player->RemoveAurasByType(SPELL_AURA_MOD_STUN);
    float forward = player->HasUnitMovementFlag(MOVEMENTFLAG_BACKWARD)  ? -1
                    : player->HasUnitMovementFlag(MOVEMENTFLAG_FORWARD) ? 1
                                                                        : 0;
    float strafe = player->HasUnitMovementFlag(MOVEMENTFLAG_STRAFE_LEFT)    ? 1
                   : player->HasUnitMovementFlag(MOVEMENTFLAG_STRAFE_RIGHT) ? -1
                                                                            : 0;
    float angle = forward || strafe ? std::atan2(strafe, forward) : 0;
    float distance = sSpellMgr->GetSpellInfo(801929)->Effects[0].CalcRadius(player);
    if (distance <= 0)
        distance = 15;
    if (forward || strafe)
    {
        float rate = player->GetSpeedRate(MOVE_RUN);
        float speed = player->GetSpeed(MOVE_RUN);
        if (speed > 0 && speed < 35.0f)
        {
            float surge = rate * 35.0f / speed;
            player->SetSpeed(MOVE_RUN, surge, true);
            state.scheduler.Schedule(Milliseconds(uint32(1000.0f * distance / 35.0f)), [player, rate, surge](TaskContext)
            {
                if (player->IsInWorld() && player->GetSpeedRate(MOVE_RUN) == surge)
                    player->SetSpeed(MOVE_RUN, rate, true);
            });
        }
        return;
    }
    Position end = player->GetPosition();
    player->MovePositionToFirstCollision(end, distance, angle);
    player->GetMotionMaster()->MoveCharge(end.GetPositionX(), end.GetPositionY(), end.GetPositionZ(), 35);
}
void UpdateDash(Player* player, uint32 diff)
{
    auto& state = State(player);
    if (!state.dashMs)
        return;
    float dx = player->GetPositionX() - state.dashPrevious.GetPositionX();
    float dy = player->GetPositionY() - state.dashPrevious.GetPositionY();
    float length = dx * dx + dy * dy;
    if (player->IsAlive() && length > .0001f && length < 2500)
        for (Unit* target : Nearby(player, std::sqrt(length) + 3))
        {
            float t = length ? std::clamp(((target->GetPositionX() - state.dashPrevious.GetPositionX()) * dx +
                                           (target->GetPositionY() - state.dashPrevious.GetPositionY()) * dy) /
                                              length,
                                          0.0f, 1.0f)
                             : 0;
            if (target->GetExactDist2d(state.dashPrevious.GetPositionX() + dx * t,
                                       state.dashPrevious.GetPositionY() + dy * t) <= 2 &&
                std::abs(target->GetPositionZ() - player->GetPositionZ()) < 4 && player->IsValidAttackTarget(target) &&
                player->IsWithinLOSInMap(target) && state.dashHits.insert(target->GetGUID()).second)
                Cast(player, target, 803459);
        }
    state.dashPrevious = player->GetPosition();
    state.dashMs = state.dashMs > diff && player->IsAlive() ? state.dashMs - diff : 0;
}
}
namespace
{
class pyromancer_player : public PlayerScript
{
  public:
    pyromancer_player() : PlayerScript("pyromancer_player", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT}) {}
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (AscensionPyromancer::Owner(player) != player)
            return;
        auto& state = AscensionPyromancer::State(player);
        state.timers.Update(diff);
        while (state.timers.ExecuteEvent())
        {
        }
        state.scheduler.Update(diff);
        AscensionPyromancer::UpdateDash(player, diff);
        if (!state.timers.HasTimeUntilEvent(AscensionPyromancer::EmberAura))
        {
            state.timers.ScheduleEvent(AscensionPyromancer::EmberAura, 500ms);
            AscensionPyromancer::Refresh(player);
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(AscensionPyromancer::stateMutex);
        AscensionPyromancer::states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionPyromancer()
{
    new pyromancer_player();
}
