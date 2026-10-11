/*
 * mod-coa-challenges (review split): shared umbrella header.
 * Generated from review-CoAChallenges.cpp by review-split/split.ps1.
 * Structs, small constants, extern globals + forward declarations shared
 * by the CoA.Challenges.*.cpp translation units. Not compiled directly.
 */
#ifndef COA_CHALLENGES_REVIEW_H
#define COA_CHALLENGES_REVIEW_H

#include "AscensionCoAConfig.h"
#include "ScriptMgr.h"
#include "Player.h"
#include "Bag.h"
#include "DBCStores.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"
#include "WorldPacket.h"
#include "Opcodes.h"
#include "Config.h"
#include "Log.h"
#include "DatabaseEnv.h"
#include "SpellMgr.h"
#include "SpellAuras.h"
#include "Spell.h"
#include "Group.h"
#include "GameEventMgr.h"
#include "ObjectAccessor.h"
#include "CharacterCache.h"
#include "Chat.h"
#include "CommandScript.h"
#include "CoA.Prestige.API.h"
#include "CoAChallengeParse.h"
#include "CoAChallengeInternal.h"
#include "MiscScript.h"
#include "TaskScheduler.h"
#include "StringFormat.h"
#include "SmartEnum.h"
#include "Timer.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cctype>
#include <chrono>
#include <ctime>
#include <memory>
#include <map>
#include <mutex>
#include <set>
#include <thread>
#include <utility>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace CoAChallenges
{

    // Broadcast colors, sampled from the live client's chat (2026-09-13):
    //   [TrialName] = FFA500, player name = 43C6DB, killer/cause = FF0000.
    // The body ("has completed their Trial!" / "(Level N) has been killed by")
    // is left uncolored so the client applies the SYSTEM chat default.
    char const* const TRIAL_COLOR = "|cffFFA500";
    char const* const PLAYER_COLOR = "|cff43C6DB";
    char const* const KILLER_COLOR = "|cffff0000";

    // Cause of death for the failure broadcast, resolved when known.
    // Creature/Player get a clickable link; Environment/Self/Mechanic are
    // literal red labels (Falling/Suicide/Starved/...).
    enum class KillerKind : uint8 { Unknown, Creature, Player, Environment, Self, Mechanic, Rule };

    // Failure broadcast. FailChallenge records the failure here for every cause
    // (death, shared fate, group leave). OnPlayerJustDied runs before
    // OnPlayerKilledByCreature / OnPlayerPVPKill, which fill in the killer;
    // the message is flushed on the next world tick.
    // killerSource is the guid whose death carries the killer info: the dead
    // player themselves, or (for shared fate) the member who actually died, so
    // every holder's line names the same killer.
    struct PendingFail
    {
        uint32 challengeID = 0;
        uint32 level = 1;
        KillerKind killerKind = KillerKind::Unknown;
        uint32 killerEntry = 0;
        std::string killerName;
        // When the failed challenge is part of the character's active custom
        // trial, the announcement shows the trial's name/icon instead.
        std::string displayName;
        std::string displayIcon;
    };

    // Killer of a player's most recent death, captured by
    // OnPlayerKilledByCreature / OnPlayerPVPKill. Those hooks run at the end of
    // Unit::Kill, BEFORE OnPlayerJustDied (which only runs on the player's next
    // update tick via KillPlayer), so FailChallenge reads it here instead of
    // relying on the hook order.
    struct PendingKiller
    {
        KillerKind kind = KillerKind::Unknown;
        uint32 entry = 0;
        std::string name;
    };

    // Hunger tracking (server-driven; the client only renders).
    // Observed on live (video): thirst +1/10s, hunger +1/16s, eating or
    // drinking DECREASES (not reset), death at 100. Displayed as stacks on
    // separate meter auras (drink glass + ham) that appear once >0.
    //
    // The authoritative values live in memory (like Player's field map) and
    // are flushed to the DB periodically and on logout, mirroring
    // Player::m_nextSave + SaveToDB. This avoids a SELECT/UPDATE per tick.
    struct HungerState { int32 hunger = 0; int32 thirst = 0; };

    struct HungerClock
    {
        uint32 thirstMs = 0;
        uint32 hungerMs = 0;
        uint32 foodMs = 0;
        uint32 drinkMs = 0;
        uint32 flushMs = 0;
        bool dirty = false;
        std::unordered_map<uint32, HungerState> state; // challengeId -> values
    };

    // Eat/drink restore ticks: 1 point per tick while the matching regen
    // aura is up. Observed live: drinking drops ~2x faster than eating.
    uint32 const HUNGER_FOOD_TICK_MS = 500;
    uint32 const HUNGER_DRINK_TICK_MS = 250;
    // Persist cadence for the in-memory counters.
    uint32 const HUNGER_FLUSH_MS = 5000;

    // Sentinel "challenge id" used to run the hunger/thirst system for the
    // Survivalist gamemode (Enum.GameMode.Survivalist, bit 0x4) without a real
    // challenge. Never stored in coa_character_challenge.
    uint32 const SURVIVALIST_HUNGER_ID = 0xFFFFFFFEu;
    uint32 const GAMEMODE_SURVIVALIST  = 0x00000004u;

    // --- Custom game modes -------------------------------------
    // Toggled by the client via CMSG 0x5A4 (mode name string + enable bool).
    // State is a bitmask (Enum.GameMode) pushed with SMSG 0x90B; the toggle
    // result is a "<MODE>_<RESULT>" string on SMSG 0x5A5.
    struct GameModeDef
    {
        char const* name;        // wire name the client sends
        char const* response;    // response prefix ("IRONMAN", "BUILDDRAFT", ...)
        char const* configKey;   // client C_Config key gating (locking) the UI entry
        char const* hiddenKey;   // client C_Config key hiding the row from the tab
        uint32      bit;         // Enum.GameMode bit
    };

    GameModeDef const GameModes[] =
    {
        { "Ironman",     "IRONMAN",     "CONFIG_IRONMAN_ENABLE",      "CONFIG_IRONMAN_HIDDEN",      0x0002 },
        { "Survivalist", "SURVIVALIST", "CONFIG_SURVIALIST_ENABLE",   "CONFIG_SURVIALIST_HIDDEN",   0x0004 },
        { "Draft",       "DRAFT",       "CONFIG_DRAFT_ENABLE",        "CONFIG_DRAFT_HIDDEN",        0x0008 },
        { "Resolute",    "RESOLUTE",    "CONFIG_RESOLUTE_ENABLE",     "CONFIG_RESOLUTE_HIDDEN",     0x0020 },
        { "WildCard",    "WILDCARD",    "CONFIG_WILD_CARD_ENABLE",    "CONFIG_WILD_CARD_HIDDEN",    0x0040 },
        { "Felforged",   "FELFORGED",   "CONFIG_FELFORGED_ENABLED",   "CONFIG_FELFORGED_HIDDEN",    0x0080 },
        { "Nightmare",   "NIGHTMARE",   "CONFIG_NIGHTMARE_ENABLE",    "CONFIG_NIGHTMARE_HIDDEN",    0x0100 },
        { "BuildDraft",  "BUILDDRAFT",  "CONFIG_BUILD_DRAFT_ENABLED", "CONFIG_BUILD_DRAFT_HIDDEN",  0x0800 },
        { "Crusader",    "CRUSADER",    "CONFIG_CRUSADER_ENABLED",    "CONFIG_CRUSADER_HIDDEN",     0x1000 },
    };

    // Hide a mode row from the Gamemodes tab (client CONFIG_*_HIDDEN). Reads the
    // comma-separated wire names in CoAChallenges.GameModes.Hidden. A hidden mode
    // still appears on the client while it is ACTIVE; this is presentation-only.
    bool GameModeHidden(char const* name);

    // Rows pending persistence for one player. Copied out under the lock so
    // the DB commit itself runs without holding HungerMutex.
    struct HungerFlushRow { uint32 challengeID; int32 hunger; int32 thirst; };

    // --- FATIGUED_UNLESS_RESTED (Narcolepsy: 170/171/172/384/385/386) --------
    // Native "fatigue" bar (MirrorTimer type FATIGUE = MirrorTimer1, the yellow
    // exhaustion bar) that FILLS from 0 to max while the player is OUTSIDE a
    // rested area (inn); at max the player falls asleep (dies). Driven entirely
    // server-side (not an aura meter). Only challenges whose Rules list carries
    // CHALLENGE_RULES_TYPE_FATIGUED_UNLESS_RESTED are tracked.
    struct FatigueState { uint32 challengeId = 0; int32 fatigue = 0; uint32 ms = 0; bool resting = true; uint32 graceMs = 0; };

    struct ConditionState { std::string label; bool broken = false; std::string detail; std::string message; };

    // Group challenge sync (SMSG 0x59B / CMSG 0x59C). The client's 0x59B
    // handler stores the {challengeID, level} pairs as "pending" and fires
    // CHALLENGE_SYNC_REQUEST(timeoutMs); UIParent shows CHALLENGES_SYNC when
    // the pending list is non-empty, else CHALLENGES_SYNC_REMOVE. The answer
    // (SendChallengeSyncResponse) is a single accept/decline byte with no ids,
    // so the server remembers what each outstanding request means per player.
    struct PendingSync
    {
        uint32 requesterGuid = 0;                        // activator that asked for the sync
        bool remove = false;                             // true = remove popup
        bool rollbackOnDecline = false;                  // party-required -> decline reverts
        std::vector<std::pair<uint32, uint32>> pairs;    // offered set (wire / applied on accept)
        std::vector<std::pair<uint32, uint32>> rollback; // set to revert on the requester on decline
    };

    // One entry of a challenge's reward list (per level). Empty itemId means
    // the entry is achievement-only (the client export encodes those as
    // "item=0x0|ach=<id>"). isFirst = the reward is only granted on the
    // character's first completion of that level (IsFirstCompletion); entries
    // with isFirst=false are repeatable (the client marks the "special" ones,
    // IsSpecialReward). Delivery is by mail (CoAChallenges.GrantRewards).
    struct RewardDef
    {
        uint32 itemId = 0;
        uint32 amount = 1;
        uint32 achievement = 0;
        bool isSpecial = false;
        bool isFirst = true;
    };

    // Per-challenge definition, DB-first (coa_challenge_definition +
    // coa_challenge_spell + coa_challenge_reward). Loaded into DefCache at
    // startup / `.coa challenges reload`; the world DB is the single source of
    // truth (no generated-.conf fallback).
    struct ChallengeDef
    {
        uint32 id = 0;
        std::string name;
        std::string icon;
        uint32 levelCount = 1;
        bool isTrial = false;
        bool isPrestige = false;
        uint32 exclusiveGroup = 0;
        uint32 requiredGameMode = 0;
        uint32 requiredGameEvent = 0;
        bool noRewards = false;
        bool noResurrect = false;
        uint32 lives = 0;
        bool sharedFate = false;
        bool survivalist = false;
        std::string rules;
        std::string conditions;
        std::string objectives;
        std::map<uint32, std::string> spells; // level -> "a;b" PvE auras (0 = union)
        std::map<uint32, std::vector<RewardDef>> rewards; // level -> reward list
    };

    extern std::mutex DefMutex; // defined in CoA.Challenges.Definitions.cpp
    extern std::unordered_map<uint32, ChallengeDef> DefCache;

    bool DefHas(uint32 challengeID);
    uint32 DefCount();
    std::vector<uint32> DefIds();
    void LoadChallengeDefinitions();

    // DB-only field read: the world DB is the single source of truth for
    // definitions (there is no generated-conf fallback). Misses return the
    // caller's default.
    template <typename T>
    T DefField(uint32 challengeID, T ChallengeDef::*member, std::string const& /*confKey*/, T def)
    {
        std::lock_guard<std::mutex> lock(DefMutex);
        auto it = DefCache.find(challengeID);
        if (it != DefCache.end())
            return it->second.*member;
        return def;
    }

    inline std::string ChallengeRules(uint32 challengeID)
    {
        return DefField<std::string>(challengeID, &ChallengeDef::rules,
            "CoAChallenges.Rules." + std::to_string(challengeID), "");
    }

    inline std::string ChallengeConditions(uint32 challengeID)
    {
        return DefField<std::string>(challengeID, &ChallengeDef::conditions,
            "CoAChallenges.Conditions." + std::to_string(challengeID), "");
    }

// Namespace-scope state (defined once in the domain file noted).
extern std::mutex PendingFailMutex; // defined in CoA.Challenges.Core.cpp
extern std::unordered_map<uint32, PendingFail> PendingFailBroadcast; // defined in CoA.Challenges.Core.cpp
    extern std::mutex LastKillerMutex; // defined in CoA.Challenges.Core.cpp
    extern std::unordered_map<uint32, PendingKiller> LastKiller; // defined in CoA.Challenges.Core.cpp
    extern std::atomic<bool> g_testQuiet; // defined in CoA.Challenges.Core.cpp
extern std::mutex HungerMutex; // defined in CoA.Challenges.Hunger.cpp
extern std::unordered_map<uint32, HungerClock> HungerAccum; // defined in CoA.Challenges.Hunger.cpp
extern std::unordered_set<uint32> HungerGuids; // defined in CoA.Challenges.Hunger.cpp
extern std::unordered_map<uint32, uint32> GameModeBase; // guarded by GameModeBaseMutex; iterate via GameModeBaseSnapshot()
extern std::mutex CharChallengeMutex; // defined in CoA.Challenges.Lifecycle.cpp
// guid -> the character's active challenges, as (challengeId, level)
extern std::unordered_map<uint32, std::vector<std::pair<uint32, uint32>>> CharChallengeCache;
extern std::mutex GameModeMaskMutex; // defined in CoA.Challenges.GameModes.cpp
extern std::unordered_map<uint32, uint32> GameModeMaskCache; // defined in CoA.Challenges.GameModes.cpp
extern std::mutex FatigueMutex; // defined in CoA.Challenges.Fatigue.cpp
extern std::unordered_map<uint32, FatigueState> FatigueStates; // defined in CoA.Challenges.Fatigue.cpp
extern std::mutex ObjectiveCacheMutex; // defined in CoA.Challenges.Lifecycle.cpp
extern std::unordered_map<uint32, std::vector<Objective>> ObjectiveCache; // defined in CoA.Challenges.Lifecycle.cpp
extern std::mutex CraftRarityMutex; // defined in CoA.Challenges.Professions.cpp
extern std::unordered_map<uint32, uint32> CraftRarity; // defined in CoA.Challenges.Professions.cpp
extern std::mutex PendingSyncMutex; // defined in CoA.Challenges.Core.cpp
extern std::unordered_map<uint32, PendingSync> PendingSyncByGuid; // CoA.Challenges.Core.cpp
extern std::atomic<bool> g_suppressSyncBroadcast; // defined in CoA.Challenges.Core.cpp

// Player-facing system message. The GM test harness sets g_testQuiet so a test
// run only prints its PASS/FAIL lines (production always shows the message).
template <typename... Args>
void NotifyPlayer(Player* player, char const* fmt, Args&&... args)
{
    if (g_testQuiet || !player || !player->GetSession())
        return;
    ChatHandler(player->GetSession()).PSendSysMessage(fmt, std::forward<Args>(args)...);
}

// Forward declarations (generated by split.ps1; definitions live in CoA.Challenges.*.cpp).
std::string ChallengeName(uint32 challengeID);
std::string ChallengeIcon(uint32 challengeID);
uint32 ChallengeLevelCount(uint32 challengeID);
std::string ChallengeBracket(uint32 challengeID, uint32 level);
std::string ChallengeIconTag(uint32 challengeID);
std::string ChatTimestamp();
char const* ClassToken(uint8 cls);
char const* ClassColorForToken(std::string const& token);
std::string PlayerNameLink(Player* player);
void AnnounceCompletion(Player* player, uint32 challengeID, uint32 level);
void SetDeathCause(Player* player, KillerKind kind, uint32 entry, std::string const& name);
void AnnounceFailure(Player* player, PendingFail const& fail);
void FlushFailureBroadcasts();
void AppendConfigString(WorldPacket& data, std::string const& key);
std::string HexDump(WorldPacket const& packet);
void EnsureTables();
void AppendClientConfig(AscensionClientConfig& config);
GameModeDef const* FindGameMode(std::string const& name);
char const* GameModeNameForBit(uint32 bit);
bool GameModesEnabled();
uint32 RealmGameModeMask();
void BuildGameModeBaseMap();
uint32 GameModeBaseForBit(uint32 bit);
std::unordered_map<uint32, uint32> GameModeBaseSnapshot();
uint32 PlayerToggleMaskFor(uint32 guid);
void ClearPlayerToggleBit(uint32 guid, uint32 bit);
uint32 LoadGameModeMask(uint32 guid);
bool CacheGenerationGuardEnabled();
std::vector<std::pair<uint32, uint32>> CachedCharChallenges(uint32 guid);
void ClearCharChallengeCache(uint32 guid);
struct ActiveChallengeRow
{
    uint32 challengeId = 0;
    uint32 level = 0;
    int32 hunger = 0;
    int32 thirst = 0;
};
std::vector<ActiveChallengeRow> LoadActiveChallengeRows(uint32 guid);
uint64 CharChallengeCacheGeneration();
void SeedCharChallengeCache(uint32 guid, uint64 generation, std::vector<ActiveChallengeRow> const& rows);
void PreloadLoginChallengeRows(uint32 guid);
std::vector<ActiveChallengeRow> TakeLoginChallengeRows(uint32 guid);
void ForgetLoginChallengeRows(uint32 guid);
uint32 CachedGameModeMask(uint32 guid);
void ClearGameModeMaskCache(uint32 guid);
void ApplyGameModeSpells(Player* player, uint32 oldMask, uint32 newMask);
void SaveGameModeMask(uint32 guid, uint32 mask);
void SendGameModeState(Player* player, uint32 mask);
void SendGameModeToggleResult(Player* player, std::string const& response);
void HandleToggleGameMode(Player* player, WorldPacket const& packet);
void ApplyGameModeToggle(Player* player, GameModeDef const* mode, bool enable);
uint32 LoadModeDeaths(uint32 guid, uint32 bit);
void SaveModeDeaths(uint32 guid, uint32 bit, uint32 deaths);
void ClearModeDeaths(uint32 guid, uint32 bit);
void TrackModeLives(Player* player, uint32 bit);
void UntrackModeLives(Player* player, uint32 bit);
void ReapplyGameModeBehavior(Player* player);
char const* ChallengeResponseString(uint32 code);
    std::vector<uint32> GetChallengeSpells(uint32 challengeID, uint32 level = 0);
    void ReapplyActiveSpells(Player* player);
    void ReapplyActiveSpells(Player* player, std::vector<ActiveChallengeRow> const& rows);
    void StripOrphanChallengeAuras(Player* player);
    std::vector<RewardDef> GetChallengeRewards(uint32 challengeID, uint32 level);
    void GrantChallengeRewards(Player* player, uint32 challengeID, uint32 level, bool firstItemReward,
        bool firstAchievement);
uint32 HungerFoodSpell();
uint32 HungerDrinkSpell();
void SetMeterAura(Player* player, uint32 spell, int32 value);
uint32 LivesTotal(uint32 challengeID);
bool IsHungerChallenge(uint32 challengeID);
void TakeHungerFlushLocked(uint32 guid, std::vector<HungerFlushRow>& out);
void CommitHungerFlush(uint32 guid, std::vector<HungerFlushRow> const& rows);
void TrackSurvivalist(Player* player);
void UntrackHunger(Player* player);
void WarnHunger(Player* player, char const* kind, int32 value);
void HungerUpdate(Player* player, uint32 diff);
void RefreshHungerTracking(Player* player);
void RefreshHungerTracking(Player* player, std::vector<ActiveChallengeRow> const& rows);
void RemoveHungerChallenge(Player* player, uint32 challengeID);
void SyncMeterAuras(Player* player);
bool IsFatigueChallenge(uint32 challengeID);
uint32 FatigueMax();
uint32 FatigueFillSeconds();
void PersistFatigue(uint32 guid, uint32 challengeId, int32 fatigue);
void StopFatigueBar(Player* player);
void SendFatigueBar(Player* player, int32 fatigue);
void TrackFatigue(Player* player, uint32 challengeID);
void ClearFatigue(Player* player);
void RefreshFatigueTracking(Player* player);
void RefreshFatigueTracking(Player* player, std::vector<ActiveChallengeRow> const& rows);
void TrackSpellbind(Player* player, uint32 challengeID);
void UntrackSpellbind(Player* player);
void RefreshSpellbindTracking(Player* player);
void TrackInvertedBreath(Player* player, uint32 challengeID);
void UntrackInvertedBreath(Player* player);
void RefreshInvertedBreathTracking(Player* player);
    void RefreshRegenTracking(Player* player);
    void UntrackRegen(Player* player);
    void FatigueUpdate(Player* player, uint32 diff);
    // HIGH_RISK_ONLY: aura that marks a character as participating in the
    // High Risk ruleset (applied by CoA). Conf-tunable.
    uint32 HighRiskAura();
    bool HighRiskActivationBlocked(Player* player);
    void RefreshHighRiskTracking(Player* player);
    void UntrackHighRisk(Player* player);
    bool HighRiskTracked(uint32 guid);
    // NO_CREATURE_LEVEL_SCALING / NO_QUEST_LEVEL_SCALING: the parts of level
    // scaling the active challenges switch off, as LocalLevelScaling's
    // ChallengeBlocks* mask (refreshed on login/activate/deactivate/complete/fail).
    void RefreshLevelScalingTracking(Player* player);
    void UntrackLevelScaling(Player* player);
    uint8 LevelScalingBlocks(Player const* player);
    // NO_NON_LOOTED_ITEMS ("Scavenger"): item-instance looted tracking.
    void RefreshLootedTracking(Player* player);
    void UntrackLootedItems(uint32 guid);
    bool ItemWasLooted(uint32 guid, uint32 itemGuid);
    // NO_HEALING_UNLESS_BANDAGING: the First Aid heal spells are the only
    // healing allowed by the rule.
    bool IsBandageSpell(SpellInfo const* spellInfo);
    // NO_GROUP_FOR_DUNGEONS: true when either player is inside a dungeon.
    bool GroupForDungeonsBlocked(Player* player, Player* other);
void SendActiveList(Player* player);
void SendActiveList(Player* player, std::vector<ActiveChallengeRow> const& rows);
void PushLoginState(Player* player);
void AppendFailureString(WorldPacket& data, std::string const& s);
void AppendFailureRecord(WorldPacket& data, std::string const& who, uint32 challengeID, uint32 level);
void SendFailureAdded(Player* player, uint32 challengeID, uint32 level);
void SendFailureList(Player* player);
void AppendCompletionEntry(WorldPacket& data, uint32 challengeID, uint32 level, std::string const& name, std::string const& race, std::string const& gender, std::string const& klass, uint32 startTime, uint32 completeTime);
void SendCompletionList(Player* player, uint32 challengeID, uint32 level);
void SendCompletionAdded(Player* player, uint32 challengeID, uint32 level);
void SendCompletedList(Player* player);
void AppendCriteriaEntry(WorldPacket& data, uint32 a, uint32 b, uint32 c, uint32 typeIdx,
    uint32 e, uint32 f, uint32 g, uint32 h, uint8 done);
std::array<uint32, 9> BuildCriteriaEntry(uint32 challengeID, uint32 level, uint32 typeIdx,
    Objective const& o, bool done);
uint32 RequirementIdFor(Player* player, uint32 challengeID, std::string const& key);
void SendRequirementDef(Player* player, uint32 id, std::string const& type,
    uint32 v1, uint32 v2, uint32 v3);
void SendCriteriaList(Player* player, std::vector<std::array<uint32, 9>> const& entries);
void SendCriteriaUpdated(Player* player, std::array<uint32, 9> const& e);
void SendCriteriaState(Player* player);
void SendCriteriaUpdatedForObjective(Player* player, uint32 challengeID, uint32 level,
    Objective const& o, bool done);
uint32 ActiveChallengeLevel(uint32 guid, uint32 challengeID);
bool ReadWireString(WorldPacket const& packet, uint32& off, std::string& out);
void SendTrialResult(Player* player, uint16 opcode, std::string const& trialID, std::string const& response);
std::string GenerateTrialId(uint32 guid);
void SendTrialList(Player* player);
void SendTrialData(Player* player);
void SendActiveTrial(Player* player, std::string const& trialID);
std::string GetActiveCustomTrial(uint32 guid);
void SetActiveCustomTrial(Player* player, std::string const& trialID);
uint32 TrialOwnerGuid(std::string const& trialID);
void EndActiveCustomTrialFor(Player* player, uint32 challengeID);
void AppendTrialCompletionEntry(WorldPacket& data, std::string const& trialID,
    std::string const& name, std::string const& race, std::string const& gender,
    std::string const& klass, uint32 startTime, uint32 completeTime);
void SendTrialCompletions(Player* player, std::string const& trialID);
void SendTrialCompletionAdded(Player* player, std::string const& trialID);
bool TryCompleteCustomTrial(Player* player, uint32 challengeID);
bool ActiveTrialDisplayFor(Player* player, uint32 challengeID, std::string& name, std::string& icon);
void HandleSaveTrial(Player* player, WorldPacket const& packet);
void HandleDeleteTrial(Player* player, WorldPacket const& packet);
void HandleActivateTrial(Player* player, WorldPacket const& packet);
void HandleDeactivateTrial(Player* player, WorldPacket const& packet);
void HandleRateTrial(Player* player, WorldPacket const& packet);
void SendSyncRequest(Player* player, uint32 timeoutMs, bool remove,
    std::vector<std::pair<uint32, uint32>> const& pairs, uint32 requesterGuid,
    bool rollbackOnDecline, std::vector<std::pair<uint32, uint32>> const& rollback);
void HandleSyncResponse(Player* player, WorldPacket const& packet);
void BroadcastChallengeSync(Player* player, uint32 challengeID, uint32 level, bool remove);
void SendChallengeSyncToGroup(Player* actor, uint32 timeoutMs, bool remove,
    std::vector<std::pair<uint32, uint32>> const& pairs, bool rollbackOnDecline,
    std::vector<std::pair<uint32, uint32>> const& rollback);
bool ChallengeRequiresParty(uint32 challengeID);
bool HasFailure(uint32 guid, uint32 challengeID);
bool HasAnyFailure(uint32 guid);
bool ActivationPermanentlyBlocked(uint32 guid);
bool HasCompletion(uint32 guid, uint32 challengeID);
bool HasCompletionLevel(uint32 guid, uint32 challengeID, uint32 level);
void SendDeathUpdate(Player* player, uint32 challengeID, uint32 level, uint32 deaths);
bool IsSharedFate(uint32 challengeID);
uint32 ExclusiveGroup(uint32 challengeID);
bool IsTrialChallenge(uint32 challengeID);
bool IsPrestigeChallenge(uint32 challengeID);
// Prestige state and its aura live in mod-coa-prestige (single owner).
// "Prestiged" is the client's C_Player:IsPrestiged() = HasAura(PRESTIGE_AURA).
// The experience bonus is applied here, from CoAPrestige::ExperienceBonusPercent.
constexpr uint32 COA_PRESTIGE_AURA = CoAPrestige::PRESTIGE_AURA;
bool IsPrestiged(Player* player);
uint32 RequiredGameMode(uint32 challengeID);
void RecomputeRequiredGameModes(Player* player);
void RecomputeRequiredGameModes(Player* player, std::vector<ActiveChallengeRow> const& rows);
uint32 RequiredGameEvent(uint32 challengeID);
bool NoRewards(uint32 challengeID);
bool ChallengeExists(uint32 challengeID);
uint32 ConflictingExclusiveChallenge(uint32 guid, uint32 challengeID, uint32& conflictId);
bool IsPermaDeath(uint32 challengeID);
bool HasPermaDeathFailure(Player* player);
uint32 ValidateChallenge(Player* player, uint32 challengeID, uint32 level);
void DoActivateChallenge(Player* player, uint32 challengeID, uint32 level);
uint32 ActivateChallenge(Player* player, uint32 challengeID, uint32 level);
void DeactivateChallenge(Player* player, uint32 challengeID);
bool RuleListContains(std::string const& list, std::string const& rule);
bool PlayerHasRule(Player* player, char const* rule);
void LoadChallengesEnabled();
bool ChallengesEnabled();
bool OutsideInteractionGateEnabled();
uint32 ActiveChallengeWithRule(Player* player, char const* rule, uint32& level);
std::set<uint32> ActiveChallenges(uint32 guid);
bool HasActiveTrial(uint32 guid);
void SetConditionFlag(uint32 guid, char const* flag);
bool HasConditionFlag(uint32 guid, char const* flag);
void ClearConditionFlag(uint32 guid, std::string const& flag);
void ResetConditionFlags(uint32 guid);
void ForgetConditionFlags(uint32 guid);
uint32 FreeInventorySlots(Player* player);
std::vector<ConditionState> EvaluateConditions(Player* player, uint32 challengeID);
std::vector<ConditionState> EvaluateConditionsFor(Player* player, uint32 challengeID,
    std::string const& conds, bool injectOutside);
std::string CheckActivationConditions(Player* player, uint32 challengeID);
bool IsPristine(Player* player, uint32 challengeID);
bool RequirementsMet(uint32 guid, uint32 challengeID);
void CompleteAtLevelCap(Player* player);
int QuestColor(uint32 questLevel, uint32 playerLevel);
uint32 NextGatedLevel(Player* player);
void MarkObjectives(Player* player, char const* type, uint32 eventValue);
std::string ObjectiveFailLabel(std::string const& type);
bool CheckObjectiveLevels(Player* player);
// killerSource is the guid whose death carries the killer info. causeKind (with
// causeEntry/causeName) lets a rule failure name its own cause (e.g. the beast a
// FAILABLE_NO_KILL_BEASTS trial forbids) instead of "killed by Unknown".
void FailChallenge(Player* player, uint32 challengeID, uint32 level, uint32 deaths,
    ObjectGuid const& killerSource = ObjectGuid::Empty,
    KillerKind causeKind = KillerKind::Unknown, uint32 causeEntry = 0, std::string causeName = "");
void FailSharedFate(Player* dead, uint32 challengeID);
void FailSharedFateHolders(Group* group, ObjectGuid extraGuid);
void HandlePlayerDeath(Player* player);
uint32 CraftedItemRarity(SkillLineAbilityEntry const* ability);
void GrantProfessionXP(Player* member, uint32 rarityMult);
Player* GetPlayerOwner(Creature* creature);
void ApplyActiveChallengeSpellsToCreature(Player* player, Creature* creature);
} // namespace CoAChallenges

#endif // COA_CHALLENGES_REVIEW_H
