-- The Crossroads (#10879): #7212 moved Thork (creature guid 14344) onto his QuestSuperTrack point, 0.6 yd from the
-- stock Weapon Crate (gameobject guid 13310). The crate takes Thork's former spot on the same tower floor.
UPDATE `gameobject` SET `position_x` = -473.202, `position_y` = -2595.7, `position_z` = 103.806
WHERE `guid` = 13310 AND `id` = 3661;
