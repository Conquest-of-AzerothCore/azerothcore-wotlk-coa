-- azzar-wonka-wonka.lua  v1.2k  (Rowan/Claude 2026-11-14; v1.1 = stage two, 2026-11-16; v1.2 = like live, 2026-11-17; v1.2a = platform + spread, UNTESTED)
-- v1.2k (2026-11-17 12:40, Rowan, with Wonka Wonka closed at v1.2j: 'and yes do Otto Wonkas greeting. The whole thing.'): Otto in the tent
--   now shows live's own window (58:56-59:00): 'Let me know when you're ready to start!' = npc_text 1200305 (live id and text, from the cache
--   dumps), with the one option 'I'm ready!'. NEEDS THE ROW: tools\azzar-otto-tent-text.sql (Azzar-Otto-Tent-Text-Apply.bat, which also copies
--   this file) and a restart (npc_text is read at start-up only). Without the row the client shows its plain default greeting there.
-- v1.2j (2026-11-17 12:13, Rowan: '2.5 is good for normal speed and the sprint can be set to 3.5 and make sure they stick because when i get
--   hit by aoe etc, sometimes the speed reverts back to how it was before restart'):
--   MOUNT 2.5, SPRINT 3.5 (ROWAN'S NUMBERS). WHY IT WENT BACK: the bar's sprint is live's 257449, a real +50% speed aura, and whenever a
--   speed aura comes or goes the core works the speed out afresh from the creature template (speed_run 1.6): 2.4 while it ran, 1.6 from then
--   on. The script never saw that sprint (it only listened for the other one, 256027). Now the playing tick looks at every mount twice a
--   second: sprinting = the sprint aura is on it, and whatever speed it has is put back to 2.5, or 3.5 while sprinting. The Wonkas that
--   follow keep 1.15 times that. '#ww speed <rate>' and '#ww sprintspeed <rate>' change the two on the spot.
-- v1.2i (2026-11-17 12:08, Rowan after a round on v1.2h, the realms restarted: 'everything is great except the wind spell. It is not doing a
--   knock back affect'). So SEEN IN GAME BY ROWAN and fine: the launch by a jump of the mount, getting off the Wonka, the speeds 2.6 / 1.5 / 1.2.
--   AIR BLAST 256056, live's own words: 'Push your rivals with a powerful wonka air blast.' It is a dummy spell (no knock-back, no radius in
--   the DBC), so live scripts the push. Until now ours only made a rival's Wonkas run off and sent a land bomb walking away at speed 2.0
--   (under the bombs' new 1.5 that showed nothing). Now, within 15 yd of the caster: every rival's mount is blown 12 yd back in a low jump
--   (not held), his Wonkas still run off, and every land bomb is thrown 12 yd back the same way (it still counts as pushed for 4 s: 'Take
--   that!'). OURS: the 15 yd all round, the 12 yd, the low arc. Playing alone only the bombs show it.
-- v1.2h (2026-11-17 11:16, Rowan in game on v1.2g, bombs and hydras walking at last: 'When leaving my wonka, I am put back in it which forces me
--   to use #leave in order to exit the mini game. The hydras need to move around the roads a little faster. Keep in mind this is suppose to be a
--   fast paced mini game. Also, the wonka is not launched into the air when hitting a bomb. Everything else regarding that is fine.' 11:17 'and my
--   wonka vehicles speed needs an increase again. the bombs need to move around faster as well. Remember, fast paced game.'):
--   GETTING OFF: a rider who leaves his Wonka is left on foot; the Wonka waits where it stands (click it to ride again) and he can walk to the
--   Azzar Faire Portal. On foot he is no target for bombs / bolts and does not score. (v1.2-v1.2g seated him again within half a second.)
--   THE LAUNCH: no longer a knock-back spell (58561 did nothing even with the mounts made beasts) but the mount itself is sent on a jump
--   (MoveJump: about 4 yd up, 6 yd away from the bomb or the grenade, 1.3 s), then held. The mounts go back to creature type 10 in the SQL.
--   SPEEDS (all OURS, 1 = a player running): mount 2.0 -> 2.6, land bombs 0.8 -> 1.5, hydras 0.65 -> 1.2. To try others on the spot:
--   '#ww speed <rate>', '#ww bombspeed <rate>', '#ww hydraspeed <rate>'.
-- v1.2g (2026-11-17 10:49, Rowan in game on v1.2f: 'Lightning strikes work. The teleporting in works. Wonkas move to slow at normal speed. Hydras
--   are still stationary but are on the road at least. Bombs are still stationary. Bombs don't launch me into the air.' 10:51 'The timer sound
--   played at 3:30 so that's good. Game music is playing.' 10:54 'Confetti works.'):
--   WHY the bombs and hydras stand still and the lift does nothing was in the DATABASE, not here (core source read, Build\coa-core):
--   creature_template_movement had Hand grenade 99751 and Devourawonkas 99757 ROOTED (our own 'inert for now' rows of 2026-11-14), and a
--   template-rooted creature cannot be moved or un-rooted by a script; and a knock-back spell moves a vehicle only if it is a BEAST
--   (Spell::EffectKnockBack), ours were type 10. Both are changed in tools\azzar-wonka-wonka.sql (7 rows; Azzar-Wonka-Wonka-Apply.bat, then
--   '.reload creature_template 99741 99742 99743 99744 99745 99751 99757'). This script says so in the log if a bomb or hydra is still rooted.
--   MOUNT SPEED 1.6 -> 2.0 (the sprint stays 1.5 times it: live's 257449 is +50%); '#ww speed <rate>' sets another on the spot. A Wonka that
--   follows a rider now runs 1.15 times as fast as his mount does at that moment (it was a fixed 1.5 against the mount's 1.6: left behind).
-- v1.2f (2026-11-17 10:41, Rowan, on the end of the game: 'I want it matched with live please.'): live 67:15-67:31 (sheets\endparty.jpg):
--   0:00  everyone is on the platform, STILL MOUNTED and standing still, the same waiting look as through the countdown; +5 s the three places
--   and the confetti; +10 s (67:25) on foot; +16 s (67:31) 'Round 1 is complete. Round 2 is now available!'. So now: a rider on the platform
--   (10 yd) stays on his mount, held; a rider who is not is taken off, teleported onto it and seated on a new mount there (a ridden mount
--   cannot be teleported from Lua: the same two steps as at GO); the confetti goes off on the mounts; everyone is put on foot 10 s after 0:00
--   and the next round is offered 16 s after it (was 10).
-- v1.2e (2026-11-17 10:29, Rowan: 'At the 3:30 mark of the countdown timer, a sound like the one in the battle grounds play when time is getting
--   low is missing. Add an on fire aura after being hit by the wandering bombs as well so it looks like the player is on fire from the explosion
--   whilst being lifted up in the air. At the end of the game everyone not on the platform is teleported to the platform and strings of confetti
--   etc are all around the players as a celebration. Idk if the confetti exists in the files.'):
--   3:30 LEFT: sound 8457 'PVPWarningHorde' (Arathi Basin's 'near victory' horn). LIVE, found in the video's sound track (wonka-sound-find.py):
--   63:45.2, z 113, the second the clock shows 3:30. Found the same way: 25478 'ui_battlegroundcountdown_end' at 0:00 (67:15.6) as at GO
--   (59:15.6), so that goes out at the end of the game too.
--   ON FIRE: a mount caught by a walking bomb burns while it is thrown and held (36301 'On Fire' + 34658 'Flames' = the Immolate look, off when
--   it is let go). Live 59:29.6-59:32.2: fire round the mount from the hit until it runs again (sheets\bombfire.jpg). Which spell live uses: not known.
--   THE END: only who is NOT on the platform (10 yd) is brought onto it; 5 s later (live 67:20-67:22, sheets\endparty.jpg) the three places are
--   called and confetti goes off round every player: live's own 256066 'Confetti' (kit 163339, ud_confetti_01), played as a kit as well as cast
--   (v1.2-v1.2d cast it in the same instant as the teleport, where it was most likely lost), twice, with 256067 'Emote: Applause'.
-- v1.2d (2026-11-17 10:07, Rowan after his first round (v1.2a): 'No music either. The bombs are not stationary but move in large random patterns.
--   That increases risk. Also, when a player gets hit by a bomb, the player is lift up in the air slightly like what happens when a bomb explodes.
--   Plus you need the exploding bomb effect. The ground floor aoe lightning is missing the lightning coming down itself. ... the hand grenades can
--   also be used to stun players. With a message overheard that says <player name> delivered an explosive reminder to <player name>. The hydras are
--   bigger and patrol up and down the road and around the roads.' / 'So those need to be implemented'):
--   MUSIC 215019 'azzar_faire_wonkas_music'. LIVE, measured in the video's own sound track (wonka-music-timing.py): it starts at 59:04.4, the
--   moment the countdown comes up, and runs back to back (again at 62:03.0 and 65:01.5 = every 178.6 s, the length of the file), on past the
--   end of the game (67:15) for as long as the player is in the tent. So: on at the countdown, sent again every 178.6 s, off when you leave.
--   LAND BOMBS roam: one far spot after another (25-60 yd, a 9-yd leg at a time so each leg ends on the ground), not across the platform.
--   Going off = the explosion of live's own bomb spell (kit 163183, on the bomb and on whoever it catches); who is in reach is thrown up and
--   back a little (knock-back spell 58561, cast by the bomb: this ALE has no knock-back call) and held once down.
--   LIGHTNING: the bolt itself comes down on the marked spot (kit 163329 = the cast look and the whip-crack of 256060 'Electrocuted').
--   LIVE, from the sound track (wonka-sounds-timing.py): thunder 215020 every 20 s from 20 s after 'Storm incoming!' (59:53, 60:33, 61:33,
--   61:53, 62:13 ... 66:14), so that goes out too; the hydra sound 215018 is heard once, at 'Hydras emerging!' (60:03.5).
--   GRENADE: lands after its flight (30 yd/s, the spell's own speed) with the explosion; whoever is in reach is thrown back and held; the
--   'explosive reminder' line and the 'ate a bomb' line are shown mid-screen as well as in chat.
--   HYDRAS: five, twice the size (the model is 6 x 4.4 x 4.8 yd at size 1, about a rider's mount), out from 'Hydras emerging!' to the end,
--   walking the ROADS: out one spoke road, round the ring road to the next spoke, in again, and back. The roads are read off the tile's road
--   texture (8ZUL_TILE01, wonka-roads.py): five spokes (bearings 0, 68, 142, 218, 290) and a ring about 155 yd out. A hydra still only eats
--   Wonkas that follow somebody past it. OURS: how many, how big, how fast, the 7-yd reach, turning round 36 yd short of the middle.
-- v1.2c (2026-11-17 09:57, Rowan: 'On live the players are ported into the game away from the platform and have to run up to Otto. Also, you are
--   missing the portal back to the faire.' / 'So put the spawn point down the road from the platform.'):
--   ARRIVAL on the road, 52 yd north of the platform's middle, facing it (live 58:48-58:55: the minimap arrow points south the whole run, about
--   7 s on foot; the ground there is the road's bed, 13.5, no model in the way from 16 to 70 yd). Several players stand side by side.
--   AZZAR FAIRE PORTAL (creature 9997810, the orb; text 1200245, both already in the database and used by Bullet Romper and the race) by the
--   arrival spot, a little behind and to the left of those arriving (live 67:38-67:42): 'Exit!' takes you back to the Faire. #leave still works.
-- v1.2b (2026-11-17 09:46, Rowan: 'Why do #ready? Why not start the game the way live does it?'): live 58:58 = OTTO WONKA stands on the platform
--   in the tent; his window says 'Let me know when you're ready to start!' with one option, 'I'm ready!'; then the green tick over your head.
--   Now so (as Rikky in Bullet Romper): Otto is put on the platform, 'I'm ready!' is his only option there, #ready still works. He greets
--   with his Faire text until the live sentence has a text row of its own (SQL). 'Every player must be ready...' only while others are awaited.
-- v1.2a (2026-11-17 09:32, Rowan on an earlier version: 'When I spawn into the map, I am stuck inside the platform and have to jump up to reach it',
--   'The baby wonkas are not spread out but instead are packed around the platform'):
--   PLATFORM: its top is at z 17.12, level out to 9 yd, then it slopes to 15.0 at 15 yd (ray cast on the tent model: the logo floor is part of
--   azzarfaire_tent_round_interioronly_wonka.wmo; the Zandalari platform at 15.02 lies under it). The script had 15.2 = 1.9 yd inside it.
--   SPREAD: with height data the spawn rule puts half the Wonkas beyond 73 yd; 'packed' = the rule's fallback ring at 40 yd = the server's height
--   lookup gave nothing in that game. The script now carries the terrain itself (client ADT, its own 4.17-yd grid) and uses it whenever the server's answer
--   is missing or more than 8 yd off; the log says once which one is in use. Wonkas now out to 150 yd (was 120).
-- v1.2 (2026-11-17, Rowan asleep; his rule since 11-16: 'I want everything like live'): the live game read second by second from
--   'All 7 Azzar Faire games' 58:38-67:45 (faire-cache\wonka-wonka-live-2026-11-17\WONKA-WONKA-LIVE-VS-OURS-2026-11-17.md). Changed:
--   HUD by world states (WorldStateUI.dbc 378 'End of Game' + 380-384 the five colours); countdown ON FOOT with the mounts waiting at
--   the platform's edge, seated at GO, 'You have selected the X Wonka' at GO; the storm is announced ONCE (0:18 into the game) and
--   stays; 'Hydras emerging!' ONCE (0:48); Walking Land Bombs stand in the tent from the start, wander and go off on touch (no fuse,
--   no chase); [TIMER] 3 / 2 / 1 minutes and 9s..0s; at the end everyone on the platform, First / Second / Third place by name,
--   confetti; 'Round N is complete. Round N+1 is now available!' and a new ready check; the first three 'win' (live: 2nd and 3rd got
--   the winner's achievements); achievement counters by kill credit 379182-379187; Predator / Environment / Explosion Avoided;
--   'Take that!'; the grenade lands where it is aimed (15 yd round the spot); 'Wonkas following' counts; no chat lines live has not.
--   Ready for a changed bar (SQL, only on Rowan's word): 256044 / 256026 banana at a TARGETED Wonka, 256027 sprint (12 s).
--   Not solved: Air Blast does not push riders (this ALE has no KnockbackFrom); the grenade button stays on the bar.
-- v1.1: you arrive ON FOOT and say #ready; nobody is seated while a client is still loading (the Rainbow Race freeze). 10 s countdown
--   (footage 59:05-59:15) with the client's big numbers. STAGE TWO, all on the creatures already in azzar-wonka-wonka.sql:
--   STORM ('Storm incoming! Watch the lightning strikes.': marked spots, then a bolt: Electrocuted, your Wonkas scatter),
--   HYDRAS ('Hydras emerging! Keep moving!': they eat following Wonkas that pass them), hidden CARNIVOROUS PLANTS (eat up to 2 and
--   hold your mount), walking BOMB-BOTS (follow a rider, blow up on touch or after 20 s; Air Blast sends them away:
--   'X delivered an explosive reminder to Y.'), WONKA EGGS (ride over one = a HAND GRENADE; button 4 throws it at the nearest
--   rival: 'Y just ate a bomb from X.', their Wonkas may change sides). Button 4 needs the re-run SQL (mount spell slot 4 = 256058).
--   How often and how hard is OURS (settings below); the wording of the [WONKA] lines is live.
-- WONKA WONKA! mini-game for the Azzar Faire (map 960 'MiniGames', area 10112), host Otto Wonka 99730 on Dawnrise (map 909).
-- Rules from Otto's live text 1200247 + the footage ('All 7 Azzar Faire games' 58:30-1:07:30):
--   each player rides a coloured Wonka mount (live vehicles 99741-99745), throws bananas (live 255757) at the little Wonkas (live 99749)
--   until they follow, and leads them to the centre platform to score. Air Blast (live 256056) scares a rival's Wonkas away.
--   Wonka Sprint (live 257449) is a short speed boost. Most points when the clock runs out wins.
-- v1.0 = bananas, followers, scoring at the centre, Air Blast, sprint, clock, places, rewards.
--        NOT in v1.0: storm/lightning, hydras, carnivorous plants, Bomb-Bots, eggs + hand grenades (their creatures are already in the SQL).
-- ARENA (client files): tent WMO azzarfaire_tent_round_interioronly_wonka at 960 5600.68 -5597.70 (inside radius ~190 yd), real terrain
--   (tile MiniGames_42_21, ground z ~13-15 near the middle, hills further out), centre = 8tr_zandalari_platform_ruined01 at
--   5600.99 -5597.58 z 14.26 (radius 14 yd, the round platform with the Faire logo where players arrive).
-- Commands (chat):  #leave = back to the Faire.   GM only:  #ww start | #ww time <seconds left>
-- Needs azzar-wonka-wonka.sql (mounts, Wonka, quests). The banana's landing marker 99677 'Wonka Food' comes from azzar-wonka-quests.sql.
local WK = {
  MAP = 960,
  CENTER = { 5600.99, -5597.58, 17.12 },                    -- v1.2a: the TOP of the centre platform (was 15.2 = inside it); level out to 9 yd
  CENTER_R = 14,                                            -- stand this close to the middle to score
  ARRIVE = { 52, 0 }, PORTAL = { 55, -5 },                  -- v1.2c: yards north (+x) and west (+y) of the middle: where players arrive on the road, and the Azzar Faire Portal
  FAIRE_SPOT = { 909, -1602.83, -11968.30, 61.6, 0.55 },    -- in front of Otto (spawn 13800564: -1600.70 -11967.00 61.50 o 3.69)
  MAX_PLAYERS = 5, JOIN_RANGE = 40,
  GAME_TIME = 480,           -- seconds (footage HUD: 'End of Game: 8:00'; Otto's text says five minutes)
  ARRIVE_WAIT = 3000, ARRIVE_MAX = 30000, COUNTDOWN = 10, READY_MAX = 300000, BIG_COUNTDOWN = true,
  SHOCK_MS = 3000,           -- how long a bolt or a bomb disables your mount
  STORM_FIRST = 18000, BOLT_EVERY = 4000, BOLT_WARN = 2000, BOLT_R = 4, BOLT_NEAR = 4, BOLT_FAR = 14,   -- v1.2: live announces the storm ONCE, 0:18 into the game (59:33), and it stays; how often a bolt falls is OURS
  HYDRA_FIRST = 48000, HYDRA_EVERY = 60000, HYDRAS = 5, HYDRA_SCALE = 2, HYDRA_SPEED = 1.2, HYDRA_WARN = 2500, HYDRA_TIME = 15000, HYDRA_R = 7,
  PLANTS = 8, PLANT_R = 6, PLANT_UP = 6000, PLANT_REARM = 30000, PLANT_EATS = 2,
  BOT_SPEED = 1.5, BOT_HOP_MIN = 25, BOT_HOP_MAX = 60, BOT_LEG = 9, BOT_FUSE = true,   -- v1.2d: land bombs roam in large random patterns (Rowan); the fuse sound = live's 256065
  MUSIC = true, MUSIC_ID = 215019, MUSIC_AGAIN = 178600,    -- v1.2d: 'azzar_faire_wonkas_music', 178.6 s long, back to back on live
  THUNDER_EVERY = 20000,                                    -- v1.2d: live, from the sound track
  LOW_AT = 210, PARTY_AFTER = 5000, PLATFORM_R = 10,        -- v1.2e: the horn at 3:30 left (live); places + confetti 5 s after the end (live); 'on the platform' = this close to the middle
  BOTS = 12, BOT_BACK = 8000, BOT_ARM = 3000, BOT_TOUCH = 3, BOT_R = 6, BOT_RMIN = 30, BOT_RMAX = 110,   -- v1.2: Walking Land Bombs: in the tent from the start (live 59:29), wandering; how many is OURS
  EGGS = 6, EGG_R = 3, GRENADE_R = 30, GRENADE_STEAL = 50, GRENADE_BLAST = 15,  -- eggs on the ground; grenade reach; % of the rival's Wonkas that change sides
  WONKAS = 40,               -- little Wonkas loose in the tent at any time
  SPAWN_RMIN = 35, SPAWN_RMAX = 150, SPAWN_ZMAX = 22,       -- where they appear (ring round the centre, not on the steep hills)
  FEED_R = 8,                -- a banana feeds Wonkas this close to where it lands
  FEED_MAX = 3,              -- at most this many per banana
  LEASH = 70,                -- a follower further than this from its owner is lost
  BLAST_R = 15,              -- Air Blast reach
  MOUNT_SPEED = 2.5, SPRINT_SPEED = 3.5, WONKA_SPEED = 1.5, FOLLOW_X = 1.15,   -- v1.2j: 2.5 and 3.5 are Rowan's (12:13)
  BLAST_BACK = 12, BLAST_UP = 7,                            -- v1.2i: Air Blast blows a rival's mount or a land bomb this far back, in a low jump (7 = about 1.3 yd high)
  LIFT_UP = 12.5, LIFT_BACK = 6, LIFT_MS = 1400,            -- v1.2h: a bomb throws the mount: take-off speed (12.5 = about 4 yd high), yards away, and held this long after the hit
  WONKA_SCALE = 0.5,         -- mounts and little Wonkas share one model (Creature\Wonka\Wonka.m2): the little ones are scaled down
  TICKETS = 300,             -- per finished game (live value unknown; same as Vertical Ascent)
  RESULT_TIME = 16000, PARTY_TIME = 10000,       -- v1.2: on the platform after the end, then 'Round N is complete' (live 67:15 -> 67:31)
  CHAT_BOARD = false,        -- v1.2: live has no scoreboard line in chat (the HUD shows the scores); true = our old line each minute
  HUD = true,                -- v1.2: the live HUD (world states; WorldStateUI.dbc 378 + 380-384, map 960)
  SPRINT_MS = 8000,   -- v1.2: for sprint 256027 (live's 12 s one has no speed of its own; how much faster is OURS)
}
local E = { OTTO = 99730, PORTAL = 9997810, WONKA = 99749, FOOD = 99677, CONTROLLER = 99734, CREDIT = 379182,
            WIN = 379183, SCORED = 379184, EGGOPEN = 379185, THROWN = 379186, STOLEN = 379187,   -- v1.2: the achievements' counters (Achievement_Criteria: kill credit)
            STORM = 99755, STORMZONE = 99756, HYDRA = 99757, PLANT = 99754, BOMBBOT = 99751, EGG = 99752 }   -- v1.1: live ids, in the SQL since v1.0
local S = { RIDE = 46598, STUN = 255620, BANANA = 255757, BLAST = 256056, SPRINT = 257449, HAPPY = 255759, FOLLOWING = 256057, SCORE = 256062, ZONE = 256046,
            READY = 257210, GRENADE = 256058, BOMB = 256059, BOMBVIS = 256052, EMERGE = 256055, SHOCK = 256060, BOLTZONE = 256061,
            BANANA_T = 256044, BANANA_PH = 256026, SPRINT12 = 256027, FOODVIS = 255830, CONFETTI = 256066, APPLAUSE = 256067,   -- v1.2
            FUSE = 256065, LIFT = 58561,                    -- v1.2d: 'Sound: Fuse Loop'; 58561 = a plain knock-back (up 7.5, back 4.5 yd/s)
            ONFIRE = 36301, ONFIRE2 = 34658,                -- v1.2e: 'On Fire' (Immolate_State_Base) + 'Flames' (Immolate_State on the chest)
            AV_HYDRA = 257221, AV_BOLT = 257222, AV_BOMB = 257223 }   -- v1.2: the live marker auras of the three 'Avoided' achievements (on at GO, 59:16)
local OP_COUNTDOWN = 0x588
local OP_PLAY_VISUAL, KIT_BOOM, KIT_BOLT = 0x1F3, 163183, 163329   -- v1.2d: SMSG_PLAY_SPELL_VISUAL; the impact kit of 256059 'Bomb'; the cast kit of 256060 'Electrocuted'
local SND_HYDRA, SND_THUNDER = 215018, 215020              -- v1.2d: 'azzar_faire_wonka_hydra', 'fx_weather_80_lightningstorm_periodic'
local SND_LOW, SND_END, KIT_CONFETTI = 8457, 25478, 163339   -- v1.2e: 'PVPWarningHorde'; 'ui_battlegroundcountdown_end'; the cast kit of 256066 'Confetti'
local COLORS = {            -- slot order = the HUD order in the footage
  { name = "Yellow", mount = 99741, aura = 256047, ach = 90233 },
  { name = "Blue",   mount = 99745, aura = 256048, ach = 90234 },
  { name = "Purple", mount = 99744, aura = 256049, ach = 90235 },
  { name = "Green",  mount = 99742, aura = 256050, ach = 90236 },
  { name = "Orange", mount = 99743, aura = 256051, ach = 90237 },
}
local WONKA_LOOKS = { 137759, 137760, 137761, 137762 }
local ACH = { FIRST_MATCH = 90211, WINNER = 90215, SINGLE = 90224, MAMA = 90225, DOMINATOR = 90239, NO_HYDRA = 90219, NO_BOLT = 90220, NO_BOMB = 90221, TAKE_THAT = 90223 }
local Q_BASE, Q_DAILY = 1650232, 1650273
local TEXT_GREET, TEXT_MORE, TEXT_PORTAL = 1200246, 1200247, 1200245
local TEXT_TENT = 1200305                                   -- v1.2k: 'Let me know when you're ready to start!' (live npc_text; azzar-otto-tent-text.sql)
local ITEM_TICKET = 558530
local TEMPSUMMON_TIMED_DESPAWN = 3
local LIFE = 30 * 60000

local Games = {}
local Pending = {}
local WT = "|cffffd200[WONKA]|r "
local AZT = "|cffff8000Azzar Event:|r "
local TT = "|cffffd200[TIMER]|r "
local WS = { TIME = 3564, MIN = 3559, TEN = 3560, ONE = 3561, SCORES = 2577, COLOR = { 1583, 1584, 1585, 1586, 1587 } }   -- v1.2: HUD world states; COLOR in slot order (Yellow, Blue, Purple, Green, Orange)

local function log(msg) print("[WonkaWonka] " .. msg) end
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
local function inGame(g, pl) return pl and pl:GetMapId() == WK.MAP and pl:GetInstanceId() == g.inst end
-- v1.0.1 (2026-11-14): never keep a Map handle between ticks (ALE invalidates it when the hook that made it ends);
-- fetch the race map fresh from a member who is in the game instance.
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
local function mountOf(g, m) return obj(g, m.mountGuid) end
local function hasAch(pl, id) return try(pl, "HasAchieved", id) == true end
local function giveAch(pl, id) if not hasAch(pl, id) then try(pl, "SetAchievement", id) end end
local function credit(pl, entry, n)                         -- v1.2: the achievement counters run on kill credit (379182-379187)
  for _ = 1, (n or 1) do try(pl, "KilledMonsterCredit", entry) end
end
-- ---------- v1.2: the live HUD ----------
local function ws(pl, field, value) if WK.HUD then try(pl, "SendUpdateWorldState", field, value) end end
local function hudScores(g)
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      ws(pl, WS.SCORES, 1)
      for slot, field in ipairs(WS.COLOR) do
        local sc = 0
        for _, m in pairs(g.members) do if m.slot == slot then sc = m.score end end
        ws(pl, field, sc)
      end
    end
  end
end
local function hudTime(g, left)
  left = math.max(0, math.floor(left)); local s = left % 60
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then ws(pl, WS.TIME, 1); ws(pl, WS.MIN, math.floor(left / 60)); ws(pl, WS.TEN, math.floor(s / 10)); ws(pl, WS.ONE, s % 10) end
  end
end
local function hudOff(pl) if pl then ws(pl, WS.TIME, 0); ws(pl, WS.SCORES, 0) end end
local function music(pl, id)                                -- v1.2d: on the music channel, as Bullet Romper and the race send theirs (id 0 = off)
  if not pl or try(pl, "IsBot") == true or not (WK.MUSIC or id == 0) then return end
  if type(pl.PlayMusic) == "function" then local ok = pcall(pl.PlayMusic, pl, id, pl); if ok then return end end
  if id ~= 0 then try(pl, "PlayDirectSound", id, pl) end
end
local function musicAll(g, id) for low in pairs(g.members) do local pl = getPlayer(g, low); if inGame(g, pl) then music(pl, id) end end end
local function soundAll(g, id) for low in pairs(g.members) do local pl = getPlayer(g, low); if inGame(g, pl) then try(pl, "PlayDirectSound", id, pl) end end end   -- v1.2e
local function playKit(g, unit, kit)                        -- v1.2d: a one-shot visual kit played on a unit for everyone in the game (as Bullet Romper v1.33)
  if not (unit and type(CreatePacket) == "function") then return false end
  local ok, err = pcall(function()
    for low, _ in pairs(g.members) do
      local pl = getPlayer(g, low)
      if pl then local pk = CreatePacket(OP_PLAY_VISUAL, 12); pk:WriteGUID(unit:GetGUID()); pk:WriteULong(kit); pl:SendPacket(pk) end
    end
  end)
  if not ok and not g.kitSaid then g.kitSaid = true; log("could not play a visual kit: " .. tostring(err)) end
  return ok
end

-- ---------- mounts ----------
local function hold(c, on)
  if not c then return end
  if on then try(c, "AddAura", S.STUN, c); try(c, "SetRooted", true)
  else try(c, "RemoveAura", S.STUN); try(c, "SetRooted", false) end
end
local function dropMount(g, low, pl)
  local m = g.members[low]
  local c = mountOf(g, m)
  if c then
    local kit = c:GetVehicleKit()
    if kit and pl then try(kit, "RemovePassenger", pl) end
    g.mountOwner[c:GetGUIDLow()] = nil
    c:DespawnOrUnsummon(300)
  end
  m.mountGuid = nil
end
local function spawnMount(g, low, pl, x, y, z, o)           -- v1.2: the mount can stand waiting (live: at the platform's edge through the countdown)
  local m = g.members[low]
  local col = COLORS[m.slot]
  local c = pl:SpawnCreature(col.mount, x, y, z + 0.2, o, TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if not c then log("could not spawn a Wonka mount (template " .. col.mount .. " missing? run the SQL)"); return nil end
  m.mountGuid = c:GetGUID(); g.mountOwner[c:GetGUIDLow()] = low
  try(c, "SetSpeed", 1, WK.MOUNT_SPEED, true)
  try(c, "SetPowerType", 3); try(c, "SetMaxPower", 3, 100); try(c, "SetPower", 100, 3)   -- the banana gives energy: a full green bar
  try(c, "AddAura", col.aura, c)                            -- v1.2: live mounts carry their colour (59:47)
  hold(c, true)
  return c
end
local function seat(g, low, pl)
  local m = g.members[low]
  local c = mountOf(g, m)
  if not c then return false end
  local kit = c:GetVehicleKit()
  if not kit then log("the Wonka mount has no vehicle kit (VehicleId missing in creature_template " .. COLORS[m.slot].mount .. "?)"); return false end
  pl:CastSpell(c, S.RIDE, true)
  if not kit:GetPassenger(0) then try(kit, "AddPassenger", pl, 0) end
  hold(c, g.state ~= "playing")
  local pas = kit:GetPassenger(0)
  return pas and pas:GetGUIDLow() == low
end
local function board(g, low, pl)
  if not spawnMount(g, low, pl, pl:GetX(), pl:GetY(), pl:GetZ(), pl:GetO()) then return false end
  return seat(g, low, pl)
end

-- ---------- little Wonkas ----------
-- v1.2a: the terrain of the tent, from the client's own map tile (MiniGames_42_21.adt): 97 x 97 points 4.16667 yd apart, two hex digits a cell = z * 6
local TERRAIN = { X0 = 5400.0000, Y0 = -5799.9999, STEP = 4.166666, N = 97, z = {} }
do
  local rows = {
    "0000000000000000000000000000000000000000000000000000000000000003090e151b22292e33373b3e404345474848494a4b4c4d4d4d4d4c4c4b4b4b4b4b4c4d4d4d4b4a46423d372f25190d03000000000000000000000000000000000000",
    "000000000000000000000000000000000000000000000000000000000000040a11171f262d32363a3e4043454748494a4a4b4b4c4d4e4e4e4d4d4c4c4c4c4c4c4d4f5050504f4d4946413c352c2013070000000000000000000000000000000000",
    "0000000000000000000000000000000000000000000000000000000000040b121a222a31373c4042454648494a4b4c4c4c4c4d4d4e4f4f4e4e4d4d4d4d4c4d4d4e5051525251504d4b48443f393125180b01000000000000000000000000000000",
    "00000000000000000000000000000000000000000000000000000000040b131c2731393e424647494a4b4b4c4d4d4e4e4d4e4e4e4f50504f4f4e4e4e4d4d4e4e4f5152535352514f4d4b4946423c352a1d0f030000000000000000000000000000",
    "000000000000000000000000000000000000000000000000000000030a15232f383f45484a4c4d4d4e4e4e4f4f4f50504f4f4f505151515150504f4f4e4e4e4f50525353535251504e4d4b4947443f382e21120500000000000000000000000000",
    "0000000000000000000000000000000000000000000000000000010d1c2a353e45494d4f505051515151515151515151515151515253535352525150504f5051525354535352514f4e4d4c4b494846413a30241506000000000000000000000000",
    "00000000000000000000000000000000000000000000000000061322303a42484d50525353535353535354535453535354535353545455555454535251515152535454545352504f4e4c4c4b4a4a4947423b322516070000000000000000000000",
    "0000000000000000000000000000000000000000000000040c1828363f464c4f5253545555565656565656565555555555565656565656565656555453535454555555545352504f4d4c4c4b4b4b4b4947433c3326170800000000000000000000",
    "0000000000000000000000000000000000000000000109131f2f3b444a4e51535455565656575757575757575757575757575757575757575757575656565656565656555452504f4d4c4c4b4b4b4b4b4a47433d33261708000000000000000000",
    "0000000000000000000000000000000000000000030e1c283541494e515354555656565757575757575757575757575757575757575757575757575757575757575756555453514f4e4d4c4b4b4b4c4c4b4947433c322515070000000000000000",
    "00000000000000000000000000000000000000081725313b454c505354555656565757575757575757575757565656575655555555565656575757575757575757575756555452504f4e4d4c4c4c4c4c4b4b4946423b3123130500000000000000",
    "0000000000000000000000000000000000010f1f2c37424a4f5254555656575757575757575756575756555455565556555555565655555656565657575757575757575756555452514f4e4e4d4d4d4c4c4c4b494641392f201003000000000000",
    "00000000000000000000000000000000061525333f474d515455565757575758575757575757565858565656595c5c5b595757575757575757565556565757575757575757565554535151504f4e4e4d4d4c4c4a48443f372c1d0c010000000000",
    "0000000000000000000000000000010a1a2b39444b5053555657575858585858585759595959595959595a5b5f605f5f5d59575757575757575757575655565657575757575757565554535251504e4e4e4d4c4a4846423c332818080000000000",
    "00000000000000000000000000020d1e303d474d51545556575758585959585757575a59595b5c5d5e62646363646565635c5b5a5b57575757575757575657565655565757575757575655545351504f4e4d4b4a4947443f392f23130400000000",
    "000000000000000000000000020f223340494f5354565657585859595a5a5a595a5b535252556266686b6c6967666561625a595c59575757595c5b5757575755555454555657575757575656545351504f4d4b4a494745423c352a1d0c01000000",
    "000000000000000000000002102434424b5053555656575859595a5b5c5c5c5c58514f4f50526b717172716c6a696762625d5757575757575757575757575755565756555556575757575757565453514f4d4c4b494846433f3930251606000000",
    "0000000000000000000001102434424b505455565657585b5a5c5d5d585555524f4b4e4d4d55737a7878746f6d7870625d5b575757575757575757575757575757575757575655575757575757565552504e4d4b4a494845413d352b1f0e010000",
    "000000000000000000000e2233414a50545556575758595b5d5f6060565352504b4a494a4c65787d7c7d79737a6b5d5c5c5a585758595b58575757575757575757575757575655565757575757575654514f4d4c4b4a4847443f39302516060000",
    "0000000000000000000a1f313f494f535556575758595b5e6062646458524e4c4a4849494e6a7b8382847f6e6e5f5e5c5b5a5b5d5b595a575757575757575757575a575757575655565758595957575553514f4d4c4a494846423c342a1d0e0000",
    "0000000000000000051a2d3c474e525556575758595b5d60636668696154514c4847474a5c74838a8a88808757545455545b5b5f5d575757575757575757575757575858585757565657585b5d5a57565452504e4d4c4b4a48443f382f23140400",
    "0000000000000000132737444d515456575758595b5c5e6367696b6d6c645c524f49494f758693938f8b88755755535353535c5c5d5857575757575757575757585a5a5e5b595757575656595c5c5957565452504e4d4c4a4946423b3227190a00",
    "000000000000000b2032404a505355565758595a5c5d62676a6c6e71716f665f5c54545f7f8c9494928e898577544d484953535c5d5a5757575757575757575a5d5f5f615c5b5a5b57565557595b5b59575553514f4e4d4b4a48453e342a1d0f00",
    "00000000000004182b3b464d5254565758595a5c5e63676a6d70727476787a746c6968717f8b949693918b8072544b49484b535c5d5b58575757575757575a5e59616262615f5f5e5857555457585c5d59575553514f4e4d4c4a4741382c211304",
    "000000000000102437434b5053565758595a5c5e62666a6e707375787c80808184808282868c939794918d8b7e544d49484a505e5f5e5d585757575757595c5d5f53535252525f5d5a5857545557595d5c58565553514f4e4d4c49443c30231608",
    "0000000000081c3140494e51545757585a5b5d6064696d717476787b7f82838286898f8f8c8e949795938b8b66544b46484b4f5d5a57585756565757585c5c5e53525252545254615c5e59575355575a5b5958565452514f4e4d4b463f3426190b",
    "000000000013293c464c5053565758595a5c5f61656b6f7376797b7d80848784848991948e8e929695958b7863534c46484c535d5b5757575656575757545e5352504f4f4f50515562615f5a575456575a5a5957555352504f4e4c4943382a1c0e",
    "00000000091f36444b4f525457575859595d6164686b7175787a7c7f8284878886878f94908f919293918b8865544f4a4c53535d5b575757565657585b5d5553514f4f4f4f4f4f505462615d5a585555585a5a585654535150504e4b463d2f1e10",
    "00000000122d404a4f5154565758595b5d6063676b6e7276797b7d7f8284858886868c908f8f8f92908e87787e56524f4f535c5e5c575757555557595b5d53524f4f4f4f4f4f4f4f505355605d5b575555585959575554535251504d4942342212",
    "000000051f39474e515355575758595b5e6265696d717375787a7c7e8183848383858a8d8d8c8e908e89867a6c59555253535c5e5d5b5757555557535554524f4f4f4f4f4f4f4f4f4e5052555f5a59575557585a59565554535251504c46392714",
    "0000000e2d414c515455565757585a5b5f65696b6f747777787879797e8282828383878a8a8d8f8c8b84837a6b5d595a5a5a5d5f5f5d57575455585a5c53524d4f4e4f4e4c4b4d4e4b4f50535e5b5a585455585b5b585655545353514f493e2d17",
    "0000001b37474f535556575758595b5c6169706c7176797b79797878787e808182818689888f8f89868081826c5e5958595858595858575453545a5b5d53524e4a474b4b4c4e4c4d494b4f50535d5b595654565a5c5a575655545453514c43331c",
    "000004273e4b515556575758595a5c5f62676e6f7276797b7c7c7b7876787d7f8080858682878786827c7d76675e59585b5757575757575353565b5c6053524d4c4f4f4f4f4f4f4f4c4e4f50525f5c5a585555595c5b575756565554534f473822",
    "00000f2f434d5255575757585a5a5c6063656a6e7276797a7b7c7b7977787d7e7f7e7d7b7a7c7f817f7c776d635d59575b5857575757525253595c5e5353514f4f4f4f4f4b4c4f4b4d4f4f4f515f5c5b58565457595a5757575756565450493c27",
    "00001a36464e5356575758595a5b5d606365696e727577797c7b7a7a7a7b7b7b7e7d7b797778787674716c66605b5857595b575757545252565a555f53524f504e4e4f4b44474d4e4e4e4f4f50535d5e5e575555575858575757575654504a3e2c",
    "0000223b484f54565757585a5a5a5e616366696d727575767d7d7a7a7b7c7a79787b7b7874706d6a696864605c5a595a585b585757525252575b5d5352524f4f4c494c494a4d4d4f4f4c4b4f50525d5c5e58575556585a5757575654524f4a4030",
    "00082a3e4a5054575758595a5a5b606264676a6e727677767677787a7c7e7d7876757577736e6a6563615e5b595a5a5957575757535352575a5c5e5353514f4f4f4e4a4e4d4d4d4f4f4c4d4f50525e5c6058575556575a5957565553514f4a4233",
    "001130424c5256575758595b595d626365686b6f73787c7b7877787a7d817e7d76737171716c67635f5c595a5b59595757575757535355575b5c5f53534f4f4f4f4e4e4f4f4f4f4f4f4f4f4f52535e5b5a59575454575b5c57565452514e4b4437",
    "001935454e53565758595a5b5c61636566686b6d6f7378797978787b7d827e7c7a766f6c6a6965615d5a585a5d5a5b5957575754535357575c5c5f53524f4f4f4f4d4f4f4f4f4f4e4b4e4f5252535e5a585757565557595c57565452504e4b453a",
    "052039475055575758595a5c5e63666a69696b6c6e7071747576787b7e817d7a7774706b6662615e5b5e5b57575a5d5b58575753535557575b5c5e5352504f4f4f4d4f4f4f4f4f4f4f4f5252525f5d5e5a5757575757575a57555452504e4c473e",
    "0c263d4a5156575758595b5c60656b706b6b6c6d7377797a7676797c7e7f7e7b75706c68625c5b5b59585c57575a5b5857575453535757575a5c525353525352525252525252525252525353616260645c5757575756575a58555452504f4c4841",
    "122b404b52565757585a5c5f63666a6d6c6d6d6e7379787776787a7c7e7f7f7e786e6764605b57565858595757575857575753535457575758545c5e53545461525252535352525453535f60636066645a5757575756575a59555453514f4d4a43",
    "182f424d53575757595c5c5f64686b6d6e6e6f6f70727374777a7d83867f7f7c786e68645e5b56555557575757595a59575652525757575858595b5d5e5e5e5e5e5f535354605e5d5d5e5d5f6464615c5757595c5755565a5956555352504f4c46",
    "1c33444e545757575a5d5d61666d716f7071707071727476797b7f8787807f7d746c69665e5958555453575757585957575252525757575b5a57585b5d5d5d5c5c585e5e5d585c5f5f5f5b5b5c5b5857575b5d5a57555659595755545352504d49",
    "2036464f54575757595d5d6268727171797772727374777a7c7e82878882807e766f6b69635a575754525457575757575752525257575757575757585a5b5a5c595c5b5b5b555a5d615d595757575757575b59575754565959575655545452504c",
    "2439474f545757575a5d5d636b7472767d77737374777a7f82858585878684807b746c69625d5957575454545656575758565557575757575757575758585857575857575757575758575757575757585c5f5b575754565a5b575756565554524f",
    "283b4850545757575a5e60646d7777787b78757577797c7f84898b8b8c8c888281796d6a64615e595757545354555857575757575757575757575757575757575756575757575757575757575757575757575757575556595a5757575756555351",
    "2a3d4950545657585b5f6266707b7c7c7c7b7778797c7e8084878b8f91908a86837d6f65615d59575757575654575757575757575757575755535353535251515151535557575757575757575656575757575757575556595c5757575756555451",
    "2c3f4a50545657585f64676b757f817f7f807c7b7d7e8183868b8b8e918f8d8c8a84715f5a595757575758575757575757575757565252515150515151515050504f5052545654535354545353535354545454555555565a5d5857575756565452",
    "2d404a505456575c6266687077808380808281808082838688918f8f9090909190927d5b5757575757585d57575757575757575756525151505050515251505151505051535653525353545353535354535353555557575a5d5757575756565452",
    "2e404a505355575e62686a71787f818181818182828485888b8e90929394949592965f5857575757575a5b57575757575757575756525151515051545555565656555454565657555556575757575655555556575756575a5c5757575756565452",
    "2e404a4f53555860646b6d707a808384848383838486878a8d9193969798989592717658575757575757575757575757575757575757555555565757575758595959585757575757575b5b585758585857575757575456595c5757575756565452",
    "2d3f494f52555860676f70727a8287878685858586888a8d9194979a9b9b98a2a3695a575757575757575757575757575757575757575757575859595a5759605f5b5f5b575759575a5f605a585a5b5b5c57575b5755575b5a5757575756555351",
    "2b3e484e5254585f6871747579838d8d89878788898a8d9094989b9e9ea492a5905c58575757575757575756555757575756565757575757575859595a595b61615d5d5f5f5e5d5e56615f575d5f615e605659565756575c595757575655545250",
    "293c474d515357606b7377777a828a8d8b898a8a8c8e9194989c9fa0a595836c5b5857575757575657565556555757575756565757575d5e5a595a5a5a5c575f5f5e5f5f5f5c5c5e5f5757575e60646256535152555556595b575756555453514f",
    "253a454c5052555e6c7577767b828c8e8b8c8c8d8f9295989c9fa19f9197825a5857575757575555565656575757595757565657575757595a595d5d5b5c5e57565656565657565656565657575e615f544c4c52565657595b575655545352504e",
    "2137434a4f525458687578767b828b8e8c8d8e8f9295999c9fa09ea16f5e5a5857575757575755555657575757575e575757565657575d58575d605f5c5e555352515151525151515252535556575e57554e505657565759595756555453514f4d",
    "1b3340494e515457657278787b81898e8c8d8e909396999c9d9ba2706059575757575757575656575757575757585c575757565557575e5a585d5c5855555251505050505050505050505152545657555453525557575759585756555452514f4c",
    "152e3d474c505357616d78797a7f858d8a8b8d8d8f9095a1a39e706f59575757575757575657575757575b58595759575757565455575858585a5b5a5d5d5150505050505050505050505051525452535353535356575759575756555352504e4b",
    "0d2839454b4f52575c697679797d818688898a8b8a8588949694605958575757575757575757575757575a585b5d585757575755555757585859595d5d51505050505050505050505050505050525253525252525657585a575756555352504e4a",
    "05213442494e51555963707777797d80828586868587896a5e5c5958575757575757575757575757575757575a5b5757575a5757565657585b5e5d5754515050505050505050505050505050505051525151515656555558575756555452504d49",
    "00182e3d474c4f53565f69747576787979797876726a765b5a58575757575756555557575757575757595957575a5c58575b5757575757595a5e605753515050505050505050505050505050505050515151515555515356575757555452504d48",
    "000f2638444a4e51545a646c7270726f6e6d6968625a5857575757575757565656565757575757575757595a5958595b57575757575556595961615754515050505050505050505050505050505050505151515552515255575757565553504c47",
    "00051e3241484d50535660666d6c6b6764665e5f595757575757575756555656575757575a59575757595a76785c58585757575757555558585e625756515050505050505050505050505050505050505051525451515154575757565553504b46",
    "0000142b3d474b4f52555c62646663605b5d5a5e575757575757575654555657575757595957585757939472725c5a57595757575756555757595957575250505050505050505050505050505050505050525655515151545757565655534f4a44",
    "00000a2137444a4e5255585e5f5f5d5b57585a5d585c585757565756565757575757575857595d7e8995999493865b57585a5a5857565456585b5d61575350505050505050505050505050505050505050545553515152545757565654524e4841",
    "000000173041494e5255575a5b5b5a58575757585d5b5756565556575757575757575757595f85999ca4a5a1927a5d5d6262615d58575556585c6163625451505050505050505050505050505050505050565651515152555756565553504b453d",
    "0000000c283d484d525657575959585557575758595756555556575757575959585757595f6d8ca6adafafacac9c886c716d69625a575656575b61636155525050505050505050505050505050505050505852515151535656565554524e484138",
    "000000021d37454c515657575757575556575757575654545556575757585b5a5857575b9a93b2afb2b2b2b0ab9b847c7a746c665b575656575a5f626156535050505050505050505050515050505050555651515152545655545352504b443c33",
    "00000000112f424b505457575757575655575757565554545557575d5a5757585a5d5c9ba5a6afb2b3b3b3b2afa8b288807972665b57565657595c5e605755515050505050505050505151515050505155515151515355545453514f4c473f372c",
    "0000000005253c494f5255565757575655575756565554555757575c595757595f93929ea8acb1b3b4b4b5b2b0abb2b2837b766a5a57565456585a5a5b62575451505050505050505151515151515157535151515254545352514f4d4841393026",
    "00000000001834464d505355565757575656565656565657575759595757585d629fa0a8acaeb1b3b5b5b9b6b0aca9a290817f705e585756565757585e626357545251505050515252515151515157565151515254555352504f4c48423a32291e",
    "00000000000a2a3e494d5052545657575756545556565758585a595757595f616692a6aaacaeb1b3b4b4b5b8b1acaaa5998b867c6b5f5b585656575a5c6165625755535252525455545251515156565151515254555352504e4c48433b322a2118",
    "0000000000001a35444b4e5052545657575755565757585b5c5c58585a6f776682a1a7aaacaeafb1b3b5b3b7b4acaaa59b8f8a857c6d5f5a565556595c5e626564575656565757575552515155565151515154565452504e4b48443d332a221a11",
    "0000000000000a273c474b4d4f515356575757575757585b5d5b595c617f87959ba2a7abacadadafb2b1b1afadaba8a39a928c88827a695c585655575a5c5e60615757565556575756525156555151515153565653514e4c48443d3429211a130c",
    "00000000000005173141484b4c4e505355575757555557595b5c5b60678991929ba1a5abacabacacadadadacaaa9a59e9996908c857f725f5855555657595a5a565f616161616257555256575151515151565655524f4c49443e362a201a130d07",
    "000000000000030d233843484a4c4e505355565756555557575a5d636a758490989fa4aaa8a8a9aaababaaa9a7a59f99928f8f90867f77665757555557575757595b5c5e60616257555657515151515152575654514e4a453f372c1f19120d0803",
    "000000000000020a162b3c4448494b4e515355575756555657595c5f69717c88939a9ea0a5a7a6a7a8a7a6a4a29f9c948e8b8887837e786d5a575555565757575b57575d5e5f57575756525151515151535654524f4c4740382e2017110c080300",
    "0000000000000008101f323f4547494c4e5153565757565657585b5e676d737c888f8f9599a09fa09f9e9d9c9c9d978e8a878583807c756f5e5755555455575757575a5c595757565755525151515152545553514e49423a2f2216100b07040000",
    "00000000000000060e1727374045484a4c4e5154565757575757585a62676e7579797d858b909291939494979b928c888482807e7c7a736b5e57575554565757575c5b595757565657555352525252535453514f4b453c3224160f0a0603000000",
    "00000000000000050b131d2d3a4246484b4c4f515456575757575858595b60696a6c727b7e818387898a8a8c8c878583817c7a79777871655c585757565557575758575756545457585856545353535453514f4c463e3326170d09050200000000",
    "000000000000000309101923323d4347494b4c4f515455575757575857575a5c5f656d71726e737b7f818282827e807e7d75737170706a605c5957575755555757575755565656585a57555453535251504e4b47403427180b0704010000000000",
    "0000000000000002070d151e28363f4447484a4c4e51535556575756555758595a5d5e6467676c7270797d7c7b777679796f69696967625c5e5e5b585756565656575656575757575655535251504f4e4d4b47403528180b050200000000000000",
    "0000000000000002050b111a232d39404446484a4b4d4f515356575758595958585a5d5e5f616365676e6d6e6c6d6b6e6d67656766625c5a5a5d5957575756555657575757575757555251504e4d4d4b4946413728190a03000000000000000000",
    "000000000000000204080e161f27303a4044464748494b4d5053555757585858585a5d5c5d5f605f5e5d5e5f5f606162636160605d5c5a585758575757555657575757575757565452504e4d4c4b4a48453f372918090000000000000000000000",
    "000000000000000003050a111a222a32394042434546484a4d5053555757575757595c5d5d5e5f5c595a5a5a5a59595a595959595857575756555655565657575d57575756555452504e4c4b4a4947443e36281709000000000000000000000000",
    "00000000000000000103070d141d252c33383d40424446484a4d5053555757575757595a5d5f5f5d5b5a59595958575757575655575556555555575757575757575757565553524f4d4b4a494846433e3427160700000000000000000000000000",
    "0000000000000000000104080e161e262c31363b3f414446484b4e515455565757575758595a5b5b5a5a59585857575657565656575757575757595857575757575756545351504d4b4a484745423c332615050000000000000000000000000000",
    "000000000000000000000204080e161e252b3035393e4144474a4d505254555656565757575758585857575757575757575757575757575757575656555556565656555352504e4c4a484745423c32251404000000000000000000000000000000",
    "00000000000000000000000205090e151c23292f34393d4245484b4e51535354545555565656565656575757575757575757575757575656565555545454555555555452514f4e4b494744413b3224140400000000000000000000000000000000",
    "0000000000000000000000000205080d131a21282e34393e42464a4d4f515152525253535354545556565657575756565656555555565656555454535353545454545352504e4d4b4845413b322313040000000000000000000000000000000000",
    "000000000000000000000000000204070a10171e262d33393e43474b4d4f4f4f5050504f50505152535455555656555555545453545454545353535353535353535352514f4e4b4946413a30221204000000000000000000000000000000000000",
    "0000000000000000000000000000010305070c131b232b32383e43474a4b4c4d4d4d4c4c4c4d4e4f505151525354545353535252525353535252525252525252525251504e4c494540392e1f100300000000000000000000000000000000000000",
    "00000000000000000000000000000000020405080e161f272e353c414446484949494949494a4b4b4c4c4d4f4f505151515151515151525251515151515151515151504f4c49453f372c1c0c010000000000000000000000000000000000000000",
    "00000000000000000000000000000000000102030509101820282f363a3d4042434444454646474748494a4b4c4d4d4e4f4f4f4f5050515050505050505050504f4f4d4b48433c3327160700000000000000000000000000000000000000000000",
    "00000000000000000000000000000000000000010203050a0f161d24292e3236393a3c3e3f4141424344464748494a4b4c4d4d4e4e4f4f4f4f4f4e4e4e4e4d4d4c4a48453f382e200e020000000000000000000000000000000000000000000000",
    "00000000000000000000000000000000000000000001010204070b1014191e2226292c30333537393b3d3f414344454748494a4b4b4c4d4d4c4c4c4b4b4a494745433f393125160701000000000000000000000000000000000000000000000000"
  }
  for j, row in ipairs(rows) do
    local line = {}
    for i = 1, TERRAIN.N do line[i] = tonumber(row:sub(2 * i - 1, 2 * i), 16) / 6 end
    TERRAIN.z[j] = line
  end
end
local function tableZ(x, y)
  local fi, fj = (x - TERRAIN.X0) / TERRAIN.STEP, (y - TERRAIN.Y0) / TERRAIN.STEP
  if fi < 0 or fj < 0 or fi >= TERRAIN.N - 1 or fj >= TERRAIN.N - 1 then return nil end
  local i, j = math.floor(fi), math.floor(fj)
  local a, b = fi - i, fj - j
  local r0, r1 = TERRAIN.z[j + 1], TERRAIN.z[j + 2]
  return r0[i + 1] * (1 - a) * (1 - b) + r0[i + 2] * a * (1 - b) + r1[i + 1] * (1 - a) * b + r1[i + 2] * a * b
end
local function groundZ(g, x, y)
  local tz = tableZ(x, y)
  local z = try(mapOf(g), "GetHeight", x, y)
  if type(z) == "number" and z > -100 and z < 200 and (not tz or math.abs(z - tz) <= 8) then
    if not g.groundSaid then g.groundSaid = true; log(string.format("ground: the server's height lookup answers (%.1f; terrain table %s)", z, tz and string.format("%.1f", tz) or "-")) end
    return z
  end
  if tz and not g.groundSaid then g.groundSaid = true; log("ground: the server's height lookup gave " .. tostring(z) .. ", using the built-in terrain table") end
  return tz
end
local function spawnWonka(g)
  local a = anchor(g)
  if not a then return end
  local x, y, z
  for _ = 1, 8 do
    local ang, r = math.random() * 2 * math.pi, WK.SPAWN_RMIN + math.random() * (WK.SPAWN_RMAX - WK.SPAWN_RMIN)
    x, y = WK.CENTER[1] + r * math.cos(ang), WK.CENTER[2] + r * math.sin(ang)
    z = groundZ(g, x, y)
    if z and z <= WK.SPAWN_ZMAX then break end
    z = nil
  end
  if not z then                                             -- no height data answer: flat ring close to the middle
    local ang = math.random() * 2 * math.pi
    x, y, z = WK.CENTER[1] + 40 * math.cos(ang), WK.CENTER[2] + 40 * math.sin(ang), 14.5
  end
  local c = a:SpawnCreature(E.WONKA, x, y, z + 0.3, math.random() * 6.28, TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if not c then
    if not g.noWonka then g.noWonka = true; log("could not spawn a Wonka (template " .. E.WONKA .. " missing? run the SQL)") end
    return
  end
  try(c, "SetDisplayId", WONKA_LOOKS[math.random(#WONKA_LOOKS)])
  try(c, "SetScale", WK.WONKA_SCALE)
  try(c, "SetSpeed", 1, WK.WONKA_SPEED, true)
  try(c, "MoveRandom", 6)
  local need = (math.random(4) == 1) and 2 or 1             -- 'some of these little birds are more stubborn': one in four wants two bananas
  g.wonkas[c:GetGUIDLow()] = { guid = c:GetGUID(), need = need, trust = {} }
  g.wonkaCount = g.wonkaCount + 1
end
local function followers(g, low)
  local t = {}
  for wl, w in pairs(g.wonkas) do if w.owner == low then t[#t + 1] = wl end end
  return t
end
local function setFollowAura(g, low)
  local m = g.members[low]; local pl = getPlayer(g, low)
  if not (m and pl) then return end
  local n = #followers(g, low)
  if n > 0 and not m.followAura then try(pl, "AddAura", S.FOLLOWING, pl); m.followAura = true
  elseif n == 0 and m.followAura then try(pl, "RemoveAura", S.FOLLOWING); m.followAura = nil end
  if n > 0 then local au = try(pl, "GetAura", S.FOLLOWING); if au then try(au, "SetStackAmount", n) end end   -- v1.2: the live aura counts them (it stacks to 99)
end
local function mountRate(m) return (m and (m.sprinting or m.sprintUntil)) and WK.SPRINT_SPEED or WK.MOUNT_SPEED end   -- v1.2g: what a rider's mount runs at right now
local function pace(g, low)                                 -- v1.2g: the Wonkas that follow a rider run a little faster than his mount, so they keep up
  local m = g.members[low]
  for _, wl in ipairs(followers(g, low)) do
    local w = g.wonkas[wl]
    if w then try(obj(g, w.guid), "SetSpeed", 1, mountRate(m) * WK.FOLLOW_X, true) end
  end
end
local function follow(g, wl, low)
  local w, m = g.wonkas[wl], g.members[low]
  local c, lead = obj(g, w.guid), mountOf(g, m) or getPlayer(g, low)
  if not (c and lead) then return end
  w.owner = low; w.trust = {}
  local n = #followers(g, low)
  try(c, "MoveClear")
  try(c, "MoveFollow", lead, 2 + 0.6 * (n % 6), (n * 1.3) % 6.28)
  try(c, "AddAura", S.HAPPY, c); try(c, "AddAura", COLORS[m.slot].aura, c)
  setFollowAura(g, low)
  pace(g, low)                                              -- v1.2g
end
local function release(g, wl, scared)
  local w = g.wonkas[wl]
  local c = obj(g, w.guid)
  local old = w.owner
  w.owner = nil; w.trust = {}
  if c then
    if old and g.members[old] then try(c, "RemoveAura", COLORS[g.members[old].slot].aura) end
    try(c, "SetSpeed", 1, WK.WONKA_SPEED, true)             -- v1.2g: its own speed again
    try(c, "RemoveAura", S.HAPPY); try(c, "MoveClear"); try(c, "MoveRandom", scared and 15 or 6)
  end
  if old then setFollowAura(g, old) end
end
local function removeWonka(g, wl, ms)
  local w = g.wonkas[wl]
  if not w then return end
  local c = obj(g, w.guid)
  if c then c:DespawnOrUnsummon(ms or 0) end
  g.wonkas[wl] = nil; g.wonkaCount = math.max(0, g.wonkaCount - 1)
end

-- ---------- bananas ----------
local function thrower(g, food, t)                          -- who threw this banana
  local o = try(food, "GetOwner")
  if o then
    local low = o:GetGUIDLow()
    if g.members[low] then return low end
    if g.mountOwner[low] then return g.mountOwner[low] end
  end
  local best, bt                                            -- else: the most recent throw nobody has been credited for
  for low, m in pairs(g.members) do
    if m.threwAt and t - m.threwAt < 4000 and (not bt or m.threwAt > bt) then best, bt = low, m.threwAt end
  end
  if best then g.members[best].threwAt = nil end
  return best
end
local function tickFood(g, t)
  local a = anchor(g)
  if not a then return end
  for _, food in ipairs(try(a, "GetCreaturesInRange", 260, E.FOOD) or {}) do
    local fl = food:GetGUIDLow()
    if not g.foodSeen[fl] then
      g.foodSeen[fl] = true
      local low = thrower(g, food, t)
      if low then
        local fx, fy, fed = food:GetX(), food:GetY(), 0
        for wl, w in pairs(g.wonkas) do
          if not w.owner and fed < WK.FEED_MAX then
            local c = obj(g, w.guid)
            if c and dist2(c:GetX(), c:GetY(), fx, fy) <= WK.FEED_R then
              fed = fed + 1
              w.trust[low] = (w.trust[low] or 0) + 1
              if w.trust[low] >= w.need then follow(g, wl, low) else try(c, "PerformEmote", 5) end   -- stubborn one: wants another
            end
          end
        end
      end
    end
  end
end

-- ---------- scoring ----------
local function score(g, low, pl, t)
  local list = followers(g, low)
  if #list == 0 then return end
  local m = g.members[low]
  for _, wl in ipairs(list) do
    local c = obj(g, g.wonkas[wl].guid)
    if c then try(c, "CastSpell", c, S.SCORE, true) end
    removeWonka(g, wl, 1500)
  end
  m.score = m.score + #list
  setFollowAura(g, low)
  local col = COLORS[m.slot]
  log(string.format("%s rescued %d wonka%s. %s Wonka: %d", m.name, #list, #list == 1 and "" or "s", col.name, m.score))   -- v1.2: not a chat line on live (the HUD shows it)
  credit(pl, E.SCORED, #list); hudScores(g)                 -- v1.2: 'Score a total of N wonkas' (90226-28)
  pl:SendAreaTriggerMessage(string.format("+%d   (%s Wonka: %d)", #list, col.name, m.score))
  if #list == 1 then giveAch(pl, ACH.SINGLE) end
  if #list >= 10 then giveAch(pl, ACH.MAMA) end
end
local function scoreboard(g, left)
  local parts = {}
  for _, col in ipairs(COLORS) do
    for _, m in pairs(g.members) do if COLORS[m.slot] == col then parts[#parts + 1] = col.name .. " " .. m.score end end
  end
  tell(g, WT .. "End of Game: " .. mmss(left) .. "   " .. table.concat(parts, " | "))
end

-- ---------- leaving ----------
local function sendHome(g, low)
  local m = g.members[low]
  local pl = getPlayer(g, low)
  if not (m and pl) then return end
  for _, wl in ipairs(followers(g, low)) do release(g, wl) end
  dropMount(g, low, pl)
  hudOff(pl)                                                -- v1.2
  music(pl, 0)                                              -- v1.2d
  for _, a in ipairs({ S.AV_HYDRA, S.AV_BOLT, S.AV_BOMB, S.APPLAUSE, COLORS[m.slot].aura }) do try(pl, "RemoveAura", a) end
  local h = m.home or WK.FAIRE_SPOT
  later(m.guid, 600, function(p) if p:GetMapId() == WK.MAP then p:Teleport(h[1], h[2], h[3], h[4], h[5]) end end)
end
local clearStageTwoFn                                       -- set below (stage two is defined after cleanup)
local function cleanup(g, why)
  if clearStageTwoFn then clearStageTwoFn(g) end
  for low, _ in pairs(g.members) do local pl = getPlayer(g, low); if pl then try(pl, "RemoveAura", S.READY) end end
  for wl, _ in pairs(g.wonkas) do removeWonka(g, wl, 0) end
  local z = obj(g, g.zoneGuid); if z then z:DespawnOrUnsummon(0) end
  local ot = obj(g, g.ottoGuid); if ot then ot:DespawnOrUnsummon(0) end   -- v1.2b
  local po = obj(g, g.portalGuid); if po then po:DespawnOrUnsummon(0) end   -- v1.2c
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then sendHome(g, low) else local c = mountOf(g, m); if c then c:DespawnOrUnsummon(0) end end
  end
  if g.inst then Games[g.inst] = nil end
  log("game closed (" .. tostring(why) .. ")")
end

-- ---------- v1.1 stage two: storm, hydras, plants, Bomb-Bots, eggs ----------
local function helper(g, entry, x, y, z, life, aura)
  local a = anchor(g)
  if not a then return nil end
  local c = a:SpawnCreature(entry, x, y, z, math.random() * 6.28, TEMPSUMMON_TIMED_DESPAWN, life)
  if c and aura then try(c, "AddAura", aura, c) end
  return c
end
local function spotNear(g, x, y, rmin, rmax)
  local ang, r = math.random() * 2 * math.pi, rmin + math.random() * (rmax - rmin)
  local sx, sy = x + r * math.cos(ang), y + r * math.sin(ang)
  return sx, sy, (groundZ(g, sx, sy) or 14.5)
end
local function ringSpot(g, rmin, rmax)                      -- a spot on the ring round the centre, off the steep hills
  for _ = 1, 8 do
    local x, y, z = spotNear(g, WK.CENTER[1], WK.CENTER[2], rmin, rmax)
    if z <= WK.SPAWN_ZMAX then return x, y, z end
  end
  local x, y = spotNear(g, WK.CENTER[1], WK.CENTER[2], 30, 45)
  return x, y, 14.5
end
local function eachRider(g, fn)
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) and not m.onFoot then fn(low, m, pl, pl:GetX(), pl:GetY()) end   -- v1.2h: not who has got off his Wonka
  end
end
local function randomRider(g)
  local t = {}
  eachRider(g, function(low, m, pl, x, y) t[#t + 1] = { low, x, y } end)
  if #t == 0 then return nil end
  return t[math.random(#t)]
end
local function launch(g, mc, fromX, fromY, back, up)        -- v1.2h: 'launched into the air' (Rowan): the mount jumps up and away from the blast; v1.2i: or how far and how high it is told
  if not mc then return end
  back, up = back or WK.LIFT_BACK, up or WK.LIFT_UP
  local x, y = mc:GetX(), mc:GetY()
  local d = dist2(x, y, fromX, fromY)
  local ux, uy
  if d > 0.3 then ux, uy = (x - fromX) / d, (y - fromY) / d
  else local o = mc:GetO(); ux, uy = -math.cos(o), -math.sin(o) end   -- right on top of it: backwards
  local lx, ly = x + ux * back, y + uy * back
  local air = 2 * up / 19.29                                 -- seconds in the air at that take-off speed
  try(mc, "MoveJump", lx, ly, groundZ(g, lx, ly) or mc:GetZ(), back / air, up)
end
local function shock(g, low, t, ms, scatter, delay)         -- mount disabled for ms; with scatter the followers run off; v1.2d: delay = held only after that long (a blast throws it first: a held mount is not moved)
  local m = g.members[low]
  if not m then return 0 end
  m.shockUntil = t + (delay or 0) + ms
  if delay and delay > 0 then later(m.guid, delay, function() if m.shockUntil then hold(mountOf(g, m), true) end end)
  else hold(mountOf(g, m), true) end
  local list = followers(g, low)
  if scatter then for _, wl in ipairs(list) do release(g, wl, true) end end
  return #list
end
local function tickStorm(g, t)
  if not g.stormUntil and t >= g.nextStorm then              -- v1.2: once a game, and it stays to the end (live: one line at 59:33, strikes to 67:00)
    g.stormUntil = g.endAt; g.nextBolt = t + 2000; g.nextThunder = t + WK.THUNDER_EVERY
    tell(g, WT .. "Storm incoming! Watch the lightning strikes.", "Storm incoming! Watch the lightning strikes.")
    local sc = helper(g, E.STORM, WK.CENTER[1], WK.CENTER[2], WK.CENTER[3] + 25, math.max(1000, g.endAt - t))
    g.stormGuid = sc and sc:GetGUID()
  end
  if g.stormUntil then
    if t >= (g.nextThunder or 0) then                        -- v1.2d: live, thunder every 20 s through the storm
      g.nextThunder = (g.nextThunder or t) + WK.THUNDER_EVERY
      soundAll(g, SND_THUNDER)
    end
    if t >= g.nextBolt then
      g.nextBolt = t + WK.BOLT_EVERY
      local r = randomRider(g)
      if r then
        local x, y, z = spotNear(g, r[2], r[3], WK.BOLT_NEAR, WK.BOLT_FAR)   -- v1.2: beside a rider, never on top of one (was 0-9): live players go whole games without a hit ('Environment Avoided', 67:15)
        local c = helper(g, E.STORMZONE, x, y, z, WK.BOLT_WARN + 1500, S.BOLTZONE)
        g.bolts[#g.bolts + 1] = { guid = c and c:GetGUID(), x = x, y = y, at = t + WK.BOLT_WARN }
      end
    end
  end
  for i = #g.bolts, 1, -1 do
    local b = g.bolts[i]
    if t >= b.at then
      local zc = obj(g, b.guid); if zc then playKit(g, zc, KIT_BOLT) end   -- v1.2d: the bolt itself, down on the marked spot (Rowan: 'missing the lightning coming down itself')
      eachRider(g, function(low, m, pl, x, y)
        if dist2(x, y, b.x, b.y) <= WK.BOLT_R and not m.shockUntil then
          try(mountOf(g, m), "AddAura", S.SHOCK, mountOf(g, m))
          shock(g, low, t, WK.SHOCK_MS, true)
          m.struck = (m.struck or 0) + 1; try(pl, "RemoveAura", S.AV_BOLT)   -- v1.2: 'Environment Avoided' is lost
          pl:SendAreaTriggerMessage("Electrocuted!")
        end
      end)
      table.remove(g.bolts, i)
    end
  end
end
-- v1.2d: the ROADS of the tent, read off the road texture of the client map tile (wonka-road-points.py): five spoke roads from the platform out to a
-- ring road. Points are yards north (+x) and west (+y) of the middle; the ring is its radius every 3 degrees of bearing (0 = north, clockwise).
local ROADS = {
  spokes = {
    { bearing = 0, { 36.0, 1.3 }, { 44.0, -1.5 }, { 51.9, -2.7 }, { 60.0, -2.1 }, { 67.9, -3.6 }, { 76.0, -0.0 }, { 84.0, -0.0 }, { 92.0, 1.6 }, { 100.0, -0.0 }, { 108.0, -0.0 }, { 116.0, -0.0 }, { 124.0, -0.0 }, { 132.0, 2.3 }, { 140.0, -0.0 }, { 148.0, -2.6 } },
    { bearing = 68, { 11.1, -34.2 }, { 15.0, -41.3 }, { 17.8, -48.9 }, { 23.4, -55.2 }, { 26.6, -62.6 }, { 32.1, -68.9 }, { 35.5, -76.1 }, { 35.9, -84.7 }, { 34.2, -94.0 }, { 38.7, -100.8 }, { 41.6, -108.3 }, { 46.5, -115.0 }, { 49.4, -122.4 }, { 54.7, -128.9 }, { 60.2, -135.2 } },
    { bearing = 142, { -30.2, -19.6 }, { -35.6, -25.9 }, { -42.6, -29.8 }, { -47.9, -36.1 }, { -53.6, -41.9 }, { -59.9, -46.8 }, { -66.2, -51.7 }, { -72.5, -56.6 }, { -79.9, -60.2 }, { -83.9, -68.0 }, { -88.9, -74.6 }, { -99.0, -74.6 }, { -105.4, -79.4 }, { -111.8, -84.3 }, { -116.6, -91.1 } },
    { bearing = 218, { -26.3, 24.6 }, { -34.2, 27.7 }, { -41.0, 32.0 }, { -47.3, 36.9 }, { -52.8, 42.8 }, { -59.1, 47.8 }, { -65.3, 52.9 }, { -71.5, 57.9 }, { -77.7, 62.9 }, { -85.1, 66.5 }, { -92.6, 69.8 }, { -99.0, 74.6 }, { -104.0, 81.3 }, { -110.3, 86.2 }, { -116.6, 91.1 } },
    { bearing = 290, { 9.3, 34.8 }, { 13.6, 41.8 }, { 18.6, 48.5 }, { 21.5, 56.0 }, { 23.3, 63.9 }, { 24.7, 71.9 }, { 27.3, 79.4 }, { 26.9, 88.0 }, { 30.9, 95.1 }, { 36.9, 101.5 }, { 39.7, 109.0 }, { 44.4, 115.8 }, { 49.4, 122.4 }, { 50.2, 130.7 }, { 55.4, 137.2 } },
  },
  ring = { 142, 148, 154, 156, 158, 157, 156, 156, 156, 155, 154, 154, 154, 153, 152, 153, 154, 155, 156, 157, 158, 154, 150, 154, 158, 159, 160, 160, 160, 158, 156, 157, 158, 158, 158, 158, 158, 159, 160, 160, 159, 160, 160, 160, 160, 160, 160, 160, 160, 159, 158, 158, 158, 157, 156, 157, 158, 160, 162, 162, 162, 160, 158, 158, 158, 158, 158, 158, 158, 159, 160, 160, 160, 160, 160, 160, 160, 160, 159, 160, 160, 159, 158, 158, 158, 157, 156, 157, 158, 159, 160, 159, 158, 158, 158, 159, 160, 158, 156, 156, 156, 157, 158, 157, 156, 156, 156, 157, 158, 158, 158, 157, 156, 156, 156, 156, 156, 156, 156, 149 },
}
local ROUTES = {}                                           -- one per spoke: out along it, round the ring to the next spoke, in again (walked there and back)
do
  local function at(dn, dw) return { WK.CENTER[1] + dn, WK.CENTER[2] + dw } end
  local n = #ROADS.spokes
  for k = 1, n do
    local a, b = ROADS.spokes[k], ROADS.spokes[k % n + 1]
    local route = {}
    for i = 1, #a do route[#route + 1] = at(a[i][1], a[i][2]) end
    local b0, b1 = a.bearing, b.bearing
    if b1 <= b0 then b1 = b1 + 360 end
    for deg = math.floor(b0 / 3) * 3 + 3, b1 - 1, 3 do
      local r, rad = ROADS.ring[(deg % 360) / 3 + 1], math.rad(deg)
      route[#route + 1] = at(r * math.cos(rad), -r * math.sin(rad))
    end
    for i = #b, 1, -1 do route[#route + 1] = at(b[i][1], b[i][2]) end
    ROUTES[k] = route
  end
end
local function spawnHydras(g, t)                            -- v1.2d: 'The hydras are bigger and patrol up and down the road and around the roads' (Rowan)
  for k = 1, WK.HYDRAS do
    local route = ROUTES[(k - 1) % #ROUTES + 1]
    local i = math.random(math.floor(#route / 3), #route - 3)   -- out on the roads, not by the platform
    local p = route[i]
    local c = helper(g, E.HYDRA, p[1], p[2], groundZ(g, p[1], p[2]) or 14.5, LIFE)
    if c then try(c, "SetScale", WK.HYDRA_SCALE); try(c, "SetWalk", false); try(c, "SetSpeed", 1, WK.HYDRA_SPEED, true) end
    if c and not g.rootSaidH and try(c, "IsRooted") == true then g.rootSaidH = true; log("the hydras are ROOTED by creature_template_movement and will not move: run Azzar-Wonka-Wonka-Apply.bat (SQL of 2026-11-17), then .reload creature_template 99741 99742 99743 99744 99745 99751 99757") end   -- v1.2g
    g.hydras[#g.hydras + 1] = { guid = c and c:GetGUID(), route = route, i = i, dir = (k % 2 == 0) and 1 or -1, x = p[1], y = p[2], armAt = t + WK.HYDRA_WARN }
  end
  soundAll(g, SND_HYDRA)                                     -- live 60:03.5, once
end
local function tickHydras(g, t)
  if not g.hydraSaid and t >= g.nextHydra then               -- live says it once (60:02), 0:48 into the game; from then on they are out
    g.hydraSaid = true
    tell(g, WT .. "Hydras emerging! Keep moving!", "Hydras emerging! Keep moving!")
    spawnHydras(g, t)
  end
  for i = #g.hydras, 1, -1 do
    local h = g.hydras[i]
    local c = obj(g, h.guid)
    if not c then table.remove(g.hydras, i)
    else
      h.x, h.y = c:GetX(), c:GetY()
      local wp = h.route[h.i]
      if h.speed ~= WK.HYDRA_SPEED then h.speed = WK.HYDRA_SPEED; try(c, "SetSpeed", 1, WK.HYDRA_SPEED, true) end   -- v1.2h: also after '#ww hydraspeed'
      local there = dist2(h.x, h.y, wp[1], wp[2]) < math.max(4, WK.HYDRA_SPEED * 7 * 0.6)
      if there or t >= (h.moveBy or 0) then                  -- on to the next point of its road (or sent again if it has stopped)
        if there then
          if h.i + h.dir > #h.route or h.i + h.dir < 1 then h.dir = -h.dir end
          h.i = h.i + h.dir; wp = h.route[h.i]
        end
        try(c, "MoveTo", 0, wp[1], wp[2], groundZ(g, wp[1], wp[2]) or c:GetZ())
        h.moveBy = t + 8000
      end
      if t >= h.armAt then
        for wl, w in pairs(g.wonkas) do                      -- 'Devourawonkas': it eats the Wonkas that follow somebody past it
          local owner = w.owner
          if owner then
            local wc = obj(g, w.guid)
            if wc and dist2(wc:GetX(), wc:GetY(), h.x, h.y) <= WK.HYDRA_R then
              removeWonka(g, wl, 300); setFollowAura(g, owner)
              local m, pl = g.members[owner], getPlayer(g, owner)
              if m then m.eaten = (m.eaten or 0) + 1; m.hydraHit = true end   -- 'Predator Avoided' is lost
              if pl then try(pl, "RemoveAura", S.AV_HYDRA); pl:SendAreaTriggerMessage("A hydra ate one of your wonkas!") end
            end
          end
        end
      end
    end
  end
end
local function tickPlants(g, t)
  for _, p in ipairs(g.plants) do
    if p.upUntil and t >= p.upUntil then p.upUntil = nil; p.readyAt = t + WK.PLANT_REARM end
    if not p.upUntil and t >= (p.readyAt or 0) then
      eachRider(g, function(low, m, pl, x, y)
        if not p.upUntil and dist2(x, y, p.x, p.y) <= WK.PLANT_R then
          p.upUntil = t + WK.PLANT_UP
          helper(g, E.PLANT, p.x, p.y, p.z, WK.PLANT_UP, S.EMERGE)
          local list, ate = followers(g, low), 0
          for i = 1, math.min(WK.PLANT_EATS, #list) do removeWonka(g, list[i], 300); ate = ate + 1 end
          setFollowAura(g, low)
          shock(g, low, t, 2000, false)
          m.eaten = (m.eaten or 0) + ate
          pl:SendAreaTriggerMessage(ate > 0 and ("A carnivorous plant ate " .. ate .. " of your wonkas!") or "A carnivorous plant! Your Wonka is stuck for a moment.")
        end
      end)
    end
  end
end
local function spawnBot(g, t)
  local x, y, z = ringSpot(g, WK.BOT_RMIN, WK.BOT_RMAX)
  local c = helper(g, E.BOMBBOT, x, y, z, LIFE, S.BOMBVIS)  -- 256052 = the red dashed ring round it
  g.bots[#g.bots + 1] = { guid = c and c:GetGUID(), x = x, y = y, born = t }
end
local function botHop(g, b)                                 -- v1.2d: 'not stationary but move in large random patterns' (Rowan): a new far spot to make for
  local x, y, z
  for _ = 1, 6 do
    x, y, z = spotNear(g, b.x, b.y, WK.BOT_HOP_MIN, WK.BOT_HOP_MAX)
    local r = dist2(x, y, WK.CENTER[1], WK.CENTER[2])
    if z <= WK.SPAWN_ZMAX and r >= 22 and r <= 165 then break end
    x = nil
  end
  if not x then x, y = ringSpot(g, WK.BOT_RMIN, WK.BOT_RMAX) end
  b.tx, b.ty, b.lx, b.ly = x, y, nil, nil
end
local function botStep(g, b, c, t)                          -- v1.2d: on towards it a short leg at a time (each leg ends on the ground: over a hill, not through it)
  if not b.set then
    b.set = true; try(c, "SetWalk", false); try(c, "SetSpeed", 1, WK.BOT_SPEED, true)
    if not g.rootSaidB and try(c, "IsRooted") == true then g.rootSaidB = true; log("the land bombs are ROOTED by creature_template_movement and will not move: run Azzar-Wonka-Wonka-Apply.bat (SQL of 2026-11-17), then .reload creature_template 99741 99742 99743 99744 99745 99751 99757") end   -- v1.2g
    if WK.BOT_FUSE then try(c, "AddAura", S.FUSE, c) end
  end
  if b.speed ~= WK.BOT_SPEED then b.speed = WK.BOT_SPEED; try(c, "SetSpeed", 1, WK.BOT_SPEED, true) end   -- v1.2h: also after '#ww bombspeed'
  local ahead = math.max(3.5, WK.BOT_SPEED * 7 * 0.6)       -- v1.2h: sent on before it gets there (what it covers in a tick and a bit), so it never stops between legs
  if b.lx and dist2(b.x, b.y, b.lx, b.ly) > ahead then
    if t < b.legBy then return end                          -- still on its way
    b.tx = nil                                              -- it did not get there (something in the way): another spot
  end
  for _ = 1, 4 do
    if not b.tx or dist2(b.x, b.y, b.tx, b.ty) < 3 then botHop(g, b) end
    local d = dist2(b.x, b.y, b.tx, b.ty)
    local k = math.min(1, math.max(WK.BOT_LEG, ahead * 2.2) / math.max(d, 0.1))
    b.lx, b.ly = b.x + (b.tx - b.x) * k, b.y + (b.ty - b.y) * k
    if dist2(b.lx, b.ly, WK.CENTER[1], WK.CENTER[2]) >= 20 then break end   -- not across the platform, where the Wonkas are handed in
    b.tx = nil
  end
  b.legBy = t + 4000
  try(c, "MoveTo", 0, b.lx, b.ly, groundZ(g, b.lx, b.ly) or c:GetZ())
end
local function tickBots(g, t)                               -- v1.2: Walking Land Bombs: in the tent from the start, off on touch (live 59:29, 59:38, 60:50); v1.2d: roaming
  if #g.bots < WK.BOTS and t >= (g.nextBot or 0) then g.nextBot = t + 1000; spawnBot(g, t) end
  for i = #g.bots, 1, -1 do
    local b = g.bots[i]
    local c = obj(g, b.guid)
    if c then b.x, b.y = c:GetX(), c:GetY() end
    local boom = false
    if not c then boom = nil                                -- it is gone: forget it, another one comes
    else
      if b.pushedAt and t >= b.pushedAt + 4000 then b.pushedBy, b.pushedAt = nil, nil; try(c, "SetSpeed", 1, WK.BOT_SPEED, true); b.tx, b.lx = nil, nil end   -- an Air Blast push wears off
      if not b.pushedAt then botStep(g, b, c, t) end
      if t >= b.born + WK.BOT_ARM then
        eachRider(g, function(low, m, pl, x, y) if dist2(x, y, b.x, b.y) <= WK.BOT_TOUCH then boom = true end end)
      end
    end
    if boom then
      try(c, "MoveClear"); playKit(g, c, KIT_BOOM)          -- v1.2d: 'the exploding bomb effect' (Rowan) = the explosion of live's own 'Bomb' spell
      eachRider(g, function(low, m, pl, x, y)
        if dist2(x, y, b.x, b.y) <= WK.BOT_R then
          local mc = mountOf(g, m)
          if mc then playKit(g, mc, KIT_BOOM); launch(g, mc, b.x, b.y) end   -- v1.2d: 'lift up in the air slightly' (Rowan); v1.2h: by a jump of the mount, away from the bomb
          for _, fire in ipairs({ S.ONFIRE, S.ONFIRE2 }) do    -- v1.2e: 'on fire from the explosion whilst being lifted up in the air' (Rowan; live 59:29.6-59:32.2)
            local fa = try(mc, "AddAura", fire, mc)
            if type(fa) == "userdata" then try(fa, "SetDuration", WK.SHOCK_MS + WK.LIFT_MS + 400) end   -- and never longer than this, whatever happens to the mount
          end
          shock(g, low, t, WK.SHOCK_MS, true, WK.LIFT_MS)      -- held once it has come down
          m.bombed = (m.bombed or 0) + 1; try(pl, "RemoveAura", S.AV_BOMB)   -- 'Explosion Avoided' is lost
          local by = b.pushedBy and b.pushedBy ~= low and g.members[b.pushedBy]
          if by then                                        -- pushed into a rider by an Air Blast: 'Take that!' (90223)
            tell(g, WT .. m.name .. " just ate a bomb from " .. by.name .. ".", m.name .. " just ate a bomb from " .. by.name .. ".")
            local pp = getPlayer(g, b.pushedBy); if pp then giveAch(pp, ACH.TAKE_THAT) end
          end
          log(m.name .. " was hit by a Walking Land Bomb" .. (by and (" pushed by " .. by.name) or ""))
        end
      end)
      c:DespawnOrUnsummon(500)
    end
    if boom ~= false then table.remove(g.bots, i); g.nextBot = t + WK.BOT_BACK end
  end
end
local function tickEggs(g, t)
  local n = 0
  for _ in pairs(g.eggs) do n = n + 1 end
  if n < WK.EGGS and t >= (g.nextEgg or 0) then
    g.nextEgg = t + 4000
    local x, y, z = ringSpot(g, 25, 110)
    local c = helper(g, E.EGG, x, y, z + 0.2, LIFE)
    if c then g.eggs[c:GetGUIDLow()] = { guid = c:GetGUID(), x = x, y = y } end
  end
  for el, e in pairs(g.eggs) do
    eachRider(g, function(low, m, pl, x, y)
      if g.eggs[el] and dist2(x, y, e.x, e.y) <= WK.EGG_R then
        local c = obj(g, e.guid); if c then c:DespawnOrUnsummon(0) end
        g.eggs[el] = nil
        m.grenades = (m.grenades or 0) + 1; m.eggs = (m.eggs or 0) + 1; credit(pl, E.EGGOPEN)   -- v1.2: 'Open N Wonka eggs' (90229-31)
        pl:SendAreaTriggerMessage("Hand grenade! (" .. m.grenades .. ")  Button 4: aim it at a rival.")
      end
    end)
  end
end
local function startStageTwo(g, t)
  g.bolts, g.hydras, g.bots, g.eggs, g.plants = {}, {}, {}, {}, {}
  g.nextStorm, g.nextHydra, g.nextBot = t + WK.STORM_FIRST, t + WK.HYDRA_FIRST, t
  g.stormUntil, g.stormGuid, g.hydraSaid, g.nextEgg = nil, nil, nil, nil   -- v1.2: a new round starts clean
  for _ = 1, WK.PLANTS do local x, y, z = ringSpot(g, 30, 100); g.plants[#g.plants + 1] = { x = x, y = y, z = z } end
end
local function clearStageTwo(g)
  for _, list in ipairs({ g.bolts or {}, g.hydras or {}, g.bots or {} }) do
    for _, h in ipairs(list) do local c = obj(g, h.guid); if c then c:DespawnOrUnsummon(0) end end
  end
  for _, e in pairs(g.eggs or {}) do local c = obj(g, e.guid); if c then c:DespawnOrUnsummon(0) end end
  local sc = obj(g, g.stormGuid); if sc then sc:DespawnOrUnsummon(0) end; g.stormGuid = nil
  g.bolts, g.hydras, g.bots, g.eggs = {}, {}, {}, {}
end
clearStageTwoFn = clearStageTwo
local function sweepLeftovers(g)                            -- v1.2 (as Bullet Romper v1.0.4): whatever a '.reload ale' or an abandoned game left in the tent
  local a = anchor(g)
  if not a then return end
  local n = 0
  local list = { E.WONKA, E.CONTROLLER, E.STORM, E.STORMZONE, E.HYDRA, E.PLANT, E.BOMBBOT, E.EGG, E.FOOD, E.OTTO, E.PORTAL }   -- Otto: the one in the tent (the Faire is another map); the portal: ours (the others' are over 500 yd away)
  for _, col in ipairs(COLORS) do list[#list + 1] = col.mount end
  for _, e in ipairs(list) do
    for _, c in ipairs(try(a, "GetCreaturesInRange", 260, e) or {}) do c:DespawnOrUnsummon(0); n = n + 1 end
  end
  if n > 0 then log("arrival: removed " .. n .. " creature(s) left over from an earlier game") end
end
local function setStage(g)                                  -- v1.2b: the glow on the platform and Otto in the tent; looked at again before every round (they live 30 minutes)
  local a = anchor(g)
  if not a then return end
  if not obj(g, g.zoneGuid) then                            -- glow on the centre platform = 'bring them here' (live 99734 'Wonka Game' controller)
    local z = a:SpawnCreature(E.CONTROLLER, WK.CENTER[1], WK.CENTER[2], WK.CENTER[3], 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if z then g.zoneGuid = z:GetGUID(); try(z, "AddAura", S.ZONE, z) end
  end
  if not obj(g, g.ottoGuid) then                            -- live 58:56-59:17: Otto Wonka on the platform, a few yards from its middle
    local o = a:SpawnCreature(E.OTTO, WK.CENTER[1], WK.CENTER[2], WK.CENTER[3] + 0.1, 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if o then g.ottoGuid = o:GetGUID(); try(o, "SetNPCFlags", 1) else log("could not put Otto Wonka in the tent") end   -- 1 = talk only: no quest mark, no shop in the tent
  end
  if not obj(g, g.portalGuid) then                          -- v1.2c: the way back (live 67:42: the 'Azzar Faire Portal' orb by the arrival spot)
    local px, py = WK.CENTER[1] + WK.PORTAL[1], WK.CENTER[2] + WK.PORTAL[2]
    local p = a:SpawnCreature(E.PORTAL, px, py, (tableZ(px, py) or 13.6) + 0.1, math.pi, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if p then g.portalGuid = p:GetGUID() elseif not g.noPortal then g.noPortal = true; log("no Azzar Faire Portal (creature " .. E.PORTAL .. " missing); #leave still takes you back") end
  end
  for wl, w in pairs(g.wonkas) do                           -- Wonkas whose 30 minutes ran out make room for new ones
    if not obj(g, w.guid) then g.wonkas[wl] = nil; g.wonkaCount = math.max(0, g.wonkaCount - 1) end
  end
end
local function bigCountdown(pl, ms)                         -- the client's own big numbers (found for the Rainbow Race, v2.1.4)
  if not (WK.BIG_COUNTDOWN and pl and type(CreatePacket) == "function") then return false end
  local ok, err = pcall(function() local pk = CreatePacket(OP_COUNTDOWN, 4); pk:WriteULong(ms); pl:SendPacket(pk) end)
  if not ok then log("could not send the countdown packet: " .. tostring(err)) end
  return ok
end

-- ---------- the game ----------
local PLACE = { "First", "Second", "Third", "Fourth", "Fifth" }
local function podiumSize(n)                                -- v1.2: live = 5 players and the first THREE 'win' (2nd got 'Wonka Wonka! Winner!' + 'Green Plumage', 3rd 'Wonka Dominator')
  if n < 2 then return 0 end                                -- alone = no win, as before (Rowan's call)
  return math.max(1, math.floor(n * 3 / 5))                 -- OURS for fewer than five: 2 or 3 players = 1 winner, 4 = 2, 5 = 3
end
local function party(g)                                     -- v1.2e: live 67:20-67:22: the three places (names only), confetti round every player
  local order = g.partyOrder or {}
  for i = 1, math.min(3, #order) do
    local m = g.members[order[i]]
    if m then tell(g, WT .. "|cff40ff40" .. PLACE[i] .. " place:|r " .. m.name) end
  end
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      local tg = mountOf(g, m) or pl                         -- v1.2f: they are on their mounts (a rider is not seen), so the confetti goes off there
      try(tg, "CastSpell", tg, S.CONFETTI, true); try(pl, "AddAura", S.APPLAUSE, pl)   -- 256066 Confetti, 256067 Emote: Applause
      playKit(g, tg, KIT_CONFETTI)
      later(m.guid, 1200, function(p) if g.state == "done" and inGame(g, p) then playKit(g, mountOf(g, m) or p, KIT_CONFETTI) end end)
    end
  end
end
local function endGame(g, t)
  g.state = "done"; g.doneAt = t
  clearStageTwo(g)
  local order = {}
  for low, m in pairs(g.members) do order[#order + 1] = low end
  table.sort(order, function(a, b) return g.members[a].score > g.members[b].score end)
  local wins = podiumSize(#order)
  hudTime(g, 0); hudScores(g)
  for i, low in ipairs(order) do
    local m = g.members[low]; local col = COLORS[m.slot]
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then
      for _, wl in ipairs(followers(g, low)) do release(g, wl) end
      local ang = (i - 1) * (2 * math.pi / WK.MAX_PLAYERS)
      local px, py = WK.CENTER[1] + 5 * math.cos(ang), WK.CENTER[2] + 5 * math.sin(ang)
      local mc = mountOf(g, m)
      if mc and not m.onFoot and dist2(pl:GetX(), pl:GetY(), WK.CENTER[1], WK.CENTER[2]) <= WK.PLATFORM_R then   -- v1.2f: on the platform already: stays where it is, mounted and held (live 67:15-67:25)
        hold(mc, true)
        for _, a in ipairs({ S.ONFIRE, S.ONFIRE2 }) do try(mc, "RemoveAura", a) end
        try(mc, "AddAura", S.APPLAUSE, mc)
      else                                                   -- not on the platform: brought onto it (Rowan; live 67:15) and seated again
        dropMount(g, low, pl)
        later(m.guid, 700, function(p)
          if p:GetMapId() ~= WK.MAP then return end
          p:Teleport(WK.MAP, px, py, WK.CENTER[3] + 0.5, ang + math.pi)
        end)
        later(m.guid, 1900, function(p)
          if g.state ~= "done" or not g.footAt or not g.members[low] or not inGame(g, p) or mountOf(g, m) then return end
          local c = spawnMount(g, low, p, px, py, WK.CENTER[3], ang + math.pi)
          if c then seat(g, low, p); try(c, "AddAura", S.APPLAUSE, c) end   -- seat() holds it: the round is over
        end)
      end
      try(pl, "AddItem", ITEM_TICKET, WK.TICKETS)
      giveAch(pl, ACH.FIRST_MATCH); credit(pl, E.CREDIT)     -- v1.2: every match counts (90211-14 run on this credit), with the quest or without
      if i <= wins and m.score > 0 then
        giveAch(pl, ACH.WINNER); giveAch(pl, col.ach); credit(pl, E.WIN)
        if m.score >= 50 then giveAch(pl, ACH.DOMINATOR) end
      end
      if not m.hydraHit then giveAch(pl, ACH.NO_HYDRA) end   -- v1.2: the three 'Avoided'
      if not m.struck then giveAch(pl, ACH.NO_BOLT) end
      if not m.bombed then giveAch(pl, ACH.NO_BOMB) end
      for _, a in ipairs({ S.AV_HYDRA, S.AV_BOLT, S.AV_BOMB }) do try(pl, "RemoveAura", a) end
    end
    log(string.format("%s place: %s (%s) %d", PLACE[i] or i, m.name, col.name, m.score))
  end
  g.partyAt, g.partyOrder = t + WK.PARTY_AFTER, order         -- v1.2e: the places and the confetti come 5 s on (live 67:20)
  g.footAt = t + WK.PARTY_TIME                               -- v1.2f: and everyone is on foot 10 s on (live 67:25)
  soundAll(g, SND_END)                                       -- v1.2e: live 67:15.6
end
local function tickGame(g, t)
  if g.musicAt and WK.MUSIC and t - g.musicAt >= WK.MUSIC_AGAIN then g.musicAt = g.musicAt + WK.MUSIC_AGAIN; musicAll(g, WK.MUSIC_ID) end   -- v1.2d: back to back, as on live (also after the end of the game)
  if g.partyAt and t >= g.partyAt then g.partyAt = nil; party(g) end   -- v1.2e
  if g.footAt and t >= g.footAt then                         -- v1.2f: the party is over: on foot (live 67:25)
    g.footAt = nil
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if m.mountGuid then dropMount(g, low, inGame(g, pl) and pl or nil) end
    end
  end
  if g.state == "arriving" then
    local allIn = true
    for low, _ in pairs(g.members) do if not inGame(g, getPlayer(g, low)) then allIn = false end end
    if (allIn and t >= g.arrivedAt + WK.ARRIVE_WAIT) or t >= g.arrivedAt + WK.ARRIVE_MAX then
      for low, m in pairs(g.members) do
        local pl = getPlayer(g, low)
        if not inGame(g, pl) then g.members[low] = nil; g.count = math.max(0, g.count - 1) end   -- v1.2: 'You have selected the X Wonka' comes at GO, as on live (59:17)
      end
      sweepLeftovers(g)                                      -- v1.2
      setStage(g)                                            -- v1.2b
      for _ = 1, WK.WONKAS do spawnWonka(g) end
      g.state = "ready"; g.readyAt = t; g.round = 1         -- v1.1: on foot until everyone says #ready
      tell(g, WT .. "Run up to Otto Wonka on the platform and tell him when you are ready. The Azzar Faire Portal behind you goes back to the Faire.")   -- OURS (live says nothing here)
    end
  elseif g.state == "ready" then
    local allReady, n = true, 0
    for low, m in pairs(g.members) do
      if inGame(g, getPlayer(g, low)) then n = n + 1; if not m.ready then allReady = false end
      else
        m.goneSince = m.goneSince or t
        if t > m.goneSince + 15000 then g.members[low] = nil; g.count = math.max(0, g.count - 1) end
      end
    end
    if n > 0 and allReady then
      g.bigOk = true
      for low, m in pairs(g.members) do
        local pl = getPlayer(g, low)
        if inGame(g, pl) then
          try(pl, "RemoveAura", S.READY)
          m.busyUntil = t + WK.COUNTDOWN * 1000 + 3000
          m.score = 0; m.struck, m.bombed, m.hydraHit, m.eaten, m.grenades, m.sprintUntil, m.shockUntil = nil, nil, nil, nil, nil, nil, nil
          local ang = (m.slot - 1) * (2 * math.pi / WK.MAX_PLAYERS)   -- v1.2: the mounts wait at the platform's edge, the players stand on foot (live 59:05-59:14)
          if not mountOf(g, m) then spawnMount(g, low, pl, WK.CENTER[1] + 8 * math.cos(ang), WK.CENTER[2] + 8 * math.sin(ang), WK.CENTER[3], ang + math.pi) end
          if not bigCountdown(pl, WK.COUNTDOWN * 1000) then g.bigOk = false end
        end
      end
      g.state = "countdown"; g.countAt = t; g.lastCount = nil
      tell(g, AZT .. "Round " .. g.round .. " is starting!", "Round " .. g.round .. " is starting!")
      if g.round == 1 then tell(g, WT .. "Throw bananas at the little Wonkas until they follow you, then lead them to the centre platform. Say #leave to go back to the Faire.") end
      hudTime(g, WK.GAME_TIME); hudScores(g)                -- v1.2: live 59:04, the HUD comes up with the countdown (8:00, all colours 0)
      g.musicAt = t; musicAll(g, WK.MUSIC_ID)                -- v1.2d: live 59:04.4, the music starts with the countdown
    elseif t > g.readyAt + (g.round > 1 and 120000 or WK.READY_MAX) then cleanup(g, g.round > 1 and "no new round" or "nobody readied up"); return
    end
  elseif g.state == "countdown" then
    local n = WK.COUNTDOWN - math.floor((t - g.countAt) / 1000)
    if n ~= g.lastCount then
      g.lastCount = n
      if n > 0 then
        if not g.bigOk and (n <= 5 or n == WK.COUNTDOWN) then tell(g, WT .. n .. "...", tostring(n)) end
      else
        g.state = "playing"; g.startedAt = t; g.endAt = t + WK.GAME_TIME * 1000; g.nextBoard = t + 60000; g.warned = nil; g.lastLeft = nil
        startStageTwo(g, t)
        for low, m in pairs(g.members) do                    -- v1.2: on the Wonka at GO (live 59:15-59:17)
          local pl = getPlayer(g, low)
          if inGame(g, pl) then
            m.busyUntil = t + 3000
            if not mountOf(g, m) then spawnMount(g, low, pl, pl:GetX(), pl:GetY(), pl:GetZ(), pl:GetO()) end
            if not seat(g, low, pl) then pl:SendBroadcastMessage(WT .. "Could not seat you on your Wonka: click it to get on.") end
            pl:SendBroadcastMessage("You have selected the " .. COLORS[m.slot].name .. " Wonka. It will be your mount during this event.")
            try(pl, "AddAura", COLORS[m.slot].aura, pl)
            for _, a in ipairs({ S.AV_HYDRA, S.AV_BOLT, S.AV_BOMB }) do try(pl, "AddAura", a, pl) end   -- live 59:16
          end
        end
        for _, m in pairs(g.members) do hold(mountOf(g, m), false) end
        log("round " .. g.round .. " started with " .. g.count .. " player(s), " .. g.wonkaCount .. " wonkas")
      end
    end
  elseif g.state == "playing" then
    local ok, err = pcall(tickFood, g, t)
    if not ok then log("banana error: " .. tostring(err)) end
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) then
        m.goneSince = nil
        local x, y = pl:GetX(), pl:GetY()
        for _, wl in ipairs(followers(g, low)) do           -- lost followers go free
          local c = obj(g, g.wonkas[wl].guid)
          if not c then removeWonka(g, wl) elseif dist2(c:GetX(), c:GetY(), x, y) > WK.LEASH then release(g, wl) end
        end
        if m.shockUntil and t >= m.shockUntil then          -- v1.1: a bolt / bomb / plant lets go
          m.shockUntil = nil
          for _, fire in ipairs({ S.ONFIRE, S.ONFIRE2 }) do try(mountOf(g, m), "RemoveAura", fire) end   -- v1.2e
          local c = mountOf(g, m); if c then try(c, "RemoveAura", S.SHOCK); hold(c, false) end
        end
        if not m.onFoot and dist2(x, y, WK.CENTER[1], WK.CENTER[2]) <= WK.CENTER_R then score(g, low, pl, t) end
        if t > (m.busyUntil or 0) then                       -- v1.2: also when the mount stands there without its rider
          local mc = mountOf(g, m)
          local mk = mc and mc:GetVehicleKit()
          if not mc then m.busyUntil = t + 3000; m.onFoot = nil; board(g, low, pl)
          elseif mk and not mk:GetPassenger(0) then          -- v1.2h: he got off: it waits for him where it stands (Rowan: 'When leaving my wonka, I am put back in it')
            if not m.onFoot then
              m.onFoot = true; hold(mc, true)
              pl:SendBroadcastMessage(WT .. "You are off your Wonka. Click it to ride again, or take the Azzar Faire Portal to leave the game.")
            end
          elseif m.onFoot then m.onFoot = nil; if not m.shockUntil then hold(mc, false) end   -- back on it
          end
        end
        if m.sprintUntil and t >= m.sprintUntil then m.sprintUntil = nil end
        local smc = mountOf(g, m)                             -- v1.2j: 'make sure they stick' (Rowan): the speed is looked at every tick and put right
        if smc then
          local sprinting = m.sprintUntil ~= nil or try(smc, "HasAura", S.SPRINT) == true   -- the bar's sprint is live's 257449: its aura on the mount
          if sprinting ~= (m.sprinting or false) then m.sprinting = sprinting or nil; pace(g, low) end
          local want, have = mountRate(m), try(smc, "GetSpeedRate", 1)
          if type(have) ~= "number" or math.abs(have - want) > 0.02 then try(smc, "SetSpeed", 1, want, true) end
        end
      else
        m.goneSince = m.goneSince or t
        if t > m.goneSince + 15000 then
          for _, wl in ipairs(followers(g, low)) do release(g, wl) end
          local c = mountOf(g, m); if c then c:DespawnOrUnsummon(0) end
          g.members[low] = nil; g.count = math.max(0, g.count - 1)
          log(m.name .. " left the game")
        end
      end
    end
    for _, h in ipairs({ { tickStorm, "storm" }, { tickHydras, "hydra" }, { tickPlants, "plant" }, { tickBots, "bomb-bot" }, { tickEggs, "egg" } }) do
      local ok2, err2 = pcall(h[1], g, t)
      if not ok2 then log(h[2] .. " error: " .. tostring(err2)) end
    end
    local missing = WK.WONKAS - g.wonkaCount                -- keep the tent stocked (a few per tick)
    for _ = 1, math.min(missing, 3) do spawnWonka(g) end
    if WK.CHAT_BOARD and t >= g.nextBoard and g.endAt - t > 20000 then g.nextBoard = t + 60000; scoreboard(g, (g.endAt - t) / 1000) end
    local left = math.max(0, math.ceil((g.endAt - t) / 1000))
    if left ~= g.lastLeft then                              -- v1.2: the live clock and the live [TIMER] lines (64:17, 65:17, 66:19, 67:05-67:14)
      local was = g.lastLeft; g.lastLeft = left
      hudTime(g, left)
      if left % 15 == 0 then hudScores(g) end               -- sent again now and then, in case a client dropped its world states
      if was then
        if left == WK.LOW_AT then soundAll(g, SND_LOW) end    -- v1.2e: live 63:45.2, the clock at 3:30 (Rowan: 'a sound like the one in the battle grounds ... when time is getting low')
        if left == 180 or left == 120 then tell(g, TT .. math.floor(left / 60) .. " minutes remaining!", math.floor(left / 60) .. " minutes remaining!")
        elseif left == 60 then tell(g, TT .. "1 minute remaining!", "1 minute remaining!")
        elseif left <= 9 then tell(g, TT .. left .. "s remaining!", left .. "s remaining!") end
      end
    end
    if t >= g.endAt then endGame(g, t) end
  elseif g.state == "done" and t > g.doneAt + WK.RESULT_TIME then   -- v1.2: live 67:31 'Round 1 is complete. Round 2 is now available!', then a new ready check
    local n = 0
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) then n = n + 1; m.ready = nil; try(pl, "RemoveAura", S.APPLAUSE); try(pl, "RemoveAura", COLORS[m.slot].aura)
      else g.members[low] = nil; g.count = math.max(0, g.count - 1) end
    end
    if n == 0 then cleanup(g, "finished"); return end
    local line = "Round " .. g.round .. " is complete. Round " .. (g.round + 1) .. " is now available!"
    tell(g, AZT .. line, line)
    tell(g, WT .. "Talk to Otto Wonka for another round, or take the Azzar Faire Portal down the road.")   -- OURS
    g.round = g.round + 1; g.state = "ready"; g.readyAt = t
    setStage(g)
  end
  local here = 0
  for low, _ in pairs(g.members) do here = here + 1 end
  if here == 0 and g.state ~= "arriving" then cleanup(g, "nobody left") end
end
local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)
    if t > g.created + 90000 then Pending[sLow] = nil; log("start cancelled (starter did not arrive within 90 s)")
    elseif st and st:GetMapId() == WK.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then st:SendBroadcastMessage(WT .. "A game is already running here.")
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
end, 500, 0)

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
    if count >= WK.MAX_PLAYERS or p:IsBot() then return end  -- v1.0: real players only
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), name = p:GetName(), slot = count, score = 0,
                     home = (p:GetMapId() ~= WK.MAP) and { p:GetMapId(), p:GetX(), p:GetY(), p:GetZ(), p:GetO() } or nil }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= WK.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  if count == 0 then return end
  if count == 1 then members[player:GetGUIDLow()].slot = math.random(#COLORS) end   -- alone: a random colour each game
  local g = { members = members, count = count, created = now(), state = "pending", wonkas = {}, wonkaCount = 0, foodSeen = {}, mountOwner = {} }
  Pending[player:GetGUIDLow()] = g
  local n = 0
  for low, m in pairs(members) do
    local p = GetPlayerByGUID(m.guid)
    if p then
      local ax, ay = WK.CENTER[1] + WK.ARRIVE[1], WK.CENTER[2] + WK.ARRIVE[2] + (n - (count - 1) / 2) * 2.5; n = n + 1   -- v1.2c: on the road, side by side
      p:SendBroadcastMessage(AZT .. "You have joined the Wonkas queue.")
      p:Teleport(WK.MAP, ax, ay, (tableZ(ax, ay) or 13.6) + 0.5, math.pi)   -- facing the platform (south)
    end
  end
  log(string.format("%s starts Wonka Wonka! with %d player(s)", player:GetName(), count))
end

local function markReady(g, low, player)                    -- v1.2b: the ready check: Otto's 'I'm ready!' in the tent (live 58:58), or #ready
  local m = g.members[low]
  if not (m and g.state == "ready" and not m.ready) then return false end
  m.ready = true
  try(player, "CastSpell", player, S.READY, true)
  if try(player, "HasAura", S.READY) ~= true then try(player, "AddAura", S.READY, player) end
  tell(g, WT .. player:GetName() .. " is ready.")
  local waiting = false
  for l2, m2 in pairs(g.members) do if not m2.ready and inGame(g, getPlayer(g, l2)) then waiting = true end end
  if waiting then tell(g, AZT .. "Every player must be ready before the round can start.", "Every player must be ready before the round can start.") end   -- live wording (Bullet Romper 53:30)
  return true
end
-- ---------- Otto ----------
local function ottoMenu(player, creature)
  player:GossipClearMenu()
  if creature:GetMapId() == WK.MAP then                     -- v1.2b: Otto on the platform in the tent (live 58:58: 'Let me know when you're ready to start!' / 'I'm ready!')
    local g = Games[player:GetInstanceId()]
    local m = g and g.members[player:GetGUIDLow()]
    if m and g.state == "ready" and not m.ready then player:GossipMenuAddItem(0, "I'm ready!", 0, 10) end
    player:GossipSendMenu(TEXT_TENT, creature)              -- v1.2k: live's own sentence (was his Faire greeting)
    return
  end
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Start Wonka Wonka! (with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about Wonka Wonka!?", 0, 2)
  player:GossipMenuAddItem(1, "I'd like to browse your goods.", 0, 3)
  player:GossipSendMenu(TEXT_GREET, creature)
end
RegisterCreatureGossipEvent(E.OTTO, 1, function(event, player, creature) ottoMenu(player, creature) end)
RegisterCreatureGossipEvent(E.OTTO, 2, function(event, player, creature, sender, intid)
  if intid == 10 then                                       -- v1.2b: 'I'm ready!'
    player:GossipComplete()
    local g = Games[player:GetInstanceId()]
    if g then markReady(g, player:GetGUIDLow(), player) end
    return
  end
  if creature:GetMapId() == WK.MAP then player:GossipComplete(); return end   -- nothing else is offered in the tent
  if intid == 1 then
    player:GossipComplete()
    if busy(player) then player:SendBroadcastMessage(WT .. "You are already in a game."); return end
    creature:SendUnitSay("In you go! Mind the little ones, they bite when they're hungry.", 0)
    startSession(player)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_MORE, creature)
  elseif intid == 3 then
    player:GossipComplete(); player:SendListInventory(creature)
  else
    ottoMenu(player, creature)
  end
end)

-- ---------- the mount's bar: banana (who threw) and Air Blast ----------
local function casterOf(a, b)
  local function has(o, k) local ok2, f = pcall(function() return o[k] end); return ok2 and type(f) == "function" end
  local caster = a
  if a and has(a, "GetCaster") and not has(a, "GetMapId") then caster = a:GetCaster() end
  if b and has(b, "GetCaster") and not (caster and has(caster, "GetMapId")) then caster = b:GetCaster() end
  return caster
end
local function memberOf(caster)
  if not caster or caster:GetMapId() ~= WK.MAP then return nil end
  local g = Games[caster:GetInstanceId()]
  if not g or g.state ~= "playing" then return nil end
  local low = caster:GetGUIDLow()
  if not g.members[low] then low = g.mountOwner[low] end
  if low and g.members[low] then return g, low end
  return nil
end
local function onBanana(caster)
  local g, low = memberOf(caster)
  if g then g.members[low].threwAt = now() end
end
local function onBlast(caster)
  local g, low = memberOf(caster)
  if not g then return end
  local me = getPlayer(g, low)
  if not me then return end
  for l2, m2 in pairs(g.members) do
    local p2 = getPlayer(g, l2)
    if l2 ~= low and inGame(g, p2) and not m2.onFoot and dist2(me:GetX(), me:GetY(), p2:GetX(), p2:GetY()) <= WK.BLAST_R then
      launch(g, mountOf(g, m2), me:GetX(), me:GetY(), WK.BLAST_BACK, WK.BLAST_UP)   -- v1.2i: 'Push your rivals' (the spell's own words; Rowan: 'not doing a knock back')
      local list = followers(g, l2)
      for _, wl in ipairs(list) do release(g, wl, true) end
      if #list > 0 then log(string.format("%s blasted %s: %d wonka%s ran off", g.members[low].name, m2.name, #list, #list == 1 and "" or "s")) end   -- v1.2: not a chat line on live
    end
  end
end
local function onBlastBots(caster)                          -- v1.1: Air Blast sends a Bomb-Bot away from you
  local g, low = memberOf(caster)
  local me = g and getPlayer(g, low)
  if not me then return end
  for _, b in ipairs(g.bots or {}) do
    local d = dist2(me:GetX(), me:GetY(), b.x, b.y)
    if d <= WK.BLAST_R then
      local c = obj(g, b.guid)
      b.pushedBy = low; b.pushedAt = now()
      if c then try(c, "MoveClear"); launch(g, c, me:GetX(), me:GetY(), WK.BLAST_BACK, WK.BLAST_UP) end   -- v1.2i: thrown back (was: walking away)
      b.tx, b.lx = nil, nil
    end
  end
end
local function onGrenade(caster, spell)                     -- live 256058: aimed on the ground (green circle, 62:14); 'Throw the grenade at a rival to push them back. It has the chance to make your opponent's wonkas follow you.'
  local g, low = memberOf(caster)
  local me = g and getPlayer(g, low)
  if not me then return end
  local m = g.members[low]
  if (m.grenades or 0) <= 0 then me:SendBroadcastMessage(WT .. "No hand grenade: ride over a Wonka Egg to get one."); return end
  m.grenades = m.grenades - 1
  credit(me, E.THROWN)                                      -- v1.2: 'Throw 100 Hand Grenades' (90232)
  local dx, dy
  if spell then local ok2, x, y = pcall(spell.GetTargetDest, spell); if ok2 and type(x) == "number" and type(y) == "number" then dx, dy = x, y end end
  local function land(p)                                    -- v1.2d: what it does where it comes down, after its flight
    me = p
    if not (g.members[low] and g.state == "playing") then return end
    local victims = {}
    if dx then                                                -- v1.2: every rival within reach of the spot it lands on (the landing spell 256059 reaches 15 yd)
      eachRider(g, function(l2, m2, p2, x, y) if l2 ~= low and dist2(dx, dy, x, y) <= WK.GRENADE_BLAST then victims[#victims + 1] = l2 end end)
    else                                                      -- no aim point from this ALE: the v1.1 rule, the nearest rival within reach of the thrower
      if not g.noAim then g.noAim = true; log("hand grenade: no aim point from the spell, using the nearest rival") end
      local best, bd
      eachRider(g, function(l2, m2, p2, x, y)
        if l2 ~= low then local d = dist2(me:GetX(), me:GetY(), x, y); if d <= WK.GRENADE_R and (not bd or d < bd) then best, bd = l2, d end end
      end)
      if best then victims[1] = best end
    end
    local mk = dx and helper(g, E.STORMZONE, dx, dy, groundZ(g, dx, dy) or me:GetZ(), 2500)   -- v1.2d: where it lands: the explosion, and what the blast throws from
    if mk then playKit(g, mk, KIT_BOOM) end
    if #victims == 0 then me:SendBroadcastMessage(WT .. "Nobody in reach of the blast. (" .. m.grenades .. " left)"); return end
    for _, best in ipairs(victims) do
      local stolen = 0
      for _, wl in ipairs(followers(g, best)) do
        if math.random(100) <= WK.GRENADE_STEAL then release(g, wl, false); follow(g, wl, low); stolen = stolen + 1 else release(g, wl, true) end
      end
      local vmc = mountOf(g, g.members[best])
      if vmc then playKit(g, vmc, KIT_BOOM) end
      if vmc and dx then launch(g, vmc, dx, dy) end          -- v1.2d: 'push them back' (the spell's own words); v1.2h: by a jump of the mount
      shock(g, best, now(), 1500, false, dx and WK.LIFT_MS or 0)
      local vm, vp = g.members[best], getPlayer(g, best)
      vm.bombed = (vm.bombed or 0) + 1; if vp then try(vp, "RemoveAura", S.AV_BOMB) end
      if stolen > 0 then credit(me, E.STOLEN, stolen) end     -- 'Steal N wonkas from other players' (90240-42)
      tell(g, WT .. m.name .. " delivered an explosive reminder to " .. vm.name .. ".", m.name .. " delivered an explosive reminder to " .. vm.name .. ".")   -- live 61:38, right after Walty's own throw; v1.2d: mid-screen as well (Rowan: 'a message overhead')
      log(string.format("hand grenade: %s hit %s, %d wonka(s) changed sides", m.name, vm.name, stolen))
    end
  end
  local fly = dx and math.floor(dist2(me:GetX(), me:GetY(), dx, dy) / 30 * 1000) or 0   -- 256058 flies at 30 yd a second
  if fly > 150 then later(m.guid, fly, land) else land(me) end
end
local function onBananaAt(caster, spell)                    -- v1.2: live's button 1 is thrown at a TARGETED Wonka (256044 'Unlimited Bananas' / 256026 'Banana'): one Wonka a banana
  local g, low = memberOf(caster)
  local me = g and getPlayer(g, low)
  if not me then return end
  local tg = (spell and try(spell, "GetTarget")) or try(me, "GetSelection")
  local wl = tg and tg:GetGUIDLow()
  local w = wl and g.wonkas[wl]
  if not w or w.owner then return end
  local c = obj(g, w.guid)
  if not c or dist2(c:GetX(), c:GetY(), me:GetX(), me:GetY()) > 25 then return end
  local f = helper(g, E.FOOD, c:GetX(), c:GetY(), c:GetZ(), 6000, S.FOODVIS)   -- a banana on the ground by it (255830), as in the footage (60:06)
  if f then g.foodSeen[f:GetGUIDLow()] = true end           -- not a thrown 255757 banana: the food tick must leave it alone
  w.trust[low] = (w.trust[low] or 0) + 1
  if w.trust[low] >= w.need then follow(g, wl, low) else try(c, "PerformEmote", 5) end
end
local function onSprint(caster)                             -- v1.2: live's sprint (256027: 12 s cooldown, 8 s) has no speed of its own
  local g, low = memberOf(caster)
  if not g then return end
  local m = g.members[low]
  m.sprintUntil = now() + WK.SPRINT_MS
  try(mountOf(g, m), "SetSpeed", 1, WK.SPRINT_SPEED, true)
  pace(g, low)                                              -- v1.2g
end
local function spellOf(a, b)                                -- the Spell object of a spell event, whichever argument carries it (as Duck Hunt's aim does)
  local function has(o, k) local ok2, f = pcall(function() return o[k] end); return ok2 and type(f) == "function" end
  if b and has(b, "GetTargetDest") then return b end
  if a and has(a, "GetTargetDest") then return a end
  return nil
end
local function onBlastBoth(caster) onBlast(caster); onBlastBots(caster) end   -- v1.2: one handler for the one spell
for _, h in ipairs({ { S.BANANA, onBanana, "banana" }, { S.BLAST, onBlastBoth, "air blast" }, { S.GRENADE, onGrenade, "hand grenade" },
                     { S.BANANA_T, onBananaAt, "banana at a target" }, { S.BANANA_PH, onBananaAt, "banana at a target" }, { S.SPRINT12, onSprint, "sprint" } }) do   -- v1.2: the last three = live's own bar spells, for a changed bar
  local ok, err = pcall(RegisterSpellEvent, h[1], 2, function(event, a, b)
    local ok3, err3 = pcall(h[2], casterOf(a, b), spellOf(a, b))
    if not ok3 then log(h[3] .. " error: " .. tostring(err3)) end
  end)
  if not ok then log("RegisterSpellEvent(" .. h[3] .. ") failed: " .. tostring(err)) end
end

-- ---------- chat commands ----------
local function nearArena(pl) return pl:GetMapId() == WK.MAP and dist2(pl:GetX(), pl:GetY(), WK.CENTER[1], WK.CENTER[2]) < 260 end
local function leaveGame(player)                            -- back to the Faire: the Azzar Faire Portal (v1.2c) or #leave
  local low = player:GetGUIDLow()
  local g = Games[player:GetInstanceId()]
  if g and g.members[low] then
    local others = 0
    for l2, _ in pairs(g.members) do if l2 ~= low and inGame(g, getPlayer(g, l2)) then others = others + 1 end end
    if others == 0 then cleanup(g, "the last player left")   -- v1.2: clear the tent while somebody is still in it (afterwards nothing in it can be reached)
    else
      sendHome(g, low)
      later(player:GetGUID(), 1500, function() if g.members[low] then g.members[low] = nil; g.count = math.max(0, g.count - 1) end end)
    end
  else
    local f = WK.FAIRE_SPOT; player:Teleport(f[1], f[2], f[3], f[4], f[5])
  end
end
local function ourPortal(creature) return creature:GetMapId() == WK.MAP and dist2(creature:GetX(), creature:GetY(), WK.CENTER[1], WK.CENTER[2]) < 260 end   -- Bullet Romper's and the race's portals (same creature) stand elsewhere on this map
RegisterCreatureGossipEvent(E.PORTAL, 1, function(event, player, creature)   -- v1.2c: live 67:42, the window of the 'Azzar Faire Portal'
  if not ourPortal(creature) then return end
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Exit!", 0, 20, false, "Are you sure you want to exit?")
  player:GossipSendMenu(TEXT_PORTAL, creature)             -- '<The portal connects to the Azzar Faire. If you leave, you will have to pay again to access the mini-game.>'
end)
RegisterCreatureGossipEvent(E.PORTAL, 2, function(event, player, creature, sender, intid)
  if not ourPortal(creature) then return end
  player:GossipComplete()
  if intid == 20 then leaveGame(player) end
end)
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#leave" then
    if not nearArena(player) then return end
    leaveGame(player)
    player:SendBroadcastMessage(WT .. "Back to the Faire you go!")
    return false
  end
  if msg == "#ready" then                                   -- v1.1
    local g = Games[player:GetInstanceId()]
    local low = player:GetGUIDLow()
    if not (nearArena(player) and g and g.members[low]) then return end
    markReady(g, low, player)
    return false
  end
  local cmd, arg = msg:match("^#ww%s+(%a+)%s*(%S*)$")
  if not cmd or (player:GetGMRank() or 0) < 1 then return end
  cmd = cmd:lower()
  if cmd == "start" then
    if busy(player) then player:SendBroadcastMessage(WT .. "You are already in a game.") else startSession(player) end
  elseif cmd == "time" and tonumber(arg) then
    local g = Games[player:GetInstanceId()]
    if g and g.state == "playing" then g.endAt = now() + tonumber(arg) * 1000; g.warned = nil; player:SendBroadcastMessage(WT .. "End of Game: " .. mmss(tonumber(arg)))
    else player:SendBroadcastMessage(WT .. "No game is running here.") end
  elseif cmd == "speed" and tonumber(arg) then               -- v1.2g: try another mount speed on the spot (1 = running on foot, 2 = twice that); the sprint stays 1.5 times it
    local rate = math.max(1, math.min(4, tonumber(arg)))
    WK.MOUNT_SPEED = rate
    local g = Games[player:GetInstanceId()]
    if g then for low, m in pairs(g.members) do try(mountOf(g, m), "SetSpeed", 1, mountRate(m), true); pace(g, low) end end
    player:SendBroadcastMessage(WT .. "Mount speed " .. rate .. " (sprint " .. WK.SPRINT_SPEED .. "), until the next .reload ale. Tell Claude the number that feels like live.")
    log("mount speed set to " .. rate .. " by " .. player:GetName())
  elseif (cmd == "bombspeed" or cmd == "hydraspeed" or cmd == "sprintspeed") and tonumber(arg) then   -- v1.2h: the same for the land bombs and the hydras (they pick it up within a second)
    local rate = math.max(0.3, math.min(4, tonumber(arg)))
    if cmd == "bombspeed" then WK.BOT_SPEED = rate elseif cmd == "hydraspeed" then WK.HYDRA_SPEED = rate else WK.SPRINT_SPEED = rate end
    player:SendBroadcastMessage(WT .. (cmd == "bombspeed" and "Land bomb" or cmd == "hydraspeed" and "Hydra" or "Sprint") .. " speed " .. rate .. ", until the next .reload ale. Tell Claude the number that feels like live.")
    log(cmd .. " set to " .. rate .. " by " .. player:GetName())
  elseif cmd == "storm" or cmd == "hydra" or cmd == "bot" then   -- v1.1: bring the next one on now
    local g = Games[player:GetInstanceId()]
    if g and g.state == "playing" then
      if cmd == "storm" then g.nextStorm = now() elseif cmd == "hydra" then g.nextHydra = now()
      else                                                  -- v1.2: one more Walking Land Bomb, 12 yd from you
        local bx, by = player:GetX() + 12, player:GetY()
        local bc = helper(g, E.BOMBBOT, bx, by, groundZ(g, bx, by) or player:GetZ(), LIFE, S.BOMBVIS)
        g.bots[#g.bots + 1] = { guid = bc and bc:GetGUID(), x = bx, y = by, born = now() }
      end
      player:SendBroadcastMessage(WT .. "Coming up: " .. cmd .. ".")
    else player:SendBroadcastMessage(WT .. "No game is running here.") end
  elseif cmd == "grenade" then
    local g = Games[player:GetInstanceId()]
    local m = g and g.members[player:GetGUIDLow()]
    if m then m.grenades = (m.grenades or 0) + 3; player:SendBroadcastMessage(WT .. "3 hand grenades (button 4).") end
  else
    player:SendBroadcastMessage(WT .. "GM: #ww start | #ww time <seconds left> | #ww speed <rate> | #ww sprintspeed <rate> | #ww bombspeed <rate> | #ww hydraspeed <rate> | #ww storm | #ww hydra | #ww bot | #ww grenade     Everyone: #ready, #leave")
  end
  return false
end)

log("script loaded v1.2k like live, music, horn at 3:30, roaming bombs + blast + fire, bolts + thunder, road hydras, confetti: HUD, mount at GO, storm + hydras once, land bombs, [TIMER], podium, rounds (Otto " .. E.OTTO .. ", map " .. WK.MAP .. ", " .. WK.WONKAS .. " wonkas, " .. mmss(WK.GAME_TIME) .. " game)")
