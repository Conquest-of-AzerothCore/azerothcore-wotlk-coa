-- Three Sisters Cry (175062): Alcarian's progress text was empty; transcribed from the live realm (video HIbr82QgX6w
-- 02:12:18).
DELETE FROM `quest_request_items` WHERE `ID` = 175062;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175062, 0, 0, 'Yes?', 0);
