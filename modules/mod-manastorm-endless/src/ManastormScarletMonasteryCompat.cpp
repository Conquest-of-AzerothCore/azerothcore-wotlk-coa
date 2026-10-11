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

    constexpr uint32 MAP_SCARLET_MONASTERY = 189;
    constexpr uint32 NPC_HEROD = 3975;
    constexpr uint32 SEGMENT_HEROD_NORMAL = 110;
    constexpr uint32 SEGMENT_HEROD_ENDGAME = 315;

    // Exact persistent Herod's Door spawn from the in-game GM tooltip.
    constexpr ObjectGuid::LowType HEROD_DOOR_SPAWN_ID = 32250;
    constexpr uint32 GO_HEROD_DOOR = 101854;
    constexpr float HEROD_DOOR_X = 1933.69f;
    constexpr float HEROD_DOOR_Y = -431.654f;

    class manastorm_scarlet_monastery_herod_door : public AllMapScript
    {
    public:
        manastorm_scarlet_monastery_herod_door()
            : AllMapScript("manastorm_scarlet_monastery_herod_door")
        {
        }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() != MAP_SCARLET_MONASTERY ||
                !map->IsScriptedPrivateInstance())
            {
                return;
            }

            ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
            if (!run ||
                run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
            {
                return;
            }

            ManastormSegment const& segment = run->GetSegment();
            if (segment.MapId != MAP_SCARLET_MONASTERY ||
                segment.ObjectiveCreatureEntry != NPC_HEROD ||
                (segment.SegmentId != SEGMENT_HEROD_NORMAL &&
                 segment.SegmentId != SEGMENT_HEROD_ENDGAME))
            {
                return;
            }

            // The door lies beyond Herod's selected arrival grid. Load only
            // its known location, never unrelated dungeon grids or world GOs.
            map->LoadGrid(HEROD_DOOR_X, HEROD_DOOR_Y);

            auto& spawns = map->GetGameObjectBySpawnIdStore();
            auto const range = spawns.equal_range(HEROD_DOOR_SPAWN_ID);
            for (auto itr = range.first; itr != range.second; ++itr)
            {
                GameObject* door = itr->second;
                if (!door ||
                    !door->IsInWorld() ||
                    door->GetEntry() != GO_HEROD_DOOR ||
                    door->GetSpawnId() != HEROD_DOOR_SPAWN_ID)
                {
                    continue;
                }

                // Leave the permanent spawn and public dungeon untouched.
                // The forced-open state must not be saved to the instance DB.
                door->AllowSaveToDB(false);
                if (door->GetGoState() != GO_STATE_ACTIVE)
                    door->SetGoState(GO_STATE_ACTIVE);

                LOG_INFO(
                    LOG_FILTER,
                    "Opened Herod's Door for private Manastorm Scarlet Monastery stage: "
                    "run={} segment={} instance={} spawn={} entry={}.",
                    run->GetRunId(),
                    segment.SegmentId,
                    run->GetInstanceId(),
                    HEROD_DOOR_SPAWN_ID,
                    GO_HEROD_DOOR);
                return;
            }

            LOG_WARN(
                LOG_FILTER,
                "Could not find Herod's Door for private Manastorm stage: "
                "run={} segment={} instance={} spawn={} entry={}.",
                run->GetRunId(),
                segment.SegmentId,
                run->GetInstanceId(),
                HEROD_DOOR_SPAWN_ID,
                GO_HEROD_DOOR);
        }
    };
}

void AddSC_manastorm_scarlet_monastery_compat()
{
    new manastorm_scarlet_monastery_herod_door();
}
