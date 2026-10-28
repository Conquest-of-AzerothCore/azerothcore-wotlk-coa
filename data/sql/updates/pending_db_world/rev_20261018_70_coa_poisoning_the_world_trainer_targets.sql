-- Poisoning the World (200025 Shadowglen, 200026 Valley of Trials): the client sends the Mysterious Concoction
-- (662217, spell 685013) at the player instead of the selected trainer while the trainer has UNIT_FLAG_IMMUNE_TO_PC,
-- so the On Spellhit credit never fires. Clear only that flag on the six trainers the quest targets.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` & ~256 WHERE `entry` IN (50294, 503250, 9300350, 502925, 9300200, 9300201);
