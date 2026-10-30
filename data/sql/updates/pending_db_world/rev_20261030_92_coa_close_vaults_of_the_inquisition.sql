-- Vaults of the Inquisition (map 936) closed to players and in the (random) Dungeon Finder.
-- Flags 7 = Normal, Heroic and Mythic, the three MapDifficulty rows of map 936; DisableMgr skips a row naming any other.
DELETE FROM `disables` WHERE `sourceType` IN (2, 8) AND `entry` = 936;
INSERT INTO `disables` (`sourceType`, `entry`, `flags`, `params_0`, `params_1`, `comment`) VALUES
(2, 936, 7, '', '', 'Vaults of the Inquisition - closed to players'),
(8, 936, 7, '', '', 'Vaults of the Inquisition - closed in the Dungeon Finder');
