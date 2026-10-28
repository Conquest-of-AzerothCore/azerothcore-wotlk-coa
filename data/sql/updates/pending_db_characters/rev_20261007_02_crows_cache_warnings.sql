ALTER TABLE `coa_crows_cache` ADD COLUMN `announcements` TINYINT UNSIGNED NOT NULL DEFAULT 0;

UPDATE `coa_crows_cache` SET `deadline` = `UNIX_TIMESTAMP`() + 10800 WHERE `id` = 0;
UPDATE `coa_crows_cache` SET `deadline` = 0 WHERE `phase` = 2;
UPDATE `coa_crows_cache` SET `announcements` = CASE
    WHEN `deadline` >= `UNIX_TIMESTAMP`() + 1800 THEN 0
    WHEN `deadline` >= `UNIX_TIMESTAMP`() + 900 THEN 1
    WHEN `deadline` >= `UNIX_TIMESTAMP`() + 300 THEN 3
    WHEN `deadline` >= `UNIX_TIMESTAMP`() + 60 THEN 7
    ELSE 15 END WHERE `phase` = 1;
