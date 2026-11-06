-- Vaults of the Inquisition (map 936): the Inquisitorial Torturer's Sword Strike (256918) hits like a regular blow, as
-- Fierce Blow does. With its flat 54-71 from Spell.dbc it was never scaled on Heroic and Mythic, so a level 60 tank took
-- 17 from it on Ascension's Mythic logs next to a 479 regular blow. The script only acts on maps 936 and 937.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (975011, 256918) AND `ScriptName` IN ('spell_coa_custom_dungeon_fierce_blow', 'spell_coa_custom_dungeon_regular_blow');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(975011, 'spell_coa_custom_dungeon_regular_blow'),
(256918, 'spell_coa_custom_dungeon_regular_blow');
