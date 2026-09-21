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
#include <limits>

namespace
{
constexpr char const* LOG_FILTER = "module.manastorm.endless";

bool IsValidPositiveMultiplier(float value)
{
    return std::isfinite(value) && value > 0.0f;
}

using NativeIdentity = std::array<uint32, 4>;

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
        file.seekg(20, std::ios::cur); // Five remaining words are not server identity fields.
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
    _unlocks.clear();

    bool const segmentsLoaded =
        LoadSegments();

    bool const chaoticLinkSpawnsLoaded =
        segmentsLoaded &&
        LoadChaoticLinkSpawns();

    bool const scalingLoaded =
        LoadScalingCurve();

    bool const unlocksLoaded =
        segmentsLoaded &&
        LoadUnlocks();

    bool const unlockGrantsLoaded =
        unlocksLoaded &&
        LoadUnlockGrants();

    _loaded =
        segmentsLoaded &&
        chaoticLinkSpawnsLoaded &&
        scalingLoaded &&
        unlocksLoaded &&
        unlockGrantsLoaded;

    if (_loaded)
    {
        LOG_INFO(
            LOG_FILTER,
            "Manastorm datastore loaded: {} segments, "
            "{} scaling points, {} progression unlocks.",
            _segments.size(),
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

bool ManastormDataStore::LoadChaoticLinkSpawns()
{
    QueryResult countResult =
        WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_chaotic_link_spawn`");

    if (!countResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to query `manastorm_chaotic_link_spawn`. "
            "The table is missing or inaccessible.");

        return false;
    }

    uint64 const configuredRows =
        countResult->Fetch()[0].Get<uint64>();

    std::size_t loadedRows = 0;
    bool valid = true;

    if (configuredRows)
    {
        //
        // Join against `creature` while loading so bad authoring data
        // cannot silently connect a segment to a spawn from another map.
        //
        QueryResult result =
            WorldDatabase.Query(
                "SELECT "
                "l.`segment_id`, "
                "l.`spawn_guid`, "
                "COALESCE(c.`map`, 4294967295), "
                "COALESCE(c.`id`, 0) "
                "FROM `manastorm_chaotic_link_spawn` l "
                "LEFT JOIN `creature` c "
                "ON c.`guid` = l.`spawn_guid` "
                "WHERE l.`enabled` = 1 "
                "ORDER BY l.`segment_id`, l.`spawn_guid`");

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

                uint32 const spawnMap =
                    fields[2].Get<uint32>();

                uint32 const spawnEntry =
                    fields[3].Get<uint32>();

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

                //
                // Rows for disabled/non-loaded segments do not affect
                // the current datastore.
                //
                if (!segment)
                {
                    LOG_WARN(
                        LOG_FILTER,
                        "Ignoring Chaotic Link spawn {} for unknown or "
                        "disabled Manastorm segment {}.",
                        spawnGuid,
                        segmentId);

                    continue;
                }

                if (!spawnGuid ||
                    spawnMap ==
                    std::numeric_limits<uint32>::max() ||
                    !spawnEntry)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid Chaotic Link route spawn for segment {}: "
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
                        "Invalid Chaotic Link route spawn {} for segment {}: "
                        "creature is on map {}, but segment uses map {}.",
                        spawnGuid,
                        segmentId,
                        spawnMap,
                        segment->MapId);

                    valid = false;
                    continue;
                }

                //
                // Never allow the objective itself to be configured as
                // one of its own Link breakers.
                //
                if (spawnEntry ==
                    segment->ObjectiveCreatureEntry)
                {
                    LOG_ERROR(
                        LOG_FILTER,
                        "Invalid Chaotic Link route spawn {} for segment {}: "
                        "spawn entry {} is the objective boss itself.",
                        spawnGuid,
                        segmentId,
                        spawnEntry);

                    valid = false;
                    continue;
                }

                segment->ChaoticLinkSpawnIds.push_back(
                    spawnGuid);

                ++loadedRows;
            } while (result->NextRow());
        }
    }

    //
    // A segment must have at least as many usable route spawns as its
    // starting Link count. Otherwise reaching zero would be impossible.
    //
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
        "Loaded {} enabled Chaotic Link route spawns from {} "
        "configured rows.",
        loadedRows,
        configuredRows);

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
            "`trigger_depth`, "
            "`mode_mask`, "
            "`intro_segment_id`, "
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

        definition.TriggerDepth =
            fields[1].Get<uint32>();

        definition.ModeMask =
            fields[2].Get<uint8>();

        definition.IntroSegmentId =
            fields[3].Get<uint32>();

        definition.IntroMessageId =
            fields[4].Get<uint32>();

        definition.CompletionMessageId =
            fields[5].Get<uint32>();

        if (!definition.UnlockId)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock: unlock_id=0.");

            valid = false;
            continue;
        }

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

        if (!definition.IntroSegmentId ||
            !GetSegmentById(
                definition.IntroSegmentId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm unlock {}: "
                "intro segment {} is not an enabled "
                "valid Manastorm segment.",
                definition.UnlockId,
                definition.IntroSegmentId);

            valid = false;
            continue;
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

            LOG_ERROR(
                LOG_FILTER,
                "Manastorm unlock {} conflicts with "
                "unlock {} at trigger depth {}. "
                "Their mode masks overlap.",
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
    ManastormMode mode) const
{
    uint8 const modeBit =
        ManastormGetModeBit(mode);

    if (!completedDepth ||
        !modeBit)
    {
        return nullptr;
    }

    for (auto const& pair :
        _unlocks)
    {
        ManastormUnlockDefinition const& unlock =
            pair.second;

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

        return &unlock;
    }

    return nullptr;
}
