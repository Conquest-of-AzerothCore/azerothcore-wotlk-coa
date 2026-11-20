-- Enchant Weapon - Strider (20044, 113278) reads "This is 35% stronger if you are wielding a single two handed
-- weapon." Its proc buff Strider (20046) has no effect for that, so the Agility never rose with a two-hander
-- (#12337). spell_ascension_enchant_strider adds the 35% while the main hand holds a two-hander and the off hand
-- is empty.
DELETE FROM `spell_script_names` WHERE `spell_id` = 20046 AND `ScriptName` = 'spell_ascension_enchant_strider';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (20046, 'spell_ascension_enchant_strider');
