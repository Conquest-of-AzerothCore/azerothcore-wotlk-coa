DELETE FROM `spell_script_names`
WHERE `spell_id` = 1133757
  AND `ScriptName` = 'spell_sha_windfury_weapon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (1133757, 'spell_sha_windfury_weapon');

DELETE FROM `spell_proc` WHERE `SpellId` = 1133757;
INSERT INTO `spell_proc`
(`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
 `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`,
 `Cooldown`, `Charges`)
VALUES (1133757, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 3000, 0);
