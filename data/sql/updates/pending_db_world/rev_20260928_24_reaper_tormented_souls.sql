-- Tormented Souls 500483 creates one Tormented Soul per Reaped Soul it consumes (two with Soulfused Constitution
-- 561100, and two more with 525013) as stacks of 500481; its script counts the souls before they are consumed and
-- skips the two delayed reapplications of 500481, whose refresh would reset the count.
DELETE FROM `spell_script_names` WHERE `spell_id` = 500483 AND `ScriptName` = 'spell_ascension_reaper_tormented_souls';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500483, 'spell_ascension_reaper_tormented_souls');

-- 500481 ships ProcFlags 0. Each direct attack taken (melee, ranged or spell damage, not periodic) now heals through
-- 500482 and removes one stack. Harnessed Life 705406's SPELLMOD_CHANCE_OF_SUCCESS lowers this Chance by 25.
DELETE FROM `spell_proc` WHERE `SpellId` = 500481;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (500481, 0, 0, 0, 0, 0, 139944, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 500481 AND `ScriptName` = 'aura_ascension_reaper_tormented_souls';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500481, 'aura_ascension_reaper_tormented_souls');

-- The Tormented Soul heal 500482 is 50 + 0.5 per level + 5.8% of attack power + 24% of Stamina (Ascension DB). The
-- script supplies the base and the Stamina term; this row supplies the attack power term and no spell power.
DELETE FROM `spell_bonus_data` WHERE `entry` = 500482;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(500482, 0, 0, 0.058, 0, 'Reaper - Tormented Soul heal');
