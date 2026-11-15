-- Difficulty 1: halve health across the supplied regular depth curve.
-- Runs after zz_manastorm_tuning_curve.sql. Match original tuning for safe replay.
UPDATE `manastorm_scaling_curve`
SET `health_multiplier` = `health_multiplier` * 0.5
WHERE `depth` BETWEEN 1 AND 2000
AND ABS(`health_multiplier` - CASE
    WHEN `depth` <= 10 THEN 0.6 + (`depth` - 1) / 90.0
    WHEN `depth` <= 25 THEN 0.7 + (`depth` - 10) / 100.0
    WHEN `depth` <= 50 THEN 0.85 + (`depth` - 25) * 0.006
    WHEN `depth` <= 200 THEN 1.0 + (`depth` - 50) * 0.005
    WHEN `depth` <= 500 THEN 1.75 + (`depth` - 200) / 240.0
    ELSE 3.0 + (`depth` - 500) * 0.004
END) < 0.00001;
