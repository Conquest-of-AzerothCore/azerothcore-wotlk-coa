#include <array>
#include <cassert>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <vector>

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;

struct Field
{
    std::string value;

    template<class T>
    T Get() const
    {
        if constexpr (std::is_same_v<T, std::string_view>)
            return value;
        else
            return T(std::stoul(value));
    }
};

struct Result
{
    std::vector<std::array<Field, 7>> rows;
    std::size_t index = 0;
    Field* Fetch() { return rows[index].data(); }
    bool NextRow() { return ++index < rows.size(); }
};

using QueryResult = std::shared_ptr<Result>;

struct Database
{
    bool tableExists = false;
    std::vector<std::array<Field, 7>> rows;
    std::vector<std::string> queries;

    QueryResult Query(char const* sql)
    {
        queries.emplace_back(sql);
        std::string_view query(sql);
        if (query == "SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND "
            "TABLE_NAME = 'creature_display_preset_variety'")
            return tableExists ? std::make_shared<Result>() : nullptr;
        assert(query == "SELECT entry, gender, skins, faces, hair_styles, hair_colors, facial_hairs "
            "FROM creature_display_preset_variety");
        assert(tableExists);
        return rows.empty() ? nullptr : std::make_shared<Result>(Result{ rows });
    }
} WorldDatabase;

struct CreatureDisplayPresetVariety
{
    std::vector<uint8> skins, faces, hairs, hairColors, facialHairs;
};

std::vector<uint8> ParsePresetVarietyValues(std::string_view text)
{
    return { uint8(std::stoul(std::string(text))) };
}

struct AscensionCreaturePresetMgr
{
    void LoadVarietiesFromDB();
    static uint64 MakeKey(uint32 entry, uint32 gender) { return (uint64(entry) << 32) | gender; }
    std::unordered_map<uint64, CreatureDisplayPresetVariety> _varieties;
};

#define LOG_INFO(...) do { } while (false)

// ACTUAL_LOADER

int main()
{
    AscensionCreaturePresetMgr manager;
    WorldDatabase.tableExists = true;
    WorldDatabase.rows = { { Field{ "42" }, Field{ "1" }, Field{ "2" }, Field{ "3" }, Field{ "4" },
        Field{ "5" }, Field{ "6" } } };
    manager.LoadVarietiesFromDB();
    assert(WorldDatabase.queries.size() == 2);
    assert(manager._varieties.size() == 1);
    auto const& variety = manager._varieties.at(manager.MakeKey(42, 1));
    assert(variety.skins == std::vector<uint8>{ 2 });
    assert(variety.faces == std::vector<uint8>{ 3 });
    assert(variety.hairs == std::vector<uint8>{ 4 });
    assert(variety.hairColors == std::vector<uint8>{ 5 });
    assert(variety.facialHairs == std::vector<uint8>{ 6 });

    WorldDatabase.queries.clear();
    WorldDatabase.tableExists = false;
    manager.LoadVarietiesFromDB();
    assert(WorldDatabase.queries.size() == 1);
    assert(manager._varieties.empty());

    WorldDatabase.queries.clear();
    WorldDatabase.tableExists = true;
    WorldDatabase.rows.clear();
    manager.LoadVarietiesFromDB();
    assert(WorldDatabase.queries.size() == 2);
    assert(manager._varieties.empty());
}
