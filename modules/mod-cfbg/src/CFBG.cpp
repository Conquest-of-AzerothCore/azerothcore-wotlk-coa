/*
 * Copyright (С) since 2019 Andrei Guluaev (Winfidonarleyan/Kargatum) https://github.com/Winfidonarleyan
 * Copyright (С) since 2019+ AzerothCore <www.azerothcore.org>
 * Licence MIT https://opensource.org/MIT
 */

#include "CFBG.h"
#include "BattlegroundMgr.h"
#include "BattlegroundQueue.h"
#include "BattlegroundUtils.h"
#include "Chat.h"
#include "Config.h"
#include "Containers.h"
#include "Group.h"
#include "Language.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "Tokenize.h"
#include "GameTime.h"
#include "Player.h"
#include "WorldSessionMgr.h"

constexpr uint32 MapAlteracValley = 30;

CrossFactionGroupInfo::CrossFactionGroupInfo(GroupQueueInfo* groupInfo)
{
    uint32 sumLevels = 0;
    uint32 sumAverageItemLevels = 0;
    uint32 playersCount = 0;

    for (auto const& playerGuid : groupInfo->Players)
    {
        auto player = ObjectAccessor::FindConnectedPlayer(playerGuid);
        if (!player)
            continue;

        if (player->getClass() == CLASS_HUNTER && !IsHunterJoining)
            IsHunterJoining = true;

        sumLevels += player->GetLevel();
        sumAverageItemLevels += player->GetAverageItemLevel();
        playersCount++;

        SumAverageItemLevel += player->GetAverageItemLevel();
        SumPlayerLevel += player->GetLevel();
    }

    if (!playersCount)
        return;

    AveragePlayersLevel = sumLevels / playersCount;
    AveragePlayersItemLevel = sumAverageItemLevels / playersCount;
}

CFBG::CFBG()
{
    _raceData =
    {
        RaceData{ CLASS_NONE,           { 0 }, { 0 } },
        RaceData{ CLASS_WARRIOR,        { RACE_HUMAN, RACE_DWARF, RACE_GNOME, RACE_DRAENEI  }, { RACE_ORC, RACE_TAUREN, RACE_TROLL } },
        RaceData{ CLASS_PALADIN,        { RACE_HUMAN, RACE_DWARF, RACE_DRAENEI }, { RACE_BLOODELF } },
        RaceData{ CLASS_HUNTER,         { RACE_DWARF, RACE_DRAENEI }, { RACE_ORC, RACE_TAUREN, RACE_TROLL, RACE_BLOODELF } },
        RaceData{ CLASS_ROGUE,          { RACE_HUMAN, RACE_DWARF, RACE_GNOME }, { RACE_ORC, RACE_TROLL, RACE_BLOODELF } },
        RaceData{ CLASS_PRIEST,         { RACE_HUMAN, RACE_DWARF, RACE_DRAENEI  }, { RACE_TROLL, RACE_BLOODELF } },
        RaceData{ CLASS_DEATH_KNIGHT,   { RACE_HUMAN, RACE_DWARF, RACE_GNOME, RACE_DRAENEI }, { RACE_ORC, RACE_TAUREN, RACE_TROLL, RACE_BLOODELF } },
        RaceData{ CLASS_SHAMAN,         { RACE_DRAENEI }, { RACE_ORC, RACE_TAUREN, RACE_TROLL  } },
        RaceData{ CLASS_MAGE,           { RACE_HUMAN, RACE_GNOME }, { RACE_BLOODELF, RACE_TROLL } },
        RaceData{ CLASS_WARLOCK,        { RACE_HUMAN, RACE_GNOME }, { RACE_ORC, RACE_BLOODELF } },
        RaceData{ CLASS_NONE,           { 0 }, { 0 } },
        RaceData{ CLASS_DRUID,          { RACE_HUMAN }, { RACE_TAUREN } }
    };

    _anyClassRaceData = RaceData{ CLASS_NONE,
        { RACE_HUMAN, RACE_DWARF, RACE_GNOME, RACE_DRAENEI },
        { RACE_ORC, RACE_TAUREN, RACE_TROLL, RACE_BLOODELF } };

    _raceInfo =
    {
        CFBGRaceInfo{ RACE_HUMAN,    "human",    TEAM_HORDE    },
        CFBGRaceInfo{ RACE_NIGHTELF, "nightelf", TEAM_HORDE    },
        CFBGRaceInfo{ RACE_DWARF,    "dwarf",    TEAM_HORDE    },
        CFBGRaceInfo{ RACE_GNOME,    "gnome",    TEAM_HORDE    },
        CFBGRaceInfo{ RACE_DRAENEI,  "draenei",  TEAM_HORDE    },
        CFBGRaceInfo{ RACE_ORC,      "orc",      TEAM_ALLIANCE },
        CFBGRaceInfo{ RACE_BLOODELF, "bloodelf", TEAM_ALLIANCE },
        CFBGRaceInfo{ RACE_TROLL,    "troll",    TEAM_ALLIANCE },
        CFBGRaceInfo{ RACE_TAUREN,   "tauren",   TEAM_ALLIANCE }
    };
}

CFBG* CFBG::instance()
{
    static CFBG instance;
    return &instance;
}

void CFBG::LoadConfig()
{
    bool const wasEnabled = _IsEnableSystem;
    _IsEnableSystem = sConfigMgr->GetOption<bool>("CFBG.Enable", true);
    if (!_IsEnableSystem)
    {
        // Live-disable via .reload: restore every online faked player and drop
        // all Player*-keyed state; otherwise they stay cross-faction until
        // relog and the stale keys can corrupt a later Player reusing the
        // same address.
        if (wasEnabled)
        {
            for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
                if (IsPlayerFake(player))
                    ClearFakePlayer(player);

            // Anything left is a leaked entry whose Player was already
            // deleted; drop it without dereferencing the key.
            _fakePlayerStore.clear();
            _forgetBGPlayersStore.clear();
        }

        return;
    }

    _IsEnableWGSystem = sConfigMgr->GetOption<bool>("CFBG.Battlefield.Enable", true);
    _IsEnableWGTeamLock = sConfigMgr->GetOption<bool>("CFBG.Battlefield.TeamLock.Enable", true);
    _IsEnableWGNativePriority = sConfigMgr->GetOption<bool>("CFBG.Battlefield.NativePriority.Enable", true);
    _IsEnableWGReapplyOnResurrect = sConfigMgr->GetOption<bool>("CFBG.Battlefield.ReapplyOnResurrect.Enable", true);

    _wgSkipClasses.clear();
    std::string const skipClasses = sConfigMgr->GetOption<std::string>("CFBG.Battlefield.SkipClasses", "");
    for (auto const& token : Acore::Tokenize(skipClasses, ',', false))
    {
        if (Optional<uint8> playerClass = Acore::StringTo<uint8>(token))
            _wgSkipClasses.insert(*playerClass);
    }

    _IsEnableAvgIlvl = sConfigMgr->GetOption<bool>("CFBG.Include.Avg.Ilvl.Enable", false);
    _IsEnableBalancedTeams = sConfigMgr->GetOption<bool>("CFBG.BalancedTeams", true);
    _IsEnableEvenTeams = sConfigMgr->GetOption<bool>("CFBG.EvenTeams.Enabled", false);
    _IsEnableBalanceClassLowLevel = sConfigMgr->GetOption<bool>("CFBG.BalancedTeams.Class.LowLevel", false);
    _IsEnableResetCooldowns = sConfigMgr->GetOption<bool>("CFBG.ResetCooldowns", false);
    _IsEnableBalanceTeamsOnEntry = sConfigMgr->GetOption<bool>("CFBG.BalanceTeamsOnEntry.Enabled", true);
    _IsEnableBalanceTeamsAtStart = sConfigMgr->GetOption<bool>("CFBG.BalanceTeamsAtStart.Enabled", true);
    _showPlayerName = sConfigMgr->GetOption<bool>("CFBG.Show.PlayerName", false);
    _EvenTeamsMaxPlayersThreshold = sConfigMgr->GetOption<uint32>("CFBG.EvenTeams.MaxPlayersThreshold", 0);
    _MaxPlayersCountInGroup = sConfigMgr->GetOption<uint32>("CFBG.Players.Count.In.Group", 3);
    _balanceClassMinLevel = sConfigMgr->GetOption<uint8>("CFBG.BalancedTeams.Class.MinLevel", 10);
    _balanceClassMaxLevel = sConfigMgr->GetOption<uint8>("CFBG.BalancedTeams.Class.MaxLevel", 19);
    _balanceClassLevelDiff = sConfigMgr->GetOption<uint8>("CFBG.BalancedTeams.Class.LevelDiff", 2);
    _randomizeRaces = sConfigMgr->GetOption<bool>("CFBG.RandomRaceSelection", true);
    _keepRace = sConfigMgr->GetOption<bool>("CFBG.KeepRace", true);
}

uint32 CFBG::GetBGTeamAverageItemLevel(Battleground* bg, TeamId team)
{
    if (!bg)
    {
        return 0;
    }

    uint32 sum = 0;
    uint32 count = 0;

    for (auto const& [playerGuid, player] : bg->GetPlayers())
    {
        if (player && player->GetTeamId() == team)
        {
            sum += player->GetAverageItemLevel();
            count++;
        }
    }

    if (!count || !sum)
    {
        return 0;
    }

    return sum / count;
}

uint32 CFBG::GetBGTeamSumPlayerLevel(Battleground* bg, TeamId team)
{
    if (!bg)
    {
        return 0;
    }

    uint32 sum = 0;

    for (auto const& [playerGuid, player] : bg->GetPlayers())
    {
        if (player && player->GetTeamId() == team)
        {
            sum += player->GetLevel();
        }
    }

    return sum;
}

std::optional<TeamId> CFBG::ResolveHunterOverride(Battleground* bg, CrossFactionGroupInfo const& cfGroupInfo)
{
    if (!IsEnableEvenTeams())
        return std::nullopt;

    uint32 playerLevel = cfGroupInfo.AveragePlayersLevel;

    // if CFBG.BalancedTeams.Class.LowLevel is enabled, balance the quantity of
    // hunters per team when a hunter is joining within the configured level band.
    if (IsEnableBalanceClassLowLevel() &&
        (playerLevel >= _balanceClassMinLevel && playerLevel <= _balanceClassMaxLevel) &&
        (playerLevel >= getBalanceClassMinLevel(bg)) &&
        cfGroupInfo.IsHunterJoining)
    {
        return getTeamWithLowerClass(bg, CLASS_HUNTER);
    }

    return std::nullopt;
}

TeamId CFBG::ResolveBalancedTeam(TeamBalanceContext const& ctx)
{
    // 1. Head-count: the smaller side always wins.
    if (ctx.countA != ctx.countH)
        return ctx.countA < ctx.countH ? TEAM_ALLIANCE : TEAM_HORDE;

    // 2. Level sum (only if CFBG.BalancedTeams).
    if (IsEnableBalancedTeams())
    {
        TeamId team = ctx.fallback;

        // First select team - where the sum of the levels is less
        if (ctx.levelSumA != ctx.levelSumH)
            team = ctx.levelSumA < ctx.levelSumH ? TEAM_ALLIANCE : TEAM_HORDE;

        // EvenTeams refinement (only if CFBG.EvenTeams.Enabled).
        if (IsEnableEvenTeams())
        {
            if (ctx.hunterOverride)
            {
                team = *ctx.hunterOverride;
            }
            // Zero-denominator guard: formation / low-occupancy can present an
            // empty side; float division by 0 would yield inf/NaN and garbage.
            else if (ctx.evenCountA > 0 && ctx.evenCountH > 0)
            {
                // We need to have a diff of 0.5f
                // Range of calculation: [minBgLevel, maxBgLevel], i.e: [10,20)
                float avgLvlAlliance = ctx.levelSumA / (float)ctx.evenCountA;
                float avgLvlHorde = ctx.levelSumH / (float)ctx.evenCountH;

                if (std::abs(avgLvlAlliance - avgLvlHorde) >= 0.5f)
                    team = avgLvlAlliance < avgLvlHorde ? TEAM_ALLIANCE : TEAM_HORDE;
                else if (ctx.avgIlvlA != ctx.avgIlvlH) // levels balanced, ilvl breaks the tie; an exact ilvl tie keeps the current pick
                    team = ctx.avgIlvlA < ctx.avgIlvlH ? TEAM_ALLIANCE : TEAM_HORDE;
            }
        }
        else if (ctx.levelSumA == ctx.levelSumH && ctx.avgIlvlA != ctx.avgIlvlH)
        {
            team = ctx.avgIlvlA < ctx.avgIlvlH ? TEAM_ALLIANCE : TEAM_HORDE;
        }

        return team;
    }

    // 3. Item level (only if CFBG.Include.Avg.Ilvl.Enable).
    if (IsEnableAvgIlvl() && ctx.avgIlvlA != ctx.avgIlvlH)
        return ctx.avgIlvlA < ctx.avgIlvlH ? TEAM_ALLIANCE : TEAM_HORDE;

    // 4. Fallback: the provisional / candidate team.
    return ctx.fallback;
}

uint8 CFBG::getBalanceClassMinLevel(Battleground const* bg) const
{
    return static_cast<uint8>(bg->GetMaxLevel()) - _balanceClassLevelDiff;
}

TeamId CFBG::getTeamWithLowerClass(Battleground *bg, Classes c)
{
    uint16 hordeClassQty = 0;
    uint16 allianceClassQty = 0;

    for (auto const& [playerGuid, player] : bg->GetPlayers())
    {
        if (player && player->getClass() == c)
        {
            if (player->GetTeamId() == TEAM_ALLIANCE)
            {
                allianceClassQty++;
            }
            else
            {
                hordeClassQty++;
            }
        }
    }

    return hordeClassQty > allianceClassQty ? TEAM_ALLIANCE : TEAM_HORDE;
}

void CFBG::ValidatePlayerForBG(Battleground* bg, Player* player)
{
    if (!_IsEnableSystem || !bg || bg->isArena() || !player)
        return;

    // A WG fake survives the teleport into a BG: OnPlayerUpdateZone's
    // InBattleground() guard blocks the deferred clear. Drop it so
    // BalanceTeamsOnEntry and SetFakeRaceAndMorph run against BG state.
    if (IsPlayerFake(player))
        ClearFakePlayer(player);

    BalanceTeamsOnEntry(bg, player);

    TeamId const assigned = player->GetBgTeamId();

    // Keep bgTeamId authoritative (also covers the TEAM_NEUTRAL bootstrap where GetBgTeamId() falls back to m_team)
    player->GetBGData().bgTeamId = assigned;

    EnforceBGTeamConsistency(player);

    // AV forced reactions apply only to a cross-faction (faked) player;
    // a native player already holds the correct Frostwolf/Stormpike standings.
    if (!IsPlayingNative(player) && bg->GetMapId() == MapAlteracValley)
    {
        if (assigned == TEAM_HORDE)
        {
            player->GetReputationMgr().ApplyForceReaction(FACTION_FROSTWOLF_CLAN, REP_FRIENDLY, true);
            player->GetReputationMgr().ApplyForceReaction(FACTION_STORMPIKE_GUARD, REP_HOSTILE, true);
        }
        else
        {
            player->GetReputationMgr().ApplyForceReaction(FACTION_FROSTWOLF_CLAN, REP_HOSTILE, true);
            player->GetReputationMgr().ApplyForceReaction(FACTION_STORMPIKE_GUARD, REP_FRIENDLY, true);
        }

        player->GetReputationMgr().SendForceReactions();
    }
}

void CFBG::EnforceBGTeamConsistency(Player* player)
{
    if (!player || !player->InBattleground())
        return;

    Battleground* bg = player->GetBattleground();
    if (!bg || bg->isArena())
        return;

    TeamId const assigned = player->GetBgTeamId();

    // Native: must not carry a fake.
    if (player->GetTeamId(true) == assigned)
    {
        if (IsPlayerFake(player))
            ClearFakePlayer(player);

        // A foreign template can outlive its writer on a non-faked native
        // (e.g. a charm undone after an unfake). Repair it unless a legitimate
        // writer owns it: GM-on holds FACTION_FRIENDLY; an active MOD_FACTION
        // aura restores natives correctly on removal.
        if (!player->IsGameMaster() && !player->HasAuraType(SPELL_AURA_MOD_FACTION))
        {
            ChrRacesEntry const* raceEntry = sChrRacesStore.LookupEntry(player->getRace(true));
            if (raceEntry && player->GetFaction() != raceEntry->FactionID)
                SetFactionForRace(player, player->getRace(true), player->GetTeamId(true));
        }

        return;
    }

    // Cross-faction: must be faked to `assigned`.
    FakePlayer const* info = GetFakePlayer(player);
    if (!info)
        SetFakeRaceAndMorph(player);            // not faked yet -> apply
    else if (info->FakeTeamID != assigned)
    {
        ClearFakePlayer(player);                // stale wrong-team fake -> redo
        SetFakeRaceAndMorph(player);
    }
    else
        ReapplyFakePlayer(player);              // correct side -> re-push reset values
}

void CFBG::BalanceTeamsOnEntry(Battleground* bg, Player* player)
{
    // The invite-time team was chosen using level/ilvl, but declined invites can
    // leave the teams uneven once players actually arrive. Here we only correct
    // that head-count distortion for solo entrants.
    if (!IsEnableSystem() || !IsEnableBalanceTeamsOnEntry())
        return;

    if (bg->isArena() || bg->isRated())
        return;

    // Never split a genuine BG premade materialising here, but a solo-queued
    // player who merely sits in a social/questing party (e.g. a duo auto-queued
    // as two separate solo entries) is still eligible. At this hook -- before BG
    // raid placement -- GetGroup() is the social party.
    if (IsPartyCommittedToBG(player, player->GetGroup(), bg))
        return;

    // Genuine first entry only: skip relog re-adds (already in the BG), otherwise
    // the invited-count books would be adjusted a second time.
    if (bg->GetPlayers().find(player->GetGUID()) != bg->GetPlayers().end())
        return;

    // Never flip a player who is already faked. The faction sync that backs
    // GetTeamId() -- SetFakeRaceAndMorph -> SetFactionForRace -> setTeamId() -- is
    // skipped for already-faked players (its IsPlayerFake guard). Flipping bgTeamId
    // now would therefore move the player to the new side for grouping/graveyards/
    // win purposes while GetTeamId() (used by flag capture and scoring) stays on the
    // OLD side -- e.g. an Alliance player on Horde's side capturing Alliance flags.
    // Fresh entrants are not faked yet (the morph runs right after this), so they
    // are still rebalanced normally.
    if (IsPlayerFake(player))
        return;

    TeamId provisional = player->GetBgTeamId();

    // The invited ledger (entered + accepted-in-flight + pending-invited) sees
    // reservations that live head counts miss while invitees are still porting
    // (issue #172: a solo flipped onto a porting premade's side -> 1v3).
    int32 countA = bg->GetInvitedCount(TEAM_ALLIANCE);
    int32 countH = bg->GetInvitedCount(TEAM_HORDE);

    // Accept does not release the reservation (RemovePlayer with
    // decreaseInvitedCount=false), so the entrant is still ledgered on the
    // provisional side: exclude them from the comparison.
    if (provisional == TEAM_ALLIANCE)
        --countA;
    else
        --countH;

    // Sides already balanced: keep the provisional team, no morph / count churn.
    if (countA == countH)
        return;

    TeamId corrected = (countA < countH) ? TEAM_ALLIANCE : TEAM_HORDE;

    if (corrected == provisional)
        return;

    // Move the reserved slot to the corrected side. DecreaseInvitedCount is safe:
    // accept does not decrement, so the player is still counted as invited on the
    // provisional team; the method is underflow-guarded. The matching decrement
    // happens in RemovePlayerAtLeave on the (corrected) current team -> zero-sum.
    bg->DecreaseInvitedCount(provisional);
    bg->IncreaseInvitedCount(corrected);
    player->GetBGData().bgTeamId = corrected;

    // The player was already teleported to the provisional base before AddPlayer;
    // move them to the corrected base so they don't spawn at the enemy's.
    Position const* startPos = bg->GetTeamStartPosition(corrected);
    player->TeleportTo(bg->GetMapId(), startPos->GetPositionX(), startPos->GetPositionY(),
        startPos->GetPositionZ(), startPos->GetOrientation());
}

bool CFBG::IsPartyCommittedToBG(Player* player, Group* group, Battleground* bg)
{
    if (!group)
        return false;

    for (auto const& slot : group->GetMemberSlots())
    {
        if (slot.guid == player->GetGUID())
            continue;

        // Already standing in this instance.
        if (bg->GetPlayers().find(slot.guid) != bg->GetPlayers().end())
            return true;

        // Or still porting in on an invite to it. An offline member can't be on
        // his way, so he never blocks the flip.
        Player* member = ObjectAccessor::FindConnectedPlayer(slot.guid);
        if (member && member->IsInvitedForBattlegroundInstance(bg->GetInstanceID()))
            return true;
    }

    return false;
}

void CFBG::BalanceTeamsAtStart(Battleground* bg)
{
    // The gates just opened. Team selection was balanced when the invites went
    // out, but same-side no-shows with an empty backfill queue can leave the
    // physical teams grossly uneven (4v1). Nothing re-checks the split before the
    // doors open, so do it here: flip surplus entrants onto the smaller side
    // until the diff is at most 1.
    if (!IsEnableSystem() || !IsEnableBalanceTeamsAtStart())
        return;

    if (!bg || bg->isArena() || bg->isRated())
        return;

    // Decide on physical head counts only: the pending reservations that never
    // materialised are exactly what produced the imbalance, so the invited ledger
    // must not steer the repair. Each flip shrinks the diff by 2, so the loop
    // terminates when the teams are within 1 or no flippable candidate is left.
    while (true)
    {
        uint32 const countA = bg->GetPlayersCountByTeam(TEAM_ALLIANCE);
        uint32 const countH = bg->GetPlayersCountByTeam(TEAM_HORDE);
        uint32 const diff = countA > countH ? countA - countH : countH - countA;

        if (diff < 2)
            break;

        TeamId const larger = countA > countH ? TEAM_ALLIANCE : TEAM_HORDE;
        TeamId const smaller = larger == TEAM_ALLIANCE ? TEAM_HORDE : TEAM_ALLIANCE;

        // Prefer flipping a faked player whose real faction is the smaller side:
        // the flip just unfakes him back to native (least disruption). Otherwise
        // take any flippable player on the larger side.
        Player* toFlip = nullptr;
        Player* fallback = nullptr;

        for (auto const& [guid, player] : bg->GetPlayers())
        {
            if (!player || player->GetBgTeamId() != larger)
                continue;

            // Never split a real premade. Inside the BG the social party is the
            // original group -- GetGroup() is the BG raid at this point.
            if (IsPartyCommittedToBG(player, player->GetOriginalGroup(), bg))
                continue;

            if (IsPlayerFake(player) && player->GetTeamId(true) == smaller)
            {
                toFlip = player;
                break;
            }

            if (!fallback)
                fallback = player;
        }

        if (!toFlip)
            toFlip = fallback;

        // Nothing left to flip: any residual imbalance is rooted in premades we
        // won't split. Open the match as-is -- the existing 5-minute premature
        // finish path handles a still-degenerate game, exactly as today.
        if (!toFlip)
            break;

        // Keep both the physical counts and the invited ledger zero-sum with the
        // player's future leave-time decrement (mirrors BalanceTeamsOnEntry).
        bg->UpdatePlayersCountByTeam(larger, true);
        bg->UpdatePlayersCountByTeam(smaller, false);
        bg->DecreaseInvitedCount(larger);
        bg->IncreaseInvitedCount(smaller);
        toFlip->GetBGData().bgTeamId = smaller;

        // Move him into the smaller side's BG raid. Remove from the old raid
        // first: AddOrSetPlayerToCorrectBgGroup early-returns while the player is
        // still in a BG group.
        if (Group* oldRaid = bg->GetBgRaid(larger))
            if (oldRaid->IsMember(toFlip->GetGUID()))
                if (!oldRaid->RemoveMember(toFlip->GetGUID())) // group was disbanded
                    bg->SetBgRaid(larger, nullptr);
        bg->AddOrSetPlayerToCorrectBgGroup(toFlip, smaller);

        // Apply/clear/redo the fake for the new side.
        EnforceBGTeamConsistency(toFlip);

        // The flip changed his race/faction; refresh every client's cached
        // identity for him (and his for theirs) so nobody keeps the pre-flip
        // race in their name-query cache -- same path a fresh entrant takes via
        // OnBattlegroundAddPlayer.
        FitPlayerInTeam(toFlip, bg);

        // AV forced reactions track the assigned side, so refresh them for a
        // player who is now cross-faction (a now-native player had them cleared
        // by the unfake). Mirrors ValidatePlayerForBG's entry-time handling.
        if (!IsPlayingNative(toFlip) && bg->GetMapId() == MapAlteracValley)
        {
            if (smaller == TEAM_HORDE)
            {
                toFlip->GetReputationMgr().ApplyForceReaction(FACTION_FROSTWOLF_CLAN, REP_FRIENDLY, true);
                toFlip->GetReputationMgr().ApplyForceReaction(FACTION_STORMPIKE_GUARD, REP_HOSTILE, true);
            }
            else
            {
                toFlip->GetReputationMgr().ApplyForceReaction(FACTION_FROSTWOLF_CLAN, REP_HOSTILE, true);
                toFlip->GetReputationMgr().ApplyForceReaction(FACTION_STORMPIKE_GUARD, REP_FRIENDLY, true);
            }

            toFlip->GetReputationMgr().SendForceReactions();
        }

        // Move him from his old base to the smaller side's.
        Position const* startPos = bg->GetTeamStartPosition(smaller);
        toFlip->TeleportTo(bg->GetMapId(), startPos->GetPositionX(), startPos->GetPositionY(),
            startPos->GetPositionZ(), startPos->GetOrientation());

        LOG_DEBUG("module", "mod-cfbg: BalanceTeamsAtStart flipped {} to {} in instance {} ({}v{})",
            toFlip->GetName(), static_cast<uint32>(smaller), bg->GetInstanceID(),
            bg->GetPlayersCountByTeam(TEAM_ALLIANCE), bg->GetPlayersCountByTeam(TEAM_HORDE));
    }
}

uint32 CFBG::GetMorphFromRace(uint8 race, uint8 gender)
{
    switch (race)
    {
        case RACE_BLOODELF:
            return gender == GENDER_MALE ? FAKE_M_BLOOD_ELF : FAKE_F_BLOOD_ELF;
        case RACE_ORC:
            return gender == GENDER_MALE ? FAKE_M_FEL_ORC : FAKE_F_ORC;
        case RACE_TROLL:
            return gender == GENDER_MALE ? FAKE_M_TROLL : FAKE_F_BLOOD_ELF;
        case RACE_TAUREN:
            return gender == GENDER_MALE ? FAKE_M_TAUREN : FAKE_F_TAUREN;
        case RACE_DRAENEI:
            return gender == GENDER_MALE ? FAKE_M_BROKEN_DRAENEI : FAKE_F_DRAENEI;
        case RACE_DWARF:
            return gender == GENDER_MALE ? FAKE_M_DWARF : FAKE_F_HUMAN;
        case RACE_GNOME:
            return gender == GENDER_MALE ? FAKE_M_GNOME : FAKE_F_GNOME;
        case RACE_NIGHTELF: // female is missing and male causes client crashes...
        case RACE_HUMAN:
            return gender == GENDER_MALE ? FAKE_M_HUMAN : FAKE_F_HUMAN;
        default:
            // Default: Blood elf.
            return gender == GENDER_MALE ? FAKE_M_BLOOD_ELF : FAKE_F_BLOOD_ELF;
    }
}

CFBG::RandomSkinInfo CFBG::GetRandomRaceMorph(TeamId team, uint8 playerClass, uint8 gender)
{
    RaceData const& raceData = GetRaceDataForClass(playerClass);
    uint8 playerRace = Acore::Containers::SelectRandomContainerElement(team == TEAM_ALLIANCE ? raceData.availableRacesH : raceData.availableRacesA);
    uint32 playerMorph = GetMorphFromRace(playerRace, gender);

    return { playerRace, playerMorph };
}

RaceData const& CFBG::GetRaceDataForClass(uint8 playerClass) const
{
    if (playerClass >= _raceData.size() || _raceData[playerClass].charClass == CLASS_NONE)
        return _anyClassRaceData;

    return _raceData[playerClass];
}

void CFBG::SetFakeRaceAndMorph(Player* player)
{
    if (!player->InBattleground() || player->GetTeamId(true) == player->GetBgTeamId() || IsPlayerFake(player))
        return;

    // generate random race and morph
    RandomSkinInfo skinInfo{ GetRandomRaceMorph(player->GetTeamId(true), player->getClass(), player->getGender()) };

    uint8 selectedRace = player->GetPlayerSetting("mod-cfbg", SETTING_CFBG_RACE).value;

    if (!RandomizeRaces() && selectedRace && IsRaceValidForFaction(player->GetTeamId(true), selectedRace))
    {
        skinInfo.first = selectedRace;
        skinInfo.second = GetMorphFromRace(skinInfo.first, player->getGender());
    }

    if (KeepRace())
        skinInfo = { player->getRace(true), player->GetNativeDisplayId() };

    FakePlayer fakePlayerInfo
    {
        skinInfo.first,
        skinInfo.second,
        player->GetBgTeamId(),
        player->getRace(true),
        player->GetDisplayId(),
        player->GetNativeDisplayId(),
        player->GetTeamId(true)
    };

    ApplyFakePlayer(player, fakePlayerInfo);

    _fakePlayerStore.emplace(player, std::move(fakePlayerInfo));
}

void CFBG::SetFakeRaceAndMorphForBF(Player* player, TeamId assignedTeam)
{
    if (!player || IsPlayerFake(player))
        return;

    TeamId realTeam = player->GetTeamId(true);
    if (realTeam == assignedTeam)
        return;

    // Generate a race/morph from the assigned team's faction (opposite of real faction)
    RandomSkinInfo skinInfo{ GetRandomRaceMorph(realTeam, player->getClass(), player->getGender()) };

    uint8 selectedRace = player->GetPlayerSetting("mod-cfbg", SETTING_CFBG_RACE).value;

    if (!RandomizeRaces() && selectedRace && IsRaceValidForFaction(realTeam, selectedRace))
    {
        skinInfo.first = selectedRace;
        skinInfo.second = GetMorphFromRace(skinInfo.first, player->getGender());
    }

    if (KeepRace())
        skinInfo = { player->getRace(true), player->GetNativeDisplayId() };

    FakePlayer fakePlayerInfo
    {
        skinInfo.first,
        skinInfo.second,
        assignedTeam,
        player->getRace(true),
        player->GetDisplayId(),
        player->GetNativeDisplayId(),
        realTeam
    };

    ApplyFakePlayer(player, fakePlayerInfo);

    _fakePlayerStore.emplace(player, std::move(fakePlayerInfo));
}

void CFBG::ApplyFakePlayer(Player* player, FakePlayer const& fake)
{
    if (KeepRace())
    {
        SetFactionForRace(player, GetTeamRace(fake.FakeTeamID), fake.FakeTeamID);
        return;
    }

    player->setRace(fake.FakeRace);
    SetFactionForRace(player, fake.FakeRace, fake.FakeTeamID);
    player->SetDisplayId(fake.FakeMorph);
    player->SetNativeDisplayId(fake.FakeMorph);
}

void CFBG::SetFactionForRace(Player* player, uint8 Race, TeamId teamId)
{
    if (!player)
        return;

    player->setTeamId(teamId);

    ChrRacesEntry const* DBCRace = sChrRacesStore.LookupEntry(Race);
    player->SetFaction(DBCRace ? DBCRace->FactionID : 0);

    for (Unit* controlled : player->m_Controlled)
    {
        if (controlled)
            controlled->SetFaction(player->GetFaction());
    }
}

void CFBG::ClearFakePlayer(Player* player)
{
    if (!IsPlayerFake(player))
        return;

    // Unwind any charm ON the player while the fake record still exists:
    // Unit::RemoveCharmedBy blindly restores the faction snapshotted at charm
    // time (the fake one), which the restore below then overwrites. A charm
    // ending after the unfake would re-plant the fake template (#166).
    if (player->IsCharmed())
        player->RemoveCharmAuras();

    player->setRace(_fakePlayerStore[player].RealRace);
    // Restore via the aura-resolution path, not the entry-time snapshot: a
    // player who dropped a shapeshift/transform mid-BG must get the real model
    // back, one still in the form keeps the form model. RestoreDisplayId's
    // no-aura fallback is the native display, so set that first.
    player->SetNativeDisplayId(_fakePlayerStore[player].RealNativeMorph);
    player->RestoreDisplayId();
    SetFactionForRace(player, _fakePlayerStore[player].RealRace, _fakePlayerStore[player].RealTeamID);

    // Clear forced faction reactions. Rank doesn't matter here, not used when they are removed.
    player->GetReputationMgr().ApplyForceReaction(FACTION_FROSTWOLF_CLAN, REP_FRIENDLY, false);
    player->GetReputationMgr().ApplyForceReaction(FACTION_STORMPIKE_GUARD, REP_FRIENDLY, false);

    _fakePlayerStore.erase(player);

    // The player's own name cache still holds the assigned team's race.
    WorldPacket data(SMSG_INVALIDATE_PLAYER, 8);
    data << player->GetGUID();
    player->GetSession()->SendPacket(&data);
    player->GetSession()->SendNameQueryOpcode(player->GetGUID());
}

// Erase-only: no race/morph/faction/m_team restore. Used at wartime WG logout,
// where Player::RemoveFromWorld still erases PlayersInWar keyed on the fake team.
void CFBG::DropFakePlayerRecord(Player* player)
{
    _fakePlayerStore.erase(player);
}

void CFBG::ReapplyFakePlayer(Player* player)
{
    FakePlayer const* info = GetFakePlayer(player);
    if (!info)
        return;

    // Re-push the stored fake values after a resurrect so the assigned faction
    // and morph survive the ghost->alive transition.
    ApplyFakePlayer(player, *info);
}

bool CFBG::IsPlayerFake(Player* player)
{
    return _fakePlayerStore.contains(player);
}

FakePlayer const* CFBG::GetFakePlayer(Player* player) const
{
    return Acore::Containers::MapGetValuePtr(_fakePlayerStore, player);
}

std::optional<TeamId> CFBG::GetWGWarAssignment(ObjectGuid guid) const
{
    auto const& itr = _wgWarAssignmentStore.find(guid);
    if (itr == _wgWarAssignmentStore.end())
        return std::nullopt;

    return itr->second;
}

void CFBG::SetWGWarAssignment(ObjectGuid guid, TeamId team)
{
    _wgWarAssignmentStore[guid] = team;
}

void CFBG::ClearWGWarAssignments()
{
    // A player re-faked at zone entry whose invite was still pending at war
    // end is in no PlayersInWar set, so the war-end unfake loop misses him;
    // sweep the assignments so no fake survives the war. Players inside a
    // battleground are skipped: their fake belongs to the BG lifecycle.
    for (auto const& [guid, teamId] : _wgWarAssignmentStore)
        if (Player* player = ObjectAccessor::FindPlayer(guid))
            if (!player->InBattleground() && IsPlayerFake(player))
                ClearFakePlayer(player);

    _wgWarAssignmentStore.clear();
    _wgCensusValid = false;
    _wgMajorityNativeKept = 0;
}

TeamId CFBG::ResolveWGWarTeam(Player* player, uint32 nativeAllianceInvited, uint32 nativeHordeInvited, uint32 allianceInWar, uint32 hordeInWar)
{
    // Capture the native split once: at the first join PlayersInWar is empty
    // and nobody is faked, so the invited counts are the true native census.
    if (!_wgCensusValid)
    {
        _wgMajorityTeam = (nativeAllianceInvited >= nativeHordeInvited) ? TEAM_ALLIANCE : TEAM_HORDE;
        _wgMajorityFairShare = (nativeAllianceInvited + nativeHordeInvited + 1) / 2;
        _wgMajorityNativeKept = 0;
        _wgCensusValid = true;
    }

    TeamId realTeam = player->GetTeamId(true);

    // Minority stays native.
    if (realTeam != _wgMajorityTeam)
        return realTeam;

    // Majority keeps its fair share native in accept order; the rest (latest
    // to commit) flip.
    if (_wgMajorityNativeKept < _wgMajorityFairShare)
    {
        ++_wgMajorityNativeKept;
        return realTeam;
    }

    // Past the fair share: flip only when it does not worsen the live balance —
    // with a sparse census (e.g. 1/0) and trickle joins, unconditional flips
    // would stack the entire majority onto the other side.
    uint32 const ownInWar   = (realTeam == TEAM_ALLIANCE) ? allianceInWar : hordeInWar;
    uint32 const otherInWar = (realTeam == TEAM_ALLIANCE) ? hordeInWar : allianceInWar;
    if (ownInWar > otherInWar)
        return (_wgMajorityTeam == TEAM_ALLIANCE) ? TEAM_HORDE : TEAM_ALLIANCE;

    ++_wgMajorityNativeKept;
    return realTeam;
}

void CFBG::FitPlayerInTeam(Player* player, Battleground* bg)
{
    if (!_IsEnableSystem)
        return;

    if (!bg)
        bg = player->GetBattleground();

    if (!bg || bg->isArena())
        return;

    SetForgetBGPlayers(player, true);
}

void CFBG::SetForgetBGPlayers(Player* player, bool value)
{
    _forgetBGPlayersStore[player] = value;
}

bool CFBG::ShouldForgetBGPlayers(Player* player)
{
    return _forgetBGPlayersStore[player];
}

bool CFBG::HasPendingForget(Player* player) const
{
    auto const itr = _forgetBGPlayersStore.find(player);
    return itr != _forgetBGPlayersStore.end() && itr->second;
}

void CFBG::DoForgetPlayersInBG(Player* player, Battleground* bg)
{
    for (auto const& itr : bg->GetPlayers())
    {
        // Here we invalidate players in the bg to the added player
        WorldPacket data1(SMSG_INVALIDATE_PLAYER, 8);
        data1 << itr.first;
        player->GetSession()->SendPacket(&data1);

        if (Player* _player = ObjectAccessor::FindPlayer(itr.first))
        {
            player->GetSession()->SendNameQueryOpcode(_player->GetGUID()); // Send namequery answer instantly if player is available

            // Here we invalidate the player added to players in the bg
            WorldPacket data2(SMSG_INVALIDATE_PLAYER, 8);
            data2 << player->GetGUID();
            _player->GetSession()->SendPacket(&data2);
            _player->GetSession()->SendNameQueryOpcode(player->GetGUID());
        }
    }
}

bool CFBG::IsPlayingNative(Player* player)
{
    return player->GetTeamId(true) == player->GetBGData().bgTeamId;
}

std::array<uint32, 2> CFBG::GetProjectedBaseCounts(Battleground* bg, BattlegroundQueue* queue, BattlegroundBracketId bracketId) const
{
    if (!bg)
        return { 0, 0 };

    std::array<uint32, 2> counts{ bg->GetPlayersCountByTeam(TEAM_ALLIANCE), bg->GetPlayersCountByTeam(TEAM_HORDE) };

    // An invite reserves the slot even if the player is disconnected; groups
    // invited to a different instance are reserved elsewhere and don't count.
    for (auto const& gInfo : queue->m_QueuedGroups[bracketId][BG_QUEUE_CFBG])
        if (gInfo->IsInvitedToBGInstanceGUID == bg->GetInstanceID())
            counts[gInfo->teamId] += gInfo->Players.size();

    // A player between accept and worldport ack is in neither term above (the
    // accept deleted their ginfo; AddPlayer has not run yet). The BG's invited
    // ledger still holds every reservation, so clamp up to it; max() degrades
    // gracefully if either register is skewed.
    uint32 const computedA = counts[TEAM_ALLIANCE];
    uint32 const computedH = counts[TEAM_HORDE];
    counts[TEAM_ALLIANCE] = std::max(computedA, bg->GetInvitedCount(TEAM_ALLIANCE));
    counts[TEAM_HORDE] = std::max(computedH, bg->GetInvitedCount(TEAM_HORDE));

    // The ledger exceeding the physical + invited-queued tally is the signature
    // of a leaked reservation steering selection. In-flight accepts trip this
    // briefly and legitimately, so it stays at debug for operators hunting a
    // persistent skew.
    if (counts[TEAM_ALLIANCE] > computedA || counts[TEAM_HORDE] > computedH)
        LOG_DEBUG("module", "mod-cfbg: instance {} projections clamped by invited ledger (A {}->{}, H {}->{}), possible phantom reservation",
            bg->GetInstanceID(), computedA, counts[TEAM_ALLIANCE], computedH, counts[TEAM_HORDE]);

    return counts;
}

void CFBG::SelectBalancedGroups(BattlegroundQueue* queue, BattlegroundBracketId bracketId, Battleground* bg, uint32 maxPerTeam, uint32 allowedDiff)
{
    auto base = GetProjectedBaseCounts(bg, queue, bracketId);

    // Base level sums mirror the head counts: in-BG players plus the
    // invited-not-yet-entered ones (disconnected invitees contribute 0).
    std::array<uint32, 2> baseLevelSum{};
    if (bg)
    {
        baseLevelSum = { GetBGTeamSumPlayerLevel(bg, TEAM_ALLIANCE), GetBGTeamSumPlayerLevel(bg, TEAM_HORDE) };

        for (auto const& gInfo : queue->m_QueuedGroups[bracketId][BG_QUEUE_CFBG])
        {
            if (gInfo->IsInvitedToBGInstanceGUID != bg->GetInstanceID())
                continue;

            for (auto const& playerGuid : gInfo->Players)
                if (auto player = ObjectAccessor::FindConnectedPlayer(playerGuid))
                    baseLevelSum[gInfo->teamId] += player->GetLevel();
        }
    }

    std::array<GroupsList, 2> staged;
    std::array<uint32, 2> stagedCount{};
    std::array<uint32, 2> stagedLevelSum{};
    std::array<uint32, 2> stagedIlvlSum{};

    // Stage: greedy FIFO pass onto the smaller projected side; groups are
    // staged whole -- a premade party is never split.
    for (auto const& gInfo : queue->m_QueuedGroups[bracketId][BG_QUEUE_CFBG])
    {
        if (gInfo->IsInvitedToBGInstanceGUID)
            continue;

        auto cfInfo = CrossFactionGroupInfo(gInfo);

        TeamBalanceContext ctx;
        ctx.countA = base[TEAM_ALLIANCE] + stagedCount[TEAM_ALLIANCE];
        ctx.countH = base[TEAM_HORDE] + stagedCount[TEAM_HORDE];

        ctx.levelSumA = baseLevelSum[TEAM_ALLIANCE] + stagedLevelSum[TEAM_ALLIANCE];
        ctx.levelSumH = baseLevelSum[TEAM_HORDE] + stagedLevelSum[TEAM_HORDE];

        // ilvl metric: live BG average when reinforcing, staged sums at formation.
        ctx.avgIlvlA = bg ? GetBGTeamAverageItemLevel(bg, TEAM_ALLIANCE) : stagedIlvlSum[TEAM_ALLIANCE];
        ctx.avgIlvlH = bg ? GetBGTeamAverageItemLevel(bg, TEAM_HORDE) : stagedIlvlSum[TEAM_HORDE];

        ctx.evenCountA = ctx.countA;
        ctx.evenCountH = ctx.countH;

        ctx.hunterOverride = bg ? ResolveHunterOverride(bg, cfInfo) : std::nullopt;
        ctx.fallback = gInfo->teamId;

        TeamId team = ResolveBalancedTeam(ctx);

        // team is the smaller projected side; under a symmetric cap, a group
        // that does not fit there cannot fit the other side either.
        if (base[team] + stagedCount[team] + gInfo->Players.size() > maxPerTeam)
            continue;

        staged[team].emplace_back(gInfo);
        stagedCount[team] += gInfo->Players.size();
        stagedLevelSum[team] += cfInfo.SumPlayerLevel;
        stagedIlvlSum[team] += cfInfo.SumAverageItemLevel;
    }

    // Repair: move or drop staged groups until the diff fits allowedDiff. Moves
    // strictly shrink the diff, drops the selection, so the loop terminates.
    while (true)
    {
        uint32 projA = base[TEAM_ALLIANCE] + stagedCount[TEAM_ALLIANCE];
        uint32 projH = base[TEAM_HORDE] + stagedCount[TEAM_HORDE];
        uint32 diff = projA > projH ? projA - projH : projH - projA;

        if (diff <= allowedDiff)
            break;

        TeamId larger = projA > projH ? TEAM_ALLIANCE : TEAM_HORDE;
        TeamId smaller = larger == TEAM_ALLIANCE ? TEAM_HORDE : TEAM_ALLIANCE;

        // Imbalance rooted in already-entered/invited players; the selection
        // only narrows the gap -- invite it as-is.
        if (staged[larger].empty())
            break;

        // Prefer moving a group across -- nobody loses the invite. Pick the
        // move landing closest to balance (first staged wins ties).
        GroupQueueInfo* moveGroup = nullptr;
        uint32 moveDiff = diff;

        for (auto const& gInfo : staged[larger])
        {
            uint32 transfer = gInfo->Players.size() * 2;
            uint32 newDiff = transfer > diff ? transfer - diff : diff - transfer;

            if (newDiff < moveDiff && base[smaller] + stagedCount[smaller] + gInfo->Players.size() <= maxPerTeam)
            {
                moveGroup = gInfo;
                moveDiff = newDiff;
            }
        }

        if (moveGroup)
        {
            std::erase(staged[larger], moveGroup);
            staged[smaller].emplace_back(moveGroup);
            stagedCount[larger] -= moveGroup->Players.size();
            stagedCount[smaller] += moveGroup->Players.size();
            continue;
        }

        // No useful move: drop the group landing closest to balance; ties drop
        // the newest. Dropped groups stay queued for the next update.
        GroupQueueInfo* dropGroup = nullptr;
        uint32 dropDiff = 0;

        for (auto const& gInfo : staged[larger])
        {
            uint32 size = gInfo->Players.size();
            uint32 newDiff = size > diff ? size - diff : diff - size;

            if (!dropGroup || newDiff < dropDiff || (newDiff == dropDiff && gInfo->JoinTime > dropGroup->JoinTime))
            {
                dropGroup = gInfo;
                dropDiff = newDiff;
            }
        }

        std::erase(staged[larger], dropGroup);
        stagedCount[larger] -= dropGroup->Players.size();
    }

    // Invite: write the staged selection into the pools; caps were enforced
    // while staging, so every AddGroup succeeds.
    queue->m_SelectionPools[TEAM_ALLIANCE].Init();
    queue->m_SelectionPools[TEAM_HORDE].Init();

    for (auto team : { TEAM_ALLIANCE, TEAM_HORDE })
    {
        for (auto const& gInfo : staged[team])
        {
            gInfo->teamId = team;
            queue->m_SelectionPools[team].AddGroup(gInfo, maxPerTeam - base[team]);
        }
    }
}

bool CFBG::CheckCrossFactionMatch(BattlegroundQueue* queue, BattlegroundBracketId bracket_id, uint32 minPlayers, uint32 maxPlayers)
{
    if (!IsEnableSystem())
        return false;

    bool isTesting = sBattlegroundMgr->isTesting();
    SelectBalancedGroups(queue, bracket_id, nullptr, maxPlayers, isTesting ? maxPlayers : (IsEnableEvenTeams() ? 0 : 1));

    // Mirror core CanStartMatch's testing arm: under .debug bg a single
    // non-empty pool is enough to start (1v0), so skip the pool reset.
    if (isTesting && (queue->m_SelectionPools[TEAM_ALLIANCE].GetPlayerCount() || queue->m_SelectionPools[TEAM_HORDE].GetPlayerCount()))
        return true;

    // Return when we're ready to start a BG, if we're in startup process
    if (queue->m_SelectionPools[TEAM_ALLIANCE].GetPlayerCount() >= minPlayers &&
        queue->m_SelectionPools[TEAM_HORDE].GetPlayerCount() >= minPlayers)
        return true;

    // Return false when we didn't manage to fill the BattleGround in Filling "mode".
    // reset selectionpool for further attempts
    queue->m_SelectionPools[TEAM_ALLIANCE].Init();
    queue->m_SelectionPools[TEAM_HORDE].Init();
    return true;
}

bool CFBG::FillPlayersToCFBG(BattlegroundQueue* bgqueue, Battleground* bg, BattlegroundBracketId bracket_id)
{
    if (!IsEnableSystem() || bg->isArena() || bg->isRated())
        return false;

    uint32 allowedDiff = 1;

    if (IsEnableEvenTeams())
    {
        // Threshold 0 enforces even teams at all sizes; otherwise relax to
        // diff <= 1 once the projected total reaches threshold * 2.
        uint32 threshold = EvenTeamsMaxPlayersThreshold();
        auto base = GetProjectedBaseCounts(bg, bgqueue, bracket_id);

        if (!threshold || base[TEAM_ALLIANCE] + base[TEAM_HORDE] < threshold * 2)
            allowedDiff = 0;
    }

    // Cap on GetMaxPlayersPerTeam, not GetFreeSlotsForTeam: the latter imposes
    // no relative cap with Battleground.InvitationType = 0.
    SelectBalancedGroups(bgqueue, bracket_id, bg, bg->GetMaxPlayersPerTeam(), allowedDiff);
    return true;
}

bool CFBG::isClassJoining(uint8 _class, Player* player, uint32 minLevel)
{
    if (!player)
    {
        return false;
    }

    return player->getClass() == _class && (player->GetLevel() >= minLevel);
}

void CFBG::UpdateForget(Player* player)
{
    Battleground* bg = player->GetBattleground();
    if (bg && ShouldForgetBGPlayers(player))
    {
        DoForgetPlayersInBG(player, bg);
        SetForgetBGPlayers(player, false);
    }
}

void CFBG::SendMessageQueue(BattlegroundQueue* bgQueue, Battleground* bg, PvPDifficultyEntry const* bracketEntry, Player* leader)
{
    BattlegroundBracketId bracketId = bracketEntry->GetBracketId();

    auto bgName = bg->GetName();
    uint32 q_min_level = std::min(bracketEntry->minLevel, (uint32)80);
    uint32 q_max_level = std::min(bracketEntry->maxLevel, (uint32)80);
    uint32 MinPlayers = GetMinPlayersPerTeam(bg, bracketEntry) * 2;
    uint32 qTotal = bgQueue->GetPlayersCountInGroupsQueue(bracketId, (BattlegroundQueueGroupTypes)BG_QUEUE_CFBG);

    if (sWorld->getBoolConfig(CONFIG_BATTLEGROUND_QUEUE_ANNOUNCER_PLAYERONLY))
    {
        ChatHandler(leader->GetSession()).PSendSysMessage("CFBG {} (Levels: {} - {}). Registered: {}/{}", bgName.c_str(), q_min_level, q_max_level, qTotal, MinPlayers);
    }
    else
    {
        if (sWorld->getBoolConfig(CONFIG_BATTLEGROUND_QUEUE_ANNOUNCER_TIMED))
        {
            if (bgQueue->GetQueueAnnouncementTimer(bracketEntry->bracketId) < 0)
            {
                bgQueue->SetQueueAnnouncementTimer(bracketEntry->bracketId, sWorld->getIntConfig(CONFIG_BATTLEGROUND_QUEUE_ANNOUNCER_TIMER));
            }
        }
        else
        {
            // Defer to the shared core announcer (cross-faction); spam-window and
            // Limit gating now happen centrally in BattlegroundQueueAnnouncerUpdate.
            if (bgQueue->GetQueueAnnouncementTimer(bracketId) < 0)
            {
                bgQueue->SetQueueAnnouncementTimer(bracketId, BG_QUEUE_ANNOUNCER_IMMEDIATE_DEBOUNCE, true);
            }
        }
    }
}

bool CFBG::IsRaceValidForFaction(uint8 teamId, uint8 race)
{
    for (auto const& raceVariable : _raceInfo)
    {
        if (race == raceVariable.RaceId && teamId == raceVariable.TeamId)
        {
            return true;
        }
    }

    return false;
}
