-- Dungeon Diving dailies pay their dungeon's Callboard Cache, which no source granted.
-- Heroic Dungeon Diving (81245) adds a Heroic Dungeon Callboard Cache (1615001) and Mythic Dungeon Diving (81246) a
-- Mythic Dungeon Callboard Cache (1615002) to its 1500 Runes of Ascension. This is a CoA choice: the live quests
-- (SUB dump 2026-10-04) paid only the runes, and no capture shows where live granted either cache.
-- Mythic Dungeon Diving joins Heroic Dungeon Diving on the Stormwind and Orgrimmar Call Boards; its text sends the
-- player to "the Callboard in any major city" and mod-hero-call-board already credits a Mythic LFG clear (80652).

UPDATE `quest_template` SET `RewardItem2` = 1615001, `RewardAmount2` = 1 WHERE `ID` = 81245;
UPDATE `quest_template` SET `RewardItem2` = 1615002, `RewardAmount2` = 1 WHERE `ID` = 81246;

DELETE FROM `gameobject_queststarter` WHERE `id` IN (402000, 402001) AND `quest` = 81246;
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES
(402000, 81246),
(402001, 81246);

DELETE FROM `gameobject_questender` WHERE `id` IN (402000, 402001) AND `quest` = 81246;
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES
(402000, 81246),
(402001, 81246);
