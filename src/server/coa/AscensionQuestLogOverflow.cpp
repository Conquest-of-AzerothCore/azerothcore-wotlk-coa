#include "AscensionClientLua.h"
#include "Chat.h"
#include "DataMap.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <string>
#include <vector>

namespace QuestLogOverflow
{
namespace
{
constexpr char AddonPrefix[] = "COAQLOG";
constexpr uint32 WindowRequirementType = 25;
constexpr uint32 WindowRequirementRow = 16265;
constexpr char WindowToken[] = "QUEST_LOG_OVERFLOW_WINDOW";
constexpr uint32 RefreshIntervalMs = 1000;
constexpr std::size_t MaxTextLength = 180;
std::string const ViewKey = "CoAQuestLogOverflowView";

struct OverflowView final : DataMap::Base
{
    std::vector<std::string> Sent;
    uint32 SinceRefreshMs = 0;
    bool WindowCodeSent = false;
};

std::string Clip(std::string text)
{
    for (char& character : text)
        if (character == '\t' || character == '\n' || character == '\r')
            character = ' ';
    if (text.size() > MaxTextLength)
        text.resize(MaxTextLength);
    return text;
}

std::string ObjectiveTarget(Quest const* quest, uint8 index)
{
    if (!quest->ObjectiveText[index].empty())
        return quest->ObjectiveText[index];

    int32 const target = quest->RequiredNpcOrGo[index];
    if (target > 0)
    {
        if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(uint32(target)))
            return creature->Name + " slain";
    }
    else if (GameObjectTemplate const* object = sObjectMgr->GetGameObjectTemplate(uint32(-target)))
        return object->name;

    return "Objective";
}

std::string Progress(std::string const& text, uint32 current, uint32 required)
{
    return "O " + Clip(Acore::StringFormat("{}: {}/{}", text, std::min(current, required), required));
}

void AppendObjectives(Player* player, Quest const* quest, uint16 slot, std::vector<std::string>& messages)
{
    for (uint8 index = 0; index < QUEST_OBJECTIVES_COUNT; ++index)
        if (quest->RequiredNpcOrGo[index] && quest->RequiredNpcOrGoCount[index])
            messages.push_back(Progress(ObjectiveTarget(quest, index), player->GetQuestSlotCounter(slot, index),
                quest->RequiredNpcOrGoCount[index]));

    QuestStatusMap& statuses = player->getQuestStatusMap();
    auto const status = statuses.find(quest->GetQuestId());
    for (uint8 index = 0; index < QUEST_ITEM_OBJECTIVES_COUNT; ++index)
    {
        uint32 const itemId = quest->RequiredItemId[index];
        if (!itemId || !quest->RequiredItemCount[index])
            continue;

        ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
        uint32 const owned = status != statuses.end() ? status->second.ItemCount[index] : 0;
        messages.push_back(Progress(item ? item->Name1 : "Item", owned, quest->RequiredItemCount[index]));
    }

    if (uint32 const players = quest->GetPlayersSlain())
    {
        uint32 const slain = status != statuses.end() ? status->second.PlayerCount : 0;
        messages.push_back(Progress("Players slain", slain, players));
    }
}

char StatusCode(QuestStatus status)
{
    if (status == QUEST_STATUS_COMPLETE)
        return 'c';
    if (status == QUEST_STATUS_FAILED)
        return 'f';
    return '-';
}

std::vector<std::string> BuildMessages(Player* player)
{
    std::vector<std::string> quests;
    for (uint16 slot = NATIVE_QUEST_LOG_SIZE; slot < MAX_QUEST_LOG_SIZE; ++slot)
    {
        uint32 const questId = player->GetQuestSlotQuestId(slot);
        Quest const* quest = questId ? sObjectMgr->GetQuestTemplate(questId) : nullptr;
        if (!quest)
            continue;

        quests.push_back(Acore::StringFormat("Q {}\t{}\t{}\t{}", questId, player->GetQuestLevel(quest),
            StatusCode(player->GetQuestStatus(questId)), Clip(quest->GetTitle())));
        AppendObjectives(player, quest, slot, quests);
    }

    if (quests.empty())
        return {};

    uint32 count = 0;
    for (std::string const& message : quests)
        count += message[0] == 'Q' ? 1 : 0;

    std::vector<std::string> messages;
    messages.push_back(Acore::StringFormat("BEGIN {} {}", count, player->GetQuestLogCapacity()));
    messages.insert(messages.end(), quests.begin(), quests.end());
    messages.push_back("END");
    return messages;
}

void SendAddon(Player* player, std::string const& message)
{
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player,
        std::string(AddonPrefix) + "\t" + message);
    player->SendDirectMessage(&packet);
}

constexpr char WindowLua[] = R"lua(
local PREFIX = "COAQLOG"
local f = CoAQuestLogOverflowFrame
local function send(message)
  SendAddonMessage(PREFIX, message, "WHISPER", UnitName("player"))
end

if not f then
  f = CreateFrame("Frame", "CoAQuestLogOverflowFrame", UIParent)
  f:SetSize(360, 420)
  f:SetPoint("CENTER", 200, 0)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  f:Hide()
  tinsert(UISpecialFrames, "CoAQuestLogOverflowFrame")

  f.Title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  f.Title:SetPoint("TOP", 0, -16)
  f.Summary = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  f.Summary:SetPoint("TOP", f.Title, "BOTTOM", 0, -4)
  f.Close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.Close:SetPoint("TOPRIGHT", -6, -6)

  f.Scroll = CreateFrame("ScrollFrame", "CoAQuestLogOverflowScroll", f, "UIPanelScrollFrameTemplate")
  f.Scroll:SetPoint("TOPLEFT", 18, -52)
  f.Scroll:SetPoint("BOTTOMRIGHT", -36, 18)
  f.Content = CreateFrame("Frame", nil, f.Scroll)
  f.Content:SetSize(300, 10)
  f.Scroll:SetScrollChild(f.Content)
  f.Rows = {}

  f.Opener = CreateFrame("Button", "CoAQuestLogOverflowButton", QuestLogFrame, "UIPanelButtonTemplate")
  f.Opener:SetSize(110, 22)
  f.Opener:SetPoint("TOPLEFT", QuestLogFrame, "TOPRIGHT", -2, -40)
  f.Opener:SetScript("OnClick", function() if f:IsShown() then f:Hide() else f:Show() end end)
  f.Opener:Hide()

  StaticPopupDialogs["COA_QUEST_LOG_OVERFLOW_ABANDON"] = {
    text = "Abandon \"%s\"?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, questId) send("ABANDON " .. questId) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
  }

  SLASH_COAEXTRAQUESTS1 = "/extraquests"
  SlashCmdList.COAEXTRAQUESTS = function() if f:IsShown() then f:Hide() else f:Show() end end
end

local function row(index)
  local r = f.Rows[index]
  if r then return r end
  r = CreateFrame("Frame", nil, f.Content)
  r:SetWidth(300)
  r.Name = r:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  r.Name:SetPoint("TOPLEFT", 0, 0)
  r.Name:SetWidth(300)
  r.Name:SetJustifyH("LEFT")
  r.Objectives = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  r.Objectives:SetPoint("TOPLEFT", r.Name, "BOTTOMLEFT", 10, -2)
  r.Objectives:SetWidth(290)
  r.Objectives:SetJustifyH("LEFT")
  r.Move = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  r.Move:SetSize(120, 20)
  r.Move:SetText("Move to Quest Log")
  r.Move:SetScript("OnClick", function(self) send("PROMOTE " .. self:GetParent().QuestId) end)
  r.Abandon = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  r.Abandon:SetSize(80, 20)
  r.Abandon:SetText("Abandon")
  r.Abandon:SetPoint("LEFT", r.Move, "RIGHT", 6, 0)
  r.Abandon:SetScript("OnClick", function(self)
    local parent = self:GetParent()
    local dialog = StaticPopup_Show("COA_QUEST_LOG_OVERFLOW_ABANDON", parent.QuestTitle)
    if dialog then dialog.data = parent.QuestId end
  end)
  f.Rows[index] = r
  return r
end

local function render()
  local quests = f.Quests or {}
  local offset = 0
  for index, quest in ipairs(quests) do
    local r = row(index)
    r.QuestId = quest.id
    r.QuestTitle = quest.title
    local color = GetQuestDifficultyColor(quest.level)
    local suffix = quest.status == "c" and " (Complete)" or (quest.status == "f" and " (Failed)" or "")
    r.Name:SetText("[" .. quest.level .. "] " .. quest.title .. suffix)
    r.Name:SetTextColor(color.r, color.g, color.b)
    r.Objectives:SetText(table.concat(quest.objectives, "\n"))
    local objectiveHeight = #quest.objectives > 0 and r.Objectives:GetStringHeight() or 0
    r.Move:ClearAllPoints()
    r.Move:SetPoint("TOPLEFT", r.Name, "BOTTOMLEFT", 10, -objectiveHeight - 6)
    local height = r.Name:GetStringHeight() + objectiveHeight + 34
    r:SetHeight(height)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 0, -offset)
    r:Show()
    offset = offset + height + 8
  end
  for index = #quests + 1, #f.Rows do f.Rows[index]:Hide() end
  f.Content:SetHeight(math.max(offset, 10))
  f.Title:SetText("Extra Quests")
  local noun = #quests == 1 and " quest" or " quests"
  f.Summary:SetText(#quests .. noun .. " beyond the 25-slot log (" .. (f.Capacity or 25) .. " in total)")
  f.Opener:SetText("Extra Quests (" .. #quests .. ")")
  if #quests > 0 then f.Opener:Show() else f.Opener:Hide(); f:Hide() end
end

f.Shown = f.Shown or {}
local function notify(text)
  local shown = f.Shown[text]
  if not shown or GetTime() - shown > 3 then UIErrorsFrame:AddMessage(text, 1, 1, 0) end
end

local function announce(previous)
  if not previous then return end
  local known = {}
  for _, quest in ipairs(previous) do known[quest.id] = quest end
  for _, quest in ipairs(f.Quests) do
    local before = known[quest.id]
    if not before then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Your quest log is full: " .. quest.title ..
        " was placed in Extra Quests (/extraquests).|r")
    else
      for index, objective in ipairs(quest.objectives) do
        if objective ~= before.objectives[index] then notify(objective) end
      end
      if quest.status == "c" and before.status ~= "c" then notify(format(ERR_QUEST_COMPLETE_S, quest.title)) end
    end
  end
end

f:UnregisterAllEvents()
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("UI_INFO_MESSAGE")
f:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
  if event == "UI_INFO_MESSAGE" then
    self.Shown[prefix] = GetTime()
    return
  end
  if prefix ~= PREFIX or channel ~= "WHISPER" or sender ~= UnitName("player") then return end
  local kind, rest = message:match("^(%u+) ?(.*)$")
  if kind == "BEGIN" then
    local _, capacity = rest:match("^(%d+) (%d+)$")
    self.Capacity = tonumber(capacity)
    self.Pending = {}
  elseif kind == "Q" and self.Pending then
    local id, level, status, title = rest:match("^(%d+)\t(%-?%d+)\t(.)\t(.*)$")
    if id then
      tinsert(self.Pending, { id = tonumber(id), level = tonumber(level), status = status, title = title,
        objectives = {} })
    end
  elseif kind == "O" and self.Pending and #self.Pending > 0 then
    tinsert(self.Pending[#self.Pending].objectives, rest)
  elseif kind == "END" and self.Pending then
    local previous = self.Quests
    self.Quests = self.Pending
    self.Pending = nil
    announce(previous)
    render()
  elseif kind == "EMPTY" then
    self.Quests = {}
    self.Pending = nil
    render()
  elseif kind == "ERROR" then
    UIErrorsFrame:AddMessage(rest, 1, 0.1, 0.1)
  end
end)

send("LIST")
)lua";

class QuestLogOverflowPlayer final : public PlayerScript
{
public:
    QuestLogOverflowPlayer()
        : PlayerScript("coa_quest_log_overflow_player",
            {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT})
    {
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (player->GetSession()->IsHeadlessBot() || !player->IsInWorld())
            return;

        OverflowView* view = player->CustomData.Get<OverflowView>(ViewKey);
        if (!view && !player->HasOverflowQuests())
            return;

        if (!view)
            view = player->CustomData.GetDefault<OverflowView>(ViewKey);

        view->SinceRefreshMs += diff;
        if (view->SinceRefreshMs < RefreshIntervalMs)
            return;

        view->SinceRefreshMs = 0;
        Refresh(player, *view, false);
    }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 language, std::string& message,
        Player* receiver) override
    {
        std::string const prefix = std::string(AddonPrefix) + "\t";
        if (type != CHAT_MSG_WHISPER || language != LANG_ADDON || receiver != player ||
            message.compare(0, prefix.size(), prefix) != 0)
            return true;

        Handle(player, message.substr(prefix.size()));
        return false;
    }

private:
    static void Refresh(Player* player, OverflowView& view, bool force)
    {
        std::vector<std::string> messages = BuildMessages(player);
        if (!messages.empty() && !view.WindowCodeSent)
        {
            view.WindowCodeSent = true;
            RunAscensionClientLua(player, {WindowRequirementType, WindowRequirementRow, WindowToken, WindowLua});
        }

        if (!force && messages == view.Sent)
            return;

        if (messages.empty())
            SendAddon(player, "EMPTY");
        for (std::string const& message : messages)
            SendAddon(player, message);
        view.Sent = std::move(messages);
    }

    static void Handle(Player* player, std::string const& body)
    {
        std::size_t const space = body.find(' ');
        std::string const action = body.substr(0, space);
        uint32 const questId = space != std::string::npos
            ? Acore::StringTo<uint32>(body.substr(space + 1)).value_or(0)
            : 0;
        uint16 const slot = questId ? player->FindQuestSlot(questId) : MAX_QUEST_LOG_SIZE;
        bool const overflow = slot >= NATIVE_QUEST_LOG_SIZE && slot < MAX_QUEST_LOG_SIZE;

        if (action == "PROMOTE" && overflow && !player->PromoteQuestToNativeLog(questId))
            SendAddon(player, "ERROR Your quest log has no quest that can make room.");
        else if (action == "ABANDON" && overflow)
            player->GetSession()->AbandonQuestLogSlot(slot);

        Refresh(player, *player->CustomData.GetDefault<OverflowView>(ViewKey), action == "LIST");
    }
};
}
}

void AddSC_AscensionQuestLogOverflow()
{
    new QuestLogOverflow::QuestLogOverflowPlayer();
}
