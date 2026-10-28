-- Lucifron's Impending Doom (2105201, hit 2105205) came from a DBM timer (first cast 7000 ms, every 20000 ms). The
-- archive combat logs measure it instead: in three pulls (2026-08-09, 08-16, 08-23) the hits land 22.2-22.6 s
-- apart (14 consecutive intervals, a skipped cast shows as 44.5 s), and the first hit lands at 43.3, 45.1 and
-- 49.9 s, which puts the first cast 20.9-27.5 s after the pull (three pulls, so the first-cast window is a
-- measured range rather than a distribution).

UPDATE `coa_boss_schedule`
SET `first_ms` = 20900, `first_max_ms` = 27500, `period_ms` = 22200, `period_max_ms` = 22600,
    `comment` = 'Impending Doom [logs: first 20.9-27.5 s, repeat 22.2-22.6 s]'
WHERE `entry` = 12118 AND `idx` = 4 AND `spell_d0` = 2105201;
