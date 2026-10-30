-- Possessed Crow Eye for Blinding the Black Rook (175325) drops from every Possessed Crow killed on the quest.
UPDATE `creature_loot_template` SET `Chance` = 100 WHERE `Entry` = 164944 AND `Item` = 560339 AND `QuestRequired` = 1;
