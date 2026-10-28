-- DISABLE_TYPE_LFG_MAP rows are read as a difficulty mask: LFGMgr::IsDungeonDisabled asks at normal difficulty,
-- so flags 0 left both dungeons open. 7 covers the normal, heroic and mythic MapDifficulty rows of maps 936 and 937.
UPDATE `disables` SET `flags` = 7 WHERE `sourceType` = 8 AND `entry` IN (936, 937);
