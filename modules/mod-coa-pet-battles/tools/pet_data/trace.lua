local scripts = ...
package.path = scripts .. "/?.lua;" .. package.path

local function readAll(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end

local function patchOnce(text, find, replace)
    local first = text:find(find, 1, true)
    assert(first, "pattern not found: " .. find)
    assert(not text:find(find, first + #find, true), "pattern found twice: " .. find)
    return text:sub(1, first - 1) .. replace .. text:sub(first + #find)
end

local source = readAll(scripts .. "/pb_core.lua")
source = patchOnce(source, "local function RunEffects(X, fxlist)", "C._EFFECTS = EFFECTS\nlocal function RunEffects(X, fxlist)")
source = patchOnce(source, "if v == nil then for _, x in pairs(st) do v = x; break end end",
    "if v == nil then C._fallback = true; for _, x in pairs(st) do v = x; break end end")
local C = assert(loadstring(source, "@pb_core.lua"))()
package.loaded["pb_core"] = C

local D = require("pb_data")
local R = require("pb_retail")
local Rules = require("pb_rules")

local NAMES = {}
for i = 1, 40 do NAMES[i] = string.format("FX%02d", i - 1) end
NAMES[41] = "FX145"
NAMES[42] = "FX40"
assert(#C._EFFECTS == 42, "expected 42 effect handlers, found " .. #C._EFFECTS)

local counts = {}
for i, entry in ipairs(C._EFFECTS) do
    local handler, name = entry[2], NAMES[i]
    entry[2] = function(X, f)
        counts[name] = (counts[name] or 0) + 1
        return handler(X, f)
    end
end

local M = { C = C, D = D, R = R, Rules = Rules, counts = counts }

function M.unknownTotal()
    local total = 0
    for _, n in pairs(C.unknown) do total = total + n end
    return total
end

local function auraText(p)
    local parts = {}
    for _, a in ipairs(p.auras) do parts[#parts + 1] = tostring(a.id) .. ":" .. tostring(a.left) end
    table.sort(parts)
    return table.concat(parts, ",")
end

function M.snapshot(b)
    local rows = {}
    for _, side in ipairs({ "P", "E" }) do
        for idx, p in ipairs(b[side]) do
            rows[#rows + 1] = { side, tostring(idx), tostring(p.hp), tostring(p.max), tostring(p.power),
                tostring(C.Speed(p)), tostring(p.cd[1]) .. "," .. tostring(p.cd[2]) .. "," .. tostring(p.cd[3]),
                auraText(p), C.StatusString(p) }
        end
    end
    return rows
end

function M.built(pet)
    local ids = {}
    for slot = 1, 3 do ids[slot] = pet.abil[slot] and tostring(pet.abil[slot].id) or "nil" end
    return { tostring(pet.max), tostring(pet.power), tostring(pet.speed), table.concat(ids, ",") }
end

function M.tips(pet)
    local rows = {}
    for slot = 1, 3 do
        local ab = pet.abil[slot]
        if ab then
            C._fallback = false
            local text = C.Describe({ text = ab.text, turns = ab.turns, family = ab.family }, pet.power)
            assert(text == ab.tip, "tooltip differs from NewPet's")
            rows[#rows + 1] = { slot = slot, text = text, fallback = C._fallback == true }
        end
    end
    return rows
end

function M.choices(b)
    local pet = b.P[b.active.P]
    local ready, locked, bench = {}, {}, {}
    for slot = 1, 3 do
        if C.Ready(pet, slot) then ready[#ready + 1] = slot else locked[#locked + 1] = slot end
    end
    for idx, q in ipairs(b.P) do
        if idx ~= b.active.P and q.hp > 0 then bench[#bench + 1] = idx end
    end
    return { ready = ready, locked = locked, bench = bench, canTrap = C.CanTrap(b), channel = pet.channel ~= nil,
        active = b.active.P }
end

function M.kitSlots(entry)
    local rows = {}
    for _, k in ipairs(C.Kit(entry)) do
        local ab = R.abilities[k.ability.id]
        local turns = {}
        for _, t in ipairs(ab.turns or {}) do
            local fx = {}
            for _, f in ipairs(t.fx) do
                local p = f.p or {}
                fx[#fx + 1] = { prop = f.prop, p1 = p[1] or 0, p2 = p[2] or 0, p3 = p[3] or 0 }
            end
            turns[#turns + 1] = { event = t.event, fx = fx }
        end
        rows[#rows + 1] = { slot = k.slot, opt = k.opt, unlock = k.unlock, id = k.ability.id,
            priority = k.ability.priority == true, turns = turns }
    end
    return rows
end

function M.kitProps(entry)
    local found = {}
    local function scan(ab)
        for _, t in ipairs(ab.turns or {}) do
            for _, f in ipairs(t.fx) do
                local p = f.p or {}
                found[#found + 1] = { prop = f.prop, p1 = p[1] or 0, p2 = p[2] or 0, p3 = p[3] or 0 }
            end
        end
    end
    for _, k in ipairs(C.Kit(entry)) do scan(R.abilities[k.ability.id]) end
    return found
end

return M
