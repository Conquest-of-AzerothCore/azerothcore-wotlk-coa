-- Issue #7722: quest 1195 'The Sacred Flame' sends its in-world arrow to Raynewood Retreat while the world map
-- marks the Ashenvale Moonwell.
--
-- WHERE EACH VALUE COMES FROM
--   what the player sees  SOURCED-CLIENT + SOURCED-CORE: the in-world arrow and minimap pin are the client's
--     SuperTrack.dbc, which the login patch stream overrides from this table (AscensionCompat.cpp:4646 builds
--     the rows, SendSuperTrackRow streams them). Quest 1195 binds its single objective to SuperTrack point 4599
--     (QuestSuperTrack.dbc row 2865, field 2), and the client places 4599 at Raynewood Retreat
--     (2377.6299, -1665.83, 142.128). The world map is the server's quest_poi rows and needs no change.
--   the correct point  SOURCED-CORE: gameobject 20806 'Ashenvale Moonwell' stands at (1870.43, -1771.57,
--     61.328) and quest_poi id 2 (ObjectiveIndex 5) marks the same moonwell at 1888 -1776. The issue's
--     coordinates (1869.9268, -1771.5237, 61.985527) are that moonwell.
--   blast radius  VERIFIED: point 4599 occupies exactly one objective slot in QuestSuperTrack.dbc (row 2865,
--     field 2, quest 1195), so the move affects no other quest. Radius, NextID and Flags keep the client's
--     own values for the point.
DELETE FROM `coa_client_super_track` WHERE `ID` = 4599;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(4599, 1, 1870.43, -1771.57, 61.328, 5.5, 0, 0);
