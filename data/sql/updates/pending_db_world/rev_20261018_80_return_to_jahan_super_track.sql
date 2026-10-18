-- Return to Jahan (6364) put its turn-in diamond at the top of the Crossroads smithy ramp, ~20 yd from Jahan Hawkwing.
--
-- The client takes the turn-in point from QuestSuperTrack 3903 (quest 6364) -> SuperTrack 1751
-- (-346.63, -2566.44, 97.36) radius 5.5, which is where 3.3.5 stood Jahan. Our spawn (guid 15096) is at
-- (-363.5, -2576.2, 96.01), at the foot of the ramp. The core streams coa_client_super_track rows to the client at
-- login (SMSG_PATCH_SUPER_TRACK), so the node moves onto the spawn without a client patch.
-- MapID 1, Radius 5.5, NextID 0 and Flags 0 are the client's own values and are kept.
-- Only quest 6364 references node 1751, and no node chains to it.
--
-- Idempotent: an exact-key delete before the insert.

DELETE FROM `coa_client_super_track` WHERE `ID` = 1751;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(1751, 1, -363.5, -2576.2, 96.01, 5.5, 0, 0);
