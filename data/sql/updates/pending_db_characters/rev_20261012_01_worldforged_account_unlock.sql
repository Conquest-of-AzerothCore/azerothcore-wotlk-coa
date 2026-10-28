-- Raid bosses an account has defeated, unlocking the Worldforged upgrade tiers above the first
CREATE TABLE IF NOT EXISTS `worldforged_account_unlock` (
  `account` INT UNSIGNED NOT NULL,
  `creature` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`account`, `creature`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
