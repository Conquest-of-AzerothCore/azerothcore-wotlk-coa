#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllSpellScript.h"
#include "Creature.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
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

    constexpr uint32 MAP_MOLTEN_CORE = 409;
    constexpr uint32 NPC_ANCIENT_CORE_HOUND = 11671;
    constexpr uint32 SPELL_CORE_HOUND_PLAY_DEAD = 19822;
    constexpr uint32 SPELL_CHAOTIC_LINK = 93459;
    constexpr double CHAOTIC_LINK_HEALTH_PER_STACK = 0.25;
    constexpr uint8 ENDGAME_LEVEL = 60;

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
    new manastorm_molten_core_play_dead();
    new manastorm_forced_track_restore();
}
