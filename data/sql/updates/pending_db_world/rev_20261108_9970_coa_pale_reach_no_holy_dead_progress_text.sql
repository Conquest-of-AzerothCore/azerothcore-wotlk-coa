-- No Holy Dead (175344): Paladin Abigail's progress text was empty; transcribed from the live realm (video RIEMlZSgbQw
-- 07:10:00).
DELETE FROM `quest_request_items` WHERE `ID` = 175344;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175344, 0, 0, 'Have you purged this place? Have you discovered the source of this evil?', 0);
