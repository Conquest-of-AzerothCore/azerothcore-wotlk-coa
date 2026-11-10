-- Zul'Gurub quests as in the CoA client quest cache: Zandalar Tribe reputation comes from the
-- QuestFactionReward index (+250/+350/+500) instead of the 10000/15000/20000 override, The Hero's Brand,
-- the class enchant and Savage Guard quests open at level 10 and The Heart of Hakkar at level 60.
UPDATE `quest_template` SET `RewardFactionOverride1` = 0 WHERE `RewardFactionID1` = 270 AND `RewardFactionOverride1` <> 0;
UPDATE `quest_template` SET `MinLevel` = 10 WHERE `ID` IN (8048, 8184, 8185, 8186, 8187, 8188, 8189, 8190, 8191, 8192, 9208, 9209, 9210);
UPDATE `quest_template` SET `MinLevel` = 60 WHERE `ID` = 8183;
