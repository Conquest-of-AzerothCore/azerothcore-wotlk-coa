-- The Reborn Fire Ward and Frost Ward ranks took Abjurer's Ward's script (rev_20261029_59), and a twin with a script of
-- its own is not given its stock spell's: they lost spell_mage_fire_frost_ward (Frost Warding's negate and mana, the
-- spell power bonus, Incanter's Absorption). Both scripts run.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_fire_frost_ward' AND `spell_id` IN (1100543, 1108457,
1108458, 1110223, 1110225, 1127128, 1143010, 1106143, 1108461, 1108462, 1110177, 1128609, 1132796, 1143012);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1100543, 'spell_mage_fire_frost_ward'),
(1108457, 'spell_mage_fire_frost_ward'),
(1108458, 'spell_mage_fire_frost_ward'),
(1110223, 'spell_mage_fire_frost_ward'),
(1110225, 'spell_mage_fire_frost_ward'),
(1127128, 'spell_mage_fire_frost_ward'),
(1143010, 'spell_mage_fire_frost_ward'),
(1106143, 'spell_mage_fire_frost_ward'),
(1108461, 'spell_mage_fire_frost_ward'),
(1108462, 'spell_mage_fire_frost_ward'),
(1110177, 'spell_mage_fire_frost_ward'),
(1128609, 'spell_mage_fire_frost_ward'),
(1132796, 'spell_mage_fire_frost_ward'),
(1143012, 'spell_mage_fire_frost_ward');
