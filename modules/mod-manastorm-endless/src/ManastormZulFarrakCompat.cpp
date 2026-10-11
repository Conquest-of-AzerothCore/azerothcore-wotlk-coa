#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "AllMapScript.h"
#include "GameObject.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr uint32 MAP_ZUL_FARRAK = 209;
    constexpr uint32 NPC_VELRATHA = 7795;
    constexpr uint32 SEGMENT_VELRATHA_NORMAL = 538;
    constexpr uint32 SEGMENT_VELRATHA_ENDGAME = 548;

    // In-game inspection of the real Gong of Zul'Farrak.
    constexpr uint32 GO_GONG_OF_ZUL_FARRAK = 141832;
    constexpr ObjectGuid::LowType GONG_SPAWN_ID = 27140;
    constexpr float GONG_X = 1650.91f;
    constexpr float GONG_Y = 1171.88f;
    constexpr float GONG_SEARCH_RANGE = 115.0f;

    class manastorm_zul_farrak_velratha_gong : public AllMapScript
    {
    public:
        manastorm_zul_farrak_velratha_gong()
            : AllMapScript("manastorm_zul_farrak_velratha_gong") { }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() || !map || !player ||
                map->GetId() != MAP_ZUL_FARRAK ||
                !map->IsScriptedPrivateInstance())
                return;

            ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
            if (!run || run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
                return;

            ManastormSegment const& segment = run->GetSegment();
            if (segment.MapId != MAP_ZUL_FARRAK ||
                segment.ObjectiveCreatureEntry != NPC_VELRATHA ||
                (segment.SegmentId != SEGMENT_VELRATHA_NORMAL &&
                 segment.SegmentId != SEGMENT_VELRATHA_ENDGAME))
                return;

            // The same entrance is used by the Gahz'rilla segment.
            // Disable the gong's interaction in THIS private stage only.
            // Keep the world DB gameobject, GUID, and regular dungeon intact.
            map->LoadGrid(GONG_X, GONG_Y);

            GameObject* gong = player->FindNearestGameObject(
                GO_GONG_OF_ZUL_FARRAK,
                GONG_SEARCH_RANGE);

            if (!gong || gong->GetMap() != map ||
                gong->GetSpawnId() != GONG_SPAWN_ID)
            {
                LOG_WARN("module.manastorm.endless",
                    "Private Velratha gong missing or unexpected GUID: "
                    "run={} segment={} instance={} expectedSpawn={}.",
                    run->GetRunId(), segment.SegmentId,
                    run->GetInstanceId(), GONG_SPAWN_ID);
                return;
            }

            if (!gong->HasGameObjectFlag(GO_FLAG_NOT_SELECTABLE))
                gong->SetGameObjectFlag(GO_FLAG_NOT_SELECTABLE);

            LOG_INFO("module.manastorm.endless",
                "Disabled native Zul'Farrak gong interaction for private "
                "Velratha stage: run={} segment={} instance={} spawn={}.",
                run->GetRunId(), segment.SegmentId,
                run->GetInstanceId(), GONG_SPAWN_ID);
        }
    };
}

void AddSC_manastorm_zul_farrak_compat()
{
    new manastorm_zul_farrak_velratha_gong();
}
