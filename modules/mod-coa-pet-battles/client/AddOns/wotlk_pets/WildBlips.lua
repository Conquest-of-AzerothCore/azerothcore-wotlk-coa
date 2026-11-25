-- Minimap blips for the wild pets around you. The server (pb_wild) sends "pbw|pets|<north>,<west>,<species>,<level>,<name>;..." every second while there are any:
-- offsets in YARDS from you (WoW world: +x is north, +y is west). We draw our own pet icon on the minimap, clamped to its edge when the pet is farther than it shows.
local blips, expire = {}, 0
WotlkPetsDB = WotlkPetsDB or {}   -- SavedVariables: { blips = false } when the player switched the minimap blips off in the tracking menu
local function Enabled() return WotlkPetsDB.blips ~= false end
local ICON = "Interface\\Icons\\INV_Box_PetCarrier_01"
-- radius in yards from the minimap centre to its edge, by zoom level 0 (far) .. 5 (near)
local OUTDOOR = { 233.3, 200, 166.7, 133.3, 100, 66.7 }
local INDOOR = { 150, 120, 90, 60, 40, 25 }

-- pure math: screen offset (pixels from the minimap centre, x right / y up) of a pet at (north, west) yards; facing = player facing in radians when the minimap rotates
local function Place(north, west, radiusYards, radiusPx, facing)
    local x, y = -west, north   -- east is screen right, north is screen up
    if facing then
        local c, s = math.cos(facing), math.sin(facing)
        x, y = x * c + y * s, -x * s + y * c
    end
    local d = math.sqrt(x * x + y * y)
    local k = radiusPx / radiusYards
    local edge = false
    if d > radiusYards then k = radiusPx / d; edge = true end   -- beyond the map: pinned to its rim
    return x * k, y * k, edge
end

local inside, dirty = false, true   -- recomputed only when the minimap zoom / area changes (the check below briefly changes the zoom)
local function Indoors()
    if not dirty then return inside end
    dirty = false
    local zoom = Minimap:GetZoom()
    if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1) end   -- the usual trick: a zoom step shows which table applies
    inside = (tonumber(GetCVar("minimapZoom")) or 0) == Minimap:GetZoom()
    Minimap:SetZoom(zoom)
    return inside
end

local function Blip(i)
    local b = blips[i]
    if b then return b end
    b = CreateFrame("Button", nil, Minimap); b:SetSize(16, 16); b:SetFrameLevel(Minimap:GetFrameLevel() + 6)
    b.tex = b:CreateTexture(nil, "OVERLAY"); b.tex:SetAllPoints(); b.tex:SetTexture(ICON)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine(self.name or "Wild pet", 1, 0.82, 0)
        GameTooltip:AddLine("Wild pet, level " .. (self.level or "?"), 0.8, 0.8, 0.8); GameTooltip:AddLine("Right-click it to challenge it.", 0.6, 0.6, 0.6); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide(); blips[i] = b
    return b
end

local data = {}   -- { north, west, species, level, name }
local function Draw()
    if not Enabled() then for i = 1, #blips do blips[i]:Hide() end return end
    local zoom = Minimap:GetZoom()
    local radius = (Indoors() and INDOOR or OUTDOOR)[zoom + 1] or 100
    local px = (Minimap:GetWidth() or 140) / 2 - 6
    local rot = GetCVar("rotateMinimap") == "1"
    local facing = rot and GetPlayerFacing and GetPlayerFacing() or nil
    for i, e in ipairs(data) do
        local b = Blip(i)
        local x, y, edge = Place(e[1], e[2], radius, px, facing)
        b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", x, y); b:SetAlpha(edge and 0.55 or 1)
        b.name, b.level = e[5], e[4]; b:Show()
    end
    for i = #data + 1, #blips do blips[i]:Hide() end
end

local driver = CreateFrame("Frame")
for _, ev in ipairs({ "MINIMAP_UPDATE_ZOOM", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED" }) do driver:RegisterEvent(ev) end
driver:SetScript("OnEvent", function() dirty = true end)
driver:SetScript("OnUpdate", function(self, dt)
    if #data == 0 then return end
    self.t = (self.t or 0) + dt
    if self.t < 0.1 then return end
    self.t = 0
    if GetTime() > expire then data = {}; Draw(); return end   -- the server stopped talking (left the zone): no stale blips
    Draw()
end)

AcoreLib.On("pbw", "pets", function(p)
    data = {}
    if p ~= "none" then
        for entry in p:gmatch("[^;]+") do
            local n, w, sp, lv, name = entry:match("^(%-?%d+),(%-?%d+),(%d+),(%d+),(.+)$")
            if n then data[#data + 1] = { tonumber(n), tonumber(w), tonumber(sp), tonumber(lv), name } end
        end
    end
    expire = GetTime() + 6
    Draw()
end)

-- the minimap TRACKING menu (the magnifier button) gets a "Wild Pets" tick box; /petblips does the same from the chat line
local function Toggle(on)
    if on == nil then on = not Enabled() end
    WotlkPetsDB.blips = on and true or false
    Draw()
end
if hooksecurefunc and MiniMapTrackingDropDown_Initialize then
    hooksecurefunc("MiniMapTrackingDropDown_Initialize", function()
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Wild Pets"; info.isNotRadio = true; info.keepShownOnClick = 1; info.checked = Enabled()
        info.icon = ICON; info.func = function() Toggle(); end
        UIDropDownMenu_AddButton(info)
    end)
    -- the tracking dropdown kept a reference to the ORIGINAL function when Blizzard's UI loaded: point it at the hooked one
    if MiniMapTrackingDropDown and UIDropDownMenu_Initialize then pcall(UIDropDownMenu_Initialize, MiniMapTrackingDropDown, MiniMapTrackingDropDown_Initialize, "MENU") end
end
SLASH_PETBLIPS1 = "/petblips"
SlashCmdList["PETBLIPS"] = function() Toggle(); DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Pets]|r minimap wild pet markers " .. (Enabled() and "on" or "off") .. ".") end

WotlkBlips = { Toggle = Toggle, Enabled = Enabled, Place = Place, Data = function() return data end, Blips = function() return blips end, Draw = Draw }   -- (tests)
