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
    constexpr uint32 EMITTER_LIFETIME_MS = 12000;

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
    };

    struct PendingVoice
    {
        uint64 RunId = 0;
        uint32 DelayMs = 0;
        uint32 MapId = 0;
        uint32 InstanceId = 0;
        uint32 SoundId = 0;

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
        uint32 delayMs)
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

        voice.Members =
            run.GetMembers();

        return voice;
    }

    bool IsMemberReadyForVoice(
        Player* member,
        PendingVoice const& voice)
    {
        return
            member &&
            member->GetSession() &&
            member->IsInWorld() &&
            !member->IsBeingTeleported() &&
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

    void PlayVoice(
        PendingVoice const& voice)
    {
        if (!voice.SoundId)
            return;

        for (ObjectGuid::LowType memberGuid :
            voice.Members)
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            memberGuid));

            PlayForMember(
                member,
                voice);
        }
    }

    void QueueVoice(
        ManastormRun const& run,
        uint32 soundId,
        uint32 delayMs)
    {
        if (!soundId)
            return;

        PendingVoice voice =
            BuildVoice(
                run,
                soundId,
                delayMs);

        if (!delayMs)
        {
            PlayVoice(
                voice);

            return;
        }

        PendingVoices.push_back(
            std::move(voice));
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
        for (auto& pair :
            RunStates)
        {
            RunVoiceState& state =
                pair.second;

            if (state.DeathCooldownMs <= diff)
                state.DeathCooldownMs = 0;
            else
                state.DeathCooldownMs -= diff;
        }

        for (auto itr =
            PendingVoices.begin();
            itr != PendingVoices.end();)
        {
            if (itr->DelayMs > diff)
            {
                itr->DelayMs -= diff;
                ++itr;
                continue;
            }

            PendingVoice voice =
                std::move(*itr);

            itr =
                PendingVoices.erase(
                    itr);

            // A terminal run cleanup removes both the run state and all of
            // its pending events. This extra check also protects against a
            // stale delayed event if ordering ever changes later.
            if (RunStates.find(
                    voice.RunId) ==
                RunStates.end())
            {
                continue;
            }

            PlayVoice(
                voice);
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
                INTRO_EMITTER_SETTLE_MS);

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
        SoundPool const dungeonPool =
            GetDungeonPool(
                run.GetSegment());

        uint32 const dungeonSound =
            PickSound(
                dungeonPool,
                state.LastDungeonSound);

        if (!dungeonSound)
            return;

        state.LastDungeonSound =
            dungeonSound;

        QueueVoice(
            run,
            dungeonSound,
            STAGE_DUNGEON_DELAY_MS);
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
            0);
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
            0);
    }
}
