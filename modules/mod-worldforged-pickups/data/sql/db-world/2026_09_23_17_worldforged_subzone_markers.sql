-- ----------------------------------------------------------------------------
-- Worldforged pickups: five rows put back on the map's own sub-zone page markers
-- ----------------------------------------------------------------------------
-- The Westfall and Burning Steppes passes dropped these five rows believing no marker of
-- any page plotted them.  They read a marker set built with an outside bounds table that
-- had no rectangle for the map's sub-zone pages (the Jangolode Mine, the Gold Coast
-- Quarry, Blackrock Mountain, the Grizzled Den, Coldridge Pass and forty more), so the
-- 380 markers on those pages were invisible to them.  With the complete set every one of
-- the five stands 0.0 yd from a marker of its own object:
--
--   Misplaced Pitchfork (515224)   marker worldforge-jangolode-mine-misplaced-pitchfork
--   Quarry Sledge (95785)          marker worldforge-gold-coast-quarry-quarry-sledge
--   Blackbreach Handaxe (686898)   marker worldforge-blackrock-mountain-blackbreach-handaxe
--   Darkest Night Ring (90288)     marker worldforge-blackrock-mountain-darkest-night-loop
--   Taskmaster's Blade (254660)    marker worldforge-blackrock-mountain-searsteel-claymore
--
-- Each is written back on its marker with the guid it had, so a database that has already
-- run the dropping migration and one that has not both end in the same state.
--
-- Idempotent.  Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Misplaced Pitchfork (515224): the map plots it at -9876.2 1440.3 on its jangolode-mine page
--   marker worldforge-jangolode-mine-misplaced-pitchfork (Misplaced Pitchfork), 0.0 yd from where it stood
--   height from the floor the realm's own props share (22 of them)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940755, 515224, 0, 0, 0, 1, 1, -9876.2000, 1440.3000, 41.3144, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Misplaced Pitchfork | marker worldforge-jangolode-mine-misplaced-pitchfork | restored: the marker stands on a page the earlier pass could not project');

-- Quarry Sledge (95785): the map plots it at -10468.5 1944.0 on its gold-coast-quarry page
--   marker worldforge-gold-coast-quarry-quarry-sledge (Quarry Sledge), 0.0 yd from where it stood
--   height from the floor the realm's own props share (36 of them)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940915, 95785, 0, 0, 0, 1, 1, -10468.5000, 1944.0000, 10.0397, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Quarry Sledge | marker worldforge-gold-coast-quarry-quarry-sledge | restored: the marker stands on a page the earlier pass could not project');

-- Blackbreach Handaxe (686898): the map plots it at -7467.5 -1117.5 on its blackrock-mountain page
--   marker worldforge-blackrock-mountain-blackbreach-handaxe (Blackbreach Handaxe), 0.0 yd from where it stood
--   height from the terrain the worldserver reads
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940123, 686898, 0, 0, 0, 1, 1, -7467.5000, -1117.5000, 792.0052, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Blackbreach Handaxe | marker worldforge-blackrock-mountain-blackbreach-handaxe | restored: the marker stands on a page the earlier pass could not project');

-- Darkest Night Ring (90288): the map plots it at -7505.8 -881.4 on its blackrock-mountain page
--   marker worldforge-blackrock-mountain-darkest-night-loop (Darkest Night Loop), 0.0 yd from where it stood
--   height from the terrain the worldserver reads
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940310, 90288, 0, 0, 0, 1, 1, -7505.8000, -881.4000, 644.8918, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Darkest Night Ring | marker worldforge-blackrock-mountain-darkest-night-loop | restored: the marker stands on a page the earlier pass could not project');

-- Taskmaster's Blade (254660): the map plots it at -7422.4 -1010.6 on its blackrock-mountain page
--   marker worldforge-blackrock-mountain-searsteel-claymore (Searsteel Claymore), 0.0 yd from where it stood
--   height from the terrain the worldserver reads
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941041, 254660, 0, 0, 0, 1, 1, -7422.4000, -1010.6000, 464.2992, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Taskmaster''s Blade | marker worldforge-blackrock-mountain-searsteel-claymore | restored: the marker stands on a page the earlier pass could not project');

COMMIT;
