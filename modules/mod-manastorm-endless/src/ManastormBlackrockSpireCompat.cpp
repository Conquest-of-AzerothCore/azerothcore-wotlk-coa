#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllMapScript.h"
#include "Creature.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <unordered_map>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    constexpr uint32 MAP_BLACKROCK_SPIRE = 229;
    constexpr uint32 NPC_PYROGUARD_EMBERSEER = 9816;

    // Native Blackrock Spire identifiers recovered from blackrock_spire.h.
    constexpr uint32 DATA_PYROGUARD_EMBERSEER = 9;
    constexpr uint32 EVENT_PYROGUARD_EMBERSEER = 4884;

    // Emberseer's native reset applies this after the encounter has finished
    // its five-second spawn initialization. Waiting for it prevents a very
    // fast Manastorm bubble exit from racing the boss's pending reset event.
    constexpr uint32 SPELL_ENCAGED_EMBERSEER = 15282;

    constexpr uint32 SEGMENT_PYROGUARD_NORMAL = 661;
    constexpr uint32 SEGMENT_PYROGUARD_ENDGAME = 660;

    constexpr uint32 CHECK_INTERVAL_MS = 250;
    constexpr uint32 PENDING_TIMEOUT_MS = 180000;

    struct PendingEmberseerStage
    {
        ObjectGuid::LowType MemberGuid = 0;
        uint32 InstanceId = 0;
        uint32 WaitedMs = 0;
    };

    std::unordered_map<uint64, PendingEmberseerStage>
        sPendingEmberseerStages;

    uint32 sCheckTimerMs =
        CHECK_INTERVAL_MS;

    bool IsEmberseerManastormSegment(
        ManastormRun const& run)
    {
        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId !=
                MAP_BLACKROCK_SPIRE ||
            segment.ObjectiveCreatureEntry !=
                NPC_PYROGUARD_EMBERSEER)
        {
            return false;
        }

        return segment.SegmentId ==
                SEGMENT_PYROGUARD_NORMAL ||
            segment.SegmentId ==
                SEGMENT_PYROGUARD_ENDGAME;
    }

    Creature* FindEmberseer(
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
                    NPC_PYROGUARD_EMBERSEER)
            {
                return objective;
            }
        }

        // The persistent objective may have loaded before Manastorm's stage
        // index existed. Fall back to this private map's already-loaded DB
        // creatures; this is local to one pending Emberseer stage, not a
        // world/global creature scan.
        for (auto const& spawn :
            map->GetCreatureBySpawnIdStore())
        {
            Creature* creature =
                spawn.second;

            if (!creature ||
                !creature->IsInWorld() ||
                !creature->IsAlive() ||
                creature->GetEntry() !=
                    NPC_PYROGUARD_EMBERSEER)
            {
                continue;
            }

            return creature;
        }

        return nullptr;
    }

    void QueueEmberseerStage(
        Player* player,
        ManastormRun const& run)
    {
        if (!player)
            return;

        PendingEmberseerStage& pending =
            sPendingEmberseerStages[
                run.GetRunId()];

        pending.MemberGuid =
            player->GetGUID().GetCounter();

        pending.InstanceId =
            run.GetInstanceId();
    }

    class manastorm_blackrock_spire_emberseer_map :
        public AllMapScript
    {
    public:
        manastorm_blackrock_spire_emberseer_map()
            : AllMapScript(
                "manastorm_blackrock_spire_emberseer_map")
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
                    .GetRunFor(
                        player);

            if (!run ||
                !IsEmberseerManastormSegment(
                    *run) ||
                run->GetInstanceId() !=
                    map->GetInstanceId())
            {
                return;
            }

            QueueEmberseerStage(
                player,
                *run);
        }
    };

    class manastorm_blackrock_spire_emberseer_world :
        public WorldScript
    {
    public:
        manastorm_blackrock_spire_emberseer_world()
            : WorldScript(
                "manastorm_blackrock_spire_emberseer_world")
        {
        }

        void OnUpdate(
            uint32 diff) override
        {
            if (!ManastormModuleConfig::Enabled())
            {
                sPendingEmberseerStages.clear();
                sCheckTimerMs =
                    CHECK_INTERVAL_MS;
                return;
            }

            if (sPendingEmberseerStages.empty())
                return;

            if (sCheckTimerMs > diff)
            {
                sCheckTimerMs -= diff;
                return;
            }

            sCheckTimerMs =
                CHECK_INTERVAL_MS;

            for (auto itr =
                    sPendingEmberseerStages.begin();
                itr !=
                    sPendingEmberseerStages.end();)
            {
                uint64 const runId =
                    itr->first;

                PendingEmberseerStage& pending =
                    itr->second;

                pending.WaitedMs =
                    pending.WaitedMs >=
                        PENDING_TIMEOUT_MS -
                            CHECK_INTERVAL_MS
                    ? PENDING_TIMEOUT_MS
                    : pending.WaitedMs +
                        CHECK_INTERVAL_MS;

                Player* player =
                    ObjectAccessor::FindConnectedPlayer(
                        ObjectGuid::Create<
                            HighGuid::Player>(
                                pending.MemberGuid));

                if (!player ||
                    !player->IsInWorld() ||
                    player->IsBeingTeleported())
                {
                    if (pending.WaitedMs <
                        PENDING_TIMEOUT_MS)
                    {
                        ++itr;
                        continue;
                    }

                    LOG_WARN(
                        LOG_FILTER,
                        "Discarded pending Manastorm Emberseer bootstrap after timeout: "
                        "run={} instance={} member={}.",
                        runId,
                        pending.InstanceId,
                        pending.MemberGuid);

                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                ManastormRun* run =
                    ManastormMgr::Instance()
                        .GetRunFor(
                            player);

                if (!run ||
                    run->GetRunId() != runId ||
                    !IsEmberseerManastormSegment(
                        *run) ||
                    run->GetInstanceId() !=
                        pending.InstanceId)
                {
                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                // Do not begin the native room event while the party is still
                // protected by the Manastorm Safety Bubble. The main manager
                // changes Preparing -> Active only after the player leaves
                // protection or explicitly engages a stage creature.
                if (run->GetState() ==
                    ManastormRunState::Preparing)
                {
                    ++itr;
                    continue;
                }

                if (run->GetState() !=
                    ManastormRunState::Active)
                {
                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                Map* map =
                    player->FindMap();

                if (!map ||
                    map->GetId() !=
                        MAP_BLACKROCK_SPIRE ||
                    map->GetInstanceId() !=
                        pending.InstanceId)
                {
                    ++itr;
                    continue;
                }

                Creature* emberseer =
                    FindEmberseer(
                        map,
                        player,
                        *run);

                if (!emberseer)
                {
                    if (pending.WaitedMs <
                        PENDING_TIMEOUT_MS)
                    {
                        ++itr;
                        continue;
                    }

                    LOG_ERROR(
                        LOG_FILTER,
                        "Manastorm Emberseer bootstrap timed out without objective: "
                        "run={} segment={} map={} instance={} objective={}.",
                        run->GetRunId(),
                        run->GetSegment().SegmentId,
                        run->GetSegment().MapId,
                        run->GetInstanceId(),
                        run->GetSegment()
                            .ObjectiveCreatureEntry);

                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                InstanceScript* instance =
                    emberseer->GetInstanceScript();

                if (!instance)
                {
                    if (pending.WaitedMs <
                        PENDING_TIMEOUT_MS)
                    {
                        ++itr;
                        continue;
                    }

                    LOG_ERROR(
                        LOG_FILTER,
                        "Manastorm Emberseer bootstrap timed out without Blackrock Spire instance script: "
                        "run={} segment={} instance={} guid={}.",
                        run->GetRunId(),
                        run->GetSegment().SegmentId,
                        run->GetInstanceId(),
                        emberseer->GetGUID()
                            .GetRawValue());

                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                EncounterState state =
                    instance->GetBossState(
                        DATA_PYROGUARD_EMBERSEER);

                // A reconnect or another native trigger may already have
                // started/completed the event. In that case there is nothing
                // Manastorm-specific left to do.
                if (state == IN_PROGRESS ||
                    state == DONE)
                {
                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                if (state != NOT_STARTED)
                {
                    LOG_WARN(
                        LOG_FILTER,
                        "Manastorm Emberseer bootstrap found unexpected native state: "
                        "run={} segment={} instance={} state={}.",
                        run->GetRunId(),
                        run->GetSegment().SegmentId,
                        run->GetInstanceId(),
                        uint32(state));

                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                // Emberseer's Reset() schedules its native initial cage setup
                // five seconds after spawn. If a player leaves the safety
                // bubble extremely quickly, wait for that setup instead of
                // starting event 4884 and then having the pending reset undo it.
                if (!emberseer->HasAura(
                        SPELL_ENCAGED_EMBERSEER))
                {
                    if (pending.WaitedMs <
                        PENDING_TIMEOUT_MS)
                    {
                        ++itr;
                        continue;
                    }

                    LOG_ERROR(
                        LOG_FILTER,
                        "Manastorm Emberseer bootstrap timed out waiting for native cage initialization: "
                        "run={} segment={} instance={} guid={}.",
                        run->GetRunId(),
                        run->GetSegment().SegmentId,
                        run->GetInstanceId(),
                        emberseer->GetGUID()
                            .GetRawValue());

                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                // Use the exact native Blackrock Spire event normally fired by
                // the Altar of Emberseer. The instance script forwards event
                // 4884 to Emberseer AI SetData(1, 1), which:
                //   - sets the boss encounter IN_PROGRESS;
                //   - activates nearby Blackhand Incarcerators (10316);
                //   - removes their immunity and starts combat;
                //   - runs Emberseer's native growth/release sequence;
                //   - finally makes Emberseer selectable/attackable.
                // No flags or immunities are manually overridden here.
                instance->ProcessEvent(
                    emberseer,
                    EVENT_PYROGUARD_EMBERSEER);

                state =
                    instance->GetBossState(
                        DATA_PYROGUARD_EMBERSEER);

                if (state != IN_PROGRESS &&
                    state != DONE)
                {
                    if (pending.WaitedMs <
                        PENDING_TIMEOUT_MS)
                    {
                        ++itr;
                        continue;
                    }

                    LOG_ERROR(
                        LOG_FILTER,
                        "Native Manastorm Emberseer event did not enter progress: "
                        "run={} segment={} instance={} state={} guid={}.",
                        run->GetRunId(),
                        run->GetSegment().SegmentId,
                        run->GetInstanceId(),
                        uint32(state),
                        emberseer->GetGUID()
                            .GetRawValue());

                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                LOG_INFO(
                    LOG_FILTER,
                    "Started native Blackrock Spire Emberseer event for Manastorm: "
                    "run={} segment={} map={} instance={} event={} objective={} guid={} state={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetSegment().MapId,
                    run->GetInstanceId(),
                    EVENT_PYROGUARD_EMBERSEER,
                    NPC_PYROGUARD_EMBERSEER,
                    emberseer->GetGUID()
                        .GetRawValue(),
                    uint32(state));

                itr =
                    sPendingEmberseerStages.erase(
                        itr);
            }
        }
    };
}

void AddSC_manastorm_blackrock_spire_compat()
{
    new manastorm_blackrock_spire_emberseer_map();
    new manastorm_blackrock_spire_emberseer_world();
}
