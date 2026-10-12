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
#include "DBCStores.h"
#include "DisableMgr.h"
#include "GameTime.h"
#include "LFGMgr.h"
#include "Language.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"
#include <algorithm>
#include <array>
#include <bit>
#include <mutex>
#include <optional>
#include <unordered_map>
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
    std::unordered_map<uint32, ArenaRequest> PendingRequests;
    std::unordered_map<ObjectGuid, bool> HealerByPlayer;
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
        PendingRequests[session->GetAccountId()] = request;
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
        sBattlegroundMgr->ScheduleQueueUpdate(std::max<uint32>(matchmakerRating, 1), bracket->ArenaType, queueType,
            BATTLEGROUND_AA, bracketEntry->GetBracketId());
    }

    bool IsSoloQueueEntry(GroupQueueInfo const* ginfo, uint8 arenaType)
    {
        return ginfo->IsRated && ginfo->ArenaType == arenaType && ginfo->Players.size() == 1
            && !ginfo->IsInvitedToBGInstanceGUID;
    }

    bool IsHealer(GroupQueueInfo const* ginfo, std::unordered_map<ObjectGuid, bool> const& healers)
    {
        auto itr = healers.find(*ginfo->Players.begin());
        return itr != healers.end() && itr->second;
    }

    struct SoloLineup
    {
        std::array<std::vector<GroupQueueInfo*>, PVP_TEAMS_COUNT> Sides;
    };

    uint32 AverageMatchmakerRating(std::vector<GroupQueueInfo*> const& side)
    {
        uint64 total = 0;
        for (GroupQueueInfo const* ginfo : side)
            total += ginfo->ArenaMatchmakerRating;
        return side.empty() ? 0 : uint32(total / side.size());
    }

    uint32 AverageTeamRating(std::vector<GroupQueueInfo*> const& side)
    {
        uint64 total = 0;
        for (GroupQueueInfo const* ginfo : side)
            total += ginfo->ArenaTeamRating;
        return side.empty() ? 0 : uint32(total / side.size());
    }

    SoloLineup BalanceLineup(std::vector<GroupQueueInfo*> const& healers, std::vector<GroupQueueInfo*> const& damage,
        uint32 teamSize)
    {
        uint32 damagePerSide = teamSize - (healers.empty() ? 0 : 1);
        uint32 bestMask = 0;
        uint64 bestGap = UINT64_MAX;
        for (uint32 mask = 0; mask < (1u << damage.size()); ++mask)
        {
            if (uint32(std::popcount(mask)) != damagePerSide)
                continue;

            SoloLineup lineup;
            for (std::size_t i = 0; i < healers.size(); ++i)
                lineup.Sides[i].push_back(healers[i]);
            for (std::size_t i = 0; i < damage.size(); ++i)
                lineup.Sides[(mask >> i) & 1 ? TEAM_ALLIANCE : TEAM_HORDE].push_back(damage[i]);

            int64 gap = int64(AverageMatchmakerRating(lineup.Sides[TEAM_ALLIANCE]))
                - int64(AverageMatchmakerRating(lineup.Sides[TEAM_HORDE]));
            uint64 absoluteGap = uint64(gap < 0 ? -gap : gap);
            if (absoluteGap < bestGap)
            {
                bestGap = absoluteGap;
                bestMask = mask;
            }
        }

        SoloLineup lineup;
        for (std::size_t i = 0; i < healers.size(); ++i)
            lineup.Sides[i].push_back(healers[i]);
        for (std::size_t i = 0; i < damage.size(); ++i)
            lineup.Sides[(bestMask >> i) & 1 ? TEAM_ALLIANCE : TEAM_HORDE].push_back(damage[i]);
        return lineup;
    }

    std::optional<SoloLineup> ComposeLineup(GroupQueueInfo* anchor, std::vector<GroupQueueInfo*> const& eligible,
        uint32 teamSize, std::unordered_map<ObjectGuid, bool> const& healerRoles)
    {
        std::vector<GroupQueueInfo*> healers;
        std::vector<GroupQueueInfo*> damage;
        bool anchorIsHealer = IsHealer(anchor, healerRoles);
        (anchorIsHealer ? healers : damage).push_back(anchor);
        for (GroupQueueInfo* ginfo : eligible)
        {
            if (ginfo != anchor)
                (IsHealer(ginfo, healerRoles) ? healers : damage).push_back(ginfo);
        }

        if (healers.size() >= 2 && damage.size() >= 2 * teamSize - 2)
        {
            healers.resize(2);
            damage.resize(2 * teamSize - 2);
            return BalanceLineup(healers, damage, teamSize);
        }

        if (!anchorIsHealer && damage.size() >= 2 * teamSize)
        {
            damage.resize(2 * teamSize);
            return BalanceLineup({}, damage, teamSize);
        }

        return std::nullopt;
    }

    std::optional<SoloLineup> FindLineup(BattlegroundQueue* queue, BattlegroundBracketId bracketId, uint8 arenaType,
        uint32 teamSize)
    {
        std::vector<GroupQueueInfo*> waiting;
        for (uint32 index : { BG_QUEUE_NORMAL_ALLIANCE, BG_QUEUE_NORMAL_HORDE })
            for (GroupQueueInfo* ginfo : queue->m_QueuedGroups[bracketId][index])
                if (IsSoloQueueEntry(ginfo, arenaType))
                    waiting.push_back(ginfo);

        if (waiting.size() < 2 * teamSize)
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

            if (eligible.size() < 2 * teamSize)
                continue;

            if (std::optional<SoloLineup> lineup = ComposeLineup(anchor, eligible, teamSize, healerRoles))
                return lineup;
        }

        return std::nullopt;
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
                match.Participants[*ginfo->Players.begin()] = SoloParticipant{ ginfo->ArenaTeamId, teamId, false };
                queue->InviteGroupToBG(ginfo, arena, teamId);
            }
        }

        match.MatchmakerRating = matchmakerRating;
        match.Sides[TEAM_ALLIANCE] = new SoloSideTeam(arenaType, "Gold Team", teamRating[TEAM_ALLIANCE]);
        match.Sides[TEAM_HORDE] = new SoloSideTeam(arenaType, "Green Team", teamRating[TEAM_HORDE]);
        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
        {
            sArenaTeamMgr->AddArenaTeam(match.Sides[side]);
            arena->SetArenaTeamIdForTeam(TeamId(side), match.Sides[side]->GetId());
        }

        {
            std::lock_guard<std::mutex> lock(StateLock);
            for (auto const& [guid, participant] : match.Participants)
                HealerByPlayer.erase(guid);
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

    class AscensionArenaQueueWorld final : public WorldScript
    {
    public:
        AscensionArenaQueueWorld()
            : WorldScript("AscensionArenaQueueWorld", { WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_SHUTDOWN }) { }

        void OnUpdate(uint32) override
        {
            std::unordered_map<uint32, ArenaRequest> requests;
            {
                std::lock_guard<std::mutex> lock(StateLock);
                if (PendingRequests.empty())
                    return;
                requests.swap(PendingRequests);
            }

            for (auto const& [accountId, request] : requests)
            {
                WorldSession* session = sWorldSessionMgr->FindSession(accountId);
                Player* player = session ? session->GetPlayer() : nullptr;
                if (player && player->IsInWorld())
                    JoinRatedSoloQueue(player, request);
            }
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
        AscensionArenaQueuePlayer() : PlayerScript("AscensionArenaQueuePlayer", { PLAYERHOOK_ON_LOGOUT }) { }

        void OnPlayerLogout(Player* player) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            PendingRequests.erase(player->GetSession()->GetAccountId());
            HealerByPlayer.erase(player->GetGUID());
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

        void OnAddGroup(BattlegroundQueue*, GroupQueueInfo* ginfo, uint32& index, Player*, Group* group,
            BattlegroundTypeId bgTypeId, PvPDifficultyEntry const*, uint8 arenaType, bool isRated, bool, uint32, uint32,
            uint32, uint32) override
        {
            if (isRated && !group && bgTypeId == BATTLEGROUND_AA && IsSoloTeamBracket(arenaType))
                index = ginfo->teamId == TEAM_HORDE ? BG_QUEUE_NORMAL_HORDE : BG_QUEUE_NORMAL_ALLIANCE;
        }

        void OnQueueUpdate(BattlegroundQueue* queue, uint32, BattlegroundTypeId bgTypeId,
            BattlegroundBracketId bracketId, uint8 arenaType, bool isRated, uint32) override
        {
            if (!isRated || bgTypeId != BATTLEGROUND_AA || !IsSoloTeamBracket(arenaType))
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

        void OnBattlegroundEnd(Battleground* bg, TeamId) override
        {
            std::lock_guard<std::mutex> lock(StateLock);
            auto itr = MatchByInstance.find(bg->GetInstanceID());
            if (itr == MatchByInstance.end())
                return;

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
    new AscensionArenaQueueWorld();
    new AscensionArenaQueuePlayer();
    new AscensionArenaQueueMatchmaker();
    new AscensionArenaQueueRating();
}
