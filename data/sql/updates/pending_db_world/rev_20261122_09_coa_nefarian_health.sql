START TRANSACTION;

-- Nefarian retains 80% HP. The six opening drakonids retain 70% HP.
UPDATE `coa_boss_flex`
SET `hp_d0` = 1246572, `hp_d1` = 1795064, `hp_d2` = 2343555, `hp_d3` = 2892047
WHERE `entry` = 11583;

UPDATE `coa_boss_flex`
SET `hp_d0` = 20522, `hp_d1` = 29551, `hp_d2` = 38581, `hp_d3` = 47611
WHERE `entry` IN (14261, 14262, 14263, 14264, 14265);

UPDATE `coa_boss_flex`
SET `hp_d0` = 42723, `hp_d1` = 61522, `hp_d2` = 80319, `hp_d3` = 99118
WHERE `entry` = 14302;

COMMIT;
