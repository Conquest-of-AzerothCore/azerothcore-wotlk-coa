-- ----------------------------------------------------------------------------
-- Worldforged pickups: the height the client recorded, and Elwynn's two missing
-- ----------------------------------------------------------------------------
-- HEIGHTS. The archive's dumps are the client's own sightings: an object, its map and
-- the world XYZ the client saw it at. A sighting of that same object standing within
-- twelve yards of where `2026_09_23_05_worldforged_map.sql` put it is the object's own
-- height, and it is the better answer wherever the terrain disagrees: an object inside
-- a cave or a tower is under (or over) the surface the terrain reader can see, so the
-- height it was recorded at is the only one of the two that is true. Every pickup that
-- differs from its own recording is stood on it here.
--   278 pickups, from 2483 the realm holds.
--
-- OBJECTS. Elwynn's page lists 71 worldforge props; the realm stands 69 of them at
-- those spots. The two it lacks are objects it has never had, and the archive holds the
-- realm's own client-cache records for both - entry, type, appearance, size and
-- Data0..Data23 exactly as the realm sent them, so nothing here is chosen:
--   Brother's Cherry Pie  90634, invisible chest, hands out Brother Danil's Cherry Pie
--                         (694540); the visible Cherry Pie prop (90635, display 5493)
--                         stands with it as it does at every other starter-zone pie.
--   Bloodied Axe          93008, a chest whose appearance is the axe itself (175455), at
--                         both spots the client recorded it at: Duskwood/Elwynn and
--                         Thousand Needles.
--
-- Idempotent: heights are set outright, and the two objects are cleared by their own
-- entries and guid range first. Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- The recorded height, one row per pickup. (guid, z, where the recording is)
UPDATE `gameobject` SET `position_z` = 365.271 WHERE `guid` = 6940004;  -- Abandoned Greatsword: -16.26, sighting 1.0 yd in LochModan
UPDATE `gameobject` SET `position_z` = 91.084 WHERE `guid` = 6940006;  -- Abandoned Hammer: +3.81, sighting 1.3 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 89.742 WHERE `guid` = 6940013;  -- Forgotten Sack: +1.55, sighting 3.2 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 408.375 WHERE `guid` = 6940016;  -- Forgotten Sack: +2.01, sighting 3.5 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 60.624 WHERE `guid` = 6940025;  -- Agamand Walking Stick: -33.10, sighting 2.4 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 12.164 WHERE `guid` = 6940030;  -- Alchemy Visceral Juice: +1.68, sighting 0.6 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 54.393 WHERE `guid` = 6940046;  -- Old Crate: +10.95, sighting 5.9 yd in Hilsbrad
UPDATE `gameobject` SET `position_z` = 34.598 WHERE `guid` = 6940049;  -- Stolen Lordaeron Jewel: +4.31, sighting 5.8 yd in Silverpine
UPDATE `gameobject` SET `position_z` = 230.110 WHERE `guid` = 6940084;  -- Spare Bow: -1.55, sighting 2.0 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = -109.893 WHERE `guid` = 6940090;  -- Atal'ai Alchemy Supplies: -129.42, sighting 0.3 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 35.749 WHERE `guid` = 6940101;  -- Bag of Folding: -20.53, sighting 2.7 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = 60.335 WHERE `guid` = 6940109;  -- Fallen Hero's Shield: -13.44, sighting 1.7 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = 141.916 WHERE `guid` = 6940111;  -- Crushridge Chest: -28.83, sighting 3.5 yd in Alterac
UPDATE `gameobject` SET `position_z` = 141.926 WHERE `guid` = 6940124;  -- Sulfurspike Hatchet: +1.43, sighting 5.1 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 61.566 WHERE `guid` = 6940126;  -- Blackrock Render: +2.49, sighting 2.7 yd in Redridge
UPDATE `gameobject` SET `position_z` = 193.016 WHERE `guid` = 6940143;  -- Blood Keeper's Staff: +20.62, sighting 5.6 yd in Arathi
UPDATE `gameobject` SET `position_z` = 116.802 WHERE `guid` = 6940145;  -- Blood-soaked Bag: -122.25, sighting 4.1 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = -31.509 WHERE `guid` = 6940162;  -- Barnacle-Crusted Boarder's Axe: +16.89, sighting 2.1 yd in Arathi
UPDATE `gameobject` SET `position_z` = 185.371 WHERE `guid` = 6940186;  -- Brightflame Codex: +35.36, sighting 2.7 yd in WesternPlaguelands
UPDATE `gameobject` SET `position_z` = 181.003 WHERE `guid` = 6940190;  -- Broken Chain: -195.41, sighting 1.7 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = 115.852 WHERE `guid` = 6940192;  -- Witherbark Chest: +22.32, sighting 5.6 yd in Hinterlands
UPDATE `gameobject` SET `position_z` = 89.414 WHERE `guid` = 6940203;  -- Burial Wraps: +7.14, sighting 2.0 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 131.364 WHERE `guid` = 6940208;  -- Draconic Chest: -31.93, sighting 0.7 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 28.152 WHERE `guid` = 6940210;  -- Butchery Blade: +2.80, sighting 11.6 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 125.428 WHERE `guid` = 6940211;  -- Oathblade: -13.61, sighting 6.7 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 25.312 WHERE `guid` = 6940214;  -- Mire Leaves: -1.40, sighting 4.0 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 48.625 WHERE `guid` = 6940218;  -- Caretaker's Burden: +1.28, sighting 4.0 yd in Arathi
UPDATE `gameobject` SET `position_z` = 156.379 WHERE `guid` = 6940222;  -- Casket Lid: +7.74, sighting 1.9 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 2.022 WHERE `guid` = 6940224;  -- Catacomb Grave Dirt Pile: -33.56, sighting 0.6 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 18.567 WHERE `guid` = 6940225;  -- Catacombs Relic Torch: -41.04, sighting 1.6 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 252.767 WHERE `guid` = 6940234;  -- Forgewright's Scepter: -284.01, sighting 3.3 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 169.524 WHERE `guid` = 6940237;  -- Stashed Shoulderpads: -29.74, sighting 9.9 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 213.904 WHERE `guid` = 6940239;  -- Free Sample: +37.34, sighting 9.8 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 361.824 WHERE `guid` = 6940247;  -- Miner's Pickaxe: -23.14, sighting 2.9 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 20.455 WHERE `guid` = 6940255;  -- Circle of Waves Idol: -28.53, sighting 3.5 yd in Arathi
UPDATE `gameobject` SET `position_z` = 448.564 WHERE `guid` = 6940257;  -- Claw of Vagash: -47.22, sighting 2.5 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 389.856 WHERE `guid` = 6940262;  -- Tundrid Supply Cabinet: -22.66, sighting 8.4 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 153.991 WHERE `guid` = 6940263;  -- Coldridge Crusher: +12.13, sighting 2.5 yd in Alterac
UPDATE `gameobject` SET `position_z` = 265.922 WHERE `guid` = 6940271;  -- Buried Chest: -16.70, sighting 11.8 yd in Badlands
UPDATE `gameobject` SET `position_z` = 48.451 WHERE `guid` = 6940272;  -- Silk Drape: +7.35, sighting 7.4 yd in Alterac
UPDATE `gameobject` SET `position_z` = 159.782 WHERE `guid` = 6940278;  -- Hanging Ogre Bag: -20.27, sighting 6.0 yd in Alterac
UPDATE `gameobject` SET `position_z` = 47.877 WHERE `guid` = 6940289;  -- Cursed Toy: +7.50, sighting 0.9 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 11.330 WHERE `guid` = 6940299;  -- Dark Iron Harvester: +2.28, sighting 1.9 yd in Wetlands
UPDATE `gameobject` SET `position_z` = 64.381 WHERE `guid` = 6940315;  -- Hidden Ring: +7.03, sighting 10.4 yd in Hilsbrad
UPDATE `gameobject` SET `position_z` = 87.914 WHERE `guid` = 6940325;  -- Deathstalker Cape: +8.01, sighting 4.2 yd in Hilsbrad
UPDATE `gameobject` SET `position_z` = 156.662 WHERE `guid` = 6940332;  -- Decayed Sharpshot: +26.86, sighting 1.3 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 43.785 WHERE `guid` = 6940340;  -- Defias Mage Stash: +1.07, sighting 1.1 yd in Westfall
UPDATE `gameobject` SET `position_z` = -2.545 WHERE `guid` = 6940351;  -- Defiled Necklace: +13.17, sighting 7.1 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 5.430 WHERE `guid` = 6940356;  -- Unstable Water Lodestone: +7.35, sighting 8.7 yd in Stranglethorn
UPDATE `gameobject` SET `position_z` = 185.571 WHERE `guid` = 6940359;  -- Dirt Mound: -87.48, sighting 0.2 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = -9.539 WHERE `guid` = 6940363;  -- Discharged Sawblade: -151.20, sighting 0.3 yd in BlastedLands
UPDATE `gameobject` SET `position_z` = 256.331 WHERE `guid` = 6940365;  -- Scoped Rifle: +16.32, sighting 3.2 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = 25.291 WHERE `guid` = 6940371;  -- Dockmaster's Stolen Supplies: +3.19, sighting 1.9 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 100.159 WHERE `guid` = 6940381;  -- Sacrificial Knife: +10.41, sighting 1.3 yd in BlastedLands
UPDATE `gameobject` SET `position_z` = 247.669 WHERE `guid` = 6940392;  -- Dusty Sack: -2.39, sighting 8.5 yd in Azeroth
UPDATE `gameobject` SET `position_z` = 51.389 WHERE `guid` = 6940401;  -- Sealed Barrel: -93.25, sighting 3.1 yd in Arathi
UPDATE `gameobject` SET `position_z` = 269.415 WHERE `guid` = 6940424;  -- Obsidian Axe: -194.91, sighting 3.6 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 147.376 WHERE `guid` = 6940427;  -- Embrace of the Fifth: -5.15, sighting 3.4 yd in Alterac
UPDATE `gameobject` SET `position_z` = 8.020 WHERE `guid` = 6940448;  -- Shadowsworn Staff: +1.87, sighting 2.6 yd in BlastedLands
UPDATE `gameobject` SET `position_z` = 29.139 WHERE `guid` = 6940450;  -- Exile's Amulet: +6.97, sighting 3.1 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 293.894 WHERE `guid` = 6940452;  -- Eye of Twilight: +6.80, sighting 3.0 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = 155.854 WHERE `guid` = 6940465;  -- Missing Alliance Supplies: -1.29, sighting 9.3 yd in Alterac
UPDATE `gameobject` SET `position_z` = 189.064 WHERE `guid` = 6940482;  -- Flamescale Equipment Cache: -73.32, sighting 8.3 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 10.947 WHERE `guid` = 6940496;  -- Foreman's Lightcap: -24.34, sighting 3.1 yd in Hilsbrad
UPDATE `gameobject` SET `position_z` = 122.468 WHERE `guid` = 6940504;  -- Fort Defender Band: +3.19, sighting 6.7 yd in Hinterlands
UPDATE `gameobject` SET `position_z` = 185.393 WHERE `guid` = 6940514;  -- Frostwatch Defender: +18.67, sighting 4.8 yd in Alterac
UPDATE `gameobject` SET `position_z` = 419.891 WHERE `guid` = 6940517;  -- Ice Beard's Furled Finger: -51.10, sighting 11.5 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 181.887 WHERE `guid` = 6940518;  -- Fungal Axe: +3.20, sighting 1.5 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 56.571 WHERE `guid` = 6940549;  -- Glinting Kobold Corpse: -148.89, sighting 1.9 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 417.764 WHERE `guid` = 6940551;  -- Glinting Necklace: -99.43, sighting 2.4 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 4.959 WHERE `guid` = 6940562;  -- Gorlash's Stash: -7.49, sighting 4.4 yd in Stranglethorn
UPDATE `gameobject` SET `position_z` = 73.698 WHERE `guid` = 6940567;  -- Rattlecage Cauldron: -4.07, sighting 8.0 yd in Tirisfal
UPDATE `gameobject` SET `position_z` = 354.133 WHERE `guid` = 6940588;  -- Hammerspine's Fallen Hammer: -65.20, sighting 1.5 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 29.568 WHERE `guid` = 6940615;  -- Heat Tempered Sword: -34.36, sighting 6.7 yd in Arathi
UPDATE `gameobject` SET `position_z` = 146.031 WHERE `guid` = 6940618;  -- Hercular's Unstable Orb: +1.47, sighting 3.4 yd in Alterac
UPDATE `gameobject` SET `position_z` = 129.727 WHERE `guid` = 6940648;  -- Pile of Bones: -223.83, sighting 4.1 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = 0.154 WHERE `guid` = 6940657;  -- Forgotten Dwarven Axe: -38.58, sighting 1.3 yd in Wetlands
UPDATE `gameobject` SET `position_z` = 41.898 WHERE `guid` = 6940664;  -- Jack's Toothpicker: dump_Duskwood records the object at 41.90, 16.6 yd off; the Defias Bandit 6 yd away stands at 41.37 and the Silverleaf 15 yd away at 41.52, and the pickup sat 2.5 yd under both
UPDATE `gameobject` SET `position_z` = 31.173 WHERE `guid` = 6940687;  -- Kurzen Eviscerator: +1.13, sighting 2.3 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 34.193 WHERE `guid` = 6940688;  -- Humming Blade: +1.31, sighting 6.9 yd in Stranglethorn
UPDATE `gameobject` SET `position_z` = 100.226 WHERE `guid` = 6940697;  -- Lexicon of Azora - Part I: Mage Inscript: +35.49, sighting 7.5 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 73.902 WHERE `guid` = 6940698;  -- Westfall Supply Cache: +38.12, sighting 11.5 yd in Westfall
UPDATE `gameobject` SET `position_z` = -17.252 WHERE `guid` = 6940700;  -- Ancient Formula: -157.04, sighting 2.4 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = 99.371 WHERE `guid` = 6940712;  -- Lookout Scope: +43.75, sighting 5.1 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 43.032 WHERE `guid` = 6940715;  -- Waterproof Trunk: -24.33, sighting 11.2 yd in Arathi
UPDATE `gameobject` SET `position_z` = 382.848 WHERE `guid` = 6940718;  -- Lost Adventurer's Ring: -135.46, sighting 1.9 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 115.455 WHERE `guid` = 6940739;  -- Scarlet Gavel: +14.73, sighting 10.9 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 16.290 WHERE `guid` = 6940744;  -- Marsh Bonebreaker: +6.89, sighting 4.9 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 137.336 WHERE `guid` = 6940759;  -- Incendosaur Tooth: -222.54, sighting 6.8 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = 197.751 WHERE `guid` = 6940760;  -- Collector's Shelves: -20.63, sighting 4.0 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 8.305 WHERE `guid` = 6940775;  -- Unique Pole: +3.73, sighting 10.8 yd in Redridge
UPDATE `gameobject` SET `position_z` = 140.961 WHERE `guid` = 6940791;  -- Empty Bag: -6.07, sighting 9.6 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 37.680 WHERE `guid` = 6940792;  -- Clothing Crate: +3.17, sighting 3.6 yd in Arathi
UPDATE `gameobject` SET `position_z` = -8.976 WHERE `guid` = 6940803;  -- Nethergarde Mining Cap: -134.61, sighting 0.7 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 30.475 WHERE `guid` = 6940810;  -- Nightshot: +3.47, sighting 1.9 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 414.356 WHERE `guid` = 6940817;  -- Officer's Pike: +8.02, sighting 0.6 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 310.548 WHERE `guid` = 6940826;  -- Ol' Blunderbuss: +25.63, sighting 1.4 yd in LochModan
UPDATE `gameobject` SET `position_z` = -14.101 WHERE `guid` = 6940876;  -- Peculiar Gold Nugget: -48.20, sighting 0.6 yd in Westfall
UPDATE `gameobject` SET `position_z` = 6.268 WHERE `guid` = 6940878;  -- Peculiar Root: -20.89, sighting 1.6 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 40.341 WHERE `guid` = 6940879;  -- People's Militia Stolen Badge: +2.67, sighting 0.9 yd in Westfall
UPDATE `gameobject` SET `position_z` = 68.929 WHERE `guid` = 6940888;  -- Plague Mask: +7.31, sighting 2.0 yd in WesternPlaguelands
UPDATE `gameobject` SET `position_z` = 274.270 WHERE `guid` = 6940908;  -- Precarious Treasure: +1.59, sighting 0.9 yd in Badlands
UPDATE `gameobject` SET `position_z` = 295.471 WHERE `guid` = 6940925;  -- Barbarian King's Circlet: -50.80, sighting 7.3 yd in Badlands
UPDATE `gameobject` SET `position_z` = 61.682 WHERE `guid` = 6940938;  -- Well Kept Hatchet: +6.86, sighting 10.8 yd in Hilsbrad
UPDATE `gameobject` SET `position_z` = 100.874 WHERE `guid` = 6940944;  -- Red Mage Wand: +43.91, sighting 1.9 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 65.601 WHERE `guid` = 6940949;  -- Reliever's Burden: -1.28, sighting 7.6 yd in WesternPlaguelands
UPDATE `gameobject` SET `position_z` = 151.007 WHERE `guid` = 6940966;  -- Lexicon of Azora - Part II: Warlock Ritu: +36.31, sighting 9.6 yd in Redridge
UPDATE `gameobject` SET `position_z` = 380.532 WHERE `guid` = 6940973;  -- Rocket Shrapnel: -8.80, sighting 1.4 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 0.311 WHERE `guid` = 6940980;  -- Rower's Footlocker: +6.67, sighting 2.6 yd in Westfall
UPDATE `gameobject` SET `position_z` = 0.846 WHERE `guid` = 6940982;  -- Ruby Skeletal Ring: -34.51, sighting 1.5 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 29.689 WHERE `guid` = 6940985;  -- Mojo's Chest: +21.74, sighting 3.6 yd in BlastedLands
UPDATE `gameobject` SET `position_z` = 36.695 WHERE `guid` = 6940993;  -- Sack of Defias Gear: -6.74, sighting 0.2 yd in Westfall
UPDATE `gameobject` SET `position_z` = 52.579 WHERE `guid` = 6940994;  -- Sack of Pine Seeds: +4.56, sighting 1.7 yd in Silverpine
UPDATE `gameobject` SET `position_z` = 101.104 WHERE `guid` = 6940996;  -- Safe Treasure No One Could Ever Reach: +16.69, sighting 0.3 yd in Arathi
UPDATE `gameobject` SET `position_z` = 70.420 WHERE `guid` = 6941012;  -- Cauterizing Needle: +1.23, sighting 11.1 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 289.769 WHERE `guid` = 6941026;  -- Scorched Greatblade: +12.70, sighting 2.2 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 165.914 WHERE `guid` = 6941029;  -- Runeblade: -25.38, sighting 4.2 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 52.700 WHERE `guid` = 6941033;  -- Fishing Box: +46.78, sighting 8.7 yd in WesternPlaguelands
UPDATE `gameobject` SET `position_z` = 165.803 WHERE `guid` = 6941042;  -- Taskmaster's Blade: +1.78, sighting 4.5 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 96.936 WHERE `guid` = 6941048;  -- Sentinel's Blade: +36.42, sighting 10.4 yd in Westfall
UPDATE `gameobject` SET `position_z` = 128.528 WHERE `guid` = 6941058;  -- Shadowpounce Cowl: +8.66, sighting 4.0 yd in Hinterlands
UPDATE `gameobject` SET `position_z` = -73.066 WHERE `guid` = 6941064;  -- Sharpened Dragon Bone: -90.91, sighting 0.3 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 34.623 WHERE `guid` = 6941067;  -- Shelf of Recipes: -144.04, sighting 1.8 yd in BlastedLands
UPDATE `gameobject` SET `position_z` = 147.735 WHERE `guid` = 6941071;  -- Shiny Kobold Treasure: +2.72, sighting 1.4 yd in Arathi
UPDATE `gameobject` SET `position_z` = -52.482 WHERE `guid` = 6941073;  -- Shoulderguards of the Ancient Prophet: -43.87, sighting 0.5 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 52.762 WHERE `guid` = 6941091;  -- Skippy's Bone: +6.32, sighting 5.0 yd in WesternPlaguelands
UPDATE `gameobject` SET `position_z` = 107.321 WHERE `guid` = 6941102;  -- Sludge Hammer: -38.96, sighting 10.8 yd in Hinterlands
UPDATE `gameobject` SET `position_z` = 183.610 WHERE `guid` = 6941105;  -- Blackrock Greataxe: +49.45, sighting 4.5 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 34.036 WHERE `guid` = 6941106;  -- Stolen Belongings: -6.19, sighting 1.5 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 346.859 WHERE `guid` = 6941109;  -- Snow Pile: -51.76, sighting 2.2 yd in DunMorogh
UPDATE `gameobject` SET `position_z` = 34.247 WHERE `guid` = 6941119;  -- Spare Bag: +6.81, sighting 0.5 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 245.248 WHERE `guid` = 6941125;  -- Extra Crate: -5.17, sighting 7.8 yd in Badlands
UPDATE `gameobject` SET `position_z` = 390.598 WHERE `guid` = 6941129;  -- Solid Chest: -17.14, sighting 6.6 yd in LochModan
UPDATE `gameobject` SET `position_z` = 187.402 WHERE `guid` = 6941131;  -- Pyrebloom Maul: +23.00, sighting 2.3 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 175.730 WHERE `guid` = 6941133;  -- Adventurer's Corpse: +8.61, sighting 3.3 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 41.019 WHERE `guid` = 6941136;  -- Splinterspear Armor Crate: +17.88, sighting 1.6 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = 233.715 WHERE `guid` = 6941144;  -- Steam Pressure Totem: -57.79, sighting 3.7 yd in SearingGorge
UPDATE `gameobject` SET `position_z` = 124.225 WHERE `guid` = 6941146;  -- Stolen Belt: -97.00, sighting 1.8 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 35.189 WHERE `guid` = 6941153;  -- Stolen Rot Hide Circlet: +3.59, sighting 0.6 yd in Silverpine
UPDATE `gameobject` SET `position_z` = 313.849 WHERE `guid` = 6941157;  -- Druidic Stone: +9.04, sighting 2.4 yd in Badlands
UPDATE `gameobject` SET `position_z` = 5.823 WHERE `guid` = 6941160;  -- Stonesplitter: -101.92, sighting 9.4 yd in Stranglethorn
UPDATE `gameobject` SET `position_z` = 153.830 WHERE `guid` = 6941163;  -- Stonewatch Chest: +17.14, sighting 5.7 yd in Redridge
UPDATE `gameobject` SET `position_z` = 75.404 WHERE `guid` = 6941170;  -- Stormguard: +7.34, sighting 9.0 yd in Arathi
UPDATE `gameobject` SET `position_z` = -74.779 WHERE `guid` = 6941177;  -- Sunken Axe: +1.58, sighting 1.5 yd in SwampOfSorrows
UPDATE `gameobject` SET `position_z` = 43.936 WHERE `guid` = 6941180;  -- Suspiciously Brown Discarded Pants: +4.11, sighting 11.3 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 389.198 WHERE `guid` = 6941185;  -- Sword of Stone: -23.35, sighting 10.8 yd in LochModan
UPDATE `gameobject` SET `position_z` = 226.432 WHERE `guid` = 6941200;  -- Tattered Fabric: -21.96, sighting 2.0 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 26.590 WHERE `guid` = 6941210;  -- The One Candle: -20.20, sighting 1.1 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 153.529 WHERE `guid` = 6941213;  -- The Final Strike: +1.85, sighting 2.8 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 13.686 WHERE `guid` = 6941214;  -- The Ironjaw: -155.62, sighting 2.8 yd in Stranglethorn
UPDATE `gameobject` SET `position_z` = 16.924 WHERE `guid` = 6941216;  -- Wine Bottle: -109.62, sighting 2.4 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = 31.498 WHERE `guid` = 6941222;  -- Box of Smoke Bombs: -7.15, sighting 10.9 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 87.691 WHERE `guid` = 6941239;  -- Thule's Curse Parchment: +26.68, sighting 2.4 yd in Silverpine
UPDATE `gameobject` SET `position_z` = 0.748 WHERE `guid` = 6941251;  -- Tiki Shield: +8.63, sighting 3.7 yd in Hinterlands
UPDATE `gameobject` SET `position_z` = 140.007 WHERE `guid` = 6941291;  -- Venerable Necklace: +8.82, sighting 3.2 yd in DeadwindPass
UPDATE `gameobject` SET `position_z` = 140.027 WHERE `guid` = 6941306;  -- Ashen Shield: +3.17, sighting 6.3 yd in BurningSteppes
UPDATE `gameobject` SET `position_z` = 148.953 WHERE `guid` = 6941323;  -- Praetorian Helmet: +41.18, sighting 7.0 yd in EasternPlaguelands
UPDATE `gameobject` SET `position_z` = 19.030 WHERE `guid` = 6941339;  -- Will in the Casket: -29.16, sighting 1.3 yd in Duskwood
UPDATE `gameobject` SET `position_z` = 89.908 WHERE `guid` = 6941353;  -- Worn Shovel: +2.95, sighting 2.0 yd in Elwynn
UPDATE `gameobject` SET `position_z` = 211.096 WHERE `guid` = 6941357;  -- Wyrmscale Spaulders: +1.33, sighting 7.5 yd in Wetlands
UPDATE `gameobject` SET `position_z` = 65.785 WHERE `guid` = 6941371;  -- Zul'Kunda Blood Ring: +5.51, sighting 3.3 yd in Stranglethorn
UPDATE `gameobject` SET `position_z` = 135.660 WHERE `guid` = 6941382;  -- Accursed Yeti Horn: +1.21, sighting 8.3 yd in Feralas
UPDATE `gameobject` SET `position_z` = 84.722 WHERE `guid` = 6941393;  -- Ambereye Amulet: -28.15, sighting 1.7 yd in Desolace
UPDATE `gameobject` SET `position_z` = -48.180 WHERE `guid` = 6941400;  -- Ancient Femur: -106.71, sighting 2.2 yd in Durotar
UPDATE `gameobject` SET `position_z` = -39.126 WHERE `guid` = 6941402;  -- Ancient Jar: -175.53, sighting 1.7 yd in Durotar
UPDATE `gameobject` SET `position_z` = 850.929 WHERE `guid` = 6941418;  -- Blue Dragon Crystal: +1.70, sighting 4.3 yd in Winterspring
UPDATE `gameobject` SET `position_z` = 155.776 WHERE `guid` = 6941432;  -- Dire Maul Belt: +64.11, sighting 2.7 yd in Kalimdor
UPDATE `gameobject` SET `position_z` = 415.814 WHERE `guid` = 6941438;  -- Embedded Claymore: +18.42, sighting 1.3 yd in Felwood
UPDATE `gameobject` SET `position_z` = -157.050 WHERE `guid` = 6941449;  -- Blaze Runners: +8.57, sighting 6.7 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 104.432 WHERE `guid` = 6941493;  -- Appropriated Goods: +98.17, sighting 10.3 yd in StonetalonMountains
UPDATE `gameobject` SET `position_z` = 63.294 WHERE `guid` = 6941496;  -- Bristleback Staff: -83.25, sighting 2.8 yd in Desolace
UPDATE `gameobject` SET `position_z` = 24.679 WHERE `guid` = 6941511;  -- Burning Blade Initiate's Stash: +2.17, sighting 2.3 yd in Durotar
UPDATE `gameobject` SET `position_z` = 63.508 WHERE `guid` = 6941514;  -- Burning Blade Ring: -60.20, sighting 2.2 yd in Durotar
UPDATE `gameobject` SET `position_z` = 95.127 WHERE `guid` = 6941516;  -- Crate of Mining Supplies: -27.00, sighting 2.0 yd in Desolace
UPDATE `gameobject` SET `position_z` = 41.690 WHERE `guid` = 6941520;  -- Moxie's Tool Bucket: +5.61, sighting 6.6 yd in Dustwallow
UPDATE `gameobject` SET `position_z` = 14.851 WHERE `guid` = 6941523;  -- Captain's Compass: +9.81, sighting 10.2 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 1398.270 WHERE `guid` = 6941543;  -- Carrion Eye: -66.35, sighting 1.2 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = 206.263 WHERE `guid` = 6941549;  -- Loose Barrel: -26.78, sighting 4.7 yd in Mulgore
UPDATE `gameobject` SET `position_z` = 751.862 WHERE `guid` = 6941559;  -- Frozen Mace: -164.69, sighting 3.5 yd in Winterspring
UPDATE `gameobject` SET `position_z` = -51.479 WHERE `guid` = 6941561;  -- Lost Supplies: +1.28, sighting 2.8 yd in Silithus
UPDATE `gameobject` SET `position_z` = -41.645 WHERE `guid` = 6941563;  -- Odd Silithid Larva: -115.86, sighting 1.9 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 34.063 WHERE `guid` = 6941565;  -- Cilkeck's Toolbox: +13.26, sighting 7.5 yd in Azshara
UPDATE `gameobject` SET `position_z` = 185.943 WHERE `guid` = 6941573;  -- Lion's Claws: -22.56, sighting 3.8 yd in Azshara
UPDATE `gameobject` SET `position_z` = 66.238 WHERE `guid` = 6941585;  -- Cord of Reverence: +2.03, sighting 2.2 yd in Mulgore
UPDATE `gameobject` SET `position_z` = 85.632 WHERE `guid` = 6941598;  -- Cursed Scepter: -32.27, sighting 11.5 yd in Barrens
UPDATE `gameobject` SET `position_z` = 1289.067 WHERE `guid` = 6941631;  -- Lazy Crossbow: +7.34, sighting 6.9 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = -255.565 WHERE `guid` = 6941633;  -- Protruding Bone: +5.04, sighting 1.5 yd in UngoroCrater
UPDATE `gameobject` SET `position_z` = 1.685 WHERE `guid` = 6941637;  -- Dirge of the Dead: +1.06, sighting 4.6 yd in Ashenvale
UPDATE `gameobject` SET `position_z` = 1438.790 WHERE `guid` = 6941641;  -- Disciple Bow: -18.35, sighting 1.8 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = 71.636 WHERE `guid` = 6941648;  -- Doomwarden: +7.62, sighting 4.2 yd in Desolace
UPDATE `gameobject` SET `position_z` = 105.780 WHERE `guid` = 6941654;  -- Drudger Smash: +27.23, sighting 9.1 yd in Barrens
UPDATE `gameobject` SET `position_z` = 8.927 WHERE `guid` = 6941657;  -- Dunemaul Champion Hammer: -1.07, sighting 4.0 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 10.144 WHERE `guid` = 6941682;  -- Moonwashed Bow: +15.20, sighting 3.1 yd in Azshara
UPDATE `gameobject` SET `position_z` = 94.469 WHERE `guid` = 6941685;  -- Embedded Claymore: +7.74, sighting 1.2 yd in Barrens
UPDATE `gameobject` SET `position_z` = -179.997 WHERE `guid` = 6941686;  -- Volcano Heated Crown: -25.22, sighting 4.9 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 35.347 WHERE `guid` = 6941692;  -- Emberscale Greatsword: -97.23, sighting 4.5 yd in Dustwallow
UPDATE `gameobject` SET `position_z` = 276.742 WHERE `guid` = 6941731;  -- Felhound Corpse: -1.15, sighting 10.8 yd in Felwood
UPDATE `gameobject` SET `position_z` = 258.514 WHERE `guid` = 6941742;  -- Flower of Tranquility: +21.26, sighting 4.9 yd in StonetalonMountains
UPDATE `gameobject` SET `position_z` = 434.005 WHERE `guid` = 6941753;  -- Freshly Brewed Potion: -145.87, sighting 1.5 yd in Felwood
UPDATE `gameobject` SET `position_z` = 1300.210 WHERE `guid` = 6941776;  -- Glinting Ring: -120.70, sighting 1.4 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = -331.585 WHERE `guid` = 6941786;  -- Hive Queen's Antenna: -125.52, sighting 2.5 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 114.325 WHERE `guid` = 6941788;  -- Large Bone: +1.64, sighting 8.2 yd in Feralas
UPDATE `gameobject` SET `position_z` = 77.046 WHERE `guid` = 6941791;  -- Greataxe of Kolk: -50.39, sighting 1.2 yd in Desolace
UPDATE `gameobject` SET `position_z` = 19.404 WHERE `guid` = 6941793;  -- Useful Potion: +8.19, sighting 10.7 yd in Dustwallow
UPDATE `gameobject` SET `position_z` = 215.879 WHERE `guid` = 6941797;  -- Grimtotem Club: -17.16, sighting 2.6 yd in Mulgore
UPDATE `gameobject` SET `position_z` = -65.403 WHERE `guid` = 6941808;  -- Hardened Scarab Gauntlets: -83.97, sighting 2.1 yd in Silithus
UPDATE `gameobject` SET `position_z` = 20.149 WHERE `guid` = 6941810;  -- Harpy Hunter: +11.63, sighting 8.3 yd in Durotar
UPDATE `gameobject` SET `position_z` = 134.812 WHERE `guid` = 6941812;  -- Hatefury Wand: +7.94, sighting 7.7 yd in Desolace
UPDATE `gameobject` SET `position_z` = 4.379 WHERE `guid` = 6941813;  -- Hatestrike: -42.37, sighting 5.9 yd in Feralas
UPDATE `gameobject` SET `position_z` = -31.498 WHERE `guid` = 6941815;  -- Hazzali Silithid Antenna: -60.95, sighting 2.4 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 334.139 WHERE `guid` = 6941830;  -- Old Blade: +1.06, sighting 9.7 yd in Felwood
UPDATE `gameobject` SET `position_z` = -25.685 WHERE `guid` = 6941839;  -- Ritual Horn: -34.58, sighting 1.0 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 756.104 WHERE `guid` = 6941845;  -- Hunter's Knife: +3.44, sighting 2.7 yd in Winterspring
UPDATE `gameobject` SET `position_z` = 116.951 WHERE `guid` = 6941854;  -- Icon of Khan Maraudos: -116.59, sighting 1.7 yd in Desolace
UPDATE `gameobject` SET `position_z` = 54.126 WHERE `guid` = 6941876;  -- Highborne Wand: +35.65, sighting 8.6 yd in Feralas
UPDATE `gameobject` SET `position_z` = 343.443 WHERE `guid` = 6941877;  -- Jadefire Bone Hatchet: +3.34, sighting 6.4 yd in Felwood
UPDATE `gameobject` SET `position_z` = 300.840 WHERE `guid` = 6941879;  -- Jaednar Spire: -35.65, sighting 3.7 yd in Felwood
UPDATE `gameobject` SET `position_z` = -261.251 WHERE `guid` = 6941881;  -- Jane's Hat: -129.67, sighting 1.4 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 1325.920 WHERE `guid` = 6941886;  -- Jar of Spiders: -139.36, sighting 0.5 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = -36.346 WHERE `guid` = 6941902;  -- Last Stand: -53.33, sighting 3.3 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 76.517 WHERE `guid` = 6941903;  -- Leather Cape: -111.53, sighting 0.8 yd in Mulgore
UPDATE `gameobject` SET `position_z` = 735.169 WHERE `guid` = 6941919;  -- Night Elf Crate: -108.17, sighting 2.2 yd in Winterspring
UPDATE `gameobject` SET `position_z` = 84.043 WHERE `guid` = 6941924;  -- Loose Palisade: +22.64, sighting 0.2 yd in Durotar
UPDATE `gameobject` SET `position_z` = 1317.228 WHERE `guid` = 6941937;  -- Lunar Tome: +9.34, sighting 7.9 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = 64.464 WHERE `guid` = 6941940;  -- Maestra's Training Longbow: +38.17, sighting 9.6 yd in Ashenvale
UPDATE `gameobject` SET `position_z` = 126.197 WHERE `guid` = 6941944;  -- Malgin's Barback: -49.03, sighting 0.8 yd in Barrens
UPDATE `gameobject` SET `position_z` = 84.636 WHERE `guid` = 6941951;  -- Pinned Crossbow: -7.73, sighting 8.2 yd in Aszhara
UPDATE `gameobject` SET `position_z` = 76.175 WHERE `guid` = 6941982;  -- Ancient Necklace: +6.12, sighting 11.1 yd in Feralas
UPDATE `gameobject` SET `position_z` = 1388.950 WHERE `guid` = 6941984;  -- Nest Thorn: -31.51, sighting 0.9 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = -51.947 WHERE `guid` = 6942018;  -- Stray Pack Kodo Satchel: -4.91, sighting 10.3 yd in ThousandNeedles
UPDATE `gameobject` SET `position_z` = -189.603 WHERE `guid` = 6942038;  -- Prancefin: +82.19, sighting 0.8 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = -37.821 WHERE `guid` = 6942051;  -- Fresh Hive'Ashi Corpse: -52.76, sighting 0.7 yd in Silithus
UPDATE `gameobject` SET `position_z` = -56.069 WHERE `guid` = 6942052;  -- Qiraji-Touched Tool: -65.74, sighting 2.1 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 39.623 WHERE `guid` = 6942056;  -- Raptor Talon: +1.76, sighting 1.4 yd in Dustwallow
UPDATE `gameobject` SET `position_z` = 133.786 WHERE `guid` = 6942069;  -- Reclaimed Circlet: +6.56, sighting 1.7 yd in Azshara
UPDATE `gameobject` SET `position_z` = 1337.880 WHERE `guid` = 6942088;  -- Ridiculously Thick Web: -127.96, sighting 3.3 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = -229.733 WHERE `guid` = 6942091;  -- Ringo's Throwing Star: -32.57, sighting 4.4 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 477.455 WHERE `guid` = 6942104;  -- Rotwood Rapier: +3.46, sighting 4.8 yd in Felwood
UPDATE `gameobject` SET `position_z` = 155.508 WHERE `guid` = 6942105;  -- Ruin Excavator: +10.58, sighting 0.6 yd in Aszhara
UPDATE `gameobject` SET `position_z` = -0.350 WHERE `guid` = 6942113;  -- Floating Cargo: +6.76, sighting 7.4 yd in Durotar
UPDATE `gameobject` SET `position_z` = 15.269 WHERE `guid` = 6942116;  -- Shipwreck Axe: +26.46, sighting 1.7 yd in Dustwallow
UPDATE `gameobject` SET `position_z` = 174.197 WHERE `guid` = 6942129;  -- Sandstorm Shaper: +5.68, sighting 4.8 yd in Silithus
UPDATE `gameobject` SET `position_z` = -6.025 WHERE `guid` = 6942155;  -- Twilight Storage Barrel: -115.81, sighting 2.4 yd in Silithus
UPDATE `gameobject` SET `position_z` = 158.112 WHERE `guid` = 6942156;  -- Shadowbreaker: +48.93, sighting 0.8 yd in Desolace
UPDATE `gameobject` SET `position_z` = 62.529 WHERE `guid` = 6942157;  -- Shadowprey Bag: +15.92, sighting 4.1 yd in Desolace
UPDATE `gameobject` SET `position_z` = 114.216 WHERE `guid` = 6942161;  -- Sharpened Pike: +22.54, sighting 1.9 yd in Ashenvale
UPDATE `gameobject` SET `position_z` = 138.823 WHERE `guid` = 6942173;  -- Shoulderguards of Zin-Malor: +34.66, sighting 1.8 yd in Aszhara
UPDATE `gameobject` SET `position_z` = -16.298 WHERE `guid` = 6942183;  -- Silt Covered Ring: -57.08, sighting 1.2 yd in Durotar
UPDATE `gameobject` SET `position_z` = 289.320 WHERE `guid` = 6942187;  -- Silverhand Spaulder: +1.92, sighting 6.9 yd in Felwood
UPDATE `gameobject` SET `position_z` = 4.909 WHERE `guid` = 6942196;  -- Stuck Sword: -42.69, sighting 1.7 yd in Durotar
UPDATE `gameobject` SET `position_z` = 604.198 WHERE `guid` = 6942208;  -- Icy Blade: -470.21, sighting 2.2 yd in Winterspring
UPDATE `gameobject` SET `position_z` = 30.719 WHERE `guid` = 6942214;  -- Sorrow Bolter: +21.68, sighting 11.2 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 360.947 WHERE `guid` = 6942231;  -- Staff of Talons: -54.88, sighting 3.3 yd in StonetalonMountains
UPDATE `gameobject` SET `position_z` = -207.499 WHERE `guid` = 6942240;  -- Steel Helmet: +9.15, sighting 1.0 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 61.244 WHERE `guid` = 6942243;  -- Hanging Ogre Pouch: +13.21, sighting 3.7 yd in Feralas
UPDATE `gameobject` SET `position_z` = 10.218 WHERE `guid` = 6942249;  -- Stormscale Supplies: -22.04, sighting 6.0 yd in Darkshore
UPDATE `gameobject` SET `position_z` = 566.386 WHERE `guid` = 6942287;  -- Talonbranch Sweeper: -1.85, sighting 8.1 yd in Felwood
UPDATE `gameobject` SET `position_z` = 171.557 WHERE `guid` = 6942300;  -- Eternal Watcher's Log: +41.71, sighting 2.0 yd in Silithus
UPDATE `gameobject` SET `position_z` = 91.467 WHERE `guid` = 6942305;  -- The Undying Eye: +9.22, sighting 0.9 yd in Desolace
UPDATE `gameobject` SET `position_z` = 1256.820 WHERE `guid` = 6942331;  -- Timberling Ritual Blade: -46.16, sighting 5.1 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = 587.131 WHERE `guid` = 6942332;  -- Timbermaw Cache: -68.21, sighting 2.1 yd in Felwood
UPDATE `gameobject` SET `position_z` = -259.108 WHERE `guid` = 6942341;  -- Engineer's Tongs: -1.12, sighting 4.1 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = -61.690 WHERE `guid` = 6942343;  -- Lost Hero's Remains: -89.13, sighting 1.9 yd in Silithus
UPDATE `gameobject` SET `position_z` = 138.856 WHERE `guid` = 6942344;  -- Unsavory Scraps: +2.38, sighting 3.5 yd in Feralas
UPDATE `gameobject` SET `position_z` = 71.249 WHERE `guid` = 6942351;  -- Traitor Chest: -12.89, sighting 1.7 yd in Mulgore
UPDATE `gameobject` SET `position_z` = 97.813 WHERE `guid` = 6942382;  -- Venture Co. Ring: +2.16, sighting 3.0 yd in Mulgore
UPDATE `gameobject` SET `position_z` = 30.964 WHERE `guid` = 6942386;  -- Venture Co. Union Buster: +28.68, sighting 5.7 yd in StonetalonMountains
UPDATE `gameobject` SET `position_z` = 1392.880 WHERE `guid` = 6942392;  -- Vulture Effigy: -47.35, sighting 3.4 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = 54.158 WHERE `guid` = 6942393;  -- Vuna'thell: +78.94, sighting 0.3 yd in Azshara
UPDATE `gameobject` SET `position_z` = 101.257 WHERE `guid` = 6942394;  -- Wailing Sapphire Gem: +21.24, sighting 5.1 yd in Barrens
UPDATE `gameobject` SET `position_z` = 4.488 WHERE `guid` = 6942411;  -- Water Seer's Headdress: +6.36, sighting 10.0 yd in Desolace
UPDATE `gameobject` SET `position_z` = 1251.970 WHERE `guid` = 6942418;  -- Whisperwind's Wayfinders: +12.52, sighting 10.7 yd in Teldrassil
UPDATE `gameobject` SET `position_z` = 4.878 WHERE `guid` = 6942440;  -- Wooden Plank: +3.36, sighting 1.4 yd in Tanaris
UPDATE `gameobject` SET `position_z` = 43.862 WHERE `guid` = 6942441;  -- Woodpaw Greatblade: +7.80, sighting 11.8 yd in Feralas
UPDATE `gameobject` SET `position_z` = 76.039 WHERE `guid` = 6942443;  -- Worn Axe: -3.78, sighting 6.3 yd in Durotar
UPDATE `gameobject` SET `position_z` = -234.209 WHERE `guid` = 6942446;  -- Kodo Riding Harness: +23.24, sighting 7.8 yd in UnGoroCrater
UPDATE `gameobject` SET `position_z` = 117.142 WHERE `guid` = 6942452;  -- Yeti Napkin: -95.55, sighting 6.9 yd in Feralas
UPDATE `gameobject` SET `position_z` = -77.026 WHERE `guid` = 6942455;  -- Rusted Sword: +7.99, sighting 1.1 yd in Desolace

-- Elwynn's two missing objects, from the realm's own client-cache records.
DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (90634, 90635, 93008);
DELETE FROM `gameobject_template`      WHERE `entry` IN (90634, 90635, 93008);
DELETE FROM `gameobject`               WHERE `guid`  BETWEEN 6960001 AND 6960099;

REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90634, 3, 980926, 'Brother''s Cherry Pie', '', 'Looting', '', 1, 1689, 90634, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup'),
(90635, 5, 5493, 'Cherry Pie prop', '', 'Looting', '', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(93008, 3, 175455, 'Bloodied Axe', '', 'Inspecting', '', 1, 1689, 93008, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

-- Brother''s Cherry Pie hands out Brother Danil's Cherry Pie (694540).
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(90634, 694540, 0, 100, 0, 1, 0, 1, 1, 'AscensionWorldforged:client cache 90634');

-- Bloodied Axe hands out Mystic Scroll: Brutal Execution (201579).
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(93008, 201579, 0, 100, 0, 1, 0, 1, 1, 'AscensionWorldforged:client cache 93008');

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960001, 90634, 0, 0, 0, 1, 1, -8899.700, -109.800, 82.000, 0.000000, 0, 0, 0, 1.000000, 0, 0, 1, 'worldforged_pickup', 'Brothers Cherry Pie - beside Brother Danil (152) at -8901.6 -112.7 82.0, the North'),
(6960002, 90635, 0, 0, 0, 1, 1, -8899.700, -109.800, 82.000, 0.000000, 0, 0, 0, 1.000000, 0, 0, 1, '', 'Cherry Pie prop - the visible pie every other starter-zone pie stands next to '),
(6960003, 93008, 0, 0, 0, 1, 1, -9994.840, -835.920, 22.598, 0.000000, 0, 0, 0, 1.000000, 0, 0, 1, 'worldforged_pickup', 'Bloodied Axe - the clients own sighting in dump_Duskwood.txt, next to the '),
(6960004, 93008, 1, 0, 0, 1, 1, -5067.920, -2362.220, -52.986, 0.000000, 0, 0, 0, 1.000000, 0, 0, 1, 'worldforged_pickup', 'Bloodied Axe - the clients own sighting in dump_ThousandNeedles.txt; the t');

COMMIT;
