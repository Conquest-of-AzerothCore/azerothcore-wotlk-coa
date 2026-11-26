-- Loch Modan Worldforged pickups left underground by the 2026_09_23_05 realm-map pass (#10219).
-- Restore realm dump coordinates (2026_09_16 / 2026_09_22) for five spawns and LootCollector
-- alignment for Special Brewing Gear (6941158), which rev_20261014_95 had targeted at 6941159.
UPDATE `gameobject`
SET `position_x` = -5017.87, `position_y` = -3586.46, `position_z` = 295.326,
    `orientation` = 2.24259, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.900664, `rotation3` = 0.434516
WHERE `guid` = 6940384 AND `id` = 97118 AND `map` = 0;

UPDATE `gameobject`
SET `position_x` = -5541.41, `position_y` = -2718.69, `position_z` = 367.091,
    `orientation` = 2.70226, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.97597, `rotation3` = 0.217906
WHERE `guid` = 6940402 AND `id` = 97121 AND `map` = 0;

UPDATE `gameobject`
SET `position_x` = -5288.869, `position_y` = -2691.869, `position_z` = 345.7341,
    `orientation` = 3.404475, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.991374, `rotation3` = -0.131063
WHERE `guid` = 6940507 AND `id` = 95533 AND `map` = 0;

UPDATE `gameobject`
SET `position_x` = -5268.45, `position_y` = -4132.88, `position_z` = 335.382
WHERE `guid` = 6941158 AND `id` = 518319 AND `map` = 0;

UPDATE `gameobject`
SET `position_x` = -5375.25, `position_y` = -3727.24, `position_z` = 299.837,
    `orientation` = 0.72865, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.35632, `rotation3` = 0.934364
WHERE `guid` = 6941035 AND `id` = 95531 AND `map` = 0;

UPDATE `gameobject`
SET `position_x` = -5478.07, `position_y` = -3488.3, `position_z` = 298.3,
    `orientation` = 4.59717, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.746646, `rotation3` = -0.665221
WHERE `guid` = 6940726 AND `id` = 95532 AND `map` = 0;
