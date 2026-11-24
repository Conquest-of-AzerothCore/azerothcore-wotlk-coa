-- Worldforged Bloodsail Decksweeper (pickup 6940150, Stranglethorn Vale, #11718) floated 0.8 yd over the beach: the
-- realm-map pass moved it 2.2 yd off the rowboat and kept the boat height. New z: the server's ground height there.
UPDATE `gameobject` SET `position_z` = 0.102
WHERE `guid` = 6940150 AND `id` = 95713 AND `map` = 0
  AND `position_x` BETWEEN -14862.61 AND -14862.59
  AND `position_y` BETWEEN 70.59 AND 70.61
  AND `position_z` BETWEEN 0.89 AND 0.90;
