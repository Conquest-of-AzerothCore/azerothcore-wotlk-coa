-- Path of Duality (129243): its 15 s periodic dummy keeps the higher stat's attack power helper
-- (820056 Strength -> AP or 820057 Agility -> AP) active, as the tooltip's "Strength or Agility, whichever is higher".
DELETE FROM `spell_script_names` WHERE `spell_id` = 129243 AND `ScriptName` = 'aura_wildcard_path_of_duality';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (129243, 'aura_wildcard_path_of_duality');
