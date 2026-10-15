-- Warchief Rend Blackhand and Gyth are bosses (rank 3) in CoA's own creature query cache
-- (hertigservices/ascension-data, conquest-of-azeroth, captured 2026-09-04).
UPDATE `creature_template` SET `rank` = 3 WHERE `entry` IN (10339, 10429);
