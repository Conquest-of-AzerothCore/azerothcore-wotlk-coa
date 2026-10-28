-- Victory Rush 34428: "{AP*0.45+SP*0.45}": the spell power part (spell_hero_warrior_victory_rush)
DELETE FROM `spell_script_names` WHERE `spell_id` = 34428 AND `ScriptName` = 'spell_hero_warrior_victory_rush';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(34428, 'spell_hero_warrior_victory_rush');
