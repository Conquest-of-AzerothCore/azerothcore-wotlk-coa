-- Reborn Spirit Guard (1182045-1182047) carries its "blocked attacks deal 5% less" as a 5-point school absorb: the
-- first hit used it up and took the whole passive talent with it, its block rating from Agility included. A script
-- makes the absorb unlimited and limits it to 5% of blocked hits.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1182045, 1182046, 1182047) AND `ScriptName` = 'spell_ascension_reborn_spirit_guard';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1182045, 'spell_ascension_reborn_spirit_guard'),
(1182046, 'spell_ascension_reborn_spirit_guard'),
(1182047, 'spell_ascension_reborn_spirit_guard');
