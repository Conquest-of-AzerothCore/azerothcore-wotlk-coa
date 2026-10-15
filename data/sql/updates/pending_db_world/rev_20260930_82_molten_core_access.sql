-- Molten Core access on CoA: level 60 on every difficulty, and Attunement to the Core
-- (Alliance 7848, Horde 7487, both from Lothos Riftwaker) for Ascended.
UPDATE `dungeon_access_template` SET `min_level` = 60, `comment` = 'Molten Core (Normal)' WHERE `id` = 24;
DELETE FROM `dungeon_access_template` WHERE `id` IN (122, 123, 124);
INSERT INTO `dungeon_access_template` (`id`, `map_id`, `difficulty`, `min_level`, `max_level`, `min_avg_item_level`, `comment`) VALUES
(122, 409, 1, 60, 0, 0, 'Molten Core (Heroic)'),
(123, 409, 2, 60, 0, 0, 'Molten Core (Mythic)'),
(124, 409, 3, 60, 0, 0, 'Molten Core (Ascended)');
DELETE FROM `dungeon_access_requirements` WHERE `dungeon_access_id` = 124;
INSERT INTO `dungeon_access_requirements` (`dungeon_access_id`, `requirement_type`, `requirement_id`, `requirement_note`, `faction`, `priority`, `leader_only`, `comment`) VALUES
(124, 1, 7848, 'You must complete the quest "Attunement to the Core" before entering the Ascended difficulty of Molten Core.', 0, NULL, 0, 'Molten Core (Ascended): Attunement to the Core (Alliance)'),
(124, 1, 7487, 'You must complete the quest "Attunement to the Core" before entering the Ascended difficulty of Molten Core.', 1, NULL, 0, 'Molten Core (Ascended): Attunement to the Core (Horde)');
