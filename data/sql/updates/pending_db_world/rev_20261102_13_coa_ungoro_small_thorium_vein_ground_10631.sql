-- Small Thorium Vein 12020694 (#10631, GatherMate import) floated 1.94 yd above the Un'Goro ground;
-- the ground under it is -262.483.
UPDATE `gameobject` SET `position_z` = -262.483
WHERE `guid` = 12020694 AND `id` = 324 AND `map` = 1 AND `position_z` BETWEEN -260.6 AND -260.5;
