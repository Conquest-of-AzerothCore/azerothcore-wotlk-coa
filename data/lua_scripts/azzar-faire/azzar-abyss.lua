-- azzar-abyss.lua  v0.1  (Rowan/Claude 2026-11-19: FIRST BUILD, written overnight from the live video, NOT TESTED IN GAME YET)
-- A.B.Y.S.S. mini-game for the Azzar Faire (map 968 'AzzarEvent'), host Mizzle 371920 on Dawnrise (map 909).
-- Source: drop-in\The Abyss_Azzar_Faire.mp4 (two live matches against the entity 'Celestial Serpent'); scan notes
--   faire-cache\abyss-live-2026-11-19\ABYSS-SCAN-2026-11-19.md. Needs azzar-abyss.sql (Azzar-Abyss-Apply.bat) and a restart.
-- LIVE RULES (Mizzle's text 1200144 + the video): survive. Three lives; falling into the abyss costs one and puts you back on a platform; out of
--   lives = you watch from the temple. The match is 6:00 ('End of Game'); whoever still has a life then wins ('Survivors win: ...', 500 tickets).
-- WHAT THIS BUILD DOES
--   Lobby on the troll-temple floor ('Waiting for more players to join...', 'Game will start in N seconds with the current players.'), then the big
--   10..1 countdown with the entity's name. The field = 11 x 8 platform tiles (visible creature + the live collision object under it) round the
--   temple model's origin, in one of four tile looks and one of four hole patterns per match. You play as the ethereal (spell 255586 'Vortex':
--   transform + the live bar with Escapist's Jump and the sprint).
--   The Celestial Serpent's cycle, with the live lines and the live timing (every 150 s):
--     +10 s Meteor Cross: one row + one column of tiles get marked, 4 s later they are hit.
--     +16 s Starfall volley: scattered marks, stars fall on them one after the other.
--     +22 s Celestial orbs (28 s): an orb hangs over a tile (mostly yours), comes down after 3.5 s and bursts.
--       A hit CRACKS a tile; a cracked tile that is hit again, or any tile hit while somebody stands on it, FALLS. Fallen tiles come back after 25 s.
--     +58 s Pursuit: the field falls away row by row from the temple side, a path of tiles grows out of the far edge and the serpent takes it down
--       behind you, faster and faster. The field is rebuilt meanwhile.
--     +130 s Exit portals at the head of the path: step in to return to the field; +150 s the rest of the path goes and the cycle starts again.
-- GUESSES / OURS (to check against live with Rowan): the mark look (257495), the orb look (257509), what a hit does to a player (live may knock
--   you away; ours only breaks the tile), the shape of the pursuit path (live: a long strip far from the field; ours starts at the far edge), field
--   size and patterns, the wording of the lines that are not in the video ('... is out of the game', 'You fell ...').
-- NOT BUILT YET: the other five entities (Void, Gizmo, Air Elemental, Bwonsamdi, Arcane Encounter), Zik + the two quests (credits are given if you
--   have them), script-run contestants / bots, the changing sky.
-- Commands (chat):  #leave = back to the Faire.   GM only:  #ab start | #ab go (skip the wait) | #ab time <seconds left> |
--   #ab phase <meteor|starfall|orbs|pursuit|portals|next> | #ab lives <n> | #ab fx <spell id> | #ab set <SETTING> <value>
local AB = {
  MAP = 968,
  CENTER = { 766.4, 800.0, 101.0 },      -- the middle of the field = the temple model's origin (abyss_trolltemple.wmo at 766.4 800.0 101.0); tile tops at z 101
  LOBBY = { 681.4, 800.0, 111.6, 0 },    -- on the temple floor (model x -85, y 0, floor z 10 = world 111.0), facing the field
  LOBBY_SPREAD = 7,
  PORTAL_AT = { 676.4, 830.0, 111.3 },   -- the Azzar Faire Portal orb on the temple floor (model x -90, y 30)
  FAIRE_SPOT = { 909, -1721.5, -12131.0, 63.0, 4.6 },       -- fallback way home (by Mizzle) for players with no saved spot
  MAX_PLAYERS = 40, JOIN_RANGE = 40,
  LOBBY_WAIT = 20,           -- seconds on the temple before the countdown ('Game will start in N seconds with the current players.'); GM '#ab go' skips it
  COUNTDOWN = 10,            -- live: big numbers 10..1 with the entity's name
  SETDOWN_AT = 7,            -- players are set down on their tiles at this number (the field itself appears with the 10)
  GAME_TIME = 360,           -- live HUD: 'End of Game: 5:58' two seconds in
  LIVES = 3,
  COLS = 11, ROWS = 8, PITCH = 14.2,     -- columns run along y (left-right seen from the temple), rows along x (away from the temple)
  STYLE = 0, PATTERN = 0,    -- 0 = random per match; STYLE 1 arcane (video 1), 2 / 3, 4 wood (video 2); PATTERN 1 = no holes
  TILE_HALF = 7.3,           -- you count as standing on a tile inside this half-width
  FALL_Z = 22,               -- this far below the tiles = you fell
  TILE_BACK_MS = 25000,      -- a fallen tile comes back ('After a while, they'll reappear')
  FALL_MS = 2000,            -- the tile's own falling animation (214)
  GO_SECS = 900,             -- lifetime of a collision object (a safety net: they go with their tile anyway)
  HIT_DROPS_OCCUPIED = true, -- a hit on a tile with somebody on it drops it at once
  MARK_MS = 4000, MARK_SCALE = 0.75,
  STARS = 8, STARS_PER_CYCLE = 3, STAR_GAP = 350,
  ORBS_MS = 28000, ORB_EVERY = 3000, ORB_EVERY_MIN = 1600, ORB_CHARGE = 3500, ORB_Z = 9, ORB_SCALE = 1.5,
  CYCLE = 150,               -- seconds; phase offsets below are live (game clock of the video)
  AT_METEOR = 10, AT_STARFALL = 16, AT_ORBS = 22, AT_PURSUIT = 58, AT_PORTALS = 130,
  SWEEP_STEP = 1500,         -- pursuit: the field falls row by row at this pace (each row cracks one step before it falls)
  PATH_AHEAD = 6, PATH_MAX = 60, PATH_TURN = 0.6, PATH_WAVE = 0.3, PATH_RISE = 0.25, PATH_RISE_MAX = 8,
  CHASE_STEP = 2200, CHASE_MIN = 1500, CHASE_FASTER = 25,   -- ms per path tile at the start / at the fastest / quicker by this much each tile
  REBUILD_AT = 30,           -- seconds into the pursuit: the field is whole again (live: +88 s on the game clock)
  PORTAL_R = 5,
  SERPENT_R = 55, SERPENT_Z = 30, SERPENT_SPEED = 9,
  TRANSFORM = true,          -- spell 255586 'Vortex' on the players (ethereal + the live bar); false = play as yourself
  SILENCE = true,            -- spell 255876 'Vortex: PreGame' during the countdown
  BIG_COUNTDOWN = true,
  END_WAIT = 12000,
  TICKETS = 500,             -- winners (live chat: '500 tickets and 4000 runes')
  TICKETS_OUT = 50,          -- out of lives (live chat: 'You receive item: [Azzar Faire Ticket]x50' + 400 runes; WHEN live gives it is a guess: ours when you go out)
  ACHIEVEMENTS = true,
}
local E = { MIZZLE = 371920, PORTAL = 9997810, SERPENT = 99764, MARK = 99775, ORB = 99778, CREDIT1 = 379164, CREDIT2 = 372022 }
local STYLES = { { tile = 99496, col = 2300104 }, { tile = 99500, col = 2300105 }, { tile = 99501, col = 2300106 }, { tile = 99502, col = 2300107 } }
local S = { VORTEX = 255586, PREGAME = 255876, CRACK = 255878, FALL = 255877, HEART = 255879, MARK = 257495, STAR = 257508, ORB = 257509,
            PORTALVIS = 257522 }
local WS = { REM_ON = 50089, REM = 50088, TIME_ON = 50090, MIN = 50091, TEN = 50092, ONE = 50093 }   -- WorldStateUI 377 / 608 (map 968)
local ACH = { WIN = 90248, UNTOUCHED = 90282 }
local Q1, Q2 = 1650226, 1650265
local TEXT_GREET, TEXT_RULES, TEXT_PORTAL = 9997143, 1200144, 1200245
local ITEM_TICKET = 558530
local OP_COUNTDOWN = 0x588
local TEMPSUMMON_TIMED_DESPAWN = 3
local LIFE = 20 * 60000
local ENTITY = "Celestial Serpent"

local Games, Pending = {}, {}
local AT = "|cffb070ff[A.B.Y.S.S.]|r "
local function log(msg) print("[Abyss] " .. msg) end
local missingLogged = {}
local function try(o, method, ...)
  if not o then return nil end
  local f = o[method]
  if type(f) ~= "function" then
    if not missingLogged[method] then missingLogged[method] = true; log("note: this ALE has no " .. method .. "(), skipped") end
    return nil
  end
  local ok, r = pcall(f, o, ...)
  if not ok then log(method .. " failed: " .. tostring(r)) end
  return r
end
local function now() return GetCurrTime() end
local function mmss(sec) sec = math.max(0, math.floor(sec)); return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end
local function dist2(ax, ay, bx, by) local dx, dy = ax - bx, ay - by; return math.sqrt(dx * dx + dy * dy) end
local function later(guid, ms, fn)
  CreateLuaEvent(function()
    local p = GetPlayerByGUID(guid)
    if p and p:IsInWorld() then local ok, err = pcall(fn, p); if not ok then log("later() error: " .. tostring(err)) end end
  end, ms, 1)
end
local function getPlayer(g, low)
  local m = g.members[low]
  if not m then return nil end
  local pl = GetPlayerByGUID(m.guid)
  if pl and pl:IsInWorld() then return pl end
  return nil
end
local function inGame(g, pl) return pl and pl:GetMapId() == AB.MAP and pl:GetInstanceId() == g.inst end
-- never keep a Map handle between ticks (ALE invalidates it when the hook that made it ends): fetch it fresh from a member
local function mapOf(g)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then return pl:GetMap() end
  end
  return nil
end
local function anchor(g)
  for low, _ in pairs(g.members) do local pl = getPlayer(g, low); if inGame(g, pl) then return pl end end
  return nil
end
local function tell(g, msg, center)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl then
      pl:SendBroadcastMessage(msg)
      if center then pl:SendAreaTriggerMessage(center == true and msg or center) end
    end
  end
end
local function obj(g, guid) local mp = mapOf(g); return guid and mp and mp:GetWorldObject(guid) end
local function giveAch(pl, id) if pl and AB.ACHIEVEMENTS and try(pl, "HasAchieved", id) ~= true then try(pl, "SetAchievement", id) end end
local function clearAuras(pl) if pl then try(pl, "RemoveAura", S.VORTEX); try(pl, "RemoveAura", S.PREGAME) end end
local function active(m) return m and not m.out end

-- ---------- HUD (world states, as the other mini-games) ----------
local function ws(pl, field, value) try(pl, "SendUpdateWorldState", field, value) end
local function remaining(g) local n = 0; for _, m in pairs(g.members) do if active(m) then n = n + 1 end end; return n end
local function hudShow(g, secLeft)
  local left = math.max(0, math.ceil(secLeft))
  local key = left .. ":" .. remaining(g)
  if key == g.hudKey then return end
  g.hudKey = key
  local s = left % 60
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      ws(pl, WS.REM_ON, 1); ws(pl, WS.REM, remaining(g))
      ws(pl, WS.TIME_ON, 1); ws(pl, WS.MIN, math.floor(left / 60)); ws(pl, WS.TEN, math.floor(s / 10)); ws(pl, WS.ONE, s % 10)
    end
  end
end
local function hudOff(pl) if pl then ws(pl, WS.REM_ON, 0); ws(pl, WS.TIME_ON, 0) end end

-- ---------- the tiles ----------
local function tilePos(r, c)
  return AB.CENTER[1] + (r - (AB.ROWS + 1) / 2) * AB.PITCH, AB.CENTER[2] + (c - (AB.COLS + 1) / 2) * AB.PITCH
end
local PATTERNS = {
  function(r, c) return true end,
  function(r, c) return not ((r == 3 or r == AB.ROWS - 2) and c >= 3 and c <= AB.COLS - 2 and c ~= math.floor((AB.COLS + 1) / 2)) end,   -- two moats with a bridge
  function(r, c) return not (c % 4 == 0 and r > 1 and r < AB.ROWS) end,                                                                 -- lanes
  function(r, c) return (r + 2 * c) % 5 ~= 0 or r == AB.ROWS end,                                                                       -- scattered holes (the far row stays whole: the pursuit path starts there)
}
local function despawnAny(o)
  if not o then return end
  if o.DespawnOrUnsummon then pcall(o.DespawnOrUnsummon, o, 0)
  elseif not pcall(function() o:Despawn() end) then try(o, "RemoveFromWorld", false) end
end
local function unmark(g, t) local m = obj(g, t.markGuid); if m then m:DespawnOrUnsummon(0) end; t.markGuid = nil end
local function spawnTile(g, t)
  local a = anchor(g)
  if not a then return false end
  local c = a:SpawnCreature(g.style.tile, t.x, t.y, t.z, 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if not c then
    if not g.noTile then g.noTile = true; log("could not spawn a platform (creature " .. g.style.tile .. " missing? run Azzar-Abyss-Apply.bat and restart)") end
    return false
  end
  t.cGuid = c:GetGUID(); t.state = "up"; t.respawnAt = nil
  local go = try(c, "SummonGameObject", g.style.col, t.x, t.y, t.z, 0, AB.GO_SECS)   -- the tile owns its collision object: it goes when the tile goes
  t.goGuid = go and go:GetGUID() or nil
  if not go and not g.noCol then g.noCol = true; log("could not summon the collision object " .. g.style.col .. " (template missing?): nobody can stand on the platforms") end
  return true
end
local function dropTile(g, t, backMs)                       -- backMs nil = it stays away until the field is rebuilt
  if t.state == "down" then return end
  t.state = "down"; t.respawnAt = backMs and (now() + backMs) or nil
  unmark(g, t)
  despawnAny(obj(g, t.goGuid)); t.goGuid = nil
  local c = obj(g, t.cGuid)
  if c then try(c, "CastSpell", c, S.FALL, true); c:DespawnOrUnsummon(AB.FALL_MS) end
  t.cGuid = nil
end
local function crackTile(g, t)
  if t.state ~= "up" then return end
  t.state = "cracked"
  local c = obj(g, t.cGuid); if c then try(c, "AddAura", S.CRACK, c) end
end
local function onTile(t, x, y, z) return math.abs(x - t.x) <= AB.TILE_HALF and math.abs(y - t.y) <= AB.TILE_HALF and z > t.z - 3 and z < t.z + 10 end
local function eachActive(g, fn)                            -- fn(low, m, pl) for every player still in the match and on the map
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if active(m) and inGame(g, pl) then fn(low, m, pl) end
  end
end
local function occupied(g, t)
  local n = 0
  eachActive(g, function(low, m, pl) if onTile(t, pl:GetX(), pl:GetY(), pl:GetZ()) then n = n + 1 end end)
  return n > 0
end
local function hitTile(g, t)                                -- a meteor, a star or an orb lands on it
  if t.state == "down" then return end
  unmark(g, t)
  if t.state == "cracked" or (AB.HIT_DROPS_OCCUPIED and occupied(g, t)) then dropTile(g, t, t.path and nil or AB.TILE_BACK_MS)
  else crackTile(g, t) end
end
local function mark(g, t, ms)
  if t.state == "down" or t.markGuid then return end
  local a = anchor(g)
  local m = a and a:SpawnCreature(E.MARK, t.x, t.y, t.z + 0.4, 0, TEMPSUMMON_TIMED_DESPAWN, ms + 1500)
  if m then try(m, "SetScale", AB.MARK_SCALE); try(m, "AddAura", S.MARK, m); t.markGuid = m:GetGUID() end
end
local function buildField(g)
  g.tiles = {}
  for r = 1, AB.ROWS do
    for c = 1, AB.COLS do
      if g.pattern(r, c) then
        local x, y = tilePos(r, c)
        local t = { r = r, c = c, x = x, y = y, z = AB.CENTER[3], state = "down" }
        g.tiles[#g.tiles + 1] = t
        spawnTile(g, t)
      end
    end
  end
end
local function rebuildField(g)                              -- everything of the field that is down or cracked comes back whole
  for _, t in ipairs(g.tiles) do
    if t.state == "cracked" then local c = obj(g, t.cGuid); if c then try(c, "RemoveAura", S.CRACK) end; t.state = "up"
    elseif t.state == "down" then spawnTile(g, t) end
  end
end
local function tileUnder(g, x, y, z)
  for _, t in ipairs(g.tiles) do if t.state ~= "down" and onTile(t, x, y, z) then return t end end
  if g.pursuit then for _, t in pairs(g.pursuit.tiles) do if t.state ~= "down" and onTile(t, x, y, z) then return t end end end
  return nil
end
local function randomTile(g, wantSafe)                      -- a standing field tile; wantSafe = whole and not marked
  local pool = {}
  for _, t in ipairs(g.tiles) do
    if t.state == "up" and not t.markGuid then pool[#pool + 1] = t
    elseif not wantSafe and t.state == "cracked" then pool[#pool + 1] = t end
  end
  if #pool == 0 then for _, t in ipairs(g.tiles) do if t.state ~= "down" then pool[#pool + 1] = t end end end
  if #pool == 0 then return nil end
  return pool[math.random(#pool)]
end
local function playerTile(g)                                -- the tile under a random player (nil if nobody stands on one)
  local list = {}
  eachActive(g, function(low, m, pl) local t = tileUnder(g, pl:GetX(), pl:GetY(), pl:GetZ()); if t and not t.path then list[#list + 1] = t end end)
  if #list == 0 then return nil end
  return list[math.random(#list)]
end

-- ---------- the serpent ----------
local function serpentTo(g, x, y, z)
  local s = obj(g, g.serpentGuid)
  if s then try(s, "MoveTo", 0, x, y, z) end
end
local function tickSerpent(g, t)
  if t < (g.nextSerpent or 0) then return end
  g.nextSerpent = t + 2000
  local p = g.pursuit
  if p and p.chaseAt and t >= p.chaseAt and p.tiles[p.dropped + 1] then
    local tl = p.tiles[p.dropped + 1]; serpentTo(g, tl.x, tl.y, tl.z + 10)
  else
    g.serpentAng = (g.serpentAng or 0) + 2 * AB.SERPENT_SPEED / AB.SERPENT_R
    serpentTo(g, AB.CENTER[1] + math.cos(g.serpentAng) * AB.SERPENT_R, AB.CENTER[2] + math.sin(g.serpentAng) * AB.SERPENT_R, AB.CENTER[3] + AB.SERPENT_Z)
  end
end
local function starAt(g, t)                                 -- the falling star / meteor look on a marked tile (missile from the serpent onto the mark)
  local s, m = obj(g, g.serpentGuid), obj(g, t.markGuid)
  if s and m then try(s, "CastSpell", m, S.STAR, true) end
end

-- ---------- the serpent's attacks ----------
local function strikeLater(g, t, tile, ms)
  mark(g, tile, ms)
  g.strikes[#g.strikes + 1] = { tile = tile, at = t + ms }
end
local function meteorCross(g, t)
  tell(g, "Meteor Cross is forming. Move out of the marked platforms!", true)
  local mid = (math.random(10) <= 7 and playerTile(g)) or randomTile(g, false)
  if not mid then return end
  for _, tl in ipairs(g.tiles) do
    if tl.state ~= "down" and (tl.r == mid.r or tl.c == mid.c) then strikeLater(g, t, tl, AB.MARK_MS) end
  end
end
local function starfall(g, t)
  tell(g, "Starfall volley incoming. Watch the new marks!", true)
  local n = AB.STARS + AB.STARS_PER_CYCLE * (g.cycle - 1)
  for i = 1, n do
    local tl = (math.random(2) == 1 and playerTile(g)) or randomTile(g, false)
    if tl and not tl.markGuid then strikeLater(g, t, tl, 3000 + i * AB.STAR_GAP) end
  end
end
local function tickStrikes(g, t)
  for i = #g.strikes, 1, -1 do
    local s = g.strikes[i]
    if not s.shot and t >= s.at - 700 then s.shot = true; starAt(g, s.tile) end
    if t >= s.at then hitTile(g, s.tile); table.remove(g.strikes, i) end
  end
end
local function tickOrbs(g, t)
  if g.orbsUntil and t < g.orbsUntil and t >= (g.nextOrb or 0) then
    local left = math.max(0, (g.endAt - t) / (AB.GAME_TIME * 1000))
    g.nextOrb = t + AB.ORB_EVERY_MIN + (AB.ORB_EVERY - AB.ORB_EVERY_MIN) * left
    local tl = (math.random(10) <= 6 and playerTile(g)) or randomTile(g, false)
    local a = anchor(g)
    if tl and a and not tl.markGuid then
      mark(g, tl, AB.ORB_CHARGE)
      local o = a:SpawnCreature(E.ORB, tl.x, tl.y, tl.z + AB.ORB_Z, 0, TEMPSUMMON_TIMED_DESPAWN, AB.ORB_CHARGE + 1500)
      if o then try(o, "SetScale", AB.ORB_SCALE); try(o, "AddAura", S.ORB, o); try(o, "SetSpeed", 6, 3, true); try(o, "SetSpeed", 1, 3, true) end
      g.orbs[#g.orbs + 1] = { tile = tl, guid = o and o:GetGUID(), at = t + AB.ORB_CHARGE }
    end
  end
  for i = #g.orbs, 1, -1 do
    local ob = g.orbs[i]
    local o = obj(g, ob.guid)
    if not ob.dived and t >= ob.at - 600 then ob.dived = true; if o then try(o, "MoveTo", 0, ob.tile.x, ob.tile.y, ob.tile.z + 1.5) end end
    if t >= ob.at then
      local m = obj(g, ob.tile.markGuid)
      if o and m then try(o, "CastSpell", m, S.STAR, true) end       -- the burst
      if o then o:DespawnOrUnsummon(400) end
      hitTile(g, ob.tile)
      table.remove(g.orbs, i)
    end
  end
end

-- ---------- the pursuit ----------
local function addPathTile(g)
  local p = g.pursuit
  p.k = p.k + 1
  local th = AB.PATH_TURN * math.sin(p.k * AB.PATH_WAVE)
  p.px = p.px + AB.PITCH * math.cos(th); p.py = p.py + AB.PITCH * math.sin(th)
  p.pz = math.min(AB.CENTER[3] + AB.PATH_RISE_MAX, p.pz + AB.PATH_RISE)
  local tl = { x = p.px, y = p.py, z = p.pz, path = p.k, state = "down" }
  p.tiles[p.k] = tl
  spawnTile(g, tl)
end
local function startPursuit(g, t)
  tell(g, "The serpent begins the pursuit. Run ahead and stay on the path!", true)
  for i = #g.strikes, 1, -1 do unmark(g, g.strikes[i].tile); table.remove(g.strikes, i) end
  g.orbsUntil = nil
  local x0, y0 = tilePos(AB.ROWS, (AB.COLS + 1) / 2)
  g.pursuit = { t0 = t, tiles = {}, k = 0, dropped = 0, px = x0, py = y0, pz = AB.CENTER[3], sweepRow = 0, nextSweep = t + 2500 }
  for _, tl in ipairs(g.tiles) do                           -- the way onto the path: the far row is whole
    if tl.r == AB.ROWS then
      if tl.state == "down" then spawnTile(g, tl) elseif tl.state == "cracked" then local c = obj(g, tl.cGuid); if c then try(c, "RemoveAura", S.CRACK) end; tl.state = "up" end
    end
  end
  for _ = 1, AB.PATH_AHEAD do addPathTile(g) end
end
local function furthest(g)                                  -- the path tile number the leading runner stands on (0 = nobody is on the path)
  local best = 0
  local p = g.pursuit
  eachActive(g, function(low, m, pl)
    local x, y, z = pl:GetX(), pl:GetY(), pl:GetZ()
    for k, tl in pairs(p.tiles) do if k > best and tl.state ~= "down" and onTile(tl, x, y, z) then best = k end end
  end)
  return best
end
local function openPortals(g, t)
  local p = g.pursuit
  if not p or p.portals then return end
  tell(g, "Exit portals are open! Take a portal before the path collapses!", true)
  p.portals = {}
  local a = anchor(g)
  for k = p.k, math.max(1, p.k - 1), -1 do
    local tl = p.tiles[k]
    if tl and a then
      if tl.state == "down" then spawnTile(g, tl) end
      local c = a:SpawnCreature(E.MARK, tl.x, tl.y, tl.z + 0.5, 0, TEMPSUMMON_TIMED_DESPAWN, (AB.CYCLE - AB.AT_PORTALS) * 1000 + 3000)
      if c then try(c, "AddAura", S.PORTALVIS, c) end
      p.portals[#p.portals + 1] = { x = tl.x, y = tl.y, z = tl.z, guid = c and c:GetGUID() }
    end
  end
  if not p.rebuilt then p.rebuilt = true; rebuildField(g) end
end
local function endPursuit(g)                                -- the rest of the path goes; anybody still on it falls and comes back on the field
  local p = g.pursuit
  if not p then return end
  for _, tl in pairs(p.tiles) do if tl.state ~= "down" then dropTile(g, tl, nil) end end
  for _, po in ipairs(p.portals or {}) do local c = obj(g, po.guid); if c then c:DespawnOrUnsummon(0) end end
  if not p.rebuilt then rebuildField(g) end
  g.pursuit = nil
end
local function tickPursuit(g, t)
  local p = g.pursuit
  if not p then return end
  if p.sweepRow <= AB.ROWS and t >= p.nextSweep then        -- the field falls away row by row from the temple side
    p.nextSweep = t + AB.SWEEP_STEP
    p.sweepRow = p.sweepRow + 1
    for _, tl in ipairs(g.tiles) do
      if tl.r == p.sweepRow then crackTile(g, tl) elseif tl.r == p.sweepRow - 1 then dropTile(g, tl, nil) end
    end
    if p.sweepRow > AB.ROWS then p.chaseAt = t + AB.SWEEP_STEP; p.nextDrop = p.chaseAt; p.step = AB.CHASE_STEP end
  end
  if p.chaseAt and t >= p.nextDrop and not p.done then     -- the serpent takes the path down behind the runners
    local tl = p.tiles[p.dropped + 1]
    local keep = p.portals and 2 or 0                       -- the portal tiles stay to the end of the cycle
    if tl and p.dropped + 1 <= p.k - keep then
      dropTile(g, tl, nil); p.dropped = p.dropped + 1
      p.step = math.max(AB.CHASE_MIN, p.step - AB.CHASE_FASTER)
    end
    p.nextDrop = t + p.step
  end
  if not p.portals then                                     -- the path grows ahead of the leading runner
    local lead = math.max(furthest(g), p.dropped)
    while p.k < lead + AB.PATH_AHEAD and p.k < AB.PATH_MAX do addPathTile(g) end
  else
    eachActive(g, function(low, m, pl)
      for _, po in ipairs(p.portals) do
        if dist2(pl:GetX(), pl:GetY(), po.x, po.y) <= AB.PORTAL_R and math.abs(pl:GetZ() - po.z) < 8 then
          local tl = randomTile(g, true)
          if tl then pl:NearTeleport(tl.x, tl.y, tl.z + 1.2, pl:GetO()); m.safeUntil = t + 2500 end
        end
      end
    end)
  end
  if not p.rebuilt and t >= p.t0 + AB.REBUILD_AT * 1000 and p.sweepRow > AB.ROWS then p.rebuilt = true; rebuildField(g) end
end

-- ---------- lives ----------
local function lobbySpot(m)
  local k = (m.slot or 1) - 1
  return AB.LOBBY[1] - (k % 3) * 3, AB.LOBBY[2] + ((k % 7) - 3) * (AB.LOBBY_SPREAD / 2), AB.LOBBY[3], AB.LOBBY[4]
end
local function safeSpot(g)                                  -- where a player who fell comes back
  local p = g.pursuit
  if p and not p.rebuilt then                               -- on the path, a few tiles ahead of the collapse
    for k = math.min(p.k, p.dropped + 4), p.k do local tl = p.tiles[k]; if tl and tl.state ~= "down" then return tl end end
  end
  return randomTile(g, true)
end
local function putOut(g, low, pl, t)
  local m = g.members[low]
  m.out = true
  clearAuras(pl)
  local x, y, z, o = lobbySpot(m)
  pl:NearTeleport(x, y, z, o)
  if AB.TICKETS_OUT > 0 and not m.paid then m.paid = true; try(pl, "AddItem", ITEM_TICKET, AB.TICKETS_OUT) end
  tell(g, AT .. m.name .. " is out of the game.")
  pl:SendAreaTriggerMessage("You are out of lives. Watch the rest from the temple, or take the portal back to the Faire.")
  g.hudKey = nil
end
local function fell(g, low, pl, t)
  local m = g.members[low]
  m.lives = m.lives - 1; m.falls = (m.falls or 0) + 1
  try(pl, "CastSpell", pl, S.HEART, true)
  if m.lives <= 0 then putOut(g, low, pl, t); return end
  local tl = safeSpot(g)
  if tl then pl:NearTeleport(tl.x, tl.y, tl.z + 1.2, pl:GetO()) else local x, y, z, o = lobbySpot(m); pl:NearTeleport(x, y, z, o) end
  m.safeUntil = t + 2500
  pl:SendBroadcastMessage(AT .. string.format("You fell into the abyss. Lives left: %d.", m.lives))
  pl:SendAreaTriggerMessage(string.format("Lives left: %d", m.lives))
end

-- ---------- leaving ----------
local function sendHome(g, low)
  local m = g.members[low]
  local pl = getPlayer(g, low)
  if not (m and pl) then return end
  hudOff(pl); clearAuras(pl)
  local h = m.home or AB.FAIRE_SPOT
  later(m.guid, 500, function(p) if p:GetMapId() == AB.MAP then p:Teleport(h[1], h[2], h[3], h[4], h[5]) end end)
end
local function clearField(g)
  for _, t in ipairs(g.tiles or {}) do unmark(g, t); despawnAny(obj(g, t.goGuid)); local c = obj(g, t.cGuid); if c then c:DespawnOrUnsummon(0) end; t.state = "down" end
  if g.pursuit then
    for _, t in pairs(g.pursuit.tiles) do unmark(g, t); despawnAny(obj(g, t.goGuid)); local c = obj(g, t.cGuid); if c then c:DespawnOrUnsummon(0) end end
    for _, po in ipairs(g.pursuit.portals or {}) do local c = obj(g, po.guid); if c then c:DespawnOrUnsummon(0) end end
    g.pursuit = nil
  end
  for _, ob in ipairs(g.orbs or {}) do local o = obj(g, ob.guid); if o then o:DespawnOrUnsummon(0) end end
  local s = obj(g, g.serpentGuid); if s then s:DespawnOrUnsummon(0) end
  g.tiles = {}; g.orbs = {}; g.strikes = {}; g.serpentGuid = nil
end
local function cleanup(g, why)
  clearField(g)
  local po = obj(g, g.portalGuid); if po then po:DespawnOrUnsummon(0) end
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then sendHome(g, low) elseif pl then clearAuras(pl) end
  end
  if g.inst then Games[g.inst] = nil end
  log("game closed (" .. tostring(why) .. ")")
end

-- ---------- the match ----------
local function bigCountdown(pl, ms)                         -- the client draws the big numbers itself (as in the other mini-games)
  if not (AB.BIG_COUNTDOWN and pl and type(CreatePacket) == "function") then return false end
  local ok, err = pcall(function() local pk = CreatePacket(OP_COUNTDOWN, 4); pk:WriteULong(ms); pl:SendPacket(pk) end)
  if not ok then log("could not send the countdown packet: " .. tostring(err)) end
  return ok
end
local function sweepGone(g, t)                              -- players who left the map drop out after 15 s
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then m.goneSince = nil
    else
      m.goneSince = m.goneSince or t
      if t > m.goneSince + 15000 then
        if pl then clearAuras(pl) end
        g.members[low] = nil; g.count = math.max(0, g.count - 1); g.hudKey = nil; log(m.name .. " left the game")
      end
    end
  end
end
local function setDown(g, t)                                -- everybody onto a tile of his own
  local used = {}
  eachActive(g, function(low, m, pl)
    local tl
    for _ = 1, 20 do tl = randomTile(g, true); if tl and not used[tl] then break end end
    if tl then used[tl] = true; pl:NearTeleport(tl.x, tl.y, tl.z + 1.2, AB.LOBBY[4]) end
    m.safeUntil = t + 4000
  end)
end
local function startCountdown(g, t)
  g.state = "countdown"; g.countAt = t; g.lastCount = nil; g.down = false
  g.style = STYLES[(AB.STYLE >= 1 and AB.STYLE <= #STYLES) and AB.STYLE or math.random(#STYLES)]
  g.pattern = PATTERNS[(AB.PATTERN >= 1 and AB.PATTERN <= #PATTERNS) and AB.PATTERN or math.random(#PATTERNS)]
  g.strikes, g.orbs, g.cycle = {}, {}, 1
  buildField(g)
  local a = anchor(g)
  if a then
    local s = a:SpawnCreature(E.SERPENT, AB.CENTER[1] + AB.SERPENT_R, AB.CENTER[2], AB.CENTER[3] + AB.SERPENT_Z, 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if s then
      g.serpentGuid = s:GetGUID()
      try(s, "SetSpeed", 6, AB.SERPENT_SPEED / 7.0, true); try(s, "SetSpeed", 1, AB.SERPENT_SPEED / 7.0, true)
    else log("could not spawn the Celestial Serpent (creature " .. E.SERPENT .. " missing? run Azzar-Abyss-Apply.bat and restart)") end
  end
  g.bigOk = true
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      m.lives = AB.LIVES; m.out = nil; m.falls = 0
      if AB.TRANSFORM then try(pl, "AddAura", S.VORTEX, pl) end
      if AB.SILENCE then try(pl, "AddAura", S.PREGAME, pl) end
      if not bigCountdown(pl, AB.COUNTDOWN * 1000) then g.bigOk = false end
      pl:SendAreaTriggerMessage("|cff40ff40" .. ENTITY .. "|r")
    end
  end
  tell(g, AT .. "Your opponent: |cff40ff40" .. ENTITY .. "|r. You have " .. AB.LIVES .. " lives: do not fall into the abyss!")
end
local function finish(g, t)
  g.state = "ending"; g.doneAt = t
  local names, winners = {}, {}
  for low, m in pairs(g.members) do if active(m) then names[#names + 1] = m.name; winners[#winners + 1] = low end end
  table.sort(names)
  if #names > 0 then tell(g, "Survivors win: " .. table.concat(names, ", "), true)
  else tell(g, "Nobody survived the A.B.Y.S.S.", true) end
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then
      clearAuras(pl)
      if active(m) then
        try(pl, "AddItem", ITEM_TICKET, AB.TICKETS)
        giveAch(pl, ACH.WIN)
        if (m.falls or 0) == 0 then giveAch(pl, ACH.UNTOUCHED) end
      end
      if pl:HasQuest(Q1) then pl:KilledMonsterCredit(E.CREDIT1) end      -- 'Complete a battle in A.B.Y.S.S.' (the quests themselves are not in our database yet)
      if pl:HasQuest(Q2) then pl:KilledMonsterCredit(E.CREDIT2) end
    end
  end
  clearField(g)
  for _, low in ipairs(winners) do                          -- the field is gone: the winners stand on the temple with the others
    local m, pl = g.members[low], getPlayer(g, low)
    if pl and inGame(g, pl) then local x, y, z, o = lobbySpot(m); pl:NearTeleport(x, y, z, o) end
  end
  tell(g, AT .. "The match is over. Back to the Faire in a few seconds.")
  log(string.format("match over: %d survivor(s) of %d", #names, g.count))
end
local PHASES = { "meteor", "starfall", "orbs", "pursuit", "portals", "next" }
local function runPhase(g, t, name)
  if name == "meteor" then meteorCross(g, t)
  elseif name == "starfall" then starfall(g, t)
  elseif name == "orbs" then tell(g, "Celestial orbs are charging. Keep moving!", true); g.orbsUntil = t + AB.ORBS_MS; g.nextOrb = t + 800
  elseif name == "pursuit" then if not g.pursuit then startPursuit(g, t) end
  elseif name == "portals" then openPortals(g, t)
  elseif name == "next" then
    endPursuit(g)
    g.cycle = g.cycle + 1; g.cycleAt = t; g.phase = 1
    for low, _ in pairs(g.members) do local pl = getPlayer(g, low); if inGame(g, pl) then pl:SendAreaTriggerMessage("|cff40ff40" .. ENTITY .. "|r") end end
  end
end
local function phaseAt(name)
  if name == "meteor" then return AB.AT_METEOR elseif name == "starfall" then return AB.AT_STARFALL elseif name == "orbs" then return AB.AT_ORBS
  elseif name == "pursuit" then return AB.AT_PURSUIT elseif name == "portals" then return AB.AT_PORTALS end
  return AB.CYCLE
end
local function tickGame(g, t)
  if g.state == "arriving" then
    local allIn = true
    for low, _ in pairs(g.members) do if not inGame(g, getPlayer(g, low)) then allIn = false end end
    if (allIn and t >= g.arrivedAt + 3000) or t >= g.arrivedAt + 30000 then
      for low, _ in pairs(g.members) do
        if not inGame(g, getPlayer(g, low)) then g.members[low] = nil; g.count = math.max(0, g.count - 1) end
      end
      local a = anchor(g)
      if a then
        for _, e in ipairs({ 99496, 99500, 99501, 99502, E.SERPENT, E.MARK, E.ORB, E.PORTAL }) do   -- leftovers of an earlier match in this instance
          local list = try(a, "GetCreaturesInRange", 300, e)
          for _, c in ipairs(type(list) == "table" and list or {}) do c:DespawnOrUnsummon(0) end
        end
        local po = a:SpawnCreature(E.PORTAL, AB.PORTAL_AT[1], AB.PORTAL_AT[2], AB.PORTAL_AT[3], 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
        if po then g.portalGuid = po:GetGUID() end
      end
      g.state = "lobby"; g.startAt = t + AB.LOBBY_WAIT * 1000
      tell(g, AT .. "Waiting for more players to join...", "Waiting for more players to join...")
      tell(g, AT .. string.format("Game will start in %d seconds with the current players.", AB.LOBBY_WAIT))
    end
  elseif g.state == "lobby" then
    sweepGone(g, t)
    if not g.said10 and g.startAt - t <= 10000 and AB.LOBBY_WAIT > 10 then
      g.said10 = true; tell(g, AT .. "Game will start in 10 seconds with the current players.")
    end
    if g.count > 0 and t >= g.startAt then startCountdown(g, t) end
  elseif g.state == "countdown" then
    local n = AB.COUNTDOWN - math.floor((t - g.countAt) / 1000)
    if n ~= g.lastCount then
      g.lastCount = n
      if n <= AB.SETDOWN_AT and not g.down then g.down = true; setDown(g, t) end
      if n > 0 then
        if not g.bigOk then tell(g, AT .. n .. "...", tostring(n)) end
      else
        g.state = "playing"; g.startedAt = t; g.endAt = t + AB.GAME_TIME * 1000; g.cycleAt = t; g.phase = 1; g.hudKey = nil
        for low, _ in pairs(g.members) do local pl = getPlayer(g, low); if pl then try(pl, "RemoveAura", S.PREGAME) end end
        log("match started with " .. g.count .. " player(s), tile " .. g.style.tile)
      end
    end
    eachActive(g, function(low, m, pl)                      -- nobody loses a life before the start
      if g.down and pl:GetZ() < AB.CENTER[3] - AB.FALL_Z then local tl = randomTile(g, true); if tl then pl:NearTeleport(tl.x, tl.y, tl.z + 1.2, pl:GetO()) end end
    end)
  elseif g.state == "playing" then
    sweepGone(g, t)
    eachActive(g, function(low, m, pl)
      if pl:GetZ() < AB.CENTER[3] - AB.FALL_Z and t > (m.safeUntil or 0) then fell(g, low, pl, t) end
    end)
    while g.phase <= #PHASES and t >= g.cycleAt + phaseAt(PHASES[g.phase]) * 1000 do
      local name = PHASES[g.phase]; g.phase = g.phase + 1
      local ok, err = pcall(runPhase, g, t, name); if not ok then log("phase error (" .. name .. "): " .. tostring(err)) end
    end
    local ok, err = pcall(tickStrikes, g, t); if not ok then log("strike error: " .. tostring(err)) end
    ok, err = pcall(tickOrbs, g, t); if not ok then log("orb error: " .. tostring(err)) end
    ok, err = pcall(tickPursuit, g, t); if not ok then log("pursuit error: " .. tostring(err)) end
    ok, err = pcall(tickSerpent, g, t); if not ok then log("serpent error: " .. tostring(err)) end
    for _, tl in ipairs(g.tiles) do                         -- fallen tiles come back (not while the pursuit has the field down)
      if tl.state == "down" and tl.respawnAt and t >= tl.respawnAt and not (g.pursuit and not g.pursuit.rebuilt) then spawnTile(g, tl) end
    end
    hudShow(g, (g.endAt - t) / 1000)
    if t >= g.endAt or remaining(g) == 0 then finish(g, t) end
  elseif g.state == "ending" then
    sweepGone(g, t)
    if t > g.doneAt + AB.END_WAIT then cleanup(g, "finished"); return end
  end
  local here = 0
  for _ in pairs(g.members) do here = here + 1 end
  if here == 0 and g.state ~= "arriving" then cleanup(g, "nobody left") end
end
local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)
    if t > g.created + 30000 then
      Pending[sLow] = nil; log("start cancelled (the starter did not arrive on map " .. AB.MAP .. " within 30 s: raid map, see the note in startSession)")
      if st then st:SendBroadcastMessage(AT .. "You did not get into the A.B.Y.S.S. map (raid map: GM mode on, a raid group, or Instance.IgnoreRaid = 1).") end
    elseif st and st:GetMapId() == AB.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then st:SendBroadcastMessage(AT .. "A match is already running here.")
      else Games[g.inst] = g; g.state = "arriving"; g.arrivedAt = t end
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
end, 250, 0)

-- ---------- starting ----------
local function busy(player)
  local low = player:GetGUIDLow()
  for _, g in pairs(Games) do if g.members[low] then return true end end
  for _, g in pairs(Pending) do if g.members[low] then return true end end
  return false
end
local function startSession(player)
  local members, count = {}, 0
  local function add(p)
    if count >= AB.MAX_PLAYERS or p:IsBot() then return end  -- real players only for now
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), name = p:GetName(), slot = count, lives = AB.LIVES,
                     home = (p:GetMapId() ~= AB.MAP) and { p:GetMapId(), p:GetX(), p:GetY(), p:GetZ(), p:GetO() } or nil }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= AB.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  if count == 0 then return end
  -- Map 968 is a RAID map (Map.dbc type 2, 40 players) and the realms run with Instance.IgnoreRaid = 0: the core only lets you in with a raid
  -- group or in GM mode. A party is made a raid here; alone and not in GM mode you are told why nothing happens.
  if grp then
    if try(grp, "IsRaidGroup") ~= true then try(grp, "ConvertToRaid") end
  else
    player:SendBroadcastMessage(AT .. "A.B.Y.S.S. is a raid map: alone the server only lets you in with GM mode on (.gm on), or with Instance.IgnoreRaid = 1 in worldserver.conf.")
  end
  local g = { members = members, count = count, created = now(), state = "pending", tiles = {}, strikes = {}, orbs = {}, cycle = 1 }
  Pending[player:GetGUIDLow()] = g
  for low, m in pairs(members) do
    local p = GetPlayerByGUID(m.guid)
    if p then
      local x, y, z, o = lobbySpot(m)
      p:SendBroadcastMessage(AT .. "You have joined the A.B.Y.S.S. queue.")
      p:Teleport(AB.MAP, x, y, z, o)
    end
  end
  log(string.format("%s starts A.B.Y.S.S. with %d player(s)", player:GetName(), count))
end
local function leaveGame(player)
  local low = player:GetGUIDLow()
  local g = Games[player:GetInstanceId()]
  if g and g.members[low] then
    sendHome(g, low)
    later(player:GetGUID(), 1500, function() if g.members[low] then g.members[low] = nil; g.count = math.max(0, g.count - 1); g.hudKey = nil end end)
  else
    clearAuras(player); hudOff(player)
    local f = AB.FAIRE_SPOT; player:Teleport(f[1], f[2], f[3], f[4], f[5])
  end
  player:SendBroadcastMessage(AT .. "Back to the Faire you go!")
end

-- ---------- Mizzle ----------
local function mizzleMenu(player, creature)
  player:GossipClearMenu()
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Enter A.B.Y.S.S. (with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about A.B.Y.S.S.?", 0, 2)
  player:GossipSendMenu(TEXT_GREET, creature)
end
RegisterCreatureGossipEvent(E.MIZZLE, 1, function(event, player, creature) mizzleMenu(player, creature) end)
RegisterCreatureGossipEvent(E.MIZZLE, 2, function(event, player, creature, sender, intid)
  if intid == 1 then
    player:GossipComplete()
    if busy(player) then player:SendBroadcastMessage(AT .. "You are already in a match."); return end
    startSession(player)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_RULES, creature)
  else
    mizzleMenu(player, creature)
  end
end)

-- ---------- the Azzar Faire Portal on the temple (the same orb creature as in the other mini-games, which stand on map 960) ----------
local function ourPortal(creature) return creature:GetMapId() == AB.MAP end
RegisterCreatureGossipEvent(E.PORTAL, 1, function(event, player, creature)
  if not ourPortal(creature) then return end
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Exit!", 0, 20, false, "Are you sure you want to exit?")
  player:GossipSendMenu(TEXT_PORTAL, creature)
end)
RegisterCreatureGossipEvent(E.PORTAL, 2, function(event, player, creature, sender, intid)
  if not ourPortal(creature) then return end
  player:GossipComplete()
  if intid == 20 then leaveGame(player) end
end)

-- ---------- safety: nobody keeps the ethereal look or the silence outside the A.B.Y.S.S. map ----------
local function strip(event, player) if player and player:GetMapId() ~= AB.MAP then clearAuras(player) end end
RegisterPlayerEvent(3, strip)     -- login
RegisterPlayerEvent(28, strip)    -- map change

-- ---------- chat commands ----------
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#leave" then
    if player:GetMapId() ~= AB.MAP then return end
    leaveGame(player)
    return false
  end
  local cmd, arg = msg:match("^#ab%s+(%a+)%s*(%S*)%s*%S*$")
  if not cmd or (player:GetGMRank() or 0) < 1 then return end
  cmd = cmd:lower()
  local g = Games[player:GetInstanceId()]
  if g and not g.members[player:GetGUIDLow()] then g = nil end
  if cmd == "start" then
    if busy(player) then player:SendBroadcastMessage(AT .. "You are already in a match.") else startSession(player) end
  elseif cmd == "go" then
    if g and g.state == "lobby" then g.startAt = now() else player:SendBroadcastMessage(AT .. "Only while waiting on the temple.") end
  elseif cmd == "time" and tonumber(arg) then
    if g and g.state == "playing" then g.endAt = now() + tonumber(arg) * 1000; player:SendBroadcastMessage(AT .. "End of Game: " .. mmss(tonumber(arg)))
    else player:SendBroadcastMessage(AT .. "No match is running here.") end
  elseif cmd == "phase" then
    local okName = false
    for _, n in ipairs(PHASES) do if n == arg then okName = true end end
    if g and g.state == "playing" and okName then
      local ok, err = pcall(runPhase, g, now(), arg)
      player:SendBroadcastMessage(AT .. (ok and ("Phase '" .. arg .. "' now.") or ("Phase error: " .. tostring(err))))
    else player:SendBroadcastMessage(AT .. "Usage (during a match): #ab phase meteor | starfall | orbs | pursuit | portals | next") end
  elseif cmd == "lives" and tonumber(arg) then
    if g then g.members[player:GetGUIDLow()].lives = math.floor(tonumber(arg)); player:SendBroadcastMessage(AT .. "Lives: " .. arg) end
  elseif cmd == "fx" and tonumber(arg) then                 -- look at any visual on a marker 8 yd in front of you for 12 s
    local o = player:GetO()
    local c = player:SpawnCreature(E.MARK, player:GetX() + 8 * math.cos(o), player:GetY() + 8 * math.sin(o), player:GetZ() + 0.3, o, TEMPSUMMON_TIMED_DESPAWN, 12000)
    if c then try(c, "AddAura", tonumber(arg), c); try(c, "CastSpell", c, tonumber(arg), true) end
    player:SendBroadcastMessage(AT .. (c and ("Spell " .. arg .. " on a marker in front of you for 12 s.") or "Could not spawn the marker (run Azzar-Abyss-Apply.bat and restart?)."))
  elseif cmd == "set" then
    local k, v = msg:match("^#ab%s+set%s+([%w_]+)%s+(%S+)")
    if k and type(AB[k]) == "number" and tonumber(v) then AB[k] = tonumber(v); player:SendBroadcastMessage(AT .. k .. " = " .. v .. " (until the next .reload ale; tell Claude what you kept).")
    elseif k and type(AB[k]) == "boolean" then AB[k] = (v == "true" or v == "1" or v == "on"); player:SendBroadcastMessage(AT .. k .. " = " .. tostring(AB[k]) .. " (until the next .reload ale).")
    else player:SendBroadcastMessage(AT .. "Usage: #ab set <SETTING> <value>   (a number or true/false setting from the top of the script, e.g. STYLE, PATTERN, LIVES, MARK_SCALE)") end
  else
    player:SendBroadcastMessage(AT .. "GM: #ab start | #ab go | #ab time <seconds left> | #ab phase <name> | #ab lives <n> | #ab fx <spell id> | #ab set <SETTING> <value>     Everyone: #leave")
  end
  return false
end)

log("script loaded v0.1 first build (field 11x8, Celestial Serpent cycle: meteor cross, starfall, orbs, pursuit + exit portals; 3 lives; 6:00)")
