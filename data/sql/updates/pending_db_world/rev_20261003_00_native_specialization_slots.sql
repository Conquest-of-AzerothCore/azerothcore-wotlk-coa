-- Tomes IX..XII have original client rows but are absent from the server item templates.
CREATE TEMPORARY TABLE `native_specialization_tome` ENGINE=InnoDB AS
    SELECT * FROM `item_template` WHERE `entry` = 106954;
UPDATE `native_specialization_tome` SET `entry` = 752030;
INSERT INTO `item_template` SELECT * FROM `native_specialization_tome`
ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`);
UPDATE `native_specialization_tome` SET `entry` = 752031;
INSERT INTO `item_template` SELECT * FROM `native_specialization_tome`
ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`);
UPDATE `native_specialization_tome` SET `entry` = 752032;
INSERT INTO `item_template` SELECT * FROM `native_specialization_tome`
ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`);
UPDATE `native_specialization_tome` SET `entry` = 752033;
INSERT INTO `item_template` SELECT * FROM `native_specialization_tome`
ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`);
DROP TEMPORARY TABLE `native_specialization_tome`;

-- Restore Tome names, prerequisites and learning effects from ItemAddon.dbc and ItemSpells.dbc.
UPDATE `item_template` SET `name` = 'Tome of Specialization II', `Quality` = 6,
    `requiredspell` = 0, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = -1, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979994, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106954;

UPDATE `item_template` SET `name` = 'Tome of Specialization III', `Quality` = 6,
    `requiredspell` = 979994, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979995, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106956;

UPDATE `item_template` SET `name` = 'Tome of Specialization IV', `Quality` = 6,
    `requiredspell` = 979995, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979996, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106957;

UPDATE `item_template` SET `name` = 'Tome of Specialization V', `Quality` = 6,
    `requiredspell` = 979996, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979997, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106958;

UPDATE `item_template` SET `name` = 'Tome of Specialization VI', `Quality` = 6,
    `requiredspell` = 979997, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979986, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106959;

UPDATE `item_template` SET `name` = 'Tome of Specialization VII', `Quality` = 6,
    `requiredspell` = 979986, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979987, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106960;

UPDATE `item_template` SET `name` = 'Tome of Specialization VIII', `Quality` = 6,
    `requiredspell` = 979987, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 979988, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 106961;

UPDATE `item_template` SET `name` = 'Tome of Specialization IX', `Quality` = 6,
    `requiredspell` = 979988, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84874, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 752030;

UPDATE `item_template` SET `name` = 'Tome of Specialization X', `Quality` = 6,
    `requiredspell` = 84874, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84876, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 752031;

UPDATE `item_template` SET `name` = 'Tome of Specialization XI', `Quality` = 6,
    `requiredspell` = 84876, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84878, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 752032;

UPDATE `item_template` SET `name` = 'Tome of Specialization XII', `Quality` = 6,
    `requiredspell` = 84878, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84880, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 752033;

UPDATE `item_template` SET `name` = 'Tome of Specialization XIII', `Quality` = 6,
    `requiredspell` = 84880, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84882, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97400;

UPDATE `item_template` SET `name` = 'Tome of Specialization XIV', `Quality` = 6,
    `requiredspell` = 84882, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84884, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97401;

UPDATE `item_template` SET `name` = 'Tome of Specialization XV', `Quality` = 6,
    `requiredspell` = 84884, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84886, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97402;

UPDATE `item_template` SET `name` = 'Tome of Specialization XVI', `Quality` = 6,
    `requiredspell` = 84886, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84888, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97403;

UPDATE `item_template` SET `name` = 'Tome of Specialization XVII', `Quality` = 6,
    `requiredspell` = 84888, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84890, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97404;

UPDATE `item_template` SET `name` = 'Tome of Specialization XVIII', `Quality` = 6,
    `requiredspell` = 84890, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84892, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97405;

UPDATE `item_template` SET `name` = 'Tome of Specialization XIX', `Quality` = 6,
    `requiredspell` = 84892, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84894, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97406;

UPDATE `item_template` SET `name` = 'Tome of Specialization XX', `Quality` = 6,
    `requiredspell` = 84894, `spellid_1` = 55884, `spelltrigger_1` = 0,
    `spellcharges_1` = 0, `spellcooldown_1` = 0, `spellcategory_1` = 3600,
    `spellcategorycooldown_1` = -1, `spellid_2` = 84896, `spelltrigger_2` = 6,
    `spellcharges_2` = -1, `spellcooldown_2` = 0, `spellcategory_2` = 3600,
    `spellcategorycooldown_2` = -1 WHERE `entry` = 97407;

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_specialization_slot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(979993, 'spell_ascension_specialization_slot'),
(979994, 'spell_ascension_specialization_slot'),
(979995, 'spell_ascension_specialization_slot'),
(979996, 'spell_ascension_specialization_slot'),
(979997, 'spell_ascension_specialization_slot'),
(979986, 'spell_ascension_specialization_slot'),
(979987, 'spell_ascension_specialization_slot'),
(979988, 'spell_ascension_specialization_slot'),
(84874, 'spell_ascension_specialization_slot'),
(84876, 'spell_ascension_specialization_slot'),
(84878, 'spell_ascension_specialization_slot'),
(84880, 'spell_ascension_specialization_slot'),
(84882, 'spell_ascension_specialization_slot'),
(84884, 'spell_ascension_specialization_slot'),
(84886, 'spell_ascension_specialization_slot'),
(84888, 'spell_ascension_specialization_slot'),
(84890, 'spell_ascension_specialization_slot'),
(84892, 'spell_ascension_specialization_slot'),
(84894, 'spell_ascension_specialization_slot'),
(84896, 'spell_ascension_specialization_slot');

-- Ethereal Bazaar convenience stock; ExtendedCost 2984 is 150 Bazaar Tokens.
DELETE FROM `npc_vendor` WHERE `entry` = 900008 AND `item` IN (
    106954, 106956, 106957, 106958, 106959, 106960, 106961, 752030, 752031, 752032,
    752033, 97400, 97401, 97402, 97403, 97404, 97405, 97406, 97407);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `ExtendedCost`) VALUES
(900008, 27, 106954, 2984),
(900008, 28, 106956, 2984),
(900008, 29, 106957, 2984),
(900008, 30, 106958, 2984),
(900008, 31, 106959, 2984),
(900008, 32, 106960, 2984),
(900008, 33, 106961, 2984),
(900008, 34, 752030, 2984),
(900008, 35, 752031, 2984),
(900008, 36, 752032, 2984),
(900008, 37, 752033, 2984),
(900008, 38, 97400, 2984),
(900008, 39, 97401, 2984),
(900008, 40, 97402, 2984),
(900008, 41, 97403, 2984),
(900008, 42, 97404, 2984),
(900008, 43, 97405, 2984),
(900008, 44, 97406, 2984),
(900008, 45, 97407, 2984);
