-- CoA worldforged: remove misplaced gear pickups, move the ones with no correct spawn
--
-- Scope: worldforged pickups whose item is equippable gear (weapons; armor incl. rings, necks,
-- cloaks, shields, trinkets and relics). Bags, consumables and scrolls are not touched.
--
-- Every spawn was compared with the recorded find positions for its item: LootCollector
-- (Vol'jin realm database first, then the Bronzebeard database and the addon's starter
-- database) and the archived community pins and zone dumps (hertigservices/ascension-data,
-- supplemental/worldforged, captured 2026-08/09). A spawn counts as correct within 60 yd of a
-- recorded position of the same item on the same map. LootCollector zone coordinates were
-- converted to world coordinates through WorldMapArea.dbc bounds (0.7 yd median against the
-- pins that carry both).
--
-- Most misplaced spawns hold the right zone coordinates applied to the wrong zone (Feralas
-- items in Arathi, Hinterlands items in Darkshore, Un'Goro items in Ashenvale, Silithus items in
-- the Hinterlands, ...): the realm-map placement of 2026_09_23_05_worldforged_map.sql.
--
-- 1. Removed: a spawn that is not at any recorded position while another spawn of the same
--    item already stands at one. The item stays obtainable at its correct spot.
-- 2. Moved: an item with no correctly placed spawn gets one of its spawns moved to the recorded
--    position; any further misplaced copies are removed. The height is the recorded height of
--    the live object at that spot, or the floor of the realm's nearest object or creature.
-- 3. Added: an item whose pickup template has no spawn at all gets one at its recorded position,
--    when a height can be read there the same way.
-- Spawns placed by hand in game (authored/playtest/in-game check passes) that stand within
-- 300 yd of a recorded position are left alone: they were moved to a reachable spot on purpose.
--
-- Every statement only applies while the spawn is still where main has it (2026-10-24), so a
-- newer correction to the same pickup is never overwritten. Orientation is unchanged.

-- Moved
-- Ambercoil Pendant (item 515163, guid 6940038): Arathi Highlands -> Feralas, source LC Vol'jin, height: recorded live height
UPDATE `gameobject` SET `map` = 1, `position_x` = -5281.0, `position_y` = 8.9, `position_z` = 19.44 WHERE `guid` = 6940038 AND `id` = 96138 AND `map` = 0 AND `position_x` BETWEEN -1643.3 AND -1642.3 AND `position_y` BETWEEN -3677.7 AND -3676.7;
-- Dwarven Crossbow (item 3595662, guid 6940397): Badlands -> maraudonpurple, source pins(dump), height: floor of nearest gameobject 5.0 yd away
UPDATE `gameobject` SET `map` = 1, `position_x` = -1281.3, `position_y` = 2922.6, `position_z` = 74.28 WHERE `guid` = 6940397 AND `id` = 1345045 AND `map` = 0 AND `position_x` BETWEEN -6099.2 AND -6098.2 AND `position_y` BETWEEN -3019.3 AND -3018.3;
-- Grimtotem Outrider's Vest (item 515156, guid 6940582): Arathi Highlands -> Feralas, source LC Vol'jin, height: floor of nearest creature 7.7 yd away
UPDATE `gameobject` SET `map` = 1, `position_x` = -4168.1, `position_y` = 587.8, `position_z` = 71.26 WHERE `guid` = 6940582 AND `id` = 96114 AND `map` = 0 AND `position_x` BETWEEN -1066.6 AND -1065.6 AND `position_y` BETWEEN -3380.7 AND -3379.7;
-- Hivebreakers' Ward (item 515767, guid 6941839): Un'Goro Crater -> Tanaris, source pins(dump), height: floor of nearest creature 13.4 yd away
UPDATE `gameobject` SET `map` = 1, `position_x` = -8589.0, `position_y` = -2219.0, `position_z` = 11.98 WHERE `guid` = 6941839 AND `id` = 515767 AND `map` = 1 AND `position_x` BETWEEN -7935.6 AND -7934.6 AND `position_y` BETWEEN -2408.4 AND -2407.4;
-- Kazkaz's Ceremonial Mask (item 354240, guid 6940678): Swamp of Sorrows -> thetempleofatalhakkar, source pins(dump), height: floor of nearest creature 3.7 yd away
UPDATE `gameobject` SET `map` = 109, `position_x` = -496.6, `position_y` = 96.7, `position_z` = -189.73 WHERE `guid` = 6940678 AND `id` = 254375 AND `map` = 0 AND `position_x` BETWEEN -10348.8 AND -10347.8 AND `position_y` BETWEEN -3968.2 AND -3967.2;
-- Necklace of Purity (item 515339, guid 6940796): Alterac Mountains -> Felwood, source LC Vol'jin, height: recorded live height
UPDATE `gameobject` SET `map` = 1, `position_x` = 6131.7, `position_y` = -1516.2, `position_z` = 440.82 WHERE `guid` = 6940796 AND `id` = 96161 AND `map` = 0 AND `position_x` BETWEEN 1013.2 AND 1014.2 AND `position_y` BETWEEN -755.8 AND -754.8;
-- Shorean's Ironwood Longbow (item 354462, guid 6942171): Mulgore -> Deadwind Pass, source LC Vol'jin, height: floor of nearest gameobject 1.0 yd away
UPDATE `gameobject` SET `map` = 0, `position_x` = -11107.5, `position_y` = -1901.8, `position_z` = 0.51 WHERE `guid` = 6942171 AND `id` = 1345127 AND `map` = 1 AND `position_x` BETWEEN -2821.4 AND -2820.4 AND `position_y` BETWEEN -148.1 AND -147.1;

-- Removed, grouped by the zone the misplaced copy stands in
-- Alterac Mountains
-- Acid Bolter (item 515340, guid 6940009): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940009 AND `id` = 517275 AND `map` = 0 AND `position_x` BETWEEN -83.8 AND -82.8 AND `position_y` BETWEEN -582.0 AND -581.0;
-- Bitterbranch Claymore (item 515342, guid 6940121): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940121 AND `id` = 517276 AND `map` = 0 AND `position_x` BETWEEN 982.4 AND 983.4 AND `position_y` BETWEEN -364.8 AND -363.8;
-- Bones to Munch (item 354476, guid 6940167): belongs in Arathi Highlands
DELETE FROM `gameobject` WHERE `guid` = 6940167 AND `id` = 90225 AND `map` = 0 AND `position_x` BETWEEN 659.8 AND 660.8 AND `position_y` BETWEEN -1120.8 AND -1119.8;
-- Bubbling Fel Mixture (item 515319, guid 6940199): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940199 AND `id` = 517233 AND `map` = 0 AND `position_x` BETWEEN 360.1 AND 361.1 AND `position_y` BETWEEN -198.3 AND -197.3;
-- Carrion Eye (item 824401, guid 6940219): belongs in shadowglenstart
DELETE FROM `gameobject` WHERE `guid` = 6940219 AND `id` = 520067 AND `map` = 0 AND `position_x` BETWEEN 1115.7 AND 1116.7 AND `position_y` BETWEEN -1085.0 AND -1084.0;
-- Crystal of Cruel Corruption (item 515333, guid 6940281): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940281 AND `id` = 96158 AND `map` = 0 AND `position_x` BETWEEN 1387.5 AND 1388.5 AND `position_y` BETWEEN -784.9 AND -783.9;
-- Decayed Breeches (item 521121, guid 6940329): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940329 AND `id` = 517364 AND `map` = 0 AND `position_x` BETWEEN 379.9 AND 380.9 AND `position_y` BETWEEN -309.1 AND -308.1;
-- Disciple String (item 824399, guid 6940364): belongs in shadowglenstart
DELETE FROM `gameobject` WHERE `guid` = 6940364 AND `id` = 520069 AND `map` = 0 AND `position_x` BETWEEN -240.4 AND -239.4 AND `position_y` BETWEEN -917.9 AND -916.9;
-- Emerald Circle Charm (item 515314, guid 6940429): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940429 AND `id` = 517204 AND `map` = 0 AND `position_x` BETWEEN -12.0 AND -11.0 AND `position_y` BETWEEN -645.0 AND -644.0;
-- Enchanted Kobold Lantern (item 450729, guid 6940437): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940437 AND `id` = 95619 AND `map` = 0 AND `position_x` BETWEEN 454.5 AND 455.5 AND `position_y` BETWEEN -1036.9 AND -1035.9;
-- Fallen Sentinel's Leggings (item 515328, guid 6940457): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940457 AND `id` = 517257 AND `map` = 0 AND `position_x` BETWEEN 1093.8 AND 1094.8 AND `position_y` BETWEEN -313.0 AND -312.0;
-- Felhound Tendril (item 515318, guid 6940464): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940464 AND `id` = 517232 AND `map` = 0 AND `position_x` BETWEEN 342.6 AND 343.6 AND `position_y` BETWEEN -299.9 AND -298.9;
-- Fisherman's Jerkin (item 521128, guid 6940478): belongs in Elwynn Forest
DELETE FROM `gameobject` WHERE `guid` = 6940478 AND `id` = 387850 AND `map` = 0 AND `position_x` BETWEEN 305.3 AND 306.3 AND `position_y` BETWEEN -187.9 AND -186.9;
-- Forgotten Wristguards (item 515202, guid 6940637): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940637 AND `id` = 96130 AND `map` = 0 AND `position_x` BETWEEN 1111.4 AND 1112.4 AND `position_y` BETWEEN -729.0 AND -728.0;
-- Heart of the Warpwood (item 515331, guid 6940605): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940605 AND `id` = 96155 AND `map` = 0 AND `position_x` BETWEEN 1163.6 AND 1164.6 AND `position_y` BETWEEN -840.9 AND -839.9;
-- Infernal Tender (item 515324, guid 6940652): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940652 AND `id` = 1345077 AND `map` = 0 AND `position_x` BETWEEN 731.8 AND 732.8 AND `position_y` BETWEEN -367.6 AND -366.6;
-- Ironbeard's Axe (item 450812, guid 6940658): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940658 AND `id` = 95706 AND `map` = 0 AND `position_x` BETWEEN -129.3 AND -128.3 AND `position_y` BETWEEN -370.5 AND -369.5;
-- Ironwood Cap (item 515329, guid 6940660): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940660 AND `id` = 517263 AND `map` = 0 AND `position_x` BETWEEN 1033.0 AND 1034.0 AND `position_y` BETWEEN -584.3 AND -583.3;
-- Jadefire Bone Breaker (item 515315, guid 6940665): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940665 AND `id` = 517210 AND `map` = 0 AND `position_x` BETWEEN -50.0 AND -49.0 AND `position_y` BETWEEN -307.2 AND -306.2;
-- Jadefire Piercer (item 515317, guid 6940666): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940666 AND `id` = 517225 AND `map` = 0 AND `position_x` BETWEEN 251.0 AND 252.0 AND `position_y` BETWEEN -133.9 AND -132.9;
-- Jaednar Spire (item 515322, guid 6940667): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940667 AND `id` = 517237 AND `map` = 0 AND `position_x` BETWEEN 487.8 AND 488.8 AND `position_y` BETWEEN -279.2 AND -278.2;
-- Lost Shipment Wristguards (item 515316, guid 6940725): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940725 AND `id` = 517224 AND `map` = 0 AND `position_x` BETWEEN 141.8 AND 142.8 AND `position_y` BETWEEN -470.1 AND -469.1;
-- Mismatched Shoulderpads (item 521245, guid 6960022): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6960022 AND `id` = 517314 AND `map` = 0 AND `position_x` BETWEEN 1018.1 AND 1019.1 AND `position_y` BETWEEN 708.3 AND 709.3;
-- Murder Machete (item 450871, guid 6940782): belongs in Elwynn Forest
DELETE FROM `gameobject` WHERE `guid` = 6940782 AND `id` = 95697 AND `map` = 0 AND `position_x` BETWEEN 323.9 AND 324.9 AND `position_y` BETWEEN -561.0 AND -560.0;
-- Nest Thorn (item 824400, guid 6940800): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6940800 AND `id` = 520068 AND `map` = 0 AND `position_x` BETWEEN -80.4 AND -79.4 AND `position_y` BETWEEN -1269.8 AND -1268.8;
-- Nest Thorn (item 824400, guid 6940801): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6940801 AND `id` = 520068 AND `map` = 0 AND `position_x` BETWEEN 1081.0 AND 1082.0 AND `position_y` BETWEEN -1254.6 AND -1253.6;
-- Old Snapjaw Shell (item 515022, guid 6940842): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6940842 AND `id` = 515379 AND `map` = 0 AND `position_x` BETWEEN 465.2 AND 466.2 AND `position_y` BETWEEN 443.8 AND 444.8;
-- Old Snapjaw Shell (item 515022, guid 6941283): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6941283 AND `id` = 515379 AND `map` = 0 AND `position_x` BETWEEN 547.8 AND 548.8 AND `position_y` BETWEEN -1479.1 AND -1478.1;
-- Rotwood Sabre (item 515343, guid 6940978): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940978 AND `id` = 517277 AND `map` = 0 AND `position_x` BETWEEN 1225.6 AND 1226.6 AND `position_y` BETWEEN -422.7 AND -421.7;
-- Silverhand Spaulders (item 515320, guid 6941084): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941084 AND `id` = 517234 AND `map` = 0 AND `position_x` BETWEEN 563.0 AND 564.0 AND `position_y` BETWEEN -301.6 AND -300.6;
-- Sindelle's Fuzzy Cuffs (item 515330, guid 6941085): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941085 AND `id` = 96156 AND `map` = 0 AND `position_x` BETWEEN 753.1 AND 754.1 AND `position_y` BETWEEN -561.0 AND -560.0;
-- Talonbranch Sweeper (item 515334, guid 6941196): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941196 AND `id` = 517271 AND `map` = 0 AND `position_x` BETWEEN 1047.4 AND 1048.4 AND `position_y` BETWEEN -903.6 AND -902.6;
-- Thornmantle Quills (item 450610, guid 6941230): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941230 AND `id` = 90332 AND `map` = 0 AND `position_x` BETWEEN -239.1 AND -238.1 AND `position_y` BETWEEN -1679.6 AND -1678.6;
-- Timbermaw Girdle (item 515337, guid 6941258): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941258 AND `id` = 517274 AND `map` = 0 AND `position_x` BETWEEN 1428.4 AND 1429.4 AND `position_y` BETWEEN -1038.8 AND -1037.8;
-- Timelost Captain Shield (item 515023, guid 6941259): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6941259 AND `id` = 515380 AND `map` = 0 AND `position_x` BETWEEN -41.9 AND -40.9 AND `position_y` BETWEEN 128.1 AND 129.1;
-- Timelost Vestments (item 515313, guid 6941260): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941260 AND `id` = 96166 AND `map` = 0 AND `position_x` BETWEEN -105.3 AND -104.3 AND `position_y` BETWEEN -812.9 AND -811.9;
-- Tracker's Dagger (item 450676, guid 6941267): belongs in shadowthreadcave
DELETE FROM `gameobject` WHERE `guid` = 6941267 AND `id` = 95606 AND `map` = 0 AND `position_x` BETWEEN -340.0 AND -339.0 AND `position_y` BETWEEN -757.9 AND -756.9;
-- Traveler's Forest Cloak (item 521122, guid 6941277): belongs in Elwynn Forest
DELETE FROM `gameobject` WHERE `guid` = 6941277 AND `id` = 517366 AND `map` = 0 AND `position_x` BETWEEN 174.6 AND 175.6 AND `position_y` BETWEEN -1230.5 AND -1229.5;
-- Umbral Stalker's Tarp (item 515327, guid 6941288): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941288 AND `id` = 517254 AND `map` = 0 AND `position_x` BETWEEN 863.9 AND 864.9 AND `position_y` BETWEEN -482.6 AND -481.6;
-- Xorothian Slippers (item 515321, guid 6941359): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941359 AND `id` = 517235 AND `map` = 0 AND `position_x` BETWEEN 676.6 AND 677.6 AND `position_y` BETWEEN -223.5 AND -222.5;
-- Arathi Highlands
-- Accursed Yeti Horn (item 515205, guid 6940008): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940008 AND `id` = 96132 AND `map` = 0 AND `position_x` BETWEEN -949.0 AND -948.0 AND `position_y` BETWEEN -2813.4 AND -2812.4;
-- Beastpile Drape (item 515167, guid 6940113): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940113 AND `id` = 96142 AND `map` = 0 AND `position_x` BETWEEN -1667.1 AND -1666.1 AND `position_y` BETWEEN -3507.8 AND -3506.8;
-- Bench Breaker (item 515161, guid 6940114): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940114 AND `id` = 96146 AND `map` = 0 AND `position_x` BETWEEN -1478.5 AND -1477.5 AND `position_y` BETWEEN -3426.5 AND -3425.5;
-- Bloodscorn Ritual Kris (item 515204, guid 6940156): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940156 AND `id` = 96131 AND `map` = 0 AND `position_x` BETWEEN -901.5 AND -900.5 AND `position_y` BETWEEN -2834.6 AND -2833.6;
-- Buccaneer's Barrier (item 515206, guid 6940201): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940201 AND `id` = 515864 AND `map` = 0 AND `position_x` BETWEEN -1427.8 AND -1426.8 AND `position_y` BETWEEN -2633.0 AND -2632.0;
-- Dormant Dreamscale (item 515195, guid 6940375): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940375 AND `id` = 515865 AND `map` = 0 AND `position_x` BETWEEN -613.3 AND -612.3 AND `position_y` BETWEEN -2700.3 AND -2699.3;
-- Dwarven Sandals (item 521143, guid 6940405): belongs in Loch Modan
DELETE FROM `gameobject` WHERE `guid` = 6940405 AND `id` = 517336 AND `map` = 0 AND `position_x` BETWEEN -665.3 AND -664.3 AND `position_y` BETWEEN -2270.4 AND -2269.4;
-- Gilded Stone Bulwark (item 515197, guid 6940541): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940541 AND `id` = 96133 AND `map` = 0 AND `position_x` BETWEEN -423.2 AND -422.2 AND `position_y` BETWEEN -2340.7 AND -2339.7;
-- Gordunni Thumbtack (item 515153, guid 6940559): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940559 AND `id` = 1345062 AND `map` = 0 AND `position_x` BETWEEN -751.7 AND -750.7 AND `position_y` BETWEEN -3569.7 AND -3568.7;
-- Grasping Claw (item 515150, guid 6940564): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940564 AND `id` = 96104 AND `map` = 0 AND `position_x` BETWEEN -920.2 AND -919.2 AND `position_y` BETWEEN -3568.7 AND -3567.7;
-- Grim Totem (item 515155, guid 6940577): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940577 AND `id` = 515853 AND `map` = 0 AND `position_x` BETWEEN -1048.6 AND -1047.6 AND `position_y` BETWEEN -3282.8 AND -3281.8;
-- Hardened Scarab Gauntlets (item 410062, guid 6940591): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6940591 AND `id` = 686885 AND `map` = 0 AND `position_x` BETWEEN -274.8 AND -273.8 AND `position_y` BETWEEN -2299.7 AND -2298.7;
-- Hatestrike (item 515191, guid 6940597): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940597 AND `id` = 96124 AND `map` = 0 AND `position_x` BETWEEN -1832.5 AND -1831.5 AND `position_y` BETWEEN -1901.9 AND -1900.9;
-- Heartwood Cleaver (item 515146, guid 6940606): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6940606 AND `id` = 96102 AND `map` = 0 AND `position_x` BETWEEN -1085.6 AND -1084.6 AND `position_y` BETWEEN -3782.5 AND -3781.5;
-- Isildien Tender's Wand (item 515175, guid 6940661): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940661 AND `id` = 515884 AND `map` = 0 AND `position_x` BETWEEN -1789.5 AND -1788.5 AND `position_y` BETWEEN -2919.6 AND -2918.6;
-- Long-Clawed Gnoll Paw (item 515168, guid 6940711): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940711 AND `id` = 96143 AND `map` = 0 AND `position_x` BETWEEN -1620.3 AND -1619.3 AND `position_y` BETWEEN -3534.8 AND -3533.8;
-- Moonlight Infused Band (item 515143, guid 6940764): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940764 AND `id` = 518135 AND `map` = 0 AND `position_x` BETWEEN -1069.5 AND -1068.5 AND `position_y` BETWEEN -4070.5 AND -4069.5;
-- Necklace of the Sunken Empire (item 515178, guid 6940797): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940797 AND `id` = 96116 AND `map` = 0 AND `position_x` BETWEEN -1957.5 AND -1956.5 AND `position_y` BETWEEN -2774.5 AND -2773.5;
-- Nightfallen Longbow (item 515169, guid 6940806): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940806 AND `id` = 96109 AND `map` = 0 AND `position_x` BETWEEN -1598.7 AND -1597.7 AND `position_y` BETWEEN -3322.4 AND -3321.4;
-- Ogre Cleaver (item 515152, guid 6940818): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6940818 AND `id` = 96106 AND `map` = 0 AND `position_x` BETWEEN -838.1 AND -837.1 AND `position_y` BETWEEN -3565.4 AND -3564.4;
-- Ogre Kneepad (item 515177, guid 6940823): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940823 AND `id` = 96115 AND `map` = 0 AND `position_x` BETWEEN -1765.0 AND -1764.0 AND `position_y` BETWEEN -2972.5 AND -2971.5;
-- Old God Carving (item 410073, guid 6940834): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940834 AND `id` = 518456 AND `map` = 0 AND `position_x` BETWEEN -500.1 AND -499.1 AND `position_y` BETWEEN -3698.8 AND -3697.8;
-- Ravenwind Codex (item 515199, guid 6940936): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940936 AND `id` = 515844 AND `map` = 0 AND `position_x` BETWEEN -517.5 AND -516.5 AND `position_y` BETWEEN -2270.5 AND -2269.5;
-- Ravenwind Fangblade (item 515196, guid 6940937): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940937 AND `id` = 96127 AND `map` = 0 AND `position_x` BETWEEN -376.1 AND -375.1 AND `position_y` BETWEEN -2462.0 AND -2461.0;
-- Rockstalker Silk Robe (item 410064, guid 6940974): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940974 AND `id` = 356434 AND `map` = 0 AND `position_x` BETWEEN -481.3 AND -480.3 AND `position_y` BETWEEN -2847.9 AND -2846.9;
-- Runaway's Tunic (item 410050, guid 6940984): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940984 AND `id` = 1345118 AND `map` = 0 AND `position_x` BETWEEN -323.0 AND -322.0 AND `position_y` BETWEEN -4158.1 AND -4157.1;
-- Runestone Figurine (item 515176, guid 6940987): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940987 AND `id` = 96111 AND `map` = 0 AND `position_x` BETWEEN -1837.5 AND -1836.5 AND `position_y` BETWEEN -2972.5 AND -2971.5;
-- Savage Crossbow (item 515159, guid 6941006): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941006 AND `id` = 96144 AND `map` = 0 AND `position_x` BETWEEN -1429.7 AND -1428.7 AND `position_y` BETWEEN -3634.5 AND -3633.5;
-- Scorpionscale Mantle (item 410068, guid 6941031): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941031 AND `id` = 518462 AND `map` = 0 AND `position_x` BETWEEN -908.1 AND -907.1 AND `position_y` BETWEEN -3308.0 AND -3307.0;
-- Secluded Soothsayer's Pipes (item 515162, guid 6941044): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941044 AND `id` = 515958 AND `map` = 0 AND `position_x` BETWEEN -1688.9 AND -1687.9 AND `position_y` BETWEEN -3638.1 AND -3637.1;
-- Sentinel Wrap (item 515184, guid 6941047): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941047 AND `id` = 1345124 AND `map` = 0 AND `position_x` BETWEEN -1714.6 AND -1713.6 AND `position_y` BETWEEN -2519.6 AND -2518.6;
-- Shattered Highborne Blade (item 515174, guid 6941066): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941066 AND `id` = 515887 AND `map` = 0 AND `position_x` BETWEEN -1902.8 AND -1901.8 AND `position_y` BETWEEN -3071.1 AND -3070.1;
-- Shen'dralar Slicer (item 515182, guid 6941068): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941068 AND `id` = 515880 AND `map` = 0 AND `position_x` BETWEEN -1285.5 AND -1284.5 AND `position_y` BETWEEN -2846.5 AND -2845.5;
-- Shimmering Silithid Carapace (item 515165, guid 6941070): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941070 AND `id` = 96140 AND `map` = 0 AND `position_x` BETWEEN -1738.9 AND -1737.9 AND `position_y` BETWEEN -3608.3 AND -3607.3;
-- Silithic Scale Hauberk (item 410061, guid 6941078): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941078 AND `id` = 1345128 AND `map` = 0 AND `position_x` BETWEEN -134.4 AND -133.4 AND `position_y` BETWEEN -2487.2 AND -2486.2;
-- Stolen Highborne Spaulders (item 515149, guid 6941148): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941148 AND `id` = 96103 AND `map` = 0 AND `position_x` BETWEEN -982.9 AND -981.9 AND `position_y` BETWEEN -3527.6 AND -3526.6;
-- Strider Shot (item 515186, guid 6941168): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941168 AND `id` = 515877 AND `map` = 0 AND `position_x` BETWEEN -949.5 AND -948.5 AND `position_y` BETWEEN -2306.5 AND -2305.5;
-- Strider Waist Piece (item 515187, guid 6941169): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941169 AND `id` = 96125 AND `map` = 0 AND `position_x` BETWEEN -971.1 AND -970.1 AND `position_y` BETWEEN -2207.9 AND -2206.9;
-- Tanner Gloves (item 515192, guid 6941198): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941198 AND `id` = 96126 AND `map` = 0 AND `position_x` BETWEEN -950.5 AND -949.5 AND `position_y` BETWEEN -2705.4 AND -2704.4;
-- Worn Angler Cord (item 515158, guid 6941351): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941351 AND `id` = 96108 AND `map` = 0 AND `position_x` BETWEEN -1237.5 AND -1236.5 AND `position_y` BETWEEN -3602.5 AND -3601.5;
-- Yeti Napkin (item 515181, guid 6941360): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941360 AND `id` = 96119 AND `map` = 0 AND `position_x` BETWEEN -1579.5 AND -1578.5 AND `position_y` BETWEEN -2742.5 AND -2741.5;
-- Zaetar's Lost Heirloom (item 515200, guid 6941364): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941364 AND `id` = 96128 AND `map` = 0 AND `position_x` BETWEEN -205.5 AND -204.5 AND `position_y` BETWEEN -2522.5 AND -2521.5;
-- Zapping Rod (item 515185, guid 6941366): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941366 AND `id` = 515878 AND `map` = 0 AND `position_x` BETWEEN -1170.1 AND -1169.1 AND `position_y` BETWEEN -2487.9 AND -2486.9;
-- Ashenvale
-- Apothecary's Lantern (item 515015, guid 6941408): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941408 AND `id` = 1345003 AND `map` = 1 AND `position_x` BETWEEN 3143.9 AND 3144.9 AND `position_y` BETWEEN -837.5 AND -836.5;
-- Butchery Blade (item 450874, guid 6941519): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941519 AND `id` = 95805 AND `map` = 1 AND `position_x` BETWEEN 2942.1 AND 2943.1 AND `position_y` BETWEEN -2163.7 AND -2162.7;
-- Campsite Shrapnel (item 515391, guid 6941522): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941522 AND `id` = 95919 AND `map` = 1 AND `position_x` BETWEEN 3249.6 AND 3250.6 AND `position_y` BETWEEN -2226.0 AND -2225.0;
-- Caravaneer's Machete (item 515401, guid 6941539): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941539 AND `id` = 95926 AND `map` = 1 AND `position_x` BETWEEN 2788.4 AND 2789.4 AND `position_y` BETWEEN -1702.4 AND -1701.4;
-- Cord of Living Vines (item 515396, guid 6941584): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941584 AND `id` = 96219 AND `map` = 1 AND `position_x` BETWEEN 3118.9 AND 3119.9 AND `position_y` BETWEEN -157.7 AND -156.7;
-- Faded Gravecloth Cuffs (item 521027, guid 6941717): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941717 AND `id` = 517347 AND `map` = 1 AND `position_x` BETWEEN 1902.2 AND 1903.2 AND `position_y` BETWEEN -2630.8 AND -2629.8;
-- Marsh Shooter (item 515357, guid 6941953): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941953 AND `id` = 96175 AND `map` = 1 AND `position_x` BETWEEN 1824.6 AND 1825.6 AND `position_y` BETWEEN -2450.9 AND -2449.9;
-- Molten Fang (item 515387, guid 6941960): belongs in Winterspring
DELETE FROM `gameobject` WHERE `guid` = 6941960 AND `id` = 95930 AND `map` = 1 AND `position_x` BETWEEN 2982.1 AND 2983.1 AND `position_y` BETWEEN -1128.7 AND -1127.7;
-- Mystic Geode (item 515358, guid 6941978): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941978 AND `id` = 96176 AND `map` = 1 AND `position_x` BETWEEN 2327.3 AND 2328.3 AND `position_y` BETWEEN -2971.0 AND -2970.0;
-- Nightfallen Jerkin (item 521030, guid 6941989): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941989 AND `id` = 517352 AND `map` = 1 AND `position_x` BETWEEN 2394.5 AND 2395.5 AND `position_y` BETWEEN -2106.1 AND -2105.1;
-- Old Arcanus Robe (item 450758, guid 6942001): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6942001 AND `id` = 1345103 AND `map` = 1 AND `position_x` BETWEEN 3057.4 AND 3058.4 AND `position_y` BETWEEN -2221.4 AND -2220.4;
-- Rattlecage Warplate (item 521031, guid 6942060): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6942060 AND `id` = 517368 AND `map` = 1 AND `position_x` BETWEEN 3019.0 AND 3020.0 AND `position_y` BETWEEN -1183.5 AND -1182.5;
-- Revantusk Hide Steppers (item 515718, guid 6941828): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941828 AND `id` = 95795 AND `map` = 1 AND `position_x` BETWEEN 3094.7 AND 3095.7 AND `position_y` BETWEEN -1927.9 AND -1926.9;
-- Slightly Sticky Cloak (item 515388, guid 6942204): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942204 AND `id` = 96222 AND `map` = 1 AND `position_x` BETWEEN 3288.0 AND 3289.0 AND `position_y` BETWEEN -1068.2 AND -1067.2;
-- Sparkshard Necklace (item 515378, guid 6942223): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942223 AND `id` = 96188 AND `map` = 1 AND `position_x` BETWEEN 2750.4 AND 2751.4 AND `position_y` BETWEEN -2743.2 AND -2742.2;
-- Tawana's Spare Axe (item 515400, guid 6942293): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942293 AND `id` = 96216 AND `map` = 1 AND `position_x` BETWEEN 2679.3 AND 2680.3 AND `position_y` BETWEEN -2502.8 AND -2501.8;
-- Wailing Sash (item 521040, guid 6942395): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6942395 AND `id` = 517367 AND `map` = 1 AND `position_x` BETWEEN 2212.0 AND 2213.0 AND `position_y` BETWEEN -2394.4 AND -2393.4;
-- Waterlogged Sparkler (item 515043, guid 6942413): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6942413 AND `id` = 515405 AND `map` = 1 AND `position_x` BETWEEN 3019.0 AND 3020.0 AND `position_y` BETWEEN -318.6 AND -317.6;
-- Azshara
-- Deathguard Vambraces (item 410149, guid 6941620): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941620 AND `id` = 90527 AND `map` = 1 AND `position_x` BETWEEN 2004.4 AND 2005.4 AND `position_y` BETWEEN -5749.9 AND -5748.9;
-- Ghoulbane Gauntlets (item 410142, guid 6941772): belongs in Alterac Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941772 AND `id` = 90508 AND `map` = 1 AND `position_x` BETWEEN 2249.7 AND 2250.7 AND `position_y` BETWEEN -3541.9 AND -3540.9;
-- Plaguebloom Spear (item 410154, guid 6942033): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942033 AND `id` = 90532 AND `map` = 1 AND `position_x` BETWEEN 4384.0 AND 4385.0 AND `position_y` BETWEEN -3652.3 AND -3651.3;
-- Azuremyst Isle
-- Blackthorn Splitter (item 521199, guid 6942461): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942461 AND `id` = 97114 AND `map` = 530 AND `position_x` BETWEEN -4191.8 AND -4190.8 AND `position_y` BETWEEN -11550.6 AND -11549.6;
-- Giant Qiraji Scale (item 521195, guid 6942467): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942467 AND `id` = 254556 AND `map` = 530 AND `position_x` BETWEEN -4121.3 AND -4120.3 AND `position_y` BETWEEN -11534.6 AND -11533.6;
-- Grunt's Chain Leggings (item 450724, guid 6942468): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942468 AND `id` = 95832 AND `map` = 530 AND `position_x` BETWEEN -3687.6 AND -3686.6 AND `position_y` BETWEEN -11480.3 AND -11479.3;
-- Muck Trudgers (item 515235, guid 6942470): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942470 AND `id` = 515947 AND `map` = 530 AND `position_x` BETWEEN -4022.9 AND -4021.9 AND `position_y` BETWEEN -11737.6 AND -11736.6;
-- Stump Biter (item 451085, guid 6942478): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942478 AND `id` = 95835 AND `map` = 530 AND `position_x` BETWEEN -4151.2 AND -4150.2 AND `position_y` BETWEEN -11586.1 AND -11585.1;
-- Takar's Old Wand (item 521197, guid 6942479): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942479 AND `id` = 97116 AND `map` = 530 AND `position_x` BETWEEN -4013.3 AND -4012.3 AND `position_y` BETWEEN -11589.2 AND -11588.2;
-- Badlands
-- Ambereye Amulet (item 354207, guid 6940039): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6940039 AND `id` = 254308 AND `map` = 0 AND `position_x` BETWEEN -7009.0 AND -7008.0 AND `position_y` BETWEEN -3494.1 AND -3493.1;
-- Apprentice's Harpoon (item 450799, guid 6940067): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940067 AND `id` = 95640 AND `map` = 0 AND `position_x` BETWEEN -7238.3 AND -7237.3 AND `position_y` BETWEEN -3403.1 AND -3402.1;
-- Champion's Band (item 521092, guid 6940232): belongs in Arathi Highlands
DELETE FROM `gameobject` WHERE `guid` = 6940232 AND `id` = 517370 AND `map` = 0 AND `position_x` BETWEEN -6659.8 AND -6658.8 AND `position_y` BETWEEN -3022.1 AND -3021.1;
-- Dwarven Crossbow (item 3595662, guid 6940396): belongs in Uldaman
DELETE FROM `gameobject` WHERE `guid` = 6940396 AND `id` = 1345045 AND `map` = 0 AND `position_x` BETWEEN -6619.0 AND -6618.0 AND `position_y` BETWEEN -2601.8 AND -2600.8;
-- Farm Hands (item 450713, guid 6940462): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940462 AND `id` = 95638 AND `map` = 0 AND `position_x` BETWEEN -6158.8 AND -6157.8 AND `position_y` BETWEEN -3267.5 AND -3266.5;
-- Greataxe of Kolk (item 354208, guid 6940575): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6940575 AND `id` = 254309 AND `map` = 0 AND `position_x` BETWEEN -7106.1 AND -7105.1 AND `position_y` BETWEEN -3223.3 AND -3222.3;
-- Logsplitter (item 450692, guid 6940708): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940708 AND `id` = 95648 AND `map` = 0 AND `position_x` BETWEEN -6387.2 AND -6386.2 AND `position_y` BETWEEN -3169.1 AND -3168.1;
-- Raptorscale Cloak (item 450697, guid 6940928): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940928 AND `id` = 95628 AND `map` = 0 AND `position_x` BETWEEN -7113.6 AND -7112.6 AND `position_y` BETWEEN -3689.3 AND -3688.3;
-- Shadowshard Shield (item 354209, guid 6941059): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6941059 AND `id` = 254310 AND `map` = 0 AND `position_x` BETWEEN -6230.2 AND -6229.2 AND `position_y` BETWEEN -3019.8 AND -3018.8;
-- Blasted Lands
-- Cowl of the Stone Summoner (item 415160, guid 6941167): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941167 AND `id` = 518123 AND `map` = 0 AND `position_x` BETWEEN -12423.0 AND -12422.0 AND `position_y` BETWEEN -1305.2 AND -1304.2;
-- Dustbringer (item 415153, guid 6940825): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940825 AND `id` = 518087 AND `map` = 0 AND `position_x` BETWEEN -12586.0 AND -12585.0 AND `position_y` BETWEEN -1452.5 AND -1451.5;
-- Duststorm Sash (item 354504, guid 6940394): belongs in Searing Gorge
DELETE FROM `gameobject` WHERE `guid` = 6940394 AND `id` = 518346 AND `map` = 0 AND `position_x` BETWEEN -12009.7 AND -12008.7 AND `position_y` BETWEEN -1533.0 AND -1532.0;
-- Earth Bindings (item 415148, guid 6941201): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941201 AND `id` = 518060 AND `map` = 0 AND `position_x` BETWEEN -12463.2 AND -12462.2 AND `position_y` BETWEEN -2742.3 AND -2741.3;
-- Focusing Spirit Band (item 415154, guid 6940586): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940586 AND `id` = 518086 AND `map` = 0 AND `position_x` BETWEEN -12711.1 AND -12710.1 AND `position_y` BETWEEN -1499.5 AND -1498.5;
-- Obsidian Boltthrower (item 410201, guid 6940813): belongs in Burning Steppes
DELETE FROM `gameobject` WHERE `guid` = 6940813 AND `id` = 686913 AND `map` = 0 AND `position_x` BETWEEN -12675.4 AND -12674.4 AND `position_y` BETWEEN -1399.0 AND -1398.0;
-- Ogre Fire Poker (item 415149, guid 6940821): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940821 AND `id` = 518063 AND `map` = 0 AND `position_x` BETWEEN -11844.3 AND -11843.3 AND `position_y` BETWEEN -2236.4 AND -2235.4;
-- Real Big Bone (item 415139, guid 6940940): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940940 AND `id` = 518030 AND `map` = 0 AND `position_x` BETWEEN -12000.7 AND -11999.7 AND `position_y` BETWEEN -3908.1 AND -3907.1;
-- Rock Runners (item 415145, guid 6940926): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940926 AND `id` = 518053 AND `map` = 0 AND `position_x` BETWEEN -12393.9 AND -12392.9 AND `position_y` BETWEEN -3124.2 AND -3123.2;
-- Safety Gloves (item 415131, guid 6940173): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940173 AND `id` = 518006 AND `map` = 0 AND `position_x` BETWEEN -11551.7 AND -11550.7 AND `position_y` BETWEEN -2119.2 AND -2118.2;
-- Sandworn Arcanist Staff (item 354503, guid 6940552): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940552 AND `id` = 518348 AND `map` = 0 AND `position_x` BETWEEN -11703.6 AND -11702.6 AND `position_y` BETWEEN -1837.8 AND -1836.8;
-- Spellpiercing Cloak (item 415147, guid 6940451): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940451 AND `id` = 518055 AND `map` = 0 AND `position_x` BETWEEN -12284.4 AND -12283.4 AND `position_y` BETWEEN -2960.1 AND -2959.1;
-- Stonebloom Idol (item 415150, guid 6940386): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940386 AND `id` = 518079 AND `map` = 0 AND `position_x` BETWEEN -12534.7 AND -12533.7 AND `position_y` BETWEEN -1593.3 AND -1592.3;
-- Stonewalker's Totem (item 415146, guid 6940051): belongs in Upperfargodeepmine
DELETE FROM `gameobject` WHERE `guid` = 6940051 AND `id` = 518054 AND `map` = 0 AND `position_x` BETWEEN -12092.3 AND -12091.3 AND `position_y` BETWEEN -2939.9 AND -2938.9;
-- Tombscarred Guardian (item 415144, guid 6940571): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940571 AND `id` = 518052 AND `map` = 0 AND `position_x` BETWEEN -12201.8 AND -12200.8 AND `position_y` BETWEEN -3144.3 AND -3143.3;
-- Vulture Cult Idol (item 824398, guid 6941311): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941311 AND `id` = 520071 AND `map` = 0 AND `position_x` BETWEEN -12195.5 AND -12194.5 AND `position_y` BETWEEN -2571.1 AND -2570.1;
-- Wand of the Ancients (item 354502, guid 6940056): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940056 AND `id` = 254565 AND `map` = 0 AND `position_x` BETWEEN -11784.0 AND -11783.0 AND `position_y` BETWEEN -3053.9 AND -3052.9;
-- Wind-Worn Longbow (item 415159, guid 6941343): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941343 AND `id` = 518102 AND `map` = 0 AND `position_x` BETWEEN -12016.4 AND -12015.4 AND `position_y` BETWEEN -2290.1 AND -2289.1;
-- Burning Steppes
-- Alther's Chain Wrap (item 521210, guid 6940037): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940037 AND `id` = 254541 AND `map` = 0 AND `position_x` BETWEEN -7913.2 AND -7912.2 AND `position_y` BETWEEN -1789.6 AND -1788.6;
-- Breastplate of the Current (item 354142, guid 6940184): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940184 AND `id` = 95662 AND `map` = 0 AND `position_x` BETWEEN -8908.9 AND -8907.9 AND `position_y` BETWEEN -709.0 AND -708.0;
-- Dragon Matriarch Cloak (item 450569, guid 6940378): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940378 AND `id` = 90280 AND `map` = 0 AND `position_x` BETWEEN -7636.6 AND -7635.6 AND `position_y` BETWEEN -1526.0 AND -1525.0;
-- Mrrrllrl Stick (item 450577, guid 6940776): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940776 AND `id` = 90265 AND `map` = 0 AND `position_x` BETWEEN -8220.9 AND -8219.9 AND `position_y` BETWEEN -2640.7 AND -2639.7;
-- Reverence of the Ancient Ones (item 354454, guid 6940956): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940956 AND `id` = 254506 AND `map` = 0 AND `position_x` BETWEEN -7957.1 AND -7956.1 AND `position_y` BETWEEN -1475.3 AND -1474.3;
-- Ribchaser's Loop (item 450580, guid 6940959): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940959 AND `id` = 1345113 AND `map` = 0 AND `position_x` BETWEEN -8280.8 AND -8279.8 AND `position_y` BETWEEN -735.1 AND -734.1;
-- Rusty Redridge Rifle (item 521217, guid 6940992): belongs in SecretInquisitorialDungeon
DELETE FROM `gameobject` WHERE `guid` = 6940992 AND `id` = 254548 AND `map` = 0 AND `position_x` BETWEEN -8105.1 AND -8104.1 AND `position_y` BETWEEN -881.6 AND -880.6;
-- Talon Idol (item 521230, guid 6941195): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941195 AND `id` = 97103 AND `map` = 0 AND `position_x` BETWEEN -8966.2 AND -8965.2 AND `position_y` BETWEEN -1195.7 AND -1194.7;
-- Three Corner Coil (item 450574, guid 6941235): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941235 AND `id` = 90262 AND `map` = 0 AND `position_x` BETWEEN -8436.9 AND -8435.9 AND `position_y` BETWEEN -2199.6 AND -2198.6;
-- Tidecaller's Hammer (item 521219, guid 6941250): belongs in Redridge Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941250 AND `id` = 254550 AND `map` = 0 AND `position_x` BETWEEN -8046.5 AND -8045.5 AND `position_y` BETWEEN -1965.3 AND -1964.3;
-- Darnassus
-- Deadman's Signet (item 515510, guid 6941619): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6941619 AND `id` = 515510 AND `map` = 1 AND `position_x` BETWEEN 9924.8 AND 9925.8 AND `position_y` BETWEEN 1909.0 AND 1910.0;
-- Ghoul-Stitched Shoulders (item 410031, guid 6941771): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941771 AND `id` = 735901 AND `map` = 1 AND `position_x` BETWEEN 9710.6 AND 9711.6 AND `position_y` BETWEEN 2251.6 AND 2252.6;
-- Deadwind Pass
-- Arlithrien Moon Orb (item 515430, guid 6940080): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6940080 AND `id` = 515430 AND `map` = 0 AND `position_x` BETWEEN -10976.1 AND -10975.1 AND `position_y` BETWEEN -1966.1 AND -1965.1;
-- Chipped Sentinel Blade (item 521010, guid 6960021): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6960021 AND `id` = 90562 AND `map` = 0 AND `position_x` BETWEEN -10837.5 AND -10836.5 AND `position_y` BETWEEN -2089.8 AND -2088.8;
-- Cracked Earth Vest (item 354505, guid 6940204): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940204 AND `id` = 518345 AND `map` = 0 AND `position_x` BETWEEN -11533.8 AND -11532.8 AND `position_y` BETWEEN -1998.6 AND -1997.6;
-- Dustscour Courier Belt (item 354486, guid 6940391): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6940391 AND `id` = 97132 AND `map` = 0 AND `position_x` BETWEEN -11447.6 AND -11446.6 AND `position_y` BETWEEN -3301.7 AND -3300.7;
-- Forsaken Tome (item 824385, guid 6940502): belongs in SecretInquisitorialDungeon
DELETE FROM `gameobject` WHERE `guid` = 6940502 AND `id` = 520063 AND `map` = 0 AND `position_x` BETWEEN -11177.6 AND -11176.6 AND `position_y` BETWEEN -1857.5 AND -1856.5;
-- Harpy Feather Drape (item 521013, guid 6940593): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6940593 AND `id` = 90565 AND `map` = 0 AND `position_x` BETWEEN -10559.6 AND -10558.6 AND `position_y` BETWEEN -1743.0 AND -1742.0;
-- Lunar Tome (item 515431, guid 6960018): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6960018 AND `id` = 515431 AND `map` = 0 AND `position_x` BETWEEN -11116.7 AND -11115.7 AND `position_y` BETWEEN -2085.9 AND -2084.9;
-- Moonwell Cane (item 521002, guid 6960016): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6960016 AND `id` = 90552 AND `map` = 0 AND `position_x` BETWEEN -11064.7 AND -11063.7 AND `position_y` BETWEEN -2155.4 AND -2154.4;
-- Nightmare's Edge (item 354499, guid 6960032): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6960032 AND `id` = 254562 AND `map` = 0 AND `position_x` BETWEEN -11232.5 AND -11231.5 AND `position_y` BETWEEN -887.1 AND -886.1;
-- Ragescorn Circlet (item 415157, guid 6940107): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940107 AND `id` = 518099 AND `map` = 0 AND `position_x` BETWEEN -11462.3 AND -11461.3 AND `position_y` BETWEEN -3161.1 AND -3160.1;
-- Resonite Band (item 354134, guid 6960029): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6960029 AND `id` = 254230 AND `map` = 0 AND `position_x` BETWEEN -10497.6 AND -10496.6 AND `position_y` BETWEEN -1272.9 AND -1271.9;
-- Saplingweave Handwraps (item 521004, guid 6941003): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941003 AND `id` = 90554 AND `map` = 0 AND `position_x` BETWEEN -10300.8 AND -10299.8 AND `position_y` BETWEEN -1908.5 AND -1907.5;
-- Spark of Infernus (item 415133, guid 6941120): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941120 AND `id` = 518007 AND `map` = 0 AND `position_x` BETWEEN -11216.6 AND -11215.6 AND `position_y` BETWEEN -2655.2 AND -2654.2;
-- Starfall Edge (item 515434, guid 6941143): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941143 AND `id` = 515434 AND `map` = 0 AND `position_x` BETWEEN -10861.8 AND -10860.8 AND `position_y` BETWEEN -1690.5 AND -1689.5;
-- The Rock Binder (item 415132, guid 6941217): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941217 AND `id` = 518000 AND `map` = 0 AND `position_x` BETWEEN -11348.4 AND -11347.4 AND `position_y` BETWEEN -1787.6 AND -1786.6;
-- Timberbane Axe (item 515437, guid 6941254): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941254 AND `id` = 515437 AND `map` = 0 AND `position_x` BETWEEN -10301.0 AND -10300.0 AND `position_y` BETWEEN -2021.2 AND -2020.2;
-- Timberling Dagger (item 515433, guid 6960019): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6960019 AND `id` = 515433 AND `map` = 0 AND `position_x` BETWEEN -11157.4 AND -11156.4 AND `position_y` BETWEEN -2479.7 AND -2478.7;
-- Toe Hammer (item 415136, guid 6940093): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940093 AND `id` = 518011 AND `map` = 0 AND `position_x` BETWEEN -11326.1 AND -11325.1 AND `position_y` BETWEEN -3017.0 AND -3016.0;
-- Whisperwind Heirloom (item 515436, guid 6941336): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941336 AND `id` = 515436 AND `map` = 0 AND `position_x` BETWEEN -11163.3 AND -11162.3 AND `position_y` BETWEEN -2053.4 AND -2052.4;
-- Wildwood Shortbow (item 521026, guid 6941338): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941338 AND `id` = 90557 AND `map` = 0 AND `position_x` BETWEEN -10633.3 AND -10632.3 AND `position_y` BETWEEN -1983.5 AND -1982.5;
-- Woven Ceremonial Belt (item 354137, guid 6960030): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6960030 AND `id` = 254231 AND `map` = 0 AND `position_x` BETWEEN -10370.1 AND -10369.1 AND `position_y` BETWEEN -1251.5 AND -1250.5;
-- Desolace
-- Arctic Imbued Stick (item 450254, guid 6941412): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941412 AND `id` = 95516 AND `map` = 1 AND `position_x` BETWEEN -1901.1 AND -1900.1 AND `position_y` BETWEEN 291.1 AND 292.1;
-- Blade of the Submerged Moon (item 515435, guid 6941447): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941447 AND `id` = 515435 AND `map` = 1 AND `position_x` BETWEEN -2393.6 AND -2392.6 AND `position_y` BETWEEN 378.3 AND 379.3;
-- Bug Catchers (item 515166, guid 6941506): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941506 AND `id` = 96141 AND `map` = 1 AND `position_x` BETWEEN -1195.1 AND -1194.1 AND `position_y` BETWEEN 3147.0 AND 3148.0;
-- Champion's Band (item 521092, guid 6941552): belongs in Kalimdor
DELETE FROM `gameobject` WHERE `guid` = 6941552 AND `id` = 517370 AND `map` = 1 AND `position_x` BETWEEN -1273.6 AND -1272.6 AND `position_y` BETWEEN 3251.7 AND 3252.7;
-- Felforged Meteor Fragment (item 451046, guid 6941729): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6941729 AND `id` = 90376 AND `map` = 1 AND `position_x` BETWEEN -967.4 AND -966.4 AND `position_y` BETWEEN 1185.7 AND 1186.7;
-- Icon of Khan Maraudos (item 354206, guid 6941855): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6941855 AND `id` = 254307 AND `map` = 1 AND `position_x` BETWEEN -1354.2 AND -1353.2 AND `position_y` BETWEEN 3089.9 AND 3090.9;
-- Logsplitter (item 450692, guid 6941917): belongs in campnarachestart
DELETE FROM `gameobject` WHERE `guid` = 6941917 AND `id` = 95648 AND `map` = 1 AND `position_x` BETWEEN -1195.7 AND -1194.7 AND `position_y` BETWEEN 3248.5 AND 3249.5;
-- Long-Clawed Gnoll Paw (item 515168, guid 6941922): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941922 AND `id` = 96143 AND `map` = 1 AND `position_x` BETWEEN -1286.8 AND -1285.8 AND `position_y` BETWEEN 3248.5 AND 3249.5;
-- Moon-Infused Breeches (item 515183, guid 6941962): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941962 AND `id` = 96120 AND `map` = 1 AND `position_x` BETWEEN -1266.4 AND -1265.4 AND `position_y` BETWEEN 3116.4 AND 3117.4;
-- Orb of Isildien Echoes (item 515173, guid 6942011): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6942011 AND `id` = 96110 AND `map` = 1 AND `position_x` BETWEEN -1262.8 AND -1261.8 AND `position_y` BETWEEN 3245.8 AND 3246.8;
-- Pauldrons of Shadow (item 354460, guid 6942023): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6942023 AND `id` = 254516 AND `map` = 1 AND `position_x` BETWEEN -1829.5 AND -1828.5 AND `position_y` BETWEEN -162.5 AND -161.5;
-- Pristine Tortoise Carapace (item 4050653, guid 6942043): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6942043 AND `id` = 90375 AND `map` = 1 AND `position_x` BETWEEN -1236.3 AND -1235.3 AND `position_y` BETWEEN 1313.1 AND 1314.1;
-- Ravasaur Talon (item 515399, guid 6942062): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6942062 AND `id` = 96215 AND `map` = 1 AND `position_x` BETWEEN -2471.9 AND -2470.9 AND `position_y` BETWEEN 398.6 AND 399.6;
-- Resilient Stompers (item 410134, guid 6942078): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942078 AND `id` = 90486 AND `map` = 1 AND `position_x` BETWEEN 41.9 AND 42.9 AND `position_y` BETWEEN 138.0 AND 139.0;
-- Revantusk Hide Steppers (item 515718, guid 6941827): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941827 AND `id` = 95795 AND `map` = 1 AND `position_x` BETWEEN -704.0 AND -703.0 AND `position_y` BETWEEN 577.6 AND 578.6;
-- Shen'dralar Slicer (item 515182, guid 6942166): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6942166 AND `id` = 515880 AND `map` = 1 AND `position_x` BETWEEN -1236.1 AND -1235.1 AND `position_y` BETWEEN 3150.6 AND 3151.6;
-- Spitelash Warbanner (item 515629, guid 6942400): belongs in Azshara
DELETE FROM `gameobject` WHERE `guid` = 6942400 AND `id` = 254463 AND `map` = 1 AND `position_x` BETWEEN -1196.9 AND -1195.9 AND `position_y` BETWEEN 2708.7 AND 2709.7;
-- Strider Waist Piece (item 515187, guid 6942255): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6942255 AND `id` = 96125 AND `map` = 1 AND `position_x` BETWEEN -1204.9 AND -1203.9 AND `position_y` BETWEEN 3195.1 AND 3196.1;
-- Timbermaw Girdle (item 515337, guid 6942334): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6942334 AND `id` = 517274 AND `map` = 1 AND `position_x` BETWEEN -2529.2 AND -2528.2 AND `position_y` BETWEEN 910.4 AND 911.4;
-- Whisperwind Boots (item 515432, guid 6942417): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6942417 AND `id` = 515432 AND `map` = 1 AND `position_x` BETWEEN -2421.8 AND -2420.8 AND `position_y` BETWEEN 369.1 AND 370.1;
-- Zapping Rod (item 515185, guid 6942454): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6942454 AND `id` = 515878 AND `map` = 1 AND `position_x` BETWEEN -1198.0 AND -1197.0 AND `position_y` BETWEEN 3285.4 AND 3286.4;
-- Dun Morogh
-- Apothecary Cowl (item 410036, guid 6940060): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940060 AND `id` = 96246 AND `map` = 0 AND `position_x` BETWEEN -5564.1 AND -5563.1 AND `position_y` BETWEEN -374.6 AND -373.6;
-- Blightbloom Talisman (item 278848, guid 6940137): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940137 AND `id` = 340042 AND `map` = 0 AND `position_x` BETWEEN -5536.8 AND -5535.8 AND `position_y` BETWEEN -236.6 AND -235.6;
-- Burning Blade Ring (item 450508, guid 6940206): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940206 AND `id` = 90297 AND `map` = 0 AND `position_x` BETWEEN -5154.3 AND -5153.3 AND `position_y` BETWEEN 1084.1 AND 1085.1;
-- Charblaze Rifle (item 410199, guid 6940236): belongs in Burning Steppes
DELETE FROM `gameobject` WHERE `guid` = 6940236 AND `id` = 686909 AND `map` = 0 AND `position_x` BETWEEN -5319.7 AND -5318.7 AND `position_y` BETWEEN -381.3 AND -380.3;
-- Charred Slicer (item 410027, guid 6940241): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940241 AND `id` = 340120 AND `map` = 0 AND `position_x` BETWEEN -5466.6 AND -5465.6 AND `position_y` BETWEEN -245.4 AND -244.4;
-- Ebonblight Slippers (item 410020, guid 6940413): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940413 AND `id` = 340123 AND `map` = 0 AND `position_x` BETWEEN -5523.9 AND -5522.9 AND `position_y` BETWEEN -199.6 AND -198.6;
-- Ghoul-Stitched Shoulders (item 410031, guid 6940535): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940535 AND `id` = 735901 AND `map` = 0 AND `position_x` BETWEEN -5524.0 AND -5523.0 AND `position_y` BETWEEN -122.8 AND -121.8;
-- Infantry Gauntlets (item 278852, guid 6940649): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940649 AND `id` = 341060 AND `map` = 0 AND `position_x` BETWEEN -5577.1 AND -5576.1 AND `position_y` BETWEEN -312.5 AND -311.5;
-- People's Militia Badge (item 450561, guid 6940880): belongs in jangolodemine
DELETE FROM `gameobject` WHERE `guid` = 6940880 AND `id` = 90250 AND `map` = 0 AND `position_x` BETWEEN -5868.8 AND -5867.8 AND `position_y` BETWEEN 560.8 AND 561.8;
-- Phylactery Shard (item 410010, guid 6940883): belongs in Duskwood
DELETE FROM `gameobject` WHERE `guid` = 6940883 AND `id` = 340112 AND `map` = 0 AND `position_x` BETWEEN -5490.7 AND -5489.7 AND `position_y` BETWEEN -201.4 AND -200.4;
-- Reliever's Burden (item 278845, guid 6940948): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940948 AND `id` = 340111 AND `map` = 0 AND `position_x` BETWEEN -5548.7 AND -5547.7 AND `position_y` BETWEEN -212.0 AND -211.0;
-- Scarlet Pauldrons (item 410026, guid 6941018): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941018 AND `id` = 96243 AND `map` = 0 AND `position_x` BETWEEN -5463.8 AND -5462.8 AND `position_y` BETWEEN -196.6 AND -195.6;
-- Scarlet Slicer (item 410014, guid 6941023): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941023 AND `id` = 340061 AND `map` = 0 AND `position_x` BETWEEN -5437.8 AND -5436.8 AND `position_y` BETWEEN -236.5 AND -235.5;
-- Skeletal Club (item 278851, guid 6941089): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941089 AND `id` = 340098 AND `map` = 0 AND `position_x` BETWEEN -5562.4 AND -5561.4 AND `position_y` BETWEEN -298.5 AND -297.5;
-- Durotar
-- Apothecary's Lantern (item 515015, guid 6941407): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6941407 AND `id` = 1345003 AND `map` = 1 AND `position_x` BETWEEN 338.7 AND 339.7 AND `position_y` BETWEEN -4689.5 AND -4688.5;
-- Bone Splitter (item 354176, guid 6941473): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6941473 AND `id` = 254276 AND `map` = 1 AND `position_x` BETWEEN -230.1 AND -229.1 AND `position_y` BETWEEN -4652.0 AND -4651.0;
-- Boom-Bling Choker (item 515355, guid 6941476): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941476 AND `id` = 96167 AND `map` = 1 AND `position_x` BETWEEN -763.1 AND -762.1 AND `position_y` BETWEEN -4573.8 AND -4572.8;
-- Boom-Bling Choker (item 515355, guid 6941477): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941477 AND `id` = 96167 AND `map` = 1 AND `position_x` BETWEEN 1405.7 AND 1406.7 AND `position_y` BETWEEN -2278.5 AND -2277.5;
-- Bracers of the Bound Storm (item 410072, guid 6941481): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941481 AND `id` = 96232 AND `map` = 1 AND `position_x` BETWEEN -74.1 AND -73.1 AND `position_y` BETWEEN -4272.2 AND -4271.2;
-- Brackish Spellweave Robe (item 515237, guid 6941483): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941483 AND `id` = 1345018 AND `map` = 1 AND `position_x` BETWEEN 915.2 AND 916.2 AND `position_y` BETWEEN -4782.7 AND -4781.7;
-- Carapace Clasps (item 410069, guid 6941527): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941527 AND `id` = 518464 AND `map` = 1 AND `position_x` BETWEEN -260.1 AND -259.1 AND `position_y` BETWEEN -4298.5 AND -4297.5;
-- Caravan Guard Pauldrons (item 354174, guid 6941533): belongs in dustwindcave
DELETE FROM `gameobject` WHERE `guid` = 6941533 AND `id` = 254274 AND `map` = 1 AND `position_x` BETWEEN -381.3 AND -380.3 AND `position_y` BETWEEN -5191.4 AND -5190.4;
-- Caravaneer's Machete (item 515401, guid 6941538): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941538 AND `id` = 95926 AND `map` = 1 AND `position_x` BETWEEN -438.7 AND -437.7 AND `position_y` BETWEEN -4437.0 AND -4436.0;
-- Charred Battlegreaves (item 521083, guid 6941554): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941554 AND `id` = 90599 AND `map` = 1 AND `position_x` BETWEEN -1428.3 AND -1427.3 AND `position_y` BETWEEN -3356.4 AND -3355.4;
-- Chitin Thread Wraps (item 410060, guid 6941562): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941562 AND `id` = 686883 AND `map` = 1 AND `position_x` BETWEEN -107.1 AND -106.1 AND `position_y` BETWEEN -4352.3 AND -4351.3;
-- Cindersguard Saber (item 515381, guid 6941567): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941567 AND `id` = 95936 AND `map` = 1 AND `position_x` BETWEEN -506.5 AND -505.5 AND `position_y` BETWEEN -4316.5 AND -4315.5;
-- Claw of Vagash (item 450256, guid 6941571): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941571 AND `id` = 95518 AND `map` = 1 AND `position_x` BETWEEN -1482.3 AND -1481.3 AND `position_y` BETWEEN -3729.2 AND -3728.2;
-- Crokolisk Hunter (item 515233, guid 6941589): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6941589 AND `id` = 96151 AND `map` = 1 AND `position_x` BETWEEN 911.9 AND 912.9 AND `position_y` BETWEEN -4711.2 AND -4710.2;
-- Darnell's Blade (item 410051, guid 6941614): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941614 AND `id` = 638836 AND `map` = 1 AND `position_x` BETWEEN -210.9 AND -209.9 AND `position_y` BETWEEN -4318.7 AND -4317.7;
-- Deserter's Last Resort (item 515216, guid 6941630): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941630 AND `id` = 1345038 AND `map` = 1 AND `position_x` BETWEEN 870.0 AND 871.0 AND `position_y` BETWEEN -4708.0 AND -4707.0;
-- Dinosaur Tranquilizer (item 515354, guid 6941636): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6941636 AND `id` = 96168 AND `map` = 1 AND `position_x` BETWEEN -756.8 AND -755.8 AND `position_y` BETWEEN -4591.9 AND -4590.9;
-- Dive's Instruction Manual (item 515737, guid 6941643): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941643 AND `id` = 96152 AND `map` = 1 AND `position_x` BETWEEN 836.7 AND 837.7 AND `position_y` BETWEEN -4755.0 AND -4754.0;
-- Dustsworn Sash (item 410039, guid 6941667): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941667 AND `id` = 686869 AND `map` = 1 AND `position_x` BETWEEN -92.2 AND -91.2 AND `position_y` BETWEEN -4517.2 AND -4516.2;
-- Ember Crown (item 515384, guid 6941687): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941687 AND `id` = 95933 AND `map` = 1 AND `position_x` BETWEEN -452.7 AND -451.7 AND `position_y` BETWEEN -4317.8 AND -4316.8;
-- Embercarve Greataxe (item 410225, guid 6941689): belongs in blackrockmountain
DELETE FROM `gameobject` WHERE `guid` = 6941689 AND `id` = 254658 AND `map` = 1 AND `position_x` BETWEEN -201.2 AND -200.2 AND `position_y` BETWEEN -4395.0 AND -4394.0;
-- Emberstring Drakebow (item 515219, guid 6941694): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941694 AND `id` = 515921 AND `map` = 1 AND `position_x` BETWEEN 859.3 AND 860.3 AND `position_y` BETWEEN -4722.6 AND -4721.6;
-- Embrace of the Fifth (item 354214, guid 6941695): belongs in Alterac Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941695 AND `id` = 254318 AND `map` = 1 AND `position_x` BETWEEN -948.6 AND -947.6 AND `position_y` BETWEEN -3700.9 AND -3699.9;
-- Farm Hands (item 450713, guid 6941722): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941722 AND `id` = 95638 AND `map` = 1 AND `position_x` BETWEEN 530.7 AND 531.7 AND `position_y` BETWEEN -2241.9 AND -2240.9;
-- Ghost Buster (item 410160, guid 6941769): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941769 AND `id` = 93000 AND `map` = 1 AND `position_x` BETWEEN -694.1 AND -693.1 AND `position_y` BETWEEN -4645.9 AND -4644.9;
-- Infested Pauldrons (item 410045, guid 6941867): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941867 AND `id` = 686871 AND `map` = 1 AND `position_x` BETWEEN -50.3 AND -49.3 AND `position_y` BETWEEN -4415.9 AND -4414.9;
-- Junior Mallet (item 410162, guid 6941888): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941888 AND `id` = 96233 AND `map` = 1 AND `position_x` BETWEEN 690.1 AND 691.1 AND `position_y` BETWEEN -2319.9 AND -2318.9;
-- Last Guardian (item 415089, guid 6941900): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941900 AND `id` = 254346 AND `map` = 1 AND `position_x` BETWEEN 940.3 AND 941.3 AND `position_y` BETWEEN -4776.5 AND -4775.5;
-- Lid of the Dead (item 515770, guid 6942261): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6942261 AND `id` = 515770 AND `map` = 1 AND `position_x` BETWEEN 896.7 AND 897.7 AND `position_y` BETWEEN -4787.6 AND -4786.6;
-- Lost Fighter's Crossbow (item 515366, guid 6941927): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6941927 AND `id` = 96179 AND `map` = 1 AND `position_x` BETWEEN -128.0 AND -127.0 AND `position_y` BETWEEN -4260.3 AND -4259.3;
-- Mudcrush Shoulders (item 515214, guid 6941975): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941975 AND `id` = 518153 AND `map` = 1 AND `position_x` BETWEEN 904.6 AND 905.6 AND `position_y` BETWEEN -4714.1 AND -4713.1;
-- One Ring to Flame Them All (item 515383, guid 6942006): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942006 AND `id` = 95934 AND `map` = 1 AND `position_x` BETWEEN -425.0 AND -424.0 AND `position_y` BETWEEN -4299.9 AND -4298.9;
-- Premium Banana (item 415054, guid 6942040): belongs in Azshara
DELETE FROM `gameobject` WHERE `guid` = 6942040 AND `id` = 95715 AND `map` = 1 AND `position_x` BETWEEN 1329.6 AND 1330.6 AND `position_y` BETWEEN -4562.6 AND -4561.6;
-- Retired Hero's Helm (item 515374, guid 6942082): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942082 AND `id` = 96218 AND `map` = 1 AND `position_x` BETWEEN -827.9 AND -826.9 AND `position_y` BETWEEN -4319.1 AND -4318.1;
-- Rockstalker Silk Robe (item 410064, guid 6942097): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6942097 AND `id` = 356434 AND `map` = 1 AND `position_x` BETWEEN -278.3 AND -277.3 AND `position_y` BETWEEN -4283.0 AND -4282.0;
-- Sailor's Cuffs (item 450718, guid 6942112): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942112 AND `id` = 95637 AND `map` = 1 AND `position_x` BETWEEN -1428.3 AND -1427.3 AND `position_y` BETWEEN -3660.3 AND -3659.3;
-- Salt Scoured Boarding Axe (item 515231, guid 6942117): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6942117 AND `id` = 515946 AND `map` = 1 AND `position_x` BETWEEN 891.9 AND 892.9 AND `position_y` BETWEEN -4774.5 AND -4773.5;
-- Sandstorm Shaper (item 410074, guid 6942130): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6942130 AND `id` = 686888 AND `map` = 1 AND `position_x` BETWEEN -79.5 AND -78.5 AND `position_y` BETWEEN -4246.7 AND -4245.7;
-- Scalebane Pendant (item 515222, guid 6941691): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941691 AND `id` = 515923 AND `map` = 1 AND `position_x` BETWEEN 840.4 AND 841.4 AND `position_y` BETWEEN -4769.3 AND -4768.3;
-- Shoulderpads of the Conjuror (item 354160, guid 6942175): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942175 AND `id` = 254260 AND `map` = 1 AND `position_x` BETWEEN 1176.4 AND 1177.4 AND `position_y` BETWEEN -4956.6 AND -4955.6;
-- Silithid Ritual Robe (item 515398, guid 6942181): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6942181 AND `id` = 96220 AND `map` = 1 AND `position_x` BETWEEN -671.5 AND -670.5 AND `position_y` BETWEEN -4240.5 AND -4239.5;
-- Silverback Cape (item 515363, guid 6942185): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942185 AND `id` = 96170 AND `map` = 1 AND `position_x` BETWEEN 374.7 AND 375.7 AND `position_y` BETWEEN -4041.3 AND -4040.3;
-- Skull Ring (item 450740, guid 6942194): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942194 AND `id` = 95645 AND `map` = 1 AND `position_x` BETWEEN 733.4 AND 734.4 AND `position_y` BETWEEN -2444.5 AND -2443.5;
-- Standard Cenarion Spear (item 410047, guid 6942236): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6942236 AND `id` = 356436 AND `map` = 1 AND `position_x` BETWEEN -126.9 AND -125.9 AND `position_y` BETWEEN -4374.7 AND -4373.7;
-- Stormwitch Staff (item 450803, guid 6942251): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942251 AND `id` = 95623 AND `map` = 1 AND `position_x` BETWEEN 260.5 AND 261.5 AND `position_y` BETWEEN -2545.8 AND -2544.8;
-- Sturdy Fishing Pole (item 450988, guid 6942263): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942263 AND `id` = 95631 AND `map` = 1 AND `position_x` BETWEEN 125.4 AND 126.4 AND `position_y` BETWEEN -3457.7 AND -3456.7;
-- Swamplight Concoction (item 515239, guid 6942277): belongs in skullrock
DELETE FROM `gameobject` WHERE `guid` = 6942277 AND `id` = 518139 AND `map` = 1 AND `position_x` BETWEEN 925.9 AND 926.9 AND `position_y` BETWEEN -4766.4 AND -4765.4;
-- Thawed Boots (item 450686, guid 6942297): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6942297 AND `id` = 95654 AND `map` = 1 AND `position_x` BETWEEN -1428.3 AND -1427.3 AND `position_y` BETWEEN -3153.7 AND -3152.7;
-- The Eternal's Journal (item 410041, guid 6942301): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6942301 AND `id` = 518166 AND `map` = 1 AND `position_x` BETWEEN -140.8 AND -139.8 AND `position_y` BETWEEN -4382.3 AND -4381.3;
-- Throwing Rock (item 450744, guid 6942316): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6942316 AND `id` = 95677 AND `map` = 1 AND `position_x` BETWEEN -955.4 AND -954.4 AND `position_y` BETWEEN -5889.4 AND -5888.4;
-- Tongs of Miscalibration (item 515364, guid 6942342): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942342 AND `id` = 96178 AND `map` = 1 AND `position_x` BETWEEN 470.6 AND 471.6 AND `position_y` BETWEEN -4206.5 AND -4205.5;
-- Warcaster Slippers (item 354485, guid 6942402): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6942402 AND `id` = 97134 AND `map` = 1 AND `position_x` BETWEEN -1058.9 AND -1057.9 AND `position_y` BETWEEN -3832.9 AND -3831.9;
-- Wrangler's Cord (item 515371, guid 6942447): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942447 AND `id` = 96174 AND `map` = 1 AND `position_x` BETWEEN -663.1 AND -662.1 AND `position_y` BETWEEN -4087.0 AND -4086.0;
-- Duskwood
-- Bracers of Emerald Will (item 354252, guid 6940174): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6940174 AND `id` = 254387 AND `map` = 0 AND `position_x` BETWEEN -11290.2 AND -11289.2 AND `position_y` BETWEEN 146.3 AND 147.3;
-- Charred Spaulders (item 521223, guid 6960010): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6960010 AND `id` = 97108 AND `map` = 0 AND `position_x` BETWEEN -9809.4 AND -9808.4 AND `position_y` BETWEEN -464.3 AND -463.3;
-- Crocolisk Hunter's Bow (item 354501, guid 6940275): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6940275 AND `id` = 254564 AND `map` = 0 AND `position_x` BETWEEN -10049.3 AND -10048.3 AND `position_y` BETWEEN 514.3 AND 515.3;
-- Deadman's Signet (item 515510, guid 6960036): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6960036 AND `id` = 515510 AND `map` = 0 AND `position_x` BETWEEN -10281.4 AND -10280.4 AND `position_y` BETWEEN 74.3 AND 75.3;
-- Engine Safety Belt (item 354482, guid 6940441): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6940441 AND `id` = 97135 AND `map` = 0 AND `position_x` BETWEEN -11196.9 AND -11195.9 AND `position_y` BETWEEN 216.3 AND 217.3;
-- Frostmane Axe (item 450252, guid 6940510): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6940510 AND `id` = 95514 AND `map` = 0 AND `position_x` BETWEEN -10753.2 AND -10752.2 AND `position_y` BETWEEN 310.2 AND 311.2;
-- Kreil's Gauntlets (item 354230, guid 6940685): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6940685 AND `id` = 254365 AND `map` = 0 AND `position_x` BETWEEN -9848.5 AND -9847.5 AND `position_y` BETWEEN 735.4 AND 736.4;
-- Lifesap Blade (item 515438, guid 6960028): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6960028 AND `id` = 515438 AND `map` = 0 AND `position_x` BETWEEN -11224.9 AND -11223.9 AND `position_y` BETWEEN -180.6 AND -179.6;
-- Murloc Crown (item 354259, guid 6940785): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6940785 AND `id` = 254394 AND `map` = 0 AND `position_x` BETWEEN -10038.4 AND -10037.4 AND `position_y` BETWEEN -164.2 AND -163.2;
-- Nightmare's Edge (item 354499, guid 6940808): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6940808 AND `id` = 254562 AND `map` = 0 AND `position_x` BETWEEN -10730.3 AND -10729.3 AND `position_y` BETWEEN -98.6 AND -97.6;
-- Sorrow's Light (item 354231, guid 6941115): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6941115 AND `id` = 254366 AND `map` = 0 AND `position_x` BETWEEN -10485.2 AND -10484.2 AND `position_y` BETWEEN 398.7 AND 399.7;
-- Spear of Emerald (item 354234, guid 6960027): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6960027 AND `id` = 254369 AND `map` = 0 AND `position_x` BETWEEN -10385.8 AND -10384.8 AND `position_y` BETWEEN -432.7 AND -431.7;
-- Tahonda Gauntlets (item 515528, guid 6941193): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941193 AND `id` = 515528 AND `map` = 0 AND `position_x` BETWEEN -11465.0 AND -11464.0 AND `position_y` BETWEEN 257.2 AND 258.2;
-- Timbermaw Defender (item 515336, guid 6941257): belongs in Stranglethorn Vale
DELETE FROM `gameobject` WHERE `guid` = 6941257 AND `id` = 517273 AND `map` = 0 AND `position_x` BETWEEN -9948.6 AND -9947.6 AND `position_y` BETWEEN 623.1 AND 624.1;
-- Dustwallow Marsh
-- Caravan Guard Pauldrons (item 354174, guid 6941531): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6941531 AND `id` = 254274 AND `map` = 1 AND `position_x` BETWEEN -2435.9 AND -2434.9 AND `position_y` BETWEEN -5396.6 AND -5395.6;
-- Dark Iron Vest (item 450685, guid 6941607): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941607 AND `id` = 95653 AND `map` = 1 AND `position_x` BETWEEN -2509.1 AND -2508.1 AND `position_y` BETWEEN -5180.1 AND -5179.1;
-- Dustrunner Bindings (item 450705, guid 6941663): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941663 AND `id` = 95652 AND `map` = 1 AND `position_x` BETWEEN -3917.9 AND -3916.9 AND `position_y` BETWEEN -3043.9 AND -3042.9;
-- Earthshatterer Gavel (item 521089, guid 6941671): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941671 AND `id` = 254633 AND `map` = 1 AND `position_x` BETWEEN -3249.4 AND -3248.4 AND `position_y` BETWEEN -3543.8 AND -3542.8;
-- Lost Scout's Idol (item 278850, guid 6941931): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941931 AND `id` = 340099 AND `map` = 1 AND `position_x` BETWEEN -3206.7 AND -3205.7 AND `position_y` BETWEEN -4401.8 AND -4400.8;
-- Raptorscale Cloak (item 450697, guid 6942058): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942058 AND `id` = 95628 AND `map` = 1 AND `position_x` BETWEEN -3387.2 AND -3386.2 AND `position_y` BETWEEN -3964.3 AND -3963.3;
-- Eastern Plaguelands
-- Aloof Tauren's Herbs (item 354475, guid 6940033): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6940033 AND `id` = 254521 AND `map` = 0 AND `position_x` BETWEEN 1929.4 AND 1930.4 AND `position_y` BETWEEN -4182.1 AND -4181.1;
-- Ancestor's Axe (item 450506, guid 6940040): belongs in deathknellstart
DELETE FROM `gameobject` WHERE `guid` = 6940040 AND `id` = 90220 AND `map` = 0 AND `position_x` BETWEEN 1902.5 AND 1903.5 AND `position_y` BETWEEN -5109.2 AND -5108.2;
-- Apprentice Staff (item 450983, guid 6940066): belongs in deathknellstart
DELETE FROM `gameobject` WHERE `guid` = 6940066 AND `id` = 95670 AND `map` = 0 AND `position_x` BETWEEN 2843.3 AND 2844.3 AND `position_y` BETWEEN -5149.5 AND -5148.5;
-- Brambleblade (item 450612, guid 6940178): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940178 AND `id` = 90336 AND `map` = 0 AND `position_x` BETWEEN 2493.9 AND 2494.9 AND `position_y` BETWEEN -5592.9 AND -5591.9;
-- Cord of Reverence (item 354474, guid 6940268): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6940268 AND `id` = 254522 AND `map` = 0 AND `position_x` BETWEEN 2614.9 AND 2615.9 AND `position_y` BETWEEN -5431.7 AND -5430.7;
-- Moonwell Cane (item 521002, guid 6940766): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6940766 AND `id` = 90552 AND `map` = 0 AND `position_x` BETWEEN 1699.5 AND 1700.5 AND `position_y` BETWEEN -2297.6 AND -2296.6;
-- Stolen Tauren Cloak (item 450505, guid 6941154): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941154 AND `id` = 90219 AND `map` = 0 AND `position_x` BETWEEN 2305.7 AND 2306.7 AND `position_y` BETWEEN -5310.7 AND -5309.7;
-- Sun Touched Club (item 824388, guid 6941175): belongs in campnarachestart
DELETE FROM `gameobject` WHERE `guid` = 6941175 AND `id` = 520700 AND `map` = 0 AND `position_x` BETWEEN 1499.3 AND 1500.3 AND `position_y` BETWEEN -5592.9 AND -5591.9;
-- Traitor's Last Kiss (item 824387, guid 6941270): belongs in campnarachestart
DELETE FROM `gameobject` WHERE `guid` = 6941270 AND `id` = 520701 AND `map` = 0 AND `position_x` BETWEEN 1929.4 AND 1930.4 AND `position_y` BETWEEN -4948.0 AND -4947.0;
-- Elwynn Forest
-- Deepmoss Fang (item 521227, guid 6940333): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940333 AND `id` = 1345036 AND `map` = 0 AND `position_x` BETWEEN -9175.2 AND -9174.2 AND `position_y` BETWEEN -598.0 AND -597.0;
-- Misplaced Pitchfork (item 515005, guid 6940755): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6940755 AND `id` = 515224 AND `map` = 0 AND `position_x` BETWEEN -9876.7 AND -9875.7 AND `position_y` BETWEEN 1439.8 AND 1440.8;
-- Venture Co. Logging Axe (item 354130, guid 6941294): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941294 AND `id` = 254225 AND `map` = 0 AND `position_x` BETWEEN -9274.9 AND -9273.9 AND `position_y` BETWEEN -697.8 AND -696.8;
-- Windsong Shortbow (item 521228, guid 6941344): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941344 AND `id` = 97104 AND `map` = 0 AND `position_x` BETWEEN -9651.7 AND -9650.7 AND `position_y` BETWEEN 499.8 AND 500.8;
-- Ziz's Alchemy Goggles (item 354131, guid 6941368): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941368 AND `id` = 254229 AND `map` = 0 AND `position_x` BETWEEN -9475.3 AND -9474.3 AND `position_y` BETWEEN -19.5 AND -18.5;
-- Eversong Woods
-- Fallow Tunic (item 354229, guid 6942463): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6942463 AND `id` = 254364 AND `map` = 530 AND `position_x` BETWEEN 10586.4 AND 10587.4 AND `position_y` BETWEEN -6360.8 AND -6359.8;
-- Fire Poker (item 450671, guid 6942464): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6942464 AND `id` = 95605 AND `map` = 530 AND `position_x` BETWEEN 9610.8 AND 9611.8 AND `position_y` BETWEEN -7687.3 AND -7686.3;
-- Flame Infused Offering Band (item 415044, guid 6942465): belongs in Arathi Highlands
DELETE FROM `gameobject` WHERE `guid` = 6942465 AND `id` = 95879 AND `map` = 530 AND `position_x` BETWEEN 10016.9 AND 10017.9 AND `position_y` BETWEEN -5766.0 AND -5765.0;
-- Frostwalker Boots (item 450238, guid 6942466): belongs in Arathi Highlands
DELETE FROM `gameobject` WHERE `guid` = 6942466 AND `id` = 95500 AND `map` = 530 AND `position_x` BETWEEN 9082.2 AND 9083.2 AND `position_y` BETWEEN -6470.8 AND -6469.8;
-- Marsh Adventurer Boots (item 354261, guid 6942469): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6942469 AND `id` = 254396 AND `map` = 530 AND `position_x` BETWEEN 10411.4 AND 10412.4 AND `position_y` BETWEEN -6148.2 AND -6147.2;
-- Murloc Crown (item 354259, guid 6942471): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6942471 AND `id` = 254394 AND `map` = 530 AND `position_x` BETWEEN 10541.1 AND 10542.1 AND `position_y` BETWEEN -6837.8 AND -6836.8;
-- Nightmare's Edge (item 354499, guid 6942472): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6942472 AND `id` = 254562 AND `map` = 530 AND `position_x` BETWEEN 10224.8 AND 10225.8 AND `position_y` BETWEEN -6807.8 AND -6806.8;
-- Robe of Woven Dreams (item 354263, guid 6942474): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6942474 AND `id` = 254398 AND `map` = 530 AND `position_x` BETWEEN 10555.5 AND 10556.5 AND `position_y` BETWEEN -6615.8 AND -6614.8;
-- Rocket Shrapnel (item 824397, guid 6942475): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6942475 AND `id` = 520703 AND `map` = 530 AND `position_x` BETWEEN 9336.0 AND 9337.0 AND `position_y` BETWEEN -6278.7 AND -6277.7;
-- The Wanderer's Stirring Rod (item 354266, guid 6942480): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6942480 AND `id` = 254401 AND `map` = 530 AND `position_x` BETWEEN 10811.6 AND 10812.6 AND `position_y` BETWEEN -6522.1 AND -6521.1;
-- Felwood
-- Agamand Sharpshooter (item 521029, guid 6941388): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941388 AND `id` = 517351 AND `map` = 1 AND `position_x` BETWEEN 3518.6 AND 3519.6 AND `position_y` BETWEEN -952.9 AND -951.9;
-- Agamand Walking Stick (item 515032, guid 6941389): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941389 AND `id` = 515392 AND `map` = 1 AND `position_x` BETWEEN 3654.6 AND 3655.6 AND `position_y` BETWEEN -1338.0 AND -1337.0;
-- Anchorfoot Greaves (item 515692, guid 6941397): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941397 AND `id` = 95885 AND `map` = 1 AND `position_x` BETWEEN 6367.4 AND 6368.4 AND `position_y` BETWEEN 975.8 AND 976.8;
-- Ancient Vilebranch Gloves (item 354510, guid 6941405): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941405 AND `id` = 254573 AND `map` = 1 AND `position_x` BETWEEN 5887.0 AND 5888.0 AND `position_y` BETWEEN -792.4 AND -791.4;
-- Blade of Thunder (item 354164, guid 6941446): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6941446 AND `id` = 254264 AND `map` = 1 AND `position_x` BETWEEN 5829.0 AND 5830.0 AND `position_y` BETWEEN -2276.1 AND -2275.1;
-- Blood Drinker (item 515730, guid 6941454): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941454 AND `id` = 95912 AND `map` = 1 AND `position_x` BETWEEN 4679.9 AND 4680.9 AND `position_y` BETWEEN -1223.4 AND -1222.4;
-- Blood Keeper's Staff (item 515708, guid 6941455): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941455 AND `id` = 95901 AND `map` = 1 AND `position_x` BETWEEN 5356.4 AND 5357.4 AND `position_y` BETWEEN -263.3 AND -262.3;
-- Bloodthread Leggings (item 515721, guid 6941464): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941464 AND `id` = 95798 AND `map` = 1 AND `position_x` BETWEEN 5711.9 AND 5712.9 AND `position_y` BETWEEN -1195.8 AND -1194.8;
-- Brood Caller's Raiment (item 515699, guid 6941500): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941500 AND `id` = 95892 AND `map` = 1 AND `position_x` BETWEEN 5406.6 AND 5407.6 AND `position_y` BETWEEN 844.8 AND 845.8;
-- Broodsilk Gloves (item 515700, guid 6941501): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941501 AND `id` = 95893 AND `map` = 1 AND `position_x` BETWEEN 5450.3 AND 5451.3 AND `position_y` BETWEEN 320.9 AND 321.9;
-- Cenarion Dreamcatcher (item 515356, guid 6941545): belongs in Winterspring
DELETE FROM `gameobject` WHERE `guid` = 6941545 AND `id` = 96169 AND `map` = 1 AND `position_x` BETWEEN 4095.1 AND 4096.1 AND `position_y` BETWEEN -145.6 AND -144.6;
-- Drowned Link Belt (item 515704, guid 6941653): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941653 AND `id` = 95897 AND `map` = 1 AND `position_x` BETWEEN 6760.4 AND 6761.4 AND `position_y` BETWEEN -203.0 AND -202.0;
-- Dwarven Drinking Pants (item 515691, guid 6941670): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941670 AND `id` = 95884 AND `map` = 1 AND `position_x` BETWEEN 6192.7 AND 6193.7 AND `position_y` BETWEEN 1172.3 AND 1173.3;
-- Elder Highpeak's Keepsake (item 515706, guid 6941678): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941678 AND `id` = 95899 AND `map` = 1 AND `position_x` BETWEEN 6211.0 AND 6212.0 AND `position_y` BETWEEN -327.5 AND -326.5;
-- Expedition Bracers (item 515407, guid 6941713): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941713 AND `id` = 96211 AND `map` = 1 AND `position_x` BETWEEN 3364.9 AND 3365.9 AND `position_y` BETWEEN -491.6 AND -490.6;
-- Fort Defender Band (item 515713, guid 6941749): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941749 AND `id` = 95790 AND `map` = 1 AND `position_x` BETWEEN 6398.8 AND 6399.8 AND `position_y` BETWEEN -1408.0 AND -1407.0;
-- Garren's Pitchfork (item 451096, guid 6941764): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941764 AND `id` = 95698 AND `map` = 1 AND `position_x` BETWEEN 3391.0 AND 3392.0 AND `position_y` BETWEEN -1650.0 AND -1649.0;
-- Hexcall Gavel (item 515707, guid 6941821): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941821 AND `id` = 95900 AND `map` = 1 AND `position_x` BETWEEN 6018.0 AND 6019.0 AND `position_y` BETWEEN -334.0 AND -333.0;
-- Hexweave Robes (item 515697, guid 6941824): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941824 AND `id` = 95890 AND `map` = 1 AND `position_x` BETWEEN 5455.5 AND 5456.5 AND `position_y` BETWEEN 1310.5 AND 1311.5;
-- Highnest Repeater (item 515729, guid 6941834): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941834 AND `id` = 95911 AND `map` = 1 AND `position_x` BETWEEN 4838.9 AND 4839.9 AND `position_y` BETWEEN -1381.8 AND -1380.8;
-- Highvale Ranger Bow (item 515694, guid 6941837): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941837 AND `id` = 95887 AND `map` = 1 AND `position_x` BETWEEN 6454.7 AND 6455.7 AND `position_y` BETWEEN 844.8 AND 845.8;
-- Idol of the Aerie (item 515717, guid 6941859): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941859 AND `id` = 95794 AND `map` = 1 AND `position_x` BETWEEN 6526.7 AND 6527.7 AND `position_y` BETWEEN -768.2 AND -767.2;
-- Idol of the Brooding Shadow (item 515241, guid 6941860): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941860 AND `id` = 1345075 AND `map` = 1 AND `position_x` BETWEEN 5319.3 AND 5320.3 AND `position_y` BETWEEN -1250.9 AND -1249.9;
-- Jane's Lucky Hat (item 515362, guid 6941883): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941883 AND `id` = 96173 AND `map` = 1 AND `position_x` BETWEEN 4059.3 AND 4060.3 AND `position_y` BETWEEN -2287.1 AND -2286.1;
-- Libram of Resolute Light (item 515732, guid 6941912): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941912 AND `id` = 1345084 AND `map` = 1 AND `position_x` BETWEEN 4664.2 AND 4665.2 AND `position_y` BETWEEN -792.4 AND -791.4;
-- Lucky Fisherman's Breeches (item 515405, guid 6941935): belongs in Winterspring
DELETE FROM `gameobject` WHERE `guid` = 6941935 AND `id` = 96212 AND `map` = 1 AND `position_x` BETWEEN 3712.7 AND 3713.7 AND `position_y` BETWEEN -314.0 AND -313.0;
-- Maggot Eye Musket (item 521033, guid 6941941): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941941 AND `id` = 517353 AND `map` = 1 AND `position_x` BETWEEN 3470.6 AND 3471.6 AND `position_y` BETWEEN -1695.5 AND -1694.5;
-- Ooze Cleansed Shoulderpads (item 515703, guid 6942008): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942008 AND `id` = 95896 AND `map` = 1 AND `position_x` BETWEEN 6494.9 AND 6495.9 AND `position_y` BETWEEN -3.9 AND -2.9;
-- Overwatch Longrifle (item 515690, guid 6942015): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942015 AND `id` = 95883 AND `map` = 1 AND `position_x` BETWEEN 6188.3 AND 6189.3 AND `position_y` BETWEEN 1094.3 AND 1095.3;
-- Ritual Robes (item 354163, guid 6942094): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6942094 AND `id` = 254263 AND `map` = 1 AND `position_x` BETWEEN 6177.3 AND 6178.3 AND `position_y` BETWEEN -3111.4 AND -3110.4;
-- Sash of Contemplation (item 354509, guid 6942133): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942133 AND `id` = 254572 AND `map` = 1 AND `position_x` BETWEEN 6105.3 AND 6106.3 AND `position_y` BETWEEN -137.5 AND -136.5;
-- Seabreeze Hauberk (item 515719, guid 6942148): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942148 AND `id` = 95796 AND `map` = 1 AND `position_x` BETWEEN 5231.9 AND 5232.9 AND `position_y` BETWEEN -2233.2 AND -2232.2;
-- Silverback Cape (item 515363, guid 6942186): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942186 AND `id` = 96170 AND `map` = 1 AND `position_x` BETWEEN 3969.8 AND 3970.8 AND `position_y` BETWEEN -2106.6 AND -2105.6;
-- Sludge Hammer (item 515712, guid 6942205): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942205 AND `id` = 95789 AND `map` = 1 AND `position_x` BETWEEN 6448.6 AND 6449.6 AND `position_y` BETWEEN -916.9 AND -915.9;
-- The Blood Talon (item 515726, guid 6942299): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942299 AND `id` = 95908 AND `map` = 1 AND `position_x` BETWEEN 5411.4 AND 5412.4 AND `position_y` BETWEEN -531.1 AND -530.1;
-- Tiki Shield (item 515736, guid 6942328): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6942328 AND `id` = 515918 AND `map` = 1 AND `position_x` BETWEEN 6602.7 AND 6603.7 AND `position_y` BETWEEN -759.0 AND -758.0;
-- Tome of Sundered Souls (item 515242, guid 6942339): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942339 AND `id` = 95909 AND `map` = 1 AND `position_x` BETWEEN 4926.2 AND 4927.2 AND `position_y` BETWEEN -1491.2 AND -1490.2;
-- Trapper's Lone Band (item 515720, guid 6942352): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942352 AND `id` = 95797 AND `map` = 1 AND `position_x` BETWEEN 6018.0 AND 6019.0 AND `position_y` BETWEEN -1381.8 AND -1380.8;
-- Vilebranch Beastlance (item 515714, guid 6942390): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942390 AND `id` = 95791 AND `map` = 1 AND `position_x` BETWEEN 6233.7 AND 6234.7 AND `position_y` BETWEEN -1714.5 AND -1713.5;
-- Wand of the Broodbound (item 515733, guid 6942399): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942399 AND `id` = 1345163 AND `map` = 1 AND `position_x` BETWEEN 4533.2 AND 4534.2 AND `position_y` BETWEEN -857.9 AND -856.9;
-- Zipcoil's Zapper Cap (item 515695, guid 6942457): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942457 AND `id` = 1345183 AND `map` = 1 AND `position_x` BETWEEN 6673.0 AND 6674.0 AND `position_y` BETWEEN 713.8 AND 714.8;
-- Zun'watha Cleaver (item 515689, guid 6942459): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6942459 AND `id` = 95882 AND `map` = 1 AND `position_x` BETWEEN 5794.8 AND 5795.8 AND `position_y` BETWEEN 1380.5 AND 1381.5;
-- Feralas
-- Belt of the Shen'dralar (item 354514, guid 6941431): belongs in DireMaul
DELETE FROM `gameobject` WHERE `guid` = 6941431 AND `id` = 254578 AND `map` = 1 AND `position_x` BETWEEN -4260.0 AND -4259.0 AND `position_y` BETWEEN 1581.7 AND 1582.7;
-- Fel Cleaver (item 515341, guid 6941725): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941725 AND `id` = 96159 AND `map` = 1 AND `position_x` BETWEEN -4010.2 AND -4009.2 AND `position_y` BETWEEN 2534.4 AND 2535.4;
-- Plague Fiend Chain (item 410165, guid 6942032): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942032 AND `id` = 90625 AND `map` = 1 AND `position_x` BETWEEN -4128.6 AND -4127.6 AND `position_y` BETWEEN 4185.9 AND 4186.9;
-- Hillsbrad Foothills
-- Band of Scales (item 515188, guid 6940104): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6940104 AND `id` = 515867 AND `map` = 0 AND `position_x` BETWEEN -1355.1 AND -1354.1 AND `position_y` BETWEEN -1911.9 AND -1910.9;
-- Brambleblade (item 450612, guid 6940177): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940177 AND `id` = 90336 AND `map` = 0 AND `position_x` BETWEEN -557.6 AND -556.6 AND `position_y` BETWEEN -1540.7 AND -1539.7;
-- Ceremonial Gloves (item 824389, guid 6940228): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6940228 AND `id` = 520702 AND `map` = 0 AND `position_x` BETWEEN -1204.9 AND -1203.9 AND `position_y` BETWEEN -1356.5 AND -1355.5;
-- Daggerspine Rod (item 521240, guid 6940291): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6940291 AND `id` = 517323 AND `map` = 0 AND `position_x` BETWEEN -198.2 AND -197.2 AND `position_y` BETWEEN 918.2 AND 919.2;
-- Glen Guardian (item 450674, guid 6940548): belongs in shadowglenstart
DELETE FROM `gameobject` WHERE `guid` = 6940548 AND `id` = 1344803 AND `map` = 0 AND `position_x` BETWEEN -859.0 AND -858.0 AND `position_y` BETWEEN -470.0 AND -469.0;
-- Solarsal Pendant (item 515189, guid 6941111): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941111 AND `id` = 96122 AND `map` = 0 AND `position_x` BETWEEN -1377.9 AND -1376.9 AND `position_y` BETWEEN -1807.2 AND -1806.2;
-- Tidebaron's Sigil (item 515190, guid 6941248): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941248 AND `id` = 96123 AND `map` = 0 AND `position_x` BETWEEN -1717.5 AND -1716.5 AND `position_y` BETWEEN -1766.5 AND -1765.5;
-- Waterlogged Musket (item 451105, guid 6941329): belongs in Wetlands
DELETE FROM `gameobject` WHERE `guid` = 6941329 AND `id` = 95700 AND `map` = 0 AND `position_x` BETWEEN -872.2 AND -871.2 AND `position_y` BETWEEN -531.4 AND -530.4;
-- Kalimdor
-- Cryptsilk Cuffs (item 410150, guid 6941592): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941592 AND `id` = 90528 AND `map` = 1 AND `position_x` BETWEEN 5438.9 AND 5439.9 AND `position_y` BETWEEN -7589.8 AND -7588.8;
-- Loch Modan
-- Ancient Vilebranch Gloves (item 354510, guid 6940054): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6940054 AND `id` = 254573 AND `map` = 0 AND `position_x` BETWEEN -5517.9 AND -5516.9 AND `position_y` BETWEEN -3566.1 AND -3565.1;
-- Arcane Glinting Shard (item 450537, guid 6940070): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940070 AND `id` = 90321 AND `map` = 0 AND `position_x` BETWEEN -5168.3 AND -5167.3 AND `position_y` BETWEEN -4007.6 AND -4006.6;
-- Broodsilk Gloves (item 515700, guid 6940193): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6940193 AND `id` = 95893 AND `map` = 0 AND `position_x` BETWEEN -5701.9 AND -5700.9 AND `position_y` BETWEEN -3097.1 AND -3096.1;
-- Fenris Ring (item 450546, guid 6940467): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940467 AND `id` = 90329 AND `map` = 0 AND `position_x` BETWEEN -5241.9 AND -5240.9 AND `position_y` BETWEEN -3648.9 AND -3647.9;
-- Gilnean Monocle (item 450544, guid 6940545): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940545 AND `id` = 90328 AND `map` = 0 AND `position_x` BETWEEN -5021.1 AND -5020.1 AND `position_y` BETWEEN -3014.3 AND -3013.3;
-- Haren's Tankard (item 450930, guid 6940592): belongs in Loch Modan
DELETE FROM `gameobject` WHERE `guid` = 6940592 AND `id` = 1345067 AND `map` = 0 AND `position_x` BETWEEN -5472.5 AND -5471.5 AND `position_y` BETWEEN -3776.6 AND -3775.6;
-- Hazzali Antenna (item 515781, guid 6940604): belongs in thegapingchasm
DELETE FROM `gameobject` WHERE `guid` = 6940604 AND `id` = 515781 AND `map` = 0 AND `position_x` BETWEEN -4965.9 AND -4964.9 AND `position_y` BETWEEN -3966.2 AND -3965.2;
-- Hide Piercer (item 515696, guid 6940623): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6940623 AND `id` = 95889 AND `map` = 0 AND `position_x` BETWEEN -5554.7 AND -5553.7 AND `position_y` BETWEEN -2876.4 AND -2875.4;
-- Lordamere Cuffs (item 521133, guid 6940716): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940716 AND `id` = 517330 AND `map` = 0 AND `position_x` BETWEEN -5113.1 AND -5112.1 AND `position_y` BETWEEN -3648.9 AND -3647.9;
-- Overwatch Longrifle (item 515690, guid 6940860): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6940860 AND `id` = 95883 AND `map` = 0 AND `position_x` BETWEEN -5390.9 AND -5389.9 AND `position_y` BETWEEN -2771.3 AND -2770.3;
-- Ravenclaw Bone Necklace (item 450547, guid 6940932): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940932 AND `id` = 90330 AND `map` = 0 AND `position_x` BETWEEN -5481.1 AND -5480.1 AND `position_y` BETWEEN -3262.6 AND -3261.6;
-- Small Claw of the Meat Wagon (item 450542, guid 6941103): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6941103 AND `id` = 90349 AND `map` = 0 AND `position_x` BETWEEN -4821.5 AND -4820.5 AND `position_y` BETWEEN -3013.8 AND -3012.8;
-- Moonglade
-- Corrupted Dragon Eye (item 515209, guid 6941587): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941587 AND `id` = 515949 AND `map` = 1 AND `position_x` BETWEEN 7873.4 AND 7874.4 AND `position_y` BETWEEN -2500.2 AND -2499.2;
-- Icon of Khan Maraudos (item 354206, guid 6941856): belongs in Azshara
DELETE FROM `gameobject` WHERE `guid` = 6941856 AND `id` = 254307 AND `map` = 1 AND `position_x` BETWEEN 7717.5 AND 7718.5 AND `position_y` BETWEEN -1659.6 AND -1658.6;
-- Mulgore
-- Ariden's Circlet (item 354457, guid 6941413): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6941413 AND `id` = 254492 AND `map` = 1 AND `position_x` BETWEEN -1437.0 AND -1436.0 AND `position_y` BETWEEN -624.2 AND -623.2;
-- Ashen Boots (item 354463, guid 6941415): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941415 AND `id` = 254489 AND `map` = 1 AND `position_x` BETWEEN -2944.3 AND -2943.3 AND `position_y` BETWEEN -453.2 AND -452.2;
-- Axe of Slaughter (item 354449, guid 6941420): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6941420 AND `id` = 254497 AND `map` = 1 AND `position_x` BETWEEN -2183.7 AND -2182.7 AND `position_y` BETWEEN -737.2 AND -736.2;
-- Bleakheart Piercer (item 450948, guid 6941450): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6941450 AND `id` = 90396 AND `map` = 1 AND `position_x` BETWEEN -2001.8 AND -2000.8 AND `position_y` BETWEEN -2126.5 AND -2125.5;
-- Bloodied Gauntlets (item 354450, guid 6941459): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6941459 AND `id` = 254496 AND `map` = 1 AND `position_x` BETWEEN -2808.7 AND -2807.7 AND `position_y` BETWEEN -1278.5 AND -1277.5;
-- Carapace Cracker (item 515393, guid 6941529): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941529 AND `id` = 95927 AND `map` = 1 AND `position_x` BETWEEN -1723.0 AND -1722.0 AND `position_y` BETWEEN -1381.3 AND -1380.3;
-- Centaur Axe (item 450689, guid 6941546): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941546 AND `id` = 95639 AND `map` = 1 AND `position_x` BETWEEN -3589.9 AND -3588.9 AND `position_y` BETWEEN -2241.9 AND -2240.9;
-- Claw Scarred Mail (item 450780, guid 6941570): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941570 AND `id` = 95673 AND `map` = 1 AND `position_x` BETWEEN -1360.7 AND -1359.7 AND `position_y` BETWEEN -1330.0 AND -1329.0;
-- Crystal Fused Carapace (item 515394, guid 6941594): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941594 AND `id` = 95920 AND `map` = 1 AND `position_x` BETWEEN -1511.2 AND -1510.2 AND `position_y` BETWEEN -997.1 AND -996.1;
-- Fragment of K'aresh (item 354469, guid 6941751): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6941751 AND `id` = 1345056 AND `map` = 1 AND `position_x` BETWEEN -2990.2 AND -2989.2 AND `position_y` BETWEEN -207.7 AND -206.7;
-- Frostmane Totem (item 450865, guid 6941755): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941755 AND `id` = 95676 AND `map` = 1 AND `position_x` BETWEEN -759.5 AND -758.5 AND `position_y` BETWEEN -1503.2 AND -1502.2;
-- Galak Chicken Smasher (item 515506, guid 6941763): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6941763 AND `id` = 515506 AND `map` = 1 AND `position_x` BETWEEN -2122.0 AND -2121.0 AND `position_y` BETWEEN -1086.5 AND -1085.5;
-- Gorishi Antenna (item 515395, guid 6941787): belongs in theslitheringscar
DELETE FROM `gameobject` WHERE `guid` = 6941787 AND `id` = 95921 AND `map` = 1 AND `position_x` BETWEEN -1865.0 AND -1864.0 AND `position_y` BETWEEN -1153.4 AND -1152.4;
-- Heavy Logsplitter (item 450872, guid 6941684): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941684 AND `id` = 95695 AND `map` = 1 AND `position_x` BETWEEN -3577.0 AND -3576.0 AND `position_y` BETWEEN -2355.5 AND -2354.5;
-- Hope for Atonement (item 450607, guid 6941841): belongs in Duskwood
DELETE FROM `gameobject` WHERE `guid` = 6941841 AND `id` = 89640 AND `map` = 1 AND `position_x` BETWEEN -3144.1 AND -3143.1 AND `position_y` BETWEEN -3040.2 AND -3039.2;
-- Lumber Axe (item 450244, guid 6941936): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941936 AND `id` = 95506 AND `map` = 1 AND `position_x` BETWEEN -2846.8 AND -2845.8 AND `position_y` BETWEEN -1937.9 AND -1936.9;
-- Magnus' Mug (item 450246, guid 6941942): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941942 AND `id` = 95508 AND `map` = 1 AND `position_x` BETWEEN -1968.7 AND -1967.7 AND `position_y` BETWEEN -2241.9 AND -2240.9;
-- Plains Bolter (item 415038, guid 6942034): belongs in Arathi Highlands
DELETE FROM `gameobject` WHERE `guid` = 6942034 AND `id` = 95875 AND `map` = 1 AND `position_x` BETWEEN -482.6 AND -481.6 AND `position_y` BETWEEN -1735.3 AND -1734.3;
-- Quilbow (item 450696, guid 6942053): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942053 AND `id` = 95625 AND `map` = 1 AND `position_x` BETWEEN -1684.9 AND -1683.9 AND `position_y` BETWEEN -2294.5 AND -2293.5;
-- Rabbit's Paw (item 450681, guid 6942055): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942055 AND `id` = 95615 AND `map` = 1 AND `position_x` BETWEEN -1293.2 AND -1292.2 AND `position_y` BETWEEN -924.7 AND -923.7;
-- Repelling Necklace (item 451026, guid 6942075): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942075 AND `id` = 95681 AND `map` = 1 AND `position_x` BETWEEN -2373.9 AND -2372.9 AND `position_y` BETWEEN -1633.9 AND -1632.9;
-- Retired Shadow Blade (item 450751, guid 6942084): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942084 AND `id` = 95643 AND `map` = 1 AND `position_x` BETWEEN -719.0 AND -718.0 AND `position_y` BETWEEN -3052.4 AND -3051.4;
-- Reverence of the Ancient Ones (item 354454, guid 6942086): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6942086 AND `id` = 254506 AND `map` = 1 AND `position_x` BETWEEN -2562.1 AND -2561.1 AND `position_y` BETWEEN 153.4 AND 154.4;
-- Sinister Garb (item 824381, guid 6942191): belongs in SinisterLair
DELETE FROM `gameobject` WHERE `guid` = 6942191 AND `id` = 520698 AND `map` = 1 AND `position_x` BETWEEN -403.2 AND -402.2 AND `position_y` BETWEEN -2648.3 AND -2647.3;
-- Snow Shovel (item 450243, guid 6942207): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6942207 AND `id` = 95505 AND `map` = 1 AND `position_x` BETWEEN -1968.7 AND -1967.7 AND `position_y` BETWEEN -2545.8 AND -2544.8;
-- Southfury Totem (item 450745, guid 6942217): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942217 AND `id` = 95627 AND `map` = 1 AND `position_x` BETWEEN -2306.4 AND -2305.4 AND `position_y` BETWEEN -1127.3 AND -1126.3;
-- Tainted Wasteblade (item 410133, guid 6942282): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942282 AND `id` = 90484 AND `map` = 1 AND `position_x` BETWEEN -2411.3 AND -2410.3 AND `position_y` BETWEEN -598.0 AND -597.0;
-- Warm Whoolies (item 450762, guid 6942403): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942403 AND `id` = 95679 AND `map` = 1 AND `position_x` BETWEEN -2238.8 AND -2237.8 AND `position_y` BETWEEN -1836.6 AND -1835.6;
-- Redridge Mountains
-- Branch of Mourning (item 354458, guid 6940180): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940180 AND `id` = 254491 AND `map` = 0 AND `position_x` BETWEEN -10003.5 AND -10002.5 AND `position_y` BETWEEN -3330.5 AND -3329.5;
-- Searing Gorge
-- Ancient Femur (item 824378, guid 6940048): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940048 AND `id` = 520018 AND `map` = 0 AND `position_x` BETWEEN -6586.0 AND -6585.0 AND `position_y` BETWEEN -635.9 AND -634.9;
-- Icon of Khan Maraudos (item 354206, guid 6940641): belongs in Burning Steppes
DELETE FROM `gameobject` WHERE `guid` = 6940641 AND `id` = 254307 AND `map` = 0 AND `position_x` BETWEEN -6635.6 AND -6634.6 AND `position_y` BETWEEN -2502.3 AND -2501.3;
-- Old Gardening Gloves (item 824383, guid 6940833): belongs in northshire
DELETE FROM `gameobject` WHERE `guid` = 6940833 AND `id` = 520065 AND `map` = 0 AND `position_x` BETWEEN -6654.4 AND -6653.4 AND `position_y` BETWEEN -1483.1 AND -1482.1;
-- Skull Sword (item 450694, guid 6941092): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941092 AND `id` = 95646 AND `map` = 0 AND `position_x` BETWEEN -7052.2 AND -7051.2 AND `position_y` BETWEEN -925.1 AND -924.1;
-- Swamplight Concoction (item 515239, guid 6941182): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941182 AND `id` = 518139 AND `map` = 0 AND `position_x` BETWEEN -6487.9 AND -6486.9 AND `position_y` BETWEEN -1562.6 AND -1561.6;
-- Water Wraps (item 450657, guid 6941327): belongs in northshire
DELETE FROM `gameobject` WHERE `guid` = 6941327 AND `id` = 95613 AND `map` = 0 AND `position_x` BETWEEN -6518.0 AND -6517.0 AND `position_y` BETWEEN -1661.7 AND -1660.7;
-- Yowler's Howl (item 450568, guid 6941363): belongs in SecretInquisitorialDungeon
DELETE FROM `gameobject` WHERE `guid` = 6941363 AND `id` = 90256 AND `map` = 0 AND `position_x` BETWEEN -6450.5 AND -6449.5 AND `position_y` BETWEEN -990.8 AND -989.8;
-- Silithus
-- Betrayer's Blade (item 515743, guid 6941437): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6941437 AND `id` = 515743 AND `map` = 1 AND `position_x` BETWEEN -6755.5 AND -6754.5 AND `position_y` BETWEEN 587.6 AND 588.6;
-- Cindersguard Saber (item 515381, guid 6941566): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941566 AND `id` = 95936 AND `map` = 1 AND `position_x` BETWEEN -5966.5 AND -5965.5 AND `position_y` BETWEEN 532.5 AND 533.5;
-- Dark Iron Loop (item 515268, guid 6941606): belongs in Blasted Lands
DELETE FROM `gameobject` WHERE `guid` = 6941606 AND `id` = 68410 AND `map` = 1 AND `position_x` BETWEEN -6846.6 AND -6845.6 AND `position_y` BETWEEN 750.6 AND 751.6;
-- Emerald Circle Charm (item 515314, guid 6941696): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6941696 AND `id` = 517204 AND `map` = 1 AND `position_x` BETWEEN -6141.4 AND -6140.4 AND `position_y` BETWEEN 1886.1 AND 1887.1;
-- Jar of Spiders (item 450806, guid 6941884): belongs in Ashenvale
DELETE FROM `gameobject` WHERE `guid` = 6941884 AND `id` = 3244513 AND `map` = 1 AND `position_x` BETWEEN -6642.2 AND -6641.2 AND `position_y` BETWEEN 1201.5 AND 1202.5;
-- Silverpine Forest
-- Darrow Silverband (item 521235, guid 6960023): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6960023 AND `id` = 97100 AND `map` = 0 AND `position_x` BETWEEN 418.5 AND 419.5 AND `position_y` BETWEEN 1842.7 AND 1843.7;
-- Hillsbrad Shovel (item 515024, guid 6960025): belongs in Hillsbrad Foothills
DELETE FROM `gameobject` WHERE `guid` = 6960025 AND `id` = 515383 AND `map` = 0 AND `position_x` BETWEEN 1293.3 AND 1294.3 AND `position_y` BETWEEN 1963.2 AND 1964.2;
-- Stonetalon Mountains
-- Barrel Smasher (item 354135, guid 6942095): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6942095 AND `id` = 95655 AND `map` = 1 AND `position_x` BETWEEN 2212.0 AND 2213.0 AND `position_y` BETWEEN -1414.1 AND -1413.1;
-- Caravan Utility Hammer (item 515403, guid 6941536): belongs in valleyoftrialsstart
DELETE FROM `gameobject` WHERE `guid` = 6941536 AND `id` = 96217 AND `map` = 1 AND `position_x` BETWEEN 2288.8 AND 2289.8 AND `position_y` BETWEEN -895.2 AND -894.2;
-- Cindersguard Saber (item 515381, guid 6941568): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941568 AND `id` = 95936 AND `map` = 1 AND `position_x` BETWEEN 2509.8 AND 2510.8 AND `position_y` BETWEEN -1176.0 AND -1175.0;
-- Doomfall Spark (item 515373, guid 6941647): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941647 AND `id` = 96183 AND `map` = 1 AND `position_x` BETWEEN 1174.4 AND 1175.4 AND `position_y` BETWEEN -837.5 AND -836.5;
-- Elegantly Designed Cuffs (item 515397, guid 6941680): belongs in Winterspring
DELETE FROM `gameobject` WHERE `guid` = 6941680 AND `id` = 96214 AND `map` = 1 AND `position_x` BETWEEN 2710.0 AND 2711.0 AND `position_y` BETWEEN -432.8 AND -431.8;
-- Ember Crown (item 515384, guid 6941688): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941688 AND `id` = 95933 AND `map` = 1 AND `position_x` BETWEEN 2750.0 AND 2751.0 AND `position_y` BETWEEN -1183.5 AND -1182.5;
-- Ghostmoor Cloak (item 521034, guid 6941770): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941770 AND `id` = 517354 AND `map` = 1 AND `position_x` BETWEEN 2750.0 AND 2751.0 AND `position_y` BETWEEN -1587.1 AND -1586.1;
-- Gravedigger's Delight (item 515013, guid 6941789): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941789 AND `id` = 515369 AND `map` = 1 AND `position_x` BETWEEN 2173.5 AND 2174.5 AND `position_y` BETWEEN -837.5 AND -836.5;
-- One Ring to Flame Them All (item 515383, guid 6942007): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942007 AND `id` = 95934 AND `map` = 1 AND `position_x` BETWEEN 2849.9 AND 2850.9 AND `position_y` BETWEEN -1122.4 AND -1121.4;
-- Retired Hero's Helm (item 515374, guid 6942083): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942083 AND `id` = 96218 AND `map` = 1 AND `position_x` BETWEEN 1376.5 AND 1377.5 AND `position_y` BETWEEN -1181.2 AND -1180.2;
-- Ringo's Star (item 515382, guid 6942092): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942092 AND `id` = 95935 AND `map` = 1 AND `position_x` BETWEEN 2747.7 AND 2748.7 AND `position_y` BETWEEN -1300.5 AND -1299.5;
-- Scarlet Insignia (item 515020, guid 6942142): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6942142 AND `id` = 515377 AND `map` = 1 AND `position_x` BETWEEN 2058.3 AND 2059.3 AND `position_y` BETWEEN -1241.2 AND -1240.2;
-- Spring Shard (item 515413, guid 6942230): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942230 AND `id` = 95925 AND `map` = 1 AND `position_x` BETWEEN 2753.8 AND 2754.8 AND `position_y` BETWEEN -661.7 AND -660.7;
-- The Silver Blade (item 410143, guid 6942303): belongs in Alterac Mountains
DELETE FROM `gameobject` WHERE `guid` = 6942303 AND `id` = 90509 AND `map` = 1 AND `position_x` BETWEEN 1977.4 AND 1978.4 AND `position_y` BETWEEN 31.2 AND 32.2;
-- Thunderstomp Scale (item 515372, guid 6942323): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942323 AND `id` = 95918 AND `map` = 1 AND `position_x` BETWEEN 1789.3 AND 1790.3 AND `position_y` BETWEEN -549.2 AND -548.2;
-- Totem of Scorching Sparks (item 515386, guid 6942349): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942349 AND `id` = 95931 AND `map` = 1 AND `position_x` BETWEEN 2635.9 AND 2636.9 AND `position_y` BETWEEN -1330.0 AND -1329.0;
-- Stormwind City
-- Barrel Smasher (item 354135, guid 6960008): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6960008 AND `id` = 95655 AND `map` = 0 AND `position_x` BETWEEN -9067.6 AND -9066.6 AND `position_y` BETWEEN 156.1 AND 157.1;
-- Flower of Tranquility (item 354127, guid 6940492): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6940492 AND `id` = 254222 AND `map` = 0 AND `position_x` BETWEEN -8150.8 AND -8149.8 AND `position_y` BETWEEN 167.6 AND 168.6;
-- Staff of Talons (item 354128, guid 6941138): belongs in Stonetalon Mountains
DELETE FROM `gameobject` WHERE `guid` = 6941138 AND `id` = 254223 AND `map` = 0 AND `position_x` BETWEEN -8238.8 AND -8237.8 AND `position_y` BETWEEN 604.2 AND 605.2;
-- Stranglethorn Vale
-- Bloodmage Coil (item 515304, guid 6940148): belongs in Blasted Lands
DELETE FROM `gameobject` WHERE `guid` = 6940148 AND `id` = 90423 AND `map` = 0 AND `position_x` BETWEEN -11770.0 AND -11769.0 AND `position_y` BETWEEN -1007.5 AND -1006.5;
-- Collector's Junk (item 515292, guid 6940264): belongs in Blasted Lands
DELETE FROM `gameobject` WHERE `guid` = 6940264 AND `id` = 96199 AND `map` = 0 AND `position_x` BETWEEN -12695.3 AND -12694.3 AND `position_y` BETWEEN -1097.5 AND -1096.5;
-- Gorishi Antenna (item 515395, guid 6940561): belongs in theslitheringscar
DELETE FROM `gameobject` WHERE `guid` = 6940561 AND `id` = 95921 AND `map` = 0 AND `position_x` BETWEEN -14846.9 AND -14845.9 AND `position_y` BETWEEN -675.1 AND -674.1;
-- Lost Faith (item 515305, guid 6940720): belongs in Blasted Lands
DELETE FROM `gameobject` WHERE `guid` = 6940720 AND `id` = 90421 AND `map` = 0 AND `position_x` BETWEEN -12357.1 AND -12356.1 AND `position_y` BETWEEN -545.0 AND -544.0;
-- Pauldron of the First War (item 515299, guid 6940870): belongs in Blasted Lands
DELETE FROM `gameobject` WHERE `guid` = 6940870 AND `id` = 96196 AND `map` = 0 AND `position_x` BETWEEN -12845.4 AND -12844.4 AND `position_y` BETWEEN -1296.5 AND -1295.5;
-- Wild Tracker Bindings (item 515144, guid 6941337): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941337 AND `id` = 96101 AND `map` = 0 AND `position_x` BETWEEN -13335.7 AND -13334.7 AND `position_y` BETWEEN -428.0 AND -427.0;
-- Wintergale Cloak (item 410097, guid 6941345): belongs in Winterspring
DELETE FROM `gameobject` WHERE `guid` = 6941345 AND `id` = 518175 AND `map` = 0 AND `position_x` BETWEEN -12433.6 AND -12432.6 AND `position_y` BETWEEN 211.1 AND 212.1;
-- Swamp of Sorrows
-- Ariden's Circlet (item 354457, guid 6940079): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940079 AND `id` = 254492 AND `map` = 0 AND `position_x` BETWEEN -10145.6 AND -10144.6 AND `position_y` BETWEEN -3417.7 AND -3416.7;
-- Ashen Boots (item 354463, guid 6940082): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940082 AND `id` = 254489 AND `map` = 0 AND `position_x` BETWEEN -10815.7 AND -10814.7 AND `position_y` BETWEEN -3340.6 AND -3339.6;
-- Axe of Slaughter (item 354449, guid 6940096): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940096 AND `id` = 254497 AND `map` = 0 AND `position_x` BETWEEN -10474.7 AND -10473.7 AND `position_y` BETWEEN -3464.9 AND -3463.9;
-- Banner of the Dark Riders (item 354453, guid 6940106): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940106 AND `id` = 254493 AND `map` = 0 AND `position_x` BETWEEN -10088.2 AND -10087.2 AND `position_y` BETWEEN -3091.0 AND -3090.0;
-- Bastion of the Fallen (item 354446, guid 6940110): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940110 AND `id` = 254505 AND `map` = 0 AND `position_x` BETWEEN -10724.9 AND -10723.9 AND `position_y` BETWEEN -3135.5 AND -3134.5;
-- Betrayal's Edge (item 354452, guid 6940116): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940116 AND `id` = 254494 AND `map` = 0 AND `position_x` BETWEEN -10160.3 AND -10159.3 AND `position_y` BETWEEN -3034.6 AND -3033.6;
-- Defias Apothecary Pants (item 515684, guid 6940335): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6940335 AND `id` = 95784 AND `map` = 0 AND `position_x` BETWEEN -10768.0 AND -10767.0 AND `position_y` BETWEEN -3828.3 AND -3827.3;
-- Discarded Wagon Wheel (item 450621, guid 6940362): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6940362 AND `id` = 90346 AND `map` = 0 AND `position_x` BETWEEN -10523.2 AND -10522.2 AND `position_y` BETWEEN -3576.0 AND -3575.0;
-- Faded Promise Ring (item 354447, guid 6940454): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6940454 AND `id` = 254026 AND `map` = 0 AND `position_x` BETWEEN -10738.3 AND -10737.3 AND `position_y` BETWEEN -3447.5 AND -3446.5;
-- Furbolg War-drum (item 515029, guid 6960017): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6960017 AND `id` = 515388 AND `map` = 0 AND `position_x` BETWEEN -10997.2 AND -10996.2 AND `position_y` BETWEEN -2313.0 AND -2312.0;
-- Kul Tiras Armplates (item 521082, guid 6940686): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940686 AND `id` = 90598 AND `map` = 0 AND `position_x` BETWEEN -10506.9 AND -10505.9 AND `position_y` BETWEEN -2917.2 AND -2916.2;
-- Sentinel Wrap (item 515184, guid 6941046): belongs in Feralas
DELETE FROM `gameobject` WHERE `guid` = 6941046 AND `id` = 1345124 AND `map` = 0 AND `position_x` BETWEEN -10457.6 AND -10456.6 AND `position_y` BETWEEN -3279.8 AND -3278.8;
-- Timber Maul (item 521003, guid 6960020): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6960020 AND `id` = 90553 AND `map` = 0 AND `position_x` BETWEEN -10856.1 AND -10855.1 AND `position_y` BETWEEN -2286.9 AND -2285.9;
-- Venture Co. Ring (item 450620, guid 6941295): belongs in Burning Steppes
DELETE FROM `gameobject` WHERE `guid` = 6941295 AND `id` = 90345 AND `map` = 0 AND `position_x` BETWEEN -10950.4 AND -10949.4 AND `position_y` BETWEEN -3149.5 AND -3148.5;
-- Tanaris
-- Dino Wacker (item 515370, guid 6941632): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6941632 AND `id` = 96182 AND `map` = 1 AND `position_x` BETWEEN -8715.2 AND -8714.2 AND `position_y` BETWEEN -4115.3 AND -4114.3;
-- Silithid Ritual Robe (item 515398, guid 6942179): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942179 AND `id` = 96220 AND `map` = 1 AND `position_x` BETWEEN -8683.6 AND -8682.6 AND `position_y` BETWEEN -4287.3 AND -4286.3;
-- Slightly Sticky Cloak (item 515388, guid 6942202): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942202 AND `id` = 96222 AND `map` = 1 AND `position_x` BETWEEN -8346.6 AND -8345.6 AND `position_y` BETWEEN -4337.5 AND -4336.5;
-- Tawana's Spare Axe (item 515400, guid 6942291): belongs in Un'Goro Crater
DELETE FROM `gameobject` WHERE `guid` = 6942291 AND `id` = 96216 AND `map` = 1 AND `position_x` BETWEEN -8486.0 AND -8485.0 AND `position_y` BETWEEN -4655.5 AND -4654.5;
-- Teldrassil
-- Abandoned Moonshine (item 515530, guid 6941379): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6941379 AND `id` = 515530 AND `map` = 1 AND `position_x` BETWEEN 9355.9 AND 9356.9 AND `position_y` BETWEEN 174.5 AND 175.5;
-- Apothecary Cowl (item 410036, guid 6941406): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941406 AND `id` = 96246 AND `map` = 1 AND `position_x` BETWEEN 9306.4 AND 9307.4 AND `position_y` BETWEEN -284.2 AND -283.2;
-- Blightbloom Talisman (item 278848, guid 6941452): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941452 AND `id` = 340042 AND `map` = 1 AND `position_x` BETWEEN 9582.0 AND 9583.0 AND `position_y` BETWEEN 1106.1 AND 1107.1;
-- Brambleblade (item 450612, guid 6941488): belongs in campnarachestart
DELETE FROM `gameobject` WHERE `guid` = 6941488 AND `id` = 90336 AND `map` = 1 AND `position_x` BETWEEN 10599.1 AND 10600.1 AND `position_y` BETWEEN 309.9 AND 310.9;
-- Ceremonial Gloves (item 824389, guid 6941550): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941550 AND `id` = 520702 AND `map` = 1 AND `position_x` BETWEEN 10305.7 AND 10306.7 AND `position_y` BETWEEN 393.4 AND 394.4;
-- Charred Slicer (item 410027, guid 6941556): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941556 AND `id` = 340120 AND `map` = 1 AND `position_x` BETWEEN 10288.9 AND 10289.9 AND `position_y` BETWEEN 1017.0 AND 1018.0;
-- Cursed Elemental Scepter (item 515514, guid 6941599): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6941599 AND `id` = 515514 AND `map` = 1 AND `position_x` BETWEEN 10959.3 AND 10960.3 AND `position_y` BETWEEN 1822.4 AND 1823.4;
-- Darkcloud Totem (item 515516, guid 6941611): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6941611 AND `id` = 515516 AND `map` = 1 AND `position_x` BETWEEN 10621.2 AND 10622.2 AND `position_y` BETWEEN 1865.7 AND 1866.7;
-- Dunemaul Warbelt (item 515772, guid 6941659): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6941659 AND `id` = 515772 AND `map` = 1 AND `position_x` BETWEEN 10057.1 AND 10058.1 AND `position_y` BETWEEN 1835.6 AND 1836.6;
-- Ebonblight Slippers (item 410020, guid 6941674): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941674 AND `id` = 340123 AND `map` = 1 AND `position_x` BETWEEN 9712.0 AND 9713.0 AND `position_y` BETWEEN 1478.8 AND 1479.8;
-- Fisher's Misfortune (item 515834, guid 6941738): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6941738 AND `id` = 515834 AND `map` = 1 AND `position_x` BETWEEN 11051.2 AND 11052.2 AND `position_y` BETWEEN 331.3 AND 332.3;
-- Graveyard Striker (item 410033, guid 6941790): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941790 AND `id` = 340122 AND `map` = 1 AND `position_x` BETWEEN 10020.5 AND 10021.5 AND `position_y` BETWEEN 769.1 AND 770.1;
-- Grimtotem Darkblade (item 515504, guid 6941799): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6941799 AND `id` = 515504 AND `map` = 1 AND `position_x` BETWEEN 10412.1 AND 10413.1 AND `position_y` BETWEEN 1820.4 AND 1821.4;
-- Grimtotem Jaw Smasher (item 515512, guid 6941801): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6941801 AND `id` = 515512 AND `map` = 1 AND `position_x` BETWEEN 10729.8 AND 10730.8 AND `position_y` BETWEEN 2191.5 AND 2192.5;
-- Highperch Necklace (item 515508, guid 6941836): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6941836 AND `id` = 515508 AND `map` = 1 AND `position_x` BETWEEN 10445.1 AND 10446.1 AND `position_y` BETWEEN 2894.1 AND 2895.1;
-- Infantry Gauntlets (item 278852, guid 6941864): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941864 AND `id` = 341060 AND `map` = 1 AND `position_x` BETWEEN 9176.1 AND 9177.1 AND `position_y` BETWEEN 341.4 AND 342.4;
-- Last Guardian (item 415089, guid 6941901): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941901 AND `id` = 254346 AND `map` = 1 AND `position_x` BETWEEN 10178.2 AND 10179.2 AND `position_y` BETWEEN 1082.9 AND 1083.9;
-- Lid of the Dead (item 515770, guid 6942262): belongs in Darkshore
DELETE FROM `gameobject` WHERE `guid` = 6942262 AND `id` = 515770 AND `map` = 1 AND `position_x` BETWEEN 10130.9 AND 10131.9 AND `position_y` BETWEEN 1070.8 AND 1071.8;
-- Phylactery Shard (item 410010, guid 6942026): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6942026 AND `id` = 340112 AND `map` = 1 AND `position_x` BETWEEN 10045.9 AND 10046.9 AND `position_y` BETWEEN 1459.9 AND 1460.9;
-- Reliever's Burden (item 278845, guid 6942074): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942074 AND `id` = 340111 AND `map` = 1 AND `position_x` BETWEEN 9461.8 AND 9462.8 AND `position_y` BETWEEN 1354.0 AND 1355.0;
-- Sand Stompers (item 515900, guid 6942122): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6942122 AND `id` = 515900 AND `map` = 1 AND `position_x` BETWEEN 10385.3 AND 10386.3 AND `position_y` BETWEEN 1310.3 AND 1311.3;
-- Scarlet Blunderbuss (item 410233, guid 6942141): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942141 AND `id` = 324506 AND `map` = 1 AND `position_x` BETWEEN 10066.3 AND 10067.3 AND `position_y` BETWEEN 1738.9 AND 1739.9;
-- Scarlet Pauldrons (item 410026, guid 6942143): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942143 AND `id` = 96243 AND `map` = 1 AND `position_x` BETWEEN 10316.4 AND 10317.4 AND `position_y` BETWEEN 1508.8 AND 1509.8;
-- Scarlet Slicer (item 410014, guid 6942144): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942144 AND `id` = 340061 AND `map` = 1 AND `position_x` BETWEEN 10578.8 AND 10579.8 AND `position_y` BETWEEN 1107.1 AND 1108.1;
-- Skeletal Club (item 278851, guid 6942192): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6942192 AND `id` = 340098 AND `map` = 1 AND `position_x` BETWEEN 9323.4 AND 9324.4 AND `position_y` BETWEEN 482.5 AND 483.5;
-- Staff of the Wind Sisters (item 354480, guid 6942234): belongs in Thousand Needles
DELETE FROM `gameobject` WHERE `guid` = 6942234 AND `id` = 254560 AND `map` = 1 AND `position_x` BETWEEN 10283.5 AND 10284.5 AND `position_y` BETWEEN 2229.2 AND 2230.2;
-- Sun Cover (item 515822, guid 6942269): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6942269 AND `id` = 515822 AND `map` = 1 AND `position_x` BETWEEN 9408.5 AND 9409.5 AND `position_y` BETWEEN 602.6 AND 603.6;
-- Thornmantle Quills (item 450610, guid 6942313): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6942313 AND `id` = 90332 AND `map` = 1 AND `position_x` BETWEEN 10743.4 AND 10744.4 AND `position_y` BETWEEN 246.9 AND 247.9;
-- Thunder Hide Tailspike (item 450768, guid 6942319): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942319 AND `id` = 95624 AND `map` = 1 AND `position_x` BETWEEN 10166.7 AND 10167.7 AND `position_y` BETWEEN 1126.8 AND 1127.8;
-- Zelyn'Theris (item 354180, guid 6942456): belongs in Desolace
DELETE FROM `gameobject` WHERE `guid` = 6942456 AND `id` = 254280 AND `map` = 1 AND `position_x` BETWEEN 9319.9 AND 9320.9 AND `position_y` BETWEEN 3284.3 AND 3285.3;
-- The Barrens
-- Rider's Ring (item 450980, guid 6942087): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6942087 AND `id` = 63517 AND `map` = 1 AND `position_x` BETWEEN -1766.0 AND -1765.0 AND `position_y` BETWEEN -3964.3 AND -3963.3;
-- Thunder Hide Tailspike (item 450768, guid 6942317): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942317 AND `id` = 95624 AND `map` = 1 AND `position_x` BETWEEN -9.7 AND -8.7 AND `position_y` BETWEEN -1836.6 AND -1835.6;
-- The Hinterlands
-- Ancient Sentinel Headdress (item 410048, guid 6940052): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940052 AND `id` = 1345002 AND `map` = 0 AND `position_x` BETWEEN 39.8 AND 40.8 AND `position_y` BETWEEN -3998.7 AND -3997.7;
-- Betrayer's Blade (item 515743, guid 6940117): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6940117 AND `id` = 515743 AND `map` = 0 AND `position_x` BETWEEN 585.1 AND 586.1 AND `position_y` BETWEEN -3730.3 AND -3729.3;
-- Bloody Wedding Ring (item 450644, guid 6940159): belongs in The Barrens
DELETE FROM `gameobject` WHERE `guid` = 6940159 AND `id` = 90305 AND `map` = 0 AND `position_x` BETWEEN 170.2 AND 171.2 AND `position_y` BETWEEN -3475.1 AND -3474.1;
-- Bracers of the Bound Storm (item 410072, guid 6940176): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940176 AND `id` = 96232 AND `map` = 0 AND `position_x` BETWEEN 935.1 AND 936.1 AND `position_y` BETWEEN -2769.0 AND -2768.0;
-- Bravecrest Chain (item 410038, guid 6940182): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940182 AND `id` = 518162 AND `map` = 0 AND `position_x` BETWEEN 930.2 AND 931.2 AND `position_y` BETWEEN -4687.8 AND -4686.8;
-- Brigade Blunderbuss (item 410075, guid 6940185): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940185 AND `id` = 356433 AND `map` = 0 AND `position_x` BETWEEN 51.6 AND 52.6 AND `position_y` BETWEEN -2583.4 AND -2582.4;
-- Bristleback Thorn (item 521198, guid 6940188): belongs in Wetlands
DELETE FROM `gameobject` WHERE `guid` = 6940188 AND `id` = 97115 AND `map` = 0 AND `position_x` BETWEEN 84.2 AND 85.2 AND `position_y` BETWEEN -3631.8 AND -3630.8;
-- Chitin Thread Wraps (item 410060, guid 6940249): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940249 AND `id` = 686883 AND `map` = 0 AND `position_x` BETWEEN 719.3 AND 720.3 AND `position_y` BETWEEN -3340.7 AND -3339.7;
-- Chitinsunder Greataxe (item 410077, guid 6940250): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940250 AND `id` = 159984 AND `map` = 0 AND `position_x` BETWEEN 309.3 AND 310.3 AND `position_y` BETWEEN -2315.9 AND -2314.9;
-- Dark Iron Collar (item 450266, guid 6940297): belongs in Loch Modan
DELETE FROM `gameobject` WHERE `guid` = 6940297 AND `id` = 95528 AND `map` = 0 AND `position_x` BETWEEN 1106.3 AND 1107.3 AND `position_y` BETWEEN -3847.0 AND -3846.0;
-- Darnell's Blade (item 410051, guid 6940314): belongs in Western Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940314 AND `id` = 638836 AND `map` = 0 AND `position_x` BETWEEN -6.9 AND -5.9 AND `position_y` BETWEEN -3098.2 AND -3097.2;
-- Deadman Gauntlets (item 515745, guid 6940318): belongs in Silverpine Forest
DELETE FROM `gameobject` WHERE `guid` = 6940318 AND `id` = 515745 AND `map` = 0 AND `position_x` BETWEEN 541.7 AND 542.7 AND `position_y` BETWEEN -3477.4 AND -3476.4;
-- Geo Band (item 410056, guid 6940529): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940529 AND `id` = 686879 AND `map` = 0 AND `position_x` BETWEEN 310.8 AND 311.8 AND `position_y` BETWEEN -3038.5 AND -3037.5;
-- Grimtotem Bow (item 824386, guid 6940580): belongs in MoltenCore
DELETE FROM `gameobject` WHERE `guid` = 6940580 AND `id` = 520699 AND `map` = 0 AND `position_x` BETWEEN 1338.1 AND 1339.1 AND `position_y` BETWEEN -5189.8 AND -5188.8;
-- Lost Cenarion Bolter (item 410070, guid 6940719): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940719 AND `id` = 518466 AND `map` = 0 AND `position_x` BETWEEN 234.8 AND 235.8 AND `position_y` BETWEEN -3696.5 AND -3695.5;
-- Murloc Voodoo Doll (item 450522, guid 6940790): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6940790 AND `id` = 90228 AND `map` = 0 AND `position_x` BETWEEN 907.9 AND 908.9 AND `position_y` BETWEEN -2921.0 AND -2920.0;
-- Purple Steppers (item 410076, guid 6940913): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940913 AND `id` = 356432 AND `map` = 0 AND `position_x` BETWEEN 670.0 AND 671.0 AND `position_y` BETWEEN -2692.0 AND -2691.0;
-- Qiraji Scale Greaves (item 410059, guid 6940914): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6940914 AND `id` = 686882 AND `map` = 0 AND `position_x` BETWEEN 1108.6 AND 1109.6 AND `position_y` BETWEEN -3263.0 AND -3262.0;
-- Sandstone Sniper (item 410071, guid 6941000): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941000 AND `id` = 356435 AND `map` = 0 AND `position_x` BETWEEN 353.7 AND 354.7 AND `position_y` BETWEEN -4245.5 AND -4244.5;
-- Sandstorm Shaper (item 410074, guid 6941001): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941001 AND `id` = 686888 AND `map` = 0 AND `position_x` BETWEEN 907.9 AND 908.9 AND `position_y` BETWEEN -2606.9 AND -2605.9;
-- Southwind Defender (item 410049, guid 6941118): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941118 AND `id` = 1345134 AND `map` = 0 AND `position_x` BETWEEN -124.7 AND -123.7 AND `position_y` BETWEEN -3858.2 AND -3857.2;
-- Standard Cenarion Spear (item 410047, guid 6941142): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941142 AND `id` = 356436 AND `map` = 0 AND `position_x` BETWEEN 581.8 AND 582.8 AND `position_y` BETWEEN -3492.8 AND -3491.8;
-- Traveler's Forest Cloak (item 521122, guid 6941278): belongs in Elwynn Forest
DELETE FROM `gameobject` WHERE `guid` = 6941278 AND `id` = 517366 AND `map` = 0 AND `position_x` BETWEEN 1325.5 AND 1326.5 AND `position_y` BETWEEN -2660.0 AND -2659.0;
-- Trigdy's Pistol (item 410046, guid 6941281): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941281 AND `id` = 518788 AND `map` = 0 AND `position_x` BETWEEN 821.7 AND 822.7 AND `position_y` BETWEEN -3671.4 AND -3670.4;
-- Twilight Prophet Staff (item 410067, guid 6941284): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941284 AND `id` = 518461 AND `map` = 0 AND `position_x` BETWEEN 708.3 AND 709.3 AND `position_y` BETWEEN -2955.7 AND -2954.7;
-- Wand of Twilight (item 410042, guid 6941318): belongs in Silithus
DELETE FROM `gameobject` WHERE `guid` = 6941318 AND `id` = 518171 AND `map` = 0 AND `position_x` BETWEEN 1029.3 AND 1030.3 AND `position_y` BETWEEN -4193.5 AND -4192.5;
-- Whisperwind Boots (item 515432, guid 6941335): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6941335 AND `id` = 515432 AND `map` = 0 AND `position_x` BETWEEN 1424.9 AND 1425.9 AND `position_y` BETWEEN -2168.6 AND -2167.6;
-- Thousand Needles
-- Bloodtalon Vestments (item 521079, guid 6941462): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941462 AND `id` = 1345013 AND `map` = 1 AND `position_x` BETWEEN -4468.0 AND -4467.0 AND `position_y` BETWEEN -3457.7 AND -3456.7;
-- Kul Tiras Handwraps (item 521080, guid 6941895): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6941895 AND `id` = 90594 AND `map` = 1 AND `position_x` BETWEEN -5008.4 AND -5007.4 AND `position_y` BETWEEN -3761.7 AND -3760.7;
-- Scalebane Pendant (item 515222, guid 6941690): belongs in Dustwallow Marsh
DELETE FROM `gameobject` WHERE `guid` = 6941690 AND `id` = 515923 AND `map` = 1 AND `position_x` BETWEEN -4691.4 AND -4690.4 AND `position_y` BETWEEN -3964.9 AND -3963.9;
-- Southfury Totem (item 450745, guid 6942216): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6942216 AND `id` = 95627 AND `map` = 1 AND `position_x` BETWEEN -4047.1 AND -4046.1 AND `position_y` BETWEEN -2896.9 AND -2895.9;
-- Thunder Bluff
-- Betrayal's Edge (item 354452, guid 6941435): belongs in Badlands
DELETE FROM `gameobject` WHERE `guid` = 6941435 AND `id` = 254494 AND `map` = 1 AND `position_x` BETWEEN -1471.3 AND -1470.3 AND `position_y` BETWEEN 197.5 AND 198.5;
-- Branch of Mourning (item 354458, guid 6941490): belongs in Deadwind Pass
DELETE FROM `gameobject` WHERE `guid` = 6941490 AND `id` = 254491 AND `map` = 1 AND `position_x` BETWEEN -1130.8 AND -1129.8 AND `position_y` BETWEEN -434.2 AND -433.2;
-- Gnomeregan Spanner (item 450249, guid 6941781): belongs in Dun Morogh
DELETE FROM `gameobject` WHERE `guid` = 6941781 AND `id` = 95511 AND `map` = 1 AND `position_x` BETWEEN -1293.2 AND -1292.2 AND `position_y` BETWEEN -114.1 AND -113.1;
-- Sandswept Binding (item 515744, guid 6941615): belongs in Tanaris
DELETE FROM `gameobject` WHERE `guid` = 6941615 AND `id` = 515744 AND `map` = 1 AND `position_x` BETWEEN -1330.8 AND -1329.8 AND `position_y` BETWEEN -131.2 AND -130.2;
-- Tirisfal Glades
-- Fallen Hardwood Plank (item 450615, guid 6960208): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6960208 AND `id` = 90339 AND `map` = 0 AND `position_x` BETWEEN 2571.9 AND 2572.9 AND `position_y` BETWEEN 525.9 AND 526.9;
-- Interloper's Loop (item 450622, guid 6960207): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6960207 AND `id` = 90347 AND `map` = 0 AND `position_x` BETWEEN 2434.2 AND 2435.2 AND `position_y` BETWEEN 1598.7 AND 1599.7;
-- Plainsblade (item 521071, guid 6940898): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6940898 AND `id` = 90591 AND `map` = 0 AND `position_x` BETWEEN 2207.8 AND 2208.8 AND `position_y` BETWEEN 1053.7 AND 1054.7;
-- Sunchaser Blade (item 521073, guid 6941176): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941176 AND `id` = 1345145 AND `map` = 0 AND `position_x` BETWEEN 2542.9 AND 2543.9 AND `position_y` BETWEEN 1404.9 AND 1405.9;
-- Swiftfoot Slippers (item 521074, guid 6941183): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941183 AND `id` = 254630 AND `map` = 0 AND `position_x` BETWEEN 3354.4 AND 3355.4 AND `position_y` BETWEEN 1451.2 AND 1452.2;
-- Thunderwalk Breastplate (item 521064, guid 6941247): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941247 AND `id` = 1345152 AND `map` = 0 AND `position_x` BETWEEN 3203.8 AND 3204.8 AND `position_y` BETWEEN 728.3 AND 729.3;
-- Un'Goro Crater
-- Hazzali Antenna (item 515781, guid 6941816): belongs in thegapingchasm
DELETE FROM `gameobject` WHERE `guid` = 6941816 AND `id` = 515781 AND `map` = 1 AND `position_x` BETWEEN -7769.6 AND -7768.6 AND `position_y` BETWEEN -2724.0 AND -2723.0;
-- Revantusk Hide Steppers (item 515718, guid 6941826): belongs in The Hinterlands
DELETE FROM `gameobject` WHERE `guid` = 6941826 AND `id` = 95795 AND `map` = 1 AND `position_x` BETWEEN -6978.7 AND -6977.7 AND `position_y` BETWEEN -1794.5 AND -1793.5;
-- Ror's Wrecker (item 515312, guid 6942100): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6942100 AND `id` = 517202 AND `map` = 1 AND `position_x` BETWEEN -6731.5 AND -6730.5 AND `position_y` BETWEEN -2553.0 AND -2552.0;
-- Venom-Infused Screwdriver (item 515769, guid 6942376): belongs in thenoxiouslair
DELETE FROM `gameobject` WHERE `guid` = 6942376 AND `id` = 515769 AND `map` = 1 AND `position_x` BETWEEN -7961.1 AND -7960.1 AND `position_y` BETWEEN -1199.9 AND -1198.9;
-- Undercity
-- Windfury Harpy Claw (item 450618, guid 6941341): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6941341 AND `id` = 90342 AND `map` = 0 AND `position_x` BETWEEN 1757.5 AND 1758.5 AND `position_y` BETWEEN 50.6 AND 51.6;
-- Western Plaguelands
-- Blade of the Submerged Moon (item 515435, guid 6940131): belongs in Teldrassil
DELETE FROM `gameobject` WHERE `guid` = 6940131 AND `id` = 515435 AND `map` = 0 AND `position_x` BETWEEN 1771.4 AND 1772.4 AND `position_y` BETWEEN -2056.0 AND -2055.0;
-- Earthshatterer Gavel (item 521089, guid 6940411): belongs in Durotar
DELETE FROM `gameobject` WHERE `guid` = 6940411 AND `id` = 254633 AND `map` = 0 AND `position_x` BETWEEN 1779.2 AND 1780.2 AND `position_y` BETWEEN -1771.7 AND -1770.7;
-- Long Fishing Spear (item 450617, guid 6960206): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6960206 AND `id` = 90340 AND `map` = 0 AND `position_x` BETWEEN 3073.6 AND 3074.6 AND `position_y` BETWEEN -26.5 AND -25.5;
-- Palemane Threads (item 521063, guid 6940864): belongs in Mulgore
DELETE FROM `gameobject` WHERE `guid` = 6940864 AND `id` = 90579 AND `map` = 0 AND `position_x` BETWEEN 1760.5 AND 1761.5 AND `position_y` BETWEEN -831.2 AND -830.2;
-- Westfall
-- Ror's Wrecker (item 515312, guid 6940975): belongs in Felwood
DELETE FROM `gameobject` WHERE `guid` = 6940975 AND `id` = 517202 AND `map` = 0 AND `position_x` BETWEEN -11599.1 AND -11598.1 AND `position_y` BETWEEN 1330.0 AND 1331.0;
-- Sawtooth Jaw (item 354250, guid 6941007): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6941007 AND `id` = 254385 AND `map` = 0 AND `position_x` BETWEEN -11593.5 AND -11592.5 AND `position_y` BETWEEN 111.3 AND 112.3;
-- Signet of Lire'kes (item 354251, guid 6941076): belongs in Swamp of Sorrows
DELETE FROM `gameobject` WHERE `guid` = 6941076 AND `id` = 254386 AND `map` = 0 AND `position_x` BETWEEN -11657.4 AND -11656.4 AND `position_y` BETWEEN 555.4 AND 556.4;
-- Wetlands
-- Borelgore's Chewtoy (item 410178, guid 6940169): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6940169 AND `id` = 90612 AND `map` = 0 AND `position_x` BETWEEN -2892.2 AND -2891.2 AND `position_y` BETWEEN -2512.1 AND -2511.1;
-- Defias Sprig (item 450563, guid 6940348): belongs in Westfall
DELETE FROM `gameobject` WHERE `guid` = 6940348 AND `id` = 90252 AND `map` = 0 AND `position_x` BETWEEN -3250.3 AND -3249.3 AND `position_y` BETWEEN -2498.9 AND -2497.9;
-- Ghostmoor Cloak (item 521034, guid 6940533): belongs in thegrizzledden
DELETE FROM `gameobject` WHERE `guid` = 6940533 AND `id` = 517354 AND `map` = 0 AND `position_x` BETWEEN -3519.1 AND -3518.1 AND `position_y` BETWEEN -2732.1 AND -2731.1;
-- Maggot Eye Musket (item 521033, guid 6940733): belongs in thegrizzledden
DELETE FROM `gameobject` WHERE `guid` = 6940733 AND `id` = 517353 AND `map` = 0 AND `position_x` BETWEEN -2996.9 AND -2995.9 AND `position_y` BETWEEN -2819.0 AND -2818.0;
-- Scarlet Insignia (item 515020, guid 6941015): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941015 AND `id` = 515377 AND `map` = 0 AND `position_x` BETWEEN -4017.3 AND -4016.3 AND `position_y` BETWEEN -2508.8 AND -2507.8;
-- Wailing Sash (item 521040, guid 6941314): belongs in Tirisfal Glades
DELETE FROM `gameobject` WHERE `guid` = 6941314 AND `id` = 517367 AND `map` = 0 AND `position_x` BETWEEN -3916.9 AND -3915.9 AND `position_y` BETWEEN -3307.0 AND -3306.0;
-- Wailing Spirit Amulet (item 410166, guid 6941316): belongs in Eastern Plaguelands
DELETE FROM `gameobject` WHERE `guid` = 6941316 AND `id` = 90627 AND `map` = 0 AND `position_x` BETWEEN -3672.7 AND -3671.7 AND `position_y` BETWEEN -1045.5 AND -1044.5;
-- map 43
-- Wailing Sapphire Gem (item 450642, guid 6942460): belongs in WailingCaverns
DELETE FROM `gameobject` WHERE `guid` = 6942460 AND `id` = 90303 AND `map` = 43 AND `position_x` BETWEEN -336.2 AND -335.2 AND `position_y` BETWEEN 327.9 AND 328.9;

-- Added: gear items whose pickup template has no spawn at all (the realm-map wipe of
-- 2026_09_23_05_worldforged_map.sql removed them and no later pass put them back). Each stands
-- at its recorded position; height as above. New guids 6975000-6975036.
-- Scholar's Ring of Enlightenment (item 500817, object 1345121): Alterac Mountains, source pins(dump), height: floor of nearest creature 3.9 yd away
-- Farstrider's Grips (item 521042, object 1345051): Arathi Highlands, source pins(dump), height: floor of nearest creature 8.8 yd away
-- Alliance Cord (item 521109, object 1345001): Azuremyst Isle, source pins(dump), height: floor of nearest gameobject 0.5 yd away
-- Feathered Pants (item 521096, object 1345052): Azuremyst Isle, source pins(dump), height: floor of nearest creature 1.8 yd away
-- Stillpine Gavel (item 521106, object 1345141): Azuremyst Isle, source pins(dump), height: floor of nearest creature 6.6 yd away
-- Bloodwashed Gloves (item 354126, object 254221): Bloodmyst Isle, source pins(dump), height: floor of nearest gameobject 2.5 yd away
-- Mystwood Glaive (item 521169, object 1345096): Bloodmyst Isle, source pins(dump), height: floor of nearest creature 13.2 yd away
-- Web Wrappings (item 354112, object 1345165): Bloodmyst Isle, source pins(dump), height: floor of nearest gameobject 12.4 yd away
-- Charstone Warband (item 500821, object 1345022): Burning Steppes, source pins(dump), height: floor of nearest gameobject 5.1 yd away
-- Ring of Embered Thought (item 500820, object 1345115): Burning Steppes, source pins(dump), height: floor of nearest gameobject 4.6 yd away
-- Icehide Cloak (item 500663, object 1345074): Dun Morogh, source pins(dump), height: floor of nearest gameobject 13.5 yd away
-- Fullmoon Howl (item 450582, object 1345057): Duskwood, source pins(dump), height: floor of nearest creature 7.1 yd away
-- Loded Ring (item 1388656, object 1345087): Eastern Plaguelands, source pins(dump), height: floor of nearest creature 7.5 yd away
-- Deadtooth (item 450521, object 1345032): Elwynn Forest, source pins(dump), height: floor of nearest gameobject 7.1 yd away
-- Goldshire Traveler's Boots (item 500814, object 1345061): Elwynn Forest, source pins(dump), height: floor of nearest gameobject 2.8 yd away
-- Decayed Cape (item 521044, object 1345035): Eversong Woods, source pins(dump), height: floor of nearest creature 2.1 yd away
-- Scourgewarped Bow (item 354069, object 254176): Eversong Woods, source pins(dump), height: floor of nearest gameobject 9.3 yd away
-- Blackpaw Scavenger Pick (item 450631, object 90361): Ghostlands, source pins(dump), height: floor of nearest creature 4.2 yd away
-- Blight Infused Mantle (item 521179, object 1345010): Ghostlands, source pins(dump), height: floor of nearest creature 3.7 yd away
-- Blight Potion (item 450626, object 90354): Ghostlands, source pins(dump), height: floor of nearest creature 0.9 yd away
-- Fallen Eye Jewel (item 450633, object 1345050): Ghostlands, source pins(dump), height: floor of nearest creature 4.9 yd away
-- Morin's Jug (item 500811, object 1345092): Hillsbrad Foothills, source pins(dump), height: floor of nearest creature 4.8 yd away
-- Durnar's Stein (item 500810, object 1345041): Loch Modan, source pins(dump), height: floor of nearest gameobject 2.5 yd away
-- Bonechopper (item 217842, object 1345016): Searing Gorge, source pins(dump), height: floor of nearest creature 14.7 yd away
-- Shadewell Stabber (item 824384, object 520066): ShadewellSpring, source pins(dump), height: recorded live height
-- Northpoint Helmet (item 1388940, object 1345098): Silithus, source pins(dump), height: floor of nearest gameobject 0.4 yd away
-- Apprentice's Cane (item 217843, object 1345007): Stranglethorn Vale, source pins(dump), height: floor of nearest gameobject 4.8 yd away
-- Dustworn Saber (item 217844, object 1345043): Stranglethorn Vale, source pins(dump), height: floor of nearest creature 4.1 yd away
-- Junglewood Recurve (item 217851, object 1345080): Stranglethorn Vale, source pins(dump), height: floor of nearest creature 2.9 yd away
-- Shockzip's Saw Blade (item 500658, object 1345126): Stranglethorn Vale, source pins(dump), height: floor of nearest gameobject 12.5 yd away
-- Apothecary's Lantern (item 1379103, object 1345004): Tanaris, source pins(dump), height: floor of nearest gameobject 2.1 yd away
-- String of Ears (item 1388738, object 1345143): The Barrens, source pins(dump), height: floor of nearest gameobject 2.9 yd away
-- Defias Turncoat's Jerkin (item 500815, object 1345037): Westfall, source pins(dump), height: floor of nearest gameobject 7.2 yd away
-- Grunir's Mug (item 500809, object 1345064): Wetlands, source pins(dump), height: floor of nearest creature 8.2 yd away
-- Cloak of Owlkin Feathers (item 354064, object 1345023): ammenvalestart, source pins(dump), height: floor of nearest creature 11.2 yd away
-- Totem of the Vale (item 354068, object 254156): ammenvalestart, source pins(dump), height: floor of nearest creature 5.0 yd away
-- Vial of Dread Water (item 1378929, object 1345161): lowerblackrockmountain, source pins(dump), height: floor of nearest gameobject 4.9 yd away
DELETE FROM `gameobject` WHERE `guid` BETWEEN 6975000 AND 6975036;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(6975000, 1345121, 0, 0, 0, 1, 1, -77.5, -333.5, 136.47, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Scholar''s Ring of Enlightenment'),
(6975001, 1345051, 0, 0, 0, 1, 1, -1134.8, -2357.1, 52.03, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Farstrider''s Grips'),
(6975002, 1345001, 530, 0, 0, 1, 1, -4799.7, -12397.0, 0.63, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Alliance Cord'),
(6975003, 1345052, 530, 0, 0, 1, 1, -4977.5, -11193.9, 16.93, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Feathered Pants'),
(6975004, 1345141, 530, 0, 0, 1, 1, -3374.0, -12273.7, 21.46, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Stillpine Gavel'),
(6975005, 254221, 530, 0, 0, 1, 1, -1490.8, -11199.1, -1.52, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Bloodwashed Gloves'),
(6975006, 1345096, 530, 0, 0, 1, 1, -2563.2, -11494.9, 30.56, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Mystwood Glaive'),
(6975007, 1345165, 530, 0, 0, 1, 1, -1388.8, -10666.4, 86.09, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Web Wrappings'),
(6975008, 1345022, 0, 0, 0, 1, 1, -7981.2, -2111.9, 128.25, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Charstone Warband'),
(6975009, 1345115, 0, 0, 0, 1, 1, -8145.4, -2004.4, 134.12, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Ring of Embered Thought'),
(6975010, 1345074, 0, 0, 0, 1, 1, -5841.5, -1111.5, 382.18, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Icehide Cloak'),
(6975011, 1345057, 0, 0, 0, 1, 1, -10204.3, -69.3, 33.75, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Fullmoon Howl'),
(6975012, 1345087, 0, 0, 0, 1, 1, 2230.4, -5339.3, 84.71, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Loded Ring'),
(6975013, 1345032, 0, 0, 0, 1, 1, -9768.1, -1553.3, 41.48, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Deadtooth'),
(6975014, 1345061, 0, 0, 0, 1, 1, -9332.4, -1335.7, 64.41, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Goldshire Traveler''s Boots'),
(6975015, 1345035, 530, 0, 0, 1, 1, 9095.2, -6426.5, 1.03, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Decayed Cape'),
(6975016, 254176, 530, 0, 0, 1, 1, 9032.8, -6970.2, 14.42, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Scourgewarped Bow'),
(6975017, 90361, 530, 0, 0, 1, 1, 7016.6, -6256.5, 46.79, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Blackpaw Scavenger Pick'),
(6975018, 1345010, 530, 0, 0, 1, 1, 6289.7, -6362.1, 79.56, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Blight Infused Mantle'),
(6975019, 90354, 530, 0, 0, 1, 1, 6480.5, -6290.2, 48.92, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Blight Potion'),
(6975020, 1345050, 530, 0, 0, 1, 1, 8057.4, -7869.2, 180.52, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Fallen Eye Jewel'),
(6975021, 1345092, 0, 0, 0, 1, 1, -716.4, -528.4, 23.80, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Morin''s Jug'),
(6975022, 1345041, 0, 0, 0, 1, 1, -4971.7, -3143.8, 321.72, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Durnar''s Stein'),
(6975023, 1345016, 0, 0, 0, 1, 1, -6770.6, -1073.7, 241.96, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Bonechopper'),
(6975024, 520066, 0, 0, 0, 1, 1, -8547.0, -517.5, 146.44, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Shadewell Stabber'),
(6975025, 1345098, 1, 0, 0, 1, 1, -6846.5, 751.1, 42.54, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Northpoint Helmet'),
(6975026, 1345007, 0, 0, 0, 1, 1, -12371.0, -782.4, 31.24, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Apprentice''s Cane'),
(6975027, 1345043, 0, 0, 0, 1, 1, -12344.7, -1112.3, 1.53, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Dustworn Saber'),
(6975028, 1345080, 0, 0, 0, 1, 1, -13481.8, 179.0, 42.75, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Junglewood Recurve'),
(6975029, 1345126, 0, 0, 0, 1, 1, -12253.6, -867.9, 22.88, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Shockzip''s Saw Blade'),
(6975030, 1345004, 1, 0, 0, 1, 1, -7189.7, -3793.6, 9.01, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Apothecary''s Lantern'),
(6975031, 1345143, 1, 0, 0, 1, 1, -945.4, -3699.4, 7.04, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged String of Ears'),
(6975032, 1345037, 0, 0, 0, 1, 1, -9854.7, 1295.5, 41.89, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Defias Turncoat''s Jerkin'),
(6975033, 1345064, 0, 0, 0, 1, 1, -3240.2, -950.3, 9.90, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Grunir''s Mug'),
(6975034, 1345023, 530, 0, 0, 1, 1, -4466.3, -14107.9, 109.42, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Cloak of Owlkin Feathers'),
(6975035, 254156, 530, 0, 0, 1, 1, -3755.1, -13331.1, 83.24, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Totem of the Vale'),
(6975036, 1345161, 0, 0, 0, 1, 1, -7189.6, -893.7, 165.80, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', NULL, 'Worldforged Vial of Dread Water');
