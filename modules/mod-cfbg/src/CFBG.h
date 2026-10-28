/*
 * Copyright (С) since 2019 Andrei Guluaev (Winfidonarleyan/Kargatum) https://github.com/Winfidonarleyan
 * Copyright (С) since 2019+ AzerothCore <www.azerothcore.org>
 * Licence MIT https://opensource.org/MIT
 */

#ifndef _CFBG_H_
#define _CFBG_H_

#include "SharedDefines.h"
#include "DBCEnums.h"
#include "ObjectGuid.h"
#include <array>
#include <optional>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class Player;
class Battlefield;
class Battleground;
class BattlegroundQueue;
class Group;

struct GroupQueueInfo;
struct PvPDifficultyEntry;

enum FakeMorphs
{
    FAKE_M_FEL_ORC        = 21267,
    FAKE_F_ORC            = 20316,
    FAKE_M_DWARF          = 20317,
    FAKE_M_NIGHT_ELF      = 20318,
    FAKE_F_DRAENEI        = 20323,
    FAKE_M_BROKEN_DRAENEI = 21105,
    FAKE_M_TROLL          = 20321,
    FAKE_M_HUMAN          = 19723,
    FAKE_F_HUMAN          = 19724,
    FAKE_M_BLOOD_ELF      = 20578,
    FAKE_F_BLOOD_ELF      = 20579,
    FAKE_F_GNOME          = 20320,
    FAKE_M_GNOME          = 20580,
    FAKE_F_TAUREN         = 20584,
    FAKE_M_TAUREN         = 20585
};

constexpr auto FACTION_FROSTWOLF_CLAN = 729;
constexpr auto FACTION_STORMPIKE_GUARD = 730;

// Cfbg settings
constexpr auto SETTING_CFBG_RACE = 0;

struct FakePlayer
{
    // Fake
    uint8   FakeRace;
    uint32  FakeMorph;
    TeamId  FakeTeamID;

    // Real
    uint8   RealRace;
    uint32  RealMorph;
    uint32  RealNativeMorph;
    TeamId  RealTeamID;
};

struct RaceData
{
    uint8 charClass;
    std::vector<uint8> availableRacesA;
    std::vector<uint8> availableRacesH;
};

struct CFBGRaceInfo
{
    uint8 RaceId;
    std::string RaceName;
    uint8 TeamId;
};

struct CrossFactionGroupInfo
{
    explicit CrossFactionGroupInfo(GroupQueueInfo* groupInfo);

    uint32 AveragePlayersLevel{ 0 };
    uint32 AveragePlayersItemLevel{ 0 };
    bool IsHunterJoining{ false };
    uint32 SumAverageItemLevel{ 0 };
    uint32 SumPlayerLevel{ 0 };

    CrossFactionGroupInfo() = delete;
    CrossFactionGroupInfo(CrossFactionGroupInfo&&) = delete;
};

// Precomputed numeric aggregates fed to CFBG::ResolveBalancedTeam, the single
// shared team-decision cascade. Each caller (formation / reinforcement) builds
// one from its own data source (queue tallies or live BG counts).
struct TeamBalanceContext
{
    int32  countA{ 0 };               // head counts, candidate EXCLUDED
    int32  countH{ 0 };
    uint32 levelSumA{ 0 };            // level sums, candidate EXCLUDED (like the counts)
    uint32 levelSumH{ 0 };
    uint32 avgIlvlA{ 0 };            // per-team ilvl metric (bg avg OR queue sum)
    uint32 avgIlvlH{ 0 };
    uint32 evenCountA{ 0 };          // denominators for the EvenTeams avg-level step
    uint32 evenCountH{ 0 };
    std::optional<TeamId> hunterOverride{ std::nullopt }; // set only when the bg-gated hunter step fires
    TeamId fallback{ TEAM_NEUTRAL }; // provisional / candidate team
};

class CFBG
{
public:
    using RandomSkinInfo = std::pair<uint8/*race*/, uint32/*morph*/>;
    using GroupsList = std::vector<GroupQueueInfo*>;

    static CFBG* instance();

    void LoadConfig();

    inline bool IsEnableSystem() const { return _IsEnableSystem; }
    inline bool IsEnableWGSystem() const { return _IsEnableWGSystem; }
    inline bool IsEnableWGTeamLock() const { return _IsEnableWGTeamLock; }
    inline bool IsEnableWGNativePriority() const { return _IsEnableWGNativePriority; }
    inline bool IsEnableWGReapplyOnResurrect() const { return _IsEnableWGReapplyOnResurrect; }
    inline bool IsWGSkipClass(uint8 playerClass) const { return _wgSkipClasses.count(playerClass) > 0; }
    inline bool IsEnableAvgIlvl() const { return _IsEnableAvgIlvl; }
    inline bool IsEnableBalancedTeams() const { return _IsEnableBalancedTeams; }
    inline bool IsEnableBalanceClassLowLevel() const { return _IsEnableBalanceClassLowLevel; }
    inline bool IsEnableEvenTeams() const { return _IsEnableEvenTeams; }
    inline bool IsEnableResetCooldowns() const { return _IsEnableResetCooldowns; }
    inline bool IsEnableBalanceTeamsOnEntry() const { return _IsEnableBalanceTeamsOnEntry; }
    inline bool IsEnableBalanceTeamsAtStart() const { return _IsEnableBalanceTeamsAtStart; }
    inline uint32 EvenTeamsMaxPlayersThreshold() const { return _EvenTeamsMaxPlayersThreshold; }
    inline uint32 GetMaxPlayersCountInGroup() const { return _MaxPlayersCountInGroup; }
    inline uint8 GetBalanceClassMinLevel() const { return _balanceClassMinLevel; }
    inline uint8 GetBalanceClassMaxLevel() const { return _balanceClassMaxLevel; }
    inline uint8 GetBalanceClassLevelDiff() const { return _balanceClassLevelDiff; }
    inline bool RandomizeRaces() const { return _randomizeRaces; }
    inline bool KeepRace() const { return _keepRace; }
    // Race standing for a team where a kept-race player needs one: faction
    // template and the race the client sees in name query responses.
    static inline uint8 GetTeamRace(TeamId teamId) { return teamId == TEAM_ALLIANCE ? RACE_HUMAN : RACE_ORC; }

    uint32 GetBGTeamAverageItemLevel(Battleground* bg, TeamId team);
    uint32 GetBGTeamSumPlayerLevel(Battleground* bg, TeamId team);

    TeamId ResolveBalancedTeam(TeamBalanceContext const& ctx);

    bool IsPlayerFake(Player* player);
    FakePlayer const* GetFakePlayer(Player* player) const;

    // Per-war WG team lock, GUID-keyed so it survives leaving the war/zone and
    // relog. Cleared when the war ends.
    std::optional<TeamId> GetWGWarAssignment(ObjectGuid guid) const;
    void SetWGWarAssignment(ObjectGuid guid, TeamId team);
    void ClearWGWarAssignments();

    // Native-priority WG balancing: keep the minority native, flip only the
    // majority's surplus (latest accepters). The fair share is a ceiling; past
    // it a majority joiner flips only when the flip does not worsen the live
    // war counts. Census captured on the first call of a war, reset in
    // ClearWGWarAssignments.
    TeamId ResolveWGWarTeam(Player* player, uint32 nativeAllianceInvited, uint32 nativeHordeInvited, uint32 allianceInWar, uint32 hordeInWar);

    bool IsPlayingNative(Player* player);

    void ValidatePlayerForBG(Battleground* bg, Player* player);
    // Forces race/faction/m_team/fake-store into agreement with the player's
    // assigned BG team (GetBgTeamId()); idempotent and self-correcting.
    void EnforceBGTeamConsistency(Player* player);

    // Doors-open head-count repair: when declined/no-show invites left the teams
    // grossly uneven (diff >= 2) once the gates open, flip surplus solo entrants
    // to the smaller side so the match starts within 1 of even. Real BG premades
    // are never split. Fired from OnBattlegroundStart.
    void BalanceTeamsAtStart(Battleground* bg);
    void SetFakeRaceAndMorph(Player* player);
    void SetFakeRaceAndMorphForBF(Player* player, TeamId assignedTeam);
    void SetFactionForRace(Player* player, uint8 Race, TeamId teamId);
    void ClearFakePlayer(Player* player);
    void DropFakePlayerRecord(Player* player);
    void ReapplyFakePlayer(Player* player);
    void FitPlayerInTeam(Player* player, Battleground* bg);
    void DoForgetPlayersInBG(Player* player, Battleground* bg);
    void SetForgetBGPlayers(Player* player, bool value);
    bool ShouldForgetBGPlayers(Player* player);
    // Const, non-inserting flag probe for the per-tick update hook
    // (ShouldForgetBGPlayers' operator[] would default-insert an entry for
    // every online player every tick).
    bool HasPendingForget(Player* player) const;
    void UpdateForget(Player* player);
    void SendMessageQueue(BattlegroundQueue* bgQueue, Battleground* bg, PvPDifficultyEntry const* bracketEntry, Player* leader);

    bool FillPlayersToCFBG(BattlegroundQueue* bgqueue, Battleground* bg, BattlegroundBracketId bracket_id);
    bool CheckCrossFactionMatch(BattlegroundQueue* bgqueue, BattlegroundBracketId bracket_id, uint32 minPlayers, uint32 maxPlayers);

    bool IsRaceValidForFaction(uint8 teamId, uint8 race);
    TeamId getTeamWithLowerClass(Battleground* bg, Classes c);
    uint8 getBalanceClassMinLevel(Battleground const* bg) const;

    inline auto GetRaceData() { return &_raceData; }
    RaceData const& GetRaceDataForClass(uint8 playerClass) const;
    inline auto GetRaceInfo() { return &_raceInfo; }

private:
    bool isClassJoining(uint8 _class, Player* player, uint32 minLevel);

    // Live, bg-gated hunter-class override for the reinforcement path. Returns a
    // team only when EvenTeams + class-low-level balancing apply to the candidate.
    std::optional<TeamId> ResolveHunterOverride(Battleground* bg, CrossFactionGroupInfo const& cfGroupInfo);

    // Arrival-time head-count correction for solo entrants.
    void BalanceTeamsOnEntry(Battleground* bg, Player* player);

    // True when another member of `player`'s social party is already committed to
    // this bg instance (already entered, or holding an invite to it). Flipping the
    // player would then split a real premade that is materializing here, so the
    // head-count repairs leave them put. `group` is the social party: GetGroup()
    // before the BG raid is assigned (entry hook), GetOriginalGroup() once inside.
    bool IsPartyCommittedToBG(Player* player, Group* group, Battleground* bg);

    RandomSkinInfo GetRandomRaceMorph(TeamId team, uint8 playerClass, uint8 gender);

    uint32 GetMorphFromRace(uint8 race, uint8 gender);

    void ApplyFakePlayer(Player* player, FakePlayer const& fake);

    // Projected head counts per team: in-BG players plus invited-not-yet-entered
    // ones. bg == nullptr (formation) yields zeros.
    std::array<uint32, 2> GetProjectedBaseCounts(Battleground* bg, BattlegroundQueue* queue, BattlegroundBracketId bracketId) const;

    // Unified stage->repair->invite selection (formation + reinforcement): fills
    // m_SelectionPools keeping projected sizes within allowedDiff, premades atomic.
    void SelectBalancedGroups(BattlegroundQueue* queue, BattlegroundBracketId bracketId, Battleground* bg, uint32 maxPerTeam, uint32 allowedDiff);

    std::unordered_map<Player*, FakePlayer> _fakePlayerStore;
    std::unordered_map<ObjectGuid, TeamId> _wgWarAssignmentStore;

    // Per-war native census for ResolveWGWarTeam, reset in ClearWGWarAssignments.
    bool   _wgCensusValid        = false;
    TeamId _wgMajorityTeam       = TEAM_ALLIANCE;
    uint32 _wgMajorityFairShare  = 0;
    uint32 _wgMajorityNativeKept = 0;
    std::unordered_map<Player*, bool> _forgetBGPlayersStore;

    std::array<RaceData, 12> _raceData{};
    RaceData _anyClassRaceData{};
    std::array<CFBGRaceInfo, 9> _raceInfo{};

    // For config
    // = false so LoadConfig's disable-transition read is well-defined on the
    // very first load.
    bool _IsEnableSystem = false;
    bool _IsEnableWGSystem;
    bool _IsEnableWGTeamLock;
    bool _IsEnableWGNativePriority;
    bool _IsEnableWGReapplyOnResurrect;
    std::unordered_set<uint8> _wgSkipClasses;
    bool _IsEnableAvgIlvl;
    bool _IsEnableBalancedTeams;
    bool _IsEnableBalanceClassLowLevel;
    bool _IsEnableEvenTeams;
    bool _IsEnableResetCooldowns;
    bool _IsEnableBalanceTeamsOnEntry;
    bool _IsEnableBalanceTeamsAtStart;
    bool _showPlayerName;
    bool _randomizeRaces;
    bool _keepRace;
    uint32 _EvenTeamsMaxPlayersThreshold;
    uint32 _MaxPlayersCountInGroup;
    uint8 _balanceClassMinLevel;
    uint8 _balanceClassMaxLevel;
    uint8 _balanceClassLevelDiff;

    CFBG();
    ~CFBG() = default;

    CFBG(CFBG const&) = delete;
    CFBG(CFBG&&) = delete;
    CFBG& operator=(CFBG const&) = delete;
    CFBG& operator=(CFBG&&) = delete;
};

#define sCFBG CFBG::instance()

#endif // _KARGATUM_CFBG_H_
