-- Warcraft Reborn Rogue: Savage Combat, Crimson Tempest, Poison Nova and Saber Slash do what their tooltips say.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1151682, 1158413);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
`SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1151682, 0, 8, 0, 524288, 0, 0, 5, 2, 0, 2, 0, 0, 0, 0, 0),
(1158413, 0, 8, 0, 524288, 0, 0, 5, 2, 0, 2, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2304883, 2304884, 2304885, 2304886, 2304887, 2304888, 2304889)
AND `ScriptName` IN ('spell_ascension_reborn_crimson_tempest', 'spell_ascension_reborn_crimson_tempest_bleed');
DELETE FROM `spell_script_names` WHERE `spell_id` IN (983281, 983283, 983284, 983285, 983286, 983287, 983288, 983289, 983290, 983291)
AND `ScriptName` = 'spell_ascension_reborn_poison_nova';
DELETE FROM `spell_script_names` WHERE `spell_id` = 1587522 AND `ScriptName` = 'spell_ascension_reborn_saber_slash';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2304883, 'spell_ascension_reborn_crimson_tempest'),
(2304884, 'spell_ascension_reborn_crimson_tempest'),
(2304885, 'spell_ascension_reborn_crimson_tempest'),
(2304886, 'spell_ascension_reborn_crimson_tempest'),
(2304887, 'spell_ascension_reborn_crimson_tempest'),
(2304888, 'spell_ascension_reborn_crimson_tempest'),
(2304889, 'spell_ascension_reborn_crimson_tempest'),
(2304883, 'spell_ascension_reborn_crimson_tempest_bleed'),
(2304884, 'spell_ascension_reborn_crimson_tempest_bleed'),
(2304885, 'spell_ascension_reborn_crimson_tempest_bleed'),
(2304886, 'spell_ascension_reborn_crimson_tempest_bleed'),
(2304887, 'spell_ascension_reborn_crimson_tempest_bleed'),
(2304888, 'spell_ascension_reborn_crimson_tempest_bleed'),
(2304889, 'spell_ascension_reborn_crimson_tempest_bleed'),
(983281, 'spell_ascension_reborn_poison_nova'),
(983283, 'spell_ascension_reborn_poison_nova'),
(983284, 'spell_ascension_reborn_poison_nova'),
(983285, 'spell_ascension_reborn_poison_nova'),
(983286, 'spell_ascension_reborn_poison_nova'),
(983287, 'spell_ascension_reborn_poison_nova'),
(983288, 'spell_ascension_reborn_poison_nova'),
(983289, 'spell_ascension_reborn_poison_nova'),
(983290, 'spell_ascension_reborn_poison_nova'),
(983291, 'spell_ascension_reborn_poison_nova'),
(1587522, 'spell_ascension_reborn_saber_slash');

DELETE FROM `spell_bonus_data` WHERE `entry` IN (983281, 983283, 983284, 983285, 983286, 983287, 983288, 983289, 983290, 983291);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(983281, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983283, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983284, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983285, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983286, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983287, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983288, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983289, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983290, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)'),
(983291, 0, 0, 0, 0, 'Warcraft Reborn Rogue - Poison Nova (combo point scaling is scripted)');
