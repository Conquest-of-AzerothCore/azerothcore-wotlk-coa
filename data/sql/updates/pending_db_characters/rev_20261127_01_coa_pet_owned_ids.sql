SELECT IF(EXISTS (
  SELECT 1 FROM `information_schema`.`COLUMNS`
  WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_pet_journal' AND `COLUMN_NAME` = 'pet_id'
), 'DO 0', 'ALTER TABLE `coa_pet_journal` ADD COLUMN `pet_id` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `account`')
INTO @pet_id_ddl;
PREPARE pet_id_migration FROM @pet_id_ddl;
EXECUTE pet_id_migration;
DEALLOCATE PREPARE pet_id_migration;

UPDATE `coa_pet_journal` SET `pet_id` = `species` WHERE `pet_id` = 0;

SELECT IF(EXISTS (
  SELECT 1 FROM `information_schema`.`STATISTICS`
  WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_pet_journal'
    AND `INDEX_NAME` = 'PRIMARY' AND `COLUMN_NAME` = 'pet_id'
), 'DO 0', 'ALTER TABLE `coa_pet_journal` DROP PRIMARY KEY, ADD PRIMARY KEY (`account`, `pet_id`)')
INTO @pet_id_ddl;
PREPARE pet_id_migration FROM @pet_id_ddl;
EXECUTE pet_id_migration;
DEALLOCATE PREPARE pet_id_migration;

SELECT IF(EXISTS (
  SELECT 1 FROM `information_schema`.`COLUMNS`
  WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_pet_follower' AND `COLUMN_NAME` = 'species'
), 'ALTER TABLE `coa_pet_follower` CHANGE COLUMN `species` `pet_id` INT UNSIGNED NOT NULL', 'DO 0') INTO @pet_id_ddl;
PREPARE pet_id_migration FROM @pet_id_ddl;
EXECUTE pet_id_migration;
DEALLOCATE PREPARE pet_id_migration;
