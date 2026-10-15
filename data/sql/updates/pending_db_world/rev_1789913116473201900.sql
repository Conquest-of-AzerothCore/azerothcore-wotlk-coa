--
-- Primordial Earth (#944): melee critical hits summon one Spirit of Life for an immediate Lesser Spirit Charge.
DELETE FROM `spell_proc` WHERE `SpellId` = 806536;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806536, 0, 0, 0, 0, 0, 20, 1, 2, 2, 2, 0, 0, 100, 0, 0);

-- Archived NPC 840002 identifies display 8824; its Ent model exists in the copied client.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 840002;
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`)
SELECT 840002, 'Spirit of Life', 1, 1, 35, 1, 6
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 840002);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 840002;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (840002, 0, 8824, 1, 1);

SET @ScriptName = 'spell_ascension_primordial_spirit';
DELETE FROM `spell_script_names` WHERE `spell_id` = 572853 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (572853, @ScriptName);

DELETE FROM `spell_bonus_data` WHERE `entry` = 572830;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (572830, 0, 0, 0, 0, 'Primordial Earth: owner Nature SP and AP supplied before native effect modifiers');

SET @ScriptName = 'spell_ascension_lesser_spirit_charge';
DELETE FROM `spell_script_names` WHERE `spell_id` = 572830 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (572830, @ScriptName);
