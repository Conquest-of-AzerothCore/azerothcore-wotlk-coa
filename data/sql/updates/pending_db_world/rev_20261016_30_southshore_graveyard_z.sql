-- CoA rebuilt Southshore: the stock Alliance graveyard (game_graveyard 149, -732.799 -592.502 z 22.663) now lies at
-- the gate of a new Westfall barracks, 1.09 yd under the terrain, so released ghosts spawned under the map and fell in
-- a loop (#7848). Move the graveyard and its Spirit Healer to the new Southshore burial ground, on open ground by the
-- tombstone monument, with the ghost appearing in front of the healer.
UPDATE `game_graveyard` SET `x` = -639.143, `y` = -510.149, `z` = 33.06 WHERE `ID` = 149;
UPDATE `creature` SET `position_x` = -637.086, `position_y` = -507.965, `position_z` = 33.17, `orientation` = 3.9568 WHERE `guid` = 40538 AND `id` = 6491;
