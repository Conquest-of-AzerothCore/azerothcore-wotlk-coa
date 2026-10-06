-- Apply to acore_world.
-- User-selected policy: each Case contains all twenty matching scrolls,
-- one of each. Independent guaranteed rows; no random selection group.
-- Replace only these two Case loot profiles. Retain existing item flags.
UPDATE `item_template` SET `Flags` = `Flags` | 4 WHERE `entry` IN (1278048, 1278049);

DELETE FROM `item_loot_template` WHERE `Entry` IN (1278048, 1278049);
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(1278049, 97913, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 1'),
(1278049, 97914, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 2'),
(1278049, 97915, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 3'),
(1278049, 97916, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 4'),
(1278049, 97917, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 5'),
(1278049, 97918, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 6'),
(1278049, 97919, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 7'),
(1278049, 97920, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 8'),
(1278049, 97921, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 9'),
(1278049, 97922, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 10'),
(1278049, 97923, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 11'),
(1278049, 97924, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 12'),
(1278049, 97925, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 13'),
(1278049, 97926, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 14'),
(1278049, 97927, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 15'),
(1278049, 97928, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 16'),
(1278049, 97929, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 17'),
(1278049, 97930, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 18'),
(1278049, 97931, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 19'),
(1278049, 97932, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: ability scroll 20'),
(1278048, 97933, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 1'),
(1278048, 97934, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 2'),
(1278048, 97935, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 3'),
(1278048, 97936, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 4'),
(1278048, 97937, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 5'),
(1278048, 97938, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 6'),
(1278048, 97939, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 7'),
(1278048, 97940, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 8'),
(1278048, 97941, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 9'),
(1278048, 97942, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 10'),
(1278048, 97943, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 11'),
(1278048, 97944, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 12'),
(1278048, 97945, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 13'),
(1278048, 97946, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 14'),
(1278048, 97947, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 15'),
(1278048, 97948, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 16'),
(1278048, 97949, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 17'),
(1278048, 97950, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 18'),
(1278048, 97951, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 19'),
(1278048, 97952, 0, 100, 0, 1, 0, 1, 1, 'Manastorm Fortune Case: talent scroll 20');

SELECT `Entry`, `Item` FROM `item_loot_template` WHERE `Entry` IN (1278048, 1278049) ORDER BY `Entry`, `Item`;
