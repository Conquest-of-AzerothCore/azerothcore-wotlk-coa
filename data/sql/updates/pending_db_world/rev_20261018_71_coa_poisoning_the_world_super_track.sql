-- Poisoning the World (200025 Shadowglen, 200026 Valley of Trials): the in-world diamond for the tracked quest.
--
-- The client resolves that diamond from QuestSuperTrack.dbc (quest -> SuperTrack nodes per objective) and
-- SuperTrack.dbc (node -> map, x, y, z, radius). The start-zone class quests have no QuestSuperTrack row, so the
-- client falls back to the quest_poi area, which has no height and puts the diamond off its target (Exodite
-- Telusaara stands on an upper floor of Aldrassil, z 1346.75).
--
-- The core streams coa_client_quest_super_track as SMSG_PATCH_QUEST_SUPER_TRACK (0x06BF) and coa_client_super_track
-- as SMSG_PATCH_SUPER_TRACK (0x06BE) at login. Each objective now points at its trainer's own spawn and the
-- completion at the quest's trainer. Radius 5.5 is the client table's most common value.
--
-- QuestSuperTrack 33201-33202 are new rows above the client's max (33141), which the client finds. A SuperTrack id
-- above the client's max (21632) is never found and the diamond falls back to the quest_poi area, so the nodes take
-- 21083-21090, ids inside the client's range with no SuperTrack row, no NextID and no QuestSuperTrack reference.

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

DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 21083 AND 21090;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21083, 1, 10458.2, 807.65, 1346.75, 5.5, 0, 0),
(21084, 1, 10434.3, 795.62, 1322.7, 5.5, 0, 0),
(21085, 1, 10386.7, 811.88, 1317.53, 5.5, 0, 0),
(21086, 1, 10405.4, 717.75, 1321.65, 5.5, 0, 0),
(21087, 1, -619.9, -4313.76, 40.291, 5.5, 0, 0),
(21088, 1, -633.42, -4287.44, 39.825, 5.5, 0, 0),
(21089, 1, -641.03, -4229.15, 38.135, 5.5, 0, 0),
(21090, 1, -558.66, -4195.2, 46.396, 5.5, 0, 0);

DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (33201, 33202);
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(33201, 200025, 0, 0, 21083),
(33201, 200025, 1, 0, 21084),
(33201, 200025, 2, 0, 21085),
(33201, 200025, -1, 0, 21086),
(33202, 200026, 0, 0, 21087),
(33202, 200026, 1, 0, 21088),
(33202, 200026, 2, 0, 21089),
(33202, 200026, -1, 0, 21090);
