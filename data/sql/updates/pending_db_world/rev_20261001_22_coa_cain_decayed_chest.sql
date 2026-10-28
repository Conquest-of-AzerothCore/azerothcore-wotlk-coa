-- Worldforged Decayed Chest 516984 in the Cain manor's upper room, behind the Crystal Ball (CoA footage). CoA's
-- gameobjectcache and the Exiles export both have the object (chest, lock 1689, display 1 = Chest02, the model
-- the module's other Worldforged chests use) and Exiles its one loot row, the Cain Family Heirloom wand 824402;
-- mod-worldforged-pickups never restored it and no source gives its position. It is set up exactly like the
-- module's pickups (worldforged_pickup, Data10/12/18 = 1, its own item at 100%) and stands on the room floor beside
-- the barrel next to the Crystal Ball's table, where the author recalls it from CoA (INFERRED spot), facing the rug.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data10`, `Data12`, `Data18`, `AIName`, `ScriptName`)
VALUES
(516984, 3, 1, 'Decayed Chest', '', '', 1, 1689, 516984, 1, 1, 1, '', 'worldforged_pickup')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
`IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`),
`Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data10` = VALUES(`Data10`), `Data12` = VALUES(`Data12`),
`Data18` = VALUES(`Data18`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 516984;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(516984, 824402, 0, 100, 0, 1, 0, 1, 1, 'Decayed Chest - Cain Family Heirloom (Exiles gameobject_loot)');
DELETE FROM `gameobject` WHERE `guid` = 7916020;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(7916020, 516984, 0, 0, 0, 1, 1, 1923.78, 1952.57, 176.799, 0.3346, 0, 0, 0.166521, 0.986038, 0, 0, 1, 'worldforged_pickup', 'CoA Cain manor upper room: Worldforged Decayed Chest behind the Crystal Ball');
