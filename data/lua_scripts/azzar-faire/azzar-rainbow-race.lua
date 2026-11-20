-- azzar-rainbow-race.lua  v2.3.7  (Rowan/Claude 2026-11-14)
-- v2.3.7 (Fable, Rowan 21:50 + the v2.3.6 log): CAUSE FOUND. 18 'bot OUT of kart' lines in one lap: each time the bot was 73-183 yd from
--          its kart and 5-40 yd from Rowan, stunned or not = the playerbot 'follow' strategy TELEPORTS a bot to its master once it is
--          more than about 75 yd away (and steers its kart toward him when nearer). The stun does not stop that. So 'stay' (BOT_STAY,
--          written in v2.3 but off and never tried) is now ON: the player whispers 'stay' to the bots when the karts come out, again at
--          GO, and to any bot the watchdog finds out of its kart; 'follow' when the podium ends or a bot is sent home.
-- v2.3.6 (Fable, Rowan 21:42: 'still the slide show with EMPTY carts and the bots running on the track behind me'): the bots do not STAY
--          in their karts. They are seated on the grid (log) and are out again later, on foot, following him; the script went on driving
--          the empty karts. New watchdog seatBots(): once a second every bot racer is checked against seat 0 of its kart; one that is out
--          is logged ('bot OUT of kart': how long it sat, how far from its kart and from the nearest player, stunned or not) and put
--          back in. The log lines are there to find out WHAT takes them out. GM '#rr botseat' switches the putting-back off/on.
-- v2.3.5 (Fable, Rowan 21:33-21:36: two bots ran off in the lobby, the race 'still broken'): the bots' OWN AI is still awake. In the
--          lobby it walks them away; in a kart the playerbot 'follow the master' movement steers the VEHICLE (it clears the kart's
--          movement and sets its own), fighting the script's path many times a second = the slide show, worst while the bots are near
--          Rowan at the start. Now every bot racer carries the mini-game stun (255620, 8 s, renewed every 3 s) from the grid to the end:
--          a stunned bot's AI does not move. It is taken off for the moment a bot is seated and when it goes home, and wears off by
--          itself within 8 s if anything goes wrong. GM '#rr botfreeze' switches it off/on for comparing.
-- v2.3.4 (Fable, Rowan 21:24 'slide show at the start, clears up later'): botdiag shows the bot kart's SPEED changing every ~2 s
--          (slipstream on/off while the pack is bunched at the start, Coin Speed, chevrons, the rubber band flipping) and every change
--          makes the core restart the kart's movement = one hitch each, on top of our own new paths. Bot karts now: no slipstream /
--          Coin Speed / Klaxon speed changes, the rubber band is re-checked every 4 s only, a new speed is sent at most once a second
--          and only for a change of 8 % or more (stun, tar, lightning, Obsidian Fury go through at once), and the new path goes out in
--          the same tick as the new speed. Nothing else is changed. EXPERIMENT, off by default: '#rr botpath' = bot karts follow the
--          road with the server's path-finder (one long path of ~120 yd instead of a short straight one every second).
-- v2.3.3: botdiag showed bot karts reaching the end of each path and stopping (the server refreshes a moving kart's position only every
--          ~0.4-0.6 s, so the 8 yd 'near the end' check missed): paths are now timed and renewed ~0.8 s before they run out, and longer.
-- v2.3.2: still small jumps in Rowan's 2nd video (a bot snapped from the road edge to right behind him in one frame): new bot paths only
--          when the kart nears the end of its path (or after 2.5 s / a 15 % speed change). '#rr botdiag' logs the first bot's kart every tick.
-- v2.3.1: bot karts get a new path only every 0.9 s (or near their target), 5 points ahead on straights, and no 2 s speed refresh:
--          v2.3 sent one every 250 ms and the bots looked like a slide show (Rowan 20:36). First bot race: bot won 4:43.9, Rowan 2nd 4:46.1.
-- v2.3: BOT RACERS (Duck Hunt pattern). Group bots near you join the race, are ready by themselves and are seated by the script.
--        Bots have no game client, so Automove cannot drive them: the script drives their karts (MoveTo a point a few track points
--        ahead, on the bot's own lane, lanes drift toward the mystery boxes), uses their items after 1-4 s, and keeps them a little
--        slower than the players (92-100 %, a bit faster when far behind the leading player, slower when far ahead). Bots get no tickets,
--        runes, achievements or quest credit, and no bar / sounds. GM: '#rr bots' (on/off for new races), '#rr botskill <0.5-1.5>',
--        '#rr botstay' (the leader whispers 'stay' to the bots at GO and 'follow' at the end, if the bot AI fights the kart).
-- v2.2 (needs azzar-rainbow-race-podium.sql + ONE restart; without it the script falls back to v2.1.7 behaviour): the real PODIUM
--        (object 9997810, client model azzarfaire_circuit_podium.m2) stands just past the start row from the first finish until the
--        podium ends, 1st/2nd/3rd are parked on its three steps, 4th/5th on the road in front; the exit portal is our own creature
--        9997810 'Azzar Faire Portal' (orb, gear cursor) and its window shows the live text 1200245.
-- v2.1.6: chevron tiles +45 %.  v2.1.7: the race theme is played as music and stopped when you leave the track (it kept playing at the Faire).
-- v2.1.5 (Rowan's 2nd recording): the falling boxes showed as smoking red BOMBS (the flying helper 99549 is Duck Hunt's bomb and wears
--        aura 255651 from its template): the aura, the hostile faction and the click box are taken off before the dice look goes on.
-- v2.1.4: the BIG GOLD COUNTDOWN + faction crest. The client's Extensions.dll registers a handler on opcode 0x588: uint32 milliseconds ->
--        event BATTLEGROUND_COUNTDOWN_STARTED -> FrameXML CountdownTimer:StartTimer (0 -> BATTLEGROUND_STARTED). Our core never sends it
--        (arenas show the small red numbers too), so the script sends it itself when the karts appear. '#rr countdown' = back to the small numbers.
-- v2.1.3 (from Rowan's own recording of a v2.1 race, Rainbow_Race.mp4): button 5 is the live KLAXON 257217 (icon inv_rainbowrace_horn = the
--        gramophone; 'Triggers a loud horn sound', sound 215107 fx_car_horn). The blue vortex that sat there is the SONIC HORN 255711 = an ITEM
--        (shockwave, 12 m): it replaces our made-up 'Static Bomb' mine. Boxes and coins are taken a tick EARLY (where the kart will be in
--        0.3 s) so the box is gone as you reach it instead of after you drove through it. The blue light beams (live 'Vehicle Stun' 257214)
--        now only flash for 1.2 s when the karts appear, not through the whole countdown.
-- v2.1.2 (Rowan 15:02): the roll shows one icon at a time (0.5 s each) so the icons no longer pile up over the coin counter;
--        the exit portal is creature 99652 (gear cursor like live; the dressed-up helper 840178 showed a chat bubble).
-- v2.1.1 (Rowan 14:55): the picked item's floating icon now fades by itself after its 2 s (it was held up for as long as you kept the item);
--        a taken box / coin is removed by a sweep of the spot (also catches a leftover twin from an earlier race) and the log says what
--        it removed; the falling boxes ride an un-rooted flying helper (Duck Hunt's invisible 99549) so the glide is a real smooth move.
-- v2.1 (Rowan's first v2.0 race, 14:41): horn on button 5 like live (was 4); boxes are REMOVED when taken (a new one comes back), hang lower and
--        glide down in a random order so that all five stand on the road as the countdown ends; the item roll shows each icon for its full
--        2 s with the live jingle (sound 214906) + box pick-up sound 214907, race start 214905 + race theme 214904 at GO; Obsidian Fury no
--        longer steers itself (the MoveTo autopilot fought the client: it zig-zagged) = you steer it, at 2.2x speed.
-- RAINBOW RACE mini-game for the Azzar Faire (map 960 'MiniGames', area 10072), host Brumm 371923 on Dawnrise (map 909).
-- v2.0 = the live race, mimicked second by second from the games video 0:29-6:22 (1 frame per second at 1080p; the log is
--        faire-cache\rainbow-race\RAINBOW-RACE-LIVE-1S-HD-2026-11-14.md). On top of the v1.3.7 start flow (ready lobby, karts, 10 s
--        countdown, Automove, arrow tiles):
--   * MYSTERY BOXES: 7 rows of 5 across the road; row 1 drops in from the sky during the countdown. Driving through one rolls
--     an item for 3 s (the live 'Icon:' spells flicker on the kart), then the item sits in bar slot 1 (a second one waits in slot 2).
--   * ITEMS (live spells, live icons on the bar): Nitro Booster III -> II -> I (three presses, 3 s apart), Oil Trap, Rear Grenade,
--     Static Bomb, Green Rocket (aim on the ground), Crimson Rocket (the kart ahead, with the live chat callouts), Sapphire Seeker
--     Rocket (the leader), Lightning Storm (shrinks + slows + disarms everyone ahead), Obsidian Fury (the giant rocket, self-driving).
--     The SONIC HORN is always on the bar (4th button), like live.
--   * COINS: +1 each up to 10, the number floats on your kart; at 10 every further coin = 'Coin Speed' for 4 s. A hit, a fall or
--     the lightning costs 3 coins.
--   * SLIPSTREAM behind another kart, ACCELERATION ZONE on the arrow tiles, STICKY TRAP in the tar.
--   * CHAT like live (also top-centre): Race Standings block 10 s after GO and after every pass ('X passed Y!'), 'completed lap n/3
--     in mm:ss.mmm', 'set the best lap', 'is on the final lap!', 'Winner: / Second place: / Third place:'.
--   * FINISH: your kart is parked on the podium spots just past the start row, fireworks, then everyone is back on foot on the
--     grid and the Azzar Faire Portal stands behind the start row (gossip 'Exit!' + 'Are you sure you want to exit?').
--   HOW THE BAR WORKS: the kart template only knows 'Return to Checkpoint'. The script sends its own SMSG_PET_SPELLS (0x179) to
--     draw the buttons and reads the clicks from CMSG_PET_ACTION (0x175) / CMSG_PET_CAST_SPELL (0x1F0, the Green Rocket's ground
--     target) with a packet hook. If the bar does not react, say  #use  (uses the item) and tell Claude.
--   NOT YET (needs SQL + restart, or is unknown): the podium blocks (object display 300140), a portal that is NAMED 'Azzar Faire
--     Portal' with the live text, the entry cost, the big 3D countdown numbers and the 'Laps' HUD (client UI), bot racers.
-- TRACK = centre line of the live track, read from the client files (collision walls of azzarfaire_rainbow_road.wmo + the floor of
--        rainbwow_road.m2; WMO placed at 960 -1360.15 -4677.965 10.512, rot 0). 253 points, 12 yd apart, lap = 3032 yd. Point 1 = the start line.
-- Commands (chat):  #leave = back to the Faire.   #use = use your item.   #stuck = back onto the road.
--   GM only:  #rr start | bots | botskill <n> | botstay | botdiag | botpath | botfreeze | botseat | speed <rate> | tp <point> | dir | automove | item <NAME> | coins <n> | boxmode | bbauto | aura <id> | unaura <id> | cast <id>
-- Needs azzar-rainbow-race.sql (kart + helper templates, Brumm, quests). v2.0 needs NO new SQL and NO restart: .reload ale
local RR = {
  MAP = 960,
  FAIRE_SPOT = { 909, -1783.32, -12080.17, 62.6, 3.61 },   -- in front of Brumm (Rowan .gps 2026-11-12: Brumm -1785.55 -12081.30 62.44 o 0.468)
  LAPS = 3, MAX_PLAYERS = 5, JOIN_RANGE = 40,
  SPEED = 4.1,               -- kart speed rate (1.0 = 7 yd/s). v2.0: 3.6 -> 4.1 (live laps ~1:34 WITH boosts; ours were ~2:04 at 3.6). Tune live with '#rr speed'
  DIR = -1,                  -- v1.1.2: -1 = AGAINST the point list = the live direction (Rowan confirmed). '#rr dir' flips it
  GRID_BACK = 1,             -- the grid row sits this many points (12 yd each) behind the start line
  GRID_SIDE = { 0, -5, 5, -10, 10 },                       -- sideways offsets of the 5 grid slots (track is 25 yd wide)
  ARRIVE_WAIT = 6000,        -- ms between everyone arriving and the karts rolling out
  ARRIVE_MAX = 30000,        -- racers still loading after this are left out
  BOARD_MAX = 45000,         -- v1.1: ms to climb into your kart before you are seated for you
  COUNTDOWN = 10,            -- seconds (live)
  LOBBY_MAX = 300000,        -- ms the ready lobby waits before the race is called off
  PAD_RADIUS = 3.5,          -- yd from a speed panel that counts as driving over it
  PAD_BOOST_MS = 3000,       -- how long the arrow-tile boost lasts
  HOST = { -1536.8308, -4788.413, 0.6442602, 3.135657 },   -- grid Brumm on the start line (Rowan .gps 2026-11-14 13:12)
  AUTOMOVE = true,           -- live 'Automove' on the karts at GO (the kart drives itself, you steer). GM '#rr automove' flips it
  WINDOW = 10,               -- the tracker looks this many points either way from your last point
  MAX_PUTBACKS = 8,          -- safety: more new karts than this in one race = stop that player's race
  OFF_DIST = 40,             -- further than this from the centre line = off the track
  FALL_BELOW = 12,           -- lower than this under the track = fell
  END_AFTER_FIRST = 90000,   -- the race closes this long after the winner finishes
  MAX_TIME = 12 * 60000,
  TICKETS = 300,             -- per finished race (OURS: live value for 2nd-5th not seen)
  WIN_TICKETS = 500,         -- v2.0 live: 'You receive item: [Azzar Faire Ticket]x500' for the winner
  WIN_RUNES = 4000,          -- v2.0 live: 'You receive item: [Rune of Ascension]x4000' for the winner (item 375250). 0 = off
  -- ---- v2.0 ----
  BOX_UP = 0.3,              -- yd a mystery box floats above the road (v2.1: 1.3 was too high)
  BOX_DROP = 12,             -- v2.1: yd above its place that a row-1 box appears before it glides down
  BOX_R = 2.9,               -- yd: drive this close to a box to take it (boxes stand 5.1 yd apart)
  BOX_RESPAWN = 4000,        -- ms until a taken box is back
  BOX_MODE = "aura",         -- 'aura' = the live way (invisible 'Minigame Box' + spell 255654 'Visual: Box race'); 'display' = creature display 137670 (RacingBox.m2). GM '#rr boxmode' switches
  ROLL_MS = 3000,            -- the item roll (live 0:57-1:00)
  COIN_UP = 1.0, COIN_R = 2.7, COIN_RESPAWN = 8000,
  COIN_MAX = 10, COIN_SPEED_MS = 4000, HIT_COINS = 3,
  NITRO = { 0.25, 0.40, 0.60 },                            -- speed bonus of Nitro Booster I / II / III (OURS: the live spells are visuals only)
  NITRO_MS = 3000, STAGE_CD = 3000,                         -- live: each booster burns 3 s, the next stage is ready 3 s later
  PAD_BONUS = 0.45,   -- v2.1.6: chevron tiles +45 % (was +30 %; Rowan: a little more). GM '#rr pad <percent>' tunes it live
   COIN_SPEED_BONUS = 0.20, SLIP_BONUS = 0.12,
  SLIP_DIST = 16, SLIP_AFTER = 750,                         -- within 16 yd behind a kart for 0.75 s = Slipstream
  STICKY_MS = 3500, STICKY_SLOW = 0.5,                      -- live 3:04-3:08
  SHRINK_MS = 4500, SHRINK_SLOW = 0.6, SHRINK_SCALE = 0.4,  -- live 2:49-2:55
  STUN_MS = 1200,            -- a rocket / bomb hit stops the kart this long
  HORN_CD = 1000, HORN_R = 11,          -- Klaxon: 1 s (its DBC cooldown). HORN_R = the Sonic Horn item's shockwave (live text: 12 metres)
  BULLET_MS = 16000, BULLET_MULT = 2.2, BULLET_DISPLAY = 137873, BULLET_SCALE = 1.0,   -- Obsidian Fury: live 5:06-5:24; purple Azzar_Rocket_missile.m2
  BB_AUTOPILOT = false,      -- v2.1: OFF (in game the MoveTo chain fought the client and zig-zagged). GM '#rr bbauto' turns the experiment back on
  ROCKET_SPEED = 90,         -- yd/s of the rockets (spell missile speed)
  PODIUM_MS = 35000,         -- podium + fireworks after the LAST finisher (live 5:37 -> 6:15)
  AFTER_MAX = 300000,        -- after that everyone still there is sent back to the Faire
  FIREWORK_MS = 900,
  BOTS = true,               -- v2.3: group bots race too (script-driven karts). GM '#rr bots'
  BOT_SKILL = 1.0,           -- v2.3: multiplies every bot's speed (each bot rolls 0.92-1.00 per race on top). GM '#rr botskill <n>'
  BOT_LOOK = 4,              -- v2.3.3: track points (12 yd each) ahead that a bot kart aims at in bends (6 on straights)
  BOT_EARLY_MS = 800,        -- v2.3.3: a new bot path goes out this long before the old one would end (server ticks here are 250-500 ms)
  BOT_LANE = 8,
  BOT_PATH_MS = 2500,        -- v2.3.2: longest a bot path runs before a new one (new paths come when the kart nears its target)
  BOT_SEAT = true,           -- v2.3.6: put a bot that left its kart back in (checked once a second). GM '#rr botseat'
  BOT_FREEZE = true,         -- v2.3.5: keep the bots' own AI still (stun on the bot player) while they are in a race. GM '#rr botfreeze'
  BOT_ROADPATH = false,      -- v2.3.4 EXPERIMENT: MoveTo with the core's path-finder (mmaps of the track), 10 points ahead. GM '#rr botpath'
  BOT_RATE_MS = 1000, BOT_RATE_STEP = 0.08,   -- v2.3.4: a bot kart's speed is sent at most this often, and only for a change this big
  BOT_DIAG = false,          -- v2.3.2: GM '#rr botdiag' logs the first bot's kart every tick (world-console.log)              -- yd either side of the centre line a bot may use (the road is 25 yd wide)
  BOT_STAY = true,           -- v2.3: whisper 'stay' / 'follow' to the bots (only if the bot AI fights the kart). GM '#rr botstay'
  BIG_COUNTDOWN = true,      -- v2.1.4: send the client its own countdown packet (0x588)
  MUSIC = true,              -- v2.1: live race sounds (client SoundEntries 214904-214907)
}
local E = { BRUMM = 371923, KART = 99550, CREDIT = 379171,
            BOX = 99555, FALLER = 99549, COIN = 99576, TAR = 99575, BOMB = 99577, CTRL = 99554, PORTAL = 9997810, PORTAL_OLD = 99652, PODIUM_GO = 9997810 }   -- v2.1.2: PORTAL = Vertical Ascent's 'Portal' 99652 (orb 137860, IconName Interact = the gear cursor); both scripts tell their portals apart by where they stand   -- v2.0: live helper ids, all in the DB since azzar-rainbow-race.sql (invisible; the script dresses them)
local S = { RIDE = 46598, STUN = 255620, RETURN = 255753, READY = 257210, AUTOMOVE = 255634, READY_GO = 257212,
            GRID_STUN = 257214,          -- live 'Vehicle Stun' (its end plays the 'start minigames' burst)
            ACCEL_ZONE = 255723, SLIP = 255724,
            BOX_VIS = 255654, COIN_VIS = 255704, COIN_PLUS = 255710, COIN_MINUS = 255751, COIN_ICON0 = 255739, COIN_SPEED = 255750,
            NITRO1 = 255698, NITRO2 = 255699, NITRO3 = 255700,
            OIL = 255695, STICKY = 255696, REAR = 255705, GRENADE_VIS = 255706, BOOM = 255707,
            GREEN = 255702, HORN = 255711, KLAXON = 257217, STORM = 255713, SPARK = 255714, FURY = 255715,
            CRIMSON = 255716, CRIMSON_MISSILE = 255717, SAPPHIRE = 255718, SAPPHIRE_MISSILE = 255720, SAPPHIRE_MARK = 255721 }
local SND = { THEME = 214904, START = 214905, ROLL = 214906, PICKUP = 214907, KLAXON = 215107 }   -- mini_game_race_theme / _start / _item_box / _box_pick_up
local FIREWORKS = { 255883, 255884, 255885 }                   -- live 'Visual: Firework 01/02/03'
local TEXT_PORTAL = 1200245                                   -- live npc_text: '<The portal connects to the Azzar Faire. ...>'
-- the podium model: 10 yd long, 14.4 yd wide, three steps (middle highest), built on a slope that rises 0.12 a yard = our road here.
-- Stood at orientation pi its high end points back at the start row. Kart spots = step tops read from the model's collision mesh.
local PODIUM_GO_SPOT = { -1525.2, -4787.98, -1.25, 3.14159 }
local PODIUM_STEPS = { { -1525.0, -4788.5, 2.49, 0 }, { -1525.0, -4783.7, 1.24, 0 }, { -1525.0, -4793.3, -0.01, 0 },
                       { -1514.5, -4783.4, -2.55, 0 }, { -1514.5, -4793.6, -2.55, 0 } }   -- 1st, 2nd, 3rd on the steps; 4th, 5th on the road in front
local PORTAL_DISPLAY = 137860                                 -- AzzarFaire_portal.m2 (the glowing orb)
local KART_LOOKS = { 137649, 137651, 137652, 137653, 137649 }  -- GoblinKart.m2, skins 01/03/04/05
local ACH = { FIRST_MATCH = 90142, SAFE_ROAD = 90149, WINNER = 90150, AIM = 90160, DRAFT = 90161 }   -- 90160 'May my aim be true' (2 karts with one Green Rocket), 90161 'It Had to Be You' (draft 3 times in a race)
local Q_BASE, Q_DAILY = 1650229, 1650268
local TEXT_GREET, TEXT_MORE = 1200149, 1200150
local ITEM_TICKET, ITEM_RUNE = 558530, 375250
local TEMPSUMMON_TIMED_DESPAWN = 3
local KART_LIFE = 15 * 60000
local OP = { PET_SPELLS = 0x179, PET_ACTION = 0x175, PET_CAST = 0x1F0, COUNTDOWN = 0x588 }   -- 3.3.5a opcodes
local TRACK = {
  { -1531.62, -4788.48, -0.18 }, { -1543.61, -4788.39, 1.74 }, { -1555.59, -4788.19, 3.72 }, { -1567.57, -4787.80, 5.63 },
  { -1579.54, -4787.07, 7.38 }, { -1591.45, -4785.78, 8.83 }, { -1603.19, -4783.38, 9.88 }, { -1614.33, -4779.08, 10.40 },
  { -1623.37, -4771.37, 10.50 }, { -1628.95, -4760.84, 10.51 }, { -1631.71, -4749.20, 10.51 }, { -1632.92, -4737.28, 10.51 },
  { -1633.43, -4725.30, 10.51 }, { -1633.61, -4713.32, 10.51 }, { -1633.62, -4701.33, 10.51 }, { -1633.54, -4689.35, 10.51 },
  { -1633.17, -4677.37, 10.51 }, { -1632.07, -4665.44, 10.51 }, { -1629.24, -4653.82, 10.52 }, { -1622.88, -4643.77, 10.55 },
  { -1612.57, -4637.82, 10.70 }, { -1600.94, -4635.05, 11.14 }, { -1589.02, -4633.76, 11.80 }, { -1577.05, -4633.18, 12.64 },
  { -1565.07, -4632.96, 13.59 }, { -1553.08, -4632.89, 14.62 }, { -1541.10, -4632.92, 15.67 }, { -1529.11, -4632.95, 16.69 },
  { -1517.12, -4632.99, 17.65 }, { -1505.14, -4632.99, 18.48 }, { -1493.15, -4632.99, 19.13 }, { -1481.17, -4632.99, 19.56 },
  { -1469.18, -4632.99, 19.81 }, { -1457.19, -4632.99, 19.76 }, { -1445.21, -4632.99, 19.46 }, { -1433.22, -4632.99, 18.96 },
  { -1421.23, -4632.99, 18.25 }, { -1409.25, -4632.99, 17.38 }, { -1397.26, -4632.99, 16.40 }, { -1385.28, -4632.99, 15.36 },
  { -1373.29, -4632.99, 14.31 }, { -1361.30, -4632.99, 13.30 }, { -1349.32, -4632.99, 12.37 }, { -1337.33, -4632.99, 11.58 },
  { -1325.34, -4632.99, 10.97 }, { -1313.36, -4632.99, 10.61 }, { -1301.37, -4632.99, 10.51 }, { -1289.39, -4632.94, 10.51 },
  { -1277.41, -4632.41, 10.51 }, { -1265.51, -4631.07, 10.51 }, { -1253.75, -4628.76, 10.51 }, { -1242.32, -4625.17, 10.51 },
  { -1231.56, -4619.93, 10.51 }, { -1221.99, -4612.77, 10.51 }, { -1214.23, -4603.68, 10.51 }, { -1209.12, -4592.87, 10.51 },
  { -1206.30, -4581.24, 10.51 }, { -1205.51, -4569.29, 10.51 }, { -1206.12, -4557.33, 10.51 }, { -1208.61, -4545.62, 10.51 },
  { -1213.48, -4534.71, 10.51 }, { -1220.92, -4525.36, 10.51 }, { -1230.55, -4518.29, 10.51 }, { -1241.47, -4513.39, 10.51 },
  { -1253.08, -4510.43, 10.51 }, { -1264.96, -4508.89, 10.51 }, { -1276.93, -4508.47, 10.51 }, { -1288.88, -4509.26, 10.51 },
  { -1300.35, -4512.54, 10.51 }, { -1308.41, -4520.93, 10.51 }, { -1309.60, -4532.78, 10.51 }, { -1309.21, -4544.75, 10.51 },
  { -1311.43, -4556.42, 10.51 }, { -1319.44, -4565.07, 10.49 }, { -1330.26, -4570.07, 10.33 }, { -1341.96, -4572.62, 9.73 },
  { -1353.88, -4573.81, 8.76 }, { -1365.86, -4574.22, 7.48 }, { -1377.84, -4574.25, 5.97 }, { -1389.83, -4574.25, 4.34 },
  { -1401.82, -4574.25, 2.64 }, { -1413.80, -4574.25, 0.97 }, { -1425.79, -4574.25, -0.59 }, { -1437.78, -4574.25, -1.97 },
  { -1449.76, -4574.25, -3.08 }, { -1461.75, -4574.25, -3.84 }, { -1473.73, -4574.25, -4.30 }, { -1485.72, -4574.25, -4.32 },
  { -1497.71, -4574.25, -3.89 }, { -1509.69, -4574.25, -3.16 }, { -1521.68, -4574.25, -2.07 }, { -1533.67, -4574.25, -0.71 },
  { -1545.65, -4574.25, 0.84 }, { -1557.64, -4574.25, 2.48 }, { -1569.62, -4574.25, 3.93 }, { -1581.61, -4574.25, 5.04 },
  { -1593.59, -4574.40, 5.90 }, { -1605.53, -4575.45, 6.54 }, { -1617.29, -4577.71, 6.88 }, { -1628.70, -4581.39, 6.77 },
  { -1639.62, -4586.29, 6.22 }, { -1649.82, -4592.57, 5.47 }, { -1659.22, -4600.00, 4.74 }, { -1667.72, -4608.44, 4.06 },
  { -1675.21, -4617.80, 3.43 }, { -1681.76, -4627.82, 2.86 }, { -1687.34, -4638.43, 2.35 }, { -1691.92, -4649.50, 1.90 },
  { -1695.61, -4660.90, 1.54 }, { -1698.36, -4672.56, 1.25 }, { -1700.21, -4684.40, 1.08 }, { -1701.19, -4696.34, 0.96 },
  { -1701.23, -4708.33, 0.96 }, { -1700.42, -4720.28, 1.10 }, { -1698.69, -4732.14, 1.27 }, { -1696.05, -4743.83, 1.57 },
  { -1692.53, -4755.28, 1.95 }, { -1688.06, -4766.40, 2.39 }, { -1682.66, -4777.09, 2.91 }, { -1676.32, -4787.26, 3.48 },
  { -1668.92, -4796.69, 4.11 }, { -1660.57, -4805.28, 4.79 }, { -1651.36, -4812.93, 5.52 }, { -1641.26, -4819.38, 6.28 },
  { -1630.50, -4824.63, 7.15 }, { -1619.17, -4828.51, 8.32 }, { -1607.46, -4831.06, 9.82 }, { -1595.55, -4832.36, 11.63 },
  { -1583.57, -4832.65, 13.71 }, { -1571.59, -4832.65, 15.85 }, { -1559.60, -4832.65, 17.85 }, { -1547.61, -4832.65, 19.68 },
  { -1535.63, -4832.65, 21.49 }, { -1523.64, -4832.65, 23.26 }, { -1511.65, -4832.65, 24.93 }, { -1499.67, -4832.65, 26.43 },
  { -1487.68, -4832.65, 27.71 }, { -1475.70, -4832.65, 28.71 }, { -1463.71, -4832.65, 29.36 }, { -1451.72, -4832.65, 29.75 },
  { -1439.74, -4832.65, 29.71 }, { -1427.75, -4832.65, 29.29 }, { -1415.76, -4832.65, 28.59 }, { -1403.78, -4832.65, 27.54 },
  { -1391.79, -4832.65, 26.23 }, { -1379.81, -4832.65, 24.70 }, { -1367.82, -4832.65, 23.02 }, { -1355.83, -4832.65, 21.24 },
  { -1343.85, -4832.65, 19.42 }, { -1331.86, -4832.65, 17.62 }, { -1319.88, -4832.64, 15.91 }, { -1307.89, -4832.44, 14.32 },
  { -1296.31, -4829.72, 13.00 }, { -1287.62, -4821.89, 12.18 }, { -1284.76, -4810.37, 11.65 }, { -1284.70, -4798.39, 9.85 },
  { -1284.28, -4786.42, 10.62 }, { -1279.95, -4775.46, 10.51 }, { -1269.54, -4769.96, 10.51 }, { -1257.63, -4768.84, 10.51 },
  { -1245.76, -4767.30, 10.51 }, { -1234.75, -4762.76, 10.51 }, { -1225.48, -4755.19, 10.51 }, { -1215.38, -4748.90, 10.51 },
  { -1203.63, -4746.90, 10.51 }, { -1191.67, -4746.18, 10.51 }, { -1179.95, -4743.77, 10.51 }, { -1169.10, -4738.79, 10.51 },
  { -1160.23, -4730.82, 10.51 }, { -1154.73, -4720.25, 10.51 }, { -1152.58, -4708.50, 10.51 }, { -1153.44, -4696.58, 10.51 },
  { -1157.74, -4685.47, 10.51 }, { -1165.66, -4676.59, 10.51 }, { -1176.28, -4671.15, 10.51 }, { -1187.95, -4668.55, 10.51 },
  { -1199.92, -4668.05, 10.51 }, { -1211.87, -4668.94, 10.51 }, { -1223.70, -4670.81, 10.51 }, { -1235.41, -4673.39, 10.51 },
  { -1247.16, -4675.68, 10.51 }, { -1259.14, -4675.98, 10.35 }, { -1271.13, -4675.95, 9.70 }, { -1283.11, -4675.91, 8.62 },
  { -1295.10, -4675.90, 7.19 }, { -1307.08, -4675.90, 5.48 }, { -1319.07, -4675.90, 3.59 }, { -1331.06, -4675.90, 1.58 },
  { -1343.04, -4675.90, -0.47 }, { -1355.03, -4675.90, -2.46 }, { -1367.01, -4675.90, -4.33 }, { -1379.00, -4675.90, -5.99 },
  { -1390.99, -4675.90, -7.36 }, { -1402.97, -4675.90, -8.36 }, { -1414.96, -4675.90, -8.97 }, { -1426.95, -4675.90, -9.19 },
  { -1438.93, -4675.90, -8.81 }, { -1450.92, -4675.90, -7.74 }, { -1462.90, -4675.90, -5.90 }, { -1474.89, -4675.90, -3.42 },
  { -1486.88, -4675.90, -0.46 }, { -1498.86, -4675.90, 2.84 }, { -1510.85, -4675.90, 6.32 }, { -1522.84, -4675.90, 9.83 },
  { -1534.82, -4675.90, 13.21 }, { -1546.81, -4675.90, 16.30 }, { -1558.79, -4675.90, 18.95 }, { -1570.78, -4675.91, 21.02 },
  { -1582.54, -4677.62, 22.33 }, { -1591.31, -4685.36, 23.07 }, { -1594.17, -4696.84, 23.43 }, { -1591.32, -4708.33, 23.24 },
  { -1582.78, -4716.39, 22.93 }, { -1570.98, -4717.94, 22.55 }, { -1558.99, -4717.94, 21.86 }, { -1547.00, -4717.94, 20.85 },
  { -1535.02, -4717.94, 19.63 }, { -1523.03, -4717.94, 18.26 }, { -1511.05, -4717.94, 16.82 }, { -1499.06, -4717.94, 15.37 },
  { -1487.07, -4717.94, 13.99 }, { -1475.09, -4717.94, 12.57 }, { -1463.10, -4717.94, 10.68 }, { -1451.12, -4717.94, 8.41 },
  { -1439.13, -4717.94, 5.98 }, { -1427.14, -4717.94, 3.54 }, { -1415.16, -4717.94, 0.92 }, { -1403.17, -4717.94, -1.81 },
  { -1391.18, -4717.87, -4.47 }, { -1379.20, -4717.71, -6.95 }, { -1367.21, -4717.66, -9.07 }, { -1355.26, -4718.36, -10.68 },
  { -1343.90, -4721.89, -11.87 }, { -1337.44, -4731.70, -13.12 }, { -1335.83, -4743.55, -14.05 }, { -1335.94, -4755.53, -14.41 },
  { -1337.49, -4767.40, -14.10 }, { -1342.35, -4778.24, -13.41 }, { -1352.18, -4784.83, -12.92 }, { -1363.85, -4787.42, -12.76 },
  { -1375.81, -4788.22, -12.49 }, { -1387.79, -4788.48, -12.04 }, { -1399.78, -4788.52, -11.42 }, { -1411.76, -4788.52, -10.64 },
  { -1423.75, -4788.52, -9.76 }, { -1435.73, -4788.52, -8.80 }, { -1447.72, -4788.52, -7.79 }, { -1459.71, -4788.52, -6.76 },
  { -1471.69, -4788.52, -5.92 }, { -1483.68, -4788.52, -5.15 }, { -1495.67, -4788.52, -4.45 }, { -1507.65, -4788.52, -3.39 },
  { -1519.64, -4788.51, -1.93 },
}
local N = #TRACK
local HALF = math.floor(N / 2)

local Games = {}          -- [instanceId] = race
local Pending = {}        -- [starterLow] = race waiting for its starter to arrive
local RT = "|cffffd200[RACE]|r "
local AZT = "|cffff8000Azzar Event:|r "

local function log(msg) print("[RainbowRace] " .. msg) end
local missingLogged = {}
local function try(obj, method, ...)
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
local function clock(ms) ms = math.max(0, math.floor(ms)); return string.format("%02d:%02d.%03d", math.floor(ms / 60000), math.floor(ms / 1000) % 60, ms % 1000) end
local function wrap(i) return ((i - 1) % N) + 1 end
local atan2 = math.atan2 or math.atan
local PADS = {   -- v2: the 80 live rainbow_speed panels (x, y, z, nearest track point), read from rainbwow_road.m2
  { -1360.3, -4796.9, -11.5, 1 }, { -1364.8, -4797.4, -11.4, 1 }, { -1610.2, -4792.1, 10.3, 21 }, { -1608.4, -4790.4, 10.2, 21 },
  { -1615.7, -4789.9, 10.4, 22 }, { -1621.3, -4787.0, 10.5, 22 }, { -1624.1, -4782.2, 10.5, 22 }, { -1613.7, -4788.4, 10.4, 22 },
  { -1619.0, -4785.8, 10.5, 22 }, { -1626.6, -4783.0, 10.5, 23 }, { -1630.7, -4778.0, 10.5, 23 }, { -1631.1, -4639.1, 10.5, 34 },
  { -1625.9, -4634.4, 10.5, 34 }, { -1633.6, -4638.9, 10.5, 34 }, { -1628.4, -4633.8, 10.5, 34 }, { -1609.1, -4627.1, 10.8, 35 },
  { -1620.9, -4630.8, 10.5, 35 }, { -1615.2, -4628.4, 10.6, 35 }, { -1610.8, -4625.5, 10.8, 35 }, { -1210.2, -4615.5, 10.5, 68 },
  { -1212.7, -4614.9, 10.5, 68 }, { -1206.8, -4611.0, 10.5, 69 }, { -1205.4, -4605.6, 10.5, 69 }, { -1203.3, -4606.8, 10.5, 69 },
  { -1209.3, -4610.7, 10.5, 69 }, { -1203.0, -4600.7, 10.5, 70 }, { -1200.8, -4601.7, 10.5, 70 }, { -1231.1, -4508.3, 10.5, 77 },
  { -1230.1, -4506.2, 10.5, 77 }, { -1235.6, -4504.6, 10.5, 78 }, { -1240.6, -4502.8, 10.5, 78 }, { -1235.3, -4507.1, 10.5, 78 },
  { -1240.2, -4505.3, 10.5, 78 }, { -1305.3, -4503.4, 10.5, 83 }, { -1312.5, -4508.4, 10.5, 83 }, { -1310.7, -4510.2, 10.5, 83 },
  { -1303.0, -4504.8, 10.5, 83 }, { -1310.2, -4506.9, 10.5, 83 }, { -1315.1, -4516.6, 10.5, 84 }, { -1317.4, -4515.5, 10.5, 84 },
  { -1317.5, -4522.2, 10.5, 84 }, { -1319.7, -4523.0, 10.5, 84 }, { -1315.7, -4513.2, 10.5, 84 }, { -1319.9, -4520.5, 10.5, 84 },
  { -1318.2, -4528.6, 10.5, 85 }, { -1320.6, -4528.5, 10.5, 85 }, { -1299.2, -4550.4, 10.5, 86 }, { -1301.2, -4548.9, 10.5, 86 },
  { -1304.3, -4562.6, 10.5, 87 }, { -1301.0, -4556.3, 10.5, 87 }, { -1305.8, -4568.2, 10.5, 87 }, { -1301.8, -4562.2, 10.5, 87 },
  { -1308.3, -4567.9, 10.5, 88 }, { -1632.1, -4571.6, 7.6, 114 }, { -1636.8, -4573.5, 7.5, 114 }, { -1630.3, -4573.3, 7.5, 114 },
  { -1634.9, -4575.1, 7.4, 114 }, { -1640.5, -4576.3, 7.2, 115 }, { -1642.3, -4575.0, 7.3, 115 }, { -1644.9, -4579.4, 6.9, 115 },
  { -1646.1, -4577.3, 7.1, 115 }, { -1646.7, -4602.4, 4.3, 116 }, { -1653.2, -4607.7, 3.6, 117 }, { -1650.0, -4605.0, 3.9, 117 },
  { -1675.9, -4604.9, 5.0, 118 }, { -1677.7, -4603.3, 5.3, 118 }, { -1679.1, -4608.8, 4.8, 119 }, { -1686.3, -4615.7, 4.6, 119 },
  { -1685.0, -4617.8, 4.3, 119 }, { -1683.4, -4611.5, 4.8, 119 }, { -1680.9, -4607.3, 5.1, 119 }, { -1682.2, -4613.7, 4.4, 119 },
  { -1686.0, -4791.3, 4.8, 134 }, { -1683.1, -4795.5, 4.9, 134 }, { -1684.7, -4789.2, 4.4, 134 }, { -1681.9, -4793.3, 4.6, 134 },
  { -1676.7, -4803.5, 5.4, 135 }, { -1680.0, -4799.5, 5.2, 135 }, { -1675.7, -4801.2, 5.0, 135 }, { -1678.9, -4797.3, 4.8, 135 },
  { -1652.8, -4799.1, 3.8, 136 }, { -1646.3, -4804.5, 4.5, 137 }, { -1649.6, -4801.9, 4.2, 137 }, { -1645.1, -4829.1, 7.2, 138 },
  { -1640.6, -4831.4, 7.5, 138 }, { -1640.5, -4828.9, 7.3, 138 }, { -1645.0, -4826.6, 7.0, 138 }, { -1635.9, -4833.6, 7.7, 139 },
  { -1631.2, -4835.5, 8.1, 139 }, { -1636.0, -4831.1, 7.5, 139 }, { -1631.4, -4833.0, 7.8, 139 }, { -1302.1, -4842.2, 13.6, 166 },
  { -1312.2, -4842.4, 14.9, 166 }, { -1307.9, -4842.2, 14.3, 166 }, { -1303.7, -4840.1, 13.8, 166 }, { -1295.8, -4840.7, 12.9, 167 },
  { -1297.8, -4838.9, 13.2, 167 }, { -1284.6, -4803.4, 11.3, 170 }, { -1284.7, -4798.8, 11.1, 170 }, { -1247.7, -4757.7, 10.5, 175 },
  { -1244.2, -4756.6, 10.5, 175 }, { -1226.7, -4767.5, 10.5, 176 }, { -1237.9, -4753.0, 10.5, 176 }, { -1241.0, -4755.1, 10.5, 176 },
  { -1225.3, -4769.5, 10.5, 176 }, { -1221.4, -4765.4, 10.5, 177 }, { -1222.1, -4763.0, 10.5, 177 }, { -1586.4, -4669.9, 22.2, 223 },
  { -1588.3, -4668.5, 22.3, 223 }, { -1592.7, -4671.8, 22.6, 223 }, { -1586.4, -4666.9, 22.1, 223 }, { -1598.6, -4677.9, 23.0, 224 },
  { -1597.6, -4680.4, 23.1, 224 }, { -1602.1, -4684.3, 23.4, 224 }, { -1594.9, -4673.1, 22.7, 224 }, { -1600.5, -4686.5, 23.4, 224 },
  { -1593.2, -4675.0, 22.7, 224 }, { -1604.0, -4691.2, 23.5, 225 }, { -1602.0, -4693.0, 23.5, 225 }, { -1604.4, -4698.9, 23.5, 225 },
  { -1602.2, -4697.4, 23.5, 225 }, { -1600.8, -4712.4, 23.1, 226 }, { -1601.7, -4705.1, 23.4, 226 }, { -1594.3, -4717.8, 22.9, 226 },
  { -1604.0, -4705.7, 23.4, 226 }, { -1596.1, -4719.5, 22.8, 226 }, { -1599.4, -4710.1, 23.2, 226 }, { -1597.4, -4717.3, 22.8, 226 },
  { -1589.6, -4724.1, 22.6, 227 }, { -1582.3, -4727.5, 22.3, 227 }, { -1582.9, -4725.2, 22.5, 227 }, { -1590.6, -4721.0, 22.7, 227 },
  { -1592.1, -4723.0, 22.6, 227 }, { -1584.9, -4727.5, 22.3, 227 }, { -1327.3, -4769.1, -13.8, 251 }, { -1326.7, -4763.0, -14.2, 251 },
  { -1329.2, -4775.4, -13.3, 251 }, { -1329.1, -4767.4, -13.9, 251 }, { -1330.7, -4773.3, -13.5, 251 }, { -1332.3, -4781.7, -12.7, 252 },
  { -1337.2, -4788.8, -12.0, 252 }, { -1339.3, -4786.6, -12.4, 252 }, { -1333.4, -4779.3, -13.0, 252 }, { -1336.4, -4786.1, -12.3, 252 },
  { -1349.3, -4794.8, -11.5, 253 }, { -1355.5, -4795.5, -11.6, 253 }, { -1343.1, -4792.0, -11.7, 253 }, { -1353.9, -4797.2, -11.3, 253 },
  { -1342.9, -4789.4, -12.1, 253 }, { -1348.8, -4792.3, -11.9, 253 },
}
-- v2.0 pickups, made from the track floor mesh (faire-cache\rainbow-race\track.json): x, y, floor z, track point, row/group
local BOXES = {   -- 7 rows of 5 mystery boxes (row 1 = 50 yd after the start line like live; rows 2-7 placed by lap fraction from the video timing)
  { -1487.2, -4798.7, -5.04, 250, 1 }, { -1487.2, -4793.6, -4.99, 250, 1 }, { -1487.2, -4788.5, -4.94, 250, 1 }, { -1487.2, -4783.4, -4.89, 250, 1 }, { -1487.2, -4778.3, -4.83, 250, 1 },
  { -1551.1, -4686.1, 17.21, 206, 2 }, { -1551.1, -4681.0, 17.24, 206, 2 }, { -1551.1, -4675.9, 17.26, 206, 2 }, { -1551.1, -4670.8, 17.28, 206, 2 }, { -1551.1, -4665.7, 17.29, 206, 2 },
  { -1225.8, -4681.7, 10.51, 179, 3 }, { -1226.9, -4676.7, 10.51, 179, 3 }, { -1228.0, -4671.8, 10.51, 179, 3 }, { -1229.1, -4666.8, 10.51, 179, 3 }, { -1230.2, -4661.8, 10.51, 179, 3 },
  { -1475.7, -4822.4, 28.56, 138, 4 }, { -1475.7, -4827.5, 28.64, 138, 4 }, { -1475.7, -4832.6, 28.71, 138, 4 }, { -1475.7, -4837.8, 28.78, 138, 4 }, { -1475.7, -4842.8, 28.85, 138, 4 },
  { -1688.7, -4676.7, -0.48, 110, 5 }, { -1693.7, -4675.9, 0.37, 110, 5 }, { -1698.8, -4675.1, 1.21, 110, 5 }, { -1703.8, -4674.3, 1.65, 110, 5 }, { -1708.8, -4673.5, 0.89, 110, 5 },
  { -1479.5, -4584.4, -4.29, 87, 6 }, { -1479.5, -4579.4, -4.31, 87, 6 }, { -1479.5, -4574.2, -4.31, 87, 6 }, { -1479.5, -4569.1, -4.31, 87, 6 }, { -1479.5, -4564.1, -4.30, 87, 6 },
  { -1216.4, -4579.6, 10.51, 57, 7 }, { -1211.3, -4579.9, 10.51, 57, 7 }, { -1206.2, -4580.3, 10.51, 57, 7 }, { -1201.1, -4580.6, 10.51, 57, 7 }, { -1196.1, -4580.9, 10.51, 57, 7 },
}
local COINS = {   -- 69 coins in 17 groups (lines along a lane, rows of 3 across, diagonals), OUR layout in the live style: the live spots are in no cache
  { -1431.3, -4793.6, -8.98, 246, 1 }, { -1425.3, -4793.6, -9.42, 245, 1 }, { -1419.3, -4793.6, -9.84, 245, 1 }, { -1413.3, -4793.6, -10.24, 244, 1 }, { -1407.3, -4793.6, -10.61, 244, 1 },
  { -1330.8, -4742.8, -13.94, 235, 2 }, { -1335.8, -4743.5, -14.04, 235, 2 }, { -1340.9, -4744.2, -14.13, 235, 2 }, { -1446.9, -4723.0, 7.16, 224, 3 }, { -1452.9, -4723.0, 8.37, 224, 3 },
  { -1458.9, -4723.0, 9.54, 223, 3 }, { -1464.9, -4723.0, 10.65, 223, 3 }, { -1573.0, -4710.0, 23.08, 214, 4 }, { -1579.6, -4714.3, 22.96, 213, 4 }, { -1586.8, -4716.1, 22.91, 213, 4 },
  { -1594.7, -4715.7, 21.64, 212, 4 }, { -1384.4, -4686.1, -6.36, 192, 5 }, { -1378.4, -4686.1, -5.64, 192, 5 }, { -1372.4, -4686.1, -4.79, 191, 5 }, { -1366.4, -4686.1, -3.94, 191, 5 },
  { -1360.4, -4686.1, -2.99, 190, 5 }, { -1157.8, -4706.4, 10.51, 171, 6 }, { -1152.8, -4706.0, 10.51, 171, 6 }, { -1147.7, -4705.6, 10.51, 171, 6 }, { -1251.6, -4762.9, 10.28, 161, 7 },
  { -1257.6, -4763.7, 10.49, 160, 7 }, { -1263.4, -4764.3, 10.51, 160, 7 }, { -1269.4, -4764.8, 10.51, 159, 7 }, { -1333.4, -4825.0, 18.07, 150, 8 }, { -1339.4, -4830.1, 18.82, 149, 8 },
  { -1345.4, -4835.2, 19.57, 149, 8 }, { -1351.4, -4840.3, 20.33, 148, 8 }, { -1587.7, -4832.6, 13.00, 129, 9 }, { -1593.7, -4832.4, 11.96, 128, 9 }, { -1599.6, -4831.9, 11.01, 128, 9 },
  { -1605.6, -4831.3, 10.10, 127, 9 }, { -1611.5, -4830.2, 9.30, 127, 9 }, { -1683.3, -4764.6, 1.63, 118, 10 }, { -1687.8, -4766.9, 2.41, 118, 10 }, { -1692.4, -4769.2, 2.74, 118, 10 },
  { -1591.5, -4574.4, 5.75, 97, 11 }, { -1585.5, -4574.3, 5.32, 96, 11 }, { -1579.5, -4574.2, 4.84, 96, 11 }, { -1573.5, -4574.2, 4.29, 95, 11 }, { -1335.7, -4579.0, 10.10, 76, 12 },
  { -1331.0, -4572.8, 10.30, 75, 12 }, { -1327.1, -4565.7, 10.37, 75, 12 }, { -1323.8, -4558.6, 10.44, 74, 12 }, { -1252.2, -4510.7, 10.51, 65, 13 }, { -1246.4, -4512.1, 10.51, 64, 13 },
  { -1240.6, -4513.8, 10.51, 64, 13 }, { -1235.2, -4516.2, 10.51, 63, 13 }, { -1229.8, -4518.9, 10.51, 63, 13 }, { -1341.1, -4627.9, 11.90, 44, 14 }, { -1341.1, -4633.0, 11.83, 44, 14 },
  { -1341.1, -4638.1, 11.77, 44, 14 }, { -1468.3, -4638.1, 19.81, 33, 15 }, { -1474.3, -4638.1, 19.72, 33, 15 }, { -1480.3, -4638.1, 19.60, 32, 15 }, { -1486.3, -4638.1, 19.41, 32, 15 },
  { -1596.2, -4626.9, 11.33, 22, 16 }, { -1601.9, -4632.7, 11.09, 22, 16 }, { -1606.5, -4639.1, 10.94, 21, 16 }, { -1609.1, -4644.7, 10.80, 21, 16 }, { -1622.6, -4738.1, 10.51, 12, 17 },
  { -1622.0, -4744.1, 10.51, 11, 17 }, { -1621.3, -4748.7, 10.51, 11, 17 }, { -1620.0, -4754.5, 10.51, 10, 17 }, { -1619.0, -4757.8, 10.51, 10, 17 },
}
local PODIUM = { { -1520.2, -4788.5, -1.85, 6.281, 253 }, { -1525.2, -4793.6, -1.25, 6.281, 253 }, { -1525.2, -4783.4, -0.97, 6.281, 253 }, { -1530.2, -4793.6, -0.53, 6.281, 1 }, { -1530.2, -4783.4, -0.23, 6.281, 1 } }   -- x, y, z, o, track point: 1st in the middle, just past the start row, facing up the track
local PORTAL_SPOT = { -1567.7, -4787.8, 5.65, 6.222, 4 }   -- the exit portal: 6 tile rows behind the start row, road centre
local FIREWORK_SPOTS = { { -1507.2, -4802.5, -3.71, 0.000, 252 }, { -1507.2, -4774.5, -3.14, 0.000, 252 }, { -1532.3, -4803.5, -0.52, 6.276, 1 }, { -1532.1, -4773.5, 0.36, 6.276, 1 }, { -1492.2, -4788.5, -4.65, 0.000, 251 }, { -1549.4, -4802.3, 2.24, 6.266, 2 }, { -1549.0, -4774.3, 3.09, 6.266, 2 } }
for _, p in ipairs(PADS) do                                  -- v1.3.6: re-index each panel against THIS track list (the [4] in the
  local best, bd = 1, nil                                    -- table came from track.json, whose numbering starts 13 points off)
  for k = 1, #TRACK do
    local d = (TRACK[k][1] - p[1]) ^ 2 + (TRACK[k][2] - p[2]) ^ 2 + ((TRACK[k][3] - p[3]) * 2) ^ 2
    if not bd or d < bd then best, bd = k, d end
  end
  p[4] = best
end
local function heading(i)                                   -- which way the race runs at point i
  local a, b = TRACK[i], TRACK[wrap(i + RR.DIR)]
  return atan2(b[2] - a[2], b[1] - a[1]) % (2 * math.pi)
end
local function gridSpot(slot)                               -- x, y, z, o of grid slot 1..5
  local i = wrap(1 - RR.GRID_BACK * RR.DIR)
  local p, h = TRACK[i], heading(i)
  local side = RR.GRID_SIDE[((slot - 1) % #RR.GRID_SIDE) + 1]
  return p[1] - math.sin(h) * side, p[2] + math.cos(h) * side, p[3], h, i
end
local function near(i, j, k) local d = ((i - j + HALF) % N) - HALF; return d >= -k and d <= k end   -- track points i and j within k of each other
local function segDist2(px, py, ax, ay, bx, by)             -- squared distance from p to the segment a-b (pickups at 30 yd/s: 7 yd per tick)
  local sx, sy = bx - ax, by - ay
  local l2 = sx * sx + sy * sy
  local f = l2 > 0 and ((px - ax) * sx + (py - ay) * sy) / l2 or 0
  if f < 0 then f = 0 elseif f > 1 then f = 1 end
  local dx, dy = px - (ax + sx * f), py - (ay + sy * f)
  return dx * dx + dy * dy
end
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
local function inGame(g, pl) return pl and pl:GetMapId() == RR.MAP and pl:GetInstanceId() == g.inst end
-- v1.0.1 (2026-11-14): never keep a Map handle between ticks (ALE invalidates it when the hook that made it ends);
-- fetch the race map fresh from a member who is in the game instance.
local function mapOf(g)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then return pl:GetMap(), pl end
  end
  return nil
end
local function obj(g, guid) local mp = mapOf(g); return guid and mp and mp:GetWorldObject(guid) end
local function tell(g, msg, center)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl then
      pl:SendBroadcastMessage(msg)
      if center then pl:SendAreaTriggerMessage(center == true and msg or center) end
    end
  end
end
local function race(g, text) tell(g, RT .. text, true) end   -- v2.0 live: every [RACE] line is in chat AND top-centre
local function kartOf(g, m) return obj(g, m.kartGuid) end
local function hasAch(pl, id) return try(pl, "HasAchieved", id) == true end
local function isBot(pl) return pl ~= nil and try(pl, "IsBot") == true end   -- v2.3
local function giveAch(pl, id) if pl and not isBot(pl) and not hasAch(pl, id) then try(pl, "SetAchievement", id) end end
local function zap(g, low, entry, x, y, r)                    -- remove every helper of this kind standing on a spot (ours, or a twin an earlier race left)
  local pl = getPlayer(g, low)
  local n = 0
  for _, c in pairs(pl and try(pl, "GetCreaturesInRange", 30, entry) or {}) do
    if (c:GetX() - x) ^ 2 + (c:GetY() - y) ^ 2 < r * r then c:DespawnOrUnsummon(0); n = n + 1 end
  end
  return n
end
local function despawn(g, guid) local o = obj(g, guid); if o then try(o, "DespawnOrUnsummon", 0) end end
local function spawn(g, entry, x, y, z, o, life)             -- a helper creature, summoned by any racer who is in the instance
  local _, pl = mapOf(g)
  if not pl then return nil end
  return pl:SpawnCreature(entry, x, y, z, o or 0, TEMPSUMMON_TIMED_DESPAWN, life or KART_LIFE)
end
local function sound(pl, id) if RR.MUSIC and pl and not isBot(pl) then try(pl, "PlayDirectSound", id, pl) end end
local function music(pl, id)                                 -- v2.1.7: the race theme goes out as MUSIC, so it can be stopped (id 0) when you leave
  if not pl or isBot(pl) or not (RR.MUSIC or id == 0) then return end
  if type(pl.PlayMusic) == "function" then local ok = pcall(pl.PlayMusic, pl, id, pl); if ok then return end end
  if id ~= 0 then try(pl, "PlayDirectSound", id, pl) end
end
local function bigCountdown(pl, ms)                           -- the client draws the gold numbers and the crest by itself
  if not (RR.BIG_COUNTDOWN and pl and type(CreatePacket) == "function") or isBot(pl) then return false end
  local ok, err = pcall(function() local pk = CreatePacket(OP.COUNTDOWN, 4); pk:WriteULong(ms); pl:SendPacket(pk) end)
  if not ok then log("v2.1.4: could not send the countdown packet: " .. tostring(err)) end
  return ok
end
local function after(g, ms, fn) g.timers[#g.timers + 1] = { at = now() + ms, fn = fn } end   -- run fn(t) in this race's own tick

-- ---------- v2.0: items ----------
-- icon = the live 'Icon: X' spell (the roll + what you hold, as float text / kart visual); bar = the live spell whose icon sits on the bar.
local ITEMS = {
  OIL    = { icon = 255726, bar = S.OIL,      name = "Oil Trap" },
  ACC1   = { icon = 255728, bar = S.NITRO1,   name = "Nitro Booster I" },
  ACC2   = { icon = 255729, bar = S.NITRO2,   name = "Nitro Booster II" },
  ACC3   = { icon = 255730, bar = S.NITRO3,   name = "Nitro Booster III" },
  BOMB   = { icon = 255731, bar = S.REAR,     name = "Rear Grenade" },
  STATIC = { icon = 255732, bar = S.HORN,     name = "Sonic Horn" },   -- v2.1.3: the blue vortex icon; 'emits a shockwave within 12 meters, pushing nearby racers away'
  SHRINK = { icon = 255733, bar = S.STORM,    name = "Lightning Storm" },
  BULLET = { icon = 255734, bar = S.FURY,     name = "Obsidian Fury" },
  FIRST  = { icon = 255735, bar = S.SAPPHIRE, name = "Sapphire Seeker Rocket" },
  TARGET = { icon = 255736, bar = S.CRIMSON,  name = "Crimson Rocket" },
  MORTAR = { icon = 255737, bar = S.GREEN,    name = "Green Rocket" },
}
local ROLL_ICONS = { 255727, 255731, 255732, 255737, 255729, 255733, 255735, 255734, 255736, 255730, 255728, 255726 }   -- the order seen flickering at 0:57
local BAR_ITEM = {}                                           -- bar spell -> item key
for k, d in pairs(ITEMS) do BAR_ITEM[d.bar] = k end
-- what a box gives, by place (OURS, Mario Kart style: the leader gets traps, the back gets the big guns; live odds are unknown)
local ODDS = {
  solo   = { ACC3 = 30, ACC2 = 10, OIL = 15, BOMB = 10, STATIC = 10, MORTAR = 15, BULLET = 10 },
  first  = { OIL = 28, BOMB = 20, STATIC = 14, ACC3 = 20, ACC2 = 6, MORTAR = 12 },
  middle = { ACC3 = 24, ACC2 = 8, MORTAR = 15, TARGET = 20, OIL = 10, BOMB = 8, STATIC = 4, SHRINK = 5, FIRST = 6 },
  last   = { BULLET = 14, SHRINK = 12, FIRST = 13, TARGET = 20, ACC3 = 24, ACC2 = 4, MORTAR = 13 },
}
local function rollItem(g, low)
  local n, rank = 0, 1
  local mine = g.members[low].prog or 0
  for l2, m2 in pairs(g.members) do
    n = n + 1
    if l2 ~= low and (m2.finished or (m2.prog or 0) > mine) then rank = rank + 1 end
  end
  local tab = (n <= 1 and ODDS.solo) or (rank == 1 and ODDS.first) or (rank == n and ODDS.last) or ODDS.middle
  local sum = 0
  for _, w in pairs(tab) do sum = sum + w end
  local r = math.random() * sum
  local pick
  for k, w in pairs(tab) do pick = k; r = r - w; if r <= 0 then break end end
  return pick
end

-- ---------- the kart's bar (items in slots 1-2, the horn on button 5: the live button shows a "5") ----------
local function sendBar(g, m, pl, c, t)
  if not (pl and c) or m.bot or type(CreatePacket) ~= "function" then return end
  local slots = { [0] = m.items[1] and ITEMS[m.items[1]].bar or 0, [1] = m.items[2] and ITEMS[m.items[2]].bar or 0,
                  [4] = ((g.state == "racing" or g.state == "grid") and not m.finished) and S.KLAXON or 0 }   -- live: the horn sits there dim during the countdown
  local ok, err = pcall(function()
    local pk = CreatePacket(OP.PET_SPELLS, 80)
    pk:WriteGUID(c:GetGUID())
    pk:WriteUShort(0)                                        -- pet family
    pk:WriteULong(0)                                         -- duration
    pk:WriteUByte(0); pk:WriteUByte(0); pk:WriteUShort(0x800)   -- react, command, 'vehicle' flag (as the core sends it)
    for i = 0, 9 do
      if i < 8 then pk:WriteULong((slots[i] or 0) + (i + 8) * 16777216) else pk:WriteULong(0) end
    end
    pk:WriteUByte(0)
    local cds = {}
    if m.items[1] and t < (m.itemReadyAt or 0) then cds[#cds + 1] = { slots[0], m.itemReadyAt - t } end
    if slots[4] ~= 0 and t < (m.hornAt or 0) then cds[#cds + 1] = { S.KLAXON, m.hornAt - t } end
    pk:WriteUByte(#cds)
    for _, cd in ipairs(cds) do pk:WriteULong(cd[1]); pk:WriteUShort(0); pk:WriteULong(math.floor(cd[2])); pk:WriteULong(0) end
    pl:SendPacket(pk)
  end)
  if not ok and not g.barErr then g.barErr = true; log("v2.0: could not send the kart bar (" .. tostring(err) .. "): items still work with #use") end
end
local function holdIcon(c, spell, on)                        -- the 'Icon: X' aura stays while you hold the item (the DBC gives it 2 s)
  if not c then return end
  if on then try(c, "AddAura", spell, c) else try(c, "RemoveAura", spell) end   -- v2.1.1: 2 s, then it fades by itself
end
local function giveItem(g, low, key, t)
  local m = g.members[low]
  if not (m and ITEMS[key]) or #m.items >= 2 then return false end
  m.items[#m.items + 1] = key
  local pl, c = getPlayer(g, low), kartOf(g, m)
  holdIcon(c, ITEMS[key].icon, true)
  sendBar(g, m, pl, c, t)
  return true
end
local function clearItems(g, low, t)                         -- 'out of gadgets' (the lightning) / the end of your race
  local m = g.members[low]
  local c = kartOf(g, m)
  for _, key in ipairs(m.items) do holdIcon(c, ITEMS[key].icon, false) end
  m.items = {}; m.roll = nil; m.itemReadyAt = 0
  sendBar(g, m, getPlayer(g, low), c, t)
end

-- ---------- v2.0: coins ----------
local function coinIcon(m, c, t)                             -- the coin with a number floating on the kart
  if not c then return end
  local want = (t < (m.coinSpeedUntil or 0)) and S.COIN_SPEED or (S.COIN_ICON0 + m.coins)
  if m.coinIcon ~= want then
    if m.coinIcon then try(c, "RemoveAura", m.coinIcon) end
    try(c, "AddAura", want, c)
    m.coinIcon = want
  end
end
local function addCoin(g, m, c, t)
  if m.coins >= RR.COIN_MAX then m.coinSpeedUntil = t + RR.COIN_SPEED_MS   -- live: 'Icon: Coin 10 fades', 'Icon: Coin Speed' for ~4 s
  else m.coins = m.coins + 1 end
  m.coinsTaken = (m.coinsTaken or 0) + 1
  if c then try(c, "CastSpell", c, S.COIN_PLUS, true) end    -- the yellow '+1'
  coinIcon(m, c, t)
end
local function loseCoins(g, m, c, t)                         -- live: every hit / fall / lightning = -3
  m.coinSpeedUntil = 0
  local n = math.min(RR.HIT_COINS, m.coins)
  if n > 0 then
    m.coins = m.coins - n
    if c then
      try(c, "CastSpell", c, S.COIN_MINUS, true)             -- the red '-3'
      for k = 1, n do                                        -- the coins fly out (just for show)
        local a = math.random() * 2 * math.pi
        local s = spawn(g, E.COIN, c:GetX() + math.cos(a) * 3.5, c:GetY() + math.sin(a) * 3.5, c:GetZ() + 1.5, 0, 2500)
        if s then try(s, "AddAura", S.COIN_VIS, s) end
      end
    end
  end
  coinIcon(m, c, t)
end

-- ---------- karts ----------
local function hold(c, on, grid)                            -- karts stand still (grid = the live 'Vehicle Stun' of the countdown)
  if not c then return end
  if on then try(c, "AddAura", grid and S.GRID_STUN or S.STUN, c); try(c, "SetRooted", true)
  else try(c, "RemoveAura", S.STUN); try(c, "RemoveAura", S.GRID_STUN); try(c, "SetRooted", false) end
end
local function automoveOn(m, c) if c and not m.bot then try(c, "AddAura", S.AUTOMOVE, c) end end   -- v2.3: bots have no client to steer with
local function applySpeed(g, m, c, t)                       -- ONE place sets the kart's speed (speed auras would reset it to the template's 3.6)
  if not c then return end
  local r
  if t < (m.bbUntil or 0) then r = RR.SPEED * RR.BULLET_MULT
  else
    local b = 0
    if t < (m.padUntil or 0) then b = b + RR.PAD_BONUS end
    if t < (m.nitroUntil or 0) then b = b + (m.nitroBonus or 0) end
    if not m.bot then                                        -- v2.3.4: these flicker on and off; on a script-driven kart every change is a hitch
      if t < (m.coinSpeedUntil or 0) then b = b + RR.COIN_SPEED_BONUS end
      if t < (m.slipUntil or 0) then b = b + RR.SLIP_BONUS end
    end
    r = RR.SPEED * math.min(1 + b, 2.0)
    if t < (m.stickyUntil or 0) then r = r * RR.STICKY_SLOW end
    if t < (m.shrinkUntil or 0) then r = r * RR.SHRINK_SLOW end
    if not m.bot and t < (m.hornedUntil or 0) then r = r * 0.75 end
  end
  if m.bot then                                              -- v2.3 / v2.3.4
    r = r * (m.botSkill or 1) * RR.BOT_SKILL * (m.botBand or 1)
    local hard = t < (m.bbUntil or 0) or t < (m.stickyUntil or 0) or t < (m.shrinkUntil or 0)   -- these must show at once
    if hard ~= m.rateHard then m.rateHard = hard; m.rate = nil end
    if m.rate and (math.abs(m.rate - r) < RR.BOT_RATE_STEP * m.rate or t < (m.rateAt or 0) + RR.BOT_RATE_MS) then return end
    try(c, "SetSpeed", 1, r, true); m.rate = r; m.rateAt = t
    m.tx = nil                                               -- the new path goes out with the new speed (one restart, not two)
    return
  end
  if not m.rate or math.abs(m.rate - r) > 0.01 or t >= (m.rateAt or 0) + 2000 then
    try(c, "SetSpeed", 1, r, true); m.rate = r; m.rateAt = t
  end
end
local function dropKart(g, low, pl)                         -- out of the kart, kart removed
  local m = g.members[low]
  local c = kartOf(g, m)
  if c then
    local kit = c:GetVehicleKit()
    if kit and pl then try(kit, "RemovePassenger", pl) end
    g.kartOwner[c:GetGUIDLow()] = nil
    c:DespawnOrUnsummon(300)
  end
  m.kartGuid = nil; m.coinIcon = nil; m.rate = nil
end
local function dressKart(g, low, t)                         -- v2.0: a new kart gets back what the racer carries (coins, items, bar)
  local m = g.members[low]
  if not m then return end
  local pl, c = getPlayer(g, low), kartOf(g, m)
  if not (pl and c) then return end
  m.coinIcon = nil
  if (g.state == "racing" or g.state == "grid") and not m.finished then   -- live: the '0' coin floats on every kart from the countdown on
    coinIcon(m, c, t)
  end
  sendBar(g, m, pl, c, t)
end
local function board(g, low, pl, x, y, z, o, mode)          -- a fresh kart at x y z, player in it. mode: nil = by race state, 'park' = podium (held, no Automove), 'fall' = Automove comes back 2 s later (live 4:27-4:29)
  local m = g.members[low]
  local c = pl:SpawnCreature(E.KART, x, y, z + 0.3, o, TEMPSUMMON_TIMED_DESPAWN, KART_LIFE)
  if not c then log("could not spawn a kart (template " .. E.KART .. " missing? run the SQL)"); return false end
  m.kartGuid = c:GetGUID(); g.kartOwner[c:GetGUIDLow()] = low
  m.karts = (m.karts or 0) + 1
  log(string.format("diag: kart %d spawned for %s (slot %s, kart #%d this race, state %s%s)", c:GetGUIDLow(), pl:GetName(), tostring(m.slot), m.karts, tostring(g.state), mode and (", " .. mode) or ""))
  try(c, "SetDisplayId", KART_LOOKS[m.slot] or KART_LOOKS[1])
  try(c, "SetSpeed", 1, RR.SPEED, true)
  local kit = c:GetVehicleKit()
  if not kit then log("the kart has no vehicle kit (VehicleId missing in creature_template " .. E.KART .. "?)"); return false end
  if mode == "park" then hold(c, true)
  elseif g.state ~= "racing" then hold(c, true, true)
  elseif RR.AUTOMOVE then
    if mode == "fall" then
      later(m.guid, 2000, function() local c2 = Games[g.inst] == g and g.members[low] and not g.members[low].finished and kartOf(g, g.members[low]); if c2 then automoveOn(g.members[low], c2) end end)
    else automoveOn(m, c) end
  end
  if m.bot then try(pl, "RemoveAura", S.STUN); m.freezeAt = now() + 1500 end   -- v2.3.5: a stunned bot cannot climb in
  pl:CastSpell(c, S.RIDE, true)
  if not kit:GetPassenger(0) then try(kit, "AddPassenger", pl, 0) end
  local pas = kit:GetPassenger(0)
  local seated = pas and pas:GetGUIDLow() == low
  log("diag: " .. pl:GetName() .. (seated and " seated in kart " or " NOT seated in kart ") .. c:GetGUIDLow())
  for _, ms in ipairs({ 600, 1800 }) do                      -- the core sends its own bar when you sit down: ours goes after it
    later(m.guid, ms, function() if Games[g.inst] == g then dressKart(g, low, now()) end end)
  end
  return seated
end
local sendHome                                              -- defined below, used by the safety stop
local function putBack(g, low, pl, i, why)                  -- back on the centre line at point i (new kart)
  local m = g.members[low]
  m.putBacks = (m.putBacks or 0) + 1
  log(string.format("diag: putBack #%d for %s at point %d (%s)", m.putBacks, pl:GetName(), i, tostring(why)))
  if m.putBacks > RR.MAX_PUTBACKS then                       -- safety: never keep stacking karts
    log("SAFETY STOP: " .. pl:GetName() .. " needed " .. m.putBacks .. " new karts, race stopped for them")
    pl:SendBroadcastMessage(RT .. "Kart trouble! The race is stopped for you (logged for Claude).")
    m.finished = true; sendHome(g, low)
    return
  end
  local p, h = TRACK[i], heading(i)
  local t = now()
  m.bbUntil = 0; m.nitroUntil = 0; m.stunUntil = nil; m.shrinkUntil = 0; m.shrunk = nil; m.px = nil
  dropKart(g, low, pl)
  m.busyUntil = t + 3000
  pl:NearTeleport(p[1], p[2], p[3] + 0.5, h)
  later(m.guid, 700, function(p2)
    if Games[g.inst] == g and g.members[low] and not g.members[low].finished and inGame(g, p2) then board(g, low, p2, p[1], p[2], p[3], h, "fall") end
  end)
end

-- ---------- leaving ----------
sendHome = function(g, low)
  local m = g.members[low]
  local pl = getPlayer(g, low)
  if not (m and pl) then return end
  dropKart(g, low, pl)
  music(pl, 0)
  if m.bot then m.freezeOff = true; try(pl, "RemoveAura", S.STUN) end   -- v2.3.5
  if m.bot and RR.BOT_STAY then                              -- v2.3.7: back to following its player
    for low2, m2 in pairs(g.members) do
      local boss = not m2.bot and GetPlayerByGUID(m2.guid)
      if boss then try(boss, "Whisper", "follow", 0, pl); break end
    end
  end
  local h = m.home or RR.FAIRE_SPOT
  later(m.guid, 600, function(p) if p:GetMapId() == RR.MAP then p:Teleport(h[1], h[2], h[3], h[4], h[5]) end end)
end
local function dropHost(g)                                  -- the grid Brumm goes when the race starts or ends
  if not g.hostGuid then return end
  despawn(g, g.hostGuid)
  g.hostGuid = nil
end
local function dropProps(g)                                 -- v2.0: boxes, coins, traps, firework launchers, the portal
  for _, b in ipairs(g.boxes or {}) do despawn(g, b.guid); despawn(g, b.fallGuid) end
  for _, c in ipairs(g.coins or {}) do despawn(g, c.guid) end
  for _, h in ipairs(g.hazards or {}) do despawn(g, h.guid) end
  for _, guid in ipairs(g.launchers or {}) do despawn(g, guid) end
  if g.portalGuid then despawn(g, g.portalGuid) end
  if g.podiumGuid then local o = obj(g, g.podiumGuid); if o then if not pcall(function() o:Despawn() end) then try(o, "RemoveFromWorld", false) end end; g.podiumGuid = nil end
  g.boxes, g.coins, g.hazards, g.launchers, g.portalGuid = {}, {}, {}, {}, nil
end
local function cleanup(g, why)
  dropHost(g)
  dropProps(g)
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then sendHome(g, low) else local c = kartOf(g, m); if c then c:DespawnOrUnsummon(0) end end
  end
  if g.inst then Games[g.inst] = nil end
  log("race closed (" .. tostring(why) .. ")")
end

-- ---------- v2.0: hits, traps, rockets ----------
local PLACE = { "1st", "2nd", "3rd", "4th", "5th" }
local function ranking(g)                                   -- lows in race order: finished first (by place), then by distance driven
  local list = {}
  for low, m in pairs(g.members) do list[#list + 1] = low end
  table.sort(list, function(a, b)
    local ma, mb = g.members[a], g.members[b]
    if ma.finished or mb.finished then
      if ma.finished and mb.finished then return (ma.place or 99) < (mb.place or 99) end
      return ma.finished == true
    end
    if (ma.prog or 0) ~= (mb.prog or 0) then return (ma.prog or 0) > (mb.prog or 0) end
    return (ma.slot or 0) < (mb.slot or 0)
  end)
  return list
end
local function rankOf(g, low)
  for i, l in ipairs(ranking(g)) do if l == low then return i end end
  return 1
end
local function hit(g, low, t, why)                          -- a kart is hit: -3 coins, boosts gone, stopped for a moment
  local m = g.members[low]
  if not m or m.finished or g.state ~= "racing" then return false end
  if t < (m.bbUntil or 0) or t < (m.immuneUntil or 0) then return false end   -- Obsidian Fury shrugs it off; no chain hits
  local c = kartOf(g, m)
  if c then try(c, "CastSpell", c, S.BOOM, true); hold(c, true) end
  m.stunUntil = t + RR.STUN_MS; m.immuneUntil = t + RR.STUN_MS + 1500
  m.nitroUntil = 0; m.padUntil = 0; m.slipUntil = 0
  loseCoins(g, m, c, t)
  m.hits = (m.hits or 0) + 1
  log(string.format("diag: %s hit by %s (coins now %d)", m.name, tostring(why), m.coins))
  return true
end
local function behind(c, dist)                              -- a spot 'dist' yd behind the kart
  local o = c:GetO()
  return c:GetX() - math.cos(o) * dist, c:GetY() - math.sin(o) * dist, c:GetZ()
end
local function dropHazard(g, low, c, kind, t)
  local x, y, z = behind(c, 4.5)
  local e = (kind == "tar") and E.TAR or E.BOMB
  local life = (kind == "tar") and 22000 or (kind == "mine" and 30000 or 3000)
  local s = spawn(g, e, x, y, z + 0.2, 0, life + 1000)
  if not s then return end
  if kind == "tar" then try(s, "AddAura", S.OIL, s)           -- the black puddle (live 'Oil Trap', 22 s)
  else try(s, "AddAura", S.GRENADE_VIS, s) end               -- the bomb model
  g.hazards[#g.hazards + 1] = { kind = kind, guid = s:GetGUID(), x = x, y = y, z = z, owner = low,
                                armAt = t + ((kind == "bomb") and 1000 or 1500), untilT = t + life }
end
local function explode(g, h, t, byName)                     -- a bomb goes off: everyone within 8 yd
  local s = obj(g, h.guid)
  if s then try(s, "RemoveAura", S.GRENADE_VIS); try(s, "CastSpell", s, S.BOOM, true); try(s, "DespawnOrUnsummon", 1200) end
  for low, m in pairs(g.members) do
    if m.x and (m.x - h.x) ^ 2 + (m.y - h.y) ^ 2 < 8 * 8 and math.abs(m.z - h.z) < 6 then hit(g, low, t, byName) end
  end
  h.dead = true
end
local function rocketAt(g, fromLow, toLow, missile, t, onHit)   -- a homing rocket: the live missile spell flies, the hit lands when it arrives
  local mf, mt = g.members[fromLow], g.members[toLow]
  local cf, ct = kartOf(g, mf), mt and kartOf(g, mt)
  if not (cf and ct) then return end
  try(cf, "CastSpell", ct, missile, true)
  local d = math.sqrt((mf.x - mt.x) ^ 2 + (mf.y - mt.y) ^ 2)
  after(g, math.max(400, math.min(5000, d / RR.ROCKET_SPEED * 1000)), function(t2) onHit(t2) end)
end
local CRIMSON_LINES = {                                       -- the four live callouts (1:09, 1:21, 1:38, 2:24)
  function(a, b) return a .. " tags [Crimson Rocket] as the unlucky target of " .. b .. "." end,
  function(a, b) return a .. " whispers to [Crimson Rocket]: \"" .. b .. " is coming for you.\"" end,
  function(a, b) return a .. " locks [Crimson Rocket] onto " .. b .. ". Homing chaos incoming!" end,
  function(a, b) return a .. " fires [Crimson Rocket] straight at " .. b .. ". Duck, weave, pray." end,
}
local STORM_LINES = {                                         -- live 2:49 and 4:44
  function(a) return "Track gossip: " .. a .. " fired [Lightning Storm] and turned the race into a kart daycare." end,
  function(a) return a .. " slams the red button for [Lightning Storm]. We are tiny and out of gadgets." end,
}
local FURY_LINES = {                                          -- live 5:06 and 5:24
  function(a) return a .. " strapped into [Obsidian Fury]--blink and you will miss them." end,
  function(a) return a .. " ignites [Obsidian Fury] and blasts down the lane at ludicrous speed." end,
}
local function pick(list) return list[math.random(#list)] end

-- use the item in slot 1. Returns true when something happened. gx,gy,gz = the Green Rocket's ground target (from the client)
local function useItem(g, low, t, gx, gy, gz)
  local m = g.members[low]
  if not m or m.finished or g.state ~= "racing" then return false end
  local key = m.items[1]
  local pl, c = getPlayer(g, low), kartOf(g, m)
  if not (key and pl and c) or t < (m.itemReadyAt or 0) or t < (m.stunUntil or 0) or t < (m.bbUntil or 0) then return false end
  local order = ranking(g)
  local myRank = 1
  for i, l in ipairs(order) do if l == low then myRank = i end end
  if key == "TARGET" then                                    -- Crimson Rocket: the kart ahead of you
    local tgt = order[myRank - 1]
    if not tgt or g.members[tgt].finished then pl:SendAreaTriggerMessage("|cffff2020No kart ahead of you.|r"); return false end
  elseif key == "FIRST" then                                 -- Sapphire Seeker: the leader
    local tgt = order[1]
    if tgt == low or g.members[tgt].finished then pl:SendAreaTriggerMessage("|cffff2020You are in the lead.|r"); return false end
  end
  table.remove(m.items, 1)
  holdIcon(c, ITEMS[key].icon, false)                        -- live float text: '<Icon: X> fades'
  m.used = (m.used or 0) + 1
  log(string.format("diag: %s uses %s (place %d)", m.name, ITEMS[key].name, myRank))
  if key == "ACC3" or key == "ACC2" or key == "ACC1" then
    local lvl = (key == "ACC3" and 3) or (key == "ACC2" and 2) or 1
    try(c, "AddAura", (lvl == 3 and S.NITRO3) or (lvl == 2 and S.NITRO2) or S.NITRO1, c)   -- the jet flames + '<Nitro Booster III>'
    m.nitroUntil = t + RR.NITRO_MS; m.nitroBonus = RR.NITRO[lvl]
    if lvl > 1 then                                          -- live: III leaves II in the slot, II leaves I, each ready 3 s later
      local nxt = (lvl == 3) and "ACC2" or "ACC1"
      table.insert(m.items, 1, nxt); holdIcon(c, ITEMS[nxt].icon, true)
      m.itemReadyAt = t + RR.STAGE_CD
    end
  elseif key == "OIL" then dropHazard(g, low, c, "tar", t)
  elseif key == "BOMB" then dropHazard(g, low, c, "bomb", t)
  elseif key == "STATIC" then                                -- Sonic Horn: a shockwave, karts within 12 m lose their boosts and half their speed for 2 s (OURS for 'pushed away')
    try(c, "CastSpell", c, S.HORN, true)
    for l2, m2 in pairs(g.members) do
      if l2 ~= low and m2.x and m.x and not m2.finished and (m2.x - m.x) ^ 2 + (m2.y - m.y) ^ 2 < RR.HORN_R ^ 2 and math.abs(m2.z - m.z) < 6 and t >= (m2.bbUntil or 0) then
        m2.stickyUntil = t + 2000; m2.nitroUntil = 0; m2.padUntil = 0; m2.slipUntil = 0
      end
    end
  elseif key == "TARGET" then
    local tgt = order[myRank - 1]
    race(g, pick(CRIMSON_LINES)(m.name, g.members[tgt].name))
    rocketAt(g, low, tgt, S.CRIMSON_MISSILE, t, function(t2) hit(g, tgt, t2, m.name .. "'s Crimson Rocket") end)
  elseif key == "FIRST" then
    local tgt = order[1]
    race(g, m.name .. " launches [Sapphire Seeker Rocket] at the leader, " .. g.members[tgt].name .. ".")   -- OURS: no live callout seen for this one
    local ct = kartOf(g, g.members[tgt]); if ct then try(ct, "AddAura", S.SAPPHIRE_MARK, ct) end
    rocketAt(g, low, tgt, S.SAPPHIRE_MISSILE, t, function(t2)
      if hit(g, tgt, t2, m.name .. "'s Sapphire Seeker Rocket") then g.members[tgt].stickyUntil = t2 + 3000 end   -- 'significantly slowing them down'
    end)
  elseif key == "MORTAR" then                                -- Green Rocket: lands where you aimed (or 3 points up the road)
    if not gx then local p = TRACK[wrap(m.idx + 3 * RR.DIR)]; gx, gy, gz = p[1], p[2], p[3] end
    try(c, "CastSpellAoF", gx, gy, gz, S.GREEN, true)
    local d = math.sqrt((c:GetX() - gx) ^ 2 + (c:GetY() - gy) ^ 2)
    after(g, math.max(400, math.min(5000, d / 100 * 1000)), function(t2)
      local n = 0
      for l2, m2 in pairs(g.members) do
        if l2 ~= low and m2.x and (m2.x - gx) ^ 2 + (m2.y - gy) ^ 2 < 7 * 7 and math.abs(m2.z - gz) < 8 and hit(g, l2, t2, m.name .. "'s Green Rocket") then n = n + 1 end
      end
      if n >= 2 then giveAch(getPlayer(g, low), ACH.AIM) end
    end)
  elseif key == "SHRINK" then                                -- Lightning Storm: everyone ahead of you
    try(c, "CastSpell", c, S.STORM, true)
    race(g, pick(STORM_LINES)(m.name))
    for i = 1, myRank - 1 do
      local l2 = order[i]; local m2 = g.members[l2]
      if not m2.finished and t >= (m2.bbUntil or 0) then
        local c2 = kartOf(g, m2)
        if c2 then try(c2, "AddAura", S.SPARK, c2); try(c2, "SetScale", RR.SHRINK_SCALE) end
        m2.shrinkUntil = t + RR.SHRINK_MS; m2.shrunk = true
        loseCoins(g, m2, c2, t)
        clearItems(g, l2, t)
      end
    end
  elseif key == "BULLET" then                                -- Obsidian Fury
    try(c, "CastSpell", c, S.FURY, true)
    try(c, "SetDisplayId", RR.BULLET_DISPLAY); try(c, "SetScale", RR.BULLET_SCALE)
    if m.shrunk then try(c, "RemoveAura", S.SPARK); m.shrunk = nil; m.shrinkUntil = 0 end
    m.bbUntil = t + RR.BULLET_MS; m.bb = true; m.bbMoveAt = 0
    race(g, pick(FURY_LINES)(m.name))
  end
  sendBar(g, m, pl, c, t)
  return true
end
local function horn(g, low, t)                               -- button 5, the Klaxon: just a loud honk (live: 'Triggers a loud horn sound during the race')
  local m = g.members[low]
  if not m or m.finished or g.state ~= "racing" or t < (m.hornAt or 0) then return false end
  local pl, c = getPlayer(g, low), kartOf(g, m)
  if not c then return false end
  try(c, "CastSpell", c, S.KLAXON, true)
  m.hornAt = t + RR.HORN_CD
  for l2, m2 in pairs(g.members) do                          -- everyone within 60 yd hears it
    if l2 == low or (m2.x and m.x and (m2.x - m.x) ^ 2 + (m2.y - m.y) ^ 2 < 60 * 60) then sound(getPlayer(g, l2), SND.KLAXON) end
  end
  sendBar(g, m, pl, c, t)
  return true
end

-- ---------- v2.0: boxes and coins on the road ----------
local function showBox(s, on)
  if not s then return end
  if RR.BOX_MODE == "display" then try(s, "SetDisplayId", on and 137670 or 11686)
  elseif on then try(s, "AddAura", S.BOX_VIS, s) else try(s, "RemoveAura", S.BOX_VIS) end
end
local function makeBox(g, b, zAdd)                           -- the creature of one box (again after every pick-up)
  local s = spawn(g, E.BOX, b.x, b.y, b.z + RR.BOX_UP + (zAdd or 0), 0)
  if not s then b.guid = nil; return nil end
  showBox(s, true)
  b.guid = s:GetGUID()
  return s
end
local function spawnBox(g, i)
  local d = BOXES[i]
  local b = { x = d[1], y = d[2], z = d[3], idx = d[4] }
  makeBox(g, b)
  g.boxes[#g.boxes + 1] = b
end
local function planDrops(g, t)                               -- row 1: five boxes glide down in a random order and all stand on the road as the countdown ends
  local total = RR.COUNTDOWN * 1000
  for i, d in ipairs(BOXES) do
    if d[5] == 1 then
      local dur = 2000 + math.random() * 1500
      local land = t + total - 300 - math.random() * 1200    -- between 1.5 and 0.3 s before GO
      g.boxes[#g.boxes + 1] = { x = d[1], y = d[2], z = d[3], idx = d[4], dropAt = land - dur, landAt = land, falling = true }
    end
  end
end
local function spawnPickups(g)                               -- at 'Round 1 is starting!': the coins and box rows 2-7 (row 1 falls in during the countdown)
  g.boxes, g.coins = {}, {}
  for i, b in ipairs(BOXES) do if b[5] ~= 1 then spawnBox(g, i) end end
  planDrops(g, now())
  for i, cn in ipairs(COINS) do
    local s = spawn(g, E.COIN, cn[1], cn[2], cn[3] + RR.COIN_UP, 0)
    if s then
      try(s, "AddAura", S.COIN_VIS, s)
      g.coins[#g.coins + 1] = { guid = s:GetGUID(), x = cn[1], y = cn[2], z = cn[3], idx = cn[4] }
    end
  end
  log(string.format("v2.0: %d boxes + %d coins on the road (row 1 drops in during the countdown)", #g.boxes, #g.coins))
end
local function sweepProps(g)                                 -- leftovers of earlier races on this map
  local _, pl = mapOf(g)
  if not pl then return end
  local n = 0
  for _, go in pairs(try(pl, "GetGameObjectsInRange", 1500, E.PODIUM_GO) or {}) do if not pcall(function() go:Despawn() end) then try(go, "RemoveFromWorld", false) end; n = n + 1 end
  for _, e in ipairs({ E.BOX, E.COIN, E.TAR, E.BOMB, E.CTRL, E.PORTAL, E.PORTAL_OLD, 840178 }) do
    for _, c in pairs(try(pl, "GetCreaturesInRange", 1500, e) or {}) do
      if c:GetX() < -1000 then c:DespawnOrUnsummon(0); n = n + 1 end   -- only on the race track (99652 is also Vertical Ascent's portal)
    end
  end
  if n > 0 then log("v2.0: removed " .. n .. " leftover box/coin/trap helper(s) from earlier races") end
end
local function tickProps(g, t)                               -- respawns, falling boxes, bombs on a fuse
  for _, b in ipairs(g.boxes) do
    if b.falling then
      if b.dropAt and t >= b.dropAt then                     -- appears high up on a flying helper and glides down (a real move, not steps)
        local secs = math.max(0.5, (b.landAt - t) / 1000)
        local s = spawn(g, E.FALLER, b.x, b.y, b.z + RR.BOX_UP + RR.BOX_DROP, 0, 20000)
        if s then
          try(s, "RemoveAura", 255651)                       -- v2.1.5: the helper is Duck Hunt's bomb: take off its bomb look (template aura), red hostile name and click box
          try(s, "SetFaction", 35); try(s, "SetUnitFlags", 33554434)
          showBox(s, true)
          local rate = (RR.BOX_DROP / secs) / 7
          try(s, "SetDisableGravity", true)
          try(s, "SetSpeed", 6, rate, true); try(s, "SetSpeed", 1, rate, true); try(s, "SetSpeed", 0, rate * 2.8, true)
          try(s, "MoveTo", 1, b.x, b.y, b.z + RR.BOX_UP, false)
          b.fallGuid = s:GetGUID()
        end
        b.dropAt = nil
      elseif not b.dropAt and t >= b.landAt then             -- landed: the real box takes its place
        b.falling = nil
        despawn(g, b.fallGuid); b.fallGuid = nil
        makeBox(g, b)
      end
    elseif b.upAt and t >= b.upAt then b.upAt = nil; makeBox(g, b) end
  end
  for _, cn in ipairs(g.coins) do
    if cn.upAt and t >= cn.upAt then                         -- v2.1: a fresh coin (the taken one was removed)
      cn.upAt = nil
      local s = spawn(g, E.COIN, cn.x, cn.y, cn.z + RR.COIN_UP, 0)
      if s then try(s, "AddAura", S.COIN_VIS, s); cn.guid = s:GetGUID() end
    end
  end
  local keep = {}
  for _, h in ipairs(g.hazards) do
    if not h.dead and h.kind == "bomb" and t >= h.armAt then explode(g, h, t, "a Rear Grenade") end
    if not h.dead and t >= h.untilT then h.dead = true; despawn(g, h.guid) end
    if not h.dead then keep[#keep + 1] = h end
  end
  g.hazards = keep
  if #g.timers > 0 then
    local todo, rest = {}, {}
    for _, tm in ipairs(g.timers) do if t >= tm.at then todo[#todo + 1] = tm else rest[#rest + 1] = tm end end
    g.timers = rest
    for _, tm in ipairs(todo) do local ok, err = pcall(tm.fn, t); if not ok then log("timer error: " .. tostring(err)) end end
  end
end
local function tickPickups(g, low, m, c, t, i, x, y, z)      -- what this kart drove over since the last tick
  local px, py = m.px or x, m.py or y
  if (px - x) ^ 2 + (py - y) ^ 2 > 60 * 60 then px, py = x, y end   -- it was teleported
  if t >= (m.stunUntil or 0) then                            -- v2.1.3: look one tick AHEAD, so a box is gone as you reach it (not 7 yd after you drove through)
    local o, reach = c:GetO(), (m.rate or RR.SPEED) * 7 * 0.3
    x, y = x + math.cos(o) * reach, y + math.sin(o) * reach
  end
  if not m.roll and #m.items < 2 then
    for _, b in ipairs(g.boxes) do
      if not b.upAt and not b.falling and near(b.idx, i, 2) and math.abs(b.z - z) < 7 and segDist2(b.x, b.y, px, py, x, y) < RR.BOX_R ^ 2 then
        b.upAt = t + RR.BOX_RESPAWN
        local found = obj(g, b.guid) ~= nil
        despawn(g, b.guid); b.guid = nil                     -- the box is GONE when you drive through it
        local extra = zap(g, low, E.BOX, b.x, b.y, 2.5)
        if (m.boxes or 0) < 3 then log(string.format("diag: %s took a box at point %d (its creature %s, sweep removed %d more)", m.name, b.idx, found and "found + removed" or "NOT FOUND", extra)) end
        m.roll = { untilT = t + RR.ROLL_MS, step = 0, n = 0, key = rollItem(g, low) }
        local pl = getPlayer(g, low); sound(pl, SND.PICKUP); sound(pl, SND.ROLL)
        m.boxes = (m.boxes or 0) + 1
        break
      end
    end
  end
  for _, cn in ipairs(g.coins) do
    if not cn.upAt and near(cn.idx, i, 2) and math.abs(cn.z - z) < 7 and segDist2(cn.x, cn.y, px, py, x, y) < RR.COIN_R ^ 2 then
      cn.upAt = t + RR.COIN_RESPAWN
      despawn(g, cn.guid); cn.guid = nil
      zap(g, low, E.COIN, cn.x, cn.y, 2.0)
      addCoin(g, m, c, t)
    end
  end
  for _, h in ipairs(g.hazards) do
    if not h.dead and (h.kind == "tar" or h.kind == "mine") and (h.owner ~= low or t >= h.armAt) and math.abs(h.z - z) < 6
       and segDist2(h.x, h.y, px, py, x, y) < 3.2 * 3.2 then
      if h.kind == "mine" then explode(g, h, t, "a Static Bomb")
      elseif t >= (m.stickyUntil or 0) and t >= (m.bbUntil or 0) then   -- the tar: 'Sticky Trap'
        m.stickyUntil = t + RR.STICKY_MS; m.nitroUntil = 0
        try(c, "AddAura", S.STICKY, c)
      end
    end
  end
  if m.roll then                                             -- the roll: a new live icon every half second, each stays its full 2 s, then the item lands in the slot
    local r = m.roll
    if t >= r.untilT then
      m.roll = nil
      if r.step > 0 then try(c, "RemoveAura", ROLL_ICONS[r.step]) end
      giveItem(g, low, r.key, t)
    else
      r.n = r.n + 1
      if r.n % 2 == 1 then                                   -- v2.1.2: ONE icon at a time, half a second each (live: '<Icon: X>' / '<Icon: X> fades' in turn), so the stack no longer covers the coin
        if r.step > 0 then try(c, "RemoveAura", ROLL_ICONS[r.step]) end
        r.step = (r.step % #ROLL_ICONS) + 1
        try(c, "AddAura", ROLL_ICONS[r.step], c)
      end
    end
  end
end
local function tickEffects(g, low, m, pl, c, t, i, x, y, z)  -- pads, slipstream, stuns wearing off, Obsidian Fury
  if m.stunUntil and t >= m.stunUntil then m.stunUntil = nil; hold(c, false) end
  if m.shrunk and t >= (m.shrinkUntil or 0) then m.shrunk = nil; try(c, "RemoveAura", S.SPARK); try(c, "SetScale", 1) end
  if m.coinIcon == S.COIN_SPEED and t >= (m.coinSpeedUntil or 0) then coinIcon(m, c, t) end   -- back to 'Coin 10'
  if t >= (m.padUntil or 0) then                             -- arrow tiles (live 'Acceleration Zone')
    for _, p in ipairs(PADS) do
      if near(p[4], i, 2) and (p[1] - x) ^ 2 + (p[2] - y) ^ 2 < RR.PAD_RADIUS ^ 2 and math.abs(p[3] - z) < 5 then
        try(c, "AddAura", S.ACCEL_ZONE, c)
        if not m.padLogged then m.padLogged = true; log(string.format("diag: %s hit a speed panel at track point %d", m.name, p[4])) end
        m.padUntil = t + RR.PAD_BOOST_MS
        break
      end
    end
  end
  local h = heading(i)                                       -- slipstream: close behind another kart, in its line
  local hx, hy = math.cos(h), math.sin(h)
  local drafting = false
  for l2, m2 in pairs(g.members) do
    if l2 ~= low and m2.x and not m2.finished then
      local dx, dy = m2.x - x, m2.y - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d > 3 and d < RR.SLIP_DIST and math.abs(m2.z - z) < 4 and (dx * hx + dy * hy) / d > 0.92 then drafting = true; break end
    end
  end
  if drafting then
    m.slipSince = m.slipSince or t
    if t - m.slipSince >= RR.SLIP_AFTER then
      if t >= (m.slipUntil or 0) then                        -- a new draft
        try(c, "AddAura", S.SLIP, c)
        m.drafts = (m.drafts or 0) + 1
        if m.drafts == 3 then giveAch(pl, ACH.DRAFT) end
      end
      m.slipUntil = t + 1500
    end
  else m.slipSince = nil end
  if m.bb then                                               -- Obsidian Fury: flies itself, flattens what it touches
    if t >= (m.bbUntil or 0) then
      m.bb = nil
      try(c, "SetDisplayId", KART_LOOKS[m.slot] or KART_LOOKS[1]); try(c, "SetScale", 1)
    else
      if RR.BB_AUTOPILOT and t >= (m.bbMoveAt or 0) then
        local p = TRACK[wrap(i + 2 * RR.DIR)]
        try(c, "MoveTo", 0, p[1], p[2], p[3] + 0.3, false)
        m.bbMoveAt = t + 500
      end
      for l2, m2 in pairs(g.members) do
        if l2 ~= low and m2.x and (m2.x - x) ^ 2 + (m2.y - y) ^ 2 < 5 * 5 and math.abs(m2.z - z) < 5 then hit(g, l2, t, m.name .. "'s Obsidian Fury") end
      end
    end
  end
  applySpeed(g, m, c, t)
end

-- ---------- the race ----------
local function standings(g)                                  -- the live block
  local order = ranking(g)
  race(g, "===== Race Standings =====")
  for i, low in ipairs(order) do
    local m = g.members[low]
    local line = string.format("%s %s (Lap %d/%d)", PLACE[i] or ("#" .. i), m.name, math.min(RR.LAPS, (m.laps or 0) + 1), RR.LAPS)
    if i > 1 and not m.finished then                         -- live shows the gap only when it is small: '(-1m vs 1st)'
      local a = g.members[order[i - 1]]
      local gap = math.floor(((a.prog or 0) - (m.prog or 0)) * 12 * 0.9144 + 0.5)
      if not a.finished and gap >= 1 and gap < 10 then line = line .. string.format(" (-%dm vs %s)", gap, PLACE[i - 1]) end
    end
    race(g, line)
  end
  race(g, "---------------")
end
local function tickOrder(g, t)                               -- 'X passed Y!' + the standings block
  if not g.order then g.order = ranking(g); return end
  if g.firstBlockAt and t >= g.firstBlockAt then g.firstBlockAt = nil; g.blockAt = t; standings(g) end
  local o = g.order
  for k = #o, 1, -1 do if not g.members[o[k]] then table.remove(o, k) end end
  for k = 2, #o do
    local a, b = g.members[o[k]], g.members[o[k - 1]]         -- a is behind b in the list
    if not a.finished and not b.finished and (a.prog or 0) > (b.prog or 0) + 0.4 then
      o[k], o[k - 1] = o[k - 1], o[k]
      if t >= (g.blockAt or 0) + 4000 then
        g.blockAt = t
        race(g, a.name .. " passed |cffff2020" .. b.name .. "|r!")
        standings(g)
      end
      break
    end
  end
end
local function removePodium(g)
  local o = g.podiumGuid and obj(g, g.podiumGuid)
  if o then if not pcall(function() o:Despawn() end) then try(o, "RemoveFromWorld", false) end end
  g.podiumGuid = nil
end
local function ensurePodium(g, pl)                           -- v2.2: the podium appears at the first finish
  if g.podiumTried then return end
  g.podiumTried = true
  local s = PODIUM_GO_SPOT
  local ok, go = pcall(function() return pl:SummonGameObject(E.PODIUM_GO, s[1], s[2], s[3], s[4], 600) end)
  if ok and go then g.podiumGuid = go:GetGUID(); log("v2.2: podium up")
  else log("v2.2: no podium object (run Azzar-Rainbow-Race-Podium-Apply.bat + restart): parking on the road instead") end
end
local function finish(g, low, pl, t)
  local m = g.members[low]
  m.finished = true; m.finishedAt = t
  g.finishedCount = g.finishedCount + 1
  local place = g.finishedCount
  m.place = place
  if place == 1 then g.firstAt = t end
  g.lastFinishAt = t
  if place == 1 then race(g, "Winner: " .. m.name)
  elseif place == 2 then race(g, "Second place: " .. m.name)
  elseif place == 3 then race(g, "Third place: " .. m.name) end
  log(string.format("%s finished %s in %s, falls %d, coins taken %d, boxes %d, items used %d, hits taken %d", m.name, PLACE[place] or place, clock(t - g.startedAt), m.falls, m.coinsTaken or 0, m.boxes or 0, m.used or 0, m.hits or 0))
  clearItems(g, low, t)
  if not m.bot then                                          -- v2.3: bots race for fun, no rewards
    try(pl, "AddItem", ITEM_TICKET, place == 1 and RR.WIN_TICKETS or RR.TICKETS)
    if place == 1 and RR.WIN_RUNES > 0 then try(pl, "AddItem", ITEM_RUNE, RR.WIN_RUNES) end
    giveAch(pl, ACH.FIRST_MATCH)
    if m.falls == 0 then giveAch(pl, ACH.SAFE_ROAD) end
    if place == 1 and g.count >= 2 then giveAch(pl, ACH.WINNER) end
    if pl:HasQuest(Q_BASE) or pl:HasQuest(Q_DAILY) then pl:KilledMonsterCredit(E.CREDIT) end
  end
  -- live: the kart is parked on the podium right away, everybody stays seated for the fireworks
  ensurePodium(g, pl)
  local sp = g.podiumGuid and (PODIUM_STEPS[place] or PODIUM_STEPS[#PODIUM_STEPS]) or (PODIUM[place] or PODIUM[#PODIUM])
  dropKart(g, low, pl)
  m.busyUntil = t + 3000
  pl:NearTeleport(sp[1], sp[2], sp[3] + 0.5, sp[4])
  later(m.guid, 700, function(p2)
    if Games[g.inst] == g and g.members[low] and inGame(g, p2) and (g.state == "racing" or g.state == "podium") then board(g, low, p2, sp[1], sp[2], sp[3], sp[4], "park") end
  end)
end
local function nearest(m, x, y, z)
  local best, bd
  for k = -RR.WINDOW, RR.WINDOW do
    local i = wrap(m.idx + k)
    local p = TRACK[i]
    local dx, dy, dz = p[1] - x, p[2] - y, (p[3] - z) * 2
    local d = dx * dx + dy * dy + dz * dz
    if not bd or d < bd then best, bd = i, d end
  end
  local p = TRACK[best]
  return best, math.sqrt((p[1] - x) ^ 2 + (p[2] - y) ^ 2)
end
-- ---------- v2.3: bot drivers ----------
local function botBand(g, m)                                 -- rubber band against the leading PLAYER (bots can still win)
  local lead
  for _, m2 in pairs(g.members) do
    if not m2.bot and not m2.finished and (not lead or (m2.prog or 0) > lead) then lead = m2.prog or 0 end
  end
  if not lead then return 1 end
  local d = (m.prog or 0) - lead                             -- track points (12 yd) ahead (+) or behind (-) the leading player
  if d > 8 then return 0.90 elseif d > 3 then return 0.96 elseif d < -12 then return 1.08 elseif d < -5 then return 1.03 end
  return 1
end
local function botLaneFor(g, m, i)                           -- aim the lane at a box on the next few rows, else drift
  if not m.roll and #m.items < 2 then
    local best
    for _, b in ipairs(g.boxes or {}) do
      if not b.upAt and not b.falling then
        local d = ((b.idx - i) * RR.DIR + HALF) % N - HALF      -- points ahead of the bot along the race
        if d >= 2 and d <= 7 and (not best or d < best.d) then best = { d = d, b = b } end
      end
    end
    if best and math.random() < 0.85 then
      local p, h = TRACK[best.b.idx], heading(best.b.idx)
      local side = -(best.b.x - p[1]) * math.sin(h) + (best.b.y - p[2]) * math.cos(h)
      return math.max(-RR.BOT_LANE, math.min(RR.BOT_LANE, side))
    end
  end
  return (math.random() * 2 - 1) * RR.BOT_LANE
end
local function tickBot(g, low, m, c, t, i)
  if not c or m.finished or g.state ~= "racing" then return end
  if t < (m.stunUntil or 0) or t < (m.busyUntil or 0) then m.tx = nil; return end
  if not m.botSkill then m.botSkill = 0.92 + math.random() * 0.08 end
  if t >= (m.bandAt or 0) then m.botBand = botBand(g, m); m.bandAt = t + 4000 end   -- v2.3.4: was every tick (it flipped at its thresholds)
  if not m.lane then m.lane = RR.GRID_SIDE[((m.slot - 1) % #RR.GRID_SIDE) + 1]; m.laneWant = m.lane end
  if t >= (m.laneAt or 0) then m.laneWant = botLaneFor(g, m, i); m.laneAt = t + math.random(1500, 3500) end
  -- items: use what it holds after 1-4 s (Crimson / Sapphire wait until someone is ahead)
  if m.items[1] and not m.roll and t >= (m.itemReadyAt or 0) then
    if not m.botUseAt then m.botUseAt = t + math.random(1000, 4000)
    elseif t >= m.botUseAt then
      m.botUseAt = nil
      if not useItem(g, low, t) then m.botUseAt = t + 3000 end
    end
  end
  local step = 1.2                                           -- yd per tick the lane slides (no hard swerves)
  if m.laneWant > m.lane then m.lane = math.min(m.laneWant, m.lane + step) else m.lane = math.max(m.laneWant, m.lane - step) end
  -- v2.3.1: a new path only every ~0.9 s (or when the kart is close to its target / its speed changed): every 250 ms looked like a
  -- slide show on the player's screen (each new path restarts the kart's movement on the client). Straights aim further ahead.
  local far = RR.BOT_LOOK + 3
  local hd = math.abs(((heading(wrap(i + far * RR.DIR)) - heading(i) + math.pi) % (2 * math.pi)) - math.pi)
  local look = (hd < 0.35) and far or RR.BOT_LOOK              -- under ~20 degrees of bend: look 6 points (72 yd) ahead, else 4 (48 yd)
  if t < (m.bbUntil or 0) then look = look + 1 end
  if RR.BOT_ROADPATH then look = 10 end                      -- v2.3.4 experiment: one long path that follows the road
  local cx, cy = c:GetX(), c:GetY()
  if RR.BOT_DIAG and g.diagLow == nil then g.diagLow = low end
  if RR.BOT_DIAG and g.diagLow == low then               -- v2.3.2 '#rr botdiag': is the SERVER moving the kart smoothly? (7 yd a tick at full speed)
    local mv = m.dx and math.sqrt((cx - m.dx) ^ 2 + (cy - m.dy) ^ 2) or 0
    log(string.format("botdiag %s t %d at %.1f %.1f moved %.1f yd rate %.2f point %d lane %.1f", m.name, t % 100000, cx, cy, mv, m.rate or 0, i, m.lane))
  end
  m.dx, m.dy = cx, cy
  -- v2.3.3: the server only refreshes a moving kart's position every ~0.4-0.6 s (botdiag 21:07: 0 yd, then 15-20 yd), so 'close to the
  -- target' was missed and the kart reached the end of its path and STOPPED until the next one = stop-go = the slide show.
  -- Now the path is timed: a new one goes out ~0.8 s BEFORE the kart would arrive (or after 2.5 s / a 15 % speed change).
  local close = m.tx and t >= (m.pathEnd or 0) - RR.BOT_EARLY_MS
  if m.tx and t < (m.moveAt or 0) and not close then return end   -- v2.3.4: a speed change clears m.tx itself (applySpeed)
  local j = wrap(i + look * RR.DIR)
  local p, h = TRACK[j], heading(j)
  local tx, ty = p[1] - math.sin(h) * m.lane, p[2] + math.cos(h) * m.lane
  try(c, "MoveTo", 0, tx, ty, p[3] + 0.3, RR.BOT_ROADPATH == true)
  if RR.BOT_DIAG and g.diagLow == low then log(string.format("botdiag %s NEW PATH to %.1f %.1f (%.0f yd ahead, look %d)", m.name, tx, ty, math.sqrt((tx - cx) ^ 2 + (ty - cy) ^ 2), look)) end
  local yds = (m.rate or RR.SPEED) * 7
  local dist = math.sqrt((tx - cx) ^ 2 + (ty - cy) ^ 2)
  if RR.BOT_ROADPATH then dist = math.max(dist, look * 12 * 0.9) end   -- along the road, not as the crow flies
  m.pathEnd = t + dist / yds * 1000
  m.tx, m.ty, m.moveAt, m.moveRate = tx, ty, t + (RR.BOT_ROADPATH and 6000 or RR.BOT_PATH_MS), m.rate
end
local function botWhisper(g, text, only)                     -- v2.3 '#rr botstay': the first real player tells the bots (only = one bot's low guid)
  if not RR.BOT_STAY then return end
  local boss
  for low, m in pairs(g.members) do if not m.bot then boss = getPlayer(g, low); if boss then break end end end
  if not boss then return end
  for low, m in pairs(g.members) do
    if m.bot and (only == nil or only == low) then local b = getPlayer(g, low); if b then try(boss, "Whisper", text, 0, b) end end
  end
  if not only then log("v2.3: told the bots '" .. text .. "'") end
end
local function tickRacer(g, low, m, t)
  local pl = getPlayer(g, low)
  if not inGame(g, pl) then                                 -- left the map / logged out (not while everyone is still loading in)
    if g.state == "arriving" then return end
    if t > (m.goneSince or t) + 15000 then
      local c = kartOf(g, m); if c then c:DespawnOrUnsummon(0) end
      g.members[low] = nil; g.count = math.max(0, g.count - 1)
      log(m.name .. " left the race")
    end
    m.goneSince = m.goneSince or t
    return
  end
  m.goneSince = nil
  if m.finished or g.state ~= "racing" or t < (m.busyUntil or 0) then return end
  local x, y, z = pl:GetX(), pl:GetY(), pl:GetZ()
  if m.bot then local ck = kartOf(g, m); if ck then x, y, z = ck:GetX(), ck:GetY(), ck:GetZ() end end   -- v2.3: the kart is where the bot is
  local i, d = nearest(m, x, y, z)
  if d > RR.OFF_DIST or z < TRACK[i][3] - RR.FALL_BELOW then
    m.falls = m.falls + 1
    pl:SendAreaTriggerMessage("Back on the track!")
    loseCoins(g, m, nil, t)                                  -- live 4:27: a fall costs 3 coins too
    putBack(g, low, pl, m.idx, string.format("off track: %.0f yd from the line, z %.1f vs track %.1f", d, z, TRACK[i][3]))
    return
  end
  local c = kartOf(g, m)
  if not c then                                             -- kart lost (despawned / got out): a new one where they stand
    putBack(g, low, pl, i, m.kartGuid and "kart lookup failed (map lookup returned nothing)" or "no kart recorded"); m.idx = i
    return
  end
  local ok, err = pcall(tickPickups, g, low, m, c, t, i, x, y, z)
  if not ok then log("pickup error: " .. tostring(err)) end
  ok, err = pcall(tickEffects, g, low, m, pl, c, t, i, x, y, z)
  if not ok then log("effect error: " .. tostring(err)) end
  if m.bot then
    ok, err = pcall(tickBot, g, low, m, c, t, i)
    if not ok and not m.botErr then m.botErr = true; log("bot error: " .. tostring(err)) end
  end
  m.px, m.py = x, y
  m.x, m.y, m.z = x, y, z
  local delta = ((i - m.idx + HALF) % N) - HALF
  m.total = m.total + delta * RR.DIR
  m.idx = i
  local a, b = TRACK[i], TRACK[wrap(i + RR.DIR)]             -- how far along this 12 yd piece (for places and gaps)
  local sx, sy = b[1] - a[1], b[2] - a[2]
  local f = ((x - a[1]) * sx + (y - a[2]) * sy) / (sx * sx + sy * sy)
  if f < -0.5 then f = -0.5 elseif f > 0.5 then f = 0.5 end
  m.prog = m.total + f
  local laps = math.floor(m.total / N)
  if laps > m.laps then
    m.laps = laps
    local lapMs = t - m.lapStart; m.lapStart = t
    race(g, string.format("%s completed lap %d/%d in %s", m.name, laps, RR.LAPS, clock(lapMs)))
    if not g.bestLap or lapMs < g.bestLap then g.bestLap = lapMs; race(g, string.format("%s set the best lap: %s", m.name, clock(lapMs))) end
    if laps >= RR.LAPS then finish(g, low, pl, t)
    elseif laps == RR.LAPS - 1 then race(g, m.name .. " is on the final lap!") end
  end
end
local function spawnHost(g, pl)                             -- the grid Brumm, there the moment the first racer lands
  local bx, by, gz, bo = RR.HOST[1], RR.HOST[2], RR.HOST[3], RR.HOST[4]   -- Rowan's .gps
  for _, old in pairs(try(pl, "GetCreaturesInRange", 1500, E.BRUMM) or {}) do old:DespawnOrUnsummon(0) end   -- an earlier race's Brumm
  local b = pl:SpawnCreature(E.BRUMM, bx, by, gz, bo, TEMPSUMMON_TIMED_DESPAWN, RR.LOBBY_MAX + 180000)
  if b then g.hostGuid = b:GetGUID(); try(b, "Mount", 137865)   -- on the red Azzar rocket (wowhead_rocket_mount red), like live
    log(string.format("grid Brumm at %.1f %.1f %.1f (grid point %d)", bx, by, gz, select(5, gridSpot(1))))
  else log("could not spawn the grid Brumm") end
end
local function toPodiumEnd(g, t)                             -- live 6:15: karts gone, everyone on foot on the grid, the portal behind the start row
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      dropKart(g, low, pl)
      local x, y, z, o = gridSpot(m.slot)
      later(m.guid, 500, function(p2) if Games[g.inst] == g and inGame(g, p2) then p2:NearTeleport(x, y, z + 0.5, o) end end)
    end
  end
  for _, guid in ipairs(g.launchers or {}) do despawn(g, guid) end
  for _, cn in ipairs(g.coins or {}) do despawn(g, cn.guid) end
  for _, h in ipairs(g.hazards or {}) do despawn(g, h.guid) end
  g.launchers, g.coins, g.hazards = {}, {}, {}             -- the boxes stay up as scenery until the last racer leaves
  removePodium(g)
  local s = spawn(g, E.PORTAL, PORTAL_SPOT[1], PORTAL_SPOT[2], PORTAL_SPOT[3], PORTAL_SPOT[4], RR.AFTER_MAX + 60000)
  if not s then s = spawn(g, E.PORTAL_OLD, PORTAL_SPOT[1], PORTAL_SPOT[2], PORTAL_SPOT[3], PORTAL_SPOT[4], RR.AFTER_MAX + 60000) end   -- before the SQL is in
  if s then
    try(s, "SetDisplayId", PORTAL_DISPLAY); try(s, "SetUnitFlags", 2); try(s, "SetNPCFlags", 1)
    g.portalGuid = s:GetGUID()
  else log("v2.0: could not spawn the exit portal (helper " .. E.PORTAL .. ")") end
  g.state = "after"; g.afterAt = t
  botWhisper(g, "follow")
  log("v2.0: podium over, racers on foot, exit portal up")
end
local function tickFireworks(g, t)                           -- from the first finisher until the podium ends
  if not g.firstAt or t < (g.fireAt or 0) then return end
  g.fireAt = t + RR.FIREWORK_MS
  if not g.launchers or #g.launchers == 0 then
    g.launchers = {}
    for _, f in ipairs(FIREWORK_SPOTS) do
      local s = spawn(g, E.CTRL, f[1], f[2], f[3] + 6, 0, RR.END_AFTER_FIRST + RR.PODIUM_MS + 60000)
      if s then g.launchers[#g.launchers + 1] = s:GetGUID() end
    end
  end
  if #g.launchers == 0 then return end
  local s = obj(g, g.launchers[math.random(#g.launchers)])
  if s then try(s, "CastSpell", s, pick(FIREWORKS), true) end
end
local function endRace(g, t, wait)                           -- racing -> podium
  g.state = "podium"; g.podiumEnd = t + wait
  for low, m in pairs(g.members) do
    if not m.finished then                                   -- did not make it: their kart stops where it is
      m.finished = true
      local c = kartOf(g, m)
      if c then try(c, "RemoveAura", S.AUTOMOVE); hold(c, true) end
      clearItems(g, low, t)
    end
  end
  log("v2.0: race over, podium for " .. math.floor(wait / 1000) .. " s")
end
local function freezeBots(g, t)                              -- v2.3.5: a stunned bot's own AI leaves it (and its kart) alone
  for low, m in pairs(g.members) do
    if m.bot and not m.freezeOff and t >= (m.freezeAt or 0) then
      local pl = getPlayer(g, low)
      if inGame(g, pl) then
        if RR.BOT_FREEZE then
          try(pl, "AddAura", S.STUN, pl)
          local a = try(pl, "GetAura", S.STUN)
          if a then try(a, "SetMaxDuration", 8000); try(a, "SetDuration", 8000) end
        elseif m.frozen then try(pl, "RemoveAura", S.STUN) end
        m.frozen = RR.BOT_FREEZE
        m.freezeAt = t + 3000
      end
    end
  end
end
local function seatBots(g, t)                                -- v2.3.6: is every bot still IN its kart?
  if t < (g.botSeatAt or 0) then return end
  g.botSeatAt = t + 1000
  for low, m in pairs(g.members) do
    if m.bot and not m.freezeOff then
      local pl, c = getPlayer(g, low), kartOf(g, m)
      local kit = c and c:GetVehicleKit()
      if kit and inGame(g, pl) then
        local pas = kit:GetPassenger(0)
        if pas and pas:GetGUIDLow() == low then
          if not m.satAt then m.satAt = t end
        else
          local near = 9999
          for low2, m2 in pairs(g.members) do
            local p2 = not m2.bot and getPlayer(g, low2)
            if p2 and inGame(g, p2) then near = math.min(near, try(pl, "GetDistance", p2) or 9999) end
          end
          g.seatLogs = (g.seatLogs or 0) + 1
          if g.seatLogs <= 60 then
            log(string.format("diag: bot OUT of kart: %s (state %s, sat %.1f s, %.0f yd from its kart, %.0f yd from the nearest player, stun %s, own vehicle %s, out #%d)",
              m.name or tostring(low), tostring(g.state), m.satAt and (t - m.satAt) / 1000 or -1, try(pl, "GetDistance", c) or -1, near,
              tostring(try(pl, "HasAura", S.STUN)), tostring(try(pl, "IsOnVehicle")), (m.outs or 0) + 1))
          end
          m.outs = (m.outs or 0) + 1; m.satAt = nil
          if RR.BOT_SEAT then
            botWhisper(g, "stay", low)                       -- v2.3.7
            try(pl, "RemoveAura", S.STUN); m.freezeAt = t + 1500
            try(pl, "CastSpell", c, S.RIDE, true)
            if not kit:GetPassenger(0) then try(kit, "AddPassenger", pl, 0) end
            local p3 = kit:GetPassenger(0)
            if g.seatLogs <= 60 then log("diag: bot " .. (m.name or tostring(low)) .. ((p3 and p3:GetGUIDLow() == low) and " put back in its kart" or " could NOT be put back")) end
          end
        end
      end
    end
  end
end
local function tickGame(g, t)
  if g.state ~= "arriving" and g.state ~= "pending" then local ok, err = pcall(seatBots, g, t); if not ok then log("seat error: " .. tostring(err)) end end
  if g.state ~= "arriving" and g.state ~= "pending" then local ok, err = pcall(freezeBots, g, t); if not ok then log("freeze error: " .. tostring(err)) end end
  if g.state == "arriving" and not g.hostGuid then
    for low, _ in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) then spawnHost(g, pl); break end
    end
  end
  if g.state == "arriving" then
    local allIn = true
    for low, _ in pairs(g.members) do if not inGame(g, getPlayer(g, low)) then allIn = false end end
    if (allIn and t >= g.arrivedAt + RR.ARRIVE_WAIT) or t >= g.arrivedAt + RR.ARRIVE_MAX then
      local host = nil
      for low, m in pairs(g.members) do
        local pl = getPlayer(g, low)
        if inGame(g, pl) then
          local x, y, z, o, i = gridSpot(m.slot)
          m.idx = i; m.total = -RR.GRID_BACK; m.prog = m.total; m.laps = 0; m.falls = 0; m.ready = m.bot == true   -- v2.3: bots are ready by themselves
          m.coins = 0; m.items = {}
          pl:NearTeleport(x, y, z + 0.5, o)                  -- everyone on their grid tile, on foot
          host = host or pl
        else
          g.members[low] = nil; g.count = math.max(0, g.count - 1)
        end
      end
      if host and not g.hostGuid then spawnHost(g, host) end
      -- sweep karts left on this map by earlier races (a racer who dropped out takes the lookup with them)
      for low, _ in pairs(g.members) do
        local pl = getPlayer(g, low)
        if inGame(g, pl) then
          local old = try(pl, "GetCreaturesInRange", 1500, E.KART) or {}
          local swept = 0
          for _, c in pairs(old) do
            if not g.kartOwner[c:GetGUIDLow()] then c:DespawnOrUnsummon(0); swept = swept + 1 end
          end
          if swept > 0 then log("removed " .. swept .. " leftover kart(s) from earlier races") end
          break
        end
      end
      sweepProps(g)
      g.state = "lobby"; g.lobbyAt = t; g.nagAt = t
      tell(g, RT .. "Talk to Brumm when you are ready. Every player must be ready before the round can start.", "Talk to Brumm when you are ready!")
    end
  elseif g.state == "lobby" then                             -- live ready lobby
    local allReady, n, total = true, 0, 0
    for low, m in pairs(g.members) do total = total + 1; if m.ready then n = n + 1 else allReady = false end end
    if total > 0 and allReady then                           -- the swirl first, then the karts 1.5 s later
      for low, m in pairs(g.members) do
        local pl = getPlayer(g, low)
        if inGame(g, pl) then try(pl, "RemoveAura", S.READY); try(pl, "CastSpell", pl, S.READY_GO, true) end
      end
      g.state = "seating"; g.seatAt = t + 1500
      botWhisper(g, "stay")                                  -- v2.3.7
    elseif t >= g.lobbyAt + RR.LOBBY_MAX then
      tell(g, RT .. "Not everyone got ready in time. The race is called off.", true); cleanup(g, "lobby timed out"); return
    elseif t >= g.nagAt + 4000 then                          -- live 0:29-0:41: every ~4 s, chat + top-centre, until everyone is ready
      g.nagAt = t; tell(g, "|cffffff00Every player must be ready before the round can start.|r", true)
    end
  elseif g.state == "seating" then
    if t >= g.seatAt then
      local total = 0
      g.state = "grid"; g.gridAt = t; g.lastCount = nil
      for low, m in pairs(g.members) do
        total = total + 1
        local pl = getPlayer(g, low)
        if inGame(g, pl) then
          try(pl, "RemoveAura", S.READY)
          m.hornAt = t + RR.COUNTDOWN * 1000                 -- the horn button is on cooldown until GO
          local x, y, z, o = gridSpot(m.slot)
          if not board(g, low, pl, x, y, z, o) then pl:SendBroadcastMessage(RT .. "Could not seat you in a kart: click it to get in.") end
        end
      end
      g.bigCount = false
      for low, _ in pairs(g.members) do if bigCountdown(getPlayer(g, low), RR.COUNTDOWN * 1000) then g.bigCount = true end end
      log("all " .. total .. " racer(s) ready, karts out, countdown")
      tell(g, AZT .. "Round 1 is starting!", AZT .. "Round 1 is starting!")
      local ok, err = pcall(spawnPickups, g)
      if not ok then log("pickup spawn error: " .. tostring(err)) end
    end
  elseif g.state == "grid" then
    if not g.beamOff and t >= g.gridAt + 1200 then           -- v2.1.3: the light beams of 'Vehicle Stun' only flash as the karts appear (live 0:42); then the plain stun holds them
      g.beamOff = true
      for low, m in pairs(g.members) do local c = kartOf(g, m); if c then try(c, "AddAura", S.STUN, c); try(c, "RemoveAura", S.GRID_STUN) end end
    end
    local n = RR.COUNTDOWN - math.floor((t - g.gridAt) / 1000)
    if n ~= g.lastCount then
      g.lastCount = n
      if n > 0 then                                          -- live shows only the big numbers (no chat lines)
        if not g.bigCount then for low, _ in pairs(g.members) do local pl = getPlayer(g, low); if pl then pl:SendAreaTriggerMessage("|cffffd200" .. n .. "|r") end end end
      else
        g.state = "racing"; g.startedAt = t; g.firstBlockAt = t + 10000; g.order = nil
        dropHost(g)
        for low, m in pairs(g.members) do
          m.lapStart = t; local c = kartOf(g, m); hold(c, false)
          if RR.AUTOMOVE and c then automoveOn(m, c) end   -- live 'Automove' (v2.3: not on bot karts)
          if c then coinIcon(m, c, t); sendBar(g, m, getPlayer(g, low), c, t) end   -- the horn lights up
          local pl = getPlayer(g, low); sound(pl, SND.START); music(pl, SND.THEME)
        end
        botWhisper(g, "stay")
        race(g, "Countdown finished!")
        log("race started with " .. g.count .. " racer(s)")
      end
    end
  end
  local here, racing = 0, 0
  for low, m in pairs(g.members) do
    local ok, err = pcall(tickRacer, g, low, m, t)
    if not ok then log("racer error: " .. tostring(err)) end
    if g.members[low] then here = here + 1; if not m.finished then racing = racing + 1 end end
  end
  if here == 0 then cleanup(g, "nobody left"); return end
  if g.state ~= "arriving" then                              -- v2.3: only bots left = the players went home: send the bots after them
    local humans = 0
    for low, m in pairs(g.members) do if not m.bot and inGame(g, getPlayer(g, low)) then humans = humans + 1 end end
    if humans == 0 then cleanup(g, "only bots left"); return end
  end
  if g.state == "grid" or g.state == "racing" or g.state == "podium" then
    local ok, err = pcall(tickProps, g, t)
    if not ok then log("props error: " .. tostring(err)) end
  end
  if g.state == "racing" then
    local ok, err = pcall(tickOrder, g, t)
    if not ok then log("standings error: " .. tostring(err)) end
    pcall(tickFireworks, g, t)
    if racing == 0 then endRace(g, t, RR.PODIUM_MS)
    elseif g.firstAt and t > g.firstAt + RR.END_AFTER_FIRST then race(g, "The race is over!"); endRace(g, t, 10000)
    elseif t > g.startedAt + RR.MAX_TIME then race(g, "Time's up!"); endRace(g, t, 10000) end
  elseif g.state == "podium" then
    pcall(tickFireworks, g, t)
    if t >= g.podiumEnd then toPodiumEnd(g, t) end
  elseif g.state == "after" then
    if t >= g.afterAt + RR.AFTER_MAX then cleanup(g, "finished") end
  end
end
local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)
    if t > g.created + 90000 then Pending[sLow] = nil; log("start cancelled (starter did not arrive within 90 s)")
    elseif st and st:GetMapId() == RR.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then st:SendBroadcastMessage(RT .. "A race is already running here.")
      else
        Games[g.inst] = g; g.state = "arriving"; g.arrivedAt = t
        tell(g, RT .. "Welcome to the Rainbow Race! Say #leave to go back to the Faire.")
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
    if not ok2 then log("error (race " .. tostring(inst) .. "): " .. tostring(err2)) end
  end
end, 250, 0)

-- ---------- starting a race ----------
local function busy(player)
  local low = player:GetGUIDLow()
  for _, g in pairs(Games) do if g.members[low] then return true end end
  for _, g in pairs(Pending) do if g.members[low] then return true end end
  return false
end
local function startSession(player)
  local members, count = {}, 0
  local function add(p)
    local bot = p:IsBot() == true
    if count >= RR.MAX_PLAYERS or (bot and not RR.BOTS) then return end  -- v2.3: bots too (RR.BOTS)
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), name = p:GetName(), bot = bot, slot = count, idx = 1, total = 0, prog = 0, laps = 0, falls = 0, coins = 0, items = {},
                     home = (p:GetMapId() ~= RR.MAP) and { p:GetMapId(), p:GetX(), p:GetY(), p:GetZ(), p:GetO() } or nil }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= RR.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  if count == 0 then return end
  local g = { members = members, count = count, created = now(), state = "pending", finishedCount = 0, kartOwner = {},
              timers = {}, boxes = {}, coins = {}, hazards = {}, launchers = {} }
  Pending[player:GetGUIDLow()] = g
  for low, m in pairs(members) do
    local p = GetPlayerByGUID(m.guid)
    if p then
      local x, y, z, o = gridSpot(m.slot)
      p:SendBroadcastMessage(AZT .. "You have joined the Race.")
      p:Teleport(RR.MAP, x, y, z + 0.5, o)
    end
  end
  local nb = 0; for _, m in pairs(members) do if m.bot then nb = nb + 1 end end
  log(string.format("%s starts a Rainbow Race with %d racer(s), %d of them bots", player:GetName(), count, nb))
end

-- ---------- Brumm ----------
local function raceOf(player)                               -- the race this player is standing in
  local g = Games[player:GetInstanceId()]
  if g and player:GetMapId() == RR.MAP and g.members[player:GetGUIDLow()] then return g end
end
local function brummMenu(player, creature)
  player:GossipClearMenu()
  if creature:GetMapId() == RR.MAP then                      -- the grid Brumm = the ready check
    local g = raceOf(player)
    if g and g.state == "lobby" then
      if not g.members[player:GetGUIDLow()].ready then player:GossipMenuAddItem(9, "I'm ready! Let's race!", 0, 10) end
      player:GossipMenuAddItem(0, "Take me back to the Faire.", 0, 11)
    end
    player:GossipSendMenu(TEXT_GREET, creature)
    return
  end
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Start a Rainbow Race (with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about The Race?", 0, 2)
  player:GossipMenuAddItem(1, "I'd like to browse your goods.", 0, 3)
  player:GossipSendMenu(TEXT_GREET, creature)
end
RegisterCreatureGossipEvent(E.BRUMM, 1, function(event, player, creature) brummMenu(player, creature) end)
RegisterCreatureGossipEvent(E.BRUMM, 2, function(event, player, creature, sender, intid)
  if intid == 10 or intid == 11 then                         -- grid Brumm
    player:GossipComplete()
    local g = raceOf(player); if not g then return end
    if intid == 11 then
      local low = player:GetGUIDLow(); try(player, "RemoveAura", S.READY); sendHome(g, low)
      return
    end
    if g.state ~= "lobby" then return end
    local m = g.members[player:GetGUIDLow()]
    if m and not m.ready then
      m.ready = true
      try(player, "CastSpell", player, S.READY, true)        -- v2.0: a real cast (v1.3.5's AddAura landed but showed no tick)
      if try(player, "HasAura", S.READY) ~= true then try(player, "AddAura", S.READY, player) end
      local n, total = 0, 0
      for _, x in pairs(g.members) do total = total + 1; if x.ready then n = n + 1 end end
      tell(g, RT .. string.format("%s is ready! (%d/%d)", player:GetName(), n, total))
      creature:SendUnitSay(n < total and "Good. Waiting on the rest of you slowpokes!" or "Everyone's ready? Gentlemen, start your engines!", 0)
    end
    return
  end
  if intid == 1 then
    player:GossipComplete()
    if busy(player) then player:SendBroadcastMessage(RT .. "You are already in a race."); return end
    creature:SendUnitSay("Step on the gas, kid! Your kart's waiting on the grid.", 0)
    startSession(player)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_MORE, creature)
  elseif intid == 3 then
    player:GossipComplete(); player:SendListInventory(creature)
  else
    brummMenu(player, creature)
  end
end)

-- ---------- v2.0: the Azzar Faire Portal behind the start row (live 6:16-6:21) ----------
local function leaveRace(player)
  local low = player:GetGUIDLow()
  local g = Games[player:GetInstanceId()]
  if g and g.members[low] then
    local others = false                                     -- the last one out takes the boxes, coins and Brumm with them
    g.members[low].leaving = true
    for l2, m2 in pairs(g.members) do if l2 ~= low and not m2.leaving and inGame(g, getPlayer(g, l2)) then others = true end end
    if not others then dropHost(g); dropProps(g) end
    sendHome(g, low)
    later(player:GetGUID(), 1500, function() if g.members[low] then g.members[low] = nil; g.count = math.max(0, g.count - 1) end end)
  else                                                      -- no race knows this player (after .reload ale): straight back to Brumm
    music(player, 0)
    local f = RR.FAIRE_SPOT; player:Teleport(f[1], f[2], f[3], f[4], f[5])
  end
end
local function racePortal(creature) return creature:GetMapId() == RR.MAP and creature:GetX() < -1000 end   -- ours stands on the race track; Vertical Ascent's 99652 portals are at x > 4900
local function portalHello(event, player, creature)
  if not racePortal(creature) then return end
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Exit!", 0, 20, false, "Are you sure you want to exit?")
  if creature:GetEntry() == E.PORTAL then player:GossipSendMenu(TEXT_PORTAL, creature)   -- the live text in the window
  else
    player:GossipSendMenu(16777215, creature)
    player:SendBroadcastMessage("|cffffd200<The portal connects to the Azzar Faire. If you leave, you will have to pay again to access the mini-game.>|r")
  end
end
local function portalSelect(event, player, creature, sender, intid)
  if not racePortal(creature) then return end
  player:GossipComplete()
  if intid == 20 and player:GetMapId() == RR.MAP then leaveRace(player) end
end
for _, e in ipairs({ E.PORTAL, E.PORTAL_OLD }) do
  RegisterCreatureGossipEvent(e, 1, portalHello)
  RegisterCreatureGossipEvent(e, 2, portalSelect)
end

-- ---------- the kart's bar: clicks ----------
local function racerOf(player)                              -- g, low, m of a player in a race on this map
  if not player or player:GetMapId() ~= RR.MAP then return nil end
  local g = Games[player:GetInstanceId()]
  local low = player:GetGUIDLow()
  if g and g.members[low] then return g, low, g.members[low] end
  return nil
end
local function doReturn(g, low)                             -- 'Return to Checkpoint' / #stuck = back to the centre line
  local m = g.members[low]
  if not m or m.finished or g.state ~= "racing" or now() < (m.busyUntil or 0) then return end
  local pl = getPlayer(g, low)
  if pl then putBack(g, low, pl, m.idx, "asked") end
end
local function onBarClick(player, spell, gx, gy, gz)
  local g, low, m = racerOf(player)
  if not g or g.state ~= "racing" then return end
  local t = now()
  if not g.barSeen then g.barSeen = true; log("v2.0: kart bar clicks are arriving (first: spell " .. tostring(spell) .. ")") end
  if spell == S.KLAXON then horn(g, low, t)
  elseif spell == S.RETURN then doReturn(g, low)
  elseif m.items[1] and ITEMS[m.items[1]].bar == spell then useItem(g, low, t, gx, gy, gz) end
end
local function flag(mask, f) return math.floor(mask / f) % 2 == 1 end
do
  local function mine(player)                               -- only a racer sitting in a kart in a running race
    local g, low, m = racerOf(player)
    return g and g.state == "racing" and m.kartGuid and not m.finished
  end
  local ok, err = pcall(RegisterPacketEvent, OP.PET_ACTION, 5, function(event, packet, player)
    if not mine(player) then return end
    local ok2, spell = pcall(function() packet:ReadGUID(); return packet:ReadULong() % 16777216 end)
    if not ok2 then return end
    if spell == S.KLAXON or spell == S.RETURN or BAR_ITEM[spell] then
      local ok3, err3 = pcall(onBarClick, player, spell)
      if not ok3 then log("bar click error: " .. tostring(err3)) end
      return false                                          -- ours: the core does not know these spells on the kart
    end
  end)
  if not ok then log("v2.0: RegisterPacketEvent(CMSG_PET_ACTION) failed: " .. tostring(err) .. " -> items only with #use") end
  ok, err = pcall(RegisterPacketEvent, OP.PET_CAST, 5, function(event, packet, player)   -- the Green Rocket's ground target
    if not mine(player) then return end
    local ok2, spell, x, y, z = pcall(function()
      packet:ReadGUID(); packet:ReadUByte()
      local sp = packet:ReadULong(); packet:ReadUByte()
      local mask = packet:ReadULong()
      if flag(mask, 0x2) or flag(mask, 0x10000) or flag(mask, 0x800) or flag(mask, 0x200) or flag(mask, 0x8000) then packet:ReadPackedGUID() end
      if flag(mask, 0x10) or flag(mask, 0x1000) then packet:ReadPackedGUID() end
      if flag(mask, 0x20) then packet:ReadPackedGUID(); packet:ReadFloat(); packet:ReadFloat(); packet:ReadFloat() end
      if flag(mask, 0x40) then packet:ReadPackedGUID(); return sp, packet:ReadFloat(), packet:ReadFloat(), packet:ReadFloat() end
      return sp
    end)
    if not ok2 then return end
    if spell == S.KLAXON or spell == S.RETURN or BAR_ITEM[spell] then
      local ok3, err3 = pcall(onBarClick, player, spell, x, y, z)
      if not ok3 then log("bar cast error: " .. tostring(err3)) end
      return false
    end
  end)
  if not ok then log("v2.0: RegisterPacketEvent(CMSG_PET_CAST_SPELL) failed: " .. tostring(err)) end
end
do                                                          -- the template's own 'Return to Checkpoint' button (shown until our bar arrives)
  local ok, err = pcall(RegisterSpellEvent, S.RETURN, 2, function(event, a, b)
    local function has(o, k) local ok2, f = pcall(function() return o[k] end); return ok2 and type(f) == "function" end
    local caster = a
    if a and has(a, "GetCaster") and not has(a, "GetMapId") then caster = a:GetCaster() end
    if b and has(b, "GetCaster") and not (caster and has(caster, "GetMapId")) then caster = b:GetCaster() end
    local ok3, err3 = pcall(function()
      if not caster or caster:GetMapId() ~= RR.MAP then return end
      local g = Games[caster:GetInstanceId()]
      if not g then return end
      local low = caster:GetGUIDLow()
      if caster:GetEntry() == E.KART then low = g.kartOwner[low] end
      if low then doReturn(g, low) end
    end)
    if not ok3 then log("return error: " .. tostring(err3)) end
  end)
  if not ok then log("RegisterSpellEvent(Return to Checkpoint) failed: " .. tostring(err)) end
end

-- ---------- chat commands ----------
local function nearTrack(pl) local dx, dy = pl:GetX() + 1427, pl:GetY() + 4670; return pl:GetMapId() == RR.MAP and dx * dx + dy * dy < 450 * 450 end
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#leave" then
    if not nearTrack(player) then return end
    leaveRace(player)
    player:SendBroadcastMessage(RT .. "Back to the Faire you go!")
    return false
  end
  if msg == "#use" or msg == "#horn" or msg == "#stuck" then  -- v2.0: the bar by hand, in case the buttons do not answer
    local g, low = racerOf(player)
    if not g then return end
    if msg == "#use" then useItem(g, low, now()) elseif msg == "#horn" then horn(g, low, now()) else doReturn(g, low) end
    return false
  end
  local cmd, arg = msg:match("^#rr%s+(%a+)%s*(%S*)$")
  if not cmd or (player:GetGMRank() or 0) < 1 then return end
  cmd = cmd:lower()
  if cmd == "start" then
    if busy(player) then player:SendBroadcastMessage(RT .. "You are already in a race.") else startSession(player) end
  elseif cmd == "bots" then
    RR.BOTS = not RR.BOTS
    player:SendBroadcastMessage(RT .. "Bot racers are now " .. (RR.BOTS and "ON" or "OFF") .. " for new races. Resets on .reload ale.")
  elseif cmd == "botskill" and tonumber(arg) then
    RR.BOT_SKILL = math.max(0.5, math.min(1.5, tonumber(arg)))
    player:SendBroadcastMessage(RT .. "Bot speed x" .. RR.BOT_SKILL .. ". Resets on .reload ale.")
  elseif cmd == "botseat" then
    RR.BOT_SEAT = not RR.BOT_SEAT
    player:SendBroadcastMessage(RT .. "Bots that leave their kart are put back in: " .. (RR.BOT_SEAT and "ON" or "OFF") .. ". Resets on .reload ale.")
  elseif cmd == "botfreeze" then
    RR.BOT_FREEZE = not RR.BOT_FREEZE
    player:SendBroadcastMessage(RT .. "Bots' own AI held still during a race: " .. (RR.BOT_FREEZE and "ON" or "OFF") .. ". Takes up to 3 s. Resets on .reload ale.")
  elseif cmd == "botpath" then
    RR.BOT_ROADPATH = not RR.BOT_ROADPATH
    player:SendBroadcastMessage(RT .. "Bot karts " .. (RR.BOT_ROADPATH and "follow the road with the path-finder (experiment)" or "drive short straight paths (default)") .. ". Works at once. Resets on .reload ale.")
  elseif cmd == "botdiag" then
    RR.BOT_DIAG = not RR.BOT_DIAG
    player:SendBroadcastMessage(RT .. "Bot kart log (world-console.log): " .. (RR.BOT_DIAG and "ON" or "OFF") .. ". Resets on .reload ale.")
  elseif cmd == "botstay" then
    RR.BOT_STAY = not RR.BOT_STAY
    player:SendBroadcastMessage(RT .. "Whisper stay/follow to the bots: " .. (RR.BOT_STAY and "ON" or "OFF") .. ". Resets on .reload ale.")
  elseif cmd == "automove" then
    RR.AUTOMOVE = not RR.AUTOMOVE
    player:SendBroadcastMessage(RT .. "Automove at GO is now " .. (RR.AUTOMOVE and "ON" or "OFF") .. ". Resets on .reload ale.")
  elseif cmd == "speed" and tonumber(arg) then
    RR.SPEED = tonumber(arg)
    for _, g in pairs(Games) do for _, m in pairs(g.members) do m.rate = nil; try(kartOf(g, m), "SetSpeed", 1, RR.SPEED, true) end end
    player:SendBroadcastMessage(RT .. "Kart speed rate " .. RR.SPEED .. " (about " .. math.floor(RR.SPEED * 7) .. " yd/s). Resets on .reload ale.")
  elseif cmd == "tp" and tonumber(arg) then
    local i = wrap(math.floor(tonumber(arg))); local p = TRACK[i]
    if player:GetMapId() == RR.MAP then player:NearTeleport(p[1], p[2], p[3] + 1, heading(i)) else player:Teleport(RR.MAP, p[1], p[2], p[3] + 1, heading(i)) end
    player:SendBroadcastMessage(RT .. "Track point " .. i .. " of " .. N .. ".")
  elseif cmd == "dir" then
    RR.DIR = -RR.DIR
    player:SendBroadcastMessage(RT .. "Race direction " .. (RR.DIR == 1 and "forward (default)" or "REVERSED") .. ". Resets on .reload ale.")
  elseif cmd == "item" then                                  -- v2.0 test helpers
    local g, low = racerOf(player)
    local key = arg:upper()
    if not g or not ITEMS[key] then player:SendBroadcastMessage(RT .. "In a race: #rr item OIL | ACC3 | ACC2 | ACC1 | BOMB | STATIC | SHRINK | BULLET | FIRST | TARGET | MORTAR")
    else player:SendBroadcastMessage(RT .. (giveItem(g, low, key, now()) and ("You hold " .. ITEMS[key].name .. ".") or "Both slots are full.")) end
  elseif cmd == "coins" and tonumber(arg) then
    local g, low, m = racerOf(player)
    if g then m.coins = math.max(0, math.min(RR.COIN_MAX, math.floor(tonumber(arg)))); coinIcon(m, kartOf(g, m), now()) end
  elseif cmd == "boxmode" then
    RR.BOX_MODE = (RR.BOX_MODE == "aura") and "display" or "aura"
    player:SendBroadcastMessage(RT .. "Mystery boxes are now shown by " .. (RR.BOX_MODE == "aura" and "the live spell 255654" or "creature display 137670") .. " (from the next race). Resets on .reload ale.")
  elseif cmd == "countdown" then
    RR.BIG_COUNTDOWN = not RR.BIG_COUNTDOWN
    player:SendBroadcastMessage(RT .. "Countdown: " .. (RR.BIG_COUNTDOWN and "the client's big gold numbers (packet 0x588)" or "small numbers") .. ". Resets on .reload ale.")
  elseif cmd == "pad" and tonumber(arg) then
    RR.PAD_BONUS = math.max(0, math.min(100, tonumber(arg))) / 100
    player:SendBroadcastMessage(RT .. "Chevron tile boost is now +" .. math.floor(RR.PAD_BONUS * 100 + 0.5) .. " %. Resets on .reload ale.")
  elseif cmd == "music" then
    RR.MUSIC = not RR.MUSIC
    player:SendBroadcastMessage(RT .. "Race sounds are now " .. (RR.MUSIC and "ON" or "OFF") .. ". Resets on .reload ale.")
  elseif cmd == "bbauto" then
    RR.BB_AUTOPILOT = not RR.BB_AUTOPILOT
    player:SendBroadcastMessage(RT .. "Obsidian Fury autopilot is now " .. (RR.BB_AUTOPILOT and "ON" or "OFF") .. ". Resets on .reload ale.")
  elseif (cmd == "aura" or cmd == "unaura" or cmd == "cast") and tonumber(arg) then   -- try a visual on yourself (or your kart)
    local id = math.floor(tonumber(arg))
    local g, low, m = racerOf(player)
    local u = (g and kartOf(g, m)) or player
    if cmd == "aura" then try(u, "AddAura", id, u) elseif cmd == "unaura" then try(u, "RemoveAura", id) else try(u, "CastSpell", u, id, true) end
    player:SendBroadcastMessage(RT .. cmd .. " " .. id .. " on " .. ((u == player) and "you" or "your kart") .. ".")
  else
    player:SendBroadcastMessage(RT .. "GM: #rr start | bots | botskill <n> | botstay | botdiag | botpath | botfreeze | botseat | speed <rate> | tp <1-" .. N .. "> | dir | automove | item <NAME> | coins <n> | pad <percent> | boxmode | bbauto | music | countdown | aura <id> | unaura <id> | cast <id>")
  end
  return false
end)

log("script loaded v2.3.7 bots (Brumm " .. E.BRUMM .. ", kart " .. E.KART .. ", map " .. RR.MAP .. ", track " .. N .. " points, " .. RR.LAPS .. " laps, " .. #BOXES .. " boxes, " .. #COINS .. " coins)")
