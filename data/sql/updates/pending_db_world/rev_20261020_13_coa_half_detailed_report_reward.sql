-- The Half-Detailed Report (#7685): the quest target marker pointed at the Slain Protector
-- but the report itself was never obtainable, so there was nothing to find on the body.
--
-- 999913 "The Missing Report" is handed in to the Slain Protector 455339; its follow-up
-- 999914 "The Half-Detailed Report" is started and completed with item 999920, and the quest
-- text says the report is found on the body. No loot table, quest reward or provided item ever
-- granted 999920, so 999914 could never be accepted or completed. Reward the report on the
-- turn-in that finds it.
--
-- 999914 was also listed as a quest started by the Slain Protector, and the core treats any
-- involved quest giver as a valid completion target, so the report could be handed in on the
-- corpse instead of Archivist Selnor. Start the follow-up from the report item and leave Selnor
-- as its only ender, matching the quest text.

UPDATE `quest_template` SET `RewardItem1` = 999920, `RewardAmount1` = 1 WHERE `ID` = 999913;
UPDATE `item_template` SET `startquest` = 0 WHERE `entry` = 999920;
DELETE FROM `creature_queststarter` WHERE `id` = 455339 AND `quest` = 999914;
