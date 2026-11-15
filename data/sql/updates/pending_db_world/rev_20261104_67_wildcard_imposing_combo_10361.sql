-- Wildcard Imposing Combo 285598 (#10361) is a passive dummy whose tooltip names Divine Storm, Victory Rush and
-- Stormstrike buffs ($285603s1, $285604s1, $285605s1). Its helpers 285599/285600/285601 hold the per-ability class
-- masks: effect 1 PROC_TRIGGER_SPELL the buff (Imposing Divinity 285603, Imposing Victory 285604, Imposing Storm
-- 285605; SpellDuration 2000..12000 ms, which Unit::CalcSpellDuration spreads as 2 s + 2 s per combo point) and
-- effect 2 PROC_TRIGGER_SPELL Clear Combo Points 283170. Nothing applied the helpers, they had no spell_proc row
-- (DBC ProcFlags 0), and 283170 is a bare dummy. The helpers now ride on the passive and proc once per cast, on a
-- successful hit against the target holding the combo points (aura_wildcard_imposing_combo_ability).
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 285598 AND `spell_effect` IN (285599, 285600, 285601) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(285598, 285599, 2, 'Wildcard Imposing Combo - Divine Storm helper'),
(285598, 285600, 2, 'Wildcard Imposing Combo - Victory Rush helper'),
(285598, 285601, 2, 'Wildcard Imposing Combo - Stormstrike helper');

DELETE FROM `spell_proc` WHERE `SpellId` IN (285599, 285600, 285601);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(285599, 0, 10, 0, 0x20000, 0, 0x10, 0x1, 0x2, 0x3, 0, 0, 0, 100, 0, 0),
(285600, 0, 4, 0, 0x100, 0, 0x10, 0x1, 0x2, 0x3, 0, 0, 0, 100, 0, 0),
(285601, 0, 11, 0, 0x1000010, 0, 0x10, 0x1, 0x2, 0x3, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 283170 AND `ScriptName` = 'spell_wildcard_imposing_combo_clear_combo_points';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (285599, 285600, 285601) AND `ScriptName` = 'aura_wildcard_imposing_combo_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(283170, 'spell_wildcard_imposing_combo_clear_combo_points'),
(285599, 'aura_wildcard_imposing_combo_ability'),
(285600, 'aura_wildcard_imposing_combo_ability'),
(285601, 'aura_wildcard_imposing_combo_ability');
