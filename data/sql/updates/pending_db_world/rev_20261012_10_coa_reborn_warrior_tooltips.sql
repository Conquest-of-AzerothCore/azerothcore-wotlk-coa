-- Warcraft Reborn Warrior: Vigilance and Sudden Death do what their tooltips say.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1150720, 1129723, 1129725, 1129724) AND `ScriptName` IN
('spell_warr_vigilance', 'spell_ascension_reborn_sudden_death');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1150720, 'spell_warr_vigilance'),
(1129723, 'spell_ascension_reborn_sudden_death'),
(1129725, 'spell_ascension_reborn_sudden_death'),
(1129724, 'spell_ascension_reborn_sudden_death');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1129723, 1129725, 1129724);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
`SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1129723, 0, 0, 0, 0, 0, 0, 1, 2, 3, 0, 2, 0, 100, 0, 0),
(1129725, 0, 0, 0, 0, 0, 0, 1, 2, 3, 0, 2, 0, 100, 0, 0),
(1129724, 0, 0, 0, 0, 0, 0, 1, 2, 3, 0, 2, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (-1100078, 1150622, 1144949) AND `ScriptName` IN
('spell_ascension_reborn_heroic_strike', 'spell_ascension_reborn_bladestorm_whirlwind');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1100078, 'spell_ascension_reborn_heroic_strike'),
(1150622, 'spell_ascension_reborn_bladestorm_whirlwind'),
(1144949, 'spell_ascension_reborn_bladestorm_whirlwind');

DELETE FROM `spell_script_names` WHERE `spell_id` = 1123920 AND `ScriptName` = 'spell_ascension_reborn_spell_reflection';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1123920, 'spell_ascension_reborn_spell_reflection');
