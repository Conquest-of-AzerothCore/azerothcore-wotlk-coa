-- Worldforged Voodoo Kilt (Darkspear Strand, guid 6942391) stands on the cliff top at the realm-map
-- marker; the atlas sighting puts it on the shore below, 27 yd lower, matching the LootCollector pin
-- near the beach. Restore the shore position so the pickup is reachable from the beach (#9322).
UPDATE `gameobject` SET `position_x` = -518.389, `position_y` = -5214.84, `position_z` = 9.633
WHERE `guid` = 6942391 AND `id` = 95666 AND `map` = 1
  AND `position_x` BETWEEN -518.3 AND -517.3 AND `position_y` BETWEEN -5188.2 AND -5187.2
  AND ABS(`position_z` - 36.172) < 0.01;
