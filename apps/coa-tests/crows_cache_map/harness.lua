local frames = {}
local now = 0
local map = "Tanaris"
local requests = {}
local Frame = {}
Frame.__index = Frame
function Frame:SetWidth(value) self.width = value end
function Frame:SetHeight(value) self.height = value end
function Frame:GetWidth() return self.width end
function Frame:GetHeight() return self.height end
function Frame:SetFrameLevel(value) self.level = value end
function Frame:GetFrameLevel() return self.level or 10 end
function Frame:RegisterEvent(value) self.events[value] = true end
function Frame:SetScript(event, handler) self.scripts[event] = handler end
function Frame:HookScript(event, handler) self.scripts[event] = handler end
function Frame:ClearAllPoints() self.point = nil end
function Frame:SetPoint(...) self.point = {...} end
function Frame:IsShown() return self.shown end
function Frame:Show() self.shown = true end
function Frame:Hide()
    if self.shown and self.scripts.OnHide then self.scripts.OnHide(self) end
    self.shown = false
end
function Frame:CreateTexture() return setmetatable({scripts = {}}, Frame) end
function Frame:SetTexture(path) self.texture = path end
function Frame:SetTexCoord(...) self.coordinates = {...} end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({kind = kind, name = name, parent = parent, events = {}, scripts = {}}, Frame)
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
function GetMapInfo() return map end
function GetTime() return now end
function UnitName() return "Cacheowner" end
function SendAddonMessage(...) requests[#requests + 1] = {...} end
function WorldMapPOI_OnEnter(self) self.standardHover = true end
function WorldMapPOI_OnLeave(self) self.standardHover = false end
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame:Show()
WorldMapButton = CreateFrame("Frame", "WorldMapButton", WorldMapFrame)
WorldMapDetailFrame = CreateFrame("Frame", "WorldMapDetailFrame", WorldMapButton)
WorldMapDetailFrame:SetWidth(1000)
WorldMapDetailFrame:SetHeight(668)
GameTooltip = {
    SetOwner = function(self, owner) self.owner = owner end,
    IsOwned = function(self, owner) return self.owner == owner end,
    SetText = function(self, text) self.title = text end,
    AddLine = function(self, text) self.line = text end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
}
dofile(arg[1])
local events = frames[#frames]
local function message(text, sender)
    events.scripts.OnEvent(events, "CHAT_MSG_ADDON", "COACrows", text, "WHISPER", sender or "Cacheowner")
end
local function update() events.scripts.OnEvent(events, "WORLD_MAP_UPDATE") end
events.scripts.OnEvent(events, "PLAYER_ENTERING_WORLD")
assert(#requests == 1 and requests[1][1] == "COACrows" and requests[1][2] == "SYNC")
message("P;7;1;-7831;-3465", "Otherplayer")
assert(not CoACrowsCacheMarker1)
message("B")
message("P;7;1;-7831;-3465")
assert(not CoACrowsCacheMarker1)
message("E")
local marker = CoACrowsCacheMarker1
assert(marker:IsShown())
assert(math.abs(marker.point[4] - 470.57971014493) < 0.01)
assert(math.abs(marker.point[5] + 284.0452173913) < 0.01)
marker.scripts.OnEnter(marker)
assert(marker.standardHover and GameTooltip.shown)
assert(GameTooltip.title == "Crow's Cache")
assert(GameTooltip.line == "High-Risk 60 PvP Event")
map = "Kalimdor"
update()
assert(marker:IsShown() and marker.point[4] > 0 and marker.point[4] < 1000)
map = "Elwynn"
update()
assert(not marker:IsShown() and not GameTooltip.shown)
map = "Tanaris"
update()
assert(marker:IsShown())
message("D;7")
assert(not marker:IsShown())
message("P;8;1;-7831;-3465")
assert(marker:IsShown())
message("B")
message("E")
assert(not marker:IsShown())
message("P;9;1;nan;-3465")
message("P;9;1;999999;-3465")
message("P;9;0;-7831;-3465")
assert(not marker:IsShown())
now = 30
events.scripts.OnUpdate(events, 30)
assert(#requests == 2)
message("P;10;1;-7831;-3465")
events.scripts.OnEvent(events, "PLAYER_ENTERING_WORLD")
assert(not marker:IsShown() and #requests == 3)
print("Crow's Cache map regression passed: sync, sender checks, marker projection, hover, pickup removal and reload.")

map = "Silithus"
message("P;11;1;-7203.1616;372.38562")
assert(marker:IsShown())
assert(math.abs(marker.point[4] - 621.6533) < 0.03)
assert(math.abs(marker.point[5] + 358.05767) < 0.03)
marker.scripts.OnEnter(marker)
assert(GameTooltip.line == "High-Risk 60 PvP Event")
message("D;11")
assert(not marker:IsShown())
print("Silithus marker matches Southwind Village coordinates and disappears on pickup.")

map = "ThousandNeedles"
message("P;12;1;-5805.1646;-3899.4047")
assert(marker:IsShown())
assert(math.abs(marker.point[4] - 787.8190999999999) < 0.03)
assert(math.abs(marker.point[5] + 418.73275392) < 0.03)
message("D;12")
assert(not marker:IsShown())

map = "Barrens"
message("P;12;1;-763.6296;-3191.6892")
assert(marker:IsShown())
assert(math.abs(marker.point[4] - 573.79486) < 0.03)
assert(math.abs(marker.point[5] + 234.9253128) < 0.03)
message("D;12")
assert(not marker:IsShown())
