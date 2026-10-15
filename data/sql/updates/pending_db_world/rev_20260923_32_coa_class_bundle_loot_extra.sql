-- Class bundle contents whose description names no single item: the set cache, both warblades, the three named runeblades, the backsheath weapons.
DELETE FROM `item_loot_template` WHERE (`Entry`, `Item`) IN ((2615024, 317292), (2615024, 317290), (2615026, 558230), (2615027, 100765), (2615027, 100922), (2615027, 100891), (2615029, 106268), (2615033, 101000));
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2615024, 317292, 0, 100, 0, 1, 0, 1, 1, 'Warden''s Moonlit Warblade (Main-hand)'),
(2615024, 317290, 0, 100, 0, 1, 0, 1, 1, 'Warden''s Moonlit Warblade (Off-hand)'),
(2615026, 558230, 0, 100, 0, 1, 0, 1, 1, 'Azure Clockwork Set Cache'),
(2615027, 100765, 0, 100, 0, 1, 0, 1, 1, 'Manaforged Runeblade (Frost)'),
(2615027, 100922, 0, 100, 0, 1, 0, 1, 1, 'Manaforged Runeblade (Fire)'),
(2615027, 100891, 0, 100, 0, 1, 0, 1, 1, 'Manaforged Runeblade (Arcane)'),
(2615029, 106268, 0, 100, 0, 1, 0, 1, 1, 'Ghastly Nightmare''s Twin-Scythe (Backsheath)'),
(2615033, 101000, 0, 100, 0, 1, 0, 1, 1, 'Steelforged Dragonblade (Backsheath)');
