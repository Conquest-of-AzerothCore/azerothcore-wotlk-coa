-- Lower Blackrock Spire: only one of Chop'gog the Butcher, Razmorg the Decapitator and Wizz'Magg the Magus appears in a
-- run, on every difficulty, and it does not respawn within the run (#11383).
UPDATE `creature` SET `spawnMask` = 7, `spawntimesecs` = 1000000 WHERE `guid` IN (9970181, 9970182, 9970187) AND `id` IN (9217, 9218, 9219);

DELETE FROM `pool_template` WHERE `entry` = 9229001;
INSERT INTO `pool_template` (`entry`, `max_limit`, `description`) VALUES
(9229001, 1, 'Lower Blackrock Spire - Chop''gog, Razmorg or Wizz''Magg');

DELETE FROM `pool_creature` WHERE `guid` IN (9970181, 9970182, 9970187);
INSERT INTO `pool_creature` (`guid`, `pool_entry`, `chance`, `description`) VALUES
(9970181, 9229001, 0, 'Lower Blackrock Spire - Chop''gog the Butcher'),
(9970182, 9229001, 0, 'Lower Blackrock Spire - Wizz''Magg the Magus'),
(9970187, 9229001, 0, 'Lower Blackrock Spire - Razmorg the Decapitator');
