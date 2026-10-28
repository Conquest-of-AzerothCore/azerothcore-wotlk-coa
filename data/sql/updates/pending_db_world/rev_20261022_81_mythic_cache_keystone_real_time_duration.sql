-- Mythical Caches (24 h) and Mythic Keystones (7 days) count down while their owner is logged off (ITEM_FLAGS_CU_DURATION_REAL_TIME)
UPDATE `item_template` SET `flagsCustom` = `flagsCustom` | 1 WHERE `name` = 'Mythical Cache' AND `duration` = 86400 AND `spellid_1` = 84284;
UPDATE `item_template` SET `flagsCustom` = `flagsCustom` | 1 WHERE `name` LIKE 'Keystone:%' AND `duration` = 604800 AND `spellid_1` = 161;
