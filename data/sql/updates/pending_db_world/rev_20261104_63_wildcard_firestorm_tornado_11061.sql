-- Wildcard Firestorm (280575, Hero ranks 280635-280638) summons the Fiery Tornado 280576, which the database lacked,
-- so nothing appeared (#11061). Creature from the live creature cache: invisible display 11686, HealthModifier 0.3,
-- type 7. Its passive 280577 carries the tornado visual and ticks the rank's damage and knockback through the
-- summoned-effect engine.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `family`, `type`, `HealthModifier`, `ManaModifier`, `ScriptName`) VALUES
(280576, 'Fiery Tornado', NULL, 1, 80, 35, 1, 1.14286, 0, 2000, 2000, 1, 0, 7, 0.3, 1.0, 'npc_ascension_summoned_effect') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`), `family` = VALUES(`family`), `type` = VALUES(`type`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 280576;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(280576, 0, 11686, 1, 1);

DELETE FROM `spell_script_names` WHERE `spell_id` = 280577 AND `ScriptName` = 'aura_ascension_summoned_effect_tick';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(280577, 'aura_ascension_summoned_effect_tick');
