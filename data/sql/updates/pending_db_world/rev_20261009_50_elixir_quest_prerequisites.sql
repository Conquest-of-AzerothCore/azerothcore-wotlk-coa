-- Elixir of Pain follows Suffering's final hand-in; Agony follows Pain's final hand-in.
-- https://db.ascension.gg/?quest=499 and https://db.ascension.gg/?quest=509
UPDATE `quest_template_addon` SET `PrevQuestID` = 499 WHERE `ID` = 501;
UPDATE `quest_template_addon` SET `PrevQuestID` = 502 WHERE `ID` = 509;
