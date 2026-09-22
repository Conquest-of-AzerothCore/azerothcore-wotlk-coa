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

bool ManastormDataStore::Load()
{
    _loaded = false;

    _segments.clear();
    _scalingCurve.clear();
    _creaturePools.clear();
    _unlocks.clear();

    bool const segmentsLoaded =
        LoadSegments();

    bool const segmentSpawnsLoaded =
        segmentsLoaded &&
        LoadSegmentSpawns();

    bool const creaturePoolsLoaded =
        segmentSpawnsLoaded &&
        LoadCreaturePools();

    bool const scalingLoaded =
        LoadScalingCurve();

    bool const unlocksLoaded =
        segmentsLoaded &&
        LoadUnlocks();

    bool const unlockGrantsLoaded =
        unlocksLoaded &&
        creaturePoolsLoaded &&
        LoadUnlockGrants();

    _loaded =
        segmentsLoaded &&
        segmentSpawnsLoaded &&
        creaturePoolsLoaded &&
        scalingLoaded &&
        unlocksLoaded &&
        unlockGrantsLoaded;

    if (_loaded)
    {
        LOG_INFO(
            LOG_FILTER,
            "Manastorm datastore loaded: {} segments, "
            "{} creature pools, {} scaling points, {} progression unlocks.",
            _segments.size(),
            _creaturePools.size(),
            _scalingCurve.size(),
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
        "`segment_id`, `map_id`, `difficulty`, `dungeon_encounter_id`, "
        "`objective_creature_entry`, `start_game_tele_id`, `weight`, "
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
        segment.MapId = fields[1].Get<uint32>();
        segment.Difficulty = fields[2].Get<uint8>();
        segment.DungeonEncounterId = fields[3].Get<uint32>();
        segment.ObjectiveCreatureEntry = fields[4].Get<uint32>();
        segment.StartGameTeleId = fields[5].Get<uint32>();
        segment.Weight = fields[6].Get<uint32>();
        segment.MinDepth = fields[7].Get<uint32>();
        segment.MaxDepth = fields[8].Get<uint32>();
        segment.RewardMultiplier = fields[9].Get<float>();
        segment.ChaoticLinkStacks = fields[10].Get<uint8>();
        segment.Flags = fields[11].Get<uint32>();

        if (!segment.SegmentId)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment with segment_id=0.");
            continue;
        }

        if (!segment.ObjectiveCreatureEntry)
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: objective_creature_entry is 0.",
                segment.SegmentId);
            continue;
        }

        if (!sObjectMgr->GetCreatureTemplate(segment.ObjectiveCreatureEntry))
        {
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: objective creature entry {} does not exist.",
                segment.SegmentId, segment.ObjectiveCreatureEntry);
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
            LOG_ERROR(LOG_FILTER,
                "Ignoring Manastorm segment {}: map_id={} but game_tele id {} points to map {}.",
                segment.SegmentId, segment.MapId, segment.StartGameTeleId, tele->mapId);
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
            auto const identity = nativeIdentities.find(segment.SegmentId);
            if (identity == nativeIdentities.end() || identity->second[1] != segment.MapId
                || identity->second[2] != segment.Difficulty || identity->second[3] != segment.DungeonEncounterId)
            {
                LOG_ERROR(LOG_FILTER, "Ignoring Mode 2 segment {}: segment_id/map_id/difficulty/"
                    "dungeon_encounter_id must match the original Manastorm.dbc row.", segment.SegmentId);
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
        MapEntry const* map = sMapStore.LookupEntry(segment.MapId);
        if (!map || !map->IsDungeon()
            || !GetMapDifficultyData(segment.MapId, Difficulty(segment.Difficulty)))
        {
            LOG_ERROR(LOG_FILTER, "Ignoring Manastorm segment {}: unsupported private dungeon map/difficulty.",
                segment.SegmentId);
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
                "COALESCE(c.`map`, 4294967295), "
                "COALESCE(c.`id`, 0) "
                "FROM `manastorm_segment_spawn` s "
                "LEFT JOIN `creature` c "
                "ON c.`guid` = s.`spawn_guid` "
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
                    ManastormSegmentSpawnFlags::CreaturePoolSource;

                if (!routeCreature &&
                    (flags & dependentRoles))
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid authored spawn {} for segment {}: "
                        "Chaotic Link/randomization/pool-source roles require "
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
            "p.\`pool_id\`, "
            "c.\`id\` "
            "FROM \`manastorm_creature_pool_segment\` p "
            "INNER JOIN \`manastorm_segment_spawn\` s "
            "ON s.\`segment_id\` = p.\`segment_id\` "
            "INNER JOIN \`creature\` c "
            "ON c.\`guid\` = s.\`spawn_guid\` "
            "WHERE p.\`enabled\` = 1 "
            "AND s.\`enabled\` = 1 "
            "AND (s.\`flags\` & {}) <> 0 "
            "ORDER BY p.\`pool_id\`, c.\`id\`",
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
            "`completion_message_id` "
            "FROM `manastorm_unlock` "
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

        if (definition.Kind ==
            ManastormUnlockKind::Direct)
        {
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
            "`unlock_id`, "
            "`grant_type`, "
            "`content_id` "
            "FROM `manastorm_unlock_grant` "
            "WHERE `enabled` = 1 "
            "ORDER BY "
            "`unlock_id`, "
            "`grant_type`, "
            "`content_id`");

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

        if (unlock.TriggerDepth !=
            completedDepth)
        {
            continue;
        }

        if (!(unlock.ModeMask &
            modeBit))
        {
            continue;
        }

        if (!(unlock.TrackMask &
            trackBit))
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

        if (unlock.TriggerDepth !=
            completedDepth)
        {
            continue;
        }

        if (!(unlock.ModeMask &
            modeBit))
        {
            continue;
        }

        if (!(unlock.TrackMask &
            trackBit))
        {
            continue;
        }

        matches.push_back(
            &unlock);
    }

    return matches;
}
