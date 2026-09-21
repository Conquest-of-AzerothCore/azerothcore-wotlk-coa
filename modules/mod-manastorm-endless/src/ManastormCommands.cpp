#include "ManastormMgr.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Player.h"
#include "Group.h"
#include "ManastormProgression.h"
#include "ManastormDataStore.h"

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
            "`map_id`, "
            "`objective_creature_entry`, "
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
            "FROM `manastorm_chaotic_link_spawn` "
            "WHERE `segment_id` = {} "
            "AND `enabled` = 1",
            segmentId);

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
            "Scaling: HP={:.3f}x GlobalDamage={:.3f}x Melee={:.3f}x Spell={:.3f}x",
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

        static ChatCommandTable segmentCommandTable =
        {
            { "info", HandleSegmentInfoCommand, SEC_GAMEMASTER, Console::No },
        };

        static ChatCommandTable affixCommandTable =
        {
            { "force", HandleAffixForceCommand, SEC_GAMEMASTER, Console::No },
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
            { "segment", segmentCommandTable },
            { "affix",   affixCommandTable },

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

        if (!ManastormProgression::LoadSnapshot(
            player->GetGUID().GetCounter(),
            mode,
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
            "SELECT `enabled` "
            "FROM `manastorm_chaotic_link_spawn` "
            "WHERE `segment_id` = {} "
            "AND `spawn_guid` = {} "
            "LIMIT 1",
            segmentId,
            spawnId);

        if (existing &&
            existing->Fetch()[0].Get<uint8>() != 0)
        {
            handler->PSendSysMessage(
                "Manastorm: spawn {} is already a Chaotic Link "
                "for segment {}.",
                spawnId,
                segmentId);

            return true;
        }


        WorldDatabase.DirectExecute(
            "INSERT INTO `manastorm_chaotic_link_spawn` "
            "(`segment_id`, `spawn_guid`, `enabled`) "
            "VALUES ({}, {}, 1) "
            "ON DUPLICATE KEY UPDATE `enabled` = 1",
            segmentId,
            spawnId);


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
            "SELECT 1 "
            "FROM `manastorm_chaotic_link_spawn` "
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

        WorldDatabase.DirectExecute(
            "DELETE FROM `manastorm_chaotic_link_spawn` "
            "WHERE `segment_id` = {} "
            "AND `spawn_guid` = {}",
            segmentId,
            spawnId);

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
            "l.`spawn_guid`, "
            "COALESCE(c.`id1`, 0), "
            "l.`enabled` "
            "FROM `manastorm_chaotic_link_spawn` l "
            "LEFT JOIN `creature` c "
            "ON c.`guid` = l.`spawn_guid` "
            "WHERE l.`segment_id` = {} "
            "ORDER BY l.`spawn_guid`",
            segmentId);

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

            bool const enabled =
                fields[2].Get<uint8>() != 0;

            handler->PSendSysMessage(
                "  spawn={} entry={} enabled={}",
                spawnId,
                entry,
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

        WorldDatabase.DirectExecute(
            "DELETE FROM `manastorm_chaotic_link_spawn` "
            "WHERE `segment_id` = {}",
            segmentId);

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

    static bool HandleSegmentInfoCommand(
        ChatHandler* handler,
        uint32 segmentId)
    {
        QueryResult result = WorldDatabase.Query(
            "SELECT "
            "`map_id`, "
            "`difficulty`, "
            "`dungeon_encounter_id`, "
            "`objective_creature_entry`, "
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

        uint32 const mapId =
            fields[0].Get<uint32>();

        uint8 const difficulty =
            fields[1].Get<uint8>();

        uint32 const encounterId =
            fields[2].Get<uint32>();

        uint32 const objectiveEntry =
            fields[3].Get<uint32>();

        uint32 const teleId =
            fields[4].Get<uint32>();

        uint32 const weight =
            fields[5].Get<uint32>();

        uint32 const minDepth =
            fields[6].Get<uint32>();

        uint32 const maxDepth =
            fields[7].Get<uint32>();

        float const rewardMultiplier =
            fields[8].Get<float>();

        uint8 const configuredStacks =
            fields[9].Get<uint8>();

        bool const enabled =
            fields[10].Get<uint8>() != 0;

        uint32 const routeSpawnCount =
            GetChaoticLinkCount(segmentId);

        handler->PSendSysMessage(
            "Manastorm segment {}:",
            segmentId);

        handler->PSendSysMessage(
            "  map={} difficulty={} encounter={}",
            mapId,
            uint32(difficulty),
            encounterId);

        handler->PSendSysMessage(
            "  objectiveEntry={} startTele={}",
            objectiveEntry,
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
