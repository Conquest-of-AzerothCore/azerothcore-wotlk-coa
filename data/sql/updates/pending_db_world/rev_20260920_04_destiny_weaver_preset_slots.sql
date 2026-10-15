-- Destiny Weaver: correct the gear slots every cloned preset was built with.
--
-- The sixteen preset rows were written by cloning a dressed NPC's CreatureDisplayInfoExtra row,
-- but reading its item block from field 9.  The block actually starts at field 8, and its last
-- two slots run tabard then cape while the wire carries back then tabard.  Every cloned look
-- therefore arrived one slot early with its cape and tabard swapped: the head slot held a
-- shoulder model (visible in game as the missing-model cube), gloves showed as bracers, and so
-- on down the line.
--
-- The mapping, taken from this realm's own CreatureDisplayInfoExtra.dbc and cross-checked by
-- what each id actually is (its model paths and texture suffixes):
--
--   extra field   8     9      10    11     12     13    14    15     16     17      18
--   slot         head  shldr  shirt chest  waist  legs  feet  wrists hands  tabard  cape
--
-- The two human Weavers are untouched: their values came from the capture
-- (rev_20260920_00 / rev_20260920_02), not from a clone.
--
-- The same revision spells 449350 the way the live client's own creature cache carries it,
-- with a typographic apostrophe (U+2019).  Written as bytes so this file stays ASCII:
-- 54 61 76 E2 80 99 72 61 6C = "Tav" + U+2019 + "ral".

UPDATE `creature_template` SET `name` = CONVERT(UNHEX('546176E2809972616C') USING utf8mb4) WHERE `entry` = 449350;
UPDATE `creature_display_preset` SET `item_head` = 53350, `item_shoulders` = 25488, `item_body` = 53351, `item_chest` = 28691, `item_waist` = 28692, `item_legs` = 25487, `item_feet` = 25486, `item_wrists` = 34270, `item_hands` = 25460, `item_back` = 52659, `item_tabard` = 50924 WHERE `entry` = 449340;  -- Tav'vin, cloned from extra 19788
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 146593, `item_body` = 148098, `item_chest` = 149499, `item_waist` = 151349, `item_legs` = 153458, `item_feet` = 24288, `item_wrists` = 156541, `item_hands` = 24289, `item_back` = 158669, `item_tabard` = 158509 WHERE `entry` = 449341;  -- Magistrix Benjamin, cloned from extra 13654
UPDATE `creature_display_preset` SET `item_head` = 41412, `item_shoulders` = 41413, `item_body` = 41414, `item_chest` = 37958, `item_waist` = 37959, `item_legs` = 37960, `item_feet` = 41415, `item_wrists` = 0, `item_hands` = 27475, `item_back` = 28579, `item_tabard` = 10389 WHERE `entry` = 449342;  -- Thrain Galewin, cloned from extra 16090
UPDATE `creature_display_preset` SET `item_head` = 49456, `item_shoulders` = 49457, `item_body` = 50482, `item_chest` = 49458, `item_waist` = 49459, `item_legs` = 49460, `item_feet` = 49461, `item_wrists` = 39650, `item_hands` = 50020, `item_back` = 52650, `item_tabard` = 50925 WHERE `entry` = 449343;  -- Veylae, cloned from extra 18921
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 43662, `item_body` = 46182, `item_chest` = 46183, `item_waist` = 41405, `item_legs` = 44380, `item_feet` = 41448, `item_wrists` = 46731, `item_hands` = 41449, `item_back` = 18764, `item_tabard` = 46853 WHERE `entry` = 449344;  -- Saltheris Dawnborn, cloned from extra 17930
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 40757, `item_body` = 7696, `item_chest` = 42415, `item_waist` = 40759, `item_legs` = 40760, `item_feet` = 40761, `item_wrists` = 23935, `item_hands` = 41477, `item_back` = 42416, `item_tabard` = 40183 WHERE `entry` = 449345;  -- Elundra Moonsong, cloned from extra 16652
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 24408, `item_body` = 48191, `item_chest` = 23977, `item_waist` = 32502, `item_legs` = 30437, `item_feet` = 23974, `item_wrists` = 23973, `item_hands` = 23975, `item_back` = 18764, `item_tabard` = 40869 WHERE `entry` = 449346;  -- Waerun Cliffwalker, cloned from extra 18453
UPDATE `creature_display_preset` SET `item_head` = 53350, `item_shoulders` = 25488, `item_body` = 53351, `item_chest` = 28691, `item_waist` = 28692, `item_legs` = 25487, `item_feet` = 25486, `item_wrists` = 34270, `item_hands` = 25460, `item_back` = 52659, `item_tabard` = 50924 WHERE `entry` = 449350;  -- Tav'ral, cloned from extra 19788
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 146593, `item_body` = 148098, `item_chest` = 149499, `item_waist` = 151349, `item_legs` = 153458, `item_feet` = 24288, `item_wrists` = 156541, `item_hands` = 24289, `item_back` = 158669, `item_tabard` = 158509 WHERE `entry` = 449351;  -- Magistrix Belanor, cloned from extra 13654
UPDATE `creature_display_preset` SET `item_head` = 41412, `item_shoulders` = 41413, `item_body` = 41414, `item_chest` = 37958, `item_waist` = 37959, `item_legs` = 37960, `item_feet` = 41415, `item_wrists` = 0, `item_hands` = 27475, `item_back` = 28579, `item_tabard` = 10389 WHERE `entry` = 449352;  -- Thrainnor Galestrom, cloned from extra 16090
UPDATE `creature_display_preset` SET `item_head` = 49456, `item_shoulders` = 49457, `item_body` = 50482, `item_chest` = 49458, `item_waist` = 49459, `item_legs` = 49460, `item_feet` = 49461, `item_wrists` = 39650, `item_hands` = 50020, `item_back` = 52650, `item_tabard` = 50925 WHERE `entry` = 449353;  -- Veylin, cloned from extra 18921
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 43662, `item_body` = 46182, `item_chest` = 46183, `item_waist` = 41405, `item_legs` = 44380, `item_feet` = 41448, `item_wrists` = 46731, `item_hands` = 41449, `item_back` = 18764, `item_tabard` = 46853 WHERE `entry` = 449354;  -- Salthoril Dawnspire, cloned from extra 17930
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 40757, `item_body` = 7696, `item_chest` = 42415, `item_waist` = 40759, `item_legs` = 40760, `item_feet` = 40761, `item_wrists` = 23935, `item_hands` = 41477, `item_back` = 42416, `item_tabard` = 40183 WHERE `entry` = 449355;  -- Elundrel Moonsinger, cloned from extra 16652
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 24408, `item_body` = 48191, `item_chest` = 23977, `item_waist` = 32502, `item_legs` = 30437, `item_feet` = 23974, `item_wrists` = 23973, `item_hands` = 23975, `item_back` = 18764, `item_tabard` = 40869 WHERE `entry` = 449356;  -- Waeric Cliffstrider, cloned from extra 18453
