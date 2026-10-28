ManastormQueueMixin = {}

function ManastormQueueMixin:OnLoad()
    self:RegisterEvent("ENTER_MANASTORM_RESULT")
    self:RegisterEvent("LEAVE_MANASTORM_RESULT")
    self.Background:SetAtlas("manastorm-background", Const.TextureKit.IgnoreAtlasSize)
    self.levels = {}

    self.RightPanel.LevelDropDown.Button:SetScript("OnClick", GenerateClosure(self.ToggleLevelSelect, self))
    self.RightPanel.LevelSelect.ScrollList:SetGetNumResultsFunction(function() return #self.levels end)
    self.RightPanel.LevelSelect:SetFrameLevel(self:GetFrameLevel()+30)
    
    self.CurrencyBar:AddCurrency(1297307, true) -- Bedlam Bullions
    self.CurrencyBar:AddCurrency(1297308, true) -- Bonzo Bolts
    self.CurrencyBar:UseDynamicWidth(true)
end

function ManastormQueueMixin:OnShow()
    local parent = self:GetParent():GetParent()
    PortraitFrame_SetIcon(parent, "Interface\\LFGFrame\\lfgicon-arcanevaults")
    PortraitFrame_SetTitle(parent, ENTER_THE_MANASTORM)
    
    parent:SetSize(860, parent.BASE_HEIGHT)

    self.selectedLevel = nil
    self:RefreshAvailableLevels()
    self:RefreshHighestLevels()
    self:UpdateQueueButton()
    self:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self:RegisterEvent("RAID_ROSTER_UPDATE")
    self:RegisterEvent("MAX_COMPLETED_MANASTORM_LEVEL_UPDATED")
    self:RegisterEvent("MAX_COMPLETED_MANASTORM_SOLO_LEVEL_UPDATED")
    self:RegisterEvent("MAX_COMPLETED_MANASTORM_DUO_LEVEL_UPDATED")
    self:RegisterEvent("MAX_COMPLETED_MANASTORM_TRIO_LEVEL_UPDATED")
    self:RegisterEvent("MAX_COMPLETED_MANASTORM_GROUP_LEVEL_UPDATED")
    self:RegisterEvent(ManastormUtil.RewardVisibilityUpdatedEvent)

    self:UpdateRewards()

    if C_Config.GetBoolConfig("CONFIG_MANASTORM_LOADOUTS_ENABLED") then
        self.LoadoutTitle:Show()
        self.LoadoutAbout:Show()
        self.LoadoutDiv:Show()
        self.Loadout:Show()
    else
        self.LoadoutTitle:Hide()
        self.LoadoutAbout:Hide()
        self.LoadoutDiv:Hide()
        self.Loadout:Hide()
    end
end

function ManastormQueueMixin:OnHide()
    StaticPopup_Hide("LEAVE_THE_MANASTORM_CONFIRM")
    StaticPopup_Hide("LEAVE_THE_MANASTORM_CHECKPOINT_CONFIRM")
    StaticPopup_Hide("GENERIC_CONFIRM")
    self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
    self:UnregisterEvent("RAID_ROSTER_UPDATE")
    self:UnregisterEvent("MAX_COMPLETED_MANASTORM_LEVEL_UPDATED")
    self:UnregisterEvent("MAX_COMPLETED_MANASTORM_SOLO_LEVEL_UPDATED")
    self:UnregisterEvent("MAX_COMPLETED_MANASTORM_DUO_LEVEL_UPDATED")
    self:UnregisterEvent("MAX_COMPLETED_MANASTORM_TRIO_LEVEL_UPDATED")
    self:UnregisterEvent("MAX_COMPLETED_MANASTORM_GROUP_LEVEL_UPDATED")
    self:UnregisterEvent(ManastormUtil.RewardVisibilityUpdatedEvent)
    if ManastormLoadoutFlyoutFrame:IsShown() then
        ManastormLoadoutFlyoutFrame:Hide()
    end
end

function ManastormQueueMixin:OnEvent(event, ...)
    self:UpdateQueueButton()
    if event == ManastormUtil.RewardVisibilityUpdatedEvent then
        self:UpdateRewards()
    elseif event == "LEAVE_MANASTORM_RESULT" then
        local result = ...
        C_Logger.Info("LEAVE_MANASTORM_RESULT: %s", result)
        if result == "LEAVE_MANASTORM_OK" then
            return HideUIPanel(AscensionLFGFrame)
        end

        self:ShowError(CANNOT_LEAVE_MANASTORM, _G[result] or result)
    elseif event == "ENTER_MANASTORM_RESULT" then
        local result = ...
        C_Logger.Info("ENTER_MANASTORM_RESULT: %s", result)
        if result == "ENTER_MANASTORM_OK" then
            return HideUIPanel(AscensionLFGFrame)
        end

        self:ShowError(CANNOT_ENTER_MANASTORM, _G[result] or result)
    else
        self:RefreshHighestLevels()
    end
end

function ManastormQueueMixin:UpdateRewards()
    local wildcard = C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
    local context = ManastormUtil.GetRewardVisibilityContext()
    local previousReward

    for i, reward in ipairs(self.Rewards) do
        local shouldShow = wildcard or i < 4
        if shouldShow then
            shouldShow = not reward:UpdateRewardVisibility(context)
        else
            reward:SetLocked(false)
        end

        reward:SetShown(shouldShow)
        if shouldShow then
            reward:ClearAllPoints()
            if previousReward then
                reward:SetPoint("LEFT", previousReward, "RIGHT", 8, 0)
            else
                reward:SetPoint("TOPLEFT", self.RewardDiv, "BOTTOMLEFT", 0, -4)
            end
            previousReward = reward
        end
    end
end

function ManastormQueueMixin:RefreshAvailableLevels()
    self.levels = C_Manastorm.GetEnterableLevels() or {}
    if not self.selectedLevel or not tContains(self.levels, self.selectedLevel) then
        self:SelectHighestLevel()
        return
    else
        self.RightPanel.LevelSelect.ScrollList:RefreshScrollFrame()
    end
    self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
end

function ManastormQueueMixin:SelectHighestLevel()
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
end

function ManastormQueueMixin:ToggleLevelSelect()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
    if self.RightPanel.LevelSelect:IsShown() then
        self:HideLevelSelect()
    else
        self:ShowLevelSelect()
    end
end 

function ManastormQueueMixin:RefreshHighestLevels()
    local _, solo, duo, trio, group = C_Manastorm.GetMaxCompletedLevels("player")
    self.RightPanel.HighestSolo.Text:SetText(solo)
    self.RightPanel.HighestDuo.Text:SetText(duo)
    self.RightPanel.HighestTrio.Text:SetText(trio)
    self.RightPanel.HighestGroup.Text:SetText(group)

    self.maxLevelInGroup = false
    local endGamePlayerLevel = ManastormUtil.GetEndGamePlayerLevel()
    for unit in GroupUtil.EnumerateGroupMembers() do
        if UnitLevel(unit) >= endGamePlayerLevel then
            self.maxLevelInGroup = true
            break
        end
    end
end

function ManastormQueueMixin:ShowLevelSelect()
    self.RightPanel.LevelSelect:Show()
    self.RightPanel.LevelSelect.ScrollList:SetTemplate("ManastormLevelScrollListItemTemplate")
    self:RefreshAvailableLevels()
end 

function ManastormQueueMixin:HideLevelSelect()
    self.RightPanel.LevelSelect:Hide()
    if not self.selectedLevel then
        self.RightPanel.LevelDropDown.Text:SetText("")
        return
    end
    self.RightPanel.LevelDropDown.Text:SetFormattedText(UNIT_LEVEL_TEMPLATE, self.selectedLevel)
end 

function ManastormQueueMixin:EnterQueue()
    if C_Manastorm.IsInManastorm() then
        ManastormUtil.ShowLeaveManastormDialog()
    else
        if not self.selectedLevel then
            self:UpdateQueueButton()
            return
        end
        if not ManastormUtil.IsLoadoutFilled() then
            StaticPopup_GenericConfirm(MANASTORM_SPELL_LOADOUT_MISSING, nil, nil, YES, CANCEL, GenerateClosure(C_Manastorm.Enter, self.selectedLevel))
            return
        end

        if C_Player:IsHero() and not C_PrimaryStat:GetActivePrimaryStat() then
            ShowForcedPrimaryStat()
            return
        end
        C_Manastorm.Enter(self.selectedLevel)
        self.RightPanel.EnterButton:Disable()
    end
end

function ManastormQueueMixin:ShowError(title, text)
    self.Error:Show()
    self.Error:SetText(title or "", text or "")
end

function ManastormQueueMixin:UpdateQueueButton()
    if C_Manastorm.IsInManastorm() then
        self.RightPanel.EnterButton:SetText(LEAVE_THE_MANASTORM)
        local canLeave, reasons = C_Manastorm.CanLeave()
        self.RightPanel.EnterButton:SetEnabled(canLeave)
        if not canLeave then
            self.RightPanel.EnterButton.tooltipTitle = CANNOT_LEAVE_MANASTORM
            for i, reason in ipairs(reasons) do
                reasons[i] = _G[reason] or reason
            end
            self.RightPanel.EnterButton.tooltipText = RED_FONT_COLOR:WrapText(table.concat(reasons, "\n"))
        else
            self.RightPanel.EnterButton.tooltipTitle = nil
            self.RightPanel.EnterButton.tooltipText = nil
        end
    else
        local manastormType = ManastormUtil.GetManastormType()
        self.RightPanel.EnterButton:SetText(_G["ENTER_MANASTORM_"..manastormType])
        if not self.selectedLevel then
            self.RightPanel.EnterButton:Disable()
            self.RightPanel.EnterButton.tooltipTitle = CANNOT_ENTER_MANASTORM
            self.RightPanel.EnterButton.tooltipText = nil
            return
        end
        local canEnter, reasons, ineligilbeUnits = C_Manastorm.CanEnter(self.selectedLevel)
        self.RightPanel.EnterButton:SetEnabled(canEnter)
        if not canEnter then
            self.RightPanel.EnterButton.tooltipTitle = CANNOT_ENTER_MANASTORM
            for i, reason in ipairs(reasons) do
                reasons[i] = _G[reason] or reason
            end
            if ineligilbeUnits then
                for i, unit in ipairs(ineligilbeUnits) do
                    ineligilbeUnits[i] = UnitName(unit)
                end
                table.insert(reasons, "|n" .. PLAYERS_INELIGIBLE_FOR_MANASTORM_LEVEL:format(table.concat(ineligilbeUnits, ", ")))
            end
            self.RightPanel.EnterButton.tooltipText = RED_FONT_COLOR:WrapText(table.concat(reasons, "\n"))
        else
            self.RightPanel.EnterButton.tooltipTitle = nil
            self.RightPanel.EnterButton.tooltipText = nil
        end
    end
end

function ManastormQueueMixin:OnMouseDown()
    if ManastormLoadoutFlyoutFrame:IsVisible() then
        ManastormLoadoutFlyoutFrame:Hide()
    end
end

--
-- Level Scroll Item
--
ManastormLevelScrollListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function ManastormLevelScrollListItemMixin:OnLoad()
    self.parent = ManastormQueueFrame
end

function ManastormLevelScrollListItemMixin:Update()
    local level = self.parent.levels[self.index]
    if C_Player:GetLevel() >= ManastormUtil.GetEndGamePlayerLevel() then
        self.Text:SetFormattedText(TOOLTIP_UNIT_LEVEL, HIGHLIGHT_FONT_COLOR:WrapText(level))
    else
        local expModifier = C_Manastorm.GetExperienceModifier(self.parent.maxLevelInGroup and 2 or 0, level)
        expModifier = (expModifier - 1) * 100

        local xp = HIGHLIGHT_FONT_COLOR:WrapText(format("+%.1f%% "..XP, expModifier))
        self.Text:SetFormattedText(TOOLTIP_UNIT_LEVEL_TYPE, HIGHLIGHT_FONT_COLOR:WrapText(level), xp)
    end
end

function ManastormLevelScrollListItemMixin:OnSelected()
    self.parent.selectedLevel = self.parent.levels[self.index]
    self.parent:UpdateQueueButton()
    self.parent:HideLevelSelect()
end

--
-- Potential Reward Mixin
--
ManastormPotentialRewardMixin = CreateFromMixins(ItemIconTemplateMixin)

function ManastormPotentialRewardMixin:OnLoad()
    ItemIconTemplateMixin.OnLoad(self)
    SetParentArray(self, "Rewards", self:GetID())
    self:SetBorderSize(40, 40)
    self:SetOverlaySize(40, 40)
    self:SetOverlayBlendMode("ADD")
    self:SetItem(self:GetAttribute("item"), self:GetAttribute("count") or 1)
end

function ManastormPotentialRewardMixin:OnHide()
    self:StopLockTicker()
end

function ManastormPotentialRewardMixin:SetItem(itemID, count)
    ItemIconTemplateMixin.SetItem(self, itemID, count)
    self.itemID = itemID
    local quality = (self.item and self.item:GetQuality()) or Enum.ItemQuality.Poor
    local atlas = QUICKSLOT_QUALITY_BORDER_ATLAS[quality] or QUICKSLOT_QUALITY_BORDER_ATLAS[Enum.ItemQuality.Poor]
    self:SetBorderAtlas(atlas)
    self:SetOverlayAtlas(atlas)
    self:UpdateRewardVisibility(ManastormUtil.GetRewardVisibilityContext())
end

function ManastormPotentialRewardMixin:UpdateRewardVisibility(context)
    local action, remainingSeconds = ManastormUtil.GetRewardVisibilityAction(context, self.itemID)
    if action == ManastormUtil.RewardDisplayAction.Hide then
        self:SetLocked(false)
        return true
    end

    self:SetLocked(action == ManastormUtil.RewardDisplayAction.LockedRateLimitExhausted, remainingSeconds)
    return false
end

function ManastormPotentialRewardMixin:SetLocked(locked, remainingSeconds)
    self.locked = locked
    self:SetIconDesaturated(locked)
    self:SetBorderDesaturated(locked)
    if locked then
        self.LockedOverlay:Show()
        self.LockedIcon:Show()
    else
        self.LockedOverlay:Hide()
        self.LockedIcon:Hide()
    end

    if not locked then
        self.lockExpirationTime = nil
        self.LockTime:SetText("")
        self:StopLockTicker()
        return
    end

    if remainingSeconds and remainingSeconds > 0 then
        self.lockExpirationTime = GetTime() + remainingSeconds
        self:UpdateLockTime()
        self:StartLockTicker()
    else
        self.lockExpirationTime = nil
        self.LockTime:SetText("")
        self:StopLockTicker()
    end
end

function ManastormPotentialRewardMixin:StartLockTicker()
    if self.lockTicker then
        return
    end

    self.lockTicker = Timer.NewTicker(1, function()
        self:UpdateLockTime()
    end)
end

function ManastormPotentialRewardMixin:StopLockTicker()
    if self.lockTicker then
        self.lockTicker:Cancel()
        self.lockTicker = nil
    end
end

function ManastormPotentialRewardMixin:UpdateLockTime()
    if not self.lockExpirationTime then
        self.LockTime:SetText("")
        return
    end

    local secondsRemaining = math.ceil(self.lockExpirationTime - GetTime())
    if secondsRemaining <= 0 then
        self.LockTime:SetText("")
        self:StopLockTicker()
        return
    end

    self.LockTime:SetText(SecondsToTimeAbbrev(secondsRemaining))
end
