-- CoA Pale Reach: 175019 'A Sword for the North' had no progress text, so Guard Dornhelm (164017) opened an empty
-- window while the quest was incomplete. No capture of the original line exists (the quest cache does not store
-- it); this text is newly written to match the quest's description and reward text.
DELETE FROM `quest_request_items` WHERE `ID` = 175019;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`)
VALUES (175019, 0, 0, 'Back already? I see no blood on that blade. The bandits are still holed up in Deepstone Cave, and every hour they stay there is another merchant who won''t reach the city.', 0);
