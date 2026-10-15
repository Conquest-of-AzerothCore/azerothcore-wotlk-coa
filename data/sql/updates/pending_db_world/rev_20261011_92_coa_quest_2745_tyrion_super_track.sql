-- CoA: quest 2745 'Infiltrating the Castle' still sent its in-world arrow and minimap pin 188 yd outside
-- the walls of Stormwind Keep, at the garden CoA replaced when it rebuilt the courtyard (#7005).
--
-- rev_20261011_91_coa_quest_2745_tyrion_marker.sql fixed only the static world-map pin, which is the
-- quest_poi / quest_poi_points pair a client asks for with CMSG_QUEST_POI_QUERY. The in-world 3D arrow and
-- the minimap pin are a second, independent route: the client resolves them itself from its own
-- QuestSuperTrack.dbc and SuperTrack.dbc rows (C_SuperTrack), taking the tracked quest's QuestSuperTrack
-- row, following the SuperTrack node of the objective under way, and walking that node's NextID chain to
-- the node nearest the player. The core streams SuperTrack.dbc rows from coa_client_super_track to the
-- client at login (AscensionCompat, SMSG_PATCH_SUPER_TRACK, 0x06BE), so the route can be corrected without
-- a client patch.
-- The client rows here are
--   QuestSuperTrack 234 (quest 2745): completion -> SuperTrack 164,
--   QuestSuperTrack 3139 (quest 2746): completion -> SuperTrack 164 as well (Tyrion ends both quests),
--   SuperTrack 164 at (-8409.0, 450.793, 123.76) - the stock garden, which is the ground CoA cut away
--   when it rebuilt the keep, so the pin hung in the air 188 yd from Tyrion.
-- (SOURCED-CLIENT: raw/tables/QuestSuperTrack and raw/tables/SuperTrack of the CoA client. Only 2745 and
-- 2746 reference node 164, so no other quest's route changes.)
--
-- WHERE EACH VALUE COMES FROM
--   position  SOURCED-CORE: Tyrion 7766 (guid 43667) stands in the CoA keep roof garden beside the library
--     at (-8330, 279.5, 156.833), from rev_20260923_03_coa_stormwind.sql, which the creature table
--     confirms. The node takes that spot exactly, 0.5 yd from his spawn, and the Z is the garden floor the
--     player stands on when the arrow arrives.
--   MapID 0, Radius 5.5, NextID 0, Flags 0 are the client's own values for node 164 and are kept.
--
-- Idempotent: an exact-key delete before the insert.

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

DELETE FROM `coa_client_super_track` WHERE `ID` = 164;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(164, 0, -8330, 279.5, 156.833, 5.5, 0, 0);
