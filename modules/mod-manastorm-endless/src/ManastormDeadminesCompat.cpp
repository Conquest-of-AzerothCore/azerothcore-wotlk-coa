#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllMapScript.h"
#include "GameObject.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";

    constexpr uint32 MAP_DEADMINES = 36;
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
}
