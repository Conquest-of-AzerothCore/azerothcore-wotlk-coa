-- Mother's Milk (Mother Smolderweb): the DBC spells are dummies, CoADungeonBossSpells.cpp makes them work
DELETE FROM `spell_script_names` WHERE `spell_id` IN (2102215, 2102217);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2102215, 'spell_coa_mothers_milk_spray'),
(2102217, 'spell_coa_mothers_milk_debuff');
