DELETE FROM `spell_proc` WHERE `SpellId` = 531128;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `Chance`) VALUES
(531128, 332116, 1, 2, 3, 5);

DELETE FROM `spell_script_names` WHERE `spell_id` = 531128 AND `ScriptName` = 'aura_ascension_necromancer_overwhelming_force';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(531128, 'aura_ascension_necromancer_overwhelming_force');
