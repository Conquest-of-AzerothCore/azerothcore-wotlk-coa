/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
#include "AscensionFelswornData.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <array>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace AscensionFelsworn
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<FelswornState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    Player* player = unit ? const_cast<Unit*>(unit)->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_DEMON_HUNTER ? player : nullptr;
}
FelswornState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<FelswornState>()).first->second;
}
bool Named(SpellInfo const* info, uint32 root)
{
    return info && sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(root);
}
bool CanLearnRift(Player const* player, uint32 spellId)
{
    if (!player)
        return false;
    constexpr std::array<uint32, 8> factionRifts = {535595, 535596, 535597, 535598, 535599, 535600, 535601, 535602};
    if (std::find(factionRifts.begin(), factionRifts.end(), spellId) == factionRifts.end())
        return true;
    auto const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    for (auto itr = bounds.first; itr != bounds.second; ++itr)
        if (itr->second->RaceMask && !(itr->second->RaceMask & player->getRaceMask()))
            return false;
    return true;
}
bool Spender(SpellInfo const* info)
{
    return Named(info, 801904) || Named(info, 802060) || Named(info, 801895) || Named(info, 520236) ||
           (info && (info->Id == 800206 || info->Id == 705121));
}
bool Derived(SpellInfo const* info)
{
    if (!info)
        return false;
    for (uint32 id : FelswornCopies)
        if (id == info->Id)
            return true;
    return info->Id == 555742 || info->Id == 804372 || info->Id == 800598 || info->Id == 563271 || info->Id == 804336 ||
           info->Id == 804809;
}
bool SpenderImpact(SpellInfo const* info)
{
    return Spender(info) ||
           (info && (info->Id == 520262 || info->Id == 572585 || info->Id == 803715 || info->Id == 712399));
}
bool ResistDebuff(Player* player, SpellInfo const* info)
{
    if (!Owner(player) || !player->IsAlive() || !player->IsFullHealth() || !player->HasAura(804613) ||
        player->HasAura(706818) || !info || info->IsPositive() || info->HasAttribute(SPELL_ATTR4_NO_CAST_LOG) ||
        (info->Dispel != DISPEL_MAGIC && info->Dispel != DISPEL_CURSE))
        return false;
    bool aura = false;
    for (auto const& effect : info->Effects)
        if (effect.IsEffect())
        {
            if (!effect.ApplyAuraName)
                return false;
            aura = true;
        }
    if (!aura)
        return false;
    Cast(player, player, 706818);
    return true;
}
void SettleDebt(Player* player)
{
    auto& state = State(player);
    uint64 amount = 0;
    for (auto const& debt : state.debt)
        amount += debt.remaining;
    state.debt.clear();
    state.timers.CancelEvent(807727);
    if (player->IsAlive() && amount)
        Unit::DealDamage(player, player, uint32(std::min<uint64>(amount, UINT32_MAX)), nullptr, NODAMAGE,
                         SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
}
bool Direct(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 20 && !Derived(info) &&
           (info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) || info->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE) ||
            info->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE) || info->HasEffect(SPELL_EFFECT_NORMALIZED_WEAPON_DMG) ||
            info->HasEffect(SPELL_EFFECT_HEALTH_LEECH));
}
bool Bane(SpellInfo const* info)
{
    return Named(info, 704368) ||
           (info && (info->Id == 707901 || info->Id == 707902 || info->Id == 707903 || info->Id == 712483));
}
bool Pact(SpellInfo const* info)
{
    return Named(info, 800029) || (info && (info->Id == 800031 || info->Id == 803343 || info->Id == 804764));
}
bool Rush(SpellInfo const* info)
{
    return info && (info->Id == 500610 ||
                    (info->SpellFamilyName == 20 && (info->SpellFamilyFlags[1] & 524288) && !info->IsPassive()));
}
bool Twin(SpellInfo const* info)
{
    return Named(info, 801901) ||
           (info && info->SpellFamilyName == 20 &&
            ((info->SpellFamilyFlags[0] & 1048576) || (info->SpellFamilyFlags[1] & 65536)));
}
bool Inner(Unit const* player)
{
    return player && player->HasAura(804216);
}
bool Triggered(Spell const* spell)
{
    constexpr uint32 castWhileCasting = TRIGGERED_IGNORE_CAST_IN_PROGRESS | TRIGGERED_CAST_DIRECTLY;
    return spell->HasTriggeredCastFlag(TriggerCastFlags(TRIGGERED_FULL_MASK & ~castWhileCasting));
}
int32 Amount(uint32 spell, uint8 effect, Unit* caster)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    return info ? info->Effects[effect].CalcValue(caster) : 0;
}
uint32 Fury(Unit const* player)
{
    Aura const* aura = player ? player->GetAura(800058) : nullptr;
    return aura ? aura->GetStackAmount() : 0;
}
void Cast(Unit* caster, Unit* target, uint32 spell)
{
    if (caster && target && target->IsAlive() && caster->IsInWorld())
        caster->CastSpell(target, spell, true);
}
void Copy(Unit* caster, Unit* target, uint32 spell, uint32 amount)
{
    if (caster && target && target->IsAlive() && amount)
        caster->CastCustomSpell(spell, SPELLVALUE_BASE_POINT0, int32(std::min(amount, uint32(INT32_MAX))), target,
                                true);
}
void CopyDot(Player* player, Unit* target, uint32 spell, uint32 amount)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    if (info && info->Effects[0].Amplitude && info->GetDuration() > 0)
        Copy(player, target, spell, amount / std::max(1, info->GetDuration() / int32(info->Effects[0].Amplitude)));
}
std::list<Unit*> Nearby(Unit* center, float range)
{
    std::list<Unit*> units;
    if (!center || !center->IsInWorld())
        return units;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, units, check);
    Cell::VisitObjects(center, search, range);
    units.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    units.sort([center](Unit* a, Unit* b) {
        float first = center->GetDistance(a), second = center->GetDistance(b);
        return first == second ? a->GetGUID() < b->GetGUID() : first < second;
    });
    return units;
}
void Extend(Player* player, int32 milliseconds)
{
    if (Aura* aura = player->GetAura(804216))
    {
        int32 duration = int32(std::min<int64>(INT32_MAX, int64(aura->GetDuration()) + milliseconds));
        aura->SetMaxDuration(std::max(aura->GetMaxDuration(), duration));
        aura->SetDuration(duration);
    }
}
void Generated(Player* player, uint32 amount)
{
    if (!Owner(player) || !amount || !player->IsAlive())
        return;
    auto& state = State(player);
    if (player->HasAura(706425))
    {
        state.fury += amount;
        while (state.fury >= 10)
        {
            state.fury -= 10;
            Cast(player, player, 706269);
        }
    }
    if (player->HasAura(807438))
        Extend(player, int32(amount) * 500);
    if (player->HasAura(706267))
    {
        bool old = state.event;
        state.event = true;
        for (uint32 i = 0; i < amount; ++i)
            Cast(player, player, 555742);
        state.event = old;
    }
}
void Gain(Player* player, uint32 amount)
{
    if (!amount)
        return;
    if (Aura* aura = player->GetAura(800058))
        aura->ModStackAmount(amount);
    else if (Aura* created = player->AddAura(800058, player))
        created->SetStackAmount(std::min(6u, amount));
    if (Fury(player) >= 2 && !player->HasAura(803468))
        Cast(player, player, 803468);
    Generated(player, amount);
}
bool Chance(Player* player, uint32 talent, uint32 cooldown)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(talent);
    if (!player->HasAura(talent) || !info || State(player).timers.HasTimeUntilEvent(talent) ||
        !roll_chance_f(float(info->ProcChance)))
        return false;
    if (cooldown)
        State(player).timers.ScheduleEvent(talent, Milliseconds(cooldown));
    return true;
}
void Reduce(Player* player, uint32 root, int32 milliseconds)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            if (milliseconds == INT32_MAX)
                player->RemoveSpellCooldown(pair.first, true);
            else
                player->ModifySpellCooldown(pair.first, -milliseconds);
}
void Replace(Player* player, uint32 root, uint32 replacement)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            player->SetTemporarySpellReplacement(pair.first, replacement);
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing)
        return;
    state.refreshing = true;
    auto toggle = [player](uint32 id, bool enabled) {
        if (enabled && !player->HasAura(id))
            Cast(player, player, id);
        else if (!enabled)
            player->RemoveAurasDueToSpell(id);
    };
    bool inner = Inner(player) && player->IsAlive();
    toggle(807421, inner);
    toggle(807428, inner);
    toggle(800707, inner && player->HasAura(574140));
    toggle(801208, inner && player->HasAura(802108));
    toggle(500031, inner && player->HasAura(705122));
    toggle(807426, inner && player->HasAura(805236));
    toggle(801573, player->HasAura(300470) && player->GetHealthPct() > 75.0f);
    toggle(807962, player->HasAura(804613) && player->IsFullHealth() && !player->HasAura(706818));
    if (!player->HasAura(706425))
        state.fury = 0;
    state.refreshing = false;
}
void RefreshUnphased(Player* player)
{
    AuraEffect* pushback = player->GetAuraEffect(Unphased, EFFECT_1);
    if (!pushback)
        return;
    int32 const full = pushback->GetSpellInfo()->Effects[EFFECT_1].CalcValue(player);
    pushback->SetCanBeRecalculated(false);
    pushback->ChangeAmount(Inner(player) ? full : 0);
}

void SpreadCripple(Player* player, Unit* target)
{
    Aura* source = target->GetAura(704371, player->GetGUID());
    if (!source)
        return;
    uint32 count = 0;
    for (Unit* enemy : Nearby(target, 10.0f))
    {
        if (enemy == target || !player->IsValidAttackTarget(enemy) || enemy->HasAura(704371, player->GetGUID()) ||
            !target->IsWithinLOSInMap(enemy))
            continue;
        if (Aura* copy = player->AddAura(source->GetId(), enemy))
        {
            copy->SetMaxDuration(source->GetMaxDuration());
            copy->SetDuration(source->GetDuration());
            for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                if (AuraEffect* old = source->GetEffect(i))
                    if (AuraEffect* effect = copy->GetEffect(i))
                    {
                        effect->ChangeAmount(old->GetAmount());
                        effect->SetPeriodicTimer(old->GetPeriodicTimer());
                    }
            if (++count == 2)
                break;
        }
    }
}
}

namespace
{
class felsworn_player : public PlayerScript
{
  public:
    felsworn_player()
        : PlayerScript("felsworn_player", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_BEFORE_LOGOUT, PLAYERHOOK_ON_LOGOUT,
                                            PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_LOGIN})
    {
    }
    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        using namespace AscensionFelsworn;
        if (spellId != Unphased || !Owner(player))
            return;
        RefreshUnphased(player);
    }
    void OnPlayerLogin(Player* player) override
    {
        using namespace AscensionFelsworn;
        if (!Owner(player))
            return;
        RefreshUnphased(player);
    }
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        using namespace AscensionFelsworn;
        if (!Owner(player))
            return;
        auto& state = State(player);
        state.timers.Update(diff);
        state.scheduler.Update(diff);
        while (uint32 event = state.timers.ExecuteEvent())
            if (event == 807727)
            {
                uint64 amount = 0;
                for (auto& debt : state.debt)
                {
                    uint64 tick = (debt.remaining + debt.ticks - 1) / debt.ticks;
                    debt.remaining -= tick;
                    --debt.ticks;
                    amount += tick;
                }
                state.debt.erase(
                    std::remove_if(state.debt.begin(), state.debt.end(), [](Debt const& debt) { return !debt.ticks; }),
                    state.debt.end());
                if (player->IsAlive() && amount)
                    Unit::DealDamage(player, player, uint32(std::min<uint64>(amount, UINT32_MAX)), nullptr, NODAMAGE,
                                     SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
                if (!state.debt.empty())
                    state.timers.ScheduleEvent(807727, 1s);
            }
        if (!player->IsAlive())
        {
            state.debt.clear();
            player->RemoveAurasDueToSpell(804216);
        }
        if (!state.timers.HasTimeUntilEvent(1))
        {
            Refresh(player);
            state.infernals.erase(
                std::remove_if(state.infernals.begin(), state.infernals.end(),
                               [player](ObjectGuid guid) { return !ObjectAccessor::GetCreature(*player, guid); }),
                state.infernals.end());
            state.timers.ScheduleEvent(1, 250ms);
        }
    }
    void OnPlayerBeforeLogout(Player* player) override
    {
        if (AscensionFelsworn::Owner(player))
            AscensionFelsworn::SettleDebt(player);
    }
    void OnPlayerLogout(Player* player) override
    {
        using namespace AscensionFelsworn;
        if (!Owner(player))
            return;
        for (ObjectGuid guid : State(player).infernals)
            if (Creature* unit = ObjectAccessor::GetCreature(*player, guid))
                unit->DespawnOrUnsummon();
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionFelsworn()
{
    new felsworn_player();
}
