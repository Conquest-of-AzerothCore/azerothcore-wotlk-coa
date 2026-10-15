--
-- Primal Totem (#1093): restore the archived creature and its 15-second raid-stat summon.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 224861;
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`)
SELECT 224861, 'Primal Totem', 1, 1, 35, 1, 11
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 224861);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 224861;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (224861, 0, 16997, 1, 1);

SET @ScriptName = 'spell_ascension_primal_totem';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504229 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504229, @ScriptName);
