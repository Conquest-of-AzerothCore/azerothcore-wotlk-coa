-- Retain dungeon quest XP levels and existing chains, keys, objectives and disabled quests.
UPDATE `quest_template` SET `MinLevel` = 60
WHERE `MinLevel` BETWEEN 61 AND 254 AND `ID` IN (10091, 10095, 10097, 10098, 10164, 10165, 10167, 10168, 10216, 10218, 10257, 10283, 10649, 10665, 10666, 10704, 10882, 10977, 10981, 11001, 11372, 11373, 11374, 11375, 11376, 11378, 11382, 11383, 11384, 11385, 11386, 11387, 11388, 11389, 11488, 11490, 11492, 11499, 11500, 12513, 12515);

UPDATE `quest_template_addon` SET `MaxLevel` = 60
WHERE `MaxLevel` BETWEEN 1 AND 59 AND `ID` IN (10091, 10095, 10097, 10098, 10164, 10165, 10167, 10168, 10216, 10218, 10257, 10283, 10649, 10665, 10666, 10704, 10882, 10977, 10981, 11001, 11372, 11373, 11374, 11375, 11376, 11378, 11382, 11383, 11384, 11385, 11386, 11387, 11388, 11389, 11488, 11490, 11492, 11499, 11500, 12513, 12515);

UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201697 WHERE `ID` = 10091 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201696 WHERE `ID` = 10091 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201695 WHERE `ID` = 10091 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201694 WHERE `ID` = 10091 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201701 WHERE `ID` = 10095 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201700 WHERE `ID` = 10095 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201699 WHERE `ID` = 10095 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201698 WHERE `ID` = 10095 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201857 WHERE `ID` = 10097 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201858 WHERE `ID` = 10097 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201859 WHERE `ID` = 10097 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201860 WHERE `ID` = 10097 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201855 WHERE `ID` = 10098 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201856 WHERE `ID` = 10098 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201854 WHERE `ID` = 10098 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201864 WHERE `ID` = 10164 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201863 WHERE `ID` = 10164 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201862 WHERE `ID` = 10164 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201861 WHERE `ID` = 10164 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201866 WHERE `ID` = 10165 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201865 WHERE `ID` = 10165 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201868 WHERE `ID` = 10165 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201867 WHERE `ID` = 10165 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201853 WHERE `ID` = 10218 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201852 WHERE `ID` = 10218 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201851 WHERE `ID` = 10218 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201850 WHERE `ID` = 10218 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201960 WHERE `ID` = 10704 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201957 WHERE `ID` = 10704 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201959 WHERE `ID` = 10704 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID4` = 10201958 WHERE `ID` = 10704 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID5` = 10201956 WHERE `ID` = 10704 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID1` = 10201961 WHERE `ID` = 10882 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID2` = 10201963 WHERE `ID` = 10882 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardChoiceItemID3` = 10201962 WHERE `ID` = 10882 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardItem1` = 10211969 WHERE `ID` = 11001 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardItem1` = 10202025 WHERE `ID` = 12513 AND `MinLevel` <> 255;
UPDATE `quest_template` SET `RewardItem1` = 10202025 WHERE `ID` = 12515 AND `MinLevel` <> 255;
