-- Wildcard Seal of Arcane Wrath 277854 (#10602) is a column-for-column copy of Seal of Righteousness 21084
-- (attributes, ProcFlags 0x14, family flags 0x8000000/0x20000000) and its damage spell 277856 copies 25742; the
-- tooltip says it 'Scales with Seal of Righteousness modifiers'. Like Seal of Fervor 272087 it had neither a
-- spell_proc row nor a script, so main hand auto attacks and Paladin melee abilities dealt no Arcane damage. Each
-- now deals 277856 for the Seal of Righteousness 21084 per-hit formula 1 + MWS * (0.0085 * AP + 0.072 * SP),
-- with Arcane spell power.
-- Judging the seal cast its effect 2 dummy amount 277856 (BasePoints -1, 0 damage). The seal script now points
-- the judgement at Judgement of Arcane Wrath 277857 ('${1+0.325*$AP+0.5*$SPA} Arcane damage'), whose coefficients
-- are carried by spell_bonus_data like Judgement of Righteousness 20187 (0.32 SP, 0.2 AP).
DELETE FROM `spell_proc` WHERE `SpellId` = 277854;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(277854, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0x2, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_wildcard_seal_of_arcane_wrath';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(277854, 'aura_wildcard_seal_of_arcane_wrath');

DELETE FROM `spell_bonus_data` WHERE `entry` = 277857;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(277857, 0.5, 0, 0.325, 0, 'Wildcard Judgement of Arcane Wrath: 1 + 0.325 AP + 0.5 Arcane SP');
