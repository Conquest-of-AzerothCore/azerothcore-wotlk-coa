-- Conquest of Azeroth, Teldrassil stock content outside Dolanaar and the Vulture Cult ground.
--
-- WHERE EACH VALUE COMES FROM
--   next-quest links  SOURCED-CACHE: questcache NextQuestInChain of 917, 921, 923, 928, 937, 3521 and
--     4495. The core offers RewardNextQuest at turn-in when the same NPC starts it
--     (PlayerQuest.cpp:231-259, QuestHandler.cpp:300); each next quest starts at the NPC that ends the
--     previous one.
--   2459 slots  SOURCED-CACHE: the jewel 8050 is RequiredItemId1, as the cache and QuestSuperTrack's
--     objective 1 (ST3679 at the Ferocitas camp) have it; the Mystics stay in RequiredNpcOrGo2. The
--     jewel's map blob (quest_poi id 3) follows it: ObjectiveIndex 4 + item slot (QueryHandler.cpp:452).
--   cave graveyards  SOURCED-CLIENT: CoA AreaTable gives Shadowthread Cave 257, Fel Rock 258 and
--     Ban'ethil Barrow Den 262/10133 parent 0 and WMOAreaTable maps the cave WMOs to them, so the cave is
--     the zone and graveyard_zone had no link (GameGraveyard.cpp:145-170 then falls back to Westfall).
--     DERIVED: each cave takes the links its stock parent zone has, which restores the stock nearest
--     graveyard.
--   top-ups  STANDARDS G2 (487 needs 18 Ambushers, 2459 needs 21 Mystics for 7 kills). Hand-placed
--     literal points in the stock camps; z from the server floor; reasons in each spawn comment.
--   Shal'Athil  DERIVED: CoA built a walled druid enclave over two Elder Nightsabers and two herb nodes;
--     each moves to the nearest open forest outside the walls (INFERRED spot, reason in the comment).
--
-- Blocks: creature guid 9007600-9007699. 7 next-quest links, 1 objective slot fix, 13 graveyard links, 6
-- Ambushers, 12 Mystics, 3 creature and 4 object moves.

-- ---------------------------------------------------------------------------
-- 1. Quest rows
-- ---------------------------------------------------------------------------
-- 917 Webwood Egg -> 920 Tenaron's Summons: Gilshalan Windwalker 2082 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 920 WHERE `ID` = 917;
-- 921 Crown of the Earth -> 928 Crown of the Earth: Tenaron Stormgrip 3514 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 928 WHERE `ID` = 921;
-- 928 Crown of the Earth -> 929 Crown of the Earth: Corithras Moonrage 3515 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 929 WHERE `ID` = 928;
-- 3521 Iverron's Antidote -> 3522 Iverron's Antidote: Dirania Silvershine 8583 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 3522 WHERE `ID` = 3521;
-- 4495 A Good Friend -> 3519 A Friend in Need: Iverron 8584 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 3519 WHERE `ID` = 4495;
-- 923 Tumors -> 2498 Return to Denalan: Rellian Greenspyre 3517 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 2498 WHERE `ID` = 923;
-- 937 The Enchanted Glade -> 940 Teldrassil: Arynia Cloudsbreak 3519 ends the one and starts the other.
UPDATE `quest_template` SET `RewardNextQuest` = 940 WHERE `ID` = 937;

-- 2459 Ferocitas the Dream Eater: the jewel moves from item slot 3 to slot 1.
UPDATE `quest_template` SET `RequiredItemId1` = 8050, `RequiredItemCount1` = 1, `RequiredItemId3` = 0, `RequiredItemCount3` = 0 WHERE `ID` = 2459;
UPDATE `quest_poi` SET `ObjectiveIndex` = 4 WHERE `QuestID` = 2459 AND `id` = 3 AND `ObjectiveIndex` = 6;
-- 2459 progress text: CoA's version adds a closing sentence (AscensionES archive pEN).
UPDATE `quest_request_items` SET `CompletionText` = 'Ferocitas and the Gnarlpine Mystics must return what is mine. Please retrieve the emerald so that I may repair my emerald dreamcatcher.$B$BMake sure to take the gem out of that necklace first, I don''t need the rest of it.' WHERE `ID` = 2459;

-- ---------------------------------------------------------------------------
-- 2. Cave graveyards
-- ---------------------------------------------------------------------------
-- 257 Shadowthread Cave: inside the new Shadowglen zone 10143, whose only link is 93.
-- 258 Fel Rock: stock parent Teldrassil 141.
-- 262 Ban'ethil Barrow Den: stock parent Teldrassil 141.
-- 10133 Ban'ethil Barrow Den: CoA's second area id for the same barrow (WMO groups).
DELETE FROM `graveyard_zone` WHERE `GhostZone` IN (257, 258, 262, 10133);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(93, 257, 0, 'Shadowthread Cave - Teldrassil, Aldrassil GY'),
(90, 258, 469, 'Fel Rock - Teldrassil, Darnassus GY'),
(91, 258, 0, 'Fel Rock - Teldrassil, Dolanaar GY'),
(93, 258, 469, 'Fel Rock - Teldrassil, Aldrassil GY'),
(129, 258, 0, 'Fel Rock - Teldrassil, Rut''theran Village GY'),
(90, 262, 469, 'Ban''ethil Barrow Den - Teldrassil, Darnassus GY'),
(91, 262, 0, 'Ban''ethil Barrow Den - Teldrassil, Dolanaar GY'),
(93, 262, 469, 'Ban''ethil Barrow Den - Teldrassil, Aldrassil GY'),
(129, 262, 0, 'Ban''ethil Barrow Den - Teldrassil, Rut''theran Village GY'),
(90, 10133, 469, 'Ban''ethil Barrow Den - Teldrassil, Darnassus GY'),
(91, 10133, 0, 'Ban''ethil Barrow Den - Teldrassil, Dolanaar GY'),
(93, 10133, 469, 'Ban''ethil Barrow Den - Teldrassil, Aldrassil GY'),
(129, 10133, 0, 'Ban''ethil Barrow Den - Teldrassil, Rut''theran Village GY');

-- ---------------------------------------------------------------------------
-- 3. Gnarlpine Ambushers (487) and Gnarlpine Mystics (2459)
-- ---------------------------------------------------------------------------
-- 487: 15 stock Ambushers + 6 in Ban'ethil Hollow. 2459: 9 stock Mystics + 12 in and around the Ferocitas camp.
DELETE FROM `creature` WHERE `guid` IN (9007600, 9007601, 9007602, 9007603, 9007604, 9007605, 9007606, 9007607, 9007608, 9007609, 9007610, 9007611, 9007612, 9007613, 9007614, 9007615, 9007616, 9007617) OR `guid` BETWEEN 9007600 AND 9007699;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9007600, 2152, 1, 0, 0, 1, 1, 0, 10012, 1375, 1283.371, 4.64, 300, 5, 0, 120, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: south end of Ban''ethil Hollow where the floor narrows toward the ridge road, between the two southern Ambushers; faces the road vantage (10004, 1259) where Amara''s patrol turns'),
(9007601, 2152, 1, 0, 0, 1, 1, 0, 10038, 1398, 1276.593, 4.47, 300, 5, 0, 120, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: east floor of Ban''ethil Hollow under the ridge, 14 yd south-west of the Fel Cone; faces the road vantage'),
(9007602, 2152, 1, 0, 0, 1, 1, 0, 10028, 1432, 1275.917, 4.57, 300, 5, 0, 120, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: hollow floor just north of the great Kalidartree02, 20 yd from the objective point ST3677; faces the road vantage'),
(9007603, 2152, 1, 0, 0, 1, 1, 0, 10070, 1440, 1276.912, 3.66, 300, 5, 0, 120, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: at the mouth of Agal''s den (Md_Jungleden), watching the hollow floor'),
(9007604, 2152, 1, 0, 0, 1, 1, 0, 10026, 1490, 1284.627, 5.07, 300, 5, 0, 120, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: west slope of the hollow, where the ground climbs toward the Barrow Den; faces the objective point ST3677'),
(9007605, 2152, 1, 0, 0, 1, 1, 0, 9990, 1500, 1294.93, 5.3, 300, 5, 0, 120, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: south-west rim on the way down from the Barrow Den, between the two rim Ambushers; faces the hollow floor'),
(9007606, 7235, 1, 0, 0, 1, 1, 1, 10006, 290, 1320.923, 6.04, 300, 0, 0, 115, 126, 0, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: 16 yd south of Ferocitas''s campfire (10021.8, 286.0), 10 yd from the furbolg totem; faces the fire'),
(9007607, 7235, 1, 0, 0, 1, 1, 1, 10030, 270, 1324.185, 2.4, 300, 0, 0, 115, 126, 0, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: beside the animal cages at the back of Ferocitas''s tent, guarding the captives; faces the cages'),
(9007608, 7235, 1, 0, 0, 1, 1, 1, 10044, 300, 1323.833, 3.7, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: on the trail between the two fires of the Ferocitas camp; faces Ferocitas''s campfire (10021.8, 286.0)'),
(9007609, 7235, 1, 0, 0, 1, 1, 1, 10016, 310, 1320.519, 2.29, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: west side of the Ferocitas camp, 11 yd north of the Kalidartree07; faces the western approach from Dolanaar'),
(9007610, 7235, 1, 0, 0, 1, 1, 1, 10072, 342, 1323.489, 3.83, 300, 0, 0, 115, 126, 0, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: beyond the drum tent, 14 yd from the second totem; faces the drum circle campfire (10056.5, 323.4)'),
(9007611, 7235, 1, 0, 0, 1, 1, 1, 10046, 250, 1326.614, 1.84, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: east side of the Ferocitas camp, 5 yd north of the Kalidartree03; faces the camp centre'),
(9007612, 7235, 1, 0, 0, 1, 1, 1, 9995, 330, 1316.885, 2.43, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: south-west approach to the Ferocitas camp on the way up from Starbreeze; faces down the approach'),
(9007613, 7235, 1, 0, 0, 1, 1, 1, 9978, 262, 1324.854, 3.14, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: south approach to the Ferocitas camp on the trail up from Starbreeze, clear of the Kalidartree01 root shelf; faces south toward Starbreeze'),
(9007614, 7235, 1, 0, 0, 1, 1, 1, 10045, 312, 1323.022, 0.78, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: trail between the fires, 16 yd short of the drum circle campfire (10056.5, 323.4); faces the drum circle'),
(9007615, 7235, 1, 0, 0, 1, 1, 1, 10085, 340, 1324.281, 3.67, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: north edge of the drum circle ground, 33 yd from the fire; faces the drum circle campfire (10056.5, 323.4)'),
(9007616, 7235, 1, 0, 0, 1, 1, 1, 10000, 250, 1327.872, 1.03, 300, 5, 0, 115, 126, 1, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: south-east slope below the Ferocitas camp, a lookout over the tents; faces the camp'),
(9007617, 7235, 1, 0, 0, 1, 1, 1, 10072, 317, 1324.984, 2.75, 300, 0, 0, 115, 126, 0, 0, 0, 0, '', NULL, 0, 'CoA Teldrassil: north of the drum tent, 6 yd from the Battered Chest; faces the drum circle campfire (10056.5, 323.4)');

-- ---------------------------------------------------------------------------
-- 4. Shal'Athil and its edge
-- ---------------------------------------------------------------------------
-- Each UPDATE matches guid and entry, so a row something else has changed is left alone.
-- Elder Nightsaber (49832): stood in the middle of CoA's Shal'Athil enclave (floating 0.69); moved to the forest
-- floor 44 yd north of the north moongate by the Kalidartree07 roots (the ground right outside the north wall is
-- a root shelf cut off from the navmesh).
UPDATE `creature` SET `position_x` = 10388, `position_y` = 1455, `position_z` = 1332.98 WHERE `guid` = 49832 AND `id` = 2033;
-- Elder Nightsaber (49834): stood on the Shal'Athil gazebo's druid base; moved to the forest floor south of the
-- enclave, 20 yd past the fallen Kalidartreelog01 and 17 yd off the signpost road (the ground right outside the
-- south wall is a root shelf cut off from the navmesh).
UPDATE `creature` SET `position_x` = 10200, `position_y` = 1450, `position_z` = 1329.86 WHERE `guid` = 49834 AND `id` = 2033;
-- Strigid Owl (47359): CoA raised the ground 0.6 yd at the edge of Shal'Athil; same x and y, z from the CoA
-- floor.
UPDATE `creature` SET `position_x` = 10219.1, `position_y` = 1479.88, `position_z` = 1330.947 WHERE `guid` = 47359 AND `id` = 1995;
-- Mageroyal (10319): sunk 0.64 in the druid base of the enclave's south gazebo; moved outside the enclave's east
-- wall to flat forest floor below the wall-top ash trees.
UPDATE `gameobject` SET `position_x` = 10315, `position_y` = 1392, `position_z` = 1338.302 WHERE `guid` = 10319 AND `id` = 1620;
-- Silverleaf (10360): floating 3.4 over the druid-cat statue base at the east moongate; moved outside the
-- enclave's east wall, 37 yd north-east of the moongate and 15 yd from the moved Mageroyal.
UPDATE `gameobject` SET `position_x` = 10300, `position_y` = 1392, `position_z` = 1341.407 WHERE `guid` = 10360 AND `id` = 1617;

-- ---------------------------------------------------------------------------
-- 5. Herb nodes clipped by CoA's new trees
-- ---------------------------------------------------------------------------
-- Each UPDATE matches guid and entry and keeps the pool and the facing.
-- Silverleaf (10357): pool 427; its stock spot is inside the trunk of a Kalidartree01 CoA added (0.35 yd); moved
-- 1.7 yd south-west to the open slope beside the trunk, clear of it.
UPDATE `gameobject` SET `position_x` = 9431.5, `position_y` = 956.1, `position_z` = 1267.303 WHERE `guid` = 10357 AND `id` = 1617;
-- Silverleaf (10391): pool 426; its stock spot sits on a root of a CoA Kalidartree01, 0.2 yd from the trunk;
-- moved 2.4 yd south onto the open ground below the trunk, clear of the roots.
UPDATE `gameobject` SET `position_x` = 9997.5, `position_y` = 1541, `position_z` = 1304.222 WHERE `guid` = 10391 AND `id` = 1617;
