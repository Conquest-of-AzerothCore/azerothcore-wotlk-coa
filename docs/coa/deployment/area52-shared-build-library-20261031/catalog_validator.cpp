#include "Area52BuildSelection.h"
#include "AscensionMysticEnchantCatalog.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include <charconv>
#include <iostream>

int main(int argc, char** argv)
{
    if (argc != 2)
        return 2;
    DbcDirectory = std::string(argv[1]) + "/";
    AscensionFreePick::Catalog catalog;
    AscensionMysticEnchant::Catalog enchants;
    ClientDBC spells;
    if (!AscensionFreePick::LoadCatalog(catalog)
        || !AscensionMysticEnchant::LoadCatalog(enchants, GetClientDBCPath("MysticEnchant.dbc"))
        || !spells.Load(GetClientDBCPath("Spell.dbc"), 234) || spells.GetRecordSize() != 936)
        return 3;
    std::map<std::uint32_t, std::uint32_t> limits;
    for (std::uint32_t i = 0; i < spells.GetRecordCount(); ++i)
    {
        auto const row = spells.GetRecord(i);
        limits[row.GetUInt32(0)] = std::max(1u, row.GetUInt32(49));
    }
    std::string line;
    while (std::getline(std::cin, line))
    {
        if (line == "CATALOG")
        {
            for (auto const& [id, entry] : catalog.Entries)
                for (auto spell : entry.Spells)
                    std::cout << "S " << spell << '\n';
            for (auto const& [spell, entry] : enchants.BySpell)
                if (limits.contains(spell) && entry.Quality >= 2 && entry.Quality <= 5)
                    std::cout << "E " << spell << '\n';
            std::cout << "END\n";
            continue;
        }
        bool valid = line.size() % 2 == 0 && line.size() <= Area52Build::MaxPacketBytes * 2;
        std::vector<std::uint8_t> bytes;
        for (std::size_t i = 0; valid && i < line.size(); i += 2)
        {
            unsigned value = 0;
            auto result = std::from_chars(line.data() + i, line.data() + i + 2, value, 16);
            valid = result.ec == std::errc{} && result.ptr == line.data() + i + 2;
            bytes.push_back(std::uint8_t(value));
        }
        Area52Build::Entry plan;
        valid = valid && Area52Build::Decode(bytes, plan) && !plan.Spells.empty();
        std::string reason = "invalid build data";
        std::vector<AscensionFreePick::KnownEntry> selected;
        for (std::uint32_t level = 1; valid && level <= 80; ++level)
        {
            auto result = Area52Build::Select(catalog, plan, level, selected);
            if (!result)
            {
                valid = false;
                reason = std::string(result.Learn) + " at level " + std::to_string(level);
            }
            AscensionMysticEnchant::Slots slots{};
            std::set<std::uint32_t> entitlement;
            std::size_t next = 0;
            std::uint32_t worldforged = 0;
            for (auto const& enchant : plan.Enchants)
            {
                if (enchant.Level > level)
                    continue;
                if (!enchant.Stacks || enchant.Stacks > slots.size() - next)
                {
                    valid = false;
                    reason = "invalid enchant slot count";
                    break;
                }
                entitlement.insert(enchant.Id);
                for (std::uint32_t n = 0; n < enchant.Stacks; ++n)
                    slots[next++] = enchant.Id;
                auto const found = enchants.BySpell.find(enchant.Id);
                if (found != enchants.BySpell.end() && found->second.Worldforged && found->second.Quality == 3)
                    worldforged += enchant.Stacks;
            }
            if (valid && (worldforged > 3
                || !AscensionMysticEnchant::ValidateSlots(enchants, slots, level, entitlement, limits)))
            {
                valid = false;
                reason = "enchant level, quality or stack budget at level " + std::to_string(level);
            }
        }
        std::cout << (valid ? "OK" : "REJECT " + reason) << '\n';
    }
}
