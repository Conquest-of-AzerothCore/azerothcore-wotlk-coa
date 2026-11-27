-- v1.6t (2026-11-19 21:42 real clock; Rowan 21:40 after his v1.6s run: 'That was awesome! One small problem though. The crystals dont disappear
--   the moment of the explosion after i collect those. The stick around for a second or two. If that cant be fixed then leave it. I dont want
--   anything messed up in the process.').  ONE change, nothing else touched: the crystal was already despawned the instant it is collected, but
--   the game client fades a removed creature out over about a second. So at pick-up the crystal is first swapped to the invisible model (11686)
--   and shrunk (both show at once on the client), and is removed 400 ms later. CRYSTAL_HIDE = false gives exactly the v1.6s behaviour back.
--   UNTESTED in game. Server log of his v1.6s run: 'halo visual sent = true' (the Halo ring by packet works, HALO_CAST not needed).
-- v1.6s (2026-11-19 21:26 real clock; Rowan 21:23: 'I believe the spell is from the holy priest called halo').  He is right as far as the client
--   data goes: SPELLS\priest_halo_cast.m2 (the holy Halo ring that grows out to 30 yd = the 60-yd golden disc of frames 275, 372, 461) is
--   SpellVisualKit 21884 (visual 21991). The only spells that carry it are class spells with real effects ('Circle of Life' 271484 etc., which
--   trigger heal missiles), so the kit is played on its own: where a +5 crystal lands a helper is put 1.2 yd under the floor (the ring sits
--   1.7 yd over its origin) and 0.3 s later SMSG_PLAY_SPELL_VISUAL (0x1F3: unit + kit 21884) goes to every player in the game. UNTESTED.
--   If nothing shows: '#se set HALO_CAST true' makes the helper cast 271484 instead (the same ring for certain, plus that spell's heal on dwarfs
--   near it). v1.6q's fixed disc (256023) and v1.6r's spreading circles (256846; never loaded) are OFF: RING_SPELL 0, RIP_SPELL 0.
--   Nothing else changed. The pick-up burst 256022 stays (Rowan likes it).
-- v1.6r (2026-11-19 21:23 real clock; Rowan 21:20 on v1.6q, with the live picture at 4:22 again: 'The crystal explosion is not like live but I
--   like it. Makes it show more of how powerful the light is. One thing I would change though is the large crystal hitting the floor needs to
--   look like this picture. See the light aoe spreading out?' / 'Nevermind the arrows').
--   PICK-UP BURST 256022 from the dwarf: KEPT, Rowan likes it (not like live, his choice).
--   BIG CRYSTAL LANDING: the golden disc (256023, a fixed 26 yd) stays, and from it golden circles now SPREAD over the floor: 256846 'Holy Zone'
--     (11fx_holy_circle06, a sizeable flat golden circle, plain dummy aura) on seven helpers, radius 12 / 19 / 26 / 34 / 41 / 48 / 55 yd, one
--     every 0.3 s, each up for 0.6 s and then fading (the model's own 0.9-s birth and 0.8-s decay). The circle sits 0.4 yd over its helper per
--     unit of size, so each helper is put that far under the floor. UNTESTED look. RIP_SPELL 0 = off. Nothing else changed since v1.6q.
-- v1.6q (2026-11-19 21:13 real clock; Rowan 21:13 after running v1.6l once more: 'Yeah the black hole closes in and the music stops when the round
--   ends.').  Both are CONFIRMED as v1.6l had them, so v1.6m's and v1.6n's changes to them are taken back (he never loaded m, n, o or p):
--   THE DARK OUTSIDE as v1.6l: RIM_IN 0.65, 45 s in, 5 s there, 10 s out, 10 s rest; harmless (RIM_CATCH false; the catch code stays, off).
--   MUSIC as v1.6l: the plain stop (PlayMusic 0) at the end of a round and when the game closes - IT WORKS for 215023 on this client (the Bullet
--     Romper note that a stop does nothing does not hold here). No jingles. Kept from v1.6m: the same plain stop when a player leaves.
--   Still new since v1.6l, UNTESTED: the pick-up burst (256022 from the dwarf, v1.6o) and the golden floor disc where a +5 crystal lands
--   (256023, v1.6p).
-- v1.6p (2026-11-19 21:09 real clock; Rowan 21:07: 'Also missing the light burst floor animation as seen in the 1k frames which i know you seen
--   without finishing the scan.').  Seen in frames 274-275, 287, 324, 369-375, 383, 452-454, 460-461, 484, 488: a pale golden disc ~25 yd wide
--   with a bright rippled rim under a crystal that has just landed, spreading over the floor. Its centre is a big ribbon-wrapped crystal that
--   has just come down (453-454), and the recorder's own +5 pick-ups do not throw one (281, 289, 316) = it belongs to the LANDING OF A BIG
--   (+5) CRYSTAL. Data: 256023 'Visual: Holy Zone' = 11fx_holy_circle04 x2 (a flat golden circle 26 yd across, 0.9 s birth / 0.8 s decay) +
--   8fx_nzothmental_mindgateportal_state x3; it sits between 256022 (the holy impact) and 256025 'Void Hitted Aura'. A helper gets it where a
--   +5 crystal lands, for RING_MS 2.5 s. UNTESTED look. RING_SPELL 0 = off.
--   The landing flash of every crystal (v1.6o) is OFF by default again (BURST_LAND false): 256022 also carries a flamestrike ground burst and a
--   tall light pillar, too much to put on every landing before Rowan has seen it once at a pick-up. '#se set BURST_LAND true' turns it on.
-- v1.6o (2026-11-19 21:08 real clock; Rowan 21:05 on v1.6l: 'so everything from that last run is perfect. Except the crystals which still do not
--   burst in light.').  CONFIRMED by that sentence, do not change: the circles following, the purple fog cone + ground lightning (255632 /
--   255631, CONES 3), the caught vortex, the dark outside closing in, the void music playing.
--   PICK-UP BURST, third attempt: v1.6l's two ways (the crystal really died - the log says so - and the aura look put on and off) showed him
--     nothing, so the burst is not the crystal model. Found in the same spell cluster as the orb look (256068) and 'Shadow Impact' (256105):
--     256022 'Stomp' = 11fx_holy_impact01 x2 as a world effect at its caster, a plain dummy spell (it sits beside 256025 'Void Hitted Aura').
--     NOT 256104 'Holy Impact' (the same model x3): that one does damage and leaves a damage area. The dwarf casts 256022 on himself with the
--     score pop (live frame 455: the starburst sits at the dwarf's feet), and a crystal casts it when it lands (live frames 267, 373-374).
--     BURST_SPELL 0 = none, BURST_LAND false = not at landing. v1.6l's two attempts are off (CRYSTAL_BURST 0). UNTESTED.
--   Carried from v1.6m / v1.6n (not yet loaded by Rowan): the dark comes in to r ~37 and catches 3 yd out in it (RIM_CATCH), and the music is cut by
--   the 7-s game-over jingle at the end of a round and by the Faire music on leaving.
-- v1.6n (2026-11-19 21:05 real clock; Rowan 21:00: 'The music should stop at rounds end and when leaving the course.' - after his test of v1.6l,
--   where the void music played on).  WHY IT PLAYED ON: the track is 325 s long (longer than a round), and a stop (PlayMusic 0) does nothing on
--   this client (measured for Bullet Romper v1.47). What does cut a track is the next track (same measurement: the fight track replaced the
--   intro at once). So: at the end of a lost round the Faire's own 7-s game-over jingle goes out (214897 mini_game_duck_gameover), 214898 (2.8 s)
--   after a survived round, and the Faire's zone music 214184 Azzar_Music_01 when a player leaves (#leave, Snagg, the portal, dropping off the
--   map) or the game closes. The Shadow Eye area has no zone music of its own, so after the jingle it is quiet. THE JINGLES ARE NOT FROM THE LIVE
--   FOOTAGE (its sound was not checked); MUSIC_END_ID / MUSIC_WIN_ID / MUSIC_LEAVE_ID can be set to any client sound.
--   Server log from Rowan's v1.6l test: 'crystal burst: mode 3, crystal died = true' and 'Void Consumption cast started = true'.
-- v1.6m (2026-11-19 21:02 real clock; Rowan 21:00 with a live picture at 4:22 on the round clock, an arrow from the blue rim to the pit's black).
--   THE DARK OUTSIDE: 'The black hole as close as it gets which limits players movements.' In his picture (38 s into the round) the lit corridor
--     between the blue rim and the black round the pit is ~17 yd wide = the rim at r ~37. RIM_IN 0.65 -> 0.60, closest after 35 s (RIM_CLOSE),
--     10 s there, 10 s back out, 5 s rest, again (the times other than 'closest by 38 s' are guesses). NEW, CLAUDE'S READING of 'limits players
--     movements': a dwarf more than 3 yd out in the black is caught (RIM_CATCH; rim taken as r 56 at rest, RIM_R0). RIM_CATCH false = harmless.
--   MUSIC: 'The music should stop at rounds end and when leaving the course.' The stop went out at the end of a round and when the game closes
--     (v1.6l); now also the moment a player leaves (#leave, Snagg, the portal).
-- v1.6l (2026-11-19 20:55 real clock; Rowan 20:40-20:42 after his test of v1.6k, with ten live pictures).
--   CONFIRMED by Rowan, do not change: 'The orbs are great. The puddles are great. The area surrounding the eye is great.' (orbs wandering each on
--     its own; puddles 255633 one by one from under the eyeball; black floor 256827 x16 with no trunks round the eye).
--   SWIRL CIRCLES: 'So I was wrong about these not following a player. They do. Watched the video again and it was following a player.'
--     POOL_CHASE true again (v1.6i: a circle slides after every marked dwarf, stops, the eyeball throws at it).
--   PURPLE FOG + GROUND LIGHTNING: 'The ground lightning and cracking is not there anymore and neither is the purple fog aoe.' Data, same spell
--     block as the rest of the game: 255632 'Visual: Void Cone' (4 s, Malkorok_ArcingSmash_Precast) and 255631 'Tentacle Hit'
--     (Malkorok_ArcingSmash_Impact). Live timing (frames 463-467, 505-512, clock on screen): mark, fog 2-3 s later, lightning ~5 s after the mark,
--     gone at 7 s; the lightning catches whoever stands in it (330-331, 412-413). CONES 3 per mark from the middle outward, one of them toward a
--     runner; cone 2 s after the mark, the hit 2.8 s later, it catches inside the wedge (8 degrees either side, r 14-62). LOOK AND SIZE UNTESTED.
--     CONES 0 = off.
--   PICK-UP BURST: 'The crystals do not burst when i collect them.' The score pop is only the number (one flat texture, no particles). The crystal
--     model itself has a 0.9-s birth and a 1.3-s death with a flash mesh and 10 particle emitters; live shows the same burst when a crystal
--     lands and when it is taken. Two attempts at once (CRYSTAL_BURST 3): 1 = the crystal is really killed and stays 1.5 s for its death burst
--     (v1.6c-f tried this through DealDamage without checking that it died; now the server log says whether it died); 2 = the live
--     'Holy Crystal: Visual' aura 257213 put on a helper at the spot and taken off 0.35 s later (birth + death of the same model as a spell
--     effect). '#se set CRYSTAL_BURST 1' or 2 shows them apart, 0 = none. UNTESTED.
--   CAUGHT LOOK: Rowan did not see the blue and pink vortex. It is the PRECAST kit of the 30-s Void Consumption cast (257219), so it only shows
--     while the dwarf really casts. The spell is flagged castable while stunned and Vehicle Stun is a stun-mechanic aura, so the cast should
--     start. The log now says once per game whether it did ('Void Consumption cast started = ...'). Nothing else changed there.
--   THE DARK OUTSIDE: 'The area of black is suppose to come closer and closer to the center and then retract back after a time period.' The dark
--     outer ring (256005, 8fx_discboss_surgingdarkness_farring, sizeable) is on its own helper now and is sized down and up again during a round:
--     45 s in to RIM_IN 0.65 (blue rim from r ~54 to ~39), 5 s there, 10 s back out, 10 s rest, again. THE NUMBERS ARE GUESSES; harmless.
--     RIM_MOVE false = as before.
--   MUSIC: 'there is no music playing during the course.' Client sound 215023 azzar_faire_void_music, sent with Player:PlayMusic at GO (as the
--     Rainbow Race theme), stop sent at the end of a round and when the game closes (the stop is not known to work). MUSIC false = off.
-- v1.6k (2026-11-19 19:20 real clock; Rowan 19:13-19:18: three pictures from v1.6i, then his first look at v1.6j after a reload).
--   SWIRL CIRCLES: Rowan (circled the lilac disc at his dwarf's heels): 'this keeps following me which is not suppose to happen', and it followed
--     his own character out of the vehicle too. That was v1.6i's POOL_CHASE (a circle sliding after every marked dwarf). OFF. The circles are back
--     as rows of 3-5 the eyeball throws at (as he saw them up to v1.6f), now on the moving helper: each wanders at random, 9 yd at a time, 3 yd/s.
--     POOL_SEEK false: they are no longer placed in front of a runner and never head for one. (13:53: 'void waves are still stationary and dont
--     move around at random. Those are the ones the eyeball fires at.')
--   TRUNKS ROUND THE EYE: Rowan: 'in live the tentacles dont exist that surround the eye unless you seen something different.' PIT_TENTS 3 -> 0
--     (they were v1.6's addition from the frames, never confirmed by him; in his v1.6j picture one stands in front of the eyeball). The frames DO
--     show two thick trunks rising out of the lava (456, 458, 505, 507): sent to Rowan to judge. '#se set PIT_TENTS 2' brings two back.
--   GROUND ROUND THE EYEBALL: Rowan (live picture, circled): 'a black fluid like environment surrounding the eye. The version on the server does
--     not have that' / 'You are also missing the ground effects that surround the eyeball.' Data: the pit spell 255629 carries them -
--     8fx_nzothraid_raden_unstablevoid_area x8 hung 18.2 yd UNDER its helper and a void barrier 17 yd under; with the helper at 12 (Rowan's
--     eyeball height) both lie 5-6 yd under the floor. NEW, UNTESTED: the same black model alone (256827 'Void Zone', sized x16 = the same x8)
--     on its own helper on the floor (SKIRT_SCALE 16), so the eyeball stays at 12. '#se skirt <size>' / '#se skirt off'. The other way to see
--     the live pieces: '#se pit 18.2' (eyeball 6 yd higher, both pieces at floor level).
--   Everything else as v1.6j (eyeball 12, orbs each on their own, puddles one by one from under the eyeball, pick-up burst from the dwarf).
-- v1.6j (2026-11-19 18:20 real clock; Rowan's look at v1.6i in game, 18:13-18:17, four points, + pass 5 frames 192-458).
--   EYEBALL: Rowan: 'Eye ball is too low. I used #se pit 12 and that is the correct height.' PIT_Z 1 -> 12 (v1.6g had laid it on the floor).
--   ORBS: Rowan: 'The orbs are exactly how they are suppose to be' (look 256068 = CONFIRMED) but 'they are in a line moving together not fluidly
--     what they need to be doing is moving individually in random directions more fluently'. ORB_WANDER true: every orb has its own speed
--     (1.5-3 yd/s) and glides leg after leg on its own heading (a new leg before the old one ends, so it never stops; it curves, max ORB_TURN per
--     leg), anywhere from the pit (r 10) to just outside the rim (r 60). They still APPEAR in straight lines at GO (live frames 267-271, 446, 448)
--     and leave them at once, each its own way. ORB_SCATTER true = they appear scattered instead. ORB_WANDER false = v1.6i's turning lines.
--   PUDDLES (black and cyan): Rowan: 'The puddles move individually from the center of the map where the eyeball is, but currently in the game
--     they're all moving in the same direction at the same time which makes them look like one big line of puddles.' The line he saw was v1.6i's
--     FOG BANDS, built from 255633, which is named 'Visual: Void Wave' and IS the puddle look. Fog bands OFF (FOG_BANDS 0). The puddles now use
--     255633 (VW_SPELL; VW_SCALE 1), one at a time from under the eyeball (VW_FROM 4) straight out to the wall, slowly (VW_SPEED 3), each on its
--     own random bearing at least 45 degrees off the two before it, one every 2.6-4 s, the first 10 s into a round. No more aiming at runners.
--     The fog's real look is still unknown (#se gallery cloud); the lightning that follows it catches on live (frames 330-331, 412-413): not built.
--   PICK-UP: Rowan: 'Crystals do not do a light burst when collected.' The pop (255647 / 257231) sizes itself by its caster (0.01-100x) and the
--     crystal is an invisible stub helper. Now the DWARF casts it on himself (as the duck and the race kart do) and the crystal goes at once.
--   END OF ROUND: live puts every player on the lobby spot with the 'Round n is complete' line (frames 245, 350, 429). LOBBY_GATHER true.
--   Not changed: the Eye's own helper (255657, EYE_ROAM 5) - Rowan has not said whether the eyeball moves. Everything else as v1.6i.
-- v1.6i (2026-11-19 14:26 real clock; pass 5 frames 116-171 = the first 50 s of round 2, ten of them without the interface and from above, plus a
--   still-camera composite of 903-909 s; log faire-cache\shadow-eye-live-1000\PASS5-FRAME-LOG-2026-11-19.md). From frames unless it says UNTESTED.
--   ORBS: they stand in STRAIGHT LINES from the rim of the pit outward (4 to a line in round 1, 5 in round 2, ~9 yd apart, the outermost beyond the
--     blue rim) and the lines are still straight 40 s into a round, while each orb slides sideways along a circle round the pit: the lines turn
--     like clock hands. Now SPOKES 3 lines, SPOKE_TURN 0.04 rad/s (inner orb ~1 yd/s, outer ~2.5). The number of lines and the turning speed are
--     my estimate. v1.6g's lines stood for a few seconds and then every orb crept off on its own: wrong.
--   SWIRL CIRCLES: while the mark is up, a blue circle slides after each marked dwarf from behind, stops after ~1 s, the Eye's dart comes down on
--     it and it stays as a lilac circle; the stopped ones lie behind him as a trail, 5-6 at a time. Rowan: 'moving around ... make the player get
--     shot up in the air. Those are the ones the eyeball fires at.' POOL_CHASE true replaces v1.6g's wandering clusters.
--     NOT built: the dart that stays standing in the circle (its model only comes inside spells with a 17-yd disc).
--   FOG: 2 s after each mark, 3 bands of violet fog from the pit to the rim for 4.5 s (live 2-4 bands, ~45 x 12 yd). Harmless (live 141, 163).
--     Its look is 255633 'Visual: Void Wave' from the game's own spell block, a line of puffs: UNTESTED, it may be too small or not show.
--     #se gallery cloud compares 255633 / 255533 / 255548. FOG_BANDS 0 = off. The lightning web that ends it is not built.
--   TRUNKS AT THE PIT: live has them standing INSIDE the crater, in the lava (154, 156). PIT_R 21 -> 9, three of them.
--   THE PORTAL is still there at '5' on live (116): it goes at '3' now.
-- v1.6h (2026-11-19 14:17 real clock; pass 5 through the live frames, 001-115 = all of round 1 and both lobbies, every frame whole at full size:
--   faire-cache\shadow-eye-live-1000\PASS5-FRAME-LOG-2026-11-19.md). Everything here is from frames unless it says UNTESTED / ours.
--   START SLOTS: at the '5' of the countdown the players still stand bunched; by '3' each dwarf stands alone on one ring round the pit, evenly spaced
--     (measured on the live minimap in 018 / 020: 72, 70, 74, 71, 72 degrees between five players). Now: at '4' everybody is put on his own slot
--     (START_R 44, 360 / n degrees apart, facing the pit) and becomes the dwarf there. The swirl at '5' is Vehicle Stun's own end effect (START_SWIRL).
--   A CAUGHT DWARF: live shows blue-white spikes round his feet and light rays from the moment he is caught = Vehicle Stun 257214 (its model is the
--     soulstone base). It is on again under the Void Consumption cast (the cast is flagged usable while stunned), which also brings the stun pose
--     back (Rowan: 'The dwarf stun animation does not work anymore when hit'). A revive takes it off = the rainbow swirl round the revived dwarf (038).
--   THE END OF A ROUND, timed from the frames (091-105): the last runner is caught = the floor is cleared and everybody is on foot at once, where he
--     stood; 'Game Over.' 2.5 s later; the points and scores 8.5 s after; 'Round n is complete. Round n+1 is now available!' at 13.5 s, and then
--     Snagg is back. The portal is back as soon as the round is over.
--   READY CHECK: 'Every player must be ready before the round can start.' is plain yellow without 'Azzar Event:' and only comes when somebody readies
--     while others have not (006, 014, 112). No 'x is ready' line (live shows the green tick only). No 'Run!' text at GO.
--   THE PUDDLE (Rowan's 'little moving blue and black puddles'): its model is fx_darkmissile inside 257572, flat, 11 x 5-9 yd, black with cyan streaks
--     = the live puddle. 257572 hangs it 9 yd above its helper, so v1.6c-g showed it in the air. Now the helper is tiny (VW_SCALE 0.02), which should
--     bring it down to the floor. UNTESTED: #se gallery wave shows three ways side by side. One every 3 s, 5 yd/s (live 074-079), from r 20.
--   STILL OURS, not live: the two [VOID] hint lines, the auto-start after 20 s from round 2 on, the self-revive when you play alone.
-- v1.6g (2026-11-19 14:07 real clock; Rowan's look at v1.6f in game + pass 5 through the live frames, every frame whole at full size, 001-076 so far:
--   faire-cache\shadow-eye-live-1000\PASS5-FRAME-LOG-2026-11-19.md). What is frame-backed and what is a guess is said per line.
--   Rowan: 'Crystalls are still not placed at random and there is no burst of light when collected'. CRYSTALS come down ONE BY ONE at random spots
--     (no rows); none before the '2' of the countdown (live 016-020), then they keep falling during the round. The '+1' / '+5' pop is now cast by
--     the crystal itself (the way the duck and the race coin do it, which work); the crystal is hidden and removed 1.5 s later.
--   Rowan: 'the orbs still do not look like this screesnhot'. ORB look 256068 'Visual: Void' instead of 256103 (fuzzy blob + DASHED ring): a 2.3-yd
--     dark ball with flat wisps at floor level + ONE thin SOLID dark-blue ring 7.4 yd across (live: ball ~2.2, ring ~3x). From the game's own
--     spell block (256024-256068, next to Void Hitted Aura). Model sizes read from the client; NOT yet seen in game. #se orbspell <id> / #se gallery orb.
--     They are born at GO in straight lines from the rim of the pit outward (live burst 19.5-22 s), then creep (2 yd/s) after 1.5-5 s.
--   Rowan: 'voide waves are still stationary and dont move around at random. Those are the ones the eyeball fires at.' The Eye's swirl circles are
--     on the un-rooted helper now and wander (3 yd/s, a new heading every 2.5-4 s, half the time toward a runner: live 063-074 a blue-centred
--     circle trails the marked dwarf); they launch where they ARE. The 5 extra wanderers of v1.6d are off (ROAM 0): live shows no circles at all
--     in the first 18 s of a round.
--   VOID METEOR MARK (new, from the frames + Spell.dbc): live has no standing arrow over the dwarfs. Every 20 s (first 18 s into the round) every
--     dwarf that is still running gets 257524 'Void Meteor' for 15 s = the purple debuff icon + the yellow chevron (its model is
--     arrow_state_animated). The Eye's circles only come while the mark is up.
--   Rowan: 'the eye is suppose to move around at random like its searching for players'. Live burst 16-18.3 s (camera still): it drifts 3-4 yd
--     sideways and up within 1.5 s. The Eye is on the un-rooted helper, flying, and moves to a new spot within 5 yd of the middle, 11-15 yd up,
--     every 2.5-4 s. UNTESTED: if it drops to the floor or stops showing, #se set EYE_ROAM 0 puts it back as it was.
--   Rowan: 'the faire portal is still active during the course'. The portal goes when the countdown starts and is back in the lobby.
--   Rowan: 'What is this suppose to be?' (a 10-yd blue-rimmed disc with shards): that was v1.6d's guess at the purple cloud (256827 x7). OFF
--     (CLOUD_EVERY 0) until the real fog bank is found. Live: a violet fog bank ~25-30 yd beside the pit for ~4 s that ends in a web of lightning,
--     ~6 s after each mark goes up (062-067).
--   THE PIT: Rowan's v1.6a pictures show the red iris lying FLAT at its helper's height (12 yd up = hanging in the air). PIT_Z 1 = on the floor,
--     and it comes at '5' with the Eye (VOID_AT 5; live: a dark mass rises at 5). Live from the track is a low black jagged mound with flames
--     (burst 16-19 s): the flat iris will not give the mound. Still open. #se pit <height> / #se pit off.
-- v1.6f (2026-11-19 13:14 real clock, Rowan: 'Look again.' + a live picture at 0:39: orbs standing far off, dark blades apart from them).
--   Looked again at live 039-044, 073-084 and 946-953 (camera nearly still) and 265 / 268 / 795 / 797 (round start), sheets pass4\R1-R4:
--   ORBS: none at 265, then an evenly spaced ARC of them on the edge of the pit at 268 (six in view); with a still camera one orb creeps
--     ~1.5 yd/s (947-949). So: they start as an even ring on the pit edge and creep at random again (DRIFT_RING, DRIFT_CREEP true, 1.5 yd/s).
--     v1.6c was wrong to stop them.
--   CREATURE: separate from the orbs; each one runs in a straight line away from the pit (074-077, 080-084, 946-948), ~3-5 yd/s. VW_SPEED 4.
--   GM: #se gallery orb | wave | cloud = the candidate looks side by side in front of you for 60 s (left to right, the legend comes in
--     chat, a yellow arrow marks number 1), so one screenshot settles a look.
-- v1.6e (2026-11-19 13:10 real clock, Rowan: 'No the orbs and the creature are not one thing.'): v1.6d wrongly merged them. Separate again:
--   ORBS stand on the track as before v1.6d (DRIFT 9, rows + scattered, they do not creep), look 256103.
--   The black-and-blue CREATURE ('moves like a slime') is its own thing: it comes from the Eye and glides to the tent wall (the Void Wave
--     helper with 257572 only; VW_ORB false, no row on the pit rim: VW_START 0), one every ~2 s, 3 yd/s.
-- v1.6d (2026-11-19 12:54 real clock, Rowan's third round of notes with 6 live pictures; the server still ran v1.6a):
--   'the void wave as its called [our purple swirl circles carry that name], needs to be moving around randomly and make the player get shot
--     up in the air': ROAM 5 swirl circles wander over the track (2 yd/s, a new heading every 4-6 s) and launch whoever touches one, like
--     the circles the Eye's projectiles leave (those stay). One launch routine for both; if the launch does not lift the dwarf try
--     #se set LAUNCH_JUMP true (a server-side jump instead of the knock-up spell 33673).
--   'The dwarf stun animation does not work anymore when hit': the eliminated dwarf gets the stun emote state (64) again; a real stun would
--     break the Void Consumption cast, which is why v1.3 dropped it.
--   'The light crystals need to come down from the cieling during the countdown ... and not be there before the countdown': nothing is put
--     on the floor before the count; five groups fall in at each number 5-4-3-2-1.
--   'missing the purple cloud thing floor aoe that spawns at random': our cloud was a 7-yd patch. Now ONE bank, CLOUD_SCALE 7 (~25 yd,
--     256827 can be sized), every ~15-21 s. Whether 256827 is the live cloud is a GUESS; the lightning web at its end is not built.
--   'the black and blue creature moving ... like a slime' + his live pictures from above: every orb on live travels in a straight line from
--     the pit to the wall with a dark blade trailing it, and at the start of a round a row of them sits on the rim of the pit. So ALL orbs
--     are Void Waves now: 8 start on the rim, then one every ~1.5 s, 3 yd/s, ball + ring (256103) and blade (257572) on the same helper.
--     The standing orbs are off (DRIFT 0; #se set DRIFT 9 brings them back next round).
-- v1.6c (2026-11-19 12:47 real clock, Rowan's second look, v1.6a still loaded; his words and 5 pictures, 3 of them live):
--   'The crystals are suppose to disappear when a player collect those like whats in the screenshot' (live: a yellow starburst + '+1').
--     The crystal model has its own Death animation (1.3 s, 10 particle emitters); we despawned it at once, so nothing showed. Now the
--     crystal DIES when collected (DealDamage) and goes 1.4 s later (CRYSTAL_DIE_MS; 0 = the old instant despawn).
--   'The black aoe floor needs to be a bit wider' (his tooltip: Void Sky Visual): SKY_SCALE 1 -> 0.9. The dark outer ring (256005) can be
--     sized, so the blue rim comes in from ~53 to ~48 yd; the realm dome is locked and does not change. GM: #se sky <height> <size>.
--   'Snaggs is not suppose to be there when the course starts': Snagg leaves when the countdown starts and is back for the next lobby.
--   'The little moving blue and black puddles need to come from the eye ball and move towards the tent wall' (live picture: a dark blade
--     with cyan streaks on the floor): VOID WAVES. Every ~2 s one starts at the rim of the pit and glides straight out to the wall at
--     5 yd/s; half of them head for where somebody is running; touching one eliminates (VW_R 2.2). Look: 257572 'Visual: Void Wave '
--     (a dark missile + the blue glow Rowan saw on our orbs), a GUESS. The orbs no longer creep (DRIFT_CREEP false): they stand.
--   CORRECTION to the v1.6b note: 256103 is NOT from a Shadow Eye spell block (that block is mostly Wonka Wonka and a void boss); it was
--     picked for its name and its ball + thin ring only.
-- v1.6b (2026-11-19 12:39 real clock, Rowan's first look at v1.6a in game, two screenshots: 'Crystals are the right models but they don't bunch up
--   like that. The dark orbs are wrong.'):
--   ORBS: ours showed a flat blue glow inside a 14-yd cracked dark disc. Two causes: the ring spell 256250 is locked at its own size (min = max = 1,
--     RING_SCALE never did anything) and has a cracked disc live does not have; and 257220 shows as a blue glow in the client, not a ball.
--     Live (Rowan's zoomed screenshot + frame 720): a black ball with star sparkles and a crisp blue-violet rim over ONE thin blue ring ~3.2x its width.
--     Now 256103 'Visual: Void Orb' = a 1.6-yd dark void ball + a thin dark-blue floor ring (~6 yd) in one spell, from the same spell block as
--     'Void Hitted Aura' and 'Ride Void Vehicle'. HOLE_RING 0 (256250 off), HOLE_Z 0.1 (the ring must lie on the floor; the ball has its own lift).
--     UNTESTED. Other look: #se orbspell 255515 (N'Zoth orb x2 + the same ring x0.8). Both can be looked at first with #se fx <spell>.
--   CRYSTALS: no more tight bunch (3-5 within 1-3.5 yd): that group is a loose scatter now (3.5-9 yd apart) and no crystal lands within
--     CRYSTAL_GAP 2.5 yd of another.
-- v1.6a (2026-11-19 12:50, after the full sweep of all 1000 live frames): PIT_Z 6 -> 12, nothing else. Reason: spell 255629 is three pieces, the flat
--   iris (a few yards under its helper) and two void pieces 17 and 18.2 yd under it with ragged 'eat-away' black edges, the likely source of the
--   black jagged mound. At 12 the iris hangs ~5 yd over the floor (live: the red band sits just over the black rim, under the upright Eye) and the
--   tops of the void pieces can show at floor level. Still a guess: try #se pit 6, #se pit 12 and #se pit 17.5 and tell Claude which is closest.
-- v1.6 (2026-11-19 midday, fourth pass through the live frames at FULL size while Rowan was out; notes shadow-eye-live-1000\PASS4-NOTES-2026-11-19.md).
--   UNTESTED IN GAME, like v1.5 (v1.5 was never loaded: v1.6 holds everything v1.5 changed).
--   COURSE TENTACLES: they are tall standing trunks (16 yd x 3 yd, the model cannot be sized or laid down; live 182, 460, 718 show the same trunks
--     standing on the track). They no longer come as 1-3 'lying' strips with a 7.5 x 1.3 yd hit strip (Rowan was caught where nothing stood, 0:56 of
--     his clip): one trunk rises ahead of a runner, sometimes a second a few yards off, and it catches whoever touches its BASE (TENT_R 2.2 yd)
--     from 1.5 s after it rises until it goes (TENT_HIT 0; a number = only that many ms).
--   PIT TENTACLES: live has tall trunks standing on the rim of the pit beside the Eye during a round (182, 718, 719) -> PIT_TENTS 4 at r 21,
--     they come and go with the Eye (not in the lobby).
--   THE PIT (a guess, say so): live = a ring of black jagged rock ~40 yd across with a red-orange glow inside that is dark in the middle
--     (363, 718, 719; from the track 019 / 020 / 264 / 444 it is a low black rim with a red glow over it, brighter left and right than in the
--     middle). That is what a huge iris lying flat looks like: spell 255629 (the piercing-gaze eye that hung in the sky in Rowan's v1.4 clip,
--     a 28-yd red veined iris with a black pupil and a ragged black edge) set DOWN on the floor, on the live helper 99525 'Void eye'.
--     The realm (255628) only gives the faint blue ring at the foot of the rocks (its inner rings are tinted dark blue, 30 % strength).
--     PIT_SPELL 255629, PIT_Z 6 (the helper's height; the iris hangs a few yards under it). GM: #se pit <height> [spell] | #se pit off.
-- v1.5 (2026-11-19 11:30, third pass through the live frames at full size + Rowan's zoomed orb screenshot; notes shadow-eye-live-1000\PASS3-NOTES-2026-11-19.md):
--   LOBBY: live has the dark sky, the red sparks and tall blue-edged tentacles round the arena from the moment you zone in and between rounds
--     (001-010, 110, 246-254); only the Eye and its pit come at '3' -> SKY_LOBBY (sky + rim + 14 standing tentacles from arrival), eyeOff() after a round.
--   EYE: live = an UPRIGHT black pupil in a red-orange iris with a blue-violet flame halo (018-020), ~6-7 yd / ~16 yd, its middle ~9-10 yd up.
--     That is the client's own Azzar_voideye model (spell 255657), which v1.2-v1.3b had; v1.4's 255629 eye lies flat and cannot be sized. Back to 255657.
--   ORB: live = a black ball with star sparkles and a blue rim (FX_EmbraceofNothingness_Precast) = spell 257220 'Void State' (x0.3, 1.2 yd) on a size-1
--     helper; v1.4's 257445 is a particle flame. Ring 256250 at 0.33 (~4.6 yd). Other look to try: #se orbspell 257572.
--   SpellVisualEffectName min / max scale IS a clamp: 255629's eye (1 / 1), the realm (0.45 / 0.45) and the 255652 tentacle (2 / 2) cannot be sized by
--     the helper; Azzar's own effects (0.01 / 100) can. So TENT_SCALE and WALL_SCALE do nothing: a tentacle is always ~16 yd tall and ~3 yd thick.
-- v1.4c (2026-11-19 10:50, Rowan's zoomed live screenshot of an orb: a black ball with stars in it and a thin blue-violet rim, floating about its own
--   radius over the floor, over ONE thin blue ring ~3.2x its width, no cracked ground, no flame): the ring helper is sized now (RING_SCALE 0.26), orb 0.2.
-- v1.4b (2026-11-19 10:40): GM command #se orbspell <spell> to compare orb looks in the arena (257445 ours, 255515 'Visual: Orb', 256245 'Void Beam').
-- v1.4a (2026-11-19 morning, from Rowan's first v1.4 test clip drop-in\shadow_eye_test.mp4): the orbs were ~7x too big (15-yd cracked circles with
--   blue fire; live = a 2-yd black orb in a thin blue ring) -> HOLE_SCALE 0.15; the Eye hung too high to see with a level camera -> EYE_AT 21 -> 16;
--   the void's black pit floor lay 0.3 yd under the tent floor -> SKY_Z 0.6. Tune: #se eye <size> [height], #se sky <height> [size], #se set HOLE_SCALE <n>.
-- azzar-shadow-eye.lua  v1.2  (Rowan/Claude 2026-11-14; v1.1 2026-11-16 from the second-by-second footage pass, UNTESTED)
-- v1.4 (2026-11-19, second pass over Rowan's 1000 live frames + the client data; notes faire-cache\shadow-eye-live-1000\PASS2-NOTES-2026-11-19.md):
--   THE VOID IS BUILT LIKE LIVE. The spells keep their models in SpellVisualKitModelAttach.dbc (the first pass only read the kit fields and
--   called them empty): Void Sky 255628 = N'Zoth's realm (dark dome, the pit with its rock ring and red fire, the tall tentacles round the
--   outside) and must stand at the centre AT FLOOR LEVEL (ours hung 30 yd up = Rowan's 'black void banner sits too high'); the second Void Sky
--   256005 = the dark ring from r 53 outwards with the blue rim; the Eye = 255629 (N'Zoth's orange eye) on a SMALL helper high over the pit
--   (255657 was a placeholder disc). Black orbs = the live look 257445; swirl pools = Void Meteors 255636 in a row of 3-5, thrown by the Eye,
--   and they launch you (no more deadly blast); tentacles = the live lying tentacle (size 0.25, they were 32-48 yd long) that comes down across
--   your path, 1-3 side by side, and stays lying; the 14 wall tentacles are gone (the realm has its own).
--   RULES LIKE LIVE: the 30 s 'Void Consumption' is the whole revive window and 'was not revived in time' is only a line after 10 s; revives
--   cost nothing and the reviver runs on with the golden trail too (alone: the one charge frees you); Game Over as soon as nobody is running;
--   the void comes at '3' of the countdown and goes at the end of the round, when you are back on foot at Snagg; score lines also mid-screen;
--   '[TIMER]' 3/2/1 minutes, 30s, 10s, 5s..0s; 500 tickets (live); the Azzar Faire Portal orb stands in the arena; live achievements.
--   Things that must MOVE (falling crystals, creeping orbs, the void wave) use the un-rooted helper 99519: our own helpers are rooted in the
--   database and never moved (the 'falling' crystals hung 22 yd up).
--   GM: #se sky <height> [size] | #se eye <size> [height] | #se eyespell <spell> | #se void (on/off between rounds, to look at it) |
--       #se set <SETTING> <value> (any number or true/false setting below, live).
-- v1.3b (Rowan 23:19, our arrival vs the live countdown): the Azzar void eye model is HUGE at its own size (a black mass with the eye
--   and tentacles filling the view): it now sits in the middle at 0.35 size (GM '#se eye <size> [height]' tunes it live) and the extra pit
--   tentacles are off (the model has its own). You arrive ON THE RING facing the pit (live), not in the middle; Snagg stands between you
--   and the pit, facing you.
-- v1.3a (Rowan 23:18 'Snagg is not in there with me'): Snagg stands in the arena with the players (live frame 997) and readies you up
--   by talking to him (the live parchment window = his gossip frame): 'I'm ready!' / 'Take me back to the Faire'. The void look (Eye,
--   pit + wall tentacles, sky) only exists DURING a round, as on live: between rounds it is the plain tent.
-- v1.3 (2026-11-18, Rowan's 1000-frame live game, notes faire-cache\shadow-eye-live-1000\SCAN-NOTES-2026-11-18.md): the course is a
--   RING round a central pit (nothing spawns inside r 24); the Eye hangs 18 yd up over the pit with tentacles rising round it; crystals
--   come in long rows that follow the curve of the track (50 at once); a dozen black orbs drift about; each throw leaves a dark object
--   lying on the track for 20 s and a cluster of 3-5 launch pools beside it; eliminated = 'Void Consumption' cast bar (257219, 30 s,
--   the tentacle vortex) and the revive window is those 30 s; out = the blue circle (257214); a harmless purple void cloud rolls over
--   the track now and then; '[TIMER] n minutes remaining!' lines and '[VOID] Victory!'.
-- v1.2e (Rowan 22:20, live close-ups): the purple swirl pools LAUNCH you into the air when you touch them (not eliminate): Shockwave
--   33673 (straight up, 25) on your archaeologist, 2 s between launches; their look = the purple vortex 64135 (what our v1.1 'black
--   holes' looked like) + the thrown void meteor lying in it (255600). The black orbs keep drifting at random and still catch you.
-- v1.2d (Rowan 22:17, live screenshot 'the eyeball throws objects that land on the floor'): the Void Meteor is THROWN by the Eye in
--   the middle (missile 255637 from the Eye to the spot) and leaves a dark void meteor lying in its purple pool (255600 = void zone
--   + 8fx_rl_meteor_state_void) instead of the pool alone.
-- v1.2c (Rowan 22:14-22:15, live screenshots): the black holes are BLACK ORBS (dark, starry, blue rim) floating over a blue circle on
--   the floor: orb model + floor circle that travel together; new crystals come DOWN onto the course from the sky with a light trail
--   (Holy Crystal: Visual State 257218) and count once landed. GM '#se look <display id>' shows any model to pick looks.
-- v1.2b (Rowan 22:11-22:13 + a live screenshot): the Eye sits in the CENTRE of the arena (over its fire ring), not at the wall; tall
--   tentacles stand round the tent wall; crystals are the holy crystal MODEL (display 141855, creature_demoncrystal_03_holy) instead of
--   an aura (the aura did not show); leftovers of an earlier game in the same instance (the old orbs: 'nobody left' cannot reach them)
--   are swept away when a game starts; crystals live one round, not an hour.
-- v1.2a (Rowan 22:06 'a lot of [the orbs] are out of bounds'): spawn radius 54 (reachable floor ends at 58.7 per the navmesh), crystals
--   in lines and clusters like live, the Eye nearer (72 yd).
-- v1.2 (2026-11-18, Rowan's first test video drop-in\shadow_eye.mp4 next to the live footage: 'It is definitely lacking a lot'):
--   the live HUD (world states: Combat Resurrection Charges Remaining / End of Game / Collected Crystals) instead of the mid-screen line;
--   Holy Crystal 257213 (the yellow shard) instead of Holy Orb; black holes also DRIFT about the floor all round (live: many, scattered);
--   the Void Meteor now falls (255637 from 25 yd up) onto a Void Meteors zone (255636); void tentacle 255652 and the Azzar void eye 255657
--   (255630 / 255629 have no model in our client: nothing showed); Void Ambience Missiles (dark torrents) cross the arena.
--   NOT fixable in the script: the live arena is pitch black (Void Sky 255628 / 256005 have no model in our client).
-- v1.1 (faire-cache\shadow-eye-1s\SHADOW-EYE-1S-SCAN-2026-11-16.md): like live the game is now ROUNDS (7) in the same arena with a ready
--   check before each ('Every player must be ready before the round can start'): say #ready. Nobody is seated while their client is
--   still loading (the Rainbow Race freeze): you arrive on foot and only become the dwarf once everyone is ready. Live wording for
--   eliminated / not revived / Game Over / Void Event Points / Final scores / 'Round N is complete. Round N+1 is now available!'.
--   Live auras: eliminated = Void Hitted Aura 256025 + Vehicle Stun 257214, revived = Sanctified Aegis 257216 (6 s safe), yellow arrow
--   255649 over every dwarf, Score +1 / +5 pops (255647 / 257231), the client's big countdown (packet 0x588, as in the Rainbow Race).
--   New dangers: the meteor leaves a void pool, rows of black holes cross the floor, tentacles come up near runners, the Eye hangs at
--   the edge. Revive window 10 s (footage), one charge per round. OURS, not live: alone, the charge frees you by itself after 3 s.
--   GM: #se fx <spell id> shows any visual on a marker in front of you (to pick looks), #se round <n>.
-- SHADOW EYE mini-game for the Azzar Faire (map 960 'MiniGames', area 10070), host Snagg 371922 on Dawnrise (map 909).
-- Rules from Snagg's live text 1200148 + the footage ('All 7 Azzar Faire games' 23:00-37:00): a cooperative run. Everyone becomes a dwarven
--   archaeologist (live vehicle 99735 'Brann Bronzebeard') who can never stop running (live aura 255634 Automove), collects Light Crystals
--   (+1, big ones +5) and dodges what the Void throws. Caught = eliminated until a companion reaches you ('Revive them before they are
--   lost'). One survivor at the end of the clock is enough to complete the game.
-- v1.0 = crystals, void strikes with a warning zone, elimination + revive, clock, scores, rewards.
--        NOT in v1.0: tentacles, void waves/cones, the eye's gaze, several rounds with ready checks, hard mode.
-- ARENA (client files): tent WMO azzarfaire_tent_round_interioronly_void at 960 5961.1 -5232.8, flat round floor z 10.0, radius ~92 yd.
-- Commands (chat):  #ready, #leave = back to the Faire.   GM only:  #se start | #se time <seconds left> | #se fx <spell> | #se round <n>
-- Needs azzar-shadow-eye.sql. Snagg has NO spawn yet (Rowan's .gps pending): until then start with '#se start'.
local SE = {
  MAP = 960,
  CENTER = { 5961.1, -5232.8, 10.0 },
  FLOOR_R = 54,              -- v1.2a (Rowan: 'a lot of them are out of bounds'): the server's walking map (mmtile 9602041) says the floor
                             --   you can reach ends 58.7 yd from the centre (the 92 was the tent model): crystals and dangers stay inside 54
  FAIRE_SPOT = { 909, -1795.9, -11999.1, 61.7, 0 },         -- fallback way home (by the game tents) for players with no saved spot
  MAX_PLAYERS = 5, JOIN_RANGE = 40,
  GAME_TIME = 300,           -- seconds (footage HUD: 'End of Game: 4:55')
  ARRIVE_WAIT = 3000, ARRIVE_MAX = 30000, COUNTDOWN = 5,
  ROUNDS = 7,                -- footage: 'Round 6 is complete. Round 7 is now available!', then the last scores
  LOBBY_AUTO = 20000,        -- from round 2 on a round starts by itself after 20 s (round 1 waits for every #ready: clients may still be loading)
  LOBBY_IDLE = 300000, ROUND_GAP = 13500, END_OVER = 2500, END_SCORES = 8500, END_GATHER = false, LOBBY_GATHER = true,   -- v1.6h: the live end of a round: floor cleared at once, "Game Over." 2.5 s later, the scores at 8.5 s, "Round n is complete" at 13.5 s; END_GATHER true = put everybody back on the arrival spot (old way)
  START_SPREAD = true, START_R = 44, START_SWIRL = true,    -- v1.6h: at the "4" of the countdown everybody is put on his own start slot on one ring, evenly spaced, facing the pit (live minimap 018-020)

  BIG_COUNTDOWN = true,      -- the client's own big numbers (packet 0x588)
  AUTOMOVE = true,           -- 'you can never stop running'
  SPEED = 1.3,
  CRYSTALS = 50, CRYSTAL_R = 3.5, BIG_CHANCE = 6, CRYSTAL_GAP = 5, CRYSTAL_DIE_MS = 1500, CRYSTAL_COUNT_AT = 2, CRYSTAL_START = 10, CRYSTAL_EVERY = 400,           -- on the floor at once; pick-up distance; one in six is worth 5
  STRIKE_EVERY = 7000, STRIKE_MIN = 3500,                   -- ms between void strikes at the start / at the end of the clock
  STRIKE_WARN = 2500, STRIKE_R = 5,                         -- warning time and blast radius
  REVIVE_R = 4, REVIVE_WINDOW = 30000, REVIVES = 1,         -- reach an eliminated companion within the window (footage: ~10 s); charges per ROUND
  SOLO_REVIVE = 3000,        -- OURS: playing alone, the charge frees you by itself after 3 s (nobody could reach you)
  AEGIS_MS = 5000,           -- Sanctified Aegis after a revive: nothing can catch you for 6 s
  POOL_LAUNCH = true, LAUNCH_CD = 2000, POOL_SPEED = 3, POOL_MOVE = 2500, POOL_STEP = 9,
  POOL_CHASE = true, POOL_SEEK = false, POOL_EVERY = 1300, POOL_BEHIND = 5, POOL_CHASE_MS = 1200, POOL_CHASE_SPEED = 10,   -- v1.6i: while the mark is up every running dwarf has a swirl circle chasing him: it starts behind him, follows for 1.2 s, stops, the Eye's dart lands on it, and it lies there for POOL_MS (false = v1.6g: clusters that wander)
  SPOKES = 3, SPOKE_N = 4, SPOKE_MAX = 6, SPOKE_R1 = 26, SPOKE_GAP = 9, SPOKE_TURN = 0.04,
  ORB_WANDER = true, ORB_SCATTER = false, ORB_SPEED_LO = 1.5, ORB_SPEED_HI = 3, ORB_LEG_LO = 4000, ORB_LEG_HI = 8000, ORB_TURN = 1.6, ORB_R_IN = 10, ORB_R_OUT = 60,   -- v1.6j (Rowan): every orb glides on its own, in its own direction
    -- v1.6i: the orbs stand in straight lines from the pit outward and the lines turn round the pit like clock hands (rad/s; 0.04 = one turn in ~2.5 min; SPOKES 0 = v1.6g behaviour)
  FOG_BANDS = 0, FOG_AFTER = 2000, FOG_MS = 4500, FOG_GAP = 6, FOG_SPELL = 255633,   -- v1.6i: violet fog in bands from the pit to the rim, 2 s after each mark (harmless; FOG_BANDS 0 = off). Look UNTESTED
    -- v1.6g: the swirl circles move about (POOL_SPEED 0 = they lie still)
  MARK_FIRST = 18000, MARK_EVERY = 20000, MARK_MS = 15000,   -- v1.6g: the live Void Meteor mark (257524, the chevron): 15 s every 20 s, first 18 s into a round; the Eye only fires while it is up (MARK_EVERY 0 = old way)
                      -- v1.2e: touching a pool launches you up (live); false = it catches you as before
  POOL_ROCK = true,                                         -- v1.2e: the thrown void meteor lies in the pool
  POOL_MS = 6000, POOL_R = 2.8, POOL_CLUSTER = 4, POOL_GAP = 4.5, OBJ_MS = 20000,   -- v1.3: pools come in clusters of 3-5; the thrown object lies 20 s
                               -- void pool left by a meteor (set POOL_MS = 0 to turn pools off)
  HOLE_EVERY = 0, HOLE_MIN = 7000, HOLE_COUNT = 5, HOLE_GAP = 7, HOLE_SPEED = 7, HOLE_TRAVEL = 70, HOLE_R = 2.3,   -- a row of black holes (HOLE_EVERY = 0: off)
  TENT_EVERY = 7000, TENT_MIN = 3500, TENT_ARM = 1500, TENT_LIFE = 20000, TENT_R = 2.2, TENT_N = 2, TENT_SPREAD = 9,                                -- tentacles (TENT_EVERY = 0: off)
  EYE_AT = { 0, 0, 12 }, EYE_ROAM = 5, EYE_Z_LO = 11, EYE_Z_HI = 15, EYE_SPEED = 2.5, EYE_EVERY = 2500,   -- v1.6g: the Eye wanders over the pit (EYE_ROAM 0 = it hangs still)
    -- v1.5: Azzar_voideye is centred on its helper; live: the middle of the Eye ~9-10 yd over the floor (frames 018-020)
  -- v1.4a note (piercing-gaze eye, gone):   -- v1.4a: was 21; Rowan's test 11-19: the Eye hung above the top of the screen. Its middle sits ~7 yd under this height.
  -- old note:      -- v1.3b: the model holds the pit, the fire and the eye up high itself
  EYE_SCALE = 0.15,          -- v1.3b: its own size fills the arena
  PIT_TENTS = 0, PIT_R = 9, PIT_SCALE = 1,                 -- v1.6: tall trunks on the rim of the pit beside the Eye, during a round only (live 182, 718, 719); 0 = off
  PIT_SPELL = 255629, PIT_Z = 12, SKIRT_SPELL = 256827, SKIRT_SCALE = 16,
  CONES = 3, CONE_AFTER = 2000, CONE_WARN = 2800, CONE_HIT_MS = 600, CONE_AT = 0, CONE_R0 = 14, CONE_LEN = 62, CONE_HALF = 0.14, CONE_SPELL = 255632, CONE_HIT = 255631,   -- v1.6l: purple fog cone, then the ground lightning that catches
  CRYSTAL_BURST = 0, BURST_MS = 350, BURST_SPELL = 256022, BURST_LAND = false, RING_SPELL = 0, RING_MS = 2500, RIP_SPELL = 0, RIP_S = { 2.5, 4, 5.5, 7, 8.5, 10, 11.5 }, RIP_STEP = 300, RIP_HOLD = 600, RIP_Z = 0.4,
  HALO_KIT = 21884, HALO_Z = -1.2, HALO_AFTER = 300, HALO_CAST = false, HALO_SPELL = 271484, CRYSTAL_HIDE = true, CRYSTAL_HIDE_DISPLAY = 11686, CRYSTAL_GONE_MS = 400,   -- v1.6s: the holy priest Halo ring where a +5 crystal lands   -- v1.6o: the holy impact (Stomp 256022) from the dwarf at pick-up and from the crystal when it lands;                       -- v1.6l: pick-up burst: 1 = the crystal dies, 2 = Holy Crystal look on and off at the spot, 3 = both, 0 = none
  RIM_MOVE = true, RIM_IN = 0.65, RIM_CLOSE = 45000, RIM_HOLD = 5000, RIM_OPEN = 10000, RIM_REST = 10000, RIM_CATCH = false, RIM_R0 = 56, RIM_MARGIN = 3,   -- v1.6l: the dark outside closes in and opens again (numbers are guesses)
  MUSIC = true, MUSIC_ID = 215023, MUSIC_END_ID = 0, MUSIC_WIN_ID = 0, MUSIC_LEAVE_ID = 0,                         -- v1.6l: azzar_faire_void_music during a round                           -- v1.6 UNTESTED: the pit = the piercing-gaze iris lying on the floor (helper 99525 at this height over the floor); PIT_SPELL 0 = no pit
       -- the Eye: offset from the centre (v1.2b, live screenshot: in the MIDDLE of the arena, over its fire ring)
  CENTER_FREE = 24,          -- v1.2b: no crystals or meteors inside this radius (the Eye's pit)
  SKY_LOBBY = true,          -- v1.5: the dark sky, the blue rim and the standing tentacles are there from the moment you zone in and between rounds (live 001-010, 110, 246-254); only the Eye comes with the round
  WALL_TENTS = 14, WALL_R = 60, WALL_SCALE = 1,           -- v1.2b: tentacles standing round the tent wall (live screenshot); 0 = off
  HOLE_DISPLAY = 0,     -- v1.2c: black orb model (FX_BlackHoleSun_Aura). Others to try with '#se look': 132285 FX_BlackHole_Aura,
                             --   129938 Summoner_BlackHole, 129158 Monk_HealthGlobe_BlackHole, 460254 argus_voidorb, 127213 priest void orb,
                             --   130547 discboss_voidcorruption_orb, 132345/132346/132349/132353 BlackHoleSun 02/01/04/05; 0 = old aura 64135
  RING_SCALE = 0.33,         -- v1.4c: the floor ring is on its own helper and was never sized (17 yd across at size 1); live = one thin blue ring ~3x the orb (Rowan's live screenshot 11-19)
  HOLE_Z = 0.1, HOLE_SCALE = 1,                             -- v1.2c: the orbs float above head height
  HOLE_RING = 0,             -- v1.6b: off (256250 is locked at 14 yd and has a cracked disc; the orb spell 256103 brings its own thin ring). Was 256250. v1.2c: the blue circle on the floor under each orb (Visual: Void Beam Zone = 11fx_voidcircle02); 0 = off
  FALL_H = 22, FALL_SPEED = 14,                             -- v1.2c: new crystals come down from 22 yd at 14 yd/s with a light trail
  ARRIVE_R = 38, ARRIVE_ANG = -math.pi / 2,                -- v1.3b: you arrive on the ring (r 38, south side) facing the pit
  SNAGG_R = 31,               -- v1.3a/b: Snagg between the players and the pit, facing them
  CONSUME = true,            -- v1.3: eliminated = the live 'Void Consumption' cast (bar + vortex); false = the old stun look
  CLOUD_EVERY = 0, CLOUD_MS = 9000, CLOUD_SCALE = 7, CLOUD_N = 1, CLOUD_ARC = 1.0,   -- v1.3: a harmless purple void cloud over a stretch of track (0 = off)
  VW_EVERY = 2600, VW_MIN = 1500, VW_JITTER = 1400, VW_APART = 0.8, VW_HOLD = 600, VW_FIRST = 10000, VW_SPEED = 3, VW_FROM = 4, VW_SCALE = 1, VW_TO = 62, VW_R = 2.2, VW_Z = 0.1, VW_SPELL = 255633, VW_ORB = false, VW_START = 0,   -- v1.6c: Void Waves from the Eye out to the wall (VW_EVERY 0 = off)
  ROAM = 0, ROAM_SPEED = 2, ROAM_EVERY = 4000, ROAM_STEP = 12, LAUNCH_JUMP = false, STUN_EMOTE = 64,   -- v1.6d: wandering swirl circles that launch you; the stun pose of an eliminated dwarf (0 = none)
  DRIFT_CREEP = true,        -- v1.6c: the orbs stand where they are (true = they creep about as in v1.4)
  TIMER_AT = { 180, 120, 60, 30, 10, 5, 4, 3, 2, 1, 0 },                          -- v1.3: '[TIMER] ... remaining!' lines
  CRYSTAL_DISPLAY = 141855,  -- v1.2b: the yellow holy crystal model (0 = the old aura look)
  HUD = true,                -- v1.2: the live HUD (world states; WorldStateUI.dbc 300 / 378 / 385, map 960)
  CHAT_BOARD = false,        -- v1.2: live has no minute line in chat (the HUD shows it); true = our old line each minute
  CENTER_SCORE = false,      -- v1.2: live has no '+1 (Collected Crystals: n)' line mid-screen, only the +1 / +5 pop
  DRIFT = 12, DRIFT_ROUND = 2, DRIFT_MAX = 20, DRIFT_SPEED = 2, DRIFT_RING = true, DRIFT_LINE = 4, DRIFT_EVERY = 7000, DRIFT_ROWS = 0.6,   -- v1.2: black holes drifting about all round (DRIFT = 0: off)
  FALL_Z = 25, FALL_MS = 600,                               -- v1.2: the Void Meteor falls from 25 yd (50 yd/s) and lands as the warning ends
  THROW_FROM_EYE = true, THROW_Z = 14,                      -- v1.2d: the Eye throws it (from 10 yd up in the middle); false = straight down
  ZONE_SCALE = 1.6, POOL_SCALE = 0.9,                       -- v1.2: the void zone model is small (x0.5): helper scale to match STRIKE_R / POOL_R
  AMB_EVERY = 2500,          -- v1.2: Void Ambience Missiles (dark umbral torrents) across the arena (0 = off)
  -- v1.4 (live pass 2)
  LATE_MSG = 10000,          -- 'was not revived in time and remains eliminated!' comes 10 s after the elimination; the revive window stays 30 s
  STRIKE_KILL = false,       -- live: the meteor zones launch you; true = the old deadly blast (STRIKE_R) as well
  TENT_SCALE = 0.25, TENT_LEN = 7.5, TENT_W = 1.3, TENT_GAP = 3, TENT_HIT = 0,   -- v1.6: the trunk catches at its base (TENT_R) as long as it stands (a number = only that many ms after it rises); TENT_SCALE / LEN / W / GAP are unused now
  SKY_Z = 0.6, SKY_SCALE = 0.9, SKY_RING = true,                -- the realm dome stands at floor level in the middle; SKY_RING = the dark outer ring with the blue rim (256005)
  EYE_SPELL = 255657,        -- v1.5: Azzar_voideye (upright red-orange iris with a black pupil + blue flame halo) = the live Eye after all; 255629 = the piercing-gaze eye of v1.4 (cannot be sized, lies flat)
  -- v1.4 note:        -- N'Zoth's eye (live); 255657 = the placeholder disc of v1.2-v1.3b
  VOID_AT = 5,               -- the void appears at this number of the countdown (live: 3)
  PORTAL_R = 49, PORTAL_ANG = -0.5,                         -- the Azzar Faire Portal orb: yards from the centre, angle off the arrival side
  ACHIEVEMENTS = true,
  TICKETS = 500,             -- per visit, the first round you outlast the clock (live: 'You receive item: [Azzar Faire Ticket]x500')
}
local E = { SNAGG = 371922, BRANN = 99735, CRYSTAL = 379183, STRIKE = 99564, SKY = 99524, CREDIT = 372024,
            EYE = 99560, PIT = 99525, TENTACLE = 99526, POOL = 99527, HOLE = 99528, PORTAL = 9997810,
            MOVER = 99519 }   -- v1.4: 99519 is the only invisible helper that is NOT rooted in the database (Bullet Romper's orb): what must move uses it     -- v1.1: invisible void helpers already in azzar-shadow-eye.sql
local S = { RIDE = 46598, STUN = 255620, AUTOMOVE = 255634, CRYSTAL = 257213, ZONE = 255636, METEOR = 255637, SKY = 255628, SCORE1 = 255647,   -- v1.2: Holy Crystal, Void Meteors zone, Void Meteor
            SCORE5 = 257231, READY = 257210, ARROW = 255649,                 -- v1.1, all in the server's Spell.dbc
            HIT = 256025, VSTUN = 257214, AEGIS = 257216,                    -- Void Hitted Aura, Vehicle Stun, Sanctified Aegis (names seen in the footage)
            TRAIL = 257218, CONSUME = 257219, CLOUD = 256827, POOLVIS = 64135, ROCK = 255600, LAUNCH = 33673, EYE = 255657, TENT = 255652, TENTHIT = 255631, AMB = 257416,   -- v1.2: Azzar_voideye, void tentacle, Void Ambience Missile
            HOLEVIS = 256068, ZONEVIS = 255635, SKY2 = 256005, WAVE = 255633, MARK = 257524 }   -- v1.4: the live looks (models by SpellVisualKitModelAttach)                                                -- GUESS: the stock Black Hole look (Algalon); pick another with '#se fx <id>'
local OP_COUNTDOWN = 0x588
local Q_BASE, Q_DAILY = 1650228, 1650267
local TEXT_GREET, TEXT_MORE = 1200147, 1200148
local TEXT_PORTAL = 1200245    -- '<The portal connects to the Azzar Faire. ...>' (already in the database, as in Wonka Wonka)
local ACH = { FRIENDS = 90284, STAND = 90291, NOTOUCH = 90292, ALLALIVE = 90293, NOBODY = 90294, ONLY = 90295, DODGE = 90296, HAND = 90297,
              SPARKS = 90300, CREW = 90303, PASSING = 90305, ADDICT = 90306, PURPOSE = 90307 }   -- v1.4: live achievements (Achievement.dbc, category 2008)
local RED = "|cffff2020"
local ITEM_TICKET = 558530
local TEMPSUMMON_TIMED_DESPAWN = 3
local LIFE = 60 * 60000        -- v1.1: 7 rounds can run past 20 minutes

local Games = {}
local Pending = {}
local VT = "|cffb070ff[VOID]|r "
local AZT = "|cffff8000Azzar Event:|r "

local function log(msg) print("[ShadowEye] " .. msg) end
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
local function giveAch(pl, id)                              -- v1.4
  if pl and SE.ACHIEVEMENTS and try(pl, "HasAchieved", id) ~= true then try(pl, "SetAchievement", id) end
end
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
local function inGame(g, pl) return pl and pl:GetMapId() == SE.MAP and pl:GetInstanceId() == g.inst end
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
local function rideOf(g, m) return obj(g, m.rideGuid) end
local function randSpot(rmin, rmax)
  local ang, r = math.random() * 2 * math.pi, rmin + math.random() * (rmax - rmin)
  return SE.CENTER[1] + r * math.cos(ang), SE.CENTER[2] + r * math.sin(ang)
end

-- ---------- the archaeologist (vehicle) ----------
local function hold(c, on)
  if not c then return end
  if on then try(c, "RemoveAura", S.AUTOMOVE); try(c, "AddAura", S.STUN, c); try(c, "SetRooted", true)
  else try(c, "RemoveAura", S.STUN); try(c, "SetRooted", false); if SE.AUTOMOVE then try(c, "AddAura", S.AUTOMOVE, c) end end
end
local function dropRide(g, low, pl)
  local m = g.members[low]
  local c = rideOf(g, m)
  if c then
    local kit = c:GetVehicleKit()
    if kit and pl then try(kit, "RemovePassenger", pl) end
    c:DespawnOrUnsummon(300)
  end
  m.rideGuid = nil
end
local function board(g, low, pl)
  local m = g.members[low]
  local c = pl:SpawnCreature(E.BRANN, pl:GetX(), pl:GetY(), SE.CENTER[3] + 0.2, pl:GetO(), TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if not c then log("could not spawn the archaeologist (template " .. E.BRANN .. " missing? run the SQL)"); return false end
  m.rideGuid = c:GetGUID()
  try(c, "SetSpeed", 1, SE.SPEED, true)
  if SE.MARK_EVERY <= 0 then try(c, "AddAura", S.ARROW, c) end   -- v1.6g: live has no standing arrow; the chevron is the 15-s Void Meteor mark (257524)
  local kit = c:GetVehicleKit()
  if not kit then log("the archaeologist has no vehicle kit (VehicleId missing in creature_template " .. E.BRANN .. "?)"); return false end
  pl:CastSpell(c, S.RIDE, true)
  if not kit:GetPassenger(0) then try(kit, "AddPassenger", pl, 0) end
  hold(c, g.state ~= "playing" or m.down ~= nil)
  local pas = kit:GetPassenger(0)
  return pas and pas:GetGUIDLow() == low
end

-- ---------- v1.2: the live HUD (world states, as Wonka Wonka v1.2) ----------
local WS = { RES_ON = 6000, RES = 6001, TIME_ON = 3564, MIN = 3559, TEN = 3560, ONE = 3561, CRY_ON = 2579, CRY = 1588 }
local function ws(pl, field, value) if SE.HUD then try(pl, "SendUpdateWorldState", field, value) end end
local function hudShow(g, secLeft)                       -- only sends when something changed
  local left = math.max(0, math.ceil(secLeft))
  local showRes = (g.round >= 2 or g.count <= 1) and 1 or 0   -- v1.4: live shows the charges line from round 2 on (ours: also when you play alone, where it is your one self-revive)
  local key = left .. ":" .. g.total .. ":" .. g.revives .. ":" .. showRes
  if key == g.hudKey then return end
  g.hudKey = key
  local s = left % 60
  for low, _ in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) then
      ws(pl, WS.RES_ON, showRes); ws(pl, WS.RES, g.revives)
      ws(pl, WS.TIME_ON, 1); ws(pl, WS.MIN, math.floor(left / 60)); ws(pl, WS.TEN, math.floor(s / 10)); ws(pl, WS.ONE, s % 10)
      ws(pl, WS.CRY_ON, 1); ws(pl, WS.CRY, g.total)
    end
  end
end
local function hudOff(pl) if pl then ws(pl, WS.RES_ON, 0); ws(pl, WS.TIME_ON, 0); ws(pl, WS.CRY_ON, 0) end end
local function hudAfter(g, pl) if pl then ws(pl, WS.RES_ON, 0); ws(pl, WS.TIME_ON, 0); ws(pl, WS.CRY_ON, 1); ws(pl, WS.CRY, g.total) end end   -- v1.4: after a round only 'Collected Crystals: n' stays (live)

-- ---------- crystals ----------
local function spawnCrystalAt(g, x, y, fall)
  local a = anchor(g)
  if not a then return end
  if (SE.CRYSTAL_GAP or 0) > 0 then                          -- v1.6b: never two crystals on top of each other
    for _, q in pairs(g.crystals) do if dist2(x, y, q.x, q.y) < SE.CRYSTAL_GAP then return end end
  end
  local c = a:SpawnCreature(fall and E.MOVER or E.CRYSTAL, x, y, SE.CENTER[3] + 1.2 + (fall and SE.FALL_H or 0), math.random() * 6.28, TEMPSUMMON_TIMED_DESPAWN, (SE.GAME_TIME + 120) * 1000)   -- v1.2b: one round
  if not c then
    if not g.noCrystal then g.noCrystal = true; log("could not spawn a Light Crystal (template " .. E.CRYSTAL .. " missing? run the SQL)") end
    return
  end
  local big = math.random(SE.BIG_CHANCE) == 1
  if SE.CRYSTAL_DISPLAY > 0 then try(c, "SetDisplayId", SE.CRYSTAL_DISPLAY) else try(c, "AddAura", S.CRYSTAL, c) end   -- v1.2b
  if big then try(c, "SetScale", 2) end
  local readyAt = 0
  if fall then                                              -- v1.2c: it comes down from the sky with a light trail
    try(c, "SetRooted", false); try(c, "SetSpeed", 6, SE.FALL_SPEED / 7.0, true); try(c, "SetSpeed", 1, SE.FALL_SPEED / 7.0, true)
    try(c, "AddAura", S.TRAIL, c); try(c, "MoveTo", 0, x, y, SE.CENTER[3] + 1.2)
    readyAt = now() + math.floor(SE.FALL_H / SE.FALL_SPEED * 1000) + 300
  end
  g.crystals[c:GetGUIDLow()] = { guid = c:GetGUID(), x = x, y = y, worth = big and 5 or 1, readyAt = readyAt, trail = fall }
  g.crystalCount = g.crystalCount + 1
end
local function tickFalls(g, t)                              -- v1.2c: a landed crystal loses its trail
  for i = #(g.halos or {}), 1, -1 do                        -- v1.6s: the Halo ring, a moment after its helper has reached the clients
    local q = g.halos[i]
    if t >= q.at then
      table.remove(g.halos, i)
      local hh = obj(g, q.guid)
      if hh and SE.HALO_CAST then try(hh, "CastSpell", hh, SE.HALO_SPELL, true)
      elseif hh then
        local ok, err = pcall(function()
          local pk = CreatePacket(0x1F3, 12)                -- SMSG_PLAY_SPELL_VISUAL: the unit, then the SpellVisualKit id
          pk:WriteGUID(hh:GetGUID()); pk:WriteULong(SE.HALO_KIT)
          for low, _ in pairs(g.members) do local pl = getPlayer(g, low); if inGame(g, pl) then pl:SendPacket(pk) end end
        end)
        if not g.haloLogged then g.haloLogged = true; log("halo visual sent = " .. tostring(ok) .. (ok and "" or (" (" .. tostring(err) .. ")"))) end
      end
    end
  end
  for i = #(g.ripQ or {}), 1, -1 do                         -- v1.6r (Rowan: the light aoe spreading out): golden circles, each wider than the last, one after another
    local q = g.ripQ[i]
    local a3 = anchor(g)
    while q.k < #SE.RIP_S and t >= q.t0 + q.k * SE.RIP_STEP do
      q.k = q.k + 1
      local sc = SE.RIP_S[q.k]
      local w = a3 and a3:SpawnCreature(E.STRIKE, q.x, q.y, SE.CENTER[3] + 0.3 - SE.RIP_Z * sc, 0, TEMPSUMMON_TIMED_DESPAWN, SE.RIP_HOLD + 3000)
      if w then
        try(w, "SetScale", sc); try(w, "AddAura", SE.RIP_SPELL, w)
        g.pops = g.pops or {}; g.pops[#g.pops + 1] = { guid = w:GetGUID(), at = t + SE.RIP_HOLD, aura = SE.RIP_SPELL }
      end
    end
    if q.k >= #SE.RIP_S then table.remove(g.ripQ, i) end
  end
  for i = #(g.pops or {}), 1, -1 do                         -- v1.6l: the pick-up burst helper: its crystal look is taken off again
    local p = g.pops[i]
    if t >= p.at then
      local h = obj(g, p.guid)
      if h then try(h, "RemoveAura", p.aura or S.CRYSTAL); h:DespawnOrUnsummon(1600) end
      table.remove(g.pops, i)
    end
  end
  for _, cr in pairs(g.crystals) do
    if cr.trail and t >= cr.readyAt then
      cr.trail = false
      local c = obj(g, cr.guid)
      if c then
        try(c, "RemoveAura", S.TRAIL)
        if SE.BURST_LAND and (SE.BURST_SPELL or 0) > 0 then try(c, "CastSpell", c, SE.BURST_SPELL, true) end
      end
      if cr.worth >= 5 and (SE.HALO_KIT or 0) > 0 then      -- v1.6s (Rowan: the holy priest spell Halo): its ring spreads from where a big crystal lands
        local a4 = anchor(g)
        local hh = a4 and a4:SpawnCreature(E.STRIKE, cr.x, cr.y, SE.CENTER[3] + SE.HALO_Z, 0, TEMPSUMMON_TIMED_DESPAWN, 6000)
        if hh then g.halos = g.halos or {}; g.halos[#g.halos + 1] = { guid = hh:GetGUID(), at = t + SE.HALO_AFTER } end
      end
      if cr.worth >= 5 and (SE.RIP_SPELL or 0) > 0 then g.ripQ = g.ripQ or {}; g.ripQ[#g.ripQ + 1] = { x = cr.x, y = cr.y, t0 = t, k = 0 } end   -- v1.6r: the light spreads out from here
      if cr.worth >= 5 and (SE.RING_SPELL or 0) > 0 then    -- v1.6p (Rowan: the light burst floor animation): the golden disc where a big crystal lands
        local a2 = anchor(g)
        local h = a2 and a2:SpawnCreature(E.STRIKE, cr.x, cr.y, SE.CENTER[3] + 0.2, 0, TEMPSUMMON_TIMED_DESPAWN, SE.RING_MS + 3000)
        if h then
          try(h, "AddAura", SE.RING_SPELL, h)
          g.pops = g.pops or {}; g.pops[#g.pops + 1] = { guid = h:GetGUID(), at = t + SE.RING_MS, aura = SE.RING_SPELL }
        end
      end
    end
  end
end
local function spawnGroup(g, fall)                          -- v1.6g: ONE crystal at a random spot of the track (live: they come down one by one, anywhere; Rowan: 'not placed at random')
  for _ = 1, 6 do
    local x, y = randSpot(SE.CENTER_FREE + 2, SE.FLOOR_R - 2)
    local before = g.crystalCount
    spawnCrystalAt(g, x, y, fall)
    if g.crystalCount > before then return end
  end
end
local function collect(g, low, pl, x, y)
  local m = g.members[low]
  for cl, cr in pairs(g.crystals) do
    if (cr.readyAt or 0) <= now() and dist2(x, y, cr.x, cr.y) <= SE.CRYSTAL_R then   -- v1.2c: only once it has landed
      local c = obj(g, cr.guid)
      if c then                                              -- v1.6g: the '+1' / '+5' pop with its burst is cast by the CRYSTAL where it stood (as the duck and the race coin do);
        try(c, "RemoveAura", S.TRAIL)
        local mode = SE.CRYSTAL_BURST or 0                   -- v1.6l (Rowan: still no burst): 1 = the crystal DIES and stays for its death burst, 2 = the Holy Crystal look put on and taken off at the spot, 3 = both
        local dead = false
        if mode == 1 or mode == 3 then
          try(c, "DealDamage", c, 10000000, false)
          pcall(function() dead = not c:IsAlive() end)
          if not g.burstLogged then g.burstLogged = true; log("crystal burst: mode " .. mode .. ", crystal died = " .. tostring(dead)) end
        end
        local gone = dead and (SE.CRYSTAL_DIE_MS or 1500) or 0
        if not dead and SE.CRYSTAL_HIDE then                 -- v1.6t (Rowan: a collected crystal stays a second or two): the client fades a removed creature out,
          try(c, "SetDisplayId", SE.CRYSTAL_HIDE_DISPLAY); try(c, "SetScale", 0.01)   --   so it is made invisible and tiny first (instant on the client) and removed a moment later
          gone = SE.CRYSTAL_GONE_MS or 400
        end
        c:DespawnOrUnsummon(gone)
        if mode >= 2 then
          local a2 = anchor(g)
          local h = a2 and a2:SpawnCreature(E.STRIKE, cr.x, cr.y, SE.CENTER[3] + 1.2, 0, TEMPSUMMON_TIMED_DESPAWN, 2500)
          if h then
            try(h, "AddAura", S.CRYSTAL, h)
            if cr.worth >= 5 then try(h, "SetScale", 2) end
            g.pops = g.pops or {}; g.pops[#g.pops + 1] = { guid = h:GetGUID(), at = now() + (SE.BURST_MS or 350) }
          end
        end
      end                                                    --   so the DWARF casts it on himself (as the duck and the race kart do); the crystal goes at once.
      local rc, pop = rideOf(g, m), cr.worth >= 5 and S.SCORE5 or S.SCORE1
      if rc then try(rc, "CastSpell", rc, pop, true) elseif pl then try(pl, "CastSpell", pl, pop, true) end
      if (SE.BURST_SPELL or 0) > 0 then                      -- v1.6o: the burst of light (Stomp 256022 = 11fx_holy_impact01, a harmless dummy)
        if rc then try(rc, "CastSpell", rc, SE.BURST_SPELL, true) elseif pl then try(pl, "CastSpell", pl, SE.BURST_SPELL, true) end
      end
      g.crystals[cl] = nil; g.crystalCount = g.crystalCount - 1
      m.score = m.score + cr.worth; g.total = g.total + cr.worth
      m.visit = (m.visit or 0) + cr.worth; if m.visit >= 50 then giveAch(pl, ACH.SPARKS) end          -- v1.4
      m.cq = m.cq or {}; m.cq[#m.cq + 1] = { now(), cr.worth }
      while m.cq[1] and now() - m.cq[1][1] > 30000 do table.remove(m.cq, 1) end
      local sum = 0; for _, e in ipairs(m.cq) do sum = sum + e[2] end
      if sum >= 75 then giveAch(pl, ACH.ADDICT) end
      if SE.CENTER_SCORE then pl:SendAreaTriggerMessage("+" .. cr.worth .. "   (Collected Crystals: " .. g.total .. ")") end
    end
  end
end

-- ---------- the Void strikes ----------
local function music(pl, id)                                -- v1.6l: sent as the Rainbow Race sends its theme (Player:PlayMusic; 0 = stop)
  if not SE.MUSIC or not pl then return end
  if type(pl.PlayMusic) == "function" then local ok = pcall(pl.PlayMusic, pl, id, pl); if ok then return end end
  if id ~= 0 then try(pl, "PlayDirectSound", id, pl) end
end
local function eliminate(g, low, t)
  local m = g.members[low]
  if m.down or m.out or (m.aegisUntil or 0) > t then return end
  m.down = t; m.lateSaid = nil; m.hits = (m.hits or 0) + 1
  local c = rideOf(g, m)
  if SE.CONSUME and c then                                  -- v1.3: rooted (a stun would break the cast), then the live 30 s 'Void Consumption'
    try(c, "RemoveAura", S.AUTOMOVE); try(c, "SetRooted", true); try(c, "AddAura", S.HIT, c)
    try(c, "AddAura", S.VSTUN, c)                           -- v1.6h: live look of a caught dwarf = Vehicle Stun 257214 (blue-white spikes round the feet + light rays). Void Consumption (257219) is flagged usable while stunned, so the cast still runs; taking the stun off at a revive plays the rainbow swirl (its own end effect)
    if (SE.STUN_EMOTE or 0) > 0 then try(c, "EmoteState", SE.STUN_EMOTE) end   -- v1.6d: the dizzy pose
    try(c, "CastSpell", c, S.CONSUME, false)
    if not g.consumeLogged then                             -- v1.6l: Rowan did not see the vortex (= the precast kit of this cast): did the cast start?
      g.consumeLogged = true
      local casting = "unknown"; pcall(function() casting = tostring(c:IsCasting()) end)
      log("caught " .. tostring(m.name) .. ": Void Consumption cast started = " .. casting)
    end
  else
    hold(c, true)
    if c then try(c, "AddAura", S.HIT, c); try(c, "AddAura", S.VSTUN, c) end
  end
  tell(g, VT .. RED .. m.name .. "|r was eliminated! Revive them before they are lost.", true)   -- v1.4: the whole line mid-screen too (live)
  if g.startedAt and t - g.startedAt <= 10000 then giveAch(getPlayer(g, low), ACH.PURPOSE) end
end
local function eachRunner(g, fn)                            -- fn(low, m, pl, x, y) for every player still running
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if inGame(g, pl) and not m.down and not m.out then fn(low, m, pl, pl:GetX(), pl:GetY()) end
  end
end
local function dummy(g, entry, x, y, z, life, aura)         -- an invisible helper carrying a visual
  local a = anchor(g)
  if not a then return nil end
  local c = a:SpawnCreature(entry, x, y, z, 0, TEMPSUMMON_TIMED_DESPAWN, life)
  if c and aura then try(c, "AddAura", aura, c) end
  return c
end
local function runnerSpot(g, spread)                        -- a spot near a random runner (nil if nobody is running)
  local alive = {}
  eachRunner(g, function(low, m, pl, x, y) alive[#alive + 1] = { x, y } end)
  if #alive == 0 then return nil end
  local p = alive[math.random(#alive)]
  return p[1] + (math.random() * 2 - 1) * spread, p[2] + (math.random() * 2 - 1) * spread
end
local function runnerAhead(g, dist)                         -- v1.4: a spot `dist` yards in front of a random runner + his heading (nil if nobody runs)
  local alive = {}
  eachRunner(g, function(low, m, pl, x, y) alive[#alive + 1] = { x, y, pl:GetO() or 0 } end)
  if #alive == 0 then return nil end
  local p = alive[math.random(#alive)]
  local x, y = p[1] + math.cos(p[3]) * dist, p[2] + math.sin(p[3]) * dist
  local r = dist2(x, y, SE.CENTER[1], SE.CENTER[2])
  if r < SE.CENTER_FREE + 1 or r > SE.FLOOR_R + 4 then x, y = p[1], p[2] end   -- not into the pit, not out into the dark
  return x, y, p[3]
end
-- v1.4: a volley of Void Meteors as on live: 3-5 swirl zones in a ROW along the track ('Void Meteors' 255636, 12 s), the Eye throws a void
-- missile at each, and a zone you touch launches you into the air (Rowan's live close-ups). They do not eliminate (STRIKE_KILL brings that back).
local function launchUp(g, m, pl, t)                        -- v1.6d: one launch for the Eye's circles and the wandering ones
  if t < (m.launchAt or 0) then return end
  m.launchAt = t + SE.LAUNCH_CD
  local ride = rideOf(g, m) or pl
  if SE.LAUNCH_JUMP then
    local o = ride:GetO() or 0
    try(ride, "MoveJump", ride:GetX() + math.cos(o) * 12, ride:GetY() + math.sin(o) * 12, SE.CENTER[3] + 0.5, 8, 16)
  else try(ride, "CastSpell", ride, S.LAUNCH, true) end
end
local function strike(g, t)
  local x, y
  if SE.POOL_SEEK and math.random(3) > 1 then x, y = runnerAhead(g, 10) end   -- v1.6k (Rowan): not placed at a runner
  if not x then x, y = randSpot(SE.CENTER_FREE + 4, SE.FLOOR_R - 3) end
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  local r0 = math.max(SE.CENTER_FREE + 3, math.min(SE.FLOOR_R - 2, dist2(x, y, cx, cy)))
  local a0 = (math.atan2 or math.atan)(y - cy, x - cx)
  local n = math.random(math.max(1, SE.POOL_CLUSTER - 1), SE.POOL_CLUSTER + 1)
  local step = (SE.POOL_GAP / r0) * (math.random(2) == 1 and 1 or -1)
  local ex, ey = cx + SE.EYE_AT[1], cy + SE.EYE_AT[2]
  for k = 0, n - 1 do
    local aa = a0 + step * k
    local px, py = cx + math.cos(aa) * r0, cy + math.sin(aa) * r0
    local z = dummy(g, SE.POOL_SPEED > 0 and E.MOVER or E.POOL, px, py, SE.CENTER[3] + 0.1, SE.POOL_MS + 500, S.ZONE)   -- v1.6g: on the un-rooted helper, so it can move
    if z then
      try(z, "SetScale", SE.POOL_SCALE)
      if SE.POOL_SPEED > 0 then
        try(z, "SetRooted", false)
        try(z, "SetSpeed", 0, SE.POOL_SPEED / 2.5, true); try(z, "SetSpeed", 1, SE.POOL_SPEED / 7.0, true); try(z, "SetSpeed", 6, SE.POOL_SPEED / 7.0, true)
      end
    end
    local d = dist2(px, py, ex, ey)
    local throwAt = t + 500 + k * 250
    g.pools[#g.pools + 1] = { guid = z and z:GetGUID(), x = px, y = py, throwAt = throwAt,
                              armAt = throwAt + math.floor(math.sqrt(d * d + SE.THROW_Z * SE.THROW_Z) / 50 * 1000), untilT = t + SE.POOL_MS, nextMove = t + 900 + k * 300 }
  end
end
local function chaser(g, t, low, pl, x, y)                  -- v1.6i: live 144-145, 161-163, burst 67.6-71.4 s: a blue swirl circle slides after a marked dwarf, stops, turns lilac, the dart
  local o = pl:GetO() or 0                                  --   comes down on it; the stopped circles lie behind him as a trail (5-6 at a time)
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  local bx, by = x - math.cos(o) * SE.POOL_BEHIND, y - math.sin(o) * SE.POOL_BEHIND
  local r = dist2(bx, by, cx, cy)
  local rr = math.max(SE.CENTER_FREE + 2, math.min(SE.FLOOR_R, r))
  if r > 0.1 then bx, by = cx + (bx - cx) * rr / r, cy + (by - cy) * rr / r end
  local z = dummy(g, E.MOVER, bx, by, SE.CENTER[3] + 0.1, SE.POOL_CHASE_MS + SE.POOL_MS + 500, S.ZONE)
  if z then
    try(z, "SetRooted", false)
    try(z, "SetSpeed", 0, SE.POOL_CHASE_SPEED / 2.5, true); try(z, "SetSpeed", 1, SE.POOL_CHASE_SPEED / 7.0, true); try(z, "SetSpeed", 6, SE.POOL_CHASE_SPEED / 7.0, true)
  end
  g.pools[#g.pools + 1] = { guid = z and z:GetGUID(), x = bx, y = by, chase = low, chaseUntil = t + SE.POOL_CHASE_MS, nextMove = 0,
                            throwAt = t + math.max(0, SE.POOL_CHASE_MS - 600), armAt = t + SE.POOL_CHASE_MS + 300, untilT = t + SE.POOL_CHASE_MS + SE.POOL_MS }
end
local function tickStrikes(g, t)
  local left = math.max(0, (g.endAt - t) / (SE.GAME_TIME * 1000))        -- 1 at the start, 0 at the end: volleys speed up
  local every = math.max(SE.STRIKE_MIN, SE.STRIKE_EVERY - 400 * (g.round - 1))   -- and a little faster each round
  if SE.POOL_CHASE and SE.MARK_EVERY > 0 then
    if t < (g.markUntil or 0) then
      eachRunner(g, function(low, m, pl, x, y)
        if t >= (m.nextPool or 0) then m.nextPool = t + SE.POOL_EVERY + math.random(0, 300); chaser(g, t, low, pl, x, y) end
      end)
    end
  elseif t >= g.nextStrike and (SE.MARK_EVERY <= 0 or t < (g.markUntil or 0)) then   -- v1.6g: live: the circles only come while the Void Meteor mark is up
    g.nextStrike = t + SE.STRIKE_MIN + (every - SE.STRIKE_MIN) * left
    strike(g, t)
  end
  for i = #g.pools, 1, -1 do
    local p = g.pools[i]
    if p.chase then                                          -- v1.6i: after its dwarf until it stops
      local zc2 = obj(g, p.guid)
      if zc2 then
        p.x, p.y = zc2:GetX(), zc2:GetY()
        local m2 = g.members[p.chase]; local pl2 = m2 and not m2.down and not m2.out and getPlayer(g, p.chase)
        if t >= p.chaseUntil or not pl2 then p.chase = nil; try(zc2, "MoveStop")
        elseif t >= p.nextMove then p.nextMove = t + 250; try(zc2, "MoveTo", 0, pl2:GetX(), pl2:GetY(), SE.CENTER[3] + 0.1) end
      else p.chase = nil end
    end
    local zc = SE.POOL_SPEED > 0 and not SE.POOL_CHASE and obj(g, p.guid)          -- v1.6g: it wanders (half the time toward somebody who is running) and launches where it IS
    if zc then
      p.x, p.y = zc:GetX(), zc:GetY()
      if t >= (p.nextMove or 0) and t < p.untilT - 500 then
        p.nextMove = t + SE.POOL_MOVE + math.random(0, 1500)
        local cx, cy = SE.CENTER[1], SE.CENTER[2]
        local tx, ty
        if SE.POOL_SEEK and math.random(2) == 1 then tx, ty = runnerSpot(g, 4) end   -- v1.6k (Rowan): they wander at random, they do not follow
        if tx then
          local d = dist2(tx, ty, p.x, p.y)
          if d > SE.POOL_STEP then tx, ty = p.x + (tx - p.x) * SE.POOL_STEP / d, p.y + (ty - p.y) * SE.POOL_STEP / d end
        else
          local a = math.random() * 2 * math.pi
          tx, ty = p.x + math.cos(a) * SE.POOL_STEP, p.y + math.sin(a) * SE.POOL_STEP
        end
        local r = dist2(tx, ty, cx, cy)
        local rr = math.max(SE.CENTER_FREE + 3, math.min(SE.FLOOR_R - 2, r))
        if r > 0.1 then tx, ty = cx + (tx - cx) * rr / r, cy + (ty - cy) * rr / r end
        try(zc, "MoveTo", 0, tx, ty, SE.CENTER[3] + 0.1)
      end
    end
    if p.throwAt and t >= p.throwAt then                    -- the Eye throws its meteor at the zone (missile 255637, 50 yd/s)
      p.throwAt = nil
      local z = obj(g, p.guid)
      local eyeC = obj(g, g.eyeGuid)                         -- v1.6i: from where the Eye is now (it wanders)
      local ex, ey, ez = SE.CENTER[1] + SE.EYE_AT[1], SE.CENTER[2] + SE.EYE_AT[2], SE.CENTER[3] + SE.THROW_Z
      if eyeC then ex, ey, ez = eyeC:GetX(), eyeC:GetY(), eyeC:GetZ() end
      local hi = SE.THROW_FROM_EYE and dummy(g, E.STRIKE, ex, ey, ez, 4000, nil)
      if hi and z then try(hi, "CastSpell", z, S.METEOR, true) end
      if hi then g.amb = g.amb or {}; g.amb[#g.amb + 1] = { guid = hi:GetGUID(), untilT = t + 4000 } end
    end
    if t >= p.untilT then table.remove(g.pools, i)
    elseif t >= p.armAt then
      if SE.STRIKE_KILL and not p.blasted then
        p.blasted = true
        eachRunner(g, function(low, m, pl, x, y) if dist2(x, y, p.x, p.y) <= SE.STRIKE_R then eliminate(g, low, t) end end)
      end
      eachRunner(g, function(low, m, pl, x, y)
        if SE.POOL_LAUNCH and dist2(x, y, p.x, p.y) <= SE.POOL_R then launchUp(g, m, pl, t) end   -- v1.2e: up you go
      end)
    end
  end
end
-- v1.2c: a black orb (model) and its blue floor circle, travelling together
local function makeHole(g, x, y, life, speed)
  local c = dummy(g, E.MOVER, x, y, SE.CENTER[3] + SE.HOLE_Z, life, SE.HOLE_DISPLAY > 0 and nil or S.HOLEVIS)
  if c then
    if SE.HOLE_DISPLAY > 0 then try(c, "SetDisplayId", SE.HOLE_DISPLAY) end
    if SE.HOLE_SCALE ~= 1 then try(c, "SetScale", SE.HOLE_SCALE) end
    try(c, "SetRooted", false); try(c, "SetSpeed", 1, speed / 7.0, true); try(c, "SetSpeed", 6, speed / 7.0, true)
  end
  local r
  if SE.HOLE_RING > 0 then
    r = dummy(g, E.MOVER, x, y, SE.CENTER[3] + 0.1, life, SE.HOLE_RING)
    if r then if SE.RING_SCALE ~= 1 then try(r, "SetScale", SE.RING_SCALE) end; try(r, "SetRooted", false); try(r, "SetSpeed", 1, speed / 7.0, true); try(r, "SetSpeed", 6, speed / 7.0, true); g.rings[#g.rings + 1] = r:GetGUID() end
  end
  return c, r
end
local function moveHole(c, r, x, y)
  if c then try(c, "MoveTo", 0, x, y, SE.CENTER[3] + SE.HOLE_Z) end
  if r then try(r, "MoveTo", 0, x, y, SE.CENTER[3] + 0.1) end
end
-- v1.1: a row of black holes crossing the floor through a runner's spot (footage 23:57: five in a line)
local function tickHoles(g, t)
  if SE.HOLE_EVERY > 0 and t >= g.nextHole then
    g.nextHole = t + math.max(SE.HOLE_MIN, SE.HOLE_EVERY - 1000 * (g.round - 1))
    local tx, ty = runnerSpot(g, 6)
    if tx then
      local ang = math.random() * 2 * math.pi
      local dx, dy = math.cos(ang), math.sin(ang)           -- the row travels along this bearing
      local half, life = SE.HOLE_TRAVEL / 2, SE.HOLE_TRAVEL / SE.HOLE_SPEED * 1000
      for k = 1, SE.HOLE_COUNT do
        local off = (k - (SE.HOLE_COUNT + 1) / 2) * SE.HOLE_GAP          -- place in the row, sideways
        local sx, sy = tx - dx * half - dy * off, ty - dy * half + dx * off
        local ex, ey = tx + dx * half - dy * off, ty + dy * half + dx * off
        local c, r = makeHole(g, sx, sy, life + 500, SE.HOLE_SPEED)   -- v1.2c: orb + floor circle
        moveHole(c, r, ex, ey)
        g.holes[#g.holes + 1] = { guid = c and c:GetGUID(), sx = sx, sy = sy, ex = ex, ey = ey, t0 = t, life = life }
      end
    end
  end
  for i = #g.holes, 1, -1 do
    local h = g.holes[i]
    local f = (t - h.t0) / h.life
    local c = obj(g, h.guid)
    if f >= 1 then
      if c then c:DespawnOrUnsummon(0) end
      table.remove(g.holes, i)
    elseif f > 0.08 then                                    -- the hole is where its marker really is (if the marker did not move, neither does the danger)
      local hx, hy = h.sx + (h.ex - h.sx) * f, h.sy + (h.ey - h.sy) * f
      if c then hx, hy = c:GetX(), c:GetY() end
      eachRunner(g, function(low, m, pl, x, y) if dist2(x, y, hx, hy) <= SE.HOLE_R then eliminate(g, low, t) end end)
    end
  end
end
-- v1.2: black holes drifting about the floor all round (live 24:00-24:06: many, scattered, slow); v1.2c: orb + floor circle
local function driftTo(h, c)                                -- v1.4: they creep a few yards at a time and stay on the ring
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  local a = math.random() * 2 * math.pi
  local x, y = c:GetX() + math.cos(a) * 9, c:GetY() + math.sin(a) * 9
  local r = dist2(x, y, cx, cy)
  local rr = math.max(SE.CENTER_FREE + 2, math.min(SE.FLOOR_R, r))
  if r > 0.1 then x, y = cx + (x - cx) * rr / r, cy + (y - cy) * rr / r end
  moveHole(c, h.ring and obj(h.g, h.ring), x, y)
end
local function startDrift(g)
  g.drift = {}
  if (SE.SPOKES or 0) > 0 then                              -- v1.6i: live: straight lines of orbs from the rim of the pit outward (still straight and evenly spaced 0, 6, 12, 39 and 41 s into
    local cx, cy = SE.CENTER[1], SE.CENTER[2]               --   a round: frames 022, 030, 126, 160, 162), and every orb slides sideways along a circle round the pit (still-camera composite
    local per = math.min(SE.SPOKE_MAX, SE.SPOKE_N + (g.round - 1))   --   903-909 s: chains of circles along arcs). Round 1: 4 to a line, round 2: 5 (162).
    local dir = math.random(2) == 1 and 1 or -1
    local a0 = math.random() * 2 * math.pi
    for try_ = 1, 30 do                                     -- no line through somebody's start slot (17 degrees clear, 9 if that cannot be had: five players and three lines)
      local clear, need = true, try_ <= 12 and 0.3 or 0.15
      for low, _ in pairs(g.members) do
        local pl = getPlayer(g, low)
        if inGame(g, pl) then
          local pa = (math.atan2 or math.atan)(pl:GetY() - cy, pl:GetX() - cx)
          for j = 0, SE.SPOKES - 1 do
            local d = (a0 + j * 2 * math.pi / SE.SPOKES - pa) % (2 * math.pi); if d > math.pi then d = 2 * math.pi - d end
            if d < need then clear = false end
          end
        end
      end
      if clear then break end
      a0 = math.random() * 2 * math.pi
    end
    g.spokeT0, g.spokeDir = now(), dir
    for j = 0, SE.SPOKES - 1 do
      local aa = a0 + j * 2 * math.pi / SE.SPOKES
      for i = 0, per - 1 do
        local rr = SE.SPOKE_R1 + i * SE.SPOKE_GAP
        local ox, oy = cx + math.cos(aa) * rr, cy + math.sin(aa) * rr
        local sp = math.max(0.5, rr * SE.SPOKE_TURN * 1.15)
        if SE.ORB_WANDER then                                -- v1.6j (Rowan): its own speed, and off on its own heading a moment after it appears
          sp = SE.ORB_SPEED_LO + math.random() * (SE.ORB_SPEED_HI - SE.ORB_SPEED_LO)
          if SE.ORB_SCATTER then
            for _ = 1, 10 do
              ox, oy = randSpot(SE.ORB_R_IN + 4, SE.FLOOR_R)
              local clear = true
              for low, _ in pairs(g.members) do
                local pl = getPlayer(g, low)
                if inGame(g, pl) and dist2(ox, oy, pl:GetX(), pl:GetY()) < 12 then clear = false end
              end
              if clear then break end
            end
          end
        end
        local c, r = makeHole(g, ox, oy, SE.GAME_TIME * 1000 + 10000, sp)
        if c then
          try(c, "SetSpeed", 0, sp / 2.5, true); if r then try(r, "SetSpeed", 0, sp / 2.5, true) end
          g.drift[#g.drift + 1] = { g = g, guid = c:GetGUID(), ring = r and r:GetGUID(), spokeA = aa, spokeR = rr, wander = SE.ORB_WANDER, speed = sp, head = math.random() * 2 * math.pi,
            nextMove = now() + (SE.ORB_WANDER and math.random(700, 2200) or 1200), armAt = now() + 800 }   -- live: they fade in over half a second (burst 19.5-20 s)
        end
      end
    end
    return
  end
  if SE.DRIFT <= 0 then return end
  local n = math.min(SE.DRIFT_MAX, SE.DRIFT + SE.DRIFT_ROUND * (g.round - 1))
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  local spots, inRow = {}, math.floor(n * SE.DRIFT_ROWS)
  if (SE.DRIFT_LINE or 0) > 0 then                          -- v1.6g: live (burst 19.5-22 s, frames 022, 030): at GO they appear in STRAIGHT LINES from the rim of the pit outward, 4 to a line, ~9 yd apart
    local lines = math.ceil(n / SE.DRIFT_LINE)
    local a0 = math.random() * 2 * math.pi
    local r1, r2 = SE.CENTER_FREE + 1, SE.FLOOR_R - 2
    for j = 0, lines - 1 do
      local aa = a0 + (j + (math.random() - 0.5) * 0.4) * 2 * math.pi / lines
      for i = 0, SE.DRIFT_LINE - 1 do
        if #spots < n then
          local rr = r1 + i * (r2 - r1) / math.max(1, SE.DRIFT_LINE - 1)
          spots[#spots + 1] = { cx + math.cos(aa) * rr, cy + math.sin(aa) * rr }
        end
      end
    end
  elseif SE.DRIFT_RING then                                 -- v1.6f: an even ring on the edge of the pit
    local a0, rr = math.random() * 2 * math.pi, SE.CENTER_FREE + 2
    for i = 0, n - 1 do local aa = a0 + i * 2 * math.pi / n; spots[#spots + 1] = { cx + math.cos(aa) * rr, cy + math.sin(aa) * rr } end
  end
  while #spots < inRow do                                   -- v1.4: live: rows of 3-5 along the track (frames 267, 794), the rest scattered
    local r = SE.CENTER_FREE + 3 + math.random() * (SE.FLOOR_R - SE.CENTER_FREE - 8)
    local a0, k = math.random() * 2 * math.pi, math.random(3, 5)
    for i = 0, k - 1 do
      if #spots < inRow then local aa = a0 + i * (SE.HOLE_GAP / r); spots[#spots + 1] = { cx + math.cos(aa) * r, cy + math.sin(aa) * r } end
    end
  end
  while #spots < n do local x, y = randSpot(SE.CENTER_FREE + 2, SE.FLOOR_R); spots[#spots + 1] = { x, y } end
  for _, sp in ipairs(spots) do
    local x, y = sp[1], sp[2]
    for low, _ in pairs(g.members) do                       -- never on top of somebody at the start
      local pl = getPlayer(g, low)
      if inGame(g, pl) and dist2(x, y, pl:GetX(), pl:GetY()) < 10 then x, y = cx - (x - cx), cy - (y - cy) end
    end
    local c, r = makeHole(g, x, y, SE.GAME_TIME * 1000 + 10000, SE.DRIFT_SPEED)
    if c then
      local h = { g = g, guid = c:GetGUID(), ring = r and r:GetGUID(), nextMove = now() + math.random(1500, 5000) }   -- they stand in their rows for a moment, then creep
      g.drift[#g.drift + 1] = h
    end
  end
end
local function wanderOrb(h, c, t)                           -- v1.6j: one more leg on its own heading; the next leg starts before this one ends
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  local x0, y0 = c:GetX(), c:GetY()
  local leg = SE.ORB_LEG_LO + math.random() * (SE.ORB_LEG_HI - SE.ORB_LEG_LO)
  local d = h.speed * leg / 1000
  local x, y
  for _ = 1, 8 do
    local a = (h.head or 0) + (math.random() - 0.5) * 2 * SE.ORB_TURN
    local tx, ty = x0 + math.cos(a) * d, y0 + math.sin(a) * d
    local r = dist2(tx, ty, cx, cy)
    if r >= SE.ORB_R_IN and r <= SE.ORB_R_OUT then h.head = a; x, y = tx, ty; break end
    h.head = math.random() * 2 * math.pi
  end
  if not x then                                             -- boxed in at the pit or the wall: back toward the middle of the track
    local a = (math.atan2 or math.atan)(y0 - cy, x0 - cx) + (math.random() - 0.5) * 2
    local rr = (SE.ORB_R_IN + SE.ORB_R_OUT) / 2
    x, y = cx + math.cos(a) * rr, cy + math.sin(a) * rr
    h.head = (math.atan2 or math.atan)(y - y0, x - x0)
    leg = dist2(x, y, x0, y0) / h.speed * 1000
  end
  h.nextMove = t + math.max(1000, math.floor(leg * 0.85))
  moveHole(c, h.ring and obj(h.g, h.ring), x, y)
end
local function tickDrift(g, t)
  for _, h in ipairs(g.drift or {}) do
    local c = obj(g, h.guid)
    if c then
      if h.wander then
        if t >= h.nextMove then wanderOrb(h, c, t) end
      elseif h.spokeR then                                      -- v1.6i: along its circle, a second and a half ahead each time
        if t >= h.nextMove then
          h.nextMove = t + 1000
          local aa = h.spokeA + (g.spokeDir or 1) * SE.SPOKE_TURN * (t + 1500 - (g.spokeT0 or t)) / 1000
          moveHole(c, h.ring and obj(g, h.ring), SE.CENTER[1] + math.cos(aa) * h.spokeR, SE.CENTER[2] + math.sin(aa) * h.spokeR)
        end
      elseif SE.DRIFT_CREEP and t >= h.nextMove then h.nextMove = t + SE.DRIFT_EVERY + math.random(0, 2000); driftTo(h, c) end
      local hx, hy = c:GetX(), c:GetY()
      if t >= (h.armAt or 0) then eachRunner(g, function(low, m, pl, x, y) if dist2(x, y, hx, hy) <= SE.HOLE_R then eliminate(g, low, t) end end) end
    end
  end
end
-- v1.2: Void Ambience Missiles: dark torrents from the edge across the arena (looks only)
local function tickAmb(g, t)
  g.amb = g.amb or {}; g.waves = g.waves or {}
  if SE.AMB_EVERY > 0 and t >= (g.nextAmb or 0) then
    g.nextAmb = t + SE.AMB_EVERY
    local ang = math.random() * 2 * math.pi
    local src = dummy(g, E.STRIKE, SE.CENTER[1] + math.cos(ang) * SE.FLOOR_R, SE.CENTER[2] + math.sin(ang) * SE.FLOOR_R, SE.CENTER[3] + 8, 5000, nil)
    local x, y = randSpot(SE.CENTER_FREE, SE.FLOOR_R)
    local dst = dummy(g, E.STRIKE, x, y, SE.CENTER[3] + 0.3, 5000, nil)
    if src and dst then try(src, "CastSpell", dst, S.AMB, true) end
    if src then g.amb[#g.amb + 1] = { guid = src:GetGUID(), untilT = t + 5000 } end
    if dst then g.amb[#g.amb + 1] = { guid = dst:GetGUID(), untilT = t + 5000 } end
  end
  if (SE.FOG_BANDS or 0) > 0 and g.fogAt and t >= g.fogAt then   -- v1.6i: live 062-066, 083-087, 141, 162-163: 2 s after each mark violet fog lies in long bands from the pit out to the rim
    g.fogAt = nil; g.fogQ = g.fogQ or {}                    --   (~45 x 12 yd, 2-4 of them) for ~4 s and ends in a web of lightning (not built). You can run through it (141, 163).
    local a0 = math.random() * 2 * math.pi
    for k = 0, SE.FOG_BANDS - 1 do
      local aa = a0 + (k + (math.random() - 0.5) * 0.5) * 2 * math.pi / SE.FOG_BANDS
      local i = 0
      for rr = 22, SE.FLOOR_R + 4, SE.FOG_GAP do
        g.fogQ[#g.fogQ + 1] = { at = t + i * 250, x = SE.CENTER[1] + math.cos(aa) * rr, y = SE.CENTER[2] + math.sin(aa) * rr, o = aa % (2 * math.pi) }
        i = i + 1
      end
    end
  end
  for i = #(g.fogQ or {}), 1, -1 do
    local f = g.fogQ[i]
    if t >= f.at then
      table.remove(g.fogQ, i)
      local c = dummy(g, E.STRIKE, f.x, f.y, SE.CENTER[3] + 0.2, SE.FOG_MS, SE.FOG_SPELL)
      if c then try(c, "SetFacing", f.o); g.amb[#g.amb + 1] = { guid = c:GetGUID(), untilT = t + SE.FOG_MS } end
    end
  end
  if SE.CLOUD_EVERY > 0 and t >= (g.nextCloud or 0) then   -- v1.4: the live 'Void Wave' (255633): a bank of purple void cloud with lightning that rolls along a stretch of the track; harmless
    g.nextCloud = t + SE.CLOUD_EVERY + math.random(0, 6000)
    local cx, cy = SE.CENTER[1], SE.CENTER[2]
    local a0 = math.random() * 2 * math.pi
    local sweep = SE.CLOUD_ARC * (math.random(2) == 1 and 1 or -1)
    for k = 1, SE.CLOUD_N do
      local r = SE.CENTER_FREE + 5 + (k - 1) * ((SE.FLOOR_R - SE.CENTER_FREE - 10) / math.max(1, SE.CLOUD_N - 1))
      local cl = dummy(g, E.MOVER, cx + math.cos(a0) * r, cy + math.sin(a0) * r, SE.CENTER[3] + 0.2, SE.CLOUD_MS, S.WAVE)
      if cl then
        try(cl, "AddAura", S.CLOUD, cl); try(cl, "SetScale", SE.CLOUD_SCALE)
        local sp = r * SE.CLOUD_ARC / (SE.CLOUD_MS / 1000) / 7.0
        try(cl, "SetSpeed", 0, sp, true); try(cl, "SetSpeed", 1, sp, true); try(cl, "SetSpeed", 6, sp, true)
        g.waves[#g.waves + 1] = { guid = cl:GetGUID(), r = r, a0 = a0, sweep = sweep, t0 = t, untilT = t + SE.CLOUD_MS, nextMove = 0 }
      end
    end
  end
  for i = #g.waves, 1, -1 do
    local w = g.waves[i]
    if t >= w.untilT then table.remove(g.waves, i)
    elseif t >= w.nextMove then                             -- along the arc in short hops
      w.nextMove = t + 700
      local aa = w.a0 + w.sweep * math.min(1, (t + 900 - w.t0) / SE.CLOUD_MS)
      local c = obj(g, w.guid)
      if c then try(c, "MoveTo", 0, SE.CENTER[1] + math.cos(aa) * w.r, SE.CENTER[2] + math.sin(aa) * w.r, SE.CENTER[3] + 0.2) end
    end
  end
  for i = #g.amb, 1, -1 do if t >= g.amb[i].untilT then table.remove(g.amb, i) end end
end
-- v1.4: the live 'Void tentacle' (255652 = the crushing-grasp tentacle: 16 x 3 yd lying along its facing, x2 by the effect, so size 0.25 = the
-- 8-yd dark shards on the live track). It comes down ACROSS a runner's path, 1-3 side by side, catches whoever is under it as it lands and
-- then stays lying there.
-- v1.6d: Void Waves = the orbs. Each starts on the rim of the pit and glides straight out to the wall with its dark blade (Rowan's live pictures 11-19)
local function vwSpawn(g, t, ang, delay)
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  local dx, dy = math.cos(ang), math.sin(ang)
  local life = math.floor((SE.VW_TO - SE.VW_FROM) / SE.VW_SPEED * 1000) + delay + 800
  local c = dummy(g, E.MOVER, cx + dx * SE.VW_FROM, cy + dy * SE.VW_FROM, SE.CENTER[3] + SE.VW_Z, life, SE.VW_SPELL > 0 and SE.VW_SPELL or nil)
  if c then
    if (SE.VW_SCALE or 1) ~= 1 then try(c, "SetScale", SE.VW_SCALE) end   -- v1.6h: 257572 hangs its flat dark missile 9 yd ABOVE the helper; a tiny helper shrinks that offset (the effect itself is locked at size 1). UNTESTED
    if SE.VW_ORB then try(c, "AddAura", S.HOLEVIS, c) end
    try(c, "SetFacing", ang % (2 * math.pi)); try(c, "SetRooted", false)
    try(c, "SetSpeed", 0, SE.VW_SPEED / 2.5, true); try(c, "SetSpeed", 1, SE.VW_SPEED / 7.0, true); try(c, "SetSpeed", 6, SE.VW_SPEED / 7.0, true)
    g.vw[#g.vw + 1] = { guid = c:GetGUID(), dx = dx, dy = dy, t0 = t + delay }
  end
end
local function tickVoidWaves(g, t)
  g.vw = g.vw or {}
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  if g.vwRound ~= g.round then                               -- the row on the rim of the pit at the start of a round (live 267, 794)
    g.vwRound = g.round
    local a0 = math.random() * 2 * math.pi
    for k = 1, SE.VW_START do vwSpawn(g, t, a0 + (k - 1) * 2 * math.pi / SE.VW_START, 2000 + math.random(0, 9000)) end
    g.nextVW = t + (SE.VW_FIRST or 4000)
  end
  if SE.VW_EVERY > 0 and t >= (g.nextVW or 0) then
    g.nextVW = t + math.max(SE.VW_MIN, SE.VW_EVERY - 150 * (g.round - 1)) + math.random(0, SE.VW_JITTER or 0)
    local ang                                                -- v1.6j (Rowan): each on its own bearing, never near the two before it (no 'one big line')
    for _ = 1, 12 do
      ang = math.random() * 2 * math.pi
      local ok = true
      for _, pa in ipairs(g.vwLast or {}) do
        local d = math.abs(ang - pa) % (2 * math.pi); if d > math.pi then d = 2 * math.pi - d end
        if d < (SE.VW_APART or 0) then ok = false end
      end
      if ok then break end
    end
    g.vwLast = g.vwLast or {}; table.insert(g.vwLast, 1, ang); g.vwLast[3] = nil
    vwSpawn(g, t, ang, SE.VW_HOLD or 1500)
  end
  for i = #g.vw, 1, -1 do
    local w = g.vw[i]
    local r = SE.VW_FROM + SE.VW_SPEED * math.max(0, t - w.t0) / 1000
    if r >= SE.VW_TO then
      local c = obj(g, w.guid); if c then c:DespawnOrUnsummon(0) end
      table.remove(g.vw, i)
    else
      if not w.moving and t >= w.t0 then
        w.moving = true
        local c = obj(g, w.guid); if c then try(c, "MoveTo", 0, cx + w.dx * SE.VW_TO, cy + w.dy * SE.VW_TO, SE.CENTER[3] + SE.VW_Z) end
      end
      local wx, wy = cx + w.dx * r, cy + w.dy * r
      eachRunner(g, function(low, m, pl, x, y) if dist2(x, y, wx, wy) <= SE.VW_R then eliminate(g, low, t) end end)
    end
  end
end
-- v1.6d: swirl circles that wander about and shoot you up (Rowan 11-19: 'needs to be moving around randomly and make the player get shot up in the air')
local function tickRoam(g, t)
  if SE.ROAM <= 0 then return end
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  if g.roamRound ~= g.round then
    g.roamRound = g.round; g.roam = {}
    for _ = 1, SE.ROAM do
      local x, y = randSpot(SE.CENTER_FREE + 4, SE.FLOOR_R - 4)
      local c = dummy(g, E.MOVER, x, y, SE.CENTER[3] + 0.1, SE.GAME_TIME * 1000 + 10000, S.ZONEVIS)
      if c then
        try(c, "SetRooted", false)
        try(c, "SetSpeed", 0, SE.ROAM_SPEED / 2.5, true); try(c, "SetSpeed", 1, SE.ROAM_SPEED / 7.0, true); try(c, "SetSpeed", 6, SE.ROAM_SPEED / 7.0, true)
        g.roam[#g.roam + 1] = { guid = c:GetGUID(), nextMove = t + math.random(500, 3000), reAura = t + 10000 }
      end
    end
  end
  for _, h in ipairs(g.roam or {}) do
    local c = obj(g, h.guid)
    if c then
      local hx, hy = c:GetX(), c:GetY()
      if t >= h.reAura then h.reAura = t + 10000; try(c, "AddAura", S.ZONEVIS, c) end
      if t >= h.nextMove then
        h.nextMove = t + SE.ROAM_EVERY + math.random(0, 2500)
        local a = math.random() * 2 * math.pi
        local x, y = hx + math.cos(a) * SE.ROAM_STEP, hy + math.sin(a) * SE.ROAM_STEP
        local r = dist2(x, y, cx, cy)
        local rr = math.max(SE.CENTER_FREE + 3, math.min(SE.FLOOR_R - 2, r))
        if r > 0.1 then x, y = cx + (x - cx) * rr / r, cy + (y - cy) * rr / r end
        try(c, "MoveTo", 0, x, y, SE.CENTER[3] + 0.1)
      end
      eachRunner(g, function(low, m, pl, x, y) if dist2(x, y, hx, hy) <= SE.POOL_R then launchUp(g, m, pl, t) end end)
    end
  end
end
local function tickCones(g, t)                              -- v1.6l: Visual: Void Cone (the purple fog) from the middle outward, then Tentacle Hit (the ground lightning) along it
  g.cones = g.cones or {}
  local cx, cy = SE.CENTER[1], SE.CENTER[2]
  if (SE.CONES or 0) > 0 and g.coneAt and t >= g.coneAt then
    g.coneAt = nil
    local a = anchor(g)
    local used = {}
    for k = 1, SE.CONES do
      local ang
      if k == 1 then
        local x, y = runnerSpot(g, 0)
        if x then ang = (math.atan2 or math.atan)(y - cy, x - cx) + (math.random() - 0.5) * 0.5 end
      end
      for _ = 1, 12 do
        if ang then
          local ok = true
          for _, u in ipairs(used) do
            local d = math.abs(ang - u) % (2 * math.pi); if d > math.pi then d = 2 * math.pi - d end
            if d < 0.9 then ok = false end
          end
          if ok then break end
        end
        ang = math.random() * 2 * math.pi
      end
      used[#used + 1] = ang
      local c = a and a:SpawnCreature(E.STRIKE, cx + math.cos(ang) * SE.CONE_AT, cy + math.sin(ang) * SE.CONE_AT, SE.CENTER[3] + 0.2, ang % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, SE.CONE_WARN + 4000)
      if c then try(c, "AddAura", SE.CONE_SPELL, c) end
      g.cones[#g.cones + 1] = { guid = c and c:GetGUID(), ang = ang, hitAt = t + SE.CONE_WARN, untilT = t + SE.CONE_WARN + SE.CONE_HIT_MS }
    end
  end
  for i = #g.cones, 1, -1 do
    local q = g.cones[i]
    if t >= q.hitAt then
      if not q.hit then
        q.hit = true
        local c = obj(g, q.guid)
        if c then try(c, "RemoveAura", SE.CONE_SPELL); try(c, "CastSpell", c, SE.CONE_HIT, true) end
      end
      eachRunner(g, function(low, m, pl, x, y)
        local r = dist2(x, y, cx, cy)
        if r >= SE.CONE_R0 and r <= SE.CONE_LEN then
          local d = math.abs((math.atan2 or math.atan)(y - cy, x - cx) - q.ang) % (2 * math.pi); if d > math.pi then d = 2 * math.pi - d end
          if d <= SE.CONE_HALF then eliminate(g, low, t) end
        end
      end)
      if t >= q.untilT then table.remove(g.cones, i) end
    end
  end
end
local function tickTentacles(g, t)                          -- v1.6: one standing trunk ahead of a runner (sometimes a second near it); it catches at its base
  if SE.TENT_EVERY > 0 and t >= g.nextTent then
    g.nextTent = t + math.max(SE.TENT_MIN, SE.TENT_EVERY - 600 * (g.round - 1))
    local x, y = runnerAhead(g, 11 + math.random() * 7)
    local a = anchor(g)
    if x and a then
      local n = math.random(1, math.max(1, SE.TENT_N))
      for k = 1, n do
        local sx, sy = x, y
        if k > 1 then
          local ang, d = math.random() * 2 * math.pi, SE.TENT_SPREAD * (0.6 + math.random() * 0.6)
          sx, sy = x + math.cos(ang) * d, y + math.sin(ang) * d
        end
        local r = dist2(sx, sy, SE.CENTER[1], SE.CENTER[2])
        if k == 1 or (r >= SE.CENTER_FREE + 1 and r <= SE.FLOOR_R) then
          local c = a:SpawnCreature(E.TENTACLE, sx, sy, SE.CENTER[3] + 0.1, math.random() * 2 * math.pi, TEMPSUMMON_TIMED_DESPAWN, SE.TENT_LIFE + 500)
          if c then try(c, "AddAura", S.TENT, c) end
          g.tents[#g.tents + 1] = { guid = c and c:GetGUID(), x = sx, y = sy, armAt = t + SE.TENT_ARM,
                                    hitUntil = t + SE.TENT_ARM + SE.TENT_HIT, untilT = t + SE.TENT_LIFE }
        end
      end
    end
  end
  for i = #g.tents, 1, -1 do
    local q = g.tents[i]
    if t >= q.untilT then table.remove(g.tents, i)
    elseif t >= q.armAt and (SE.TENT_HIT <= 0 or t <= q.hitUntil) then
      eachRunner(g, function(low, m, pl, x, y)
        if dist2(x, y, q.x, q.y) <= SE.TENT_R then
          if not q.hit then q.hit = true; local c = obj(g, q.guid); if c then try(c, "CastSpell", c, S.TENTHIT, true) end end
          eliminate(g, low, t)
        end
      end)
    end
  end
end
-- v1.4: revives as on live: the 30 s 'Void Consumption' cast is the window; a companion who reaches you frees you (no charge), you get the
-- golden pillar and he runs on with the golden trail too; 10 s in comes the 'was not revived in time' line (only a line).
local function revive(g, low, t, by)                        -- by = the reviver's key, nil = the Light (alone)
  local m = g.members[low]
  m.down = nil; m.aegisUntil = t + SE.AEGIS_MS
  local c = rideOf(g, m)
  if c then try(c, "EmoteState", 0); try(c, "StopSpellCast", S.CONSUME); try(c, "InterruptSpell", 1); try(c, "RemoveAura", S.HIT); try(c, "RemoveAura", S.VSTUN); try(c, "AddAura", S.AEGIS, c) end
  hold(c, false)
  local m2 = by and g.members[by]
  if m2 then
    m2.aegisUntil = t + SE.AEGIS_MS
    local c2 = rideOf(g, m2); if c2 then try(c2, "AddAura", S.AEGIS, c2) end
    m2.revived = (m2.revived or 0) + 1
    m2.revTimes = m2.revTimes or {}; m2.revTimes[#m2.revTimes + 1] = t
    local p2, n = getPlayer(g, by), #m2.revTimes
    giveAch(p2, ACH.HAND)
    if m2.revived >= 8 then giveAch(p2, ACH.CREW) end
    if n >= 3 and t - m2.revTimes[n - 2] <= 10000 then giveAch(p2, ACH.PASSING) end
  end
end
local function tickRevives(g, t)
  local solo = g.count <= 1
  for low, m in pairs(g.members) do
    if m.down then
      local pl = getPlayer(g, low)
      local by, light
      if pl then
        if solo then
          if g.revives > 0 and t > m.down + SE.SOLO_REVIVE then light = true end   -- OURS: alone, the one charge frees you
        else
          for l2, m2 in pairs(g.members) do
            local p2 = getPlayer(g, l2)
            if l2 ~= low and not m2.down and not m2.out and inGame(g, p2) and dist2(pl:GetX(), pl:GetY(), p2:GetX(), p2:GetY()) <= SE.REVIVE_R then by = l2 end
          end
        end
      end
      if by or light then
        if light then g.revives = g.revives - 1; tell(g, VT .. "The Light frees you. Combat Resurrection Charges Remaining: " .. g.revives) end
        revive(g, low, t, by)
      elseif t > m.down + SE.REVIVE_WINDOW then             -- the cast ran out: lost for this round (the blue circle)
        m.down = nil; m.out = true
        local c = rideOf(g, m); if c then hold(c, true); try(c, "AddAura", S.VSTUN, c) end
      elseif not m.lateSaid and t > m.down + SE.LATE_MSG then
        m.lateSaid = true
        tell(g, VT .. RED .. m.name .. "|r was not revived in time and remains eliminated!", true)
      end
    end
  end
end

-- ---------- leaving ----------
local function sendHome(g, low)
  local m = g.members[low]
  local pl = getPlayer(g, low)
  if not (m and pl) then return end
  hudOff(pl)                                                -- v1.2
  dropRide(g, low, pl)
  local h = m.home or SE.FAIRE_SPOT
  later(m.guid, 600, function(p) if p:GetMapId() == SE.MAP then p:Teleport(h[1], h[2], h[3], h[4], h[5]) end end)
end
local function clearRound(g)                                -- everything a round put on the floor
  for _, cr in pairs(g.crystals) do local c = obj(g, cr.guid); if c then c:DespawnOrUnsummon(0) end end
  for _, list in ipairs({ g.strikes, g.pools, g.holes, g.tents, g.drift or {}, g.amb or {}, g.waves or {}, g.vw or {}, g.roam or {} }) do
    for _, s in ipairs(list) do local c = obj(g, s.guid); if c then c:DespawnOrUnsummon(0) end end
  end
  for _, guid in ipairs(g.rings or {}) do local c = obj(g, guid); if c then c:DespawnOrUnsummon(0) end end   -- v1.2c
  g.crystals = {}; g.crystalCount = 0; g.strikes = {}; g.pools = {}; g.holes = {}; g.tents = {}; g.vw = {}; g.nextVW = nil; g.roam = {}; g.drift = {}; g.amb = {}; g.rings = {}; g.waves = {}; g.fogQ = {}; g.fogAt = nil; g.cones = {}; g.coneAt = nil; g.pops = {}; g.ripQ = {}; g.halos = {}
end
-- v1.3a: the void look exists only during a round (live: between rounds it is the plain lit tent)
-- v1.5: live keeps the dark sky, the blue rim and the standing tentacles from zone-in on; the Eye alone comes and goes with the round
local function pitOff(g)                                    -- v1.6: the pit helper and the trunks on its rim
  local pit = obj(g, g.pitGuid); if pit then pit:DespawnOrUnsummon(0) end
  for _, guid in ipairs(g.pitTentGuids or {}) do local c = obj(g, guid); if c then c:DespawnOrUnsummon(0) end end
  g.pitGuid, g.pitTentGuids = nil, {}; g.skirtGuid = nil
end
local function eyeOff(g)
  local eye = obj(g, g.eyeGuid); if eye then eye:DespawnOrUnsummon(0) end
  pitOff(g)
  g.eyeGuid, g.voidUp = nil, false
end
local function spawnPit(g, a)                               -- v1.6 UNTESTED: the piercing-gaze iris lying on the floor + tall trunks on its rim
  pitOff(g)
  if (SE.PIT_SPELL or 0) > 0 then
    local pit = a:SpawnCreature(E.PIT, SE.CENTER[1], SE.CENTER[2], SE.CENTER[3] + SE.PIT_Z, SE.ARRIVE_ANG % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if pit then g.pitGuid = pit:GetGUID(); try(pit, "AddAura", SE.PIT_SPELL, pit) end
  end
  if (SE.SKIRT_SCALE or 0) > 0 then                          -- v1.6k UNTESTED ('#se skirt <size>' / '#se skirt off'): the black floor round the pit on its own helper
    local sk = a:SpawnCreature(E.PIT, SE.CENTER[1], SE.CENTER[2], SE.CENTER[3] + 0.2, 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if sk then try(sk, "SetScale", SE.SKIRT_SCALE); try(sk, "AddAura", SE.SKIRT_SPELL, sk); g.pitTentGuids[#g.pitTentGuids + 1] = sk:GetGUID(); g.skirtGuid = sk:GetGUID() end
  end
  for k = 1, SE.PIT_TENTS do
    local ang = SE.ARRIVE_ANG + (k - 0.5) * 2 * math.pi / SE.PIT_TENTS
    local w = a:SpawnCreature(E.TENTACLE, SE.CENTER[1] + math.cos(ang) * SE.PIT_R, SE.CENTER[2] + math.sin(ang) * SE.PIT_R, SE.CENTER[3], ang % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if w then try(w, "AddAura", S.TENT, w); g.pitTentGuids[#g.pitTentGuids + 1] = w:GetGUID() end
  end
end
local function voidOff(g)                                   -- everything (the game closes, '#se void')
  eyeOff(g)
  local sky = obj(g, g.skyGuid); if sky then sky:DespawnOrUnsummon(0) end
  local rim = obj(g, g.rimGuid); if rim then rim:DespawnOrUnsummon(0) end; g.rimGuid = nil
  for _, guid in ipairs(g.wallGuids or {}) do local c = obj(g, guid); if c then c:DespawnOrUnsummon(0) end end
  g.skyGuid, g.wallGuids, g.skyUp = nil, {}, false
end
local function spawnEye(g, a)                               -- v1.4: N'Zoth's eye (255629) on a small helper high over the pit, facing the arrival side
  local old = obj(g, g.eyeGuid); if old then old:DespawnOrUnsummon(0) end
  local roam = (SE.EYE_ROAM or 0) > 0                       -- v1.6g: on the un-rooted helper, flying, so it can move (99560 is rooted in the database)
  local eye = a:SpawnCreature(roam and E.MOVER or E.EYE, SE.CENTER[1] + SE.EYE_AT[1], SE.CENTER[2] + SE.EYE_AT[2], SE.CENTER[3] + SE.EYE_AT[3], SE.ARRIVE_ANG % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if eye then
    g.eyeGuid = eye:GetGUID(); try(eye, "SetScale", SE.EYE_SCALE)
    if roam then
      try(eye, "SetRooted", false); try(eye, "SetDisableGravity", true); try(eye, "SetHover", true)   -- the pattern Bullet Romper's flying helpers use
      try(eye, "SetSpeed", 0, SE.EYE_SPEED / 2.5, true); try(eye, "SetSpeed", 1, SE.EYE_SPEED / 7.0, true); try(eye, "SetSpeed", 6, SE.EYE_SPEED / 7.0, true)
      g.eyeMoveAt = now() + 800
    end
    try(eye, "AddAura", SE.EYE_SPELL, eye)
  end
end
local function spawnSky(g, a)                               -- v1.4: the realm (dome, pit, fire, outer tentacles) at FLOOR level in the middle + the dark outer ring with the blue rim
  local old = obj(g, g.skyGuid); if old then old:DespawnOrUnsummon(0) end
  local sky = a:SpawnCreature(E.SKY, SE.CENTER[1], SE.CENTER[2], SE.CENTER[3] + SE.SKY_Z, 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if sky then
    g.skyGuid = sky:GetGUID()
    if SE.SKY_SCALE ~= 1 then try(sky, "SetScale", SE.SKY_SCALE) end
    try(sky, "AddAura", S.SKY, sky)
    if SE.SKY_RING and not SE.RIM_MOVE then try(sky, "AddAura", S.SKY2, sky) end
    if SE.SKY_RING and SE.RIM_MOVE then                     -- v1.6l: the dark outer ring on its own helper, so it can close in and open again
      local oldRim = obj(g, g.rimGuid); if oldRim then oldRim:DespawnOrUnsummon(0) end
      local rim = a:SpawnCreature(E.SKY, SE.CENTER[1], SE.CENTER[2], SE.CENTER[3] + SE.SKY_Z, 0, TEMPSUMMON_TIMED_DESPAWN, LIFE)
      if rim then g.rimGuid = rim:GetGUID(); g.rimScale = SE.SKY_SCALE; try(rim, "SetScale", SE.SKY_SCALE); try(rim, "AddAura", S.SKY2, rim) end
    end
  end
end
local function skyOn(g)                                     -- v1.5: the lobby look: sky + rim + standing tentacles
  if g.skyUp and obj(g, g.skyGuid) then return end
  local a = anchor(g)
  if not a then return end
  for _, guid in ipairs(g.wallGuids or {}) do local c = obj(g, guid); if c then c:DespawnOrUnsummon(0) end end
  g.wallGuids = {}
  for k = 1, SE.WALL_TENTS do                              -- off since v1.4 (the realm has its own); kept for trying
    local ang = (k - 1) * 2 * math.pi / SE.WALL_TENTS
    local w = a:SpawnCreature(E.TENTACLE, SE.CENTER[1] + math.cos(ang) * SE.WALL_R, SE.CENTER[2] + math.sin(ang) * SE.WALL_R, SE.CENTER[3], (ang + math.pi) % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, LIFE)
    if w then try(w, "SetScale", SE.WALL_SCALE); try(w, "AddAura", S.TENT, w); g.wallGuids[#g.wallGuids + 1] = w:GetGUID() end
  end
  spawnSky(g, a)
  g.skyUp = true
end
local function voidOn(g)                                    -- the round look: the lobby look + the Eye
  local a = anchor(g)
  if not a then return end
  skyOn(g)
  spawnEye(g, a)
  spawnPit(g, a)
  g.voidUp = true
end
local function tickEye(g, t)                                -- v1.6g: live (burst 16-18.3 s, camera still): the Eye drifts about over the pit, a few yards a second, up and down too;
  if SE.RIM_MOVE and g.rimGuid and g.state == "playing" and g.startedAt then   -- v1.6l (Rowan): the black comes closer to the centre and goes back
    local ph = (t - g.startedAt) % (SE.RIM_CLOSE + SE.RIM_HOLD + SE.RIM_OPEN + SE.RIM_REST)
    local f = 0
    if ph < SE.RIM_CLOSE then f = ph / SE.RIM_CLOSE
    elseif ph < SE.RIM_CLOSE + SE.RIM_HOLD then f = 1
    elseif ph < SE.RIM_CLOSE + SE.RIM_HOLD + SE.RIM_OPEN then f = 1 - (ph - SE.RIM_CLOSE - SE.RIM_HOLD) / SE.RIM_OPEN end
    local sc = SE.SKY_SCALE + (SE.RIM_IN - SE.SKY_SCALE) * f
    if math.abs(sc - (g.rimScale or 0)) > 0.004 then g.rimScale = sc; local rc = obj(g, g.rimGuid); if rc then try(rc, "SetScale", sc) end end
    if SE.RIM_CATCH and f > 0.15 then                        -- v1.6m (Rowan: it limits players movements): whoever is well out in the black is caught
      local lim = SE.RIM_R0 * sc / SE.SKY_SCALE + SE.RIM_MARGIN
      eachRunner(g, function(low, m, pl, x, y) if dist2(x, y, SE.CENTER[1], SE.CENTER[2]) > lim then eliminate(g, low, t) end end)
    end
  end
  if g.skirtGuid and t >= (g.skirtAt or 0) then              -- v1.6k: the test skirt's look is put back if its aura has run out
    g.skirtAt = t + 3000
    local sk = obj(g, g.skirtGuid)
    if sk then local has = false; pcall(function() has = sk:HasAura(SE.SKIRT_SPELL) end); if not has then try(sk, "AddAura", SE.SKIRT_SPELL, sk) end end
  end
  if (SE.EYE_ROAM or 0) <= 0 or t < (g.eyeMoveAt or 0) then return end   --   Rowan: 'the eye is suppose to move around at random like its searching for players'
  local eye = obj(g, g.eyeGuid)
  if not eye then return end
  g.eyeMoveAt = t + SE.EYE_EVERY + math.random(0, 1500)
  local a, r = math.random() * 2 * math.pi, math.random() * SE.EYE_ROAM
  local tx, ty
  if math.random(2) == 1 then tx, ty = runnerSpot(g, 0) end    -- half the time it leans out toward somebody who is running
  if tx then a = (math.atan2 or math.atan)(ty - SE.CENTER[2], tx - SE.CENTER[1]); r = SE.EYE_ROAM * (0.5 + math.random() * 0.5) end
  try(eye, "MoveTo", 0, SE.CENTER[1] + math.cos(a) * r, SE.CENTER[2] + math.sin(a) * r, SE.CENTER[3] + SE.EYE_Z_LO + math.random() * (SE.EYE_Z_HI - SE.EYE_Z_LO), false)
end
local function cleanup(g, why)
  for low, _ in pairs(g.members or {}) do music(getPlayer(g, low), SE.MUSIC_LEAVE_ID) end   -- v1.6n
  clearRound(g)
  voidOff(g)
  local sn = obj(g, g.snaggGuid); if sn then sn:DespawnOrUnsummon(0) end   -- v1.3a
  local po = obj(g, g.portalGuid); if po then po:DespawnOrUnsummon(0) end  -- v1.4
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl then try(pl, "RemoveAura", S.READY) end
    if pl and inGame(g, pl) then sendHome(g, low) else local c = rideOf(g, m); if c then c:DespawnOrUnsummon(0) end end
  end
  if g.inst then Games[g.inst] = nil end
  log("game closed (" .. tostring(why) .. ")")
end

-- ---------- the game ----------
local function bigCountdown(pl, ms)                         -- the client draws the big numbers itself (found for the Rainbow Race, v2.1.4)
  if not (SE.BIG_COUNTDOWN and pl and type(CreatePacket) == "function") then return false end
  local ok, err = pcall(function() local pk = CreatePacket(OP_COUNTDOWN, 4); pk:WriteULong(ms); pl:SendPacket(pk) end)
  if not ok then log("could not send the countdown packet: " .. tostring(err)) end
  return ok
end
local function sweepGone(g, t)                              -- players who left the map drop out after 15 s
  for low, m in pairs(g.members) do
    if inGame(g, getPlayer(g, low)) then m.goneSince = nil
    else
      m.goneSince = m.goneSince or t
      if t > m.goneSince + 15000 then
        local c = rideOf(g, m); if c then c:DespawnOrUnsummon(0) end
        music(getPlayer(g, low), SE.MUSIC_LEAVE_ID); g.members[low] = nil; g.count = math.max(0, g.count - 1); log(m.name .. " left the game")
      end
    end
  end
end
local function snaggOff(g)                                  -- v1.6c: Snagg is not in the arena while a round runs (Rowan 11-19)
  local sn = obj(g, g.snaggGuid); if sn then sn:DespawnOrUnsummon(0) end
  g.snaggGuid = nil
end
local function spawnSnagg(g, a)
  if obj(g, g.snaggGuid) then return end
  local sn = a:SpawnCreature(E.SNAGG, SE.CENTER[1] + math.cos(SE.ARRIVE_ANG) * SE.SNAGG_R, SE.CENTER[2] + math.sin(SE.ARRIVE_ANG) * SE.SNAGG_R,
                             SE.CENTER[3] + 0.3, SE.ARRIVE_ANG % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if sn then g.snaggGuid = sn:GetGUID() end
end
local function portalOff(g)                                 -- v1.6g: no Faire portal while a round runs (Rowan 11-19; live shows it in the lobby only)
  local po = obj(g, g.portalGuid); if po then po:DespawnOrUnsummon(0) end
  g.portalGuid = nil
end
local function spawnPortal(g, a)
  if obj(g, g.portalGuid) then return end
  local pa = SE.ARRIVE_ANG + SE.PORTAL_ANG                  -- v1.4: the way out, as on live (the blue orb 'Azzar Faire Portal')
  local po = a:SpawnCreature(E.PORTAL, SE.CENTER[1] + math.cos(pa) * SE.PORTAL_R, SE.CENTER[2] + math.sin(pa) * SE.PORTAL_R, SE.CENTER[3] + 0.3, (pa + math.pi) % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, LIFE)
  if po then g.portalGuid = po:GetGUID() end
end
local function openLobby(g, t)                              -- between rounds: on foot in the arena, ready check
  clearRound(g)
  local a0 = anchor(g); if a0 then spawnSnagg(g, a0); spawnPortal(g, a0) end      -- v1.6c: Snagg is back between rounds
  if SE.SKY_LOBBY then eyeOff(g); skyOn(g) else voidOff(g) end   -- v1.5 (v1.3a took the whole void away between rounds)
  g.round = g.round + 1
  g.state = "lobby"; g.lobbyAt = t
  for low, m in pairs(g.members) do
    local pl = getPlayer(g, low)
    if pl then dropRide(g, low, pl); hudOff(pl) end          -- v1.2: no HUD between rounds
    m.ready = nil; m.down = nil; m.out = nil; m.aegisUntil = nil; m.score = 0; m.hits = 0; m.revived = 0; m.revTimes = nil; m.cq = nil; m.lateSaid = nil
  end
  g.total = 0; g.revives = SE.REVIVES
  if g.round == 1 then tell(g, VT .. "Tell Snagg you are ready (or say #ready) when you can see the arena. The Azzar Faire Portal or #leave takes you back to the Faire.")
  else tell(g, VT .. string.format("Round %d of %d: say #ready (it starts by itself in %d s). #leave = back to the Faire.", g.round, SE.ROUNDS, SE.LOBBY_AUTO / 1000)) end
end
local function slotSpot(m)                                  -- where a player stands between rounds (side by side on the arrival side)
  local ang = SE.ARRIVE_ANG + ((m.slot or 3) - 3) * 0.08
  return SE.CENTER[1] + SE.ARRIVE_R * math.cos(ang), SE.CENTER[2] + SE.ARRIVE_R * math.sin(ang), SE.CENTER[3] + 0.5, (ang + math.pi) % (2 * math.pi)
end
local function endRound(g, t, survived)
  for low, _ in pairs(g.members) do music(getPlayer(g, low), survived and SE.MUSIC_WIN_ID or SE.MUSIC_END_ID) end   -- v1.6n: only a new track cuts the old one
  local rc0 = obj(g, g.rimGuid); if rc0 then try(rc0, "SetScale", SE.SKY_SCALE) end; g.rimScale = SE.SKY_SCALE
  g.state = "roundend"; g.doneAt = t
  local order = {}
  for low, _ in pairs(g.members) do order[#order + 1] = low end
  table.sort(order, function(a, b) return g.members[a].score > g.members[b].score end)
  local allAlive, nStand = true, 0
  for _, m in pairs(g.members) do if m.out or m.down then allAlive = false else nStand = nStand + 1 end end
  if survived then                                          -- live order (frame 765): 'Shadow Eye and friends', the tickets, '[VOID] Victory!', the other achievements, then the scores
    for _, low in ipairs(order) do
      local m, pl = g.members[low], getPlayer(g, low)
      if pl and inGame(g, pl) then
        giveAch(pl, ACH.FRIENDS)
        if not m.rewarded then                              -- once per visit: the first round somebody outlasts the clock
          m.rewarded = true
          try(pl, "AddItem", ITEM_TICKET, SE.TICKETS)
          if pl:HasQuest(Q_BASE) or pl:HasQuest(Q_DAILY) then pl:KilledMonsterCredit(E.CREDIT) end
        end
      end
    end
  end
  local endSteps = { { at = t + SE.END_OVER, lines = { VT .. (survived and "Victory!" or "Game Over.") } } }   -- v1.6h: the lines come in steps (live 091-105)
  if survived then
    for _, low in ipairs(order) do
      local m, pl = g.members[low], getPlayer(g, low)
      if pl and inGame(g, pl) and not m.out and not m.down then
        giveAch(pl, ACH.STAND); giveAch(pl, ACH.NOTOUCH)
        if (m.hits or 0) == 0 and m.score == 0 then giveAch(pl, ACH.DODGE) end
        if g.count >= 2 and allAlive then giveAch(pl, ACH.ALLALIVE); giveAch(pl, ACH.NOBODY) end
        if g.count >= 2 and nStand == 1 and m.score >= 888 then giveAch(pl, ACH.ONLY) end
      end
    end
  end
  g.timerSaid = nil
  local sc = { VT .. "Void Event Points: |cff40c0ff" .. g.total .. "|r", VT .. "Final scores:" }
  for i, low in ipairs(order) do
    local m = g.members[low]
    sc[#sc + 1] = VT .. string.format("#%d %s - %d pts", i, m.name, m.score)
  end
  endSteps[#endSteps + 1] = { at = t + SE.END_SCORES, lines = sc }
  g.endSteps = endSteps; g.completeSaid = nil
  clearRound(g)                                             -- v1.4: live: the round is over = the void is gone and everybody stands on foot together in the lit tent
  if SE.SKY_LOBBY then eyeOff(g) else voidOff(g) end
  for _, low in ipairs(order) do
    local m, pl = g.members[low], getPlayer(g, low)
    if pl and inGame(g, pl) then
      dropRide(g, low, pl); hudAfter(g, pl)
      if SE.END_GATHER then                                  -- v1.6h: live leaves everybody where he stood (095-104: they walk back to Snagg)
        local x, y, z, o = slotSpot(m)
        later(m.guid, 500, function(p) if p:GetMapId() == SE.MAP and Games[g.inst] == g then p:NearTeleport(x, y, z, o) end end)
      end
    end
  end
  local a9 = anchor(g); if a9 then spawnPortal(g, a9) end   -- v1.6h: the portal is back as soon as the round is over (live 099)
  g.last = g.round >= SE.ROUNDS
  log(string.format("round %d over: %s, %d crystals, %d player(s)", g.round, survived and "survived" or "lost", g.total, #order))
end
local function tickGame(g, t)
  if g.state == "arriving" then
    local allIn = true
    for low, _ in pairs(g.members) do if not inGame(g, getPlayer(g, low)) then allIn = false end end
    if (allIn and t >= g.arrivedAt + SE.ARRIVE_WAIT) or t >= g.arrivedAt + SE.ARRIVE_MAX then
      for low, _ in pairs(g.members) do
        if not inGame(g, getPlayer(g, low)) then g.members[low] = nil; g.count = math.max(0, g.count - 1) end
      end
      local a = anchor(g)
      if a then
        for _, e in ipairs({ E.CRYSTAL, E.STRIKE, E.SKY, E.EYE, E.TENTACLE, E.POOL, E.HOLE, E.SNAGG, E.PORTAL, E.MOVER }) do   -- v1.2b: sweep an earlier game's leftovers
          local list = try(a, "GetCreaturesInRange", 170, e)
          for _, c in ipairs(type(list) == "table" and list or {}) do c:DespawnOrUnsummon(0) end
        end
        spawnSnagg(g, a)                                     -- v1.3a: Snagg is in there with you (v1.6c: in the lobby only)
        spawnPortal(g, a)                                    -- v1.4 / v1.6g: the way out, in the lobby only
      end
      openLobby(g, t)
    end
  elseif g.state == "lobby" then
    sweepGone(g, t)
    local allReady, n = true, 0
    for low, m in pairs(g.members) do
      if inGame(g, getPlayer(g, low)) then n = n + 1; if not m.ready then allReady = false end end
    end
    local auto = g.round > 1 and t >= g.lobbyAt + SE.LOBBY_AUTO
    if n > 0 and (allReady or auto) then
      g.bigOk = true
      local slots = {}
      for low, _ in pairs(g.members) do if inGame(g, getPlayer(g, low)) then slots[#slots + 1] = low end end
      table.sort(slots)
      for i, low in ipairs(slots) do
        local m, pl = g.members[low], getPlayer(g, low)
        try(pl, "RemoveAura", S.READY)
        m.busyUntil = t + 4000
        if not bigCountdown(pl, SE.COUNTDOWN * 1000) then g.bigOk = false end
        if SE.START_SPREAD then                              -- v1.6h: live: the swirl on each player at "5", then at "4" he stands alone on his slot as the dwarf
          local ang = SE.ARRIVE_ANG + (i - 1) * 2 * math.pi / #slots
          local sx, sy = SE.CENTER[1] + math.cos(ang) * SE.START_R, SE.CENTER[2] + math.sin(ang) * SE.START_R
          if SE.START_SWIRL then try(pl, "AddAura", S.VSTUN, pl); later(m.guid, 250, function(p) try(p, "RemoveAura", S.VSTUN) end) end
          later(m.guid, 1000, function(p)
            try(p, "RemoveAura", S.VSTUN)
            if Games[g.inst] ~= g or not g.members[low] or p:GetMapId() ~= SE.MAP then return end
            p:NearTeleport(sx, sy, SE.CENTER[3] + 0.5, (ang + math.pi) % (2 * math.pi))
          end)
          later(m.guid, 1600, function(p)
            if Games[g.inst] ~= g or not g.members[low] or p:GetMapId() ~= SE.MAP then return end
            if g.state ~= "countdown" and g.state ~= "playing" then return end
            if not rideOf(g, g.members[low]) and not board(g, low, p) then p:SendBroadcastMessage(VT .. "Could not make you an archaeologist: click the dwarf to take over.") end
          end)
        elseif not board(g, low, pl) then pl:SendBroadcastMessage(VT .. "Could not make you an archaeologist: click the dwarf to take over.") end
      end
      -- v1.6d: no crystals before the count; they fall in during it (below)
      g.state = "countdown"; g.countAt = t; g.lastCount = nil
      g.hudKey = nil; hudShow(g, SE.GAME_TIME)               -- v1.2: the HUD comes up with the countdown
      tell(g, AZT .. "Round " .. g.round .. " is starting!")
      snaggOff(g)                                            -- v1.6c
      if g.round == 1 then tell(g, VT .. "Collect the Light Crystals and keep running. If the Void catches a companion, run to them to free them. Say #leave to go back to the Faire.") end
    elseif t > g.lobbyAt + SE.LOBBY_IDLE then cleanup(g, "nobody readied up"); return
    end
  elseif g.state == "countdown" then
    pcall(tickEye, g, t)                                    -- v1.6g
    local n = SE.COUNTDOWN - math.floor((t - g.countAt) / 1000)
    if n ~= g.lastCount then
      g.lastCount = n
      if n > 0 then
        if n <= SE.CRYSTAL_COUNT_AT then for _ = 1, SE.CRYSTAL_START do if g.crystalCount >= SE.CRYSTALS then break end; spawnGroup(g, true) end end   -- v1.6g: live 016-020: none at 5, 4, 3; they are in the air at 2 and 1
        if n <= 3 then portalOff(g) end                       -- v1.6i: live still shows the portal at "5" (116)
        if n <= SE.VOID_AT and not g.voidUp then voidOn(g) end   -- v1.4: live: the pit and the Eye appear at '3'
        if not g.bigOk then tell(g, VT .. n .. "...", tostring(n)) end
      else
        if not g.voidUp then voidOn(g) end
        portalOff(g)
        g.state = "playing"; g.startedAt = t; g.endAt = t + SE.GAME_TIME * 1000; for low, _ in pairs(g.members) do music(getPlayer(g, low), SE.MUSIC_ID) end
        g.nextMark = t + SE.MARK_FIRST; g.markUntil = 0; g.nextCrystal = 0; g.nextStrike = t + 4000; g.nextTent = t + 7000; g.nextHole = t + 9000; g.nextBoard = t + 60000; g.nextAmb = t + 1000; g.nextCloud = t + 12000
        local okd, errd = pcall(startDrift, g); if not okd then log("drift error: " .. tostring(errd)) end   -- v1.2
        for _, m in pairs(g.members) do hold(rideOf(g, m), false) end
        if not g.bigOk then tell(g, VT .. "Run! End of Game: " .. mmss(SE.GAME_TIME), "RUN!") end   -- v1.6h: live shows no text at GO (the crest of the big countdown only)
        log("round " .. g.round .. " started with " .. g.count .. " player(s)")
      end
    end
  elseif g.state == "playing" then
    local alive = 0
    for low, m in pairs(g.members) do
      local pl = getPlayer(g, low)
      if inGame(g, pl) then
        m.goneSince = nil
        if not m.down and not m.out then
          alive = alive + 1
          collect(g, low, pl, pl:GetX(), pl:GetY())
          if dist2(pl:GetX(), pl:GetY(), SE.CENTER[1], SE.CENTER[2]) > 110 or pl:GetZ() < SE.CENTER[3] - 15 then   -- out of the tent
            dropRide(g, low, pl); pl:NearTeleport(SE.CENTER[1] + math.cos(SE.ARRIVE_ANG) * SE.ARRIVE_R, SE.CENTER[2] + math.sin(SE.ARRIVE_ANG) * SE.ARRIVE_R, SE.CENTER[3] + 0.5, (SE.ARRIVE_ANG + math.pi) % (2 * math.pi)); m.busyUntil = t + 2500
            later(m.guid, 800, function(p) if Games[g.inst] == g and g.members[low] and g.state == "playing" then board(g, low, p) end end)
          elseif not rideOf(g, m) and t > (m.busyUntil or 0) then m.busyUntil = t + 3000; board(g, low, pl) end
        elseif m.down then alive = alive + 1 end           -- still savable
      else
        m.goneSince = m.goneSince or t
        if t > m.goneSince + 15000 then
          local c = rideOf(g, m); if c then c:DespawnOrUnsummon(0) end
          music(getPlayer(g, low), SE.MUSIC_LEAVE_ID); g.members[low] = nil; g.count = math.max(0, g.count - 1); log(m.name .. " left the game")
        end
      end
    end
    if SE.MARK_EVERY > 0 and t >= (g.nextMark or 0) then    -- v1.6g: the Void Meteor mark on everybody who is still running (live: 4:42, 4:22, ... of a 5:00 round)
      g.nextMark = t + SE.MARK_EVERY; g.markUntil = t + SE.MARK_MS; g.fogAt = t + SE.FOG_AFTER; g.coneAt = t + SE.CONE_AFTER
      for _, m in pairs(g.members) do
        if not m.down and not m.out then local rd = rideOf(g, m); if rd then try(rd, "AddAura", S.MARK, rd) end end
      end
    end
    local ok, err = pcall(tickStrikes, g, t); if not ok then log("strike error: " .. tostring(err)) end
    ok, err = pcall(tickEye, g, t); if not ok then log("eye error: " .. tostring(err)) end
    ok, err = pcall(tickHoles, g, t); if not ok then log("black hole error: " .. tostring(err)) end
    ok, err = pcall(tickTentacles, g, t); if not ok then log("tentacle error: " .. tostring(err)) end
    ok, err = pcall(tickCones, g, t); if not ok then log("cone error: " .. tostring(err)) end
    ok, err = pcall(tickVoidWaves, g, t); if not ok then log("void wave error: " .. tostring(err)) end
    ok, err = pcall(tickRoam, g, t); if not ok then log("roam error: " .. tostring(err)) end
    ok, err = pcall(tickRevives, g, t); if not ok then log("revive error: " .. tostring(err)) end
    ok, err = pcall(tickDrift, g, t); if not ok then log("drift error: " .. tostring(err)) end      -- v1.2
    ok, err = pcall(tickAmb, g, t); if not ok then log("ambience error: " .. tostring(err)) end     -- v1.2
    hudShow(g, (g.endAt - t) / 1000)                        -- v1.2
    g.timerSaid = g.timerSaid or {}
    local leftMs = g.endAt - t
    for _, sec in ipairs(SE.TIMER_AT) do                    -- v1.4: live '[TIMER] 3 minutes remaining!' ... '[TIMER] 1s remaining!', '[TIMER] 0s remaining!'
      if not g.timerSaid[sec] and leftMs <= sec * 1000 and leftMs > sec * 1000 - 1300 then
        g.timerSaid[sec] = true
        local line = sec >= 60 and string.format("%d minute%s remaining!", sec / 60, sec >= 120 and "s" or "") or string.format("%ds remaining!", sec)
        tell(g, "|cffffa040[TIMER]|r " .. line, true)
      end
    end
    tickFalls(g, t)                                         -- v1.2c
    if g.crystalCount < SE.CRYSTALS and t >= (g.nextCrystal or 0) then g.nextCrystal = t + SE.CRYSTAL_EVERY; spawnGroup(g, true) end   -- v1.6g: one by one                                 -- v1.2a: one line or cluster at a time
    if SE.CHAT_BOARD and t >= g.nextBoard and g.endAt - t > 20000 then
      g.nextBoard = t + 60000
      tell(g, VT .. string.format("End of Game: %s   Collected Crystals: %d   Combat Resurrection Charges Remaining: %d", mmss((g.endAt - t) / 1000), g.total, g.revives))
    end
    local standing, downs = 0, 0
    for _, m in pairs(g.members) do if m.down then downs = downs + 1 elseif not m.out then standing = standing + 1 end end
    if t >= g.endAt then endRound(g, t, standing > 0)
    elseif standing == 0 and not (g.count <= 1 and downs > 0 and g.revives > 0) then endRound(g, t, false) end   -- v1.4: live: Game Over as soon as nobody is running (alone: your charge still gets its 3 s)
  elseif g.state == "roundend" then
    sweepGone(g, t)
    for _, st in ipairs(g.endSteps or {}) do
      if not st.done and t >= st.at then st.done = true; for _, line in ipairs(st.lines) do tell(g, line, true) end end
    end
    if not g.completeSaid and t > g.doneAt + SE.ROUND_GAP then
      g.completeSaid = true; g.endSteps = nil
      if g.last then
        tell(g, AZT .. "Round " .. g.round .. " is complete.", "Round " .. g.round .. " is complete.")
        tell(g, VT .. "That was the last round. Back to the Faire in a few seconds.")
      else
        local line = string.format("Round %d is complete. Round %d is now available!", g.round, g.round + 1)
        tell(g, AZT .. line, line)
        for low, _ in pairs(g.members) do hudOff(getPlayer(g, low)) end
        openLobby(g, t)
        if SE.LOBBY_GATHER then                              -- v1.6j: live 245, 350, 429: all five stand on one spot beside Snagg and the portal with this line
          for low, m in pairs(g.members) do
            local pl = getPlayer(g, low)
            if inGame(g, pl) then local x, y, z, o = slotSpot(m); try(pl, "NearTeleport", x, y, z, o) end
          end
        end
      end
    elseif g.completeSaid and g.last and t > g.doneAt + SE.ROUND_GAP + 5000 then cleanup(g, "finished"); return
    end
  end
  local here = 0
  for _ in pairs(g.members) do here = here + 1 end
  if here == 0 and g.state ~= "arriving" then cleanup(g, "nobody left") end
end
local function tickPending(t)
  for sLow, g in pairs(Pending) do
    local st = getPlayer(g, sLow)
    if t > g.created + 90000 then Pending[sLow] = nil; log("start cancelled (starter did not arrive within 90 s)")
    elseif st and st:GetMapId() == SE.MAP then
      Pending[sLow] = nil
      g.inst = st:GetInstanceId()
      if Games[g.inst] then st:SendBroadcastMessage(VT .. "A game is already running here.")
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
    if count >= SE.MAX_PLAYERS or p:IsBot() then return end  -- v1.0: real players only
    local low = p:GetGUIDLow()
    if members[low] then return end
    count = count + 1
    members[low] = { guid = p:GetGUID(), name = p:GetName(), slot = count, score = 0,
                     home = (p:GetMapId() ~= SE.MAP) and { p:GetMapId(), p:GetX(), p:GetY(), p:GetZ(), p:GetO() } or nil }
  end
  add(player)
  local grp = player:GetGroup()
  if grp then
    for _, p in ipairs(grp:GetMembers()) do
      if p:GetGUIDLow() ~= player:GetGUIDLow() and p:IsInWorld() and p:GetMapId() == player:GetMapId()
         and p:GetDistance(player) <= SE.JOIN_RANGE and p:IsAlive() then add(p) end
    end
  end
  if count == 0 then return end
  local g = { members = members, count = count, created = now(), state = "pending", crystals = {}, crystalCount = 0, strikes = {},
              pools = {}, holes = {}, tents = {}, waves = {}, round = 0, total = 0, revives = SE.REVIVES }
  Pending[player:GetGUIDLow()] = g
  for low, m in pairs(members) do
    local p = GetPlayerByGUID(m.guid)
    if p then
      local ang = SE.ARRIVE_ANG + (m.slot - 3) * 0.08         -- v1.3b: side by side on the ring
      p:SendBroadcastMessage(AZT .. "You have joined the Void queue.")
      p:Teleport(SE.MAP, SE.CENTER[1] + SE.ARRIVE_R * math.cos(ang), SE.CENTER[2] + SE.ARRIVE_R * math.sin(ang), SE.CENTER[3] + 0.5, (ang + math.pi) % (2 * math.pi))
    end
  end
  log(string.format("%s starts Shadow Eye with %d player(s)", player:GetName(), count))
end

local function leaveGame(player)                            -- v1.4: one way out for #leave, Snagg and the portal
  music(player, SE.MUSIC_LEAVE_ID)                           -- v1.6n (Rowan): the void music ends when you leave the course (the Faire music takes over)
  local low = player:GetGUIDLow()
  local g = Games[player:GetInstanceId()]
  if g and g.members[low] then
    sendHome(g, low)
    later(player:GetGUID(), 1500, function() if g.members[low] then g.members[low] = nil; g.count = math.max(0, g.count - 1) end end)
  else
    local f = SE.FAIRE_SPOT; player:Teleport(f[1], f[2], f[3], f[4], f[5])
  end
  player:SendBroadcastMessage(VT .. "Back to the Faire you go!")
end

-- ---------- Snagg ----------
local function readyUp(player)                              -- v1.3a: one ready path for #ready and Snagg's 'I'm ready!'
  local g = Games[player:GetInstanceId()]
  local low = player:GetGUIDLow()
  if not (g and g.members[low] and player:GetMapId() == SE.MAP) then return false end
  if g.state == "lobby" and not g.members[low].ready then
    g.members[low].ready = true
    try(player, "CastSpell", player, S.READY, true)
    if try(player, "HasAura", S.READY) ~= true then try(player, "AddAura", S.READY, player) end
    local waiting = false                                    -- v1.6h: live prints this line (plain yellow, no prefix) while somebody is ready and others are not (006, 014, 112); no 'x is ready' line
    for l2, m2 in pairs(g.members) do if not m2.ready and inGame(g, getPlayer(g, l2)) then waiting = true end end
    if waiting then tell(g, "|cffffff00Every player must be ready before the round can start.|r", "Every player must be ready before the round can start.") end
  end
  return true
end
local function snaggMenu(player, creature)
  player:GossipClearMenu()
  if creature:GetMapId() == SE.MAP then                     -- v1.3a: Snagg in the arena = the ready check
    local g = Games[player:GetInstanceId()]
    local m = g and g.members[player:GetGUIDLow()]
    if m and g.state == "lobby" and not m.ready then player:GossipMenuAddItem(0, "I'm ready!", 0, 10) end
    player:GossipMenuAddItem(0, "Take me back to the Faire.", 0, 11)
    player:GossipSendMenu(TEXT_GREET, creature)
    return
  end
  player:GossipAddQuests(creature)
  player:GossipMenuAddItem(9, "Enter the Shadow Eye (with my group)", 0, 1)
  player:GossipMenuAddItem(0, "Can you tell me more about The Shadoweye?", 0, 2)
  player:GossipMenuAddItem(1, "I'd like to browse your goods.", 0, 3)
  player:GossipSendMenu(TEXT_GREET, creature)
end
RegisterCreatureGossipEvent(E.SNAGG, 1, function(event, player, creature) snaggMenu(player, creature) end)
RegisterCreatureGossipEvent(E.SNAGG, 2, function(event, player, creature, sender, intid)
  if intid == 10 then player:GossipComplete(); readyUp(player); return end   -- v1.3a
  if intid == 11 then player:GossipComplete(); leaveGame(player); return end
  if intid == 1 then
    player:GossipComplete()
    if busy(player) then player:SendBroadcastMessage(VT .. "You are already in a game."); return end
    creature:SendUnitSay("Run. Run until time itself fades.", 0)
    startSession(player)
  elseif intid == 2 then
    player:GossipClearMenu(); player:GossipMenuAddItem(0, "Back", 0, 4); player:GossipSendMenu(TEXT_MORE, creature)
  elseif intid == 3 then
    player:GossipComplete(); player:SendListInventory(creature)
  else
    snaggMenu(player, creature)
  end
end)

-- ---------- the Azzar Faire Portal (v1.4; the same orb creature as in Wonka Wonka, Bullet Romper and the race, which stand elsewhere on this map) ----------
local function ourPortal(creature) return creature:GetMapId() == SE.MAP and dist2(creature:GetX(), creature:GetY(), SE.CENTER[1], SE.CENTER[2]) < 140 end
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

-- ---------- chat commands ----------
local function nearArena(pl) return pl:GetMapId() == SE.MAP and dist2(pl:GetX(), pl:GetY(), SE.CENTER[1], SE.CENTER[2]) < 140 end
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#leave" then
    if not nearArena(player) then return end
    leaveGame(player)
    return false
  end
  if msg == "#ready" then                                   -- v1.1: the ready check before each round (v1.3a: or talk to Snagg)
    if not nearArena(player) then return end
    if readyUp(player) then return false end
    return
  end
  local cmd, arg = msg:match("^#se%s+(%a+)%s*(%S*)%s*%S*$")   -- v1.3b: a second number is allowed (#se eye <size> <height>)
  if not cmd or (player:GetGMRank() or 0) < 1 then return end
  cmd = cmd:lower()
  if cmd == "start" then
    if busy(player) then player:SendBroadcastMessage(VT .. "You are already in a game.") else startSession(player) end
  elseif cmd == "time" and tonumber(arg) then
    local g = Games[player:GetInstanceId()]
    if g and g.state == "playing" then g.endAt = now() + tonumber(arg) * 1000; player:SendBroadcastMessage(VT .. "End of Game: " .. mmss(tonumber(arg)))
    else player:SendBroadcastMessage(VT .. "No game is running here.") end
  elseif cmd == "fx" and tonumber(arg) then                 -- v1.1: look at any visual on a marker 8 yd in front of you for 12 s
    local o = player:GetO()
    local c = player:SpawnCreature(E.STRIKE, player:GetX() + 8 * math.cos(o), player:GetY() + 8 * math.sin(o), player:GetZ() + 0.2, o, TEMPSUMMON_TIMED_DESPAWN, 12000)
    if c then try(c, "AddAura", tonumber(arg), c); try(c, "CastSpell", c, tonumber(arg), true) end
    player:SendBroadcastMessage(VT .. (c and ("Spell " .. arg .. " on a marker in front of you for 12 s.") or "Could not spawn the marker (run the SQL?)."))
  elseif cmd == "eye" and tonumber(arg) then                 -- v1.3b: '#se eye <size> [height]' tunes the Eye live
    local sc, zz = msg:match("^#se%s+%a+%s+(%S+)%s*(%S*)")
    SE.EYE_SCALE = tonumber(sc) or SE.EYE_SCALE
    if tonumber(zz) then SE.EYE_AT[3] = tonumber(zz) end
    local g = Games[player:GetInstanceId()]
    if g and g.eyeGuid then spawnEye(g, player) end
    if not (g and g.eyeGuid) and player:GetMapId() == SE.MAP then local gg = { }; spawnEye(gg, player); later(player:GetGUID(), 20000, function(p) local e = gg.eyeGuid and p:GetMap():GetWorldObject(gg.eyeGuid); if e then e:DespawnOrUnsummon(0) end end) end
    player:SendBroadcastMessage(VT .. string.format("Eye size %.2f, height %.1f (until the next .reload ale; tell Claude the numbers).", SE.EYE_SCALE, SE.EYE_AT[3]))
  elseif cmd == "skirt" then                                 -- v1.6k TEST: '#se skirt <size> [spell]' lays the black floor round the pit, '#se skirt off' takes it away
    local sz, sp = msg:match("^#se%s+%a+%s+(%S+)%s*(%S*)")
    if sz == "off" then SE.SKIRT_SCALE = 0
    elseif tonumber(sz) then SE.SKIRT_SCALE = tonumber(sz); if tonumber(sp) then SE.SKIRT_SPELL = tonumber(sp) end end
    local g = Games[player:GetInstanceId()]
    if g and g.voidUp then spawnPit(g, player) end
    player:SendBroadcastMessage(VT .. string.format("Skirt spell %d, size %.1f (until the next .reload ale; tell Claude the numbers). It shows during a round.", SE.SKIRT_SPELL, SE.SKIRT_SCALE))
  elseif cmd == "pit" then                                   -- v1.6: '#se pit <height> [spell]' sets the pit down / lifts it live, '#se pit off' takes it away
    local hz, sp = msg:match("^#se%s+%a+%s+(%S+)%s*(%S*)")
    if hz == "off" then SE.PIT_SPELL = 0
    elseif tonumber(hz) then
      SE.PIT_Z = tonumber(hz)
      if tonumber(sp) then SE.PIT_SPELL = tonumber(sp) elseif (SE.PIT_SPELL or 0) == 0 then SE.PIT_SPELL = 255629 end
    end
    local g = Games[player:GetInstanceId()]
    if g and g.voidUp then spawnPit(g, player) end
    player:SendBroadcastMessage(VT .. string.format("Pit spell %d, helper height %.1f (until the next .reload ale; tell Claude the numbers). It shows during a round.", SE.PIT_SPELL or 0, SE.PIT_Z))
  elseif cmd == "sky" and tonumber(arg) then                 -- v1.4: '#se sky <height> [size]' moves the realm dome live
    local zz, sc = msg:match("^#se%s+%a+%s+(%S+)%s*(%S*)")
    SE.SKY_Z = tonumber(zz) or SE.SKY_Z
    if tonumber(sc) then SE.SKY_SCALE = tonumber(sc) end
    local g = Games[player:GetInstanceId()]
    if g and (g.voidUp or g.skyUp) then spawnSky(g, player) end
    player:SendBroadcastMessage(VT .. string.format("Sky height %.1f, size %.2f (until the next .reload ale; tell Claude the numbers).", SE.SKY_Z, SE.SKY_SCALE))
  elseif cmd == "eyespell" and tonumber(arg) then            -- v1.4: 255629 = N'Zoth's eye (live), 255657 = the placeholder disc
    SE.EYE_SPELL = tonumber(arg)
    local g = Games[player:GetInstanceId()]
    if g and g.voidUp then spawnEye(g, player) end
    player:SendBroadcastMessage(VT .. "The Eye now uses spell " .. arg .. " (until the next .reload ale).")
  elseif cmd == "orbspell" and tonumber(arg) then            -- v1.4b: 257445 = 'Void Zone Black Hole' (ours), 255515 = 'Visual: Orb' (N'Zoth's black orb x2), 256245 = 'Void Beam' orb
    S.HOLEVIS = tonumber(arg)
    player:SendBroadcastMessage(VT .. "New orbs now use spell " .. arg .. " (until the next .reload ale). Size: #se set HOLE_SCALE <n>, ring off: #se set HOLE_RING 0.")
  elseif cmd == "gallery" then                               -- v1.6f: candidate looks side by side, to settle a look with one screenshot
    local sets = {
      orb = { { s = 256068 }, { s = 256103 }, { s = 255515 }, { s = 257220 }, { s = 256295 }, { s = 256283 }, { d = 132344 }, { d = 132285 }, { d = 460254 }, { d = 127213 }, { d = 130547 } },
      wave = { { s = 255633 }, { s = 257572, sc = 0.02 }, { s = 257572 }, { s = 257572, z = -8.6 }, { s = 256068 }, { s = 255633 }, { s = 256036 }, { s = 256037 }, { s = 255652 } },
      cloud = { { s = 255633 }, { s = 255533 }, { s = 255548 }, { s = 256827, sc = 7 }, { s = 256827, sc = 4 }, { s = 255633 }, { s = 256039, sc = 4 }, { s = 257538 } },
    }
    local set = sets[(arg or ""):lower()]
    if not set then player:SendBroadcastMessage(VT .. "Usage: #se gallery orb | wave | cloud")
    else
      local o = player:GetO() or 0
      local fx, fy, lx, ly = math.cos(o), math.sin(o), -math.sin(o), math.cos(o)
      local n, gap, legend = #set, (arg:lower() == "cloud") and 16 or 6, {}
      for k, it in ipairs(set) do
        local off = ((n + 1) / 2 - k) * gap
        local x, y = player:GetX() + fx * 24 + lx * off, player:GetY() + fy * 24 + ly * off
        local c = player:SpawnCreature(E.MOVER, x, y, player:GetZ() + 0.1 + (it.z or 0), (o + math.pi) % (2 * math.pi), TEMPSUMMON_TIMED_DESPAWN, 60000)
        if c then
          if it.sc then try(c, "SetScale", it.sc) end
          if it.d then try(c, "SetDisplayId", it.d) else try(c, "AddAura", it.s, c) end
          if k == 1 then try(c, "AddAura", S.ARROW, c) end
        end
        legend[#legend + 1] = k .. " = " .. (it.d and ("display " .. it.d) or ("spell " .. it.s)) .. (it.z and " (sunk)" or "") .. (it.sc and (" x" .. it.sc) or "")
      end
      player:SendBroadcastMessage(VT .. "Gallery '" .. arg .. "', left to right for 60 s (the yellow arrow is number 1):")
      for i = 1, #legend, 4 do player:SendBroadcastMessage("   " .. table.concat(legend, "   ", i, math.min(i + 3, #legend))) end
    end
  elseif cmd == "void" then                                  -- v1.4: the void on / off while you stand in the arena, to look at it
    local g = Games[player:GetInstanceId()]
    if not g then player:SendBroadcastMessage(VT .. "No game is running here (use #se start first).")
    elseif g.voidUp or g.skyUp then voidOff(g); player:SendBroadcastMessage(VT .. "Void off.")
    else voidOn(g); player:SendBroadcastMessage(VT .. "Void on.") end
  elseif cmd == "set" then                                   -- v1.4: '#se set <SETTING> <value>' changes any number or switch of the SE table live (until .reload ale), e.g. '#se set HOLE_DISPLAY 132344' = the old orb model
    local k, v = msg:match("^#se%s+set%s+([%w_]+)%s+(%S+)")
    if k and type(SE[k]) == "number" and tonumber(v) then SE[k] = tonumber(v); player:SendBroadcastMessage(VT .. k .. " = " .. v .. " (until the next .reload ale; tell Claude what you kept).")
    elseif k and type(SE[k]) == "boolean" then SE[k] = (v == "true" or v == "1" or v == "on"); player:SendBroadcastMessage(VT .. k .. " = " .. tostring(SE[k]) .. " (until the next .reload ale).")
    else player:SendBroadcastMessage(VT .. "Usage: #se set <SETTING> <value>   (a number or true/false setting from the top of the script, e.g. TENT_SCALE, DRIFT, POOL_R, STRIKE_KILL)") end
  elseif cmd == "look" and tonumber(arg) then                -- v1.2c: any creature display on a marker in front of you for 15 s (to pick looks)
    local o = player:GetO()
    local c = player:SpawnCreature(E.STRIKE, player:GetX() + 8 * math.cos(o), player:GetY() + 8 * math.sin(o), player:GetZ() + 2.5, o, TEMPSUMMON_TIMED_DESPAWN, 15000)
    if c then try(c, "SetDisplayId", tonumber(arg)) end
    player:SendBroadcastMessage(VT .. (c and ("Display " .. arg .. " in front of you for 15 s.") or "Could not spawn the marker (run the SQL?)."))
  elseif cmd == "round" and tonumber(arg) then
    local g = Games[player:GetInstanceId()]
    if g and g.state == "lobby" then g.round = math.max(1, math.min(SE.ROUNDS, math.floor(tonumber(arg)))); player:SendBroadcastMessage(VT .. "This is now round " .. g.round .. ".")
    else player:SendBroadcastMessage(VT .. "Only between rounds (in the ready check).") end
  else
    player:SendBroadcastMessage(VT .. "GM: #se start | #se time <seconds left> | #se fx <spell id> | #se look <display id> | #se eye <size> [height] | #se sky <height> [size] | #se eyespell <spell> | #se orbspell <spell> | #se void | #se set <SETTING> <value> | #se round <n>     Everyone: #ready, #leave")
  end
  return false
end)

log("script loaded v1.6t (a collected crystal vanishes at once; was v1.6s: Halo ring where a big crystal lands; was v1.6r: light spreading over the floor where a big crystal lands; was v1.6q: dark outside and music stop exactly as v1.6l again; pick-up burst 256022 + golden floor disc 256023 new; was v1.6p: golden floor disc where a big crystal lands; was v1.6o: crystal burst = holy impact 256022 at pick-up and at landing; was v1.6n: music is cut by a jingle at the end of a round and by the Faire music on leaving; was v1.6m: the dark closes in to r ~37 and catches out there, music off on leaving; was v1.6l: circles follow again, fog cone + ground lightning, pick-up burst, the dark outside closes in, music; was v1.6k: swirl circles wander at random and follow nobody, no trunks round the eye, black floor round the pit; was v1.6j: eyeball at 12, orbs each on their own, puddles one by one from under the eyeball, pick-up burst from the dwarf; was v1.6i: orb lines turning round the pit, a swirl circle chasing each marked dwarf, fog bands, trunks inside the pit; was v1.6h: start slots, staged Game Over, Vehicle Stun on a caught dwarf, puddle at floor level; was v1.6g: single random crystals + their pop, orb 256068, moving swirl circles, wandering Eye, Void Meteor mark, no portal in a round; was v1.6f: orbs: even ring on the pit edge, then they creep; creature 4 yd/s; #se gallery; was v1.6e: orbs stand, the slime creature goes from the Eye to the wall on its own; was v1.6d: orbs = void waves from the pit rim to the wall, wandering launch circles, stun pose, crystals fall during the count, one big cloud; was v1.6c: crystals burst when collected, Snagg leaves for the round, void waves from the Eye to the wall, darker rim at 0.9; orb 256103 + its own ring, no crystal bunches; fourth pass: standing trunks that catch at their base, trunks on the pit rim, the pit = 255629 on the floor [untested]) was v1.5 (third pass through the live frames: sky + tentacles from zone-in, Eye = Azzar_voideye 255657, orb = 257220 starry black ball) was v1.4c (orb 0.2 + ring 0.26 from the live screenshot; #se orbspell; Eye lower 16, orbs size 0.15, void 0.6 yd up for the black pit floor) live void (realm sky at floor level + far ring 256005, eye 255629 small and high, orb 257445, meteor volleys = launch pools, lying tentacles 0.25, free revives in the 30 s cast, portal, achievements, mover 99519); was v1.3b: eye 0.35 in the middle, arrive on the ring, Snagg in the arena + void only during rounds, live game pass (ring course, high eye, track rows, consumption 30 s, clouds, timer), launch pools, the Eye throws the meteors, black orbs + floor circles, falling crystals, eye in the centre, wall tentacles, crystal model, sweep, live HUD, floor-only spawns, holy crystals, drifting holes, falling meteors, void tentacles + eye, ambience (Snagg " .. E.SNAGG .. ", map " .. SE.MAP .. ", " .. SE.CRYSTALS .. " crystals, " .. mmss(SE.GAME_TIME) .. " game)")
