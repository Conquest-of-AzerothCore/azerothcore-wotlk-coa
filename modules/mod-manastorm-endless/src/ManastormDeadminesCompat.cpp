#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllMapScript.h"
#include "Creature.h"
#include "GameObject.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";

    constexpr uint32 MAP_DEADMINES = 36;
    constexpr uint32 NPC_CAPTAIN_GREENSKIN = 647;
    constexpr uint32 NPC_EDWIN_VANCLEEF = 639;
    constexpr uint32 SEGMENT_GREENSKIN_NORMAL = 126;
    constexpr uint32 SEGMENT_GREENSKIN_ENDGAME = 228;
    constexpr uint32 SEGMENT_VANCLEEF_NORMAL = 129;
    constexpr uint32 SEGMENT_VANCLEEF_ENDGAME = 551;

    // VanCleef's teleport is intentionally identical to Greenskin's.
    // Use its known grid/arrival position; Greenskin's DB spawn GUID
    // was not provided, so use a bounded nearby-creature lookup instead.
    constexpr float GREENSKIN_ANCHOR_X = -100.544f;
    constexpr float GREENSKIN_ANCHOR_Y = -791.458f;
    constexpr float GREENSKIN_SEARCH_RANGE = 120.0f;


    // Exact persistent spawn from the in-game DB GUID tooltip.
    constexpr ObjectGuid::LowType VANCLEEF_SPAWN_ID = 79336;
    constexpr float VANCLEEF_X = -87.369f;
    constexpr float VANCLEEF_Y = -819.895f;

    constexpr uint32 NPC_SNEEDS_SHREDDER = 642;
    constexpr uint32 SEGMENT_SNEED_NORMAL = 113;
    constexpr uint32 SEGMENT_SNEED_ENDGAME = 213;

    constexpr ObjectGuid::LowType DOOR_SPAWN_ID = 26183;
    constexpr uint32 GO_HEAVY_DOOR = 17153;

    // Exact location of the Heavy Door, provided by the in-game GM tooltip.
    constexpr float DOOR_X = -262.714f;
    constexpr float DOOR_Y = -482.361f;

    bool IsSneedStage(ManastormRun const& run)
    {
        ManastormSegment const& segment = run.GetSegment();

        return segment.MapId == MAP_DEADMINES &&
            segment.ObjectiveCreatureEntry == NPC_SNEEDS_SHREDDER &&
            (segment.SegmentId == SEGMENT_SNEED_NORMAL ||
             segment.SegmentId == SEGMENT_SNEED_ENDGAME);
    }


    bool IsGreenskinStage(ManastormRun const& run)
    {
        ManastormSegment const& segment = run.GetSegment();

        return segment.MapId == MAP_DEADMINES &&
            segment.ObjectiveCreatureEntry == NPC_CAPTAIN_GREENSKIN &&
            (segment.SegmentId == SEGMENT_GREENSKIN_NORMAL ||
             segment.SegmentId == SEGMENT_GREENSKIN_ENDGAME);
    }

    class manastorm_deadmines_greenskin_vancleef : public AllMapScript
    {
    public:
        manastorm_deadmines_greenskin_vancleef()
            : AllMapScript("manastorm_deadmines_greenskin_vancleef")
        {
        }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() != MAP_DEADMINES ||
                !map->IsScriptedPrivateInstance())
            {
                return;
            }

            ManastormRun const* run =
                ManastormMgr::Instance().GetRunFor(player);

            if (!run ||
                !IsGreenskinStage(*run) ||
                run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
            {
                return;
            }

            // VanCleef is near Greenskin's authored route. Load only his
            // known grid so the DB spawn is available even if his area was
            // outside the first player's initial visibility range.
            map->LoadGrid(VANCLEEF_X, VANCLEEF_Y);

            auto& spawns = map->GetCreatureBySpawnIdStore();
            auto const range = spawns.equal_range(VANCLEEF_SPAWN_ID);

            for (auto itr = range.first; itr != range.second; ++itr)
            {
                Creature* vancleef = itr->second;

                if (!vancleef ||
                    !vancleef->IsInWorld() ||
                    vancleef->GetEntry() != NPC_EDWIN_VANCLEEF ||
                    vancleef->GetSpawnId() != VANCLEEF_SPAWN_ID)
                {
                    continue;
                }

                // A second party member may enter after he was removed.
                if (!vancleef->IsAlive())
                    return;

                // The map and instance guards above ensure this only touches
                // VanCleef's real DB spawn in the disposable Greenskin stage.
                // Keep him down longer than an Endless stage can reasonably
                // last; don't modify or delete his world database record.
                vancleef->DespawnOrUnsummon(0ms, 24h);

                LOG_INFO(
                    LOG_FILTER,
                    "Despawned nearby Edwin VanCleef for private Manastorm Greenskin stage: "
                    "run={} segment={} instance={} spawn={} entry={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetInstanceId(),
                    VANCLEEF_SPAWN_ID,
                    NPC_EDWIN_VANCLEEF);
                return;
            }

            LOG_WARN(
                LOG_FILTER,
                "Could not find Edwin VanCleef DB spawn for Manastorm Greenskin stage: "
                "run={} segment={} instance={} spawn={} entry={}.",
                run->GetRunId(),
                run->GetSegment().SegmentId,
                run->GetInstanceId(),
                VANCLEEF_SPAWN_ID,
                NPC_EDWIN_VANCLEEF);
        }
    };


    bool IsVanCleefStage(ManastormRun const& run)
    {
        ManastormSegment const& segment = run.GetSegment();

        return segment.MapId == MAP_DEADMINES &&
            segment.ObjectiveCreatureEntry == NPC_EDWIN_VANCLEEF &&
            (segment.SegmentId == SEGMENT_VANCLEEF_NORMAL ||
             segment.SegmentId == SEGMENT_VANCLEEF_ENDGAME);
    }

    class manastorm_deadmines_vancleef_greenskin : public AllMapScript
    {
    public:
        manastorm_deadmines_vancleef_greenskin()
            : AllMapScript("manastorm_deadmines_vancleef_greenskin")
        {
        }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() != MAP_DEADMINES ||
                !map->IsScriptedPrivateInstance())
            {
                return;
            }

            ManastormRun const* run =
                ManastormMgr::Instance().GetRunFor(player);

            if (!run ||
                !IsVanCleefStage(*run) ||
                run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
            {
                return;
            }

            // Both bosses share this route. Touch only the known anchor grid
            // and find Greenskin near the player; no map-wide creature scan.
            map->LoadGrid(GREENSKIN_ANCHOR_X, GREENSKIN_ANCHOR_Y);

            Creature* greenskin =
                player->FindNearestCreature(
                    NPC_CAPTAIN_GREENSKIN,
                    GREENSKIN_SEARCH_RANGE,
                    true);

            if (!greenskin ||
                greenskin->GetMap() != map ||
                greenskin->GetInstanceId() != run->GetInstanceId() ||
                !greenskin->GetSpawnId())
            {
                LOG_WARN(
                    LOG_FILTER,
                    "Captain Greenskin not found near private Manastorm VanCleef start: "
                    "run={} segment={} instance={} searchRange={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetInstanceId(),
                    GREENSKIN_SEARCH_RANGE);
                return;
            }

            // Suppress only this private stage's native Greenskin spawn.
            // Record its DB GUID before despawn (the creature may be removed).
            ObjectGuid::LowType const spawnId = greenskin->GetSpawnId();
            greenskin->DespawnOrUnsummon(0ms, 24h);

            LOG_INFO(
                LOG_FILTER,
                "Despawned nearby Captain Greenskin for private Manastorm VanCleef stage: "
                "run={} segment={} instance={} spawn={} entry={}.",
                run->GetRunId(),
                run->GetSegment().SegmentId,
                run->GetInstanceId(),
                spawnId,
                NPC_CAPTAIN_GREENSKIN);
        }
    };

    class manastorm_deadmines_sneed_door : public AllMapScript
    {
    public:
        manastorm_deadmines_sneed_door()
            : AllMapScript("manastorm_deadmines_sneed_door")
        {
        }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() != MAP_DEADMINES ||
                !map->IsScriptedPrivateInstance())
            {
                return;
            }

            ManastormRun const* run =
                ManastormMgr::Instance().GetRunFor(player);

            if (!run ||
                !IsSneedStage(*run) ||
                run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
            {
                return;
            }

            // The door can be outside the arrival grid. Load only its known
            // grid; never scan all world objects or force every dungeon grid.
            map->LoadGrid(DOOR_X, DOOR_Y);

            auto& spawns = map->GetGameObjectBySpawnIdStore();
            auto const range = spawns.equal_range(DOOR_SPAWN_ID);

            for (auto itr = range.first; itr != range.second; ++itr)
            {
                GameObject* door = itr->second;

                if (!door ||
                    !door->IsInWorld() ||
                    door->GetEntry() != GO_HEAVY_DOOR ||
                    door->GetSpawnId() != DOOR_SPAWN_ID)
                {
                    continue;
                }

                // Deadmines' instance script explicitly enables database
                // state saving for doors. This override must remain private:
                // never write the forced-open state to instance_saved_data.
                door->AllowSaveToDB(false);

                // Idempotent: don't toggle an already-open door back closed.
                // Direct state activation avoids a timed auto-close.
                if (door->GetGoState() != GO_STATE_ACTIVE)
                    door->SetGoState(GO_STATE_ACTIVE);

                LOG_INFO(
                    LOG_FILTER,
                    "Opened Deadmines Heavy Door for private Manastorm Sneed stage: "
                    "run={} segment={} instance={} spawn={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetInstanceId(),
                    DOOR_SPAWN_ID);
                return;
            }

            LOG_WARN(
                LOG_FILTER,
                "Could not find Deadmines Heavy Door for private Manastorm Sneed stage: "
                "run={} segment={} instance={} spawn={} entry={}.",
                run->GetRunId(),
                run->GetSegment().SegmentId,
                run->GetInstanceId(),
                DOOR_SPAWN_ID,
                GO_HEAVY_DOOR);
        }
    };
}

void AddSC_manastorm_deadmines_compat()
{
    new manastorm_deadmines_sneed_door();
    new manastorm_deadmines_greenskin_vancleef();
    new manastorm_deadmines_vancleef_greenskin();
}
