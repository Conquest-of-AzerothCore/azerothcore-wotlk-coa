-- CoA Brill: the Beginner's Book of Ascension and Deathguard Simmer stand in town, as on the live realm
-- (Ascension stream UGryc1wOL_g, 2026-08-29, Brill at 4:50-8:00). Creature guid 9005100.

-- Beginner's Book of Ascension (75118): client QuestSuperTrack node 8868 (quest 1903520, start) in Brill beside the
-- small stone house off the square; Questie-X-AscensionDB (61.4, 53.0) and Descension 7000016 agree within 1.2 yd.
-- Faces the fountain.
DELETE FROM `creature` WHERE `guid` = 9005100;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9005100, 75118, 0, 0, 0, 1, 1, 0, 2238.95, 259.03, 34.12, 1.03, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Beginner''s Book of Ascension in Brill (QuestSuperTrack 8868)');

-- Deathguard Simmer (29794): the 2026-08-29 stream shows him on the grass east of the Brill road, the farm wagon
-- (FK_Wagon01, patch-WB1) at his north side and Deathguard Lawrence to the south; the post is estimated from that
-- frame. QuestSuperTrack 3471 marks the start of his quest 365 north of Brill (2303, 1349), near the Deathknell
-- road post that rev_20260926_13 gave him.
UPDATE `creature` SET `position_x` = 2298, `position_y` = 385, `position_z` = 34.21, `orientation` = 1.75 WHERE `guid` = 29794 AND `id` = 1519;
