-- ==========================================================================================
-- rev_20260930_99_ASC_northshire_revamp - Northshire Valley / Spada world content
--
-- Everything custom that this realm's world database adds on top of the base core, as a
-- single content update: the Northshire Valley custom layer (NPCs, spawns, props, emotes,
-- the Shadewell mine and the Ruins of Northshire / Vaults), the Spada quest family
-- (1660000-1660057), the wayward theologian encounter, the relic purification objects and
-- all spawn edits the live world carries.  The worldserver updater picks this file up and
-- applies it on the next start; it is re-runnable (every block deletes exactly its own rows
-- before inserting them).
--
-- Generated 2026-09-29 from acore_world after the complete reconciliation; the spawn rows
-- carry the final live values - positions, orientations, comments, VerifiedBuild.
--
-- Layout:
--   Section 1  creature spawns     - grouped by creature entry (155 spawns, map 0 / Northshire)
--   Section 2  gameobject spawns   - grouped by gameobject entry (212 spawns, map 0 / Northshire)
--   Section 3  spawn removals      - the existing rows this content deliberately deletes
--   Section 4+ content             - NPC/object templates and models, displays, addons,
--                                    waypoints, quests and their texts, SmartAI, loot,
--                                    spell data and the column-level corrections
--
-- All spawns of this package sit in Northshire Valley (Elwynn Forest, Eastern Kingdoms,
-- map 0).  Spawns are grouped by entry; each entry's DELETE lists the complete set of that
-- entry's spawns, so a block can be reviewed and re-run on its own.  The companion rows of
-- a spawn (creature_addon - emotes, mounts, patrol bindings - and waypoint_data) follow in
-- Section 4 ("northshire world layer") and Section 11.
-- ==========================================================================================

-- ##########################################################################################
-- SECTION 1 - CREATURE SPAWNS (by creature entry)
-- ##########################################################################################

-- All 155 spawns are in Northshire Valley (map 0).  Entry order is numeric.

-- ---------------------------------------------------------------------------------------------
-- entry 38 - Defias Thug (5 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500263, 7500273, 9000033, 9000137, 9000138);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500263, 38, 0, 0, 0, 1, 1, 0, -8895.85, -384.25, 69.39, 0.9977, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Thug'),
  (7500273, 38, 0, 0, 0, 1, 1, 0, -9095.81, -356.66, 73.45, 4.3359, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Thug'),
  (9000033, 38, 0, 0, 0, 1, 1, 1, -8861.97, -397.771, 69.1019, 2.19679, 270, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (9000137, 38, 0, 0, 0, 1, 1, 1, -9138.25, -292.1, 72.7867, 2.42431, 270, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (9000138, 38, 0, 0, 0, 1, 1, 1, -9135.69, -294.604, 73.2082, 2.17176, 270, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 69 - Timber Wolf (2 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500194, 7500221);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500194, 69, 0, 0, 0, 1, 1, 0, -9014.43, -221.2, 70.49, 3.7349, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Timber Wolf'),
  (7500221, 69, 0, 0, 0, 1, 1, 0, -8705.04, -79.86, 93.39, 3.9238, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Timber Wolf');

-- ---------------------------------------------------------------------------------------------
-- entry 80 - Kobold Laborer (10 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500353, 7500355, 7500356, 7500357, 7500358, 7500359, 7500361, 7500362, 7500363, 7500364);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500353, 80, 0, 0, 0, 1, 1, 0, -8554.79, -218.95, 85.23, 5.9212, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500355, 80, 0, 0, 0, 1, 1, 0, -8647.22, -118.84, 88.66, 3.8997, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500356, 80, 0, 0, 0, 1, 1, 0, -8640.09, -145.89, 86.49, 4.9385, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500357, 80, 0, 0, 0, 1, 1, 0, -8635.99, -106.6, 87, 2.6862, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500358, 80, 0, 0, 0, 1, 1, 0, -8614.88, -175.78, 86.12, 2.5854, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500359, 80, 0, 0, 0, 1, 1, 0, -8590.31, -138.12, 89.94, 1.1639, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500361, 80, 0, 0, 0, 1, 1, 0, -8570.67, -145.5, 90.52, 1.8254, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500362, 80, 0, 0, 0, 1, 1, 0, -8528.52, -195.39, 83.96, 6.1333, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500363, 80, 0, 0, 0, 1, 1, 0, -8539.46, -182.46, 84.17, 4.319, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer'),
  (7500364, 80, 0, 0, 0, 1, 1, 0, -8618.71, -152.76, 86.4, 0, 120, 0, 0, 1, 0, 2, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Laborer');

-- ---------------------------------------------------------------------------------------------
-- entry 257 - Kobold Worker (3 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500099, 7500101, 7500104);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500099, 257, 0, 0, 0, 1, 1, 0, -8678.51, -112.49, 90.28, 5.1735, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Worker'),
  (7500101, 257, 0, 0, 0, 1, 1, 0, -8683.02, -133.31, 95.53, 0.0394, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Worker'),
  (7500104, 257, 0, 0, 0, 1, 1, 0, -8671.75, -139.37, 106.09, 1.3408, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Kobold Worker');

-- ---------------------------------------------------------------------------------------------
-- entry 299 - Young Wolf (3 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500153, 7500172, 7500174);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500153, 299, 0, 0, 0, 1, 1, 0, -8983.08, -50.64, 91.21, 1.7204, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Young Wolf'),
  (7500172, 299, 0, 0, 0, 1, 1, 0, -8838.88, -68.03, 85.29, 3.707, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Young Wolf'),
  (7500174, 299, 0, 0, 0, 1, 1, 0, -8865.04, -17.91, 110.99, 4.6664, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Young Wolf');

-- ---------------------------------------------------------------------------------------------
-- entry 537 - Defias Trainee (17 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500277, 7500278, 7500279, 7500280, 7500281, 7500282, 7500283, 7500284, 7500285, 7500286, 7500287, 7500288, 7500289, 7500290, 7500291, 7500292, 9000139);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500277, 537, 0, 0, 0, 1, 1, 0, -9015.52, -292.62, 73.84, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500278, 537, 0, 0, 0, 1, 1, 0, -9034.04, -301.8, 74.64, 5.9112, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500279, 537, 0, 0, 0, 1, 1, 0, -8968.54, -326.05, 70.54, 1.8383, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500280, 537, 0, 0, 0, 1, 1, 0, -8993.93, -311.092, 71.5079, 1.43763, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (7500281, 537, 0, 0, 0, 1, 1, 0, -8934.96, -336.83, 70.47, 0.6819, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500282, 537, 0, 0, 0, 1, 1, 0, -8980.52, -337.27, 73.54, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500283, 537, 0, 0, 0, 1, 1, 0, -8923.88, -364.04, 72.12, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500284, 537, 0, 0, 0, 1, 1, 0, -8889.42, -398.72, 67.04, 1.5171, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500285, 537, 0, 0, 0, 1, 1, 0, -8907.27, -407.934, 67.0105, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500286, 537, 0, 0, 0, 1, 1, 0, -8916.98, -389.46, 69.58, 5.8372, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500287, 537, 0, 0, 0, 1, 1, 0, -9051.68, -305.54, 73.59, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500288, 537, 0, 0, 0, 1, 1, 0, -9070.37, -247.3, 73.31, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500289, 537, 0, 0, 0, 1, 1, 0, -9078.8, -283.19, 73.77, 0.7363, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500290, 537, 0, 0, 0, 1, 1, 0, -9075.33, -332.12, 73.54, 3.6652, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500291, 537, 0, 0, 0, 1, 1, 0, -9120.29, -269.85, 73.52, 3.9432, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (7500292, 537, 0, 0, 0, 1, 1, 0, -9025.71, -354.81, 75.63, 4.8341, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Defias Trainee'),
  (9000139, 537, 0, 0, 0, 1, 1, 0, -9133, -297.182, 73.453, 2.50887, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 50280 - Brother William (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500235);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500235, 50280, 0, 0, 0, 1, 1, 0, -8907.19, -210.78, 89.17, 1.3678, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Brother William');

-- ---------------------------------------------------------------------------------------------
-- entry 50282 - Soridormi (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500344);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500344, 50282, 0, 0, 0, 1, 1, 0, -8852.45, -191.49, 89.32, 2.7458, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Soridormi');

-- ---------------------------------------------------------------------------------------------
-- entry 50283 - Patal the Mad (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500245);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500245, 50283, 0, 0, 0, 1, 1, 0, -8917.39, -164.58, 81.94, 4.432, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Patal the Mad');

-- ---------------------------------------------------------------------------------------------
-- entry 50286 - Chaplain Nysoni (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500294);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500294, 50286, 0, 0, 0, 1, 1, 0, -8853.76, -193.45, 81.93, 3.5096, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Chaplain Nysoni');

-- ---------------------------------------------------------------------------------------------
-- entry 50287 - Norman Goldshire (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500253);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500253, 50287, 0, 0, 0, 1, 1, 0, -8905.17, -105.17, 81.85, 4.2615, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Norman Goldshire');

-- ---------------------------------------------------------------------------------------------
-- entry 50289 - Troes the Remover (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500244);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500244, 50289, 0, 0, 0, 1, 1, 0, -8925.75, -199.67, 80.66, 2.4558, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Troes the Remover');

-- ---------------------------------------------------------------------------------------------
-- entry 50291 - Wanda Belezin (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500234);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500234, 50291, 0, 0, 0, 1, 1, 0, -8909.81, -216.7, 81.94, 1.9722, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Wanda Belezin');

-- ---------------------------------------------------------------------------------------------
-- entry 50292 - Whisp the Silent (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500231);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500231, 50292, 0, 0, 0, 1, 1, 0, -8938.88, -175.9, 80.49, 4.556, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Whisp the Silent');

-- ---------------------------------------------------------------------------------------------
-- entry 50295 - Amanda the Reaver (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500252);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500252, 50295, 0, 0, 0, 1, 1, 0, -8913.97, -99.21, 81.92, 5.9057, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Amanda the Reaver');

-- ---------------------------------------------------------------------------------------------
-- entry 50324 - Vanguard Gus (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500233);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500233, 50324, 0, 0, 0, 1, 1, 0, -8906.3, -207.67, 81.94, 3.4079, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Vanguard Gus');

-- ---------------------------------------------------------------------------------------------
-- entry 50325 - Deacon Frost (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500230);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500230, 50325, 0, 0, 0, 1, 1, 0, -8949.41, -173.84, 80.17, 1.1967, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Deacon Frost');

-- ---------------------------------------------------------------------------------------------
-- entry 50340 - Koby the Incinerator (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500229);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500229, 50340, 0, 0, 0, 1, 1, 0, -8950.24, -210.71, 79.02, 3.6371, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Koby the Incinerator');

-- ---------------------------------------------------------------------------------------------
-- entry 75118 - Beginner's Book of Ascension (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9000134);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (9000134, 75118, 0, 0, 0, 1, 1, 0, -8909.88, -133.162, 80.5296, 2.67656, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 80894 - Water Source (6 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500003, 7500004, 7500005, 7500006, 7500007, 9000136);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500003, 80894, 0, 0, 0, 1, 1, 0, -8932.2, -165.35, 80.95, 4.3834, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Water Source'),
  (7500004, 80894, 0, 0, 0, 1, 1, 0, -8896.02, -119.62, 82.03, 3.0044, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Water Source'),
  (7500005, 80894, 0, 0, 0, 1, 1, 0, -8907.14, -106.76, 82, 3.0388, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Water Source'),
  (7500006, 80894, 0, 0, 0, 1, 1, 0, -8707.92, -442.69, 143.43, 5.5217, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Water Source'),
  (7500007, 80894, 0, 0, 0, 1, 1, 0, -9035.41, -305.67, 74.18, 2.4555, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Water Source'),
  (9000136, 80894, 0, 0, 0, 1, 1, 0, -8929.25, -156.934, 81.46, 4.3834, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161700 - Bianca Spada (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500251);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500251, 161700, 0, 0, 0, 1, 1, 0, -8920.48, -133.22, 80.71, 5.4819, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Bianca Spada');

-- ---------------------------------------------------------------------------------------------
-- entry 161701 - Moroi Spada (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500240);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500240, 161701, 0, 0, 0, 1, 1, 0, -8900.59, -197.32, 81.94, 3.5323, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Moroi Spada');

-- ---------------------------------------------------------------------------------------------
-- entry 161702 - Sister Alma (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500316);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500316, 161702, 0, 0, 0, 1, 1, 0, -8748.88, -282.91, 67.23, 0.6311, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Sister Alma');

-- ---------------------------------------------------------------------------------------------
-- entry 161703 - [KC] 161703 (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500365);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500365, 161703, 0, 0, 0, 1, 1, 0, -8708.26, -504.44, 153.34, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Hidden Path marker');

-- ---------------------------------------------------------------------------------------------
-- entry 161704 - [KC] 161704 (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500366);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500366, 161704, 0, 0, 0, 1, 1, 0, -8604.62, -570.05, 145.22, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Ruined Estate marker');

-- ---------------------------------------------------------------------------------------------
-- entry 161705 - Injured Northshire Guard (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500315);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500315, 161705, 0, 0, 0, 1, 1, 0, -8852.27, -368.92, 70.33, 3.433, 120, 0, 0, 38, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161707 - Shadewell Spider (10 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500295, 7500296, 7500297, 7500298, 7500299, 7500300, 7500301, 7500302, 7500303, 7500305);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500295, 161707, 0, 0, 0, 1, 1, 0, -8810.57, -275.82, 77.24, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Spider'),
  (7500296, 161707, 0, 0, 0, 1, 1, 0, -8805.52, -299.42, 75.84, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500297, 161707, 0, 0, 0, 1, 1, 0, -8792.21, -310.41, 71.39, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Spider'),
  (7500298, 161707, 0, 0, 0, 1, 1, 0, -8791.44, -294.72, 75.33, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500299, 161707, 0, 0, 0, 1, 1, 0, -8787.74, -284.689, 75.8946, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500300, 161707, 0, 0, 0, 1, 1, 0, -8752.28, -272.93, 80.57, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Spider'),
  (7500301, 161707, 0, 0, 0, 1, 1, 0, -8752.88, -306.348, 78.1719, 3.904, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500302, 161707, 0, 0, 0, 1, 1, 0, -8751.41, -300.02, 66.52, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Spider'),
  (7500303, 161707, 0, 0, 0, 1, 1, 0, -8775.32, -264.6, 79.1598, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500305, 161707, 0, 0, 0, 1, 1, 0, -8816.74, -302.48, 75.8, 6.1478, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Spider');

-- ---------------------------------------------------------------------------------------------
-- entry 161708 - Accursed Judge (15 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500328, 7500329, 7500330, 7500331, 7500332, 7500333, 7500334, 7500335, 7500337, 7500339, 7500340, 7500341, 7500342, 7500343, 9000140);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500328, 161708, 0, 0, 0, 1, 1, 0, -8701.46, -284.77, 57.99, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500329, 161708, 0, 0, 0, 1, 1, 0, -8674.06, -277.17, 53.72, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500330, 161708, 0, 0, 0, 1, 1, 0, -8646.79, -265.27, 53.77, 1.4338, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500331, 161708, 0, 0, 0, 1, 1, 0, -8653.38, -301.01, 53.75, 5.1535, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500332, 161708, 0, 0, 0, 1, 1, 0, -8624.47, -265.14, 53.76, 2.1862, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500333, 161708, 0, 0, 0, 1, 1, 0, -8640.96, -246.28, 53.73, 4.4682, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500334, 161708, 0, 0, 0, 1, 1, 0, -8620.95, -340.11, 53.72, 4.7536, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500335, 161708, 0, 0, 0, 1, 1, 0, -8626.19, -356.68, 53.72, 4.4461, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500337, 161708, 0, 0, 0, 1, 1, 0, -8634.42, -226.59, 53.75, 5.2947, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500339, 161708, 0, 0, 0, 1, 1, 0, -8637.27, -376.62, 53.72, 4.4057, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500340, 161708, 0, 0, 0, 1, 1, 0, -8634.42, -291.01, 53.77, 3.5749, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500341, 161708, 0, 0, 0, 1, 1, 0, -8617.54, -400.64, 53.73, 0.7489, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500342, 161708, 0, 0, 0, 1, 1, 0, -8630.67, -431.65, 53.72, 4.7372, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (7500343, 161708, 0, 0, 0, 1, 1, 0, -8628.34, -167.15, 46.43, 0, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge'),
  (9000140, 161708, 0, 0, 0, 1, 1, 0, -8591.77, -278.557, 53.7193, 6.16063, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161710 - Carthorse (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500250);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500250, 161710, 0, 0, 0, 1, 1, 0, -8933.1, -127.28, 82.52, 5.632, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Carthorse');

-- ---------------------------------------------------------------------------------------------
-- entry 161712 - Accursed Censor (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500352);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500352, 161712, 0, 0, 0, 1, 1, 0, -8577.25, -258.37, 53.72, 1.1716, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Censor');

-- ---------------------------------------------------------------------------------------------
-- entry 161713 - Wayward Theologian (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9000133);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (9000133, 161713, 0, 0, 0, 1, 1, 0, -8604.52, -569.947, 145.225, 1.85574, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entries 161880 / 161881 / 161882 / 161883 - [KC] Purify Relics markers (1 spawn each)
-- One unique marker per relic: Journal 7500347, Staff 7500348, Idol 7500346, Jewel 7500345.
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500345, 7500346, 7500347, 7500348);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500345, 161883, 0, 0, 0, 1, 1, 0, -8658.67, -318.02, 53.73, 2.9164, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - [KC] Purify Jewel marker'),
  (7500346, 161882, 0, 0, 0, 1, 1, 0, -8619.05, -278.12, 57.69, 2.2519, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - [KC] Purify Idol marker'),
  (7500347, 161880, 0, 0, 0, 1, 1, 0, -8575.71, -253.146, 53.7228, 2.8954, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA - [KC] Purify Journal marker'),
  (7500348, 161881, 0, 0, 0, 1, 1, 0, -8638.85, -404.45, 54.72, 3.1877, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - [KC] Purify Staff marker');

-- ---------------------------------------------------------------------------------------------
-- entry 161716 - Shadewell Murloc (16 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500125, 7500126, 7500127, 7500128, 7500129, 7500130, 7500131, 7500132, 7500133, 7500134, 7500135, 7500136, 7500137, 9000035, 9000036, 9000141);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500125, 161716, 0, 0, 0, 1, 1, 0, -8703.1, -449.88, 141.61, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500126, 161716, 0, 0, 0, 1, 1, 0, -8683.18, -453.45, 142.32, 2.1856, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500127, 161716, 0, 0, 0, 1, 1, 0, -8670.62, -469.15, 141.52, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500128, 161716, 0, 0, 0, 1, 1, 0, -8616.04, -482.08, 141.9, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500129, 161716, 0, 0, 0, 1, 1, 0, -8659.17, -496.69, 144.01, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500130, 161716, 0, 0, 0, 1, 1, 0, -8629.69, -506.09, 144.33, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500131, 161716, 0, 0, 0, 1, 1, 0, -8603.04, -501.43, 144.98, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500132, 161716, 0, 0, 0, 1, 1, 0, -8634.74, -487.98, 140.49, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500133, 161716, 0, 0, 0, 1, 1, 0, -8545.74, -471.42, 140.35, 4.4862, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500134, 161716, 0, 0, 0, 1, 1, 0, -8571.84, -496.46, 143.99, 3.3414, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500135, 161716, 0, 0, 0, 1, 1, 0, -8559.25, -522.37, 144.89, 5.5784, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500136, 161716, 0, 0, 0, 1, 1, 0, -8533.14, -491.99, 140.42, 5.5541, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (7500137, 161716, 0, 0, 0, 1, 1, 0, -8537.52, -512.11, 144.38, 1.24, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc'),
  (9000035, 161716, 0, 0, 0, 1, 1, 0, -8575.81, -517.186, 145.114, 5.5784, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (9000036, 161716, 0, 0, 0, 1, 1, 0, -8593.81, -513.738, 146.918, 5.5784, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (9000141, 161716, 0, 0, 0, 1, 1, 0, -8517.71, -469.023, 145.554, 4.4862, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161717 - Shadewell Murloc Oracle (13 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500317, 7500318, 7500319, 7500320, 7500321, 7500322, 7500323, 7500324, 7500325, 7500326, 7500327, 9000034, 9000142);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500317, 161717, 0, 0, 0, 1, 1, 0, -8722.85, -427.15, 138.18, 2.322, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500318, 161717, 0, 0, 0, 1, 1, 0, -8704, -435.61, 146.27, 4.9495, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500319, 161717, 0, 0, 0, 1, 1, 0, -8690.09, -466.21, 144.91, 1.6934, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500320, 161717, 0, 0, 0, 1, 1, 0, -8667.1, -486.49, 145.62, 1.1672, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500321, 161717, 0, 0, 0, 1, 1, 0, -8647.48, -499.52, 143.99, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500322, 161717, 0, 0, 0, 1, 1, 0, -8616.23, -496.35, 149.62, 1.6698, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (7500323, 161717, 0, 0, 0, 1, 1, 0, -8570.1, -495.3, 140.47, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500324, 161717, 0, 0, 0, 1, 1, 0, -8572.29, -478.73, 148.27, 4.3055, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500325, 161717, 0, 0, 0, 1, 1, 0, -8579.57, -506.86, 143.99, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500326, 161717, 0, 0, 0, 1, 1, 0, -8549.38, -516.86, 144.67, 1.7608, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (7500327, 161717, 0, 0, 0, 1, 1, 0, -8530.76, -511.94, 149.05, 2.4088, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Shadewell Murloc Oracle'),
  (9000034, 161717, 0, 0, 0, 1, 1, 0, -8549.07, -488.762, 140.432, 2.4088, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (9000142, 161717, 0, 0, 0, 1, 1, 0, -8519.73, -475.596, 145.605, 3.34307, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161736 - Defias Plunderer (9 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500310, 7500311, 7500312, 7500313, 7500314, 9000029, 9000030, 9000032, 9000143);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500310, 161736, 0, 0, 0, 1, 1, 0, -8807.3, -395.521, 110.378, 5.6383, 120, 0, 0, 1, 0, 2, 0, 0, 0, '', NULL, 0, NULL),
  (7500311, 161736, 0, 0, 0, 1, 1, 0, -8798.67, -379, 75.28, 2.1352, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500312, 161736, 0, 0, 0, 1, 1, 0, -8804.36, -406.32, 75.21, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (7500313, 161736, 0, 0, 0, 1, 1, 0, -8813.96, -394.84, 110.38, 4.8035, 120, 0, 0, 1, 0, 2, 0, 0, 0, '', NULL, 0, NULL),
  (7500314, 161736, 0, 0, 0, 1, 1, 0, -8810.04, -390.16, 75.29, 5.5535, 120, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL),
  (9000029, 161736, 0, 0, 0, 1, 1, 0, -8843.77, -397.266, 75.5569, 2.34232, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (9000030, 161736, 0, 0, 0, 1, 1, 0, -8814.13, -370.42, 76.1631, 3.40261, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (9000032, 161736, 0, 0, 0, 1, 1, 0, -8823.89, -367.572, 75.2505, 5.2866, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
  (9000143, 161736, 0, 0, 0, 1, 1, 0, -8813.14, -398.572, 110.378, 1.93436, 120, 4, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161841 - Shadewell Murloc Forager (3 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500306, 7500307, 7500308);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500306, 161841, 0, 0, 0, 1, 1, 0, -8849.08, -369.83, 70.02, 0.649884, 120, 0, 0, 0, 0, 0, 0, 33555200, 288, '', NULL, 0, NULL),
  (7500307, 161841, 0, 0, 0, 1, 1, 0, -8850.37, -364.88, 69.69, 3.8532, 120, 0, 0, 0, 0, 0, 0, 33555200, 288, '', NULL, 0, NULL),
  (7500308, 161841, 0, 0, 0, 1, 1, 0, -8846.32, -367.3, 69.67, 3.2013, 120, 0, 0, 0, 0, 0, 0, 33555200, 288, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161842 - Defias Plunderer (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500309);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500309, 161842, 0, 0, 0, 1, 1, 0, -8855.01, -371.64, 70.88, 1.1042, 120, 0, 0, 0, 0, 0, 0, 33555200, 288, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161844 - Father Harnos (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500239);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500239, 161844, 0, 0, 0, 1, 1, 0, -8904.51, -171.01, 81.58, 5.9042, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Father Harnos');

-- ---------------------------------------------------------------------------------------------
-- entry 161857 - Echo of the High Inquisitor (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500350);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500350, 161857, 0, 0, 0, 1, 1, 0, -8614.31, -280.37, 56.66, 0.5057, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Echo of the High Inquisitor');

-- ---------------------------------------------------------------------------------------------
-- entry 161858 - Echo of the Abbess (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500349);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500349, 161858, 0, 0, 0, 1, 1, 0, -8612.63, -278.83, 56.61, 6.2499, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 161895 - Accursed Judge (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500336);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500336, 161895, 0, 0, 0, 1, 1, 0, -8600.78, -272.44, 59.76, 3.4548, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge');

-- ---------------------------------------------------------------------------------------------
-- entry 161897 - Accursed Judge (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500338);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500338, 161897, 0, 0, 0, 1, 1, 0, -8599.77, -293.07, 59.65, 2.4024, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Accursed Judge');

-- ---------------------------------------------------------------------------------------------
-- entry 200200 - Darien's Horse (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500001);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500001, 200200, 0, 0, 0, 1, 1, 0, -8941.83, -124.13, 83.17, 5.27, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Darien''s Horse');

-- ---------------------------------------------------------------------------------------------
-- entry 399223 - Zipi (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500372);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500372, 399223, 0, 0, 0, 1, 1, 0, -8627.64, -110.71, 89.13, 3.1736, 120, 0, 0, 0, 0, 0, 0, 393218, 32, '', NULL, 0, NULL);

-- ---------------------------------------------------------------------------------------------
-- entry 501266 - Valerius Thorne (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500237);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500237, 501266, 0, 0, 0, 1, 1, 0, -8925.31, -198.25, 80.67, 2.781, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Valerius Thorne');

-- ---------------------------------------------------------------------------------------------
-- entry 502770 - Niki Thesla (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500243);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500243, 502770, 0, 0, 0, 1, 1, 0, -8878.25, -183.11, 81.94, 6.0284, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Niki Thesla');

-- ---------------------------------------------------------------------------------------------
-- entry 502923 - Halbert the Scoundrel (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500242);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500242, 502923, 0, 0, 0, 1, 1, 0, -8920.47, -178.42, 80.89, 4.2175, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Halbert the Scoundrel');

-- ---------------------------------------------------------------------------------------------
-- entry 502960 - Doctor Yara (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500259);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500259, 502960, 0, 0, 0, 1, 1, 0, -8875.32, -207.59, 81.34, 5.8588, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Doctor Yara');

-- ---------------------------------------------------------------------------------------------
-- entry 503410 - Owen of Moonbrook (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500238);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500238, 503410, 0, 0, 0, 1, 1, 0, -8872.82, -160.38, 80.07, 0.6628, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Owen of Moonbrook');

-- ---------------------------------------------------------------------------------------------
-- entry 522923 - Skeletal Warrior (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500241);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500241, 522923, 0, 0, 0, 1, 1, 0, -8919.34, -178.32, 80.78, 4.1312, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 12340, 0, 'CoA - Skeletal Warrior');

-- ---------------------------------------------------------------------------------------------
-- entry 721111 - Cookie (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500228);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500228, 721111, 0, 0, 0, 1, 1, 0, -8951.9, -212.4, 78.71, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Cookie');

-- ---------------------------------------------------------------------------------------------
-- entry 922442 - Chicken (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500371);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500371, 922442, 0, 0, 0, 1, 1, 0, -8690.21, -171.23, 91.08, 0, 120, 5, 0, 1, 0, 1, 0, 0, 0, '', 12340, 0, 'CoA - Chicken');

-- ---------------------------------------------------------------------------------------------
-- entry 10157356 - Challenger Darien (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (7500002);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
  (7500002, 10157356, 0, 0, 0, 1, 1, 0, -8944.52, -125.35, 83.36, 4.3668, 120, 0, 0, 1, 0, 0, 1, 0, 0, '', NULL, 0, NULL);

-- ##########################################################################################
-- SECTION 2 - GAMEOBJECT SPAWNS (by gameobject entry)
-- ##########################################################################################

-- All 212 spawns are in Northshire Valley (map 0): the valley props, the Spada scene,
-- the Lost Page chests and the relic objects.  Entry order is numeric.

-- ---------------------------------------------------------------------------------------------
-- gameobject 1617 - Silverleaf (6 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500075, 7500076, 7500077, 7500078, 7500079, 7500080);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500075, 1617, 0, 0, 0, 1, 1, -8849.27, -274.734, 80.274, 1.674, 0, 0, 0.742637, 0.669694, 120, 100, 1, '', 12340, 'CoA - Silverleaf'),
  (7500076, 1617, 0, 0, 0, 1, 1, -8753.94, -377.705, 70.798, 5.403, 0, 0, 0.426015, -0.904716, 120, 100, 1, '', 12340, 'CoA - Silverleaf'),
  (7500077, 1617, 0, 0, 0, 1, 1, -9065.76, -269.333, 73.757, 1.7879, 0, 0, 0.779549, 0.626342, 120, 100, 1, '', 12340, 'CoA - Silverleaf'),
  (7500078, 1617, 0, 0, 0, 1, 1, -9130.28, -294.519, 73.321, 4.1166, 0, 0, 0.883507, -0.468417, 120, 100, 1, '', 12340, 'CoA - Silverleaf'),
  (7500079, 1617, 0, 0, 0, 1, 1, -8830.97, -111.419, 81.724, 1.9999, 0, 0, 0.841455, 0.540328, 120, 100, 1, '', 12340, 'CoA - Silverleaf'),
  (7500080, 1617, 0, 0, 0, 1, 1, -8729.65, -144.836, 86.225, 4.2627, 0, 0, 0.846961, -0.531655, 120, 100, 1, '', 12340, 'CoA - Silverleaf');

-- ---------------------------------------------------------------------------------------------
-- gameobject 1618 - Peacebloom (7 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500091, 7500092, 7500093, 7500094, 7500095, 7500096, 7500097);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500091, 1618, 0, 0, 0, 1, 1, -8973.77, -64.276, 90.949, 1.4659, 0, 0, 0.669054, 0.743214, 120, 100, 1, '', 12340, 'CoA - Peacebloom'),
  (7500092, 1618, 0, 0, 0, 1, 1, -9047.42, -230.386, 70.818, 5.7149, 0, 0, 0.280344, -0.9599, 120, 100, 1, '', 12340, 'CoA - Peacebloom'),
  (7500093, 1618, 0, 0, 0, 1, 1, -8900.7, -243.511, 80.565, 3.9909, 0, 0, 0.911177, -0.412014, 120, 100, 1, '', 12340, 'CoA - Peacebloom'),
  (7500094, 1618, 0, 0, 0, 1, 1, -8838.64, -254.064, 82.867, 5.0355, 0, 0, 0.584154, -0.811643, 120, 100, 1, '', 12340, 'CoA - Peacebloom'),
  (7500095, 1618, 0, 0, 0, 1, 1, -8825.24, -208.908, 83.927, 5.9897, 0, 0, 0.146192, -0.989256, 120, 100, 1, '', 12340, 'CoA - Peacebloom'),
  (7500096, 1618, 0, 0, 0, 1, 1, -9063.23, -256.403, 74.07, 3.3233, 0, 0, 0.995874, -0.090749, 120, 100, 1, '', 12340, 'CoA - Peacebloom'),
  (7500097, 1618, 0, 0, 0, 1, 1, -8712.45, -118.68, 87.554, 2.4955, 0, 0, 0.948281, 0.317433, 120, 100, 1, '', 12340, 'CoA - Peacebloom');

-- ---------------------------------------------------------------------------------------------
-- gameobject 1731 - Copper Vein (3 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500087, 7500088, 7500089);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500087, 1731, 0, 0, 0, 1, 1, -8708.12, -311.652, 86.534, 5.7848, 0, 0, 0.246641, -0.969107, 120, 100, 1, '', 12340, 'CoA - Copper Vein'),
  (7500088, 1731, 0, 0, 0, 1, 1, -8745.77, 26.308, 101.982, 0.8211, 0, 0, 0.399093, 0.916911, 120, 100, 1, '', 12340, 'CoA - Copper Vein'),
  (7500089, 1731, 0, 0, 0, 1, 1, -8691.19, -127.441, 89.805, 5.9419, 0, 0, 0.169835, -0.985472, 120, 100, 1, '', 12340, 'CoA - Copper Vein');

-- ---------------------------------------------------------------------------------------------
-- gameobject 1940 - Campfire (2 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500171, 7500172);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500171, 1940, 0, 0, 0, 1, 1, -8624.82, -513.191, 145.449, 2.378, 0, 0, 0.927993, 0.372597, 120, 100, 1, '', 12340, 'CoA - Campfire'),
  (7500172, 1940, 0, 0, 0, 1, 1, -8625.7, -516.412, 136.427, 1.5708, 0, 0, 0.707105, 0.707109, 120, 100, 1, '', 12340, 'CoA - Campfire');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2061 - Campfire (4 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500081, 7500082, 7500083, 7500084);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500081, 2061, 0, 0, 0, 1, 1, -8752.72, -190.934, 85.41, 3.002, 0, 0, 0.997564, 0.069755, 120, 100, 1, '', 12340, 'CoA - Campfire'),
  (7500082, 2061, 0, 0, 0, 1, 1, -8789.56, -248.096, 82.704, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Campfire'),
  (7500083, 2061, 0, 0, 0, 1, 1, -8768.92, -115.092, 83.367, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Campfire'),
  (7500084, 2061, 0, 0, 0, 1, 1, -8672.23, -189.828, 91.734, 5.6383, 0, 0, 0.316903, -0.948458, 120, 100, 1, '', 12340, 'CoA - Campfire');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2843 - Battered Chest (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500174);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500174, 2843, 0, 0, 0, 1, 1, -9038.98, -303.642, 74.362, 2.2864, 0, 0, 0.909961, 0.414694, 120, 100, 1, '', 12340, 'CoA - Battered Chest');

-- ---------------------------------------------------------------------------------------------
-- gameobject 21007 - Campfire (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500153);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500153, 21007, 0, 0, 0, 1, 1, -8752.72, -190.934, 85.41, 3.002, 0, 0, 0.997564, 0.069755, 120, 100, 1, '', 12340, 'CoA - Campfire');

-- ---------------------------------------------------------------------------------------------
-- gameobject 21008 - Campfire (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500209);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500209, 21008, 0, 0, 0, 1, 1, -8768.92, -115.092, 83.367, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Campfire');

-- ---------------------------------------------------------------------------------------------
-- gameobject 21009 - Campfire (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500150);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500150, 21009, 0, 0, 0, 1, 1, -8789.56, -248.096, 82.704, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Campfire');

-- ---------------------------------------------------------------------------------------------
-- gameobject 22773 - Cozy Fire (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500100);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500100, 22773, 0, 0, 0, 1, 1, -8672.01, -189.836, 91.734, 5.6383, 0, 0, 0.316903, -0.948458, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 90214 - Wax Stained Bag (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500132);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500132, 90214, 0, 0, 0, 1, 1, -8769.06, -174.064, 83.937, 5.0609, 0, 0, 0.573785, -0.819006, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Wax Stained Bag');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90215 - Old Grave  (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500139);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500139, 90215, 0, 0, 0, 1, 1, -8687.94, -299.219, 84.926, 4.3211, 0, 0, 0.83109, -0.556138, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Old Grave ');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90216 - Defias Special Bucket (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500126);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500126, 90216, 0, 0, 0, 1, 1, -9142.46, -288.985, 72.198, 5.9265, 0, 0, 0.177419, -0.984135, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Defias Special Bucket');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90217 - Alliance Gem of Fortitude (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500133);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500133, 90217, 0, 0, 0, 1, 1, -8678.32, -189.398, 92.7, 1.0491, 0, 0, 0.500841, 0.865539, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Alliance Gem of Fortitude');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90633 - Table Prop (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500122);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500122, 90633, 0, 0, 0, 1, 1, -8900.77, -110.352, 81.849, 5.6581, 0, 0, 0.30747, -0.951558, 120, 100, 1, '', 12340, 'CoA - Table Prop');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90634 - Brother's Cherry Pie (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500121);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500121, 90634, 0, 0, 0, 1, 1, -8900.61, -110.8, 82.485, 4.1568, 0, 0, 0.873912, -0.486084, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Brother''s Cherry Pie');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90635 - Cherry Pie prop (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500086);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500086, 90635, 0, 0, 0, 1, 1, -8900.61, -110.8, 82.485, 4.1568, 0, 0, 0.873912, -0.486084, 120, 100, 1, '', 12340, 'CoA - Cherry Pie prop');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90636 - Forgotten Sack (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500090);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500090, 90636, 0, 0, 0, 1, 1, -9039.82, -44.4863, 89.742, 2.8036, 0, 0, 0.985753, 0.168198, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Forgotten Sack');

-- ---------------------------------------------------------------------------------------------
-- gameobject 90637 - Eagan's Water Pouch (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500107);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500107, 90637, 0, 0, 0, 1, 1, -8867.34, -165.09, 81.31, 6.1806, 0, 0, 0.051247, -0.998686, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Eagan''s Water Pouch');

-- ---------------------------------------------------------------------------------------------
-- gameobject 95602 - Worn Shovel (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500140);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500140, 95602, 0, 0, 0, 1, 1, -8627.79, -108.211, 89.908, 1.09413, -0.218834, 0.679026, 0.364514, 0.598469, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Worn Shovel');

-- ---------------------------------------------------------------------------------------------
-- gameobject 95670 - Apprentice Staff (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500127);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500127, 95670, 0, 0, 0, 1, 1, -9125.24, -224.092, 74.286, 5.53945, -0.717045, -0.0291774, -0.253048, 0.648816, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Apprentice Staff');

-- ---------------------------------------------------------------------------------------------
-- gameobject 95953 - Skeleton RPG Prop (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500208);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500208, 95953, 0, 0, 0, 1, 1, -9125.92, -224.254, 73.937, 3.6289, 0, 0, 0.97046, -0.241262, 120, 100, 1, '', 12340, 'CoA - Skeleton RPG Prop');

-- ---------------------------------------------------------------------------------------------
-- gameobject 96383 - Armor Stand (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500173);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500173, 96383, 0, 0, 0, 1, 1, -8677.44, -178.08, 91.718, 1.31188, 0, 0, 0.609903, 0.792476, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 98007 - Elwynn Fence RPG Prop (2 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500211, 7500212);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500211, 98007, 0, 0, 0, 1, 1, -8703.62, -155.99, 87.89, 2.57734, -0.0789274, -0.0372665, 0.9568, 0.277337, 120, 100, 1, '', NULL, NULL),
  (7500212, 98007, 0, 0, 0, 1, 1, -8696.47, -160.242, 89.381, 5.76141, -0.0617178, 0.137727, 0.254983, -0.955095, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 142075 - Mailbox (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500085);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500085, 142075, 0, 0, 0, 1, 1, -8905.93, -129.345, 81.059, 1.9858, 0, 0, 0.837619, 0.546255, 120, 100, 1, '', 12340, 'CoA - Mailbox');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151953 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500108);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500108, 151953, 0, 0, 0, 1, 1, -8883.07, -155.2, 81.926, 2.8012, 0, 0, 0.985556, 0.169351, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151954 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500104);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500104, 151954, 0, 0, 0, 1, 1, -8920.58, -208.072, 89.1578, 5.969, 0, 0, 0.156435, -0.987688, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151956 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500125);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500125, 151956, 0, 0, 0, 1, 1, -8861.49, -180.356, 81.943, 5.8992, 0, 0, 0.190809, -0.981627, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151959 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500155);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500155, 151959, 0, 0, 0, 1, 1, -8853.78, -180.455, 81.943, 4.3371, 0, 0, 0.826589, -0.562806, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151960 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500110);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500110, 151960, 0, 0, 0, 1, 1, -8882.17, -188.219, 81.9528, 1.1955, 0, 0, 0.562805, 0.82659, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151961 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500113);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500113, 151961, 0, 0, 0, 1, 1, -8873.38, -172.736, 81.943, 4.3371, 0, 0, 0.826589, -0.562806, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151962 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500124);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500124, 151962, 0, 0, 0, 1, 1, -8866.22, -175.556, 81.943, 4.3371, 0, 0, 0.826589, -0.562806, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151963 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500114);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500114, 151963, 0, 0, 0, 1, 1, -8874.48, -171.567, 89.291, 4.3371, 0, 0, 0.826589, -0.562806, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151964 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500118);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500118, 151964, 0, 0, 0, 1, 1, -8876.24, -191.115, 89.291, 1.1868, 0, 0, 0.559191, 0.829039, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151965 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500109);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500109, 151965, 0, 0, 0, 1, 1, -8910.39, -167.963, 113.15, 5.9079, 0, 0, 0.186524, -0.98245, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151966 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500111);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500111, 151966, 0, 0, 0, 1, 1, -8911.89, -182.81, 81.926, 1.1781, 0, 0, 0.555571, 0.831469, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151968 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500117);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500117, 151968, 0, 0, 0, 1, 1, -8889.9, -162.104, 113.122, 4.3284, 0, 0, 0.829038, -0.559192, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151969 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500116);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500116, 151969, 0, 0, 0, 1, 1, -8905.3, -182.084, 113.122, 5.9167, 0, 0, 0.182236, -0.983255, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151970 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500115);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500115, 151970, 0, 0, 0, 1, 1, -8912.84, -189.944, 89.152, 5.9079, 0, 0, 0.186524, -0.98245, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151971 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500112);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500112, 151971, 0, 0, 0, 1, 1, -8899.14, -195.708, 89.152, 2.7838, 0, 0, 0.984041, 0.177944, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 151972 - Wooden Bench (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500105);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500105, 151972, 0, 0, 0, 1, 1, -8905.1, -210.85, 89.1403, 2.7838, 0, 0, 0.984041, 0.177944, 120, 100, 1, '', 12340, 'CoA - Wooden Bench');

-- ---------------------------------------------------------------------------------------------
-- gameobject 161557 - Milly's Harvest (33 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500175, 7500176, 7500177, 7500178, 7500179, 7500180, 7500181, 7500182, 7500183, 7500184, 7500185, 7500186, 7500187, 7500188, 7500189, 7500190, 7500191, 7500192, 7500193, 7500194, 7500195, 7500196, 7500197, 7500198, 7500199, 7500200, 7500201, 7500202, 7500203, 7500204, 7500205, 7500206, 7500207);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500175, 161557, 0, 0, 0, 1, 1, -9073.2, -298.484, 73.454, 2.7053, 0, 0, 0.976296, 0.21644, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500176, 161557, 0, 0, 0, 1, 1, -9042.6, -316.675, 73.516, 1.0821, 0, 0, 0.515036, 0.857168, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500177, 161557, 0, 0, 0, 1, 1, -9038.2, -325.137, 73.467, 1.2217, 0, 0, 0.573576, 0.819152, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500178, 161557, 0, 0, 0, 1, 1, -9064.08, -312.041, 73.452, 5.6549, 0, 0, 0.309017, -0.951056, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500179, 161557, 0, 0, 0, 1, 1, -9052.65, -319.387, 73.454, 4.8869, 0, 0, 0.642786, -0.766046, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500180, 161557, 0, 0, 0, 1, 1, -9060.96, -297.315, 73.46, 5.2185, 0, 0, 0.507538, -0.861629, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500181, 161557, 0, 0, 0, 1, 1, -9050.2, -303.807, 73.674, 4.7124, 0, 0, 0.707106, -0.707107, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500182, 161557, 0, 0, 0, 1, 1, -9086.57, -310.064, 73.386, 0.7156, 0, 0, 0.350207, 0.936672, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500183, 161557, 0, 0, 0, 1, 1, -9074, -314.569, 73.452, 5.9167, 0, 0, 0.182235, -0.983255, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500184, 161557, 0, 0, 0, 1, 1, -9041.35, -334.082, 73.456, 6.0039, 0, 0, 0.139173, -0.990268, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500185, 161557, 0, 0, 0, 1, 1, -9051.67, -340.492, 73.452, 1.2392, 0, 0, 0.580701, 0.814117, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500186, 161557, 0, 0, 0, 1, 1, -9039.74, -343.685, 73.514, 0.6632, 0, 0, 0.325568, 0.945519, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500187, 161557, 0, 0, 0, 1, 1, -9026.81, -331.989, 73.701, 1.0123, 0, 0, 0.484809, 0.87462, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500188, 161557, 0, 0, 0, 1, 1, -9061.2, -330.884, 73.452, 1.85, 0, 0, 0.798636, 0.601815, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500189, 161557, 0, 0, 0, 1, 1, -9085.58, -340.105, 73.452, 0.5411, 0, 0, 0.267238, 0.96363, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500190, 161557, 0, 0, 0, 1, 1, -9068.66, -336.238, 73.452, 0.3316, 0, 0, 0.165048, 0.986286, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500191, 161557, 0, 0, 0, 1, 1, -9068.64, -344.935, 73.452, 0.0175, 0, 0, 0.008726, 0.999962, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500192, 161557, 0, 0, 0, 1, 1, -9095.65, -334.19, 73.452, 5.3931, 0, 0, 0.430511, -0.902585, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500193, 161557, 0, 0, 0, 1, 1, -9095.93, -318.186, 73.374, 1.3264, 0, 0, 0.615661, 0.788011, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500194, 161557, 0, 0, 0, 1, 1, -9102.25, -325.9, 73.415, 0.1375, 0, 0, 0.068693, 0.997638, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500195, 161557, 0, 0, 0, 1, 1, -9084.25, -323.969, 73.452, 4.119, 0, 0, 0.882948, -0.469471, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500196, 161557, 0, 0, 0, 1, 1, -9045.19, -351.078, 73.527, 4.8695, 0, 0, 0.649449, -0.760405, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500197, 161557, 0, 0, 0, 1, 1, -9062.97, -358.679, 73.452, 6.0214, 0, 0, 0.130526, -0.991445, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500198, 161557, 0, 0, 0, 1, 1, -9054.42, -358.9, 73.467, 5.5152, 0, 0, 0.374606, -0.927184, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500199, 161557, 0, 0, 0, 1, 1, -9056.31, -348.569, 73.452, 4.9742, 0, 0, 0.608763, -0.793352, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500200, 161557, 0, 0, 0, 1, 1, -9092.74, -345.37, 73.452, 0.6632, 0, 0, 0.325568, 0.945519, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500201, 161557, 0, 0, 0, 1, 1, -9081.92, -352.131, 73.452, 3.5081, 0, 0, 0.983255, -0.182237, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500202, 161557, 0, 0, 0, 1, 1, -9085.33, -361.118, 73.452, 0.1745, 0, 0, 0.087156, 0.996195, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500203, 161557, 0, 0, 0, 1, 1, -9071.23, -371.267, 73.453, 6.1959, 0, 0, 0.04362, -0.999048, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500204, 161557, 0, 0, 0, 1, 1, -9096.34, -358.273, 73.452, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500205, 161557, 0, 0, 0, 1, 1, -9106.75, -337.229, 73.434, 3.4401, 0, 0, 0.988885, -0.148685, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500206, 161557, 0, 0, 0, 1, 1, -9104.13, -342.145, 73.449, 5.8469, 0, 0, 0.21644, -0.976296, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest'),
  (7500207, 161557, 0, 0, 0, 1, 1, -9105.36, -332.526, 73.43, 4.1539, 0, 0, 0.874619, -0.48481, 120, 100, 1, '', 12340, 'CoA - Milly''s Harvest');

-- ---------------------------------------------------------------------------------------------
-- gameobject 174849 -  (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500135);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500135, 174849, 0, 0, 0, 1, 1, -8681.54, -185.572, 91.741, 3.9513, 0, 0, 0.919152, -0.393903, 120, 100, 1, '', 12340, 'CoA - ');

-- ---------------------------------------------------------------------------------------------
-- gameobject 175761 - Civil War in the Plaguelands (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500098);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500098, 175761, 0, 0, 0, 1, 1, -8856.74, -184.672, 83.119, 0.733, 0, 0, 0.358368, 0.93358, 120, 100, 1, '', 12340, 'CoA - Civil War in the Plaguelands');

-- ---------------------------------------------------------------------------------------------
-- gameobject 176573 - Alliance Bell (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500099);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500099, 176573, 0, 0, 0, 1, 1, -8896.91, -173.596, 140.675, 2.2864, 0, 0, 0.909961, 0.414694, 120, 100, 1, '', 12340, 'CoA - Alliance Bell');

-- ---------------------------------------------------------------------------------------------
-- gameobject 178646 - Alliance Supply Crate (3 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500159, 7500160, 7500161);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500159, 178646, 0, 0, 0, 1, 1, -8677.11, -190.133, 91.708, 4.8884, 0, 0, 0.64221, -0.766529, 120, 100, 1, '', 12340, 'CoA - Alliance Supply Crate'),
  (7500160, 178646, 0, 0, 0, 1, 1, -8673.17, -181.535, 91.762, 0.6435, 0, 0, 0.316204, 0.948691, 120, 100, 1, '', 12340, 'CoA - Alliance Supply Crate'),
  (7500161, 178646, 0, 0, 0, 1, 1, -8671.8, -182.373, 91.758, 0.729, 0, 0, 0.356476, 0.934305, 120, 100, 1, '', 12340, 'CoA - Alliance Supply Crate');

-- ---------------------------------------------------------------------------------------------
-- gameobject 191541 - Alchemy Lab (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500103);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500103, 191541, 0, 0, 0, 1, 1, -8873.28, -208.644, 81.304, 5.9006, 0, 0, 0.190123, -0.98176, 120, 100, 1, '', 12340, 'CoA - Alchemy Lab');

-- ---------------------------------------------------------------------------------------------
-- gameobject 244614 - Elwynn Tree (77 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500002, 7500003, 7500004, 7500005, 7500006, 7500007, 7500008, 7500009, 7500010, 7500011, 7500012, 7500013, 7500014, 7500015, 7500016, 7500017, 7500018, 7500019, 7500020, 7500021, 7500022, 7500023, 7500024, 7500025, 7500026, 7500027, 7500028, 7500029, 7500030, 7500031, 7500032, 7500033, 7500034, 7500035, 7500036, 7500037, 7500038, 7500039, 7500040, 7500041, 7500042, 7500043, 7500044, 7500045, 7500046, 7500047, 7500048, 7500049, 7500050, 7500051, 7500052, 7500053, 7500054, 7500055, 7500056, 7500057, 7500058, 7500059, 7500060, 7500061, 7500062, 7500063, 7500064, 7500065, 7500066, 7500067, 7500068, 7500069, 7500070, 7500071, 7500072, 7500073, 7500074, 7500213, 7500214, 7500215, 7500218);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500002, 244614, 0, 0, 0, 1, 1, -9043.79, -106.068, 88.9, 5.6574, 0, 0, 0.307812, -0.951447, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500003, 244614, 0, 0, 0, 1, 1, -9041.31, -107.762, 88.072, 4.1197, 0, 0, 0.882771, -0.469804, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500004, 244614, 0, 0, 0, 1, 1, -8929.57, -206.494, 80.482, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500005, 244614, 0, 0, 0, 1, 1, -8900.04, -103.59, 81.83, 3.9708, 0, 0, 0.915284, -0.402809, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500006, 244614, 0, 0, 0, 1, 1, -8884.2, -101.582, 83.027, 0.0014, 0, 0, 0.000703, 1, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500007, 244614, 0, 0, 0, 1, 1, -8923.98, -81.994, 87.11, 4.7736, 0, 0, 0.685134, -0.728417, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500008, 244614, 0, 0, 0, 1, 1, -8884.3, -99.162, 83.427, 5.7272, 0, 0, 0.274426, -0.961608, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500009, 244614, 0, 0, 0, 1, 1, -8901.01, -59.371, 86.746, 3.7271, 0, 0, 0.95746, -0.288566, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500010, 244614, 0, 0, 0, 1, 1, -8900.21, -57.281, 87.008, 2.0759, 0, 0, 0.86137, 0.507978, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500011, 244614, 0, 0, 0, 1, 1, -8932.76, -41.41, 91.618, 3.983, 0, 0, 0.9128, -0.408407, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500012, 244614, 0, 0, 0, 1, 1, -8916.85, -52.857, 87.291, 4.7604, 0, 0, 0.689938, -0.723869, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500013, 244614, 0, 0, 0, 1, 1, -8825.64, -108.799, 82.722, 2.2552, 0, 0, 0.903388, 0.428825, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500014, 244614, 0, 0, 0, 1, 1, -9145.62, -358.532, 72.332, 1.5915, 0, 0, 0.714403, 0.699735, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500015, 244614, 0, 0, 0, 1, 1, -8942.85, -430.622, 65.287, 2.2788, 0, 0, 0.908376, 0.418153, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500016, 244614, 0, 0, 0, 1, 1, -8825.02, -313.92, 72.657, 3.4176, 0, 0, 0.990492, -0.137571, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500017, 244614, 0, 0, 0, 1, 1, -8743.19, -219.305, 88.843, 3.7985, 0, 0, 0.946536, -0.322599, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500018, 244614, 0, 0, 0, 1, 1, -8719.56, -130.895, 85.869, 6.029, 0, 0, 0.126726, -0.991938, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500019, 244614, 0, 0, 0, 1, 1, -8969.73, -270.51, 75.287, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500020, 244614, 0, 0, 0, 1, 1, -8890.07, -301.955, 75.657, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500021, 244614, 0, 0, 0, 1, 1, -8799.06, -415.154, 80.087, 4.3667, 0, 0, 0.81819, -0.574949, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500022, 244614, 0, 0, 0, 1, 1, -8784.81, -384.898, 71.449, 0.9349, 0, 0, 0.450594, 0.892729, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500023, 244614, 0, 0, 0, 1, 1, -8748.41, -378.309, 71.683, 2.5312, 0, 0, 0.953795, 0.300457, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500024, 244614, 0, 0, 0, 1, 1, -8745.4, -299.309, 79.938, 4.3847, 0, 0, 0.812966, -0.582311, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500025, 244614, 0, 0, 0, 1, 1, -8747.18, -301.105, 79.783, 2.0752, 0, 0, 0.861177, 0.508306, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500026, 244614, 0, 0, 0, 1, 1, -8760.32, -409.48, 74.41, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500027, 244614, 0, 0, 0, 1, 1, -8743.73, -388.828, 73.448, 4.1811, 0, 0, 0.867945, -0.49666, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500028, 244614, 0, 0, 0, 1, 1, -8842.73, -451.531, 69.346, 0.4969, 0, 0, 0.2459, 0.969295, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500029, 244614, 0, 0, 0, 1, 1, -8699.12, -434.107, 144.185, 5.4978, 0, 0, 0.382682, -0.92388, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500030, 244614, 0, 0, 0, 1, 1, -8673.77, -433.82, 180.576, 4.5989, 0, 0, 0.746058, -0.665881, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500031, 244614, 0, 0, 0, 1, 1, -8670.2, -432.838, 182.569, 3.6477, 0, 0, 0.968147, -0.250381, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500032, 244614, 0, 0, 0, 1, 1, -8787.64, -185.57, 81.88, 1.5621, 0, 0, 0.704015, 0.710185, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500033, 244614, 0, 0, 0, 1, 1, -8752.57, -212.051, 87.012, 1.7082, 0, 0, 0.75399, 0.656886, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500034, 244614, 0, 0, 0, 1, 1, -8679.74, -303.947, 83.906, 6.1958, 0, 0, 0.043659, -0.999046, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500035, 244614, 0, 0, 0, 1, 1, -8689.96, -309.775, 85.139, 4.6213, 0, 0, 0.73855, -0.674198, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500036, 244614, 0, 0, 0, 1, 1, -8690.56, -312.217, 85.715, 3.4248, 0, 0, 0.98999, -0.141136, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500037, 244614, 0, 0, 0, 1, 1, -8673.17, -296.051, 86.351, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500038, 244614, 0, 0, 0, 1, 1, -8835.56, -404.632, 74.735, 2.8286, 0, 0, 0.987776, 0.155883, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500039, 244614, 0, 0, 0, 1, 1, -8650.99, -182.279, 97.227, 0.9745, 0, 0, 0.468194, 0.883626, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500040, 244614, 0, 0, 0, 1, 1, -8647.71, -185.387, 97.658, 3.0543, 0, 0, 0.999048, 0.043617, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500041, 244614, 0, 0, 0, 1, 1, -8638.61, -443.74, 197.898, 4.3371, 0, 0, 0.826591, -0.562804, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500042, 244614, 0, 0, 0, 1, 1, -8632.96, -461.525, 174.483, 2.0682, 0, 0, 0.859405, 0.511295, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500043, 244614, 0, 0, 0, 1, 1, -8569.27, -457, 184.742, 4.2062, 0, 0, 0.86163, -0.507537, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500044, 244614, 0, 0, 0, 1, 1, -8612.71, -511.689, 146.38, 3.3985, 0, 0, 0.991761, -0.128106, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500045, 244614, 0, 0, 0, 1, 1, -8540.66, -448.619, 153.419, 3.9706, 0, 0, 0.915312, -0.402745, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500046, 244614, 0, 0, 0, 1, 1, -8552.45, -461.523, 144.15, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500047, 244614, 0, 0, 0, 1, 1, -8612.05, -513.502, 146.047, 4.0352, 0, 0, 0.901841, -0.432067, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500048, 244614, 0, 0, 0, 1, 1, -8676.05, -507.088, 151.964, 1.766, 0, 0, 0.772663, 0.634817, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500049, 244614, 0, 0, 0, 1, 1, -8665.19, -516.096, 149.039, 5.6806, 0, 0, 0.296745, -0.954957, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500050, 244614, 0, 0, 0, 1, 1, -8655.02, -549.461, 147.509, 0.9979, 0, 0, 0.478496, 0.87809, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500051, 244614, 0, 0, 0, 1, 1, -8583.79, -569.818, 145.921, 4.6691, 0, 0, 0.722245, -0.691637, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500052, 244614, 0, 0, 0, 1, 1, -8543.65, -538.158, 145.739, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500053, 244614, 0, 0, 0, 1, 1, -9119.66, -221.059, 74.617, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500054, 244614, 0, 0, 0, 1, 1, -9123.22, -221.969, 74.128, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500055, 244614, 0, 0, 0, 1, 1, -8862.12, -73.152, 84.865, 3.9389, 0, 0, 0.921584, -0.388178, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500056, 244614, 0, 0, 0, 1, 1, -8950.29, -24.279, 97.134, 3.6912, 0, 0, 0.962484, -0.271339, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500057, 244614, 0, 0, 0, 1, 1, -8952.75, -22.484, 98.06, 6.2816, 0, 0, 0.000813, -1, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500058, 244614, 0, 0, 0, 1, 1, -8914.47, 24.396, 112.437, 3.0119, 0, 0, 0.997899, 0.064786, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500059, 244614, 0, 0, 0, 1, 1, -8914.63, 25.773, 112.238, 3.3369, 0, 0, 0.995236, -0.097494, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500060, 244614, 0, 0, 0, 1, 1, -8780.65, -96.322, 85.766, 1.731, 0, 0, 0.76141, 0.648271, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500061, 244614, 0, 0, 0, 1, 1, -8805.3, 30.367, 104.607, 1.6928, 0, 0, 0.7489, 0.662683, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500062, 244614, 0, 0, 0, 1, 1, -8750.21, -12.168, 92.676, 3.1416, 0, 0, 1, 0.000001, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500063, 244614, 0, 0, 0, 1, 1, -8721.96, -9.432, 94.214, 4.7508, 0, 0, 0.6934, -0.720552, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500064, 244614, 0, 0, 0, 1, 1, -8728.46, -124.732, 85.797, 3.8446, 0, 0, 0.938863, -0.344291, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500065, 244614, 0, 0, 0, 1, 1, -8693.45, -47.059, 99.192, 3.6465, 0, 0, 0.968301, -0.249785, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500066, 244614, 0, 0, 0, 1, 1, -8720.13, -2.141, 94.856, 2.6085, 0, 0, 0.964685, 0.263406, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500067, 244614, 0, 0, 0, 1, 1, -8676.32, -87.152, 91.623, 4.9197, 0, 0, 0.630139, -0.776482, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500068, 244614, 0, 0, 0, 1, 1, -8687.76, -26.307, 114.269, 3.2496, 0, 0, 0.998544, -0.053953, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500069, 244614, 0, 0, 0, 1, 1, -8688.96, -24.598, 114.994, 4.163, 0, 0, 0.872408, -0.488778, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500070, 244614, 0, 0, 0, 1, 1, -8663.48, -115.062, 102.506, 4.5291, 0, 0, 0.768842, -0.639439, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500071, 244614, 0, 0, 0, 1, 1, -8654.91, -135.172, 112.265, 3.1329, 0, 0, 0.99999, 0.004361, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500072, 244614, 0, 0, 0, 1, 1, -8653.01, -37.182, 99.261, 2.4609, 0, 0, 0.942642, 0.333804, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500073, 244614, 0, 0, 0, 1, 1, -8653.21, -33.475, 99.879, 1.5528, 0, 0, 0.700708, 0.713448, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500074, 244614, 0, 0, 0, 1, 1, -8677.32, -169.059, 91.937, 0.143, 0, 0, 0.071463, 0.997443, 120, 100, 1, '', 12340, 'CoA - Elwynn Tree'),
  (7500213, 244614, 0, 0, 0, 1, 1, -9051.47, -461.348, 73.0139, 1.07226, 0, 0, 0.510812, 0.859693, 120, 100, 1, '', NULL, NULL),
  (7500214, 244614, 0, 0, 0, 1, 1, -9078.55, -495.613, 82.1781, 4.82753, -0.0280403, 0.107356, 0.661142, -0.742011, 120, 100, 1, '', NULL, NULL),
  (7500215, 244614, 0, 0, 0, 1, 1, -9100.71, -503.035, 83.1135, 3.17247, 0, 0, 0.999881, -0.0154382, 120, 100, 1, '', NULL, NULL),
  (7500218, 244614, 0, 0, 0, 1, 1, -8949.07, -121.479, 83.2139, 0, 0, 0, 0, 1, 300, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 250002 - Barrel of Milk (2 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500157, 7500158);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500157, 250002, 0, 0, 0, 1, 1, -8678.23, -189.375, 91.709, 4.5311, 0, 0, 0.768227, -0.640177, 120, 100, 1, '', 12340, 'CoA - Barrel of Milk'),
  (7500158, 250002, 0, 0, 0, 1, 1, -8677.05, -190.264, 92.319, 5.6306, 0, 0, 0.320534, -0.947237, 120, 100, 1, '', 12340, 'CoA - Barrel of Milk');

-- ---------------------------------------------------------------------------------------------
-- gameobject 271911 - Bubbling Cauldron (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500142);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500142, 271911, 0, 0, 0, 1, 1, -8875.1, -204.393, 81.22, 0.9447, 0, 0, 0.454997, 0.890493, 120, 100, 1, '', 12340, 'CoA - Bubbling Cauldron');

-- ---------------------------------------------------------------------------------------------
-- gameobject 515417 - Wooden Chair, no sit (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500163);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500163, 515417, 0, 0, 0, 1, 1, -8673.9, -182.881, 91.744, 2.5912, 0, 0, 0.962372, 0.271736, 120, 100, 1, '', 12340, 'CoA - Wooden Chair, no sit');

-- ---------------------------------------------------------------------------------------------
-- gameobject 520063 - Scorched Tome (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (6960007);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (6960007, 520063, 0, 0, 0, 1, 1, -8571.74, -261.561, 53.7241, 0, 0.703246, 0, 0, 0.710947, 0, 0, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 520065 - Disturbed Dirt (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500129);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500129, 520065, 0, 0, 0, 1, 1, -8813.85, -309.135, 72.57, 2.8816, 0, 0, 0.991561, 0.12964, 120, 100, 1, 'worldforged_pickup', 12340, 'CoA - Disturbed Dirt');

-- ---------------------------------------------------------------------------------------------
-- gameobject 520066 - Murloc Tool (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500149);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500149, 520066, 0, 0, 0, 1, 1, -8545.82, -514.623, 146.444, 1.02845, -0.433674, 0.46383, 0.379972, 0.672614, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 600530 - Bush Prop (2 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500219, 7500220);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500219, 600530, 0, 0, 0, 1, 1, -8940.47, -120.748, 82.6635, 0, 0, 0, 0, 1, 300, 100, 1, '', NULL, NULL),
  (7500220, 600530, 0, 0, 0, 1, 1, -8947.5, -121.074, 83.1304, 4.48084, 0, 0, -0.784056, 0.62069, 300, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 600639 - Banner Prop (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500221);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500221, 600639, 0, 0, 0, 1, 1, -8944.74, -122.354, 83.1209, 4.37012, 0, 0, -0.817199, 0.576356, 300, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 800054 - Lamp Post (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500210);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500210, 800054, 0, 0, 0, 1, 1, -8704.18, -155.641, 87.728, 0.9624, 0, 0, 0.462847, 0.886438, 120, 100, 1, '', 12340, 'CoA - Lamp Post');

-- ---------------------------------------------------------------------------------------------
-- gameobject 911649 - Eye of Rokan (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500123);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500123, 911649, 0, 0, 0, 1, 1, -8857.81, -184.75, 83.12, 2.7648, 0, 0, 0.982306, 0.187284, 120, 100, 1, '', 12340, 'CoA - Eye of Rokan');

-- ---------------------------------------------------------------------------------------------
-- gameobject 1600928 -  (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500138);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500138, 1600928, 0, 0, 0, 1, 1, -8677.65, -178.037, 93.206, 4.5203, 0, 0, 0.771651, -0.636046, 120, 100, 1, '', 12340, 'CoA - ');

-- ---------------------------------------------------------------------------------------------
-- gameobject 1600933 -  (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500137);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500137, 1600933, 0, 0, 0, 1, 1, -8677.23, -178.117, 93.219, 4.2835, 0, 0, 0.841389, -0.540431, 120, 100, 1, '', 12340, 'CoA - ');

-- ---------------------------------------------------------------------------------------------
-- gameobject 1600935 -  (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500136);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500136, 1600935, 0, 0, 0, 1, 1, -8674.35, -179.275, 92.709, 2.22484, -0.616593, 0.458993, 0.573611, 0.283035, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 1600940 - RPG Fence Post (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500134);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500134, 1600940, 0, 0, 0, 1, 1, -8700.09, -158.201, 88.328, 5.75031, -0.0262612, 0.0997537, 0.261894, -0.959568, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300136 - Beer Mug (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500162);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500162, 2300136, 0, 0, 0, 1, 1, -8673.39, -181.76, 92.35, 1.9227, 0, 0, 0.819962, 0.572418, 120, 100, 1, '', 12340, 'CoA - Beer Mug');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300328 - Ascension_Collision_Npc_Cylinder (3 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500001, 7500216, 7500217);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500001, 2300328, 0, 0, 0, 1, 1, -8944.52, -125.349, 83.357, 4.3668, 0, 0, 0.818151, -0.575004, 120, 100, 1, '', 12340, 'CoA - Ascension_Collision_Npc_Cylinder'),
  (7500216, 2300328, 0, 0, 0, 1, 1, -8909.34, -131.348, 80.7199, 4.3668, 0, 0, 0.818151, -0.575004, 120, 100, 1, '', NULL, NULL),
  (7500217, 2300328, 0, 0, 0, 1, 1, -8909.99, -133.221, 80.5256, 4.3668, 0, 0, 0.818151, -0.575004, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300500 - Lost Page I (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500102);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500102, 2300500, 0, 0, 0, 1, 1, -8912.93, -209.889, 83.0107, 0.0326, 0, 0, 0.016276, 0.999868, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300501 - Dungeon Door (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500131);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500131, 2300501, 0, 0, 0, 1, 1, -8775.58, -278.451, 79.173, 3.1463, 0, 0, 0.999997, -0.002356, 120, 100, 1, '', 12340, 'CoA - Dungeon Door');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300503 - Lost Page II (4 spawns)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500143, 7500144, 7500145, 7500146);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500143, 2300503, 0, 0, 0, 1, 1, -8859.49, -188.781, 90.3938, 1.1302, 0, 0, 0.535488, 0.844543, 120, 100, 1, '', NULL, NULL),
  (7500144, 2300503, 0, 0, 0, 1, 1, -8858.7, -191.539, 90.4269, 1.4156, 0, 0, 0.65017, 0.759788, 120, 100, 1, '', NULL, NULL),
  (7500145, 2300503, 0, 0, 0, 1, 1, -8859.06, -186.182, 90.3954, 5.7858, 0, 0, 0.246121, -0.969239, 120, 100, 1, '', NULL, NULL),
  (7500146, 2300503, 0, 0, 0, 1, 1, -8856.93, -188.018, 90.397, 4.2097, 0, 0, 0.860752, -0.509025, 120, 100, 1, '', 12340, 'CoA - Lost Page II');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300504 - Lost Page III (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500106);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500106, 2300504, 0, 0, 0, 1, 1, -8881.75, -182.758, 81.9442, 4.3169, 0, 0, 0.832248, -0.554404, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300505 - Lost Page IV (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500154);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500154, 2300505, 0, 0, 0, 1, 1, -8857.35, -185.58, 83.128, 2.2199, 0, 0, 0.895665, 0.444729, 120, 100, 1, '', 12340, 'CoA - Lost Page IV');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300520 - Abbess’ Journal (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500165);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500165, 2300520, 0, 0, 0, 1, 1, -8575.74, -253.084, 53.7228, 2.8954, 0, 0, 0.992431, 0.122801, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300521 - Abbess’s Staff (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500166);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500166, 2300521, 0, 0, 0, 1, 1, -8638.85, -404.449, 54.723, 3.18773, 0.502571, -0.0115944, 0.864228, -0.0199379, 120, 100, 1, '', NULL, NULL);

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300522 - Heretical Idol Purified (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500164);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500164, 2300522, 0, 0, 0, 1, 1, -8619.05, -278.116, 57.693, 2.2519, 0, 0, 0.902683, 0.430306, 120, 100, 1, '', 12340, 'CoA - Heretical Idol Purified');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300523 - Jewel (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500156);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500156, 2300523, 0, 0, 0, 1, 1, -8658.67, -318.016, 53.725, 2.9164, 0, 0, 0.993667, 0.112369, 120, 100, 1, '', 12340, 'CoA - Jewel');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300565 - Doodad_InstanceNewPortal_Purple01 (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500170);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500170, 2300565, 0, 0, 0, 1, 1, -8628.39, -491.629, 40.111, 1.5811, 0, 0, 0.710747, 0.703447, 120, 100, 1, '', 12340, 'CoA - Doodad_InstanceNewPortal_Purple01');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300566 - Doodad_InstanceNewPortal_Purple_Skull01 (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500169);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500169, 2300566, 0, 0, 0, 1, 1, -8628.39, -491.629, 40.111, 1.5811, 0, 0, 0.710747, 0.703447, 120, 100, 1, '', 12340, 'CoA - Doodad_InstanceNewPortal_Purple_Skull01');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300567 - Doodad_InstancePortal_Green_5Man_Mythic01 (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500168);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500168, 2300567, 0, 0, 0, 1, 1, -8628.39, -491.629, 40.111, 1.5811, 0, 0, 0.710747, 0.703447, 120, 100, 1, '', 12340, 'CoA - Doodad_InstancePortal_Green_5Man_Mythic01');

-- ---------------------------------------------------------------------------------------------
-- gameobject 2300568 - Meeting Stone (1 spawn)
-- ---------------------------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (7500167);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
  (7500167, 2300568, 0, 0, 0, 1, 1, -8608.71, -465.472, 53.724, 2.0858, 0, 0, 0.863856, 0.503739, 120, 100, 1, '', 12340, 'CoA - Meeting Stone');

-- ##########################################################################################
-- SECTION 3 - SPAWN REMOVALS
-- ##########################################################################################

-- Rows a rebuilt core still has because earlier versions of this content (or the base
-- world) placed them there, and the live world deliberately removed: the Spada-house
-- mailbox, the old camp props, the replaced Murloc Tool, the duplicate benches
-- (base-world guids 26725-26741), the stray props (the extra Lost Page V/VI chests,
-- the second Scorched Tome, the waterlogged chest, five old tool-era rows), the
-- leftover Rabbit 79947, the disabled Living Heresy stub 9000135, the removed
-- Shadewell spider, the extra wayward censor and the stock rabbits/vermin the valley
-- no longer uses.

DELETE FROM `creature` WHERE `guid` = 79947;  -- creature 721 - Rabbit at (-8931.6, -137.1)
DELETE FROM `creature` WHERE `guid` = 79963;  -- creature 375 - Priestess Anetta at (-8853.6, -193.3)
DELETE FROM `creature` WHERE `guid` = 80100;  -- creature 6 - Kobold Vermin at (-8765.4, -256.0)
DELETE FROM `creature` WHERE `guid` = 80103;  -- creature 257 - Kobold Worker at (-8778.1, -254.6)
DELETE FROM `creature` WHERE `guid` = 80105;  -- creature 257 - Kobold Worker at (-8781.4, -274.6)
DELETE FROM `creature` WHERE `guid` = 80106;  -- creature 69 - Timber Wolf at (-8752.9, -295.0)
DELETE FROM `creature` WHERE `guid` = 80107;  -- creature 257 - Kobold Worker at (-8769.0, -272.6)
DELETE FROM `creature` WHERE `guid` = 80116;  -- creature 6 - Kobold Vermin at (-8796.1, -258.3)
DELETE FROM `creature` WHERE `guid` = 80122;  -- creature 257 - Kobold Worker at (-8811.3, -257.7)
DELETE FROM `creature` WHERE `guid` = 80132;  -- creature 721 - Rabbit at (-8795.5, -296.8)
DELETE FROM `creature` WHERE `guid` = 80189;  -- creature 38 - Defias Thug at (-9075.3, -332.1)
DELETE FROM `creature` WHERE `guid` = 80193;  -- creature 38 - Defias Thug at (-9054.5, -311.6)
DELETE FROM `creature` WHERE `guid` = 7500304;  -- Shadewell Spider 161707 - removed 2026-09-29
DELETE FROM `creature` WHERE `guid` = 7500351;  -- extra Accursed Censor 161712 spawn - removed 2026-09-29
DELETE FROM `creature` WHERE `guid` = 7500369;  -- duplicate wayward theologian 161713 spawn - replaced by 9000133
DELETE FROM `creature` WHERE `guid` = 9000135;  -- creature 161711 - Living Heresy at (-8853.6, -187.3)

DELETE FROM `gameobject` WHERE `guid` = 26725;  -- gameobject 151956 - Wooden Bench at (-8861.5, -180.4)
DELETE FROM `gameobject` WHERE `guid` = 26726;  -- gameobject 151964 - Wooden Bench at (-8876.2, -191.1)
DELETE FROM `gameobject` WHERE `guid` = 26727;  -- gameobject 151968 - Wooden Bench at (-8889.9, -162.1)
DELETE FROM `gameobject` WHERE `guid` = 26728;  -- gameobject 151969 - Wooden Bench at (-8905.3, -182.1)
DELETE FROM `gameobject` WHERE `guid` = 26729;  -- gameobject 151970 - Wooden Bench at (-8912.8, -189.9)
DELETE FROM `gameobject` WHERE `guid` = 26730;  -- gameobject 151972 - Wooden Bench at (-8905.1, -210.8)
DELETE FROM `gameobject` WHERE `guid` = 26731;  -- gameobject 151963 - Wooden Bench at (-8874.5, -171.6)
DELETE FROM `gameobject` WHERE `guid` = 26733;  -- gameobject 151959 - Wooden Bench at (-8853.8, -180.5)
DELETE FROM `gameobject` WHERE `guid` = 26734;  -- gameobject 151961 - Wooden Bench at (-8873.4, -172.7)
DELETE FROM `gameobject` WHERE `guid` = 26735;  -- gameobject 151962 - Wooden Bench at (-8866.2, -175.6)
DELETE FROM `gameobject` WHERE `guid` = 26737;  -- gameobject 151966 - Wooden Bench at (-8911.9, -182.8)
DELETE FROM `gameobject` WHERE `guid` = 26738;  -- gameobject 151954 - Wooden Bench at (-8920.3, -208.2)
DELETE FROM `gameobject` WHERE `guid` = 26739;  -- gameobject 151960 - Wooden Bench at (-8882.2, -188.2)
DELETE FROM `gameobject` WHERE `guid` = 26740;  -- gameobject 151965 - Wooden Bench at (-8910.4, -168.0)
DELETE FROM `gameobject` WHERE `guid` = 26741;  -- gameobject 151953 - Wooden Bench at (-8883.1, -155.2)
DELETE FROM `gameobject` WHERE `guid` = 29287;  -- gameobject 1940 - Campfire at (-8637.6, -547.4)
DELETE FROM `gameobject` WHERE `guid` = 6901512;  -- gameobject 144570 - Mailbox at (-8908.8, -131.8)
DELETE FROM `gameobject` WHERE `guid` = 6940013;  -- gameobject 90636 - Forgotten Sack at (-9040.0, -46.1)
DELETE FROM `gameobject` WHERE `guid` = 6940032;  -- gameobject 90217 - Alliance Gem of Fortitude at (-8679.2, -186.2)
DELETE FROM `gameobject` WHERE `guid` = 6940063;  -- gameobject 95670 - Apprentice Staff at (-9123.9, -224.3)
DELETE FROM `gameobject` WHERE `guid` = 6940319;  -- gameobject 90215 - Old Grave  at (-8687.8, -298.0)
DELETE FROM `gameobject` WHERE `guid` = 6940345;  -- gameobject 90216 - Defias Special Bucket at (-9142.9, -289.0)
DELETE FROM `gameobject` WHERE `guid` = 6940368;  -- gameobject 518303 - Disturbed Dirt at (-8768.7, -321.4)
DELETE FROM `gameobject` WHERE `guid` = 6940503;  -- gameobject 520063 - Scorched Tome at (-8717.2, -312.6)
DELETE FROM `gameobject` WHERE `guid` = 6940787;  -- gameobject 520066 - Murloc Tool at (-8545.0, -515.4)
DELETE FROM `gameobject` WHERE `guid` = 6940832;  -- gameobject 520065 - Disturbed Dirt at (-8820.3, -325.3)
DELETE FROM `gameobject` WHERE `guid` = 6941293;  -- gameobject 254232 - Slain Traveler at (-8697.2, -474.3)
DELETE FROM `gameobject` WHERE `guid` = 6941333;  -- gameobject 90214 - Wax Stained Bag at (-8769.0, -174.1)
DELETE FROM `gameobject` WHERE `guid` = 6941353;  -- gameobject 95602 - Worn Shovel at (-8627.2, -107.9)
DELETE FROM `gameobject` WHERE `guid` = 6960001;  -- gameobject 90634 - Brother's Cherry Pie at (-8912.0, -103.8)
DELETE FROM `gameobject` WHERE `guid` = 6960002;  -- gameobject 90635 - Cherry Pie prop at (-8912.2, -103.5)
DELETE FROM `gameobject` WHERE `guid` = 7500101;  -- Lost Page VI chest 2300517 (worldforged prop) - removed 2026-09-29
DELETE FROM `gameobject` WHERE `guid` = 7500119;  -- gameobject 151955 - Wooden Bench at (-8888.9, -151.5)
DELETE FROM `gameobject` WHERE `guid` = 7500120;  -- gameobject 151958 - Wooden Bench at (-8917.3, -164.1)
DELETE FROM `gameobject` WHERE `guid` = 7500128;  -- Old Northshire Bolter 520064 (duplicate of the module placement 6940835) - removed 2026-09-29
DELETE FROM `gameobject` WHERE `guid` = 7500130;  -- Waterlogged Chest 95613 - duplicate prop removed 2026-09-29
DELETE FROM `gameobject` WHERE `guid` = 7500141;  -- Scorched Tome 520063 - duplicate of the relic-camp tome - removed 2026-09-29
DELETE FROM `gameobject` WHERE `guid` = 7500147;  -- Lost Page V chest 2300516 - removed 2026-09-29
DELETE FROM `gameobject` WHERE `guid` = 7500148;  -- Lost Page V chest 2300516 (worldforged prop) - removed 2026-09-29
DELETE FROM `gameobject` WHERE `guid` = 7500151;  -- gameobject 151967 - Wooden Bench at (-8849.8, -192.8)
DELETE FROM `gameobject` WHERE `guid` = 7500152;  -- gameobject 151957 - Wooden Bench at (-8847.9, -187.0)

-- ##########################################################################################
-- SECTION 4 - northshire world layer (NPCs, props, quest texts)
-- ##########################################################################################

-- northshire_custom_only.sql - generated 2026-09-28 03:51 from northshire_full_apply_fixed_animations.sql
--
-- FILTER RULE: a row is kept only when its NPC id does NOT exist in the
-- clean core database (frozen clean-core backup).
-- Unique NPCs (exactly one spawn in core): position_x/y/z are updated to this
-- script's values. EXCEPTION: all gameobject rows are always
-- applied; stock NPCs are never created or deleted.
-- GUID deletes were trimmed to the custom spawns this script itself manages.
--
-- EMOTE RULE (new): a spawn whose exported creature_addon sets an emote or a
-- non-zero stand state is allowed even when its entry is stock:
--   * within 1.0 yd of an existing core spawn of the same entry -> animation
--     applied onto that core spawn (no duplicate NPC);
--   * otherwise imported as a new spawn.
-- Emote NPCs: 6 attached, 20 imported, 15 custom; all listed in custom_emote_marks.
--
--   kept   : DELETE creature (range)=1, DELETE creature_addon (range)=1, DELETE ctm=26, DELETE gameobject (range)=1, DELETE waypoint (range)=1, INSERT IGNORE cdi=499, INSERT IGNORE model_info=1, INSERT creature=119, INSERT creature (emote)=20, INSERT creature_addon=124, INSERT creature_template=45, INSERT cta=27, INSERT ctm=45, INSERT waypoint=9, INSERT/REPLACE gameobject=212, INSERT/REPLACE go_tpl=77, REPLACE creature_addon (emote attach)=6, REPLACE creature_display_preset=1, REPLACE go_loot=1, REPLACE go_tpl (script preserved)=6, UPDATE creature position (unique)=11, UPDATE creature_template=1, UPDATE creature_template (filtered)=3, UPDATE gameobject_template=1, emote attach (spawn skipped)=6
--   dropped: DELETE creature=3, DELETE creature_addon=3, DELETE ctm=1, DELETE gameobject=1, INSERT IGNORE model_info=498, INSERT creature (core, dropped)=216, INSERT creature_addon=91, INSERT creature_template=28, INSERT cta=1, INSERT ctm=28, INSERT waypoint=72, INSERT/REPLACE item_template=1, UPDATE creature_template=1, UPDATE creature_template (stock, dropped)=1
--
SET `FOREIGN_KEY_CHECKS` = 0;

START TRANSACTION;

-- creature_template / creature_template_model
DELETE FROM `creature_template_model` WHERE `CreatureID` = 537;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (537, 0, 0, 0, 0, 0, 'Defias Trainee', '', NULL, 0, 1, 2, 0, 14, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.8956, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (537);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (537, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50280;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50280, 0, 0, 0, 0, 0, 'Brother William', 'Templar Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50280);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50280, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50282;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50282, 0, 0, 0, 0, 0, 'Soridormi', 'Chronomancer Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50282);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50282, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50283;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50283, 0, 0, 0, 0, 0, 'Patal the Mad', 'Cultist Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50283);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50283, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50286;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50286, 0, 0, 0, 0, 0, 'Chaplain Nysoni', 'Sun Cleric Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50286);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50286, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50287;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50287, 0, 0, 0, 0, 0, 'Norman Goldshire', 'Tinker Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50287);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50287, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50289;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50289, 0, 0, 0, 0, 0, 'Troes the Remover', 'Reaper Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50289);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50289, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50291;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50291, 0, 0, 0, 0, 0, 'Wanda Belezin', 'Runemaster Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50291);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50291, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50292;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50292, 0, 0, 0, 0, 0, 'Whisp the Silent', 'Bloodmage Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50292);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50292, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50295;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50295, 0, 0, 0, 0, 0, 'Amanda the Reaver', 'Barbarian Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50295);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50295, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50324;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50324, 0, 0, 0, 0, 0, 'Vanguard Gus', 'Guardian Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50324);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50324, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50325;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50325, 0, 0, 0, 0, 0, 'Deacon Frost', 'Witch Hunter Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50325);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50325, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50340;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (50340, 0, 0, 0, 0, 0, 'Koby the Incinerator', 'Pyromancer Trainer', NULL, 0, 15, 17, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50340);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (50340, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (80894, 0, 0, 0, 0, 0, 'Water Source', '', NULL, 0, 60, 60, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554944, 2048, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.8100, 1.0000, 1, 1, 0, 0, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (80894);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (80894, 0, 11686, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (80894);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (80894, 0, 0, 0, 4097, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161700;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161700, 0, 0, 0, 0, 0, 'Bianca Spada', '', NULL, 0, 6, 6, 0, 12, 2, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 770, 16, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9600, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161700);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161700, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161700);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161700, 0, 0, 0, 4096, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161701;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161701, 0, 0, 0, 0, 0, 'Moroi Spada', 'Seminarian of Northshire Abbey', NULL, 0, 11, 11, 0, 12, 2, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 770, 16, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9800, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161701);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161701, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161701);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161701, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161702;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161702, 0, 0, 0, 0, 0, 'Sister Alma', 'Ancient Priestess of Northshire', NULL, 0, 55, 55, 0, 12, 2, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 770, 16, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.0000, 1.0000, 1, 1, 0, 998, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161702);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161702, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161702);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161702, 0, 0, 33554432, 0, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161705;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161705, 0, 0, 0, 0, 0, 'Injured Northshire Guard', '', NULL, 0, 17, 17, 0, 12, 3, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 770, 16, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.0000, 1.0000, 1, 1, 0, 998, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161705);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161705, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161705);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161705, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161707, 0, 0, 0, 0, 0, 'Shadewell Spider', '', NULL, 0, 3, 3, 0, 16, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 2048, 256, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161707);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161707, 0, 955, 0.6000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161707);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161707, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161708, 0, 0, 0, 0, 0, 'Accursed Judge', '', NULL, 0, 3, 3, 0, 16, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 2048, 256, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161708);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161708, 0, 4629, 0.8000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161708);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161708, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161710, 0, 0, 0, 0, 0, 'Carthorse', '', NULL, 0, 3, 3, 0, 12, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33555200, 2048, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161710);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161710, 0, 2408, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161710);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161710, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161712, 0, 0, 0, 0, 0, 'Accursed Censor', '', NULL, 0, 4, 4, 0, 25, 0, 1, 1.14286, 1, 1, 20, 1, 0, 1, 2000, 0, 1, 1, 1, 0, 2048, 256, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 2.7900, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161712);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161712, 0, 7555, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161712);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161712, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161713;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161713, 0, 0, 0, 0, 0, 'Wayward Theologian', '', NULL, 0, 7, 7, 0, 16, 0, 1, 1.14286, 1, 1, 20, 1, 0, 1, 2000, 0, 1, 1, 1, 0, 2064, 256, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 5.7600, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161713);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161713, 0, 49, 1.1000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161713);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161713, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161715, 0, 0, 0, 0, 0, '[KC] Purify Relics', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.0000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161715);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161715, 0, 11686, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161715);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161715, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161716, 0, 0, 0, 0, 0, 'Shadewell Murloc', '', NULL, 0, 3, 3, 0, 25, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 32768, 2048, 256, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161716);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161716, 0, 757, 0.8000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161716);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161716, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161717, 0, 0, 0, 0, 0, 'Shadewell Murloc Oracle', '', NULL, 0, 16, 16, 0, 16, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 32768, 2048, 256, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161717);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161717, 0, 1079, 0.8000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161717);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161717, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161736, 0, 0, 0, 0, 0, 'Defias Plunderer', '', NULL, 0, 3, 3, 0, 16, 2, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 2048, 256, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161736);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161736, 0, 4418, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161736);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161736, 0, 0, 1, 0, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161841, 0, 0, 0, 0, 0, 'Shadewell Murloc Forager', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 0, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 1, 288, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'PassiveAI', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 0, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161841);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161841, 0, 757, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161841);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161841, 0, 0, 7, 0, 65, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161842, 0, 0, 0, 0, 0, 'Defias Plunderer', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 0, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 1, 288, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'PassiveAI', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 0, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161842);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161842, 0, 4419, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161842);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161842, 0, 0, 7, 0, 65, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161844;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161844, 0, 0, 0, 0, 0, 'Father Harnos', '', NULL, 0, 8, 8, 0, 12, 2, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 770, 16, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9600, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161844);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161844, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161844);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161844, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161857;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161857, 0, 0, 0, 0, 0, 'Echo of the High Inquisitor', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 16, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161857);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161857, 0, 49, 1.2000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161857);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161857, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161858, 0, 0, 0, 0, 0, 'Echo of the Abbess', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161858);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161858, 0, 139062, 1.2000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161858);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161858, 0, 0, 0, 1, 672, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161895, 0, 0, 0, 0, 0, 'Accursed Judge', '', NULL, 0, 3, 3, 0, 25, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161895);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161895, 0, 5548, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161895);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161895, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (161897, 0, 0, 0, 0, 0, 'Accursed Judge', '', NULL, 0, 3, 3, 0, 25, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.9300, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161897);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161897, 0, 1501, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (161897);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (161897, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (200200, 0, 0, 0, 0, 0, 'Darien''s Horse', '', NULL, 0, 60, 60, 0, 35, 0, 1, 1.14286, 1, 1, 20, 1, 0, 1, 2000, 0, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.3120, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (200200);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (200200, 0, 126139, 1.1000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (200200);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (200200, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (399223, 0, 0, 0, 0, 0, 'Zipi', 'The Bully', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 1, 1, 0, 0, 0, 1, 2000, 0, 1, 1, 1, 393218, 2048, 32, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 'PassiveAI', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 0, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (399223);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (399223, 0, 2299, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (399223);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (399223, 0, 0, 7, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 501266;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (501266, 0, 0, 0, 0, 0, 'Valerius Thorne', 'Death Knight Trainer', NULL, 0, 55, 55, 0, 35, 179, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33282, 2064, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.6900, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (501266);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (501266, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 502770;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (502770, 0, 0, 0, 0, 0, 'Niki Thesla', 'Stormbringer Trainer', NULL, 0, 5, 5, 0, 12, 179, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 514, 2064, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (502770);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (502770, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 502923;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (502923, 0, 0, 0, 0, 0, 'Halbert the Scoundrel', 'Necromancer Trainer', NULL, 0, 5, 5, 0, 12, 179, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 514, 2064, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (502923);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (502923, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (502923);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (502923, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 502960;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (502960, 0, 0, 0, 0, 0, 'Doctor Yara', 'Witch Doctor Trainer', NULL, 0, 5, 5, 0, 12, 179, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 514, 2064, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (502960);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (502960, 0, 50, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (502960);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (502960, 0, 0, 0, 1, 133, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 503410;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (503410, 0, 0, 0, 0, 0, 'Owen of Moonbrook', 'Ranger Trainer', NULL, 0, 5, 5, 0, 12, 179, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 514, 2064, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (503410);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (503410, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (503410);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (503410, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (522923, 0, 0, 0, 0, 0, 'Skeletal Warrior', '', NULL, 0, 5, 5, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 1107296768, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.5000, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (522923);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (522923, 0, 775, 0.6000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_addon` WHERE `entry` IN (522923);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (522923, 0, 0, 0, 1, 0, '') ON DUPLICATE KEY UPDATE `bytes1` = VALUES(`bytes1`), `bytes2` = VALUES(`bytes2`), `emote` = VALUES(`emote`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (721111, 0, 0, 0, 0, 0, 'Cookie', '', NULL, 0, 1, 1, 0, 31, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.0150, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (721111);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (721111, 0, 5555, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (922442, 0, 0, 0, 0, 0, 'Chicken', '', NULL, 0, 1, 1, 0, 31, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.0112, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (922442);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (922442, 0, 304, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 10157356;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (10157356, 0, 0, 0, 0, 0, 'Challenger Darien', 'Leveling Challenges and Trials', NULL, 0, 25, 27, 0, 35, 0, 1, 1.14286, 1, 1, 20, 1, 0, 1, 2000, 0, 1, 1, 1, 0, 0, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.6406, 1.0000, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `detection_range` = VALUES(`detection_range`), `faction` = VALUES(`faction`), `RegenHealth` = VALUES(`RegenHealth`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (10157356);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (10157356, 0, 49, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `Probability` = VALUES(`Probability`);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (10913, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (5035, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (604, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3275, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (365, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3277, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3276, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3251, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1859, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2299, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (447, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (328, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2072, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (347, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (654, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3253, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3317, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (604, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (10913, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3278, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (134, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (447, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (604, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3167, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3167, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3167, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1060, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2299, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2299, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2410, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (5087, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (5233, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (134, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (8489, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11354, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (4449, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (3167, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (447, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (134, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (955, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (4629, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2408, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (7555, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (757, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1079, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (4418, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2299, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (757, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (4419, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES (139062, 0.38, 1.5, 2, 0, 12340);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (139062, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (5548, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1501, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (757, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1079, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (757, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1079, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (1060, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (134, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (328, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (126139, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (604, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (328, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2299, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (2408, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (775, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (5555, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (304, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (11686, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);

DELETE FROM `creature_addon` WHERE `guid` IN (7500001,7500002,7500003,7500004,7500005,7500006,7500007,7500099,7500101,7500104,7500125,7500126,7500127,7500128,7500129,7500130,7500131,7500132,7500133,7500134,7500135,7500136,7500137,7500153,7500172,7500174,7500194,7500221,7500228,7500229,7500230,7500231,7500233,7500234,7500235,7500237,7500238,7500239,7500240,7500241,7500242,7500243,7500244,7500245,7500250,7500251,7500252,7500253,7500259,7500263,7500273,7500277,7500278,7500279,7500280,7500281,7500282,7500283,7500284,7500285,7500286,7500287,7500288,7500289,7500290,7500291,7500292,7500294,7500295,7500296,7500297,7500298,7500299,7500300,7500301,7500302,7500303,7500304,7500305,7500306,7500307,7500308,7500309,7500310,7500311,7500312,7500313,7500314,7500315,7500316,7500317,7500318,7500319,7500320,7500321,7500322,7500323,7500324,7500325,7500326,7500327,7500328,7500329,7500330,7500331,7500332,7500333,7500334,7500335,7500336,7500337,7500338,7500339,7500340,7500341,7500342,7500343,7500344,7500345,7500346,7500347,7500348,7500349,7500350,7500351,7500352,7500353,7500355,7500356,7500357,7500358,7500359,7500361,7500362,7500363,7500364,7500369,7500371,7500372);
DELETE FROM `waypoint_data` WHERE `id` IN (7500001,7500002,7500003,7500004,7500005,7500006,7500007,7500099,7500101,7500104,7500125,7500126,7500127,7500128,7500129,7500130,7500131,7500132,7500133,7500134,7500135,7500136,7500137,7500153,7500172,7500174,7500194,7500221,7500228,7500229,7500230,7500231,7500233,7500234,7500235,7500237,7500238,7500239,7500240,7500241,7500242,7500243,7500244,7500245,7500250,7500251,7500252,7500253,7500259,7500263,7500273,7500277,7500278,7500279,7500280,7500281,7500282,7500283,7500284,7500285,7500286,7500287,7500288,7500289,7500290,7500291,7500292,7500294,7500295,7500296,7500297,7500298,7500299,7500300,7500301,7500302,7500303,7500304,7500305,7500306,7500307,7500308,7500309,7500310,7500311,7500312,7500313,7500314,7500315,7500316,7500317,7500318,7500319,7500320,7500321,7500322,7500323,7500324,7500325,7500326,7500327,7500328,7500329,7500330,7500331,7500332,7500333,7500334,7500335,7500336,7500337,7500338,7500339,7500340,7500341,7500342,7500343,7500344,7500345,7500346,7500347,7500348,7500349,7500350,7500351,7500352,7500353,7500355,7500356,7500357,7500358,7500359,7500361,7500362,7500363,7500364,7500369,7500371,7500372);

UPDATE `creature` SET `position_x` = -8892.210, `position_y` = -176.430, `position_z` = 81.580 WHERE `guid` = 9000019;

UPDATE `creature` SET `position_x` = -8947.640, `position_y` = -132.320, `position_z` = 83.720 WHERE `guid` = 79942;

UPDATE `creature` SET `position_x` = -8927.620, `position_y` = -201.790, `position_z` = 80.680 WHERE `guid` = 79965;

UPDATE `creature` SET `position_x` = -8902.130, `position_y` = -181.650, `position_z` = 113.240 WHERE `guid` = 79968;
UPDATE `creature` SET `position_x` = -8869.220, `position_y` = -163.240, `position_z` = 80.970 WHERE `guid` = 79971;
UPDATE `creature` SET `position_x` = -8874.240, `position_y` = -185.590, `position_z` = 81.940 WHERE `guid` = 79969;

UPDATE `creature` SET `position_x` = -8909.230, `position_y` = -131.390, `position_z` = 80.720 WHERE `guid` = 79970;
UPDATE `creature` SET `position_x` = -8909.460, `position_y` = -104.160, `position_z` = 82.030 WHERE `guid` = 79953;
UPDATE `creature` SET `position_x` = -8898.230, `position_y` = -119.840, `position_z` = 82.020 WHERE `guid` = 79952;
UPDATE `creature` SET `position_x` = -8897.710, `position_y` = -115.330, `position_z` = 82.000 WHERE `guid` = 79951;
-- [emote] spawn 7500258 (entry 152): animation applied to existing core spawn 79950 (no duplicate NPC)
UPDATE `creature` SET `position_x` = -8901.580, `position_y` = -112.820, `position_z` = 81.850 WHERE `guid` = 79950;

UPDATE `creature` SET `position_x` = -8850.650, `position_y` = -224.020, `position_z` = 81.670 WHERE `guid` = 80118;

-- creature_addon / waypoint_data
DELETE FROM `creature_addon` WHERE `guid` IN (7500364, 7500001, 7500002, 7500003, 7500004, 7500005, 7500006, 7500007, 7500099, 7500101, 7500104, 7500125, 7500126, 7500127, 7500128, 7500129, 7500130, 7500131, 7500132, 7500133, 7500134, 7500135, 7500136, 7500137, 7500153, 7500172, 7500174, 7500194, 7500221);

INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES
(7500364, 7500364, 0, 0, 4097, 234, ''),
(7500001, 0, 0, 0, 1, 0, ''),
(7500002, 0, 0, 0, 1, 0, ''),
(7500003, 0, 0, 0, 4097, 0, ''),
(7500004, 0, 0, 0, 4097, 0, ''),
(7500005, 0, 0, 0, 4097, 0, ''),
(7500006, 0, 0, 0, 4097, 0, ''),
(7500007, 0, 0, 0, 4097, 0, ''),
(7500099, 0, 0, 0, 1, 234, ''),
(7500101, 0, 0, 0, 1, 234, ''),
(7500104, 0, 0, 0, 1, 234, ''),
(7500125, 0, 0, 0, 1, 0, ''),
(7500126, 0, 0, 0, 1, 0, ''),
(7500127, 0, 0, 0, 1, 0, ''),
(7500128, 0, 0, 0, 1, 0, ''),
(7500129, 0, 0, 0, 1, 0, ''),
(7500130, 0, 0, 0, 1, 0, ''),
(7500131, 0, 0, 0, 1, 0, ''),
(7500132, 0, 0, 0, 1, 0, ''),
(7500133, 0, 0, 0, 1, 0, ''),
(7500134, 0, 0, 0, 1, 0, ''),
(7500135, 0, 0, 0, 1, 0, ''),
(7500136, 0, 0, 0, 1, 0, ''),
(7500137, 0, 0, 0, 1, 0, ''),
(7500153, 0, 0, 1, 0, 0, ''),
(7500172, 0, 0, 1, 0, 0, ''),
(7500174, 0, 0, 1, 0, 0, ''),
(7500194, 0, 0, 1, 0, 0, ''),
(7500221, 0, 0, 1, 0, 0, '');
-- [emote] animation of spawn 7500222 applied to core spawn 80262 (entry 11260)
REPLACE INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (80262, 0, 0, 0, 1, 234, '');
-- [emote] animation of spawn 7500224 applied to core spawn 80145 (entry 11260)
REPLACE INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (80145, 0, 0, 0, 1, 234, '');
-- [emote] animation of spawn 7500226 applied to core spawn 80119 (entry 11260)
REPLACE INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (80119, 0, 0, 0, 1, 234, '');
-- [emote] animation of spawn 7500227 applied to core spawn 80127 (entry 11260)
REPLACE INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (80127, 0, 0, 0, 1, 234, '');
DELETE FROM `creature_addon` WHERE `guid` IN (7500228, 7500230, 7500233, 7500234, 7500235, 7500238, 7500239, 7500240, 7500241, 7500242, 7500244, 7500250, 7500251, 7500252, 7500253);

INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES
(7500228, 0, 0, 0, 1, 0, ''),
(7500230, 0, 0, 0, 1, 0, ''),
(7500233, 0, 0, 0, 1, 0, ''),
(7500234, 0, 0, 0, 1, 0, ''),
(7500235, 0, 0, 0, 1, 0, ''),
(7500238, 0, 0, 0, 1, 0, ''),
(7500239, 0, 0, 0, 1, 0, ''),
(7500240, 0, 0, 0, 1, 0, ''),
(7500241, 0, 0, 0, 1, 0, ''),
(7500242, 0, 0, 0, 1, 0, ''),
(7500244, 0, 0, 0, 1, 0, ''),
(7500250, 0, 0, 0, 1, 0, ''),
(7500251, 0, 0, 0, 4096, 0, ''),
(7500252, 0, 0, 0, 1, 0, ''),
(7500253, 0, 0, 0, 1, 0, '');
-- [emote] animation of spawn 7500258 applied to core spawn 79950 (entry 152)
REPLACE INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (79950, 0, 0, 0, 4353, 69, '');
DELETE FROM `creature_addon` WHERE `guid` IN (7500259, 7500263);

INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES
(7500259, 0, 0, 0, 1, 133, ''),
(7500263, 0, 0, 3, 4097, 0, '');
-- [emote] animation of spawn 7500271 applied to core spawn 80188 (entry 38)
REPLACE INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES (80188, 0, 0, 0, 4096, 69, '');
DELETE FROM `creature_addon` WHERE `guid` IN (7500273, 7500277, 7500279, 7500281, 7500285, 7500289, 7500290, 7500291, 7500292, 7500294, 7500295, 7500296, 7500297, 7500298, 7500299, 7500300, 7500301, 7500302, 7500303, 7500304, 7500305, 7500306, 7500307, 7500308, 7500309, 7500310, 7500311, 7500312, 7500313, 7500314, 7500315, 7500316, 7500317, 7500318, 7500319, 7500320, 7500321, 7500322, 7500323, 7500324, 7500325, 7500326, 7500327, 7500328, 7500329, 7500330, 7500331, 7500332, 7500333, 7500334, 7500335, 7500336, 7500337, 7500338, 7500339, 7500340, 7500341, 7500342, 7500343, 7500345, 7500346, 7500347, 7500348, 7500349, 7500350, 7500351, 7500352, 7500353, 7500355, 7500356, 7500357, 7500358, 7500359, 7500361, 7500362, 7500363, 7500369, 7500372);

INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`) VALUES
(7500273, 0, 0, 0, 4097, 69, ''),
(7500277, 0, 0, 0, 4097, 0, ''),
(7500279, 0, 0, 8, 0, 0, ''),
(7500281, 0, 0, 0, 1, 0, ''),
(7500285, 0, 0, 3, 4097, 0, ''),
(7500289, 0, 0, 0, 1, 0, ''),
(7500290, 0, 0, 0, 4097, 69, ''),
(7500291, 0, 0, 0, 1, 0, ''),
(7500292, 0, 0, 0, 4097, 0, ''),
(7500294, 0, 0, 0, 1, 0, ''),
(7500295, 0, 0, 0, 1, 0, ''),
(7500296, 0, 0, 0, 1, 0, ''),
(7500297, 0, 0, 0, 1, 0, ''),
(7500298, 0, 0, 0, 1, 0, ''),
(7500299, 0, 0, 0, 1, 0, ''),
(7500300, 0, 0, 0, 1, 0, ''),
(7500301, 0, 0, 0, 1, 0, ''),
(7500302, 0, 0, 0, 1, 0, ''),
(7500303, 0, 0, 0, 1, 0, ''),
(7500304, 0, 0, 0, 1, 0, ''),
(7500305, 0, 0, 0, 1, 0, ''),
(7500306, 0, 0, 7, 0, 65, ''),
(7500307, 0, 0, 7, 0, 65, ''),
(7500308, 0, 0, 7, 0, 65, ''),
(7500309, 0, 0, 7, 0, 65, ''),
(7500310, 0, 0, 1, 0, 0, ''),
(7500311, 0, 0, 1, 4097, 0, ''),
(7500312, 0, 0, 1, 4097, 69, ''),
(7500313, 0, 0, 1, 4097, 69, ''),
(7500314, 0, 0, 1, 4097, 69, ''),
(7500315, 0, 0, 0, 1, 0, ''),
(7500316, 0, 0, 33554432, 0, 0, ''),
(7500317, 0, 0, 0, 1, 0, ''),
(7500318, 0, 0, 0, 1, 0, ''),
(7500319, 0, 0, 0, 1, 0, ''),
(7500320, 0, 0, 0, 1, 0, ''),
(7500321, 0, 0, 0, 1, 0, ''),
(7500322, 0, 0, 0, 1, 0, ''),
(7500323, 0, 0, 0, 1, 0, ''),
(7500324, 0, 0, 0, 1, 0, ''),
(7500325, 0, 0, 0, 1, 0, ''),
(7500326, 0, 0, 0, 1, 0, ''),
(7500327, 0, 0, 0, 1, 0, ''),
(7500328, 0, 0, 0, 1, 0, ''),
(7500329, 0, 0, 0, 1, 0, ''),
(7500330, 0, 0, 0, 1, 0, ''),
(7500331, 0, 0, 0, 1, 0, ''),
(7500332, 0, 0, 0, 1, 0, ''),
(7500333, 0, 0, 0, 1, 0, ''),
(7500334, 0, 0, 0, 1, 0, ''),
(7500335, 0, 0, 0, 1, 0, ''),
(7500336, 0, 0, 0, 1, 0, ''),
(7500337, 0, 0, 0, 1, 0, ''),
(7500338, 0, 0, 0, 1, 0, ''),
(7500339, 0, 0, 0, 1, 0, ''),
(7500340, 0, 0, 0, 1, 0, ''),
(7500341, 0, 0, 0, 1, 0, ''),
(7500342, 0, 0, 0, 1, 0, ''),
(7500343, 0, 0, 0, 1, 0, ''),
(7500345, 0, 0, 0, 1, 0, ''),
(7500346, 0, 0, 0, 1, 0, ''),
(7500347, 0, 0, 0, 1, 0, ''),
(7500348, 0, 0, 0, 1, 0, ''),
(7500349, 0, 0, 0, 1, 672, ''),
(7500350, 0, 0, 0, 1, 0, ''),
(7500351, 0, 0, 0, 1, 0, ''),
(7500352, 0, 0, 0, 1, 0, ''),
(7500353, 0, 0, 0, 1, 234, ''),
(7500355, 0, 0, 0, 1, 234, ''),
(7500356, 0, 0, 0, 1, 234, ''),
(7500357, 0, 0, 0, 1, 234, ''),
(7500358, 0, 0, 0, 1, 234, ''),
(7500359, 0, 0, 0, 1, 234, ''),
(7500361, 0, 0, 0, 1, 234, ''),
(7500362, 0, 0, 0, 1, 234, ''),
(7500363, 0, 0, 0, 1, 234, ''),
(7500369, 0, 0, 0, 1, 0, ''),
(7500372, 0, 0, 7, 1, 0, '');
DELETE FROM `waypoint_data` WHERE `id` IN (7500364, 7500364, 7500364, 7500364, 7500364, 7500364, 7500364, 7500364, 7500364);

INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(7500364, 1, -8618.710, -152.760, 86.400, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 2, -8615.670, -155.440, 86.060, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 3, -8614.180, -163.050, 85.840, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 4, -8612.120, -160.070, 85.920, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 5, -8613.360, -148.520, 86.900, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 6, -8616.380, -140.700, 87.510, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 7, -8619.450, -139.290, 86.710, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 8, -8619.930, -141.620, 86.760, NULL, 0, 0, 0, 0, 0, 100, 0),
(7500364, 9, -8618.730, -152.590, 86.430, NULL, 0, 0, 0, 0, 0, 100, 0);

COMMIT;

START TRANSACTION;

-- gameobject_template
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1617, 3, 270, 'Silverleaf', '', '', '', 0.60, 29, 1414, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1618, 3, 269, 'Peacebloom', '', '', '', 0.50, 29, 1415, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1731, 3, 310, 'Copper Vein', '', '', '', 0.50, 38, 1502, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1940, 8, 192, 'Campfire', '', '', '', 1.00, 4, 10, 2061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_flames', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2061, 6, 299, 'Campfire', '', '', '', 1.00, 0, 1, 2, 7897, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2843, 3, 259, 'Battered Chest', '', '', '', 1.00, 57, 2265, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (21007, 8, 192, 'Campfire', '', '', '', 1.00, 4, 10, 2061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_flames', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (21008, 8, 192, 'Campfire', '', '', '', 1.00, 4, 10, 2061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_flames', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (21009, 8, 192, 'Campfire', '', '', '', 1.00, 4, 10, 2061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_flames', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (22773, 8, 199, 'Cozy Fire', '', '', '', 1.30, 4, 8, 2061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_flames', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90214, 3, 1017819, 'Wax Stained Bag', '', 'Looting', '', 0.60, 1689, 90214, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90215, 3, 357, 'Old Grave ', '', 'Looting', '', 1.00, 1689, 90215, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90216, 3, 1021882, 'Defias Special Bucket', '', 'Looting', '', 0.80, 1689, 90216, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90217, 3, 1034276, 'Alliance Gem of Fortitude', '', 'Looting', '', 0.80, 1689, 90217, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90633, 5, 1015420, 'Table Prop', '', 'Looting', '', 0.60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90634, 3, 980926, 'Brother''s Cherry Pie', '', 'Looting', '', 1.00, 1689, 90634, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90635, 5, 5493, 'Cherry Pie prop', '', 'Looting', '', 3.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90636, 3, 7679, 'Forgotten Sack', '', 'Looting', '', 0.65, 1689, 90636, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (90637, 3, 1033132, 'Eagan''s Water Pouch', '', 'Looting', '', 1.00, 1689, 90637, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES (90637, 159, 0, 100, 0, 1, 0, 1, 5, 'AscensionWorldforged:placeholder loot for 90637 (Eagan\'s Water Pouch)');
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (95602, 3, 515102, 'Worn Shovel', '', 'Looting', '', 1.00, 1689, 95602, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (95613, 3, 10, 'Waterlogged Chest', '', 'Looting', '', 1.00, 1689, 95613, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (95670, 3, 1010931, 'Apprentice Staff', '', 'Looting', '', 1.00, 1689, 95670, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (95953, 5, 4451, 'Skeleton RPG Prop', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (96383, 5, 7736, 'Armor Stand', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (98007, 5, 6151, 'Elwynn Fence RPG Prop', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (142075, 19, 1907, 'Mailbox', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151953, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151954, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151955, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151956, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151957, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151958, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151959, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151960, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151961, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151962, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151963, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151964, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151965, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151966, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151967, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151968, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151969, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151970, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151971, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (151972, 7, 603, 'Wooden Bench', '', '', '', 1.00, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (161557, 3, 3012, 'Milly''s Harvest', '', '', '', 1.00, 43, 10119, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (174849, 0, 3471, '', '', '', '', 0.66, 0, 0, 3000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (175761, 9, 559, 'Civil War in the Plaguelands', '', '', '', 1.00, 2097, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (176573, 5, 3972, 'Alliance Bell', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_bells', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (178646, 5, 336, 'Alliance Supply Crate', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (191541, 8, 8109, 'Alchemy Lab', '', '', '', 1.00, 663, 10, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (244614, 3, 170000, 'Elwynn Tree', 'AxeCursor', 'Collecting', '', 1.00, 1876, 244614, 0, 1, 1, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (250002, 5, 334, 'Barrel of Milk', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (271911, 8, 216, 'Bubbling Cauldron', '', '', '', 0.75, 4, 10, 2061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (515417, 5, 39, 'Wooden Chair, no sit', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (520063, 3, 515676, 'Scorched Tome', '', 'Looting', '', 1.00, 1689, 520063, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (520064, 3, 526821, 'Old Northshire Bolter', '', 'Looting', '', 1.00, 1689, 520064, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (520065, 3, 20, 'Disturbed Dirt', '', 'Looting', '', 1.00, 1689, 520065, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (520066, 3, 515677, 'Murloc Tool', '', 'Looting', '', 1.00, 1689, 520066, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (800054, 6, 5671, 'Lamp Post', '', '', '', 1.00, 0, -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (911649, 5, 621, 'Eye of Rokan', '', '', '', 0.50, 0, 0, 2, 57573, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1600928, 5, 515535, '', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1600933, 5, 515534, '', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1600935, 5, 515536, '', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (1600940, 5, 88798, 'RPG Fence Post', '', '', '', 1.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300136, 5, 300132, 'Beer Mug', '', '', '', 0.50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300328, 5, 300325, 'Ascension_Collision_Npc_Cylinder', '', '', '', 2.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300500, 3, 300450, 'Lost Page I', '', '', '', 1.00, 1689, 2300500, 0, 0, 0, 0, 0, 0, 1660001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300501, 0, 300449, 'Dungeon Door', '', '', '', 1.00, 0, 0, 5000, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300503, 3, 300450, 'Lost Page II', '', '', '', 1.00, 1689, 2300503, 0, 0, 0, 0, 0, 0, 1660001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300504, 3, 300450, 'Lost Page III', '', '', '', 1.00, 1689, 2300504, 0, 0, 0, 0, 0, 0, 1660001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300505, 3, 300450, 'Lost Page IV', '', '', '', 1.00, 1689, 2300505, 0, 0, 0, 0, 0, 0, 1660001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300516, 3, 300450, 'Lost Page V', '', '', '', 1.00, 1689, 2300516, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300517, 3, 300450, 'Lost Page VI', '', '', '', 1.00, 1689, 2300517, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300520, 10, 1029136, 'Abbess'' Journal', '', '', '', 1.00, 0, 1660003, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300521, 10, 87111, 'Abbess''s Staff', '', '', '', 1.25, 0, 1660003, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300522, 10, 63523, 'Heretical Idol Purified', '', '', '', 1.50, 0, 1660003, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300523, 10, 7075, 'Jewel', '', '', '', 0.75, 0, 1660003, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300565, 31, 8196, 'Doodad_InstanceNewPortal_Purple01', '', '', '', 1.75, 936, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300566, 31, 8197, 'Doodad_InstanceNewPortal_Purple_Skull01', '', '', '', 1.75, 936, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300567, 31, 9040, 'Doodad_InstancePortal_Green_5Man_Mythic01', '', '', '', 1.50, 936, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (2300568, 23, 5492, 'Meeting Stone', '', '', '', 1.00, 23, 255, 10218, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340);

COMMIT;

-- creature_display_preset

START TRANSACTION;

REPLACE INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
  (537, 50, 1, 1, 8, 4, 0, 3, 9, 8, 0, 144944, 0, 0, 148561, 150152, 152077, 154288, 0, 0, 0, 0),
  (50280, 49, 1, 0, 1, 7, 1, 3, 0, 4, 0, 0, 145915, 138411, 149422, 0, 37009, 13324, 0, 0, 0, 0),
  (50282, 50, 1, 1, 1, 2, 4, 10, 14, 8, 0, 0, 0, 0, 12071, 151314, 166767, 154609, 84312, 157159, 0, 0),
  (50283, 49, 1, 0, 1, 4, 3, 8, 8, 10, 0, 0, 0, 67226, 149163, 15579, 154171, 155076, 0, 0, 63924, 0),
  (50286, 50, 1, 1, 1, 3, 5, 22, 5, 3, 0, 74274, 0, 149739, 23107, 0, 0, 155314, 0, 0, 17892, 0),
  (50287, 49, 1, 0, 1, 3, 4, 2, 20, 7, 0, 15161, 0, 148002, 0, 0, 39568, 13515, 0, 0, 0, 0),
  (50289, 49, 1, 0, 1, 0, 0, 16, 9, 8, 0, 0, 140605, 163727, 22923, 0, 16880, 22865, 0, 22922, 0, 0),
  (50291, 50, 1, 1, 1, 4, 14, 0, 0, 8, 0, 0, 9414, 147621, 149570, 22571, 143962, 36709, 0, 157800, 0, 0),
  (50292, 50, 1, 1, 1, 7, 1, 9, 14, 8, 0, 0, 140607, 166060, 147558, 6715, 143938, 7227, 106371, 166082, 0, 0),
  (50295, 50, 1, 1, 1, 6, 5, 12, 18, 3, 0, 0, 0, 72081, 148802, 151123, 14507, 166065, 7474, 0, 0, 0),
  (50324, 49, 1, 0, 1, 1, 4, 1, 6, 5, 0, 21669, 146008, 45677, 148532, 11451, 20301, 17625, 0, 0, 0, 0),
  (50325, 49, 1, 0, 1, 5, 1, 0, 0, 4, 0, 13513, 0, 16820, 13226, 6715, 7462, 12649, 0, 0, 74277, 0),
  (50340, 49, 1, 0, 1, 6, 6, 10, 16, 1, 0, 0, 140622, 147830, 11322, 0, 153400, 156060, 6982, 156876, 0, 0),
  (161700, 50, 1, 1, 1, 1, 3, 7, 0, 3, 0, 0, 0, 10037, 13122, 13062, 13059, 1246, 0, 0, 0, 0),
  (161701, 49, 1, 0, 1, 0, 3, 4, 0, 5, 0, 0, 0, 0, 9673, 0, 0, 13198, 0, 0, 0, 0),
  (161702, 50, 1, 1, 1, 1, 12, 2, 4, 4, 0, 11960, 7085, 0, 14466, 17569, 0, 155740, 79567, 0, 0, 0),
  (161705, 49, 1, 0, 1, 3, 4, 5, 1, 4, 0, 0, 145998, 0, 148064, 150436, 4630, 154610, 0, 157061, 0, 16657),
  (161713, 49, 1, 0, 1, 4, 3, 3, 8, 2, 0, 11995, 10841, 7947, 148618, 11340, 0, 133652, 0, 20335, 0, 0),
  (161844, 49, 1, 0, 1, 3, 3, 3, 9, 3, 0, 11995, 11365, 0, 9657, 13132, 0, 155314, 0, 0, 0, 0),
  (161857, 49, 1, 0, 1, 9, 9, 9, 9, 9, 0, 0, 21024, 148383, 24528, 0, 21021, 21064, 0, 21065, 0, 0),
  (501266, 49, 1, 0, 6, 12, 1, 11, 13, 8, 0, 0, 169327, 148037, 9, 12, 13, 14, 0, 11, 0, 0),
  (502770, 50, 1, 1, 1, 4, 3, 14, 4, 4, 0, 0, 140617, 147553, 30340, 6684, 153959, 61815, 0, 0, 0, 0),
  (502923, 49, 1, 0, 1, 0, 10, 11, 0, 4, 0, 0, 10563, 0, 16459, 0, 0, 58479, 0, 157495, 22851, 0),
  (502960, 50, 1, 1, 1, 7, 5, 21, 18, 8, 0, 0, 0, 72079, 164915, 13254, 152499, 71189, 0, 0, 0, 0),
  (503410, 49, 1, 0, 1, 2, 3, 5, 8, 1, 0, 0, 0, 0, 143957, 6715, 143956, 10676, 144333, 13397, 0, 0),
  (10157356, 49, 1, 0, 1, 0, 8, 5, 5, 6, 0, 74302, 142354, 0, 144748, 144800, 142353, 142350, 0, 142352, 74303, 0);

-- creature_model_info / creaturedisplayinfo_dbc
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (49, 49, 0, 0, 1.0, 255);
INSERT IGNORE INTO `creaturedisplayinfo_dbc` (`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`) VALUES (50, 49, 0, 0, 1.0, 255);

COMMIT;

-- npc_vendor

START TRANSACTION;

COMMIT;

START TRANSACTION;

-- npc_text

-- gossip_menu / gossip_menu_option

-- creature_template

COMMIT;

-- item_template

-- creature_template
UPDATE `creature_template` SET `faction` = 14 WHERE `entry` = 537;
UPDATE `creature_template` SET `faction` = 16 WHERE `entry` IN (161713, 161717, 161736);
UPDATE `creature_template` SET `faction` = 32 WHERE `entry` IN (161716);
UPDATE `creature_template` SET `faction` = 35 WHERE `entry` IN (399223, 161710, 200200, 161841, 161842);

-- gameobject_template
UPDATE `gameobject_template` SET `ScriptName` = 'worldforged_pickup' WHERE `entry` = 95603;

SET `FOREIGN_KEY_CHECKS` = 1;

-- ========================= custom_emote_marks =========================
-- NPCs from northshire_full_apply_fixed_animations.sql that set an emote or stand animation, plus how they were applied:
--   custom   = custom NPC kept by the normal filter (emote set)
--   imported = stock NPC imported as a new spawn (emote rule)
--   attached = animation applied to the existing stock spawn (guid = core guid)
CREATE TABLE IF NOT EXISTS `custom_emote_marks` (
  `guid` int NOT NULL,
  `src_guid` int NOT NULL,
  `entry` int NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT '',
  `emote` int NOT NULL DEFAULT 0,
  `stand_state` int NOT NULL DEFAULT 0,
  `mode` enum('custom','imported','attached') NOT NULL,
  `source` varchar(96) NOT NULL DEFAULT '',
  `marked_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  KEY `idx_entry` (`entry`),
  KEY `idx_mode` (`mode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `custom_emote_marks` WHERE `source` = 'northshire_full_apply_fixed_animations.sql';
INSERT INTO `custom_emote_marks` (`guid`, `src_guid`, `entry`, `name`, `emote`, `stand_state`, `mode`, `source`) VALUES
(7500099, 7500099, 257, 'Kobold Worker', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500101, 7500101, 257, 'Kobold Worker', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500104, 7500104, 257, 'Kobold Worker', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500153, 7500153, 299, 'Young Wolf', 0, 1, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500172, 7500172, 299, 'Young Wolf', 0, 1, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500174, 7500174, 299, 'Young Wolf', 0, 1, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500194, 7500194, 69, 'Timber Wolf', 0, 1, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500221, 7500221, 69, 'Timber Wolf', 0, 1, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(80262, 7500222, 11260, 'Northshire Peasant', 234, 0, 'attached', 'northshire_full_apply_fixed_animations.sql'),
(80145, 7500224, 11260, 'Northshire Peasant', 234, 0, 'attached', 'northshire_full_apply_fixed_animations.sql'),
(80119, 7500226, 11260, 'Northshire Peasant', 234, 0, 'attached', 'northshire_full_apply_fixed_animations.sql'),
(80127, 7500227, 11260, 'Northshire Peasant', 234, 0, 'attached', 'northshire_full_apply_fixed_animations.sql'),
(79950, 7500258, 152, 'Brother Danil', 69, 0, 'attached', 'northshire_full_apply_fixed_animations.sql'),
(7500259, 7500259, 502960, 'Doctor Yara', 133, 0, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500263, 7500263, 38, 'Defias Thug', 0, 3, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(80188, 7500271, 38, 'Defias Thug', 69, 0, 'attached', 'northshire_full_apply_fixed_animations.sql'),
(7500273, 7500273, 38, 'Defias Thug', 69, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500279, 7500279, 537, 'Defias Trainee', 0, 8, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500285, 7500285, 537, 'Defias Trainee', 0, 3, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500290, 7500290, 537, 'Defias Trainee', 69, 0, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500306, 7500306, 161841, 'Shadewell Murloc Forager', 65, 7, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500307, 7500307, 161841, 'Shadewell Murloc Forager', 65, 7, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500308, 7500308, 161841, 'Shadewell Murloc Forager', 65, 7, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500309, 7500309, 161842, 'Defias Plunderer', 65, 7, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500310, 7500310, 161736, 'Defias Plunderer', 0, 1, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500311, 7500311, 161736, 'Defias Plunderer', 0, 1, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500312, 7500312, 161736, 'Defias Plunderer', 69, 1, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500313, 7500313, 161736, 'Defias Plunderer', 69, 1, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500314, 7500314, 161736, 'Defias Plunderer', 69, 1, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500349, 7500349, 161858, 'Echo of the Abbess', 672, 0, 'custom', 'northshire_full_apply_fixed_animations.sql'),
(7500353, 7500353, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500355, 7500355, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500356, 7500356, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500357, 7500357, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500358, 7500358, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500359, 7500359, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500361, 7500361, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500362, 7500362, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500363, 7500363, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500364, 7500364, 80, 'Kobold Laborer', 234, 0, 'imported', 'northshire_full_apply_fixed_animations.sql'),
(7500372, 7500372, 399223, 'Zipi', 0, 7, 'custom', 'northshire_full_apply_fixed_animations.sql');

-- ##########################################################################################
-- SECTION 5 - missing Spada entities
-- ##########################################################################################

-- ==========================================================================================
-- Missing Spada / Northshire entities - recovered from the 2026-09-16 world backup
-- Source: the 2026-09-16 pre-rebuild world dump (517 MB; a second copy of it is identical
-- for these rows). All rows below existed there and the
-- current acore_world is missing them (checked 2026-09-28).
--
-- CONTENTS:
--   1. creature_template         ten templates: the six invisible credit markers, the
--                                kharanos trigger and the three Goldshire NPCs
--   2. creature_template_model   model rows for the same ten entries
--   3. creature_model_info       custom display support for 652000-652003, 652079,
--                                652354, 652414, 652415
--   4. creaturedisplayinfo_dbc   the same eight displays mapped to the plain human displays
--                                (50 -> extra 13750, 49 -> extra 13749)
--   5. ghost visuals             translucent display copies (opacity only) for Sister Alma
--                                161702 (75%) and the echoes 161857/161858/161895/161897 (50%),
--                                the 'Ghost' aura 8326 on their addon rows, and hover movement
--                                rows (they never drop; 2 yd lift for the echoes, Alma keeps
--                                her already-airborne spawn position)
--
-- NOTES
--   * The six markers (161703/161704/161714/161824/161825/161826) and 162920 are invisible
--     credit/trigger creatures (display 11686 InvisibleStalker, faction 35). Their old names
--     are placeholders ('[KC] <entry>' / '[TG] kharanos hops'); the true live names were never
--     captured - only 161715 '[KC] Purify Relics' has its real name. They are what the
--     objectives of 1660002 / 1660003 / 1660004 / 1660057 need in order to complete.
--   * 162800 Dulcinea, 162802 Aldia Crayon, 162803 Lady Agria Spada are the Goldshire / manor
--     NPCs of quests 1660055-1660057.
--   * The model rows use the live custom display ids (652354 / 652414 / 652415). The current
--     world instead dresses the Spada NPCs with plain displays 49/50 plus a
--     creature_display_preset row (see 161700-161705 in acore_world for the pattern) - switch
--     the model rows to 49/50 and add presets if that pipeline is preferred.
--   * Reference: the old DB's spawns (the current world already has these, do not re-add) -
--       161700 Bianca Spada   (-8920.50, -133.20, 80.70)
--       161701 Moroi Spada    (-8900.83, -197.95, 81.94)
--       161705 Injured Guard  (-8916.79, -130.36, 80.87)
--   * NOT INCLUDED - never recovered anywhere: spawn positions for the ten entries above,
--     any smart/script wiring, and creature_queststarter/ender rows (the old DB's link rows
--     are blanket placeholders - Moroi starts and ends almost everything, contradicting the
--     quest texts - do not copy them; assign links in game).
--
-- Safe to re-import: creature_template rows are upserts, the other three tables are
-- delete-and-reinsert per id. UTF-8 file.
-- ==========================================================================================

-- 1. creature_template ----------------------------------------------------------------------

-- 161703 credit marker for 1660004 'Hidden Path found'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161703,0,0,0,0,0,'[KC] 161703','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 161704 credit marker for 1660004 'Ruined Estate discovered'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161704,0,0,0,0,0,'[KC] 161704','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 161714 credit marker for 1660002 'dungeon entrance found'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161714,0,0,0,0,0,'[KC] 161714','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 161824 credit marker for 1660003 'Abbess's Staff Purified'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161824,0,0,0,0,0,'[KC] 161824','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 161825 credit marker for 1660003 'Heretical Idol Purified'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161825,0,0,0,0,0,'[KC] 161825','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 161826 credit marker for 1660003 'Jewel Purified'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161826,0,0,0,0,0,'[KC] 161826','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 162800 Dulcinea - 1660055 ender / 1660056 giver (Goldshire)
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(162800,0,0,0,0,0,'Dulcinea','Maid of House Spada',NULL,0,8,8,0,12,3,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,768,2048,0,0,7,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,0,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 162802 Aldia Crayon - 1660056 ender / 1660057 giver/ender (manor)
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(162802,0,0,0,0,0,'Aldia Crayon','Majordomo',NULL,0,8,8,0,12,3,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,768,2048,0,0,7,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,0,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 162803 Lady Agria Spada - manor NPC (the patient)
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(162803,0,0,0,0,0,'Lady Agria Spada','',NULL,0,8,8,0,12,3,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,768,2048,0,0,7,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,0,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 162920 credit marker for 1660057 'Mirror Shard Inspected'
INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(162920,0,0,0,0,0,'[TG] kharanos hops','',NULL,0,1,1,0,35,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,33555200,2048,0,0,10,0,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,130,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 2. creature_template_model -----------------------------------------------------------------

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161703, 161704, 161714, 161824, 161825, 161826, 162800, 162802, 162803, 162920);

INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
(161703,0,11686,1,1,NULL),
(161704,0,11686,1,1,NULL),
(161714,0,11686,1,1,NULL),
(161824,0,11686,1,1,NULL),
(161825,0,11686,1,1,NULL),
(161826,0,11686,1,1,NULL),
(162800,0,652354,1,1,NULL),
(162802,0,652414,1,1,NULL),
(162803,0,652415,1,1,NULL),
(162920,0,11686,1,1,NULL);

-- 3. creature_model_info ---------------------------------------------------------------------

DELETE FROM `creature_model_info` WHERE `DisplayID` IN (652000, 652001, 652002, 652003, 652079, 652354, 652414, 652415);

INSERT INTO `creature_model_info`
(`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`)
VALUES
(652000,0.306,1.5,1,0,NULL),
(652001,0.306,1.5,0,0,NULL),
(652002,0.306,1.5,1,0,NULL),
(652003,0.306,1.5,0,0,NULL),
(652079,0.306,1.5,0,0,NULL),
(652354,0.306,1.5,1,0,NULL),
(652414,0.306,1.5,0,0,NULL),
(652415,0.306,1.5,1,0,NULL);

-- 4. creaturedisplayinfo_dbc -----------------------------------------------------------------

DELETE FROM `creaturedisplayinfo_dbc` WHERE `ID` IN (652000, 652001, 652002, 652003, 652079, 652354, 652414, 652415);

INSERT INTO `creaturedisplayinfo_dbc`
(`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`, `TextureVariation_1`, `TextureVariation_2`, `TextureVariation_3`, `PortraitTextureName`, `BloodLevel`, `BloodID`, `NPCSoundID`, `ParticleColorID`, `CreatureGeosetData`, `ObjectEffectPackageID`)
VALUES
(652000,50,0,13750,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652001,49,0,13749,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652002,50,0,13750,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652003,50,0,13750,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652079,49,0,13749,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652354,50,0,13750,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652414,50,0,13750,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652415,50,0,13750,1,255,NULL,NULL,NULL,NULL,1,0,0,0,0,0);

-- 5. ghost visuals - Sister Alma 161702 + the Inquisitorial echoes 161857/161858/161895/161897 --
-- OPACITY ONLY: each NPC keeps the display it had - the copies below carry the exact model,
-- extra, scale and sounds of that display, with only CreatureModelAlpha changed. Custom ids
-- are required because CreatureModelAlpha lives in the display record and the source displays
-- are stock (shared, client-side). The patch streamer sends every id >= 652000 at client login.
--
--   entry   from display  copy    alpha      the display it copies
--   161702  3227          652005  191 (75%)  'Wandering Spirit' ghost display
--   161857  49            652006  128 (50%)  plain HumanMale (his preset dresses him)
--   161858  139062        652007  128 (50%)  'Echo of the Abbess' custom display
--   161895  5548          652008  128 (50%)  Bishop Farthing display (robed judge look)
--   161897  1501          652009  128 (50%)  Brother Cassius display (robed judge look)
--
-- The model row and the (entry, display_id) preset row must move together - the mirror-image
-- appearance path answers with the unit's display id, and its first-row preset fallback must
-- not disagree. Presets: 161702 and 161857 have one (values carried verbatim, only the
-- display id moved); the other three render straight from their display copy.
--
-- AURA: 'Ghost' 8326 (SPELL_AURA_GHOST 95) on each spawn addon (a spawn-level creature_addon
-- replaces the template addon entirely) and template addon. Harmless on creatures: the aura
-- handler is player-gated, so it is a no-op server-side. Remove with auras = '' updates.
--
-- Re-import note: the Northshire dump (northshire_custom_only.sql) carries the original
-- display rows for these entries - re-apply this section after any re-import.

DELETE FROM `creaturedisplayinfo_dbc` WHERE `ID` IN (652005, 652006, 652007, 652008, 652009);

INSERT INTO `creaturedisplayinfo_dbc`
(`ID`, `ModelID`, `SoundID`, `ExtendedDisplayInfoID`, `CreatureModelScale`, `CreatureModelAlpha`, `TextureVariation_1`, `TextureVariation_2`, `TextureVariation_3`, `PortraitTextureName`, `BloodLevel`, `BloodID`, `NPCSoundID`, `ParticleColorID`, `CreatureGeosetData`, `ObjectEffectPackageID`)
VALUES
(652005,50,0,1475,1,191,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652006,49,0,0,1,128,NULL,NULL,NULL,NULL,1,0,0,0,0,0),
(652007,49,0,0,1,128,NULL,NULL,NULL,NULL,0,0,0,0,0,0),
(652008,49,0,3694,1,128,NULL,NULL,NULL,NULL,1,0,49,0,0,0),
(652009,49,0,221,1,128,NULL,NULL,NULL,NULL,1,0,48,0,0,0);

DELETE FROM `creature_model_info` WHERE `DisplayID` IN (652005, 652006, 652007, 652008, 652009);

INSERT INTO `creature_model_info`
(`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`)
VALUES
(652005,0.208,1.5,1,0,NULL),
(652006,0.306,1.5,0,0,NULL),
(652007,0.38,1.5,2,0,NULL),
(652008,0.306,1.5,0,0,NULL),
(652009,0.306,1.5,0,0,NULL);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161702, 161857, 161858, 161895, 161897);

INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
(161702,0,652005,1,1,NULL),
(161857,0,652006,1,1,NULL),
(161858,0,652007,1,1,NULL),
(161895,0,652008,1,1,NULL),
(161897,0,652009,1,1,NULL);

DELETE FROM `creature_display_preset` WHERE `entry` IN (161702, 161857);

INSERT INTO `creature_display_preset`
(`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(161702,652005,1,1,1,1,12,2,4,4,0,11960,7085,0,14466,17569,0,155740,79567,0,0,0),
(161857,652006,1,0,1,9,9,9,9,9,0,0,21024,148383,24528,0,21021,21064,0,21065,0,0);

UPDATE `creature_addon` SET `auras` = '8326' WHERE `guid` IN (7500316, 7500350, 7500349, 7500336, 7500338);

UPDATE `creature_template_addon` SET `auras` = '8326' WHERE `entry` IN (161702, 161857, 161858, 161895, 161897);

-- HOVER: the five ghosts hover and never drop - Ground=2 (Hover) keeps MOVEMENTFLAG_HOVER on
-- them (the client stops pulling them down), Flight=1 (DisableGravity) keeps them aloft if they
-- are ever knocked upward. HoverHeight: 2 yd of lift for the four ground-placed echoes; Alma
-- 161702 uses 0 because her spawn point is already up in the air - 0 means the engine never
-- relocates her, she stays at exactly the spawn z. Both flags are applied by
-- Creature::UpdateMovementFlags from this template.

DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (161702, 161857, 161858, 161895, 161897);

INSERT INTO `creature_template_movement`
(`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`)
VALUES
(161702,2,0,1,0,0,0,NULL),
(161857,2,0,1,0,0,0,NULL),
(161858,2,0,1,0,0,0,NULL),
(161895,2,0,1,0,0,0,NULL),
(161897,2,0,1,0,0,0,NULL);

UPDATE `creature_template` SET `HoverHeight` = 2 WHERE `entry` IN (161857, 161858, 161895, 161897);

UPDATE `creature_template` SET `HoverHeight` = 0 WHERE `entry` = 161702;

-- ##########################################################################################
-- SECTION 6 - wayward theologian encounter
-- ##########################################################################################

-- ==========================================================================================
-- Wayward Theologian (161713) encounter - complete import for the CoA world DB
-- Restored 2026-09-27 from live-service observations (MobSpells capture, creature caches)
-- and the encounter flow supplied by the client owner.
--
-- CONTENTS (in load order):
--   1. creature_template rows     - 161904 summon template, 161908/161909 portal templates
--   2. creature_template values   - captured stats, unit_class, faction 17, portal interact flag, SmartAI
--   3. appearance                 - model rows and display presets for all four entries
--   4. spawn                      - the boss placement (guid 9000133, delete-and-reinsert) plus
--                                   the removal of the northshire layer's duplicate 7500369
--   5. npc_spellclick_spells      - the portal click carrier (spell 12980)
--   6. smart_scripts + conditions - the whole encounter AI (161713, 161904, 161908, 161909)
--   7. creature_text              - the boss's three lines (aggro, +4 s, on death)
--
-- Safe to re-import: script rows and the spawn are delete-and-reinsert, template values are
-- updates and the other three template rows are upserts. 161713's base creature_template row is expected
-- to exist already (it ships with the CoA world DB); the other three entries are created
-- here.
--
-- ENCOUNTER BEHAVIOUR
--   * he opens the fight with two spoken lines: line 0 the moment combat starts and line 1
--     after 4 seconds of combat (one-shot rows whose timers pause out of combat, so a wipe
--     re-arms them); the third line is his dying line and plays when he dies
--   * Shadow Bolt every 2 seconds while able to cast
--   * Shadowfury 5 seconds after combat starts, then every 15 seconds
--   * at 70% and again at 25% health the boss winds up with Dark Reality (256762, a 4 s
--     self-cast): when it lands, Shadow Shield (256763) goes up and every spawn hangs off
--     that moment through the link rows - three 161904 summons, then the two portal units
--     161908/161909 - so the whole set appears the moment the shield lands. The cast gates
--     both phases: if it cannot start the row retries; a mid-cast interrupt means that
--     wave does not spawn
--   * the three 161904 summons of each wave drop to the wave's percentage right after they
--     spawn (70% / 25%): a linked SET_HEALTH_PCT row targets every living 161904 within 60
--     yards once the third summon is out, so the adds look as wounded as the boss does when
--     they appear instead of arriving at full health
--   * the shield and the portals clear when no summoned unit remains alive; the check runs
--     every second, so the drop can trail the last kill (the portals clear through the
--     link rows)
--   * any end of the fight clears every spawned unit: the On Evade, On Reset and On Death
--     chains each despawn the two portals and the 161904 summons
--   * while Shadow Shield is up 161713 casts nothing (a negative Shield condition sits on
--     the three cast rows) and stops meleeing and moving; everything returns when the
--     shield drops or on reset
--   * the summoned 161904 units engage the closest player, never move in combat and cast
--     256738 Shadow Bolt on a 5 s loop matching the captured ~5.1 s chain-cast
--   * the portals cast 256761 "Portal" when they come into the world - that aura is their
--     only visible output, the unit model itself is an invisible stalker - and clicking
--     one teleports the clicker to the platform above; the click chain then tells the boss
--     and the living summons to re-engage, because the engine stops the player's combat on
--     same-map teleports (Player::TeleportTo sends CombatStop unless the caller opts out)
--   * the summon positions were taken from the placed spawns 9000145-9000149; the spawn
--     objects themselves were removed - the units are script-only summons
--   * the encounter leashes at about 40 yards: row 46 evades once the aggro holder is
--     farther than that - event distance 35 plus the 5-yard nominal melee reach, plus up
--     to 2.66 yards of running leeway while both the holder and the boss are moving. The
--     invert slot repeats 35 because the row loader validates distance <= invert and would
--     reject 35/1 ("uses min/max params wrong"). The evade is a normal one, so the On
--     Evade / On Reset chains clear the summons, the portals and the shield
-- ==========================================================================================

-- 1. creature_template rows -----------------------------------------------------------------

-- 161904: the shield guardians 161713 summons (three per phase). type, unit_flags and
-- flags_extra are pinned to the values the encounter was authored with: the realm's port
-- of this content ships type 7 and flags_extra 64 on the row.
INSERT INTO `creature_template`
  (`entry`, `name`, `minlevel`, `maxlevel`, `type`, `unit_flags`, `flags_extra`)
VALUES
  (161904, 'Wayward Theologian', 5, 5, 0, 0, 0)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `type` = VALUES(`type`), `unit_flags` = VALUES(`unit_flags`), `flags_extra` = VALUES(`flags_extra`);

-- 161908/161909: the portal units. Display 11686 is CreatureDisplayInfo 11686 ->
-- model 1731 Creature\InvisibleStalker\InvisibleStalker.mdx (invisible); type 9 is the
-- live value and the "Interact" icon name comes from the live creature cache. unit_flags
-- and flags_extra are pinned clear: without that the realm's port leaves the portals
-- NOT_SELECTABLE (unit_flags 33555202) and they can never be clicked for the teleport.
INSERT INTO `creature_template`
  (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `IconName`, `type`, `unit_flags`, `flags_extra`)
VALUES
  (161908, 'Wayward Theologian', 5, 5, 35, 'Interact', 9, 0, 0),
  (161909, 'Wayward Theologian', 5, 5, 35, 'Interact', 9, 0, 0)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `faction` = VALUES(`faction`), `IconName` = VALUES(`IconName`), `type` = VALUES(`type`),
  `unit_flags` = VALUES(`unit_flags`), `flags_extra` = VALUES(`flags_extra`);

-- 2. creature_template values ---------------------------------------------------------------

-- Captured stats (Vol'jin cache, 2026-09-11): 161713 is an elite with a 5.76 health
-- modifier, 161904 an elite with the default modifier. Levels were not captured.
UPDATE `creature_template` SET `HealthModifier` = 5.76, `rank` = 1 WHERE `entry` = 161713;
UPDATE `creature_template` SET `rank` = 1, `unit_class` = 1 WHERE `entry` = 161904;

-- unit_class 1 on the three created entries: the core replaces an invalid 0 with 1 and logs
-- a load warning; setting it here silences that warning (161713 ships with a class already).
UPDATE `creature_template` SET `unit_class` = 1 WHERE `entry` IN (161908, 161909);

-- Faction 17 (Defias Brotherhood) for the fighting units; the portals keep faction 35 so
-- they never aggro anyone.
UPDATE `creature_template` SET `faction` = 17 WHERE `entry` IN (161713, 161904);

-- Spell-click flag on the portals: the client shows the interact cursor and sends the
-- click opcode. The flag is stripped at load without an npc_spellclick_spells row (see 5).
UPDATE `creature_template` SET `npcflag` = 16777216 WHERE `entry` IN (161908, 161909);

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (161713, 161904, 161908, 161909);

-- 3. appearance -----------------------------------------------------------------------------

-- Model rows: the Theologians point at plain character display 49 (dressed by the preset
-- below), the portals at the invisible stalker display.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161713, 161904, 161908, 161909);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(161713, 0, 49, 1, 1, NULL),
(161904, 0, 49, 1, 1, NULL),
(161908, 0, 11686, 1, 1, NULL),
(161909, 0, 11686, 1, 1, NULL);

-- Captured mirror-image appearance (2026-09-01 corpus): hair, skin and weapon/armour look.
REPLACE INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(161713, 49, 1, 0, 1, 4, 3, 3, 8, 2, 0, 11995, 10841, 7947, 148618, 11340, 0, 133652, 0, 20335, 0, 0),
(161904, 49, 1, 0, 1, 4, 3, 3, 8, 2, 0, 11995, 10841, 7947, 148618, 11340, 0, 133652, 0, 20335, 0, 0);

-- 4. spawn ----------------------------------------------------------------------------------

DELETE FROM `creature_addon` WHERE `guid` = 7500369;

-- 5. npc_spellclick_spells ------------------------------------------------------------------

-- Carrier spell for the portal click. 12980 "Simple Teleport" is instant, has no effect
-- beyond its visual and is cast with flag 3 (caster and target both the clicker), so the
-- clicker gets a shimmer and the click itself never fails a range or target check.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` IN (161908, 161909);
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(161908, 12980, 3, 0),
(161909, 12980, 3, 0);

-- 6. smart_scripts --------------------------------------------------------------------------

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161713 AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`,
    `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`,
    `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
    `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
    `comment`) VALUES
(161713, 0, 0, 0, 0, 0, 100, 0, 0, 0, 2000, 2000, 0, 0, 11, 256737, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - In Combat - Cast Shadow Bolt'),
(161713, 0, 1, 0, 0, 0, 100, 0, 5000, 5000, 15000, 15000, 0, 0, 11, 256486, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - In Combat - Cast Shadowfury (5s after combat, then every 15s)'),
(161713, 0, 2, 0, 0, 0, 100, 0, 5000, 5000, 8000, 8000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - In Combat - Cast Fierce Blow'),
(161713, 0, 3, 39, 2, 0, 100, 1, 0, 70, 0, 0, 0, 0, 11, 256762, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - At 70% Health - Cast Dark Reality (once, 4 s wind-up)'),
(161713, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161904, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8613.93, -567.846, 149.652, 0, 'Wayward Theologian - On Link - Summon Wayward Theologian with the 70% Shadow Shield'),
(161713, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161904, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8597.88, -560.254, 150.81, 3.09548, 'Wayward Theologian - On Link - Summon Wayward Theologian with the 70% Shadow Shield'),
(161713, 0, 6, 37, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161904, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8600.11, -584.039, 150.322, 1.88637, 'Wayward Theologian - On Link - Summon Wayward Theologian with the 70% Shadow Shield'),
(161713, 0, 7, 41, 2, 0, 100, 1, 0, 25, 0, 0, 0, 0, 11, 256762, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - At 25% Health - Cast Dark Reality (once, 4 s wind-up)'),
(161713, 0, 8, 9, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161904, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8613.93, -567.846, 149.652, 0, 'Wayward Theologian - On Link - Summon Wayward Theologian with the 25% Shadow Shield'),
(161713, 0, 9, 10, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161904, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8597.88, -560.254, 150.81, 3.09548, 'Wayward Theologian - On Link - Summon Wayward Theologian with the 25% Shadow Shield'),
(161713, 0, 10, 38, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161904, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8600.11, -584.039, 150.322, 1.88637, 'Wayward Theologian - On Link - Summon Wayward Theologian with the 25% Shadow Shield'),
(161713, 0, 11, 17, 0, 0, 100, 0, 5000, 5000, 1000, 1000, 0, 0, 28, 256763, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - In Combat - Remove Shadow Shield when the summons are gone'),
(161713, 0, 12, 19, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 256763, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Reset - Remove Shadow Shield'),
(161713, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161908, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8611.97, -564.475, 145.008, 0, 'Wayward Theologian - On Link - Summon the 161908 portal with the 70% Shadow Shield'),
(161713, 0, 14, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161909, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8600.46, -558.379, 146.265, 0, 'Wayward Theologian - On Link - Summon the 161909 portal with the 70% Shadow Shield'),
(161713, 0, 15, 16, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161908, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8611.97, -564.475, 145.008, 0, 'Wayward Theologian - On Link - Summon the 161908 portal with the 25% Shadow Shield'),
(161713, 0, 16, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161909, 2, 600000, 0, 0, 0, 8, 0, 0, 0, 0, -8600.46, -558.379, 146.265, 0, 'Wayward Theologian - On Link - Summon the 161909 portal with the 25% Shadow Shield'),
(161713, 0, 17, 18, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161908, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161908 portal when the summons are gone'),
(161713, 0, 18, 25, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161909, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161909 portal when the summons are gone'),
(161713, 0, 19, 20, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161908, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161908 portal on reset'),
(161713, 0, 20, 27, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161909, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161909 portal on reset'),
(161713, 0, 21, 22, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Stop melee while Shadow Shield is up'),
(161713, 0, 22, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Stop moving while Shadow Shield is up'),
(161713, 0, 23, 24, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Stop melee while Shadow Shield is up (25% phase)'),
(161713, 0, 24, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Stop moving while Shadow Shield is up (25% phase)'),
(161713, 0, 25, 26, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 20, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Resume melee when the shield clears'),
(161713, 0, 26, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Resume movement when the shield clears'),
(161713, 0, 27, 28, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 20, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Resume melee on reset'),
(161713, 0, 28, 33, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Resume movement on reset'),
(161713, 0, 29, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 200, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Data Set 1 1 - Attack the closest player again after a portal teleport'),
(161713, 0, 30, 31, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161904, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Death - Clear the summoned units'),
(161713, 0, 31, 32, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161908, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161908 portal on death'),
(161713, 0, 32, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161909, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161909 portal on death'),
(161713, 0, 33, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161904, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the summoned units on reset'),
(161713, 0, 34, 35, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161904, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Evade - Clear the summoned units'),
(161713, 0, 35, 36, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161908, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161908 portal on evade'),
(161713, 0, 36, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 11, 161909, 150, 1, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Clear the 161909 portal on evade'),
(161713, 0, 37, 13, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 70, 0, 0, 0, 0, 0, 9, 161904, 0, 60, 1, 0, 0, 0, 0, 'Wayward Theologian - On Link - Set the summoned units to 70% health (70% wave)'),
(161713, 0, 38, 15, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 25, 0, 0, 0, 0, 0, 9, 161904, 0, 60, 1, 0, 0, 0, 0, 'Wayward Theologian - On Link - Set the summoned units to 25% health (25% wave)'),
(161713, 0, 39, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Enter event phase 1 (70% wave)'),
(161713, 0, 40, 21, 31, 1, 100, 1, 256762, 0, 0, 0, 0, 0, 11, 256763, 32, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Dark Reality landing - Shadow Shield + the 70% wave summons'),
(161713, 0, 41, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Enter event phase 2 (25% wave)'),
(161713, 0, 42, 23, 31, 2, 100, 1, 256762, 0, 0, 0, 0, 0, 11, 256763, 32, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Dark Reality landing - Shadow Shield + the 25% wave summons'),
(161713, 0, 43, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Aggro - Say Line 0 (intro)'),
(161713, 0, 44, 0, 0, 0, 100, 1, 4000, 4000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - In Combat (4 s) - Say Line 1 (intro, once)'),
(161713, 0, 45, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Death - Say Line 2 (dying line)'),
(161713, 0, 46, 0, 110, 0, 100, 0, 1000, 1000, 1000, 1000, 35, 35, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - Leash - On the aggro holder farther than ~40 yd - Evade and reset the encounter');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 161713 AND `SourceGroup` IN (1, 2, 3, 12);
INSERT INTO `conditions` (
    `SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 161713, 0, 0, 1, 1, 256763, 0, 0, 1, 0, 0, '', 'Wayward Theologian - Silent while Shadow Shield is up (Shadow Bolt row)'),
(22, 2, 161713, 0, 0, 1, 1, 256763, 0, 0, 1, 0, 0, '', 'Wayward Theologian - Silent while Shadow Shield is up (Shadowfury row)'),
(22, 3, 161713, 0, 0, 1, 1, 256763, 0, 0, 1, 0, 0, '', 'Wayward Theologian - Silent while Shadow Shield is up (Fierce Blow row)'),
(22, 12, 161713, 0, 0, 29, 1, 161904, 150, 0, 1, 0, 0, '', 'Wayward Theologian - Shadow Shield drops when no summoned unit remains');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161908, 161909) AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`,
    `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`,
    `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
    `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
    `comment`) VALUES
(161908, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 256761, 32, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian portal - On Reset - Cast Portal'),
(161909, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 256761, 32, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian portal - On Reset - Cast Portal'),
(161908, 0, 1, 2, 73, 0, 100, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -8617.437, -574.22394, 149.65506, 0, 'Wayward Theologian portal - On Spell Click - Teleport the clicker to the platform above'),
(161909, 0, 1, 2, 73, 0, 100, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -8593.289, -563.79486, 150.80756, 0, 'Wayward Theologian portal - On Spell Click - Teleport the clicker to the platform above'),
(161908, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 11, 161713, 200, 1, 0, 0, 0, 0, 0, 'Wayward Theologian portal - On Link - Tell the boss to re-engage after the teleport'),
(161909, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 11, 161713, 200, 1, 0, 0, 0, 0, 0, 'Wayward Theologian portal - On Link - Tell the boss to re-engage after the teleport'),
(161908, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 11, 161904, 500, 1, 0, 0, 0, 0, 0, 'Wayward Theologian portal - On Link - Tell the summons to re-engage after the teleport'),
(161909, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 11, 161904, 500, 1, 0, 0, 0, 0, 0, 'Wayward Theologian portal - On Link - Tell the summons to re-engage after the teleport');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161904 AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`,
    `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`,
    `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
    `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
    `comment`) VALUES
(161904, 0, 0, 0, 0, 0, 100, 0, 0, 0, 5000, 5000, 0, 0, 11, 256738, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - In Combat - Cast Shadow Bolt'),
(161904, 0, 1, 2, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Reset - Never move in combat'),
(161904, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 100, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Attack the closest player'),
(161904, 0, 3, 4, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Just Summoned - Never move in combat'),
(161904, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 100, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Link - Attack the closest player'),
(161904, 0, 5, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 500, 0, 0, 0, 0, 0, 0, 0, 'Wayward Theologian - On Data Set 1 1 - Attack the closest player again after a portal teleport');

-- 7. creature_text - the encounter's lines --------------------------------------------
-- The first line lands the moment combat starts (aggro), the second follows 4 seconds in via
-- a timed row (the timer pauses out of combat and re-arms on a wipe); the third is his dying
-- line and plays from the On Death row. Type 12 = monster say; no sound, no emote.
DELETE FROM `creature_text` WHERE `CreatureID` = 161713;

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`)
VALUES
(161713, 0, 0, 'You''ve come for Sitis, haven''t you? Then you''ve already gone too far... I''m sorry for what must follow.', 12, 0, 100, 0, 0, 0, 0),
(161713, 1, 0, 'We are not so different. Curiosity led me too -into her words, her philosophy...', 12, 0, 100, 0, 0, 0, 0),
(161713, 2, 0, 'I beg you... Don''t speak her name... Don''t read her words... Her philosophy... will be your end...', 12, 0, 100, 0, 0, 0, 0);

-- ##########################################################################################
-- SECTION 7 - quest links
-- ##########################################################################################

-- Spada chain quest giver/ender links, from the pre-rebuild backup (creature_queststarter /
-- creature_questender rows for the 1660000 quest family) with later corrections that move the
-- sisterhood arc to Sister Alma (see the exceptions below).
--
-- Moroi Spada 161701 is the hub for most of the chain. Exceptions:
--   * 1660000 Bookworm starts at Bianca Spada 161700
--   * 1660002 The Ruins of Northshire ends at Sister Alma 161702 - the backup had Moroi, but
--     the quest's completion log ("Speak with the spectral priestess.") names Alma, the
--     'Ancient Priestess of Northshire'
--   * 1660003 Accursed Sisterhood starts AND ends at Sister Alma 161702 (log "Speak with
--     Sister Alma."; the backup had Moroi on both sides)
--   * 1660038 The Saddest Among Us starts AND ends at Sister Alma 161702
--   * 1660004 Words that Shepherd Madness starts at Sister Alma 161702 (the end stays Moroi)
--   * 1660005 The Threat Swept Downstream starts AND ends at Injured Northshire Guard 161705
--     (its log "Return to the injured guard." fits a single hub NPC)
--   * 1660036 Oracular Idol ends at Father Harnos 161844 - it has NO creature starter (the
--     quest-start item 559159 starts it); the supertrack endpoint (waypoint 8696) sits exactly
--     on Harnos's spawn at the abbey (-8904.51, -171.01, 81.58)
--   * 1660055 The Maid I Left Behind starts at Bianca Spada 161700 - the quest text is Bianca
--     speaking about her maid Dulcinea ("I left one of my maids in Goldshire", "my brother");
--     the backup had Moroi as the starter
--   * the Goldshire continuation 1660055-1660060 is re-wired at the END of this file to the
--     full Spada cast (Dulcinea, Aldia Crayon, Clara the Mad, the mayor, Aliscar Lend and
--     Eldor Hammer). The lists below stay as they are so the Northshire rows keep their
--     idempotent cleanup; the block at the end is the last writer for the six quests.
--
-- Idempotent: removes only this family's rows, then re-inserts them.

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660000, 1660001, 1660002, 1660003, 1660004, 1660005, 1660038, 1660055, 1660056, 1660057);

INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(161700, 1660000),
(161701, 1660001),
(161701, 1660002),
(161702, 1660003),
(161702, 1660004),
(161705, 1660005),
(161702, 1660038),
(161700, 1660055);

DELETE FROM `creature_questender` WHERE `quest` IN (1660000, 1660001, 1660002, 1660003, 1660004, 1660005, 1660036, 1660038, 1660055, 1660056, 1660057);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(161701, 1660000),
(161701, 1660001),
(161702, 1660002),
(161702, 1660003),
(161701, 1660004),
(161702, 1660038),
(161705, 1660005),
(161844, 1660036);

-- ##########################################################################################
-- SECTION 8 - quest objects
-- ##########################################################################################

-- Spada quest objects: the Lost Page chests for quest 1660001 'Knowledge Corrupts', the
-- walk-up markers that complete 1660002 'The Ruins of Northshire' (the Dungeon Door) and
-- quest 1660004's "Hidden Path found" + "Ruined Estate discovered" (the 161703 + 161704
-- markers), and the Shadewell murloc loot tables of quest 1660005 (Spada chain).
--
-- Merged 2026-09-28 from the standalone rebuild script (2026-09-14) and re-checked against
-- the live client's game object cache before merging:
--   * gameobjectcache.wdb knows 2300500 / 2300503 / 2300504 / 2300505 as type 3
--     (chest) with display 300450 and the names 'Lost Page I'..'Lost Page IV'
--     (the same cache also holds 2300501 'Dungeon Door', spawned separately).
--   * display 300450 exists in both the server and client GameObjectDisplayInfo.dbc
--     (world\expansion03\doodads\worgen\items\worgen_paper_06.m2).
--   * loot items 559130-559133 are exactly quest 1660001's four required items,
--     and no other loot table drops them.
--
-- WHAT THIS FILE PROVIDES:
--   1. the four gameobject loot rows - they were missing from the rebuilt world,
--      which made the Lost Pages unobtainable and the quest impossible to finish.
--   2. the Lost Page ambush: opening a page chest summons Living Heresy 161711 at
--      the chest and it attacks the looter (it despawns when it evades). The summon
--      is guarded - never more than one Living Heresy near a chest at a time; the
--      chest's data flag and timer are per-chest bookkeeping only.
--   3. Living Heresy's combat behaviour: it fights with Shadow Bite 256474 and despawns
--      when it evades. Its creature_template and model rows are recreated here as well -
--      on the live server they were a direct edit that no layer file carried, so a fresh
--      core plus northshire layer had no 161711 at all (found 2026-09-29 in the boot log).
--   4. the Dungeon Door 2300501: walking up to it credits quest 1660002's
--      dungeon-entrance objective (161714), whose marker has no spawn in any source.
--   5. the Injured Northshire Guard 161705: spawns and respawns at 10% health (he is the
--      wounded guard of the chain) - his SmartAI rows are spawn-scoped (he has a single
--      spawn, and a spawn script replaces the entry script) and set the health on
--      spawn/respawn plus a 1 s pin; his template regen is off so he stays wounded; he
--      also says a line when the player accepts quest 1660005 from him.
--   6. the quest 1660004 walk-up markers 161703 + 161704: walking through the quest's tracked
--      path nodes (supertrack waypoints 8655 and 8656) credits "Hidden Path found" and
--      "Ruined Estate discovered" - the markers are the chain's invisible kill-credit stubs,
--      spawned on those path points.
--   7. the Shadewell murloc loot tables (161716 + 161717): both had none; each now drops the
--      item kit of the lowest-level stock murloc wearing its model, plus the zone's level 1-5
--      world-drop references. 161717 additionally carries quest 1660036's drops: the quest
--      starter 'Oracular Idol' (559159, only while the quest is not started or completed - the
--      core enforces it for startquest items) and the quest-required Prophet's Oracular Orb
--      (559160, only rolls for looters who still need one).
--   8. Northshire NPC tuning (2026-09-28): the two Northshire wolves 299 'Young Wolf' + 69
--      'Timber Wolf' get the classic wolf model (display 903, Creature\Wolf\Wolf.mdx) and lose
--      their shipped 'Diseased' aura (spell 71764) - cleared on both template addons and the
--      spawn addon guid 79945; and the Northshire/Defias mobs 537, 161707, 161708, 161713,
--      161716, 161717 and 161736 get a 10 yard aggro radius (detection_range 20 -> 10); plus
--      the Northshire Guard 1642 (all seven abbey spawns) at level 55, down from 65 (2026-09-29).
--   9. sleeping NPC Zzz (2026-09-28): the two sleeping Northshire Defias (spawn guids 7500263
--      'Defias Thug' + 7500285 'Defias Trainee', stand state 3) get the cosmetic spell 55474
--      'Cosmetic - Sleep Zzz' on their spawn addon so the Zzz shows above them like on the
--      original server; a spawn-scoped SmartAI row strips it on aggro and the engine reapplies
--      it when the creature leaves combat (mechanics in the section).
--  10. Accursed Judge 161708 loot (2026-09-29): the judge (display 4629) had lootid 0 - its kit
--      is recreated from the ghosts it matches: the same-display donor 15657 'Darkwraith'
--      (Linen Cloth, Refreshing Spring Water, Forest Mushroom Cap, Shiny Red Apple) and the level
--      3-4 Arcane Wraiths 15273/15298 (the lowbie wraith reference trio incl. the 'Wraith 1-5'
--      table).
--  11. the Injured Northshire Guard's gossip text (2026-09-29): talking to him showed only the
--      quest list - his wounded-soldier greeting is stored as npc_text 750001 (single variant,
--      Probability0 1) and wired through gossip_menu 750001; creature_template.gossip_menu_id
--      on 161705 points at it. npc_text has no reload command - the text binds when the
--      worldserver starts (the menu mapping alone hot-reloads with `.reload gossip_menu`).
--  12. the 'Lost Page V' spawn removed (2026-09-29): the chest 2300516 (a worldforged pickup,
--      not part of the quest) had its spawn guid 7500147 (-8856.41, -191.365, 90.3931)
--      deleted; the DELETE below keeps re-imports free of the row. The 2300516
--      template itself is untouched.
--  13. a base-world spawn removed (2026-09-29): the Shadewell Spider 161707 spawn guid 7500304
--      (-8754.30, -290.93, 66.52 - one of the eleven spiders placed by the package) was
--      deleted; the DELETEs below keep re-imports free of it. 161707's template
--      and its ten remaining spawns are untouched.
--  14. the Shadewell Spider 161707 loot (2026-09-29): lootid 0 -> the kit of the same-model
--      Night Web Spider 1505 (the undead starting zone's spider, level 3-4): the lowbie
--      spider references (Small Pouch 0.2%, Grey 1-5 20%, Spider 1-5 100% + 30% second roll)
--      plus Webbed Pants 3263 at 1%, copied verbatim.
--  15. the Northshire cleaning pass (2026-09-29): deduplicates the valley benches and removes
--      stray props and spawns - the base-world bench guids
--      26725-26741 and their custom duplicates, the extra Lost Page V/VI chests, the second
--      Scorched Tome, the waterlogged chest, five old tool-era props, the leftover Rabbit
--      79947, the disabled Living Heresy stub 9000135 and the duplicate Old Northshire Bolter
--      7500128 all gone; the sleeping Trainee 7500285 re-stated at its new spot. Spawn
--      statements load at worldserver start.
--
-- WHAT THIS FILE DELIBERATELY DOES NOT TOUCH:
--   * the chest templates 2300500 / 2300503 / 2300504 / 2300505 - lockId, consumable
--     and every other field stay exactly as the world has them. Three fields change:
--     `AIName` is set (so the objects can run SmartAI), `Data8` is cleared (see the
--     update below) and `ScriptName` is cleared to detach the worldforged-pickup
--     module (see the detach note above the update).
--   * the world's own spawn POSITIONS - they are authoritative and stay as placed:
--       2300500 guid 7500102
--       2300503 guids 7500143, 7500144, 7500145, 7500146
--       2300504 guid 7500106
--       2300505 guid 7500154
--     (the rebuild script's 6000xxx spawns are duplicates of these and are not used).
--     The two rows that carry the module's ScriptName at spawn level (7500146, 7500154)
--     get that one field cleared; nothing else about them changes.
--
-- Idempotent: delete-and-reinsert of the four loot rows.

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (2300500, 2300503, 2300504, 2300505);

INSERT INTO `gameobject_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300500, 559130, 0, 100, 1, 1, 0, 1, 1, 'Knowledge Corrupts - Lost Page I'),
(2300503, 559131, 0, 100, 1, 1, 0, 1, 1, 'Knowledge Corrupts - Lost Page II'),
(2300504, 559132, 0, 100, 1, 1, 0, 1, 1, 'Knowledge Corrupts - Lost Page III'),
(2300505, 559133, 0, 100, 1, 1, 0, 1, 1, 'Knowledge Corrupts - Lost Page IV');

-- Lost Page re-loot fix (2026-10-10): QuestRequired alone does not stop a character who
-- already has a page from being handed another one - it only hides the item from a
-- character with no active need for it, not from one who already banked the page and is
-- still mid-quest. The chests are non-consumable (so their loot re-rolls for the next
-- opener) and no longer carry ScriptName 'worldforged_pickup' (cleared below, so
-- SmartGameObjectAI can run the Living Heresy ambush instead - see that note for why the
-- two AIs cannot coexist). These conditions recreate the module's "once per character"
-- rule at the loot-template level: each page item is withheld once the looting character
-- already holds a copy of it.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 4 AND `SourceGroup` IN (2300500, 2300503, 2300504, 2300505);

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(4, 2300500, 559130, 0, 0, 2, 0, 559130, 1, 0, 1, 0, 0, '', 'Lost Page I - withhold the item once the looter already has a copy'),
(4, 2300503, 559131, 0, 0, 2, 0, 559131, 1, 0, 1, 0, 0, '', 'Lost Page II - withhold the item once the looter already has a copy'),
(4, 2300504, 559132, 0, 0, 2, 0, 559132, 1, 0, 1, 0, 0, '', 'Lost Page III - withhold the item once the looter already has a copy'),
(4, 2300505, 559133, 0, 0, 2, 0, 559133, 1, 0, 1, 0, 0, '', 'Lost Page IV - withhold the item once the looter already has a copy');

-- 2. Lost Page ambush: Living Heresy 161711 --------------------------------------------
-- Opening a page chest (loot state GO_ACTIVATED) runs the chest's SmartAI. One condition
-- gates the whole trigger: no Living Heresy (161711) within 20 yd of that chest. A
-- data-field check must NOT be added to the summon row: smart rows run in id order
-- within one event pass, so the flag row (id 1) would set the field before the summon
-- row (id 2) read it and the summon would never run.
-- Data8 (the chest's quest field) is cleared so the chests stop shimmering for the whole
-- time the quest is merely incomplete - the core sparks a chest while its quest is
-- INCOMPLETE (GameObject::ActivateToQuest). The chests still count as quest objects because
-- their loot rows are QuestRequired, so each chest shimmers only while the player still
-- needs the page it drops, and stops once they have it. Lock, loot and the ambush are
-- untouched.
-- When the trigger passes, three actions run in order: a one-shot 30 second timed
-- event (id 1) is created, the cooldown flag is set, and Living Heresy is summoned at
-- the chest. The summon carries no attack order of its own - the summon action's
-- attack-invoker shortcut (value 2) fails the load-time validation and the row would be
-- skipped - instead Living Heresy engages itself on spawn (section 3: On Just Summoned
-- -> attack the closest player). When the timed event fires, the flag is cleared again.
-- The flag lives on the chest instance alone, so it only ever kept one chest from
-- re-triggering itself; the 20 yd check is what keeps the ambushers from stacking across
-- the chest cluster, and Living Heresy despawns when it evades (last statement in this
-- file), so a killed or evaded ambusher never blocks the next page.
--
-- THE WORLDFORGED-PICKUP DETACH (2026-09-28): the chest templates ship with
-- ScriptName 'worldforged_pickup' (the CoA worldforged-pickup module, which index pages
-- and other world pickups use for their one-loot-per-character memory). A ScriptName
-- script outranks AIName when the engine picks a gameobject's AI, so with the name in
-- place that module's pickup AI owned these chests and SmartGameObjectAI - and with it
-- the ambush - never bound. For a quest chest the module is actively wrong:
-- GameObject::Use asks the AI's GossipHello first and the module refuses the use of any
-- spawn the character has already looted there once, forever. The core keeps glowing
-- the page chests for as long as the quest still needs that page, so a player who lost
-- or destroyed a page saw a chest that glows but cannot be looted - and a player who
-- abandoned and retook the quest was locked out of the pages for good. Clearing the
-- name hands the chests back to the core and to SmartGameObjectAI: they loot whenever
-- the player still needs the page, the glow follows that need, and the ambush runs.
-- The module's other two hooks (the loot veto and the claims ledger) key on the same
-- script name, so they stop matching these spawns as well.

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `Data8` = 0 WHERE `entry` IN (2300500, 2300503, 2300504, 2300505);

-- Two spawn rows repeat the script name and a spawn ScriptName overrides the template's,
-- so they are cleared too (a no-op where the spawns are not imported yet).
UPDATE `gameobject` SET `ScriptName` = '' WHERE `guid` IN (7500146, 7500154);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300500, 2300503, 2300504, 2300505) AND `source_type` = 1;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300500, 1, 0, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page I - On Loot Opened - Start 30 second spawn cooldown'),
(2300500, 1, 1, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page I - On Loot Opened - Set cooldown flag'),
(2300500, 1, 2, 0, 70, 0, 40, 0, 2, 0, 0, 0, 0, 0, 12, 161711, 7, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page I - On Loot Opened - Summon Living Heresy (40% ambush chance)'),
(2300500, 1, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 45, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page I - Cooldown expired - Clear cooldown flag'),
(2300503, 1, 0, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page II - On Loot Opened - Start 30 second spawn cooldown'),
(2300503, 1, 1, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page II - On Loot Opened - Set cooldown flag'),
(2300503, 1, 2, 0, 70, 0, 40, 0, 2, 0, 0, 0, 0, 0, 12, 161711, 7, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page II - On Loot Opened - Summon Living Heresy (40% ambush chance)'),
(2300503, 1, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 45, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page II - Cooldown expired - Clear cooldown flag'),
(2300504, 1, 0, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page III - On Loot Opened - Start 30 second spawn cooldown'),
(2300504, 1, 1, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page III - On Loot Opened - Set cooldown flag'),
(2300504, 1, 2, 0, 70, 0, 40, 0, 2, 0, 0, 0, 0, 0, 12, 161711, 7, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page III - On Loot Opened - Summon Living Heresy (40% ambush chance)'),
(2300504, 1, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 45, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page III - Cooldown expired - Clear cooldown flag'),
(2300505, 1, 0, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page IV - On Loot Opened - Start 30 second spawn cooldown'),
(2300505, 1, 1, 0, 70, 0, 100, 0, 2, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page IV - On Loot Opened - Set cooldown flag'),
(2300505, 1, 2, 0, 70, 0, 40, 0, 2, 0, 0, 0, 0, 0, 12, 161711, 7, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page IV - On Loot Opened - Summon Living Heresy (40% ambush chance)'),
(2300505, 1, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 45, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Page IV - Cooldown expired - Clear cooldown flag');

-- Conditions bind to smart rows by SourceGroup = smart id + 1, so group 1/2/3 is row
-- id 0/1/2. The summon row (group 3) carries only the 20 yd check.
-- Each group also now carries the "looter does not already have the page" check (id 2 =
-- CONDITION_ITEM, negated): with it, a character who already banked the page gets no
-- cooldown timer, no cooldown flag and no ambush at all from clicking the chest again -
-- the same "inert for that character" outcome worldforged_pickup used to give, just
-- reimplemented on top of SmartAI instead of relying on the now-detached module.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` IN (2300500, 2300503, 2300504, 2300505) AND `SourceId` = 1;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 2300500, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page I - no Living Heresy within 20 yards (id 0)'),
(22, 1, 2300500, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page I - spawn cooldown flag not set (id 0)'),
(22, 1, 2300500, 1, 0, 2, 0, 559130, 1, 0, 1, 0, 0, '', 'Lost Page I - looter does not already have the page (id 0)'),
(22, 2, 2300500, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page I - no Living Heresy within 20 yards (id 1)'),
(22, 2, 2300500, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page I - spawn cooldown flag not set (id 1)'),
(22, 2, 2300500, 1, 0, 2, 0, 559130, 1, 0, 1, 0, 0, '', 'Lost Page I - looter does not already have the page (id 1)'),
(22, 3, 2300500, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page I - no Living Heresy within 20 yards (id 2)'),
(22, 3, 2300500, 1, 0, 2, 0, 559130, 1, 0, 1, 0, 0, '', 'Lost Page I - looter does not already have the page (id 2)'),
(22, 1, 2300503, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page II - no Living Heresy within 20 yards (id 0)'),
(22, 1, 2300503, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page II - spawn cooldown flag not set (id 0)'),
(22, 1, 2300503, 1, 0, 2, 0, 559131, 1, 0, 1, 0, 0, '', 'Lost Page II - looter does not already have the page (id 0)'),
(22, 2, 2300503, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page II - no Living Heresy within 20 yards (id 1)'),
(22, 2, 2300503, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page II - spawn cooldown flag not set (id 1)'),
(22, 2, 2300503, 1, 0, 2, 0, 559131, 1, 0, 1, 0, 0, '', 'Lost Page II - looter does not already have the page (id 1)'),
(22, 3, 2300503, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page II - no Living Heresy within 20 yards (id 2)'),
(22, 3, 2300503, 1, 0, 2, 0, 559131, 1, 0, 1, 0, 0, '', 'Lost Page II - looter does not already have the page (id 2)'),
(22, 1, 2300504, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page III - no Living Heresy within 20 yards (id 0)'),
(22, 1, 2300504, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page III - spawn cooldown flag not set (id 0)'),
(22, 1, 2300504, 1, 0, 2, 0, 559132, 1, 0, 1, 0, 0, '', 'Lost Page III - looter does not already have the page (id 0)'),
(22, 2, 2300504, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page III - no Living Heresy within 20 yards (id 1)'),
(22, 2, 2300504, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page III - spawn cooldown flag not set (id 1)'),
(22, 2, 2300504, 1, 0, 2, 0, 559132, 1, 0, 1, 0, 0, '', 'Lost Page III - looter does not already have the page (id 1)'),
(22, 3, 2300504, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page III - no Living Heresy within 20 yards (id 2)'),
(22, 3, 2300504, 1, 0, 2, 0, 559132, 1, 0, 1, 0, 0, '', 'Lost Page III - looter does not already have the page (id 2)'),
(22, 1, 2300505, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page IV - no Living Heresy within 20 yards (id 0)'),
(22, 1, 2300505, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page IV - spawn cooldown flag not set (id 0)'),
(22, 1, 2300505, 1, 0, 2, 0, 559133, 1, 0, 1, 0, 0, '', 'Lost Page IV - looter does not already have the page (id 0)'),
(22, 2, 2300505, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page IV - no Living Heresy within 20 yards (id 1)'),
(22, 2, 2300505, 1, 0, 104, 1, 1, 0, 0, 0, 0, 0, '', 'Lost Page IV - spawn cooldown flag not set (id 1)'),
(22, 2, 2300505, 1, 0, 2, 0, 559133, 1, 0, 1, 0, 0, '', 'Lost Page IV - looter does not already have the page (id 1)'),
(22, 3, 2300505, 1, 0, 29, 1, 161711, 20, 0, 1, 0, 0, '', 'Lost Page IV - no Living Heresy within 20 yards (id 2)'),
(22, 3, 2300505, 1, 0, 2, 0, 559133, 1, 0, 1, 0, 0, '', 'Lost Page IV - looter does not already have the page (id 2)');

-- 3. Living Heresy 161711 - combat ability and despawn on evade -------------------------
-- It fights with Shadow Bite 256474 (the spell the live server's version uses): instant,
-- no mana cost, 15 second stacking debuff on the target that also deals a small shadow
-- hit. The biting cadence is a design choice - the spell carries no cooldown in the DBC.
-- It engages on its own when summoned, through event 54 (Just Summoned) - a summon cannot
-- order the attack itself: the summon action's attack-invoker value 2 is rejected by the
-- load-time validation (boolean, 0-1) and the whole row is skipped. Level 3, faction 14
-- (Monster) and unit_class 1 fit the level 6 / min level 3 quest it guards.
--
-- FRESH-INSTALL BASE: the live world's 161711 creature_template was a direct edit on the
-- live server (no layer file carried it), so a fresh core + northshire layer + this import
-- had no 161711 - the chest ambush summon and its 12 type-29 conditions were skipped with
-- 'does not exist' warnings. Recreated from the 2026-09-29 pre-fresh backup (row copied
-- verbatim: level 3/3, faction 14, unit_class 1, SmartAI, display 19110).

INSERT INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(161711,0,0,0,0,0,'Living Heresy',NULL,NULL,0,3,3,0,14,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,'SmartAI',0,1,1,1,1,1,0,0,1,0,0,'',NULL)
ON DUPLICATE KEY UPDATE
`difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 161711;

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(161711,0,19110,1,1,NULL);

UPDATE `creature_template` SET `AIName` = 'SmartAI', `minlevel` = 3, `maxlevel` = 3, `faction` = 14, `unit_class` = 1 WHERE `entry` = 161711;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161711 AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(161711, 0, 0, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Living Heresy - On Evade - Despawn'),
(161711, 0, 1, 0, 0, 0, 100, 0, 1000, 1500, 4000, 6000, 0, 0, 11, 256474, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Living Heresy - In Combat - Cast Shadow Bite'),
(161711, 0, 2, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 100, 0, 0, 0, 0, 0, 0, 0, 'Living Heresy - On Just Summoned - Attack the closest player');

-- 4. Dungeon Door 2300501 - completes 1660002 'The Ruins of Northshire' ------------------
-- 1660002's only objective is credit 161714 ('Secret Inquisitorial Dungeon entrance
-- found') and the marker has no spawn in any source - the cellar door itself delivers the
-- credit when a player walks up to it: no click, no client-side area trigger (the client's
-- AreaTrigger.dbc has no trigger at the door, and the client only sends CMSG_AREATRIGGER
-- for triggers it knows from that DBC).
--
-- Walk-up detection is SMART_EVENT_NEAR_PLAYERS (101) on the door itself: the GO AI arms the
-- event via its first timer (1.5 s after the door loads), then every repeat window it counts
-- non-GM players within 8 yd. Action 33 credits quest objective 161714 and target 17
-- (PLAYER_RANGE) resolves to every player within 7 yd of the door, so group members walking
-- in together are each credited. KilledMonsterCredit only ticks the quest while it is
-- active, so the script is harmless for anyone not on 1660002 - they just walk past a door.
-- No condition rows: the credit action is the whole script.
--
-- Idempotent: one UPDATE + delete/reinsert of the object's script.

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300501;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300501 AND `source_type` = 1;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300501, 1, 0, 0, 101, 0, 100, 0, 1, 8, 1500, 1500, 2500, 0, 33, 161714, 0, 0, 0, 0, 0, 17, 0, 7, 0, 0, 0, 0, 0, 0, 'Dungeon Door - On players near (1 within 8 yd) - Credit Secret Inquisitorial Dungeon entrance found (walk-up)');

-- 5. Injured Northshire Guard 161705 - spawns at 10% health and stays pinned there ---------
-- He must always look (and be) wounded. He has a single spawn (7500315), so every one of his
-- SmartAI rows lives on that spawn (-7500315): a spawn script REPLACES the unit's entry
-- script (unless the creature has CREATURE_FLAG_EXTRA_DONT_OVERRIDE_ENTRY_SAI) and his spawn
-- already carries one (the health pin placed by the spawn-section block at the end of this
-- import), so entry-scoped rows could never run.
-- SMART_ACTION_SET_HEALTH_PCT (142) with 10% runs on:
--   * SMART_EVENT_JUST_CREATED (63, the first spawn) and SMART_EVENT_RESPAWN (11, every
--     respawn; all of its type/map/zone params are 0, meaning "any") - instant 10% on spawn;
--   * SMART_EVENT_UPDATE (60) every second - pinned "no matter what": that event has no
--     in/out-of-combat guard, so heals (or damage) cannot leave him above/below 10% while
--     alive. The 1 s cadence is the tuning knob (event_param1..4 = initial/repeat ms).
-- The template's RegenHealth is turned off as well - otherwise out-of-combat regeneration
-- would fight the pin between ticks. Death is unaffected: he respawns and re-pins.
--
-- The spawn row itself is set to the same 10% of his 386 base HP (level 17: 386 / 10 = 38;
-- the action computes the identical 38). With RegenHealth off the core honors the spawn's
-- `curhealth` verbatim, so he is wounded from the first frame - even before the script
-- above is bound to the instance (e.g. right after the row is added and nothing reloaded).
--
-- He also briefs the player: accepting quest 1660005 from him fires SMART_EVENT_QUEST_ACCEPT
-- (19, event_param1 = the quest id), which plays his creature_text group 0 as a monster say
-- (SMART_ACTION_TALK, target self). The line is authored (no broadcast text or capture
-- carries it); `.reload creature_text` makes it live, while the event rows themselves bind
-- when the spawn's script rebinds (worldserver restart).
--
-- Idempotent: two UPDATEs + delete of the unit's entry rows + delete/reinsert of the
-- spawn-scoped rows (ids 1-4) + delete/reinsert of the say line.

UPDATE `creature_template` SET `RegenHealth` = 0 WHERE `entry` = 161705;

UPDATE `creature` SET `curhealth` = 38 WHERE `id` = 161705;

-- All rows of the unit, spawn-scoped (ids 1-4); the spawn's own pin row (id 0) is placed by
-- the spawn-section block at the end of this import.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161705 AND `source_type` = 0;

DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500315 AND `source_type` = 0 AND `id` IN (1, 2, 3, 4) AND `link` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-7500315, 0, 1, 0, 19, 0, 100, 0, 1660005, 20000, 20000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Northshire Guard - On quest 1660005 accepted - say his briefing line'),
(-7500315, 0, 2, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Northshire Guard - On Just Created - Set health to 10% - spawns injured'),
(-7500315, 0, 3, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Northshire Guard - On Respawn - Set health to 10% - spawns injured'),
(-7500315, 0, 4, 0, 60, 0, 100, 0, 1000, 1000, 1000, 1000, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Northshire Guard - Update (every 1 s) - Pin health to 10%');

-- The briefing line. Type 12 = monster say; no voice, no emote; plain text (no broadcast).
DELETE FROM `creature_text` WHERE `CreatureID` = 161705 AND `GroupID` = 0 AND `ID` = 0;

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`)
VALUES
(161705, 0, 0, 'Spare no mercy, to Defias or murloc alike. That''s experience talking...', 12, 0, 100, 0, 0, 0, 0);

-- 6. Quest 1660004 walk-up markers 161703 + 161704 - the path credits its objectives ----------
-- Both are the chain's invisible, non-selectable kill-credit stubs (display 11686
-- InvisibleStalker, unit_flags 33555200), each spawned directly ON its supertrack node of
-- quest 1660004 'Words that Shepherd Madness', so walking the path credits the matching
-- objective:
--   161703 "Hidden Path found" (RequiredNpcOrGo1)        - supertrack slot 1, waypoint 8655,
--                                                          map 0, -8708.26, -504.44, 153.34
--   161704 "Ruined Estate discovered" (RequiredNpcOrGo2) - supertrack slot 2, waypoint 8656,
--                                                          map 0, -8604.62, -570.05, 145.22
--     (slot 2 is where the Wayward Theologian waits - the estate is discovered exactly as the
--      player arrives at the confrontation)
-- Same walk-up pattern as the Dungeon Door in section 4: SMART_EVENT_NEAR_PLAYERS (101) fires
-- when any non-GM player is within 12 yards and CALL_KILLEDMONSTER (33 -> the marker's own
-- entry) credits every player within that radius (target 17 PLAYER_RANGE; GMs are excluded by
-- the event and the target). Crediting a marker is a no-op unless its quest is active and
-- incomplete, so no conditions are needed.
-- The markers' spawns (guids 7500365, 7500366) live in the import's spawn snapshot section.
-- Each marker has exactly one spawn, so its script is spawn-scoped (-7500365 / -7500366):
-- a spawn script replaces the unit's entry script.
-- Idempotent: one template UPDATE + delete of the old entry rows + delete/reinsert per marker.

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (161703, 161704);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161703, 161704) AND `source_type` = 0;

DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500365 AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-7500365, 0, 0, 0, 101, 0, 100, 0, 1, 12, 1000, 1000, 1500, 0, 33, 161703, 0, 0, 0, 0, 0, 17, 0, 12, 0, 0, 0, 0, 0, 0, 'Hidden Path marker - On players near (1 within 12 yd) - Credit Hidden Path found (walk-up)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500366 AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-7500366, 0, 0, 0, 101, 0, 100, 0, 1, 12, 1000, 1000, 1500, 0, 33, 161704, 0, 0, 0, 0, 0, 17, 0, 12, 0, 0, 0, 0, 0, 0, 'Ruined Estate marker - On players near (1 within 12 yd) - Credit Ruined Estate discovered (walk-up)');

-- 7. Shadewell murloc loot 161716 + 161717 - copied from their same-model stock murlocs -------
-- Both murlocs of quest 1660005 had no loot (lootid 0). Each gets a new loot table with the
-- item kit of the LOWEST-LEVEL stock creature wearing the same model (display search, sorted
-- by minlevel): 161716 (display 757) from 458 'Murloc Hunter' (level 16-17); 161717 (display
-- 1079) from 517 'Murloc Oracle' (level 17-18) - no stock user of those displays below level
-- 16 carries a loot table. The kit is the classic murloc drop set: Murloc Eye, Murloc Fin,
-- Small Barnacled Clam, Slimy Murloc Scale, Raw Longjaw Mud Snapper, Clam Meat, food and junk.
-- The world-drop references are the level 1-5 trio this zone uses (same structure as the
-- Northshire kobolds and as lootid 38 of the Defias Thug, which the custom Defias Plunderer
-- 161736 and Wayward Theologian 161713 already drop): 11111 Small Pouch 0.2%,
-- 20014 Food 1-5 30%, 20000 Grey 1-5 30% (group 1, matching that convention).
-- The donors' own "World Loot Level 16/17" references were NOT copied: those packages only
-- start at level 5 and target level 16-18 drops, which do not belong on level 3-4 murlocs.
-- Quest item: quest 1660036 'Oracular Idol' wants three Prophet's Oracular Orbs (559160)
-- "from the murloc oracles roaming the Shadewell Spring", but the orb had no source in any
-- loot table. 161717 now carries it as a QuestRequired row: it rolls only for a looter who
-- has the quest and still needs an orb (LootMgr gates on Player::HasQuestForItem, which also
-- stops the drop at 3/3). Chance 100, one orb per drop - every eligible kill drops one until 3/3.
-- Quest starter: quest 1660036 has no other giver - the 'Oracular Idol' item 559159 starts it
-- (startquest = 1660036). The item row is a clean-package item already present in acore_world
-- (verified field-for-field, 125/125, against the Ascension client capture of 2026-08-30), so
-- only the drop is wired here. Its row MUST keep QuestRequired = 0: a requirement flag would
-- hide it from exactly the players who do not have the quest yet. No loot condition is needed
-- for the "only drop while the quest is not started or completed" rule - the core hides
-- quest-starter drops once the quest is started or rewarded, or while the player already
-- holds one (LootItem::AllowedForPlayer, LootMgr.cpp). Chance 100.
-- Idempotent: two template UPDATEs + delete/reinsert of both tables.

UPDATE `creature_template` SET `lootid` = 161716 WHERE `entry` = 161716;

UPDATE `creature_template` SET `lootid` = 161717 WHERE `entry` = 161717;

DELETE FROM `creature_loot_template` WHERE `entry` IN (161716, 161717);

INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161716, 730, 0, 35.3831, 0, 1, 0, 1, 1, 'Shadewell Murloc - Murloc Eye'),
(161716, 1179, 0, 2.3676, 0, 1, 0, 1, 1, 'Shadewell Murloc - Ice Cold Milk'),
(161716, 1357, 0, 1, 0, 1, 0, 1, 1, 'Shadewell Murloc - Captain Sanders'' Treasure Map'),
(161716, 1468, 0, 13.201, 0, 1, 0, 1, 1, 'Shadewell Murloc - Murloc Fin'),
(161716, 2287, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc - Haunch of Meat'),
(161716, 2698, 0, 0.12, 0, 1, 0, 1, 1, 'Shadewell Murloc - Recipe: Cooked Crab Claw'),
(161716, 4359, 0, 0.06, 0, 1, 0, 1, 1, 'Shadewell Murloc - Handful of Copper Bolts'),
(161716, 4361, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc - Copper Tube'),
(161716, 4363, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc - Copper Modulator'),
(161716, 4364, 0, 0.12, 0, 1, 0, 1, 1, 'Shadewell Murloc - Coarse Blasting Powder'),
(161716, 4405, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc - Crude Scope'),
(161716, 4541, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc - Freshly Baked Bread'),
(161716, 5498, 0, 0.08, 0, 1, 0, 1, 1, 'Shadewell Murloc - Small Lustrous Pearl'),
(161716, 5503, 0, 1.92, 0, 1, 0, 1, 1, 'Shadewell Murloc - Clam Meat'),
(161716, 5523, 0, 35.8435, 0, 1, 0, 1, 1, 'Shadewell Murloc - Small Barnacled Clam'),
(161716, 5784, 0, 17.0996, 0, 1, 0, 1, 1, 'Shadewell Murloc - Slimy Murloc Scale'),
(161716, 6289, 0, 5.0641, 0, 1, 0, 1, 3, 'Shadewell Murloc - Raw Longjaw Mud Snapper'),
(161716, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Shadewell Murloc - (Small Pouch ReferenceTable)'),
(161716, 0, 20014, 30, 0, 1, 0, 1, 1, 'Shadewell Murloc - (Food 1-5 ReferenceTable)'),
(161716, 0, 20000, 30, 0, 1, 1, 1, 1, 'Shadewell Murloc - (Grey 1-5 ReferenceTable)'),
(161717, 414, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Dalaran Sharp'),
(161717, 730, 0, 36.4778, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Murloc Eye'),
(161717, 1179, 0, 2.197, 0, 1, 0, 1, 5, 'Shadewell Murloc Oracle - Ice Cold Milk'),
(161717, 1357, 0, 1, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Captain Sanders'' Treasure Map'),
(161717, 1468, 0, 43.012, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Murloc Fin'),
(161717, 2287, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Haunch of Meat'),
(161717, 2698, 0, 0.06, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Recipe: Cooked Crab Claw'),
(161717, 4359, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Handful of Copper Bolts'),
(161717, 4364, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Coarse Blasting Powder'),
(161717, 4537, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Tel''Abim Banana'),
(161717, 4541, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Freshly Baked Bread'),
(161717, 4605, 0, 0.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Red-speckled Mushroom'),
(161717, 5498, 0, 0.0523, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Small Lustrous Pearl'),
(161717, 5503, 0, 1.62, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Clam Meat'),
(161717, 5523, 0, 36.5998, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Small Barnacled Clam'),
(161717, 5784, 0, 17.0009, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Slimy Murloc Scale'),
(161717, 6289, 0, 4.2371, 0, 1, 0, 1, 3, 'Shadewell Murloc Oracle - Raw Longjaw Mud Snapper'),
(161717, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - (Small Pouch ReferenceTable)'),
(161717, 0, 20014, 30, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - (Food 1-5 ReferenceTable)'),
(161717, 0, 20000, 30, 0, 1, 1, 1, 1, 'Shadewell Murloc Oracle - (Grey 1-5 ReferenceTable)'),
(161717, 559159, 0, 100, 0, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Oracular Idol (starts quest 1660036)'),
(161717, 559160, 0, 100, 1, 1, 0, 1, 1, 'Shadewell Murloc Oracle - Prophet''s Oracular Orb (Oracular Idol)');

-- 8. Northshire NPC tuning - wolf restyle + 10 yard aggro radius ------------------------------
-- Wolves 299 'Young Wolf' and 69 'Timber Wolf': the package ships them with the custom displays
-- 31048/31049 and the 'Diseased' aura (spell 71764) on both creature_template_addon rows; the
-- spawn-level addon guid 79945 repeated the aura. Changed 2026-09-28: display 903
-- (Creature\Wolf\Wolf.mdx - the classic wolf; creature_model_info has a row for 903) and no aura.
-- Aggro radius: creature_template.detection_range 20 -> 10 for 537 Defias Trainee, 161707
-- Shadewell Spider, 161708 Accursed Judge, 161713 Wayward Theologian, 161716 Shadewell Murloc,
-- 161717 Shadewell Murloc Oracle and 161736 Defias Plunderer. detection_range is the base of
-- the creature's aggro radius (Creature::GetAggroRange, read into the creature at creation),
-- so anything created after the import has it at once - pair it with `.reload creature_template
-- <entry>` to update the loaded template in place first; existing creatures pick it up when a
-- restart or grid recreation re-creates them.
-- Creature models and addons are boot-loaded (no reload commands) - the wolf look and aura
-- changes need the worldserver restart.
-- Idempotent: five UPDATEs.

UPDATE `creature_template_model` SET `CreatureDisplayID` = 903 WHERE `CreatureID` IN (69, 299);

UPDATE `creature_template_addon` SET `auras` = '' WHERE `entry` IN (69, 299);

UPDATE `creature_addon` SET `auras` = '' WHERE `guid` = 79945;

UPDATE `creature_template` SET `detection_range` = 10 WHERE `entry` IN (537, 161707, 161708, 161713, 161716, 161717, 161736);

-- Northshire Guard 1642 (the seven spawns on the abbey grounds): level 65 -> 55 (2026-09-29).
-- The template level is read by Creature::SelectLevel when a creature is created, so existing
-- guards follow on respawn or restart; `.reload creature_template 1642` updates the loaded
-- template first.

UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 55 WHERE `entry` = 1642;

-- 9. Sleeping NPCs - 'Zzz' over the two sleeping Northshire Defias -----------------------------
-- Both sleeping spawns carry stand state 3 (sleep) in `creature_addon` but nothing drew the Zzz:
-- in this client the pose alone shows no glyphs - the game's own sleepers always carry a visual
-- spell too (Stalvan Mistmantle 20355, Shatterhorn 24178, Blackmaw 30001, Rageclaw Pup 29848,
-- Icehowl 35470). The one used here is 55474 'Cosmetic - Sleep Zzz' (hidden dummy aura + the
-- persistent Zzz spell visual 12147; present in the server AND client Spell.dbc and already used
-- by the package's own sleeping NPCs).
--
-- Why this is enough (all engine behaviour, no restore scripting):
--   * spawn / grid load / respawn  - Creature::LoadCreaturesAddon applies `auras` and the stand
--     state from this table;
--   * aggro                        - Creature::AtEngage() stands the creature up (the pose byte
--     clears by itself) and the spawn's AGGRO row below removes 55474 - it is a hidden dummy
--     aura, so unlike a sleep effect it does NOT break on its own;
--   * combat end                   - CreatureAI::EnterEvadeMode() and the HomeMovementGenerator
--     call LoadCreaturesAddon(true), which re-applies the sleep pose AND the aura (the same path
--     that makes sitting NPCs sit back down after combat); the respawn path does it too.
-- The AGGRO rows are SPAWN-scoped (negative entryorguid = creature guid), so the stock Defias
-- Thug/Trainee spawns elsewhere stay untouched. Entry 38 already runs SmartAI with an on-aggro
-- bark; because a spawn script REPLACES the entry script (SmartScript::GetScript: guid first,
-- entry as fallback), that bark row is repeated here verbatim. Entry 537 had no AIName - it gains
-- SmartAI for this one scripted spawn.
-- Re-running northshire_custom_only.sql resets `creature_addon.auras` to '' (and entry 537's
-- AIName) - re-apply this section (or the whole master) afterwards, like the wolves section.
-- Idempotent: two UPDATEs + delete/reinsert of the two spawn scripts.

UPDATE `creature_addon` SET `auras` = '55474' WHERE `guid` IN (7500263, 7500285);

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 537;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-7500263, -7500285) AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-7500263, 0, 0, 0, 4, 0, 30, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'CoA - Defias Thug (sleeping spawn) - On Aggro - Say Line 0 (entry-script copy)'),
(-7500263, 0, 1, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 28, 55474, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'CoA - Defias Thug (sleeping spawn) - On Aggro - remove Cosmetic - Sleep Zzz'),
(-7500285, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 28, 55474, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'CoA - Defias Trainee (sleeping spawn) - On Aggro - remove Cosmetic - Sleep Zzz');

-- 10. Accursed Judge 161708 - loot rebuilt from the same-display and same-level ghosts -----------
-- 161708 'Accursed Judge' (display 4629, level 3-4, undead) sat at lootid 0. Display 4629 is the
-- shared spectral model; its only low-level user with loot is 15657 'Darkwraith' (9-10), and the
-- level-exact ghosts are 15273 'Arcane Wraith' / 15298 'Tainted Arcane Wraith' (3-4). Both kits
-- are recreated:
--   * wraith trio (verbatim from the Arcane Wraiths): ref 11111 0.2%, ref 20001 30%, ref 20013
--     100% plus a second ref 20013 at 30% in group 1 - 20013 rolls Wraith Fragment/Sparkling Dust;
--   * Darkwraith items (verbatim): Linen Cloth 30.2389% (1-2), Refreshing Spring Water 3.5188%,
--     Forest Mushroom Cap 7.3666%, Shiny Red Apple 0.0072%.
-- Deliberately NOT copied: the Darkwraith's chance-0 Scourge event refs (1000109/1000110 - they
-- never roll) and the wraiths' Ghostlands quest items (20482/20483/20934, QuestRequired - wrong
-- zone). Siblings 161895/161897 (also 'Accursed Judge') and 161712 'Accursed Censor' still have
-- lootid 0 - point them at kit 161708 if wanted.
-- Idempotent: lootid pointer + delete/reinsert of the eight rows.

UPDATE `creature_template` SET `lootid` = 161708 WHERE `entry` = 161708;

DELETE FROM `creature_loot_template` WHERE `entry` = 161708;

INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161708, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Accursed Judge - (Small Pouch ReferenceTable, lowbie wraith trio)'),
(161708, 0, 20001, 30, 0, 1, 0, 1, 1, 'Accursed Judge - (Grey 1-5 ReferenceTable, lowbie wraith trio)'),
(161708, 0, 20013, 100, 0, 1, 0, 1, 1, 'Accursed Judge - (Wraith 1-5 ReferenceTable, always one)'),
(161708, 0, 20013, 30, 0, 1, 1, 1, 1, 'Accursed Judge - (Wraith 1-5 ReferenceTable, 30% second roll)'),
(161708, 159, 0, 3.5188, 0, 1, 0, 1, 1, 'Accursed Judge - Refreshing Spring Water (Darkwraith 15657)'),
(161708, 2589, 0, 30.2389, 0, 1, 0, 1, 2, 'Accursed Judge - Linen Cloth (Darkwraith 15657)'),
(161708, 4536, 0, 0.0072, 0, 1, 0, 1, 1, 'Accursed Judge - Shiny Red Apple (Darkwraith 15657)'),
(161708, 4604, 0, 7.3666, 0, 1, 0, 1, 1, 'Accursed Judge - Forest Mushroom Cap (Darkwraith 15657)');

-- 11. Injured Guard 161705 - gossip text, the wounded soldier's greeting ---------------------------
-- The guard's gossip window carried no text (gossip_menu_id 0), so it opened straight onto the
-- quest list. The greeting supplied for him - the skewered shoulder, the bitterness about the
-- "quiet post", and the refusal to die here - is stored as npc_text 750001 (single text variant,
-- Probability0 1 like the other single-variant rows) and mapped by gossip_menu 750001, which
-- creature_template.gossip_menu_id puts on the guard. npc_text has no reload command: the text
-- itself binds on the next worldserver start (the mapping alone can hot-reload via
-- `.reload gossip_menu` + `.reload creature_template 161705`).
-- Idempotent: delete/reinsert of the text and menu rows + the pointer update.

DELETE FROM `npc_text` WHERE `ID` = 750001;

INSERT INTO `npc_text` (`ID`, `text0_0`, `Probability0`) VALUES
(750001, '<The soldier gasps, his fist barely clenched around the hilt of his sword. His arm dangles uselessly from a shoulder skewered clean through by an arrow shaft still jutting from the wound.>\n\nNorthshire Valley was supposed to be a quiet post... "a stroke of luck", they said, to have me stationed here!\n\n<He spits his bitterness to the ground and growls:>\n\nTo hell with that. I''m not dying here.', 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 750001;

INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(750001, 750001);

UPDATE `creature_template` SET `gossip_menu_id` = 750001 WHERE `entry` = 161705;

-- 12. Lost Page V 2300516 - spawn 7500147 removed (2026-09-29) -----------------------------------
-- Deleted: the chest at -8856.41, -191.365, 90.3931 (the worldforged pickup 'Lost
-- Page V', not part of quest 1660001) is gone from the world. The family import no longer
-- carries the guid in its spawn snapshot, and this DELETE removes a lingering row on
-- re-import. Spawn rows are loaded at worldserver start / grid load.
-- Idempotent: a repeated delete is a no-op.

-- 13. Shadewell Spider 161707 - spawn 7500304 removed (2026-09-29) -------------------------------
-- Deleted: the spider at -8754.30, -290.93, 66.52 (one of the package's eleven 161707
-- spawns; the template and the other ten spawns are untouched). The family import never carried
-- this guid in its spawn snapshot - these DELETEs remove a lingering row on re-import (there is
-- no ON DELETE CASCADE on creature_addon in this schema, hence the explicit second delete).
-- Spawn rows are loaded at worldserver start / grid load.
-- Idempotent: repeated deletes are no-ops.

DELETE FROM `creature_addon` WHERE `guid` = 7500304;

-- 14. Shadewell Spider 161707 - loot copied from the same-model Night Web Spider (2026-09-29) --
-- 161707 'Shadewell Spider' (level 3, ten spawns in the Shadewell mine area) sat at lootid 0 -
-- it dropped nothing. Its model is shared with the undead starting zone's spiders: the client
-- CreatureDisplayInfo maps display 955 (161707), display 539 (1505 Night Web Spider) and
-- display 513 (1504 Young Night Web Spider) all to model 30,
-- Creature\MineSpider\MineSpider.mdx - they are the same spider with different display rows.
-- The donor is 1505 'Night Web Spider' (Tirisfal Glades / Deathknell, level 3-4) - the level
-- match for the level 3 Shadewell Spider - and its table is copied verbatim:
--   * the classic lowbie references (named tables live in `reference_loot_template`):
--     11111 Small Pouch 0.2%, 20000 Grey 1-5 EXP 0 20%, and 20004 Spider 1-5 100% plus a 30%
--     second roll in group 1 (20004 rolls Snapped Spider Limb 40% / Sticky Ichor 30% /
--     Bug Eye 30%);
--   * item 3263 Webbed Pants at 1%.
-- The donor's template has mingold/maxgold 0 (no coin) and pickpocketloot 0, so the lootid
-- pointer is the only template change. The lootid is the entry itself, like 161716/161717/
-- 161708 above. Loot hot-reloads: `.reload creature_template 161707` + `.reload
-- creature_loot_template` + `.reload conditions`.
-- Idempotent: one template UPDATE + delete/reinsert of the five rows.

UPDATE `creature_template` SET `lootid` = 161707 WHERE `entry` = 161707;

DELETE FROM `creature_loot_template` WHERE `entry` = 161707;

INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161707, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Shadewell Spider - (Small Pouch ReferenceTable)'),
(161707, 0, 20000, 20, 0, 1, 0, 1, 1, 'Shadewell Spider - (Grey 1-5 ReferenceTable - Night Web Spider 1505)'),
(161707, 0, 20004, 100, 0, 1, 0, 1, 1, 'Shadewell Spider - (Spider 1-5 ReferenceTable, always one)'),
(161707, 0, 20004, 30, 0, 1, 1, 1, 1, 'Shadewell Spider - (Spider 1-5 ReferenceTable, 30% second roll)'),
(161707, 3263, 0, 1, 0, 1, 0, 1, 1, 'Shadewell Spider - Webbed Pants (Night Web Spider 1505)');

-- 15. Northshire cleaning pass - bench dedup, stray props and spawns removed (2026-09-29) -------
-- The pass deduplicated the valley benches and cleaned up leftovers earlier passes (or the
-- base world) had placed. Everything below is transcribed verbatim; the script/comment
-- carry-over and one extra deletion after it were added, for the reasons noted there.
--
--   * creature: the leftover Rabbit 79947 (entry 721) and the disabled Living Heresy test stub
--     9000135 (entry 161711, spawnMask 0 - the live-world reconciliation no longer re-adds it
--     either) are removed; the sleeping Defias Trainee 7500285 is re-stated at its new spot
--     (-8907.27, -407.93, 67.01), and 9000143 keeps its place and values.
--   * gameobject deletions - the fifteen base-world bench guids 26725-26741 are duplicates of
--     benches that survive as 7500xxx props; the custom guids deleted without replacement are
--     duplicates or strays: the Lost Page VI and V chests 7500101 / 7500148 (worldforged
--     props, not quest content), the extra benches 7500119, 7500120, 7500151, 7500152, the
--     waterlogged chest 7500130, the duplicate Scorched Tome 7500141, plus five old tool-era
--     rows (Apprentice Staff 6940063, Defias Special Bucket 6940345, Murloc Tool 6940787,
--     Slain Traveler 6941293, Wax Stained Bag 6941333).
--   * the seven re-stated props are the dedup survivors: the Forgotten Sack 7500090 and the
--     Alliance Gem of Fortitude 7500133 (both nudged), the three benches, the Barrel of Milk
--     7500157 and the Apprentice Staff 7500127 (same spot, re-oriented).
--   * one further deletion follows the export (see the note at the end of this section):
--     the duplicate Old Northshire Bolter 7500128.
--   * smart_scripts / creature_text: the guard 161705 gains an entry-scoped briefing row
--     (id 3: accept quest 1660005 -> say his line), the preset and greeting rows and the two
--     creature_text rows are re-stated. Note: the guard's single spawn 7500315 runs a
--     spawn-scoped script, and a spawn script replaces the entry script - his accept line
--     keeps firing from -7500315 id 1, and the new entry row stays dormant until that spawn
--     script is ever dropped. Edited 2026-09-29: the 'IT'S BEEN HALF AN HOUR' line
--     left the Defias Thug aggro group 0 for its own group 1, and the -80183 preset row now
--     talks group 1 (group 0 is back to the two stock Defias aggro lines).
--
-- Spawn rows load at worldserver start / grid load.
-- Idempotent: delete-and-reinsert for every table touched.

SET @CGUID  := 79947;
SET @OGUID  := 26725;

-- creature_addon ------------------------------------------------------------------------
DELETE FROM `creature_addon` WHERE `guid` IN (@CGUID, @CGUID+8920188);
INSERT INTO `creature_addon`
  (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
   `auras`) VALUES
  (@CGUID+7420338, 0, 0, 3, 1, 0, 0, '55474')
ON DUPLICATE KEY UPDATE `path_id` = VALUES(`path_id`), `mount` = VALUES(`mount`),
  `emote` = VALUES(`emote`), `auras` = VALUES(`auras`),
  `bytes1` = (`bytes1` & 0xFFFFFF00) | (VALUES(`bytes1`) & 0xFF);

-- smart_scripts -------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500315 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500251 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -80183 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161705 AND `source_type` = 0 AND `id` = 3 AND `link` = 0;
INSERT INTO `smart_scripts`
  (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
   `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
   `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
   `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
   `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
   `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
  (-7500315, 0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
   0.000000, 0.000000, 0.000000, 0.000000,
   'Update IC -> Set Health PCT (percent=10) at Self'),
  (-7500251, 0, 0, 0, 1, 0, 100, 0, 60000, 60000, 120000, 120000, 0, 0, 1, 0, 0, 0, 0, 0, 0,
   1, 0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Preset: says its line while it is out of combat, first after 60s, then every 120s.'),
  (-80183, 0, 0, 0, 1, 0, 100, 0, 15000, 15000, 60000, 60000, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1,
   0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Preset: says its line while it is out of combat, first after 15s, then every 60s.'),
  (161705, 0, 3, 0, 19, 0, 100, 0, 1660005, 20000, 20000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1,
   0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Injured Northshire Guard - On quest 1660005 accepted - say his briefing line');

-- creature_text -------------------------------------------------------------------------
DELETE FROM `creature_text` WHERE `CreatureID` = 38 AND `GroupID` = 0 AND `ID` = 0;
DELETE FROM `creature_text` WHERE `CreatureID` = 38 AND `GroupID` = 1 AND `ID` = 0;
DELETE FROM `creature_text` WHERE `CreatureID` = 161700 AND `GroupID` = 0 AND `ID` = 0;
INSERT INTO `creature_text`
  (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
   `Duration`, `Sound`, `BroadcastTextId`) VALUES
  (38, 1, 0, 'IT''S BEEN HALF AN HOUR GET OUTTA THERE!!', 12, 0, 100, 0, 0, 0, 0),
  (161700, 0, 0,
   'Moroi, I know you''re in there! We don''t have all day. Mother doesn''t either! Get out here you scoundrel!',
   12, 0, 100, 0, 0, 0, 0);

-- Script carry-over (added 2026-09-29): the export's reduced gameobject column list has no
-- `ScriptName`, `VerifiedBuild` or `Comment`, so re-inserting the seven survivors would
-- silently clear the worldforged_pickup binding on the three pickups and drop the layer's
-- per-row annotations. Both are restored below: the scripting is functionally load-bearing
-- (it hands the object's item to the looter), and the annotations match the northshire
-- layer's convention on every other row. The Trainee's comment is restored for the same
-- annotation reason; its reduced creature columns carry no script.

UPDATE `gameobject` SET `ScriptName` = 'worldforged_pickup', `Comment` = 'CoA - Forgotten Sack', `VerifiedBuild` = 12340 WHERE `guid` = 7500090;
UPDATE `gameobject` SET `ScriptName` = 'worldforged_pickup', `Comment` = 'CoA - Apprentice Staff', `VerifiedBuild` = 12340 WHERE `guid` = 7500127;
UPDATE `gameobject` SET `ScriptName` = 'worldforged_pickup', `Comment` = 'CoA - Alliance Gem of Fortitude', `VerifiedBuild` = 12340 WHERE `guid` = 7500133;
UPDATE `gameobject` SET `Comment` = 'CoA - Wooden Bench', `VerifiedBuild` = 12340 WHERE `guid` IN (7500104, 7500105, 7500110);
UPDATE `gameobject` SET `Comment` = 'CoA - Barrel of Milk', `VerifiedBuild` = 12340 WHERE `guid` = 7500157;

UPDATE `creature` SET `Comment` = 'CoA - Defias Trainee', `VerifiedBuild` = 12340 WHERE `guid` = 7500285;

-- Old Northshire Bolter 7500128 - duplicate spawn removed (2026-09-29) ---------------------------
-- Added after the cleaning pass. The worldforged pickup 'Old Northshire Bolter' (gameobject
-- entry 520064) sat at -8801.30, -399.039, 76.015 - a duplicate of the module's own in-game
-- placement 6940835 (entry 520064 at -8801.51, -399.379, 75.957, about 0.4 yard away), which
-- keeps its place. Gameobject namespace only: the creature guid 7500128 (a Shadewell murloc
-- spawn) is untouched. The northshire layer still lists this spawn, so the DELETE below removes
-- it on every re-import; the family import no longer carries the guid.
-- Spawn rows load at worldserver start / grid load.
-- Idempotent: a repeated delete is a no-op.

SET @OGUID  := 7500128;

-- ##########################################################################################
-- SECTION 9 - relic purification
-- ##########################################################################################

-- Relic purification for quest 1660003 'Accursed Sisterhood' (Spada chain).
--
-- Design: clicking a relic makes the PLAYER cast Heartfelt Prayer (3 second cast)
-- at a hidden [KC] marker unit standing on the relic, so the prayer and its
-- glimmer play on the relic, and the matching objective completes only when that
-- cast succeeds:
--   * Every relic carries its own marker spawn on top of it. The four markers
--     have unique creature entries (161880 Journal, 161881 Staff, 161882 Idol,
--     161883 Jewel) - an earlier revision shared one entry (161715), and the
--     closest-by-entry search could then pick a far copy of it, which the range
--     check refused with "Out of range".
--   * The relic is a GOOBER with data1 = 1660003 (quest gate) and data10 = 0;
--     SmartGameObjectAI binds via AIName and its single row answers the plain use
--     (event 64, param1 = 1 - the client also sends a report-use packet) with
--     86 CROSS_CAST: the invoker (the player) casts the relic's own Heartfelt
--     Prayer at the relic's marker, targeted by spawn id (SMART_TARGET_CREATURE_GUID,
--     an exact lookup - not a search). The marker is always exactly where the
--     relic is, so the cast's range check can never refuse it.
--   * The spell's DUMMY lands on the marker - the prayer and its glimmer play
--     there, on the relic - and the marker's own spawn-scoped row grants the
--     kill credit from its spell hit: the credit is applied only when the cast
--     completes (the dummy hit reaches the marker's SmartAI), so moving or being
--     interrupted credits nothing.
--   * spell_dbc REPLACES the whole DBC record, so every field the cast uses is
--     repeated here: 3000 ms cast (CastingTimeIndex 14), the original interrupt
--     flags, a 30 yard range (RangeIndex 4), equipped item class -1, school,
--     visual/icon, the 1.0 effect multipliers and the 0xFF0FBE name/description
--     locale masks. Strings stay empty - the loader keeps the DBC text for empty
--     SQL strings. The DUMMY keeps effect target 25 (unit target any) so the only
--     hit target is the marker the cast was aimed at.
--   * Kill credits: 256701 Journal -> 161715, 256726 Staff -> 161824, 256728 Idol ->
--     161825, 365036 Jewel -> 161826 (the invisible [KC] templates of quest 1660003;
--     SPELL_EFFECT_KILL_CREDIT 134 = RewardPlayerAndGroupAtEvent).
--   * Permanence: the relics are never hidden - a relic stays visible and usable for
--     every player after it has been prayed at. An earlier revision hid each relic from
--     the player who credited its objective (type 30 OBJECT_VISIBILITY conditions);
--     those rows are removed and only cleaned up below.
--
-- Activation: worldserver RESTART - gameobject_template, creature_template and the
-- DBC stores (spell_dbc) load at startup and have no reload command.
-- Idempotent: template updates + delete/reinsert of the objects' scripts, rows and
-- conditions.

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `data10` = 0 WHERE `entry` = 2300520;
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `data10` = 0 WHERE `entry` = 2300521;
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `data10` = 0 WHERE `entry` = 2300522;
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `data10` = 0 WHERE `entry` = 2300523;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300520, 2300521, 2300522, 2300523) AND `source_type` = 1;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300520, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256701, 0, 7, 0, 0, 0, 10, 7500347, 161880, 0, 0, 0, 0, 0, 0, 'Abbess Journal - plain use: Heartfelt Prayer cast at its marker 161880'),
(2300521, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256726, 0, 7, 0, 0, 0, 10, 7500348, 161881, 0, 0, 0, 0, 0, 0, 'Abbess Staff - plain use: Heartfelt Prayer cast at its marker 161881'),
(2300522, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256728, 0, 7, 0, 0, 0, 10, 7500346, 161882, 0, 0, 0, 0, 0, 0, 'Heretical Idol - plain use: Heartfelt Prayer cast at its marker 161882'),
(2300523, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 365036, 0, 7, 0, 0, 0, 10, 7500345, 161883, 0, 0, 0, 0, 0, 0, 'Jewel - plain use: Heartfelt Prayer cast at its marker 161883');

DELETE FROM `spell_dbc` WHERE `Id` IN (256701, 256726, 256728, 365036);

INSERT INTO `spell_dbc`
(`Id`, `AttributesEx`, `AttributesEx2`, `CastingTimeIndex`, `InterruptFlags`, `ProcChance`, `DurationIndex`, `RangeIndex`, `EquippedItemClass`, `Effect_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectMiscValue_1`, `EffectBonusMultiplier_1`, `EffectBonusMultiplier_2`, `EffectBonusMultiplier_3`, `SpellVisualID_1`, `SpellIconID`, `SchoolMask`, `Name_Lang_Mask`, `NameSubtext_Lang_Mask`, `Description_Lang_Mask`, `AuraDescription_Lang_Mask`)
VALUES
(256701, 0, 4, 14, 63, 101, 0, 4, -1, 3, 1, 25, 0, 1, 1, 1, 278474, 300, 1, 16712190, 16712190, 16712190, 16712190),
(256726, 0, 4, 14, 47, 101, 0, 4, -1, 3, 1, 25, 0, 1, 1, 1, 278474, 300, 1, 16712190, 16712190, 16712190, 16712190),
(256728, 0, 4, 14, 47, 101, 0, 4, -1, 3, 1, 25, 0, 1, 1, 1, 278474, 300, 1, 16712190, 16712190, 16712190, 16712190),
(365036, 268435456, 4, 14, 63, 101, 6, 4, -1, 3, 1, 25, 0, 1, 1, 1, 364270, 300, 1, 16712190, 16712190, 16712190, 16712190);

-- The four marker templates: one unique creature per relic, cloned from 161715
-- '[KC] Purify Relics' (level 1, faction 35, invisible stalker 11686, not selectable).
-- AIName 'SmartAI' lets each marker answer the prayer's hit with its relic's credit.

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(161880, 0, 0, 0, 0, 0, '[KC] Purify Journal', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 0, '', 12340),
(161881, 0, 0, 0, 0, 0, '[KC] Purify Staff', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 0, '', 12340),
(161882, 0, 0, 0, 0, 0, '[KC] Purify Idol', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 0, '', 12340),
(161883, 0, 0, 0, 0, 0, '[KC] Purify Jewel', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 0, 1, 1, 1, 33554432, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 0, '', 12340) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `dynamicflags` = VALUES(`dynamicflags`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161880, 161881, 161882, 161883);

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(161880, 0, 11686, 1.0000, 1.00, 12340),
(161881, 0, 11686, 1.0000, 1.00, 12340),
(161882, 0, 11686, 1.0000, 1.00, 12340),
(161883, 0, 11686, 1.0000, 1.00, 12340) ON DUPLICATE KEY UPDATE `CreatureDisplayID` = VALUES(`CreatureDisplayID`), `DisplayScale` = VALUES(`DisplayScale`), `Probability` = VALUES(`Probability`);

-- The prayer lands on the marker, so the marker grants the credit from its own
-- spell hit. One spawn-scoped row per marker (7500347 Journal, 7500348 Staff,
-- 7500346 Idol, 7500345 Jewel).

UPDATE `creature_template` SET `AIName` = '' WHERE `entry` = 161715;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-7500345, -7500346, -7500347, -7500348) AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-7500347, 0, 0, 0, 8, 0, 100, 0, 256701, 0, 0, 0, 0, 0, 33, 161715, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Journal marker 161880 - Heartfelt Prayer hit: credit 161715'),
(-7500348, 0, 0, 0, 8, 0, 100, 0, 256726, 0, 0, 0, 0, 0, 33, 161824, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Staff marker 161881 - Heartfelt Prayer hit: credit 161824'),
(-7500346, 0, 0, 0, 8, 0, 100, 0, 256728, 0, 0, 0, 0, 0, 33, 161825, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Idol marker 161882 - Heartfelt Prayer hit: credit 161825'),
(-7500345, 0, 0, 0, 8, 0, 100, 0, 365036, 0, 0, 0, 0, 0, 33, 161826, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Jewel marker 161883 - Heartfelt Prayer hit: credit 161826');

-- The conditions gate the click cast to an in-progress 1660003 (the relics cast
-- nothing themselves - data10 is 0 - and the marker credit needs the cast). A second
-- condition per relic (2026-10-10) gates on that relic's OWN objective not yet being
-- complete: quest_template 1660003 carries RequiredNpcOrGo1-4 = 161715/161824/161825/
-- 161826 (Journal/Staff/Idol/Jewel), RequiredNpcOrGoCount1-4 = 1 each, so objective
-- index 0-3 maps one-to-one to these four relics. CONDITION_QUEST_OBJECTIVE_PROGRESS
-- (48) is true when the player's slot counter for that objective equals ConditionValue3;
-- negated, it is true while the counter has not yet reached the required count (0, since
-- every count here is 1). Without this, the earlier "quest in progress" check alone let a
-- player re-trigger an already-completed relic's prayer/credit for as long as the other
-- three objectives were still outstanding.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` IN (2300520, 2300521, 2300522, 2300523) AND `SourceId` = 1;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 2300520, 1, 0, 47, 0, 1660003, 8, 0, 0, 0, 0, '', 'Abbess Journal - the prayer only casts while quest 1660003 is in progress'),
(22, 1, 2300520, 1, 0, 48, 0, 1660003, 0, 1, 1, 0, 0, '', 'Abbess Journal - only while its own objective (slot 0) is not yet complete'),
(22, 1, 2300521, 1, 0, 47, 0, 1660003, 8, 0, 0, 0, 0, '', 'Abbess Staff - the prayer only casts while quest 1660003 is in progress'),
(22, 1, 2300521, 1, 0, 48, 0, 1660003, 1, 1, 1, 0, 0, '', 'Abbess Staff - only while its own objective (slot 1) is not yet complete'),
(22, 1, 2300522, 1, 0, 47, 0, 1660003, 8, 0, 0, 0, 0, '', 'Heretical Idol - the prayer only casts while quest 1660003 is in progress'),
(22, 1, 2300522, 1, 0, 48, 0, 1660003, 2, 1, 1, 0, 0, '', 'Heretical Idol - only while its own objective (slot 2) is not yet complete'),
(22, 1, 2300523, 1, 0, 47, 0, 1660003, 8, 0, 0, 0, 0, '', 'Jewel - the prayer only casts while quest 1660003 is in progress'),
(22, 1, 2300523, 1, 0, 48, 0, 1660003, 3, 1, 1, 0, 0, '', 'Jewel - only while its own objective (slot 3) is not yet complete');

-- Permanence: no visibility conditions - a relic stays in the world for every player
-- after it has been prayed at. The delete clears the hide rows an earlier revision
-- created (the realm's own port of this content carries them too) and keeps re-applies
-- clean; nothing is inserted.

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 1 AND `SourceEntry` IN (2300520, 2300521, 2300522, 2300523);

-- The realm's port bound the same prayer mechanic to two more places. Our data owns
-- these spells now, so unbind the replaced handler (it despawns the object it is cast at
-- and is cast at a relic by the port's gameobject script) and give 2300579 'Kobold
-- Warren' (quest 1660058) the realm's own handler back, now casting 'Destroy' 267031:
-- the click runs the 3 second cast and only the completed cast reaches the handler,
-- which credits 162940, rolls the 75% ambush at the warren and despawns it - an
-- interrupted cast leaves everything unchanged. The handler binding covers the warren's
-- and the shard's spells alone; the sisterhood relics keep their own click cast and
-- credit rows, and 267031 keeps the native DUMMY effect the handler listens for.

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_coa_abbess_relic_prayer';

UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_abbess_relic', `AIName` = '', `Data10` = 0 WHERE `entry` = 2300579;

DELETE FROM `spell_script_names` WHERE `spell_id` = 267031;

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (267031, 'spell_coa_abbess_relic_prayer');

DELETE FROM `spell_dbc` WHERE `Id` = 267031;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300579 AND `source_type` = 1;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 2300579 AND `SourceId` = 1;

-- The handler summons and engages the ambusher itself, so the prospector needs no
-- script of its own.

INSERT INTO `creature_template` (`entry`, `name`, `AIName`)
VALUES (162915, 'Kobold Prospector', '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `AIName` = VALUES(`AIName`);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162915 AND `source_type` = 0;

-- ##########################################################################################

-- ##########################################################################################
-- SECTION 10 - quests (with the trailing NPC script and text blocks)
-- ##########################################################################################

-- ==========================================================================================
-- CoA custom quest family 166xxxx - ALL 30 quests in one import
-- Generated 2026-09-28 by merging spada_quest_chain.sql (10 Spada storyline quests) with
-- coa_quest_family_extras.sql (20 quests from the other storylines in the same id block).
-- This is the single quest import; the two originals remain as the recovery notes.
--
-- Recovered from the live client's quest caches:
--   D:\wow ASCENSION\Cache_old\WDB\enUS\questcache.wdb                               (default realm, 2026-08-26)
--   D:\wow ASCENSION\Cache_old\WDB\enUS\Vol'jin - Conquest of Azeroth\questcache.wdb (Vol'jin, 2026-09-11)
--   D:\wow ASCENSION\Cache_old\WDB\enUS\Darkmoon - Season 10 Wildcard\questcache.wdb (Darkmoon, 2026-08-18)
--
-- The cache holds the server's SMSG_QUEST_QUERY_RESPONSE, so every row here is what live
-- sends: level band, zone, XP band, money, flags, all five text fields, every objective and
-- its objective text. What the cache does NOT carry (server-side only) is left at defaults:
--   * quest_offer_reward / quest_request_items text and emotes
--   * quest_details emotes
--   * giver/turn-in links (creature_queststarter / creature_questender)
--   * chain links (PrevQuestID / NextQuestID) - the cache stores no chain data; the Spada
--     chain's prerequisites are wired by design in step 3 below
--
-- CONTENTS (load order):
--   1. quest_template       - all 30 quests (Spada chain first, then the other storylines)
--   2. quest_template_addon - the same 30 quests (1660056 and 1660079 need ProvidedItemCount 1)
--   3. chain prerequisites  - the Spada chain order (PrevQuestID links + one availability condition)
--
-- THE SPADA CHAIN (giver -> ender and objective ids inferred from the texts; the cache links nothing).
-- Prerequisites wired in step 3: 1660000 -> 1660001 -> 1660002 -> {1660003, 1660038};
-- 1660003 and 1660038 both -> 1660004; 1660003 -> 1660005; 1660004 -> 1660055:
--   1660000 Bookworm                       Bianca Spada 161700 -> Moroi Spada 161701, no objectives (a talk quest)
--   1660001 Knowledge Corrupts             Moroi Spada 161701 -> Moroi Spada, collect Lost Page I-IV (items 559130-559133)
--   1660002 The Ruins of Northshire        Moroi Spada 161701 -> Sister Alma 161702, objective 161714
--   1660003 Accursed Sisterhood            Sister Alma 161702 -> Sister Alma, purify objectives 161715/161824/161825/161826
--   1660004 Words that Shepherd Madness    Moroi Spada 161701 -> Moroi Spada, objectives 161703/161704/161713
--   1660005 The Threat Swept Downstream    Injured Northshire Guard 161705 -> Injured Northshire Guard (chain end)
--   1660038 The Saddest Among Us           Sister Alma 161702 -> Sister Alma, kill 161712 (chain end)
--   1660055 The Maid I Left Behind         Bianca Spada 161700 -> Dulcinea 162800, no objectives (a talk quest)
--   1660056 Agria's Medicine               Dulcinea 162800 -> Aldia Crayon 162802, buy the four ingredients
--   1660057 Seven Years of Bad Luck        Aldia Crayon 162802 -> Aldia Crayon, inspect 6x 162920 (chain end)
--
-- THE OTHER STORYLINES:
--   Anvilmar / Coldridge / Radiance Town (Dun Morogh)    1660006-1660011, 1660039
--   Zeb'Goro (Darkmoon cache only)                       1660018
--   Northshire, Shadewell Spring (Spada-chain companion) 1660036
--   Goldshire town                                       1660058, 1660059, 1660060
--   Kharanos / Thunderbrew (Dun Morogh)                  1660076, 1660077, 1660079
--   Vaults of Inquisition / Road to De Other Side        1660081-1660084, 1660088
--
-- CHAIN SUPPORT FILES (recovered separately; import them alongside this one):
--   spada_quest_links.sql           - giver/turn-in links for the chain, from the live backup
--   coa_missing_entities.sql        - the chain's missing creature rows (markers, Goldshire NPCs)
--   spada_quest_objects.sql         - Lost Page chests, the Living Heresy ambush
--   spada_relic_purify.sql          - the relic purification objects for 1660003
--   wayward_theologian_complete.sql - the 161713 encounter used by 1660004
-- Spawn positions for the recovered entities are in no source; place them yourself. The old
-- backup's giver/turn-in rows are blanket placeholders (Moroi starts and ends nearly
-- everything) and contradict the quest texts - do not copy them.
--
-- MONEY: this realm stores the client's "money at max level" in RewardMoneyDifficulty (see
-- Quest::FindMoneyTier) - col14 of the cache maps there, col13 to RewardMoney.
--
-- SOURCES: the Vol'jin realm cache is used where it has the quest (newest capture); the default
-- realm fills the gaps; 1660018 exists only in the Darkmoon cache. For 1660081/1660082 the two
-- caches disagree (Vol'jin: level -1 / min level 15, captured 09-11; default: level 15 / min 10,
-- captured 08-26) - the newer Vol'jin values are used here; swap if the older revision is wanted.
--
-- 1660006's four objectives are GAME OBJECTS, stored the way the core expects them: as negative
-- ids (-2300507 .. -2300510).
--
-- Safe to re-import. The file is UTF-8; import it with a utf8mb4 client charset.
-- quest_template rows are upserted (ON DUPLICATE KEY UPDATE), addon rows are delete-and-reinsert.
-- ==========================================================================================

-- 1. quest_template ------------------------------------------------------------------------

-- 1660000 Bookworm - Bianca Spada 161700 -> Moroi Spada 161701, no objectives (a talk quest)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660000, 2, 6, 3, 9, 0, 0, 3, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Bookworm', 'Speak with Seminarian Moroi, brother of Bianca Spada.', '<A woman greets you, visibly agitated. A sharp mix of anger and worry flashes in her eyes.>$b$bSorry, I didn’t mean to make a scene, but… that blasted brother of mine, always buried in his books! I’ve been out here forever, yelling my lungs out, and nothing. The guards have already warned me about “disturbing the abbey’s peace” one more time.$b$bWould you mind going in there and dragging him out by the ears if you have to? Our mother’s on her deathbed, and I’ve traveled a long way to fetch him so he can say goodbye. The ungrateful wretch.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660001 Knowledge Corrupts - Moroi Spada 161701 -> Moroi Spada, collect Lost Page I-IV (items 559130-559133)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660001, 2, 6, 3, 9, 0, 0, 4, 15, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Knowledge Corrupts', 'Recover the missing pages from Moroi’s unclassified manuscript, scattered throughout the abbey.', 'Go on, take a look.$b$b<Moroi gestures toward the book holding his attention: a thin, battered manuscript, not unlike its reader.>$b$bI stumbled across it in the library; it’s not listed in the abbey’s records. I think it’s some sort of chronicle about an old abbess accused of heresy. In my haste, I’ve misplaced several pages. I’ve been trying to piece them back together, but some are still missing.$b$bCould you have a look around the abbey and recover the pages I lost? This is a banned book; if anyone finds out I’ve been poking my nose where it doesn’t belong, they’ll ship me back home… to my sister.$b$bDo me a mercy, will you?', '', 'Return to Moroi.', 0, 0, 0, 0, 0, 0, 0, 0, 559130, 559131, 559132, 559133, 0, 0, 1, 1, 1, 1, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660002 The Ruins of Northshire - Moroi Spada 161701 -> Sister Alma 161702, objective 161714
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660002, 2, 6, 3, 9, 0, 0, 4, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Ruins of Northshire', 'Locate the cellar entrance to the Secret Inquisitorial Dungeon.', 'A visit to the dungeon where the abbess was tried might shed some light…$b$bAccording to the book, the now-abandoned town of Northshire held a secret entrance to the Inquisitorial Dungeon.$b$bI’ll mark it on your map, but tread carefully. No one’s set foot in that place for years… I’d rather not imagine what vermin have claimed its ruins.', '', 'Speak with the spectral priestess.', 161714, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Secret Inquisitorial Dungeon entrance found', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660003 Accursed Sisterhood - Sister Alma 161702 -> Sister Alma, purify objectives 161715/161824/161825/161826
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660003, 2, 6, 3, 9, 0, 0, 5, 0, 0, 0, 8, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Accursed Sisterhood', 'Purify the belongings of the former abbess, scattered throughout the Secret Inquisitorial Dungeon.', 'The way is shut. The abbess cursed those who judged her, binding them to wander as restless spirits.$b$bThose who died are still chained by her power. The dignity and belongings they stripped from her became shackles. A simple prayer. A sincere plea. That would be enough...$b$bThey’ll find no rest until someone purifies the abbess’s relics, scattered throughout the dungeon.$b$bBut the Dead guard them well. And so, the way remains shut.', '', 'Speak with Sister Alma.', 161715, 161824, 161825, 161826, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Abbess'' Journal Purified', 'Abbess''s Staff Purified', 'Heretical Idol Purified', 'Jewel Purified', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660004 Words that Shepherd Madness - Moroi Spada 161701 -> Moroi Spada, objectives 161703/161704/161713
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660004, 2, 6, 3, 9, 0, 2, 7, 35, 0, 0, 8, 559182, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Words that Shepherd Madness', 'Find the hidden path leading to the top of the waterfall and confront the sins of the former abbess of Northshire.', 'Sitis was... a storm. Her teachings were unorthodox; dangerous, even. Many students left the Church because of her.$b$bSo when the inquisitorial court summoned me to testify, I agreed to speak against her.$b$bI had learned she was holding secret gatherings with her closest circle at an old manor above the waterfall. In those meetings, Sitis spoke of the Light, of life, of death...$b$bAnd of the nature of the Shadow.$b$bHer heresy still stains that land. But beware if you go there; she had no shortage of followers, and the Inquisition never caught them all...', '', 'Return to Moroi and report what you’ve discovered about the former abbess and her crimes.', 161703, 161704, 161713, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Hidden Path found', 'Ruined Estate discovered', 'Wayward Theologian confronted', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660005 The Threat Swept Downstream - Injured Northshire Guard 161705 -> Injured Northshire Guard (chain end)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660005, 2, 6, 3, 9, 0, 0, 6, 20, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Threat Swept Downstream', 'Defeat the Defias lurking in the ruined tower and thin the ranks of the Shadewell murlocs atop the waterfall, across the rope bridge.', 'I need… help.$b$b<The soldier’s voice comes ragged, choked with pain. Each grimace is a fresh wound.>$b$bI was ordered to find the murloc village, to cut off their threat. But, as you can see, the road has not been kind to me. And worse yet: the only path to the upper river runs straight through that tower.$b$b<He nods weakly toward the looming, ruined structure.>$b$bYou, though… you might succeed where I could not.$b$bDeal with the Defias infesting the tower, thin the ranks of the murlocs above the falls, and you’ll be doing me a favor the whole kingdom will thank you for.', '', 'Return to the injured guard.', 161736, 161716, 0, 0, 5, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Plunderer slain', 'Shadewell Murloc slain', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660038 The Saddest Among Us - Sister Alma 161702 -> Sister Alma, kill 161712 (chain end)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660038, 2, 6, 3, 9, 0, 2, 3, 0, 0, 0, 8, 0, 0, 559176, 1, 559177, 1, 559178, 1, 559179, 1, 559180, 1, 559181, 1, 0, 0, 0, 'The Saddest Among Us', 'Defeat the Cursed Censor in the Secret Inquisitorial Dungeon.', 'Slave to the hunger of the flames, always demanding more books to devour. When there were no more blasphemies left, they turned on the sacred texts instead.$b$bThe fire burns in his hollow sockets; there are no more tears left to shed.$b$bOnly death can release the Cursed Censor…', '', 'Return to Sister Alma.', 161712, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660055 The Maid I Left Behind - Bianca Spada 161700 -> Dulcinea 162800, no objectives (a talk quest)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660055, 2, 8, 5, 12, 0, 0, 4, 120, 135, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 'The Maid I Left Behind', 'Find Dulcinea, Bianca''s maid, in Goldshire.', 'You''ve been in and out of the abbey all day, yet I still haven''t seen my brother anywhere.$b$bI take it you couldn''t snap him out of it. Well... worth a try.$b$b<Her long, weary sigh says enough.>$b$bHeading out again? Maybe you can do me one more favor. On the way to the abbey I left one of my maids in Goldshire with a long list of ingredients to buy; medicine for my mother.$b$bHer name is Dulcinea. Could you find her and let her know I''ll be late?', '', 'Speak with Dulcinea.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660056 Agria's Medicine - Dulcinea 162800 -> Aldia Crayon 162802, buy the four ingredients
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660056, 2, 8, 5, 12, 0, 0, 5, 110, 120, 558960, 8, 0, 0, 2302015, 1, 2302020, 1, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 'Agria''s Medicine', 'Buy the potion''s ingredients at the Goldshire market: Elgris Blossom Petals, Dun Kazad Liquor Concentrate, Pumpkin Juice, and a Murloc Eyeball.', 'Lady Agria Spada is a woman besieged by age. Of late she''s borne a litany of ailments that keep her to her bed.$b$bOnly one thing eases her: the draught brewed by her master alchemist.$b$bI''ve gathered a few ingredients, but the list is long and fussy. We still need Elgris Blossom Petals, Dun Kazad Liquor Concentrate, Pumpkin Juice, and a Murloc Eyeball.$b$bTake a turn through the market. Once you''ve got the lot, report to my lady''s manor. I don''t dare the roads alone, but you... you''re made of sterner stuff, aren''t you?', '', 'Speak with Aldia Crayon, butler to the Spadas, at the family manor.', 0, 0, 0, 0, 0, 0, 0, 0, 558956, 558957, 558958, 558959, 558960, 0, 1, 1, 1, 1, 1, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660057 Seven Years of Bad Luck - Aldia Crayon 162802 -> Aldia Crayon, inspect 6x 162920 (chain end)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660057, 2, 8, 5, 12, 0, 0, 5, 350, 382, 0, 8, 0, 0, 2302030, 1, 2302035, 1, 2302040, 1, 0, 0, 0, 0, 0, 0, 72, 5, 0, 'Seven Years of Bad Luck', 'Inspect the broken mirror shards that Aldia Crayon blames for the curse afflicting Lady Agria Spada.', 'Hm...$b$b<The majordomo gives you a long, measuring look.>$b$bBefore you go... I need your help with one more matter.$b$bI''ve had the sense for some time that my lady''s ailments aren''t physical, but magical. A curse.$b$bIt started with a broken mirror. And you know what they say. However thorough I''ve been, shards keep turning up; bits of glass tucked around the manor and the grounds.$b$bWould you kindly deal with them?', '', 'Return to the butler.', 162920, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard Inspected', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660006 Smoke on the Wind [voljin] - Coldridge Valley, Dun Morogh - follows Grelbin; objectives are the four burnt GOs
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660006, 2, 6, 3, 132, 0, 0, 4, 0, 0, 0, 8, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Smoke on the Wind', 'Follow in the footsteps of Grelbin, son of Groldha, and investigate the source of the smoke.', 'Ah, a traveler! One look at your garb and I knew you’d come from afar.$b$bCome closer, look. This newborn of mine suffers from an illness no healer has managed to cure. He has little time left. But his older brother refuses to accept that.$b$bSomewhere along the way, he heard whispers of a “congregation” claiming to have a cure for all ailments. Grelbin clung to that hope like a drowning man to driftwood, and left to find them.$b$bThat was two weeks ago. He hasn’t returned yet, and worse, the wind now carries an ugly black smoke from the direction I last saw him go. I fear the worst.$b$bPlease… follow in his footsteps, and bring him back to me. The gods have already judged that I must give up one son. I won’t lose them both.', '', 'Inspect the corpse of the dead crewman.', -2300507, -2300508, -2300509, -2300510, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Plating examined', 'Crate examined', 'Crystal shards examined', 'Banner examined', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660007 A Promising Path [voljin] - Coldridge Valley - loot the dead goblin, find the mountain path (objective 161721)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660007, 2, 6, 3, 132, 0, 0, 4, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Promising Path', 'Follow the mountain path to uncover the location of the mysterious group.', '<Before looting the body, you reason that the goblin won’t be missing the papers in his pocket.>$b$b<Thumbing through them, you piece together that the goblin was part of a crew sent to locate a mysterious group of ascetics in the Coldridge Mountains; the very same group Grelbin, Groldha’s son, went searching for.>$b$b<Among the papers, you find a map marking a path up the mountain to the ascetics’ hidden domain.>', '', 'Speak with the mountaineer.', 161721, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Hidden path tread', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660008 A Fitting Disguise [voljin] - Coldridge Valley - collect Radiant armour pieces (item 559142)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660008, 2, 6, 3, 132, 0, 0, 6, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Fitting Disguise', 'Slay Radiant fanatics and collect their armor pieces. Deliver them to Arathror so he can craft a disguise.', 'Up ahead are the gates to Radiance Town, a rat’s nest of that sect’s rabble. They call themselves “The Radiants.” I’ve been keeping watch on them for a month now.$b$bThey believe bathing in the same radiation that devastated Gnomeregan will grant them some kind of revelation, or Light knows what.$b$bThey’re dangerous; heretics as well as rebels. Their leader’s crowned himself king, if you can believe it. And I have orders to see him executed.$b$bNow that you’re here… a plan comes to mind.$b$bFollow the road, scout the forest ahead, and cut down a few of those zealots. Bring me back some pieces of their armor. I’ve got an idea… you’ll see!', '', 'Return to Arathror.', 0, 0, 0, 0, 0, 0, 0, 0, 559142, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660009 His Radiant Majesty [voljin] - Coldridge Valley - infiltrate Radiance Town, kill 161722 / 161775
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660009, 2, 6, 3, 132, 0, 2, 7, 35, 0, 0, 8, 559182, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'His Radiant Majesty', 'Tell Arathror when you’re ready to don the disguise. Then infiltrate Radiance Town and slay the cult leader, His Radiant Majesty.', 'I’ve had too many run-ins with the Radiant; they’d spot me in a heartbeat. You, though… you’re new. An unknown face.$b$bAye, I think this disguise will pass. Let me know when you’re ready and I’ll help you into it. No, not like that, don’t be daft.$b$bOnce you’re disguised, keep your head down. Cross the village to the far side without drawing attention, and find their so-called king. Most cults fall apart without a strong leader.$b$bIf this is one of them, you might just be in time to save Groldha’s son from losing his mind.', '', 'Return to Anvilmar and tell Groldha what you learned about her son and the sect.', 161722, 161775, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ask Arathror to help you put on the disguise', 'His Radiant Majesty slain', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660010 Deciphering Radiation [voljin] - Coldridge Valley - harvest mutagen (items 559161/559162)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660010, 2, 6, 3, 132, 0, 0, 5, 25, 0, 559161, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Deciphering Radiation', 'Slay radioactive slimes in Radiance Town and use the Contamination Extractor on their corpses to harvest mutagen.', 'If you can sneak your way into Radiance Town… there’s something I could use your help with.$b$bI’ve been trying to understand how radiation works, looking for a way to counter its effects. For that purpose… I built this:$b$b<Redna shows you a contraption that only vaguely resembles a rifle.>$b$bKill a few radioactive slimes, then pull the trigger on this beauty. It’ll siphon the essence out of the slime and, with luck, let me isolate the mutagen.', '', 'Bring the harvested mutagens to Redna.', 0, 0, 0, 0, 0, 0, 0, 0, 559162, 559161, 0, 0, 0, 0, 5, 1, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660011 Soaking the Masses [voljin] - Coldridge Valley - douse the townsfolk (item 559163, kills 161902)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660011, 2, 6, 3, 132, 0, 0, 4, 15, 0, 559163, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Soaking the Masses', 'Use the Radiation Sprayer to douse Radiaville’s townsfolk with radiation.', 'New around here?$b$bForgive me; might be I’ve run into you before, but my memory… it flickers, in and out, like a dying bulb.$b$bFriend or stranger, I could use your help. <Lahud stifles a guilty little giggle, clearly embarrassed.> Don’t think I’m trying to weasel out of my duty; I meant to do it, truly! But then I got woozy…$b$b<The gnome swallows back a burp and jerks upright, twitching as if he’d grabbed a live wire.>$b$bAll you need to do is spray a bit of blessed radiation on some of the townsfolk. You know, their weekly dose. Do this for me and I’ll be forever in your debt!', '', 'Speak with Lahud.', 161902, 0, 0, 0, 5, 0, 0, 0, 559163, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Radiant Devotees doused', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660018 Those Who Fell [darkmoon] - Zeb'Goro - only in the Darkmoon realm cache; item 559155 + provided stone 559158
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660018, 2, 6, 3, 363, 0, 0, 4, 0, 0, 559158, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Those Who Fell', 'Use the Unremarkable Stone to extract samples of spiritual unrest from the restless orcs and trolls, and present your findings to the witch of Zeb''Goro.', 'The spirits of the dead are restless. They torment us with dreams and visions that have already broken many among us. I have sought counsel with the elements, but… they will not answer me.$b$bTake this.$b$b<Esgramor places in your hand a stone far heavier than its modest size would suggest.>$b$bIt is a warding amulet. Go to the broken, to the tormented, and use the stone’s power to draw forth fragments of their unresting spirit. Gather what you can and bring them to the witch of Zeb’Goro. She is a sorceress of dreadful power and deep wisdom.$b$bI trust she will know what must be done.', '', 'Speak with Swa’li, the Witch’s right hand.', 0, 0, 0, 0, 0, 0, 0, 0, 559155, 559158, 0, 0, 0, 0, 5, 1, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660036 Oracular Idol [voljin] - Northshire - Shadewell Spring murloc oracles, collect 3x 559160
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660036, 2, 6, 3, 9, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Oracular Idol', 'Collect three Prophet’s Oracular Orbs from the murloc oracles roaming the Shadewell Spring.', '<After the spasms and convulsions of a brutal death, the murloc slumps into the wet earth, dropping a sphere that rolls to a stop at your boots.>$b$b<On closer inspection, you realize it’s no common jewel at all; it’s an eyeball. Its slick surface reflects vague images that do not match the world around you. It’s as if… it’s as if it shows you what’s yet to come.>$b$b<Perhaps you should strike down the other oracles and examine their strange, blind eyes.>', '', 'Find someone at the Abbey to share your discovery with.', 0, 0, 0, 0, 0, 0, 0, 0, 559160, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660039 Sever the Right Hand [voljin] - Radiance Town - defeat 161835
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660039, 2, 6, 3, 132, 0, 2, 3, 0, 0, 0, 8, 0, 0, 559176, 1, 559177, 1, 559178, 1, 559185, 1, 559186, 1, 559181, 1, 0, 0, 0, 'Sever the Right Hand', 'Defeat Right Hand of His Majesty in Radiance Town.', 'Have you run into the exile, Redna?$bShe pitched her camp on the hill just above us.$b$bLast time I spoke with her, she said something I haven’t been able to shake off:$b“The only one who’ll defend a lie fiercer than the liar is the fool who believed it.”$b$bThe one they call “The Right Hand of His Majesty” is living proof of that. He’s no ordinary follower; Redna swears he’s crueler, more despotic, and more fanatical than his master.$b$bIf you’ve the steel for it, cut him down while you’re making your way through Radiance Town. Then, report to Redna. She and him had… unfinished business.', '', 'Return to Redna.', 161835, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660058 Worm-Eaten Apple [voljin] - Goldshire - destroy kobold warrens (162940 x6), Clara the Mad
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660058, 2, 8, 5, 12, 0, 0, 5, 260, 337, 0, 8, 2302045, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 'Worm-Eaten Apple', 'Find and destroy the kobold warrens around Goldshire.', 'Whispers. They think no one''s noticed,but I sleep with my ear to the floor! Ha!$b$bThey dig and dig and dig. They''ll strike when you least expect it... unless you do something first.$b$bKobolds and kobolds and more kobolds. Under our feet! Watch where you step. Mind your footing!$b$bFind their warrens and set them alight. Crush them. With a big, heavy hammer!$b$b<She laughs to herself, then stares into the middle distance.>', '', 'Return to Clara the Mad.', 162940, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Kobold Warren Destroyed', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660059 Goldshire's Generosity [voljin] - Goldshire - harvest melons/pumpkins/apples for the refugees
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660059, 2, 8, 5, 12, 0, 0, 5, 156, 213, 0, 8, 0, 0, 2302050, 1, 2302055, 1, 2302060, 1, 0, 0, 0, 0, 0, 0, 72, 5, 0, 'Goldshire''s Generosity', 'Gather Melons, Pumpkins, and Apples from the farms around Goldshire. Then deliver them to Eldor Hammer, leader of the refugees.', 'Welcome.$b$bI am Thorm—Harvend Thorm—mayor of Goldshire, serving on behalf of Lord Bruk and his house.$b$bYou may have noticed the makeshift camp in the shadow of this grand hall. Of late, Goldshire has taken in countless refugees out of Westfall. At times I fear it''s beyond our means...$b$bEven so, I won''t turn away while they go hungry. Walk the village fields and take a little from each harvest to bring to the camp. You have my leave—and, by extension, Lord Bruk''s.', '', 'Deliver the basket of food to Eldor Hammer.', 0, 0, 0, 0, 0, 0, 0, 0, 558961, 558962, 558963, 0, 0, 0, 3, 3, 10, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660060 Stay a While [voljin] - Goldshire - listen to Aliscar Lend (162921)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660060, 2, 8, 5, 12, 0, 0, 3, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Aliscar Lend.', 'As it turns out, I''m the leading authority around here when it comes to the village''s history. Care for a short lesson?$b$b<The aging sorcerer seems eager, almost desperate, to talk.>$b$b<Perhaps he has something worth sharing.>', '', 'Say goodbye to Aliscar Lend.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Aliscar Lend', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660076 A Growing Business [voljin] - Kharanos - deliver word to Eyma Thunderbrew (talk quest)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660076, 2, 8, 5, 1, 0, 0, 4, 0, 0, 0, 8, 0, 0, 2302013, 1, 2302018, 1, 2302023, 1, 0, 0, 0, 0, 0, 0, 47, 5, 0, 'A Growing Business', 'Speak with Eyma Thunderbrew at the Thunderbrew Distillery in Kharanos.', '<The dwarf waves from afar to catch your eye; big sweeping arms at first, then he starts hopping in place.>$b$bWell met! <pants> I saw how you handled Groldha. I''m guessing you won''t be lingering in Anvilmar much longer...$b$bIf that''s the case and your feet carry you to Kharanos, I''ve a message that needs delivering.$b$bFind Eyma at the inn and tell her the talks in Anvilmar bore fruit. They want a shipment of our best ale; if it wins them over, we''ve got ourselves regular buyers. The ancestors smile on us, $C!', '', 'Speak with Eyma Thunderbrew.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660077 Thunderbrew's Hop [voljin] - Kharanos - pick 7x 558964 Thunderbrew Hops
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660077, 2, 8, 5, 1, 0, 0, 5, 260, 337, 0, 8, 0, 0, 2302028, 1, 2302033, 1, 2302038, 1, 0, 0, 0, 0, 0, 0, 47, 5, 0, 'Thunderbrew''s Hop', 'Harvest seven Thunderbrew Hops from the Thunderbrew Distillery grounds in Kharanos.', 'Nori must''ve seen something in you, to trust you with that message.$b$bSince you''re here, maybe you can lend a hand.$b$bStep out of the inn and look left; you''ll see the distillery''s hop yard. Special strain of hops, for the finest brew in all Dun Morogh.$b$bWe''re swamped today with customers. Would you mind picking hops and bringing them back to me? Hardly hero''s work, I know. But it pays, and it pays well.', '', 'Return to Eyma Thunderbrew.', 0, 0, 0, 0, 0, 0, 0, 0, 558964, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660079 Live-Fire Demo [voljin] - Kharanos - test the blunderbuss on targets (162917, item 558950)
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660079, 2, 8, 5, 1, 0, 0, 5, 83, 114, 558950, 8, 0, 0, 2302048, 1, 2302053, 1, 2302058, 1, 0, 0, 0, 0, 0, 0, 47, 5, 0, 'Live-Fire Demo', 'Test Gornarn''s Blunderbuss and ammo on the practice targets up on the ridge above Kharanos.', '<The dwarf braces a blunderbuss between his knees and runs a rod down the barrel; push, twist, pull, until the grime comes loose and spatters out.>$b$bSorry, didn''t notice I had an audience.$b$bFancy putting a few rounds downrange? Targets are always hungry for lead; with luck, we''ll catch a buyer''s eye.$b$bAll this ammunition isn''t going to sell itself.', '', 'Speak with Gornarn.', 162917, 0, 0, 0, 3, 0, 0, 0, 558950, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Target hit', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660081 Judging the Confessor [voljin] - Vaults of Inquisition (dungeon 10218) - kill 162999
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660081, 2, -1, 15, 10218, 81, 0, 6, 755, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Judging the Confessor', 'Slay Inquisitorial Confessor Konrad on Normal difficulty.', 'I have nothing to confess. Why do you keep beating me? I have nothing to confess, I swear...!$b$b<Another agonized scream, followed by a long silence. At last, he seems to register your presence.>$b$bThe Confessor. Kill him! I can''t take any more... He''s a torturer. A murderer. A monster worse than the creatures at his mercy.$b$bGive us peace. Get rid of him.', '', 'Return to the Tortured Ghost.', 162999, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660082 What Levels Us All [voljin] - Vaults of Inquisition (dungeon 10218) - clear the undead
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660082, 2, -1, 15, 10218, 81, 0, 6, 755, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'What Levels Us All', 'Slay the undead that dwell within the Vaults of Inquisition on Normal difficulty.', 'Please. Please...$b$b<The ghost moans and mumbles under his breath, lost in memories of the time he was captive of the Church.>$b$b<This place, you realize, is cursed. And the ghosts who haunt it now—prisoners and jailers alike—have been trapped here far too long.>$b$bEnough. Enough. Enough...$b$b<It would be an act of mercy to purge the dungeon and lay to rest every creature, ghost or not, that wanders its halls.>', '', 'Return to the Tortured Ghost.', 162736, 162705, 162735, 162733, 4, 5, 6, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'Phantasmal Bound', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660083 The Will of the Loa of Death [voljin] - Road to De Other Side (dungeon 10219) - kill 162988
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660083, 2, 15, 10, 10219, 81, 0, 6, 755, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Will of the Loa of Death', 'Defeat Vol''zeen, the dire undead troll on Normal difficulty.', 'Da Upstart Three were craftier than we thought.$b$bMy master Bwonsamdi be hatin'' da undead, and for dat very reason dey set one to guard their chimeric whelp.$b$bVol''zeen be his name; a dire troll, a blood-mad berserker, as dey be callin'' him.$b$bMe mojo be worthless against a t''ing like dat. Bring it down, and I''ll see ya paid in kind.', '', 'Return to Adlazin.', 162988, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660084 A Sinister Family [voljin] - Road to De Other Side (dungeon 10219) - kill the chimera's brood
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660084, 2, 15, 10, 10219, 81, 0, 6, 755, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Sinister Family', 'Defeat the bats, spiders, and hissers on the Road to De Other Side on Normal difficulty.', 'Though Hirsutta''s ritual was spoiled, da creature she tried to call from da world o'' flesh managed to force a part o'' itself into dis in-between.$b$bIt be a monstrous chimera. An abomination if ever there was.$b$bHir''eek, Dambala, and Shadra infested dis path to da Other Side. Somehow, I be thinkin'' its life be tied to da spirits of spider, serpent, and bat wanderin'' dese caverns.$b$bSlay dem all.$b$bMy lord Bwonsamdi will be generous.', '', 'Return to Adlazin.', 162782, 162770, 163814, 0, 8, 25, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 1660088 Vaults of Inquisition [voljin] - Vaults of Inquisition (dungeon 10218) - defeat 162704, party of five
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1660088, 2, 17, 10, 10218, 81, 5, 6, 1025, 0, 0, 8, 559377, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Vaults of Inquisition', 'Assemble a full party of five adventurers, descend into the perilous Vaults of Inquisition, and defeat the Presence of the Deceiver on Normal difficulty.', 'Something''s wrong, wrong! Terribly wrong!$b$b<Clara the Mad wrings her clammy hands in a nervous frenzy.>$b$bThe door has opened again. The seal is broken. Could it have been my sisters? Impossible. I''m not going back to Northshire. No!$b$b<Clara the Mad''s gaze pierces through you, wild, feverish.>$b$bYou do it! Silence the Voice! I’ll give you what little I have! They lied: “The Light will protect us,” they said. Ha! Now they''re all dead. All of them! Except her. All but her!$b$b<Clara laughs to herself before her eyes drift into the void.>', '', 'Return to Clara the Mad.', 162704, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Presence of the Deceiver slain', '', '', '', NULL)
ON DUPLICATE KEY UPDATE
`QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- 2. quest_template_addon -------------------------------------------------------------------

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660000, 1660001, 1660002, 1660003, 1660004, 1660005, 1660006, 1660007, 1660008, 1660009, 1660010, 1660011, 1660018, 1660036, 1660038, 1660039, 1660055, 1660056, 1660057, 1660058, 1660059, 1660060, 1660076, 1660077, 1660079, 1660081, 1660082, 1660083, 1660084, 1660088);

INSERT INTO `quest_template_addon` (`ID`, `ProvidedItemCount`) VALUES
(1660000, 0),
(1660001, 0),
(1660002, 0),
(1660003, 0),
(1660004, 0),
(1660005, 0),
(1660006, 0),
(1660007, 0),
(1660008, 0),
(1660009, 0),
(1660010, 1),
(1660011, 1),
(1660018, 1),
(1660036, 0),
(1660038, 0),
(1660039, 0),
(1660055, 0),
(1660056, 1),
(1660057, 0),
(1660058, 0),
(1660059, 0),
(1660060, 0),
(1660076, 0),
(1660077, 0),
(1660079, 1),
(1660081, 0),
(1660082, 0),
(1660083, 0),
(1660084, 0),
(1660088, 0);

-- 3. chain prerequisites --------------------------------------------------------------------

-- The Spada chain order, wired by design. Every prerequisite is a quest_template_addon
-- .PrevQuestID (positive = the previous quest must be rewarded first). 1660004 is the one
-- quest with two: it needs 1660038 through the chain and 1660003 through an availability
-- condition - two plain chain links would OR together (with several previous quests, one
-- rewarded is enough), and a shared negative ExclusiveGroup would also make 1660005 require
-- 1660038. The condition (type 8, quest rewarded; source 19 = quest available) is checked
-- on the offer, the gossip quest menu and the take, so 1660004 stays hidden until both
-- 1660003 and 1660038 are done. Live-apply: `.reload quest_template` + `.reload conditions`.

UPDATE `quest_template_addon` SET `PrevQuestID` = 1660000 WHERE `ID` = 1660001;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660001 WHERE `ID` = 1660002;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660002 WHERE `ID` = 1660003;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660002 WHERE `ID` = 1660038;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660038 WHERE `ID` = 1660004;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660003 WHERE `ID` = 1660005;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660004 WHERE `ID` = 1660055;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 19 AND `SourceEntry` = 1660004;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(19, 0, 1660004, 0, 0, 8, 0, 1660003, 0, 0, 0, 0, 0, '', 'Words that Shepherd Madness - Accursed Sisterhood (1660003) must be rewarded');

-- 4. quest 1660002 'The Ruins of Northshire' - reward text + Sister Alma's completion say ---------

-- Reward text as shown by the original server's complete-quest window (2026-09-29); the client
-- quest cache cannot carry it and the 09-16 backup ships `quest_offer_reward` empty for the
-- whole family. Breaks are stored as `$b$b`, the convention the family's own quest texts use
-- in this DB (see the 1660002 QuestDescription above): the client renders it as a break.
DELETE FROM `quest_offer_reward` WHERE `ID` = 1660002;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660002, 0, 0, 0, 0, 0, 0, 0, 0, 'The way is shut, mortal.$b$bThe dungeon is home to the Dead, and the Dead keep it so.$b$bJailers in life, prisoners in death... all of us, victims of her curse.$b$bThe way is shut.', NULL);

-- Sister Alma says the opening line out loud when the quest is completed - same shape as the
-- other preset say lines in this file: creature_text type 12 (monster say) + a SmartAI TALK row.
-- Event 20 (quest rewarded) fires on the NPC the reward was taken from:
-- SmartAI::sQuestReward() -> SMART_EVENT_REWARD_QUEST. The row is spawn-scoped (-7500316, her
-- only spawn): a spawn script replaces the unit's entry script, so a single-spawn unit's rows
-- live on its spawn id.
DELETE FROM `creature_text` WHERE `CreatureID` = 161702 AND `GroupID` = 0 AND `ID` = 0;

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`)
VALUES
(161702, 0, 0, 'The way is shut, mortal.', 12, 0, 100, 0, 0, 0, 0);

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161702;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161702 AND `source_type` = 0;

DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500316 AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-7500316, 0, 0, 0, 20, 0, 100, 0, 1660002, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Sister Alma - quest 1660002 rewarded - say the completion line');

-- 5. quest 1660005 'The Threat Swept Downstream' - reward text ---------------------------------

-- Reward text as shown by the original server's complete-quest window (2026-09-29, supplied by
-- the client owner): the guard's breathless thanks. `$b$b` breaks as in 1660002 above.
DELETE FROM `quest_offer_reward` WHERE `ID` = 1660005;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660005, 0, 0, 0, 0, 0, 0, 0, 0, 'You did it.... <he gasps for breath.>$b$bIt shames the uniform I wear with such pride that I had to turn to someone outside the army.$b$bIt should have been my duty to see it done, but, as you can see, I haven''t the strength to even limp back to the Abbey.$b$bStormwind owes you thanks, Guardian... and so do I.', NULL);

-- 6. quest 1660036 'Oracular Idol' - request-items + reward texts ------------------------------

-- Both windows supplied by the client owner from the original server (2026-09-29): the
-- request-items window ("Can I help you with something, child?" - shown with the Required Items
-- list while the three Prophet's Oracular Orbs are still needed) and the complete-quest window
-- text (the priest's lecture). `$b$b` breaks as above.
DELETE FROM `quest_request_items` WHERE `ID` = 1660036;

INSERT INTO `quest_request_items`
(`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`)
VALUES
(1660036, 0, 0, 'Can I help you with something, child?', NULL);

DELETE FROM `quest_offer_reward` WHERE `ID` = 1660036;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660036, 0, 0, 0, 0, 0, 0, 0, 0, '<The priest listens intently as you recount the events.>$b$bAn interesting discovery.$b$bIt is curious... almost every saint to whom we ascribe visions suffered some form of blindness.$b$bIn any case <he tosses the murloc eyes into the waste bin> only the Light knows what the future holds.$b$bWhatever you think you saw in these heretical creatures was nothing but deception. Murlocs are an insult to the human spirit. Best you put this curiosity of yours to rest.', NULL);

-- 7. quest 1660004 'Words that Shepherd Madness' - reward text -------------------------------

-- Reward text as shown by the original server's complete-quest window (2026-09-29, supplied by
-- the client owner): Moroi Spada's reply. `$b$b` breaks as above; the companion's name is the
-- `$N` player-name substitution (the screenshot's name is a player character - it exists
-- nowhere on this server, and the position matches Blizzard's own `$N` texts).
DELETE FROM `quest_offer_reward` WHERE `ID` = 1660004;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660004, 0, 0, 0, 0, 0, 0, 0, 0, '<Moroi listens to your account intently.>$b$bThey say the pen is mightier than the sword, and Sitis... fitting name. It means "thirst." From what you''ve told me, she was a woman thirsty for truth and knowledge.$b$bI hardly think that''s a sin.$b$bHere''s my plan, $N: I''ll go with my sister, say my goodbyes to my mother, and on my way back to the abbey, I''ll stop by that place you spoke of, where Sitis held her most daring gatherings.$b$b"There is no darkness but ignorance." I thank you for the warning, but my mind won''t rest until I uncover the truth... no matter the risks you''ve mentioned.', NULL);

-- 8. quest 1660000 'Bookworm' - reward text --------------------------------------------------

-- Reward text as shown by the original server's complete-quest window (2026-09-29, supplied by
-- the client owner): Moroi Spada greets the player his sister sent. `$b$b` breaks as above.
DELETE FROM `quest_offer_reward` WHERE `ID` = 1660000;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660000, 0, 0, 0, 0, 0, 0, 0, 0, 'Did my sister send you, by any chance?$b$bI already told her this isn''t a good time; although honestly, there''s never a good time to deal with her.$b$bAnyway, I''m in the middle of a discovery that... has me completely absorbed. Maybe you''d be interested in lending a hand?', NULL);

-- 9. quest 1660001 'Knowledge Corrupts' - request-items + reward texts -------------------------

-- Both windows supplied by the client owner from the original server (2026-09-29): the
-- request-items window while the four Lost Pages are still needed, and the complete-quest
-- window (Moroi going through the pages). `$b$b` breaks as above.
DELETE FROM `quest_request_items` WHERE `ID` = 1660001;

INSERT INTO `quest_request_items`
(`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`)
VALUES
(1660001, 0, 0, 'Have you found the pages?', NULL);

DELETE FROM `quest_offer_reward` WHERE `ID` = 1660001;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660001, 0, 0, 0, 0, 0, 0, 0, 0, 'Well, what do we have here?$b$b<Moroi eagerly inspects the pages you''ve brought him.>$b$bThat clears up a few gaps: the abbess accused of heresy was tried by the Inquisition and excommunicated. No wonder the Church wanted the whole thing wiped from the records. It''s almost a miracle they forgot to burn this book.$b$bMakes you wonder what she did to earn such a punishment, doesn''t it?', NULL);

-- 10. quest 1660003 'Accursed Sisterhood' - reward text ----------------------------------------

-- Reward text as shown by the original server's complete-quest window (2026-09-29, supplied by
-- the client owner): Sister Alma reveals herself at the end of the dungeon. `$b$b` breaks as above.
DELETE FROM `quest_offer_reward` WHERE `ID` = 1660003;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660003, 0, 0, 0, 0, 0, 0, 0, 0, 'The curse...$b$bThe way has opened. I can feel it; a warm light calling my spirit elsewhere.$b$b<The priestess seems more awake, more aware than before.>$b$bI was once called Sister Alma, priestess of Northshire Abbey.$b$bYou came down here seeking knowledge. You''re not the first. But I trust you''ll be the last.$b$bVery well. I will tell you about Sitis.', NULL);

-- 11. quest 1660038 'The Saddest Among Us' - reward text ----------------------------------------

-- Reward text as shown by the original server's complete-quest window (2026-09-29, supplied by
-- the client owner): Alma sends the player off to the reward choice. `$b$b` breaks as above.
-- The six reward choices (559176-559181) are already set on the quest row by the cache import.
DELETE FROM `quest_offer_reward` WHERE `ID` = 1660038;

INSERT INTO `quest_offer_reward`
(`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`)
VALUES
(1660038, 0, 0, 0, 0, 0, 0, 0, 0, 'The fire cannot burn forever without someone to indulge its whims.$b$bBy killing him, you''ve set him free. Now the flames must content themselves with licking his bones until both are dust and ash.$b$bBut these chambers hold more than dust and ash... Choose your reward, mortal.', NULL);

SET @CGUID  := 7500349;
SET @OGUID  := 6940013;
SET @PATH   := 799480;

-- creature_addon ------------------------------------------------------------------------
DELETE FROM `creature_addon` WHERE `guid` = @CGUID;
INSERT INTO `creature_addon`
  (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
   `auras`) VALUES
  (@CGUID, 0, 0, 8, 1, 672, 0, '8326')
ON DUPLICATE KEY UPDATE `path_id` = VALUES(`path_id`), `mount` = VALUES(`mount`),
  `emote` = VALUES(`emote`), `auras` = VALUES(`auras`),
  `bytes1` = (`bytes1` & 0xFFFFFF00) | (VALUES(`bytes1`) & 0xFF);

-- smart_scripts -------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500315 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500251 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -80183 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
INSERT INTO `smart_scripts`
  (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
   `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
   `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
   `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
   `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
   `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
  (-7500315, 0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
   0.000000, 0.000000, 0.000000, 0.000000,
   'Update IC -> Set Health PCT (percent=10) at Self'),
  (-7500251, 0, 0, 0, 1, 0, 100, 0, 60000, 60000, 120000, 120000, 0, 0, 1, 0, 0, 0, 0, 0, 0,
   1, 0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Preset: says its line while it is out of combat, first after 60s, then every 120s.'),
  (-80183, 0, 0, 0, 1, 0, 100, 0, 15000, 15000, 60000, 60000, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1,
   0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Preset: says its line while it is out of combat, first after 15s, then every 60s.');

-- creature_text -------------------------------------------------------------------------
DELETE FROM `creature_text` WHERE `CreatureID` = 38 AND `GroupID` = 0 AND `ID` = 0;
DELETE FROM `creature_text` WHERE `CreatureID` = 38 AND `GroupID` = 1 AND `ID` = 0;
DELETE FROM `creature_text` WHERE `CreatureID` = 161700 AND `GroupID` = 0 AND `ID` = 0;
INSERT INTO `creature_text`
  (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
   `Duration`, `Sound`, `BroadcastTextId`) VALUES
  (38, 1, 0, 'IT''S BEEN HALF AN HOUR GET OUTTA THERE!!', 12, 0, 100, 0, 0, 0, 0),
  (161700, 0, 0,
   'Moroi, I know you''re in there! We don''t have all day. Mother doesn''t either! Get out here you scoundrel!',
   12, 0, 100, 0, 0, 0, 0);

-- waypoint_data -------------------------------------------------------------------------
DELETE FROM `waypoint_data` WHERE `id` = @PATH;
INSERT INTO `waypoint_data`
  (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`,
   `move_type`, `action`, `action_chance`) VALUES
  (@PATH, 1, -8998.910000, -85.836200, 85.953000, NULL, 180000, 0, 0, 100),
  (@PATH, 2, -8985.990000, -98.679400, 85.521200, NULL, 0, 0, 0, 100),
  (@PATH, 3, -8985.990000, -98.679400, 85.521200, NULL, 0, 0, 0, 100),
  (@PATH, 4, -8973.210000, -112.158000, 84.364500, NULL, 0, 0, 0, 100),
  (@PATH, 5, -8942.790000, -112.881000, 82.871200, NULL, 0, 0, 0, 100),
  (@PATH, 6, -8928.890000, -115.532000, 82.538600, NULL, 0, 0, 0, 100),
  (@PATH, 7, -8915.750000, -131.645000, 80.884500, NULL, 0, 0, 0, 100),
  (@PATH, 8, -8914.440000, -134.267000, 80.552300, NULL, 0, 0, 0, 100),
  (@PATH, 9, -8921.773906, -122.046953, 81.922486, NULL, 0, 0, 0, 100),
  (@PATH, 10, -8933.160000, -114.324000, 82.587900, NULL, 0, 0, 0, 100),
  (@PATH, 11, -8949.460000, -112.983000, 83.121200, NULL, 0, 0, 0, 100),
  (@PATH, 12, -8966.530000, -114.035000, 83.874400, NULL, 0, 0, 0, 100),
  (@PATH, 13, -8978.180000, -108.689000, 84.975600, NULL, 0, 0, 0, 100),
  (@PATH, 14, -8991.040000, -93.846200, 85.795800, NULL, 0, 0, 0, 100),
  (@PATH, 15, -8998.500000, -86.373000, 85.836400, NULL, 0, 0, 0, 100),
  (@PATH, 16, -9005.460000, -86.230500, 86.152900, NULL, 0, 0, 0, 100),
  (@PATH, 17, -9013.070000, -88.455100, 86.522500, NULL, 0, 0, 0, 100),
  (@PATH, 18, -9018.740000, -92.921900, 86.866300, NULL, 0, 0, 0, 100),
  (@PATH, 19, -9024.940000, -98.152300, 87.297800, NULL, 0, 0, 0, 100),
  (@PATH, 20, -9033.030000, -100.896000, 87.608100, NULL, 0, 0, 0, 100),
  (@PATH, 21, -9040.210000, -99.923800, 87.871700, NULL, 0, 0, 0, 100),
  (@PATH, 22, -9045.310000, -95.843800, 88.040300, NULL, 0, 0, 0, 100),
  (@PATH, 23, -9049.690000, -89.689500, 87.987300, NULL, 0, 0, 0, 100),
  (@PATH, 24, -9050.380000, -83.107400, 88.124400, NULL, 0, 0, 0, 100),
  (@PATH, 25, -9048.630000, -74.402300, 88.157400, NULL, 0, 0, 0, 100),
  (@PATH, 26, -9046.780000, -65.261700, 88.156100, NULL, 0, 0, 0, 100),
  (@PATH, 27, -9046.120000, -57.599600, 88.153800, NULL, 0, 0, 0, 100),
  (@PATH, 28, -9048.030000, -49.078100, 88.272900, NULL, 0, 0, 0, 100),
  (@PATH, 29, -9048.800000, -43.168000, 88.275600, NULL, 0, 0, 0, 100),
  (@PATH, 30, -9044.530000, -38.246100, 88.284700, NULL, 0, 0, 0, 100),
  (@PATH, 31, -9040.420000, -28.103500, 88.249200, NULL, 0, 0, 0, 100),
  (@PATH, 32, -9039.940000, -18.021500, 88.241800, NULL, 0, 0, 0, 100),
  (@PATH, 33, -9038.960000, -9.701170, 88.241800, NULL, 0, 0, 0, 100),
  (@PATH, 34, -9036.630000, -3.468750, 88.411900, NULL, 0, 0, 0, 100),
  (@PATH, 35, -9034.060000, 0.621094, 88.333500, NULL, 0, 0, 0, 100),
  (@PATH, 36, -9027.980000, 4.427730, 88.223600, NULL, 0, 0, 0, 100),
  (@PATH, 37, -9021.290000, 3.453120, 88.353800, NULL, 0, 0, 0, 100),
  (@PATH, 38, -9015.470000, -1.623050, 88.755000, NULL, 0, 0, 0, 100),
  (@PATH, 39, -9013.060000, -10.814500, 88.450800, NULL, 0, 0, 0, 100),
  (@PATH, 40, -9010.390000, -20.392600, 88.326800, NULL, 0, 0, 0, 100),
  (@PATH, 41, -9008.880000, -28.046900, 88.344500, NULL, 0, 0, 0, 100),
  (@PATH, 42, -9009.540000, -36.908200, 87.942500, NULL, 0, 0, 0, 100),
  (@PATH, 43, -9010.120000, -46.224600, 87.435900, NULL, 0, 0, 0, 100),
  (@PATH, 44, -9010.210000, -55.498000, 87.201800, NULL, 0, 0, 0, 100),
  (@PATH, 45, -9009.280000, -62.769500, 87.035500, NULL, 0, 0, 0, 100),
  (@PATH, 46, -9006.920000, -70.160200, 86.626100, NULL, 0, 0, 0, 100),
  (@PATH, 47, -9003.910000, -76.117200, 86.339100, NULL, 0, 0, 0, 100),
  (@PATH, 48, -8999.900000, -84.332000, 85.961800, NULL, 45000, 0, 0, 100);

SET @CGUID  := 7500347;
SET @OGUID  := 6960007;

-- creature_addon ------------------------------------------------------------------------
DELETE FROM `creature_addon` WHERE `guid` = @CGUID;
INSERT INTO `creature_addon`
  (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
   `auras`) VALUES
  (@CGUID, 0, 0, 0, 1, 0, 0, NULL)
ON DUPLICATE KEY UPDATE `path_id` = VALUES(`path_id`), `mount` = VALUES(`mount`),
  `emote` = VALUES(`emote`), `auras` = VALUES(`auras`),
  `bytes1` = (`bytes1` & 0xFFFFFF00) | (VALUES(`bytes1`) & 0xFF);

-- smart_scripts -------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500315 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500251 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -80183 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
INSERT INTO `smart_scripts`
  (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
   `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
   `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`,
   `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
   `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
   `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
  (-7500315, 0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
   0.000000, 0.000000, 0.000000, 0.000000,
   'Update IC -> Set Health PCT (percent=10) at Self'),
  (-7500251, 0, 0, 0, 1, 0, 100, 0, 60000, 60000, 120000, 120000, 0, 0, 1, 0, 0, 0, 0, 0, 0,
   1, 0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Preset: says its line while it is out of combat, first after 60s, then every 120s.'),
  (-80183, 0, 0, 0, 1, 0, 100, 0, 15000, 15000, 60000, 60000, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1,
   0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000,
   'Preset: says its line while it is out of combat, first after 15s, then every 60s.');

-- creature_text -------------------------------------------------------------------------
DELETE FROM `creature_text` WHERE `CreatureID` = 38 AND `GroupID` = 0 AND `ID` = 0;
DELETE FROM `creature_text` WHERE `CreatureID` = 38 AND `GroupID` = 1 AND `ID` = 0;
DELETE FROM `creature_text` WHERE `CreatureID` = 161700 AND `GroupID` = 0 AND `ID` = 0;
INSERT INTO `creature_text`
  (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
   `Duration`, `Sound`, `BroadcastTextId`) VALUES
  (38, 1, 0, 'IT''S BEEN HALF AN HOUR GET OUTTA THERE!!', 12, 0, 100, 0, 0, 0, 0),
  (161700, 0, 0,
   'Moroi, I know you''re in there! We don''t have all day. Mother doesn''t either! Get out here you scoundrel!',
   12, 0, 100, 0, 0, 0, 0);

-- ##########################################################################################
-- SECTION 11 - live-world reconciliation (edits, masks, props)
-- ##########################################################################################

-- ==========================================================================================
-- Live-world reconciliation (2026-09-29): the remaining differences between the
-- previous acore_world (the world the family content was authored on, backed up before the
-- rebuild) and a fresh core + world layer + family import. Generated by comparing the live
-- backup against the rebuilt world
-- (scratch DBs acore_live / acore_core) on 2026-09-29.
--
--   1. additions  - live-only rows: the 9000xxx Northshire spawns (three of them
--                   renumbered to 9000141-143 because the new module content took
--                   over guids 9000027/28/31), their addons, and the Elwynn scene
--                   props (trees, collision cylinders, bushes, banner). The old
--                   disabled Living Heresy stub 9000135 is NOT restored - the
--                   spada file's cleaning pass removes it for good.
--   2. removals   - rows the live world deliberately deleted (stock Northshire spam
--                   spawns, the Spada-house mailbox, the old campfire/props, and the
--                   northshire layer's extra censor spawn 7500351).
--   3. edits      - value fixes on rows present in both worlds (positions,
--                   orientations, movement/wander values; float tails under 0.005 are
--                   treated as noise and not emitted).
--   4. spawn masks- the package baseline sets spawnMask 15 on the classic instances;
--                   the live world uses 1 (raids) / 3 (dungeons) - reconciled per map.
--
-- Safe to re-import: additions are delete-and-reinsert, removals are deletes, the
-- edits and mask fixes target fixed values.
-- ==========================================================================================

-- 1. additions ---------------------------------------------------------------------------

DELETE FROM `creature_addon` WHERE `guid` IN (79945, 79960, 79961, 9000029, 9000033);

INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(79945, 799450, 0, 0, 1, 0, 0, ''),
(79960, 0, 0, 0, 1, 0, 0, NULL),
(79961, 0, 0, 0, 1, 0, 0, NULL),
(9000029, 0, 0, 1, 1, 69, 0, NULL),
(9000033, 0, 0, 1, 1, 0, 0, NULL);

-- 2. removals ----------------------------------------------------------------------------

DELETE FROM `creature_addon` WHERE `guid` IN (79963, 80100, 80103, 80105, 80106, 80107, 80116, 80122, 80132, 80189, 80193, 7500351);

-- 3. edits -------------------------------------------------------------------------------

UPDATE `creature` SET `position_x` = -9002.68, `position_y` = -85.957, `position_z` = 86.1193, `orientation` = 5.74207 WHERE `guid` = 79927;
UPDATE `creature` SET `position_x` = -9000.18, `position_y` = -82.2266, `position_z` = 86.0087, `orientation` = 5.67697 WHERE `guid` = 79932;
UPDATE `creature` SET `MovementType` = 2 WHERE `guid` = 79945;
UPDATE `creature` SET `position_x` = -8999.16, `position_y` = -85.7734, `position_z` = 85.8892, `orientation` = 5.61053 WHERE `guid` = 79948;
UPDATE `creature` SET `position_x` = -8661.55, `position_y` = -197.604, `position_z` = 94.228 WHERE `guid` = 80062;
UPDATE `creature` SET `position_x` = -8694.16, `position_y` = -196.834, `position_z` = 91.6739 WHERE `guid` = 80063;
UPDATE `creature` SET `position_x` = -8998.44, `position_y` = -305.902, `position_z` = 71.5015, `orientation` = 0.712786 WHERE `guid` = 80147;
UPDATE `creature` SET `position_x` = -8888.75, `position_y` = -374.73, `position_z` = 71.1336 WHERE `guid` = 80241;
UPDATE `creature` SET `position_x` = -8880.75, `position_y` = -358.545, `position_z` = 72.6291 WHERE `guid` = 80253;
UPDATE `creature` SET `position_x` = -8930.62, `position_y` = -357.867, `position_z` = 72.3166 WHERE `guid` = 80257;
UPDATE `creature` SET `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 7500125;
UPDATE `creature` SET `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 7500126;
UPDATE `creature` SET `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 7500128;
UPDATE `creature` SET `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 7500133;
UPDATE `creature` SET `position_x` = -8993.93, `position_y` = -311.092, `position_z` = 71.5079, `orientation` = 1.43763, `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 7500280;
UPDATE `creature` SET `wander_distance` = 5 WHERE `guid` = 7500296;
UPDATE `creature` SET `wander_distance` = 5 WHERE `guid` = 7500298;
UPDATE `creature` SET `position_x` = -8787.74, `position_y` = -284.689, `position_z` = 75.8946, `wander_distance` = 5 WHERE `guid` = 7500299;
UPDATE `creature` SET `position_x` = -8752.88, `position_y` = -306.348, `position_z` = 78.1719, `wander_distance` = 5 WHERE `guid` = 7500301;
UPDATE `creature` SET `position_x` = -8775.32, `position_y` = -264.6, `position_z` = 79.1598 WHERE `guid` = 7500303;
UPDATE `creature` SET `orientation` = 0.649884 WHERE `guid` = 7500306;
UPDATE `creature` SET `position_x` = -8807.3, `position_y` = -395.521, `position_z` = 110.378, `orientation` = 5.6383, `MovementType` = 2 WHERE `guid` = 7500310;
UPDATE `creature` SET `wander_distance` = 5 WHERE `guid` = 7500311;
UPDATE `creature` SET `wander_distance` = 5 WHERE `guid` = 7500312;
UPDATE `creature` SET `MovementType` = 2 WHERE `guid` = 7500313;
UPDATE `creature` SET `wander_distance` = 5, `MovementType` = 1 WHERE `guid` = 7500319;

UPDATE `gameobject` SET `rotation0` = -0.0330791, `rotation1` = -0.0376265 WHERE `guid` = 6940869;
UPDATE `gameobject` SET `position_x` = -8753.7, `position_y` = -395.928, `position_z` = 68.4003 WHERE `guid` = 6941326;
UPDATE `gameobject` SET `position_x` = -8672.01, `position_y` = -189.836 WHERE `guid` = 7500100;
UPDATE `gameobject` SET `rotation0` = -0.0262612, `rotation1` = 0.0997537, `rotation3` = -0.959568 WHERE `guid` = 7500134;
UPDATE `gameobject` SET `orientation` = 2.22484, `rotation0` = -0.616593, `rotation1` = 0.458993, `rotation2` = 0.573611, `rotation3` = 0.283035 WHERE `guid` = 7500136;
UPDATE `gameobject` SET `orientation` = 1.09413, `rotation0` = -0.218834, `rotation1` = 0.679026, `rotation2` = 0.364514, `rotation3` = 0.598469 WHERE `guid` = 7500140;
UPDATE `gameobject` SET `orientation` = 2.57734, `rotation0` = -0.0789274, `rotation1` = -0.0372665, `rotation3` = 0.277337 WHERE `guid` = 7500211;
UPDATE `gameobject` SET `orientation` = 5.76141, `rotation0` = -0.0617178, `rotation1` = 0.137727, `rotation2` = 0.254983, `rotation3` = -0.955095 WHERE `guid` = 7500212;

-- 4. spawn masks -------------------------------------------------------------------------

UPDATE `creature` SET `spawnMask` = 1 WHERE `map` IN (309, 531, 509, 469, 409) AND `spawnMask` = 15;

UPDATE `creature` SET `spawnMask` = 3 WHERE `map` IN (249) AND `spawnMask` = 15;

UPDATE `gameobject` SET `spawnMask` = 1 WHERE `map` IN (309, 469, 409, 531, 509) AND `spawnMask` = 15;

UPDATE `gameobject` SET `spawnMask` = 3 WHERE `map` IN (249) AND `spawnMask` = 15;

-- ##########################################################################################
-- SECTION 12 - field-level corrections
-- ##########################################################################################

-- ============================================================================
-- live_reconciliation_fields.sql  --  field-level reconciliation (part 10/10)
--
-- Generated 2026-09-29 15:17.
-- Source of truth: the pre-rebuild world (acore_live) compared FIELD BY FIELD
-- against the freshly rebuilt world (acore_world). Rows the old world only had
-- are re-created; rows whose column values drifted are set back to the old world's
-- exact values. Rules:
--   * live-only rows      -> DELETE + INSERT from the old world
--   * changed rows        -> UPDATE to the old world's values, except
--       - rows equal to the shape schema in the base core keep the fresh values
--         (they carry new content pulled after the old world was built),
--       - an explicit keeper list (module-managed rows: Book of Artisans 57500,
--         the worldforged pickup spawns, the renumbered 9000027/28/31 rows).
-- Applies to a freshly rebuilt database; re-running on the old world is a no-op.
-- ============================================================================

-- Tables with no differences and no writes: acore_string, creature_display_preset, creature_loot_template, creature_model_info, creature_questender, creature_queststarter, creature_template_addon, creature_template_model, creature_template_movement, creature_text, creaturedisplayinfo_dbc, creaturedisplayinfoextra_dbc, gameobject_loot_template, gossip_menu, gossip_menu_option, item_template, npc_text, smart_scripts, spell_dbc, spell_script_names

-- ----------------------------------------------------------------------------
-- creature_template: 14 update(s), 0 re-created row(s)
-- ----------------------------------------------------------------------------

UPDATE `creature_template` SET `faction` = 17 WHERE `entry` = 38;
UPDATE `creature_template` SET `name` = 'Timber Wolf' WHERE `entry` = 69;
UPDATE `creature_template` SET `faction` = 17 WHERE `entry` = 103;
UPDATE `creature_template` SET `name` = 'Young Wolf' WHERE `entry` = 299;
UPDATE `creature_template` SET `faction` = 17, `lootid` = 38, `pickpocketloot` = 38, `mingold` = 1, `maxgold` = 5 WHERE `entry` = 537;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161700;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161705;
UPDATE `creature_template` SET `maxlevel` = 4 WHERE `entry` = 161708;
UPDATE `creature_template` SET `BaseAttackTime` = 0, `RangeAttackTime` = 0 WHERE `entry` = 161711;
UPDATE `creature_template` SET `lootid` = 38, `pickpocketloot` = 38, `mingold` = 1, `maxgold` = 5 WHERE `entry` = 161713;
UPDATE `creature_template` SET `maxlevel` = 4 WHERE `entry` = 161716;
UPDATE `creature_template` SET `minlevel` = 3, `maxlevel` = 4 WHERE `entry` = 161717;
UPDATE `creature_template` SET `maxlevel` = 4, `faction` = 17, `lootid` = 38, `pickpocketloot` = 38, `mingold` = 1, `maxgold` = 5 WHERE `entry` = 161736;
UPDATE `creature_template` SET `minlevel` = 60, `maxlevel` = 60 WHERE `entry` = 10157356;

-- ----------------------------------------------------------------------------
-- creature_addon: 26 update(s), 0 re-created row(s)
-- ----------------------------------------------------------------------------

UPDATE `creature_addon` SET `mount` = 2410 WHERE `guid` = 79927;
UPDATE `creature_addon` SET `mount` = 2410 WHERE `guid` = 79932;
UPDATE `creature_addon` SET `mount` = 2410 WHERE `guid` = 79948;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500002;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500125;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500126;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500128;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500133;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500296;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500298;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500299;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500301;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500303;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500306;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500307;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500308;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500309;
UPDATE `creature_addon` SET `path_id` = 75003100, `bytes1` = 0, `auras` = NULL WHERE `guid` = 7500310;
UPDATE `creature_addon` SET `bytes1` = 0, `auras` = NULL WHERE `guid` = 7500311;
UPDATE `creature_addon` SET `bytes1` = 0, `auras` = NULL WHERE `guid` = 7500312;
UPDATE `creature_addon` SET `path_id` = 75003130, `bytes1` = 0, `auras` = NULL WHERE `guid` = 7500313;
UPDATE `creature_addon` SET `bytes1` = 0, `auras` = NULL WHERE `guid` = 7500314;
UPDATE `creature_addon` SET `bytes1` = 8, `auras` = NULL WHERE `guid` = 7500315;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500319;
UPDATE `creature_addon` SET `auras` = NULL WHERE `guid` = 7500322;
UPDATE `creature_addon` SET `bytes1` = 0, `auras` = NULL WHERE `guid` = 7500372;

-- ----------------------------------------------------------------------------
-- creature: 35 update(s), 0 re-created row(s)
-- ----------------------------------------------------------------------------

UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 79927;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 79932;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 79945;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 79948;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 79960;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 79961;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 80062;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 80063;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 80147;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 80241;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 80253;
UPDATE `creature` SET `VerifiedBuild` = NULL WHERE `guid` = 80257;
UPDATE `creature` SET `npcflag` = 1, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500002;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500125;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500126;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500128;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500133;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500280;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500296;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500298;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500299;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500301;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500303;
UPDATE `creature` SET `unit_flags` = 33555200, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500306;
UPDATE `creature` SET `unit_flags` = 33555200, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500307;
UPDATE `creature` SET `unit_flags` = 33555200, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500308;
UPDATE `creature` SET `unit_flags` = 33555200, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500309;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500310;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500311;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500312;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500313;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500314;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500319;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500322;
UPDATE `creature` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500372;

-- ----------------------------------------------------------------------------
-- creature_formations: 0 update(s), 3 re-created row(s)
-- ----------------------------------------------------------------------------

DELETE FROM `creature_formations` WHERE `memberGUID` = 79927;
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES (79948, 79927, 3.52822, 221.523, 515, 0, 0);
DELETE FROM `creature_formations` WHERE `memberGUID` = 79932;
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES (79948, 79932, 3.69104, 144.606, 515, 0, 0);
DELETE FROM `creature_formations` WHERE `memberGUID` = 79948;
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES (79948, 79948, 0, 0, 515, 0, 0);

-- ----------------------------------------------------------------------------
-- waypoint_data: 14 update(s), 65 re-created row(s)
-- ----------------------------------------------------------------------------

UPDATE `waypoint_data` SET `position_x` = -8946.63, `position_y` = -341.17, `position_z` = 71.5234 WHERE `id` = 801490 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8934, `position_y` = -348.716, `position_z` = 72.2953, `orientation` = NULL WHERE `id` = 801490 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -8912.77, `position_y` = -352.085, `position_z` = 72.5823, `orientation` = 5.88143 WHERE `id` = 801490 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -8883.71, `position_y` = -361.67, `position_z` = 72.2116, `orientation` = 6.17595, `move_type` = 1 WHERE `id` = 801490 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = -8886.21, `position_y` = -350.573, `position_z` = 72.4008, `orientation` = 2.81837 WHERE `id` = 801490 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -8898.48, `position_y` = -345.141, `position_z` = 70.8293, `orientation` = 2.75397 WHERE `id` = 801490 AND `point` = 8;
UPDATE `waypoint_data` SET `position_x` = -8910.54, `position_y` = -349.637, `position_z` = 71.9803, `orientation` = 2.95582 WHERE `id` = 801490 AND `point` = 9;
UPDATE `waypoint_data` SET `position_x` = -8936.12, `position_y` = -348.222, `position_z` = 72.043, `orientation` = 2.87728, `delay` = 0, `action` = 0 WHERE `id` = 801490 AND `point` = 10;
UPDATE `waypoint_data` SET `position_x` = -8889.86, `position_y` = -373.091, `position_z` = 71.3316 WHERE `id` = 802410 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8931.27, `position_y` = -362.219, `position_z` = 72.3597 WHERE `id` = 802410 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8902.94, `position_y` = -391.85, `position_z` = 68.925 WHERE `id` = 802410 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8892.6, `position_y` = -386.461, `position_z` = 68.9633 WHERE `id` = 802410 AND `point` = 15;
UPDATE `waypoint_data` SET `position_x` = -8888.8, `position_y` = -376.817, `position_z` = 70.7684 WHERE `id` = 802410 AND `point` = 16;
UPDATE `waypoint_data` SET `position_x` = -8875, `position_y` = -375.454, `position_z` = 70.3252 WHERE `id` = 802510 AND `point` = 9;
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 1;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 1, -9002.24, -149.281, 82.3183, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 2;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 2, -9010.55, -146.629, 83.6636, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 3;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 3, -9021.07, -152.857, 82.6652, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 4;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 4, -9027.48, -161.201, 79.9164, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 5;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 5, -9029.44, -169.547, 78.1557, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 6;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 6, -9025.71, -181.021, 76.3219, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 7;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 7, -9018.04, -191.318, 76.0901, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 8;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 8, -9007.63, -193.895, 75.3846, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 9;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 9, -8993.88, -190.152, 75.661, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 10;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 10, -8988.32, -180.844, 76.7073, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 11;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 11, -8988.05, -168.438, 78.4544, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 799450 AND `point` = 12;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (799450, 12, -8992.25, -158.006, 80.0037, NULL, 0, 0, 0, 1, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 801490 AND `point` = 11;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (801490, 11, -8940.77, -340.701, 71.1274, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 801490 AND `point` = 12;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (801490, 12, -9008.89, -320.603, 75.8279, 2.8812, 0, 25000, 0, 0, 8014900, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 1;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 1, -8807.16, -395.588, 110.378, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 2;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 2, -8798.2, -401.625, 108.456, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 3;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 3, -8788.39, -408.115, 107.616, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 4;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 4, -8778.3, -414.811, 109.271, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 5;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 5, -8766.65, -422.631, 114.425, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 6;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 6, -8757.71, -428.518, 121.379, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 7;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 7, -8749.09, -435.176, 131.719, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 8;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 8, -8745.65, -442.984, 135.448, NULL, 0, 7500, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 9;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 9, -8749.37, -435.379, 131.698, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 10;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 10, -8757.56, -428.643, 121.544, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 11;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 11, -8767.1, -422.018, 114.077, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 12;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 12, -8778.43, -414.807, 109.246, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 13;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 13, -8788.29, -408.072, 107.619, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 14;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 14, -8798.4, -401.904, 108.454, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003100 AND `point` = 15;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003100, 15, -8806.97, -395.906, 110.378, NULL, 0, 4500, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 1;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 1, -8813.96, -395.232, 110.378, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 2;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 2, -8815.46, -385.129, 104.795, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 3;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 3, -8818.98, -385.293, 104.379, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 4;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 4, -8821.97, -392.053, 101.109, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 5;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 5, -8817.52, -397.375, 99.2914, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 6;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 6, -8809.71, -397.053, 96.9112, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 7;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 7, -8806.55, -390.221, 94.6057, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 8;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 8, -8808.17, -384.445, 93.4146, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 9;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 9, -8814.15, -381.664, 90.3282, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 10;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 10, -8819.54, -383.654, 88.9988, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 11;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 11, -8823.62, -388.549, 86.5244, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 12;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 12, -8823.18, -393.365, 84.4668, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 13;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 13, -8819.83, -398.174, 83.1736, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 14;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 14, -8814.95, -400.334, 82.3803, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 15;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 15, -8809.08, -398.346, 80.0596, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 16;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 16, -8805.46, -393.766, 78.9394, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 17;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 17, -8805.17, -389.953, 77.494, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 18;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 18, -8807.4, -384.764, 75.2921, NULL, 0, 5500, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 19;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 19, -8805.03, -392.027, 78.302, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 20;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 20, -8807.22, -396.412, 80.0596, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 21;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 21, -8812.81, -400.961, 81.3515, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 22;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 22, -8818.36, -400.012, 82.8947, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 23;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 23, -8823.4, -395.092, 83.9524, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 24;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 24, -8824.15, -389.721, 86.3146, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 25;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 25, -8821.29, -384.551, 88.9988, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 26;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 26, -8815.77, -381.117, 89.8138, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 27;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 27, -8809.71, -382.949, 92.3858, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 28;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 28, -8806.65, -387.615, 94.4434, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 29;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 29, -8807.16, -392.582, 94.6057, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 30;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 30, -8809.12, -396.502, 96.7769, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 31;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 31, -8813.86, -398.232, 99.0347, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 32;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 32, -8821.02, -395.844, 99.5658, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 33;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 33, -8821.66, -390.061, 102.202, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 34;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 34, -8819.26, -384.725, 104.422, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 35;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 35, -8815.34, -384.031, 104.795, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `waypoint_data` WHERE `id` = 75003130 AND `point` = 36;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (75003130, 36, -8814.29, -394.881, 110.378, NULL, 0, 7500, 0, 0, 0, 100, 0);

-- ----------------------------------------------------------------------------
-- gameobject_template: 0 update(s), 2 re-created row(s)
-- ----------------------------------------------------------------------------

REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (600639, 5, 8623, 'Banner Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', NULL);
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (600530, 5, 85147, 'Bush Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', NULL);

-- ----------------------------------------------------------------------------
-- gameobject: 6 update(s), 0 re-created row(s)
-- ----------------------------------------------------------------------------

UPDATE `gameobject` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500100;
UPDATE `gameobject` SET `orientation` = 5.75031, `rotation2` = 0.261894, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500134;
UPDATE `gameobject` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500136;
UPDATE `gameobject` SET `orientation` = 1.31188, `rotation2` = 0.609903, `rotation3` = 0.792476, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500173;
UPDATE `gameobject` SET `rotation2` = 0.9568, `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500211;
UPDATE `gameobject` SET `VerifiedBuild` = NULL, `Comment` = NULL WHERE `guid` = 7500212;

-- Spawn corrections: stray spawns removed; the Staff relic marker (now the unique [KC]
-- 161881) and the Journal re-stated.
SET @CGUID := 80131;
SET @OGUID := 7500165;

-- creature ------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (@CGUID, @CGUID+5, @CGUID+21, @CGUID+7420217,
   @CGUID+8922990, @CGUID+8922992, @CGUID+8922993, @CGUID+8922996, @CGUID+8922997);
INSERT INTO `creature`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`,
   `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`,
   `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`,
   `dynamicflags`) VALUES
  (@CGUID+7420217, 161881, 0, 1, 1, 0, -8638.850000, -404.450000, 54.720000, 3.187700, 120,
   0.000000, 0, 1, 0, 0, 0, 0, 0);

-- 80152's script rows go with the spawn; group 8015200 is called only by -80152.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-80152, 8015200);

-- creature_addon ------------------------------------------------------------------------
DELETE FROM `creature_addon` WHERE `guid` IN (@CGUID, @CGUID+5, @CGUID+21, @CGUID+8922990,
   @CGUID+8922992, @CGUID+8922993, @CGUID+8922996, @CGUID+8922997);
INSERT INTO `creature_addon`
  (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
   `auras`) VALUES
  (@CGUID+7420217, 0, 0, 0, 1, 0, 0, NULL)
ON DUPLICATE KEY UPDATE `path_id` = VALUES(`path_id`), `mount` = VALUES(`mount`),
  `emote` = VALUES(`emote`), `auras` = VALUES(`auras`),
  `bytes1` = (`bytes1` & 0xFFFFFF00) | (VALUES(`bytes1`) & 0xFF);

-- gameobject ----------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (@OGUID, @OGUID+7, @OGUID+409836, @OGUID+409846,
   @OGUID+409847, @OGUID+409848, @OGUID+411935, @OGUID+411937, @OGUID+411938, @OGUID+411939,
   @OGUID+411940, @OGUID+411941, @OGUID+411942, @OGUID+411943, @OGUID+411944, @OGUID+411945,
   @OGUID+411946, @OGUID+411947, @OGUID+411948, @OGUID+411949, @OGUID+411950, @OGUID+411951,
   @OGUID+411952);
INSERT INTO `gameobject`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
   `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
   `animprogress`, `state`) VALUES
  (@OGUID, 2300520, 0, 1, 1, -8575.740000, -253.084000, 53.722800, 2.895400, 0.000000000,
   0.000000000, 0.992431000, 0.122801000, 120, 100, 1);

-- ----------------------------------------------------------------------------
-- Spada questline: the Goldshire continuation 1660055-1660060, wired from the realm's own
-- ported content. The six quests and every supporting asset (texts, vendors, item hand-ins,
-- gossip, crops, warren, mirror shards) already exist in the world; only the starter/ender
-- set was missing, so the storyline stopped at Northshire. This block is the last writer:
--   starters  Dulcinea 162800 (1660056), Aldia Crayon 162802 (1660057), Clara the Mad 162805
--             (1660058), the mayor Harvend Thorm 162807 (1660059), Aliscar Lend 162806
--             (1660060); Bianca Spada 161700 keeps 1660055
--   enders    Dulcinea 162800 (1660055), Aldia Crayon 162802 (1660056 + 1660057), Clara the
--             Mad 162805 (1660058), Eldor Hammer 162801 (1660059), Aliscar Lend 162806 (1660060)
--   chain     1660057 follows 1660056; 1660055 offers 1660056 as its breadcrumb
-- ----------------------------------------------------------------------------

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);

INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(161700, 1660055),
(162800, 1660056),
(162802, 1660057),
(162805, 1660058),
(162807, 1660059),
(162806, 1660060);

DELETE FROM `creature_questender` WHERE `quest` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(162800, 1660055),
(162802, 1660056),
(162802, 1660057),
(162805, 1660058),
(162801, 1660059),
(162806, 1660060);

UPDATE `quest_template_addon` SET `BreadcrumbForQuestId` = 1660056 WHERE `ID` = 1660055;
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660056 WHERE `ID` = 1660057;

-- ---------------------------------------------------------------------------
-- Seven Years of Bad Luck: mirror shard spawn corrections
-- ---------------------------------------------------------------------------
-- The mirror shards around the manor are repositioned and thinned, two shards are
-- added, and three stray critter spawns are removed (Forest Spider 80288, Sheep
-- 80290, Thuros Lightfingers 134008; the first two had been relocated onto the
-- manor grounds by the Elwynn stock relocation file).

SET @CGUID  := 80288;
SET @OGUID  := 7911000;

-- creature ------------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (@CGUID, @CGUID+2, @CGUID+53720);

-- creature_addon ------------------------------------------------------------------------
DELETE FROM `creature_addon` WHERE `guid` IN (@CGUID, @CGUID+2, @CGUID+53720);

-- gameobject ----------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (@OGUID, @OGUID+1, @OGUID+2, @OGUID+3, @OGUID+4,
   @OGUID+5, @OGUID+6, @OGUID+7, @OGUID+8, @OGUID+9, @OGUID+10, @OGUID+11, @OGUID+12,
   @OGUID+14, @OGUID+15, @OGUID+16);
INSERT INTO `gameobject`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
   `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
   `animprogress`, `state`) VALUES
  (@OGUID, 2300546, 0, 1, 1, -9275.875000, 456.062500, 82.248207, 4.486969, 0.000000000,
   0.000000000, -0.782149482, 0.623090834, 60, 100, 1),
  (@OGUID+4, 2300546, 0, 1, 1, -9283.238281, 466.894531, 89.870483, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1),
  (@OGUID+5, 2300546, 0, 1, 1, -9299.470703, 462.406250, 86.030952, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1),
  (@OGUID+7, 2300546, 0, 1, 1, -9283.470703, 478.667969, 77.805656, 1.790808, 0.000000000,
   0.000000000, 0.780461650, 0.625203657, 60, 100, 1),
  (@OGUID+9, 2300546, 0, 1, 1, -9279.664062, 492.011719, 78.589531, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1),
  (@OGUID+10, 2300546, 0, 1, 1, -9307.068359, 462.580078, 78.477119, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1),
  (@OGUID+11, 2300546, 0, 1, 1, -9310.453125, 501.781250, 77.561836, 2.953911, 0.000000000,
   0.000000000, -0.995600177, -0.0937031930, 60, 100, 1),
  (@OGUID+14, 2300546, 0, 1, 1, -9270.294922, 452.421875, 79.224075, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1),
  (@OGUID+16, 2300546, 0, 1, 1, -9308.707031, 428.375000, 77.485962, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1);

-- gameobject (new spawns) ---------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (8001305, 8001306);
INSERT INTO `gameobject`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
   `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
   `animprogress`, `state`) VALUES
  (8001305, 2300546, 0, 1, 1, -9270.521484, 457.613281, 82.248207, 0.209746, 0.000000000,
   0.000000000, 0.104680696, 0.994505883, 60, 100, 1),
  (8001306, 2300546, 0, 1, 1, -9315.384766, 481.646484, 78.069740, 4.681728, 0.000000000,
   0.000000000, -0.717863680, 0.696183695, 60, 100, 1);

-- ---------------------------------------------------------------------------
-- Seven Years of Bad Luck: the shard click (Inspecting cast + Curse Shard)
-- ---------------------------------------------------------------------------
-- The shard uses the realm's own handler, like the warren: the click runs the 3
-- second 'Inspecting' cast (256702, the native client record) at the shard, and only
-- the completed cast reaches the handler, which credits the inspection (162920),
-- summons the 'Curse Shard' 162919 (display 33054, the entity the realm's creature
-- cache knows) at the shard and despawns it - an interrupted cast changes nothing.
-- The binding covers 256702 alone; the native DUMMY effect is kept.

UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_abbess_relic', `AIName` = '', `Data10` = 0 WHERE `entry` = 2300546;

DELETE FROM `spell_script_names` WHERE `spell_id` = 256702;

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (256702, 'spell_coa_abbess_relic_prayer');

DELETE FROM `spell_dbc` WHERE `Id` = 256702;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300546 AND `source_type` = 1;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 2300546 AND `SourceId` = 1;

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `AIName`)
VALUES (162919, 'Curse Shard', NULL, 6, 7, 14, 1, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `AIName` = VALUES(`AIName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 162919;

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (162919, 0, 33054, 0.75, 1);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162919 AND `source_type` = 0;

-- ---------------------------------------------------------------------------
-- Seven Years of Bad Luck: shard spawn corrections, continued
-- ---------------------------------------------------------------------------
-- Shard 7911000 moves onto the coordinates the block above gives 7911010, the old
-- 7911003 spot stays removed, and shard 8001307 is added.

SET @OGUID := 7911000;

-- gameobject ----------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` IN (@OGUID, @OGUID+3);
INSERT INTO `gameobject`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
   `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
   `animprogress`, `state`) VALUES
  (@OGUID, 2300546, 0, 1, 1, -9307.068359, 462.580078, 78.477119, 0.000000, 0.000000000,
   0.000000000, 0.000000000, 1.000000000, 60, 100, 1);

-- gameobject (new spawns) ---------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` = 8001307;
INSERT INTO `gameobject`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
   `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
   `animprogress`, `state`) VALUES
  (8001307, 2300546, 0, 1, 1, -9300.369141, 442.689453, 78.217064, 4.803136, 0.000000000,
   0.000000000, 0.674305996, -0.738452045, 60, 100, 1);

-- ---------------------------------------------------------------------------
-- Seven Years of Bad Luck: shard spawn corrections, continued
-- ---------------------------------------------------------------------------
-- Shard 7911013 moves.

SET @OGUID  := 7911013;

-- gameobject ----------------------------------------------------------------------------
DELETE FROM `gameobject` WHERE `guid` = @OGUID;
INSERT INTO `gameobject`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
   `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
   `animprogress`, `state`) VALUES
  (@OGUID, 2300546, 0, 1, 1, -9275.855469, 455.861328, 82.248207, 4.409257, 0.000000000,
   0.000000000, -0.805763848, 0.592236963, 60, 100, 1);

-- ---------------------------------------------------------------------------
-- Kobold Warren & Mirror Shard, final: pure SAI on the data10 cast
-- ---------------------------------------------------------------------------
-- Both objects go back to the template's own cast - data10 = 'Destroy' 267031 /
-- 'Inspecting' 256702, the native 3 second records - with 'SmartGameObjectAI' as
-- the script. The core casts a goober spell that asks for a gameobject target at
-- the object itself, so the native DUMMY lands on the object and its AI receives
-- the spell hit (SMART_EVENT_SPELLHIT, 8). The hit exists only when the cast
-- completes: an interrupted cast applies no effect, fires no event and changes
-- nothing. data1 is the goober quest gate - the click casts nothing while the
-- quest is not in progress - and the smart-event conditions repeat that gate for
-- the credit/ambush/despawn rows, exactly like the replaced handler did.
--
-- The ambusher spawns ON the object (target self) and attacks the clicker:
-- summon type 4 = timed despawn out of combat for 30 s, attackInvoker 2 attacks
-- the event invoker, i.e. the spell's caster. The object despawns on the spot
-- and is back in 60 s. The replaced C++ handler and its spell bindings come off;
-- no gameobject or spell may still name them (worldserver would log the missing
-- scripts at startup).

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `Data1` = 1660058, `Data10` = 267031 WHERE `entry` = 2300579;
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `ScriptName` = '', `Data1` = 1660057, `Data10` = 256702 WHERE `entry` = 2300546;

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_coa_abbess_relic_prayer';

-- Mirror Shard (2300546) ambush fix (2026-10-10): the Curse Shard summon row (id 1,
-- action_type 12 SMART_ACTION_SUMMON_CREATURE) carried event_chance 100, the same bug as
-- Living Heresy above - same fix, same reasoning: changed to 40, leaving the credit row
-- (id 0, action_type 33) and the despawn row (id 2, action_type 41) at 100 since they must
-- keep firing every time regardless of whether the ambush itself procs. The sibling Kobold
-- Warren row (2300579, id 1) already used a reduced chance (75%), so this file's own
-- precedent confirms 100% was never the intent for a chest-ambush summon.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300579, 2300546) AND `source_type` = 1;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300579, 1, 0, 0, 8, 0, 100, 0, 267031, 0, 0, 0, 0, 0, 33, 162940, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Kobold Warren - Destroy completed: credit 162940'),
(2300579, 1, 1, 0, 8, 0, 75, 0, 267031, 0, 0, 0, 0, 0, 12, 162915, 4, 30000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kobold Warren - Destroy completed: 75% Kobold Prospector ambush at the warren'),
(2300579, 1, 2, 0, 8, 0, 100, 0, 267031, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kobold Warren - destroyed, back in 60 s'),
(2300546, 1, 0, 0, 8, 0, 100, 0, 256702, 0, 0, 0, 0, 0, 33, 162920, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard - Inspecting completed: credit 162920'),
(2300546, 1, 1, 0, 8, 0, 40, 0, 256702, 0, 0, 0, 0, 0, 12, 162919, 4, 30000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard - Inspecting completed: Curse Shard at the shard (40% ambush chance)'),
(2300546, 1, 2, 0, 8, 0, 100, 0, 256702, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard - inspected, back in 60 s');

-- Smart-event conditions key on the entryorguid and the row id + 1.

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` IN (2300579, 2300546) AND `SourceId` = 1;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 2300579, 1, 0, 47, 0, 1660058, 8, 0, 0, 0, 0, '', 'Kobold Warren - credit only while quest 1660058 is in progress'),
(22, 2, 2300579, 1, 0, 47, 0, 1660058, 8, 0, 0, 0, 0, '', 'Kobold Warren - ambush only while quest 1660058 is in progress'),
(22, 3, 2300579, 1, 0, 47, 0, 1660058, 8, 0, 0, 0, 0, '', 'Kobold Warren - despawn only while quest 1660058 is in progress'),
(22, 1, 2300546, 1, 0, 47, 0, 1660057, 8, 0, 0, 0, 0, '', 'Mirror Shard - credit only while quest 1660057 is in progress'),
(22, 2, 2300546, 1, 0, 47, 0, 1660057, 8, 0, 0, 0, 0, '', 'Mirror Shard - ambush only while quest 1660057 is in progress'),
(22, 3, 2300546, 1, 0, 47, 0, 1660057, 8, 0, 0, 0, 0, '', 'Mirror Shard - despawn only while quest 1660057 is in progress');

-- ===== 2026-10-01 corrections ==============================================================
-- Folded in after the fact; every item below was applied to the live world during the
-- pre-merge test pass on 2026-10-01. All statements are idempotent and safe to re-apply.

-- 537 Defias Trainee - the casting script restored, and the mana it was written for --------
-- The seven rows were live-only (no SQL file ever carried them) and died in the
-- 2026-09-27/28 file-based rebuilds; recovered verbatim from the surviving 09-27 world.
-- The template has always been unit_class 1 (warrior -> rage, so no mana at all): Fireball
-- costs 45 and the MANA_PCT event is guarded by GetMaxPower(POWER_MANA), which pinned the
-- mob in its phase-1 hold forever. Class 8 (mage) gives 120 mana at level 1 and 147 at
-- level 2 - 0.3 * 120 = 36 < 45, the value its own comment ("cannot pay 45") was written
-- around. The port file's 537 INSERT still says unit_class = 1; this file sorts after it.
UPDATE `creature_template` SET `unit_class` = 8 WHERE `entry` = 537;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 537 AND `source_type` = 0;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(537, 0, 0, 1, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - On Reset - Hold position'),
(537, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Linked - Clear event phase'),
(537, 0, 2, 3, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - On Aggro - Set phase 1 (cast)'),
(537, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Linked - Hold position in combat'),
(537, 0, 4, 0, 9, 1, 100, 0, 0, 0, 3500, 4500, 0, 25, 11, 9488, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Phase 1: victim within 25 yd - Cast Fireball (9488)'),
(537, 0, 5, 6, 3, 1, 100, 0, 0, 30, 1000, 1000, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Phase 1: mana at or below 30% (cannot pay 45) - Set phase 2 (melee)'),
(537, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Linked - Allow combat movement (close to melee)');

-- 161701 Moroi Spada - speaks when quest 1660001 is accepted ---------------------------------
-- Guard pattern: the entry copy is the durable record and the spawn copy is the one that
-- fires (a spawn script replaces the entry script for its spawn). Event 19 = ACCEPTED_QUEST
-- with the 20 s cooldown pair, action 1 talks creature_text group 0 (type 12 = monster say).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161701 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = -7500240 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(161701, 0, 0, 0, 19, 0, 100, 0, 1660001, 20000, 20000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000, 'Moroi Spada - On quest 1660001 accepted - say his line'),
(-7500240, 0, 0, 0, 19, 0, 100, 0, 1660001, 20000, 20000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.000000, 0.000000, 0.000000, 0.000000, 'Moroi Spada - On quest 1660001 accepted - say his line');

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161701;

DELETE FROM `creature_text` WHERE `CreatureID` = 161701 AND `GroupID` = 0 AND `ID` = 0;
INSERT INTO `creature_text`
  (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
   `Duration`, `Sound`, `BroadcastTextId`) VALUES
  (161701, 0, 0, 'Missing a page here... no, two. What a mess... Hard to focus with all that racket going on!', 12, 0, 100, 0, 0, 0, 0);

-- Note: the Injured Northshire Guard's spawn-scoped accept row (-7500315 id 1) was edited in
-- place above: its cooldown now matches its entry copy (161705 id 3) at 20 s, so a re-fired
-- line cannot spam chat.

-- 9003122 Gerald (class-trainer chain NPC at the north end of the river bridge) removed ------
-- The spawn row comes from rev_20260923_06_coa_class_trainers_northshire.sql; the deletion
-- itself was applied live-only and is recorded here so a rebuild cannot resurrect him.
DELETE FROM `creature` WHERE `guid` = 9003122;
DELETE FROM `creature_addon` WHERE `guid` = 9003122;
