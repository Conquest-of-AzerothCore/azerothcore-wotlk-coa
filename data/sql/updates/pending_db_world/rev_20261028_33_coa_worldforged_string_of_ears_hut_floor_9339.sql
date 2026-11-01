-- Worldforged String of Ears (Durotar, guid 6942256) was aligned to the stock terrain by
-- rev_20261014_95_worldforged_lootcollector_alignment.sql, 2.69 yd under the Troll_Hotel_Burn01.wmo
-- floor of the hut it belongs in, matching the reporter's own follow-up ("spawn under the structure").
-- Restore it to the hut floor (#9339).
UPDATE `gameobject` SET `position_z` = 9.908
WHERE `guid` = 6942256 AND `id` = 1345142 AND `map` = 1
  AND `position_x` BETWEEN -1126.8 AND -1125.8 AND `position_y` BETWEEN -5574.7 AND -5573.7
  AND ABS(`position_z` - 7.214) < 0.01;
