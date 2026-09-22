-- Recovered Manastorm segment/creature-pool architecture.
--
-- Evidence boundary:
-- * objective bosses stay attached to exact Manastorm segment families;
-- * ordinary creature randomization is a separate server-side content pool;
-- * exact replacement chance/weighting is still unknown and is NOT enabled.
--
-- This script is idempotent. It preserves legacy Chaotic Link authoring without
-- guessing randomization or CreaturePoolSource eligibility.

CREATE TABLE IF NOT EXISTS `manastorm_segment_spawn` (
  `segment_id` INT UNSIGNED NOT NULL,
  `spawn_guid` INT UNSIGNED NOT NULL,
  `flags` INT UNSIGNED NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`segment_id`,`spawn_guid`),
  KEY `idx_spawn_guid` (`spawn_guid`),
  KEY `idx_segment_flags` (`segment_id`,`flags`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_creature_pool` (
  `pool_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`pool_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `manastorm_creature_pool_segment` (
  `pool_id` INT UNSIGNED NOT NULL,
  `segment_id` INT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`pool_id`,`segment_id`),
  KEY `idx_source_segment` (`segment_id`,`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Legacy rows prove only:
--   RouteCreature          0x01
--   ChaoticLinkEligible    0x02
--
-- Do NOT silently infer:
--   RandomizationSlot      0x04
--   CreaturePoolSource     0x08
INSERT IGNORE INTO `manastorm_segment_spawn`
    (`segment_id`, `spawn_guid`, `flags`, `enabled`)
SELECT
    `segment_id`,
    `spawn_guid`,
    3,
    `enabled`
FROM `manastorm_chaotic_link_spawn`;

-- Audit after applying:
SELECT
    COUNT(*) AS authored_segment_spawns,
    SUM((`flags` & 1) <> 0) AS route_rows,
    SUM((`flags` & 2) <> 0) AS chaotic_link_rows,
    SUM((`flags` & 4) <> 0) AS randomization_slot_rows,
    SUM((`flags` & 8) <> 0) AS creature_pool_source_rows
FROM `manastorm_segment_spawn`;
