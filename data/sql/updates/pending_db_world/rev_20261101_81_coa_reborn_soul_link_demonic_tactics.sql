-- Reborn Improved Demonic Tactics' effect 1: while the demon is below 20% health, the damage Soul Link (1125228) splits
-- to it is the rank's share lower.
DELETE FROM `spell_script_names` WHERE `spell_id` = 1125228 AND `ScriptName` = 'spell_ascension_reborn_soul_link';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1125228, 'spell_ascension_reborn_soul_link');
