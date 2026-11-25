#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GossipDef.h"
#include "Group.h"
#include "InstanceSaveMgr.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <chrono>
#include <tuple>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 ResetText = 9990502;
constexpr int64 DefaultCostGold = 10;
constexpr auto QuoteLifetime = std::chrono::minutes(1);
std::atomic<uint32> resetCost{DefaultCostGold * GOLD};

enum ResetAction : uint32
{
    Personal = 1,
    Raid = 2,
    Confirm = 3,
    Cancel = 4
};

struct Binding
{
    ObjectGuid player;
    uint32 map;
    Difficulty difficulty;
    uint32 instance;

    bool operator==(Binding const&) const = default;
};

struct ResetPlan
{
    std::vector<Binding> bindings;
    uint32 characters = 0;
    uint32 skipped = 0;
};

struct Quote
{
    ResetPlan plan;
    bool raid;
    ObjectGuid group;
    uint32 cost;
    std::chrono::steady_clock::time_point expires;
};

bool Available(Player* player)
{
    return player && player->IsInWorld() && player->IsAlive() && !player->IsInCombat()
        && !player->IsBeingTeleported() && player->FindMap() && !player->GetMap()->Instanceable();
}

bool LeadsRaid(Player* player)
{
    Group* group = player->GetGroup();
    return group && group->isRaidGroup() && group->IsLeader(player->GetGUID());
}

void CollectBindings(Player* player, ResetPlan& plan)
{
    if (!Available(player))
    {
        ++plan.skipped;
        return;
    }
    std::size_t const before = plan.bindings.size();
    for (uint8 mode = 0; mode < MAX_RAID_DIFFICULTY; ++mode)
        for (auto const& [mapId, bind] : sInstanceSaveMgr->PlayerGetBoundInstances(player->GetGUID(), Difficulty(mode)))
            if (MapEntry const* map = sMapStore.LookupEntry(mapId); map && map->IsRaid() && bind.save)
                plan.bindings.push_back({player->GetGUID(), mapId, Difficulty(mode), bind.save->GetInstanceId()});
    if (plan.bindings.size() != before)
        ++plan.characters;
}

ResetPlan BuildPlan(Player* requester, bool raid)
{
    ResetPlan plan;
    CollectBindings(requester, plan);
    if (raid)
        for (Group::MemberSlot const& slot : requester->GetGroup()->GetMemberSlots())
        {
            if (slot.guid == requester->GetGUID())
                continue;
            Player* member = ObjectAccessor::FindConnectedPlayer(slot.guid);
            if (member && member->GetSession() && member->GetSession()->IsBot())
                CollectBindings(member, plan);
            else
                ++plan.skipped;
        }
    std::sort(plan.bindings.begin(), plan.bindings.end(), [](Binding const& left, Binding const& right)
    {
        return std::tie(left.player, left.map, left.difficulty, left.instance)
            < std::tie(right.player, right.map, right.difficulty, right.instance);
    });
    return plan;
}

class raid_reset_config : public WorldScript
{
public:
    raid_reset_config()
        : WorldScript("raid_reset_config", {WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnStartup() override
    {
        OnAfterConfigLoad(false);
    }

    void OnAfterConfigLoad(bool) override
    {
        int64 const gold = sConfigMgr->GetOption<int64>("CoA.RaidReset.CostGold", DefaultCostGold);
        resetCost = uint32(std::clamp<int64>(gold, 0, MAX_MONEY_AMOUNT / GOLD) * GOLD);
    }
};

struct npc_coa_raid_reset : ScriptedAI
{
    explicit npc_coa_raid_reset(Creature* creature) : ScriptedAI(creature) { }

    std::unordered_map<ObjectGuid, Quote> quotes;

    void Tell(Player* player, char const* message)
    {
        ChatHandler(player->GetSession()).SendSysMessage(message);
    }

    void sGossipHello(Player* player) override
    {
        auto const now = std::chrono::steady_clock::now();
        std::erase_if(quotes, [now](auto const& pair) { return pair.second.expires <= now; });
        quotes.erase(player->GetGUID());
        ClearGossipMenuFor(player);
        if (!Available(player) || player->GetSession()->IsBot())
        {
            Tell(player, "You must be alive, out of combat, and outside instances to clear raid locks.");
            CloseGossipMenuFor(player);
            return;
        }
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Clear all my raid locks", GOSSIP_SENDER_MAIN, Personal);
        if (LeadsRaid(player))
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Clear my raid locks and my raid's bot locks",
                GOSSIP_SENDER_MAIN, Raid);
        SendGossipMenuFor(player, ResetText, me->GetGUID());
    }

    void sGossipSelect(Player* player, uint32, uint32 option) override
    {
        uint32 const action = player->PlayerTalkClass->GetGossipOptionAction(option);
        ClearGossipMenuFor(player);
        CloseGossipMenuFor(player);
        if (action == Cancel)
        {
            quotes.erase(player->GetGUID());
            return;
        }
        if (!Available(player) || player->GetSession()->IsBot())
        {
            quotes.erase(player->GetGUID());
            Tell(player, "You must be alive, out of combat, and outside instances to clear raid locks.");
            return;
        }
        if (action == Personal || action == Raid)
        {
            bool const raid = action == Raid;
            if (raid && !LeadsRaid(player))
            {
                Tell(player, "Only the raid leader can clear bot raid locks.");
                return;
            }
            ResetPlan plan = BuildPlan(player, raid);
            if (plan.bindings.empty())
            {
                Tell(player, "There are no eligible raid locks to clear. You have not been charged.");
                return;
            }
            uint32 const cost = resetCost.load();
            std::string const prompt = Acore::StringFormat(
                "Clear {} raid locks across {} characters for {} gold total? {} other members skipped. "
                "All raid difficulties are included. Other players' raid locks are unchanged.",
                plan.bindings.size(), plan.characters, cost / GOLD, plan.skipped);
            quotes.insert_or_assign(player->GetGUID(), Quote{std::move(plan), raid,
                raid ? player->GetGroup()->GetGUID() : ObjectGuid::Empty, cost,
                std::chrono::steady_clock::now() + QuoteLifetime});
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Confirm raid lock reset", GOSSIP_SENDER_MAIN,
                Confirm, prompt, 0, false);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Cancel", GOSSIP_SENDER_MAIN, Cancel);
            SendGossipMenuFor(player, ResetText, me->GetGUID());
            return;
        }
        if (action != Confirm)
            return;
        auto const found = quotes.find(player->GetGUID());
        if (found == quotes.end())
            return;
        Quote quote = std::move(found->second);
        quotes.erase(found);
        if (quote.expires <= std::chrono::steady_clock::now() || quote.cost != resetCost.load()
            || (quote.raid && (!LeadsRaid(player) || player->GetGroup()->GetGUID() != quote.group)))
        {
            Tell(player, "Your reset quote has changed or expired. Please request a new quote.");
            return;
        }
        ResetPlan const current = BuildPlan(player, quote.raid);
        if (current.bindings != quote.plan.bindings)
        {
            Tell(player, "The eligible raid locks have changed. Please request a new quote.");
            return;
        }
        if (player->GetMoney() < quote.cost)
        {
            Tell(player, "You do not have enough gold. No raid locks were cleared.");
            return;
        }
        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        for (Binding const& binding : current.bindings)
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_DEL_CHAR_INSTANCE_BY_INSTANCE_GUID);
            statement->SetData(0, binding.player.GetCounter());
            statement->SetData(1, binding.instance);
            transaction->Append(statement);
        }
        player->ModifyMoney(-int32(quote.cost));
        player->SaveGoldToDB(transaction);
        for (Binding const& binding : current.bindings)
            sInstanceSaveMgr->PlayerUnbindInstance(binding.player, binding.map, binding.difficulty, false,
                ObjectAccessor::FindConnectedPlayer(binding.player));
        CharacterDatabase.CommitTransaction(transaction);
        Tell(player, Acore::StringFormat("Cleared {} raid locks across {} characters for {} gold total.",
            current.bindings.size(), current.characters, quote.cost / GOLD).c_str());
    }
};
}

void AddSC_CoARaidResetNpc()
{
    new raid_reset_config();
    RegisterCreatureAI(npc_coa_raid_reset);
}
