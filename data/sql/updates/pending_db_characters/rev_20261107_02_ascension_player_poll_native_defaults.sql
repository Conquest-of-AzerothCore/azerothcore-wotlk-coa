UPDATE `coa_player_poll`
SET `wire_04` = COALESCE(`wire_04`, 4294967295),
    `wire_50` = COALESCE(`wire_50`, 0),
    `wire_54` = COALESCE(`wire_54`, 0),
    `wire_a8` = COALESCE(`wire_a8`, 100)
WHERE `wire_04` IS NULL OR `wire_50` IS NULL OR `wire_54` IS NULL OR `wire_a8` IS NULL;

ALTER TABLE `coa_player_poll`
    MODIFY `wire_04` INT UNSIGNED NOT NULL DEFAULT 4294967295,
    MODIFY `wire_50` INT UNSIGNED NOT NULL DEFAULT 0,
    MODIFY `wire_54` INT UNSIGNED NOT NULL DEFAULT 0,
    MODIFY `wire_a8` INT UNSIGNED NOT NULL DEFAULT 100;
