-- #9486: the Timbermaw feather and bead turn-ins return to the Ascension reward, QuestFactionReward index 3
-- (75 reputation), instead of the vanilla 50 override from rev_20260923_63 (maintainer decision 2026-11-23).
UPDATE `quest_template` SET `RewardFactionOverride1` = 0
WHERE `ID` IN (8466, 8467, 8469) AND `RewardFactionID1` = 576 AND `RewardFactionValue1` = 3;
