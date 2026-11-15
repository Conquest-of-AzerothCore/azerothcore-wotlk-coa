-- The 44 Call Board dailies also pay Bazaar Tokens (975001): twice the quest's Callboard Cache points
-- (`ascension_callboard_quest_points`), so 25 points pay 50 tokens, 20 points 40 and 15 points 30.
-- This is a CoA choice: no live quest paid Bazaar Tokens (SUB dump 2026-10-04). High-Risk quests are not included.
-- Heroic and Mythic Dungeon Diving keep their Callboard Cache in the second slot and take the tokens in the third.

UPDATE `quest_template` SET `RewardItem2` = 975001, `RewardAmount2` = 50
WHERE `ID` IN (18034, 18036, 18104, 18109);

UPDATE `quest_template` SET `RewardItem2` = 975001, `RewardAmount2` = 40
WHERE `ID` IN (17838, 17926, 18017, 18018, 18019, 18030, 18044, 18045, 18046, 18054, 18055, 18056, 18089, 18090,
    18091, 18105, 18106, 18110, 18111, 80651, 81260);

UPDATE `quest_template` SET `RewardItem2` = 975001, `RewardAmount2` = 30
WHERE `ID` IN (26035, 26053, 81244, 1005092, 1005124, 1005170, 1005259, 1005301, 1005468, 1005474, 1005647, 1005660,
    1005664, 1007453, 1007496, 1038797, 1038884);

UPDATE `quest_template` SET `RewardItem3` = 975001, `RewardAmount3` = 30
WHERE `ID` IN (81245, 81246);
