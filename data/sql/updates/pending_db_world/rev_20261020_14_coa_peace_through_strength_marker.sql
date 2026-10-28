-- Peace Through Strength (#8019): the Guardian quest had no map marker in Northshire.
--
-- 200114 is the Northshire variant (starter Vanguard Gus 50324, ender Lil Wa'zoo 85031 inside
-- the Kobold mine). Of the six variants only 200140 (Deathknell) received a quest_poi row in
-- rev_20261007_95, so 200114 showed no objective or turn-in pin. The quest has no kill/item
-- objective, so its single marker is the turn-in at the ender. Northshire quests use the CoA
-- starting-zone map 1237 (see 200104/200106). The spawn's addon also pinned Lil Wa'zoo to the
-- kneel state (bytes1 8), which reads as a frozen statue; return him to the standing idle pose.

UPDATE `creature_addon` SET `bytes1` = 0 WHERE `guid` = 9003121 AND `path_id` = 0;

DELETE FROM `quest_poi` WHERE `QuestID` = 200114;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(200114, 0, -1, 0, 1237, 0, 0, 1, NULL);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 200114;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(200114, 0, 0, -8629, -110, NULL);
