-- Aetherial Reliquary (8263512): Aetherial Displacement restores the experience boosts stored at the realm
-- level cap (#4755). The item is consumed by its successful use; refused uses keep it.
DELETE FROM `spell_script_names` WHERE `spell_id` = 8263512 AND `ScriptName` = 'AetherialReliquary::Displacement';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (8263512, 'AetherialReliquary::Displacement');

UPDATE `item_template` SET `spellcharges_1` = -1 WHERE `entry` = 8263512;
