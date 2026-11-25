UPDATE `item_template`
SET `duration` = 0, `flagsCustom` = `flagsCustom` & ~1
WHERE `name` LIKE 'Keystone:%' AND `spellid_1` = 161;
