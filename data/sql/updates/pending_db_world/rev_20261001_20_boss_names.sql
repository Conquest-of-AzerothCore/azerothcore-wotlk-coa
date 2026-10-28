-- Boss names Ascension uses (Exiles creature names); vanilla names stayed here, e.g. the Spirestone rares in Lower
-- Blackrock Spire are Ascension bosses (Wizz'Magg, Razmorg, Chop'gog, Xot'hot). Sneed's Shredder (642) stays as it is.

UPDATE `creature_template` SET `name` = 'Captain Midwinter' WHERE `entry` IN (3872, 103872, 203872); -- was Deathsworn Captain
UPDATE `creature_template` SET `name` = 'Brightwing' WHERE `entry` IN (5912, 105912, 205912); -- was Deviate Faerie Dragon
UPDATE `creature_template` SET `name` = 'Wizz''Magg the Magus' WHERE `entry` IN (9217, 109217, 209217); -- was Spirestone Lord Magus
UPDATE `creature_template` SET `name` = 'Razmorg the Decapitator' WHERE `entry` IN (9218, 109218, 209218); -- was Spirestone Battle Lord
UPDATE `creature_template` SET `name` = 'Chop''gog the Butcher' WHERE `entry` IN (9219, 109219, 209219); -- was Spirestone Butcher
UPDATE `creature_template` SET `name` = 'Xot''hot the Burning' WHERE `entry` IN (10263, 110263, 210263); -- was Burning Felguard
