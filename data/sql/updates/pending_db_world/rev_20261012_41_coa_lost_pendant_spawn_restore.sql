-- Lost Pendant (200058) needs one chest, gameobject 9301103, on the crate at the Defias camp. rev_20261007_20 and
-- rev_20261007_70 place it, but a world database that lost the row afterwards (seen on a repack that had both files
-- recorded as applied and no spawn) keeps the quest with nothing to loot. The row is written again exactly as
-- rev_20261007_70 leaves it, and the pendant rev_20261007_20 put on the trail (guid 7912106) is cleared, so the valley
-- ends with the single pendant whichever state the database was in.
DELETE FROM `gameobject` WHERE `guid` IN (7912105, 7912106) AND `id` = 9301103;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(7912105, 9301103, 0, 0, 0, 1, 1, -8956.38, -435.027, 65.3559, 0.00392888, -0.0725746, -0.031781, -0.000347103, 0.996856, 60, 100, 1, '', 'CoA Northshire class chain: on the crate at the Defias camp, where the chaplain fled and dropped it; the valley''s single Lost Pendant for 200058');
