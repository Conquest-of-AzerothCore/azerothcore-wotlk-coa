--
-- Son of Ursoc (#726): Savage Frenzy owns the transformation and movement cleanse.
-- Archived NPC 421493 uses display 328642 (Unleashed Golden Saberon), present in the copied client.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 421493;
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `family`)
SELECT 421493, 'Incarnation: Unleashed Golden Saberon', 1, 1, 35, 1, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 421493);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 421493;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (421493, 0, 328642, 1, 1);

-- This is a transformation-only template; players retain their native combat reach.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 328642;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES (328642, 0.306, 1.5, 0, 0);

SET @ScriptName = 'aura_ascension_son_of_ursoc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 806549 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (806549, @ScriptName);
