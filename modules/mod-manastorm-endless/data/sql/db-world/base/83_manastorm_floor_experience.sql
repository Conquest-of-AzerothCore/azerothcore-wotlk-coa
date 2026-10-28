-- Apply to acore_world before starting the updated server.
-- Reconstruction policy: one repeatable Classic RDF XP reward per completed floor.
-- 258 = Random Classic Dungeon. Only otherQuest is used; no first-daily bonus.
-- multiplier 1.0 = 100%, 0.5 = 50%, 2.0 = 200%. enabled 0 stops new awards.
-- Existing operator settings survive reapplication. Restart or reload Manastorm after edits.
CREATE TABLE IF NOT EXISTS `manastorm_floor_experience`
(
    `id` TINYINT UNSIGNED NOT NULL,
    `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `rdf_dungeon_id` INT UNSIGNED NOT NULL DEFAULT 258,
    `multiplier` DOUBLE NOT NULL DEFAULT 1.0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Intentionally no DELETE: preserve an existing operator configuration.
INSERT INTO `manastorm_floor_experience` (`id`, `enabled`, `rdf_dungeon_id`, `multiplier`)
SELECT 1, 1, 258, 1.0
WHERE NOT EXISTS (SELECT 1 FROM `manastorm_floor_experience` WHERE `id` = 1);
