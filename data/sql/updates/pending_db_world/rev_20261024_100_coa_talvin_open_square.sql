-- Talvin, Stormwind Witch Hunter trainer (#8883): his inferred Cathedral Square post stood inside the cathedral
-- district's columns. No source records his realm position; moved to an Old Town nook beside the training yard,
-- facing out to it. The guards' direction point follows him.
UPDATE `creature` SET `position_x` = -8736, `position_y` = 376, `position_z` = 101.164, `orientation` = 4.5
WHERE `guid` = 9004505 AND `id` = 650325;
UPDATE `points_of_interest` SET `PositionX` = -8736, `PositionY` = 376 WHERE `ID` = 9321005;
