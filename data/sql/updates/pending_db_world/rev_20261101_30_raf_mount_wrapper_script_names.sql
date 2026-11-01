-- Blazing Hippogryph (74856) and X-53 Touring Rocket (75973), both Recruit a Friend mount wrappers, had no
-- spell_script_names row for spell_ascension_local_mount, so AscensionCollectibles::MountWrappers entries
-- added for them in AscensionCollectibleSpellData.h were never consulted (#10460).
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_local_mount' AND `spell_id` IN (74856, 75973);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(74856, 'spell_ascension_local_mount'),
(75973, 'spell_ascension_local_mount');
