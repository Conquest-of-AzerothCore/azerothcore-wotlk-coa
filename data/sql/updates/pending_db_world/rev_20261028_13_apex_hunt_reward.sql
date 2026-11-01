-- The hunt pays the Skin-Peeler 9000 alongside the diploma.
UPDATE `quest_template`
SET `RewardItem2` = 190191, `RewardAmount2` = 1
WHERE `ID` IN (9916201, 9916211);
