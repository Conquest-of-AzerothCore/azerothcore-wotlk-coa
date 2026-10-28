CREATE TABLE IF NOT EXISTS `coa_client_shapeshift_form` (
  `ID` INT UNSIGNED NOT NULL,
  `BonusActionBar` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Guardian formations keep the main action bar instead of paging to their own bar like warrior stances.
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` IN (35, 36, 37);
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(35, 0),
(36, 0),
(37, 0);
