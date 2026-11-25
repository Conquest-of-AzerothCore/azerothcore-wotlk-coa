-- World map: hovering a zone also shows its wild mob level range and the level of its battle pets.
-- Data: ZoneLevels.lua (generated from the server's zone table).
local mine = false   -- true while the description line shows OUR text
local function Hook()
    if not WorldMapButton or not WorldMapFrameAreaLabel or not WorldMapFrameAreaDescription then return end
    WorldMapButton:HookScript("OnUpdate", function()
        local z = WotlkPetZoneLevels and WotlkPetZoneLevels[WorldMapFrameAreaLabel:GetText() or ""]
        if not z or not WorldMapFrameAreaLabel:IsShown() then
            if mine then mine = false; WorldMapFrameAreaDescription:SetText(""); WorldMapFrameAreaDescription:Hide() end   -- over water / outside a zone: our line goes away
            return
        end
        mine = true
        local pets = z[1] == z[2] and tostring(z[1]) or (z[1] .. "-" .. z[2])
        WorldMapFrameAreaDescription:SetText(string.format("Creatures %d-%d   |   Battle pets %s", z[3], z[4], pets))
        WorldMapFrameAreaDescription:SetTextColor(1, 0.82, 0)
        WorldMapFrameAreaDescription:Show()
    end)
end
local f = CreateFrame("Frame"); f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() Hook() end)
