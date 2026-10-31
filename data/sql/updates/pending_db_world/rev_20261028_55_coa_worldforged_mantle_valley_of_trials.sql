-- Worldforged Scorpionscale Mantle (#9179): the realm-map migration placed a copy of item 410068's
-- pickup (guid 6942147, template 518462) in the Valley of Trials, the same wrong-zone defect #8904
-- already removed for the other misplaced worldforged gear; this one (a level 56-57 Silithus item)
-- was outside that pass's filter. The correct Silithus copy (guid 6942146) is untouched.
DELETE FROM `gameobject`
WHERE `guid` = 6942147 AND `id` = 518462 AND `map` = 1
  AND `position_x` BETWEEN -342.1 AND -341.1 AND `position_y` BETWEEN -4345.4 AND -4344.4;
