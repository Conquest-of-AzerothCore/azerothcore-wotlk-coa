-- Custom uncommon and rare helms and shoulders (2061xxx) had no disenchant table, so they could not be disenchanted (#7709).
-- Each gets the standard table for its quality and item level, as the rest of the set already has.
UPDATE `item_template` SET `DisenchantID` = 1 WHERE `entry` IN (2061025, 2061028, 2061050, 2061051, 2061077, 2061082, 2061089, 2061099, 2061100, 2061127, 2061128, 2061167, 2061168, 2061214, 2061251, 2061607);
UPDATE `item_template` SET `DisenchantID` = 2 WHERE `entry` IN (2061081, 2061083, 2061087, 2061094, 2061097, 2061114, 2061186, 2061216, 2061225, 2061438, 2061502, 2061567);
UPDATE `item_template` SET `DisenchantID` = 3 WHERE `entry` IN (2061133, 2061134, 2061622);
UPDATE `item_template` SET `DisenchantID` = 32 WHERE `entry` IN (2061126, 2061129, 2061194, 2061195);
