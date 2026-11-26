-- #13564: Restore Tightly Sealed Lockbox (guid 6942442, entry 96108, drops Worn Angler Cord 515158)
-- to its first-pass realm-dump position on the Wildwind Lake lakebed (row 6901352) instead of the
-- 82-degree waterfall cliff face where the realm-map pass placed it.
UPDATE `gameobject`
SET `position_x` = -4490.840, `position_y` = 180.309, `position_z` = -35.059
WHERE `guid` = 6942442 AND `id` = 96108;
