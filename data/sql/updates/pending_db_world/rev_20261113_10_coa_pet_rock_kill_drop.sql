-- Hardcore - Oh, the Places You'll Go (611, Prestige 612) requires looting Pet Rock 20030 before level 60. Its only
-- source is pickpocketing Timbermaw Shaman 6188 (2.766%), as on Ascension (Exiles DB mirror of db.exil.es), so only
-- classes with a pickpocket spell (Rogue, Ranger, Reaper) could complete the trial. By the contributor's decision
-- the Shaman's kill loot drops it at the same 2.766%, so every class can loot it; the pickpocket source stays.
DELETE FROM `creature_loot_template` WHERE `Entry` = 6188 AND `Item` = 20030;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(6188, 20030, 0, 2.766, 0, 1, 0, 1, 1, 'Timbermaw Shaman - Pet Rock');
