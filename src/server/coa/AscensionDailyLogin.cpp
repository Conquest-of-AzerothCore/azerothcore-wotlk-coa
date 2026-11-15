/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientLua.h"
#include "AsyncCallbackProcessor.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include "WorldPacket.h"
#include <algorithm>
#include <limits>
#include <memory>
#include <mutex>
#include <utility>
#include <vector>

namespace
{
    struct Reward
    {
        uint32 Item;
        uint32 Quantity;
    };

    std::vector<Reward> rewards;
    std::mutex commitLock;
    AsyncCallbackProcessor<TransactionCallback> commits;

    void ScheduleLoginReward(Player* player, uint8 attempts = 12);

    void ShowRewardToast(Player* player, uint64 claim, uint8 attempts = 12)
    {
        if (!player->IsInWorld() || !player->FindMap() || player->IsBeingTeleported())
        {
            if (attempts > 1)
                player->m_Events.AddEventAtOffset([guid = player->GetGUID(), claim, attempts]()
                {
                    if (Player* current = ObjectAccessor::FindConnectedPlayer(guid))
                        ShowRewardToast(current, claim, attempts - 1);
                }, Milliseconds(5000));
            return;
        }
        AscensionClientLuaChunk chunk;
        chunk.RequirementTypeId = 24;
        chunk.RequirementId = 16265;
        chunk.Token = Acore::StringFormat("COA_DAILY_LOGIN_{}_{}", player->GetSession()->GetAccountId(), claim);
        chunk.Lua = "local rewards={";
        for (Reward const& reward : rewards)
        {
            WorldPacket query;
            query << reward.Item;
            player->GetSession()->HandleItemQuerySingleOpcode(query);
            chunk.Lua += Acore::StringFormat("{{{},{}}},", reward.Item, reward.Quantity);
        }
        chunk.Lua += R"lua(}
local frame = CreateFrame("Frame")
local elapsed, interval, index = 0, 0, 1
frame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed > 30 then self:SetScript("OnUpdate", nil) return end
    interval = interval + delta
    if interval < 0.25 then return end
    interval = 0
    if not ToastNotificationSystem or not ToastNotificationSystem.EnqueueGenericNotification then return end
    local reward = rewards[index]
    local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(reward[1])
    if not icon then return end
    ToastNotificationSystem:EnqueueGenericNotification("Item", "Daily Login Reward", name,
        reward[2], icon, quality, nil, "Your reward has been sent by mail.")
    index = index + 1
    if index > #rewards then self:SetScript("OnUpdate", nil) end
end)
)lua";
        RunAscensionClientLua(player, chunk);
    }

    void CompleteDailyLogin(Player* player, PreparedQueryResult const& result)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;
        Field* fields = result->Fetch();
        uint64 const nextClaim = fields[0].Get<uint64>();
        uint64 const previousClaim = fields[1].Get<uint64>();
        uint64 const now = fields[2].Get<uint64>();
        if (now < nextClaim || previousClaim == std::numeric_limits<uint64>::max())
            return;

        auto transaction = CharacterDatabase.BeginTransaction();
        auto* claim = CharacterDatabase.GetPreparedStatement(CHAR_CLAIM_COA_DAILY_LOGIN);
        claim->SetData(0, session->GetAccountId());
        claim->SetData(1, now);
        claim->SetData(2, now + DAY);
        claim->SetData(3, now);
        claim->SetData(4, previousClaim);
        transaction->Append(claim);

        auto mail = std::shared_ptr<MailDraft>(new MailDraft("Daily Login Reward",
            "Thank you for playing Conquest of Azeroth! Your daily rewards are enclosed."), [](MailDraft* draft)
        {
            draft->DiscardItems();
            delete draft;
        });
        for (Reward const& reward : rewards)
        {
            ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(reward.Item);
            if (!itemTemplate)
                return;
            uint32 remaining = reward.Quantity;
            while (remaining)
            {
                uint32 const count = std::min(remaining, uint32(itemTemplate->GetMaxStackSize()));
                Item* item = Item::CreateItem(reward.Item, count, player);
                if (!item)
                    return;
                item->SaveToDB(transaction);
                mail->AddItem(item);
                remaining -= count;
            }
        }
        auto staged = mail->StageMailTo(transaction, player->GetGUID().GetCounter(), MailSender(MAIL_NORMAL, 0));
        if (!staged)
            return;
        auto committed = CharacterDatabase.AsyncCommitTransaction(transaction);
        std::lock_guard lock(commitLock);
        commits.AddCallback(std::move(committed)).AfterComplete(
            [mail, staged = *staged, guid = player->GetGUID(),
             accountId = player->GetSession()->GetAccountId(), claimNumber = previousClaim + 1](bool success)
        {
            if (!success)
                return;
            Player* current = ObjectAccessor::FindConnectedPlayer(guid);
            if (current && (!current->GetSession() || current->GetSession()->GetAccountId() != accountId))
                current = nullptr;
            mail->PublishStagedMail(staged, current);
            if (current)
                ShowRewardToast(current, claimNumber);
        });
    }

    void GrantDailyLogin(Player* player)
    {
        WorldSession* session = player->GetSession();
        if (rewards.empty() || !session || session->IsBot() || !player->IsInWorld() ||
            player->IsBeingTeleported() || !player->FindMap())
            return;
        auto* read = CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_DAILY_LOGIN);
        read->SetData(0, session->GetAccountId());
        session->GetQueryProcessor().AddCallback(CharacterDatabase.AsyncQuery(read).WithPreparedCallback(
            [guid = player->GetGUID(), accountId = session->GetAccountId()](PreparedQueryResult result)
        {
            if (!result)
                return;
            Player* current = ObjectAccessor::FindConnectedPlayer(guid);
            if (!current || !current->GetSession() || current->GetSession()->GetAccountId() != accountId ||
                current->GetSession()->IsBot())
                return;
            if (!current->IsInWorld() || !current->FindMap() || current->IsBeingTeleported())
            {
                ScheduleLoginReward(current);
                return;
            }
            CompleteDailyLogin(current, result);
        }));
    }

    void ScheduleLoginReward(Player* player, uint8 attempts)
    {
        player->m_Events.AddEventAtOffset([guid = player->GetGUID(), attempts]()
        {
            Player* current = ObjectAccessor::FindConnectedPlayer(guid);
            if (!current)
                return;
            if (!current->IsInWorld() || !current->FindMap() || current->IsBeingTeleported())
            {
                if (attempts > 1)
                    ScheduleLoginReward(current, attempts - 1);
                return;
            }
            GrantDailyLogin(current);
        }, Milliseconds(5000));
    }

    class DailyLoginWorld final : public WorldScript
    {
    public:
        DailyLoginWorld() : WorldScript("coa_daily_login_world", {WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE}) { }

        void OnUpdate(uint32) override
        {
            std::lock_guard lock(commitLock);
            commits.ProcessReadyCallbacks();
        }

        void OnStartup() override
        {
            rewards.clear();
            auto* read = WorldDatabase.GetPreparedStatement(WORLD_SEL_COA_DAILY_LOGIN_REWARDS);
            PreparedQueryResult result = WorldDatabase.Query(read);
            if (!result)
                return;
            uint64 stacks = 0;
            do
            {
                Field* fields = result->Fetch();
                Reward const reward{fields[0].Get<uint32>(), fields[1].Get<uint32>()};
                ItemTemplate const* item = sObjectMgr->GetItemTemplate(reward.Item);
                if (!item || !reward.Quantity || reward.Quantity > 1000000 || item->GetMaxStackSize() <= 0)
                {
                    rewards.clear();
                    LOG_ERROR("coa.daily_login", "Invalid daily login reward. Rewards disabled.");
                    return;
                }
                stacks += (uint64(reward.Quantity) + item->GetMaxStackSize() - 1) / item->GetMaxStackSize();
                if (stacks > MAX_MAIL_ITEMS)
                {
                    rewards.clear();
                    LOG_ERROR("coa.daily_login", "Daily login rewards exceed one mail's attachment limit.");
                    return;
                }
                rewards.push_back(reward);
            } while (result->NextRow());
        }
    };

    class DailyLoginPlayer final : public PlayerScript
    {
    public:
        DailyLoginPlayer() : PlayerScript("coa_daily_login_player", {PLAYERHOOK_ON_LOGIN}) { }

        void OnPlayerLogin(Player* player) override
        {
            if (!rewards.empty())
                ScheduleLoginReward(player);
        }
    };
}

void AddSC_AscensionDailyLogin()
{
    new DailyLoginWorld();
    new DailyLoginPlayer();
}
