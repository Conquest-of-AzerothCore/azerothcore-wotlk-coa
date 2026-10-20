-- patch-WB1 replaced Durnholde's prison longhouses with PRISONHQ_NEW.WMO, whose floor under Drull (2239) and his
-- Locked ball and chain (1721) is at 54.53/54.55; both still stood at the old longhouse floor, below it.
-- It also replaced the barracks with WESTFALL_BARRACKS.WMO, which left Jailor Marlgen (2428) in a wall corner.
-- Drull and Marlgen take the positions set in-game with .npc move; both z values match the WB1 floor.
UPDATE `creature` SET `position_x` = -486.324, `position_y` = -1344.73, `position_z` = 54.5268, `orientation` = 0.375935
    WHERE `guid` = 15597 AND `id` = 2239;
UPDATE `creature` SET `position_x` = -461.582, `position_y` = -1477.03, `position_z` = 88.7214, `orientation` = 1.08279
    WHERE `guid` = 16063 AND `id` = 2428;
UPDATE `gameobject` SET `position_z` = 54.55 WHERE `guid` = 20785 AND `id` = 1721;
