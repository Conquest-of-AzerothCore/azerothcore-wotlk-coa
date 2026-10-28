-- Mounts that are no longer sold in the Vanity Store (rows removed, as set on the Rexxar realm).
-- A realm without these rows is unchanged.
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  203079,  -- Anu'relos's Reins
  49093,  -- Arktos
  612830,  -- Armored Obsidian Drake
  559594,  -- Armored Voidborne Noctivagant
  559595,  -- Armored Voidwing
  558650,  -- Beloved Raptor of an Ancient King
  559400,  -- Black Faire Nestling
  558606,  -- Black Nitro Junk
  558602,  -- Blue Nitro Junk
  199667,  -- Bound Blizzard
  559401,  -- Brown Faire Nestling
  558645,  -- Bubblegum Toy Train
  558641,  -- Classic Toy Train
  558646,  -- Coal Toy Train
  559599,  -- Darkwell Phoenix
  560504,  -- Deathly Spiritreaver
  560574,  -- Emberdeep Minecart
  1001619,  -- Felsteel Annihilator's Control Module
  558643,  -- Flame Toy Train
  1777413,  -- Glacial Tidestorm
  311704,  -- Gnomish "Eco-Friendly" Plane
  559402,  -- Green Faire Nestling
  558605,  -- Green Nitro Junk
  49095,  -- Incarnation: Arktos
  558642,  -- Intergalactic Toy Train
  203080,  -- Lumi'ara's Reins
  559405,  -- Mech Faire Nestling
  559367,  -- Mutant Void Rat
  203082,  -- Nyxaroth's Reins
  559403,  -- Pink Faire Nestling
  558603,  -- Purple Nitro Junk
  558604,  -- Red Nitro Junk
  99485,  -- Reins of the Accursed Wrathsteed
  283040,  -- Reins of The Headless Horseman's Ghoulish Charger
  49636,  -- Reins of the Onyxian Drake
  98490,  -- Reins of the Spectral Steed
  291915,  -- Reins of the Unbound Star-Eater
  1777416,  -- Restoration Deathwalker
  560573,  -- Shadowburn Minecart
  560506,  -- Shadowed Spiritreaver
  1175625,  -- Sigil of the Crimson Skyblazer
  499438,  -- Smoldering Ember Wyrm
  1777414,  -- Soultwisted Deathwalker
  560498,  -- Spiritborne Moose
  560500,  -- Spiritborne Spider
  560499,  -- Spiritborne Wolf
  558644,  -- Sunshine Toy Train
  19872,  -- Swift Razzashi Raptor
  19902,  -- Swift Zulian Tiger
  560575,  -- Titan-Delver Minecart
  203081,  -- Verdara's Reins
  559447,  -- Void Combat Airship
  559542,  -- Void Wonka
  559590,  -- Voidbound Bat
  559427,  -- Voidbound Force
  559592,  -- Voidbound Gryphon
  559591,  -- Voidbound Hippogryph
  559589,  -- Voidbound Wyvern
  1777415,  -- Wastewarped Deathwalker
  559406,  -- White Faire Nestling
  558639,  -- Wrathful Fel Reaver Head
  560505,  -- Wrathful Spiritreaver
  559404,  -- Yellow Faire Nestling
  558601  -- Yellow Nitro Junk
);

-- Mounts that drop from bosses and creatures (the vanity description says where): earned in game, not sold
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  559412,  -- Albino Floral Snail
  558675,  -- Amber Spiteful Frog
  499181,  -- Arboreal Gulper
  155655,  -- Archmage's Prismatic Disc: Arcane
  32458,  -- Ashes of Al'ar
  559414,  -- Autumnal Floral Snail
  559423,  -- Azure Carnivarus Cutting
  558651,  -- Azzar Faire Bear
  559520,  -- Azzar Faire Buzzsaw Ripper
  558634,  -- Azzar Faire Rocket
  558617,  -- B.L. 03 X-treme Rocket
  50250,  -- Big Love Rocket
  559433,  -- Black Goblin Aerial Propulsor
  558648,  -- Black Skittering Shadowfang
  559449,  -- Blue Gnomish Terratransformer
  559435,  -- Blue Goblin Aerial Propulsor
  558600,  -- Bullet Romper Warframe
  559421,  -- Carnivarus Cutting
  558672,  -- Cerulean Spiteful Frog
  558625,  -- Chestnut Duck
  1001622,  -- Corrupted Annihilator's Control Module
  559424,  -- Crimson Carnivarus Cutting
  558676,  -- Crimson Spiteful Frog
  558632,  -- Cute Pink Rocket
  558612,  -- Cyan Winged Wonka
  559547,  -- Cyan Wonka
  13335,  -- Deathcharger's Reins
  1001621,  -- Defiled Annihilator's Control Module
  559438,  -- Discarded Aerial Attraction: Series X
  558671,  -- Ebony Spiteful Frog
  558631,  -- Emerald Rocket
  559445,  -- Faire Firecracker
  559585,  -- Fel Raven
  559579,  -- Felcharger
  559584,  -- Felslate Basilisk
  559582,  -- Felsteel Arachnid
  558608,  -- Felsteel Wonka
  30480,  -- Fiery Warhorse's Reins
  1001620,  -- Frostbitten Annihilator's Control Module
  558616,  -- G.L.D. 02 X-treme Rocket
  558619,  -- G.R. 05 X-treme Rocket
  558652,  -- Gizmo Insignia Hat
  559417,  -- Goblin Racing Pod
  559415,  -- Goblin Tricycle
  558620,  -- Golden Crocolisk
  558633,  -- Golden Lunar Rocket
  558656,  -- Golden Rain Cloud
  37828,  -- Great Brewfest Kodo
  559419,  -- Great Treasure-Extractor G-3000
  559436,  -- Green Goblin Aerial Propulsor
  558797,  -- Green Winged Wonka
  559550,  -- Green Wonka
  558624,  -- Hateful Duck
  393448,  -- Heart of the Everlasting Cinderstalker
  559411,  -- Herbaceous Floral Snail
  558611,  -- Insignia Red Wonka
  8200177,  -- Jigglesworth Sr.'s Reins
  558678,  -- Jumping Azzar Robot Talkin
  558677,  -- Jumping Faire Robot Talkin
  558635,  -- Jumping Recycled Robot Talkin
  558637,  -- Jumping Rusty Robot Talkin
  558673,  -- Lemon Spiteful Frog
  559598,  -- Lightcharger
  558654,  -- Lightning Charged Cloud
  558629,  -- Lucky Lunar Rocket
  559448,  -- Luxurious Goblin Combat Cruiser
  558657,  -- Melancholic Rain Cloud
  558622,  -- Midnight Crocolisk
  499679,  -- Minion of Grumpus
  558749,  -- Navy Anti-gravity Office
  559549,  -- Ochre Wonka
  558752,  -- Opulent Anti-gravity Office
  558614,  -- Orange Winged Wonka
  558618,  -- P.R.P. 04 X-treme Rocket
  559422,  -- Pale Carnivarus Cutting
  558636,  -- Polished Jumping Recycled Robot Talkin
  170005,  -- Prestigious War Horse
  170006,  -- Prestigious War Wolf
  558613,  -- Purple Winged Wonka
  559548,  -- Purple Wonka
  558615,  -- R.D. 01 X-treme Rocket
  558621,  -- Radiant Crocolisk
  499364,  -- Razor-Lined Reins of Dark Portent
  559450,  -- Red Gnomish Terratransformer
  559434,  -- Red Goblin Aerial Propulsor
  559451,  -- Red Goblin Terratransformer
  558750,  -- Refined Anti-gravity Office
  343209,  -- Reins of the Betrayer's Felsworn Spire Terror
  343208,  -- Reins of the Betrayer's Savage Spire Terror
  343210,  -- Reins of the Betrayer's Supreme Spire Terror
  343211,  -- Reins of the Betrayer's Unscarred Spire Terror
  102107,  -- Reins of the Magmatic Steed
  32768,  -- Reins of the Raven Lord
  8199957,  -- Reins of the Red Magmashell
  558751,  -- Rusty Anti-gravity Office
  559519,  -- Rusty Buzzsaw Ripper
  558630,  -- Sapphire Rocket
  558649,  -- Scarlet Skittering Shadowfang
  558627,  -- Sea Foam Duck
  558669,  -- Shiny Tidewater Pincer
  558647,  -- Skittering Shadowfang
  559593,  -- Somber Torment
  558658,  -- Sparkling Cloud
  558628,  -- Sunray Duck
  33977,  -- Swift Brewfest Ram
  35513,  -- Swift White Hawkstrider
  37012,  -- The Horseman's Reins
  558670,  -- Tidewater Pincer
  559418,  -- Treasure-Extractor G-774
  559420,  -- Turbo Racer “Time Is Gold”
  559453,  -- Turbo-Blue Goblin Surfboard
  559416,  -- Turbo-Charged Goblin Tricycle
  559454,  -- Turbo-Green Goblin Surfboard
  559456,  -- Turbo-Ivory Goblin Surfboard
  559455,  -- Turbo-Red Goblin Surfboard
  559413,  -- Twilight Floral Snail
  559439,  -- Unstable Black Rocket-Missile
  559440,  -- Unstable Blue Rocket-Missile
  559441,  -- Unstable Green Rocket-Missile
  559442,  -- Unstable Purple Rocket-Missile
  559443,  -- Unstable Red Rocket-Missile
  559444,  -- Unstable Yellow Rocket-Missile
  558626,  -- Verdant River Duck
  558674,  -- Verdant Spiteful Frog
  559581,  -- Void Charger
  558623,  -- Weathered Crocolisk
  558655,  -- Whispering Snow Cloud
  559580,  -- Wrathful Felcharger
  559583,  -- Wrathful Felsteel Arachnid
  559437,  -- Yellow Goblin Aerial Propulsor
  559452,  -- Yellow Goblin Terratransformer
  558798,  -- Yellow Winged Wonka
  559551  -- Yellow Wonka
);

-- Quest-chain mounts: earned in game, not sold
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  978317,  -- Alabaster Thunderwing
  21176,  -- Black Qiraji Resonating Crystal
  1175635,  -- Charger
  1175634,  -- Dreadsteed
  8200028,  -- Felfire Steed
  98468,  -- Felsteed
  1777071,  -- Thalassian Charger
  1877071,  -- Thalassian Warhorse
  559203,  -- Undead Charger
  559202,  -- Undead Warhorse
  98467,  -- Warhorse
  46102  -- Whistle of the Venomhide Ravasaur
);
