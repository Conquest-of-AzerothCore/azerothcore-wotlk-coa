-- #10896: Emerald Amanita (354288), the reagent for Potion of Fungal Regrowth, had no source. The node template
-- 254477 is the client capture (AscensionDB gameobjectcache, captured 2026-07-02..09-04); its one known spawn is the
-- AscensionDB addon sighting in northern Felwood (catalogue/gameobjects.tsv, revision d6494ceb3150). The 100% loot
-- chance is a maintainer decision (2026-11-23); respawn and animation follow the stock Felwood herb nodes.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
    `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(254477, 3, 1040328, 'Emerald Amanita', '', '', '', 1, 2444, 254477, 0, 1, 1, 1, '', '', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`),
    `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 254477;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
    `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254477, 354288, 0, 100, 0, 1, 0, 1, 1, 'Emerald Amanita - Emerald Amanita');

DELETE FROM `gameobject` WHERE `guid` = 9936000 AND `id` = 254477;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
    `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
    `state`, `ScriptName`) VALUES
(9936000, 254477, 1, 0, 0, 1, 1, 6455.252, -1485.986, 439.477, 0, 0, 0, 0, 1, 900, 255, 1, '');
