-- Wildcard March of the Dead 280510 (#10616) copies the Necromancer's 707007: SCRIPT_EFFECT, 5+1 creatures 280511,
-- SummonProperties 61, 30 s, 'each undead marches forward, exploding when it reaches an enemy'. Its explosion is
-- 280512 March of the Dead [Damage] (560 Plague in 5 yd, -72% speed in 8 yd for 3 s). Creature 280511 had no
-- template and nothing handled the script effect, so the cast spent rage and did nothing. The live creature cache
-- records creature 280511 'Zombie', type 6, display 25495, HealthModifier 1; display 25495 uses the same 0.3
-- scale as the Necromancer's Zombie 523032 (rev_20260909_03).
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`, `HealthModifier`, `flags_extra`, `ScriptName`) VALUES
(280511, 'Zombie', 1, 1, 35, 1, 6, 2000, 2000, 1, 64, 'npc_wildcard_march_of_the_dead_zombie')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`),
`HealthModifier` = VALUES(`HealthModifier`), `flags_extra` = VALUES(`flags_extra`),
`ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 280511;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(280511, 0, 25495, 0.3, 1);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_wildcard_march_of_the_dead';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(280510, 'spell_wildcard_march_of_the_dead');
