-- PTR character copies (.ptr copy): the source realm's character guid, its live copy here and when it was made.
CREATE TABLE IF NOT EXISTS `coa_ptr_character_copy` (
  `source_guid` int unsigned NOT NULL,
  `account` int unsigned NOT NULL,
  `target_guid` int unsigned NOT NULL,
  `copied_at` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`source_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
