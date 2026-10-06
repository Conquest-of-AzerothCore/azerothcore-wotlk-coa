#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllMapScript.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"

#include <unordered_map>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    constexpr uint32 MAP_BLACKROCK_SPIRE = 229;
    constexpr uint32 NPC_PYROGUARD_EMBERSEER = 9816;
    constexpr uint32 NPC_BLACKHAND_INCARCERATOR = 10316;
    constexpr uint32 NPC_BURNING_FELGUARD = 10263;
    constexpr uint32 NPC_WARCHIEF_REND_BLACKHAND = 10429;

    // Native Blackrock Spire identifiers recovered from blackrock_spire.h.
    constexpr uint32 DATA_PYROGUARD_EMBERSEER = 9;
    constexpr uint32 DATA_GYTH = 11;

    // Emberseer's native reset applies the cage after its five-second spawn
    // initialization. Waiting for it prevents a very fast Manastorm bubble
    // exit from racing the boss's pending reset event.
    constexpr uint32 SPELL_ENCAGED_EMBERSEER = 15282;
    constexpr uint32 SPELL_FREEZE_ANIM = 16245;
    constexpr uint32 SPELL_EMBERSEER_GROWING = 16048;
    constexpr uint32 SPELL_EMBERSEER_GROWING_TRIGGER = 16049;
    constexpr uint32 SPELL_EMBERSEER_FULL_STRENGTH = 16047;

    constexpr uint32 SEGMENT_BURNING_FELGUARD_NORMAL = 501;
    constexpr uint32 SEGMENT_BURNING_FELGUARD_ENDGAME = 513;
    constexpr uint32 SEGMENT_REND_NORMAL = 663;
    constexpr uint32 SEGMENT_REND_ENDGAME = 662;
    constexpr uint32 SEGMENT_PYROGUARD_NORMAL = 661;
    constexpr uint32 SEGMENT_PYROGUARD_ENDGAME = 660;

    // Segment 501/513 enters at the recovered Burning Felguard area. Unlike
    // the DB-backed BRS rares, entry 10263 is normally produced by Scarshield
    // Warlock portal summons, so a disposable Manastorm stage owns a direct
    // temporary objective spawn here instead of waiting on that random event.
    constexpr float BURNING_FELGUARD_X = -121.781f;
    constexpr float BURNING_FELGUARD_Y = -372.468f;
    constexpr float BURNING_FELGUARD_Z = 57.2964f;
    constexpr float BURNING_FELGUARD_O = 0.742208f;

    // Native stadium/Gyth arena anchor recovered from boss_rend_blackhand.cpp.
    Position const REND_ARENA_POSITION =
    {
        211.762f,
        -397.5885f,
        111.1817f,
        4.747295f
    };

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

    bool IsBurningFelguardManastormSegment(
        ManastormRun const& run)
    {
        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId !=
                MAP_BLACKROCK_SPIRE ||
            segment.ObjectiveCreatureEntry !=
                NPC_BURNING_FELGUARD)
        {
            return false;
        }

        return segment.SegmentId ==
                SEGMENT_BURNING_FELGUARD_NORMAL ||
            segment.SegmentId ==
                SEGMENT_BURNING_FELGUARD_ENDGAME;
    }

    bool IsRendManastormSegment(
        ManastormRun const& run)
    {
        ManastormSegment const& segment =
            run.GetSegment();

        return segment.MapId == MAP_BLACKROCK_SPIRE &&
            segment.ObjectiveCreatureEntry == NPC_WARCHIEF_REND_BLACKHAND &&
            (segment.SegmentId == SEGMENT_REND_NORMAL ||
                segment.SegmentId == SEGMENT_REND_ENDGAME);
    }

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

    Creature* FindBurningFelguard(
        Player* player,
        ManastormRun const& run)
    {
        if (!player)
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
                    NPC_BURNING_FELGUARD)
            {
                return objective;
            }
        }

        // If the native Scarshield Warlock portal happened to create the rare
        // before this hook runs, reuse that nearby live creature rather than
        // manufacturing a duplicate objective.
        std::list<Creature*> felguards;
        GetCreatureListWithEntryInGrid(
            felguards,
            player,
            NPC_BURNING_FELGUARD,
            100.0f);

        for (Creature* felguard :
            felguards)
        {
            if (felguard &&
                felguard->IsInWorld() &&
                felguard->IsAlive())
            {
                return felguard;
            }
        }

        return nullptr;
    }

    bool EnsureBurningFelguard(
        Map* map,
        Player* player,
        ManastormRun& run)
    {
        if (!map ||
            !player ||
            !IsBurningFelguardManastormSegment(
                run) ||
            map->GetId() !=
                MAP_BLACKROCK_SPIRE ||
            map->GetInstanceId() !=
                run.GetInstanceId())
        {
            return false;
        }

        Creature* felguard =
            FindBurningFelguard(
                player,
                run);

        if (felguard)
        {
            if (run.GetObjectiveCreatureGuid() !=
                felguard->GetGUID())
            {
                ManastormMgr::Instance()
                    .OnCreatureAddWorld(
                        felguard);
            }

            if (run.GetObjectiveCreatureGuid() ==
                felguard->GetGUID())
            {
                return true;
            }
        }

        Position const felguardPosition =
        {
            BURNING_FELGUARD_X,
            BURNING_FELGUARD_Y,
            BURNING_FELGUARD_Z,
            BURNING_FELGUARD_O
        };

        TempSummon* summon =
            map->SummonCreature(
                NPC_BURNING_FELGUARD,
                felguardPosition);

        if (!summon)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm could not summon Burning Felguard objective: "
                "run={} segment={} map={} instance={} objective={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                NPC_BURNING_FELGUARD);

            return false;
        }

        // Keep the summoned rare for the lifetime of this disposable stage.
        // Normal/public Blackrock Spire still relies on Scarshield Warlock
        // portal RNG and is never modified by this compatibility path.
        summon->SetTempSummonType(
            TEMPSUMMON_MANUAL_DESPAWN);

        // SummonCreature() normally reaches the global Manastorm creature hook
        // through AddToWorld(). Register explicitly only if that hook has not
        // already claimed this exact runtime GUID as the fixed objective.
        if (run.GetObjectiveCreatureGuid() !=
            summon->GetGUID())
        {
            ManastormMgr::Instance()
                .OnCreatureAddWorld(
                    summon);
        }

        if (run.GetObjectiveCreatureGuid() !=
            summon->GetGUID())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Summoned Burning Felguard failed Manastorm objective registration: "
                "run={} segment={} map={} instance={} objective={} guid={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                NPC_BURNING_FELGUARD,
                summon->GetGUID()
                    .GetRawValue());

            summon->DespawnOrUnsummon();
            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Burning Felguard objective for Manastorm: "
            "run={} segment={} map={} instance={} objective={} guid={}.",
            run.GetRunId(),
            run.GetSegment().SegmentId,
            run.GetSegment().MapId,
            run.GetInstanceId(),
            NPC_BURNING_FELGUARD,
            summon->GetGUID()
                .GetRawValue());

        return true;
    }

    void EnsureRend(
        Map* map,
        ManastormRun& run)
    {
        InstanceScript* instance =
            map->GetInstanceScript();

        if (!instance)
            return;

        if (instance->GetBossState(DATA_GYTH) != IN_PROGRESS)
            instance->SetBossState(DATA_GYTH, IN_PROGRESS);

        Creature* rend = nullptr;
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* creature = spawn.second;
            if (creature &&
                creature->IsInWorld() &&
                creature->IsAlive() &&
                creature->GetEntry() == NPC_WARCHIEF_REND_BLACKHAND)
            {
                rend = creature;
                break;
            }
        }

        if (!rend)
            return;

        rend->NearTeleportTo(REND_ARENA_POSITION);
        rend->RemoveUnitFlag(
            UNIT_FLAG_NON_ATTACKABLE |
            UNIT_FLAG_PREPARATION);
        rend->SetImmuneToAll(false);

        if (run.GetObjectiveCreatureGuid() != rend->GetGUID())
            ManastormMgr::Instance().OnCreatureAddWorld(rend);
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

    uint32 ActivateEmberseerIncarcerators(
        Creature* emberseer)
    {
        if (!emberseer)
            return 0;

        std::list<Creature*> incarcerators;
        GetCreatureListWithEntryInGrid(
            incarcerators,
            emberseer,
            NPC_BLACKHAND_INCARCERATOR,
            35.0f);

        uint32 activated = 0;

        for (Creature* incarcerator :
            incarcerators)
        {
            if (!incarcerator ||
                !incarcerator->IsInWorld() ||
                !incarcerator->IsAlive())
            {
                continue;
            }

            CreatureAI* ai =
                incarcerator->AI();

            if (!ai)
                continue;

            // This is the native Blackhand Incarcerator activation path. It
            // removes immunity, interrupts the Emberseer channel, cancels
            // re-encage work and places the add in combat with the zone.
            ai->SetData(1, 1);
            ++activated;
        }

        return activated;
    }

    void ReleaseEmberseerImmediately(
        Creature* emberseer)
    {
        if (!emberseer)
            return;

        // Manastorm selects Emberseer as the objective directly, so the
        // dungeon's altar/growth ritual is not a prerequisite for this private
        // stage. Preserve the native release state without running the delayed
        // ritual sequence.
        emberseer->RemoveAura(
            SPELL_ENCAGED_EMBERSEER);
        emberseer->RemoveAura(
            SPELL_FREEZE_ANIM);
        emberseer->RemoveAura(
            SPELL_EMBERSEER_GROWING);
        emberseer->RemoveAura(
            SPELL_EMBERSEER_GROWING_TRIGGER);

        emberseer->CastSpell(
            emberseer,
            SPELL_EMBERSEER_FULL_STRENGTH);

        emberseer->RemoveUnitFlag(
            UNIT_FLAG_NOT_SELECTABLE);
        emberseer->SetImmuneToPC(false);
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

    class manastorm_blackrock_spire_objective_map :
        public AllMapScript
    {
    public:
        manastorm_blackrock_spire_objective_map()
            : AllMapScript(
                "manastorm_blackrock_spire_objective_map")
        {
        }

        void OnPlayerEnterAll(
            Map* map,
            Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !map ||
                !player ||
                map->GetId() != MAP_BLACKROCK_SPIRE)
            {
                return;
            }

            ManastormRun* run =
                ManastormMgr::Instance().GetRunFor(player);

            if (!run ||
                run->GetInstanceId() != map->GetInstanceId())
            {
                return;
            }

            if (IsBurningFelguardManastormSegment(*run))
                EnsureBurningFelguard(map, player, *run);
            else if (IsRendManastormSegment(*run))
                EnsureRend(map, *run);
        }
    };

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
                        "Discarded pending Manastorm Emberseer activation after timeout: "
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

                // Keep the native encounter untouched while the party is still
                // protected. Manastorm changes Preparing -> Active only after
                // the safety phase ends or a stage creature is engaged.
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
                        "Manastorm Emberseer activation timed out without objective: "
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
                        "Manastorm Emberseer activation timed out without Blackrock Spire instance script: "
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

                if (state == DONE)
                {
                    itr =
                        sPendingEmberseerStages.erase(
                            itr);
                    continue;
                }

                if (state != NOT_STARTED &&
                    state != IN_PROGRESS)
                {
                    LOG_WARN(
                        LOG_FILTER,
                        "Manastorm Emberseer activation found unexpected native state: "
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

                // Emberseer's Reset() schedules the cage initialization five
                // seconds after spawn. Wait for that event to finish before
                // overriding the private Manastorm stage, otherwise Reset()
                // could immediately make the boss untargetable again.
                if (state == NOT_STARTED &&
                    !emberseer->HasAura(
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
                        "Manastorm Emberseer activation timed out waiting for native cage initialization: "
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

                if (state == NOT_STARTED)
                {
                    instance->SetBossState(
                        DATA_PYROGUARD_EMBERSEER,
                        IN_PROGRESS);
                }

                uint32 const activatedIncarcerators =
                    ActivateEmberseerIncarcerators(
                        emberseer);

                ReleaseEmberseerImmediately(
                    emberseer);

                state =
                    instance->GetBossState(
                        DATA_PYROGUARD_EMBERSEER);

                LOG_INFO(
                    LOG_FILTER,
                    "Activated Blackrock Spire Emberseer immediately for Manastorm: "
                    "run={} segment={} map={} instance={} objective={} guid={} "
                    "incarcerators={} state={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetSegment().MapId,
                    run->GetInstanceId(),
                    NPC_PYROGUARD_EMBERSEER,
                    emberseer->GetGUID()
                        .GetRawValue(),
                    activatedIncarcerators,
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
    new manastorm_blackrock_spire_objective_map();
    new manastorm_blackrock_spire_emberseer_map();
    new manastorm_blackrock_spire_emberseer_world();
}
