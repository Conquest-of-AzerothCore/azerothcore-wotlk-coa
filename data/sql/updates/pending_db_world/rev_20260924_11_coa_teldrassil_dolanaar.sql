-- Conquest of Azeroth rebuilt Dolanaar. It moved the inn 60 yards south and turned it 74 degrees, moved
-- Tallonkai's druid tower 110 yards south-east, put a two-storey house and a sentinel tower where they
-- stood, laid a plaza with a fountain between them, added three small houses, a tent, two bridges and a
-- brook, re-sculpted the ground and cut a termite den under the village. The stock residents stayed
-- behind, floating over the new ground or standing inside the new buildings. This moves them, and adds
-- the village's two CoA quests, 1660074 Termites in Teldrassil and 1660075 Stay a While.
--
-- WHERE EACH VALUE COMES FROM
--   inn and tower  every stock row of the two buildings follows its rigid move, read from the same WMO
--     placed in the stock and CoA collision data: the inn turns +73.7397 degrees about (9809.8609,
--     956.5562) to (9821.9019, 898.0601), z -2.3341; the tower turns -58.6709 degrees about (9905.7222,
--     987.7818) to (9955.5738, 888.7574), z +2.7863. The residents land on the CoA floors at their stock
--     height over the floor.
--   quest givers and enders  the client's QuestSuperTrack turn-in points; Keldamyr, Tallonkai, Athridas
--     and Laurna stand 0.7-1.9 yd from their transform points, which confirms the transforms.
--   signpost  the CoA terrain moves the same signpost placement (ADT uid 283648) 38 yards north-west,
--     turns it 5.0306 degrees and scales it 1.0703125; its arms follow.
--   inn rest area  CoA AreaTrigger.dbc 715 (the rest area stayed at the stock inn).
--   groups, houses, wildlife, patrols  INFERRED: hand-chosen points on the CoA ground; each row says why.
--   1660074, 1660075  the realm client cache (quests, creatures, displays, text 85162); Kaladir and the
--     queen stand at their SuperTrack points, Alenna at her Questie-X sighting; the termites are
--     hand-placed through the den on its navmesh. The sentinels at the barricades carry the stock
--     glaive and bow (equipment 1). Their aggro reach is 43 yards (detection range 18 + 25 levels), and
--     every termite and every other creature hostile to them keeps 46 yards away, less its wander, so they
--     hold the line without clearing the den or the forest around the crater.
--   appearance  STAND-IN displays for Kaladir and Alenna: their CoA displays are missing from the client.
--
-- Spawn guid block: creature 9007400-9007599. 62 stock rows moved, 31 termites, 5 critters, 3 barricade sentinels.
-- Each UPDATE matches guid and entry, so a row something else has changed is left alone.

-- ---------------------------------------------------------------------------
-- 1. Inn residents, moved with the inn
-- ---------------------------------------------------------------------------
UPDATE `creature` SET `position_x` = 9829.73, `position_y` = 908.66, `position_z` = 1306.526, `orientation` = 2.4215 WHERE `guid` = 46184 AND `id` = 3598;
UPDATE `creature` SET `position_x` = 9828.61, `position_y` = 875.74, `position_z` = 1306.526, `orientation` = 2.2993 WHERE `guid` = 46185 AND `id` = 3599;
UPDATE `creature` SET `position_x` = 9831.22, `position_y` = 897.95, `position_z` = 1306.516, `orientation` = 2.98 WHERE `guid` = 46197 AND `id` = 3609;
UPDATE `creature` SET `position_x` = 9813.51, `position_y` = 913.13, `position_z` = 1306.526, `orientation` = 5.79 WHERE `guid` = 46198 AND `id` = 3610;
UPDATE `creature` SET `position_x` = 9814.81, `position_y` = 875.64, `position_z` = 1306.526, `orientation` = 0.5365 WHERE `guid` = 46199 AND `id` = 3611;
UPDATE `creature` SET `position_x` = 9831.34, `position_y` = 894.43, `position_z` = 1306.516, `orientation` = 3.1196 WHERE `guid` = 46200 AND `id` = 3612;
UPDATE `creature` SET `position_x` = 9831.23, `position_y` = 901.62, `position_z` = 1306.516, `orientation` = 3.2767 WHERE `guid` = 46201 AND `id` = 3613;
UPDATE `creature` SET `position_x` = 9815.81, `position_y` = 901.18, `position_z` = 1306.536, `orientation` = 0.6936 WHERE `guid` = 46207 AND `id` = 2081;
UPDATE `creature` SET `position_x` = 9799.12, `position_y` = 903.11, `position_z` = 1311.646, `orientation` = 5.1093 WHERE `guid` = 46478 AND `id` = 6781;
UPDATE `gameobject` SET `position_x` = 9810.84, `position_y` = 895.48, `position_z` = 1306.436, `orientation` = 5.9121, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.18448, `rotation3` = -0.982836 WHERE `guid` = 49733 AND `id` = 3719;

-- ---------------------------------------------------------------------------
-- 2. Druid tower residents, moved with the tower
-- ---------------------------------------------------------------------------
UPDATE `creature` SET `position_x` = 9948.83, `position_y` = 900.86, `position_z` = 1330.436, `orientation` = 2.6412 WHERE `guid` = 46196 AND `id` = 3608;
UPDATE `creature` SET `position_x` = 9958.96, `position_y` = 907.28, `position_z` = 1330.816, `orientation` = 4.5785 WHERE `guid` = 46203 AND `id` = 3614;
UPDATE `creature` SET `position_x` = 9953.37, `position_y` = 905.62, `position_z` = 1316.706, `orientation` = 4.8403 WHERE `guid` = 46887 AND `id` = 4266;
UPDATE `creature` SET `position_x` = 9964.2, `position_y` = 897.27, `position_z` = 1316.706, `orientation` = 3.0601 WHERE `guid` = 47499 AND `id` = 6094;
UPDATE `creature` SET `position_x` = 9949.04, `position_y` = 901.43, `position_z` = 1357.816, `orientation` = 5.9573 WHERE `guid` = 49843 AND `id` = 3571;
UPDATE `creature` SET `position_x` = 9951.51, `position_y` = 886.62, `position_z` = 1357.676, `orientation` = 0.669 WHERE `guid` = 49844 AND `id` = 3571;
UPDATE `creature` SET `position_x` = 9928.55, `position_y` = 901.48, `position_z` = 1316.696, `orientation` = 3.6186 WHERE `guid` = 49849 AND `id` = 3571;
UPDATE `gameobject` SET `position_x` = 9955.22, `position_y` = 885.53, `position_z` = 1357.586, `orientation` = 1.7162, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.756602, `rotation3` = 0.653876 WHERE `guid` = 49615 AND `id` = 3658;

-- ---------------------------------------------------------------------------
-- 3. Quest givers and enders at their CoA turn-in points
-- ---------------------------------------------------------------------------
-- Innkeeper Keldamyr (46343): turn-in of 2159 (SuperTrack 1475) on the inn's raised dining floor, 0.74 yd from his
--   inn-transform point; facing as the transform turns his stock facing
UPDATE `creature` SET `position_x` = 9794.05, `position_y` = 897.77, `position_z` = 1311.554, `orientation` = 6.087 WHERE `guid` = 46343 AND `id` = 6736;
-- Tallonkai Swiftroot (49559): turn-in of 932, 2438, 2459 and 1660071 (SuperTrack 1074 = 8782) in the druid
--   tower's top room, 0.66 yd from his tower-transform point; facing as the transform turns his stock facing
UPDATE `creature` SET `position_x` = 9949.98, `position_y` = 893.79, `position_z` = 1357.588, `orientation` = 0.198 WHERE `guid` = 49559 AND `id` = 3567;
-- Athridas Bearmantle (46204): turn-in of 476, 483 and 486 (SuperTrack 1147) on the druid tower's ground floor,
--   0.79 yd from his tower-transform point; facing as the transform turns his stock facing
UPDATE `creature` SET `position_x` = 9927.83, `position_y` = 892.37, `position_z` = 1316.605, `orientation` = 2.641 WHERE `guid` = 46204 AND `id` = 2078;
-- Laurna Morninglight (46186): turn-in of 5621 and 5622 (SuperTrack 357) on the druid tower's ground floor by the
--   fountain, 1.9 yd from her tower-transform point; facing as the transform turns her stock facing
UPDATE `creature` SET `position_x` = 9954.62, `position_y` = 886.29, `position_z` = 1316.618, `orientation` = 1.419 WHERE `guid` = 46186 AND `id` = 3600;
-- Syral Bladeleaf (46211): turn-in of 1581 and CoA 1903559 (SuperTrack 1467) by the street lamps on the path from
--   the plaza to the druid tower (Questie 0.5 yd); her stock spot is inside the new sentinel tower; faces south
--   toward the plaza
UPDATE `creature` SET `position_x` = 9903.85, `position_y` = 902.33, `position_z` = 1306.587, `orientation` = 3.27 WHERE `guid` = 46211 AND `id` = 2083;
-- Zarrin (46718): turn-in of 4161 (SuperTrack 1600) at the north side of the tent by the plaza fountain; faces his
--   cauldron, which stands north of him as it did in stock
UPDATE `creature` SET `position_x` = 9880.47, `position_y` = 908.6, `position_z` = 1306.19, `orientation` = 6.05 WHERE `guid` = 46718 AND `id` = 6286;
-- Orenthil Whisperwind (46827): turn-in of 5842 (SuperTrack 1716) in front of the table with a bottle beside the
--   cart; faces the plaza
UPDATE `creature` SET `position_x` = 9843.08, `position_y` = 894.6, `position_z` = 1306.359, `orientation` = 0.13 WHERE `guid` = 46827 AND `id` = 11942;
-- Dazalar (46188): turn-in of 6063, 6071-6073, 6101, 6102, 6721 and 6722 (SuperTrack 189) on the open ground east
--   of the inn, north of the rune stone; faces the plaza
UPDATE `creature` SET `position_x` = 9843.54, `position_y` = 876.19, `position_z` = 1306.663, `orientation` = 0.57 WHERE `guid` = 46188 AND `id` = 3601;

-- ---------------------------------------------------------------------------
-- 4. Residents placed by hand
-- ---------------------------------------------------------------------------
-- Keldas (49526): pet trainer of the stock hunter group (Dazalar, Keldas, Seriadne stood together before the stock
--   inn): beside Dazalar on the open ground east of the inn, north of the rune stones; faces the plaza
UPDATE `creature` SET `position_x` = 9848.5, `position_y` = 874, `position_z` = 1306.705, `orientation` = 0.77 WHERE `guid` = 49526 AND `id` = 3306;
-- Seriadne (46313): stable master of the same hunter group: beside Dazalar on his other side, clear of the cart;
--   faces the plaza
UPDATE `creature` SET `position_x` = 9846.5, `position_y` = 880.5, `position_z` = 1306.538, `orientation` = 0.47 WHERE `guid` = 46313 AND `id` = 10051;
-- Nyoma (46886): cooking supplies, who stood 3.7 yd from Zarrin in stock: beside Zarrin on the open ground north
--   of the plaza tent, clear of the floating candles; faces the cauldron
UPDATE `creature` SET `position_x` = 9882, `position_y` = 905.8, `position_z` = 1306.286, `orientation` = 0.5 WHERE `guid` = 46886 AND `id` = 4265;
-- Cauldron (49700): Zarrin's cooking fire, 4.8 yd north of him as in stock: on the open ground north of the plaza
--   tent
UPDATE `gameobject` SET `position_x` = 9885.1, `position_y` = 907.5, `position_z` = 1306.087, `orientation` = 3.14159, `rotation0` = 0, `rotation1` = 0, `rotation2` = 1, `rotation3` = 0.000001 WHERE `guid` = 49700 AND `id` = 32880;
-- Cyndra Kindwhisper (46191): alchemy trainer; CoA removed her stock house, and house A is the one furnished as an
--   alchemy shop (stone table with a magic implement, globe and books); beside the stone table, facing the door on
--   the west side
UPDATE `creature` SET `position_x` = 9913.2, `position_y` = 832.6, `position_z` = 1316.669, `orientation` = 1.35 WHERE `guid` = 46191 AND `id` = 3603;
-- Malorne Bladeleaf (46192): herbalism trainer, Cyndra's housemate: at the desk with the globe and books in house
--   A, facing the door
UPDATE `creature` SET `position_x` = 9921, `position_y` = 834.5, `position_z` = 1316.669, `orientation` = 2.02 WHERE `guid` = 46192 AND `id` = 3604;
-- Teldrassil Sentinel (49846): stock inn door guard: the inn transform puts her 0.9 yd under the lower ground
--   before the moved inn door; on the ground there, 0.7 yd off the transform to clear the crates, facing out from
--   the door
UPDATE `creature` SET `position_x` = 9814.4, `position_y` = 932.4, `position_z` = 1305.797, `orientation` = 1.479 WHERE `guid` = 49846 AND `id` = 3571;
-- Teldrassil Sentinel (49848): the other inn door guard: the transform point is 0.42 yd from a pot; 1.1 yd along
--   the inn front, facing out from the door
UPDATE `creature` SET `position_x` = 9827.4, `position_y` = 931.9, `position_z` = 1305.747, `orientation` = 1.706 WHERE `guid` = 49848 AND `id` = 3571;
-- Mailbox (49531): mailboxes move with their building: the inn transform of its stock spot, on the ground beside
--   the inn front, clear of the door
UPDATE `gameobject` SET `position_x` = 9831.95, `position_y` = 935.15, `position_z` = 1306.097, `orientation` = 4.769, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.686811, `rotation3` = -0.726836 WHERE `guid` = 49531 AND `id` = 142109;
-- Teldrassil Sentinel (49847): stationary guard by the west moonwell: her stock spot clips a CoA
--   Kalidarstonerune02 rune stone (0.5 yd, on a 39-degree edge); 1.7 yd east on the level ground beside it, clear
--   of the stone, same facing
UPDATE `creature` SET `position_x` = 9729, `position_y` = 949, `position_z` = 1294.508, `orientation` = 4.76475 WHERE `guid` = 49847 AND `id` = 3571;

-- ---------------------------------------------------------------------------
-- 5. Signpost arms, moved with the post
-- ---------------------------------------------------------------------------
UPDATE `gameobject` SET `position_x` = 9870.22, `position_y` = 951.75, `position_z` = 1307.02, `orientation` = 3.5523, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.978989, `rotation3` = -0.203913 WHERE `guid` = 49604 AND `id` = 12358;
UPDATE `gameobject` SET `position_x` = 9870.22, `position_y` = 951.74, `position_z` = 1306.303, `orientation` = 3.5523, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.978989, `rotation3` = -0.203913 WHERE `guid` = 49605 AND `id` = 12359;
UPDATE `gameobject` SET `position_x` = 9870.27, `position_y` = 951.83, `position_z` = 1306.314, `orientation` = 0.4107, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.20391, `rotation3` = 0.97899 WHERE `guid` = 49606 AND `id` = 12360;
UPDATE `gameobject` SET `position_x` = 9870.26, `position_y` = 951.86, `position_z` = 1307.02, `orientation` = 0.4107, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.20391, `rotation3` = 0.97899 WHERE `guid` = 49607 AND `id` = 12361;
UPDATE `gameobject` SET `position_x` = 9870.21, `position_y` = 951.71, `position_z` = 1305.532, `orientation` = 3.5523, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.978989, `rotation3` = -0.203913 WHERE `guid` = 49608 AND `id` = 12362;
UPDATE `gameobject` SET `position_x` = 9870.26, `position_y` = 951.86, `position_z` = 1305.597, `orientation` = 0.4107, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.20391, `rotation3` = 0.97899 WHERE `guid` = 49616 AND `id` = 12363;
UPDATE `gameobject_template` SET `size` = 1.0703125 WHERE `entry` IN (12358, 12359, 12360, 12361, 12362, 12363);

-- ---------------------------------------------------------------------------
-- 6. Wildlife, Fel Cones and herbs off the new walls, water and ground
-- ---------------------------------------------------------------------------
-- Webwood Lurker (47523): its 33-yd stock wander covers the corner where Alenna Whisperbough meditates: on the
--   open bank south of the Kalidartree03 on the same shore, 45 yd from her, wandering 12 yd like its neighbour
--   47520
UPDATE `creature` SET `position_x` = 9796, `position_y` = 764, `position_z` = 1302.151, `orientation` = 4.43142, `wander_distance` = 12 WHERE `guid` = 47523 AND `id` = 1998;
-- Webwood Lurker (47520): CoA raised the ground 4.9 yd over it; same spot on the CoA ground
UPDATE `creature` SET `position_x` = 9850.49, `position_y` = 750.5, `position_z` = 1309.226, `orientation` = 5.70224 WHERE `guid` = 47520 AND `id` = 1998;
-- Nightsaber (49900): CoA moved the druid tower onto its spot, 20 yd from Byancie: on the open ground at the foot
--   of the giant root (Kalidargiantroot02) south-east of the village, its wander outside Dolanaar (area 186)
UPDATE `creature` SET `position_x` = 9962, `position_y` = 783, `position_z` = 1323.952, `orientation` = 0.0977 WHERE `guid` = 49900 AND `id` = 2042;
-- Webwood Lurker (47527): its spot is the front garden of CoA house A under a Kalidarroots01 arch, and its 23-yd
--   wander reached Malorne and Cyndra: on the Webwood Lurker ground south-east of the village, toward Lurkers
--   47516 and 47518, its wander outside Dolanaar (area 186)
UPDATE `creature` SET `position_x` = 9950, `position_y` = 775, `position_z` = 1321.25, `orientation` = 4.80137 WHERE `guid` = 47527 AND `id` = 1998;
-- Peacebloom (10242): CoA lowered the ground 0.8 yd under it; same spot on the CoA ground
UPDATE `gameobject` SET `position_x` = 9969.02, `position_y` = 874.03, `position_z` = 1322.48, `orientation` = 3.49066, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.984808, `rotation3` = -0.173649 WHERE `guid` = 10242 AND `id` = 1618;
-- Webwood Lurker (47511): its spot on the south slope of the termite crater is 28 yd from the barricade sentinels,
--   inside their 43-yd aggro reach: on the open forest slope under the great tree's canopy south-west of the
--   crater, 50 yd from the barricades
UPDATE `creature` SET `position_x` = 9645, `position_y` = 1088, `position_z` = 1268.151, `orientation` = 6.15793 WHERE `guid` = 47511 AND `id` = 1998;
-- Strigid Owl (47370): on the south-east lip of the termite crater, which CoA lowered 3.1 yd; same spot on the CoA
--   ground
UPDATE `creature` SET `position_x` = 9660.53, `position_y` = 1023.73, `position_z` = 1280.724, `orientation` = 3.92285 WHERE `guid` = 47370 AND `id` = 1995;
-- Strigid Owl (47377): its spot is under the CoA dryad shrine (0.4 yd from it on a 38-degree slope): on the open
--   ground north of the shrine, below the druid tower
UPDATE `creature` SET `position_x` = 9926, `position_y` = 883, `position_z` = 1316.569, `orientation` = 5.69173 WHERE `guid` = 47377 AND `id` = 1995;
-- Strigid Owl (47383): its spot is inside CoA house A: on the meadow west of the house, off the road
UPDATE `creature` SET `position_x` = 9894.5, `position_y` = 846, `position_z` = 1313.276, `orientation` = 5.49013 WHERE `guid` = 47383 AND `id` = 1995;
-- Strigid Owl (47378): its spot is buried inside CoA house C: on the open bank between the house and the brook
--   pool
UPDATE `creature` SET `position_x` = 9808, `position_y` = 826, `position_z` = 1301.456, `orientation` = 2.49631 WHERE `guid` = 47378 AND `id` = 1995;
-- Rabbit (47936): its spot is 2.5 yd up on CoA tree roots beside house C: on the open grass north of the house
UPDATE `creature` SET `position_x` = 9806, `position_y` = 822, `position_z` = 1303.341, `orientation` = 5.19514 WHERE `guid` = 47936 AND `id` = 721;
-- Nightsaber (49897): its spot is under the deck of the CoA moongate bridge: on the open grass north of the
--   moongate, off the road
UPDATE `creature` SET `position_x` = 9866, `position_y` = 830, `position_z` = 1310.089, `orientation` = 5.55685 WHERE `guid` = 49897 AND `id` = 2042;
-- Fel Cone (49753): its spot is 2.9 yd up on a CoA rune stone below house A: on the bank above the brook pool at
--   the foot of the tree, beside the rune stones; out of the water
UPDATE `gameobject` SET `position_x` = 9933.27, `position_y` = 807.24, `position_z` = 1318.026, `orientation` = -2.40855, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.93358, `rotation3` = 0.35837 WHERE `guid` = 49753 AND `id` = 1673;
-- Fel Cone (49755): its spot is in the CoA brook, 4 yd over the bed: on the dry west bank of the pool below the
--   druid tower
UPDATE `gameobject` SET `position_x` = 9944, `position_y` = 858, `position_z` = 1318.437, `orientation` = 0.506145, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.25038, `rotation3` = 0.968148 WHERE `guid` = 49755 AND `id` = 1673;
-- Peacebloom (10229): its spot floats 6 yd over the lowered crater floor on the approach to the sentinel camp: on
--   the undisturbed ground at the crater's south lip, by a tree
UPDATE `gameobject` SET `position_x` = 9662, `position_y` = 1012, `position_z` = 1285.497, `orientation` = 4.71239, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.707106, `rotation3` = -0.707107 WHERE `guid` = 10229 AND `id` = 1618;
-- Nightsaber (49875): its spot floats 9 yd over the lowered crater, inside the sentinel camp: on the level ground
--   just west of the tree (Kalidartree04) south-west of the crater, beyond the barricade sentinels' reach
UPDATE `creature` SET `position_x` = 9628, `position_y` = 1068, `position_z` = 1271.687, `orientation` = 1.5916 WHERE `guid` = 49875 AND `id` = 2042;
-- Webwood Lurker (47508): its spot is 8.7 yd up on a tree stump over the crater, and the forest just west of the
--   rim is inside the barricade sentinels' reach: in the open forest north of the root arch (Kalidarroots01) west
--   of the crater
UPDATE `creature` SET `position_x` = 9694, `position_y` = 1102, `position_z` = 1275.614, `orientation` = 0.928362 WHERE `guid` = 47508 AND `id` = 1998;
-- Nightsaber (49894): its stock spot west of the crater is 37 yd from the barricade sentinels, inside their reach:
--   on the flat ground at the south end of the root arch (Kalidarroots01) west of the crater, 40 yd from the deer
UPDATE `creature` SET `position_x` = 9665, `position_y` = 1100, `position_z` = 1270.94, `orientation` = 5.70691 WHERE `guid` = 49894 AND `id` = 2042;
-- Fel Cone (49785): its spot is 6.5 yd up a tree over the crater: on the forest floor west of the barricades, out
--   of the camp
UPDATE `gameobject` SET `position_x` = 9700, `position_y` = 1066, `position_z` = 1279.87, `orientation` = 1.55334, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.700908, `rotation3` = 0.713252 WHERE `guid` = 49785 AND `id` = 1673;
-- Silverleaf (10351): its spot is 20 yd under the Theren-Dion switchback CoA raised: on the new slope beside the
--   switchback path
UPDATE `gameobject` SET `position_x` = 9988, `position_y` = 776, `position_z` = 1344.544, `orientation` = 1.32645, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.615661, `rotation3` = 0.788011 WHERE `guid` = 10351 AND `id` = 1617;

-- ---------------------------------------------------------------------------
-- 7. Dolanaar inn rest area
-- ---------------------------------------------------------------------------
UPDATE `areatrigger` SET `x` = 9819.75, `y` = 897.539, `z` = 1306.46 WHERE `entry` = 715;

-- ---------------------------------------------------------------------------
-- 8. Patrols
-- ---------------------------------------------------------------------------
-- Teldrassil Sentinel (49845, path 498450): The stock walk ran from the west moonwell up to the stock inn porch,
--   now through CoA house B and the great tree; she walks the lane between the moonwell and house B instead, from
--   her post to the corner north of the house and back.
UPDATE `creature` SET `position_x` = 9766.85, `position_y` = 923.66, `position_z` = 1298.71, `orientation` = 0.259354 WHERE `guid` = 49845 AND `id` = 3571;
-- Ancient Protector (49855, path 498550): The stock round crossed the moved inn, the new plaza fountain and a
--   wagon; the treant now walks the open village street from the moongate bridge through the west side of the
--   plaza, past the signpost and the sentinel tower, up the road toward Darnassus and back.
UPDATE `creature` SET `position_x` = 9858, `position_y` = 834, `position_z` = 1307.966, `orientation` = 1.55456 WHERE `guid` = 49855 AND `id` = 2041;

DELETE FROM `waypoint_data` WHERE `id` IN (498450, 498550);
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`)
VALUES
(498450, 1, 9766.85, 923.66, 1298.71, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 2, 9763, 936, 1302.448, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 3, 9761.8, 942, 1303.864, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 4, 9760.5, 948, 1302.271, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 5, 9763, 961, 1299.377, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 6, 9770, 966, 1304.379, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 7, 9763, 961, 1299.377, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 8, 9760.5, 948, 1302.271, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 9, 9761.8, 942, 1303.864, NULL, 0, 0, 0, 0, 0, 100, 0),
(498450, 10, 9763, 936, 1302.448, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 1, 9858, 834, 1307.966, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 2, 9866, 862, 1306.265, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 3, 9859, 880, 1306.079, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 4, 9858.5, 900, 1306.035, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 5, 9866, 918, 1306.029, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 6, 9876, 936, 1306.566, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 7, 9860, 962, 1305.731, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 8, 9852, 990, 1305.426, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 9, 9846.5, 1018, 1305.445, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 10, 9846.5, 1045, 1305.014, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 11, 9854, 1061, 1306.469, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 12, 9846.5, 1045, 1305.014, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 13, 9846.5, 1018, 1305.445, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 14, 9852, 990, 1305.426, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 15, 9860, 962, 1305.731, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 16, 9876, 936, 1306.566, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 17, 9866, 918, 1306.029, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 18, 9858.5, 900, 1306.035, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 19, 9859, 880, 1306.079, NULL, 0, 0, 0, 0, 0, 100, 0),
(498550, 20, 9866, 862, 1306.265, NULL, 0, 0, 0, 0, 0, 100, 0);

-- ---------------------------------------------------------------------------
-- 9. Creatures of the two quests
-- ---------------------------------------------------------------------------
-- 162879 Kaladir: STAND-IN display 1982 (female night elf sentinel of the unspawned Sentinel Selarin 3694); cache
--   652438 is not in CreatureDisplayInfo. Her text speaks of "my sisters ... holding the line": a Sentinel
-- 162881 Alenna Whisperbough: STAND-IN display 12169 (robed female night elf of the unspawned Priestess of Elune
--   12116); cache 652450 is not in CreatureDisplayInfo
-- 162876 Barkshredder Termite: cache display 11091 (Silithid.mdx) resolves
-- 162877 Barkshredder Queen: cache display 141829 (mantidtank_low01.m2 at display scale 0.2, CoA's own, in client
--   patch-CM.MPQ) resolves; it has no creature_model_info row, so one is added (Creature.cpp:526-532 refuses a
--   display without it)
-- 162875 Termite: cache display 15468 (SilithidScarab.mdx) resolves
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(162879, 'Kaladir', NULL, 0, 9, 9, 0, 80, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 0, ''),
(162881, 'Alenna Whisperbough', NULL, 85162, 25, 25, 0, 80, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(162876, 'Barkshredder Termite', NULL, 0, 6, 6, 0, 22, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, '', 0, 0.96, 1, 1, 1, 0, ''),
(162877, 'Barkshredder Queen', NULL, 0, 8, 8, 0, 22, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, '', 0, 0.96, 1, 1, 1, 0, ''),
(162875, 'Termite', NULL, 0, 1, 1, 0, 188, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 8, 0, 0, '', 0, 0.93, 1, 1, 1, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (162875, 162876, 162877, 162879, 162881);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162879, 0, 1982, 1, 1),
(162881, 0, 12169, 1, 1),
(162876, 0, 11091, 1, 1),
(162877, 0, 141829, 1, 1),
(162875, 0, 15468, 1, 1);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 141829;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(141829, 2, 3, 2, 0);

-- Alenna meditates in her corner: she sits (the quest text: "Alenna would not be moved").
DELETE FROM `creature_template_addon` WHERE `entry` = 162881;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(162881, 0, 0, 1, 1, 0, 0, NULL);

-- ---------------------------------------------------------------------------
-- 10. Quests
-- ---------------------------------------------------------------------------
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660074, 2, 9, 5, 141, 0, 0, 0, 0, 0, 0, 0, 5, 350, 382, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302047, 1, 2302052, 1, 2302057, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Termites in Teldrassil', 'Enter the bark of Teldrassil near Dolanaar and defeat the termites infesting its depths.', 'Ishnu-alah, $C.$b$bTeldrassil has grown dangerous of late, and Dolanaar is no exception.$b$bSouthwest of here, the earth yawns open to bare the vast heartwood of the World Tree''s trunk. My sisters have found a termite colony there and are holding the line... but we''re too few, and for every termite we kill, two more scuttle in to take its place.$b$bHelp us stem the termite threat, and I''ll see you''re rewarded in full for the risk you''ll take down there.', '', 'Return to Kaladir.', 162876, 162877, 0, 0, 10, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660075, 2, 8, 5, 141, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Alenna Whisperbough.', '<Gazing at her, you''re certain that Teldrassil itself could go up in roaring flame and Alenna would not be moved.>$b$b<Perhaps she has something to share.>', '', 'Say goodbye to Alenna.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Alenna Whisperbough', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660074, 1660075);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `BreadcrumbForQuestId`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660074, 0, 0, 1660071, 0, 0, 0),
(1660075, 0, 0, 1660071, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660074, 1660075);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660074, 'Well fought, $C.$B$BMy sisters acknowledge your merits with admiration… and a touch of envy.$B$BWe Sentinels will see to exterminating the rest.'),
(1660075, '<Alenna’s gaze darkens. It seems the beauty of Dolanaar isn’t enough to chase off the dread conjured by that cult’s name.>');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660074, 1660075);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660074, 'Have you finished off the termites? Did they give you much trouble?'),
(1660075, '');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660074, 1660075);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(162879, 1660074),
(162881, 1660075);

DELETE FROM `creature_questender` WHERE `quest` IN (1660074, 1660075);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(162879, 1660074),
(162881, 1660075);

-- ---------------------------------------------------------------------------
-- 11. Alenna Whisperbough: listening to her
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` = 85162;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`)
VALUES
(85162, '<Slowly, as if opening her eyes for the first time in years, Alenna turns her face to you and smiles.>$b$bI like to meditate in this corner. Isn’t it beautiful?', '<Slowly, as if opening her eyes for the first time in years, Alenna turns her face to you and smiles.>$b$bI like to meditate in this corner. Isn’t it beautiful?', 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 85162;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(85162, 85162);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 85162;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(85162, 0, 0, '<Sit with her a while and listen.>', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 85162;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 85162, 0, 0, 0, 9, 0, 1660075, 0, 0, 0, 0, 0, '', 'Alenna Whisperbough - listen only while Stay a While is taken');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162881 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162881, 0, 0, 1, 62, 0, 100, 0, 85162, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Alenna Whisperbough - On Gossip Option 0 Selected - Close Gossip'),
(162881, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Alenna Whisperbough - Linked - Credit listening to her');

-- ---------------------------------------------------------------------------
-- 12. Spawns: Kaladir, Alenna, the termite den and the sentinels holding its mouth
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9007400, 9007401, 9007402, 9007403, 9007404, 9007405, 9007406, 9007407, 9007408, 9007409, 9007410, 9007411, 9007412, 9007413, 9007414, 9007415, 9007416, 9007417, 9007418, 9007419, 9007420, 9007421, 9007422, 9007423, 9007424, 9007425, 9007426, 9007427, 9007428, 9007429, 9007430, 9007431, 9007432, 9007433, 9007440, 9007441, 9007442, 9007443, 9007444, 9007450, 9007451, 9007452) OR `guid` BETWEEN 9007400 AND 9007599;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9007400, 162879, 1, 0, 0, 1, 1, 0, 9804.09, 938.56, 1307.281, 5.84, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar: SuperTrack turn-in of 1660074 (8785) north of the new tent (Questie 1.7 yd), facing the inn door and the plaza, the way players come from Tallonkai'),
(9007401, 162881, 1, 0, 0, 1, 1, 0, 9830.92, 792.49, 1305.521, 2.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar: Questie point of Alenna Whisperbough (no SuperTrack record): the corner at the foot of the great roots on the east bank of the brook pool, her back to the roots, facing south-west over the bank and the path players take from the village'),
(9007402, 162877, 1, 0, 0, 1, 1, 0, 9792.3, 956.3, 1232.298, 1.18, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar: SuperTrack objective of 1660074 (8787): the floor of the bottom chamber, facing the slope down from the shelf'),
(9007403, 162876, 1, 0, 0, 1, 1, 0, 9734, 1019, 1272.627, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: tunnel entrance just inside the mouth, beside the mushroom cluster, chewing the tunnel wall; stationary, out of reach of the barricade sentinels'),
(9007404, 162876, 1, 0, 0, 1, 1, 0, 9740, 1016, 1269.826, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: tunnel, among the Desolace mushrooms'),
(9007405, 162876, 1, 0, 0, 1, 1, 0, 9746.5, 1020.5, 1268.413, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: tunnel west wall, under the small mushrooms, chewing the bark'),
(9007406, 162876, 1, 0, 0, 1, 1, 0, 9751, 1016.5, 1264.197, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: tunnel where it starts to drop, past the three small mushrooms'),
(9007407, 162876, 1, 0, 0, 1, 1, 0, 9755.5, 1012, 1259.201, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: the bend where the tunnel turns down into the ramp, under the shelf fungus'),
(9007408, 162876, 1, 0, 0, 1, 1, 0, 9761.5, 1008, 1254.474, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: upper ramp, beside the hanging roots'),
(9007409, 162876, 1, 0, 0, 1, 1, 0, 9765, 999, 1248.602, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: middle of the ramp, below the shelf fungi'),
(9007410, 162876, 1, 0, 0, 1, 1, 0, 9768, 991.5, 1244.578, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: foot of the ramp where it opens onto the shelf'),
(9007411, 162876, 1, 0, 0, 1, 1, 0, 9780, 994, 1241.02, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: west shelf, by the mushroom group'),
(9007412, 162876, 1, 0, 0, 1, 1, 0, 9784, 1000, 1242.055, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: west shelf, by the small mushroom'),
(9007413, 162876, 1, 0, 0, 1, 1, 0, 9792, 1006, 1242.414, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: shelf, by the small mushroom under the roots'),
(9007414, 162876, 1, 0, 0, 1, 1, 0, 9798, 1017, 1241.141, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: north end of the shelf, by the hanging roots'),
(9007415, 162876, 1, 0, 0, 1, 1, 0, 9800, 1004, 1241.315, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: shelf, below the shelf fungi'),
(9007416, 162876, 1, 0, 0, 1, 1, 0, 9790, 986, 1240.386, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: shelf edge overlooking the bottom chamber, by the mushroom group'),
(9007417, 162876, 1, 0, 0, 1, 1, 0, 9806, 1022, 1240.591, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: north corner of the shelf, beside the root curtain'),
(9007418, 162876, 1, 0, 0, 1, 1, 0, 9810, 1008, 1239.067, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: middle level, below the shelf fungi'),
(9007419, 162876, 1, 0, 0, 1, 1, 0, 9814, 1020, 1238.72, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: middle level north corner (Questie sighting 2.2 yd)'),
(9007420, 162876, 1, 0, 0, 1, 1, 0, 9822, 1014, 1236.775, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: middle level, by the tall mushroom'),
(9007421, 162876, 1, 0, 0, 1, 1, 0, 9828, 1018, 1238.56, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: north-east corner, by the mushroom group'),
(9007422, 162876, 1, 0, 0, 1, 1, 0, 9834, 1000, 1237.249, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: east wall, by the Desolace mushroom cluster'),
(9007423, 162876, 1, 0, 0, 1, 1, 0, 9818, 998, 1236.098, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: centre of the middle level, by the mushroom group'),
(9007424, 162876, 1, 0, 0, 1, 1, 0, 9826, 986, 1236.676, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: south-east of the middle level'),
(9007425, 162876, 1, 0, 0, 1, 1, 0, 9832, 990, 1237.293, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: east wall, below the small mushrooms'),
(9007426, 162876, 1, 0, 0, 1, 1, 0, 9824, 978, 1236.815, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: rim above the bottom chamber, by the small mushroom'),
(9007427, 162876, 1, 0, 0, 1, 1, 0, 9800, 970, 1231.645, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: bottom chamber floor'),
(9007428, 162876, 1, 0, 0, 1, 1, 0, 9808, 978, 1232.697, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: north side of the bottom chamber'),
(9007429, 162876, 1, 0, 0, 1, 1, 0, 9818, 972, 1233.956, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: east side of the bottom chamber'),
(9007430, 162876, 1, 0, 0, 1, 1, 0, 9814, 960, 1233.579, 0, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: bottom chamber, among the small mushrooms'),
(9007431, 162876, 1, 0, 0, 1, 1, 0, 9810, 968, 1232.138, 0, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: middle of the bottom chamber'),
(9007432, 162876, 1, 0, 0, 1, 1, 0, 9802, 958, 1232.664, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: bottom chamber, guarding the queen'),
(9007433, 162876, 1, 0, 0, 1, 1, 0, 9790, 966, 1230.79, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: bottom chamber west, by the Desolace mushroom, guarding the queen'),
(9007440, 162875, 1, 0, 0, 1, 1, 0, 9744, 1014.5, 1268.18, 0, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: tunnel, between the mushrooms'),
(9007441, 162875, 1, 0, 0, 1, 1, 0, 9759.5, 1001.5, 1252.608, 0, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: upper ramp, below the shelf fungi'),
(9007442, 162875, 1, 0, 0, 1, 1, 0, 9795, 1012, 1242.253, 0, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: shelf, under the roots'),
(9007443, 162875, 1, 0, 0, 1, 1, 0, 9820, 1006, 1235.84, 0, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: middle level'),
(9007444, 162875, 1, 0, 0, 1, 1, 0, 9804, 974, 1232.246, 0, 300, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite den: bottom chamber'),
(9007450, 3571, 1, 0, 0, 1, 1, 1, 9685.5, 1028.5, 1276.875, 6.18, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite crater: behind the middle barricade by the crates, facing the den mouth'),
(9007451, 3571, 1, 0, 0, 1, 1, 1, 9692.5, 1042, 1276.409, 5.74, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite crater: behind the north barricade pair, facing the den mouth'),
(9007452, 3571, 1, 0, 0, 1, 1, 1, 9678.5, 1045.5, 1275.454, 5.82, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Dolanaar termite crater: behind the west barricade by the supply crates, facing the den mouth');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9007400 AND 9007599;
