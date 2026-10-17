-- No duplicate quests (user): twelve older custom quests (9920010-9920022, except Dunshire's Signature Pie 9920019) are the same
-- quests as the Pale Reach ones and were offered side by side. The Pale Reach copies stay (they also carry the Road Marauder and
-- well objectives); the custom copies are no longer offered or taken by any NPC. The quest order the custom chain had moves to
-- the Pale Reach copies: Graysky Justice > Notes of a Conspiracy > To Believe In An Ideal... > The Black Rook of Graysky, and
-- Dunshire's Signature Pie > From Grain to Flour > From Plot to Plate.
DELETE FROM `creature_queststarter` WHERE `quest` IN (9920010, 9920011, 9920012, 9920013, 9920014, 9920015, 9920016, 9920017, 9920018, 9920020, 9920021, 9920022);
DELETE FROM `creature_questender` WHERE `quest` IN (9920010, 9920011, 9920012, 9920013, 9920014, 9920015, 9920016, 9920017, 9920018, 9920020, 9920021, 9920022);
DELETE FROM `gameobject_queststarter` WHERE `quest` IN (9920010, 9920011, 9920012, 9920013, 9920014, 9920015, 9920016, 9920017, 9920018, 9920020, 9920021, 9920022);
DELETE FROM `gameobject_questender` WHERE `quest` IN (9920010, 9920011, 9920012, 9920013, 9920014, 9920015, 9920016, 9920017, 9920018, 9920020, 9920021, 9920022);
DELETE FROM `quest_template_addon` WHERE `ID` IN (175003, 175004, 175005, 175006, 175029, 175030);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES
(175003, 175002),
(175004, 175003),
(175005, 175004),
(175006, 175005),
(175029, 9920019),
(175030, 175029);
