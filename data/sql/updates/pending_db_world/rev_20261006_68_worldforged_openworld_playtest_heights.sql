-- ----------------------------------------------------------------------------
-- Worldforged pickups: raise playtest soft-burial and bridge heights (#4984)
-- ----------------------------------------------------------------------------
-- In-game playtest of 2026_10_06_65..67 showed the ADT height under-reads the walkable surface by
-- 3-5 yd at some pins: bridges/WMOs (the mass float pass in _65 wrongly lowered a pin that was
-- already right) and open-air spots the burial exclusion had left sunk. This file raises them.
-- Z only; XY, orientation and entry are untouched, and _65 / _66 / _67 are left as shipped.
--
-- Section 1: six pins whose Z was measured in game.
-- Section 2: floats snapped down by _65 whose pre-_65 Z agrees with 3+ stock creatures standing
--   within 25 yd at the same height above the ADT (a bridge/building floor); restored to pre-_65 Z.
-- Section 3: open-air soft burials (2.9-6.5 yd below the ADT, not authored, 2+ stock creatures
--   within 40 yd standing on the ADT, flat 3 yd ring); raised to the map height.
-- Ambiguous rows are not changed here.
START TRANSACTION;

-- 1. Playtest-measured raises (6)
UPDATE `gameobject` SET `position_z` = 121.053 WHERE `guid` = 6941652;
UPDATE `gameobject` SET `position_z` = 18.603 WHERE `guid` = 6941950;
UPDATE `gameobject` SET `position_z` = 68.898 WHERE `guid` = 6942218;
UPDATE `gameobject` SET `position_z` = 17.156 WHERE `guid` = 6942271;
UPDATE `gameobject` SET `position_z` = 402.766 WHERE `guid` = 6940960;
UPDATE `gameobject` SET `position_z` = 1332.25 WHERE `guid` = 6942141;

-- 2. Bridge/building floats restored to pre-65 Z (3)
UPDATE `gameobject` SET `position_z` = 46.544 WHERE `guid` = 6941629;
UPDATE `gameobject` SET `position_z` = 39.413 WHERE `guid` = 6942309;
UPDATE `gameobject` SET `position_z` = 72.156 WHERE `guid` = 6940146;

-- 3. Open-air soft burials raised to map height (9)
UPDATE `gameobject` SET `position_z` = 96.2151 WHERE `guid` = 6942084;
UPDATE `gameobject` SET `position_z` = 15.1595 WHERE `guid` = 6942175;
UPDATE `gameobject` SET `position_z` = 157.6245 WHERE `guid` = 6940009;
UPDATE `gameobject` SET `position_z` = 46.4067 WHERE `guid` = 6941295;
UPDATE `gameobject` SET `position_z` = 57.105 WHERE `guid` = 6941751;
UPDATE `gameobject` SET `position_z` = 35.8215 WHERE `guid` = 6941462;
UPDATE `gameobject` SET `position_z` = 1334.8432 WHERE `guid` = 6941801;
UPDATE `gameobject` SET `position_z` = 48.242 WHERE `guid` = 6942121;
UPDATE `gameobject` SET `position_z` = 38.2406 WHERE `guid` = 6942276;

COMMIT;
