-- Stolen Armor Shipment pickup (guid 6940886) floated 1.2 yd above the ground (#10925).
UPDATE `gameobject` SET `position_z` = 8.097
WHERE `guid` = 6940886 AND `id` = 95716 AND `map` = 0
  AND `position_x` BETWEEN -13677.91 AND -13677.89 AND `position_y` BETWEEN -268.21 AND -268.19
  AND ABS(`position_z` - 9.32) < 0.01;
