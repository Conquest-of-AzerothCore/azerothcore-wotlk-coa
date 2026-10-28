-- ----------------------------------------------------------------------------
-- Worldforged pickups: the appearance Ascension's own records give them.
-- ----------------------------------------------------------------------------
-- Each value is read from a record Ascension produced; none is chosen here.
--
--   A  the entry's own record in the client's gameobjectcache
--   B  the entry's record in the archive's client-capture collection
--   C  the GameObject dump catalogue's sighting of an object of that name
--   D  another entry Ascension gives the same name, and that entry's own record
--   E  the object the Exiles database names as the source of the item it drops
--
-- The statement below is the final appearance of all 1721 objects the module
-- owns, not a diff, so a fresh database lands exactly where this one is.
-- 0 of them differ from what the earlier migrations produced. The other
-- 203 have no record in any corpus and keep the value they already ship;
-- they are listed in the module README rather than assigned a guess.
-- ----------------------------------------------------------------------------

UPDATE `gameobject_template` SET `displayId` = CASE `entry`
  WHEN 63143 THEN 186468  -- [A] Dorius' Shield
  WHEN 63517 THEN 63517  -- [C] Something Shiny
  WHEN 66601 THEN 515022  -- [A] Caravan Crossbow
  WHEN 67241 THEN 75323  -- [A] Spider Silk
  WHEN 67261 THEN 515454  -- [A] Stomped Tome
  WHEN 67262 THEN 6930  -- [A] Leatherworking Book
  WHEN 68369 THEN 1868  -- [A] Dark Iron Supplies
  WHEN 68371 THEN 7911  -- [A] Lava Hardened Rock
  WHEN 68374 THEN 515458  -- [A] Scorching Dagger
  WHEN 68376 THEN 2612  -- [A] Dark Iron Corpse
  WHEN 68379 THEN 20900  -- [A] Twilight Axe
  WHEN 68381 THEN 1009575  -- [A] Steam Pressure Totem
  WHEN 68394 THEN 63517  -- [A] Jewelled Ring
  WHEN 68399 THEN 1013513  -- [A] Rune Circle
  WHEN 68403 THEN 1014316  -- [A] Travel Sack
  WHEN 68406 THEN 1015781  -- [A] Dead Slave
  WHEN 68410 THEN 20  -- [A] Dirt Mound
  WHEN 68428 THEN 278  -- [A] Pile of Bones
  WHEN 68430 THEN 2613  -- [A] Dwarf Corpse
  WHEN 68434 THEN 84677  -- [A] Incendosaur Tooth
  WHEN 86168 THEN 1019881  -- [A] Burning Corpse
  WHEN 86169 THEN 515250  -- [A] Iron Hammer
  WHEN 86171 THEN 364  -- [A] Silkwrapped Object
  WHEN 89640 THEN 1047366  -- [A] Atonement
  WHEN 90043 THEN 7781  -- [A] Mysterious Water Orb
  WHEN 90214 THEN 1017819  -- [A] Wax Stained Bag
  WHEN 90215 THEN 357  -- [A] Old Grave
  WHEN 90216 THEN 1021882  -- [A] Defias Special Bucket
  WHEN 90217 THEN 1034276  -- [A] Alliance Gem of Fortitude
  WHEN 90218 THEN 1014587  -- [A] Large Kodo Bone
  WHEN 90219 THEN 7215  -- [A] Stolen Tauren Cloak
  WHEN 90220 THEN 515116  -- [A] Ancestor's Axe
  WHEN 90221 THEN 1013843  -- [A] Stolen Red Cloud Mesa Supplies
  WHEN 90223 THEN 88291  -- [A] Glinting Kobold Corpse
  WHEN 90224 THEN 1029175  -- [A] Riverpaw Pack Chieftain's Lunch
  WHEN 90225 THEN 1020297  -- [D] Riverpaw Pack Second in Command's Lunch
  WHEN 90226 THEN 1065032  -- [D] Stormwind Memento Offering
  WHEN 90228 THEN 1036950  -- [A] Murloc Voodoo Toy
  WHEN 90229 THEN 515387  -- [K] Scarecrow Arm
  WHEN 90233 THEN 1022454  -- [D] Lexicon of Azora - Part I: Mage Inscriptions
  WHEN 90234 THEN 138008  -- [A] Lexicon of Azora - Part II: Warlock Rituals
  WHEN 90235 THEN 1047590  -- [A] Dockmaster's Stolen Supplies
  WHEN 90236 THEN 1016329  -- [A] Thunder Falls Enchanted Branches
  WHEN 90237 THEN 1009548  -- [A] Thunder Falls Finest Gun Selection
  WHEN 90238 THEN 1015946  -- [C] Loop of the Sly Rogue
  WHEN 90239 THEN 1049447  -- [C] The One Candle
  WHEN 90240 THEN 1  -- [A] Quel'Thalas Sunken Treasure Chest
  WHEN 90241 THEN 1  -- [A] Quel'Thalas Sunken Treasure Chest
  WHEN 90242 THEN 1  -- [A] Quel'Thalas Sunken Treasure Chest
  WHEN 90243 THEN 1036400  -- [A] Fisherman's Last Wish
  WHEN 90244 THEN 1019016  -- [D] Peculiar Gold Nugget
  WHEN 90245 THEN 1  -- [A] Quel'Thalas Sunken Treasure Chest
  WHEN 90246 THEN 1  -- [A] Quel'Thalas Sunken Treasure Chest
  WHEN 90247 THEN 1015607  -- [A] People's Militia Armaments
  WHEN 90248 THEN 1015458  -- [A] Stolen Brew
  WHEN 90249 THEN 1034354  -- [A] Madness Cursed Notes
  WHEN 90250 THEN 1066265  -- [A] People's Militia Stolen Badge
  WHEN 90251 THEN 1012093  -- [A] Defias Remains
  WHEN 90252 THEN 1046130  -- [C] Defias Mage Stash
  WHEN 90253 THEN 1009548  -- [A] Defias Rusty Gun Rack
  WHEN 90254 THEN 7679  -- [A] Sack of Defias Gear
  WHEN 90255 THEN 9170  -- [A] Dirtpaw Trousers
  WHEN 90256 THEN 1009690  -- [A] Yowler's Howl
  WHEN 90258 THEN 1010146  -- [C] Ilgalar Stolen Neckpiece
  WHEN 90259 THEN 1015449  -- [C] Blackrock Armor Supplies
  WHEN 90260 THEN 1051775  -- [C] Shadowhide Treasure
  WHEN 90261 THEN 100519  -- [A] Blackrock Render
  WHEN 90262 THEN 1017937  -- [C] Blackrock Smuggled Goods
  WHEN 90263 THEN 1013373  -- [A] Chocked Fish Corpse
  WHEN 90264 THEN 254156  -- [A] Adventurer's Cloak
  WHEN 90265 THEN 1010592  -- [A] Unique Pole
  WHEN 90266 THEN 1011781  -- [A] Lookout Scope
  WHEN 90268 THEN 1022636  -- [C] Aqualon's Core
  WHEN 90269 THEN 1010146  -- [C] Eliza's Pendant
  WHEN 90270 THEN 1047472  -- [A] Leftover Provisions
  WHEN 90271 THEN 1070109  -- [C] Nightwatch Circlet
  WHEN 90272 THEN 20  -- [A] Darkshire Grave
  WHEN 90274 THEN 1018646  -- [A] Defias Night Blade
  WHEN 90275 THEN 254157  -- [A] Vul'Gol Torch
  WHEN 90276 THEN 228  -- [A] Spider Ichor Sample
  WHEN 90277 THEN 1038131  -- [A] Cursed Toy
  WHEN 90278 THEN 1070109  -- [C] The Jitters
  WHEN 90279 THEN 100520  -- [A] Skeleton Hand
  WHEN 90280 THEN 49  -- [A] Burning Scales of the Black Dragonflight Matriarch
  WHEN 90281 THEN 1043607  -- [A] Will in the Casket
  WHEN 90282 THEN 86417  -- [A] Catacombs Relic Torch
  WHEN 90283 THEN 1026950  -- [A] Alchemy Visceral Juice
  WHEN 90284 THEN 1013433  -- [C] Ruby Skeletal Ring
  WHEN 90285 THEN 1045031  -- [C] Sharp Bone Necklace
  WHEN 90286 THEN 20  -- [A] Catacomb Grave Dirt Pile
  WHEN 90287 THEN 254158  -- [A] Peculiar Root
  WHEN 90288 THEN 1070109  -- [K] Darkest Night Ring
  WHEN 90289 THEN 1015957  -- [C] Munitions Crate
  WHEN 90290 THEN 1055729  -- [A] Emerald Shard
  WHEN 90292 THEN 515255  -- [A] Worn Axe
  WHEN 90293 THEN 1010201  -- [A] Abandoned Peon's Sack
  WHEN 90294 THEN 5744  -- [A] Fallen Recruit Footlocker
  WHEN 90295 THEN 1010810  -- [A] Pile of Rocks
  WHEN 90296 THEN 1011282  -- [A] Non-work Approved Bedroll
  WHEN 90297 THEN 1011043  -- [K] Burning Blade Ring
  WHEN 90302 THEN 100524  -- [A] Honor Blade
  WHEN 90303 THEN 5092  -- [A] Wailing Sapphire Gem
  WHEN 90304 THEN 500009  -- [A] Stylish Cloak
  WHEN 90305 THEN 1070109  -- [K] Bloody Wedding Ring
  WHEN 90306 THEN 1009548  -- [A] Northwatch Hand Gun Rack
  WHEN 90308 THEN 1011781  -- [A] Captain's Spyglass
  WHEN 90310 THEN 515026  -- [A] Overwatch Bow
  WHEN 90311 THEN 1048631  -- [A] Special Excavation Lantern
  WHEN 90312 THEN 100523  -- [A] Gnoll Subdue Wand
  WHEN 90313 THEN 500003  -- [A] Rot Hide Stash
  WHEN 90314 THEN 1019768  -- [A] Cursed Fang Remains
  WHEN 90316 THEN 500014  -- [A] Dusty Book
  WHEN 90317 THEN 285  -- [C] Rot Hide Supplies
  WHEN 90319 THEN 1070109  -- [C] Stolen Rot Hide Circlet
  WHEN 90320 THEN 1019417  -- [A] Thule's Curse Parchment
  WHEN 90321 THEN 1060048  -- [C] Post-Explosion Magic Debris
  WHEN 90322 THEN 1066265  -- [A] Stolen Lordaeron Jewel
  WHEN 90323 THEN 6484  -- [C] Sack of Pine Seeds
  WHEN 90324 THEN 1014587  -- [C] Ivar's Femur
  WHEN 90325 THEN 500004  -- [A] Dirt Covered Gown
  WHEN 90327 THEN 1047608  -- [D] Victim's Empty jar
  WHEN 90328 THEN 7539  -- [A] Gilnean Crate
  WHEN 90329 THEN 1070109  -- [K] Fenris Ring
  WHEN 90330 THEN 1045031  -- [C] Ravenclaw Bone Necklace
  WHEN 90331 THEN 1010931  -- [A] Bristleback Staff
  WHEN 90332 THEN 8126  -- [A] Thornmantle Quills
  WHEN 90336 THEN 515188  -- [A] Brambleblade Blade
  WHEN 90338 THEN 254161  -- [A] Venture Co. Unique Concoction
  WHEN 90339 THEN 100500  -- [A] Fallen Hardwood Plank
  WHEN 90340 THEN 1012773  -- [A] Long Fishing Spear
  WHEN 90341 THEN 1051868  -- [A] Snaggle's Engage Whistle
  WHEN 90342 THEN 7922  -- [C] Matriarch Windfury Claw
  WHEN 90345 THEN 1011043  -- [C] Venture Co. Ring
  WHEN 90346 THEN 515348  -- [A] Discarded Wagon Wheel
  WHEN 90347 THEN 1010146  -- [A] Interloper's Loop
  WHEN 90348 THEN 1038878  -- [C] Wood Pile
  WHEN 90349 THEN 8483  -- [C] Meat Wagon Small Claw
  WHEN 90352 THEN 1040953  -- [D] Sin'dorei Battle Staff
  WHEN 90354 THEN 254168  -- [A] Blight Potion
  WHEN 90356 THEN 86641  -- [A] Scourge Blight Staff
  WHEN 90361 THEN 254171  -- [A] Blackpaw Scavenger Pick
  WHEN 90372 THEN 515180  -- [A] Elven Spear of Zoram
  WHEN 90373 THEN 515319  -- [A] Elven Militia Crown
  WHEN 90375 THEN 100502  -- [A] Pristine Tortoise Carapace
  WHEN 90376 THEN 1025536  -- [C] Felforged Meteor Fragment Remnant
  WHEN 90378 THEN 500011  -- [A] Guide to Elven Restoration - Vol. I
  WHEN 90379 THEN 1026756  -- [A] Bathran's Cursed Branch
  WHEN 90380 THEN 515038  -- [A] Maestra's Training Longbow
  WHEN 90382 THEN 1041975  -- [C] Echo of Aessina
  WHEN 90383 THEN 254177  -- [A] Thistlefur Fur Shroud
  WHEN 90384 THEN 63519  -- [D] Cursed Fire Scar Pendant
  WHEN 90385 THEN 7922  -- [A] Ursangous' Claw
  WHEN 90387 THEN 429  -- [D] Elune Tear Fragment
  WHEN 90388 THEN 515241  -- [A] Mystral Staff
  WHEN 90389 THEN 1010746  -- [A] Ring of Druidic Whispers
  WHEN 90390 THEN 405  -- [A] Endless Moonwell Chalice
  WHEN 90391 THEN 1001067  -- [A] Woodbreaker Mallet
  WHEN 90392 THEN 500012  -- [A] Warsong Timbercleaver
  WHEN 90393 THEN 1027048  -- [A] Silverwing Grovekeeper's Bow
  WHEN 90394 THEN 3991  -- [K] Fel Infused Fragment
  WHEN 90395 THEN 1018860  -- [C] Bloodtooth Neck
  WHEN 90396 THEN 515142  -- [A] Bleakheart Heartpiercer
  WHEN 90411 THEN 1044222  -- [A] Cracked Hearthstone of the Fallen
  WHEN 90412 THEN 7118  -- [A] Portal Fragment
  WHEN 90421 THEN 3079  -- [A] Lost One Satchel
  WHEN 90423 THEN 1014316  -- [A] Bloodmage Coil
  WHEN 90429 THEN 515227  -- [A] Ritual Darkened Blade
  WHEN 90472 THEN 2612  -- [K] Mossflayer Corpse
  WHEN 90478 THEN 100531  -- [A] Fallen Sentry Armor
  WHEN 90479 THEN 100534  -- [A] Fungal Axe
  WHEN 90480 THEN 1026109  -- [A] Forbidden Fruit
  WHEN 90484 THEN 515130  -- [A] Tainted Blade
  WHEN 90486 THEN 1020695  -- [A] Adventurer's Boots
  WHEN 90489 THEN 1014316  -- [A] Sack of Relics
  WHEN 90492 THEN 100552  -- [A] Executioner's Axe
  WHEN 90493 THEN 1063512  -- [B] Scarlet Libram
  WHEN 90497 THEN 100553  -- [A] Runeblade
  WHEN 90498 THEN 515036  -- [A] Defense Crossbow
  WHEN 90501 THEN 100554  -- [A] Cauterizing Needle
  WHEN 90502 THEN 100555  -- [A] Scarlet Gavel
  WHEN 90508 THEN 1015781  -- [A] Chainmail Gauntlets
  WHEN 90509 THEN 189148  -- [A] Holy Sword
  WHEN 90517 THEN 343  -- [K] Baby Plaguebat
  WHEN 90519 THEN 4211  -- [A] Pool of Blood of Heroes
  WHEN 90526 THEN 1070109  -- [K] Glowing Ring
  WHEN 90527 THEN 1046081  -- [A] Broken Box of War Supplies
  WHEN 90528 THEN 1028909  -- [K] Murkied Bracers
  WHEN 90529 THEN 100556  -- [A] Stuck Rapier
  WHEN 90530 THEN 100628  -- [A] Praetorian Helmet
  WHEN 90531 THEN 100629  -- [A] Quel'thalas Relic
  WHEN 90532 THEN 185533  -- [A] Encrusted Spear
  WHEN 90534 THEN 500000  -- [A] Darrowshire Cloak
  WHEN 90545 THEN 2612  -- [K] Adventurer's Corpse
  WHEN 90546 THEN 500015  -- [A] Scarlet Sword
  WHEN 90550 THEN 41  -- [K] Underbed Glint
  WHEN 90551 THEN 500016  -- [A] Hanged Pelt
  WHEN 90552 THEN 188449  -- [A] Forgotten Cane
  WHEN 90553 THEN 179000  -- [A] Wooden Maul
  WHEN 90554 THEN 1008956  -- [A] Unique Bush
  WHEN 90555 THEN 8966  -- [C] Gnarlpine Basket
  WHEN 90557 THEN 515530  -- [A] Mossy Shortbow
  WHEN 90559 THEN 8966  -- [A] Gnarlpine Basket
  WHEN 90560 THEN 1018713  -- [A] Porcelain Jar
  WHEN 90561 THEN 180714  -- [K] Leather Scraps
  WHEN 90562 THEN 500017  -- [A] Stuck Scimitar
  WHEN 90563 THEN 515533  -- [A] Lazy Crossbow
  WHEN 90564 THEN 190491  -- [A] Small Branch
  WHEN 90565 THEN 500018  -- [A] Red Plumage
  WHEN 90569 THEN 1070109  -- [K] Glinting Ring
  WHEN 90578 THEN 2612  -- [K] Adventurer's Corpse
  WHEN 90579 THEN 500019  -- [A] Leather Cape
  WHEN 90583 THEN 500020  -- [A] Rough Axe
  WHEN 90586 THEN 515022  -- [A] Withered Crossbow
  WHEN 90589 THEN 1027445  -- [B] Covered Relic
  WHEN 90591 THEN 500022  -- [A] Leaning Greatsword
  WHEN 90594 THEN 1053885  -- [A] Floating Barrel
  WHEN 90596 THEN 1  -- [K] Lost Goods
  WHEN 90598 THEN 1046081  -- [A] Broken Crate
  WHEN 90599 THEN 2350  -- [C] Abandoned Crate
  WHEN 90606 THEN 500024  -- [A] Shabby Knife
  WHEN 90607 THEN 1  -- [K] Lost Goods
  WHEN 90611 THEN 1014316  -- [A] Fisherman Bag
  WHEN 90612 THEN 527302  -- [A] Chewed Knuckle
  WHEN 90614 THEN 8376  -- [A] Impaled Corpse
  WHEN 90615 THEN 515224  -- [A] Plagued Pitchfork
  WHEN 90617 THEN 500025  -- [A] Scourge Banner Scrap
  WHEN 90618 THEN 7679  -- [K] Glinting Sack
  WHEN 90619 THEN 527407  -- [A] Flaming Rod
  WHEN 90620 THEN 285  -- [A] Dusty Crate
  WHEN 90621 THEN 526265  -- [A] Buried Shotgun
  WHEN 90623 THEN 500026  -- [A] Golden Circlet
  WHEN 90625 THEN 24  -- [A] Mossy Belt
  WHEN 90626 THEN 1011490  -- [A] Mossy Bag
  WHEN 90627 THEN 1074163  -- [A] Glinting Pendant
  WHEN 90636 THEN 7679  -- [A] Forgotten Sack
  WHEN 93000 THEN 9069  -- [A] Crusader's Chest
  WHEN 95500 THEN 1015091  -- [A] Frostwalker?s Boots
  WHEN 95501 THEN 100002  -- [A] Spicy Candle
  WHEN 95502 THEN 1010746  -- [A] Lost Adventurer's Ring
  WHEN 95503 THEN 1074449  -- [A] Forgotten Knapsack
  WHEN 95504 THEN 63520  -- [A] Glinting Necklace
  WHEN 95505 THEN 515102  -- [A] Abandoned Shovel
  WHEN 95506 THEN 515117  -- [A] Sturdy Axe
  WHEN 95507 THEN 254033  -- [A] Lost Mountaineer's Bow
  WHEN 95508 THEN 3151  -- [A] Warm Mug
  WHEN 95509 THEN 1014746  -- [A] Miner's Pickaxe
  WHEN 95510 THEN 254148  -- [A] A Really Pointy Bone
  WHEN 95511 THEN 1209  -- [A] Well Kept Tools
  WHEN 95512 THEN 1015946  -- [C] Lost Ring
  WHEN 95513 THEN 5333  -- [A] Snow Pile
  WHEN 95514 THEN 515120  -- [A] Axe of the Frostmane
  WHEN 95515 THEN 1074163  -- [K] Ice Beard's Furled Finger
  WHEN 95516 THEN 254032  -- [A] Arctic Imbued Stick
  WHEN 95518 THEN 254155  -- [A] Claw of Vagash
  WHEN 95519 THEN 1014428  -- [C] Heavy Ogre Axe
  WHEN 95520 THEN 1049446  -- [C] Grizlak's Candle
  WHEN 95521 THEN 100516  -- [A] Large Buzzard Talon
  WHEN 95522 THEN 100517  -- [A] Tunnel Rat Pike
  WHEN 95523 THEN 1053978  -- [A] Miner's League Vest
  WHEN 95524 THEN 515133  -- [A] Sword of Stone
  WHEN 95525 THEN 100515  -- [A] Galgosh's Other Bone
  WHEN 95526 THEN 33  -- [A] Boom Barrel
  WHEN 95527 THEN 515018  -- [A] Ol' Blunderbuss
  WHEN 95528 THEN 1013847  -- [C] Dark Iron Collar
  WHEN 95529 THEN 468  -- [C] Chok'sul's Basket
  WHEN 95530 THEN 668  -- [A] Broken Bobber
  WHEN 95531 THEN 1017804  -- [K] Wreckage Piece
  WHEN 95532 THEN 1074163  -- [K] Open Wound
  WHEN 95533 THEN 500002  -- [A] Tattered Cloth Roll
  WHEN 95534 THEN 515373  -- [A] Runed Quill Plume
  WHEN 95535 THEN 1049754  -- [A] Silk Drape
  WHEN 95536 THEN 5743  -- [A] Dust-Covered Trunk
  WHEN 95537 THEN 667  -- [A] Soot-Covered Flames
  WHEN 95538 THEN 515293  -- [A] Dusty Hat
  WHEN 95539 THEN 86293  -- [A] Bound Remains
  WHEN 95602 THEN 515102  -- [A] Worn Shovel
  WHEN 95603 THEN 515190  -- [A] Sword in a Board
  WHEN 95604 THEN 100505  -- [A] Drumstick
  WHEN 95605 THEN 1010592  -- [A] Fire Poker
  WHEN 95606 THEN 5731  -- [A] Lost Tracker
  WHEN 95609 THEN 216  -- [A] Rattlecage Cauldron
  WHEN 95610 THEN 1058634  -- [A] Burial Wraps
  WHEN 95612 THEN 1014316  -- [A] Travel Sack
  WHEN 95613 THEN 10  -- [A] Waterlogged Chest
  WHEN 95614 THEN 88284  -- [A] Ridiculously Thick Web
  WHEN 95615 THEN 3675  -- [A] Wolf Droppings
  WHEN 95616 THEN 515093  -- [A] Hammerspine's Fallen Hammer
  WHEN 95617 THEN 1013469  -- [A] Discarded Hand Cannon
  WHEN 95618 THEN 254150  -- [A] Defias Cowl
  WHEN 95619 THEN 100506  -- [A] Enchanted Kobold Lantern
  WHEN 95622 THEN 515090  -- [A] Embedded Sword
  WHEN 95623 THEN 1010592  -- [A] Stormwitch Staff
  WHEN 95624 THEN 254162  -- [A] Broken Tail Spike
  WHEN 95625 THEN 254018  -- [A] Quilbow
  WHEN 95626 THEN 325  -- [A] Firestarter
  WHEN 95627 THEN 1029810  -- [C] Southfury Totem
  WHEN 95628 THEN 254163  -- [A] Abandoned Banner
  WHEN 95629 THEN 7144  -- [C] Scalper's Sack
  WHEN 95631 THEN 1006324  -- [A] Fishy Fishing Pole
  WHEN 95632 THEN 1033798  -- [C] Sailor's Gambeson
  WHEN 95633 THEN 1988  -- [C] Scorched Equipment Cache
  WHEN 95635 THEN 515022  -- [A] Assassin's Crossbow
  WHEN 95636 THEN 515088  -- [A] Totem Charged Mace
  WHEN 95637 THEN 7539  -- [A] Floating Cargo
  WHEN 95638 THEN 1988  -- [C] Farmer's Old Gear
  WHEN 95639 THEN 515117  -- [A] Centaur Axe
  WHEN 95640 THEN 515096  -- [A] Apprentice's Harpoon
  WHEN 95641 THEN 3451  -- [A] Untouched Cactus Fruit
  WHEN 95642 THEN 1059993  -- [A] Burning Blade Initiate's Stash
  WHEN 95643 THEN 526008  -- [A] Retired Shadow Blade
  WHEN 95644 THEN 7678  -- [C] Pillaged Sack
  WHEN 95645 THEN 1070109  -- [D] Silt Covered Ring
  WHEN 95646 THEN 515201  -- [A] Stuck Sword
  WHEN 95647 THEN 515217  -- [A] Orcish Fishing Device
  WHEN 95648 THEN 515121  -- [A] Logsplitter
  WHEN 95650 THEN 254164  -- [A] Harpy Hunter
  WHEN 95651 THEN 515366  -- [A] Looted Shield
  WHEN 95652 THEN 468  -- [C] Loot Basket
  WHEN 95653 THEN 2612  -- [A] Dark Iron Traitor
  WHEN 95654 THEN 1012699  -- [A] Frozen Boots
  WHEN 95655 THEN 515094  -- [A] Rock Smasher
  WHEN 95656 THEN 515018  -- [A] Venture Co. Union Buster
  WHEN 95657 THEN 7678  -- [C] Unclaimed Sack
  WHEN 95659 THEN 515365  -- [A] Fire Strike
  WHEN 95661 THEN 515203  -- [A] Wind Shearer
  WHEN 95662 THEN 41  -- [A] Appropriated Goods
  WHEN 95666 THEN 2450  -- [A] Makashar's Belongings
  WHEN 95668 THEN 1012699  -- [A] Spare Boots
  WHEN 95670 THEN 1010931  -- [A] Apprentice Staff
  WHEN 95671 THEN 1014519  -- [A] Stashed Goods
  WHEN 95673 THEN 211  -- [A] Dwarf Remains
  WHEN 95676 THEN 7954  -- [A] Frostmane Totem
  WHEN 95677 THEN 254149  -- [A] Throwing Rock
  WHEN 95678 THEN 254034  -- [A] Officer's Pike
  WHEN 95679 THEN 9168  -- [A] Warm Whoolies
  WHEN 95681 THEN 3675  -- [A] Bear Left Overs
  WHEN 95683 THEN 515348  -- [A] Reinforced Spare Wheel
  WHEN 95686 THEN 6396  -- [C] Spare Equipment
  WHEN 95687 THEN 254151  -- [A] Heavy Iron Pan
  WHEN 95688 THEN 515087  -- [A] Defias Shanker
  WHEN 95690 THEN 254015  -- [A] Homer's Boar Harvester
  WHEN 95691 THEN 100507  -- [A] Confiscated Crossbow
  WHEN 95692 THEN 31  -- [C] Morale Boosters
  WHEN 95693 THEN 100508  -- [A] Murloc Ritual Stick
  WHEN 95694 THEN 100510  -- [A] Jack's Toothpicker
  WHEN 95695 THEN 100511  -- [A] Embedded Axe
  WHEN 95696 THEN 1011607  -- [D] Riding Cloak
  WHEN 95697 THEN 100512  -- [A] Murder Machete
  WHEN 95698 THEN 515224  -- [A] Garren's Pitchfork
  WHEN 95700 THEN 515034  -- [A] Waterlogged Rifle
  WHEN 95706 THEN 515122  -- [A] Forgotten Dwarven Axe
  WHEN 95707 THEN 7356  -- [C] Partially Buried Tablet
  WHEN 95709 THEN 189137  -- [A] Arcane Blade
  WHEN 95710 THEN 515093  -- [A] Hull Breaker
  WHEN 95711 THEN 189469  -- [A] Pirate Sabre
  WHEN 95712 THEN 5744  -- [A] Cannon Master's Belongings
  WHEN 95713 THEN 1013469  -- [A] Bloodsail Decksweeper
  WHEN 95714 THEN 1029730  -- [A] Tanning Rack
  WHEN 95715 THEN 138078  -- [D] Baby Gorilla Bait
  WHEN 95716 THEN 1869  -- [C] Stolen Armor Shipment
  WHEN 95717 THEN 515376  -- [A] Pirate's Lost Axe
  WHEN 95718 THEN 1050445  -- [D] Brilliant Shell
  WHEN 95719 THEN 179765  -- [A] Buccaneer's Shiv
  WHEN 95720 THEN 515538  -- [A] Well Used Trident
  WHEN 95721 THEN 1065373  -- [A] Dead Explorer's Pack
  WHEN 95722 THEN 7308  -- [A] Murdered Fisherman
  WHEN 95723 THEN 84677  -- [A] Razorsharp Tooth
  WHEN 95724 THEN 184800  -- [A] Strange Book
  WHEN 95725 THEN 2630  -- [A] Pristine Feather
  WHEN 95726 THEN 515377  -- [A] Voodoo Bonemaker
  WHEN 95727 THEN 1  -- [K] Half Buried Shipment
  WHEN 95728 THEN 188302  -- [A] Witchdoctor Effigy
  WHEN 95729 THEN 63519  -- [D] Glinting Silt-Encrusted Necklace
  WHEN 95730 THEN 180728  -- [A] Gore Coated Pauldrons
  WHEN 95731 THEN 179776  -- [A] Bloodscalper
  WHEN 95732 THEN 515316  -- [A] Death Trophy
  WHEN 95733 THEN 31  -- [C] Stolen Property
  WHEN 95734 THEN 184940  -- [A] Yojamba Hex Skull
  WHEN 95735 THEN 7781  -- [C] Unstable Water Lodestone
  WHEN 95736 THEN 1070109  -- [K] Zul'Kunda Blood Ring
  WHEN 95737 THEN 1074163  -- [A] Drowned Man's Necklace
  WHEN 95738 THEN 2450  -- [A] Scout's Stash
  WHEN 95739 THEN 176000  -- [A] Bloodscalp Bow
  WHEN 95740 THEN 1012699  -- [A] Left Behind Boots
  WHEN 95741 THEN 186376  -- [A] Riverheart Crest
  WHEN 95742 THEN 515379  -- [A] Kurzen Medicine Compendium
  WHEN 95743 THEN 175384  -- [A] Heavy Jungle Chopper
  WHEN 95744 THEN 515180  -- [A] The Wrangler
  WHEN 95745 THEN 5743  -- [A] Kurzen Officer's Trunk
  WHEN 95746 THEN 189456  -- [A] Kurzen Eviscerator
  WHEN 95747 THEN 186305  -- [A] Crystallized Shield
  WHEN 95748 THEN 31  -- [D] Venture Co. Gear
  WHEN 95749 THEN 7737  -- [A] Splinter Guard
  WHEN 95750 THEN 1074163  -- [K] Loose Gear
  WHEN 95751 THEN 1010931  -- [A] Fifth Staff of Mosh'Ogg Circle
  WHEN 95752 THEN 515380  -- [A] Mai'Zoth's Artifact
  WHEN 95753 THEN 1018771  -- [K] Mosh'Ogg Protection Totem
  WHEN 95754 THEN 515036  -- [A] Skullsplitter Crossbow
  WHEN 95755 THEN 184782  -- [C] Ritual Tome
  WHEN 95756 THEN 1074163  -- [A] Encased Amulet
  WHEN 95757 THEN 336  -- [C] Abandoned Supplies
  WHEN 95758 THEN 515311  -- [A] The Ironjaw
  WHEN 95759 THEN 174784  -- [A] Stonesplitter
  WHEN 95760 THEN 186415  -- [A] Fallen Gladiator's Shield
  WHEN 95761 THEN 63520  -- [C] Suspiciously Cool Amulet
  WHEN 95762 THEN 1061335  -- [C] Black Powder Sack
  WHEN 95763 THEN 63518  -- [C] Offering
  WHEN 95764 THEN 1010519  -- [A] Tribal Runners
  WHEN 95765 THEN 1014316  -- [A] Clawed Up Bag
  WHEN 95766 THEN 1027445  -- [C] Dead Druid's Relic
  WHEN 95767 THEN 190130  -- [A] Gurubashi Throwing Axe
  WHEN 95777 THEN 4  -- [A] Salma's Summer Wardrobe
  WHEN 95778 THEN 500006  -- [A] Field Boots
  WHEN 95779 THEN 31  -- [C] Storage Crate
  WHEN 95780 THEN 174916  -- [A] Gnoll Cleaver
  WHEN 95781 THEN 186265  -- [A] Harvester?s Aegis
  WHEN 95782 THEN 190147  -- [A] Defias Throwing Knife
  WHEN 95783 THEN 41  -- [A] Charred Strongbox
  WHEN 95784 THEN 1015607  -- [A] Klaven's Wardrobe
  WHEN 95785 THEN 515105  -- [A] Quarry Sledge
  WHEN 95786 THEN 188673  -- [A] Harvest Scythe
  WHEN 95787 THEN 5743  -- [C] Rower's Footlocker
  WHEN 95788 THEN 69735  -- [A] Partially Digested Corpse
  WHEN 95789 THEN 184722  -- [A] Sludge Hammer
  WHEN 95790 THEN 63517  -- [A] Fort Defender Band
  WHEN 95791 THEN 185530  -- [A] Vilebranch Beastlance
  WHEN 95792 THEN 515322  -- [A] Shadowpounce Cowl
  WHEN 95793 THEN 186379  -- [A] Terrapine Carapace
  WHEN 95794 THEN 406  -- [B] Idol of the Aerie
  WHEN 95795 THEN 1074449  -- [A] Hidden Stash
  WHEN 95796 THEN 4191  -- [A] Undelivered Package
  WHEN 95797 THEN 1062275  -- [A] Trapper's Lone Band
  WHEN 95798 THEN 2450  -- [A] Witch Doctor's Stash
  WHEN 95801 THEN 1013433  -- [C] Unearthed Ring
  WHEN 95803 THEN 515104  -- [A] Ulag's Other Cleaver
  WHEN 95804 THEN 254152  -- [A] Captain's Shield
  WHEN 95805 THEN 515189  -- [A] Butchery Blade
  WHEN 95806 THEN 1033131  -- [A] Murloc Plunder
  WHEN 95807 THEN 31  -- [C] Forgotten Shipment
  WHEN 95808 THEN 1038182  -- [A] Liquid Arcane
  WHEN 95809 THEN 1  -- [A] Unlocked Chest
  WHEN 95810 THEN 515005  -- [A] Sentinel's Blade
  WHEN 95811 THEN 515265  -- [A] Defias Handshake
  WHEN 95812 THEN 1010201  -- [A] Travel Sack
  WHEN 95813 THEN 515147  -- [A] Defias Toe Knife
  WHEN 95814 THEN 41  -- [A] Stashed Goods
  WHEN 95815 THEN 31  -- [C] Salvaged Goods
  WHEN 95816 THEN 515106  -- [A] Defias Magus Staff
  WHEN 95817 THEN 1009920  -- [A] Heavy Stompers
  WHEN 95818 THEN 515245  -- [A] Sharpened Chopper
  WHEN 95819 THEN 1044908  -- [D] Heavy Bone
  WHEN 95820 THEN 515132  -- [A] Dirt Covered Sword
  WHEN 95821 THEN 1010201  -- [C] Spare Bag
  WHEN 95822 THEN 515204  -- [A] The Dark Soul
  WHEN 95823 THEN 515060  -- [A] Silk Covered Spaulders
  WHEN 95824 THEN 9170  -- [A] Suspiciously Brown Discarded Pants
  WHEN 95825 THEN 1018631  -- [A] Tilloa's Flowers
  WHEN 95826 THEN 526628  -- [A] Nightshot
  WHEN 95829 THEN 5531  -- [D] Conscription Supplies
  WHEN 95830 THEN 515094  -- [A] Drudger Smash
  WHEN 95831 THEN 515180  -- [A] Sharpened Pike
  WHEN 95832 THEN 5531  -- [D] Stolen Crossroads Shipment
  WHEN 95833 THEN 9168  -- [A] Forgotten Pool Trunks
  WHEN 95834 THEN 1074163  -- [A] Captain's Chain
  WHEN 95835 THEN 254174  -- [A] Embedded Axe
  WHEN 95836 THEN 100507  -- [A] Bristle Crossbow
  WHEN 95837 THEN 100522  -- [A] Peon Motivator
  WHEN 95838 THEN 100525  -- [A] Syndicate Spell Tome
  WHEN 95839 THEN 515537  -- [A] Stormguard
  WHEN 95840 THEN 188370  -- [A] Caretaker's Burden
  WHEN 95841 THEN 190335  -- [A] Peace of the Dead
  WHEN 95842 THEN 179762  -- [A] Syndicate Shanker
  WHEN 95843 THEN 188896  -- [A] Lordly Blade
  WHEN 95844 THEN 41  -- [A] Thief's Stash
  WHEN 95845 THEN 1062275  -- [C] Rather Large Ring
  WHEN 95846 THEN 515328  -- [A] Well Worn Hat
  WHEN 95847 THEN 31  -- [C] Clothing Crate
  WHEN 95848 THEN 179285  -- [A] Handheld Persuasion Device
  WHEN 95849 THEN 174942  -- [A] Embedded Axe
  WHEN 95850 THEN 184723  -- [A] Witherbark Headsmasher
  WHEN 95851 THEN 1018771  -- [K] Witherbark Totem
  WHEN 95853 THEN 184338  -- [A] Fallen Adventurer's Mace
  WHEN 95854 THEN 189826  -- [A] Heat Tempered Sword
  WHEN 95855 THEN 5743  -- [A] Witherbark Cache
  WHEN 95856 THEN 175993  -- [A] Poacher's Bow
  WHEN 95857 THEN 178328  -- [A] Dark Iron Blaster
  WHEN 95858 THEN 183918  -- [A] Sunken Mace
  WHEN 95859 THEN 1010146  -- [A] Shiny Kobold Treasure
  WHEN 95860 THEN 9170  -- [A] Warm Dry Pants
  WHEN 95861 THEN 2612  -- [A] Decayed Corpse
  WHEN 95862 THEN 1014519  -- [A] Hidden Stash
  WHEN 95863 THEN 138104  -- [A] Safe Treasure No One Could Ever Reach
  WHEN 95864 THEN 1043587  -- [A] Valuable Offering
  WHEN 95865 THEN 515316  -- [A] Intact Plate Helm
  WHEN 95866 THEN 515365  -- [A] Ancient Naga Trident
  WHEN 95867 THEN 175384  -- [A] Barnacle-Crusted Boarder's Axe
  WHEN 95868 THEN 1050391  -- [C] Circle of Waves Idol
  WHEN 95870 THEN 1033798  -- [A] Brumn's Discarded Project
  WHEN 95872 THEN 336  -- [A] Abandoned Supplies
  WHEN 95874 THEN 100854  -- [A] Climbing Boots
  WHEN 95875 THEN 176141  -- [A] Plains Bolter
  WHEN 95876 THEN 41  -- [A] Waterproof Trunk
  WHEN 95877 THEN 190151  -- [A] Throwing Dagger
  WHEN 95879 THEN 1043587  -- [C] Valuable Offering
  WHEN 95880 THEN 179772  -- [A] Shiv of Warm Greetings
  WHEN 95881 THEN 178314  -- [A] Pillow Gun
  WHEN 95882 THEN 174902  -- [A] Zun'watha Cleaver
  WHEN 95883 THEN 178327  -- [A] Overwatch Longrifle
  WHEN 95884 THEN 9168  -- [A] Drinkin' Pants
  WHEN 95885 THEN 1012699  -- [A] Heavy Boots
  WHEN 95886 THEN 1064624  -- [C] Highvale Wellband
  WHEN 95887 THEN 175771  -- [A] Highvale Ranger's Bow
  WHEN 95889 THEN 179754  -- [A] Ritual Hideskinner
  WHEN 95890 THEN 2450  -- [A] Ritual Chest
  WHEN 95891 THEN 1047683  -- [A] Totem of the Broodmother
  WHEN 95892 THEN 2450  -- [A] Witherbark Chest
  WHEN 95893 THEN 1010315  -- [A] Offering Chest
  WHEN 95894 THEN 181600  -- [A] Floodworn Shoulderguards
  WHEN 95895 THEN 41  -- [A] Undelivered Shipment
  WHEN 95896 THEN 183228  -- [A] Ooze Cleansed Shoulderpads
  WHEN 95897 THEN 10  -- [A] Sunken Chest
  WHEN 95898 THEN 1049754  -- [A] Carefully Folded Cloak
  WHEN 95899 THEN 1060885  -- [A] Elder Highpeak's Keepsake Box
  WHEN 95900 THEN 515252  -- [A] Hexcall Gavel
  WHEN 95901 THEN 188488  -- [A] Blood Keeper's Staff
  WHEN 95902 THEN 2450  -- [A] Warder's Cache
  WHEN 95903 THEN 1013433  -- [A] Glinting Object
  WHEN 95904 THEN 1056972  -- [A] Oozing Thoughtcore
  WHEN 95906 THEN 190129  -- [A] Vilebranch Warthrower
  WHEN 95907 THEN 179696  -- [A] Ritual Knife
  WHEN 95908 THEN 188893  -- [A] The Blood Talon
  WHEN 95909 THEN 184782  -- [A] Ritual Tome
  WHEN 95910 THEN 189901  -- [A] Flayer's Edge
  WHEN 95911 THEN 176141  -- [A] Highnest Repeater
  WHEN 95912 THEN 175458  -- [A] Bloody Cleaver
  WHEN 95915 THEN 184809  -- [A] Strongly Scented Bottle
  WHEN 95916 THEN 179754  -- [A] Bone Scraper
  WHEN 95917 THEN 188412  -- [A] Crystal Encased Staff
  WHEN 95918 THEN 186378  -- [A] Preserved Dermal Plate
  WHEN 95919 THEN 7526  -- [A] Campsite Shrapnel
  WHEN 95920 THEN 1058162  -- [A] Crystal Resonator Coffer
  WHEN 95921 THEN 515387  -- [A] Hive Queen's Antenna
  WHEN 95922 THEN 31  -- [A] Failed Delivery
  WHEN 95923 THEN 1  -- [A] Waterlogged Chest
  WHEN 95924 THEN 8520  -- [A] Ancient Libram
  WHEN 95925 THEN 179790  -- [A] Spring Blade
  WHEN 95926 THEN 189189  -- [A] Heating Blade
  WHEN 95927 THEN 175633  -- [A] Fallen Axe
  WHEN 95928 THEN 182259  -- [A] Ballast Laden Pauldrons
  WHEN 95929 THEN 8285  -- [A] Hot Springs Scouring Basket
  WHEN 95930 THEN 179707  -- [A] Glowing Blade
  WHEN 95931 THEN 1012682  -- [A] Totem of Scorching Sparks
  WHEN 95932 THEN 1009920  -- [A] Blaze Runners
  WHEN 95933 THEN 515288  -- [A] Volcano Heated Crown
  WHEN 95934 THEN 1070109  -- [A] Precious Ring
  WHEN 95935 THEN 190185  -- [A] Ringo's Throwing Star
  WHEN 95936 THEN 189465  -- [A] Forlorn Memorial
  WHEN 95937 THEN 1061943  -- [A] Feeding Pile
  WHEN 95938 THEN 179594  -- [A] Stinger
  WHEN 95939 THEN 10  -- [A] Sealed Shipping Crate
  WHEN 95940 THEN 41  -- [A] Forgotten Supplies
  WHEN 95941 THEN 515304  -- [A] Stardust Scoured Helmet
  WHEN 95942 THEN 175317  -- [A] Fallen Warrior's Axe
  WHEN 95943 THEN 100556  -- [A] Roland's Striker
  WHEN 95945 THEN 10  -- [A] Clawed Chest
  WHEN 95946 THEN 174925  -- [A] Well Kept Hatchet
  WHEN 95947 THEN 515153  -- [A] A "Fishy" Staff
  WHEN 95948 THEN 175762  -- [A] Camouflaged Bow
  WHEN 96101 THEN 336  -- [A] Abandoned Supplies
  WHEN 96102 THEN 174960  -- [A] Logging Axe
  WHEN 96103 THEN 1016156  -- [A] Hanging Ogre Pouch
  WHEN 96104 THEN 515429  -- [A] Large Bone
  WHEN 96105 THEN 1029891  -- [A] Stolen Tome
  WHEN 96106 THEN 515245  -- [A] Ogre Cleaver
  WHEN 96108 THEN 1017863  -- [A] Tightly Sealed Lockbox
  WHEN 96109 THEN 175768  -- [A] Nightfallen Longbow
  WHEN 96110 THEN 1041127  -- [A] Strange Glowing Orb
  WHEN 96111 THEN 1041029  -- [C] Ancient Statue
  WHEN 96112 THEN 515297  -- [A] Crystalline Crown
  WHEN 96113 THEN 1012699  -- [A] Mud-Covered Boots
  WHEN 96114 THEN 7741  -- [A] Tanned Tunic
  WHEN 96115 THEN 7679  -- [A] Bulging Sack
  WHEN 96116 THEN 1074163  -- [A] Ancient Necklace
  WHEN 96117 THEN 3851  -- [A] Sickly-Looking Egg
  WHEN 96118 THEN 1032864  -- [A] Forgotten Light of Elune
  WHEN 96119 THEN 1012986  -- [A] Yeti Napkin
  WHEN 96120 THEN 1074449  -- [A] Ogre Laundry Pouch
  WHEN 96122 THEN 63518  -- [A] Glint of Metal
  WHEN 96123 THEN 8513  -- [A] Strange Glowing Object
  WHEN 96124 THEN 515426  -- [A] Hatestrike
  WHEN 96125 THEN 186563  -- [A] Busted Buckler
  WHEN 96126 THEN 1036633  -- [A] Tanner's Chest
  WHEN 96127 THEN 515156  -- [A] Pruning Knife
  WHEN 96128 THEN 1013842  -- [A] Slightly Scorched Supplies
  WHEN 96130 THEN 5743  -- [A] Hunter's Cache
  WHEN 96131 THEN 179949  -- [A] Sacrifical Dagger
  WHEN 96132 THEN 1017808  -- [A] Accursed Yeti Horn
  WHEN 96133 THEN 515421  -- [A] Highborne Relic
  WHEN 96134 THEN 1035102  -- [A] Ancient Bag of Scrolls
  WHEN 96135 THEN 515424  -- [A] Gnoll Throwing Axe
  WHEN 96136 THEN 180714  -- [A] Unsavory Scraps
  WHEN 96137 THEN 515425  -- [A] Woodpaw Greatblade
  WHEN 96138 THEN 1074163  -- [A] Chip of Amber
  WHEN 96139 THEN 7649  -- [A] Hivemother's Carapace
  WHEN 96140 THEN 6502  -- [A] Unearthed Treasures
  WHEN 96141 THEN 1065373  -- [A] Adventurer's Backpack
  WHEN 96142 THEN 1065373  -- [A] Tattered Fur Remains
  WHEN 96143 THEN 1065373  -- [A] Half-Eaten Gnoll
  WHEN 96144 THEN 1021194  -- [A] Gnollish Artillery
  WHEN 96145 THEN 4192  -- [A] Woodpaw Chest
  WHEN 96146 THEN 175455  -- [A] Freshly Sharpened Axe
  WHEN 96147 THEN 515423  -- [A] Spotter's Rifle
  WHEN 96148 THEN 1043036  -- [A] Firemane Effigy
  WHEN 96150 THEN 1016305  -- [A] Moxie's Tool Bucket
  WHEN 96151 THEN 185530  -- [A] Dropped Polearm
  WHEN 96152 THEN 928  -- [A] Singed Booklet
  WHEN 96153 THEN 254098  -- [A] Useful Potion
  WHEN 96155 THEN 1014666  -- [A] Worshipped Warpwood Growth
  WHEN 96156 THEN 10  -- [A] Prized Lockbox
  WHEN 96157 THEN 63430  -- [A] Freshly Brewed Potion
  WHEN 96158 THEN 1045546  -- [A] Darazzal's Chest
  WHEN 96159 THEN 515447  -- [A] Fel Axe
  WHEN 96160 THEN 1070109  -- [C] Silvery Ring
  WHEN 96161 THEN 1074163  -- [A] Shining Necklace
  WHEN 96162 THEN 1013847  -- [A] Spiked Collar
  WHEN 96166 THEN 1387  -- [C] Heavy Chest
  WHEN 96167 THEN 138105  -- [A] Shareholder's Coffer
  WHEN 96168 THEN 178505  -- [A] Polished Rifle
  WHEN 96169 THEN 1065404  -- [A] Dreamcatcher
  WHEN 96170 THEN 1054483  -- [C] Silverback Cape
  WHEN 96173 THEN 515444  -- [A] Jane's Hat
  WHEN 96174 THEN 1029814  -- [A] Kodo Riding Harness
  WHEN 96175 THEN 175957  -- [A] Well Loved Bow
  WHEN 96176 THEN 5011  -- [A] Amethyst Shard
  WHEN 96177 THEN 1060048  -- [A] Strange Glowing Crystal
  WHEN 96178 THEN 515449  -- [A] Engineer's Tongs
  WHEN 96179 THEN 2350  -- [A] Abandoned Crate
  WHEN 96180 THEN 515450  -- [A] Spear of a Slain Hunter
  WHEN 96181 THEN 176684  -- [A] Ancient Earth Idol
  WHEN 96182 THEN 515451  -- [A] Protruding Bone
  WHEN 96183 THEN 8052  -- [A] Small Meteor
  WHEN 96184 THEN 1066565  -- [A] Mutated Threshadon Heart
  WHEN 96185 THEN 20  -- [A] Shallow Grave
  WHEN 96186 THEN 5511  -- [A] Raptor Thief's Corpse
  WHEN 96188 THEN 1060885  -- [A] Charging Box
  WHEN 96189 THEN 515453  -- [A] Improvised Lever
  WHEN 96190 THEN 391  -- [A] Tar-Covered Sproutling
  WHEN 96191 THEN 101677  -- [A] Hefty Bone
  WHEN 96192 THEN 285  -- [A] Nethergarde Crate
  WHEN 96193 THEN 515284  -- [A] Nethergarde Mining Cap
  WHEN 96194 THEN 336  -- [A] Old Crate
  WHEN 96195 THEN 1036633  -- [A] Dreadmaul Supplies
  WHEN 96196 THEN 7943  -- [A] Rusted Shoulderplate
  WHEN 96197 THEN 184705  -- [A] Ogre Mace
  WHEN 96198 THEN 179698  -- [A] Half-Buried Dagger
  WHEN 96199 THEN 1010316  -- [A] Kum'isha's Supply Chest
  WHEN 96200 THEN 515429  -- [A] Skeletal Claw
  WHEN 96201 THEN 86641  -- [A] Shadowsworn Staff
  WHEN 96202 THEN 175337  -- [A] Sharpened Axe
  WHEN 96203 THEN 188401  -- [A] Magical Staff
  WHEN 96204 THEN 10  -- [A] Mojo's Chest
  WHEN 96205 THEN 1010588  -- [A] Shadowsworn Chest
  WHEN 96206 THEN 188676  -- [A] Empowered Scythe
  WHEN 96207 THEN 179987  -- [A] Sacrificial Knife
  WHEN 96208 THEN 1046185  -- [A] Skewered Doll
  WHEN 96209 THEN 8513  -- [A] Glowing Gem
  WHEN 96210 THEN 254102  -- [A] Smoldering Boots
  WHEN 96211 THEN 1028909  -- [A] Slime-Covered Bracers
  WHEN 96212 THEN 1051775  -- [A] Wooden Chest
  WHEN 96213 THEN 1074449  -- [A] Beach Bag
  WHEN 96214 THEN 1070109  -- [A] Beautifully Crafted Bracelets
  WHEN 96215 THEN 7922  -- [A] Ravasaur Claw
  WHEN 96216 THEN 174930  -- [A] Sharpened Hatchet
  WHEN 96217 THEN 90836  -- [A] Abandoned Mallet
  WHEN 96218 THEN 515290  -- [A] Steel Helmet
  WHEN 96219 THEN 10  -- [A] Bert's Box of Success
  WHEN 96220 THEN 1010588  -- [A] Ritual Chest
  WHEN 96221 THEN 1065373  -- [A] Fallen Adventurer
  WHEN 96222 THEN 254099  -- [A] Tar Stuck Wrap
  WHEN 96223 THEN 515443  -- [A] Ominous Sword
  WHEN 96224 THEN 1066612  -- [A] Portal Anchor
  WHEN 96225 THEN 1030083  -- [C] Cenarion Crate
  WHEN 96226 THEN 1041127  -- [A] Highborne Momento
  WHEN 96228 THEN 1056773  -- [A] Gnomish Chest
  WHEN 96229 THEN 2976  -- [A] Sample Box
  WHEN 96232 THEN 1050644  -- [A] Elemental Bracer
  WHEN 96233 THEN 178994  -- [A] Spare Hammer
  WHEN 96234 THEN 41  -- [A] Chest of Warm Clothes
  WHEN 96235 THEN 10  -- [A] Harvester's Chest
  WHEN 96236 THEN 615123  -- [A] Plagued Bow
  WHEN 96238 THEN 655981  -- [C] Assistant's Remains
  WHEN 96239 THEN 184763  -- [A] Empty Bag
  WHEN 96240 THEN 184594  -- [A] Crusader's Mace
  WHEN 96241 THEN 1030083  -- [A] Gift of Malorne
  WHEN 96243 THEN 259  -- [A] Slightly-Damaged Chest
  WHEN 96244 THEN 530296  -- [A] Pulsating Staff
  WHEN 96246 THEN 1013845  -- [A] Apothecary Sack
  WHEN 96247 THEN 41  -- [A] Druidic Chest
  WHEN 96248 THEN 12000  -- [A] Fire-Resistant Lockbox
  WHEN 97100 THEN 1070109  -- [K] Hidden Ring
  WHEN 97101 THEN 300145  -- [A] Yeti Loot Hoard
  WHEN 97102 THEN 515252  -- [A] Grimtotem Striker
  WHEN 97103 THEN 1060114  -- [A] Talon Idol
  WHEN 97104 THEN 175965  -- [A] Dryad's Bow
  WHEN 97107 THEN 1017804  -- [A] Fallen Nest
  WHEN 97108 THEN 287  -- [A] Lost Shipment
  WHEN 97109 THEN 468  -- [A] Laundry Basket
  WHEN 97111 THEN 1988  -- [A] Sunrock Supplies
  WHEN 97112 THEN 184046  -- [A] Thornweaver Mace
  WHEN 97113 THEN 189694  -- [A] Embedded Claymore
  WHEN 97114 THEN 175319  -- [A] Blackthorn Splitter
  WHEN 97115 THEN 190148  -- [A] Thrown Dagger
  WHEN 97116 THEN 190330  -- [A] Discarded Wand
  WHEN 97117 THEN 515265  -- [A] Malgin's Barback
  WHEN 97118 THEN 63519  -- [A] Muck Coated Pendant
  WHEN 97119 THEN 1070109  -- [K] Plundered Ring
  WHEN 97120 THEN 189697  -- [A] Abandoned Greatsword
  WHEN 97121 THEN 1  -- [A] Stolen Shipment
  WHEN 97123 THEN 5333  -- [A] Snowy Grave
  WHEN 97124 THEN 176068  -- [A] Syndicate Crossbow
  WHEN 97125 THEN 184718  -- [A] Tombbound Warhammer
  WHEN 97126 THEN 1015578  -- [A] Weathered Chest
  WHEN 97127 THEN 178310  -- [A] Unfired Rifle
  WHEN 97128 THEN 286  -- [A] Venture Co Supplies
  WHEN 97129 THEN 176016  -- [A] Bloodsail Longbow
  WHEN 97130 THEN 2450  -- [A] Bloodscalp Tribute Chest
  WHEN 97131 THEN 1016156  -- [A] Tattered Goblin Cargo Sack
  WHEN 97132 THEN 1988  -- [A] Unloaded Shipment
  WHEN 97133 THEN 188390  -- [A] Kolkar Staff
  WHEN 97134 THEN 4191  -- [A] Intercepted Package
  WHEN 97135 THEN 1010377  -- [A] Useless Racing Parts
  WHEN 97136 THEN 176068  -- [A] Needlewind Crossbow
  WHEN 97137 THEN 285  -- [A] Lost Shipment
  WHEN 142102 THEN 1947  -- [A] Mailbox
  WHEN 142109 THEN 1948  -- [A] Mailbox
  WHEN 144570 THEN 1947  -- [C] Mailbox
  WHEN 150900 THEN 5746  -- [A] Mineral Fragment
  WHEN 158300 THEN 5497  -- [A] Elder's Pipe
  WHEN 158305 THEN 515344  -- [A] Wrench
  WHEN 158307 THEN 1019881  -- [A] Lost Mail Armor
  WHEN 158309 THEN 175316  -- [A] Two-Handed Axe
  WHEN 158313 THEN 178320  -- [A] Scoped Rifle
  WHEN 158316 THEN 179741  -- [A] Burned Blade Shiv
  WHEN 158319 THEN 903737  -- [A] Dark Iron Hood
  WHEN 158320 THEN 1014316  -- [A] Bag of Disciplinary Tools
  WHEN 158321 THEN 177517  -- [A] Broken Chain
  WHEN 158328 THEN 287  -- [A] Important Belongings
  WHEN 158330 THEN 189742  -- [A] Scorched Greatblade
  WHEN 158333 THEN 1057260  -- [A] Eye of Twilight
  WHEN 159984 THEN 515664  -- [A] Crystal Axe
  WHEN 159985 THEN 259  -- [A] Solid Chest
  WHEN 159997 THEN 189470  -- [A] Freedom Falchion
  WHEN 184133 THEN 6870  -- [A] Mailbox
  WHEN 184134 THEN 7013  -- [A] Mailbox
  WHEN 188132 THEN 1947  -- [C] Mailbox
  WHEN 254026 THEN 1014782  -- [A] Forgotten Flower
  WHEN 254156 THEN 254036  -- [B] Ancient Furbolg Totem
  WHEN 254162 THEN 1025463  -- [C] Eroded Sigil Stone
  WHEN 254163 THEN 254016  -- [A] Abandoned Hammer
  WHEN 254164 THEN 254017  -- [A] Scarlet Shield
  WHEN 254165 THEN 323  -- [A] Abandoned Bag
  WHEN 254166 THEN 378  -- [A] Quivering Web
  WHEN 254172 THEN 6891  -- [A] Principles of Cryomancy - Ultimate Edition, Version 2
  WHEN 254176 THEN 254018  -- [A] Scourgewarped Bow
  WHEN 254177 THEN 563  -- [D] Fairbreeze Feast
  WHEN 254178 THEN 254019  -- [A] Faded Ward of the East Sanctum
  WHEN 254193 THEN 8577  -- [D] Broken Highborne Lamp
  WHEN 254194 THEN 500027  -- [A] Spare Hunting Boots
  WHEN 254221 THEN 1  -- [B] Bloodwashed Gloves
  WHEN 254222 THEN 254026  -- [A] Flower of Tranquility
  WHEN 254223 THEN 254027  -- [A] Staff of Talons
  WHEN 254225 THEN 254028  -- [A] Overseer's Axe
  WHEN 254227 THEN 1056220  -- [A] Grimtotem Totem
  WHEN 254228 THEN 254176  -- [A] Bloodfury Tapestry
  WHEN 254229 THEN 254029  -- [A] Ziz's Alchemy Goggles
  WHEN 254230 THEN 1074163  -- [K] Resonite Band
  WHEN 254231 THEN 254175  -- [A] Woven Ceremonial Belt
  WHEN 254232 THEN 4451  -- [A] Slain Traveler
  WHEN 254233 THEN 354031  -- [A] Crimson Dragonscale
  WHEN 254234 THEN 1066612  -- [A] Balgaras's Foul Amulet
  WHEN 254235 THEN 254031  -- [A] Wyrmscale Spaulders
  WHEN 254236 THEN 1058753  -- [A] Kixxle's Experimental Potion
  WHEN 254237 THEN 1  -- [A] Snellig's Footlocker
  WHEN 254238 THEN 1  -- [A] Fitzsimmons' Footlocker
  WHEN 254240 THEN 4451  -- [A] Gnawed Bones
  WHEN 254255 THEN 254037  -- [A] Arkonite Orb
  WHEN 254258 THEN 1013435  -- [A] Ball of Yarn
  WHEN 254259 THEN 1012699  -- [A] Abandoned Boots
  WHEN 254260 THEN 336  -- [A] Caravan Crate
  WHEN 254261 THEN 254038  -- [A] Flamescoured Bow
  WHEN 254262 THEN 1988  -- [C] Crate of Mining Supplies
  WHEN 254263 THEN 323  -- [A] Sack of Ritual Attire
  WHEN 254264 THEN 515381  -- [A] Blade of Thunder
  WHEN 254265 THEN 1010201  -- [A] Moonglow Bag
  WHEN 254266 THEN 323  -- [A] Shadowprey Bag
  WHEN 254267 THEN 8295  -- [A] Hatefury Skull Totem
  WHEN 254268 THEN 515382  -- [A] Hatefury Wand
  WHEN 254269 THEN 254041  -- [A] Spear of Hatred
  WHEN 254270 THEN 515539  -- [A] Circlet of Desolation
  WHEN 254271 THEN 254043  -- [A] Blade of Dread
  WHEN 254272 THEN 6313  -- [A] Woven Flowers
  WHEN 254273 THEN 1988  -- [A] Caravan Guard's Supplies
  WHEN 254274 THEN 1988  -- [C] Caravan Guard's Supplies
  WHEN 254275 THEN 254044  -- [A] Sorrow of the Kodo
  WHEN 254276 THEN 254045  -- [A] Bone Splitter
  WHEN 254277 THEN 63516  -- [C] Offering to Azshara
  WHEN 254278 THEN 254047  -- [A] Water Seer's Headdress
  WHEN 254279 THEN 1012699  -- [A] Diving Boots
  WHEN 254280 THEN 254048  -- [A] Rusted Sword
  WHEN 254281 THEN 32  -- [A] Barrel of Goods
  WHEN 254282 THEN 1  -- [A] Washed-Up Chest
  WHEN 254283 THEN 254049  -- [A] Orb of Dawn
  WHEN 254284 THEN 323  -- [A] Sack of Kodo Hides
  WHEN 254285 THEN 254050  -- [A] Burning Blade Ritual Knife
  WHEN 254286 THEN 6477  -- [A] Heretical Libram
  WHEN 254287 THEN 254051  -- [A] Doomwarden
  WHEN 254288 THEN 1988  -- [C] Pillaged Crate
  WHEN 254289 THEN 254052  -- [A] Gelkis Cleaver
  WHEN 254290 THEN 254053  -- [A] Shell Cracker
  WHEN 254291 THEN 254046  -- [C] Sunken Ring
  WHEN 254292 THEN 1043302  -- [A] The Waiting Fisher
  WHEN 254294 THEN 254054  -- [C] The Undying Eye
  WHEN 254295 THEN 515120  -- [A] Magram Hatchet
  WHEN 254296 THEN 254056  -- [A] Crown of the Great Khan
  WHEN 254297 THEN 254057  -- [A] Jairal'kesh, Staff of Summoning
  WHEN 254298 THEN 254058  -- [A] Shadowbreaker
  WHEN 254299 THEN 254059  -- [A] Kodo Hunter
  WHEN 254300 THEN 254060  -- [A] The Winning Javelin
  WHEN 254301 THEN 254061  -- [A] Bone Harvester
  WHEN 254302 THEN 20  -- [A] Suspicious Dirt Pile
  WHEN 254303 THEN 254062  -- [A] Stormpiercer
  WHEN 254304 THEN 644  -- [A] Maraudine Basket
  WHEN 254305 THEN 644  -- [A] Maraudine Basket
  WHEN 254306 THEN 323  -- [A] Sack of Gloves
  WHEN 254307 THEN 1034276  -- [A] Icon of Khan Maraudos
  WHEN 254308 THEN 63520  -- [C] Ambereye Amulet
  WHEN 254309 THEN 254063  -- [A] Greataxe of Kolk
  WHEN 254310 THEN 254064  -- [A] Shadowshard Shield
  WHEN 254311 THEN 20  -- [A] Hidden Stash
  WHEN 254312 THEN 259  -- [A] Overlook Cache
  WHEN 254313 THEN 4  -- [A] Preserved Wardrobe
  WHEN 254314 THEN 254065  -- [A] Alteraci Avenger
  WHEN 254318 THEN 254066  -- [A] Embrace of the Fifth
  WHEN 254319 THEN 1016156  -- [C] Hanging Ogre Bag
  WHEN 254320 THEN 41  -- [A] Crushridge Chest
  WHEN 254321 THEN 254067  -- [A] Syndicate Chopping Axe
  WHEN 254322 THEN 470  -- [B] Libram of the Third Host
  WHEN 254323 THEN 254069  -- [A] Sentry Shot
  WHEN 254324 THEN 254068  -- [A] Staff of Argus
  WHEN 254325 THEN 254070  -- [A] Icecracker
  WHEN 254326 THEN 254071  -- [A] Ogre Toothpick
  WHEN 254327 THEN 5333  -- [A] Odd Snow Pile
  WHEN 254328 THEN 254072  -- [A] Frostwatch Defender
  WHEN 254329 THEN 336  -- [A] Syndicate Cobbler's Supplies
  WHEN 254330 THEN 254015  -- [A] Dandred's Harvester
  WHEN 254331 THEN 254073  -- [C] Hercular's Unstable Orb
  WHEN 254332 THEN 1022713  -- [C] Tracker's Scope
  WHEN 254334 THEN 254074  -- [A] Blood Soaked Spike
  WHEN 254335 THEN 254075  -- [A] Syndicate Slicer
  WHEN 254336 THEN 31  -- [C] Missing Alliance Supplies
  WHEN 254337 THEN 181664  -- [A] Frost Coated Pauldrons
  WHEN 254338 THEN 8323  -- [A] Icy Grave
  WHEN 254339 THEN 2314  -- [A] Arcane-Tinged Flower
  WHEN 254340 THEN 254076  -- [A] Coldridge Crusher
  WHEN 254341 THEN 515307  -- [A] Muckrake's Soup Scooper
  WHEN 254342 THEN 5333  -- [A] Snow Buried Shipment
  WHEN 254343 THEN 7311  -- [A] Raided Cadaver
  WHEN 254345 THEN 1015414  -- [A] Finished Fur Cloak
  WHEN 254346 THEN 1018771  -- [A] Last Guardian
  WHEN 254347 THEN 254077  -- [A] Panther Claw
  WHEN 254348 THEN 254078  -- [A] Jungle Stalker Pauldrons
  WHEN 254349 THEN 254046  -- [A] Ring of the Jungle
  WHEN 254350 THEN 1010201  -- [A] Gorlash's Stash
  WHEN 254351 THEN 10  -- [A] Overboard Treasure
  WHEN 254352 THEN 254079  -- [C] Mokrash's Ring
  WHEN 254353 THEN 254080  -- [A] Jungle Defender
  WHEN 254354 THEN 100883  -- [A] Rugged Leather Runners
  WHEN 254363 THEN 6884  -- [A] Mire Leaves
  WHEN 254364 THEN 644  -- [A] Fallow Basket
  WHEN 254365 THEN 7856  -- [A] Half-Buried Crate
  WHEN 254366 THEN 254081  -- [A] Lantern of Endless Sorrow
  WHEN 254367 THEN 254082  -- [A] Sorrowmurk Shrine Barrel
  WHEN 254368 THEN 63516  -- [C] Holy Atal'ai Band
  WHEN 254369 THEN 254083  -- [A] Spear of Emerald
  WHEN 254370 THEN 254095  -- [A] Icon of Blood
  WHEN 254371 THEN 63520  -- [C] Defiled Necklace
  WHEN 254372 THEN 254084  -- [A] Sunken Axe
  WHEN 254373 THEN 515159  -- [A] Sharpened Dragon Bone
  WHEN 254374 THEN 515540  -- [A] Shoulderguards of the Ancient Prophet
  WHEN 254375 THEN 254087  -- [A] Kazkaz's Ceremonial Mask
  WHEN 254376 THEN 1  -- [A] Atal'ai Alchemy Supplies
  WHEN 254377 THEN 254088  -- [A] Sha-Bane Staff
  WHEN 254378 THEN 1988  -- [A] Splinterspear Armor Crate
  WHEN 254379 THEN 6358  -- [A] Itharius's Jar
  WHEN 254380 THEN 287  -- [A] Biggs's Spare Equipment
  WHEN 254381 THEN 1012699  -- [A] Atal'ai Fisher's Boots
  WHEN 254382 THEN 254007  -- [A] Emerald Tear
  WHEN 254383 THEN 212  -- [A] Idol to Hakkar
  WHEN 254384 THEN 1010201  -- [A] Distant Wanderer's Pack
  WHEN 254385 THEN 254089  -- [A] Sawtooth Jaw
  WHEN 254386 THEN 8  -- [A] Forbidding Locker
  WHEN 254387 THEN 254082  -- [A] Misty Reed Barrel
  WHEN 254388 THEN 254090  -- [A] Swamp Talker's Crossbow
  WHEN 254389 THEN 254091  -- [A] Marsh Bonebreaker
  WHEN 254390 THEN 254082  -- [A] Cartographer's Supplies
  WHEN 254391 THEN 63519  -- [A] Exile's Amulet
  WHEN 254392 THEN 63517  -- [C] Dusksinger Band
  WHEN 254393 THEN 1045031  -- [A] Choker of Hakkar
  WHEN 254394 THEN 254092  -- [A] Murloc Crown
  WHEN 254395 THEN 254093  -- [A] Rusted Shield
  WHEN 254396 THEN 254240  -- [A] Marsh Adventurer's Boots
  WHEN 254398 THEN 323  -- [A] Loose Stone
  WHEN 254399 THEN 76328  -- [A] Scout's Supplies
  WHEN 254400 THEN 63517  -- [C] Ruby Giant's Eye
  WHEN 254401 THEN 515469  -- [A] The Wanderer's Stirring Rod
  WHEN 254402 THEN 7118  -- [A] Everdark Shard
  WHEN 254404 THEN 254097  -- [A] Woodcleaving Axe
  WHEN 254405 THEN 254098  -- [A] Cylla's Endless Potion
  WHEN 254410 THEN 254099  -- [A] Drape of the Lost
  WHEN 254411 THEN 254100  -- [A] Fallen Glaive
  WHEN 254412 THEN 254101  -- [A] Arcane Tome
  WHEN 254413 THEN 1010201  -- [A] Bag of Folding
  WHEN 254414 THEN 4  -- [A] Apprentice's Wardrobe
  WHEN 254415 THEN 1018771  -- [A] Ursolan Totem
  WHEN 254416 THEN 1033263  -- [A] Woven Legashi Basket
  WHEN 254417 THEN 254102  -- [A] Experimental Boots
  WHEN 254418 THEN 254103  -- [A] Bloody Knife
  WHEN 254419 THEN 644  -- [A] Legashi Equipment
  WHEN 254420 THEN 1014722  -- [A] Stargazer
  WHEN 254425 THEN 86069  -- [A] Heavy Furbolg Basket
  WHEN 254429 THEN 515460  -- [A] Eldara's Lyre
  WHEN 254430 THEN 254104  -- [A] The Wrath of Arkkoroc
  WHEN 254434 THEN 1070109  -- [A] Glinting Signet Stone
  WHEN 254436 THEN 279  -- [A] Spitelash Supply Barrel
  WHEN 254437 THEN 254105  -- [A] Advanced Pirate Medical Device
  WHEN 254438 THEN 88648  -- [A] Buried Cage
  WHEN 254439 THEN 1022590  -- [A] Cilkeck's Toolbox
  WHEN 254442 THEN 1074163  -- [A] Beached Necklace
  WHEN 254443 THEN 254107  -- [A] Fel Hunter's Spike
  WHEN 254444 THEN 254108  -- [A] Shed Hydra Scales
  WHEN 254446 THEN 254110  -- [A] Old Shell
  WHEN 254448 THEN 254111  -- [A] Giant's Storm Dagger
  WHEN 254449 THEN 254112  -- [A] Reclaimed Circlet
  WHEN 254450 THEN 254113  -- [A] Draconic Wand
  WHEN 254453 THEN 254114  -- [A] Crystalized Shield
  WHEN 254455 THEN 1015946  -- [A] Ancient Ring
  WHEN 254456 THEN 1074163  -- [A] Might of Azshara
  WHEN 254457 THEN 1009733  -- [A] Glowing Shard
  WHEN 254458 THEN 254115  -- [A] Pinned Crossbow
  WHEN 254459 THEN 254116  -- [A] Shoulderguards of Zin-Malor
  WHEN 254462 THEN 254118  -- [A] Bare Shoes
  WHEN 254463 THEN 254119  -- [A] Warbanner
  WHEN 254464 THEN 63518  -- [A] Offering
  WHEN 254465 THEN 254120  -- [A] Ruin Excavator
  WHEN 254466 THEN 254121  -- [A] Stuck Hammer
  WHEN 254467 THEN 254122  -- [A] Moonwashed Bow
  WHEN 254468 THEN 515448  -- [A] Duke's Staff
  WHEN 254471 THEN 254125  -- [A] Lion's Claws
  WHEN 254472 THEN 254124  -- [A] Buried Statue
  WHEN 254473 THEN 4431  -- [A] Peter's Prototype Pattern
  WHEN 254474 THEN 7631  -- [A] Repository of Eldara
  WHEN 254480 THEN 254127  -- [A] Vuna'thell
  WHEN 254484 THEN 188487  -- [A] Hexed Staff
  WHEN 254486 THEN 254128  -- [A] Wine Bottle
  WHEN 254488 THEN 254129  -- [A] Shining Wand
  WHEN 254489 THEN 254130  -- [A] Intact Boots
  WHEN 254491 THEN 254132  -- [A] Cursed Branch
  WHEN 254492 THEN 254133  -- [C] Long-Abandoned Circlet
  WHEN 254493 THEN 500025  -- [A] Foreboding Banner
  WHEN 254494 THEN 254135  -- [A] Dark Scythe
  WHEN 254495 THEN 1070109  -- [K] Memento Ring
  WHEN 254496 THEN 1016156  -- [A] Blood-soaked Bag
  WHEN 254497 THEN 254136  -- [A] Ogrish Handaxe
  WHEN 254498 THEN 7526  -- [A] Cellar Rubble
  WHEN 254499 THEN 1036371  -- [A] Shelf of Recipes
  WHEN 254502 THEN 4431  -- [A] Ancient Formula
  WHEN 254503 THEN 254138  -- [A] Coalescence of Agony
  WHEN 254504 THEN 254139  -- [A] Plundered Shipment
  WHEN 254505 THEN 254140  -- [A] Fallen Hero's Shield
  WHEN 254506 THEN 1070109  -- [K] Reverent Ring
  WHEN 254507 THEN 1032915  -- [A] Venerable Necklace
  WHEN 254516 THEN 526674  -- [A] Fallen Traveler's Pauldrons
  WHEN 254518 THEN 254143  -- [A] Blade of the Faithful
  WHEN 254520 THEN 254144  -- [A] Stuck Sword
  WHEN 254521 THEN 254146  -- [A] Aloof Tauren's Herbs
  WHEN 254522 THEN 254147  -- [C] Cord of Reverence
  WHEN 254539 THEN 254189  -- [A] Gnollish Shoulderpad
  WHEN 254540 THEN 254190  -- [A] Gnollish Headwear
  WHEN 254541 THEN 254191  -- [A] Web-Covered Belt
  WHEN 254542 THEN 259  -- [A] Stonewatch Chest
  WHEN 254543 THEN 254192  -- [A] Tharil'zun's Extra Boots
  WHEN 254544 THEN 254193  -- [A] Redwood Buckler
  WHEN 254545 THEN 254194  -- [A] Gnollish Sword
  WHEN 254546 THEN 254195  -- [A] Sunken Claymore
  WHEN 254547 THEN 254196  -- [A] Lost Axe
  WHEN 254548 THEN 254197  -- [A] Capsized Rifle
  WHEN 254549 THEN 378  -- [A] Cocooned Adventurer
  WHEN 254550 THEN 254198  -- [A] Improvised Murloc Hammer
  WHEN 254551 THEN 1128  -- [B] Free Book
  WHEN 254553 THEN 254200  -- [A] Wooden Staff
  WHEN 254554 THEN 85929  -- [A] Abandoned Totem
  WHEN 254555 THEN 254201  -- [A] Venture Co. Warning
  WHEN 254556 THEN 254202  -- [A] Silithid Scale
  WHEN 254557 THEN 254203  -- [A] Giant Gnomish Staff
  WHEN 254558 THEN 254204  -- [A] Fisherman's Longbow
  WHEN 254559 THEN 1  -- [K] Reverent of Earth
  WHEN 254560 THEN 254205  -- [A] Infused Staff
  WHEN 254561 THEN 254206  -- [A] Draenic Axe
  WHEN 254562 THEN 254207  -- [A] Crimson Blade
  WHEN 254563 THEN 254208  -- [A] Gnomish Shotgun
  WHEN 254564 THEN 254209  -- [A] Gore Covered Bow
  WHEN 254565 THEN 254210  -- [A] Ancient Wand
  WHEN 254571 THEN 63519  -- [A] Elven Necklace
  WHEN 254572 THEN 2350  -- [A] Highvale Scouting Supplies
  WHEN 254573 THEN 2450  -- [A] Sunken Stash
  WHEN 254574 THEN 1012699  -- [K] Fallen Hero
  WHEN 254575 THEN 254213  -- [A] Elven Shoulderpads
  WHEN 254577 THEN 254215  -- [A] Zazera's Wand
  WHEN 254578 THEN 254216  -- [A] Dire Maul Belt
  WHEN 254580 THEN 32  -- [A] Abandoned Barrel
  WHEN 254581 THEN 254217  -- [A] Runic Belt
  WHEN 254582 THEN 36  -- [A] Theramore Equipment
  WHEN 254583 THEN 254218  -- [A] Scorched Shoulders
  WHEN 254617 THEN 254238  -- [A] Corrupted Rifle
  WHEN 254618 THEN 254239  -- [A] Cracked Bow
  WHEN 254628 THEN 254245  -- [A] Wind Control Rod
  WHEN 254630 THEN 254247  -- [A] Satinka's Spare Slippers
  WHEN 254631 THEN 1034269  -- [A] Weaver's Baskets
  WHEN 254633 THEN 254249  -- [A] Shiny Hammer
  WHEN 254635 THEN 4093  -- [K] Lost Hero's Remains
  WHEN 254638 THEN 254252  -- [A] Everburning Draconic Claw
  WHEN 254639 THEN 1018771  -- [K] Black Dragon Totem
  WHEN 254640 THEN 325  -- [C] Dragonflame Torch
  WHEN 254641 THEN 1868  -- [C] Dark Iron Supplies
  WHEN 254642 THEN 2611  -- [A] Fallen Dark Iron Soldier
  WHEN 254643 THEN 1868  -- [C] Stolen Crate
  WHEN 254644 THEN 526960  -- [A] Draconic Spire
  WHEN 254645 THEN 254256  -- [A] Stashed Shoulderpads
  WHEN 254647 THEN 254258  -- [A] Tattered Fabric
  WHEN 254648 THEN 254259  -- [A] Stolen Belt
  WHEN 254649 THEN 3311  -- [A] Blackened Object
  WHEN 254650 THEN 254260  -- [A] Ashen Shield
  WHEN 254652 THEN 254261  -- [A] Gavel of the Ruined Court
  WHEN 254653 THEN 254262  -- [A] Blackrock Greataxe
  WHEN 254654 THEN 254010  -- [A] Burnscorch Wand
  WHEN 254655 THEN 527037  -- [A] Dragonspawn Headguard
  WHEN 254656 THEN 7985  -- [A] Collector's Shelves
  WHEN 254657 THEN 6477  -- [A] Officer's Libram
  WHEN 254658 THEN 175631  -- [A] Obsidian Axe
  WHEN 254659 THEN 184349  -- [A] Forgewright's Scepter
  WHEN 254660 THEN 526223  -- [A] Taskmaster's Blade
  WHEN 254661 THEN 527180  -- [A] Moltengore Spaulders
  WHEN 254662 THEN 2350  -- [C] Warlock's Supplies
  WHEN 254663 THEN 179713  -- [A] Ritual Dagger
  WHEN 254664 THEN 526060  -- [A] Thar'zul's Staff
  WHEN 254665 THEN 336  -- [A] Dragon Handler's Equipment
  WHEN 254666 THEN 1009569  -- [A] Fragment of Bokk
  WHEN 254667 THEN 10  -- [A] Flamescale Equipment Cache
  WHEN 254668 THEN 1074163  -- [A] Flamescale Necklace
  WHEN 254669 THEN 1020358  -- [C] Old Ogre Relic
  WHEN 254676 THEN 526357  -- [A] Spare Bow
  WHEN 300010 THEN 526138  -- [A] Hunter's Knife
  WHEN 300011 THEN 5255  -- [A] Jack's Stash
  WHEN 300017 THEN 2770  -- [A] Blue Dragon Crystal
  WHEN 300028 THEN 100537  -- [A] Sticky Sabatons
  WHEN 324495 THEN 178211  -- [A] Skippy's Bone
  WHEN 324505 THEN 1009597  -- [A] Spiced Rum
  WHEN 324506 THEN 1009548  -- [A] Scarlet Blunderbuss
  WHEN 324507 THEN 100525  -- [A] Andorhal Manual
  WHEN 324509 THEN 63517  -- [C] Wraithbone Ring
  WHEN 324510 THEN 1029891  -- [A] Libram of Remembrance
  WHEN 340042 THEN 8437  -- [A] Corrupted Flower
  WHEN 340043 THEN 10  -- [A] Morvanth's Chest
  WHEN 340044 THEN 1074449  -- [A] Empty Sack
  WHEN 340047 THEN 8  -- [A] Garmet Supplies
  WHEN 340053 THEN 515461  -- [A] Northridge Hatchet
  WHEN 340061 THEN 526232  -- [A] Scarlet Knight Sword
  WHEN 340066 THEN 1074163  -- [K] Scarlet Band
  WHEN 340068 THEN 515311  -- [A] Flayer's Helmet
  WHEN 340098 THEN 515252  -- [A] Skeletal Club
  WHEN 340099 THEN 1027445  -- [A] Lost Scout's Idol
  WHEN 340110 THEN 515182  -- [A] Shimmering Scarlet Cane
  WHEN 340111 THEN 526109  -- [A] Reliever's Burden
  WHEN 340112 THEN 7118  -- [A] Phylactery Shard
  WHEN 340113 THEN 515479  -- [A] Scarlet Shield
  WHEN 340114 THEN 515467  -- [A] Brightflame Codex
  WHEN 340115 THEN 6396  -- [A] Fishing Box
  WHEN 340116 THEN 287  -- [C] Scarlet Supplies
  WHEN 340117 THEN 934240  -- [A] Plague Mask
  WHEN 340118 THEN 515660  -- [A] Abomination Hook
  WHEN 340120 THEN 526858  -- [A] Charred Slicer
  WHEN 340122 THEN 527364  -- [A] Graveyard Striker
  WHEN 340123 THEN 515661  -- [A] Ebonblight Slippers
  WHEN 340125 THEN 527097  -- [A] Tracker's Plagued Spike
  WHEN 340126 THEN 515468  -- [A] Sentinel Sharpshooter
  WHEN 340127 THEN 515469  -- [A] Burning Judgement
  WHEN 340132 THEN 515481  -- [A] Bonescourge Dagger
  WHEN 341060 THEN 335  -- [A] Infantry Equipment
  WHEN 356431 THEN 527843  -- [A] Fetid Blade
  WHEN 356432 THEN 285  -- [A] Twilight Post Supplies
  WHEN 356433 THEN 515473  -- [A] Fallen Blunderbuss
  WHEN 356434 THEN 1060403  -- [A] Rock Stalker Egg Sacks
  WHEN 356435 THEN 175766  -- [A] Sandstone Sniper
  WHEN 356436 THEN 527094  -- [A] Standard Cenarion Spear
  WHEN 356439 THEN 63520  -- [A] Frozen Pendant
  WHEN 356440 THEN 527098  -- [A] Chillbane Cleaver
  WHEN 356443 THEN 515477  -- [A] Climbing Pick
  WHEN 357440 THEN 1010204  -- [A] Maddening Satchel
  WHEN 375003 THEN 1015490  -- [A] Expedition Satchel
  WHEN 375005 THEN 527707  -- [A] The Leaping Arc
  WHEN 375024 THEN 1018935  -- [A] Sinter Wive's Rope
  WHEN 375131 THEN 4031  -- [A] Tundrid Supply Cabinet
  WHEN 375231 THEN 1032277  -- [A] Box of Smoke Bombs
  WHEN 375327 THEN 1032148  -- [A] Stormscale Supplies
  WHEN 387849 THEN 1036633  -- [A] Kodo Supplies
  WHEN 387850 THEN 6396  -- [A] Fishing Box
  WHEN 387852 THEN 1046130  -- [A] Mercenary Camp Supplies
  WHEN 387854 THEN 5744  -- [A] Hunter's Lockbox
  WHEN 387866 THEN 1013567  -- [A] Blue Crystal Powder
  WHEN 387867 THEN 515511  -- [A] Raptor-Gnawed Cap
  WHEN 387868 THEN 7176  -- [A] Wilted Plant
  WHEN 387869 THEN 500028  -- [A] Arakor Mace
  WHEN 387870 THEN 515433  -- [A] Old Dragon Bone
  WHEN 387872 THEN 515513  -- [A] Thelsamar Bow
  WHEN 387875 THEN 515514  -- [A] Swiftgear Sniper
  WHEN 387876 THEN 515515  -- [A] Pilfered Stormpike Polearm
  WHEN 387877 THEN 515516  -- [A] Dark Iron Harvester
  WHEN 387878 THEN 515517  -- [A] Dragonmaw Ritual Staff
  WHEN 387880 THEN 1033507  -- [C] Crude Bluegill Totem
  WHEN 387881 THEN 1011043  -- [A] Borrowed Dark Iron Signet
  WHEN 387882 THEN 515518  -- [A] Old Dragonmaw Cleaver
  WHEN 515039 THEN 515039  -- [A] Hunter's Rifle
  WHEN 515089 THEN 515089  -- [A] Old Family Broom
  WHEN 515224 THEN 515224  -- [A] Misplaced Pitchfork
  WHEN 515259 THEN 515259  -- [C] Glass Bottle on the Shore
  WHEN 515345 THEN 515345  -- [A] Wheel
  WHEN 515362 THEN 515362  -- [A] Shoddy Blade
  WHEN 515365 THEN 10  -- [A] Chest
  WHEN 515366 THEN 1  -- [A] Hidden Chest
  WHEN 515367 THEN 254178  -- [A] Deathstalker Cape
  WHEN 515368 THEN 1074163  -- [K] Forsaken Stone Braid
  WHEN 515369 THEN 100514  -- [A] Forgotten Shovel
  WHEN 515370 THEN 4  -- [A] Agamand Dresser
  WHEN 515372 THEN 515176  -- [A] Ceremonial Mace
  WHEN 515373 THEN 7509  -- [C] Cracked Stone Golemn
  WHEN 515375 THEN 112  -- [A] Sealed Barrel
  WHEN 515376 THEN 9170  -- [A] Dusty Trousers
  WHEN 515377 THEN 63520  -- [C] Old Insignia
  WHEN 515378 THEN 5744  -- [A] Blackwood Chest
  WHEN 515379 THEN 515009  -- [A] Turtle Shell
  WHEN 515380 THEN 515049  -- [A] Ancient Shield
  WHEN 515383 THEN 515102  -- [A] Heavy Shovel
  WHEN 515384 THEN 515186  -- [A] Crude Effigy
  WHEN 515385 THEN 515212  -- [A] Deadman's Dagger
  WHEN 515386 THEN 515222  -- [A] Eroded Pit Fighter Knuckles
  WHEN 515387 THEN 7309  -- [A] Frayed Cuffs
  WHEN 515388 THEN 1009892  -- [A] Small War Drum
  WHEN 515390 THEN 300130  -- [A] Mysterious Mushroom
  WHEN 515392 THEN 1010931  -- [A] Agamand Walking Stick
  WHEN 515394 THEN 1014587  -- [C] Gnawed Remains
  WHEN 515395 THEN 500008  -- [A] Blackwood Torch
  WHEN 515396 THEN 1030581  -- [A] Waterlogged Driftwood
  WHEN 515397 THEN 1018646  -- [A] Cursed Blade
  WHEN 515398 THEN 1034677  -- [B] Dusty Tome
  WHEN 515400 THEN 500007  -- [A] Dusted Sword
  WHEN 515402 THEN 1044507  -- [A] Faded Scroll
  WHEN 515403 THEN 515284  -- [A] Foreman's Lightcap
  WHEN 515404 THEN 1051452  -- [A] Shipwreck Crate
  WHEN 515405 THEN 1053885  -- [A] Floating Barrel
  WHEN 515406 THEN 1015122  -- [A] Nightweb Spider Egg
  WHEN 515407 THEN 515347  -- [A] Old Ship Wheel
  WHEN 515408 THEN 1059297  -- [A] Sturdy Flora
  WHEN 515409 THEN 1025121  -- [A] Moonkin Nest
  WHEN 515425 THEN 515255  -- [A] Nightsong Waraxe
  WHEN 515428 THEN 1014547  -- [D] Herbalist's Stash
  WHEN 515429 THEN 1019417  -- [A] Torn Spellbook Page
  WHEN 515430 THEN 6749  -- [C] Arlithrien Moon Orb
  WHEN 515431 THEN 254165  -- [A] Lunar Tome
  WHEN 515432 THEN 254166  -- [A] Whisperwind's Wayfinders
  WHEN 515433 THEN 515147  -- [A] Timberling Ritual Blade
  WHEN 515434 THEN 515092  -- [A] Celestial Edge of Starfall
  WHEN 515435 THEN 515110  -- [A] Submerged Crescent Blade
  WHEN 515436 THEN 1032915  -- [C] Heirloom of the Whisperwind
  WHEN 515437 THEN 515118  -- [A] Timberbane's Old Hatchet
  WHEN 515438 THEN 515087  -- [A] Ritual Blade
  WHEN 515439 THEN 254167  -- [A] Herbalist's Cane
  WHEN 515440 THEN 500013  -- [A] Ierie Broadsword
  WHEN 515441 THEN 515162  -- [A] Abandoned Fishing Rod
  WHEN 515442 THEN 515123  -- [A] Hammer of the Earthshaper
  WHEN 515443 THEN 1034271  -- [C] Bundle of Dried Corn
  WHEN 515444 THEN 515191  -- [A] Dirge of the Dead
  WHEN 515466 THEN 515371  -- [A] Ladel
  WHEN 515470 THEN 515375  -- [A] Humming Blade
  WHEN 515502 THEN 1012986  -- [A] Tattered Remains
  WHEN 515503 THEN 515061  -- [A] Forgotten Pauldron
  WHEN 515504 THEN 515189  -- [A] Grimtotem Blade
  WHEN 515505 THEN 515199  -- [A] Rusty Hatchet
  WHEN 515506 THEN 515262  -- [A] Galak Smasher
  WHEN 515508 THEN 63519  -- [A] Frayed Cord
  WHEN 515509 THEN 1017935  -- [C] Strange Trinket
  WHEN 515510 THEN 63516  -- [C] Deadman's Signet
  WHEN 515511 THEN 63518  -- [A] Drowned Diver's Signet
  WHEN 515512 THEN 515367  -- [A] Grimtotem Skull Smasher
  WHEN 515513 THEN 515368  -- [A] Galak Shortbow
  WHEN 515514 THEN 190211  -- [A] Cursed Scepter
  WHEN 515515 THEN 1014589  -- [C] Gnawed Kodo Bone
  WHEN 515516 THEN 1029781  -- [C] Darkcloud Totem
  WHEN 515517 THEN 1015578  -- [C] Highlands Chest
  WHEN 515518 THEN 259  -- [A] Caravaner's Chest
  WHEN 515519 THEN 1027359  -- [A] Stray Pack Kodo Satchel
  WHEN 515520 THEN 1069362  -- [A] Cloud Serpent Feather
  WHEN 515524 THEN 515132  -- [A] Scuba Slayer's Blade
  WHEN 515525 THEN 515287  -- [A] Drowned Diver's Helmet
  WHEN 515528 THEN 5744  -- [A] Tahonda Chest
  WHEN 515529 THEN 259  -- [A] Pirate's Booty
  WHEN 515530 THEN 515259  -- [A] Abandoned Moonshine
  WHEN 515531 THEN 7822  -- [A] Radiating Green Stone
  WHEN 515532 THEN 9170  -- [A] Abandoned Trousers
  WHEN 515533 THEN 7533  -- [A] Leftover Kodo War Drum
  WHEN 515534 THEN 515032  -- [A] Silithid Wall Creeper
  WHEN 515535 THEN 515044  -- [A] Rickety Invention
  WHEN 515536 THEN 515188  -- [A] Runway Scraper
  WHEN 515537 THEN 515283  -- [A] Racing Goggles
  WHEN 515539 THEN 515369  -- [A] Rustmaul Artifact
  WHEN 515540 THEN 254179  -- [A] Racing Boots
  WHEN 515542 THEN 237  -- [A] Sizzling Bottle
  WHEN 515571 THEN 515370  -- [A] Harpy Feather
  WHEN 515596 THEN 515374  -- [A] Dangerously Loose Machine Part
  WHEN 515598 THEN 1046354  -- [C] Charm
  WHEN 515600 THEN 515276  -- [A] Lazy Hat
  WHEN 515613 THEN 1029671  -- [A] Shimmer Dust
  WHEN 515723 THEN 1042250  -- [A] Hidden Cache
  WHEN 515727 THEN 1049249  -- [A] Lost Southsea Loot
  WHEN 515738 THEN 1010314  -- [C] Goblin Cache
  WHEN 515739 THEN 515383  -- [A] Warlord's Blade
  WHEN 515740 THEN 515384  -- [A] Time Stream Slasher
  WHEN 515741 THEN 515206  -- [A] Ancient Horde Blade
  WHEN 515742 THEN 10  -- [A] Alchemist Cache
  WHEN 515743 THEN 515136  -- [A] Betrayer's Blade
  WHEN 515744 THEN 7310  -- [A] Dead Adventurer
  WHEN 515745 THEN 1072314  -- [A] Deadman Gauntlets
  WHEN 515747 THEN 1072391  -- [A] Disturbed Sand
  WHEN 515748 THEN 1049754  -- [A] Sand Cover
  WHEN 515750 THEN 515068  -- [A] Watcher's Mantle
  WHEN 515755 THEN 138103  -- [A] Lost Treasure
  WHEN 515764 THEN 515310  -- [A] Tender's Hat
  WHEN 515767 THEN 1009690  -- [A] Ritual Horn
  WHEN 515769 THEN 515385  -- [A] Qiraji-Touched Tool
  WHEN 515770 THEN 515386  -- [A] Sturdy Coffin Lid
  WHEN 515771 THEN 1070109  -- [A] Damp Ring
  WHEN 515772 THEN 7635  -- [A] Dunemaul Crate
  WHEN 515773 THEN 1072391  -- [A] Disturbed Sand Pile
  WHEN 515775 THEN 515156  -- [A] Carapace Carver
  WHEN 515781 THEN 515387  -- [A] Hazzali Silithid Antenna
  WHEN 515782 THEN 515388  -- [A] Last Stand
  WHEN 515783 THEN 84953  -- [A] Odd Silithid Larva
  WHEN 515791 THEN 515389  -- [A] Ancient Wagon Wheel
  WHEN 515797 THEN 1074163  -- [A] Sun Ritual Necklace
  WHEN 515798 THEN 7637  -- [A] Abandoned Trader Crate
  WHEN 515800 THEN 1044843  -- [A] Ancient Elven Chest
  WHEN 515801 THEN 515390  -- [A] The Wingman
  WHEN 515822 THEN 1019305  -- [A] Loose Barrel
  WHEN 515823 THEN 515213  -- [A] Winkey's Misplaced Wrench
  WHEN 515824 THEN 515391  -- [A] Water Binder
  WHEN 515825 THEN 4192  -- [A] Southsea Chest
  WHEN 515826 THEN 1016172  -- [A] Pilfered Backpack
  WHEN 515827 THEN 515392  -- [A] Wooden Plank
  WHEN 515828 THEN 1048480  -- [A] Captain's Compass
  WHEN 515829 THEN 31  -- [A] Pilfered Crate
  WHEN 515830 THEN 1072391  -- [A] Shallow Grave
  WHEN 515834 THEN 63518  -- [A] Fisher's Misfortune
  WHEN 515835 THEN 515393  -- [A] Magnify Glass
  WHEN 515836 THEN 515394  -- [A] Noon's Shade Relic
  WHEN 515837 THEN 1  -- [A] Desert Cache
  WHEN 515838 THEN 515208  -- [A] Dunemaul Champion Hammer
  WHEN 515839 THEN 515309  -- [A] Stylish Racing Hat
  WHEN 515840 THEN 515396  -- [A] Sandfury Ritual Mace
  WHEN 515841 THEN 515397  -- [A] Sandfury Boomerang
  WHEN 515842 THEN 515398  -- [A] Sorrow Bolter
  WHEN 515843 THEN 1010146  -- [A] Southmoon Amulet
  WHEN 515844 THEN 515399  -- [A] Ravenwind Codex
  WHEN 515845 THEN 515400  -- [A] Seamstress Scissors
  WHEN 515846 THEN 515401  -- [A] Shen'dralar Staff
  WHEN 515849 THEN 515402  -- [A] Gnoll-Gnawed Bone Bat
  WHEN 515853 THEN 1018771  -- [A] Grim Totem
  WHEN 515863 THEN 515403  -- [A] Huntress Bow
  WHEN 515864 THEN 515347  -- [A] Old Ship Wheel
  WHEN 515865 THEN 1057305  -- [A] Dormant Dreamscale
  WHEN 515866 THEN 1015414  -- [A] Gregan Tanning Rack
  WHEN 515867 THEN 177562  -- [D] Lodged Artifact
  WHEN 515877 THEN 515404  -- [A] Giant Stalker Rifle
  WHEN 515878 THEN 515405  -- [A] Zorbin's Backup Wrench
  WHEN 515880 THEN 515406  -- [A] Fallen's Sword
  WHEN 515884 THEN 515407  -- [A] Highborne Wand
  WHEN 515887 THEN 515408  -- [A] Shattered Highborne Blade
  WHEN 515900 THEN 5743  -- [A] Sandy Chest
  WHEN 515901 THEN 515031  -- [A] Buried Wood
  WHEN 515902 THEN 31  -- [A] Stolen Caravan Crate
  WHEN 515903 THEN 515211  -- [A] High Seas Axe
  WHEN 515904 THEN 515409  -- [A] Unfortunate Shoulderpad
  WHEN 515906 THEN 515410  -- [A] Executioner's Axe
  WHEN 515909 THEN 515411  -- [A] Dunecaller's Spire
  WHEN 515910 THEN 1032915  -- [A] High Cascade Cord
  WHEN 515916 THEN 515412  -- [A] Desperate Defense
  WHEN 515918 THEN 515413  -- [A] Tiki Shield
  WHEN 515919 THEN 31  -- [A] Abandoned Crate
  WHEN 515920 THEN 515414  -- [A] Raptor Talon
  WHEN 515921 THEN 515415  -- [A] Emberstring Drakebow
  WHEN 515922 THEN 515416  -- [A] Humming Bone
  WHEN 515923 THEN 1067435  -- [A] Emberheart Talisman
  WHEN 515941 THEN 515417  -- [A] Emberscale Greatsword
  WHEN 515942 THEN 1031225  -- [A] Emberheart Talisman
  WHEN 515943 THEN 300030  -- [A] Shipwreck Barrel
  WHEN 515944 THEN 1017937  -- [A] Ogre Supply Crate
  WHEN 515945 THEN 336  -- [A] Waterlogged Crate
  WHEN 515946 THEN 515209  -- [A] Shipwreck Axe
  WHEN 515947 THEN 1036633  -- [A] Tauren Crate
  WHEN 515948 THEN 20  -- [A] Shallow Grave
  WHEN 515949 THEN 7554  -- [B] Evil Jewel
  WHEN 515950 THEN 515418  -- [A] Primitive Murloc Skewer
  WHEN 515951 THEN 1048164  -- [A] Relic of Grim Wrath
  WHEN 515952 THEN 1074449  -- [A] Durn's Loot Bag
  WHEN 515958 THEN 515420  -- [A] Secluded Soothsayer's Pipes
  WHEN 517202 THEN 515240  -- [A] Ror's Chopper
  WHEN 517204 THEN 1055729  -- [A] Small Emerald
  WHEN 517210 THEN 515433  -- [A] Jadefire Bone Hatchet
  WHEN 517223 THEN 515434  -- [A] Minstrel's Banjo
  WHEN 517224 THEN 1  -- [A] Drowned Chest
  WHEN 517225 THEN 185850  -- [A] Jadefire Piercer
  WHEN 517232 THEN 179796  -- [A] Felhound Corpse
  WHEN 517233 THEN 7410  -- [A] Fel Cauldron
  WHEN 517234 THEN 180729  -- [A] Silverhand Spaulder
  WHEN 517235 THEN 515435  -- [A] Demonic Portal
  WHEN 517237 THEN 515436  -- [A] Jaednar Spire
  WHEN 517242 THEN 1009597  -- [A] Shimmering Bottle
  WHEN 517254 THEN 1018853  -- [A] Tattered Cloth
  WHEN 517257 THEN 644  -- [A] Satyr Basket
  WHEN 517261 THEN 179783  -- [A] Old Blade
  WHEN 517263 THEN 1288  -- [A] Reinforced Helmet
  WHEN 517271 THEN 515446  -- [A] Talonbranch Sweeper
  WHEN 517272 THEN 7410  -- [A] Bubbling Cauldron
  WHEN 517273 THEN 515439  -- [A] Timbermaw Defender
  WHEN 517274 THEN 1036633  -- [A] Timbermaw Cache
  WHEN 517275 THEN 515440  -- [A] Acid Bolter
  WHEN 517276 THEN 515189  -- [A] Embedded Claymore
  WHEN 517277 THEN 515441  -- [A] Rotwood Rapier
  WHEN 517295 THEN 515442  -- [A] Discharged Sawblade
  WHEN 517314 THEN 515520  -- [A] Old Shoulderpad
  WHEN 517316 THEN 31  -- [A] Old Crate
  WHEN 517317 THEN 515522  -- [A] Syndicate Boots
  WHEN 517322 THEN 515205  -- [A] Alder's Axe
  WHEN 517323 THEN 254129  -- [A] Siren's Wand
  WHEN 517324 THEN 515523  -- [A] Old Slippers
  WHEN 517325 THEN 9  -- [A] Broken Barrel
  WHEN 517330 THEN 6434  -- [A] Floating Debris
  WHEN 517331 THEN 515505  -- [A] Dwarven Hatchet
  WHEN 517336 THEN 1015383  -- [A] Caravan Barrel
  WHEN 517338 THEN 515062  -- [A] Muddy Shoulderpad
  WHEN 517340 THEN 31  -- [A] Trogg Crate
  WHEN 517341 THEN 31  -- [A] Storage Crate
  WHEN 517342 THEN 515524  -- [A] Vermin Cane
  WHEN 517347 THEN 1  -- [A] Edwin's Chest
  WHEN 517349 THEN 515528  -- [A] Barnaby's Booties
  WHEN 517351 THEN 175795  -- [A] Old Crossbow
  WHEN 517352 THEN 336  -- [A] Forsaken Cart Crate
  WHEN 517353 THEN 178507  -- [A] Rusty Shotgun
  WHEN 517354 THEN 20  -- [A] Shallow Grave
  WHEN 517356 THEN 515041  -- [A] Old Buckler
  WHEN 517357 THEN 5732  -- [A] Mauled Skeleton
  WHEN 517359 THEN 31  -- [A] Stolen Cargo
  WHEN 517364 THEN 20  -- [A] Loose Dirt
  WHEN 517366 THEN 515529  -- [A] Traveling Cloth
  WHEN 517367 THEN 1  -- [A] Offering For the Dead
  WHEN 517368 THEN 41  -- [K] Broken Rattlecage
  WHEN 517370 THEN 1074163  -- [K] Champion's Band
  WHEN 517371 THEN 1036633  -- [A] Wyvern Cache
  WHEN 518000 THEN 178796  -- [A] The Rock Binder
  WHEN 518006 THEN 6396  -- [A] Box of Safety Equipment
  WHEN 518007 THEN 3691  -- [C] Spark of Infernus
  WHEN 518009 THEN 1009548  -- [A] Shadowforge Shotgun
  WHEN 518010 THEN 522  -- [A] Shadowforged Deflector
  WHEN 518011 THEN 178806  -- [A] Awkwardly Placed Hammer
  WHEN 518016 THEN 254056  -- [A] Blood Covered Helm
  WHEN 518018 THEN 63520  -- [C] Blood Covered Metal
  WHEN 518030 THEN 178217  -- [A] Real Big Bone
  WHEN 518045 THEN 1  -- [A] Gareks Personal Belongings
  WHEN 518048 THEN 515063  -- [A] Throkaf's Project
  WHEN 518050 THEN 31  -- [C] Stolen Goods
  WHEN 518051 THEN 254081  -- [A] Lit Lantern
  WHEN 518052 THEN 188896  -- [A] Gravesword
  WHEN 518053 THEN 1033131  -- [A] Ramshackled Crate
  WHEN 518054 THEN 1044173  -- [A] Ancient Relic
  WHEN 518055 THEN 31  -- [C] Extra Crate
  WHEN 518060 THEN 1016155  -- [A] Tattered Sack
  WHEN 518063 THEN 185518  -- [A] Ogre Fire Poker
  WHEN 518079 THEN 1015242  -- [C] Druidic Stone
  WHEN 518082 THEN 5511  -- [A] Stolen Goods
  WHEN 518086 THEN 10  -- [A] Half Buried Chest
  WHEN 518087 THEN 175319  -- [A] Ogre Throwing Axe
  WHEN 518097 THEN 179698  -- [A] Warning Dagger
  WHEN 518098 THEN 190151  -- [A] Scorched Knife
  WHEN 518099 THEN 515304  -- [A] Barbarian King's Circlet
  WHEN 518100 THEN 1387  -- [C] Precarious Treasure
  WHEN 518102 THEN 515368  -- [A] Windhorn Longbow
  WHEN 518123 THEN 515323  -- [A] Strange Helm
  WHEN 518135 THEN 1027535  -- [C] Accumulated Moonlight
  WHEN 518139 THEN 5258  -- [A] Mordant Grimsby's Unwanted Gift
  WHEN 518140 THEN 352  -- [A] Sturdy Coffin Lid
  WHEN 518144 THEN 515422  -- [A] Blackhoof Warmaul
  WHEN 518147 THEN 190341  -- [A] Missing Apprentice Wand
  WHEN 518149 THEN 1015126  -- [A] Darkmist Widow's Previous Meal
  WHEN 518153 THEN 1074449  -- [A] Mudcrush's Stolen Goods
  WHEN 518162 THEN 1066612  -- [A] Weathered Amulet
  WHEN 518166 THEN 515658  -- [A] Eternal Watcher's Log
  WHEN 518171 THEN 515382  -- [A] Twilight Infusion
  WHEN 518172 THEN 300131  -- [A] Discarded Belongings
  WHEN 518174 THEN 279  -- [A] Twilight Storage Barrel
  WHEN 518175 THEN 1054483  -- [C] Heavy Fur
  WHEN 518300 THEN 515525  -- [A] Twilight Drape
  WHEN 518301 THEN 6035  -- [A] Stolen Elf Crate
  WHEN 518302 THEN 2350  -- [A] Old Caravan Crate
  WHEN 518303 THEN 49  -- [A] Disturbed Dirt
  WHEN 518305 THEN 189067  -- [A] Teldrassil Skewer
  WHEN 518311 THEN 7539  -- [A] Lost Oasis Crate
  WHEN 518315 THEN 515532  -- [A] Red Mage Wand
  WHEN 518316 THEN 259  -- [A] Stolen Belongings
  WHEN 518317 THEN 515270  -- [A] Old Gilnean Lance
  WHEN 518318 THEN 515036  -- [A] Old Crossbow
  WHEN 518319 THEN 287  -- [A] Special Brewing Gear
  WHEN 518321 THEN 6448  -- [A] Westfall Supply Cache
  WHEN 518322 THEN 287  -- [A] Stolen Supplies
  WHEN 518342 THEN 32  -- [A] Old Theramore Barrel
  WHEN 518344 THEN 3791  -- [A] Broken Crate
  WHEN 518345 THEN 10  -- [A] Buried Chest
  WHEN 518346 THEN 1016156  -- [A] Dusty Sack
  WHEN 518348 THEN 515143  -- [A] Gnawed Stave
  WHEN 518354 THEN 1  -- [A] Scarlet Chest
  WHEN 518372 THEN 41  -- [B] Scarlet Chest
  WHEN 518456 THEN 1050391  -- [A] Hive Regal Idol
  WHEN 518457 THEN 1072391  -- [C] Draconian Relic Sediment
  WHEN 518460 THEN 526842  -- [A] Rough Longbow
  WHEN 518461 THEN 526253  -- [A] Twilight Stave
  WHEN 518462 THEN 526941  -- [A] Scorpion Scale
  WHEN 518464 THEN 2612  -- [K] Scorpion Corpse
  WHEN 518466 THEN 527430  -- [A] Lost Crossbow
  WHEN 518562 THEN 528603  -- [A] Frost Covered Crossbow
  WHEN 518564 THEN 526058  -- [A] Frozen Saber
  WHEN 518565 THEN 1074163  -- [K] Suffering Soul
  WHEN 518566 THEN 6035  -- [C] Night Elf Crate
  WHEN 518567 THEN 526363  -- [A] Dwarven Rifle
  WHEN 518568 THEN 529972  -- [A] Frostsaber Halberd
  WHEN 518569 THEN 1988  -- [A] Supply Cache
  WHEN 518572 THEN 2612  -- [K] Owlbeast Corpse
  WHEN 518573 THEN 31  -- [A] Crate
  WHEN 518574 THEN 526749  -- [A] Frozen Dagger
  WHEN 518575 THEN 323  -- [A] Stolen Supplies
  WHEN 518576 THEN 527976  -- [A] Frozen Mace
  WHEN 518577 THEN 515657  -- [A] Yeti Cave Cloak
  WHEN 518578 THEN 526635  -- [A] Scalebane Corpse
  WHEN 518579 THEN 31  -- [A] Dun Mandarr Crate
  WHEN 518580 THEN 6035  -- [C] Night Elf Crate
  WHEN 518582 THEN 526453  -- [A] Elven Bow
  WHEN 518583 THEN 526201  -- [A] Whizzpin's Sword
  WHEN 518584 THEN 527094  -- [A] Darkwhisper Spear
  WHEN 518586 THEN 526779  -- [A] Icy Blade
  WHEN 518678 THEN 41  -- [K] Dead Orc
  WHEN 518788 THEN 515544  -- [A] Trigdy's Pistol
  WHEN 518894 THEN 1  -- [B] Lost Gilnean Cache
  WHEN 520018 THEN 1014587  -- [A] Ancient Femur
  WHEN 520047 THEN 515022  -- [A] Decayed Sharpshot
  WHEN 520051 THEN 1018646  -- [K] Sturdy Arrow
  WHEN 520055 THEN 526115  -- [A] Oathblade
  WHEN 520062 THEN 352  -- [D] Casket Lid
  WHEN 520063 THEN 515676  -- [A] Scorched Tome
  WHEN 520064 THEN 526821  -- [A] Old Northshire Bolter
  WHEN 520065 THEN 20  -- [A] Disturbed Dirt
  WHEN 520066 THEN 515677  -- [A] Murloc Tool
  WHEN 520067 THEN 526730  -- [A] Carrion Eye
  WHEN 520068 THEN 515678  -- [A] Nest Thorn
  WHEN 520069 THEN 527980  -- [A] Disciple Bow
  WHEN 520071 THEN 188302  -- [K] Vulture Effigy
  WHEN 520072 THEN 515681  -- [A] Ancient Battleaxe
  WHEN 520073 THEN 526880  -- [A] Radiant Rifle
  WHEN 520696 THEN 515413  -- [A] Dropped Shield
  WHEN 520697 THEN 515412  -- [A] Loose Palisade
  WHEN 520698 THEN 1043082  -- [A] Ancient Jar
  WHEN 520699 THEN 526402  -- [A] Grimtotem Bow
  WHEN 520700 THEN 526016  -- [A] Grimtotem Club
  WHEN 520701 THEN 1  -- [A] Traitor Chest
  WHEN 520702 THEN 279  -- [A] Loose Barrel
  WHEN 520703 THEN 515679  -- [A] Rocket Shrapnel
  WHEN 520704 THEN 515680  -- [A] Radiant Helmet
  WHEN 638836 THEN 515542  -- [A] Darnell's Blade
  WHEN 654637 THEN 1011020  -- [A] Draconic Chest
  WHEN 686868 THEN 515477  -- [A] Excavator's Pick
  WHEN 686869 THEN 24  -- [A] Dustsworn Sash
  WHEN 686871 THEN 515543  -- [A] Infested Pauldrons
  WHEN 686877 THEN 515547  -- [A] Scarab Smasher
  WHEN 686878 THEN 515548  -- [A] Twilight's Presence
  WHEN 686879 THEN 63518  -- [C] Geo Band
  WHEN 686880 THEN 515549  -- [A] Cursed Ritual Carver
  WHEN 686881 THEN 1066265  -- [C] Wind Pendant
  WHEN 686882 THEN 2612  -- [K] Fresh Hive'Ashi Corpse
  WHEN 686883 THEN 1013843  -- [K] Lost Supplies
  WHEN 686885 THEN 241  -- [K] Hardened Scarab Gauntlets
  WHEN 686887 THEN 515550  -- [A] Soldier's Bulwark
  WHEN 686888 THEN 515551  -- [A] Sandstorm Shaper
  WHEN 686889 THEN 515553  -- [A] Radiating Charred Branch
  WHEN 686891 THEN 515554  -- [A] Extremely Hot Poker
  WHEN 686898 THEN 515556  -- [A] Blackbreach Handaxe
  WHEN 686899 THEN 515490  -- [A] Sulfurspike Hatchet
  WHEN 686900 THEN 1  -- [K] Madness Cowl
  WHEN 686902 THEN 1074163  -- [K] Glinting Metal
  WHEN 686906 THEN 515559  -- [A] Hellforge Shortsword
  WHEN 686907 THEN 515560  -- [A] Incinerator Pike
  WHEN 686908 THEN 515217  -- [A] Pyrebloom Maul
  WHEN 686909 THEN 526361  -- [A] Charblaze Rifle
  WHEN 686913 THEN 527429  -- [A] Obsidian Boltthrower
  WHEN 686914 THEN 526779  -- [A] The Final Strike
  WHEN 686916 THEN 1074163  -- [K] Grave Offering
  WHEN 686918 THEN 515158  -- [A] Blackrock Shiv
  WHEN 686919 THEN 1016155  -- [A] Empty Ogre Loot Sack
  WHEN 686920 THEN 515501  -- [A] Lava Absorbing Blade
  WHEN 686922 THEN 500000  -- [A] Heatshimmer Cape
  WHEN 686930 THEN 1011043  -- [A] Free Sample
  WHEN 686933 THEN 1  -- [K] Cinderthread Sash
  WHEN 686934 THEN 1027  -- [K] Timbermaw Shrine
  WHEN 686935 THEN 526335  -- [A] Excavator's Buckler
  WHEN 686936 THEN 6830  -- [A] Windsong Totem
  WHEN 686937 THEN 1  -- [K] Glacierpaw Bindings
  WHEN 735901 THEN 100531  -- [K] Ghoul-Stitched Shoulders
  WHEN 735902 THEN 1047590  -- [A] Primitive Offering Box
  WHEN 735924 THEN 1016149  -- [A] Prancefin
  WHEN 836218 THEN 1010317  -- [A] Moonrest Supplies
  WHEN 1344099 THEN 87226  -- [A] Moss Picker's Pouch
  WHEN 1344800 THEN 63520  -- [C] Moonbathed Necklace
  WHEN 1344801 THEN 253  -- [A] Conspicuous Lily
  WHEN 1344802 THEN 1009892  -- [C] Well Worn Drum
  WHEN 1344803 THEN 130  -- [A] Eye-Catching Item Rack
  WHEN 1345000 THEN 1  -- [K] Affray Cuirras
  WHEN 1345001 THEN 335  -- [E] Alliance Cord
  WHEN 1345002 THEN 41  -- [K] Ancient Sentinel Headdress
  WHEN 1345003 THEN 100513  -- [K] Apothecary's Lantern
  WHEN 1345004 THEN 100513  -- [K] Apothecary's Lantern
  WHEN 1345005 THEN 100513  -- [K] Apothecary's Lantern
  WHEN 1345006 THEN 100513  -- [K] Apothecary's Lantern
  WHEN 1345007 THEN 187593  -- [K] Apprentice's Cane
  WHEN 1345008 THEN 9170  -- [K] Beezil's Pants
  WHEN 1345009 THEN 1074449  -- [K] Billy Bag
  WHEN 1345010 THEN 254226  -- [E] Blight Infused Mantle
  WHEN 1345011 THEN 1028909  -- [K] Bloodied Torn Bracers
  WHEN 1345012 THEN 95607  -- [E] Bloodmyst Totem
  WHEN 1345013 THEN 1  -- [K] Bloodtalon Vestments
  WHEN 1345014 THEN 1018771  -- [K] Bogcaller Totem
  WHEN 1345015 THEN 1018771  -- [K] Bogcaller Totem
  WHEN 1345016 THEN 175501  -- [K] Bonechopper
  WHEN 1345017 THEN 41  -- [K] Boulder Greaves
  WHEN 1345018 THEN 323  -- [K] Brackish Spellweave Robe
  WHEN 1345019 THEN 179755  -- [K] Bristleback Quill
  WHEN 1345020 THEN 1  -- [K] Celsalia's Luxorious Robes
  WHEN 1345021 THEN 41  -- [K] Chain Belt of the Elements
  WHEN 1345022 THEN 1074163  -- [K] Charstone Warband
  WHEN 1345023 THEN 1  -- [K] Cloak of Owlkin Feathers
  WHEN 1345024 THEN 7310  -- [E] Cloudchaser Pendant
  WHEN 1345025 THEN 1  -- [K] Coastline Vest
  WHEN 1345026 THEN 188568  -- [K] Contraband Magician Rod
  WHEN 1345027 THEN 100516  -- [K] Cryptfiend Fang
  WHEN 1345028 THEN 41  -- [K] Dakota Steppe Greaves
  WHEN 1345029 THEN 100554  -- [K] Dark Iron Scorcher
  WHEN 1345030 THEN 254237  -- [E] Darnassus Longbow
  WHEN 1345031 THEN 20900  -- [K] Deadcapitator
  WHEN 1345032 THEN 1074163  -- [K] Deadtooth
  WHEN 1345033 THEN 181101  -- [K] Deadweight Pauldrons
  WHEN 1345034 THEN 100523  -- [K] Deathwhisper Wand
  WHEN 1345035 THEN 254181  -- [E] Decayed Cape
  WHEN 1345036 THEN 179794  -- [K] Deepmoss Fang
  WHEN 1345037 THEN 1  -- [K] Defias Turncoat's Jerkin
  WHEN 1345038 THEN 1074163  -- [K] Deserter's Last Resort
  WHEN 1345039 THEN 254228  -- [E] Dreadscar Girdle
  WHEN 1345040 THEN 1074163  -- [K] Dripping Fang
  WHEN 1345041 THEN 184947  -- [K] Durnar's Stein
  WHEN 1345042 THEN 254187  -- [E] Duskwither Hatchet
  WHEN 1345043 THEN 189249  -- [K] Dustworn Saber
  WHEN 1345044 THEN 517034  -- [E] Dwarven Bucket
  WHEN 1345045 THEN 178184  -- [K] Dwarven Crossbow
  WHEN 1345046 THEN 100002  -- [K] Dwarven Demolition Kit
  WHEN 1345047 THEN 1  -- [K] Edan's Stripe
  WHEN 1345048 THEN 1010201  -- [K] Empty Satchel
  WHEN 1345049 THEN 3731  -- [E] Everyday Applications of Pyromancy
  WHEN 1345050 THEN 1058298  -- [E] Fallen Eye Jewel
  WHEN 1345051 THEN 6670  -- [E] Farstrider's Grips
  WHEN 1345052 THEN 644  -- [E] Feathered Pants
  WHEN 1345053 THEN 1  -- [K] Fine Silk Wraps
  WHEN 1345054 THEN 254240  -- [E] Fish Gutter
  WHEN 1345055 THEN 1  -- [K] Flattened Shoulderpad
  WHEN 1345056 THEN 1074163  -- [K] Fragment of K'aresh
  WHEN 1345057 THEN 1074163  -- [K] Fullmoon Howl
  WHEN 1345058 THEN 1012699  -- [K] Gauntlets of the Overlook
  WHEN 1345059 THEN 138105  -- [E] Ghostclaw Vest
  WHEN 1345060 THEN 41  -- [K] Girdle of the Shadowslayer
  WHEN 1345061 THEN 1012699  -- [K] Goldshire Traveler's Boots
  WHEN 1345062 THEN 41  -- [K] Gordunni Thumbtack
  WHEN 1345063 THEN 254156  -- [K] Grimson Cloak
  WHEN 1345064 THEN 184947  -- [K] Grunir's Mug
  WHEN 1345065 THEN 254156  -- [K] Gutspill Cloak
  WHEN 1345066 THEN 41  -- [K] Hammerfall Wristguards
  WHEN 1345067 THEN 184947  -- [K] Haren's Tankard
  WHEN 1345068 THEN 188673  -- [K] Harvest Golem Scythe
  WHEN 1345069 THEN 184835  -- [K] Haunted Bouquet
  WHEN 1345070 THEN 517033  -- [E] Highlands Kitchen Knife
  WHEN 1345071 THEN 180384  -- [K] Hive Regal Claw
  WHEN 1345072 THEN 1  -- [K] Huntress Threads
  WHEN 1345073 THEN 515265  -- [K] Hyjal Protector's Knuckleduster
  WHEN 1345074 THEN 254156  -- [K] Icehide Cloak
  WHEN 1345075 THEN 1074163  -- [K] Idol of the Brooding Shadow
  WHEN 1345076 THEN 1027445  -- [K] Idol of the Ocean's Depths
  WHEN 1345077 THEN 190359  -- [K] Infernal Tender
  WHEN 1345078 THEN 175617  -- [K] Ironhew's Spare Chopper
  WHEN 1345080 THEN 175871  -- [K] Junglewood Recurve
  WHEN 1345081 THEN 254087  -- [K] Kargan's Mask
  WHEN 1345082 THEN 2450  -- [E] Kel'gash's War Breeches
  WHEN 1345083 THEN 1029891  -- [K] Libram of Amphibious Devotion
  WHEN 1345084 THEN 184790  -- [K] Libram of Resolute Light
  WHEN 1345085 THEN 1074163  -- [K] Light of the Talondeep Path
  WHEN 1345086 THEN 1070109  -- [K] Loded Ring
  WHEN 1345087 THEN 1070109  -- [K] Loded Ring
  WHEN 1345088 THEN 1064914  -- [K] Lyrath's Pan Flute
  WHEN 1345089 THEN 1070109  -- [K] Melika's Ring
  WHEN 1345090 THEN 41  -- [K] Miner Handwraps
  WHEN 1345091 THEN 1074163  -- [K] Minervia's Pendant of Atonement
  WHEN 1345092 THEN 184947  -- [K] Morin's Jug
  WHEN 1345093 THEN 7737  -- [K] Mossy Hide Armor
  WHEN 1345094 THEN 515224  -- [K] Mrlrgrl Pitchfork
  WHEN 1345095 THEN 1074163  -- [K] Mystral Compass
  WHEN 1345096 THEN 254221  -- [E] Mystwood Glaive
  WHEN 1345097 THEN 41  -- [K] Northpoint Helmet
  WHEN 1345098 THEN 41  -- [K] Northpoint Helmet
  WHEN 1345099 THEN 343  -- [K] Notice of Urgent Delivery
  WHEN 1345100 THEN 343  -- [K] Notice of Urgent Delivery
  WHEN 1345101 THEN 63519  -- [K] Offering Pendant
  WHEN 1345102 THEN 1018853  -- [K] Ogre Cloth
  WHEN 1345103 THEN 323  -- [K] Old Arcanus Robe
  WHEN 1345104 THEN 1074163  -- [K] Owlbeast Talon
  WHEN 1345105 THEN 1074163  -- [K] Owlbeast Talon
  WHEN 1345106 THEN 176001  -- [K] Pilfered Bloodhoof Bow
  WHEN 1345107 THEN 177593  -- [K] Plague Purger
  WHEN 1345108 THEN 254013  -- [E] Prodigy's Staff
  WHEN 1345109 THEN 440  -- [C] Radley's Special Scope
  WHEN 1345110 THEN 440  -- [C] Radley's Special Scope
  WHEN 1345111 THEN 254098  -- [K] Recipe: Vi'el's Unstable Fel Potion
  WHEN 1345112 THEN 182759  -- [K] Red Metal Pauldrons
  WHEN 1345113 THEN 1074163  -- [K] Ribchaser's Loop
  WHEN 1345114 THEN 1074163  -- [K] Ring of Arakosh
  WHEN 1345115 THEN 1074163  -- [K] Ring of Embered Thought
  WHEN 1345116 THEN 1070109  -- [K] Rough Weathered Ring
  WHEN 1345117 THEN 1070109  -- [K] Rough Weathered Ring
  WHEN 1345118 THEN 1  -- [K] Runaway's Tunic
  WHEN 1345119 THEN 254186  -- [E] Rusty Falchion
  WHEN 1345120 THEN 287  -- [E] Rusty Greaves
  WHEN 1345121 THEN 1074163  -- [K] Scholar's Ring of Enlightenment
  WHEN 1345122 THEN 515235  -- [E] Second War Axe
  WHEN 1345123 THEN 1074163  -- [K] Seed of Overgrowth
  WHEN 1345124 THEN 41  -- [K] Sentinel Wrap
  WHEN 1345125 THEN 1  -- [K] Shadow Cowl
  WHEN 1345126 THEN 515110  -- [K] Shockzip's Saw Blade
  WHEN 1345127 THEN 176011  -- [K] Shorean's Ironwood Longbow
  WHEN 1345128 THEN 41  -- [K] Silithic Scale Hauberk
  WHEN 1345129 THEN 323  -- [K] Silken Travel Gloves
  WHEN 1345130 THEN 254244  -- [E] Silt Shore Hammer
  WHEN 1345131 THEN 178301  -- [K] Singed Flintlock
  WHEN 1345133 THEN 1012699  -- [K] Sky Guard's Cuirass
  WHEN 1345134 THEN 189447  -- [K] Southwind Defender
  WHEN 1345135 THEN 254184  -- [E] Spellribbon Wand
  WHEN 1345136 THEN 254027  -- [K] Staff of Twin Blossoms
  WHEN 1345137 THEN 188422  -- [K] Staff of the Earth Guardian
  WHEN 1345138 THEN 41  -- [K] Steelrider Girdle
  WHEN 1345139 THEN 174925  -- [K] Steppereaver Hatchet
  WHEN 1345140 THEN 254159  -- [E] Stillpine Cloak
  WHEN 1345141 THEN 254242  -- [E] Stillpine Gavel
  WHEN 1345142 THEN 1074163  -- [K] String of Ears
  WHEN 1345143 THEN 1074163  -- [K] String of Ears
  WHEN 1345144 THEN 1  -- [K] Stubborn Dwarf Slippers
  WHEN 1345145 THEN 515110  -- [K] Sunchaser Blade
  WHEN 1345146 THEN 9170  -- [K] Supply Runner's Pants
  WHEN 1345147 THEN 1074163  -- [K] Terrible Defias Mixture
  WHEN 1345149 THEN 1074163  -- [K] Terrified Braids
  WHEN 1345150 THEN 3851  -- [K] The "Kodo Egg"
  WHEN 1345151 THEN 84677  -- [K] Thresher's Tooth
  WHEN 1345153 THEN 184776  -- [K] Tome of Second Chances
  WHEN 1345154 THEN 1018771  -- [K] Totem of the Flowing River
  WHEN 1345155 THEN 181717  -- [K] Unusual Emerald Scales
  WHEN 1345156 THEN 1012699  -- [K] Venture Co. Boots
  WHEN 1345157 THEN 41  -- [K] Venture Co. Sabatons
  WHEN 1345158 THEN 180717  -- [K] Venture Co. Spaulders
  WHEN 1345159 THEN 1074163  -- [K] Verdant Ember Loop
  WHEN 1345160 THEN 1074163  -- [K] Vial of Dread Water
  WHEN 1345161 THEN 1074163  -- [K] Vial of Dread Water
  WHEN 1345162 THEN 179688  -- [K] Vilebranch Ritual Dagger
  WHEN 1345163 THEN 190304  -- [C] Wand of the Broodbound
  WHEN 1345164 THEN 343  -- [K] Watcher of Tomes
  WHEN 1345165 THEN 1  -- [K] Web Wrappings
  WHEN 1345166 THEN 515051  -- [K] Wheel of Misfortune
  WHEN 1345167 THEN 1013213  -- [E] Windhoof Totem
  WHEN 1345168 THEN 259  -- [K] Worldforged Scroll: Corrupted Shiv
  WHEN 1345169 THEN 259  -- [K] Worldforged Scroll: Disciple of Arugal
  WHEN 1345170 THEN 259  -- [K] Worldforged Scroll: Earthborer Acid
  WHEN 1345173 THEN 259  -- [K] Worldforged Scroll: Flameburst
  WHEN 1345174 THEN 259  -- [K] Worldforged Scroll: Maggot Trap
  WHEN 1345175 THEN 259  -- [K] Worldforged Scroll: Primal Tide
  WHEN 1345176 THEN 259  -- [K] Worldforged Scroll: Saber Slash
  WHEN 1345177 THEN 259  -- [K] Worldforged Scroll: Screams of the Past
  WHEN 1345178 THEN 259  -- [K] Worldforged Scroll: Silence in the Library
  WHEN 1345179 THEN 259  -- [K] Worldforged Scroll: Troll Sweat
  WHEN 1345180 THEN 259  -- [K] Worldforged Scroll: Veil Of Shadows
  WHEN 1345181 THEN 259  -- [K] Worldforged Scroll: Water Geyser
  WHEN 1345182 THEN 185528  -- [K] Wyvern Trapper Spear
  WHEN 1345183 THEN 1009697  -- [K] Zipcoil's Zapper Cap
  WHEN 1546304 THEN 188455  -- [A] Ish'thel Falesh, Gaze of Eldara
  WHEN 1800962 THEN 357  -- [A] Behemoth Victim
  WHEN 2100094 THEN 1044486  -- [B] Cannon Ball
  WHEN 3244513 THEN 1020415  -- [C] Jar of Spiders
  ELSE `displayId` END
WHERE `entry` IN (63143, 63517, 66601, 67241, 67261, 67262, 68369, 68371, 68374, 68376, 68379, 68381, 68394, 68399, 68403, 68406, 68410, 68428, 68430, 68434, 86168, 86169, 86171, 89640, 90043, 90214, 90215, 90216, 90217, 90218, 90219, 90220, 90221, 90223, 90224, 90225, 90226, 90228, 90229, 90233, 90234, 90235, 90236, 90237, 90238, 90239, 90240, 90241, 90242, 90243, 90244, 90245, 90246, 90247, 90248, 90249, 90250, 90251, 90252, 90253, 90254, 90255, 90256, 90258, 90259, 90260, 90261, 90262, 90263, 90264, 90265, 90266, 90268, 90269, 90270, 90271, 90272, 90274, 90275, 90276, 90277, 90278, 90279, 90280, 90281, 90282, 90283, 90284, 90285, 90286, 90287, 90288, 90289, 90290, 90292, 90293, 90294, 90295, 90296, 90297, 90302, 90303, 90304, 90305, 90306, 90308, 90310, 90311, 90312, 90313, 90314, 90316, 90317, 90319, 90320, 90321, 90322, 90323, 90324, 90325, 90327, 90328, 90329, 90330, 90331, 90332, 90336, 90338, 90339, 90340, 90341, 90342, 90345, 90346, 90347, 90348, 90349, 90352, 90354, 90356, 90361, 90372, 90373, 90375, 90376, 90378, 90379, 90380, 90382, 90383, 90384, 90385, 90387, 90388, 90389, 90390, 90391, 90392, 90393, 90394, 90395, 90396, 90411, 90412, 90421, 90423, 90429, 90472, 90478, 90479, 90480, 90484, 90486, 90489, 90492, 90493, 90497, 90498, 90501, 90502, 90508, 90509, 90517, 90519, 90526, 90527, 90528, 90529, 90530, 90531, 90532, 90534, 90545, 90546, 90550, 90551, 90552, 90553, 90554, 90555, 90557, 90559, 90560, 90561, 90562, 90563, 90564, 90565, 90569, 90578, 90579, 90583, 90586, 90589, 90591, 90594, 90596, 90598, 90599, 90606, 90607, 90611, 90612, 90614, 90615, 90617, 90618, 90619, 90620, 90621, 90623, 90625, 90626, 90627, 90636, 93000, 95500, 95501, 95502, 95503, 95504, 95505, 95506, 95507, 95508, 95509, 95510, 95511, 95512, 95513, 95514, 95515, 95516, 95518, 95519, 95520, 95521, 95522, 95523, 95524, 95525, 95526, 95527, 95528, 95529, 95530, 95531, 95532, 95533, 95534, 95535, 95536, 95537, 95538, 95539, 95602, 95603, 95604, 95605, 95606, 95609, 95610, 95612, 95613, 95614, 95615, 95616, 95617, 95618, 95619, 95622, 95623, 95624, 95625, 95626, 95627, 95628, 95629, 95631, 95632, 95633, 95635, 95636, 95637, 95638, 95639, 95640, 95641, 95642, 95643, 95644, 95645, 95646, 95647, 95648, 95650, 95651, 95652, 95653, 95654, 95655, 95656, 95657, 95659, 95661, 95662, 95666, 95668, 95670, 95671, 95673, 95676, 95677, 95678, 95679, 95681, 95683, 95686, 95687, 95688, 95690, 95691, 95692, 95693, 95694, 95695, 95696, 95697, 95698, 95700, 95706, 95707, 95709, 95710, 95711, 95712, 95713, 95714, 95715, 95716, 95717, 95718, 95719, 95720, 95721, 95722, 95723, 95724, 95725, 95726, 95727, 95728, 95729, 95730, 95731, 95732, 95733, 95734, 95735, 95736, 95737, 95738, 95739, 95740, 95741, 95742, 95743, 95744, 95745, 95746, 95747, 95748, 95749, 95750, 95751, 95752, 95753, 95754, 95755, 95756, 95757, 95758, 95759, 95760, 95761, 95762, 95763, 95764, 95765, 95766, 95767, 95777, 95778, 95779, 95780, 95781, 95782, 95783, 95784, 95785, 95786, 95787, 95788, 95789, 95790, 95791, 95792, 95793, 95794, 95795, 95796, 95797, 95798, 95801, 95803, 95804, 95805, 95806, 95807, 95808, 95809, 95810, 95811, 95812, 95813, 95814, 95815, 95816, 95817, 95818, 95819, 95820, 95821, 95822, 95823, 95824, 95825, 95826, 95829, 95830, 95831, 95832, 95833, 95834, 95835, 95836, 95837, 95838, 95839, 95840, 95841, 95842, 95843, 95844, 95845, 95846, 95847, 95848, 95849, 95850, 95851, 95853, 95854, 95855, 95856, 95857, 95858, 95859, 95860, 95861, 95862, 95863, 95864, 95865, 95866, 95867, 95868, 95870, 95872, 95874, 95875, 95876, 95877, 95879, 95880, 95881, 95882, 95883, 95884, 95885, 95886, 95887, 95889, 95890, 95891, 95892, 95893, 95894, 95895, 95896, 95897, 95898, 95899, 95900, 95901, 95902, 95903, 95904, 95906, 95907, 95908, 95909, 95910, 95911, 95912, 95915, 95916, 95917, 95918, 95919, 95920, 95921, 95922, 95923, 95924, 95925, 95926, 95927, 95928, 95929, 95930, 95931, 95932, 95933, 95934, 95935, 95936, 95937, 95938, 95939, 95940, 95941, 95942, 95943, 95945, 95946, 95947, 95948, 96101, 96102, 96103, 96104, 96105, 96106, 96108, 96109, 96110, 96111, 96112, 96113, 96114, 96115, 96116, 96117, 96118, 96119, 96120, 96122, 96123, 96124, 96125, 96126, 96127, 96128, 96130, 96131, 96132, 96133, 96134, 96135, 96136, 96137, 96138, 96139, 96140, 96141, 96142, 96143, 96144, 96145, 96146, 96147, 96148, 96150, 96151, 96152, 96153, 96155, 96156, 96157, 96158, 96159, 96160, 96161, 96162, 96166, 96167, 96168, 96169, 96170, 96173, 96174, 96175, 96176, 96177, 96178, 96179, 96180, 96181, 96182, 96183, 96184, 96185, 96186, 96188, 96189, 96190, 96191, 96192, 96193, 96194, 96195, 96196, 96197, 96198, 96199, 96200, 96201, 96202, 96203, 96204, 96205, 96206, 96207, 96208, 96209, 96210, 96211, 96212, 96213, 96214, 96215, 96216, 96217, 96218, 96219, 96220, 96221, 96222, 96223, 96224, 96225, 96226, 96228, 96229, 96232, 96233, 96234, 96235, 96236, 96238, 96239, 96240, 96241, 96243, 96244, 96246, 96247, 96248, 97100, 97101, 97102, 97103, 97104, 97107, 97108, 97109, 97111, 97112, 97113, 97114, 97115, 97116, 97117, 97118, 97119, 97120, 97121, 97123, 97124, 97125, 97126, 97127, 97128, 97129, 97130, 97131, 97132, 97133, 97134, 97135, 97136, 97137, 142102, 142109, 144570, 150900, 158300, 158305, 158307, 158309, 158313, 158316, 158319, 158320, 158321, 158328, 158330, 158333, 159984, 159985, 159997, 184133, 184134, 188132, 254026, 254156, 254162, 254163, 254164, 254165, 254166, 254172, 254176, 254177, 254178, 254193, 254194, 254221, 254222, 254223, 254225, 254227, 254228, 254229, 254230, 254231, 254232, 254233, 254234, 254235, 254236, 254237, 254238, 254240, 254255, 254258, 254259, 254260, 254261, 254262, 254263, 254264, 254265, 254266, 254267, 254268, 254269, 254270, 254271, 254272, 254273, 254274, 254275, 254276, 254277, 254278, 254279, 254280, 254281, 254282, 254283, 254284, 254285, 254286, 254287, 254288, 254289, 254290, 254291, 254292, 254294, 254295, 254296, 254297, 254298, 254299, 254300, 254301, 254302, 254303, 254304, 254305, 254306, 254307, 254308, 254309, 254310, 254311, 254312, 254313, 254314, 254318, 254319, 254320, 254321, 254322, 254323, 254324, 254325, 254326, 254327, 254328, 254329, 254330, 254331, 254332, 254334, 254335, 254336, 254337, 254338, 254339, 254340, 254341, 254342, 254343, 254345, 254346, 254347, 254348, 254349, 254350, 254351, 254352, 254353, 254354, 254363, 254364, 254365, 254366, 254367, 254368, 254369, 254370, 254371, 254372, 254373, 254374, 254375, 254376, 254377, 254378, 254379, 254380, 254381, 254382, 254383, 254384, 254385, 254386, 254387, 254388, 254389, 254390, 254391, 254392, 254393, 254394, 254395, 254396, 254398, 254399, 254400, 254401, 254402, 254404, 254405, 254410, 254411, 254412, 254413, 254414, 254415, 254416, 254417, 254418, 254419, 254420, 254425, 254429, 254430, 254434, 254436, 254437, 254438, 254439, 254442, 254443, 254444, 254446, 254448, 254449, 254450, 254453, 254455, 254456, 254457, 254458, 254459, 254462, 254463, 254464, 254465, 254466, 254467, 254468, 254471, 254472, 254473, 254474, 254480, 254484, 254486, 254488, 254489, 254491, 254492, 254493, 254494, 254495, 254496, 254497, 254498, 254499, 254502, 254503, 254504, 254505, 254506, 254507, 254516, 254518, 254520, 254521, 254522, 254539, 254540, 254541, 254542, 254543, 254544, 254545, 254546, 254547, 254548, 254549, 254550, 254551, 254553, 254554, 254555, 254556, 254557, 254558, 254559, 254560, 254561, 254562, 254563, 254564, 254565, 254571, 254572, 254573, 254574, 254575, 254577, 254578, 254580, 254581, 254582, 254583, 254617, 254618, 254628, 254630, 254631, 254633, 254635, 254638, 254639, 254640, 254641, 254642, 254643, 254644, 254645, 254647, 254648, 254649, 254650, 254652, 254653, 254654, 254655, 254656, 254657, 254658, 254659, 254660, 254661, 254662, 254663, 254664, 254665, 254666, 254667, 254668, 254669, 254676, 300010, 300011, 300017, 300028, 324495, 324505, 324506, 324507, 324509, 324510, 340042, 340043, 340044, 340047, 340053, 340061, 340066, 340068, 340098, 340099, 340110, 340111, 340112, 340113, 340114, 340115, 340116, 340117, 340118, 340120, 340122, 340123, 340125, 340126, 340127, 340132, 341060, 356431, 356432, 356433, 356434, 356435, 356436, 356439, 356440, 356443, 357440, 375003, 375005, 375024, 375131, 375231, 375327, 387849, 387850, 387852, 387854, 387866, 387867, 387868, 387869, 387870, 387872, 387875, 387876, 387877, 387878, 387880, 387881, 387882, 515039, 515089, 515224, 515259, 515345, 515362, 515365, 515366, 515367, 515368, 515369, 515370, 515372, 515373, 515375, 515376, 515377, 515378, 515379, 515380, 515383, 515384, 515385, 515386, 515387, 515388, 515390, 515392, 515394, 515395, 515396, 515397, 515398, 515400, 515402, 515403, 515404, 515405, 515406, 515407, 515408, 515409, 515425, 515428, 515429, 515430, 515431, 515432, 515433, 515434, 515435, 515436, 515437, 515438, 515439, 515440, 515441, 515442, 515443, 515444, 515466, 515470, 515502, 515503, 515504, 515505, 515506, 515508, 515509, 515510, 515511, 515512, 515513, 515514, 515515, 515516, 515517, 515518, 515519, 515520, 515524, 515525, 515528, 515529, 515530, 515531, 515532, 515533, 515534, 515535, 515536, 515537, 515539, 515540, 515542, 515571, 515596, 515598, 515600, 515613, 515723, 515727, 515738, 515739, 515740, 515741, 515742, 515743, 515744, 515745, 515747, 515748, 515750, 515755, 515764, 515767, 515769, 515770, 515771, 515772, 515773, 515775, 515781, 515782, 515783, 515791, 515797, 515798, 515800, 515801, 515822, 515823, 515824, 515825, 515826, 515827, 515828, 515829, 515830, 515834, 515835, 515836, 515837, 515838, 515839, 515840, 515841, 515842, 515843, 515844, 515845, 515846, 515849, 515853, 515863, 515864, 515865, 515866, 515867, 515877, 515878, 515880, 515884, 515887, 515900, 515901, 515902, 515903, 515904, 515906, 515909, 515910, 515916, 515918, 515919, 515920, 515921, 515922, 515923, 515941, 515942, 515943, 515944, 515945, 515946, 515947, 515948, 515949, 515950, 515951, 515952, 515958, 517202, 517204, 517210, 517223, 517224, 517225, 517232, 517233, 517234, 517235, 517237, 517242, 517254, 517257, 517261, 517263, 517271, 517272, 517273, 517274, 517275, 517276, 517277, 517295, 517314, 517316, 517317, 517322, 517323, 517324, 517325, 517330, 517331, 517336, 517338, 517340, 517341, 517342, 517347, 517349, 517351, 517352, 517353, 517354, 517356, 517357, 517359, 517364, 517366, 517367, 517368, 517370, 517371, 518000, 518006, 518007, 518009, 518010, 518011, 518016, 518018, 518030, 518045, 518048, 518050, 518051, 518052, 518053, 518054, 518055, 518060, 518063, 518079, 518082, 518086, 518087, 518097, 518098, 518099, 518100, 518102, 518123, 518135, 518139, 518140, 518144, 518147, 518149, 518153, 518162, 518166, 518171, 518172, 518174, 518175, 518300, 518301, 518302, 518303, 518305, 518311, 518315, 518316, 518317, 518318, 518319, 518321, 518322, 518342, 518344, 518345, 518346, 518348, 518354, 518372, 518456, 518457, 518460, 518461, 518462, 518464, 518466, 518562, 518564, 518565, 518566, 518567, 518568, 518569, 518572, 518573, 518574, 518575, 518576, 518577, 518578, 518579, 518580, 518582, 518583, 518584, 518586, 518678, 518788, 518894, 520018, 520047, 520051, 520055, 520062, 520063, 520064, 520065, 520066, 520067, 520068, 520069, 520071, 520072, 520073, 520696, 520697, 520698, 520699, 520700, 520701, 520702, 520703, 520704, 638836, 654637, 686868, 686869, 686871, 686877, 686878, 686879, 686880, 686881, 686882, 686883, 686885, 686887, 686888, 686889, 686891, 686898, 686899, 686900, 686902, 686906, 686907, 686908, 686909, 686913, 686914, 686916, 686918, 686919, 686920, 686922, 686930, 686933, 686934, 686935, 686936, 686937, 735901, 735902, 735924, 836218, 1344099, 1344800, 1344801, 1344802, 1344803, 1345000, 1345001, 1345002, 1345003, 1345004, 1345005, 1345006, 1345007, 1345008, 1345009, 1345010, 1345011, 1345012, 1345013, 1345014, 1345015, 1345016, 1345017, 1345018, 1345019, 1345020, 1345021, 1345022, 1345023, 1345024, 1345025, 1345026, 1345027, 1345028, 1345029, 1345030, 1345031, 1345032, 1345033, 1345034, 1345035, 1345036, 1345037, 1345038, 1345039, 1345040, 1345041, 1345042, 1345043, 1345044, 1345045, 1345046, 1345047, 1345048, 1345049, 1345050, 1345051, 1345052, 1345053, 1345054, 1345055, 1345056, 1345057, 1345058, 1345059, 1345060, 1345061, 1345062, 1345063, 1345064, 1345065, 1345066, 1345067, 1345068, 1345069, 1345070, 1345071, 1345072, 1345073, 1345074, 1345075, 1345076, 1345077, 1345078, 1345080, 1345081, 1345082, 1345083, 1345084, 1345085, 1345086, 1345087, 1345088, 1345089, 1345090, 1345091, 1345092, 1345093, 1345094, 1345095, 1345096, 1345097, 1345098, 1345099, 1345100, 1345101, 1345102, 1345103, 1345104, 1345105, 1345106, 1345107, 1345108, 1345109, 1345110, 1345111, 1345112, 1345113, 1345114, 1345115, 1345116, 1345117, 1345118, 1345119, 1345120, 1345121, 1345122, 1345123, 1345124, 1345125, 1345126, 1345127, 1345128, 1345129, 1345130, 1345131, 1345133, 1345134, 1345135, 1345136, 1345137, 1345138, 1345139, 1345140, 1345141, 1345142, 1345143, 1345144, 1345145, 1345146, 1345147, 1345149, 1345150, 1345151, 1345153, 1345154, 1345155, 1345156, 1345157, 1345158, 1345159, 1345160, 1345161, 1345162, 1345163, 1345164, 1345165, 1345166, 1345167, 1345168, 1345169, 1345170, 1345173, 1345174, 1345175, 1345176, 1345177, 1345178, 1345179, 1345180, 1345181, 1345182, 1345183, 1546304, 1800962, 2100094, 3244513);

-- the render scale the same record states
UPDATE `gameobject_template` SET `size` = CASE `entry`
  WHEN 63143 THEN 1.0
  WHEN 66601 THEN 1.0
  WHEN 67241 THEN 1.0
  WHEN 67261 THEN 1.0
  WHEN 67262 THEN 1.0
  WHEN 68369 THEN 1.0
  WHEN 68371 THEN 1.0
  WHEN 68374 THEN 1.0
  WHEN 68376 THEN 1.0
  WHEN 68379 THEN 1.0
  WHEN 68381 THEN 1.0
  WHEN 68394 THEN 1.0
  WHEN 68399 THEN 1.0
  WHEN 68403 THEN 1.0
  WHEN 68406 THEN 0.7
  WHEN 68410 THEN 1.0
  WHEN 68428 THEN 1.0
  WHEN 68430 THEN 1.0
  WHEN 68434 THEN 1.0
  WHEN 86168 THEN 1.0
  WHEN 86169 THEN 1.0
  WHEN 86171 THEN 1.0
  WHEN 89640 THEN 0.6
  WHEN 90043 THEN 0.2
  WHEN 90214 THEN 0.6
  WHEN 90215 THEN 1.0
  WHEN 90216 THEN 0.8
  WHEN 90217 THEN 0.8
  WHEN 90218 THEN 0.5
  WHEN 90219 THEN 1.5
  WHEN 90220 THEN 2.0
  WHEN 90221 THEN 0.7
  WHEN 90223 THEN 1.0
  WHEN 90224 THEN 1.5
  WHEN 90228 THEN 0.8
  WHEN 90234 THEN 0.25
  WHEN 90235 THEN 1.0
  WHEN 90236 THEN 0.4
  WHEN 90237 THEN 0.8
  WHEN 90240 THEN 1.0
  WHEN 90241 THEN 1.0
  WHEN 90242 THEN 1.0
  WHEN 90243 THEN 0.7
  WHEN 90245 THEN 1.0
  WHEN 90246 THEN 1.0
  WHEN 90247 THEN 0.7
  WHEN 90248 THEN 0.7
  WHEN 90249 THEN 1.0
  WHEN 90250 THEN 1.0
  WHEN 90251 THEN 1.0
  WHEN 90253 THEN 1.0
  WHEN 90254 THEN 0.8
  WHEN 90255 THEN 1.2
  WHEN 90256 THEN 1.0
  WHEN 90261 THEN 1.2
  WHEN 90263 THEN 1.2
  WHEN 90264 THEN 1.2
  WHEN 90265 THEN 1.5
  WHEN 90266 THEN 1.5
  WHEN 90270 THEN 1.0
  WHEN 90272 THEN 1.0
  WHEN 90274 THEN 1.0
  WHEN 90275 THEN 0.4
  WHEN 90276 THEN 1.0
  WHEN 90277 THEN 1.0
  WHEN 90279 THEN 1.0
  WHEN 90280 THEN 0.3
  WHEN 90281 THEN 1.0
  WHEN 90282 THEN 1.0
  WHEN 90283 THEN 1.0
  WHEN 90286 THEN 1.0
  WHEN 90287 THEN 1.0
  WHEN 90290 THEN 1.0
  WHEN 90292 THEN 1.8
  WHEN 90293 THEN 1.0
  WHEN 90294 THEN 1.0
  WHEN 90295 THEN 0.5
  WHEN 90296 THEN 1.0
  WHEN 90302 THEN 1.2
  WHEN 90303 THEN 1.0
  WHEN 90304 THEN 1.3
  WHEN 90306 THEN 1.0
  WHEN 90308 THEN 1.2
  WHEN 90310 THEN 1.8
  WHEN 90311 THEN 1.0
  WHEN 90312 THEN 1.0
  WHEN 90313 THEN 1.3
  WHEN 90314 THEN 1.0
  WHEN 90316 THEN 1.0
  WHEN 90320 THEN 1.0
  WHEN 90322 THEN 0.7
  WHEN 90325 THEN 1.8
  WHEN 90328 THEN 0.3
  WHEN 90331 THEN 1.0
  WHEN 90336 THEN 1.0
  WHEN 90338 THEN 0.5
  WHEN 90339 THEN 1.0
  WHEN 90340 THEN 1.6
  WHEN 90341 THEN 1.6
  WHEN 90346 THEN 0.7
  WHEN 90347 THEN 0.7
  WHEN 90354 THEN 1.5
  WHEN 90356 THEN 1.0
  WHEN 90361 THEN 1.0
  WHEN 90372 THEN 1.0
  WHEN 90373 THEN 1.3
  WHEN 90375 THEN 1.0
  WHEN 90378 THEN 1.8
  WHEN 90379 THEN 0.4
  WHEN 90380 THEN 1.0
  WHEN 90383 THEN 1.6
  WHEN 90385 THEN 0.2
  WHEN 90388 THEN 1.0
  WHEN 90389 THEN 0.35
  WHEN 90390 THEN 1.6
  WHEN 90391 THEN 1.0
  WHEN 90392 THEN 1.4
  WHEN 90393 THEN 1.3
  WHEN 90396 THEN 1.2
  WHEN 90412 THEN 1.3
  WHEN 90421 THEN 0.8
  WHEN 90423 THEN 1.0
  WHEN 90429 THEN 0.8
  WHEN 90478 THEN 1.0
  WHEN 90479 THEN 1.0
  WHEN 90480 THEN 1.0
  WHEN 90484 THEN 1.0
  WHEN 90486 THEN 0.8
  WHEN 90489 THEN 0.8
  WHEN 90492 THEN 1.0
  WHEN 90493 THEN 0.25
  WHEN 90497 THEN 1.0
  WHEN 90498 THEN 1.0
  WHEN 90501 THEN 1.0
  WHEN 90502 THEN 1.0
  WHEN 90508 THEN 0.7
  WHEN 90509 THEN 1.0
  WHEN 90519 THEN 1.3
  WHEN 90527 THEN 0.5
  WHEN 90529 THEN 1.0
  WHEN 90530 THEN 1.0
  WHEN 90531 THEN 1.5
  WHEN 90532 THEN 1.3
  WHEN 90534 THEN 1.3
  WHEN 90546 THEN 1.2
  WHEN 90551 THEN 1.8
  WHEN 90552 THEN 1.2
  WHEN 90553 THEN 1.2
  WHEN 90554 THEN 0.65
  WHEN 90557 THEN 1.0
  WHEN 90559 THEN 0.8
  WHEN 90560 THEN 1.0
  WHEN 90562 THEN 1.0
  WHEN 90563 THEN 1.0
  WHEN 90564 THEN 1.0
  WHEN 90565 THEN 1.8
  WHEN 90579 THEN 1.8
  WHEN 90583 THEN 1.0
  WHEN 90586 THEN 1.0
  WHEN 90589 THEN 0.55
  WHEN 90591 THEN 1.8
  WHEN 90594 THEN 1.0
  WHEN 90598 THEN 0.7
  WHEN 90606 THEN 1.0
  WHEN 90611 THEN 1.0
  WHEN 90612 THEN 1.0
  WHEN 90614 THEN 1.0
  WHEN 90615 THEN 1.0
  WHEN 90617 THEN 1.0
  WHEN 90619 THEN 1.0
  WHEN 90620 THEN 1.0
  WHEN 90621 THEN 1.0
  WHEN 90623 THEN 1.75
  WHEN 90625 THEN 0.75
  WHEN 90626 THEN 0.5
  WHEN 90627 THEN 0.75
  WHEN 90636 THEN 0.65
  WHEN 93000 THEN 1.0
  WHEN 95500 THEN 0.7
  WHEN 95501 THEN 1.0
  WHEN 95502 THEN 0.3
  WHEN 95503 THEN 1.0
  WHEN 95504 THEN 0.314
  WHEN 95505 THEN 1.0
  WHEN 95506 THEN 1.0
  WHEN 95507 THEN 1.0
  WHEN 95508 THEN 1.2
  WHEN 95509 THEN 1.0
  WHEN 95510 THEN 1.0
  WHEN 95511 THEN 1.0
  WHEN 95513 THEN 1.1
  WHEN 95514 THEN 1.0
  WHEN 95516 THEN 1.0
  WHEN 95518 THEN 0.4
  WHEN 95521 THEN 1.0
  WHEN 95522 THEN 0.6
  WHEN 95523 THEN 1.7
  WHEN 95524 THEN 1.0
  WHEN 95525 THEN 1.0
  WHEN 95526 THEN 1.0
  WHEN 95527 THEN 1.0
  WHEN 95530 THEN 1.0
  WHEN 95533 THEN 1.2
  WHEN 95534 THEN 1.0
  WHEN 95535 THEN 0.7
  WHEN 95536 THEN 1.05
  WHEN 95537 THEN 0.5
  WHEN 95538 THEN 1.2
  WHEN 95539 THEN 1.0
  WHEN 95602 THEN 1.0
  WHEN 95603 THEN 1.0
  WHEN 95604 THEN 1.2
  WHEN 95605 THEN 1.0
  WHEN 95606 THEN 1.15
  WHEN 95609 THEN 0.35
  WHEN 95610 THEN 1.0
  WHEN 95612 THEN 1.0
  WHEN 95613 THEN 1.0
  WHEN 95614 THEN 1.0
  WHEN 95615 THEN 1.0
  WHEN 95616 THEN 1.0
  WHEN 95617 THEN 1.0
  WHEN 95618 THEN 0.5
  WHEN 95619 THEN 1.0
  WHEN 95622 THEN 1.0
  WHEN 95623 THEN 1.0
  WHEN 95625 THEN 1.0
  WHEN 95626 THEN 0.5
  WHEN 95628 THEN 0.85
  WHEN 95631 THEN 1.0
  WHEN 95635 THEN 1.0
  WHEN 95636 THEN 1.0
  WHEN 95637 THEN 1.0
  WHEN 95639 THEN 1.0
  WHEN 95640 THEN 1.0
  WHEN 95641 THEN 1.2
  WHEN 95642 THEN 1.0
  WHEN 95643 THEN 1.0
  WHEN 95646 THEN 1.0
  WHEN 95647 THEN 1.0
  WHEN 95648 THEN 1.0
  WHEN 95650 THEN 0.5
  WHEN 95651 THEN 1.0
  WHEN 95653 THEN 1.0
  WHEN 95654 THEN 1.0
  WHEN 95655 THEN 1.0
  WHEN 95656 THEN 1.0
  WHEN 95659 THEN 0.6
  WHEN 95661 THEN 1.0
  WHEN 95662 THEN 1.0
  WHEN 95666 THEN 1.0
  WHEN 95668 THEN 1.0
  WHEN 95670 THEN 1.0
  WHEN 95671 THEN 0.7
  WHEN 95673 THEN 1.0
  WHEN 95677 THEN 1.0
  WHEN 95678 THEN 1.0
  WHEN 95679 THEN 1.0
  WHEN 95681 THEN 1.5
  WHEN 95683 THEN 1.0
  WHEN 95687 THEN 1.0
  WHEN 95688 THEN 1.0
  WHEN 95690 THEN 1.0
  WHEN 95691 THEN 1.0
  WHEN 95693 THEN 1.0
  WHEN 95694 THEN 1.0
  WHEN 95695 THEN 1.0
  WHEN 95697 THEN 0.8
  WHEN 95698 THEN 1.0
  WHEN 95700 THEN 1.0
  WHEN 95706 THEN 1.4
  WHEN 95709 THEN 1.0
  WHEN 95710 THEN 1.0
  WHEN 95711 THEN 1.0
  WHEN 95712 THEN 1.0
  WHEN 95713 THEN 1.0
  WHEN 95714 THEN 1.0
  WHEN 95717 THEN 1.0
  WHEN 95719 THEN 1.0
  WHEN 95720 THEN 1.0
  WHEN 95721 THEN 1.0
  WHEN 95722 THEN 1.0
  WHEN 95723 THEN 1.0
  WHEN 95724 THEN 1.0
  WHEN 95725 THEN 1.0
  WHEN 95726 THEN 1.0
  WHEN 95728 THEN 1.0
  WHEN 95730 THEN 1.0
  WHEN 95731 THEN 1.0
  WHEN 95732 THEN 1.0
  WHEN 95734 THEN 1.0
  WHEN 95737 THEN 1.0
  WHEN 95738 THEN 1.0
  WHEN 95739 THEN 1.0
  WHEN 95740 THEN 1.0
  WHEN 95741 THEN 1.0
  WHEN 95742 THEN 1.0
  WHEN 95743 THEN 1.0
  WHEN 95744 THEN 1.0
  WHEN 95745 THEN 1.0
  WHEN 95746 THEN 1.0
  WHEN 95747 THEN 1.0
  WHEN 95749 THEN 1.0
  WHEN 95751 THEN 1.0
  WHEN 95752 THEN 1.0
  WHEN 95754 THEN 1.0
  WHEN 95756 THEN 1.0
  WHEN 95758 THEN 1.0
  WHEN 95759 THEN 1.0
  WHEN 95760 THEN 1.0
  WHEN 95764 THEN 1.0
  WHEN 95765 THEN 1.0
  WHEN 95767 THEN 1.0
  WHEN 95777 THEN 1.0
  WHEN 95778 THEN 1.0
  WHEN 95780 THEN 1.0
  WHEN 95781 THEN 1.0
  WHEN 95782 THEN 1.0
  WHEN 95783 THEN 1.0
  WHEN 95784 THEN 1.0
  WHEN 95785 THEN 1.0
  WHEN 95786 THEN 1.0
  WHEN 95788 THEN 1.0
  WHEN 95789 THEN 1.0
  WHEN 95790 THEN 1.0
  WHEN 95791 THEN 1.0
  WHEN 95792 THEN 1.0
  WHEN 95793 THEN 1.0
  WHEN 95794 THEN 1.0
  WHEN 95795 THEN 1.0
  WHEN 95796 THEN 1.0
  WHEN 95797 THEN 1.0
  WHEN 95798 THEN 1.0
  WHEN 95803 THEN 1.0
  WHEN 95804 THEN 1.2
  WHEN 95805 THEN 1.0
  WHEN 95806 THEN 1.0
  WHEN 95808 THEN 1.0
  WHEN 95809 THEN 0.9
  WHEN 95810 THEN 1.0
  WHEN 95811 THEN 1.0
  WHEN 95812 THEN 0.4
  WHEN 95813 THEN 1.0
  WHEN 95814 THEN 1.0
  WHEN 95816 THEN 1.0
  WHEN 95817 THEN 1.0
  WHEN 95818 THEN 1.0
  WHEN 95820 THEN 1.0
  WHEN 95822 THEN 1.0
  WHEN 95823 THEN 1.0
  WHEN 95824 THEN 1.0
  WHEN 95825 THEN 1.0
  WHEN 95826 THEN 1.0
  WHEN 95830 THEN 1.0
  WHEN 95831 THEN 1.0
  WHEN 95833 THEN 1.0
  WHEN 95834 THEN 1.0
  WHEN 95835 THEN 0.65
  WHEN 95836 THEN 1.0
  WHEN 95837 THEN 1.0
  WHEN 95838 THEN 1.0
  WHEN 95839 THEN 1.3
  WHEN 95840 THEN 1.0
  WHEN 95841 THEN 1.0
  WHEN 95842 THEN 1.0
  WHEN 95843 THEN 1.0
  WHEN 95844 THEN 1.0
  WHEN 95846 THEN 1.0
  WHEN 95848 THEN 1.0
  WHEN 95849 THEN 1.0
  WHEN 95850 THEN 1.0
  WHEN 95853 THEN 1.0
  WHEN 95854 THEN 1.0
  WHEN 95855 THEN 1.0
  WHEN 95856 THEN 1.0
  WHEN 95857 THEN 1.0
  WHEN 95858 THEN 1.0
  WHEN 95859 THEN 1.0
  WHEN 95860 THEN 1.0
  WHEN 95861 THEN 1.0
  WHEN 95862 THEN 1.0
  WHEN 95863 THEN 1.0
  WHEN 95864 THEN 1.0
  WHEN 95865 THEN 1.0
  WHEN 95866 THEN 1.0
  WHEN 95867 THEN 1.0
  WHEN 95870 THEN 1.0
  WHEN 95872 THEN 1.0
  WHEN 95874 THEN 1.0
  WHEN 95875 THEN 1.0
  WHEN 95876 THEN 1.0
  WHEN 95877 THEN 1.0
  WHEN 95880 THEN 1.0
  WHEN 95881 THEN 1.0
  WHEN 95882 THEN 1.0
  WHEN 95883 THEN 1.0
  WHEN 95884 THEN 1.0
  WHEN 95885 THEN 1.0
  WHEN 95887 THEN 1.0
  WHEN 95889 THEN 1.0
  WHEN 95890 THEN 1.0
  WHEN 95891 THEN 1.0
  WHEN 95892 THEN 1.0
  WHEN 95893 THEN 1.0
  WHEN 95894 THEN 1.0
  WHEN 95895 THEN 1.0
  WHEN 95896 THEN 1.0
  WHEN 95897 THEN 1.0
  WHEN 95898 THEN 1.0
  WHEN 95899 THEN 1.0
  WHEN 95900 THEN 1.0
  WHEN 95901 THEN 1.0
  WHEN 95902 THEN 1.0
  WHEN 95903 THEN 1.0
  WHEN 95904 THEN 1.0
  WHEN 95906 THEN 1.0
  WHEN 95907 THEN 1.0
  WHEN 95908 THEN 1.0
  WHEN 95909 THEN 1.0
  WHEN 95910 THEN 1.0
  WHEN 95911 THEN 1.0
  WHEN 95912 THEN 1.0
  WHEN 95915 THEN 1.0
  WHEN 95916 THEN 1.0
  WHEN 95917 THEN 1.0
  WHEN 95918 THEN 1.0
  WHEN 95919 THEN 1.0
  WHEN 95920 THEN 1.0
  WHEN 95921 THEN 1.0
  WHEN 95922 THEN 1.0
  WHEN 95923 THEN 1.0
  WHEN 95924 THEN 1.0
  WHEN 95925 THEN 1.0
  WHEN 95926 THEN 1.0
  WHEN 95927 THEN 1.0
  WHEN 95928 THEN 1.0
  WHEN 95929 THEN 1.0
  WHEN 95930 THEN 1.0
  WHEN 95931 THEN 1.0
  WHEN 95932 THEN 1.0
  WHEN 95933 THEN 1.0
  WHEN 95934 THEN 1.0
  WHEN 95935 THEN 1.0
  WHEN 95936 THEN 1.0
  WHEN 95937 THEN 1.0
  WHEN 95938 THEN 1.0
  WHEN 95939 THEN 1.0
  WHEN 95940 THEN 1.0
  WHEN 95941 THEN 1.0
  WHEN 95942 THEN 1.0
  WHEN 95943 THEN 1.0
  WHEN 95945 THEN 1.0
  WHEN 95946 THEN 1.0
  WHEN 95947 THEN 1.0
  WHEN 95948 THEN 1.0
  WHEN 96101 THEN 1.0
  WHEN 96102 THEN 1.0
  WHEN 96103 THEN 1.0
  WHEN 96104 THEN 1.0
  WHEN 96105 THEN 1.0
  WHEN 96106 THEN 1.0
  WHEN 96108 THEN 1.0
  WHEN 96109 THEN 1.0
  WHEN 96110 THEN 1.0
  WHEN 96112 THEN 1.0
  WHEN 96113 THEN 1.0
  WHEN 96114 THEN 1.0
  WHEN 96115 THEN 1.0
  WHEN 96116 THEN 1.0
  WHEN 96117 THEN 1.0
  WHEN 96118 THEN 1.0
  WHEN 96119 THEN 1.75
  WHEN 96120 THEN 1.0
  WHEN 96122 THEN 1.0
  WHEN 96123 THEN 1.0
  WHEN 96124 THEN 1.0
  WHEN 96125 THEN 1.0
  WHEN 96126 THEN 1.0
  WHEN 96127 THEN 1.0
  WHEN 96128 THEN 1.0
  WHEN 96130 THEN 1.0
  WHEN 96131 THEN 1.0
  WHEN 96132 THEN 1.0
  WHEN 96133 THEN 1.0
  WHEN 96134 THEN 1.0
  WHEN 96135 THEN 1.0
  WHEN 96136 THEN 1.0
  WHEN 96137 THEN 1.0
  WHEN 96138 THEN 1.0
  WHEN 96139 THEN 1.0
  WHEN 96140 THEN 1.0
  WHEN 96141 THEN 1.0
  WHEN 96142 THEN 1.0
  WHEN 96143 THEN 1.0
  WHEN 96144 THEN 1.0
  WHEN 96145 THEN 1.0
  WHEN 96146 THEN 1.0
  WHEN 96147 THEN 1.0
  WHEN 96148 THEN 1.0
  WHEN 96150 THEN 1.0
  WHEN 96151 THEN 1.0
  WHEN 96152 THEN 1.0
  WHEN 96153 THEN 1.0
  WHEN 96155 THEN 1.0
  WHEN 96156 THEN 1.0
  WHEN 96157 THEN 1.0
  WHEN 96158 THEN 1.0
  WHEN 96159 THEN 1.0
  WHEN 96161 THEN 1.0
  WHEN 96162 THEN 1.0
  WHEN 96167 THEN 1.0
  WHEN 96168 THEN 1.0
  WHEN 96169 THEN 1.0
  WHEN 96173 THEN 1.0
  WHEN 96174 THEN 1.0
  WHEN 96175 THEN 1.0
  WHEN 96176 THEN 1.0
  WHEN 96177 THEN 1.0
  WHEN 96178 THEN 1.0
  WHEN 96179 THEN 1.0
  WHEN 96180 THEN 1.0
  WHEN 96181 THEN 1.0
  WHEN 96182 THEN 1.0
  WHEN 96183 THEN 1.0
  WHEN 96184 THEN 1.0
  WHEN 96185 THEN 1.0
  WHEN 96186 THEN 1.0
  WHEN 96188 THEN 1.0
  WHEN 96189 THEN 1.0
  WHEN 96190 THEN 1.0
  WHEN 96191 THEN 1.0
  WHEN 96192 THEN 1.0
  WHEN 96193 THEN 1.0
  WHEN 96194 THEN 1.0
  WHEN 96195 THEN 1.0
  WHEN 96196 THEN 1.0
  WHEN 96197 THEN 1.0
  WHEN 96198 THEN 1.0
  WHEN 96199 THEN 1.0
  WHEN 96200 THEN 1.0
  WHEN 96201 THEN 1.0
  WHEN 96202 THEN 1.0
  WHEN 96203 THEN 1.0
  WHEN 96204 THEN 1.0
  WHEN 96205 THEN 1.0
  WHEN 96206 THEN 1.0
  WHEN 96207 THEN 1.0
  WHEN 96208 THEN 1.0
  WHEN 96209 THEN 1.0
  WHEN 96210 THEN 1.0
  WHEN 96211 THEN 1.0
  WHEN 96212 THEN 1.0
  WHEN 96213 THEN 1.0
  WHEN 96214 THEN 1.0
  WHEN 96215 THEN 1.0
  WHEN 96216 THEN 1.0
  WHEN 96217 THEN 1.0
  WHEN 96218 THEN 1.0
  WHEN 96219 THEN 1.0
  WHEN 96220 THEN 1.0
  WHEN 96221 THEN 1.0
  WHEN 96222 THEN 1.0
  WHEN 96223 THEN 1.0
  WHEN 96224 THEN 1.0
  WHEN 96226 THEN 1.0
  WHEN 96228 THEN 1.0
  WHEN 96229 THEN 1.0
  WHEN 96232 THEN 1.0
  WHEN 96233 THEN 1.0
  WHEN 96234 THEN 1.0
  WHEN 96235 THEN 1.0
  WHEN 96236 THEN 1.0
  WHEN 96239 THEN 1.0
  WHEN 96240 THEN 1.0
  WHEN 96241 THEN 1.0
  WHEN 96243 THEN 1.0
  WHEN 96244 THEN 1.0
  WHEN 96246 THEN 2.0
  WHEN 96247 THEN 1.0
  WHEN 96248 THEN 1.0
  WHEN 97101 THEN 1.0
  WHEN 97102 THEN 1.0
  WHEN 97103 THEN 0.5
  WHEN 97104 THEN 1.0
  WHEN 97107 THEN 1.0
  WHEN 97108 THEN 1.0
  WHEN 97109 THEN 1.0
  WHEN 97111 THEN 1.0
  WHEN 97112 THEN 1.0
  WHEN 97113 THEN 1.0
  WHEN 97114 THEN 1.0
  WHEN 97115 THEN 1.0
  WHEN 97116 THEN 1.0
  WHEN 97117 THEN 1.0
  WHEN 97118 THEN 1.0
  WHEN 97120 THEN 1.0
  WHEN 97121 THEN 1.0
  WHEN 97123 THEN 1.0
  WHEN 97124 THEN 1.0
  WHEN 97125 THEN 1.0
  WHEN 97126 THEN 1.0
  WHEN 97127 THEN 1.0
  WHEN 97128 THEN 1.0
  WHEN 97129 THEN 1.0
  WHEN 97130 THEN 1.0
  WHEN 97131 THEN 1.0
  WHEN 97132 THEN 1.0
  WHEN 97133 THEN 1.0
  WHEN 97134 THEN 1.0
  WHEN 97135 THEN 1.0
  WHEN 97136 THEN 1.0
  WHEN 97137 THEN 1.0
  WHEN 142102 THEN 1.0
  WHEN 142109 THEN 1.0
  WHEN 150900 THEN 0.3
  WHEN 158300 THEN 1.0
  WHEN 158305 THEN 1.0
  WHEN 158307 THEN 1.0
  WHEN 158309 THEN 1.0
  WHEN 158313 THEN 1.0
  WHEN 158316 THEN 1.0
  WHEN 158319 THEN 1.0
  WHEN 158320 THEN 1.0
  WHEN 158321 THEN 1.0
  WHEN 158328 THEN 0.4
  WHEN 158330 THEN 1.0
  WHEN 158333 THEN 1.0
  WHEN 159984 THEN 1.0
  WHEN 159985 THEN 1.0
  WHEN 159997 THEN 1.0
  WHEN 184133 THEN 1.0
  WHEN 184134 THEN 1.0
  WHEN 254026 THEN 0.7
  WHEN 254156 THEN 2.0
  WHEN 254163 THEN 1.0
  WHEN 254164 THEN 0.85
  WHEN 254165 THEN 0.7
  WHEN 254166 THEN 1.2
  WHEN 254172 THEN 1.0
  WHEN 254176 THEN 1.0
  WHEN 254178 THEN 1.0
  WHEN 254194 THEN 1.0
  WHEN 254221 THEN 0.5
  WHEN 254222 THEN 1.0
  WHEN 254223 THEN 1.0
  WHEN 254225 THEN 1.0
  WHEN 254227 THEN 1.0
  WHEN 254228 THEN 1.0
  WHEN 254229 THEN 1.0
  WHEN 254231 THEN 1.0
  WHEN 254232 THEN 1.0
  WHEN 254233 THEN 1.0
  WHEN 254234 THEN 1.0
  WHEN 254235 THEN 1.0
  WHEN 254236 THEN 1.0
  WHEN 254237 THEN 1.0
  WHEN 254238 THEN 1.0
  WHEN 254240 THEN 0.8
  WHEN 254255 THEN 1.0
  WHEN 254258 THEN 1.0
  WHEN 254259 THEN 1.0
  WHEN 254260 THEN 1.0
  WHEN 254261 THEN 1.0
  WHEN 254263 THEN 1.0
  WHEN 254264 THEN 1.0
  WHEN 254265 THEN 0.7
  WHEN 254266 THEN 0.7
  WHEN 254267 THEN 0.7
  WHEN 254268 THEN 1.0
  WHEN 254269 THEN 1.0
  WHEN 254270 THEN 1.0
  WHEN 254271 THEN 1.0
  WHEN 254272 THEN 1.0
  WHEN 254273 THEN 1.3
  WHEN 254275 THEN 1.0
  WHEN 254276 THEN 1.0
  WHEN 254278 THEN 0.6
  WHEN 254279 THEN 1.0
  WHEN 254280 THEN 1.0
  WHEN 254281 THEN 1.0
  WHEN 254282 THEN 1.0
  WHEN 254283 THEN 1.0
  WHEN 254284 THEN 1.0
  WHEN 254285 THEN 1.0
  WHEN 254286 THEN 0.5
  WHEN 254287 THEN 0.5
  WHEN 254289 THEN 1.0
  WHEN 254290 THEN 1.0
  WHEN 254292 THEN 1.0
  WHEN 254295 THEN 1.0
  WHEN 254296 THEN 1.0
  WHEN 254297 THEN 1.0
  WHEN 254298 THEN 1.0
  WHEN 254299 THEN 1.0
  WHEN 254300 THEN 1.0
  WHEN 254301 THEN 1.0
  WHEN 254302 THEN 1.0
  WHEN 254303 THEN 1.0
  WHEN 254304 THEN 1.0
  WHEN 254305 THEN 1.0
  WHEN 254306 THEN 1.0
  WHEN 254307 THEN 1.0
  WHEN 254309 THEN 2.0
  WHEN 254310 THEN 1.4
  WHEN 254311 THEN 1.0
  WHEN 254312 THEN 1.0
  WHEN 254313 THEN 1.0
  WHEN 254314 THEN 1.0
  WHEN 254318 THEN 1.0
  WHEN 254320 THEN 1.0
  WHEN 254321 THEN 1.0
  WHEN 254322 THEN 1.0
  WHEN 254323 THEN 1.0
  WHEN 254324 THEN 1.0
  WHEN 254325 THEN 1.0
  WHEN 254326 THEN 1.0
  WHEN 254327 THEN 1.0
  WHEN 254328 THEN 1.0
  WHEN 254329 THEN 1.0
  WHEN 254330 THEN 1.0
  WHEN 254334 THEN 1.0
  WHEN 254335 THEN 1.0
  WHEN 254337 THEN 1.0
  WHEN 254338 THEN 1.0
  WHEN 254339 THEN 1.0
  WHEN 254340 THEN 1.0
  WHEN 254341 THEN 1.0
  WHEN 254342 THEN 1.1
  WHEN 254343 THEN 1.0
  WHEN 254345 THEN 0.7
  WHEN 254346 THEN 0.4
  WHEN 254347 THEN 1.0
  WHEN 254348 THEN 1.0
  WHEN 254349 THEN 1.0
  WHEN 254350 THEN 1.0
  WHEN 254351 THEN 1.0
  WHEN 254353 THEN 1.0
  WHEN 254354 THEN 1.0
  WHEN 254363 THEN 1.0
  WHEN 254364 THEN 1.0
  WHEN 254365 THEN 1.0
  WHEN 254366 THEN 1.0
  WHEN 254367 THEN 1.0
  WHEN 254369 THEN 0.6
  WHEN 254370 THEN 1.0
  WHEN 254372 THEN 1.0
  WHEN 254373 THEN 1.0
  WHEN 254374 THEN 1.0
  WHEN 254375 THEN 1.2
  WHEN 254376 THEN 0.3
  WHEN 254377 THEN 0.3
  WHEN 254378 THEN 1.0
  WHEN 254379 THEN 1.0
  WHEN 254380 THEN 1.0
  WHEN 254381 THEN 1.0
  WHEN 254382 THEN 1.0
  WHEN 254383 THEN 0.3
  WHEN 254384 THEN 0.6
  WHEN 254385 THEN 1.0
  WHEN 254386 THEN 1.0
  WHEN 254387 THEN 1.0
  WHEN 254388 THEN 1.0
  WHEN 254389 THEN 1.0
  WHEN 254390 THEN 1.0
  WHEN 254391 THEN 0.4
  WHEN 254393 THEN 0.4
  WHEN 254394 THEN 1.0
  WHEN 254395 THEN 1.0
  WHEN 254396 THEN 1.0
  WHEN 254398 THEN 0.2
  WHEN 254399 THEN 1.0
  WHEN 254401 THEN 1.5
  WHEN 254402 THEN 1.5
  WHEN 254404 THEN 1.0
  WHEN 254405 THEN 1.0
  WHEN 254410 THEN 1.0
  WHEN 254411 THEN 1.0
  WHEN 254412 THEN 1.0
  WHEN 254413 THEN 0.7
  WHEN 254414 THEN 1.0
  WHEN 254415 THEN 1.0
  WHEN 254416 THEN 1.0
  WHEN 254417 THEN 1.0
  WHEN 254418 THEN 1.0
  WHEN 254419 THEN 1.2
  WHEN 254420 THEN 1.0
  WHEN 254425 THEN 1.0
  WHEN 254429 THEN 1.0
  WHEN 254430 THEN 1.0
  WHEN 254434 THEN 1.0
  WHEN 254436 THEN 1.0
  WHEN 254437 THEN 1.0
  WHEN 254438 THEN 1.0
  WHEN 254439 THEN 1.0
  WHEN 254442 THEN 1.0
  WHEN 254443 THEN 1.0
  WHEN 254444 THEN 1.0
  WHEN 254446 THEN 1.0
  WHEN 254448 THEN 1.0
  WHEN 254449 THEN 1.0
  WHEN 254450 THEN 1.0
  WHEN 254453 THEN 1.0
  WHEN 254455 THEN 1.0
  WHEN 254456 THEN 1.0
  WHEN 254457 THEN 1.0
  WHEN 254458 THEN 1.0
  WHEN 254459 THEN 1.0
  WHEN 254462 THEN 1.0
  WHEN 254463 THEN 1.0
  WHEN 254464 THEN 1.0
  WHEN 254465 THEN 1.0
  WHEN 254466 THEN 1.0
  WHEN 254467 THEN 1.0
  WHEN 254468 THEN 1.0
  WHEN 254471 THEN 1.0
  WHEN 254472 THEN 1.0
  WHEN 254473 THEN 1.0
  WHEN 254474 THEN 0.5
  WHEN 254480 THEN 1.0
  WHEN 254484 THEN 1.0
  WHEN 254486 THEN 1.0
  WHEN 254488 THEN 1.0
  WHEN 254489 THEN 1.0
  WHEN 254491 THEN 1.0
  WHEN 254493 THEN 1.0
  WHEN 254494 THEN 1.0
  WHEN 254496 THEN 1.0
  WHEN 254497 THEN 1.0
  WHEN 254498 THEN 1.0
  WHEN 254499 THEN 1.0
  WHEN 254502 THEN 1.0
  WHEN 254503 THEN 1.0
  WHEN 254504 THEN 1.0
  WHEN 254505 THEN 1.0
  WHEN 254507 THEN 1.0
  WHEN 254516 THEN 1.0
  WHEN 254518 THEN 1.0
  WHEN 254520 THEN 1.0
  WHEN 254521 THEN 1.0
  WHEN 254539 THEN 1.0
  WHEN 254540 THEN 1.0
  WHEN 254541 THEN 1.0
  WHEN 254542 THEN 1.0
  WHEN 254543 THEN 1.0
  WHEN 254544 THEN 1.0
  WHEN 254545 THEN 1.0
  WHEN 254546 THEN 1.0
  WHEN 254547 THEN 1.0
  WHEN 254548 THEN 1.0
  WHEN 254549 THEN 1.0
  WHEN 254550 THEN 1.0
  WHEN 254551 THEN 1.0
  WHEN 254553 THEN 1.0
  WHEN 254554 THEN 1.0
  WHEN 254555 THEN 1.0
  WHEN 254556 THEN 1.0
  WHEN 254557 THEN 1.0
  WHEN 254558 THEN 1.0
  WHEN 254560 THEN 1.3
  WHEN 254561 THEN 1.0
  WHEN 254562 THEN 1.0
  WHEN 254563 THEN 1.0
  WHEN 254564 THEN 1.0
  WHEN 254565 THEN 1.0
  WHEN 254571 THEN 1.0
  WHEN 254572 THEN 1.0
  WHEN 254573 THEN 1.0
  WHEN 254575 THEN 1.0
  WHEN 254577 THEN 1.0
  WHEN 254578 THEN 1.0
  WHEN 254580 THEN 1.0
  WHEN 254581 THEN 1.0
  WHEN 254582 THEN 1.0
  WHEN 254583 THEN 1.0
  WHEN 254617 THEN 1.0
  WHEN 254618 THEN 1.0
  WHEN 254628 THEN 1.0
  WHEN 254630 THEN 1.0
  WHEN 254631 THEN 1.0
  WHEN 254633 THEN 1.0
  WHEN 254638 THEN 1.0
  WHEN 254642 THEN 1.0
  WHEN 254644 THEN 1.0
  WHEN 254645 THEN 1.0
  WHEN 254647 THEN 1.0
  WHEN 254648 THEN 1.0
  WHEN 254649 THEN 1.0
  WHEN 254650 THEN 1.0
  WHEN 254652 THEN 1.0
  WHEN 254653 THEN 1.0
  WHEN 254654 THEN 1.0
  WHEN 254655 THEN 1.0
  WHEN 254656 THEN 1.0
  WHEN 254657 THEN 1.0
  WHEN 254658 THEN 1.0
  WHEN 254659 THEN 1.0
  WHEN 254660 THEN 1.0
  WHEN 254661 THEN 1.0
  WHEN 254663 THEN 1.0
  WHEN 254664 THEN 1.4
  WHEN 254665 THEN 1.0
  WHEN 254666 THEN 1.0
  WHEN 254667 THEN 1.0
  WHEN 254668 THEN 1.0
  WHEN 254676 THEN 1.0
  WHEN 300010 THEN 1.0
  WHEN 300011 THEN 1.0
  WHEN 300017 THEN 1.0
  WHEN 300028 THEN 1.0
  WHEN 324495 THEN 1.0
  WHEN 324505 THEN 1.0
  WHEN 324506 THEN 1.0
  WHEN 324507 THEN 1.0
  WHEN 324510 THEN 1.0
  WHEN 340042 THEN 1.0
  WHEN 340043 THEN 1.0
  WHEN 340044 THEN 1.0
  WHEN 340047 THEN 1.0
  WHEN 340053 THEN 1.0
  WHEN 340061 THEN 1.0
  WHEN 340068 THEN 1.0
  WHEN 340098 THEN 1.0
  WHEN 340099 THEN 1.0
  WHEN 340110 THEN 1.0
  WHEN 340111 THEN 1.0
  WHEN 340112 THEN 1.0
  WHEN 340113 THEN 1.0
  WHEN 340114 THEN 1.0
  WHEN 340115 THEN 1.0
  WHEN 340117 THEN 1.0
  WHEN 340118 THEN 1.0
  WHEN 340120 THEN 1.0
  WHEN 340122 THEN 1.0
  WHEN 340123 THEN 1.0
  WHEN 340125 THEN 1.0
  WHEN 340126 THEN 1.0
  WHEN 340127 THEN 1.0
  WHEN 340132 THEN 1.0
  WHEN 341060 THEN 1.0
  WHEN 356431 THEN 1.0
  WHEN 356432 THEN 1.0
  WHEN 356433 THEN 1.0
  WHEN 356434 THEN 1.0
  WHEN 356435 THEN 1.0
  WHEN 356436 THEN 1.0
  WHEN 356439 THEN 1.0
  WHEN 356440 THEN 1.0
  WHEN 356443 THEN 1.0
  WHEN 357440 THEN 0.5
  WHEN 375003 THEN 1.0
  WHEN 375005 THEN 1.0
  WHEN 375024 THEN 1.0
  WHEN 375131 THEN 1.0
  WHEN 375231 THEN 1.0
  WHEN 375327 THEN 1.0
  WHEN 387849 THEN 1.0
  WHEN 387850 THEN 1.0
  WHEN 387852 THEN 1.0
  WHEN 387854 THEN 1.0
  WHEN 387866 THEN 1.0
  WHEN 387867 THEN 1.0
  WHEN 387868 THEN 1.0
  WHEN 387869 THEN 1.0
  WHEN 387870 THEN 1.0
  WHEN 387872 THEN 1.0
  WHEN 387875 THEN 1.0
  WHEN 387876 THEN 1.0
  WHEN 387877 THEN 1.0
  WHEN 387878 THEN 1.0
  WHEN 387881 THEN 1.0
  WHEN 387882 THEN 1.0
  WHEN 515039 THEN 1.0
  WHEN 515089 THEN 1.0
  WHEN 515224 THEN 1.0
  WHEN 515345 THEN 1.0
  WHEN 515362 THEN 1.0
  WHEN 515365 THEN 1.0
  WHEN 515366 THEN 1.0
  WHEN 515367 THEN 1.0
  WHEN 515369 THEN 1.0
  WHEN 515370 THEN 1.0
  WHEN 515372 THEN 1.0
  WHEN 515375 THEN 1.0
  WHEN 515376 THEN 1.0
  WHEN 515378 THEN 1.0
  WHEN 515379 THEN 1.0
  WHEN 515380 THEN 1.0
  WHEN 515383 THEN 1.0
  WHEN 515384 THEN 1.0
  WHEN 515385 THEN 1.0
  WHEN 515386 THEN 1.0
  WHEN 515387 THEN 1.0
  WHEN 515388 THEN 1.0
  WHEN 515390 THEN 0.35
  WHEN 515392 THEN 1.0
  WHEN 515395 THEN 1.4
  WHEN 515396 THEN 1.0
  WHEN 515397 THEN 1.0
  WHEN 515398 THEN 1.0
  WHEN 515400 THEN 1.0
  WHEN 515402 THEN 1.0
  WHEN 515403 THEN 1.0
  WHEN 515404 THEN 1.0
  WHEN 515405 THEN 1.0
  WHEN 515406 THEN 1.0
  WHEN 515407 THEN 1.0
  WHEN 515408 THEN 1.0
  WHEN 515409 THEN 1.0
  WHEN 515425 THEN 1.0
  WHEN 515429 THEN 1.5
  WHEN 515431 THEN 1.0
  WHEN 515432 THEN 1.0
  WHEN 515433 THEN 1.0
  WHEN 515434 THEN 1.0
  WHEN 515435 THEN 1.0
  WHEN 515437 THEN 1.0
  WHEN 515438 THEN 1.0
  WHEN 515439 THEN 1.0
  WHEN 515440 THEN 1.0
  WHEN 515441 THEN 1.0
  WHEN 515442 THEN 2.0
  WHEN 515444 THEN 1.3
  WHEN 515466 THEN 1.0
  WHEN 515470 THEN 1.0
  WHEN 515502 THEN 0.65
  WHEN 515503 THEN 1.0
  WHEN 515504 THEN 1.0
  WHEN 515505 THEN 1.0
  WHEN 515506 THEN 1.0
  WHEN 515508 THEN 1.0
  WHEN 515511 THEN 1.0
  WHEN 515512 THEN 1.0
  WHEN 515513 THEN 1.0
  WHEN 515514 THEN 1.0
  WHEN 515518 THEN 0.7
  WHEN 515519 THEN 1.0
  WHEN 515520 THEN 0.5
  WHEN 515524 THEN 1.0
  WHEN 515525 THEN 1.0
  WHEN 515528 THEN 1.0
  WHEN 515529 THEN 1.0
  WHEN 515530 THEN 1.0
  WHEN 515531 THEN 0.6
  WHEN 515532 THEN 1.0
  WHEN 515533 THEN 1.2
  WHEN 515534 THEN 1.0
  WHEN 515535 THEN 1.0
  WHEN 515536 THEN 1.0
  WHEN 515537 THEN 1.0
  WHEN 515539 THEN 1.0
  WHEN 515540 THEN 2.0
  WHEN 515542 THEN 1.0
  WHEN 515571 THEN 2.0
  WHEN 515596 THEN 1.0
  WHEN 515600 THEN 1.0
  WHEN 515613 THEN 1.0
  WHEN 515723 THEN 1.0
  WHEN 515727 THEN 1.0
  WHEN 515739 THEN 1.0
  WHEN 515740 THEN 1.0
  WHEN 515741 THEN 1.0
  WHEN 515742 THEN 1.0
  WHEN 515743 THEN 1.0
  WHEN 515744 THEN 1.0
  WHEN 515745 THEN 1.0
  WHEN 515747 THEN 1.0
  WHEN 515748 THEN 1.0
  WHEN 515750 THEN 1.0
  WHEN 515755 THEN 1.0
  WHEN 515764 THEN 1.0
  WHEN 515767 THEN 1.0
  WHEN 515769 THEN 1.0
  WHEN 515770 THEN 1.0
  WHEN 515771 THEN 1.0
  WHEN 515772 THEN 1.0
  WHEN 515773 THEN 1.0
  WHEN 515775 THEN 1.0
  WHEN 515781 THEN 1.0
  WHEN 515782 THEN 1.0
  WHEN 515783 THEN 1.0
  WHEN 515791 THEN 1.0
  WHEN 515797 THEN 1.0
  WHEN 515798 THEN 1.0
  WHEN 515800 THEN 1.0
  WHEN 515801 THEN 1.0
  WHEN 515822 THEN 1.0
  WHEN 515823 THEN 1.0
  WHEN 515824 THEN 1.0
  WHEN 515825 THEN 1.0
  WHEN 515826 THEN 1.0
  WHEN 515827 THEN 1.0
  WHEN 515828 THEN 1.0
  WHEN 515829 THEN 1.0
  WHEN 515830 THEN 1.0
  WHEN 515834 THEN 1.0
  WHEN 515835 THEN 1.0
  WHEN 515836 THEN 1.0
  WHEN 515837 THEN 1.0
  WHEN 515838 THEN 1.0
  WHEN 515839 THEN 1.0
  WHEN 515840 THEN 1.0
  WHEN 515841 THEN 1.0
  WHEN 515842 THEN 1.0
  WHEN 515843 THEN 1.0
  WHEN 515844 THEN 1.0
  WHEN 515845 THEN 1.0
  WHEN 515846 THEN 1.0
  WHEN 515849 THEN 1.0
  WHEN 515853 THEN 1.0
  WHEN 515863 THEN 1.0
  WHEN 515864 THEN 1.0
  WHEN 515865 THEN 1.0
  WHEN 515866 THEN 1.0
  WHEN 515877 THEN 1.0
  WHEN 515878 THEN 1.0
  WHEN 515880 THEN 1.0
  WHEN 515884 THEN 1.0
  WHEN 515887 THEN 1.0
  WHEN 515900 THEN 1.0
  WHEN 515901 THEN 1.0
  WHEN 515902 THEN 1.0
  WHEN 515903 THEN 1.0
  WHEN 515904 THEN 1.0
  WHEN 515906 THEN 1.0
  WHEN 515909 THEN 1.0
  WHEN 515910 THEN 1.0
  WHEN 515916 THEN 1.0
  WHEN 515918 THEN 1.0
  WHEN 515919 THEN 1.0
  WHEN 515920 THEN 1.0
  WHEN 515921 THEN 1.0
  WHEN 515922 THEN 1.0
  WHEN 515923 THEN 1.0
  WHEN 515941 THEN 1.0
  WHEN 515942 THEN 1.0
  WHEN 515943 THEN 1.0
  WHEN 515944 THEN 1.0
  WHEN 515945 THEN 1.0
  WHEN 515946 THEN 1.0
  WHEN 515947 THEN 1.0
  WHEN 515948 THEN 1.0
  WHEN 515949 THEN 1.0
  WHEN 515950 THEN 1.0
  WHEN 515951 THEN 1.0
  WHEN 515952 THEN 1.0
  WHEN 515958 THEN 1.0
  WHEN 517202 THEN 1.0
  WHEN 517204 THEN 1.0
  WHEN 517210 THEN 1.0
  WHEN 517223 THEN 1.0
  WHEN 517224 THEN 1.0
  WHEN 517225 THEN 1.0
  WHEN 517232 THEN 1.0
  WHEN 517233 THEN 1.0
  WHEN 517234 THEN 1.0
  WHEN 517235 THEN 1.0
  WHEN 517237 THEN 1.0
  WHEN 517242 THEN 1.0
  WHEN 517254 THEN 1.0
  WHEN 517257 THEN 1.0
  WHEN 517261 THEN 1.0
  WHEN 517263 THEN 1.0
  WHEN 517271 THEN 1.0
  WHEN 517272 THEN 1.0
  WHEN 517273 THEN 1.0
  WHEN 517274 THEN 1.0
  WHEN 517275 THEN 1.0
  WHEN 517276 THEN 1.0
  WHEN 517277 THEN 1.0
  WHEN 517295 THEN 1.0
  WHEN 517314 THEN 1.0
  WHEN 517316 THEN 1.0
  WHEN 517317 THEN 1.0
  WHEN 517322 THEN 1.0
  WHEN 517323 THEN 1.0
  WHEN 517324 THEN 1.0
  WHEN 517325 THEN 1.0
  WHEN 517330 THEN 1.0
  WHEN 517331 THEN 1.0
  WHEN 517336 THEN 1.0
  WHEN 517338 THEN 1.0
  WHEN 517340 THEN 1.0
  WHEN 517341 THEN 0.65
  WHEN 517342 THEN 1.0
  WHEN 517347 THEN 1.0
  WHEN 517349 THEN 1.0
  WHEN 517351 THEN 1.0
  WHEN 517352 THEN 1.0
  WHEN 517353 THEN 1.0
  WHEN 517354 THEN 1.0
  WHEN 517356 THEN 1.0
  WHEN 517357 THEN 1.0
  WHEN 517359 THEN 1.0
  WHEN 517364 THEN 1.0
  WHEN 517366 THEN 1.0
  WHEN 517367 THEN 1.0
  WHEN 517371 THEN 1.0
  WHEN 518000 THEN 1.0
  WHEN 518006 THEN 1.0
  WHEN 518009 THEN 1.0
  WHEN 518010 THEN 1.0
  WHEN 518011 THEN 1.0
  WHEN 518016 THEN 1.0
  WHEN 518030 THEN 1.0
  WHEN 518045 THEN 1.0
  WHEN 518048 THEN 1.0
  WHEN 518051 THEN 1.0
  WHEN 518052 THEN 1.0
  WHEN 518053 THEN 1.0
  WHEN 518054 THEN 1.0
  WHEN 518060 THEN 1.0
  WHEN 518063 THEN 1.0
  WHEN 518082 THEN 1.0
  WHEN 518086 THEN 1.0
  WHEN 518087 THEN 1.0
  WHEN 518097 THEN 1.0
  WHEN 518098 THEN 1.0
  WHEN 518099 THEN 1.0
  WHEN 518102 THEN 1.0
  WHEN 518123 THEN 1.0
  WHEN 518139 THEN 1.0
  WHEN 518140 THEN 1.0
  WHEN 518144 THEN 1.0
  WHEN 518147 THEN 1.0
  WHEN 518149 THEN 1.0
  WHEN 518153 THEN 1.0
  WHEN 518162 THEN 1.0
  WHEN 518166 THEN 1.0
  WHEN 518171 THEN 1.0
  WHEN 518172 THEN 1.0
  WHEN 518174 THEN 1.0
  WHEN 518300 THEN 1.0
  WHEN 518301 THEN 1.0
  WHEN 518302 THEN 1.0
  WHEN 518303 THEN 1.0
  WHEN 518305 THEN 1.0
  WHEN 518311 THEN 1.0
  WHEN 518315 THEN 1.0
  WHEN 518316 THEN 1.0
  WHEN 518317 THEN 1.0
  WHEN 518318 THEN 1.0
  WHEN 518319 THEN 1.0
  WHEN 518321 THEN 1.0
  WHEN 518322 THEN 1.0
  WHEN 518342 THEN 1.0
  WHEN 518344 THEN 1.0
  WHEN 518345 THEN 1.0
  WHEN 518346 THEN 1.0
  WHEN 518348 THEN 1.0
  WHEN 518354 THEN 1.0
  WHEN 518372 THEN 1.0
  WHEN 518456 THEN 1.0
  WHEN 518460 THEN 1.0
  WHEN 518461 THEN 1.0
  WHEN 518462 THEN 1.0
  WHEN 518466 THEN 1.0
  WHEN 518562 THEN 1.0
  WHEN 518564 THEN 1.0
  WHEN 518567 THEN 1.0
  WHEN 518568 THEN 1.0
  WHEN 518569 THEN 1.0
  WHEN 518573 THEN 1.0
  WHEN 518574 THEN 1.0
  WHEN 518575 THEN 1.0
  WHEN 518576 THEN 1.0
  WHEN 518577 THEN 1.0
  WHEN 518578 THEN 1.0
  WHEN 518579 THEN 1.0
  WHEN 518582 THEN 1.0
  WHEN 518583 THEN 1.0
  WHEN 518584 THEN 1.0
  WHEN 518586 THEN 1.0
  WHEN 518788 THEN 1.0
  WHEN 518894 THEN 1.0
  WHEN 520018 THEN 1.0
  WHEN 520047 THEN 1.0
  WHEN 520055 THEN 1.0
  WHEN 520063 THEN 1.0
  WHEN 520064 THEN 1.0
  WHEN 520065 THEN 1.0
  WHEN 520066 THEN 1.0
  WHEN 520067 THEN 1.0
  WHEN 520068 THEN 1.0
  WHEN 520069 THEN 1.0
  WHEN 520072 THEN 1.0
  WHEN 520073 THEN 1.0
  WHEN 520696 THEN 1.0
  WHEN 520697 THEN 1.0
  WHEN 520698 THEN 1.0
  WHEN 520699 THEN 1.0
  WHEN 520700 THEN 1.0
  WHEN 520701 THEN 1.0
  WHEN 520702 THEN 1.0
  WHEN 520703 THEN 1.0
  WHEN 520704 THEN 1.0
  WHEN 638836 THEN 1.0
  WHEN 654637 THEN 0.5
  WHEN 686868 THEN 1.0
  WHEN 686869 THEN 1.0
  WHEN 686871 THEN 1.0
  WHEN 686877 THEN 1.0
  WHEN 686878 THEN 1.0
  WHEN 686880 THEN 1.0
  WHEN 686887 THEN 1.0
  WHEN 686888 THEN 1.0
  WHEN 686889 THEN 1.0
  WHEN 686891 THEN 1.0
  WHEN 686898 THEN 1.0
  WHEN 686899 THEN 1.0
  WHEN 686906 THEN 1.0
  WHEN 686907 THEN 1.0
  WHEN 686908 THEN 1.0
  WHEN 686909 THEN 1.0
  WHEN 686913 THEN 1.0
  WHEN 686914 THEN 1.0
  WHEN 686918 THEN 1.0
  WHEN 686919 THEN 1.0
  WHEN 686920 THEN 1.0
  WHEN 686922 THEN 1.0
  WHEN 686930 THEN 1.0
  WHEN 686935 THEN 1.0
  WHEN 686936 THEN 1.0
  WHEN 735902 THEN 1.0
  WHEN 735924 THEN 1.0
  WHEN 836218 THEN 1.0
  WHEN 1344099 THEN 0.7
  WHEN 1344801 THEN 0.7
  WHEN 1344803 THEN 1.0
  WHEN 1546304 THEN 1.0
  WHEN 1800962 THEN 1.0
  WHEN 2100094 THEN 1.0
  ELSE `size` END
WHERE `entry` IN (63143, 66601, 67241, 67261, 67262, 68369, 68371, 68374, 68376, 68379, 68381, 68394, 68399, 68403, 68406, 68410, 68428, 68430, 68434, 86168, 86169, 86171, 89640, 90043, 90214, 90215, 90216, 90217, 90218, 90219, 90220, 90221, 90223, 90224, 90228, 90234, 90235, 90236, 90237, 90240, 90241, 90242, 90243, 90245, 90246, 90247, 90248, 90249, 90250, 90251, 90253, 90254, 90255, 90256, 90261, 90263, 90264, 90265, 90266, 90270, 90272, 90274, 90275, 90276, 90277, 90279, 90280, 90281, 90282, 90283, 90286, 90287, 90290, 90292, 90293, 90294, 90295, 90296, 90302, 90303, 90304, 90306, 90308, 90310, 90311, 90312, 90313, 90314, 90316, 90320, 90322, 90325, 90328, 90331, 90336, 90338, 90339, 90340, 90341, 90346, 90347, 90354, 90356, 90361, 90372, 90373, 90375, 90378, 90379, 90380, 90383, 90385, 90388, 90389, 90390, 90391, 90392, 90393, 90396, 90412, 90421, 90423, 90429, 90478, 90479, 90480, 90484, 90486, 90489, 90492, 90493, 90497, 90498, 90501, 90502, 90508, 90509, 90519, 90527, 90529, 90530, 90531, 90532, 90534, 90546, 90551, 90552, 90553, 90554, 90557, 90559, 90560, 90562, 90563, 90564, 90565, 90579, 90583, 90586, 90589, 90591, 90594, 90598, 90606, 90611, 90612, 90614, 90615, 90617, 90619, 90620, 90621, 90623, 90625, 90626, 90627, 90636, 93000, 95500, 95501, 95502, 95503, 95504, 95505, 95506, 95507, 95508, 95509, 95510, 95511, 95513, 95514, 95516, 95518, 95521, 95522, 95523, 95524, 95525, 95526, 95527, 95530, 95533, 95534, 95535, 95536, 95537, 95538, 95539, 95602, 95603, 95604, 95605, 95606, 95609, 95610, 95612, 95613, 95614, 95615, 95616, 95617, 95618, 95619, 95622, 95623, 95625, 95626, 95628, 95631, 95635, 95636, 95637, 95639, 95640, 95641, 95642, 95643, 95646, 95647, 95648, 95650, 95651, 95653, 95654, 95655, 95656, 95659, 95661, 95662, 95666, 95668, 95670, 95671, 95673, 95677, 95678, 95679, 95681, 95683, 95687, 95688, 95690, 95691, 95693, 95694, 95695, 95697, 95698, 95700, 95706, 95709, 95710, 95711, 95712, 95713, 95714, 95717, 95719, 95720, 95721, 95722, 95723, 95724, 95725, 95726, 95728, 95730, 95731, 95732, 95734, 95737, 95738, 95739, 95740, 95741, 95742, 95743, 95744, 95745, 95746, 95747, 95749, 95751, 95752, 95754, 95756, 95758, 95759, 95760, 95764, 95765, 95767, 95777, 95778, 95780, 95781, 95782, 95783, 95784, 95785, 95786, 95788, 95789, 95790, 95791, 95792, 95793, 95794, 95795, 95796, 95797, 95798, 95803, 95804, 95805, 95806, 95808, 95809, 95810, 95811, 95812, 95813, 95814, 95816, 95817, 95818, 95820, 95822, 95823, 95824, 95825, 95826, 95830, 95831, 95833, 95834, 95835, 95836, 95837, 95838, 95839, 95840, 95841, 95842, 95843, 95844, 95846, 95848, 95849, 95850, 95853, 95854, 95855, 95856, 95857, 95858, 95859, 95860, 95861, 95862, 95863, 95864, 95865, 95866, 95867, 95870, 95872, 95874, 95875, 95876, 95877, 95880, 95881, 95882, 95883, 95884, 95885, 95887, 95889, 95890, 95891, 95892, 95893, 95894, 95895, 95896, 95897, 95898, 95899, 95900, 95901, 95902, 95903, 95904, 95906, 95907, 95908, 95909, 95910, 95911, 95912, 95915, 95916, 95917, 95918, 95919, 95920, 95921, 95922, 95923, 95924, 95925, 95926, 95927, 95928, 95929, 95930, 95931, 95932, 95933, 95934, 95935, 95936, 95937, 95938, 95939, 95940, 95941, 95942, 95943, 95945, 95946, 95947, 95948, 96101, 96102, 96103, 96104, 96105, 96106, 96108, 96109, 96110, 96112, 96113, 96114, 96115, 96116, 96117, 96118, 96119, 96120, 96122, 96123, 96124, 96125, 96126, 96127, 96128, 96130, 96131, 96132, 96133, 96134, 96135, 96136, 96137, 96138, 96139, 96140, 96141, 96142, 96143, 96144, 96145, 96146, 96147, 96148, 96150, 96151, 96152, 96153, 96155, 96156, 96157, 96158, 96159, 96161, 96162, 96167, 96168, 96169, 96173, 96174, 96175, 96176, 96177, 96178, 96179, 96180, 96181, 96182, 96183, 96184, 96185, 96186, 96188, 96189, 96190, 96191, 96192, 96193, 96194, 96195, 96196, 96197, 96198, 96199, 96200, 96201, 96202, 96203, 96204, 96205, 96206, 96207, 96208, 96209, 96210, 96211, 96212, 96213, 96214, 96215, 96216, 96217, 96218, 96219, 96220, 96221, 96222, 96223, 96224, 96226, 96228, 96229, 96232, 96233, 96234, 96235, 96236, 96239, 96240, 96241, 96243, 96244, 96246, 96247, 96248, 97101, 97102, 97103, 97104, 97107, 97108, 97109, 97111, 97112, 97113, 97114, 97115, 97116, 97117, 97118, 97120, 97121, 97123, 97124, 97125, 97126, 97127, 97128, 97129, 97130, 97131, 97132, 97133, 97134, 97135, 97136, 97137, 142102, 142109, 150900, 158300, 158305, 158307, 158309, 158313, 158316, 158319, 158320, 158321, 158328, 158330, 158333, 159984, 159985, 159997, 184133, 184134, 254026, 254156, 254163, 254164, 254165, 254166, 254172, 254176, 254178, 254194, 254221, 254222, 254223, 254225, 254227, 254228, 254229, 254231, 254232, 254233, 254234, 254235, 254236, 254237, 254238, 254240, 254255, 254258, 254259, 254260, 254261, 254263, 254264, 254265, 254266, 254267, 254268, 254269, 254270, 254271, 254272, 254273, 254275, 254276, 254278, 254279, 254280, 254281, 254282, 254283, 254284, 254285, 254286, 254287, 254289, 254290, 254292, 254295, 254296, 254297, 254298, 254299, 254300, 254301, 254302, 254303, 254304, 254305, 254306, 254307, 254309, 254310, 254311, 254312, 254313, 254314, 254318, 254320, 254321, 254322, 254323, 254324, 254325, 254326, 254327, 254328, 254329, 254330, 254334, 254335, 254337, 254338, 254339, 254340, 254341, 254342, 254343, 254345, 254346, 254347, 254348, 254349, 254350, 254351, 254353, 254354, 254363, 254364, 254365, 254366, 254367, 254369, 254370, 254372, 254373, 254374, 254375, 254376, 254377, 254378, 254379, 254380, 254381, 254382, 254383, 254384, 254385, 254386, 254387, 254388, 254389, 254390, 254391, 254393, 254394, 254395, 254396, 254398, 254399, 254401, 254402, 254404, 254405, 254410, 254411, 254412, 254413, 254414, 254415, 254416, 254417, 254418, 254419, 254420, 254425, 254429, 254430, 254434, 254436, 254437, 254438, 254439, 254442, 254443, 254444, 254446, 254448, 254449, 254450, 254453, 254455, 254456, 254457, 254458, 254459, 254462, 254463, 254464, 254465, 254466, 254467, 254468, 254471, 254472, 254473, 254474, 254480, 254484, 254486, 254488, 254489, 254491, 254493, 254494, 254496, 254497, 254498, 254499, 254502, 254503, 254504, 254505, 254507, 254516, 254518, 254520, 254521, 254539, 254540, 254541, 254542, 254543, 254544, 254545, 254546, 254547, 254548, 254549, 254550, 254551, 254553, 254554, 254555, 254556, 254557, 254558, 254560, 254561, 254562, 254563, 254564, 254565, 254571, 254572, 254573, 254575, 254577, 254578, 254580, 254581, 254582, 254583, 254617, 254618, 254628, 254630, 254631, 254633, 254638, 254642, 254644, 254645, 254647, 254648, 254649, 254650, 254652, 254653, 254654, 254655, 254656, 254657, 254658, 254659, 254660, 254661, 254663, 254664, 254665, 254666, 254667, 254668, 254676, 300010, 300011, 300017, 300028, 324495, 324505, 324506, 324507, 324510, 340042, 340043, 340044, 340047, 340053, 340061, 340068, 340098, 340099, 340110, 340111, 340112, 340113, 340114, 340115, 340117, 340118, 340120, 340122, 340123, 340125, 340126, 340127, 340132, 341060, 356431, 356432, 356433, 356434, 356435, 356436, 356439, 356440, 356443, 357440, 375003, 375005, 375024, 375131, 375231, 375327, 387849, 387850, 387852, 387854, 387866, 387867, 387868, 387869, 387870, 387872, 387875, 387876, 387877, 387878, 387881, 387882, 515039, 515089, 515224, 515345, 515362, 515365, 515366, 515367, 515369, 515370, 515372, 515375, 515376, 515378, 515379, 515380, 515383, 515384, 515385, 515386, 515387, 515388, 515390, 515392, 515395, 515396, 515397, 515398, 515400, 515402, 515403, 515404, 515405, 515406, 515407, 515408, 515409, 515425, 515429, 515431, 515432, 515433, 515434, 515435, 515437, 515438, 515439, 515440, 515441, 515442, 515444, 515466, 515470, 515502, 515503, 515504, 515505, 515506, 515508, 515511, 515512, 515513, 515514, 515518, 515519, 515520, 515524, 515525, 515528, 515529, 515530, 515531, 515532, 515533, 515534, 515535, 515536, 515537, 515539, 515540, 515542, 515571, 515596, 515600, 515613, 515723, 515727, 515739, 515740, 515741, 515742, 515743, 515744, 515745, 515747, 515748, 515750, 515755, 515764, 515767, 515769, 515770, 515771, 515772, 515773, 515775, 515781, 515782, 515783, 515791, 515797, 515798, 515800, 515801, 515822, 515823, 515824, 515825, 515826, 515827, 515828, 515829, 515830, 515834, 515835, 515836, 515837, 515838, 515839, 515840, 515841, 515842, 515843, 515844, 515845, 515846, 515849, 515853, 515863, 515864, 515865, 515866, 515877, 515878, 515880, 515884, 515887, 515900, 515901, 515902, 515903, 515904, 515906, 515909, 515910, 515916, 515918, 515919, 515920, 515921, 515922, 515923, 515941, 515942, 515943, 515944, 515945, 515946, 515947, 515948, 515949, 515950, 515951, 515952, 515958, 517202, 517204, 517210, 517223, 517224, 517225, 517232, 517233, 517234, 517235, 517237, 517242, 517254, 517257, 517261, 517263, 517271, 517272, 517273, 517274, 517275, 517276, 517277, 517295, 517314, 517316, 517317, 517322, 517323, 517324, 517325, 517330, 517331, 517336, 517338, 517340, 517341, 517342, 517347, 517349, 517351, 517352, 517353, 517354, 517356, 517357, 517359, 517364, 517366, 517367, 517371, 518000, 518006, 518009, 518010, 518011, 518016, 518030, 518045, 518048, 518051, 518052, 518053, 518054, 518060, 518063, 518082, 518086, 518087, 518097, 518098, 518099, 518102, 518123, 518139, 518140, 518144, 518147, 518149, 518153, 518162, 518166, 518171, 518172, 518174, 518300, 518301, 518302, 518303, 518305, 518311, 518315, 518316, 518317, 518318, 518319, 518321, 518322, 518342, 518344, 518345, 518346, 518348, 518354, 518372, 518456, 518460, 518461, 518462, 518466, 518562, 518564, 518567, 518568, 518569, 518573, 518574, 518575, 518576, 518577, 518578, 518579, 518582, 518583, 518584, 518586, 518788, 518894, 520018, 520047, 520055, 520063, 520064, 520065, 520066, 520067, 520068, 520069, 520072, 520073, 520696, 520697, 520698, 520699, 520700, 520701, 520702, 520703, 520704, 638836, 654637, 686868, 686869, 686871, 686877, 686878, 686880, 686887, 686888, 686889, 686891, 686898, 686899, 686906, 686907, 686908, 686909, 686913, 686914, 686918, 686919, 686920, 686922, 686930, 686935, 686936, 735902, 735924, 836218, 1344099, 1344801, 1344803, 1546304, 1800962, 2100094);
