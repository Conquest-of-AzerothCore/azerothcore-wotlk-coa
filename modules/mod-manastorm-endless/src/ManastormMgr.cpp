#include "ManastormClientBridge.h"
#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"
#include "ManastormPotionClient.h"
#include "AscensionManastormGadgets.h"

#include "ObjectAccessor.h"
#include "Creature.h"
#include "DynamicObject.h"
#include "Pet.h"
#include "CreatureAI.h"
#include "GameObject.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Group.h"
#include "InstanceSaveMgr.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "ManastormDataStore.h"
#include "ManastormGenerator.h"
#include "ManastormProgression.h"
#include "ManastormRewards.h"
#include "ManastormExperience.h"
#include "ManastormAffixEngine.h"
#include "ManastormGreedyDemon.h"
#include "ManastormVoiceOfMillhouse.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>
#include "Random.h"
#include "Chat.h"
#include "ScriptedGossip.h"
#include "TemporarySummon.h"
#include "Language.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "World.h"
#include <set>
#include <sstream>

namespace
{
    //
// WoW raid-target indexes are zero-based server-side.
//
// Lua:
//     SetRaidTarget("target", 8)
//
// corresponds to:
//
//     server marker index 7 = Skull
//
    constexpr uint8 ENDLESS_OBJECTIVE_SKULL_INDEX = 7;

    void SendEndlessRaidTargetMarker(
        Player* player,
        ObjectGuid setterGuid,
        uint8 markerIndex,
        ObjectGuid targetGuid)
    {
        if (!player ||
            !player->GetSession())
        {
            return;
        }

        WorldPacket packet(
            MSG_RAID_TARGET_UPDATE,
            1 + 8 + 1 + 8);

        packet << uint8(0);       // Set/update marker.
        packet << setterGuid;
        packet << markerIndex;
        packet << targetGuid;

        player->GetSession()->SendPacket(
            &packet);
    }

    void SetEndlessObjectiveSkull(
        ManastormRun const& run,
        ObjectGuid targetGuid)
    {
        ObjectGuid const ownerGuid =
            ObjectGuid::Create<HighGuid::Player>(
                run.GetOwnerGuid());

        Player* owner =
            ObjectAccessor::FindConnectedPlayer(
                ownerGuid);

        //
        // Once shared group transport is implemented, use AzerothCore's
        // real Group target-marker state whenever possible.
        //
        if (owner)
        {
            if (Group* group = owner->GetGroup())
            {
                group->SetTargetIcon(
                    ENDLESS_OBJECTIVE_SKULL_INDEX,
                    owner->GetGUID(),
                    targetGuid);

                return;
            }
        }

        //
        // A solo run has no Group target-icon broadcaster.
        //
        // Normal Group::SetTargetIcon cannot service a player that has
        // no Group, so reproduce the same MSG_RAID_TARGET_UPDATE packet
        // directly for each Endless member.
        //
        for (ObjectGuid::LowType memberGuid :
        run.GetMembers())
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(
                        memberGuid));

            if (!member)
                continue;

            ObjectGuid const setterGuid =
                owner
                ? owner->GetGUID()
                : member->GetGUID();

            SendEndlessRaidTargetMarker(
                member,
                setterGuid,
                ENDLESS_OBJECTIVE_SKULL_INDEX,
                targetGuid);
        }
    }

    //
// Recovered Ascension Manastorm stage XP curve.
//
// Level 1 = 1.000 = +0.0%
// Level 2 = 1.003 = +0.3%
// Level 3 = 1.006 = +0.6%
//
// The recovered modifier sequence continues linearly:
//
//     1 + (0.003 * (depth - 1))
//
    constexpr double ENDLESS_XP_BONUS_PER_DEPTH = 0.003;

    double GetEndlessExperienceMultiplier(
        uint32 depth)
    {
        if (!depth)
            return 1.0;

        return 1.0 +
            (double(depth - 1) *
                ENDLESS_XP_BONUS_PER_DEPTH);
    }

    uint64 GetEndlessExperienceBonusTenths(
        uint32 depth)
    {
        if (!depth)
            return 0;

        //
        // Client wire format stores tenths of one percent:
        //
        // +0.3% = 3
        // +0.6% = 6
        // +0.9% = 9
        //
        return uint64(depth - 1) * 3ULL;
    }

    constexpr std::size_t
        ENDLESS_ADDON_PAYLOAD_LIMIT = 230;

    std::string EscapeEndlessAddonField(
        std::string const& value)
    {
        static char const HEX[] =
            "0123456789ABCDEF";

        std::string escaped;

        escaped.reserve(
            value.size());

        for (unsigned char c :
        value)
        {
            switch (c)
            {
            case '%':
            case '|':
            case '\t':
            case '\r':
            case '\n':
                escaped += '%';
                escaped +=
                    HEX[(c >> 4) & 0x0F];
                escaped +=
                    HEX[c & 0x0F];
                break;

            default:
                escaped +=
                    char(c);
                break;
            }
        }

        return escaped;
    }

    constexpr char const* CLIENT_ADDON_PREFIX = "MANASTORM";
    constexpr char const* LOG_FILTER = "module.manastorm.endless";
    constexpr uint64 RUN_SEED_MIX = 0xD1B54A32D192ED03ULL;
    constexpr uint32 STAGE_TRANSITION_DELAY_MS = 5000;

    // 93305 is visually centered on its invisible 80910 controller. Spawning
    // that controller at the objective corpse's ground Z buries roughly half
    // of the recovered portal effect below the terrain, so lift only the
    // temporary portal anchor while preserving the boss X/Y/orientation.
    constexpr float STAGE_PORTAL_Z_OFFSET = 3.5f;

    constexpr uint32 NPC_MANASTORM_HEART = 900025;
    constexpr uint32 NPC_EMPTY_HEART_CONTAINER = 900027;

    constexpr uint32 SPELL_MANASTORM_HEART_PROJECTILE = 991507;
    constexpr uint32 SPELL_MANASTORM_HEART_HEALING = 991510;
    constexpr uint32 SPELL_MANASTORM_HEART_VISUAL = 991511;

    // Recovered Ascension Manastorm Chaotic Link boss aura.
    constexpr uint32 SPELL_CHAOTIC_LINK = 93459;

    // Recovered Cleaving proc spell. Spell.dbc defines 93352 as a
    // PROC_TRIGGER_SPELL aura pointing at 93351. 93351 is 100% weapon
    // damage with EffectChainTargets=3.
    constexpr uint32 SPELL_MANASTORM_CLEAVE = 93351;
    constexpr uint8 MANASTORM_AFFIX_PRIMARY_RANK_ROLE = 1;

    constexpr uint32 SPELL_MANASTORM_REFLECTIVE = 93361;

    // Prevent reflected damage from recursively re-entering Manastorm
    // damage callbacks (Reflecting -> Reflecting, Leeching, etc.).
    thread_local bool sManastormReflectDamageDispatch = false;

    // 80919 is the native Cogsley non-combat companion/vendor summoned by
    // spell 93418.
    constexpr uint32 NPC_COGSLEY = 80919;

    // Recovered Ascension end-of-stage Manastorm portal presentation.
    //
    // Runtime validation on the target client proved:
    //
    //     80910 "The Manastorm"
    //         = invisible creature/controller
    //
    //     93305 "Manastorm Portal Effect"
    //         = the visible purple/black stage portal
    //
    // The portal remains server-authoritative: interacting with this exact
    // runtime creature advances the shared run, while the existing five-second
    // automatic transition remains as a fallback.
    constexpr uint32 NPC_STAGE_PORTAL = 80910;
    constexpr uint32 SPELL_STAGE_PORTAL = 93305;

    constexpr uint32 SPELL_SAFETY_BUBBLE = 93306;
    constexpr uint32 SPELL_SAFETY_BUBBLE_HELPER = 93307;

    //
    // Recovered Manastorm Safety Bubble families across the supplied
    // Ascension revisions. 93306/93307 are the older controller/helper pair
    // used by this reconstruction; the 21803xx / 31803xx family contains the
    // later visual/state/combat-preventer variants.
    //
    // When the shared backend declares preparation protection finished, no
    // member may retain one of these combat-prevention auras. Leaving one
    // behind makes normal dungeon creatures appear unable to hit the player
    // even though the run has already entered ACTIVE state.
    //
    constexpr uint32 SAFETY_BUBBLE_CLEANUP_SPELLS[] =
    {
        93304,   // Entering the Manastorm...
        93306,   // older Safety Bubble
        93307,   // older Safety Bubble helper
        2180300, // Safety Bubble Trigger
        2180301, // Safety Bubble
        2180302, // Safety Bubble
        2180304, // Safety Bubble - Combat Preventer
        2180305, // Safety Bubble Fake
        3180300, // revision variant
        3180304, // revision combat-preventer variant
        3180305  // revision fake variant
    };

    //
    // Event-driven dungeon objectives
    // --------------------------------
    //
    // Some native Manastorm objectives are normally produced by prerequisite
    // dungeon events rather than persistent DB spawns. Endless stages should
    // not depend on quest items, long ritual chains, or encounter-specific
    // failure mechanics just to make their selected objective exist.
    //
    // Keep those exceptions centralized here and bootstrap the selected
    // objective directly using the dungeon's own native spawn data. The
    // generic Manastorm objective/scaling/Chaotic-Link path then takes over
    // exactly as it does for every other boss.
    //
    // Sunken Temple:
    //   675 = Avatar of Hakkar (Normal)
    //   678 = Avatar of Hakkar (Endgame)
    //
    // AzerothCore world event script 8502 summons Avatar of Hakkar (8443)
    // at this exact position after the four-flame ritual succeeds:
    //
    //   -466.86, 272.31, -90.74, 3.52
    //
    // The normal ritual can be failed by its own suppressor mechanics and is
    // currently known to have very fast add respawns on AzerothCore. For an
    // Endless objective, summon the final native boss directly instead of
    // starting that prerequisite event.
    //
    // Blasted Lands / Rise of the Defiler:
    // Razelikh (7664) is normally quest-summoned and has no persistent
    // creature spawn row. Spell 13461 ("Go Home") targets his native home
    // point on the summit, which gives us the canonical spawn position.
    constexpr uint32 MANASTORM_MAP_EASTERN_KINGDOMS = 0;
    constexpr uint32 NPC_RAZELIKH_THE_DEFILER = 7664;
    constexpr uint32 SEGMENT_RAZELIKH_NORMAL = 542;
    constexpr uint32 SEGMENT_RAZELIKH_ENDGAME = 543;

    Position const RAZELIKH_HOME_POSITION =
    {
        -11234.8f,
         -2842.52f,
           157.92f,
             1.47f
    };

    // Lord Hel'nurath is summoned during the Warlock Dreadsteed ritual,
    // not loaded from a permanent dungeon creature spawn.
    // Tuten'kash is an event-summoned Razorfen Downs boss with no
    // persistent creature spawn row. Original Endgame Manastorm 294
    // starts at the final encounter, not at the three-wave gong event.
    constexpr uint32 MANASTORM_MAP_RAZORFEN_DOWNS = 129;
    constexpr uint32 NPC_TUTEN_KASH = 7355;
    constexpr uint32 NPC_PLAGUEMAW_THE_ROTTING = 7356;
    constexpr uint32 GO_RFD_GONG = 148917;
    constexpr uint32 SEGMENT_TUTEN_KASH_ENDGAME = 294;
    constexpr uint32 SEGMENT_PLAGUEMAW_ENDGAME = 689;
    // Ragglesnout is a genuinely rare native RFD dungeon spawn.
    // Both of these are recovered original Manastorm segment identities;
    // 9999 is the original Normal encounter ID, not a replacement value.
    constexpr uint32 NPC_RAGGLESNOUT = 7354;
    constexpr uint32 SEGMENT_RAGGLESNOUT_NORMAL = 692;
    constexpr uint32 SEGMENT_RAGGLESNOUT_ENDGAME = 690;

    // Uldaman's altar-locked Archaedas is a normal native DB boss.
    // Manastorm loads his original creature in PREPARING, then reproduces
    // the altar spell's native SetData sequence once the stage is ACTIVE.
    constexpr uint32 MANASTORM_MAP_ULDAMAN = 70;
    constexpr uint32 NPC_ULDAMAN_ARCHAEDAS = 2748;
    constexpr uint32 SEGMENT_ARCHAEDAS_NORMAL = 101;
    constexpr uint32 SEGMENT_ARCHAEDAS_ENDGAME = 385;
    constexpr uint32 DATA_ULDAMAN_ARCHAEDAS = 2;

    // Ironaya is the native sealed-chamber DB boss. The Uldaman
    // instance script opens both the seal and keystone on DONE.
    // Only original Manastorm segments 694/693 use this private bootstrap.
    constexpr uint32 NPC_ULDAMAN_IRONAYA = 7228;
    constexpr uint32 SEGMENT_IRONAYA_NORMAL = 694;
    constexpr uint32 SEGMENT_IRONAYA_ENDGAME = 693;
    constexpr uint32 DATA_ULDAMAN_IRONAYA_DOORS = 0;
    constexpr uint32 GO_ULDAMAN_IRONAYA_SEAL = 124372;
    constexpr uint32 GO_ULDAMAN_KEYSTONE = 124371;

    // Meshlok is a native Maraudon rare. Both original Manastorm
    // segments must guarantee his DB spawn inside the disposable
    // private instance, without changing his public-dungeon rarity.
    constexpr uint32 MANASTORM_MAP_MARAUDON = 349;
    constexpr uint32 NPC_MARAUDON_MESHLOK = 12237;
    constexpr uint32 SEGMENT_MESHLOK_NORMAL = 684;
    constexpr uint32 SEGMENT_MESHLOK_ENDGAME = 683;

    // Native TrinityCore 3.3.5 RFD gong's final Tuten'kash summon
    // position (not the player-authored game_tele 2158 arrival point).
    Position const TUTEN_KASH_GONG_POSITION =
    {
        2487.939f, 804.2224f, 43.10735f, 1.692969f
    };

    // RFD's npc_belnistrasz randomly chooses from PosSummonSpawner[3]
    // for each wave. On wave eight (data == 7) the native
    // npc_idol_room_spawner summons Plaguemaw at its own position.
    // Use the first exact native spawner position as a deterministic
    // standalone boss location, without requiring the escort quest.
    Position const PLAGUEMAW_NATIVE_EVENT_POSITION =
    {
        2582.789f, 954.3925f, 52.48214f, 3.787364f
    };

    constexpr uint32 MANASTORM_MAP_ZUL_FARRAK = 209;
    constexpr uint32 NPC_GAHZRILLA = 7273;
    constexpr uint32 NPC_HYDROMANCER_VELRATHA = 7795;
    constexpr uint32 SEGMENT_GAHZRILLA_NORMAL = 198;
    constexpr uint32 SEGMENT_GAHZRILLA_ENDGAME = 392;
    constexpr uint32 SEGMENT_VELRATHA_NORMAL = 538;
    constexpr uint32 SEGMENT_VELRATHA_ENDGAME = 548;

    // Native Zul'Farrak gong-event (2488) summon position in the pool.
    // Source: historical DB-event summon coordinates, not the player
    // entrance teleport. Only used for private Manastorm objective stages.
    Position const GAHZRILLA_GONG_POSITION =
    {
        1667.54f, 1190.57f, -2.80444f, 0.890118f
    };

    constexpr uint32 MANASTORM_MAP_DIRE_MAUL = 429;
    constexpr uint32 NPC_LORD_HELNURATH = 14506;
    constexpr uint32 NPC_IMMOLTHAR = 11496;
    constexpr uint32 NPC_CAPTAIN_KROMCRUSH = 14325;
    constexpr uint32 NPC_KING_GORDOK = 11501;
    constexpr uint32 SEGMENT_KING_GORDOK_NORMAL = 148;
    constexpr uint32 SEGMENT_KING_GORDOK_ENDGAME = 279;
    constexpr uint32 SEGMENT_HELNURATH_NORMAL = 687;
    constexpr uint32 SEGMENT_HELNURATH_ENDGAME = 688;

    // Native Dreadsteed ritual pedestal (Dire Maul West).
    // This is a Manastorm-only boss location, not a claimed DB spawn.
    Position const HELNURATH_RITUAL_POSITION =
    {
        -37.9392f, 812.805f, -29.4525f, 4.81711f
    };

    constexpr uint32 MANASTORM_MAP_SUNKEN_TEMPLE = 109;
    constexpr uint32 NPC_SHADE_OF_ERANIKUS = 5709;
    constexpr uint32 NPC_JAMMALAN_THE_PROPHET = 5710;
    constexpr uint32 NPC_AVATAR_OF_HAKKAR = 8443;
    constexpr uint32 NPC_ATAL_ALARION = 8580;
    constexpr uint32 DATA_SUNKEN_TEMPLE_STATUES = 10;
    constexpr uint32 DATA_SUNKEN_TEMPLE_DEFENDER_KILLED = 11;
    constexpr uint32 SUNKEN_TEMPLE_STATUE_PHASES = 6;
    constexpr uint32 SUNKEN_TEMPLE_DEFENDERS_COUNT = 6;
    constexpr uint32 SEGMENT_ATAL_ALARION_NORMAL = 673;
    constexpr uint32 SEGMENT_ATAL_ALARION_ENDGAME = 674;
    constexpr uint32 SEGMENT_HAKKAR_NORMAL = 675;
    constexpr uint32 SEGMENT_JAMMALAN_NORMAL = 676;
    constexpr uint32 SEGMENT_ERANIKUS_NORMAL = 677;
    constexpr uint32 SEGMENT_HAKKAR_ENDGAME = 678;
    constexpr uint32 SEGMENT_JAMMALAN_ENDGAME = 679;
    constexpr uint32 SEGMENT_ERANIKUS_ENDGAME = 680;

    // Wailing Caverns segment 703 uses Brightwing as its recovered runtime
    // objective. Brightwing is a rare native DB spawn and is not guaranteed
    // to exist in a fresh disposable Manastorm instance, so this one segment
    // owns a direct objective bootstrap without changing normal WC behavior.
    // The Unforgiven normally emerges near the Stratholme archway with
    // Vengeful Phantoms. The native instance script does not summon him.
    // Only exact recovered Manastorm routes use the private bootstrap.
    constexpr uint32 MANASTORM_MAP_STRATHOLME = 329;
    constexpr uint32 NPC_STRATHOLME_UNFORGIVEN = 10516;
    constexpr uint32 NPC_STRATHOLME_VENGEFUL_PHANTOM = 10387;
    constexpr uint32 SEGMENT_UNFORGIVEN_NORMAL = 130;
    constexpr uint32 SEGMENT_UNFORGIVEN_ENDGAME = 354;
    // The Scarlet-side Stratholme final encounter has a native
    // permanent Dathrohan (10812) spawn. His SmartAI performs action 36
    // (Update Template to 10813) below 40% HP, preserving his GUID.
    // The historical Manastorm objective remains Balnazzar (10813).
    constexpr uint32 NPC_STRATHOLME_DATHROHAN = 10812;
    constexpr uint32 NPC_STRATHOLME_BALNAZZAR = 10813;
    constexpr uint32 SEGMENT_BALNAZZAR_NORMAL = 187;
    constexpr uint32 SEGMENT_BALNAZZAR_ENDGAME = 358;

    // Historical emulator report locates the original encounter near
    // this gateway. This is an approximate fallback arena, NOT a
    // verified original creature DB spawn or the player's game_tele.
    Position const UNFORGIVEN_REPORTED_GATE_POSITION =
    {
        3721.607f, -3424.507f, 131.761f, 0.0f
    };

    constexpr uint32 MANASTORM_MAP_WAILING_CAVERNS = 43;
    constexpr uint32 NPC_BRIGHTWING = 5912;
    constexpr ObjectGuid::LowType SPAWN_BRIGHTWING = 517;
    constexpr uint32 SEGMENT_BRIGHTWING_ENDGAME = 703;
    // Earthcaller Halmgar is an Endgame-only Razorfen Kraul Manastorm rare.
    // The native base-world creature spawn (entry 4842, map 47) has a
    // 43,200-second respawn timer. Its original DB GUID and position are
    // preserved rather than fabricating a second boss at the player teleport.
    constexpr uint32 MANASTORM_MAP_RAZORFEN_KRAUL = 47;
    constexpr uint32 NPC_EARTHCALLER_HALMGAR = 4842;
    constexpr uint32 SEGMENT_HALMGAR_ENDGAME = 705;
    constexpr ObjectGuid::LowType SPAWN_EARTHCALLER_HALMGAR = 1975863;
    constexpr float HALMGAR_SPAWN_X = 2118.58f;
    constexpr float HALMGAR_SPAWN_Y = 1695.32f;

    bool RestorePrivateRouteCreatures(Map* map, ManastormRun& run, std::string& error)
    {
        ManastormSegment const& segment = run.GetSegment();
        if (!map || !map->IsScriptedPrivateInstance() || map->GetId() != segment.MapId
            || map->GetInstanceId() != run.GetInstanceId())
        {
            error = "Private route restoration received a different map or instance.";
            return false;
        }
        for (ObjectGuid::LowType spawnId : segment.RouteSpawnIds)
        {
            if (sObjectMgr->GetCreatureData(spawnId))
                continue;
            CreatureData const* data = ManastormDataStore::Instance().GetPrivateCreature(spawnId);
            if (!data)
                continue;
            if (data->mapid != segment.MapId)
            {
                error = "Private route creature map does not match its authored segment.";
                return false;
            }
            map->LoadGrid(data->posX, data->posY);
            if (map->GetCreatureBySpawnIdStore().contains(spawnId))
                continue;
            Creature* creature = new Creature();
            if (!creature->LoadCreatureFromDB(spawnId, map, true, false, data))
            {
                delete creature;
                error = "Unable to restore original private route spawn " + std::to_string(spawnId);
                return false;
            }
            creature->setActive(true);
            LOG_INFO(LOG_FILTER, "Restored Manastorm-only creature: segment={} instance={} spawn={} entry={}.",
                segment.SegmentId, run.GetInstanceId(), spawnId, data->id);
        }
        return true;
    }

    bool BootstrapRazelikhEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        if (!map)
        {
            error =
                "Razelikh bootstrap has no destination map.";
            return false;
        }

        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId !=
                MANASTORM_MAP_EASTERN_KINGDOMS ||
            segment.ObjectiveCreatureEntry !=
                NPC_RAZELIKH_THE_DEFILER ||
            (segment.SegmentId !=
                SEGMENT_RAZELIKH_NORMAL &&
             segment.SegmentId !=
                SEGMENT_RAZELIKH_ENDGAME))
        {
            std::ostringstream message;

            message
                << "Razelikh bootstrap was requested for segment "
                << segment.SegmentId
                << " but runtime map/objective is "
                << segment.MapId
                << "/"
                << segment.ObjectiveCreatureEntry
                << ".";

            error = message.str();
            return false;
        }

        TempSummon* razelikh =
            map->SummonCreature(
                NPC_RAZELIKH_THE_DEFILER,
                RAZELIKH_HOME_POSITION);

        if (!razelikh)
        {
            error =
                "Manastorm could not summon Razelikh the Defiler (7664).";
            return false;
        }

        // Razelikh is a quest-summoned Vanilla objective rather than a
        // persistent DB spawn. Own only this runtime copy for the disposable
        // Manastorm stage while preserving his native SmartAI and combat kit.
        razelikh->SetTempSummonType(
            TEMPSUMMON_MANUAL_DESPAWN);

        // SummonCreature() normally reaches the global creature hook already,
        // but explicit registration is duplicate-safe and lets us reject a
        // bootstrap that failed to become this run's exact objective.
        ManastormMgr::Instance()
            .OnCreatureAddWorld(
                razelikh);

        if (run.GetObjectiveCreatureGuid() !=
            razelikh->GetGUID())
        {
            razelikh->DespawnOrUnsummon();

            error =
                "Razelikh was summoned but did not register as the runtime objective.";
            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Manastorm quest-summoned Razelikh objective: "
            "run={} segment={} map={} instance={} objective={} guid={}.",
            run.GetRunId(),
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            segment.ObjectiveCreatureEntry,
            razelikh->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapSunkenTempleAtalAlarionEncounter(
        Map* map,
        ManastormRun const& run,
        std::string& error)
    {
        error.clear();

        if (!map)
        {
            error =
                "Sunken Temple Atal'alarion bootstrap has no destination map.";
            return false;
        }

        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId != MANASTORM_MAP_SUNKEN_TEMPLE ||
            segment.ObjectiveCreatureEntry != NPC_ATAL_ALARION)
        {
            std::ostringstream message;

            message
                << "Sunken Temple Atal'alarion bootstrap was requested for "
                << "segment "
                << segment.SegmentId
                << " but runtime map/objective is "
                << segment.MapId
                << "/"
                << segment.ObjectiveCreatureEntry
                << ".";

            error = message.str();
            return false;
        }

        InstanceMap* instanceMap =
            map->ToInstanceMap();

        if (!instanceMap)
        {
            error =
                "Sunken Temple Atal'alarion bootstrap is not running on an InstanceMap.";
            return false;
        }

        InstanceScript* instance =
            instanceMap->GetInstanceScript();

        if (!instance)
        {
            error =
                "Sunken Temple Atal'alarion bootstrap has no instance script.";
            return false;
        }

        uint32 const statuePhase =
            instance->GetData(
                DATA_SUNKEN_TEMPLE_STATUES);

        if (statuePhase >=
            SUNKEN_TEMPLE_STATUE_PHASES)
        {
            return true;
        }

        //
        // Native Sunken Temple progression:
        //
        //   DATA_STATUES (10) reaches 6
        //       -> Atal'alarion SmartAI condition becomes true
        //       -> native SMART_EVENT_UPDATE action sets phase mask 1
        //       -> ordinary players can see/fight the existing DB boss
        //
        // Manastorm begins directly at this selected encounter, so enqueue
        // only the missing native statue-completion events. EventMap permits
        // duplicate event IDs and the instance script processes one per map
        // update, exactly as if the six statue triggers had been completed.
        //
        // Do not force visibility, do not summon a duplicate 8580, and do not
        // replace Atal'alarion's SmartAI.
        //
        uint32 const missingStatues =
            SUNKEN_TEMPLE_STATUE_PHASES -
            statuePhase;

        for (uint32 i = 0;
            i < missingStatues;
            ++i)
        {
            instance->SetData(
                DATA_SUNKEN_TEMPLE_STATUES,
                1);
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped native Manastorm Sunken Temple statue progression: "
            "run={} segment={} map={} instance={} statues={}/{} queued={} "
            "objective={}.",
            run.GetRunId(),
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            statuePhase,
            SUNKEN_TEMPLE_STATUE_PHASES,
            missingStatues,
            segment.ObjectiveCreatureEntry);

        return true;
    }

    bool BootstrapSunkenTempleHakkarEncounter(
        Map* map,
        ManastormRun const& run,
        std::string& error)
    {
        error.clear();

        if (!map)
        {
            error = "Sunken Temple Hakkar bootstrap has no destination map.";
            return false;
        }

        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId != MANASTORM_MAP_SUNKEN_TEMPLE ||
            segment.ObjectiveCreatureEntry != NPC_AVATAR_OF_HAKKAR)
        {
            std::ostringstream message;

            message
                << "Sunken Temple Hakkar bootstrap was requested for "
                << "segment "
                << segment.SegmentId
                << " but runtime map/objective is "
                << segment.MapId
                << "/"
                << segment.ObjectiveCreatureEntry
                << ".";

            error = message.str();
            return false;
        }

        Position const avatarPosition =
        {
            -466.86f,
             272.31f,
             -90.74f,
               3.52f
        };

        TempSummon* avatar =
            map->SummonCreature(
                NPC_AVATAR_OF_HAKKAR,
                avatarPosition);

        if (!avatar)
        {
            error = "Manastorm could not summon Avatar of Hakkar (8443).";
            return false;
        }

        //
        // Own this boss for the lifetime of the disposable Manastorm stage.
        // OnCreatureAddWorld() will register this exact runtime GUID as the
        // objective, apply the Skull marker, scale it, and synchronize its
        // Chaotic Link aura.
        //
        avatar->SetTempSummonType(
            TEMPSUMMON_MANUAL_DESPAWN);

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Manastorm event objective directly: run={} "
            "segment={} map={} instance={} objective={} guid={}.",
            run.GetRunId(),
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            segment.ObjectiveCreatureEntry,
            avatar->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapSunkenTempleJammalanEncounter(
        Map* map,
        ManastormRun const& run,
        std::string& error)
    {
        error.clear();

        if (!map)
        {
            error = "Sunken Temple Jammal'an bootstrap has no destination map.";
            return false;
        }

        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId != MANASTORM_MAP_SUNKEN_TEMPLE ||
            segment.ObjectiveCreatureEntry != NPC_JAMMALAN_THE_PROPHET)
        {
            std::ostringstream message;

            message
                << "Sunken Temple Jammal'an bootstrap was requested for "
                << "segment "
                << segment.SegmentId
                << " but runtime map/objective is "
                << segment.MapId
                << "/"
                << segment.ObjectiveCreatureEntry
                << ".";

            error = message.str();
            return false;
        }

        InstanceMap* instanceMap =
            map->ToInstanceMap();

        if (!instanceMap)
        {
            error =
                "Sunken Temple Jammal'an bootstrap is not running on an InstanceMap.";
            return false;
        }

        InstanceScript* instance =
            instanceMap->GetInstanceScript();

        if (!instance)
        {
            error =
                "Sunken Temple Jammal'an bootstrap has no instance script.";
            return false;
        }

        uint32 defendersKilled =
            instance->GetData(
                DATA_SUNKEN_TEMPLE_DEFENDER_KILLED);

        if (defendersKilled >=
            SUNKEN_TEMPLE_DEFENDERS_COUNT)
        {
            return true;
        }

        //
        // The native Sunken Temple instance increments this value once for
        // each of its six Atal'ai defenders. Reaching six opens GO 149431 and
        // fires Jammal'an's normal "shield be down" progression event.
        //
        // Manastorm starts this stage behind that prerequisite route, so move
        // only the native instance state forward to the state the dungeon
        // would have after those six defenders were defeated. The existing
        // persistent Jammal'an spawn remains the objective; no duplicate boss
        // is created.
        //
        while (defendersKilled <
            SUNKEN_TEMPLE_DEFENDERS_COUNT)
        {
            uint32 const previous =
                defendersKilled;

            instance->SetData(
                DATA_SUNKEN_TEMPLE_DEFENDER_KILLED,
                1);

            defendersKilled =
                instance->GetData(
                    DATA_SUNKEN_TEMPLE_DEFENDER_KILLED);

            if (defendersKilled <= previous)
            {
                error =
                    "Sunken Temple defender state did not advance during Jammal'an bootstrap.";
                return false;
            }
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Manastorm Sunken Temple progression: run={} "
            "segment={} map={} instance={} defenders={}/{} objective={}.",
            run.GetRunId(),
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            defendersKilled,
            SUNKEN_TEMPLE_DEFENDERS_COUNT,
            segment.ObjectiveCreatureEntry);

        return true;
    }

    bool BootstrapSunkenTempleEranikusEncounter(
        Map* map,
        ManastormRun const& run,
        std::string& error)
    {
        error.clear();

        if (!map)
        {
            error = "Sunken Temple Eranikus bootstrap has no destination map.";
            return false;
        }

        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId != MANASTORM_MAP_SUNKEN_TEMPLE ||
            segment.ObjectiveCreatureEntry != NPC_SHADE_OF_ERANIKUS)
        {
            std::ostringstream message;

            message
                << "Sunken Temple Eranikus bootstrap was requested for "
                << "segment "
                << segment.SegmentId
                << " but runtime map/objective is "
                << segment.MapId
                << "/"
                << segment.ObjectiveCreatureEntry
                << ".";

            error = message.str();
            return false;
        }

        Creature* eranikus = nullptr;

        for (auto const& spawn :
            map->GetCreatureBySpawnIdStore())
        {
            Creature* creature =
                spawn.second;

            if (!creature ||
                !creature->IsInWorld() ||
                creature->GetEntry() !=
                    NPC_SHADE_OF_ERANIKUS)
            {
                continue;
            }

            eranikus = creature;
            break;
        }

        if (!eranikus)
        {
            error =
                "Sunken Temple Eranikus bootstrap could not find the persistent Shade of Eranikus (5709) spawn.";
            return false;
        }

        //
        // Native Sunken Temple progression leaves Eranikus unavailable until
        // Jammal'an is completed. The instance progression removes
        // NOT_SELECTABLE, while Eranikus' own SmartAI removes the player/NPC
        // immunity flags (mask 768) before the fight becomes usable.
        //
        // The Manastorm Eranikus segment begins after that prerequisite, so
        // reproduce that complete post-Jammal'an unlock state. Do not
        // duplicate the boss and do not bypass Eranikus' own combat AI.
        //
        eranikus->RemoveUnitFlag(
            UNIT_FLAG_NOT_SELECTABLE);

        eranikus->RemoveUnitFlag(
            UNIT_FLAG_IMMUNE_TO_PC);

        eranikus->RemoveUnitFlag(
            UNIT_FLAG_IMMUNE_TO_NPC);

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Manastorm Sunken Temple Eranikus unlock: run={} "
            "segment={} map={} instance={} objective={} guid={}.",
            run.GetRunId(),
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            segment.ObjectiveCreatureEntry,
            eranikus->GetGUID().GetRawValue());

        return true;
    }

    void StabilizeManastormBrightwing(
        Creature* brightwing)
    {
        if (!brightwing ||
            brightwing->GetEntry() !=
                NPC_BRIGHTWING)
        {
            return;
        }

        //
        // Native WC rarity for entry 5912 is implemented by SmartAI:
        //
        //   AI_INIT -> 85% FORCE_DESPAWN after 500 ms
        //
        // SMART_EVENT_FLAG_WHILE_CHARMED only means the event is also
        // permitted while charmed; it does not restrict the roll to charmed
        // creatures. Therefore a Manastorm-selected Brightwing can correctly
        // materialize/register, then disappear half a second later.
        //
        // At this point AI initialization has already happened and the
        // delayed FORCE_DESPAWN is queued in the creature's EventProcessor.
        // Segment 703 explicitly selected this rare as its objective, so
        // cancel the spawn-time delayed event for THIS runtime creature only.
        //
        // SmartAI itself remains installed: combat behavior is preserved.
        // Normal/public Wailing Caverns is completely untouched.
        //
        brightwing->m_Events.KillAllEvents(
            true);
    }

    bool BootstrapWailingCavernsBrightwingEncounter(
        Map* map,
        ManastormRun const& run,
        std::string& error)
    {
        error.clear();

        if (!map)
        {
            error =
                "Wailing Caverns Brightwing bootstrap has no destination map.";
            return false;
        }

        ManastormSegment const& segment =
            run.GetSegment();

        if (segment.MapId != MANASTORM_MAP_WAILING_CAVERNS ||
            segment.ObjectiveCreatureEntry != NPC_BRIGHTWING)
        {
            std::ostringstream message;

            message
                << "Wailing Caverns Brightwing bootstrap was requested for "
                << "segment "
                << segment.SegmentId
                << " but runtime map/objective is "
                << segment.MapId
                << "/"
                << segment.ObjectiveCreatureEntry
                << ".";

            error = message.str();
            return false;
        }

        CreatureData const* spawnData =
            sObjectMgr->GetCreatureData(
                SPAWN_BRIGHTWING);

        if (!spawnData ||
            spawnData->mapid !=
                MANASTORM_MAP_WAILING_CAVERNS ||
            spawnData->id !=
                NPC_BRIGHTWING)
        {
            error =
                "Wailing Caverns Brightwing DB spawn 517 does not resolve to entry 5912 on map 43.";
            return false;
        }

        //
        // Prefer the actual persistent WC spawn if this fresh private copy
        // already has it alive. This preserves its native DB identity, AI,
        // addon data and spawn GUID instead of manufacturing a TempSummon.
        //
        auto const existingBounds =
            map->GetCreatureBySpawnIdStore()
                .equal_range(
                    SPAWN_BRIGHTWING);

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
                creature->GetEntry() !=
                    NPC_BRIGHTWING)
            {
                continue;
            }

            StabilizeManastormBrightwing(
                creature);

            ManastormMgr::Instance()
                .OnCreatureAddWorld(
                    creature);

            if (run.GetObjectiveCreatureGuid() !=
                creature->GetGUID())
            {
                error =
                    "Living Brightwing DB spawn 517 did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(
                LOG_FILTER,
                "Reused living Manastorm Wailing Caverns Brightwing DB spawn: "
                "run={} segment={} map={} instance={} spawn={} guid={}.",
                run.GetRunId(),
                segment.SegmentId,
                segment.MapId,
                run.GetInstanceId(),
                SPAWN_BRIGHTWING,
                creature->GetGUID().GetRawValue());

            return true;
        }

        //
        // Brightwing is a rare 24-hour DB spawn. AzerothCore's normal
        // Creature::LoadCreatureFromDB() honors a map respawn timestamp and
        // therefore may materialize this spawn dead with zero HP.
        //
        // A scripted-private Manastorm stage is disposable, and its respawn
        // state is memory-only. Clear only THIS private instance's timestamp,
        // then instantiate the real spawn GUID 517 directly from the DB cache.
        // Normal Wailing Caverns remains completely untouched.
        //
        map->RemoveCreatureRespawnTime(
            SPAWN_BRIGHTWING);

        Creature* brightwing =
            new Creature();

        if (!brightwing->LoadCreatureFromDB(
                SPAWN_BRIGHTWING,
                map,
                true,
                true))
        {
            delete brightwing;

            error =
                "Manastorm could not load Brightwing DB spawn 517 into the private Wailing Caverns instance.";
            return false;
        }

        if (!brightwing->IsInWorld() ||
            !brightwing->IsAlive() ||
            brightwing->GetEntry() !=
                NPC_BRIGHTWING)
        {
            brightwing->AddObjectToRemoveList();

            error =
                "Brightwing DB spawn 517 loaded but was not a living entry 5912.";
            return false;
        }

        //
        // AI initialization occurs inside AddToWorld(), before
        // LoadCreatureFromDB() returns. Cancel Brightwing's native 85%
        // AI_INIT rare-despawn timer immediately, while keeping SmartAI itself.
        //
        StabilizeManastormBrightwing(
            brightwing);

        //
        // Register explicitly. The global AllCreatureScript hook may also
        // have fired during AddToMap(); OnCreatureAddWorld() is duplicate-safe
        // for the same exact runtime GUID.
        //
        ManastormMgr::Instance()
            .OnCreatureAddWorld(
                brightwing);

        if (run.GetObjectiveCreatureGuid() !=
            brightwing->GetGUID())
        {
            brightwing->AddObjectToRemoveList();

            error =
                "Brightwing DB spawn 517 loaded alive but did not register as the runtime objective.";
            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Bootstrapped Manastorm Wailing Caverns Brightwing from DB spawn: "
            "run={} segment={} map={} instance={} spawn={} objective={} guid={} registered=1.",
            run.GetRunId(),
            segment.SegmentId,
            segment.MapId,
            run.GetInstanceId(),
            SPAWN_BRIGHTWING,
            segment.ObjectiveCreatureEntry,
            brightwing->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapRazorfenKraulHalmgarEncounter(
        Map* map,
        ManastormRun const& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();

        if (!map ||
            map->GetId() != MANASTORM_MAP_RAZORFEN_KRAUL ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_RAZORFEN_KRAUL ||
            segment.SegmentId != SEGMENT_HALMGAR_ENDGAME ||
            segment.ObjectiveCreatureEntry != NPC_EARTHCALLER_HALMGAR)
        {
            error =
                "Razorfen Kraul Halmgar rare bootstrap received a nonmatching private stage.";
            return false;
        }

        CreatureData const* spawnData =
            sObjectMgr->GetCreatureData(
                SPAWN_EARTHCALLER_HALMGAR);

        if (!spawnData ||
            spawnData->mapid != MANASTORM_MAP_RAZORFEN_KRAUL ||
            spawnData->id != NPC_EARTHCALLER_HALMGAR)
        {
            error =
                "Razorfen Kraul Halmgar native DB spawn 1975863 is missing or does not match creature 4842 on map 47.";
            return false;
        }

        // The physical boss is farther into the dungeon than teleport 2129.
        // Load only the known original spawn's grid, not the whole instance.
        map->LoadGrid(
            HALMGAR_SPAWN_X,
            HALMGAR_SPAWN_Y);

        auto& spawns = map->GetCreatureBySpawnIdStore();
        auto const range = spawns.equal_range(
            SPAWN_EARTHCALLER_HALMGAR);

        for (auto itr = range.first; itr != range.second; ++itr)
        {
            Creature* halmgar = itr->second;

            if (!halmgar ||
                !halmgar->IsInWorld() ||
                !halmgar->IsAlive() ||
                halmgar->GetEntry() != NPC_EARTHCALLER_HALMGAR)
            {
                continue;
            }

            // The normal DB spawn may have loaded before stage indexing
            // existed. Register this exact instance-owned runtime creature.
            ManastormMgr::Instance().OnCreatureAddWorld(halmgar);

            if (run.GetObjectiveCreatureGuid() != halmgar->GetGUID())
            {
                error =
                    "Existing living Razorfen Kraul Halmgar did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(
                LOG_FILTER,
                "Reused native Earthcaller Halmgar for private Manastorm stage: "
                "run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(),
                segment.SegmentId,
                run.GetInstanceId(),
                SPAWN_EARTHCALLER_HALMGAR,
                halmgar->GetGUID().GetRawValue());
            return true;
        }

        // A long native rare respawn must not leave an explicit Manastorm
        // objective impossible. The private instance's respawn state is
        // disposable; do not touch the public dungeon's DB/spawn timer.
        map->RemoveCreatureRespawnTime(
            SPAWN_EARTHCALLER_HALMGAR);

        Creature* halmgar = new Creature();

        if (!halmgar->LoadCreatureFromDB(
                SPAWN_EARTHCALLER_HALMGAR,
                map,
                true,
                true))
        {
            delete halmgar;
            error =
                "Could not load native Earthcaller Halmgar DB spawn 1975863 in private Razorfen Kraul.";
            return false;
        }

        if (!halmgar->IsInWorld() ||
            !halmgar->IsAlive() ||
            halmgar->GetEntry() != NPC_EARTHCALLER_HALMGAR)
        {
            halmgar->AddObjectToRemoveList();
            error =
                "Native Earthcaller Halmgar spawn was loaded but is not a living creature 4842.";
            return false;
        }

        // OnCreatureAddWorld is duplicate-safe for this same runtime GUID.
        ManastormMgr::Instance().OnCreatureAddWorld(halmgar);

        if (run.GetObjectiveCreatureGuid() != halmgar->GetGUID())
        {
            halmgar->AddObjectToRemoveList();
            error =
                "Native Earthcaller Halmgar failed Manastorm objective registration.";
            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Restored rare native Earthcaller Halmgar for private Manastorm stage: "
            "run={} segment={} instance={} spawn={} objective={} guid={}.",
            run.GetRunId(),
            segment.SegmentId,
            run.GetInstanceId(),
            SPAWN_EARTHCALLER_HALMGAR,
            NPC_EARTHCALLER_HALMGAR,
            halmgar->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapDireMaulHelnurathEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_DIRE_MAUL ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_DIRE_MAUL ||
            segment.ObjectiveCreatureEntry != NPC_LORD_HELNURATH ||
            (segment.SegmentId != SEGMENT_HELNURATH_NORMAL &&
             segment.SegmentId != SEGMENT_HELNURATH_ENDGAME))
        {
            error = "Hel'nurath bootstrap received a nonmatching private Manastorm stage.";
            return false;
        }

        // Load the actual ritual arena, not the entire dungeon. Immol'thar
        // normally occupies it; suppress his native DB spawn in this copy.
        map->LoadGrid(
            HELNURATH_RITUAL_POSITION.GetPositionX(),
            HELNURATH_RITUAL_POSITION.GetPositionY());

        std::vector<ObjectGuid> immoltharGuids;
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* creature = spawn.second;
            if (creature && creature->IsInWorld() &&
                creature->GetEntry() == NPC_IMMOLTHAR)
            {
                immoltharGuids.push_back(creature->GetGUID());
            }
        }

        for (ObjectGuid const& guid : immoltharGuids)
            if (Creature* creature = map->GetCreature(guid))
                creature->DespawnOrUnsummon(0ms, 24h);

        TempSummon* helnurath = map->SummonCreature(
            NPC_LORD_HELNURATH,
            HELNURATH_RITUAL_POSITION);
        if (!helnurath)
        {
            error = "Could not summon Lord Hel'nurath (14506) in the Dire Maul ritual arena.";
            return false;
        }

        helnurath->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);

        // SummonCreature usually dispatches this already; explicit registration
        // checks that the real summoned GUID became the exact run objective.
        ManastormMgr::Instance().OnCreatureAddWorld(helnurath);
        if (run.GetObjectiveCreatureGuid() != helnurath->GetGUID())
        {
            helnurath->DespawnOrUnsummon();
            error = "Lord Hel'nurath was summoned but did not register as the Manastorm objective.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Bootstrapped private Dire Maul Hel'nurath objective: "
            "run={} segment={} instance={} guid={}.",
            run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
            helnurath->GetGUID().GetRawValue());

        return true;
    }

    bool IsUldamanIronayaStage(ManastormSegment const& segment)
    {
        return segment.MapId == MANASTORM_MAP_ULDAMAN &&
            segment.ObjectiveCreatureEntry == NPC_ULDAMAN_IRONAYA &&
            ((segment.SegmentId == SEGMENT_IRONAYA_NORMAL &&
              segment.Difficulty == 0 &&
              segment.DungeonEncounterId == 549) ||
             (segment.SegmentId == SEGMENT_IRONAYA_ENDGAME &&
              segment.Difficulty == 2 &&
              segment.DungeonEncounterId == 2549));
    }

    bool BootstrapUldamanIronayaEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_ULDAMAN ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            !IsUldamanIronayaStage(segment))
        {
            error = "Ironaya bootstrap received a nonmatching private Uldaman stage.";
            return false;
        }

        InstanceMap* instanceMap = map->ToInstanceMap();
        InstanceScript* instance =
            instanceMap ? instanceMap->GetInstanceScript() : nullptr;

        if (!instance)
        {
            error = "Uldaman's native instance script is unavailable for Ironaya.";
            return false;
        }

        // Original Uldaman OnGameObjectCreate checks this state to open
        // the Ironaya seal (124372) and keystone (124371). Manastorm
        // starts directly at this boss without collecting the staff, so
        // complete just the door prerequisite on this disposable map.
        // Do not alter public Uldaman, boss AI, or dungeon GO templates.
        if (instance->GetData(DATA_ULDAMAN_IRONAYA_DOORS) != DONE)
            instance->SetData(DATA_ULDAMAN_IRONAYA_DOORS, DONE);

        GameTele const* entrance =
            sObjectMgr->GetGameTele(segment.StartGameTeleId);
        if (!entrance)
        {
            error = "Ironaya stage is missing its authored arrival teleport.";
            return false;
        }

        map->LoadGrid(entrance->position_x, entrance->position_y);

        // OnGameObjectCreate handles newly loaded GOs, but existing
        // loaded gameobjects won't receive the callback again just
        // because the instance's door flag changed. Open both native
        // objects already present in this private map as well.
        for (auto const& spawn : map->GetGameObjectBySpawnIdStore())
        {
            GameObject* gameObject = spawn.second;
            if (!gameObject ||
                !gameObject->IsInWorld() ||
                (gameObject->GetEntry() != GO_ULDAMAN_IRONAYA_SEAL &&
                 gameObject->GetEntry() != GO_ULDAMAN_KEYSTONE))
                continue;

            instance->HandleGameObject(
                ObjectGuid::Empty, true, gameObject);
            gameObject->SetGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
        }

        // Force-load only the genuine Ironaya arena grid. She is a
        // permanent native world DB boss, not an event-only summon.
        // This ensures the original objective can be registered before
        // the stage's safety-bubble preparation finishes.
        QueryResult spawn = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` "
            "FROM `creature` WHERE `map` = 70 AND `id` = 7228 "
            "AND (`spawnMask` & 1) <> 0 ORDER BY `guid` LIMIT 1");

        if (!spawn)
        {
            error = "Native Ironaya (7228) spawn not found in Uldaman world DB.";
            return false;
        }

        Field* fields = spawn->Fetch();
        ObjectGuid::LowType const spawnId = fields[0].Get<uint32>();
        float const x = fields[1].Get<float>();
        float const y = fields[2].Get<float>();

        CreatureData const* spawnData = sObjectMgr->GetCreatureData(spawnId);
        if (!spawnData ||
            spawnData->mapid != MANASTORM_MAP_ULDAMAN ||
            spawnData->id != NPC_ULDAMAN_IRONAYA)
        {
            error = "Resolved Ironaya DB spawn does not match NPC 7228 on map 70.";
            return false;
        }

        map->LoadGrid(x, y);

        // The map-local store contains only loaded creatures; do not
        // scan all world creatures or summon an artificial replacement.
        auto const bounds =
            map->GetCreatureBySpawnIdStore().equal_range(spawnId);
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
        {
            Creature* ironaya = itr->second;
            if (!ironaya ||
                !ironaya->IsInWorld() ||
                !ironaya->IsAlive() ||
                ironaya->GetEntry() != NPC_ULDAMAN_IRONAYA)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(ironaya);
            if (run.GetObjectiveCreatureGuid() != ironaya->GetGUID())
            {
                error = "Original Ironaya failed Manastorm objective registration.";
                return false;
            }

            // Native keystone SmartAI removes mask 33554434 after opening
            // the seal. Completing only the instance door state skips it.
            ironaya->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            ironaya->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);

            LOG_INFO(LOG_FILTER,
                "Unlocked native Ironaya in private Manastorm: "
                "run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                spawnId, ironaya->GetGUID().GetRawValue());
            return true;
        }

        error = "Ironaya's native DB spawn is not loaded/alive in the private Uldaman stage.";
        return false;
    }

    bool IsUldamanArchaedasStage(ManastormSegment const& segment)
    {
        return segment.MapId == MANASTORM_MAP_ULDAMAN &&
            segment.ObjectiveCreatureEntry == NPC_ULDAMAN_ARCHAEDAS &&
            ((segment.SegmentId == SEGMENT_ARCHAEDAS_NORMAL &&
              segment.Difficulty == 0 &&
              segment.DungeonEncounterId == 554) ||
             (segment.SegmentId == SEGMENT_ARCHAEDAS_ENDGAME &&
              segment.Difficulty == 2 &&
              segment.DungeonEncounterId == 2554));
    }

    bool BootstrapUldamanArchaedasEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_ULDAMAN ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            !IsUldamanArchaedasStage(segment))
        {
            error = "Archaedas bootstrap received a nonmatching private Uldaman stage.";
            return false;
        }

        // The native boss is a persistent petrified DB creature. Do not
        // spawn a duplicate or bypass his altar/SmartAI encounter mechanics.
        // Resolve his original spawn coordinates and GUID rather than
        // mistaking the player-authored arrival point for his home position.
        QueryResult spawn = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` "
            "FROM `creature` WHERE `map` = 70 AND `id` = 2748 "
            "AND (`spawnMask` & 1) <> 0 ORDER BY `guid` LIMIT 1");

        if (!spawn)
        {
            error = "Uldaman's native Archaedas (2748) spawn was not found in the world DB.";
            return false;
        }

        Field* fields = spawn->Fetch();
        ObjectGuid::LowType const spawnId = fields[0].Get<uint32>();
        float const x = fields[1].Get<float>();
        float const y = fields[2].Get<float>();

        CreatureData const* spawnData = sObjectMgr->GetCreatureData(spawnId);
        if (!spawnData ||
            spawnData->mapid != MANASTORM_MAP_ULDAMAN ||
            spawnData->id != NPC_ULDAMAN_ARCHAEDAS)
        {
            error = "Native Uldaman Archaedas spawn GUID does not resolve to entry 2748 on map 70.";
            return false;
        }

        map->LoadGrid(x, y);

        auto const bounds = map->GetCreatureBySpawnIdStore().equal_range(spawnId);
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
        {
            Creature* existing = itr->second;
            if (!existing ||
                !existing->IsInWorld() ||
                !existing->IsAlive() ||
                existing->GetEntry() != NPC_ULDAMAN_ARCHAEDAS)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(existing);
            if (run.GetObjectiveCreatureGuid() != existing->GetGUID())
            {
                error = "Native Archaedas did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Registered original Uldaman Archaedas in private Manastorm: "
                "run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                spawnId, existing->GetGUID().GetRawValue());
            return true;
        }

        // Honor the exact native DB record if it was absent due to
        // a private-instance respawn state. Public Uldaman is untouched.
        map->RemoveCreatureRespawnTime(spawnId);

        Creature* archaedas = new Creature();
        if (!archaedas->LoadCreatureFromDB(spawnId, map, true, true))
        {
            delete archaedas;
            error = "Could not load the original Archaedas DB spawn into private Uldaman.";
            return false;
        }

        if (!archaedas->IsInWorld() ||
            !archaedas->IsAlive() ||
            archaedas->GetEntry() != NPC_ULDAMAN_ARCHAEDAS)
        {
            archaedas->AddObjectToRemoveList();
            error = "Native Archaedas loaded but is not a living NPC 2748.";
            return false;
        }

        ManastormMgr::Instance().OnCreatureAddWorld(archaedas);
        if (run.GetObjectiveCreatureGuid() != archaedas->GetGUID())
        {
            archaedas->AddObjectToRemoveList();
            error = "Loaded native Archaedas failed Manastorm objective registration.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Loaded original Uldaman Archaedas in private Manastorm: "
            "run={} segment={} instance={} spawn={} guid={}.",
            run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
            spawnId, archaedas->GetGUID().GetRawValue());
        return true;
    }

    bool ActivateUldamanArchaedasEncounter(
        Player* player,
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        if (!IsUldamanArchaedasStage(run.GetSegment()))
            return true;

        if (!player ||
            !map ||
            map->GetId() != MANASTORM_MAP_ULDAMAN ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            run.GetState() != ManastormRunState::Active)
        {
            error = "Archaedas awakening requested outside the active private Uldaman stage.";
            return false;
        }

        InstanceMap* instanceMap = map->ToInstanceMap();
        InstanceScript* instance =
            instanceMap ? instanceMap->GetInstanceScript() : nullptr;

        if (!instance)
        {
            error = "Uldaman's native instance script was not available for Archaedas.";
            return false;
        }

        if (instance->GetData(DATA_ULDAMAN_ARCHAEDAS) == DONE)
        {
            error = "Uldaman reports Archaedas already defeated before Manastorm activation.";
            return false;
        }

        if (instance->GetData(DATA_ULDAMAN_ARCHAEDAS) == IN_PROGRESS)
            return true;

        ObjectGuid const guid = run.GetObjectiveCreatureGuid();
        Creature* archaedas =
            guid.IsEmpty() ? nullptr : ObjectAccessor::GetCreature(*player, guid);

        if (!archaedas ||
            !archaedas->IsInWorld() ||
            !archaedas->IsAlive() ||
            archaedas->GetEntry() != NPC_ULDAMAN_ARCHAEDAS ||
            !archaedas->AI())
        {
            error = "Original Archaedas is not available for his native altar awakening.";
            return false;
        }

        // These are the exact two native operations performed by
        // spell_uldaman_boss_agro_archaedas, in the same order.
        // Start only when the protection bubble has been cleared.
        // Keep the original Stoned aura, SmartAI transition, combat
        // abilities and instance-door state under native ownership.
        instance->SetData(DATA_ULDAMAN_ARCHAEDAS, IN_PROGRESS);
        archaedas->AI()->SetData(1, 1);

        LOG_INFO(LOG_FILTER,
            "Activated native Uldaman Archaedas altar sequence in "
            "private Manastorm: run={} segment={} instance={} guid={}.",
            run.GetRunId(), run.GetSegment().SegmentId,
            run.GetInstanceId(), guid.GetRawValue());
        return true;
    }

    bool BootstrapMaraudonMeshlokEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_MARAUDON ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_MARAUDON ||
            segment.ObjectiveCreatureEntry != NPC_MARAUDON_MESHLOK ||
            !((segment.SegmentId == SEGMENT_MESHLOK_NORMAL &&
               segment.Difficulty == 0 &&
               segment.DungeonEncounterId == 9997) ||
              (segment.SegmentId == SEGMENT_MESHLOK_ENDGAME &&
               segment.Difficulty == 2 &&
               segment.DungeonEncounterId == 2621)))
        {
            error = "Meshlok bootstrap received a nonmatching private Maraudon stage.";
            return false;
        }

        // The user's teleport is an arrival point, not Meshlok's
        // spawn. Select the real native DB record nearest that arrival.
        // This also handles databases containing multiple rare locations.
        GameTele const* entrance =
            sObjectMgr->GetGameTele(segment.StartGameTeleId);
        if (!entrance || entrance->mapId != MANASTORM_MAP_MARAUDON)
        {
            error = "Meshlok is missing his Maraudon arrival teleport.";
            return false;
        }

        QueryResult result = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` "
            "FROM `creature` "
            "WHERE `map` = 349 AND `id` = 12237 "
            "AND (`spawnMask` & 1) <> 0 "
            "ORDER BY POW(`position_x` - {}, 2) + "
            "POW(`position_y` - {}, 2), `guid` LIMIT 1",
            entrance->position_x, entrance->position_y);

        if (!result)
        {
            error = "Native Meshlok (12237) spawn not found in Maraudon world DB.";
            return false;
        }

        Field* fields = result->Fetch();
        ObjectGuid::LowType const spawnId = fields[0].Get<uint32>();
        float const spawnX = fields[1].Get<float>();
        float const spawnY = fields[2].Get<float>();

        CreatureData const* spawnData = sObjectMgr->GetCreatureData(spawnId);
        if (!spawnData ||
            spawnData->mapid != MANASTORM_MAP_MARAUDON ||
            spawnData->id != NPC_MARAUDON_MESHLOK)
        {
            error = "Meshlok's native DB spawn does not resolve to NPC 12237 on map 349.";
            return false;
        }

        map->LoadGrid(spawnX, spawnY);

        // Reuse a living native rare already loaded in this instance.
        // A private-map-local index is safe; do not scan other maps
        // or create duplicate creatures in the same dungeon copy.
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* existing = spawn.second;
            if (!existing ||
                !existing->IsInWorld() ||
                !existing->IsAlive() ||
                existing->GetEntry() != NPC_MARAUDON_MESHLOK)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(existing);
            if (run.GetObjectiveCreatureGuid() != existing->GetGUID())
            {
                error = "Existing native Meshlok did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Reused native Maraudon Meshlok in private Manastorm: "
                "run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                existing->GetSpawnId(),
                existing->GetGUID().GetRawValue());
            return true;
        }

        // A rare may be missing due to respawn or pool selection.
        // Clear ONLY this scripted-private stage's transient respawn
        // timer, and instantiate the original DB GUID at its home.
        // Leave normal Maraudon untouched.
        map->RemoveCreatureRespawnTime(spawnId);

        Creature* meshlok = new Creature();
        if (!meshlok->LoadCreatureFromDB(spawnId, map, true, true))
        {
            delete meshlok;
            error = "Failed loading native Meshlok DB spawn into private Maraudon.";
            return false;
        }

        if (!meshlok->IsInWorld() ||
            !meshlok->IsAlive() ||
            meshlok->GetEntry() != NPC_MARAUDON_MESHLOK)
        {
            meshlok->AddObjectToRemoveList();
            error = "Meshlok DB spawn loaded but did not create a living NPC 12237.";
            return false;
        }

        ManastormMgr::Instance().OnCreatureAddWorld(meshlok);
        if (run.GetObjectiveCreatureGuid() != meshlok->GetGUID())
        {
            meshlok->AddObjectToRemoveList();
            error = "Native Meshlok failed to register as the Manastorm objective.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Restored native Maraudon rare Meshlok in private Manastorm: "
            "run={} segment={} instance={} spawn={} guid={}.",
            run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
            spawnId, meshlok->GetGUID().GetRawValue());
        return true;
    }

    bool BootstrapRazorfenDownsRagglesnoutEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_RAZORFEN_DOWNS ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_RAZORFEN_DOWNS ||
            segment.ObjectiveCreatureEntry != NPC_RAGGLESNOUT ||
            !((segment.SegmentId == SEGMENT_RAGGLESNOUT_NORMAL &&
               segment.Difficulty == 0 &&
               segment.DungeonEncounterId == 9999) ||
              (segment.SegmentId == SEGMENT_RAGGLESNOUT_ENDGAME &&
               segment.Difficulty == 2 &&
               segment.DungeonEncounterId == 2619)))
        {
            error = "Ragglesnout bootstrap received a nonmatching private Razorfen Downs stage.";
            return false;
        }

        // In an ordinary Razorfen Downs instance, Ragglesnout is a
        // random rare. The recovered Manastorm segment explicitly
        // selects him, so this disposable private stage must ensure
        // the original spawn exists, without editing the common world
        // table or spawning a creature at the player's teleport.
        //
        // Look up actual native spawn coordinates/GUID at runtime.
        // The player's teleport is an arrival/reference point ONLY;
        // the original boss remains at the DB-authored spawn point.
        QueryResult result = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` "
            "FROM `creature` "
            "WHERE `map` = 129 AND `id` = 7354 "
            "AND (`spawnMask` & 1) <> 0 "
            "ORDER BY POW(`position_x` - {}, 2) + "
            "POW(`position_y` - {}, 2), `guid` LIMIT 1",
            2413.95f, 897.604f);

        if (!result)
        {
            error = "Native Ragglesnout (7354) spawn not found in the Razorfen Downs world DB.";
            return false;
        }

        Field* fields = result->Fetch();
        ObjectGuid::LowType const spawnId = fields[0].Get<uint32>();
        float const spawnX = fields[1].Get<float>();
        float const spawnY = fields[2].Get<float>();

        CreatureData const* spawnData = sObjectMgr->GetCreatureData(spawnId);
        if (!spawnData ||
            spawnData->mapid != MANASTORM_MAP_RAZORFEN_DOWNS ||
            spawnData->id != NPC_RAGGLESNOUT)
        {
            error = "Ragglesnout native spawn does not resolve to NPC 7354 on map 129.";
            return false;
        }

        map->LoadGrid(spawnX, spawnY);

        // Prefer an already-existing native creature, preserving its
        // DB spawn identity, rarity, movement and combat behavior.
        // The instance's object index is local, not a global map scan.
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* existing = spawn.second;
            if (!existing || !existing->IsInWorld() ||
                !existing->IsAlive() ||
                existing->GetEntry() != NPC_RAGGLESNOUT)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(existing);
            if (run.GetObjectiveCreatureGuid() != existing->GetGUID())
            {
                error = "Existing native Ragglesnout did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Reused native RFD rare Ragglesnout in private Manastorm: "
                "run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId,
                run.GetInstanceId(), existing->GetSpawnId(),
                existing->GetGUID().GetRawValue());
            return true;
        }

        // The selected rare may be absent due to its normal respawn
        // timer or pool selection. The Manastorm copy owns its own
        // disposable respawn state; never modify the live dungeon.
        map->RemoveCreatureRespawnTime(spawnId);

        Creature* ragglesnout = new Creature();
        if (!ragglesnout->LoadCreatureFromDB(
                spawnId, map, true, true))
        {
            delete ragglesnout;
            error = "Could not load native Ragglesnout DB spawn into private Razorfen Downs.";
            return false;
        }

        if (!ragglesnout->IsInWorld() ||
            !ragglesnout->IsAlive() ||
            ragglesnout->GetEntry() != NPC_RAGGLESNOUT)
        {
            ragglesnout->AddObjectToRemoveList();
            error = "Ragglesnout DB spawn loaded but did not create a living NPC 7354.";
            return false;
        }

        ManastormMgr::Instance().OnCreatureAddWorld(ragglesnout);
        if (run.GetObjectiveCreatureGuid() != ragglesnout->GetGUID())
        {
            ragglesnout->AddObjectToRemoveList();
            error = "Native Ragglesnout failed to register as the Manastorm objective.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Restored native RFD Ragglesnout rare for private Manastorm: "
            "run={} segment={} instance={} spawn={} guid={}.",
            run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
            spawnId, ragglesnout->GetGUID().GetRawValue());
        return true;
    }

    bool BootstrapRazorfenDownsPlaguemawEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_RAZORFEN_DOWNS ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_RAZORFEN_DOWNS ||
            segment.SegmentId != SEGMENT_PLAGUEMAW_ENDGAME ||
            segment.ObjectiveCreatureEntry != NPC_PLAGUEMAW_THE_ROTTING)
        {
            error = "Plaguemaw bootstrap received a nonmatching private Razorfen Downs stage.";
            return false;
        }

        // Plaguemaw is normally event-summoned by Belnistrasz's final
        // escort wave. In the recovered standalone Endgame Manastorm
        // stage, only the final original creature is needed, not the
        // escort, spawner (8611), or its preceding trash waves.
        // Load only the genuine arena grid and keep public RFD intact.
        map->LoadGrid(
            PLAGUEMAW_NATIVE_EVENT_POSITION.GetPositionX(),
            PLAGUEMAW_NATIVE_EVENT_POSITION.GetPositionY());

        // A prior native event/creature hook might already have
        // registered the objective in this private run.
        // Never intentionally create a second Plaguemaw.
        if (!run.GetObjectiveCreatureGuid().IsEmpty())
        {
            LOG_INFO(LOG_FILTER,
                "Reused registered Plaguemaw objective in private RFD: "
                "run={} segment={} instance={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                run.GetObjectiveCreatureGuid().GetRawValue());
            return true;
        }

        TempSummon* plaguemaw = map->SummonCreature(
            NPC_PLAGUEMAW_THE_ROTTING,
            PLAGUEMAW_NATIVE_EVENT_POSITION);

        if (!plaguemaw)
        {
            error = "Could not summon original Plaguemaw (7356) for private RFD Endgame stage.";
            return false;
        }

        plaguemaw->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);

        // The normal AddToMap hook normally registers TempSummon;
        // explicit duplicate-safe registration guarantees validation.
        ManastormMgr::Instance().OnCreatureAddWorld(plaguemaw);

        if (run.GetObjectiveCreatureGuid() != plaguemaw->GetGUID())
        {
            plaguemaw->DespawnOrUnsummon();
            error = "Summoned Plaguemaw failed to register as the private Manastorm objective.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Summoned original Plaguemaw for private RFD Endgame: "
            "run={} segment={} instance={} guid={}.",
            run.GetRunId(), segment.SegmentId,
            run.GetInstanceId(), plaguemaw->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapRazorfenDownsTutenKashEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_RAZORFEN_DOWNS ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.SegmentId != SEGMENT_TUTEN_KASH_ENDGAME ||
            segment.MapId != MANASTORM_MAP_RAZORFEN_DOWNS ||
            segment.ObjectiveCreatureEntry != NPC_TUTEN_KASH)
        {
            error = "Tuten'kash bootstrap received a nonmatching private Razorfen Downs stage.";
            return false;
        }

        // Regular RFD summons this boss only after the three gong waves.
        // This isolated Endgame Manastorm stage selects the final boss
        // directly. Disable interaction with the ORIGINAL gong in this
        // one instance, preventing the native waves from spawning a
        // second Tuten'kash after the direct objective summon.
        //
        // Obtain its real world DB coordinates and spawn ID; do not
        // change the shared gameobject rows or manipulate the RFD
        // instance's native gong progression.
        QueryResult nativeGong = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` "
            "FROM `gameobject` "
            "WHERE `map` = 129 AND `id` = 148917 "
            "AND (`spawnMask` & 1) <> 0 "
            "ORDER BY POW(`position_x` - 2514.93, 2) + "
            "POW(`position_y` - 882.652, 2), `guid` LIMIT 1");

        if (nativeGong)
        {
            Field* gongFields = nativeGong->Fetch();
            ObjectGuid::LowType const spawnId =
                gongFields[0].Get<uint32>();

            map->LoadGrid(
                gongFields[1].Get<float>(),
                gongFields[2].Get<float>());

            auto& objects = map->GetGameObjectBySpawnIdStore();
            auto const gongRange = objects.equal_range(spawnId);
            bool gongDisabled = false;

            for (auto itr = gongRange.first;
                 itr != gongRange.second; ++itr)
            {
                GameObject* gong = itr->second;
                if (!gong || !gong->IsInWorld() ||
                    gong->GetEntry() != GO_RFD_GONG)
                    continue;

                gong->SetGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
                gongDisabled = true;
            }

            if (!gongDisabled)
            {
                LOG_WARN(LOG_FILTER,
                    "Private RFD Tuten'kash gong could not be loaded: "
                    "run={} segment={} instance={} DBspawn={}.",
                    run.GetRunId(), segment.SegmentId,
                    run.GetInstanceId(), spawnId);
            }
        }
        else
        {
            // Missing gong does not prevent the objective from being
            // summoned; there is no native event to duplicate here.
            LOG_WARN(LOG_FILTER,
                "Private RFD Tuten'kash gong GO 148917 missing in world DB: "
                "run={} segment={} instance={}.",
                run.GetRunId(), segment.SegmentId,
                run.GetInstanceId());
        }

        // Prepare only the historical final-boss spawn grid. Normal
        // dungeon path, other RFD Manastorm stages, and public world
        // spawns remain untouched.
        map->LoadGrid(
            TUTEN_KASH_GONG_POSITION.GetPositionX(),
            TUTEN_KASH_GONG_POSITION.GetPositionY());

        // Avoid a replacement if an already-loaded persistent copy
        // exists in this private map.
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* creature = spawn.second;
            if (!creature || !creature->IsInWorld() ||
                !creature->IsAlive() ||
                creature->GetEntry() != NPC_TUTEN_KASH)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(creature);
            if (run.GetObjectiveCreatureGuid() != creature->GetGUID())
            {
                error = "Existing Tuten'kash did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Reused original Tuten'kash in private RFD: "
                "run={} segment={} instance={} guid={}.",
                run.GetRunId(), segment.SegmentId,
                run.GetInstanceId(), creature->GetGUID().GetRawValue());
            return true;
        }

        TempSummon* tutenKash = map->SummonCreature(
            NPC_TUTEN_KASH,
            TUTEN_KASH_GONG_POSITION);

        if (!tutenKash)
        {
            error = "Could not summon native Tuten'kash (7355) for private RFD Endgame stage.";
            return false;
        }

        tutenKash->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);
        ManastormMgr::Instance().OnCreatureAddWorld(tutenKash);

        if (run.GetObjectiveCreatureGuid() != tutenKash->GetGUID())
        {
            tutenKash->DespawnOrUnsummon();
            error = "Summoned Tuten'kash failed private Manastorm objective registration.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Summoned original Tuten'kash for private RFD Endgame: "
            "run={} segment={} instance={} guid={}.",
            run.GetRunId(), segment.SegmentId,
            run.GetInstanceId(), tutenKash->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapZulFarrakGahzrillaEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_ZUL_FARRAK ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_ZUL_FARRAK ||
            segment.ObjectiveCreatureEntry != NPC_GAHZRILLA ||
            (segment.SegmentId != SEGMENT_GAHZRILLA_NORMAL &&
             segment.SegmentId != SEGMENT_GAHZRILLA_ENDGAME))
        {
            error = "Gahz'rilla bootstrap received a nonmatching private Manastorm stage.";
            return false;
        }

        // The native boss is gong-summoned rather than a standing world
        // spawn. Prepare the genuine pool grid, not the whole instance.
        map->LoadGrid(
            GAHZRILLA_GONG_POSITION.GetPositionX(),
            GAHZRILLA_GONG_POSITION.GetPositionY());

        // Respect a boss that may already have been created by a DB gong
        // script in this isolated instance; never create a second objective.
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* existing = spawn.second;
            if (!existing || !existing->IsInWorld() ||
                !existing->IsAlive() ||
                existing->GetEntry() != NPC_GAHZRILLA)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(existing);
            if (run.GetObjectiveCreatureGuid() != existing->GetGUID())
            {
                error = "Existing Gahz'rilla failed Manastorm objective registration.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Reused existing Gahz'rilla for private Manastorm stage: "
                "run={} segment={} instance={} guid={}.",
                run.GetRunId(), segment.SegmentId,
                run.GetInstanceId(), existing->GetGUID().GetRawValue());
            return true;
        }

        TempSummon* gahzrilla = map->SummonCreature(
            NPC_GAHZRILLA,
            GAHZRILLA_GONG_POSITION);

        if (!gahzrilla)
        {
            error = "Failed to summon native Gahz'rilla (7273) in the private Zul'Farrak pool.";
            return false;
        }

        gahzrilla->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);

        // Registration is duplicate-safe: OnCreatureAddWorld may already
        // have run from the creature's normal world-add hook.
        ManastormMgr::Instance().OnCreatureAddWorld(gahzrilla);
        if (run.GetObjectiveCreatureGuid() != gahzrilla->GetGUID())
        {
            gahzrilla->DespawnOrUnsummon();
            error = "Summoned Gahz'rilla did not register as the private Manastorm objective.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Summoned native Gahz'rilla for private Manastorm stage: "
            "run={} segment={} instance={} guid={}.",
            run.GetRunId(), segment.SegmentId,
            run.GetInstanceId(), gahzrilla->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapZulFarrakVelrathaEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        error.clear();

        ManastormSegment const& segment = run.GetSegment();
        if (!map ||
            map->GetId() != MANASTORM_MAP_ZUL_FARRAK ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_ZUL_FARRAK ||
            segment.ObjectiveCreatureEntry != NPC_HYDROMANCER_VELRATHA ||
            (segment.SegmentId != SEGMENT_VELRATHA_NORMAL &&
             segment.SegmentId != SEGMENT_VELRATHA_ENDGAME))
        {
            error = "Hydromancer Velratha bootstrap received a nonmatching private Manastorm stage.";
            return false;
        }

        // Velratha naturally patrols the Gahz'rilla pool. Unlike Gahz'rilla
        // she is a persistent native DB creature, NOT a gong summon.
        // Read her actual map-209 spawn; never invent boss coordinates or
        // replace her native movement AI with a stationary duplicate.
        QueryResult nativeSpawn = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` "
            "FROM `creature` "
            "WHERE `map` = 209 AND `id` = 7795 "
            "AND (`spawnMask` & 1) <> 0 "
            "ORDER BY POW(`position_x` - 1706.51, 2) + "
            "POW(`position_y` - 1161.51, 2), `guid` "
            "LIMIT 1");

        if (!nativeSpawn)
        {
            error = "No native Hydromancer Velratha (7795) creature spawn exists on map 209; provide a verified DB spawn before creating a replacement.";
            return false;
        }

        Field* fields = nativeSpawn->Fetch();
        ObjectGuid::LowType const spawnId =
            fields[0].Get<uint32>();
        float const spawnX = fields[1].Get<float>();
        float const spawnY = fields[2].Get<float>();

        CreatureData const* spawnData =
            sObjectMgr->GetCreatureData(spawnId);
        if (!spawnData ||
            spawnData->mapid != MANASTORM_MAP_ZUL_FARRAK ||
            spawnData->id != NPC_HYDROMANCER_VELRATHA)
        {
            error = "Native Hydromancer Velratha DB GUID does not resolve to creature 7795 on map 209.";
            return false;
        }

        // Load only the original boss's grid, not the dungeon.
        map->LoadGrid(spawnX, spawnY);

        auto& spawned = map->GetCreatureBySpawnIdStore();
        auto const range = spawned.equal_range(spawnId);
        for (auto itr = range.first; itr != range.second; ++itr)
        {
            Creature* velratha = itr->second;
            if (!velratha || !velratha->IsInWorld() ||
                !velratha->IsAlive() ||
                velratha->GetEntry() != NPC_HYDROMANCER_VELRATHA)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(velratha);
            if (run.GetObjectiveCreatureGuid() != velratha->GetGUID())
            {
                error = "Native Hydromancer Velratha loaded but did not register as the Manastorm objective.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Reused native Hydromancer Velratha in private Manastorm: "
                "run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                spawnId, velratha->GetGUID().GetRawValue());
            return true;
        }

        // An isolated fresh stage must not be blocked by an inherited
        // respawn timer. Restore the *same* original DB creature only here.
        map->RemoveCreatureRespawnTime(spawnId);

        Creature* velratha = new Creature();
        if (!velratha->LoadCreatureFromDB(spawnId, map, true, true))
        {
            delete velratha;
            error = "Could not load the native Hydromancer Velratha DB spawn in private Zul'Farrak.";
            return false;
        }

        if (!velratha->IsInWorld() || !velratha->IsAlive() ||
            velratha->GetEntry() != NPC_HYDROMANCER_VELRATHA)
        {
            velratha->AddObjectToRemoveList();
            error = "Restored native Hydromancer Velratha is not a living creature 7795.";
            return false;
        }

        ManastormMgr::Instance().OnCreatureAddWorld(velratha);
        if (run.GetObjectiveCreatureGuid() != velratha->GetGUID())
        {
            velratha->AddObjectToRemoveList();
            error = "Restored Hydromancer Velratha failed Manastorm objective registration.";
            return false;
        }

        LOG_INFO(LOG_FILTER,
            "Restored native Hydromancer Velratha in private Manastorm: "
            "run={} segment={} instance={} spawn={} guid={}.",
            run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
            spawnId, velratha->GetGUID().GetRawValue());

        return true;
    }

    bool BootstrapStratholmeUnforgivenEncounter(
        Map* map, ManastormRun& run, std::string& error)
    {
        error.clear();
        ManastormSegment const& segment = run.GetSegment();

        if (!map ||
            map->GetId() != MANASTORM_MAP_STRATHOLME ||
            !map->IsScriptedPrivateInstance() ||
            map->GetInstanceId() != run.GetInstanceId() ||
            segment.MapId != MANASTORM_MAP_STRATHOLME ||
            segment.ObjectiveCreatureEntry != NPC_STRATHOLME_UNFORGIVEN ||
            !((segment.SegmentId == SEGMENT_UNFORGIVEN_NORMAL &&
               segment.Difficulty == 0 && segment.DungeonEncounterId == 472) ||
              (segment.SegmentId == SEGMENT_UNFORGIVEN_ENDGAME &&
               segment.Difficulty == 2 && segment.DungeonEncounterId == 2472)))
        {
            error = "The Unforgiven bootstrap received a nonmatching private Stratholme stage.";
            return false;
        }

        GameTele const* entrance = sObjectMgr->GetGameTele(segment.StartGameTeleId);
        if (!entrance || entrance->mapId != MANASTORM_MAP_STRATHOLME)
        {
            error = "The Unforgiven is missing the authored Stratholme arrival teleport.";
            return false;
        }

        // Prefer a real native creature spawn, if the server DB has one.
        QueryResult result = WorldDatabase.Query(
            "SELECT `guid`, `position_x`, `position_y` FROM `creature` "
            "WHERE `map` = 329 AND `id` = 10516 AND (`spawnMask` & 1) <> 0 "
            "ORDER BY POW(`position_x` - 3721.607, 2) + "
            "POW(`position_y` + 3424.507, 2), `guid` LIMIT 1");

        ObjectGuid::LowType nativeSpawnId = 0;
        float spawnX = UNFORGIVEN_REPORTED_GATE_POSITION.GetPositionX();
        float spawnY = UNFORGIVEN_REPORTED_GATE_POSITION.GetPositionY();

        if (result)
        {
            Field* fields = result->Fetch();
            nativeSpawnId = fields[0].Get<uint32>();
            spawnX = fields[1].Get<float>();
            spawnY = fields[2].Get<float>();

            CreatureData const* data = sObjectMgr->GetCreatureData(nativeSpawnId);
            if (!data || data->mapid != MANASTORM_MAP_STRATHOLME ||
                data->id != NPC_STRATHOLME_UNFORGIVEN)
            {
                error = "Native Unforgiven world-DB spawn is not creature 10516 in Stratholme.";
                return false;
            }
        }

        map->LoadGrid(spawnX, spawnY);

        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* existing = spawn.second;
            if (!existing || !existing->IsInWorld() ||
                !existing->IsAlive() ||
                existing->GetEntry() != NPC_STRATHOLME_UNFORGIVEN)
                continue;

            ManastormMgr::Instance().OnCreatureAddWorld(existing);
            if (run.GetObjectiveCreatureGuid() != existing->GetGUID())
            {
                error = "Existing native Unforgiven failed private Manastorm objective registration.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Reused original Stratholme Unforgiven: run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                existing->GetSpawnId(), existing->GetGUID().GetRawValue());
            return true;
        }

        if (nativeSpawnId)
        {
            // Only clear respawn data in this run's disposable private map.
            map->RemoveCreatureRespawnTime(nativeSpawnId);

            Creature* original = new Creature();
            if (!original->LoadCreatureFromDB(nativeSpawnId, map, true, true))
            {
                delete original;
                error = "Failed to load native Unforgiven spawn into private Stratholme.";
                return false;
            }

            if (!original->IsInWorld() || !original->IsAlive() ||
                original->GetEntry() != NPC_STRATHOLME_UNFORGIVEN)
            {
                original->AddObjectToRemoveList();
                error = "Loaded Stratholme Unforgiven is not a living creature 10516.";
                return false;
            }

            ManastormMgr::Instance().OnCreatureAddWorld(original);
            if (run.GetObjectiveCreatureGuid() != original->GetGUID())
            {
                original->AddObjectToRemoveList();
                error = "Native Unforgiven failed private Manastorm registration.";
                return false;
            }

            LOG_INFO(LOG_FILTER,
                "Loaded native Unforgiven objective: run={} segment={} instance={} spawn={} guid={}.",
                run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
                nativeSpawnId, original->GetGUID().GetRawValue());
            return true;
        }

        // Some world databases spawn this boss only through the archway
        // event. Guarantee the objective in this private Manastorm stage.
        // The reported gate vicinity is a documented approximation.
        TempSummon* unforgiven = map->SummonCreature(
            NPC_STRATHOLME_UNFORGIVEN, UNFORGIVEN_REPORTED_GATE_POSITION);
        if (!unforgiven)
        {
            error = "Failed to summon The Unforgiven in the private Stratholme archway.";
            return false;
        }

        unforgiven->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);
        ManastormMgr::Instance().OnCreatureAddWorld(unforgiven);
        if (run.GetObjectiveCreatureGuid() != unforgiven->GetGUID())
        {
            unforgiven->DespawnOrUnsummon();
            error = "Summoned Unforgiven failed private Manastorm objective registration.";
            return false;
        }

        // The original ambush includes four Vengeful Phantoms. These
        // compact offsets are private-stage placements, not purported
        // Blizzard DB spawn coordinates; phantoms are never objectives.
        for (uint8 i = 0; i < 4; ++i)
        {
            float const dx = i < 2 ? -3.0f : 3.0f;
            float const dy = (i % 2) == 0 ? -3.0f : 3.0f;
            Position const position(
                UNFORGIVEN_REPORTED_GATE_POSITION.GetPositionX() + dx,
                UNFORGIVEN_REPORTED_GATE_POSITION.GetPositionY() + dy,
                UNFORGIVEN_REPORTED_GATE_POSITION.GetPositionZ(), 0.0f);

            if (TempSummon* phantom = map->SummonCreature(
                    NPC_STRATHOLME_VENGEFUL_PHANTOM, position))
            {
                phantom->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);
                ManastormMgr::Instance().OnCreatureAddWorld(phantom);
            }
        }

        LOG_INFO(LOG_FILTER,
            "Bootstrapped private Stratholme Unforgiven at reported archway: "
            "run={} segment={} instance={} guid={}.",
            run.GetRunId(), segment.SegmentId, run.GetInstanceId(),
            unforgiven->GetGUID().GetRawValue());
        return true;
    }

    bool BootstrapSpecialEncounter(
        Map* map,
        ManastormRun& run,
        std::string& error)
    {
        switch (run.GetSegment().SegmentId)
        {
        case SEGMENT_UNFORGIVEN_NORMAL:
        case SEGMENT_UNFORGIVEN_ENDGAME:
            return BootstrapStratholmeUnforgivenEncounter(map, run, error);

        case SEGMENT_MESHLOK_NORMAL:
        case SEGMENT_MESHLOK_ENDGAME:
            return BootstrapMaraudonMeshlokEncounter(
                map, run, error);

        case SEGMENT_IRONAYA_NORMAL:
        case SEGMENT_IRONAYA_ENDGAME:
            return BootstrapUldamanIronayaEncounter(
                map, run, error);

        case SEGMENT_ARCHAEDAS_NORMAL:
        case SEGMENT_ARCHAEDAS_ENDGAME:
            return BootstrapUldamanArchaedasEncounter(
                map, run, error);

        case SEGMENT_TUTEN_KASH_ENDGAME:
            return BootstrapRazorfenDownsTutenKashEncounter(
                map, run, error);

        case SEGMENT_PLAGUEMAW_ENDGAME:
            return BootstrapRazorfenDownsPlaguemawEncounter(
                map, run, error);

        case SEGMENT_RAGGLESNOUT_NORMAL:
        case SEGMENT_RAGGLESNOUT_ENDGAME:
            return BootstrapRazorfenDownsRagglesnoutEncounter(
                map, run, error);

        case SEGMENT_GAHZRILLA_NORMAL:
        case SEGMENT_GAHZRILLA_ENDGAME:
            return BootstrapZulFarrakGahzrillaEncounter(
                map, run, error);

        case SEGMENT_VELRATHA_NORMAL:
        case SEGMENT_VELRATHA_ENDGAME:
            return BootstrapZulFarrakVelrathaEncounter(
                map, run, error);

        case SEGMENT_HELNURATH_NORMAL:
        case SEGMENT_HELNURATH_ENDGAME:
            return BootstrapDireMaulHelnurathEncounter(
                map,
                run,
                error);

        case SEGMENT_RAZELIKH_NORMAL:
        case SEGMENT_RAZELIKH_ENDGAME:
            return BootstrapRazelikhEncounter(
                map,
                run,
                error);

        case SEGMENT_ATAL_ALARION_NORMAL:
        case SEGMENT_ATAL_ALARION_ENDGAME:
            return BootstrapSunkenTempleAtalAlarionEncounter(
                map,
                run,
                error);

        case SEGMENT_HAKKAR_NORMAL:
        case SEGMENT_HAKKAR_ENDGAME:
            return BootstrapSunkenTempleHakkarEncounter(
                map,
                run,
                error);

        case SEGMENT_JAMMALAN_NORMAL:
        case SEGMENT_JAMMALAN_ENDGAME:
            return BootstrapSunkenTempleJammalanEncounter(
                map,
                run,
                error);

        case SEGMENT_ERANIKUS_NORMAL:
        case SEGMENT_ERANIKUS_ENDGAME:
            return BootstrapSunkenTempleEranikusEncounter(
                map,
                run,
                error);

        case SEGMENT_BRIGHTWING_ENDGAME:
            return BootstrapWailingCavernsBrightwingEncounter(
                map,
                run,
                error);

        case SEGMENT_HALMGAR_ENDGAME:
            return BootstrapRazorfenKraulHalmgarEncounter(
                map,
                run,
                error);

        default:
            error.clear();
            return true;
        }
    }

    bool SuppressPreparingCompanionAttack(Unit* attacker, ManastormRun const& run, uint32& damage)
    {
        if (!attacker || attacker->IsPlayer() || run.GetState() != ManastormRunState::Preparing)
            return false;

        damage = 0;
        attacker->AttackStop();
        return true;
    }

    void ApplySafetyBubbleProtection(Unit* unit, ManastormRun const& run)
    {
        if (!unit || !unit->IsAlive() || !unit->IsInWorld() ||
            unit->GetMapId() != run.GetSegment().MapId || unit->GetInstanceId() != run.GetInstanceId() ||
            run.GetState() != ManastormRunState::Preparing)
            return;

        if (!unit->HasAura(SPELL_SAFETY_BUBBLE_HELPER))
            unit->CastSpell(unit, SPELL_SAFETY_BUBBLE_HELPER, true);
        if (Aura* aura = unit->GetAura(SPELL_SAFETY_BUBBLE_HELPER))
        {
            aura->SetMaxDuration(int32(run.GetPreparationProtectionRemainingMs()));
            aura->SetDuration(int32(run.GetPreparationProtectionRemainingMs()));
        }
    }

    void CaptureStageCompanions(Player* player, ManastormRun& run)
    {
        auto& saved = run.CompanionTransfers[player->GetGUID().GetCounter()];
        saved.clear();
        for (Unit* controlled : player->m_Controlled)
        {
            if (!controlled || !controlled->IsAlive() || !controlled->IsInWorld() ||
                controlled->GetOwnerGUID() != player->GetGUID() || controlled->GetCharmerGUID())
                continue;

            Creature* creature = controlled->ToCreature();
            if (!creature || (!creature->IsGuardian() && !creature->IsPet()))
                continue;

            Pet* pet = creature->ToPet();
            if (pet && !pet->isTemporarySummoned())
                continue;
            TempSummon* summon = creature->ToTempSummon();
            if (!pet && (!summon || !summon->m_Properties))
                continue;

            ManastormRun::CompanionTransfer state;
            state.Entry = creature->GetEntry();
            state.Spell = creature->GetUInt32Value(UNIT_CREATED_BY_SPELL);
            if (pet && (!state.Spell || !sSpellMgr->GetSpellInfo(state.Spell)))
                continue;
            state.Properties = summon && summon->m_Properties ? summon->m_Properties->Id : 0;
            state.RemainingMs = pet ? uint32(pet->GetDuration().count()) : summon->GetTimer();
            state.CapturedMs = getMSTime();
            state.SummonType = summon ? uint32(summon->GetSummonType()) : 0;
            state.HealthPct = creature->GetHealthPct();
            state.Power = creature->GetPower(creature->getPowerType());
            state.ReactState = uint8(creature->GetReactState());
            state.TemporaryPet = pet != nullptr;
            saved.push_back(state);
        }
    }

    void RestoreStageCompanions(Player* player, ManastormRun& run)
    {
        auto found = run.CompanionTransfers.find(player->GetGUID().GetCounter());
        if (found == run.CompanionTransfers.end() || !player->IsAlive())
            return;

        auto saved = std::move(found->second);
        run.CompanionTransfers.erase(found);
        for (auto const& state : saved)
        {
            uint32 const elapsed = getMSTimeDiff(state.CapturedMs, getMSTime());
            if (state.RemainingMs && elapsed >= state.RemainingMs)
                continue;
            uint32 const remaining = state.RemainingMs ? state.RemainingMs - elapsed : 0;
            Creature* restored = nullptr;
            if (state.TemporaryPet)
            {
                if (player->GetPet() || player->GetTemporaryUnsummonedPetNumber())
                    continue;
                player->CastSpell(player, state.Spell, true);
                if (Pet* pet = player->GetPet())
                {
                    if (pet->GetEntry() != state.Entry)
                        continue;
                    pet->SetDuration(Milliseconds(remaining));
                    restored = pet;
                }
            }
            else
            {
                SummonPropertiesEntry const* properties = sSummonPropertiesStore.LookupEntry(state.Properties);
                if (!properties)
                    continue;
                if (TempSummon* summon = player->GetMap()->SummonCreature(state.Entry, player->GetPosition(),
                        properties, remaining, player, state.Spell))
                {
                    summon->SetTempSummonType(TempSummonType(state.SummonType));
                    summon->SetTimer(remaining);
                    restored = summon;
                }
            }
            if (!restored)
                continue;
            restored->SetHealth(std::max(1u, restored->CountPctFromMaxHealth(state.HealthPct)));
            restored->SetPower(restored->getPowerType(), std::min(state.Power, restored->GetMaxPower(restored->getPowerType())));
            restored->SetReactState(ReactStates(state.ReactState));
            ApplySafetyBubbleProtection(restored, run);
        }
    }

    void ClearSafetyBubble(Player* player)
    {
        if (!player)
            return;

        for (Unit* companion : player->m_Controlled)
            if (companion && companion->GetOwnerGUID() == player->GetGUID())
                companion->RemoveAurasDueToSpell(SPELL_SAFETY_BUBBLE_HELPER);

        for (uint32 spellId :
            SAFETY_BUBBLE_CLEANUP_SPELLS)
        {
            player->RemoveDynObject(
                spellId);

            player->RemoveAurasDueToSpell(
                spellId);
        }
    }

    void DespawnCogsleyCompanion(Player* player)
    {
        if (!player)
            return;

        ObjectGuid const critterGuid =
            player->GetCritterGUID();

        if (critterGuid.IsEmpty())
            return;

        Creature* critter =
            ObjectAccessor::GetCreature(
                *player,
                critterGuid);

        if (!critter ||
            critter->GetEntry() != NPC_COGSLEY)
        {
            return;
        }

        critter->DespawnOrUnsummon();
    }

    // Recovered spell values:
    // each Chaotic Link gives +25% boss HP and +10% boss damage.
    constexpr double CHAOTIC_LINK_HEALTH_PER_STACK = 0.25;
    constexpr double CHAOTIC_LINK_DAMAGE_PER_STACK = 0.10;

    // Recovered Ascension Heart Proc chance for ordinary monsters.
    // The roll is owned by OnUnitDeath(), matching the kill-associated
    // trash Heart behavior while boss Hearts remain HP-threshold driven.
    constexpr uint32 HEART_TRASH_CHANCE_PCT = 75;

    // A death-triggered trash Heart is launched by a short-lived built-in
    // WORLD_TRIGGER. At the recovered 991507 speed, two seconds is ample
    // for the 10-20 yard projectile while leaving no persistent helper.
    constexpr uint32 HEART_PROJECTILE_LAUNCHER_LIFETIME_MS = 35000;
    constexpr uint32 HEART_PICKUP_ARM_DELAY_MS = 1000;
    constexpr uint32 HEART_PICKUP_CHECK_INTERVAL_MS = 500;
    constexpr float HEART_PICKUP_DISTANCE = 1.0f;

    constexpr float HEART_MIN_LANDING_DISTANCE = 10.0f;
    constexpr float HEART_MAX_LANDING_DISTANCE = 20.0f;
    constexpr float TWO_PI = 6.28318530717958647692f;
    uint64 MakeStageKey(uint32 mapId, uint32 instanceId)
    {
        return (uint64(mapId) << 32) | instanceId;
    }

    bool IsPlayerControlledCreature(Creature const* creature)
    {
        return creature &&
            (creature->IsControlledByPlayer() ||
                creature->IsCreatedByPlayer() ||
                creature->IsCharmedOwnedByPlayerOrPlayer());
    }

    uint8 ResolveCreatureLevel(
        std::vector<ObjectGuid::LowType> const& members,
        uint8 fallbackLevel)
    {
        uint8 resolvedLevel = fallbackLevel;
        bool foundConnectedMember = false;

        for (ObjectGuid::LowType memberGuid : members)
        {
            Player* member = ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(memberGuid));

            if (!member)
                continue;

            if (!foundConnectedMember)
            {
                resolvedLevel = member->GetLevel();
                foundConnectedMember = true;
                continue;
            }

            resolvedLevel = std::max(
                resolvedLevel,
                member->GetLevel());
        }

        return resolvedLevel;
    }

    uint32 ScaleUnsignedValue(uint32 value, double multiplier)
    {
        if (!value || multiplier == 1.0)
            return value;

        if (!std::isfinite(multiplier) || multiplier < 0.0)
            return value;

        double const scaled = std::round(double(value) * multiplier);

        return uint32(std::clamp(
            scaled,
            0.0,
            double(std::numeric_limits<uint32>::max())));
    }
    bool IsObjectiveBoss(
        Creature const* creature,
        ManastormRun const& run)
    {
        if (!creature)
            return false;

        ObjectGuid const objectiveGuid =
            run.GetObjectiveCreatureGuid();

        return !objectiveGuid.IsEmpty() &&
            creature->GetGUID() == objectiveGuid;
    }

    double GetChaoticLinkHealthMultiplier(
        ManastormRun const& run)
    {
        return 1.0 +
            (double(run.GetChaoticLinkStacks()) *
                CHAOTIC_LINK_HEALTH_PER_STACK);
    }

    double GetChaoticLinkDamageMultiplier(
        ManastormRun const& run)
    {
        return 1.0 +
            (double(run.GetChaoticLinkStacks()) *
                CHAOTIC_LINK_DAMAGE_PER_STACK);
    }

    void SyncChaoticLinkAura(
        Creature* boss,
        ManastormRun const& run)
    {
        if (!boss ||
            !IsObjectiveBoss(boss, run))
        {
            return;
        }

        uint8 const stacks =
            run.GetChaoticLinkStacks();

        if (!stacks)
        {
            boss->RemoveAurasDueToSpell(
                SPELL_CHAOTIC_LINK);

            return;
        }

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

        if (!aura)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm run {} failed to apply Chaotic Link spell {} "
                "to objective boss guid={}.",
                run.GetRunId(),
                SPELL_CHAOTIC_LINK,
                boss->GetGUID().GetRawValue());

            return;
        }

        if (aura->GetStackAmount() != stacks)
        {
            aura->SetStackAmount(
                stacks);
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} synchronized Chaotic Link on objective boss "
            "guid={}: stacks={} healthMultiplier={:.3f}x "
            "damageMultiplier={:.3f}x.",
            run.GetRunId(),
            boss->GetGUID().GetRawValue(),
            uint32(stacks),
            GetChaoticLinkHealthMultiplier(run),
            GetChaoticLinkDamageMultiplier(run));
    }
}

ManastormMgr& ManastormMgr::Instance()
{
    static ManastormMgr instance;
    return instance;
}

void ManastormMgr::SendClientState(
    Player* player,
    ManastormRun const* run) const
{
    if (ManastormModuleConfig::IsNativeClientMode())
    {
        ManastormClientBridge::Instance().SendState(player, run);
        return;
    }

    if (!player || !player->GetSession())
        return;

    std::ostringstream message;

    message << CLIENT_ADDON_PREFIX
        << "\tSTATE|";

    bool const active =
        run &&
        run->GetState() != ManastormRunState::Failed &&
        run->GetState() != ManastormRunState::Finished;

    if (!active)
    {
        message
            << "0|"       // active
            << "0|"       // depth
            << "NONE|"    // mode
            << "0|"       // encounter
            << "0|"       // chaotic links
            << "0|"       // chaotic health %
            << "0|"       // chaotic damage %
            << "0|"       // stage complete
            << "0|"       // XP bonus, tenths of 1%
            << "0|"       // reward %
            << "-1|"      // cache chance unavailable
            << "0|"       // guaranteed caches
            << "0";       // cache item
    }
    else
    {
        uint32 const links =
            run->GetChaoticLinkStacks();

        uint32 const chaoticHealthPct =
            links * 25;

        uint32 const chaoticDamagePct =
            links * 10;

        bool const stageComplete =
            run->GetState() ==
            ManastormRunState::StageComplete;

        //
        // Recovered Manastorm XP presentation curve:
        //
        // Depth 1 = +0.0%
        // Depth 2 = +0.3%
        // Depth 3 = +0.6%
        // Depth 4 = +0.9%
        //
        // Wire format stores tenths of one percent:
        //
        // 3  = 0.3%
        // 6  = 0.6%
        // 9  = 0.9%
        //
        uint64 const xpBonusTenths =
            GetEndlessExperienceBonusTenths(
                run->GetDepth());

        //
        // Existing Manastorm segment reward multiplier.
        //
        // 1.0 = 100%
        // 1.5 = 150%
        // 2.0 = 200%
        //
        uint32 const rewardPct =
            ScaleUnsignedValue(
                100,
                run->GetSegment().RewardMultiplier);

        //
        // Reward % and Cache Chance are independent systems.
        //
        // RewardMultiplier modifies applicable currency payout.
        // CacheChancePct is persistent bad-luck protection for the
        // next normal Manastorm Cache roll.
        //
        ManastormRewardStateSnapshot rewardState;
        std::string rewardError;

        int32 cacheChancePct = -1;
        uint32 guaranteedCaches =
            run->GetBonusCacheCount();

        uint32 cacheItemId = 0;

        if (!ManastormRewards::Instance()
            .ResolveCacheItemEntry(
                run->IsEndgame(),
                run->GetDepth(),
                uint32(
                    player->GetLevel()),
                cacheItemId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Unable to resolve addon Manastorm cache item for {}: "
                "track={} depth={} level={}.",
                player->GetGUID().GetCounter(),
                run->IsEndgame()
                    ? uint32(
                        ManastormTrackBits::Endgame)
                    : uint32(
                        ManastormTrackBits::Normal),
                run->GetDepth(),
                uint32(
                    player->GetLevel()));
        }

        if (ManastormRewards::Instance()
            .LoadState(
                player->GetGUID().GetCounter(),
                run->GetMode(),
                run->IsEndgame(),
                rewardState,
                rewardError))
        {
            cacheChancePct =
                int32(
                    rewardState.CacheChancePct);
        }
        else
        {
            LOG_ERROR(
                LOG_FILTER,
                "Unable to load Manastorm reward state for {}: {}",
                player->GetGUID().GetCounter(),
                rewardError);
        }

        message
            << "1|"
            << run->GetDepth()
            << "|"
            << std::string(
                ManastormModeName(
                    run->GetMode()))
            << "|"
            << run->GetSegment().DungeonEncounterId
            << "|"
            << links
            << "|"
            << chaoticHealthPct
            << "|"
            << chaoticDamagePct
            << "|"
            << (stageComplete ? 1 : 0)
            << "|"
            << xpBonusTenths
            << "|"
            << rewardPct
            << "|"
            << cacheChancePct
            << "|"
            << guaranteedCaches
            << "|"
            << cacheItemId;
    }

    WorldPacket packet;

    ChatHandler::BuildChatPacket(
        packet,
        CHAT_MSG_WHISPER,
        LANG_ADDON,
        player,
        player,
        message.str());

    player->GetSession()->SendPacket(
        &packet);
}

void ManastormMgr::SendClientProgression(
    Player* player) const
{
    if (ManastormModuleConfig::IsNativeClientMode())
    {
        ManastormClientBridge::Instance().SendProgression(player);
        return;
    }

    if (!player ||
        !player->GetSession())
    {
        return;
    }

    auto sendPayload =
        [player](std::string const& payload)
        {
            std::string const message =
                std::string(CLIENT_ADDON_PREFIX) +
                "\t" +
                payload;

            WorldPacket packet;

            ChatHandler::BuildChatPacket(
                packet,
                CHAT_MSG_WHISPER,
                LANG_ADDON,
                player,
                player,
                message);

            player->GetSession()->SendPacket(
                &packet);
        };

    ObjectGuid::LowType const characterGuid =
        player->GetGUID().GetCounter();

    ManastormBestCompletedDepths best;
    std::string error;

    if (!ManastormProgression::LoadBestCompletedDepths(
        characterGuid,
        best,
        error))
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to send Manastorm progression "
            "to character {}: {}",
            characterGuid,
            error);

        sendPayload(
            "PROGRESS_ERROR");

        return;
    }

    //
    // Outside an active run, entry-mode eligibility is
    // based on current group size.
    //
    uint32 memberCount = 1;

    if (Group* group =
        player->GetGroup())
    {
        memberCount =
            std::max<uint32>(
                1,
                group->GetMembersCount());
    }

    ManastormMode mode =
        ManastormModeForMemberCount(
            memberCount);

    //
    // If a run already exists, its mode remains
    // authoritative regardless of later roster changes.
    //
    if (ManastormRun const* run =
        GetRunFor(player))
    {
        mode =
            run->GetMode();
    }

    ManastormProgressionSnapshot snapshot;

    uint32 const snapshotEndgameLevel =
        std::max(
            60u,
            sWorld->getIntConfig(
                CONFIG_MAX_PLAYER_LEVEL));

    bool const snapshotEndgame =
        GetRunFor(player)
        ? GetRunFor(player)->IsEndgame()
        : player->GetLevel() >=
            snapshotEndgameLevel;

    if (!ManastormProgression::LoadSnapshot(
        characterGuid,
        mode,
        snapshotEndgame,
        snapshot,
        error))
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to send Manastorm checkpoint "
            "state to character {}: {}",
            characterGuid,
            error);

        sendPayload(
            "PROGRESS_ERROR");

        return;
    }

    std::vector<uint32> enterableDepths;

    ManastormProgression::BuildEnterableDepths(
        snapshot,
        enterableDepths);

    //
    // First packet:
    //
    // PROGRESS
    // |bestSolo
    // |bestDuo
    // |bestTrio
    // |bestGroup
    // |currentMode
    // |pendingIntroDepth
    // |numberOfEnterableLevels
    //
    std::ostringstream header;

    header
        << "PROGRESS|"
        << best.Solo
        << "|"
        << best.Duo
        << "|"
        << best.Trio
        << "|"
        << best.Group
        << "|"
        << std::string(
            ManastormModeName(mode))
        << "|"
        << snapshot.PendingIntroDepth
        << "|"
        << enterableDepths.size();

    sendPayload(
        header.str());

    //
    // Addon messages have a small payload ceiling.
    //
    // A deep Ascension-style character can eventually
    // have MANY checkpoints:
    //
    // 1, 6, 11, 16 ... 946 ...
    //
    // Therefore never put the complete list into one
    // message. Send safe chunks.
    //
    constexpr std::size_t LEVEL_CHUNK_LIMIT =
        180;

    std::string chunk;

    for (uint32 depth :
    enterableDepths)
    {
        std::string const token =
            std::to_string(depth);

        std::size_t const additionalSize =
            token.size() +
            (chunk.empty() ? 0 : 1);

        if (!chunk.empty() &&
            chunk.size() +
            additionalSize >
            LEVEL_CHUNK_LIMIT)
        {
            sendPayload(
                std::string("LEVELS|") +
                chunk);

            chunk.clear();
        }

        if (!chunk.empty())
            chunk += ",";

        chunk +=
            token;
    }

    if (!chunk.empty())
    {
        sendPayload(
            std::string("LEVELS|") +
            chunk);
    }

    //
    // Lets the addon know that all chunks belonging
    // to this progression response have arrived.
    //
    sendPayload(
        "LEVELS_END");
}

void ManastormMgr::SendUnlockToast(
    Player* player,
    uint32 messageId) const
{
    if (ManastormModuleConfig::IsNativeClientMode())
    {
        // Native Ascension resolves the presentation client-side from
        // MANASTORM_LEVEL_COMPLETED plus ManastormMessages.dbc.
        return;
    }

    if (!player ||
        !player->GetSession() ||
        !messageId)
    {
        return;
    }

    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "`icon`, "
            "`title`, "
            "`description` "
            "FROM `manastorm_unlock_message` "
            "WHERE `message_id` = {} "
            "LIMIT 1",
            messageId);

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm could not resolve "
            "unlock-toast message {}.",
            messageId);

        return;
    }

    Field* fields =
        result->Fetch();

    std::string const icon =
        fields[0].Get<std::string>();

    std::string const title =
        fields[1].Get<std::string>();

    std::string const description =
        fields[2].Get<std::string>();

    std::ostringstream payload;

    payload
        << "TOAST|"
        << messageId
        << "|"
        << EscapeEndlessAddonField(
            icon)
        << "|"
        << EscapeEndlessAddonField(
            title)
        << "|"
        << EscapeEndlessAddonField(
            description);

    std::string const payloadText =
        payload.str();

    //
    // I checked all 291 recovered messages.
    //
    // Longest recovered values are still safely
    // below this limit.
    //
    // If we later create unusually long UnderWorld
    // custom messages, we can add chunk transport
    // instead of silently truncating them.
    //
    if (payloadText.size() >
        ENDLESS_ADDON_PAYLOAD_LIMIT)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm unlock-toast message {} "
            "is too large for the current addon "
            "wire format: {} bytes.",
            messageId,
            payloadText.size());

        return;
    }

    std::string const message =
        std::string(
            CLIENT_ADDON_PREFIX) +
        "\t" +
        payloadText;

    WorldPacket packet;

    ChatHandler::BuildChatPacket(
        packet,
        CHAT_MSG_WHISPER,
        LANG_ADDON,
        player,
        player,
        message);

    player->GetSession()->SendPacket(
        &packet);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm sent Manastorm unlock "
        "toast message {} to character {}: {}",
        messageId,
        player->GetGUID().GetCounter(),
        title);
}

void ManastormMgr::BroadcastClientState(
    ManastormRun const& run) const
{
    for (ObjectGuid::LowType memberGuid :
    run.GetMembers())
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (!member)
            continue;

        SendClientState(
            member,
            &run);
    }
}

void ManastormMgr::SyncClientState(
    Player* player)
{
    if (!player)
        return;

    SendClientState(
        player,
        GetRunFor(player));

    //
    // REQUEST now mirrors Ascension's client contract:
    //
    // current run state
    // +
    // persistent best runs
    // +
    // server-authoritative enterable levels
    //
    SendClientProgression(
        player);
}

void ManastormMgr::OpenClientUI(
    Player* player) const
{
    if (ManastormModuleConfig::IsNativeClientMode())
    {
        SendClientState(player, GetRunFor(player));
        SendClientProgression(player);
        return;
    }

    if (!player ||
        !player->GetSession())
    {
        return;
    }

    WorldPacket packet;

    ChatHandler::BuildChatPacket(
        packet,
        CHAT_MSG_WHISPER,
        LANG_ADDON,
        player,
        player,
        "MANASTORM\tOPEN_UI");

    player->GetSession()->SendPacket(
        &packet);

    //
    // Immediately follow OPEN_UI with the authoritative
    // current Endless state.
    //
    SendClientState(
        player,
        GetRunFor(player));

    SendClientProgression(
        player);
}

bool ManastormMgr::ReloadData()
{
    if (!ManastormDataStore::Instance().Load())
        return false;

    if (!ManastormRewards::Instance().Load())
        return false;

    return ManastormGreedyDemon::Instance().Load();
}

uint64 ManastormMgr::BuildRunSeed(
    uint64 runId, ObjectGuid::LowType ownerGuid) const
{
    uint64 const now = uint64(GameTime::GetGameTime().count());
    return (now << 32) ^
        (uint64(ownerGuid) << 1) ^
        (runId * RUN_SEED_MIX);
}

bool ManastormMgr::IsPlayerInActiveEndlessStage(
    Player const* player) const
{
    if (!player)
        return false;

    ManastormRun const* run =
        GetRunFor(player);

    if (!run)
        return false;

    if (run->GetState() != ManastormRunState::Active &&
        run->GetState() != ManastormRunState::StageComplete)
    {
        return false;
    }

    Map const* map = player->FindMap();

    if (!map)
        return false;

    return
        map->GetId() ==
        run->GetSegment().MapId &&
        map->GetInstanceId() ==
        run->GetInstanceId();
}

bool ManastormMgr::IsPlayerInUsableEndlessStage(
    Player const* player) const
{
    if (!player)
        return false;

    ManastormRun const* run =
        GetRunFor(player);

    if (!run)
        return false;

    if (run->GetState() != ManastormRunState::Preparing &&
        run->GetState() != ManastormRunState::Active &&
        run->GetState() != ManastormRunState::StageComplete)
    {
        return false;
    }

    Map const* map = player->FindMap();

    if (!map)
        return false;

    return
        map->GetId() ==
        run->GetSegment().MapId &&
        map->GetInstanceId() ==
        run->GetInstanceId();
}

bool ManastormMgr::HasManastormPotionCharge(
    Player const* player) const
{
    if (!player)
        return false;

    auto const itr =
        _manastormPotionCharges.find(
            player->GetGUID().GetCounter());

    if (itr == _manastormPotionCharges.end())
        return false;

    return itr->second.Charges > 0;
}

bool ManastormMgr::ConsumeManastormPotionCharge(
    Player* player)
{
    if (!player ||
        !IsPlayerInUsableEndlessStage(player))
    {
        return false;
    }

    auto itr =
        _manastormPotionCharges.find(
            player->GetGUID().GetCounter());

    if (itr == _manastormPotionCharges.end() ||
        !itr->second.Charges)
    {
        return false;
    }

    ManastormPotionChargeState& state =
        itr->second;

    --state.Charges;

    if (state.Charges <
        ManastormBaseline::PotionMaxCharges &&
        !state.RechargeTimerMs)
    {
        state.RechargeTimerMs =
            ManastormBaseline::PotionRechargeMs;
    }

    SyncManastormPotionCharges(player);
    return true;
}

void ManastormMgr::SyncManastormPotionCharges(Player const* player) const
{
    if (!player)
        return;

    auto const itr = _manastormPotionCharges.find(player->GetGUID().GetCounter());
    if (!ManastormModuleConfig::Enabled() || !IsPlayerInActiveEndlessStage(player) ||
        itr == _manastormPotionCharges.end())
    {
        ManastormPotionClient::Reset(player);
        return;
    }

    ManastormPotionClient::Send(player, itr->second.Charges, itr->second.RechargeTimerMs);
}

bool ManastormMgr::IsValidRegenerationMatrixTarget(
    Player const* caster,
    Player const* target) const
{
    if (!caster ||
        !target ||
        !caster->IsInWorld() ||
        !target->IsInWorld() ||
        !caster->IsAlive() ||
        target->IsAlive())
    {
        return false;
    }

    ManastormRun const* run =
        GetRunFor(caster);

    ManastormRun const* targetRun =
        GetRunFor(target);

    //
    // Matrix may resurrect only another member of
    // the SAME authoritative Endless run.
    //
    if (!run ||
        !targetRun ||
        run != targetRun)
    {
        return false;
    }

    if (run->GetState() !=
        ManastormRunState::Active &&
        run->GetState() !=
        ManastormRunState::StageComplete)
    {
        return false;
    }

    ManastormSegment const& segment =
        run->GetSegment();

    //
    // Both players must physically belong to the exact
    // current disposable stage instance.
    //
    if (caster->GetMapId() != segment.MapId ||
        caster->GetInstanceId() !=
        run->GetInstanceId() ||
        target->GetMapId() != segment.MapId ||
        target->GetInstanceId() !=
        run->GetInstanceId())
    {
        return false;
    }

    return true;
}

bool ManastormMgr::ConsumeRegenerationMatrixCharge(
    Player* caster,
    Player* target)
{
    if (!caster || !target)
        return false;

    ManastormRun* run =
        GetRunFor(caster);

    ManastormRun* targetRun =
        GetRunFor(target);

    if (!run ||
        !targetRun ||
        run != targetRun)
    {
        return false;
    }

    if (run->GetState() !=
        ManastormRunState::Active &&
        run->GetState() !=
        ManastormRunState::StageComplete)
    {
        return false;
    }

    ManastormSegment const& segment =
        run->GetSegment();

    if (caster->GetMapId() != segment.MapId ||
        caster->GetInstanceId() !=
        run->GetInstanceId() ||
        target->GetMapId() != segment.MapId ||
        target->GetInstanceId() !=
        run->GetInstanceId())
    {
        return false;
    }

    if (!run->ConsumeResurrectionCharge())
        return false;

    uint32 const remaining =
        run->GetResurrectionCharges();

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} consumed one resurrection resource: "
        "caster={} target={} remaining={}/{}.",
        run->GetRunId(),
        caster->GetGUID().GetCounter(),
        target->GetGUID().GetCounter(),
        remaining,
        uint32(ManastormResurrection::MaxCharges));

    //
    // Useful immediately for testing and later the addon
    // will display this visually.
    //
    std::ostringstream message;

    message
        << "Manastorm: Resurrection Resources "
        << remaining
        << "/"
        << uint32(
            ManastormResurrection::MaxCharges)
        << ".";

    for (ObjectGuid::LowType memberGuid :
    run->GetMembers())
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (member)
            member->SendSystemMessage(
                message.str());
    }

    BroadcastClientState(
        *run);

    return true;
}

void ManastormMgr::FailRun(
    ManastormRun& run,
    std::string const& reason,
    ObjectGuid::LowType externalDepartureGuid,
    ManastormFailureExit failureExit)
{
    if (run.GetState() ==
        ManastormRunState::Failed ||
        run.GetState() ==
        ManastormRunState::Finished)
    {
        return;
    }

    //
    // Copy everything needed BEFORE the run object
    // is eventually erased.
    //
    uint64 const runId =
        run.GetRunId();

    uint32 const failedDepth =
        run.GetDepth();

    uint32 const stageMapId =
        run.GetSegment().MapId;

    uint32 const stageInstanceId =
        run.GetInstanceId();

    bool const hadPreviousStage =
        run.HasPreviousStage();

    uint32 const previousStageMapId =
        hadPreviousStage
        ? run.GetPreviousSegment().MapId
        : MAPID_INVALID;

    uint32 const previousStageInstanceId =
        hadPreviousStage
        ? run.GetPreviousInstanceId()
        : 0;

    std::vector<ObjectGuid::LowType> const members =
        run.GetMembers();

    for (ObjectGuid::LowType memberGuid : members)
        ManastormRewards::Instance().SettlePendingCurrency(memberGuid);

    run.SetState(
        ManastormRunState::Failed);

    //
    // A failed run must never proceed to another depth.
    //
    _transitionTimers.erase(
        runId);

    SetEndlessObjectiveSkull(
        run,
        ObjectGuid::Empty);

    //
    // Tell the addons the run is no longer active
    // before destroying runtime ownership.
    //
    BroadcastClientState(
        run);

    //
    // IMPORTANT:
    //
    // Remove ownership BEFORE any teleport occurs.
    //
    // OnPlayerEnterMap() fires after a far teleport.
    // Without removing these first, our own failure
    // ejection could be misread as another external
    // abandonment.
    //
    for (ObjectGuid::LowType memberGuid :
    members)
    {
        auto itr =
            _memberRunIds.find(
                memberGuid);

        if (itr !=
            _memberRunIds.end() &&
            itr->second == runId)
        {
            _memberRunIds.erase(
                itr);
        }
    }

    if (stageInstanceId)
    {
        _stageRunIds.erase(
            MakeStageKey(
                stageMapId,
                stageInstanceId));
    }

    for (ObjectGuid::LowType memberGuid :
    members)
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<
                HighGuid::Player>(
                    memberGuid));

        if (!member)
        {
            _manastormPotionCharges.erase(
                memberGuid);

            continue;
        }

        ManastormAffixEngine::Instance()
            .RemoveActivePlayerAffixes(
                member,
                run);

        RemoveBaselineRunItems(
            member,
            true);

        // Cogsley (80919) is a Manastorm-only non-combat companion.
        // Remove it before leaving the private stage so it cannot leak into
        // the normal world after a stop/failure teleport.
        DespawnCogsleyCompanion(
            member);

        // A terminal ejection can return to the same native map ID as the
        // private stage (for example private Kalimdor -> public Kalimdor).
        // Player::TeleportTo normally treats same-map movement as a near
        // teleport, which would leave the player inside the private instance.
        // Remember that we are leaving a scripted-private map before clearing
        // its routing metadata so the return teleport can be forced through
        // the far/world-transfer path.
        bool const leavingScriptedPrivateStage =
            member->IsInWorld() &&
            member->GetMap() &&
            member->GetMap()->IsScriptedPrivateInstance();

        RestoreOriginalDifficulties(member);
        member->ClearScriptedPrivateInstance();

        std::ostringstream failureMessage;

        failureMessage
            << "Manastorm: run failed";

        if (!reason.empty())
        {
            failureMessage
                << " - "
                << reason;
        }

        member->SendSystemMessage(
            failureMessage.str());

        //
        // External departure:
        //
        // Hearthstone, dungeon exit portal,
        // GM teleport, teleport spell, etc.
        //
        // That player has already successfully reached
        // another destination. Do NOT drag them back to
        // the location from which they entered Endless.
        //
        if (memberGuid ==
            externalDepartureGuid)
        {
            LOG_INFO(
                LOG_FILTER,
                "Manastorm run {} cleaned external "
                "departure for player {} at map={} "
                "instance={}; player was not returned "
                "to the saved entry position.",
                runId,
                memberGuid,
                member->GetMapId(),
                member->GetInstanceId());

            continue;
        }

        //
        // Normal failure / wipe.
        //
        // Stop combat before resurrection and ejection.
        //
        member->CombatStopWithPets(
            true);

        //
        // A failed Manastorm must never dump a corpse
        // back into the normal world.
        //
        // SOLO:
        //     player dies -> run fails -> resurrect.
        //
        // GROUP:
        //     entire group wipes -> resurrect every
        //     dead member before ejecting everybody.
        //
        if (!member->IsAlive())
        {
            member->ResurrectPlayer(
                1.0f,
                false);

            if (member->IsAlive())
            {
                member->SpawnCorpseBones();

                LOG_INFO(
                    LOG_FILTER,
                    "Manastorm resurrected player {} "
                    "after failed run {} before ejection.",
                    memberGuid,
                    runId);
            }
            else
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm could not resurrect "
                    "player {} after failed run {}.",
                    memberGuid,
                    runId);
            }
        }

        if (WorldLocation const* location = (run).GetReturnLocation(memberGuid))
        {
            member->m_recallMap = location->GetMapId();
            member->m_recallX = location->GetPositionX();
            member->m_recallY = location->GetPositionY();
            member->m_recallZ = location->GetPositionZ();
            member->m_recallO = location->GetOrientation();
        }

        uint32 returnMap =
            member->m_recallMap;

        float returnX =
            member->m_recallX;

        float returnY =
            member->m_recallY;

        float returnZ =
            member->m_recallZ;

        float returnO =
            member->m_recallO;

        char const* destinationName =
            "saved location";

        //
        // Native death/wipe failure:
        //
        // Ascension returns failed players to the faction Manastorm hub.
        // Resolve that destination from the persistent Teleport Pad spawn,
        // not from duplicated hard-coded XYZ coordinates.
        //
        // Other FailRun causes deliberately retain the saved pre-Manastorm
        // location, and StopRun() is completely separate below.
        //
        if (failureExit ==
            ManastormFailureExit::FactionHub)
        {
            uint8 const teamId =
                static_cast<uint8>(
                    member->GetTeamId());

            if (ManastormHubReturn const* hubReturn =
                ManastormDataStore::Instance()
                    .GetHubReturn(teamId))
            {
                returnMap =
                    hubReturn->MapId;

                returnX =
                    hubReturn->PositionX;

                returnY =
                    hubReturn->PositionY;

                returnZ =
                    hubReturn->PositionZ +
                    hubReturn->ZOffset;

                returnO =
                    hubReturn->Orientation;

                destinationName =
                    "faction Manastorm Teleport Pad";
            }
            else
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm failed run {} could not resolve "
                    "a faction hub return for player {} team_id={}; "
                    "falling back to the saved entry location.",
                    runId,
                    memberGuid,
                    uint32(teamId));
            }
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm ejecting player {} from "
            "failed run {} to {} "
            "map={} position=({}, {}, {}, {}).",
            memberGuid,
            runId,
            destinationName,
            returnMap,
            returnX,
            returnY,
            returnZ,
            returnO);

        if (!member->TeleportTo(
            returnMap,
            returnX,
            returnY,
            returnZ,
            returnO,
            0,
            nullptr,
            leavingScriptedPrivateStage))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm failed to eject player {} "
                "from failed run {} to {} "
                "map={} position=({}, {}, {}, {}).",
                memberGuid,
                runId,
                destinationName,
                returnMap,
                returnX,
                returnY,
                returnZ,
                returnO);

            member->SendSystemMessage(
                "Manastorm: the run failed, but "
                "ejecting you from the failed "
                "Manastorm did not succeed.");
        }
    }

    //
    // The failed run is now completely terminal.
    //
    // No stale member ownership.
    // No stale stage ownership.
    // No transition timer.
    // No runtime run object.
    //
    _transitionTimers.erase(
        runId);

    if (Map* stage =
        sMapMgr->FindMap(
            stageMapId,
            stageInstanceId))
    {
        if (stage->IsScriptedPrivateInstance())
            stage->RequestScriptedPrivateUnload();
    }

    if (hadPreviousStage &&
        previousStageMapId !=
            MAPID_INVALID &&
        previousStageInstanceId)
    {
        if (Map* previous =
            sMapMgr->FindMap(
                previousStageMapId,
                previousStageInstanceId))
        {
            if (previous->
                IsScriptedPrivateInstance())
            {
                previous->
                    RequestScriptedPrivateUnload();
            }
        }
    }

    ManastormVoiceOfMillhouse::ClearRun(
        runId);

    _runs.erase(
        runId);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} FAILED and was fully "
        "cleaned at depth {}: {}",
        runId,
        failedDepth,
        reason);
}

void ManastormMgr::HandlePlayerDeath(
    Player* player)
{
    if (!player)
        return;

    ManastormRun* run =
        GetRunFor(player);

    if (!run ||
        run->GetState() !=
        ManastormRunState::Active)
    {
        return;
    }

    ManastormSegment const& segment =
        run->GetSegment();

    //
    // Ignore deaths outside the exact owned stage.
    //
    if (player->GetMapId() !=
        segment.MapId ||
        player->GetInstanceId() !=
        run->GetInstanceId())
    {
        return;
    }

    ManastormVoiceOfMillhouse::OnPlayerDeath(
        *run);

    bool hasLivingMember = false;

    for (ObjectGuid::LowType memberGuid :
    run->GetMembers())
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (!member ||
            !member->IsInWorld() ||
            !member->IsAlive())
        {
            continue;
        }

        if (member->GetMapId() !=
            segment.MapId ||
            member->GetInstanceId() !=
            run->GetInstanceId())
        {
            continue;
        }

        hasLivingMember = true;
        break;
    }

    //
    // DUO / TRIO / GROUP:
    //
    // At least one living player remains, so the run stays
    // ACTIVE and the fallen player can be recovered with
    // the Regeneration Matrix.
    //
    if (hasLivingMember)
    {
        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} member {} died at depth {}. "
            "Run continues with {}/{} resurrection resources.",
            run->GetRunId(),
            player->GetGUID().GetCounter(),
            run->GetDepth(),
            uint32(
                run->GetResurrectionCharges()),
            uint32(
                ManastormResurrection::MaxCharges));

        return;
    }

    //
    // SOLO naturally reaches this branch immediately.
    //
    // Multiplayer reaches it only when every run member
    // in the stage is dead.
    //
    // Keep native membership until Leave/Release, so the death UI remains usable.
    // This state cannot advance or earn another stage reward.
    run->SetState(ManastormRunState::AwaitingExit);
    _transitionTimers.erase(run->GetRunId());
    SetEndlessObjectiveSkull(*run, ObjectGuid::Empty);
    BroadcastClientState(*run);

    for (ObjectGuid::LowType guid : run->GetMembers())
    {
        Player* member = ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(guid));
        if (member)
            member->SendSystemMessage(
                "Manastorm: your run has ended. Leave Manastorm or release spirit to return.");
    }
}

void ManastormMgr::GrantBaselineRunItems(
    Player* player)
{
    if (!player)
        return;

    ObjectGuid::LowType const playerGuid =
        player->GetGUID().GetCounter();

    //
    // IMPORTANT:
    // try_emplace means entering another depth does NOT reset
    // the Potion charges. The charge state survives the entire run.
    //
    _manastormPotionCharges.try_emplace(
        playerGuid);

    uint32 const items[] =
    {
        ManastormBaseline::ItemPotion,
        ManastormBaseline::ItemRegenerationMatrix,
        ManastormBaseline::ItemMagicalEscape
    };

    for (uint32 itemId : items)
    {
        if (player->HasItemCount(
            itemId,
            1,
            false))
        {
            continue;
        }

        if (!sObjectMgr->GetItemTemplate(itemId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm baseline item {} "
                "does not exist in item_template.",
                itemId);

            continue;
        }

        if (!player->AddItem(
            itemId,
            1))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm could not grant "
                "baseline item {} to player {}.",
                itemId,
                playerGuid);

            player->SendSystemMessage(
                "Manastorm: I could not place one "
                "of your Manastorm tools in your bags. "
                "Make sure you have free inventory space.");
        }
        else
        {
            _grantedBaselineItems[playerGuid]
                .insert(itemId);
        }
    }
}

void ManastormMgr::RemoveBaselineRunItems(
    Player* player,
    bool clearPotionState)
{
    if (!player)
        return;

    ClearSafetyBubble(player);
    ManastormPotionClient::Reset(player);

    uint32 const items[] =
    {
        ManastormBaseline::ItemPotion,
        ManastormBaseline::ItemRegenerationMatrix,
        ManastormBaseline::ItemMagicalEscape
    };

    ObjectGuid::LowType const playerGuid =
        player->GetGUID().GetCounter();

    auto grantedItr =
        _grantedBaselineItems.find(
            playerGuid);

    if (grantedItr !=
        _grantedBaselineItems.end())
    {
        for (uint32 itemId : items)
        {
            if (grantedItr->second.find(
                    itemId) ==
                grantedItr->second.end())
            {
                continue;
            }

            if (player->HasItemCount(
                itemId,
                1,
                false))
            {
                player->DestroyItemCount(
                    itemId,
                    1,
                    true);
            }
        }

        _grantedBaselineItems.erase(
            grantedItr);
    }

    if (clearPotionState)
    {
        _manastormPotionCharges.erase(
            playerGuid);
    }
}

void ManastormMgr::UpdateManastormPotionCharges(
    uint32 diff)
{
    for (auto itr =
        _manastormPotionCharges.begin();
        itr != _manastormPotionCharges.end();)
    {
        //
        // If the player no longer belongs to a run,
        // discard stale runtime charge state.
        //
        if (!GetRunForGuid(itr->first))
        {
            itr =
                _manastormPotionCharges.erase(itr);

            continue;
        }

        ManastormPotionChargeState& state =
            itr->second;

        if (state.Charges >=
            ManastormBaseline::PotionMaxCharges)
        {
            state.Charges =
                ManastormBaseline::PotionMaxCharges;

            state.RechargeTimerMs = 0;

            ++itr;
            continue;
        }

        uint8 const previousCharges = state.Charges;
        uint32 remainingDiff = diff;

        while (
            remainingDiff > 0 &&
            state.Charges <
            ManastormBaseline::PotionMaxCharges)
        {
            if (!state.RechargeTimerMs)
            {
                state.RechargeTimerMs =
                    ManastormBaseline::PotionRechargeMs;
            }

            if (remainingDiff <
                state.RechargeTimerMs)
            {
                state.RechargeTimerMs -=
                    remainingDiff;

                remainingDiff = 0;
                break;
            }

            remainingDiff -=
                state.RechargeTimerMs;

            ++state.Charges;

            if (state.Charges >=
                ManastormBaseline::PotionMaxCharges)
            {
                state.Charges =
                    ManastormBaseline::PotionMaxCharges;

                state.RechargeTimerMs = 0;
                break;
            }

            state.RechargeTimerMs =
                ManastormBaseline::PotionRechargeMs;
        }

        if (state.Charges != previousCharges)
            if (Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(itr->first)))
                SyncManastormPotionCharges(player);

        ++itr;
    }
}

void ManastormMgr::SpawnStagePortal(
    Map* map,
    ManastormRun& run,
    Position const& position)
{
    if (!map)
        return;

    if (Creature* previous =
        map->GetCreature(
            run.GetPortalGuid()))
    {
        previous->DespawnOrUnsummon();
    }

    run.SetPortalGuid(
        ObjectGuid::Empty);

    Position portalPosition =
        position;

    portalPosition.m_positionZ +=
        STAGE_PORTAL_Z_OFFSET;

    if (Creature* portal =
        map->SummonCreature(
            NPC_STAGE_PORTAL,
            portalPosition))
    {
        portal->SetFaction(35);
        portal->SetReactState(REACT_PASSIVE);

        //
        // 80910 is only an invisible visual/controller anchor.
        //
        // Creature::Create() preserves the +Z position supplied above, but a
        // normal creature remains subject to gravity and will settle back onto
        // the terrain. Keep this temporary controller suspended at the authored
        // portal height instead of turning it into a normal flying creature.
        //
        portal->SetDisableGravity(true);
        portal->SetHomePosition(portalPosition);

        //
        // The recovered creature itself is intentionally invisible.
        // Spell 93305 is the verified visible Manastorm portal effect.
        //
        portal->CastSpell(
            portal,
            SPELL_STAGE_PORTAL,
            true);

        run.SetPortalGuid(
            portal->GetGUID());

        LOG_INFO(
            LOG_FILTER,
            "Spawned recovered Manastorm stage portal for run {}: "
            "creature={} guid={} spell={} map={} instance={} "
            "position=({}, {}, {}, {}).",
            run.GetRunId(),
            NPC_STAGE_PORTAL,
            portal->GetGUID().GetRawValue(),
            SPELL_STAGE_PORTAL,
            portal->GetMapId(),
            portal->GetInstanceId(),
            portal->GetPositionX(),
            portal->GetPositionY(),
            portal->GetPositionZ(),
            portal->GetOrientation());
    }
    else
    {
        LOG_ERROR(
            LOG_FILTER,
            "Cannot summon recovered Manastorm stage portal creature {} "
            "for run {}.",
            NPC_STAGE_PORTAL,
            run.GetRunId());
    }
}

bool ManastormMgr::PrepareStage(
    Player* player,
    ManastormRun& run,
    std::string& error,
    ObjectGuid::LowType transferOnlyGuid)
{
    error.clear();

    if (!player || !player->GetSession())
    {
        error = "A connected player is required to prepare the stage.";
        return false;
    }

    ManastormSegment const& segment =
        run.GetSegment();

    GameTele const* tele =
        sObjectMgr->GetGameTele(
            segment.StartGameTeleId);

    if (!tele)
    {
        error = "The selected segment start GameTele no longer exists.";
        return false;
    }

    if (tele->mapId != segment.MapId)
    {
        error = "The selected segment GameTele points to a different map.";
        return false;
    }

    MapEntry const* mapEntry =
        sMapStore.LookupEntry(
            segment.MapId);

    if (!mapEntry)
    {
        error = "The selected segment map does not exist.";
        return false;
    }

    if (mapEntry->IsBattlegroundOrArena())
    {
        error = "Battleground/arena maps cannot be used as Manastorm stages.";
        return false;
    }

    if (mapEntry->Instanceable())
    {
        if (!mapEntry->IsDungeon())
        {
            error = "The selected instanceable map is not a supported dungeon/raid stage.";
            return false;
        }

        if (!sObjectMgr->GetInstanceTemplate(
                segment.MapId))
        {
            error = "The selected dungeon/raid map has no instance_template row.";
            return false;
        }
    }

    bool const transferAll =
        transferOnlyGuid == 0;

    std::set<ObjectGuid> memberGuids;
    std::vector<Player*> connected;
    Player* transferPlayer = nullptr;

    for (ObjectGuid::LowType guid :
        run.GetMembers())
    {
        ObjectGuid const fullGuid =
            ObjectGuid::Create<
                HighGuid::Player>(
                    guid);

        memberGuids.insert(
            fullGuid);

        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                fullGuid);

        bool const ready =
            member &&
            member->GetSession() &&
            member->IsInWorld() &&
            !member->IsBeingTeleported();

        if (!ready)
        {
            if (transferAll)
            {
                error =
                    "Every run member must be connected and ready before the initial stage transfer.";

                return false;
            }

            continue;
        }

        connected.push_back(
            member);

        if (guid ==
            transferOnlyGuid)
        {
            transferPlayer =
                member;
        }
    }

    if (connected.empty() ||
        connected.size() >
            ManastormLimits::MaxMembers)
    {
        error =
            "Private Manastorm stages require one to " +
            std::to_string(
                ManastormLimits::MaxMembers) +
            " connected member(s).";

        return false;
    }

    if (!transferAll &&
        !transferPlayer)
    {
        error =
            "The player using the stage portal is no longer ready to transfer.";

        return false;
    }

    ObjectGuid const owner =
        ObjectGuid::Create<
            HighGuid::Player>(
                run.GetOwnerGuid());

    for (Player* member :
        connected)
    {
        WorldLocation const* location =
            run.GetReturnLocation(
                member->GetGUID()
                    .GetCounter());

        if (!location)
        {
            error =
                "The run has no saved return location for a member.";

            return false;
        }

        member->PrepareScriptedPrivateInstance(
            segment.MapId,
            *location,
            owner,
            memberGuids,
            true);

        if (mapEntry->Instanceable())
        {
            if (mapEntry->IsRaid())
            {
                member->SetRaidDifficulty(
                    Difficulty(
                        segment.RuntimeDifficulty));
            }
            else
            {
                member->SetDungeonDifficulty(
                    Difficulty(
                        segment.RuntimeDifficulty));
            }
        }
    }

    run.SetState(
        ManastormRunState::Preparing);

    Map* destination =
        sMapMgr->CreateMap(
            segment.MapId,
            transferAll
            ? player
            : transferPlayer);

    if (!destination ||
        !destination->IsScriptedPrivateInstance())
    {
        error =
            "Unable to create the private Manastorm instance.";

        return false;
    }

    uint32 const instanceId =
        destination->GetInstanceId();

    run.SetInstanceId(
        instanceId);

    _stageRunIds[
        MakeStageKey(
            segment.MapId,
            instanceId)] =
        run.GetRunId();

    for (Player* member :
        connected)
    {
        member->SetScriptedPrivateInstanceId(
            instanceId);
    }

    for (Player* member :
        connected)
    {
        if (!transferAll &&
            member->GetGUID()
                .GetCounter() !=
                transferOnlyGuid)
        {
            continue;
        }

        CaptureStageCompanions(member, run);
        member->CombatStopWithPets(
            true);

        if (!member->TeleportTo(
                segment.MapId,
                tele->position_x,
                tele->position_y,
                tele->position_z,
                tele->orientation,
                TELE_TO_GM_MODE,
                nullptr,
                true))
        {
            error =
                "A member could not transfer to the private Manastorm instance.";

            return false;
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Prepared Manastorm run {} stage: segment={} map={} instance={} "
        "difficulty={} runtimeDifficulty={} tele={} immediateTransfer={} destination=({}, {}, {}, {}).",
        run.GetRunId(),
        segment.SegmentId,
        segment.MapId,
        instanceId,
        segment.Difficulty,
        segment.RuntimeDifficulty,
        segment.StartGameTeleId,
        transferAll
            ? 0
            : transferOnlyGuid,
        tele->position_x,
        tele->position_y,
        tele->position_z,
        tele->orientation);

    return true;
}

bool ManastormMgr::TransferMemberToCurrentStage(
    Player* player,
    ManastormRun& run,
    std::string& error)
{
    error.clear();

    if (!player ||
        !player->GetSession() ||
        !player->IsInWorld() ||
        player->IsBeingTeleported())
    {
        error =
            "The Manastorm member is not ready to transfer.";

        return false;
    }

    ObjectGuid::LowType const guid =
        player->GetGUID()
            .GetCounter();

    if (!run.IsPendingStageTransfer(
            guid))
    {
        return true;
    }

    ManastormSegment const& segment =
        run.GetSegment();

    if (player->GetMapId() ==
            segment.MapId &&
        player->GetInstanceId() ==
            run.GetInstanceId())
    {
        run.MarkStageTransferComplete(
            guid);

        return true;
    }

    GameTele const* tele =
        sObjectMgr->GetGameTele(
            segment.StartGameTeleId);

    WorldLocation const* location =
        run.GetReturnLocation(
            guid);

    Map* destination =
        sMapMgr->FindMap(
            segment.MapId,
            run.GetInstanceId());

    if (!tele ||
        !location ||
        !destination ||
        !destination->IsScriptedPrivateInstance() ||
        !destination->IsScriptedPrivateMember(
            player->GetGUID()))
    {
        error =
            "The prepared next Manastorm stage is no longer available.";

        return false;
    }

    std::set<ObjectGuid> memberGuids;

    for (ObjectGuid::LowType memberGuid :
        run.GetMembers())
    {
        memberGuids.insert(
            ObjectGuid::Create<
                HighGuid::Player>(
                    memberGuid));
    }

    MapEntry const* mapEntry =
        sMapStore.LookupEntry(
            segment.MapId);

    player->PrepareScriptedPrivateInstance(
        segment.MapId,
        *location,
        ObjectGuid::Create<
            HighGuid::Player>(
                run.GetOwnerGuid()),
        memberGuids,
        true);

    if (mapEntry &&
        mapEntry->Instanceable())
    {
        if (mapEntry->IsRaid())
        {
            player->SetRaidDifficulty(
                Difficulty(
                    segment.RuntimeDifficulty));
        }
        else
        {
            player->SetDungeonDifficulty(
                Difficulty(
                    segment.RuntimeDifficulty));
        }
    }

    player->SetScriptedPrivateInstanceId(
        run.GetInstanceId());

    player->CombatStopWithPets(
        true);

    if (!player->TeleportTo(
            segment.MapId,
            tele->position_x,
            tele->position_y,
            tele->position_z,
            tele->orientation,
            TELE_TO_GM_MODE,
            nullptr,
            true))
    {
        error =
            "The member could not transfer to the next Manastorm stage.";

        return false;
    }

    return true;
}

void ManastormMgr::FinishPreviousStageTransition(
    ManastormRun& run)
{
    if (!run.HasPreviousStage())
        return;

    uint32 const previousMapId =
        run.GetPreviousSegment()
            .MapId;

    uint32 const previousInstanceId =
        run.GetPreviousInstanceId();

    _stageRunIds.erase(
        MakeStageKey(
            previousMapId,
            previousInstanceId));

    if (Map* previous =
        sMapMgr->FindMap(
            previousMapId,
            previousInstanceId))
    {
        if (previous->
            IsScriptedPrivateInstance())
        {
            previous->
                RequestScriptedPrivateUnload();
        }
    }

    run.ClearPreviousStageTransition();
}

ManastormRun* ManastormMgr::StartRun(
    Player* player,
    uint32 depth,
    std::string& error,
    bool bypassCheckpoint,
    uint32 forcedSegmentId)
{
    error.clear();

    if (!ManastormModuleConfig::Enabled())
    {
        error = "Manastorm is disabled by configuration.";
        return nullptr;
    }

    if (!player || !player->GetSession())
    {
        error = "A connected player is required.";
        return nullptr;
    }

    if (!depth)
    {
        error = "Depth must be at least 1.";
        return nullptr;
    }

    if (!ManastormDataStore::Instance().IsLoaded() && !ReloadData())
    {
        error = "Manastorm datastore is not loaded. Apply the world SQL and check server logs.";
        return nullptr;
    }

    ManastormSegment const* authoringForcedSegment = nullptr;

    if (forcedSegmentId)
    {
        authoringForcedSegment =
            ManastormDataStore::Instance().GetSegmentById(
                forcedSegmentId);

        if (!authoringForcedSegment)
        {
            error =
                "Forced Manastorm segment " +
                std::to_string(forcedSegmentId) +
                " is not enabled/valid in the datastore.";
            return nullptr;
        }

        if (authoringForcedSegment->Difficulty != 0 &&
            authoringForcedSegment->Difficulty != 2)
        {
            error =
                "Forced Manastorm segment " +
                std::to_string(forcedSegmentId) +
                " has unsupported native difficulty " +
                std::to_string(
                    uint32(authoringForcedSegment->Difficulty)) +
                ".";
            return nullptr;
        }
    }

    std::vector<ObjectGuid::LowType> members;
    ObjectGuid::LowType ownerGuid = player->GetGUID().GetCounter();

    Group* group = player->GetGroup();
    if (group && group->GetMembersCount() > 1)
    {
        if (!group->IsLeader(player->GetGUID()))
        {
            error = "Only the group leader can start an Endless debug run.";
            return nullptr;
        }

        ownerGuid = group->GetLeaderGUID().GetCounter();

        for (Group::MemberSlot const& member : group->GetMemberSlots())
            members.push_back(member.guid.GetCounter());
    }
    else
    {
        members.push_back(player->GetGUID().GetCounter());
    }

    if (members.empty())
    {
        error = "No run members could be resolved.";
        return nullptr;
    }

    if (members.size() > ManastormLimits::MaxMembers)
    {
        error =
            "Manastorm supports up to " +
            std::to_string(ManastormLimits::MaxMembers) +
            " players.";
        return nullptr;
    }

    for (ObjectGuid::LowType memberGuid : members)
    {
        if (_memberRunIds.find(memberGuid) != _memberRunIds.end())
        {
            error = "At least one member already belongs to an active Manastorm run.";
            return nullptr;
        }
    }

    uint64 const runId =
        _nextRunId++;

    uint64 const seed =
        BuildRunSeed(
            runId,
            ownerGuid);

    ManastormMode const mode =
        ManastormModeForMemberCount(
            uint32(members.size()));

    //
    // Resolve the native stage track BEFORE selecting a segment.
    //
    // Patch-M Manastorm.dbc uses difficulty 0 for normal stages and
    // difficulty 2 for end-game stages. The old code calculated this only
    // after selection, which allowed the two native pools to mix.
    //
    bool endgame = false;
    uint32 const endgameLevel =
        std::max(
            60u,
            sWorld->getIntConfig(
                CONFIG_MAX_PLAYER_LEVEL));

    for (ObjectGuid::LowType memberGuid :
        members)
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (!member ||
            !member->IsInWorld() ||
            member->IsBeingTeleported())
        {
            error =
                "Every run member must be connected and ready.";

            return nullptr;
        }

        if (member->GetLevel() < 10)
        {
            error = "Every run member must be at least level 10 to enter Manastorm.";
            return nullptr;
        }

        endgame =
            endgame ||
            member->GetLevel() >=
                endgameLevel;
    }

    // GM authoring tests must be deterministic even when the GM character is
    // max level. The exact forced segment owns its native Normal/Endgame track.
    if (authoringForcedSegment)
        endgame =
            authoringForcedSegment->Difficulty == 2;

    ManastormProgressionSnapshot progression;

    if (!ManastormProgression::LoadSnapshot(
        ownerGuid,
        mode,
        endgame,
        progression,
        error))
    {
        return nullptr;
    }

    if (!bypassCheckpoint &&
        !ManastormProgression::IsDepthEnterable(
            progression,
            depth))
    {
        std::vector<uint32> enterableDepths;

        ManastormProgression::BuildEnterableDepths(
            progression,
            enterableDepths);

        std::ostringstream allowed;

        for (std::size_t index = 0;
            index < enterableDepths.size();
            ++index)
        {
            if (index)
                allowed << ", ";

            allowed << enterableDepths[index];
        }

        std::ostringstream message;

        message
            << "Depth "
            << depth
            << " is not an enterable Manastorm checkpoint "
            << "for "
            << ManastormModeName(mode)
            << ". Best completed depth="
            << progression.BestCompletedDepth
            << ". Enterable depths: "
            << allowed.str()
            << ".";

        error =
            message.str();

        return nullptr;
    }

    ManastormGenerator generator;

    uint32 const forcedIntroSegmentId =
        progression.PendingIntroDepth == depth
        ? (endgame
            ? progression.PendingEndgameIntroSegmentId
            : progression.PendingIntroSegmentId)
        : 0;

    uint32 const selectedForcedSegmentId =
        forcedSegmentId
        ? forcedSegmentId
        : forcedIntroSegmentId;

    ManastormSegment const* selected =
        generator.SelectSegment(
            depth,
            seed,
            progression.UnlockedSegmentIds,
            endgame,
            0,
            selectedForcedSegmentId);

    if (!selected)
    {
        error =
            "No accessible Manastorm segment is "
            "eligible for this depth.";

        return nullptr;
    }

    ManastormScalingPoint const scaling =
        ManastormDataStore::Instance()
        .GetScalingForDepth(
            depth,
            uint32(members.size()));

    uint8 const creatureLevel =
        ResolveCreatureLevel(
            members,
            player->GetLevel());

    //
    // Save the position the player occupied BEFORE
    // entering Manastorm.
    //
    // IMPORTANT:
    // This is deliberately done once at run creation,
    // never inside PrepareStage().
    //
    // Every later depth creates another disposable stage,
    // but leaving the entire run must return the player
    // to the location they originally entered from.
    //
    player->SaveRecallPosition();

    LOG_INFO(
        LOG_FILTER,
        "Manastorm saved return position for player {}: "
        "map={} position=({}, {}, {}, {}).",
        player->GetGUID().GetCounter(),
        player->m_recallMap,
        player->m_recallX,
        player->m_recallY,
        player->m_recallZ,
        player->m_recallO);

    auto run = std::make_unique<ManastormRun>(
        runId,
        seed,
        ownerGuid,
        members,
        mode,
        creatureLevel,
        depth,
        *selected,
        scaling);

    //
    // First-time VO uses the existing authoritative progression snapshot.
    // A character with no completed depth in the selected mode/track has not
    // yet completed a Manastorm run in that progression lane.
    //
    ManastormVoiceOfMillhouse::RegisterRun(
        runId,
        progression.BestCompletedDepth == 0);

    for (auto guid : members)
    {
        Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
        if (!member || !member->IsInWorld() || member->IsBeingTeleported())
        {
            error = "Every run member must be connected and ready.";
            return nullptr;
        }
        member->SaveRecallPosition();
        run->SaveReturnLocation(
            guid,
            WorldLocation(
                member->GetMapId(),
                member->GetPosition()));

        ManastormRun::GadgetSlots slots{};
        auto* loadoutStatement =
            CharacterDatabase.GetPreparedStatement(
                CHAR_SEL_MANASTORM_LOADOUT);

        loadoutStatement->SetData(
            0,
            guid);

        PreparedQueryResult loadout =
            CharacterDatabase.Query(
                loadoutStatement);

        if (loadout)
        {
            do
            {
                Field* fields =
                    loadout->Fetch();

                uint8 const slot =
                    fields[0].Get<uint8>();

                if (slot < slots.size())
                {
                    slots[slot] =
                        fields[1].Get<uint32>();
                }
            }
            while (loadout->NextRow());
        }

        run->SetMemberGadgetLoadout(
            guid,
            slots);
    }
    run->SetEndgame(endgame);

    ManastormAffixEngine::Instance()
        .InitializeStage(
            *run,
            progression.UnlockedAffixIds);

    // The run must be discoverable before stage preparation starts.
// Teleporting can initialize the destination instance and add creatures
// before StartRun() returns.
    ManastormRun* runPtr = run.get();
    _runs.emplace(runId, std::move(run));

    for (ObjectGuid::LowType memberGuid : runPtr->GetMembers())
        _memberRunIds[memberGuid] = runId;

    for (ObjectGuid::LowType guid : runPtr->GetMembers())
    {
        if (Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
            _originalDifficulties.emplace(guid,
                ManastormDifficultySettings{member->GetDungeonDifficulty(), member->GetRaidDifficulty()});
    }

    if (!PrepareStage(player, *runPtr, error))
    {
        FailRun(*runPtr, error);
        return nullptr;
    }

    LOG_INFO(LOG_FILTER,
        "Created Manastorm run {}: owner={} mode={} members={} depth={} "
        "segment={} map={} instance={} encounter={} objective={} tele={} seed={}.",
        runId,
        ownerGuid,
        ManastormModeName(mode),
        runPtr->GetMembers().size(),
        depth,
        selected->SegmentId,
        selected->MapId,
        runPtr->GetInstanceId(),
        selected->DungeonEncounterId,
        selected->ObjectiveCreatureEntry,
        selected->StartGameTeleId,
        seed);

    return runPtr;
}

void ManastormMgr::RestoreOriginalDifficulties(Player* player)
{
    auto const itr = _originalDifficulties.find(player->GetGUID().GetCounter());
    if (itr == _originalDifficulties.end())
        return;

    player->SetDungeonDifficulty(itr->second.Dungeon);
    player->SetRaidDifficulty(itr->second.Raid);
    _originalDifficulties.erase(itr);
}

void ManastormMgr::OnPlayerLogin(Player* player)
{
    if (!player || !player->GetSession())
        return;
    ManastormExperience::Instance().Settle(player);
    ManastormRun* run = GetRunFor(player);
    if (!run)
    {
        RestoreOriginalDifficulties(player);
        ManastormRewards::Instance().SettlePendingCurrency(player->GetGUID().GetCounter());
        RemoveBaselineRunItems(player, true);
        SendClientState(player, nullptr);
        return;
    }
    Map* map = sMapMgr->FindMap(run->GetSegment().MapId, run->GetInstanceId());
    WorldLocation const* location = run->GetReturnLocation(player->GetGUID().GetCounter());
    GameTele const* tele = sObjectMgr->GetGameTele(run->GetSegment().StartGameTeleId);
    if (!map || !map->IsScriptedPrivateInstance() || !location || !tele
        || !map->IsScriptedPrivateMember(player->GetGUID()))
    {
        FailRun(*run, "The private stage is no longer available for reconnect.");
        return;
    }
    std::set<ObjectGuid> members;
    for (auto guid : run->GetMembers())
        members.insert(ObjectGuid::Create<HighGuid::Player>(guid));
    player->m_recallMap = location->GetMapId();
    player->m_recallX = location->GetPositionX();
    player->m_recallY = location->GetPositionY();
    player->m_recallZ = location->GetPositionZ();
    player->m_recallO = location->GetOrientation();
    player->PrepareScriptedPrivateInstance(map->GetId(), *location,
        ObjectGuid::Create<HighGuid::Player>(run->GetOwnerGuid()), members, true);

    if (map->IsRaid())
        player->SetRaidDifficulty(Difficulty(run->GetSegment().RuntimeDifficulty));
    else
        player->SetDungeonDifficulty(Difficulty(run->GetSegment().RuntimeDifficulty));
    player->SetScriptedPrivateInstanceId(run->GetInstanceId());
    if (!player->TeleportTo(map->GetId(), tele->position_x, tele->position_y,
        tele->position_z, tele->orientation, TELE_TO_GM_MODE, nullptr, true))
        FailRun(*run, "Reconnect teleport failed.");
}

bool ManastormMgr::OnPlayerEnterMap(Map* map, Player* player)
{
    if (!map || !player)
        return false;

    if (player->GetSession() && player->GetSession()->PlayerLoading())
        return true;

    ManastormExperience::Instance().OnMapEntry(player);

    ManastormRun* run =
        GetRunFor(player);

    if (!run)
    {
        //
        // Also cleans stale temporary tools after a
        // server restart where no run survives.
        //
        RemoveBaselineRunItems(
            player,
            true);

        return false;
    }

    if (run->GetState() ==
        ManastormRunState::Failed ||
        run->GetState() ==
        ManastormRunState::Finished)
    {
        RemoveBaselineRunItems(
            player,
            true);

        return false;
    }

    if (map->GetId() !=
        run->GetSegment().MapId ||
        map->GetInstanceId() !=
        run->GetInstanceId())
    {
        //
        // Server-authorized stage movement must not be
        // mistaken for abandoning the run.
        //
        // During an Endless depth transition the run may
        // temporarily be Transitioning / Preparing while
        // the destination instance is being established.
        //
        if (run->GetState() ==
            ManastormRunState::Transitioning ||
            run->GetState() ==
            ManastormRunState::Preparing)
        {
            RemoveBaselineRunItems(
                player,
                false);

            return true;
        }

        //
        // Otherwise the player physically left the
        // authoritative Endless stage without using
        // Endless' own transition system.
        //
        // Examples:
        //
        // - Hearthstone
        // - mage/other teleport
        // - GM .tele
        // - normal dungeon exit portal
        // - any other external map/instance transfer
        //
        // The external teleport has already succeeded,
        // therefore FailRun receives this player's GUID
        // and will NOT teleport that player back again.
        //
        ObjectGuid::LowType const departingGuid =
            player->GetGUID().GetCounter();

        std::ostringstream reason;

        reason
            << "Player "
            << departingGuid
            << " left the active Endless stage.";

        FailRun(
            *run,
            reason.str(),
            departingGuid);

        return false;
    }

    if (run->HasPreviousStage() &&
        run->IsPendingStageTransfer(
            player->GetGUID().GetCounter()))
    {
        run->MarkStageTransferComplete(
            player->GetGUID().GetCounter());

        if (!run->HasPendingStageTransfers())
        {
            _transitionTimers.erase(
                run->GetRunId());

            FinishPreviousStageTransition(
                *run);
        }
    }

    //
    // Exact owned map + instance.
    //
    // Duplicate-safe. On later depths the existing three
    // items remain; they are NOT recreated or duplicated.
    //
    GrantBaselineRunItems(player);

    // Arrival hooks can repeat for reconnects. Reset each member once per floor.
    // The shared potion backend keeps ownership of its three-charge recharge state.
    if ((run->GetState() == ManastormRunState::Preparing ||
        run->GetState() == ManastormRunState::Active) &&
        run->MarkStageCooldownsReset(player->GetGUID().GetCounter()))
    {
        for (auto const& gadget : Ascension::Manastorm::Gadgets)
        {
            if (gadget.passive || !player->HasSpell(gadget.spell) ||
                gadget.spell == 254440 || gadget.spell == 992090 || gadget.spell == 762608)
                continue;

            player->RemoveSpellCooldown(gadget.spell, true);
        }

        player->RemoveActivePetSpellCooldowns();
    }

    ManastormSegment const& segment = run->GetSegment();
    if (map->GetId() != segment.MapId ||
        map->GetInstanceId() != run->GetInstanceId())
        return true;

    if (run->GetState() == ManastormRunState::Preparing || run->GetState() == ManastormRunState::Active)
        RestoreStageCompanions(player, *run);

    if (run->GetState() == ManastormRunState::Preparing)
    {
        GameTele const* entrance = sObjectMgr->GetGameTele(segment.StartGameTeleId);
        if (!entrance)
            return true;
        if (!run->EntranceInitialized())
        {
            std::string bootstrapError;

            if (!RestorePrivateRouteCreatures(map, *run, bootstrapError) || !BootstrapSpecialEncounter(
                    map,
                    *run,
                    bootstrapError))
            {
                FailRun(
                    *run,
                    "Special encounter bootstrap failed: " +
                        bootstrapError);

                return false;
            }

            run->SetEntranceInitialized();
            Position const position(entrance->position_x, entrance->position_y,
                entrance->position_z, entrance->orientation);
            player->CastSpell(position.GetPositionX(), position.GetPositionY(), position.GetPositionZ(),
                SPELL_SAFETY_BUBBLE, true);
            // Instance scripts may have loaded creatures during CreateMap, before
            // the stage index existed. Register those DB spawns once as well.
            std::vector<ObjectGuid> loadedSpawnGuids;
            loadedSpawnGuids.reserve(map->GetCreatureBySpawnIdStore().size());
            for (auto const& spawn : map->GetCreatureBySpawnIdStore())
                if (spawn.second && spawn.second->IsInWorld())
                    loadedSpawnGuids.push_back(spawn.second->GetGUID());

            for (ObjectGuid const& guid : loadedSpawnGuids)
                if (Creature* creature = map->GetCreature(guid))
                    if (creature->IsInWorld())
                        OnCreatureAddWorld(creature);
        }

        //
        // Recovered presentation timing: Manastorm_Intro_* belongs to the
        // protected arrival window. The first caller reaches this point only
        // after the Safety Bubble has been created; later party members reach
        // the same hook as they arrive in the already-initialized stage.
        //
        ApplySafetyBubbleProtection(player, *run);
        for (Unit* companion : player->m_Controlled)
            if (companion && companion->GetOwnerGUID() == player->GetGUID())
                ApplySafetyBubbleProtection(companion, *run);
        if (DynamicObject* bubble = player->GetDynObject(SPELL_SAFETY_BUBBLE))
            bubble->SetDuration(int32(run->GetPreparationProtectionRemainingMs()));

        ManastormVoiceOfMillhouse::OnPlayerEnteredProtection(
            *run,
            player);

        bool start = run->StartRequested();

        if (run->CanStartWithMissingMembers() &&
            run->HasPreviousStage() &&
            run->HasPendingStageTransfers())
        {
            SendClientState(
                player,
                run);

            return true;
        }

        // Normal movement/combat activation waits for the whole party.
        // The real protection timeout and the five-second inter-stage fallback
        // are allowed to activate with disconnected/missing members so
        // PREPARING can never become permanent.
        if (!run->CanStartWithMissingMembers())
        {
            for (auto guid : run->GetMembers())
            {
                Player* member =
                    ObjectAccessor::FindConnectedPlayer(
                        ObjectGuid::Create<
                            HighGuid::Player>(
                                guid));

                if (!member ||
                    !member->IsInWorld() ||
                    member->IsBeingTeleported() ||
                    member->GetMapId() !=
                        map->GetId() ||
                    member->GetInstanceId() !=
                        map->GetInstanceId())
                {
                    SendClientState(
                        player,
                        run);

                    return true;
                }
            }
        }
        for (auto guid : run->GetMembers())
            if (Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
                start = start || (member->IsAlive() && member->GetExactDist(entrance->position_x,
                    entrance->position_y, entrance->position_z) > 8.0f);
        if (!start)
        {
            SendClientState(player, run);
            return true;
        }
        for (auto guid : run->GetMembers())
            if (Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
                ClearSafetyBubble(member);
        run->SetState(ManastormRunState::Active);

        //
        // Voice presentation starts only once the safety bubble collapses and
        // the stage is truly ACTIVE. This prevents intro/dungeon VO from
        // firing during private-instance construction or partial transfers.
        //
        ManastormVoiceOfMillhouse::OnStageActivated(
            *run);

        for (auto guid : run->GetMembers())
        {
            if (Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            guid)))
            {
                if (member->IsInWorld() &&
                    member->GetMapId() ==
                        map->GetId() &&
                    member->GetInstanceId() ==
                        map->GetInstanceId())
                {
                    ManastormAffixEngine::Instance()
                        .ApplyActivePlayerAffixes(
                            member,
                            *run);
                }
            }
        }

        std::size_t healthScaledCount = 0;

        for (ObjectGuid const& guid :
            run->GetStageCreatureGuids())
        {
            Creature* creature =
                ObjectAccessor::GetCreature(
                    *player,
                    guid);

            if (!creature ||
                !creature->IsAlive() ||
                creature->IsTrigger() ||
                creature->IsPet() ||
                IsPlayerControlledCreature(creature))
            {
                continue;
            }

            uint32 const nativeMaxHealth =
                creature->GetMaxHealth();

            double const healthPct =
                nativeMaxHealth
                ? double(creature->GetHealth()) /
                double(nativeMaxHealth)
                : 1.0;

            ApplyCreatureHealthScaling(
                creature,
                *run,
                healthPct);

            ++healthScaledCount;
        }

        // Affix ownership may have been decided while PREPARING, but marker
        // auras are deliberately dormant until the safety bubble collapses.
        // Replay creature initialization now to activate the already-selected
        // affixes without changing their deterministic ownership rolls.
        for (ObjectGuid const& guid :
            run->GetStageCreatureGuids())
        {
            Creature* creature =
                ObjectAccessor::GetCreature(
                    *player,
                    guid);

            if (!creature ||
                !creature->IsInWorld() ||
                !creature->IsAlive())
            {
                continue;
            }

            ManastormAffixEngine::Instance()
                .OnCreatureAdded(
                    creature,
                    *run);
        }

        //
        // Ensure the exact objective boss has the real recovered
        // Chaotic Link aura and correct visible stack count.
        //
        ObjectGuid const objectiveGuid =
            run->GetObjectiveCreatureGuid();

        if (!objectiveGuid.IsEmpty())
        {
            Creature* objectiveBoss =
                ObjectAccessor::GetCreature(
                    *player,
                    objectiveGuid);

            if (objectiveBoss)
            {
                SyncChaoticLinkAura(
                    objectiveBoss,
                    *run);
            }
        }

        //
        // Archaedas's native altar awakening is deliberately deferred
        // until ACTIVE, after all members' safety bubbles are cleared,
        // and after native creatures have their stage scaling, affixes,
        // and Chaotic Links. The PREPARING bootstrap only loads his
        // original petrified DB spawn.
        //
        if ((segment.SegmentId == SEGMENT_ARCHAEDAS_NORMAL ||
             segment.SegmentId == SEGMENT_ARCHAEDAS_ENDGAME))
        {
            std::string archaedasError;
            if (!ActivateUldamanArchaedasEncounter(
                    player, map, *run, archaedasError))
            {
                FailRun(
                    *run,
                    "Uldaman Archaedas native activation failed: " +
                        archaedasError);
                return false;
            }
        }

        // Greedy Demon is selected once when the disposable stage becomes
        // active. Spawning after the PREPARING-affix replay guarantees the
        // special creature can never inherit ordinary stage affixes.
        ManastormGreedyDemon::Instance()
            .TrySpawnForStage(
                map,
                *run);

        SendClientState(
            player,
            run);

        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} activated stage with scaling: "
            "HP={:.3f}x globalDamage={:.3f}x melee={:.3f}x spell={:.3f}x. "
            "Scaled {} existing stage creatures.",
            run->GetRunId(),
            double(run->GetScaling().HealthMultiplier),
            double(run->GetScaling().GlobalDamageMultiplier),
            double(run->GetScaling().MeleeMultiplier),
            double(run->GetScaling().SpellMultiplier),
            healthScaledCount);

        LOG_INFO(LOG_FILTER,
            "Manastorm run {} entered active stage: player={} segment={} "
            "map={} instance={} objective={}.",
            run->GetRunId(),
            player->GetGUID().GetCounter(),
            segment.SegmentId,
            segment.MapId,
            run->GetInstanceId(),
            segment.ObjectiveCreatureEntry);

        player->SendSystemMessage(
            "Manastorm: stage ACTIVE. Instance transport succeeded.");

        SendClientState(
            player,
            run);
    }
    SendClientState(player, run);
    if (run->GetState() == ManastormRunState::StageComplete)
        ManastormClientBridge::Instance().SendStageCompleted(player, run->GetDepth());
    return true;
}

void ManastormMgr::OnPlayerLevelChanged(
    Player* player,
    uint8 oldLevel)
{
    if (!player)
        return;

    ManastormRun* run = GetRunFor(player);
    if (!run ||
        (run->GetState() != ManastormRunState::Preparing &&
            run->GetState() != ManastormRunState::Active))
        return;

    uint8 const newCreatureLevel =
        ResolveCreatureLevel(
            run->GetMembers(),
            player->GetLevel());

    uint8 const previousCreatureLevel =
        run->GetCreatureLevel();

    if (newCreatureLevel == previousCreatureLevel)
        return;

    run->SetCreatureLevel(newCreatureLevel);

    // During PREPARING, newly loaded creatures will automatically
    // receive the new run level through OnBeforeCreatureSelectLevel().
    if (run->GetState() != ManastormRunState::Active)
        return;

    Map* map = player->GetMap();
    if (!map ||
        map->GetId() != run->GetSegment().MapId ||
        map->GetInstanceId() != run->GetInstanceId())
        return;

    std::size_t rescaledCount = 0;

    for (ObjectGuid const& guid :
        run->GetStageCreatureGuids())
    {
        Creature* creature =
            ObjectAccessor::GetCreature(
                *player,
                guid);

        if (!creature ||
            !creature->IsAlive() ||
            creature->IsTrigger() ||
            creature->IsPet() ||
            IsPlayerControlledCreature(creature))
            continue;

        uint32 const oldHealth =
            creature->GetHealth();

        uint32 const oldMaxHealth =
            creature->GetMaxHealth();

        uint32 const oldMana =
            creature->GetPower(POWER_MANA);

        uint32 const oldMaxMana =
            creature->GetMaxPower(POWER_MANA);

        double const healthPct =
            oldMaxHealth
            ? double(oldHealth) /
            double(oldMaxHealth)
            : 1.0;

        double const manaPct =
            oldMaxMana
            ? double(oldMana) /
            double(oldMaxMana)
            : 1.0;

        //
        // Re-enter native creature level/stat generation.
        //
        // OnBeforeCreatureSelectLevel:
        //     forces new UW run level
        //
        // Creature::SelectLevel:
        //     HP
        //     Mana
        //     Armor
        //     AP
        //     Ranged AP
        //     Base Damage
        //
        //
        // Explicitly change the creature's runtime level.
        //
        creature->SelectLevel(false);

        // Creature::SelectLevel() rebuilds the level-dependent HP, mana,
        // AP and base weapon damage, but normal Creature::UpdateEntry()
        // applies the class-level armor baseline immediately afterwards.
        // Reproduce that missing part here for a live Endless level change.
        CreatureTemplate const* creatureTemplate =
            creature->GetCreatureTemplate();

        if (creatureTemplate)
        {
            CreatureBaseStats const* stats =
                sObjectMgr->GetCreatureBaseStats(
                    newCreatureLevel,
                    creatureTemplate->unit_class);

            if (stats)
            {
                creature->SetStatFlatModifier(
                    UNIT_MOD_ARMOR,
                    BASE_VALUE,
                    stats->GenerateArmor(creatureTemplate));
            }
        }

        // Force the runtime fields to reflect the newly selected level.
        creature->UpdateArmor();
        creature->UpdateAttackPowerAndDamage(false);
        creature->UpdateAttackPowerAndDamage(true);

        ApplyCreatureHealthScaling(
            creature,
            *run,
            healthPct);

        uint32 const newMaxMana =
            creature->GetMaxPower(
                POWER_MANA);

        if (oldMaxMana && newMaxMana)
        {
            uint32 const restoredMana =
                std::min<uint32>(
                    newMaxMana,
                    uint32(std::llround(
                        double(newMaxMana) *
                        manaPct)));

            creature->SetPower(
                POWER_MANA,
                restoredMana);
        }

        // All native stat rebuilding is finished.
        //
        // SelectLevel(false) deliberately does not modify UNIT_FIELD_LEVEL,
        // so explicitly commit the final runtime creature level now.
        creature->SetLevel(
            newCreatureLevel);

        creature->ForceValuesUpdateAtIndex(
            UNIT_FIELD_LEVEL);

        if (creature->GetLevel() == newCreatureLevel)
        {
            ++rescaledCount;
        }
        else
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm run {} failed to dynamically set creature {} "
                "entry={} to level {}. Actual runtime level={}.",
                run->GetRunId(),
                creature->GetGUID().GetCounter(),
                creature->GetEntry(),
                uint32(newCreatureLevel),
                uint32(creature->GetLevel()));
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} dynamically rescaled active stage "
        "from level {} to {} after player {} changed "
        "from level {} to {}. Rescaled {} loaded stage creatures.",
        run->GetRunId(),
        uint32(previousCreatureLevel),
        uint32(newCreatureLevel),
        player->GetGUID().GetCounter(),
        uint32(oldLevel),
        uint32(player->GetLevel()),
        rescaledCount);

    player->SendSystemMessage(
        "Manastorm: active stage creature level updated.");
}

void ManastormMgr::OnPlayerGiveXP(
    Player* player,
    uint32& amount,
    Unit* victim,
    uint8 /*xpSource*/)
{
    if (!player ||
        !victim ||
        !amount)
    {
        return;
    }

    //
    // Endless XP progression applies only to creature XP.
    //
    // Quest XP, exploration XP, battleground XP, etc. are left
    // completely untouched.
    //
    Creature* creature =
        victim->ToCreature();

    if (!creature)
        return;

    //
    // Never treat our Heart helper or player-controlled entities
    // as Endless XP sources.
    //
    if (creature->GetEntry() ==
        NPC_MANASTORM_HEART ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsPlayerControlledCreature(
            creature))
    {
        return;
    }

    ManastormRun* run =
        GetRunFor(player);

    if (!run)
        return;

    //
    // XP can be awarded immediately around the objective-death
    // transition, so StageComplete remains a valid state here.
    //
    if (run->GetState() !=
        ManastormRunState::Active &&
        run->GetState() !=
        ManastormRunState::StageComplete)
    {
        return;
    }

    ManastormSegment const& segment =
        run->GetSegment();

    //
    // The player and XP victim must both belong to the exact
    // current Endless stage.
    //
    if (player->GetMapId() !=
        segment.MapId ||
        player->GetInstanceId() !=
        run->GetInstanceId() ||
        creature->GetMapId() !=
        segment.MapId ||
        creature->GetInstanceId() !=
        run->GetInstanceId())
    {
        return;
    }

    double xpMultiplier =
        GetEndlessExperienceMultiplier(
            run->GetDepth());

    // Match C_Manastorm.GetStageBonusExperience's first return:
    // ManastormModifiers word 11 * Manastorm word 6.
    // The addon shows (multiplier - 1) * 100; word 8 is a separate return.
    if (ManastormModuleConfig::IsNativeClientMode())
    {
        double const mapFactor = double(segment.NativeExperienceFactor1);
        if (!std::isfinite(mapFactor) || mapFactor < 0.0)
        {
            LOG_ERROR(LOG_FILTER, "Invalid native Manastorm XP factor for segment {}.",
                segment.SegmentId);
            return;
        }

        xpMultiplier *= mapFactor;
    }

    uint32 const originalAmount =
        amount;

    amount =
        ScaleUnsignedValue(
            amount,
            xpMultiplier);

    LOG_DEBUG(
        LOG_FILTER,
        "Manastorm XP: run={} depth={} player={} "
        "victimEntry={} baseXP={} multiplier={:.3f}x finalXP={}.",
        run->GetRunId(),
        run->GetDepth(),
        player->GetGUID().GetRawValue(),
        creature->GetEntry(),
        originalAmount,
        xpMultiplier,
        amount);
}

void ManastormMgr::OnBeforeCreatureSelectLevel(
    Creature* creature,
    uint8& level)
{
    if (!creature ||
        creature->GetEntry() == NPC_MANASTORM_HEART ||
        creature->GetEntry() == NPC_COGSLEY ||
        creature->GetEntry() == NPC_STAGE_PORTAL ||
        creature->GetEntry() ==
            ManastormVoiceOfMillhouse::EmitterCreatureEntry ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsPlayerControlledCreature(creature))
        return;

    Map* map = creature->GetMap();
    if (!map || !map->GetInstanceId())
        return;

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run ||
        (run->GetState() != ManastormRunState::Preparing &&
            run->GetState() != ManastormRunState::Active))
        return;

    level = run->GetCreatureLevel();
}

void ManastormMgr::OnCreatureSelectLevel(
    Creature* creature)
{
    if (!creature)
        return;
    if (creature->GetEntry() != NPC_MANASTORM_HEART)
    {
        // SelectLevel(false) rebuilds stats but deliberately leaves the visible
        // UNIT_FIELD_LEVEL unchanged. Keep both consistent in an owned stage.
        uint8 level = creature->GetLevel();
        OnBeforeCreatureSelectLevel(creature, level);
        if (creature->GetLevel() != level)
            creature->SetLevel(level);
        return;
    }

    //
    // Creature::SelectLevel normally calls SetLevel(level, true).
    //
    // For the invisible Manastorm Heart controller we do not want that
    // level initialization sent to the client as a visible level-change
    // event.
    //
    // Keep the level exactly as selected, but clear the level update bit
    // BEFORE the creature is added to the world.
    //
    creature->SetLevel(
        creature->GetLevel(),
        false);
}

void ManastormMgr::ApplyCreatureHealthScaling(
    Creature* creature,
    ManastormRun& run,
    double healthPct)
{
    if (!creature)
        return;

    uint32 const normalizedMaxHealth =
        creature->GetMaxHealth();

    if (!normalizedMaxHealth)
        return;

    double endlessMultiplier =
        double(
            run.GetScaling().HealthMultiplier);

    if (!std::isfinite(
        endlessMultiplier) ||
        endlessMultiplier <= 0.0)
    {
        endlessMultiplier = 1.0;
    }

    healthPct =
        std::clamp(
            healthPct,
            0.0,
            1.0);

    //
    // First calculate the authoritative boss/trash health after normal
    // Endless depth scaling only.
    //
    uint32 const endlessMaxHealth =
        std::max<uint32>(
            1,
            ScaleUnsignedValue(
                normalizedMaxHealth,
                endlessMultiplier));

    uint32 finalMaxHealth =
        endlessMaxHealth;

    //
    // Only the exact objective boss receives Chaotic Link.
    //
    // Store its Endless-only max health separately so future Link
    // reductions can always recalculate from a stable baseline.
    //
    if (IsObjectiveBoss(
        creature,
        run))
    {
        run.SetChaoticLinkBaseMaxHealth(
            endlessMaxHealth);

        finalMaxHealth =
            std::max<uint32>(
                1,
                ScaleUnsignedValue(
                    endlessMaxHealth,
                    GetChaoticLinkHealthMultiplier(
                        run)));
    }

    creature->SetCreateHealth(
        finalMaxHealth);

    creature->SetStatFlatModifier(
        UNIT_MOD_HEALTH,
        BASE_VALUE,
        float(finalMaxHealth));

    creature->SetMaxHealth(
        finalMaxHealth);

    uint32 const finalHealth =
        std::clamp<uint32>(
            uint32(std::llround(
                double(finalMaxHealth) *
                healthPct)),
            1u,
            finalMaxHealth);

    creature->SetHealth(
        finalHealth);
}

void ManastormMgr::ApplyChaoticLinkBossHealth(
    Creature* boss,
    ManastormRun& run,
    double healthPct)
{
    if (!boss ||
        !IsObjectiveBoss(
            boss,
            run))
    {
        return;
    }

    uint32 const baseMaxHealth =
        run.GetChaoticLinkBaseMaxHealth();

    if (!baseMaxHealth)
    {
        LOG_WARN(
            LOG_FILTER,
            "Manastorm run {} cannot recalculate Chaotic Link HP for "
            "objective boss guid={}: Endless-only base max health is 0.",
            run.GetRunId(),
            boss->GetGUID().GetRawValue());

        return;
    }

    healthPct =
        std::clamp(
            healthPct,
            0.0,
            1.0);

    uint32 const finalMaxHealth =
        std::max<uint32>(
            1,
            ScaleUnsignedValue(
                baseMaxHealth,
                GetChaoticLinkHealthMultiplier(
                    run)));

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

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} recalculated Chaotic Link boss HP: "
        "guid={} stacks={} baseEndlessMax={} finalMax={} "
        "preservedHealthPct={:.3f}.",
        run.GetRunId(),
        boss->GetGUID().GetRawValue(),
        uint32(run.GetChaoticLinkStacks()),
        baseMaxHealth,
        finalMaxHealth,
        healthPct);
}

bool ManastormMgr::SpawnHeartProjectile(
    Creature* creature,
    ManastormRun& run,
    bool persistentLauncher)
{
    if (!creature ||
        run.GetState() != ManastormRunState::Active ||
        creature->GetEntry() == NPC_MANASTORM_HEART ||
        !run.IsStageCreature(creature->GetGUID()))
    {
        return false;
    }

    float const distance =
        frand(
            HEART_MIN_LANDING_DISTANCE,
            HEART_MAX_LANDING_DISTANCE);

    float const angle =
        frand(
            0.0f,
            TWO_PI);

    // Use the core's collision-aware position finder so dungeon walls and
    // cramped geometry can shorten/redirect the destination safely.
    Position const destination =
        creature->GetFirstCollisionPosition(
            distance,
            angle);

    if (!destination.IsPositionValid())
    {
        LOG_WARN(
            LOG_FILTER,
            "Manastorm run {} failed to find a valid Heart landing "
            "position for creature entry={} guid={}.",
            run.GetRunId(),
            creature->GetEntry(),
            creature->GetGUID().GetRawValue());

        return false;
    }

    //
    // 991507 = Manastorm Projectile Visual
    //
    // Its recovered Spell.dbc data triggers 991509 on impact.
    //
    // 991509 then summons creature 900025 at the destination.
    //
    Creature* projectileCaster =
        creature;

    //
    // Ordinary trash Hearts are death-triggered.
    //
    // Never cast 991509 directly for a lethal trash kill: doing so bypasses
    // the recovered projectile and makes the Heart pop into existence.
    //
    // Instead create the core's built-in invisible WORLD_TRIGGER at the
    // corpse position. It survives the source creature's death long enough
    // to cast the real 991507 missile. Spell.dbc then continues naturally:
    //
    //     991507 -> 991509 -> 900025
    //
    if (persistentLauncher)
    {
        projectileCaster =
            creature->SummonTrigger(
                creature->GetPositionX(),
                creature->GetPositionY(),
                creature->GetPositionZ(),
                creature->GetOrientation(),
                HEART_PROJECTILE_LAUNCHER_LIFETIME_MS,
                false);

        if (!projectileCaster)
        {
            LOG_WARN(
                LOG_FILTER,
                "Manastorm run {} could not create temporary Heart "
                "projectile launcher for creature entry={} guid={}.",
                run.GetRunId(),
                creature->GetEntry(),
                creature->GetGUID().GetRawValue());

            return false;
        }
    }

    projectileCaster->CastSpell(
        destination.GetPositionX(),
        destination.GetPositionY(),
        destination.GetPositionZ(),
        SPELL_MANASTORM_HEART_PROJECTILE,
        true);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} launched Manastorm Heart projectile from "
        "creature entry={} guid={} toward ({}, {}, {}).",
        run.GetRunId(),
        creature->GetEntry(),
        creature->GetGUID().GetRawValue(),
        destination.GetPositionX(),
        destination.GetPositionY(),
        destination.GetPositionZ());

    return true;
}

bool ManastormMgr::TrySpawnTrashHeart(
    Creature* creature,
    ManastormRun& run)
{
    if (!creature ||
        run.GetState() != ManastormRunState::Active ||
        creature->GetEntry() == NPC_MANASTORM_HEART ||
        !run.IsStageCreature(creature->GetGUID()))
    {
        return false;
    }

    //
    // Recovered Ascension Heart proc chance: 75%.
    //
    // Ordinary stage monsters get exactly one roll when they die.
    // Failed rolls are consumed too, so the same runtime creature cannot
    // acquire repeated Heart attempts.
    //
    if (!run.TryMarkTrashHeartRoll(
            creature->GetGUID()) ||
        urand(1, 100) >
            HEART_TRASH_CHANCE_PCT)
    {
        return false;
    }

    return SpawnHeartProjectile(
        creature,
        run,
        true);
}

void ManastormMgr::OnDamage(
    Unit* attacker,
    Unit* victim,
    uint32& damage)
{
    if (!victim || !damage)
        return;

    if (sManastormReflectDamageDispatch)
        return;

    //
    // REFLECTING
    //
    // Recovered DBC flow:
    //   93360 -> every 12s -> 9336100 charge -> 93361 Reflective for 5s.
    //
    // 93361 is Aura 4 (DUMMY), so stock AzerothCore cannot infer the
    // reflection callback. The recovered amount is BP29 => 30 at rank 1;
    // the user-approved reconstruction interprets that amount as the
    // percentage of actual incoming damage reflected to the attacker.
    //
    if (attacker &&
        attacker != victim &&
        attacker->IsAlive())
    {
        if (Creature* reflectingCreature =
            victim->ToCreature())
        {
            if (reflectingCreature->IsAlive() &&
                reflectingCreature->GetEntry() !=
                    NPC_MANASTORM_HEART &&
                !reflectingCreature->IsTrigger() &&
                !reflectingCreature->IsPet() &&
                !IsPlayerControlledCreature(
                    reflectingCreature) &&
                reflectingCreature->HasAura(
                    SPELL_MANASTORM_REFLECTIVE))
            {
                Map* reflectMap =
                    reflectingCreature->GetMap();

                if (reflectMap &&
                    reflectMap->GetInstanceId() &&
                    attacker->GetMap() ==
                        reflectMap)
                {
                    ManastormRun* reflectRun =
                        GetRunForStage(
                            reflectMap->GetId(),
                            reflectMap->GetInstanceId());

                    if (reflectRun &&
                        reflectRun->GetState() ==
                            ManastormRunState::Active &&
                        reflectRun->IsStageCreature(
                            reflectingCreature->GetGUID()) &&
                        reflectRun->HasCreatureAffix(
                            reflectingCreature->GetGUID(),
                            ManastormAffixIds::Reflecting))
                    {
                        ManastormAffixDefinition const*
                            definition =
                                ManastormDataStore::Instance()
                                    .GetAffixById(
                                        ManastormAffixIds::Reflecting);

                        uint32 reflectiveSpellId =
                            SPELL_MANASTORM_REFLECTIVE;

                        if (definition)
                        {
                            uint8 const rank =
                                reflectRun->GetStageAffixRank(
                                    ManastormAffixIds::Reflecting);

                            uint32 const rankSpellId =
                                definition->GetRankSpell(
                                    MANASTORM_AFFIX_PRIMARY_RANK_ROLE,
                                    rank);

                            if (rankSpellId)
                                reflectiveSpellId =
                                    rankSpellId;
                        }

                        if (SpellInfo const* reflectiveInfo =
                            sSpellMgr->GetSpellInfo(
                                reflectiveSpellId))
                        {
                            int32 const reflectPct =
                                reflectiveInfo->Effects[EFFECT_0]
                                    .CalcValue(
                                        reflectingCreature);

                            if (reflectPct > 0)
                            {
                                uint32 const actualDamage =
                                    std::min(
                                        damage,
                                        victim->GetHealth());

                                uint32 const reflectedDamage =
                                    uint32(
                                        uint64(actualDamage) *
                                        uint32(reflectPct) /
                                        100ULL);

                                if (reflectedDamage)
                                {
                                    sManastormReflectDamageDispatch =
                                        true;

                                    reflectingCreature
                                        ->SendSpellNonMeleeDamageLog(
                                            attacker,
                                            reflectiveInfo,
                                            reflectedDamage,
                                            reflectiveInfo
                                                ->GetSchoolMask(),
                                            0,
                                            0,
                                            true,
                                            0,
                                            false,
                                            true);

                                    Unit::DealDamage(
                                        reflectingCreature,
                                        attacker,
                                        reflectedDamage,
                                        nullptr,
                                        NODAMAGE,
                                        reflectiveInfo
                                            ->GetSchoolMask(),
                                        reflectiveInfo,
                                        false);

                                    sManastormReflectDamageDispatch =
                                        false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //
    // LEECHING
    //
    // Recovered behavior:
    //     successful damage dealt by an affixed Manastorm creature
    //     -> heal the attacker for the affix percentage of actual damage.
    //
    // Spell.dbc stores Leeching as a DUMMY aura, so stock AzerothCore has
    // no generic handler that can infer this behavior. The base/root spell
    // 93344 encodes 30% (base points 29 => value 30); the recovered
    // 115091..115110 rank family carries the higher-rank percentages.
    //
    // Cap the source damage by the victim's current health so overkill does
    // not create extra healing. This matches the recovered donor behavior.
    //
    if (Creature* attackingCreature =
        attacker
        ? attacker->ToCreature()
        : nullptr)
    {
        if (attackingCreature->IsAlive() &&
            attackingCreature->GetEntry() !=
                NPC_MANASTORM_HEART &&
            !attackingCreature->IsTrigger() &&
            !attackingCreature->IsPet() &&
            !IsPlayerControlledCreature(
                attackingCreature))
        {
            Map* attackerMap =
                attackingCreature->GetMap();

            if (attackerMap &&
                attackerMap->GetInstanceId() &&
                victim->GetMap() ==
                    attackerMap)
            {
                ManastormRun* attackerRun =
                    GetRunForStage(
                        attackerMap->GetId(),
                        attackerMap->GetInstanceId());

                if (attackerRun &&
                    attackerRun->GetState() ==
                        ManastormRunState::Active &&
                    attackerRun->IsStageCreature(
                        attackingCreature->GetGUID()) &&
                    attackerRun->HasCreatureAffix(
                        attackingCreature->GetGUID(),
                        ManastormAffixIds::Leeching))
                {
                    ManastormAffixDefinition const*
                        definition =
                            ManastormDataStore::Instance()
                                .GetAffixById(
                                    ManastormAffixIds::Leeching);

                    uint32 leechSpellId =
                        definition &&
                        definition->MarkerSpellId
                        ? definition->MarkerSpellId
                        : ManastormAffixIds::Leeching;

                    if (definition)
                    {
                        uint8 const rank =
                            attackerRun->GetStageAffixRank(
                                ManastormAffixIds::Leeching);

                        uint32 const rankSpellId =
                            definition->GetRankSpell(
                                MANASTORM_AFFIX_PRIMARY_RANK_ROLE,
                                rank);

                        if (rankSpellId)
                            leechSpellId =
                                rankSpellId;
                    }

                    if (SpellInfo const* leechInfo =
                        sSpellMgr->GetSpellInfo(
                            leechSpellId))
                    {
                        int32 const leechPct =
                            leechInfo->Effects[EFFECT_0]
                                .CalcValue(
                                    attackingCreature);

                        if (leechPct > 0)
                        {
                            uint32 const actualDamage =
                                std::min(
                                    damage,
                                    victim->GetHealth());

                            uint32 const healAmount =
                                uint32(
                                    uint64(actualDamage) *
                                    uint32(leechPct) /
                                    100ULL);

                            if (healAmount)
                            {
                                HealInfo healInfo(
                                    attackingCreature,
                                    attackingCreature,
                                    healAmount,
                                    leechInfo,
                                    leechInfo->GetSchoolMask());

                                attackingCreature->HealBySpell(
                                    healInfo,
                                    false);
                            }
                        }
                    }
                }
            }
        }
    }

    Creature* creature =
        victim->ToCreature();

    if (!creature ||
        creature->GetEntry() == NPC_MANASTORM_HEART ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsPlayerControlledCreature(creature))
    {
        return;
    }

    Map* map =
        creature->GetMap();

    if (!map ||
        !map->GetInstanceId())
    {
        return;
    }

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run ||
        !run->IsStageCreature(
            creature->GetGUID()))
    {
        return;
    }

    //
    // Treat the first real player/player-controlled hit as explicit intent to
    // start the stage. Entrance safety itself is owned by the real Ascension
    // Safety Bubble spell; do not add a second server-side damage immunity
    // layer while PREPARING.
    //
    if (run->GetState() ==
        ManastormRunState::Preparing)
    {
        Player* attackingPlayer =
            attacker
            ? attacker->
                GetCharmerOrOwnerPlayerOrPlayerItself()
            : nullptr;

        ManastormRun* playerRun =
            attackingPlayer
            ? GetRunFor(
                attackingPlayer)
            : nullptr;

        bool const exactStageMember =
            attackingPlayer &&
            playerRun == run &&
            attackingPlayer->GetMapId() ==
                run->GetSegment().MapId &&
            attackingPlayer->GetInstanceId() ==
                run->GetInstanceId();

        if (exactStageMember)
        {
            if (SuppressPreparingCompanionAttack(attacker, *run, damage))
                return;

            run->RequestStart();

            if (!OnPlayerEnterMap(
                    attackingPlayer->FindMap(),
                    attackingPlayer))
                return;
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} activated because player {} engaged "
            "stage creature entry={} guid={}.",
            run->GetRunId(),
            attackingPlayer
                ? attackingPlayer->GetGUID().GetCounter()
                : 0,
            creature->GetEntry(),
            creature->GetGUID().GetRawValue());
    }

    if (run->GetState() !=
        ManastormRunState::Active)
    {
        return;
    }

    uint32 const currentHealth =
        creature->GetHealth();

    uint32 const maxHealth =
        creature->GetMaxHealth();

    if (!currentHealth ||
        !maxHealth)
    {
        return;
    }

    ManastormSegment const& segment =
        run->GetSegment();

    bool const isObjectiveBoss =
        IsObjectiveBoss(
            creature,
            *run);

    //
    // Normal trash Hearts are death-driven in OnUnitDeath().
    //
    // Keep objective-boss behavior unchanged: boss Hearts remain tied to
    // the non-lethal 90..10% thresholds below.
    //
    if (damage >= currentHealth)
        return;

    uint32 const remainingHealth =
        currentHealth - damage;

    if (isObjectiveBoss)
    {
        //
        // Objective boss Hearts:
        //
        // one guaranteed Heart when the boss FIRST crosses each threshold:
        // 90, 80, 70, 60, 50, 40, 30, 20 and 10 percent.
        //
        // A large non-lethal hit can legitimately cross more than one
        // threshold, in which case each newly crossed threshold launches one.
        //
        for (uint8 threshold = 90;
            threshold >= 10;
            threshold -= 10)
        {
            bool const wasAboveThreshold =
                uint64(currentHealth) * 100 >
                uint64(maxHealth) * threshold;

            bool const isAtOrBelowThreshold =
                uint64(remainingHealth) * 100 <=
                uint64(maxHealth) * threshold;

            if (wasAboveThreshold &&
                isAtOrBelowThreshold &&
                !run->HasBossHeartThreshold(threshold))
            {
                if (SpawnHeartProjectile(
                    creature,
                    *run))
                {
                    run->MarkBossHeartThreshold(
                        threshold);

                    LOG_INFO(
                        LOG_FILTER,
                        "Manastorm run {} objective boss crossed {}% HP "
                        "and launched a Manastorm Heart.",
                        run->GetRunId(),
                        uint32(threshold));
                }
            }

            if (threshold == 10)
                break;
        }

        return;
    }

    //
    // Regular trash intentionally has no HP-threshold Heart behavior here.
    // Its single 75% chance is evaluated by OnUnitDeath().
    //
}

bool ManastormMgr::ForceStageAffix(
    Player* player,
    uint32 affixId,
    std::string& error)
{
    error.clear();

    if (!player)
    {
        error =
            "An in-game player is required.";

        return false;
    }

    ManastormRun* run =
        GetRunFor(player);

    if (!run)
    {
        error =
            "You are not part of an active Manastorm run.";

        return false;
    }

    if (run->GetState() !=
        ManastormRunState::Active)
    {
        error =
            "Affixes can currently be forced only while "
            "the Endless stage is ACTIVE.";

        return false;
    }

    if (!ManastormAffixEngine::Instance()
        .ForceStageAffix(
            *run,
            affixId,
            error))
    {
        return false;
    }

    std::size_t assignedCount = 0;

    for (ObjectGuid const& guid :
        run->GetStageCreatureGuids())
    {
        Creature* creature =
            ObjectAccessor::GetCreature(
                *player,
                guid);

        if (!creature ||
            !creature->IsInWorld() ||
            !creature->IsAlive())
        {
            continue;
        }

        bool const alreadyAssigned =
            run->HasCreatureAffix(
                guid,
                affixId);

        ManastormAffixEngine::Instance()
            .ForceAffixOnCreature(
                creature,
                *run,
                affixId);

        if (!alreadyAssigned &&
            run->HasCreatureAffix(
                guid,
                affixId))
        {
            ++assignedCount;
        }
    }

    for (ObjectGuid::LowType memberGuid :
        run->GetMembers())
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (member &&
            member->IsInWorld() &&
            member->GetMapId() ==
                run->GetSegment().MapId &&
            member->GetInstanceId() ==
                run->GetInstanceId())
        {
            ManastormAffixEngine::Instance()
                .ApplyActivePlayerAffixes(
                    member,
                    *run);
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} force-enabled affix {} "
        "on current depth {}. Newly assigned creatures={}.",
        run->GetRunId(),
        affixId,
        run->GetDepth(),
        assignedCount);

    return true;
}

void ManastormMgr::OnCreatureAddWorld(Creature* creature)
{
    if (creature)
        if (Player* owner = creature->GetCharmerOrOwnerPlayerOrPlayerItself())
            if (ManastormRun const* run = GetRunFor(owner))
                ApplySafetyBubbleProtection(creature, *run);

    // Cosmetic toy pickups never join stage objectives, affixes or healing hearts.
    if (!creature ||
        creature->GetEntry() == NPC_EMPTY_HEART_CONTAINER ||
        creature->GetEntry() == NPC_COGSLEY ||
        creature->GetEntry() == NPC_STAGE_PORTAL ||
        creature->GetEntry() ==
            ManastormVoiceOfMillhouse::EmitterCreatureEntry)
    {
        return;
    }

    Map* map =
        creature->GetMap();

    if (!map ||
        !map->GetInstanceId())
    {
        return;
    }

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run)
        return;

    // This private stage replaces Immol'thar with the original ritual boss.
    // Guard later grid loads as well as the initial encounter bootstrap.
    if (creature->GetEntry() == NPC_IMMOLTHAR &&
        map->GetId() == MANASTORM_MAP_DIRE_MAUL &&
        map->IsScriptedPrivateInstance() &&
        run->GetInstanceId() == map->GetInstanceId() &&
        (run->GetState() == ManastormRunState::Preparing ||
         run->GetState() == ManastormRunState::Active))
    {
        ManastormSegment const& segment = run->GetSegment();
        if (segment.MapId == MANASTORM_MAP_DIRE_MAUL &&
            segment.ObjectiveCreatureEntry == NPC_LORD_HELNURATH &&
            (segment.SegmentId == SEGMENT_HELNURATH_NORMAL ||
             segment.SegmentId == SEGMENT_HELNURATH_ENDGAME))
        {
            creature->DespawnOrUnsummon(0ms, 24h);
            return;
        }
    }

    // No Gahz'rilla may join Velratha's separate private Manastorm stage.
    // This guards against a gong event spawning him after the stage starts.
    // Do not change ordinary Zul'Farrak or Gahz'rilla's own segments.
    if (creature->GetEntry() == NPC_GAHZRILLA &&
        map->GetId() == MANASTORM_MAP_ZUL_FARRAK &&
        map->IsScriptedPrivateInstance() &&
        run->GetInstanceId() == map->GetInstanceId() &&
        (run->GetState() == ManastormRunState::Preparing ||
         run->GetState() == ManastormRunState::Active))
    {
        ManastormSegment const& segment = run->GetSegment();
        if (segment.MapId == MANASTORM_MAP_ZUL_FARRAK &&
            segment.ObjectiveCreatureEntry == NPC_HYDROMANCER_VELRATHA &&
            (segment.SegmentId == SEGMENT_VELRATHA_NORMAL ||
             segment.SegmentId == SEGMENT_VELRATHA_ENDGAME))
        {
            creature->DespawnOrUnsummon(0ms, 24h);
            LOG_INFO(LOG_FILTER,
                "Suppressed Gahz'rilla in private Velratha stage: "
                "run={} segment={} instance={}.",
                run->GetRunId(), segment.SegmentId, run->GetInstanceId());
            return;
        }
    }

    // Captain Kromcrush stands on King Gordok's Manastorm arrival route.
    // Remove him only in the private King Gordok stage, even if his native
    // DB spawn enters the loaded grid after the initial player arrival.
    // Never count him as trash or trigger his death/tribute progression.
    if (creature->GetEntry() == NPC_CAPTAIN_KROMCRUSH &&
        map->GetId() == MANASTORM_MAP_DIRE_MAUL &&
        map->IsScriptedPrivateInstance() &&
        run->GetInstanceId() == map->GetInstanceId() &&
        (run->GetState() == ManastormRunState::Preparing ||
         run->GetState() == ManastormRunState::Active))
    {
        ManastormSegment const& segment = run->GetSegment();
        if (segment.MapId == MANASTORM_MAP_DIRE_MAUL &&
            segment.ObjectiveCreatureEntry == NPC_KING_GORDOK &&
            (segment.SegmentId == SEGMENT_KING_GORDOK_NORMAL ||
             segment.SegmentId == SEGMENT_KING_GORDOK_ENDGAME))
        {
            ObjectGuid::LowType const spawnId = creature->GetSpawnId();
            creature->DespawnOrUnsummon(0ms, 24h);

            LOG_INFO(LOG_FILTER,
                "Suppressed Captain Kromcrush on private King Gordok stage: "
                "run={} segment={} instance={} spawn={}.",
                run->GetRunId(), segment.SegmentId,
                run->GetInstanceId(), spawnId);
            return;
        }
    }

    //
    // Manastorm Heart pickup anchor.
    //
    // 991509 dynamically summons creature 900025.
    // It must NOT become a normal Endless stage creature.
    //
    // StageComplete is accepted here because a boss Heart projectile
    // can finish landing immediately after the boss dies.
    //
    if (creature->GetEntry() ==
        NPC_MANASTORM_HEART)
    {
        if (run->GetState() !=
            ManastormRunState::Preparing &&
            run->GetState() !=
            ManastormRunState::Active &&
            run->GetState() !=
            ManastormRunState::StageComplete)
        {
            return;
        }

        run->RegisterActiveHeart(
            creature->GetGUID(),
            HEART_PICKUP_ARM_DELAY_MS);

        creature->CastSpell(
            creature,
            SPELL_MANASTORM_HEART_VISUAL,
            true);

        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} activated Manastorm Heart visual: "
            "heartGuid={} level={} map={} instance={}.",
            run->GetRunId(),
            creature->GetGUID().GetRawValue(),
            uint32(creature->GetLevel()),
            map->GetId(),
            map->GetInstanceId());

        return;
    }

    //
    // Greedy Demon is a stage-level treasure encounter. It participates in
    // Manastorm level/health normalization, but never receives ordinary
    // affixes, Heart rolls, route roles, loot or reputation.
    //
    if (ManastormGreedyDemon::Instance()
        .IsGreedyDemonEntry(
            creature->GetEntry()))
    {
        if (run->GetState() !=
                ManastormRunState::Preparing &&
            run->GetState() !=
                ManastormRunState::Active)
        {
            return;
        }

        run->RegisterStageCreature(
            creature->GetGUID());

        if (run->GreedyDemonRolled())
        {
            run->SetGreedyDemonGuid(
                creature->GetGUID());
        }

        creature->SetFaction(14);
        creature->SetReactState(
            REACT_PASSIVE);
        creature->SetLootRewardDisabled(
            true);
        creature->SetReputationRewardDisabled(
            true);
        creature->SetLootMode(0);

        if (creature->GetLevel() !=
            run->GetCreatureLevel())
        {
            creature->SelectLevel();

            CreatureTemplate const* creatureTemplate =
                creature->GetCreatureTemplate();

            if (creatureTemplate)
            {
                CreatureBaseStats const* stats =
                    sObjectMgr->GetCreatureBaseStats(
                        run->GetCreatureLevel(),
                        creatureTemplate->unit_class);

                if (stats)
                {
                    creature->SetStatFlatModifier(
                        UNIT_MOD_ARMOR,
                        BASE_VALUE,
                        stats->GenerateArmor(
                            creatureTemplate));
                }
            }

            creature->UpdateArmor();
            creature->UpdateAttackPowerAndDamage(
                false);
            creature->UpdateAttackPowerAndDamage(
                true);
        }

        if (run->GetState() ==
            ManastormRunState::Active)
        {
            ApplyCreatureHealthScaling(
                creature,
                *run,
                1.0);
        }

        return;
    }

    //
    // Treasure Keeper is a real hostile special encounter, but it must not
    // inherit ordinary trash affixes, Heart rolls, or authored route roles.
    //
    if (ManastormRewards::Instance()
        .IsTreasureKeeperEntry(
            creature->GetEntry()))
    {
        if (run->GetState() !=
                ManastormRunState::Preparing &&
            run->GetState() !=
                ManastormRunState::Active)
        {
            return;
        }

        run->RegisterStageCreature(
            creature->GetGUID());

        if (run->TreasureKeeperSpawned())
        {
            run->SetTreasureKeeperGuid(
                creature->GetGUID());
        }

        creature->SetLootRewardDisabled(
            true);
        creature->SetReputationRewardDisabled(
            true);
        creature->SetLootMode(0);

        //
        // The recovered client identity does not prove original server-side
        // level/stat values. Our fallback creature_template row is level 1,
        // so the special encounter must enter the same player-level
        // normalization path as every other Manastorm creature before depth
        // HP scaling is applied.
        //
        if (creature->GetLevel() !=
            run->GetCreatureLevel())
        {
            creature->SelectLevel();

            CreatureTemplate const* creatureTemplate =
                creature->GetCreatureTemplate();

            if (creatureTemplate)
            {
                CreatureBaseStats const* stats =
                    sObjectMgr->GetCreatureBaseStats(
                        run->GetCreatureLevel(),
                        creatureTemplate->unit_class);

                if (stats)
                {
                    creature->SetStatFlatModifier(
                        UNIT_MOD_ARMOR,
                        BASE_VALUE,
                        stats->GenerateArmor(
                            creatureTemplate));
                }
            }

            creature->UpdateArmor();
            creature->UpdateAttackPowerAndDamage(
                false);
            creature->UpdateAttackPowerAndDamage(
                true);
        }

        if (run->GetState() ==
            ManastormRunState::Active)
        {
            ApplyCreatureHealthScaling(
                creature,
                *run,
                1.0);
        }

        return;
    }

    //
// Recovered Mana Bomb helper.
//
// It is a trigger/helper, not normal dungeon trash,
// so let the Affix Engine initialize it separately.
//
    if (ManastormAffixEngine::Instance()
        .IsAffixHelperCreature(
            creature->GetEntry()))
    {
        ManastormAffixEngine::Instance()
            .OnCreatureAdded(
                creature,
                *run);

        return;
    }

    if (run->GetState() !=
        ManastormRunState::Preparing &&
        run->GetState() !=
        ManastormRunState::Active)
    {
        return;
    }

    ObjectGuid const guid =
        creature->GetGUID();

    ManastormSegment const& segment =
        run->GetSegment();

    //
    // Register the exact objective GUID BEFORE HP scaling.
    //
    // This lets ApplyCreatureHealthScaling() know whether this exact
    // creature is the Chaotic Link boss even if the objective happens
    // to spawn after the stage is already ACTIVE.
    //
    // Stratholme's Balnazzar is not a separate DB-spawned boss:
    // Dathrohan (10812) transforms to Balnazzar (10813) on the same
    // runtime GUID. Bind that GUID as the stage objective while it is
    // still in disguise so skull, scaling, and Chaotic Link work from
    // PREPARING onward. OnUnitDeath continues to require entry 10813,
    // so killing Dathrohan before his transformation cannot complete
    // either recovered Balnazzar objective.
    //
    // Scope this alias to the two exact original private Manastorm
    // segments; ordinary Stratholme and all other stages are untouched.
    bool const isBalnazzarDisguise =
        creature->GetEntry() == NPC_STRATHOLME_DATHROHAN &&
        map->GetId() == MANASTORM_MAP_STRATHOLME &&
        map->IsScriptedPrivateInstance() &&
        map->GetInstanceId() == run->GetInstanceId() &&
        segment.MapId == MANASTORM_MAP_STRATHOLME &&
        segment.ObjectiveCreatureEntry == NPC_STRATHOLME_BALNAZZAR &&
        ((segment.SegmentId == SEGMENT_BALNAZZAR_NORMAL &&
          segment.Difficulty == 0 &&
          segment.DungeonEncounterId == 478) ||
         (segment.SegmentId == SEGMENT_BALNAZZAR_ENDGAME &&
          segment.Difficulty == 2 &&
          segment.DungeonEncounterId == 2478));

    if (creature->GetEntry() ==
            segment.ObjectiveCreatureEntry ||
        isBalnazzarDisguise)
    {
        ObjectGuid const existingGuid =
            run->GetObjectiveCreatureGuid();

        if (existingGuid.IsEmpty())
        {
            run->SetObjectiveCreatureGuid(
                guid);

            //
            // Automatically mark the exact Endless objective boss
            // with the standard Skull raid-target marker.
            //
            SetEndlessObjectiveSkull(
                *run,
                guid);

            SyncChaoticLinkAura(
                creature,
                *run);

            LOG_INFO(
                LOG_FILTER,
                "Registered Manastorm objective for run {}: "
                "segment={} map={} instance={} entry={} guid={} "
                "chaoticLinks={}.",
                run->GetRunId(),
                segment.SegmentId,
                segment.MapId,
                run->GetInstanceId(),
                segment.ObjectiveCreatureEntry,
                guid.GetRawValue(),
                uint32(
                    run->GetChaoticLinkStacks()));
        }
        else if (existingGuid == guid)
        {
            // Re-synchronize presentation if the same exact runtime
            // objective is observed again.
            SyncChaoticLinkAura(
                creature,
                *run);
        }
        else
        {
            LOG_WARN(
                LOG_FILTER,
                "Manastorm run {} already has objective GUID {} for "
                "segment {}; ignoring duplicate runtime creature GUID {} "
                "(entry={}) as the objective.",
                run->GetRunId(),
                existingGuid.GetRawValue(),
                segment.SegmentId,
                guid.GetRawValue(),
                creature->GetEntry());
        }
    }

    //
    // Runtime stage membership.
    //
    // Existing creatures loaded during PREPARING are scaled together
    // when the player enters and the stage becomes ACTIVE.
    //
    // Later scripted spawns during ACTIVE are scaled immediately.
    // Keep the core kill-reward path enabled for XP. Loot mode 0 suppresses
    // ordinary item and money loot; disabling loot rewards also suppresses XP.
    //
    if (!creature->IsTrigger() &&
        !creature->IsPet() &&
        !IsPlayerControlledCreature(
            creature))
    {
        creature->SetLootRewardDisabled(
            false);
        creature->SetReputationRewardDisabled(
            true);
        creature->SetLootMode(0);

        bool const newlyRegistered =
            run->RegisterStageCreature(
                guid);

        if (newlyRegistered &&
            creature->GetLevel() !=
                run->GetCreatureLevel())
        {
            creature->SelectLevel();

            CreatureTemplate const* creatureTemplate =
                creature->GetCreatureTemplate();

            if (creatureTemplate)
            {
                CreatureBaseStats const* stats =
                    sObjectMgr->GetCreatureBaseStats(
                        run->GetCreatureLevel(),
                        creatureTemplate->unit_class);

                if (stats)
                {
                    creature->SetStatFlatModifier(
                        UNIT_MOD_ARMOR,
                        BASE_VALUE,
                        stats->GenerateArmor(
                            creatureTemplate));
                }
            }

            creature->UpdateArmor();
            creature->UpdateAttackPowerAndDamage(false);
            creature->UpdateAttackPowerAndDamage(true);
        }
        if (newlyRegistered &&
            run->GetState() ==
            ManastormRunState::Active)
        {
            uint32 const nativeMaxHealth =
                creature->GetMaxHealth();

            double const healthPct =
                nativeMaxHealth
                ? double(
                    creature->GetHealth()) /
                double(nativeMaxHealth)
                : 1.0;

            ApplyCreatureHealthScaling(
                creature,
                *run,
                healthPct);
        }
    }

    ManastormAffixEngine::Instance()
        .OnCreatureAdded(
            creature,
            *run);
}

void ManastormMgr::OnCreatureRemoveWorld(Creature* creature)
{
    if (!creature || creature->GetEntry() == NPC_EMPTY_HEART_CONTAINER)
        return;

    Map* map = creature->GetMap();
    if (!map || !map->GetInstanceId())
        return;

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run)
        return;

    if (creature->GetEntry() == NPC_MANASTORM_HEART)
    {
        run->UnregisterActiveHeart(
            creature->GetGUID());

        return;
    }

    if (creature->GetEntry() ==
        ManastormVoiceOfMillhouse::EmitterCreatureEntry)
    {
        return;
    }

    if (ManastormRewards::Instance()
        .IsTreasureKeeperEntry(
            creature->GetEntry()))
    {
        run->UnregisterStageCreature(
            creature->GetGUID());

        if (run->GetTreasureKeeperGuid() ==
            creature->GetGUID())
        {
            run->ClearTreasureKeeperGuid();
        }

        return;
    }

    if (ManastormGreedyDemon::Instance()
        .IsGreedyDemonEntry(
            creature->GetEntry()))
    {
        run->UnregisterStageCreature(
            creature->GetGUID());

        if (run->GetGreedyDemonGuid() ==
            creature->GetGUID())
        {
            run->ClearGreedyDemonGuid();
        }

        return;
    }

    //
    // Clear exact runtime affix ownership before the creature
    // leaves this disposable Endless stage.
    //
    ManastormAffixEngine::Instance()
        .OnCreatureRemoved(
            creature,
            *run);

    //
    // Recovered affix helper summons are never registered as normal
    // stage creatures.
    //
    if (ManastormAffixEngine::Instance()
        .IsAffixHelperCreature(
            creature->GetEntry()))
    {
        return;
    }

    run->UnregisterStageCreature(
        creature->GetGUID());

    if (run->GetState() ==
        ManastormRunState::StageComplete)
    {
        return;
    }

    if (run->GetObjectiveCreatureGuid() != creature->GetGUID())
        return;

    LOG_INFO(LOG_FILTER,
        "Cleared Manastorm objective GUID for run {} because creature {} "
        "left map={} instance={} before stage completion.",
        run->GetRunId(),
        creature->GetGUID().GetRawValue(),
        map->GetId(),
        map->GetInstanceId());

    SetEndlessObjectiveSkull(
        *run,
        ObjectGuid::Empty);

    run->ClearObjectiveCreatureGuid();

}

void ManastormMgr::OnMeleeDamage(
    Unit* attacker,
    Unit* victim,
    uint32 damage)
{
    if (!attacker ||
        !victim ||
        !damage)
    {
        return;
    }

    Creature* creature =
        attacker->ToCreature();

    if (!creature ||
        !creature->IsAlive() ||
        creature->GetEntry() ==
            NPC_MANASTORM_HEART ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsPlayerControlledCreature(
            creature))
    {
        return;
    }

    Map* map =
        creature->GetMap();

    if (!map ||
        !map->GetInstanceId() ||
        victim->GetMap() !=
            map)
    {
        return;
    }

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run ||
        run->GetState() !=
            ManastormRunState::Active ||
        !run->IsStageCreature(
            creature->GetGUID()) ||
        !run->HasCreatureAffix(
            creature->GetGUID(),
            ManastormAffixIds::Cleaving))
    {
        return;
    }

    //
    // Spell.dbc:
    //
    //     93352 Cleaving
    //       Aura 42 = PROC_TRIGGER_SPELL
    //       TriggerSpell = 93351
    //       ProcChance = 100
    //
    //     93351 Cleave
    //       Effect 31 = WEAPON_PERCENT_DAMAGE
    //       amount = 100%
    //       EffectChainTargets = 3
    //
    // Ascension's DBC leaves the proc type mask at zero, so stock
    // AzerothCore never supplies the missing outgoing-melee event.
    // Supply only that event here and let the recovered 93351 spell own
    // its weapon damage and chain-target selection.
    //
    creature->CastSpell(
        victim,
        SPELL_MANASTORM_CLEAVE,
        true);
}

uint32 ManastormMgr::ScaleCreatureDamage(
    Unit* attacker,
    Unit* victim,
    uint32 damage,
    DamageEffectType damageType)
{
    if (!attacker || !victim || !damage)
        return damage;

    Creature* creature = attacker->ToCreature();
    if (!creature ||
        creature->GetEntry() == NPC_MANASTORM_HEART ||
        creature->IsTrigger() ||
        creature->IsPet() ||
        IsPlayerControlledCreature(creature))
    {
        return damage;
    }

    Map* map = creature->GetMap();
    if (!map ||
        !map->GetInstanceId() ||
        victim->GetMap() != map)
        return damage;

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run ||
        (run->GetState() != ManastormRunState::Active &&
            run->GetState() != ManastormRunState::StageComplete))
    {
        return damage;
    }

    ManastormScalingPoint const& scaling =
        run->GetScaling();

    double multiplier =
        scaling.GlobalDamageMultiplier;

    switch (damageType)
    {
    case DIRECT_DAMAGE:
        multiplier *=
            scaling.MeleeMultiplier;
        break;

    case SPELL_DIRECT_DAMAGE:
    case DOT:
        multiplier *=
            scaling.SpellMultiplier;
        break;

    default:
        return damage;
    }

    //
    // Chaotic Link increases damage only for the exact objective boss.
    //
    // Recovered Ascension value:
    // +10% damage per Link.
    //
    if (IsObjectiveBoss(
        creature,
        *run))
    {
        multiplier *=
            GetChaoticLinkDamageMultiplier(
                *run);
    }

    return ScaleUnsignedValue(
        damage,
        multiplier);
}

void ManastormMgr::OnUnitEnterCombat(
    Unit* unit,
    Unit* /*victim*/)
{
    if (!unit)
        return;

    Creature* creature =
        unit->ToCreature();

    if (!creature ||
        !creature->IsAlive())
    {
        return;
    }

    Map* map =
        creature->GetMap();

    if (!map ||
        !map->GetInstanceId())
    {
        return;
    }

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run ||
        run->GetState() !=
            ManastormRunState::Active)
    {
        return;
    }

    ManastormSegment const& segment =
        run->GetSegment();

    //
    // Native Shade of Eranikus aggro sets DATA_ERANIKUS_FIGHT, which
    // calls SetInCombatWithZone() on every living Dragonkin registered
    // by the Sunken Temple instance. In a normal clear most of those
    // creatures are already dead. In an isolated Manastorm stage they
    // are still alive across the dungeon and would all rush the party.
    //
    // Preserve Eranikus' own SmartAI and abilities, but suppress only
    // that dungeon-wide assist side effect inside the private Manastorm
    // Eranikus stage. Normal Sunken Temple remains untouched.
    //
    if (segment.NativeMapId !=
            MANASTORM_MAP_SUNKEN_TEMPLE ||
        segment.NativeObjectiveCreatureEntry !=
            NPC_SHADE_OF_ERANIKUS ||
        creature->GetEntry() ==
            NPC_SHADE_OF_ERANIKUS ||
        creature->GetCreatureType() !=
            CREATURE_TYPE_DRAGONKIN)
    {
        return;
    }

    ObjectGuid const objectiveGuid =
        run->GetObjectiveCreatureGuid();

    if (objectiveGuid.IsEmpty())
        return;

    Creature* eranikus =
        ObjectAccessor::GetCreature(
            *creature,
            objectiveGuid);

    if (!eranikus ||
        eranikus->GetEntry() !=
            NPC_SHADE_OF_ERANIKUS ||
        !eranikus->IsInCombat())
    {
        return;
    }

    CreatureAI* ai =
        creature->AI();

    if (!ai)
        return;

    LOG_DEBUG(
        LOG_FILTER,
        "Suppressed native Eranikus dungeon-wide Dragonkin assist in "
        "Manastorm: run={} segment={} spawn={} entry={} guid={}.",
        run->GetRunId(),
        segment.SegmentId,
        creature->GetSpawnId(),
        creature->GetEntry(),
        creature->GetGUID().GetRawValue());

    ai->EnterEvadeMode();
}

void ManastormMgr::OnUnitDeath(
    Unit* unit,
    Unit* /*killer*/)
{
    if (!unit)
        return;

    //
    // Player deaths are part of the Endless failure /
    // resurrection system.
    //
    if (Player* player =
        unit->ToPlayer())
    {
        HandlePlayerDeath(
            player);

        return;
    }

    Creature* creature =
        unit->ToCreature();

    if (!creature ||
        creature->GetEntry() ==
        NPC_MANASTORM_HEART)
    {
        return;
    }

    Map* map =
        creature->GetMap();

    if (!map ||
        !map->GetInstanceId())
    {
        return;
    }

    ManastormRun* run =
        GetRunForStage(
            map->GetId(),
            map->GetInstanceId());

    if (!run ||
        run->GetState() !=
        ManastormRunState::Active)
    {
        return;
    }

    //
    // Greedy Demon resolution is also completely separate from ordinary
    // trash death: no affix death event, Heart roll, Keeper roll, route
    // progress or objective processing is allowed for this treasure mob.
    //
    if (ManastormGreedyDemon::Instance()
        .IsActiveGreedyDemon(
            creature,
            *run))
    {
        ManastormGreedyDemon::Instance()
            .OnKilled(
                creature,
                *run);

        return;
    }

    //
    // Treasure Keeper reward resolution is intentionally separate from
    // objective/cache pity and ordinary trash death processing.
    //
    if (ManastormRewards::Instance()
        .IsActiveTreasureKeeper(
            creature,
            *run))
    {
        ManastormRewards::Instance()
            .OnTreasureKeeperKilled(
                *run);

        BroadcastClientState(
            *run);

        return;
    }

    //
    // AFFIX EVENTS MUST RUN BEFORE SPECIALIZED DEATH LOGIC.
    //
    // Chaotic Link route processing below deliberately contains
    // several early returns. Dispatching affixes here guarantees
    // OnDeath affixes such as Mana Bomb work for normal route
    // creatures as well.
    //
    ManastormAffixEngine::Instance()
        .OnCreatureDeath(
            creature,
            *run);

    ManastormSegment const& segment =
        run->GetSegment();

    ObjectGuid const objectiveGuid =
        run->GetObjectiveCreatureGuid();

    bool const isObjectiveBoss =
        !objectiveGuid.IsEmpty() &&
        objectiveGuid ==
        creature->GetGUID();

    bool const isObjectiveCreature =
        isObjectiveBoss ||
        creature->GetEntry() ==
            segment.ObjectiveCreatureEntry;

    //
    // ORIGINAL-STYLE TRASH HEART FLOW
    //
    // Ordinary stage monsters receive one 75% Heart roll on death.
    // The corpse supplies the origin position only. SpawnHeartProjectile()
    // creates a short-lived invisible WORLD_TRIGGER that remains alive long
    // enough to cast 991507, after which the recovered DBC performs:
    //
    //     991507 -> 991509 -> 900025
    //
    // OnCreatureAddWorld() then registers 900025 and applies 991511.
    //
    // This covers one-shots without shortcutting directly to 991509.
    //
    if (!isObjectiveCreature)
    {
        TrySpawnTrashHeart(
            creature,
            *run);

        //
        // Separate special-encounter roll:
        //
        // eligible trash kills increase the Treasure Keeper chance.
        // This does NOT consume or modify the normal Cache pity meter.
        //
        ManastormRewards::Instance()
            .TrySpawnTreasureKeeper(
                creature,
                *run);
    }

    //
    // CHAOTIC LINK ROUTE TRASH
    //
    // A creature can break one Link only when:
    //
    // - it is not the objective boss;
    // - it is a static DB spawn;
    // - its persistent spawn GUID belongs to this segment's authored route;
    // - that spawn has not already been consumed during this stage;
    // - at least one Chaotic Link remains.
    //
    if (!isObjectiveBoss)
    {
        //
        // Never treat the objective entry itself as trash, even if the
        // objective GUID has not loaded/registered yet.
        //
        if (creature->GetEntry() ==
            segment.ObjectiveCreatureEntry)
        {
            return;
        }

        if (!run->GetChaoticLinkStacks())
            return;

        ObjectGuid::LowType const spawnId =
            creature->GetSpawnId();

        //
        // Dynamically summoned creatures normally have SpawnId 0 and can
        // therefore never become Link breakers through this system.
        //
        if (!spawnId)
            return;

        if (!run->ConsumeChaoticLinkSpawn(
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

        //
        // The objective might not be loaded yet in a very large dungeon.
        //
        // That is fine: the authoritative run stack count is already
        // reduced. When the boss later enters the world,
        // OnCreatureAddWorld() will apply the current stack count.
        //
        Creature* objectiveBoss = nullptr;

        if (!objectiveGuid.IsEmpty())
        {
            objectiveBoss =
                ObjectAccessor::GetCreature(
                    *creature,
                    objectiveGuid);
        }

        if (objectiveBoss &&
            objectiveBoss->IsAlive())
        {
            uint32 const oldMaxHealth =
                objectiveBoss->GetMaxHealth();

            double const healthPct =
                oldMaxHealth
                ? double(
                    objectiveBoss->GetHealth()) /
                double(oldMaxHealth)
                : 1.0;

            //
            // Synchronize the real recovered Ascension aura.
            //
            // At zero stacks this removes spell 93459 completely.
            //
            SyncChaoticLinkAura(
                objectiveBoss,
                *run);

            //
            // Preserve the boss's current health percentage while
            // lowering its maximum HP.
            //
            ApplyChaoticLinkBossHealth(
                objectiveBoss,
                *run,
                healthPct);
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} broke one Chaotic Link: "
            "segment={} killedEntry={} spawnId={} "
            "stacks={} -> {} unusedRouteSpawns={}.",
            run->GetRunId(),
            segment.SegmentId,
            creature->GetEntry(),
            spawnId,
            uint32(previousStacks),
            uint32(newStacks),
            run->GetUnusedChaoticLinkSpawnCount());

        BroadcastClientState(
            *run);

        //
        // This was normal route trash, not the stage objective.
        //
        return;
    }

    //
    // OBJECTIVE BOSS DEATH
    //
    if (creature->GetEntry() !=
        segment.ObjectiveCreatureEntry)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} objective GUID {} died with unexpected "
            "entry {} (expected {}). Stage was not completed.",
            run->GetRunId(),
            objectiveGuid.GetRawValue(),
            creature->GetEntry(),
            segment.ObjectiveCreatureEntry);

        return;
    }

    //
 // The objective boss is dead.
 //
 // Persist progression BEFORE allowing the stage
 // transition. The next-stage generator may need the
 // newly queued or newly completed unlock immediately.
 //
    std::vector<ManastormProgressionToastEvent>
        progressionToasts;

    std::string progressionError;

    if (!ManastormProgression::RecordStageCompletion(
        *run,
        progressionToasts,
        progressionError))
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} could not persist "
            "progression after completing depth {}: {}",
            run->GetRunId(),
            run->GetDepth(),
            progressionError);

        FailRun(
            *run,
            "Progression persistence failed.");

        return;
    }

    //
// Progression persistence succeeded.
//
// Now present every unlock event generated by
// this stage completion.
//
// There can deliberately be more than one.
//
    for (ManastormProgressionToastEvent const& toast :
        progressionToasts)
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<
                HighGuid::Player>(
                    toast.CharacterGuid));

        if (!member)
            continue;

        SendUnlockToast(
            member,
            toast.MessageId);
    }

    //
    // Objective is dead: clear the Skull marker before transitioning.
    //
    SetEndlessObjectiveSkull(
        *run,
        ObjectGuid::Empty);

    run->SetState(
        ManastormRunState::StageComplete);

    // Spawn the recovered Ascension presentation at the dead objective:
    //
    //     80910 invisible controller
    //       + 93305 Manastorm Portal Effect
    //
    // A player may interact with it to advance immediately. If nobody does,
    // the existing five-second automatic transition remains the fallback.
    SpawnStagePortal(
        map,
        *run,
        creature->GetPosition());

    //
    // One recovered BossKill/portal line is chosen for this completion.
    // The VO component delays only the explicit PortalsReady alternatives so
    // they cannot precede the actual portal summon above.
    //
    ManastormVoiceOfMillhouse::OnObjectiveComplete(
        *run);

    ManastormClientBridge::Instance()
        .BroadcastStageCompleted(*run);

    _transitionTimers[
        run->GetRunId()] =
        STAGE_TRANSITION_DELAY_MS;

        BroadcastClientState(
            *run);

        LOG_INFO(
            LOG_FILTER,
            "Manastorm objective complete: run={} depth={} segment={} "
            "map={} instance={} entry={} guid={}. "
            "Transition scheduled in {} ms.",
            run->GetRunId(),
            run->GetDepth(),
            segment.SegmentId,
            segment.MapId,
            run->GetInstanceId(),
            segment.ObjectiveCreatureEntry,
            objectiveGuid.GetRawValue(),
            STAGE_TRANSITION_DELAY_MS);

        for (ObjectGuid::LowType memberGuid :
        run->GetMembers())
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<HighGuid::Player>(
                        memberGuid));

            if (member)
            {
                member->SendSystemMessage(
                    "Manastorm: objective complete. "
                    "Use the portal to continue now, or the next depth "
                    "will begin automatically in 5 seconds.");
            }
        }
}

bool ManastormMgr::UseStagePortal(
    Player* player,
    Creature* portal,
    std::string& error)
{
    error.clear();

    if (!player || !portal)
    {
        error =
            "A player and the active Manastorm portal are required.";

        return false;
    }

    if (portal->GetEntry() !=
        NPC_STAGE_PORTAL)
    {
        error =
            "That creature is not the active Manastorm stage portal.";

        return false;
    }

    ManastormRun* run =
        GetRunFor(player);

    if (!run)
    {
        error =
            "You are not part of an active Manastorm run.";

        return false;
    }

    ObjectGuid::LowType const playerGuid =
        player->GetGUID().GetCounter();

    bool const firstCrossing =
        run->GetState() ==
            ManastormRunState::StageComplete;

    if (firstCrossing)
    {
        ManastormSegment const& segment =
            run->GetSegment();

        if (player->GetMapId() !=
                segment.MapId ||
            player->GetInstanceId() !=
                run->GetInstanceId() ||
            portal->GetMapId() !=
                segment.MapId ||
            portal->GetInstanceId() !=
                run->GetInstanceId() ||
            run->GetPortalGuid().IsEmpty() ||
            portal->GetGUID() !=
                run->GetPortalGuid())
        {
            error =
                "That portal does not belong to your current Manastorm stage.";

            return false;
        }

        uint32 const completedDepth =
            run->GetDepth();

        std::string transitionError;

        uint64 const runId = run->GetRunId();
        if (!TransitionToNextStage(
                *run,
                transitionError,
                playerGuid,
                false))
        {
            if (_runs.find(runId) == _runs.end())
            {
                error = transitionError;
                return false;
            }

            LOG_ERROR(
                LOG_FILTER,
                "Manastorm run {} failed to prepare the next stage "
                "after player {} used the portal at depth {}: {}",
                run->GetRunId(),
                playerGuid,
                completedDepth,
                transitionError);

            error =
                transitionError.empty()
                ? "The next Manastorm stage could not be prepared."
                : transitionError;

            FailRun(
                *run,
                std::string(
                    "Stage transition failed after portal click: ") +
                    error);

            return false;
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm run {} prepared depth {} after player {} crossed "
            "the stage portal. Other members remain in the completed stage "
            "until they use the portal or the five-second fallback expires.",
            run->GetRunId(),
            run->GetDepth(),
            playerGuid);

        return true;
    }

    if (!run->HasPreviousStage() ||
        !run->IsPendingStageTransfer(
            playerGuid))
    {
        error =
            "The current Manastorm stage is not waiting for you to cross.";

        return false;
    }

    ManastormSegment const& previous =
        run->GetPreviousSegment();

    if (player->GetMapId() !=
            previous.MapId ||
        player->GetInstanceId() !=
            run->GetPreviousInstanceId() ||
        portal->GetMapId() !=
            previous.MapId ||
        portal->GetInstanceId() !=
            run->GetPreviousInstanceId() ||
        run->GetPreviousPortalGuid().IsEmpty() ||
        portal->GetGUID() !=
            run->GetPreviousPortalGuid())
    {
        error =
            "That portal is not the completed-stage portal assigned to you.";

        return false;
    }

    if (!TransferMemberToCurrentStage(
            player,
            *run,
            error))
    {
        return false;
    }

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} transferred member {} to prepared depth {} "
        "after that member used the completed-stage portal.",
        run->GetRunId(),
        playerGuid,
        run->GetDepth());

    return true;
}

bool ManastormMgr::TransitionToNextStage(
    ManastormRun& run,
    std::string& error,
    ObjectGuid::LowType immediateMemberGuid,
    bool transferAll)
{
    error.clear();

    if (run.HasPreviousStage())
    {
        if (!transferAll)
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            immediateMemberGuid));

            if (!member)
            {
                error =
                    "The Manastorm member disconnected before crossing the portal.";

                return false;
            }

            return TransferMemberToCurrentStage(
                member,
                run,
                error);
        }

        run.AllowStartWithMissingMembers();

        std::vector<ObjectGuid::LowType>
            pending(
                run.GetPendingStageTransferMembers()
                    .begin(),
                run.GetPendingStageTransferMembers()
                    .end());

        for (ObjectGuid::LowType guid :
            pending)
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            guid));

            if (!member ||
                !member->GetSession() ||
                !member->IsInWorld())
            {
                // The five-second fallback has expired. An offline member is
                // no longer allowed to keep the completed stage alive; on
                // reconnect OnPlayerLogin routes them into the current stage.
                run.MarkStageTransferComplete(
                    guid);

                continue;
            }

            if (member->IsBeingTeleported())
                continue;

            std::string transferError;

            if (!TransferMemberToCurrentStage(
                    member,
                    run,
                    transferError))
            {
                error =
                    "Could not auto-transfer connected member " +
                    std::to_string(guid) +
                    " after the five-second fallback: " +
                    transferError;

                return false;
            }
        }

        for (ObjectGuid::LowType guid :
            run.GetMembers())
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            guid));

            if (member &&
                member->IsInWorld() &&
                !member->IsBeingTeleported() &&
                member->GetMapId() ==
                    run.GetSegment().MapId &&
                member->GetInstanceId() ==
                    run.GetInstanceId())
            {
                if (!OnPlayerEnterMap(
                        member->FindMap(),
                        member))
                {
                    error = "The Manastorm run ended during stage activation.";
                    return false;
                }

                break;
            }
        }

        if (!run.HasPendingStageTransfers())
        {
            FinishPreviousStageTransition(
                run);
        }

        return true;
    }

    if (run.GetState() !=
        ManastormRunState::StageComplete)
    {
        error =
            "The Manastorm run is not ready to prepare another stage.";

        return false;
    }

    if (run.GetDepth() ==
        std::numeric_limits<uint32>::max())
    {
        error =
            "The Endless depth counter reached its maximum value.";

        return false;
    }

    Player* creator = nullptr;

    if (immediateMemberGuid)
    {
        creator =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<
                    HighGuid::Player>(
                        immediateMemberGuid));
    }

    if (!creator ||
        !creator->GetSession() ||
        !creator->IsInWorld() ||
        creator->IsBeingTeleported())
    {
        creator = nullptr;

        for (ObjectGuid::LowType guid :
            run.GetMembers())
        {
            Player* candidate =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            guid));

            if (candidate &&
                candidate->GetSession() &&
                candidate->IsInWorld() &&
                !candidate->IsBeingTeleported())
            {
                creator =
                    candidate;
                break;
            }
        }
    }

    if (!creator)
    {
        error =
            "No connected Manastorm member is ready to create the next stage.";

        return false;
    }

    ObjectGuid::LowType const creatorGuid =
        creator->GetGUID().GetCounter();

    uint32 const previousDepth =
        run.GetDepth();

    uint32 const previousSegmentId =
        run.GetSegment().SegmentId;

    uint32 const previousMapId =
        run.GetSegment().MapId;

    uint32 const previousInstanceId =
        run.GetInstanceId();

    uint32 nextDepth =
        previousDepth + 1;

    ManastormProgressionSnapshot
        progression;

    if (!ManastormProgression::LoadSnapshot(
            run.GetOwnerGuid(),
            run.GetMode(),
            run.IsEndgame(),
            progression,
            error))
    {
        return false;
    }

    // Resume the destination track after a level-cap transition. Pending
    // unlock introductions take priority over ordinary five-floor checkpoints.
    if (run.IsEndgame() != (run.GetSegment().Difficulty == 2))
    {
        if (progression.PendingIntroDepth)
        {
            nextDepth = progression.PendingIntroDepth;
        }
        else
        {
            std::vector<uint32> enterableDepths;
            ManastormProgression::BuildEnterableDepths(progression, enterableDepths);
            nextDepth = enterableDepths.front();
        }
    }

    ManastormGenerator generator;

    uint32 const forcedIntroSegmentId =
        progression.PendingIntroDepth ==
            nextDepth
        ? (run.IsEndgame()
            ? progression
                .PendingEndgameIntroSegmentId
            : progression
                .PendingIntroSegmentId)
        : 0;

    ManastormSegment const* nextSegment =
        generator.SelectSegment(
            nextDepth,
            run.GetSeed(),
            progression.UnlockedSegmentIds,
            run.IsEndgame(),
            previousSegmentId,
            forcedIntroSegmentId,
            run.GetRecentObjectiveKeys());

    if (!nextSegment)
    {
        error =
            "No enabled Manastorm segment is eligible for the next depth.";

        return false;
    }

    ManastormScalingPoint const
        nextScaling =
            ManastormDataStore::Instance()
                .GetScalingForDepth(
                    nextDepth,
                    uint32(
                        run.GetMembers()
                            .size()));

    for (ObjectGuid::LowType memberGuid :
        run.GetMembers())
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (member)
        {
            ManastormAffixEngine::Instance()
                .RemoveActivePlayerAffixes(
                    member,
                    run);
        }
    }

    run.BeginPreviousStageTransition();

    // The completed map remains alive as a five-second portal waiting room,
    // but it no longer owns combat callbacks once the next stage exists.
    _stageRunIds.erase(
        MakeStageKey(
            previousMapId,
            previousInstanceId));

    run.SetState(
        ManastormRunState::Transitioning);

    uint8 const nextCreatureLevel =
        ResolveCreatureLevel(
            run.GetMembers(),
            creator->GetLevel());

    run.PrepareNextStage(
        nextCreatureLevel,
        nextDepth,
        *nextSegment,
        nextScaling);

    ManastormAffixEngine::Instance()
        .InitializeStage(
            run,
            progression.UnlockedAffixIds);

    if (!PrepareStage(
            creator,
            run,
            error,
            creatorGuid))
    {
        return false;
    }

    if (transferAll)
    {
        run.AllowStartWithMissingMembers();

        std::vector<ObjectGuid::LowType>
            pending(
                run.GetPendingStageTransferMembers()
                    .begin(),
                run.GetPendingStageTransferMembers()
                    .end());

        for (ObjectGuid::LowType guid :
            pending)
        {
            if (guid == creatorGuid)
                continue;

            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            guid));

            if (!member ||
                !member->GetSession() ||
                !member->IsInWorld())
            {
                run.MarkStageTransferComplete(
                    guid);

                continue;
            }

            if (member->IsBeingTeleported())
                continue;

            std::string transferError;

            if (!TransferMemberToCurrentStage(
                    member,
                    run,
                    transferError))
            {
                error =
                    "Could not auto-transfer connected member " +
                    std::to_string(guid) +
                    " while opening the next Manastorm stage: " +
                    transferError;

                return false;
            }
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} prepared depth {} segment {} from completed "
        "depth {} segment {}. Previous map={} instance={} remains available "
        "only for pending portal transfers.",
        run.GetRunId(),
        nextDepth,
        nextSegment->SegmentId,
        previousDepth,
        previousSegmentId,
        previousMapId,
        previousInstanceId);

    creator->SendSystemMessage(
        "Manastorm: next stage prepared. "
        "Other members have until the five-second fallback to cross.");

    return true;
}

void ManastormMgr::UpdateHeartPickups(uint32 diff)
{
    for (auto& runPair : _runs)
    {
        if (!runPair.second)
            continue;

        ManastormRun& run =
            *runPair.second;

        if (run.GetState() != ManastormRunState::Active &&
            run.GetState() != ManastormRunState::StageComplete)
        {
            continue;
        }

        auto& activeHearts =
            run.GetActiveHeartGuids();

        if (activeHearts.empty())
            continue;

        Map* map = sMapMgr->FindMap(run.GetSegment().MapId, run.GetInstanceId());
        if (!map)
            continue;

        for (auto itr = activeHearts.begin();
            itr != activeHearts.end();)
        {
            ObjectGuid const heartGuid =
                itr->first;

            uint32& remainingArmTime =
                itr->second;

            Creature* heart = map->GetCreature(heartGuid);

            if (!heart ||
                !heart->IsInWorld() ||
                heart->GetEntry() != NPC_MANASTORM_HEART)
            {
                itr = activeHearts.erase(itr);
                continue;
            }

            if (remainingArmTime > diff)
            {
                remainingArmTime -= diff;
                ++itr;
                continue;
            }

            remainingArmTime = 0;

            Player* player = nullptr;
            for (auto guid : run.GetMembers())
            {
                Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid));
                if (member && member->IsInWorld() && member->IsAlive() && !member->IsBeingTeleported() &&
                    member->FindMap() == map && member->GetExactDist(heart) <= HEART_PICKUP_DISTANCE)
                {
                    player = member;
                    break;
                }
            }
            if (!player)
            {
                ++itr;
                continue;
            }

            //
            // 991510 = Manastorm Heart Healing.
            //
            // The player casts it on self so the recovered level-based heal
            // uses the player's level:
            //
            //     heal = 10 + (5 * player level)
            //     mana = 15% maximum mana
            //
            player->CastSpell(
                player,
                SPELL_MANASTORM_HEART_HEALING,
                true);

            LOG_INFO(
                LOG_FILTER,
                "Manastorm run {} player {} consumed Manastorm Heart {}.",
                run.GetRunId(),
                player->GetGUID().GetCounter(),
                heartGuid.GetRawValue());

            itr = activeHearts.erase(itr);

            heart->DespawnOrUnsummon();
        }
    }
}

void ManastormMgr::Update(uint32 diff)
{
    //
    // Live Ascension entry protection has a ~2 minute maximum. Movement or
    // player combat can request activation earlier; timeout is only the final
    // safeguard against an indefinitely protected PREPARING stage.
    //
    for (auto const& pair :
        _runs)
    {
        ManastormRun* run =
            pair.second.get();

        if (!run ||
            run->GetState() !=
                ManastormRunState::Preparing ||
            run->CanStartWithMissingMembers())
        {
            continue;
        }

        if (run->UpdatePreparationProtection(
                diff))
        {
            run->AllowStartWithMissingMembers();

            LOG_INFO(
                LOG_FILTER,
                "Manastorm run {} reached the 2-minute preparation "
                "protection limit; stage activation requested.",
                run->GetRunId());
        }
    }

    // Empty private instances expire after disconnects. Release their run and
    // membership indexes even if no player reconnects to trigger recovery.
    if (_runValidationTimer <= diff)
    {
        _runValidationTimer = 1000;
        for (auto itr = _runs.begin(); itr != _runs.end();)
        {
            ManastormRun& run = *itr->second;
            ++itr;
            if (run.GetInstanceId() &&
                !sMapMgr->FindMap(run.GetSegment().MapId, run.GetInstanceId()))
            {
                FailRun(
                    run,
                    "The private stage instance has expired.");
            }
            else if (run.GetState() ==
                    ManastormRunState::Preparing &&
                run.GetInstanceId())
            {
                for (auto guid :
                    run.GetMembers())
                {
                    Player* member =
                        ObjectAccessor::FindConnectedPlayer(
                            ObjectGuid::Create<
                                HighGuid::Player>(
                                    guid));

                    if (!member ||
                        !member->IsInWorld() ||
                        member->IsBeingTeleported() ||
                        member->GetMapId() !=
                            run.GetSegment().MapId ||
                        member->GetInstanceId() !=
                            run.GetInstanceId())
                    {
                        continue;
                    }

                    //
                    // The initial map-entry callback can still see the player
                    // as teleporting. Retry the protected-arrival narrator
                    // here once the player is fully settled in the instance.
                    // OnPlayerEnteredProtection() is duplicate-safe per member.
                    //
                    ManastormVoiceOfMillhouse::OnPlayerEnteredProtection(
                        run,
                        member);

                    GameTele const* entrance =
                        sObjectMgr->GetGameTele(
                            run.GetSegment()
                                .StartGameTeleId);

                    ApplySafetyBubbleProtection(member, run);
                    for (Unit* companion : member->m_Controlled)
                        if (companion && companion->GetOwnerGUID() == member->GetGUID())
                            ApplySafetyBubbleProtection(companion, run);

                    if (run.StartRequested() ||
                        (entrance &&
                            member->IsAlive() &&
                            member->GetExactDist(
                                entrance->position_x,
                                entrance->position_y,
                                entrance->position_z) >
                                8.0f))
                    {
                        OnPlayerEnterMap(
                            member->FindMap(),
                            member);

                        break;
                    }
                }
            }
            else if ((run.GetState() ==
                        ManastormRunState::Active ||
                    run.GetState() ==
                        ManastormRunState::StageComplete) &&
                run.GetInstanceId())
            {
                //
                // Safety Bubble protection belongs only to PREPARING.
                // Remove any stale/re-applied controller or combat-preventer
                // aura while the authoritative stage is already active.
                //
                for (auto guid :
                    run.GetMembers())
                {
                    Player* member =
                        ObjectAccessor::FindConnectedPlayer(
                            ObjectGuid::Create<
                                HighGuid::Player>(
                                    guid));

                    if (member &&
                        member->IsInWorld() &&
                        !member->IsBeingTeleported() &&
                        member->GetMapId() ==
                            run.GetSegment().MapId &&
                        member->GetInstanceId() ==
                            run.GetInstanceId())
                    {
                        ClearSafetyBubble(
                            member);
                    }
                }
            }
        }
    }
    else
        _runValidationTimer -= diff;

    UpdateManastormPotionCharges(diff);

    ManastormVoiceOfMillhouse::Update(
        diff);

    if (_heartPickupCheckTimer <= diff)
    {
        _heartPickupCheckTimer =
            HEART_PICKUP_CHECK_INTERVAL_MS;

        UpdateHeartPickups(
            HEART_PICKUP_CHECK_INTERVAL_MS);
    }
    else
    {
        _heartPickupCheckTimer -= diff;
    }

    if (_transitionTimers.empty())
        return;

    for (auto itr = _transitionTimers.begin();
        itr != _transitionTimers.end();)
    {
        uint64 const runId = itr->first;

        auto runItr = _runs.find(runId);
        if (runItr == _runs.end() || !runItr->second)
        {
            itr = _transitionTimers.erase(itr);
            continue;
        }

        ManastormRun& run = *runItr->second;

        bool const waitingForPortal =
            run.GetState() ==
                ManastormRunState::StageComplete ||
            (run.HasPreviousStage() &&
             run.GetState() ==
                ManastormRunState::Preparing);

        if (!waitingForPortal)
        {
            itr = _transitionTimers.erase(
                itr);

            continue;
        }

        if (itr->second > diff)
        {
            itr->second -= diff;
            ++itr;
            continue;
        }

        itr = _transitionTimers.erase(
            itr);

        std::string error;

        if (TransitionToNextStage(
                run,
                error,
                0,
                true))
        {
            continue;
        }

        if (_runs.find(runId) == _runs.end())
            continue;

        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} failed the five-second stage fallback "
            "at depth {}: {}",
            run.GetRunId(),
            run.GetDepth(),
            error);

        FailRun(
            run,
            std::string(
                "Stage transition fallback failed: ") +
            error);
    }
}

bool ManastormMgr::HandleReleaseAfterWipe(Player* player)
{
    ManastormRun* run = GetRunFor(player);
    if (!run || run->GetState() != ManastormRunState::AwaitingExit)
        return false;

    FailRun(*run, "All run members are dead.", 0, ManastormFailureExit::FactionHub);
    return true;
}

bool ManastormMgr::StopRun(Player* player, std::string& error)
{
    error.clear();

    if (!player)
    {
        error = "A player is required.";
        return false;
    }

    ManastormRun* run = GetRunFor(player);
    if (!run)
    {
        error = "You are not part of an active Manastorm run.";
        return false;
    }

    if (run->GetState() == ManastormRunState::AwaitingExit)
    {
        FailRun(*run, "All run members are dead.", 0, ManastormFailureExit::FactionHub);
        return true;
    }

    uint64 const runId = run->GetRunId();
    std::vector<ObjectGuid::LowType> const members = run->GetMembers();

    bool const hadPreviousStage =
        run->HasPreviousStage();

    uint32 const previousStageMapId =
        hadPreviousStage
        ? run->GetPreviousSegment().MapId
        : MAPID_INVALID;

    uint32 const previousStageInstanceId =
        hadPreviousStage
        ? run->GetPreviousInstanceId()
        : 0;

    for (ObjectGuid::LowType memberGuid : members)
        ManastormRewards::Instance().SettlePendingCurrency(memberGuid);

    run->SetState(
        ManastormRunState::Finished);

    BroadcastClientState(
        *run);

    for (ObjectGuid::LowType memberGuid : members)
    {
        auto itr = _memberRunIds.find(memberGuid);
        if (itr != _memberRunIds.end() && itr->second == runId)
            _memberRunIds.erase(itr);
    }

    if (run->GetInstanceId())
    {
        _stageRunIds.erase(
            MakeStageKey(
                run->GetSegment().MapId,
                run->GetInstanceId()));
    }

    for (ObjectGuid::LowType memberGuid :
    run->GetMembers())
    {
        Player* member =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(
                    memberGuid));

        if (!member)
        {
            _manastormPotionCharges.erase(
                memberGuid);

            continue;
        }

        ManastormAffixEngine::Instance()
            .RemoveActivePlayerAffixes(
                member,
                *run);

        //
        // Endless-only tools disappear when the
        // player leaves the run.
        //
        RemoveBaselineRunItems(
            member,
            true);

        // Cogsley (80919) is a Manastorm-only non-combat companion.
        // Remove it before leaving the private stage so it cannot leak into
        // the normal world after a stop/failure teleport.
        DespawnCogsleyCompanion(
            member);

        // Returning from a private world copy to the public copy can use the
        // same map ID. Force a far transfer in that case; otherwise TeleportTo
        // would perform an in-instance near teleport and strand the player in
        // the disposable Manastorm map.
        bool const leavingScriptedPrivateStage =
            member->IsInWorld() &&
            member->GetMap() &&
            member->GetMap()->IsScriptedPrivateInstance();

        RestoreOriginalDifficulties(member);
        member->ClearScriptedPrivateInstance();

        //
        // Ensure the player is not left fighting creatures
        // while the far teleport is initiated.
        //
        member->CombatStopWithPets(
            true);

        if (WorldLocation const* location = (*run).GetReturnLocation(memberGuid))
        {
            member->m_recallMap = location->GetMapId();
            member->m_recallX = location->GetPositionX();
            member->m_recallY = location->GetPositionY();
            member->m_recallZ = location->GetPositionZ();
            member->m_recallO = location->GetOrientation();
        }

        if (!member->IsAlive())
        {
            member->ResurrectPlayer(1.0f, false);
            member->SpawnCorpseBones();
        }

        uint32 const returnMap =
            member->m_recallMap;

        float const returnX =
            member->m_recallX;

        float const returnY =
            member->m_recallY;

        float const returnZ =
            member->m_recallZ;

        float const returnO =
            member->m_recallO;

        LOG_INFO(
            LOG_FILTER,
            "Manastorm returning player {} from run {} "
            "to saved location map={} position=({}, {}, {}, {}).",
            memberGuid,
            runId,
            returnMap,
            returnX,
            returnY,
            returnZ,
            returnO);

        if (!member->TeleportTo(
            returnMap,
            returnX,
            returnY,
            returnZ,
            returnO,
            0,
            nullptr,
            leavingScriptedPrivateStage))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm failed to return player {} "
                "from run {} to saved location "
                "map={} position=({}, {}, {}, {}).",
                memberGuid,
                runId,
                returnMap,
                returnX,
                returnY,
                returnZ,
                returnO);

            member->SendSystemMessage(
                "Manastorm: the run ended, but returning "
                "you to your previous location failed.");
        }
    }

    if (Map* stage =
        sMapMgr->FindMap(
            run->GetSegment().MapId,
            run->GetInstanceId()))
    {
        if (stage->IsScriptedPrivateInstance())
            stage->RequestScriptedPrivateUnload();
    }

    if (hadPreviousStage &&
        previousStageMapId !=
            MAPID_INVALID &&
        previousStageInstanceId)
    {
        if (Map* previous =
            sMapMgr->FindMap(
                previousStageMapId,
                previousStageInstanceId))
        {
            if (previous->
                IsScriptedPrivateInstance())
            {
                previous->
                    RequestScriptedPrivateUnload();
            }
        }
    }

    _transitionTimers.erase(runId);

    ManastormVoiceOfMillhouse::ClearRun(
        runId);

    _runs.erase(runId);

    LOG_INFO(LOG_FILTER,
        "Stopped Manastorm run {} by player {}.",
        runId, player->GetGUID().GetCounter());

    return true;
}

ManastormRun* ManastormMgr::GetRunFor(Player const* player)
{
    return player ? GetRunForGuid(player->GetGUID().GetCounter()) : nullptr;
}

ManastormRun const* ManastormMgr::GetRunFor(Player const* player) const
{
    return player ? GetRunForGuid(player->GetGUID().GetCounter()) : nullptr;
}

ManastormRun* ManastormMgr::GetRunForGuid(ObjectGuid::LowType guid)
{
    auto indexItr = _memberRunIds.find(guid);
    if (indexItr == _memberRunIds.end())
        return nullptr;

    auto runItr = _runs.find(indexItr->second);
    return runItr != _runs.end() ? runItr->second.get() : nullptr;
}

ManastormRun const* ManastormMgr::GetRunForGuid(ObjectGuid::LowType guid) const
{
    auto indexItr = _memberRunIds.find(guid);
    if (indexItr == _memberRunIds.end())
        return nullptr;

    auto runItr = _runs.find(indexItr->second);
    return runItr != _runs.end() ? runItr->second.get() : nullptr;
}

ManastormRun* ManastormMgr::GetRunForStage(
    uint32 mapId, uint32 instanceId)
{
    if (!instanceId)
        return nullptr;

    auto stageItr =
        _stageRunIds.find(
            MakeStageKey(mapId, instanceId));

    if (stageItr == _stageRunIds.end())
        return nullptr;

    auto runItr = _runs.find(stageItr->second);
    if (runItr == _runs.end() ||
        !runItr->second)
    {
        _stageRunIds.erase(stageItr);
        return nullptr;
    }

    ManastormRun* run = runItr->second.get();

    if (run->GetInstanceId() != instanceId ||
        run->GetSegment().MapId != mapId)
    {
        _stageRunIds.erase(stageItr);
        return nullptr;
    }

    return run;
}

uint32 ManastormMgr::ResolveAffixRankSpell(Unit const* caster, uint32 spellId)
{
    // These are payload/controller roles, not necessarily the catalog's marker.
    // Keep identical rank families and the existing Leeching/Reflecting callbacks.
    uint32 affixId = 0;
    uint8 role = 1;
    switch (spellId)
    {
        case 93489: affixId = 11; break;
        case 93365: affixId = 11; role = 2; break;
        case 93355: affixId = 13; break;
        case 93358: affixId = 13; role = 2; break;
        case 93423: affixId = 23; break;
        case 93420: affixId = 26; break;
        case 94761: affixId = 28; break;
        case 93378: affixId = 31; break;
        case 93380: affixId = 31; role = 2; break;
        case 93437: affixId = 33; break;
        case 93370: affixId = 61; break;
        case 93386: affixId = 101; break;
        case 93319: affixId = 93316; break;
        case 93342: affixId = 93341; break;
        case 93406: affixId = 93403; role = 2; break;
        case 93407: affixId = 93403; role = 3; break;
        case 94754: affixId = 93510; break;
        case 93412: affixId = 101; break;
        default: return spellId;
    }

    if (!caster || !caster->IsInWorld())
        return spellId;

    Map const* map = caster->FindMap();
    if (!map || !map->IsScriptedPrivateInstance())
        return spellId;

    ManastormRun* run = GetRunForStage(map->GetId(), map->GetInstanceId());
    if (!run ||
        (run->GetState() != ManastormRunState::Active &&
         run->GetState() != ManastormRunState::StageComplete) ||
        !run->HasStageAffix(affixId))
    {
        return spellId;
    }

    if (Player const* player = caster->ToPlayer())
    {
        if (GetRunFor(player) != run)
            return spellId;
    }
    else if (Creature const* creature = caster->ToCreature())
    {
        if (creature->IsControlledByPlayer() ||
            creature->IsCreatedByPlayer() ||
            creature->IsCharmedOwnedByPlayerOrPlayer() ||
            (!run->HasCreatureAffix(creature->GetGUID(), affixId) &&
             !ManastormAffixEngine::Instance().IsAffixHelperCreature(creature->GetEntry())))
        {
            return spellId;
        }
    }
    else
        return spellId;

    ManastormAffixDefinition const* definition =
        ManastormDataStore::Instance().GetAffixById(affixId);
    if (!definition)
        return spellId;

    uint32 const rankedSpell =
        definition->GetRankSpell(role, run->GetStageAffixRank(affixId));
    return rankedSpell && sSpellMgr->GetSpellInfo(rankedSpell) ? rankedSpell : spellId;
}
