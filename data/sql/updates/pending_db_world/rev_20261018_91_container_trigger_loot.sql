-- Small Sack of Coins and Sack of Gems carry the container trigger 93461 without the openable flag, so
-- neither path opened their loot. The flag restores the stock open and release behaviour; the spell script
-- resends the template to clients whose cache still lacks it, so their next use opens the container.
UPDATE `item_template` SET `Flags` = `Flags` | 4 WHERE `entry` IN (11938, 11966);

DELETE FROM `spell_script_names` WHERE `spell_id` = 93461 AND `ScriptName` = 'spell_coa_container_trigger';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(93461, 'spell_coa_container_trigger');
