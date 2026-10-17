-- Belorite Sprites (175095): the 17 Wild Steelbloom stand-ins the user placed in the Gilded Vale become Belorita flowers,
-- one flower per pick, lootable only while on the quest, back after 30 seconds.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data3`, `Data8`, `Data10`, `Data12`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300808, 3, 371, 'Belorita', '', '', '', 1, 1689, 2300808, 1, 175095, 1, 1, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`), `Data8` = VALUES(`Data8`), `Data10` = VALUES(`Data10`), `Data12` = VALUES(`Data12`);
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300808;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2300808, 559903, 0, 100, 1, 1, 0, 1, 1, 'Belorita - Belorite Sprites');
UPDATE `gameobject` SET `id` = 2300808, `spawntimesecs` = 30 WHERE `id` = 1623 AND `guid` BETWEEN 9963500 AND 9963516;
