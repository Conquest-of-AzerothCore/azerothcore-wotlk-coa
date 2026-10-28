CoAHeirloomArmorTooltip = {}

local HEIRLOOM_QUALITY = 7

local auctionArmorTypes = { GetAuctionItemSubClasses(2) }

local armorTypes = {
    { name = ITEM_SUBCLASS_4_1 or auctionArmorTypes[2] or "Cloth", spellID = 9078, skill = "Cloth" },
    { name = ITEM_SUBCLASS_4_2 or auctionArmorTypes[3] or "Leather", spellID = 9077, skill = "Leather" },
    { name = ITEM_SUBCLASS_4_3 or auctionArmorTypes[4] or "Mail", spellID = 8737, skill = "Mail" },
    { name = ITEM_SUBCLASS_4_4 or auctionArmorTypes[5] or "Plate", spellID = 750, skill = "Plate Mail" },
}

local armorTypeByName = {}
for _, armorType in ipairs(armorTypes) do
    armorTypeByName[armorType.name] = armorType
end

local function HasSkillLine(skillName)
    for index = 1, GetNumSkillLines() do
        local name, isHeader = GetSkillLineInfo(index)
        if not isHeader and name == skillName then
            return true
        end
    end
    return false
end

function CoAHeirloomArmorTooltip.CanWear(armorType)
    if IsSpellKnown and IsSpellKnown(armorType.spellID) then
        return true
    end
    local spellName = GetSpellInfo(armorType.spellID)
    return HasSkillLine(spellName or armorType.skill) or HasSkillLine(armorType.skill)
end

function CoAHeirloomArmorTooltip.FixArmorTypeLine(tooltip)
    local _, link = tooltip:GetItem()
    if not link then
        return
    end

    local _, _, quality, _, _, _, itemSubType = GetItemInfo(link)
    local realType = quality == HEIRLOOM_QUALITY and armorTypeByName[itemSubType]
    if not realType then
        return
    end

    local tooltipName = tooltip:GetName()
    for index = 2, tooltip:NumLines() do
        local right = _G[tooltipName .. "TextRight" .. index]
        if right and right:IsShown() and armorTypeByName[right:GetText()] then
            right:SetText(realType.name)
            if CoAHeirloomArmorTooltip.CanWear(realType) then
                right:SetTextColor(1, 1, 1)
            else
                right:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
            end
            tooltip:Show()
            return
        end
    end
end

for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3 }) do
    if tooltip then
        tooltip:HookScript("OnTooltipSetItem", CoAHeirloomArmorTooltip.FixArmorTypeLine)
    end
end
