ManastormLoadoutFlyoutMixin = {}

function ManastormLoadoutFlyoutMixin:OnLoad()
    self.buttonPool = CreateFramePool("Button", self.Buttons, "ManastormLoadoutFlyoutButtonTemplate")
end 

function ManastormLoadoutFlyoutMixin:OnHide()
    if self.button then
        self.button:ClearSelected()
    end
    self.button = nil
    self.buttonPool:ReleaseAll()
end

function ManastormLoadoutFlyoutMixin:IsOwnedBy(button)
    return self.button == button
end

function ManastormLoadoutFlyoutMixin:Open(button)
    self.button = button
    self.button:SetSelected()
    self.Buttons:ClearAndSetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 0)
    self:Show()
    self:ClearAndSetPoint("CENTER", button, "CENTER", 0, 0)
    self:RefreshSpells()
end

function ManastormLoadoutFlyoutMixin:OnButtonClicked(button)
    if button.spell then
        C_Manastorm.SetLoadoutSpellAtIndex(self.button:GetID(), button.spell.spellID)
    end
    self:Hide()
end

function ManastormLoadoutFlyoutMixin:RefreshSpells()
    self.buttonPool:ReleaseAll()
    local availableSpells, unavailableSpells = C_Manastorm.GetAvailableLoadoutSpells()
    local numAvailableSpells = #availableSpells
    local numItems = numAvailableSpells + #unavailableSpells
    if numItems == 0 then
        self:Hide()
        return
    end
    local numColumns = 6
    local offset = 0

    local width, height
    for i = 1, numItems do
        local button = self.buttonPool:Acquire()
        if i <= numAvailableSpells then
            button:SetSpell(availableSpells[i])
            button:Enable()
            button:SetDesaturated(false)
        else
            button:SetSpell(unavailableSpells[i - numAvailableSpells])
            button:Disable()
            button:SetDesaturated(true)
        end

        if i == numAvailableSpells + 1 and numAvailableSpells > 0 then
            local columnsToNextRow = ((i - 1) % numColumns)
            if columnsToNextRow > 0 then
                offset = numColumns - columnsToNextRow
            end
        end

        button:Show()

        if not width then
            width, height = button:GetSize()
        end
        
        -- position in rows 
        local row = math.ceil((i + offset) / numColumns)
        local column = (i + offset) % numColumns
        if column == 0 then
            column = numColumns
        end

        row = row - 1
        column = column - 1

        button:SetPoint("TOPLEFT", self.Buttons, "TOPLEFT", column * width, row * -height)
    end

    numItems = numItems + offset
    numColumns = math.min(numItems, numColumns)
    local fullWidth = numColumns * width
    local fullHeight = math.ceil(numItems / numColumns) * height
    self.Buttons:SetSize(fullWidth, fullHeight)
end

ManastormLoadoutFlyoutButtonMixin = CreateFromMixins("SpellIconTemplateMixin")

function ManastormLoadoutFlyoutButtonMixin:OnClick()
    if self:IsEnabled() == 1 then
        self:GetParent():GetParent():OnButtonClicked(self)
    end
end