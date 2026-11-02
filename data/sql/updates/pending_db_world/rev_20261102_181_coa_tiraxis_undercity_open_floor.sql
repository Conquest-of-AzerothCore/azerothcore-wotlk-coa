-- Tiraxis stood inside the wall behind Auctioneer Stockton in the Undercity Auction House (#8351): the
-- reconstructed spot (1586, 193, -56.79) has no floor under it and a wall 0.17 yd away in the server vmaps.
-- (1579, 191) is the nearest measured floor at the same height that is clear of the walls (2.2 yd), with no
-- roof over it and 3 yd from Stockton, who faces the same way.
UPDATE `creature` SET `position_x` = 1579.0, `position_y` = 191.0, `position_z` = -56.79 WHERE `guid` = 9000006 AND `id` = 900007 AND `position_x` = 1586 AND `position_y` = 193;
