-- Tiraxis' lists as the live server showed them (screenshots of the Spanish client, 11.10.2026, and the list in #4751).
-- Convenience Items: six pages in the live order; the Keeper's Scrolls move to their own Consumables list (900012).
DELETE FROM `npc_vendor` WHERE `entry` = 900008;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(900008, 0, 818046, 0, 0, 41021),  -- Potion of Experience, 35 tokens
(900008, 1, 818047, 0, 0, 41021),  -- Potion of Reputation, 35 tokens
(900008, 2, 818059, 0, 0, 2990),  -- Aura of Experience, 250 tokens
(900008, 3, 818061, 0, 0, 3016),  -- Aura of Reputation, 500 tokens
(900008, 4, 200001, 0, 0, 2990),  -- Race Change Potion, 250 tokens
(900008, 5, 910200, 0, 0, 10335),  -- Faction Change Potion, 600 tokens
(900008, 6, 97318, 0, 0, 10349),  -- Conquest of Azeroth Travel Guide, 2000 tokens
(900008, 7, 101257, 0, 0, 10223),  -- Scroll of Defense: Ashenvale, 50 tokens
(900008, 8, 101258, 0, 0, 10223),  -- Scroll of Defense: Hillsbrad Foothills, 50 tokens
(900008, 9, 1904514, 0, 0, 3015),  -- Portable Sanguine Workbench, 350 tokens
(900008, 10, 57000, 0, 0, 10337),  -- Lootbot 3000, 800 tokens
(900008, 11, 98074, 0, 0, 10337),  -- Cogsley, 800 tokens
(900008, 12, 101169, 0, 0, 10337),  -- Wondrous Wisdomball, 800 tokens
(900008, 13, 190190, 0, 0, 10345),  -- Loot-Transfigurator 5000, 1600 tokens
(900008, 14, 505002, 0, 0, 41021),  -- Pristine Pouch, 35 tokens
(900008, 15, 505003, 0, 0, 3015),  -- Heroes' Satchel, 350 tokens
(900008, 16, 1006971, 0, 0, 10335),  -- Dragon Hide Bag, 600 tokens
(900008, 17, 1004036, 0, 0, 10337),  -- Ironweave Bag, 800 tokens
(900008, 18, 1004040, 0, 0, 10344),  -- Mekkatorque's Neverending Storage Contraption, 1500 tokens
(900008, 19, 98457, 0, 0, 3015),  -- Book of Descension, 350 tokens
(900008, 20, 750750, 0, 0, 3015),  -- Book of Artisans, 350 tokens
(900008, 21, 1179288, 0, 0, 2988),  -- Unlock Talent Loadout, 175 tokens
(900008, 22, 1806961, 0, 0, 3016),  -- Mystic Enchanting: Specialization, 500 tokens
(900008, 23, 97871, 0, 0, 3016),  -- Craftsman's Codex, 500 tokens
(900008, 24, 777998, 0, 0, 3016),  -- Tradesman's Scroll, 500 tokens
(900008, 25, 3001006, 0, 0, 2983),  -- Riding Tome: Apprentice Riding, 100 tokens
(900008, 26, 3001005, 0, 0, 3016),  -- Riding Tome: Journeyman Riding, 500 tokens
(900008, 27, 3211009, 0, 0, 13010),  -- Riding Tome: Expert Riding, 475 tokens
(900008, 28, 3211010, 0, 0, 10344),  -- Riding Tome: Artisan Riding, 1500 tokens
(900008, 29, 1179243, 0, 0, 10344),  -- Riding Tome: Extraordinary Riding, 1500 tokens
(900008, 30, 910201, 0, 0, 2984),  -- Customization Potion, 150 tokens
(900008, 31, 106955, 0, 0, 2990),  -- Tome of Specialization II, 250 tokens
(900008, 32, 106956, 0, 0, 3014),  -- Tome of Specialization III, 300 tokens
(900008, 33, 106957, 0, 0, 10221),  -- Tome of Specialization IV, 400 tokens
(900008, 34, 106958, 0, 0, 3016),  -- Tome of Specialization V, 500 tokens
(900008, 35, 106959, 0, 0, 10336),  -- Tome of Specialization VI, 700 tokens
(900008, 36, 106960, 0, 0, 10344),  -- Tome of Specialization VII, 1500 tokens
(900008, 37, 97332, 0, 0, 10349),  -- Master's Tome Of Specialization (8-20), 2000 tokens
(900008, 38, 1777028, 0, 0, 3016),  -- Thermal Anvil, 500 tokens
(900008, 39, 898070, 0, 0, 10336),  -- Battle Horn, 700 tokens
(900008, 40, 1777064, 0, 0, 3016),  -- Portable Sawmill, 500 tokens
(900008, 41, 1004000, 0, 0, 10336),  -- Herbalist's Hat, 700 tokens
(900008, 42, 1004001, 0, 0, 10336),  -- Miner's Hat, 700 tokens
(900008, 43, 1004002, 0, 0, 10336),  -- Skinner's Hat, 700 tokens
(900008, 44, 1004003, 0, 0, 10336),  -- Alchemist's Hat, 700 tokens
(900008, 45, 1004004, 0, 0, 10336),  -- Blacksmith's Hat, 700 tokens
(900008, 46, 1004006, 0, 0, 10336),  -- Enchanter's Hat, 700 tokens
(900008, 47, 1004007, 0, 0, 10336),  -- Engineer's Goggles, 700 tokens
(900008, 48, 1004012, 0, 0, 10336),  -- Leatherworker's Hat, 700 tokens
(900008, 49, 1004013, 0, 0, 10336),  -- Tailor's Hat, 700 tokens
(900008, 50, 1004014, 0, 0, 10336),  -- Field Medic's Hat, 700 tokens
(900008, 51, 1004017, 0, 0, 10336);  -- Chef's Hat, 700 tokens

-- Consumables: page one as on the live server; page two holds the other Keeper's Scrolls this realm has.
DELETE FROM `npc_vendor` WHERE `entry` = 900012;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(900012, 0, 696661, 0, 0, 3017),  -- Keeper's Scroll: Golganneth, 60 tokens
(900012, 1, 696662, 0, 0, 3017),  -- Keeper's Scroll: Norgannon, 60 tokens
(900012, 2, 696663, 0, 0, 3017),  -- Keeper's Scroll: Khaz'goroth, 60 tokens
(900012, 3, 696664, 0, 0, 3017),  -- Keeper's Scroll: Aggramar, 60 tokens
(900012, 4, 696665, 0, 0, 3017),  -- Keeper's Scroll: Eonar, 60 tokens
(900012, 5, 1179126, 0, 0, 2984),  -- Keeper's Scroll: Ancient Enchanting Altar, 150 tokens
(900012, 6, 1179240, 0, 0, 2983),  -- Keeper's Scroll: Steadfast, 100 tokens
(900012, 7, 1179261, 0, 0, 3017),  -- Keeper's Scroll: Featherfall, 60 tokens
(900012, 8, 1179266, 0, 0, 460),  -- Keeper's Scroll: Ghost Runner, 75 tokens
(900012, 9, 246194, 0, 0, 3017),  -- Keeper's Scroll: Sargeras, 60 tokens
(900012, 10, 246199, 0, 0, 3017),  -- Keeper's Scroll: Aman'thul, 60 tokens
(900012, 11, 1179269, 0, 0, 3017),  -- Keeper's Scroll: Crafting Speed, 60 tokens
(900012, 12, 134994, 0, 0, 3017),  -- Keeper's Scroll: Gathering Speed, 60 tokens
(900012, 13, 97388, 0, 0, 460);  -- Keeper's Scroll: Zoomer, 75 tokens

-- "How do I get Bazaar Tokens?"
DELETE FROM `npc_text` WHERE `ID` = 900012;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(900012, 'Bazaar Tokens come from the creatures you slay and the quests you complete, more from dungeon and raid bosses. Other travelers sell them in the auction house.', 'Bazaar Tokens come from the creatures you slay and the quests you complete, more from dungeon and raid bosses. Other travelers sell them in the auction house.', 1);
