#include "ManastormAffixEngine.h"

#include "Creature.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "ManastormRun.h"

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    constexpr ManastormAffixDefinition
        MANA_BOMB_DEFINITION
        {
            ManastormManaBomb::AffixId,
            ManastormManaBomb::MarkerSpell,
            ManastormAffixRuntimeType::OnDeath
        };

    bool IsPlayerControlledCreature(
        Creature const* creature)
    {
        return creature &&
            (creature->IsControlledByPlayer() ||
             creature->IsCreatedByPlayer() ||
             creature->IsCharmedOwnedByPlayerOrPlayer());
    }
}

ManastormAffixEngine&
ManastormAffixEngine::Instance()
{
    static ManastormAffixEngine instance;
    return instance;
}

ManastormAffixDefinition const*
ManastormAffixEngine::GetDefinition(
    uint32 affixId) const
{
    switch (affixId)
    {
    case ManastormManaBomb::AffixId:
        return &MANA_BOMB_DEFINITION;

    default:
        return nullptr;
    }
}

bool ManastormAffixEngine::ValidateDefinition(
    ManastormAffixDefinition const& definition,
    std::string& error) const
{
    error.clear();

    if (!definition.AffixId)
    {
        error =
            "Affix definition has affix_id=0.";

        return false;
    }

    if (!definition.MarkerSpellId ||
        !sSpellMgr->GetSpellInfo(
            definition.MarkerSpellId))
    {
        error =
            "Affix marker spell " +
            std::to_string(
                definition.MarkerSpellId) +
            " is not loaded by the server.";

        return false;
    }

    if (definition.AffixId ==
        ManastormManaBomb::AffixId)
    {
        uint32 const requiredSpells[] =
        {
            ManastormManaBomb::PrecastSpell,
            ManastormManaBomb::EffectSpell,
            ManastormManaBomb::DispatcherSpell,
            ManastormManaBomb::DebuffSpell
        };

        for (uint32 spellId :
            requiredSpells)
        {
            if (sSpellMgr->GetSpellInfo(
                spellId))
            {
                continue;
            }

            error =
                "Mana Bomb requires spell " +
                std::to_string(spellId) +
                ", but it is not loaded by the server.";

            return false;
        }

        if (!sObjectMgr->GetCreatureTemplate(
            ManastormManaBomb::
            HelperCreature))
        {
            error =
                "Mana Bomb helper creature 663028 "
                "does not exist in creature_template.";

            return false;
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

    std::size_t recognizedAffixes = 0;

    for (uint32 affixId :
        unlockedAffixIds)
    {
        if (GetDefinition(affixId))
            ++recognizedAffixes;
    }

    //
    // We deliberately stop at the eligible-pool boundary.
    //
    // We have NOT yet proven:
    //
    // - number of active affixes per depth;
    // - density;
    // - historical rank selection;
    // - weighting;
    // - whether bosses use the same assignment policy.
    //
    // Therefore production/random stage selection remains disabled
    // until those rules are recovered.
    //
    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} initialized affix state for depth {}: "
        "ownedAffixes={} recognizedCandidates={} activeAffixes=0. "
        "Automatic historical selection is not enabled yet.",
        run.GetRunId(),
        run.GetDepth(),
        unlockedAffixIds.size(),
        recognizedAffixes);
}

bool ManastormAffixEngine::ForceStageAffix(
    ManastormRun& run,
    uint32 affixId,
    std::string& error)
{
    error.clear();

    ManastormAffixDefinition const*
        definition =
            GetDefinition(affixId);

    if (!definition)
    {
        error =
            "Unknown or unsupported Manastorm affix " +
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

    bool const newlyAdded =
        run.AddStageAffix(
            affixId);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} {} forced affix {} for "
        "depth {}.",
        run.GetRunId(),
        newlyAdded
            ? "added"
            : "already had",
        affixId,
        run.GetDepth());

    return true;
}

bool ManastormAffixEngine::
IsEligibleStageCreature(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!creature ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsPlayerControlledCreature(
            creature))
    {
        return false;
    }

    if (!run.IsStageCreature(
        creature->GetGUID()))
    {
        return false;
    }

    //
    // Objective-boss affix eligibility has NOT yet been
    // recovered from Ascension.
    //
    // Until that behavior is known, do not silently treat
    // bosses as normal affix-bearing trash.
    //
    ObjectGuid const objectiveGuid =
        run.GetObjectiveCreatureGuid();

    if (!objectiveGuid.IsEmpty() &&
        creature->GetGUID() ==
        objectiveGuid)
    {
        return false;
    }

    return true;
}


bool ManastormAffixEngine::
IsEligibleForManaBomb(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!IsEligibleStageCreature(
        creature,
        run))
    {
        return false;
    }

    //
    // Mana Bomb currently belongs only to creatures explicitly
    // authored into this segment's Chaotic Link route.
    //
    // This is intentionally based on the immutable configured
    // route membership, NOT on whether this spawn can still
    // consume another boss Link.
    //
    ObjectGuid::LowType const spawnId =
        creature->GetSpawnId();

    if (!spawnId)
        return false;

    return run.IsChaoticLinkSpawn(
        spawnId);
}

void ManastormAffixEngine::
AssignActiveAffixes(
    Creature* creature,
    ManastormRun& run)
{
    if (!IsEligibleStageCreature(
        creature,
        run))
    {
        return;
    }

    for (uint32 affixId :
        run.GetActiveStageAffixIds())
    {
        ManastormAffixDefinition const*
            definition =
                GetDefinition(affixId);

        if (!definition)
            continue;

        //
        // Individual affixes own their eligibility rules.
        //
        // Mana Bomb:
        //     authored Chaotic Link route creatures only.
        //
        if (affixId ==
            ManastormManaBomb::AffixId &&
            !IsEligibleForManaBomb(
                creature,
                run))
        {
            continue;
        }

        bool const newlyAssigned =
            run.AssignCreatureAffix(
                creature->GetGUID(),
                affixId);

        if (!newlyAssigned)
            continue;

        //
        // 93363 is the recovered Mana Bomb affix marker.
        //
        // It does not provide our server-side death dispatcher:
        // the recovered row has ProcFlags=0.
        //
        // We still apply the actual marker aura so the creature
        // carries the recovered Ascension spell identity.
        //
        if (definition->MarkerSpellId &&
            !creature->HasAura(
                definition->MarkerSpellId))
        {
            creature->CastSpell(
                creature,
                definition->MarkerSpellId,
                true);
        }

        LOG_DEBUG(
            LOG_FILTER,
            "Manastorm run {} assigned affix {} "
            "to creature entry={} guid={}.",
            run.GetRunId(),
            affixId,
            creature->GetEntry(),
            creature->GetGUID()
                .GetRawValue());
    }
}

void ManastormAffixEngine::OnCreatureAdded(
    Creature* creature,
    ManastormRun& run)
{
    if (!creature)
        return;

    //
    // 663028 is NOT a normal affixed stage creature.
    //
    // It is the recovered invisible Mana Bomb helper summoned
    // by 93364.
    //
    if (creature->GetEntry() ==
        ManastormManaBomb::HelperCreature)
    {
        if (creature->IsSummon())
        {
            TempSummon* summon =
                creature->ToTempSummon();

            Unit* summoner =
                summon
                ? summon->GetSummonerUnit()
                : nullptr;

            if (summoner)
            {
                //
                // SummonProperties 64 does not give our stock
                // core a reliable faction-inheritance rule.
                //
                // Preserve the producing creature's faction so
                // future enemy/ally Mana Bomb targeting has the
                // correct relationship context.
                //
                creature->SetFaction(
                    summoner->GetFaction());

                LOG_DEBUG(
                    LOG_FILTER,
                    "Manastorm run {} initialized Mana Bomb "
                    "helper guid={} from summoner guid={} "
                    "with faction={}.",
                    run.GetRunId(),
                    creature->GetGUID()
                        .GetRawValue(),
                    summoner->GetGUID()
                        .GetRawValue(),
                    creature->GetFaction());
            }
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
    if (!creature)
        return;

    if (creature->GetEntry() ==
        ManastormManaBomb::HelperCreature)
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

    std::unordered_set<uint32> const*
        affixes =
            run.GetCreatureAffixIds(
                creature->GetGUID());

    if (!affixes)
        return;

    for (uint32 affixId :
        *affixes)
    {
        ManastormAffixDefinition const*
            definition =
                GetDefinition(affixId);

        if (!definition)
            continue;

        switch (definition->RuntimeType)
        {
        case ManastormAffixRuntimeType::OnDeath:
            DispatchOnDeath(
                creature,
                run,
                affixId);
            break;

        case ManastormAffixRuntimeType::Passive:
        case ManastormAffixRuntimeType::Periodic:
        case ManastormAffixRuntimeType::Environmental:
        case ManastormAffixRuntimeType::SpawnedHazard:
            break;
        }
    }
}

void ManastormAffixEngine::DispatchOnDeath(
    Creature* creature,
    ManastormRun& run,
    uint32 affixId)
{
    switch (affixId)
    {
    case ManastormManaBomb::AffixId:
        StartManaBomb(
            creature,
            run);
        break;

    default:
        break;
    }
}

void ManastormAffixEngine::StartManaBomb(
    Creature* creature,
    ManastormRun& run)
{
    if (!creature)
        return;

    //
    // Recovered Ascension chain:
    //
    // 93363 Mana Bomb
    //      ↓ creature death
    //
    // 93364 Mana Bomb Precast
    //      ├── visual 20636
    //      ├── summons 663028
    //      └── Effect 193 / amplitude 4000 / trigger 93488
    //
    // We deliberately DO NOT hard-code:
    //
    //      4000 ms -> 93488
    //
    // here yet.
    //
    // ASTRA is currently determining whether Effect 193 itself
    // provides that generic behavior or whether it was a
    // server-side scripted dispatcher.
    //
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
        creature->GetGUID()
            .GetRawValue(),
        ManastormManaBomb::PrecastSpell);
}
