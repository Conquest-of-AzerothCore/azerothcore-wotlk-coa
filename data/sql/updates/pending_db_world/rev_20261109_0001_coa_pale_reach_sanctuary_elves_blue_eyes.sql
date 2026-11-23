-- The Namarien Sanctuary elves are high elves, but eight still had green-eyed blood elf skins. Each moves to the
-- blue-eyed skin closest in tone to the one it had; nothing else about them changes.
UPDATE `creature_display_preset` SET `skin` = 23 WHERE `entry` = 164321 AND `display_id` = 15476 AND `skin` = 7; -- Remmos
UPDATE `creature_display_preset` SET `skin` = 24 WHERE `entry` IN (164282, 164289, 164294) AND `display_id` = 15476 AND `skin` = 1; -- Faelorn, Caelorn, Thalior Brightwind
UPDATE `creature_display_preset` SET `skin` = 39 WHERE `entry` = 164290 AND `display_id` = 15476 AND `skin` = 0; -- Therenis
UPDATE `creature_display_preset` SET `skin` = 39 WHERE `entry` IN (164287, 164288) AND `display_id` = 15475 AND `skin` = 0; -- Caelithra, Sylthara
UPDATE `creature_display_preset` SET `skin` = 24 WHERE `entry` = 164285 AND `display_id` = 15475 AND `skin` = 4; -- Seloria
