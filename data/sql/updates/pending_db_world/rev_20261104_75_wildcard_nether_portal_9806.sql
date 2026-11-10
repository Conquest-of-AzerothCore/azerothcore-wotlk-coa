-- Wildcard Nether Portal (290441): the portal anchor 840095 and its demons, from the live creature cache
-- (840097 Void Terror only in the Exiles export). Shadow Bolt, Incinerate and Soul Fire under 290443 summon them.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `family`, `type`, `HealthModifier`, `ManaModifier`, `ScriptName`) VALUES
(840095, 'Nether Portal', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 0, 10, 1.0, 1.0, 'npc_ascension_summoned_effect'),
(840096, 'Satyr', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 23, 3, 0.44, 0.33, 'npc_wildcard_nether_portal_demon'),
(840097, 'Void Terror', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 23, 3, 0.44, 0.33, 'npc_wildcard_nether_portal_demon'),
(840098, 'Wrathguard', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 23, 3, 0.5, 0.33, 'npc_wildcard_nether_portal_demon'),
(840099, 'Darkhound', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 23, 3, 0.44, 0.33, 'npc_wildcard_nether_portal_demon'),
(840101, 'Dreadlord', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 23, 3, 0.44, 0.33, 'npc_wildcard_nether_portal_demon'),
(840102, 'Shivarra', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 23, 3, 0.36, 0.33, 'npc_wildcard_nether_portal_demon') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `family` = VALUES(`family`), `type` = VALUES(`type`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (840095, 840096, 840097, 840098, 840099, 840101, 840102);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(840095, 0, 11686, 1, 1),
(840096, 0, 2878, 1, 1),
(840097, 0, 19368, 1, 1),
(840098, 0, 20045, 1, 1),
(840099, 0, 9021, 1, 1),
(840101, 0, 348, 1, 1),
(840102, 0, 19586, 1, 1);

DELETE FROM `spell_script_names` WHERE `spell_id` = 290441 AND `ScriptName` = 'spell_ascension_summoned_effect_summon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (290441, 'spell_ascension_summoned_effect_summon');
