-- A boss leash with `target` = 1 also resets the boss when its current target stands outside the area, on every
-- dungeon difficulty. For bosses that do not move in combat, whose own position never leaves the area.
SELECT IF(NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_boss_leash'
            AND `COLUMN_NAME` = 'target'),
    "ALTER TABLE `coa_boss_leash` ADD COLUMN `target` TINYINT UNSIGNED NOT NULL DEFAULT 0 "
        "COMMENT '1: also resets when its target is outside the area, on every difficulty' AFTER `radius`",
    'DO 0') INTO @coa_boss_leash_target;
PREPARE `coa_boss_leash_target` FROM @coa_boss_leash_target;
EXECUTE `coa_boss_leash_target`;
DEALLOCATE PREPARE `coa_boss_leash_target`;
