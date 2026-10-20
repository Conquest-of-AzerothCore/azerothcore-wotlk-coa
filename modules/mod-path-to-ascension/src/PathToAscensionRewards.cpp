/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "PathToAscension.h"

#include "GossipDef.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <atomic>
#include <deque>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace PathToAscension
{
    namespace
    {
        constexpr uint16 CMSG_CLAIM_TUTORIAL_REWARD = 0x06A8;
        constexpr uint16 SMSG_CLAIM_TUTORIAL_REWARD_RESULT = 0x06AF;
        constexpr uint16 SMSG_TUTORIAL_REWARDED_LIST = 0x06B0;
        constexpr uint16 SMSG_TUTORIAL_REWARDED = 0x06B1;
        constexpr uint32 IntroductionTutorial = 120;
        constexpr uint32 InnkeeperTutorial = 76;
        constexpr uint32 InnkeeperAchievement = 86676;
        constexpr uint8 MinimumLevel = 8;
        constexpr std::size_t MaxQueuedRequests = 8;
        constexpr std::size_t MaxRewardStacks = 128;

        struct Request
        {
            uint64 token;
            uint32 id;
            bool startQuest;
        };

        std::map<uint32, std::vector<uint32>> trackingQuests;
        std::atomic<uint64> nextToken{0};
        std::mutex requestMutex;
        std::unordered_map<uint32, std::deque<Request>> requests;

        bool Claimed(Player const* player, uint32 id)
        {
            return SettingValue(player, ClaimSetting, id) == 1;
        }

        void SendResult(Player* player, char const* message)
        {
            WorldPacket packet(SMSG_CLAIM_TUTORIAL_REWARD_RESULT, 64);
            packet << message;
            player->SendDirectMessage(&packet);
        }

        bool IsIntroduction(Tutorial const& tutorial)
        {
            return tutorial.Id() == IntroductionTutorial && !tutorial.AchievementId() && !tutorial.QuestId()
                && tutorial.objectives.empty();
        }

        bool IsVerified(Player const* player, Tutorial const& tutorial)
        {
            return SettingValue(player, VerifiedSetting, tutorial.Id()) == 1
                && (!tutorial.AchievementId() || player->HasAchieved(tutorial.AchievementId()));
        }

        bool Complete(Player const* player, uint32 id)
        {
            Tutorial const* tutorial = GetCatalog().Find(id);
            if (!tutorial)
                return false;

            if (Claimed(player, id) || IsIntroduction(*tutorial))
                return true;

            if (id == InnkeeperTutorial && player->HasAchieved(InnkeeperAchievement))
                return true;

            return IsVerified(player, *tutorial);
        }

        // Extensions.dll 0x10a18e10 checks a prerequisite's achievement, not its class applicability.
        // A verified sibling with the same quest and achievement therefore completes the prerequisite.
        bool PreviousComplete(Player const* player, uint32 id)
        {
            if (Complete(player, id))
                return true;

            Tutorial const* previous = GetCatalog().Find(id);
            if (!previous || !previous->QuestId() || !previous->AchievementId())
                return false;

            for (auto const& [otherId, other] : GetCatalog().Tutorials())
                if (otherId != id && other.QuestId() == previous->QuestId()
                    && other.AchievementId() == previous->AchievementId() && Complete(player, otherId))
                    return true;

            return false;
        }

        bool Eligible(Player const* player, Tutorial const& tutorial)
        {
            Settings const& settings = GetSettings();
            auto const& f = tutorial.fields;
            if (!tutorial.CategoryId() || !f[RealmAvailabilityField(settings.realm)]
                || player->GetLevel() < MinimumLevel || !MatchesRaceAndClass(player, tutorial)
                || !IsExpansionOffered(tutorial))
                return false;

            bool hasPrevious = false;
            bool previousComplete = false;
            for (uint32 i = TutorialField::FirstPrevious; i <= TutorialField::LastPrevious; ++i)
            {
                hasPrevious |= f[i] != 0;
                previousComplete |= f[i] && PreviousComplete(player, f[i]);
            }

            if (hasPrevious && !previousComplete)
                return false;

            bool hasSpell = false;
            bool spellKnown = false;
            for (uint32 i = TutorialField::FirstRequiredSpell; i <= TutorialField::LastRequiredSpell; ++i)
            {
                hasSpell |= f[i] != 0;
                spellKnown |= f[i] && player->HasSpell(f[i]);
            }

            if (hasSpell && !spellKnown)
                return false;

            uint32 const required = f[TutorialField::RequiredGameModes];
            uint32 const excluded = f[TutorialField::ExcludedGameModes];
            if (!required && !excluded)
                return true;

            std::optional<uint32> const modes = GameModeMask(player);
            return modes && (!required || (required & *modes)) && !(excluded & *modes);
        }

        void ActivateTracking(Player* player, uint32 questId)
        {
            auto const found = trackingQuests.find(questId);
            if (found == trackingQuests.end())
                return;

            for (uint32 variant : found->second)
            {
                Tutorial const* tutorial = GetCatalog().Find(variant);
                bool const active = tutorial && !Claimed(player, variant) && Eligible(player, *tutorial);
                player->UpdatePlayerSetting(TrackingSetting, variant, active ? 1 : 0);
                if (active)
                    SyncTracking(player, variant);
            }
        }

        bool Enqueue(WorldSession* session, Request request)
        {
            std::lock_guard<std::mutex> lock(requestMutex);
            std::deque<Request>& queue = requests[session->GetAccountId()];
            if (queue.size() < MaxQueuedRequests)
                queue.push_back(request);
            return true;
        }

        void SendRewardedList(Player* player)
        {
            std::vector<uint32> claimed;
            for (auto const& [id, tutorial] : GetCatalog().Tutorials())
                if (Claimed(player, id))
                    claimed.push_back(id);

            WorldPacket packet(SMSG_TUTORIAL_REWARDED_LIST, 4 + claimed.size() * 4);
            packet << uint32(claimed.size());
            for (uint32 id : claimed)
                packet << id;
            player->SendDirectMessage(&packet);
        }
    }

    void ConfigureRewards()
    {
        trackingQuests.clear();
        for (auto const& [id, tutorial] : GetCatalog().Tutorials())
        {
            if (!tutorial.QuestId() || !IsCallbackImplemented(id))
                continue;

            // Tutorial.dbc owns the quest mapping; only an event-completed quest without rewards of its
            // own can serve as a tracking view.
            Quest const* quest = sObjectMgr->GetQuestTemplate(tutorial.QuestId());
            if (quest && quest->HasSpecialFlag(QUEST_SPECIAL_FLAGS_EXPLORATION_OR_EVENT)
                && !quest->GetRewItemsCount() && !quest->GetRewChoiceItemsCount()
                && !quest->GetRewSpell() && !quest->GetRewSpellCast())
                trackingQuests[tutorial.QuestId()].push_back(id);
        }

        LOG_INFO("module.pta", "Path to Ascension tracks {} quest views", trackingQuests.size());
    }

    bool IsTrackingQuest(uint32 questId)
    {
        Settings const& settings = GetSettings();
        return settings.rewards && settings.tracking && trackingQuests.contains(questId);
    }

    bool IsQuestAvailable(Player const* player, uint32 questId)
    {
        if (!IsTrackingQuest(questId))
            return true;

        if (!player || player->IsGameMaster())
            return false;

        for (uint32 id : trackingQuests.at(questId))
            if (Tutorial const* tutorial = GetCatalog().Find(id); tutorial && !Claimed(player, id)
                && Eligible(player, *tutorial))
                return true;

        return false;
    }

    void SyncTracking(Player* player, uint32 tutorialId)
    {
        if (!GetSettings().tracking || !player || !player->IsInWorld() || player->IsGameMaster()
            || SettingValue(player, TrackingSetting, tutorialId) != 1)
            return;

        Tutorial const* tutorial = GetCatalog().Find(tutorialId);
        if (!tutorial || !IsTrackingQuest(tutorial->QuestId()))
            return;

        uint32 const questId = tutorial->QuestId();
        constexpr uint32 IntroductionVisits = 2;
        constexpr uint32 IntroductionQuest = 81000;
        if (tutorialId == IntroductionVisits && questId == IntroductionQuest)
        {
            uint32 const visits = SettingValue(player, EventSetting, IntroductionVisits);
            if (visits & 1u)
                player->TalkedToCreature(80420, ObjectGuid::Empty);
            if (visits & 2u)
                player->TalkedToCreature(80421, ObjectGuid::Empty);
        }

        if (Complete(player, tutorialId) && player->GetQuestStatus(questId) == QUEST_STATUS_INCOMPLETE)
            player->AreaExploredOrEventHappens(questId);
    }

    void StartTrackedQuest(Player* player, uint32 questId)
    {
        auto const found = trackingQuests.find(questId);
        if (!GetSettings().tracking || found == trackingQuests.end() || player->IsBeingTeleportedFar()
            || player->GetTradeData())
            return;

        Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
        if (!quest)
            return;

        if (!IsQuestAvailable(player, questId))
        {
            bool const claimed = std::any_of(found->second.begin(), found->second.end(),
                [player](uint32 id) { return Claimed(player, id); });
            return SendResult(player, claimed ? "This tutorial reward has already been collected."
                : "This tutorial is not available for your character.");
        }

        if (player->GetQuestStatus(questId) == QUEST_STATUS_NONE)
        {
            if (!player->CanTakeQuest(quest, true) || !player->CanAddQuest(quest, true))
                return;
            player->AddQuest(quest, nullptr);
        }

        if (player->FindQuestSlot(questId) >= MAX_QUEST_LOG_SIZE)
            return;

        ActivateTracking(player, questId);
        player->SaveToDB(false, false);
    }

    uint32 NpcRewardTutorial(Player const* player, uint32 questId)
    {
        if (!IsTrackingQuest(questId) || !player || player->IsGameMaster()
            || player->GetQuestStatus(questId) != QUEST_STATUS_COMPLETE)
            return 0;

        for (uint32 id : trackingQuests.at(questId))
            if (Tutorial const* tutorial = GetCatalog().Find(id);
                tutorial && !Claimed(player, id) && Complete(player, id) && Eligible(player, *tutorial))
                return id;

        return 0;
    }

    void Claim(Player* player, uint32 id)
    {
        Tutorial const* tutorial = GetCatalog().Find(id);
        if (!tutorial)
            return SendResult(player, "Unknown tutorial.");
        if (Claimed(player, id))
            return SendResult(player, "This tutorial reward has already been collected.");
        if (!Complete(player, id) || !Eligible(player, *tutorial))
            return SendResult(player, "This tutorial reward is not available for your character.");
        if (!IsVerified(player, *tutorial) && !IsIntroduction(*tutorial)
            && !(id == InnkeeperTutorial && player->HasAchieved(InnkeeperAchievement)))
            return SendResult(player, "This objective's original completion rule is not restored yet.");
        if (player->IsBeingTeleportedFar() || player->GetTradeData())
            return SendResult(player, "Finish your transfer or trade before collecting this reward.");

        std::vector<std::unique_ptr<Item>> prepared;
        std::vector<Item*> items;
        for (Reward const& reward : tutorial->rewards)
        {
            ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(reward.itemId);
            if (!itemTemplate || !reward.count)
                return SendResult(player, "The original reward item is unavailable on this server.");

            for (uint32 remaining = reward.count; remaining;)
            {
                uint32 const count = std::min(remaining, itemTemplate->GetMaxStackSize());
                if (!count || prepared.size() >= MaxRewardStacks)
                    return SendResult(player, "The original reward could not be prepared.");

                std::unique_ptr<Item> item(Item::CreateItem(reward.itemId, count, player));
                if (!item)
                    return SendResult(player, "The original reward could not be prepared.");

                items.push_back(item.get());
                prepared.push_back(std::move(item));
                remaining -= count;
            }
        }

        uint32 limitedCategory = 0;
        if (player->CanStoreItems(items.data(), int(items.size()), &limitedCategory) != EQUIP_ERR_OK)
            return SendResult(player, "There is not enough room for this reward, or an item limit has been reached.");

        struct StoredPart
        {
            ObjectGuid guid;
            uint32 count;
        };

        std::vector<StoredPart> storedParts;
        std::vector<StoredPart> notifications;
        for (std::unique_ptr<Item>& item : prepared)
        {
            ItemPosCountVec destinations;
            InventoryResult const result = player->CanStoreItem(NULL_BAG, NULL_SLOT, destinations, item.get(), false);
            if (result != EQUIP_ERR_OK)
            {
                // Batch and single-item rules can disagree (unique-item limits); undo only this request.
                for (auto part = storedParts.rbegin(); part != storedParts.rend(); ++part)
                    if (Item* stored = player->GetItemByGuid(part->guid))
                        player->DestroyItemCount(stored, part->count, true);

                LOG_ERROR("module.pta", "Reward placement rejected for tutorial {}: {}", id, result);
                return SendResult(player, "The reward could not be placed in your inventory. No reward was collected.");
            }

            uint32 const count = item->GetCount();
            Item* stored = player->StoreItem(destinations, item.release(), true);
            for (ItemPosCount const& destination : destinations)
                if (Item* part = player->GetItemByPos(destination.pos))
                    storedParts.push_back({part->GetGUID(), destination.count});
            notifications.push_back({stored->GetGUID(), count});
        }

        for (StoredPart const& notification : notifications)
            if (Item* stored = player->GetItemByGuid(notification.guid))
            {
                player->ItemAddedQuestCheck(stored->GetEntry(), notification.count);
                player->SendNewItem(stored, notification.count, true, false);
            }

        player->UpdatePlayerSetting(ClaimSetting, id, 1);
        if (IsTrackingQuest(tutorial->QuestId()))
        {
            uint16 const slot = player->FindQuestSlot(tutorial->QuestId());
            if (slot < MAX_QUEST_LOG_SIZE)
                player->SetQuestSlot(slot, 0);
            player->RemoveActiveQuest(tutorial->QuestId());
            for (uint32 variant : trackingQuests.at(tutorial->QuestId()))
                player->UpdatePlayerSetting(TrackingSetting, variant, 0);
        }

        // One character save carries the items, the achievement progress and the claim marker.
        player->SaveToDB(false, false);
        WorldPacket rewarded(SMSG_TUTORIAL_REWARDED, 4);
        rewarded << id;
        player->SendDirectMessage(&rewarded);
        SendResult(player, "CLAIM_TUTORIAL_OK");
    }

    bool QueueClientRequest(WorldSession* session, WorldPacket const& packet)
    {
        bool const startQuest = packet.GetOpcode() == CMSG_QUESTGIVER_ACCEPT_QUEST;
        if (startQuest)
        {
            // C_Tutorial.StartQuest sends a zero quest giver GUID in a 16-byte accept packet.
            if (packet.size() != 16 || packet.read<uint64>(0) != 0 || !IsTrackingQuest(packet.read<uint32>(8)))
                return false;
        }
        else if (packet.GetOpcode() != CMSG_CLAIM_TUTORIAL_REWARD)
            return false;

        uint64 const token = session->GetScriptPacketToken();
        if (!GetSettings().rewards || !token || (!startQuest && packet.size() != 4))
            return true;

        return Enqueue(session, {token, packet.read<uint32>(startQuest ? 8 : 0), startQuest});
    }

    void LoginRewards(Player* player)
    {
        if (!GetSettings().rewards || player->GetSession()->IsBot())
            return;

        // The session token is shared with the other extension services: keep one they assigned.
        if (!player->GetSession()->GetScriptPacketToken())
            player->GetSession()->SetScriptPacketToken((uint64(1) << 63) | ++nextToken);

        SendRewardedList(player);

        for (auto const& [id, tutorial] : GetCatalog().Tutorials())
            SyncTracking(player, id);
    }

    void PrestigeRewards(Player* player)
    {
        if (!GetSettings().rewards || player->GetSession()->IsBot())
            return;

        for (auto const& [id, tutorial] : GetCatalog().Tutorials())
            if (SettingValue(player, TrackingSetting, id) == 1
                && player->FindQuestSlot(tutorial.QuestId()) >= MAX_QUEST_LOG_SIZE)
                player->UpdatePlayerSetting(TrackingSetting, id, 0);

        SendRewardedList(player);
    }

    void LogoutRewards(Player* player)
    {
        std::lock_guard<std::mutex> lock(requestMutex);
        requests.erase(player->GetSession()->GetAccountId());
    }

    void UpdateRewards(Player* player)
    {
        if (!GetSettings().rewards || player->GetSession()->IsBot() || !player->IsInWorld())
            return;

        std::deque<Request> incoming;
        {
            std::lock_guard<std::mutex> lock(requestMutex);
            auto const found = requests.find(player->GetSession()->GetAccountId());
            if (found == requests.end())
                return;
            incoming.swap(found->second);
            requests.erase(found);
        }

        uint64 const token = player->GetSession()->GetScriptPacketToken();
        for (Request const& request : incoming)
        {
            if (!token || request.token != token)
                continue;

            if (request.startQuest)
                StartTrackedQuest(player, request.id);
            else
                Claim(player, request.id);
        }
    }
}

using namespace PathToAscension;

class PathToAscensionQuests final : public PlayerScript
{
public:
    PathToAscensionQuests() : PlayerScript("PathToAscensionQuests",
        { PLAYERHOOK_CAN_TAKE_QUEST, PLAYERHOOK_CAN_REWARD_QUEST, PLAYERHOOK_ON_QUEST_GIVER_CHOOSE_REWARD,
          PLAYERHOOK_ON_PLAYER_QUEST_ACCEPT }) { }

    bool OnPlayerCanTakeQuest(Player const* player, Quest const* quest) override
    {
        return !IsLoaded() || IsQuestAvailable(player, quest->GetQuestId());
    }

    bool OnPlayerCanRewardQuest(Player const* /*player*/, Quest const* quest) override
    {
        return !IsLoaded() || !IsTrackingQuest(quest->GetQuestId());
    }

    bool OnPlayerQuestGiverChooseReward(Player* player, Object* /*questGiver*/, Quest const* quest,
        uint32 /*reward*/) override
    {
        if (!IsLoaded() || !IsTrackingQuest(quest->GetQuestId()))
            return false;

        if (uint32 const id = NpcRewardTutorial(player, quest->GetQuestId()))
            Claim(player, id);
        player->PlayerTalkClass->SendCloseGossip();
        return true;
    }

    void OnPlayerQuestAccept(Player* player, Quest const* quest) override
    {
        if (!IsLoaded() || !IsTrackingQuest(quest->GetQuestId()))
            return;

        StartTrackedQuest(player, quest->GetQuestId());
    }
};

class PathToAscensionRewardPlayers final : public PlayerScript
{
public:
    PathToAscensionRewardPlayers() : PlayerScript("PathToAscensionRewardPlayers",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_COA_PRESTIGE_SAVED }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (IsLoaded())
            LoginRewards(player);
    }

    void OnPlayerCoAPrestigeSaved(Player* player) override
    {
        if (IsLoaded())
            PrestigeRewards(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        LogoutRewards(player);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (IsLoaded())
            UpdateRewards(player);
    }
};

class PathToAscensionNetwork final : public ServerScript
{
public:
    PathToAscensionNetwork() : ServerScript("PathToAscensionNetwork", { SERVERHOOK_CAN_PACKET_RECEIVE_EARLY }) { }

    bool CanPacketReceiveEarly(WorldSession* session, WorldPacket const& packet) override
    {
        return !session || !IsLoaded() || !QueueClientRequest(session, packet);
    }
};

void AddPathToAscensionRewardScripts()
{
    new PathToAscensionQuests();
    new PathToAscensionRewardPlayers();
    new PathToAscensionNetwork();
}
