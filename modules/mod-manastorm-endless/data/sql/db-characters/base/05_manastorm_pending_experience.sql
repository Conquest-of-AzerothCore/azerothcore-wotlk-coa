-- Apply to acore_characters before starting the updated server.
-- Floor completion adds base XP in the same transaction as progression/rewards.
-- Online members claim immediately; disconnected members claim on login.
-- A claim saves character level/XP and debits this balance in one transaction.
-- RDF quest rates, quest XP auras and XP hooks are evaluated when claiming.
CREATE TABLE IF NOT EXISTS `character_manastorm_pending_experience`
(
    `guid` INT UNSIGNED NOT NULL,
    `base_xp` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
