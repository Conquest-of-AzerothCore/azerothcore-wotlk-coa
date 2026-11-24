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
local BEFORE = {
    rebirth = "table.remove(p.auras, ai)",
    revive = "p.revived = true",
    detonate = "local d = math.max(1, math.floor(Round(base * Bonus(bomb.pwr))",
    portal = "local from = b.active[sd]; cur.channel = nil; b.active[sd] = bi",
    chew = "local before = #ev; p.useFam = a.fam;",
    leech = "Heal(b, ev, sd, i2, math.floor(math.min(auraDmg, p.hp) * leechPct / 100))",
    siphon = "Heal(b, ev, sd, i2, Rules.Heal(f.p[1], a.pwr or q.power))",
    teamaura = "teamK = (teamK or 0) + 1",
    charges = "a.charges = a.charges - 1;",
    wall = "b.wall.charges = b.wall.charges - 1;",
    split_bench = "share = MagicCap(q, share);",
    castate_bench = "local d = MagicCap(q, Dmg(pet, q, p[1]));",
    swap145 = "b.active[side] = cand[1]",
    swap39 = "b.active[o2] = cand[(f.prop == 139) and 1 or b.rng(1, #cand)]",
}
local AFTER_THEN = {
    reflect204 = "if rd > 0 then",
    reflect179 = "if rf.prop == 179 and pet.hp > 0 then",
    webbing = "if rf.prop == 24 and pet.hp > 0 then",
    plagued = "if rf.prop == 23 and pet.hp > 0 then Heal(",
    meteor = 'if q.hp > 0 and Mod(q, "unkillable") == 0 and not roach then',
    photosynthesis = "if w and sn and w[sn] then heal = heal + Rules.Heal(f.p[1], a.pwr or p.power) end",
    spore = "then ApplyAura(b, ev, s, idx, f.aura, math.max(1, f.p[3] or 1), false, nil, a.src)",
    lockout = "if f9.prop == 129 then",
    ally_heal = "if k == X.h100 then",
    team_heal = "if k == X.healed then",
}
for name, anchor in pairs(BEFORE) do
    source = patchOnce(source, anchor, 'C._count("' .. name .. '"); ' .. anchor)
end
for name, anchor in pairs(AFTER_THEN) do
    local at = anchor:find("then", 1, true)
    source = patchOnce(source, anchor, anchor:sub(1, at + 3) .. ' C._count("' .. name .. '");' .. anchor:sub(at + 4))
end
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

local branches = {}
C._count = function(name) branches[name] = (branches[name] or 0) + 1 end

local M = { C = C, D = D, R = R, Rules = Rules, counts = counts, branches = branches }

local DAMAGE = { [24] = true, [222] = true, [96] = true, [62] = true }

local function auraFeatures(id, found)
    local aura = id and id ~= 0 and R.abilities[id]
    local states = R.states[id] or {}
    if states.Mechanic_IsBomb then found.detonate = true end
    if states.Special_BlockedAttackCount then found.charges = true end
    if not aura then return end
    local text = aura.text or ""
    for _, t in ipairs(aura.turns or {}) do
        local damage = false
        for _, f in ipairs(t.fx) do if DAMAGE[f.prop] then damage = true end end
        for _, f in ipairs(t.fx) do
            if t.event == 1 and f.prop == 204 then found.reflect204 = true end
            if t.event == 1 and f.prop == 179 then found.reflect179 = true end
            if t.event == 2 and f.prop == 24 then found.webbing = true end
            if t.event == 1 and f.prop == 23 then found.plagued = true end
            if t.event == 7 and f.prop == 111 then found.rebirth = true end
            if t.event == 9 and f.prop == 129 then found.lockout = true end
            if t.event == 255 then
                if DAMAGE[f.prop] then found.chew = true end
                if f.prop == 32 and damage then found.leech = true end
                if f.prop == 23 and damage then found.siphon = true end
                if f.prop == 171 then found.photosynthesis = true end
                if (f.prop == 54 or f.prop == 178 or f.prop == 52) and f.aura and f.aura ~= 0 then found.spore = true end
                if damage and (text:find("your team", 1, true) or text:find("enemy team", 1, true)) then found.teamaura = true end
            end
        end
    end
end

function M.branchCandidates()
    local out = {}
    local function add(name, entry, k)
        out[name] = out[name] or {}
        out[name][#out[name] + 1] = { entry = entry, slot = k.slot, opt = k.opt }
    end
    for entry in pairs(D.species) do
        local family = C.Family(entry)
        for _, k in ipairs(C.Kit(entry)) do
            local ab = R.abilities[k.ability.id]
            local found = {}
            if family == "Undead" or family == "Mechanical" then found.revive = true end
            for _, t in ipairs(ab.turns or {}) do
                local heals = 0
                for _, f in ipairs(t.fx) do if f.prop == 23 then heals = heals + 1 end end
                if heals > 1 then found.team_heal = true end
                for _, f in ipairs(t.fx) do
                    auraFeatures(f.aura, found)
                    if t.event ~= 255 and (f.prop == 145 or f.prop == 107) then found.portal = true end
                    if t.event == 255 and f.prop == 145 then found.swap145 = true end
                    if t.event == 255 and (f.prop == 107 or f.prop == 139) then found.swap39 = true end
                    if f.prop == 141 then found.split_bench = true end
                    if f.prop == 29 and (f.p[3] or 0) > 0 then found.castate_bench = true end
                    if f.prop == 100 then found.ally_heal = true end
                    if f.prop == 159 then found.meteor = true end
                    if f.prop == 150 then found.wall = true end
                end
            end
            for name in pairs(found) do add(name, entry, k) end
        end
    end
    return out
end

function M.kitTips(entry, power)
    local rows = {}
    for _, k in ipairs(C.Kit(entry)) do
        local ab = k.ability
        C._fallback = false
        local text = C.Describe({ text = ab.text, turns = ab.turns, family = ab.family }, power)
        rows[#rows + 1] = { slot = k.slot, opt = k.opt, text = text, fallback = C._fallback == true }
    end
    return rows
end

function M.fallbackCensus(power)
    local total, hits = 0, 0
    for entry in pairs(D.species) do
        for _, row in ipairs(M.kitTips(entry, power)) do
            total = total + 1
            if row.fallback then hits = hits + 1 end
        end
    end
    return { total = total, hits = hits }
end

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

function M.libraryAbility(aid)
    local a = assert(R.abilities[aid], "library ability " .. tostring(aid) .. " missing")
    local main, procs = {}, {}
    for _, t in ipairs(a.turns) do if t.event == 255 then main[#main + 1] = t else procs[#procs + 1] = t end end
    if #main == 0 then main, procs = a.turns, {} end
    local priority = (a.text or ""):find("always goes first") ~= nil
    for _, t in ipairs(procs) do
        for _, f in ipairs(t.fx) do if f.prop == 79 or f.prop == 145 or f.prop == 107 then priority = true end end
    end
    return { id = aid, name = a.name, retailName = a.name, icon = "", tip = "", text = a.text, family = a.family,
        cd = a.cd, turns = main, procs = procs, priority = priority }
end

function M.setWeather(b, id, left)
    b.weather = { id = id, left = left }
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
