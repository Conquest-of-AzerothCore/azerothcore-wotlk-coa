/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AllBattlegroundScript.h"
#include "Battleground.h"
#include "ConditionMgr.h"
#include "Config.h"
#include "DBCStores.h"
#include "GameObject.h"
#include "GameObjectScript.h"
#include "GlobalScript.h"
#include "GossipDef.h"
#include "Group.h"
#include "LFGMgr.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "ReputationMgr.h"
#include "ScriptedGossip.h"
#include "ServerScript.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"
#include "WorldState.h"
#include "WorldStateDefines.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <optional>
#include <vector>

namespace
{
    enum BoardCategory : uint32
    {
        CategoryPvE = 1,
        CategoryReturn = 2,
        CategoryProfessions = 3,
        CategoryPvP = 4,
        CategoryHighRisk = 5
    };

    enum BoardQuestSort : int32
    {
        SortPvE = -380,
        SortPvP = -381,
        SortProfessions = -382
    };

    constexpr uint32 WorldStateWeeklyReset = 20002;
    constexpr uint32 WorldStateDailyReset = 20010;
    constexpr uint32 BoardCurrency = 975001;
    constexpr uint32 DuelQuest = 80651;
    constexpr uint32 DuelCredit = 80027;
    constexpr uint32 BattlegroundQuest = 81260;
    constexpr uint32 NormalDungeonCredit = 81042;
    constexpr uint32 HeroicDungeonCredit = 81041;
    constexpr uint32 MythicDungeonCredit = 80652;
    constexpr uint32 RaidLeaderCredit = 101000;
    constexpr uint32 DungeonLeaderCredit = 101001;
    constexpr uint32 QuelLithienUnrestQuest = 18044;
    constexpr uint32 SilvermoonRemnantFaction = 269;
    constexpr uint32 QuelLithienLodgeFactionTemplate = 1576;
    constexpr uint32 EasternPlaguelandsZone = 139;
    constexpr uint32 HighRiskRulesetAura = 1004019;
    constexpr std::array<uint32, 16> FinalRaidBosses = { 10184, 11502, 11583, 14834, 15339, 15727, 15990, 110184,
        111502, 111583, 114834, 115339, 115727, 115990, 210184, 211502 };

    constexpr uint16 SmsgAutoQuestUpdate = 0x0927;
    constexpr uint32 AutoQuestOffer = 0;
    constexpr uint32 HeroCallBoard = 402000;
    constexpr uint32 WarchiefCommandBoard = 402001;
    constexpr uint32 PaleReachIntroduction = 175207;
    constexpr std::array<uint32, 3> PaleReachOpeningQuests = { 175000, 175001, 175002 };

    std::atomic<bool> enabled{true};
    std::atomic<bool> autoOffer{true};

    bool IsCallBoard(uint32 entry)
    {
        switch (entry)
        {
            case 108606: case 402000: case 402001: case 402002: case 402003:
            case 412000: case 412001: case 413000: case 422000: case 1008002:
            case 1008008: case 1804480: case 2250000:
                return true;
            default:
                return false;
        }
    }

    bool RequiresHighRisk(Quest const* quest)
    {
        ConditionList const conditions = sConditionMgr->GetConditionsForNotGroupedEntry(
            CONDITION_SOURCE_TYPE_QUEST_AVAILABLE, quest->GetQuestId());
        return std::any_of(conditions.begin(), conditions.end(), [](Condition const* condition)
        {
            return condition->ConditionType == CONDITION_AURA && condition->ConditionValue1 == HighRiskRulesetAura
                && !condition->NegativeCondition;
        });
    }

    std::optional<uint32> CategoryOf(Quest const* quest)
    {
        if (RequiresHighRisk(quest))
            return CategoryHighRisk;

        int32 const sort = quest->GetZoneOrSort();
        if (sort > 0)
            return CategoryPvE;

        switch (sort)
        {
            case SortPvE: return CategoryPvE;
            case SortPvP: return CategoryPvP;
            case SortProfessions: return CategoryProfessions;
            default: return std::nullopt;
        }
    }

    bool InCategory(Quest const* quest, uint32 category)
    {
        std::optional<uint32> const questCategory = CategoryOf(quest);
        return questCategory && *questCategory == category;
    }

    uint32 FactionBoard(Player const* player)
    {
        return player->GetTeamId() == TEAM_ALLIANCE ? HeroCallBoard : WarchiefCommandBoard;
    }

    bool IsZoneOrder(Quest const* quest)
    {
        return quest->GetZoneOrSort() > 0 && !RequiresHighRisk(quest);
    }

    Quest const* FactionZoneOrder(Player const* player, uint32 questId)
    {
        auto const starters = sObjectMgr->GetGOQuestRelationBounds(FactionBoard(player));
        for (auto itr = starters.first; itr != starters.second; ++itr)
            if (itr->second == questId)
                if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId); quest && IsZoneOrder(quest))
                    return quest;

        return nullptr;
    }

    Quest const* PaleReachIntroductionFor(Player* player)
    {
        if (player->GetTeamId() != TEAM_ALLIANCE)
            return nullptr;

        for (uint32 questId : PaleReachOpeningQuests)
            if (player->GetQuestStatus(questId) != QUEST_STATUS_NONE || player->GetQuestRewardStatus(questId))
                return nullptr;

        Quest const* quest = sObjectMgr->GetQuestTemplate(PaleReachIntroduction);
        return quest && player->CanTakeQuest(quest, false) ? quest : nullptr;
    }

    void SendAutoQuestOffer(Player* player, Quest const* quest)
    {
        WorldPacket offer(SmsgAutoQuestUpdate, 2 * sizeof(uint32));
        offer << quest->GetQuestId() << AutoQuestOffer;
        player->SendDirectMessage(&offer);
    }

    void OfferPaleReachIntroduction(Player* player, uint32 previousLevel)
    {
        if (Quest const* quest = PaleReachIntroductionFor(player); quest && quest->GetMinLevel() > previousLevel)
            SendAutoQuestOffer(player, quest);
    }

    void OfferZoneOrdersUnlockedSince(Player* player, uint32 previousLevel)
    {
        auto const starters = sObjectMgr->GetGOQuestRelationBounds(FactionBoard(player));
        for (auto itr = starters.first; itr != starters.second; ++itr)
        {
            Quest const* quest = sObjectMgr->GetQuestTemplate(itr->second);
            if (!quest || !IsZoneOrder(quest) || quest->GetMinLevel() <= previousLevel
                || quest->GetMinLevel() > player->GetLevel() || !player->CanSeeStartQuest(quest)
                || !player->CanTakeQuest(quest, false))
                continue;

            SendAutoQuestOffer(player, quest);
        }
    }

    bool OffersZoneOrders(Player const* player)
    {
        return enabled.load() && autoOffer.load() && !player->GetSession()->IsBot();
    }

    void SendBoardMenu(Player* player, GameObject* board)
    {
        // Questgiver Data3 is a gossip menu ID. Its empty text makes the client clear its gossip GUID before
        // GOSSIP_SHOW, which CallBoardUI requires.
        player->PlayerTalkClass->GetGossipMenu().SetMenuId(board->GetGOInfo()->questgiver.gossipID);
        board->LastUsedScriptID = board->GetScriptId();
        SendGossipMenuFor(player, board->GetEntry(), board->GetGUID());
    }

    void ShowCategories(Player* player, GameObject* board)
    {
        ClearGossipMenuFor(player);

        // CallBoardTimers.lua reads these reset times as Unix world states.
        player->SendUpdateWorldState(WorldStateWeeklyReset,
            static_cast<uint32>(sWorld->GetNextWeeklyQuestsResetTime().count()));
        player->SendUpdateWorldState(WorldStateDailyReset,
            static_cast<uint32>(sWorld->GetNextDailyQuestsResetTime().count()));
        uint64 const arenaReset = sWorld->getBoolConfig(CONFIG_ARENA_AUTO_DISTRIBUTE_POINTS)
            ? sWorldState->getWorldState(WORLD_STATE_CUSTOM_ARENA_DISTRIBUTION_TIME) : 0;
        player->SendUpdateWorldState(WORLD_STATE_CUSTOM_ARENA_DISTRIBUTION_TIME, static_cast<uint32>(arenaReset));

        WorldPacket tokenQuery(CMSG_ITEM_QUERY_SINGLE, sizeof(uint32));
        tokenQuery << BoardCurrency;
        player->GetSession()->HandleItemQuerySingleOpcode(tokenQuery);

        // CallBoardUI binds its category buttons to these exact option labels.
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "PvE Quests", GOSSIP_SENDER_MAIN, CategoryPvE);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Profession Quests", GOSSIP_SENDER_MAIN, CategoryProfessions);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "PvP Quests", GOSSIP_SENDER_MAIN, CategoryPvP);
        if (player->HasAura(HighRiskRulesetAura))
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "High-Risk Quests", GOSSIP_SENDER_MAIN, CategoryHighRisk);
        SendBoardMenu(player, board);
    }

    void ShowCategory(Player* player, GameObject* board, uint32 category)
    {
        ClearGossipMenuFor(player);
        QuestMenu& menu = player->PlayerTalkClass->GetQuestMenu();

        // Filter before adding: both categories together can exceed the 32-entry menu limit.
        auto const involved = sObjectMgr->GetGOQuestInvolvedRelationBounds(board->GetEntry());
        for (auto itr = involved.first; itr != involved.second; ++itr)
        {
            Quest const* quest = sObjectMgr->GetQuestTemplate(itr->second);
            if (!quest || !InCategory(quest, category) || menu.HasItem(itr->second))
                continue;

            QuestStatus const status = player->GetQuestStatus(itr->second);
            if ((status == QUEST_STATUS_INCOMPLETE || status == QUEST_STATUS_COMPLETE)
                && menu.GetMenuItemCount() < GOSSIP_MAX_MENU_ITEMS)
                menu.AddMenuItem(itr->second, 4);
        }

        std::vector<Quest const*> offered;
        auto const available = sObjectMgr->GetGOQuestRelationBounds(board->GetEntry());
        for (auto itr = available.first; itr != available.second; ++itr)
        {
            Quest const* quest = sObjectMgr->GetQuestTemplate(itr->second);
            if (quest && InCategory(quest, category) && !menu.HasItem(itr->second)
                && player->CanSeeStartQuest(quest) && player->CanTakeQuest(quest, false))
                offered.push_back(quest);
        }

        // Past the menu limit the quests closest to the character's level stay listed.
        std::stable_sort(offered.begin(), offered.end(),
            [](Quest const* left, Quest const* right) { return left->GetMinLevel() > right->GetMinLevel(); });
        for (Quest const* quest : offered)
            if (menu.GetMenuItemCount() < GOSSIP_MAX_MENU_ITEMS)
                menu.AddMenuItem(quest->GetQuestId(), 2);

        // CallBoardLayout reads the quests' QuestSort synchronously, even on a cold client cache.
        for (uint16 index = 0; index < menu.GetMenuItemCount(); ++index)
            if (Quest const* quest = sObjectMgr->GetQuestTemplate(menu.GetItem(index).QuestId))
                player->PlayerTalkClass->SendQuestQueryResponse(quest);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Return", GOSSIP_SENDER_MAIN, CategoryReturn);
        SendBoardMenu(player, board);
    }

    bool RefreshBoard(Player* player, Object* object, Quest const* quest)
    {
        if (!enabled.load() || !player || !object || !quest || !object->IsGameObject())
            return false;

        GameObject* board = object->ToGameObject();
        if (!IsCallBoard(board->GetEntry())
            || (!board->hasQuest(quest->GetQuestId()) && !board->hasInvolvedQuest(quest->GetQuestId())))
            return false;

        std::optional<uint32> const category = CategoryOf(quest);
        if (!category)
            return false;

        ShowCategory(player, board, *category);
        return true;
    }

    // Quest 18044 is offered on both faction boards, but the Quel'Lithien Lodge elves are friendly to the Alliance:
    // they turn hostile to a character in Eastern Plaguelands while the quest is in its log. Their faction also has
    // friendly quest givers and trainers elsewhere, so the forced reaction stays within the zone.
    void UpdateQuelLithienReaction(Player* player, uint32 zoneId)
    {
        FactionTemplateEntry const* lodge = sFactionTemplateStore.LookupEntry(QuelLithienLodgeFactionTemplate);
        if (!lodge)
            return;

        QuestStatus const status = player->GetQuestStatus(QuelLithienUnrestQuest);
        bool const hostile = zoneId == EasternPlaguelandsZone
            && (status == QUEST_STATUS_INCOMPLETE || status == QUEST_STATUS_COMPLETE);
        ReputationMgr& reputation = player->GetReputationMgr();
        if (hostile == (reputation.GetForcedRankIfAny(lodge) != nullptr))
            return;

        reputation.ApplyForceReaction(SilvermoonRemnantFaction, REP_HOSTILE, hostile);
        reputation.SendForceReactions();

        FactionTemplateEntry const* own = player->GetFactionTemplateEntry();
        if (!hostile && own && lodge->IsFriendlyTo(*own))
            player->StopAttackFaction(SilvermoonRemnantFaction);
    }
}

class go_hero_call_board final : public GameObjectScript
{
public:
    go_hero_call_board() : GameObjectScript("native_ascension_callboard") { }

    uint32 GetDialogStatus(Player* /*player*/, GameObject* board) override
    {
        // The board is a permanent service: daily quest flags must not turn its marker blue.
        return enabled.load() && IsCallBoard(board->GetEntry()) ? DIALOG_STATUS_AVAILABLE
            : DIALOG_STATUS_SCRIPTED_NO_STATUS;
    }

    bool OnGossipHello(Player* player, GameObject* board) override
    {
        if (!enabled.load() || !IsCallBoard(board->GetEntry()))
            return false;

        ShowCategories(player, board);
        return true;
    }

    bool OnGossipSelect(Player* player, GameObject* board, uint32 sender, uint32 action) override
    {
        if (!enabled.load() || !IsCallBoard(board->GetEntry()) || sender != GOSSIP_SENDER_MAIN)
            return false;

        if (action == CategoryReturn)
            ShowCategories(player, board);
        else if (action == CategoryPvE || action == CategoryProfessions || action == CategoryPvP
            || action == CategoryHighRisk)
            ShowCategory(player, board, action);
        else
            return false;

        return true;
    }

    bool OnQuestReward(Player* player, GameObject* board, Quest const* quest, uint32 /*reward*/) override
    {
        return RefreshBoard(player, board, quest);
    }
};

class HeroCallBoardPlayers final : public PlayerScript
{
public:
    HeroCallBoardPlayers() : PlayerScript("HeroCallBoardPlayers",
        { PLAYERHOOK_ON_REFRESH_QUEST_GIVER, PLAYERHOOK_ON_QUEST_ABANDON, PLAYERHOOK_ON_DUEL_END,
            PLAYERHOOK_ON_CREATURE_KILL, PLAYERHOOK_ON_CREATURE_KILLED_BY_PET, PLAYERHOOK_ON_LEVEL_CHANGED,
            PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_UPDATE_ZONE, PLAYERHOOK_ON_PLAYER_QUEST_ACCEPT,
            PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST }) { }

    void OnPlayerLogin(Player* player) override
    {
        UpdateQuelLithienReaction(player, player->GetZoneId());
        if (OffersZoneOrders(player))
            OfferPaleReachIntroduction(player, 0);
    }

    void OnPlayerUpdateZone(Player* player, uint32 newZone, uint32 /*newArea*/) override
    {
        UpdateQuelLithienReaction(player, newZone);
    }

    void OnPlayerQuestAccept(Player* player, Quest const* quest) override
    {
        if (quest->GetQuestId() == QuelLithienUnrestQuest)
            UpdateQuelLithienReaction(player, player->GetZoneId());
    }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        if (quest->GetQuestId() == QuelLithienUnrestQuest)
            UpdateQuelLithienReaction(player, player->GetZoneId());
    }

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override
    {
        if (OffersZoneOrders(player) && player->GetLevel() > oldLevel)
        {
            OfferZoneOrdersUnlockedSince(player, oldLevel);
            OfferPaleReachIntroduction(player, oldLevel);
        }
    }

    void OnPlayerCreatureKill(Player* killer, Creature* killed) override { CreditRaidLeader(killer, killed); }

    void OnPlayerCreatureKilledByPet(Player* owner, Creature* killed) override { CreditRaidLeader(owner, killed); }

    bool OnPlayerRefreshQuestGiver(Player* player, Object* questGiver, Quest const* quest) override
    {
        // Accept All submits a batch through the ordinary accept opcode: the category stays open, and every
        // quest still passes the core's checks.
        return RefreshBoard(player, questGiver, quest);
    }

    void OnPlayerQuestAbandon(Player* player, uint32 questId) override
    {
        if (questId == QuelLithienUnrestQuest)
            UpdateQuelLithienReaction(player, player->GetZoneId());

        if (!enabled.load())
            return;

        // Refresh only a still-open board that listed this quest.
        ObjectGuid const boardGuid = player->PlayerTalkClass->GetGossipMenu().GetSenderGUID();
        if (boardGuid.IsEmpty() || !player->PlayerTalkClass->GetQuestMenu().HasItem(questId))
            return;

        Object* board = ObjectAccessor::GetObjectByTypeMask(*player, boardGuid, TYPEMASK_GAMEOBJECT);
        if (board && player->CanInteractWithQuestGiver(board))
            RefreshBoard(player, board, sObjectMgr->GetQuestTemplate(questId));
    }

    void OnPlayerDuelEnd(Player* winner, Player* loser, DuelCompleteType type) override
    {
        // Only victories count; requests, losses and interrupted duels do not.
        if (!enabled.load() || type != DUEL_WON || !winner || !loser || winner == loser || !winner->IsInWorld()
            || !loser->IsInWorld() || winner->GetQuestStatus(DuelQuest) != QUEST_STATUS_INCOMPLETE)
            return;

        winner->KilledMonsterCredit(DuelCredit);
    }

private:
    // The classic raids' last encounters have no usable dungeon encounter data here, so the final bosses are listed.
    static void CreditRaidLeader(Player* killer, Creature* killed)
    {
        if (!enabled.load() || !killed->GetMap()->IsRaid()
            || std::find(FinalRaidBosses.begin(), FinalRaidBosses.end(), killed->GetEntry()) == FinalRaidBosses.end())
            return;

        Group const* group = killer->GetGroup();
        Player* leader = group ? ObjectAccessor::FindPlayer(group->GetLeaderGUID()) : nullptr;
        if (leader && leader->IsInWorld() && leader->IsAtGroupRewardDistance(killed))
            leader->KilledMonsterCredit(RaidLeaderCredit);
    }
};

class HeroCallBoardBattlegrounds final : public AllBattlegroundScript
{
public:
    HeroCallBoardBattlegrounds() : AllBattlegroundScript("HeroCallBoardBattlegrounds",
        { ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_END_REWARD }) { }

    void OnBattlegroundEndReward(Battleground* battleground, Player* player, TeamId winner) override
    {
        if (!enabled.load() || battleground->isArena() || battleground->IsWargame() || winner == TEAM_NEUTRAL
            || player->GetBgTeamId() != winner || player->GetQuestStatus(BattlegroundQuest) != QUEST_STATUS_INCOMPLETE)
            return;

        player->AreaExploredOrEventHappens(BattlegroundQuest);
    }
};

class HeroCallBoardDungeons final : public GlobalScript
{
public:
    HeroCallBoardDungeons() : GlobalScript("HeroCallBoardDungeons", { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType /*type*/, uint32 /*creditEntry*/, Unit* source,
        Difficulty /*difficulty*/, std::list<DungeonEncounter const*> const* /*encounters*/, uint32 dungeonId,
        bool updated) override
    {
        if (!enabled.load() || !updated || !dungeonId || !map || !map->IsNonRaidDungeon()
            || map->IsScriptedPrivateInstance() || !source || source->FindMap() != map)
            return;

        auto const* dungeon = sLFGMgr->GetLFGDungeon(dungeonId);
        if (!dungeon || dungeon->map != map->GetId() || dungeon->difficulty != map->GetDifficulty())
            return;

        CreditDungeonLeader(map, source);

        uint32 credit = 0;
        switch (map->GetDifficulty())
        {
            case DUNGEON_DIFFICULTY_NORMAL: credit = NormalDungeonCredit; break;
            case DUNGEON_DIFFICULTY_HEROIC: credit = HeroicDungeonCredit; break;
            case DUNGEON_DIFFICULTY_EPIC: credit = MythicDungeonCredit; break;
            default: return;
        }

        for (auto const& reference : map->GetPlayers())
        {
            Player* player = reference.GetSource();
            if (!player || !player->IsInWorld() || !player->IsAtGroupRewardDistance(source))
                continue;

            // The dailies require a dungeon finder group assigned to this dungeon; the durable state keeps the
            // assignment while the group looks for a replacement.
            Group const* group = player->GetGroup();
            if (group && group->isLFGGroup() && sLFGMgr->GetDungeon(group->GetGUID()) == dungeonId
                && sLFGMgr->GetOldState(group->GetGUID()) == lfg::LFG_STATE_DUNGEON
                && sLFGMgr->GetOldState(player->GetGUID()) == lfg::LFG_STATE_DUNGEON)
                player->KilledMonsterCredit(credit);
        }
    }

private:
    static void CreditDungeonLeader(Map* map, Unit* source)
    {
        for (auto const& reference : map->GetPlayers())
        {
            Player* player = reference.GetSource();
            Group const* group = player ? player->GetGroup() : nullptr;
            if (group && group->IsLeader(player->GetGUID()) && player->IsInWorld()
                && player->IsAtGroupRewardDistance(source))
                player->KilledMonsterCredit(DungeonLeaderCredit);
        }
    }
};

class HeroCallBoardAutoAccept final : public ServerScript
{
public:
    HeroCallBoardAutoAccept() : ServerScript("HeroCallBoardAutoAccept", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        bool const accepting = packet.GetOpcode() == CMSG_QUESTGIVER_ACCEPT_QUEST;
        if ((!accepting && packet.GetOpcode() != CMSG_QUESTGIVER_QUERY_QUEST)
            || packet.size() != (accepting ? 16u : 13u) || packet.read<uint64>(0) != 0
            || !enabled.load() || !autoOffer.load() || !session)
            return true;

        Player* player = session->GetPlayer();
        uint32 const questId = packet.read<uint32>(8);
        if (!player || (!accepting && questId != PaleReachIntroduction))
            return true;

        Quest const* quest = questId == PaleReachIntroduction ? PaleReachIntroductionFor(player)
            : FactionZoneOrder(player, questId);
        if (!quest)
            return true;

        if (!accepting)
            player->PlayerTalkClass->SendQuestGiverQuestDetails(quest, ObjectGuid::Empty, true);
        else if (player->CanTakeQuest(quest, true) && player->CanAddQuest(quest, true))
            player->AddQuestAndCheckCompletion(quest, nullptr);

        return false;
    }
};

class HeroCallBoardWorld final : public WorldScript
{
public:
    HeroCallBoardWorld() : WorldScript("HeroCallBoardWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        enabled.store(sConfigMgr->GetOption<bool>("HeroCallBoard.Enable", true));
        autoOffer.store(sConfigMgr->GetOption<bool>("HeroCallBoard.AutoOffer", true));
    }
};

void AddHeroCallBoardScripts()
{
    new go_hero_call_board();
    new HeroCallBoardPlayers();
    new HeroCallBoardBattlegrounds();
    new HeroCallBoardDungeons();
    new HeroCallBoardAutoAccept();
    new HeroCallBoardWorld();
}
