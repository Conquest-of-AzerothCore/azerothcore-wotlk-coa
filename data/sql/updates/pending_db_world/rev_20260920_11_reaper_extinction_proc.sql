-- Extinction (573039) never triggered.
--
-- The talent is a plain SPELL_AURA_PROC_TRIGGER_SPELL that casts the Stack Adder 520501, which is
-- what grants the Extinction buff 560414. Its DBC record carries ProcTypeMask 0, so the aura has no
-- proc event to hook and SpellMgr builds it with no proc flags at all: the handler is installed and
-- then nothing can ever reach it. The character owns the talent, the tooltip reads correctly, and
-- the buff is unobtainable.
--
-- spell_proc supplies what the record omits rather than editing the client's Spell.dbc, which the
-- realm and every player share.
--
-- ProcFlags 20 = PROC_FLAG_DONE_MELEE_AUTO_ATTACK (0x4) | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS
-- (0x10), the two ways a Reaper deals the "direct Physical damage" the tooltip names. SchoolMask 1
-- keeps it to Physical, SpellTypeMask 1 to damaging spells and SpellPhaseMask 2 to a landed hit, so
-- a dodge or a miss does not spend the roll.
--
-- Chance 100 hands every qualifying hit to spell_ascension_reaper_extinction, which does the real
-- roll: the tooltip's 5% plus 10% for each Reaped Soul the character is holding.
DELETE FROM `spell_proc` WHERE `SpellId` = 573039;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (573039, 1, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 100, 0, 0);

-- RegisterSpellScript only makes the script available; spell_script_names is what binds it to a
-- spell, and without the row the world logs "Script named
-- 'spell_ascension_reaper_extinction' is not assigned in the database" and the roll never runs.
DELETE FROM `spell_script_names` WHERE `spell_id` = 573039 AND `ScriptName` = 'spell_ascension_reaper_extinction';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(573039, 'spell_ascension_reaper_extinction');

-- The buff never came off either. Extinction 560414 carries its own
-- SPELL_AURA_PROC_TRIGGER_SPELL for the Stack Remover 561113, and its record has the same empty
-- ProcTypeMask, so the free Slaughter went out and the buff stayed. ProcFlags 16 =
-- PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS with SpellPhaseMask 1 fires on the cast rather than on the
-- hit, so the cost reduction and the health exemption are already spent when it goes.
-- spell_ascension_reaper_extinction_buff narrows that to the seven Slaughter ranks.
DELETE FROM `spell_proc` WHERE `SpellId` = 560414;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (560414, 0, 0, 0, 0, 0, 16, 1, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 560414
  AND `ScriptName` = 'spell_ascension_reaper_extinction_buff';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560414, 'spell_ascension_reaper_extinction_buff');
