-- Quest 33 "Wolves Across the Border" is the exact shape wanted: item objective only,
-- POI on the item index, drops gated by the quest. Its quest flags are 524296
-- (SHARABLE | AUTO_ACCEPT); ours were 0. Match it.
UPDATE `quest_template`
SET `Flags` = 524296
WHERE `ID` IN (17839, 17844);
