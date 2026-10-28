-- Senseless Death, Shattered Hearts (175040) had no progress text, so Aralia Dolmen's request-items window was blank.
-- Text from the realm window (VOD i5vATMYui0I, 01:26:35).
DELETE FROM `quest_request_items` WHERE `ID` = 175040;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175040, 0, 0, 'Tell me you bring good news, please...', 0);
