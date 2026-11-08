#include "ManastormClientUIFixes.h"
#include "AscensionClientLua.h"
#include "Config.h"
#include "DataMap.h"
#include "GameTime.h"
#include "ManastormModuleConfig.h"
#include "ManastormRewards.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "WorldSession.h"
#include <string_view>

namespace
{
    constexpr uint32 RequirementTypeId = 24;
    constexpr uint32 RequirementId = 16262;
    constexpr std::string_view Token = "MANASTORM_UI_FIXES";
    constexpr Milliseconds LoginDelay = Milliseconds(5000);

    constexpr char CoALootStateKey[] = "Manastorm.CoALoot.ClientState";
    struct CoALootClientState final : DataMap::Base
    {
        std::string Value;
        uint32 ClockSync = 0;
    };

    constexpr std::string_view CoALootLua = R"lua(
CoAManastormTokenState.receivedAt = GetTime()
local function ApplyCoALootState()
if not ManastormQueueFrame then return end
local queue = ManastormQueueFrame
queue.RewardDiv = queue.RewardDiv or ManastormQueueFrameRewardDiv
if not queue.CoATokenProgress then
    queue.CoATokenProgress = queue:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    queue.CoATokenProgress:SetPoint("TOPLEFT", queue.RewardDiv, "BOTTOMLEFT", 0, -48)
    queue.CoATokenProgress:SetJustifyH("LEFT")
end
if not queue.CoAOriginalUpdateRewards then
    queue.CoAOriginalUpdateRewards = queue.UpdateRewards
    local function Update(self)
        local data = CoAManastormTokenState
        local regular = self.Rewards and self.Rewards[1]
        if not regular then return end
        if not data or not data.enabled then
            if regular.itemID == 975001 then regular:SetItem(97884, 1) end
            if self.CoABonusReward then
                self.CoABonusReward:SetItem(self.CoABonusReward:GetAttribute("item"), 1)
            end
            self.CoATokenProgress:Hide()
            self.LoadoutTitle:ClearAllPoints()
            self.LoadoutTitle:SetPoint("TOPLEFT", self.RewardDiv, "BOTTOMLEFT", 0, -48)
            self.CoAOriginalUpdateRewards(self)
            return
        end
        local elapsed = math.max(0, GetTime() - data.receivedAt)
        local expired = data.finish and data.finish > 0 and data.now + elapsed >= data.finish
        local earned = expired and 0 or (data.earned or 0)
        local remaining = math.max(0, (data.cap or 0) - earned)
        local types = { SOLO=1, DUO=2, TRIO=3, GROUP=4,
            SOLO_END_GAME=1, DUO_END_GAME=2, TRIO_END_GAME=3, GROUP_END_GAME=4 }
        local kind = ManastormUtil.GetManastormType()
        local mode = types[kind] or data.mode or 1
        local track = data.track or 1
        if types[kind] then track = string.find(kind, "END_GAME", 1, true) and 2 or 1 end
        local depth = self.selectedLevel or 1
        local first = not (data.clears and data.clears[mode .. ":" .. track .. ":" .. depth])
        if expired and data.perWindow then first = true end
        local quantity = 0
        for _, rule in ipairs(data.rules or {}) do
            if (rule[1] == 0 or rule[1] == mode) and (rule[2] == 0 or rule[2] == track)
                and depth >= rule[3] and (rule[4] == 0 or depth <= rule[4]) then
                if first and data.first then
                    quantity = rule[5]
                    if rule[7] > 0 and depth % rule[7] == 0 then quantity = quantity + rule[8] end
                elseif not first and data.repeatReward then
                    quantity = rule[6]
                end
                break
            end
        end
        quantity = math.min(quantity + (data.bonusTokens or 0), remaining)
        if regular.itemID ~= 975001 or self.CoATokenQuantity ~= quantity then
            regular:SetItem(975001, quantity)
            self.CoATokenQuantity = quantity
        end
        self.CoAOriginalUpdateRewards(self)
        regular:SetShown(true)
        local seconds = math.max(0, (data.finish or 0) - (data.now or 0) - elapsed)
        regular:SetLocked(data.unavailable or remaining == 0, seconds)
        if not self.CoABonusReward and (data.bonus or 0) > 0 then
            self.CoABonusReward = self.Rewards[4]
        end
        if self.CoABonusReward then
            self.CoABonusReward:SetShown((data.bonus or 0) > 0 and (data.bonusItem or 0) > 0)
            if self.CoABonusReward:IsShown() then
                self.CoABonusReward:SetItem(data.bonusItem, data.bonus)
                self.CoABonusReward:SetLocked(false)
                local previous = regular
                for index, button in ipairs(self.Rewards) do
                    if button ~= self.CoABonusReward and button:IsShown() then previous = button end
                end
                self.CoABonusReward:ClearAllPoints()
                self.CoABonusReward:SetPoint("LEFT", previous, "RIGHT", 8, 0)
            end
        end
        local reset = seconds > 0 and ("Resets in " .. SecondsToTimeAbbrev(seconds))
            or "Reward window starts on completion"
        local label = first and "First clear" or "Repeat clear"
        if data.unavailable then
            self.CoATokenProgress:SetText("Bazaar Token rewards temporarily unavailable")
        else
            self.CoATokenProgress:SetText(string.format("%s: %d tokens  |  %d / %d earned\n%d remaining  |  %s",
                label, quantity, earned, data.cap or 0, remaining, reset))
        end
        self.CoATokenProgress:Show()
        self.LoadoutTitle:ClearAllPoints()
        self.LoadoutTitle:SetPoint("TOPLEFT", self.RewardDiv, "BOTTOMLEFT", 0, -80)
    end
    ManastormQueueMixin.UpdateRewards = Update
    queue.UpdateRewards = Update
    queue:HookScript("OnUpdate", function(self, elapsed)
        self.CoATokenElapsed = (self.CoATokenElapsed or 0) + elapsed
        if self.CoATokenElapsed >= 1 then
            self.CoATokenElapsed = 0
            if CoAManastormTokenState and CoAManastormTokenState.enabled then self:UpdateRewards() end
        end
    end)
end
queue:UpdateRewards()
end
if IsAddOnLoaded("Ascension_Manastorm") then
    ApplyCoALootState()
else
    local loader = CoAManastormTokenLoader or CreateFrame("Frame")
    CoAManastormTokenLoader = loader
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, _, addon)
        if addon == "Ascension_Manastorm" then
            self:UnregisterEvent("ADDON_LOADED")
            ApplyCoALootState()
        end
    end)
end
)lua";

    constexpr std::string_view GroupFinderKeybindLua = R"lua(
function ToggleLFDParentFrame()
    if AscensionPVEFrame:IsVisible() then
        HideUIPanel(AscensionLFGFrame)
    elseif C_Player:GetLevel() >= SHOW_LFD_LEVEL then
        AscensionLFGFrame:ShowFrame("AscensionPVEFrame")
    elseif C_Manastorm.IsInManastorm() or C_Manastorm.CanEnter(1) then
        AscensionLFGFrame:ShowFrame("AscensionPVEFrame")
    end
end
)lua";

    constexpr std::string_view AddonFixesBeginLua = R"lua(
local manastormFixes = {}
local function PatchMethod(mixin, frames, name, method)
    mixin[name] = method
    for _, frame in ipairs(frames) do
        frame[name] = method
    end
end
local function RewardButtons()
    local buttons = {}
    local index = 1
    while _G["ManastormQueueFrameReward" .. index] do
        buttons[index] = _G["ManastormQueueFrameReward" .. index]
        index = index + 1
    end
    return buttons
end
)lua";

    constexpr std::string_view RewardAnchorLua = R"lua(
table.insert(manastormFixes, function()
    ManastormQueueFrame.RewardDiv = ManastormQueueFrameRewardDiv
    if ManastormQueueFrame:IsVisible() then
        ManastormQueueFrame:UpdateRewards()
    end
end)
)lua";

    constexpr std::string_view QueueLevelGuardsLua = R"lua(
table.insert(manastormFixes, function()
    local queue = { ManastormQueueFrame }
    local function GetSortedLevels()
        local levels = {}
        for _, level in ipairs(C_Manastorm.GetEnterableLevels() or {}) do
            levels[#levels + 1] = level
        end
        table.sort(levels, function(left, right) return left > right end)
        return levels
    end
    PatchMethod(ManastormQueueMixin, queue, "RefreshAvailableLevels", function(self)
        self.levels = GetSortedLevels()
        if not self.selectedLevel or not tContains(self.levels, self.selectedLevel) then
            self:SelectHighestLevel()
            return
        end
        local levelSelect = self.RightPanel.LevelSelect
        local wasShown = levelSelect:IsShown()
        for index, level in ipairs(self.levels) do
            if level == self.selectedLevel then
                levelSelect.ScrollList:SetSelectedIndex(index, ScrollListMixin.UpdateType.Always)
                break
            end
        end
        if wasShown then levelSelect:Show() end
        self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
        self:UpdateQueueButton()
    end)
    PatchMethod(ManastormQueueMixin, queue, "SelectHighestLevel", function(self)
        self.levels = GetSortedLevels()
        self.selectedLevel = self.levels[1]
        if not self.selectedLevel then
            self.RightPanel.LevelSelect.ScrollList:RefreshScrollFrame()
            self.RightPanel.LevelDropDown.Text:SetText("")
            self:UpdateQueueButton()
            return
        end
        self.RightPanel.LevelSelect.ScrollList:SetSelectedIndex(1, ScrollListMixin.UpdateType.Always)
        self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
        self:UpdateQueueButton()
    end)
    PatchMethod(ManastormQueueMixin, queue, "HideLevelSelect", function(self)
        self.RightPanel.LevelSelect:Hide()
        if not self.selectedLevel then
            self.RightPanel.LevelDropDown.Text:SetText("")
            return
        end
        self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
    end)
    local enterQueue = ManastormQueueMixin.EnterQueue
    PatchMethod(ManastormQueueMixin, queue, "EnterQueue", function(self)
        if not C_Manastorm.IsInManastorm() and not self.selectedLevel then
            self:UpdateQueueButton()
            return
        end
        return enterQueue(self)
    end)
    local updateQueueButton = ManastormQueueMixin.UpdateQueueButton
    PatchMethod(ManastormQueueMixin, queue, "UpdateQueueButton", function(self)
        if not C_Manastorm.IsInManastorm() and not self.selectedLevel then
            self.RightPanel.EnterButton:SetText(_G["ENTER_MANASTORM_" .. ManastormUtil.GetManastormType()])
            self.RightPanel.EnterButton:Disable()
            self.RightPanel.EnterButton.tooltipTitle = CANNOT_ENTER_MANASTORM
            self.RightPanel.EnterButton.tooltipText = nil
            return
        end
        return updateQueueButton(self)
    end)
    PatchMethod(ManastormPotentialRewardMixin, RewardButtons(), "SetItem", function(self, itemID, count)
        ItemIconTemplateMixin.SetItem(self, itemID, count)
        self.itemID = itemID
        local quality = (self.item and self.item:GetQuality()) or Enum.ItemQuality.Poor
        local atlas = QUICKSLOT_QUALITY_BORDER_ATLAS[quality] or QUICKSLOT_QUALITY_BORDER_ATLAS[Enum.ItemQuality.Poor]
        self:SetBorderAtlas(atlas)
        self:SetOverlayAtlas(atlas)
        self:UpdateRewardVisibility(ManastormUtil.GetRewardVisibilityContext())
    end)
end)
)lua";

    constexpr std::string_view EmptyLoadoutFlyoutLua = R"lua(
table.insert(manastormFixes, function()
    local refreshSpells = ManastormLoadoutFlyoutMixin.RefreshSpells
    PatchMethod(ManastormLoadoutFlyoutMixin, { ManastormLoadoutFlyoutFrame }, "RefreshSpells", function(self)
        local availableSpells, unavailableSpells = C_Manastorm.GetAvailableLoadoutSpells()
        if #(availableSpells or {}) + #(unavailableSpells or {}) == 0 then
            self.buttonPool:ReleaseAll()
            self:Hide()
            return
        end
        return refreshSpells(self)
    end)
end)
)lua";

    constexpr std::string_view AddonFixesEndLua = R"lua(
local function ApplyManastormFixes()
    for _, fix in ipairs(manastormFixes) do
        fix()
    end
end
if IsAddOnLoaded("Ascension_Manastorm") then
    ApplyManastormFixes()
else
    local loader = ManastormUIFixLoader or CreateFrame("Frame")
    ManastormUIFixLoader = loader
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, _, addon)
        if addon == "Ascension_Manastorm" then
            self:UnregisterEvent("ADDON_LOADED")
            ApplyManastormFixes()
        end
    end)
end
)lua";

    constexpr std::string_view NativeObjectiveHighlightLua = R"lua(
local frame = _G.CoAManastormObjectiveHighlight
if not enabled and not frame then return end
if not frame then
    frame = CreateFrame("Frame")
    _G.CoAManastormObjectiveHighlight = frame
end
frame:UnregisterAllEvents()
frame:SetScript("OnUpdate", nil)
frame:SetScript("OnEvent", nil)
frame:Hide()
if not enabled then return end
local function Active()
    return C_Manastorm and type(C_Manastorm.IsInManastorm) == "function"
        and type(C_Manastorm.ShowObjectiveIcon) == "function" and C_Manastorm.IsInManastorm()
end
local function Refresh(self)
    self.elapsed = 0
    if Active() then
        C_Manastorm.ShowObjectiveIcon()
        self:Show()
    else
        self:Hide()
    end
end
frame:SetScript("OnEvent", Refresh)
frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 8 then Refresh(self) end
end)
frame:RegisterEvent("ACTIVE_MANASTORM_UPDATED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("MANASTORM_LEVEL_COMPLETED")
Refresh(frame)
)lua";

    std::string const ObjectiveHighlightStateKey = "ManastormObjectiveHighlightDelivery";

    struct ObjectiveHighlightState final : DataMap::Base
    {
        bool Ready = false;
        bool Enabled = false;
    };

    bool CanPush(Player* player)
    {
        WorldSession* session = player ? player->GetSession() : nullptr;
        return session && !session->IsBot() && ManastormModuleConfig::Enabled() &&
            ManastormModuleConfig::IsNativeClientMode();
    }
}

namespace ManastormClientUIFixes
{
    void SendCoALootState(Player* player, ManastormRun const* run)
    {
        if (!CanPush(player))
            return;
        std::string state = ManastormRewards::Instance().CoATokenClientState(
            player->GetGUID().GetCounter(), run, false);
        auto* previous = player->CustomData.GetDefault<CoALootClientState>(CoALootStateKey);
        if (state == "{enabled=false}" && previous->Value.empty())
            return;
        bool const changed = previous->Value != state;
        uint32 const now = uint32(GameTime::GetGameTime().count());
        if (!changed && (state == "{enabled=false}" ||
            (now >= previous->ClockSync && now - previous->ClockSync < 60)))
            return;
        previous->Value = state;
        previous->ClockSync = now;
        AscensionClientLuaChunk chunk;
        chunk.RequirementTypeId = RequirementTypeId;
        chunk.RequirementId = 16264;
        chunk.Token = "MANASTORM_COA_TOKEN_REWARDS";
        chunk.TargetAddon = "Ascension_Manastorm";
        if (changed)
        {
            chunk.Lua = "CoAManastormTokenState=" + state + "\nCoAManastormTokenState.now=" +
                std::to_string(now) + "\n";
            chunk.Lua.append(CoALootLua);
        }
        else
            chunk.Lua = "if CoAManastormTokenState then CoAManastormTokenState.now=" +
                std::to_string(now) + ";CoAManastormTokenState.receivedAt=GetTime() end";
        RunAscensionClientLua(player, chunk);
    }

    uint32 ConfiguredFixes()
    {
        return sConfigMgr->GetOption<uint32>("Manastorm.ClientUIFixes", 0, false) & FIX_ALL;
    }

    std::string BuildLua(uint32 fixes)
    {
        std::string lua;
        if (fixes & FIX_GROUP_FINDER_KEYBIND)
            lua.append(GroupFinderKeybindLua);

        if (!(fixes & (FIX_REWARD_ANCHOR | FIX_QUEUE_LEVEL_GUARDS | FIX_EMPTY_LOADOUT_FLYOUT)))
            return lua;

        lua.append(AddonFixesBeginLua);
        if (fixes & FIX_REWARD_ANCHOR)
            lua.append(RewardAnchorLua);
        if (fixes & FIX_QUEUE_LEVEL_GUARDS)
            lua.append(QueueLevelGuardsLua);
        if (fixes & FIX_EMPTY_LOADOUT_FLYOUT)
            lua.append(EmptyLoadoutFlyoutLua);
        lua.append(AddonFixesEndLua);
        return lua;
    }

    void SendObjectiveHighlight(Player* player)
    {
        if (!CanPush(player))
            return;
        ObjectiveHighlightState* state = player->CustomData.Get<ObjectiveHighlightState>(ObjectiveHighlightStateKey);
        if (!state || !state->Ready)
            return;
        bool const enabled = ManastormModuleConfig::NativeObjectiveHighlight();
        if (state->Enabled == enabled)
            return;
        state->Enabled = enabled;
        AscensionClientLuaChunk chunk;
        chunk.RequirementTypeId = RequirementTypeId;
        chunk.RequirementId = 16263;
        chunk.Token = "MANASTORM_OBJECTIVE_HIGHLIGHT";
        chunk.Lua = enabled ? "local enabled = true\n" : "local enabled = false\n";
        chunk.Lua.append(NativeObjectiveHighlightLua);
        RunAscensionClientLua(player, chunk);
    }

    void ResetObjectiveHighlight(Player* player)
    {
        if (player)
        {
            player->CustomData.Erase(ObjectiveHighlightStateKey);
            player->CustomData.Erase(CoALootStateKey);
        }
    }

    void ScheduleLoginPush(Player* player)
    {
        if (!CanPush(player))
            return;

        player->CustomData.GetDefault<ObjectiveHighlightState>(ObjectiveHighlightStateKey);
        player->m_Events.AddEventAtOffset([guid = player->GetGUID()]()
        {
            Player* current = ObjectAccessor::FindPlayer(guid);
            uint32 const fixes = ConfiguredFixes();
            if (!CanPush(current))
                return;
            ObjectiveHighlightState* state = current->CustomData.Get<ObjectiveHighlightState>(ObjectiveHighlightStateKey);
            if (!state)
                return;
            state->Ready = true;
            SendObjectiveHighlight(current);
            if (!fixes)
                return;

            AscensionClientLuaChunk chunk;
            chunk.RequirementTypeId = RequirementTypeId;
            chunk.RequirementId = RequirementId;
            chunk.Token = std::string(Token);
            chunk.Lua = BuildLua(fixes);
            RunAscensionClientLua(current, chunk);
        }, LoginDelay);
    }
}
