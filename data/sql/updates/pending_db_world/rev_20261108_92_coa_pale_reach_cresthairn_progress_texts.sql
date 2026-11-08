-- Ursine Rampage (175034), Change of Heart (175323) and A Tooth for a Song (175324) progress text,
-- from live footage of Jornan Thalor's and Aisling's turn-in windows.
DELETE FROM `quest_request_items` WHERE `ID` IN (175034, 175323, 175324);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175034, 0, 0, 'Do you have the pelts?', 0),
(175323, 0, 0, 'Have you brought the heart? If there is one thing Scadeald has in abundance, besides the damned crows, it is foxes.', 0),
(175324, 0, 0, 'How goes it out there? Do you have everything?', 0);
