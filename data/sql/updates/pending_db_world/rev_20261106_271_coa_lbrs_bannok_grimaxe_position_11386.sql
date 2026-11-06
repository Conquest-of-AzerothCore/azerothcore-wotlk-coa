-- Bannok Grimaxe (9596, spawn 45843) stood in the Firebrand camp's middle instead of the back of the encampment
-- (#11386).
-- The position is the reporter's, confirmed by the tester; its height is the ground there.
UPDATE `creature` SET `position_x` = -73.995750427246, `position_y` = -411.50689697266, `position_z` = -18.934993743896
WHERE `guid` = 45843 AND `id` = 9596 AND `map` = 229
  AND `position_x` BETWEEN -26.70 AND -26.68 AND `position_y` BETWEEN -428.57 AND -428.55
  AND `position_z` BETWEEN -18.94 AND -18.93;
