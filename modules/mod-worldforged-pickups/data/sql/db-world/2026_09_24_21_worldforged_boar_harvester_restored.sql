-- ----------------------------------------------------------------------------
-- Worldforged pickups: Homer's Boar Harvester stood back up
-- ----------------------------------------------------------------------------
-- The final authored pass (`2026_09_24_20_worldforged_authored_in_game_final.sql`) read a
-- changeset whose whole content is
--
--     SET @OGUID := 6940160;
--     DELETE FROM `gameobject` WHERE `guid` = @OGUID;
--
-- (`C:/Users/BOGDAN/Desktop/client/pro2/changesets/spawns_20260924_094425.sql`) and took it for
-- the editor having removed the object from the world.  It had not: that row was never taken out
-- of the map, and the changeset carries no rewrite because no rewrite was made.  The last row the
-- editor authored for it is the one its own previous save wrote
-- (`spawns_20260924_094300.sql`): moved 3.48 yd and turned 1.043 rad from where the map pass had
-- left it, at the Stonefield Farm.  That row is stood back here, field for field - entry, map,
-- spawn mask, phase mask, position, rotation quaternion, and the orientation column written as the
-- yaw that quaternion represents (0.835903, the same value the editor's own column states).
--
-- The object's template and its loot row are untouched: this file only puts the placement back.
--
-- Idempotent: one REPLACE keyed on the guid.
-- ----------------------------------------------------------------------------

START TRANSACTION;

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`,
 `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940160, 95690, 0, 0, 0, 1, 1, -9857.103516, 355.619141, 37.559227, 0.835903, -0.427825355,
 0.532009758, -0.296585701, -0.667808360, 0, 0, 1, 'worldforged_pickup',
 'AscensionWorldforged Homer''s Boar Harvester | in-game placement 2026-09-24 (spawns_20260924_094300.sql)');

COMMIT;
