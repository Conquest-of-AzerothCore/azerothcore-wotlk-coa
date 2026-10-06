#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllMapScript.h"
#include "Creature.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    constexpr uint32 MAP_BLACKROCK_SPIRE = 229;
    constexpr uint32 NPC_WARCHIEF_REND_BLACKHAND = 10429;

    // Native Blackrock Spire encounter indexes recovered from
    // blackrock_spire.h.
    constexpr uint32 DATA_WARCHIEF_REND_BLACKHAND = 10;
    constexpr uint32 DATA_GYTH = 11;

    constexpr uint32 SEGMENT_REND_NORMAL = 663;
    constexpr uint32 SEGMENT_REND_ENDGAME = 662;

    // Native boss_rend_blackhand.cpp transitions the stadium controller Rend
    // onto the arena floor and then summons Gyth at this exact point. Gyth's
    // 25% health spell later summons the combat Rend within a small radius of
    // Gyth. A direct Manastorm Rend stage skips that prerequisite chain, so
    // this recovered native arena anchor is used for the selected objective.
    Position const REND_ARENA_POSITION =
    {
        211.762f,
        -397.5885f,
        111.1817f,
        4.747295f
    };

    bool IsRendManastormSegment(
        ManastormRun const& run)
    {
        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId !=
                MAP_BLACKROCK_SPIRE ||
            segment.ObjectiveCreatureEntry !=
                NPC_WARCHIEF_REND_BLACKHAND)
        {
            return false;
        }

        return segment.SegmentId ==
                SEGMENT_REND_NORMAL ||
            segment.SegmentId ==
                SEGMENT_REND_ENDGAME;
    }

    Creature* FindRend(
        Map* map,
        Player* player,
        ManastormRun const& run)
    {
        if (!map || !player)
            return nullptr;

        ObjectGuid const objectiveGuid =
            run.GetObjectiveCreatureGuid();

        if (!objectiveGuid.IsEmpty())
        {
            Creature* objective =
                ObjectAccessor::GetCreature(
                    *player,
                    objectiveGuid);

            if (objective &&
                objective->IsInWorld() &&
                objective->IsAlive() &&
                objective->GetEntry() ==
                    NPC_WARCHIEF_REND_BLACKHAND)
            {
                return objective;
            }
        }

        // Blackrock Spire normally owns a persistent Rend event-controller
        // spawn above the stadium. Reuse that real dungeon creature whenever
        // possible so its native BossAI, instance ownership and DB identity
        // remain intact.
        for (auto const& spawn :
            map->GetCreatureBySpawnIdStore())
        {
            Creature* creature =
                spawn.second;

            if (!creature ||
                !creature->IsInWorld() ||
                !creature->IsAlive() ||
                creature->GetEntry() !=
                    NPC_WARCHIEF_REND_BLACKHAND)
            {
                continue;
            }

            return creature;
        }

        // A native Gyth transition may already have produced a temporary Rend
        // in this private copy. Reuse it rather than creating a duplicate.
        std::list<Creature*> rends;
        GetCreatureListWithEntryInGrid(
            rends,
            player,
            NPC_WARCHIEF_REND_BLACKHAND,
            200.0f);

        for (Creature* rend : rends)
        {
            if (rend &&
                rend->IsInWorld() &&
                rend->IsAlive())
            {
                return rend;
            }
        }

        return nullptr;
    }

    bool PrepareRendForManastorm(
        Map* map,
        Player* player,
        ManastormRun& run)
    {
        if (!map ||
            !player ||
            !IsRendManastormSegment(run) ||
            map->GetId() !=
                MAP_BLACKROCK_SPIRE ||
            map->GetInstanceId() !=
                run.GetInstanceId())
        {
            return false;
        }

        InstanceScript* instance =
            map->GetInstanceScript();

        if (!instance)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm Rend bootstrap has no Blackrock Spire instance script: "
                "run={} segment={} instance={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetInstanceId());

            return false;
        }

        EncounterState const gythState =
            instance->GetBossState(DATA_GYTH);

        if (gythState == DONE)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm Rend bootstrap found Gyth already DONE in disposable stage: "
                "run={} segment={} instance={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetInstanceId());

            return false;
        }

        // Native Rend Reset() makes the boss attackable only while the Gyth
        // encounter is IN_PROGRESS. Manastorm selects Rend directly, so move
        // only that prerequisite state forward instead of running the stadium
        // waves and Gyth health transition.
        if (gythState != IN_PROGRESS)
        {
            if (!instance->SetBossState(
                    DATA_GYTH,
                    IN_PROGRESS))
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm could not advance native Gyth state for Rend: "
                    "run={} segment={} instance={} state={}.",
                    run.GetRunId(),
                    run.GetSegment().SegmentId,
                    run.GetInstanceId(),
                    uint32(gythState));

                return false;
            }
        }

        Creature* rend =
            FindRend(
                map,
                player,
                run);

        bool createdFallback = false;

        if (!rend)
        {
            TempSummon* summon =
                map->SummonCreature(
                    NPC_WARCHIEF_REND_BLACKHAND,
                    REND_ARENA_POSITION);

            if (!summon)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm could not materialize Rend objective: "
                    "run={} segment={} map={} instance={} objective={}.",
                    run.GetRunId(),
                    run.GetSegment().SegmentId,
                    run.GetSegment().MapId,
                    run.GetInstanceId(),
                    NPC_WARCHIEF_REND_BLACKHAND);

                return false;
            }

            summon->SetTempSummonType(
                TEMPSUMMON_MANUAL_DESPAWN);

            rend = summon;
            createdFallback = true;
        }
        else
        {
            // The persistent stadium Rend normally waits above the arena in a
            // non-attackable preparation state. A direct Manastorm segment
            // reuses that same creature as the combat objective.
            rend->NearTeleportTo(
                REND_ARENA_POSITION.GetPositionX(),
                REND_ARENA_POSITION.GetPositionY(),
                REND_ARENA_POSITION.GetPositionZ(),
                REND_ARENA_POSITION.GetOrientation());
        }

        rend->RemoveUnitFlag(
            UNIT_FLAG_NON_ATTACKABLE |
            UNIT_FLAG_PREPARATION);
        rend->SetImmuneToAll(false);

        // Registration is duplicate-safe. It also covers the case where the
        // persistent controller loaded before the Manastorm run index existed.
        if (run.GetObjectiveCreatureGuid() !=
            rend->GetGUID())
        {
            ManastormMgr::Instance()
                .OnCreatureAddWorld(
                    rend);
        }

        if (run.GetObjectiveCreatureGuid() !=
            rend->GetGUID())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Prepared Rend failed Manastorm objective registration: "
                "run={} segment={} map={} instance={} objective={} guid={} fallback={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                NPC_WARCHIEF_REND_BLACKHAND,
                rend->GetGUID().GetRawValue(),
                createdFallback ? 1 : 0);

            if (createdFallback)
                rend->DespawnOrUnsummon();

            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Warchief Rend Blackhand for Manastorm: "
            "run={} segment={} map={} instance={} objective={} guid={} "
            "gythState={} fallback={}.",
            run.GetRunId(),
            run.GetSegment().SegmentId,
            run.GetSegment().MapId,
            run.GetInstanceId(),
            NPC_WARCHIEF_REND_BLACKHAND,
            rend->GetGUID().GetRawValue(),
            uint32(instance->GetBossState(DATA_GYTH)),
            createdFallback ? 1 : 0);

        return true;
    }

    class manastorm_blackrock_spire_rend_map :
        public AllMapScript
    {
    public:
        manastorm_blackrock_spire_rend_map()
            : AllMapScript(
                "manastorm_blackrock_spire_rend_map")
        {
        }

        void OnPlayerEnterAll(
            Map* map,
            Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() !=
                    MAP_BLACKROCK_SPIRE)
            {
                return;
            }

            ManastormRun* run =
                ManastormMgr::Instance()
                    .GetRunFor(player);

            if (!run ||
                !IsRendManastormSegment(*run) ||
                run->GetInstanceId() !=
                    map->GetInstanceId())
            {
                return;
            }

            PrepareRendForManastorm(
                map,
                player,
                *run);
        }
    };
}

void AddSC_manastorm_blackrock_spire_rend_compat()
{
    new manastorm_blackrock_spire_rend_map();
}
