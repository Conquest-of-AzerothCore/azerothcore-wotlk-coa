-- Lower Blackrock Spire: the Mythic-only copies of Chop'gog, Wizz'Magg, Razmorg and Xot'hot (rev_20261007_97) stayed
-- next to the all-difficulty rows that rev_20261009_50 placed at the same spots, so Mythic loaded each rare twice
-- (#11387).
DELETE FROM `creature` WHERE `map` = 229 AND `spawnMask` = 4
    AND ((`guid` = 9970181 AND `id` = 9219) OR (`guid` = 9970182 AND `id` = 9217)
        OR (`guid` = 9970187 AND `id` = 9218) OR (`guid` = 9970189 AND `id` = 10263));
