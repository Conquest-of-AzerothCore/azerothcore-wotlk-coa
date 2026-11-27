-- Drak'math the Sinister King (162715), #13537: he followed a player out of his arena (the web doors have no server
-- collision), so he could be kited away. He now resets when he or his target is more than 22 yards from his spawn
-- point. The arena walls stand 16 to 20 yards from it and the two doors 19.5 yards, so the leash ends just past them.
DELETE FROM `coa_boss_leash_point` WHERE `entry` = 162715;
DELETE FROM `coa_boss_leash` WHERE `entry` = 162715;
INSERT INTO `coa_boss_leash` (`entry`, `radius`, `target`) VALUES (162715, 22, 1);
