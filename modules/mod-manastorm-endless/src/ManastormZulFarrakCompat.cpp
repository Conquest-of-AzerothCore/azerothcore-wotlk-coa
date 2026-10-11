#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "AllMapScript.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr uint32 MAP_ZUL_FARRAK = 209;
    constexpr uint32 NPC_VELRATHA = 7795;
    constexpr uint32 NPC_CHIEF_UKORZ = 7267;
    constexpr uint32 NPC_RUUZLU = 7797;
    constexpr uint32 GO_ZUL_FARRAK_END_DOOR = 146084;
    constexpr uint32 SEGMENT_UKORZ_NORMAL = 696;
    constexpr uint32 SEGMENT_UKORZ_ENDGAME = 695;
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

    class manastorm_zul_farrak_ukorz_gate : public AllMapScript
    {
    public:
        manastorm_zul_farrak_ukorz_gate()
            : AllMapScript("manastorm_zul_farrak_ukorz_gate") { }

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
                segment.ObjectiveCreatureEntry != NPC_CHIEF_UKORZ ||
                (segment.SegmentId != SEGMENT_UKORZ_NORMAL &&
                 segment.SegmentId != SEGMENT_UKORZ_ENDGAME))
                return;

            InstanceMap* instanceMap = map->ToInstanceMap();
            InstanceScript* instance =
                instanceMap ? instanceMap->GetInstanceScript() : nullptr;
            if (!instance)
            {
                LOG_WARN("module.manastorm.endless",
                    "Missing Zul'Farrak instance script on private Chief Ukorz "
                    "stage: run={} segment={} instance={}.",
                    run->GetRunId(), segment.SegmentId, run->GetInstanceId());
                return;
            }

            // The native pyramid event opens GO 146084 only when completed.
            // In this isolated Manastorm stage the party teleports straight
            // into the boss area, so only open the original door; DO NOT
            // simulate the whole pyramid event, kill escort NPCs, or spawn
            // replacement Ukorz/Ruuzlu creatures (their DB spawns are native).
            //
            // Locate the physical door through its real DB spawn and load
            // exactly that grid, not the entire map. Do not hardcode an
            // unverified gate coordinate or modify the shared world DB.
            QueryResult gateLocation = WorldDatabase.Query(
                "SELECT `position_x`, `position_y` "
                "FROM `gameobject` "
                "WHERE `map` = 209 AND `id` = 146084 "
                "ORDER BY POW(`position_x` - 1781.65, 2) + "
                "POW(`position_y` - 1079.82, 2), `guid` "
                "LIMIT 1");

            if (!gateLocation)
            {
                LOG_WARN("module.manastorm.endless",
                    "Native Zul'Farrak end gate (146084) not found in DB: "
                    "run={} segment={} instance={}.",
                    run->GetRunId(), segment.SegmentId, run->GetInstanceId());
                return;
            }

            Field* fields = gateLocation->Fetch();
            map->LoadGrid(
                fields[0].Get<float>(),
                fields[1].Get<float>());

            ObjectGuid const gateGuid =
                instance->GetGuidData(GO_ZUL_FARRAK_END_DOOR);

            GameObject* gate =
                gateGuid.IsEmpty() ? nullptr : map->GetGameObject(gateGuid);

            if (!gate || gate->GetEntry() != GO_ZUL_FARRAK_END_DOOR)
            {
                LOG_WARN("module.manastorm.endless",
                    "Native Zul'Farrak end gate (146084) did not load for "
                    "private Chief Ukorz stage: run={} segment={} instance={}.",
                    run->GetRunId(), segment.SegmentId, run->GetInstanceId());
                return;
            }

            if (gate->GetGoState() != GO_STATE_ACTIVE)
                gate->SetGoState(GO_STATE_ACTIVE);

            LOG_INFO("module.manastorm.endless",
                "Opened native Zul'Farrak end gate only inside private "
                "Chief Ukorz stage: run={} segment={} instance={}; "
                "preserved boss={} and companion={}.",
                run->GetRunId(), segment.SegmentId,
                run->GetInstanceId(), NPC_CHIEF_UKORZ, NPC_RUUZLU);
        }
    };
}

void AddSC_manastorm_zul_farrak_compat()
{
    new manastorm_zul_farrak_velratha_gong();
    new manastorm_zul_farrak_ukorz_gate();
}
