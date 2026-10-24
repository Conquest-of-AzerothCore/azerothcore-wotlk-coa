-- Baron Geddon's Melt Through (2105756) went to a random non-tank, who died under its 80 ms Fire ticks.
-- In the Ascension logs it lands on Geddon's tank in every pull (fights 1312, 1630, 1752: the player taking
-- his Fire Strikes), whose fire resistance absorbs most of it.
UPDATE `coa_boss_schedule` SET `target` = 0 WHERE `entry` = 12056 AND `idx` = 5;
