/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionBazaarTokenCap.h"
#include "AscensionClientLua.h"
#include "Chat.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <string>

namespace
{
constexpr char AddonPrefix[] = "COABTCAP";
constexpr char StateRequest[] = "STATE";
constexpr char NoOpenWindow[] = "NONE";
constexpr uint32 QuestRewardsRequirementType = 26;
constexpr uint32 QuestRewardsRequirementRow = 16266;
constexpr char QuestRewardsToken[] = "BAZAAR_TOKEN_CAP_QUEST_REWARDS";
constexpr Milliseconds LoginLuaDelay = 5s;

constexpr char QuestRewardsLua[] = R"lua(
if not CoABazaarTokenCapQuestRewards then
  local PREFIX = "COABTCAP"
  local TOKEN_ITEM = 975001
  local state = { remaining = nil, endsAt = 0 }
  CoABazaarTokenCapQuestRewards = state

  local function remainingNow()
    if state.remaining and GetTime() < state.endsAt then
      return state.remaining
    end
  end

  local function rewardItemId(button)
    local link
    if QuestInfoFrame.questLog then
      link = GetQuestLogItemLink("reward", button:GetID())
    else
      link = GetQuestItemLink("reward", button:GetID())
    end
    return link and tonumber(link:match("item:(%d+)"))
  end

  local function adjustTokenRewards()
    local remaining = remainingNow()
    if not remaining then
      return
    end
    for index = 1, MAX_NUM_ITEMS do
      local button = _G["QuestInfoItem" .. index]
      if button and button:IsShown() and button.type == "reward" and button.rewardType == "item"
        and rewardItemId(button) == TOKEN_ITEM then
        if remaining == 0 then
          button:Hide()
        elseif button.count and button.count > remaining then
          SetItemButtonCount(button, remaining)
        end
      end
    end
  end

  local function redrawQuestRewards()
    local choice = QuestInfoFrame.itemChoice
    if not pcall(QuestInfo_ShowRewards) then
      return
    end
    if choice and choice > 0 then
      for index = 1, MAX_NUM_ITEMS do
        local button = _G["QuestInfoItem" .. index]
        if button and button:IsShown() and button.type == "choice" and button:GetID() == choice then
          QuestInfoItem_OnClick(button)
        end
      end
    end
  end

  local function limitTokenAmounts(template)
    local remaining = remainingNow()
    if not remaining or type(template) ~= "table" or type(template.RewardItems) ~= "table"
      or type(template.RewardAmount) ~= "table" then
      return template
    end
    local limited = {}
    for key, value in pairs(template) do
      limited[key] = value
    end
    limited.RewardAmount = {}
    for index, amount in pairs(template.RewardAmount) do
      if template.RewardItems[index] == TOKEN_ITEM and type(amount) == "number" then
        limited.RewardAmount[index] = math.min(amount, remaining)
      else
        limited.RewardAmount[index] = amount
      end
    end
    return limited
  end

  if type(GetQuestTemplate) == "function" then
    local getQuestTemplate = GetQuestTemplate
    GetQuestTemplate = function(...)
      return limitTokenAmounts(getQuestTemplate(...))
    end
  end

  local function refreshCallBoard()
    if CallBoardUI and CallBoardUI.questRewards then
      CallBoardUI.questRewards = {}
      if CallBoardUI:IsShown() and CallBoardUI.LoadRewards then
        pcall(CallBoardUI.LoadRewards, CallBoardUI)
      end
    end
  end

  local events = CreateFrame("Frame")
  events:RegisterEvent("CHAT_MSG_ADDON")
  events:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    if prefix ~= PREFIX or sender ~= UnitName("player") then
      return
    end
    local before = remainingNow()
    local remaining, seconds = message:match("^(%d+) (%d+)$")
    if remaining then
      state.remaining = tonumber(remaining)
      state.endsAt = GetTime() + tonumber(seconds)
    else
      state.remaining = nil
    end
    if QuestInfoFrame:IsVisible() then
      local after = remainingNow()
      if before and (not after or after > before) then
        redrawQuestRewards()
      end
      adjustTokenRewards()
    end
    refreshCallBoard()
  end)

  hooksecurefunc("QuestInfo_Display", adjustTokenRewards)
  SendAddonMessage(PREFIX, "STATE", "WHISPER", UnitName("player"))
end
)lua";

void SendAddon(Player* player, std::string const& body)
{
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player,
        std::string(AddonPrefix) + "\t" + body);
    player->SendDirectMessage(&packet);
}

bool IsStateRequest(Player* player, uint32 type, uint32 language, std::string const& message, Player* receiver)
{
    return type == CHAT_MSG_WHISPER && language == LANG_ADDON && receiver == player &&
        message == std::string(AddonPrefix) + "\t" + StateRequest;
}
}

void AscensionBazaarTokenCap::SendClientState(Player* player)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot() || !GetCap())
        return;

    uint32 remaining = 0;
    uint32 secondsLeft = 0;
    if (GetOpenWindow(player->GetSession()->GetAccountId(), remaining, secondsLeft))
        SendAddon(player, Acore::StringFormat("{} {}", remaining, secondsLeft));
    else
        SendAddon(player, NoOpenWindow);
}

class AscensionBazaarTokenCapQuestRewardsPlayer final : public PlayerScript
{
public:
    AscensionBazaarTokenCapQuestRewardsPlayer()
        : PlayerScript("coa_bazaar_token_cap_quest_rewards_player",
            {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT})
    {
    }

    void OnPlayerLogin(Player* player) override
    {
        if (player->GetSession()->IsBot() || !AscensionBazaarTokenCap::GetCap())
            return;

        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([guid]()
        {
            Player* player = ObjectAccessor::FindPlayer(guid);
            if (player && player->IsInWorld())
                RunAscensionClientLua(player,
                    {QuestRewardsRequirementType, QuestRewardsRequirementRow, QuestRewardsToken, QuestRewardsLua});
        }, LoginLuaDelay);
    }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 language, std::string& message, Player* receiver) override
    {
        if (!IsStateRequest(player, type, language, message, receiver))
            return true;

        AscensionBazaarTokenCap::SendClientState(player);
        return false;
    }
};

void AddSC_AscensionBazaarTokenCapQuestRewards()
{
    new AscensionBazaarTokenCapQuestRewardsPlayer();
}
