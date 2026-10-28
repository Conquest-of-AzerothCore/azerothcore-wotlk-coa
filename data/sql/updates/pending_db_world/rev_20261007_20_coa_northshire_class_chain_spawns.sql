-- Northshire class chain: republish the valley's class-chain spawns - the 18 gameobjects at
-- guids 7912100-7912117, the chain NPCs at guids 9003120-9003129 and their two addons.
--
-- rev_20260930_98_northshire_baseline_restore reverted the valley to the pre-revamp world and
-- deleted the CoA rows it found there, which is the same regression that
-- rev_20261003_00_coa_northshire_trainer_interaction.sql repairs for the trainer *templates*.
-- The spawns were never restored, so on every world database that has applied the restore the
-- objects the class chains need are simply absent, while the quests that point at them are still
-- offered:
--
--   9301103 Lost Pendant (guids 7912105, 7912106)  - quest 200058 and its per-class twins
--   9301105 Uther's Statue (guid 7912102)          - quest 200077 and its per-class twins
--   9301101 Training Wand, 9301102 Eye of the Beholder, 9301104 Scrap Metal (the kobold camps)
--   9301100 Ritual Circle
--
-- The rows below are the ones rev_20260923_06_coa_class_trainers_northshire.sql authors, copied
-- unchanged, so every id and position still matches the quest and SmartAI rows that already
-- exist in the world. The valley's trainer spawns are not repeated here: those NPCs are spawned
-- by the class-trainer migration that the restore left in place.

DELETE FROM `creature` WHERE `guid` IN (9003120, 9003121, 9003122, 9003123, 9003124, 9003125, 9003126, 9003127, 9003128, 9003129);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9003120, 299235, 0, 0, 0, 1, 1, 1, -8859, -193, 81.932, 3.14, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Northshire Abbey, Library Wing ground floor ("Somewhere in the Library Wing", 200071), between the shelves 5.6 yd from Chaplain Nysoni; faces south toward the way in from the main hall'),
(9003121, 85031, 0, 0, 0, 1, 1, 0, -8628.8, -110.2, 88.907, 3.51, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Echo Ridge Mine side chamber by the Worn Shovel, just inside the mouth (Exiles zone claim 47,30 = the mine mouth; text: "in the Kobold mine"); kneeling, injured; faces the chamber opening players come through'),
(9003122, 299325, 0, 0, 0, 1, 1, 1, -8966.5, -289, 73.469, 0.99, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: north end of the river bridge on the road from the abbey to the vineyards, telling passers-by his grievances; faces the abbey road'),
(9003123, 9300102, 0, 0, 0, 1, 1, 0, -8800.79, -408.43, 75.172, 3.1, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: supply yard of the Defias-held Damaged Guard Tower, among the crates at the yard''s east edge where the scouting falcon came down: the nearest reachable floor to the SOURCED-CACHE quest point of 199999 (-8799.29, -412.93), 4.7 yd off, because the point itself lies on the yard''s steep east retaining edge with no navmesh; faces 3.10 into the yard, where the navmesh paths from the abbey arrive'),
(9003124, 9300103, 0, 0, 0, 1, 1, 0, -8677.65, -185.65, 92.28, 3.94, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: CoA farmhouse (Redridge_Human_Farm.wmo) north of the abbey, seated in the chair at his small table (low chair, stand state 4) facing the table; the furnished house with its armour stand is his "own home in the valley"'),
(9003125, 9300104, 0, 0, 0, 1, 1, 0, -8960.4, -212.9, 77.008, 1.25, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: outside the graveyard''s stone wall south-west of the abbey, an old villager tending the graves, 3.5 yd off the Northshire Peasant''s walk to the graveyard gate (path 802620); faces the fence''s west corner, where players from Deacon Frost come round'),
(9003126, 9300101, 0, 0, 0, 1, 1, 0, -8974, -465.5, 73.693, 0.98, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: draw in the hills south-east of the Defias camp, beside the campfire it is bound to; faces the fire'),
(9003127, 9300100, 0, 0, 0, 1, 1, 1, -8961.5, -442.5, 66.07, 1.26, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Defias camp, south end of the tent, facing the camp fire; one of the camp''s own bandits'),
(9003128, 9300100, 0, 0, 0, 1, 1, 1, -9040, -311, 73.771, 1.03, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Northshire Vineyards among the Defias Thugs, by the water wagon he faces; the second holder so two players can take the tome at once'),
(9003129, 685037, 0, 0, 0, 1, 1, 0, -8739.5, -410.5, 81.707, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: invisible walk-in credit for A Quiet Life at the foot of the Northshire falls, on the low rock between the pool''s east end and the cliff under Uther''s Statue; from here it sees the whole bank below the statue and falls and most of the pool within 15 yd, where the statue ledge itself cannot be reached on foot');

DELETE FROM `creature_addon` WHERE `guid` IN (9003121, 9003124);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9003121, 0, 0, 8, 0, 0, 0, ''),
(9003124, 0, 0, 4, 0, 0, 0, '');

DELETE FROM `gameobject` WHERE `guid` IN (7912100, 7912101, 7912102, 7912103, 7912104, 7912105, 7912106, 7912107, 7912108, 7912109, 7912110, 7912111, 7912112, 7912113, 7912114, 7912115, 7912116, 7912117);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(7912100, 9301100, 0, 0, 0, 1, 1, -8918.5, -418, 66.037, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Northshire class chain: clearing in the woods north of the Defias camp, 35 yd from its bandits (the note: "the nearby Defias bandits have just what is needed")'),
(7912101, 21282, 0, 0, 0, 1, 1, -8972, -462.5, 72.399, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Northshire class chain: the campfire Scorch is bound to, in the draw south-east of the Defias camp'),
(7912102, 9301105, 0, 0, 0, 1, 1, -8732.4, -416.4, 83.38, 2.45, 0, 0, 0.940806, 0.338946, 300, 100, 1, '', 'CoA Northshire class chain: the ledge above the pool 10 yd south of the SOURCED-ATLAS sighting of goober 251653, which lies on a 55-63 degree cliff face where the stand-in model floated up to 6 yd; z is the lowest floor under its footprint (83.38-84.33); faces the pool and the visit marker'),
(7912103, 9301101, 0, 0, 0, 1, 1, -8909.4, -183.3, 81.939, 1.2, 0, 0, 0.564642, 0.825336, 60, 100, 1, '', 'CoA Northshire class chain: Northshire Abbey, entry chapel floor beside the tall book stack, far from Soridormi''s library'),
(7912104, 9301102, 0, 0, 0, 1, 1, -8898.6, -181.2, 81.939, 2.9, 0, 0, 0.992713, 0.120503, 60, 100, 1, '', 'CoA Northshire class chain: Northshire Abbey, main hall, at the foot of the first stone bust (the riddle''s "silent watchers")'),
(7912105, 9301103, 0, 0, 0, 1, 1, -8941, -417.5, 66.024, 0.6, 0, 0, 0.29552, 0.955336, 60, 100, 1, '', 'CoA Northshire class chain: trail north of the Defias camp fire, where the chaplain fled'),
(7912106, 9301103, 0, 0, 0, 1, 1, -8931, -409, 66.564, 2.2, 0, 0, 0.891207, 0.453596, 60, 100, 1, '', 'CoA Northshire class chain: further along the same trail toward the river; a second spot so two players need not wait'),
(7912107, 9301104, 0, 0, 0, 1, 1, -8779.3, -115.8, 82.641, 0.4, 0, 0, 0.198669, 0.980067, 120, 100, 1, '', 'CoA Northshire class chain: north kobold camp, beside the wheelbarrow'),
(7912108, 9301104, 0, 0, 0, 1, 1, -8763.5, -124.8, 83.527, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Northshire class chain: north kobold camp, behind the tent'),
(7912109, 9301104, 0, 0, 0, 1, 1, -8775.5, -121.5, 82.964, 4.1, 0, 0, 0.887362, -0.461073, 120, 100, 1, '', 'CoA Northshire class chain: north kobold camp, west of the campfire'),
(7912110, 9301104, 0, 0, 0, 1, 1, -8756.5, -193.8, 85.762, 1.1, 0, 0, 0.522687, 0.852525, 120, 100, 1, '', 'CoA Northshire class chain: middle kobold camp, beside the campfire'),
(7912111, 9301104, 0, 0, 0, 1, 1, -8771.8, -170.2, 82.61, 5.2, 0, 0, 0.515501, -0.856889, 120, 100, 1, '', 'CoA Northshire class chain: middle kobold camp, by the crates at the tent'),
(7912112, 9301104, 0, 0, 0, 1, 1, -8759.5, -166, 84.098, 3, 0, 0, 0.997495, 0.070737, 120, 100, 1, '', 'CoA Northshire class chain: middle kobold camp, north edge'),
(7912113, 9301104, 0, 0, 0, 1, 1, -8781, -250.8, 82.548, 0.8, 0, 0, 0.389418, 0.921061, 120, 100, 1, '', 'CoA Northshire class chain: south kobold camp, among the sacks'),
(7912114, 9301104, 0, 0, 0, 1, 1, -8808.2, -240.8, 82.188, 2.6, 0, 0, 0.963558, 0.267499, 120, 100, 1, '', 'CoA Northshire class chain: south kobold camp, by the west tent'),
(7912115, 9301104, 0, 0, 0, 1, 1, -8797.8, -246.2, 82.4, 4.5, 0, 0, 0.778073, -0.628174, 120, 100, 1, '', 'CoA Northshire class chain: south kobold camp, north side of the fire'),
(7912116, 9301104, 0, 0, 0, 1, 1, -8674.8, -117.5, 91.554, 1.7, 0, 0, 0.75128, 0.659983, 120, 100, 1, '', 'CoA Northshire class chain: Echo Ridge Mine mouth, west side'),
(7912117, 9301104, 0, 0, 0, 1, 1, -8664, -126, 91.492, 5.9, 0, 0, 0.190423, -0.981702, 120, 100, 1, '', 'CoA Northshire class chain: Echo Ridge Mine mouth, inside the entrance');
