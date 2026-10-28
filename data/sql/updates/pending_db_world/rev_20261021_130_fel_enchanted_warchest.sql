UPDATE `item_template` SET `Flags` = `Flags` | 4, `spellid_1` = 0 WHERE `entry` = 657112;

DELETE FROM `item_loot_template` WHERE `Entry` = 657112
AND `Item` IN (99489, 1903515, 99492, 597602, 1414012, 348450);
INSERT INTO `item_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(657112, 99489, 0, 100, 0, 1, 0, 1, 1, 'Fel Enchanted Warchest - Felflame Talbuk'),
(657112, 1903515, 0, 100, 0, 1, 0, 1, 1, 'Fel Enchanted Warchest - Fel-Infused Gateway'),
(657112, 99492, 0, 100, 0, 1, 0, 1, 1, 'Fel Enchanted Warchest - Pit Lord''s Eye'),
(657112, 597602, 0, 100, 0, 1, 0, 1, 1, 'Fel Enchanted Warchest - Fel-Infused Tabard of Descension'),
(657112, 348450, 0, 100, 0, 1, 0, 4, 4, 'Fel Enchanted Warchest - Pit Lord''s Satchel');
