-- patch-WB1 replaced Durnholde's prison longhouses with PRISONHQ_NEW.WMO, whose floor under Drull (2239) and his
-- Locked ball and chain (1721) is at 54.53/54.55; both still stood at the old longhouse floor, below it.
UPDATE `creature` SET `position_z` = 54.53 WHERE `guid` = 15597 AND `id` = 2239;
UPDATE `gameobject` SET `position_z` = 54.55 WHERE `guid` = 20785 AND `id` = 1721;
