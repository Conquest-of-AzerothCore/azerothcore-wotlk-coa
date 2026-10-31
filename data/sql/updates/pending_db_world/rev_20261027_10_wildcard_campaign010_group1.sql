START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 209452;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(209452, 0, 0, 0, 0, 0, 331792, 1, 2, 3, 2, 6, 0, 65, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 209452 AND `ScriptName` = 'aura_wildcard_vindication';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(209452, 'aura_wildcard_vindication');
DELETE FROM `spell_bonus_data` WHERE `entry` = 270034;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(270034, 0.198865, 0, 0.198865, 0, 'Eldritch Wrath - original tooltip spell power and attack power');
DELETE FROM `spell_group` WHERE `id` = 1062 AND `spell_id` = 270036;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1062, 270036);
COMMIT;
