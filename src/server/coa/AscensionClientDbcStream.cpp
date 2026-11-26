/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientDbcStream.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "QueryResult.h"
#include "WorldSession.h"
#include <algorithm>
#include <bit>
#include <mutex>

namespace
{
    using Kind = AscensionClientDbcColumnKind;

    constexpr std::array<char const*, TOTAL_LOCALES> LocaleColumnSuffixes = {
        "enUS", "enGB", "koKR", "frFR", "deDE", "enCN", "zhCN", "enTW", "zhTW"};

    std::vector<AscensionClientDbcTable> const Tables = {
        {AscensionClientDbcGameObjectDisplayInfoOpcode, "gameobjectdisplayinfo_dbc",
            {{"ID", Kind::Int}, {"ModelName", Kind::String},
             {"Sound_1", Kind::Int}, {"Sound_2", Kind::Int}, {"Sound_3", Kind::Int}, {"Sound_4", Kind::Int},
             {"Sound_5", Kind::Int}, {"Sound_6", Kind::Int}, {"Sound_7", Kind::Int}, {"Sound_8", Kind::Int},
             {"Sound_9", Kind::Int}, {"Sound_10", Kind::Int},
             {"GeoBoxMinX", Kind::Float}, {"GeoBoxMinY", Kind::Float}, {"GeoBoxMinZ", Kind::Float},
             {"GeoBoxMaxX", Kind::Float}, {"GeoBoxMaxY", Kind::Float}, {"GeoBoxMaxZ", Kind::Float},
             {"ObjectEffectPackageID", Kind::Int}}},
        {AscensionClientDbcMapOpcode, "map_dbc",
            {{"ID", Kind::Int}, {"Directory", Kind::String}, {"InstanceType", Kind::Int}, {"Flags", Kind::Int},
             {"PVP", Kind::Int}, {"MapName", Kind::LocalizedString}, {"AreaTableID", Kind::Int},
             {"MapDescription0", Kind::LocalizedString}, {"MapDescription1", Kind::LocalizedString},
             {"LoadingScreenID", Kind::Int}, {"MinimapIconScale", Kind::Float}, {"CorpseMapID", Kind::Int},
             {"CorpseX", Kind::Float}, {"CorpseY", Kind::Float}, {"TimeOfDayOverride", Kind::Int},
             {"ExpansionID", Kind::Int}, {"RaidOffset", Kind::Int}, {"MaxPlayers", Kind::Int}}},
        {AscensionClientDbcMapDifficultyOpcode, "mapdifficulty_dbc",
            {{"ID", Kind::Int}, {"MapID", Kind::Int}, {"Difficulty", Kind::Int},
             {"Message", Kind::LocalizedString}, {"RaidDuration", Kind::Int}, {"MaxPlayers", Kind::Int},
             {"Difficultystring", Kind::String}}},
    };

    std::mutex LoadMutex;
    bool Loaded = false;
    std::vector<std::vector<AscensionClientDbcRow>> LoadedRows;

    std::vector<AscensionClientDbcRow> LoadRows(AscensionClientDbcTable const& table)
    {
        std::string query = "SELECT ";
        for (AscensionClientDbcColumn const& column : table.Columns)
        {
            if (column.Kind == Kind::LocalizedString)
                for (char const* suffix : LocaleColumnSuffixes)
                    query += Acore::StringFormat("`{}_Lang_{}`, ", column.Name, suffix);
            else
                query += Acore::StringFormat("`{}`, ", column.Name);
        }
        query.resize(query.size() - 2);
        query += Acore::StringFormat(" FROM `{}` ORDER BY `ID`", table.SqlTable);

        std::vector<AscensionClientDbcRow> rows;
        QueryResult result = WorldDatabase.Query(query);
        if (!result)
            return rows;
        do
        {
            Field const* fields = result->Fetch();
            AscensionClientDbcRow& row = rows.emplace_back();
            uint32 index = 0;
            for (AscensionClientDbcColumn const& column : table.Columns)
            {
                switch (column.Kind)
                {
                    case Kind::Int:
                        row.Values.push_back(uint32(fields[index++].Get<int32>()));
                        break;
                    case Kind::Float:
                        row.Values.push_back(std::bit_cast<uint32>(fields[index++].Get<float>()));
                        break;
                    case Kind::String:
                        row.Values.push_back(0);
                        row.Strings.emplace_back()[LOCALE_enUS] = fields[index++].Get<std::string>();
                        break;
                    case Kind::LocalizedString:
                    {
                        row.Values.push_back(0);
                        std::array<std::string, TOTAL_LOCALES>& text = row.Strings.emplace_back();
                        for (std::string& slot : text)
                            slot = fields[index++].Get<std::string>();
                        break;
                    }
                }
            }
        } while (result->NextRow());
        return rows;
    }

    std::vector<std::vector<AscensionClientDbcRow>> const& GetRows()
    {
        std::lock_guard lock(LoadMutex);
        if (!Loaded)
        {
            for (AscensionClientDbcTable const& table : Tables)
            {
                LoadedRows.push_back(LoadRows(table));
                if (!LoadedRows.back().empty())
                    LOG_INFO("coa", "Loaded {} {} rows for the client DBC stream", LoadedRows.back().size(), table.SqlTable);
            }
            Loaded = true;
        }
        return LoadedRows;
    }
}

void LoadAscensionClientDbcStream()
{
    GetRows();
}

std::vector<AscensionClientDbcTable> const& GetAscensionClientDbcTables()
{
    return Tables;
}

std::vector<WorldPacket> BuildAscensionClientDbcPackets(AscensionClientDbcTable const& table,
    std::vector<AscensionClientDbcRow> const& rows, LocaleConstant locale)
{
    std::vector<WorldPacket> packets;
    uint32 count = 0;
    for (AscensionClientDbcRow const& row : rows)
    {
        std::size_t rowBytes = table.Columns.size() * sizeof(uint32);
        std::vector<std::string const*> texts;
        for (std::size_t field = 0, string = 0; field < table.Columns.size(); ++field)
        {
            Kind const kind = table.Columns[field].Kind;
            if (kind != Kind::String && kind != Kind::LocalizedString)
                continue;
            std::array<std::string, TOTAL_LOCALES> const& text = row.Strings[string++];
            std::string const* chosen = kind == Kind::LocalizedString && !text[locale].empty() ? &text[locale] : &text[LOCALE_enUS];
            texts.push_back(chosen);
            rowBytes += chosen->size();
        }

        if (packets.empty() || count == AscensionClientDbcPacketRows ||
            (count && packets.back().size() + rowBytes > AscensionClientDbcPacketBytes))
        {
            if (!packets.empty())
                packets.back().put<uint32>(0, count);
            packets.emplace_back(table.Opcode, std::min(rowBytes, AscensionClientDbcPacketBytes) + sizeof(uint32));
            packets.back() << uint32(0);
            count = 0;
        }

        WorldPacket& packet = packets.back();
        for (std::size_t field = 0, string = 0; field < table.Columns.size(); ++field)
        {
            Kind const kind = table.Columns[field].Kind;
            if (kind != Kind::String && kind != Kind::LocalizedString)
            {
                packet << row.Values[field];
                continue;
            }
            std::string const& text = *texts[string++];
            packet << uint32(text.size());
            if (!text.empty())
                packet.append(reinterpret_cast<uint8 const*>(text.data()), text.size());
        }
        ++count;
    }
    if (!packets.empty())
        packets.back().put<uint32>(0, count);
    return packets;
}

void SendAscensionClientDbcStream(WorldSession* session)
{
    std::vector<std::vector<AscensionClientDbcRow>> const& rows = GetRows();
    LocaleConstant const locale = session->GetSessionDbcLocale();
    std::size_t bytes = 0;
    uint32 rowsSent = 0;
    for (std::size_t table = 0; table < Tables.size(); ++table)
    {
        for (WorldPacket const& packet : BuildAscensionClientDbcPackets(Tables[table], rows[table], locale))
        {
            session->SendPacket(&packet);
            bytes += packet.size();
        }
        rowsSent += uint32(rows[table].size());
    }
    if (rowsSent)
        LOG_DEBUG("coa", "Streamed {} client DBC rows ({} bytes) to account {} before world login",
            rowsSent, bytes, session->GetAccountId());
}
