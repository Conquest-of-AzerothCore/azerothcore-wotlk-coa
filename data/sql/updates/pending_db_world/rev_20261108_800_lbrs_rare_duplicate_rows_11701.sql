-- Lower Blackrock Spire: Chop'gog, Razmorg and Wizz'Magg each kept two always-standing rows outside the one-per-run
-- pool (stock and rev_20261009_50), so several copies of the same rare stood at once (#11701).
DELETE FROM `creature_addon` WHERE `guid` = 43523;

DELETE FROM `creature` WHERE (`guid`, `id`, `map`) IN (
    (43519, 9218, 229),
    (43521, 9217, 229),
    (43523, 9219, 229),
    (9950259, 9219, 229),
    (9950260, 9217, 229),
    (9950265, 9218, 229));
