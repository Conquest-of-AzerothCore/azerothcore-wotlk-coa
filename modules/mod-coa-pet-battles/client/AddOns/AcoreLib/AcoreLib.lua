-- AcoreLib: tiny messaging layer shared by our addons. Wire format matches scripts/acore_msg.lua
-- usage:  AcoreLib.On("shop", "bal", function(payload) ... end);  AcoreLib.Send("shop", "buy", "1001")
AcoreLib = AcoreLib or {}
local L = AcoreLib
L.PREFIX = "ACORE"
L.handlers = L.handlers or {}

-- opaque panel behind a window's contents (the stock dialog backgrounds are see-through). inset = how far inside the border to start
function L.Solid(frame, inset, r, g, b)
    local t = frame:CreateTexture(nil, "BACKGROUND")
    t:SetPoint("TOPLEFT", inset, -inset); t:SetPoint("BOTTOMRIGHT", -inset, inset); t:SetTexture(r or 0.07, g or 0.07, b or 0.09, 1)
    return t
end

function L.On(module, action, fn)
    L.handlers[module .. "|" .. action] = fn
end

function L.Send(module, action, payload)
    local text = module .. "|" .. action .. "|" .. tostring(payload or "")
    if #text > 240 then return false end
    SendAddonMessage(L.PREFIX, text, "WHISPER", UnitName("player"))   -- server hook swallows it
    return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
    if prefix ~= L.PREFIX then return end
    local module, action, payload = msg:match("^([%w_]+)|([%w_]+)|?(.*)$")
    local fn = module and L.handlers[module .. "|" .. action]
    if fn then fn(payload, sender) end
end)

-- Addon handshake: every addon calls AcoreLib.Announce("<name>") when it loads. On entering the world (and again a few seconds later, and
-- whenever the server asks with core|who after a script reload) we tell the server which of our addons are installed ("core|hello|a,b").
-- The server uses it to refuse a feature (garrison portal, jukebox NPC) to a player who does not have the matching addon.
local announced = {}
function L.Announce(name)
    for _, n in ipairs(announced) do if n == name then return end end
    announced[#announced + 1] = name
end
local function Hello() if #announced > 0 then L.Send("core", "hello", table.concat(announced, ",")) end end
L.On("core", "who", Hello)
local hf, waited, step = CreateFrame("Frame"), 0, 3
hf:RegisterEvent("PLAYER_ENTERING_WORLD")
hf:SetScript("OnEvent", function() Hello(); waited, step = 0, 1; hf:Show() end)
hf:SetScript("OnUpdate", function(self, elapsed)   -- the server may not be listening for the very first message: repeat at 3 s and 10 s
    waited = waited + elapsed
    if step == 1 and waited > 3 then Hello(); step = 2 elseif step == 2 and waited > 10 then Hello(); step = 3; self:Hide() end
end)

-- /acorelib ping : round-trip test against the server
SLASH_ACORELIB1 = "/acorelib"
SlashCmdList["ACORELIB"] = function(arg)
    L.On("core", "pong", function(p) print("|cff00ff00AcoreLib:|r server replied: " .. tostring(p)) end)
    L.Send("core", "ping", arg ~= "" and arg or "hello")
end
