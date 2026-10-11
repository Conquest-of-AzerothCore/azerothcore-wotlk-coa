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
    constexpr uint32 NPC_WHITEMANE = 3977;
    constexpr uint32 SEGMENT_WHITEMANE_NORMAL = 528;
    constexpr uint32 SEGMENT_WHITEMANE_ENDGAME = 532;

    // Exact persistent Herod's Door spawn from the in-game GM tooltip.
    constexpr ObjectGuid::LowType HEROD_DOOR_SPAWN_ID = 32250;
    constexpr uint32 GO_HEROD_DOOR = 101854;
    constexpr float HEROD_DOOR_X = 1933.69f;
    constexpr float HEROD_DOOR_Y = -431.654f;

    // Exact outer Chapel Door spawn; the inner Whitemane door remains native.
    constexpr ObjectGuid::LowType CHAPEL_DOOR_SPAWN_ID = 11875;
    constexpr uint32 GO_CHAPEL_DOOR = 104591;
    constexpr float CHAPEL_DOOR_X = 1069.95f;
    constexpr float CHAPEL_DOOR_Y = 1399.14f;

    class manastorm_scarlet_monastery_private_doors : public AllMapScript
    {
    public:
        manastorm_scarlet_monastery_private_doors()
            : AllMapScript("manastorm_scarlet_monastery_private_doors")
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
            if (segment.MapId != MAP_SCARLET_MONASTERY)
                return;

            bool const herodStage =
                segment.ObjectiveCreatureEntry == NPC_HEROD &&
                (segment.SegmentId == SEGMENT_HEROD_NORMAL ||
                 segment.SegmentId == SEGMENT_HEROD_ENDGAME);

            bool const whitemaneStage =
                segment.ObjectiveCreatureEntry == NPC_WHITEMANE &&
                (segment.SegmentId == SEGMENT_WHITEMANE_NORMAL ||
                 segment.SegmentId == SEGMENT_WHITEMANE_ENDGAME);

            if (!herodStage && !whitemaneStage)
                return;

            ObjectGuid::LowType const spawnId =
                herodStage ? HEROD_DOOR_SPAWN_ID : CHAPEL_DOOR_SPAWN_ID;
            uint32 const entry = herodStage ? GO_HEROD_DOOR : GO_CHAPEL_DOOR;
            float const x = herodStage ? HEROD_DOOR_X : CHAPEL_DOOR_X;
            float const y = herodStage ? HEROD_DOOR_Y : CHAPEL_DOOR_Y;
            char const* doorName = herodStage ? "Herod's Door" : "Chapel Door";

            // Only load the exact barrier grid for the selected private stage.
            map->LoadGrid(x, y);

            auto& spawns = map->GetGameObjectBySpawnIdStore();
            auto const range = spawns.equal_range(spawnId);
            for (auto itr = range.first; itr != range.second; ++itr)
            {
                GameObject* door = itr->second;
                if (!door ||
                    !door->IsInWorld() ||
                    door->GetEntry() != entry ||
                    door->GetSpawnId() != spawnId)
                {
                    continue;
                }

                // Keep the permanent spawn and ordinary instances untouched.
                door->AllowSaveToDB(false);
                if (door->GetGoState() != GO_STATE_ACTIVE)
                    door->SetGoState(GO_STATE_ACTIVE);

                LOG_INFO(
                    LOG_FILTER,
                    "Opened {} for private Manastorm Scarlet Monastery stage: "
                    "run={} segment={} instance={} spawn={} entry={}.",
                    doorName,
                    run->GetRunId(),
                    segment.SegmentId,
                    run->GetInstanceId(),
                    spawnId,
                    entry);
                return;
            }

            LOG_WARN(
                LOG_FILTER,
                "Could not find {} for private Manastorm stage: "
                "run={} segment={} instance={} spawn={} entry={}.",
                doorName,
                run->GetRunId(),
                segment.SegmentId,
                run->GetInstanceId(),
                spawnId,
                entry);
        }
    };
}

void AddSC_manastorm_scarlet_monastery_compat()
{
    new manastorm_scarlet_monastery_private_doors();
}
