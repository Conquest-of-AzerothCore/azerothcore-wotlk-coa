-- Fourteen more Reaper talents that never fired.
--
-- Each is a SPELL_AURA_PROC_TRIGGER_SPELL passive whose DBC record carries ProcTypeMask 0, so
-- SpellMgr builds the aura with no proc flags and no event can reach the handler. Of the Reaper's
-- proc talents only four ship with flags of their own, so this is the rule rather than the
-- exception; these are the ones whose trigger the tooltip states plainly enough to answer with a
-- proc flag alone.
--
-- Chance is 100 in every row. The flags can say "a melee ability landed" but not which ability,
-- and these talents carry no family mask, so spell_ascension_reaper_talent_proc checks the spell
-- against the list in AscensionReaperTalentProcs.h.

-- Dealing damage with Reliquary of the Lost
DELETE FROM `spell_proc` WHERE `SpellId` = 301193;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (301193, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 301193
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(301193, 'spell_ascension_reaper_talent_proc');

-- Avoiding attacks
DELETE FROM `spell_proc` WHERE `SpellId` = 500286;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (500286, 0, 0, 0, 0, 0, 40, 7, 2, 48, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 500286
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500286, 'spell_ascension_reaper_talent_proc');

-- Casting Spectre Stride
DELETE FROM `spell_proc` WHERE `SpellId` = 560412;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (560412, 0, 0, 0, 0, 0, 69652, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 560412
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560412, 'spell_ascension_reaper_talent_proc');

-- Your successful parries and dodges
DELETE FROM `spell_proc` WHERE `SpellId` = 560487;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (560487, 0, 0, 0, 0, 0, 40, 7, 2, 48, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 560487
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560487, 'spell_ascension_reaper_talent_proc');

-- Every 6th cast of Reap
DELETE FROM `spell_proc` WHERE `SpellId` = 704193;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (704193, 0, 0, 0, 0, 0, 69652, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704193
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704193, 'spell_ascension_reaper_talent_proc');

-- Damage dealt with Dreadwake
DELETE FROM `spell_proc` WHERE `SpellId` = 704356;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (704356, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704356
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704356, 'spell_ascension_reaper_talent_proc');

-- Critical strikes with Doomrend
DELETE FROM `spell_proc` WHERE `SpellId` = 704552;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (704552, 0, 0, 0, 0, 0, 69652, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704552
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704552, 'spell_ascension_reaper_talent_proc');

-- Requiem and Soulrend
DELETE FROM `spell_proc` WHERE `SpellId` = 705403;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (705403, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705403
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705403, 'spell_ascension_reaper_talent_proc');

-- Your Slaughter now has a chance to cast an additional time
DELETE FROM `spell_proc` WHERE `SpellId` = 705414;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (705414, 0, 0, 0, 0, 0, 69652, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705414
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705414, 'spell_ascension_reaper_talent_proc');

-- Critical strikes with Slaughter
DELETE FROM `spell_proc` WHERE `SpellId` = 705428;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (705428, 0, 0, 0, 0, 0, 69652, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705428
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705428, 'spell_ascension_reaper_talent_proc');

-- Damage dealt by Soul Strike and Murder
DELETE FROM `spell_proc` WHERE `SpellId` = 706792;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (706792, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 706792
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(706792, 'spell_ascension_reaper_talent_proc');

-- Casting Harvest Time
DELETE FROM `spell_proc` WHERE `SpellId` = 707899;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (707899, 0, 0, 0, 0, 0, 69652, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 707899
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707899, 'spell_ascension_reaper_talent_proc');

-- Striking at least 1 enemy with Soulslam
DELETE FROM `spell_proc` WHERE `SpellId` = 712484;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (712484, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 712484
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(712484, 'spell_ascension_reaper_talent_proc');

-- Damage dealt by Deathchaser
DELETE FROM `spell_proc` WHERE `SpellId` = 805196;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (805196, 0, 0, 0, 0, 0, 69652, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 805196
  AND `ScriptName` = 'spell_ascension_reaper_talent_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(805196, 'spell_ascension_reaper_talent_proc');
