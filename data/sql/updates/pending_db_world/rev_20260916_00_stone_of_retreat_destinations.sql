-- Stone of Retreat teleport destinations (spell_target_position).
-- Hub coordinates stay exactly as the world `.tele` table defines them. Where the
-- hub point sat up to 3 yd below the walkable floor that the server itself places
-- creatures/objects on, the landing is lifted onto that floor plus 0.5 yd of
-- clearance, so a stone can never drop the player inside the ground it lands on.
-- Generated from spawn evidence (3D-nearest) and the .map terrain grids.
-- Rows are idempotent REPLACE statements.
--
-- Audit pass 2 (terrain surface + canonical teleport table):
--   * every untouched row was re-checked against the server's own .map terrain
--     surface, read with a reader validated on 3,700 samples to a median error of
--     0.10 yd against creature spawn Z;
--   * 15 of the 21 rows below flagged LEVEL-*/NO-EVIDENCE turned out to sit exactly
--     ON the terrain surface (dz 0.00) - the earlier flag only meant that the
--     nearest placed object was a structure above the landing, not that the point
--     was buried;
--   * all 21 are byte-identical to a row in the server's own `game_tele` table, i.e.
--     the exact spot `.tele <hub>` puts a GM. The apparent level differences are
--     carved interiors (Undercity's tunnel, Blackrock's inside), floating cities
--     (Dalaran, Orgrimmar's plateau), instance terraces (Icecrown Citadel,
--     Onyxia's Lair) and the Thondroril River bridge deck - all intended.
--   * Undercity and Theramore Isle were confirmed in game as landing correctly.
--   Verdicts: LIFTED = z raised onto the local floor; ON-FLOOR/ON-TERRAIN = already
--   matched the walkable surface; LEVEL-*/INTERIOR/BRIDGE-* = structure or sub-level
--   landing, left exactly as .tele defines it.

-- LIFTED             Stone of Retreat: Warsong Hold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76876, 0, 571, 2741.2900, 6097.1600, 78.4291, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Valiance Keep
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76877, 0, 571, 2213.9500, 5273.1500, 11.2565, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: Coldarra
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76878, 0, 571, 4155.5500, 6962.6900, 164.6710, 0.00, 0);

-- LIFTED             Stone of Retreat: Unu'pe
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76879, 0, 571, 2925.0200, 4065.6300, 2.6418, 0.00, 0);

-- LIFTED             Stone of Retreat: Vengeance Landing
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76880, 0, 571, 1942.8600, -6167.1100, 24.5417, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: New Agamand
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76881, 0, 571, 424.4050, -4548.7600, 245.6520, 0.00, 0);

-- LIFTED             Stone of Retreat: Utgarde Keep
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76882, 0, 571, 1219.7200, -4865.2800, 43.5614, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Valgarde
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76883, 0, 571, 564.4010, -4944.9400, 18.5962, 0.00, 0);

-- LIFTED             Stone of Retreat: Westguard Keep
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76884, 0, 571, 1391.0400, -3284.6300, 167.2920, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Naxxramas (Dragonblight)
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76885, 0, 571, 3668.7200, -1262.4600, 243.6220, 0.00, 0);

-- LIFTED             Stone of Retreat: Wintergarde Keep
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76886, 0, 571, 3682.7100, -722.6350, 213.8760, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Wyrmrest Temple
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76887, 0, 571, 3556.2200, 264.5140, 342.7220, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Moa'ki Harbor
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76888, 0, 571, 2713.0200, 902.5810, 4.6095, 0.00, 0);

-- LIFTED             Stone of Retreat: Agmar's Hammer
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76889, 0, 571, 3841.5100, 1534.0400, 90.8701, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Azjol-Nerub
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76890, 0, 571, 3677.5300, 2166.7000, 35.8080, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Venture Bay
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76891, 0, 571, 2792.2000, -1972.3600, 10.8207, 0.00, 0);

-- LEVEL-BELOW/TRIGGER Stone of Retreat: Conquest Hold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76892, 0, 571, 3251.8600, -2244.9800, 114.5550, 0.00, 0);

-- LIFTED             Stone of Retreat: Westfall Brigade Encampment
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76893, 0, 571, 4529.5900, -4233.9300, 170.9920, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: The Argent Stand
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76894, 0, 571, 5450.3800, -2422.6500, 292.4190, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Drak'Tharon Keep
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76895, 0, 571, 4774.6000, -2032.9200, 229.1500, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Gundrak
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76896, 0, 571, 6898.7200, -4584.9400, 451.1200, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Lakeside Landing
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76897, 0, 571, 5501.4700, 4733.0000, -194.3760, 0.00, 0);

-- LIFTED             Stone of Retreat: Nesingwary Base Camp
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76898, 0, 571, 5561.6900, 5748.6500, -74.8992, 0.00, 0);

-- ON-TERRAIN        Stone of Retreat: Ulduar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76899, 0, 571, 9214.6300, -1110.8200, 1216.1200, 0.00, 0);

-- LIFTED             Stone of Retreat: K3
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76900, 0, 571, 6123.7000, -1059.1900, 404.9740, 0.00, 0);

-- LIFTED             Stone of Retreat: Grom'arsh Crash-Site
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76901, 0, 571, 7843.9000, -796.8260, 1185.1700, 0.00, 0);

-- LIFTED             Stone of Retreat: Frosthold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76902, 0, 571, 6666.4300, -211.3410, 951.1550, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Brunnhildar Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76903, 0, 571, 7056.3700, -1698.0000, 821.5950, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: Dun Niffelem
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76904, 0, 571, 7165.4200, -2729.0100, 776.7700, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Argent Tournament Grounds
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76905, 0, 571, 8515.8900, 629.2500, 547.3960, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: The Shadow Vault
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76906, 0, 571, 8427.8800, 2706.3300, 655.0950, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Blackwatch
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76907, 0, 571, 6654.1500, 3224.6600, 810.5010, 0.00, 0);

-- LEVEL-ABOVE        Stone of Retreat: Icecrown Citadel
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76908, 0, 571, 5873.8200, 2110.9800, 636.0110, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: The Argent Vanguard
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76909, 0, 571, 6216.6800, -2.7300, 410.1650, 0.00, 0);

-- LIFTED             Stone of Retreat: Zim'Torga
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76910, 0, 571, 5757.2100, -3528.2200, 388.9870, 0.00, 0);

-- LEVEL-BELOW/TRIGGER Stone of Retreat: Amberpine Lodge
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76911, 0, 571, 3412.8800, -2791.1700, 201.5210, 0.00, 0);

-- LEVEL-BELOW/TRIGGER Stone of Retreat: Camp Oneqwah
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76912, 0, 571, 3848.7000, -4543.4600, 209.2780, 0.00, 0);

-- LIFTED             Stone of Retreat: Camp Winterhoof
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76913, 0, 571, 2649.8200, -4362.6900, 278.0070, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Stars' Rest
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76914, 0, 571, 3480.7000, 2000.0600, 64.9750, 0.00, 0);

-- LIFTED             Stone of Retreat: Venomspite
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76915, 0, 571, 3241.2900, -699.7670, 167.9520, 0.00, 0);

-- LIFTED             Stone of Retreat: Talonbranch Glade
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76916, 0, 1, 6209.5100, -1927.0100, 570.2180, 0.00, 0);

-- BRIDGE-DECK       Stone of Retreat: Thondroril River
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76917, 0, 0, 1925.0800, -2621.3100, 62.2875, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Chillwind Camp
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (76918, 0, 0, 967.9640, -1443.9900, 65.0399, 0.00, 0);

-- LIFTED             Stone of Retreat: Allerian Stronghold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102178, 0, 530, -2949.2700, 3958.3200, 1.5612, 0.00, 0);

-- LIFTED             Stone of Retreat: Altar of Shatar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102179, 0, 530, -3053.9600, 828.8960, -8.9849, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Cenarion Refuge
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102180, 0, 530, -223.5410, 5487.9900, 23.2281, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Cosmowrench
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102181, 0, 530, 2988.2100, 1806.9000, 139.0710, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Evergrove
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102182, 0, 530, 2976.8500, 5511.0100, 144.6370, 0.00, 0);

-- LIFTED             Stone of Retreat: Falcon Watch
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102183, 0, 530, -600.7820, 4100.1000, 91.7013, 0.00, 0);

-- LIFTED             Stone of Retreat: Garadar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102184, 0, 530, -1321.3400, 7239.1200, 33.6456, 0.00, 0);

-- LIFTED             Stone of Retreat: Honor Hold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102185, 0, 530, -748.2110, 2681.5200, 101.8570, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Ogri'la
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102186, 0, 530, 2297.6800, 7293.1200, 365.6170, 0.00, 0);

-- LIFTED             Stone of Retreat: Orebor Harborage
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102187, 0, 530, 958.6600, 7374.0200, 29.0269, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Sanctum of the Stars
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102188, 0, 530, -4115.5100, 1120.5400, 44.5242, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Shadowmoon Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102189, 0, 530, -2998.6600, 2568.9000, 76.6306, 0.00, 0);

-- LIFTED             Stone of Retreat: Stonebreaker Hold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102190, 0, 530, -2640.0800, 4404.3800, 36.6808, 0.00, 0);

-- LIFTED             Stone of Retreat: Swamprat Post
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102191, 0, 530, 104.5340, 5199.3100, 22.2179, 0.00, 0);

-- LIFTED             Stone of Retreat: Sylvanaar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102192, 0, 530, 2018.9100, 6854.4700, 174.8390, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Telaar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102193, 0, 530, -2560.7600, 7300.7200, 13.9485, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Telredor
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102194, 0, 530, 278.5820, 6001.2700, 144.7300, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Temple of Telhamat
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102195, 0, 530, 78.9769, 4333.5800, 101.5530, 0.00, 0);

-- LIFTED             Stone of Retreat: The Stormspire
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102196, 0, 530, 4150.1900, 3015.9200, 341.7940, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Thrallmar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102197, 0, 530, 156.2510, 2673.4500, 85.1587, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Thunderlord Stronghold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102198, 0, 530, 2314.7500, 6041.9600, 142.4170, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Toshley's Station
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102199, 0, 530, 1910.6300, 5556.2500, 263.0170, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Wildhammer Stronghold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102200, 0, 530, -3989.4700, 2168.3900, 105.3500, 0.00, 0);

-- LIFTED             Stone of Retreat: Zabra'jin
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (102201, 0, 530, 260.2800, 7860.4000, 24.6461, 0.00, 0);

-- LEVEL-BELOW/TRIGGER Stone of Retreat: Orgrimmar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777000, 0, 1, 1629.8500, -4373.6400, 31.5573, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: Undercity
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777001, 0, 0, 1584.1400, 240.3080, -52.1534, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Thunder Bluff
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777002, 0, 1, -1277.3700, 124.8040, 131.2870, 0.00, 0);

-- LIFTED             Stone of Retreat: Stormwind
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777003, 0, 0, -8833.3800, 628.6280, 94.8162, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Darnassus
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777004, 0, 1, 9949.5600, 2284.2100, 1341.4000, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Ironforge
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777005, 0, 0, -4918.8800, -940.4060, 501.5640, 0.00, 0);

-- LIFTED             Stone of Retreat: Light's Hope
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777006, 0, 0, 2279.6500, -5310.0100, 88.5198, 0.00, 0);

-- LIFTED             Stone of Retreat: Everlook
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777007, 0, 1, 6725.6900, -4619.4400, 721.9840, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Booty Bay
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777008, 0, 0, -14297.2000, 530.9930, 8.7792, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Gadgetzan
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777009, 0, 1, -7177.1500, -3785.3400, 8.3698, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Ratchet
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777010, 0, 1, -956.6640, -3754.7100, 5.3324, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Thorium Point
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777011, 0, 0, -6506.4700, -1149.9500, 307.7080, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Mudsprocket
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777012, 0, 1, -4573.7900, -3173.1500, 34.0877, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Cenarion Hold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777013, 0, 1, -6818.0900, 733.8140, 41.5661, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Silvermoon City
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777014, 0, 530, 9487.6900, -7279.2000, 14.2866, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: The Exodar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777015, 0, 530, -3965.7000, -11653.6000, -138.8440, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Shattrath
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777016, 0, 530, -1838.1600, 5301.7900, -12.4280, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Area 52
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777017, 0, 530, 3043.3300, 3681.3300, 143.0650, 0.00, 0);

-- LIFTED             Stone of Retreat: Altar of Sha'tar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777018, 0, 530, -3053.9600, 828.8960, -8.9849, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Sanctum of the Stars
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777019, 0, 530, -4115.5100, 1120.5400, 44.5242, 0.00, 0);

-- ON-TERRAIN        Stone of Retreat: Gurubashi Arena
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777020, 0, 0, -13277.4000, 127.3720, 26.1418, 0.00, 0);

-- LIFTED             Stone of Retreat: Bloodvenom Post
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777021, 0, 1, 5128.9100, -343.5060, 356.6220, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Stormspire (Deprecated)
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777022, 0, 530, 3043.3300, 3681.3300, 143.0650, 0.00, 0);

-- ON-TERRAIN        Stone of Retreat: Azshara
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777023, 0, 1, 3341.3600, -4603.7900, 92.5027, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Zul'Gurub
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777024, 0, 0, -11916.7000, -1215.7200, 92.2890, 0.00, 0);

-- INTERIOR          Stone of Retreat: Blackrock Mountain
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777025, 0, 0, -7494.9400, -1123.4900, 265.5470, 0.00, 0);

-- ON-TERRAIN        Stone of Retreat: Gates of Ahn'Qiraj
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777026, 0, 1, -8216.0600, 1536.3600, 1.3080, 0.00, 0);

-- LEVEL-ABOVE/TRIGGER Stone of Retreat: Onyxia's Lair
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777027, 0, 1, -4708.2700, -3727.6400, 54.5589, 0.00, 0);

-- LEVEL-ABOVE/TRIGGER Stone of Retreat: Dalaran City
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777028, 0, 571, 5807.9800, 588.4870, 660.9400, 0.00, 0);

-- LIFTED             Stone of Retreat: Ragefire Chasm (Orgrimmar)
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777029, 0, 1, 1811.7800, -4410.5000, -17.3275, 0.00, 0);

-- LIFTED             Stone of Retreat: Stockade (Stormwind)
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777030, 0, 0, -8779.9000, 834.3490, 97.9556, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Karazhan
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777031, 0, 0, -11118.9000, -2010.3300, 47.0819, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Moonglade
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (777032, 0, 1, 7654.3000, -2232.8700, 462.1070, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Yojamba Isle
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777023, 0, 0, -11774.3000, 1266.9400, 2.9936, 0.00, 0);

-- LIFTED             Stone of Retreat: Camp Mojache
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777024, 0, 1, -4396.7000, 224.8410, 26.4546, 0.00, 0);

-- LIFTED             Stone of Retreat: Feathermoon Stronghold
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777025, 0, 1, -4317.4700, 3287.3500, 19.6552, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Nethergarde Keep
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777026, 0, 0, -10999.8000, -3380.0800, 62.2525, 0.00, 0);

-- LIFTED             Stone of Retreat: Stonard
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777027, 0, 0, -10446.9000, -3261.9100, 21.0848, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Aerie Peak
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777036, 0, 0, 260.3660, -2125.2100, 119.5650, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Revantusk Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777037, 0, 0, -557.2260, -4581.2700, 9.5884, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Shadowprey Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777043, 0, 1, -1664.7900, 3091.6700, 30.5552, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Nijel's Point
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777044, 0, 1, 176.4260, 1309.7600, 190.1800, 0.00, 0);

-- LIFTED             Stone of Retreat: Marshal's Refuge
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777045, 0, 1, -6152.2500, -1087.6000, -199.7040, 0.00, 0);

-- LIFTED             Stone of Retreat: Thalanaar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777046, 0, 1, -4525.6300, -791.3640, -41.0917, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Freewind Post
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777047, 0, 1, -5431.7800, -2449.3800, 89.2848, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: Theramore Isle
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777048, 0, 1, -3711.9500, -4404.3000, 21.3729, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Brackenwall Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777049, 0, 1, -3130.6700, -2908.4300, 34.0976, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Camp Taurajo
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777050, 0, 1, -2363.1100, -1913.7800, 95.7829, 0.00, 0);

-- LIFTED             Stone of Retreat: The Crossroads
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777051, 0, 1, -452.8400, -2650.7600, 98.3503, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Mor'shan Base Camp
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777052, 0, 1, 1035.6200, -2106.0000, 122.9460, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Sun Rock Retreat
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777053, 0, 1, 966.1470, 926.4990, 104.6490, 0.00, 0);

-- LIFTED             Stone of Retreat: Stonetalon Peak
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777054, 0, 1, 2678.3800, 1497.4600, 235.4480, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Ghost Walker's Post
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777055, 0, 1, -1228.7100, 1721.6100, 89.9293, 0.00, 0);

-- LIFTED             Stone of Retreat: Talrendis Point
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777056, 0, 1, 2735.0600, -3867.4400, 102.0320, 0.00, 0);

-- LIFTED             Stone of Retreat: Valormok
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777057, 0, 1, 3608.5900, -4414.4300, 114.1110, 0.00, 0);

-- LIFTED             Stone of Retreat: Emerald Sanctuary
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777058, 0, 1, 3986.7100, -1293.5800, 251.6540, 0.00, 0);

-- LIFTED             Stone of Retreat: Auberdine
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777059, 0, 1, 6501.4000, 481.6070, 7.3245, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Grove of the Ancients
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777060, 0, 1, 4986.0200, 92.2780, 52.7174, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Astranaar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777061, 0, 1, 2676.1900, -422.9050, 107.1230, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Forest Song
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777062, 0, 1, 3011.1600, -3359.0800, 147.9600, 0.00, 0);

-- ON-TERRAIN        Stone of Retreat: Splintertree Post
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777063, 0, 1, 2270.9400, -2538.1900, 93.9198, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Zoram'gar Outpost
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777064, 0, 1, 3376.8600, 1013.0500, 3.3439, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Darkshire
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777065, 0, 0, -10573.0000, -1182.5100, 28.0148, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Eastvale Logging Camp
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777066, 0, 0, -9450.8200, -1299.9200, 42.7818, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Sentinel Hill
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777067, 0, 0, -10624.5000, 1096.6600, 33.7641, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Grom'gol Basecamp
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777068, 0, 0, -12388.9000, 172.5780, 2.8336, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Rebel Camp
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777069, 0, 0, -11322.4000, -202.4920, 75.6362, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Nesingwary's Expedition
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777070, 0, 0, -11609.3000, -52.9532, 10.9376, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Lakeshire
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777071, 0, 0, -9266.5900, -2188.7700, 64.0892, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Morgan's Vigil
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777072, 0, 0, -8372.7700, -2754.4600, 186.6220, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: Kargath
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777073, 0, 0, -6692.4800, -2175.3100, 244.1450, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Hammertoe Digsite
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777074, 0, 0, -6065.4400, -3022.0300, 230.3480, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Farstrider Lodge
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777075, 0, 0, -5657.2900, -4278.2500, 407.8230, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Thelsamar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777076, 0, 0, -5352.5400, -2948.5300, 323.7800, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Menethil Harbor
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777077, 0, 0, -3769.3200, -744.2600, 8.0103, 0.00, 0);

-- LIFTED             Stone of Retreat: Refuge Point
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777078, 0, 0, -1246.6100, -2529.3200, 21.7457, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Hammerfall
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777079, 0, 0, -941.0070, -3526.6600, 70.9350, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: Faldir's Cove
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777080, 0, 0, -2074.6500, -2113.6400, 15.3642, 0.00, 0);

-- LIFTED             Stone of Retreat: Southshore
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777081, 0, 0, -853.2210, -533.5290, 12.8683, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Tarren Mill
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777082, 0, 0, -34.1467, -923.3660, 54.5576, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: The Sepulcher
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777083, 0, 0, 533.8798, 1536.8212, 134.68832, 1.8692487, 0);

-- ON-FLOOR           Stone of Retreat: Kharanos
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777084, 0, 0, -5597.3100, -483.3980, 396.9810, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Brill
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777085, 0, 0, 2259.2500, 290.4300, 34.1137, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Goldshire
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777086, 0, 0, -9448.5500, 68.2360, 56.3225, 0.00, 0);

-- LIFTED             Stone of Retreat: Dolanaar
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777087, 0, 1, 9848.3700, 966.9530, 1307.3900, 0.00, 0);

-- LIFTED             Stone of Retreat: Sen'jin Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777088, 0, 1, -813.0970, -4880.0800, 20.2186, 0.00, 0);

-- LIFTED             Stone of Retreat: Razor Hill
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777089, 0, 1, 326.8100, -4706.6500, 16.8531, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Bloodhoof Village
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777090, 0, 1, -2240.9100, -399.1740, -9.4245, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Flame Crest
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777091, 0, 0, -7501.5100, -2183.0800, 165.9260, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: The Harborage
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777092, 0, 0, -10126.0000, -2834.7300, 22.2157, 0.00, 0);

-- ON-FLOOR           Stone of Retreat: Ambermill
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777093, 0, 0, -129.0940, 835.6210, 63.5980, 0.00, 0);

-- LEVEL-BELOW        Stone of Retreat: The Bulwark
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (1777094, 0, 0, 1711.9900, -719.7610, 54.3351, 0.00, 0);
