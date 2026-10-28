-- Runemaster Earth, Wind, and Fire (706531, #591): a Runic Explosion (712324) that strikes its fifth enemy casts
-- Wild Steam (803737) around the Runemaster.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 712324 AND `ScriptName` = 'spell_ascension_runemaster_earth_wind_and_fire';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(712324, 'spell_ascension_runemaster_earth_wind_and_fire');

-- Wild Steam (803737): ${$m1*$<scalingbp>+$AP*.25} Frostfire damage.
DELETE FROM `spell_bonus_data` WHERE `entry` = 803737;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(803737, 0, 0, 0.25, 0, 'Ascension Runemaster Wild Steam - AP');

-- Runemaster Prismatic Flow (705581, #593): Spell.dbc carries ProcFlags 0, so SpellMgr::LoadSpellProcs generates no
-- entry and its SPELL_AURA_PROC_TRIGGER_SPELL never casts 705582 (+40% movement speed for 2 sec). Casting Phase Out
-- (500671, SpellFamilyName 38 mask0 0x40, unique in the family) is a DmgClass NONE cast of either positivity; the
-- dummy effect 1 carries no trigger spell.
DELETE FROM `spell_proc` WHERE `SpellId` = 705581;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705581, 0, 38, 64, 0, 0, 5120, 0, 1, 0, 0, 2, 0, 100, 0, 0);

-- Runemaster Fracture (803018, #595): ${$m1+0+$AP*1.5} Frost damage.
DELETE FROM `spell_bonus_data` WHERE `entry` = 803018;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(803018, 0, 0, 1.5, 0, 'Ascension Runemaster Fracture - AP');
