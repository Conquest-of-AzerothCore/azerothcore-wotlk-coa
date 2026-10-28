-- Broken grave quests in the remodelled graveyards (#8240): Helcular's Revenge (553) and
-- Until Death Do Us Part (264) could not be completed because their quest graves stayed on
-- the pre-remodel graveyard ground.
--
-- Southshore: the graveyard moved to the new burial ground; the client's turn-in node for 553
-- (QuestSuperTrack 1315) is at -628.132 -485.601, z 33.577. Helcular's Grave (gameobject 1767,
-- guid 17015) was left at the stock -738.663 -621.415, the site now occupied by the rebuilt
-- barracks area. Move it onto the client's turn-in point (terrain 34.08).
--
-- The Sepulcher: the client's turn-in node for 264 (QuestSuperTrack 1237) is at 513.694
-- 1592.540, z 128.484, while Yuriv's Tombstones (24776 quest ender guid 33401, 24777
-- decoration guid 33359) stayed at the old graves at 471.82 1594.13. Move both onto that point
-- (terrain 127.09).

UPDATE `gameobject` SET `position_x` = -628.132, `position_y` = -485.601, `position_z` = 34.1, `orientation` = 0.0
WHERE `guid` = 17015 AND `id` = 1767 AND `map` = 0;

UPDATE `gameobject` SET `position_x` = 513.694, `position_y` = 1592.540, `position_z` = 127.1, `orientation` = -1.5253
WHERE `guid` = 33401 AND `id` = 24776 AND `map` = 0;

UPDATE `gameobject` SET `position_x` = 511.0, `position_y` = 1595.0, `position_z` = 127.1, `orientation` = -1.53995
WHERE `guid` = 33359 AND `id` = 24777 AND `map` = 0;

-- Keep the server map pins on the moved graves.
UPDATE `quest_poi_points` SET `X` = -628, `Y` = -486 WHERE `QuestID` = 553 AND `Idx1` = 3 AND `Idx2` = 0;
UPDATE `quest_poi_points` SET `X` = 514, `Y` = 1592 WHERE `QuestID` = 264 AND `Idx1` = 0 AND `Idx2` = 0;
