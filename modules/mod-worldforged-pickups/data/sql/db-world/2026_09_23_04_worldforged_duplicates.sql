-- ----------------------------------------------------------------------------
-- Worldforged pickups: one placement where the restoration put two.
-- ----------------------------------------------------------------------------
-- The placements this removes were all made by the passes it follows, and each of the
-- three causes is in the data those passes used:
--
-- 1. One object standing twice. The passes placed a second spawn of an object where the
--    archive recorded it again and no spawn of it stood within 30 yd. The two corpora
--    that recorded these objects - the community's zone dumps and its loot pins - hold
--    the same object and the same placement, and agree to a median of 27 yd, because one
--    of them carries the object's own stored XYZ and the other a position read off a
--    zone chart. A 30 yd window therefore re-places most objects the second corpus saw.
--    One spawn survives: the spot a player was recorded looting at (a pin, the most
--    recorded one first), else the object's own catalogue position. Two spots that the
--    community recorded more than once each are left alone - those are two spawns.
--
-- 2. One item offered by two objects. A pin names the item its looter picked up, never
--    the object it came from. Where the restoration defined two objects that hand out
--    one item - an entry whose client record is the invisible placeholder, and the object
--    a player actually sees - a pin of that item fits both, and both were placed on it.
--    One object belongs at that spot: the one whose own record is a real prop, then the
--    better attested row, then the variant the realm has most of. Rows of the other
--    object elsewhere in the world are untouched.
--
-- 3. A position from another season. A row whose only evidence names Area 52, Bronzebeard,
--    Darkmoon or Dawnrise rather than Conquest of Azeroth - every one of these rows names
--    one of those realms rather than this one. They are dropped where anything else
--    stands for the same object; the item they hold is offered at another placement, so
--    no item is lost.
--
-- Nothing here takes an item out of the world: a row is spared when it is the last
-- placement of the item it holds, and the rows kept stand where the evidence puts the
-- object - position, height and facing are all left exactly as they were.
--
-- 262 rows across 208 objects.
-- ----------------------------------------------------------------------------

-- 1. one object standing twice: 185 rows
-- Dorius' Shield (object 63143, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900748);

-- Jewelled Ring (object 68394, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900762);

-- Alliance Gem of Fortitude (object 90217, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903046);

-- Large Kodo Bone (object 90218, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900819);

-- Murloc Voodoo Toy (object 90228, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900827);

-- Thunder Falls Finest Gun Selection (object 90237, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903078);

-- Peculiar Gold Nugget (object 90244, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920049);

-- Madness Cursed Notes (object 90249, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903105);

-- Defias Mage Stash (object 90252, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900848);

-- Blackrock Smuggled Goods (object 90262, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900857);

-- Lookout Scope (object 90266, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903138);

-- Darkshire Grave (object 90272, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900866);

-- Catacombs Relic Torch (object 90282, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900875);

-- Alchemy Visceral Juice (object 90283, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900876);

-- Emerald Shard (object 90290, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900883, 6903177);

-- Abandoned Peon's Sack (object 90293, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900885);

-- Thule's Curse Parchment (object 90320, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903190);

-- Sack of Pine Seeds (object 90323, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900907, 6903197);

-- Sack of Pine Seeds (object 90323, map 43)
DELETE FROM `gameobject` WHERE `guid` IN (6931090);

-- Dirt Covered Gown (object 90325, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900909);

-- Discarded Wagon Wheel (object 90346, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900923, 6904222, 6904223, 6904224);

-- Thistlefur Fur Shroud (object 90383, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920052);

-- Porcelain Jar (object 90560, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900987, 6904246);

-- Rough Axe (object 90583, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920056);

-- Shabby Knife (object 90606, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901004);

-- Mossy Bag (object 90626, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6931024);

-- Crusader's Chest (object 93000, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6931027);

-- Spicy Candle (object 95501, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901021, 6903284);

-- Forgotten Knapsack (object 95503, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901023);

-- Glinting Necklace (object 95504, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901024);

-- Warm Mug (object 95508, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920058);

-- Chok'sul's Basket (object 95529, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901045);

-- Wreckage Piece (object 95531, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901047);

-- Fire Poker (object 95605, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901058, 6903362);

-- Rattlecage Cauldron (object 95609, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901060);

-- Waterlogged Chest (object 95613, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903371);

-- Assassin's Crossbow (object 95635, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901081);

-- Centaur Axe (object 95639, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901085);

-- Apprentice Staff (object 95670, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901108);

-- Stashed Goods (object 95671, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901109);

-- Heavy Iron Pan (object 95687, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901118, 6903405);

-- Morale Boosters (object 95692, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901122);

-- Riding Cloak (object 95696, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901126);

-- Garren's Pitchfork (object 95698, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901128);

-- Forgotten Dwarven Axe (object 95706, map 47)
DELETE FROM `gameobject` WHERE `guid` IN (6905056);

-- Pirate Sabre (object 95711, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901134);

-- Baby Gorilla Bait (object 95715, map 230)
DELETE FROM `gameobject` WHERE `guid` IN (6931139);

-- Kurzen Medicine Compendium (object 95742, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901165, 6903480, 6903482);

-- Abandoned Supplies (object 95757, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901180);

-- Quarry Sledge (object 95785, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903518);

-- Partially Digested Corpse (object 95788, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920065);

-- Murloc Plunder (object 95806, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901215);

-- Defias Handshake (object 95811, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901220);

-- Stashed Goods (object 95814, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901223);

-- Spare Bag (object 95821, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901230);

-- The Dark Soul (object 95822, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901231);

-- Sharpened Pike (object 95831, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901238);

-- Fallen Adventurer's Mace (object 95853, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901259);

-- Sunken Mace (object 95858, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903572);

-- Hidden Stash (object 95862, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903581);

-- Safe Treasure No One Could Ever Reach (object 95863, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901269);

-- Plains Bolter (object 95875, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901278);

-- Drinkin' Pants (object 95884, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920070);

-- Sunken Chest (object 95897, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901298);

-- Warder's Cache (object 95902, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901303);

-- Crystal Resonator Coffer (object 95920, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6931035);

-- Forgotten Light of Elune (object 96118, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901362);

-- Strange Glowing Object (object 96123, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901366);

-- Ancient Bag of Scrolls (object 96134, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920073);

-- Dropped Polearm (object 96151, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920074);

-- Freshly Brewed Potion (object 96157, map 429)
DELETE FROM `gameobject` WHERE `guid` IN (6905236);

-- Crusader's Mace (object 96240, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6904516);

-- Thrown Dagger (object 97115, map 329)
DELETE FROM `gameobject` WHERE `guid` IN (6905182);

-- Abandoned Greatsword (object 97120, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901494);

-- Needlewind Crossbow (object 97136, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901509);

-- Abandoned Hammer (object 254163, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920010);

-- Abandoned Bag (object 254165, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900029);

-- Snellig's Footlocker (object 254237, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900045);

-- Gnawed Bones (object 254240, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900047, 6903733);

-- Shell Cracker (object 254290, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900080);

-- Sunken Ring (object 254291, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900081);

-- Magram Hatchet (object 254295, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6904582);

-- Greataxe of Kolk (object 254309, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900098, 6920019);

-- Syndicate Cobbler's Supplies (object 254329, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903743);

-- Snow Buried Shipment (object 254342, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900127);

-- Sawtooth Jaw (object 254385, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900161);

-- Dusksinger Band (object 254392, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900168);

-- Ancient Ring (object 254455, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920022);

-- Stuck Sword (object 254520, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900245);

-- Tharil'zun's Extra Boots (object 254543, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900252);

-- Redwood Buckler (object 254544, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6903849);

-- Gnollish Sword (object 254545, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900254);

-- Free Book (object 254551, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900260);

-- Elven Necklace (object 254571, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900274, 6903875);

-- Everburning Draconic Claw (object 254638, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900292, 6903880);

-- Tattered Fabric (object 254647, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920024);

-- Obsidian Axe (object 254658, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900310);

-- Blue Dragon Crystal (object 300017, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6904661);

-- Empty Sack (object 340044, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900336);

-- Scarlet Shield (object 340113, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900347);

-- Plague Mask (object 340117, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900351);

-- Pilfered Stormpike Polearm (object 387876, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900386);

-- Wheel (object 515345, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900396);

-- Shoddy Blade (object 515362, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900397);

-- Hidden Chest (object 515366, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900399);

-- Ceremonial Mace (object 515372, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900404);

-- Ceremonial Mace (object 515372, map 70)
DELETE FROM `gameobject` WHERE `guid` IN (6905084);

-- Heavy Shovel (object 515383, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900412);

-- Faded Scroll (object 515402, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900426);

-- Moonkin Nest (object 515409, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900433);

-- Celestial Edge of Starfall (object 515434, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900441);

-- Submerged Crescent Blade (object 515435, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6904698);

-- Timberbane's Old Hatchet (object 515437, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900444);

-- Herbalist's Cane (object 515439, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900446);

-- Bundle of Dried Corn (object 515443, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900450, 6904711);

-- Stray Pack Kodo Satchel (object 515519, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900470, 6920025);

-- Drowned Diver's Helmet (object 515525, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6904751, 6904761);

-- Drowned Diver's Helmet (object 515525, map 90)
DELETE FROM `gameobject` WHERE `guid` IN (6931115);

-- Harpy Feather (object 515571, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900487);

-- Lost Southsea Loot (object 515727, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900493, 6904782);

-- Sturdy Coffin Lid (object 515770, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900509);

-- Disturbed Sand Pile (object 515773, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920029);

-- Last Stand (object 515782, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900515);

-- Sun Ritual Necklace (object 515797, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900518);

-- Tauren Crate (object 515947, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900577);

-- Shallow Grave (object 515948, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900578);

-- Ror's Chopper (object 517202, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6904883);

-- Broken Barrel (object 517325, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900614);

-- Rusty Shotgun (object 517353, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900624);

-- Gareks Personal Belongings (object 518045, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920038);

-- Lit Lantern (object 518051, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920039);

-- Darkmist Widow's Previous Meal (object 518149, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900669);

-- Lost Oasis Crate (object 518311, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900682);

-- Darkwhisper Spear (object 518584, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900721);

-- Icy Blade (object 518586, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920043);

-- Ancient Femur (object 520018, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900726);

-- Decayed Sharpshot (object 520047, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900727);

-- Sturdy Arrow (object 520051, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900728);

-- Oathblade (object 520055, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6904118);

-- Casket Lid (object 520062, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900730, 6904121);

-- Old Northshire Bolter (object 520064, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900731);

-- Ancient Battleaxe (object 520072, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6904135);

-- Radiant Rifle (object 520073, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900739);

-- Rocket Shrapnel (object 520703, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900746);

-- Geo Band (object 686879, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900775, 6904972);

-- Cursed Ritual Carver (object 686880, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920046);

-- Sulfurspike Hatchet (object 686899, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900786, 6904148);

-- Free Sample (object 686930, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900800);

-- Primitive Offering Box (object 735902, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920047);

-- Moss Picker's Pouch (object 1344099, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900001);

-- Moonbathed Necklace (object 1344800, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900002);

-- Apothecary's Lantern (object 1345003, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6910002);

-- Coastline Vest (object 1345025, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6910022);

-- Defias Turncoat's Jerkin (object 1345037, map 70)
DELETE FROM `gameobject` WHERE `guid` IN (6910390);

-- Dwarven Crossbow (object 1345045, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6910255);

-- Empty Satchel (object 1345048, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920005);

-- Grunir's Mug (object 1345064, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6910079);

-- Haren's Tankard (object 1345067, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6910087);

-- Pilfered Bloodhoof Bow (object 1345106, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6910294);

-- Supply Runner's Pants (object 1345146, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6910193);

-- Verdant Ember Loop (object 1345159, map 329)
DELETE FROM `gameobject` WHERE `guid` IN (6910421);

-- Windhoof Totem (object 1345167, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6910354);

-- Wyvern Trapper Spear (object 1345182, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6910359);


-- 2. one item offered by two objects: 32 rows
-- Gilnean Crate (object 90328, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900911);

-- Executioner's Axe (object 90492, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6930073, 6931018, 6931019, 6931020);

-- Cauterizing Needle (object 90501, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900964, 6931001);

-- Mossy Bag (object 90626, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6931002);

-- Mossy Bag (object 90626, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6931022, 6931023, 6931025);

-- Crusader's Chest (object 93000, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6931003, 6931004);

-- Crusader's Chest (object 93000, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6931026);

-- Travel Sack (object 95612, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920060, 6931006);

-- Travel Sack (object 95612, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6901062, 6930076);

-- Crusader's Mace (object 96240, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6901470);

-- Water Seer's Headdress (object 254278, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900068);

-- Frost Coated Pauldrons (object 254337, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900122, 6931011);

-- Memento Ring (object 254495, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900232, 6903818);

-- Memento Ring (object 254495, map 209)
DELETE FROM `gameobject` WHERE `guid` IN (6905143);

-- Humming Blade (object 515470, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6900453, 6931012, 6931013);

-- Humming Blade (object 515470, map 36)
DELETE FROM `gameobject` WHERE `guid` IN (6931088);

-- Abandoned Trousers (object 515532, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6900478);

-- Scarlet Chest (object 518372, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6930059);

-- Moss Picker's Pouch (object 1344099, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6930123);


-- 3. a position from another season: 45 rows
-- The One Candle (object 90239, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920048);

-- Stylish Cloak (object 90304, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920050);

-- Thule's Curse Parchment (object 90320, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920051);

-- Sack of Relics (object 90489, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920053);

-- Encrusted Spear (object 90532, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920054);

-- Glinting Ring (object 90569, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920055);

-- Forgotten Sack (object 90636, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920057);

-- Sword in a Board (object 95603, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920059);

-- Storage Crate (object 95779, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920063);

-- Gnoll Cleaver (object 95780, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920064);

-- Shadowpounce Cowl (object 95792, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920066);

-- Idol of the Aerie (object 95794, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920067);

-- Travel Sack (object 95812, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920068);

-- Rather Large Ring (object 95845, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920069);

-- Abandoned Supplies (object 96101, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920072);

-- Chest of Warm Clothes (object 96234, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920076);

-- Abandoned Hammer (object 254163, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920011);

-- Spare Hunting Boots (object 254194, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920012);

-- Arkonite Orb (object 254255, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920014, 6920015);

-- Arkonite Orb (object 254255, map 530)
DELETE FROM `gameobject` WHERE `guid` IN (6920016, 6920017);

-- Stormpiercer (object 254303, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920018);

-- Heavy Furbolg Basket (object 254425, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920020);

-- Reclaimed Circlet (object 254449, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920021);

-- Warbanner (object 254463, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920023);

-- Dangerously Loose Machine Part (object 515596, map 47)
DELETE FROM `gameobject` WHERE `guid` IN (6920026);

-- Dangerously Loose Machine Part (object 515596, map 129)
DELETE FROM `gameobject` WHERE `guid` IN (6920028);

-- Sun Ritual Necklace (object 515797, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920030);

-- Abandoned Trader Crate (object 515798, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920031);

-- Wooden Plank (object 515827, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920032);

-- High Seas Axe (object 515903, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920033);

-- Unfortunate Shoulderpad (object 515904, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920034);

-- Tiki Shield (object 515918, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920035);

-- Syndicate Boots (object 517317, map 36)
DELETE FROM `gameobject` WHERE `guid` IN (6920036);

-- Floating Debris (object 517330, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920037);

-- Scorched Knife (object 518098, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920040);

-- Accumulated Moonlight (object 518135, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920041);

-- Frostsaber Halberd (object 518568, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920042);

-- Disciple Bow (object 520069, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920044);

-- Excavator's Pick (object 686868, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920045);

-- Brackish Spellweave Robe (object 1345018, map 1)
DELETE FROM `gameobject` WHERE `guid` IN (6920004);

-- Minervia's Pendant of Atonement (object 1345091, map 189)
DELETE FROM `gameobject` WHERE `guid` IN (6920007);

-- Plague Purger (object 1345107, map 530)
DELETE FROM `gameobject` WHERE `guid` IN (6920008);

-- Rough Weathered Ring (object 1345117, map 0)
DELETE FROM `gameobject` WHERE `guid` IN (6920009);
