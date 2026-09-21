#include "ManastormAffixEngine.h"

#include "Creature.h"
#include "Log.h"
#include "ManastormRun.h"
#include "ObjectMgr.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"

#include <array>
#include <string_view>

namespace
{
constexpr char const* LOG_FILTER = "module.manastorm.endless";

struct RecoveredAffixMetadata
{
    ManastormAffixDefinition Definition;
    std::string_view Name;
    uint32 UnlockDepth = 0;
    uint32 DeathTriggerSpellId = 0;
    uint32 SecondaryDeathTriggerSpellId = 0;
    uint32 HelperCreatureEntry1 = 0;
    uint32 HelperCreatureEntry2 = 0;
    uint32 PrimaryRankFirstSpellId = 0;
    uint32 SecondaryRankFirstSpellId = 0;
    uint8 MaxRank = 0;
    bool ApplyMarkerAura = true;
    bool BoundedRuntime = false;
};

constexpr std::array<RecoveredAffixMetadata, 14> RECOVERED_AFFIXES =
{{
    {{ ManastormAffixIds::ManaBomb, 93363, ManastormAffixRuntimeType::OnDeath },
        "Mana Bomb", 11, 93364, 0, 663028, 0, 93490, 115211, 20, true, true},
    {{ ManastormAffixIds::LightningRod, 93354, ManastormAffixRuntimeType::OnDeath },
        "Lightning Rod", 13, 93355, 0, 0, 0, 115151, 115171, 20, true, true},
    {{ ManastormAffixIds::Rampaging, 94758, ManastormAffixRuntimeType::Passive },
        "Rampaging", 16, 0, 0, 0, 0, 115551, 0, 20, true, true},
    {{ ManastormAffixIds::AethyricWinds, 94749, ManastormAffixRuntimeType::OnDeath },
        "Aethyric Winds", 19, 94764, 0, 0, 0, 0, 0, 0, true, true},
    {{ ManastormAffixIds::ColdSnap, 93444, ManastormAffixRuntimeType::OnDeath },
        "Cold Snap", 21, 93445, 0, 80924, 80925, 115451, 0, 20, true, false},
    {{ ManastormAffixIds::TribalFury, 93422, ManastormAffixRuntimeType::Passive },
        "Tribal Fury", 23, 0, 0, 0, 0, 115391, 0, 20, true, true},
    {{ ManastormAffixIds::Vortex, 93381, ManastormAffixRuntimeType::OnDeath },
        "Vortex", 26, 93382, 0, 0, 0, 115371, 0, 20, true, true},
    {{ ManastormAffixIds::Stalwart, 94760, ManastormAffixRuntimeType::Passive },
        "Stalwart", 28, 0, 0, 0, 0, 115571, 0, 20, true, true},
    {{ ManastormAffixIds::Fungal, 93377, ManastormAffixRuntimeType::OnDeath },
        "Fungal", 31, 93378, 0, 80914, 0, 115271, 0, 20, false, false},
    {{ ManastormAffixIds::WildMagics, 93425, ManastormAffixRuntimeType::Passive },
        "Wild Magics", 33, 0, 0, 80922, 80923, 115431, 0, 20, true, false},
    {{ ManastormAffixIds::RunesOfPower, 94752, ManastormAffixRuntimeType::OnDeath },
        "Runes of Power", 39, 94753, 94762, 0, 0, 0, 0, 0, true, true},
    {{ ManastormAffixIds::Reflecting, 93360, ManastormAffixRuntimeType::Passive },
        "Reflecting", 41, 0, 0, 0, 0, 115191, 0, 20, true, false},
    {{ ManastormAffixIds::BoneStorm, 93366, ManastormAffixRuntimeType::OnDeath },
        "Bone Storm", 61, 93367, 0, 80913, 0, 115231, 0, 20, true, false},
    {{ ManastormAffixIds::OverwhelmingEnergy, 93383, ManastormAffixRuntimeType::OnDeath },
        "Overwhelming Energy", 101, 93408, 0, 80917, 0, 115291, 0, 20, true, false}
}};

RecoveredAffixMetadata const* GetRecoveredMetadata(uint32 affixId)
{
    for (RecoveredAffixMetadata const& metadata : RECOVERED_AFFIXES)
        if (metadata.Definition.AffixId == affixId)
            return &metadata;
    return nullptr;
}

bool IsPlayerControlledCreature(Creature const* creature)
{
    return creature &&
        (creature->IsControlledByPlayer() ||
         creature->IsCreatedByPlayer() ||
         creature->IsCharmedOwnedByPlayerOrPlayer());
}
}

ManastormAffixEngine& ManastormAffixEngine::Instance()
{
    static ManastormAffixEngine instance;
    return instance;
}

ManastormAffixDefinition const* ManastormAffixEngine::GetDefinition(uint32 affixId) const
{
    if (RecoveredAffixMetadata const* metadata = GetRecoveredMetadata(affixId))
        return &metadata->Definition;
    return nullptr;
}

bool ManastormAffixEngine::ValidateDefinition(
    ManastormAffixDefinition const& definition,
    std::string& error) const
{
    error.clear();
    RecoveredAffixMetadata const* metadata = GetRecoveredMetadata(definition.AffixId);
    if (!metadata)
    {
        error = "Affix is not part of the recovered Manastorm catalogue.";
        return false;
    }

    if (!definition.MarkerSpellId || !sSpellMgr->GetSpellInfo(definition.MarkerSpellId))
    {
        error = "Affix root spell " + std::to_string(definition.MarkerSpellId) + " is not loaded.";
        return false;
    }

    uint32 const triggers[] =
    {
        metadata->DeathTriggerSpellId,
        metadata->SecondaryDeathTriggerSpellId
    };
    for (uint32 spellId : triggers)
    {
        if (spellId && !sSpellMgr->GetSpellInfo(spellId))
        {
            error = "Affix " + std::string(metadata->Name) +
                " requires trigger spell " + std::to_string(spellId) + ".";
            return false;
        }
    }

    uint32 const helpers[] =
    {
        metadata->HelperCreatureEntry1,
        metadata->HelperCreatureEntry2
    };
    for (uint32 entry : helpers)
    {
        if (entry && !sObjectMgr->GetCreatureTemplate(entry))
        {
            error = "Affix " + std::string(metadata->Name) +
                " requires helper creature " + std::to_string(entry) + ".";
            return false;
        }
    }

    if (metadata->MaxRank)
    {
        uint32 const firstSpells[] =
        {
            metadata->PrimaryRankFirstSpellId,
            metadata->SecondaryRankFirstSpellId
        };

        for (uint32 firstSpell : firstSpells)
        {
            if (!firstSpell)
                continue;

            for (uint8 rank = 0; rank < metadata->MaxRank; ++rank)
            {
                uint32 const spellId = firstSpell + uint32(rank);
                if (!sSpellMgr->GetSpellInfo(spellId))
                    LOG_WARN(LOG_FILTER,
                        "Recovered affix {} ({}) is missing rank spell {} (rank {}).",
                        definition.AffixId, metadata->Name, spellId, uint32(rank) + 1);
            }
        }
    }

    if (definition.AffixId == ManastormAffixIds::ManaBomb)
    {
        uint32 const spells[] =
        {
            ManastormManaBomb::EffectSpell,
            ManastormManaBomb::DispatcherSpell,
            ManastormManaBomb::DebuffSpell
        };
        for (uint32 spellId : spells)
            if (!sSpellMgr->GetSpellInfo(spellId))
            {
                error = "Mana Bomb requires spell " + std::to_string(spellId) + ".";
                return false;
            }
    }

    return true;
}

void ManastormAffixEngine::InitializeStage(
    ManastormRun& run,
    std::unordered_set<uint32> const& unlockedAffixIds)
{
    run.ClearStageAffixState();

    std::size_t recognizedAffixes = 0;
    for (uint32 affixId : unlockedAffixIds)
        if (GetDefinition(affixId))
            ++recognizedAffixes;

    LOG_INFO(LOG_FILTER,
        "Manastorm run {} initialized affix state for depth {}: "
        "ownedAffixes={} recognizedCandidates={} activeAffixes=0. "
        "Historical automatic selection/density/rank policy remains disabled.",
        run.GetRunId(), run.GetDepth(), unlockedAffixIds.size(), recognizedAffixes);
}

bool ManastormAffixEngine::ForceStageAffix(
    ManastormRun& run,
    uint32 affixId,
    std::string& error)
{
    error.clear();

    ManastormAffixDefinition const* definition = GetDefinition(affixId);
    if (!definition)
    {
        error = "Unknown or unsupported Manastorm affix " + std::to_string(affixId) + ".";
        return false;
    }

    if (!ValidateDefinition(*definition, error))
        return false;

    if (RecoveredAffixMetadata const* metadata = GetRecoveredMetadata(affixId))
        if (!metadata->BoundedRuntime)
            LOG_WARN(LOG_FILTER,
                "Forcing recovered affix {} ({}) with an unresolved original runtime edge.",
                affixId, metadata->Name);

    run.AddStageAffix(affixId);
    return true;
}

bool ManastormAffixEngine::IsAffixHelperCreature(uint32 creatureEntry) const
{
    if (!creatureEntry)
        return false;

    for (RecoveredAffixMetadata const& metadata : RECOVERED_AFFIXES)
        if (metadata.HelperCreatureEntry1 == creatureEntry ||
            metadata.HelperCreatureEntry2 == creatureEntry)
            return true;

    return false;
}

bool ManastormAffixEngine::IsEligibleStageCreature(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!creature || creature->IsTrigger() || creature->IsPet() ||
        IsAffixHelperCreature(creature->GetEntry()) ||
        IsPlayerControlledCreature(creature))
        return false;

    if (!run.IsStageCreature(creature->GetGUID()))
        return false;

    ObjectGuid const objectiveGuid = run.GetObjectiveCreatureGuid();
    return objectiveGuid.IsEmpty() || creature->GetGUID() != objectiveGuid;
}

bool ManastormAffixEngine::IsEligibleForManaBomb(
    Creature const* creature,
    ManastormRun const& run) const
{
    if (!IsEligibleStageCreature(creature, run))
        return false;

    ObjectGuid::LowType const spawnId = creature->GetSpawnId();
    return spawnId && run.IsChaoticLinkSpawn(spawnId);
}

void ManastormAffixEngine::AssignActiveAffixes(
    Creature* creature,
    ManastormRun& run)
{
    if (!IsEligibleStageCreature(creature, run))
        return;

    for (uint32 affixId : run.GetActiveStageAffixIds())
    {
        ManastormAffixDefinition const* definition = GetDefinition(affixId);
        RecoveredAffixMetadata const* metadata = GetRecoveredMetadata(affixId);
        if (!definition || !metadata)
            continue;

        if (affixId == ManastormAffixIds::ManaBomb &&
            !IsEligibleForManaBomb(creature, run))
            continue;

        if (!run.AssignCreatureAffix(creature->GetGUID(), affixId))
            continue;

        if (metadata->ApplyMarkerAura &&
            definition->MarkerSpellId &&
            !creature->HasAura(definition->MarkerSpellId))
            creature->CastSpell(creature, definition->MarkerSpellId, true);
    }
}

void ManastormAffixEngine::OnCreatureAdded(Creature* creature, ManastormRun& run)
{
    if (!creature)
        return;

    if (IsAffixHelperCreature(creature->GetEntry()))
    {
        if (creature->IsSummon())
        {
            if (TempSummon* summon = creature->ToTempSummon())
                if (Unit* summoner = summon->GetSummonerUnit())
                    creature->SetFaction(summoner->GetFaction());
        }
        return;
    }

    AssignActiveAffixes(creature, run);
}

void ManastormAffixEngine::OnCreatureRemoved(Creature* creature, ManastormRun& run)
{
    if (!creature || IsAffixHelperCreature(creature->GetEntry()))
        return;

    run.ClearCreatureAffixes(creature->GetGUID());
}

void ManastormAffixEngine::OnCreatureDeath(Creature* creature, ManastormRun& run)
{
    if (!IsEligibleStageCreature(creature, run))
        return;

    std::unordered_set<uint32> const* affixes =
        run.GetCreatureAffixIds(creature->GetGUID());
    if (!affixes)
        return;

    for (uint32 affixId : *affixes)
    {
        ManastormAffixDefinition const* definition = GetDefinition(affixId);
        if (definition &&
            definition->RuntimeType == ManastormAffixRuntimeType::OnDeath)
            DispatchOnDeath(creature, run, affixId);
    }
}

void ManastormAffixEngine::DispatchOnDeath(
    Creature* creature,
    ManastormRun& run,
    uint32 affixId)
{
    if (!creature)
        return;

    if (affixId == ManastormAffixIds::ManaBomb)
    {
        StartManaBomb(creature, run);
        return;
    }

    RecoveredAffixMetadata const* metadata = GetRecoveredMetadata(affixId);
    if (!metadata)
        return;

    uint32 const triggers[] =
    {
        metadata->DeathTriggerSpellId,
        metadata->SecondaryDeathTriggerSpellId
    };

    for (uint32 spellId : triggers)
        if (spellId)
            creature->CastSpell(creature, spellId, true);
}

void ManastormAffixEngine::StartManaBomb(Creature* creature, ManastormRun& run)
{
    if (!creature)
        return;

    creature->CastSpell(creature, ManastormManaBomb::PrecastSpell, true);

    LOG_INFO(LOG_FILTER,
        "Manastorm Mana Bomb started: run={} depth={} creatureEntry={} "
        "creatureGuid={} spell={}.",
        run.GetRunId(), run.GetDepth(), creature->GetEntry(),
        creature->GetGUID().GetRawValue(), ManastormManaBomb::PrecastSpell);
}
