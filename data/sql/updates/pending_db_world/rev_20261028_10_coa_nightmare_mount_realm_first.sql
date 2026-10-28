-- "Realm First! Nightmare Mode: Obtained a Mount" (achievement 15334, criteria 29342, type 75
-- ACHIEVEMENT_CRITERIA_TYPE_LEARN_SKILLLINE_SPELLS) has no game-mode gate in Achievement_Criteria.dbc, so any
-- player who learns their first mount spell in any game mode completes it (#8406). The sibling Nightmare
-- achievements are gated by the achievement_coa_game_mode_nightmare AchievementCriteriaScript through an
-- achievement_criteria_data type 11 row, generated for reach-level criteria by
-- apps/coa-wildcard/level_achievement_conditions.py, but that generator only covers CRITERIA_REACH_LEVEL (type 5)
-- criteria, so criteria 29342 was never covered. Add the same gate by hand; src/server/coa's
-- LearnSkillLineSpellsCriteriaDataGate makes LEARN_SKILLLINE_SPELLS criteria honor this row.
DELETE FROM `achievement_criteria_data` WHERE `criteria_id` = 29342 AND `type` = 11;
INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`) VALUES
(29342, 11, 0, 0, 'achievement_coa_game_mode_nightmare'); -- Realm First! Nightmare Mode: Obtained a Mount
