-- Optional second character name; existing names and character GUIDs are preserved.
ALTER TABLE `characters`
  MODIFY `name` varchar(25) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_bin` NOT NULL,
  MODIFY `deleteInfos_Name` varchar(25) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` DEFAULT NULL;

ALTER TABLE `gm_ticket`
  MODIFY `name` varchar(25) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` NOT NULL
    COMMENT 'Name of ticket creator';

ALTER TABLE `reserved_name`
  MODIFY `name` varchar(25) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_bin` NOT NULL;

ALTER TABLE `profanity_name`
  MODIFY `name` varchar(25) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_bin` NOT NULL;

ALTER TABLE `character_declinedname`
  MODIFY `genitive` varchar(31) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` NOT NULL DEFAULT '',
  MODIFY `dative` varchar(31) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` NOT NULL DEFAULT '',
  MODIFY `accusative` varchar(31) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` NOT NULL DEFAULT '',
  MODIFY `instrumental` varchar(31) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` NOT NULL DEFAULT '',
  MODIFY `prepositional` varchar(31) CHARACTER SET `utf8mb4` COLLATE `utf8mb4_unicode_ci` NOT NULL DEFAULT '';
