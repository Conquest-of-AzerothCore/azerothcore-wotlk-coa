-- Prestige: Open World (80956) counts any open-world quest, so its second objective reads "World Quests
-- Completed", as in CoA's own quest cache (Dawnrise WDB capture, questcache-dawnrise-2026-09-01c.tsv).
UPDATE `quest_template` SET `ObjectiveText2` = 'World Quests Completed' WHERE `ID` = 80956;
