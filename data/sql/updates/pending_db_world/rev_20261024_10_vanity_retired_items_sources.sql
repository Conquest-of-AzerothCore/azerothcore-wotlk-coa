-- Vanity items the Rexxar realm has retired, taken out of every place they can still be bought or rolled from.
-- Scope: like rev_20261024_01, every statement only runs on a realm that fills the Vanity Store price table
-- (coa_client_vanity_collection has priced rows). On a realm with an empty table nothing here changes.
-- Every statement writes fixed values, so a reapply leaves the result unchanged.

-- 1) Vanity Store price 0. Keep the row at 0 rather than deleting it: without a row the server falls back to
--    the VanityCollection.dbc price (#8788). A price of 0 is refused by the buy command.
--    - Recruit-A-Friend rewards: they are earned by recruiting, not bought.
--    - The Ethereal Tool Dispenser Crate (rev_20261023_03 priced it at 3000).
--    - The Stones of Retreat to Northrend, Outland, the Exodar and Silvermoon City: only the vanilla-zone and
--      custom-location stones stay for sale.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES
  ROW(23713),  -- Hippogryph Hatchling
  ROW(34493),  -- Dragon Kite
  ROW(37719),  -- Swift Zhevra
  ROW(46778),  -- Magic Rooster Egg
  ROW(49287),  -- Tuskarr Kite
  ROW(54068),  -- Wooly White Rhino
  ROW(54811),  -- Celestial Steed
  ROW(8263511),  -- Ethereal Tool Dispenser Crate
  ROW(436),  -- Stone of Retreat: Agmar's Hammer
  ROW(458),  -- Stone of Retreat: Amberpine Lodge
  ROW(452),  -- Stone of Retreat: Argent Tournament Grounds
  ROW(437),  -- Stone of Retreat: Azjol-Nerub
  ROW(454),  -- Stone of Retreat: Blackwatch
  ROW(450),  -- Stone of Retreat: Brunnhildar Village
  ROW(459),  -- Stone of Retreat: Camp Oneqwah
  ROW(460),  -- Stone of Retreat: Camp Winterhoof
  ROW(425),  -- Stone of Retreat: Coldarra
  ROW(439),  -- Stone of Retreat: Conquest Hold
  ROW(777028),  -- Stone of Retreat: Dalaran City
  ROW(442),  -- Stone of Retreat: Drak'Tharon Keep
  ROW(451),  -- Stone of Retreat: Dun Niffelem
  ROW(449),  -- Stone of Retreat: Frosthold
  ROW(448),  -- Stone of Retreat: Grom'arsh Crash-Site
  ROW(443),  -- Stone of Retreat: Gundrak
  ROW(455),  -- Stone of Retreat: Icecrown Citadel
  ROW(447),  -- Stone of Retreat: K3
  ROW(444),  -- Stone of Retreat: Lakeside Landing
  ROW(435),  -- Stone of Retreat: Moa'ki Harbor
  ROW(432),  -- Stone of Retreat: Naxxramas (Dragonblight)
  ROW(445),  -- Stone of Retreat: Nesingwary Base Camp
  ROW(428),  -- Stone of Retreat: New Agamand
  ROW(461),  -- Stone of Retreat: Stars' Rest
  ROW(441),  -- Stone of Retreat: The Argent Stand
  ROW(456),  -- Stone of Retreat: The Argent Vanguard
  ROW(453),  -- Stone of Retreat: The Shadow Vault
  ROW(446),  -- Stone of Retreat: Ulduar
  ROW(426),  -- Stone of Retreat: Unu'pe
  ROW(429),  -- Stone of Retreat: Utgarde Keep
  ROW(430),  -- Stone of Retreat: Valgarde
  ROW(424),  -- Stone of Retreat: Valiance Keep
  ROW(427),  -- Stone of Retreat: Vengeance Landing
  ROW(462),  -- Stone of Retreat: Venomspite
  ROW(438),  -- Stone of Retreat: Venture Bay
  ROW(423),  -- Stone of Retreat: Warsong Hold
  ROW(440),  -- Stone of Retreat: Westfall Brigade Encampment
  ROW(431),  -- Stone of Retreat: Westguard Keep
  ROW(433),  -- Stone of Retreat: Wintergarde Keep
  ROW(434),  -- Stone of Retreat: Wyrmrest Temple
  ROW(457),  -- Stone of Retreat: Zim'Torga
  ROW(102178),  -- Stone of Retreat: Allerian Stronghold
  ROW(777018),  -- Stone of Retreat: Altar of Sha'tar
  ROW(1175646),  -- Stone of Retreat: Altar of Sha'tar
  ROW(102179),  -- Stone of Retreat: Altar of Shatar
  ROW(777017),  -- Stone of Retreat: Area 52
  ROW(102180),  -- Stone of Retreat: Cenarion Refuge
  ROW(102181),  -- Stone of Retreat: Cosmowrench
  ROW(102182),  -- Stone of Retreat: Evergrove
  ROW(1175644),  -- Stone of Retreat: Evergrove
  ROW(102183),  -- Stone of Retreat: Falcon Watch
  ROW(102184),  -- Stone of Retreat: Garadar
  ROW(102185),  -- Stone of Retreat: Honor Hold
  ROW(102186),  -- Stone of Retreat: Ogri'la
  ROW(102187),  -- Stone of Retreat: Orebor Harborage
  ROW(102188),  -- Stone of Retreat: Sanctum of the Stars
  ROW(777019),  -- Stone of Retreat: Sanctum of the Stars
  ROW(1175645),  -- Stone of Retreat: Sanctum of the Stars
  ROW(102189),  -- Stone of Retreat: Shadowmoon Village
  ROW(777016),  -- Stone of Retreat: Shattrath
  ROW(777014),  -- Stone of Retreat: Silvermoon City
  ROW(102190),  -- Stone of Retreat: Stonebreaker Hold
  ROW(777022),  -- Stone of Retreat: Stormspire (Deprecated)
  ROW(102191),  -- Stone of Retreat: Swamprat Post
  ROW(102192),  -- Stone of Retreat: Sylvanaar
  ROW(102193),  -- Stone of Retreat: Telaar
  ROW(102194),  -- Stone of Retreat: Telredor
  ROW(102195),  -- Stone of Retreat: Temple of Telhamat
  ROW(777015),  -- Stone of Retreat: The Exodar
  ROW(102196),  -- Stone of Retreat: The Stormspire
  ROW(102197),  -- Stone of Retreat: Thrallmar
  ROW(102198),  -- Stone of Retreat: Thunderlord Stronghold
  ROW(102199),  -- Stone of Retreat: Toshley's Station
  ROW(102200),  -- Stone of Retreat: Wildhammer Stronghold
  ROW(102201)  -- Stone of Retreat: Zabra'jin
) `n` (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;

-- 2) Tiraxis' Stones of Retreat list (900010): the same 75 stones.
DELETE FROM `npc_vendor`
WHERE `entry` = 900010 AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0) AND `item` IN (
  436,  -- Stone of Retreat: Agmar's Hammer
  458,  -- Stone of Retreat: Amberpine Lodge
  452,  -- Stone of Retreat: Argent Tournament Grounds
  437,  -- Stone of Retreat: Azjol-Nerub
  454,  -- Stone of Retreat: Blackwatch
  450,  -- Stone of Retreat: Brunnhildar Village
  459,  -- Stone of Retreat: Camp Oneqwah
  460,  -- Stone of Retreat: Camp Winterhoof
  425,  -- Stone of Retreat: Coldarra
  439,  -- Stone of Retreat: Conquest Hold
  777028,  -- Stone of Retreat: Dalaran City
  442,  -- Stone of Retreat: Drak'Tharon Keep
  451,  -- Stone of Retreat: Dun Niffelem
  449,  -- Stone of Retreat: Frosthold
  448,  -- Stone of Retreat: Grom'arsh Crash-Site
  443,  -- Stone of Retreat: Gundrak
  455,  -- Stone of Retreat: Icecrown Citadel
  447,  -- Stone of Retreat: K3
  444,  -- Stone of Retreat: Lakeside Landing
  435,  -- Stone of Retreat: Moa'ki Harbor
  432,  -- Stone of Retreat: Naxxramas (Dragonblight)
  445,  -- Stone of Retreat: Nesingwary Base Camp
  428,  -- Stone of Retreat: New Agamand
  461,  -- Stone of Retreat: Stars' Rest
  441,  -- Stone of Retreat: The Argent Stand
  456,  -- Stone of Retreat: The Argent Vanguard
  453,  -- Stone of Retreat: The Shadow Vault
  446,  -- Stone of Retreat: Ulduar
  426,  -- Stone of Retreat: Unu'pe
  429,  -- Stone of Retreat: Utgarde Keep
  430,  -- Stone of Retreat: Valgarde
  424,  -- Stone of Retreat: Valiance Keep
  427,  -- Stone of Retreat: Vengeance Landing
  462,  -- Stone of Retreat: Venomspite
  438,  -- Stone of Retreat: Venture Bay
  423,  -- Stone of Retreat: Warsong Hold
  440,  -- Stone of Retreat: Westfall Brigade Encampment
  431,  -- Stone of Retreat: Westguard Keep
  433,  -- Stone of Retreat: Wintergarde Keep
  434,  -- Stone of Retreat: Wyrmrest Temple
  457,  -- Stone of Retreat: Zim'Torga
  102178,  -- Stone of Retreat: Allerian Stronghold
  777018,  -- Stone of Retreat: Altar of Sha'tar
  1175646,  -- Stone of Retreat: Altar of Sha'tar
  102179,  -- Stone of Retreat: Altar of Shatar
  777017,  -- Stone of Retreat: Area 52
  102180,  -- Stone of Retreat: Cenarion Refuge
  102181,  -- Stone of Retreat: Cosmowrench
  102182,  -- Stone of Retreat: Evergrove
  1175644,  -- Stone of Retreat: Evergrove
  102183,  -- Stone of Retreat: Falcon Watch
  102184,  -- Stone of Retreat: Garadar
  102185,  -- Stone of Retreat: Honor Hold
  102186,  -- Stone of Retreat: Ogri'la
  102187,  -- Stone of Retreat: Orebor Harborage
  102188,  -- Stone of Retreat: Sanctum of the Stars
  777019,  -- Stone of Retreat: Sanctum of the Stars
  1175645,  -- Stone of Retreat: Sanctum of the Stars
  102189,  -- Stone of Retreat: Shadowmoon Village
  777016,  -- Stone of Retreat: Shattrath
  777014,  -- Stone of Retreat: Silvermoon City
  102190,  -- Stone of Retreat: Stonebreaker Hold
  777022,  -- Stone of Retreat: Stormspire (Deprecated)
  102191,  -- Stone of Retreat: Swamprat Post
  102192,  -- Stone of Retreat: Sylvanaar
  102193,  -- Stone of Retreat: Telaar
  102194,  -- Stone of Retreat: Telredor
  102195,  -- Stone of Retreat: Temple of Telhamat
  777015,  -- Stone of Retreat: The Exodar
  102196,  -- Stone of Retreat: The Stormspire
  102197,  -- Stone of Retreat: Thrallmar
  102198,  -- Stone of Retreat: Thunderlord Stronghold
  102199,  -- Stone of Retreat: Toshley's Station
  102200,  -- Stone of Retreat: Wildhammer Stronghold
  102201  -- Stone of Retreat: Zabra'jin
);

-- 3) Tiraxis' Convenience Items (900008): the Loot-Transfigurator 5000 is retired with the Lost Toy Cache.
DELETE FROM `npc_vendor`
WHERE `entry` = 900008 AND `item` = 190190 AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

-- 4) The Lost Toy Cache and the Lost Convenience Cache are no longer sold (vendor 900009).
DELETE FROM `npc_vendor`
WHERE `entry` = 900009 AND `item` IN (8950007, 8950009) AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

-- 5) Lost caches must not roll what the Vanity Store no longer sells.
--    Lost Mount Cache: mounts at price 0. Lost Pet Cache: Recruit-A-Friend pets.
--    Lost Toy Cache: the Loot-Transfigurator 5000 and The Skin-Peeler 9000.
--    The Ethereal Tool Dispenser leaves the Lost Convenience Cache and its own crates.
DELETE FROM `ethereal_bazaar_cache_pool`
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
  AND (`cache_item`, `reward_item`) IN (
  (8950003, 98490),    -- Lost Mount Cache: Reins of the Spectral Steed
  (8950003, 99485),    -- Lost Mount Cache: Reins of the Accursed Wrathsteed
  (8950003, 199667),   -- Lost Mount Cache: Bound Blizzard
  (8950003, 203079),   -- Lost Mount Cache: Anu'relos's Reins
  (8950003, 283040),   -- Lost Mount Cache: Reins of The Headless Horseman's Ghoulish Charger
  (8950005, 23713),    -- Lost Pet Cache: Hippogryph Hatchling
  (8950005, 34493),    -- Lost Pet Cache: Dragon Kite
  (8950005, 49287),    -- Lost Pet Cache: Tuskarr Kite
  (8950009, 190190),   -- Lost Toy Cache: Loot-Transfigurator 5000
  (8950009, 190191),   -- Lost Toy Cache: The Skin-Peeler 9000
  (8950007, 8263511),  -- Lost Convenience Cache: Ethereal Tool Dispenser Crate
  (8263510, 8263501),  -- Ethereal Tool Dispenser Crate (Bad): Ethereal Tool Dispenser
  (8263511, 8263501)   -- Ethereal Tool Dispenser Crate: Ethereal Tool Dispenser
);
