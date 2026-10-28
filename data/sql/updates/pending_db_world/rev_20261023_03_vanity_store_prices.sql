-- Vanity Store (coa_client_vanity_collection) prices by category, as set on the Rexxar realm.
-- The table ships empty and each realm fills it; on a realm without rows this file changes nothing.
-- Every statement writes fixed values, so a reapply leaves the result unchanged.

-- Stones of Retreat: 350
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 350
WHERE it.`name` LIKE 'Stone of Retreat:%';

-- Transmog sets, priced by how many pieces the cache holds (ethereal_bazaar_set_cache):
-- 8 or more (full set) 3200, 4-7 pieces 2700, 1-3 pieces 2200.
-- Not the Demon Hunter horn options, which share the "cosmetic set" wording.
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
JOIN (SELECT `cache_item`, COUNT(*) AS `pieces` FROM `ethereal_bazaar_set_cache` GROUP BY `cache_item`) sc
  ON sc.`cache_item` = v.`ItemID`
SET v.`BazaarTokenCost` = CASE WHEN sc.`pieces` >= 8 THEN 3200 WHEN sc.`pieces` >= 4 THEN 2700 ELSE 2200 END
WHERE it.`description` LIKE '%cosmetic set%' AND it.`description` NOT LIKE '%Demon Hunter horns%'
  AND it.`name` NOT LIKE 'Stone of Retreat:%';

-- Weapons: one-hand 1500, two-hand and ranged 2200
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 1500
WHERE it.`class` = 2 AND it.`InventoryType` IN (13, 21, 22);
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 2200
WHERE it.`class` = 2 AND it.`InventoryType` IN (17, 15, 25, 26);

-- Pets (companions and tamed-pet items): 1500
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 1500
WHERE (it.`class` = 15 AND it.`subclass` = 2)
   OR it.`name` LIKE 'Beastmaster''s Whistle:%' OR it.`name` LIKE 'Elemental Lodestone:%'
   OR it.`name` LIKE 'Summoner''s Stone:%' OR it.`name` LIKE 'Blood Soaked Vellum:%'
   OR it.`name` LIKE 'Draconic Warhorn:%';

-- Mounts: 3800
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 3800
WHERE it.`class` = 15 AND it.`subclass` = 5;

-- Other caches whose contents are only weapons and armor (sets and dual-wield pairs without the
-- "cosmetic set" wording): same piece-count prices. Key containers, raid markers and toys keep theirs.
UPDATE `coa_client_vanity_collection` v
JOIN (SELECT s.`cache_item`, COUNT(*) AS `pieces`, SUM(mi.`class` NOT IN (2, 4) OR mi.`class` IS NULL) AS `other`
      FROM `ethereal_bazaar_set_cache` s LEFT JOIN `item_template` mi ON mi.`entry` = s.`member_item`
      GROUP BY s.`cache_item`) sc ON sc.`cache_item` = v.`ItemID`
SET v.`BazaarTokenCost` = CASE WHEN sc.`pieces` >= 8 THEN 3200 WHEN sc.`pieces` >= 4 THEN 2700 ELSE 2200 END
WHERE sc.`other` = 0;

-- Shields and held-in-off-hand items: the one-hand price, 1500
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 1500
WHERE it.`InventoryType` IN (14, 23);

-- Raid Marker - Bundle: 2000; Dwayne (a companion in a box): the pet price, 1500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 2000 WHERE `ItemID` = 499428;
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 1500 WHERE `ItemID` = 532589;

-- Not usable: the Great Raven caches and the One With The Light incarnation caches are no longer sold
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  199735,  -- Prophet's Great Raven Cache
  199736,  -- Archmage's Great Raven Cache
  193918, 193919, 193920, 193921, 193922, 193923, 193924, 193925);  -- Incarnation: One With The Light ... Cache

-- Ethereal Tool Dispenser Crate and Fel Enchanted Warchest: 3000
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 3000 WHERE `ItemID` IN (8263511, 657112);

-- Toys, banners and costumes (the former 75-token items) are no longer sold: most do not work yet
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  558772,  -- Air Blade Racer Controller
  500008,  -- Allegiance Banner: Argent Dawn
  1500005,  -- Ancient Tuskarr Horn
  509505,  -- Aspect of the Nap
  558754,  -- Azzar Faire Beach Chair
  558786,  -- Azzar Faire Picnic
  110003,  -- Banner of Recruitment
  558771,  -- Battle Trak Racer Controller
  509883,  -- Big Game Hunter's Tracker Belt
  97748,  -- Blightcaller's Disguise
  499604,  -- Blue Dragon Body Costume
  499605,  -- Blue Dragon Head Costume
  499603,  -- Blue Dragon Tail Costume
  100009,  -- Bottled Qiraji Swarm
  34686,  -- Brazier of Dancing Flames
  33927,  -- Brewfest Pony Keg
  49704,  -- Carved Ogre Idol
  532576,  -- Chromatic Actuator
  499584,  -- Coin of Many Faces
  559540,  -- Comfy Wonka Egg
  500647,  -- Comical Banner: Ghosted
  500012,  -- Comical Banner: Khadgar
  500009,  -- Comical Banner: Salty
  500655,  -- Comical Banner: Skol!
  38301,  -- D.I.S.C.O.
  1326924,  -- Dark Ranger's Disguise
  532577,  -- Dazzling Rod
  558774,  -- Dirt Devil Racer Controller
  559564,  -- Duckmageddon 5000
  82313,  -- Ebon Blade Banner
  53834,  -- Empty Heart Container
  8000014,  -- Empty Water Chalice
  467790,  -- Everlasting Path of Cenarius
  559539,  -- Faire Spotlight
  559597,  -- Fel Alteration Codex
  1903515,  -- Fel-Infused Gateway
  559532,  -- Female Goblin Wonkaphile Costume
  33223,  -- Fishing Chair
  558781,  -- Flying Toy Ship Controller
  45063,  -- Foam Sword Rack
  33219,  -- Goblin Gumbo Kettle
  509901,  -- Goblin Money Printer
  505000,  -- Gordok Ogre Suit
  1777173,  -- Greasy Goblin Gizmo
  499601,  -- Green Dragon Body Costume
  499602,  -- Green Dragon Head Costume
  499600,  -- Green Dragon Tail Costume
  97749,  -- Grove Ranger's Guise: Windrunner
  97760,  -- Guise of the Dormant Vrykul
  509885,  -- Guise of the Dungeon Saurok
  97764,  -- Guise of the Nightmare Satyr
  197767,  -- Guise of the Plague Spreader
  97767,  -- Guise of the Purple Slime Skeleton
  558773,  -- Havac Racer Controller
  558776,  -- Hobgoblin Costume
  499607,  -- Horse Head Costume
  499606,  -- Horse Tail Costume
  32542,  -- Imp in a Ball
  90131,  -- John's Ball
  559586,  -- Jumper's Pedestal
  100576,  -- Legion Pocket Portal
  505001,  -- Light of Ascension
  980033,  -- Limited Edition 4.20.2020 Peace Pipe
  702454,  -- Limitless Healing Potion
  702455,  -- Limitless Mana Potion
  998529,  -- Limitless Noggenfogger Elixir
  509907,  -- Lonely Bonfire
  558790,  -- Magic Faire Stone
  559531,  -- Male Goblin Wonkaphile Costume
  509890,  -- Manastorm's Duplicator
  558770,  -- Marauder Racer Controller
  453836,  -- Millhouse Mixtape
  233223,  -- Millhouse's Mystical Transportation Device
  33079,  -- Murloc Costume
  46780,  -- Ogre Pinata
  898072,  -- PX-238-Portable Winter Wondervolt
  34499,  -- Paper Flying Machine Kit
  99076,  -- Pepe
  558788,  -- Pepe
  559633,  -- Personal Atmospheric Reconfigurator: Core
  559632,  -- Personal Atmospheric Reconfigurator: Empyrean
  559628,  -- Personal Atmospheric Reconfigurator: Firmament
  559631,  -- Personal Atmospheric Reconfigurator: Invasion
  559630,  -- Personal Atmospheric Reconfigurator: Sempiternal
  559629,  -- Personal Atmospheric Reconfigurator: Twilight
  32566,  -- Picnic Basket
  558778,  -- Pink Dragon Body Costume
  558779,  -- Pink Dragon Head Costume
  558777,  -- Pink Dragon Tail Costume
  558775,  -- Pioneer Gravitational Anchoring Suit
  559530,  -- Prime Gravitational Anchoring Suit
  100011,  -- Qiraji Battle Horn
  100010,  -- Qiraji Egg
  309907,  -- Recalibrator Pylon
  806657,  -- Regenerative Savory Deviate Delight
  800579,  -- Remote of Retreat: Ahn'Qiraj
  800580,  -- Remote of Retreat: Blackwing Lair
  800577,  -- Remote of Retreat: Molten Core
  800582,  -- Remote of Retreat: Naxxramas
  800581,  -- Remote of Retreat: Onyxia's Lair
  800578,  -- Remote of Retreat: Zul'Gurub
  34480,  -- Romantic Picnic Basket
  299950,  -- Ruby Attrition Insignia
  45047,  -- Sandbox Tiger
  100021,  -- Scourge Stick
  559529,  -- Sentinel Gravitational Anchoring Suit
  559523,  -- Simulated Subject Emulator: Amber
  559525,  -- Simulated Subject Emulator: Azure
  559524,  -- Simulated Subject Emulator: Rose
  559526,  -- Simulated Subject Emulator: Viridian
  559527,  -- Solar Gravitational Anchoring Suit
  100013,  -- Staff of the Sun God
  38578,  -- The Flag of Ownership
  499177,  -- The Flag of Ownership (Green F)
  499176,  -- The Flag of Ownership (Grimacing)
  499175,  -- The Flag of Ownership (Joy)
  499174,  -- The Flag of Ownership (Nerd)
  499173,  -- The Flag of Ownership (Pensive)
  499172,  -- The Flag of Ownership (Question Mark)
  499171,  -- The Flag of Ownership (Rage)
  499170,  -- The Flag of Ownership (Smile)
  499169,  -- The Flag of Ownership (Sunglasses)
  499168,  -- The Flag of Ownership (Weary)
  50471,  -- The Heartbreaker
  532591,  -- The Mighty Fist
  818060,  -- The Skeleton Coin
  509891,  -- Tiki Troll Mask
  559522,  -- Tiny Shadow Eye
  222739,  -- Tome of Polymorph: Frogduck
  44793,  -- Tome of Polymorph: Rabbit
  244793,  -- Tome of Polymorph: Rabbit
  22739,  -- Tome of Polymorph: Turtle
  1022739,  -- Tome of Polymorph: Turtle
  532575,  -- Transform: S.A.V.I.O.R
  509887,  -- Treasure Nabbin' Bag
  558769,  -- Turnip Punching Bag
  100012,  -- Twilight Bonfire
  559528,  -- Vanguard Gravitational Anchoring Suit
  559533,  -- Void-Corrupting Fragment
  559567,  -- Volatile Reactive Throne
  499180,  -- Winter Veil - Pepe
  558802,  -- Wonka Blue Flag
  559536,  -- Wonka Glasses
  558805,  -- Wonka Green Flag
  558804,  -- Wonka Orange Flag
  558803,  -- Wonka Purple Flag
  558999,  -- Wonka Rainbow Flag
  558801,  -- Wonka Red Flag
  558806,  -- Wonka Yellow Flag
  559565  -- Zandalari Gong
);

-- Single armor pieces (not caches, not shields or off-hands):
-- head, shoulders, chest, robe, legs 1000; waist, feet, wrist, hands, back 600; shirts and tabards 800.
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = CASE WHEN it.`InventoryType` IN (1, 3, 5, 7, 20) THEN 1000
                               WHEN it.`InventoryType` IN (4, 19) THEN 800 ELSE 600 END
WHERE it.`class` = 4 AND it.`InventoryType` IN (1, 3, 4, 5, 6, 7, 8, 9, 10, 16, 19, 20)
  AND v.`ItemID` NOT IN (SELECT `cache_item` FROM `ethereal_bazaar_set_cache`);

-- Trinkets, necks and rings are no longer sold
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  409,  -- Insignia of the Burning Legion
  12344,  -- Seal of Ascension
  16309,  -- Drakefire Amulet
  101428,  -- Greater Insignia of the Burning Legion
  666000,  -- Molten Core Medallion
  666001,  -- Blackwing Lair Medallion
  666002,  -- Battle for Mount Hyjal Medallion
  666003  -- Serpentshrine Cavern Medallion
);

-- Manastorm items are no longer sold
DELETE v FROM `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
WHERE it.`description` LIKE '%|cff33fff0Manastorm%';

-- Aura of Experience and Potion of Experience are sold again, at Tiraxis' prices (350 and 100).
-- Only on a realm that fills the table: on an empty one these two rows would be the whole store.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, n.`BazaarTokenCost`
FROM (SELECT 818059 AS `ItemID`, 350 AS `BazaarTokenCost` UNION ALL SELECT 818046, 100) n  -- Aura, Potion of Experience
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `ItemID` NOT IN (818059, 818046))
ON DUPLICATE KEY UPDATE `BazaarTokenCost` = VALUES(`BazaarTokenCost`);

-- Felforged Tomes no longer sold
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  79315,  -- Felforged Tome: Rush of Adrenaline V
  79316,  -- Felforged Tome: Fel Blood V
  101170  -- Felforged Tome: Relentless V
);

-- Misc cosmetics
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = CASE
    WHEN it.`name` LIKE 'Demon Scroll:%' THEN 1000
    WHEN it.`class` = 15 AND it.`subclass` = 4 AND it.`name` LIKE '%Wings%' THEN 3500
    WHEN it.`class` = 15 AND it.`subclass` = 4 AND it.`name` REGEXP 'Backpack|Satchel|Knapsack|Pouch|Pack$|Satch-Shell|Quiver|Bait Box|Tacklebox|Tidal Trunk|Verdant Vault|Verdant Vessel|Crimson Cargo' THEN 2500
    WHEN it.`class` = 15 AND it.`name` LIKE '%Altar%' THEN 750
    WHEN it.`name` LIKE 'Illusion:%' THEN 1500
    WHEN it.`class` = 15 AND it.`name` LIKE '% Blink' THEN 1200
    WHEN it.`class` = 15 AND it.`name` LIKE '% Life Tap' THEN 800
    WHEN it.`class` = 15 AND it.`name` LIKE '% Shadow Form' THEN 2000
    WHEN it.`name` LIKE '%Mana-forged Barrier' THEN 1200
    WHEN it.`name` LIKE 'Metamorphosis Incarnation:%' THEN 2000
    WHEN it.`name` LIKE 'Incarnation:%' THEN 2000
    WHEN it.`name` LIKE 'Demon Horns - %' OR it.`name` LIKE 'Horns of The Ascended %'
      OR it.`name` IN ('Sunwell Seeker''s Horned Memento', 'Triumphant Warlock''s Grimhorns') THEN 1250
    WHEN it.`class` = 0 AND it.`subclass` = 0 AND (it.`name` LIKE '% Aura' OR it.`name` LIKE 'Aura of the %') THEN 2000
    ELSE v.`BazaarTokenCost` END
WHERE it.`name` LIKE 'Demon Scroll:%' OR it.`name` LIKE 'Illusion:%' OR it.`name` LIKE '%Incarnation:%'
   OR it.`name` LIKE '%Mana-forged Barrier' OR it.`name` LIKE 'Demon Horns - %' OR it.`name` LIKE 'Horns of The Ascended %'
   OR it.`name` IN ('Sunwell Seeker''s Horned Memento', 'Triumphant Warlock''s Grimhorns')
   OR (it.`class` = 15 AND (it.`name` LIKE '%Altar%' OR it.`name` LIKE '% Blink' OR it.`name` LIKE '% Life Tap' OR it.`name` LIKE '% Shadow Form'))
   OR (it.`class` = 15 AND it.`subclass` = 4 AND (it.`name` LIKE '%Wings%' OR it.`name` REGEXP 'Backpack|Satchel|Knapsack|Pouch|Pack$|Satch-Shell|Quiver|Bait Box|Tacklebox|Tidal Trunk|Verdant Vault|Verdant Vessel|Crimson Cargo'))
   OR (it.`class` = 0 AND it.`subclass` = 0 AND (it.`name` LIKE '% Aura' OR it.`name` LIKE 'Aura of the %'));

-- Blooming Wakes, Embraces and Cloaks of the Heavens are no longer sold
DELETE v FROM `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
WHERE it.`class` = 15 AND it.`subclass` = 4
  AND (it.`name` LIKE '%Matriarch''s Blooming Wake' OR it.`name` LIKE '%Embrace%' OR it.`name` LIKE '%Cloak of the Heavens');

-- Profession and utility items: Tiraxis' prices where he sells them (900008), 500-700 for the rest
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 350 WHERE `ItemID` = 1904514;  -- Portable Sanguine Workbench
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 500 WHERE `ItemID` IN (
  1777028, 1777064,                    -- Thermal Anvil, Portable Sawmill
  1777007, 1777008, 1777009,           -- Portable Runeforge (Red, Blue, Green)
  196891, 196892, 196893, 196894);     -- Farmer's Egg Perches
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 600 WHERE `ItemID` IN (
  1913515, 1913516, 1913517,           -- Portable Call Board (Alliance, Horde, Outlaw)
  97768);                              -- Survivalist's Campsite
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 700 WHERE `ItemID` IN (
  1903512, 1903510,                    -- Gnomish Portable Post Tube, Gnomish Portable Transpolyporter
  97758);                              -- Homebound Portal

-- Account and travel items are no longer sold, except Feather of Ancients: Azeroth (1000)
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  134988, 977020,  -- Founder's Charter
  1777010,         -- Godslayer's Charter
  977220,          -- Bloodforged Contract
  223772,          -- Silversteel Covenant
  977026,          -- Feather of Ancients: TBC
  977028,          -- Travel Permit
  101493,          -- Northrend Travel Guide
  97318,           -- Conquest of Azeroth Travel Guide
  397318,          -- Original 9 Classes - Bronzebeard Travel Guide
  97398,           -- Seasonal Achievements Unlock
  1000498          -- Feral Tome: Swift Flight Form
);
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 1000 WHERE `ItemID` IN (134989, 977025);  -- Feather of Ancients: Azeroth

-- Hunter pet calls and named pets: 1000
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 1000 WHERE `ItemID` IN (
  80009, 80010,                                    -- Bjomolf's Call, Call of the Mottled Worg
  507858, 507860, 507861, 507862, 507863, 507864); -- Daisy, Zul'kara, Dart, Kevin, Roko, Kahun

-- Wind Shear visuals: the Blink price, 1200
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 1200
WHERE it.`class` = 15 AND it.`name` LIKE '% Wind Shear';

-- Tomes: 1200 (not the Soaring Spelltome mount or the Watcher of Tomes pet)
UPDATE `coa_client_vanity_collection` v JOIN `item_template` it ON it.`entry` = v.`ItemID`
SET v.`BazaarTokenCost` = 1200
WHERE it.`name` LIKE 'Tome of %' OR it.`name` IN ('Felforged Tome: Track Humanoids', 'Flamebender''s Tome');

-- Watcher of Tomes is a pet: 1500 (Reins of the Soaring Spelltome is already at the mount price)
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 1500 WHERE `ItemID` = 354472;
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 3800 WHERE `ItemID` = 8199945;

-- Companions filed as consumables: the pet price, 1500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 1500 WHERE `ItemID` IN (
  515323, 354119, 515044, 515412, 354157, 666451, 450886,  -- Bottled Oozeling, Docile Mystwood Lasher, Docile Night Web Hatchling,
                                                           -- Friendly Sludgemonster, Frightened Kitten, Young Plaguebat, The "Kodo Egg"
  187088, 187089, 187090, 187091, 187092,                  -- Great Eagles, Rotfeather Scavenger
  244252, 244253, 244254);                                 -- Tamed Eboncoil, Dustcoil, Verdantcoil

-- Not sold: everyone gets a Personal Bank; Felstone, Vanity Collection Sync; Manastorm items are earned in the Manastorm
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  110000, 134985,  -- Personal Bank
  509892,          -- Celestial Personal Bank
  11,              -- Felstone
  777989,          -- Vanity Collection Sync
  449050           -- Manastorm: Endless Manastorm Potion (Rank 2)
);

UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 500 WHERE `ItemID` = 10;  -- Flight Master's Whistle

-- Keeper's Scrolls: 100
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 100 WHERE `ItemID` IN (
  696661, 696662, 696663, 696664, 696665,        -- Keeper's Scroll: Golganneth, Norgannon, Khaz'goroth, Aggramar, Eonar
  2200009, 2200010, 2200011, 2200012, 2200013);  -- Soulbound Keeper's Scroll: same five

-- Runes of Retreat: 500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 500 WHERE `ItemID` IN (
  106948, 106949, 106950, 106951, 106952, 82314);  -- Arcane, Flaming, Freezing, Dark, Holy, Frostforged

-- Cosmetic auras and effects filed as consumables: 2000
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 2000 WHERE `ItemID` IN (
  99017,  -- Arcane Spheres
  99914,  -- Blessing of Holy Light
  499156,  -- Burning Remnant - Blue
  499155,  -- Burning Remnant - Green
  499154,  -- Burning Remnant - Orange
  499153,  -- Burning Remnant - Purple
  599890,  -- Chillwind Haze
  559554,  -- Chronometric Pressure
  199914,  -- Frosty Balls
  499163,  -- Gaze of the First Summoner - Green
  499162,  -- Gaze of the First Summoner - Red
  499161,  -- Gaze of the First Summoner - Yellow
  101402,  -- Haunting Aberrations
  101406,  -- Malevolent Presence
  1777090,  -- Mark of the Naaru
  199912,  -- Molten Spheres
  97757,  -- Nightmarish
  499160,  -- Pride of the Pit Lord - Green
  499159,  -- Pride of the Pit Lord - Purple
  499158,  -- Pride of the Pit Lord - Red
  499157,  -- Pride of the Pit Lord - Yellow
  199913,  -- Shadow Orbs
  101408,  -- Shadows Overwhelming
  99077,  -- Skull of the Man'ari
  499167,  -- Skull of the Man'ari - Green
  499166,  -- Skull of the Man'ari - Purple
  499165,  -- Skull of the Man'ari - Red
  499164,  -- Skull of the Man'ari - Yellow
  499152,  -- Soul of the Forgotten - Blue
  499151,  -- Soul of the Forgotten - Purple
  499150,  -- Soul of the Forgotten - Red
  499149,  -- Soul of the Forgotten - Yellow
  499148,  -- Thal'kiel's Visage - Blue
  499147,  -- Thal'kiel's Visage - Pale
  499146,  -- Thal'kiel's Visage - Purple
  499145,  -- Thal'kiel's Visage - Red
  99010  -- Verdant Spheres
);

-- Back cosmetics filed as consumables (thrusters, balloons, tanks, mantles, halos ...): the backpack price, 2500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 2500 WHERE `ItemID` IN (
  558700,  -- Back Horse Balloon
  558701,  -- Back Murloc Balloon
  558702,  -- Back Wolf Balloon
  559496,  -- Blue Back-Mounted Thrusters
  558783,  -- Blue Balloon
  559505,  -- Elegant Ornamental Bow
  760028,  -- Faewoven Bulb
  559483,  -- Fel Demonic Back Adornment
  558703,  -- Fuel Container
  760002,  -- Glittering Gold Sinstone Chain
  559497,  -- Green Back-Mounted Thrusters
  558782,  -- Green Balloon
  558705,  -- Grungy Containment Pack
  760038,  -- Halo of the Discordant
  760036,  -- Halo of the Harmonious
  760039,  -- Halo of the Reverent
  760037,  -- Halo of the Selfless
  559506,  -- Hopeful Ornamental Bow
  558697,  -- Horse Balloon
  559510,  -- King Turtle Shell
  559508,  -- Luxurious Ornamental Bow
  760005,  -- Mantle of Burnished Blades
  760006,  -- Mantle of Court Blades
  760004,  -- Mantle of Crimson Blades
  760007,  -- Mantle of the Forgemaster's Dark Blades
  559495,  -- Metallic Back-Mounted Thrusters
  558698,  -- Murloc Balloon
  1777030,  -- Painbringer's Back-Prison
  559515,  -- Pioneer Gravitational Oxygen Tank
  559507,  -- Precious Ornamental Bow
  559541,  -- Prime Gravitational Oxygen Tank
  559498,  -- Purple Back-Mounted Thrusters
  559484,  -- Purple Demonic Back Adornment
  559499,  -- Red Back-Mounted Thrusters
  558784,  -- Red Balloon
  760042,  -- Selfless Sigil of the Archon
  559514,  -- Sentinel Gravitational Oxygen Tank
  559516,  -- Solar Gravitational Oxygen Tank
  760024,  -- Spirit Tender's Branches
  760029,  -- Spirit Tender's Bulb
  499888,  -- Tendrils of Mana
  499890,  -- Tendrils of the Naaru
  499889,  -- Tendrils of the Old Gods
  760019,  -- Trophy of the Reborn Bonelord
  559509,  -- Turtle Shell
  559517,  -- Vanguard Gravitational Oxygen Tank
  559513,  -- Void Back Growth
  760031,  -- Winter Tender's Bulb
  760030,  -- Winterwoven Bulb
  558699,  -- Wolf Balloon
  559494,  -- Yellow Back-Mounted Thrusters
  558787,  -- Yellow Balloon
  559481  -- Yellow Demonic Back Adornment
);

-- Wings filed as consumables: the wings price, 3500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 3500 WHERE `ItemID` IN (
  559626,  -- Aureate Holo-Wings
  559625,  -- Azure Holo-Wings
  760016,  -- Barbarous Osteowings
  8210128,  -- Blazing Irie Wings
  700002,  -- Blazing Phoenix Feathers
  559623,  -- Crimson Holo-Wings
  559624,  -- Emerald Holo-Wings
  8210122,  -- Felfire Wings
  559627,  -- Ivory Holo-Wings
  499949,  -- Phoenix Feathers
  760017,  -- Regrown Osteowings
  8210120,  -- Smoldering Wings
  8210126  -- Sulfurous Wings
);

-- Backpacks filed as consumables: 2500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 2500 WHERE `ItemID` IN (
  99011,  -- Headhunter's Backpack
  10017,  -- Plaguethrower's Backpack (Green)
  10016,  -- Plaguethrower's Backpack (Purple)
  99012,  -- Stylish Backpack
  99013  -- Traveler's Backpack
);

-- More wings filed as consumables (Enchanted Wings, Wings of ..., duck wings): 3500
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 3500 WHERE `ItemID` IN (
  8210124,  -- Enchanted Wings: Faerie
  8210125,  -- Enchanted Wings: Irie
  8210127,  -- Enchanted Wings: Manaforged
  99015,  -- Guardian Spirit's Gift
  559512,  -- Mechanical Wings of the Azzar Faire
  760018,  -- Osteowings of the Necrolords
  760045,  -- Selfless Wings of the Ascended
  8210123,  -- Wings of Haunting Nightmare
  559573,  -- Wings of the Bronze Duck
  559576,  -- Wings of the Bronze Spectral Duck
  559569,  -- Wings of the Chestnut Duck
  559575,  -- Wings of the Golden Duck
  559578,  -- Wings of the Golden Spectral Duck
  559568,  -- Wings of the Hateful Duck
  559571,  -- Wings of the Sea Foam Duck
  559574,  -- Wings of the Silver Duck
  559577,  -- Wings of the Silver Spectral Duck
  559572,  -- Wings of the Sunray Duck
  559570  -- Wings of the Verdant River Duck
);
