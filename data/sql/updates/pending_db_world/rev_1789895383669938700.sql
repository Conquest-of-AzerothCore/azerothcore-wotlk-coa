--
-- Rockslide (#638): one 15 percent roll per completed Stoneshard, including its own delayed repeats.
-- Triggered spells skip CAST-phase procs; FINISH runs for both original casts and repeats.
DELETE FROM `spell_proc` WHERE `SpellId` = 560154;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560154, 0, 37, 0, 512, 0, 65536, 0, 4, 0, 2, 0, 0, 15, 0, 0);

SET @ScriptName = 'aura_ascension_rockslide';
DELETE FROM `spell_script_names` WHERE `spell_id` = 560154 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (560154, @ScriptName);
