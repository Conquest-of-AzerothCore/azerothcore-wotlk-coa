#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllMapScript.h"
#include "AllSpellScript.h"
#include "Creature.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SmartAI.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "UnitScript.h"

#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    constexpr uint32 MAP_EASTERN_KINGDOMS = 0;
    constexpr uint32 NPC_GROL_THE_DESTROYER = 7665;
    constexpr uint32 SEGMENT_GROL_NORMAL = 409;
    constexpr uint32 SEGMENT_GROL_ENDGAME = 478;
    constexpr uint32 NPC_ARCHMAGE_ALLISTARJ = 7666;
    constexpr uint32 SEGMENT_ALLISTARJ_NORMAL = 552;
    constexpr uint32 SEGMENT_ALLISTARJ_ENDGAME = 553;
    constexpr uint32 NPC_LADY_SEVINE = 7667;
    constexpr uint32 SEGMENT_SEVINE_NORMAL = 554;
    constexpr uint32 SEGMENT_SEVINE_ENDGAME = 555;

    constexpr uint32 MAP_MOLTEN_CORE = 409;
    constexpr uint32 NPC_ANCIENT_CORE_HOUND = 11671;
    constexpr uint32 SPELL_CORE_HOUND_PLAY_DEAD = 19822;
    constexpr uint32 SPELL_CHAOTIC_LINK = 93459;
    constexpr double CHAOTIC_LINK_HEALTH_PER_STACK = 0.25;
    constexpr uint8 ENDGAME_LEVEL = 60;

    constexpr uint32 MAP_BLACKROCK_SPIRE = 229;
    constexpr uint32 NPC_SPIRESTONE_BATTLE_LORD = 9218;
    constexpr uint32 NPC_SPIRESTONE_BUTCHER = 9219;
    constexpr uint32 NPC_CRYSTAL_FANG = 10376;

    struct BlackrockSpireRareObjective
    {
        uint32 SegmentId;
        uint32 Entry;
        ObjectGuid::LowType SpawnId;
    };

    constexpr BlackrockSpireRareObjective
        BLACKROCK_SPIRE_RARE_OBJECTIVES[] =
    {
        {497, NPC_SPIRESTONE_BUTCHER, 43523},
        {511, NPC_SPIRESTONE_BUTCHER, 43523},
        {503, NPC_CRYSTAL_FANG, 44422},
        {515, NPC_CRYSTAL_FANG, 44422},
        {508, NPC_SPIRESTONE_BATTLE_LORD, 43519},
        {520, NPC_SPIRESTONE_BATTLE_LORD, 43519},
    };

    ManastormRun* GetRunForStageCreature(
        Creature* creature)
    {
        if (!creature)
            return nullptr;

        Map* map =
            creature->GetMap();

        if (!map ||
            !map->GetInstanceId())
        {
            return nullptr;
        }

        ManastormMgr& mgr =
            ManastormMgr::Instance();

        for (auto const& playerRef :
            map->GetPlayers())
        {
            Player* player =
                playerRef.GetSource();

            if (!player)
                continue;

            ManastormRun* run =
                mgr.GetRunFor(player);

            if (!run ||
                run->GetSegment().MapId !=
                    map->GetId() ||
                run->GetInstanceId() !=
                    map->GetInstanceId())
            {
                continue;
            }

            return run;
        }

        return nullptr;
    }

    BlackrockSpireRareObjective const*
    GetBlackrockSpireRareObjective(
        ManastormRun const& run)
    {
        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId !=
            MAP_BLACKROCK_SPIRE)
        {
            return nullptr;
        }

        for (BlackrockSpireRareObjective const& rare :
            BLACKROCK_SPIRE_RARE_OBJECTIVES)
        {
            if (rare.SegmentId ==
                    segment.SegmentId &&
                rare.Entry ==
                    segment.ObjectiveCreatureEntry)
            {
                return &rare;
            }
        }

        return nullptr;
    }

    void StabilizeBlackrockSpireRareObjective(
        Creature* creature,
        BlackrockSpireRareObjective const& rare)
    {
        if (!creature ||
            creature->GetEntry() != rare.Entry ||
            creature->GetSpawnId() != rare.SpawnId)
        {
            return;
        }

        //
        // These native Blackrock Spire rares use the same rarity pattern
        // recovered for Brightwing:
        //
        //   AI_INIT -> 85% FORCE_DESPAWN after 500 ms
        //
        // AI initialization has already run by the time this helper is called,
        // so the delayed rarity despawn is sitting in the creature's
        // EventProcessor. The selected Manastorm segment explicitly requires
        // this rare as its objective; cancel only that runtime creature's
        // queued spawn-time events while leaving its SmartAI attached.
        //
        // This is scoped to the disposable Manastorm instance. Normal/public
        // Blackrock Spire keeps its native rare-spawn behavior unchanged.
        //
        creature->m_Events.KillAllEvents(
            true);
    }

    bool EnsureBlackrockSpireRareObjective(
        Map* map,
        Player* player,
        ManastormRun& run)
    {
        if (!map ||
            !player ||
            map->GetId() != MAP_BLACKROCK_SPIRE ||
            map->GetInstanceId() != run.GetInstanceId())
        {
            return true;
        }

        BlackrockSpireRareObjective const* rare =
            GetBlackrockSpireRareObjective(
                run);

        if (!rare)
            return true;

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
                objective->GetEntry() == rare->Entry &&
                objective->GetSpawnId() == rare->SpawnId)
            {
                // The main Manastorm creature hook is registered before this
                // runtime-compat map hook. On the first member entering the
                // stage, the rare may therefore already be registered as the
                // objective but still have its 500 ms rarity despawn queued.
                if (run.GetState() !=
                    ManastormRunState::Active)
                {
                    StabilizeBlackrockSpireRareObjective(
                        objective,
                        *rare);
                }

                return true;
            }
        }

        CreatureData const* spawnData =
            sObjectMgr->GetCreatureData(
                rare->SpawnId);

        if (!spawnData ||
            spawnData->mapid !=
                MAP_BLACKROCK_SPIRE ||
            spawnData->id !=
                rare->Entry)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm Blackrock Spire rare bootstrap rejected DB spawn: "
                "run={} segment={} map={} instance={} spawn={} expectedEntry={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                rare->SpawnId,
                rare->Entry);

            return false;
        }

        // Prefer the real native DB creature if the fresh private instance
        // still has it alive. Stabilize that exact runtime object and register
        // it through the normal Manastorm objective path.
        auto const existingBounds =
            map->GetCreatureBySpawnIdStore()
                .equal_range(
                    rare->SpawnId);

        for (auto itr =
                existingBounds.first;
            itr !=
                existingBounds.second;
            ++itr)
        {
            Creature* creature =
                itr->second;

            if (!creature ||
                !creature->IsInWorld() ||
                !creature->IsAlive() ||
                creature->GetEntry() != rare->Entry)
            {
                continue;
            }

            StabilizeBlackrockSpireRareObjective(
                creature,
                *rare);

            ManastormMgr::Instance()
                .OnCreatureAddWorld(
                    creature);

            if (run.GetObjectiveCreatureGuid() !=
                creature->GetGUID())
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Living Manastorm Blackrock Spire rare failed objective registration: "
                    "run={} segment={} map={} instance={} spawn={} entry={} guid={}.",
                    run.GetRunId(),
                    run.GetSegment().SegmentId,
                    run.GetSegment().MapId,
                    run.GetInstanceId(),
                    rare->SpawnId,
                    rare->Entry,
                    creature->GetGUID().GetRawValue());

                return false;
            }

            LOG_INFO(
                LOG_FILTER,
                "Reused living Manastorm Blackrock Spire rare DB spawn: "
                "run={} segment={} map={} instance={} spawn={} entry={} guid={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                rare->SpawnId,
                rare->Entry,
                creature->GetGUID().GetRawValue());

            return true;
        }

        // These are long-respawn native DB rares. A scripted-private
        // Manastorm stage is disposable, so clear only this map instance's
        // in-memory respawn timestamp and instantiate the original DB spawn.
        // No world DB row or normal Blackrock Spire rarity is changed.
        map->RemoveCreatureRespawnTime(
            rare->SpawnId);

        Creature* creature =
            new Creature();

        if (!creature->LoadCreatureFromDB(
                rare->SpawnId,
                map,
                true,
                true))
        {
            delete creature;

            LOG_ERROR(
                LOG_FILTER,
                "Manastorm could not load Blackrock Spire rare DB spawn: "
                "run={} segment={} map={} instance={} spawn={} entry={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                rare->SpawnId,
                rare->Entry);

            return false;
        }

        if (!creature->IsInWorld() ||
            !creature->IsAlive() ||
            creature->GetEntry() != rare->Entry)
        {
            creature->AddObjectToRemoveList();

            LOG_ERROR(
                LOG_FILTER,
                "Manastorm Blackrock Spire rare DB spawn loaded in an invalid state: "
                "run={} segment={} map={} instance={} spawn={} entry={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                rare->SpawnId,
                rare->Entry);

            return false;
        }

        // LoadCreatureFromDB() has already completed AddToWorld()/SmartAI
        // initialization. Remove the queued native rarity despawn immediately,
        // then explicitly register this exact native spawn as the objective.
        StabilizeBlackrockSpireRareObjective(
            creature,
            *rare);

        ManastormMgr::Instance()
            .OnCreatureAddWorld(
                creature);

        if (run.GetObjectiveCreatureGuid() !=
            creature->GetGUID())
        {
            creature->AddObjectToRemoveList();

            LOG_ERROR(
                LOG_FILTER,
                "Loaded Manastorm Blackrock Spire rare failed objective registration: "
                "run={} segment={} map={} instance={} spawn={} entry={} guid={}.",
                run.GetRunId(),
                run.GetSegment().SegmentId,
                run.GetSegment().MapId,
                run.GetInstanceId(),
                rare->SpawnId,
                rare->Entry,
                creature->GetGUID().GetRawValue());

            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Manastorm Blackrock Spire rare from native DB spawn: "
            "run={} segment={} map={} instance={} spawn={} entry={} guid={} registered=1.",
            run.GetRunId(),
            run.GetSegment().SegmentId,
            run.GetSegment().MapId,
            run.GetInstanceId(),
            rare->SpawnId,
            rare->Entry,
            creature->GetGUID().GetRawValue());

        return true;
    }

    void BroadcastRunState(
        Creature* source,
        ManastormRun& run)
    {
        if (!source ||
            !source->GetMap())
        {
            return;
        }

        ManastormMgr& mgr =
            ManastormMgr::Instance();

        for (auto const& playerRef :
            source->GetMap()->GetPlayers())
        {
            Player* player =
                playerRef.GetSource();

            if (!player ||
                mgr.GetRunFor(player) !=
                    &run)
            {
                continue;
            }

            mgr.SyncClientState(
                player);
        }
    }

    void SynchronizeChaoticLinkBoss(
        Creature* source,
        ManastormRun& run)
    {
        if (!source)
            return;

        ObjectGuid const objectiveGuid =
            run.GetObjectiveCreatureGuid();

        if (objectiveGuid.IsEmpty())
            return;

        Creature* boss =
            ObjectAccessor::GetCreature(
                *source,
                objectiveGuid);

        if (!boss ||
            !boss->IsAlive())
        {
            return;
        }

        uint8 const stacks =
            run.GetChaoticLinkStacks();

        if (!stacks)
        {
            boss->RemoveAurasDueToSpell(
                SPELL_CHAOTIC_LINK);
        }
        else
        {
            Aura* aura =
                boss->GetAura(
                    SPELL_CHAOTIC_LINK);

            if (!aura)
            {
                boss->CastSpell(
                    boss,
                    SPELL_CHAOTIC_LINK,
                    true);

                aura =
                    boss->GetAura(
                        SPELL_CHAOTIC_LINK);
            }

            if (aura &&
                aura->GetStackAmount() != stacks)
            {
                aura->SetStackAmount(
                    stacks);
            }
        }

        uint32 const baseMaxHealth =
            run.GetChaoticLinkBaseMaxHealth();

        if (!baseMaxHealth)
            return;

        uint32 const oldMaxHealth =
            boss->GetMaxHealth();

        double const healthPct =
            oldMaxHealth
            ? double(boss->GetHealth()) /
                double(oldMaxHealth)
            : 1.0;

        double const healthMultiplier =
            1.0 +
            (double(stacks) *
                CHAOTIC_LINK_HEALTH_PER_STACK);

        double const scaledHealth =
            std::round(
                double(baseMaxHealth) *
                healthMultiplier);

        uint32 const finalMaxHealth =
            uint32(
                std::clamp(
                    scaledHealth,
                    1.0,
                    double(
                        std::numeric_limits<uint32>::max())));

        boss->SetCreateHealth(
            finalMaxHealth);

        boss->SetStatFlatModifier(
            UNIT_MOD_HEALTH,
            BASE_VALUE,
            float(finalMaxHealth));

        boss->SetMaxHealth(
            finalMaxHealth);

        uint32 const finalHealth =
            std::clamp<uint32>(
                uint32(std::llround(
                    double(finalMaxHealth) *
                    healthPct)),
                1u,
                finalMaxHealth);

        boss->SetHealth(
            finalHealth);
    }

    class manastorm_blackrock_spire_rare_objective :
        public AllMapScript
    {
    public:
        manastorm_blackrock_spire_rare_objective()
            : AllMapScript(
                "manastorm_blackrock_spire_rare_objective")
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
                run->GetSegment().MapId !=
                    MAP_BLACKROCK_SPIRE ||
                run->GetInstanceId() !=
                    map->GetInstanceId() ||
                !GetBlackrockSpireRareObjective(
                    *run))
            {
                return;
            }

            if (!EnsureBlackrockSpireRareObjective(
                    map,
                    player,
                    *run))
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm Blackrock Spire rare objective bootstrap failed: "
                    "run={} segment={} map={} instance={} objective={}.",
                    run->GetRunId(),
                    run->GetSegment().SegmentId,
                    run->GetSegment().MapId,
                    run->GetInstanceId(),
                    run->GetSegment().ObjectiveCreatureEntry);
            }
        }
    };

    class manastorm_molten_core_play_dead :
        public AllSpellScript
    {
    public:
        manastorm_molten_core_play_dead()
            : AllSpellScript(
                "manastorm_molten_core_play_dead",
                {ALLSPELLHOOK_ON_HIT_RESULT})
        {
        }

        void OnSpellHitResult(
            Spell* spell,
            Unit* target,
            uint8 missInfo,
            uint32 /*damage*/,
            uint32 /*healing*/,
            bool /*critical*/) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !spell ||
                !target ||
                missInfo != SPELL_MISS_NONE ||
                spell->GetSpellInfo()->Id !=
                    SPELL_CORE_HOUND_PLAY_DEAD)
            {
                return;
            }

            Creature* hound =
                target->ToCreature();

            if (!hound ||
                hound->GetEntry() !=
                    NPC_ANCIENT_CORE_HOUND ||
                hound->GetMapId() !=
                    MAP_MOLTEN_CORE ||
                spell->GetCaster() != hound)
            {
                return;
            }

            ManastormRun* run =
                GetRunForStageCreature(
                    hound);

            if (!run ||
                run->GetState() !=
                    ManastormRunState::Active ||
                !run->IsStageCreature(
                    hound->GetGUID()) ||
                !run->GetChaoticLinkStacks())
            {
                return;
            }

            ObjectGuid::LowType const spawnId =
                hound->GetSpawnId();

            if (!spawnId ||
                !run->IsChaoticLinkSpawn(
                    spawnId) ||
                !run->ConsumeChaoticLinkSpawn(
                    spawnId))
            {
                return;
            }

            uint8 const previousStacks =
                run->GetChaoticLinkStacks();

            uint8 const newStacks =
                previousStacks - 1;

            run->SetChaoticLinkStacks(
                newStacks);

            SynchronizeChaoticLinkBoss(
                hound,
                *run);

            BroadcastRunState(
                hound,
                *run);

            LOG_INFO(
                LOG_FILTER,
                "Manastorm run {} treated Molten Core Core Hound Play Dead "
                "as one Chaotic Link defeat: segment={} spawnId={} "
                "stacks={} -> {} unusedRouteSpawns={}.",
                run->GetRunId(),
                run->GetSegment().SegmentId,
                spawnId,
                uint32(previousStacks),
                uint32(newStacks),
                run->GetUnusedChaoticLinkSpawnCount());
        }
    };

    class manastorm_blasted_lands_invincibility_bypass :
        public UnitScript
    {
    public:
        manastorm_blasted_lands_invincibility_bypass()
            : UnitScript(
                "manastorm_blasted_lands_invincibility_bypass",
                true,
                {UNITHOOK_ON_UNIT_ENTER_COMBAT})
        {
        }

        void OnUnitEnterCombat(
            Unit* unit,
            Unit* /*victim*/) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !unit)
            {
                return;
            }

            Creature* creature =
                unit->ToCreature();

            if (!creature ||
                creature->GetMapId() !=
                    MAP_EASTERN_KINGDOMS ||
                (creature->GetEntry() !=
                    NPC_GROL_THE_DESTROYER &&
                 creature->GetEntry() !=
                    NPC_ARCHMAGE_ALLISTARJ &&
                 creature->GetEntry() !=
                    NPC_LADY_SEVINE))
            {
                return;
            }

            ManastormRun* run =
                GetRunForStageCreature(
                    creature);

            if (!run)
                return;

            ManastormSegment const& segment =
                run->GetSegment();

            bool const grol =
                segment.ObjectiveCreatureEntry ==
                    NPC_GROL_THE_DESTROYER &&
                (segment.SegmentId ==
                    SEGMENT_GROL_NORMAL ||
                 segment.SegmentId ==
                    SEGMENT_GROL_ENDGAME);

            bool const allistarj =
                segment.ObjectiveCreatureEntry ==
                    NPC_ARCHMAGE_ALLISTARJ &&
                (segment.SegmentId ==
                    SEGMENT_ALLISTARJ_NORMAL ||
                 segment.SegmentId ==
                    SEGMENT_ALLISTARJ_ENDGAME);

            bool const sevine =
                segment.ObjectiveCreatureEntry ==
                    NPC_LADY_SEVINE &&
                (segment.SegmentId ==
                    SEGMENT_SEVINE_NORMAL ||
                 segment.SegmentId ==
                    SEGMENT_SEVINE_ENDGAME);

            if (!grol && !allistarj && !sevine)
                return;

            SmartAI* smartAI =
                CAST_AI(
                    SmartAI,
                    creature->AI());

            if (!smartAI)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm Blasted Lands objective is not using SmartAI: "
                    "run={} segment={} map={} instance={} guid={}.",
                    run->GetRunId(),
                    segment.SegmentId,
                    segment.MapId,
                    run->GetInstanceId(),
                    creature->GetGUID().GetRawValue());

                return;
            }

            // Native Grol, Allistarj, and Lady Sevine are quest-gated by a
            // SmartAI invincibility floor normally removed by Fel Curse
            // (12938). Their recovered Manastorm stages select them directly, so
            // bypass only that HP floor in the disposable Manastorm copy.
            // Enter-combat is used deliberately: SmartAI Reset may restore
            // the floor after an evade, and every new pull must remain
            // killable without changing public Blasted Lands behavior.
            smartAI->SetInvincibilityHpLevel(
                0);

            LOG_INFO(
                LOG_FILTER,
                "Removed native Fel Curse invincibility floor from "
                "Manastorm Blasted Lands objective: run={} segment={} "
                "entry={} instance={} guid={}.",
                run->GetRunId(),
                segment.SegmentId,
                creature->GetEntry(),
                run->GetInstanceId(),
                creature->GetGUID().GetRawValue());
        }
    };

    class manastorm_forced_track_restore :
        public UnitScript
    {
    public:
        manastorm_forced_track_restore()
            : UnitScript(
                "manastorm_forced_track_restore",
                true,
                {UNITHOOK_ON_UNIT_DEATH})
        {
        }

        void OnUnitDeath(
            Unit* unit,
            Unit* /*killer*/) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !unit)
            {
                return;
            }

            Creature* creature =
                unit->ToCreature();

            if (!creature)
                return;

            ManastormRun* run =
                GetRunForStageCreature(
                    creature);

            // This script is registered after the main Manastorm UnitScript.
            // Therefore an objective kill has already persisted the forced
            // stage and moved the run to StageComplete before we restore the
            // character/group's natural track for the next stage.
            if (!run ||
                run->GetState() !=
                    ManastormRunState::StageComplete ||
                run->GetObjectiveCreatureGuid() !=
                    creature->GetGUID())
            {
                return;
            }

            bool const naturalEndgame =
                run->GetCreatureLevel() >=
                    ENDGAME_LEVEL;

            bool const stageEndgame =
                run->GetSegment().Difficulty == 2;

            if (naturalEndgame == stageEndgame)
                return;

            run->SetEndgame(
                naturalEndgame);

            BroadcastRunState(
                creature,
                *run);

            LOG_INFO(
                LOG_FILTER,
                "Manastorm run {} restored natural {} track after forced "
                "segment {} (native difficulty={}) completed at player-scaled "
                "level {}.",
                run->GetRunId(),
                naturalEndgame
                    ? "Endgame"
                    : "Normal",
                run->GetSegment().SegmentId,
                uint32(
                    run->GetSegment().Difficulty),
                uint32(
                    run->GetCreatureLevel()));
        }
    };
}

void AddSC_manastorm_runtime_compat()
{
    new manastorm_blackrock_spire_rare_objective();
    new manastorm_molten_core_play_dead();
    new manastorm_blasted_lands_invincibility_bypass();
    new manastorm_forced_track_restore();
}
