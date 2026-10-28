#include "AscensionItemScalingPolicy.h"
#include "AscensionItemStatData.h"
#include "ItemTemplate.h"
#include "WorldPacket.h"
#include <atomic>
#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <shared_mutex>
#include <sstream>
#include <unordered_map>
#include <unordered_set>

#define ASSERT(condition, ...) assert(condition)
#define LOG_ERROR(...) static_cast<void>(0)
#define LOG_INFO(...) static_cast<void>(0)
#define LOG_WARN(...) static_cast<void>(++warnings)

std::size_t warnings = 0;

// ACTUAL_BYTE_BUFFER

class WorldSession
{
public:
    std::vector<WorldPacket> sent;
    void SendPacket(WorldPacket const* packet) { sent.push_back(*packet); }
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
constexpr int CONFIG_MAX_PLAYER_LEVEL = 0;
struct World
{
    std::string dataPath;
    std::string const& GetDataPath() const { return dataPath; }
    uint32 getIntConfig(int) const { return 80; }
} world;
World* sWorld = &world;

struct ConfigMgr
{
    template <typename T>
    T GetOption(char const*, T fallback) const { return fallback; }
} configMgr;
ConfigMgr* sConfigMgr = &configMgr;

constexpr int WORLDHOOK_ON_AFTER_CONFIG_LOAD = 0;
constexpr int WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE = 1;
constexpr int WORLDHOOK_ON_STARTUP = 2;
struct WorldScript
{
    WorldScript(char const*, std::initializer_list<int>) { }
    virtual void OnAfterConfigLoad(bool) { }
    virtual void OnLoadCustomDatabaseTable() { }
    virtual void OnStartup() { }
};

namespace NativeItemScaling
{
std::unordered_set<uint32> handled;
bool Handles(uint32 item) { return handled.contains(item); }
}

namespace ItemScaling
{
// ACTUAL_STARTUP
using CurveKey = std::tuple<uint32, uint32, uint32, uint32>;
using CurveSet = std::map<CurveKey, LevelCurve>;
struct Curves
{
    CurveSet armor;
    CurveSet damagePerSecond;
    CurveSet block;
    CurveSet sellPrice;
    std::map<CurveKey, std::map<uint32, int32>> randomProperties;
};
uint32 PropertyPoints(uint32 level, uint32) { return level == 28 ? 100 : 220; }
CurveKey KeyOf(ItemTemplate const& proto)
{ return {proto.Class, proto.SubClass, proto.InventoryType, proto.Quality}; }
double SetRatio(CurveSet const&, CurveKey const&, uint32, uint32, double fallback) { return fallback; }
uint32 BaseEntry(uint32 item) { return item == FirstScaledEntry ? 720 : item; }

// ACTUAL_BUILD_TEMPLATE
// ACTUAL_HANDLE_QUERY

struct Registry
{
    std::size_t restorations = 0;
    static Registry& Instance() { static Registry registry; return registry; }
    void Load() { }
    void RestoreUnliftableCopies() { ++restorations; }
};

// ACTUAL_CONFIGURATION
}

namespace
{
int checks = 0, failures = 0;
void Check(bool value, char const* name)
{
    ++checks;
    failures += !value;
    std::cout << (value ? "PASS: " : "FAIL: ") << name << '\n';
}

void AppendWord(std::string& bytes, uint32 word)
{
    for (unsigned shift = 0; shift < 32; shift += 8)
        bytes.push_back(char(word >> shift));
}

std::string File(std::vector<ItemScaling::CapturedStats::Record> const& records)
{
    std::string bytes = "WDBC";
    for (uint32 word : {uint32(records.size()), uint32(39), uint32(156), uint32(0)})
        AppendWord(bytes, word);
    for (auto const& record : records)
        for (uint32 word : record.words)
            AppendWord(bytes, word);
    return bytes;
}

void TestInvalidFiles(ItemScaling::CapturedStats::Record record)
{
    using namespace ItemScaling::CapturedStats;
    std::string error;
    Table table;
    std::istringstream good(File({record}));
    Check(table.Load(good, error) && !table.InvalidRows() && !table.DuplicateRows(),
        "valid numeric DBC loads without skipped rows");
    std::vector<std::string> bad = {"", File({record}).substr(0, 19), File({record}).substr(0, 40),
        File({record}) + "extra"};
    for (std::size_t offset : {std::size_t(0), std::size_t(4), std::size_t(8), std::size_t(12), std::size_t(16)})
    {
        auto bytes = File({record});
        bytes[offset] = '\xff';
        bad.push_back(bytes);
    }
    for (auto [field, value] : std::array<std::pair<std::size_t, uint32>, 6>{{
        {Item, 0}, {Level, 0}, {Level, 301}, {StatPairs, 49}, {Damage, 0x7FC00000}, {Damage, 0xBF800000}}})
    {
        auto invalid = record;
        invalid.words[field] = value;
        bad.push_back(File({invalid}));
    }
    bool rejected = true;
    for (auto const& bytes : bad)
    {
        std::istringstream input(bytes);
        rejected &= !table.Load(input, error) && !error.empty() && table.Size() == 1 &&
            table.Find(record.words[Item], record.words[Level]);
    }
    Check(rejected, "malformed files and tables with no valid rows reject without partial publication");
    auto signedRecord = record;
    signedRecord.words[StatPairs + 1] = uint32(-1);
    signedRecord.words[RandomProperty] = uint32(-42);
    signedRecord.words[Resistances] = uint32(-3);
    ItemTemplate proto{};
    signedRecord.Apply(proto);
    Check(proto.ItemStat[0].ItemStatValue == -1 && proto.RandomProperty == -42 && proto.HolyRes == -3,
        "signed stats, random property and resistances preserve their captured bits");
}

void TestPartialFiles(ItemScaling::CapturedStats::Record record)
{
    using namespace ItemScaling::CapturedStats;
    auto other = record;
    ++other.words[Level];
    auto duplicate = record;
    duplicate.words[Id] = 0;
    duplicate.words[StatPairs + 1] = 99;
    std::vector<Record> rows{other};
    for (auto [field, value] : std::array<std::pair<std::size_t, uint32>, 6>{{
        {Item, 0}, {Level, 0}, {Level, 301}, {StatPairs, 49}, {Damage, 0x7FC00000}, {Damage, 0xBF800000}}})
    {
        auto invalid = record;
        invalid.words[field] = value;
        rows.push_back(invalid);
    }
    rows.push_back(record);
    rows.push_back(duplicate);
    Table table;
    std::string error;
    std::istringstream input(File(rows));
    Check(table.Load(input, error) && error.empty() && table.Size() == 2 &&
        table.InvalidRows() == 6 && table.DuplicateRows() == 1 &&
        table.Find(other.words[Item], other.words[Level]),
        "invalid rows and duplicate keys leave unrelated valid rows available");
    auto const* retained = table.Find(record.words[Item], record.words[Level]);
    Check(retained && retained->words == record.words, "duplicate keys retain the first valid row in file order");
    std::istringstream truncated(File(rows).substr(0, File(rows).size() - 1));
    Check(!table.Load(truncated, error) && !error.empty() && table.Size() == 2 &&
        table.InvalidRows() == 6 && table.DuplicateRows() == 1 &&
        table.Find(record.words[Item], record.words[Level]),
        "structurally truncated tables retain the previous complete table");

    auto const dataPath = world.dataPath;
    auto saved = std::move(ItemScaling::capturedStats);
    auto const partialPath = std::filesystem::path(dataPath) / "partial";
    std::filesystem::create_directories(partialPath / "dbc");
    std::ofstream output(partialPath / "dbc" / "ItemStat.dbc", std::ios::binary);
    auto const bytes = File(rows);
    output.write(bytes.data(), bytes.size());
    output.close();
    world.dataPath = partialPath.string();
    std::size_t const previousWarnings = warnings;
    ItemScaling::Configuration{}.OnLoadCustomDatabaseTable();
    Check(ItemScaling::capturedStats.Size() == 2 && warnings == previousWarnings + 1,
        "startup loads valid rows and warns once when rows are skipped");
    world.dataPath = dataPath;
    ItemScaling::capturedStats = std::move(saved);
}

void TestTemplatesAndReplies()
{
    using namespace ItemScaling;
    ItemTemplate base{};
    base.ItemId = 720;
    base.ItemLevel = 28;
    base.RequiredLevel = 23;
    base.Quality = 2;
    base.Armor = 122;
    base.BuyPrice = 12000;
    base.SellPrice = 1338;
    base.ItemStat[0] = {4, 8};
    base.ItemStat[1] = {7, 7};
    base.ItemStat[9] = {5, 100};
    base.StatsCount = 10;
    base.Damage[0].DamageType = 2;
    base.Damage[1].DamageType = 4;
    base.Delay = 2100;
    Curves curves;
    auto scaled = BuildTemplate(FirstScaledEntry, base, 30, curves);
    Check(scaled->ItemStat[0].ItemStatValue == 10 && scaled->ItemStat[1].ItemStatValue == 8 &&
        scaled->StatsCount == 2 && scaled->ItemStat[9].ItemStatValue == 0,
        "lifted Brawler Gloves use original 10 strength / 8 stamina and clear stale stat slots");
    Check(scaled->ItemId == FirstScaledEntry && scaled->ItemLevel == 58 && scaled->RequiredLevel == 53 &&
        scaled->Armor == 249 && scaled->SellPrice == 2676 && scaled->BuyPrice == 24000 && scaled->Delay == 2100,
        "captured armor, required level and sell price apply while synthetic identity and absent metadata remain");
    auto priced = base;
    priced.SellPrice = 0;
    Check(BuildTemplate(FirstScaledEntry, priced, 30, curves)->BuyPrice == 26400,
        "zero base sell price uses the existing estimated buy-price scaling");
    priced.SellPrice = 10704;
    priced.BuyPrice = 11;
    Check(BuildTemplate(FirstScaledEntry, priced, 30, curves)->BuyPrice == 3,
        "captured sell-price decreases scale buy prices with rounding");
    priced.SellPrice = 1;
    priced.BuyPrice = INT32_MAX;
    Check(BuildTemplate(FirstScaledEntry, priced, 30, curves)->BuyPrice == INT32_MAX,
        "captured buy-price scaling saturates at the signed item-template limit");
    for (int32 buyPrice : {0, -1})
    {
        priced.BuyPrice = buyPrice;
        Check(BuildTemplate(FirstScaledEntry, priced, 30, curves)->BuyPrice == buyPrice,
            "nonpositive base buy prices retain their sentinel values");
    }
    {
        auto free = *capturedStats.Find(720, 58);
        free.words[CapturedStats::SellPrice] = 0;
        auto savedPrices = std::move(capturedStats);
        std::string error;
        std::istringstream input(File({free}));
        Check(capturedStats.Load(input, error) &&
            BuildTemplate(FirstScaledEntry, base, 30, curves)->BuyPrice == 0,
            "zero captured sell price scales a positive buy price to zero");
        capturedStats = std::move(savedPrices);
    }
    objectMgr.items[720] = base;
    objectMgr.items[FirstScaledEntry] = *scaled;
    WorldSession session;
    WorldPacket query(CapturedStats::QueryOpcode, 8);
    query << uint32(FirstScaledEntry) << uint32(58);
    HandleStatQuery(&session, query);
    Check(session.sent.size() == 1 && session.sent[0].GetOpcode() == 0x0700 && session.sent[0].size() == 168,
        "native item-stat query returns one 168-byte SMSG 0x700");
    if (!session.sent.empty())
    {
        auto const& response = session.sent[0];
        Check(response.read<uint32>(0) == FirstScaledEntry && response.read<uint32>(4) == 58 &&
            response.read<uint32>(8) == 720 && response.read<uint32>(12) == 58 &&
            response.read<int32>(0x14) == 10 && response.read<int32>(0x1C) == 8 &&
            response.read<uint32>(0x78) == 249 && response.read<uint32>(0x7C) == 82 &&
            response.read<uint32>(0xA0) == 53 && response.read<uint32>(0xA4) == 2676 &&
            response.read<uint32>(0x68) == 2 && response.read<uint32>(0x74) == 4,
            "reply key matches the requested synthetic item; stat and reborn-armor offsets match the native client");
    }
    std::size_t const count = session.sent.size();
    HandleStatQuery(nullptr, query);
    HandleStatQuery(&session, WorldPacket(CapturedStats::QueryOpcode, 0));
    WorldPacket tooLong(query);
    tooLong << uint32(0);
    HandleStatQuery(&session, tooLong);
    WorldPacket missing(CapturedStats::QueryOpcode, 8);
    missing << uint32(720) << uint32(777);
    HandleStatQuery(&session, missing);
    WorldPacket unknown(CapturedStats::QueryOpcode, 8);
    unknown << uint32(999) << uint32(58);
    HandleStatQuery(&session, unknown);
    Check(session.sent.size() == count, "null sessions, malformed queries and uncaptured keys send no fabricated rows");
    NativeItemScaling::handled.insert(FirstScaledEntry);
    HandleStatQuery(&session, query);
    Check(session.sent.size() == count, "items answered by native item scaling get no captured reply");
    NativeItemScaling::handled.clear();
    auto const* weapon = capturedStats.Find(753, 58);
    ItemTemplate sword{};
    weapon->Apply(sword);
    Check(sword.Damage[0].DamageMin == 46.0f && sword.Damage[0].DamageMax == 74.0f &&
        sword.ItemStat[0].ItemStatValue == 8, "captured weapon damage and stamina retain the original row");
    auto saved = std::move(capturedStats);
    capturedStats = CapturedStats::Table{};
    auto const dataPath = world.dataPath;
    world.dataPath += "/missing";
    Configuration{}.OnLoadCustomDatabaseTable();
    auto fallback = BuildTemplate(FirstScaledEntry, base, 30, curves);
    Check(!capturedStats.Size() && fallback->ItemStat[0].ItemStatValue == 18 &&
        fallback->ItemStat[1].ItemStatValue == 15 && fallback->SellPrice == 2944 && fallback->BuyPrice == 26400,
        "startup without ItemStat.dbc retains existing estimated scaling");
    world.dataPath = dataPath;
    capturedStats = std::move(saved);
    auto unmatched = BuildTemplate(FirstScaledEntry, base, 31, curves);
    Check(unmatched->ItemLevel == 59 && unmatched->ItemStat[0].ItemStatValue == 18,
        "uncaptured levels retain estimated scaling without nearest-row substitution");
}
}

int main(int argc, char** argv)
{
    if (argc < 2)
        return 2;
    std::string error;
    world.dataPath = std::filesystem::path(argv[1]).parent_path().parent_path().string();
    ItemScaling::Configuration startup;
    startup.OnAfterConfigLoad(false);
    startup.OnLoadCustomDatabaseTable();
    Check(ItemScaling::capturedStats.Size() == 6, "startup uses original ItemStat rows without an opt-in setting");
    startup.OnStartup();
    Check(ItemScaling::Registry::Instance().restorations == 1 && ItemScaling::capturedStats.Size() == 6,
        "startup restores unliftable copies while retaining captured item stats");
    auto const* gloves = ItemScaling::capturedStats.Find(720, 58);
    Check(gloves && ItemScaling::capturedStats.Find(720, 28) && !ItemScaling::capturedStats.Find(720, 57),
        "lookup uses the exact item and scaling level");
    if (gloves)
    {
        TestInvalidFiles(*gloves);
        TestPartialFiles(*gloves);
        TestTemplatesAndReplies();
    }
    if (argc > 2)
    {
        ItemScaling::CapturedStats::Table full;
        std::ifstream original(argv[2], std::ios::binary);
        Check(full.Load(original, error) && full.Size() > 1000000 && full.Find(720, 58),
            "complete captured ItemStat table loads with unique keys and valid numeric fields");
        std::cout << "full table: " << full.Size() << " records; " << full.InvalidRows() << " invalid, " <<
            full.DuplicateRows() << " duplicates; " << error << '\n';
    }
    std::cout << checks - failures << '/' << checks << " checks passed\n";
    return failures ? 1 : 0;
}
