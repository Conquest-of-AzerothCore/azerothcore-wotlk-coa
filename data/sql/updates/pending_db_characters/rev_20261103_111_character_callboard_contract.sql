-- Call Board Temporal Contracts: completions of every contract type per character in the current reset week.
CREATE TABLE IF NOT EXISTS `character_callboard_contract` (
  `guid` int unsigned NOT NULL,
  `contract_type` varchar(64) NOT NULL,
  `week_start` int unsigned NOT NULL,
  `completions` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `contract_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
