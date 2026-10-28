#include "AscensionItemPowerTable.h"
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

namespace
{
int failures = 0;

void Expect(bool condition, char const* what)
{
    if (!condition)
    {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

struct Row
{
    std::uint32_t item;
    std::uint32_t pve;
    std::uint32_t pvp;
};

std::filesystem::path Write(char const* name, std::vector<Row> const& rows,
    std::uint32_t magic = ItemAddonFile::Magic, std::uint32_t declaredRows = 0)
{
    std::filesystem::path const path = std::filesystem::temp_directory_path() / name;
    std::ofstream file(path, std::ios::binary);
    std::uint32_t const header[5] = { magic, declaredRows ? declaredRows : std::uint32_t(rows.size()),
        ItemAddonFile::Fields, ItemAddonFile::RecordSize, 0 };
    file.write(reinterpret_cast<char const*>(header), sizeof(header));
    for (Row const& row : rows)
    {
        std::uint32_t record[ItemAddonFile::Fields] = {};
        record[ItemAddonFile::EntryField] = row.item;
        record[ItemAddonFile::PveField] = row.pve;
        record[ItemAddonFile::PvpField] = row.pvp;
        file.write(reinterpret_cast<char const*>(record), sizeof(record));
    }
    return path;
}
}

int main()
{
    using ItemPowerTable::Table;

    auto const good = Write("coa-item-power-good.dbc", {
        { 100077, 0, 36 },
        { 35599, 25, 0 },
        { 14, 0, 80010 },
        { 7, 0, 0 },
        { 5000, 38, 42 },
        { 5000, 99, 99 },
        { 100079, 0, ItemPowerTable::MaxAuthored },
        { 100081, ItemPowerTable::MaxAuthored + 1, 0 },
    });

    Table table;
    Expect(table.Load(good), "a well-formed ItemAddon table loads");
    Expect(table.Pvp(100077) == 36 && table.Pve(100077) == 0, "a PvP-only item reads its PvP Power");
    Expect(table.Pve(35599) == 25 && table.Pvp(35599) == 0, "a PvE-only item reads its PvE Power");
    Expect(table.Pve(5000) == 38 && table.Pvp(5000) == 42, "the first record of a duplicated item wins");
    Expect(table.Pvp(14) == 0, "a value above the cap is not power");
    Expect(table.Pvp(100079) == ItemPowerTable::MaxAuthored, "the largest accepted value is kept");
    Expect(table.Pve(100081) == 0, "a value just above the largest accepted one is dropped");
    Expect(table.Pve(7) == 0 && table.Pvp(7) == 0, "an item with neither power reads zero");
    Expect(table.Pve(123456) == 0 && table.Pvp(123456) == 0, "an item without a record reads zero");
    Expect(table.Size() == 4, "only items with power are stored");

    Table untouched;
    Expect(!untouched.Load(Write("coa-item-power-magic.dbc", { { 1, 1, 1 } }, 0x12345678)),
        "a file with another magic is rejected");
    Expect(untouched.Size() == 0, "a rejected file leaves the table empty");
    Expect(!untouched.Load(Write("coa-item-power-short.dbc", { { 1, 1, 1 } }, ItemAddonFile::Magic, 2)),
        "a file shorter than its header declares is rejected");
    Expect(!untouched.Load("coa-item-power-missing.dbc"), "a missing file is rejected");

    Table reloaded;
    Expect(reloaded.Load(good) && reloaded.Load(Write("coa-item-power-one.dbc", { { 9, 1, 2 } })) &&
        reloaded.Size() == 1 && reloaded.Pve(100077) == 0, "a second load replaces the first");

    if (failures)
        return 1;
    std::cout << "ItemAddon power table loading, cap and lookup checks passed\n";
    return 0;
}
