#include "ManastormMgr.h"
#include "ManastormGreedyDemon.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Player.h"
#include "Group.h"
#include "ManastormProgression.h"
#include "ManastormDataStore.h"
#include "ObjectMgr.h"
#include "World.h"

#include <algorithm>
#include <string>

using namespace Acore::ChatCommands;

namespace
{
    struct ManastormAuthoringSegment
    {
        uint32 SegmentId = 0;
        uint32 MapId = 0;
        uint32 ObjectiveCreatureEntry = 0;
        uint8 ChaoticLinkStacks = 0;
    };

    bool GetAuthoringSegment(
        uint32 segmentId,
        ManastormAuthoringSegment& segment)
    {
        QueryResult result = WorldDatabase.Query(
            "SELECT "
            "`segment_id`, "
            "CASE "
            "WHEN `runtime_map_override_enabled` <> 0 "
            "THEN `runtime_map_id` "
            "ELSE `map_id` "
            "END, "
            "COALESCE(NULLIF(`runtime_objective_creature_entry`, 0), "
            "`objective_creature_entry`), "
            "`chaotic_link_stacks` "
            "FROM `manastorm_segment` "
            "WHERE `segment_id` = {} "
            "LIMIT 1",
            segmentId);

        if (!result)
            return false;

        Field* fields = result->Fetch();

        segment.SegmentId =
            fields[0].Get<uint32>();

        segment.MapId =
            fields[1].Get<uint32>();

        segment.ObjectiveCreatureEntry =
            fields[2].Get<uint32>();

        segment.ChaoticLinkStacks =
            fields[3].Get<uint8>();

        return true;
    }

    uint32 GetChaoticLinkCount(
        uint32 segmentId)
    {
        QueryResult result = WorldDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `manastorm_segment_spawn` "
            "WHERE `segment_id` = {} "
            "AND (`flags` & {}) <> 0 "
            "AND `enabled` = 1",
            segmentId,
            ManastormSegmentSpawnFlags::ChaoticLinkEligible);

        if (!result)
            return 0;

        return uint32(
            result->Fetch()[0].Get<uint64>());
    }

    bool ReloadAfterAuthoring(
        ChatHandler* handler)
    {
        if (ManastormMgr::Instance().ReloadData())
            return true;

        handler->SendErrorMessage(
            "Manastorm: database change succeeded, "
            "but datastore reload failed. Check worldserver logs.");

        return false;
    }

    bool SetSelectedSpawnRole(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 roleFlag,
        bool enable,
        char const* roleName)
    {
        ManastormAuthoringSegment segment;

        if (!GetAuthoringSegment(
            segmentId,
            segment))
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        Creature* creature =
            handler->getSelectedCreature();

        if (!creature)
        {
            handler->SendErrorMessage(
                "Manastorm: select a creature first.");

            return false;
        }

        ObjectGuid::LowType const spawnId =
            creature->GetSpawnId();

        if (!spawnId)
        {
            handler->SendErrorMessage(
                "Manastorm: selected creature has no stable DB spawn ID. "
                "Temporary/summoned creatures cannot receive authored "
                "segment-spawn roles.");

            return false;
        }

        if (creature->GetMapId() !=
            segment.MapId)
        {
            handler->PSendSysMessage(
                "Manastorm: spawn {} is on map {}, but segment {} uses map {}.",
                spawnId,
                creature->GetMapId(),
                segmentId,
                segment.MapId);

            return true;
        }

        if (creature->GetEntry() ==
            segment.ObjectiveCreatureEntry)
        {
            handler->PSendSysMessage(
                "Manastorm: creature entry {} is the fixed objective for "
                "segment {} and cannot be a trash randomization/pool-source "
                "spawn.",
                creature->GetEntry(),
                segmentId);

            return true;
        }

        if (enable)
        {
            uint32 const flags =
                ManastormSegmentSpawnFlags::RouteCreature |
                roleFlag;

            WorldDatabase.DirectExecute(
                "INSERT INTO `manastorm_segment_spawn` "
                "(`segment_id`, `spawn_guid`, `flags`, `enabled`) "
                "VALUES ({}, {}, {}, 1) "
                "ON DUPLICATE KEY UPDATE "
                "`flags` = (`flags` | VALUES(`flags`)), "
                "`enabled` = 1",
                segmentId,
                spawnId,
                flags);
        }
        else
        {
            WorldDatabase.DirectExecute(
                "UPDATE `manastorm_segment_spawn` "
                "SET `flags` = (`flags` & ~{}) "
                "WHERE `segment_id` = {} "
                "AND `spawn_guid` = {}",
                roleFlag,
                segmentId,
                spawnId);
        }

        if (!ReloadAfterAuthoring(handler))
            return false;

        handler->PSendSysMessage(
            "Manastorm: {} {} for segment={} spawn={} entry={} name='{}'.",
            roleName,
            enable ? "enabled" : "disabled",
            segmentId,
            spawnId,
            creature->GetEntry(),
            creature->GetName());

        return true;
    }

    void SendRunStatus(ChatHandler* handler, ManastormRun const& run)
    {
        ManastormSegment const& segment = run.GetSegment();
        ManastormScalingPoint const& scaling = run.GetScaling();

        handler->PSendSysMessage(
            "Manastorm run {} | state={} | mode={} | members={} | "
            "depth={} | creatureLevel={} | seed={}",
            run.GetRunId(),
            ManastormRunStateName(run.GetState()),
            ManastormModeName(run.GetMode()),
            run.GetMembers().size(),
            run.GetDepth(),
            uint32(run.GetCreatureLevel()),
            run.GetSeed());

        handler->PSendSysMessage(
            "Stage: segment={} map={} instance={} difficulty={} encounter={} objective={} tele={} "
            "weight={} reward={:.3f}x",
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            segment.Difficulty,
            segment.DungeonEncounterId,
            segment.ObjectiveCreatureEntry,
            segment.StartGameTeleId,
            segment.Weight,
            segment.RewardMultiplier);

        handler->PSendSysMessage(
            "Effective scaling (depth x {} members): "
            "HP={:.3f}x GlobalDamage={:.3f}x Melee={:.3f}x Spell={:.3f}x",
            run.GetMembers().size(),
            scaling.HealthMultiplier,
            scaling.GlobalDamageMultiplier,
            scaling.MeleeMultiplier,
            scaling.SpellMultiplier);

        ObjectGuid const objectiveGuid = run.GetObjectiveCreatureGuid();

        handler->PSendSysMessage(
            "Runtime: stageCreatures={} objectiveGuid={} counter={} "
            "chaoticLinks={} unusedLinkSpawns={} "
            "resurrections={}/{} complete={}", run.GetStageCreatureCount(),
            objectiveGuid.GetRawValue(),
            objectiveGuid.GetCounter(),
            uint32(run.GetChaoticLinkStacks()),
            run.GetUnusedChaoticLinkSpawnCount(),
            uint32(run.GetResurrectionCharges()),
            uint32(ManastormResurrection::MaxCharges),
            run.GetState() == ManastormRunState::StageComplete
            ? "yes"
            : "no");
    }
}

class manastorm_commandscript : public CommandScript
{
public:
    manastorm_commandscript()
        : CommandScript("manastorm_commandscript")
    {
    }

    ChatCommandTable GetCommands() const override
    {

        static ChatCommandTable linkCommandTable =
        {
            { "add",    HandleLinkAddCommand,    SEC_GAMEMASTER, Console::No },
            { "remove", HandleLinkRemoveCommand, SEC_GAMEMASTER, Console::No },
            { "list",   HandleLinkListCommand,   SEC_GAMEMASTER, Console::No },
            { "clear",  HandleLinkClearCommand,  SEC_GAMEMASTER, Console::No },
            { "stacks", HandleLinkStacksCommand, SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable spawnCommandTable =
        {
            { "randomslot", HandleSpawnRandomSlotCommand, SEC_GAMEMASTER, Console::No },
            { "poolsource", HandleSpawnPoolSourceCommand, SEC_GAMEMASTER, Console::No },
            { "affix",      HandleSpawnAffixCommand,      SEC_GAMEMASTER, Console::No },
            { "info",       HandleSpawnInfoCommand,       SEC_GAMEMASTER, Console::No },
            { "list",       HandleSpawnListCommand,       SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable poolCommandTable =
        {
            { "info", HandlePoolInfoCommand, SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable segmentCommandTable =
        {
            { "info",      HandleSegmentInfoCommand,             SEC_GAMEMASTER, Console::No },
            { "runtime",   HandleSegmentRuntimeMapCommand,       SEC_GAMEMASTER, Console::No },
            { "objective", HandleSegmentRuntimeObjectiveCommand, SEC_GAMEMASTER, Console::No },
            { "enable",    HandleSegmentEnableCommand,           SEC_GAMEMASTER, Console::No },
            { "test",      HandleSegmentTestCommand,             SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable affixCommandTable =
        {
            { "force", HandleAffixForceCommand, SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable greedyCommandTable =
        {
            { "spawn", HandleGreedySpawnCommand, SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable endlessCommandTable =
        {
            { "ui",          HandleUICommand,          SEC_PLAYER,     Console::No },
            { "start",       HandleStartCommand,       SEC_GAMEMASTER, Console::No },
            { "startforce",  HandleStartForceCommand,  SEC_GAMEMASTER, Console::No },
            { "checkpoints", HandleCheckpointsCommand, SEC_GAMEMASTER, Console::No },
            { "status",      HandleStatusCommand,      SEC_GAMEMASTER, Console::No },
            { "stop",        HandleStopCommand,        SEC_GAMEMASTER, Console::No },

            { "link",    linkCommandTable },
            { "spawn",   spawnCommandTable },
            { "pool",    poolCommandTable },
            { "segment", segmentCommandTable },
            { "affix",   affixCommandTable },
            { "greedy",  greedyCommandTable },

            { "reload", HandleReloadCommand, SEC_ADMINISTRATOR, Console::Yes },
        };

        static ChatCommandTable commandTable =
        {
            { "manastorm", endlessCommandTable },
        };

        return commandTable;
    }

    static bool HandleUICommand(
        ChatHandler* handler)
    {
        Player* player =
            handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage(
                "Manastorm: this command requires an in-game player.");

            return false;
        }

        ManastormMgr::Instance()
            .OpenClientUI(player);

        return true;
    }

    static bool HandleStartCommand(ChatHandler* handler, uint32 depth)
    {
        Player* player = handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage("Manastorm: this command requires an in-game player.");
            return false;
        }

        std::string error;
        ManastormRun* run = ManastormMgr::Instance().StartRun(
            player, depth, error);

        if (!run)
        {
            handler->PSendSysMessage("Manastorm: {}", error);
            return true;
        }

        handler->PSendSysMessage(
            "Manastorm: Phase-2A run prepared. Teleporting to segment {} in instance {}.",
            run->GetSegment().SegmentId,
            run->GetInstanceId());

        SendRunStatus(handler, *run);
        return true;
    }

    static bool HandleStartForceCommand(
        ChatHandler* handler,
        uint32 depth)
    {
        Player* player =
            handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage(
                "Manastorm: this command requires "
                "an in-game player.");

            return false;
        }

        std::string error;

        ManastormRun* run =
            ManastormMgr::Instance().StartRun(
                player,
                depth,
                error,
                true);

        if (!run)
        {
            handler->PSendSysMessage(
                "Manastorm: {}",
                error);

            return true;
        }

        handler->PSendSysMessage(
            "Manastorm: FORCE-started depth {} "
            "for authoring/debug. Segment={} instance={}.",
            depth,
            run->GetSegment().SegmentId,
            run->GetInstanceId());

        SendRunStatus(
            handler,
            *run);

        return true;
    }

    static bool HandleCheckpointsCommand(
        ChatHandler* handler)
    {
        Player* player =
            handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage(
                "Manastorm: this command requires "
                "an in-game player.");

            return false;
        }

        uint32 memberCount = 1;

        if (Group* group =
            player->GetGroup())
        {
            memberCount =
                std::max<uint32>(
                    1,
                    group->GetMembersCount());
        }

        ManastormMode const mode =
            ManastormModeForMemberCount(
                memberCount);

        ManastormProgressionSnapshot snapshot;
        std::string error;

        uint32 const endgameLevel =
            std::max(
                60u,
                sWorld->getIntConfig(
                    CONFIG_MAX_PLAYER_LEVEL));

        bool const endgame =
            player->GetLevel() >=
                endgameLevel;

        if (!ManastormProgression::LoadSnapshot(
            player->GetGUID().GetCounter(),
            mode,
            endgame,
            snapshot,
            error))
        {
            handler->PSendSysMessage(
                "Manastorm: {}",
                error);

            return true;
        }

        std::vector<uint32> depths;

        ManastormProgression::BuildEnterableDepths(
            snapshot,
            depths);

        handler->PSendSysMessage(
            "Manastorm checkpoints | mode={} | "
            "bestCompleted={} | pendingUnlock={} | "
            "pendingIntroDepth={} | pendingSegment={}",
            ManastormModeName(mode),
            snapshot.BestCompletedDepth,
            snapshot.PendingUnlockId,
            snapshot.PendingIntroDepth,
            snapshot.PendingIntroSegmentId);

        if (depths.empty())
        {
            handler->SendSysMessage(
                "Enterable depths: none.");

            return true;
        }

        std::string list;

        for (std::size_t index = 0;
            index < depths.size();
            ++index)
        {
            if (index)
                list += ", ";

            list +=
                std::to_string(
                    depths[index]);
        }

        handler->PSendSysMessage(
            "Enterable depths (highest first): {}",
            list);

        return true;
    }

    static bool HandleStatusCommand(ChatHandler* handler)
    {
        Player* player = handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage("Manastorm: this command requires an in-game player.");
            return false;
        }

        ManastormRun const* run =
            ManastormMgr::Instance().GetRunFor(player);

        if (!run)
        {
            handler->SendSysMessage(
                "Manastorm: you are not part of an active run.");
            return true;
        }

        SendRunStatus(handler, *run);
        return true;
    }

    static bool HandleStopCommand(ChatHandler* handler)
    {
        Player* player = handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage("Manastorm: this command requires an in-game player.");
            return false;
        }

        std::string error;
        if (!ManastormMgr::Instance().StopRun(player, error))
        {
            handler->PSendSysMessage("Manastorm: {}", error);
            return true;
        }

        handler->SendSysMessage("Manastorm: run stopped.");
        return true;
    }

    static bool HandleSpawnRandomSlotCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 enabled)
    {
        if (enabled > 1)
        {
            handler->SendErrorMessage(
                "Manastorm: randomslot value must be 0 or 1.");

            return false;
        }

        return SetSelectedSpawnRole(
            handler,
            segmentId,
            ManastormSegmentSpawnFlags::RandomizationSlot,
            enabled != 0,
            "RandomizationSlot");
    }

    static bool HandleSpawnPoolSourceCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 enabled)
    {
        if (enabled > 1)
        {
            handler->SendErrorMessage(
                "Manastorm: poolsource value must be 0 or 1.");

            return false;
        }

        return SetSelectedSpawnRole(
            handler,
            segmentId,
            ManastormSegmentSpawnFlags::CreaturePoolSource,
            enabled != 0,
            "CreaturePoolSource");
    }

    static bool HandleSpawnAffixCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 enabled)
    {
        if (enabled > 1)
        {
            handler->SendErrorMessage(
                "Manastorm: affix value must be 0 or 1.");

            return false;
        }

        return SetSelectedSpawnRole(
            handler,
            segmentId,
            ManastormSegmentSpawnFlags::AffixEligible,
            enabled != 0,
            "AffixEligible");
    }

    static bool HandleSpawnInfoCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        Creature* creature =
            handler->getSelectedCreature();

        if (!creature)
        {
            handler->SendErrorMessage(
                "Manastorm: select a creature first.");

            return false;
        }

        ObjectGuid::LowType const spawnId =
            creature->GetSpawnId();

        if (!spawnId)
        {
            handler->SendErrorMessage(
                "Manastorm: selected creature has no stable DB spawn ID.");

            return false;
        }

        QueryResult result = WorldDatabase.Query(
            "SELECT `flags`, `enabled` "
            "FROM `manastorm_segment_spawn` "
            "WHERE `segment_id` = {} "
            "AND `spawn_guid` = {} "
            "LIMIT 1",
            segmentId,
            spawnId);

        if (!result)
        {
            handler->PSendSysMessage(
                "Manastorm: spawn {} has no authored roles for segment {}.",
                spawnId,
                segmentId);

            return true;
        }

        Field* fields =
            result->Fetch();

        uint32 const flags =
            fields[0].Get<uint32>();

        bool const enabled =
            fields[1].Get<uint8>() != 0;

        handler->PSendSysMessage(
            "Manastorm spawn roles | segment={} spawn={} entry={} "
            "flags=0x{:X} enabled={} route={} link={} randomslot={} poolsource={} affix={}",
            segmentId,
            spawnId,
            creature->GetEntry(),
            flags,
            enabled ? "yes" : "no",
            (flags & ManastormSegmentSpawnFlags::RouteCreature) ? "yes" : "no",
            (flags & ManastormSegmentSpawnFlags::ChaoticLinkEligible) ? "yes" : "no",
            (flags & ManastormSegmentSpawnFlags::RandomizationSlot) ? "yes" : "no",
            (flags & ManastormSegmentSpawnFlags::CreaturePoolSource) ? "yes" : "no",
            (flags & ManastormSegmentSpawnFlags::AffixEligible) ? "yes" : "no");

        return true;
    }

    static bool HandleSpawnListCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        QueryResult result = WorldDatabase.Query(
            "SELECT "
            "s.`spawn_guid`, "
            "COALESCE(c.`id`, 0), "
            "s.`flags`, "
            "s.`enabled` "
            "FROM `manastorm_segment_spawn` s "
            "LEFT JOIN `creature` c "
            "ON c.`guid` = s.`spawn_guid` "
            "WHERE s.`segment_id` = {} "
            "ORDER BY s.`spawn_guid`",
            segmentId);

        if (!result)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} has no authored spawn roles.",
                segmentId);

            return true;
        }

        handler->PSendSysMessage(
            "Manastorm authored spawns for segment {}:",
            segmentId);

        do
        {
            Field* fields =
                result->Fetch();

            handler->PSendSysMessage(
                "  spawn={} entry={} flags=0x{:X} enabled={}",
                fields[0].Get<uint32>(),
                fields[1].Get<uint32>(),
                fields[2].Get<uint32>(),
                fields[3].Get<uint8>() ? "yes" : "no");
        } while (result->NextRow());

        return true;
    }

    static bool HandlePoolInfoCommand(
        ChatHandler* handler,
        uint32 poolId)
    {
        ManastormCreaturePoolDefinition const* pool =
            ManastormDataStore::Instance()
            .GetCreaturePoolById(poolId);

        if (!pool)
        {
            handler->PSendSysMessage(
                "Manastorm: creature pool {} is not loaded/enabled.",
                poolId);

            return true;
        }

        handler->PSendSysMessage(
            "Manastorm creature pool {} '{}' | sourceSegments={} "
            "derivedCreatureEntries={} | replacementRuntime=disabled",
            pool->PoolId,
            pool->Name,
            pool->SourceSegmentIds.size(),
            pool->CreatureEntries.size());

        for (uint32 segmentId :
            pool->SourceSegmentIds)
        {
            handler->PSendSysMessage(
                "  sourceSegment={}",
                segmentId);
        }

        for (uint32 creatureEntry :
            pool->CreatureEntries)
        {
            CreatureTemplate const* creatureTemplate =
                sObjectMgr->GetCreatureTemplate(
                    creatureEntry);

            handler->PSendSysMessage(
                "  creatureEntry={} name='{}'",
                creatureEntry,
                creatureTemplate
                    ? creatureTemplate->Name
                    : "<missing template>");
        }

        return true;
    }

    static bool HandleLinkAddCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        if (!segmentId)
        {
            handler->SendErrorMessage(
                "Manastorm: segment ID must be greater than 0.");

            return false;
        }

        ManastormAuthoringSegment segment;

        if (!GetAuthoringSegment(
            segmentId,
            segment))
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        Creature* creature =
            handler->getSelectedCreature();

        if (!creature)
        {
            handler->SendErrorMessage(
                "Manastorm: select a creature first.");

            return false;
        }

        ObjectGuid::LowType const spawnId =
            creature->GetSpawnId();

        if (!spawnId)
        {
            handler->SendErrorMessage(
                "Manastorm: selected creature has no stable DB spawn ID. "
                "Temporary, summoned, or dynamically-created creatures "
                "cannot be Chaotic Links.");

            return false;
        }

        if (creature->GetMapId() !=
            segment.MapId)
        {
            handler->PSendSysMessage(
                "Manastorm: spawn {} is on map {}, "
                "but segment {} uses map {}.",
                spawnId,
                creature->GetMapId(),
                segmentId,
                segment.MapId);

            return true;
        }

        if (creature->GetEntry() ==
            segment.ObjectiveCreatureEntry)
        {
            handler->PSendSysMessage(
                "Manastorm: creature entry {} is the "
                "objective boss for segment {} and cannot "
                "also be a Chaotic Link route spawn.",
                creature->GetEntry(),
                segmentId);

            return true;
        }

        QueryResult existing = WorldDatabase.Query(
            "SELECT `flags`, `enabled` "
            "FROM `manastorm_segment_spawn` "
            "WHERE `segment_id` = {} "
            "AND `spawn_guid` = {} "
            "LIMIT 1",
            segmentId,
            spawnId);

        if (existing)
        {
            Field* fields =
                existing->Fetch();

            uint32 const flags =
                fields[0].Get<uint32>();

            bool const enabled =
                fields[1].Get<uint8>() != 0;

            uint32 const requiredFlags =
                ManastormSegmentSpawnFlags::RouteCreature |
                ManastormSegmentSpawnFlags::ChaoticLinkEligible |
                ManastormSegmentSpawnFlags::AffixEligible;

            if (enabled && (flags & requiredFlags) == requiredFlags)
            {
                handler->PSendSysMessage(
                    "Manastorm: spawn {} is already a Chaotic Link "
                    "for segment {}.",
                    spawnId,
                    segmentId);

                return true;
            }
        }

        uint32 const addFlags =
            ManastormSegmentSpawnFlags::RouteCreature |
            ManastormSegmentSpawnFlags::ChaoticLinkEligible |
            ManastormSegmentSpawnFlags::AffixEligible;

        WorldDatabase.DirectExecute(
            "INSERT INTO `manastorm_segment_spawn` "
            "(`segment_id`, `spawn_guid`, `flags`, `enabled`) "
            "VALUES ({}, {}, {}, 1) "
            "ON DUPLICATE KEY UPDATE "
            "`flags` = (`flags` | VALUES(`flags`)), "
            "`enabled` = 1",
            segmentId,
            spawnId,
            addFlags);

        if (!ReloadAfterAuthoring(handler))
            return false;

        uint32 const newCount =
            GetChaoticLinkCount(segmentId);

        handler->PSendSysMessage(
            "Manastorm: added Chaotic Link candidate | "
            "segment={} spawn={} entry={} name='{}' | "
            "candidates={} requiredBossLinks={}.",
            segmentId,
            spawnId,
            creature->GetEntry(),
            creature->GetName(),
            newCount,
            uint32(segment.ChaoticLinkStacks));

        return true;
    }

    static bool HandleLinkRemoveCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        if (!segmentId)
        {
            handler->SendErrorMessage(
                "Manastorm: segment ID must be greater than 0.");

            return false;
        }

        ManastormAuthoringSegment segment;

        if (!GetAuthoringSegment(
            segmentId,
            segment))
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        Creature* creature =
            handler->getSelectedCreature();

        if (!creature)
        {
            handler->SendErrorMessage(
                "Manastorm: select a creature first.");

            return false;
        }

        ObjectGuid::LowType const spawnId =
            creature->GetSpawnId();

        if (!spawnId)
        {
            handler->SendErrorMessage(
                "Manastorm: selected creature has no stable DB spawn ID.");

            return false;
        }

        QueryResult existing = WorldDatabase.Query(
            "SELECT `flags`, `enabled` "
            "FROM `manastorm_segment_spawn` "
            "WHERE `segment_id` = {} "
            "AND `spawn_guid` = {} "
            "LIMIT 1",
            segmentId,
            spawnId);

        if (!existing)
        {
            handler->PSendSysMessage(
                "Manastorm: spawn {} is not registered "
                "to segment {}.",
                spawnId,
                segmentId);

            return true;
        }

        Field* existingFields =
            existing->Fetch();

        uint32 const existingFlags =
            existingFields[0].Get<uint32>();

        bool const existingEnabled =
            existingFields[1].Get<uint8>() != 0;

        if (!existingEnabled ||
            !(existingFlags &
                ManastormSegmentSpawnFlags::ChaoticLinkEligible))
        {
            handler->PSendSysMessage(
                "Manastorm: spawn {} is not an enabled Chaotic Link "
                "candidate for segment {}.",
                spawnId,
                segmentId);

            return true;
        }

        uint32 const currentCandidateCount =
            GetChaoticLinkCount(segmentId);

        uint32 const remainingCandidateCount =
            currentCandidateCount > 0
            ? currentCandidateCount - 1
            : 0;

        if (remainingCandidateCount <
            uint32(segment.ChaoticLinkStacks))
        {
            handler->PSendSysMessage(
                "Manastorm: cannot remove this candidate. "
                "Segment {} requires {} boss Link break(s), "
                "but removal would leave only {} candidate(s). "
                "Lower the required Link count first with "
                "`.manastorm link stacks {} <count>`.",
                segmentId,
                uint32(segment.ChaoticLinkStacks),
                remainingCandidateCount,
                segmentId);

            return true;
        }

        uint32 const nonRouteRoles =
            existingFlags &
            (ManastormSegmentSpawnFlags::RandomizationSlot |
                ManastormSegmentSpawnFlags::CreaturePoolSource);

        if (nonRouteRoles)
        {
            // Other evidence-backed roles still depend on this authored route
            // spawn. Remove only Chaotic Link eligibility.
            WorldDatabase.DirectExecute(
                "UPDATE `manastorm_segment_spawn` "
                "SET `flags` = (`flags` & ~{}) "
                "WHERE `segment_id` = {} "
                "AND `spawn_guid` = {}",
                ManastormSegmentSpawnFlags::ChaoticLinkEligible,
                segmentId,
                spawnId);
        }
        else
        {
            // A row authored only through .manastorm link add carries
            // RouteCreature|ChaoticLinkEligible. Preserve the old intuitive
            // remove behavior and remove that authoring row completely.
            WorldDatabase.DirectExecute(
                "DELETE FROM `manastorm_segment_spawn` "
                "WHERE `segment_id` = {} "
                "AND `spawn_guid` = {}",
                segmentId,
                spawnId);
        }

        if (!ReloadAfterAuthoring(handler))
            return false;

        handler->PSendSysMessage(
            "Manastorm: removed Chaotic Link candidate | "
            "segment={} spawn={} entry={} | "
            "candidates={} requiredBossLinks={}.",
            segmentId,
            spawnId,
            creature->GetEntry(),
            GetChaoticLinkCount(segmentId),
            uint32(segment.ChaoticLinkStacks));

        return true;
    }

    static bool HandleLinkListCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        ManastormAuthoringSegment segment;

        if (!GetAuthoringSegment(
            segmentId,
            segment))
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        QueryResult result = WorldDatabase.Query(
            "SELECT "
            "s.`spawn_guid`, "
            "COALESCE(c.`id`, 0), "
            "s.`flags`, "
            "s.`enabled` "
            "FROM `manastorm_segment_spawn` s "
            "LEFT JOIN `creature` c "
            "ON c.`guid` = s.`spawn_guid` "
            "WHERE s.`segment_id` = {} "
            "AND (s.`flags` & {}) <> 0 "
            "ORDER BY s.`spawn_guid`",
            segmentId,
            ManastormSegmentSpawnFlags::ChaoticLinkEligible);

        handler->PSendSysMessage(
            "Manastorm: Chaotic Link route for segment {} "
            "(map={}, candidates={}, requiredBossLinks={}):",
            segmentId,
            segment.MapId,
            GetChaoticLinkCount(segmentId),
            uint32(segment.ChaoticLinkStacks));

        if (!result)
        {
            handler->SendSysMessage(
                "  No Chaotic Link spawns configured.");

            return true;
        }

        do
        {
            Field* fields =
                result->Fetch();

            ObjectGuid::LowType const spawnId =
                fields[0].Get<uint32>();

            uint32 const entry =
                fields[1].Get<uint32>();

            uint32 const flags =
                fields[2].Get<uint32>();

            bool const enabled =
                fields[3].Get<uint8>() != 0;

            handler->PSendSysMessage(
                "  spawn={} entry={} flags=0x{:X} enabled={}",
                spawnId,
                entry,
                flags,
                enabled ? "yes" : "no");
        } while (result->NextRow());

        return true;
    }

    static bool HandleLinkClearCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        ManastormAuthoringSegment segment;

        if (!GetAuthoringSegment(
            segmentId,
            segment))
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        if (segment.ChaoticLinkStacks)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} still requires {} boss "
                "Link break(s). Set its Link stacks to 0 first with "
                "`.manastorm link stacks {} 0` before clearing "
                "all route candidates.",
                segmentId,
                uint32(segment.ChaoticLinkStacks),
                segmentId);

            return true;
        }

        uint32 const oldCount =
            GetChaoticLinkCount(segmentId);

        // Rows with future randomization/pool-source roles remain authored
        // route members; rows that only existed for Chaotic Link authoring
        // are removed entirely.
        WorldDatabase.DirectExecute(
            "DELETE FROM `manastorm_segment_spawn` "
            "WHERE `segment_id` = {} "
            "AND (`flags` & {}) <> 0 "
            "AND (`flags` & {}) = 0",
            segmentId,
            ManastormSegmentSpawnFlags::ChaoticLinkEligible,
            ManastormSegmentSpawnFlags::RandomizationSlot |
                ManastormSegmentSpawnFlags::CreaturePoolSource);

        WorldDatabase.DirectExecute(
            "UPDATE `manastorm_segment_spawn` "
            "SET `flags` = (`flags` & ~{}) "
            "WHERE `segment_id` = {} "
            "AND (`flags` & {}) <> 0",
            ManastormSegmentSpawnFlags::ChaoticLinkEligible,
            segmentId,
            ManastormSegmentSpawnFlags::ChaoticLinkEligible);

        if (!ReloadAfterAuthoring(handler))
            return false;

        handler->PSendSysMessage(
            "Manastorm: cleared {} Chaotic Link candidate spawn(s) "
            "from segment {}. requiredBossLinks=0.",
            oldCount,
            segmentId);

        return true;
    }

    static bool HandleLinkStacksCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 stacks)
    {
        if (!segmentId)
        {
            handler->SendErrorMessage(
                "Manastorm: segment ID must be greater than 0.");

            return false;
        }

        ManastormAuthoringSegment segment;

        if (!GetAuthoringSegment(
            segmentId,
            segment))
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        if (stacks > 254)
        {
            handler->SendErrorMessage(
                "Manastorm: Chaotic Link stacks cannot exceed 254.");

            return false;
        }

        uint32 const candidateCount =
            GetChaoticLinkCount(segmentId);

        if (stacks > candidateCount)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} has only {} configured "
                "Chaotic Link candidate(s), so required boss Links "
                "cannot be set to {}.",
                segmentId,
                candidateCount,
                stacks);

            return true;
        }

        WorldDatabase.DirectExecute(
            "UPDATE `manastorm_segment` "
            "SET `chaotic_link_stacks` = {} "
            "WHERE `segment_id` = {}",
            stacks,
            segmentId);

        if (!ReloadAfterAuthoring(handler))
            return false;

        handler->PSendSysMessage(
            "Manastorm: segment {} now has {} configured "
            "candidate(s) and requires {} candidate death(s) "
            "to remove all boss Chaotic Links.",
            segmentId,
            candidateCount,
            stacks);

        return true;
    }

    static bool HandleSegmentEnableCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 enabled)
    {
        if (!segmentId || enabled > 1)
        {
            handler->SendErrorMessage(
                "Usage: .manastorm segment enable <segmentId> <0|1>");
            return false;
        }

        QueryResult result =
            WorldDatabase.Query(
                "SELECT 1 "
                "FROM `manastorm_segment` "
                "WHERE `segment_id` = {} "
                "LIMIT 1",
                segmentId);

        if (!result)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);
            return true;
        }

        WorldDatabase.DirectExecute(
            "UPDATE `manastorm_segment` "
            "SET `enabled` = {} "
            "WHERE `segment_id` = {}",
            enabled,
            segmentId);

        if (enabled)
        {
            if (!ReloadAfterAuthoring(handler))
            {
                handler->PSendSysMessage(
                    "Manastorm: segment {} was enabled in SQL, "
                    "but datastore validation rejected it. Check worldserver logs.",
                    segmentId);
                return true;
            }
        }
        else
        {
            // Reload when possible. If this was the final enabled segment the
            // datastore may intentionally report that no valid rows remain.
            ManastormMgr::Instance().ReloadData();
        }

        handler->PSendSysMessage(
            "Manastorm: segment {} {}.",
            segmentId,
            enabled ? "enabled" : "disabled");

        return true;
    }

    static bool HandleSegmentTestCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        Player* player =
            handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage(
                "Manastorm: this command requires an in-game player.");
            return false;
        }

        ManastormSegment const* segment =
            ManastormDataStore::Instance().GetSegmentById(
                segmentId);

        if (!segment)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} is not enabled/valid. "
                "Use `.manastorm segment enable {} 1` and inspect the "
                "worldserver log if validation rejects it.",
                segmentId,
                segmentId);
            return true;
        }

        uint32 const depth =
            std::max<uint32>(
                1,
                segment->MinDepth);

        std::string error;

        ManastormRun* run =
            ManastormMgr::Instance().StartRun(
                player,
                depth,
                error,
                true,
                segmentId);

        if (!run)
        {
            handler->PSendSysMessage(
                "Manastorm: exact-segment test failed: {}",
                error);
            return true;
        }

        handler->PSendSysMessage(
            "Manastorm: TEST launched exact segment {} "
            "at depth {} | nativeMap={} runtimeMap={} instance={}.",
            segmentId,
            depth,
            run->GetSegment().NativeMapId,
            run->GetSegment().MapId,
            run->GetInstanceId());

        SendRunStatus(
            handler,
            *run);

        return true;
    }

    static bool HandleSegmentRuntimeMapCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 mapId)
    {
        QueryResult segmentResult =
            WorldDatabase.Query(
                "SELECT `map_id` "
                "FROM `manastorm_segment` "
                "WHERE `segment_id` = {} "
                "LIMIT 1",
                segmentId);

        if (!segmentResult)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);
            return true;
        }

        uint32 const nativeMapId =
            segmentResult->Fetch()[0].Get<uint32>();

        if (mapId)
        {
            MapEntry const* mapEntry =
                sMapStore.LookupEntry(mapId);

            if (!mapEntry)
            {
                handler->PSendSysMessage(
                    "Manastorm: runtime map {} does not exist.",
                    mapId);
                return true;
            }

            if (mapEntry->IsBattlegroundOrArena())
            {
                handler->PSendSysMessage(
                    "Manastorm: battleground/arena map {} cannot be used "
                    "as a runtime stage map.",
                    mapId);
                return true;
            }
        }

        WorldDatabase.DirectExecute(
            "UPDATE `manastorm_segment` "
            "SET `runtime_map_id` = {} "
            "WHERE `segment_id` = {}",
            mapId,
            segmentId);

        if (!ReloadAfterAuthoring(handler))
            return false;

        handler->PSendSysMessage(
            "Manastorm: segment {} nativeMap={} runtimeMap={}{}.",
            segmentId,
            nativeMapId,
            mapId ? mapId : nativeMapId,
            mapId ? " (override)" : " (native)");

        return true;
    }

    static bool HandleSegmentRuntimeObjectiveCommand(
        ChatHandler* handler,
        uint32 segmentId,
        uint32 creatureEntry)
    {
        QueryResult segmentResult =
            WorldDatabase.Query(
                "SELECT `objective_creature_entry` "
                "FROM `manastorm_segment` "
                "WHERE `segment_id` = {} "
                "LIMIT 1",
                segmentId);

        if (!segmentResult)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);
            return true;
        }

        uint32 const nativeObjectiveEntry =
            segmentResult->Fetch()[0].Get<uint32>();

        if (creatureEntry &&
            !sObjectMgr->GetCreatureTemplate(creatureEntry))
        {
            handler->PSendSysMessage(
                "Manastorm: runtime objective creature entry {} "
                "does not exist in creature_template.",
                creatureEntry);
            return true;
        }

        WorldDatabase.DirectExecute(
            "UPDATE `manastorm_segment` "
            "SET `runtime_objective_creature_entry` = {} "
            "WHERE `segment_id` = {}",
            creatureEntry,
            segmentId);

        if (!ReloadAfterAuthoring(handler))
            return false;

        handler->PSendSysMessage(
            "Manastorm: segment {} nativeObjective={} runtimeObjective={}{}.",
            segmentId,
            nativeObjectiveEntry,
            creatureEntry
                ? creatureEntry
                : nativeObjectiveEntry,
            creatureEntry
                ? " (override)"
                : " (native)");

        return true;
    }

    static bool HandleSegmentInfoCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        QueryResult result = WorldDatabase.Query(
            "SELECT "
            "`map_id`, "
            "`runtime_map_id`, "
            "`difficulty`, "
            "`dungeon_encounter_id`, "
            "`objective_creature_entry`, "
            "`runtime_objective_creature_entry`, "
            "`start_game_tele_id`, "
            "`weight`, "
            "`min_depth`, "
            "`max_depth`, "
            "`reward_multiplier`, "
            "`chaotic_link_stacks`, "
            "`enabled` "
            "FROM `manastorm_segment` "
            "WHERE `segment_id` = {} "
            "LIMIT 1",
            segmentId);

        if (!result)
        {
            handler->PSendSysMessage(
                "Manastorm: segment {} does not exist.",
                segmentId);

            return true;
        }

        Field* fields =
            result->Fetch();

        uint32 const nativeMapId =
            fields[0].Get<uint32>();

        uint32 const runtimeMapOverride =
            fields[1].Get<uint32>();

        uint32 const runtimeMapId =
            runtimeMapOverride
            ? runtimeMapOverride
            : nativeMapId;

        uint8 const difficulty =
            fields[2].Get<uint8>();

        uint32 const encounterId =
            fields[3].Get<uint32>();

        uint32 const nativeObjectiveEntry =
            fields[4].Get<uint32>();

        uint32 const runtimeObjectiveOverride =
            fields[5].Get<uint32>();

        uint32 const runtimeObjectiveEntry =
            runtimeObjectiveOverride
            ? runtimeObjectiveOverride
            : nativeObjectiveEntry;

        uint32 const teleId =
            fields[6].Get<uint32>();

        uint32 const weight =
            fields[7].Get<uint32>();

        uint32 const minDepth =
            fields[8].Get<uint32>();

        uint32 const maxDepth =
            fields[9].Get<uint32>();

        float const rewardMultiplier =
            fields[10].Get<float>();

        uint8 const configuredStacks =
            fields[11].Get<uint8>();

        bool const enabled =
            fields[12].Get<uint8>() != 0;

        uint32 const routeSpawnCount =
            GetChaoticLinkCount(segmentId);

        handler->PSendSysMessage(
            "Manastorm segment {}:",
            segmentId);

        handler->PSendSysMessage(
            "  nativeMap={} runtimeMap={}{} difficulty={} encounter={}",
            nativeMapId,
            runtimeMapId,
            runtimeMapOverride ? " (override)" : "",
            uint32(difficulty),
            encounterId);

        handler->PSendSysMessage(
            "  objectiveNative={} objectiveRuntime={}{} startTele={}",
            nativeObjectiveEntry,
            runtimeObjectiveEntry,
            runtimeObjectiveOverride ? " (override)" : "",
            teleId);

        handler->PSendSysMessage(
            "  depth={}..{} weight={} reward={:.3f}x",
            minDepth,
            maxDepth,
            weight,
            rewardMultiplier);

        handler->PSendSysMessage(
            "  chaoticLinks={} routeSpawns={} enabled={}",
            uint32(configuredStacks),
            routeSpawnCount,
            enabled ? "yes" : "no");

        return true;
    }

    static bool HandleReloadCommand(ChatHandler* handler)
    {
        bool const ok = ManastormMgr::Instance().ReloadData();

        ManastormDataStore const& store = ManastormDataStore::Instance();

        if (!ok)
        {
            handler->SendErrorMessage(
                "Manastorm: datastore reload failed. Check worldserver logs.");
            return false;
        }

        handler->PSendSysMessage(
            "Manastorm: datastore reloaded. segments={} scalingPoints={} activeRuns={}. "
            "Existing runs keep their stage/scaling snapshots.",
            store.GetSegmentCount(),
            store.GetScalingPointCount(),
            ManastormMgr::Instance().GetActiveRunCount());

        return true;
    }

    static bool HandleGreedySpawnCommand(
        ChatHandler* handler)
    {
        Player* player =
            handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage(
                "Manastorm: this command requires "
                "an in-game player.");

            return false;
        }

        std::string error;

        if (!ManastormGreedyDemon::Instance()
            .ForceSpawn(
                player,
                error))
        {
            handler->PSendSysMessage(
                "Manastorm: {}",
                error);

            return true;
        }

        handler->SendSysMessage(
            "Manastorm: forced Greedy Demon encounter.");

        return true;
    }

    static bool HandleAffixForceCommand(
        ChatHandler* handler,
        uint32 affixId)
    {
        Player* player =
            handler->GetSession()
            ? handler->GetSession()->GetPlayer()
            : nullptr;

        if (!player)
        {
            handler->SendErrorMessage(
                "Manastorm: this command requires "
                "an in-game player.");

            return false;
        }

        std::string error;

        if (!ManastormMgr::Instance()
            .ForceStageAffix(
                player,
                affixId,
                error))
        {
            handler->PSendSysMessage(
                "Manastorm: {}",
                error);

            return true;
        }

        handler->PSendSysMessage(
            "Manastorm: forced affix {} onto "
            "the current stage.",
            affixId);

        ManastormRun const* run =
            ManastormMgr::Instance()
            .GetRunFor(player);

        if (run)
        {
            SendRunStatus(
                handler,
                *run);
        }

        return true;
    }
};

void AddSC_manastorm_commandscript()
{
    new manastorm_commandscript();
}
