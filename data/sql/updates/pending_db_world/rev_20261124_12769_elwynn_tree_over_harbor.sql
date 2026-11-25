-- #12769: Elwynn Tree 8000010 (rev_20260928_82) floated 34.94 yd above a Stormwind Harbor cliff, outside
-- Elwynn Forest. Remove it, as rev_20260930_92 removed other trees placed outside their zone.
DELETE FROM `gameobject`
WHERE `guid` = 8000010 AND `id` = 244614 AND `map` = 0 AND `position_x` BETWEEN -8712.3 AND -8712.2;
DELETE FROM `gameobject_addon` WHERE `guid` = 8000010;
