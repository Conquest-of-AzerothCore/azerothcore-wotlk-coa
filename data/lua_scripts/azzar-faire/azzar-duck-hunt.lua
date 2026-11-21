--[[ Venture Co / Azzar Faire: DUCK HUNT mini-game (Rowan/Claude 2026-11-12, v2 "like live").
  Needs mod-ale (ALE) on + azzar-duck-hunt.sql applied. Built from the 1-second footage pass
  (faire-cache\duck-hunt-1s\DUCK-HUNT-1S-SCAN-2026-11-12.md).

  FLOW (as on live):
   1. Takk (371936) at the Duck Hunt tent on Dawnrise: "Let's blast some ducks!" -> you + up to 4 group members near you (bots too)
      go to the arena (map 960). The arena is built: 5 cannons at the platform rim, the hedge + trees at the wall, Takk on the platform.
   2. Talk to Takk on the platform: "I'm ready!" (bots are ready by themselves). When everyone is ready:
      victory text, "Azzar Event: Round N is starting!", 10..1 countdown, "Ready!" / "Go!", everyone is put in a cannon.
   3. A round is ONE GAME of up to 5:00. The sky fills with ducks (+1), the golden duck (+50) shows up every 30-60 s, bombs in the
      swarm (-20), frogs hop onto the platform and poison the cannons, bears (round 2+) walk in and throw you out of your cannon.
      The game ends at 0:00 or when every cannon is destroyed.
   4. Game Over: one ranked line per player (Earned / Lost / Final), "Round N is complete. Round N+1 is now available!",
      quest credit for Lead Stuffed Ducks / its daily. Talk to Takk again to play the next (harder) round, or to go back to the Faire.
  VICTORY: at least one cannon standing and the team reaches the target: 250 per player in round 1, +75 per player each round
  (1250 / 1625 / 2000 ... for 5 players; live's 3000 at round 11).
  BOTS: seated by the script, aimed + fired by the script (every ~1.5-2.5 s, avoid bombs, repair when hurt).
  Safety hatch: say #leave in the arena. Lines starting with [DuckHunt] in the server log are from this script. ]]

-- ======================= SETTINGS =======================
local DH = {
  MAP = 960,
  CENTRE = { 5960.19, -4898.84, 12.48 },        -- Rowan .gps: middle of the round platform (the '8')
  CANNON_R = 7.9,                                -- rim is 8.3 yd out (Rowan .gps); cannons at the rim, facing out
  GRASS_Z = 9.95,                                -- Rowan .gps on the grass 23 yd out (5982.09 -4890.81 9.947, 23:27); walkway at the wall was 9.69
  BUSH_R = 73.0,                                 -- hedge along the wall
  HEDGE_COUNT = 110, HEDGE_ROWS = 2, HEDGE_ROW_STEP = 3.5, HEDGE_DISPLAYS = { 137621, 137622, 137623, 137624 }, HEDGE_SCALE_MIN = 1.3, HEDGE_SCALE_MAX = 2.0,
  TREE_COUNT = 26, TREE_BACK = 3.0, TREE_DISPLAYS = { 137625, 137626, 137627, 137628 }, TREE_SCALE_MIN = 0.8, TREE_SCALE_MAX = 1.15,
  TAKK_SPOT = { 909, -1795.91, -11999.08, 61.68, 2.90 },   -- back at the Faire, in front of Takk
  MAX_PLAYERS = 5, JOIN_RANGE = 60.0,
  TARGET_BASE = 250, TARGET_STEP = 75,           -- per player: round 1 = 250 (1250 for 5), +75 a round; reaches live's 3000 (for 5) at round 11
  GAME_SECONDS = 300,                            -- live: 'End of Game 5:00'
  COUNTDOWN = 10,
  -- the swarm: ducks alive at once (server load cap) and how many may be added per 0.5 s tick, per round (index = round, last repeats)
  SWARM_CAP   = { 110, 130, 150, 150, 150 },
  SWARM_SPAWN = { 6, 7, 8, 9, 10 },
  DUCK_LIFE_MS = 18000, FLY_Z_MIN = 6.0, FLY_Z_MAX = 34.0,
  -- duck flight mix (Rowan 23:41): most circle the back of the tent like live (in front of the cannons, wall behind them),
  -- a share flies straight across the middle like before. 0 = pure live style, 1 = all across.
  DUCK_CROSS_SHARE = 0.2,
  ORBIT_R_MIN = 48.0, ORBIT_R_MAX = 66.0,         -- the circling lane: between the frogs' ring and the hedge/trees (r 73-76)
  ORBIT_Z_MIN = 8.0, ORBIT_Z_MAX = 28.0,          -- height above the platform
  ORBIT_STEP = 0.35,                              -- radians per leg (~20 yd at r 60); a new leg is set when the duck nears the old one
  BOMB_EVERY = 30,                               -- 1 bomb per ~30 ducks spawned
  BOMB_DISPLAY = 34339, BOMB_SCALE = 1.6,        -- goblin bomb model (the live bomb marker is invisible on our client)
  GOLDEN_MIN = 30, GOLDEN_MAX = 60,              -- seconds between golden ducks
  FROG_FIRST = { 10, 10, 8, 8, 8 }, FROG_EVERY_MIN = 12, FROG_EVERY_MAX = 20, FROG_GROUP = { 5, 6, 7, 8, 8 },   -- more frogs (Rowan 23:15, again 23:46)
  FROG_START_R = 66.0,                           -- frogs come out of the hedge (live; Rowan 23:21 watched the bushes)
  FROG_BOT_GRACE_MS = 8000,                      -- bots can't hurt a frog (aimed OR splash) for 8 s after it lands, so you see it poison the cannon; players can
  FROG_SCALE = 1.5,
  FROG_STOP_R_MIN = 27.0, FROG_STOP_R_MAX = 35.0, -- live: frogs hop in to a ring on the grass and stop (Rowan .gps 5975.25 -4872.07 9.95 = 30.7 yd out)
  FROG_SPIT_MS_MIN = 2500, FROG_SPIT_MS_MAX = 3500, FROG_SPIT_PCT = 0.02, FROG_SPIT_SPEED = 25.0,  -- then spit poison bolts at a cannon (255641 flies 25 yd/s)
  FROG_HOP = 8.0, FROG_HOP_MS = 1100, FROG_POISON_PCT = 0.025, FROG_POISON_MS = 1000,
  BEAR_HOP = 12.0, BEAR_HOP_MS = 1500,
  BEAR_FROM_ROUND = 2, BEAR_FIRST = 90, BEAR_EVERY_MIN = 55, BEAR_EVERY_MAX = 80, BEAR_HP = 6,
  BEAR_MAUL_PCT = 0.10, BEAR_MAUL_MS = 3000, BEAR_THROW_MS = 6000, THROWN_OUT_MS = 4000,
  AIM_LINE_R = 3.5,                              -- player shots: anything within 3.5 yd of the line cannon -> crosshair point is 'in the line of fire'
  HEAT_DRAIN = 3, OVERHEAT_STUN_MS = 3000,
  BOT_SHOT_MS_MIN = 1500, BOT_SHOT_MS_MAX = 2500, BOT_AIM_ERROR = 7.0,
  LOBBY_SECONDS = 60,                            -- after a game: 60 s to ready up for the next round, then everyone is sent back to the Faire
  STATUS_EVERY = 30,                             -- seconds between status lines (time / ducks / score)
}
local E = { TAKK = 371936, TAKK_ARENA = 99532, CANNON = 99530, DUCK = 99531, DUCK2 = 99547, BOMB = 99549,
            FROG = 99546, BEAR = 99548, BUSHES = { 99534, 99535, 99536, 99537, 99538 }, CREDIT = 372026 }
local S = { SHOT = 255638, SHOT_HIT = 255639, SHOT2 = 256462, SHOT2_HIT = 256463, REPAIR = 255642, STUN = 255620,
            FROG_SPIT = 255641, GOLDEN = 255643, SCORE1 = 255647, SCORE50 = 255648, SCOREM20 = 255653, BOMB_BOOM = 256470, RIDE = 46598 }
local Q_BASE, Q_DAILY = 1650230, 1650269
local TEXT_GREET, TEXT_RULES = 1200153, 1200154
local POWER_ENERGY = 3
local TEMPSUMMON_TIMED_DESPAWN = 3
local NPCFLAG_GOSSIP = 1
-- =========================================================

local Games = {}          -- [instanceId] = session (one group in the arena, many rounds)
local Pending = {}        -- [starterLow] = session waiting for its starter to arrive

local function log(msg) print("[DuckHunt] " .. msg) end
local missingLogged = {}
local function try(obj, method, ...)                 -- call a method only if this ALE build has it
  if not obj then return nil end
  local f = obj[method]
  if type(f) ~= "function" then
    if not missingLogged[method] then missingLogged[method] = true; log("note: this ALE has no " .. method .. "(), skipped") end
    return nil
  end
  local ok, r = pcall(f, obj, ...)
  if not ok then log(method .. " failed: " .. tostring(r)) end
  return r
end
local function now() return GetCurrTime() end
local function rnd(a, b) return a + math.random() * (b - a) end
local function perRound(t, round) return t[math.min(round, #t)] end
local function polar(r, ang, z) return DH.CENTRE[1] + r * math.cos(ang), DH.CENTRE[2] + r * math.sin(ang), z end
local function cannonAng(i) return (i - 1) * (2 * math.pi / 5) end
local function cannonSpot(i) local a = cannonAng(i); local x, y, z = polar(DH.CANNON_R, a, DH.CENTRE[3]); return x, y, z, a end
local function mmss(sec) sec = math.max(0, math.floor(sec)); return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end

local function getPlayer(g, low)
  local m = g.members[low]
  if not m then return nil end
  local pl = GetPlayerByGUID(m.guid)
  if pl and pl:IsInWorld() then return pl end
  return nil
end
local function inArena(g, pl) return pl and pl:GetMapId() == DH.MAP and pl:GetInstanceId() == g.inst end
local function getMap(g)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inArena(g, pl) then return pl:GetMap(), pl end
  end
  return nil
end
local function getObj(g, guid)
  if not g.map or not guid then return nil end
  return g.map:GetWorldObject(guid)
end
local function tell(g, msg, center)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and not pl:IsBot() then
      pl:SendBroadcastMessage(msg)
      if center then pl:SendAreaTriggerMessage(msg) end
    end
  end
end
local DHT = "|cffffd200[Duck Hunt]|r "
local AZT = "|cffff8000Azzar Event:|r "
local function yell(g, msg) local t = getObj(g, g.takkGuid); if t then t:SendUnitYell(msg, 0) end end
local function say(g, msg) local t = getObj(g, g.takkGuid); if t then t:SendUnitSay(msg, 0) end end

local function spawnRaw(g, entry, x, y, z, o, lifeMs)
  local _, anchor = getMap(g)
  if not anchor then return nil end
  return anchor:SpawnCreature(entry, x, y, z, o or 0, TEMPSUMMON_TIMED_DESPAWN, lifeMs or 20000)
end
local function spawnFixed(g, entry, x, y, z, o, lifeMs)      -- arena pieces (kept in g.fixed, removed at the end)
  local c = spawnRaw(g, entry, x, y, z, o, lifeMs)
  if c then g.fixed[#g.fixed + 1] = c:GetGUID() end
  return c
end
local function addTarget(g, c, t)                              -- game creatures (ducks, bombs, frogs, bears)
  -- they are hostile (so the cannon shot can hit them) but must never aggro: a hostile frog/bear chased the player
  -- on the server's floorless map and dropped to z 0, under the arena, where nobody could see it (Rowan 22:44 'no frogs')
  try(c, "SetReactState", 0)                                  -- REACT_PASSIVE
  try(c, "SetAggroEnabled", false)
  t.born = now()
  t.guid = c:GetGUID(); g.targets[c:GetGUIDLow()] = t; g.nTargets = g.nTargets + 1
  if t.kind == "duck" then g.ducksAlive = g.ducksAlive + 1 end
end
local function dropTarget(g, key)
  local t = g.targets[key]
  if not t then return end
  if t.kind == "duck" and not t.counted then g.ducksAlive = g.ducksAlive - 1; t.counted = true end
  g.targets[key] = nil; g.nTargets = g.nTargets - 1
end

-- -------- scoring --------
local function award(g, low, pts)
  local m = low and g.members[low]
  if not m then return end
  if pts >= 0 then m.earned = m.earned + pts else m.lost = m.lost - pts end
  g.score = g.score + pts
end

local function shooterLow(g, unit)
  if not unit then return nil end
  local low = unit:GetGUIDLow()
  if unit:GetTypeId() == 4 then return g.members[low] and low or nil end
  local cn = g.cannons[low]
  if cn then
    local kit = unit:GetVehicleKit()
    local pas = kit and kit:GetPassenger(0)
    if pas and g.members[pas:GetGUIDLow()] then return pas:GetGUIDLow() end
    return cn.owner
  end
  return nil
end

local function gameOf(creature) return Games[creature:GetInstanceId()] end

local function onShotHit(creature, caster)
  local g = gameOf(creature)
  if not g or g.state ~= "play" then return end
  local key = creature:GetGUIDLow()
  local t = g.targets[key]
  if not t or t.dead then return end
  -- frogs and bears can't be hit until they have landed by their cannon: otherwise the bots' splash on low ducks killed them
  -- out on the grass before anyone saw one (log 23:05: first frog killed 24 yd out by a bot)
  if (t.kind == "frog" or t.kind == "bear") and not t.arrived and now() - (t.born or 0) < 20000 then return end   -- 20 s safety: a stuck one can still be shot
  local low = shooterLow(g, caster)
  if t.kind == "frog" and low and g.members[low] and g.members[low].bot and now() < (t.arrivedAt or 0) + DH.FROG_BOT_GRACE_MS then return end
  if t.kind == "bear" then
    t.hp = t.hp - 1
    creature:CastSpell(creature, S.SCORE1, true)
    if t.hp > 0 then return end
  end
  t.dead = true
  if t.kind == "duck" then
    g.ducksKilled = g.ducksKilled + 1
    award(g, low, t.golden and 50 or 1)
    creature:CastSpell(creature, t.golden and S.SCORE50 or S.SCORE1, true)
    if t.golden and low then tell(g, DHT .. g.members[low].name .. " tagged the Golden Duck and earned |cff00ff00+50 points|r!") end
    if t.kind == "duck" and not t.counted then g.ducksAlive = g.ducksAlive - 1; t.counted = true end
  elseif t.kind == "bomb" then
    if low then
      award(g, low, -20)
      tell(g, DHT .. g.members[low].name .. " hit a |cffff2020Bomb|r and lost |cffff2020-20 points|r!")
    end
    creature:CastSpell(creature, S.SCOREM20, true)
    creature:CastSpell(creature, S.BOMB_BOOM, true)
  end
  g.stats[t.kind] = (g.stats[t.kind] or 0) + 1
  if t.kind == "frog" and not g.frogDeathLogged then
    g.frogDeathLogged = true
    log(string.format("instance %d: first frog killed at %.1f %.1f %.1f by %s", g.inst, creature:GetX(), creature:GetY(), creature:GetZ(), (low and g.members[low] and g.members[low].name) or "?"))
  end
  local who = low and g.members[low]
  if who then if who.bot then g.stats.byBot = g.stats.byBot + 1 else g.stats.byPlayer = g.stats.byPlayer + 1 end end
  try(creature, "SetDisableGravity", false)
  local killer = caster or creature
  killer:DealDamage(creature, creature:GetMaxHealth() * 2, false)
  creature:DespawnOrUnsummon(1200)
end

for _, entry in ipairs({ E.DUCK, E.DUCK2, E.BOMB, E.FROG, E.BEAR }) do
  RegisterCreatureEvent(entry, 30, function(event, caster, spellid, effindex, creature)     -- ON_DUMMY_EFFECT (the live shot lands as a dummy)
    if spellid == S.SHOT_HIT or spellid == S.SHOT2_HIT or spellid == S.SHOT or spellid == S.SHOT2 then onShotHit(creature, caster) end
  end)
  RegisterCreatureEvent(entry, 14, function(event, creature, caster, spellid)               -- ON_HIT_BY_SPELL (backup)
    if spellid == S.SHOT_HIT or spellid == S.SHOT2_HIT then onShotHit(creature, caster) end
  end)
end

-- -------- arena --------
local function clearLeftovers(g)
  local _, anchor = getMap(g)
  if not anchor then return end
  local n = 0
  local all = { E.TAKK_ARENA, E.CANNON, E.DUCK, E.DUCK2, E.BOMB, E.FROG, E.BEAR }
  for _, b in ipairs(E.BUSHES) do all[#all + 1] = b end
  for _, entry in ipairs(all) do
    for _, c in ipairs(try(anchor, "GetCreaturesInRange", 150, entry) or {}) do c:DespawnOrUnsummon(0); n = n + 1 end
  end
  if n > 0 then log("cleared " .. n .. " leftover arena creatures") end
end

local LIFE = 4 * 3600 * 1000
local function spawnCannon(g, i, low)
  local x, y, z, ang = cannonSpot(i)
  local c = spawnFixed(g, E.CANNON, x, y, z, ang, LIFE)
  if not c then return end
  c:SetPower(0, POWER_ENERGY)
  g.cannons[c:GetGUIDLow()] = { guid = c:GetGUID(), owner = low, i = i, nextShot = 0, stunUntil = 0, repairReady = 0 }
  g.members[low].cannonLow = c:GetGUIDLow()
end

local function buildArena(g)
  clearLeftovers(g)
  local takk = spawnFixed(g, E.TAKK_ARENA, DH.CENTRE[1], DH.CENTRE[2], DH.CENTRE[3], 0, LIFE)
  if takk then g.takkGuid = takk:GetGUID(); try(takk, "SetNPCFlags", NPCFLAG_GOSSIP) end
  for i = 1, DH.HEDGE_COUNT do
    local ang = (i - 1) * (2 * math.pi / DH.HEDGE_COUNT) + rnd(-0.02, 0.02)
    local r = DH.BUSH_R - ((i - 1) % DH.HEDGE_ROWS) * DH.HEDGE_ROW_STEP + rnd(-1.0, 1.0)
    local x, y, z = polar(r, ang, DH.GRASS_Z)
    local b = spawnFixed(g, E.BUSHES[math.random(1, #E.BUSHES)], x, y, z, rnd(0, 2 * math.pi), LIFE)
    if b then
      try(b, "SetDisplayId", DH.HEDGE_DISPLAYS[math.random(1, #DH.HEDGE_DISPLAYS)])
      try(b, "SetScale", rnd(DH.HEDGE_SCALE_MIN, DH.HEDGE_SCALE_MAX))
    end
    g.bushes[#g.bushes + 1] = { x = x, y = y, z = z, ang = ang }
  end
  for i = 1, DH.TREE_COUNT do
    local ang = (i - 1) * (2 * math.pi / DH.TREE_COUNT) + rnd(-0.08, 0.08)
    local x, y, z = polar(DH.BUSH_R + DH.TREE_BACK + rnd(-1, 1), ang, DH.GRASS_Z)
    local b = spawnFixed(g, E.BUSHES[math.random(1, #E.BUSHES)], x, y, z, rnd(0, 2 * math.pi), LIFE)
    if b then
      try(b, "SetDisplayId", DH.TREE_DISPLAYS[math.random(1, #DH.TREE_DISPLAYS)])
      try(b, "SetScale", rnd(DH.TREE_SCALE_MIN, DH.TREE_SCALE_MAX))
    end
  end
  for low, m in pairs(g.members) do spawnCannon(g, m.slot, low) end
  log(string.format("arena built in instance %d for %d players", g.inst, g.count))
end

-- put a member in their cannon (humans only while a game is on; bots always, so they never stand on the floorless platform)
local function seat(g, low)
  local m = g.members[low]
  local pl = getPlayer(g, low)
  if not m or not inArena(g, pl) or not m.cannonLow then return end
  if not m.bot and g.state ~= "countdown" and g.state ~= "play" then return end
  if m.thrownUntil and now() < m.thrownUntil then return end
  -- players are seated at the start of a round and after a bear throws them out; if they climb out themselves they stay out
  -- (Rowan 23:04). They can get back in by clicking the cannon or saying #cannon.
  if not m.bot and not m.wantSeat then
    -- the player is in charge of their own seat (Rowan 23:15): Leave Vehicle to get out, click the cannon (green cursor) to get in.
    -- The script never puts you back. It only watches for you leaving, and if the server thinks you dropped under the
    -- floorless arena (z 0), lifts you back onto the platform where you really are, so the cannon click is in range.
    local cn0 = g.cannons[m.cannonLow]
    local c0 = cn0 and getObj(g, cn0.guid)
    local kit0 = c0 and c0:GetVehicleKit()
    local pas0 = kit0 and kit0:GetPassenger(0)
    local inMine = pas0 and pas0:GetGUIDLow() == low
    if inMine or try(pl, "IsInVehicle") then
      m.seated = true
    elseif m.seated then
      m.seated = false
      local dx, dy = pl:GetX() - DH.CENTRE[1], pl:GetY() - DH.CENTRE[2]
      if pl:GetZ() < DH.CENTRE[3] - 3 and dx * dx + dy * dy <= 12 * 12 then
        pl:NearTeleport(pl:GetX(), pl:GetY(), DH.CENTRE[3] + 0.3, pl:GetO())
        log(string.format("instance %d: %s left the cannon, server had them at z %.1f, lifted onto the platform", g.inst, m.name, pl:GetZ()))
      end
    end
    return
  end
  local cn = g.cannons[m.cannonLow]
  local c = cn and getObj(g, cn.guid)
  if not c or not c:IsAlive() then return end
  local kit = c:GetVehicleKit()
  if not kit then return end
  local pas = kit:GetPassenger(0)
  if pas then
    -- boarding often finishes a tick AFTER the call below, so wantSeat was never cleared and the next time you climbed out
    -- the script put you straight back in (Rowan 23:11). Clear it as soon as we see you in the seat.
    if pas:GetGUIDLow() == low and not m.bot then m.wantSeat = false; m.seated = true end
    return
  end
  -- after leaving the cannon the server drops you to its own 'ground' (z 0: no floor data under the platform), out of reach
  -- of the boarding spell, so you were never put back in (Rowan 23:00). Bring the player next to the cannon first, board next tick.
  if pl:GetDistance(c) > 3 then
    local ang = cannonAng(m.slot)
    pl:NearTeleport(DH.CENTRE[1] + (DH.CANNON_R - 1.5) * math.cos(ang), DH.CENTRE[2] + (DH.CANNON_R - 1.5) * math.sin(ang), DH.CENTRE[3] + 0.3, ang)
    g.nextSeat = math.min(g.nextSeat or 0, now() + 500)
    return
  end
  pl:CastSpell(c, S.RIDE, true)
  if not kit:GetPassenger(0) then kit:AddPassenger(pl, 0) end
  if kit:GetPassenger(0) and not m.bot then m.wantSeat = false; m.seated = true end
  if not kit:GetPassenger(0) then
    m.seatFails = (m.seatFails or 0) + 1
    if m.seatFails == 3 then log(string.format("instance %d: could not put %s back in cannon %d (distance %.1f)", g.inst, m.name, m.slot, pl:GetDistance(c))) end
  else
    m.seatFails = 0
  end
end

local function unseat(g, low)
  local m = g.members[low]
  local cn = m and m.cannonLow and g.cannons[m.cannonLow]
  local c = cn and getObj(g, cn.guid)
  local pl = getPlayer(g, low)
  if not c or not pl then return end
  local kit = c:GetVehicleKit()
  local pas = kit and kit:GetPassenger(0)
  if pas and pas:GetGUIDLow() == low then
    try(kit, "RemovePassenger", pl)
    -- the cannon seat has no Leave button and RemovePassenger alone did not free the client (Rowan 22:36):
    -- a short teleport on the same map always takes a player out of a vehicle. Lands just inside the cannon, on the platform.
    local m2 = g.members[low]
    local ang = cannonAng(m2.slot)
    pl:NearTeleport(DH.CENTRE[1] + (DH.CANNON_R - 2.5) * math.cos(ang), DH.CENTRE[2] + (DH.CANNON_R - 2.5) * math.sin(ang), DH.CENTRE[3] + 0.3, ang + math.pi)
  end
end

local function aliveCannons(g)
  local list = {}
  for low, cn in pairs(g.cannons) do
    local c = getObj(g, cn.guid)
    if c and c:IsAlive() then list[#list + 1] = { low = low, cn = cn, unit = c } end
  end
  return list
end

-- -------- the swarm and the critters --------
local function orbitLeg(d, tg)
  tg.oa = tg.oa + tg.odir * DH.ORBIT_STEP
  tg.oz = math.max(DH.ORBIT_Z_MIN, math.min(DH.ORBIT_Z_MAX, tg.oz + rnd(-3, 3)))
  tg.ox, tg.oy, tg.ozz = polar(tg.or_ + rnd(-2, 2), tg.oa, DH.CENTRE[3] + tg.oz)
  tg.legUntil = now() + 4500
  d:MoveTo(1, tg.ox, tg.oy, tg.ozz, false)
end

-- circle the back of the tent: rise out of the hedge, then fly leg by leg around the wall, clockwise or anticlockwise
local function flyOrbit(g, d, b, tg)
  try(d, "SetDisableGravity", true)
  tg.orbit = true
  tg.odir = (math.random() < 0.5) and -1 or 1
  tg.or_ = rnd(DH.ORBIT_R_MIN, DH.ORBIT_R_MAX)
  tg.oz = rnd(DH.ORBIT_Z_MIN, DH.ORBIT_Z_MAX)
  tg.oa = b.ang
  orbitLeg(d, tg)
end

local function fly(g, d, b, tg)
  if math.random() < DH.DUCK_CROSS_SHARE then
    local a = b.ang + math.pi + rnd(-0.9, 0.9)
    local ex, ey, ez = polar(rnd(15, DH.BUSH_R - 5), a, DH.CENTRE[3] + rnd(DH.FLY_Z_MIN, DH.FLY_Z_MAX))
    try(d, "SetDisableGravity", true)
    d:MoveTo(1, ex, ey, ez, false)
  else
    flyOrbit(g, d, b, tg)
  end
end

local function flyAcross(g, d, b)
  local a = b.ang + math.pi + rnd(-0.9, 0.9)
  local ex, ey, ez = polar(rnd(15, DH.BUSH_R - 5), a, DH.CENTRE[3] + rnd(DH.FLY_Z_MIN, DH.FLY_Z_MAX))
  try(d, "SetDisableGravity", true)
  d:MoveTo(1, ex, ey, ez, false)
end

local function spawnDucks(g, n)
  for k = 1, n do
    local b = g.bushes[math.random(1, #g.bushes)]
    g.spawnedCount = g.spawnedCount + 1
    local isBomb = (g.spawnedCount % DH.BOMB_EVERY == 0)
    local entry = isBomb and E.BOMB or ((math.random() < 0.5) and E.DUCK or E.DUCK2)
    local d = spawnRaw(g, entry, b.x + rnd(-2, 2), b.y + rnd(-2, 2), b.z + rnd(0.5, 3), b.ang, DH.DUCK_LIFE_MS)
    if d then
      local tg = isBomb and { kind = "bomb" } or { kind = "duck" }
      addTarget(g, d, tg)
      if isBomb then try(d, "SetDisplayId", DH.BOMB_DISPLAY); try(d, "SetScale", DH.BOMB_SCALE) end
      fly(g, d, b, tg)
    end
  end
end

local function spawnGolden(g)
  local b = g.bushes[math.random(1, #g.bushes)]
  local d = spawnRaw(g, E.DUCK, b.x, b.y, b.z + 1, b.ang, 14000)
  if not d then return end
  local tg = { kind = "duck", golden = true }
  addTarget(g, d, tg)
  try(d, "AddAura", S.GOLDEN, d)
  try(d, "SetScale", 1.4)
  try(d, "SetSpeed", 6, 2.0, true)
  try(d, "SetSpeed", 1, 2.0, true)
  fly(g, d, b, tg)
end

local function spawnFrogs(g)
  local cannons = aliveCannons(g)
  if #cannons == 0 then return end
  for k = 1, perRound(DH.FROG_GROUP, g.round) do
    local tgt = cannons[math.random(1, #cannons)]
    local ang = cannonAng(tgt.cn.i)
    local sx, sy, sz = polar(DH.FROG_START_R, ang + rnd(-0.3, 0.3), DH.GRASS_Z)      -- on the grass in plain view of the cannons
    local f = spawnRaw(g, E.FROG, sx, sy, sz, ang + math.pi, 180000)
    if f then
      try(f, "SetScale", DH.FROG_SCALE)
      -- hops in to its spot on the grass ring (live footage + Rowan 23:35), then spits poison at its cannon from there
      local hx, hy, hz = polar(rnd(DH.FROG_STOP_R_MIN, DH.FROG_STOP_R_MAX), ang + rnd(-0.35, 0.35), DH.GRASS_Z)
      addTarget(g, f, { kind = "frog", cannon = tgt.low, nextHop = now() + 400, nextPoison = 0, hx = hx, hy = hy, hz = hz })
    end
  end
  log(string.format("instance %d: %d frog(s) sent (round %d)", g.inst, perRound(DH.FROG_GROUP, g.round), g.round))
  tell(g, DHT .. "Frogs spotted! Watch your cannons!", true)
end

local function spawnBears(g)
  local cannons = aliveCannons(g)
  if #cannons == 0 then return end
  for k = 1, math.max(1, math.floor(g.count / 2)) do
    local tgt = cannons[math.random(1, #cannons)]
    local ang = cannonAng(tgt.cn.i)
    local sx, sy, sz = polar(DH.BUSH_R - 2, ang + rnd(-0.2, 0.2), DH.GRASS_Z)
    local b = spawnRaw(g, E.BEAR, sx, sy, sz, ang + math.pi, 240000)
    if b then
      local hx, hy, hz = polar(DH.CANNON_R + 2.5, ang, DH.CENTRE[3])
      addTarget(g, b, { kind = "bear", cannon = tgt.low, hp = DH.BEAR_HP, nextMaul = 0, nextThrow = 0, nextHop = now() + 600, hx = hx, hy = hy, hz = hz })
    end
  end
  tell(g, DHT .. "Bears incoming! Brace yourselves!", true)
end

-- -------- per-tick work --------
local function tickTargets(g, t)
  local ducks = 0
  for key, tg in pairs(g.targets) do
    local u = getObj(g, tg.guid)
    if not u or not u:IsAlive() then
      dropTarget(g, key)
    else
      if tg.kind == "duck" and not tg.dead then ducks = ducks + 1 end
      if tg.orbit and not tg.dead then                       -- circling ducks/bombs: next leg when close to the last one (or 4.5 s)
        local ex, ey = tg.ox - u:GetX(), tg.oy - u:GetY()
        if ex * ex + ey * ey < 25 or now() >= tg.legUntil then orbitLeg(u, tg) end
      end
      if not tg.dead and (tg.kind == "frog" or tg.kind == "bear") and g.state == "play" then
        local cn = g.cannons[tg.cannon]
        local c = cn and getObj(g, cn.guid)
        if not c or not c:IsAlive() then
          local list = aliveCannons(g)
          if #list > 0 then
            local nt = list[math.random(1, #list)]
            tg.cannon = nt.low
            local ang = cannonAng(nt.cn.i)
            if tg.kind == "frog" then
              -- stays where it is and spits at another cannon
            else
              tg.hx, tg.hy, tg.hz = polar(DH.CANNON_R + 2.5, ang, DH.CENTRE[3])
            end
          end
        elseif tg.kind == "frog" then
          if tg.hitAt and t >= tg.hitAt then                  -- the poison bolt lands
            local hc = getObj(g, tg.hitCannon)
            if hc and hc:IsAlive() then u:DealDamage(hc, math.max(1, math.floor(hc:GetMaxHealth() * DH.FROG_SPIT_PCT)), false) end
            tg.hitAt = nil
          end
          local dx, dy = tg.hx - u:GetX(), tg.hy - u:GetY()
          local dist = math.sqrt(dx * dx + dy * dy)
          if dist > 1.5 then
            if t >= tg.nextHop then
              tg.nextHop = t + DH.FROG_HOP_MS
              local k = math.min(DH.FROG_HOP, dist) / dist
              local last = dist <= DH.FROG_HOP
              local nx, ny, nz = u:GetX() + dx * k, u:GetY() + dy * k, last and tg.hz or DH.GRASS_Z
              -- if the last jump did not move it (MoveJump ignored), place it there directly so it never gets stuck in the hedge
              if tg.lastX and math.abs(tg.lastX - u:GetX()) < 0.5 and math.abs(tg.lastY - u:GetY()) < 0.5 then
                tg.stuck = (tg.stuck or 0) + 1
                u:NearTeleport(nx, ny, nz, u:GetO())
                if not g.stuckLogged then g.stuckLogged = true; log(string.format("instance %d: frog jump did not move it (at %.1f %.1f %.1f), using NearTeleport hops", g.inst, u:GetX(), u:GetY(), u:GetZ())) end
              else
                u:MoveJump(nx, ny, nz, 10, 3)
              end
              tg.lastX, tg.lastY = u:GetX(), u:GetY()
              tg.hops = (tg.hops or 0) + 1
              if not g.hopLogged and tg.hops == 4 then
                g.hopLogged = true
                log(string.format("instance %d: frog after 4 hops at %.1f %.1f %.1f, %.1f yd from its cannon spot", g.inst, u:GetX(), u:GetY(), u:GetZ(), dist))
              end
            end
          elseif not tg.arrived then
            tg.arrived = true; tg.arrivedAt = t; g.stats.frogLanded = (g.stats.frogLanded or 0) + 1
            u:NearTeleport(tg.hx, tg.hy, tg.hz, u:GetO())     -- settle exactly on its spot on the grass
            try(u, "SetFacingToObject", c)
            tg.nextPoison = t + math.random(400, 1200)
          elseif t >= tg.nextPoison then
            if not g.frogLogged then
              g.frogLogged = true
              log(string.format("instance %d: first frog in position at %.1f %.1f %.1f (wanted %.1f %.1f %.1f)", g.inst, u:GetX(), u:GetY(), u:GetZ(), tg.hx, tg.hy, tg.hz))
            end
            tg.nextPoison = t + math.random(DH.FROG_SPIT_MS_MIN, DH.FROG_SPIT_MS_MAX)
            try(u, "SetFacingToObject", c)
            u:CastSpell(c, S.FROG_SPIT, true)                  -- the poison bolt you see flying at the cannon
            tg.hitAt = t + math.floor(u:GetDistance(c) / DH.FROG_SPIT_SPEED * 1000); tg.hitCannon = c:GetGUID()
          end
        elseif tg.kind == "bear" and math.sqrt((tg.hx - u:GetX()) ^ 2 + (tg.hy - u:GetY()) ^ 2) > 1.5 then
          -- bears LEAP in (footage: they jump over the hedge). Walking with gravity off showed a swim animation (Rowan 22:56),
          -- walking with gravity on drops them under the floorless arena, so they move in big jumps like the frogs.
          if t >= tg.nextHop then
            tg.nextHop = t + DH.BEAR_HOP_MS
            local dx, dy = tg.hx - u:GetX(), tg.hy - u:GetY()
            local dist = math.sqrt(dx * dx + dy * dy)
            local k = math.min(DH.BEAR_HOP, dist) / dist
            local last = dist <= DH.BEAR_HOP
            u:MoveJump(u:GetX() + dx * k, u:GetY() + dy * k, last and tg.hz or DH.GRASS_Z, 14, 4)
          end
        elseif tg.kind == "bear" and u:GetDistance(c) < 5.5 then
          tg.arrived = true
          if t >= tg.nextThrow then
            tg.nextThrow = t + DH.BEAR_THROW_MS
            try(u, "SetFacingToObject", c); try(u, "PerformEmote", 35)
            local kit = c:GetVehicleKit()
            local pas = kit and kit:GetPassenger(0)
            if pas and pas:GetTypeId() == 4 then
              local m = g.members[pas:GetGUIDLow()]
              if m and not m.bot then
                unseat(g, pas:GetGUIDLow())
                m.seated = false; m.wantSeat = false            -- climb back in yourself (click the cannon), like any other exit
                pas:ToPlayer():SendAreaTriggerMessage("The bear threw you out of your cannon! Click it to climb back in.")
              elseif m then
                try(c, "AddAura", S.STUN, c); cn.stunUntil = t + DH.THROWN_OUT_MS   -- bots would fall through the floor: stun instead
              end
            end
          end
          if t >= tg.nextMaul then
            tg.nextMaul = t + DH.BEAR_MAUL_MS
            u:DealDamage(c, math.max(1, math.floor(c:GetMaxHealth() * DH.BEAR_MAUL_PCT)), false)
          end
        end
      end
    end
  end
  g.ducksAlive = ducks
end

local function botShot(g, c, cn, t, heat)
  cn.nextShot = t + math.random(DH.BOT_SHOT_MS_MIN, DH.BOT_SHOT_MS_MAX)
  -- priority like the players in the footage: bears > frogs > ducks
  local best, bestScore
  for key, tg in pairs(g.targets) do
    if not tg.dead and tg.kind ~= "bomb" then
      local u = getObj(g, tg.guid)
      if u and u:IsAlive() then
        local d = c:GetDistance(u)
        -- bots only deal with frogs/bears once they reach the platform (live: frogs get there and do damage);
        -- sniping them at the hedge made them vanish before anyone saw them (Rowan 22:33 'no frogs')
        local close = (tg.kind == "duck") or (tg.kind == "frog" and tg.arrived and t >= (tg.arrivedAt or 0) + DH.FROG_BOT_GRACE_MS)
                      or (tg.kind == "bear" and tg.arrived and d < 14)
        if d < 60 and close then
          local s = d - ((tg.kind == "bear") and 100 or (tg.kind == "frog") and 60 or 0)
          if not bestScore or s < bestScore then best, bestScore = u, s end
        end
      end
    end
  end
  if not best then return end
  local ax = best:GetX() + rnd(-DH.BOT_AIM_ERROR, DH.BOT_AIM_ERROR) * 0.5
  local ay = best:GetY() + rnd(-DH.BOT_AIM_ERROR, DH.BOT_AIM_ERROR) * 0.5
  local az = best:GetZ()
  for key, tg in pairs(g.targets) do                 -- hold fire if a bomb is in the blast
    if not tg.dead and tg.kind == "bomb" then
      local u = getObj(g, tg.guid)
      if u then
        local dx, dy, dz = u:GetX() - ax, u:GetY() - ay, u:GetZ() - az
        if dx * dx + dy * dy + dz * dz <= 100 then return end
      end
    end
  end
  try(c, "SetFacingToObject", best)
  c:CastSpellAoF(ax, ay, az, S.SHOT, true)
  local hits = {}
  for key, tg in pairs(g.targets) do
    if not tg.dead then
      local u = getObj(g, tg.guid)
      if u and u:IsAlive() then
        local dx, dy, dz = u:GetX() - ax, u:GetY() - ay, u:GetZ() - az
        if dx * dx + dy * dy + dz * dz <= 64 then hits[#hits + 1] = u end
      end
    end
  end
  for _, u in ipairs(hits) do onShotHit(u, c) end
end

local function tickCannons(g, t)
  for low, cn in pairs(g.cannons) do
    local c = getObj(g, cn.guid)
    if c and c:IsAlive() then
      local heat = c:GetPower(POWER_ENERGY)
      if cn.stunUntil > 0 and t >= cn.stunUntil then
        try(c, "RemoveAura", S.STUN); cn.stunUntil = 0; c:SetPower(math.min(heat, 60), POWER_ENERGY)
      elseif cn.stunUntil == 0 and heat >= 100 then
        try(c, "AddAura", S.STUN, c); cn.stunUntil = t + DH.OVERHEAT_STUN_MS
        local kit = c:GetVehicleKit(); local pas = kit and kit:GetPassenger(0)
        if pas and pas:GetTypeId() == 4 and not pas:ToPlayer():IsBot() then pas:ToPlayer():SendAreaTriggerMessage("OVERHEATED! Let the cannon cool down!") end
      elseif cn.stunUntil == 0 and heat > 0 then
        c:SetPower(math.max(0, heat - DH.HEAT_DRAIN), POWER_ENERGY)
      end
      local kit = c:GetVehicleKit()
      local pas = kit and kit:GetPassenger(0)
      local bot = pas and pas:GetTypeId() == 4 and pas:ToPlayer():IsBot()
      if bot and g.state == "play" and cn.stunUntil == 0 then
        if c:GetHealth() < c:GetMaxHealth() * 0.5 and t >= cn.repairReady then
          c:CastSpell(c, S.REPAIR, true); cn.repairReady = t + 30000
        elseif t >= cn.nextShot and heat < 85 then
          botShot(g, c, cn, t, heat)
        end
      end
    elseif not cn.dead then
      cn.dead = true
      if g.state == "play" then tell(g, DHT .. "A cannon has been destroyed!", true) end
      local ow = getPlayer(g, cn.owner)
      if ow and ow:IsBot() then ow:Teleport(DH.MAP, DH.CENTRE[1], DH.CENTRE[2], DH.CENTRE[3] + 0.5, 0) end
    end
  end
end

-- -------- rounds --------
local function resetCannons(g)
  for low, cn in pairs(g.cannons) do
    local c = getObj(g, cn.guid)
    if c and c:IsAlive() then
      c:SetHealth(c:GetMaxHealth()); c:SetPower(0, POWER_ENERGY); try(c, "RemoveAura", S.STUN)
      cn.stunUntil = 0; cn.repairReady = 0
    else
      if c then c:DespawnOrUnsummon(0) end
      g.cannons[low] = nil
      local m = g.members[cn.owner]
      if m then spawnCannon(g, m.slot, cn.owner) end
    end
  end
end

local function clearSky(g)
  for key, tg in pairs(g.targets) do
    local u = getObj(g, tg.guid)
    if u then u:DespawnOrUnsummon(0) end
  end
  g.targets = {}; g.nTargets = 0; g.ducksAlive = 0
end

local function startCountdown(g, t)
  g.round = g.round + 1
  for low, m in pairs(g.members) do m.earned = 0; m.lost = 0; m.ready = false; m.thrownUntil = nil; m.wantSeat = true end
  g.score = 0; g.ducksKilled = 0; g.spawnedCount = 0
  g.stats = { duck = 0, bomb = 0, frog = 0, bear = 0, byBot = 0, byPlayer = 0 }
  resetCannons(g)
  g.target = (DH.TARGET_BASE + DH.TARGET_STEP * (g.round - 1)) * g.count
  tell(g, DHT .. string.format("Victory condition: keep at least one cannon operational and score at least %d points before time expires.", g.target))
  tell(g, AZT .. "Round " .. g.round .. " is starting!")
  g.state = "countdown"; g.phaseEnd = t + DH.COUNTDOWN * 1000; g.lastCount = nil; g.nextSeat = t; g.lobbyUntil = nil
end

local function startPlay(g, t)
  g.state = "play"
  g.phaseEnd = t + DH.GAME_SECONDS * 1000
  g.goldenAt = t + math.random(DH.GOLDEN_MIN, DH.GOLDEN_MAX) * 1000
  g.frogAt = t + perRound(DH.FROG_FIRST, g.round) * 1000
  g.bearAt = (g.round >= DH.BEAR_FROM_ROUND) and (t + DH.BEAR_FIRST * 1000) or nil
  g.nextStatus = t + DH.STATUS_EVERY * 1000
  g.timer3 = false; g.timer1 = false
  log(string.format("instance %d: round %d started, target %d", g.inst, g.round, g.target))
  tell(g, DHT .. "Go!", true)
  yell(g, g.round == 1 and "Cannons ready? FIRE AT WILL!" or "Round " .. g.round .. "! They're angrier now!")
end

local function endGame(g, reason)
  if g.state ~= "play" then return end
  g.state = "lobby"
  local cannonsLeft = #aliveCannons(g)
  local win = (cannonsLeft > 0) and (g.score >= g.target)
  clearSky(g)
  tell(g, DHT .. "Game Over.", true)
  -- ranked lines, lowest first so #1 ends up at the bottom of the chat (as on live)
  local list = {}
  for low, m in pairs(g.members) do list[#list + 1] = m end
  table.sort(list, function(a, b) return (a.earned - a.lost) > (b.earned - b.lost) end)
  for i = #list, 1, -1 do
    local m = list[i]
    tell(g, DHT .. string.format("#%d %s - |cff00ff00Earned:|r %d pts | |cffff2020Lost:|r %d pts | |cff00ccffFinal:|r %d",
      i, m.name, m.earned, m.lost, m.earned - m.lost))
  end
  tell(g, win and (DHT .. "|cff00ff00VICTORY!|r Team score " .. g.score .. " / " .. g.target .. ".")
             or (DHT .. "|cffff4040Defeat.|r Team score " .. g.score .. " / " .. g.target .. "."))
  tell(g, AZT .. "Round " .. g.round .. " is complete. Round " .. (g.round + 1) .. " is now available!")
  yell(g, win and "Now THAT'S justice! Feathers everywhere!" or "Pathetic! The ducks are laughing at you!")
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inArena(g, pl) then
      if not pl:IsBot() then unseat(g, low) end
      if pl:HasQuest(Q_BASE) or pl:HasQuest(Q_DAILY) then pl:KilledMonsterCredit(E.CREDIT) end
    end
  end
  local st = g.stats
  log(string.format("round %d over in instance %d (%s): %s, score %d/%d, cannons %d, ducks %d, bombs %d, frogs %d, bears %d, kills players %d / bots %d, frogs landed %d",
    g.round, g.inst, reason, win and "WIN" or "LOSS", g.score, g.target, cannonsLeft, st.duck, st.bomb, st.frog, st.bear, st.byPlayer, st.byBot, st.frogLanded or 0))
  g.lobbyUntil = now() + DH.LOBBY_SECONDS * 1000
  tell(g, DHT .. "Talk to Takk within " .. DH.LOBBY_SECONDS .. " seconds to play Round " .. (g.round + 1) .. ", or you'll be sent back to the Faire.")
  say(g, "Talk to me when you're ready for the next round. Or go home and cry, your call.")
end

local function finalCleanup(g, why)
  clearSky(g)
  for _, guid in ipairs(g.fixed) do local o = getObj(g, guid); if o then o:DespawnOrUnsummon(0) end end
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inArena(g, pl) then local t = DH.TAKK_SPOT; pl:Teleport(t[1], t[2], t[3], t[4], t[5]) end
  end
  Games[g.inst] = nil
  log("instance " .. tostring(g.inst) .. " cleaned up (" .. why .. ")")
end

-- leaving the arena: first take everyone out of the cannons, THEN teleport 1.5 s later. Teleporting players while they sit in
-- a vehicle left the client's party frames stuck on the vehicle (blank portraits until /reload, Rowan 22:39).
local function cleanup(g, why)
  if g.leavingAt then return end
  g.leavingAt = now() + 1500; g.leaveWhy = why; g.state = "leaving"
  for low, cn in pairs(g.cannons) do
    local c = getObj(g, cn.guid)
    local kit = c and c:GetVehicleKit()
    local pas = kit and kit:GetPassenger(0)
    if pas then
      local m = g.members[pas:GetGUIDLow()]
      if m and not m.bot then unseat(g, pas:GetGUIDLow()) else try(kit, "RemovePassenger", pas) end
    end
  end
end

local function humansLeft(g)
  for low, m in pairs(g.members) do
    if not m.bot and inArena(g, getPlayer(g, low)) then return true end
  end
  return false
end

local function tickGame(g, t)
  g.map = select(1, getMap(g))
  if g.leavingAt then
    if t >= g.leavingAt or not g.map then finalCleanup(g, g.leaveWhy) end
    return
  end
  if not g.map then
    log("nobody left in instance " .. tostring(g.inst) .. ", session dropped"); Games[g.inst] = nil; return
  end
  if not humansLeft(g) and t > (g.created + 60000) then cleanup(g, "no players left"); return end
  if t >= (g.nextSeat or 0) then
    g.nextSeat = t + 1000
    for low, _ in pairs(g.members) do seat(g, low) end
  end
  tickCannons(g, t)
  tickTargets(g, t)
  if g.state == "lobby" then
    -- everyone ready? (bots always are)
    local all, any = true, false
    for low, m in pairs(g.members) do
      if not m.bot and inArena(g, getPlayer(g, low)) then any = true; if not m.ready then all = false end end
    end
    if any and all then startCountdown(g, t)
    elseif g.lobbyUntil and t >= g.lobbyUntil then cleanup(g, "nobody readied up after the game") return end
  elseif g.state == "countdown" then
    local left = math.ceil((g.phaseEnd - t) / 1000)
    if left ~= g.lastCount and left > 0 then g.lastCount = left; tell(g, tostring(left), true) end
    if t >= g.phaseEnd then startPlay(g, t) end
  elseif g.state == "play" then
    local cap, per = perRound(DH.SWARM_CAP, g.round), perRound(DH.SWARM_SPAWN, g.round)
    if g.ducksAlive < cap then spawnDucks(g, math.min(per, cap - g.ducksAlive)) end
    if g.goldenAt and t >= g.goldenAt then g.goldenAt = t + math.random(DH.GOLDEN_MIN, DH.GOLDEN_MAX) * 1000; spawnGolden(g) end
    if t >= g.frogAt then g.frogAt = t + math.random(DH.FROG_EVERY_MIN, DH.FROG_EVERY_MAX) * 1000; spawnFrogs(g) end
    if g.bearAt and t >= g.bearAt then g.bearAt = t + math.random(DH.BEAR_EVERY_MIN, DH.BEAR_EVERY_MAX) * 1000; spawnBears(g) end
    local left = (g.phaseEnd - t) / 1000
    if not g.timer3 and left <= 180 then g.timer3 = true; tell(g, "|cffff8000[TIMER]|r 3 minutes remaining!") end
    if not g.timer1 and left <= 60 then g.timer1 = true; tell(g, "|cffff8000[TIMER]|r 1 minute remaining!") end
    if t >= g.nextStatus then
      g.nextStatus = t + DH.STATUS_EVERY * 1000
      tell(g, string.format("End of Game: %s   Ducks Killed: %d   Team: %d / %d", mmss(left), g.ducksKilled, g.score, g.target), true)
    end
    if #aliveCannons(g) == 0 then tell(g, DHT .. "All the cannons are destroyed!", true); endGame(g, "cannons")
    elseif t >= g.phaseEnd then endGame(g, "time") end
  end
end

local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)       -- nil while the starter is on the loading screen: wait
    if t > g.created + 90000 then
      Pending[sLow] = nil; log("start cancelled (starter did not arrive within 90 s)")
    elseif st and st:GetMapId() == DH.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then
        st:SendBroadcastMessage(DHT .. "A game is already running in this arena.")
      else
        Games[g.inst] = g
        g.map = st:GetMap()
        buildArena(g)
        g.state = "lobby"; g.nextSeat = t
        tell(g, DHT .. "Talk to Takk on the platform when you're ready to start.")
        yell(g, "Welcome, welcome! Grab a cannon... after you tell me you're ready. No duck is innocent!")
      end
    end
  end
end

CreateLuaEvent(function()
  local t = now()
  local ok, err = pcall(tickPending, t)
  if not ok then log("error (pending): " .. tostring(err)) end
  for inst, g in pairs(Games) do
    local ok2, err2 = pcall(tickGame, g, t)
    if not ok2 then log("error (game " .. tostring(inst) .. "): " .. tostring(err2)) end
  end
end, 500, 0)

-- -------- Takk at the Faire: start a session --------
local function startSession(player, takk)
  local members, count = {}, 0
  local function add(p)
    if count >= DH.MAX_PLAYERS then return end
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), bot = p:IsBot(), name = p:GetName(), slot = count, earned = 0, lost = 0, ready = false }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= DH.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  local g = { members = members, count = count, starter = player:GetGUIDLow(), created = now(), state = "arriving",
              cannons = {}, targets = {}, nTargets = 0, ducksAlive = 0, fixed = {}, bushes = {}, score = 0, round = 0,
              ducksKilled = 0, spawnedCount = 0, stats = {}, target = DH.TARGET_BASE * count }
  Pending[player:GetGUIDLow()] = g
  for low, m in pairs(members) do
    local ang = cannonAng(m.slot)
    local px, py = DH.CENTRE[1] + (DH.CANNON_R - 2.5) * math.cos(ang), DH.CENTRE[2] + (DH.CANNON_R - 2.5) * math.sin(ang)
    local p = GetPlayerByGUID(m.guid)
    if p then p:Teleport(DH.MAP, px, py, DH.CENTRE[3] + 0.3, ang) end
  end
  log(string.format("%s starts Duck Hunt with %d player(s)", player:GetName(), count))
  takk:SendUnitSay("To the cannons! And remember: no duck is innocent.", 0)
end

local function faireMenu(player, creature)
  player:GossipClearMenu()
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Let's blast some ducks! (start Duck Hunt with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about The Duck Hunt?", 0, 2)
  player:GossipMenuAddItem(1, "I'd like to browse your goods.", 0, 3)
  player:GossipSendMenu(TEXT_GREET, creature)
end

RegisterCreatureGossipEvent(E.TAKK, 1, function(event, player, creature) faireMenu(player, creature) end)
RegisterCreatureGossipEvent(E.TAKK, 2, function(event, player, creature, sender, intid)
  if intid == 1 then
    player:GossipComplete()
    for _, g in pairs(Games) do
      if g.members[player:GetGUIDLow()] then player:SendBroadcastMessage(DHT .. "You are already in a game."); return end
    end
    startSession(player, creature)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_RULES, creature)
  elseif intid == 3 then
    player:GossipComplete(); player:SendListInventory(creature)
  else
    faireMenu(player, creature)
  end
end)

-- -------- Takk on the platform: ready check + way home --------
local function arenaMenu(player, creature)
  local g = gameOf(creature)
  player:GossipClearMenu()
  if g and g.state == "lobby" and g.members[player:GetGUIDLow()] then
    local m = g.members[player:GetGUIDLow()]
    if not m.ready then player:GossipMenuAddItem(9, "I'm ready!", 0, 10) end
    player:GossipMenuAddItem(0, "Can you tell me more about The Duck Hunt?", 0, 11)
    player:GossipMenuAddItem(2, "Take me back to the Azzar Faire.", 0, 12)
  else
    player:GossipMenuAddItem(2, "Take me back to the Azzar Faire.", 0, 12)
  end
  player:GossipSendMenu(TEXT_GREET, creature)
end

RegisterCreatureGossipEvent(E.TAKK_ARENA, 1, function(event, player, creature) arenaMenu(player, creature) end)
RegisterCreatureGossipEvent(E.TAKK_ARENA, 2, function(event, player, creature, sender, intid)
  local g = gameOf(creature)
  local m = g and g.members[player:GetGUIDLow()]
  if intid == 10 and m and g.state == "lobby" then
    player:GossipComplete()
    m.ready = true
    local n, of = 0, 0
    for low, mm in pairs(g.members) do if not mm.bot then of = of + 1; if mm.ready then n = n + 1 end end end
    if n < of then tell(g, DHT .. m.name .. " is ready (" .. n .. "/" .. of .. "). Every player must be ready before the round can start.") end
  elseif intid == 11 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 13); player:GossipSendMenu(TEXT_RULES, creature)
  elseif intid == 12 then
    player:GossipComplete()
    if g and m then
      if g.state == "play" or g.state == "countdown" then
        tell(g, DHT .. m.name .. " left the game.")
      end
      g.members[player:GetGUIDLow()] = nil; g.count = math.max(0, g.count - 1)
    end
    local t = DH.TAKK_SPOT
    player:Teleport(t[1], t[2], t[3], t[4], t[5])
  else
    arenaMenu(player, creature)
  end
end)

-- -------- player aim (Rowan 23:30: 'the crosshair only goes to the tent wall or the ground') --------
-- The shot is a lobbed (trajectory) spell: the client can only put the crosshair where the arc meets the world (ground / wall),
-- never on a duck in the air, and the core only scores what the arc happens to pass through. So when a PLAYER fires, the script
-- takes the straight line from the cannon to the crosshair point and hits the first thing on that line (within AIM_LINE_R),
-- with the usual 8 yd blast around it. Aim at the wall just behind a duck and the duck is hit. Bots are not touched.
local aimLogged = 0
local function onPlayerShot(caster, spell)
  if not caster or not spell then return end
  local c = caster
  if c:GetTypeId() == 4 then                                  -- some cores make the player the caster: use their cannon
    local g0 = Games[c:GetInstanceId()]
    local m0 = g0 and g0.members[c:GetGUIDLow()]
    local cn0 = m0 and m0.cannonLow and g0.cannons[m0.cannonLow]
    c = cn0 and getObj(g0, cn0.guid)
    if not c then return end
  elseif c:GetEntry() ~= E.CANNON then return end
  local g = gameOf(c)
  if not g or g.state ~= "play" then return end
  g.map = c:GetMap()            -- the map handle saved by the game tick is no longer valid inside a spell event (log 23:44)
  local kit = c:GetVehicleKit()
  local pas = kit and kit:GetPassenger(0)
  if not pas or pas:GetTypeId() ~= 4 then return end
  local m = g.members[pas:GetGUIDLow()]
  if not m or m.bot then return end
  local ok, dx, dy, dz = pcall(spell.GetTargetDest, spell)
  if not ok or not dx or not dy or not dz then
    if aimLogged < 1 then aimLogged = 1; log("aim: GetTargetDest gave nothing (" .. tostring(dx) .. ")") end
    return
  end
  local sx, sy, sz = c:GetX(), c:GetY(), c:GetZ() + 2.0      -- muzzle
  local vx, vy, vz = dx - sx, dy - sy, dz - sz
  local len2 = vx * vx + vy * vy + vz * vz
  if len2 < 1 then return end
  local best, bestT, bestKind
  for key, tg in pairs(g.targets) do
    if not tg.dead then
      local u = getObj(g, tg.guid)
      if u and u:IsAlive() then
        local ux, uy, uz = u:GetX() - sx, u:GetY() - sy, u:GetZ() + 0.5 - sz
        local tt = (ux * vx + uy * vy + uz * vz) / len2
        if tt > 0 and tt <= 1.1 then
          local px, py, pz = ux - vx * tt, uy - vy * tt, uz - vz * tt
          if px * px + py * py + pz * pz <= DH.AIM_LINE_R * DH.AIM_LINE_R and (not bestT or tt < bestT) then
            best, bestT, bestKind = u, tt, tg.kind
          end
        end
      end
    end
  end
  if aimLogged < 4 then
    aimLogged = aimLogged + 1
    log(string.format("aim: %s shot at %.1f %.1f %.1f -> %s", m.name, dx, dy, dz, best and (bestKind .. string.format(" %.0f yd out", math.sqrt(len2) * bestT)) or "nothing on the line"))
  end
  if not best then return end
  local hx, hy, hz = best:GetX(), best:GetY(), best:GetZ()
  local hits = {}
  for key, tg in pairs(g.targets) do
    if not tg.dead then
      local u = getObj(g, tg.guid)
      if u and u:IsAlive() then
        local ex, ey, ez = u:GetX() - hx, u:GetY() - hy, u:GetZ() - hz
        if ex * ex + ey * ey + ez * ez <= 64 then hits[#hits + 1] = u end
      end
    end
  end
  for _, u in ipairs(hits) do onShotHit(u, c) end
end
for _, sid in ipairs({ S.SHOT, S.SHOT2 }) do
  local ok, err = pcall(RegisterSpellEvent, sid, 2, function(event, a, b)
    local function has(o, k) local ok, f = pcall(function() return o[k] end); return ok and type(f) == "function" end
    local caster, spell = a, b
    if not (spell and has(spell, "GetTargetDest")) and a and has(a, "GetTargetDest") then
      spell = a; caster = has(a, "GetCaster") and a:GetCaster() or nil
    end
    local ok, err = pcall(onPlayerShot, caster, spell)
    if not ok and aimLogged < 6 then aimLogged = aimLogged + 1; log("aim error: " .. tostring(err)) end
  end)   -- SPELL_EVENT_ON_CAST
  if not ok then log("aim: RegisterSpellEvent failed: " .. tostring(err)) end
end

-- safety hatch: say "#leave" in the arena (not announced; live has no exit mid-game)
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#cannon" and player:GetMapId() == DH.MAP then             -- get back into your cannon after climbing out
    local g = Games[player:GetInstanceId()]
    local m = g and g.members[player:GetGUIDLow()]
    if m then m.wantSeat = true; m.thrownUntil = nil; seat(g, player:GetGUIDLow()) end
    return false
  end
  if msg ~= "#leave" or player:GetMapId() ~= DH.MAP then return end
  for inst, g in pairs(Games) do
    if g.members[player:GetGUIDLow()] then g.members[player:GetGUIDLow()] = nil; g.count = math.max(0, g.count - 1) end
  end
  local t = DH.TAKK_SPOT
  player:SendBroadcastMessage(DHT .. "Back to the Faire you go!")
  player:Teleport(t[1], t[2], t[3], t[4], t[5])
  return false
end)

log("script loaded v2.5 frog-ring+aim-fix+duck-mix+more-frogs (Takk " .. E.TAKK .. ", map " .. DH.MAP .. ")")
