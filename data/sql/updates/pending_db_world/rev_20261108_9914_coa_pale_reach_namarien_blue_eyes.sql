-- Namarien Sanctuary is a high elf refuge, so its elves have the blue high elf eyes. Rhandor (164299) had a green-eyed
-- blood elf skin (2); skin 23 is the same light tone with blue eyes.
UPDATE `creature_display_preset` SET `skin` = 23 WHERE `entry` = 164299 AND `display_id` = 15476;
