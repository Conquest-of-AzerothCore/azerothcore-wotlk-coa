-- High Overlord Saurfang (14720) had no spawn, so Path to Ascension tutorial 57 (quest 1903521), which completes on
-- talking to him, could not be finished. The client's turn-in marker (QuestSuperTrack 9753 -> SuperTrack 1128) points
-- at the Warchief's Command Board (1579.26, -4417.08); he stands a few yards in front of it, facing the same way.
DELETE FROM `creature` WHERE `guid` = 7905318;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
VALUES (7905318, 14720, 1, 1637, 0, 1, 1, 1, 1575.5, -4415, 7.2, 3.14159, 300, 0, 0);
