/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundBrackets.h"
#include "AscensionBattlegroundBracketsPolicy.h"
#include "DBCStores.h"
#include "Log.h"
#include <deque>
#include <map>
#include <mutex>
#include <set>
#include <vector>

extern DBCStorage<PvPDifficultyEntry> sPvPDifficultyStore;

namespace AscensionBattlegroundBrackets
{
namespace
{
    namespace Policy = AscensionBattlegroundBracketsPolicy;

    struct MapBrackets
    {
        std::vector<PvPDifficultyEntry const*> widened;
        std::set<uint32> absorbedIds;
    };

    bool configuredEnabled = false;
    std::string configuredRanges;
    std::once_flag built;
    std::deque<PvPDifficultyEntry> entries;
    std::map<uint32, MapBrackets> brackets;

    std::map<uint32, std::vector<PvPDifficultyEntry const*>> StockBattlegroundRowsBelowSixty()
    {
        std::map<uint32, std::vector<PvPDifficultyEntry const*>> rows;
        for (PvPDifficultyEntry const* entry : sPvPDifficultyStore)
        {
            if (entry->maxLevel > Policy::HighestWidenableLevel)
                continue;

            MapEntry const* map = sMapStore.LookupEntry(entry->mapId);
            if (map && map->IsBattleground())
                rows[entry->mapId].push_back(entry);
        }
        return rows;
    }

    bool BuildFrom(std::vector<Policy::LevelRange> const& ranges)
    {
        auto const stockRowsByMap = StockBattlegroundRowsBelowSixty();
        std::vector<uint32> mapIds;
        std::vector<std::vector<Policy::BracketRow>> widenedPerMap;
        for (auto const& [mapId, stockRows] : stockRowsByMap)
        {
            std::vector<Policy::BracketRow> rows;
            for (PvPDifficultyEntry const* entry : stockRows)
                rows.push_back({ entry->bracketId, entry->minLevel, entry->maxLevel });

            auto widened = Policy::Widen(rows, ranges);
            if (!widened)
            {
                LOG_ERROR("server.loading", "CoA.Battleground.WideBrackets.Ranges \"{}\" splits a stock bracket of "
                    "map {}; stock battleground brackets stay in use.", configuredRanges, mapId);
                return false;
            }

            mapIds.push_back(mapId);
            widenedPerMap.push_back(std::move(*widened));
        }

        if (auto const misaligned = Policy::FirstMapWithMisalignedId(widenedPerMap, ranges))
        {
            LOG_ERROR("server.loading", "CoA.Battleground.WideBrackets.Ranges \"{}\" gives map {} a bracket id that "
                "another battleground uses for a different range; stock battleground brackets stay in use.",
                configuredRanges, mapIds[*misaligned]);
            return false;
        }

        for (std::size_t index = 0; index < mapIds.size(); ++index)
        {
            uint32 const mapId = mapIds[index];
            std::vector<PvPDifficultyEntry const*> const& stockRows = stockRowsByMap.at(mapId);
            MapBrackets& mapBrackets = brackets[mapId];
            for (Policy::BracketRow const& row : widenedPerMap[index])
            {
                uint32 difficulty = 0;
                for (PvPDifficultyEntry const* entry : stockRows)
                {
                    if (entry->bracketId == row.bracketId)
                        difficulty = entry->difficulty;
                    else if (entry->minLevel >= row.minLevel && entry->maxLevel <= row.maxLevel)
                        mapBrackets.absorbedIds.insert(entry->bracketId);
                }

                entries.emplace_back(mapId, row.bracketId, row.minLevel, row.maxLevel, difficulty);
                mapBrackets.widened.push_back(&entries.back());
            }
        }
        return true;
    }

    void Build()
    {
        if (!configuredEnabled)
            return;

        auto const ranges = Policy::ParseRanges(configuredRanges);
        if (!ranges)
        {
            LOG_ERROR("server.loading", "CoA.Battleground.WideBrackets.Ranges \"{}\" is invalid; stock battleground "
                "brackets stay in use.", configuredRanges);
            return;
        }

        if (!BuildFrom(*ranges))
        {
            brackets.clear();
            entries.clear();
            return;
        }

        LOG_INFO("server.loading", ">> Battleground brackets below level 60 widened to {}", configuredRanges);
    }

    MapBrackets const* BracketsOf(uint32 mapId)
    {
        std::call_once(built, Build);
        auto const it = brackets.find(mapId);
        return it == brackets.end() ? nullptr : &it->second;
    }

    PvPDifficultyEntry const* WidenedEntry(MapBrackets const& mapBrackets, BattlegroundBracketId id)
    {
        for (PvPDifficultyEntry const* entry : mapBrackets.widened)
            if (entry->bracketId == id)
                return entry;
        return nullptr;
    }
}

void Configure(bool enabled, std::string ranges)
{
    configuredEnabled = enabled;
    configuredRanges = std::move(ranges);
}

PvPDifficultyEntry const* FindByLevel(uint32 mapId, uint32 level)
{
    MapBrackets const* mapBrackets = BracketsOf(mapId);
    if (!mapBrackets)
        return nullptr;

    for (PvPDifficultyEntry const* entry : mapBrackets->widened)
        if (entry->minLevel <= level && level <= entry->maxLevel)
            return entry;
    return nullptr;
}

bool FindById(uint32 mapId, BattlegroundBracketId id, PvPDifficultyEntry const*& entry)
{
    MapBrackets const* mapBrackets = BracketsOf(mapId);
    if (!mapBrackets)
        return false;

    if (PvPDifficultyEntry const* widened = WidenedEntry(*mapBrackets, id))
    {
        entry = widened;
        return true;
    }

    if (!mapBrackets->absorbedIds.count(id))
        return false;

    entry = nullptr;
    return true;
}

uint32 WidenedMaxLevel(uint32 mapId, BattlegroundBracketId id)
{
    MapBrackets const* mapBrackets = BracketsOf(mapId);
    if (!mapBrackets)
        return 0;

    PvPDifficultyEntry const* entry = WidenedEntry(*mapBrackets, id);
    return entry ? entry->maxLevel : 0;
}
}
