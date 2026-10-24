-- Items taken out of the Vanity Store must keep a row with price 0, not lose their row. Without a row the server
-- falls back to the price in VanityCollection.dbc, which some realms' DBC sets for these items, so deleting the row
-- (#8554, #8686, #8787) can leave them buyable. A price of 0 is refused ("That item cannot be bought with Bazaar Tokens").
-- Only on a realm that fills the table: on an empty one, rows here would be the whole store.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 0
FROM (VALUES
  ROW(1644102),  -- Aged Pauldrons of The Five Thunders
  ROW(558772),  -- Air Blade Racer Controller
  ROW(978317),  -- Alabaster Thunderwing
  ROW(559412),  -- Albino Floral Snail
  ROW(500008),  -- Allegiance Banner: Argent Dawn
  ROW(558675),  -- Amber Spiteful Frog
  ROW(1642999),  -- Ancient Crossbow
  ROW(1500005),  -- Ancient Tuskarr Horn
  ROW(203079),  -- Anu'relos's Reins
  ROW(499181),  -- Arboreal Gulper
  ROW(199736),  -- Archmage's Great Raven Cache
  ROW(155655),  -- Archmage's Prismatic Disc: Arcane
  ROW(49093),  -- Arktos
  ROW(612830),  -- Armored Obsidian Drake
  ROW(559594),  -- Armored Voidborne Noctivagant
  ROW(559595),  -- Armored Voidwing
  ROW(32458),  -- Ashes of Al'ar
  ROW(509505),  -- Aspect of the Nap
  ROW(461563),  -- Aura of Fel Power
  ROW(818061),  -- Aura of Reputation
  ROW(461566),  -- Aura of Souls
  ROW(559414),  -- Autumnal Floral Snail
  ROW(300112),  -- Autumnal Matriarch's Blooming Wake
  ROW(559423),  -- Azure Carnivarus Cutting
  ROW(558754),  -- Azzar Faire Beach Chair
  ROW(558651),  -- Azzar Faire Bear
  ROW(559520),  -- Azzar Faire Buzzsaw Ripper
  ROW(558786),  -- Azzar Faire Picnic
  ROW(558634),  -- Azzar Faire Rocket
  ROW(558617),  -- B.L. 03 X-treme Rocket
  ROW(1642944),  -- Balanced Heartseeker
  ROW(110003),  -- Banner of Recruitment
  ROW(666002),  -- Battle for Mount Hyjal Medallion
  ROW(558771),  -- Battle Trak Racer Controller
  ROW(1644096),  -- Battleworn Thrash Blade
  ROW(558650),  -- Beloved Raptor of an Ancient King
  ROW(509883),  -- Big Game Hunter's Tracker Belt
  ROW(50250),  -- Big Love Rocket
  ROW(559400),  -- Black Faire Nestling
  ROW(559433),  -- Black Goblin Aerial Propulsor
  ROW(558606),  -- Black Nitro Junk
  ROW(21176),  -- Black Qiraji Resonating Crystal
  ROW(558648),  -- Black Skittering Shadowfang
  ROW(666001),  -- Blackwing Lair Medallion
  ROW(97748),  -- Blightcaller's Disguise
  ROW(977220),  -- Bloodforged Contract
  ROW(1642943),  -- Bloodied Arcanite Reaper
  ROW(499604),  -- Blue Dragon Body Costume
  ROW(499605),  -- Blue Dragon Head Costume
  ROW(499603),  -- Blue Dragon Tail Costume
  ROW(559449),  -- Blue Gnomish Terratransformer
  ROW(559435),  -- Blue Goblin Aerial Propulsor
  ROW(558602),  -- Blue Nitro Junk
  ROW(100009),  -- Bottled Qiraji Swarm
  ROW(199667),  -- Bound Blizzard
  ROW(34686),  -- Brazier of Dancing Flames
  ROW(33927),  -- Brewfest Pony Keg
  ROW(559401),  -- Brown Faire Nestling
  ROW(558645),  -- Bubblegum Toy Train
  ROW(558600),  -- Bullet Romper Warframe
  ROW(1339098),  -- Burnished Belt of Might
  ROW(1339105),  -- Burnished Boots of Might
  ROW(1339112),  -- Burnished Bracers of Might
  ROW(3148685),  -- Burnished Breastplate of Might
  ROW(1339133),  -- Burnished Gauntlets of Might
  ROW(1339126),  -- Burnished Helmet of Might
  ROW(1339119),  -- Burnished Platelegs of Might
  ROW(3142949),  -- Burnished Spaulders of Might
  ROW(559421),  -- Carnivarus Cutting
  ROW(49704),  -- Carved Ogre Idol
  ROW(509892),  -- Celestial Personal Bank
  ROW(558672),  -- Cerulean Spiteful Frog
  ROW(339036),  -- Chakra Chug (Rank 1)
  ROW(439071),  -- Chakra Chug (Rank 2)
  ROW(439072),  -- Chakra Chug (Rank 3)
  ROW(439073),  -- Chakra Chug (Rank 4)
  ROW(439074),  -- Chakra Chug (Rank 5)
  ROW(439075),  -- Chakra Chug (Rank 6)
  ROW(439076),  -- Chakra Chug (Rank 7)
  ROW(439077),  -- Chakra Chug (Rank 8)
  ROW(1339096),  -- Champion Herod's Belt
  ROW(1339103),  -- Champion Herod's Boots
  ROW(1339110),  -- Champion Herod's Bracers
  ROW(1339131),  -- Champion Herod's Gloves
  ROW(1339124),  -- Champion Herod's Helmet
  ROW(1339117),  -- Champion Herod's Legguards
  ROW(1642950),  -- Champion Herod's Shoulder
  ROW(1648677),  -- Champion's Deathdealer Breastplate
  ROW(1339084),  -- Champion's Deathdealer Cloak
  ROW(1175635),  -- Charger
  ROW(1642946),  -- Charmed Ancient Bone Bow
  ROW(558625),  -- Chestnut Duck
  ROW(532576),  -- Chromatic Actuator
  ROW(558641),  -- Classic Toy Train
  ROW(339030),  -- Cleanse (Rank 1)
  ROW(439030),  -- Cleanse (Rank 2)
  ROW(439031),  -- Cleanse (Rank 3)
  ROW(439032),  -- Cleanse (Rank 4)
  ROW(439033),  -- Cleanse (Rank 5)
  ROW(439034),  -- Cleanse (Rank 6)
  ROW(439045),  -- Cleanse (Rank 7)
  ROW(439046),  -- Cleanse (Rank 8)
  ROW(558646),  -- Coal Toy Train
  ROW(499584),  -- Coin of Many Faces
  ROW(559540),  -- Comfy Wonka Egg
  ROW(500647),  -- Comical Banner: Ghosted
  ROW(500012),  -- Comical Banner: Khadgar
  ROW(500009),  -- Comical Banner: Salty
  ROW(500655),  -- Comical Banner: Skol!
  ROW(97318),  -- Conquest of Azeroth Travel Guide
  ROW(1001622),  -- Corrupted Annihilator's Control Module
  ROW(559424),  -- Crimson Carnivarus Cutting
  ROW(558676),  -- Crimson Spiteful Frog
  ROW(339033),  -- Curing (Rank 1)
  ROW(439035),  -- Curing (Rank 2)
  ROW(439036),  -- Curing (Rank 3)
  ROW(439133),  -- Curing (Rank 4)
  ROW(439134),  -- Curing (Rank 5)
  ROW(439135),  -- Curing (Rank 6)
  ROW(439136),  -- Curing (Rank 7)
  ROW(439137),  -- Curing (Rank 8)
  ROW(558632),  -- Cute Pink Rocket
  ROW(558612),  -- Cyan Winged Wonka
  ROW(559547),  -- Cyan Wonka
  ROW(38301),  -- D.I.S.C.O.
  ROW(1326924),  -- Dark Ranger's Disguise
  ROW(559599),  -- Darkwell Phoenix
  ROW(532577),  -- Dazzling Rod
  ROW(13335),  -- Deathcharger's Reins
  ROW(560504),  -- Deathly Spiritreaver
  ROW(1001621),  -- Defiled Annihilator's Control Module
  ROW(1642948),  -- Devout Aurastone Hammer
  ROW(1642947),  -- Dignified Headmaster's Charge
  ROW(558774),  -- Dirt Devil Racer Controller
  ROW(559438),  -- Discarded Aerial Attraction: Series X
  ROW(1642992),  -- Discerning Eye of the Beast
  ROW(16309),  -- Drakefire Amulet
  ROW(1175634),  -- Dreadsteed
  ROW(1642896),  -- Druid Idol of Agility
  ROW(1642897),  -- Druid Idol of Spells
  ROW(559564),  -- Duckmageddon 5000
  ROW(82313),  -- Ebon Blade Banner
  ROW(558671),  -- Ebony Spiteful Frog
  ROW(298156),  -- Eldritch Embrace of the Hexflame Coven
  ROW(560574),  -- Emberdeep Minecart
  ROW(558631),  -- Emerald Rocket
  ROW(53834),  -- Empty Heart Container
  ROW(8000014),  -- Empty Water Chalice
  ROW(298154),  -- Esoteric Embrace of the Hexflame Coven
  ROW(467790),  -- Everlasting Path of Cenarius
  ROW(1644103),  -- Exceptional Stormshroud Shoulders
  ROW(1644107),  -- Exquisite Sunderseer Mantle
  ROW(559445),  -- Faire Firecracker
  ROW(559539),  -- Faire Spotlight
  ROW(977026),  -- Feather of Ancients: TBC
  ROW(559597),  -- Fel Alteration Codex
  ROW(559585),  -- Fel Raven
  ROW(1903515),  -- Fel-Infused Gateway
  ROW(559579),  -- Felcharger
  ROW(8200028),  -- Felfire Steed
  ROW(3001008),  -- Felforged Tome: Apprentice Riding
  ROW(79316),  -- Felforged Tome: Fel Blood V
  ROW(3001007),  -- Felforged Tome: Journeyman Riding
  ROW(101170),  -- Felforged Tome: Relentless V
  ROW(79315),  -- Felforged Tome: Rush of Adrenaline V
  ROW(559584),  -- Felslate Basilisk
  ROW(98468),  -- Felsteed
  ROW(1001619),  -- Felsteel Annihilator's Control Module
  ROW(559582),  -- Felsteel Arachnid
  ROW(558608),  -- Felsteel Wonka
  ROW(11),  -- Felstone
  ROW(559532),  -- Female Goblin Wonkaphile Costume
  ROW(1000498),  -- Feral Tome: Swift Flight Form
  ROW(30480),  -- Fiery Warhorse's Reins
  ROW(33223),  -- Fishing Chair
  ROW(558643),  -- Flame Toy Train
  ROW(558781),  -- Flying Toy Ship Controller
  ROW(45063),  -- Foam Sword Rack
  ROW(134988),  -- Founder's Charter
  ROW(977020),  -- Founder's Charter
  ROW(99290),  -- Freedom Fizz (Rank 1)
  ROW(99291),  -- Freedom Fizz (Rank 2)
  ROW(99292),  -- Freedom Fizz (Rank 3)
  ROW(99293),  -- Freedom Fizz (Rank 4)
  ROW(99294),  -- Freedom Fizz (Rank 5)
  ROW(99295),  -- Freedom Fizz (Rank 6)
  ROW(99296),  -- Freedom Fizz (Rank 7)
  ROW(99297),  -- Freedom Fizz (Rank 8)
  ROW(339042),  -- Frogduck Morph Machine
  ROW(1001620),  -- Frostbitten Annihilator's Control Module
  ROW(300107),  -- Frozen Matriarch's Blooming Wake
  ROW(558616),  -- G.L.D. 02 X-treme Rocket
  ROW(558619),  -- G.R. 05 X-treme Rocket
  ROW(339035),  -- Genius Juice (Rank 1)
  ROW(439064),  -- Genius Juice (Rank 2)
  ROW(439065),  -- Genius Juice (Rank 3)
  ROW(439066),  -- Genius Juice (Rank 4)
  ROW(439067),  -- Genius Juice (Rank 5)
  ROW(439068),  -- Genius Juice (Rank 6)
  ROW(439069),  -- Genius Juice (Rank 7)
  ROW(439070),  -- Genius Juice (Rank 8)
  ROW(298157),  -- Gilded Embrace of the Hexflame Coven
  ROW(558652),  -- Gizmo Insignia Hat
  ROW(1777413),  -- Glacial Tidestorm
  ROW(311704),  -- Gnomish "Eco-Friendly" Plane
  ROW(33219),  -- Goblin Gumbo Kettle
  ROW(509901),  -- Goblin Money Printer
  ROW(559417),  -- Goblin Racing Pod
  ROW(559415),  -- Goblin Tricycle
  ROW(1777010),  -- Godslayer's Charter
  ROW(558620),  -- Golden Crocolisk
  ROW(558633),  -- Golden Lunar Rocket
  ROW(558656),  -- Golden Rain Cloud
  ROW(505000),  -- Gordok Ogre Suit
  ROW(1644095),  -- Grand Staff of Jordan
  ROW(1777173),  -- Greasy Goblin Gizmo
  ROW(37828),  -- Great Brewfest Kodo
  ROW(559419),  -- Great Treasure-Extractor G-3000
  ROW(101428),  -- Greater Insignia of the Burning Legion
  ROW(499601),  -- Green Dragon Body Costume
  ROW(499602),  -- Green Dragon Head Costume
  ROW(499600),  -- Green Dragon Tail Costume
  ROW(559402),  -- Green Faire Nestling
  ROW(559436),  -- Green Goblin Aerial Propulsor
  ROW(558605),  -- Green Nitro Junk
  ROW(558797),  -- Green Winged Wonka
  ROW(559550),  -- Green Wonka
  ROW(97749),  -- Grove Ranger's Guise: Windrunner
  ROW(97760),  -- Guise of the Dormant Vrykul
  ROW(509885),  -- Guise of the Dungeon Saurok
  ROW(97764),  -- Guise of the Nightmare Satyr
  ROW(197767),  -- Guise of the Plague Spreader
  ROW(97767),  -- Guise of the Purple Slime Skeleton
  ROW(339071),  -- Harm Repellant Remedy (Rank 1)
  ROW(439099),  -- Harm Repellant Remedy (Rank 2)
  ROW(439100),  -- Harm Repellant Remedy (Rank 3)
  ROW(439101),  -- Harm Repellant Remedy (Rank 4)
  ROW(439102),  -- Harm Repellant Remedy (Rank 5)
  ROW(439103),  -- Harm Repellant Remedy (Rank 6)
  ROW(439104),  -- Harm Repellant Remedy (Rank 7)
  ROW(439105),  -- Harm Repellant Remedy (Rank 8)
  ROW(558624),  -- Hateful Duck
  ROW(558773),  -- Havac Racer Controller
  ROW(393448),  -- Heart of the Everlasting Cinderstalker
  ROW(99269),  -- Hearty Heal Upgrade (Rank 1)
  ROW(99270),  -- Hearty Heal Upgrade (Rank 2)
  ROW(99271),  -- Hearty Heal Upgrade (Rank 3)
  ROW(99272),  -- Hearty Heal Upgrade (Rank 4)
  ROW(99273),  -- Hearty Heal Upgrade (Rank 5)
  ROW(99274),  -- Hearty Heal Upgrade (Rank 6)
  ROW(99275),  -- Hearty Heal Upgrade (Rank 7)
  ROW(99276),  -- Hearty Heal Upgrade (Rank 8)
  ROW(559411),  -- Herbaceous Floral Snail
  ROW(558776),  -- Hobgoblin Costume
  ROW(499607),  -- Horse Head Costume
  ROW(499606),  -- Horse Tail Costume
  ROW(298152),  -- Illidari Slayer's Embrace
  ROW(32542),  -- Imp in a Ball
  ROW(339063),  -- Incantation Intensifier (Rank 1)
  ROW(439085),  -- Incantation Intensifier (Rank 2)
  ROW(439086),  -- Incantation Intensifier (Rank 3)
  ROW(439087),  -- Incantation Intensifier (Rank 4)
  ROW(439088),  -- Incantation Intensifier (Rank 5)
  ROW(439089),  -- Incantation Intensifier (Rank 6)
  ROW(439090),  -- Incantation Intensifier (Rank 7)
  ROW(439091),  -- Incantation Intensifier (Rank 8)
  ROW(49095),  -- Incarnation: Arktos
  ROW(193923),  -- Incarnation: One With The Light Blue Cache
  ROW(193924),  -- Incarnation: One With The Light Blue-Green Cache
  ROW(193925),  -- Incarnation: One With The Light Fiery Cache
  ROW(193922),  -- Incarnation: One With The Light Gold Cache
  ROW(193921),  -- Incarnation: One With The Light Green Cache
  ROW(193919),  -- Incarnation: One With The Light Pink Cache
  ROW(193918),  -- Incarnation: One With The Light Purple Cache
  ROW(193920),  -- Incarnation: One With The Light Red Cache
  ROW(1644098),  -- Inherited Insignia of the Alliance
  ROW(1644097),  -- Inherited Insignia of the Horde
  ROW(409),  -- Insignia of the Burning Legion
  ROW(558611),  -- Insignia Red Wonka
  ROW(558642),  -- Intergalactic Toy Train
  ROW(339041),  -- Interrupt Rod (Rank 1)
  ROW(439057),  -- Interrupt Rod (Rank 2)
  ROW(439058),  -- Interrupt Rod (Rank 3)
  ROW(439059),  -- Interrupt Rod (Rank 4)
  ROW(439060),  -- Interrupt Rod (Rank 5)
  ROW(439061),  -- Interrupt Rod (Rank 6)
  ROW(439062),  -- Interrupt Rod (Rank 7)
  ROW(439063),  -- Interrupt Rod (Rank 8)
  ROW(8200177),  -- Jigglesworth Sr.'s Reins
  ROW(90131),  -- John's Ball
  ROW(559586),  -- Jumper's Pedestal
  ROW(558678),  -- Jumping Azzar Robot Talkin
  ROW(558677),  -- Jumping Faire Robot Talkin
  ROW(558635),  -- Jumping Recycled Robot Talkin
  ROW(558637),  -- Jumping Rusty Robot Talkin
  ROW(1644105),  -- Lasting Feralheart Spaulders
  ROW(100576),  -- Legion Pocket Portal
  ROW(558673),  -- Lemon Spiteful Frog
  ROW(505001),  -- Light of Ascension
  ROW(559598),  -- Lightcharger
  ROW(558654),  -- Lightning Charged Cloud
  ROW(980033),  -- Limited Edition 4.20.2020 Peace Pipe
  ROW(702454),  -- Limitless Healing Potion
  ROW(702455),  -- Limitless Mana Potion
  ROW(998529),  -- Limitless Noggenfogger Elixir
  ROW(509907),  -- Lonely Bonfire
  ROW(339070),  -- Long Haul Liquid (Rank 1)
  ROW(439092),  -- Long Haul Liquid (Rank 2)
  ROW(439093),  -- Long Haul Liquid (Rank 3)
  ROW(439094),  -- Long Haul Liquid (Rank 4)
  ROW(439095),  -- Long Haul Liquid (Rank 5)
  ROW(439096),  -- Long Haul Liquid (Rank 6)
  ROW(439097),  -- Long Haul Liquid (Rank 7)
  ROW(439098),  -- Long Haul Liquid (Rank 8)
  ROW(190190),  -- Loot-Transfigurator 5000
  ROW(558629),  -- Lucky Lunar Rocket
  ROW(203080),  -- Lumi'ara's Reins
  ROW(559448),  -- Luxurious Goblin Combat Cruiser
  ROW(558790),  -- Magic Faire Stone
  ROW(559531),  -- Male Goblin Wonkaphile Costume
  ROW(509890),  -- Manastorm's Duplicator
  ROW(449050),  -- Manastorm: Endless Manastorm Potion (Rank 2)
  ROW(558770),  -- Marauder Racer Controller
  ROW(559405),  -- Mech Faire Nestling
  ROW(558657),  -- Melancholic Rain Cloud
  ROW(558622),  -- Midnight Crocolisk
  ROW(453836),  -- Millhouse Mixtape
  ROW(1300179),  -- Millhouse Mobility Mixture
  ROW(1300186),  -- Millhouse Mobility Mixture (Upgrade Rank 1)
  ROW(1300187),  -- Millhouse Mobility Mixture (Upgrade Rank 2)
  ROW(1300188),  -- Millhouse Mobility Mixture (Upgrade Rank 3)
  ROW(1300189),  -- Millhouse Mobility Mixture (Upgrade Rank 4)
  ROW(1300190),  -- Millhouse Mobility Mixture (Upgrade Rank 5)
  ROW(1300191),  -- Millhouse Mobility Mixture (Upgrade Rank 6)
  ROW(1300192),  -- Millhouse Mobility Mixture (Upgrade Rank 7)
  ROW(233223),  -- Millhouse's Mystical Transportation Device
  ROW(499679),  -- Minion of Grumpus
  ROW(666000),  -- Molten Core Medallion
  ROW(339074),  -- Motion Lotion (Rank 1)
  ROW(439113),  -- Motion Lotion (Rank 2)
  ROW(439114),  -- Motion Lotion (Rank 3)
  ROW(439115),  -- Motion Lotion (Rank 4)
  ROW(439116),  -- Motion Lotion (Rank 5)
  ROW(439117),  -- Motion Lotion (Rank 6)
  ROW(439131),  -- Motion Lotion (Rank 7)
  ROW(439132),  -- Motion Lotion (Rank 8)
  ROW(33079),  -- Murloc Costume
  ROW(339034),  -- Muscle Maxer (Rank 1)
  ROW(439037),  -- Muscle Maxer (Rank 2)
  ROW(439038),  -- Muscle Maxer (Rank 3)
  ROW(439039),  -- Muscle Maxer (Rank 4)
  ROW(439041),  -- Muscle Maxer (Rank 5)
  ROW(439042),  -- Muscle Maxer (Rank 6)
  ROW(439043),  -- Muscle Maxer (Rank 7)
  ROW(439044),  -- Muscle Maxer (Rank 8)
  ROW(559367),  -- Mutant Void Rat
  ROW(1339095),  -- Mystical Belt of Elements
  ROW(1339102),  -- Mystical Boots of Elements
  ROW(1339109),  -- Mystical Bracers of Elements
  ROW(1339090),  -- Mystical Cloak of Elements
  ROW(1339130),  -- Mystical Gloves of Elements
  ROW(1339123),  -- Mystical Helm of Elements
  ROW(1339116),  -- Mystical Kilt of Elements
  ROW(1642951),  -- Mystical Pauldrons of Elements
  ROW(1648683),  -- Mystical Vest of Elements
  ROW(558749),  -- Navy Anti-gravity Office
  ROW(101493),  -- Northrend Travel Guide
  ROW(203082),  -- Nyxaroth's Reins
  ROW(559549),  -- Ochre Wonka
  ROW(46780),  -- Ogre Pinata
  ROW(558752),  -- Opulent Anti-gravity Office
  ROW(558614),  -- Orange Winged Wonka
  ROW(397318),  -- Original 9 Classes - Bronzebeard Travel Guide
  ROW(558618),  -- P.R.P. 04 X-treme Rocket
  ROW(1642901),  -- Paladin Libram of Healing
  ROW(1642900),  -- Paladin Libram of Strength
  ROW(559422),  -- Pale Carnivarus Cutting
  ROW(34499),  -- Paper Flying Machine Kit
  ROW(339076),  -- Pendant of Adventure
  ROW(339100),  -- Pendant of Discovery
  ROW(1339078),  -- Pendant of the Bulwark
  ROW(1339077),  -- Pendant of the Sorcerer
  ROW(1339076),  -- Pendant of the Warrior
  ROW(99076),  -- Pepe
  ROW(558788),  -- Pepe
  ROW(559633),  -- Personal Atmospheric Reconfigurator: Core
  ROW(559632),  -- Personal Atmospheric Reconfigurator: Empyrean
  ROW(559628),  -- Personal Atmospheric Reconfigurator: Firmament
  ROW(559631),  -- Personal Atmospheric Reconfigurator: Invasion
  ROW(559630),  -- Personal Atmospheric Reconfigurator: Sempiternal
  ROW(559629),  -- Personal Atmospheric Reconfigurator: Twilight
  ROW(110000),  -- Personal Bank
  ROW(134985),  -- Personal Bank
  ROW(32566),  -- Picnic Basket
  ROW(558778),  -- Pink Dragon Body Costume
  ROW(558779),  -- Pink Dragon Head Costume
  ROW(558777),  -- Pink Dragon Tail Costume
  ROW(559403),  -- Pink Faire Nestling
  ROW(558775),  -- Pioneer Gravitational Anchoring Suit
  ROW(1339097),  -- Polished Belt of Valor
  ROW(1339104),  -- Polished Boots of Valor
  ROW(1339111),  -- Polished Bracers of Valor
  ROW(1648685),  -- Polished Breastplate of Valor
  ROW(1339085),  -- Polished Cloak of Valor
  ROW(1339132),  -- Polished Gauntlets of Valor
  ROW(1339125),  -- Polished Helmet of Valor
  ROW(558636),  -- Polished Jumping Recycled Robot Talkin
  ROW(3148335),  -- Polished Observer's Shield
  ROW(1339118),  -- Polished Platelegs of Valor
  ROW(1642949),  -- Polished Spaulders of Valor
  ROW(1339094),  -- Preened Ironfeather Belt
  ROW(1339101),  -- Preened Ironfeather Boots
  ROW(1339108),  -- Preened Ironfeather Bracers
  ROW(1648687),  -- Preened Ironfeather Breastplate
  ROW(1339089),  -- Preened Ironfeather Cloak
  ROW(1339129),  -- Preened Ironfeather Gloves
  ROW(1339122),  -- Preened Ironfeather Headguard
  ROW(1339115),  -- Preened Ironfeather Legguards
  ROW(1642984),  -- Preened Ironfeather Shoulders
  ROW(170005),  -- Prestigious War Horse
  ROW(170006),  -- Prestigious War Wolf
  ROW(559530),  -- Prime Gravitational Anchoring Suit
  ROW(1644100),  -- Pristine Lightforge Spaulders
  ROW(1644101),  -- Prized Beastmaster's Mantle
  ROW(199735),  -- Prophet's Great Raven Cache
  ROW(439124),  -- Purge-O-Matic
  ROW(339031),  -- Purification (Rank 1)
  ROW(539031),  -- Purification (Rank 2)
  ROW(539032),  -- Purification (Rank 3)
  ROW(539033),  -- Purification (Rank 4)
  ROW(539034),  -- Purification (Rank 5)
  ROW(539035),  -- Purification (Rank 6)
  ROW(539036),  -- Purification (Rank 7)
  ROW(539037),  -- Purification (Rank 8)
  ROW(558603),  -- Purple Nitro Junk
  ROW(558613),  -- Purple Winged Wonka
  ROW(559548),  -- Purple Wonka
  ROW(898072),  -- PX-238-Portable Winter Wondervolt
  ROW(100011),  -- Qiraji Battle Horn
  ROW(100010),  -- Qiraji Egg
  ROW(558615),  -- R.D. 01 X-treme Rocket
  ROW(308379),  -- Radiant Cloak of the Heavens
  ROW(558621),  -- Radiant Crocolisk
  ROW(300111),  -- Radiant Matriarch's Blooming Wake
  ROW(339072),  -- Rage Rush Solution (Rank 1)
  ROW(439106),  -- Rage Rush Solution (Rank 2)
  ROW(439107),  -- Rage Rush Solution (Rank 3)
  ROW(439108),  -- Rage Rush Solution (Rank 4)
  ROW(439109),  -- Rage Rush Solution (Rank 5)
  ROW(439110),  -- Rage Rush Solution (Rank 6)
  ROW(439111),  -- Rage Rush Solution (Rank 7)
  ROW(439112),  -- Rage Rush Solution (Rank 8)
  ROW(499364),  -- Razor-Lined Reins of Dark Portent
  ROW(1180097),  -- Realm Bank
  ROW(309907),  -- Recalibrator Pylon
  ROW(559450),  -- Red Gnomish Terratransformer
  ROW(559434),  -- Red Goblin Aerial Propulsor
  ROW(559451),  -- Red Goblin Terratransformer
  ROW(558604),  -- Red Nitro Junk
  ROW(558750),  -- Refined Anti-gravity Office
  ROW(339037),  -- Reflex Booster (Rank 1)
  ROW(439078),  -- Reflex Booster (Rank 2)
  ROW(439079),  -- Reflex Booster (Rank 3)
  ROW(439080),  -- Reflex Booster (Rank 4)
  ROW(439081),  -- Reflex Booster (Rank 5)
  ROW(439082),  -- Reflex Booster (Rank 6)
  ROW(439083),  -- Reflex Booster (Rank 7)
  ROW(439084),  -- Reflex Booster (Rank 8)
  ROW(1644092),  -- Reforged Truesilver Champion
  ROW(806657),  -- Regenerative Savory Deviate Delight
  ROW(99485),  -- Reins of the Accursed Wrathsteed
  ROW(343209),  -- Reins of the Betrayer's Felsworn Spire Terror
  ROW(343208),  -- Reins of the Betrayer's Savage Spire Terror
  ROW(343210),  -- Reins of the Betrayer's Supreme Spire Terror
  ROW(343211),  -- Reins of the Betrayer's Unscarred Spire Terror
  ROW(283040),  -- Reins of The Headless Horseman's Ghoulish Charger
  ROW(102107),  -- Reins of the Magmatic Steed
  ROW(49636),  -- Reins of the Onyxian Drake
  ROW(32768),  -- Reins of the Raven Lord
  ROW(8199957),  -- Reins of the Red Magmashell
  ROW(98490),  -- Reins of the Spectral Steed
  ROW(291915),  -- Reins of the Unbound Star-Eater
  ROW(800579),  -- Remote of Retreat: Ahn'Qiraj
  ROW(800580),  -- Remote of Retreat: Blackwing Lair
  ROW(800577),  -- Remote of Retreat: Molten Core
  ROW(800582),  -- Remote of Retreat: Naxxramas
  ROW(800581),  -- Remote of Retreat: Onyxia's Lair
  ROW(800578),  -- Remote of Retreat: Zul'Gurub
  ROW(1648718),  -- Repurposed Lava Dredger
  ROW(1777416),  -- Restoration Deathwalker
  ROW(1518202),  -- Rethreaded Left Bear Claw
  ROW(1518203),  -- Rethreaded Right Bear Claw
  ROW(3001006),  -- Riding Tome: Apprentice Riding
  ROW(3001005),  -- Riding Tome: Journeyman Riding
  ROW(1339081),  -- Ring of the Bulwark
  ROW(1339082),  -- Ring of the Lionhearted
  ROW(1339083),  -- Ring of the Seer
  ROW(1339080),  -- Ring of the Sorcerer
  ROW(1339079),  -- Ring of the Vanguard
  ROW(34480),  -- Romantic Picnic Basket
  ROW(299950),  -- Ruby Attrition Insignia
  ROW(558751),  -- Rusty Anti-gravity Office
  ROW(559519),  -- Rusty Buzzsaw Ripper
  ROW(45047),  -- Sandbox Tiger
  ROW(298155),  -- Sanguine Embrace of the Hexflame Coven
  ROW(558630),  -- Sapphire Rocket
  ROW(558649),  -- Scarlet Skittering Shadowfang
  ROW(100021),  -- Scourge Stick
  ROW(558627),  -- Sea Foam Duck
  ROW(12344),  -- Seal of Ascension
  ROW(97398),  -- Seasonal Achievements Unlock
  ROW(559529),  -- Sentinel Gravitational Anchoring Suit
  ROW(666003),  -- Serpentshrine Cavern Medallion
  ROW(560573),  -- Shadowburn Minecart
  ROW(560506),  -- Shadowed Spiritreaver
  ROW(1642898),  -- Shaman Totem of Agility
  ROW(1642899),  -- Shaman Totem of Spells
  ROW(1644091),  -- Sharpened Scarlet Kris
  ROW(308380),  -- Shining Cloak of the Heavens
  ROW(558669),  -- Shiny Tidewater Pincer
  ROW(1175625),  -- Sigil of the Crimson Skyblazer
  ROW(223772),  -- Silversteel Covenant
  ROW(559523),  -- Simulated Subject Emulator: Amber
  ROW(559525),  -- Simulated Subject Emulator: Azure
  ROW(559524),  -- Simulated Subject Emulator: Rose
  ROW(559526),  -- Simulated Subject Emulator: Viridian
  ROW(558647),  -- Skittering Shadowfang
  ROW(499438),  -- Smoldering Ember Wyrm
  ROW(559527),  -- Solar Gravitational Anchoring Suit
  ROW(559593),  -- Somber Torment
  ROW(2200034),  -- Soulbound Riding Tome: Apprentice Riding
  ROW(2200033),  -- Soulbound Riding Tome: Journeyman Riding
  ROW(1777414),  -- Soultwisted Deathwalker
  ROW(300110),  -- Sovereign Matriarch's Blooming Wake
  ROW(558658),  -- Sparkling Cloud
  ROW(560498),  -- Spiritborne Moose
  ROW(560500),  -- Spiritborne Spider
  ROW(560499),  -- Spiritborne Wolf
  ROW(339050),  -- Sprint Serum (Rank 1)
  ROW(439050),  -- Sprint Serum (Rank 2)
  ROW(439051),  -- Sprint Serum (Rank 3)
  ROW(439052),  -- Sprint Serum (Rank 4)
  ROW(439053),  -- Sprint Serum (Rank 5)
  ROW(439054),  -- Sprint Serum (Rank 6)
  ROW(439055),  -- Sprint Serum (Rank 7)
  ROW(439056),  -- Sprint Serum (Rank 8)
  ROW(100013),  -- Staff of the Sun God
  ROW(1339093),  -- Stained Shadowcraft Belt
  ROW(1339100),  -- Stained Shadowcraft Boots
  ROW(1339107),  -- Stained Shadowcraft Bracers
  ROW(1339088),  -- Stained Shadowcraft Cloak
  ROW(1339128),  -- Stained Shadowcraft Gloves
  ROW(1339121),  -- Stained Shadowcraft Hood
  ROW(1339114),  -- Stained Shadowcraft Pants
  ROW(1642952),  -- Stained Shadowcraft Spaulders
  ROW(1648689),  -- Stained Shadowcraft Tunic
  ROW(339075),  -- Stick on a Carrot
  ROW(1339087),  -- Strengthened Cloak of Might
  ROW(1644099),  -- Strengthened Stockade Pauldrons
  ROW(3142943),  -- Sturdied Arcanite Spear
  ROW(558628),  -- Sunray Duck
  ROW(558644),  -- Sunshine Toy Train
  ROW(33977),  -- Swift Brewfest Ram
  ROW(1642991),  -- Swift Hand of Justice
  ROW(19872),  -- Swift Razzashi Raptor
  ROW(35513),  -- Swift White Hawkstrider
  ROW(19902),  -- Swift Zulian Tiger
  ROW(1339092),  -- Tattered Dreadmist Belt
  ROW(1339099),  -- Tattered Dreadmist Boots
  ROW(1339106),  -- Tattered Dreadmist Bracers
  ROW(1339086),  -- Tattered Dreadmist Cloak
  ROW(1339127),  -- Tattered Dreadmist Gloves
  ROW(1339120),  -- Tattered Dreadmist Hood
  ROW(1339113),  -- Tattered Dreadmist Leggings
  ROW(1642985),  -- Tattered Dreadmist Mantle
  ROW(1648691),  -- Tattered Dreadmist Robe
  ROW(339077),  -- Taunting Tonic (Rank 1)
  ROW(439125),  -- Taunting Tonic (Rank 2)
  ROW(439126),  -- Taunting Tonic (Rank 3)
  ROW(439127),  -- Taunting Tonic (Rank 4)
  ROW(439128),  -- Taunting Tonic (Rank 5)
  ROW(439129),  -- Taunting Tonic (Rank 6)
  ROW(439130),  -- Taunting Tonic (Rank 7)
  ROW(439138),  -- Taunting Tonic (Rank 8)
  ROW(1777071),  -- Thalassian Charger
  ROW(1877071),  -- Thalassian Warhorse
  ROW(1644094),  -- The Blessed Hammer of Grace
  ROW(38578),  -- The Flag of Ownership
  ROW(499177),  -- The Flag of Ownership (Green F)
  ROW(499176),  -- The Flag of Ownership (Grimacing)
  ROW(499175),  -- The Flag of Ownership (Joy)
  ROW(499174),  -- The Flag of Ownership (Nerd)
  ROW(499173),  -- The Flag of Ownership (Pensive)
  ROW(499172),  -- The Flag of Ownership (Question Mark)
  ROW(499171),  -- The Flag of Ownership (Rage)
  ROW(499170),  -- The Flag of Ownership (Smile)
  ROW(499169),  -- The Flag of Ownership (Sunglasses)
  ROW(499168),  -- The Flag of Ownership (Weary)
  ROW(50471),  -- The Heartbreaker
  ROW(37012),  -- The Horseman's Reins
  ROW(532591),  -- The Mighty Fist
  ROW(818060),  -- The Skeleton Coin
  ROW(190191),  -- The Skin-Peeler 9000
  ROW(1642902),  -- Thrown Axe of the Executioner
  ROW(558670),  -- Tidewater Pincer
  ROW(509891),  -- Tiki Troll Mask
  ROW(559522),  -- Tiny Shadow Eye
  ROW(339062),  -- Tiny Ticking Time-Bomb
  ROW(560575),  -- Titan-Delver Minecart
  ROW(222739),  -- Tome of Polymorph: Frogduck
  ROW(44793),  -- Tome of Polymorph: Rabbit
  ROW(244793),  -- Tome of Polymorph: Rabbit
  ROW(22739),  -- Tome of Polymorph: Turtle
  ROW(1022739),  -- Tome of Polymorph: Turtle
  ROW(106955),  -- Tome of Specialization II
  ROW(106956),  -- Tome of Specialization III
  ROW(134980),  -- Tome of Specialization III
  ROW(106957),  -- Tome of Specialization IV
  ROW(134981),  -- Tome of Specialization IV
  ROW(106958),  -- Tome of Specialization V
  ROW(134982),  -- Tome of Specialization V
  ROW(777998),  -- Tradesman's Scroll
  ROW(532575),  -- Transform: S.A.V.I.O.R
  ROW(977028),  -- Travel Permit
  ROW(509887),  -- Treasure Nabbin' Bag
  ROW(559418),  -- Treasure-Extractor G-774
  ROW(559420),  -- Turbo Racer “Time Is Gold”
  ROW(559453),  -- Turbo-Blue Goblin Surfboard
  ROW(559416),  -- Turbo-Charged Goblin Tricycle
  ROW(559454),  -- Turbo-Green Goblin Surfboard
  ROW(559456),  -- Turbo-Ivory Goblin Surfboard
  ROW(559455),  -- Turbo-Red Goblin Surfboard
  ROW(558769),  -- Turnip Punching Bag
  ROW(100012),  -- Twilight Bonfire
  ROW(298153),  -- Twilight Embrace of the Hexflame Coven
  ROW(559413),  -- Twilight Floral Snail
  ROW(559203),  -- Undead Charger
  ROW(559202),  -- Undead Warhorse
  ROW(559439),  -- Unstable Black Rocket-Missile
  ROW(559440),  -- Unstable Blue Rocket-Missile
  ROW(559441),  -- Unstable Green Rocket-Missile
  ROW(559442),  -- Unstable Purple Rocket-Missile
  ROW(559443),  -- Unstable Red Rocket-Missile
  ROW(559444),  -- Unstable Yellow Rocket-Missile
  ROW(1644093),  -- Upgraded Dwarven Hand Cannon
  ROW(3140350),  -- Urn of Aspiring Light
  ROW(559528),  -- Vanguard Gravitational Anchoring Suit
  ROW(777989),  -- Vanity Collection Sync
  ROW(1642945),  -- Venerable Dal'Rend's Sacred Charge
  ROW(1648716),  -- Venerable Mass of McGowan
  ROW(558626),  -- Verdant River Duck
  ROW(558674),  -- Verdant Spiteful Frog
  ROW(203081),  -- Verdara's Reins
  ROW(300109),  -- Vivacious Matriarch's Blooming Wake
  ROW(559581),  -- Void Charger
  ROW(559447),  -- Void Combat Airship
  ROW(559542),  -- Void Wonka
  ROW(559533),  -- Void-Corrupting Fragment
  ROW(559590),  -- Voidbound Bat
  ROW(559427),  -- Voidbound Force
  ROW(559592),  -- Voidbound Gryphon
  ROW(559591),  -- Voidbound Hippogryph
  ROW(559589),  -- Voidbound Wyvern
  ROW(559567),  -- Volatile Reactive Throne
  ROW(1642846),  -- Wand of the Forgotten Lich
  ROW(98467),  -- Warhorse
  ROW(1777415),  -- Wastewarped Deathwalker
  ROW(558623),  -- Weathered Crocolisk
  ROW(558655),  -- Whispering Snow Cloud
  ROW(46102),  -- Whistle of the Venomhide Ravasaur
  ROW(559406),  -- White Faire Nestling
  ROW(499180),  -- Winter Veil - Pepe
  ROW(558802),  -- Wonka Blue Flag
  ROW(559536),  -- Wonka Glasses
  ROW(558805),  -- Wonka Green Flag
  ROW(558804),  -- Wonka Orange Flag
  ROW(558803),  -- Wonka Purple Flag
  ROW(558999),  -- Wonka Rainbow Flag
  ROW(558801),  -- Wonka Red Flag
  ROW(558806),  -- Wonka Yellow Flag
  ROW(558639),  -- Wrathful Fel Reaver Head
  ROW(559580),  -- Wrathful Felcharger
  ROW(559583),  -- Wrathful Felsteel Arachnid
  ROW(560505),  -- Wrathful Spiritreaver
  ROW(559404),  -- Yellow Faire Nestling
  ROW(559437),  -- Yellow Goblin Aerial Propulsor
  ROW(559452),  -- Yellow Goblin Terratransformer
  ROW(558601),  -- Yellow Nitro Junk
  ROW(558798),  -- Yellow Winged Wonka
  ROW(559551),  -- Yellow Wonka
  ROW(559565),  -- Zandalari Gong
  ROW(101172)  -- Kleptomanic Demon Leash
) n (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;

-- PvP mounts (honor, arena rating, PvP seasons and leaderboards) are earned in PvP, not bought with Bazaar Tokens.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 0
FROM (VALUES
  ROW(29465),  -- Black Battlestrider
  ROW(29466),  -- Black War Kodo
  ROW(29467),  -- Black War Ram
  ROW(29468),  -- Black War Steed Bridle
  ROW(43516),  -- Brutal Nether Drake
  ROW(334410),  -- Corrupted Gladiator's Proto-Drake
  ROW(978312),  -- Cruel Gladiator's Storm Dragon
  ROW(699639),  -- Demonic Gladiator's Storm Dragon
  ROW(978315),  -- Dominant Gladiator's Storm Dragon
  ROW(334415),  -- Dread Gladiator's Proto-Drake
  ROW(978311),  -- Fearless Gladiator's Storm Dragon
  ROW(978313),  -- Ferocious Gladiator's Storm Dragon
  ROW(978314),  -- Fierce Gladiator's Storm Dragon
  ROW(259654),  -- Gladiator's Abyssal Crocolisk
  ROW(259965),  -- Gladiator's Crag Crocolisk
  ROW(259633),  -- Gladiator's Jade Crocolisk
  ROW(416601),  -- Gladiator's Jungle Crocolisk
  ROW(416602),  -- Gladiator's Magma Crocolisk
  ROW(236292),  -- Gladiator's Void Crocolisk
  ROW(29469),  -- Horn of the Black War Wolf
  ROW(334414),  -- Malevolent Gladiator's Proto-Drake
  ROW(34092),  -- Merciless Nether Drake
  ROW(334416),  -- Notorious Gladiator's Proto-Drake
  ROW(699636),  -- Primal Gladiator's Felblood Gronnling
  ROW(29470),  -- Red Skeletal Warhorse
  ROW(35906),  -- Reins of the Black War Elekk
  ROW(29471),  -- Reins of the Black War Tiger
  ROW(499987),  -- Reins of the Silverwing Nightsaber
  ROW(499984),  -- Reins of the Warsong Wolf
  ROW(1777320),  -- Rocktusk Battleboar
  ROW(334411),  -- Sinister Gladiator's Proto-Drake
  ROW(334412),  -- Spiteful Gladiator's Proto-Drake
  ROW(30609),  -- Swift Nether Drake
  ROW(34129),  -- Swift Warstrider
  ROW(1777436),  -- Umberhoof Warboar
  ROW(37676),  -- Vengeful Nether Drake
  ROW(1179149),  -- Vicious War Spider (Alliance)
  ROW(1179152),  -- Vicious War Spider (Horde)
  ROW(334413),  -- Vile Gladiator's Proto-Drake
  ROW(978310),  -- Vindictive Gladiator's Storm Dragon
  ROW(499636),  -- Warforged Nightmare
  ROW(699638),  -- Warmongering Gladiator's Felblood Gronnling
  ROW(29472),  -- Whistle of the Black War Raptor
  ROW(699637)  -- Wild Gladiator's Felblood Gronnling
) n (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;
