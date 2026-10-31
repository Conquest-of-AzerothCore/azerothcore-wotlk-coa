-- Lakeshire Hallow's End pumpkins that stand inside the lion statues patch-WB1 adds.
DELETE FROM `game_event_gameobject` WHERE `eventEntry` = 12 AND `guid` IN (36410, 36840, 36841, 37264);
DELETE FROM `gameobject` WHERE `guid` = 36410 AND `id` = 180405;
DELETE FROM `gameobject` WHERE `guid` = 36840 AND `id` = 180406;
DELETE FROM `gameobject` WHERE `guid` = 36841 AND `id` = 180406;
DELETE FROM `gameobject` WHERE `guid` = 37264 AND `id` = 180407;
