#ifndef COA_ASCENSION_ITEM_STAT_DATA_H
#define COA_ASCENSION_ITEM_STAT_DATA_H

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstdint>
#include <istream>
#include <string>
#include <vector>

namespace ItemScaling::CapturedStats
{
constexpr std::uint16_t QueryOpcode = 0x06FF;
constexpr std::uint16_t ResponseOpcode = 0x0700;
constexpr std::size_t FieldCount = 39;
constexpr std::size_t RecordBytes = FieldCount * sizeof(std::uint32_t);
constexpr std::size_t ResponseWords = 42;
constexpr std::uint32_t MaximumRecords = 2000000;
constexpr std::uint32_t MaximumScalingLevel = 300;
constexpr std::uint32_t MaximumStatType = 48;

enum Field : std::size_t
{
    Id = 0,
    Item = 1,
    Level = 2,
    StatPairs = 3,
    Damage = 23,
    Armor = 27,
    ArmorReborn = 28,
    Resistances = 29,
    Block = 35,
    RandomProperty = 36,
    RequiredLevel = 37,
    SellPrice = 38
};

struct Record
{
    std::array<std::uint32_t, FieldCount> words{};

    std::uint64_t Key() const
    {
        return std::uint64_t(words[Level]) << 32 | words[Item];
    }

    bool Valid() const
    {
        if (!words[Item] || !words[Level] || words[Level] > MaximumScalingLevel)
            return false;
        for (std::size_t index = 0; index < 10; ++index)
            if (words[StatPairs + index * 2] > MaximumStatType)
                return false;
        for (std::size_t index = 0; index < 4; ++index)
        {
            float const damage = std::bit_cast<float>(words[Damage + index]);
            if (!std::isfinite(damage) || damage < 0.0f)
                return false;
        }
        return true;
    }

    template <class Template>
    void Apply(Template& proto) const
    {
        proto.ItemLevel = words[Level];
        proto.StatsCount = 0;
        for (std::size_t index = 0; index < 10; ++index)
        {
            auto& stat = proto.ItemStat[index];
            stat.ItemStatType = words[StatPairs + index * 2];
            stat.ItemStatValue = std::bit_cast<std::int32_t>(words[StatPairs + index * 2 + 1]);
            if (stat.ItemStatType || stat.ItemStatValue)
                proto.StatsCount = std::uint32_t(index + 1);
        }
        for (std::size_t index = 0; index < 2; ++index)
        {
            proto.Damage[index].DamageMin = std::bit_cast<float>(words[Damage + index * 2]);
            proto.Damage[index].DamageMax = std::bit_cast<float>(words[Damage + index * 2 + 1]);
        }
        proto.Armor = words[Armor];
        std::array<std::int32_t*, 6> const resistances = { &proto.HolyRes, &proto.FireRes, &proto.NatureRes,
            &proto.FrostRes, &proto.ShadowRes, &proto.ArcaneRes };
        for (std::size_t index = 0; index < resistances.size(); ++index)
            *resistances[index] = std::bit_cast<std::int32_t>(words[Resistances + index]);
        proto.Block = words[Block];
        proto.RandomProperty = std::bit_cast<std::int32_t>(words[RandomProperty]);
        proto.RequiredLevel = words[RequiredLevel];
        proto.SellPrice = words[SellPrice];
    }

    std::array<std::uint32_t, ResponseWords> Response(std::uint32_t item,
        std::array<std::uint32_t, 2> const& damageTypes) const
    {
        std::array<std::uint32_t, ResponseWords> response{};
        response[0] = item;
        response[1] = words[Level];
        response[2] = words[Item];
        response[3] = words[Level];
        std::copy_n(words.begin() + StatPairs, 20, response.begin() + 4);
        for (std::size_t index = 0; index < 2; ++index)
        {
            response[24 + index * 3] = words[Damage + index * 2];
            response[25 + index * 3] = words[Damage + index * 2 + 1];
            response[26 + index * 3] = damageTypes[index];
        }
        std::copy(words.begin() + Armor, words.end(), response.begin() + 30);
        return response;
    }
};

class Table
{
public:
    bool Load(std::istream& source, std::string& error)
    {
        error.clear();
        std::array<unsigned char, 20> header{};
        if (!source.read(reinterpret_cast<char*>(header.data()), header.size()))
        {
            error = "truncated WDBC header";
            return false;
        }
        std::uint32_t const count = ReadWord(header.data() + 4);
        if (std::string(header.begin(), header.begin() + 4) != "WDBC" || !count || count > MaximumRecords ||
            ReadWord(header.data() + 8) != FieldCount || ReadWord(header.data() + 12) != RecordBytes ||
            ReadWord(header.data() + 16) != 0)
        {
            error = "expected numeric ItemStat WDBC with 39 fields and 156-byte rows";
            return false;
        }
        std::vector<Record> rows;
        rows.reserve(count);
        std::size_t invalidRows = 0;
        std::array<unsigned char, RecordBytes> bytes{};
        for (std::uint32_t index = 0; index < count; ++index)
        {
            if (!source.read(reinterpret_cast<char*>(bytes.data()), bytes.size()))
            {
                error = "truncated ItemStat record";
                return false;
            }
            Record row;
            for (std::size_t column = 0; column < FieldCount; ++column)
                row.words[column] = ReadWord(bytes.data() + column * sizeof(std::uint32_t));
            if (!row.Valid())
            {
                ++invalidRows;
                continue;
            }
            rows.push_back(row);
        }
        if (source.peek() != std::char_traits<char>::eof() || source.bad())
        {
            error = "unexpected data after ItemStat records";
            return false;
        }
        if (rows.empty())
        {
            error = "no valid ItemStat records";
            return false;
        }
        std::stable_sort(rows.begin(), rows.end(), [](Record const& a, Record const& b) { return a.Key() < b.Key(); });
        auto const end = std::unique(rows.begin(), rows.end(),
            [](Record const& a, Record const& b) { return a.Key() == b.Key(); });
        std::size_t const duplicateRows = std::size_t(rows.end() - end);
        rows.erase(end, rows.end());
        _rows.swap(rows);
        _invalidRows = invalidRows;
        _duplicateRows = duplicateRows;
        return true;
    }

    Record const* Find(std::uint32_t item, std::uint32_t level) const
    {
        std::uint64_t const key = std::uint64_t(level) << 32 | item;
        auto const row = std::lower_bound(_rows.begin(), _rows.end(), key,
            [](Record const& record, std::uint64_t value) { return record.Key() < value; });
        return row != _rows.end() && row->Key() == key ? &*row : nullptr;
    }

    std::size_t Size() const
    {
        return _rows.size();
    }

    std::size_t InvalidRows() const
    {
        return _invalidRows;
    }

    std::size_t DuplicateRows() const
    {
        return _duplicateRows;
    }

private:
    static std::uint32_t ReadWord(unsigned char const* bytes)
    {
        return std::uint32_t(bytes[0]) | std::uint32_t(bytes[1]) << 8 | std::uint32_t(bytes[2]) << 16 |
            std::uint32_t(bytes[3]) << 24;
    }

    std::vector<Record> _rows;
    std::size_t _invalidRows = 0;
    std::size_t _duplicateRows = 0;
};
}

#endif
