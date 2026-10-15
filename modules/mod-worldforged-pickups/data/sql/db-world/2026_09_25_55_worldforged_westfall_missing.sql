-- ----------------------------------------------------------------------------
-- Worldforged pickups: Westfall, the four objects the reference realm still
-- stands that we did not
-- ------------------------------------------------------------------------------
-- A gameobject dump of the live reference realm (curated/dump_Westfall.csv) stands
-- thirty worldforge pickups in Westfall; twenty of them we already stand within a
-- few yards of where they stand there.  Four of the remaining six hand out real
-- loot on both realms and are restored here, each at the dump's own coordinates:
--
--   95777 Salma's Summer Wardrobe  -> Salma's Summer Dress (515677), Saldean's Farm
--   95809 Unlocked Chest           -> Field Trousers (450775), Saldean's Farm
--   95817 Heavy Stompers           -> Heavy Boots (450721), Stendel's Pond
--   518322 Stolen Supplies         -> Rehomed Belt (521266), by Sentinel Hill
--
-- The dump's other Westfall objects stand empty (no loot row): Evil Chest, Light
-- and Shadow Vol: 1 and Ancient Priest Tome are left out on purpose - a pickup
-- that gives nothing is scenery, not a pickup.  The Law of Light (111000) was
-- restored by an earlier draft of this file and taken back out: it stood empty of
-- a marker of its own and is not wanted.
--
-- Salma's Summer Wardrobe carries the rotation the map editor gave it on
-- 2026-09-25 (changeset spawns_20260925_214907.sql), position and quaternion both.
--
-- Every template, loot row and spawn written here already matches the live rows
-- carried by earlier files; they are restated so this file stands alone.  The
-- spawn rows are DELETEd for their guid before they are written, so a database
-- that ran an earlier draft of this file (which stood five, among them The Law of
-- Light on guid 6960043) ends in the same state as one that runs only this file.
--
-- Idempotent.  Apply to acore_world.
-- ------------------------------------------------------------------------------


START TRANSACTION;

-- Salma's Summer Wardrobe (95777): the editor's authored row of 2026-09-25
DELETE FROM `gameobject` WHERE `guid` = 6960039;
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(95777, 3, 4, 'Salma''s Summer Wardrobe', '', '', '', 1.00, 1689, 95777, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(95777, 515677, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged:catalog catalog loot 95777; catalog chance 0.0000, 100 as the table''s only row');

INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960039, 95777, 0, 0, 0, 1, 1, -10103.9199, 1042.8975, 42.1638, 4.129566, 0.000000000, 0.000000000, -0.880449588, 0.474139772, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Salma''s Summer Wardrobe');

-- Unlocked Chest (95809)
DELETE FROM `gameobject` WHERE `guid` = 6960040;
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(95809, 3, 1, 'Unlocked Chest', '', '', '', 0.90, 1689, 95809, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(95809, 450775, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged:catalog catalog loot 95809; catalog chance 0.0000, 100 as the table''s only row');

INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960040, 95809, 0, 0, 0, 1, 1, -10114.0996, 1046.7700, 43.7252, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Unlocked Chest');

-- Heavy Stompers (95817)
DELETE FROM `gameobject` WHERE `guid` = 6960041;
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(95817, 3, 1009920, 'Heavy Stompers', '', '', '', 1.00, 1689, 95817, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(95817, 450721, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged:catalog catalog loot 95817; catalog chance 0.0000, 100 as the table''s only row');

INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960041, 95817, 0, 0, 0, 1, 1, -10777.7998, 1394.8500, 21.2534, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Heavy Stompers');

-- Stolen Supplies (518322)
DELETE FROM `gameobject` WHERE `guid` = 6960042;
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(518322, 3, 287, 'Stolen Supplies', '', '', '', 1.00, 1689, 518322, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(518322, 521266, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged:catalog catalog loot 518322; catalog chance 0.0000, 100 as the table''s only row');

INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960042, 518322, 0, 0, 0, 1, 1, -10962.7998, 1028.4100, 37.8743, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Stolen Supplies');

-- The Law of Light stood here in an earlier draft of this file; it is not wanted.
DELETE FROM `gameobject` WHERE `guid` = 6960043;

COMMIT;
