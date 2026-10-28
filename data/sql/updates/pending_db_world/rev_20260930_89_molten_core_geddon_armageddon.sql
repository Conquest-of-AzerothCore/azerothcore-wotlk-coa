-- Baron Geddon's Armageddon: the cast (2105747, "About to explode...") had no effect wired, so it ended on
-- nothing. CoA follows it with 2105748: 8,750,000 Fire damage to every enemy within 500 yards, which
-- "can't be prevented and damage inflicted can't be reduced" - the raid dies if Geddon is not dead first.
DELETE FROM `coa_boss_schedule` WHERE `entry` = 12056 AND `idx` = 7;
INSERT INTO `coa_boss_schedule` (`entry`, `idx`, `spell_d0`, `spell_d1`, `spell_d2`, `spell_d3`, `effect`, `first_ms`, `period_ms`, `hp_pct`, `target`, `comment`) VALUES
(12056, 7, 2105747, 2105747, 2105747, 2105747, 2105748, 0, 0, 4, 3, 'Armageddon [below 4%]');
