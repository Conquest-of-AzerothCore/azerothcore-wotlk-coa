-- Warcraft Reborn taught abilities whose attack power part lived only in the tooltip: Dragon Roar ("765+AP*0.7") and
-- Dispatch ("AP*0.056 to AP*0.07 per combo point", spell_ascension_reborn_dispatch).
DELETE FROM `spell_bonus_data` WHERE `entry` = 1569444;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1569444, 0, 0, 0.7, 0, 'Warcraft Reborn Warrior - Dragon Roar');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2304553, 2304555, 2304556, 2304557, 2304558, 2304559, 2304560, 2304561) AND `ScriptName` = 'spell_ascension_reborn_dispatch';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2304553, 'spell_ascension_reborn_dispatch'),
(2304555, 'spell_ascension_reborn_dispatch'),
(2304556, 'spell_ascension_reborn_dispatch'),
(2304557, 'spell_ascension_reborn_dispatch'),
(2304558, 'spell_ascension_reborn_dispatch'),
(2304559, 'spell_ascension_reborn_dispatch'),
(2304560, 'spell_ascension_reborn_dispatch'),
(2304561, 'spell_ascension_reborn_dispatch');
