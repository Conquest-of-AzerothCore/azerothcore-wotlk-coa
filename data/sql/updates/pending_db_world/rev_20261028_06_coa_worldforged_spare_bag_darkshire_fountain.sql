-- Spare Bag (#8853): a LootCollector alignment pass overwrote the Darkshire fountain placement
-- of Lohgan's Best Bag (gameobject guid 6940709, entry 95821) that the realm's own map editor
-- had set, moving it onto the Elwynn stone fence/gate instead. Restore the authored fountain-rim
-- position (confirmed with the gameplay harness's own ground probe: point_ground_gap -0.152229
-- at the authored XY, within the default 0.8 yd grounded tolerance).

UPDATE `gameobject`
SET `position_x` = -10563.261719, `position_y` = -1173.140625, `position_z` = 28.913612
WHERE `guid` = 6940709 AND `id` = 95821 AND `map` = 0
  AND `position_x` BETWEEN -10544.5 AND -10543.5 AND `position_y` BETWEEN -1191.75 AND -1190.75;
