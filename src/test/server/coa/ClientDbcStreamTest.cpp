#include "AscensionClientDbcStream.h"
#include <gtest/gtest.h>
#include <stdexcept>

namespace
{
    AscensionClientDbcTable const& Table(uint16 opcode)
    {
        for (AscensionClientDbcTable const& table : GetAscensionClientDbcTables())
            if (table.Opcode == opcode)
                return table;
        throw std::logic_error("no table");
    }

    AscensionClientDbcRow Row(AscensionClientDbcTable const& table, uint32 id)
    {
        AscensionClientDbcRow row;
        for (AscensionClientDbcColumn const& column : table.Columns)
        {
            row.Values.push_back(0);
            if (column.Kind == AscensionClientDbcColumnKind::String ||
                column.Kind == AscensionClientDbcColumnKind::LocalizedString)
                row.Strings.emplace_back();
        }
        row.Values[0] = id;
        return row;
    }

    std::string ReadString(WorldPacket& packet)
    {
        uint32 const length = packet.read<uint32>();
        std::string text(length, '\0');
        if (length)
            packet.read(reinterpret_cast<uint8*>(text.data()), length);
        return text;
    }
}

TEST(ClientDbcStream, TablesMatchTheClientRowSizes)
{
    EXPECT_EQ(Table(AscensionClientDbcGameObjectDisplayInfoOpcode).Columns.size(), 0x4Cu / 4);
    EXPECT_EQ(Table(AscensionClientDbcMapOpcode).Columns.size(), 0x48u / 4);
    EXPECT_EQ(Table(AscensionClientDbcMapDifficultyOpcode).Columns.size(), 0x1Cu / 4);
}

TEST(ClientDbcStream, NoRowsSendNothing)
{
    EXPECT_TRUE(BuildAscensionClientDbcPackets(Table(AscensionClientDbcMapOpcode), {}, LOCALE_enUS).empty());
}

TEST(ClientDbcStream, MapDifficultyRowIsWrittenFieldByField)
{
    AscensionClientDbcTable const& table = Table(AscensionClientDbcMapDifficultyOpcode);
    AscensionClientDbcRow row = Row(table, 756);
    row.Values[1] = 934;
    row.Values[2] = 1;
    row.Values[4] = 86400;
    row.Values[5] = 5;
    row.Strings[0][LOCALE_enUS] = "Mythic Difficulty requires you to be level 80.";
    row.Strings[0][LOCALE_deDE] = "Mythisch erfordert Stufe 80.";
    row.Strings[1][LOCALE_enUS] = "DUNGEON_DIFFICULTY_5PLAYER_EPIC";

    std::vector<WorldPacket> packets = BuildAscensionClientDbcPackets(table, {row}, LOCALE_deDE);
    ASSERT_EQ(packets.size(), 1u);
    WorldPacket& packet = packets[0];
    EXPECT_EQ(packet.GetOpcode(), AscensionClientDbcMapDifficultyOpcode);
    EXPECT_EQ(packet.read<uint32>(), 1u);
    EXPECT_EQ(packet.read<uint32>(), 756u);
    EXPECT_EQ(packet.read<uint32>(), 934u);
    EXPECT_EQ(packet.read<uint32>(), 1u);
    EXPECT_EQ(ReadString(packet), "Mythisch erfordert Stufe 80.");
    EXPECT_EQ(packet.read<uint32>(), 86400u);
    EXPECT_EQ(packet.read<uint32>(), 5u);
    EXPECT_EQ(ReadString(packet), "DUNGEON_DIFFICULTY_5PLAYER_EPIC");
    EXPECT_EQ(packet.rpos(), packet.size());
}

TEST(ClientDbcStream, LocalizedTextFallsBackToEnglish)
{
    AscensionClientDbcTable const& table = Table(AscensionClientDbcMapDifficultyOpcode);
    AscensionClientDbcRow row = Row(table, 1);
    row.Strings[0][LOCALE_enUS] = "english";
    std::vector<WorldPacket> packets = BuildAscensionClientDbcPackets(table, {row}, LOCALE_frFR);
    WorldPacket& packet = packets[0];
    packet.read_skip(4 * 4);
    EXPECT_EQ(ReadString(packet), "english");
}

TEST(ClientDbcStream, BatchesSplitAtTheRowLimit)
{
    AscensionClientDbcTable const& table = Table(AscensionClientDbcMapDifficultyOpcode);
    std::vector<AscensionClientDbcRow> rows;
    for (uint32 id = 1; id <= AscensionClientDbcPacketRows + 10; ++id)
        rows.push_back(Row(table, id));
    std::vector<WorldPacket> packets = BuildAscensionClientDbcPackets(table, rows, LOCALE_enUS);
    ASSERT_EQ(packets.size(), 2u);
    EXPECT_EQ(packets[0].read<uint32>(), AscensionClientDbcPacketRows);
    EXPECT_EQ(packets[1].read<uint32>(), 10u);
    EXPECT_EQ(packets[1].read<uint32>(), AscensionClientDbcPacketRows + 1);
}

TEST(ClientDbcStream, BatchesSplitAtTheByteLimit)
{
    AscensionClientDbcTable const& table = Table(AscensionClientDbcGameObjectDisplayInfoOpcode);
    std::vector<AscensionClientDbcRow> rows;
    for (uint32 id = 1; id <= 40; ++id)
    {
        rows.push_back(Row(table, id));
        rows.back().Strings[0][LOCALE_enUS] = std::string(2000, 'm');
    }
    std::vector<WorldPacket> packets = BuildAscensionClientDbcPackets(table, rows, LOCALE_enUS);
    ASSERT_GT(packets.size(), 1u);
    uint32 total = 0;
    for (WorldPacket& packet : packets)
    {
        EXPECT_LE(packet.size(), AscensionClientDbcPacketBytes);
        total += packet.read<uint32>();
    }
    EXPECT_EQ(total, 40u);
}

TEST(ClientDbcStream, OversizedRowStillGoesAlone)
{
    AscensionClientDbcTable const& table = Table(AscensionClientDbcGameObjectDisplayInfoOpcode);
    std::vector<AscensionClientDbcRow> rows = {Row(table, 1), Row(table, 2)};
    rows[0].Strings[0][LOCALE_enUS] = std::string(AscensionClientDbcPacketBytes * 2, 'm');
    std::vector<WorldPacket> packets = BuildAscensionClientDbcPackets(table, rows, LOCALE_enUS);
    ASSERT_EQ(packets.size(), 2u);
    EXPECT_EQ(packets[0].read<uint32>(), 1u);
    EXPECT_EQ(packets[1].read<uint32>(), 1u);
}
