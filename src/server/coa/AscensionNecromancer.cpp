/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNecromancer.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace AscensionNecromancer
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<NecromancerState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    Player* player = unit ? unit->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    return player && player->getClass() == CLASS_NECROMANCER ? player : nullptr;
}
NecromancerState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<NecromancerState>()).first->second;
}
void Forget(Player* player)
{
    if (Owner(player) != player)
        return;
    Prune(player, true);
    std::lock_guard<std::mutex> lock(stateMutex);
    states.erase(player->GetGUID());
}
bool Named(SpellInfo const* info, uint32 root)
{
    return info && sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(root);
}
int32 Amount(uint32 spell, uint8 effect, Unit* caster)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    return info ? info->Effects[effect].CalcValue(caster) : 0;
}
void Cast(Unit* caster, Unit* target, uint32 spell)
{
    if (caster && target && caster->IsInWorld() && target->IsAlive())
        caster->CastSpell(target, spell, true);
}
void Copy(Unit* caster, Unit* target, uint32 spell, uint32 amount, uint8 effect)
{
    if (caster && target && target->IsAlive() && amount)
        caster->CastCustomSpell(spell, SpellValueMod(SPELLVALUE_BASE_POINT0 + effect),
                                int32(std::min(amount, uint32(INT32_MAX))), target, true);
}
std::list<Unit*> Nearby(Unit* center, float range, bool alive)
{
    std::list<Unit*> units;
    if (!center || !center->IsInWorld())
        return units;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, units, check);
    Cell::VisitObjects(center, search, range);
    units.remove_if([center, alive](Unit* unit) { return (alive && !unit->IsAlive()) || !center->InSamePhase(unit); });
    units.sort([](Unit* a, Unit* b) { return a->GetGUID() < b->GetGUID(); });
    return units;
}
uint8 Cost(Player* player, uint32 spell)
{
    switch (sSpellMgr->GetFirstSpellInChain(spell))
    {
    case 500329:
    case 500335:
    case 803139:
    case 500989:
        return 3;
    case 500331:
        return player->HasAura(807937) ? 1 : 2;
    case 504859:
    case 504861:
        return 2;
    case 500969:
    case 500970:
    case 500971:
    case 504901:
    case 504682:
    case 600992:
        return 1;
    default:
        return 0;
    }
}
uint8 Capacity(Player* player)
{
    int32 capacity = 2;
    player->ApplySpellMod(805011, SPELLMOD_MAX_AURA_STACKS, capacity);
    return uint8(std::clamp(capacity, 0, 48));
}
void Prune(Player* player, bool all)
{
    auto& state = State(player);
    auto saved = state.minions;
    auto ownsSummon = [player](MinionRecord const& row)
    {
        if (!row.cost || player->HasSpell(row.spell))
            return true;
        return std::any_of(player->GetSpellMap().begin(), player->GetSpellMap().end(),
            [row](auto const& known)
            {
                return known.second->State != PLAYERSPELL_REMOVED &&
                    Named(sSpellMgr->GetSpellInfo(known.first), row.spell);
            });
    };
    state.minions.erase(std::remove_if(state.minions.begin(), state.minions.end(),
                                       [player, all, &ownsSummon](MinionRecord const& row)
                                       {
                                           Creature* unit = player->FindMap()
                                                                ? ObjectAccessor::GetCreature(*player, row.guid)
                                                                : nullptr;
                                           return all || !unit || !unit->IsAlive() ||
                                                  unit->GetOwnerGUID() != player->GetGUID() || !player->IsInMap(unit) ||
                                                  !player->InSamePhase(unit) || !ownsSummon(row);
                                       }),
                        state.minions.end());
    for (auto const& row : saved)
        if (all || !ownsSummon(row))
            if (Creature* unit = player->FindMap() ? ObjectAccessor::GetCreature(*player, row.guid) : nullptr)
                if (unit->GetOwnerGUID() == player->GetGUID())
                    unit->DespawnOrUnsummon();
}
std::vector<Creature*> Minions(Player* player, bool raisedOnly)
{
    Prune(player);
    std::vector<Creature*> result;
    for (auto const& row : State(player).minions)
        if (!raisedOnly || row.cost)
            if (Creature* unit = ObjectAccessor::GetCreature(*player, row.guid))
                if (unit->GetEntry() != 50132 && unit->GetEntry() != 542064 && unit->GetEntry() != 575091)
                    result.push_back(unit);
    return result;
}
bool IsMinion(Player* player, Unit const* unit, bool raisedOnly)
{
    if (!unit || unit == player || unit->GetOwnerGUID() != player->GetGUID())
        return false;
    for (auto const& row : State(player).minions)
        if (row.guid == unit->GetGUID() && (!raisedOnly || row.cost))
            return true;
    return false;
}
uint8 Used(Player* player)
{
    Prune(player);
    uint32 used = 0;
    for (auto& row : State(player).minions)
    {
        row.cost = Cost(player, row.spell);
        used += row.cost;
    }
    return uint8(std::min(used, 255u));
}
uint32 Count(Player* player, std::initializer_list<uint32> entries)
{
    uint32 count = 0;
    for (Creature* unit : Minions(player))
        if (!entries.size() || std::find(entries.begin(), entries.end(), unit->GetEntry()) != entries.end())
            ++count;
    return count;
}
void BuffArmy(Player* player, uint32 spell, bool owner)
{
    if (owner)
        Cast(player, player, spell);
    for (Creature* unit : Minions(player))
        Cast(player, unit, spell);
}
void Sync(Player* player)
{
    if (!player || !player->IsInWorld() || !player->IsAlive() || State(player).syncing)
        return;
    auto& state = State(player);
    state.syncing = true;
    uint8 capacity = Capacity(player);
    int32 free = std::max(0, int32(capacity) - Used(player));
    if (Aura* total = player->GetAura(805011) ? player->GetAura(805011) : player->AddAura(805011, player))
        if (total->GetStackAmount() != std::max<uint8>(1, capacity))
            total->SetStackAmount(std::max<uint8>(1, capacity));
    if (!free)
        player->RemoveAurasDueToSpell(525004);
    else if (Aura* visual = player->GetAura(525004) ? player->GetAura(525004) : player->AddAura(525004, player))
        if (visual->GetStackAmount() != free)
            visual->SetStackAmount(uint8(free));
    state.syncing = false;
}
uint32 KnownRank(Player* player, uint32 root)
{
    uint32 result = root;
    for (auto const& [id, value] : player->GetSpellMap())
        if (value->State != PLAYERSPELL_REMOVED && value->Active && Named(sSpellMgr->GetSpellInfo(id), root) &&
            sSpellMgr->GetSpellRank(id) > sSpellMgr->GetSpellRank(result))
            result = id;
    return result;
}
void Reduce(Player* player, uint32 root, int32 milliseconds)
{
    for (auto const& [id, value] : player->GetSpellMap())
        if (value->State != PLAYERSPELL_REMOVED && Named(sSpellMgr->GetSpellInfo(id), root))
        {
            if (milliseconds == INT32_MAX)
                player->RemoveSpellCooldown(id, true);
            else
                player->ModifySpellCooldown(id, -std::abs(milliseconds));
        }
}
bool Chance(Player* player, uint32 talent, float multiplier, uint32 cooldown)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(talent);
    if (!info || !player->HasAura(talent) || State(player).cooldowns.HasTimeUntilEvent(talent))
        return false;
    float chance = info->ProcChance * multiplier;
    player->ApplySpellMod(talent, SPELLMOD_CHANCE_OF_SUCCESS, chance);
    if (!roll_chance_f(std::clamp(chance, 0.0f, 100.0f)))
        return false;
    if (cooldown)
        State(player).cooldowns.ScheduleEvent(talent, Milliseconds(cooldown));
    return true;
}
bool Disease(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 29 &&
           (info->Dispel == DISPEL_DISEASE || info->Id == 570131 || info->Id == 802132);
}
uint32 Diseases(Player* player, Unit* target)
{
    uint32 count = 0;
    if (target)
        for (auto const& [key, application] : target->GetAppliedAuras())
            if (Aura const* aura = application->GetBase();
                aura->GetCasterGUID() == player->GetGUID() && Disease(aura->GetSpellInfo()))
                ++count;
    return count;
}
void ExtendWorms(Player* player, Unit* target, int32 milliseconds)
{
    if (!target || milliseconds <= 0)
        return;
    for (auto const& [key, application] : target->GetAppliedAuras())
        if (Aura* aura = application->GetBase(); aura->GetCasterGUID() == player->GetGUID() &&
                                                 Named(aura->GetSpellInfo(), 500338) && aura->GetDuration() > 0)
            aura->SetDuration(int32(std::min<int64>(int64(aura->GetDuration()) + milliseconds, INT32_MAX)));
}
void Plague(Player* player, Unit* target, uint8 stacks)
{
    if (!target || !target->IsAlive() || !player->IsValidAttackTarget(target))
        return;
    if (Aura* aura = target->GetAura(570131, player->GetGUID()))
    {
        uint32 maximum = aura->GetSpellInfo()->CalcMaxAuraStacks(player);
        aura->SetStackAmount(uint8(std::min<uint32>(maximum, uint32(aura->GetStackAmount()) + stacks)));
    }
    else if (Aura* fresh = player->AddAura(570131, target))
        fresh->SetStackAmount(stacks);
    if (player->HasAura(574138))
        Cast(player, player, 573131);
    if (player->HasAura(300965))
        ExtendWorms(player, target, std::abs(Amount(301337, 0, player)));
}
void Spread(Player* player, Unit* source, bool refresh, bool allDiseases, uint32 limit)
{
    if (!source)
        return;
    std::vector<uint32> ids;
    for (auto const& [key, application] : source->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() == player->GetGUID() &&
            (allDiseases ? Disease(aura->GetSpellInfo()) : Named(aura->GetSpellInfo(), 500338)))
        {
            ids.push_back(aura->GetId());
            if (refresh)
                aura->RefreshDuration();
        }
    }
    uint32 count = 0;
    for (Unit* target : Nearby(source, 10.0f))
    {
        if (target == source || !player->IsValidAttackTarget(target) || !source->IsWithinLOSInMap(target))
            continue;
        for (uint32 id : ids)
            if (Aura* original = source->GetAura(id, player->GetGUID()))
                if (Aura* copy = player->AddAura(id, target))
                {
                    copy->SetStackAmount(original->GetStackAmount());
                    copy->SetMaxDuration(original->GetMaxDuration());
                    copy->SetDuration(original->GetDuration());
                    copy->SetScriptValue(801747, original->GetScriptValue(801747));
                    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                        if (AuraEffect* effect = copy->GetEffect(index))
                            if (AuraEffect* from = original->GetEffect(index))
                            {
                                effect->ChangeAmount(from->GetAmount());
                                effect->SetPeriodicTimer(from->GetPeriodicTimer());
                            }
                }
        if (limit && ++count >= limit)
            break;
    }
}
}

namespace
{
using namespace AscensionNecromancer;
class necromancer_sessions : public PlayerScript
{
  public:
    necromancer_sessions()
        : PlayerScript("necromancer_sessions", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_PVP_KILL,
                                                PLAYERHOOK_ON_CREATURE_KILL, PLAYERHOOK_ON_CREATURE_KILLED_BY_PET})
    {
    }
    void OnPlayerLogin(Player* player) override
    {
        if (player->HasAura(500981) && !player->HasAura(504691))
            Cast(player, player, 504691);
    }
    void OnPlayerLogout(Player* player) override
    {
        Forget(player);
    }
    void Reward(Player* player, Unit* killed)
    {
        if (player && Owner(player) == player && killed && killed->GetCharmerOrOwnerPlayerOrPlayerItself() != player &&
            player->isHonorOrXPTarget(killed) && player->HasAura(707562))
            Cast(player, player, 712434);
    }
    void OnPlayerPVPKill(Player* player, Player* killed) override
    {
        Reward(player, killed);
    }
    void OnPlayerCreatureKill(Player* player, Creature* killed) override
    {
        Reward(player, killed);
    }
    void OnPlayerCreatureKilledByPet(Player* player, Creature* killed) override
    {
        Reward(player, killed);
    }
};
class necromancer_lifecycle : public UnitScript
{
  public:
    necromancer_lifecycle()
        : UnitScript("necromancer_lifecycle", true, {UNITHOOK_ON_UNIT_UPDATE, UNITHOOK_ON_UNIT_DEATH})
    {
    }
    void OnUnitDeath(Unit* unit, Unit*) override
    {
        Player* player = Owner(unit);
        if (player == unit)
            Prune(player, true);
        else if (player)
            Sync(player);
    }
    void OnUnitUpdate(Unit* unit, uint32 diff) override
    {
        Player* player = Owner(unit);
        if (!player || player != unit || !player->IsInWorld())
            return;
        auto& state = State(player);
        state.cooldowns.Update(diff);
        while (state.cooldowns.ExecuteEvent())
        {
        }
        if (!state.events.HasTimeUntilEvent(1))
            state.events.ScheduleEvent(1, 1ms);
        state.events.Update(diff);
        while (uint32 event = state.events.ExecuteEvent())
        {
            if (event == 1)
            {
                Sync(player);
                for (uint32 id : {572638, 706472, 531126, 560012, 500982, 500985, 301207})
                    if (Aura* aura = player->GetAura(id))
                        aura->RecalculateAmountOfEffects();
                state.events.ScheduleEvent(1, 500ms);
            }
        }
    }
};
}
void AddAscensionNecromancerScripts()
{
    new necromancer_sessions();
    new necromancer_lifecycle();
}
