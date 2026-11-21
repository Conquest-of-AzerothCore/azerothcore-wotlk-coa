--[[ Venture Co / Azzar Faire: VERTICAL ASCENT mini-game (Rowan/Claude 2026-11-13, v1 "like live", Emerald course).
  Needs mod-ale (ALE) on + azzar-vertical-ascent.sql applied. Built from the 1-second footage pass
  (faire-cache\vertical-ascent-1s\VERTICAL-ASCENT-1S-SCAN-2026-11-13.md), Rowan's walk-through on 2026-11-13 and his .gps on map 960.

  FLOW (as on live, Rowan 11:30):
   1. Belle (371937) at the Faire: "Let's climb!" -> you + up to 4 group members near you (bots too) go to the lobby tent
      "Vertical Ascend" on map 960. "Azzar Event: You have been invited to Parkour."
   2. Talk to Belle in the lobby (99640): "I'm ready!" -> green check over your head. Bots are ready by themselves; a bot can never
      start a round, only real players. When every real player is ready: "Vertical Ascent: A random scenario is being selected...",
      a light runs round the 9 course portals and stops on one: "Vertical Ascent: Selected scenario: Emerald Dream." That portal lights up.
   3. Walk into the lit portal -> you arrive at the bottom of the course; bots follow you in. "Azzar Event: Round 1 is starting!"
      The 15-minute game clock starts ("End of Game", [TIMER] 3 / 2 minutes remaining).
   4. Jump into the spring -> suited up: you get the "Return to Checkpoint" button (spell 255753, in your spellbook, General tab).
      Climb. The green heads are checkpoints ("Checkpoint reached by: X"); fall to the floor = back to your last checkpoint.
   5. Goal at the top: "First place: X" / "Goal reached by: X", 300 Azzar Faire Tickets, course achievement (Emerald Ascent),
      Jumps and Friends (first finish), quest credit (Vertical Ascent / daily). Then wait for the clock (or everyone finished):
      everyone goes back to the lobby. Belle there starts the next round; the portal behind you goes back to the Faire.
  OURS (not live): a vehicle cannot jump, so the live suit vehicle (99529) is not used: the button is a spell you have during the run.
  BOTS (Rowan: for Squids' data): bots come along, are walked into the spring, then their own AI does what it can. Every bot's run is
   logged as one [VertAscent] BOTRUN line (checkpoints + times, falls, highest point, time stood still, big jumps = bot teleports).
  Safety hatch: say #leave on map 960. Lines starting with [VertAscent] in the server log are from this script. ]]

-- ======================= SETTINGS =======================
local VA = {
  MAP = 960,
  LOBBY_ARRIVE = { 5748.0, -4697.8, 9.95, 3.14 },        -- lobby floor (z 9.95, Rowan .gps), east of the centre, facing Belle
  BELLE = { 5743.4883, -4702.922, 9.947, 6.156687 },      -- Rowan .gps 11:39 (where live Belle stands in her robot)
  EXIT_PORTAL = { 5743.1494, -4693.0547, 9.947, 6.138 },  -- Rowan .gps 11:40: portal back to the Faire
  FAIRE_SPOT = { 909, -1795.91, -11999.08, 61.68, 2.90 }, -- fallback way home (Takk's tent) if we don't know where you came from
  PORTAL_Z = 9.95,                                        -- course portals stand on the lobby floor (Rowan .gps on the Emerald pad 11:44)
  MAX_PLAYERS = 5, JOIN_RANGE = 60.0,
  GAME_SECONDS = 900,                                     -- live: 'End of Game: 14:55' right after the start
  PORTAL_R = 2.5,                                         -- walk within 2.5 yd of a portal to use it
  PORTAL_WAIT = 60,                                       -- seconds after the pick before anyone still in the lobby is sent through
  SPRING_R = 3.5, SPRING_DZ = 3.0,                        -- in the spring = suited
  BOT_SPRING_WAIT = 8,                                    -- a bot not in the spring after 8 s is put in it
  CP_R = 4.0, CP_DZ = 4.0,                                -- touch a checkpoint / the goal
  FALL_MARGIN = 3.0,
  SAFE_R = 18.0,                                          -- floor within 18 yd of the arrival point is not a fall (spring 14 yd, return portal 15 yd away)                                      -- below floor + 3 yd (and not at the spring) = fell
  AFTER_GAME = 30,                                        -- seconds at the top after the game ends, then back to the lobby
  LOBBY_IDLE = 300,                                       -- lobby with nobody ready for 5 min -> everyone back to the Faire
  ROULETTE_MS = 180, ROULETTE_LAPS = 2,                   -- the light: 180 ms a portal, 2 full laps, then it slows down onto the pick
  BOT_STILL_YD = 0.5, BOT_JUMP_YD = 25.0,                 -- bot log: moved < 0.5 yd in a tick = standing still; > 25 yd in a tick = teleported
  TICKETS = 300,
  BELLE_MOUNT = 142795,                                   -- gizmomech_mount.m2 (Animatronic Gizmo 165621's display), Faire themed
  USE_VEHICLE = true,                                     -- v1.3i (Rowan 14:11): live DOES use the suit vehicle; back on                                    -- v1.3f (Rowan 14:03): the vehicle suit plays a boarding animation, stops GM fly and the fall
                                                          -- check (rider height not tracked): live MORPHS you into the suit. Morph + spellbook button instead.                                          -- live: 'You Received: Azzar Faire Ticket x300' on finishing (Rowan screenshot)
}
-- the 9 courses, in the order the portals stand round the lobby (client map markers; Emerald = Rowan .gps)
local COURSES = {
  { key = "kultiran",  name = "Kul Tiras",     portal = 99641, lit = 137894, x = 5702.9,    y = -4704.6,   ach = 90164,
    -- v1.7 (Rowan .gps 23:07-23:16, order 1-4). Tent 01 (docks, cannons, Daelin statue, prison tentacles), origin ~5448.5 -4704.5 rotated 270
    arrive = { 5386.0176, -4696.756, 10.2726, 6.2026 },   -- outer floor, facing the course
    spring = { 5398.884, -4697.4727, 11.0236 },           -- the Kul Tiran bed at the foot of the round stone base
    springName = "bed", springR = 2.5,
    safeR = 30.0,                                         -- start -> bed 13 yd, -> return portal 27 yd
    floor = 10.27,
    checkpoints = {
      { 5448.4, -4653.9, 18.7238 },                       -- 1 round stone platform
      { 5444.4707, -4716.1123, 17.016 },                  -- 2 stone ledge by Daelin's pedestal
      { 5446.015, -4741.7065, 23.4613 },                  -- 3 round platform with a tentacle over it
      { 5492.8413, -4705.594, 30.8191 },                  -- 4 big platform with the working Kul Tiran fountain
    },
    goal = { 5476.9775, -4686.629, 50.926 },              -- the big starry bed up high
    back = { 5379.4, -4723.15, 10.27, 0.264 },            -- client marker, facing the tent centre (Rowan 23:18: fine)
    fx = { cpSplash = 36005, cpExplosion = false },       -- Rowan 23:19: Water Splash on credit like Naga, no explosion (it's Kul Tiras)
    life = {                                              -- v1.8 (Rowan 23:20/23:25): pirates duelling on the floor + parrots, 'enough to feel alive', a variety
      parrots = { entry = 9600, cx = 5448.5, cy = -4704.5, rMin = 25, rMax = 55, zMin = 28, zMax = 55,
                  displays = { 80412, 80413, 142957, 5207, 6192, 9554 } },  -- live VA parrots 99632/99633's looks, Azzar Parrot, 3 macaws
      cannons = {                                         -- v1.8c (Rowan 23:48/23:51): 4 spawned small Kul Tiran cannons (410587) firing harmless shots
        guns = { { 5398.626, -4717.64, 9.947, 6.1335 }, { 5440.21, -4667.6885, 9.947, 6.2827 },
                 { 5483.8433, -4658.676, 9.947, 3.4239 }, { 5469.321, -4748.366, 9.947, 1.4525 } },
        display = 410587, ball = 410409, carrier = 9600,  -- cannon model, Kul Tiran cannonball model, a movable stock template to carry the ball
        fuse = 50558, fire = 68416, impact = 992005,     -- fuse lit, ball leaves the barrel, impact (Rowan's picks)
        distMin = 15, distMax = 45, cone = 0.5, floorZ = 9.95, everyMin = 4, everyMax = 8,
      },
      duels = {                                           -- { x, y, z, o, a = entry, b = entry [, mage = entry] }: Rowan .gps 23:30 (inner floor z 9.947)
        { 5414.8945, -4730.2744, 9.947, 0.522, a = 1561, b = 7855 },               -- Bloodsail Raider vs Southsea Pirate
        { 5481.897, -4733.968, 9.947, 2.081, a = 1563, b = 7902, mage = 1562 },    -- Bloodsail Swashbuckler vs Treasure Hunting Buccaneer (+ Bloodsail Mage)
        { 5469.908, -4653.5522, 9.947, 4.430, a = 4506, b = 7899 },                -- Bloodsail Swabby vs Treasure Hunting Pirate
      },
    },
  },
  { key = "mechagnome",name = "Mechagnome",    portal = 99642, lit = 137895, x = 5707.2,    y = -4677.3,   ach = 90166,
    -- v1.9 (2026-11-16, Claude, unattended): spots READ FROM THE MAP MODELS, not walked: tent WMO ..._PARKOUR_02 at 5211.775 -4697.796 (ADT placement) + its doodads' collision,
    -- ray cast straight down at the client map markers (method checked on Emerald: Rowan's 4 .gps heights matched within 0.01 yd).
    -- PROVEN 2026-11-18 18:14 (Rowan: 'Mecha Gnome is good. The markers were there and everything.'): in the random pick now (v1.9a).
    arrive = { 5279.765, -4674.103, 9.69, 3.477 },        -- outer floor ring behind the start pad, facing it (computed, like Rowan's picks on the other courses)
    spring = { 5261.50, -4680.47, 10.74 },                -- the big Mechagon teleport pad (teleportpad01) under the client start marker
    springName = "teleport pad", springR = 3.5,
    safeR = 31.0,                                         -- arrival -> pad 19 yd, -> return portal 27 yd
    floor = 9.95,
    checkpoints = {                                       -- each one is its own small teleport pad (teleportpad02) centred on the client marker
      { 5175.96, -4708.35, 26.23 },                       -- 1 pad, west
      { 5227.48, -4747.63, 34.51 },                       -- 2 pad, south (a big cog hangs over it at z 40-48)
      { 5256.11, -4717.08, 36.00 },                       -- 3 pad, south-east
    },
    goal = { 5250.21, -4685.33, 19.02 },                  -- pad on top of the power pole beside the start (lower than checkpoint 3: you drop down to it)
    back = { 5274.71, -4701.03, 10.26, 3.09 },            -- client marker, facing the tent centre
  },
  { key = "titan",     name = "Titan",         portal = 99643, lit = 137896, x = 5728.2,    y = -4659.4,   ach = 90172,
    -- v1.9 (2026-11-16, Claude, unattended): spots READ FROM THE MAP MODELS, not walked: tent WMO ..._PARKOUR_03 at 4919.766 -4697.796 (ADT placement) + its doodads' collision,
    -- ray cast straight down at the client map markers (method checked on Emerald: Rowan's 4 .gps heights matched within 0.01 yd).
    -- PROVEN 2026-11-18 18:26 (Rowan: 'all good' after testing the last four): in the random pick now (v1.9b).
    arrive = { 4999.76, -4698.783, 9.69, 3.129 },
    spring = { 4993.36, -4698.70, 9.69 },                 -- client start marker: bare floor (no fountain/pad model here), marked with a light beam
    springName = "light", springR = 3.5,
    safeR = 23.0,                                         -- arrival -> light 6 yd, -> return portal 19 yd
    floor = 9.95, fallMargin = 2.0,                       -- the two throne seats are only ~3.5 yd above the floor
    checkpoints = {
      { 4915.11, -4645.08, 38.09, alt = { 32.78, 16.73 } }, -- 1 the standing female protector statue, north: flat surface at 38.1 under the marker (others at 32.8 and 16.7: see 'alt')
      { 4867.09, -4695.73, 13.98 },                       -- 2 seat of the titan throne, west
      { 4918.54, -4751.89, 13.37 },                       -- 3 seat of the smaller titan throne, south
    },
    goal = { 4967.48, -4715.02, 37.86, alt = { 31.46, 17.16 } },  -- the standing male protector statue by the start: flat surface at 37.9 (others at 31.5 and 17.2)
    back = { 4998.55, -4679.75, 9.69, 3.367 },
    fx = { decor = { { 255816, 4993.36, -4698.70, 9.69 } } },   -- light beam on the suit-up spot (the roulette/checkpoint beam; swap if Rowan wants another)
  },
  { key = "volcanic",  name = "Volcanic",      portal = 99644, lit = 137897, x = 5757.0,    y = -4660.7,   ach = 90168,
    -- v1.6 BUILT (Rowan .gps 19:39-20:18, order 1-4 confirmed 20:19). Tent 04, volcano centre 5218.3 -4379.9
    arrive = { 5288.818, -4409.7783, 9.686, 2.666 },     -- Rowan 19:39: players + bots start here (outer wooden ring, facing the volcano)
    floor = 9.69,
    spring = { 5278.3955, -4404.8794, 10.3114 },          -- suit-up spot on the green rim at the lava's edge (Rowan 20:06), marked with a fire ring
    springName = "fire ring", springR = 3.5,
    safeR = 18.0,                                         -- safe circle round the start (portal 16 yd inside; lava edge ~18.6 yd)
    deathFalls = true, fallMargin = 1.0,                  -- v1.6b: lava surface ~10.0-10.3; only below z ~10.7 counts (low rocks by the rim are safe to stand on)
                                       -- Rowan 20:04: anywhere at floor level outside the safe zone = you burn, then respawn at your checkpoint
    checkpoints = {
      { 5278.9243, -4386.596, 26.3887 },                  -- 1 red lava-rock column
      { 5227.1, -4318.3, 31.0513 },                       -- 2 lava fissure on the black rock
      { 5158.3, -4375.9, 32.0793 },                       -- 3 flat hex-rock top
      { 5214.367, -4441.155, 36.5871 },                   -- 4 tallest hex column
    },
    goal = { 5261.7446, -4423.3477, 38.8104 },            -- glowing hex-tower top (Rowan 20:33, standing on it, fly off; the 20:18 reading was a ledge mid-column)
    back = { 5296.1, -4395.6, 9.69, 2.94 },               -- client marker, facing the volcano (Rowan 20:15: fine)
    fx = {
      decor = {                                           -- lava ring: volcano foot r 28 (Rowan .gps 5242.98 -4393.07 z10.27) to outer edge r 58 (5270.46 -4405.81 z9.95)
        { 992872, 5278.3955, -4404.8794, 10.3114 },          -- fire ring on the suit-up spot (20:10)
        { 0, 5218.3, -4379.9, 10.1, 1.0, display = 135249, count = 4, rIn = 28, rOut = 58, size = 11 },   -- BfA lava pool, random spots each round
        { 0, 5218.3, -4379.9, 10.1, 1.0, display = 407016, count = 5, rIn = 28, rOut = 58, size = 8 },    -- Blackrock lava bubbles, random
      },
      goalMarker = 76006,                                 -- v1.6c: Cosmetic - Fire Pillar on the goal (Rowan 20:29: goal marker missing)
    },
  },
  { key = "emerald",   name = "Emerald Dream", portal = 99645, lit = 137898, x = 5776.4507, y = -4677.419, ach = 90170,
    -- Rowan .gps 2026-11-13 11:49-12:07 (tent 05, origin 4921.5 -4380.0)
    arrive = { 4997.7715, -4363.327, 9.686, 4.5965 },
    spring = { 4995.9, -4376.9, 9.7 },                    -- the moonwell (WMO doodad, matches the client start marker)
    floor = 9.69,
    checkpoints = {                                       -- the 4 giant heads, climbing order N -> W -> S -> E
      { 4974.37,   -4379.078,  31.666 },
      { 4922.6523, -4327.0396, 31.376 },
      { 4869.211,  -4380.563,  32.559 },
      { 4922.626,  -4432.8755, 32.552 },
    },
    goal = { 4959.397, -4378.613, 42.409 },
    back = { 4996.245, -4348.3555, 9.685, 3.436 },        -- portal back to the lobby
    fx = { cpMarker = 255489 },                           -- Rowan 17:45: Visual: Arcane Fountain (green vines + beam) on unreached heads; steady, not looped
  },
  { key = "naga",      name = "Naga",          portal = 99646, lit = 137899, x = 5785.7,    y = -4704.9,   ach = 90171,
    -- Rowan .gps 2026-11-13 16:38-17:29 (tent 06, origin ~5218.2 -4148.3, rotated 180; Nazjatar ruins)
    arrive = { 5294.001, -4151.0747, 9.686, 3.0407 },     -- Rowan's pick: outer floor ring, facing the fountain
    spring = { 5268.99, -4148.88, 10.88 },                -- the broken naga fountain (centre from the arch top, z = basin ring)
    springName = "fountain",                              -- v1.4f: what the messages call the start spot
    springR = 5.0,                                        -- the arch fills the middle: the ring you can stand on is ~3.8 yd out
    safeR = 30.0,                                         -- arrival -> fountain 25 yd, -> return portal ~27 yd
    floor = 9.95,                                         -- inner floor (outer ring 9.69)
    checkpoints = {                                       -- Rowan's order 17:26 (annotated screenshots)
      { 5262.1504, -4124.373, 23.2118 },                  -- 1 octagon pillar near the start
      { 5219.695, -4106.1187, 23.268 },                   -- 2 octagon pillar in front of the north statue (not the statue: Rowan)
      { 5167.07, -4148.12, 43.10, at = { 5169.104, -4148.1377, 43.099 } },  -- 3 far statue behind Azshara: marker under her, respawn beside her
      { 5217.19, -4200.38, 28.14, at = { 5217.0576, -4198.5547, 28.143 } }, -- 4 south statue
    },
    goal = { 5268.634, -4163.468, 28.599 },               -- top of the rotunda arch beside the fountain
    back = { 5293.5, -4124.4, 9.69, 3.448 },              -- live marker, facing the tent centre
    fx = {                                                -- Rowan 16:41-17:00
      cpMarker = 463649, cpMarkerMs = 2000,               -- Watersplash Visual, re-applied every 2 s on checkpoints not reached yet
      cpSplash = 36005, cpExplosion = false,              -- Water Splash on credit, no 992661 explosion
      suitAura = 256054,                                  -- Visual: Water Bubble round the diving suit (and on bots)
      decor = { { 0, 5220.2, -4148.0, 9.95, 1.0, display = 410327 },  -- v1.4i (Rowan 18:17): jinyu water whirlpool MODEL under Azshara
                                                  -- (models scale, aura visuals don't: 255817 stayed small at 1.5/4/12; one big or none)
                { 256053, 5268.99, -4148.88, 10.88 } },    -- v1.4f (Rowan 18:10): glow in the fountain basin = 'start here' guide -- Visual: Water Zone on the floor under Azshara's pedestal (5th = size, Rowan 17:37: a bit bigger)
    },
  },
  { key = "darkiron",  name = "Blackrock",     portal = 99647, lit = 137900, x = 5768.7,    y = -4729.0,   ach = 90165,
    -- v1.9 (2026-11-16, Claude, unattended): spots READ FROM THE MAP MODELS, not walked: tent WMO ..._PARKOUR_07 at 4922.257 -4148.495 (ADT placement) + its doodads' collision,
    -- ray cast straight down at the client map markers (method checked on Emerald: Rowan's 4 .gps heights matched within 0.01 yd).
    -- PROVEN 2026-11-18 18:26 (Rowan: 'all good' after testing the last four): in the random pick now (v1.9b).
    arrive = { 4995.654, -4157.083, 9.69, 3.025 },
    spring = { 4984.73, -4155.80, 10.25 },                -- client start marker: bare floor on the raised rim (a table and a chest stand 6 yd in), marked with a fire ring
    springName = "fire ring", springR = 3.5,
    safeR = 26.0,                                         -- arrival -> ring 11 yd, -> return portal 22 yd
    floor = 9.95,
    checkpoints = {                                       -- four big Iron Horde train wheels float at the compass points, all with their tops at z 32.5
      { 4921.76, -4200.52, 32.55 },                       -- 1 wheel, south
      { 4870.30, -4148.61, 32.55 },                       -- 2 wheel, west
      { 4921.49, -4096.62, 32.55 },                       -- 3 wheel, north
    },
    goal = { 4974.36, -4148.48, 32.55 },                  -- the east wheel, above the start
    back = { 5000.15, -4135.36, 9.69, 3.309 },
    fx = { decor = { { 992872, 4984.73, -4155.80, 10.25 } } },  -- Fire Ring Event Visual on the suit-up spot (same one as Volcanic)
  },
  { key = "zandalari", name = "Troll",         portal = 99648, lit = 137901, x = 5742.5,    y = -4738.9,   ach = 90167,
    -- v1.9 (2026-11-16, Claude, unattended): spots READ FROM THE MAP MODELS, not walked: tent WMO ..._PARKOUR_08 at 5218.138 -3851.638 (ADT placement) + its doodads' collision,
    -- ray cast straight down at the client map markers (method checked on Emerald: Rowan's 4 .gps heights matched within 0.01 yd).
    -- PROVEN 2026-11-18 18:26 (Rowan: 'all good' after testing the last four): in the random pick now (v1.9b).
    arrive = { 5297.878, -3849.126, 9.69, 3.173 },
    spring = { 5286.88, -3849.47, 10.68 },                -- the Zandalari bed under the client start marker (a bed, as on Kul Tiras)
    springName = "bed", springR = 3.0,
    safeR = 21.0,                                         -- arrival -> bed 11 yd, -> return portal 17 yd
    floor = 9.95,
    checkpoints = {                                       -- each one is a square Zandalari lift platform (elevator01) with a gong beside it
      { 5217.92, -3803.21, 21.91 },                       -- 1 platform, north
      { 5169.57, -3850.07, 31.57 },                       -- 2 platform, west, by the tiger loa statue's head
      { 5217.92, -3900.66, 21.91 },                       -- 3 platform, south
    },
    goal = { 5254.43, -3870.79, 27.96 },                  -- platform + gong, south-east, towards the start
    back = { 5297.19, -3832.57, 9.69, 3.378 },
  },
  { key = "legion",    name = "Demonic",       portal = 99649, lit = 137902, x = 5716.0,    y = -4730.4,   ach = 90169,
    -- v1.9 (2026-11-16, Claude, unattended): spots READ FROM THE MAP MODELS, not walked: tent WMO ..._PARKOUR_09 at 4922.257 -3852.640 (ADT placement) + its doodads' collision,
    -- ray cast straight down at the client map markers (method checked on Emerald: Rowan's 4 .gps heights matched within 0.01 yd).
    -- PROVEN 2026-11-18 18:26 (Rowan: 'all good' after testing the last four): in the random pick now (v1.9b).
    arrive = { 4993.567, -3835.949, 9.69, 3.372 },
    spring = { 4982.86, -3838.46, 10.24 },                -- client start marker: bare floor on the raised rim by a Legion barricade, marked with a fire ring
    springName = "fire ring", springR = 3.5,
    safeR = 18.0,                                         -- arrival -> ring 11 yd, -> return portal 8 yd
    floor = 9.95,
    checkpoints = {                                       -- each one is a round Warden lift platform (warden_elevator01)
      { 4921.59, -3901.93, 21.19 },                       -- 1 platform, south
      { 4870.91, -3851.84, 30.80 },                       -- 2 platform, west
      { 4921.61, -3801.15, 32.50 },                       -- 3 platform, north
    },
    goal = { 4921.38, -3852.71, 32.84 },                  -- the large Legion platform floating over the dead centre of the tent
    back = { 4998.80, -3830.62, 9.69, 3.422 },
    fx = { decor = { { 992872, 4982.86, -3838.46, 10.24 } } },
  },
}
local E = { BELLE = 371937, BELLE_LOBBY = 99640, CHECKPOINT = 99592, GOAL = 99593, PORTAL = 99652, CREDIT = 379180, SUIT = 99529 }
local S = { RIDE = 46598, RETURN = 255753, READY = 257210, LIGHT = 255816, DOOR = 255827, OPEN = 255823, CP_AURA = 255816, CP_REACHED = 992661 }
-- v1.11 (Rowan 18:28-18:43): each lobby portal has its OWN theme, and it only plays once that course is picked. v1.10 put CoA's 'Visual: X
-- Zone' auras on the portal: nothing showed on Mechagnome or Titan (those look like the other mini-games' hazard zones), so they are gone.
-- v1.11 uses the LIVE theme pieces from the creature cache instead: 'Parkour Mechagon: Ligth / Oil / sparks', 'Parkour Emerald: Center /
-- Visual Music / Particles', 'Parkour Naga: Waterfall / Bublles', 'Parkour Iron: Fire / Smoke', 'Parkour Zandalari: Souls01-05',
-- 'Parkour Legion: Fel01', 'Parkour Fire: Volcan / Smoke' (seen only by players whose round picked that course = matches 'only when
-- selected'). Spawned as script markers on the portal spot, shown with the live piece's model (disp) or as an invisible marker
-- carrying a visual (aura) or casting one (cast). Spots: on the portal for now; Rowan judges and we move pieces as needed.
-- No pieces exist in any cache for Kul Tiras or Titan.
-- v1.12 (Rowan 18:51): '.aura 255820 is correct' (Emerald zone, worn by Rowan by the statue = the live look) and the Emerald plant must be
-- BIGGER like live. The zone auras showed nothing on the portal creature itself (v1.10), so now an invisible marker on the portal wears
-- them; the same for the other courses (best match by name, Rowan judges each). scale = model size.
-- v1.12b (Rowan 18:58: 'Needs to be in the center' + plant bigger): THEME_AT = the theme's centre per course (Rowan's .gps), else the portal.
-- Emerald = Rowan's 3 .gps 19:02-19:05 (head + both sides of the statue on the floor; 0.7 yd apart, averaged), floor z 9.946. The other eight
-- are CALCULATED: the 9 portals sit 40 degrees apart round the lobby centre (5742.694 -4697.796, the lobby WMO), so each statue = Emerald's
-- statue turned by 40 degrees (r 48.51 from the centre). Rowan checks each; a .gps on its head replaces a calculated line.
local THEME_AT = {
  emerald    = { 5782.528, -4670.107, 9.947 },   -- Rowan
  naga       = { 5793.7627, -4705.7236, 9.947 },  -- Rowan .gps 19:28 on top of the fountain = whirlpool centre; lobby floor z
  darkiron   = { 5776.879, -4732.217, 9.947 },   -- calculated (Rowan 19:31: fine)
  zandalari  = { 5742.4683, -4754.3184, 9.947 }, -- Rowan .gps 19:30 on top of the statue (centre); lobby floor z
  legion     = { 5716.2173, -4730.1553, 10.575 }, -- Rowan .gps 19:16: centre of the fel pad (pad top z 10.57)
  kultiran   = { 5692.0923, -4705.4277, 9.947 },  -- Rowan .gps 19:19 on top of the statue (centre), lobby floor z
  mechagnome = { 5698.798, -4677.144, 9.947 },   -- calculated
  titan      = { 5727.038, -4654.556, 9.947 },   -- Rowan .gps 19:25 (chair seat x,y); floor z: 255818 is a ring at the feet (Evoker Past Self aura x5 + beacon burst), like Emerald
  volcanic   = { 5755.410, -4650.981, 9.947 },   -- calculated (Rowan 19:31: fine)
}
local THEME = {
  mechagnome = { { aura = 255821 }, { disp = 135284 }, { disp = 135151 },
                 { aura = 257606, at = { 5707.2114, -4677.429, 10.823 } } },  -- Fuse zone, Mechagon lightning, oil, 'Visual: Sparks'
                                                     -- v1.13c (Rowan .gps 19:22 'sparks need to be where I am standing'): sparks on the portal pad top
  volcanic   = { { aura = 255819 }, { aura = 255824 }, { disp = 135289 }, { cast = 255754 } },   -- Magma zone, eruption sound, oily smoke, Volcan Eruption
  emerald    = { { aura = 255820 }, { aura = 255825 }, { disp = 133710, scale = 4 }, { disp = 133498, scale = 6, freezeAt = 2000 }, { disp = 133510 } },
                                                     -- Emerald zone (Rowan: correct), nature sound, the ring + plant 3x bigger, Dream mist
  naga       = { { aura = 255817 }, { disp = 135377 }, { disp = 130686 } },                    -- Water zone, water wall, bubble vortex
  darkiron   = { { aura = 255819 }, { disp = 135252 }, { disp = 129823 } },                    -- Magma zone, lava splash, dark smoke
  zandalari  = { { disp = 135974 }, { disp = 136320 }, { disp = 135972 }, { disp = 136326 } }, -- soul spiral, soul river, soul hand, anima
  legion     = { { aura = 255815 }, { disp = 126863 } },                                       -- Fel zone, fel pillar
  kultiran   = { { aura = 255817 } },                                                          -- Water zone (no live pieces cached)
  titan      = { { aura = 255818 } },                                                          -- Statue Coliseum (no live pieces cached)
}
local ACH = { JUMPS = 90173, ADEPT = 90174, VETERAN = 90175, EXPERT = 90176, MASTER = 90177, WINNER = 90198 }
local ITEM_TICKET = 558530
local INVISIBLE_DISPLAY = 11686                            -- stock invisible trigger model (for decor auras)
-- the suit LOOK (Rowan 13:18: on live you climb as a gnome in the suit). Default = live suit vehicle 99529's display 6981
-- (gnome male in the suit outfit). Own one of Belle's shop suits (its transform spell) -> you climb in that one (Parkourman model).
local SUIT_DEFAULT = 137643   -- Rowan 13:42: the 1940s diver suit = Parkourman display 137643 (live vehicle display 6981 was a plain gnome)
local SUIT_SHOP = { { 364382, 137643 }, { 364753, 137644 }, { 364754, 137645 }, { 364755, 137646 }, { 364756, 137647 } }  -- Pioneer, Solar, Vanguard, Sentinel, Prime (Prime's display = guess)
local Q_BASE, Q_DAILY = 1650231, 1650270
local TEXT_GREET, TEXT_MORE, TEXT_TIPS, TEXT_LOBBY = 1200155, 1200156, 1200157, 9997230
local TEMPSUMMON_TIMED_DESPAWN = 3
local LIFE = 4 * 3600 * 1000
-- =========================================================

local Games = {}          -- [instanceId] = session
local TestMode = {}       -- v1.4k: [playerLow] = true while '#va test' is on (GM only)
local Pending = {}        -- [starterLow] = session waiting for its starter to arrive

local function log(msg) print("[VertAscent] " .. msg) end
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
local function mmss(sec) sec = math.max(0, math.floor(sec)); return string.format("%d:%02d", math.floor(sec / 60), sec % 60) end
local function dist2(ax, ay, bx, by) local dx, dy = ax - bx, ay - by; return math.sqrt(dx * dx + dy * dy) end
local function courseByKey(k) for i, c in ipairs(COURSES) do if c.key == k then return c, i end end end
-- v1.9: a checkpoint/goal may list other heights ('alt') where the map model also has a flat surface under the marker.
-- Returns the height that was touched (the main one or an alt), or nil.
local function hitZ(p, z)
  if math.abs(z - p[3]) <= VA.CP_DZ then return p[3] end
  for _, a in ipairs(p.alt or {}) do if math.abs(z - a) <= VA.CP_DZ then return a end end
  return nil
end
local function built() local t = {}; for i, c in ipairs(COURSES) do if c.arrive and c.checkpoints and c.goal and not c.draft and not c.unproven then t[#t + 1] = i end end; return t end

local function getPlayer(g, low)
  local m = g.members[low]
  if not m then return nil end
  local pl = GetPlayerByGUID(m.guid)
  if pl and pl:IsInWorld() then return pl end
  return nil
end
local function inGame(g, pl) return pl and pl:GetMapId() == VA.MAP and pl:GetInstanceId() == g.inst end
local function getMap(g)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then return pl:GetMap(), pl end
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
local VAT = "|cffffd200Vertical Ascent:|r "
local AZT = "|cffff8000Azzar Event:|r "
local function belleSay(g, msg) local b = getObj(g, g.belleGuid); if b then b:SendUnitSay(msg, 0) end end

local function spawnFixed(g, entry, x, y, z, o)
  local _, anchor = getMap(g)
  if not anchor then return nil end
  local c = anchor:SpawnCreature(entry, x, y, z, o or 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if c then g.fixed[#g.fixed + 1] = c:GetGUID() end
  return c
end
local function spawnPortalGO(g, x, y, z, o)            -- the Faire portal model (creature 99652, display 137860); v1.1: was a GO showing only sparkles
  local c = spawnFixed(g, E.PORTAL, x, y, z, o)
  if c then try(c, "SetNPCFlags", 1) end                   -- v1.3h: click it (gear cursor comes from the DB IconName 'Interact')
  return c
end
local function despawn(g, guid)
  local o = getObj(g, guid)
  if not o then return end
  if o.DespawnOrUnsummon then pcall(o.DespawnOrUnsummon, o, 0) elseif o.RemoveFromWorld then pcall(o.RemoveFromWorld, o, false) end
end

local function clearLeftovers(g)
  local _, anchor = getMap(g)
  if not anchor then return end
  local n = 0
  for _, entry in ipairs({ E.BELLE_LOBBY, E.CHECKPOINT, E.GOAL, E.PORTAL, E.SUIT, 99641, 99642, 99643, 99644, 99645, 99646, 99647, 99648, 99649 }) do
    for _, c in ipairs(try(anchor, "GetCreaturesInRange", 400, entry) or {}) do c:DespawnOrUnsummon(0); n = n + 1 end
  end
  if n > 0 then log("cleared " .. n .. " leftover creatures") end
end

-- -------- the lobby --------
local function buildLobby(g)
  clearLeftovers(g)
  local b = VA.BELLE
  local belle = spawnFixed(g, E.BELLE_LOBBY, b[1], b[2], b[3], b[4])
  if belle then
    g.belleGuid = belle:GetGUID()
    try(belle, "Mount", VA.BELLE_MOUNT)                   -- v1.3o (Rowan 15:00): Belle rides the Faire's Gizmo mech (live robot 650753 not in the client)
  end
  g.portals = {}
  local cx, cy = 5742.7, -4697.8                           -- lobby centre (WMO origin)
  for i, c in ipairs(COURSES) do
    local atan2 = math.atan2 or math.atan                  -- Lua 5.3+ has no math.atan2
    local p = spawnFixed(g, c.portal, c.x, c.y, VA.PORTAL_Z, atan2(cy - c.y, cx - c.x))
    if p then g.portals[i] = p:GetGUID() end
  end
  local e = VA.EXIT_PORTAL
  spawnPortalGO(g, e[1], e[2], e[3], e[4])
end

local function portalUnit(g, i) return getObj(g, g.portals and g.portals[i]) end
local function lightPortal(g, i, on)
  local p = portalUnit(g, i)
  if not p then return end
  if on then try(p, "AddAura", S.LIGHT, p) else try(p, "RemoveAura", S.LIGHT) end
end
local function spawnTheme(g, i, store)                     -- v1.13: one course's theme pieces at its statue (used by the pick and by '#va themes')
  local c = COURSES[i]
  for _, t in ipairs(THEME[c.key] or {}) do
    local at = t.at or THEME_AT[c.key] or { c.x, c.y, VA.PORTAL_Z }   -- v1.13c: a piece can have its own spot (t.at)
    local m = spawnFixed(g, E.CHECKPOINT, at[1], at[2], at[3] + (t.dz or 0), 0)
    if m then
      try(m, "SetDisplayId", t.disp or INVISIBLE_DISPLAY)
      if t.scale then try(m, "SetScale", t.scale) end
      if t.freezeAt then                                   -- v1.12e (Rowan 19:07): the live bloom opens once and STAYS open: freeze it
        try(m, "RegisterEvent", function(_, _, _, o) pcall(function() o:AddAura(16245, o) end) end, t.freezeAt, 1)   -- 16245 Freeze Anim
      end
      if t.aura then try(m, "AddAura", t.aura, m) end
      if t.cast then try(m, "CastSpell", m, t.cast, true) end
      store[#store + 1] = m:GetGUID()
    end
  end
end
local function openPortal(g, i)
  local p = portalUnit(g, i)
  if not p then return end
  try(p, "SetDisplayId", COURSES[i].lit)                   -- the other portal look (portalN.m2 instead of portalNB.m2)
  try(p, "AddAura", S.LIGHT, p)                          -- v1.12a (Rowan 18:55 'remove that other effect'): no Parkour door (255827) any more:
  try(p, "CastSpell", p, S.OPEN, true)                   -- the lamp-post frame with blue beams round the portal is not on live
  g.themeGuids = g.themeGuids or {}                       -- v1.11: the course's own theme pieces at its statue
  spawnTheme(g, i, g.themeGuids)
  log(string.format("%s: %d theme pieces at its statue", COURSES[i].key, #g.themeGuids))
end
local function closePortal(g, i)
  local p = portalUnit(g, i)
  if not p then return end
  try(p, "RemoveAura", S.LIGHT); try(p, "RemoveAura", S.DOOR)
  for _, guid in ipairs(g.themeGuids or {}) do despawn(g, guid) end; g.themeGuids = nil   -- v1.11
  try(p, "SetDisplayId", 137902 + i)                       -- back to portalNB (137903 + i - 1)
end

local function setReady(g, low, on)
  local m = g.members[low]
  if not m then return end
  m.ready = on
  local pl = getPlayer(g, low)
  if pl then if on then try(pl, "AddAura", S.READY, pl) else try(pl, "RemoveAura", S.READY) end end
end

-- -------- the course --------
local function clearCourseLeftovers(g)                    -- v1.3l (Rowan 14:35): suits/heads/goal/portals left on the course by a wiped session
  local c = g.course
  local anchor
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if m.inCourse and inGame(g, pl) then anchor = pl; break end
  end
  if not anchor then return end
  -- v1.3n: runs 3 s into the round from the tick (at round start the server still had the player in the lobby, 800 yd away,
  -- so the search missed the old suit on head 1, Rowan 14:40); this round's own pieces are kept
  local mine = {}
  for _, guid in ipairs(g.fixed) do local o = getObj(g, guid); if o then mine[o:GetGUIDLow()] = true end end
  local n = 0
  local entries = { E.SUIT, E.CHECKPOINT, E.GOAL, E.PORTAL }
  local L = c.life                                            -- v1.8: a wiped session's parrots and pirates too
  if L then
    if L.parrots then entries[#entries + 1] = L.parrots.entry end
    for _, d in ipairs(L.duels or {}) do entries[#entries + 1] = d.a; entries[#entries + 1] = d.b; if d.mage then entries[#entries + 1] = d.mage end end
  end
  for _, entry in ipairs(entries) do
    for _, u in ipairs(try(anchor, "GetCreaturesInRange", 200, entry) or {}) do
      local key = u:GetGUIDLow()
      if not mine[key] and not g.suitOwner[key] then u:DespawnOrUnsummon(0); n = n + 1 end
    end
  end
  if n > 0 then log("cleared " .. n .. " leftover course creatures") end
end
-- ---- v1.8 course life: parrots circling + pirate duels (all friendly, not selectable, spawned per round) ----
local LIFE_FLAGS = 0x02000302                              -- NOT_SELECTABLE + NON_ATTACKABLE + IMMUNE_TO_PC + IMMUNE_TO_NPC
local function calm(u) try(u, "SetFaction", 35); try(u, "SetUnitFlags", LIFE_FLAGS); try(u, "SetReactState", 0) end
local function spawnLife(g)
  local L = g.course.life
  g.parrots, g.duelists = {}, {}
  if not L then return end
  local P = L.parrots
  for _, disp in ipairs((P and P.displays) or {}) do
    local a, r = math.random() * 2 * math.pi, P.rMin + math.random() * (P.rMax - P.rMin)
    local z = P.zMin + math.random() * (P.zMax - P.zMin)
    local u = spawnFixed(g, P.entry, P.cx + r * math.cos(a), P.cy + r * math.sin(a), z, 0)
    if u then
      try(u, "SetDisplayId", disp); calm(u)
      try(u, "SetCanFly", true); try(u, "SetDisableGravity", true)
      g.parrots[#g.parrots + 1] = { guid = u:GetGUID(), a = a, r = r, z = z, dir = (math.random() < 0.5) and 1 or -1, step = 0.25 + math.random() * 0.2 }
    end
  end
  for _, d in ipairs(L.duels or {}) do
    local ax, ay = d[1] + 1.4 * math.cos(d[4]), d[2] + 1.4 * math.sin(d[4])
    local bx, by = d[1] - 1.4 * math.cos(d[4]), d[2] - 1.4 * math.sin(d[4])
    local A = spawnFixed(g, d.a, ax, ay, d[3], d[4] + math.pi)
    local B = spawnFixed(g, d.b, bx, by, d[3], d[4])
    for _, u in ipairs({ A, B }) do
      if u then calm(u); try(u, "SetRooted", true); try(u, "SetSheath", 1); try(u, "EmoteState", 333); g.duelists[#g.duelists + 1] = u:GetGUID() end
    end
    if d.mage then
      local mx, my = d[1] + 6 * math.cos(d[4] + 1.2), d[2] + 6 * math.sin(d[4] + 1.2)
      local M = spawnFixed(g, d.mage, mx, my, d[3], math.atan2(d[2] - my, d[1] - mx))
      if M then calm(M); try(M, "SetRooted", true); g.mageGuid = M:GetGUID() end
    end
  end
  g.guns = {}
  for _, gpos in ipairs((L.cannons and L.cannons.guns) or {}) do
    local u = spawnFixed(g, E.CHECKPOINT, gpos[1], gpos[2], gpos[3], gpos[4])
    if u then try(u, "SetDisplayId", L.cannons.display); try(u, "SetFacing", gpos[4]); g.guns[#g.guns + 1] = { guid = u:GetGUID(), p = gpos } end   -- v1.8d: no calm() (it may block self-casts)
  end
  log(string.format("%s: life %d parrots, %d duellists, %d cannons", g.course.key, #g.parrots, #g.duelists, #g.guns))
end
local DUEL_EMOTES = { 36, 36, 36, 54, 60, 43 }               -- attack 1H x3, special attack, kick, parry
local function tickLife(g, t)
  if not g.parrots then return end
  if t >= (g.nextParrot or 0) then
    g.nextParrot = t + 1500
    local P = g.course.life.parrots
    for _, b in ipairs(g.parrots) do
      local u = getObj(g, b.guid)
      if u then
        b.a = b.a + b.dir * b.step
        local z = b.z + 2 * math.sin(b.a * 3)                  -- a gentle bob
        try(u, "MoveTo", 0, P.cx + b.r * math.cos(b.a), P.cy + b.r * math.sin(b.a), z, false)
      end
    end
  end
  if t >= (g.nextDuel or 0) then
    g.nextDuel = t + 900
    for _, guid in ipairs(g.duelists) do
      local u = getObj(g, guid)
      if u and math.random() < 0.55 then try(u, "PerformEmote", DUEL_EMOTES[math.random(1, #DUEL_EMOTES)]) end
    end
    local m = g.mageGuid and getObj(g, g.mageGuid)
    if m and math.random() < 0.35 then try(m, "PerformEmote", 51) end      -- spell cast
  end
  local C = g.course.life.cannons
  if C and #(g.guns or {}) > 0 and t >= (g.nextShot or 0) then
    g.nextShot = t + math.random(C.everyMin * 1000, C.everyMax * 1000)
    local gd = g.guns[math.random(1, #g.guns)]
    local gun = getObj(g, gd.guid)
    local _, anchor = getMap(g)
    if gun and anchor then
      local gp = gd.p
      local a = gp[4] + (math.random() * 2 - 1) * C.cone
      local dist = C.distMin + math.random() * (C.distMax - C.distMin)
      local tx, ty = gp[1] + dist * math.cos(a), gp[2] + dist * math.sin(a)
      local tz = (math.random() < 0.7) and C.floorZ or (C.floorZ + 6 + math.random() * 20)
      local mx, my, mz = gp[1] + 1.5 * math.cos(gp[4]), gp[2] + 1.5 * math.sin(gp[4]), gp[3] + 1.2
      try(gun, "CastSpell", gun, C.fuse, true)                      -- the fuse
      if (g.shotLogs or 0) < 6 then g.shotLogs = (g.shotLogs or 0) + 1; log(string.format("CANNON %.0f %.0f -> %.0f %.0f %.0f", gp[1], gp[2], tx, ty, tz)) end
      local map, gg = g.map, gun:GetGUID()
      CreateLuaEvent(function()
        local G = map:GetWorldObject(gg)
        if not G then return end
        try(G, "CastSpell", G, C.fire, true)                        -- the ball leaves the barrel
        local ball = G:SpawnCreature(C.carrier, mx, my, mz, gp[4], TEMPSUMMON_TIMED_DESPAWN, 6000)
        if not ball then log("CANNON: no ball spawned"); return end
        try(ball, "SetDisplayId", C.ball); calm(ball)
        try(ball, "MoveJump", tx, ty, tz, 30, 12)                    -- a real arc
        local bg = ball:GetGUID()
        local flight = math.floor(dist / 30 * 1000) + 300
        CreateLuaEvent(function()
          local B = map:GetWorldObject(bg)
          if not B then return end
          try(B, "CastSpell", B, C.impact, true)                     -- the impact, on the ball where it lands
          CreateLuaEvent(function() local B2 = map:GetWorldObject(bg); if B2 then B2:DespawnOrUnsummon(0) end end, 700, 1)
        end, flight, 1)
      end, 1500, 1)
    end
  end
end

local function buildCourse(g)
  g.cleanAt = now() + 3000                                  -- course leftovers are cleared 3 s in (tickGame)
  local c = g.course
  g.cpGuids = {}
  for i, p in ipairs(c.checkpoints or {}) do
    local u = spawnFixed(g, E.CHECKPOINT, p[1], p[2], p[3], 0)
    if u then g.cpGuids[i] = u:GetGUID() end
  end
  local u = c.goal and spawnFixed(g, E.GOAL, c.goal[1], c.goal[2], c.goal[3], 0)
  if u then g.goalGuid = u:GetGUID() end
  if c.goal and c.fx and c.fx.goalMarker then               -- v1.6c: a beacon on the goal (Volcanic: the checkpoint model is lost in the tower's glow)
    local gm = spawnFixed(g, E.CHECKPOINT, c.goal[1], c.goal[2], c.goal[3], 0)
    if gm then try(gm, "SetDisplayId", INVISIBLE_DISPLAY); try(gm, "AddAura", c.fx.goalMarker, gm) end
  end
  log(string.format("%s: goal %s at %.1f %.1f %.1f", c.key, u and "spawned" or "MISSING", (c.goal or {0,0,0})[1], (c.goal or {0,0,0})[2], (c.goal or {0,0,0})[3]))
  g.nextMarker = 0
  g.cpMarkGuids = {}
  if c.fx and c.fx.cpMarker then                             -- v1.4d: the marker sits on its own invisible dummy (the checkpoint model
    for i, p in ipairs(c.checkpoints) do                    -- doesn't show aura visuals: Rowan 18:06, Emerald vines missing)
      local mk = spawnFixed(g, E.CHECKPOINT, p[1], p[2], p[3], 0)
      if mk then try(mk, "SetDisplayId", INVISIBLE_DISPLAY); g.cpMarkGuids[i] = mk:GetGUID() end
    end
    log(string.format("%s: %d checkpoint markers (spell %d)", c.key, #g.cpMarkGuids, c.fx.cpMarker))
  end
  local spots = {}                                          -- v1.5: a decor entry can be one spot, a ring (ringOf/r) or random spots (count/rIn/rOut)
  for _, d in ipairs((c.fx and c.fx.decor) or {}) do
    if d.ringOf then
      for k = 0, d.ringOf - 1 do local a = 2 * math.pi * k / d.ringOf; spots[#spots + 1] = { d, d[2] + d.r * math.cos(a), d[3] + d.r * math.sin(a), d[4] + 0.03 * k, a } end
    elseif d.count then
      local lo, hi = d.rIn + (d.size or 0), d.rOut - (d.size or 0)
      for k = 1, d.count do local a, r = math.random() * 2 * math.pi, lo + math.random() * math.max(0, hi - lo); spots[#spots + 1] = { d, d[2] + r * math.cos(a), d[3] + r * math.sin(a), d[4] + 0.02 * k, math.random() * 2 * math.pi } end
    else spots[#spots + 1] = { d, d[2], d[3], d[4], 0 } end
  end
  for _, sp in ipairs(spots) do
    local d = sp[1]
    local dz = spawnFixed(g, E.CHECKPOINT, sp[2], sp[3], sp[4], sp[5])
    if dz then
      try(dz, "SetDisplayId", d.display or INVISIBLE_DISPLAY)  -- a model (d.display) or an invisible carrier for an aura
      if d[5] then try(dz, "SetScale", d[5]) end
      if d[1] and d[1] > 0 then try(dz, "AddAura", d[1], dz) end
    end
  end
  if c.back then spawnPortalGO(g, c.back[1], c.back[2], c.back[3], c.back[4]) end
  pcall(spawnLife, g)
end

-- ---- the suit (v1.3, Rowan 13:37: 'why not the vehicle bar now'): real players RIDE the live suit vehicle 99529
-- (gnome-in-suit look 6981, Vehicle 858: rider hidden + in control, no 'no jumping' flag), whose bar has Return to Checkpoint.
-- Bots can't drive a vehicle, so they only get the look. If boarding keeps failing, the player falls back to v1.2
-- (gnome look + the spell in the spellbook) so the run still works.
local function suitUnit(g, m) return m.suitGuid and getObj(g, m.suitGuid) end
local function inSuit(g, low)
  local m = g.members[low]
  local c = suitUnit(g, m)
  local kit = c and c:GetVehicleKit()
  local pas = kit and kit:GetPassenger(0)
  return pas and pas:GetGUIDLow() == low, c, kit
end
local function dropSuit(g, low, pl, tx, ty, tz)            -- out of the vehicle (a short teleport frees the client), old suit removed
  local m = g.members[low]
  local inside, c, kit = inSuit(g, low)
  if inside and kit then try(kit, "RemovePassenger", pl) end
  m.ourMoveUntil = now() + 1500
  if pl and (inside or tx) then pl:NearTeleport(tx or pl:GetX(), ty or pl:GetY(), (tz or pl:GetZ()) + 0.5, pl:GetO()) end
  if c then g.suitOwner[c:GetGUIDLow()] = nil; c:DespawnOrUnsummon(500) end
  m.suitGuid = nil
end
local function suitLook(pl)
  local look = SUIT_DEFAULT
  for _, sp in ipairs(SUIT_SHOP) do if pl:HasSpell(sp[1]) then look = sp[2]; break end end
  return look
end
local function board(g, low, pl)                           -- spawn a suit on the player and put them in it
  local m = g.members[low]
  local c = suitUnit(g, m)
  if not c then
    c = pl:SpawnCreature(E.SUIT, pl:GetX(), pl:GetY(), pl:GetZ() + 0.2, pl:GetO(), TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if not c then return false end
    m.suitGuid = c:GetGUID(); g.suitOwner[c:GetGUIDLow()] = low
    try(c, "SetDisplayId", suitLook(pl))                  -- always: the DB model may be stale (13:55 the DB had 6981)
    local fx = g.course and g.course.fx
    if fx and fx.suitAura then try(c, "AddAura", fx.suitAura, c) end   -- v1.4 Naga: the diving suit inside a water bubble
  end
  local kit = c:GetVehicleKit()
  if not kit then log("suit has no vehicle kit (VehicleId missing?)"); return false end
  pl:CastSpell(c, S.RIDE, true)
  if not kit:GetPassenger(0) then try(kit, "AddPassenger", pl, 0) end
  local pas = kit:GetPassenger(0)
  return pas and pas:GetGUIDLow() == low
end
local function fallbackSuit(g, low, pl)                    -- v1.2 way: the look + the spell in the spellbook
  local m = g.members[low]
  m.vehicle = false
  try(pl, "SetDisplayId", suitLook(pl))
  local fx = g.course and g.course.fx
  if fx and fx.suitAura then try(pl, "AddAura", fx.suitAura, pl) end
  m.hadReturn = pl:HasSpell(S.RETURN)
  if not m.hadReturn then try(pl, "LearnSpell", S.RETURN) end
  pl:SendBroadcastMessage(VAT .. "The suit vehicle didn't take: |cff00ff00Return to Checkpoint|r is in your spellbook (General tab) instead.")
  log(string.format("%s: could not board the suit, fallback to spell + look", m.name))
end

local function unsuit(g, low)
  local m = g.members[low]
  if not m or not m.suited then return end
  m.suited = false
  local pl = getPlayer(g, low)
  if m.vehicle then dropSuit(g, low, pl) end
  if pl then try(pl, "DeMorph") end
  local fx = g.course and g.course.fx
  if pl and fx and fx.suitAura then try(pl, "RemoveAura", fx.suitAura) end
  if pl and not m.bot and not m.vehicle and m.hadReturn == false then try(pl, "RemoveSpell", S.RETURN) end
  m.vehicle = nil; m.hadReturn = nil
end
local function suit(g, low, pl)
  local m = g.members[low]
  m.suited = true; m.suitedAt = now(); m.cp = 0
  local fx = g.course and g.course.fx
  if m.bot then
    try(pl, "SetDisplayId", suitLook(pl))
    if fx and fx.suitAura then try(pl, "AddAura", fx.suitAura, pl) end
  elseif not VA.USE_VEHICLE then
    m.vehicle = false
    try(pl, "SetDisplayId", suitLook(pl))
    m.hadReturn = pl:HasSpell(S.RETURN)
    if not m.hadReturn then try(pl, "LearnSpell", S.RETURN) end
    pl:SendBroadcastMessage(VAT .. "Suited up! |cff00ff00Return to Checkpoint|r is in your spellbook (General tab): put it on a bar. Climb!")
    pl:SendAreaTriggerMessage("Climb!")
  else
    m.vehicle = true; m.boardFails = 0
    if board(g, low, pl) then
      m.firstBoardMsg = true
      pl:SendBroadcastMessage(VAT .. "Suited up! |cff00ff00Return to Checkpoint|r is on your suit's bar. Climb!")
    else
      m.boardAt = now() + 700                             -- boarding often finishes a tick late: checked again in the tick
    end
    pl:SendAreaTriggerMessage("Climb!")
  end
  log(string.format("%s suited%s", m.name, m.bot and " (bot)" or ""))
end

local function respawnAt(g, low, pl)                       -- back to the last checkpoint (or the spring)
  local m = g.members[low]
  local c = g.course
  local p = (m.cp > 0) and c.checkpoints[m.cp] or c.spring
  if p.at then p = p.at end                                 -- v1.4: statue checkpoints respawn you beside her, not inside her
  m.ourMoveUntil = now() + 1500
  if m.vehicle then
    dropSuit(g, low, pl, p[1], p[2], p[3] + 0.5)          -- out of the suit, onto the checkpoint, a fresh suit in 1 s
    m.boardAt = now() + 1000; m.respawning = true
  else
    pl:NearTeleport(p[1], p[2], p[3] + 1.0, pl:GetO())
  end
end

local function hasAch(pl, id) return try(pl, "HasAchieved", id) == true end
local function giveAch(pl, id)
  if hasAch(pl, id) then return end
  if try(pl, "SetAchievement", id) == nil and not pl.SetAchievement then log("could not award achievement " .. id .. " (no SetAchievement in this ALE)") end
end

local PLACE = { "First", "Second", "Third", "Fourth", "Fifth" }
local function finish(g, low, pl, t)
  local m = g.members[low]
  m.finished = true; m.finishedAt = t
  g.finishedCount = g.finishedCount + 1
  local place = g.finishedCount
  tell(g, (PLACE[place] or ("#" .. place)) .. " place: " .. m.name, true)
  tell(g, VAT .. "Goal reached by: " .. m.name)
  local secs = math.floor((t - g.startedAt) / 1000)
  log(string.format("%s reached the goal (%s place, %s)%s", m.name, PLACE[place] or place, mmss(secs), m.bot and " (bot)" or ""))
  if m.bot then m.botLog.goalAt = secs; return end
  unsuit(g, low)
  -- rewards (live: 300 tickets, the course achievement, Jumps and Friends; Winner! for first place against others)
  try(pl, "AddItem", ITEM_TICKET, VA.TICKETS)
  giveAch(pl, g.course.ach)
  giveAch(pl, ACH.JUMPS)
  if place == 1 and g.count >= 2 then giveAch(pl, ACH.WINNER) end
  local done = 0
  for _, c in ipairs(COURSES) do if hasAch(pl, c.ach) then done = done + 1 end end
  if done >= 3 then giveAch(pl, ACH.ADEPT) end
  if done >= 6 then giveAch(pl, ACH.VETERAN) end
  if done >= 9 then giveAch(pl, ACH.EXPERT); giveAch(pl, ACH.MASTER) end
  if pl:HasQuest(Q_BASE) or pl:HasQuest(Q_DAILY) then pl:KilledMonsterCredit(E.CREDIT) end
end

local function later(guid, ms, fn)                         -- run fn(player) after ms, if the player is still around
  CreateLuaEvent(function() local p = GetPlayerByGUID(guid); if p and p:IsInWorld() then pcall(fn, p) end end, ms, 1)
end
local function sendToLobby(g, low)
  local pl = getPlayer(g, low)
  if not inGame(g, pl) then return end
  local m = g.members[low]
  local wasIn = m.vehicle and m.suited
  unsuit(g, low)
  local a = VA.LOBBY_ARRIVE
  local ang = (m.slot - 1) * (2 * math.pi / VA.MAX_PLAYERS)
  local x, y = a[1] + 2.0 * math.cos(ang), a[2] + 2.0 * math.sin(ang)
  m.ourMoveUntil = now() + 3000
  if wasIn then later(m.guid, 1500, function(p) p:NearTeleport(x, y, a[3] + 0.3, a[4]) end)
  else pl:NearTeleport(x, y, a[3] + 0.3, a[4]) end
end
local function sendHome(g, low)
  local pl = getPlayer(g, low)
  if not pl then return end
  local m = g.members[low]
  local wasIn = m.vehicle and m.suited
  unsuit(g, low)
  setReady(g, low, false)
  local h = m.home or VA.FAIRE_SPOT
  if wasIn then later(m.guid, 1500, function(p) p:Teleport(h[1], h[2], h[3], h[4], h[5]) end)
  else pl:Teleport(h[1], h[2], h[3], h[4], h[5]) end
end

-- bot run log (for the Squids report)
local function botLogLine(g, m)
  local b = m.botLog
  if not b then return end
  local cps = {}
  for i, s in ipairs(b.cpAt) do cps[#cps + 1] = i .. "@" .. mmss(s) end
  log(string.format("BOTRUN course=%s bot=%s class=%s level=%d suited=%s checkpoints=%d/%d [%s] goal=%s falls=%d maxZ=%.1f (floor %.1f, goal %.1f) still=%ds jumps=%d end=%s",
    g.course.key, m.name, tostring(m.class or "?"), m.level or 0, b.suitedAt and mmss(b.suitedAt) or "no", #b.cpAt, #(g.course.checkpoints or {}),
    table.concat(cps, " "), b.goalAt and mmss(b.goalAt) or "no", b.falls, b.maxZ, g.course.floor, (g.course.goal or { 0, 0, 0 })[3],
    math.floor(b.stillMs / 1000), b.jumps, b.endWhy or "?"))
end

-- -------- states --------
local ForceNext = nil                                       -- v1.4 GM test: "#va <course>" makes the next pick that course
local function startSelecting(g, t)
  if g.previewGuids then for _, guid in ipairs(g.previewGuids) do despawn(g, guid) end; g.previewGuids = nil end   -- v1.13: preview off once a pick starts
  g.state = "selecting"
  local list = built()
  g.pick = list[math.random(1, #list)]
  if ForceNext then
    local fc, fi = courseByKey(ForceNext)
    if fc and fc.arrive then g.pick = fi end
    ForceNext = nil
  end
  -- the light starts at a random portal, runs ROULETTE_LAPS laps and lands on the pick
  g.rStart = math.random(1, #COURSES)
  local toPick = (g.pick - g.rStart) % #COURSES
  g.rSteps = VA.ROULETTE_LAPS * #COURSES + toPick
  g.rStep = 0; g.rNext = t; g.rLit = nil
  tell(g, VAT .. "A random scenario is being selected...", true)
  log(string.format("instance %d: selecting (pick %s)", g.inst, COURSES[g.pick].key))
end

local function tickRoulette(g, t)
  if t < g.rNext then return end
  if g.rLit then lightPortal(g, g.rLit, false) end
  if g.rStep > g.rSteps then
    g.course = COURSES[g.pick]
    openPortal(g, g.pick)
    tell(g, VAT .. "Selected scenario: |cff00ccff" .. g.course.name .. "|r.", true)
    tell(g, VAT .. "Step into the glowing portal!", true)
    belleSay(g, "Off you go! Into the portal, and don't look down!")
    g.state = "portal"; g.portalUntil = t + VA.PORTAL_WAIT * 1000; g.rLit = nil
    return
  end
  local i = ((g.rStart - 1 + g.rStep) % #COURSES) + 1
  lightPortal(g, i, true); g.rLit = i
  local left = g.rSteps - g.rStep
  local slow = (left < 6) and (6 - left) * 120 or 0         -- slows down for the last few portals
  g.rNext = t + VA.ROULETTE_MS + slow
  g.rStep = g.rStep + 1
end

local function enterCourse(g, low, t)
  local pl = getPlayer(g, low)
  if not inGame(g, pl) then return end
  local m = g.members[low]
  local a = g.course.arrive
  local ang = (m.slot - 1) * 0.6
  m.inCourse = true; m.cp = 0; m.suited = false; m.finished = false; m.finishedAt = nil; m.arrivedAt = t
  m.climbed = false; m.falls = 0; m.walkedToSpring = false
  m.ourMoveUntil = t + 1500
  setReady(g, low, false)
  pl:NearTeleport(a[1] + 1.5 * math.cos(ang), a[2] + 1.5 * math.sin(ang), a[3] + 0.3, a[4])
  if m.bot then
    m.botLog = { cpAt = {}, falls = 0, maxZ = a[3], stillMs = 0, jumps = 0 }
    m.lastX, m.lastY, m.lastZ = nil, nil, nil
  end
end

local function startRun(g, t)
  g.state = "running"
  g.startedAt = t; g.endAt = t + VA.GAME_SECONDS * 1000; g.finishedCount = 0
  g.timer3 = false; g.timer2 = false; g.nextStatus = t + 60000
  closePortal(g, g.pick)
  buildCourse(g)
  g.round = g.round + 1
  tell(g, AZT .. "Round " .. g.round .. " is starting!", true)
  local sp = g.course.springName or "spring"
  tell(g, VAT .. "Jump into the " .. sp .. " to put on the suit. Reach the top before the clock runs out! (End of Game: " .. mmss(VA.GAME_SECONDS) .. ")")
  tell(g, "Jump into the " .. sp .. " to suit up!", true)    -- v1.4f: centre screen too
  log(string.format("instance %d: round %d started on %s with %d player(s)", g.inst, g.round, g.course.key, g.count))
end

local function endRun(g, why, t)
  if g.state ~= "running" then return end
  g.state = "over"; g.overUntil = t + VA.AFTER_GAME * 1000
  tell(g, VAT .. (why == "time" and "Time's up! End of game." or "Everyone reached the goal! End of game."), true)
  local list = {}
  for low, m in pairs(g.members) do if m.inCourse then list[#list + 1] = m end end
  table.sort(list, function(a, b) return (a.finishedAt or math.huge) < (b.finishedAt or math.huge) end)
  for i, m in ipairs(list) do
    if m.finishedAt then tell(g, string.format("#%d %s - %s", i, m.name, mmss((m.finishedAt - g.startedAt) / 1000)))
    else tell(g, string.format("-  %s - checkpoint %d/%d", m.name, m.cp or 0, #(g.course.checkpoints or {}))) end
  end
  tell(g, VAT .. "Back to the lobby in " .. VA.AFTER_GAME .. " seconds.")
  for low, m in pairs(g.members) do
    if m.bot and m.botLog then m.botLog.endWhy = why; botLogLine(g, m) end
  end
  log(string.format("instance %d: round %d over (%s), %d of %d at the goal", g.inst, g.round, why, g.finishedCount, #list))
end

local function backToLobby(g, t)
  for _, guid in ipairs(g.cpGuids or {}) do despawn(g, guid) end
  despawn(g, g.goalGuid)
  g.cpGuids = {}; g.goalGuid = nil
  for low, m in pairs(g.members) do
    if m.inCourse then sendToLobby(g, low) end
    m.inCourse = false; m.finished = false; m.finishedAt = nil; m.cp = 0; m.botLog = nil
    setReady(g, low, m.bot)
  end
  g.state = "lobby"; g.lobbySince = t; g.course = nil; g.pick = nil
  tell(g, VAT .. "Talk to Belle when you're ready for another round, or take the portal behind you back to the Faire.")
  belleSay(g, "Legs still shaking? Tell me when you're ready for another one!")
end

local function finalCleanup(g, why)
  for _, guid in ipairs(g.fixed) do despawn(g, guid) end
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then sendHome(g, low) end
  end
  Games[g.inst] = nil
  log("instance " .. tostring(g.inst) .. " cleaned up (" .. why .. ")")
end

local function humansHere(g)
  for low, m in pairs(g.members) do
    if not m.bot and inGame(g, getPlayer(g, low)) then return true end
  end
  return false
end

-- per member, every tick while running
-- v1.6 (Rowan 19:50/20:04): on a deathFalls course a fall kills you; 2.5 s later you're back at your last checkpoint, alive, in a fresh suit
local function lavaDeath(g, low, pl)
  local m = g.members[low]
  m.dying = true; m.ourMoveUntil = now() + 4000
  if m.vehicle then dropSuit(g, low, pl) end
  if not m.bot then pl:SendAreaTriggerMessage("You burned in the lava!") end
  tell(g, VAT .. m.name .. " fell into the lava!")
  try(pl, "KillPlayer")
  log(string.format("LAVA %s at %.1f %.1f %.1f (cp %d) dead=%s", m.name, pl:GetX(), pl:GetY(), pl:GetZ(), m.cp or 0, tostring(pl:IsDead())))
  local guid, inst = pl:GetGUID(), g.inst
  CreateLuaEvent(function()
    local p = GetPlayerByGUID(guid)
    local gg = Games[inst]
    local mm = gg and gg.members[low]
    if not p or not mm then return end
    if p:IsDead() then try(p, "ResurrectPlayer", 100, false) end
    mm.dying = nil
    if mm.inCourse and gg.state == "running" then respawnAt(gg, low, p) end
    if not mm.vehicle and mm.suited then try(p, "SetDisplayId", suitLook(p)) end   -- bots / fallback: the suit look again
  end, 2500, 1)
end

local function tickMember(g, low, m, t)
  local pl = getPlayer(g, low)
  if not inGame(g, pl) or not m.inCourse then return end
  local c = g.course
  local x, y, z = pl:GetX(), pl:GetY(), pl:GetZ()
  -- portal back to the lobby (leaves the run)
  if c.back and dist2(x, y, c.back[1], c.back[2]) <= VA.PORTAL_R and math.abs(z - c.back[3]) < 3 and not m.bot then
    tell(g, VAT .. m.name .. " left the course.")
    m.inCourse = false; unsuit(g, low); sendToLobby(g, low)
    return
  end
  if m.finished or c.draft or m.dying then return end                   -- v1.5: a draft course is look-only (no suit, falls or checkpoints)
  -- bot log: movement
  if m.bot and m.botLog then
    local b = m.botLog
    if z > b.maxZ then b.maxZ = z end
    if m.lastX then
      local d = math.sqrt((x - m.lastX) ^ 2 + (y - m.lastY) ^ 2 + (z - m.lastZ) ^ 2)
      if d < VA.BOT_STILL_YD then b.stillMs = b.stillMs + 500
      elseif d > VA.BOT_JUMP_YD and t > (m.ourMoveUntil or 0) then
        b.jumps = b.jumps + 1
        if b.jumps <= 5 then log(string.format("BOTJUMP %s moved %.0f yd in one tick to %.1f %.1f %.1f (not us: the bot AI teleported)", m.name, d, x, y, z)) end
      end
    end
    m.lastX, m.lastY, m.lastZ = x, y, z
  end
  -- v1.3k GM TEST MODE (Rowan 14:32): with .gm on, checkpoints + the goal count WITHOUT the suit (fly through them); no fall rule
  local gmTest = not m.bot and not m.suited and TestMode[low] == true   -- v1.4k: '#va test' switch (IsGM isn't in this ALE's method list)
  -- not suited yet: the spring
  if not m.suited and not gmTest then
    local inSpring = dist2(x, y, c.spring[1], c.spring[2]) <= (c.springR or VA.SPRING_R) and math.abs(z - c.spring[3]) <= VA.SPRING_DZ
    if inSpring then suit(g, low, pl); if m.botLog then m.botLog.suitedAt = math.floor((t - g.startedAt) / 1000) end
    elseif m.bot and t >= (m.arrivedAt or t) + VA.BOT_SPRING_WAIT * 1000 then
      m.ourMoveUntil = t + 1500
      pl:NearTeleport(c.spring[1], c.spring[2], c.spring[3] + 0.5, pl:GetO())
    elseif m.bot and not m.walkedToSpring then
      m.walkedToSpring = true
      try(pl, "MoveTo", 0, c.spring[1], c.spring[2], c.spring[3])
    end
    return
  end
  -- fell to the floor (away from the spring) = back to the last checkpoint
  -- (v1.3g, Rowan 14:05) the corner with the arrival point, the spring and the return portal is safe ground: you can walk to the portal
  local safe = dist2(x, y, c.arrive[1], c.arrive[2]) <= (c.safeR or VA.SAFE_R) or dist2(x, y, c.spring[1], c.spring[2]) <= (c.springR or VA.SPRING_R) + 2.5
  if m.suited and z < c.floor + (c.fallMargin or VA.FALL_MARGIN) and not safe and t > (m.ourMoveUntil or 0) and (m.cp > 0 or (m.climbed or false) or c.deathFalls) then   -- v1.6a: lava kills even before you've climbed
    if m.bot and m.botLog then m.botLog.falls = m.botLog.falls + 1 end
    m.falls = (m.falls or 0) + 1
    if c.deathFalls and not m.bot then lavaDeath(g, low, pl); return end    -- v1.6 Volcanic: burn, then back at the checkpoint
                                                          -- (bots just respawn: a dead playerbot releases its spirit and runs off)
    respawnAt(g, low, pl)
    if not m.bot then pl:SendAreaTriggerMessage(m.cp > 0 and ("Back to checkpoint " .. m.cp) or ("Back to the " .. (c.springName or "spring"))) end
    return
  end
  if z > c.floor + 6 then m.climbed = true end
  -- real players stay in the suit: re-board after a respawn, or if they used Leave Vehicle (live has no way out mid-run)
  if m.vehicle and t >= (m.boardAt or 0) and not inSuit(g, low) then
    if safe and not m.respawning and m.firstBoardMsg then
      -- v1.3j (Rowan 14:24): got out of the suit on the safe ground by the portal/spring = stay out; the spring suits you again
      unsuit(g, low); m.firstBoardMsg = nil
      pl:SendBroadcastMessage(VAT .. "Suit off. Jump into the " .. (c.springName or "spring") .. " to put it back on, or take the portal.")
      return
    end
    if board(g, low, pl) then
      m.respawning = nil
      if m.boardFails > 0 or m.firstBoardMsg == nil then pl:SendBroadcastMessage(VAT .. "Suited up! |cff00ff00Return to Checkpoint|r is on your suit's bar.") end
      m.firstBoardMsg = true; m.boardFails = 0
    else
      m.boardFails = m.boardFails + 1; m.boardAt = t + 1000
      if m.boardFails >= 5 then dropSuit(g, low, pl); fallbackSuit(g, low, pl) end
    end
  end
  -- next checkpoint (in order), then the goal
  local nxt = m.cp + 1
  local p = c.checkpoints[nxt]
  if p then
    local hz = dist2(x, y, p[1], p[2]) <= VA.CP_R and hitZ(p, z)
    if hz then
      m.cp = nxt
      if hz ~= p[3] then                                    -- v1.9: credited at an 'alt' height: respawn there, and say so in the log for Rowan/Claude
        p.at = { p[1], p[2], hz }
        log(string.format("%s: checkpoint %d credited at ALT height %.2f (main %.2f) by %s at %.2f %.2f %.2f", c.key, nxt, hz, p[3], m.name, x, y, z))
      end
      tell(g, VAT .. "Checkpoint reached by: " .. m.name)
      local fx = c.fx or {}
      if not m.bot then
        if fx.cpExplosion ~= false then try(pl, "CastSpell", pl, S.CP_REACHED, true) end
        if fx.cpSplash then try(pl, "CastSpell", pl, fx.cpSplash, true) end
        pl:SendAreaTriggerMessage("Checkpoint " .. nxt .. "/" .. #c.checkpoints)
      end
      local u = getObj(g, g.cpGuids[nxt])
      if u and not u:HasAura(S.CP_AURA) then
        local mk = g.cpMarkGuids and getObj(g, g.cpMarkGuids[nxt])
        if mk then g.cpMarkGuids[nxt] = nil; despawn(g, mk:GetGUID()) end   -- v1.4d: the marker goes, the beam takes over
        try(u, "AddAura", S.CP_AURA, u)
      end
      if m.botLog then m.botLog.cpAt[#m.botLog.cpAt + 1] = math.floor((t - g.startedAt) / 1000) end
    end
  else
    local gp = c.goal
    local hz = dist2(x, y, gp[1], gp[2]) <= VA.CP_R and hitZ(gp, z)
    if hz then
      if hz ~= gp[3] then log(string.format("%s: goal credited at ALT height %.2f (main %.2f) by %s at %.2f %.2f %.2f", c.key, hz, gp[3], m.name, x, y, z)) end
      finish(g, low, pl, t)
    end
  end
end

local function tickGame(g, t)
  g.map = select(1, getMap(g))
  if not g.map then log("nobody left in instance " .. tostring(g.inst) .. ", session dropped"); Games[g.inst] = nil; return end
  if not humansHere(g) and t > (g.created + 60000) then finalCleanup(g, "no players left"); return end
  if g.state == "lobby" or g.state == "portal" or g.state == "selecting" then
    -- the portal back to the Faire (any time in the lobby)
    local e = VA.EXIT_PORTAL
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) and not m.bot and not m.inCourse and dist2(pl:GetX(), pl:GetY(), e[1], e[2]) <= VA.PORTAL_R and math.abs(pl:GetZ() - e[3]) < 3 then
        tell(g, VAT .. m.name .. " went back to the Faire.")
        sendHome(g, low)
        g.members[low] = nil; g.count = math.max(0, g.count - 1)
      end
    end
  end
  if g.state == "lobby" then
    local all, any = true, false
    for low, m in pairs(g.members) do
      if not m.bot and inGame(g, getPlayer(g, low)) then any = true; if not m.ready then all = false end end
      if m.ready and t >= (m.readyAura or 0) then m.readyAura = t + 30000; local pl = getPlayer(g, low); if pl then try(pl, "AddAura", S.READY, pl) end end
    end
    if any and all then startSelecting(g, t)
    elseif t >= (g.lobbySince or t) + VA.LOBBY_IDLE * 1000 then finalCleanup(g, "nobody readied up in " .. VA.LOBBY_IDLE .. " s") end
  elseif g.state == "selecting" then
    tickRoulette(g, t)
  elseif g.state == "portal" then
    local c = g.course
    local anyIn, humanIn = false, false
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) and not m.inCourse and not m.bot then
        if dist2(pl:GetX(), pl:GetY(), c.x, c.y) <= VA.PORTAL_R + 0.5 then enterCourse(g, low, t) end
      end
      if m.inCourse then anyIn = true; if not m.bot then humanIn = true end end
    end
    if humanIn then                                       -- bots follow the first real player in
      for low, m in pairs(g.members) do if m.bot and not m.inCourse then enterCourse(g, low, t) end end
    end
    local waiting = false
    for low, m in pairs(g.members) do if not m.bot and not m.inCourse and inGame(g, getPlayer(g, low)) then waiting = true end end
    if not waiting and anyIn then startRun(g, t)
    elseif t >= g.portalUntil then
      for low, m in pairs(g.members) do if not m.inCourse then enterCourse(g, low, t) end end
      startRun(g, t)
    end
  elseif g.state == "running" then
    if g.cleanAt and t >= g.cleanAt then g.cleanAt = nil; pcall(clearCourseLeftovers, g) end
    if g.course.life then local ok, err = pcall(tickLife, g, t); if not ok then log("life: " .. tostring(err)) end end
    local fx = g.course.fx
    if fx and fx.cpMarker and t >= (g.nextMarker or 0) then   -- v1.4: looping checkpoint marker (re-applied so the splash plays again)
      g.nextMarker = t + (fx.cpMarkerMs or 2000)
      for _, guid in pairs(g.cpMarkGuids or {}) do
        local u = getObj(g, guid)
        if u then
          if fx.cpMarkerMs then try(u, "RemoveAura", fx.cpMarker); try(u, "AddAura", fx.cpMarker, u)   -- looped (one-shot visual)
          elseif not u:HasAura(fx.cpMarker) then try(u, "AddAura", fx.cpMarker, u) end                 -- steady visual: once
        end
      end
    end
    for low, m in pairs(g.members) do
      local ok, err = pcall(tickMember, g, low, m, t)
      if not ok then log("error (member " .. tostring(m.name) .. "): " .. tostring(err)) end
    end
    local left = (g.endAt - t) / 1000
    if not g.timer3 and left <= 180 then g.timer3 = true; tell(g, "|cffff8000[TIMER]|r 3 minutes remaining!") end
    if not g.timer2 and left <= 120 then g.timer2 = true; tell(g, "|cffff8000[TIMER]|r 2 minutes remaining!") end
    if t >= g.nextStatus then g.nextStatus = t + 60000; tell(g, "End of Game: " .. mmss(left), true) end
    local racers, done = 0, 0
    for low, m in pairs(g.members) do if m.inCourse then racers = racers + 1; if m.finished then done = done + 1 end end end
    local humansLeftRacing = false
    for low, m in pairs(g.members) do if m.inCourse and not m.bot and not m.finished then humansLeftRacing = true end end
    if t >= g.endAt then endRun(g, "time", t)
    elseif racers > 0 and done == racers then endRun(g, "all finished", t)
    elseif racers > 0 and not humansLeftRacing and done > 0 and left > 60 then
      -- every real player is done: give the bots one more minute, then end (no point waiting 15 min for bots)
      g.endAt = math.min(g.endAt, t + 60000); tell(g, VAT .. "All players reached the goal. The game ends in 1 minute.")
    end
  elseif g.state == "over" then
    if t >= g.overUntil then backToLobby(g, t) end
  end
end

local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)
    if t > g.created + 90000 then
      Pending[sLow] = nil; log("start cancelled (starter did not arrive within 90 s)")
    elseif st and st:GetMapId() == VA.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then
        st:SendBroadcastMessage(VAT .. "A game is already running here.")
      else
        Games[g.inst] = g
        g.map = st:GetMap()
        buildLobby(g)
        g.state = "lobby"; g.lobbySince = t
        for low, m in pairs(g.members) do if m.bot then setReady(g, low, true) end end
        tell(g, VAT .. "Talk to Belle when you're ready to start.")
        belleSay(g, "Welcome to Vertical Ascent! Tell me when you're ready, and I'll pick your challenge!")
      end
    end
  end
end

-- the Faire portal also works with NO session (after .reload ale wiped the games, or a GM .go into the lobby), Rowan 13:58
local nextOrphan = 0
local function tickOrphans(t)
  if t < nextOrphan then return end
  nextOrphan = t + 1000
  if type(GetPlayersInWorld) ~= "function" then return end
  local e = VA.EXIT_PORTAL
  for _, pl in ipairs(GetPlayersInWorld() or {}) do
    if pl:GetMapId() == VA.MAP and not pl:IsBot() then
      local g = Games[pl:GetInstanceId()]
      -- v1.3m (Rowan 14:39): suits left behind when .reload ale wiped a game: remove the ones no running game owns
      for _, u in ipairs(try(pl, "GetCreaturesInRange", 150, E.SUIT) or {}) do
        if not (g and g.suitOwner and g.suitOwner[u:GetGUIDLow()]) then
          local kit = u:GetVehicleKit(); local pas = kit and kit:GetPassenger(0)
          if pas then try(kit, "RemovePassenger", pas); if pas.NearTeleport then pas:NearTeleport(pas:GetX(), pas:GetY(), pas:GetZ() + 0.5, pas:GetO()) end end
          u:DespawnOrUnsummon(0); log("removed an abandoned suit")
        end
      end
      if not (g and g.members[pl:GetGUIDLow()]) and dist2(pl:GetX(), pl:GetY(), e[1], e[2]) <= VA.PORTAL_R and math.abs(pl:GetZ() - e[3]) < 3 then
        try(pl, "DeMorph")
        local f = VA.FAIRE_SPOT
        pl:Teleport(f[1], f[2], f[3], f[4], f[5])
        log(pl:GetName() .. " took the Faire portal (no session)")
      end
    end
  end
end

CreateLuaEvent(function()
  local t = now()
  pcall(tickOrphans, t)
  local ok, err = pcall(tickPending, t)
  if not ok then log("error (pending): " .. tostring(err)) end
  for inst, g in pairs(Games) do
    local ok2, err2 = pcall(tickGame, g, t)
    if not ok2 then log("error (game " .. tostring(inst) .. "): " .. tostring(err2)) end
  end
end, 500, 0)

-- -------- Belle at the Faire: start a session --------
local function startSession(player, belle)
  local members, count = {}, 0
  local function add(p)
    if count >= VA.MAX_PLAYERS then return end
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), bot = p:IsBot(), name = p:GetName(), slot = count, ready = false, cp = 0,
                     class = p:GetClass(), level = p:GetLevel(),
                     home = { p:GetMapId(), p:GetX(), p:GetY(), p:GetZ(), p:GetO() } }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= VA.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  local g = { members = members, count = count, starter = player:GetGUIDLow(), created = now(), state = "arriving",
              fixed = {}, portals = {}, round = 0, finishedCount = 0, suitOwner = {} }
  Pending[player:GetGUIDLow()] = g
  local a = VA.LOBBY_ARRIVE
  for low, m in pairs(members) do
    local ang = (m.slot - 1) * (2 * math.pi / VA.MAX_PLAYERS)
    local p = GetPlayerByGUID(m.guid)
    if p then
      if not m.bot then p:SendBroadcastMessage(AZT .. "You have been invited to Parkour.") end
      p:Teleport(VA.MAP, a[1] + 2.0 * math.cos(ang), a[2] + 2.0 * math.sin(ang), a[3] + 0.3, a[4])
    end
  end
  log(string.format("%s starts Vertical Ascent with %d player(s)", player:GetName(), count))
  belle:SendUnitSay("Suit up, sweetie! The gravity gear is waiting inside.", 0)
end

local function faireMenu(player, creature)
  player:GossipClearMenu()
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Let's climb! (start Vertical Ascent with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about Vertical Ascent?", 0, 2)
  player:GossipMenuAddItem(0, "Do you have any tips for overcoming the scenarios?", 0, 5)
  player:GossipMenuAddItem(1, "I'd like to browse your goods.", 0, 3)
  player:GossipSendMenu(TEXT_GREET, creature)
end

RegisterCreatureGossipEvent(E.BELLE, 1, function(event, player, creature) faireMenu(player, creature) end)
RegisterCreatureGossipEvent(E.BELLE, 2, function(event, player, creature, sender, intid)
  if intid == 1 then
    player:GossipComplete()
    for _, g in pairs(Games) do
      if g.members[player:GetGUIDLow()] then player:SendBroadcastMessage(VAT .. "You are already in a game."); return end
    end
    startSession(player, creature)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_MORE, creature)
  elseif intid == 5 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_TIPS, creature)
  elseif intid == 3 then
    player:GossipComplete(); player:SendListInventory(creature)
  else
    faireMenu(player, creature)
  end
end)

-- -------- Belle in the lobby: ready check --------
local function gameOf(creature) return Games[creature:GetInstanceId()] end
local function lobbyMenu(player, creature)
  local g = gameOf(creature)
  local m = g and g.members[player:GetGUIDLow()]
  player:GossipClearMenu()
  if g and m and g.state == "lobby" and not m.ready then player:GossipMenuAddItem(9, "I'm ready!", 0, 10) end
  player:GossipMenuAddItem(0, "Do you have any tips for overcoming the scenarios?", 0, 11)
  player:GossipSendMenu(TEXT_LOBBY, creature)
end
RegisterCreatureGossipEvent(E.BELLE_LOBBY, 1, function(event, player, creature) lobbyMenu(player, creature) end)
RegisterCreatureGossipEvent(E.BELLE_LOBBY, 2, function(event, player, creature, sender, intid)
  local g = gameOf(creature)
  local m = g and g.members[player:GetGUIDLow()]
  if intid == 10 and m and g.state == "lobby" then
    player:GossipComplete()
    setReady(g, player:GetGUIDLow(), true)
    local n, of = 0, 0
    for low, mm in pairs(g.members) do if not mm.bot then of = of + 1; if mm.ready then n = n + 1 end end end
    if n < of then tell(g, VAT .. m.name .. " is ready (" .. n .. "/" .. of .. "). Every player must be ready before the round can start.") end
  elseif intid == 11 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 12); player:GossipSendMenu(TEXT_TIPS, creature)
  else
    lobbyMenu(player, creature)
  end
end)

-- -------- Return to Checkpoint (spell 255753: a dummy on live, the script does the teleport) --------
local function onReturn(caster)
  if not caster or caster:GetMapId() ~= VA.MAP then return end
  local g = Games[caster:GetInstanceId()]
  if not g then return end
  local low = caster:GetGUIDLow()
  if caster:GetEntry() == E.SUIT then low = g.suitOwner[low] end   -- pressed on the suit's bar: the suit casts it
  local m = low and g.members[low]
  if not (m and m.suited and g.state == "running") then return end
  local pl = getPlayer(g, low)
  if pl then respawnAt(g, low, pl) end
end
do
  local ok, err = pcall(RegisterSpellEvent, S.RETURN, 2, function(event, a, b)
    local function has(o, k) local ok2, f = pcall(function() return o[k] end); return ok2 and type(f) == "function" end
    local caster = a
    if a and has(a, "GetCaster") and not has(a, "GetMapId") then caster = a:GetCaster() end
    if b and has(b, "GetCaster") and not (caster and has(caster, "GetMapId")) then caster = b:GetCaster() end
    local ok3, err3 = pcall(onReturn, caster)
    if not ok3 then log("return-to-checkpoint error: " .. tostring(err3)) end
  end)   -- SPELL_EVENT_ON_CAST
  if not ok then log("RegisterSpellEvent(Return to Checkpoint) failed: " .. tostring(err)) end
end

-- -------- the portals are clickable too (v1.3h, Rowan 14:09: yellow gear, like any other portal) --------
local function usePortal(player, creature)
  if player:GetMapId() ~= VA.MAP then return end
  local g = Games[player:GetInstanceId()]
  local low = player:GetGUIDLow()
  local m = g and g.members[low]
  local e = VA.EXIT_PORTAL
  local nearExit = dist2(creature:GetX(), creature:GetY(), e[1], e[2]) < 5
  if nearExit then                                         -- lobby: back to the Faire
    if m then
      tell(g, VAT .. m.name .. " went back to the Faire.")
      sendHome(g, low); g.members[low] = nil; g.count = math.max(0, g.count - 1)
    else
      try(player, "DeMorph"); local f = VA.FAIRE_SPOT; player:Teleport(f[1], f[2], f[3], f[4], f[5])
    end
  elseif m and m.inCourse then                             -- course: back to the lobby (leaves the run)
    tell(g, VAT .. m.name .. " left the course.")
    m.inCourse = false; unsuit(g, low); sendToLobby(g, low)
  else
    try(player, "DeMorph"); local a = VA.LOBBY_ARRIVE; player:NearTeleport(a[1], a[2], a[3] + 0.3, a[4])
  end
end
RegisterCreatureGossipEvent(E.PORTAL, 1, function(event, player, creature)
  if creature:GetX() < -1000 then return end                -- 2026-11-14: the Rainbow Race uses this same portal creature on its track (x about -1500): that script answers it
  player:GossipComplete()
  local ok, err = pcall(usePortal, player, creature)
  if not ok then log("portal error: " .. tostring(err)) end
  return true
end)

-- safety hatch: say "#leave" on map 960 (not announced)
RegisterPlayerEvent(18, function(event, player, msg)
  if msg ~= "#leave" or player:GetMapId() ~= VA.MAP then return end
  local g = Games[player:GetInstanceId()]
  local m = g and g.members[player:GetGUIDLow()]
  if not m then return end
  sendHome(g, player:GetGUIDLow())
  g.members[player:GetGUIDLow()] = nil; g.count = math.max(0, g.count - 1)
  player:SendBroadcastMessage(VAT .. "Back to the Faire you go!")
  return false
end)

-- GM test (v1.4): "#va naga" / "#va emerald" = the next random pick lands on that course (GM only, not announced)
RegisterPlayerEvent(18, function(event, player, msg)
  local key = msg:match("^#va%s+(%a+)$")
  if not key or (player:GetGMRank() or 0) < 1 then return end
  if key:lower() == "test" then                              -- v1.4k: toggle test mode (checkpoints/goal count unsuited, flying, no fall rule)
    local low = player:GetGUIDLow()
    TestMode[low] = not TestMode[low] or nil
    player:SendBroadcastMessage(VAT .. (TestMode[low] and "TEST MODE ON: fly through the checkpoints and the goal (no suit, no falls). '#va test' again to turn it off."
                                                     or "Test mode OFF: normal play."))
    return false
  end
  if key:lower() == "themes" then                            -- v1.13 (Rowan 19:11 'run them all and i will check each one'): GM preview of all 9
    local g = Games[player:GetInstanceId()]                   -- portal themes at once in the lobby; '#va themes' again clears them
    if player:GetMapId() ~= VA.MAP or not g or g.state ~= "lobby" then
      player:SendBroadcastMessage(VAT .. "Use '#va themes' in the Vertical Ascent lobby before anyone readies."); return false
    end
    if g.previewGuids then
      for _, guid in ipairs(g.previewGuids) do despawn(g, guid) end
      g.previewGuids = nil
      player:SendBroadcastMessage(VAT .. "Theme preview OFF.")
    else
      g.previewGuids = {}
      for i = 1, #COURSES do spawnTheme(g, i, g.previewGuids) end
      player:SendBroadcastMessage(VAT .. "Theme preview ON: all 9 portals' themes are showing (" .. #g.previewGuids .. " pieces). '#va themes' again to clear.")
    end
    return false
  end
  local c = courseByKey(key:lower())
  if not c or not c.arrive then player:SendBroadcastMessage(VAT .. "No built course called '" .. key .. "'."); return false end
  ForceNext = c.key
  player:SendBroadcastMessage(VAT .. "Next pick: " .. c.name .. ".")
  return false
end)

log("script loaded v1.13d (theme zone auras + live pieces on the picked portal, no door frame) all 9 courses in the pick (emerald, naga, volcanic, kul tiras, mechagnome, titan, darkiron, zandalari, legion; #va <key> forces one) (Belle " .. E.BELLE .. ", lobby Belle " .. E.BELLE_LOBBY .. ", map " .. VA.MAP .. ", courses built: " .. #built() .. ")")
