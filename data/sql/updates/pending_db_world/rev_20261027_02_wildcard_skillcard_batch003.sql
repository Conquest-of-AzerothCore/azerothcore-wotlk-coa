START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (17933, 17934, 12857, 13048, 16580, 35102, 281352, 281543, 281547, 281782, 281783, 282279, 282280, 286217, 964993);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(17933, 0, 0, 0, 0, 0, 332116, 7, 2, 0, 2, 0, 0, 30, 0, 0),
(17934, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 8, 0, 0, 100, 0, 1),
(16580, 0, 0, 0, 0, 0, 332116, 7, 2, 2, 2, 0, 0, 15, 0, 0),
(35102, 0, 0, 0, 0, 0, 332116, 7, 2, 0, 2, 0, 0, 100, 0, 0),
(281352, 0, 0, 0, 0, 0, 332116, 7, 2, 0, 2, 0, 0, 100, 0, 0),
(281543, 0, 0, 0, 0, 0, 262144, 7, 2, 0, 2, 0, 0, 100, 1000, 0),
(281782, 0, 0, 0, 0, 0, 20, 7, 2, 0, 2, 0, 0, 10, 0, 0),
(282279, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 2, 0, 0, 100, 0, 0),
(286217, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 2, 0, 0, 100, 0, 0),
(964993, 0, 0, 0, 0, 0, 2, 7, 2, 0, 3, 0, 0, 100, 10000, 0),
(281547, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 8, 0, 0, 100, 0, 1),
(281783, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 8, 0, 0, 100, 0, 1),
(282280, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 8, 0, 0, 100, 0, 1),
(12857, 0, 4, 65536, 128, 0, 1024, 4, 4, 0, 2, 0, 0, 100, 0, 0),
(13048, 0, 0, 0, 0, 0, 175784, 7, 6, 0, 2, 0, 0, 100, 5000, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` IN (12857) AND `ScriptName` = 'aura_hero_warrior_commanding_presence';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (13048) AND `ScriptName` = 'aura_hero_warrior_enrage';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (16580, 35102, 281352, 281543, 281782, 282279, 286217, 964993) AND `ScriptName` = 'aura_wildcard_skillcard_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 17933 AND `ScriptName` = 'aura_wildcard_skillcard_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 51687 AND `ScriptName` = 'spell_rog_prey_on_the_weak';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(17933, 'aura_wildcard_skillcard_proc'),
(51687, 'spell_rog_prey_on_the_weak'),
(16580, 'aura_wildcard_skillcard_proc'),
(35102, 'aura_wildcard_skillcard_proc'),
(281352, 'aura_wildcard_skillcard_proc'),
(281543, 'aura_wildcard_skillcard_proc'),
(281782, 'aura_wildcard_skillcard_proc'),
(282279, 'aura_wildcard_skillcard_proc'),
(286217, 'aura_wildcard_skillcard_proc'),
(964993, 'aura_wildcard_skillcard_proc'),
(12857, 'aura_hero_warrior_commanding_presence'),
(13048, 'aura_hero_warrior_enrage');
COMMIT;
