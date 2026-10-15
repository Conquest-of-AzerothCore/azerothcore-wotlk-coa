-- Surge of Might (#1395): the ally aura 520084 has ProcFlags 0 in Spell.dbc, so SpellMgr::LoadSpellProcs built no
-- fallback entry and Aura::GetProcEffectMask refused to proc it; the promised Nature damage 573254 never happened.
-- The row mirrors Neptulon's Wrath (rev_1789953853862044800.sql): ProcFlags 69972 is the six "done direct damage"
-- flags 0x4|0x10|0x40|0x100|0x1000|0x10000, with the script restricting the proc to the owner's own hits.
-- 573254 carries the caster's spell power forwarded by 520083, so its own coefficients stay at zero.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 520084;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520084, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_surge_of_might';
DELETE FROM `spell_script_names` WHERE `spell_id` = 520084 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (520084, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` = 573254;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(573254, 0, 0, 0, 0, 'Surge of Might: forwarded caster SP, no second coefficient');
COMMIT;
