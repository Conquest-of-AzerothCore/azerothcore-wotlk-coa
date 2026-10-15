-- Seventeen more Reaper talents that never fired, and four cast rows that could not fire.
--
-- Same shape as rev_20260920_17: each talent is a SPELL_AURA_PROC_TRIGGER_SPELL passive whose
-- DBC record carries ProcTypeMask 0, so SpellMgr builds the aura with no proc flags and no
-- event can reach the handler. The flags live here and the spell list lives in
-- AscensionReaperTalentProcs.h, because a proc flag can say "a melee ability landed" but not
-- which ability, and these talents carry no family mask.
--
-- The four corrections matter as much as the new rows. 69652 is DONE_MELEE_AUTO_ATTACK,
-- DONE_SPELL_MELEE_DMG_CLASS and the two DONE_SPELL_*_DMG_CLASS_NEG flags. Casting a
-- beneficial spell on yourself raises the _POS flags instead, so a cast-phase row built from
-- 69652 alone never sees Spectre Stride or Harvest Time being cast. 87060 adds both _POS
-- flags; the spell list still decides which cast counts, so the wider flags select nothing
-- extra.

-- Dealing direct damage, at the talent's own chance
DELETE FROM `spell_proc` WHERE `SpellId` = 300565;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (300565, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 15, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 300565
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(300565, 'spell_ascension_reaper_talent_proc');

-- Casting Spectral Scythe
DELETE FROM `spell_proc` WHERE `SpellId` = 504309;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (504309, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 504309
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(504309, 'spell_ascension_reaper_talent_proc');

-- Critical strikes with Dirge and Murder
DELETE FROM `spell_proc` WHERE `SpellId` = 520056;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (520056, 0, 0, 0, 0, 0, 69652, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 520056
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(520056, 'spell_ascension_reaper_talent_proc');

-- Damage dealt with Soul Strike
DELETE FROM `spell_proc` WHERE `SpellId` = 524939;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (524939, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 524939
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(524939, 'spell_ascension_reaper_talent_proc');

-- Casting Bolstered Form
DELETE FROM `spell_proc` WHERE `SpellId` = 560478;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (560478, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 560478
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560478, 'spell_ascension_reaper_talent_proc');

-- Damage dealt with Soul Strike
DELETE FROM `spell_proc` WHERE `SpellId` = 560919;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (560919, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 560919
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560919, 'spell_ascension_reaper_talent_proc');

-- Your auto attacks, at the talent's own chance
DELETE FROM `spell_proc` WHERE `SpellId` = 561127;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (561127, 0, 0, 0, 0, 0, 4, 1, 2, 0, 0, 0, 0, 8, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 561127
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(561127, 'spell_ascension_reaper_talent_proc');

-- Casting Withering Touch
DELETE FROM `spell_proc` WHERE `SpellId` = 561170;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (561170, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 561170
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(561170, 'spell_ascension_reaper_talent_proc');

-- Your auto attacks, at the talent's own chance
DELETE FROM `spell_proc` WHERE `SpellId` = 561340;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (561340, 0, 0, 0, 0, 0, 4, 1, 2, 0, 0, 0, 0, 15, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 561340
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(561340, 'spell_ascension_reaper_talent_proc');

-- Casting Wraithblade
DELETE FROM `spell_proc` WHERE `SpellId` = 680996;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (680996, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 680996
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680996, 'spell_ascension_reaper_talent_proc');

-- Casting Spectre Stride, Scythe Rush or Veilwalk
DELETE FROM `spell_proc` WHERE `SpellId` = 704357;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (704357, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704357
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704357, 'spell_ascension_reaper_talent_proc');

-- Direct critical strikes with Shadow damage
DELETE FROM `spell_proc` WHERE `SpellId` = 704558;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (704558, 32, 0, 0, 0, 0, 69652, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704558
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704558, 'spell_ascension_reaper_talent_proc');

-- Casting Sinister Litany
DELETE FROM `spell_proc` WHERE `SpellId` = 705426;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (705426, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705426
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705426, 'spell_ascension_reaper_talent_proc');

-- Casting Wraithblade
DELETE FROM `spell_proc` WHERE `SpellId` = 705437;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (705437, 0, 0, 0, 0, 0, 87060, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705437
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705437, 'spell_ascension_reaper_talent_proc');

-- Parrying an attack
DELETE FROM `spell_proc` WHERE `SpellId` = 706795;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (706795, 0, 0, 0, 0, 0, 40, 7, 2, 32, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 706795
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(706795, 'spell_ascension_reaper_talent_proc');

-- Direct damage critical strikes
DELETE FROM `spell_proc` WHERE `SpellId` = 707707;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (707707, 0, 0, 0, 0, 0, 69652, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 707707
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707707, 'spell_ascension_reaper_talent_proc');

-- Damage dealt with Reap, Dreadwake and Soul Strike
DELETE FROM `spell_proc` WHERE `SpellId` = 801325;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (801325, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 801325
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801325, 'spell_ascension_reaper_talent_proc');

-- The cast rows rev_20260920_17 wrote: widen their flags to the ones a beneficial
-- self-cast raises.
UPDATE `spell_proc` SET `ProcFlags` = 87060 WHERE `SpellId` = 560412;   -- Casting Spectre Stride
UPDATE `spell_proc` SET `ProcFlags` = 87060 WHERE `SpellId` = 704193;   -- Every 6th cast of Reap
UPDATE `spell_proc` SET `ProcFlags` = 87060 WHERE `SpellId` = 705414;   -- Slaughter casting an additional time
UPDATE `spell_proc` SET `ProcFlags` = 87060 WHERE `SpellId` = 707899;   -- Casting Harvest Time
