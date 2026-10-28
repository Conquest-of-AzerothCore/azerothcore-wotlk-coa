-- Fierce Blow (975011) on the coa_boss_ai-driven Molten Core bosses fires inside a window instead of on a fixed
-- clock, so neither players nor boss-timer addons can predict it. `first_max_ms` and `period_max_ms` widen
-- `first_ms` and `period_ms` into [min, max] windows; 0 keeps the row fixed, so no other row changes behaviour.
--
-- Windows come from 78744 Fierce Blow lines across the archive combat logs (SPELL_CAST_SUCCESS per creature guid,
-- de-duplicated). Repeat window 6000-10000 ms: 73% of 2491 observed repeats of every Molten Core creature fall
-- inside it (per creature 49-100%). First-cast window 6000-10000 ms: 52% of 707 first casts, measured from the
-- creature's first damage event with a player. A creature whose own distribution clearly leaves that window keeps
-- its own: interquartile range when it has 15 or more samples, observed min-max below that.
--   Gehennas  repeat 6800-10400 (interquartile range, 106 repeats, 52% inside the default)
--   Shazzrah  repeat 7600-12800 (interquartile range, 78 repeats, 49% inside the default)
--   Golemagg  first  6900-14600 (min-max of 6 first casts, 17% inside the default)
-- Lucifron and Sulfuron stay on the default windows (74% and 73% of their repeats inside).

SELECT IF(
    NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_boss_schedule' AND `COLUMN_NAME` = 'first_max_ms'),
    "ALTER TABLE `coa_boss_schedule` "
        "ADD COLUMN `first_max_ms` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'above first_ms: first cast drawn from [first_ms, first_max_ms]' AFTER `first_ms`, "
        "ADD COLUMN `period_max_ms` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'above period_ms: each repeat drawn from [period_ms, period_max_ms]' AFTER `period_ms`",
    'DO 0') INTO @coa_boss_schedule_windows;
PREPARE `coa_boss_schedule_windows` FROM @coa_boss_schedule_windows;
EXECUTE `coa_boss_schedule_windows`;
DEALLOCATE PREPARE `coa_boss_schedule_windows`;

UPDATE `coa_boss_schedule` SET `first_ms` = 6000, `first_max_ms` = 10000, `period_ms` = 6000, `period_max_ms` = 10000
WHERE `spell_d0` = 975011 AND ((`entry` = 12118 AND `idx` = 1) OR (`entry` = 12098 AND `idx` = 5));
UPDATE `coa_boss_schedule` SET `first_ms` = 6000, `first_max_ms` = 10000, `period_ms` = 6800, `period_max_ms` = 10400
WHERE `spell_d0` = 975011 AND `entry` = 12259 AND `idx` = 0;
UPDATE `coa_boss_schedule` SET `first_ms` = 6000, `first_max_ms` = 10000, `period_ms` = 7600, `period_max_ms` = 12800
WHERE `spell_d0` = 975011 AND `entry` = 12264 AND `idx` = 1;
UPDATE `coa_boss_schedule` SET `first_ms` = 6900, `first_max_ms` = 14600, `period_ms` = 6000, `period_max_ms` = 10000
WHERE `spell_d0` = 975011 AND `entry` = 11988 AND `idx` = 0;
