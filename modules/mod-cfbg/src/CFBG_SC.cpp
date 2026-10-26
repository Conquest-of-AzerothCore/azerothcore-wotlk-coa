/*
 *  Copyright (С) since 2019 Andrei Guluaev (Winfidonarleyan/Kargatum) https://github.com/Winfidonarleyan
 *  Copyright (С) since 2019+ AzerothCore <www.azerothcore.org>
 */

#include "CFBG.h"
#include "Battlefield.h"
#include "BattlefieldMgr.h"
#include "Chat.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include "BattlegroundQueue.h"

// CFBG custom script
class CFBG_BG : public BGScript
{
public:
    CFBG_BG() : BGScript("CFBG_BG", {
        ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_BEFORE_ADD_PLAYER,
        ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_ADD_PLAYER,
        ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_START,
        ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_REMOVE_PLAYER_AT_LEAVE,
        ALLBATTLEGROUNDHOOK_ON_ADD_GROUP,
        ALLBATTLEGROUNDHOOK_CAN_FILL_PLAYERS_TO_BG,
        ALLBATTLEGROUNDHOOK_IS_CHECK_NORMAL_MATCH,
        ALLBATTLEGROUNDHOOK_CAN_SEND_MESSAGE_BG_QUEUE
    }) {}

    void OnBattlegroundBeforeAddPlayer(Battleground* bg, Player* player) override
    {
        sCFBG->ValidatePlayerForBG(bg, player);
    }

    void OnBattlegroundStart(Battleground* bg) override
    {
        sCFBG->BalanceTeamsAtStart(bg);
    }

    void OnBattlegroundAddPlayer(Battleground* bg, Player* player) override
    {
        sCFBG->FitPlayerInTeam(player, bg);

        if (sCFBG->IsEnableResetCooldowns())
            player->RemoveArenaSpellCooldowns(true);
    }

    void OnBattlegroundRemovePlayerAtLeave(Battleground* bg, Player* player) override
    {
        if (!sCFBG->IsEnableSystem() || bg->isArena())
            return;

        if (sCFBG->IsPlayerFake(player))
            sCFBG->ClearFakePlayer(player);
    }

    void OnAddGroup(BattlegroundQueue* queue, GroupQueueInfo* ginfo, uint32& index, Player* /*leader*/, Group* /*group*/, BattlegroundTypeId /* bgTypeId */, PvPDifficultyEntry const* /* bracketEntry */,
        uint8 /* arenaType */, bool /* isRated */, bool /* isPremade */, uint32 /* arenaRating */, uint32 /* matchmakerRating */, uint32 /* arenaTeamId */, uint32 /* opponentsArenaTeamId */) override
    {
        if (!queue)
            return;

        if (sCFBG->IsEnableSystem() && !ginfo->ArenaType && !ginfo->IsRated)
            index = BG_QUEUE_CFBG;
    }

    bool CanFillPlayersToBG(BattlegroundQueue* queue, Battleground* bg, BattlegroundBracketId bracket_id) override
    {
        return !sCFBG->FillPlayersToCFBG(queue, bg, bracket_id);
    }

    bool IsCheckNormalMatch(BattlegroundQueue* queue, Battleground* bg, BattlegroundBracketId bracket_id, uint32 minPlayers, uint32 maxPlayers) override
    {
        if (!sCFBG->IsEnableSystem() || bg->isArena())
            return false;

        return sCFBG->CheckCrossFactionMatch(queue, bracket_id, minPlayers, maxPlayers);
    }

    bool CanSendMessageBGQueue(BattlegroundQueue* queue, Player* leader, Battleground* bg, PvPDifficultyEntry const* bracketEntry) override
    {
        if (bg->isArena() || !sCFBG->IsEnableSystem())
        {
            // if it's arena OR the CFBG is disabled, let the core handle the announcement
            return true;
        }

        // otherwise, let the CFBG module handle the announcement
        sCFBG->SendMessageQueue(queue, bg, bracketEntry, leader);
        return false;
    }
};

class CFBG_Player : public PlayerScript
{
public:
    CFBG_Player() : PlayerScript("CFBG_Player", {
        PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_LOGOUT,
        PLAYERHOOK_ON_UPDATE_ZONE,
        PLAYERHOOK_ON_UPDATE_FACTION,
        PLAYERHOOK_CAN_JOIN_IN_BATTLEGROUND_QUEUE,
        PLAYERHOOK_ON_BEFORE_UPDATE,
        PLAYERHOOK_ON_BEFORE_SEND_CHAT_MESSAGE,
        PLAYERHOOK_ON_REPUTATION_CHANGE,
        PLAYERHOOK_ON_PLAYER_RESURRECT
    }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!sCFBG->IsEnableSystem())
            return;

        if (player->GetTeamId(true) != player->GetBgTeamId())
            sCFBG->FitPlayerInTeam(player, player->GetBattleground());
    }

    void OnPlayerLogout(Player* player) override
    {
        if (!sCFBG->IsEnableSystem() || !sCFBG->IsPlayerFake(player))
            return;

        // Only WG fakes are handled here; BG fakes are owned by
        // OnBattlegroundRemovePlayerAtLeave. Outside a war, fully restore.
        // During a running war, only drop the Player*-keyed record: relog
        // constructs a new Player*, so the entry can never serve the rejoin
        // (Battlefield::TryRejoinAfterLogout re-fakes via the GUID-keyed
        // _wgWarAssignmentStore) and would dangle. Restoring race/faction here
        // would flip m_team before Player::RemoveFromWorld and mis-key core's
        // PlayersInWar erase.
        Battlefield* bf = sBattlefieldMgr->GetBattlefieldToZoneId(player->GetZoneId());
        if (bf && bf->GetTypeId() == BATTLEFIELD_WG)
        {
            if (!bf->IsWarTime())
                sCFBG->ClearFakePlayer(player);
            else
                sCFBG->DropFakePlayerRecord(player);
        }
    }

    // Fires after Player::UpdateZone has finished all Battlefield/OutdoorPvP/WorldState
    // leave+enter calls. This is where we restore a WG fake player's real faction:
    // doing it earlier (in OnBattlefieldPlayerLeaveZone) flips m_team before core's
    // Battlefield::HandlePlayerLeaveZone runs, which erases PlayersInWar using the
    // (now wrong) team and orphans the assigned-team entry.
    void OnPlayerUpdateZone(Player* player, uint32 newZone, uint32 /*newArea*/) override
    {
        if (!sCFBG->IsEnableSystem() || !sCFBG->IsEnableWGSystem())
            return;

        if (!sCFBG->IsPlayerFake(player))
            return;

        // Battleground fakes are owned by the BG hook OnBattlegroundRemovePlayerAtLeave,
        // not this WG cleanup. A battleground zone is not a WG battlefield, so without
        // this guard entering a BG would clear a cross-faction player's fake right after
        // the entry morph (Battleground::AddPlayer runs before UpdateZone), leaving
        // GetTeamId() on the real faction while bgTeamId stays on the assigned side --
        // the flag-capture/win desync. WG players are not InBattleground().
        if (player->InBattleground())
            return;

        Battlefield* bf = sBattlefieldMgr->GetBattlefieldToZoneId(newZone);
        if (!bf || bf->GetTypeId() != BATTLEFIELD_WG)
            sCFBG->ClearFakePlayer(player);
    }

    // Core's Player::SetFactionForRace resets m_team to the real race, then
    // applies the real faction template only when m_team matches that race --
    // this hook is the designed cooperation point. Keep m_team on the fake side
    // so a faked BG player's assigned faction survives core faction resets (a
    // stray or redundant .gm off would otherwise revert nameplate/hostility/team
    // until the next resurrect).
    void OnPlayerUpdateFaction(Player* player) override
    {
        if (!sCFBG->IsEnableSystem() || !player->InBattleground())
            return;

        if (FakePlayer const* fake = sCFBG->GetFakePlayer(player))
            if (player->GetTeamId() != fake->FakeTeamID)
                player->setTeamId(fake->FakeTeamID);
    }

    bool OnPlayerCanJoinInBattlegroundQueue(Player* player, ObjectGuid /*BattlemasterGuid*/ , BattlegroundTypeId /*BGTypeID*/, uint8 joinAsGroup, GroupJoinBattlegroundResult& err) override
    {
        if (!sCFBG->IsEnableSystem())
            return true;

        if (joinAsGroup)
        {
            Group* group = player->GetGroup();
            if (!group)
                return true;

            if (group->isRaidGroup() || group->GetMembersCount() > sCFBG->GetMaxPlayersCountInGroup())
            {
                // The client shows only a generic "Join as a group failed.";
                // name the actual limit so the leader knows what to change.
                ChatHandler(player->GetSession()).PSendSysMessage("Battleground groups are limited to {} players.", sCFBG->GetMaxPlayersCountInGroup());
                err = ERR_BATTLEGROUND_JOIN_FAILED;
            }

            return false;
        }

        return true;
    }

    void OnPlayerBeforeUpdate(Player* player, uint32 /*diff*/) override
    {
        // The flag is set once per BG add (or login into a BG) and cleared
        // after service, so serving it on the next tick self-rate-limits.
        if (sCFBG->HasPendingForget(player))
            sCFBG->UpdateForget(player);
    }

    void OnPlayerBeforeSendChatMessage(Player* player, uint32& type, uint32& lang, std::string& /*msg*/) override
    {
        if (!player || !sCFBG->IsEnableSystem())
            return;

        Battleground* bg = player->GetBattleground();

        if (!bg || bg->isArena())
            return;

        // skip addon lang and universal
        if (lang == LANG_UNIVERSAL || lang == LANG_ADDON)
            return;

        // skip addon and system message
        if (type == CHAT_MSG_ADDON || type == CHAT_MSG_SYSTEM)
            return;

        // keep proximity chat in the native language so enemies get
        // the normal cross-faction scramble instead of readable text
        if (type == CHAT_MSG_SAY || type == CHAT_MSG_YELL)
            return;

        // to gm lang
        lang = LANG_UNIVERSAL;
    }

    void OnPlayerResurrect(Player* player, float /*restorePercent*/, bool& /*applySickness*/) override
    {
        if (!sCFBG->IsEnableSystem())
            return;

        // Battleground fakes are not re-pushed elsewhere on resurrect;
        // re-assert assigned-team consistency after the ghost->alive transition.
        if (player->InBattleground())
        {
            sCFBG->EnforceBGTeamConsistency(player);
            return;
        }

        if (!sCFBG->IsEnableWGSystem() || !sCFBG->IsEnableWGReapplyOnResurrect())
            return;

        if (!sCFBG->IsPlayerFake(player))
            return;

        // Only re-apply for WG fakes. Battleground fakes are owned by the BG
        // hooks and must not be touched here.
        Battlefield* bf = sBattlefieldMgr->GetBattlefieldToZoneId(player->GetZoneId());
        if (!bf || bf->GetTypeId() != BATTLEFIELD_WG)
            return;

        sCFBG->ReapplyFakePlayer(player);
    }

    bool OnPlayerReputationChange(Player* player, uint32 factionID, int32& standing, bool /*incremental*/) override
    {
        if (!sCFBG->IsEnableSystem())
            return true;

        TeamId teamId = player->GetTeamId(true);

        if ((factionID == FACTION_FROSTWOLF_CLAN && teamId == TEAM_ALLIANCE) ||
            (factionID == FACTION_STORMPIKE_GUARD && teamId == TEAM_HORDE))
        {
            // Signed arithmetic: a reputation LOSS must arrive as a negative
            // delta; an unsigned difference would wrap and slam the mirror
            // faction to the reputation floor.
            int32 current = player->GetReputationMgr().GetReputation(sFactionStore.LookupEntry(factionID));
            int32 diff = standing - current;
            player->GetReputationMgr().ModifyReputation(sFactionStore.LookupEntry(teamId == TEAM_ALLIANCE ? FACTION_STORMPIKE_GUARD : FACTION_FROSTWOLF_CLAN), diff);
            return false;
        }

        return true;
    }
};

// WG constants duplicated here to avoid pulling in BattlefieldWG.h
static constexpr uint32 WG_SPELL_LIEUTENANT            = 55629;
static constexpr uint32 WG_NPC_QUEST_PVP_KILL_ALLIANCE = 31086;
static constexpr uint32 WG_NPC_QUEST_PVP_KILL_HORDE    = 39019;
static constexpr uint32 WG_QUEST_VICTORY_ALLIANCE      = 13181;
static constexpr uint32 WG_QUEST_VICTORY_HORDE         = 13183;

class CFBG_Battlefield : public BattlefieldScript
{
public:
    CFBG_Battlefield() : BattlefieldScript("CFBG_Battlefield", {
        BATTLEFIELDHOOK_ON_PLAYER_ENTER_ZONE,
        BATTLEFIELDHOOK_ON_PLAYER_JOIN_WAR,
        BATTLEFIELDHOOK_ON_WAR_END,
        BATTLEFIELDHOOK_ON_PLAYER_KILL
    }) {}

    // Core fires this before any team-keyed container is consulted (war vacancy
    // gate, kick/invite bookings, Players[] insert all key on GetTeamId()).
    // Re-faking a war-locked flipped player here makes those key on the
    // assigned side; otherwise a returning player is judged on his real team,
    // risking a wrongful 10s "battlefield full" kick and side overfill.
    void OnBattlefieldPlayerEnterZone(Battlefield* bf, Player* player) override
    {
        if (!sCFBG->IsEnableSystem() || !sCFBG->IsEnableWGSystem())
            return;

        if (bf->GetTypeId() != BATTLEFIELD_WG)
            return;

        if (!bf->IsWarTime() || !sCFBG->IsEnableWGTeamLock())
            return;

        if (sCFBG->IsPlayerFake(player))
            return;

        // Skip-class players normally have no stored assignment; the guard also
        // covers a lock stored before a mid-war SkipClasses reload.
        if (sCFBG->IsWGSkipClass(player->getClass()))
            return;

        std::optional<TeamId> locked = sCFBG->GetWGWarAssignment(player->GetGUID());
        if (locked && *locked != player->GetTeamId(true))
            sCFBG->SetFakeRaceAndMorphForBF(player, *locked);
    }

    void OnBattlefieldPlayerJoinWar(Battlefield* bf, Player* player) override
    {
        if (!sCFBG->IsEnableSystem() || !sCFBG->IsEnableWGSystem())
            return;

        if (bf->GetTypeId() != BATTLEFIELD_WG)
            return;

        if (sCFBG->IsPlayerFake(player))
            return;

        if (sCFBG->IsWGSkipClass(player->getClass()))
            return;

        TeamId realTeam     = player->GetTeamId(true);
        TeamId assignedTeam = realTeam;

        // Reuse the team locked earlier this war so rejoining keeps the same
        // side instead of re-rolling the balance.
        std::optional<TeamId> locked;
        if (sCFBG->IsEnableWGTeamLock())
            locked = sCFBG->GetWGWarAssignment(player->GetGUID());

        if (locked)
            assignedTeam = *locked;
        else if (sCFBG->IsEnableWGNativePriority())
        {
            // Invited maps still hold the full native war population here:
            // core erases each accepter from InvitedPlayers only after this hook.
            uint32 allianceInvited = static_cast<uint32>(bf->GetInvitedPlayersMap(TEAM_ALLIANCE).size());
            uint32 hordeInvited    = static_cast<uint32>(bf->GetInvitedPlayersMap(TEAM_HORDE).size());

            // Live war counts for the no-worsen flip guard; the candidate is in
            // neither set yet (hook fires before PlayersInWar.insert). These are
            // assigned (post-fake) teams, exactly what balance must compare.
            uint32 allianceInWar = static_cast<uint32>(bf->GetPlayersInWarSet(TEAM_ALLIANCE).size());
            uint32 hordeInWar    = static_cast<uint32>(bf->GetPlayersInWarSet(TEAM_HORDE).size());

            assignedTeam = sCFBG->ResolveWGWarTeam(player, allianceInvited, hordeInvited, allianceInWar, hordeInWar);

            // Never flip into a side already at Wintergrasp.PlayerMax.
            if (assignedTeam != realTeam && !bf->HasWarVacancy(assignedTeam))
                assignedTeam = realTeam;

            if (sCFBG->IsEnableWGTeamLock())
                sCFBG->SetWGWarAssignment(player->GetGUID(), assignedTeam);
        }
        else
        {
            // Greedy fallback: candidate is in neither set yet (hook fires
            // before PlayersInWar.insert), so balance off the live core counts.
            uint32 allianceCount = static_cast<uint32>(bf->GetPlayersInWarSet(TEAM_ALLIANCE).size());
            uint32 hordeCount    = static_cast<uint32>(bf->GetPlayersInWarSet(TEAM_HORDE).size());

            if (realTeam == TEAM_ALLIANCE && allianceCount > hordeCount)
                assignedTeam = TEAM_HORDE;
            else if (realTeam == TEAM_HORDE && hordeCount > allianceCount)
                assignedTeam = TEAM_ALLIANCE;

            // Never flip into a side already at Wintergrasp.PlayerMax.
            if (assignedTeam != realTeam && !bf->HasWarVacancy(assignedTeam))
                assignedTeam = realTeam;

            if (sCFBG->IsEnableWGTeamLock())
                sCFBG->SetWGWarAssignment(player->GetGUID(), assignedTeam);
        }

        if (assignedTeam != realTeam)
            sCFBG->SetFakeRaceAndMorphForBF(player, assignedTeam);
    }

    void OnBattlefieldPlayerKill(Battlefield* bf, Player* killer, Player* victim) override
    {
        if (!sCFBG->IsEnableSystem() || !sCFBG->IsEnableWGSystem())
            return;

        if (bf->GetTypeId() != BATTLEFIELD_WG)
            return;

        // Credit the killer directly on any WG-zone kill, war or not. Granting
        // both PvP-kill credit NPCs covers crossfaction players whose held quest
        // does not match their assigned team — KilledMonsterCredit on a quest
        // the player does not hold is a no-op.
        //
        // Assist credit for nearby allies stays on core's existing lieutenant
        // path (BattlefieldWG::HandleKill iterates PlayersInWar[killerTeam] when
        // victim has SPELL_LIEUTENANT). We deliberately do NOT replicate that
        // iteration for every kill: the per-kill cost would scale with war
        // population (100+ players).
        //
        // To avoid double-crediting the killer when core's lieutenant path will
        // fire, skip coreCredit if the victim is a lieutenant AND the killer is
        // actually in PlayersInWar[killerTeam] (the only set core iterates).
        TeamId killerTeam = killer->GetTeamId();
        uint32 coreCredit  = (killerTeam == TEAM_HORDE) ? WG_NPC_QUEST_PVP_KILL_ALLIANCE
                                                        : WG_NPC_QUEST_PVP_KILL_HORDE;
        uint32 otherCredit = (killerTeam == TEAM_HORDE) ? WG_NPC_QUEST_PVP_KILL_HORDE
                                                        : WG_NPC_QUEST_PVP_KILL_ALLIANCE;

        bool coreWillCreditKiller = victim->HasAura(WG_SPELL_LIEUTENANT)
                                 && bf->GetPlayersInWarSet(killerTeam).count(killer->GetGUID()) > 0;

        if (!coreWillCreditKiller)
            killer->KilledMonsterCredit(coreCredit);
        killer->KilledMonsterCredit(otherCredit);
    }

    void OnBattlefieldWarEnd(Battlefield* bf, bool /*endByTimer*/) override
    {
        if (!sCFBG->IsEnableSystem() || !sCFBG->IsEnableWGSystem())
            return;

        if (bf->GetTypeId() != BATTLEFIELD_WG)
            return;

        // Hook fires before OnBattleEnd clears PlayersInWar, so each side's
        // war set still reflects who was actively fighting. ClearFakePlayer
        // is a no-op for unfaked players, so iterating GUIDs that may or may
        // not be faked is safe.

        // "Victory in Wintergrasp": OnBattleEnd credits the winners with the
        // quest of the defending (= winning) team only, which misses cross-
        // faction players holding their native faction's copy. Grant the other
        // one here -- AreaExploredOrEventHappens is a no-op on a quest the
        // player does not hold, and core still grants its own right after.
        uint32 const otherVictoryQuest = bf->GetDefenderTeam() == TEAM_ALLIANCE ? WG_QUEST_VICTORY_HORDE
                                                                               : WG_QUEST_VICTORY_ALLIANCE;

        for (uint8 team = 0; team < PVP_TEAMS_COUNT; ++team)
        {
            bool const isWinner = static_cast<TeamId>(team) == bf->GetDefenderTeam();

            for (ObjectGuid const& guid : bf->GetPlayersInWarSet(static_cast<TeamId>(team)))
            {
                Player* player = ObjectAccessor::FindPlayer(guid);
                if (!player)
                    continue;

                if (isWinner)
                    player->AreaExploredOrEventHappens(otherVictoryQuest);

                if (sCFBG->IsPlayerFake(player))
                    sCFBG->ClearFakePlayer(player);
            }
        }

        // Lock is per-war: drop assignments so the next war re-balances.
        sCFBG->ClearWGWarAssignments();
    }
};

class CFBG_World : public WorldScript
{
public:
    CFBG_World() : WorldScript("CFBG_World", {
        WORLDHOOK_ON_AFTER_CONFIG_LOAD
    }) { }

    void OnAfterConfigLoad(bool /*Reload*/) override
    {
        sCFBG->LoadConfig();
    }
};

void AddSC_CFBG()
{
    new CFBG_BG();
    new CFBG_Player();
    new CFBG_Battlefield();
    new CFBG_World();
}
