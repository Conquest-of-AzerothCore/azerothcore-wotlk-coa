-- Apply to acore_characters before starting the updated server.
-- Unpaid currency only. Historical totals and first-clear state are unchanged.
-- The stage transaction adds earnings; settlement atomically converts them
-- into durable reward mail and deletes the balance. Reconnect without a live
-- run recovers retained earnings, including after a worldserver restart.
CREATE TABLE IF NOT EXISTS `character_manastorm_pending_currency`
(
    `guid` INT UNSIGNED NOT NULL,
    `item_entry` INT UNSIGNED NOT NULL,
    `quantity` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`, `item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
