-- Bone Reliquary 11521 and Frozen Reliquary 555555 join the shared potion cooldown category 5004 (owner ruling Q-mb-1).
UPDATE `item_template` SET `spellcategory_1` = 5004 WHERE `entry` IN (11521, 555555) AND `spellcategory_1` = 1153;
