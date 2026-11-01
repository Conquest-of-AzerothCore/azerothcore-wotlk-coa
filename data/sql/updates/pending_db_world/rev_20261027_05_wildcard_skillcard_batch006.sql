START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (277588, 280040);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(277588, 8, 0, 0, 0, 0, 332116, 1, 2, 3, 2, 6, 0, 100, 0, 0),
(280040, 0, 0, 0, 0, 0, 332116, 1, 2, 3, 2, 6, 0, 5, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 277588 AND `ScriptName` = 'aura_wildcard_skillcard_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(277588, 'aura_wildcard_skillcard_proc');
DELETE FROM `spell_bonus_data` WHERE `entry` IN (275981, 280041);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(275981, 0, 0, 0, 0, 'Masters Meatshield - forwarded Drain Life healing'),
(280041, 0.1, 0, 0.1, 0, 'Envenomed Weapons - 10 percent SP and AP');
COMMIT;
