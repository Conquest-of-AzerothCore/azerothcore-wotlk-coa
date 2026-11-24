/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLIENT_DBC_STREAM_H
#define ASCENSION_CLIENT_DBC_STREAM_H

#include "Common.h"
#include "WorldPacket.h"
#include <array>
#include <string>
#include <vector>

class WorldSession;

constexpr uint16 AscensionClientDbcGameObjectDisplayInfoOpcode = 0x8F3;
constexpr uint16 AscensionClientDbcMapOpcode = 0x8F4;
constexpr uint16 AscensionClientDbcMapDifficultyOpcode = 0x8F5;

constexpr std::size_t AscensionClientDbcPacketRows = 512;
constexpr std::size_t AscensionClientDbcPacketBytes = 16 * 1024;

enum class AscensionClientDbcColumnKind : uint8
{
    Int,
    Float,
    String,
    LocalizedString,
};

struct AscensionClientDbcColumn
{
    char const* Name;
    AscensionClientDbcColumnKind Kind;
};

struct AscensionClientDbcTable
{
    uint16 Opcode;
    char const* SqlTable;
    std::vector<AscensionClientDbcColumn> Columns;
};

struct AscensionClientDbcRow
{
    std::vector<uint32> Values;
    std::vector<std::array<std::string, TOTAL_LOCALES>> Strings;
};

std::vector<AscensionClientDbcTable> const& GetAscensionClientDbcTables();

std::vector<WorldPacket> BuildAscensionClientDbcPackets(AscensionClientDbcTable const& table,
    std::vector<AscensionClientDbcRow> const& rows, LocaleConstant locale);

void LoadAscensionClientDbcStream();

void SendAscensionClientDbcStream(WorldSession* session);

#endif
