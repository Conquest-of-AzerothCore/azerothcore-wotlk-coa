-- CoA: quest 337 'An Old History Book' pointed its map pin, its minimap pin and its in-world arrow at the stock
-- Royal Library spot, which CoA rebuilt elsewhere in Stormwind Keep, instead of at Milton Sheaf 1440 who ends it
-- (#6444).
--
-- Both marker routes are corrected, as for quest 2745 (rev_20261011_91/92):
--   map pin  quest_poi 337 id 2 (ObjectiveIndex -1, the turn-in; MapID 0, WorldMapAreaId 301, Flags 3) answers
--     CMSG_QUEST_POI_QUERY with its single quest_poi_points row (337, 2, 0).
--   arrow and minimap pin  the client resolves them from its own QuestSuperTrack.dbc row 2300 (quest 337), whose
--     completion slot leads to SuperTrack.dbc node 607; the core streams coa_client_super_track rows over the
--     client's SuperTrack rows at login (AscensionCompat, SMSG_PATCH_SUPER_TRACK 0x06BE).
--
-- WHERE EACH VALUE COMES FROM
--   Milton's spot  SOURCED-CORE: rev_20260923_03_coa_stormwind.sql moves Milton Sheaf 1440 (guid 8704) into the
--     CoA Royal Library at (-8279.309, 226.965, 155.447), the stock library room translated by
--     (+66.691, -156.963, +33.073) with its tables, shelves and candelabras matching to 0.01 yd.
--   stale point  SOURCED-CORE: quest_poi_points (337, 2, 0) still holds the stock spot (-8346, 384), 171 yd from
--     Milton. rev_20260924_60_coa_quest_markers.sql left Milton's quests alone only because the CoA arrow would
--     then disagree with the map; node 607 below moves the arrow with it.
--   new point  DERIVED: Milton's spawn rounded to the integer grid quest_poi_points uses (-8279, 227).
--   stale node  SOURCED-CLIENT: SuperTrack.dbc node 607 is (MapID 0, -8346.0, 383.928, 122.274, Radius 5.5,
--     NextID 0, Flags 0), the stock library floor.
--   new node  SOURCED-CORE: Milton's spawn position exactly; Z is the CoA library floor he stands on.
--     MapID 0, Radius 5.5, NextID 0 and Flags 0 are the client's own values for node 607 and are kept.
-- Node 607 is also the completion node of QuestSuperTrack rows 1071 (quest 343 'Speaking of Fortitude') and 2446
-- (quest 542 'Return to Milton'), which Milton ends too, so their arrows follow him as well. No other row uses it.
--
-- Idempotent: an exact-key update and an exact-key delete before the insert.

UPDATE `quest_poi_points` SET `X` = -8279, `Y` = 227 WHERE (`QuestID`, `Idx1`, `Idx2`) = (337, 2, 0);

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

DELETE FROM `coa_client_super_track` WHERE `ID` = 607;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(607, 0, -8279.309, 226.965, 155.447, 5.5, 0, 0);
