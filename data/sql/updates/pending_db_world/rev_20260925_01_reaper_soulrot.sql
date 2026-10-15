DELETE FROM `spell_proc` WHERE `SpellId` = 805196;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
(805196, 0, 0, 0, 0, 0, 331796, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_bonus_data` WHERE `entry` = 805089;
INSERT INTO `spell_bonus_data`
  (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES
  (805089, 0, 0, 2, 0, 'Reaper: Soulrot dispel retaliation');

DELETE FROM `spell_script_names` WHERE `spell_id` = 804660
  AND `ScriptName` = 'aura_ascension_reaper_soulrot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(804660, 'aura_ascension_reaper_soulrot');
