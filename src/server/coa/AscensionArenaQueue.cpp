/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "ArenaSeasonMgr.h"
#include "ArenaTeam.h"
#include "ArenaTeamMgr.h"
#include "AscensionCompatOpcodes.h"
#include "Battleground.h"
#include "BattlegroundMgr.h"
#include "BattlegroundQueue.h"
#include "Chat.h"
#include "Config.h"
#include "DBCStores.h"
#include "DisableMgr.h"
#include "GameTime.h"
#include "Group.h"
#include "LFGMgr.h"
#include "Language.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"
#include "WorldState.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <bit>
#include <mutex>
#include <optional>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
    constexpr uint16 CMSG_BATTLEMASTER_JOIN_ARENA_WITH_ROLE = 0x05C1;
    constexpr uint32 ARENA_ROLE_HEALER = 0x04;

    struct ArenaRequest
    {
        uint32 Bracket = 0;
        uint32 Role = 0;
    };

    struct SoloBracket
    {
        uint8 ArenaType;
        uint8 TeamType;
        char const* Suffix;
    };

    std::optional<SoloBracket> SoloBracketFor(uint32 bracket)
    {
        switch (bracket)
        {
            case 2:
                return SoloBracket{ ARENA_TYPE_2v2, ARENA_TEAM_2v2, "2v2" };
            case 3:
                return SoloBracket{ ARENA_TYPE_3v3, ARENA_TEAM_3v3, "3v3" };
            case 5:
                return SoloBracket{ ARENA_TYPE_1v1, ARENA_TEAM_5v5, "1v1" };
            default:
                return std::nullopt;
        }
    }

    bool IsSoloTeamBracket(uint8 arenaType)
    {
        return arenaType == ARENA_TYPE_2v2 || arenaType == ARENA_TYPE_3v3;
    }

    bool IsSoloMatchedBracket(uint8 arenaType)
    {
        return arenaType == ARENA_TYPE_1v1 || IsSoloTeamBracket(arenaType);
    }

    uint8 SideTeamTypeFor(uint8 arenaType)
    {
        return arenaType == ARENA_TYPE_1v1 ? uint8(ARENA_TEAM_5v5) : arenaType;
    }

    class SoloSideTeam final : public ArenaTeam
    {
    public:
        SoloSideTeam(uint8 type, std::string const& name, uint32 rating)
        {
            TeamId = sArenaTeamMgr->GenerateTempArenaTeamId();
            Type = type;
            TeamName = name;
            Stats = ArenaTeamStats{};
            Stats.Rating = uint16(rating);
        }

        void ClearStats()
        {
            Stats = ArenaTeamStats{};
        }
    };

    struct SoloParticipant
    {
        uint32 PersonalTeamId = 0;
        TeamId Side = TEAM_NEUTRAL;
        bool Settled = false;
    };

    struct SoloMatch
    {
        std::array<SoloSideTeam*, PVP_TEAMS_COUNT> Sides{};
        std::array<uint32, PVP_TEAMS_COUNT> MatchmakerRating{};
        bool Started = false;
        std::unordered_map<ObjectGuid, SoloParticipant> Participants;
    };

    struct RatingUpdate
    {
        uint32 PersonalTeamId = 0;
        uint32 OpponentMatchmakerRating = 0;
    };

    std::mutex StateLock;
    std::unordered_map<WorldSession const*, ArenaRequest> PendingRequests;
    std::atomic<bool> AnyPending = false;
    std::unordered_map<ObjectGuid, ArenaRequest> ReadyRequests;
    std::unordered_map<ObjectGuid, bool> HealerByPlayer;
    std::unordered_map<ObjectGuid, uint32> QueuedPersonalTeams;
    std::unordered_map<uint32, SoloMatch> MatchByInstance;
    std::unordered_map<uint32, uint32> InstanceBySideTeam;

    bool QueueRequest(WorldSession* session, WorldPacket const& received)
    {
        if (!session)
            return true;

        WorldPacket packet(received);
        packet.rpos(0);
        ArenaRequest request;
        try
        {
            request.Bracket = packet.read<uint32>();
            request.Role = packet.read<uint32>();
        }
        catch (ByteBufferException const&)
        {
            return true;
        }

        std::lock_guard<std::mutex> lock(StateLock);
        PendingRequests[session] = request;
        AnyPending = true;
        return true;
    }

    void SendJoinResult(Player* player, GroupJoinBattlegroundResult result)
    {
        WorldPacket data;
        sBattlegroundMgr->BuildGroupJoinedBattlegroundPacket(&data, result);
        player->SendDirectMessage(&data);
    }

    ArenaTeam* PersonalTeam(Player* player, SoloBracket const& bracket)
    {
        uint8 slot = ArenaTeam::GetSlotByType(bracket.TeamType);
        if (uint32 teamId = player->GetArenaTeamId(slot))
        {
            ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(teamId);
            if (team && team->GetMembersSize() == 1 && team->IsMember(player->GetGUID()))
                return team;

            ChatHandler(player->GetSession()).SendSysMessage(
                "Leave your arena team in this bracket to use the rated solo queue.");
            return nullptr;
        }

        std::string name = player->GetName() + " " + bracket.Suffix;
        if (sArenaTeamMgr->GetArenaTeamByName(name))
        {
            ChatHandler(player->GetSession()).PSendSysMessage("The arena team name {} is already taken.", name);
            return nullptr;
        }

        ArenaTeam* team = new ArenaTeam();
        if (!team->Create(player->GetGUID(), bracket.TeamType, name, 0, 0, 0, 0, 0))
        {
            delete team;
            return nullptr;
        }

        sArenaTeamMgr->AddArenaTeam(team);
        return team->IsMember(player->GetGUID()) ? team : nullptr;
    }

    void JoinRatedSoloQueue(Player* player, ArenaRequest const& request)
    {
        std::optional<SoloBracket> bracket = SoloBracketFor(request.Bracket);
        if (!bracket)
            return;

        if (player->InBattleground())
        {
            SendJoinResult(player, ERR_BATTLEGROUND_NOT_IN_BATTLEGROUND);
            return;
        }

        Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
        if (!arenaTemplate)
            return;

        if (sDisableMgr->IsDisabledFor(DISABLE_TYPE_BATTLEGROUND, BATTLEGROUND_AA, nullptr))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(LANG_ARENA_DISABLED);
            return;
        }

        PvPDifficultyEntry const* bracketEntry =
            GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), player->GetLevel());
        if (!bracketEntry)
            return;

        if (sArenaSeasonMgr->GetSeasonState() == ARENA_SEASON_STATE_DISABLED)
        {
            ChatHandler(player->GetSession()).SendSysMessage("Rated arenas are closed until the next season starts.");
            return;
        }

        if (player->InBattlegroundQueue())
        {
            SendJoinResult(player, ERR_BATTLEGROUND_CANNOT_QUEUE_FOR_RATED);
            return;
        }

        uint8 slot = ArenaTeam::GetSlotByType(bracket->TeamType);
        GroupJoinBattlegroundResult result = GroupJoinBattlegroundResult(BATTLEGROUND_AA);
        if (!sScriptMgr->OnPlayerCanJoinInArenaQueue(player, ObjectGuid::Empty, slot, BATTLEGROUND_AA, 0, 1, result)
            && result <= 0)
        {
            SendJoinResult(player, result);
            return;
        }

        lfg::LfgState lfgState = sLFGMgr->GetState(player->GetGUID());
        if (lfgState > lfg::LFG_STATE_NONE
            && (lfgState != lfg::LFG_STATE_QUEUED || !sWorld->getBoolConfig(CONFIG_ALLOW_JOIN_BG_AND_LFG)))
        {
            SendJoinResult(player, ERR_LFG_CANT_USE_BATTLEGROUND);
            return;
        }

        if (player->HasPlayerFlag(PLAYER_FLAGS_NO_PLAY_TIME))
        {
            SendJoinResult(player, ERR_GROUP_JOIN_BATTLEGROUND_FAIL);
            return;
        }

        BattlegroundQueueTypeId queueType = BattlegroundMgr::BGQueueTypeId(BATTLEGROUND_AA, bracket->ArenaType);
        if (player->GetBattlegroundQueueIndex(queueType) < PLAYER_MAX_BATTLEGROUND_QUEUES
            || !player->HasFreeBattlegroundQueueId())
            return;

        ArenaTeam* team = PersonalTeam(player, *bracket);
        if (!team)
            return;

        ArenaTeamMember* member = team->GetMember(player->GetGUID());
        if (!member)
            return;

        uint32 arenaRating = std::max<uint32>(team->GetRating(), 1);
        uint32 matchmakerRating = member->MatchMakerRating;

        {
            std::lock_guard<std::mutex> lock(StateLock);
            HealerByPlayer[player->GetGUID()] = (request.Role & ARENA_ROLE_HEALER) != 0;
        }

        BattlegroundQueue& queue = sBattlegroundMgr->GetBattlegroundQueue(queueType);
        GroupQueueInfo* ginfo = queue.AddGroup(player, nullptr, BATTLEGROUND_AA, bracketEntry, bracket->ArenaType, true,
            false, arenaRating, matchmakerRating, team->GetId(), team->GetPreviousOpponents());
        uint32 averageWaitTime = queue.GetAverageQueueWaitTime(ginfo);
        uint32 queueSlot = player->AddBattlegroundQueueId(queueType);

        WorldPacket status;
        sBattlegroundMgr->BuildBattlegroundStatusPacket(&status, arenaTemplate, queueSlot, STATUS_WAIT_QUEUE,
            averageWaitTime, 0, bracket->ArenaType, TEAM_NEUTRAL, true);
        player->SendDirectMessage(&status);

        sScriptMgr->OnPlayerJoinArena(player);
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::SoloArenaQueued, bracket->ArenaType);
        sBattlegroundMgr->ScheduleQueueUpdate(std::max<uint32>(matchmakerRating, 1), bracket->ArenaType, queueType,
            BATTLEGROUND_AA, bracketEntry->GetBracketId());
    }

    std::optional<uint32> SoloRequestBracketForSlot(uint8 arenaSlot)
    {
        switch (arenaSlot)
        {
            case 0:
                return 2;
            case 1:
                return 3;
            case 2:
                return 5;
            default:
                return std::nullopt;
        }
    }

    ArenaRequest RequestWithDeclaredRole(Player* player, uint32 bracket)
    {
        std::lock_guard<std::mutex> lock(StateLock);
        auto itr = HealerByPlayer.find(player->GetGUID());
        bool declaredHealer = itr != HealerByPlayer.end() && itr->second;
        return ArenaRequest{ bracket, declaredHealer ? ARENA_ROLE_HEALER : 0 };
    }

    bool IsPersonalTeam(uint32 teamId)
    {
        ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(teamId);
        return team && team->GetMembersSize() == 1;
    }

    bool IsWholePartyInLeaderTeam(Player* leader, Group* group, uint8 arenaSlot)
    {
        if (!group)
            return false;

        ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(leader->GetArenaTeamId(arenaSlot));
        if (!team || team->GetMembersSize() < 2)
            return false;

        for (Group::MemberSlot const& slot : group->GetMemberSlots())
            if (!team->IsMember(slot.guid))
                return false;

        return true;
    }

    std::vector<Player*> OnlinePartyMembers(Group* group)
    {
        std::vector<Player*> members;
        group->DoForAllMembers([&members](Player* member)
        {
            members.push_back(member);
        });
        return members;
    }

    void SendJoinResultToParty(Group* group, GroupJoinBattlegroundResult result)
    {
        for (Player* member : OnlinePartyMembers(group))
            SendJoinResult(member, result);
    }

    GroupJoinBattlegroundResult CheckRatedPremade(Group* group, Battleground* arenaTemplate,
        BattlegroundQueueTypeId queueType, SoloBracket const& bracket, uint8 arenaSlot)
    {
        if (group->isRaidGroup() || group->GetMembersCount() > bracket.ArenaType)
            return ERR_ARENA_TEAM_PARTY_SIZE;

        GroupJoinBattlegroundResult result = group->CanJoinBattlegroundQueue(arenaTemplate, queueType,
            group->GetMembersCount(), bracket.ArenaType, false, arenaSlot);
        if (result <= 0)
            return result;

        for (Player* member : OnlinePartyMembers(group))
        {
            if (member->InBattlegroundQueue())
                return ERR_BATTLEGROUND_CANNOT_QUEUE_FOR_RATED;

            GroupJoinBattlegroundResult memberResult = GroupJoinBattlegroundResult(BATTLEGROUND_AA);
            if (!sScriptMgr->OnPlayerCanJoinInArenaQueue(member, ObjectGuid::Empty, arenaSlot, BATTLEGROUND_AA, 0, 1,
                memberResult) && memberResult <= 0)
                return memberResult;
        }

        return result;
    }

    void JoinRatedPremadeQueue(Player* leader, Group* group, SoloBracket const& bracket, uint8 arenaSlot)
    {
        Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
        if (!arenaTemplate)
            return;

        PvPDifficultyEntry const* bracketEntry =
            GetBattlegroundBracketByLevel(arenaTemplate->GetMapId(), leader->GetLevel());
        if (!bracketEntry)
            return;

        if (sArenaSeasonMgr->GetSeasonState() == ARENA_SEASON_STATE_DISABLED)
        {
            ChatHandler(leader->GetSession()).SendSysMessage("Rated arenas are closed until the next season starts.");
            return;
        }

        BattlegroundQueueTypeId queueType = BattlegroundMgr::BGQueueTypeId(BATTLEGROUND_AA, bracket.ArenaType);
        GroupJoinBattlegroundResult result = CheckRatedPremade(group, arenaTemplate, queueType, bracket, arenaSlot);
        if (result <= 0)
        {
            SendJoinResultToParty(group, result);
            return;
        }

        std::vector<Player*> members = OnlinePartyMembers(group);
        std::unordered_map<ObjectGuid, uint32> personalTeams;
        uint64 totalTeamRating = 0;
        uint64 totalMatchmakerRating = 0;
        for (Player* member : members)
        {
            ArenaTeam* team = PersonalTeam(member, bracket);
            ArenaTeamMember* teamMember = team ? team->GetMember(member->GetGUID()) : nullptr;
            if (!teamMember)
            {
                SendJoinResultToParty(group, ERR_BATTLEGROUND_JOIN_FAILED);
                return;
            }

            personalTeams[member->GetGUID()] = team->GetId();
            totalTeamRating += team->GetRating();
            totalMatchmakerRating += teamMember->MatchMakerRating;
        }

        uint32 arenaRating = std::max<uint32>(uint32(totalTeamRating / members.size()), 1);
        uint32 matchmakerRating = uint32(totalMatchmakerRating / members.size());

        {
            std::lock_guard<std::mutex> lock(StateLock);
            for (auto const& [guid, teamId] : personalTeams)
                QueuedPersonalTeams[guid] = teamId;
        }

        BattlegroundQueue& queue = sBattlegroundMgr->GetBattlegroundQueue(queueType);
        GroupQueueInfo* ginfo = queue.AddGroup(leader, group, BATTLEGROUND_AA, bracketEntry, bracket.ArenaType, true,
            false, arenaRating, matchmakerRating, personalTeams[leader->GetGUID()], 0);
        uint32 averageWaitTime = queue.GetAverageQueueWaitTime(ginfo);

        for (Player* member : members)
        {
            uint32 queueSlot = member->AddBattlegroundQueueId(queueType);

            WorldPacket status;
            sBattlegroundMgr->BuildBattlegroundStatusPacket(&status, arenaTemplate, queueSlot, STATUS_WAIT_QUEUE,
                averageWaitTime, 0, bracket.ArenaType, TEAM_NEUTRAL, true);
            member->SendDirectMessage(&status);
            SendJoinResult(member, result);

            sScriptMgr->OnPlayerJoinArena(member);
        }

        sBattlegroundMgr->ScheduleQueueUpdate(std::max<uint32>(matchmakerRating, 1), bracket.ArenaType, queueType,
            BATTLEGROUND_AA, bracketEntry->GetBracketId());
    }

    bool RouteRatedPartyJoin(Player* player, uint8 arenaSlot)
    {
        std::optional<uint32> requestBracket = SoloRequestBracketForSlot(arenaSlot);
        if (!requestBracket)
            return false;

        Group* group = player->GetGroup();
        if (group && group->GetLeaderGUID() != player->GetGUID())
            return true;

        if (IsWholePartyInLeaderTeam(player, group, arenaSlot))
            return false;

        if (!group || group->GetMembersCount() == 1)
        {
            JoinRatedSoloQueue(player, RequestWithDeclaredRole(player, *requestBracket));
            return true;
        }

        std::optional<SoloBracket> bracket = SoloBracketFor(*requestBracket);
        if (!IsSoloTeamBracket(bracket->ArenaType))
        {
            for (Player* member : OnlinePartyMembers(group))
                JoinRatedSoloQueue(member, RequestWithDeclaredRole(member, *requestBracket));
            return true;
        }

        JoinRatedPremadeQueue(player, group, *bracket, arenaSlot);
        return true;
    }

    bool IsSoloSystemEntry(GroupQueueInfo const* ginfo, uint8 arenaType, uint32 teamSize)
    {
        return ginfo->IsRated && ginfo->ArenaType == arenaType && !ginfo->Players.empty()
            && ginfo->Players.size() <= teamSize && !ginfo->IsInvitedToBGInstanceGUID;
    }

    uint32 HealerCount(GroupQueueInfo const* ginfo, std::unordered_map<ObjectGuid, bool> const& healers)
    {
        uint32 count = 0;
        for (ObjectGuid const& guid : ginfo->Players)
        {
            auto itr = healers.find(guid);
            if (itr != healers.end() && itr->second)
                ++count;
        }
        return count;
    }

    uint32 PlayerCount(std::vector<GroupQueueInfo*> const& entries)
    {
        uint32 total = 0;
        for (GroupQueueInfo const* ginfo : entries)
            total += uint32(ginfo->Players.size());
        return total;
    }

    struct SoloLineup
    {
        std::array<std::vector<GroupQueueInfo*>, PVP_TEAMS_COUNT> Sides;
    };

    uint32 AverageMatchmakerRating(std::vector<GroupQueueInfo*> const& side)
    {
        uint64 total = 0;
        for (GroupQueueInfo const* ginfo : side)
            total += uint64(ginfo->ArenaMatchmakerRating) * ginfo->Players.size();
        uint32 players = PlayerCount(side);
        return players ? uint32(total / players) : 0;
    }

    uint32 AverageTeamRating(std::vector<GroupQueueInfo*> const& side)
    {
        uint64 total = 0;
        for (GroupQueueInfo const* ginfo : side)
            total += uint64(ginfo->ArenaTeamRating) * ginfo->Players.size();
        uint32 players = PlayerCount(side);
        return players ? uint32(total / players) : 0;
    }

    uint32 RoleBalanceWaitSeconds = 60;
    bool RoleBalance2v2 = false;
    bool RoleBalance3v3 = true;

    bool RoleBalanceRequired(uint8 arenaType)
    {
        switch (arenaType)
        {
            case ARENA_TYPE_2v2:
                return RoleBalance2v2;
            case ARENA_TYPE_3v3:
                return RoleBalance3v3;
            default:
                return false;
        }
    }

    struct LineupCandidate
    {
        GroupQueueInfo* Entry = nullptr;
        uint32 Players = 0;
        uint32 Healers = 0;
        bool Premade = false;
    };

    struct LineupSide
    {
        std::vector<GroupQueueInfo*> Entries;
        uint32 Players = 0;
        uint32 SoloHealers = 0;
        uint32 PremadeHealers = 0;
        uint64 MatchmakerRatingTotal = 0;

        bool CanTake(LineupCandidate const& candidate, uint32 teamSize, bool roleBalanceRelaxed) const
        {
            if (Players + candidate.Players > teamSize)
                return false;

            if (roleBalanceRelaxed)
                return true;

            if (candidate.Premade)
                return candidate.Healers == 0 || SoloHealers == 0;

            return candidate.Healers == 0 || (SoloHealers == 0 && PremadeHealers == 0);
        }

        void Take(LineupCandidate const& candidate)
        {
            Entries.push_back(candidate.Entry);
            Players += candidate.Players;
            (candidate.Premade ? PremadeHealers : SoloHealers) += candidate.Healers;
            MatchmakerRatingTotal += uint64(candidate.Entry->ArenaMatchmakerRating) * candidate.Players;
        }

        void Release(LineupCandidate const& candidate)
        {
            Entries.pop_back();
            Players -= candidate.Players;
            (candidate.Premade ? PremadeHealers : SoloHealers) -= candidate.Healers;
            MatchmakerRatingTotal -= uint64(candidate.Entry->ArenaMatchmakerRating) * candidate.Players;
        }

        bool HasBalancedHealers() const
        {
            return SoloHealers == 0 || (SoloHealers == 1 && PremadeHealers == 0);
        }

        bool HasHealer() const
        {
            return SoloHealers + PremadeHealers > 0;
        }
    };

    struct LineupScore
    {
        bool RoleUnbalanced = false;
        bool WithoutHealers = true;
        uint32 QueueSeniority = 0;
        uint64 RatingGap = 0;

        bool operator<(LineupScore const& other) const
        {
            return std::tie(RoleUnbalanced, WithoutHealers, QueueSeniority, RatingGap)
                < std::tie(other.RoleUnbalanced, other.WithoutHealers, other.QueueSeniority, other.RatingGap);
        }
    };

    struct LineupSearch
    {
        std::vector<LineupCandidate> Pool;
        std::vector<uint32> PlayersFrom;
        uint32 TeamSize = 0;
        bool RoleBalanceRelaxed = false;
        std::array<LineupSide, PVP_TEAMS_COUNT> Sides;
        std::optional<LineupScore> BestScore;
        SoloLineup Best;

        void Consider(uint32 queueSeniority)
        {
            bool roleBalanced = Sides[TEAM_ALLIANCE].HasHealer() == Sides[TEAM_HORDE].HasHealer()
                && Sides[TEAM_ALLIANCE].HasBalancedHealers() && Sides[TEAM_HORDE].HasBalancedHealers();
            if (!roleBalanced && !RoleBalanceRelaxed)
                return;

            uint64 allianceTotal = Sides[TEAM_ALLIANCE].MatchmakerRatingTotal;
            uint64 hordeTotal = Sides[TEAM_HORDE].MatchmakerRatingTotal;
            LineupScore score{ !roleBalanced, !Sides[TEAM_ALLIANCE].HasHealer(), queueSeniority,
                allianceTotal > hordeTotal ? allianceTotal - hordeTotal : hordeTotal - allianceTotal };
            if (BestScore && !(score < *BestScore))
                return;

            BestScore = score;
            for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
                Best.Sides[side] = Sides[side].Entries;
        }

        void Explore(std::size_t next, uint32 queueSeniority)
        {
            uint32 missingPlayers = 2 * TeamSize - Sides[TEAM_ALLIANCE].Players - Sides[TEAM_HORDE].Players;
            if (!missingPlayers)
            {
                Consider(queueSeniority);
                return;
            }

            if (next == Pool.size() || PlayersFrom[next] < missingPlayers)
                return;

            LineupCandidate const& candidate = Pool[next];
            for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
            {
                if ((next == 0 && side != TEAM_ALLIANCE) || !Sides[side].CanTake(candidate, TeamSize, RoleBalanceRelaxed))
                    continue;

                Sides[side].Take(candidate);
                Explore(next + 1, queueSeniority + uint32(next));
                Sides[side].Release(candidate);
            }

            if (next != 0)
                Explore(next + 1, queueSeniority);
        }
    };

    LineupCandidate CandidateFor(GroupQueueInfo* ginfo, std::unordered_map<ObjectGuid, bool> const& healerRoles)
    {
        uint32 players = uint32(ginfo->Players.size());
        return LineupCandidate{ ginfo, players, HealerCount(ginfo, healerRoles), players > 1 };
    }

    std::optional<SoloLineup> ComposeLineup(GroupQueueInfo* anchor, std::vector<GroupQueueInfo*> const& eligible,
        uint32 teamSize, std::unordered_map<ObjectGuid, bool> const& healerRoles, bool roleBalanceRelaxed)
    {
        constexpr uint32 PremadesKeptPerSize = 2;
        uint32 soloHealersKept = roleBalanceRelaxed ? 2 * teamSize : 2;

        LineupSearch search;
        search.TeamSize = teamSize;
        search.RoleBalanceRelaxed = roleBalanceRelaxed;
        search.Pool.push_back(CandidateFor(anchor, healerRoles));

        uint32 soloHealers = 0;
        uint32 soloDamage = 0;
        std::array<uint32, ARENA_TYPE_5v5 + 1> premadesBySize{};
        for (GroupQueueInfo* ginfo : eligible)
        {
            if (ginfo == anchor)
                continue;

            LineupCandidate candidate = CandidateFor(ginfo, healerRoles);
            bool kept = candidate.Premade ? premadesBySize[candidate.Players]++ < PremadesKeptPerSize
                : candidate.Healers ? soloHealers++ < soloHealersKept
                : soloDamage++ < 2 * teamSize;
            if (kept)
                search.Pool.push_back(candidate);
        }

        search.PlayersFrom.assign(search.Pool.size() + 1, 0);
        for (std::size_t i = search.Pool.size(); i-- > 0;)
            search.PlayersFrom[i] = search.PlayersFrom[i + 1] + search.Pool[i].Players;

        search.Explore(0, 0);
        if (!search.BestScore)
            return std::nullopt;

        return search.Best;
    }

    std::optional<SoloLineup> FindLineup(BattlegroundQueue* queue, BattlegroundBracketId bracketId, uint8 arenaType,
        uint32 teamSize)
    {
        std::vector<GroupQueueInfo*> waiting;
        for (uint32 index : { BG_QUEUE_NORMAL_ALLIANCE, BG_QUEUE_NORMAL_HORDE })
            for (GroupQueueInfo* ginfo : queue->m_QueuedGroups[bracketId][index])
                if (IsSoloSystemEntry(ginfo, arenaType, teamSize))
                    waiting.push_back(ginfo);

        if (PlayerCount(waiting) < 2 * teamSize)
            return std::nullopt;

        std::stable_sort(waiting.begin(), waiting.end(), [](GroupQueueInfo const* left, GroupQueueInfo const* right)
        {
            return left->JoinTime < right->JoinTime;
        });

        std::unordered_map<ObjectGuid, bool> healerRoles;
        {
            std::lock_guard<std::mutex> lock(StateLock);
            healerRoles = HealerByPlayer;
        }

        int32 discardTime = int32(GameTime::GetGameTimeMS().count() - sBattlegroundMgr->GetRatingDiscardTimer());
        uint32 maxDifference = sBattlegroundMgr->GetMaxRatingDifference();
        for (GroupQueueInfo* anchor : waiting)
        {
            bool anchorWaitedLong = int32(anchor->JoinTime) < discardTime;
            uint32 minRating = anchor->ArenaMatchmakerRating > maxDifference
                ? anchor->ArenaMatchmakerRating - maxDifference : 0;
            uint32 maxRating = anchor->ArenaMatchmakerRating + maxDifference;

            std::vector<GroupQueueInfo*> eligible;
            for (GroupQueueInfo* ginfo : waiting)
            {
                if (anchorWaitedLong || int32(ginfo->JoinTime) < discardTime
                    || (ginfo->ArenaMatchmakerRating >= minRating && ginfo->ArenaMatchmakerRating <= maxRating))
                    eligible.push_back(ginfo);
            }

            if (PlayerCount(eligible) < 2 * teamSize)
                continue;

            bool roleBalanceRelaxed = !RoleBalanceRequired(arenaType) || (RoleBalanceWaitSeconds
                && getMSTimeDiff(anchor->JoinTime, uint32(GameTime::GetGameTimeMS().count()))
                    > RoleBalanceWaitSeconds * IN_MILLISECONDS);
            if (std::optional<SoloLineup> lineup =
                ComposeLineup(anchor, eligible, teamSize, healerRoles, roleBalanceRelaxed))
                return lineup;
        }

        return std::nullopt;
    }

    uint32 PersonalTeamIdFor(GroupQueueInfo const* ginfo, ObjectGuid guid,
        std::unordered_map<ObjectGuid, uint32> const& personalTeams)
    {
        if (ginfo->Players.size() == 1)
            return ginfo->ArenaTeamId;

        auto itr = personalTeams.find(guid);
        return itr != personalTeams.end() ? itr->second : 0;
    }

    std::string SideTeamName(uint8 arenaType, std::vector<GroupQueueInfo*> const& side)
    {
        bool withPremade = std::any_of(side.begin(), side.end(), [](GroupQueueInfo const* ginfo)
        {
            return ginfo->Players.size() > 1;
        });
        return Acore::StringFormat("{}v{}{}", arenaType, arenaType, withPremade ? "" : " (Solo Queue)");
    }

    bool StartSoloMatch(BattlegroundQueue* queue, BattlegroundBracketId bracketId, uint8 arenaType,
        SoloLineup const& lineup)
    {
        Battleground* arenaTemplate = sBattlegroundMgr->GetBattlegroundTemplate(BATTLEGROUND_AA);
        if (!arenaTemplate)
            return false;

        PvPDifficultyEntry const* bracketEntry = GetBattlegroundBracketById(arenaTemplate->GetMapId(), bracketId);
        if (!bracketEntry)
            return false;

        Battleground* arena = sBattlegroundMgr->CreateNewBattleground(BATTLEGROUND_AA, bracketEntry, arenaType, true);
        if (!arena)
        {
            LOG_ERROR("bg.arena", "Rated solo queue could not create a {}v{} arena", arenaType, arenaType);
            return false;
        }

        std::array<uint32, PVP_TEAMS_COUNT> matchmakerRating{};
        std::array<uint32, PVP_TEAMS_COUNT> teamRating{};
        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
        {
            matchmakerRating[side] = AverageMatchmakerRating(lineup.Sides[side]);
            teamRating[side] = AverageTeamRating(lineup.Sides[side]);
        }

        std::unordered_map<ObjectGuid, uint32> personalTeams;
        {
            std::lock_guard<std::mutex> lock(StateLock);
            personalTeams = QueuedPersonalTeams;
        }

        SoloMatch match;
        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
        {
            TeamId teamId = TeamId(side);
            TeamId opponent = Battleground::GetOtherTeamId(teamId);
            arena->SetArenaMatchmakerRating(teamId, matchmakerRating[side]);
            for (GroupQueueInfo* ginfo : lineup.Sides[side])
            {
                ginfo->OpponentsTeamRating = teamRating[opponent];
                ginfo->OpponentsMatchmakerRating = matchmakerRating[opponent];
                for (ObjectGuid const& guid : ginfo->Players)
                    match.Participants[guid] = SoloParticipant{ PersonalTeamIdFor(ginfo, guid, personalTeams), teamId,
                        false };
                queue->InviteGroupToBG(ginfo, arena, teamId);
            }
        }

        match.MatchmakerRating = matchmakerRating;
        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
            match.Sides[side] = new SoloSideTeam(SideTeamTypeFor(arenaType), SideTeamName(arenaType, lineup.Sides[side]),
                teamRating[side]);
        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
        {
            sArenaTeamMgr->AddArenaTeam(match.Sides[side]);
            arena->SetArenaTeamIdForTeam(TeamId(side), match.Sides[side]->GetId());
        }

        {
            std::lock_guard<std::mutex> lock(StateLock);
            for (auto const& [guid, participant] : match.Participants)
                QueuedPersonalTeams.erase(guid);
            for (SoloSideTeam* sideTeam : match.Sides)
                InstanceBySideTeam[sideTeam->GetId()] = arena->GetInstanceID();
            MatchByInstance[arena->GetInstanceID()] = std::move(match);
        }

        arena->StartBattleground();
        return true;
    }

    void DestroySideTeams(SoloMatch& match)
    {
        for (SoloSideTeam*& sideTeam : match.Sides)
        {
            if (!sideTeam)
                continue;

            InstanceBySideTeam.erase(sideTeam->GetId());
            sArenaTeamMgr->RemoveArenaTeam(sideTeam->GetId());
            delete sideTeam;
            sideTeam = nullptr;
        }
    }

    constexpr uint32 RUNE_OF_ASCENSION_ITEM = 375250;
    constexpr char SeasonConquestSetting[] = "core.rated_solo_conquest";
    constexpr uint32 WORLD_STATE_RATED_SOLO_CONQUEST_SEASON = 20101;
    constexpr uint32 WORLD_STATE_RATED_SOLO_CONQUEST_SEASON_START = 20102;

    enum SeasonConquestField : uint32
    {
        SEASON_CONQUEST_SEASON = 0,
        SEASON_CONQUEST_EARNED = 1
    };

    std::atomic<uint32> ConquestSeason = 0;
    std::atomic<int64> ConquestSeasonStart = 0;

    struct SoloWinRewards
    {
        uint32 ArenaPoints1v1 = 25;
        uint32 ArenaPoints2v2 = 300;
        uint32 ArenaPoints3v3 = 300;
        uint32 RunesOfAscension = 25;
        uint32 ConquestCapPerWeek = 12000;
        uint32 ConquestCapMax = 0;
        uint32 CombatantRating = 1400;
    };

    SoloWinRewards WinRewards;

    struct RatingTitle
    {
        char const* ConfigName;
        uint32 TitleId;
        uint32 DefaultRating;
        uint32 Rating;
    };

    std::array<RatingTitle, 4> RatingTitles{ {
        { "RatedSoloArena.Title.Challenger", 45, 1700, 1700 },
        { "RatedSoloArena.Title.Rival", 44, 2000, 2000 },
        { "RatedSoloArena.Title.Duelist", 43, 2300, 2300 },
        { "RatedSoloArena.Title.Gladiator", 42, 2600, 2600 }
    } };

    void LoadWinRewards()
    {
        WinRewards.ArenaPoints1v1 = sConfigMgr->GetOption<uint32>("RatedSoloArena.Win.ArenaPoints.1v1", 25);
        WinRewards.ArenaPoints2v2 = sConfigMgr->GetOption<uint32>("RatedSoloArena.Win.ArenaPoints.2v2", 300);
        WinRewards.ArenaPoints3v3 = sConfigMgr->GetOption<uint32>("RatedSoloArena.Win.ArenaPoints.3v3", 300);
        WinRewards.RunesOfAscension = sConfigMgr->GetOption<uint32>("RatedSoloArena.Win.RunesOfAscension", 25);
        WinRewards.ConquestCapPerWeek = sConfigMgr->GetOption<uint32>("RatedSoloArena.SeasonCap.PerWeek", 12000);
        WinRewards.ConquestCapMax = sConfigMgr->GetOption<uint32>("RatedSoloArena.SeasonCap.Max", 0);
        WinRewards.CombatantRating = sConfigMgr->GetOption<uint32>("RatedSoloArena.Tier.Combatant", 1400);
        RoleBalanceWaitSeconds = sConfigMgr->GetOption<uint32>("RatedSoloArena.RoleBalanceWaitSeconds", 60);
        RoleBalance2v2 = sConfigMgr->GetOption<bool>("RatedSoloArena.RoleBalance.2v2", false);
        RoleBalance3v3 = sConfigMgr->GetOption<bool>("RatedSoloArena.RoleBalance.3v3", true);
        for (RatingTitle& title : RatingTitles)
            title.Rating = sConfigMgr->GetOption<uint32>(title.ConfigName, title.DefaultRating);
    }

    uint32 WinArenaPointsFor(uint32 teamType)
    {
        switch (teamType)
        {
            case ARENA_TEAM_2v2:
                return WinRewards.ArenaPoints2v2;
            case ARENA_TEAM_3v3:
                return WinRewards.ArenaPoints3v3;
            case ARENA_TEAM_5v5:
                return WinRewards.ArenaPoints1v1;
            default:
                return 0;
        }
    }

    void TrackConquestSeason()
    {
        uint32 season = sArenaSeasonMgr->GetCurrentSeason();
        if (sWorldState->getWorldState(WORLD_STATE_RATED_SOLO_CONQUEST_SEASON) != season
            || !sWorldState->getWorldState(WORLD_STATE_RATED_SOLO_CONQUEST_SEASON_START))
        {
            int64 currentWeekStart = sWorld->GetNextWeeklyQuestsResetTime().count() - int64(WEEK);
            int64 seasonStart = currentWeekStart > 0 ? currentWeekStart : int64(GameTime::GetGameTime().count());
            sWorldState->setWorldState(WORLD_STATE_RATED_SOLO_CONQUEST_SEASON, season);
            sWorldState->setWorldState(WORLD_STATE_RATED_SOLO_CONQUEST_SEASON_START, uint64(seasonStart));
        }

        ConquestSeasonStart = int64(sWorldState->getWorldState(WORLD_STATE_RATED_SOLO_CONQUEST_SEASON_START));
        ConquestSeason = season;
    }

    uint32 ConquestSeasonWeek()
    {
        int64 elapsed = int64(GameTime::GetGameTime().count()) - ConquestSeasonStart;
        return 1 + uint32(std::max<int64>(elapsed, 0) / int64(WEEK));
    }

    uint32 ConquestCap()
    {
        uint64 cap = uint64(WinRewards.ConquestCapPerWeek) * ConquestSeasonWeek();
        if (WinRewards.ConquestCapMax)
            cap = std::min<uint64>(cap, WinRewards.ConquestCapMax);
        return uint32(std::min<uint64>(cap, UINT32_MAX));
    }

    uint32 ConquestEarnedThisSeason(Player* player)
    {
        if (player->GetPlayerSetting(SeasonConquestSetting, SEASON_CONQUEST_SEASON).value != ConquestSeason)
            return 0;

        return player->GetPlayerSetting(SeasonConquestSetting, SEASON_CONQUEST_EARNED).value;
    }

    constexpr uint16 CMSG_ASCENSION_PVP_REWARD_INFO_QUERY = 0x053E;
    constexpr uint16 SMSG_ASCENSION_PVP_REWARD_INFO_QUERY_RESPONSE = 0x0925;

    enum ArenaRewardBracket : uint32
    {
        ARENA_REWARD_BRACKET_NONE = 0,
        ARENA_REWARD_BRACKET_COMBATANT = 1
    };

    std::unordered_set<WorldSession const*> RewardInfoDue;
    std::atomic<bool> AnyRewardInfoDue = false;
    uint32 AnnouncedConquestWeek = 0;
    uint32 AnnouncedConquestSeason = 0;

    uint32 BestSoloPersonalRating(Player* player)
    {
        uint32 best = 0;
        for (uint8 slot = 0; slot < MAX_ARENA_SLOT; ++slot)
            if (ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(player->GetArenaTeamId(slot)))
                if (ArenaTeamMember* member = team->GetMember(player->GetGUID()))
                    best = std::max<uint32>(best, member->PersonalRating);
        return best;
    }

    uint32 ArenaRewardBracketFor(uint32 personalRating)
    {
        if (personalRating < WinRewards.CombatantRating)
            return ARENA_REWARD_BRACKET_NONE;

        uint32 bracket = ARENA_REWARD_BRACKET_COMBATANT;
        for (RatingTitle const& tier : RatingTitles)
            if (personalRating >= tier.Rating)
                ++bracket;
        return bracket;
    }

    void SendArenaRewardInfo(Player* player)
    {
        if (player->GetSession()->IsBot())
            return;

        constexpr uint32 PointsForLoss = 0;
        WorldPacket packet(SMSG_ASCENSION_PVP_REWARD_INFO_QUERY_RESPONSE, 7 * sizeof(uint32));
        packet << uint32(ConquestCap()) << uint32(ConquestEarnedThisSeason(player))
               << uint32(ArenaRewardBracketFor(BestSoloPersonalRating(player))) << PointsForLoss << PointsForLoss
               << uint32(WinRewards.ArenaPoints2v2) << uint32(WinRewards.ArenaPoints1v1);
        player->SendDirectMessage(&packet);
    }

    bool QueueRewardInfoQuery(WorldSession* session, WorldPacket const&)
    {
        if (!session)
            return true;

        std::lock_guard<std::mutex> lock(StateLock);
        RewardInfoDue.insert(session);
        AnyRewardInfoDue = true;
        return true;
    }

    bool TakeRewardInfoDue(WorldSession const* session)
    {
        std::lock_guard<std::mutex> lock(StateLock);
        bool due = RewardInfoDue.erase(session) != 0;
        AnyRewardInfoDue = !RewardInfoDue.empty();
        return due;
    }

    void ScheduleRewardInfoForEveryone()
    {
        std::lock_guard<std::mutex> lock(StateLock);
        for (auto const& [accountId, session] : sWorldSessionMgr->GetAllSessions())
            if (session && !session->IsBot() && session->GetPlayer())
                RewardInfoDue.insert(session);
        AnyRewardInfoDue = !RewardInfoDue.empty();
    }

    void AnnounceConquestCapChanges()
    {
        uint32 week = ConquestSeasonWeek();
        if (week == AnnouncedConquestWeek && ConquestSeason == AnnouncedConquestSeason)
            return;

        bool alreadyAnnounced = AnnouncedConquestWeek != 0;
        AnnouncedConquestWeek = week;
        AnnouncedConquestSeason = ConquestSeason;
        if (alreadyAnnounced)
            ScheduleRewardInfoForEveryone();
    }

    void GrantWinArenaPoints(Player* player, uint32 teamType)
    {
        uint32 earned = ConquestEarnedThisSeason(player);
        uint32 cap = ConquestCap();
        uint32 points = std::min(WinArenaPointsFor(teamType), cap > earned ? cap - earned : 0);
        if (!points)
            return;

        earned += points;
        player->UpdatePlayerSetting(SeasonConquestSetting, SEASON_CONQUEST_SEASON, ConquestSeason);
        player->UpdatePlayerSetting(SeasonConquestSetting, SEASON_CONQUEST_EARNED, earned);
        player->ModifyArenaPoints(int32(points));
        ChatHandler(player->GetSession()).PSendSysMessage(
            "You've received {} Arena Points. Current Points: ({}) Cap: ({}/{})", points, player->GetArenaPoints(),
            earned, cap);
    }

    void GrantWinRewards(Player* player, uint32 teamType)
    {
        GrantWinArenaPoints(player, teamType);
        if (WinRewards.RunesOfAscension)
            player->AddItem(RUNE_OF_ASCENSION_ITEM, WinRewards.RunesOfAscension);
    }

    void GrantRatingTitles(Player* player, uint32 personalRating)
    {
        for (RatingTitle const& tier : RatingTitles)
        {
            if (personalRating < tier.Rating)
                continue;

            CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(tier.TitleId);
            if (!title || player->HasTitle(title))
                continue;

            player->SetTitle(title);
        }
    }

    void UpdateRatingProgress(Player* player, uint32 personalRating)
    {
        GrantRatingTitles(player, personalRating);
        SendArenaRewardInfo(player);
    }

    void SettleSoloDuel(Player* player, bool won)
    {
        if (!player)
            return;

        ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(player->GetArenaTeamId(ArenaTeam::GetSlotByType(ARENA_TEAM_5v5)));
        if (!team)
            return;

        if (won)
            GrantWinRewards(player, ARENA_TEAM_5v5);

        if (ArenaTeamMember* member = team->GetMember(player->GetGUID()))
            UpdateRatingProgress(player, member->PersonalRating);
    }

    void ApplyPersonalResult(Player* player, RatingUpdate const& update, bool won)
    {
        ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(update.PersonalTeamId);
        if (!team)
            return;

        ArenaTeamMember* member = team->GetMember(player->GetGUID());
        if (!member)
            return;

        uint32 ownMatchmakerRating = member->MatchMakerRating;
        int32 ratingChange = 0;
        if (won)
        {
            int32 matchmakerChange = team->WonAgainst(ownMatchmakerRating, update.OpponentMatchmakerRating,
                ratingChange, player->FindMap());
            team->MemberWon(player, update.OpponentMatchmakerRating, matchmakerChange);
        }
        else
        {
            int32 matchmakerChange = team->LostAgainst(ownMatchmakerRating, update.OpponentMatchmakerRating,
                ratingChange, player->FindMap());
            team->MemberLost(player, update.OpponentMatchmakerRating, matchmakerChange);
        }

        team->SaveToDB();
        team->NotifyStatsChanged();

        if (won)
            GrantWinRewards(player, team->GetType());

        if (ArenaTeamMember* updatedMember = team->GetMember(player->GetGUID()))
            UpdateRatingProgress(player, updatedMember->PersonalRating);
    }

    std::optional<RatingUpdate> SettleParticipant(SoloMatch& match, ObjectGuid guid)
    {
        auto itr = match.Participants.find(guid);
        if (itr == match.Participants.end() || itr->second.Settled)
            return std::nullopt;

        itr->second.Settled = true;
        TeamId opponent = Battleground::GetOtherTeamId(itr->second.Side);
        return RatingUpdate{ itr->second.PersonalTeamId, match.MatchmakerRating[opponent] };
    }

    struct PersonalRatingOutcome
    {
        int32 RatingChange = 0;
        uint32 MatchmakerRating = 0;
    };

    std::optional<PersonalRatingOutcome> ForecastPersonalOutcome(SoloMatch const& match, ObjectGuid guid,
        SoloParticipant const& participant, bool won)
    {
        ArenaTeam* team = sArenaTeamMgr->GetArenaTeamById(participant.PersonalTeamId);
        ArenaTeamMember* member = team ? team->GetMember(guid) : nullptr;
        if (!member)
            return std::nullopt;

        uint32 opponentMatchmakerRating = match.MatchmakerRating[Battleground::GetOtherTeamId(participant.Side)];
        int32 change = team->GetRatingMod(member->PersonalRating, opponentMatchmakerRating, won);
        return PersonalRatingOutcome{ std::max<int32>(change, -int32(member->PersonalRating)),
            member->MatchMakerRating };
    }

    std::optional<int32> AveragePersonalRatingChange(Battleground* bg, SoloMatch const& match, TeamId side, bool won)
    {
        int64 total = 0;
        uint32 counted = 0;
        for (auto const& [guid, participant] : match.Participants)
        {
            if (participant.Side != side || participant.Settled)
                continue;

            std::optional<PersonalRatingOutcome> outcome = ForecastPersonalOutcome(match, guid, participant, won);
            if (!outcome)
                continue;

            bg->SetArenaPersonalScore(guid, side, outcome->RatingChange, outcome->MatchmakerRating);
            total += outcome->RatingChange;
            ++counted;
        }

        if (!counted)
            return std::nullopt;

        return int32(total / int64(counted));
    }

    std::optional<TeamId> LosingSide(SoloMatch const& match)
    {
        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
        {
            ArenaTeamStats const& stats = match.Sides[side]->GetStats();
            if (stats.SeasonGames && !stats.SeasonWins)
                return TeamId(side);
        }
        return std::nullopt;
    }

    class AscensionArenaQueueScoreboard final : public FormulaScript
    {
    public:
        AscensionArenaQueueScoreboard()
            : FormulaScript("AscensionArenaQueueScoreboard", { FORMULAHOOK_ON_AFTER_ARENA_RATING_CALCULATION }) { }

        void OnAfterArenaRatingCalculation(Battleground* const bg, int32&, int32&, int32& winnerChange,
            int32& loserChange) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            auto itr = MatchByInstance.find(bg->GetInstanceID());
            if (itr == MatchByInstance.end())
                return;

            std::optional<TeamId> loser = LosingSide(itr->second);
            if (!loser)
                return;

            if (std::optional<int32> change =
                AveragePersonalRatingChange(bg, itr->second, Battleground::GetOtherTeamId(*loser), true))
                winnerChange = *change;
            if (std::optional<int32> change = AveragePersonalRatingChange(bg, itr->second, *loser, false))
                loserChange = *change;
        }
    };

    class AscensionArenaQueueWorld final : public WorldScript
    {
    public:
        AscensionArenaQueueWorld()
            : WorldScript("AscensionArenaQueueWorld", {
                WORLDHOOK_ON_AFTER_CONFIG_LOAD,
                WORLDHOOK_ON_STARTUP,
                WORLDHOOK_ON_UPDATE,
                WORLDHOOK_ON_SHUTDOWN
            }) { }

        void OnAfterConfigLoad(bool) override
        {
            LoadWinRewards();
        }

        void OnStartup() override
        {
            LoadWinRewards();
            TrackConquestSeason();
        }

        void OnUpdate(uint32) override
        {
            if (sArenaSeasonMgr->GetCurrentSeason() != ConquestSeason)
                TrackConquestSeason();
            AnnounceConquestCapChanges();

            std::unordered_map<ObjectGuid, ArenaRequest> requests;
            {
                std::lock_guard<std::mutex> lock(StateLock);
                if (ReadyRequests.empty())
                    return;
                requests.swap(ReadyRequests);
            }

            for (auto const& [guid, request] : requests)
                if (Player* player = ObjectAccessor::FindPlayer(guid))
                    JoinRatedSoloQueue(player, request);
        }

        void OnShutdown() override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            for (auto& [instanceId, match] : MatchByInstance)
                DestroySideTeams(match);
            MatchByInstance.clear();
        }
    };

    class AscensionArenaQueuePlayer final : public PlayerScript
    {
    public:
        AscensionArenaQueuePlayer()
            : PlayerScript("AscensionArenaQueuePlayer", {
                PLAYERHOOK_ON_LOGIN,
                PLAYERHOOK_ON_LOGOUT,
                PLAYERHOOK_ON_UPDATE,
                PLAYERHOOK_CAN_JOIN_IN_ARENA_QUEUE
            }) { }

        void OnPlayerLogout(Player* player) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            PendingRequests.erase(player->GetSession());
            AnyPending = !PendingRequests.empty();
            ReadyRequests.erase(player->GetGUID());
            RewardInfoDue.erase(player->GetSession());
            AnyRewardInfoDue = !RewardInfoDue.empty();
            HealerByPlayer.erase(player->GetGUID());
            QueuedPersonalTeams.erase(player->GetGUID());
        }

        void OnPlayerLogin(Player* player) override
        {
            SendArenaRewardInfo(player);
        }

        void OnPlayerUpdate(Player* player, uint32) override
        {
            if (AnyRewardInfoDue && TakeRewardInfoDue(player->GetSession()))
                SendArenaRewardInfo(player);

            if (!AnyPending)
                return;

            std::lock_guard<std::mutex> lock(StateLock);
            auto itr = PendingRequests.find(player->GetSession());
            if (itr == PendingRequests.end())
                return;

            ReadyRequests[player->GetGUID()] = itr->second;
            PendingRequests.erase(itr);
            AnyPending = !PendingRequests.empty();
        }

        bool OnPlayerCanJoinInArenaQueue(Player* player, ObjectGuid, uint8 arenaSlot, BattlegroundTypeId bgTypeId,
            uint8 joinAsGroup, uint8 isRated, GroupJoinBattlegroundResult& err) override
        {
            if (!isRated || !joinAsGroup || bgTypeId != BATTLEGROUND_AA || !RouteRatedPartyJoin(player, arenaSlot))
                return true;

            err = ERR_BATTLEGROUND_NONE;
            return false;
        }
    };

    class AscensionArenaQueueMatchmaker final : public AllBattlegroundScript
    {
    public:
        AscensionArenaQueueMatchmaker() : AllBattlegroundScript("AscensionArenaQueueMatchmaker", {
            ALLBATTLEGROUNDHOOK_ON_ADD_GROUP,
            ALLBATTLEGROUNDHOOK_ON_QUEUE_UPDATE,
            ALLBATTLEGROUNDHOOK_CAN_ADD_GROUP_TO_MATCHING_POOL,
            ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_REMOVE_PLAYER_AT_LEAVE,
            ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_END,
            ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_DESTROY
        }) { }

        void OnAddGroup(BattlegroundQueue*, GroupQueueInfo* ginfo, uint32& index, Player*, Group*,
            BattlegroundTypeId bgTypeId, PvPDifficultyEntry const*, uint8 arenaType, bool isRated, bool, uint32, uint32,
            uint32 arenaTeamId, uint32) override
        {
            if (isRated && bgTypeId == BATTLEGROUND_AA && IsSoloMatchedBracket(arenaType) && IsPersonalTeam(arenaTeamId))
                index = ginfo->teamId == TEAM_HORDE ? BG_QUEUE_NORMAL_HORDE : BG_QUEUE_NORMAL_ALLIANCE;
        }

        void OnQueueUpdate(BattlegroundQueue* queue, uint32, BattlegroundTypeId bgTypeId,
            BattlegroundBracketId bracketId, uint8 arenaType, bool isRated, uint32) override
        {
            if (!isRated || bgTypeId != BATTLEGROUND_AA || !IsSoloMatchedBracket(arenaType))
                return;

            uint32 teamSize = sBattlegroundMgr->isArenaTesting() ? 1 : arenaType;
            while (std::optional<SoloLineup> lineup = FindLineup(queue, bracketId, arenaType, teamSize))
                if (!StartSoloMatch(queue, bracketId, arenaType, *lineup))
                    return;
        }

        bool CanAddGroupToMatchingPool(BattlegroundQueue*, GroupQueueInfo* ginfo, uint32, Battleground*,
            BattlegroundBracketId) override
        {
            return !ginfo->IsRated;
        }

        void OnBattlegroundRemovePlayerAtLeave(Battleground* bg, Player* player) override
        {
            std::optional<RatingUpdate> update;
            {
                std::lock_guard<std::mutex> lock(StateLock);
                auto itr = MatchByInstance.find(bg->GetInstanceID());
                if (itr == MatchByInstance.end() || !itr->second.Started)
                    return;
                update = SettleParticipant(itr->second, player->GetGUID());
            }

            if (update)
                ApplyPersonalResult(player, *update, false);
        }

        void OnBattlegroundEnd(Battleground* bg, TeamId winnerTeamId) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            auto itr = MatchByInstance.find(bg->GetInstanceID());
            if (itr == MatchByInstance.end())
            {
                if (bg->isArena() && bg->isRated() && bg->GetArenaType() == ARENA_TYPE_1v1)
                    for (auto const& [guid, player] : bg->GetPlayers())
                        SettleSoloDuel(player, player->GetBgTeamId() == winnerTeamId);
                return;
            }

            for (auto const& [guid, player] : bg->GetPlayers())
                SettleParticipant(itr->second, guid);
        }

        void OnBattlegroundDestroy(Battleground* bg) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            auto itr = MatchByInstance.find(bg->GetInstanceID());
            if (itr == MatchByInstance.end())
                return;

            DestroySideTeams(itr->second);
            MatchByInstance.erase(itr);
        }
    };

    class AscensionArenaQueueRating final : public ArenaScript
    {
    public:
        AscensionArenaQueueRating() : ArenaScript("AscensionArenaQueueRating", {
            ARENAHOOK_CAN_SAVE_TO_DB,
            ARENAHOOK_ON_ARENA_START,
            ARENAHOOK_ON_BEFORE_TEAM_MEMBER_UPDATE
        }) { }

        bool CanSaveToDB(ArenaTeam* team) override
        {
            return team->GetId() < MAX_ARENA_TEAM_ID;
        }

        void OnArenaStart(Battleground* bg) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            auto itr = MatchByInstance.find(bg->GetInstanceID());
            if (itr != MatchByInstance.end())
                itr->second.Started = true;
        }

        bool OnBeforeArenaTeamMemberUpdate(ArenaTeam* team, Player* player, bool won, uint32, int32) override
        {
            if (team->GetId() < MAX_ARENA_TEAM_ID)
                return true;

            std::optional<RatingUpdate> update;
            {
                std::lock_guard<std::mutex> lock(StateLock);
                auto instance = InstanceBySideTeam.find(team->GetId());
                if (instance == InstanceBySideTeam.end())
                    return false;

                auto itr = MatchByInstance.find(instance->second);
                if (itr == MatchByInstance.end())
                    return false;

                for (SoloSideTeam* sideTeam : itr->second.Sides)
                    sideTeam->ClearStats();
                update = SettleParticipant(itr->second, player->GetGUID());
            }

            if (update)
                ApplyPersonalResult(player, *update, won);
            return false;
        }
    };
}

void AddAscensionArenaQueueScripts()
{
    AscensionCompatOpcodes::Claim(CMSG_BATTLEMASTER_JOIN_ARENA_WITH_ROLE, &QueueRequest);
    AscensionCompatOpcodes::Claim(CMSG_ASCENSION_PVP_REWARD_INFO_QUERY, &QueueRewardInfoQuery);
    new AscensionArenaQueueWorld();
    new AscensionArenaQueuePlayer();
    new AscensionArenaQueueMatchmaker();
    new AscensionArenaQueueRating();
    new AscensionArenaQueueScoreboard();
}
