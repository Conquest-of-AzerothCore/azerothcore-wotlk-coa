-- Stay a While (1660075, Alenna Whisperbough 162881 in Dolanaar) is offered from MinLevel 5
-- without completing the Shadowglen Vulture Cult chain (1660071 A Dark Warning) (#10209).
UPDATE `quest_template_addon`
SET `PrevQuestID` = 0
WHERE `ID` = 1660075 AND `PrevQuestID` = 1660071;
