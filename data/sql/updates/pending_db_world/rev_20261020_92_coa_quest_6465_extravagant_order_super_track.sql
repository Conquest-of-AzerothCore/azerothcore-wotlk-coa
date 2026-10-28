-- Extravagant Order (17001): the in-world diamond and minimap pin for the turn-in sat 11 yd from Tharynn Bouden.
--
-- The client resolves the tracked quest's diamond from QuestSuperTrack.dbc (quest -> SuperTrack nodes per objective)
-- and SuperTrack.dbc (node -> map, x, y, z, radius). QuestSuperTrack row 40 (quest 17001) sends the completion to
-- SuperTrack node 1080 at (-9496.32, 72.83, 56.6), which is Remy "Two Times" 241's spawn (creature guid 80326 in
-- data/sql/base/db_world/creature.sql) and the completion node of his own quest 47 (QuestSuperTrack row 39). Node 1080
-- cannot move without moving 47's diamond, so 17001's completion gets its own node.
--
-- The core streams coa_client_quest_super_track as SMSG_PATCH_QUEST_SUPER_TRACK (0x06BF) and coa_client_super_track as
-- SMSG_PATCH_SUPER_TRACK (0x06BE) at login. A streamed QuestSuperTrack row is sent whole, so row 40 repeats the
-- client's own objective 0 node 43 (the Jasperlode Mine) next to the new completion node.
--
-- WHERE EACH VALUE COMES FROM
--   QuestSuperTrack row 40, quest 17001, objective 0 node 43  SOURCED-CLIENT: QuestSuperTrack.dbc of the installed
--     client (row 40: field 1 = 17001, field 2 = 43, field 82 = 1080, every other node 0).
--   node position  SOURCED-CORE: Tharynn Bouden 66, creature guid 80327 at (-9494.13, 83.9096, 56.6586) in
--     data/sql/base/db_world/creature.sql, unchanged by every update; quest 17001 starts and ends with him
--     (rev_20260923_01_coa_elwynn_quests.sql) and its world-map turn-in pin already stands there
--     (rev_20261009_00_coa_quest_6977_goldshire_objective_markers.sql).
--   node 21098  an id inside the client's SuperTrack range (max 21632) with no SuperTrack row, no NextID and no
--     QuestSuperTrack reference, and no coa_client_super_track row; the client does not find ids above its max.
--   MapID 0, Radius 5.5, NextID 0, Flags 0  the values of node 1080 in the client's SuperTrack.dbc.
--
-- Idempotent: exact-key deletes before the inserts.

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

CREATE TABLE IF NOT EXISTS `coa_client_quest_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `QuestID` INT UNSIGNED NOT NULL,
  `ObjectiveIndex` TINYINT NOT NULL COMMENT '0-3 objective, -1 completion',
  `NodeIndex` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0-19',
  `SuperTrackID` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`, `ObjectiveIndex`, `NodeIndex`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_super_track` WHERE `ID` = 21098;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21098, 0, -9494.13, 83.9096, 56.6586, 5.5, 0, 0);

DELETE FROM `coa_client_quest_super_track` WHERE `ID` = 40;
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(40, 17001, 0, 0, 43),
(40, 17001, -1, 0, 21098);
