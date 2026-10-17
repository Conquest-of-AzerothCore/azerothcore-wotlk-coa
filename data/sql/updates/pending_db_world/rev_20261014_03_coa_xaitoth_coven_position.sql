-- CoA: Xaitoth, the demon of 'A Dangerous Sample' (254009), stood at the mouth of the Burning Blade Coven,
-- passive, with the quest marker on top of him. He belongs in the middle hall, beside Thazz'ril's Pick,
-- hostile like the other coven demons (Vile Familiar and Felstalker use faction 14).
--
-- Three routes show the marker, and each needs its own row:
--   quest_poi_points           the world-map pin, asked for with CMSG_QUEST_POI_QUERY.
--   coa_client_super_track     the in-world arrow and minimap diamond, which the client resolves from its own
--                              QuestSuperTrack.dbc / SuperTrack.dbc rows. QuestSuperTrack 8990 (quest 254009)
--                              sends objective 0 to SuperTrack 3456 at (-179.73, -4360.58, 68.479), the old
--                              spawn; only quest 254009 references node 3456. The core streams the row to the
--                              client at login (SMSG_PATCH_SUPER_TRACK), so no client patch is needed.
--                              MapID 1, Radius 5.5, NextID 0 and Flags 0 are the client's own values.
--   creature                   the spawn itself.
-- Position: the spot a player marked in-game with .gps in the middle hall, 17 yd from the pick.
--
-- Idempotent: exact-key updates and an exact-key delete before the insert.

UPDATE `creature_template` SET `faction` = 14 WHERE `entry` = 254015;

UPDATE `creature` SET `position_x` = -94.136, `position_y` = -4290.211, `position_z` = 61.294, `orientation` = 3.578,
    `Comment` = 'CoA Sakari: Burning Blade Coven, middle hall near Thazz''ril''s Pick (in-game .gps by the reporter)'
WHERE `guid` = 9012551 AND `id` = 254015;

UPDATE `quest_poi_points` SET `X` = -94, `Y` = -4290 WHERE `QuestID` = 254009 AND `Idx1` = 1 AND `Idx2` = 0;

CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_super_track` WHERE `ID` = 3456;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(3456, 1, -94.136, -4290.211, 61.294, 5.5, 0, 0);
