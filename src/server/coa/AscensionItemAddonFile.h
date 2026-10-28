#ifndef COA_ASCENSION_ITEM_ADDON_FILE_H
#define COA_ASCENSION_ITEM_ADDON_FILE_H

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <vector>

namespace ItemAddonFile
{
constexpr std::uint32_t Magic = 0x43424457;
constexpr std::uint32_t Fields = 48;
constexpr std::uint32_t RecordSize = Fields * sizeof(std::uint32_t);
constexpr std::uint32_t ChunkRecords = 8192;
constexpr unsigned EntryField = 1;
constexpr unsigned PveField = 38;
constexpr unsigned PvpField = 39;
constexpr unsigned RebornArmorField = 43;

inline std::uint32_t Field(std::uint8_t const* record, unsigned index)
{
    std::uint32_t value;
    std::memcpy(&value, record + index * sizeof(value), sizeof(value));
    return value;
}

template <typename Visitor>
bool Scan(std::filesystem::path const& path, Visitor&& visit)
{
    std::ifstream file(path, std::ios::binary);
    std::uint32_t header[5] = {};
    if (!file || !file.read(reinterpret_cast<char*>(header), sizeof(header)) || header[0] != Magic ||
        header[2] != Fields || header[3] != RecordSize)
        return false;

    std::uint32_t const records = header[1];
    std::vector<std::uint8_t> chunk(std::size_t(ChunkRecords) * RecordSize);
    for (std::uint32_t first = 0; first < records; first += ChunkRecords)
    {
        std::uint32_t const count = std::min(ChunkRecords, records - first);
        if (!file.read(reinterpret_cast<char*>(chunk.data()), std::streamsize(count) * RecordSize))
            return false;

        for (std::uint32_t i = 0; i < count; ++i)
            visit(chunk.data() + std::size_t(i) * RecordSize);
    }
    return true;
}
}

#endif
