-- The Gryphon Eggs (175148): the 7 Gryphon Egg props the user placed in the nests around Fort Boreos become the quest pick-ups,
-- one Boreos Gryphon Egg each, lootable only while on the quest, back after 2 minutes. Spawn rows keep their tilt.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data3`, `Data8`, `Data10`, `Data12`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300810, 3, 3851, 'Gryphon Egg', '', '', '', 1, 1689, 2300810, 1, 175148, 1, 1, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`), `Data8` = VALUES(`Data8`), `Data10` = VALUES(`Data10`), `Data12` = VALUES(`Data12`);
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300810;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2300810, 559927, 0, 100, 1, 1, 0, 1, 1, 'Gryphon Egg - The Gryphon Eggs');
UPDATE `gameobject` SET `id` = 2300810, `spawntimesecs` = 120 WHERE `id` = 181645 AND `guid` BETWEEN 9963219 AND 9963225;
