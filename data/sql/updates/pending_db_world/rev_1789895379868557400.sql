--
-- Mountain Fury (#632): each hit uses 65% SP, 17% AP and the scripted 125% Stamina term.
DELETE FROM `spell_bonus_data` WHERE `entry` = 806186;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(806186, 0.65, 0, 0.17, 0, 'Primalist - Mountain Fury');

SET @ScriptName = 'spell_ascension_mountain_fury_pull';
DELETE FROM `spell_script_names` WHERE `spell_id` = 806186 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (806186, @ScriptName);
