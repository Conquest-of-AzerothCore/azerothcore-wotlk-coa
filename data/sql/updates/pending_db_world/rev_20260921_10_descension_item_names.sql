-- Rebranding: item names and descriptions, Ascension -> Descension
--
-- Only names where "Ascension" means the server. Blizzard's own
-- ("Seal of Ascension", "Garb of Royal Ascension") are left alone, and
-- so are the ability names ("Holy Ascension", "Accelerated Ascension") -
-- renaming those would leave a card no longer matching its spell.
--
-- Every row is named by its id instead of matched with LIKE, so nothing
-- outside this list can be caught by accident.

UPDATE `item_template` SET `name` = 'Descension Appearance 46522' WHERE `entry` = 46522;   -- Ascension Appearance 46522
UPDATE `item_template` SET `name` = 'Descension Appearance 46523' WHERE `entry` = 46523;   -- Ascension Appearance 46523
UPDATE `item_template` SET `name` = 'Descension Appearance 46524' WHERE `entry` = 46524;   -- Ascension Appearance 46524
UPDATE `item_template` SET `name` = 'Descension Appearance 46525' WHERE `entry` = 46525;   -- Ascension Appearance 46525
UPDATE `item_template` SET `name` = 'Descension Appearance 46526' WHERE `entry` = 46526;   -- Ascension Appearance 46526
UPDATE `item_template` SET `name` = 'Descension Appearance 46527' WHERE `entry` = 46527;   -- Ascension Appearance 46527
UPDATE `item_template` SET `name` = 'Ruthless Book of Descension' WHERE `entry` = 91461;   -- Ruthless Book of Ascension
UPDATE `item_template` SET `name` = 'Battleplate of Descension' WHERE `entry` = 97274;   -- Battleplate of Ascension
UPDATE `item_template` SET `name` = 'Gauntlets of Descension' WHERE `entry` = 97275;   -- Gauntlets of Ascension
UPDATE `item_template` SET `name` = 'Faceguard of Descension' WHERE `entry` = 97276;   -- Faceguard of Ascension
UPDATE `item_template` SET `name` = 'Greaves of Descension' WHERE `entry` = 97277;   -- Greaves of Ascension
UPDATE `item_template` SET `name` = 'Mantle of Descension' WHERE `entry` = 97278;   -- Mantle of Ascension
UPDATE `item_template` SET `name` = 'Bracers of Descension' WHERE `entry` = 97289;   -- Bracers of Ascension
UPDATE `item_template` SET `name` = 'Belt of Descension' WHERE `entry` = 97290;   -- Belt of Ascension
UPDATE `item_template` SET `name` = 'Boots of Descension' WHERE `entry` = 97291;   -- Boots of Ascension
UPDATE `item_template` SET `name` = 'Flames of Descension' WHERE `entry` = 97300;   -- Flames of Ascension
UPDATE `item_template` SET `name` = 'Cache of Descension' WHERE `entry` = 97314;   -- Cache of Ascension
UPDATE `item_template` SET `name` = 'Vestments of Descension' WHERE `entry` = 97317;   -- Vestments of Ascension
UPDATE `item_template` SET `name` = 'Challenger''s Book of Descension' WHERE `entry` = 97765;   -- Challenger's Book of Ascension
UPDATE `item_template` SET `name` = 'Cache of Descension' WHERE `entry` = 98006;   -- Cache of Ascension
UPDATE `item_template` SET `name` = 'Cache of Descension' WHERE `entry` = 98007;   -- Cache of Ascension
UPDATE `item_template` SET `name` = 'Nightmarish Book of Descension' WHERE `entry` = 98450;   -- Nightmarish Book of Ascension
UPDATE `item_template` SET `name` = 'Book of Descension' WHERE `entry` = 98457;   -- Book of Ascension
UPDATE `item_template` SET `name` = 'Book of Talented Descension' WHERE `entry` = 98458;   -- Book of Talented Ascension
UPDATE `item_template` SET `name` = 'Book of Skillful Descension' WHERE `entry` = 98459;   -- Book of Skillful Ascension
UPDATE `item_template` SET `name` = 'Verdant Book of Descension' WHERE `entry` = 98461;   -- Verdant Book of Ascension
UPDATE `item_template` SET `name` = 'Drafted Book of Descension' WHERE `entry` = 99386;   -- Drafted Book of Ascension
UPDATE `item_template` SET `name` = 'Ruthless Tabard of Descension' WHERE `entry` = 99984;   -- Ruthless Tabard of Ascension
UPDATE `item_template` SET `name` = 'Wild Book of Descension' WHERE `entry` = 102133;   -- Wild Book of Ascension
UPDATE `item_template` SET `name` = 'Mark of Descension' WHERE `entry` = 111381;   -- Mark of Ascension
UPDATE `item_template` SET `name` = 'Descension Appearance 132707' WHERE `entry` = 132707;   -- Ascension Appearance 132707
UPDATE `item_template` SET `name` = 'Descension Appearance 132719' WHERE `entry` = 132719;   -- Ascension Appearance 132719
UPDATE `item_template` SET `name` = 'Harlequin''s Book of Descension' WHERE `entry` = 229980;   -- Harlequin's Book of Ascension
UPDATE `item_template` SET `name` = 'Destined Book of Descension' WHERE `entry` = 253331;   -- Destined Book of Ascension
UPDATE `item_template` SET `name` = 'Descension Music Box' WHERE `entry` = 332190;   -- Ascension Music Box
UPDATE `item_template` SET `name` = 'Rune of Descension' WHERE `entry` = 375250;   -- Rune of Ascension
UPDATE `item_template` SET `name` = 'Warcraft Reborn Book of Descension' WHERE `entry` = 393610;   -- Warcraft Reborn Book of Ascension
UPDATE `item_template` SET `name` = 'Challenge Reward: Mark of Descension' WHERE `entry` = 414045;   -- Challenge Reward: Mark of Ascension
UPDATE `item_template` SET `name` = 'Beginner''s Book of Descension' WHERE `entry` = 414200;   -- Beginner's Book of Ascension
UPDATE `item_template` SET `name` = 'Bloodforged Book of Descension' WHERE `entry` = 499920;   -- Bloodforged Book of Ascension
UPDATE `item_template` SET `name` = 'Book of Descension' WHERE `entry` = 499992;   -- Book of Ascension
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (12,500)' WHERE `entry` = 509872;   -- Rune of Ascension Pouch (12,500)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (15,000)' WHERE `entry` = 509873;   -- Rune of Ascension Pouch (15,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (20,000)' WHERE `entry` = 509874;   -- Rune of Ascension Pouch (20,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (25,000)' WHERE `entry` = 509875;   -- Rune of Ascension Pouch (25,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (30,000)' WHERE `entry` = 509876;   -- Rune of Ascension Pouch (30,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (17,500)' WHERE `entry` = 509886;   -- Rune of Ascension Pouch (17,500)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (32,500)' WHERE `entry` = 509893;   -- Rune of Ascension Pouch (32,500)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (39,000)' WHERE `entry` = 509894;   -- Rune of Ascension Pouch (39,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (45,500)' WHERE `entry` = 509895;   -- Rune of Ascension Pouch (45,500)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (52,000)' WHERE `entry` = 509896;   -- Rune of Ascension Pouch (52,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (65,000)' WHERE `entry` = 509897;   -- Rune of Ascension Pouch (65,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (35,000)' WHERE `entry` = 518448;   -- Rune of Ascension Pouch (35,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (40,000)' WHERE `entry` = 518449;   -- Rune of Ascension Pouch (40,000)
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (50,000)' WHERE `entry` = 518450;   -- Rune of Ascension Pouch (50,000)
UPDATE `item_template` SET `name` = 'Tabard of Descension' WHERE `entry` = 597600;   -- Tabard of Ascension
UPDATE `item_template` SET `name` = 'Fel-Infused Tabard of Descension' WHERE `entry` = 597602;   -- Fel-Infused Tabard of Ascension
UPDATE `item_template` SET `name` = 'Icebound Tabard of Descension' WHERE `entry` = 597603;   -- Icebound Tabard of Ascension
UPDATE `item_template` SET `name` = 'Tabard of Blessed Descension' WHERE `entry` = 597800;   -- Tabard of Blessed Ascension
UPDATE `item_template` SET `name` = 'Reborn Book of Descension' WHERE `entry` = 637848;   -- Reborn Book of Ascension
UPDATE `item_template` SET `name` = 'Descension Survival Guide' WHERE `entry` = 777991;   -- Ascension Survival Guide
UPDATE `item_template` SET `name` = 'Boss Blitz Rune of Descension Pouch (200,000)' WHERE `entry` = 800902;   -- Boss Blitz Rune of Ascension Pouch (200,000)
UPDATE `item_template` SET `name` = 'Conqueror''s Tabard of Descension' WHERE `entry` = 1175624;   -- Conqueror's Tabard of Ascension
UPDATE `item_template` SET `name` = 'Unleashed Elemental Book of Descension' WHERE `entry` = 1777357;   -- Unleashed Elemental Book of Ascension
UPDATE `item_template` SET `name` = 'Unleashed Book of Descension' WHERE `entry` = 1777359;   -- Unleashed Book of Ascension
UPDATE `item_template` SET `name` = 'Tabard of Fanatical Descension' WHERE `entry` = 2073850;   -- Tabard of Fanatical Ascension
UPDATE `item_template` SET `name` = 'Rune of Descension Pouch (500,000)' WHERE `entry` = 2509893;   -- Rune of Ascension Pouch (500,000)
UPDATE `item_template` SET `name` = 'Necrotic Book of Descension' WHERE `entry` = 6300095;   -- Necrotic Book of Ascension

-- 68 items

-- The shop line in item descriptions, 974 rows carry it:
-- "...from other players, the auctionhouse, or the Ascension shop."
UPDATE `item_template` SET `description` = REPLACE(`description`, 'the Ascension shop', 'the lost shop') WHERE `description` LIKE '%the Ascension shop%';

-- Three travel guides sent players to ascension.gg for an alpha
-- realm Discord invite. Neither the realm nor the invite still exists.
UPDATE `item_template` SET `description` = 'It was all just a dream...' WHERE `entry` = 97318;
UPDATE `item_template` SET `description` = 'It was all just a dream...' WHERE `entry` = 101171;
UPDATE `item_template` SET `description` = 'It was all just a dream...' WHERE `entry` = 101493;
