/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionItemLadder.h"
#include "gtest/gtest.h"
#include <array>
#include <cstring>

namespace
{
using Record = std::array<uint8, ItemLadder::RecordSize>;

template <typename T>
void Put(Record& record, uint32 field, T value)
{
    std::memcpy(record.data() + field * sizeof(uint32), &value, sizeof(T));
}

Record SampleRecord()
{
    Record record{};
    Put<uint32>(record, 0, 900001);
    Put<uint32>(record, 1, 2244);
    Put<uint32>(record, 2, 42);
    for (uint32 i = 0; i < 10; ++i)
    {
        Put<uint32>(record, 3 + 2 * i, 3 + i);
        Put<int32>(record, 4 + 2 * i, int32(10 * (i + 1)));
    }
    Put<float>(record, 23, 11.5f);
    Put<float>(record, 24, 22.5f);
    Put<float>(record, 25, 3.0f);
    Put<float>(record, 26, 6.0f);
    Put<uint32>(record, 27, 111);
    Put<uint32>(record, 28, 33);
    for (uint32 i = 0; i < 6; ++i)
        Put<int32>(record, 29 + i, int32(i + 1));
    Put<uint32>(record, 35, 44);
    Put<uint32>(record, 36, 55);
    Put<uint32>(record, 37, 37);
    Put<uint32>(record, 38, 12345);
    return record;
}

ItemLadder::Row RowAt(uint32 level, int32 firstStat)
{
    ItemLadder::Row row;
    row.ItemId = 2244;
    row.Level = level;
    row.Stats[0] = { 7, firstStat };
    return row;
}

ItemLadder::Row ArmorAt(uint32 level, uint32 armor, uint32 armorReborn)
{
    ItemLadder::Row row = RowAt(level, 0);
    row.Armor = armor;
    row.ArmorReborn = armorReborn;
    return row;
}

ItemLadder::Ladder CowlLadder(ItemTemplate const* authored)
{
    return ItemLadder::Ladder({ ArmorAt(29, 170, 61), ArmorAt(30, 174, 62), ArmorAt(60, 355, 97) }, authored);
}

ItemTemplate Authored(uint32 itemLevel, uint32 armor)
{
    ItemTemplate proto{};
    proto.ItemLevel = itemLevel;
    proto.Armor = armor;
    return proto;
}
}

TEST(AscensionItemLadder, RecordFieldsFollowTheItemStatLayout)
{
    Record const record = SampleRecord();
    ItemLadder::Row const row = ItemLadder::ParseRecord(record.data());

    EXPECT_EQ(row.ItemId, 2244u);
    EXPECT_EQ(row.Level, 42u);
    EXPECT_EQ(row.Stats[0].ItemStatType, 3u);
    EXPECT_EQ(row.Stats[0].ItemStatValue, 10);
    EXPECT_EQ(row.Stats[9].ItemStatType, 12u);
    EXPECT_EQ(row.Stats[9].ItemStatValue, 100);
    EXPECT_FLOAT_EQ(row.DamageMin[0], 11.5f);
    EXPECT_FLOAT_EQ(row.DamageMax[0], 22.5f);
    EXPECT_FLOAT_EQ(row.DamageMin[1], 3.0f);
    EXPECT_FLOAT_EQ(row.DamageMax[1], 6.0f);
    EXPECT_EQ(row.Armor, 111u);
    EXPECT_EQ(row.ArmorReborn, 33u);
    EXPECT_EQ(row.Resistances[0], 1);
    EXPECT_EQ(row.Resistances[5], 6);
    EXPECT_EQ(row.Block, 44u);
    EXPECT_EQ(row.RandomProperty, 55u);
    EXPECT_EQ(row.RequiredLevel, 37u);
    EXPECT_EQ(row.SellPrice, 12345u);
}

TEST(AscensionItemLadder, LevelsOutsideTheLadderClampToItsEnds)
{
    ItemLadder::Ladder const ladder({ RowAt(20, 200), RowAt(10, 100), RowAt(30, 300) });

    EXPECT_EQ(ladder.At(1)->Level, 10u);
    EXPECT_EQ(ladder.At(10)->Level, 10u);
    EXPECT_EQ(ladder.At(60)->Level, 30u);
}

TEST(AscensionItemLadder, MissingLevelsUseTheClosestRowBelow)
{
    ItemLadder::Ladder const ladder({ RowAt(10, 100), RowAt(20, 200), RowAt(30, 300) });

    EXPECT_EQ(ladder.At(19)->Level, 10u);
    EXPECT_EQ(ladder.At(20)->Level, 20u);
    EXPECT_EQ(ladder.At(29)->Stats[0].ItemStatValue, 200);
}

TEST(AscensionItemLadder, RowsAboveLevelSixtyFiveAreIgnored)
{
    ItemLadder::Ladder const ladder({ RowAt(65, 650), RowAt(86, 860), RowAt(105, 1050) });

    EXPECT_EQ(ladder.At(100)->Level, 65u);
    EXPECT_TRUE(ItemLadder::Ladder({ RowAt(86, 860) }).Empty());
    EXPECT_EQ(ItemLadder::Ladder().At(10), nullptr);
}

TEST(AscensionItemLadder, DropLevelIsTheLooterLevelPlusOffsetWithinOneToSixtyFive)
{
    EXPECT_EQ(ItemLadder::DropLevel(37, 0), 37);
    EXPECT_EQ(ItemLadder::DropLevel(37, -2), 35);
    EXPECT_EQ(ItemLadder::DropLevel(1, -5), 1);
    EXPECT_EQ(ItemLadder::DropLevel(64, 5), 65);
}

TEST(AscensionItemLadder, OnlyStaticWeaponsAndArmorScale)
{
    ItemTemplate proto{};
    proto.Class = ITEM_CLASS_WEAPON;
    proto.Quality = ITEM_QUALITY_UNCOMMON;
    EXPECT_TRUE(ItemLadder::ScalableItem(proto));

    proto.Class = ITEM_CLASS_ARMOR;
    EXPECT_TRUE(ItemLadder::ScalableItem(proto));

    proto.Quality = ITEM_QUALITY_HEIRLOOM;
    EXPECT_FALSE(ItemLadder::ScalableItem(proto));

    proto.Quality = ITEM_QUALITY_RARE;
    proto.ScalingStatDistribution = 1;
    EXPECT_FALSE(ItemLadder::ScalableItem(proto));

    proto.ScalingStatDistribution = 0;
    proto.Class = ITEM_CLASS_CONSUMABLE;
    EXPECT_FALSE(ItemLadder::ScalableItem(proto));
}

TEST(AscensionItemLadder, AppliedRowReplacesStatsDamageArmorAndPrice)
{
    ItemTemplate proto{};
    proto.StatsCount = 3;
    proto.ItemStat[0] = { 4, 9 };
    proto.ItemStat[1] = { 5, 9 };
    proto.ItemStat[2] = { 6, 9 };
    proto.ScalingStatDistribution = 7;
    proto.ScalingStatValue = 8;
    proto.Damage[0].DamageType = 2;

    ItemLadder::Row row = ItemLadder::ParseRecord(SampleRecord().data());
    row.Stats = {};
    row.Stats[1] = { 7, 25 };
    row.Stats[4] = { 32, 14 };
    ItemLadder::ApplyRow(proto, row);

    EXPECT_EQ(proto.StatsCount, 2u);
    EXPECT_EQ(proto.ItemStat[0].ItemStatType, 7u);
    EXPECT_EQ(proto.ItemStat[0].ItemStatValue, 25);
    EXPECT_EQ(proto.ItemStat[1].ItemStatType, 32u);
    EXPECT_EQ(proto.ItemStat[1].ItemStatValue, 14);
    EXPECT_EQ(proto.ItemStat[2].ItemStatType, 0u);
    EXPECT_EQ(proto.ItemStat[2].ItemStatValue, 0);
    EXPECT_EQ(proto.ScalingStatDistribution, 0u);
    EXPECT_EQ(proto.ScalingStatValue, 0u);
    EXPECT_FLOAT_EQ(proto.Damage[0].DamageMin, 11.5f);
    EXPECT_FLOAT_EQ(proto.Damage[0].DamageMax, 22.5f);
    EXPECT_EQ(proto.Damage[0].DamageType, 2u);
    EXPECT_EQ(proto.Armor, 111u);
    EXPECT_EQ(proto.HolyRes, 1);
    EXPECT_EQ(proto.ArcaneRes, 6);
    EXPECT_EQ(proto.Block, 44u);
    EXPECT_EQ(proto.RequiredLevel, 37u);
    EXPECT_EQ(proto.SellPrice, 12345u);
}

TEST(AscensionItemLadder, StatResponseIsTheClientsItemStatRecord)
{
    ItemTemplate proto{};
    proto.Damage[0].DamageType = 2;
    proto.Damage[1].DamageType = 4;
    ItemLadder::Row const row = ItemLadder::ParseRecord(SampleRecord().data());

    WorldPacket data = ItemLadder::BuildItemStatResponse(2244, 47, row, &proto);

    EXPECT_EQ(data.GetOpcode(), 0x0700);
    ASSERT_EQ(data.size(), 168u);
    EXPECT_EQ(data.read<uint32>(), 2244u);
    EXPECT_EQ(data.read<uint32>(), 47u);
    EXPECT_EQ(data.read<uint32>(), 2244u);
    EXPECT_EQ(data.read<uint32>(), 47u);
    for (uint32 i = 0; i < 10; ++i)
    {
        EXPECT_EQ(data.read<uint32>(), 3 + i);
        EXPECT_EQ(data.read<int32>(), int32(10 * (i + 1)));
    }
    EXPECT_FLOAT_EQ(data.read<float>(), 11.5f);
    EXPECT_FLOAT_EQ(data.read<float>(), 22.5f);
    EXPECT_EQ(data.read<uint32>(), 2u);
    EXPECT_FLOAT_EQ(data.read<float>(), 3.0f);
    EXPECT_FLOAT_EQ(data.read<float>(), 6.0f);
    EXPECT_EQ(data.read<uint32>(), 4u);
    EXPECT_EQ(data.read<uint32>(), 111u);
    EXPECT_EQ(data.read<uint32>(), 111u);
    for (int32 i = 1; i <= 6; ++i)
        EXPECT_EQ(data.read<int32>(), i);
    EXPECT_EQ(data.read<uint32>(), 44u);
    EXPECT_EQ(data.read<uint32>(), 55u);
    EXPECT_EQ(data.read<uint32>(), 37u);
    EXPECT_EQ(data.read<uint32>(), 12345u);
}

TEST(AscensionItemLadder, LevelAddonIsFieldZeroOfTheItem)
{
    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Item>(424242);
    WorldPacket data = ItemLadder::BuildLevelAddon(guid, 38);

    EXPECT_EQ(data.GetOpcode(), 0x0578);
    ASSERT_EQ(data.size(), 16u);
    EXPECT_EQ(data.read<uint64>(), guid.GetRawValue());
    EXPECT_EQ(data.read<uint32>(), 0u);
    EXPECT_EQ(data.read<uint32>(), 38u);
}

TEST(AscensionItemLadder, ItemsAuthoredWithRebornArmorWearTheRebornColumnAtEveryLevel)
{
    ItemTemplate const cowl = Authored(29, 61);
    ItemLadder::Ladder const ladder = CowlLadder(&cowl);

    EXPECT_EQ(ladder.At(29)->Armor, 61u);
    EXPECT_EQ(ladder.At(30)->Armor, 62u);
    EXPECT_EQ(ladder.At(60)->Armor, 97u);
}

TEST(AscensionItemLadder, ItemsAuthoredWithRawOrUnmatchedArmorKeepTheRawColumn)
{
    ItemTemplate const raw = Authored(29, 170);
    ItemTemplate const unmatched = Authored(29, 80);
    ItemTemplate const beyondLadder = Authored(65, 61);

    EXPECT_EQ(CowlLadder(&raw).At(30)->Armor, 174u);
    EXPECT_EQ(CowlLadder(&unmatched).At(30)->Armor, 174u);
    EXPECT_EQ(CowlLadder(&beyondLadder).At(30)->Armor, 174u);
    EXPECT_EQ(CowlLadder(nullptr).At(30)->Armor, 174u);
}

TEST(AscensionItemLadder, RebornArmorReachesTheTemplateAndBothTooltipFields)
{
    ItemTemplate const cowl = Authored(29, 61);
    ItemLadder::Ladder const ladder = CowlLadder(&cowl);
    ItemLadder::Row const& row = *ladder.At(60);

    ItemTemplate scaled = cowl;
    ItemLadder::ApplyRow(scaled, row);
    EXPECT_EQ(scaled.Armor, 97u);

    WorldPacket data = ItemLadder::BuildItemStatResponse(2244, 60, row, &cowl);
    data.read_skip(4 * sizeof(uint32) + 10 * 2 * sizeof(uint32) + 2 * 3 * sizeof(uint32));
    EXPECT_EQ(data.read<uint32>(), 97u);
    EXPECT_EQ(data.read<uint32>(), 97u);
}

TEST(AscensionItemLadder, ClientKeysFollowTheClientBands)
{
    EXPECT_EQ(ItemLadder::ClientKey(1), 3u);
    EXPECT_EQ(ItemLadder::ClientKey(20), 22u);
    EXPECT_EQ(ItemLadder::ClientKey(21), 24u);
    EXPECT_EQ(ItemLadder::ClientKey(30), 33u);
    EXPECT_EQ(ItemLadder::ClientKey(31), 35u);
    EXPECT_EQ(ItemLadder::ClientKey(50), 54u);
    EXPECT_EQ(ItemLadder::ClientKey(51), 56u);
    EXPECT_EQ(ItemLadder::ClientKey(60), 65u);
    EXPECT_EQ(ItemLadder::ClientKey(61), 86u);
    EXPECT_EQ(ItemLadder::ClientKey(80), 115u);
    EXPECT_EQ(ItemLadder::ClientKey(81), 86u);
}

TEST(AscensionItemLadder, ClientBaseForKeyInvertsTheKeyOrTakesTheLevelBelow)
{
    for (uint32 level = 1; level <= 60; ++level)
        EXPECT_EQ(ItemLadder::ClientBaseForKey(ItemLadder::ClientKey(level)), level);
    EXPECT_EQ(ItemLadder::ClientBaseForKey(23), 20u);
    EXPECT_EQ(ItemLadder::ClientBaseForKey(1), 0u);
}

TEST(AscensionItemLadder, DropBaseAndClampedLevels)
{
    EXPECT_EQ(ItemLadder::DropBase(37, 4), 41u);
    EXPECT_EQ(ItemLadder::DropBase(1, -5), 1u);
    EXPECT_EQ(ItemLadder::DropBase(255, 5), 255u);
    EXPECT_EQ(ItemLadder::ClampLevel(0), 1);
    EXPECT_EQ(ItemLadder::ClampLevel(86), ItemLadder::MaxLevel);
}

TEST(AscensionItemLadder, StockRowAnswersTheAuthoredItem)
{
    ItemTemplate cowl = Authored(29, 61);
    cowl.ItemId = 2244;
    cowl.RequiredLevel = 24;
    cowl.ItemStat[0] = { 7, 5 };

    ItemLadder::Row const row = ItemLadder::StockRow(cowl);
    EXPECT_EQ(row.ItemId, 2244u);
    EXPECT_EQ(row.Level, 29u);
    EXPECT_EQ(row.Armor, 61u);
    EXPECT_EQ(row.ArmorReborn, 61u);
    EXPECT_EQ(row.RequiredLevel, 24u);
    EXPECT_EQ(row.Stats[0].ItemStatType, 7u);
    EXPECT_EQ(row.Stats[0].ItemStatValue, 5);
}

TEST(AscensionItemLadder, PreviewPacketsCarryTheFlagRollAndInspectLevels)
{
    ObjectGuid const player = ObjectGuid::Create<HighGuid::Player>(42);
    WorldPacket flag = ItemLadder::BuildPreviewAddon(player);
    EXPECT_EQ(flag.GetOpcode(), 0x0578);
    ASSERT_EQ(flag.size(), 16u);
    EXPECT_EQ(flag.read<uint64>(), player.GetRawValue());
    EXPECT_EQ(flag.read<uint32>(), 87u);
    EXPECT_EQ(flag.read<uint32>(), 1u);

    WorldPacket roll = ItemLadder::BuildRollLevel(41);
    EXPECT_EQ(roll.GetOpcode(), 0x073F);
    ASSERT_EQ(roll.size(), 4u);
    EXPECT_EQ(roll.read<uint32>(), 41u);

    std::array<uint32, ItemLadder::InspectSlots> levels{};
    levels[0] = 37;
    levels[18] = 12;
    WorldPacket inspect = ItemLadder::BuildInspectLevels(levels);
    EXPECT_EQ(inspect.GetOpcode(), 0x0716);
    ASSERT_EQ(inspect.size(), 4u * 19u);
    EXPECT_EQ(inspect.read<uint32>(), 37u);
    inspect.read_skip(17 * sizeof(uint32));
    EXPECT_EQ(inspect.read<uint32>(), 12u);
}
