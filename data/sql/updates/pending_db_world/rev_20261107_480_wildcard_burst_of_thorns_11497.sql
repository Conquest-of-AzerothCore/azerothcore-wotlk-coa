-- Burst of Thorns (282195) never procs: a PROC_TRIGGER_SPELL aura needs a spell_proc row. Effect 0 casts the
-- thorns damage (282196, once per 1 sec), effect 1 grants Thornscale (282197, once per 8 sec), each timed by its
-- own coa_mystic_enchant_proc rule; the aura-wide spell_proc Cooldown stays 0 so one cannot gate the other.
DELETE FROM `spell_script_names` WHERE `spell_id` = 282195 AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(282195, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 282195;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `comment`) VALUES
(282195, 0, 0, 'damaged', 0, '', 100, 1000, '', '', '', '', 'Burst of Thorns damage'),
(282195, 1, 0, 'damaged', 0, '', 100, 8000, '', '', '', '', 'Burst of Thorns Thornscale');

DELETE FROM `spell_proc` WHERE `SpellId` = 282195;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(282195, 0, 0, 0, 0, 0, 0x2A8, 0, 0, 0, 0, 0, 0, 100, 0, 0);
