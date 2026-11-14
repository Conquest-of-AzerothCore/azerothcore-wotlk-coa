--
CREATE TABLE IF NOT EXISTS `coa_challenge_failure_snapshot` (
    `guid` INT UNSIGNED NOT NULL,
    `failedChallengeId` INT UNSIGNED NOT NULL,
    `challengeId` INT UNSIGNED NOT NULL,
    `level` INT UNSIGNED NOT NULL DEFAULT 1,
    `deaths` INT UNSIGNED NOT NULL DEFAULT 0,
    `hunger` INT NOT NULL DEFAULT 0,
    `thirst` INT NOT NULL DEFAULT 0,
    `fatigue` INT NOT NULL DEFAULT 0,
    `startTime` INT UNSIGNED NOT NULL DEFAULT 0,
    `trialId` VARCHAR(64) NOT NULL DEFAULT '',
    `trialStartTime` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`, `failedChallengeId`, `challengeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
