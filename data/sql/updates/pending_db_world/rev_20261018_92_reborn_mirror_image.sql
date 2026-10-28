-- Reborn Mirror Image (1155342) lacked the stock aura script: spell_mage_mirror_image casts Initialize Images
-- (the aura's effect 2 trigger, Reborn 1158836) when the aura lands, which hands the images the mage's targets.
-- Without it the images spawned idle. The script reads the trigger from the spell, so the twin binds as is.
DELETE FROM `spell_script_names` WHERE `spell_id` = 1155342 AND `ScriptName` = 'spell_mage_mirror_image';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (1155342, 'spell_mage_mirror_image');
