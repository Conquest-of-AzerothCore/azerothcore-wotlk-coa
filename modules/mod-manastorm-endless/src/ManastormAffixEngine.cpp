#include "ManastormAffixEngine.h"
#include "ManastormModuleConfig.h"

#include "Creature.h"
#include "Log.h"
#include "MotionMaster.h"
#include "ManastormDataStore.h"
#include "ManastormRun.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <string>
#include <utility>
#include <vector>

namespace
{
constexpr char const* LOG_FILTER = "module.manastorm.endless";

// Recovered helper-controller edges absent from the client DBC graph itself.
// The DBC supplies the summon and payload spells; these bounded server edges
// attach each summoned helper to the spell it is supposed to own.
constexpr uint32 NPC_CREEPING_FROST = 80916;
constexpr uint32 NPC_COLD_SNAP = 80924;
constexpr uint32 NPC_COLD_SNAP_EFFECT = 80925;
constexpr uint32 NPC_FUNGAL_MUSHROOM = 80914;
constexpr uint32 NPC_BONESTORM = 80913;
constexpr uint32 NPC_OVERWHELMING_ENERGY = 80917;

constexpr uint32 SPELL_CREEPING_FROST_EFFECT = 93342;
constexpr uint32 SPELL_COLD_SNAP_AURA = 93446;
constexpr uint32 SPELL_COLD_SNAP_EFFECT_AURA = 93448;
constexpr uint32 SPELL_FUNGAL_AURA = 93379;
constexpr uint32 SPELL_BONESTORM_AURA = 93369;
constexpr float BONESTORM_RUN_SPEED_RATE = 0.85f;
constexpr uint32 SPELL_OVERWHELMING_COSMETIC_AURA = 93414;

bool IsPlayerControlledCreature(Creature const* creature)
{
    return creature &&
        (creature->IsControlledByPlayer() ||
         creature->IsCreatedByPlayer() ||
         creature->IsCharmedOwnedByPlayerOrPlayer());
}

uint64 Mix64(uint64 value)
{
    value += 0x9e3779b97f4a7c15ULL;
    value = (value ^ (value >> 30)) *
        0xbf58476d1ce4e5b9ULL;
    value = (value ^ (value >> 27)) *
        0x94d049bb133111ebULL;
    return value ^ (value >> 31);
}

uint64 SelectionKey(
    ManastormRun const& run,
    uint32 affixId,
    uint64 salt,
    uint32 weight)
{
    uint64 const mixed =
        Mix64(
            run.GetSeed() ^
            (uint64(run.GetDepth()) << 32) ^
            uint64(affixId) ^
            salt);

    return mixed /
        std::max<uint32>(
            1,
            weight);
}

bool PassChance(
    ManastormRun const& run,
    Creature const* creature,
    uint32 affixId,
    float chancePct,
    uint64 salt)
{
    if (chancePct <= 0.0f)
        return false;

    if (chancePct >= 100.0f)
        return true;

    uint64 identity =
        creature
        ? creature->GetGUID().GetRawValue()
        : 0;

    if (creature &&
        creature->GetSpawnId())
    {
        identity =
            uint64(creature->GetSpawnId());
    }

    uint64 const mixed =
        Mix64(
            run.GetSeed() ^
            (uint64(run.GetDepth()) << 32) ^
            identity ^
            (uint64(affixId) << 1) ^
            salt);

    uint32 const roll =
        uint32(mixed % 10000ULL);

    uint32 const threshold =
        uint32(std::round(
            chancePct * 100.0f));

    return roll < threshold;
}
}

ManastormAffixEngine& ManastormAffixEngine::Instance()
{
    static ManastormAffixEngine instance;
    return instance;
}

ManastormAffixDefinition const*
ManastormAffixEngine::GetDefinition(
    uint32 affixId) const
{
    return ManastormDataStore::Instance()
        .GetAffixById(affixId);
}

bool ManastormAffixEngine::ValidateDefinition(
    ManastormAffixDefinition const& definition,
    std::string& error) const
{
    error.clear();

    if (!definition.AffixId ||
        !definition.MarkerSpellId ||
        !sSpellMgr->GetSpellInfo(
            definition.MarkerSpellId))
    {
        error =
            "Affix root spell " +
            std::to_string(
                definition.MarkerSpellId) +
            " is not loaded.";

        return false;
    }

    uint32 const triggers[] =
    {
        definition.DeathTriggerSpellId,
        definition.SecondaryDeathTriggerSpellId
    };

    for (uint32 spellId : triggers)
    {
        if (spellId &&
            !sSpellMgr->GetSpellInfo(spellId))
        {
            error =
                "Affix " +
                definition.Name +
                " requires trigger spell " +
                std::to_string(spellId) +
                ".";

            return false;
        }
    }

    uint32 const helpers[] =
    {
        definition.HelperCreatureEntry1,
        definition.HelperCreatureEntry2
    };

    for (uint32 entry : helpers)
    {
        if (entry &&
            !sObjectMgr->GetCreatureTemplate(
                entry))
        {
            error =
                "Affix " +
                definition.Name +
                " requires helper creature " +
                std::to_string(entry) +
                ".";

            return false;
        }
    }

    for (ManastormAffixRankSpell const& rankSpell :
        definition.RankSpells)
    {
        if (!sSpellMgr->GetSpellInfo(
                rankSpell.SpellId))
        {
            LOG_WARN(
                LOG_FILTER,
                "Recovered affix {} ({}) is missing "
                "rank spell {} (role {} rank {}).",
                definition.AffixId,
                definition.Name,
                rankSpell.SpellId,
                uint32(rankSpell.Role),
                uint32(rankSpell.Rank));
        }
    }

    if (definition.AffixId ==
        ManastormAffixIds::ManaBomb)
    {
        uint32 const spells[] =
        {
            ManastormManaBomb::EffectSpell,
            ManastormManaBomb::DispatcherSpell,
            ManastormManaBomb::DebuffSpell
        };

        for (uint32 spellId : spells)
        {
            if (!sSpellMgr->GetSpellInfo(
                    spellId))
            {
                error =
                    "Mana Bomb requires spell " +
                    std::to_string(spellId) +
                    ".";

                return false;
            }
        }
    }

    return true;
}

void ManastormAffixEngine::InitializeStage(
    ManastormRun& run,
    std::unordered_set<uint32> const&
        unlockedAffixIds)
{
    run.ClearStageAffixState();

    if (run.GetCreatureLevel() < ManastormModuleConfig::AffixMinimumLevel())
        return;

    ManastormDataStore const& store =
        ManastormDataStore::Instance();

    uint32 firstUnlockDepth = std::numeric_limits<uint32>::max();
    for (auto const& pair : store.GetAffixes())
        if (pair.second.AutomaticSelection &&
            pair.second.Availability == ManastormAffixAvailabilityKind::ProgressionUnlock)
            firstUnlockDepth = std::min(firstUnlockDepth, pair.second.UnlockDepth);
    if (run.GetDepth() <= firstUnlockDepth)
        return;

    ManastormAffixPolicy const* policy =
        store.GetAffixPolicyForDepth(
            run.GetDepth());

    if (!policy)
    {
        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} depth {} has no enabled "
            "affix policy; automatic selection is disabled.",
            run.GetRunId(),
            run.GetDepth());

        return;
    }

    std::vector<
        ManastormAffixDefinition const*>
        creatureCandidates;

    std::vector<
        ManastormAffixDefinition const*>
        environmentCandidates;

    for (auto const& pair :
        store.GetAffixes())
    {
        ManastormAffixDefinition const& definition =
            pair.second;

        if (!definition.AutomaticSelection ||
            definition.Availability ==
                ManastormAffixAvailabilityKind::ForcedOnly)
        {
            continue;
        }

        if (definition.Availability ==
                ManastormAffixAvailabilityKind::ProgressionUnlock &&
            unlockedAffixIds.find(
                definition.AffixId) ==
                unlockedAffixIds.end())
        {
            continue;
        }

        if (definition.Targets(
                ManastormAffixTargetBits::RouteCreature) ||
            definition.Targets(
                ManastormAffixTargetBits::Boss))
        {
            creatureCandidates.push_back(
                &definition);
        }

        if (definition.Targets(
                ManastormAffixTargetBits::Player) ||
            definition.Targets(
                ManastormAffixTargetBits::Environment))
        {
            environmentCandidates.push_back(
                &definition);
        }
    }

    auto orderCandidates =
        [&run](
            std::vector<
                ManastormAffixDefinition const*>& candidates,
            uint64 salt)
    {
        std::sort(
            candidates.begin(),
            candidates.end(),
            [&run, salt](
                ManastormAffixDefinition const* left,
                ManastormAffixDefinition const* right)
            {
                uint64 const leftKey =
                    SelectionKey(
                        run,
                        left->AffixId,
                        salt,
                        left->SelectionWeight);

                uint64 const rightKey =
                    SelectionKey(
                        run,
                        right->AffixId,
                        salt,
                        right->SelectionWeight);

                if (leftKey != rightKey)
                    return leftKey < rightKey;

                return left->AffixId <
                    right->AffixId;
            });
    };

    orderCandidates(
        creatureCandidates,
        0x4352454154555245ULL);

    orderCandidates(
        environmentCandidates,
        0x454e5649524f4e4dULL);

    auto addCandidates =
        [&run, policy, this](
            std::vector<
                ManastormAffixDefinition const*> const& candidates,
            uint8 wanted)
    {
        uint8 added = 0;

        for (ManastormAffixDefinition const* definition :
            candidates)
        {
            if (!definition ||
                added >= wanted)
            {
                break;
            }

            std::string validationError;

            if (!ValidateDefinition(
                    *definition,
                    validationError))
            {
                LOG_WARN(
                    LOG_FILTER,
                    "Skipping automatic Manastorm affix {} ({}): {}",
                    definition->AffixId,
                    definition->Name,
                    validationError);

                continue;
            }

            uint8 rank =
                definition->MaxRank
                ? std::min<uint8>(
                    policy->DefaultRank,
                    definition->MaxRank)
                : 1;

            if (run.AddStageAffix(
                    definition->AffixId,
                    rank))
            {
                ++added;
            }
        }
    };

    addCandidates(
        creatureCandidates,
        policy->CreatureStageAffixCount);

    addCandidates(
        environmentCandidates,
        policy->EnvironmentStageAffixCount);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} initialized affix state for depth {}: "
        "ownedUnlockAffixes={} creatureCandidates={} "
        "environmentCandidates={} activeAffixes={} "
        "policy={} creatureChance={:.2f}% secondChance={:.2f}% "
        "bossChance={:.2f}% defaultRank={}.",
        run.GetRunId(),
        run.GetDepth(),
        unlockedAffixIds.size(),
        creatureCandidates.size(),
        environmentCandidates.size(),
        run.GetActiveStageAffixIds().size(),
        policy->PolicyId,
        policy->CreatureAffixChancePct,
        policy->SecondAffixChancePct,
        policy->BossAffixChancePct,
        uint32(policy->DefaultRank));
}

bool ManastormAffixEngine::ForceStageAffix(
    ManastormRun& run,
    uint32 affixId,
    std::string& error)
{
    error.clear();

    ManastormAffixDefinition const* definition =
        GetDefinition(affixId);

    if (!definition)
    {
        error =
            "Unknown or disabled Manastorm affix " +
            std::to_string(affixId) +
            ".";

        return false;
    }

    if (!ValidateDefinition(
            *definition,
            error))
    {
        return false;
    }

    if (!definition->BoundedRuntime)
    {
        LOG_WARN(
            LOG_FILTER,
            "Forcing recovered affix {} ({}) "
            "with an unresolved original runtime edge.",
            affixId,
            definition->Name);
    }

    uint8 rank = 1;

    if (ManastormAffixPolicy const* policy =
        ManastormDataStore::Instance()
            .GetAffixPolicyForDepth(
                run.GetDepth()))
    {
        if (definition->MaxRank)
        {
            rank =
                std::min<uint8>(
                    policy->DefaultRank,
                    definition->MaxRank);
        }
    }

    run.AddStageAffix(
        affixId,
        rank);

    return true;
}

bool ManastormAffixEngine::IsAffixHelperCreature(
    uint32 creatureEntry) const
{
    if (!creatureEntry)
        return false;

    for (auto const& pair :
        ManastormDataStore::Instance()
            .GetAffixes())
    {
        ManastormAffixDefinition const& definition =
            pair.second;

        if (definition.HelperCreatureEntry1 ==
                creatureEntry ||
            definition.HelperCreatureEntry2 ==
                creatureEntry)
        {
            return true;
        }
    }

    return false;
}

bool ManastormAffixEngine::IsEligibleStageCreature(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!creature ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsAffixHelperCreature(
            creature->GetEntry()) ||
        IsPlayerControlledCreature(
            creature))
    {
        return false;
    }

    return run.IsStageCreature(
        creature->GetGUID());
}

bool ManastormAffixEngine::IsEligibleTrashTarget(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!IsEligibleStageCreature(
            creature,
            run))
    {
        return false;
    }

    ObjectGuid const objectiveGuid =
        run.GetObjectiveCreatureGuid();

    if (!objectiveGuid.IsEmpty() &&
        creature->GetGUID() ==
            objectiveGuid)
    {
        return false;
    }

    ObjectGuid::LowType const spawnId =
        creature->GetSpawnId();

    return spawnId &&
        run.IsAffixEligibleSpawn(
            spawnId);
}

bool ManastormAffixEngine::IsEligibleBossTarget(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!IsEligibleStageCreature(
            creature,
            run))
    {
        return false;
    }

    ObjectGuid const objectiveGuid =
        run.GetObjectiveCreatureGuid();

    return !objectiveGuid.IsEmpty() &&
        creature->GetGUID() ==
            objectiveGuid;
}

bool ManastormAffixEngine::IsEligibleForManaBomb(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!IsEligibleTrashTarget(
            creature,
            run))
    {
        return false;
    }

    ObjectGuid::LowType const spawnId =
        creature->GetSpawnId();

    return spawnId &&
        run.IsChaoticLinkSpawn(
            spawnId);
}

bool ManastormAffixEngine::AssignAffixToCreature(
    Creature* creature,
    ManastormRun& run,
    ManastormAffixDefinition const& definition,
    bool force)
{
    bool const boss =
        IsEligibleBossTarget(
            creature,
            run);

    bool const trash =
        !boss &&
        IsEligibleTrashTarget(
            creature,
            run);

    if (boss)
    {
        if (!definition.Targets(
                ManastormAffixTargetBits::Boss))
        {
            return false;
        }
    }
    else if (trash)
    {
        if (!definition.Targets(
                ManastormAffixTargetBits::RouteCreature))
        {
            return false;
        }
    }
    else
    {
        return false;
    }

    if (definition.AffixId ==
            ManastormAffixIds::ManaBomb &&
        !IsEligibleForManaBomb(
            creature,
            run))
    {
        return false;
    }

    bool const alreadyAssigned =
        run.HasCreatureAffix(
            creature->GetGUID(),
            definition.AffixId);

    if (!alreadyAssigned &&
        !force)
    {
        ManastormAffixPolicy const* policy =
            ManastormDataStore::Instance()
                .GetAffixPolicyForDepth(
                    run.GetDepth());

        if (!policy)
            return false;

        float chance = 0.0f;

        if (boss)
        {
            chance =
                policy->BossAffixChancePct;
        }
        else
        {
            std::unordered_set<uint32> const*
                existing =
                    run.GetCreatureAffixIds(
                        creature->GetGUID());

            chance =
                (!existing ||
                 existing->empty())
                ? policy->CreatureAffixChancePct
                : policy->SecondAffixChancePct;
        }

        if (!PassChance(
                run,
                creature,
                definition.AffixId,
                chance,
                boss
                    ? 0x424f5353ULL
                    : 0x5452415348ULL))
        {
            return false;
        }
    }

    bool const newlyAssigned =
        alreadyAssigned
        ? false
        : run.AssignCreatureAffix(
            creature->GetGUID(),
            definition.AffixId);

    if (!newlyAssigned &&
        !run.HasCreatureAffix(
            creature->GetGUID(),
            definition.AffixId))
    {
        return false;
    }

    // Creatures are discovered while the disposable stage is PREPARING.
    // Record ownership then, but do not start periodic/hazard auras inside
    // the two-minute safety bubble.  OnCreatureAdded() is intentionally
    // replayed when the stage becomes ACTIVE.
    if (run.GetState() ==
            ManastormRunState::Active &&
        definition.ApplyMarkerAura &&
        definition.MarkerSpellId &&
        !creature->HasAura(
            definition.MarkerSpellId))
    {
        creature->CastSpell(
            creature,
            definition.MarkerSpellId,
            true);
    }

    if (newlyAssigned)
    {
        LOG_DEBUG(
            LOG_FILTER,
            "Manastorm run {} assigned affix {} ({}) rank {} "
            "to {} entry={} spawn={} guid={}.",
            run.GetRunId(),
            definition.AffixId,
            definition.Name,
            uint32(
                run.GetStageAffixRank(
                    definition.AffixId)),
            boss ? "boss" : "route creature",
            creature->GetEntry(),
            creature->GetSpawnId(),
            creature->GetGUID().GetRawValue());
    }

    return newlyAssigned;
}

bool ManastormAffixEngine::ForceAffixOnCreature(
    Creature* creature,
    ManastormRun& run,
    uint32 affixId)
{
    ManastormAffixDefinition const* definition =
        GetDefinition(affixId);

    return definition &&
        AssignAffixToCreature(
            creature,
            run,
            *definition,
            true);
}

void ManastormAffixEngine::AssignActiveAffixes(
    Creature* creature,
    ManastormRun& run)
{
    if (!IsEligibleStageCreature(
            creature,
            run))
    {
        return;
    }

    std::vector<uint32> orderedAffixes(
        run.GetActiveStageAffixIds().begin(),
        run.GetActiveStageAffixIds().end());

    std::sort(
        orderedAffixes.begin(),
        orderedAffixes.end());

    for (uint32 affixId :
        orderedAffixes)
    {
        ManastormAffixDefinition const* definition =
            GetDefinition(affixId);

        if (!definition)
            continue;

        AssignAffixToCreature(
            creature,
            run,
            *definition,
            false);
    }
}

void ManastormAffixEngine::ApplyActivePlayerAffixes(
    Player* player,
    ManastormRun& run)
{
    if (!player ||
        !player->IsInWorld())
    {
        return;
    }

    for (uint32 affixId :
        run.GetActiveStageAffixIds())
    {
        ManastormAffixDefinition const* definition =
            GetDefinition(affixId);

        if (!definition ||
            (!definition->Targets(
                ManastormAffixTargetBits::Player) &&
             !definition->Targets(
                ManastormAffixTargetBits::Environment)) ||
            !definition->ApplyMarkerAura ||
            !definition->MarkerSpellId)
        {
            continue;
        }

        if (!player->HasAura(
                definition->MarkerSpellId))
        {
            player->CastSpell(
                player,
                definition->MarkerSpellId,
                true);
        }
    }
}

void ManastormAffixEngine::RemoveActivePlayerAffixes(
    Player* player,
    ManastormRun const& run)
{
    if (!player)
        return;

    for (uint32 affixId :
        run.GetActiveStageAffixIds())
    {
        ManastormAffixDefinition const* definition =
            GetDefinition(affixId);

        if (!definition ||
            (!definition->Targets(
                ManastormAffixTargetBits::Player) &&
             !definition->Targets(
                ManastormAffixTargetBits::Environment)) ||
            !definition->MarkerSpellId)
        {
            continue;
        }

        player->RemoveAurasDueToSpell(
            definition->MarkerSpellId);
    }
}

void ManastormAffixEngine::OnCreatureAdded(
    Creature* creature,
    ManastormRun& run)
{
    if (!creature)
        return;

    if (IsAffixHelperCreature(
            creature->GetEntry()))
    {
        // Mana Bomb's existing visual helper historically follows its
        // summoner. Preserve recovered dispositions for the other helpers.
        if (creature->GetEntry() ==
                ManastormManaBomb::HelperCreature &&
            creature->IsSummon())
        {
            if (TempSummon* summon =
                creature->ToTempSummon())
            {
                if (Unit* summoner =
                    summon->GetSummonerUnit())
                {
                    creature->SetFaction(
                        summoner->GetFaction());
                }
            }
        }

        if (run.GetState() !=
            ManastormRunState::Active)
        {
            return;
        }

        uint32 activationSpell = 0;

        switch (creature->GetEntry())
        {
        case NPC_CREEPING_FROST:
            if (run.HasStageAffix(
                    ManastormAffixIds::CreepingFrost))
            {
                activationSpell =
                    SPELL_CREEPING_FROST_EFFECT;
            }
            break;

        case NPC_COLD_SNAP:
            if (run.HasStageAffix(
                    ManastormAffixIds::ColdSnap))
            {
                activationSpell =
                    SPELL_COLD_SNAP_AURA;
            }
            break;

        case NPC_COLD_SNAP_EFFECT:
            if (run.HasStageAffix(
                    ManastormAffixIds::ColdSnap))
            {
                activationSpell =
                    SPELL_COLD_SNAP_EFFECT_AURA;
            }
            break;

        case NPC_FUNGAL_MUSHROOM:
            if (run.HasStageAffix(
                    ManastormAffixIds::Fungal))
            {
                activationSpell =
                    SPELL_FUNGAL_AURA;
            }
            break;

        case NPC_BONESTORM:
            if (run.HasStageAffix(
                    ManastormAffixIds::BoneStorm))
            {
                // Recovered 93371 is only a 1 ms periodic bridge into the
                // actual 8-second Bonestorm hazard aura (93369). AzerothCore
                // can expire that bridge before it produces a reliable tick,
                // so attach the recovered hazard aura directly to the helper.
                activationSpell =
                    SPELL_BONESTORM_AURA;

                // The recovered Bonestorm tooltip explicitly says that the
                // storm chases the player. The original proprietary movement
                // speed was not recovered. Keep the hazard escapable instead
                // of using the helper template's 1.14286 run rate, which is
                // faster than a normal player's 1.0 run rate.
                creature->SetSpeed(
                    MOVE_RUN,
                    BONESTORM_RUN_SPEED_RATE,
                    true);

                if (Player* target =
                    creature->SelectNearestPlayer(
                        100.0f))
                {
                    if (target->IsAlive())
                    {
                        // FollowMovementGenerator adds the follower's own
                        // combat reach to this range. Cancel that built-in
                        // separation so the Bonestorm center can actually
                        // pass over the Hero, matching the recovered 1-yard
                        // damage radius around the helper.
                        creature->GetMotionMaster()->MoveFollow(
                            target,
                            -creature->GetCombatReach(),
                            0.0f,
                            MOTION_SLOT_ACTIVE,
                            false,
                            false);
                    }
                }
            }
            break;

        case NPC_OVERWHELMING_ENERGY:
            if (run.HasStageAffix(
                    ManastormAffixIds::OverwhelmingEnergy))
            {
                activationSpell =
                    SPELL_OVERWHELMING_COSMETIC_AURA;
            }
            break;

        default:
            break;
        }

        if (activationSpell)
        {
            creature->CastSpell(
                creature,
                activationSpell,
                true);

            LOG_DEBUG(
                LOG_FILTER,
                "Manastorm run {} activated affix helper "
                "entry={} guid={} spell={}.",
                run.GetRunId(),
                creature->GetEntry(),
                creature->GetGUID().GetRawValue(),
                activationSpell);
        }

        return;
    }

    AssignActiveAffixes(
        creature,
        run);
}

void ManastormAffixEngine::OnCreatureRemoved(
    Creature* creature,
    ManastormRun& run)
{
    if (!creature ||
        IsAffixHelperCreature(
            creature->GetEntry()))
    {
        return;
    }

    run.ClearCreatureAffixes(
        creature->GetGUID());
}

void ManastormAffixEngine::OnCreatureDeath(
    Creature* creature,
    ManastormRun& run)
{
    if (!IsEligibleStageCreature(
            creature,
            run))
    {
        return;
    }

    std::unordered_set<uint32> const* affixes =
        run.GetCreatureAffixIds(
            creature->GetGUID());

    if (!affixes)
        return;

    for (uint32 affixId :
        *affixes)
    {
        ManastormAffixDefinition const* definition =
            GetDefinition(affixId);

        if (definition &&
            definition->RuntimeType ==
                ManastormAffixRuntimeType::OnDeath)
        {
            DispatchOnDeath(
                creature,
                run,
                affixId);
        }
    }
}

void ManastormAffixEngine::DispatchOnDeath(
    Creature* creature,
    ManastormRun& run,
    uint32 affixId)
{
    if (!creature)
        return;

    if (affixId ==
        ManastormAffixIds::ManaBomb)
    {
        StartManaBomb(
            creature,
            run);

        return;
    }

    ManastormAffixDefinition const* definition =
        GetDefinition(affixId);

    if (!definition)
        return;

    uint32 const triggers[] =
    {
        definition->DeathTriggerSpellId,
        definition->SecondaryDeathTriggerSpellId
    };

    for (uint32 spellId : triggers)
    {
        if (spellId)
        {
            creature->CastSpell(
                creature,
                spellId,
                true);
        }
    }
}

void ManastormAffixEngine::StartManaBomb(
    Creature* creature,
    ManastormRun& run)
{
    if (!creature)
        return;

    creature->CastSpell(
        creature,
        ManastormManaBomb::PrecastSpell,
        true);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm Mana Bomb started: run={} depth={} "
        "creatureEntry={} creatureGuid={} spell={}.",
        run.GetRunId(),
        run.GetDepth(),
        creature->GetEntry(),
        creature->GetGUID().GetRawValue(),
        ManastormManaBomb::PrecastSpell);
}
