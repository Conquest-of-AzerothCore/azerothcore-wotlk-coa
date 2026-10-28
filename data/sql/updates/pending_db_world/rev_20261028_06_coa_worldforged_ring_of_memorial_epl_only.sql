-- Worldforged Ring of Memorial (#8600): rev_20261016_90_worldforged_in_game_position_check moved
-- gameobject guid 6940964 from Wetlands to Stonefield Farm, Elwynn Forest, using a LootCollector
-- pin whose normalized map coordinates match the Eastern Plaguelands pin to within 0.001 (a
-- wrong-zone-rectangle conversion, the same pattern seen for other worldforged pins). The item's
-- own recorded find is Eastern Plaguelands only (exiles-db-export items.csv source_label), where
-- the second spawn (guid 6940965) already stands. Remove the Elwynn copy.

DELETE FROM `gameobject`
WHERE `guid` = 6940964 AND `id` = 90526 AND `map` = 0
    AND `position_x` BETWEEN -9941 AND -9939.5 AND `position_y` BETWEEN 313.0 AND 314.5;
