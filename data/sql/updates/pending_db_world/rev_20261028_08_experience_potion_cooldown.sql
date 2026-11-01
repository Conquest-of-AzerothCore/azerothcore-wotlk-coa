-- Potion of Experience: the client tooltip specifies a one-second cooldown.
UPDATE `item_template`
SET `spellcooldown_1` = 1000, `spellcategorycooldown_1` = 1000
WHERE `entry` IN (818046, 135060) AND `spellid_1` = 818046;
