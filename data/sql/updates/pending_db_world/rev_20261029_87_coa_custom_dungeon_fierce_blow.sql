-- Vaults of the Inquisition (map 936) and Road to De Other Side (map 937): Fierce Blow (975011, 100 % weapon damage)
-- hits as hard as the caster's regular blow. As a spell it took DestinyWeaver's flat damage factor instead of the
-- weapon range a regular blow is mapped to, so below level 60 it hit for half a blow or less. The script only acts
-- on these two maps.
DELETE FROM `spell_script_names` WHERE `spell_id` = 975011 AND `ScriptName` = 'spell_coa_custom_dungeon_fierce_blow';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(975011, 'spell_coa_custom_dungeon_fierce_blow');
