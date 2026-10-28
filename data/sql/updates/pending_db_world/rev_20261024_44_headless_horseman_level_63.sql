-- The Headless Horseman, his head and his pumpkins are level 63 like the Heroic and Mythic bosses, not 80 (#8361),
-- so level-60 players stop missing him. creature_classlevelstats has no level-63 health for expansion 2, so the
-- Horseman and his head use expansion 1, the highest with level-63 values; their modifiers are unchanged.
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63 WHERE `entry` IN (23545, 23694);
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `exp` = 1 WHERE `entry` IN (23682, 23775);
