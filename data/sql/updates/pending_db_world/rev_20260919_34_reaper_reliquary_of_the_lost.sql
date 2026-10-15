-- Reaper "Reliquary of the Lost" (500631) consumed Reaped Souls and did nothing: its periodic helper chain only
-- reaches cosmetic auras, and the Soul Bolt damage spell (500627) was never cast by anything. The script now
-- launches three Soul Bolts over five seconds along a line in front of the caster.
-- The tooltip gives Soul Bolt only an attack-power term (0.4), so its spell-power coefficient is zeroed.
DELETE FROM `spell_script_names` WHERE `spell_id` = 500631;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500631, 'spell_reaper_reliquary_of_the_lost');

DELETE FROM `spell_bonus_data` WHERE `entry` = 500627;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(500627, 0, 0, 0.4, 0, 'Reaper - Soul Bolt (Reliquary of the Lost)');
