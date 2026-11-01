-- Investigate the Camp (201): area trigger 98 "Locate the hunters' camp" credits through areatrigger_involvedrelation.
-- The client's AreaTrigger.dbc centres the 30 yard sphere at (-11619.7, -54.924, 11.17), but the world row sat
-- 15 yards away at (-11634.8, -54.0697, 13.4439), so a player approaching from the north or east entered the
-- client's sphere more than 30 yards from the server's centre: the packet was rejected and never resent (#10544).
UPDATE `areatrigger` SET `x` = -11619.7, `y` = -54.924, `z` = 11.17 WHERE `entry` = 98;
