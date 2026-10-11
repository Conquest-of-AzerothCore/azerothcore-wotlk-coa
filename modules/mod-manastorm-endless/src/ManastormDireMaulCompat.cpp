#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "AllMapScript.h"
#include "GameObject.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr uint32 MAP_DIRE_MAUL = 429;
    constexpr uint32 NPC_IMMOLTHAR = 11496;
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
            if (segment.MapId != MAP_DIRE_MAUL ||
                segment.ObjectiveCreatureEntry != NPC_IMMOLTHAR ||
                (segment.SegmentId != SEGMENT_NORMAL &&
                 segment.SegmentId != SEGMENT_ENDGAME))
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

            // Native Dire Maul releases Immol'thar when the five pylons are done.
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
}

void AddSC_manastorm_dire_maul_compat()
{
    new manastorm_dire_maul_immolthar();
}
