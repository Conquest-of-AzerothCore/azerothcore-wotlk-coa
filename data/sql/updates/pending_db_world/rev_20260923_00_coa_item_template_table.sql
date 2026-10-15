-- CoA is a core component now, so its appearance-template provenance table drops the compat name.
-- The rename runs only while the old table exists and the new one does not, so a re-run is harmless.
SELECT IF(
    EXISTS (SELECT 1 FROM `information_schema`.`TABLES`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'item_template_ascension_compat')
    AND NOT EXISTS (SELECT 1 FROM `information_schema`.`TABLES`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'item_template_coa'),
    'RENAME TABLE `item_template_ascension_compat` TO `item_template_coa`',
    'DO 0') INTO @coa_item_template_rename;
PREPARE `coa_item_template_rename` FROM @coa_item_template_rename;
EXECUTE `coa_item_template_rename`;
DEALLOCATE PREPARE `coa_item_template_rename`;
