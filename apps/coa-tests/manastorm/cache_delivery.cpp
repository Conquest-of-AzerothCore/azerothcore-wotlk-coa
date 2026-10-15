#include "AscensionManastormRules.h"
#include <array>
#include <cassert>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using namespace Ascension::Manastorm;
#define ASSERT assert
#define LOG_ERROR(...)
#define LOG_DEBUG(...)
struct ObjectGuid
{
    using LowType = uint32;
    uint32 value = 7;
    uint32 GetCounter() const
    {
        return value;
    }
    std::string ToString() const
    {
        return std::to_string(value);
    }
    auto operator<=>(ObjectGuid const&) const = default;
};
enum ItemUpdateState
{
    ITEM_UNCHANGED,
    ITEM_CHANGED,
    ITEM_NEW,
    ITEM_REMOVED
};
enum InventoryResult
{
    EQUIP_ERR_OK,
    EQUIP_ERR_INVENTORY_FULL
};
constexpr uint8 NULL_BAG = 0, NULL_SLOT = 255, INVENTORY_SLOT_BAG_0 = 0;
constexpr uint32 ACHIEVEMENT_CRITERIA_TYPE_OWN_ITEM = 1;
enum Statements
{
    CHAR_SEL_MANASTORM_CACHES,
    CHAR_SEL_MANASTORM_INVENTORY_ITEM,
    CHAR_INS_MANASTORM_CACHE_INVENTORY,
    CHAR_DEL_MANASTORM_CACHE,
    ITEM_SAVE,
    ITEM_DELETE
};
struct Statement
{
    Statements type;
    std::array<uint32, 4> values{};
    void SetData(unsigned index, uint32 value)
    {
        values[index] = value;
    }
};
struct Transaction
{
    std::vector<std::unique_ptr<Statement>> statements;
    void Append(Statement* statement)
    {
        statements.emplace_back(statement);
    }
};
using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;
struct Field
{
    uint32 value = 0;
    template <class T> T Get() const
    {
        return T(value);
    }
};
struct QueryRows
{
    std::vector<std::array<Field, 13>> rows;
    std::size_t index = 0;
    Field* Fetch()
    {
        return rows.at(index).data();
    }
    bool NextRow()
    {
        return ++index < rows.size();
    }
};
using PreparedQueryResult = std::shared_ptr<QueryRows>;
struct ItemRecord
{
    uint32 owner = 7, entry = 97877, count = 1;
};
struct PositionRecord
{
    uint32 owner = 7, bag = 0, slot = 23;
};
struct Future
{
    std::function<bool()> call;
    bool get()
    {
        return call();
    }
};
struct Callback
{
    Future m_future;
};
struct Database
{
    std::map<uint32, ItemRecord> items;
    std::map<uint32, uint32> pending;
    std::map<uint32, PositionRecord> inventory;
    bool fail = false, failRead = false;
    std::function<void()> beforeCommit;
    auto BeginTransaction()
    {
        return std::make_shared<Transaction>();
    }
    Statement* GetPreparedStatement(Statements type)
    {
        return new Statement{type};
    }
    PreparedQueryResult Query(Statement* raw)
    {
        std::unique_ptr<Statement> statement(raw);
        if (failRead)
            return {};
        auto result = std::make_shared<QueryRows>();
        result->rows.emplace_back();
        auto const& v = statement->values;
        if (statement->type == CHAR_SEL_MANASTORM_INVENTORY_ITEM)
        {
            result->rows[0][0].value = inventory.contains(v[1]) && inventory.at(v[1]).owner == v[0] &&
                                       items.contains(v[1]) && items.at(v[1]).owner == v[0];
        }
        else
        {
            assert(statement->type == CHAR_SEL_MANASTORM_CACHES);
            for (auto const& [id, owner] : pending)
                if (owner == v[0] && result->rows.size() < 4)
                {
                    auto& row = result->rows.emplace_back();
                    row[11].value = id;
                    if (items.contains(id) && items.at(id).owner == owner)
                    {
                        row[2].value = items.at(id).count;
                        row[12].value = items.at(id).entry;
                    }
                }
        }
        return result;
    }
    Callback AsyncCommitTransaction(CharacterDatabaseTransaction transaction)
    {
        return {{[this, transaction]
                 {
                     if (beforeCommit)
                         beforeCommit();
                     auto newItems = items;
                     auto newInventory = inventory;
                     auto newPending = pending;
                     for (auto const& statement : transaction->statements)
                     {
                         auto const& v = statement->values;
                         switch (statement->type)
                         {
                             case ITEM_SAVE:
                                 newItems.at(v[0]).count = v[1];
                                 break;
                             case ITEM_DELETE:
                                 newItems.erase(v[0]);
                                 break;
                             case CHAR_DEL_MANASTORM_CACHE:
                                 if (newPending.contains(v[0]) && newPending.at(v[0]) == v[1])
                                     newPending.erase(v[0]);
                                 break;
                             case CHAR_INS_MANASTORM_CACHE_INVENTORY:
                                 if (newInventory.contains(v[3]))
                                     return false;
                                 for (auto const& [id, position] : newInventory)
                                     if (position.owner == v[0] && position.bag == v[1] && position.slot == v[2])
                                         return false;
                                 newInventory[v[3]] = {v[0], v[1], v[2]};
                                 break;
                             default:
                                 assert(false);
                         }
                     }
                     if (fail)
                         return false;
                     items = std::move(newItems);
                     inventory = std::move(newInventory);
                     pending = std::move(newPending);
                     return true;
                 }}};
    }
} CharacterDatabase;
struct Player;
struct Item
{
    ObjectGuid guid{}, owner{};
    uint32 entry = 97877, count = 1;
    ItemUpdateState uState = ITEM_NEW;
    int32 uQueuePos = -1;
    bool trade = false;
    bool LoadFromDB(uint32 id, ObjectGuid who, Field* fields, uint32 type)
    {
        guid.value = id;
        owner = who;
        count = fields[2].value;
        entry = type;
        return true;
    }
    ObjectGuid GetGUID() const
    {
        return guid;
    }
    ObjectGuid GetOwnerGUID() const
    {
        return owner;
    }
    uint32 GetCount() const
    {
        return count;
    }
    void SetCount(uint32 value)
    {
        count = value;
    }
    bool IsInTrade() const
    {
        return trade;
    }
    ItemUpdateState GetState() const
    {
        return uState;
    }
    void FSetState(ItemUpdateState state)
    {
        uState = state;
    }
    bool IsInUpdateQueue() const
    {
        return uQueuePos != -1;
    }
    void SetState(ItemUpdateState state, Player* forplayer = nullptr);
    void AddToUpdateQueueOf(Player* player);
    void RemoveFromUpdateQueueOf(Player* player);
    void SaveToDB(CharacterDatabaseTransaction transaction)
    {
        assert(uState == ITEM_CHANGED);
        auto* statement = CharacterDatabase.GetPreparedStatement(ITEM_SAVE);
        statement->SetData(0, guid.value);
        statement->SetData(1, count);
        transaction->Append(statement);
        SetState(ITEM_UNCHANGED);
    }
    static void DeleteFromDB(CharacterDatabaseTransaction transaction, uint32 id)
    {
        auto* statement = CharacterDatabase.GetPreparedStatement(ITEM_DELETE);
        statement->SetData(0, id);
        transaction->Append(statement);
    }
};
struct Bag : Item
{
};
struct ItemPosCount
{
    uint16 pos;
    uint32 count;
};
using ItemPosCountVec = std::vector<ItemPosCount>;
struct Player
{
    ObjectGuid guid{};
    std::map<uint16, std::unique_ptr<Item>> slots;
    std::unique_ptr<Bag> bag;
    std::vector<Item*> m_itemUpdateQueue;
    bool m_itemUpdateQueueBlocked = false, space = true, crashAfterCommit = false;
    uint16 freePosition = 23;
    uint32 notices = 0, delivered = 0;
    ObjectGuid GetGUID() const
    {
        return guid;
    }
    Player* GetSession()
    {
        return this;
    }
    void DeleteRefundReference(ObjectGuid) {}
    Bag* GetBagByPos(uint8)
    {
        return bag.get();
    }
    Item* GetItemByPos(uint16 pos)
    {
        return slots.contains(pos) ? slots.at(pos).get() : nullptr;
    }
    InventoryResult CanStoreItem(uint8, uint8, ItemPosCountVec& positions, Item* item)
    {
        for (auto const& [pos, stack] : slots)
            if (stack->entry == item->entry && stack->count < 100 && !stack->trade)
            {
                positions.push_back({pos, 1});
                return EQUIP_ERR_OK;
            }
        if (!space)
            return EQUIP_ERR_INVENTORY_FULL;
        positions.push_back({freePosition, 1});
        return EQUIP_ERR_OK;
    }
    Item* StoreItem(ItemPosCountVec const& positions, Item* raw, bool)
    {
        std::unique_ptr<Item> item(raw);
        if (crashAfterCommit)
            throw 1;
        uint16 pos = positions.front().pos;
        Item* stack = GetItemByPos(pos);
        if (stack)
            ++stack->count;
        else
        {
            slots[pos] = std::move(item);
            stack = slots[pos].get();
        }
        stack->SetState(ITEM_CHANGED, this);
        return stack;
    }
    void ItemAddedQuestCheck(uint32, uint32) {}
    void UpdateAchievementCriteria(uint32, uint32, uint32) {}
    void SendNewItem(Item*, uint32 count, bool, bool)
    {
        delivered += count;
    }
};
// ACTUAL_ITEM_STATE
// ACTUAL_ITEM_ADD_QUEUE
// ACTUAL_ITEM_REMOVE_QUEUE
struct ChatHandler
{
    Player* player;
    explicit ChatHandler(Player* p) : player(p) {}
    void SendSysMessage(char const*)
    {
        ++player->notices;
    }
};
struct Scripts
{
    void OnPlayerStoreNewItem(Player*, Item*, uint32) {}
} scripts;
auto* sScriptMgr = &scripts;
struct Run
{
    bool cachesPending = true, cacheSpaceWarning = false;
};
struct Service
{
    // ACTUAL_STORED_ITEM
    // ACTUAL_STACK
    // ACTUAL_DELIVER
};
void Reset()
{
    CharacterDatabase = {};
    CharacterDatabase.items[100] = {};
    CharacterDatabase.pending[100] = 7;
}
void AddStack(Player& player, ItemUpdateState state)
{
    auto item = std::make_unique<Item>();
    item->guid.value = 200;
    item->count = 3;
    item->uState = state;
    if (state != ITEM_UNCHANGED)
        item->AddToUpdateQueueOf(&player);
    player.slots[23] = std::move(item);
    CharacterDatabase.items[200] = {7, 97877, 3};
    CharacterDatabase.inventory[200] = {};
}
int main()
{
    Service service;
    {
        Reset();
        Player player;
        Run run;
        CharacterDatabase.beforeCommit = [&] { assert(player.slots.empty() && player.delivered == 0); };
        service.DeliverCaches(&player, run);
        assert(player.slots.at(23)->guid.value == 100 && player.delivered == 1);
        assert(CharacterDatabase.pending.empty() && CharacterDatabase.inventory.at(100).slot == 23);
        service.DeliverCaches(&player, run);
        assert(!run.cachesPending && player.delivered == 1);
    }
    {
        Reset();
        Player player;
        Run run;
        player.space = false;
        service.DeliverCaches(&player, run);
        service.DeliverCaches(&player, run);
        assert(player.notices == 1 && player.delivered == 0 && CharacterDatabase.pending.contains(100));
        player.space = true;
        service.DeliverCaches(&player, run);
        assert(player.delivered == 1 && !run.cacheSpaceWarning);
    }
    {
        Reset();
        Player player;
        Run run;
        CharacterDatabase.fail = true;
        service.DeliverCaches(&player, run);
        assert(player.slots.empty() && CharacterDatabase.pending.contains(100) &&
               CharacterDatabase.items.contains(100));
        CharacterDatabase.fail = false;
        service.DeliverCaches(&player, run);
        assert(player.delivered == 1);
    }
    for (auto state : {ITEM_UNCHANGED, ITEM_CHANGED, ITEM_NEW})
    {
        Reset();
        Player player;
        Run run;
        AddStack(player, state);
        Item* stack = player.slots.at(23).get();
        CharacterDatabase.beforeCommit = [&]
        {
            assert(stack->count == 3 && stack->uState == state);
            assert(std::count(player.m_itemUpdateQueue.begin(), player.m_itemUpdateQueue.end(), stack) ==
                   (state != ITEM_UNCHANGED));
        };
        CharacterDatabase.fail = true;
        service.DeliverCaches(&player, run);
        assert(stack->count == 3 && CharacterDatabase.items.at(200).count == 3 &&
               CharacterDatabase.pending.contains(100));
        CharacterDatabase.fail = false;
        service.DeliverCaches(&player, run);
        assert(stack->count == 4 && CharacterDatabase.items.at(200).count == 4 &&
               !CharacterDatabase.items.contains(100));
        assert(CharacterDatabase.pending.empty() && CharacterDatabase.inventory.size() == 1 && player.delivered == 1);
    }
    {
        Reset();
        Player player;
        Run run;
        player.bag = std::make_unique<Bag>();
        player.bag->guid.value = 500;
        player.freePosition = 0x0102;
        service.DeliverCaches(&player, run);
        assert(player.delivered == 0);
        CharacterDatabase.items[500] = {7, 1234, 1};
        CharacterDatabase.inventory[500] = {7, 0, 19};
        service.DeliverCaches(&player, run);
        assert(CharacterDatabase.inventory.at(100).bag == 500 && CharacterDatabase.inventory.at(100).slot == 2);
    }
    {
        Reset();
        Player player;
        Run run;
        CharacterDatabase.inventory[999] = {};
        service.DeliverCaches(&player, run);
        assert(player.delivered == 0 && CharacterDatabase.inventory.contains(999) &&
               CharacterDatabase.pending.contains(100));
    }
    {
        Reset();
        Player player;
        Run run;
        CharacterDatabase.failRead = true;
        service.DeliverCaches(&player, run);
        assert(run.cachesPending && player.delivered == 0);
        CharacterDatabase.failRead = false;
        player.guid.value = 8;
        service.DeliverCaches(&player, run);
        assert(player.delivered == 0 && CharacterDatabase.pending.contains(100));
    }
    {
        Reset();
        Player player;
        Run run;
        player.crashAfterCommit = true;
        try
        {
            service.DeliverCaches(&player, run);
            assert(false);
        }
        catch (int)
        {
        }
        assert(CharacterDatabase.inventory.contains(100) && CharacterDatabase.pending.empty());
        Player reconnect;
        Run newRun;
        service.DeliverCaches(&reconnect, newRun);
        assert(!newRun.cachesPending && reconnect.delivered == 0);
    }
    return 0;
}
