-- Vaults of Inquisition (map 936) and Road to De Other Side (map 937) come out of Dungeon Finder.
-- DISABLE_TYPE_LFG_MAP locks both out of LFGMgr::InitializeLockedDungeons for every difficulty tier,
-- which also drops them from CachedDungeonMapStore's random-group results; neither map has a non-LFG
-- entrance, so this is the whole removal, not just the random pool.
DELETE FROM `disables` WHERE `sourceType` = 8 AND `entry` IN (936, 937);
INSERT INTO `disables` (`sourceType`, `entry`, `flags`, `params_0`, `params_1`, `comment`) VALUES
(8, 936, 0, '', '', 'Vaults of Inquisition removed from Dungeon Finder'),
(8, 937, 0, '', '', 'Road to De Other Side removed from Dungeon Finder');
