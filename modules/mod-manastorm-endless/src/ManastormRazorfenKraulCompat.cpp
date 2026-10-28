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

    constexpr uint32 MAP_RAZORFEN_KRAUL = 47;
    constexpr uint32 NPC_AGATHELOS_THE_RAGING = 4422;
    constexpr uint32 SEGMENT_AGATHELOS_NORMAL = 88;
    constexpr uint32 SEGMENT_AGATHELOS_ENDGAME = 401;

    // Exact persistent Ward of Agathelos spawn from the GM tooltip.
    // This is a barrier, not an objective; open it only in the disposable
    // Agathelos private stage, without bypassing the public dungeon event.
    constexpr ObjectGuid::LowType WARD_SPAWN_ID = 35698;
    constexpr uint32 GO_AGATHELOS_WARD = 21099;
    constexpr float WARD_X = 2060.41f;
    constexpr float WARD_Y = 2015.7f;

    bool IsAgathelosStage(ManastormRun const& run)
    {
        ManastormSegment const& segment = run.GetSegment();

        return segment.MapId == MAP_RAZORFEN_KRAUL &&
            segment.ObjectiveCreatureEntry == NPC_AGATHELOS_THE_RAGING &&
            (segment.SegmentId == SEGMENT_AGATHELOS_NORMAL ||
             segment.SegmentId == SEGMENT_AGATHELOS_ENDGAME);
    }

    class manastorm_razorfen_kraul_agathelos_ward : public AllMapScript
    {
    public:
        manastorm_razorfen_kraul_agathelos_ward()
            : AllMapScript("manastorm_razorfen_kraul_agathelos_ward")
        {
        }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() != MAP_RAZORFEN_KRAUL ||
                !map->IsScriptedPrivateInstance())
            {
                return;
            }

            ManastormRun const* run =
                ManastormMgr::Instance().GetRunFor(player);

            if (!run ||
                !IsAgathelosStage(*run) ||
                run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
            {
                return;
            }

            // Agathelos's ward is outside the authored arrival grid.
            // Load only its known location rather than scanning the map.
            map->LoadGrid(WARD_X, WARD_Y);

            auto& spawns = map->GetGameObjectBySpawnIdStore();
            auto const range = spawns.equal_range(WARD_SPAWN_ID);

            for (auto itr = range.first; itr != range.second; ++itr)
            {
                GameObject* ward = itr->second;

                if (!ward ||
                    !ward->IsInWorld() ||
                    ward->GetEntry() != GO_AGATHELOS_WARD ||
                    ward->GetSpawnId() != WARD_SPAWN_ID)
                {
                    continue;
                }

                // Never save the forced-open state to instance_saved_data.
                // Activating the native ward opens its collision/visual path
                // without removing its persistent world spawn.
                ward->AllowSaveToDB(false);

                // Idempotent for additional group members entering later.
                if (ward->GetGoState() != GO_STATE_ACTIVE)
                    ward->SetGoState(GO_STATE_ACTIVE);

                LOG_INFO(
                    LOG_FILTER,
                    "Opened Ward of Agathelos for private Manastorm Razorfen Kraul stage: "
                    "run={} segment={} instance={} spawn={} entry={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetInstanceId(),
                    WARD_SPAWN_ID,
                    GO_AGATHELOS_WARD);
                return;
            }

            LOG_WARN(
                LOG_FILTER,
                "Could not find Ward of Agathelos for private Manastorm stage: "
                "run={} segment={} instance={} spawn={} entry={}.",
                run->GetRunId(),
                run->GetSegment().SegmentId,
                run->GetInstanceId(),
                WARD_SPAWN_ID,
                GO_AGATHELOS_WARD);
        }
    };
}

void AddSC_manastorm_razorfen_kraul_compat()
{
    new manastorm_razorfen_kraul_agathelos_ward();
}
