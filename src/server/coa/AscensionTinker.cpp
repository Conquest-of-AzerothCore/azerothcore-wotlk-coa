/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTinker.h"
#include "AscensionTinkerData.h"
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
namespace AscensionTinker
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<TinkerState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    if (!unit)
        return nullptr;
    Player* player = const_cast<Unit*>(unit)->ToPlayer();
    if (!player && unit->GetOwner())
        player = unit->GetOwner()->ToPlayer();
    return player && player->getClass() == CLASS_TINKER ? player : nullptr;
}
TinkerState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<TinkerState>()).first->second;
}
bool NotifyAttack(Player* player, Unit* target)
{
    if (!player || !target || !player->IsValidAttackTarget(target))
        return false;
    State(player).focus = target->GetGUID();
    return true;
}
bool NotifySpellAttack(Player* player, SpellInfo const* spellInfo, Unit* target)
{
    if (!spellInfo || spellInfo->SpellFamilyName != 34 || spellInfo->IsPositive() || !NotifyAttack(player,target))
        return false;
    Unit* victim = player->GetVictim();
    State(player).observedVictim = victim ? victim->GetGUID() : ObjectGuid();
    return true;
}
void ObserveAttack(Player* player)
{
    if (!player)
        return;
    auto& state = State(player);
    Unit* victim = player->GetVictim();
    ObjectGuid victimGuid = victim ? victim->GetGUID() : ObjectGuid();
    if (victimGuid != state.observedVictim)
    {
        state.observedVictim = victimGuid;
        NotifyAttack(player,victim);
    }
    Spell* autoRepeat = player->GetCurrentSpell(CURRENT_AUTOREPEAT_SPELL);
    Unit* rangedTarget = autoRepeat && autoRepeat->GetSpellInfo()->IsAutoRepeatRangedSpell() ?
        autoRepeat->m_targets.GetUnitTarget() : nullptr;
    ObjectGuid rangedGuid = rangedTarget ? rangedTarget->GetGUID() : ObjectGuid();
    if (rangedGuid != state.observedAutoRepeatTarget)
    {
        state.observedAutoRepeatTarget = rangedGuid;
        NotifyAttack(player,rangedTarget);
    }
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
        for (uint32 id : TinkerCopies)
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
bool Shot(SpellInfo const* info)
{
    return Any(info,{500549,500577});
}
bool MechAbility(SpellInfo const* info)
{
    return Any(info,{801387,805372,801389}) || (info && (info->Id == 801388 || info->Id == 801390));
}
bool Build(SpellInfo const* info)
{
    if (!info || info->SpellFamilyName != 34)
        return false;
    for (uint32 id : TinkerBuilds)
        if (info->Id == id)
            return true;
    return false;
}
bool Nanobots(Player* player, Unit* target)
{
    if (!target)
        return false;
    for (auto const& pair : target->GetAppliedAuras())
        if (auto* aura = pair.second->GetBase(); aura->GetCasterGUID() == player->GetGUID() &&
            Any(aura->GetSpellInfo(),{801809,801709,502537,801808,803552}))
            return true;
    return false;
}
void Mana(Unit* target, uint32 amount, Player* source)
{
    if (target && source && amount)
        source->EnergizeBySpell(target,561267,int32(std::min<uint32>(INT32_MAX,amount)),POWER_MANA);
}
void ExitMechsuit(Player* player)
{
    for (CurrentSpellTypes slot : {CURRENT_GENERIC_SPELL,CURRENT_CHANNELED_SPELL})
        if (Spell* spell = player->GetCurrentSpell(slot); spell &&
            (spell->GetSpellInfo()->Id == 500213 || MechAbility(spell->GetSpellInfo())))
            player->InterruptSpell(slot);
    for (uint32 id : {801384,803451,801385,803329,680999,504749,801389,801386})
        player->RemoveAurasDueToSpell(id,player->GetGUID());
}
bool Resource(Player* player, uint32 id, int32 delta)
{
    if (!player || player->getClass() != CLASS_TINKER || id != Scrap)
        return false;
    uint32 after = uint32(std::clamp<int64>(int64(Count(player,Scrap)) + delta,0,100));
    if (!after)
    {
        player->RemoveAurasDueToSpell(Scrap);
        ExitMechsuit(player);
    }
    else if (Aura* aura = player->GetAura(Scrap))
        aura->SetStackAmount(after);
    else if (Aura* added = player->AddAura(Scrap,player))
        added->SetStackAmount(after);
    return true;
}
void Grant(Player* player, uint32 id, uint32 charges)
{
    Cast(player,player,id);
    if (Aura* aura = player->GetAura(id,player->GetGUID()))
    {
        aura->SetCharges(uint8(std::clamp<uint32>(charges,1,255)));
        aura->SetStackAmount(1);
        aura->SetScriptValue(Scrap,++State(player).sequence);
    }
}
void Spend(Player* player, uint32 id, uint64 generation)
{
    if (generation)
        if (Aura* aura = player->GetAura(id,player->GetGUID());
            aura && generation == aura->GetScriptValue(Scrap))
        {
            if (aura->GetCharges() > 1)
            {
                aura->SetCharges(aura->GetCharges() - 1);
                aura->SetUsingCharges(false);
            }
            else
                aura->Remove();
        }
}
void ActivateModule(Player* player, uint32 id)
{
    auto& state = State(player);
    auto previous = state.moduleTargets;
    state.moduleTargets.clear();
    state.module = id;
    SetHelper(player,707495,true);
    SetAmount(player,707495,0,int32(id));
    for (ObjectGuid guid : previous)
        if (Player* ally = ObjectAccessor::FindPlayer(guid))
            for (uint32 other : TinkerModules)
                if (other != id)
                    ally->RemoveAurasDueToSpell(other,player->GetGUID());
}
void ReconcileModules(Player* player)
{
    std::list<Aura*> remove;
    for (auto const& pair : player->GetAppliedAuras())
    {
        Aura* aura = pair.second->GetBase();
        for (uint32 module : TinkerModules)
            if (aura->GetId() == module)
                if (Player* owner = ObjectAccessor::FindPlayer(aura->GetCasterGUID()))
                    if (AuraEffect const* selected = owner->GetAuraEffect(707495,EFFECT_0); selected &&
                        selected->GetAmount() > 0 && uint32(selected->GetAmount()) != module)
                        remove.push_back(aura);
    }
    for (Aura* aura : remove)
        aura->Remove();
}
void FillMechsuitBar(Player* player)
{
    constexpr uint8 MechsuitBar = 72, MechsuitBarSize = 12;
    for (uint8 button = MechsuitBar; button < MechsuitBar + MechsuitBarSize; ++button)
        if (player->GetActionButton(button))
            return;
    uint8 button = MechsuitBar;
    for (uint32 root : {GatlingGun,801387u,805372u,801389u})
        if (player->addActionButton(button,Highest(player,root),ACTION_BUTTON_SPELL))
            ++button;
    if (button != MechsuitBar)
        player->SendActionButtons(1);
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing || !player->IsInWorld())
        return;
    state.refreshing = true;
    if ((!player->IsAlive() || !Count(player,Scrap)) && player->HasAura(Mechsuit))
        ExitMechsuit(player);
    bool mech = player->IsAlive() && player->HasAura(Mechsuit);
    SetHelper(player,801385,mech);
    SetHelper(player,803329,mech);
    SetHelper(player,680999,mech && player->HasAura(806631));
    SetAmount(player,801385,1,mech && player->HasAura(681001) ? -std::abs(Amount(681001)) : 0);
    bool suit = player->HasSpell(Highest(player,Mechsuit));
    if (suit && !player->HasSpell(GatlingGun))
        player->learnSpell(GatlingGun);
    else if (!suit && player->HasSpell(GatlingGun))
        player->removeSpell(GatlingGun,SPEC_MASK_ALL,false);
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first),500549))
            player->SetTemporarySpellReplacement(pair.first,mech && suit ? GatlingGun : 0);
    if (!mech)
    {
        player->RemoveAurasDueToSpell(803451,player->GetGUID());
        player->RemoveAurasDueToSpell(504749,player->GetGUID());
    }
    else
        FillMechsuitBar(player);
    bool mines = player->HasAura(803074);
    for (auto const& pair : player->GetSpellMap())
        mines |= player->HasSpell(pair.first) &&
            Any(sSpellMgr->GetSpellInfo(pair.first),{801718,805354,704463,706647});
    if (mines && !player->HasSpell(801798))
        player->learnSpell(801798);
    else if (!mines && player->HasSpell(801798))
        player->removeSpell(801798,SPEC_MASK_ALL,false);
    bool gear = player->HasAura(681245);
    if (Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL); channel &&
        channel->GetSpellInfo()->Id == 504594 && channel->getState() != SPELL_STATE_FINISHED)
        gear = true;
    if (gear && !player->HasSpell(504594))
        player->learnSpell(504594,true);
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first),504527))
            player->SetTemporarySpellReplacement(pair.first,gear ? 504594 : 0);
    if (!gear)
        player->removeSpell(504594,SPEC_MASK_ALL,true);
    if (!player->HasAura(707249))
        player->RemoveAurasDueToSpell(707251);
    if (!player->HasAura(572545) || !player->HasAura(653232))
        player->RemoveAurasDueToSpell(653282);
    state.refreshing = false;
}
}
namespace
{
class tinker_player : public PlayerScript
{
public:
    tinker_player() : PlayerScript("tinker_player", {PLAYERHOOK_ON_UPDATE,PLAYERHOOK_ON_LOGOUT}) { }
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        using namespace AscensionTinker;
        if (Owner(player) == player)
            ObserveAttack(player);
        auto& state = State(player);
        state.timers.Update(diff);
        while (state.timers.ExecuteEvent()) { }
        state.scheduler.Update(diff);
        if (!state.timers.HasTimeUntilEvent(Scrap))
        {
            state.timers.ScheduleEvent(Scrap,500ms);
            ReconcileModules(player);
            if (Owner(player) == player)
                Refresh(player);
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        using namespace AscensionTinker;
        if (Owner(player) == player)
            ExitMechsuit(player);
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionTinker()
{
    new tinker_player();
}
