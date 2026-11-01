-- Challenge and trial rewards were buyable in the Vanity tab with Bazaar Tokens (#9462). On Ascension they came only
-- from completing the trial, Hardcore/Ironman/Nightmare milestone or Raid Trial named in ChallengeRewards.dbc and
-- ChallengeGroupRewards.dbc. A price of 0 takes them off sale, as in rev_20261024_01; the rows are only written
-- on a realm that prices its store.
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
    10734, 20651, 76339, 76340, 76341, 76343, 77147, 77179, 77234, 77249, 78639, 82950, 82951, 82952, 82953, 82954,
    82955, 82956, 82957, 85321, 85342, 85343, 85344, 85345, 86188, 86661, 86682, 86683, 86684, 86685, 86846, 86887,
    86902, 90445, 90454, 92814, 92815, 92816, 92817, 92818, 92819, 92820, 92821, 97754, 97755, 97757, 97758, 97759,
    97761, 97762, 97763, 97768, 97770, 97853, 100646, 101908, 101909, 101910, 101911, 101912, 103870, 120716,
    140677, 140678, 140684, 140759, 140766, 140768, 140769, 140770, 140771, 140848, 141994, 153506, 154134, 170000,
    171194, 173449, 174069, 177927, 182428, 225862, 281597, 281603, 281609, 281621, 281627, 281633, 281639, 281645,
    281651, 281657, 281663, 281669, 298086, 298092, 298098, 298104, 298110, 298116, 298122, 298128, 298134, 298140,
    298146, 394415, 394416, 394417, 394418, 394419, 394420, 394421, 394422, 394423, 499363, 499367, 499933, 499943,
    500002, 500005, 500654, 509902, 509903, 509906, 555005, 574528, 612831, 621497, 621498, 621499, 621500, 621501,
    621502, 621503, 621504, 621505, 628079, 628080, 628081, 628082, 628083, 628084, 628085, 628086, 628087, 628092,
    628096, 680070, 680071, 680072, 680073, 680074, 680076, 680077, 680078, 680080, 700109, 700110, 700111, 700112,
    700113, 700114, 700115, 700116, 700117, 702117, 702118, 702119, 702120, 702121, 702122, 702123, 702124, 702125,
    732635, 732636, 732637, 732638, 732639, 732640, 732641, 732642, 732643, 734386, 734387, 734388, 734389, 734390,
    734391, 734392, 734393, 734394, 734401, 734402, 734403, 734404, 734405, 734406, 734407, 734408, 734409, 734410,
    734491, 734492, 734493, 734494, 734495, 734496, 734497, 734498, 734499, 909376, 909382, 909388, 909394, 909400,
    909406, 909412, 909418, 909424, 1001635, 1001642, 1001650, 1001651, 1001655, 1001662, 1001671, 1001675, 1001679,
    1001814, 1001815, 1001816, 1001817, 1001818, 1001819, 1001820, 1001821, 1001822, 1152543, 1777077, 6064647,
    8199960, 8200180, 8200181, 8200182, 8210123, 8210128, 8210154, 8210155, 8210156, 8210157, 8210158, 8210159,
    8210160, 8210161, 8210174, 8210193, 8210194
);
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES
  ROW(174069),  -- Artisan's Guild Tabard
  ROW(509906),  -- Beastmaster's Whistle: Tamable Thunder Lizard
  ROW(97770),  -- Belt of the Master Crafter
  ROW(702120),  -- Betrayer's Downfall
  ROW(92821),  -- Bladesnap Breastplate
  ROW(92820),  -- Bladesnap Gauntlets
  ROW(92819),  -- Bladesnap Girdle
  ROW(92818),  -- Bladesnap Helm
  ROW(92817),  -- Bladesnap Legplates
  ROW(92816),  -- Bladesnap Pauldrons
  ROW(92815),  -- Bladesnap Sabatons
  ROW(92814),  -- Bladesnap Vambraces
  ROW(8210128),  -- Blazing Irie Wings
  ROW(77249),  -- Bracers of the Banished
  ROW(140677),  -- C'thun Slayer's Cape
  ROW(140770),  -- C'thun Slayer's Cord
  ROW(140759),  -- C'thun Slayer's Gloves
  ROW(140766),  -- C'thun Slayer's Hood
  ROW(140768),  -- C'thun Slayer's Leggings
  ROW(140769),  -- C'thun Slayer's Mantle
  ROW(140678),  -- C'thun Slayer's Robe
  ROW(140684),  -- C'thun Slayer's Slippers
  ROW(140771),  -- C'thun Slayer's Wristwraps
  ROW(702124),  -- Candelabra
  ROW(8210193),  -- Conjured Divine Axe
  ROW(82950),  -- Contender's Revenant Belt
  ROW(82957),  -- Contender's Spirit Boots
  ROW(82956),  -- Contender's Spirit Bracers
  ROW(82953),  -- Contender's Spirit Breastplate
  ROW(82954),  -- Contender's Spirit Gauntlets
  ROW(82951),  -- Contender's Spirit Helm
  ROW(82955),  -- Contender's Spirit Legplates
  ROW(82952),  -- Contender's Spirit Shoulders
  ROW(612831),  -- Corrupted Grinning Reaver
  ROW(509902),  -- Dark Iron Core Hound
  ROW(702122),  -- Demon Blood Siphoner
  ROW(702118),  -- Dragon Killer
  ROW(574528),  -- Dream Raider's Shadowflame Greatsword
  ROW(177927),  -- Eldritch Scribe's Azure Garments
  ROW(509903),  -- Famous Flexing Instruction Guide
  ROW(1152543),  -- Fatebringer
  ROW(103870),  -- Felo'melorn
  ROW(90445),  -- Firerider Treads
  ROW(97853),  -- Gauntlets of the Master Crafter
  ROW(182428),  -- Gilded Sinfall Sword
  ROW(90454),  -- Girdle of the Galloping Giant
  ROW(10734),  -- Glamorous Geysergill
  ROW(97761),  -- Goggles of Pure Sight
  ROW(732637),  -- Gronn Slayer's Belt
  ROW(732636),  -- Gronn Slayer's Cloak
  ROW(732640),  -- Gronn Slayer's Gloves
  ROW(732635),  -- Gronn Slayer's Hood
  ROW(732641),  -- Gronn Slayer's Leggings
  ROW(732642),  -- Gronn Slayer's Pauldrons
  ROW(732638),  -- Gronn Slayer's Treads
  ROW(732639),  -- Gronn Slayer's Tunic
  ROW(732643),  -- Gronn Slayer's Wristguards
  ROW(680073),  -- Hakkar Slayer's Boots
  ROW(680074),  -- Hakkar Slayer's Bracers
  ROW(680072),  -- Hakkar Slayer's Buckle
  ROW(680071),  -- Hakkar Slayer's Cape
  ROW(680080),  -- Hakkar Slayer's Chest
  ROW(680076),  -- Hakkar Slayer's Gloves
  ROW(680070),  -- Hakkar Slayer's Helmet
  ROW(680077),  -- Hakkar Slayer's Leggings
  ROW(680078),  -- Hakkar Slayer's Pauldrons
  ROW(500005),  -- Heart of the Nightwing
  ROW(702123),  -- Highborne Ruin
  ROW(555005),  -- Hoax Unclaimed Belongings
  ROW(97758),  -- Homebound Portal
  ROW(97759),  -- Idol of Rage
  ROW(298110),  -- Illidari Slayer's Adornment
  ROW(298086),  -- Illidari Slayer's All-Seeing Eye
  ROW(298092),  -- Illidari Slayer's Altar
  ROW(298122),  -- Illidari Slayer's Clasp
  ROW(298128),  -- Illidari Slayer's Leggings
  ROW(298104),  -- Illidari Slayer's Ritual Harness
  ROW(298116),  -- Illidari Slayer's Sash
  ROW(298098),  -- Illidari Slayer's Shawl
  ROW(298134),  -- Illidari Slayer's Sleeves
  ROW(298146),  -- Illidari Slayer's Treads
  ROW(298140),  -- Illidari Slayer's Wristlace
  ROW(86188),  -- Inlaid Cricket Bracers
  ROW(170000),  -- Ironclad War Wolf
  ROW(734491),  -- Karazhan Conqueror's Crown
  ROW(734496),  -- Karazhan Conqueror's Gloves
  ROW(734498),  -- Karazhan Conqueror's Mantle
  ROW(734493),  -- Karazhan Conqueror's Moccasins
  ROW(734497),  -- Karazhan Conqueror's Pants
  ROW(734494),  -- Karazhan Conqueror's Robe
  ROW(734492),  -- Karazhan Conqueror's Scrolls
  ROW(734495),  -- Karazhan Conqueror's Tunic
  ROW(734499),  -- Karazhan Conqueror's Wraps
  ROW(702117),  -- Legion's Blade
  ROW(140848),  -- Legion's Blade(Off-Hand)
  ROW(153506),  -- Leviathan's Mark
  ROW(97754),  -- Lil' Bangalash
  ROW(97755),  -- Lil' Hogger
  ROW(8210155),  -- Nefarion Slayer's Chestguard
  ROW(8210174),  -- Nefarion Slayer's Cloak
  ROW(8210157),  -- Nefarion Slayer's Gauntlets
  ROW(8210160),  -- Nefarion Slayer's Girdle
  ROW(8210154),  -- Nefarion Slayer's Helm
  ROW(8210158),  -- Nefarion Slayer's Legguards
  ROW(8210159),  -- Nefarion Slayer's Shoulders
  ROW(8210156),  -- Nefarion Slayer's Warboots
  ROW(8210161),  -- Nefarion Slayer's Wristguards
  ROW(173449),  -- Nefarious Tormentor's Mask
  ROW(97757),  -- Nightmarish
  ROW(734406),  -- Nordrassil Defender's Chestplate
  ROW(734403),  -- Nordrassil Defender's Cloak
  ROW(734407),  -- Nordrassil Defender's Gauntlets
  ROW(734404),  -- Nordrassil Defender's Girdle
  ROW(734402),  -- Nordrassil Defender's Greathelm
  ROW(734408),  -- Nordrassil Defender's Greaves
  ROW(734409),  -- Nordrassil Defender's Pauldrons
  ROW(734405),  -- Nordrassil Defender's Sabatons
  ROW(734410),  -- Nordrassil Defender's Vambraces
  ROW(499363),  -- Ny'alotha Allseer
  ROW(702121),  -- Oaken Defender's Force
  ROW(1777077),  -- Obsidian Worldbreaker
  ROW(909388),  -- Onyxia Slayer's Cape
  ROW(909424),  -- Onyxia Slayer's Cinch
  ROW(909382),  -- Onyxia Slayer's Cowl
  ROW(909400),  -- Onyxia Slayer's Footpads
  ROW(909412),  -- Onyxia Slayer's Gloves
  ROW(909418),  -- Onyxia Slayer's Leggings
  ROW(909376),  -- Onyxia Slayer's Mantle
  ROW(909394),  -- Onyxia Slayer's Tunic
  ROW(909406),  -- Onyxia Slayer's Wristguard
  ROW(20651),  -- Orange Murloc Egg
  ROW(702119),  -- Pack Leader's Spear
  ROW(394417),  -- Pit lord Slayer's Belt
  ROW(394415),  -- Pit lord Slayer's Boots
  ROW(394423),  -- Pit lord Slayer's Cloak
  ROW(394421),  -- Pit lord Slayer's Crown
  ROW(394418),  -- Pit lord Slayer's Gloves
  ROW(394416),  -- Pit lord Slayer's Leggings
  ROW(394420),  -- Pit lord Slayer's Mantle
  ROW(394419),  -- Pit lord Slayer's Robes
  ROW(394422),  -- Pit lord Slayer's Staff
  ROW(1001814),  -- Qiraji Slayer's Drape
  ROW(1001817),  -- Qiraji Slayer's Handwraps
  ROW(1001816),  -- Qiraji Slayer's Hood
  ROW(1001818),  -- Qiraji Slayer's Leggings
  ROW(1001822),  -- Qiraji Slayer's Robe
  ROW(1001815),  -- Qiraji Slayer's Sash
  ROW(1001819),  -- Qiraji Slayer's Slippers
  ROW(1001820),  -- Qiraji Slayer's Tunic
  ROW(1001821),  -- Qiraji Slayer's Wraps
  ROW(700116),  -- Ragnaros Slayer's Carapace
  ROW(700113),  -- Ragnaros Slayer's Chausses
  ROW(700110),  -- Ragnaros Slayer's Cloak
  ROW(700112),  -- Ragnaros Slayer's Gauntlets
  ROW(700117),  -- Ragnaros Slayer's Girdle
  ROW(700115),  -- Ragnaros Slayer's Greaves
  ROW(700114),  -- Ragnaros Slayer's Shoulderplates
  ROW(700109),  -- Ragnaros Slayer's Vambraces
  ROW(700111),  -- Ragnaros Slayer's Visage
  ROW(78639),  -- Red Tentacular Belt
  ROW(120716),  -- Red Tentacular Boots
  ROW(100646),  -- Red Tentacular Bracers
  ROW(101908),  -- Red Tentacular Gloves
  ROW(101910),  -- Red Tentacular Leggings
  ROW(101912),  -- Red Tentacular Mantle
  ROW(101911),  -- Red Tentacular Robes
  ROW(101909),  -- Red Tentacular Shroud
  ROW(86683),  -- Red Tiger Battleplate
  ROW(86902),  -- Red Tiger Belt
  ROW(86887),  -- Red Tiger Boots
  ROW(86846),  -- Red Tiger Bracers
  ROW(86661),  -- Red Tiger Faceguard
  ROW(86682),  -- Red Tiger Gauntlets
  ROW(86685),  -- Red Tiger Greaves
  ROW(86684),  -- Red Tiger Mantle
  ROW(499943),  -- Reins of the Felsaber
  ROW(499933),  -- Reins of the Golden Vulpine Familiar
  ROW(225862),  -- Reins of the Winter Harvesthog
  ROW(8199960),  -- Reins of the Yellow Magma Slug
  ROW(702125),  -- Rushing-wave Blade
  ROW(8200182),  -- Saffron Slimesaber's Reins
  ROW(8200181),  -- Scarlet Slimesaber's Reins
  ROW(1001635),  -- Scourge Slayer's Cape
  ROW(1001655),  -- Scourge Slayer's Cinch
  ROW(1001675),  -- Scourge Slayer's Cowl
  ROW(1001650),  -- Scourge Slayer's Gloves
  ROW(1001671),  -- Scourge Slayer's Leggings
  ROW(1001651),  -- Scourge Slayer's Mantle
  ROW(1001642),  -- Scourge Slayer's Slippers
  ROW(1001679),  -- Scourge Slayer's Tunic
  ROW(1001662),  -- Scourge Slayer's Wristwraps
  ROW(628081),  -- Serpent Slayer's Belt
  ROW(628087),  -- Serpent Slayer's Bracers
  ROW(628080),  -- Serpent Slayer's Cape
  ROW(628084),  -- Serpent Slayer's Gloves
  ROW(628096),  -- Serpent Slayer's Gloves (Two-Sided)
  ROW(628079),  -- Serpent Slayer's Hat
  ROW(628083),  -- Serpent Slayer's Jacket
  ROW(628085),  -- Serpent Slayer's Leggings
  ROW(628086),  -- Serpent Slayer's Pauldrons
  ROW(628092),  -- Serpent Slayer's Pauldrons (One-Sided)
  ROW(628082),  -- Serpent Slayer's Sabatons
  ROW(500654),  -- Sharpened Rock
  ROW(97762),  -- Sigil of Graves
  ROW(97763),  -- Sigil of the Void Shardling
  ROW(154134),  -- Staff of Death
  ROW(171194),  -- Succession
  ROW(734390),  -- Sunwell Seeker's Binding
  ROW(734392),  -- Sunwell Seeker's Blazewraps
  ROW(734388),  -- Sunwell Seeker's Clasp
  ROW(734401),  -- Sunwell Seeker's Clasp (Buckle)
  ROW(734389),  -- Sunwell Seeker's Clutches
  ROW(734391),  -- Sunwell Seeker's Grasp
  ROW(734393),  -- Sunwell Seeker's Horned Memento
  ROW(734386),  -- Sunwell Seeker's Scowl
  ROW(734387),  -- Sunwell Seeker's Shawl
  ROW(734394),  -- Sunwell Seeker's Wrist Wraps
  ROW(97768),  -- Survivalist's Campsite
  ROW(621505),  -- Tempest Tamer's Bracers
  ROW(621501),  -- Tempest Tamer's Breastplate
  ROW(621499),  -- Tempest Tamer's Buckle
  ROW(621498),  -- Tempest Tamer's Cloak
  ROW(621502),  -- Tempest Tamer's Gauntlets
  ROW(621503),  -- Tempest Tamer's Greaves
  ROW(621497),  -- Tempest Tamer's Helmet
  ROW(621504),  -- Tempest Tamer's Pauldrons
  ROW(621500),  -- Tempest Tamer's Sabatons
  ROW(77179),  -- Tentacular Belt
  ROW(77234),  -- Tentacular Boots
  ROW(76343),  -- Tentacular Gloves
  ROW(77147),  -- Tentacular Hood
  ROW(76341),  -- Tentacular Leggings
  ROW(76340),  -- Tentacular Robes
  ROW(76339),  -- Tentacular Shroud
  ROW(500002),  -- The Hivemind
  ROW(6064647),  -- Time-Lost Scythe
  ROW(141994),  -- Titan's Spear
  ROW(281633),  -- Trollbane's Buckle
  ROW(281609),  -- Trollbane's Cloak
  ROW(281645),  -- Trollbane's Eviscerators
  ROW(281627),  -- Trollbane's Faulds
  ROW(281669),  -- Trollbane's Footpads
  ROW(281621),  -- Trollbane's Hide
  ROW(281639),  -- Trollbane's Leggings
  ROW(281597),  -- Trollbane's Mask
  ROW(281603),  -- Trollbane's Maw
  ROW(281657),  -- Trollbane's Treads
  ROW(281663),  -- Trollbane's Vest
  ROW(281651),  -- Trollbane's Wristwraps
  ROW(499367),  -- Uncorrupted Voidwing
  ROW(8200180),  -- Violet Slimesaber's Reins
  ROW(8210194),  -- White Knight's Blade
  ROW(85343),  -- White Tiger Battleplate
  ROW(85321),  -- White Tiger Faceguard
  ROW(85342),  -- White Tiger Gauntlets
  ROW(85345),  -- White Tiger Greaves
  ROW(85344),  -- White Tiger Mantle
  ROW(8210123)  -- Wings of Haunting Nightmare
) AS `n` (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
