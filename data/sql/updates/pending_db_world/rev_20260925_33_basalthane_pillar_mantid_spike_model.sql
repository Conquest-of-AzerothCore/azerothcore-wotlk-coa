-- Basalthane's pillars (Onyxia's Lair) get a real model instead of the
-- "Lava Hardened Rock" placeholder (entry 68371, a stock Worldforged
-- gameobject reused only for its shape).
--
-- Model: World\EXPANSION04\DOODADS\Mantid\Mantid_spike_Organic.M2. The .m2
-- file itself is in the client (confirmed present in patch-M.MPQ's listfile,
-- 2026-09-25), but no GameObjectDisplayInfo.dbc row pointed at it -- checked
-- every .dbc under Build/install/dbc and client-dbc-out, no match for
-- "spike_organic" anywhere. Added via the WXL extended-DBC continuation
-- pipeline (mod-wxl-extended-dbc) instead of repacking the client:
-- Build/install/dbc-continuations/GameObjectDisplayInfo.dbc1-basalthane,
-- a standalone WDBC file with one row (Displayid 9500100, ModelName
-- "world\expansion04\doodads\mantid\mantid_spike_organic.m2", geobox
-- -1.5,-1.5,0 to 1.5,1.5,6 as a placeholder bounding box -- tune in-game
-- if it looks wrong). This gets merged into the live DBC store at server
-- start via ReplaceEntry/EnsureCapacity, base dbc/ files untouched.
--
-- New gameobject_template entry 9500100 is a straight copy of 68371's
-- type/Data columns (only entry/displayId/name differ) so it keeps
-- whatever interaction behavior the old placeholder already had working
-- in-game. The 3 pillar spawns (guids 6901536-6901538) are repointed at it;
-- 68371 itself is untouched in case anything else references it.

-- No DELETE (gameobject_template entries are never deleted, per codestyle) - INSERT
-- IGNORE on the final clone is correct for a fresh install and safe to replay.
DROP TEMPORARY TABLE IF EXISTS `basalthane_pillar_tier`;
CREATE TEMPORARY TABLE `basalthane_pillar_tier` AS SELECT * FROM `gameobject_template` WHERE `entry` = 68371;
UPDATE `basalthane_pillar_tier` SET `entry` = 9500100, `displayId` = 9500100, `name` = 'Basalthane Pillar (Mantid Spike)';
INSERT IGNORE INTO `gameobject_template` SELECT * FROM `basalthane_pillar_tier`;
DROP TEMPORARY TABLE `basalthane_pillar_tier`;

UPDATE `gameobject` SET `id` = 9500100 WHERE `guid` IN (6901536, 6901537, 6901538);
