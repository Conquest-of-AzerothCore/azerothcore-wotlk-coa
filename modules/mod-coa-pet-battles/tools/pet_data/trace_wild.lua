local scripts, roll, world = ...
package.path = scripts .. "/?.lua;" .. package.path

math.random = function(lo, hi) return roll(lo, hi) end

local M = { out = {}, clock = 0, startOk = true }
local BASE_TIME = 1700000000
local realTime = os.time
os.time = function(t) if t then return realTime(t) end return BASE_TIME + math.floor(M.clock / 1000) end

function CreateLuaEvent() return 0 end
function RemoveEventById() end
function RegisterPlayerEvent() end
function RegisterServerEvent() end
function RegisterCreatureEvent() end
function RegisterCreatureGossipEvent() end
function CharDBQuery() return nil end
function CharDBExecute() end
function RunCommand() end
PB_CAST = { Cast = function() return true end }

local function Record(text) M.out[#M.out + 1] = { t = M.clock, text = text } end
local function F2(v) return string.format("%.2f", v) end
local function F4(v) return string.format("%.4f", v) end

local function GroundAt(mapId, x, y)
    local z = world.ground[mapId]
    for _, r in ipairs(world.rects) do
        if r.map == mapId and x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2 then z = r.z end
    end
    return z
end

local objects = {}
local function GuidOf(low) return setmetatable({ low = low }, { __tostring = function() return "obj" .. low end }) end

local function Base(o)
    return {
        GetGUIDLow = function() return o.low end,
        GetGUID = function() return GuidOf(o.low) end,
        GetEntry = function() return o.entry end,
        GetX = function() return o.x end,
        GetY = function() return o.y end,
        GetZ = function() return o.z end,
        GetMapId = function() return o.map end,
        GetMap = function() return { GetHeight = function(_, x, y) local z = GroundAt(o.map, x, y); return z or -200000 end } end,
        GetLevel = function() return o.level or 80 end,
        GetFaction = function() return o.faction end,
        GetNPCFlags = function() return o.npcflags end,
        IsInCombat = function() return o.combat end,
        GetDBTableGUIDLow = function() return o.db and o.low or 0 end,
        GetDisplayId = function() return o.display or 0 end,
        GetScale = function() return 1 end,
        RemoveAura = function() end,
        HasAura = function() return false end,
        SetReactState = function() end,
        SetPhaseMask = function() end,
    }
end

local function Wrap(o, methods)
    return setmetatable({}, { __index = function(_, k) return methods[k] or function() end end })
end

local function NewMob(m)
    local o = { low = m.guid, entry = m.entry, map = m.map, x = m.x, y = m.y, z = m.z, level = m.level, db = m.db,
        alive = m.alive, combat = m.combat, mob = true }
    local t = world.templates[m.entry]
    o.faction, o.npcflags = t and t[1] or 7, t and t[2] or 0
    local methods = Base(o)
    methods.SetFaction = function(_, f)
        o.faction = f
        if f == 35 then o.adopted = true; Record("adopt " .. o.low)
        elseif o.adopted then o.adopted = false; Record("release " .. o.low .. " " .. f .. " " .. o.npcflags) end
    end
    methods.SetNPCFlags = function(_, f) o.npcflags = f end
    methods.DespawnOrUnsummon = function() if objects[o.low] then objects[o.low] = nil; Record("despawn " .. o.low) end end
    o.object = Wrap(o, methods)
    objects[o.low] = o
    return o
end

local spawned = 900000
function PerformIngameSpawn(kind, entry, mapId, _, x, y, z, facing)
    if kind ~= 1 then return nil end
    spawned = spawned + 1
    local species = entry >= 9000000 and entry - 9000000 or entry
    local list = world.displays[species]
    local o = { low = spawned, entry = entry, map = mapId, x = x, y = y, z = z, display = list and list[1] or 0 }
    local methods = Base(o)
    methods.SetFaction = function() end
    methods.SetNPCFlags = function() end
    methods.SetScale = function(_, s) if not o.scaled then o.scaled = true; Record("scale " .. o.low .. " " .. F4(s)) end end
    methods.MoveTo = function(_, _, mx, my, mz) Record("settle " .. o.low .. " " .. F2(mx) .. " " .. F2(my) .. " " .. F2(mz)) end
    methods.MoveRandom = function(_, r) Record("wander " .. o.low .. " " .. F2(r)) end
    methods.DespawnOrUnsummon = function() if objects[o.low] then objects[o.low] = nil; Record("despawn " .. o.low) end end
    o.object = Wrap(o, methods)
    objects[o.low] = o
    Record("spawn " .. o.low .. " " .. species .. " " .. F2(x) .. " " .. F2(y) .. " " .. F2(z) .. " " .. F4(facing))
    return o.object
end

local map = { GetWorldObject = function(_, guid) local o = guid and objects[guid.low]; return o and o.object end }
function GetMapById() return map end

M.players = {}
local function Distance3(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2) end

function M.NewPlayer(low, mapId, zone, x, y, z, bot)
    local s = { low = low, map = mapId, zone = zone, x = x, y = y, z = z, bot = bot, alive = true, combat = false, battle = false }
    local methods = {
        GetGUIDLow = function() return low end,
        GetGUID = function() return GuidOf(low) end,
        GetMapId = function() return s.map end,
        GetZoneId = function() return s.zone end,
        GetX = function() return s.x end,
        GetY = function() return s.y end,
        GetZ = function() return s.z end,
        IsAlive = function() return s.alive end,
        IsInCombat = function() return s.combat end,
        GetPhaseMask = function() return 1 end,
        GetCreaturesInRange = function(_, range)
            local list, lows = {}, {}
            for _, o in pairs(objects) do
                if o.mob and o.alive and o.map == s.map and Distance3(o, s) <= range then lows[#lows + 1] = o end
            end
            table.sort(lows, function(a, b) return a.order < b.order end)
            for _, o in ipairs(lows) do list[#list + 1] = o.object end
            return list
        end,
        GossipClearMenu = function() end,
        GossipMenuAddItem = function(_, _, text) Record("menu " .. low .. " " .. M.hello .. " " .. text) end,
        GossipSendMenu = function() end,
        GossipComplete = function() end,
        SendBroadcastMessage = function(_, text) Record("say " .. low .. " " .. text) end,
    }
    local player = setmetatable({ state = s }, { __index = function(_, k) return methods[k] or function() end end })
    M.players[low] = player
    return player
end

function GetPlayersInWorld()
    local lows, list = {}, {}
    for low in pairs(M.players) do lows[#lows + 1] = low end
    table.sort(lows)
    for _, low in ipairs(lows) do list[#list + 1] = M.players[low] end
    return list
end

local function Cursor(rows)
    if #rows == 0 then return nil end
    local at = 1
    return {
        GetUInt32 = function(_, column) return rows[at][column + 1] end,
        GetFloat = function(_, column) return rows[at][column + 1] end,
        NextRow = function() at = at + 1; return at <= #rows end,
    }
end
function WorldDBQuery(sql)
    local species = sql:match("FROM creature_template_model WHERE CreatureID = (%d+) ORDER BY Idx")
    if species then
        local rows = {}
        for _, display in ipairs(world.displays[tonumber(species)] or {}) do rows[#rows + 1] = { display } end
        return Cursor(rows)
    end
    local entry = sql:match("WHERE m%.CreatureID=(%d+) AND m%.Idx=0")
    if entry then
        local info = world.modelInfo[tonumber(entry)]
        return info and Cursor({ { info[1], info[2] } }) or nil
    end
    local ids = sql:match("SELECT entry, faction, npcflag FROM creature_template WHERE entry IN %(([%d,]+)%)")
    if ids then
        local rows = {}
        for id in ids:gmatch("%d+") do
            local t = world.templates[tonumber(id)]
            if t then rows[#rows + 1] = { tonumber(id), t[1], t[2] } end
        end
        return Cursor(rows)
    end
    return nil
end

local messageHandlers = {}
package.loaded["acore_msg"] = {
    On = function(module, action, f) messageHandlers[module .. "|" .. action] = f end,
    Send = function(player, module, action, payload)
        local text = module .. "|" .. action .. "|" .. tostring(payload or "")
        if player then Record("send " .. player:GetGUIDLow() .. " " .. text) end
        return true
    end,
    SendChunks = function() end,
    Has = function() return true end,
}
package.loaded["acore_prime"] = { Register = function() end, SetDisplayResolver = function() end, Enable = function() end,
    SendAs = function() end, SendOne = function() end }
package.loaded["acore_bus"] = { On = function() end, Emit = function() end }
package.loaded["acore_util"] = { IsBot = function(player) return player.state and player.state.bot end }
package.loaded["acore_settings"] = { Get = function(_, _, default) return default end }

dofile(scripts .. "/pb_battle.lua")
local D = require("pb_data")
D.zones = world.zones
for species, sp in pairs(D.species) do
    local ours = world.species[species]
    if ours then
        sp.name = ours.name
        sp.wild = ours.wild and (ours.critter and "adopt" or true) or nil
    else
        sp.wild = nil
    end
end
package.loaded["pb_zone_species"] = world.zoneSpecies
PB_BATTLE.InBattle = function(player) return player.state and player.state.battle end
PB_BATTLE.Start = function(player, enemies)
    local parts = {}
    for _, e in ipairs(enemies) do
        parts[#parts + 1] = e.species .. ":" .. e.level .. ":" .. F4(e.quality or 1) .. ":" .. (e.display or 0)
    end
    Record("start " .. player:GetGUIDLow() .. " " .. table.concat(parts, " "))
    return M.startOk
end

local function SortedPairs(t)
    local keys = {}
    for k in next, t do keys[#keys + 1] = k end
    local numeric = true
    for _, k in ipairs(keys) do if type(k) ~= "number" then numeric = false; break end end
    if numeric then table.sort(keys) end
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k ~= nil then return k, t[k] end
    end, t, nil
end
local env = setmetatable({ pairs = SortedPairs }, { __index = _G, __newindex = _G })
local chunk = assert(loadfile(scripts .. "/pb_wild.lua"))
setfenv(chunk, env)
chunk()

local mobOrder = 0
function M.AddMob(m)
    mobOrder = mobOrder + 1
    m.order = mobOrder
    local o = NewMob(m)
    o.order = mobOrder
end

function M.Tick() PB_WILD.Tick() end
function M.Blips() PB_WILD.BlipTick() end
function M.Hello(low, guid)
    local o = objects[guid]
    if not o then return end
    M.hello = guid
    PB_WILD.OnHello(1, M.players[low], o.object)
end
function M.Select(low, guid, option)
    local o = objects[guid]
    if not o then return end
    PB_WILD.OnSelect(2, M.players[low], o.object, 0, option)
end
function M.Move(low, x, y, z, mapId, zone)
    local s = M.players[low].state
    s.x, s.y, s.z = x, y, z
    if mapId then s.map, s.zone = mapId, zone end
end
function M.SetState(low, key, value) M.players[low].state[key] = value end
function M.Vanish(guid) objects[guid] = nil end
function M.WanderTo(guid, x, y) local o = objects[guid]; if o then o.x, o.y = x, y end end
function M.Shutdown()
    local wild = PB_WILD.Wild
    local keys = {}
    for k in next, wild do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local w = wild[k]
        local o = objects[k]
        if o and w.adopted then
            local t = world.templates[w.species] or {}
            o.object:SetNPCFlags(t[2] or w.flags0 or 0)
            o.object:SetFaction(t[1] or w.faction0)
        elseif o then
            o.object:DespawnOrUnsummon(0)
        end
        wild[k] = nil
    end
end
function M.Live()
    local n = 0
    for _ in next, PB_WILD.Wild do n = n + 1 end
    return n
end

return M
