#include "ManastormVoiceOfMillhouse.h"

#include "ManastormDefines.h"
#include "ManastormRun.h"

#include "Creature.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "TemporarySummon.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <initializer_list>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    //
    // Recovered client identities.
    //
    // SoundEntries.dbc / SoundEntriesAdvanced.dbc prove these categories and
    // the sound\Manastorm WAV names. Exact original server random weights,
    // repeat rules and listener scope are not recovered, so this component
    // keeps those reconstruction choices local and explicit.
    //
    constexpr std::array<uint32, 6> INTRO_RECURRING =
    {{
        113141, // Manastorm_Intro_Accidents
        113143, // Manastorm_Intro_GenericWelcome
        113144, // Manastorm_Intro_GoodLuck
        113145, // Manastorm_Intro_GuideNotReally
        113146, // Manastorm_Intro_Unpredictable
        113147  // Manastorm_Intro_ZappedSquished
    }};

    constexpr uint32 INTRO_FIRST_TIME = 113142;

    constexpr std::array<uint32, 10> PLAYER_DEATH =
    {{
        113148, // AlreadyDead
        113149, // DidntWork
        113150, // LooksHurt
        113151, // NewStrategy
        113152, // NotEffective
        113153, // NotOut
        113154, // PowSorry
        113155, // StandInFire
        113156, // Stings
        113157  // WinningStrategy
    }};

    //
    // All eleven files are named Manastorm_BossKill_* in the recovered DBC.
    // Some are generic praise, some explicitly announce a portal, and two say
    // that portals are ready. Ascension's exact chooser is not recovered.
    //
    // We therefore make ONE selection per objective completion. Ready-lines
    // are delayed very slightly so the portal already exists when they play;
    // all other selected lines play during the completion event.
    //
    constexpr std::array<uint32, 11> OBJECTIVE_COMPLETE =
    {{
        113130, // 1PortalComingUp
        113131, // 1PortalComingUp_2
        113132, // CookinAudioPeak
        113133, // DownAndOut
        113134, // GenericPortalComingUp
        113135, // GenericPortalsReady
        113136, // GenericPortalsReady_2
        113137, // GreatJobTeam
        113138, // LooksEasy
        113139, // Unstoppable
        113140  // WhoseBad
    }};

    constexpr std::array<uint32, 3> VO_BFD =
        {{ 132955, 132956, 132957 }};
    constexpr std::array<uint32, 3> VO_BRD =
        {{ 132958, 132959, 132960 }};
    constexpr std::array<uint32, 3> VO_DEADMINES =
        {{ 132961, 132962, 132963 }};
    constexpr std::array<uint32, 3> VO_DIRE_MAUL =
        {{ 132964, 132965, 132966 }};
    constexpr std::array<uint32, 3> VO_EARTHSONG_FALLS =
        {{ 132967, 132968, 132969 }};
    constexpr std::array<uint32, 3> VO_FOULSPORE_CAVERN =
        {{ 132970, 132971, 132972 }};
    constexpr std::array<uint32, 2> VO_GNOMEREGAN =
        {{ 132973, 132974 }};
    constexpr std::array<uint32, 3> VO_LBRS =
        {{ 132975, 132976, 132977 }};
    constexpr std::array<uint32, 3> VO_RAZORFEN_KRAUL =
        {{ 132978, 132979, 132980 }};
    constexpr std::array<uint32, 3> VO_RAGEFIRE_CHASM =
        {{ 132981, 132982, 132983 }};
    constexpr std::array<uint32, 3> VO_RAZORFEN_DOWNS =
        {{ 132984, 132985, 132986 }};
    constexpr std::array<uint32, 3> VO_SCARLET_ARMORY =
        {{ 132987, 132988, 132989 }};
    constexpr std::array<uint32, 3> VO_SCARLET_CATHEDRAL =
        {{ 132990, 132991, 132992 }};
    constexpr std::array<uint32, 3> VO_SCARLET_GRAVEYARD =
        {{ 132993, 132994, 132995 }};
    constexpr std::array<uint32, 3> VO_SCARLET_LIBRARY =
        {{ 132996, 132997, 132998 }};
    constexpr std::array<uint32, 3> VO_SCHOLOMANCE =
        {{ 132999, 133000, 133001 }};
    constexpr std::array<uint32, 3> VO_SHADOWFANG_KEEP =
        {{ 133002, 133003, 133004 }};
    constexpr std::array<uint32, 3> VO_STOCKADES =
        {{ 133005, 133006, 133007 }};
    constexpr std::array<uint32, 2> VO_STRATHOLME =
        {{ 133008, 133009 }};
    constexpr std::array<uint32, 3> VO_UBRS =
        {{ 133010, 133011, 133012 }};
    constexpr std::array<uint32, 3> VO_ULDAMAN =
        {{ 133013, 133014, 133015 }};
    constexpr std::array<uint32, 3> VO_WAILING_CAVERNS =
        {{ 133016, 133017, 133018 }};
    constexpr std::array<uint32, 3> VO_WICKED_GROTTO =
        {{ 133019, 133020, 133021 }};
    constexpr std::array<uint32, 3> VO_ZULFARRAK =
        {{ 133022, 133023, 133024 }};

    // Keep an emitter alive long enough for the client to finish any recovered
    // dialogue file after SMSG_PLAY_OBJECT_SOUND is sent.
    constexpr uint32 EMITTER_LIFETIME_MS = 30000;

    // PREPARING happens immediately after a private-instance teleport. Give
    // the client a short window to receive the private 80911 create/update
    // before SMSG_PLAY_OBJECT_SOUND references that emitter GUID.
    constexpr uint32 INTRO_EMITTER_SETTLE_MS = 500;

    // Dungeon/location commentary belongs to ACTIVE, after protection falls.
    // The global Intro_* line has already been delivered in PREPARING, so no
    // long first-stage suppression is required here.
    constexpr uint32 STAGE_DUNGEON_DELAY_MS = 500;

    // Avoid a wipe generating several overlapping death jokes in one instant.
    // This is reconstruction safety, not a claimed original Ascension value.
    constexpr uint32 PLAYER_DEATH_COOLDOWN_MS = 5000;

    // Small silence between clips keeps back-to-back narration intelligible.
    constexpr uint32 VOICE_GAP_MS = 250;

    enum class DungeonVoiceGroup : uint8
    {
        None = 0,
        BlackfathomDeeps,
        BlackrockDepths,
        Deadmines,
        DireMaul,
        EarthsongFalls,
        FoulsporeCavern,
        Gnomeregan,
        LowerBlackrockSpire,
        RazorfenKraul,
        RagefireChasm,
        RazorfenDowns,
        ScarletArmory,
        ScarletCathedral,
        ScarletGraveyard,
        ScarletLibrary,
        Scholomance,
        ShadowfangKeep,
        Stockades,
        Stratholme,
        UpperBlackrockSpire,
        Uldaman,
        WailingCaverns,
        WickedGrotto,
        ZulFarrak
    };

    enum class VoiceKind : uint8
    {
        None = 0,
        Dungeon,
        Intro,
        PlayerDeath,
        ObjectiveComplete
    };

    struct SoundPool
    {
        uint32 const* Data = nullptr;
        std::size_t Size = 0;
    };

    struct RunVoiceState
    {
        bool FirstManastorm = false;
        bool FirstStageActivated = false;

        // One run-level intro is selected, then delivered independently when
        // each member actually arrives inside the protected start area.
        uint32 IntroSound = 0;
        std::unordered_set<ObjectGuid::LowType>
            IntroDeliveredMembers;

        uint32 LastIntroSound = 0;
        uint32 LastDeathSound = 0;
        uint32 LastCompletionSound = 0;
        uint32 LastDungeonSound = 0;

        uint32 DeathCooldownMs = 0;

        // Lightweight narrator scheduler. BusyMs uses the real duration of
        // the currently playing recovered clip plus a small inter-line gap.
        uint32 BusyMs = 0;
        VoiceKind CurrentKind = VoiceKind::None;
        uint32 CurrentSoundId = 0;

        // Per-dungeon shuffle bags. A line is inserted only after successful
        // playback. This lets consecutive segments in the same dungeon use
        // the rest of that dungeon's commentary before recycling.
        std::unordered_map<uint32, std::unordered_set<uint32>>
            UsedDungeonSounds;
    };

    struct PendingVoice
    {
        uint64 RunId = 0;
        uint32 DelayMs = 0;
        uint32 MapId = 0;
        uint32 InstanceId = 0;
        uint32 SoundId = 0;

        VoiceKind Kind = VoiceKind::None;
        uint8 Priority = 0;
        uint64 Sequence = 0;

        DungeonVoiceGroup DungeonGroup =
            DungeonVoiceGroup::None;

        // Death/completion narration is run-level commentary. If it waits in
        // the scheduler while the party crosses a portal, follow the members
        // into their current stage rather than dropping an otherwise-valid
        // line because its original map/instance no longer matches.
        bool FollowMemberPosition = false;

        // Empty for normal ACTIVE/death/completion playback. PREPARING intro
        // uses an already-spawned private emitter so its GUID is known to the
        // client before the sound packet is sent.
        ObjectGuid PreparedEmitterGuid;

        std::vector<ObjectGuid::LowType>
            Members;
    };

    std::unordered_map<uint64, RunVoiceState>
        RunStates;

    std::vector<PendingVoice>
        PendingVoices;

    uint64 NextVoiceSequence = 1;

    template <std::size_t N>
    SoundPool MakePool(
        std::array<uint32, N> const& sounds)
    {
        return
        {
            sounds.data(),
            sounds.size()
        };
    }

    bool IsOneOf(
        uint32 value,
        std::initializer_list<uint32> values)
    {
        for (uint32 candidate : values)
        {
            if (value == candidate)
                return true;
        }

        return false;
    }

    DungeonVoiceGroup ResolveDungeonVoiceGroup(
        ManastormSegment const& segment)
    {
        //
        // Resolve from the native Manastorm identity, not the physical
        // runtime map override. This keeps VO correct for open-world staging
        // and for segments whose runtime_map_id differs from Manastorm.dbc.
        //
        switch (segment.NativeMapId)
        {
        case 33:
            return DungeonVoiceGroup::ShadowfangKeep;

        case 34:
            return DungeonVoiceGroup::Stockades;

        case 36:
            return DungeonVoiceGroup::Deadmines;

        case 43:
            return DungeonVoiceGroup::WailingCaverns;

        case 47:
            return DungeonVoiceGroup::RazorfenKraul;

        case 48:
            return DungeonVoiceGroup::BlackfathomDeeps;

        case 70:
            return DungeonVoiceGroup::Uldaman;

        case 90:
            return DungeonVoiceGroup::Gnomeregan;

        case 129:
            return DungeonVoiceGroup::RazorfenDowns;

        case 209:
            return DungeonVoiceGroup::ZulFarrak;

        case 230:
            return DungeonVoiceGroup::BlackrockDepths;

        case 289:
            return DungeonVoiceGroup::Scholomance;

        case 329:
            return DungeonVoiceGroup::Stratholme;

        case 389:
            return DungeonVoiceGroup::RagefireChasm;

        case 429:
            return DungeonVoiceGroup::DireMaul;

        case 189:
        {
            //
            // Scarlet Monastery is one physical map with four recovered
            // narrator families. DungeonEncounter identity disambiguates it.
            //
            switch (segment.DungeonEncounterId)
            {
            case 445:
            case 2445:
                return DungeonVoiceGroup::ScarletGraveyard;

            case 446:
            case 2446:
            case 447:
            case 2447:
                return DungeonVoiceGroup::ScarletLibrary;

            case 448:
            case 2448:
                return DungeonVoiceGroup::ScarletArmory;

            case 450:
            case 2450:
                return DungeonVoiceGroup::ScarletCathedral;

            default:
                return DungeonVoiceGroup::None;
            }
        }

        case 229:
        {
            //
            // Lower and Upper Blackrock Spire share map 229.
            // Current native Manastorm.dbc uses these encounters for UBRS;
            // all other authored map-229 rows belong to the LBRS family.
            //
            if (IsOneOf(
                segment.DungeonEncounterId,
                {
                    276, 277, 278, 279, 280,
                    2276, 2277, 2278, 2279, 2280
                }))
            {
                return DungeonVoiceGroup::UpperBlackrockSpire;
            }

            return DungeonVoiceGroup::LowerBlackrockSpire;
        }

        case 349:
        {
            //
            // Maraudon's three recovered VO families correspond to its three
            // wings. Resolve by native encounter so the shared map never
            // causes an orange/purple/inner line to be mixed.
            //
            if (IsOneOf(
                segment.DungeonEncounterId,
                {
                    422, 423,
                    2422, 2423
                }))
            {
                return DungeonVoiceGroup::FoulsporeCavern;
            }

            if (IsOneOf(
                segment.DungeonEncounterId,
                {
                    424, 425, 427, 9997,
                    2424, 2425, 2427, 2621
                }))
            {
                return DungeonVoiceGroup::WickedGrotto;
            }

            if (IsOneOf(
                segment.DungeonEncounterId,
                {
                    426, 429,
                    2426, 2429
                }))
            {
                return DungeonVoiceGroup::EarthsongFalls;
            }

            return DungeonVoiceGroup::None;
        }

        default:
            return DungeonVoiceGroup::None;
        }
    }

    SoundPool GetDungeonPool(
        ManastormSegment const& segment)
    {
        switch (ResolveDungeonVoiceGroup(segment))
        {
        case DungeonVoiceGroup::BlackfathomDeeps:
            return MakePool(VO_BFD);
        case DungeonVoiceGroup::BlackrockDepths:
            return MakePool(VO_BRD);
        case DungeonVoiceGroup::Deadmines:
            return MakePool(VO_DEADMINES);
        case DungeonVoiceGroup::DireMaul:
            return MakePool(VO_DIRE_MAUL);
        case DungeonVoiceGroup::EarthsongFalls:
            return MakePool(VO_EARTHSONG_FALLS);
        case DungeonVoiceGroup::FoulsporeCavern:
            return MakePool(VO_FOULSPORE_CAVERN);
        case DungeonVoiceGroup::Gnomeregan:
            return MakePool(VO_GNOMEREGAN);
        case DungeonVoiceGroup::LowerBlackrockSpire:
            return MakePool(VO_LBRS);
        case DungeonVoiceGroup::RazorfenKraul:
            return MakePool(VO_RAZORFEN_KRAUL);
        case DungeonVoiceGroup::RagefireChasm:
            return MakePool(VO_RAGEFIRE_CHASM);
        case DungeonVoiceGroup::RazorfenDowns:
            return MakePool(VO_RAZORFEN_DOWNS);
        case DungeonVoiceGroup::ScarletArmory:
            return MakePool(VO_SCARLET_ARMORY);
        case DungeonVoiceGroup::ScarletCathedral:
            return MakePool(VO_SCARLET_CATHEDRAL);
        case DungeonVoiceGroup::ScarletGraveyard:
            return MakePool(VO_SCARLET_GRAVEYARD);
        case DungeonVoiceGroup::ScarletLibrary:
            return MakePool(VO_SCARLET_LIBRARY);
        case DungeonVoiceGroup::Scholomance:
            return MakePool(VO_SCHOLOMANCE);
        case DungeonVoiceGroup::ShadowfangKeep:
            return MakePool(VO_SHADOWFANG_KEEP);
        case DungeonVoiceGroup::Stockades:
            return MakePool(VO_STOCKADES);
        case DungeonVoiceGroup::Stratholme:
            return MakePool(VO_STRATHOLME);
        case DungeonVoiceGroup::UpperBlackrockSpire:
            return MakePool(VO_UBRS);
        case DungeonVoiceGroup::Uldaman:
            return MakePool(VO_ULDAMAN);
        case DungeonVoiceGroup::WailingCaverns:
            return MakePool(VO_WAILING_CAVERNS);
        case DungeonVoiceGroup::WickedGrotto:
            return MakePool(VO_WICKED_GROTTO);
        case DungeonVoiceGroup::ZulFarrak:
            return MakePool(VO_ZULFARRAK);
        case DungeonVoiceGroup::None:
            break;
        }

        return {};
    }

    uint32 GetSoundDurationMs(
        uint32 soundId)
    {
        //
        // Measured from the 115-file Manastorm voice archive supplied by the
        // project owner. The MP3s preserve the original WAV filenames. These
        // values let the scheduler avoid guessing how long Millhouse speaks.
        //
        switch (soundId)
        {
        case 113130: return 2904;
        case 113131: return 4176;
        case 113132: return 1632;
        case 113133: return 2496;
        case 113134: return 1128;
        case 113135: return 1152;
        case 113136: return 1944;
        case 113137: return 3816;
        case 113138: return 1968;
        case 113139: return 2976;
        case 113140: return 3960;
        case 113141: return 7872;
        case 113142: return 15168;
        case 113143: return 2880;
        case 113144: return 5184;
        case 113145: return 7728;
        case 113146: return 4920;
        case 113147: return 6600;
        case 113148: return 2784;
        case 113149: return 2616;
        case 113150: return 2136;
        case 113151: return 3408;
        case 113152: return 2400;
        case 113153: return 2664;
        case 113154: return 2520;
        case 113155: return 3120;
        case 113156: return 1608;
        case 113157: return 3648;
        case 132955: return 9288;
        case 132956: return 6480;
        case 132957: return 6024;
        case 132958: return 9720;
        case 132959: return 7464;
        case 132960: return 8208;
        case 132961: return 5232;
        case 132962: return 8256;
        case 132963: return 5208;
        case 132964: return 6192;
        case 132965: return 6528;
        case 132966: return 6192;
        case 132967: return 4128;
        case 132968: return 5592;
        case 132969: return 5352;
        case 132970: return 6024;
        case 132971: return 5328;
        case 132972: return 6264;
        case 132973: return 5616;
        case 132974: return 4608;
        case 132975: return 7800;
        case 132976: return 11688;
        case 132977: return 5040;
        case 132978: return 6384;
        case 132979: return 6672;
        case 132980: return 6144;
        case 132981: return 7656;
        case 132982: return 5448;
        case 132983: return 6648;
        case 132984: return 7560;
        case 132985: return 6624;
        case 132986: return 5040;
        case 132987: return 6744;
        case 132988: return 7392;
        case 132989: return 4440;
        case 132990: return 4464;
        case 132991: return 6360;
        case 132992: return 3624;
        case 132993: return 4680;
        case 132994: return 6648;
        case 132995: return 8592;
        case 132996: return 5736;
        case 132997: return 5568;
        case 132998: return 6120;
        case 132999: return 6576;
        case 133000: return 5544;
        case 133001: return 7032;
        case 133002: return 5760;
        case 133003: return 6192;
        case 133004: return 8448;
        case 133005: return 4392;
        case 133006: return 7800;
        case 133007: return 3936;
        case 133008: return 6504;
        case 133009: return 5784;
        case 133010: return 6048;
        case 133011: return 4752;
        case 133012: return 10944;
        case 133013: return 5376;
        case 133014: return 7752;
        case 133015: return 10680;
        case 133016: return 2952;
        case 133017: return 4152;
        case 133018: return 4776;
        case 133019: return 5592;
        case 133020: return 7512;
        case 133021: return 10728;
        case 133022: return 7992;
        case 133023: return 6120;
        case 133024: return 6288;
        default:
            return 4000;
        }
    }

    uint8 GetVoicePriority(
        VoiceKind kind)
    {
        switch (kind)
        {
        case VoiceKind::ObjectiveComplete:
            return 40;
        case VoiceKind::PlayerDeath:
            return 30;
        case VoiceKind::Intro:
            return 20;
        case VoiceKind::Dungeon:
            return 10;
        case VoiceKind::None:
            break;
        }

        return 0;
    }

    bool HasPendingDungeonSound(
        uint64 runId,
        uint32 soundId)
    {
        for (PendingVoice const& voice :
            PendingVoices)
        {
            if (voice.RunId == runId &&
                voice.Kind == VoiceKind::Dungeon &&
                voice.SoundId == soundId)
            {
                return true;
            }
        }

        return false;
    }

    void DropStaleLowerPriorityVoices(
        uint64 runId,
        VoiceKind incomingKind)
    {
        PendingVoices.erase(
            std::remove_if(
                PendingVoices.begin(),
                PendingVoices.end(),
                [runId, incomingKind](PendingVoice const& voice)
                {
                    if (voice.RunId != runId)
                        return false;

                    if (incomingKind == VoiceKind::PlayerDeath)
                    {
                        return voice.Kind == VoiceKind::Dungeon;
                    }

                    if (incomingKind ==
                        VoiceKind::ObjectiveComplete)
                    {
                        return
                            voice.Kind == VoiceKind::Dungeon ||
                            voice.Kind == VoiceKind::PlayerDeath;
                    }

                    return false;
                }),
            PendingVoices.end());
    }

    SoundPool GetEncounterSpecificPool(
        ManastormSegment const& segment)
    {
        //
        // Exact per-encounter trigger assignments are intentionally evidence-
        // gated. Several recovered filenames strongly suggest boss references,
        // but filename semantics alone are not enough to claim an original
        // Ascension trigger. Populate this resolver only when transcript/server
        // data proves a specific encounter/segment mapping.
        //
        // The selection path already prefers this pool over the broader dungeon
        // pool, so proven overrides can be added without changing scheduler
        // behavior later.
        //
        (void)segment;
        return {};
    }

    uint32 PickDungeonSound(
        SoundPool pool,
        std::unordered_set<uint32>& used,
        uint32 previousSound,
        uint64 runId)
    {
        if (!pool.Data || !pool.Size)
            return 0;

        std::vector<uint32> candidates;
        candidates.reserve(pool.Size);

        auto collect =
            [&](bool allowPrevious)
            {
                candidates.clear();

                for (std::size_t index = 0;
                    index < pool.Size;
                    ++index)
                {
                    uint32 const soundId =
                        pool.Data[index];

                    if (used.find(soundId) !=
                            used.end() ||
                        HasPendingDungeonSound(
                            runId,
                            soundId))
                    {
                        continue;
                    }

                    if (!allowPrevious &&
                        pool.Size > 1 &&
                        soundId == previousSound)
                    {
                        continue;
                    }

                    candidates.push_back(
                        soundId);
                }
            };

        //
        // First pass: unheard lines only, and avoid the immediately previous
        // line whenever the pool has alternatives.
        //
        collect(false);

        if (candidates.empty())
        {
            //
            // The dungeon's authored pool is exhausted. Reset only entries
            // belonging to this pool, then begin another cycle. Pending lines
            // remain excluded so two copies cannot queue at once.
            //
            for (std::size_t index = 0;
                index < pool.Size;
                ++index)
            {
                used.erase(
                    pool.Data[index]);
            }

            collect(false);
        }

        if (candidates.empty())
        {
            //
            // A one-line pool may legitimately need to repeat after it has
            // finished, but never enqueue another copy while one is pending.
            //
            collect(true);
        }

        if (candidates.empty())
            return 0;

        return candidates[
            urand(
                0,
                uint32(
                    candidates.size() - 1))];
    }

    uint32 PickSound(
        SoundPool pool,
        uint32 previousSound)
    {
        if (!pool.Data || !pool.Size)
            return 0;

        std::size_t index =
            urand(
                0,
                uint32(pool.Size - 1));

        if (pool.Size > 1 &&
            pool.Data[index] == previousSound)
        {
            index =
                (index + 1) %
                pool.Size;
        }

        return pool.Data[index];
    }

    template <std::size_t N>
    uint32 PickSound(
        std::array<uint32, N> const& pool,
        uint32 previousSound)
    {
        return PickSound(
            MakePool(pool),
            previousSound);
    }

    PendingVoice BuildVoice(
        ManastormRun const& run,
        uint32 soundId,
        uint32 delayMs,
        VoiceKind kind,
        DungeonVoiceGroup dungeonGroup =
            DungeonVoiceGroup::None)
    {
        PendingVoice voice;

        voice.RunId =
            run.GetRunId();

        voice.DelayMs =
            delayMs;

        voice.MapId =
            run.GetSegment().MapId;

        voice.InstanceId =
            run.GetInstanceId();

        voice.SoundId =
            soundId;

        voice.Kind =
            kind;

        voice.Priority =
            GetVoicePriority(
                kind);

        voice.Sequence =
            NextVoiceSequence++;

        voice.DungeonGroup =
            dungeonGroup;

        voice.FollowMemberPosition =
            kind == VoiceKind::PlayerDeath ||
            kind == VoiceKind::ObjectiveComplete;

        voice.Members =
            run.GetMembers();

        return voice;
    }

    bool IsMemberReadyForVoice(
        Player* member,
        PendingVoice const& voice)
    {
        if (!member ||
            !member->GetSession() ||
            !member->IsInWorld() ||
            member->IsBeingTeleported())
        {
            return false;
        }

        if (voice.FollowMemberPosition)
            return true;

        return
            member->GetMapId() == voice.MapId &&
            member->GetInstanceId() == voice.InstanceId;
    }

    TempSummon* CreateEmitterForMember(
        Player* member,
        PendingVoice const& voice)
    {
        if (!IsMemberReadyForVoice(
                member,
                voice))
        {
            return nullptr;
        }

        TempSummon* emitter =
            member->SummonCreature(
                ManastormVoiceOfMillhouse::
                    EmitterCreatureEntry,
                member->GetPosition(),
                TEMPSUMMON_TIMED_DESPAWN,
                EMITTER_LIFETIME_MS,
                0,
                nullptr,
                true);

        if (!emitter)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Voice of Millhouse could not summon emitter {} "
                "for player {} sound={} map={} instance={}.",
                ManastormVoiceOfMillhouse::
                    EmitterCreatureEntry,
                member->GetGUID().GetCounter(),
                voice.SoundId,
                voice.MapId,
                voice.InstanceId);

            return nullptr;
        }

        emitter->SetFaction(35);
        emitter->SetReactState(
            REACT_PASSIVE);

        emitter->SetUnitFlag(
            UNIT_FLAG_NON_ATTACKABLE |
            UNIT_FLAG_NOT_SELECTABLE |
            UNIT_FLAG_IMMUNE_TO_PC |
            UNIT_FLAG_IMMUNE_TO_NPC);

        //
        // The shutdown-era cache records display 10045. That display is not
        // inherently invisible, so server-side presentation makes the helper
        // effectively invisible while retaining the recovered client model.
        //
        emitter->SetObjectScale(
            0.01f);

        return emitter;
    }

    bool PlayForMember(
        Player* member,
        PendingVoice const& voice)
    {
        if (!IsMemberReadyForVoice(
                member,
                voice))
        {
            return false;
        }

        Creature* emitter = nullptr;

        if (!voice.PreparedEmitterGuid.IsEmpty())
        {
            emitter =
                ObjectAccessor::GetCreature(
                    *member,
                    voice.PreparedEmitterGuid);

            if (!emitter ||
                !emitter->IsInWorld())
            {
                LOG_DEBUG(
                    LOG_FILTER,
                    "Voice of Millhouse prepared emitter {} was not "
                    "available for run={} player={} sound={}.",
                    voice.PreparedEmitterGuid.GetRawValue(),
                    voice.RunId,
                    member->GetGUID().GetCounter(),
                    voice.SoundId);

                return false;
            }
        }
        else
        {
            emitter =
                CreateEmitterForMember(
                    member,
                    voice);

            if (!emitter)
                return false;
        }

        emitter->PlayDistanceSound(
            voice.SoundId,
            member);

        LOG_DEBUG(
            LOG_FILTER,
            "Voice of Millhouse played sound {} through emitter guid={} "
            "for run={} player={} map={} instance={}.",
            voice.SoundId,
            emitter->GetGUID().GetRawValue(),
            voice.RunId,
            member->GetGUID().GetCounter(),
            voice.MapId,
            voice.InstanceId);

        return true;
    }

    bool PlayVoice(
        PendingVoice const& voice)
    {
        if (!voice.SoundId)
            return false;

        bool played = false;

        for (ObjectGuid::LowType memberGuid :
            voice.Members)
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            memberGuid));

            played =
                PlayForMember(
                    member,
                    voice) ||
                played;
        }

        return played;
    }

    void QueueVoice(
        ManastormRun const& run,
        uint32 soundId,
        uint32 delayMs,
        VoiceKind kind,
        DungeonVoiceGroup dungeonGroup =
            DungeonVoiceGroup::None)
    {
        if (!soundId)
            return;

        DropStaleLowerPriorityVoices(
            run.GetRunId(),
            kind);

        PendingVoices.push_back(
            BuildVoice(
                run,
                soundId,
                delayMs,
                kind,
                dungeonGroup));
    }
}

namespace ManastormVoiceOfMillhouse
{
    void RegisterRun(
        uint64 runId,
        bool firstManastorm)
    {
        if (!runId)
            return;

        RunVoiceState& state =
            RunStates[runId];

        state =
            RunVoiceState{};

        state.FirstManastorm =
            firstManastorm;
    }

    void ClearRun(
        uint64 runId)
    {
        RunStates.erase(
            runId);

        PendingVoices.erase(
            std::remove_if(
                PendingVoices.begin(),
                PendingVoices.end(),
                [runId](PendingVoice const& voice)
                {
                    return voice.RunId == runId;
                }),
            PendingVoices.end());
    }

    void Update(
        uint32 diff)
    {
        //
        // First age all timers. Pending event delays are independent from the
        // narrator busy timer so a location line can become ready while an
        // intro is still speaking, then wait without overlapping it.
        //
        for (PendingVoice& voice :
            PendingVoices)
        {
            if (voice.DelayMs <= diff)
                voice.DelayMs = 0;
            else
                voice.DelayMs -= diff;
        }

        for (auto& pair :
            RunStates)
        {
            RunVoiceState& state =
                pair.second;

            if (state.DeathCooldownMs <= diff)
                state.DeathCooldownMs = 0;
            else
                state.DeathCooldownMs -= diff;

            if (state.BusyMs <= diff)
            {
                state.BusyMs = 0;
                state.CurrentKind =
                    VoiceKind::None;
                state.CurrentSoundId = 0;
            }
            else
            {
                state.BusyMs -= diff;
            }
        }

        //
        // A party member can finish loading slightly later than another. If
        // Millhouse is already playing this run's exact same Intro_* line,
        // allow that same line to begin for the late listener as well. This is
        // not audible overlap for either player, and BusyMs is extended so no
        // other narration starts until the last listener's intro finishes.
        //
        for (auto itr =
            PendingVoices.begin();
            itr != PendingVoices.end();)
        {
            auto stateItr =
                RunStates.find(
                    itr->RunId);

            if (stateItr ==
                    RunStates.end())
            {
                itr =
                    PendingVoices.erase(
                        itr);

                continue;
            }

            RunVoiceState& state =
                stateItr->second;

            if (itr->DelayMs ||
                itr->Kind != VoiceKind::Intro ||
                !state.BusyMs ||
                state.CurrentKind !=
                    VoiceKind::Intro ||
                state.CurrentSoundId !=
                    itr->SoundId)
            {
                ++itr;
                continue;
            }

            PendingVoice voice =
                std::move(*itr);

            itr =
                PendingVoices.erase(
                    itr);

            if (!PlayVoice(
                    voice))
            {
                continue;
            }

            state.BusyMs =
                std::max(
                    state.BusyMs,
                    GetSoundDurationMs(
                        voice.SoundId) +
                    VOICE_GAP_MS);
        }

        //
        // Each run owns one narrator channel. When that channel is free, pick
        // the highest-priority ready event; ties preserve enqueue order.
        //
        for (auto& pair :
            RunStates)
        {
            uint64 const runId =
                pair.first;

            RunVoiceState& state =
                pair.second;

            if (state.BusyMs)
                continue;

            auto best =
                PendingVoices.end();

            for (auto itr =
                PendingVoices.begin();
                itr != PendingVoices.end();
                ++itr)
            {
                if (itr->RunId != runId ||
                    itr->DelayMs)
                {
                    continue;
                }

                if (best ==
                        PendingVoices.end() ||
                    itr->Priority >
                        best->Priority ||
                    (itr->Priority ==
                        best->Priority &&
                     itr->Sequence <
                        best->Sequence))
                {
                    best = itr;
                }
            }

            if (best ==
                PendingVoices.end())
            {
                continue;
            }

            PendingVoice voice =
                std::move(*best);

            PendingVoices.erase(
                best);

            if (!PlayVoice(
                    voice))
            {
                continue;
            }

            state.BusyMs =
                GetSoundDurationMs(
                    voice.SoundId) +
                VOICE_GAP_MS;

            state.CurrentKind =
                voice.Kind;

            state.CurrentSoundId =
                voice.SoundId;

            if (voice.Kind ==
                    VoiceKind::Dungeon)
            {
                state.UsedDungeonSounds[
                    uint32(
                        voice.DungeonGroup)]
                    .insert(
                        voice.SoundId);
            }

            LOG_DEBUG(
                LOG_FILTER,
                "Voice of Millhouse scheduler started sound {} "
                "kind={} priority={} run={} busyMs={}.",
                voice.SoundId,
                uint32(voice.Kind),
                uint32(voice.Priority),
                voice.RunId,
                state.BusyMs);
        }
    }

    void OnPlayerEnteredProtection(
        ManastormRun const& run,
        Player* player)
    {
        if (!player ||
            run.GetState() !=
                ManastormRunState::Preparing)
        {
            return;
        }

        RunVoiceState& state =
            RunStates[
                run.GetRunId()];

        ObjectGuid::LowType const playerGuid =
            player->GetGUID().GetCounter();

        if (state.IntroDeliveredMembers.find(
                playerGuid) !=
            state.IntroDeliveredMembers.end())
        {
            return;
        }

        //
        // Select the run-level introduction once. Every party member hears the
        // same recovered line when that member actually arrives in the safety
        // bubble, rather than the first arrival causing absent/transferring
        // members to miss it.
        //
        if (!state.IntroSound)
        {
            state.IntroSound =
                state.FirstManastorm
                ? INTRO_FIRST_TIME
                : PickSound(
                    INTRO_RECURRING,
                    state.LastIntroSound);

            state.LastIntroSound =
                state.IntroSound;
        }

        PendingVoice voice =
            BuildVoice(
                run,
                state.IntroSound,
                INTRO_EMITTER_SETTLE_MS,
                VoiceKind::Intro);

        //
        // This event belongs only to the arriving member. Spawn 80911 now,
        // while the player is safely inside PREPARING, then wait briefly
        // before sending the object-bound sound from that exact creature GUID.
        //
        voice.Members.clear();
        voice.Members.push_back(
            playerGuid);

        TempSummon* emitter =
            CreateEmitterForMember(
                player,
                voice);

        if (!emitter)
            return;

        voice.PreparedEmitterGuid =
            emitter->GetGUID();

        PendingVoices.push_back(
            std::move(voice));

        // Mark once the emitter was successfully created/queued. The manager
        // retries this hook while PREPARING, so marking here prevents duplicate
        // private emitters during the 500ms client-settle window.
        state.IntroDeliveredMembers.insert(
            playerGuid);

        LOG_DEBUG(
            LOG_FILTER,
            "Voice of Millhouse queued PREPARING intro sound {} "
            "through pre-spawned emitter guid={} for run={} player={}.",
            state.IntroSound,
            emitter->GetGUID().GetRawValue(),
            run.GetRunId(),
            playerGuid);
    }

    void OnStageActivated(
        ManastormRun const& run)
    {
        RunVoiceState& state =
            RunStates[
                run.GetRunId()];

        state.FirstStageActivated =
            true;

        //
        // The global Intro_* family is intentionally NOT played here anymore.
        // It belongs to PREPARING / safety-bubble arrival. ACTIVE owns only
        // dungeon/location commentary plus later combat/completion events.
        //
        DungeonVoiceGroup const dungeonGroup =
            ResolveDungeonVoiceGroup(
                run.GetSegment());

        if (dungeonGroup ==
            DungeonVoiceGroup::None)
        {
            return;
        }

        SoundPool commentaryPool =
            GetEncounterSpecificPool(
                run.GetSegment());

        if (!commentaryPool.Data ||
            !commentaryPool.Size)
        {
            commentaryPool =
                GetDungeonPool(
                    run.GetSegment());
        }

        std::unordered_set<uint32>& used =
            state.UsedDungeonSounds[
                uint32(
                    dungeonGroup)];

        uint32 const dungeonSound =
            PickDungeonSound(
                commentaryPool,
                used,
                state.LastDungeonSound,
                run.GetRunId());

        if (!dungeonSound)
            return;

        state.LastDungeonSound =
            dungeonSound;

        QueueVoice(
            run,
            dungeonSound,
            STAGE_DUNGEON_DELAY_MS,
            VoiceKind::Dungeon,
            dungeonGroup);
    }

    void OnPlayerDeath(
        ManastormRun const& run)
    {
        RunVoiceState& state =
            RunStates[
                run.GetRunId()];

        if (state.DeathCooldownMs)
            return;

        uint32 const soundId =
            PickSound(
                PLAYER_DEATH,
                state.LastDeathSound);

        state.LastDeathSound =
            soundId;

        state.DeathCooldownMs =
            PLAYER_DEATH_COOLDOWN_MS;

        QueueVoice(
            run,
            soundId,
            0,
            VoiceKind::PlayerDeath);
    }

    void OnObjectiveComplete(
        ManastormRun const& run)
    {
        RunVoiceState& state =
            RunStates[
                run.GetRunId()];

        uint32 const soundId =
            PickSound(
                OBJECTIVE_COMPLETE,
                state.LastCompletionSound);

        state.LastCompletionSound =
            soundId;

        //
        // ManastormMgr calls this only after SpawnStagePortal(), so even the
        // recovered GenericPortalsReady alternatives are truthful immediately
        // and cannot be lost to an instant portal click.
        //
        QueueVoice(
            run,
            soundId,
            0,
            VoiceKind::ObjectiveComplete);
    }
}
