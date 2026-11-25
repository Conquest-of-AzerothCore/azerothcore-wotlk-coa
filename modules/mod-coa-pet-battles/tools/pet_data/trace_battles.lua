local scripts, roll, world = ...
package.path = scripts .. "/?.lua;" .. package.path

math.random = function(lo, hi) return roll(lo, hi) end

local M = { out = {}, clock = 0 }
local timers, sequence = {}, 0
local BASE_TIME = 1700000000
local realTime = os.time
os.time = function(t) if t then return realTime(t) end return BASE_TIME + math.floor(M.clock / 1000) end

function CreateLuaEvent(f, ms, repeats)
    sequence = sequence + 1
    timers[#timers + 1] = { f = f, ms = ms, due = M.clock + ms, left = repeats or 1, id = sequence, order = sequence }
    return sequence
end
function RemoveEventById(id) for i, t in ipairs(timers) do if t.id == id then table.remove(timers, i); return end end end

local function Record(kind, text) M.out[#M.out + 1] = { t = M.clock, kind = kind, text = text } end

function M.NextDue()
    local best
    for _, t in ipairs(timers) do if not best or t.due < best.due or (t.due == best.due and t.order < best.order) then best = t end end
    return best and best.due
end

function M.RunUntil(limit)
    while true do
        local best, at
        for i, t in ipairs(timers) do
            if not best or t.due < best.due or (t.due == best.due and t.order < best.order) then best, at = t, i end
        end
        if not best or best.due > limit then M.clock = math.max(M.clock, limit); return end
        table.remove(timers, at)
        M.clock = best.due
        if best.left == 0 or best.left > 1 then
            sequence = sequence + 1
            timers[#timers + 1] = { f = best.f, ms = best.ms, due = best.due + best.ms, left = best.left == 0 and 0 or best.left - 1,
                id = best.id, order = sequence }
        end
        best.f(best.id, best.ms, 1)
    end
end

local playerEvents = {}
function RegisterPlayerEvent(id, f) playerEvents[id] = playerEvents[id] or {}; table.insert(playerEvents[id], f) end
function RegisterServerEvent() end
function RegisterCreatureEvent() end

local objects, objectSequence = {}, 0
local STANDIN_BASE = 9000000
local function SpeciesOf(entry) return entry >= STANDIN_BASE and entry - STANDIN_BASE or entry end
local HOLD_LINE = 412
local function SideAt(y) return y > 0 and "P" or "E" end
local function Cue(kind, side, value, extra)
    Record("WORLD", "cue " .. kind .. " " .. side .. " " .. tostring(value or 0) .. (extra or ""))
end
local function NewObject(entry, x, y, z, o, follower)
    objectSequence = objectSequence + 1
    local low = objectSequence
    local list = world.displays[SpeciesOf(entry)]
    local display = list and list[1] or 0
    local object = {}
    local guid = setmetatable({ low = low }, { __tostring = function() return "obj" .. low end })
    objects[low] = object
    local side = SideAt(y)
    local auras = {}
    object.side = side
    object.follower = follower
    setmetatable(object, { __index = function(_, k)
        if not follower then
            if k == "PerformEmote" then return function(_, id) Cue("emote", side, id) end
            elseif k == "SetFacing" then return function() Cue("face", side) end
            elseif k == "MoveTo" then return function(_, mode, _, _, _, settle)
                local caller = debug.getinfo(2, "Sl")
                if caller and caller.source:find("pb_battle", 1, true) and caller.currentline == HOLD_LINE then return end
                if mode == 2 then Cue("back", side) elseif not settle then Cue("lunge", side) end end
            elseif k == "MoveJump" then return function() Cue("jump", side) end
            elseif k == "CastSpell" then return function(_, _, id) Cue("effect", side, id) end
            elseif k == "AddAura" then return function(_, id) auras[id] = true; Cue("aura", side, id) end
            elseif k == "RemoveAura" then return function(_, id) if auras[id] then auras[id] = nil; Cue("unaura", side, id) end end
            elseif k == "SetHealth" then return function(_, v) object.hp = v; Cue("health", side, v) end
            end
        end
        if k == "GetGUID" then return function() return guid end
        elseif k == "GetGUIDLow" then return function() return low end
        elseif k == "GetDisplayId" then return function() return display end
        elseif k == "SetDisplayId" then return function(_, d) display = d end
        elseif k == "GetX" then return function() return x end
        elseif k == "GetY" then return function() return y end
        elseif k == "GetZ" then return function() return z end
        elseif k == "GetO" then return function() return o end
        elseif k == "GetHealth" then return function() return object.hp or 1000 end
        elseif k == "GetEntry" then return function() return entry end
        elseif k == "DespawnOrUnsummon" then return function() if objects[low] then objects[low] = nil; Record("WORLD", follower and "follow despawn" or ("despawn " .. SpeciesOf(entry))) end end
        elseif k == "RemoveFromWorld" then return function() objects[low] = nil end
        elseif k == "GetNearestPlayer" then return function() return nil end
        end
        return function() end
    end })
    return object, guid
end

local map = { GetWorldObject = function(_, guid) return guid and objects[guid.low] end, GetHeight = function() return 0 end }
M.players = {}
local function NewPlayer(low, account)
    local state = { alive = true, combat = false, map = 0, distance = 0, rank = 0, online = true, spells = {}, bot = false, account = account,
        items = {}, mounted = false }
    local guid = setmetatable({ low = low }, { __tostring = function() return "player" .. low end })
    local player = setmetatable({ state = state }, { __index = function(_, k)
        if k == "GetGUIDLow" then return function() return low end
        elseif k == "GetGUID" then return function() return guid end
        elseif k == "GetAccountId" then return function() return state.account end
        elseif k == "GetName" then return function() return "Tester" .. low end
        elseif k == "IsAlive" then return function() return state.alive end
        elseif k == "IsInCombat" then return function() return state.combat end
        elseif k == "GetMapId" then return function() return state.map end
        elseif k == "GetMap" then return function() return map end
        elseif k == "GetDistance" then return function() return state.distance end
        elseif k == "GetPhaseMask" then return function() return 1 end
        elseif k == "GetGMRank" then return function() return state.rank end
        elseif k == "HasSpell" then return function(_, spell) return state.spells[spell] == true end
        elseif k == "GetX" or k == "GetY" or k == "GetZ" or k == "GetO" then return function() return 0 end
        elseif k == "GetCreaturesInRange" then return function() return {} end
        elseif k == "GetItemCount" then return function(_, entry) return state.items[entry] or 0 end
        elseif k == "RemoveItem" then return function(_, entry, n)
            state.items[entry] = (state.items[entry] or 0) - (n or 1)
            Record("WORLD", "item take " .. entry)
        end
        elseif k == "IsMounted" then return function() return state.mounted end
        elseif k == "GetSpeed" then return function() return 7 end
        elseif k == "SendPacket" then return function(_, packet)
            local f = packet.fields
            Record("WORLD", "prime " .. tostring(f[1]) .. " " .. tostring(f[8] or 0))
        end
        end
        return function() end
    end })
    M.players[low] = player
    return player
end
M.NewPlayer = NewPlayer
function GetPlayerByGUID(guid)
    local player = guid and M.players[guid.low]
    return player and player.state.online and player or nil
end
function GetPlayersInWorld() return {} end
function GetMapById() return map end
local function FromStore()
    for level = 3, 8 do
        local info = debug.getinfo(level, "S")
        if not info then return false end
        if info.source:find("pb_store", 1, true) then return true end
    end
    return false
end
function PerformIngameSpawn(kind, entry, _, _, x, y, z, o)
    if kind == 2 then
        local side = SideAt(y)
        Cue("crate", side, entry)
        objectSequence = objectSequence + 1
        local low = objectSequence
        local crate = setmetatable({}, { __index = function(_, k)
            if k == "RemoveFromWorld" then return function()
                if objects[low] then objects[low] = nil; Cue("uncrate", side, entry) end
            end end
            if k == "GetGUID" then return function() return setmetatable({ low = low }, {}) end end
            return function() end
        end })
        objects[low] = crate
        return crate
    end
    if kind ~= 1 then return nil end
    local follower = FromStore()
    local object = NewObject(entry, x, y, z, o, follower)
    if follower then Record("WORLD", "follow spawn " .. SpeciesOf(entry))
    else Record("WORLD", "spawn " .. SpeciesOf(entry)) end
    return object
end
local function Cursor(rows)
    if #rows == 0 then return nil end
    local at = 1
    return {
        GetUInt32 = function(_, column) return rows[at][column + 1] end,
        GetFloat = function(_, column) return rows[at][column + 1] end,
        GetString = function(_, column) return tostring(rows[at][column + 1]) end,
        NextRow = function() at = at + 1; return at <= #rows end,
    }
end
function WorldDBQuery(sql)
    local item = sql:match("FROM item_template WHERE entry=(%d+) AND class=0 AND subclass=5 AND spellcategory_1=11")
    if item then
        local level = world.foods[tonumber(item)]
        return level and Cursor({ { level } }) or nil
    end
    local templates = sql:match("FROM creature_template WHERE entry IN %(([%d,]+)%)")
    if templates and sql:find("HealthModifier", 1, true) then
        local rows = {}
        for id in templates:gmatch("%d+") do
            if world.displays[tonumber(id)] then rows[#rows + 1] = { tonumber(id), "", "", "", 0, 0, 0, 0, 0, 0, 1, 1, 0, 0 } end
        end
        return Cursor(rows)
    end
    local models = sql:match("FROM creature_template_model WHERE CreatureID IN %(([%d,]+)%) AND Idx < 4")
    if models then
        local rows = {}
        for id in models:gmatch("%d+") do
            for idx, display in ipairs(world.displays[tonumber(id)] or {}) do
                if idx <= 4 then rows[#rows + 1] = { tonumber(id), idx - 1, display } end
            end
        end
        return Cursor(rows)
    end
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
    return nil
end
local followers = {}
function CharDBQuery(sql)
    local g = sql:match("SELECT species FROM dc_battlefollower WHERE guid=(%d+)")
    if g and followers[tonumber(g)] then return Cursor({ { followers[tonumber(g)] } }) end
    return nil
end
function CharDBExecute(sql)
    local g, sp = sql:match("REPLACE INTO dc_battlefollower %(guid, species%) VALUES %((%d+),(%d+)%)")
    if g then followers[tonumber(g)] = tonumber(sp); return end
    local d = sql:match("DELETE FROM dc_battlefollower WHERE guid=(%d+)")
    if d then followers[tonumber(d)] = nil end
end
function CreatePacket()
    local fields = {}
    return setmetatable({ fields = fields }, { __index = function(packet, k)
        if k == "WriteULong" then return function(_, v) fields[#fields + 1] = v end end
        return function() end
    end })
end
function RunCommand() end

PB_CAST = { Cast = function(att, tgt, spell, o)
    o = o or {}
    local side = att and att.side or "P"
    local at = tgt and tgt.side or side
    Cue("cast", side, spell, " " .. at .. (o.ranged and " ranged" or "") .. (o.heal and " heal" or ""))
    if o.hp_after and tgt then tgt.hp = o.hp_after; Cue("health", at, o.hp_after) end
    return true
end }

local messageHandlers = {}
package.loaded["acore_msg"] = {
    On = function(module, action, f) messageHandlers[module .. "|" .. action] = f end,
    Send = function(player, module, action, payload)
        local text = module .. "|" .. action .. "|" .. tostring(payload or "")
        if #text > 240 then Record("TOOLONG", text); return false end
        if player then Record("OUT", "p" .. player:GetGUIDLow() .. " " .. text) end
        return true
    end,
    SendChunks = function() error("SendChunks is not used by the pet battle scripts") end,
    Has = function() return true end,
}
do
    local env = setmetatable({ pairs = function(tbl)
        local keys = {}
        for k in next, tbl do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        if #keys > 0 and type(keys[1]) == "number" then table.sort(keys) end
        local i = 0
        return function() i = i + 1; local k = keys[i]; if k ~= nil then return k, tbl[k] end end
    end }, { __index = _G, __newindex = _G })
    local chunk = assert(loadfile(scripts .. "/acore_prime.lua"))
    setfenv(chunk, env)
    package.loaded["acore_prime"] = chunk()
end
package.loaded["acore_bus"] = { On = function() end, Emit = function() end }
package.loaded["acore_util"] = { IsBot = function(player) return player.state and player.state.bot end }
package.loaded["acore_settings"] = { Get = function(_, _, default) return default end }

dofile(scripts .. "/pb_battle.lua")
M.Store = PB_STORE
M.Battle = PB_BATTLE
M.D = require("pb_data")
M.Eng = require("pb_core")

local function OtherFighter(player)
    for low, other in pairs(M.players) do
        if low ~= player:GetGUIDLow() and other.state.account == player.state.account and other.state.online and
            PB_BATTLE.InBattle(other) then return true end
    end
    return false
end

function M.Message(player, text)
    local module, action, payload = text:match("^([%w_]+)|([%w_]+)|?(.*)$")
    Record("IN", "p" .. player:GetGUIDLow() .. " " .. text)
    if player.state.bot or not player.state.online then return end
    if module == "pbt" and action == "start" and player.state.rank >= 2 and OtherFighter(player) then
        Record("OUT", "p" .. player:GetGUIDLow() .. " pbt|msg|Another character of your account is in a pet battle.")
        return
    end
    local f = module and messageHandlers[module .. "|" .. action]
    if f then f(player, payload) end
end

function M.LogoutForfeit(player)
    Record("IN", "p" .. player:GetGUIDLow() .. " event logout")
    if PB_BATTLE.InBattle(player) then messageHandlers["pbt|quit"](player, "") end
    M.saved = M.saved or {}
    M.saved[player:GetGUIDLow()] = M.Journal(player)
    for _, f in ipairs(playerEvents[4] or {}) do f(4, player) end
    local live = {}
    for low in pairs(objects) do live[#live + 1] = low end
    table.sort(live)
    for _, low in ipairs(live) do objects[low]:DespawnOrUnsummon(0) end
    player.state.online = false
end

function M.Login(player)
    Record("IN", "p" .. player:GetGUIDLow() .. " event login")
    player.state.online = true
    for _, f in ipairs(playerEvents[3] or {}) do f(3, player) end
end

function M.Logout(player)
    Record("IN", "p" .. player:GetGUIDLow() .. " event logout")
    for _, f in ipairs(playerEvents[4] or {}) do f(4, player) end
    player.state.online = false
end

function M.Note(player, text) Record("IN", "p" .. player:GetGUIDLow() .. " event " .. text) end

function M.Journal(player)
    if not player.state.online and M.saved and M.saved[player:GetGUIDLow()] then return M.saved[player:GetGUIDLow()] end
    local rows = {}
    for species, p in pairs(PB_STORE.Pets(player)) do
        rows[#rows + 1] = { species = species, level = p.level, xp = p.xp, a1 = p.a[1], a2 = p.a[2], a3 = p.a[3],
            quality = p.quality or 1, display = p.display or 0, hp = p.hp or 0, hpAt = p.hpAt or 0 }
    end
    table.sort(rows, function(a, b) return a.species < b.species end)
    return rows
end

function M.Reset() M.out = {} end
function M.PendingOneShots()
    local n = 0
    for _, t in ipairs(timers) do if t.left ~= 0 then n = n + 1 end end
    return n
end
function M.SetState(player, key, value, note)
    player.state[key] = value
    Record("IN", "p" .. player:GetGUIDLow() .. " event " .. note)
end
function M.InBattle(player) return PB_BATTLE.InBattle(player) end
function M.Waiting(player) return PB_BATTLE.Waiting(player) end

return M
