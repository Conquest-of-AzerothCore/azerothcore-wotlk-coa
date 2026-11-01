#include "AscensionPendingStatQueries.h"
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <map>
#include <set>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

using uint32 = std::uint32_t;

struct ItemTemplate
{
    uint32 ItemId = 0;
    uint32 ItemLevel = 0;
    uint32 Armor = 0;
};

class WorldPacket
{
public:
    WorldPacket() = default;
    WorldPacket(uint32 itemId, uint32 level) : words{itemId, level} { }

    std::size_t size() const { return words.size() * sizeof(uint32); }

    template <typename T>
    T read(std::size_t position) const { return T(words.at(position / sizeof(uint32))); }

    std::vector<uint32> words;
    bool stock = false;
    uint32 armorReborn = 0;
};

class Player;

class WorldSession
{
public:
    explicit WorldSession(uint32 accountId) : _accountId(accountId) { }

    uint32 GetAccountId() const { return _accountId; }
    Player* GetPlayer() const
    {
        ++playerReads;
        return nullptr;
    }
    void SendPacket(WorldPacket const* packet) { sent.push_back(*packet); }

    std::vector<WorldPacket> sent;
    mutable int playerReads = 0;

private:
    uint32 _accountId;
};

class Player
{
public:
    explicit Player(WorldSession* session) : _session(session) { }

    WorldSession* GetSession() const { return _session; }

    std::set<std::pair<uint32, uint32>> stored;

private:
    WorldSession* _session;
};

struct ObjectMgr
{
    std::unordered_map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 item) const
    {
        auto const found = items.find(item);
        return found == items.end() ? nullptr : &found->second;
    }
} objectMgr;
ObjectMgr* sObjectMgr = &objectMgr;

namespace ItemLadder
{
struct Row
{
    uint32 ItemId = 0;
    uint32 Level = 0;
    uint32 Armor = 0;
    uint32 ArmorReborn = 0;
};

Row StockRow(ItemTemplate const& proto, uint32 armorReborn)
{
    return {proto.ItemId, proto.ItemLevel, proto.Armor, armorReborn};
}

WorldPacket BuildItemStatResponse(uint32 itemId, uint32 level, Row const& row, ItemTemplate const*)
{
    WorldPacket packet(itemId, level);
    packet.stock = row.Armor == objectMgr.items.at(itemId).Armor;
    packet.armorReborn = row.ArmorReborn;
    return packet;
}
}

namespace NativeItemScaling
{
std::atomic<bool> enabled{true};
std::atomic<bool> preview{true};
std::atomic<bool> rebornArmor{false};

bool PreviewOn() { return preview.load(); }
uint32 AuthoredRebornArmor(ItemTemplate const& proto) { return proto.Armor * 2; }

bool OwnsStoredKey(Player* player, uint32 itemId, uint32 key)
{
    return player->stored.contains({itemId, key});
}

class LadderStore
{
public:
    static LadderStore& Instance()
    {
        static LadderStore store;
        return store;
    }

    ItemLadder::Row const* Row(uint32 itemId, uint32 level) const
    {
        auto const found = rows.find({itemId, level});
        return found == rows.end() ? nullptr : &found->second;
    }

    std::map<std::pair<uint32, uint32>, ItemLadder::Row> rows;
};

// ACTUAL_PENDING_QUERIES
}

namespace
{
constexpr uint32 Helm = 1001;
constexpr uint32 Boots = 1002;
constexpr uint32 BaseLevel = 30;

int checks = 0;
int failures = 0;

void Check(bool value, char const* name)
{
    ++checks;
    failures += !value;
    std::cout << (value ? "PASS: " : "FAIL: ") << name << '\n';
}

void Reset()
{
    NativeItemScaling::preview = true;
    NativeItemScaling::rebornArmor = false;
    for (uint32 account = 0; account < 64; ++account)
        static_cast<void>(NativeItemScaling::pendingStatQueries.Take(account));
}

void Seed()
{
    objectMgr.items[Helm] = {Helm, BaseLevel, 100};
    objectMgr.items[Boots] = {Boots, BaseLevel, 80};
    auto& rows = NativeItemScaling::LadderStore::Instance().rows;
    for (uint32 item : {Helm, Boots})
        for (uint32 level : {BaseLevel, BaseLevel + 10})
            rows[{item, level}] = {item, level, 500 + level, 900 + level};
}

void TestScaledLevelAnswersOnNetworkThread()
{
    Reset();
    WorldSession session(1);
    NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(Helm, BaseLevel + 10));
    Check(session.sent.size() == 1 && session.sent[0].read<uint32>(4) == BaseLevel + 10 && !session.sent[0].stock,
        "a scaled level is answered at once with its ladder row");
    Check(session.sent.size() == 1 && session.sent[0].armorReborn == 500 + BaseLevel + 10,
        "reborn armor off mirrors plain armor");
    Check(!session.playerReads && !NativeItemScaling::pendingStatQueries.Size(),
        "a scaled level reads no player and defers nothing");
}

void TestBaseLevelDefersOwnershipToWorldThread()
{
    Reset();
    WorldSession session(2);
    for (int repeat = 0; repeat < 5; ++repeat)
        NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(Helm, BaseLevel));
    NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(Boots, BaseLevel));
    Check(session.sent.empty() && !session.playerReads,
        "a base-level query reads no player and sends nothing on the network thread");
    Check(NativeItemScaling::pendingStatQueries.Size() == 2, "repeated base-level queries are deferred once per item");

    Player player(&session);
    player.stored.insert({Boots, BaseLevel});
    NativeItemScaling::AnswerPendingStatQueries(&player);
    bool helmStock = false;
    bool bootsLadder = false;
    for (WorldPacket const& reply : session.sent)
    {
        helmStock = helmStock || (reply.read<uint32>(0) == Helm && reply.stock);
        bootsLadder = bootsLadder || (reply.read<uint32>(0) == Boots && !reply.stock);
    }
    Check(session.sent.size() == 2 && helmStock, "an item the player does not own gets the stock row");
    Check(bootsLadder, "an owned item at its stored base level gets the ladder row");
    Check(!NativeItemScaling::pendingStatQueries.Size(), "answering empties the deferred set");

    NativeItemScaling::AnswerPendingStatQueries(&player);
    Check(session.sent.size() == 2, "a second world update sends nothing new");
}

void TestDeferredRepliesStayWithTheirAccount()
{
    Reset();
    WorldSession asker(3);
    WorldSession other(4);
    NativeItemScaling::HandleItemStatQuery(&asker, WorldPacket(Helm, BaseLevel));
    Player otherPlayer(&other);
    NativeItemScaling::AnswerPendingStatQueries(&otherPlayer);
    Check(other.sent.empty() && NativeItemScaling::pendingStatQueries.Size() == 1,
        "another account's update does not take the deferred query");

    Player askerPlayer(&asker);
    NativeItemScaling::DiscardPendingStatQueries(&askerPlayer);
    NativeItemScaling::AnswerPendingStatQueries(&askerPlayer);
    Check(asker.sent.empty() && !NativeItemScaling::pendingStatQueries.Size(),
        "logout discards the account's deferred queries");
}

void TestPreviewOffAnswersAtOnce()
{
    Reset();
    NativeItemScaling::preview = false;
    WorldSession session(5);
    NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(Helm, BaseLevel));
    Check(session.sent.size() == 1 && !session.sent[0].stock && !session.playerReads &&
        !NativeItemScaling::pendingStatQueries.Size(), "with preview off the base level is answered from the ladder");
}

void TestStockRowKeepsRebornArmor()
{
    Reset();
    NativeItemScaling::rebornArmor = true;
    WorldSession session(6);
    NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(Helm, BaseLevel));
    Player player(&session);
    NativeItemScaling::AnswerPendingStatQueries(&player);
    Check(session.sent.size() == 1 && session.sent[0].stock && session.sent[0].armorReborn == 200,
        "the deferred stock row carries the authored reborn armor");
}

void TestMalformedAndUnknownQueriesAreIgnored()
{
    Reset();
    WorldSession session(7);
    WorldPacket shortPacket;
    shortPacket.words = {Helm};
    NativeItemScaling::HandleItemStatQuery(&session, shortPacket);
    NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(Helm, 0));
    NativeItemScaling::HandleItemStatQuery(&session, WorldPacket(9999, BaseLevel));
    NativeItemScaling::HandleItemStatQuery(nullptr, WorldPacket(Helm, BaseLevel));
    Check(session.sent.empty() && !session.playerReads && !NativeItemScaling::pendingStatQueries.Size(),
        "short, level-zero, unknown and session-less queries are ignored");
}

void TestDeferredSetIsBounded()
{
    Reset();
    NativeItemScaling::PendingStatQueries queries;
    std::size_t const cap = NativeItemScaling::PendingStatQueries::MaxItemsPerAccount;
    bool accepted = true;
    for (uint32 item = 1; item <= cap; ++item)
        accepted = queries.Add(8, item) && accepted;
    Check(accepted && !queries.Add(8, uint32(cap + 1)) && queries.Add(8, 1) && queries.Size() == cap,
        "each account keeps at most its cap of distinct items, and repeats stay accepted");
    Check(queries.Add(9, uint32(cap + 1)) && queries.Size() == cap + 1, "the cap is per account");
}

void TestConcurrentQueriesAndUpdates()
{
    NativeItemScaling::PendingStatQueries queries;
    constexpr uint32 Accounts = 8;
    constexpr uint32 Items = 200;
    std::atomic<bool> producing{true};
    std::vector<std::thread> producers;
    for (uint32 account = 0; account < Accounts; ++account)
        producers.emplace_back([&queries, account]
        {
            for (uint32 item = 1; item <= Items; ++item)
                queries.Add(account, item);
        });
    std::vector<std::set<uint32>> taken(Accounts);
    std::thread consumer([&]
    {
        while (producing.load())
            for (uint32 account = 0; account < Accounts; ++account)
                for (uint32 item : queries.Take(account))
                    taken[account].insert(item);
    });
    for (std::thread& producer : producers)
        producer.join();
    producing = false;
    consumer.join();
    for (uint32 account = 0; account < Accounts; ++account)
        for (uint32 item : queries.Take(account))
            taken[account].insert(item);
    bool complete = true;
    for (std::set<uint32> const& items : taken)
        complete = complete && items.size() == Items;
    Check(complete && !queries.Size(), "concurrent queries and world updates lose nothing and leave no count behind");
}
}

int main()
{
    Seed();
    TestScaledLevelAnswersOnNetworkThread();
    TestBaseLevelDefersOwnershipToWorldThread();
    TestDeferredRepliesStayWithTheirAccount();
    TestPreviewOffAnswersAtOnce();
    TestStockRowKeepsRebornArmor();
    TestMalformedAndUnknownQueriesAreIgnored();
    TestDeferredSetIsBounded();
    TestConcurrentQueriesAndUpdates();
    std::cout << checks - failures << '/' << checks << " native item stat query checks passed\n";
    return failures ? 1 : 0;
}
