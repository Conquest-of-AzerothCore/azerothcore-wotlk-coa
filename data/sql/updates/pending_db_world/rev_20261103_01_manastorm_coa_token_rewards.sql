CREATE TABLE IF NOT EXISTS `manastorm_coa_token_rewards` (
  `id` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `track` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `min_depth` INT UNSIGNED NOT NULL DEFAULT 1,
  `max_depth` INT UNSIGNED NOT NULL DEFAULT 0,
  `first_clear_tokens` INT UNSIGNED NOT NULL DEFAULT 25,
  `repeat_tokens` INT UNSIGNED NOT NULL DEFAULT 10,
  `milestone_every` INT UNSIGNED NOT NULL DEFAULT 0,
  `milestone_tokens` INT UNSIGNED NOT NULL DEFAULT 0,
  `priority` INT UNSIGNED NOT NULL DEFAULT 0,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `manastorm_coa_token_rewards`
WHERE `id` = 1 AND `mode` = 0 AND `track` = 0 AND `min_depth` = 1 AND `max_depth` = 0
  AND `first_clear_tokens` = 25 AND `repeat_tokens` = 10
  AND `milestone_every` = 0 AND `milestone_tokens` = 0 AND `priority` = 0 AND `enabled` = 1;

INSERT INTO `manastorm_coa_token_rewards` (`id`, `mode`, `track`, `min_depth`, `max_depth`,
  `first_clear_tokens`, `repeat_tokens`, `milestone_every`, `milestone_tokens`, `priority`, `enabled`)
SELECT 1, 0, 0, 1, 0, 25, 10, 0, 0, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM `manastorm_coa_token_rewards` WHERE `id` = 1);
