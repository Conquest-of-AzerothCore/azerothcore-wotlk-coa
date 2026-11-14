-- Lower Blackrock Spire: Chop'gog the Butcher, Razmorg the Decapitator and Wizz'Magg the Magus each spawn once per run.
-- The spawn pool from rev_20261106_13 let only one of them appear. Their spawntimesecs of 1000000 stays, so none of
-- them comes back within a run.
DELETE FROM `pool_creature` WHERE `guid` IN (9970181, 9970182, 9970187) AND `pool_entry` = 9229001;
DELETE FROM `pool_template` WHERE `entry` = 9229001;
