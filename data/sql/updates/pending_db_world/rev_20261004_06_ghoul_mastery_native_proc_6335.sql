DELETE FROM `spell_proc` WHERE `SpellId` = 503740;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `Chance`) VALUES
(503740, 332116, 1, 2, 3, 15);

DELETE FROM `spell_script_names` WHERE `spell_id` = 503740 AND `ScriptName` = 'aura_ascension_necromancer_ghoul_mastery';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(503740, 'aura_ascension_necromancer_ghoul_mastery');
