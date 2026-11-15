-- Call of the Darkwing's Shadow Bats (NPC 50069) never cast Bat Bite 802358 and instead auto-attacked
-- perpetually under REACT_DEFENSIVE (src/server/coa/AscensionBloodmageDarkwing.cpp), matching issue #10614's
-- lag reports on large pulls. Live Ascension combat logs (2026-07-13) show each bat landing exactly one
-- SWING-adjacent Bat Bite hit and then staying idle until its 15 sec duration expires; up to 10 bats were
-- observed alive at once. The fix lets each bat cast Bat Bite exactly once (ScriptName below) and caps live
-- Shadow Bats per owner at 10 (AscensionBloodmageDarkwing.cpp), removing the old perpetual-autoattack path.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`, `ScriptName`) VALUES
(50069, 'Shadow Bat', 1, 1, 0, 35, 1, 12, 2000, 2000, 'npc_ascension_bloodmage_shadow_bat')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`),
`ScriptName` = VALUES(`ScriptName`);

DELETE FROM `spell_script_names` WHERE `spell_id` = 802358 AND `ScriptName` = 'spell_ascension_bloodmage_bat_bite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(802358, 'spell_ascension_bloodmage_bat_bite');
