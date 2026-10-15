/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionItemLadder.h"
#include <algorithm>
#include <cstring>

namespace ItemLadder
{
namespace
{
template <typename T>
T Field(uint8 const* record, uint32 index)
{
    T value;
    std::memcpy(&value, record + index * sizeof(uint32), sizeof(T));
    return value;
}

constexpr uint32 StatsField = 3;
constexpr uint32 DamageField = 23;
constexpr uint32 ArmorField = 27;
constexpr uint32 ResistancesField = 29;
constexpr uint32 BlockField = 35;
}

Row ParseRecord(uint8 const* record)
{
    Row row;
    row.ItemId = Field<uint32>(record, 1);
    row.Level = Field<uint32>(record, 2);
    for (uint32 i = 0; i < MAX_ITEM_PROTO_STATS; ++i)
    {
        row.Stats[i].ItemStatType = Field<uint32>(record, StatsField + 2 * i);
        row.Stats[i].ItemStatValue = Field<int32>(record, StatsField + 2 * i + 1);
    }
    for (uint32 i = 0; i < MAX_ITEM_PROTO_DAMAGES; ++i)
    {
        row.DamageMin[i] = Field<float>(record, DamageField + 2 * i);
        row.DamageMax[i] = Field<float>(record, DamageField + 2 * i + 1);
    }
    row.Armor = Field<uint32>(record, ArmorField);
    row.ArmorReborn = Field<uint32>(record, ArmorField + 1);
    for (uint32 i = 0; i < ResistanceCount; ++i)
        row.Resistances[i] = Field<int32>(record, ResistancesField + i);
    row.Block = Field<uint32>(record, BlockField);
    row.RandomProperty = Field<uint32>(record, BlockField + 1);
    row.RequiredLevel = Field<uint32>(record, BlockField + 2);
    row.SellPrice = Field<uint32>(record, BlockField + 3);
    return row;
}

Ladder::Ladder(std::vector<Row> rows, ItemTemplate const* authored)
{
    std::erase_if(rows, [](Row const& row) { return row.Level < 1 || row.Level > MaxLevel; });
    std::stable_sort(rows.begin(), rows.end(), [](Row const& a, Row const& b) { return a.Level < b.Level; });
    rows.erase(std::unique(rows.begin(), rows.end(), [](Row const& a, Row const& b) { return a.Level == b.Level; }),
        rows.end());
    _rows = std::move(rows);

    Row const* authoredRow = authored ? At(authored->ItemLevel) : nullptr;
    if (authoredRow && authored->Armor == authoredRow->ArmorReborn && authored->Armor != authoredRow->Armor)
        for (Row& row : _rows)
            row.Armor = row.ArmorReborn;
}

Row const* Ladder::At(uint32 level) const
{
    if (_rows.empty())
        return nullptr;

    uint32 const clamped = std::clamp(level, _rows.front().Level, _rows.back().Level);
    auto const above = std::upper_bound(_rows.begin(), _rows.end(), clamped,
        [](uint32 value, Row const& row) { return value < row.Level; });
    return &*std::prev(above);
}

bool ScalableItem(ItemTemplate const& proto)
{
    return (proto.Class == ITEM_CLASS_WEAPON || proto.Class == ITEM_CLASS_ARMOR) &&
        proto.Quality != ITEM_QUALITY_HEIRLOOM && !proto.ScalingStatDistribution;
}

uint8 DropLevel(uint8 looterLevel, int32 offset)
{
    return uint8(std::clamp<int32>(int32(looterLevel) + offset, 1, MaxLevel));
}

uint32 DropBase(uint8 looterLevel, int32 offset)
{
    return uint32(std::clamp<int32>(int32(looterLevel) + offset, 1, 255));
}

uint8 ClampLevel(uint32 key)
{
    return uint8(std::clamp<uint32>(key, 1, MaxLevel));
}

uint32 ClientKey(uint32 level)
{
    static constexpr std::array<uint8, 20> AboveSixty = { 25, 26, 28, 30, 31, 32, 32, 33, 34, 35,
                                                          35, 35, 35, 35, 35, 35, 35, 35, 35, 35 };
    if (level <= 20)
        return level + 2;
    if (level <= 30)
        return level + 3;
    if (level <= 50)
        return level + 4;
    if (level <= 60)
        return level + 5;
    if (level <= 80)
        return level + AboveSixty[level - 61];
    return level + 5;
}

uint32 ClientBaseForKey(uint32 key)
{
    uint32 below = 0;
    for (uint32 level = 1; level <= 80; ++level)
    {
        uint32 const levelKey = ClientKey(level);
        if (levelKey == key)
            return level;
        if (levelKey < key)
            below = level;
    }
    return below;
}

Row StockRow(ItemTemplate const& proto)
{
    Row row;
    row.ItemId = proto.ItemId;
    row.Level = proto.ItemLevel;
    for (uint32 i = 0; i < MAX_ITEM_PROTO_STATS; ++i)
        row.Stats[i] = proto.ItemStat[i];
    for (uint32 i = 0; i < MAX_ITEM_PROTO_DAMAGES; ++i)
    {
        row.DamageMin[i] = proto.Damage[i].DamageMin;
        row.DamageMax[i] = proto.Damage[i].DamageMax;
    }
    row.Armor = proto.Armor;
    row.ArmorReborn = proto.Armor;
    row.Resistances = { proto.HolyRes, proto.FireRes, proto.NatureRes, proto.FrostRes, proto.ShadowRes,
        proto.ArcaneRes };
    row.Block = proto.Block;
    row.RandomProperty = uint32(proto.RandomProperty);
    row.RequiredLevel = proto.RequiredLevel;
    row.SellPrice = proto.SellPrice;
    return row;
}

void ApplyRow(ItemTemplate& proto, Row const& row)
{
    proto.StatsCount = 0;
    for (_ItemStat& stat : proto.ItemStat)
        stat = {};
    for (_ItemStat const& stat : row.Stats)
        if (stat.ItemStatType || stat.ItemStatValue)
            proto.ItemStat[proto.StatsCount++] = stat;

    proto.ScalingStatDistribution = 0;
    proto.ScalingStatValue = 0;
    for (uint32 i = 0; i < MAX_ITEM_PROTO_DAMAGES; ++i)
    {
        proto.Damage[i].DamageMin = row.DamageMin[i];
        proto.Damage[i].DamageMax = row.DamageMax[i];
    }
    proto.Armor = row.Armor;
    proto.HolyRes = row.Resistances[0];
    proto.FireRes = row.Resistances[1];
    proto.NatureRes = row.Resistances[2];
    proto.FrostRes = row.Resistances[3];
    proto.ShadowRes = row.Resistances[4];
    proto.ArcaneRes = row.Resistances[5];
    proto.Block = row.Block;
    proto.RequiredLevel = row.RequiredLevel;
    proto.SellPrice = row.SellPrice;
}

WorldPacket BuildItemStatResponse(uint32 itemId, uint32 level, Row const& row, ItemTemplate const* proto)
{
    WorldPacket data(ItemStatResponseOpcode, ItemStatResponseSize);
    data << itemId << level << itemId << level;
    for (_ItemStat const& stat : row.Stats)
        data << stat.ItemStatType << stat.ItemStatValue;
    for (uint32 i = 0; i < MAX_ITEM_PROTO_DAMAGES; ++i)
        data << row.DamageMin[i] << row.DamageMax[i] << uint32(proto ? proto->Damage[i].DamageType : 0);
    data << row.Armor << row.Armor;
    for (int32 resistance : row.Resistances)
        data << resistance;
    data << row.Block << row.RandomProperty << row.RequiredLevel << row.SellPrice;
    return data;
}

WorldPacket BuildLevelAddon(ObjectGuid guid, uint32 level)
{
    WorldPacket data(UpdateObjectAddonOpcode, 16);
    data << guid << LevelAddonField << level;
    return data;
}

WorldPacket BuildPreviewAddon(ObjectGuid playerGuid)
{
    WorldPacket data(UpdateObjectAddonOpcode, 16);
    data << playerGuid << PreviewAddonField << uint32(1);
    return data;
}

WorldPacket BuildRollLevel(uint32 level)
{
    WorldPacket data(RollLevelOpcode, 4);
    data << level;
    return data;
}

WorldPacket BuildInspectLevels(std::array<uint32, InspectSlots> const& levels)
{
    WorldPacket data(InspectLevelsOpcode, 4 * InspectSlots);
    for (uint32 level : levels)
        data << level;
    return data;
}
}
