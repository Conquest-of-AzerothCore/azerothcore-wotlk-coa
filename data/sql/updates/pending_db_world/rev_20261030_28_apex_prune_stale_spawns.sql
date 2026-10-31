-- The look-test and first-pass spawns were re-pointed at the final entries instead of being
-- removed, so the world could hold two Torvalds, two Zul'khars and two Stormfangs.
DELETE FROM `creature` WHERE `guid` IN (9916501, 9916502, 9916503);
