local prefix = "COACrows"
local locations = {}
local pending
local buttons = {}
local bounds = {
    Tanaris = {-218, -7118, -5875, -10475},
    Silithus = {2537, -945, -5958, -8281},
    ThousandNeedles = {-433, -4833, -3966, -6900},
    Barrens = {2622, -7510, 1612, -5143},
    Kalimdor = {17066, -19733, 12799, -11733},
}
local elapsed = 0
local lastRequest = -30

local function Leave(self)
    if WorldMapPOI_OnLeave then
        WorldMapPOI_OnLeave(self)
    end
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end

local function Enter(self)
    if WorldMapPOI_OnEnter then
        WorldMapPOI_OnEnter(self)
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Crow's Cache", 1, 0.82, 0)
    GameTooltip:AddLine("High-Risk 60 PvP Event", 1, 1, 1, true)
    GameTooltip:Show()
end

local function Button(index)
    if buttons[index] then
        return buttons[index]
    end
    local button = CreateFrame("Button", "CoACrowsCacheMarker" .. index, WorldMapButton)
    button:SetWidth(80)
    button:SetHeight(80)
    button:SetFrameLevel(WorldMapButton:GetFrameLevel() + 20)
    button.name = "Crow's Cache"
    button.description = "High-Risk 60 PvP Event"
    button:SetScript("OnEnter", Enter)
    button:SetScript("OnLeave", Leave)
    button:SetScript("OnHide", Leave)
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetWidth(55)
    texture:SetHeight(55)
    texture:SetPoint("CENTER", button, "CENTER", 0, 0)
    texture:SetTexture("Interface\\Minimap\\ObjectIconsAtlas")
    texture:SetTexCoord(0.198242, 0.247070, 0.440430, 0.489258)
    buttons[index] = button
    return button
end

local function Render()
    local area = bounds[GetMapInfo()]
    local count = 0
    if WorldMapFrame:IsShown() and area then
        for _, point in pairs(locations) do
            if point.map == 1 then
                local x = (point.y - area[1]) / (area[2] - area[1])
                local y = (point.x - area[3]) / (area[4] - area[3])
                if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                    count = count + 1
                    local button = Button(count)
                    button:ClearAllPoints()
                    button:SetPoint("CENTER", WorldMapButton, "TOPLEFT",
                        x * WorldMapDetailFrame:GetWidth(), -y * WorldMapDetailFrame:GetHeight())
                    button:Show()
                end
            end
        end
    end
    for index = count + 1, #buttons do
        buttons[index]:Hide()
    end
end

local function Request()
    local name = UnitName("player")
    local now = GetTime()
    if name and now - lastRequest >= 1 then
        lastRequest = now
        SendAddonMessage(prefix, "SYNC", "WHISPER", name)
    end
end

local function Receive(message)
    if message == "B" then
        pending = {}
        return
    end
    if message == "E" then
        if pending then
            locations = pending
            pending = nil
        end
    else
        local removed = message:match("^D;(%d+)$")
        if removed then
            locations[tonumber(removed)] = nil
            if pending then
                pending[tonumber(removed)] = nil
            end
        else
            local id, map, x, y = message:match("^P;(%d+);(%d+);([^;]+);([^;]+)$")
            id, map, x, y = tonumber(id), tonumber(map), tonumber(x), tonumber(y)
            if id and map == 1 and x and y and x == x and y == y
                and math.abs(x) <= 17000 and math.abs(y) <= 17000 then
                (pending or locations)[id] = {map = map, x = x, y = y}
            else
                return
            end
        end
    end
    Render()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("WORLD_MAP_UPDATE")
events:RegisterEvent("CHAT_MSG_ADDON")
events:SetScript("OnEvent", function(self, event, first, message, channel, sender)
    if event == "CHAT_MSG_ADDON" then
        local name = UnitName("player")
        local from = sender and sender:match("^([^%-]+)")
        if first == prefix and channel == "WHISPER" and name and from == name then
            Receive(message)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        locations = {}
        pending = nil
        lastRequest = -30
        Request()
        Render()
    else
        Render()
    end
end)
events:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 30 then
        elapsed = 0
        Request()
    end
end)
WorldMapFrame:HookScript("OnShow", function()
    Request()
    Render()
end)
if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(prefix)
end
