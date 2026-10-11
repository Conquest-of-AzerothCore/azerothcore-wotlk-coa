#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "AllMapScript.h"
#include "Creature.h"
#include "GameObject.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr uint32 MAP_DIRE_MAUL = 429;
    constexpr uint32 NPC_IMMOLTHAR = 11496;
    constexpr uint32 NPC_HELNURATH = 14506;
    constexpr uint32 NPC_CAPTAIN_KROMCRUSH = 14325;
    constexpr uint32 NPC_KING_GORDOK = 11501;
    constexpr uint32 SEGMENT_KING_GORDOK_NORMAL = 148;
    constexpr uint32 SEGMENT_KING_GORDOK_ENDGAME = 279;
    constexpr float KING_GORDOK_START_X = 626.547f;
    constexpr float KING_GORDOK_START_Y = 482.21f;
    constexpr float KROMCRUSH_CLEAR_RADIUS = 190.0f;
    constexpr uint32 SEGMENT_HELNURATH_NORMAL = 687;
    constexpr uint32 SEGMENT_HELNURATH_ENDGAME = 688;
    constexpr uint32 SEGMENT_NORMAL = 686;
    constexpr uint32 SEGMENT_ENDGAME = 685;
    constexpr uint32 TYPE_PYLONS_STATE = 2;
    constexpr uint32 ALL_PYLONS_OFF = 0x1F;
    constexpr uint32 GO_FORCE_FIELD = 179503;

    class manastorm_dire_maul_immolthar : public AllMapScript
    {
    public:
        manastorm_dire_maul_immolthar() : AllMapScript("manastorm_dire_maul_immolthar") { }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() || !map || !player ||
                map->GetId() != MAP_DIRE_MAUL || !map->IsScriptedPrivateInstance())
                return;

            ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
            if (!run || run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
                return;

            ManastormSegment const& segment = run->GetSegment();
            if (segment.MapId != MAP_DIRE_MAUL)
                return;

            bool const immoltharStage =
                segment.ObjectiveCreatureEntry == NPC_IMMOLTHAR &&
                (segment.SegmentId == SEGMENT_NORMAL ||
                 segment.SegmentId == SEGMENT_ENDGAME);
            bool const helnurathStage =
                segment.ObjectiveCreatureEntry == NPC_HELNURATH &&
                (segment.SegmentId == SEGMENT_HELNURATH_NORMAL ||
                 segment.SegmentId == SEGMENT_HELNURATH_ENDGAME);

            if (!immoltharStage && !helnurathStage)
                return;

            InstanceMap* instanceMap = map->ToInstanceMap();
            InstanceScript* instance = instanceMap ? instanceMap->GetInstanceScript() : nullptr;
            if (!instance)
            {
                LOG_WARN("module.manastorm.endless",
                    "Immol'thar instance script missing: run={} segment={} instance={}.",
                    run->GetRunId(), segment.SegmentId, run->GetInstanceId());
                return;
            }

            // Open the native force field in either private encounter.
            // Hel'nurath's stage suppresses Immol'thar separately.
            instance->SetData(TYPE_PYLONS_STATE, ALL_PYLONS_OFF);

            // Handle a force field already loaded at player arrival.
            if (GameObject* field = player->FindNearestGameObject(GO_FORCE_FIELD, 130.0f))
            {
                field->AllowSaveToDB(false);
                if (field->GetGoState() != GO_STATE_ACTIVE)
                    field->SetGoState(GO_STATE_ACTIVE);
            }

            LOG_INFO("module.manastorm.endless",
                "Immol'thar released: run={} segment={} instance={}.",
                run->GetRunId(), segment.SegmentId, run->GetInstanceId());
        }
    };
    // The King Gordok start point overlaps the native Captain Kromcrush.
    // This is a fallback for DB spawns that loaded before the private stage
    // was registered. OnCreatureAddWorld handles later grid loads separately.
    class manastorm_dire_maul_king_gordok_kromcrush : public AllMapScript
    {
    public:
        manastorm_dire_maul_king_gordok_kromcrush()
            : AllMapScript("manastorm_dire_maul_king_gordok_kromcrush") { }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() || !map || !player ||
                map->GetId() != MAP_DIRE_MAUL || !map->IsScriptedPrivateInstance())
                return;

            ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
            if (!run || run->GetInstanceId() != map->GetInstanceId() ||
                (run->GetState() != ManastormRunState::Preparing &&
                 run->GetState() != ManastormRunState::Active))
                return;

            ManastormSegment const& segment = run->GetSegment();
            if (segment.MapId != MAP_DIRE_MAUL ||
                segment.ObjectiveCreatureEntry != NPC_KING_GORDOK ||
                (segment.SegmentId != SEGMENT_KING_GORDOK_NORMAL &&
                 segment.SegmentId != SEGMENT_KING_GORDOK_ENDGAME))
                return;

            // Load only the authored arrival grid: this isn't a map-wide scan.
            map->LoadGrid(KING_GORDOK_START_X, KING_GORDOK_START_Y);

            Creature* captain = player->FindNearestCreature(
                NPC_CAPTAIN_KROMCRUSH, KROMCRUSH_CLEAR_RADIUS, true);
            if (!captain || captain->GetMap() != map ||
                captain->GetInstanceId() != run->GetInstanceId() ||
                !captain->GetSpawnId())
                return;

            ObjectGuid::LowType const spawnId = captain->GetSpawnId();
            captain->DespawnOrUnsummon(0ms, 24h);

            LOG_INFO("module.manastorm.endless",
                "Suppressed preloaded Captain Kromcrush for private "
                "King Gordok stage: run={} segment={} instance={} spawn={}.",
                run->GetRunId(), segment.SegmentId,
                run->GetInstanceId(), spawnId);
        }
    };
}

void AddSC_manastorm_dire_maul_compat()
{
    new manastorm_dire_maul_immolthar();
    new manastorm_dire_maul_king_gordok_kromcrush();
}
