#include "ManastormDataStore.h"

#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Field.h"
#include "DBCStores.h"
#include "Config.h"
#include "ManastormModuleConfig.h"
#include <array>
#include <filesystem>
#include <fstream>
#include <unordered_map>
#include "Log.h"
#include "ObjectMgr.h"
#include "MapMgr.h"

#include <cmath>
#include <cstring>
#include <limits>

namespace
{
constexpr char const* LOG_FILTER = "module.manastorm.endless";

bool IsValidPositiveMultiplier(float value)
{
    return std::isfinite(value) && value > 0.0f;
}

using NativeIdentity = std::array<uint32, 9>;

float NativeWordAsFloat(uint32 word)
{
    static_assert(sizeof(float) == sizeof(uint32));

    float value = 0.0f;
    std::memcpy(&value, &word, sizeof(value));
    return value;
}

bool LoadNativeIdentities(std::unordered_map<uint32, NativeIdentity>& identities)
{
    std::filesystem::path const path = sConfigMgr->GetOption<std::string>("Manastorm.NativeDBCPath",
        (std::filesystem::path(sConfigMgr->GetOption<std::string>("DataDir", "."))
            / "dbc" / "Manastorm.dbc").string());
    std::ifstream file(path, std::ios::binary);
    char magic[4]{};
    file.read(magic, 4);
    auto readWord = [&file]() -> uint32
    {
        unsigned char bytes[4]{};
        file.read(reinterpret_cast<char*>(bytes), 4);
        return uint32(bytes[0]) | (uint32(bytes[1]) << 8) | (uint32(bytes[2]) << 16) | (uint32(bytes[3]) << 24);
    };
    uint32 const count = readWord();
    uint32 const fields = readWord();
    uint32 const size = readWord();
    uint32 const strings = readWord();
    std::error_code ec;
    uint64 const length = std::filesystem::file_size(path, ec);
    if (!file || std::string_view(magic, 4) != "WDBC" || fields != 9 || size != 36
        || count > 100000 || ec || length != 20ULL + uint64(count) * size + strings)
    {
        LOG_ERROR(LOG_FILTER, "Mode 2 requires matching Manastorm.dbc (9 words): {}. "
            "Set Manastorm.NativeDBCPath to the matching client file; no stages were invented.", path.string());
        return false;
    }
    for (uint32 i = 0; i < count; ++i)
    {
        NativeIdentity row{};
        for (auto& word : row)
            word = readWord();

        if (!file || !identities.emplace(row[0], row).second)
            return false;
    }
    return true;
}

}

ManastormDataStore& ManastormDataStore::Instance()
{
    static ManastormDataStore instance;
    return instance;
}

CreatureData const* ManastormDataStore::GetPrivateCreature(ObjectGuid::LowType spawnId) const
{
    auto const itr = _privateCreatures.find(spawnId);
    return itr == _privateCreatures.end() ? nullptr : &itr->second;
}

bool ManastormDataStore::LoadPrivateCreatures()
{
    _privateCreatures.clear();
    WorldDatabasePreparedStatement* statement = WorldDatabase.GetPreparedStatement(WORLD_SEL_MANASTORM_PRIVATE_CREATURES);
    PreparedQueryResult result = WorldDatabase.Query(statement);
    if (!result)
        return true;

    do
    {
        Field* fields = result->Fetch();
        CreatureData data;
        data.spawnId = fields[0].Get<uint32>();
        data.id = fields[1].Get<uint32>();
        data.mapid = fields[2].Get<uint16>();
        data.phaseMask = fields[3].Get<uint32>();
        data.equipmentId = fields[4].Get<int8>();
        data.posX = fields[5].Get<float>();
        data.posY = fields[6].Get<float>();
        data.posZ = fields[7].Get<float>();
        data.orientation = fields[8].Get<float>();
        data.spawntimesecs = fields[9].Get<uint32>();
        data.wander_distance = fields[10].Get<float>();
        data.currentwaypoint = fields[11].Get<uint32>();
        data.curhealth = fields[12].Get<uint32>();
        data.curmana = fields[13].Get<uint32>();
        data.movementType = fields[14].Get<uint8>();
        data.npcflag = fields[15].Get<uint32>();
        data.unit_flags = fields[16].Get<uint32>();
        data.dynamicflags = fields[17].Get<uint32>();
        data.dbData = false;
        data.spawnMask = 1;
        if (!data.spawnId || !data.phaseMask || !sObjectMgr->GetCreatureTemplate(data.id)
            || !sMapStore.LookupEntry(data.mapid) || !MapMgr::IsValidMapCoord(data.mapid, data.posX, data.posY, data.posZ, data.orientation)
            || data.movementType > 2 || !std::isfinite(data.wander_distance) || data.wander_distance < 0.0f)
        {
            LOG_ERROR(LOG_FILTER, "Invalid Manastorm private creature record {}.", data.spawnId);
            return false;
        }
        _privateCreatures.emplace(data.spawnId, data);
    } while (result->NextRow());

    LOG_INFO(LOG_FILTER, "Loaded {} SQL-backed Manastorm-only creature definitions.", _privateCreatures.size());
    return true;
}

bool ManastormDataStore::Load()
{
    _loaded = false;

    _segments.clear();
    _scalingCurve.clear();
    _groupScalingRanges.clear();
    _creaturePools.clear();
    _hubReturns.clear();
    _affixes.clear();
    _affixPolicies.clear();
    _unlocks.clear();

    bool const privateCreaturesLoaded = LoadPrivateCreatures();

    bool const segmentsLoaded =
        privateCreaturesLoaded && LoadSegments();

    bool const segmentSpawnsLoaded =
        segmentsLoaded &&
        LoadSegmentSpawns();

    bool const creaturePoolsLoaded =
        segmentSpawnsLoaded &&
        LoadCreaturePools();

    bool const scalingLoaded =
        LoadScalingCurve();

    bool const groupScalingLoaded =
        LoadGroupScaling();

    bool const hubReturnsLoaded =
        LoadHubReturns();

    bool const affixesLoaded =
        LoadAffixes();

    bool const affixRanksLoaded =
        affixesLoaded &&
        LoadAffixRankSpells();

    bool const affixPoliciesLoaded =
        affixesLoaded &&
        LoadAffixPolicies();

    bool const unlocksLoaded =
        segmentsLoaded &&
        LoadUnlocks();

    bool const unlockTriggersLoaded =
        unlocksLoaded &&
        LoadUnlockTriggers();

    bool const unlockGrantsLoaded =
        unlockTriggersLoaded &&
        creaturePoolsLoaded &&
        LoadUnlockGrants();

    _loaded =
        segmentsLoaded &&
        segmentSpawnsLoaded &&
        creaturePoolsLoaded &&
        scalingLoaded &&
        groupScalingLoaded &&
        hubReturnsLoaded &&
        affixesLoaded &&
        affixRanksLoaded &&
        affixPoliciesLoaded &&
        unlocksLoaded &&
        unlockTriggersLoaded &&
        unlockGrantsLoaded;

    if (_loaded)
    {
        LOG_INFO(
            LOG_FILTER,
            "Manastorm datastore loaded: {} segments, "
            "{} creature pools, {} depth scaling points, "
            "{} group scaling ranges, {} hub return pads, "
            "{} affixes, {} affix policies, {} progression unlocks.",
            _segments.size(),
            _creaturePools.size(),
            _scalingCurve.size(),
            _groupScalingRanges.size(),
            _hubReturns.size(),
            _affixes.size(),
            _affixPolicies.size(),
            _unlocks.size());
    }
    else
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm datastore failed to load. "
            "Check Manastorm world database tables "
            "and previous errors.");
    }

    return _loaded;
}

bool ManastormDataStore::LoadHubReturns()
{
    QueryResult countResult = WorldDatabase.Query(
        "SELECT COUNT(*) FROM `manastorm_hub_return`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_hub_return`. "
            "Apply 12_manastorm_hub_spawns.sql before starting Manastorm.");
        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    QueryResult result = WorldDatabase.Query(
        "SELECT "
        "r.`team_id`, r.`gameobject_guid`, r.`z_offset`, "
        "g.`map`, g.`position_x`, g.`position_y`, "
        "g.`position_z`, g.`orientation` "
        "FROM `manastorm_hub_return` r "
        "INNER JOIN `gameobject` g "
        "ON g.`guid` = r.`gameobject_guid` "
        "AND g.`id` = 20832 "
        "ORDER BY r.`team_id`");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "No valid Manastorm hub return pads were resolved. "
            "The configured GUIDs must point to gameobject entry 20832.");
        return false;
    }

    bool valid = true;

    do
    {
        Field* fields = result->Fetch();

        uint8 const teamId =
            fields[0].Get<uint8>();

        uint64 const spawnIdRaw =
            fields[1].Get<uint64>();

        float const zOffset =
            fields[2].Get<float>();

        uint32 const mapId =
            fields[3].Get<uint32>();

        if (teamId > 1)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm hub return team_id {}. "
                "Only 0=Alliance and 1=Horde are supported.",
                uint32(teamId));

            valid = false;
            continue;
        }

        if (!spawnIdRaw ||
            spawnIdRaw >
                uint64(std::numeric_limits<
                    ObjectGuid::LowType>::max()))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm hub return gameobject GUID {} "
                "for team_id {}.",
                spawnIdRaw,
                uint32(teamId));

            valid = false;
            continue;
        }

        if (!std::isfinite(zOffset) ||
            zOffset < 0.0f ||
            zOffset > 10.0f)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm hub return z_offset {} "
                "for team_id {}. Expected a finite value from 0 to 10.",
                zOffset,
                uint32(teamId));

            valid = false;
            continue;
        }

        if (!sMapStore.LookupEntry(mapId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm hub return map {} "
                "for team_id {}.",
                mapId,
                uint32(teamId));

            valid = false;
            continue;
        }

        ManastormHubReturn hubReturn;
        hubReturn.TeamId = teamId;
        hubReturn.GameObjectSpawnId =
            ObjectGuid::LowType(spawnIdRaw);
        hubReturn.MapId = mapId;
        hubReturn.PositionX = fields[4].Get<float>();
        hubReturn.PositionY = fields[5].Get<float>();
        hubReturn.PositionZ = fields[6].Get<float>();
        hubReturn.Orientation = fields[7].Get<float>();
        hubReturn.ZOffset = zOffset;

        if (!_hubReturns.emplace(
            teamId,
            hubReturn).second)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Duplicate Manastorm hub return mapping "
                "for team_id {}.",
                uint32(teamId));

            valid = false;
        }
    }
    while (result->NextRow());

    if (configuredRows != 2 ||
        _hubReturns.size() != 2 ||
        _hubReturns.find(0) == _hubReturns.end() ||
        _hubReturns.find(1) == _hubReturns.end())
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm hub returns require exactly two valid rows: "
            "team_id 0=Alliance and team_id 1=Horde. "
            "Configured rows={}, valid resolved rows={}.",
            configuredRows,
            _hubReturns.size());

        valid = false;
    }

    if (valid)
    {
        LOG_INFO(
            LOG_FILTER,
            "Loaded Manastorm wipe return pads: "
            "Alliance GO={} map={}, Horde GO={} map={}.",
            _hubReturns.at(0).GameObjectSpawnId,
            _hubReturns.at(0).MapId,
            _hubReturns.at(1).GameObjectSpawnId,
            _hubReturns.at(1).MapId);
    }

    return valid;
}

bool ManastormDataStore::LoadSegments()
{
    std::unordered_map<uint32, NativeIdentity> nativeIdentities;
    bool const native = ManastormModuleConfig::IsNativeClientMode();
    if (native && !LoadNativeIdentities(nativeIdentities))
        return false;

    QueryResult countResult = WorldDatabase.Query(
        "SELECT COUNT(*) FROM `manastorm_segment`");

    if (!countResult)
    {
        LOG_ERROR(LOG_FILTER,
            "Unable to query `manastorm_segment`. The table is missing or inaccessible.");
        return false;
    }

    uint64 const configuredRows = countResult->Fetch()[0].Get<uint64>();
    if (!configuredRows)
    {
        LOG_WARN(LOG_FILTER,
            "`manastorm_segment` exists but contains no rows. "
            "The engine will load, but `.manastorm start` cannot select a stage yet.");
        return true;
    }

    QueryResult result = WorldDatabase.Query(
        "SELECT "
        "`segment_id`, `map_id`, `runtime_map_id`, "
        "`runtime_map_override_enabled`, "
        "`difficulty`, `dungeon_encounter_id`, "
        "`objective_creature_entry`, `runtime_objective_creature_entry`, "
        "`start_game_tele_id`, `weight`, "
        "`min_depth`, `max_depth`, `reward_multiplier`, "
        "`chaotic_link_stacks`, `flags` "
        "FROM `manastorm_segment` "
        "WHERE `enabled` = 1 "
        "ORDER BY `segment_id`");

    if (!result)
    {
        // The table can legitimately contain rows with all rows disabled.
        LOG_INFO(LOG_FILTER,
            "`manastorm_segment` contains no enabled rows.");
        return true;
    }

    do
    {
        Field* fields = result->Fetch();

        ManastormSegment segment;
        segment.SegmentId = fields[0].Get<uint32>();
        segment.NativeMapId = fields[1].Get<uint32>();

        uint32 const runtimeMapId =
            fields[2].Get<uint32>();

        bool const runtimeMapOverrideEnabled =
            fields[3].Get<uint8>() != 0;

        segment.MapId =
            runtimeMapOverrideEnabled
            ? runtimeMapId
            : segment.NativeMapId;

        segment.Difficulty = fields[4].Get<uint8>();

        // Patch-M difficulty 2 is the native Manastorm Endgame track, not a
        // physical WotLK dungeon spawn mode. Keep the native identity intact
        // while loading the base dungeon population at runtime.
        segment.RuntimeDifficulty =
            segment.Difficulty == 2
            ? 0
            : segment.Difficulty;

        segment.DungeonEncounterId = fields[5].Get<uint32>();
        segment.NativeObjectiveCreatureEntry = fields[6].Get<uint32>();

        uint32 const runtimeObjectiveCreatureEntry =
            fields[7].Get<uint32>();

        segment.ObjectiveCreatureEntry =
            runtimeObjectiveCreatureEntry
            ? runtimeObjectiveCreatureEntry
            : segment.NativeObjectiveCreatureEntry;

        segment.StartGameTeleId = fields[8].Get<uint32>();
        segment.Weight = fields[9].Get<uint32>();
        segment.MinDepth = fields[10].Get<uint32>();
        segment.MaxDepth = fields[11].Get<uint32>();
        segment.RewardMultiplier = fields[12].Get<float>();
        segment.ChaoticLinkStacks = fields[13].Get<uint8>();
        segment.Flags = fields[14].Get<uint32>();

        if (!segment.SegmentId)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment with segment_id=0.");
            continue;
        }

        if (!segment.ObjectiveCreatureEntry)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: native objective={} and runtime "
                "objective override={} resolve to creature entry 0.",
                segment.SegmentId,
                segment.NativeObjectiveCreatureEntry,
                runtimeObjectiveCreatureEntry);
            continue;
        }

        if (!sObjectMgr->GetCreatureTemplate(segment.ObjectiveCreatureEntry))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: runtime objective creature "
                "entry {} does not exist (native objective={}).",
                segment.SegmentId,
                segment.ObjectiveCreatureEntry,
                segment.NativeObjectiveCreatureEntry);
            continue;
        }

        if (!segment.StartGameTeleId)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: start_game_tele_id is 0.",
                segment.SegmentId);
            continue;
        }

        GameTele const* tele = sObjectMgr->GetGameTele(segment.StartGameTeleId);
        if (!tele)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: game_tele id {} does not exist. "
                "Create it with `.tele add <name>` and reload Manastorm.",
                segment.SegmentId, segment.StartGameTeleId);
            continue;
        }

        if (tele->mapId != segment.MapId)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: native map_id={} runtime map={} "
                "but game_tele id {} points to map {}.",
                segment.SegmentId,
                segment.NativeMapId,
                segment.MapId,
                segment.StartGameTeleId,
                tele->mapId);
            continue;
        }

        if (!segment.Weight)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: weight must be greater than 0.",
                segment.SegmentId);
            continue;
        }

        if (!segment.MinDepth)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: min_depth must be at least 1.",
                segment.SegmentId);
            continue;
        }

        if (segment.MaxDepth && segment.MaxDepth < segment.MinDepth)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: max_depth {} is below min_depth {}.",
                segment.SegmentId, segment.MaxDepth, segment.MinDepth);
            continue;
        }

        if (!IsValidPositiveMultiplier(segment.RewardMultiplier))
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: reward_multiplier={} is invalid.",
                segment.SegmentId, segment.RewardMultiplier);
            continue;
        }

        // Spell 93459 has a recovered StackAmount limit of 254.
        if (segment.ChaoticLinkStacks > 254)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: chaotic_link_stacks={} exceeds "
                "Chaotic Link spell 93459 maximum stack count 254.",
                segment.SegmentId,
                uint32(segment.ChaoticLinkStacks));

            continue;
        }

        if (native)
        {
            auto const identity =
                nativeIdentities.find(
                    segment.SegmentId);

            if (identity == nativeIdentities.end() ||
                identity->second[1] !=
                    segment.NativeMapId ||
                identity->second[2] !=
                    segment.Difficulty ||
                identity->second[3] !=
                    segment.DungeonEncounterId)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Ignoring Mode 2 segment {}: segment_id/native map_id/"
                    "difficulty/dungeon_encounter_id must match the original "
                    "Manastorm.dbc row.",
                    segment.SegmentId);
                continue;
            }

            // Preserve all five remaining native row values in the segment
            // snapshot even though the shared gameplay backend does not yet
            // consume them. This prevents duplicate-looking segment families
            // from losing native Patch-M/realm-overlay evidence.
            segment.NativeWord4Raw =
                identity->second[4];
            segment.NativeWord5Raw =
                identity->second[5];
            segment.NativeWord6Raw =
                identity->second[6];
            segment.NativeWord7Raw =
                identity->second[7];
            segment.NativeWord8Raw =
                identity->second[8];

            segment.NativeRewardEndMultiplier =
                NativeWordAsFloat(identity->second[4]);
            segment.NativeRewardEncounterMultiplier =
                NativeWordAsFloat(identity->second[5]);
            segment.NativeExperienceFactor1 =
                NativeWordAsFloat(identity->second[6]);
            segment.NativeUnknownW7 =
                NativeWordAsFloat(identity->second[7]);
            segment.NativeExperienceFactor2 =
                NativeWordAsFloat(identity->second[8]);
        }
        MapEntry const* map =
            sMapStore.LookupEntry(
                segment.MapId);

        if (!map)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: runtime map {} does not exist "
                "(native map_id={}).",
                segment.SegmentId,
                segment.MapId,
                segment.NativeMapId);
            continue;
        }

        if (map->IsBattlegroundOrArena())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: runtime map {} is a "
                "battleground/arena.",
                segment.SegmentId,
                segment.MapId);
            continue;
        }

        // Native dungeon/raid stages retain ordinary map-difficulty
        // validation. An explicit runtime override may instead point at a
        // non-instanceable world map; the generic scripted-private map layer
        // handles isolation for that case.
        if (map->Instanceable() &&
            (!map->IsDungeon() ||
             !GetMapDifficultyData(
                 segment.MapId,
                 Difficulty(
                     segment.RuntimeDifficulty))))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Ignoring Manastorm segment {}: unsupported runtime "
                "dungeon/raid map {} difficulty {}.",
                segment.SegmentId,
                segment.MapId,
                uint32(segment.Difficulty));
            continue;
        }

        _segments.push_back(segment);
    }
    while (result->NextRow());

    LOG_INFO(LOG_FILTER,
        "Loaded {} enabled and valid Manastorm segments from {} configured rows.",
        _segments.size(), configuredRows);

    return true;
}

bool ManastormDataStore::LoadSegmentSpawns()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_segment_spawn`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_segment_spawn`. "
            "Apply 05_manastorm_segment_pool_architecture.sql before starting.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    std::size_t loadedRows = 0;
    bool valid = true;

    if (configuredRows)
    {
        QueryResult result =
            WorldDatabase.Query(
                "SELECT "
                "s.`segment_id`, "
                "s.`spawn_guid`, "
                "s.`flags`, "
                "COALESCE(c.`map`, p.`map`, 4294967295), "
                "COALESCE(c.`id`, p.`id`, 0) "
                "FROM `manastorm_segment_spawn` s "
                "LEFT JOIN `creature` c "
                "ON c.`guid` = s.`spawn_guid` "
                "LEFT JOIN `manastorm_private_creature` p ON p.`guid` = s.`spawn_guid` "
                "WHERE s.`enabled` = 1 "
                "ORDER BY s.`segment_id`, s.`spawn_guid`");

        if (result)
        {
            do
            {
                Field* fields =
                    result->Fetch();

                uint32 const segmentId =
                    fields[0].Get<uint32>();

                ObjectGuid::LowType const spawnGuid =
                    fields[1].Get<uint32>();

                uint32 const flags =
                    fields[2].Get<uint32>();

                uint32 const spawnMap =
                    fields[3].Get<uint32>();

                uint32 const spawnEntry =
                    fields[4].Get<uint32>();

                ManastormSegment* segment = nullptr;

                for (ManastormSegment& candidate :
                    _segments)
                {
                    if (candidate.SegmentId ==
                        segmentId)
                    {
                        segment = &candidate;
                        break;
                    }
                }

                if (!segment)
                {
                    LOG_WARN(
                        LOG_FILTER,
                        "Ignoring authored spawn {} for unknown or "
                        "disabled Manastorm segment {}.",
                        spawnGuid,
                        segmentId);

                    continue;
                }

                if (!flags ||
                    (flags &
                        ~ManastormSegmentSpawnFlags::KnownMask))
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid authored spawn {} for segment {}: "
                        "flags=0x{:X} contains no known role or unknown bits.",
                        spawnGuid,
                        segmentId,
                        flags);

                    valid = false;
                    continue;
                }

                bool const routeCreature =
                    (flags &
                        ManastormSegmentSpawnFlags::RouteCreature) != 0;

                uint32 const dependentRoles =
                    ManastormSegmentSpawnFlags::ChaoticLinkEligible |
                    ManastormSegmentSpawnFlags::RandomizationSlot |
                    ManastormSegmentSpawnFlags::CreaturePoolSource |
                    ManastormSegmentSpawnFlags::AffixEligible;

                if (!routeCreature &&
                    (flags & dependentRoles))
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid authored spawn {} for segment {}: "
                        "Chaotic Link/randomization/pool-source/affix roles require "
                        "RouteCreature.",
                        spawnGuid,
                        segmentId);

                    valid = false;
                    continue;
                }

                if (!spawnGuid ||
                    spawnMap ==
                    std::numeric_limits<uint32>::max() ||
                    !spawnEntry)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid authored route spawn for segment {}: "
                        "spawn_guid={} does not resolve to a creature DB spawn.",
                        segmentId,
                        spawnGuid);

                    valid = false;
                    continue;
                }

                if (spawnMap !=
                    segment->MapId)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid authored spawn {} for segment {}: "
                        "creature is on map {}, but segment uses map {}.",
                        spawnGuid,
                        segmentId,
                        spawnMap,
                        segment->MapId);

                    valid = false;
                    continue;
                }

                // The objective remains fixed to the selected segment and is
                // never part of the route-trash/randomization roster.
                if (spawnEntry ==
                    segment->ObjectiveCreatureEntry)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid authored route spawn {} for segment {}: "
                        "spawn entry {} is the objective boss itself.",
                        spawnGuid,
                        segmentId,
                        spawnEntry);

                    valid = false;
                    continue;
                }

                if (routeCreature)
                {
                    segment->RouteSpawnIds.push_back(
                        spawnGuid);
                }

                if (flags &
                    ManastormSegmentSpawnFlags::ChaoticLinkEligible)
                {
                    segment->ChaoticLinkSpawnIds.push_back(
                        spawnGuid);
                }

                if (flags &
                    ManastormSegmentSpawnFlags::RandomizationSlot)
                {
                    segment->RandomizationSpawnIds.push_back(
                        spawnGuid);
                }

                if (flags &
                    ManastormSegmentSpawnFlags::CreaturePoolSource)
                {
                    segment->CreaturePoolSourceSpawnIds.push_back(
                        spawnGuid);
                }

                if (flags &
                    ManastormSegmentSpawnFlags::AffixEligible)
                {
                    segment->AffixEligibleSpawnIds.push_back(
                        spawnGuid);
                }

                ++loadedRows;
            } while (result->NextRow());
        }
    }

    for (ManastormSegment const& segment :
        _segments)
    {
        if (std::size_t(
            segment.ChaoticLinkStacks) >
            segment.ChaoticLinkSpawnIds.size())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm segment {} has {} Chaotic Links but only {} "
                "enabled Link-breaking route spawns. The boss could not "
                "be fully weakened.",
                segment.SegmentId,
                uint32(segment.ChaoticLinkStacks),
                segment.ChaoticLinkSpawnIds.size());

            valid = false;
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm segment-spawn role rows from {} "
        "configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadCreaturePools()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_creature_pool`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_creature_pool`. "
            "Apply 05_manastorm_segment_pool_architecture.sql before starting.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    if (configuredRows)
    {
        QueryResult result =
            WorldDatabase.Query(
                "SELECT `pool_id`, `name` "
                "FROM `manastorm_creature_pool` "
                "WHERE `enabled` = 1 "
                "ORDER BY `pool_id`");

        if (result)
        {
            do
            {
                Field* fields =
                    result->Fetch();

                ManastormCreaturePoolDefinition pool;
                pool.PoolId =
                    fields[0].Get<uint32>();
                pool.Name =
                    fields[1].Get<std::string>();

                if (!pool.PoolId)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Ignoring Manastorm creature pool with pool_id=0.");

                    continue;
                }

                if (!_creaturePools.emplace(
                    pool.PoolId,
                    std::move(pool)).second)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Duplicate Manastorm creature pool id {}.",
                        fields[0].Get<uint32>());

                    return false;
                }
            } while (result->NextRow());
        }
    }

    QueryResult sourceCountResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_creature_pool_segment`");

    if (!sourceCountResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_creature_pool_segment`.");

        return false;
    }

    uint64 const configuredSourceRows =
        sourceCountResult->Fetch()[0].Get<uint64>();

    std::size_t loadedSourceRows = 0;
    bool valid = true;

    if (configuredSourceRows)
    {
        QueryResult result =
            WorldDatabase.Query(
                "SELECT `pool_id`, `segment_id` "
                "FROM `manastorm_creature_pool_segment` "
                "WHERE `enabled` = 1 "
                "ORDER BY `pool_id`, `segment_id`");

        if (result)
        {
            do
            {
                Field* fields =
                    result->Fetch();

                uint32 const poolId =
                    fields[0].Get<uint32>();

                uint32 const segmentId =
                    fields[1].Get<uint32>();

                auto poolItr =
                    _creaturePools.find(poolId);

                if (poolItr ==
                    _creaturePools.end())
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Creature-pool source row references unknown or "
                        "disabled pool {}.",
                        poolId);

                    valid = false;
                    continue;
                }

                ManastormSegment const* segment =
                    GetSegmentById(segmentId);

                if (!segment)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Creature pool {} references unknown or disabled "
                        "source segment {}.",
                        poolId,
                        segmentId);

                    valid = false;
                    continue;
                }

                poolItr->second.SourceSegmentIds.push_back(
                    segmentId);

                ++loadedSourceRows;
            } while (result->NextRow());
        }
    }

    // Materialize the distinct native creature entries contributed by
    // authored CreaturePoolSource spawn roles. This is a data-resolution step
    // only; no runtime creature replacement is performed here.
    QueryResult candidateResult =
        WorldDatabase.Query(
            "SELECT DISTINCT "
            "p.`pool_id`, "
            "c.`id` "
            "FROM `manastorm_creature_pool_segment` p "
            "INNER JOIN `manastorm_segment_spawn` s "
            "ON s.`segment_id` = p.`segment_id` "
            "INNER JOIN `creature` c "
            "ON c.`guid` = s.`spawn_guid` "
            "WHERE p.`enabled` = 1 "
            "AND s.`enabled` = 1 "
            "AND (s.`flags` & {}) <> 0 "
            "ORDER BY p.`pool_id`, c.`id`",
            ManastormSegmentSpawnFlags::CreaturePoolSource);

    if (candidateResult)
    {
        do
        {
            Field* fields =
                candidateResult->Fetch();

            uint32 const poolId =
                fields[0].Get<uint32>();

            uint32 const creatureEntry =
                fields[1].Get<uint32>();

            auto poolItr =
                _creaturePools.find(poolId);

            if (poolItr ==
                _creaturePools.end())
            {
                continue;
            }

            if (!creatureEntry ||
                !sObjectMgr->GetCreatureTemplate(
                    creatureEntry))
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Creature pool {} resolves invalid creature entry {} "
                    "from an authored source spawn.",
                    poolId,
                    creatureEntry);

                valid = false;
                continue;
            }

            poolItr->second.CreatureEntries.push_back(
                creatureEntry);
        } while (candidateResult->NextRow());
    }

    for (auto const& pair :
        _creaturePools)
    {
        ManastormCreaturePoolDefinition const& pool =
            pair.second;

        if (pool.SourceSegmentIds.empty())
        {
            LOG_WARN(
                LOG_FILTER,
                "Manastorm creature pool {} ({}) has no enabled source "
                "segments. Ownership can be stored, but it currently "
                "contributes no candidate creatures.",
                pool.PoolId,
                pool.Name);

            continue;
        }

        std::size_t sourceSpawnCount = 0;

        for (uint32 segmentId :
            pool.SourceSegmentIds)
        {
            ManastormSegment const* segment =
                GetSegmentById(segmentId);

            if (segment)
            {
                sourceSpawnCount +=
                    segment->CreaturePoolSourceSpawnIds.size();
            }
        }

        if (!sourceSpawnCount)
        {
            LOG_WARN(
                LOG_FILTER,
                "Manastorm creature pool {} ({}) has source segments but "
                "none of their authored spawns are flagged "
                "CreaturePoolSource.",
                pool.PoolId,
                pool.Name);
        }
        else if (pool.CreatureEntries.empty())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm creature pool {} ({}) has {} source spawn(s) "
                "but resolves no valid creature entries.",
                pool.PoolId,
                pool.Name,
                sourceSpawnCount);

            valid = false;
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm creature pools with {} enabled "
        "pool-to-segment source rows and derived candidate entries "
        "from {} configured source rows.",
        _creaturePools.size(),
        loadedSourceRows,
        configuredSourceRows);

    return valid;
}

bool ManastormDataStore::LoadUnlocks()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_unlock`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_unlock`.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    if (!configuredRows)
    {
        LOG_WARN(
            LOG_FILTER,
            "`manastorm_unlock` contains no rows. "
            "Only STARTING_UNLOCKED segments will be available.");

        return true;
    }

    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "`unlock_id`, "
            "`unlock_kind`, "
            "`trigger_depth`, "
            "`mode_mask`, "
            "`track_mask`, "
            "`intro_segment_id`, "
            "`endgame_intro_segment_id`, "
            "`intro_message_id`, "
            "`completion_message_id`, "
            "EXISTS (SELECT 1 FROM `manastorm_segment` AS `s` "
            "WHERE `s`.`segment_id` = `u`.`intro_segment_id` AND `s`.`enabled` = 0), "
            "EXISTS (SELECT 1 FROM `manastorm_segment` AS `s` "
            "WHERE `s`.`segment_id` = `u`.`endgame_intro_segment_id` AND `s`.`enabled` = 0), "
            "EXISTS (SELECT 1 FROM `manastorm_unlock_grant` AS `g` "
            "LEFT JOIN `manastorm_segment` AS `s` ON `s`.`segment_id` = `g`.`content_id` "
            "WHERE `g`.`unlock_id` = `u`.`unlock_id` AND `g`.`enabled` = 1 "
            "AND (`g`.`grant_type` <> 1 OR `s`.`enabled` = 1)), "
            "EXISTS (SELECT 1 FROM `manastorm_unlock_grant` AS `g` "
            "WHERE `g`.`unlock_id` = `u`.`unlock_id` AND `g`.`enabled` = 1) "
            "FROM `manastorm_unlock` AS `u` "
            "WHERE `enabled` = 1 "
            "ORDER BY `unlock_id`");

    if (!result)
    {
        LOG_INFO(
            LOG_FILTER,
            "`manastorm_unlock` contains no enabled rows.");

        return true;
    }

    bool valid = true;

    do
    {
        Field* fields =
            result->Fetch();

        ManastormUnlockDefinition definition;

        definition.UnlockId =
            fields[0].Get<uint32>();

        uint8 const unlockKindRaw =
            fields[1].Get<uint8>();

        definition.TriggerDepth =
            fields[2].Get<uint32>();

        definition.ModeMask =
            fields[3].Get<uint8>();

        definition.TrackMask =
            fields[4].Get<uint8>();

        definition.IntroSegmentId =
            fields[5].Get<uint32>();

        definition.EndgameIntroSegmentId =
            fields[6].Get<uint32>();

        definition.IntroMessageId =
            fields[7].Get<uint32>();

        definition.CompletionMessageId =
            fields[8].Get<uint32>();

        if (!definition.UnlockId)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock: unlock_id=0.");

            valid = false;
            continue;
        }

        if (unlockKindRaw >
            uint8(ManastormUnlockKind::Direct))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock {}: unlock_kind={}.",
                definition.UnlockId,
                uint32(unlockKindRaw));

            valid = false;
            continue;
        }

        definition.Kind =
            ManastormUnlockKind(
                unlockKindRaw);

        if (!definition.TriggerDepth)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock {}: "
                "trigger_depth must be at least 1.",
                definition.UnlockId);

            valid = false;
            continue;
        }

        if (!definition.ModeMask ||
            (uint32(definition.ModeMask) & ~0x0Fu) != 0)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock {}: "
                "mode_mask={} contains unsupported bits.",
                definition.UnlockId,
                uint32(definition.ModeMask));

            valid = false;
            continue;
        }

        if (!definition.TrackMask ||
            (uint32(definition.TrackMask) &
                ~uint32(ManastormTrackBits::All)) != 0)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock {}: "
                "track_mask={} contains unsupported bits.",
                definition.UnlockId,
                uint32(definition.TrackMask));

            valid = false;
            continue;
        }

        // Disabled segments retain their SQL gates without becoming playable.
        // An enabled but invalid segment is still a configuration error.
        if (definition.Kind == ManastormUnlockKind::Introduction)
        {
            if (fields[9].Get<bool>())
                definition.TrackMask &= ~ManastormTrackBits::Normal;
            if (fields[10].Get<bool>())
                definition.TrackMask &= ~ManastormTrackBits::Endgame;
            if (!definition.TrackMask)
                continue;
        }

        if (definition.Kind ==
            ManastormUnlockKind::Direct)
        {
            // Defer direct segment grants until at least one target is enabled.
            // Missing grants still reach the ordinary validation below.
            if (fields[12].Get<bool>() && !fields[11].Get<bool>())
                continue;

            if (definition.IntroSegmentId ||
                definition.EndgameIntroSegmentId ||
                definition.IntroMessageId)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Invalid direct Manastorm unlock {}: "
                    "intro segment/message fields must be 0.",
                    definition.UnlockId);

                valid = false;
                continue;
            }

            _unlocks.emplace(
                definition.UnlockId,
                std::move(definition));

            continue;
        }

        if (definition.TrackMask &
            ManastormTrackBits::Normal)
        {
            ManastormSegment const* intro =
                GetSegmentById(
                    definition.IntroSegmentId);

            if (!intro ||
                intro->Difficulty != 0)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Invalid Manastorm unlock {}: "
                    "normal intro segment {} must be an enabled "
                    "difficulty-0 Manastorm segment.",
                    definition.UnlockId,
                    definition.IntroSegmentId);

                valid = false;
                continue;
            }
        }

        if (definition.TrackMask &
            ManastormTrackBits::Endgame)
        {
            ManastormSegment const* intro =
                GetSegmentById(
                    definition.EndgameIntroSegmentId);

            if (!intro ||
                intro->Difficulty != 2)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Invalid Manastorm unlock {}: "
                    "end-game intro segment {} must be an enabled "
                    "difficulty-2 Manastorm segment.",
                    definition.UnlockId,
                    definition.EndgameIntroSegmentId);

                valid = false;
                continue;
            }
        }

        bool conflict = false;

        for (auto const& existingPair :
            _unlocks)
        {
            ManastormUnlockDefinition const& existing =
                existingPair.second;

            if (existing.TriggerDepth !=
                definition.TriggerDepth)
            {
                continue;
            }

            if (!(existing.ModeMask &
                definition.ModeMask))
            {
                continue;
            }

            if (!(existing.TrackMask &
                definition.TrackMask))
            {
                continue;
            }

            LOG_ERROR(
                LOG_FILTER,
                "Manastorm unlock {} conflicts with "
                "unlock {} at trigger depth {}. "
                "Their mode and native-track masks overlap.",
                definition.UnlockId,
                existing.UnlockId,
                definition.TriggerDepth);

            valid = false;
            conflict = true;
            break;
        }

        if (conflict)
            continue;

        _unlocks.emplace(
            definition.UnlockId,
            std::move(definition));
    } while (result->NextRow());

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm progression "
        "unlocks from {} configured rows.",
        _unlocks.size(),
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadUnlockTriggers()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_unlock_trigger`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_unlock_trigger`. "
            "Apply 06_manastorm_native_track_triggers.sql.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "`unlock_id`, "
            "`track`, "
            "`trigger_depth` "
            "FROM `manastorm_unlock_trigger` "
            "WHERE `enabled` = 1 "
            "ORDER BY `unlock_id`, `track`");

    bool valid = true;
    std::size_t loadedRows = 0;

    if (result)
    {
        do
        {
            Field* fields =
                result->Fetch();

            uint32 const unlockId =
                fields[0].Get<uint32>();

            uint8 const track =
                fields[1].Get<uint8>();

            uint32 const triggerDepth =
                fields[2].Get<uint32>();

            auto unlockItr =
                _unlocks.find(
                    unlockId);

            if (unlockItr ==
                _unlocks.end())
            {
                LOG_WARN(
                    LOG_FILTER,
                    "Ignoring native-track trigger for unknown or "
                    "disabled Manastorm unlock {}.",
                    unlockId);

                continue;
            }

            if ((track !=
                    ManastormTrackBits::Normal &&
                 track !=
                    ManastormTrackBits::Endgame) ||
                !triggerDepth)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Invalid Manastorm trigger: unlock={} track={} depth={}.",
                    unlockId,
                    uint32(track),
                    triggerDepth);

                valid = false;
                continue;
            }

            ManastormUnlockDefinition& unlock =
                unlockItr->second;

            if (!(unlock.TrackMask & track))
                continue;

            if (unlock.GetTriggerDepthForTrack(
                track))
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm unlock {} has duplicate enabled "
                    "trigger rows for track {}.",
                    unlockId,
                    uint32(track));

                valid = false;
                continue;
            }

            if (unlock.Kind ==
                ManastormUnlockKind::Introduction)
            {
                uint32 const introSegmentId =
                    track ==
                        ManastormTrackBits::Endgame
                    ? unlock.EndgameIntroSegmentId
                    : unlock.IntroSegmentId;

                uint8 const expectedDifficulty =
                    track ==
                        ManastormTrackBits::Endgame
                    ? uint8(2)
                    : uint8(0);

                ManastormSegment const* intro =
                    GetSegmentById(
                        introSegmentId);

                if (!intro ||
                    intro->Difficulty !=
                        expectedDifficulty)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Manastorm unlock {} track {} requires "
                        "difficulty-{} intro segment; configured segment={}.",
                        unlockId,
                        uint32(track),
                        uint32(expectedDifficulty),
                        introSegmentId);

                    valid = false;
                    continue;
                }

                bool conflict = false;

                for (auto const& otherPair :
                    _unlocks)
                {
                    if (otherPair.first ==
                        unlockId)
                    {
                        continue;
                    }

                    ManastormUnlockDefinition const& other =
                        otherPair.second;

                    if (other.Kind !=
                            ManastormUnlockKind::Introduction ||
                        !(other.ModeMask &
                            unlock.ModeMask) ||
                        other.GetTriggerDepthForTrack(
                            track) !=
                            triggerDepth)
                    {
                        continue;
                    }

                    LOG_ERROR(
                        LOG_FILTER,
                        "Manastorm introduction unlock {} conflicts with "
                        "unlock {} at depth {} on native track {}.",
                        unlockId,
                        other.UnlockId,
                        triggerDepth,
                        uint32(track));

                    valid = false;
                    conflict = true;
                    break;
                }

                if (conflict)
                    continue;
            }

            ManastormUnlockTrigger trigger;
            trigger.Track =
                track;
            trigger.TriggerDepth =
                triggerDepth;

            unlock.Triggers.push_back(
                trigger);

            ++loadedRows;
        } while (result->NextRow());
    }

    for (auto const& pair :
        _unlocks)
    {
        if (!pair.second.Triggers.empty())
            continue;

        LOG_ERROR(
            LOG_FILTER,
            "Enabled Manastorm unlock {} has no enabled "
            "native-track trigger rows.",
            pair.first);

        valid = false;
    }

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm native-track triggers "
        "from {} configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadUnlockGrants()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_unlock_grant`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_unlock_grant`.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    if (!configuredRows)
    {
        if (!_unlocks.empty())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm has progression unlocks "
                "but no unlock grants.");

            return false;
        }

        return true;
    }

    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "`g`.`unlock_id`, "
            "`g`.`grant_type`, "
            "`g`.`content_id`, "
            "CASE WHEN `s`.`enabled` = 0 THEN 1 ELSE 0 END "
            "FROM `manastorm_unlock_grant` AS `g` "
            "LEFT JOIN `manastorm_segment` AS `s` ON `s`.`segment_id` = `g`.`content_id` "
            "WHERE `g`.`enabled` = 1 "
            "ORDER BY "
            "`g`.`unlock_id`, "
            "`g`.`grant_type`, "
            "`g`.`content_id`");

    if (!result)
    {
        if (!_unlocks.empty())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm has enabled progression "
                "unlocks but no enabled grants.");

            return false;
        }

        return true;
    }

    bool valid = true;
    std::size_t loadedRows = 0;

    do
    {
        Field* fields =
            result->Fetch();

        uint32 const unlockId =
            fields[0].Get<uint32>();

        uint8 const grantTypeRaw =
            fields[1].Get<uint8>();

        uint32 const contentId =
            fields[2].Get<uint32>();

        auto unlockItr =
            _unlocks.find(unlockId);

        if (unlockItr == _unlocks.end())
        {
            LOG_WARN(
                LOG_FILTER,
                "Ignoring grant for unknown or disabled "
                "Manastorm unlock {}.",
                unlockId);

            continue;
        }

        if (grantTypeRaw <
            uint8(ManastormUnlockGrantType::Segment) ||
            grantTypeRaw >
            uint8(ManastormUnlockGrantType::Affix))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm grant type {} "
                "for unlock {}.",
                uint32(grantTypeRaw),
                unlockId);

            valid = false;
            continue;
        }

        if (!contentId)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm grant for unlock {}: "
                "content_id=0.",
                unlockId);

            valid = false;
            continue;
        }

        ManastormUnlockGrantType const grantType =
            ManastormUnlockGrantType(
                grantTypeRaw);

        if (grantType == ManastormUnlockGrantType::Segment && fields[3].Get<bool>())
            continue;

        if (grantType ==
            ManastormUnlockGrantType::Segment &&
            !GetSegmentById(contentId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm unlock {} grants segment {}, "
                "but that segment is not enabled/valid.",
                unlockId,
                contentId);

            valid = false;
            continue;
        }

        if (grantType ==
            ManastormUnlockGrantType::CreaturePool &&
            !GetCreaturePoolById(contentId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm unlock {} grants creature pool {}, "
                "but that pool is not enabled/valid.",
                unlockId,
                contentId);

            valid = false;
            continue;
        }

        if (grantType ==
                ManastormUnlockGrantType::Affix &&
            !GetAffixById(contentId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm unlock {} grants affix {}, "
                "but that affix is not enabled/valid.",
                unlockId,
                contentId);

            valid = false;
            continue;
        }

        if (grantType ==
            ManastormUnlockGrantType::BossPool)
        {
            LOG_WARN(
                LOG_FILTER,
                "Manastorm unlock {} uses reserved BossPool grant {}. "
                "Recovered objective progression uses Segment grants; "
                "this grant has no runtime effect.",
                unlockId,
                contentId);
        }

        ManastormUnlockGrant grant;

        grant.Type =
            grantType;

        grant.ContentId =
            contentId;

        unlockItr->second.Grants.push_back(
            grant);

        ++loadedRows;
    } while (result->NextRow());

    for (auto const& pair :
        _unlocks)
    {
        if (!pair.second.Grants.empty())
            continue;

        LOG_ERROR(
            LOG_FILTER,
            "Manastorm unlock {} has no enabled grants.",
            pair.first);

        valid = false;
    }

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm unlock grants "
        "from {} configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadAffixes()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) FROM `manastorm_affix_catalog`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_affix_catalog`. "
            "Apply the Manastorm affix SQL before starting.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "`affix_id`, `name`, `unlock_depth`, "
            "`availability_kind`, `target_mask`, `runtime_type`, "
            "`root_spell_id`, `death_trigger_spell_id`, "
            "`secondary_death_trigger_spell_id`, "
            "`helper_creature_entry_1`, `helper_creature_entry_2`, "
            "`max_rank`, `apply_marker_aura`, `bounded_runtime`, "
            "`automatic_selection`, `selection_weight`, "
            "`normal_message_id`, `endgame_message_id` "
            "FROM `manastorm_affix_catalog` "
            "WHERE `enabled` = 1 "
            "ORDER BY `affix_id`");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm affix catalog contains no enabled rows.");

        return false;
    }

    bool valid = true;
    uint64 loadedRows = 0;

    do
    {
        Field* fields = result->Fetch();

        ManastormAffixDefinition definition;
        definition.AffixId = fields[0].Get<uint32>();
        definition.Name = fields[1].Get<std::string>();
        definition.UnlockDepth = fields[2].Get<uint32>();

        uint8 const availabilityRaw =
            fields[3].Get<uint8>();

        definition.TargetMask =
            fields[4].Get<uint8>();

        uint8 const runtimeRaw =
            fields[5].Get<uint8>();

        definition.MarkerSpellId =
            fields[6].Get<uint32>();

        definition.DeathTriggerSpellId =
            fields[7].Get<uint32>();

        definition.SecondaryDeathTriggerSpellId =
            fields[8].Get<uint32>();

        definition.HelperCreatureEntry1 =
            fields[9].Get<uint32>();

        definition.HelperCreatureEntry2 =
            fields[10].Get<uint32>();

        definition.MaxRank =
            fields[11].Get<uint8>();

        definition.ApplyMarkerAura =
            fields[12].Get<uint8>() != 0;

        definition.BoundedRuntime =
            fields[13].Get<uint8>() != 0;

        definition.AutomaticSelection =
            fields[14].Get<uint8>() != 0;

        definition.SelectionWeight =
            fields[15].Get<uint32>();

        definition.NormalMessageId =
            fields[16].Get<uint32>();

        definition.EndgameMessageId =
            fields[17].Get<uint32>();

        if (!definition.AffixId ||
            !definition.MarkerSpellId ||
            availabilityRaw >
                uint8(ManastormAffixAvailabilityKind::ForcedOnly) ||
            !definition.TargetMask ||
            (definition.TargetMask &
                ~ManastormAffixTargetBits::KnownMask) ||
            runtimeRaw <
                uint8(ManastormAffixRuntimeType::OnDeath) ||
            runtimeRaw >
                uint8(ManastormAffixRuntimeType::SpawnedHazard) ||
            definition.MaxRank > 20 ||
            (definition.AutomaticSelection &&
                !definition.SelectionWeight))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm affix catalogue row id={} name='{}'.",
                definition.AffixId,
                definition.Name);

            valid = false;
            continue;
        }

        definition.Availability =
            ManastormAffixAvailabilityKind(
                availabilityRaw);

        definition.RuntimeType =
            ManastormAffixRuntimeType(
                runtimeRaw);

        if (definition.Availability ==
                ManastormAffixAvailabilityKind::ProgressionUnlock &&
            !definition.UnlockDepth)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Progression-owned Manastorm affix {} ({}) "
                "has unlock_depth=0.",
                definition.AffixId,
                definition.Name);

            valid = false;
            continue;
        }

        if (!_affixes.emplace(
                definition.AffixId,
                std::move(definition)).second)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Duplicate Manastorm affix id {}.",
                fields[0].Get<uint32>());

            valid = false;
            continue;
        }

        ++loadedRows;
    }
    while (result->NextRow());

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm affixes from {} configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadAffixRankSpells()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) FROM `manastorm_affix_rank_spell`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_affix_rank_spell`.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    if (!configuredRows)
        return true;

    QueryResult result =
        WorldDatabase.Query(
            "SELECT `affix_id`, `role`, `rank`, `spell_id` "
            "FROM `manastorm_affix_rank_spell` "
            "ORDER BY `affix_id`, `role`, `rank`");

    if (!result)
        return true;

    bool valid = true;
    uint64 loadedRows = 0;

    do
    {
        Field* fields = result->Fetch();

        uint32 const affixId =
            fields[0].Get<uint32>();

        uint8 const role =
            fields[1].Get<uint8>();

        uint8 const rank =
            fields[2].Get<uint8>();

        uint32 const spellId =
            fields[3].Get<uint32>();

        auto itr =
            _affixes.find(affixId);

        if (itr == _affixes.end())
        {
            LOG_WARN(
                LOG_FILTER,
                "Ignoring rank spell for disabled/unknown "
                "Manastorm affix {}.",
                affixId);

            continue;
        }

        if (!role ||
            !rank ||
            !spellId ||
            (itr->second.MaxRank &&
                rank > itr->second.MaxRank))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm affix rank row: "
                "affix={} role={} rank={} spell={}.",
                affixId,
                uint32(role),
                uint32(rank),
                spellId);

            valid = false;
            continue;
        }

        itr->second.RankSpells.push_back(
            { role, rank, spellId });

        ++loadedRows;
    }
    while (result->NextRow());

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} Manastorm affix rank-spell rows "
        "from {} configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadAffixPolicies()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) FROM `manastorm_affix_policy`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_affix_policy`. "
            "Apply 21_manastorm_affix_engine_v6.sql.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "`policy_id`, `min_depth`, `max_depth`, "
            "`creature_stage_affix_count`, "
            "`creature_affix_chance_pct`, "
            "`second_affix_chance_pct`, "
            "`boss_affix_chance_pct`, "
            "`environment_stage_affix_count`, "
            "`default_rank` "
            "FROM `manastorm_affix_policy` "
            "WHERE `enabled` = 1 "
            "ORDER BY `min_depth`, `policy_id`");

    if (!result)
    {
        LOG_WARN(
            LOG_FILTER,
            "No enabled Manastorm affix policy rows. "
            "Automatic affix selection will remain disabled.");

        return true;
    }

    bool valid = true;
    uint32 previousMaxDepth = 0;
    bool previousUnbounded = false;
    uint64 loadedRows = 0;

    do
    {
        Field* fields = result->Fetch();

        ManastormAffixPolicy policy;
        policy.PolicyId = fields[0].Get<uint32>();
        policy.MinDepth = fields[1].Get<uint32>();
        policy.MaxDepth = fields[2].Get<uint32>();
        policy.CreatureStageAffixCount =
            fields[3].Get<uint8>();
        policy.CreatureAffixChancePct =
            fields[4].Get<float>();
        policy.SecondAffixChancePct =
            fields[5].Get<float>();
        policy.BossAffixChancePct =
            fields[6].Get<float>();
        policy.EnvironmentStageAffixCount =
            fields[7].Get<uint8>();
        policy.DefaultRank =
            fields[8].Get<uint8>();

        auto validChance = [](float value)
        {
            return std::isfinite(value) &&
                value >= 0.0f &&
                value <= 100.0f;
        };

        if (!policy.PolicyId ||
            !policy.MinDepth ||
            (policy.MaxDepth &&
                policy.MaxDepth < policy.MinDepth) ||
            !validChance(policy.CreatureAffixChancePct) ||
            !validChance(policy.SecondAffixChancePct) ||
            !validChance(policy.BossAffixChancePct) ||
            !policy.DefaultRank ||
            policy.DefaultRank > 20 ||
            previousUnbounded ||
            (previousMaxDepth &&
                policy.MinDepth <= previousMaxDepth))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid/overlapping Manastorm affix policy id={} "
                "depth={}..{}.",
                policy.PolicyId,
                policy.MinDepth,
                policy.MaxDepth);

            valid = false;
            continue;
        }

        previousMaxDepth =
            policy.MaxDepth;

        previousUnbounded =
            policy.MaxDepth == 0;

        _affixPolicies.push_back(
            policy);

        ++loadedRows;
    }
    while (result->NextRow());

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm affix policies "
        "from {} configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

bool ManastormDataStore::LoadScalingCurve()
{
    QueryResult countResult = WorldDatabase.Query(
        "SELECT COUNT(*) FROM `manastorm_scaling_curve`");

    if (!countResult)
    {
        LOG_ERROR(LOG_FILTER,
            "Unable to query `manastorm_scaling_curve`. The table is missing or inaccessible.");
        return false;
    }

    uint64 const configuredRows = countResult->Fetch()[0].Get<uint64>();
    if (!configuredRows)
    {
        LOG_WARN(LOG_FILTER,
            "`manastorm_scaling_curve` is empty. "
            "Depths without a curve point will use neutral 1.0 multipliers.");
        return true;
    }

    QueryResult result = WorldDatabase.Query(
        "SELECT "
        "`depth`, `health_multiplier`, `global_damage_multiplier`, "
        "`melee_multiplier`, `spell_multiplier` "
        "FROM `manastorm_scaling_curve` "
        "ORDER BY `depth`");

    if (!result)
        return true;

    do
    {
        Field* fields = result->Fetch();

        ManastormScalingPoint point;
        point.Depth = fields[0].Get<uint32>();
        point.HealthMultiplier = fields[1].Get<float>();
        point.GlobalDamageMultiplier = fields[2].Get<float>();
        point.MeleeMultiplier = fields[3].Get<float>();
        point.SpellMultiplier = fields[4].Get<float>();

        if (!point.Depth)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm scaling row with depth=0.");
            continue;
        }

        if (!IsValidPositiveMultiplier(point.HealthMultiplier) ||
            !IsValidPositiveMultiplier(point.GlobalDamageMultiplier) ||
            !IsValidPositiveMultiplier(point.MeleeMultiplier) ||
            !IsValidPositiveMultiplier(point.SpellMultiplier))
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm scaling depth {}: all multipliers must be finite and greater than 0.",
                point.Depth);
            continue;
        }

        _scalingCurve[point.Depth] = point;
    }
    while (result->NextRow());

    LOG_INFO(LOG_FILTER,
        "Loaded {} valid Manastorm scaling points from {} configured rows.",
        _scalingCurve.size(), configuredRows);

    return true;
}

bool ManastormDataStore::LoadGroupScaling()
{
    QueryResult countResult = WorldDatabase.Query(
        "SELECT COUNT(*) FROM `manastorm_group_scaling`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_group_scaling`. "
            "The table is missing or inaccessible.");
        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    if (!configuredRows)
    {
        LOG_INFO(
            LOG_FILTER,
            "`manastorm_group_scaling` is empty. "
            "Member-count scaling will use neutral 1.0 multipliers.");
        return true;
    }

    QueryResult result = WorldDatabase.Query(
        "SELECT "
        "`min_members`, `max_members`, "
        "`health_multiplier`, `global_damage_multiplier`, "
        "`melee_multiplier`, `spell_multiplier` "
        "FROM `manastorm_group_scaling` "
        "WHERE `enabled` = 1 "
        "ORDER BY `min_members`, `max_members`");

    if (!result)
    {
        LOG_INFO(
            LOG_FILTER,
            "`manastorm_group_scaling` contains no enabled rows. "
            "Member-count scaling will use neutral 1.0 multipliers.");
        return true;
    }

    bool valid = true;
    uint32 previousMaxMembers = 0;
    uint64 loadedRows = 0;

    do
    {
        Field* fields = result->Fetch();

        ManastormGroupScalingRange range;
        range.MinMembers = fields[0].Get<uint8>();
        range.MaxMembers = fields[1].Get<uint8>();
        range.HealthMultiplier = fields[2].Get<float>();
        range.GlobalDamageMultiplier = fields[3].Get<float>();
        range.MeleeMultiplier = fields[4].Get<float>();
        range.SpellMultiplier = fields[5].Get<float>();

        if (!range.MinMembers ||
            range.MaxMembers < range.MinMembers ||
            range.MaxMembers > ManastormLimits::MaxMembers)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm group scaling range {}-{}. "
                "Enabled ranges must stay within 1-{}.",
                uint32(range.MinMembers),
                uint32(range.MaxMembers),
                ManastormLimits::MaxMembers);

            valid = false;
            continue;
        }

        if (!IsValidPositiveMultiplier(range.HealthMultiplier) ||
            !IsValidPositiveMultiplier(range.GlobalDamageMultiplier) ||
            !IsValidPositiveMultiplier(range.MeleeMultiplier) ||
            !IsValidPositiveMultiplier(range.SpellMultiplier))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm group scaling range {}-{}: "
                "all multipliers must be finite and greater than 0.",
                uint32(range.MinMembers),
                uint32(range.MaxMembers));

            valid = false;
            continue;
        }

        if (previousMaxMembers &&
            range.MinMembers <= previousMaxMembers)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Overlapping Manastorm group scaling range {}-{}. "
                "Enabled member-count ranges must not overlap.",
                uint32(range.MinMembers),
                uint32(range.MaxMembers));

            valid = false;
            continue;
        }

        previousMaxMembers =
            range.MaxMembers;

        _groupScalingRanges.push_back(
            range);

        ++loadedRows;
    }
    while (result->NextRow());

    LOG_INFO(
        LOG_FILTER,
        "Loaded {} enabled Manastorm group scaling ranges "
        "from {} configured rows.",
        loadedRows,
        configuredRows);

    return valid;
}

ManastormScalingPoint ManastormDataStore::GetScalingForDepth(uint32 depth) const
{
    ManastormScalingPoint neutral;
    neutral.Depth = depth;

    if (!depth || _scalingCurve.empty())
        return neutral;

    // Curve rows are breakpoints. Use the newest configured point at or below
    // the requested depth. This lets us tune depth brackets without requiring
    // one SQL row for every possible Endless depth.
    auto itr = _scalingCurve.upper_bound(depth);
    if (itr == _scalingCurve.begin())
        return neutral;

    --itr;
    ManastormScalingPoint point = itr->second;
    point.Depth = depth;
    return point;
}

ManastormScalingPoint ManastormDataStore::GetScalingForDepth(
    uint32 depth,
    uint32 memberCount) const
{
    ManastormScalingPoint effective =
        GetScalingForDepth(depth);

    if (!memberCount ||
        memberCount > ManastormLimits::MaxMembers)
    {
        return effective;
    }

    for (ManastormGroupScalingRange const& range :
        _groupScalingRanges)
    {
        if (!range.Matches(memberCount))
            continue;

        effective.HealthMultiplier *=
            range.HealthMultiplier;

        effective.GlobalDamageMultiplier *=
            range.GlobalDamageMultiplier;

        effective.MeleeMultiplier *=
            range.MeleeMultiplier;

        effective.SpellMultiplier *=
            range.SpellMultiplier;

        break;
    }

    return effective;
}

ManastormHubReturn const*
ManastormDataStore::GetHubReturn(
    uint8 teamId) const
{
    auto itr =
        _hubReturns.find(teamId);

    return itr == _hubReturns.end()
        ? nullptr
        : &itr->second;
}

ManastormSegment const*
ManastormDataStore::GetSegmentById(
    uint32 segmentId) const
{
    for (ManastormSegment const& segment :
        _segments)
    {
        if (segment.SegmentId ==
            segmentId)
        {
            return &segment;
        }
    }

    return nullptr;
}

ManastormCreaturePoolDefinition const*
ManastormDataStore::GetCreaturePoolById(
    uint32 poolId) const
{
    auto itr =
        _creaturePools.find(poolId);

    return itr == _creaturePools.end()
        ? nullptr
        : &itr->second;
}

ManastormAffixDefinition const*
ManastormDataStore::GetAffixById(
    uint32 affixId) const
{
    auto itr =
        _affixes.find(affixId);

    return itr == _affixes.end()
        ? nullptr
        : &itr->second;
}

ManastormAffixPolicy const*
ManastormDataStore::GetAffixPolicyForDepth(
    uint32 depth) const
{
    for (ManastormAffixPolicy const& policy :
        _affixPolicies)
    {
        if (policy.Matches(depth))
            return &policy;
    }

    return nullptr;
}

ManastormUnlockDefinition const*
ManastormDataStore::GetUnlockById(
    uint32 unlockId) const
{
    auto itr =
        _unlocks.find(unlockId);

    if (itr == _unlocks.end())
        return nullptr;

    return &itr->second;
}

ManastormUnlockDefinition const*
ManastormDataStore::GetUnlockForTrigger(
    uint32 completedDepth,
    ManastormMode mode,
    bool endgame) const
{
    uint8 const modeBit =
        ManastormGetModeBit(mode);

    uint8 const trackBit =
        ManastormGetTrackBit(endgame);

    if (!completedDepth ||
        !modeBit ||
        !trackBit)
    {
        return nullptr;
    }

    for (auto const& pair :
        _unlocks)
    {
        ManastormUnlockDefinition const& unlock =
            pair.second;

        if (unlock.Kind !=
            ManastormUnlockKind::Introduction)
        {
            continue;
        }

        if (unlock.GetTriggerDepthForTrack(
            trackBit) !=
            completedDepth)
        {
            continue;
        }

        if (!(unlock.ModeMask &
            modeBit))
        {
            continue;
        }

        return &unlock;
    }

    return nullptr;
}

std::vector<ManastormUnlockDefinition const*>
ManastormDataStore::GetDirectUnlocksForTrigger(
    uint32 completedDepth,
    ManastormMode mode,
    bool endgame) const
{
    std::vector<ManastormUnlockDefinition const*> matches;

    uint8 const modeBit =
        ManastormGetModeBit(mode);

    uint8 const trackBit =
        ManastormGetTrackBit(endgame);

    if (!completedDepth ||
        !modeBit ||
        !trackBit)
    {
        return matches;
    }

    for (auto const& pair :
        _unlocks)
    {
        ManastormUnlockDefinition const& unlock =
            pair.second;

        if (unlock.Kind !=
            ManastormUnlockKind::Direct)
        {
            continue;
        }

        if (unlock.GetTriggerDepthForTrack(
            trackBit) !=
            completedDepth)
        {
            continue;
        }

        if (!(unlock.ModeMask &
            modeBit))
        {
            continue;
        }

        matches.push_back(
            &unlock);
    }

    return matches;
}
