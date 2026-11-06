DELETE FROM `creature_loot_template` WHERE `Entry` IN (11440, 11442, 11443) AND `Item` = 46509 AND `Reference` = 0 AND `GroupId` = 0;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(11440, 46509, 0, 0.75, 0, 1, 0, 1, 1, 'Gordok Enforcer - Formula: Enchant Weapon - Strider'),
(11442, 46509, 0, 0.75, 0, 1, 0, 1, 1, 'Gordok Mauler - Formula: Enchant Weapon - Strider'),
(11443, 46509, 0, 0.75, 0, 1, 0, 1, 1, 'Gordok Ogre-Mage - Formula: Enchant Weapon - Strider');
