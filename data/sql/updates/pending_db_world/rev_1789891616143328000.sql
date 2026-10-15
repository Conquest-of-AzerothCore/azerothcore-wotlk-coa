--
-- Earthmaker (#633): actual Seismic/Quake damage triggers the native one-second Earthen Avatar reduction.
DELETE FROM `spell_proc` WHERE `SpellId` = 560150;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560150, 0, 37, 16, 4194304, 263424, 332048, 1, 2, 3, 2, 2, 0, 100, 0, 0);

SET @ScriptName = 'aura_ascension_earthmaker';
DELETE FROM `spell_script_names` WHERE `spell_id` = 560150 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560150, @ScriptName);
