-- #10063: "Offering of Wood" (quest 175177) is handed in at the Spirit of Unity (creature 164462, spawn
-- 9962204), and the follow-up "Candle of Unity" (175178) is taken there. The spawn stood on top of the
-- Brazier of Unity at z 842.247, about 6.5 yards above the floor a player can stand on, so the client
-- refused the interaction ("requires you to be closer") however close the player got and neither quest
-- could be completed. Put the spirit on the reachable floor in front of the brazier, at the position the
-- report was filed from.
UPDATE `creature` SET `position_x` = -6430.33, `position_y` = -140.564, `position_z` = 835.798 WHERE `guid` = 9962204;
