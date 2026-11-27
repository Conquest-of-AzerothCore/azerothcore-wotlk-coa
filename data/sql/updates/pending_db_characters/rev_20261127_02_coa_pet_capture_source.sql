SELECT IF(EXISTS (
  SELECT 1 FROM `information_schema`.`COLUMNS`
  WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_pet_journal' AND `COLUMN_NAME` = 'breed'
), 'DO 0', CONCAT(
  'ALTER TABLE `coa_pet_journal` ADD COLUMN `breed` TINYINT UNSIGNED NOT NULL DEFAULT 0, ',
  'ADD COLUMN `source` TINYINT UNSIGNED NOT NULL DEFAULT 0'
)) INTO @pet_capture_ddl;
PREPARE pet_capture_migration FROM @pet_capture_ddl;
EXECUTE pet_capture_migration;
DEALLOCATE PREPARE pet_capture_migration;
