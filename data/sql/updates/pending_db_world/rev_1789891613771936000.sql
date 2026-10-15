--
-- Spiritbound (#630): each missed, dodged or parried incoming attack grants 5 Rage and Seismic CDR.
DELETE FROM `spell_proc` WHERE `SpellId` = 681364;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(681364, 0, 0, 0, 0, 0, 680, 0, 0, 52, 2, 0, 0, 100, 0, 0);

-- Apply the helper to active ranks and to the newer Seismic Grasp sharing their cooldown.
SET @ScriptName = 'spell_ascension_spiritbound_cooldowns';
DELETE FROM `spell_script_names` WHERE `spell_id` = 681365 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681365, @ScriptName);
