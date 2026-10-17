-- What We Take from the Woods (175104): the 23 Gaea Seed stand-ins the user placed in the Gilded Vale become Enchanted Gilded Vale Pinecones,
-- one pinecone per pick, lootable only while on the quest, back after 30 seconds.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data3`, `Data8`, `Data10`, `Data12`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300809, 3, 424, 'Enchanted Gilded Vale Pinecone', '', '', '', 1, 1689, 2300809, 1, 175104, 1, 1, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`), `Data8` = VALUES(`Data8`), `Data10` = VALUES(`Data10`), `Data12` = VALUES(`Data12`);
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300809;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2300809, 559907, 0, 100, 1, 1, 0, 1, 1, 'Enchanted Gilded Vale Pinecone - What We Take from the Woods');
UPDATE `gameobject` SET `id` = 2300809, `spawntimesecs` = 30 WHERE `id` = 177926 AND `guid` BETWEEN 9963518 AND 9963540;
