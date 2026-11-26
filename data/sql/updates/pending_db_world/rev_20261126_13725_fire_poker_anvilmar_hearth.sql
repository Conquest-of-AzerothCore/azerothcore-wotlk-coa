-- #13725: Restore Fire Poker (guid 6940474, entry 95605, drops Fire Poker 450671)
-- inside Anvilmar.wmo in Dun Morogh to its first-pass realm-dump coordinates (row 6901058,
-- on the raised fireplace hearth at 396.098) instead of the realm-map pass spot 1.42 yd
-- out over the main hall floor (395.542) where it hovered 1.57 yd in midair.
UPDATE `gameobject`
SET `position_x` = -6092.410,
    `position_y` = 380.289,
    `position_z` = 397.112,
    `orientation` = 2.002220,
    `rotation2` = 0.842070,
    `rotation3` = 0.539368
WHERE `guid` = 6940474 AND `id` = 95605;
