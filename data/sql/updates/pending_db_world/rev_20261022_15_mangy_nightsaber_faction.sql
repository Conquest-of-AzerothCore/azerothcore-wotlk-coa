-- #8502 Mangy Nightsaber (2032) is a neutral starter mob (flags_extra 2 = CIVILIAN, base
-- faction 7). rev_20260920_02 set it to faction 14 (Monster) with the genuinely hostile
-- Shadowglen spiders, which renders a red name while CIVILIAN still suppresses aggro.
-- Restore the base neutral faction so the nameplate is yellow again.
UPDATE `creature_template` SET `faction` = 7 WHERE `entry` = 2032;
