-- Cyclok's Sanity's Damp Ring (guid 6941603) lay in the sand of Dunemaul Compound: the realm-map pass placed it
-- on the rounded map marker (-8359, -3047), while the client's own sighting of this pickup, with the same
-- orientation, is at the bottom of the pond south-west of it (#10738). The recorded-heights pass only reapplies
-- sightings within 12 yd of the marker, and this one is 20 yd away. Put the ring back at the sighting.
UPDATE `gameobject` SET `position_x` = -8375.14, `position_y` = -3059.4, `position_z` = 2.853
WHERE `guid` = 6941603 AND `id` = 515771 AND `map` = 1;
