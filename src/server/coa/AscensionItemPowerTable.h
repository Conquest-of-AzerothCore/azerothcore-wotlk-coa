#ifndef COA_ASCENSION_ITEM_POWER_TABLE_H
#define COA_ASCENSION_ITEM_POWER_TABLE_H

#include "AscensionItemAddonFile.h"
#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <vector>

namespace ItemPowerTable
{
constexpr std::uint32_t MaxAuthored = 1000;

struct Entry
{
    std::uint32_t item;
    std::uint32_t pve;
    std::uint32_t pvp;
};

constexpr std::uint32_t Authored(std::uint32_t value)
{
    return value <= MaxAuthored ? value : 0;
}

class Table
{
public:
    bool Load(std::filesystem::path const& path)
    {
        std::vector<Entry> entries;
        bool const scanned = ItemAddonFile::Scan(path, [&entries](std::uint8_t const* record)
        {
            Entry const entry{ ItemAddonFile::Field(record, ItemAddonFile::EntryField),
                Authored(ItemAddonFile::Field(record, ItemAddonFile::PveField)),
                Authored(ItemAddonFile::Field(record, ItemAddonFile::PvpField)) };
            if (entry.pve || entry.pvp)
                entries.push_back(entry);
        });
        if (!scanned)
            return false;

        std::stable_sort(entries.begin(), entries.end(),
            [](Entry const& a, Entry const& b) { return a.item < b.item; });
        entries.erase(std::unique(entries.begin(), entries.end(),
            [](Entry const& a, Entry const& b) { return a.item == b.item; }), entries.end());
        _entries = std::move(entries);
        return true;
    }

    std::uint32_t Pve(std::uint32_t item) const
    {
        Entry const* entry = Find(item);
        return entry ? entry->pve : 0;
    }

    std::uint32_t Pvp(std::uint32_t item) const
    {
        Entry const* entry = Find(item);
        return entry ? entry->pvp : 0;
    }

    std::size_t Size() const
    {
        return _entries.size();
    }

private:
    Entry const* Find(std::uint32_t item) const
    {
        auto const found = std::lower_bound(_entries.begin(), _entries.end(), item,
            [](Entry const& entry, std::uint32_t id) { return entry.item < id; });
        return found != _entries.end() && found->item == item ? &*found : nullptr;
    }

    std::vector<Entry> _entries;
};

inline Table& Loaded()
{
    static Table table;
    return table;
}
}

#endif
