-- ----------------------------------------------------------------------------
-- Worldforged pickups: three spawns the realm-map wipe took out and no later
-- pass put back
-- ----------------------------------------------------------------------------
-- `2026_09_23_05_worldforged_map.sql` (PR #4960, merged 2026-09-24T08:51:41Z) blanket-DELETEd
-- every worldforged_pickup spawn in guid ranges 6900001-6939999 and 6940001-6999999 and
-- re-inserted only the realm's own map placements. These three objects were not on that map
-- and no later per-zone authored pass restores them; their gameobject_template and
-- gameobject_loot_template rows were never touched and still stand. Restored here at the
-- last position each held before the wipe, each a well-matched position against its own
-- in-game report:
--
--   Shadow Cowl (entry 1345125, item 217860, Darkshore) - last stood as guid 6910308,
--     inserted at (6007.900, -55.000, 23.180) by
--     2026_09_22_01_worldforged_missing_pickups.sql:726, then ground-corrected to
--     position_z 22.2487 by 2026_09_22_03_worldforged_appearance_and_ground.sql:2641.
--     Refs #4890.
--   Cloudchaser Pendant (entry 1345024, item 521065, Ashenvale) - last stood as guid
--     6910241, inserted at (2010.000, -1899.700, 94.761) by
--     2026_09_22_01_worldforged_missing_pickups.sql:659, then ground-corrected to
--     position_z 98.5045 by 2026_09_22_03_worldforged_appearance_and_ground.sql:2588.
--     Refs #4864.
--   Assassin's Crossbow (entry 95635, Azshara, the "pin Azshara records=6" placement) -
--     last stood as guid 6904296, inserted at (3818.600, -6154.800, -6.553) by
--     2026_09_22_00_worldforged_pickup_spawns.sql:1371, then ground-corrected to
--     position_z -3.6226 by 2026_09_22_03_worldforged_appearance_and_ground.sql:1667.
--     Refs #4849.
--
-- New guids only (6960209-6960211, continuing the range the later authored passes already
-- use for new placements, e.g. 2026_09_26_63_worldforged_tirisfal_final.sql's
-- 6960206-6960208): the old guids fall inside the wiped ranges above and are not reused.
--
-- Idempotent: keyed by guid. Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Shadow Cowl (1345125): restores the guid 6910308 placement, ground-corrected height
DELETE FROM `gameobject` WHERE `guid` = 6960209;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`,
 `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960209, 1345125, 1, 0, 0, 1, 1, 6007.900, -55.000, 22.2487, 1.240875, 0, 0, 0.581391,
 0.813624, 0, 0, 1, 'worldforged_pickup',
 'AscensionWorldforged Shadow Cowl | restored | was guid 6910308, deleted by the #4960 realm-map wipe | Darkshore');

-- Cloudchaser Pendant (1345024): restores the guid 6910241 placement, ground-corrected height
DELETE FROM `gameobject` WHERE `guid` = 6960210;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`,
 `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960210, 1345024, 1, 0, 0, 1, 1, 2010.000, -1899.700, 98.5045, 3.814895, 0, 0, 0.943866,
 -0.330328, 0, 0, 1, 'worldforged_pickup',
 'AscensionWorldforged Cloudchaser Pendant | restored | was guid 6910241, deleted by #4960 wipe | Ashenvale');

-- Assassin's Crossbow (95635): restores the guid 6904296 Azshara placement, ground-corrected height
DELETE FROM `gameobject` WHERE `guid` = 6960211;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`,
 `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960211, 95635, 1, 0, 0, 1, 1, 3818.600, -6154.800, -3.6226, 2.389481, 0, 0, 0.93012,
 0.367255, 0, 0, 1, 'worldforged_pickup',
 'AscensionWorldforged Assassin''s Crossbow | restored | was guid 6904296, #4960 wipe | pin Azshara records=6');

COMMIT;
