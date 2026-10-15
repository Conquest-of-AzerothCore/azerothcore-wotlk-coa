-- Feather of Ancients: Azeroth learns Azeroth's flight paths in one handler instead of casting both
-- charge-consuming template spells (the unlock spell 979610 has no effect of its own).
UPDATE `item_template` SET `ScriptName` = 'item_ascension_feather_of_ancients' WHERE `entry` IN (134989, 977025);
