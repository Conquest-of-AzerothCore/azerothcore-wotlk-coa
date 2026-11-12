-- Call Board Temporal Contracts: paid Complete Now completions per contract type in the current reset week.
SELECT IF(
    EXISTS(SELECT 1 FROM `information_schema`.`columns` WHERE `table_schema` = DATABASE()
        AND `table_name` = 'character_callboard_contract' AND `column_name` = 'purchases'),
    'DO 0',
    'ALTER TABLE `character_callboard_contract`
     ADD COLUMN `purchases` int unsigned NOT NULL DEFAULT 0 AFTER `completions`') INTO @coa_callboard_purchases_sql;
PREPARE coa_callboard_purchases FROM @coa_callboard_purchases_sql;
EXECUTE coa_callboard_purchases;
DEALLOCATE PREPARE coa_callboard_purchases;
