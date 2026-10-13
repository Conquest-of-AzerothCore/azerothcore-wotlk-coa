#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "AllMapScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr uint32 MAP_BLACKFATHOM_DEEPS = 48;
    constexpr uint32 NPC_AKU_MAI = 4829;
    constexpr uint32 GO_AKU_MAI_DOOR = 21117;
    constexpr uint32 SEGMENT_AKU_MAI_NORMAL = 81;
    constexpr uint32 SEGMENT_AKU_MAI_ENDGAME = 244;

    // The player-authored destination is used ONLY to select the closest
    // native DB spawn when more than one record exists. Do not hardcode
    // door/boss coordinates or move their world spawns.
    constexpr float AKU_MAI_TELE_X = -817.61f;
    constexpr float AKU_MAI_TELE_Y = -211.539f;

    class manastorm_blackfathom_deeps_aku_mai_gate : public AllMapScript
    {
    public:
        manastorm_blackfathom_deeps_aku_mai_gate()
            : AllMapScript("manastorm_blackfathom_deeps_aku_mai_gate") { }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() || !map || !player ||
                map->GetId() != MAP_BLACKFATHOM_DEEPS ||
                !map->IsScriptedPrivateInstance())
                return;

            ManastormRun const* run =
                ManastormMgr::Instance().GetRunFor(player);

            if (!run || run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
                return;

            ManastormSegment const& segment = run->GetSegment();
            if (segment.MapId != MAP_BLACKFATHOM_DEEPS ||
                segment.ObjectiveCreatureEntry != NPC_AKU_MAI ||
                (segment.SegmentId != SEGMENT_AKU_MAI_NORMAL &&
                 segment.SegmentId != SEGMENT_AKU_MAI_ENDGAME))
                return;

            // Native BFD gates GO 21117 behind all four fires and their
            // summoned wave kills. This standalone Manastorm stage starts at
            // Aku'mai, so open that physical door ONLY in this private run.
            //
            // Do not mark the fires complete, suppress encounter NPCs, or
            // change the world's gameobject/creature tables.
            QueryResult doorSpawn = WorldDatabase.Query(
                "SELECT `guid`, `position_x`, `position_y` "
                "FROM `gameobject` "
                "WHERE `map` = 48 AND `id` = 21117 "
                "AND (`spawnMask` & 1) <> 0 "
                "ORDER BY POW(`position_x` - {}, 2) + "
                "POW(`position_y` - {}, 2), `guid` LIMIT 1",
                AKU_MAI_TELE_X, AKU_MAI_TELE_Y);

            if (!doorSpawn)
            {
                LOG_WARN("module.manastorm.endless",
                    "Private Aku'mai stage missing native BFD door "
                    "GO 21117: run={} segment={} instance={}.",
                    run->GetRunId(), segment.SegmentId, run->GetInstanceId());
                return;
            }

            Field* fields = doorSpawn->Fetch();
            ObjectGuid::LowType const doorSpawnId =
                fields[0].Get<uint32>();

            map->LoadGrid(
                fields[1].Get<float>(),
                fields[2].Get<float>());

            bool openedDoor = false;
            auto const& bySpawnId = map->GetGameObjectBySpawnIdStore();
            auto const bounds = bySpawnId.equal_range(doorSpawnId);

            for (auto itr = bounds.first; itr != bounds.second; ++itr)
            {
                GameObject* door = itr->second;
                if (!door || !door->IsInWorld() ||
                    door->GetEntry() != GO_AKU_MAI_DOOR)
                    continue;

                if (door->GetGoState() != GO_STATE_ACTIVE)
                    door->SetGoState(GO_STATE_ACTIVE);

                openedDoor = true;
                break;
            }

            if (!openedDoor)
            {
                LOG_WARN("module.manastorm.endless",
                    "Private Aku'mai stage could not open native BFD door: "
                    "run={} segment={} instance={} doorSpawn={}.",
                    run->GetRunId(), segment.SegmentId,
                    run->GetInstanceId(), doorSpawnId);
            }

            // Some authored portals may land outside the last boss's grid.
            // Preload only Aku'mai's actual persistent DB spawn grid so
            // the normal creature loading/Manastorm objective hooks can
            // find the native boss; never summon a duplicate.
            QueryResult bossSpawn = WorldDatabase.Query(
                "SELECT `position_x`, `position_y` "
                "FROM `creature` "
                "WHERE `map` = 48 AND `id` = 4829 "
                "AND (`spawnMask` & 1) <> 0 "
                "ORDER BY POW(`position_x` - {}, 2) + "
                "POW(`position_y` - {}, 2), `guid` LIMIT 1",
                AKU_MAI_TELE_X, AKU_MAI_TELE_Y);

            if (bossSpawn)
            {
                Field* bossFields = bossSpawn->Fetch();
                map->LoadGrid(
                    bossFields[0].Get<float>(),
                    bossFields[1].Get<float>());
            }
            else
            {
                LOG_WARN("module.manastorm.endless",
                    "No native Aku'mai (4829) creature spawn found in "
                    "BFD world DB: run={} segment={} instance={}.",
                    run->GetRunId(), segment.SegmentId,
                    run->GetInstanceId());
            }

            if (openedDoor)
            {
                LOG_INFO("module.manastorm.endless",
                    "Opened native BFD Aku'mai door only in private "
                    "Manastorm: run={} segment={} instance={} spawn={}.",
                    run->GetRunId(), segment.SegmentId,
                    run->GetInstanceId(), doorSpawnId);
            }
        }
    };
}

void AddSC_manastorm_blackfathom_deeps_compat()
{
    new manastorm_blackfathom_deeps_aku_mai_gate();
}
