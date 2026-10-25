-- Tiraxis and Vanity Store prices as set on the Rexxar realm (2026-10-25).
-- Like rev_20261024_01 every statement only acts on a realm that fills the Vanity Store price table, and every
-- statement writes fixed values, so a reapply leaves the result unchanged.

-- 1) Heirlooms leave Tiraxis (900011, rev_20261023_02) and are sold in the Vanity Store only, at twice their old
--    Tiraxis price (one-hand, shield and off-hand 900 -> 1800, ranged and relics 1000 -> 2000, two-hand 1800 -> 3600);
--    trinkets cost what a Heirloom Cache would after the same doubling, 3000, and so do the heirloom rings, necklaces
--    and Stick on a Carrot. The raid medallions and the Insignias of the Burning Legion are not sold (price 0).
--    Heirloom armor: a full set costs 6000 - chest (or robe) 2000, shoulders 2000, and the other seven pieces (head,
--    waist, legs, feet, wrists, hands, back) 286 each. The 14 Heirloom and Experience Heirloom
--    Caches are not sold at all any more (they have no Vanity Store row).
-- 2) Tiraxis' Convenience Items (900008): new prices, and the Vanity Store sells the same items at the same price.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, `n`.`BazaarTokenCost`
FROM (VALUES
  ROW(1642944, 1800),  -- Balanced Heartseeker
  ROW(1644096, 1800),  -- Battleworn Thrash Blade
  ROW(1642948, 1800),  -- Devout Aurastone Hammer
  ROW(3148335, 1800),  -- Polished Observer's Shield
  ROW(1518202, 1800),  -- Rethreaded Left Bear Claw
  ROW(1518203, 1800),  -- Rethreaded Right Bear Claw
  ROW(1644091, 1800),  -- Sharpened Scarlet Kris
  ROW(1644094, 1800),  -- The Blessed Hammer of Grace
  ROW(3140350, 1800),  -- Urn of Aspiring Light
  ROW(1642945, 1800),  -- Venerable Dal'Rend's Sacred Charge
  ROW(1648716, 1800),  -- Venerable Mass of McGowan
  ROW(1642999, 2000),  -- Ancient Crossbow
  ROW(1642946, 2000),  -- Charmed Ancient Bone Bow
  ROW(1642896, 2000),  -- Druid Idol of Agility
  ROW(1642897, 2000),  -- Druid Idol of Spells
  ROW(1642901, 2000),  -- Paladin Libram of Healing
  ROW(1642900, 2000),  -- Paladin Libram of Strength
  ROW(1642898, 2000),  -- Shaman Totem of Agility
  ROW(1642899, 2000),  -- Shaman Totem of Spells
  ROW(1642902, 2000),  -- Thrown Axe of the Executioner
  ROW(1644093, 2000),  -- Upgraded Dwarven Hand Cannon
  ROW(1642846, 2000),  -- Wand of the Forgotten Lich
  ROW(1642992, 3000),  -- Discerning Eye of the Beast
  ROW(1644098, 3000),  -- Inherited Insignia of the Alliance
  ROW(1644097, 3000),  -- Inherited Insignia of the Horde
  ROW(1642991, 3000),  -- Swift Hand of Justice
  ROW(1642943, 3600),  -- Bloodied Arcanite Reaper
  ROW(1642947, 3600),  -- Dignified Headmaster's Charge
  ROW(1644095, 3600),  -- Grand Staff of Jordan
  ROW(1644092, 3600),  -- Reforged Truesilver Champion
  ROW(1648718, 3600),  -- Repurposed Lava Dredger
  ROW(3142943, 3600),  -- Sturdied Arcanite Spear
  ROW(505002, 100),    -- Pristine Pouch
  ROW(818046, 300),    -- Potion of Experience
  ROW(3001006, 500),   -- Riding Tome: Apprentice Riding
  ROW(106955, 500),    -- Tome of Specialization II
  ROW(106956, 600),    -- Tome of Specialization III
  ROW(505003, 700),    -- Heroes' Satchel
  ROW(106957, 800),    -- Tome of Specialization IV
  ROW(818059, 1000),   -- Aura of Experience
  ROW(106958, 1000),   -- Tome of Specialization V
  ROW(1006971, 1200),  -- Dragon Hide Bag
  ROW(106959, 1400),   -- Tome of Specialization VI
  ROW(818061, 1500),   -- Aura of Reputation
  ROW(3001005, 1500),  -- Riding Tome: Journeyman Riding
  ROW(1004036, 1600),  -- Ironweave Bag
  ROW(3211009, 2000),  -- Riding Tome: Expert Riding
  ROW(97871, 3000),    -- Craftsman's Codex
  ROW(1004040, 3000),  -- Mekkatorque's Neverending Storage Contraption
  ROW(106960, 3000),   -- Tome of Specialization VII
  ROW(777998, 3000),   -- Tradesman's Scroll
  ROW(3211010, 5000),  -- Riding Tome: Artisan Riding
  ROW(1179243, 7500),  -- Riding Tome: Extraordinary Riding
  ROW(1339081, 3000),  -- Ring of the Bulwark
  ROW(1339082, 3000),  -- Ring of the Lionhearted
  ROW(1339083, 3000),  -- Ring of the Seer
  ROW(1339080, 3000),  -- Ring of the Sorcerer
  ROW(1339079, 3000),  -- Ring of the Vanguard
  ROW(12344, 3000),    -- Seal of Ascension
  ROW(666002, 0),   -- Battle for Mount Hyjal Medallion
  ROW(666001, 0),   -- Blackwing Lair Medallion
  ROW(101428, 0),   -- Greater Insignia of the Burning Legion
  ROW(409, 0),      -- Insignia of the Burning Legion
  ROW(666000, 0),   -- Molten Core Medallion
  ROW(666003, 0),   -- Serpentshrine Cavern Medallion
  ROW(339075, 3000),   -- Stick on a Carrot
  ROW(16309, 3000),    -- Drakefire Amulet
  ROW(339076, 3000),   -- Pendant of Adventure
  ROW(339100, 3000),   -- Pendant of Discovery
  ROW(1339078, 3000),  -- Pendant of the Bulwark
  ROW(1339077, 3000),  -- Pendant of the Sorcerer
  ROW(1339076, 3000),  -- Pendant of the Warrior
  ROW(1339126, 286),   -- Burnished Helmet of Might
  ROW(1339124, 286),   -- Champion Herod's Helmet
  ROW(1339123, 286),   -- Mystical Helm of Elements
  ROW(1339125, 286),   -- Polished Helmet of Valor
  ROW(1339122, 286),   -- Preened Ironfeather Headguard
  ROW(1339121, 286),   -- Stained Shadowcraft Hood
  ROW(1339120, 286),   -- Tattered Dreadmist Hood
  ROW(1644102, 2000),  -- Aged Pauldrons of The Five Thunders
  ROW(3142949, 2000),  -- Burnished Spaulders of Might
  ROW(1642950, 2000),  -- Champion Herod's Shoulder
  ROW(1644103, 2000),  -- Exceptional Stormshroud Shoulders
  ROW(1644107, 2000),  -- Exquisite Sunderseer Mantle
  ROW(1644105, 2000),  -- Lasting Feralheart Spaulders
  ROW(1642951, 2000),  -- Mystical Pauldrons of Elements
  ROW(1642949, 2000),  -- Polished Spaulders of Valor
  ROW(1642984, 2000),  -- Preened Ironfeather Shoulders
  ROW(1644100, 2000),  -- Pristine Lightforge Spaulders
  ROW(1644101, 2000),  -- Prized Beastmaster's Mantle
  ROW(1642952, 2000),  -- Stained Shadowcraft Spaulders
  ROW(1644099, 2000),  -- Strengthened Stockade Pauldrons
  ROW(1642985, 2000),  -- Tattered Dreadmist Mantle
  ROW(3148685, 2000),  -- Burnished Breastplate of Might
  ROW(1648677, 2000),  -- Champion's Deathdealer Breastplate
  ROW(1648683, 2000),  -- Mystical Vest of Elements
  ROW(1648685, 2000),  -- Polished Breastplate of Valor
  ROW(1648687, 2000),  -- Preened Ironfeather Breastplate
  ROW(1648689, 2000),  -- Stained Shadowcraft Tunic
  ROW(1648691, 2000),  -- Tattered Dreadmist Robe
  ROW(1339098, 286),   -- Burnished Belt of Might
  ROW(1339096, 286),   -- Champion Herod's Belt
  ROW(1339095, 286),   -- Mystical Belt of Elements
  ROW(1339097, 286),   -- Polished Belt of Valor
  ROW(1339094, 286),   -- Preened Ironfeather Belt
  ROW(1339093, 286),   -- Stained Shadowcraft Belt
  ROW(1339092, 286),   -- Tattered Dreadmist Belt
  ROW(1339119, 286),   -- Burnished Platelegs of Might
  ROW(1339117, 286),   -- Champion Herod's Legguards
  ROW(1339116, 286),   -- Mystical Kilt of Elements
  ROW(1339118, 286),   -- Polished Platelegs of Valor
  ROW(1339115, 286),   -- Preened Ironfeather Legguards
  ROW(1339114, 286),   -- Stained Shadowcraft Pants
  ROW(1339113, 286),   -- Tattered Dreadmist Leggings
  ROW(1339105, 286),   -- Burnished Boots of Might
  ROW(1339103, 286),   -- Champion Herod's Boots
  ROW(1339102, 286),   -- Mystical Boots of Elements
  ROW(1339104, 286),   -- Polished Boots of Valor
  ROW(1339101, 286),   -- Preened Ironfeather Boots
  ROW(1339100, 286),   -- Stained Shadowcraft Boots
  ROW(1339099, 286),   -- Tattered Dreadmist Boots
  ROW(1339112, 286),   -- Burnished Bracers of Might
  ROW(1339110, 286),   -- Champion Herod's Bracers
  ROW(1339109, 286),   -- Mystical Bracers of Elements
  ROW(1339111, 286),   -- Polished Bracers of Valor
  ROW(1339108, 286),   -- Preened Ironfeather Bracers
  ROW(1339107, 286),   -- Stained Shadowcraft Bracers
  ROW(1339106, 286),   -- Tattered Dreadmist Bracers
  ROW(1339133, 286),   -- Burnished Gauntlets of Might
  ROW(1339131, 286),   -- Champion Herod's Gloves
  ROW(1339130, 286),   -- Mystical Gloves of Elements
  ROW(1339132, 286),   -- Polished Gauntlets of Valor
  ROW(1339129, 286),   -- Preened Ironfeather Gloves
  ROW(1339128, 286),   -- Stained Shadowcraft Gloves
  ROW(1339127, 286),   -- Tattered Dreadmist Gloves
  ROW(1339084, 286),   -- Champion's Deathdealer Cloak
  ROW(1339090, 286),   -- Mystical Cloak of Elements
  ROW(1339085, 286),   -- Polished Cloak of Valor
  ROW(1339089, 286),   -- Preened Ironfeather Cloak
  ROW(1339088, 286),   -- Stained Shadowcraft Cloak
  ROW(1339087, 286),   -- Strengthened Cloak of Might
  ROW(1339086, 286)    -- Tattered Dreadmist Cloak
) `n` (`ItemID`, `BazaarTokenCost`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = `n`.`BazaarTokenCost`;

-- Tiraxis' heirloom list (900011): every heirloom and every heirloom cache.
DELETE FROM `npc_vendor`
WHERE `entry` = 900011 AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0) AND `item` IN (
  1339056,    -- Armor of Might - Experience Heirloom Cache
  1339063,    -- Armor of Might - Heirloom Cache
  1339054,    -- Champion's Battlegear - Experience Heirloom Cache
  1339061,    -- Champion's Battlegear - Heirloom Cache
  1339055,    -- Polished Battlegear of Valor - Experience Heirloom Cache
  1339062,    -- Polished Battlegear of Valor - Heirloom Cache
  1339052,    -- Preened Ironfeather Armor - Experience Heirloom Cache
  1339059,    -- Preened Ironfeather Armor - Heirloom Cache
  1339053,    -- Stained Shadowcraft Armor - Experience Heirloom Cache
  1339060,    -- Stained Shadowcraft Armor - Heirloom Cache
  1339051,    -- Tattered Dreadmist Raiment - Experience Heirloom Cache
  1339058,    -- Tattered Dreadmist Raiment - Heirloom Cache
  1339057,    -- The Mystical Elements - Experience Heirloom Cache
  1339064,    -- The Mystical Elements - Heirloom Cache
  1642944,    -- Balanced Heartseeker
  1644096,    -- Battleworn Thrash Blade
  1642948,    -- Devout Aurastone Hammer
  3148335,    -- Polished Observer's Shield
  1518202,    -- Rethreaded Left Bear Claw
  1518203,    -- Rethreaded Right Bear Claw
  1644091,    -- Sharpened Scarlet Kris
  1644094,    -- The Blessed Hammer of Grace
  3140350,    -- Urn of Aspiring Light
  1642945,    -- Venerable Dal'Rend's Sacred Charge
  1648716,    -- Venerable Mass of McGowan
  1642999,    -- Ancient Crossbow
  1642946,    -- Charmed Ancient Bone Bow
  1642896,    -- Druid Idol of Agility
  1642897,    -- Druid Idol of Spells
  1642901,    -- Paladin Libram of Healing
  1642900,    -- Paladin Libram of Strength
  1642898,    -- Shaman Totem of Agility
  1642899,    -- Shaman Totem of Spells
  1642902,    -- Thrown Axe of the Executioner
  1644093,    -- Upgraded Dwarven Hand Cannon
  1642846,    -- Wand of the Forgotten Lich
  1642992,    -- Discerning Eye of the Beast
  1644098,    -- Inherited Insignia of the Alliance
  1644097,    -- Inherited Insignia of the Horde
  1642991,    -- Swift Hand of Justice
  1642943,    -- Bloodied Arcanite Reaper
  1642947,    -- Dignified Headmaster's Charge
  1644095,    -- Grand Staff of Jordan
  1644092,    -- Reforged Truesilver Champion
  1648718,    -- Repurposed Lava Dredger
  3142943     -- Sturdied Arcanite Spear
);

-- Tiraxis' Convenience Items (900008): ItemExtendedCost ids that charge exactly that many Bazaar Tokens (975001).
UPDATE `npc_vendor` SET `ExtendedCost` = CASE `item`
  WHEN 505002 THEN 2983         -- Pristine Pouch: 100
  WHEN 818046 THEN 3014         -- Potion of Experience: 300
  WHEN 3001006 THEN 3016        -- Riding Tome: Apprentice Riding: 500
  WHEN 106955 THEN 3016         -- Tome of Specialization II: 500
  WHEN 106956 THEN 10335        -- Tome of Specialization III: 600
  WHEN 505003 THEN 10336        -- Heroes' Satchel: 700
  WHEN 106957 THEN 10337        -- Tome of Specialization IV: 800
  WHEN 818059 THEN 10339        -- Aura of Experience: 1000
  WHEN 106958 THEN 10339        -- Tome of Specialization V: 1000
  WHEN 1006971 THEN 10222       -- Dragon Hide Bag: 1200
  WHEN 106959 THEN 10343        -- Tome of Specialization VI: 1400
  WHEN 818061 THEN 10344        -- Aura of Reputation: 1500
  WHEN 3001005 THEN 10344       -- Riding Tome: Journeyman Riding: 1500
  WHEN 1004036 THEN 10345       -- Ironweave Bag: 1600
  WHEN 3211009 THEN 10349       -- Riding Tome: Expert Riding: 2000
  WHEN 97871 THEN 10359         -- Craftsman's Codex: 3000
  WHEN 1004040 THEN 10359       -- Mekkatorque's Neverending Storage Contraption: 3000
  WHEN 106960 THEN 10359        -- Tome of Specialization VII: 3000
  WHEN 777998 THEN 10359        -- Tradesman's Scroll: 3000
  WHEN 3211010 THEN 10379       -- Riding Tome: Artisan Riding: 5000
  WHEN 1179243 THEN 10404       -- Riding Tome: Extraordinary Riding: 7500
END
WHERE `entry` = 900008 AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0) AND `item` IN (
  505002, 818046, 3001006, 106955, 106956, 505003, 106957, 818059,
  106958, 1006971, 106959, 818061, 3001005, 1004036, 3211009, 97871,
  1004040, 106960, 777998, 3211010, 1179243
);
