-- Quenching The Thirst (175134, #10364): each patron took the one Nivelarn Beer, so after the first mug every other
-- patron only showed a greeting. On live the beer is a reusable item (5 s cooldown) and three patrons were served
-- with it without going back to Dalignir (RIEMlZSgbQw 7:44:40-7:45:30). Patrons now keep the beer and take it
-- back with the third mug.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164382, 164383) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164382, 0, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164382, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - On Gossip Hello - Quest Credit Mugs of beer served (175134)'),
(164382, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - Linked - Play Emote Cheer'),
(164382, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - Linked - Remove Gossip Flag'),
(164382, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - Linked - Create Timed Event 1 (60 s)'),
(164382, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - On Timed Event 1 - Add Gossip Flag'),
(164382, 0, 5, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 57, 559922, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - On Gossip Hello - Take Nivelarn Beer after the third mug'),
(164383, 0, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164382, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - On Gossip Hello - Quest Credit Mugs of beer served (175134)'),
(164383, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - Linked - Play Emote Cheer'),
(164383, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - Linked - Remove Gossip Flag'),
(164383, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - Linked - Create Timed Event 1 (60 s)'),
(164383, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - On Timed Event 1 - Add Gossip Flag'),
(164383, 0, 5, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 57, 559922, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patron - On Gossip Hello - Take Nivelarn Beer after the third mug');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` IN (1, 6) AND `SourceEntry` IN (164382, 164383) AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 164382, 0, 0, 2, 0, 559922, 1, 0, 0, 0, 0, '', 'Patron: player carries Nivelarn Beer'),
(22, 1, 164382, 0, 0, 9, 0, 175134, 0, 0, 0, 0, 0, '', 'Patron: player on Quenching The Thirst'),
(22, 6, 164382, 0, 0, 2, 0, 559922, 1, 0, 0, 0, 0, '', 'Patron beer back: player carries Nivelarn Beer'),
(22, 6, 164382, 0, 0, 48, 0, 175134, 1, 3, 0, 0, 0, '', 'Patron beer back: 3 mugs served'),
(22, 1, 164383, 0, 0, 2, 0, 559922, 1, 0, 0, 0, 0, '', 'Patron: player carries Nivelarn Beer'),
(22, 1, 164383, 0, 0, 9, 0, 175134, 0, 0, 0, 0, 0, '', 'Patron: player on Quenching The Thirst'),
(22, 6, 164383, 0, 0, 2, 0, 559922, 1, 0, 0, 0, 0, '', 'Patron beer back: player carries Nivelarn Beer'),
(22, 6, 164383, 0, 0, 48, 0, 175134, 1, 3, 0, 0, 0, '', 'Patron beer back: 3 mugs served');

-- Belorite Sprites (175095, #11089): all 18 Belorita grew within 50 yd of Meredyl. On live the ten flowers were
-- picked one by one in the Gilded Vale forest between Furious Treant and pinecone pickups (i5vATMYui0I
-- 10:44-15:16). Thirteen move into that forest beside the treant and pinecone spawns; five stay by the stream.
UPDATE `gameobject` SET `position_x` = -7405, `position_y` = 52, `position_z` = 181.865, `Comment` = 'Belorita: forest east of the stream' WHERE `guid` = 9983063 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7455, `position_y` = 60, `position_z` = 183.58, `Comment` = 'Belorita: forest north of Meredyl' WHERE `guid` = 9983065 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7476, `position_y` = 68, `position_z` = 181.875, `Comment` = 'Belorita: forest north-west of Meredyl' WHERE `guid` = 9983066 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7438, `position_y` = 68, `position_z` = 183.629, `Comment` = 'Belorita: forest north-east of Meredyl' WHERE `guid` = 9983068 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7476, `position_y` = 86, `position_z` = 181.392, `Comment` = 'Belorita: forest by the treants' WHERE `guid` = 9983070 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7406, `position_y` = 102, `position_z` = 183.123, `Comment` = 'Belorita: eastern forest slope' WHERE `guid` = 9983071 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7444, `position_y` = 116, `position_z` = 182.128, `Comment` = 'Belorita: mid forest' WHERE `guid` = 9983072 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7490, `position_y` = 115, `position_z` = 181.673, `Comment` = 'Belorita: western forest' WHERE `guid` = 9983073 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7462, `position_y` = 135, `position_z` = 181.17, `Comment` = 'Belorita: mid forest by the treants' WHERE `guid` = 9983074 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7380, `position_y` = 148, `position_z` = 179.158, `Comment` = 'Belorita: eastern forest' WHERE `guid` = 9983075 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7450, `position_y` = 162, `position_z` = 181.367, `Comment` = 'Belorita: northern forest' WHERE `guid` = 9983076 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7410, `position_y` = 192, `position_z` = 178.34, `Comment` = 'Belorita: north-eastern forest' WHERE `guid` = 9983077 AND `id` = 2300686;
UPDATE `gameobject` SET `position_x` = -7470, `position_y` = 210, `position_z` = 177.723, `Comment` = 'Belorita: north-western forest' WHERE `guid` = 9983078 AND `id` = 2300686;

-- The two seated Thirsty Northerners sat on their chairs' model origins, which lie 0.4 yd in front of the seats
-- (GeneralChairLoEnd01 in Snow_Inn), so they hung off the front edge and above the seat. They sit 0.28 yd in front of
-- the seat's middle with the low-chair sit, raised 0.12 yd, clear of the table tops.
UPDATE `creature` SET `position_x` = -6453.34, `position_y` = 70.51, `position_z` = 518.89 WHERE `guid` = 9985001 AND `id` = 164383;
UPDATE `creature` SET `position_x` = -6452.99, `position_y` = 74.25, `position_z` = 518.89 WHERE `guid` = 9985002 AND `id` = 164383;
UPDATE `creature_addon` SET `bytes1` = 4 WHERE `guid` IN (9985001, 9985002);

-- The other two seated patrons, Northerner 9985003 and Nivelarn Regular 9985022, sat on their chairs' origins the same
-- way and move onto the seats as well. Gorlin (9962259) used a chair sit beside his table with no chair in his room,
-- so he sits on the floor.
UPDATE `creature` SET `position_x` = -6450.96, `position_y` = 76.55, `position_z` = 518.89 WHERE `guid` = 9985003 AND `id` = 164383;
UPDATE `creature` SET `position_x` = -6450.86, `position_y` = 68.19, `position_z` = 518.89 WHERE `guid` = 9985022 AND `id` = 164384;
UPDATE `creature_addon` SET `bytes1` = 4 WHERE `guid` IN (9985003, 9985022);
UPDATE `creature_addon` SET `bytes1` = 1 WHERE `guid` = 9962259;
