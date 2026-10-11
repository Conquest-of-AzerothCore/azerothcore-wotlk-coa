CREATE TABLE IF NOT EXISTS `coa_account_challenge_completion` (
    `account` INT UNSIGNED NOT NULL,
    `challengeId` INT UNSIGNED NOT NULL,
    `level` INT UNSIGNED NOT NULL DEFAULT 1,
    `completeTime` INT UNSIGNED NOT NULL DEFAULT 0,
    `startTime` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account`, `challengeId`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT IF(
    EXISTS(SELECT 1 FROM `information_schema`.`tables` WHERE `table_schema` = DATABASE() AND `table_name` = 'coa_challenge_completion'),
    'INSERT IGNORE INTO `coa_account_challenge_completion` (`account`, `challengeId`, `level`, `completeTime`, `startTime`)
     SELECT `character`.`account`, `completion`.`challengeId`, `completion`.`level`, `completion`.`completeTime`, `completion`.`startTime`
     FROM `coa_challenge_completion` AS `completion`
     INNER JOIN `characters` AS `character` ON `character`.`guid` = `completion`.`guid`
     ORDER BY `completion`.`completeTime`, `completion`.`guid`',
    'DO 0') INTO @coa_trial_backfill_sql;
PREPARE coa_trial_backfill FROM @coa_trial_backfill_sql;
EXECUTE coa_trial_backfill;
DEALLOCATE PREPARE coa_trial_backfill;
