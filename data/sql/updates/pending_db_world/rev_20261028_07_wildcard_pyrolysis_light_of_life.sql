-- Card-specific refresh and healing paths; no global effect 198 implementation.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (271544, 271489)
AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 271544 AND `ScriptName` = 'aura_wildcard_pyrolysis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271544, 'aura_wildcard_pyrolysis');
DELETE FROM `spell_script_names` WHERE `spell_id` = 271546 AND `ScriptName` = 'spell_wildcard_pyrolysis_refresh';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271546, 'spell_wildcard_pyrolysis_refresh');
DELETE FROM `spell_script_names` WHERE `spell_id` = 271489 AND `ScriptName` = 'aura_wildcard_light_of_life';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271489, 'aura_wildcard_light_of_life');
DELETE FROM `spell_script_names` WHERE `spell_id` = 271490
AND `ScriptName` IN ('aura_wildcard_light_of_life_hot', 'spell_wildcard_light_of_life_renew');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(271490, 'aura_wildcard_light_of_life_hot'),
(271490, 'spell_wildcard_light_of_life_renew');
DELETE FROM `spell_proc` WHERE `SpellId` IN (271544, 271489);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `AttributesMask`, `Chance`) VALUES
(271544, 327680, 1, 2, 2, 100),
(271489, 87376, 2, 2, 2, 100);
DELETE FROM `spell_bonus_data` WHERE `entry` = 271490;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(271490, 0, 0.12, 0, 0.024, 'Wildcard Light of Life periodic healing');
