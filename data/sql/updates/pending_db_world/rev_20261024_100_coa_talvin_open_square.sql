-- Talvin, Stormwind Witch Hunter trainer (#8883): his inferred post stood inside the cathedral district's
-- columns; moved to open paving on the west side of Cathedral Square, facing the cathedral. No source records
-- his realm position. The guards' direction point follows him.
UPDATE `creature` SET `position_x` = -8630, `position_y` = 790, `position_z` = 96.786, `orientation` = 0.55
WHERE `guid` = 9004505 AND `id` = 650325;
UPDATE `points_of_interest` SET `PositionX` = -8630, `PositionY` = 790 WHERE `ID` = 9321005;
