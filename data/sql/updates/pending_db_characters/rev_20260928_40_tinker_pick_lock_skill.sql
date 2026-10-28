-- Characters who learned Pick Lock (804154) before its SkillLine fix never received Lockpicking (633).
-- UpdateSkillsForLevel raises the max to the character's level on the next login.
DELETE FROM `character_skills` WHERE `skill` = 633 AND `value` = 1 AND `max` = 5
  AND `guid` IN (SELECT `guid` FROM `character_spell` WHERE `spell` = 804154);
INSERT INTO `character_skills` (`guid`, `skill`, `value`, `max`)
SELECT `cs`.`guid`, 633, 1, 5 FROM `character_spell` `cs`
WHERE `cs`.`spell` = 804154
  AND NOT EXISTS (SELECT 1 FROM `character_skills` `sk` WHERE `sk`.`guid` = `cs`.`guid` AND `sk`.`skill` = 633);
