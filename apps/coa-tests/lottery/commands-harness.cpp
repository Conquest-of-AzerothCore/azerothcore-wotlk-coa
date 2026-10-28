#include "RULES_HEADER"
#include <array>
#include <cctype>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <variant>
#include <vector>
#define LOG_INFO(...)
#define LOG_ERROR(...)
namespace
{
using uint8 = uint8_t;
using int8 = int8_t;
using uint16 = uint16_t;
using uint32 = uint32_t;
using uint64 = uint64_t;
template<class T> using Optional = std::optional<T>;
using namespace CoALottery;
constexpr uint32 DAY = 86400, HOUR = 3600, MINUTE = 60;
constexpr uint32 MAIL_CREATURE = 3, MAIL_STATIONERY_DEFAULT = 41, MAIL_CHECK_MASK_NONE = 0, SERVER_MSG_STRING = 1;
namespace Acore
{
    template<class... Args> std::string StringFormat(std::string text, Args const&... args)
    {
        std::array<std::string, sizeof...(Args)> values{([&] {std::ostringstream out; out << args; return out.str();}())...};
        size_t position = 0;
        for (auto const& value : values)
        {
            position = text.find("{}", position);
            if (position == std::string::npos) throw std::runtime_error("format mismatch");
            text.replace(position, 2, value);
            position += value.size();
        }
        return text;
    }
    namespace ChatCommands
    {
        enum class Console {Yes};
        struct ChatCommandBuilder;
        using ChatCommandTable = std::vector<ChatCommandBuilder>;
        struct ChatCommandBuilder
        {
            std::string name;
            uint32 permission = 0;
            ChatCommandTable const* children = nullptr;
            template<class Handler> ChatCommandBuilder(char const* text, Handler&, uint32 level, Console) : name(text), permission(level) {}
            ChatCommandBuilder(char const* text, ChatCommandTable const& child) : name(text), children(&child) {}
        };
    }
}
constexpr uint32 SEC_GAMEMASTER = 2;
struct CommandScript
{
    explicit CommandScript(char const*) {}
    virtual ~CommandScript() = default;
    virtual Acore::ChatCommands::ChatCommandTable GetCommands() const = 0;
};
struct ChatHandler
{
    std::vector<std::string> messages;
    void SendSysMessage(std::string_view text) {messages.emplace_back(text);}
    void SendErrorMessage(std::string_view text, bool) {messages.emplace_back(text);}
    template<class... Args> void PSendSysMessage(char const* text, Args const&... args)
    {messages.push_back(Acore::StringFormat(text, args...));}
    bool Contains(std::string const& text) const
    {return std::any_of(messages.begin(), messages.end(), [&](auto const& message) {return message.find(text) != std::string::npos;});}
} chat;
enum class HighGuid {Player};
struct ObjectGuid
{
    uint32 guid = 0;
    ObjectGuid() = default;
    ObjectGuid(HighGuid, uint32 value) : guid(value) {}
    bool IsEmpty() const {return !guid;}
    uint32 GetCounter() const {return guid;}
};
struct Identity {std::string name; uint32 account = 42; bool deleted = false;};
struct Cache
{
    std::map<uint32, Identity> identities;
    uint32 GetCharacterAccountIdByGuid(ObjectGuid guid) const
    {
        auto found = identities.find(guid.guid);
        return found == identities.end() || found->second.deleted ? 0 : found->second.account;
    }
    ObjectGuid GetCharacterGuidByName(std::string const& name) const
    {
        for (auto const& [guid, identity] : identities)
            if (identity.name == name && !identity.deleted) return ObjectGuid(HighGuid::Player, guid);
        return ObjectGuid{};
    }
} cache;
auto* sCharacterCache = &cache;
bool normalizePlayerName(std::string& name)
{
    if (name.empty() || !std::all_of(name.begin(), name.end(), [](unsigned char c) {return std::isalpha(c);})) return false;
    for (char& c : name) c = char(std::tolower(static_cast<unsigned char>(c)));
    name[0] = char(std::toupper(static_cast<unsigned char>(name[0])));
    return true;
}
LOTTERY_STRUCTS
LotterySettings settings;
LotteryRound round;
bool ready = false, storageReady = false, automaticStart = true;
uint64 mockNow = 1000, nextDrawAttempt = 0;
std::mutex lotteryMutex;
uint64 Now() {return mockNow;}
uint32 urand(uint32 low, uint32) {return low;}
struct Field
{
    bool null = true;
    uint64 number = 0;
    std::string text;
    Field() = default;
    template<class T> explicit Field(T value) : null(false)
    {
        if constexpr (std::is_convertible_v<T, std::string>) text = value;
        else number = uint64(value);
    }
    bool IsNull() const {return null;}
    template<class T> T Get() const
    {
        if (null) throw std::runtime_error("read null field");
        if constexpr (std::is_same_v<T, std::string>) return text;
        else return T(number);
    }
};
struct Result
{
    std::vector<std::vector<Field>> rows;
    size_t index = 0;
    Field* Fetch() {return rows.at(index).data();}
    bool NextRow() {return ++index < rows.size();}
};
enum
{
    STATEMENT_ENUMS
    CHAR_INS_MAIL, CHAR_INS_MAIL_ITEM, SAVE_ITEM
};
struct Statement
{
    uint32 id;
    std::array<Field, 15> data;
    explicit Statement(uint32 value) : id(value) {}
    template<class T> void SetData(uint32 index, T value) {data.at(index) = Field(value);}
    uint64 N(uint32 index) const {return data.at(index).Get<uint64>();}
};
using CharacterDatabasePreparedStatement = Statement;
struct Transaction
{
    std::vector<Statement> operations;
    void Append(Statement* statement) {operations.push_back(*statement);}
};
using CharacterDatabaseTransaction = std::shared_ptr<Transaction>;
struct Entry {uint32 tickets = 0, spent = 0, contribution = 0;};
struct Store
{
    Optional<LotteryRound> active;
    std::map<uint64, LotteryRound> rounds;
    std::map<std::pair<uint64, uint32>, Entry> entries;
    std::map<uint32, std::pair<uint32, uint32>> mails;
    std::map<uint64, std::array<Field, 15>> winners;
    Optional<bool> enabled;
    bool autoStart = true;
} store;
struct Database
{
    bool failCommit = false, failQuery = false, failEntriesQuery = false;
    std::vector<std::unique_ptr<Statement>> statements;
    Statement* GetPreparedStatement(uint32 id)
    {statements.push_back(std::make_unique<Statement>(id)); return statements.back().get();}
    CharacterDatabaseTransaction BeginTransaction() {return std::make_shared<Transaction>();}
    std::shared_ptr<Result> Query(Statement* statement)
    {
        if (failQuery || (failEntriesQuery && statement->id == CHAR_SEL_LOTTERY_ENTRIES)) return nullptr;
        auto result = std::make_shared<Result>();
        switch (statement->id)
        {
            case CHAR_SEL_LOTTERY_STORAGE: result->rows = {{Field(4)}}; break;
            case CHAR_SEL_LOTTERY_CONTROL:
                result->rows = {{store.enabled ? Field(*store.enabled) : Field{}, Field(store.autoStart)}};
                break;
            case CHAR_SEL_LOTTERY_NEXT_ID:
                result->rows = {{Field(store.rounds.empty() ? 1 : store.rounds.rbegin()->first + 1)}};
                break;
            case CHAR_SEL_LOTTERY_ROUND:
                if (!store.active) return nullptr;
                {
                    auto const& r = *store.active;
                    result->rows = {{Field(r.id), Field(r.ends), Field(r.pot), Field(r.seed), Field(r.contribution),
                        Field(r.duration), Field(r.bonusItem), Field(r.fakeTickets), Field(r.paused), Field(r.pausedRemaining)}};
                }
                break;
            case CHAR_SEL_LOTTERY_WINNER_IDENTITY:
            {
                auto found = cache.identities.find(uint32(statement->N(0)));
                if (found == cache.identities.end() || found->second.deleted || !found->second.account) return nullptr;
                result->rows = {{Field(found->second.name), Field(found->second.account)}};
                break;
            }
            case CHAR_SEL_LOTTERY_ENTRIES:
            case CHAR_SEL_LOTTERY_ADMIN_ENTRIES:
                for (auto const& [key, entry] : store.entries)
                {
                    if (key.first != statement->N(0)) continue;
                    auto identity = cache.identities.find(key.second);
                    bool valid = identity != cache.identities.end() && !identity->second.deleted && identity->second.account;
                    if (statement->id == CHAR_SEL_LOTTERY_ENTRIES)
                    {
                        if (valid) result->rows.push_back({Field(key.second), Field(entry.tickets)});
                    }
                    else
                        result->rows.push_back({Field(key.second), Field(entry.tickets), Field(entry.spent), Field(entry.contribution),
                            valid ? Field(identity->second.name) : Field{}, valid ? Field(identity->second.account) : Field{}, Field{}});
                }
                if (statement->id == CHAR_SEL_LOTTERY_ADMIN_ENTRIES)
                    std::sort(result->rows.begin(), result->rows.end(), [](auto const& a, auto const& b)
                    {return a[1].number != b[1].number ? a[1].number > b[1].number : a[0].number < b[0].number;});
                if (result->rows.empty()) result->rows = {{Field{}, Field{}}};
                break;
            default: throw std::runtime_error("unexpected query");
        }
        return result;
    }
} CharacterDatabase;
bool Commit(CharacterDatabaseTransaction transaction)
{
    if (CharacterDatabase.failCommit) return false;
    auto original = store;
    try
    {
        for (auto const& stmt : transaction->operations)
        {
            auto N = [&](uint32 index) {return uint32(stmt.N(index));};
            switch (stmt.id)
            {
                case CHAR_INS_MAIL: store.mails[N(0)] = {N(5), N(11)}; break;
                case CHAR_INS_LOTTERY_ROUND:
                {
                    if (store.active || store.rounds.count(stmt.N(0))) throw std::runtime_error("duplicate round");
                    LotteryRound next;
                    next.id = stmt.N(0); next.ends = stmt.N(1); next.pot = N(2); next.seed = N(3);
                    next.contribution = N(4); next.duration = N(5); next.bonusItem = N(6); next.fakeTickets = N(7);
                    store.active = next; store.rounds[next.id] = next;
                    break;
                }
                case CHAR_UPD_LOTTERY_POT: store.active->pot = N(0); break;
                case CHAR_UPD_LOTTERY_END: store.active->ends = stmt.N(0); break;
                case CHAR_UPD_LOTTERY_PAUSE:
                    store.active->paused = N(0) != 0; store.active->pausedRemaining = stmt.N(1);
                    store.active->ends = stmt.N(2); break;
                case CHAR_UPD_LOTTERY_CONTROL: store.enabled = N(0) != 0; store.autoStart = N(1) != 0; break;
                case CHAR_CANCEL_LOTTERY_ROUND:
                case CHAR_COMPLETE_LOTTERY_ROUND:
                    store.rounds[store.active->id] = *store.active; store.active.reset(); break;
                case CHAR_DEL_LOTTERY_ENTRY: store.entries.erase({stmt.N(0), N(1)}); break;
                case CHAR_UPSERT_LOTTERY_ENTRY:
                {
                    auto& entry = store.entries[{stmt.N(0), N(1)}];
                    entry.tickets += N(2); entry.spent += N(3); entry.contribution += N(4); break;
                }
                case CHAR_INS_LOTTERY_WINNER: store.winners[stmt.N(0)] = stmt.data; break;
                case CHAR_INS_MAIL_ITEM:
                case SAVE_ITEM: break;
                default: throw std::runtime_error("unexpected write");
            }
        }
    }
    catch (...)
    {
        store = std::move(original);
        return false;
    }
    return true;
}
struct ItemTemplate {std::string Name1 = "Sigil of Goldilocks";};
struct ObjectManager
{
    uint32 nextMail = 100;
    ItemTemplate item;
    ItemTemplate const* GetItemTemplate(uint32 id) const {return id == 97393 || id == 98073 ? &item : nullptr;}
    uint32 GenerateMailID() {return nextMail++;}
} objectManager;
auto* sObjectMgr = &objectManager;
struct Item
{
    static Item* CreateItem(uint32, uint32) {return new Item;}
    void SetOwnerGUID(ObjectGuid) {}
    ObjectGuid GetGUID() const {return ObjectGuid(HighGuid::Player, 99);}
    ItemTemplate const* GetTemplate() const {return &objectManager.item;}
    void SaveToDB(CharacterDatabaseTransaction transaction)
    {transaction->Append(CharacterDatabase.GetPreparedStatement(SAVE_ITEM));}
};
std::vector<std::pair<uint32, uint32>> published;
void PublishMail(uint32 guid, uint32, uint32 gold, uint64, std::unique_ptr<Item>, bool = false)
{published.emplace_back(guid, gold);}
struct Sessions
{
    void SendServerMessage(uint32, std::string const&) {}
} sessions;
auto* sWorldSessionMgr = &sessions;
ROUND_METHODS
uint32 announcedDraws = 0;
void AnnounceDraw(std::string const&, uint32, bool) {++announcedDraws;}
DRAW_METHOD
struct Advertiser
{
    uint32 calls = 0;
    bool visible = false;
    void UpdateGoldilocksScale() {}
    void Update(uint32) {}
    void Configure() {++calls; visible = settings.enabled && ready;}
    bool Advertise(bool force) {return force && settings.enabled && ready && settings.spawnGallywix;}
} advertiser;
struct LotteryWorld
{
    WORLD_UPDATE_METHOD
};
COMMAND_METHODS
void Require(bool value, char const* message)
{if (!value) throw std::runtime_error(message);}
void Reset(bool running = true)
{
    settings = LotterySettings{};
    settings.contribution = 25;
    round = LotteryRound{};
    ready = storageReady = running;
    automaticStart = true;
    mockNow = 1000;
    nextDrawAttempt = 0;
    store = Store{};
    CharacterDatabase.failCommit = CharacterDatabase.failQuery = CharacterDatabase.failEntriesQuery = false;
    CharacterDatabase.statements.clear();
    cache.identities = {{10, {"Alice"}}, {20, {"Bob"}}, {30, {"Carol"}}};
    announcedDraws = 0;
    published.clear(); chat.messages.clear(); advertiser = Advertiser{};
    if (running)
    {
        round = NewRound(1);
        store.active = round;
        store.rounds[1] = round;
    }
}
void Buy(uint32 guid, uint32 tickets)
{
    uint32 contribution = Contribution(tickets, round.contribution);
    store.entries[{round.id, guid}] = {tickets, tickets * TicketCost, contribution};
    round.entries[guid] = tickets; round.totalTickets += tickets; round.pot += contribution;
    store.active->pot = round.pot;
}
void InitializationTests()
{
    Reset(); Buy(10, 200); Buy(20, 300);
    uint32 pot = round.pot;
    CharacterDatabase.failEntriesQuery = true;
    Initialize();
    Require(!ready && !storageReady, "failed ticket load enabled lottery storage or sales");
    Require(!DrawIfDue() && store.mails.empty() && store.winners.empty(), "failed ticket load allowed a draw");
    Require(!LotteryCommands::HandleStop(&chat) && store.active && store.entries.size() == 2,
        "failed ticket load allowed stop to bypass refunds");
    CharacterDatabase.failEntriesQuery = false;
    Require(LotteryCommands::HandleInfo(&chat, {}) && ready && storageReady,
        "lottery did not recover after ticket query became available");
    Require(round.entries.at(10) == 200 && round.entries.at(20) == 300 && round.totalTickets == 500 && round.pot == pot,
        "recovery lost ticket counts or changed the pot");
    Reset();
    Initialize();
    Require(ready && storageReady && round.totalTickets == 0 && round.entries.empty(),
        "empty sentinel result must still initialize a valid round");
}
void RefundTests()
{
    Reset(); Buy(10, 2); Buy(20, 3);
    Require(LotteryCommands::HandleRefund(&chat, "Alice"), "character refund failed");
    Require(published == std::vector<std::pair<uint32, uint32>>{{10, 200000}}, "refund must return full purchase cost");
    Require(round.pot == 10000000 + 75000 && round.fakeTickets == 100 && round.totalTickets == 3,
        "refund must remove only paid contribution/tickets");
    Require(LotteryCommands::HandleRefund(&chat, "Alice") && published.size() == 1, "duplicate refund");
    Require(LotteryCommands::HandleRefund(&chat, "*") && round.pot == 10000000 && round.totalTickets == 0,
        "all refund changed house gold");
    Reset(); Buy(10, 2);
    CharacterDatabase.failCommit = true;
    Require(!LotteryCommands::HandleRefund(&chat, "*") && published.empty() && round.totalTickets == 2 &&
        store.entries.size() == 1 && store.mails.empty(), "refund must roll back entirely");
    Reset(); Buy(10, 2); Buy(20, 1); cache.identities[20].deleted = true;
    Require(LotteryCommands::HandleRefund(&chat, "*") && published.size() == 1 && store.entries.empty(),
        "deleted refund recipient not skipped safely");
    Require(chat.Contains("skipped 1"), "deleted recipient refund not reported");
}
void PauseTests()
{
    Reset(); mockNow += 3600;
    uint64 left = Remaining();
    Require(LotteryCommands::HandleDisable(&chat) && round.paused && !advertiser.visible, "disable must pause and hide");
    mockNow += 999999;
    Require(Remaining() == left && !DrawIfDue(), "disabled countdown advanced or drew");
    settings.enabled = true;
    Initialize();
    Require(!settings.enabled && round.paused && Remaining() == left, "pause did not survive process restart");
    Require(LotteryCommands::HandleDisable(&chat) && Remaining() == left, "repeated disable changed remaining time");
    Require(LotteryCommands::HandleEnable(&chat) && advertiser.visible && round.ends == mockNow + left,
        "enable did not restore frozen countdown");
    auto end = round.ends;
    mockNow += 60;
    Require(LotteryCommands::HandleEnable(&chat) && round.ends == end, "repeated enable extended round");
    CharacterDatabase.failCommit = true;
    Require(!LotteryCommands::HandleDisable(&chat) && settings.enabled && !round.paused, "failed disable changed state");
}
void LifecycleTests()
{
    Reset(); Buy(10, 2);
    Require(!LotteryCommands::HandleStart(&chat, {}, {}, {}), "start accepted active round");
    LotteryCommands::HandleDisable(&chat);
    Require(!LotteryCommands::HandleStart(&chat, {}, {}, {}), "start accepted paused round");
    Require(LotteryCommands::HandleStop(&chat) && !ready && !settings.enabled && !store.active && !advertiser.visible,
        "stop failed");
    settings.enabled = true; Initialize();
    Require(!ready && !settings.enabled && !store.active, "stopped round auto started on restart");
    Require(LotteryCommands::HandleStart(&chat, std::string("2h"), 7, 0) && round.duration == 7200 &&
        round.fakeTickets == 7 && round.bonusItem == 0 && round.pot == 700000, "explicit start terms wrong");
    Buy(10, 1);
    auto old = round.id;
    CharacterDatabase.failCommit = true;
    auto mails = store.mails.size();
    Require(!LotteryCommands::HandleRestart(&chat) && round.id == old && store.mails.size() == mails && ready,
        "failed restart was not atomic");
    CharacterDatabase.failCommit = false;
    Require(LotteryCommands::HandleRestart(&chat) && round.id > old && round.duration == settings.duration &&
        round.fakeTickets == settings.fakeTickets && round.bonusItem == 97393 && settings.enabled,
        "restart did not use config");
    Require(LotteryCommands::HandleStop(&chat) && LotteryCommands::HandleEnable(&chat) && ready,
        "enable stopped lottery failed");
    Reset(); LotteryCommands::HandleStop(&chat);
    Require(!LotteryCommands::HandleStart(&chat, std::string("-2h"), {}, {}) && !ready, "negative duration accepted");
    Require(!LotteryCommands::HandleStart(&chat, std::string("59"), {}, {}) && !ready, "short duration accepted");
    Require(!LotteryCommands::HandleStart(&chat, std::string("366d"), {}, {}) && !ready, "excess duration accepted");
    Require(!LotteryCommands::HandleStart(&chat, {}, MaximumTickets + 1, {}) && !ready, "excess house count accepted");
    Require(!LotteryCommands::HandleStart(&chat, {}, {}, 999) && !ready, "missing bonus accepted");
    Require(LotteryCommands::HandleStart(&chat, {}, {}, {}) && round.duration == 604800 && round.bonusItem == 97393,
        "default start terms wrong");
}
void AutomaticDrawTests()
{
    Reset(); Buy(10, 2);
    round.fakeTickets = 0;
    store.active->fakeTickets = 0;
    uint32 pot = round.pot;
    LotteryWorld world;
    mockNow = round.ends - 1;
    world.OnUpdate(50);
    Require(store.winners.empty() && published.empty(), "world tick drew before the deadline");
    ++mockNow;
    world.OnUpdate(50);
    Require(round.id == 2 && store.winners.at(1)[2].number == 10 && announcedDraws == 1 &&
        published == std::vector<std::pair<uint32, uint32>>{{10, pot}},
        "world tick must draw and mail the prize without gossip interaction");
    world.OnUpdate(50);
    Require(store.winners.size() == 1 && published.size() == 1, "world tick paid the same round twice");
}
void DrawTests()
{
    Reset(); Buy(10, 2);
    uint32 pot = round.pot;
    Require(LotteryCommands::HandleDraw(&chat, std::string("Alice")), "forced entrant draw failed");
    auto history = store.winners.at(1);
    Require(history[2].number == 10 && history[5].number == pot && history[8].number == 2 &&
        history[13].number == 1 && history[14].number == 0, "forced entrant history/payout wrong");
    Require(published == std::vector<std::pair<uint32, uint32>>{{10, pot}} && round.id == 2, "payout/new round wrong");
    Require(announcedDraws == 1, "draw result was not announced immediately");
    Reset(); LotteryCommands::HandleDisable(&chat); pot = round.pot;
    Require(LotteryCommands::HandleDraw(&chat, std::string("Carol")), "paused non-entrant draw failed");
    history = store.winners.at(1);
    Require(history[5].number == pot + TicketCost && history[8].number == 1 && history[9].number == 101 &&
        history[13].number == 1 && history[14].number == 1 && settings.enabled && !round.paused,
        "complimentary draw/history/next state wrong");
    auto entry = store.entries.at({1, 30});
    Require(entry.tickets == 1 && entry.spent == 0 && entry.contribution == TicketCost,
        "complimentary entry not persisted as free/full contribution");
    Reset(); CharacterDatabase.failCommit = true;
    Require(!LotteryCommands::HandleDraw(&chat, std::string("Carol")) && store.winners.empty() && store.mails.empty() &&
        store.entries.empty() && round.totalTickets == 0 && round.pot == 10000000 && announcedDraws == 0,
        "forced draw rollback announced or paid a winner");
    Reset(); round.pot = MaximumPot; store.active->pot = MaximumPot;
    Require(!LotteryCommands::HandleDraw(&chat, std::string("Carol")) && store.winners.empty(), "forced pot overflow accepted");
    Reset(); cache.identities[30].deleted = true;
    Require(!LotteryCommands::HandleDraw(&chat, std::string("Carol")) && store.winners.empty(), "deleted forced winner accepted");
    Reset(); round.fakeTickets = 0; store.active->fakeTickets = 0;
    Require(!LotteryCommands::HandleDraw(&chat, {}) && ready && round.id == 1, "empty manual draw silently extended");
    Reset();
    Require(LotteryCommands::HandleDraw(&chat, {}) && store.winners.at(1)[11].number == 1 && store.mails.empty(),
        "manual house draw failed");
}
void InfoTests()
{
    Reset(); Buy(10, 2); Buy(20, 5);
    Require(LotteryCommands::HandleInfo(&chat, {}) && chat.Contains("1. Bob: 5 tickets") && chat.Contains("2. Alice: 2 tickets"),
        "info is not sorted");
    Require(LotteryCommands::HandleInfo(&chat, std::string("Carol")) && chat.Contains("Carol has 0 tickets"), "zero entry info wrong");
    for (uint32 guid = 40; guid < 55; ++guid)
    {
        cache.identities[guid] = {"Guest" + std::to_string(guid)};
        Buy(guid, guid);
    }
    chat.messages.clear(); LotteryCommands::HandleInfo(&chat, {});
    Require(chat.messages.size() == 12 && chat.Contains("1. Guest54") && chat.Contains("10. Guest45"), "top10 not bounded/sorted");
    chat.messages.clear(); Require(LotteryCommands::HandleHelp(&chat) && chat.messages.size() == 7, "missing help text");
    Require(LotteryCommands::HandleAdvertise(&chat), "manual advertisement failed");
    settings.advertise = false;
    Require(LotteryCommands::HandleAdvertise(&chat), "manual advertisement obeyed automatic mute");
    LotteryCommands::HandleDisable(&chat);
    Require(!LotteryCommands::HandleAdvertise(&chat), "disabled lottery advertised");
    LotteryCommands commands;
    auto registered = commands.GetCommands();
    Require(registered.size() == 1 && registered[0].children && registered[0].children->size() == 10,
        "command registration missing");
    for (auto const& command : *registered[0].children)
        Require(command.permission == SEC_GAMEMASTER, "GM command permission wrong");
}
}
int main()
{
    InitializationTests(); RefundTests(); PauseTests(); LifecycleTests(); AutomaticDrawTests(); DrawTests(); InfoTests();
}
