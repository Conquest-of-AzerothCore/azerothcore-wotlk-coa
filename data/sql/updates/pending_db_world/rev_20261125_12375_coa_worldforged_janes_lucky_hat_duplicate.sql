-- Jane's Lucky Hat (item 515362, object 96173, #12375): 2026_09_23_05_worldforged_map.sql placed two copies
-- inside Fungal Rock cave in Un'Goro Crater: guid 6941881 at (-6262.0, -2000.8, -261.251), 1.4 yd from the
-- CoA realm-dump sighting (-6263.19, -2001.46, -261.251), and guid 6941882 at (-6359.0, -2024.5, -259.030),
-- a cross-realm copy plotted under the item name alongside the object name. Remove the duplicate 6941882.
DELETE FROM `gameobject` WHERE `guid` = 6941882 AND `id` = 96173 AND `map` = 1 AND `position_x` BETWEEN -6359.5 AND -6358.5 AND `position_y` BETWEEN -2025.0 AND -2024.0;
