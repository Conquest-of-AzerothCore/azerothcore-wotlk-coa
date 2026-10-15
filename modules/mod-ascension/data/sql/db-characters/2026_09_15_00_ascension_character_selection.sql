-- Ascension character-selection state.
--
-- `character_ascension_state` marks a character as deactivated (the "inactive"
-- state of the Ascension character screen). A missing row means "active", so
-- existing characters are unaffected; the core character enum hides rows whose
-- `active` column is 0 and the module reports them through SMSG 0x075E instead.
--
-- `account_ascension_settings` stores the sort-order payload of SMSG 0x076F
-- verbatim; it is an opaque client-side translation table and is not parsed by
-- the server.
CREATE TABLE IF NOT EXISTS `character_ascension_state` (
    `guid` INT UNSIGNED NOT NULL,
    `active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `account_ascension_settings` (
    `account_id` INT UNSIGNED NOT NULL,
    `sort_order` VARCHAR(1024) NULL,
    PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
