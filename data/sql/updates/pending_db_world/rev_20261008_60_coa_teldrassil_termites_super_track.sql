-- CoA: 1660074 'Termites in Teldrassil' sent its tracker into the Barkshredder Queen's chamber while the
-- termites were still the outstanding objective.
--
-- The client resolves the in-world tracker and the super-track waypoint itself (C_SuperTrack): for the
-- tracked quest it takes the QuestSuperTrack.dbc row, follows the SuperTrack.dbc node of the first
-- objective that is still incomplete, then walks that node's NextID chain to the node nearest the player.
-- The client rows for this quest are
--   QuestSuperTrack 32595 (quest 1660074): objective 0 (162876 Barkshredder Termite x10) -> 8786,
--   objective 1 (162877 Barkshredder Queen x1) -> 8786 and 8787, completion -> 8785,
--   SuperTrack 8786 (9715.14, 1027.43, 1277.77) radius 4 - the crater floor at the den mouth - carried
--   NextID 8787, and 8787 is (9792.30, 956.30, 1232.30) radius 4, the queen's chamber on her own spawn
--   (guid 9007402).
-- (SOURCED-CLIENT: raw/tables/QuestSuperTrack and raw/tables/SuperTrack of the CoA client.)
--
-- From anywhere in Dolanaar the player stands nearer 8787 than 8786 - from the reported spot
-- (9812.86, 938.77) it is 21 yd against 131 yd - so the chain walk dragged the termite objective onto
-- the queen and left it there once she was dead. The core streams SuperTrack.dbc rows from
-- coa_client_super_track to the client at login (AscensionCompat, SMSG_PATCH_SUPER_TRACK), so the row
-- can be corrected without a client patch:
--   NextID 0  - breaks the chain, so objective 0 resolves to the termites' own node every time.
--   position  - the mean of the 31 termite spawns (guids 9007403-9007433, from the creature table:
--               x 9794.24, y 996.63, z 1243.08), the middle of the run the mobs patrol. The client's own
--               point sat 21 yd outside the mobs, at the den mouth, which is only their entrance.
--   MapID 1, Radius 4.0 and Flags 0 are the client's own values and are kept.
-- 8787 (the queen) and 8785 (the turn-in at Kaladir) already sit on their targets and are not touched.
-- Only quest 1660074 references these three nodes, so no other quest's route changes.
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

DELETE FROM `coa_client_super_track` WHERE `ID` = 8786;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(8786, 1, 9794.24, 996.63, 1243.08, 4.0, 0, 0);
