-- Destabilize Time (680971): "Reduces enemy casting speed by $570761s1% for $d, increasing by $570761s1% every
-- time they cast. Gaining stacks does not extend the duration of the spell." 680971 is the visible 20 sec,
-- 10-stack debuff, but its only effect is aura 42 with EffectTriggerSpell 0 and ProcFlags 0, so it never
-- fired and slowed nothing. The slow lives in 570761 (SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK -10, 10 stacks,
-- SPELL_ATTR1_NO_AURA_ICON), which nothing cast. spell_ascension_destabilize_time keeps 570761 on the target
-- with 680971's stacks and remaining duration, and adds one stack, without refreshing, on each spell the
-- debuffed unit casts: the proc fires in the CAST phase, which Spell::_cast emits only for non-triggered casts.
DELETE FROM `spell_script_names` WHERE `spell_id` = 680971 AND `ScriptName` = 'spell_ascension_destabilize_time';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680971, 'spell_ascension_destabilize_time');
DELETE FROM `spell_proc` WHERE `SpellId` = 680971;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (680971, 0, 0, 0, 0, 0, 87312, 7, 1, 0, 0, 0, 0, 100, 0, 0);
