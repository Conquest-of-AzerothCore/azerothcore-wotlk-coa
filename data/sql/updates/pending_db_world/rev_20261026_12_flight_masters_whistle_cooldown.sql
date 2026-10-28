-- COA-7253: the Flight Master's Whistle (item 10) could be used again right away. Its item row overrides the spell's
-- cooldown with 0 / 0; -1 lets the item use Flight Master's Whistle 158's own 30 minute cooldown from the client data.
UPDATE `item_template` SET `spellcooldown_1` = -1, `spellcategorycooldown_1` = -1 WHERE `entry` = 10;
