-- Explicit TBC upgrade families. Cache item zero identifies levels above the cache ladder.
CREATE TABLE IF NOT EXISTS `coa_mythic_tbc_item` (
    `base_item` INT UNSIGNED NOT NULL,
    `key_level` TINYINT UNSIGNED NOT NULL,
    `reward_item` INT UNSIGNED NOT NULL,
    `cache_item` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`base_item`, `key_level`),
    UNIQUE KEY `uq_coa_mythic_tbc_reward_item` (`reward_item`)
) ENGINE=InnoDB;
