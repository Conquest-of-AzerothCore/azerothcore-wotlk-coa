UPDATE `manastorm_Endgame_group_scaling`
SET `global_damage_multiplier` = CASE `min_members`
  WHEN 2 THEN 1.15
  WHEN 3 THEN 1.30
  WHEN 4 THEN 1.45
  WHEN 5 THEN 1.60
END
WHERE `min_members` = `max_members` AND `min_members` IN (2, 3, 4, 5);
