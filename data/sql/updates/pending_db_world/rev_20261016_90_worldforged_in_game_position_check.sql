-- CoA worldforged: in-game position check (batch 1)
-- Each pickup was visited in game: the spot reported by the community find data
-- (Ascension Sidekick, LootCollector, Wforged, HandyNotes) was checked, the exact
-- position read with .gps, and the pickup moved there with .gobject move.
-- A move only applies while the pickup is still at the position it had on main
-- (2026-10-16), so a newer correction to the same pickup is never overwritten.
-- Rows marked 'reachable spot' were reported somewhere a player cannot reach and
-- stand at the nearest reachable spot instead. Orientation is unchanged.

-- Alterac Mountains
-- Argent Sentry Pauldrons (6940076): 4492.0 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = 271.53, `position_y` = -174.83, `position_z` = 159.95 WHERE `guid` = 6940076 AND `position_x` BETWEEN -3918.3 AND -3917.3 AND `position_y` BETWEEN -1796.2 AND -1795.2;
-- Eboncrypt Band (6940415): 4093.3 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 1190.15, `position_y` = 31.62, `position_z` = -5.98 WHERE `guid` = 6940415 AND `position_x` BETWEEN -2605.7 AND -2604.7 AND `position_y` BETWEEN -1502.1 AND -1501.1;
-- Forbidden Fruit (6940494): 4668.3 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 8.9, `position_y` = -273.5, `position_z` = 192.56 WHERE `guid` = 6940494 AND `position_x` BETWEEN -4350.1 AND -4349.1 AND `position_y` BETWEEN -1946.3 AND -1945.3;
-- Quel'thalas Commander Aegis (6940919): 4178.8 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 1239.74, `position_y` = -565.07, `position_z` = 69.11 WHERE `guid` = 6940919 AND `position_x` BETWEEN -2525.2 AND -2524.2 AND `position_y` BETWEEN -2379.7 AND -2378.7;
-- Red Metal Pauldrons (6940945): 4101.4 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 1020.27, `position_y` = 467.8, `position_z` = 12.43 WHERE `guid` = 6940945 AND `position_x` BETWEEN -2861.0 AND -2860.0 AND `position_y` BETWEEN -859.8 AND -858.8;
-- Arathi Highlands
-- Lookout Scope (6940713): 3103.6 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -1999.46, `position_y` = -3947.84, `position_z` = 48.4 WHERE `guid` = 6940713 AND `position_x` BETWEEN 25.4 AND 26.4 AND `position_y` BETWEEN -1596.7 AND -1595.7;
-- Party Pants (6940868): 2738.5 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -1885.16, `position_y` = -1734.62, `position_z` = 98.24 WHERE `guid` = 6940868 AND `position_x` BETWEEN 137.3 AND 138.3 AND `position_y` BETWEEN 110.7 AND 111.7;
-- Stormwind Memento (6941166): 8141.2 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -1366, `position_y` = -3549.6, `position_z` = 81.99 WHERE `guid` = 6941166 AND `position_x` BETWEEN -9120.1 AND -9119.1 AND `position_y` BETWEEN -1068.0 AND -1067.0;
-- Syndiclap (6940589): 22.4 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -784.57, `position_y` = -2087.02, `position_z` = 35.25 WHERE `guid` = 6940589 AND `position_x` BETWEEN -781.1 AND -780.1 AND `position_y` BETWEEN -2065.5 AND -2064.5;
-- Watchguard's Prized Plate (6940996): 5.0 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -1724.52, `position_y` = -1833.04, `position_z` = 81.15 WHERE `guid` = 6940996 AND `position_x` BETWEEN -1724.7 AND -1723.7 AND `position_y` BETWEEN -1838.5 AND -1837.5;
-- Badlands
-- Boar Harvester (6940161): 7655.7 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -7185.86, `position_y` = -2938.43, `position_z` = 299.74 WHERE `guid` = 6940161 AND `position_x` BETWEEN -49.3 AND -48.3 AND `position_y` BETWEEN -169.2 AND -168.2;
-- Deflector's Wargreaves (6941147): 5204.5 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -7246.3, `position_y` = -2318.5, `position_z` = 244.58 WHERE `guid` = 6941147 AND `position_x` BETWEEN -12396.1 AND -12395.1 AND `position_y` BETWEEN -1563.1 AND -1562.1;
-- Enchanted Straw Appendage (6940440): 7698.3 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -7203.61, `position_y` = -3793.8, `position_z` = 368.5 WHERE `guid` = 6940440 AND `position_x` BETWEEN 25.4 AND 26.4 AND `position_y` BETWEEN -1148.8 AND -1147.8;
-- Heavy Logsplitter (6940610): 3762.6 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -6949.4, `position_y` = -4143.36, `position_z` = 352.87 WHERE `guid` = 6940610 AND `position_x` BETWEEN -9426.1 AND -9425.1 AND `position_y` BETWEEN -1310.9 AND -1309.9;
-- Mauled Armplates (6940747): 7721.2 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6967.9, `position_y` = -3874.5, `position_z` = 284.62 WHERE `guid` = 6940747 AND `position_x` BETWEEN 286.6 AND 287.6 AND `position_y` BETWEEN -1232.8 AND -1231.8;
-- Murloc Voodoo Doll (6940789): 7666.2 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -7311.9, `position_y` = -4013.4, `position_z` = 375.98 WHERE `guid` = 6940789 AND `position_x` BETWEEN -105.3 AND -104.3 AND `position_y` BETWEEN -1400.7 AND -1399.7;
-- Riding Cloak (6940962): 7702.4 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6996.7, `position_y` = -4150.9, `position_z` = 330.42 WHERE `guid` = 6940962 AND `position_x` BETWEEN 249.3 AND 250.3 AND `position_y` BETWEEN -1540.7 AND -1539.7;
-- Silkwrapped Cloak (6941081): 3506.1 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6315.9, `position_y` = -2827, `position_z` = 431.17 WHERE `guid` = 6941081 AND `position_x` BETWEEN -4731.1 AND -4730.1 AND `position_y` BETWEEN 299.7 AND 300.7;
-- Tombscarred Guardian (6941265): 28.1 yd, sources: Sidekick
UPDATE `gameobject` SET `position_x` = -7071.5, `position_y` = -3481.1, `position_z` = 242.18 WHERE `guid` = 6941265 AND `position_x` BETWEEN -7045.3 AND -7044.3 AND `position_y` BETWEEN -3472.7 AND -3471.7;
-- Blasted Lands
-- Ogre Finger Sleeve (6940820): 28.9 yd, sources: HandyNotes, Wforged
UPDATE `gameobject` SET `position_x` = -10842.3, `position_y` = -2723.4, `position_z` = 7.63 WHERE `guid` = 6940820 AND `position_x` BETWEEN -10856.9 AND -10855.9 AND `position_y` BETWEEN -2698.7 AND -2697.7;
-- Burning Steppes
-- Firegut Emblem (6940837): 69.5 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -7714, `position_y` = -2872.3, `position_z` = 133.43 WHERE `guid` = 6940837 AND `position_x` BETWEEN -7733.4 AND -7732.4 AND `position_y` BETWEEN -2805.9 AND -2804.9;
-- Coldridge Valley
-- Radiant Rifle (6940924): 39.2 yd, sources: Wforged
UPDATE `gameobject` SET `position_x` = -5937, `position_y` = 458.6, `position_z` = 508.38 WHERE `guid` = 6940924 AND `position_x` BETWEEN -5962.2 AND -5961.2 AND `position_y` BETWEEN 427.7 AND 428.7;
-- Deadwind Pass
-- Mongrel Blade (6940763): 2657.7 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -11043.5, `position_y` = -1916.3, `position_z` = 49.64 WHERE `guid` = 6940763 AND `position_x` BETWEEN -8414.9 AND -8413.9 AND `position_y` BETWEEN -1528.0 AND -1527.0;
-- Old War Tome (6940850): 2665.6 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10982.4, `position_y` = -1597.2, `position_z` = 205.89 WHERE `guid` = 6940850 AND `position_x` BETWEEN -8355.0 AND -8354.0 AND `position_y` BETWEEN -1151.1 AND -1150.1;
-- Ring of the Lexicon (6940967): 2697.4 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -10671.81, `position_y` = -2884.69, `position_z` = 85.99 WHERE `guid` = 6940967 AND `position_x` BETWEEN -7989.0 AND -7988.0 AND `position_y` BETWEEN -2610.0 AND -2609.0;
-- Shadowhide Claw (6941057): 2690.1 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -10861.59, `position_y` = -2619.91, `position_z` = 7.63 WHERE `guid` = 6941057 AND `position_x` BETWEEN -8183.2 AND -8182.2 AND `position_y` BETWEEN -2375.4 AND -2374.4;
-- Stolen Ilgalar Neckpiece (6941149): 1203.0 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10115.44, `position_y` = -1527.78, `position_z` = 24.81 WHERE `guid` = 6941149 AND `position_x` BETWEEN -9589.9 AND -9588.9 AND `position_y` BETWEEN -2610.1 AND -2609.1;
-- Stonewatch Handwraps (6941164): 2699.0 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10750.6, `position_y` = -2562, `position_z` = 119.89 WHERE `guid` = 6941164 AND `position_x` BETWEEN -8066.1 AND -8065.1 AND `position_y` BETWEEN -2287.5 AND -2286.5;
-- Three Corner Carp (6941233): 2356.9 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -11401.5, `position_y` = -1300.36, `position_z` = 213.33 WHERE `guid` = 6941233 AND `position_x` BETWEEN -9082.3 AND -9081.3 AND `position_y` BETWEEN -883.8 AND -882.8;
-- Deathknell
-- Decayed Sharpshot (6940332): 27.6 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = 1926.1, `position_y` = 1966.9, `position_z` = 156.64 WHERE `guid` = 6940332 AND `position_x` BETWEEN 1941.5 AND 1942.5 AND `position_y` BETWEEN 1988.9 AND 1989.9;
-- Shield of Fading Light (6941022): 3148.0 yd, sources: Wforged
UPDATE `gameobject` SET `position_x` = 1774.9, `position_y` = 1400.5, `position_z` = 94.06 WHERE `guid` = 6941022 AND `position_x` BETWEEN 2984.3 AND 2985.3 AND `position_y` BETWEEN -1506.2 AND -1505.2;
-- Dun Morogh
-- Magnus' Mug (6940738): 2.7 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -5612.51, `position_y` = -555.57, `position_z` = 441.54 WHERE `guid` = 6940738 AND `position_x` BETWEEN -5615.2 AND -5614.2 AND `position_y` BETWEEN -557.6 AND -556.6;
-- Duskwood
-- Bone Carver (6941322): 1259.7 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10676.14, `position_y` = -1556.62, `position_z` = 102.85 WHERE `guid` = 6941322 AND `position_x` BETWEEN -11918.1 AND -11917.1 AND `position_y` BETWEEN -1770.8 AND -1769.8;
-- Eastern Plaguelands
-- Deadman's Dagger (6940321): 4952.4 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 2430.12, `position_y` = -4971.12, `position_z` = 73.6 WHERE `guid` = 6940321 AND `position_x` BETWEEN -613.0 AND -612.0 AND `position_y` BETWEEN -1064.1 AND -1063.1;
-- Eroded Pit Fighter Knuckles (6940443): 6004.7 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 2577.19, `position_y` = -5600.8, `position_z` = 188.64 WHERE `guid` = 6940443 AND `position_x` BETWEEN 482.9 AND 483.9 AND `position_y` BETWEEN 26.5 AND 27.5;
-- Havenfire Crown (6940601): 6068.8 yd, sources: HandyNotes, reachable spot
UPDATE `gameobject` SET `position_x` = 3211.55, `position_y` = -3319.45, `position_z` = 161.61 WHERE `guid` = 6940601 AND `position_x` BETWEEN -2513.4 AND -2512.4 AND `position_y` BETWEEN -1304.8 AND -1303.8;
-- Mossy Bag (6940770): 4736.1 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = 1842.1, `position_y` = -3697.7, `position_z` = 158.65 WHERE `guid` = 6940770 AND `position_x` BETWEEN -1221.6 AND -1220.6 AND `position_y` BETWEEN -86.1 AND -85.1;
-- Oracle's Fishy Staff (6960026): 4848.5 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 1848.3, `position_y` = -3759.4, `position_z` = 159.7 WHERE `guid` = 6960026 AND `position_x` BETWEEN 1183.1 AND 1184.1 AND `position_y` BETWEEN 1042.9 AND 1043.9;
-- Plague Purger (6940890): 58.4 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = 3359, `position_y` = -4956.4, `position_z` = 160.05 WHERE `guid` = 6940890 AND `position_x` BETWEEN 3327.2 AND 3328.2 AND `position_y` BETWEEN -4907.6 AND -4906.6;
-- Ray's Farmhand (6960024): 5831.7 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 2769.7, `position_y` = -3631.2, `position_z` = 104.96 WHERE `guid` = 6960024 AND `position_x` BETWEEN 847.7 AND 848.7 AND `position_y` BETWEEN 1874.4 AND 1875.4;
-- Elwynn Forest
-- Apprentice Staff (6940064): 2881.5 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -9930.5, `position_y` = 56.9, `position_z` = 32.81 WHERE `guid` = 6940064 AND `position_x` BETWEEN -7379.3 AND -7378.3 AND `position_y` BETWEEN -1282.3 AND -1281.3;
-- Assisting Hand (6940088): 6113.9 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -8286.65, `position_y` = 385.58, `position_z` = 106.7 WHERE `guid` = 6940088 AND `position_x` BETWEEN -2562.4 AND -2561.4 AND `position_y` BETWEEN -1761.4 AND -1760.4;
-- Deathwhisper Wand (6940326): 6011.1 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -8665, `position_y` = 884.9, `position_z` = 97.7 WHERE `guid` = 6940326 AND `position_x` BETWEEN -3013.2 AND -3012.2 AND `position_y` BETWEEN -1161.3 AND -1160.3;
-- Defias Special Bucket (6940346): 2856.8 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -9991.69, `position_y` = -168, `position_z` = 16.03 WHERE `guid` = 6940346 AND `position_x` BETWEEN -7422.3 AND -7421.3 AND `position_y` BETWEEN -1416.2 AND -1415.2;
-- Gem of Fortitude (6940528): 2392.9 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -8311.18, `position_y` = 182.51, `position_z` = 137.18 WHERE `guid` = 6940528 AND `position_x` BETWEEN -6353.3 AND -6352.3 AND `position_y` BETWEEN -1193.0 AND -1192.0;
-- Heavy Iron Pan (6940609): 35.4 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -9472.4, `position_y` = -3.38, `position_z` = 58.9 WHERE `guid` = 6940609 AND `position_x` BETWEEN -9487.8 AND -9486.8 AND `position_y` BETWEEN -36.0 AND -35.0;
-- Murloc Ritual Staff (6940786): 15.1 yd, sources: HandyNotes, LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -9489.9, `position_y` = -358.4, `position_z` = 56.66 WHERE `guid` = 6940786 AND `position_x` BETWEEN -9490.5 AND -9489.5 AND `position_y` BETWEEN -374.0 AND -373.0;
-- Old Northshire Bolter (6940836): 2467.9 yd, sources: LootCollector, reachable spot
UPDATE `gameobject` SET `position_x` = -8800.32, `position_y` = -495.5, `position_z` = 102 WHERE `guid` = 6940836 AND `position_x` BETWEEN -6647.0 AND -6646.0 AND `position_y` BETWEEN -1700.8 AND -1699.8;
-- Ring of Memorial (6940964): 5821.0 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -9940.2, `position_y` = 313.9, `position_z` = 35.57 WHERE `guid` = 6940964 AND `position_x` BETWEEN -4532.0 AND -4531.0 AND `position_y` BETWEEN -1838.3 AND -1837.3;
-- Loch Modan
-- Abandoned Greatsword (6940005): 23.2 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -5896.96, `position_y` = -3728.74, `position_z` = 367.25 WHERE `guid` = 6940005 AND `position_x` BETWEEN -5879.4 AND -5878.4 AND `position_y` BETWEEN -3714.7 AND -3713.7;
-- Ogre Loincloth (6940251): 44.2 yd, sources: Wforged
UPDATE `gameobject` SET `position_x` = -4777.06, `position_y` = -4148.81, `position_z` = 391.34 WHERE `guid` = 6940251 AND `position_x` BETWEEN -4754.3 AND -4753.3 AND `position_y` BETWEEN -4186.9 AND -4185.9;
-- Ol' Blunderbuss (6940827): 35.0 yd, sources: Sidekick
UPDATE `gameobject` SET `position_x` = -4739.9, `position_y` = -3364.53, `position_z` = 310.5 WHERE `guid` = 6940827 AND `position_x` BETWEEN -4728.9 AND -4727.9 AND `position_y` BETWEEN -3398.1 AND -3397.1;
-- Northshire Valley
-- Brother's Special Gift (6940195): 4524.6 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -9017.8, `position_y` = -318.9, `position_z` = 74.52 WHERE `guid` = 6940195 AND `position_x` BETWEEN -5757.1 AND -5756.1 AND `position_y` BETWEEN -3455.8 AND -3454.8;
-- Galgosh's Other Bone (6940522): 9520.8 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -8996.88, `position_y` = -470.83, `position_z` = 84 WHERE `guid` = 6940522 AND `position_x` BETWEEN -234.0 AND -233.0 AND `position_y` BETWEEN -4192.7 AND -4191.7;
-- Heavy Ogre Axe (6940613): 10283.4 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -8727.2, `position_y` = -478.6, `position_z` = 142 WHERE `guid` = 6940613 AND `position_x` BETWEEN 845.8 AND 846.8 AND `position_y` BETWEEN -4233.5 AND -4232.5;
-- Large Buzzard Talon (6940690): 9516.6 yd, sources: LootCollector, Sidekick, reachable spot
UPDATE `gameobject` SET `position_x` = -9086.22, `position_y` = -523.41, `position_z` = 103 WHERE `guid` = 6940690 AND `position_x` BETWEEN -459.0 AND -458.0 AND `position_y` BETWEEN -4540.0 AND -4539.0;
-- Old Stitched Bindings (6940844): 9737.9 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -8824.17, `position_y` = -194.04, `position_z` = 82.29 WHERE `guid` = 6940844 AND `position_x` BETWEEN 464.8 AND 465.8 AND `position_y` BETWEEN -3115.5 AND -3114.5;
-- Scrap Shield (6941036): 9795.2 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -8883.3, `position_y` = -420.6, `position_z` = 65.1 WHERE `guid` = 6941036 AND `position_x` BETWEEN 233.8 AND 234.8 AND `position_y` BETWEEN -4001.0 AND -4000.0;
-- Sinter Wive's Rope (6941087): 9882.8 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -8821, `position_y` = -348.8, `position_z` = 68.42 WHERE `guid` = 6941087 AND `position_x` BETWEEN 465.8 AND 466.8 AND `position_y` BETWEEN -3728.0 AND -3727.0;
-- Spider Silk Vestments (6941130): 9912.5 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -8908.72, `position_y` = -589.57, `position_z` = 243.67 WHERE `guid` = 6941130 AND `position_x` BETWEEN 131.2 AND 132.2 AND `position_y` BETWEEN -4655.5 AND -4654.5;
-- Redridge Mountains
-- Old Redridge Buckler (6940839): 31.8 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -9605.7, `position_y` = -3500.8, `position_z` = 121.95 WHERE `guid` = 6940839 AND `position_x` BETWEEN -9632.6 AND -9631.6 AND `position_y` BETWEEN -3483.5 AND -3482.5;
-- Searing Gorge
-- Dorius' Shield (6940374): 25.2 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = -6981.5, `position_y` = -1736.9, `position_z` = 241.78 WHERE `guid` = 6940374 AND `position_x` BETWEEN -7005.0 AND -7004.0 AND `position_y` BETWEEN -1747.6 AND -1746.6;
-- Drowned Pendant (6940385): 7572.5 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6524.49, `position_y` = -1616.15, `position_z` = 302.41 WHERE `guid` = 6940385 AND `position_x` BETWEEN 723.9 AND 724.9 AND `position_y` BETWEEN -3806.6 AND -3805.6;
-- Dwarven Mail Gauntlets (6940403): 7151.3 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6953.42, `position_y` = -919.43, `position_z` = 259.36 WHERE `guid` = 6940403 AND `position_x` BETWEEN 2.9 AND 3.9 AND `position_y` BETWEEN -2576.5 AND -2575.5;
-- Frayed Backwrap (6940508): 2319.1 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6749.3, `position_y` = -890.7, `position_z` = 263.31 WHERE `guid` = 6940508 AND `position_x` BETWEEN -5291.7 AND -5290.7 AND `position_y` BETWEEN -2694.6 AND -2693.6;
-- Stolen Mountaineer Chest (6941152): 6971.9 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -7239.27, `position_y` = -1099.99, `position_z` = 267.6 WHERE `guid` = 6941152 AND `position_x` BETWEEN -510.3 AND -509.3 AND `position_y` BETWEEN -2923.0 AND -2922.0;
-- Stoneflow Handwraps (6941159): 2542.8 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6731.1, `position_y` = -2052.8, `position_z` = 346.2 WHERE `guid` = 6941159 AND `position_x` BETWEEN -5268.9 AND -5267.9 AND `position_y` BETWEEN -4133.4 AND -4132.4;
-- Sword of Stone (6941186): 7149.9 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -7003.3, `position_y` = -1140.5, `position_z` = 242.03 WHERE `guid` = 6941186 AND `position_x` BETWEEN -99.8 AND -98.8 AND `position_y` BETWEEN -3000.0 AND -2999.0;
-- Vermin Staff (6941298): 7404.4 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -6570.5, `position_y` = -913.7, `position_z` = 276.43 WHERE `guid` = 6941298 AND `position_x` BETWEEN 644.4 AND 645.4 AND `position_y` BETWEEN -2576.5 AND -2575.5;
-- Silverpine Forest
-- Darkstrand Kilt (6940313): 45.8 yd, sources: HandyNotes, Wforged
UPDATE `gameobject` SET `position_x` = 1053.5, `position_y` = 1596.4, `position_z` = 29.06 WHERE `guid` = 6940313 AND `position_x` BETWEEN 1094.5 AND 1095.5 AND `position_y` BETWEEN 1576.5 AND 1577.5;
-- Gnoll Subjugator (6942549): 29.2 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = 1007.86, `position_y` = 719, `position_z` = 61 WHERE `guid` = 6942549 AND `position_x` BETWEEN 1006.9 AND 1007.9 AND `position_y` BETWEEN 689.3 AND 690.3;
-- Stranglethorn Vale
-- Wild Tracker Bindings (6941337): 12791.7 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -13335.2, `position_y` = -427.5, `position_z` = 17.45 WHERE `guid` = 6941337 AND `position_x` BETWEEN -1021.5 AND -1020.5 AND `position_y` BETWEEN -3890.5 AND -3889.5;
-- Swamp of Sorrows
-- Chain Belt of the Elements (6940230): 5005.2 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10283.1, `position_y` = -3069.2, `position_z` = 22.02 WHERE `guid` = 6940230 AND `position_x` BETWEEN -5278.7 AND -5277.7 AND `position_y` BETWEEN -3014.3 AND -3013.3;
-- Gilnean Lance (6940543): 4973.1 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10416.9, `position_y` = -3219.6, `position_z` = 20.75 WHERE `guid` = 6940543 AND `position_x` BETWEEN -5444.3 AND -5443.3 AND `position_y` BETWEEN -3204.7 AND -3203.7;
-- Grimson Cloak (6940578): 4990.8 yd, sources: LootCollector
UPDATE `gameobject` SET `position_x` = -10305.6, `position_y` = -3551.1, `position_z` = 22.93 WHERE `guid` = 6940578 AND `position_x` BETWEEN -5315.5 AND -5314.5 AND `position_y` BETWEEN -3593.7 AND -3592.7;
-- Kul Tiras Armplates (6940686): 3698.1 yd, sources: HandyNotes
UPDATE `gameobject` SET `position_x` = -10506.4, `position_y` = -2916.7, `position_z` = 22.78 WHERE `guid` = 6940686 AND `position_x` BETWEEN -6866.6 AND -6865.6 AND `position_y` BETWEEN -3568.7 AND -3567.7;
-- Western Plaguelands
-- Brightflame Codex (6940186): 88.9 yd, sources: LootCollector, Sidekick
UPDATE `gameobject` SET `position_x` = 2506.4, `position_y` = -1647.9, `position_z` = 112.75 WHERE `guid` = 6940186 AND `position_x` BETWEEN 2594.8 AND 2595.8 AND `position_y` BETWEEN -1647.6 AND -1646.6;
