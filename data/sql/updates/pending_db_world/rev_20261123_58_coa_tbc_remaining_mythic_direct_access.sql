-- Explicit level-60 direct access rows supplement the Dungeon Finder records.
DELETE FROM `dungeon_access_template`
WHERE `difficulty` = 2 AND `map_id` IN (269, 552, 553, 554, 555, 556, 557, 558, 560, 585);
INSERT INTO `dungeon_access_template`
    (`id`, `map_id`, `difficulty`, `min_level`, `max_level`, `min_avg_item_level`, `comment`)
VALUES
(228, 269, 2, 60, 0, 0, 'Black Morass (Mythic)'),
(229, 552, 2, 60, 0, 0, 'Arcatraz (Mythic)'),
(230, 553, 2, 60, 0, 0, 'Botanica (Mythic)'),
(231, 554, 2, 60, 0, 0, 'Mechanar (Mythic)'),
(232, 555, 2, 60, 0, 0, 'Shadow Labyrinth (Mythic)'),
(233, 556, 2, 60, 0, 0, 'Sethekk Halls (Mythic)'),
(234, 557, 2, 60, 0, 0, 'Mana-Tombs (Mythic)'),
(235, 558, 2, 60, 0, 0, 'Auchenai Crypts (Mythic)'),
(236, 560, 2, 60, 0, 0, 'Escape from Durnholde (Mythic)'),
(237, 585, 2, 60, 0, 0, 'Magisters'' Terrace (Mythic)');

-- Retain the existing prerequisite checks and let level-60 players complete them.
UPDATE `quest_template` SET `MinLevel` = 60
WHERE `ID` IN (10977, 10981, 11492) AND `MinLevel` BETWEEN 61 AND 254;
