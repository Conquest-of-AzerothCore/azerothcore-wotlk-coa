-- azzar-bullet-romper.lua  v1.54  (Rowan/Claude 2026-11-17)
-- v1.54 (Rowan 03:11, a new game on v1.52: 'There is definitly something going on. The new game he came out of the portal almost perfectly but
--   did a quick step and the slide was perfect'): what is going on = the server's timers (see v1.53). The entrance's touch-down was the last
--   hand-off still done by the clock; it now waits until the server sees the Reaver at its landing spot (see the watch in the lobby tick).
--   Includes v1.53 (never loaded by itself). Nothing else changed. NOT SEEN IN GAME.
-- v1.53 (Rowan 03:03-03:04 on v1.52: round 1 'almost perfect. He did a about face for a sec before sliding almost to the center and then did
--   a two step and stomped'; round 2, same session: 'he worked as we planned'): the same code gave both = TIMING. This server's script timers
--   fire late by a varying 0-0.6 s (touch-down asked at 2250 ms: logged 2258 in round 1, 2869 in round 2; 2116-3170 tonight). In round 1
--   the run started late (he stood in the turned slide pose for about a second) and the pose was taken off by the clock before he arrived
--   (the last steps walked). Now: the wait before the run is 0.25 s (was 0.6), and the pose comes off when he is AT his spot, not at 2.3 s.
--   Nothing else changed. NOT SEEN IN GAME.
-- v1.52 (Rowan 02:59 on v1.51, after trying the four: '#br slide lead which can be followed by the stomp. I take it you will make him slide
--   farther than 12 yards'): 'lead' is the game's slide: the slide pose goes on, 0.6 s later the Reaver moves, all the way to its spot in the
--   middle as before (the 12 yd was only the test command), arriving when it always did (2.2 s after 'Round N is starting!'). The pose comes
--   off as it arrives so that the stomp 1.1 s later can show its own animation. Nothing else changed. NOT SEEN IN THE REAL INTRO YET.
-- v1.51 (Rowan 02:49 on v1.50: 'no dice. Still does the same thing as last time. At least the music works now'): two guesses at the slide
--   failed, so no third: the game's slide is back to v1.47's (walks ~0.5 s, then slides: the least walking of what has been seen), and four
--   untried ways can be looked at in the lobby with '#br slide leadjump | jumpa | lead | late' (see slideBoss). The one he picks becomes the
--   game's. Nothing else changed.
-- v1.50 (Rowan 02:47 on v1.49: 'the reaver slide for a bit, then started walking at the end so a flip flop of what was going on previously.
--   He did slam his foot down when he got to the center which didnt happen before'): the pose packet lasts one pass of the animation (0.83 s)
--   and v1.49 sent it only in the first 0.3 s. Now every 0.6 s for the whole slide, until the stomp. Nothing else changed. NOT SEEN IN GAME.
-- v1.49 (Rowan 02:40: 'i forgot about the few steps and slide. That needs to be fixed' / 'after that, as long as nothing else breaks, that is
--   it'): ONE thing, the start of the slide: the pose is also sent as a visual-kit packet at the move's start (+150, +300 ms) so the Reaver
--   does not walk the first half second (see slideBoss). Music and everything else exactly as v1.47 (which Rowan heard working after a fresh
--   login: intro, fight track through the fight, ending with the round). The GM tests '#br snd sound' / 'obj' are removed (they left music
--   playing until log-off). There is no installed v1.48 (tried and withdrawn: azzar-bullet-romper.lua.v1.48-NOT-INSTALLED). NOT SEEN IN GAME.
-- v1.47 (Rowan 02:07 on v1.46: 'it did it again. the fight music played for like 5 seconds and dropped out', clip drop-in\audio_loss.mp4, the
--   first of his clips WITH game sound): the game plays exactly as v1.46; only the GM test grew ('#br snd obj'). MEASURED on his clip: intro
--   from 9.4 s to 54.9 s = it played straight THROUGH the music stop sent at 'Round 1 is starting!' (~44.7 s): PlayMusic(0) does nothing here;
--   fight track from 55.0 s, loudest 57-58.5 s, FADED out 59.0-60.7 s (a fade, not a cut), nothing after it. Zone label 'Bullet Romper' all
--   the time. The fight track carries the LOOP flag (0x200: 89 % of the client's sounds named 'loop' have it, 4.5 % of the rest), the intro
--   does not. So on this client the music channel fades a loop-flagged track after ~4 s; the Rainbow Race is spared because its own area's
--   zone music IS its theme (ZoneMusic 2509). No DBC table points at either Bullet Romper track (all 369 scanned). NOT SOLVED: see the todo.
-- v1.46 MUSIC, the Rainbow Race way (Rowan 02:01: 'now the rainbow race doesnt do that because another version of you fixed it' = its theme,
--   the same kind of track as our fight track, plays and stops properly on the music channel): v1.44's plain-sound way is OUT. Measured on the
--   live video in 2 s steps: the intro is strong to 53:35, fades from 53:36 and is gone by 53:40 ('Round 1 is starting!' is 53:36.8); nothing
--   until the fight track at 53:45.2. So: music stop at 'Round N is starting!', fight track at 'Fight!' (PlayMusic), stop at the end of the
--   round and when a player is sent back. CLAUDE'S READING of v1.43's early stop: the fight track was started while the intro still played.
-- v1.45 (Rowan 02:00: 'how can we get that to work as intended?'): the game itself is as v1.44. Added a GM test, '#br snd sound | music |
--   intro | stop', to try by ear (or on a recording WITH game sound: Rowan's clips so far have a silent sound track) which way of sending the
--   fight track plays through, whether it loops, and whether 'stop' ends it.
-- v1.44 (Rowan 01:56 on v1.43: 'The music that plays when i come in and before I start the match plays. The fight music start when i start
--   the fight but shut off shortly after'): the fight track only: sent with PlayDirectSound (a plain sound, played to its end) after a
--   PlayMusic(0) that ends the intro, at 'Fight!' and again 252 s later. The intro stays on PlayMusic (it works). Cost: a plain sound cannot be
--   stopped, so leaving mid-fight may leave up to 2 minutes of it playing. CLAUDE'S GUESS at the cause, not shown: the game drops a looping-
--   flagged track (0x200: the fight track, the race theme) from the music channel but lets a plain one (the intro) finish. NOT HEARD IN GAME.
-- v1.43 MUSIC (Rowan 01:44: 'spell sounds etc work just no music' / 'I wish you could hear music in the video clips'): the sound of the live
--   video (drop-in\...NEW-ZONE-AZZAR-FAIR... 53:05-58:40) was matched against the client's own music files (fingerprints of spectrum peaks;
--   check: 48:00-52:50 at the Faire matches Azzar_Music_04, the Faire's zone music). The client HAS two Bullet Romper tracks (patch-O,
--   sound\eventsounds\azzarfaire; no ZoneMusic row uses them, so live's server sends them):
--     214917 mini_game_bullet_romper_music_intro (an 83 s loop x 4): heard from 53:18.2 = as the fel portal opens, until the fight.
--     214913 mini_game_bullet_romper_music (128.3 s): starts 53:45.2 = the moment the pilots are seated; ends 55:53.5; NOT looped; starts
--     again at 57:57.2 (252 s after the first start; nothing else happens then; the Reaver dies 58:28).
--   Ours: intro when the fel portal opens (every lobby), fight track at 'Fight!' and again every 252 s, stopped (music 0) when a player is
--   sent back. Sent with Player:PlayMusic like the Rainbow Race theme. Bots get none. BR.MUSIC = false turns it off. NOT HEARD IN GAME.
-- v1.42 (Rowan 01:14 on v1.41: lightning 'I can see those now'. 01:15, after '#br floor': 'the green aoe fel stuff does not cover the entire
--   floor ... I can go all the way to the wall of the tent and it does not reach me'): TWO things.
--   (1) GREEN FLOOR: v1.40's one scaled-up zone did nothing he could see (taken out again). Now two more rings of the same fel zones at their
--       normal size, 30 at 66 yd and 38 at 84 yd from the middle, with the 20 that were there = out to the wall. The hit itself was already
--       everywhere on the floor (every mecha not more than 3 yd up).
--   (2) BOOST END: his v1.41 log has 'flight guard: 5.8 yd up with no boost running (fly aura false ...)' right after a boost = at boost end the
--       game was still not told that flying is over (adding the fly aura to a mecha that still carries it only refreshes it); the guard's own
--       fresh on-and-off did bring it down. Boost end now takes the aura OFF first, then on, then off (the guard too).
-- v1.41 (Rowan 01:10 on v1.40: 'the lightning is still the same. Maybe put it just past the portal? That is what it looks like to me that its
--   inside the fel portal'): he is right, measured in the client: 7fx_portalkeeper_felportal.m2 has its layers 0-1.0 model units in front of its
--   own spot (most at 0.6) = up to 13 yd in front at scale 13, and every lightning point stood 6 yd in front = inside it, behind its front
--   layers (which is also why v1.37 gave 'traces' and v1.39's stronger bolts changed nothing). Now BOLT_FRONT 16 yd in front for the beam ends,
--   the bolts, and a new unseen point the beams start from (they started at the portal itself). Bolts set to scale 0.45, every 0.6-1.6 s, a
--   pair 35 % of the time (v1.39's numbers were never seen). Nothing else changed. NOT SEEN IN GAME.
-- v1.40 (Rowan 01:02: 'make the ground aoe after destroying the pillars fill the entire floor. The whole point is to fly up to avoid it no
--   matter where you are'): the green floor's LOOK only. The hit already reached every mecha not in the air, wherever it stood; the picture was 20
--   fel zones in two rings that stop ~80 yd from the middle (wall ~92). Added: one fel zone in the middle at scale 3.6 = the whole floor.
--   Nothing else changed. NOT SEEN IN GAME. GM test without playing up to it: '#br floor' during a fight.
-- v1.39 (Rowan 00:58 on v1.38: 'Lightning I can see but it needs to be more pronounced'): the STRIKES only, numbers + twins: scale 0.4 -> 0.55,
--   two helpers a spot lit together (brighter, thicker), every 0.5-1.4 s (was 0.7-2.2), half the time a second bolt on the other side at the
--   same moment. The green beams are as they were. Which of the two he sees is NOT known (no clip): asked.
-- v1.38 (Rowan 00:40-00:47 on v1.37: 'The reaver came in fine now'; warframe 'comes in upright but not like it shows in live ... we can keep the
--   warframe as is'; 'Still not visible lightning. I can see traces of it but not the full effect'; 'the lightning would be great. We had it
--   before at the beginning. Just dont do anything that will break everything else'): ONE thing, the PORTAL LIGHTNING, nothing else touched.
--   (a) The green beams (the portal casting 40146 at 4 unseen points round the ring every 1.2-2.2 s) are back exactly as v1.21-v1.35 had them:
--       v1.36 had replaced them. (b) The strikes: v1.37 spawned a new creature per strike for 0.95 s, and a creature fades in over about its
--       first second = 'traces'. Now 4 unseen helpers stand at the sides of the ring from the moment the portal opens and a strike = one of
--       them wears the strike model (display 126744) for 1.1 s, scale 0.4 (was 0.25). NOT SEEN IN GAME. NOT changed: the slide (he saw 'a few
--       steps' before it once, 'could be just a fluke'), the warframe's way in, bots (4 bot guns ran at 00:44, 'need some work but that comes later').
-- v1.37 (Rowan 00:03-00:19 on v1.36, clip drop-in\bulletromper9test.mp4: 'Everything else is good' apart from these four):
--   (1) 'I have infinite boost capability which should not happen'. His run's log: three boosts in the first minute, then no boost at all for five
--       minutes and only 9 hits in a 6:00 fight = the mecha could fly with no boost running. CAUSE NOT FOUND. Guard: a mecha more than 5 yd up for
--       1.5 s with no boost running is put back on the floor, its fly state is switched on and off again (so the client is told it cannot fly) and
--       'flight guard: ...' is logged with what it was carrying.
--   (2) WARFRAME: 'going into the map in a nose dive and then goes upright as it lands. It is supposed to be hovering'. The flying state of v1.34
--       plays the model's forward-flight pose. Now a jump move from the same place behind the pilots: no pitch, the model's own Jump / Fall /
--       JumpEnd. First starts 1.2 s after 'starting' (on the floor ~3.3 s).
--   (3) REAVER: 'coming from behind the top of the fel portal instead of the roof of the tent': it started 56 yd up (over the top of the dark
--       middle, at the roof beams). Now 44 yd up and 12 yd behind the portal: it first shows inside the upper part of the ring.
--   (4) PORTAL LIGHTNING: 'still no lightning around the fel portal' (00:19; 'now it's fine' at 00:03 was the boost speed). v1.36's visual kit was
--       not drawn at the portal. Each strike is now a creature of its own wearing the strike model (display 126744), 48 yd tall, for one second.
--   Also: at the end of EVERY boost the fly aura is put on and taken off again (see (1)).
-- v1.36 PORTAL LIGHTNING (Rowan 23:50 on v1.34: 'The crackling lightning around the fel portal isn't visible. I can see something that looks like
--   that animation but it is not completely visible'): in his clip (drop-in\bulletromper8test.mp4, 3-14 s, every frame checked for bright bolts)
--   there is none. Live (53:21.1, 53:21.6, 53:23.2, 53:25.2) has big forked fel bolts at the sides of the ring. The portal model itself carries no
--   lightning (1 animation, no emitters), and 40146 is only a thin channel beam. The client has a fel lightning-strike model,
--   7FX_Argus_Felstorm_LightningStrike_State.m2 (texture lightning_large_02; SpellVisualKit 2601 plays it ~38 yd tall, with its sound): that kit is
--   now played on an unseen helper on the floor at one side of the ring every 0.7-2.2 s while the portal is open. MY CHOICE of effect: it is
--   the closest in the client to what live shows, not a spell found on live. Nothing else changed from v1.35.
-- v1.35 (Rowan 23:50 on v1.34: 'The warframes fly too slow now when using boost so it takes forever to navigate the map'): MY v1.34 MISTAKE. The
--   boost's flying speed was never set anywhere: it was whatever the fly-in left on the mecha (2.8 up to v1.31, 4.4 in v1.32-1.33), and v1.34's
--   new fly-in ended on 1.0. Now enter() sets it itself: MECH_FLY 4.4. Nothing else changed.
-- v1.34 (Rowan 23:33-23:38 on his v1.33 run, drop-in\bulletromper7test.mp4; 'The ground crack AOE is great'):
--   (1) WHERE THE REAVER LANDS: 'he lands too close to the fel portal'; his .gps at 0:58 of the clip: X 5549.931 Y -5068.1074 (map 960) =
--       47.1 yd from the middle on the portal's side. LOBBY_BOSS_R 68 -> 47.1. The glide is now 70 yd, so LAND_MS 2100 -> 2400 (same speed).
--   (2) RED FIRE: 'I try to snuff out the fire pillar by standing over it but it does nothing' (1:49): he was on his boost. Over it and no
--       more than 8 yd up now snuffs it, boost or not.
--   (3) FROZEN WARFRAME (2:31) after snuffing a fire: the script left 255617 'Anim: Soak' on the mecha (anims the model does not have). Gone.
--   (4) HEALING ORBS: one in a 1:19 fight. Every 10-14 s when hurt (was 25-33), every 7 s under 50 % (was 12), 3 at a time, 15 s each.
--   (5) WARFRAMES: 'come in like they are hovering into the field of battle. Not just drop down.' Flying state on, low and nearly level
--       from behind the pilots at 16 yd a second, then settle. First starts 0.9 s after 'starting' (on the floor ~3.4 s, live 3.3).
--   Seen working in the clip and NOT touched: the slam cracks, the smooth slide, the Fel Pillars' look (157-161 s), the entrance path.
-- v1.33 (Rowan 23:07-23:10 on his v1.32 run, drop-in\bulletromper6test.mp4; looks taken from the game's own Spell / SpellVisual / SpellVisualKit
--   / SpellVisualEffectName .dbc and the client's model list, not guessed):
--   (1) ENTRANCE: 'he is supposed to come from the top of the tent, behind the fel portal and glide diagonally down to the floor using his
--       rockets like a power landing'. v1.32 started it 68 yd up IN FRONT of the ring. Now 56 yd up and 10 yd BEHIND the portal, one straight
--       move through the ring to the floor in front of it in 2.1 s (live 53:23.8-53:25.8), set down exactly when the move ends.
--   (2) THE SLAM: 'there is no fel crack like he slammed into the floor. It is a fel aoe'. 255611 is a fel TARGET CIRCLE
--       (Target_Fel_State_CenterOnly_Projected). The kit's own slam is SpellVisualKit 162751 (no spell carries it): anim 463 on the Reaver +
--       GroundCrack_Fel_State.M2. It is now played on the Reaver at the landing, at the stomp after the slide and at the crash.
--   (3) THE SLIDE: 'right posture but jagged, like he is lagging' = the 44 small jumps of 'step'. New mode 'aura' (default): ONE smooth move
--       holding the pose with 255607 'Fel Reaver: Emote 51' (kit anim 51). If its legs move: GM '#br slide step' is the old way.
--   (4) WARFRAMES: 'does not follow the same intro as live'. Live they come in from behind the pilots, pass right overhead and land in front
--       (53:39.3-53:40.1, 53:41.5-53:42.6). Now from 14 yd behind the arrival line, 26 yd up, to the v1.32 landing spots.
--   (5) HEALING ORBS: 'golden orange globes' = 255614 'Visual: Holy Orb' (solar_forcesphere_orb.m2); v1.14 had swapped in 255616, the RED orb.
--   (6) 'Even in the air I am taking floor and orb aoe damage': hits went by the boost's 6 s clock; now a mecha more than 3 yd up is out of reach.
--   (7) FEL PILLARS 'do not show up but I can target them': the look (255610 + 255621) was put on before the body was swapped for the
--       invisible one; now the body first, the look half a second later.
-- v1.32 THE OPENING, measured: Rowan's v1.30 run (drop-in\bulletromper5test.mp4) against live at full frame rate, live times by the clock
--   in the frames (faire-cache\bullet-romper-clock-2026-11-16). Rowan 22:45: 'I want everything like live'. Three things, nothing else:
--   (1) ENTRANCE: ours took 0.9 s from first showing to the floor, live 1.9 s (53:23.9-53:25.8), and live first shows about 2.4 Reaver
--       heights up, ours about 1.1. Now it starts 68 yd up and is asked to take 2.35 s (the first ~0.45 s is not drawn by the client:
--       MY READING of the clip, so the log now says when it really arrived: 'entrance: at its spot N ms after the move began').
--   (2) SLIDE: live it grows 2.5x in the picture during the slide (53:37.1-53:39.1), ours 1.6x: it stopped 25 yd short of the middle.
--       Now it slides to the middle (Rowan 21:32: 'until he gets to the middle'), 3 yd on the far side so it still faces the pilots.
--   (3) MECHAS: live they drop out of the roof onto open floor in front of the pilots, the first at 53:39.3 (on the floor 53:40.1), the
--       others 53:41.5-53:42.6, and the pilots run to them. Ours came down beside the arrival spot, out of view. Now: straight down,
--       18 yd in front of the arrival line (every second one 6 yd further), 8 yd apart; first at 2.1 s, the rest from 4.4 s 0.25 s apart.
--       Seating is unchanged (7 s; a pilot who has not run to his mecha is brought to it).
-- v1.31 (Rowan 22:33, after his v1.30 run bulletromper5test.mp4: 'when I failed the fight and was taken out of the mech, it said round 2 and
--   the fel portal opened up on the other side of the tent by the portal for the azzar faire'): openLobby() put the fel portal and the
--   Reaver 'across from the first player'. In round 1 that player has just arrived at the edge, so it came out right; in a later round he
--   stands wherever the fight ended. Now the far side is always the wall across from the ARRIVAL SPOT. Nothing else changed from v1.30.
-- v1.26 (Rowan 21:51 'you have the entire fight at your fingertips so copy it exactly'): every timer checked against the live clock
--   (table: faire-cache\bullet-romper-v116\LIVE-TIMELINE.md; fight clock 0 = pilots seated, live 53:41.0). Four were off:
--   lift-off 74 s -> 68.5 s (54:49.4); the Fel Pillars appear 4 s AFTER lift-off (54:53.4), not with it; green floor to crash 4 s -> 7 s
--   after the last pillar (55:25.8 -> 55:33); the slide to the edge 2.5 s -> 1.8 s (56:32.5-56:34.3).
-- v1.25 (Rowan 21:45 on v1.24, with a live screenshot: 'look at the size of the portal of live'; 'you managed to fix ricky and screw up
--   the fel reaver's entrance'): the entrance is back on its v1.21 numbers (it starts 42 yd up; v1.23 had moved it with the portal).
--   PORTAL: measured against the wall banners either side of it, live's ring is as wide as ours at 14 and sits partly in the floor
--   (about 1.5x wider than the part you see is tall): scale 13, raised 16 yd. And so it can be set by eye in seconds instead of by my
--   guesses: GM '#br pscale <n>' and '#br lift <yd>' now redraw the portal on the spot (it stays 2 minutes) and keep the value.
-- v1.24 RIKKY (Rowan 21:43, with a live screenshot): 'when the player comes into the map Rikky is in the middle. He then comes towards the
--   players and stops right where this screenshot shows... but he doesn't come AT the players. His line of travel is towards the portal
--   that goes back to the Faire.' -> he starts in the middle and rides straight at the Azzar Faire Portal (the exit, where the players
--   come in), stopping 9 yd short of it, beside the players. The exit portal now stands right where the players arrive (live: they
--   appear inside it), and a lone player arrives on that line instead of 10 yd to the side.
-- v1.23 (Rowan 21:39 on v1.21: 'the portal is now too big', 'the energy bar isn't even full but I can shoot'): PORTAL scale 14 -> 9.5,
--   raised 36 yd so the ring stands on the floor (its model is centred on its middle; live it covers about half the screen width from
--   mid-floor, ours at 14 covered ~60 % from further away). ENERGY: the bar was never full because the script set the wrong maximum
--   (arguments the wrong way round, like SetPower before): the maximum is now read from the mecha, filled at the start, refilled 6 % a second.
-- v1.22 THE FIGHT (Rowan 21:37 'work on the rest of the fight, frame by frame'; his recordings bulletromper3 / bulletromper4test against
--   live 54:00-54:12, 55:49-55:51 at full size): (1) every orb, mark and helper carried a green name ('Bullet Romper Explosion Zone',
--   '...Fire Center'): all helpers are made unselectable when they spawn. (2) THE YELLOW FLOOD: our fel hit under a mecha painted half
--   the screen yellow for 4 s; live it is a spiky yellow starburst about two mechas wide for half a second (54:02.0-54:02.4), with no
--   mark on the floor before it. Now: the Reaver lobs a fel shot at the spot (the warning), then a small short burst. (3) The huge
--   red/white fire blast (255615 at Reaver size) is gone from the crash, the pillar deaths and the fel shots; the crash shows the fel
--   cracks. (4) BEAM RINGS: ours were 18 red fire columns flying outward (the same look as the red fire you snuff); live is a flat
--   yellow-green disc spreading from the beam's hit: now the wide yellow splash (255611) at the hit, ring reach 35 yd.
--   (5) Orbs are told to run, not walk (they looked slow near the Reaver).
-- v1.21 (Rowan 21:32 + his 13 live screenshots): PORTAL back to scale 14 ('the size from before is close to live') and LIFTED so the whole
--   ring stands on the floor (ours had its middle at floor level), with green lightning (40146 'Cosmetic - Legion Ring Green Lightning',
--   untested). RIKKY stays where live has him, on the line between the players and the portal: the ride up to the players is removed.
--   THE REAVER (his words): 'appears from behind the portal that has lightning, comes down on jet powered assist, and slams down on the
--   ground making a cracked fel aoe look. He then slides, and has the sliding animation until he gets to the middle and then another fel
--   aoe floor crack.' -> it shows high in the ring, comes down on its rockets, slams (fel cracks 255611); on 'Round N is starting!' it
--   slides holding the slide pose (anim 51) in small steps, no walk cycle, then the second crack.
--   ENERGY ('runs out way too fast'): the mecha's energy now refills (6 a second). FEL PILLARS ('look nothing like live'): ours wore the
--   PORTAL model (a small green ring); now the kit's own pillar visuals 255610 + 255621 on an invisible body, like the orbs.
--   RED FIRE ('I have to be able to snuff out the red fire AOE when I walk over it or else it explodes'): touching it snuffs it.
-- v1.20 (Rowan 21:16 'did you include the portal back to the faire?'): the 'Azzar Faire Portal' (creature 9997810, the orb from the
--   Rainbow Race SQL) stands where the players port in, through every lobby: click it, 'Exit!', back to the Faire. It goes when the
--   round starts and is back for the next lobby. Replaces the 3.5 s arrival bubble of v1.18 (same model).
-- v1.19 (Rowan 21:14, his words): (1) 'Rikky stays in the middle instead of moving towards where the players come into the map. He is
--   supposed to move up to the players.' -> Rikky rides the head from the middle up to the arrival spot. (2) 'The reaver is to glide onto
--   the map under rocket power from his feet, not walk down invisible stairs.' -> out of the portal and in the slide it HOVERS (hover
--   state + the kit's foot glow 255609, a little off the floor) and is set down at the end: mode 'hover'. (3) 'The golden mechs are
--   supposed to come where the players port into the map.' -> everyone ports in at ONE spot at the edge (live: one arrival bubble), and
--   the mechas come down there, side by side; a pilot who wandered off is brought back to his mecha when seated.
-- v1.18 OPENING, second pass (Rowan 21:08 'close but still missing a lot from live'; his v1.17b recording bulletromper4test.mp4 0:00-0:26
--   against live 53:10-53:41): (1) the portal was now about twice too big (wider than the screen, its middle at floor level): scale 14 -> 6.5
--   (it measures ~9 yd across per scale step in game, live is ~2.5 Reaver heights). (2) The Reaver STILL WALKED in the slide (legs striding
--   at 0:19.6-0:20.4 of the recording): new mode 'jump' = a flat MoveJump, which plays no walk cycle; 2.2 s like live (53:33-53:35.2).
--   (3) The portal showed a 'Bullet Romper Fire Center' tooltip under the mouse: helpers are made unselectable with SetUnitFlags.
--   (4) The purple 'Azzar Faire Portal' bubble players arrive in (live 53:10.8-53:13.5) is there for 3.5 s.
-- v1.17 THE OPENING (Rowan 20:50: 'focus on the opening sequence and compare it to what live has, frame by frame'). His recording of
--   v1.15 (bulletromper3.mp4, 0:02-0:26, read at 4-10 frames a second) against live 53:10-53:41 (bulletromper1, every frame):
--   (1) RIKKY is there the moment you load in (live 53:10.9), riding the Fel Reaver Head. Ours came 3 s late, and the head was a prop
--       labelled 'Bullet Romper Fire Center' with Rikky hidden inside it. Now Rikky is MOUNTED on the head (mount display on the NPC);
--       if this core refuses that, the prop is kept but without a name.
--   (2) Left-overs of an earlier game stood in the tent for 3 s after arrival: swept the moment the first player is in.
--   (3) TIMING like live: portal opens 5 s after arrival (53:15.8), the Reaver shows inside it 5 s later (53:20.9) and is on the floor
--       1.5 s after that (53:22.4), the portal closes 12.5 s after it opened (53:28.4).
--   (4) PORTAL SIZE: ours was about a third of the Reaver's height; live it is about 2.5 Reavers tall. Scale 2 -> 14.
--   (5) The Reaver comes out of the portal's dark middle down to the floor; the red fire blast at its landing is gone (live has none).
--   (6) 'Every player must be ready before the round can start.' no longer shows on arrival; it is the answer while someone is not ready.
--   (7) No big 8..1 numbers and no faction crest: live shows no countdown at all, only 'Azzar Event: Round 1 is starting!'.
--   (8) THE SLIDE: ours WALKED (legs striding). It now moves the way it comes down from the portal (gravity off), which showed no leg
--       movement in the recording: mode 'glide' (GM '#br slide glide|pose|step').
--   (9) The stomp: the huge red/white blast is gone; the yellow-green cracks stay, 2 s (live 53:36.2-53:37.9).
-- v1.16 (new chat 20:40; Rowan: 'fix what is already there'; his v1.15 run in the log: destroyed at 1:17, Fel Reaver at 83 %, 7 orb hits;
--   live frames 53:41-54:50 re-read at full size, sheets faire-cache\bullet-romper-v116):
--   (1) THE FIRST SECONDS were out of order: ours threw a full ring at 4 s. Live: nothing for ~3.5 s (53:41-53:44.3), then a tight
--       STREAM of orbs like a string of beads that sweeps round (one arm, a second joins), and the first full ring only at ~10.5 s
--       (53:51.2). Streams are now dense (an orb every 0.1 s per arm, slow turn) instead of three thin arms 12 degrees apart.
--   (2) ORBS HIT FAR TOO OFTEN: live one pilot took ONE orb hit in the first 65 s inside a much denser field, flying through gaps with
--       orbs brushing the mecha; ours counted a hit 2.2 yd from the pilot. Now 1.2 yd, checked along the orb's whole path each tick
--       (a fast orb can no longer skip past between ticks either).
--   (3) The 3-4 rings one after another just before it lifts off (live 54:45-54:49) are in.
--   (4) Left-over Fel Pillars are swept with the rest when a lobby opens.
-- v1.12 (Rowan 19:33: 'run through it again frame by frame'; all 1,951 frames read, notes faire-cache\bullet-romper-rowan2\FRAME-NOTES.md):
--   mechs drop from 2.2 s 0.7 s apart (slide at once), the Reaver stands still in the ground phases, spiral-arm orbs, no orbs while it rises
--   or for 6 s after the crash, a green ring flash when a pillar dies, beam + disc every ~2.5 s (5 pilots), level 77, corpse 3.5 s.
-- v1.11 (Rowan 19:31) FINAL PHASE: at EDGE health % the Reaver slides to the edge, RISES and HOVERS there (EDGE_UP), firing until it dies;
--   its corpse then comes down to the floor. No more pillar phases once it hovers.
-- v1.10 (Rowan 19:27) THE OPENING: you enter, the portal opens, the Reaver comes THROUGH it and LANDS on the floor in front of it and
--   STANDS there through the ready check. On the countdown, all at once ('getting prepared for the fight'): it power slides to the middle,
--   the mechas fly down beside their pilots, the pilots are put in; the fight starts when the countdown ends.
-- v1.9 (Rowan 19:22): out of the portal it POWER SLIDES (slideBoss), not walks.
-- v1.8 (Rowan 19:14-19:17, 'make it just like live'): the fel cannon beam + rolling ring starts ~25 s after the FIRST CRASH (live
--   55:58, Reaver still in the middle), not at half health; it carries on through the edge phase (<= 50 %, Reaver at the far edge).
-- v1.7 PHASES from Rowan's frames drop-in\bulletromper1+2 (1,975 frames of 'NEW ZONE AZZAR FAIR' 53:01-58:33, read at 3 a second):
--   P1 GROUND 53:41-54:50: orb rings from the Reaver (single, double, 3-4 concentric 54:41-54:49), fel bursts under mechas.
--   P2 AIR 54:51-55:30 (starts 74 s in): orbs clear, it rises, pillars, big yellow fel impacts, green beams; 55:30-55:33 WHOLE FLOOR
--      GREEN (mechas fly up), 55:33-55:35 it crashes down, 55:35.6 fel cracks. Floor = 255627 1,000,000 dmg: on the floor = destroyed.
--   P3 GROUND 55:36-56:40: orbs again, green/yellow sweeps.   P4 EDGE 56:40-58:27 (~half health): it stands at the FAR EDGE and
--      fires green bolts at the floor; each spot throws an expanding yellow-green ring (every ~4 s for 5, often two at once).
--   58:27 dies -> lobby with Rikky (58:29). Healing Light Orbs (achievement 'The Good Orb') added: +13 % each.
-- v1.6 (Rowan 13:47): the Reaver POWER SLIDES to the middle after 'Round N is starting!', it does not walk: slideBoss() holds the kit's
--   slide pose (anim 51, emote 617) while moving; GM '#br slide pose|step' switches how it moves and replays a slide.
-- v1.5 OPENING from Rowan's frame-by-frame screenshots (drop-in\Bullet_Romper 0001-0256, ~10 a second): the portal opens at the far wall,
--   lightning crackles, ~4.5 s later the Reaver walks out and WAITS right in front of it through the ready check; the portal closes ~14 s in.
--   'Round N is starting!' -> it walks quickly to BOSS_STAND_R (3 s) and STOMPS (green burst + yellow fel cracks 255611); the mechas drop
--   from above one after another (0.7 s apart); pilots seated at 7 s.
-- v1.4 (Rowan 12:45-12:49 + live 53:10-53:48 re-read at 2 frames a second): PHASES like live. INTRO: a fel portal (model 21.5 yd tall at
--   scale 1; scale 2 now, was 6 = ~130 yd) opens at the far side, the Fel Reaver walks out to a spot at the far half (BOSS_STAND_R) and
--   STAYS there while the mechs drop in; no more flight to the middle (that was mine, not live). AIR PHASE: it hovers, the Fel Pillars
--   (targetable, shoot them down) stand near the tent wall and THROW THE ORBS (Rowan: the pillars, not the reaver), and the demon rains
--   Fel Cannon shots (255612) down onto the floor: a fel mark, 1.5 s, burst. RANGE: shots are measured edge to edge, and the demon's model
--   row said combat reach 8 for a 23 yd giant; the SQL now gives it 45, so the basic shot (30 yd) reaches it from near the outer ring.
--   ORDER (Rowan 12:51): pillars destroyed -> the green fel floor forms at once -> boost up out of it -> the Reaver crashes down with fel
--   cracks (255607 'Emote 51' tried for the crash; candidate). Pillars still up after 60 s: the floor comes anyway, harder (MINE).
--   GM: #br portal <scale> (try the portal size), #br rain (one fel shot).
-- v1.3 (Rowan 12:14-12:20: 'not running as intended'; live video 'NEW ZONE AZZAR FAIR' 51:15-58:36 read at 2 frames a second, plus the
--   server log of his five v1.2 runs): (1) THE DEMON NEVER MOVED: its creature_template_movement row said Rooted 1 / Flight 0, so every
--   MoveTo did nothing (log: 'put in the middle (it was at 78.0 yd)' = still on its portal spot). Fixed in the SQL (Rooted 0, Flight 2).
--   (2) SOLO WAS FAR TOO HARD: all five solo runs ended at 0:48-0:57 with the demon at 88-100 %. On live one mecha out of five lived 2:17
--   (health tube read frame by frame 53:45-56:03: an orb takes ~10 %, a fel burst ~17-20 %, the same as ours). The difference: live splits
--   the AIMED attacks (fans, fel hit zones, shock rings) over 5 pilots; ours threw all of them at the one pilot. Aimed attacks now come
--   as often PER PILOT as on live (base interval x 5 / pilots); the rings and carpets that hit everyone stay as they are.
--   (3) VORTICES: each unsmothered one blasts every mecha for 25 %; solo you had to reach every one alone, and the marker was small:
--   solo they now come at the live load per pilot (every ~42 s instead of 25 s) and the lava marker is 3x bigger. The game-over log
--   line now lists what hurt each pilot. (4) Bot-gun or GM kill: the demon now really dies (a corpse, like live 58:28) instead of being left at 1 health.
-- v1.2 (Rowan 11:50: second live video 'NEW ZONE AZZAR FAIR' 53:15-58:36, a full winning fight; read in nz\sheets + nz\hd):
--   LOBBY: a big fel portal opens at the far side and the Fel Reaver steps out of it (53:21-53:30); 'Every player must be ready before
--   the round can start.' AIR PHASE (54:57-55:41): the Fel Reaver rises into the air, Fel Pillars appear (target frame 'Fel Pillar',
--   55:03), about 40 s later the whole floor goes green (55:37) and it lands with a fel burst. Pillars still standing make the floor
--   blast worse (MY rule; live does not show what they do). SHOCK RINGS from half health (56:42 onward: a beam hits the floor, a green
--   ring spreads from the spot): boost over them. Orb rings denser (3-4 rings of ~30-40 at 54:54). LIVE NUMBERS: Fel Reaver 550K for
--   5 players (58:25) -> 110000 per player; 500 tickets per win (58:33). GM: #br ring, #br fx <spell id> (look at an effect).
-- v1.1 (Rowan 11:43: 'I want it like live, from the opening sequence onward'; full-size read of the live frames, notes in
--   BULLET-ROMPER-SCAN-2026-11-16.md): FEL PILLARS (live target frame 'Fel Pillar' under a tall green light, 54:47): a pillar charges;
--   shoot it down in time or THE WHOLE FLOOR TURNS GREEN (then only a boost saves you). FEL HIT ZONES replace the puddles: a round
--   fel mark under a mecha that bursts after 3 s (54:52 -> 54:59). ORBS as dense as live: bigger rings more often, double rings,
--   carpets in every direction, aimed fans. ROUNDS like live: after a round you stand in the arena again, Rikky is back
--   ('Round 1 is complete. Round 2 is now available!'), talk to him to go again or to leave. No clock chatter (live shows none).
--   Needs the re-run SQL for the Fel Pillar (99520) and the demon's real size; without it pillars are skipped and the floor attack
--   comes on its timer.
-- v1.0.5 (Rowan's video bullet_test2.mp4 11:07 + log): (1) the fight log said 'demon at 100%' after 1:49 of shooting: either the
--   shots went into the left-over Fel Reaver (v1.0.4 removes left-overs) or the demon's health was put back up by the core when it
--   walked; the script now remembers the lowest health and puts it back if it ever rises (and logs it). (2) The demon's leap did not
--   work (log: 'its leap had not arrived'): it now FLIES in the way the mechas do (up and over in two legs). (3) The six fel cracks
--   at its landing painted the whole floor yellow: one mark now.
-- v1.0.4 (Rowan's screenshot 10:59: two Fel Reavers and a stray mecha in the lobby): a '.reload ale' forgets the running game, so its
--   demon / mechas / helpers stayed behind in the tent. Every new lobby now first removes any Bullet Romper creature left in the tent.
-- v1.0.3 (Rowan 10:52 + footage 53:14-53:25 frame by frame): THE START LIKE LIVE. In the lobby RIKKY sits in the middle on a Fel Reaver
--   Head (the mount model 137819; the 10:53 close-up shows a goblin on a round fel machine, not a portal as first read): TALK TO HIM
--   and pick 'I'm ready!' (#ready still works). The Fel Reaver waits at the far side of the tent, already full size (no more growing in front of
--   you). When everyone is ready: 'Round 1 is starting!', Rikky leaves, the MECHAS FLY IN and land beside their pilots, the FEL
--   REAVER LEAPS IN to the middle with fel cracks on the floor, then you are seated and the fight starts (8 s in all, as on live).
-- v1.0.2 (Rowan's video bullet_test1.mp4, 10:47): after a boost the mecha stayed up 'on an invisible platform' -> when the boost ends the
--   script puts the mecha back on the floor (teleports it down; if it is still up a second later: out, down, back in). The demon now
--   WALKS (footage: it is all over the arena): a new spot every 10-16 s, and its orbs start from where it stands.
-- v1.0.1 (Rowan's first test 10:24 + the second-by-second footage read 52:39-58:14): (1) the Fel Reaver was SMALL: its model is
--   23.6 yd tall at scale 1 and the SQL shows it at 0.35; in the footage a mecha is the size of one of its feet -> the script now
--   sets scale 1.0 ('#br scale' still tunes). (2) The mecha had NO ENERGY (log: SetPower arguments were the wrong way round), and both
--   shots cost energy. (3) The boost did not lift: the live spell is only a marker aura, so the script now also puts the stock
--   'Fly' aura 34873 on the mecha for the boost: press 3, then HOLD JUMP to climb (the live tip: 'press 3 plus jump'). (4) Start ring
--   28 yd (the basic shot reaches 30). (5) '#br info' and '#br shoot' write what the server sees to the log, for the 'not in range' report.
-- BULLET ROMPER mini-game for the Azzar Faire (map 960 'MiniGames'), host Rikky 371921 on Dawnrise (map 909).
-- From the footage ('All 7 Azzar Faire games' 52:00-58:35), Rikky's live rules text 1200146 and the live cache rows
--   (faire-cache\bullet-romper-1s\BULLET-ROMPER-SCAN-2026-11-16.md): everyone pilots a golden mecha (live 99509) against the FEL REAVER
--   (live 99508). Bar: 1 basic shot (Piercing Flash 255606), 2 super shot (Light Cannon 255613), 3 boost (Golden Flight 255618: a few
--   seconds in the air). The demon throws fel orbs (rings and fans: dodge them), leaves fel puddles, raises FIERY VORTICES that a mecha
--   must stand in to smother before they blow, and now and then turns the WHOLE FLOOR green: only a mecha in the air escapes that.
--   Win = the Fel Reaver is destroyed. Lose = every mecha destroyed, or the clock runs out.
-- ROWAN'S RULES FOR OUR SERVER (2026-11-16): live needs exactly 5 players; ours SCALES to who is there (1-5 real players: the demon's
--   health and the number of vortices follow the head count), and group BOTS come as EXTRA GUNS: each bot in your group near Rikky adds
--   an unmanned mecha that shoots the demon by itself (the demon ignores it). Real players + bot guns = 5 seats at most.
-- OURS, not live: every number below (health, damage, how often), the script-side boost (6 s safe from everything on the floor,
--   15 s recharge), the bot guns. NOT in v1.0: extreme mode (Wrathful Fel Reaver 99514 is in the SQL), pillars, fire lasers, achievements.
-- ARENA (client files): plain round tent at 960 5597.0 -5066.5, flat floor z 10.0, radius ~92 yd.
-- Commands (chat):  #ready, #leave.   GM only:  #br start | #br time <seconds left> | #br hp <percent> | #br kill | #br scale <x> | #br floor | #br vortex
-- Needs azzar-bullet-romper.sql.
local BR = {
  MAP = 960,
  CENTER = { 5597.0, -5066.5, 10.0 },
  FLOOR_R = 80,
  FAIRE_SPOT = { 909, -1595.4, -12047.4, 61.7, 6.07 },      -- in front of Rikky (spawn 13800585: -1592.5 -12048.0 61.61 o 2.926)
  MAX_SEATS = 5, JOIN_RANGE = 40, LIVE_PILOTS = 5,             -- v1.3: aimed-attack intervals below are for a full live team of 5
  LOBBY_BOSS_R = 47.1,                                      -- v1.5 (Rowan's frames 0061-0184): during the ready check it waits RIGHT IN FRONT of the portal
  PORTAL_R = 80, PORTAL_AFTER = 5000, BOSS_OUT_AFTER = 5000, PORTAL_TIME = 12500,   -- v1.17: live timing (arrive 53:10.6, portal 53:15.8, Reaver 53:20.9, closed 53:28.4)
   -- portal at the far wall; the Reaver comes out ~4.5 s after it opens; it closes ~14 s in
  BOSS_STAND_R = 3,                                         -- v1.5 (frames 0185-0216): after 'Round 1 is starting!' it walks quickly to here, then stomps
  SLIDE_MODE = "lead", SLIDE_KIT_EVERY = 600, SLIDE_LEAD = 250, SLIDE_LATE = 500,   -- v1.52: 'lead' = Rowan's pick (02:59)
   JUMP_UP = 1.5, HOVER_UP = 1.5,
  ARRIVE_R = 62, ARRIVE_GAP = 5, RIKKY_STOP = 24.7, RIKKY_SPEED = 1.6, RIKKY_RIDE = true,   -- v1.27 (Rowan's .gps screenshot 21:57): he stops at 5637.3 -5066.0 = 40.3 yd from the middle
   EXIT_BACK = 3,   -- v1.19: where everyone ports in (edge of the floor); Rikky rides up to it
   SLIDE_EMOTE = 617, SLIDE_STEP_MS = 50,   -- v1.6 (Rowan 13:47: it POWER SLIDES, it does not walk): see slideBoss
  LAND_FROM = 44, LAND_BACK = 12, LAND_MS = 2200, LAND_SPEED = 4.2,   -- v1.21: it shows high in the ring and comes down on its rockets (live 53:20.9-53:22.4)
  ENERGY_EVERY = 500, ENERGY_ADD = 3,   -- % of the maximum per step                        -- v1.21: mecha energy refills 6 a second (ours)
     -- v1.19: it glides out of the portal just above the floor         -- v1.10: it drops out of the portal (from 14 yd up) onto the floor in front of it
  BOSS_RUSH_MS = 2200, STOMP_AT = 3300, MECH_FIRST = 1200, MECH_REST = 3000, MECH_STEP = 250, SEAT_AT = 7000,   -- v1.12 (frame pass): slide at once; mechs drop from 2.2 s, 0.7 s apart; seated ~7 s
  MECH_AHEAD = 18, MECH_ROW = 6, MECH_GAP = 8, MECH_BEHIND = 14, MECH_DROP = 10, MECH_HOVER = 2.5, MECH_IN_SPEED = 16, MECH_JUMP_UP = 3, MECH_DROP_RATE = 4.4, AIR_SAFE = 3, AIR_GUARD = 5,   -- v1.32: the mechas come straight down from the roof onto open floor in front of the pilots (live 53:39.3-53:42.6)
  START_R = 28,                                             -- players arrive on a ring this far from the demon
  ARRIVE_WAIT = 1000, ARRIVE_MAX = 30000, READY_MAX = 300000, COUNTDOWN = 8, BIG_COUNTDOWN = true, SHOW_COUNT = true,   -- v1.17b (Rowan 20:59): the big countdown and the crest stay

  GAME_TIME = 360,                                          -- seconds; the live fight in the footage took about 4 minutes
  BOSS_HP = 110000, BOSS_HP_GUN = 25000,                     -- the demon's health: per real player + per bot gun (GUESS; '#br hp' to tune)
  MECH_SPEED = 1.5, MECH_FLY = 4.4,                          -- v1.35: the boost's flying speed, set on purpose (4.4 = 31 yd a second, what v1.32-1.33 had)
  WALK_EVERY = 0,      -- v1.12 (frame pass): live it STANDS STILL in the ground phases (was 10000)
  WALK_R = 30, WALK_SPEED = 1.6,        -- v1.0.2: the demon walks to a new spot (WALK_EVERY = 0: stands still)
  BOSS_SCALE = 1.0,                                         -- v1.0.1: felreaver2 is 23.6 yd tall at 1.0 (a mecha is 6.8); the SQL row says 0.35
  ORB_DMG = 10, ZONE_DMG = 20, VORTEX_DMG = 25, FLOOR_DMG = 40,    -- % of a mecha's health
  RING_FIRST = 10500, RING_EVERY = 5000, RING_ORBS = 28, RING_SPEED = 9,   -- v1.16: first ring at 10.5 s (live 53:51.2), was 4 s
  WAVE_BEFORE_AIR = 4500, WAVE_RINGS = 4, WAVE_STEP = 1000,   -- v1.16: 3-4 rings in a row just before it lifts off (live 54:45-54:49)
   RING_DOUBLE = 2,   -- one ring in three is a double ring
  CARPET_FIRST = 22000, CARPET_EVERY = 13000, CARPET_ORBS = 26, CARPET_SMIN = 6, CARPET_SMAX = 14,
  FAN_FIRST = 13000, FAN_EVERY = 5000, FAN_ORBS = 7, FAN_SPEED = 13, FAN_SPREAD = 0.5,
  SPIRAL_FIRST = 3500, SPIRAL_EVERY = 16000, SPIRAL_TIME = 5000, SPIRAL_STEP = 100, SPIRAL_ARMS = 2, SPIRAL_TURN = 0.09, SPIRAL_SPEED = 12, SPIRAL_ARM2_AFTER = 2000,   -- v1.16: a dense string of beads (live 53:44.3-53:49.5), first thing in the fight   -- v1.12: rotating spiral arms (live 53:44-53:49, 55:43)
  QUIET_AFTER_CRASH = 6000,   -- v1.12: no orbs for ~6 s after the crash (live 55:36-55:42)
  BOSS_LEVEL = 77,            -- v1.12: live target frame 'Fel Reaver Level 77'
  ORB_R = 1.2, ORB_RANGE = 75,                              -- v1.16: 2.2 -> 1.2 (live: orbs brush the mecha without a hit)
  ZONE_FIRST = 17000, ZONE_EVERY = 8000, ZONE_WARN = 1500, ZONE_R = 6, ZONE_SCALE = 0.4, ZONE_FLASH = 900,   -- v1.22: fel shot, then a small short starburst       -- fel hit zone: mark, 3 s, burst
  VORTEX_SCALE = 3,                                         -- v1.3: the lava marker 3x bigger (Rowan: the small flame was easy to miss)
  VORTEX_FIRST = 20000, VORTEX_EVERY = 25000, VORTEX_TIME = 12000, VORTEX_R = 6, VORTEX_UP = 8, VORTEX_SOAK = 200,   -- v1.21 (Rowan 21:32): walking over the red fire snuffs it (was: stand in it 3 s)
  PILLAR_BODY = 11686, PILLAR_SCALE = 2,                     -- v1.21: invisible body carrying the kit's pillar visuals

  PILLAR_FIRST = 68500, PILLAR_DELAY = 4000, PILLAR_EVERY = 100000, PILLAR_TIME = 60000, PILLAR_HP = 6000, PILLAR_MAX = 4, AIR_UP = 22,
  FLOOR_BASE = 20, FLOOR_PER_PILLAR = 20,                   -- floor blast: 20 % + 20 % per pillar still standing (cap FLOOR_DMG)
  FLOOR_KILL = true,                                        -- v1.7: 255627 'Pilar Death Explosion' = 1,000,000 damage, 80 yd: on the floor = destroyed
  BEAM_AFTER_CRASH = 25000,                                 -- v1.8 (live 55:33 crash -> 55:58 first beam): beams + rings start this long after the first crash
  EDGE_R = 62, EDGE_UP = 14,                                -- v1.11: at the edge it hovers this high until it dies                                              -- v1.7 (live 56:40-58:27): last phase from the far edge of the tent
  HOLY_EVERY = 10000, HOLY_LIFE = 15000, HOLY_HEAL = 13, HOLY_R = 3.5,   -- v1.34 (Rowan 23:33: one orb in a 1:19 fight, 'needs more orbs to spawn or I won't make it through the entire fight'): every 10-14 s when hurt (was 25-33), 15 s on the floor (was 12)
  HOLY_LOW = 50, HOLY_LOW_EVERY = 7000, HOLY_FULL = 85, HOLY_NEAR = { 12, 30 }, HOLY_MAX = 3,   -- v1.34: every 7 s under 50 % (was 12), up to 3 on the floor (was 2)   -- v1.15 balance (Rowan 20:23): see tickHoly   -- v1.7: healing Light Orbs (achievement 'The Good Orb'; live +13 % at 54:17, 55:21)
  SHOCK_AT = 20,  -- v1.11b: live damage meter 56:40 = ~448K of 550K dealt -> the edge/hover phase starts at ~20 %
  SHOCK_EVERY = 2500,  -- v1.12: live a beam + disc every ~2-3 s with 5 pilots (aimed(): solo ~12 s)
  SHOCK_WARN = 1200, SHOCK_SPEED = 14, SHOCK_R = 35, SHOCK_DMG = 15, SHOCK_DOTS = 18,
  PORTAL_DISPLAY = 136906, PORTAL_SCALE = 13, PORTAL_LIFT = 16, BOLT_SPELL = 40146, BEAM_MIN = 1200, BEAM_MAX = 2200, BOLT_MIN = 600, BOLT_MAX = 1600, BOLT_SCALE = 0.45, BOLT_TWIN = 2, BOLT_DOUBLE = 35, BOLT_FRONT = 16, BOLT_DISPLAY = 126744, BOLT_HIDE = 11686, BOLT_LIFE = 1100,   -- v1.21
  BUBBLE_DISPLAY = 137860, BUBBLE_SCALE = 2, BUBBLE_TIME = 3500,   -- v1.18: AzzarFaire_portal.m2, the bubble players arrive in (scale = guess)
     -- health per real player; not shot down in time = floor attack
  MUSIC = true, MUSIC_INTRO = 214917, MUSIC_FIGHT = 214913, MUSIC_AGAIN = 252000,   -- v1.43: the live music (see the top); the fight track is 128.3 s and live starts it again 252 s after the first start
  FLOOR_WARN = 7000, FLOOR_RINGS = { { 66, 30 }, { 84, 38 } },   -- v1.42: two more rings of fel zones (yd from the middle, how many) so the green reaches the tent wall (~92 yd)
  PILLAR_RMIN = 72, PILLAR_RMAX = 78,                       -- v1.4: live 55:00-55:35: the pillars stand near the tent wall
  PILLAR_RING_ORBS = 18,                                    -- v1.4 (Rowan 12:49): in the air phase the PILLARS throw the orbs, not the demon
  RAIN_EVERY = 1200, RAIN_WARN = 1500, RAIN_R = 5, RAIN_DMG = 10, RAIN_NEAR = 7,   -- v1.4 (Rowan 12:48): the hovering demon shoots fel down onto the floor (5 pilots; aimed())
  FLY_MS = 6000, FLY_CD = 15000,
  GUN_EVERY = 1500, GUN_DMG = 250, GUN_RING = 30,           -- a bot gun: one shot every 1.5 s for 250 (a player's basic shot shows 163-320 in the footage)
  TICKETS = 500,                                            -- per win (live value unknown; same as the other games)
}
local F_FLAGS, F_DISPLAY, F_MOUNT, F_BYTES1, UF_NOT_SELECTABLE, UF_MOUNT = 59, 67, 69, 74, 0x02000000, 0x08000000   -- 3.3.5 unit fields
local HEAD_DISPLAY, HEAD_SCALE = 137819, 1.4                  -- creature\felreaverhead\felreaverheadmount.m2 (2.6 yd tall at scale 1): Rikky's seat in the lobby
local E = { RIKKY = 371921, BOSS = 99508, MECH = 99509, GUN = 99518, ORB = 99519, SOAK = 99516, SOAKBOOM = 99517, ZONE = 99522, PILLAR = 99520, CREDIT = 372023, EXIT = 9997810 }
local S = { HOLYORB = 255614,   -- v1.14 (Rowan 20:21): the healing orbs are ORANGE fire orbs (kit 255616 'Visual: Fire orb'), not 255614
            FELCANNON = 255612, EMOTE51 = 255607, RIDE = 46598, STUN = 255620, READY = 257210, SHOT = 255606, SUPER = 255613, FLIGHT = 255618,
            FLYAURA = 34873, ORBVIS = 255608, HITZONE = 255611, FIREZONE = 255619, SOAKANIM = 255617, SOAKBOOM = 255615, HOVER = 255609, PILLAR = 255610, PILLAR2 = 255621 }
local OP_COUNTDOWN = 0x588
local KIT_SLIDE = 162752                                    -- v1.49: the slide pose's own kit (state kit of 255607: animation 51 + the fel glow at its right hand)
local OP_PLAY_VISUAL, KIT_SLAM, KIT_BOLT = 0x1F3, 162751, 2601   -- KIT_BOLT (v1.36): SpellVisualKit 2601 = 7FX_Argus_Felstorm_LightningStrike_State.m2 at its base (a fel lightning strike, ~38 yd tall) + its sound
--             -- v1.33: SMSG_PLAY_SPELL_VISUAL; SpellVisualKit 162751 = anim 463 on the Reaver + spells\GroundCrack_Fel_State.M2 (scale 2)
local Q_BASE, Q_DAILY = 1650227, 1650266
local TEXT_GREET, TEXT_MORE, TEXT_EXIT = 1200145, 1200146, 1200245
local ITEM_TICKET = 558530
local TEMPSUMMON_TIMED_DESPAWN = 3
local LIFE = 30 * 60000

local Games = {}
local Pending = {}
local BT = "|cff7fff00[BULLET ROMPER]|r "
local AZT = "|cffff8000Azzar Event:|r "

local function log(msg) print("[BulletRomper] " .. msg) end
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
local function inGame(g, pl) return pl and pl:GetMapId() == BR.MAP and pl:GetInstanceId() == g.inst end
local function mapOf(g)                                     -- never keep a Map handle between ticks: fetch it fresh from a member
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
local function music(pl, id)                                -- v1.43: music goes out the way the Rainbow Race sends its theme (Player:PlayMusic = it can be stopped with id 0)
  if not pl or try(pl, "IsBot") == true or not (BR.MUSIC or id == 0) then return end
  if type(pl.PlayMusic) == "function" then local ok = pcall(pl.PlayMusic, pl, id, pl); if ok then return end end
  if id ~= 0 then try(pl, "PlayDirectSound", id, pl) end
end
local function musicAll(g, id) for low in pairs(g.members) do local pl = getPlayer(g, low); if inGame(g, pl) then music(pl, id) end end end
local function fightMusic(g) musicAll(g, BR.MUSIC_FIGHT) end   -- v1.46: on the music channel again (v1.44's plain sound could not be stopped), the way the Rainbow Race theme goes out and
                                                            --   works (Rowan 02:01). v1.43's early stop = most likely the intro still playing when the fight track came in: live
                                                            --   ends the intro 8 s earlier, at 'Round N is starting!' (see the top), and so do we now.
local function obj(g, guid) local mp = mapOf(g); return guid and mp and mp:GetWorldObject(guid) end
local function mechOf(g, m) return obj(g, m.mechGuid) end
local function playKit(g, unit, kit)                        -- v1.33: the game's own one-shot visuals (kits no spell carries) are played on the unit
  if not (unit and type(CreatePacket) == "function") then return false end
  local ok, err = pcall(function()
    for low, _ in pairs(g.members) do
      local pl = getPlayer(g, low)
      if pl then local pk = CreatePacket(OP_PLAY_VISUAL, 12); pk:WriteGUID(unit:GetGUID()); pk:WriteULong(kit); pl:SendPacket(pk) end
    end
  end)
  if not ok and not g.kitFail then g.kitFail = true; log("could not send the visual-kit packet: " .. tostring(err)) end
  return ok
end
local unselFn                                               -- v1.22: set to unsel() below
local function helper(g, entry, x, y, z, life, aura)
  local a = anchor(g)
  if not a then return nil end
  local c = a:SpawnCreature(entry, x, y, z, 0, TEMPSUMMON_TIMED_DESPAWN, life)
  if c then if unselFn then unselFn(c) end; try(c, "SetWalk", false) end   -- v1.22: no name, no tooltip; runs
  if c and aura then try(c, "AddAura", aura, c) end
  return c
end
local function unsel(c)                                     -- v1.18: no name, no tooltip, cannot be clicked
  if not c then return end
  local f = try(c, "GetUnitFlags")
  if type(f) == "number" then try(c, "SetUnitFlags", f - (f % (2 * UF_NOT_SELECTABLE)) + (f % UF_NOT_SELECTABLE) + UF_NOT_SELECTABLE) else try(c, "SetFlag", F_FLAGS, UF_NOT_SELECTABLE) end
end
local function arriveSpot(slot, back, n)                    -- v1.19: one arrival spot at the edge; n players stand side by side, centred (v1.24)
  local cx, cy = BR.CENTER[1], BR.CENTER[2]
  local off = (slot - ((n or 1) + 1) / 2) * BR.ARRIVE_GAP
  return cx + BR.ARRIVE_R + (back or 0), cy + off
end
local function rockets(c, on)                               -- v1.19 (Rowan 21:14): it glides 'under rocket power from his feet': hover state + foot glow
  if not c then return end
  if on then
    try(c, "SetRooted", false); try(c, "SetDisableGravity", true); try(c, "SetHover", true)
    try(c, "SetByteValue", F_BYTES1, 3, 3)                   -- anim tier: always stand + hover (no walk cycle)
    try(c, "AddAura", S.HOVER, c); try(c, "SetWalk", false)
  else
    try(c, "RemoveAura", S.HOVER); try(c, "SetByteValue", F_BYTES1, 3, 0); try(c, "SetHover", false); try(c, "SetDisableGravity", false)
  end
end
unselFn = unsel
local slideBoss                                             -- v1.7: defined further down (the edge phase calls it earlier in the file)
local function aimed(g, ms) return math.floor(ms * BR.LIVE_PILOTS / math.max(1, math.min(BR.LIVE_PILOTS, g.count or 1))) end   -- v1.3
local function randSpot(rmin, rmax)
  local ang, r = math.random() * 2 * math.pi, rmin + math.random() * (rmax - rmin)
  return BR.CENTER[1] + r * math.cos(ang), BR.CENTER[2] + r * math.sin(ang)
end

-- ---------- the mecha (vehicle) ----------
local function hold(c, on)
  if not c then return end
  if on then try(c, "AddAura", S.STUN, c); try(c, "SetRooted", true)
  else try(c, "RemoveAura", S.STUN); try(c, "SetRooted", false) end
end
local function dropMech(g, low, pl, boom)
  local m = g.members[low]
  local c = mechOf(g, m)
  if c then
    local kit = c:GetVehicleKit()
    if kit and pl then try(kit, "RemovePassenger", pl) end
    g.mechOwner[c:GetGUIDLow()] = nil
    c:DespawnOrUnsummon(boom and 1500 or 300)
  end
  m.mechGuid = nil
end
local function enter(g, low, pl, c)                          -- the pilot climbs into mecha c
  local m = g.members[low]
  try(c, "SetDisableGravity", false); try(c, "RemoveAura", S.FLYAURA)   -- v1.34: the fly-in state never stays on
  try(c, "SetSpeed", 1, BR.MECH_SPEED, true); try(c, "SetSpeed", 6, BR.MECH_FLY, true)   -- v1.35 (Rowan 23:50: 'the warframes fly too slow now when using boost'): v1.34's fly-in left the flying speed at 1.0; it had only ever been whatever the fly-in happened to leave
  try(c, "SetPowerType", 3)                                  -- v1.23: fill to the mecha's own maximum (this ALE wants (amount, type))
  local mx = try(c, "GetMaxPower", 3)
  if type(mx) ~= "number" or mx <= 0 then try(c, "SetMaxPower", 100, 3); mx = try(c, "GetMaxPower", 3) end
  if type(mx) ~= "number" or mx <= 0 then mx = 100 end
  try(c, "SetPower", mx, 3)
  if not g.powerLogged then g.powerLogged = true; log(string.format("mecha energy: %s of %s (type %s)", tostring(try(c, "GetPower", 3)), tostring(mx), tostring(try(c, "GetPowerType")))) end
  local kit = c:GetVehicleKit()
  if not kit then log("the mecha has no vehicle kit (VehicleId missing in creature_template " .. E.MECH .. "?)"); return false end
  pl:CastSpell(c, S.RIDE, true)
  if not kit:GetPassenger(0) then try(kit, "AddPassenger", pl, 0) end
  if g.state ~= "playing" then hold(c, true) end
  if (m.hp or 100) < 100 then local mx = try(c, "GetMaxHealth") or 100; try(c, "SetHealth", math.max(1, math.floor(mx * m.hp / 100))) end
  local pas = kit:GetPassenger(0)
  return pas and pas:GetGUIDLow() == low
end
local function board(g, low, pl)                            -- a fresh mecha right where the pilot stands (re-seats during the fight)
  local m = g.members[low]
  local c = pl:SpawnCreature(E.MECH, pl:GetX(), pl:GetY(), BR.CENTER[3] + 0.2, pl:GetO(), TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if not c then log("could not spawn a mecha (template " .. E.MECH .. " missing? run the SQL)"); return false end
  m.mechGuid = c:GetGUID(); g.mechOwner[c:GetGUIDLow()] = low
  return enter(g, low, pl, c)
end
local function flyInMech(g, low, pl)                        -- v1.19: the mecha comes down where the players ported in (Rowan 21:14)
  local m = g.members[low]
  local cz = BR.CENTER[3]
  local n, slot = math.max(1, g.count or 1), m.slot or 1     -- v1.32 (Rowan 22:45 'I want everything like live'): live they drop out of the roof one after
  local ax = arriveSpot(1, 0, 1)                             --   another onto open floor IN FRONT of the pilots, between them and the Reaver, in plain view
  local lx = ax - BR.MECH_AHEAD - ((slot % 2 == 0) and BR.MECH_ROW or 0)   --   (53:39.3 first at the top of the picture, on the floor 53:40.1; the rest 53:41.5-53:42.6);
  local ly = BR.CENTER[2] + (slot - (n + 1) / 2) * BR.MECH_GAP             --   the pilots run to them. v1.19-1.30 landed them beside the arrival spot, out of view.
  local c = pl:SpawnCreature(E.MECH, ax + BR.MECH_BEHIND, ly, cz + BR.MECH_DROP, math.pi, TEMPSUMMON_TIMED_DESPAWN, LIFE)   -- v1.33: live they come in from BEHIND the pilots (53:39.3 huge at the top of the picture = right overhead), fly over them and land in front; v1.32 dropped them straight down
  if not c then log("could not spawn a mecha (template " .. E.MECH .. " missing? run the SQL)"); return false end
  m.mechGuid = c:GetGUID(); g.mechOwner[c:GetGUIDLow()] = low
  m.landAt = { lx, ly, cz + 0.2 }                            -- in front of the pilots (v1.32)
  try(c, "MoveJump", lx, ly, cz + 0.2, BR.MECH_IN_SPEED, BR.MECH_JUMP_UP)   -- v1.37 (Rowan 00:15: 'going into the map in a nose dive and then goes upright as it lands. It is
                                                             --   supposed to be hovering as it lands'): v1.34's flying state made the client play its forward-flight
                                                             --   pose, nose first. A jump move has no pitch and plays the model's Jump / Fall / JumpEnd (upright).
  return true
end
local function seat(g, low, pl)                             -- v1.0.3: into the mecha that flew in (or a fresh one if it is not there)
  local m = g.members[low]
  local c = mechOf(g, m)
  if not c then return board(g, low, pl) end
  local L = m.landAt
  if L and (dist2(c:GetX(), c:GetY(), L[1], L[2]) > 3 or c:GetZ() > BR.CENTER[3] + 2) then
    try(c, "MoveStop"); try(c, "NearTeleport", L[1], L[2], L[3], pl:GetO())                -- it did not make it down by itself
    log(string.format("fly-in: %s's mecha was put on its landing spot (it had not arrived)", m.name))
  end
  if dist2(pl:GetX(), pl:GetY(), c:GetX(), c:GetY()) > 8 then try(pl, "NearTeleport", c:GetX() - 2, c:GetY(), BR.CENTER[3] + 0.5, math.pi) end   -- v1.19: pilot brought to his mecha
  return enter(g, low, pl, c)
end
local function eachMech(g, fn)                              -- fn(low, m, pl, x, y) for every mecha still standing
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) and not m.out then fn(low, m, pl, pl:GetX(), pl:GetY()) end
  end
end
local function standing(g)
  local n = 0
  eachMech(g, function() n = n + 1 end)
  return n
end
local function randomMech(g)
  local t = {}
  eachMech(g, function(low, m, pl, x, y) t[#t + 1] = { low, x, y } end)
  if #t == 0 then return nil end
  return t[math.random(#t)]
end
local function flying(m, t) return (m.flyUntil or 0) > t end
local function hurt(g, low, pct, what, t)                   -- a mecha loses pct % of its health; in the air nothing on the floor reaches it
  local m = g.members[low]
  if not m or m.out or flying(m, t) then return false end
  local up = getPlayer(g, low)                               -- v1.33 (Rowan 23:07 'even in the air I am taking floor and orb aoe damage'): it went by the
  if up and up:GetZ() > BR.CENTER[3] + BR.AIR_SAFE then return false end   --   boost's 6 s clock; a mecha coming down after that was still hit. Now by height.
  m.hp = m.hp - pct; m.hits = (m.hits or 0) + 1
  m.src = m.src or {}; m.src[what] = (m.src[what] or 0) + pct   -- v1.3: damage by source, written to the log at game over
  local pl = getPlayer(g, low)
  local c = mechOf(g, m)
  if m.hp > 0 then
    if c then
      local mx = try(c, "GetMaxHealth") or 100
      try(c, "SetHealth", math.max(1, math.floor(mx * m.hp / 100)))
    end
    if pl then pl:SendAreaTriggerMessage(string.format("%s!  Mecha: %d%%", what, math.max(1, math.floor(m.hp)))) end
  else
    m.out = true
    if pl then dropMech(g, low, pl, true) end
    tell(g, BT .. m.name .. "'s mecha was destroyed!", m.name .. "'s mecha was destroyed!")
  end
  return true
end

-- ---------- the Fel Reaver ----------
local function bossOf(g) return obj(g, g.bossGuid) end
local function bossPct(g)
  local b = bossOf(g)
  if not b then return 0 end
  return math.max(0, math.floor(100 * (b:GetHealth() or 0) / math.max(1, g.bossMax)))
end
local function hitBoss(g, dmg)                              -- script-side damage (bot guns, GM commands)
  local b = bossOf(g)
  if not b or g.bossDead then return end
  local h = (b:GetHealth() or 0) - dmg
  if h <= 0 then                                           -- v1.3: a real death (corpse), like live; 1 health if Kill is missing
    g.bossDead = true; try(b, "SetHealth", 1)
    local a = anchor(g); if a then try(a, "Kill", b, false) end
  else try(b, "SetHealth", h) end
end
local function spawnOrb(g, t, x, y, ang, speed, lead)       -- lead (yd): it starts that far along its path (stream orbs due between two ticks)
  lead = lead or 0
  local range = BR.ORB_RANGE - lead
  x, y = x + lead * math.cos(ang), y + lead * math.sin(ang)
  local life = range / speed * 1000
  local ex, ey = x + range * math.cos(ang), y + range * math.sin(ang)
  local c = helper(g, E.ORB, x, y, BR.CENTER[3] + 1.5, life + 500, S.ORBVIS)
  if c then try(c, "SetSpeed", 1, speed / 7.0, true); try(c, "SetSpeed", 6, speed / 7.0, true); try(c, "MoveTo", 0, ex, ey, BR.CENTER[3] + 1.5) end
  g.orbs[#g.orbs + 1] = { guid = c and c:GetGUID(), sx = x, sy = y, ex = ex, ey = ey, t0 = t, life = life, hit = {} }
end
local function segDist(px, py, ax, ay, bx, by)              -- v1.16: distance from a point to the stretch an orb covered since the last tick
  local dx, dy = bx - ax, by - ay
  local l2 = dx * dx + dy * dy
  if l2 < 0.0001 then return dist2(px, py, ax, ay) end
  local u = math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / l2))
  return dist2(px, py, ax + u * dx, ay + u * dy)
end
local function tickWalk(g, t)                               -- v1.0.2: the demon strolls round the middle of the arena
  if BR.WALK_EVERY <= 0 or g.edge or t < (g.nextWalk or 0) then return end
  g.nextWalk = t + BR.WALK_EVERY + math.random(0, 6000)
  local b = bossOf(g)
  if not b or g.floorAt or g.airPhase then return end
  local x, y = randSpot(0, BR.WALK_R)
  try(b, "SetRooted", false); try(b, "SetWalk", true); try(b, "SetSpeed", 0, BR.WALK_SPEED, true); try(b, "SetSpeed", 1, BR.WALK_SPEED, true)
  try(b, "MoveTo", 0, x, y, BR.CENTER[3] + 0.1)
end
local function orbRing(g, t, cx, cy, off, n)
  n = n or BR.RING_ORBS
  for k = 1, n do spawnOrb(g, t, cx, cy, off + 2 * math.pi * k / n, BR.RING_SPEED) end
end
local function orbSources(g)                               -- v1.4: in the air phase the standing Fel Pillars throw the orbs (Rowan 12:49)
  if not g.airPhase or #g.pillars == 0 then return nil end
  local t = {}
  for _, p in ipairs(g.pillars) do local c = obj(g, p.guid); if c then t[#t + 1] = { c:GetX(), c:GetY() } end end
  return #t > 0 and t or nil
end
local function tickOrbs(g, t)
  local cx, cy = BR.CENTER[1], BR.CENTER[2]
  local b0 = bossOf(g)
  if b0 then cx, cy = b0:GetX(), b0:GetY() end
  local srcs = orbSources(g)
  if g.airPhase and not srcs then return end                -- v1.12: no orbs while it rises (live 54:49-54:53) - pillars throw them later
  if t < (g.quietUntil or 0) then return end                -- v1.12: quiet after the crash
  if not srcs then                                          -- v1.12: SPIRAL ARMS from the Reaver
    g.nextSpiral = g.nextSpiral or (g.startedAt or t) + BR.SPIRAL_FIRST
    if t >= g.nextSpiral then
      g.nextSpiral = t + BR.SPIRAL_EVERY; g.spiralT0 = t; g.spiralEnd = t + BR.SPIRAL_TIME; g.spiralNext = t
      g.spiralAng = math.random() * 2 * math.pi; g.spiralDir = (math.random(2) == 1) and 1 or -1
    end
    if g.spiralEnd and g.spiralNext then                    -- v1.16: every orb that fell due since the last tick, each already that far out
      local n = 0
      while g.spiralNext <= t and g.spiralNext < g.spiralEnd and n < 6 do
        local lead = (t - g.spiralNext) / 1000 * BR.SPIRAL_SPEED
        local arms = (g.spiralNext - (g.spiralT0 or t) >= BR.SPIRAL_ARM2_AFTER) and BR.SPIRAL_ARMS or 1   -- one arm first, the second joins
        for k = 0, arms - 1 do spawnOrb(g, t, cx, cy, g.spiralAng + 2 * math.pi * k / BR.SPIRAL_ARMS, BR.SPIRAL_SPEED, lead) end
        g.spiralAng = g.spiralAng + BR.SPIRAL_TURN * (g.spiralDir or 1)
        g.spiralNext = g.spiralNext + BR.SPIRAL_STEP; n = n + 1
      end
    end
    if not g.edge and g.nextPillar and g.waveFor ~= g.nextPillar and t >= g.nextPillar - BR.WAVE_BEFORE_AIR then   -- v1.16: the ring wave before lift-off
      g.waveFor = g.nextPillar; g.waveLeft = BR.WAVE_RINGS; g.waveNext = t
    end
    if (g.waveLeft or 0) > 0 and t >= (g.waveNext or 0) then
      g.waveLeft = g.waveLeft - 1; g.waveNext = t + BR.WAVE_STEP
      orbRing(g, t, cx, cy, math.random() * 2 * math.pi)
    end
  end
  if g.ring2 and t >= g.ring2.at then
    if g.ring2.srcs then for _, p in ipairs(g.ring2.srcs) do orbRing(g, t, p[1], p[2], g.ring2.off, BR.PILLAR_RING_ORBS) end
    else orbRing(g, t, cx, cy, g.ring2.off) end
    g.ring2 = nil
  end
  if t >= g.nextRing then                                   -- a ring of orbs spreading out from the demon (footage 53:33)
    g.nextRing = t + BR.RING_EVERY
    local off = math.random() * 2 * math.pi
    if srcs then for _, p in ipairs(srcs) do orbRing(g, t, p[1], p[2], off, BR.PILLAR_RING_ORBS) end
    else orbRing(g, t, cx, cy, off) end
    if math.random(BR.RING_DOUBLE) == 1 then g.ring2 = { at = t + 900, off = off + math.pi / BR.RING_ORBS, srcs = srcs } end   -- double ring (54:22)
  end
  if t >= g.nextFan then                                    -- a fan of faster orbs aimed at one mecha
    g.nextFan = t + aimed(g, BR.FAN_EVERY)
    local r = randomMech(g)
    if srcs then local p = srcs[math.random(#srcs)]; cx, cy = p[1], p[2] end   -- v1.4: from a pillar in the air phase
    if r then
      local aim = math.atan(r[3] - cy, r[2] - cx)
      if math.atan2 then aim = math.atan2(r[3] - cy, r[2] - cx) end
      for k = 1, BR.FAN_ORBS do spawnOrb(g, t, cx, cy, aim + BR.FAN_SPREAD * ((k - 1) / (BR.FAN_ORBS - 1) - 0.5) * 2, BR.FAN_SPEED) end
    end
  end
  if t >= g.nextCarpet then                                 -- a carpet: orbs in every direction at mixed speeds (56:03)
    g.nextCarpet = t + BR.CARPET_EVERY
    if srcs then local p = srcs[math.random(#srcs)]; cx, cy = p[1], p[2] end
    for _ = 1, BR.CARPET_ORBS do spawnOrb(g, t, cx, cy, math.random() * 2 * math.pi, BR.CARPET_SMIN + math.random() * (BR.CARPET_SMAX - BR.CARPET_SMIN)) end
  end
  for i = #g.orbs, 1, -1 do
    local o = g.orbs[i]
    local f = (t - o.t0) / o.life
    local c = obj(g, o.guid)
    if f >= 1 then
      if c then c:DespawnOrUnsummon(0) end
      table.remove(g.orbs, i)
    elseif f > 0.04 then                                    -- the orb is where its marker really is
      local ox, oy = o.sx + (o.ex - o.sx) * f, o.sy + (o.ey - o.sy) * f
      if c then ox, oy = c:GetX(), c:GetY() end
      local qx, qy = o.px or ox, o.py or oy                  -- v1.16: where it was a tick ago
      eachMech(g, function(low, m, pl, x, y)
        if not o.hit[low] and segDist(x, y, qx, qy, ox, oy) <= BR.ORB_R then
          if hurt(g, low, BR.ORB_DMG, "Fel orb", t) then o.hit[low] = true end
        end
      end)
      o.px, o.py = ox, oy
    end
  end
end
local function tickPuddles(g, t)                            -- v1.1: FEL HIT ZONES: a round fel mark under a mecha, 3 s later it bursts
  if t >= g.nextPuddle then
    g.nextPuddle = t + aimed(g, BR.ZONE_EVERY)
    local r = randomMech(g)
    if r then
      local c = helper(g, E.ZONE, r[2], r[3], BR.CENTER[3] + 0.1, BR.ZONE_WARN + BR.ZONE_FLASH + 300)   -- unseen until it bursts
      local b = bossOf(g)
      if b and c then try(b, "CastSpell", c, S.FELCANNON, true) end   -- the fel shot coming down = the warning (live 54:01)
      g.puddles[#g.puddles + 1] = { guid = c and c:GetGUID(), x = r[2], y = r[3], at = t + BR.ZONE_WARN }
    end
  end
  for i = #g.puddles, 1, -1 do
    local p = g.puddles[i]
    if t >= p.at then
      local c = obj(g, p.guid)
      if c then try(c, "SetScale", BR.ZONE_SCALE); try(c, "AddAura", S.HITZONE, c); c:DespawnOrUnsummon(BR.ZONE_FLASH) end   -- the yellow starburst
      local lows = {}
      eachMech(g, function(low, m, pl, x, y) if dist2(x, y, p.x, p.y) <= BR.ZONE_R then lows[#lows + 1] = low end end)
      for _, low in ipairs(lows) do hurt(g, low, BR.ZONE_DMG, "Fel blast", t) end
      table.remove(g.puddles, i)
    end
  end
end
local function tickVortices(g, t)
  if t >= g.nextVortex then
    local n = math.max(1, math.ceil(g.count / 2))
    local live = math.ceil(BR.LIVE_PILOTS / 2) / BR.LIVE_PILOTS          -- v1.3: vortices per pilot per wave on live (3 of 5)
    g.nextVortex = t + math.floor(BR.VORTEX_EVERY * (n / math.max(1, g.count)) / live)   -- same load per pilot as live: solo every ~42 s
    for _ = 1, n do
      local x, y = randSpot(15, 50)
      local c = helper(g, E.SOAK, x, y, BR.CENTER[3] + 0.1, BR.VORTEX_TIME + 1500, S.FIREZONE)
      if c then try(c, "SetScale", BR.VORTEX_SCALE) end
      g.vortices[#g.vortices + 1] = { guid = c and c:GetGUID(), x = x, y = y, at = t + BR.VORTEX_TIME, soak = 0, last = t }
    end
    tell(g, BT .. (n == 1 and "Red fire! Run over it to snuff it out before it explodes." or (n .. " red fires! Run over them to snuff them out before they explode.")), "Red fire! Snuff it out!")
  end
  for i = #g.vortices, 1, -1 do
    local v = g.vortices[i]
    local c = obj(g, v.guid)
    local who
    eachMech(g, function(low, m, pl, x, y) if dist2(x, y, v.x, v.y) <= BR.VORTEX_R and pl:GetZ() <= BR.CENTER[3] + BR.VORTEX_UP then who = who or low end end)   -- v1.34 (Rowan 23:33, clip 1:49: 'I try to snuff out the fire pillar by standing over it but it does nothing'): he was on his boost, and a boosting mecha did not count. Now anyone over it and no more than VORTEX_UP above the floor snuffs it.
    if who then v.soak = v.soak + (t - v.last) end
    v.last = t
    if v.soak >= BR.VORTEX_SOAK then
      local m = g.members[who]
      if m then m.soaked = (m.soaked or 0) + 1 end           -- v1.34 (Rowan 23:33, clip 2:31: after the red fire 'my lightforged warframe stops its animation like it is frozen'): the script put 255617 'Anim: Soak' on the mecha and never took it off; its kit plays anims 213/214, which the warframe model does not have
      if c then c:DespawnOrUnsummon(300) end
      tell(g, BT .. (m and m.name or "Someone") .. " smothered a fiery vortex.")
      table.remove(g.vortices, i)
    elseif t >= v.at then
      if c then try(c, "CastSpell", c, S.SOAKBOOM, true); c:DespawnOrUnsummon(1200) end
      tell(g, BT .. "A fiery vortex exploded!", "A fiery vortex exploded!")
      local lows = {}
      eachMech(g, function(low) lows[#lows + 1] = low end)
      for _, low in ipairs(lows) do hurt(g, low, BR.VORTEX_DMG, "Vortex blast", t) end
      table.remove(g.vortices, i)
    end
  end
end
local function floorWarn(g, t)                              -- the whole floor is about to go off
  g.floorAt = t + BR.FLOOR_WARN
  tell(g, BT .. "The whole floor is turning green! Boost into the air! (button 3, then hold jump)", "The floor is turning green! BOOST!")
  CreateLuaEvent(function()                                 -- v1.26: the floor lights up for the last ~3 s (live 55:30.0-55:33), not from the first second
    if Games[g.inst] ~= g or not g.floorAt then return end
    for k = 0, 19 do
      local r, a = (k < 8) and 22 or 48, 2 * math.pi * k / ((k < 8) and 8 or 12)
      helper(g, E.ZONE, BR.CENTER[1] + r * math.cos(a), BR.CENTER[2] + r * math.sin(a), BR.CENTER[3] + 0.1, 3500, S.HITZONE)
    end
    for _, ring in ipairs(BR.FLOOR_RINGS) do              -- v1.42 (Rowan 01:15, after '#br floor': 'the green aoe fel stuff does not cover the entire floor ... I can go all the way to the
      for k = 0, ring[2] - 1 do                             --   wall of the tent and it does not reach me'): v1.40's one scaled-up zone changed nothing (his clip of v1.36 at 4:11-4:13 shows the 20
        local a = 2 * math.pi * (k + 0.5) / ring[2]         --   zones as one yellow disc that stops well short of the wall). More of the SAME zones, at their normal size, out to the wall: 30 at
        helper(g, E.ZONE, BR.CENTER[1] + ring[1] * math.cos(a), BR.CENTER[2] + ring[1] * math.sin(a), BR.CENTER[3] + 0.1, 3500, S.HITZONE)   --   66 yd and 38 at 84 yd (14 yd apart)
      end
    end
  end, math.max(0, BR.FLOOR_WARN - 3000), 1)
end
local function tickPillars(g, t)                            -- v1.2: AIR PHASE: the demon rises, Fel Pillars appear, then the floor goes green
  if t >= g.nextPillar and not g.floorAt and not g.airPhase and not g.edge then   -- v1.11: no pillar phase once it hovers at the edge
    g.nextPillar = t + BR.PILLAR_EVERY
    g.airPhase = true; g.airEnd = t + BR.PILLAR_TIME
    local b, a = bossOf(g), anchor(g)
    if b then
      try(b, "MoveStop"); try(b, "SetRooted", false); try(b, "SetDisableGravity", true); try(b, "SetHover", true)
      try(b, "AddAura", S.HOVER, b)
      try(b, "MoveTo", 0, b:GetX(), b:GetY(), BR.CENTER[3] + BR.AIR_UP)
    end
    g.pillarAt = t + BR.PILLAR_DELAY; g.airEnd = g.airEnd + BR.PILLAR_DELAY   -- v1.26: the pillars come 4 s after lift-off (live 54:49.4 -> 54:53.4)
    tell(g, BT .. "The Fel Reaver rises!", "The Fel Reaver rises!")
  end
  if g.airPhase and g.pillarAt and t >= g.pillarAt then
    g.pillarAt = nil
    local a = anchor(g)
    local n = math.min(BR.PILLAR_MAX, math.max(1, g.count) + 1)
    local off = math.random() * 2 * math.pi
    for k = 1, n do
      local ang, r = off + 2 * math.pi * k / n, BR.PILLAR_RMIN + math.random() * (BR.PILLAR_RMAX - BR.PILLAR_RMIN)   -- v1.4: by the wall
      local c = a and a:SpawnCreature(E.PILLAR, BR.CENTER[1] + r * math.cos(ang), BR.CENTER[2] + r * math.sin(ang), BR.CENTER[3] + 0.1, 0, TEMPSUMMON_TIMED_DESPAWN, BR.PILLAR_TIME + BR.FLOOR_WARN + 4000)
      if c then
        try(c, "SetMaxHealth", BR.PILLAR_HP); try(c, "SetHealth", BR.PILLAR_HP); try(c, "SetReactState", 0); try(c, "SetRooted", true)
        try(c, "SetDisplayId", BR.PILLAR_BODY); try(c, "SetScale", BR.PILLAR_SCALE)   -- v1.33 (Rowan 23:07: the pillars can be targeted but show nothing): the look was
        local pg = c:GetGUID()                                                       --   put on BEFORE the body was swapped for the invisible one, and the swap dropped it.
        CreateLuaEvent(function()                                                    --   Now the body first, the two kit visuals half a second later, as on the orbs.
          local p = Games[g.inst] == g and obj(g, pg)
          if not p then return end
          try(p, "AddAura", S.PILLAR, p); try(p, "AddAura", S.PILLAR2, p)
          if not g.pillarLook and not (try(p, "HasAura", S.PILLAR) == true or try(p, "HasAura", S.PILLAR2) == true) then g.pillarLook = true; log("pillar: neither 255610 nor 255621 stayed on the Fel Pillar") end
        end, 500, 1)
        g.pillars[#g.pillars + 1] = { guid = c:GetGUID() }
      end
    end
    if #g.pillars > 0 then
      tell(g, BT .. "The Fel Reaver rises! Destroy the Fel Pillars (Tab to target them). When the last one falls the floor turns green: boost up!", "Destroy the Fel Pillars!")
    else
      if not g.noPillar then g.noPillar = true; log("no Fel Pillar could be spawned (template " .. E.PILLAR .. " missing: run the SQL again): air phase without pillars") end
      g.airEnd = t + 8000
      tell(g, BT .. "The Fel Reaver rises!", "The Fel Reaver rises!")
    end
  end
  for i = #g.pillars, 1, -1 do
    local c = obj(g, g.pillars[i].guid)
    if not c or try(c, "IsDead") == true or (c:GetHealth() or 1) <= 0 then
      if c then                                             -- v1.12: a spinning green ring flashes out from the dead pillar (live 55:08, 55:11.8), no damage
        local px, py = c:GetX(), c:GetY()
        for d = 1, 16 do
          local ang = 2 * math.pi * d / 16
          local h = helper(g, E.ORB, px, py, BR.CENTER[3] + 1.0, 1400, S.ORBVIS)
          if h then try(h, "SetSpeed", 1, 3.0, true); try(h, "SetSpeed", 6, 3.0, true); try(h, "MoveTo", 0, px + 20 * math.cos(ang), py + 20 * math.sin(ang), BR.CENTER[3] + 1.0) end
        end
        c:DespawnOrUnsummon(500)
      end
      table.remove(g.pillars, i)
      g.pillarsDown = (g.pillarsDown or 0) + 1
      tell(g, BT .. "Fel Pillar destroyed! (" .. #g.pillars .. " left)", "Fel Pillar destroyed!")
    end
  end
  if g.airPhase and not g.floorAt and not g.pillarAt and (g.pillarsDown or 0) > 0 and #g.pillars == 0 then
    g.floorDmg = BR.FLOOR_DMG; g.pillarsCleared = true      -- v1.4 (Rowan 12:51): the LAST PILLAR falls -> the green fel floor at once: fly up (v1.7: lethal)
    tell(g, BT .. "The last Fel Pillar is down!")
    floorWarn(g, t)
  elseif g.airPhase and not g.floorAt and t >= g.airEnd then  -- pillars still up when time runs out: the floor comes anyway, harder (MINE)
    g.floorDmg = math.min(BR.FLOOR_DMG + 20, BR.FLOOR_BASE + BR.FLOOR_PER_PILLAR * #g.pillars)
    floorWarn(g, t)
  end
end
local function felShot(g, t, x, y)                          -- v1.4: one Fel Cannon shot from the hovering demon: mark, 1.5 s, burst
  g.rain = g.rain or {}
  local c = helper(g, E.ZONE, x, y, BR.CENTER[3] + 0.1, BR.RAIN_WARN + 1500, S.HITZONE)
  local b = bossOf(g)
  if b and c then try(b, "SetFacingToObject", c); try(b, "CastSpell", c, S.FELCANNON, true) end
  g.rain[#g.rain + 1] = { guid = c and c:GetGUID(), x = x, y = y, at = t + BR.RAIN_WARN }
end
local function tickRain(g, t)                              -- v1.4 (Rowan 12:48): while it hovers and the pillars stand, it shoots fel down
  g.rain = g.rain or {}
  if g.airPhase and not g.floorAt and t >= (g.nextRain or 0) then
    g.nextRain = t + aimed(g, BR.RAIN_EVERY)
    local r = randomMech(g)
    if r then
      local a, d = math.random() * 2 * math.pi, math.random() * BR.RAIN_NEAR
      felShot(g, t, r[2] + d * math.cos(a), r[3] + d * math.sin(a))
    end
  end
  for i = #g.rain, 1, -1 do
    local k = g.rain[i]
    if t >= k.at then
      local c = obj(g, k.guid)
      local lows = {}
      eachMech(g, function(low, m, pl, x, y) if dist2(x, y, k.x, k.y) <= BR.RAIN_R then lows[#lows + 1] = low end end)
      for _, low in ipairs(lows) do hurt(g, low, BR.RAIN_DMG, "Fel cannon", t) end
      table.remove(g.rain, i)
    end
  end
end
local function tickFloor(g, t)
  if g.floorAt and t >= g.floorAt then
    g.floorAt = nil; g.airPhase = nil
    g.crashedAt = g.crashedAt or t                           -- v1.8: the first crash starts the beam clock
    g.quietUntil = t + BR.QUIET_AFTER_CRASH; g.spiralEnd = nil; g.waveLeft = nil
    local lethal = g.pillarsCleared; g.pillarsCleared = nil
    for _, p in ipairs(g.pillars) do
      local c = obj(g, p.guid)
      if c then c:DespawnOrUnsummon(400) end
    end
    g.pillars = {}
    local b = bossOf(g)
    if b then                                               -- it lands with a fel burst (55:41)
      try(b, "RemoveAura", S.HOVER); try(b, "SetHover", false); try(b, "SetDisableGravity", false)
      try(b, "NearTeleport", b:GetX(), b:GetY(), BR.CENTER[3] + 0.1, b:GetO())
      playKit(g, b, KIT_SLAM)                                  -- v1.33: the slam kit (cracked floor), not the fel target circle 255611
      try(b, "CastSpell", b, S.EMOTE51, true)              -- v1.4: the crash (Rowan 12:51: fel cracks); 255607 'Fel Reaver: Emote 51' = candidate, untested
      tell(g, BT .. "The Fel Reaver crashes down!", "The Fel Reaver crashes down!")
    end
    local lows = {}
    eachMech(g, function(low) lows[#lows + 1] = low end)
    for _, low in ipairs(lows) do
      local m = g.members[low]
      if flying(m, t) then m.dodged = (m.dodged or 0) + 1 else hurt(g, low, (BR.FLOOR_KILL and lethal) and 100 or (g.floorDmg or BR.FLOOR_DMG), "Fel floor", t) end
    end
  end
end
local function tickShock(g, t)                              -- v1.2: SHOCK RINGS from half health: a beam hits the floor, a ring spreads from the spot
  if not g.airPhase and not g.floorAt and not g.edge and bossOf(g) and bossPct(g) <= BR.SHOCK_AT then   -- v1.7: last phase: it slides to the far edge and stays
    g.edge = true
    local b = bossOf(g)
    if b then
      local cx, cy = BR.CENTER[1], BR.CENTER[2]
      local a = math.atan2 and math.atan2(b:GetY() - cy, b:GetX() - cx) or 0
      slideBoss(g, cx + BR.EDGE_R * math.cos(a), cy + BR.EDGE_R * math.sin(a), 1800)
      local guid = g.bossGuid
      CreateLuaEvent(function()                              -- v1.11 (Rowan 19:31): at the edge it RISES and HOVERS until it dies
        local c = Games[g.inst] == g and g.bossGuid == guid and bossOf(g)
        if not c then return end
        try(c, "RemoveAura", S.EMOTE51); try(c, "EmoteState", 0); try(c, "SetRooted", false); try(c, "SetDisableGravity", true); try(c, "SetHover", true)
        try(c, "AddAura", S.HOVER, c); try(c, "SetSpeed", 6, 1.2, true); try(c, "SetSpeed", 1, 1.2, true)
        try(c, "MoveTo", 0, c:GetX(), c:GetY(), BR.CENTER[3] + BR.EDGE_UP)
        CreateLuaEvent(function() local d = Games[g.inst] == g and g.bossGuid == guid and bossOf(g); if d then try(d, "SetRooted", true) end end, 2500, 1)
      end, 2700, 1)
    end
    tell(g, BT .. "The Fel Reaver falls back to the edge of the arena!", "The Fel Reaver falls back!")
  end
  local beams = g.edge or (g.crashedAt and t >= g.crashedAt + BR.BEAM_AFTER_CRASH)   -- v1.8: like live, from ~25 s after the first crash
  if beams and not g.beamsOn then g.beamsOn = true; tell(g, BT .. "The Fel Reaver fires its fel cannon! Each blast throws a ring across the floor: boost over it.", "Fel cannon!") end
  if not g.airPhase and not g.floorAt and beams and t >= (g.nextShock or 0) then
    g.nextShock = t + aimed(g, BR.SHOCK_EVERY)
    local r = randomMech(g)
    if r then
      local c = helper(g, E.ZONE, r[2], r[3], BR.CENTER[3] + 0.1, BR.SHOCK_WARN + 2600)
      local b = bossOf(g)
      if b and c then try(b, "SetFacingToObject", c); try(b, "CastSpell", c, S.FELCANNON, true) end   -- the green bolt from its arm (live 56:42-58:19)
      g.shocks[#g.shocks + 1] = { guid = c and c:GetGUID(), x = r[2], y = r[3], t0 = t + BR.SHOCK_WARN, hit = {} }
    end
  end
  for i = #g.shocks, 1, -1 do
    local k = g.shocks[i]
    if t >= k.t0 then
      if not k.out then                                     -- v1.22: the flat yellow-green disc spreading from the hit (live 56:43.2-56:44.6)
        k.out = true
        local c = obj(g, k.guid)
        if c then try(c, "AddAura", S.HITZONE, c) else helper(g, E.ZONE, k.x, k.y, BR.CENTER[3] + 0.1, 2400, S.HITZONE) end
      end
      local rad = (t - k.t0) / 1000 * BR.SHOCK_SPEED
      if rad > BR.SHOCK_R then table.remove(g.shocks, i)
      else
        local lows = {}
        eachMech(g, function(low, m, pl, x, y)
          if not k.hit[low] and math.abs(dist2(x, y, k.x, k.y) - rad) <= 2.5 then k.hit[low] = true; lows[#lows + 1] = low end
        end)
        for _, low in ipairs(lows) do hurt(g, low, BR.SHOCK_DMG, "Fel shock ring", t) end
      end
    end
  end
end
local function tickHoly(g, t)                              -- v1.7: healing Light Orbs: pick one up to repair your mecha
  g.holy = g.holy or {}
  -- v1.15 BALANCE (Rowan: 'so the player doesn't die quickly nor ends up in god mode'): orbs only come for a hurt pilot.
  --   Everyone above HOLY_FULL % -> none. Lowest pilot below HOLY_LOW % -> one every ~12 s, else every 25-33 s.
  --   Each orb lands 12-30 yd from a hurt pilot (you must fly to it, away from where you stand), at most HOLY_MAX on the floor,
  --   +13 % each, never above 100 %. Live rate unknown; these numbers are ours.
  local low, lowM = nil, 101
  eachMech(g, function(l, m, pl, x, y) if m.hp < lowM then low, lowM = { x, y }, m.hp end end)
  if low and lowM < BR.HOLY_FULL and #g.holy < BR.HOLY_MAX and t >= (g.nextHoly or (g.startedAt or t) + BR.HOLY_EVERY) then
    g.nextHoly = t + ((lowM < BR.HOLY_LOW) and BR.HOLY_LOW_EVERY or (BR.HOLY_EVERY + math.random(0, 4000)))
    local a, d = math.random() * 2 * math.pi, BR.HOLY_NEAR[1] + math.random() * (BR.HOLY_NEAR[2] - BR.HOLY_NEAR[1])
    local x, y = low[1] + d * math.cos(a), low[2] + d * math.sin(a)
    if dist2(x, y, BR.CENTER[1], BR.CENTER[2]) > BR.FLOOR_R - 5 then x, y = randSpot(15, 55) end
    local c = helper(g, E.ORB, x, y, BR.CENTER[3] + 1.5, BR.HOLY_LIFE, S.HOLYORB)
    g.holy[#g.holy + 1] = { guid = c and c:GetGUID(), x = x, y = y, till = t + BR.HOLY_LIFE }
  end
  for i = #g.holy, 1, -1 do
    local h = g.holy[i]
    local got
    eachMech(g, function(low, m, pl, x, y)
      if not got and m.hp < 100 and dist2(x, y, h.x, h.y) <= BR.HOLY_R then got = low end
    end)
    if got then
      local m = g.members[got]
      m.hp = math.min(100, m.hp + BR.HOLY_HEAL); m.healed = (m.healed or 0) + 1
      local c = mechOf(g, m)
      if c then local mx = try(c, "GetMaxHealth") or 100; try(c, "SetHealth", math.max(1, math.floor(mx * m.hp / 100))) end
      local pl = getPlayer(g, got); if pl then pl:SendAreaTriggerMessage(string.format("Light Orb!  Mecha: %d%%", math.floor(m.hp))) end
      local o = obj(g, h.guid); if o then o:DespawnOrUnsummon(0) end
      table.remove(g.holy, i)
    elseif t >= h.till then table.remove(g.holy, i) end
  end
end
local function tickEnergy(g, t)                             -- v1.21 (Rowan 21:32: 'my energy runs out way too fast'): the mecha's energy refills
  if t < (g.nextEnergy or 0) then return end
  g.nextEnergy = t + BR.ENERGY_EVERY
  eachMech(g, function(low, m)
    local c = mechOf(g, m)
    local e, mx = c and try(c, "GetPower", 3), c and try(c, "GetMaxPower", 3)
    if type(mx) ~= "number" or mx <= 0 then mx = 100 end
    if type(e) == "number" and e < mx then try(c, "SetPower", math.min(mx, e + math.max(1, math.floor(mx * BR.ENERGY_ADD / 100))), 3) end
  end)
end
local function tickGuns(g, t)                               -- the bots' unmanned mechas: steady script damage
  if #g.guns == 0 or t < (g.nextGun or 0) then return end
  g.nextGun = t + BR.GUN_EVERY
  local b = bossOf(g)
  for _, gun in ipairs(g.guns) do
    local c = obj(g, gun.guid)
    if c and b then try(c, "SetFacingToObject", b); try(c, "PerformEmote", 36); hitBoss(g, BR.GUN_DMG) end
  end
end

-- ---------- leaving ----------
local function sendHome(g, low)
  local m = g.members[low]
  local pl = getPlayer(g, low)
  if not (m and pl) then return end
  try(pl, "RemoveAura", S.READY)
  dropMech(g, low, pl)
  music(pl, 0)                                              -- v1.43: the game's music stops when you are sent back
  local h = m.home or BR.FAIRE_SPOT
  later(m.guid, 600, function(p) if p:GetMapId() == BR.MAP then p:Teleport(h[1], h[2], h[3], h[4], h[5]) end end)
end
local function clearField(g)
  for _, list in ipairs({ g.orbs, g.puddles, g.vortices, g.guns, g.pillars }) do
    for _, h in ipairs(list) do local c = obj(g, h.guid); if c then c:DespawnOrUnsummon(0) end end
  end
  g.orbs, g.puddles, g.vortices, g.guns, g.pillars = {}, {}, {}, {}, {}
  for _, k in ipairs(g.rain or {}) do local c = obj(g, k.guid); if c then c:DespawnOrUnsummon(0) end end
  g.ring2 = nil; g.shocks = {}; g.airPhase = nil; g.rain = {}
  local b = bossOf(g); if b then b:DespawnOrUnsummon(0) end
  g.bossGuid = nil
  local pt = obj(g, g.portalGuid); if pt then pt:DespawnOrUnsummon(0) end
  local rk = obj(g, g.rikkyGuid); if rk then rk:DespawnOrUnsummon(0) end
  local xp = obj(g, g.exitGuid); if xp then xp:DespawnOrUnsummon(0) end
  g.portalGuid, g.rikkyGuid, g.exitGuid = nil, nil, nil
end
local function cleanup(g, why)
  clearField(g)
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then sendHome(g, low) else local c = mechOf(g, m); if c then c:DespawnOrUnsummon(0) end end
  end
  if g.inst then Games[g.inst] = nil end
  log("game closed (" .. tostring(why) .. ")")
end

-- ---------- the game ----------
local function bigCountdown(pl, ms)                         -- the client's own big numbers (found for the Rainbow Race, v2.1.4)
  if not (BR.BIG_COUNTDOWN and pl and type(CreatePacket) == "function") then return false end
  local ok, err = pcall(function() local pk = CreatePacket(OP_COUNTDOWN, 4); pk:WriteULong(ms); pl:SendPacket(pk) end)
  if not ok then log("could not send the countdown packet: " .. tostring(err)) end
  return ok
end
local function spawnBoss(g, x, y)
  local a = anchor(g)
  if not a then return nil end
  local cx, cy, cz = BR.CENTER[1], BR.CENTER[2], BR.CENTER[3]
  local b = a:SpawnCreature(E.BOSS, x, y, cz + 0.1, math.atan(cy - y, cx - x), TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if not b then log("could not spawn the Fel Reaver (template " .. E.BOSS .. " missing? run the SQL)"); return nil end
  g.bossGuid = b:GetGUID()
  if BR.BOSS_SCALE then try(b, "SetScale", BR.BOSS_SCALE) end
  try(b, "SetReactState", 0); try(b, "SetRooted", true); try(b, "SetLevel", BR.BOSS_LEVEL)
  return b
end
local function sweepLeftovers(g)                            -- v1.0.4: whatever an earlier game (or a reload) left in the tent
  local a = anchor(g)
  if not a then return end
  local n = 0
  for _, e in ipairs({ E.BOSS, E.MECH, E.GUN, E.ORB, E.SOAK, E.SOAKBOOM, E.ZONE, E.RIKKY, E.PILLAR, E.EXIT }) do   -- v1.28: the exit portal too (a reload left the old one standing = two portals); the Rainbow Race's own is thousands of yards away
    for _, c in ipairs(try(a, "GetCreaturesInRange", 250, e) or {}) do c:DespawnOrUnsummon(0); n = n + 1 end
  end
  if n > 0 then log("lobby: removed " .. n .. " creature(s) left over from an earlier game") end
end
local function openLobby(g)                                 -- v1.17: Rikky riding the Fel Reaver Head, there the moment you load in (live 53:10.9)
  local a = anchor(g)
  if not a then return end
  sweepLeftovers(g)
  local cx, cy, cz = BR.CENTER[1], BR.CENTER[2], BR.CENTER[3]
  local ax, ay = arriveSpot(1, 0, 1)                         -- v1.31: the sides of the tent are fixed by the ARRIVAL SPOT, not by where a player stands when the lobby opens
  local face = math.atan(ay - cy, ax - cx)                   --   (round 2 opened with the player on the far half, so the fel portal came up by the Azzar Faire Portal)
  if math.atan2 then face = math.atan2(ay - cy, ax - cx) end
  g.portalGuid = nil
  local rk = a:SpawnCreature(E.RIKKY, cx, cy, cz + 0.1, face, TEMPSUMMON_TIMED_DESPAWN, LIFE)
  local mounted = false
  if rk then
    g.rikkyGuid = rk:GetGUID(); try(rk, "SetRooted", true)
    local d, m = try(rk, "GetUInt32Value", F_DISPLAY), try(rk, "GetUInt32Value", F_MOUNT)   -- only write the mount field if the fields sit where 3.3.5 has them
    if type(d) == "number" and d == try(rk, "GetDisplayId") and m == 0 and try(rk, "GetMountId") == 0 then
      try(rk, "SetUInt32Value", F_MOUNT, HEAD_DISPLAY)
      mounted = try(rk, "GetMountId") == HEAD_DISPLAY
      if mounted then try(rk, "SetFlag", F_FLAGS, UF_MOUNT) else try(rk, "SetUInt32Value", F_MOUNT, 0) end
    end
  end
  if not g.mountLogged then g.mountLogged = true; log(mounted and "lobby: Rikky is mounted on the Fel Reaver Head" or "lobby: Rikky is NOT mounted (this core did not take the mount field): head prop used instead") end
  if not mounted then                                       -- the old way: a head prop with Rikky on top, now without its name label
    local pt = a:SpawnCreature(E.ZONE, cx, cy, cz + 1.1 * HEAD_SCALE, face, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if pt then g.portalGuid = pt:GetGUID(); try(pt, "SetDisplayId", HEAD_DISPLAY); try(pt, "SetScale", HEAD_SCALE); unsel(pt) end
    if rk then try(rk, "SetDisableGravity", true); try(rk, "NearTeleport", cx, cy, cz + 2.6 * HEAD_SCALE, face) end
  end
  if rk and BR.RIKKY_RIDE then                              -- v1.24 (Rowan 21:43): from the middle straight at the Azzar Faire Portal, stopping short of it
    local tx, ty = arriveSpot(1, BR.EXIT_BACK, 1)
    local d = math.max(1, dist2(tx, ty, cx, cy))
    if d > BR.RIKKY_STOP + 3 then
      local f = (d - BR.RIKKY_STOP) / d
      try(rk, "SetRooted", false); try(rk, "SetWalk", false); try(rk, "SetSpeed", 1, BR.RIKKY_SPEED, true)
      if not mounted then try(rk, "SetSpeed", 6, BR.RIKKY_SPEED, true) end
      try(rk, "MoveTo", 0, cx + (tx - cx) * f, cy + (ty - cy) * f, mounted and (cz + 0.1) or (cz + 2.6 * HEAD_SCALE))
      local pt0 = obj(g, g.portalGuid)
      if pt0 then try(pt0, "SetSpeed", 1, BR.RIKKY_SPEED, true); try(pt0, "MoveTo", 0, cx + (tx - cx) * f, cy + (ty - cy) * f, cz + 1.1 * HEAD_SCALE) end
    end
  end
  local ang = face + math.pi                                -- the side of the tent across from the first player
  g.standX, g.standY = cx + BR.BOSS_STAND_R * math.cos(ang), cy + BR.BOSS_STAND_R * math.sin(ang)   -- where it stops after 'Round N is starting!'
  g.waitX, g.waitY = cx + BR.LOBBY_BOSS_R * math.cos(ang), cy + BR.LOBBY_BOSS_R * math.sin(ang)     -- in front of the portal during the ready check
  g.portX, g.portY, g.portO = cx + BR.PORTAL_R * math.cos(ang), cy + BR.PORTAL_R * math.sin(ang), ang + math.pi
  g.lobbyAt = now(); g.bossOut = nil; g.felPortal = nil; g.portalAt = nil
  if not obj(g, g.exitGuid) then                            -- v1.20: the Azzar Faire Portal, just behind where the players port in
    local ex, ey = arriveSpot(1, BR.EXIT_BACK, 1)
    local xp = a:SpawnCreature(E.EXIT, ex, ey, cz + 0.1, math.pi, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if xp then g.exitGuid = xp:GetGUID(); try(xp, "SetDisplayId", BR.BUBBLE_DISPLAY); try(xp, "SetScale", BR.BUBBLE_SCALE); try(xp, "SetNPCFlags", 1); try(xp, "SetRooted", true)
    elseif not g.noExit then g.noExit = true; log("no Azzar Faire Portal (creature " .. E.EXIT .. " missing: the Rainbow Race podium SQL adds it); Rikky and #leave still take you back") end
  end
end
local function drawFelPortal(g, t, life)                    -- v1.25: the fel portal + its lightning points (also redrawn by '#br pscale' / '#br lift')
  local a = anchor(g)
  local cz = BR.CENTER[3]
  if not (a and g.portX) then return end
  local old = obj(g, g.fpGuid); if old then old:DespawnOrUnsummon(0) end
  for _, list in ipairs({ g.bolts or {}, g.strikes or {}, { g.beamGuid } }) do for _, bg in ipairs(list) do local o = obj(g, bg); if o then o:DespawnOrUnsummon(0) end end end
  g.fpGuid, g.bolts, g.strikes, g.strikeSpots, g.strikeBusy, g.beamGuid = nil, nil, nil, nil, nil, nil
  local fp = a:SpawnCreature(E.ZONE, g.portX, g.portY, cz + BR.PORTAL_LIFT, g.portO, TEMPSUMMON_TIMED_DESPAWN, life)
  if fp then
    g.fpGuid = fp:GetGUID(); try(fp, "SetDisableGravity", true); try(fp, "SetDisplayId", BR.PORTAL_DISPLAY); try(fp, "SetScale", BR.PORTAL_SCALE); unsel(fp)
    g.bolts = {}; g.nextBolt = t + 1500                    -- v1.21: lightning strikes out of the ring (live 53:17.9, 53:18.4, 53:19.7, 53:21.9, 53:23.6)
    local sx, sy = -math.sin(g.portO), math.cos(g.portO)  -- along the wall
    local fx, fy = math.cos(g.portO) * BR.BOLT_FRONT, math.sin(g.portO) * BR.BOLT_FRONT   -- v1.41 (Rowan 01:10: 'the lightning is still the same. Maybe put it just past the portal? ... it looks
    local bc = a:SpawnCreature(E.ZONE, g.portX + fx, g.portY + fy, cz + BR.PORTAL_LIFT, g.portO, TEMPSUMMON_TIMED_DESPAWN, life)   --   like its inside the fel portal'): measured, he is right. The portal model's
    if bc then try(bc, "SetDisableGravity", true); unsel(bc); g.beamGuid = bc:GetGUID() end   --   layers stand 0-1.0 model units in FRONT of its own spot = 0-13 yd at scale 13, and the lightning was 6 yd in front
                                                            --   = between the layers. All of it now 16 yd in front (3 yd clear), and the beams start from an unseen point there, not from the portal
    for _, q in ipairs({ { -38, 30 }, { 36, 44 }, { 30, 8 }, { -26, 52 } }) do   -- v1.38: the GREEN BEAMS of v1.21-v1.35 are back exactly as they were (Rowan 00:47: 'We had it before at the beginning'; v1.36 had taken them out)
      local bt = a:SpawnCreature(E.ZONE, g.portX + sx * q[1] + fx, g.portY + sy * q[1] + fy, cz + q[2], 0, TEMPSUMMON_TIMED_DESPAWN, life)
      if bt then try(bt, "SetDisableGravity", true); unsel(bt); g.bolts[#g.bolts + 1] = bt:GetGUID() end
    end
    g.strikes, g.strikeSpots, g.strikeBusy, g.nextStrike = {}, {}, {}, t + 2000   -- v1.38: the STRIKES. A creature fades in over its first second (v1.37's strikes lived 0.95 s = 'traces'), so unseen
    for _, q in ipairs({ -43, -33, 34, 44 }) do              --   helpers stand on the floor at the sides of the ring from the moment the portal opens and a strike = they wear the strike model for 1.1 s.
      local spot = {}                                        --   v1.39 (Rowan 00:58 'Lightning I can see but it needs to be more pronounced'): TWO helpers a spot (the second 2 yd along, a little
      for n = 1, BR.BOLT_TWIN do                             --   smaller) lit together = a brighter, thicker bolt; scale 0.4 -> 0.55
        local lat, out = q + (n - 1) * 2, BR.BOLT_FRONT + (n - 1)
        local st = a:SpawnCreature(E.ZONE, g.portX + sx * lat + math.cos(g.portO) * out, g.portY + sy * lat + math.sin(g.portO) * out, cz + 0.1, g.portO, TEMPSUMMON_TIMED_DESPAWN, life)
        if st then try(st, "SetScale", BR.BOLT_SCALE * (n == 1 and 1 or 0.88)); unsel(st); g.strikes[#g.strikes + 1] = st:GetGUID(); spot[#spot + 1] = st:GetGUID() end
      end
      g.strikeSpots[#g.strikeSpots + 1] = spot
    end
  end
end
local function tickLobby(g, t)                              -- v1.17: live timing: the portal opens, the Reaver comes out of its middle down to the floor
  if not g.lobbyAt then return end
  local cz = BR.CENTER[3]
  if not g.felPortal and t >= g.lobbyAt + BR.PORTAL_AFTER then
    g.felPortal = true; g.portalAt = t
    musicAll(g, BR.MUSIC_INTRO)                              -- v1.43: live: the intro track starts as the fel portal opens (53:18.2; portal 53:18.9)
    local a = anchor(g)
    drawFelPortal(g, t, BR.PORTAL_TIME)
  end
  if g.fpGuid and g.bolts and #g.bolts > 0 and t >= (g.nextBolt or 0) then
    g.nextBolt = t + math.random(BR.BEAM_MIN, BR.BEAM_MAX)
    local fp, bt = obj(g, g.fpGuid), obj(g, g.bolts[math.random(#g.bolts)])
    if fp and bt then try(obj(g, g.beamGuid) or fp, "CastSpell", bt, BR.BOLT_SPELL, true) else g.fpGuid = nil end   -- v1.38: as in v1.21-v1.35; v1.41: from the point in front of the portal
  end
  if g.fpGuid and g.strikeSpots and #g.strikeSpots > 0 and t >= (g.nextStrike or 0) then
    g.nextStrike = t + math.random(BR.BOLT_MIN, BR.BOLT_MAX)   -- v1.39: every 0.5-1.4 s (was 0.7-2.2; live: 5 in 6 s), and half the time a second bolt on the other side at the same moment
    if obj(g, g.fpGuid) then
      local k, n = math.random(#g.strikeSpots), #g.strikeSpots
      for shot = 1, (math.random(100) <= BR.BOLT_DOUBLE) and 2 or 1 do
        if (g.strikeBusy[k] or 0) > t then k = k % n + 1 end
        if (g.strikeBusy[k] or 0) <= t then
          g.strikeBusy[k] = t + BR.BOLT_LIFE + 300
          for _, guid in ipairs(g.strikeSpots[k]) do
            local st = obj(g, guid)
            if st then
              try(st, "SetDisplayId", BR.BOLT_DISPLAY)     -- display 126744 = 7FX_Argus_Felstorm_LightningStrike_State.m2 (1.0 s animation)
              CreateLuaEvent(function() local o = Games[g.inst] == g and obj(g, guid); if o then try(o, "SetDisplayId", BR.BOLT_HIDE) end end, BR.BOLT_LIFE, 1)
            end
          end
        end
        k = (k + math.floor(n / 2) - 1) % n + 1               -- the second bolt of a pair: the other side of the ring
      end
    end
  end
  if g.bossOut or bossOf(g) or not g.portalAt or t < g.portalAt + BR.BOSS_OUT_AFTER then return end
  g.bossOut = true
  local b = spawnBoss(g, g.waitX, g.waitY)
  if b then
    rockets(b, true)
    local ux, uy = (g.portX - BR.CENTER[1]) / BR.PORTAL_R, (g.portY - BR.CENTER[2]) / BR.PORTAL_R   -- v1.33 (Rowan 23:07-23:08): 'from the top of the tent,
    local sx0, sy0 = g.portX + ux * BR.LAND_BACK, g.portY + uy * BR.LAND_BACK                      --   BEHIND the fel portal, and glide diagonally down to the floor using his
    try(b, "NearTeleport", sx0, sy0, cz + BR.LAND_FROM, math.atan2 and math.atan2(BR.CENTER[2] - g.portY, BR.CENTER[1] - g.portX) or 0)   --   rockets like a power landing'
    local guid, t0 = g.bossGuid, now()
    local dx = dist2(sx0, sy0, g.waitX, g.waitY)
    local d3 = math.sqrt(dx * dx + BR.LAND_FROM * BR.LAND_FROM)
    local rate = math.max(1, d3 / (BR.LAND_MS / 1000) / 7.0)    -- v1.32's log: it arrives when asked (2350 asked, 2180-2840 seen by a 0.1 s poll)
    try(b, "SetSpeed", 6, rate, true); try(b, "SetSpeed", 1, rate, true)
    try(b, "MoveTo", 0, g.waitX, g.waitY, cz + 0.3, false)       -- one smooth straight move (v1.30): through the ring, down to the floor in front of it
    local function touchDown(c)                                  -- set down, and the SLAM (anim + cracked floor)
      log(string.format("entrance: touch-down %d ms after the move began (the server had it %.1f yd from its spot, %.1f yd up)", now() - t0, dist2(c:GetX(), c:GetY(), g.waitX, g.waitY), c:GetZ() - cz))
      try(c, "MoveStop"); rockets(c, false); try(c, "NearTeleport", g.waitX, g.waitY, cz + 0.1, c:GetO())
      try(c, "SetRooted", true); try(c, "SetSpeed", 1, 1.0, true)
      playKit(g, c, KIT_SLAM)                                    -- Rowan 23:08: 'there is no fel crack like he slammed into the floor. It is a fel aoe which is not right'
    end
    local function watch()                                       -- v1.54 (Rowan 03:11: 'he came out of the portal almost perfectly but did a quick step'; 'There is definitly something
      local c = Games[g.inst] == g and g.bossGuid == guid and bossOf(g)   --   going on'): the touch-down used to come by the clock (2.25 s after the start) and tonight's log has the Reaver
      if not c or g.state == "countdown" or g.state == "playing" then return end   --   anywhere from already standing there to 3.6 yd short at that moment. Now it comes when the server SEES him
      local far, up = dist2(c:GetX(), c:GetY(), g.waitX, g.waitY), c:GetZ() - cz   --   at his spot (checked every 0.1 s), at the latest 0.8 s after the planned time.
      if (far <= 0.5 and up <= 0.6) or now() - t0 >= BR.LAND_MS + 800 then touchDown(c) else CreateLuaEvent(watch, 100, 1) end
    end
    CreateLuaEvent(watch, math.max(100, BR.LAND_MS - 700), 1)
  end
end
local function setUp(g, t)                                  -- everyone is ready: health for the head count, the bot guns, the countdown
  local a = anchor(g)
  if not a then return false end
  local cx, cy, cz = BR.CENTER[1], BR.CENTER[2], BR.CENTER[3]
  local b = bossOf(g) or spawnBoss(g, g.waitX or cx, g.waitY or cy)   -- v1.5: everyone ready before it came out: it appears in front of the portal
  if not b then return false end
  g.bossMax = BR.BOSS_HP * math.max(1, g.count) + BR.BOSS_HP_GUN * g.gunCount
  try(b, "SetMaxHealth", g.bossMax); try(b, "SetHealth", g.bossMax)
  local pt = obj(g, g.portalGuid)                           -- the head prop (only there if Rikky could not be mounted)
  if pt then pt:DespawnOrUnsummon(300) end
  local rk = obj(g, g.rikkyGuid); if rk then rk:DespawnOrUnsummon(300) end
  local xp = obj(g, g.exitGuid); if xp then xp:DespawnOrUnsummon(300) end   -- v1.20: the way out closes when the round starts
  g.portalGuid, g.rikkyGuid, g.exitGuid = nil, nil, nil
  g.bigOk = true; g.introFly, g.introDive, g.introLand, g.introSeat, g.introRush, g.mechIdx = nil, nil, nil, nil, nil, nil
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      try(pl, "RemoveAura", S.READY)
      m.hp = 100; m.out = nil; m.busyUntil = t + 12000
      if not bigCountdown(pl, BR.COUNTDOWN * 1000) then g.bigOk = false end
      if not BR.SHOW_COUNT then g.bigOk = true end           -- v1.17: no numbers at all (live)
    end
  end
  local fac = try(a, "GetFaction")
  for k = 1, g.gunCount do
    local ang = 2 * math.pi * k / g.gunCount + 0.4
    local c = a:SpawnCreature(E.GUN, cx + BR.GUN_RING * math.cos(ang), cy + BR.GUN_RING * math.sin(ang), cz + 0.2, ang + math.pi, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if c then
      if fac then try(c, "SetFaction", fac) end
      g.guns[#g.guns + 1] = { guid = c:GetGUID(), name = g.gunNames[k] }
    end
  end
  return true
end
slideBoss = function(g, tx, ty, ms)                   -- v1.6: the power slide. Kit spell 255607 is 'Fel Reaver: Emote 51' and anim 51 on
  local b = bossOf(g)                                       --   felreaver2.m2 is ReadySpellDirected (a braced pose): it HOLDS that pose (emote
  if not b then return end                                  --   617 STATE_READYSPELLDIRECTED) while it is moved. Two ways to move it (GM #br slide):
  local cz = BR.CENTER[3]                                   --   'pose' = normal move with the pose held; 'step' = small hops every 0.1 s (no walk
  try(b, "SetRooted", false); try(b, "EmoteState", BR.SLIDE_EMOTE)   --   cycle at all, if the client drops the pose while moving)
  try(b, "SetFacing", math.atan2 and math.atan2(ty - b:GetY(), tx - b:GetX()) or 0)
  local mode = BR.SLIDE_MODE                                -- v1.33: ONE smooth straight move holding the pose with the kit's own aura 255607 (its kit plays animation 51 while it is on).
  if mode == "aura" or mode == "kit" or mode == "lead" or mode == "late" or mode == "jumpa" or mode == "leadjump" then
    -- v1.51 (Rowan 02:49 on v1.50: 'no dice. Still does the same thing as last time'): what is KNOWN from his three reports + one clip:
    --   aura  = aura + run together (v1.33-v1.47): walks ~0.5 s, then the pose to the end.
    --   kit   = the same + the pose as a visual-kit packet at the start and every 0.6 s (v1.49/1.50): pose ~1 s, then walks to the end.
    -- NOT KNOWN, so each can be tried by eye with '#br slide <name>' in the lobby (the Reaver slides 12 yd toward you), no reload between:
    --   lead     = aura first, the run 0.6 s later          <- THE GAME'S SLIDE since v1.52: Rowan tried it (02:59 '#br slide lead which can be followed by the stomp'): no walking
    --   late     = packet pose + run together, the aura 0.5 s later
    --   jumpa    = aura + a FLAT JUMP instead of a run      (a jump has no walk cycle; this model has no jump animation)
    --   leadjump = aura first, the flat jump 0.6 s later
    local d = dist2(b:GetX(), b:GetY(), tx, ty)
    local guid = g.bossGuid
    local lead = (mode == "lead" or mode == "leadjump") and BR.SLIDE_LEAD or 0
    local go = math.max(300, ms - lead)                      -- it still arrives when it did
    local rate = math.max(1, d / (go / 1000) / 7.0)
    local function still() return Games[g.inst] == g and g.bossGuid == guid and bossOf(g) or nil end
    local function move(c)
      if mode == "jumpa" or mode == "leadjump" then try(c, "MoveJump", tx, ty, cz + 0.1, d / (go / 1000), BR.JUMP_UP)
      else try(c, "SetWalk", false); try(c, "SetSpeed", 1, rate, true); try(c, "MoveTo", 0, tx, ty, cz + 0.1, false) end
    end
    if mode ~= "late" then try(b, "AddAura", S.EMOTE51, b) end
    if lead > 0 then CreateLuaEvent(function() local c = still(); if c and try(c, "HasAura", S.EMOTE51) then move(c) end end, lead, 1) else move(b) end
    if lead > 0 then                                         -- v1.52: the pose comes off as it ARRIVES (it used to stay on until the stomp ~1 s later): the stomp's own animation only
      local n = 0                                            --   showed when the aura's pose was no longer up at that moment. v1.53 (Rowan 03:03: round 1 'did a two step and stomped', round
      local function watch()                                 --   2 fine): v1.52 took it off by the clock (2.3 s) and this server's timers run up to ~0.6 s late (see the 'touch-down' log
        local c = still(); n = n + 1                         --   lines), so in round 1 it came off before he had arrived. Now it comes off when the server SEES him at his spot.
        if not c or not try(c, "HasAura", S.EMOTE51) then return end
        if dist2(c:GetX(), c:GetY(), tx, ty) <= 1.5 or n * 100 >= ms + 1500 then try(c, "RemoveAura", S.EMOTE51); return end
        CreateLuaEvent(watch, 100, 1)
      end
      CreateLuaEvent(watch, lead + 300, 1)
    end
    if mode == "kit" or mode == "late" then playKit(g, b, KIT_SLIDE) end
    if mode == "kit" then
      for k = 1, math.ceil((ms + 1500) / BR.SLIDE_KIT_EVERY) do
        CreateLuaEvent(function() local c = still(); if c and try(c, "HasAura", S.EMOTE51) then playKit(g, c, KIT_SLIDE) end end, k * BR.SLIDE_KIT_EVERY, 1)
      end
    end
    if mode == "late" then CreateLuaEvent(function() local c = still(); if c then try(c, "AddAura", S.EMOTE51, c) end end, BR.SLIDE_LATE, 1) end
    return
  end
  if BR.SLIDE_MODE == "step" then
    local x0, y0, guid = b:GetX(), b:GetY(), g.bossGuid
    local n = math.max(1, math.floor(ms / BR.SLIDE_STEP_MS))
    local o = math.atan2 and math.atan2(ty - y0, tx - x0) or 0
    for k = 1, n do
      CreateLuaEvent(function()
        local c = Games[g.inst] == g and g.bossGuid == guid and bossOf(g)
        if c then try(c, "NearTeleport", x0 + (tx - x0) * k / n, y0 + (ty - y0) * k / n, cz + 0.1, o) end
      end, k * BR.SLIDE_STEP_MS, 1)
    end
  else
    local d = dist2(b:GetX(), b:GetY(), tx, ty)
    local rate = math.max(1, d / (ms / 1000) / 7.0)
    if BR.SLIDE_MODE == "jump" then                         -- v1.18: a flat jump: carried across in its standing pose, no walk cycle
      try(b, "EmoteState", 0)
      try(b, "MoveJump", tx, ty, cz + 0.1, d / (ms / 1000), BR.JUMP_UP)
      return
    end
    if BR.SLIDE_MODE == "hover" then                        -- v1.19: on its rockets, a little off the floor
      try(b, "EmoteState", 0); rockets(b, true)
      try(b, "SetSpeed", 6, rate, true); try(b, "SetSpeed", 1, rate, true)
      try(b, "MoveTo", 0, tx, ty, cz + BR.HOVER_UP)
      return
    end
    if BR.SLIDE_MODE == "glide" then try(b, "SetDisableGravity", true); try(b, "SetSpeed", 6, rate, true) end   -- v1.17: no leg movement (the way it comes down from the portal)
    try(b, "SetWalk", false); try(b, "SetSpeed", 1, rate, true)
    try(b, "MoveTo", 0, tx, ty, cz + 0.1)
  end
end
local function tickIntro(g, t)                              -- v1.5: the countdown, from Rowan's frame-by-frame screenshots 0185-0252
  local el = t - g.countAt
  local cx, cy, cz = BR.CENTER[1], BR.CENTER[2], BR.CENTER[3]
  local sx, sy = g.standX or cx, g.standY or cy
  if not g.introRush then                                   -- 0185-0216: right after 'Round N is starting!' it walks quickly to the middle
    g.introRush = true
    slideBoss(g, sx, sy, BR.BOSS_RUSH_MS)                    -- v1.6: a power slide, not a walk (Rowan 13:47)
  end
  g.mechIdx = g.mechIdx or 0                                -- 0210-0240: the mechas drop from above one after another
  if el >= (g.mechIdx == 0 and BR.MECH_FIRST or (BR.MECH_REST + (g.mechIdx - 1) * BR.MECH_STEP)) then   -- v1.32: live: the first, then the rest ~2.3 s later, close together
    local k = 0
    for low, m in pairs(g.members) do
      if k == g.mechIdx then
        local pl = getPlayer(g, low)
        if inGame(g, pl) and not m.mechGuid then flyInMech(g, low, pl) end
      end
      k = k + 1
    end
    if g.mechIdx < k then g.mechIdx = g.mechIdx + 1 end
  end
  if not g.introLand and el >= BR.STOMP_AT then             -- 0218-0232: it stomps: green burst at its feet, yellow fel cracks over the floor
    g.introLand = true
    local b = bossOf(g)
    if b and dist2(b:GetX(), b:GetY(), sx, sy) > 6 then
      log(string.format("intro: the Fel Reaver was put on its spot (it was %.1f yd short; it did not walk there by itself)", dist2(b:GetX(), b:GetY(), sx, sy)))
      try(b, "MoveStop"); try(b, "NearTeleport", sx, sy, cz + 0.1, math.atan2 and math.atan2(cy - sy, cx - sx) or 0)
    elseif b then log("intro: the Fel Reaver slid to the middle by itself") end
    if b then
      rockets(b, false); try(b, "NearTeleport", b:GetX(), b:GetY(), cz + 0.1, math.atan2 and math.atan2(cy - b:GetY(), cx - b:GetX()) or b:GetO())
      try(b, "RemoveAura", S.EMOTE51); try(b, "SetRooted", true); try(b, "SetSpeed", 1, 1.0, true); try(b, "EmoteState", 0)   -- set down, out of the slide
      playKit(g, b, KIT_SLAM)                                  -- v1.33: the stomp = the slam kit (anim 463 + cracked floor), not the fel target circle
    end
  end
  if not g.introSeat and el >= BR.SEAT_AT then              -- 0248: pilots are in their mechas
    g.introSeat = true
    for low, _ in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) and not seat(g, low, pl) then pl:SendBroadcastMessage(BT .. "Could not seat you in your mecha: click it to get in.") end
    end
  end
end
local function endGame(g, t, won, why)
  musicAll(g, 0)                                              -- v1.46: the fight track ends with the round, so the next lobby's intro starts from silence (OURS: the live video ends 5 s after the kill)
  g.state = "done"; g.doneAt = t
  local b = bossOf(g)
  for _, list in ipairs({ g.orbs, g.puddles, g.vortices, g.pillars }) do
    for _, h in ipairs(list) do local c = obj(g, h.guid); if c then c:DespawnOrUnsummon(0) end end
  end
  g.orbs, g.puddles, g.vortices, g.pillars = {}, {}, {}, {}
  g.shocks = {}; g.airPhase = nil; g.rain = {}
  if won then
    if b then
      try(b, "RemoveAllAuras")
      if b:GetZ() > BR.CENTER[3] + 2 then                    -- v1.11: it was hovering: the corpse comes down onto the floor
        try(b, "SetHover", false); try(b, "SetDisableGravity", false)
        try(b, "NearTeleport", b:GetX(), b:GetY(), BR.CENTER[3] + 0.1, b:GetO())
      end
      b:DespawnOrUnsummon(3500)                               -- v1.12: live the corpse stands ~3.5 s (58:26.6-58:30)
    end
    tell(g, BT .. "The Fel Reaver has been broken!", "The Fel Reaver has been broken!")
  else
    tell(g, BT .. why, why)
  end
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl and inGame(g, pl) then
      hold(mechOf(g, m), true)
      pl:SendBroadcastMessage(BT .. string.format("%s: mecha %d%%, hits taken %d, vortices smothered %d, floor blasts dodged %d.", m.name, math.max(0, math.floor(m.hp or 0)), m.hits or 0, m.soaked or 0, m.dodged or 0))
      if won and not m.rewarded then                        -- tickets and the quest once per visit
        m.rewarded = true
        try(pl, "AddItem", ITEM_TICKET, BR.TICKETS)
        if pl:HasQuest(Q_BASE) or pl:HasQuest(Q_DAILY) then pl:KilledMonsterCredit(E.CREDIT) end
      end
    end
  end
  log(string.format("game over: %s (%s), fight %s, demon at %d%% of %d, %d player(s), %d bot gun(s)", won and "WON" or "lost", tostring(why or "demon destroyed"),
      mmss((t - (g.startedAt or t)) / 1000), won and 0 or bossPct(g), g.bossMax or 0, g.count, g.gunCount)
      .. ((g.regens or 0) > 0 and (", health put back " .. g.regens .. " time(s)") or ""))
  for _, m in pairs(g.members) do                           -- v1.3: what hurt each pilot (%% of a mecha, summed)
    local parts = {}
    for what, pct in pairs(m.src or {}) do parts[#parts + 1] = what .. " " .. pct .. "%" end
    table.sort(parts)
    log(string.format("  %s: mecha %d%%, hits %d (%s)", m.name, math.max(0, math.floor(m.hp or 0)), m.hits or 0, #parts > 0 and table.concat(parts, ", ") or "none"))
  end
end
local function tickGame(g, t)
  if g.state == "arriving" then
    if not g.lobbyOpen and anchor(g) then g.lobbyOpen = true; openLobby(g) end   -- v1.17: Rikky is there (and left-overs are gone) the moment the first player is in
    do local okL, errL = pcall(tickLobby, g, t); if not okL then log("lobby error: " .. tostring(errL)) end end
    local allIn = true
    for low, _ in pairs(g.members) do if not inGame(g, getPlayer(g, low)) then allIn = false end end
    if (allIn and t >= g.arrivedAt + BR.ARRIVE_WAIT) or t >= g.arrivedAt + BR.ARRIVE_MAX then
      for low, _ in pairs(g.members) do
        if not inGame(g, getPlayer(g, low)) then g.members[low] = nil; g.count = math.max(0, g.count - 1) end
      end
      g.state = "ready"; g.readyAt = t
      tell(g, BT .. "Talk to Rikky in the middle when you are ready (or say #ready). #leave = back to the Faire.")
      if not g.lobbyOpen then g.lobbyOpen = true; openLobby(g) end
      if g.gunCount > 0 then tell(g, BT .. g.gunCount .. " bot gun" .. (g.gunCount == 1 and "" or "s") .. " will fight beside you: " .. table.concat(g.gunNames, ", ") .. ".") end
    end
  elseif g.state == "ready" then
    do local okL, errL = pcall(tickLobby, g, t); if not okL then log("lobby error: " .. tostring(errL)) end end
    local allReady, n = true, 0
    for low, m in pairs(g.members) do
      if inGame(g, getPlayer(g, low)) then n = n + 1; if not m.ready then allReady = false end
      else
        m.goneSince = m.goneSince or t
        if t > m.goneSince + 15000 then g.members[low] = nil; g.count = math.max(0, g.count - 1) end
      end
    end
    if n > 0 and allReady then
      if not setUp(g, t) then cleanup(g, "set-up failed"); return end
      g.state = "countdown"; g.countAt = t; g.lastCount = nil
      musicAll(g, 0)                                          -- v1.46: live: the intro fades out at 'Round N is starting!' (gone by 53:40; starting 53:36.8), silence, fight track at 53:45.2
      tell(g, AZT .. "Round " .. g.round .. " is starting!")
      tell(g, BT .. "1 = basic shot, 2 = super shot, 3 = boost (a few seconds in the air). Target the Fel Reaver. Dodge the orbs and the fel marks, run over the red fire to snuff it out, shoot the Fel Pillars down, boost (3, then hold jump) if the floor turns green.")
    elseif t > g.readyAt + BR.READY_MAX then cleanup(g, "nobody readied up"); return
    end
  elseif g.state == "countdown" then
    local okI, errI = pcall(tickIntro, g, t)
    if not okI then log("intro error: " .. tostring(errI)) end
    local n = BR.COUNTDOWN - math.floor((t - g.countAt) / 1000)
    if n ~= g.lastCount then
      g.lastCount = n
      if n > 0 then
        if not g.bigOk then tell(g, BT .. n .. "...", tostring(n)) end
      else
        g.state = "playing"; g.startedAt = t; g.endAt = t + BR.GAME_TIME * 1000; g.nextBoard = t + 60000
        g.musicAt = t; fightMusic(g)             -- v1.43: live: the fight track starts the moment the pilots are seated (53:45.2; seated 53:45.3)
        g.nextRing, g.nextFan, g.nextPuddle, g.nextCarpet = t + BR.RING_FIRST, t + BR.FAN_FIRST, t + BR.ZONE_FIRST, t + BR.CARPET_FIRST
        g.nextVortex, g.nextPillar = t + BR.VORTEX_FIRST, t + BR.PILLAR_FIRST
        g.bossHp = g.bossMax; g.nextWalk = t + BR.WALK_EVERY
        local b1 = bossOf(g); if b1 then try(b1, "SetHealth", g.bossMax) end
        for low, m in pairs(g.members) do                    -- anyone not seated yet gets a mecha now
          local pl = getPlayer(g, low)
          if inGame(g, pl) and not mechOf(g, m) then board(g, low, pl) end
          m.busyUntil = t + 3000
          hold(mechOf(g, m), false)
        end
        tell(g, BT .. "Fight! End of Game: " .. mmss(BR.GAME_TIME), "FIGHT!")
        log(string.format("game started: %d player(s), %d bot gun(s), demon health %d", g.count, g.gunCount, g.bossMax))
      end
    end
  elseif g.state == "playing" then
    if t - (g.musicAt or t) >= BR.MUSIC_AGAIN then g.musicAt = t; fightMusic(g) end   -- v1.43: live: not looped: played once (ends 55:53.5), silent, started again at 57:57.2
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) then
        m.goneSince = nil
        if not m.out then
          if m.flyUntil and t >= m.flyUntil then
            m.flyUntil = nil
            local c = mechOf(g, m)
            if c then
              try(c, "RemoveAura", S.FLIGHT); try(c, "RemoveAura", S.FLYAURA); try(c, "AddAura", S.FLYAURA, c); try(c, "RemoveAura", S.FLYAURA); try(c, "SetDisableGravity", false); try(c, "SetHover", false)   -- v1.37: fly aura on and off again at the end of every boost: the core only tells the client 'cannot fly' when it believes it still can
              try(c, "NearTeleport", c:GetX(), c:GetY(), BR.CENTER[3] + 0.3, c:GetO())      -- v1.0.2: back onto the floor
            end
            m.landCheck = t + 1200
            log(string.format("boost over: %s reached z %.1f (floor %.1f)", m.name, m.maxZ or 0, BR.CENTER[3]))
            pl:SendAreaTriggerMessage("Boost over.")
          elseif m.landCheck and t >= m.landCheck then        -- v1.0.2: still up there? out, down, back in (health is kept)
            m.landCheck = nil
            if pl:GetZ() > BR.CENTER[3] + 3 then
              log(string.format("landing: %s was still at z %.1f after the teleport: re-seating on the floor", m.name, pl:GetZ()))
              local x, y, o = pl:GetX(), pl:GetY(), pl:GetO()
              dropMech(g, low, pl); pl:NearTeleport(x, y, BR.CENTER[3] + 0.5, o); m.busyUntil = t + 2500
              later(m.guid, 800, function(p) if Games[g.inst] == g and g.members[low] and g.state == "playing" and not g.members[low].out then board(g, low, p) end end)
            else log(string.format("landing: %s is down at z %.1f", m.name, pl:GetZ())) end
          elseif m.flyUntil then m.maxZ = math.max(m.maxZ or 0, pl:GetZ())
          end
          if not m.flyUntil and not m.landCheck and t > (m.busyUntil or 0) and pl:GetZ() > BR.CENTER[3] + BR.AIR_GUARD then   -- v1.37 (Rowan 00:15 'I have infinite boost
            m.upSince = m.upSince or t                           --   capability which should not happen'; log of his v1.36 run: 3 boosts, then 5 minutes in the air
            if t - m.upSince >= 1500 then                        --   with no boost running): a mecha that is up with no boost is put back down, and it is logged
              local c = mechOf(g, m)
              if (m.upLogged or 0) < 5 then m.upLogged = (m.upLogged or 0) + 1; log(string.format("flight guard: %s is %.1f yd up with no boost running (fly aura %s, Golden Flight %s): put back on the floor", m.name, pl:GetZ() - BR.CENTER[3], tostring(c and try(c, "HasAura", S.FLYAURA)), tostring(c and try(c, "HasAura", S.FLIGHT)))) end
              if c then
                try(c, "RemoveAura", S.FLYAURA); try(c, "AddAura", S.FLYAURA, c); try(c, "RemoveAura", S.FLYAURA); try(c, "RemoveAura", S.FLIGHT)   -- on and off again, so the core tells the client it cannot fly
                try(c, "SetDisableGravity", false); try(c, "SetHover", false)
                try(c, "NearTeleport", c:GetX(), c:GetY(), BR.CENTER[3] + 0.3, c:GetO())
              end
              m.upSince = nil; m.landCheck = t + 1200            -- still up after that = out, down, back in (the old landing check)
              pl:SendAreaTriggerMessage("Boost over.")
            end
          else m.upSince = nil end
          if dist2(pl:GetX(), pl:GetY(), BR.CENTER[1], BR.CENTER[2]) > 110 or pl:GetZ() < BR.CENTER[3] - 15 then   -- out of the tent
            dropMech(g, low, pl); pl:NearTeleport(BR.CENTER[1] + BR.START_R, BR.CENTER[2], BR.CENTER[3] + 0.5, math.pi); m.busyUntil = t + 2500
            later(m.guid, 800, function(p) if Games[g.inst] == g and g.members[low] and g.state == "playing" then board(g, low, p) end end)
          elseif not mechOf(g, m) and t > (m.busyUntil or 0) then m.busyUntil = t + 3000; board(g, low, pl) end
        end
      else
        m.goneSince = m.goneSince or t
        if t > m.goneSince + 15000 then
          local c = mechOf(g, m); if c then c:DespawnOrUnsummon(0) end
          g.members[low] = nil; g.count = math.max(0, g.count - 1); log(m.name .. " left the game")
        end
      end
    end
    for _, h in ipairs({ { tickWalk, "walk" }, { tickOrbs, "orb" }, { tickPuddles, "fel zone" }, { tickVortices, "vortex" }, { tickPillars, "pillar" }, { tickRain, "fel rain" }, { tickFloor, "floor" }, { tickShock, "shock ring" }, { tickHoly, "light orb" }, { tickEnergy, "energy" }, { tickGuns, "bot gun" } }) do
      local ok, err = pcall(h[1], g, t)
      if not ok then log(h[2] .. " error: " .. tostring(err)) end
    end
    if g.endAt - t <= 30000 and not g.warned then g.warned = true; tell(g, BT .. "30 seconds left! Fel Reaver: " .. bossPct(g) .. "%", "30 seconds left!") end
    if not anchor(g) then                                   -- v1.3: nobody in the arena (left / loading): wait 15 s, then close
      g.emptySince = g.emptySince or t
      if t > g.emptySince + 15000 then cleanup(g, "nobody left in the arena") end
      return
    end
    g.emptySince = nil
    local b = bossOf(g)
    if b and not g.bossDead then                            -- v1.0.5: the demon's health only ever goes down
      local h = b:GetHealth() or 0
      if g.bossHp and h > g.bossHp then
        try(b, "SetHealth", g.bossHp)
        g.regens = (g.regens or 0) + 1
        if g.regens <= 3 then log(string.format("demon health rose by itself (%d -> %d): put back", g.bossHp, h)) end
      else g.bossHp = h end
    end
    if g.bossDead or (b and (try(b, "IsDead") == true or (b:GetHealth() or 1) <= 0)) then endGame(g, t, true)
    elseif not b then endGame(g, t, false, "The Fel Reaver is gone. (Tell Claude: the demon despawned.)")
    elseif standing(g) == 0 then endGame(g, t, false, "Every mecha was destroyed. The Fel Reaver stands.")
    elseif t >= g.endAt then endGame(g, t, false, "Time's up! The Fel Reaver stands at " .. bossPct(g) .. "%.") end
  elseif g.state == "done" and t > g.doneAt + 8000 then      -- v1.1: back to the lobby for another round, like live
    local n = 0
    for low, _ in pairs(g.members) do if inGame(g, getPlayer(g, low)) then n = n + 1 end end
    if n == 0 then cleanup(g, "finished"); return end
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if pl then dropMech(g, low, pl) end
      m.ready, m.out, m.hp, m.flyUntil, m.flyReady, m.landCheck, m.hits, m.soaked, m.dodged = nil, nil, 100, nil, nil, nil, nil, nil, nil; m.src = nil
    end
    clearField(g)
    g.bossDead, g.floorAt, g.regens, g.warned, g.bossHp, g.pillarsDown = nil, nil, nil, nil, nil, nil
    g.airPhase, g.nextShock, g.floorDmg, g.edge, g.holy, g.nextHoly, g.pillarsCleared = nil, nil, nil, nil, nil, nil, nil; g.pillarAt = nil
    g.crashedAt, g.beamsOn, g.quietUntil, g.nextSpiral, g.spiralEnd = nil, nil, nil, nil, nil
    g.spiralNext, g.waveFor, g.waveLeft, g.waveNext = nil, nil, nil, nil
    g.round = g.round + 1
    g.state = "ready"; g.readyAt = t
    openLobby(g)
    local line = string.format("Round %d is complete. Round %d is now available!", g.round - 1, g.round)
    tell(g, AZT .. line, line)
    tell(g, BT .. "Talk to Rikky in the middle to go again, or ask him (or say #leave) to go back to the Faire.")
  end
  local here = 0
  for _ in pairs(g.members) do here = here + 1 end
  if here == 0 and g.state ~= "arriving" then cleanup(g, "nobody left") end
end
local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)
    if t > g.created + 90000 then Pending[sLow] = nil; log("start cancelled (starter did not arrive within 90 s)")
    elseif st and st:GetMapId() == BR.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then st:SendBroadcastMessage(BT .. "A game is already running here.")
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
  local members, count, gunNames = {}, 0, {}
  local function add(p)
    if count + #gunNames >= BR.MAX_SEATS then return end
    if try(p, "IsBot") == true then gunNames[#gunNames + 1] = p:GetName(); return end   -- a bot stays at the Faire; its unmanned mecha fights
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), name = p:GetName(), slot = count, hp = 100,
                     home = (p:GetMapId() ~= BR.MAP) and { p:GetMapId(), p:GetX(), p:GetY(), p:GetZ(), p:GetO() } or nil }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= BR.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  if count == 0 then return end
  local g = { members = members, count = count, gunCount = #gunNames, gunNames = gunNames, created = now(), state = "pending", seats = count,
              orbs = {}, puddles = {}, vortices = {}, guns = {}, pillars = {}, shocks = {}, mechOwner = {}, round = 1 }
  Pending[player:GetGUIDLow()] = g
  for low, m in pairs(members) do
    local p = GetPlayerByGUID(m.guid)
    if p then
      local ax, ay = arriveSpot(m.slot, 0, count)
      p:SendBroadcastMessage(AZT .. "You have joined the Bullet Romper queue.")
      p:Teleport(BR.MAP, ax, ay, BR.CENTER[3] + 0.5, math.pi)   -- v1.19: one arrival spot at the edge, facing the middle
    end
  end
  log(string.format("%s starts Bullet Romper with %d player(s) and %d bot gun(s)", player:GetName(), count, #gunNames))
end

-- ---------- Rikky ----------
local function leaveGame(player)                            -- back to the Faire (#leave, or Rikky in the arena)
  local low = player:GetGUIDLow()
  local g = Games[player:GetInstanceId()]
  if g and g.members[low] then
    sendHome(g, low)
    later(player:GetGUID(), 1500, function() if g.members[low] then g.members[low] = nil; g.count = math.max(0, g.count - 1) end end)
  else
    local f = BR.FAIRE_SPOT; player:Teleport(f[1], f[2], f[3], f[4], f[5])
  end
  player:SendBroadcastMessage(BT .. "Back to the Faire you go!")
end
local function markReady(player)                            -- the ready check (Rikky in the arena, or #ready)
  local g = Games[player:GetInstanceId()]
  local low = player:GetGUIDLow()
  if not (g and g.members[low]) then return false end
  if g.state == "ready" and not g.members[low].ready then
    g.members[low].ready = true
    try(player, "CastSpell", player, S.READY, true)
    if try(player, "HasAura", S.READY) ~= true then try(player, "AddAura", S.READY, player) end
    tell(g, BT .. player:GetName() .. " is ready.")
    local waiting = false
    for l2, m2 in pairs(g.members) do if not m2.ready then waiting = true end end
    if waiting then tell(g, AZT .. "Every player must be ready before the round can start.", "Every player must be ready before the round can start.") end   -- v1.17: live 53:30.6
  end
  return true
end
local function rikkyMenu(player, creature)
  player:GossipClearMenu()
  if creature:GetMapId() == BR.MAP then                     -- v1.0.3: Rikky on the Fel Reaver Head in the arena
    player:GossipMenuAddItem(0, "I'm ready!", 0, 10)
    player:GossipMenuAddItem(0, "Can you tell me more about Bullet Romper?", 0, 2)
    player:GossipMenuAddItem(0, "Take me back to the Faire.", 0, 11)
    player:GossipSendMenu(TEXT_GREET, creature)
    return
  end
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Get in the mech! (Bullet Romper, with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about Bullet Romper?", 0, 2)
  player:GossipMenuAddItem(1, "I'd like to browse your goods.", 0, 3)
  player:GossipSendMenu(TEXT_GREET, creature)
end
-- v1.13 (Rowan 19:50): a pilot whose mecha is destroyed is OUT of the fight: takes no damage (hurt() skips them) and cannot hurt the
--   Reaver either (live: every on-foot hit shows 'Miss'). Damage dealt by a PLAYER directly (not by a mecha) is cancelled here.
if type(RegisterCreatureEvent) == "function" then
  pcall(RegisterCreatureEvent, E.BOSS, 9, function(event, creature, attacker, damage)      -- CREATURE_EVENT_ON_DAMAGE_TAKEN
    if not (attacker and attacker.GetTypeId and attacker:GetTypeId() == 4) then return end   -- 4 = player (mecha shots come from the mecha)
    local low = attacker:GetGUIDLow()
    for _, g in pairs(Games) do local m = g.members[low]; if m and m.out then return 0 end end   -- only pilots whose mecha is destroyed
  end)
end
local function ourExit(creature) return creature:GetMapId() == BR.MAP and dist2(creature:GetX(), creature:GetY(), BR.CENTER[1], BR.CENTER[2]) < 140 end   -- the Rainbow Race's own portal is elsewhere on this map
RegisterCreatureGossipEvent(E.EXIT, 1, function(event, player, creature)
  if not ourExit(creature) then return end
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Exit!", 0, 20, false, "Are you sure you want to exit?")
  player:GossipSendMenu(TEXT_EXIT, creature)
end)
RegisterCreatureGossipEvent(E.EXIT, 2, function(event, player, creature, sender, intid)
  if not ourExit(creature) then return end
  player:GossipComplete()
  if intid == 20 then leaveGame(player) end
end)
RegisterCreatureGossipEvent(E.RIKKY, 1, function(event, player, creature) rikkyMenu(player, creature) end)
RegisterCreatureGossipEvent(E.RIKKY, 2, function(event, player, creature, sender, intid)
  if intid == 10 then
    player:GossipComplete()
    markReady(player)
  elseif intid == 11 then
    player:GossipComplete()
    leaveGame(player)
  elseif intid == 1 then
    player:GossipComplete()
    if creature:GetMapId() == BR.MAP then return end
    if busy(player) then player:SendBroadcastMessage(BT .. "You are already in a game."); return end
    startSession(player)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_MORE, creature)
  elseif intid == 3 then
    player:GossipComplete(); player:SendListInventory(creature)
  else
    rikkyMenu(player, creature)
  end
end)

-- ---------- the boost (button 3) ----------
local function casterOf(a, b)
  local function has(o, k) local ok2, f = pcall(function() return o[k] end); return ok2 and type(f) == "function" end
  local caster = a
  if a and has(a, "GetCaster") and not has(a, "GetMapId") then caster = a:GetCaster() end
  if b and has(b, "GetCaster") and not (caster and has(caster, "GetMapId")) then caster = b:GetCaster() end
  return caster
end
local function memberOf(caster)
  if not caster or caster:GetMapId() ~= BR.MAP then return nil end
  local g = Games[caster:GetInstanceId()]
  if not g or g.state ~= "playing" then return nil end
  local low = caster:GetGUIDLow()
  if not g.members[low] then low = g.mechOwner[low] end
  if low and g.members[low] then return g, low end
  return nil
end
local function onFlight(caster)
  local g, low = memberOf(caster)
  if not g then return end
  local m, pl, t = g.members[low], getPlayer(g, low), now()
  if m.out or not pl then return end
  local c = mechOf(g, m)
  if t < (m.flyReady or 0) then
    if c then try(c, "RemoveAura", S.FLIGHT) end
    pl:SendAreaTriggerMessage(string.format("Boost recharging: %d s", math.ceil((m.flyReady - t) / 1000)))
    return
  end
  m.flyUntil = t + BR.FLY_MS; m.flyReady = t + BR.FLY_CD; m.maxZ = pl:GetZ()
  if c then try(c, "AddAura", S.FLYAURA, c) end            -- v1.0.1: a real fly aura, so the client lets the mecha climb
  pl:SendAreaTriggerMessage("BOOST! Hold JUMP to climb (" .. (BR.FLY_MS / 1000) .. " s)")
end
do
  local ok, err = pcall(RegisterSpellEvent, S.FLIGHT, 2, function(event, a, b)
    local ok3, err3 = pcall(onFlight, casterOf(a, b))
    if not ok3 then log("boost error: " .. tostring(err3)) end
  end)
  if not ok then log("RegisterSpellEvent(boost) failed: " .. tostring(err)) end
end

-- ---------- chat commands ----------
local function nearArena(pl) return pl:GetMapId() == BR.MAP and dist2(pl:GetX(), pl:GetY(), BR.CENTER[1], BR.CENTER[2]) < 140 end
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#leave" then
    if not nearArena(player) then return end
    leaveGame(player)
    return false
  end
  if msg == "#ready" then
    if not nearArena(player) or not markReady(player) then return end
    return false
  end
  local cmd, arg = msg:match("^#br%s+(%a+)%s*(%S*)$")
  if not cmd or (player:GetGMRank() or 0) < 1 then return end
  cmd = cmd:lower()
  local g = Games[player:GetInstanceId()]
  local playing = g and g.state == "playing"
  if cmd == "start" then
    if busy(player) then player:SendBroadcastMessage(BT .. "You are already in a game.") else startSession(player) end
  elseif cmd == "time" and tonumber(arg) and playing then
    g.endAt = now() + tonumber(arg) * 1000; player:SendBroadcastMessage(BT .. "End of Game: " .. mmss(tonumber(arg)))
  elseif cmd == "hp" and tonumber(arg) and playing then
    local b = bossOf(g)
    if b then g.bossHp = math.max(1, math.floor(g.bossMax * tonumber(arg) / 100)); try(b, "SetHealth", g.bossHp) end
    player:SendBroadcastMessage(BT .. "Fel Reaver: " .. bossPct(g) .. "%")
  elseif cmd == "kill" and playing then
    g.bossDead = true
  elseif cmd == "scale" and tonumber(arg) and g then
    try(bossOf(g), "SetScale", tonumber(arg)); player:SendBroadcastMessage(BT .. "Fel Reaver scale " .. arg .. " (this game only).")
  elseif cmd == "info" and g then                            -- v1.0.1: what the server sees (also in the log)
    local m = g.members[player:GetGUIDLow()]
    local c, b = m and mechOf(g, m), bossOf(g)
    local function line(tag, u)
      if not u then return tag .. ": none" end
      return string.format("%s: %.1f %.1f %.1f  faction %s  health %s/%s  power %s (type %s)  scale %s", tag, u:GetX(), u:GetY(), u:GetZ(),
        tostring(try(u, "GetFaction")), tostring(try(u, "GetHealth")), tostring(try(u, "GetMaxHealth")), tostring(try(u, "GetPower", 3)), tostring(try(u, "GetPowerType")), tostring(try(u, "GetScale")))
    end
    local out = { line("you", player), line("mecha", c), line("demon", b) }
    if c and b then
      local dz = c:GetZ() - b:GetZ()
      out[#out + 1] = string.format("mecha to demon: %.1f yd flat, %.1f yd in 3D; state %s", dist2(c:GetX(), c:GetY(), b:GetX(), b:GetY()), math.sqrt(dist2(c:GetX(), c:GetY(), b:GetX(), b:GetY()) ^ 2 + dz * dz), tostring(g.state))
    end
    for _, l in ipairs(out) do log("INFO " .. l); player:SendBroadcastMessage(BT .. l) end
  elseif cmd == "shoot" and playing then                    -- v1.0.1: the script fires the basic shot from your mecha at the demon
    local m = g.members[player:GetGUIDLow()]
    local c, b = m and mechOf(g, m), bossOf(g)
    if c and b then
      local before = b:GetHealth()
      try(c, "CastSpell", b, S.SHOT, arg == "t")
      local guid = player:GetGUID()
      later(guid, 1500, function(p)
        local b2 = bossOf(g)
        local msg = string.format("shoot (%s): demon health %s -> %s", arg == "t" and "triggered" or "normal cast", tostring(before), tostring(b2 and b2:GetHealth()))
        log("INFO " .. msg); p:SendBroadcastMessage(BT .. msg)
      end)
    end
  elseif cmd == "snd" then                                   -- v1.45 TEST ONLY (GM): try the ways of playing the fight track by ear, without a fight: #br snd sound | music | intro | stop
    if arg == "music" then pcall(player.PlayMusic, player, BR.MUSIC_FIGHT, player)       -- the fight track on the music channel
    elseif arg == "intro" then pcall(player.PlayMusic, player, BR.MUSIC_INTRO, player)   -- the intro on the music channel
    else arg = "stop"; pcall(player.PlayMusic, player, 0, player) end                    -- music 0. v1.49: 'sound' and 'obj' are GONE: both left the fight track playing until log-off
    player:SendBroadcastMessage(BT .. "Sound test: " .. arg .. ".")
  elseif cmd == "floor" and playing then
    if not g.floorAt then floorWarn(g, now()) end
  elseif cmd == "ring" and playing then
    local m = g.members[player:GetGUIDLow()]
    g.shocks[#g.shocks + 1] = { x = player:GetX(), y = player:GetY(), t0 = now() + BR.SHOCK_WARN, hit = {} }
  elseif cmd == "fx" and tonumber(arg) and g then           -- look at a spell effect: a marker 8 yd in front of you wears it for 12 s
    local o = player:GetO()
    local c = helper(g, E.ZONE, player:GetX() + 8 * math.cos(o), player:GetY() + 8 * math.sin(o), BR.CENTER[3] + 0.1, 12000, tonumber(arg))
    if c then try(c, "CastSpell", c, tonumber(arg), true) end
    player:SendBroadcastMessage(BT .. "Effect " .. arg .. " for 12 s, 8 yd in front of you.")
  elseif cmd == "portal" and tonumber(arg) and g then      -- v1.4: try the portal size: a portal 20 yd in front of you for 15 s
    local o = player:GetO()
    local c = helper(g, E.ZONE, player:GetX() + 20 * math.cos(o), player:GetY() + 20 * math.sin(o), BR.CENTER[3] + 0.1, 15000)
    if c then try(c, "SetDisplayId", BR.PORTAL_DISPLAY); try(c, "SetScale", tonumber(arg)); try(c, "SetFacingToObject", player) end
    player:SendBroadcastMessage(BT .. "Portal at scale " .. arg .. " (model 21.5 yd tall at 1). Set PORTAL_SCALE in the script when it looks right.")
  elseif cmd == "smash" and playing then                   -- v1.4: destroy every standing Fel Pillar (tests the green floor + crash)
    for _, p in ipairs(g.pillars) do local c = obj(g, p.guid); if c then try(player, "Kill", c, false); if (c:GetHealth() or 0) > 0 then try(c, "SetHealth", 0) end end end
  elseif cmd == "slide" and g then                          -- v1.6: '#br slide pose' / '#br slide step' picks the way; it then slides 20 yd toward you
    if arg == "aura" or arg == "pose" or arg == "step" or arg == "glide" or arg == "jump" or arg == "hover" or arg == "kit" or arg == "lead" or arg == "late" or arg == "jumpa" or arg == "leadjump" then BR.SLIDE_MODE = arg end   -- default v1.21: step
    local b = bossOf(g)
    if b then
      local d = dist2(b:GetX(), b:GetY(), player:GetX(), player:GetY())
      local f = math.max(0, (d - 20) / math.max(1, d))
      slideBoss(g, b:GetX() + (player:GetX() - b:GetX()) * (1 - f) * 0.6, b:GetY() + (player:GetY() - b:GetY()) * (1 - f) * 0.6, 2000)
      later(player:GetGUID(), 2300, function() local c = bossOf(g); if c then try(c, "RemoveAura", S.EMOTE51); try(c, "EmoteState", 0); rockets(c, false); try(c, "NearTeleport", c:GetX(), c:GetY(), BR.CENTER[3] + 0.1, c:GetO()); if g.state == "playing" then try(c, "SetRooted", true) end end end)
    end
    player:SendBroadcastMessage(BT .. "Slide mode: " .. BR.SLIDE_MODE .. " (stays until .reload ale; try: leadjump, jumpa, lead, late; aura = one smooth move in the slide pose, hover = on its rockets, jump = flat jump, glide = moved with gravity off, pose = normal move holding the slide pose, step = small hops).")
  elseif (cmd == "lift" or cmd == "pscale") and tonumber(arg) then   -- v1.25: set the portal by eye: redrawn at once, stays 2 minutes
    if cmd == "lift" then BR.PORTAL_LIFT = tonumber(arg) else BR.PORTAL_SCALE = tonumber(arg) end
    if g and g.portX then g.felPortal = true; g.portalAt = g.portalAt or now(); drawFelPortal(g, now(), 120000) end
    local line = string.format("Portal: scale %s, lift %s yd%s", tostring(BR.PORTAL_SCALE), tostring(BR.PORTAL_LIFT), (g and g.portX) and " (redrawn, stays 2 minutes)" or " (from the next lobby)")
    log(line); player:SendBroadcastMessage(BT .. line)
  elseif cmd == "rain" and playing then
    felShot(g, now(), player:GetX(), player:GetY())
  elseif cmd == "pillar" and playing then
    g.nextPillar = now()
  elseif cmd == "vortex" and playing then
    g.nextVortex = now()
  else
    player:SendBroadcastMessage(BT .. "GM: #br start | info | shoot | shoot t | time <s> | hp <percent> | kill | scale <x> | pillar | smash | slide [pose|step] | rain | portal <scale> | floor | ring | fx <spell> | vortex | snd music/intro/stop     Everyone: #ready, #leave")
  end
  return false
end)

log("script loaded v1.54 (Rikky " .. E.RIKKY .. ", map " .. BR.MAP .. ", " .. mmss(BR.GAME_TIME) .. " fight, scales 1-5 players + bot guns)")
