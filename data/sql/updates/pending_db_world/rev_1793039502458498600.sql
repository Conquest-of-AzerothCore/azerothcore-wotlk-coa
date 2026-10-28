-- Stormwind Hallow's End hanging skeleton whose harbor-entrance wall patch-WB1 removes, leaving it in mid-air.
DELETE FROM `game_event_gameobject` WHERE `eventEntry` = 12 AND `guid` = 2375;
DELETE FROM `gameobject` WHERE `guid` = 2375 AND `id` = 180410;
