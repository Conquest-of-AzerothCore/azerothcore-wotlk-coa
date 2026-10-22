#ifndef MANASTORM_DEFINES_H
#define MANASTORM_DEFINES_H

#include "Define.h"
#include "ObjectGuid.h"

#include <string>
#include <string_view>
#include <vector>

enum class ManastormMode : uint8
{
    Solo = 1,
    Duo = 2,
    Trio = 3,
    Group = 4,
};

enum class ManastormRunState : uint8
{
    Created = 0,
    Preparing = 1,
    Active = 2,
    StageComplete = 3,
    Transitioning = 4,
    Failed = 5,
    Finished = 6,
    AwaitingExit = 7,
};

namespace ManastormBaseline
{
    // Temporary baseline Manastorm/Endless inventory tools.
    constexpr uint32 ItemPotion = 254041;
    constexpr uint32 ItemRegenerationMatrix = 97895;
    constexpr uint32 ItemMagicalEscape = 254042;

    // Item-cast spells recovered from shutdown-era Ascension itemcache.
    constexpr uint32 SpellPotion = 254440;
    constexpr uint32 SpellRegenerationMatrix = 93309;
    constexpr uint32 SpellMagicalEscape = 93311;

    // Periodic energy/rage regeneration triggered by the Potion.
    constexpr uint32 SpellPotionResourceRegen = 254462;

    // Endless Manastorm Potion (Rank 2) learned spell, usable only in the Manastorm.
    constexpr uint32 SpellPotionChargeSystem = 992090;

    // Recovered Manastorm Potion Charge System behavior.
    constexpr uint8 PotionMaxCharges = 3;
    constexpr uint32 PotionRechargeMs = 10000;
}

namespace ManastormResurrection
{
    // Recovered Manastorm stage resurrection resource pool.
    //
    // Each newly generated Manastorm level begins with five
    // shared resurrection resources.
    constexpr uint8 MaxCharges = 5;
}

namespace ManastormLimits
{
    // Recovered native Manastorm UI explicitly supports any composition
    // from solo through fifteen players. Solo/Duo/Trio remain distinct
    // progression modes; four through fifteen use Group mode.
    constexpr uint32 MaxMembers = 15;
}

namespace ManastormSegmentFlags
{
    // Segment is available even when the character owns
    // no progression unlock for it.
    constexpr uint32 StartingUnlocked = 0x00000001;
}

namespace ManastormModeBits
{
    constexpr uint8 Solo = 0x01;
    constexpr uint8 Duo = 0x02;
    constexpr uint8 Trio = 0x04;
    constexpr uint8 Group = 0x08;
    constexpr uint8 All = Solo | Duo | Trio | Group;
}

namespace ManastormTrackBits
{
    // Patch-M native stage tracks.
    constexpr uint8 Normal = 0x01;  // Manastorm.dbc difficulty 0
    constexpr uint8 Endgame = 0x02; // Manastorm.dbc difficulty 2
    constexpr uint8 All = Normal | Endgame;
}

inline uint8 ManastormGetTrackBit(bool endgame)
{
    return endgame
        ? ManastormTrackBits::Endgame
        : ManastormTrackBits::Normal;
}

inline uint8 ManastormGetModeBit(
    ManastormMode mode)
{
    switch (mode)
    {
    case ManastormMode::Solo:
        return ManastormModeBits::Solo;

    case ManastormMode::Duo:
        return ManastormModeBits::Duo;

    case ManastormMode::Trio:
        return ManastormModeBits::Trio;

    case ManastormMode::Group:
        return ManastormModeBits::Group;
    }

    return 0;
}

enum class ManastormUnlockKind : uint8
{
    // Existing Chapter-2 map/content flow:
    // complete trigger depth -> force NEXT introduction -> permanent grant.
    Introduction = 0,

    // Direct completion grant:
    // complete trigger depth -> permanent ownership immediately.
    //
    // Recovered ManastormMessages uses this wording for the 14 affixes:
    // "...affix in future Manastorms".
    Direct = 1,
};

enum class ManastormUnlockGrantType : uint8
{
    Segment = 1,

    // Reserved legacy/reconstruction slot.
    //
    // Recovered Ascension evidence ties objective bosses to authored
    // Manastorm segment families. Boss progression therefore uses Segment
    // grants; do not invent independent boss replacement from this value.
    BossPool = 2,

    // Permanent ownership of a server-authored creature-content pool.
    // Runtime replacement selection is intentionally separate and may remain
    // disabled until its original selection rules are recovered.
    CreaturePool = 3,

    Affix = 4,
};

namespace ManastormSegmentSpawnFlags
{
    // The persistent DB spawn belongs to the authored route for this segment.
    constexpr uint32 RouteCreature = 1u << 0;

    // Killing this exact persistent spawn may consume one Chaotic Link.
    constexpr uint32 ChaoticLinkEligible = 1u << 1;

    // This physical spawn slot may eventually receive a randomized creature.
    // The current runtime records this evidence but does not replace creatures.
    constexpr uint32 RandomizationSlot = 1u << 2;

    // The native creature occupying this slot may contribute to a creature
    // content pool sourced from this segment.
    constexpr uint32 CreaturePoolSource = 1u << 3;

    // This exact authored route spawn may receive creature-owned Manastorm
    // affixes.  Kept separate from ChaoticLinkEligible so the two systems can
    // evolve independently after the initial DB backfill.
    constexpr uint32 AffixEligible = 1u << 4;

    constexpr uint32 KnownMask =
        RouteCreature |
        ChaoticLinkEligible |
        RandomizationSlot |
        CreaturePoolSource |
        AffixEligible;
}

enum class ManastormAffixRuntimeType : uint8
{
    OnDeath = 1,
    Passive = 2,
    Periodic = 3,
    Environmental = 4,
    SpawnedHazard = 5,
};

enum class ManastormAffixAvailabilityKind : uint8
{
    // Eligible without character progression ownership.
    Baseline = 0,

    // Eligible only after the character owns the recovered affix unlock.
    ProgressionUnlock = 1,

    // Preserved/recovered definition that is not automatically selected.
    // Useful for legacy affixes such as Guardian until revision parity is
    // proven, while still allowing GM force-tests.
    ForcedOnly = 2,
};

namespace ManastormAffixTargetBits
{
    constexpr uint8 RouteCreature = 1u << 0;
    constexpr uint8 Boss = 1u << 1;
    constexpr uint8 Player = 1u << 2;
    constexpr uint8 Environment = 1u << 3;
    constexpr uint8 KnownMask =
        RouteCreature | Boss | Player | Environment;
}

namespace ManastormAffixIds
{
    //
    // Shared backend runtime IDs.
    //
    // These values match the recovered Chapter-2 unlock depths for a
    // stable reconstructed namespace. They are NOT claimed to be an
    // original native C_Manastorm protocol affix-ID field.
    //
    constexpr uint32 ManaBomb = 11;
    constexpr uint32 LightningRod = 13;
    constexpr uint32 Rampaging = 16;
    constexpr uint32 AethyricWinds = 19;
    constexpr uint32 ColdSnap = 21;
    constexpr uint32 TribalFury = 23;
    constexpr uint32 Vortex = 26;
    constexpr uint32 Stalwart = 28;
    constexpr uint32 Fungal = 31;
    constexpr uint32 WildMagics = 33;
    constexpr uint32 RunesOfPower = 39;
    constexpr uint32 Reflecting = 41;
    constexpr uint32 BoneStorm = 61;
    constexpr uint32 OverwhelmingEnergy = 101;

    // Non-checkpoint reconstructed IDs use the recovered root spell ID.
    // This keeps the namespace unique and directly traceable to Spell.dbc.
    constexpr uint32 Meteor = 93316;
    constexpr uint32 CreepingFrost = 93341;
    constexpr uint32 Leeching = 93344;
    constexpr uint32 Cleaving = 93352;
    constexpr uint32 UnrelentingSpeed = 93353;
    constexpr uint32 Juggernaut = 93359;
    constexpr uint32 ShardsOfMagic = 93403;
    constexpr uint32 ArmorPenetration = 93424;
    constexpr uint32 Evasive = 93510;
    constexpr uint32 Regenerative = 94755;
    constexpr uint32 Formidable = 94756;
    constexpr uint32 Hasty = 94757;
    constexpr uint32 Guardian = 2100261;
}

namespace ManastormManaBomb
{
    constexpr uint32 AffixId =
        ManastormAffixIds::ManaBomb;

    // Recovered Ascension Mana Bomb spell chain.
    constexpr uint32 MarkerSpell = 93363;
    constexpr uint32 PrecastSpell = 93364;
    constexpr uint32 EffectSpell = 93365;
    constexpr uint32 DispatcherSpell = 93488;
    constexpr uint32 DebuffSpell = 93489;

    // Recovered invisible Mana Bomb helper.
    constexpr uint32 HelperCreature = 663028;
}

struct ManastormAffixRankSpell
{
    uint8 Role = 0;
    uint8 Rank = 0;
    uint32 SpellId = 0;
};

struct ManastormAffixDefinition
{
    uint32 AffixId = 0;
    std::string Name;

    uint32 UnlockDepth = 0;

    ManastormAffixAvailabilityKind Availability =
        ManastormAffixAvailabilityKind::Baseline;

    uint8 TargetMask =
        ManastormAffixTargetBits::RouteCreature;

    ManastormAffixRuntimeType RuntimeType =
        ManastormAffixRuntimeType::Passive;

    uint32 MarkerSpellId = 0;
    uint32 DeathTriggerSpellId = 0;
    uint32 SecondaryDeathTriggerSpellId = 0;

    uint32 HelperCreatureEntry1 = 0;
    uint32 HelperCreatureEntry2 = 0;

    uint8 MaxRank = 0;
    bool ApplyMarkerAura = true;
    bool BoundedRuntime = false;
    bool AutomaticSelection = true;
    uint32 SelectionWeight = 100;

    uint32 NormalMessageId = 0;
    uint32 EndgameMessageId = 0;

    std::vector<ManastormAffixRankSpell> RankSpells;

    bool Targets(uint8 targetBit) const
    {
        return (TargetMask & targetBit) != 0;
    }

    uint32 GetRankSpell(uint8 role, uint8 rank) const
    {
        for (ManastormAffixRankSpell const& spell :
            RankSpells)
        {
            if (spell.Role == role &&
                spell.Rank == rank)
            {
                return spell.SpellId;
            }
        }

        return 0;
    }
};

struct ManastormAffixPolicy
{
    uint32 PolicyId = 0;
    uint32 MinDepth = 1;
    uint32 MaxDepth = 0; // 0 = no upper bound.

    uint8 CreatureStageAffixCount = 1;
    float CreatureAffixChancePct = 35.0f;
    float SecondAffixChancePct = 0.0f;
    float BossAffixChancePct = 0.0f;

    uint8 EnvironmentStageAffixCount = 0;
    uint8 DefaultRank = 1;

    bool Matches(uint32 depth) const
    {
        return depth >= MinDepth &&
            (!MaxDepth || depth <= MaxDepth);
    }
};

struct ManastormUnlockGrant
{
    ManastormUnlockGrantType Type =
        ManastormUnlockGrantType::Segment;

    uint32 ContentId = 0;
};

struct ManastormCreaturePoolDefinition
{
    uint32 PoolId = 0;
    std::string Name;

    // Authoritative content relationships. Pools reference source segments,
    // then derive candidate creature entries from those segments' authored
    // CreaturePoolSource spawn roles.
    std::vector<uint32> SourceSegmentIds;
    std::vector<uint32> CreatureEntries;
};

struct ManastormUnlockTrigger
{
    // Exact native track bit: 1=Normal, 2=Endgame.
    uint8 Track = 0;
    uint32 TriggerDepth = 0;
};

struct ManastormUnlockDefinition
{
    uint32 UnlockId = 0;

    ManastormUnlockKind Kind =
        ManastormUnlockKind::Introduction;

    // Completing this Endless depth either queues an introduction
    // or, for Direct unlocks, grants ownership immediately.
    uint32 TriggerDepth = 0;

    uint8 ModeMask =
        ManastormModeBits::All;

    // Legacy import compatibility. Runtime trigger authority is the exact
    // per-track Triggers vector loaded from manastorm_unlock_trigger.
    uint8 TrackMask =
        ManastormTrackBits::All;

    std::vector<ManastormUnlockTrigger> Triggers;

    uint32 GetTriggerDepthForTrack(uint8 trackBit) const
    {
        for (ManastormUnlockTrigger const& trigger :
            Triggers)
        {
            if (trigger.Track == trackBit)
                return trigger.TriggerDepth;
        }

        return 0;
    }

    // Forced NEXT-RUN / next-stage introductions.
    //
    // Patch-M carries separate difficulty-0 and difficulty-2
    // Manastorm stage identities. Permanent ownership is shared,
    // but the forced introduction must use the matching track.
    uint32 IntroSegmentId = 0;
    uint32 EndgameIntroSegmentId = 0;

    // Optional reconstructed Mode-1 presentation references only.
    // Native Mode 2 renders from ManastormMessages.dbc after 0x65E.
    uint32 IntroMessageId = 0;
    uint32 CompletionMessageId = 0;

    std::vector<ManastormUnlockGrant> Grants;
};

struct ManastormSegment
{
    uint32 SegmentId = 0;

    // Original Manastorm.dbc identity map. In native Mode 2 this must remain
    // byte-for-byte compatible with the client row even when the original
    // realm used a custom staging map that our server does not need.
    uint32 NativeMapId = 0;

    // Physical server map used for this stage. Defaults to NativeMapId when
    // manastorm_segment.runtime_map_id is 0.
    uint32 MapId = 0;

    // Native Patch-M Manastorm track identity.
    // 0 = Normal, 2 = Endgame. Do not use this directly as a WotLK
    // instance spawn mode.
    uint8 Difficulty = 0;

    // Physical AzerothCore instance difficulty/spawn mode. Ascension's
    // difficulty-2 Endgame track reuses the base WotLK dungeon population;
    // Manastorm supplies the Endgame progression/scaling layer itself.
    uint8 RuntimeDifficulty = 0;

    uint32 DungeonEncounterId = 0;

    // Original recovered objective identity from the imported/native segment
    // catalogue. Preserve it even when the physical AzerothCore source area
    // uses a different creature entry for the same encounter.
    uint32 NativeObjectiveCreatureEntry = 0;

    // Physical server creature entry used for runtime objective detection.
    // Defaults to NativeObjectiveCreatureEntry when
    // runtime_objective_creature_entry is 0.
    uint32 ObjectiveCreatureEntry = 0;

    uint32 StartGameTeleId = 0;
    uint32 Weight = 0;
    uint32 MinDepth = 1;
    uint32 MaxDepth = 0; // 0 = no upper bound.
    float RewardMultiplier = 1.0f;

    // Segment-authored Chaotic Link starting stack count.
    // This belongs to the dungeon/boss route, NOT the Endless depth.
    uint8 ChaoticLinkStacks = 0;

    // One authored segment roster powers several independent roles.
    //
    // These are persistent world-DB spawn GUIDs, NOT runtime creature GUIDs.
    // A fresh Endless instance receives new runtime GUIDs while
    // Creature::GetSpawnId() still resolves to these authored DB spawn IDs.
    std::vector<ObjectGuid::LowType> RouteSpawnIds;
    std::vector<ObjectGuid::LowType> ChaoticLinkSpawnIds;
    std::vector<ObjectGuid::LowType> RandomizationSpawnIds;
    std::vector<ObjectGuid::LowType> CreaturePoolSourceSpawnIds;
    std::vector<ObjectGuid::LowType> AffixEligibleSpawnIds;

    // Native Manastorm.dbc evidence carried with the selected segment in
    // native-client mode. These values are not used to invent gameplay.
    // Preserve the exact raw words as evidence as well as the recovered
    // float interpretations. w7 remains semantically unresolved.
    uint32 NativeWord4Raw = 0;
    uint32 NativeWord5Raw = 0;
    uint32 NativeWord6Raw = 0;
    uint32 NativeWord7Raw = 0;
    uint32 NativeWord8Raw = 0;

    float NativeRewardEndMultiplier = 1.0f;       // DBC w4
    float NativeRewardEncounterMultiplier = 1.0f; // DBC w5
    float NativeExperienceFactor1 = 1.0f;         // DBC w6
    float NativeUnknownW7 = 1.0f;                 // DBC w7, semantics unresolved
    float NativeExperienceFactor2 = 1.0f;         // DBC w8

    uint32 Flags = 0;
};

inline uint64 MakeManastormObjectiveKey(
    ManastormSegment const& segment)
{
    return (uint64(segment.NativeMapId) << 32) |
        uint64(segment.NativeObjectiveCreatureEntry);
}

struct ManastormScalingPoint
{
    uint32 Depth = 0;
    float HealthMultiplier = 1.0f;
    float GlobalDamageMultiplier = 1.0f;
    float MeleeMultiplier = 1.0f;
    float SpellMultiplier = 1.0f;
};

// Optional second scaling layer applied after the generic depth curve.
// Ranges make the authoring model flexible without inventing values:
//
//   1-15  = one generic group multiplier for every legal run size
//   1-1, 2-2, 3-3, 4-15 = Solo/Duo/Trio/Group buckets
//   1-1 ... 15-15 = exact per-player-count tuning if/when recovered
//
// Enabled ranges must not overlap.
struct ManastormGroupScalingRange
{
    uint8 MinMembers = 1;
    uint8 MaxMembers = 1;
    float HealthMultiplier = 1.0f;
    float GlobalDamageMultiplier = 1.0f;
    float MeleeMultiplier = 1.0f;
    float SpellMultiplier = 1.0f;

    bool Matches(uint32 memberCount) const
    {
        return memberCount >= MinMembers &&
            memberCount <= MaxMembers;
    }
};

inline ManastormMode ManastormModeForMemberCount(uint32 memberCount)
{
    if (memberCount <= 1)
        return ManastormMode::Solo;
    if (memberCount == 2)
        return ManastormMode::Duo;
    if (memberCount == 3)
        return ManastormMode::Trio;
    return ManastormMode::Group;
}

inline std::string_view ManastormModeName(ManastormMode mode)
{
    switch (mode)
    {
        case ManastormMode::Solo:  return "SOLO";
        case ManastormMode::Duo:   return "DUO";
        case ManastormMode::Trio:  return "TRIO";
        case ManastormMode::Group: return "GROUP";
    }

    return "UNKNOWN";
}

inline std::string_view ManastormRunStateName(ManastormRunState state)
{
    switch (state)
    {
    case ManastormRunState::Created:       return "CREATED";
    case ManastormRunState::Preparing:     return "PREPARING";
    case ManastormRunState::Active:        return "ACTIVE";
    case ManastormRunState::StageComplete: return "STAGE_COMPLETE";
    case ManastormRunState::Transitioning: return "TRANSITIONING";
    case ManastormRunState::Failed:        return "FAILED";
    case ManastormRunState::Finished:      return "FINISHED";
    }

    return "UNKNOWN";
}

#endif
