-- Golemagg's Cave In (2105825/2105827/2105828) is the ground fire players remember, not an
-- independent 35s/55s cast: diag-golemagg-cavein.md's combat-log corpus shows it landing
-- 3.93-4.10s after every Massive Stomp (idx 2, first_ms=9000, period_ms=45100), 8/8 casts in
-- one pull, two separate logs. coa_boss_ai schedules each row on its own independent timer (no
-- "cast B after A" hook exists), so Cave In's own row is aligned to Stomp's cadence instead.
UPDATE `coa_boss_schedule` SET `first_ms` = 13000, `period_ms` = 45100,
  `comment` = 'Cave In, 4 s after Massive Stomp [corpus]'
WHERE `entry` = 11988 AND `idx` = 5;
