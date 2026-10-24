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
