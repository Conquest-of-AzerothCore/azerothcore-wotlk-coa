--
-- Sacred Grove (#3709): native AP-scaled instant heal and bounded persistent recovery aura.
SET @ScriptName = 'aura_ascension_sacred_grove';
DELETE FROM `spell_script_names` WHERE `spell_id` = 800180 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (800180, @ScriptName);
SET @ScriptName = 'spell_ascension_sacred_grove_recovery';
DELETE FROM `spell_script_names` WHERE `spell_id` = 800179 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (800179, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` IN (800180, 800179);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(800180, 0, 0, 1, 0, 'Sacred Grove instant heal: one hundred percent AP'),
(800179, 0, 0, 0, 0, 'Sacred Grove: three percent missing health, Mana and Rage');
