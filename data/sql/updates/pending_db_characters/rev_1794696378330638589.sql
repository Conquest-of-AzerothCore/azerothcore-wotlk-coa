--
CREATE TABLE IF NOT EXISTS `coa_challenge_failure_snapshot` (
    `guid` INT UNSIGNED NOT NULL,
    `challengeId` INT UNSIGNED NOT NULL,
    `level` INT UNSIGNED NOT NULL DEFAULT 1,
    `deaths` INT UNSIGNED NOT NULL DEFAULT 0,
    `startTime` INT UNSIGNED NOT NULL DEFAULT 0,
    `characterLevel` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`, `challengeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
