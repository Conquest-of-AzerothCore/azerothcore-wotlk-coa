#include "ManastormClientUIFixes.h"
#include "AscensionClientLua.h"
#include "Config.h"
#include "DataMap.h"
#include "ManastormModuleConfig.h"
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
    PatchMethod(ManastormQueueMixin, queue, "RefreshAvailableLevels", function(self)
        self.levels = C_Manastorm.GetEnterableLevels() or {}
        if not self.selectedLevel or not tContains(self.levels, self.selectedLevel) then
            self:SelectHighestLevel()
            return
        else
            self.RightPanel.LevelSelect.ScrollList:RefreshScrollFrame()
        end
        self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
    end)
    PatchMethod(ManastormQueueMixin, queue, "SelectHighestLevel", function(self)
        self.levels = C_Manastorm.GetEnterableLevels() or {}
        self.selectedLevel = self.levels[1]
        if not self.selectedLevel then
            self.RightPanel.LevelSelect.ScrollList:RefreshScrollFrame()
            self.RightPanel.LevelDropDown.Text:SetText("")
            self:UpdateQueueButton()
            return
        end
        self.RightPanel.LevelSelect.ScrollList:SetSelectedIndex(1, ScrollListMixin.UpdateType.Always)
        self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
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
            player->CustomData.Erase(ObjectiveHighlightStateKey);
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
