-- Deathknell's CoA class trainers wear their class starter kit. No capture of any CoA trainer look exists, so
-- rev_20260923_09 gave them stand-in outfits mixed from stock NPCs; the kit (StarterKits in
-- AscensionCustomClassData.h, what a new character of the class wears) is the coherent known look. Every armour
-- slot is set from the kit and the rest cleared; one-hand, off-hand and ranged kit weapons go to ItemID1-3; every
-- display is in the client's ItemDisplayInfo. Dar'danis (rev_20261001_04) and Sunspeaker Talethia, whose CoA
-- robe is known (rev_20261001_06), keep theirs. Race, face and hair stay.
-- Bailey Horrorhate 50275, Witch Hunter: Grim Greaves, Grim Gambeson, Grim Chains, Worn Dagger, Witching Crossbow,
--   Grim Shroud
UPDATE `creature_display_preset` SET `item_head` = 22024, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143975, `item_waist` = 0, `item_legs` = 143976, `item_feet` = 143179,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 50275;
UPDATE `creature_equip_template` SET `ItemID1` = 2092, `ItemID2` = 0, `ItemID3` = 2149641
    WHERE `CreatureID` = 50275 AND `ID` = 1;
-- Dabbert Staze 502773, Stormbringer: Static Pants, Static Footpads, Static Robe, Worn Storm Staff, Static Cowl
UPDATE `creature_display_preset` SET `item_head` = 143967, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143966, `item_waist` = 0, `item_legs` = 19664, `item_feet` = 164339,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502773;
UPDATE `creature_equip_template` SET `ItemID1` = 682734, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502773 AND `ID` = 1;
-- Brallmular 9300250, Knight of Xoroth: Scorched Greaves, Scorched Sabatons, Scorched Plate, Dull Shortsword
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143980, `item_waist` = 0, `item_legs` = 143981, `item_feet` = 155511,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 9300250;
UPDATE `creature_equip_template` SET `ItemID1` = 629951, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 9300250 AND `ID` = 1;
-- Deathguard Bradforth 50279, Guardian: Fortified Legplate, Fortified Stompers, Fortified Hauberk, Dull Shortsword,
--   Studded Buckler, Fortified Shirt
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 78844,
    `item_chest` = 143947, `item_waist` = 0, `item_legs` = 143948, `item_feet` = 143949,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 50279;
UPDATE `creature_equip_template` SET `ItemID1` = 629951, `ItemID2` = 629929, `ItemID3` = 0
    WHERE `CreatureID` = 50279 AND `ID` = 1;
-- Vaelion Grandbell 502803, Templar: Resolute Chausses, Resolute Sabatons, Resolute Mail, Stone Mallet, Divine Brand
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 138411,
    `item_chest` = 20590, `item_waist` = 0, `item_legs` = 22921, `item_feet` = 15570,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502803;
UPDATE `creature_equip_template` SET `ItemID1` = 629941, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502803 AND `ID` = 1;
-- Irina Valreed 502922, Bloodmage: Crimson Garment, Crimson Footpads, Crimson Vest, Bloodied Shiv
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143937, `item_waist` = 0, `item_legs` = 143938, `item_feet` = 142733,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502922;
UPDATE `creature_equip_template` SET `ItemID1` = 629942, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502922 AND `ID` = 1;
-- Gustaf Blightflight 50281, Ranger: Forest Pants, Forest Boots, Forest Garb, Worn Dagger, Old Bow
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143957, `item_waist` = 0, `item_legs` = 143956, `item_feet` = 143955,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 50281;
UPDATE `creature_equip_template` SET `ItemID1` = 2092, `ItemID2` = 0, `ItemID3` = 484322
    WHERE `CreatureID` = 50281 AND `ID` = 1;
-- Quardormi 502822, Chronomancer: Time-worn Pants, Time-worn Boots, Time-worn Robes, Novice Staff
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143940, `item_waist` = 0, `item_legs` = 142709, `item_feet` = 13061,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502822;
UPDATE `creature_equip_template` SET `ItemID1` = 629948, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502822 AND `ID` = 1;
-- Dornall Plagueweaver 502930, Necromancer: Necrotic Pants, Necrotic Slippers, Necrotic Robes, Apprentice Staff
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143950, `item_waist` = 0, `item_legs` = 11166, `item_feet` = 142700,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502930;
UPDATE `creature_equip_template` SET `ItemID1` = 629950, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502930 AND `ID` = 1;
-- Cadmus Emberblaze 50293, Pyromancer: Kindled Pants, Kindled Slippers, Kindled Cloth, Kindled Branch
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143954, `item_waist` = 0, `item_legs` = 143185, `item_feet` = 143186,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 50293;
UPDATE `creature_equip_template` SET `ItemID1` = 484327, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 50293 AND `ID` = 1;
-- Thaddeus Voidseeker 502833, Cultist: Eldritch Pants, Eldritch Boots, Eldritch Robes, Twisted Dirk
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143942, `item_waist` = 0, `item_legs` = 20644, `item_feet` = 21690,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502833;
UPDATE `creature_equip_template` SET `ItemID1` = 629982, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502833 AND `ID` = 1;
-- Landralanis 502850, Starcaller: Moonlit Legguards, Moonlit Sabatons, Moonlit Breastplate, Moonsong Halberd
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143965, `item_waist` = 0, `item_legs` = 143963, `item_feet` = 143964,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502850;
UPDATE `creature_equip_template` SET `ItemID1` = 2000004, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502850 AND `ID` = 1;
-- Riley Jett 502873, Tinker: Engineered Trunks, Engineered Treads, Engineered Overalls, Worn Spanner, Old Rifle,
--   Scratched Goggles
UPDATE `creature_display_preset` SET `item_head` = 10195, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143972, `item_waist` = 0, `item_legs` = 13192, `item_feet` = 143971,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502873;
UPDATE `creature_equip_template` SET `ItemID1` = 2000048, `ItemID2` = 0, `ItemID3` = 484364
    WHERE `CreatureID` = 502873 AND `ID` = 1;
-- Apothecary Kelan 650688, Venomancer: Noxious Kilt, Venomancer Shoes, Noxious Wrappings, Twisted Dirk
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 143974, `item_waist` = 0, `item_legs` = 143973, `item_feet` = 12998,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 650688;
UPDATE `creature_equip_template` SET `ItemID1` = 629982, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 650688 AND `ID` = 1;
-- Undertaker Chite 502891, Reaper: Phantom Legplates , Phantom Boots, Phantom Hauberk, Reaper Scythe, Phantom Shirt
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 7071,
    `item_chest` = 143960, `item_waist` = 0, `item_legs` = 143958, `item_feet` = 143959,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502891;
UPDATE `creature_equip_template` SET `ItemID1` = 2000005, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502891 AND `ID` = 1;
-- Wilhelm Balthier 502913, Runemaster: Runic Leggings, Runic Boots, Runic Vest, Etched Blade, Runic Shirt
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 12936,
    `item_chest` = 143961, `item_waist` = 0, `item_legs` = 143962, `item_feet` = 18960,
    `item_wrists` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 502913;
UPDATE `creature_equip_template` SET `ItemID1` = 629952, `ItemID2` = 0, `ItemID3` = 0
    WHERE `CreatureID` = 502913 AND `ID` = 1;
