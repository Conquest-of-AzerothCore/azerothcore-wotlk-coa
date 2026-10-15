-- Conquest of Azeroth: guards direct each class to its own class trainers.
--
-- The stock class-trainer directions stay for the stock classes a realm may still offer. Where CoA class trainers
-- stand, the guard gains a second "Class Trainer" option that points each CoA class to its own trainers in that
-- city. Class conditions show the stock option to the stock classes and the CoA option to the CoA classes.
--
-- WHERE EACH VALUE COMES FROM
--   option and POI keys  SOURCED-DB: research/trainers-guards-markers/guard-directions.md (+ .json), re-derived on
--     coa_grd. Every stock per-class option names a stock class (Druid, Hunter, Mage, Paladin, Priest, Rogue,
--     Shaman, Warlock, Warrior); none names a Death Knight or a CoA class.
--   core path  SOURCED-CORE: a GOSSIP_OPTION_GOSSIP option sends its ActionPoiID as a map flag and then opens its
--     ActionMenuID (PlayerGossip.cpp:302-313); an option shows when OptionNpcFlag & npcflag (PlayerGossip.cpp:65;
--     every guard here has npcflag 1) and its conditions hold. Guard directions exist only as these rows:
--     guards.cpp holds only the Shattrath combat AIs, the only script SendPointOfInterest is
--     culling_of_stratholme.cpp:1240's wave POIs (1000+), and no smart_scripts row sends (action 98) or handles
--     (event 62) these menus.
--   stock directions  DERIVED: the stock "Class Trainer" / "A class trainer" root options, their per-class submenu
--     options, their points of interest and all their locale rows are kept. Section 2 shows each stock root
--     option only to the stock classes (CONDITION_CLASS mask 1535), the 18 guard root options and Dalaran's
--     10082/1 alike, so a CoA class is never sent to a trainer that cannot train it.
--   CoA trainers  SOURCED-DB: the 111 class-trainer spawns (trainer Type 0, Requirement 12-32) that stand in a
--     city or town with guard directions, read from coa_grd2 = scratch acore_world plus every updater-pending file
--     in name order (effective positions). Stormwind 16, Ironforge 11, Darnassus 13 (with Mathrengyl Bearwalker
--     4217), the Exodar 14, Orgrimmar 15, the Undercity 18, Thunder Bluff 7, Silvermoon 16 and Kharanos 1 (Zipak
--     Cogweight, Reaper). Every trainer has its city's faction. No CoA class trainer stands in Dalaran, Shattrath,
--     Razor Hill, Bloodhoof Village, Brill, Goldshire, Dolanaar, Azure Watch or Falconwing Square, so those guards
--     get no CoA option.
--   CoA root options  DESIGN: the 11 root menus of those 9 places get a CoA "Class Trainer" option with the next
--     OptionID free in gossip_menu_option and in its locale table (stock keeps orphan locale rows such as 2121/13),
--     the stock option's icon and broadcast text (so it is localised like the stock one), leading to the CoA
--     submenu. It is shown only to the CoA classes 12-32 (CONDITION_CLASS mask 4294965248).
--   class names  SOURCED-CLIENT: ChrClasses.dbc 12-32 of the CoA client data; the options are ordered by class
--     name.
--   places  SOURCED-CLIENT (server maps/vmaps): the AreaTable id of the spawn cell and the WMOAreaTable name of
--     the WMO group under each spawn, plus the named NPCs and stock POIs within 15/40 yd in coa_grd2; each leaf
--     menu comment below names what was checked. INFERRED: the wording of every text (modelled on the stock guard
--     texts of the same city).
--   points of interest  each new point stands on its trainer's spawn, Icon 7, Flags 99, Importance 0 like the stock
--     class-trainer points; points_of_interest rows need valid map coordinates (ObjectMgr.cpp:8477).
--   menus and texts  the gossip loader drops a gossip_menu row whose TextID has no npc_text (ObjectMgr.cpp:10283)
--     and an npc_text BroadcastTextID that does not exist (ObjectMgr.cpp:6767); each submenu text copies the
--     city's stock submenu text with its broadcast text id. The id block holds 100 menus, so trainers who stand in
--     the same hall share one leaf menu whose text names each of them.
--
-- Counts: no stock row deleted or changed; 11 CoA root options, 9 CoA submenus with 111 options, 84 leaf menus,
-- 111 points of interest; 30 class conditions.

-- ---------------------------------------------------------------------------
-- 1. Directions to CoA class trainers
-- ---------------------------------------------------------------------------
-- Stormwind: submenu 932100 (text copied from stock npc_text 898), 16 class options, reached from 435/16
--     (Stormwind City Guard 68, City Patroller 1976, Harbor Guard 29712).
--   leaf 932110: Barbarian Connor the Barbarian guid 9004500 POI 9321000; checked at the spawn: Command Center,
--       Old Town (WMO A01Sw_Oldtown_Commandcenter)
--   leaf 932111: Guardian Kalanaros the Bard guid 9004501 POI 9321001; checked at the spawn: Pig and Whistle
--       Tavern, Old Town (WMO area Old Town; barmaid Elly Langston 6.5 yd)
--   leaf 932112: Templar Brother Faren guid 9004502 POI 9321002, Sun Cleric Crusader Natalie guid 9004503 POI
--       9321003; checked at the spawn: Cathedral of Light nave (WMO area Cathedral of Light)
--   leaf 932113: Witch Doctor The Great Yumbabo guid 9004504 POI 9321004; checked at the spawn: The Park lawn
--       (AreaTable 10224; elven table and benches 4-6 yd, park moonwell 24 yd)
--   leaf 932114: Witch Hunter Talvin guid 9004505 POI 9321005; checked at the spawn: Cathedral Square paving south
--       of the cathedral (AreaTable 10225)
--   leaf 932115: Stormbringer Viktor Thunder-Eye guid 9004506 POI 9321006; checked at the spawn: lakeshore under
--       the trees below the Valley of Heroes (AreaTable 1617)
--   leaf 932116: Bloodmage Sofiya Taylor guid 9004507 POI 9321007, Necromancer Jefferson Lively guid 9004510 POI
--       9321010, Cultist Gerald the Demented guid 9004512 POI 9321012; checked at the spawn: The Slaughtered Lamb,
--       Mage Quarter: taproom z 122, cellar z 101 (WMO area The Slaughtered Lamb)
--   leaf 932117: Chronomancer Yisdormi guid 9004509 POI 9321009, Runemaster Balthazar Marone guid 9004515 POI
--       9321015; checked at the spawn: Wizard's Sanctum under the Mage Quarter tower (WMO area Wizard's Sanctum;
--       areatrigger_teleport 704 "Wizard Sanctum Tower Portal")
--   leaf 932118: Ranger Phoebe Lakewander guid 9004508 POI 9321008; checked at the spawn: Dwarven District plaza
--       before the hunters' lodge (stable master Jenova Stoneshield 11.7 yd)
--   leaf 932119: Pyromancer Michael Pietrus guid 9004511 POI 9321011; checked at the spawn: Dwarven District
--       forges (WMO area Dwarven District; stock POI 41 Therum Deepforge 7.6 yd)
--   leaf 932120: Tinker James Randal guid 9004513 POI 9321013; checked at the spawn: Dwarven District engineering
--       yard (Lilliam Sparkspindle 11.2 yd, Sprite Jumpsprocket 6.7 yd)
--   leaf 932121: Reaper Wilfred Soulcatcher guid 9004514 POI 9321014; checked at the spawn: city cemetery beside
--       the cathedral, foot of Sw_Staircase (gravestones 10-20 yd)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321000, 9321007, 9321009, 9321012, 9321001, 9321010, 9321011, 9321008, 9321014, 9321015, 9321006, 9321003,
    9321002, 9321013, 9321004, 9321005);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321000, 9321007, 9321009, 9321012, 9321001, 9321010, 9321011, 9321008, 9321014, 9321015, 9321006, 9321003,
    9321002, 9321013, 9321004, 9321005);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321000, -8810, 327, 7, 99, 0, 'Stormwind Barbarian Trainer'),
(9321007, -8948.5, 998.5, 7, 99, 0, 'Stormwind Bloodmage Trainer'),
(9321009, -9002.5, 879.5, 7, 99, 0, 'Stormwind Chronomancer Trainer'),
(9321012, -8972.5, 1025.5, 7, 99, 0, 'Stormwind Cultist Trainer'),
(9321001, -8621, 412.5, 7, 99, 0, 'Stormwind Guardian Trainer'),
(9321010, -8988.5, 1039.5, 7, 99, 0, 'Stormwind Necromancer Trainer'),
(9321011, -8440.5, 609, 7, 99, 0, 'Stormwind Pyromancer Trainer'),
(9321008, -8436, 566, 7, 99, 0, 'Stormwind Ranger Trainer'),
(9321014, -8470, 903.5, 7, 99, 0, 'Stormwind Reaper Trainer'),
(9321015, -8998, 866.5, 7, 99, 0, 'Stormwind Runemaster Trainer'),
(9321006, -9037, 549.5, 7, 99, 0, 'Stormwind Stormbringer Trainer'),
(9321003, -8547.5, 828, 7, 99, 0, 'Stormwind Sun Cleric Trainer'),
(9321002, -8541, 861, 7, 99, 0, 'Stormwind Templar Trainer'),
(9321013, -8355, 652, 7, 99, 0, 'Stormwind Tinker Trainer'),
(9321004, -8746, 1129, 7, 99, 0, 'Stormwind Witch Doctor Trainer'),
(9321005, -8598, 815, 7, 99, 0, 'Stormwind Witch Hunter Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932100, 932110, 932111, 932112, 932113, 932114, 932115, 932116, 932117, 932118, 932119, 932120, 932121);
DELETE FROM `npc_text` WHERE `ID` IN (
    932100, 932110, 932111, 932112, 932113, 932114, 932115, 932116, 932117, 932118, 932119, 932120, 932121);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932100, 'Which class trainer are you looking for?', 'Which class trainer are you looking for?', 2901, 7, 1, 0),
(932110, 'Connor the Barbarian? You''ll hear him before you see him. He trains his lot upstairs in the Command Center in Old Town.', 'Connor the Barbarian? You''ll hear him before you see him. He trains his lot upstairs in the Command Center in Old Town.', 0, 0, 1, 0),
(932111, 'Kalanaros the Bard teaches the ways of the Guardian, odd as that sounds. You will find him in the taproom of the Pig and Whistle Tavern in Old Town.', 'Kalanaros the Bard teaches the ways of the Guardian, odd as that sounds. You will find him in the taproom of the Pig and Whistle Tavern in Old Town.', 0, 0, 1, 0),
(932112, 'Head to the Cathedral of Light in Cathedral Square. Brother Faren trains the Templars and Crusader Natalie the Sun Clerics, both inside the nave.', 'Head to the Cathedral of Light in Cathedral Square. Brother Faren trains the Templars and Crusader Natalie the Sun Clerics, both inside the nave.', 0, 0, 1, 0),
(932113, 'A troll witch doctor in the middle of Stormwind, if you can believe it. The Great Yumbabo has made himself at home in the Park, on the lawn by the elven table and benches near the moonwell.', 'A troll witch doctor in the middle of Stormwind, if you can believe it. The Great Yumbabo has made himself at home in the Park, on the lawn by the elven table and benches near the moonwell.', 0, 0, 1, 0),
(932114, 'Talvin keeps his watch out on Cathedral Square, on the open paving south of the Cathedral of Light. Mind the look he gives you.', 'Talvin keeps his watch out on Cathedral Square, on the open paving south of the Cathedral of Light. Mind the look he gives you.', 0, 0, 1, 0),
(932115, 'Viktor Thunder-Eye likes to be near the water and the open sky. Look for him on the lakeshore below the Valley of Heroes, under the trees.', 'Viktor Thunder-Eye likes to be near the water and the open sky. Look for him on the lakeshore below the Valley of Heroes, under the trees.', 0, 0, 1, 0),
(932116, 'The Slaughtered Lamb in the Mage Quarter draws that sort. Sofiya Taylor teaches the Bloodmages in the taproom. Go down to the cellar for Jefferson Lively, the Necromancer, and Gerald the Demented, the Cultist.', 'The Slaughtered Lamb in the Mage Quarter draws that sort. Sofiya Taylor teaches the Bloodmages in the taproom. Go down to the cellar for Jefferson Lively, the Necromancer, and Gerald the Demented, the Cultist.', 0, 0, 1, 0),
(932117, 'Take the tower portal in the Mage Quarter down to the Wizard''s Sanctum. Yisdormi teaches the Chronomancers there and Balthazar Marone the Runemasters.', 'Take the tower portal in the Mage Quarter down to the Wizard''s Sanctum. Yisdormi teaches the Chronomancers there and Balthazar Marone the Runemasters.', 0, 0, 1, 0),
(932118, 'Phoebe Lakewander trains the Rangers in the Dwarven District. She''s on the plaza in front of the hunters'' lodge, near Jenova Stoneshield''s stables.', 'Phoebe Lakewander trains the Rangers in the Dwarven District. She''s on the plaza in front of the hunters'' lodge, near Jenova Stoneshield''s stables.', 0, 0, 1, 0),
(932119, 'Michael Pietrus keeps close to the fire, naturally. Find him by the brazier beside the forges of the Dwarven District.', 'Michael Pietrus keeps close to the fire, naturally. Find him by the brazier beside the forges of the Dwarven District.', 0, 0, 1, 0),
(932120, 'James Randal tinkers in the engineering yard of the Dwarven District, with Lilliam Sparkspindle and her apprentices.', 'James Randal tinkers in the engineering yard of the Dwarven District, with Lilliam Sparkspindle and her apprentices.', 0, 0, 1, 0),
(932121, 'Wilfred Soulcatcher keeps company with the dead in the city cemetery beside the Cathedral of Light. He waits at the foot of the stair that comes down from the cathedral.', 'Wilfred Soulcatcher keeps company with the dead in the city cemetery beside the Cathedral of Light. He waits at the foot of the stair that comes down from the cathedral.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932100, 932110, 932111, 932112, 932113, 932114, 932115, 932116, 932117, 932118, 932119, 932120, 932121);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932100, 932100),
(932110, 932110),
(932111, 932111),
(932112, 932112),
(932113, 932113),
(932114, 932114),
(932115, 932115),
(932116, 932116),
(932117, 932117),
(932118, 932118),
(932119, 932119),
(932120, 932120),
(932121, 932121);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932100;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932100;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932100, 0, 0, 'Barbarian', 0, 1, 1, 932110, 9321000, 0, 0, '', 0, 0),
(932100, 1, 0, 'Bloodmage', 0, 1, 1, 932116, 9321007, 0, 0, '', 0, 0),
(932100, 2, 0, 'Chronomancer', 0, 1, 1, 932117, 9321009, 0, 0, '', 0, 0),
(932100, 3, 0, 'Cultist', 0, 1, 1, 932116, 9321012, 0, 0, '', 0, 0),
(932100, 4, 0, 'Guardian', 0, 1, 1, 932111, 9321001, 0, 0, '', 0, 0),
(932100, 5, 0, 'Necromancer', 0, 1, 1, 932116, 9321010, 0, 0, '', 0, 0),
(932100, 6, 0, 'Pyromancer', 0, 1, 1, 932119, 9321011, 0, 0, '', 0, 0),
(932100, 7, 0, 'Ranger', 0, 1, 1, 932118, 9321008, 0, 0, '', 0, 0),
(932100, 8, 0, 'Reaper', 0, 1, 1, 932121, 9321014, 0, 0, '', 0, 0),
(932100, 9, 0, 'Runemaster', 0, 1, 1, 932117, 9321015, 0, 0, '', 0, 0),
(932100, 10, 0, 'Stormbringer', 0, 1, 1, 932115, 9321006, 0, 0, '', 0, 0),
(932100, 11, 0, 'Sun Cleric', 0, 1, 1, 932112, 9321003, 0, 0, '', 0, 0),
(932100, 12, 0, 'Templar', 0, 1, 1, 932112, 9321002, 0, 0, '', 0, 0),
(932100, 13, 0, 'Tinker', 0, 1, 1, 932120, 9321013, 0, 0, '', 0, 0),
(932100, 14, 0, 'Witch Doctor', 0, 1, 1, 932113, 9321004, 0, 0, '', 0, 0),
(932100, 15, 0, 'Witch Hunter', 0, 1, 1, 932114, 9321005, 0, 0, '', 0, 0);

-- Ironforge: submenu 932101 (text copied from stock npc_text 2766), 11 class options, reached from 2121/14
--     (Ironforge Guard 5595).
--   leaf 932122: Barbarian Modor Tarmund guid 9004516 POI 9321020, Guardian Dagnan the Blade guid 9004517 POI
--       9321021; checked at the spawn: Hall of Arms, Military Ward (WMO area Hall of Arms)
--   leaf 932123: Primalist Threllin the Bearded guid 9004523 POI 9321022; checked at the spawn: Military Ward
--       square by the brazier (WMO area Hall of Arms; stock POI 61 Hall of Arms 8.8 yd)
--   leaf 932124: Templar Yelya Flinthammer guid 9004518 POI 9321023, Sun Cleric Sunbeard the Pious guid 9004519
--       POI 9321024; checked at the spawn: Hall of Mysteries: floor z 504 and gallery z 525 (WMO area Hall of
--       Mysteries)
--   leaf 932125: Necromancer Baralor Oathbreaker guid 9004525 POI 9321025, Cultist Dippo the Doomer guid 9004526
--       POI 9321026; checked at the spawn: The Forlorn Cavern (WMO area The Forlorn Cavern)
--   leaf 932126: Tinker Zipgear Zoombang guid 9004520 POI 9321027; checked at the spawn: Tinker Town cavern floor
--       (WMO area Tinker Town)
--   leaf 932127: Pyromancer Penny Pyrewhistle guid 9004521 POI 9321028; checked at the spawn: The Great Forge
--       floor (WMO area The Great Forge; stock POI 67 The Great Forge 13.6 yd)
--   leaf 932128: Stormbringer Kharaz Dak guid 9004524 POI 9321029; checked at the spawn: ring road of The Great
--       Forge, north-east side (WMO area The Great Forge; stock POI 65 16.7 yd)
--   leaf 932129: Runemaster Beelo Blitzcog guid 9004522 POI 9321030; checked at the spawn: Hall of Explorers
--       library gallery (WMO area The Library)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321020, 9321026, 9321021, 9321025, 9321022, 9321028, 9321030, 9321029, 9321024, 9321023, 9321027);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321020, 9321026, 9321021, 9321025, 9321022, 9321028, 9321030, 9321029, 9321024, 9321023, 9321027);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321020, -5054, -1251, 7, 99, 0, 'Ironforge Barbarian Trainer'),
(9321026, -4630, -1100, 7, 99, 0, 'Ironforge Cultist Trainer'),
(9321021, -5029, -1231, 7, 99, 0, 'Ironforge Guardian Trainer'),
(9321025, -4617, -1130, 7, 99, 0, 'Ironforge Necromancer Trainer'),
(9321022, -5026, -1262, 7, 99, 0, 'Ironforge Primalist Trainer'),
(9321028, -4806, -1101, 7, 99, 0, 'Ironforge Pyromancer Trainer'),
(9321030, -4609, -1254, 7, 99, 0, 'Ironforge Runemaster Trainer'),
(9321029, -4737, -1144, 7, 99, 0, 'Ironforge Stormbringer Trainer'),
(9321024, -4588.5, -896.5, 7, 99, 0, 'Ironforge Sun Cleric Trainer'),
(9321023, -4620.5, -896.5, 7, 99, 0, 'Ironforge Templar Trainer'),
(9321027, -4817, -1281, 7, 99, 0, 'Ironforge Tinker Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932101, 932122, 932123, 932124, 932125, 932126, 932127, 932128, 932129);
DELETE FROM `npc_text` WHERE `ID` IN (
    932101, 932122, 932123, 932124, 932125, 932126, 932127, 932128, 932129);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932101, 'Which class trainer might ye be looking for?', 'Which class trainer might ye be looking for?', 7000, 0, 1, 0),
(932122, 'March yerself over to the Hall of Arms in the Military Ward, east of the gates. Modor Tarmund trains the Barbarians there, and Dagnan the Blade the Guardians.', 'March yerself over to the Hall of Arms in the Military Ward, east of the gates. Modor Tarmund trains the Barbarians there, and Dagnan the Blade the Guardians.', 0, 0, 1, 0),
(932123, 'Threllin the Bearded? He''s out on the square of the Military Ward, by the brazier between the Hall of Arms and the hunters'' hall. Ye can''t miss the beard.', 'Threllin the Bearded? He''s out on the square of the Military Ward, by the brazier between the Hall of Arms and the hunters'' hall. Ye can''t miss the beard.', 0, 0, 1, 0),
(932124, 'Head north from the gates to the Hall of Mysteries. Yelya Flinthammer trains the Templars on the hall floor, and Sunbeard the Pious teaches the Sun Clerics up on the gallery.', 'Head north from the gates to the Hall of Mysteries. Yelya Flinthammer trains the Templars on the hall floor, and Sunbeard the Pious teaches the Sun Clerics up on the gallery.', 0, 0, 1, 0),
(932125, 'Where else would that lot gather but The Forlorn Cavern? Baralor Oathbreaker teaches the Necromancers and Dippo the Doomer the Cultists. Watch yer purse down there.', 'Where else would that lot gather but The Forlorn Cavern? Baralor Oathbreaker teaches the Necromancers and Dippo the Doomer the Cultists. Watch yer purse down there.', 0, 0, 1, 0),
(932126, 'Zipgear Zoombang is down in Tinker Town, east of the gates. Ye''ll find him on the cavern floor just past the tunnel in from the Commons.', 'Zipgear Zoombang is down in Tinker Town, east of the gates. Ye''ll find him on the cavern floor just past the tunnel in from the Commons.', 0, 0, 1, 0),
(932127, 'Penny Pyrewhistle works her flames at The Great Forge itself, beside the great bellows in the middle of the city.', 'Penny Pyrewhistle works her flames at The Great Forge itself, beside the great bellows in the middle of the city.', 0, 0, 1, 0),
(932128, 'Kharaz Dak can be found by The Great Forge, just a bit to the north on the east side, out on the ring road.', 'Kharaz Dak can be found by The Great Forge, just a bit to the north on the east side, out on the ring road.', 0, 0, 1, 0),
(932129, 'Beelo Blitzcog studies his runes in the Hall of Explorers, up on the library gallery beside the titan vase.', 'Beelo Blitzcog studies his runes in the Hall of Explorers, up on the library gallery beside the titan vase.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932101, 932122, 932123, 932124, 932125, 932126, 932127, 932128, 932129);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932101, 932101),
(932122, 932122),
(932123, 932123),
(932124, 932124),
(932125, 932125),
(932126, 932126),
(932127, 932127),
(932128, 932128),
(932129, 932129);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932101;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932101;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932101, 0, 0, 'Barbarian', 0, 1, 1, 932122, 9321020, 0, 0, '', 0, 0),
(932101, 1, 0, 'Cultist', 0, 1, 1, 932125, 9321026, 0, 0, '', 0, 0),
(932101, 2, 0, 'Guardian', 0, 1, 1, 932122, 9321021, 0, 0, '', 0, 0),
(932101, 3, 0, 'Necromancer', 0, 1, 1, 932125, 9321025, 0, 0, '', 0, 0),
(932101, 4, 0, 'Primalist', 0, 1, 1, 932123, 9321022, 0, 0, '', 0, 0),
(932101, 5, 0, 'Pyromancer', 0, 1, 1, 932127, 9321028, 0, 0, '', 0, 0),
(932101, 6, 0, 'Runemaster', 0, 1, 1, 932129, 9321030, 0, 0, '', 0, 0),
(932101, 7, 0, 'Stormbringer', 0, 1, 1, 932128, 9321029, 0, 0, '', 0, 0),
(932101, 8, 0, 'Sun Cleric', 0, 1, 1, 932124, 9321024, 0, 0, '', 0, 0),
(932101, 9, 0, 'Templar', 0, 1, 1, 932124, 9321023, 0, 0, '', 0, 0),
(932101, 10, 0, 'Tinker', 0, 1, 1, 932126, 9321027, 0, 0, '', 0, 0);

-- Darnassus: submenu 932102 (text copied from stock npc_text 3022), 13 class options, reached from 2352/12
--     (Darnassus Sentinel 4262), 10265/12 (no user (orphan copy of 2352)).
--   leaf 932130: Felsworn Pelinor Felsight guid 9004527 POI 9321040, Knight of Xoroth Zeltur'atha the Exile guid
--       9004528 POI 9321041; checked at the spawn: Warrior's Terrace upper walk (AreaTable 1660; stock POI 101
--       12.8 yd)
--   leaf 932131: Ranger Surellion Trueshot guid 9004532 POI 9321042; checked at the spawn: training dummies north
--       of the Warrior's Terrace (AreaTable 1660; dummies 4.7 yd)
--   leaf 932132: Templar Corinthia the Templar guid 9004530 POI 9321043, Starcaller Moonpriest Ty'lera guid
--       9004535 POI 9321044; checked at the spawn: Temple of the Moon (WMO area Temple of the Moon)
--   leaf 932133: Chronomancer Belladormi guid 9004533 POI 9321045; checked at the spawn: Temple Gardens, west
--       colonnade of the temple grounds (AreaTable 1661; Chief Archaeologist Greywhisker 9.7 yd)
--   leaf 932134: Stormbringer Pak Thunderhoof guid 9004529 POI 9321046; checked at the spawn: Temple Gardens islet
--       (WMO area The Temple Gardens; Firodren Mooncaller 12.7 yd)
--   leaf 932135: Primalist Mathrengyl Bearwalker guid 46472 POI 9321047; checked at the spawn: upper Cenarion
--       Enclave (WMO area Cenarion Enclave; stock druid POI 98 9.5 yd)
--   leaf 932136: Cultist Soliras Darkwoven guid 9004534 POI 9321048, Reaper Turalen Darkwhisper guid 9004537 POI
--       9321049; checked at the spawn: lower Cenarion Enclave cave, z 1284 (WMO area Cenarion Enclave)
--   leaf 932137: Bloodmage Lokirus Veinspiller guid 9004531 POI 9321050; checked at the spawn: Craftsmen's Terrace
--       alchemy hall (AreaTable 1659; Ainethil 11.5 yd)
--   leaf 932138: Tinker Baarus the Tinker guid 9004536 POI 9321051; checked at the spawn: Craftsmen's Terrace path
--       (AreaTable 1659; Mythrin'dir 14.7 yd)
--   leaf 932139: Runemaster Shayla Runewander guid 9004538 POI 9321052; checked at the spawn: Craftsmen's Terrace
--       enchanting hall (WMO area Craftsmen's Terrace; Taladan 8.1 yd)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321050, 9321045, 9321048, 9321040, 9321041, 9321047, 9321042, 9321049, 9321052, 9321044, 9321046, 9321043,
    9321051);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321050, 9321045, 9321048, 9321040, 9321041, 9321047, 9321042, 9321049, 9321052, 9321044, 9321046, 9321043,
    9321051);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321050, 10080, 2360, 7, 99, 0, 'Darnassus Bloodmage Trainer'),
(9321045, 9636, 2600, 7, 99, 0, 'Darnassus Chronomancer Trainer'),
(9321048, 10067, 2543, 7, 99, 0, 'Darnassus Cultist Trainer'),
(9321040, 9963, 2276, 7, 99, 0, 'Darnassus Felsworn Trainer'),
(9321041, 9973, 2289, 7, 99, 0, 'Darnassus Knight of Xoroth Trainer'),
(9321047, 10179, 2563.98, 7, 99, 0, 'Darnassus Primalist Trainer'),
(9321042, 9996.5, 2256.5, 7, 99, 0, 'Darnassus Ranger Trainer'),
(9321049, 10062, 2566, 7, 99, 0, 'Darnassus Reaper Trainer'),
(9321052, 10140, 2326, 7, 99, 0, 'Darnassus Runemaster Trainer'),
(9321044, 9620, 2540, 7, 99, 0, 'Darnassus Starcaller Trainer'),
(9321046, 9760.5, 2418.5, 7, 99, 0, 'Darnassus Stormbringer Trainer'),
(9321043, 9626, 2502, 7, 99, 0, 'Darnassus Templar Trainer'),
(9321051, 10112, 2307.5, 7, 99, 0, 'Darnassus Tinker Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932102, 932130, 932131, 932132, 932133, 932134, 932135, 932136, 932137, 932138, 932139);
DELETE FROM `npc_text` WHERE `ID` IN (
    932102, 932130, 932131, 932132, 932133, 932134, 932135, 932136, 932137, 932138, 932139);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932102, 'Here in Darnassus you will find skilled trainers who have perfected the skills of their chosen class through ages of training and dedication.  I will guide you to one who can become your mentor, you have but to name your chosen path.', 'Here in Darnassus you will find skilled trainers who have perfected the skills of their chosen class through ages of training and dedication.  I will guide you to one who can become your mentor, you have but to name your chosen path.', 5339, 0, 1, 0),
(932130, 'Those who bargain with fel powers are watched closely here. Pelinor Felsight, who trains the Felsworn, and Zeltur''atha the Exile, teacher of the Knights of Xoroth, keep to the upper walk of the Warrior''s Terrace.', 'Those who bargain with fel powers are watched closely here. Pelinor Felsight, who trains the Felsworn, and Zeltur''atha the Exile, teacher of the Knights of Xoroth, keep to the upper walk of the Warrior''s Terrace.', 0, 0, 1, 0),
(932131, 'Surellion Trueshot drills her Rangers at the training dummies just north of the Warrior''s Terrace. Follow the sound of her voice.', 'Surellion Trueshot drills her Rangers at the training dummies just north of the Warrior''s Terrace. Follow the sound of her voice.', 0, 0, 1, 0),
(932132, 'Both are welcome in the Temple of the Moon. Corinthia the Templar and Moonpriest Ty''lera of the Starcallers teach within its lower hall.', 'Both are welcome in the Temple of the Moon. Corinthia the Templar and Moonpriest Ty''lera of the Starcallers teach within its lower hall.', 0, 0, 1, 0),
(932133, 'Belladormi keeps to the western colonnade of the Temple of the Moon''s grounds, near the dwarven archaeologist Greywhisker.', 'Belladormi keeps to the western colonnade of the Temple of the Moon''s grounds, near the dwarven archaeologist Greywhisker.', 0, 0, 1, 0),
(932134, 'A draenei shaman, Pak Thunderhoof, has taken up a place on the islet of the Temple Gardens, near Firodren Mooncaller and the herbalists. Follow the garden path onto the islet.', 'A draenei shaman, Pak Thunderhoof, has taken up a place on the islet of the Temple Gardens, near Firodren Mooncaller and the herbalists. Follow the garden path onto the islet.', 0, 0, 1, 0),
(932135, 'Mathrengyl Bearwalker guides the Primalists from the Cenarion Enclave, in the northern section of Darnassus.', 'Mathrengyl Bearwalker guides the Primalists from the Cenarion Enclave, in the northern section of Darnassus.', 0, 0, 1, 0),
(932136, 'Soliras Darkwoven of the Cultists and Turalen Darkwhisper of the Reapers dwell in the Cenarion Enclave, down the spiraling path in the lower cave where the rogues gather.', 'Soliras Darkwoven of the Cultists and Turalen Darkwhisper of the Reapers dwell in the Cenarion Enclave, down the spiraling path in the lower cave where the rogues gather.', 0, 0, 1, 0),
(932137, 'Lokirus Veinspiller waits at the open mouth of the alchemy hall on the Craftsmen''s Terrace, near the alchemist Ainethil.', 'Lokirus Veinspiller waits at the open mouth of the alchemy hall on the Craftsmen''s Terrace, near the alchemist Ainethil.', 0, 0, 1, 0),
(932138, 'Baarus the Tinker, a draenei, works on the Craftsmen''s Terrace outside Mythrin''dir''s trade supplies shop.', 'Baarus the Tinker, a draenei, works on the Craftsmen''s Terrace outside Mythrin''dir''s trade supplies shop.', 0, 0, 1, 0),
(932139, 'Shayla Runewander studies her runes in the enchanting hall on the Craftsmen''s Terrace, beside Taladan.', 'Shayla Runewander studies her runes in the enchanting hall on the Craftsmen''s Terrace, beside Taladan.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932102, 932130, 932131, 932132, 932133, 932134, 932135, 932136, 932137, 932138, 932139);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932102, 932102),
(932130, 932130),
(932131, 932131),
(932132, 932132),
(932133, 932133),
(932134, 932134),
(932135, 932135),
(932136, 932136),
(932137, 932137),
(932138, 932138),
(932139, 932139);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932102;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932102;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932102, 0, 0, 'Bloodmage', 0, 1, 1, 932137, 9321050, 0, 0, '', 0, 0),
(932102, 1, 0, 'Chronomancer', 0, 1, 1, 932133, 9321045, 0, 0, '', 0, 0),
(932102, 2, 0, 'Cultist', 0, 1, 1, 932136, 9321048, 0, 0, '', 0, 0),
(932102, 3, 0, 'Felsworn', 0, 1, 1, 932130, 9321040, 0, 0, '', 0, 0),
(932102, 4, 0, 'Knight of Xoroth', 0, 1, 1, 932130, 9321041, 0, 0, '', 0, 0),
(932102, 5, 0, 'Primalist', 0, 1, 1, 932135, 9321047, 0, 0, '', 0, 0),
(932102, 6, 0, 'Ranger', 0, 1, 1, 932131, 9321042, 0, 0, '', 0, 0),
(932102, 7, 0, 'Reaper', 0, 1, 1, 932136, 9321049, 0, 0, '', 0, 0),
(932102, 8, 0, 'Runemaster', 0, 1, 1, 932139, 9321052, 0, 0, '', 0, 0),
(932102, 9, 0, 'Starcaller', 0, 1, 1, 932132, 9321044, 0, 0, '', 0, 0),
(932102, 10, 0, 'Stormbringer', 0, 1, 1, 932134, 9321046, 0, 0, '', 0, 0),
(932102, 11, 0, 'Templar', 0, 1, 1, 932132, 9321043, 0, 0, '', 0, 0),
(932102, 12, 0, 'Tinker', 0, 1, 1, 932138, 9321051, 0, 0, '', 0, 0);

-- The Exodar: submenu 932103 (text copied from stock npc_text 9533), 14 class options, reached from 7777/11 (Exodar
--     Peacekeeper 16733).
--   leaf 932140: Felsworn Haraaz Felscar guid 9004814 POI 9321060; checked at the spawn: Hunters' Sanctum terrace,
--       Trader's Tier (WMO area Trader's Tier)
--   leaf 932141: Stormbringer Kuraax Stormspeaker guid 9004816 POI 9321061; checked at the spawn: Crystal Hall,
--       east rim of the shamans' stones (WMO area The Crystal Hall)
--   leaf 932142: Knight of Xoroth Vorathaan Ashmantle guid 9004817 POI 9321062; checked at the spawn: forge hall,
--       lower Trader's Tier (WMO area Trader's Tier; stock POIs 206/215 25-28 yd)
--   leaf 932143: Guardian Warden Iruvaa guid 9004818 POI 9321063; checked at the spawn: Warriors' Terrace rim,
--       upper Trader's Tier (WMO area Trader's Tier; stock warrior POI 204 20 yd)
--   leaf 932144: Templar Lightwarden Moraala guid 9004819 POI 9321064; checked at the spawn: Vault of Lights,
--       among the armour stands (WMO area The Vault of Lights; stock paladin POI 201 4.7 yd)
--   leaf 932145: Chronomancer Archivist Tolaara guid 9004822 POI 9321065; checked at the spawn: Vault of Lights
--       emitters (WMO area The Vault of Lights)
--   leaf 932146: Necromancer Soulbinder Kaarun guid 9004823 POI 9321066; checked at the spawn: outside the
--       anchorites' chamber, between the Seat of the Naaru and the Vault of Lights (WMO area The Vault of Lights)
--   leaf 932147: Pyromancer Ilaara Cindervow guid 9004824 POI 9321067; checked at the spawn: Crystal Hall south
--       gate braziers (WMO area The Crystal Hall)
--   leaf 932148: Cultist Nyrosha the Veiled guid 9004825 POI 9321068; checked at the spawn: crystal mine beyond
--       the Crystal Hall (WMO area The Crystal Hall; Broken Miner 10.5 yd)
--   leaf 932149: Starcaller Starseer Naliima guid 9004826 POI 9321069; checked at the spawn: rim of the Seat of
--       the Naaru (WMO area Seat of the Naaru)
--   leaf 932150: Tinker Technician Draalon guid 9004828 POI 9321070; checked at the spawn: power crystals
--       (Exodar_Crystal_Large 17-20 yd; Artificers Drenin 10.6 yd, Andren 12.4 yd)
--   leaf 932151: Reaper Morvaal the Grim guid 9004830 POI 9321071; checked at the spawn: armoury at the back of
--       the Trader's Tier (WMO area Trader's Tier)
--   leaf 932152: Primalist Wildkeeper Oraana guid 9004831 POI 9321072; checked at the spawn: moth keeper's
--       platform, Crystal Hall (WMO area The Crystal Hall; Sixx 11.3 yd)
--   leaf 932153: Runemaster Runecarver Iskaar guid 9004832 POI 9321073; checked at the spawn: enchanters' corner,
--       Crystal Hall (WMO area The Crystal Hall; stock POI 207 Enchanters 20 yd)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321065, 9321068, 9321060, 9321063, 9321062, 9321066, 9321072, 9321067, 9321071, 9321073, 9321069, 9321061,
    9321064, 9321070);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321065, 9321068, 9321060, 9321063, 9321062, 9321066, 9321072, 9321067, 9321071, 9321073, 9321069, 9321061,
    9321064, 9321070);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321065, -4078.5, -11433.5, 7, 99, 0, 'Exodar Chronomancer Trainer'),
(9321068, -3700, -11540, 7, 99, 0, 'Exodar Cultist Trainer'),
(9321060, -4212, -11583, 7, 99, 0, 'Exodar Felsworn Trainer'),
(9321063, -4174, -11648, 7, 99, 0, 'Exodar Guardian Trainer'),
(9321062, -4246, -11686, 7, 99, 0, 'Exodar Knight of Xoroth Trainer'),
(9321066, -4002, -11510, 7, 99, 0, 'Exodar Necromancer Trainer'),
(9321072, -3852, -11395, 7, 99, 0, 'Exodar Primalist Trainer'),
(9321067, -3833, -11527, 7, 99, 0, 'Exodar Pyromancer Trainer'),
(9321071, -4232, -11805, 7, 99, 0, 'Exodar Reaper Trainer'),
(9321073, -3887, -11514, 7, 99, 0, 'Exodar Runemaster Trainer'),
(9321069, -3890, -11631, 7, 99, 0, 'Exodar Starcaller Trainer'),
(9321061, -3797, -11470, 7, 99, 0, 'Exodar Stormbringer Trainer'),
(9321064, -4176.5, -11481.5, 7, 99, 0, 'Exodar Templar Trainer'),
(9321070, -3958, -11760, 7, 99, 0, 'Exodar Tinker Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932103, 932140, 932141, 932142, 932143, 932144, 932145, 932146, 932147, 932148, 932149, 932150, 932151,
    932152, 932153);
DELETE FROM `npc_text` WHERE `ID` IN (
    932103, 932140, 932141, 932142, 932143, 932144, 932145, 932146, 932147, 932148, 932149, 932150, 932151,
    932152, 932153);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932103, 'What trainer do you seek?', 'What trainer do you seek?', 15819, 0, 1, 0),
(932140, 'Haraaz Felscar keeps to the terrace of the Hunters'' Sanctum on the Trader''s Tier. Climb the ramp up from the forge hall.', 'Haraaz Felscar keeps to the terrace of the Hunters'' Sanctum on the Trader''s Tier. Climb the ramp up from the forge hall.', 0, 0, 1, 0),
(932141, 'Kuraax Stormspeaker stands in the Crystal Hall, by the brazier at the rim of the shamans'' circle of stones. Light be with you.', 'Kuraax Stormspeaker stands in the Crystal Hall, by the brazier at the rim of the shamans'' circle of stones. Light be with you.', 0, 0, 1, 0),
(932142, 'Vorathaan Ashmantle trains in the forge hall on the lower level of the Trader''s Tier, between the forges and the engineering benches.', 'Vorathaan Ashmantle trains in the forge hall on the lower level of the Trader''s Tier, between the forges and the engineering benches.', 0, 0, 1, 0),
(932143, 'Warden Iruvaa stands at the rim of the Warriors'' Terrace, overlooking the rest of the Trader''s Tier.', 'Warden Iruvaa stands at the rim of the Warriors'' Terrace, overlooking the rest of the Trader''s Tier.', 0, 0, 1, 0),
(932144, 'Lightwarden Moraala instructs the Templars in the Vault of Lights, among the vindicators'' armour stands. Go with the Light.', 'Lightwarden Moraala instructs the Templars in the Vault of Lights, among the vindicators'' armour stands. Go with the Light.', 0, 0, 1, 0),
(932145, 'Archivist Tolaara studies the records of our past among the light emitters of the Vault of Lights.', 'Archivist Tolaara studies the records of our past among the light emitters of the Vault of Lights.', 0, 0, 1, 0),
(932146, 'Soulbinder Kaarun of the Auchenai keeps apart from the anchorites. He stands outside their chamber, on the way from the Seat of the Naaru to the Vault of Lights.', 'Soulbinder Kaarun of the Auchenai keeps apart from the anchorites. He stands outside their chamber, on the way from the Seat of the Naaru to the Vault of Lights.', 0, 0, 1, 0),
(932147, 'Ilaara Cindervow tends the braziers at the south gate of the Crystal Hall, where the road passes between them.', 'Ilaara Cindervow tends the braziers at the south gate of the Crystal Hall, where the road passes between them.', 0, 0, 1, 0),
(932148, 'Nyrosha the Veiled hides herself away in the crystal mine beyond the Crystal Hall, where the Broken miners work.', 'Nyrosha the Veiled hides herself away in the crystal mine beyond the Crystal Hall, where the Broken miners work.', 0, 0, 1, 0),
(932149, 'Starseer Naliima stands at the rim of the Seat of the Naaru, above O''ros. Light be with you.', 'Starseer Naliima stands at the rim of the Seat of the Naaru, above O''ros. Light be with you.', 0, 0, 1, 0),
(932150, 'Technician Draalon works at the Exodar''s great power crystals, in front of the artificers Andren and Drenin.', 'Technician Draalon works at the Exodar''s great power crystals, in front of the artificers Andren and Drenin.', 0, 0, 1, 0),
(932151, 'Morvaal the Grim keeps to the armoury at the back of the Trader''s Tier, by the weapon racks of the blade shop.', 'Morvaal the Grim keeps to the armoury at the back of the Trader''s Tier, by the weapon racks of the blade shop.', 0, 0, 1, 0),
(932152, 'Wildkeeper Oraana tends the moth keeper''s platform in the Crystal Hall, with Sixx and his moths.', 'Wildkeeper Oraana tends the moth keeper''s platform in the Crystal Hall, with Sixx and his moths.', 0, 0, 1, 0),
(932153, 'Runecarver Iskaar teaches in the Crystal Hall, in the enchanters'' corner by the Lexicon of Power.', 'Runecarver Iskaar teaches in the Crystal Hall, in the enchanters'' corner by the Lexicon of Power.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932103, 932140, 932141, 932142, 932143, 932144, 932145, 932146, 932147, 932148, 932149, 932150, 932151,
    932152, 932153);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932103, 932103),
(932140, 932140),
(932141, 932141),
(932142, 932142),
(932143, 932143),
(932144, 932144),
(932145, 932145),
(932146, 932146),
(932147, 932147),
(932148, 932148),
(932149, 932149),
(932150, 932150),
(932151, 932151),
(932152, 932152),
(932153, 932153);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932103;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932103;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932103, 0, 0, 'Chronomancer', 0, 1, 1, 932145, 9321065, 0, 0, '', 0, 0),
(932103, 1, 0, 'Cultist', 0, 1, 1, 932148, 9321068, 0, 0, '', 0, 0),
(932103, 2, 0, 'Felsworn', 0, 1, 1, 932140, 9321060, 0, 0, '', 0, 0),
(932103, 3, 0, 'Guardian', 0, 1, 1, 932143, 9321063, 0, 0, '', 0, 0),
(932103, 4, 0, 'Knight of Xoroth', 0, 1, 1, 932142, 9321062, 0, 0, '', 0, 0),
(932103, 5, 0, 'Necromancer', 0, 1, 1, 932146, 9321066, 0, 0, '', 0, 0),
(932103, 6, 0, 'Primalist', 0, 1, 1, 932152, 9321072, 0, 0, '', 0, 0),
(932103, 7, 0, 'Pyromancer', 0, 1, 1, 932147, 9321067, 0, 0, '', 0, 0),
(932103, 8, 0, 'Reaper', 0, 1, 1, 932151, 9321071, 0, 0, '', 0, 0),
(932103, 9, 0, 'Runemaster', 0, 1, 1, 932153, 9321073, 0, 0, '', 0, 0),
(932103, 10, 0, 'Starcaller', 0, 1, 1, 932149, 9321069, 0, 0, '', 0, 0),
(932103, 11, 0, 'Stormbringer', 0, 1, 1, 932141, 9321061, 0, 0, '', 0, 0),
(932103, 12, 0, 'Templar', 0, 1, 1, 932144, 9321064, 0, 0, '', 0, 0),
(932103, 13, 0, 'Tinker', 0, 1, 1, 932150, 9321070, 0, 0, '', 0, 0);

-- Orgrimmar: submenu 932104 (text copied from stock npc_text 2599), 15 class options, reached from 1951/15
--     (Orgrimmar Grunt 3296).
--   leaf 932154: Barbarian Zulaka'jin guid 9004650 POI 9321080, Guardian Grunt Korthaka guid 9004651 POI 9321081;
--       checked at the spawn: Hall of the Brave, Valley of Honor (WMO area Hall of the Brave)
--   leaf 932155: Ranger Grok-gar guid 9004652 POI 9321082; checked at the spawn: Hunter's Hall courtyard, Valley
--       of Honor (stock POI 300 7.9 yd)
--   leaf 932156: Tinker Engineer Rothakk guid 9004653 POI 9321083; checked at the spawn: Nogg's Machine Shop,
--       Valley of Honor (Nogg 6.9 yd, Roxxik 7.1 yd)
--   leaf 932157: Knight of Xoroth Xevaroth guid 9004654 POI 9321084, Necromancer Deathmagus Gorat guid 9004655 POI
--       9321085; checked at the spawn: Darkfire Enclave, Cleft of Shadow (WMO area Cleft of Shadow; stock POI 305
--       6-20 yd)
--   leaf 932158: Felsworn Xantis the Slayer guid 9004656 POI 9321086; checked at the spawn: Neeru Fireblade's den,
--       Cleft of Shadow (WMO area Cleft of Shadow; Neeru 4.5 yd)
--   leaf 932159: Cultist Rokia Lohka guid 9004657 POI 9321087; checked at the spawn: head of the passage to
--       Ragefire Chasm, Cleft of Shadow (WMO area Cleft of Shadow)
--   leaf 932160: Witch Doctor Zerin'dai guid 9004658 POI 9321088; checked at the spawn: Rekkul's poison shop,
--       Cleft of Shadow (WMO area Cleft of Shadow; Rekkul 7.0 yd)
--   leaf 932161: Venomancer Wun'zujek guid 9004659 POI 9321089; checked at the spawn: Shadowswift Brotherhood
--       ledge, Cleft of Shadow (stock POI 304 16.2 yd)
--   leaf 932162: Stormbringer Darakka Stormsworn guid 9004660 POI 9321090, Primalist Thako Maz guid 9004661 POI
--       9321091; checked at the spawn: entrance room of Grommash Hold, Valley of Wisdom (WMO area Grommash Hold;
--       Elder Far Seer Zor Lonetree 4.9 yd)
--   leaf 932163: Pyromancer Murthakk Krulk guid 9004662 POI 9321092, Bloodmage Sul'natu Hearteater guid 9004663
--       POI 9321093; checked at the spawn: Darkbriar Lodge ground floor, Valley of Spirits (WMO area Valley of
--       Spirits; stock POI 301 9-26 yd)
--   leaf 932164: Runemaster Washu Zebuljin guid 9004664 POI 9321094; checked at the spawn: Darkbriar Lodge upper
--       floor (z 59; portal trainer Thuul 6.4 yd)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321080, 9321093, 9321087, 9321086, 9321081, 9321084, 9321085, 9321091, 9321092, 9321082, 9321094, 9321090,
    9321083, 9321089, 9321088);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321080, 9321093, 9321087, 9321086, 9321081, 9321084, 9321085, 9321091, 9321092, 9321082, 9321094, 9321090,
    9321083, 9321089, 9321088);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321080, 1983, -4801.5, 7, 99, 0, 'Orgrimmar Barbarian Trainer'),
(9321093, 1460, -4225, 7, 99, 0, 'Orgrimmar Bloodmage Trainer'),
(9321087, 1804, -4392, 7, 99, 0, 'Orgrimmar Cultist Trainer'),
(9321086, 1804, -4377.5, 7, 99, 0, 'Orgrimmar Felsworn Trainer'),
(9321081, 1972, -4790, 7, 99, 0, 'Orgrimmar Guardian Trainer'),
(9321084, 1831, -4353, 7, 99, 0, 'Orgrimmar Knight of Xoroth Trainer'),
(9321085, 1846, -4364.5, 7, 99, 0, 'Orgrimmar Necromancer Trainer'),
(9321091, 1919.5, -4227, 7, 99, 0, 'Orgrimmar Primalist Trainer'),
(9321092, 1477, -4228, 7, 99, 0, 'Orgrimmar Pyromancer Trainer'),
(9321082, 2112, -4618, 7, 99, 0, 'Orgrimmar Ranger Trainer'),
(9321094, 1469.5, -4226.5, 7, 99, 0, 'Orgrimmar Runemaster Trainer'),
(9321090, 1938, -4215.5, 7, 99, 0, 'Orgrimmar Stormbringer Trainer'),
(9321083, 2032, -4752, 7, 99, 0, 'Orgrimmar Tinker Trainer'),
(9321089, 1789, -4274.5, 7, 99, 0, 'Orgrimmar Venomancer Trainer'),
(9321088, 1817, -4274.5, 7, 99, 0, 'Orgrimmar Witch Doctor Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932104, 932154, 932155, 932156, 932157, 932158, 932159, 932160, 932161, 932162, 932163, 932164);
DELETE FROM `npc_text` WHERE `ID` IN (
    932104, 932154, 932155, 932156, 932157, 932158, 932159, 932160, 932161, 932162, 932163, 932164);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932104, 'Which trainer do you seek?', 'Which trainer do you seek?', 6769, 1, 1, 0),
(932154, 'Go to the Hall of the Brave in the Valley of Honor. Zulaka''jin trains the Barbarians beside the sparring pit, and Grunt Korthaka the Guardians on its south rim.', 'Go to the Hall of the Brave in the Valley of Honor. Zulaka''jin trains the Barbarians beside the sparring pit, and Grunt Korthaka the Guardians on its south rim.', 0, 0, 1, 0),
(932155, 'Grok-gar trains the Rangers in the courtyard of the Hunter''s Hall in the Valley of Honor, west of the Coliseum.', 'Grok-gar trains the Rangers in the courtyard of the Hunter''s Hall in the Valley of Honor, west of the Coliseum.', 0, 0, 1, 0),
(932156, 'Engineer Rothakk works in Nogg''s Machine Shop in the Valley of Honor. Mind the sparks.', 'Engineer Rothakk works in Nogg''s Machine Shop in the Valley of Honor. Mind the sparks.', 0, 0, 1, 0),
(932157, 'Look in the Darkfire Enclave, down in the Cleft of Shadow. Xevaroth teaches the Knights of Xoroth in its entrance chamber, and Deathmagus Gorat the Necromancers in the main room.', 'Look in the Darkfire Enclave, down in the Cleft of Shadow. Xevaroth teaches the Knights of Xoroth in its entrance chamber, and Deathmagus Gorat the Necromancers in the main room.', 0, 0, 1, 0),
(932158, 'Xantis the Slayer trains the Felsworn in the depths of the Cleft of Shadow, beside Neeru Fireblade.', 'Xantis the Slayer trains the Felsworn in the depths of the Cleft of Shadow, beside Neeru Fireblade.', 0, 0, 1, 0),
(932159, 'Rokia Lohka gathers her Cultists deep in the Cleft of Shadow, at the head of the passage down to Ragefire Chasm.', 'Rokia Lohka gathers her Cultists deep in the Cleft of Shadow, at the head of the passage down to Ragefire Chasm.', 0, 0, 1, 0),
(932160, 'Zerin''dai brews beside the cauldron at Rekkul''s poison shop in the Cleft of Shadow.', 'Zerin''dai brews beside the cauldron at Rekkul''s poison shop in the Cleft of Shadow.', 0, 0, 1, 0),
(932161, 'Wun''zujek keeps to the ledge of the Shadowswift Brotherhood in the Cleft of Shadow. Take the tunnel down from The Drag.', 'Wun''zujek keeps to the ledge of the Shadowswift Brotherhood in the Cleft of Shadow. Take the tunnel down from The Drag.', 0, 0, 1, 0),
(932162, 'Go to the entrance room of Grommash Hold in the Valley of Wisdom, where the shamans keep their fire. Darakka Stormsworn trains the Stormbringers there, and Thako Maz the Primalists.', 'Go to the entrance room of Grommash Hold in the Valley of Wisdom, where the shamans keep their fire. Darakka Stormsworn trains the Stormbringers there, and Thako Maz the Primalists.', 0, 0, 1, 0),
(932163, 'Go to the Darkbriar Lodge in the Valley of Spirits, up above and to the west of the Valley of Strength. Murthakk Krulk trains the Pyromancers and Sul''natu Hearteater the Bloodmages on the ground floor.', 'Go to the Darkbriar Lodge in the Valley of Spirits, up above and to the west of the Valley of Strength. Murthakk Krulk trains the Pyromancers and Sul''natu Hearteater the Bloodmages on the ground floor.', 0, 0, 1, 0),
(932164, 'Washu Zebuljin studies upstairs in the Darkbriar Lodge in the Valley of Spirits, near the portal trainer Thuul.', 'Washu Zebuljin studies upstairs in the Darkbriar Lodge in the Valley of Spirits, near the portal trainer Thuul.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932104, 932154, 932155, 932156, 932157, 932158, 932159, 932160, 932161, 932162, 932163, 932164);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932104, 932104),
(932154, 932154),
(932155, 932155),
(932156, 932156),
(932157, 932157),
(932158, 932158),
(932159, 932159),
(932160, 932160),
(932161, 932161),
(932162, 932162),
(932163, 932163),
(932164, 932164);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932104;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932104;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932104, 0, 0, 'Barbarian', 0, 1, 1, 932154, 9321080, 0, 0, '', 0, 0),
(932104, 1, 0, 'Bloodmage', 0, 1, 1, 932163, 9321093, 0, 0, '', 0, 0),
(932104, 2, 0, 'Cultist', 0, 1, 1, 932159, 9321087, 0, 0, '', 0, 0),
(932104, 3, 0, 'Felsworn', 0, 1, 1, 932158, 9321086, 0, 0, '', 0, 0),
(932104, 4, 0, 'Guardian', 0, 1, 1, 932154, 9321081, 0, 0, '', 0, 0),
(932104, 5, 0, 'Knight of Xoroth', 0, 1, 1, 932157, 9321084, 0, 0, '', 0, 0),
(932104, 6, 0, 'Necromancer', 0, 1, 1, 932157, 9321085, 0, 0, '', 0, 0),
(932104, 7, 0, 'Primalist', 0, 1, 1, 932162, 9321091, 0, 0, '', 0, 0),
(932104, 8, 0, 'Pyromancer', 0, 1, 1, 932163, 9321092, 0, 0, '', 0, 0),
(932104, 9, 0, 'Ranger', 0, 1, 1, 932155, 9321082, 0, 0, '', 0, 0),
(932104, 10, 0, 'Runemaster', 0, 1, 1, 932164, 9321094, 0, 0, '', 0, 0),
(932104, 11, 0, 'Stormbringer', 0, 1, 1, 932162, 9321090, 0, 0, '', 0, 0),
(932104, 12, 0, 'Tinker', 0, 1, 1, 932156, 9321083, 0, 0, '', 0, 0),
(932104, 13, 0, 'Venomancer', 0, 1, 1, 932161, 9321089, 0, 0, '', 0, 0),
(932104, 14, 0, 'Witch Doctor', 0, 1, 1, 932160, 9321088, 0, 0, '', 0, 0);

-- Undercity: submenu 932105 (text copied from stock npc_text 3542), 18 class options, reached from 2849/14
--     (Undercity Guardian 5624), 10769/14 (Kor'kron Overseer 36213).
--   leaf 932165: Felsworn Thimakria Dilanore guid 9004665 POI 9321100, Necromancer Kobidus the Lich guid 9004666
--       POI 9321101; checked at the spawn: Magic Quarter trainers' pit, z -61 (WMO area Magic Quarter; stock POIs
--       331/334 7.7 yd)
--   leaf 932166: Chronomancer Nyrmedormi guid 9004668 POI 9321102, Bloodmage Belinaros Cicero guid 9004669 POI
--       9321103; checked at the spawn: Magic Quarter portal room, z -46 (WMO area Magic Quarter; Lexington Mortaim
--       6.9 yd)
--   leaf 932167: Runemaster Thalen Mackenzie guid 9004667 POI 9321104; checked at the spawn: Anastasia Hartwell's
--       study, Magic Quarter upper level (Anastasia 3.8 yd)
--   leaf 932168: Pyromancer Ridley of Lordaeron guid 9004670 POI 9321105; checked at the spawn: War Quarter forge,
--       inner ring (WMO area War Quarter; Samuel Van Brunt 6.1 yd, stock POI 337 10.3 yd)
--   leaf 932169: Barbarian Ray'chelle Greenhill guid 9004689 POI 9321117, Guardian Deathguard Solor guid 9004671
--       POI 9321106, Knight of Xoroth Galgrimorth guid 9004672 POI 9321107, Templar Benjamin the Sinless guid
--       9004673 POI 9321108, Starcaller Fal'ador Yanille guid 9004674 POI 9321109, Cultist Vytalas the Dreamer
--       guid 9004675 POI 9321110; checked at the spawn: War Quarter round hall, outer ring (WMO area War Quarter)
--       and the island in its middle (same Undercity.wmo floor at z -57.2; Christoph Walker's removed warrior post
--       5.8 yd)
--   leaf 932170: Sun Cleric Lightspeaker Shaylan guid 9004676 POI 9321111; checked at the spawn: War Quarter east
--       corridor at the pit rim (WMO area War Quarter; stock priest POI 332 3.3 yd)
--   leaf 932171: Reaper Sidus the Soul-Collector guid 9004681 POI 9321112; checked at the spawn: training dummies
--       on the ring below the War Quarter (WMO area War Quarter; dummies 5-8 yd)
--   leaf 932172: Ranger Sigi Mikayla guid 9004677 POI 9321113, Witch Hunter Phineas the Fervent guid 9004678 POI
--       9321114, Stormbringer Harold Garett guid 9004679 POI 9321115; checked at the spawn: Rogues' Quarter open
--       floor (WMO area Rogues' Quarter; stock POI 333 13-16 yd)
--   leaf 932173: Tinker Ol' Jimbles guid 9004680 POI 9321116; checked at the spawn: engineers' stalls, Rogues'
--       Quarter outer ring (Franklin Lloyd 10.0 yd, stock POI 340 5.6 yd)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321117, 9321103, 9321102, 9321110, 9321100, 9321106, 9321107, 9321101, 9321105, 9321113, 9321112, 9321104,
    9321109, 9321115, 9321111, 9321108, 9321116, 9321114);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321117, 9321103, 9321102, 9321110, 9321100, 9321106, 9321107, 9321101, 9321105, 9321113, 9321112, 9321104,
    9321109, 9321115, 9321111, 9321108, 9321116, 9321114);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321117, 1775.5, 426, 7, 99, 0, 'Undercity Barbarian Trainer'),
(9321103, 1770.5, 69.5, 7, 99, 0, 'Undercity Bloodmage Trainer'),
(9321102, 1774, 60, 7, 99, 0, 'Undercity Chronomancer Trainer'),
(9321110, 1751.5, 423, 7, 99, 0, 'Undercity Cultist Trainer'),
(9321100, 1788.5, 51, 7, 99, 0, 'Undercity Felsworn Trainer'),
(9321106, 1797, 428, 7, 99, 0, 'Undercity Guardian Trainer'),
(9321107, 1796.5, 404, 7, 99, 0, 'Undercity Knight of Xoroth Trainer'),
(9321101, 1762.5, 73.5, 7, 99, 0, 'Undercity Necromancer Trainer'),
(9321105, 1688, 278.5, 7, 99, 0, 'Undercity Pyromancer Trainer'),
(9321113, 1408, 72, 7, 99, 0, 'Undercity Ranger Trainer'),
(9321112, 1767, 356, 7, 99, 0, 'Undercity Reaper Trainer'),
(9321104, 1812.5, 60, 7, 99, 0, 'Undercity Runemaster Trainer'),
(9321109, 1766, 441.5, 7, 99, 0, 'Undercity Starcaller Trainer'),
(9321115, 1430, 57, 7, 99, 0, 'Undercity Stormbringer Trainer'),
(9321111, 1761, 403.5, 7, 99, 0, 'Undercity Sun Cleric Trainer'),
(9321108, 1783, 441, 7, 99, 0, 'Undercity Templar Trainer'),
(9321116, 1414, 142, 7, 99, 0, 'Undercity Tinker Trainer'),
(9321114, 1403, 64, 7, 99, 0, 'Undercity Witch Hunter Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932105, 932165, 932166, 932167, 932168, 932169, 932170, 932171, 932172, 932173);
DELETE FROM `npc_text` WHERE `ID` IN (
    932105, 932165, 932166, 932167, 932168, 932169, 932170, 932171, 932172, 932173);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932105, 'Which trainer do you seek?', 'Which trainer do you seek?', 6769, 1, 1, 0),
(932165, 'Magic Quarter. Thimakria Dilanore trains the Felsworn down in the trainers'' pit, by the east ramp. Kobidus the Lich, the Necromancer, stands on the walk at the edge of the pit.', 'Magic Quarter. Thimakria Dilanore trains the Felsworn down in the trainers'' pit, by the east ramp. Kobidus the Lich, the Necromancer, stands on the walk at the edge of the pit.', 0, 0, 1, 0),
(932166, 'Magic Quarter, the portal room on the upper level. Nyrmedormi teaches the Chronomancers there and Belinaros Cicero the Bloodmages.', 'Magic Quarter, the portal room on the upper level. Nyrmedormi teaches the Chronomancers there and Belinaros Cicero the Bloodmages.', 0, 0, 1, 0),
(932167, 'Thalen Mackenzie is in Anastasia Hartwell''s study, on the upper level of the Magic Quarter.', 'Thalen Mackenzie is in Anastasia Hartwell''s study, on the upper level of the Magic Quarter.', 0, 0, 1, 0),
(932168, 'Ridley of Lordaeron works the forge in the War Quarter with the Van Brunts. He is on the inner ring.', 'Ridley of Lordaeron works the forge in the War Quarter with the Van Brunts. He is on the inner ring.', 0, 0, 1, 0),
(932169, 'The round hall of the War Quarter. Ray''chelle Greenhill trains the Barbarians on the island in its middle, over one of the bridges. On the outer ring, Deathguard Solor trains the Guardians by the north entrance. Galgrimorth of the Knights of Xoroth, Benjamin the Sinless of the Templars, Fal''ador Yanille of the Starcallers and Vytalas the Dreamer of the Cultists stand around the hall.', 'The round hall of the War Quarter. Ray''chelle Greenhill trains the Barbarians on the island in its middle, over one of the bridges. On the outer ring, Deathguard Solor trains the Guardians by the north entrance. Galgrimorth of the Knights of Xoroth, Benjamin the Sinless of the Templars, Fal''ador Yanille of the Starcallers and Vytalas the Dreamer of the Cultists stand around the hall.', 0, 0, 1, 0),
(932170, 'Lightspeaker Shaylan teaches in the War Quarter, in the east corridor at the rim of the pit, where the priests gather.', 'Lightspeaker Shaylan teaches in the War Quarter, in the east corridor at the rim of the pit, where the priests gather.', 0, 0, 1, 0),
(932171, 'Sidus the Soul-Collector waits behind the training dummies on the ring below the War Quarter.', 'Sidus the Soul-Collector waits behind the training dummies on the ring below the War Quarter.', 0, 0, 1, 0),
(932172, 'Rogues'' Quarter. Sigi Mikayla trains the Rangers, Phineas the Fervent the Witch Hunters and Harold Garett the Stormbringers, all out in the open quarter.', 'Rogues'' Quarter. Sigi Mikayla trains the Rangers, Phineas the Fervent the Witch Hunters and Harold Garett the Stormbringers, all out in the open quarter.', 0, 0, 1, 0),
(932173, 'Ol'' Jimbles tinkers with the engineers in the Rogues'' Quarter, on the outer ring, near Franklin Lloyd.', 'Ol'' Jimbles tinkers with the engineers in the Rogues'' Quarter, on the outer ring, near Franklin Lloyd.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932105, 932165, 932166, 932167, 932168, 932169, 932170, 932171, 932172, 932173);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932105, 932105),
(932165, 932165),
(932166, 932166),
(932167, 932167),
(932168, 932168),
(932169, 932169),
(932170, 932170),
(932171, 932171),
(932172, 932172),
(932173, 932173);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932105;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932105;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932105, 0, 0, 'Barbarian', 0, 1, 1, 932169, 9321117, 0, 0, '', 0, 0),
(932105, 1, 0, 'Bloodmage', 0, 1, 1, 932166, 9321103, 0, 0, '', 0, 0),
(932105, 2, 0, 'Chronomancer', 0, 1, 1, 932166, 9321102, 0, 0, '', 0, 0),
(932105, 3, 0, 'Cultist', 0, 1, 1, 932169, 9321110, 0, 0, '', 0, 0),
(932105, 4, 0, 'Felsworn', 0, 1, 1, 932165, 9321100, 0, 0, '', 0, 0),
(932105, 5, 0, 'Guardian', 0, 1, 1, 932169, 9321106, 0, 0, '', 0, 0),
(932105, 6, 0, 'Knight of Xoroth', 0, 1, 1, 932169, 9321107, 0, 0, '', 0, 0),
(932105, 7, 0, 'Necromancer', 0, 1, 1, 932165, 9321101, 0, 0, '', 0, 0),
(932105, 8, 0, 'Pyromancer', 0, 1, 1, 932168, 9321105, 0, 0, '', 0, 0),
(932105, 9, 0, 'Ranger', 0, 1, 1, 932172, 9321113, 0, 0, '', 0, 0),
(932105, 10, 0, 'Reaper', 0, 1, 1, 932171, 9321112, 0, 0, '', 0, 0),
(932105, 11, 0, 'Runemaster', 0, 1, 1, 932167, 9321104, 0, 0, '', 0, 0),
(932105, 12, 0, 'Starcaller', 0, 1, 1, 932169, 9321109, 0, 0, '', 0, 0),
(932105, 13, 0, 'Stormbringer', 0, 1, 1, 932172, 9321115, 0, 0, '', 0, 0),
(932105, 14, 0, 'Sun Cleric', 0, 1, 1, 932170, 9321111, 0, 0, '', 0, 0),
(932105, 15, 0, 'Templar', 0, 1, 1, 932169, 9321108, 0, 0, '', 0, 0),
(932105, 16, 0, 'Tinker', 0, 1, 1, 932173, 9321116, 0, 0, '', 0, 0),
(932105, 17, 0, 'Witch Hunter', 0, 1, 1, 932172, 9321114, 0, 0, '', 0, 0);

-- Thunder Bluff: submenu 932106 (text copied from stock npc_text 1300), 7 class options, reached from 721/13
--     (Bluffwatcher 3084).
--   leaf 932174: Barbarian Thokor Galanthoof guid 9004682 POI 9321120, Guardian Gohok Bighoof guid 9004683 POI
--       9321121; checked at the spawn: Hunter's Hall tent, Hunter Rise (AreaTable 1641; Taurenhuntertent.wmo
--       floor)
--   leaf 932175: Primalist Ear-he Stonehoof guid 9004684 POI 9321122, Starcaller Zoona guid 9004685 POI 9321123,
--       Sun Cleric Sunwalker Modae guid 9004686 POI 9321124; checked at the spawn: Elder Rise before the Hall of
--       Elders (AreaTable 1639; stock POI 285 9-17 yd)
--   leaf 932176: Runemaster Kodor the Seer guid 9004687 POI 9321125; checked at the spawn: top of the Spirit Rise
--       (AreaTable 1640; Shamanmesa.wmo floor; stock POI 288 12.3 yd)
--   leaf 932177: Cultist Wuyi Thunderhoof guid 9004688 POI 9321126; checked at the spawn: Pools of Vision under
--       the Spirit Rise (WMO AreaTable 2197 The Pools of Vision)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321120, 9321126, 9321121, 9321122, 9321125, 9321123, 9321124);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321120, 9321126, 9321121, 9321122, 9321125, 9321123, 9321124);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321120, -1446.5, -80.5, 7, 99, 0, 'Thunder Bluff Barbarian Trainer'),
(9321126, -945.5, 255.5, 7, 99, 0, 'Thunder Bluff Cultist Trainer'),
(9321121, -1463, -97, 7, 99, 0, 'Thunder Bluff Guardian Trainer'),
(9321122, -1044, -272, 7, 99, 0, 'Thunder Bluff Primalist Trainer'),
(9321125, -993, 266.5, 7, 99, 0, 'Thunder Bluff Runemaster Trainer'),
(9321123, -1060, -278, 7, 99, 0, 'Thunder Bluff Starcaller Trainer'),
(9321124, -1060.5, -297, 7, 99, 0, 'Thunder Bluff Sun Cleric Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932106, 932174, 932175, 932176, 932177);
DELETE FROM `npc_text` WHERE `ID` IN (
    932106, 932174, 932175, 932176, 932177);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932106, 'Which trainer do you seek?', 'Which trainer do you seek?', 6769, 1, 1, 0),
(932174, 'Make your way to the Hunter''s Hall on the Hunter Rise. Thokor Galanthoof trains the Barbarians there, and Gohok Bighoof the Guardians.', 'Make your way to the Hunter''s Hall on the Hunter Rise. Thokor Galanthoof trains the Barbarians there, and Gohok Bighoof the Guardians.', 0, 0, 1, 0),
(932175, 'Seek the Elder Rise, before the Hall of Elders. Ear-he Stonehoof teaches the Primalists there, Zoona the Starcallers and Sunwalker Modae the Sun Clerics.', 'Seek the Elder Rise, before the Hall of Elders. Ear-he Stonehoof teaches the Primalists there, Zoona the Starcallers and Sunwalker Modae the Sun Clerics.', 0, 0, 1, 0),
(932176, 'Kodor the Seer stands among the totems atop the Spirit Rise, near the Hall of Spirits.', 'Kodor the Seer stands among the totems atop the Spirit Rise, near the Hall of Spirits.', 0, 0, 1, 0),
(932177, 'Wuyi Thunderhoof dwells in the Pools of Vision, in the cave beneath the Spirit Rise.', 'Wuyi Thunderhoof dwells in the Pools of Vision, in the cave beneath the Spirit Rise.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932106, 932174, 932175, 932176, 932177);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932106, 932106),
(932174, 932174),
(932175, 932175),
(932176, 932176),
(932177, 932177);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932106;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932106;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932106, 0, 0, 'Barbarian', 0, 1, 1, 932174, 9321120, 0, 0, '', 0, 0),
(932106, 1, 0, 'Cultist', 0, 1, 1, 932177, 9321126, 0, 0, '', 0, 0),
(932106, 2, 0, 'Guardian', 0, 1, 1, 932174, 9321121, 0, 0, '', 0, 0),
(932106, 3, 0, 'Primalist', 0, 1, 1, 932175, 9321122, 0, 0, '', 0, 0),
(932106, 4, 0, 'Runemaster', 0, 1, 1, 932176, 9321125, 0, 0, '', 0, 0),
(932106, 5, 0, 'Starcaller', 0, 1, 1, 932175, 9321123, 0, 0, '', 0, 0),
(932106, 6, 0, 'Sun Cleric', 0, 1, 1, 932175, 9321124, 0, 0, '', 0, 0);

-- Silvermoon City: submenu 932107 (text copied from stock npc_text 9331), 16 class options, reached from 7633/12
--     (Silvermoon City Guardian 16222).
--   leaf 932178: Felsworn Veyrin Felshroud guid 9004914 POI 9321140; checked at the spawn: The Sanctum under
--       Murder Row (stock warlock POI 367 10.0 yd)
--   leaf 932179: Stormbringer Ilythara Skyrender guid 9004916 POI 9321141; checked at the spawn: Royal Exchange
--       garden plaza (WMO area The Royal Exchange)
--   leaf 932180: Knight of Xoroth Tarenar Blackflame guid 9004917 POI 9321142; checked at the spawn: Murder Row
--       upper street (WMO area Murder Row)
--   leaf 932181: Guardian Lorthiel Brightward guid 9004918 POI 9321143; checked at the spawn: Walk of Elders
--       inside the city gate (WMO area Walk of Elders)
--   leaf 932182: Templar Kaeleth Dawnbrand guid 9004919 POI 9321144; checked at the spawn: Blood Knights' hall off
--       Farstriders' Square (stock paladin POI 364 23.2 yd)
--   leaf 932183: Bloodmage Velanna Redthorn guid 9004920 POI 9321145; checked at the spawn: magisters' square in
--       the Bazaar (WMO area The Bazaar)
--   leaf 932184: Ranger Nyssa Swiftbough guid 9004921 POI 9321146; checked at the spawn: archery range of
--       Farstriders' Square (WMO area Farstriders' Square; Silvermoon Ranger 7.4 yd)
--   leaf 932185: Chronomancer Aeduin Hourward guid 9004922 POI 9321147; checked at the spawn: crossroads of the
--       Walk of Elders (WMO area Walk of Elders)
--   leaf 932186: Necromancer Velrith Scarwatch guid 9004923 POI 9321148; checked at the spawn: sealed Dead Scar
--       gate, west end of the Bazaar (WMO area The Bazaar; gate guardians 6.9 yd)
--   leaf 932187: Pyromancer Ilsara Flamecrest guid 9004924 POI 9321149; checked at the spawn: Royal Exchange pool
--       walk (WMO area The Royal Exchange)
--   leaf 932188: Cultist Nerethil Voidwhisper guid 9004925 POI 9321150; checked at the spawn: courtyard below
--       Murder Row by the inn (WMO area Murder Row)
--   leaf 932189: Starcaller Caleste Nightglow guid 9004926 POI 9321151, Runemaster Ithrien Glyphwarden guid
--       9004932 POI 9321152; checked at the spawn: upper plaza of the Court of the Sun (WMO area Court of the Sun)
--   leaf 932190: Sun Cleric Liraen Dawnlight guid 9004927 POI 9321153; checked at the spawn: priests' room of the
--       Sunfury Spire (WMO area Sunfury Spire; stock priest POI 365 9.0 yd)
--   leaf 932191: Tinker Keldan Sparkwright guid 9004928 POI 9321154; checked at the spawn: engineering terrace
--       (stock POI 372 Engineering 5.1 yd; Danwe 13.4 yd)
--   leaf 932192: Reaper Dathren Duskmourn guid 9004930 POI 9321155; checked at the spawn: memorial stones of the
--       Walk of Elders (WMO area Walk of Elders)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321145, 9321147, 9321150, 9321140, 9321143, 9321142, 9321148, 9321149, 9321146, 9321155, 9321152, 9321151,
    9321141, 9321153, 9321144, 9321154);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321145, 9321147, 9321150, 9321140, 9321143, 9321142, 9321148, 9321149, 9321146, 9321155, 9321152, 9321151,
    9321141, 9321153, 9321144, 9321154);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321145, 9540, -7102, 7, 99, 0, 'Silvermoon City Bloodmage Trainer'),
(9321147, 9672, -7262, 7, 99, 0, 'Silvermoon City Chronomancer Trainer'),
(9321150, 9662.5, -7333, 7, 99, 0, 'Silvermoon City Cultist Trainer'),
(9321140, 9795.5, -7315, 7, 99, 0, 'Silvermoon City Felsworn Trainer'),
(9321143, 9473.5, -7285.5, 7, 99, 0, 'Silvermoon City Guardian Trainer'),
(9321142, 9769, -7288, 7, 99, 0, 'Silvermoon City Knight of Xoroth Trainer'),
(9321148, 9702, -7061.5, 7, 99, 0, 'Silvermoon City Necromancer Trainer'),
(9321149, 9762.8, -7434, 7, 99, 0, 'Silvermoon City Pyromancer Trainer'),
(9321146, 9846, -7406.5, 7, 99, 0, 'Silvermoon City Ranger Trainer'),
(9321155, 9510, -7397, 7, 99, 0, 'Silvermoon City Reaper Trainer'),
(9321152, 9950, -7215.5, 7, 99, 0, 'Silvermoon City Runemaster Trainer'),
(9321151, 9980, -7190, 7, 99, 0, 'Silvermoon City Starcaller Trainer'),
(9321141, 9685, -7463.5, 7, 99, 0, 'Silvermoon City Stormbringer Trainer'),
(9321153, 9946, -7058, 7, 99, 0, 'Silvermoon City Sun Cleric Trainer'),
(9321144, 9846, -7490, 7, 99, 0, 'Silvermoon City Templar Trainer'),
(9321154, 9832, -7324, 7, 99, 0, 'Silvermoon City Tinker Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932107, 932178, 932179, 932180, 932181, 932182, 932183, 932184, 932185, 932186, 932187, 932188, 932189,
    932190, 932191, 932192);
DELETE FROM `npc_text` WHERE `ID` IN (
    932107, 932178, 932179, 932180, 932181, 932182, 932183, 932184, 932185, 932186, 932187, 932188, 932189,
    932190, 932191, 932192);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932107, 'What path do you wish to pursue?', 'What path do you wish to pursue?', 15235, 0, 1, 0),
(932178, 'Veyrin Felshroud studies in The Sanctum beneath Murder Row, where the warlocks keep their summoning pit. He prefers the quiet of its east study.', 'Veyrin Felshroud studies in The Sanctum beneath Murder Row, where the warlocks keep their summoning pit. He prefers the quiet of its east study.', 0, 0, 1, 0),
(932179, 'Ilythara Skyrender stands in the garden plaza of the Royal Exchange, before the auction house, where she can see the sky.', 'Ilythara Skyrender stands in the garden plaza of the Royal Exchange, before the auction house, where she can see the sky.', 0, 0, 1, 0),
(932180, 'Tarenar Blackflame keeps to Murder Row, on the upper street among its shadier trades.', 'Tarenar Blackflame keeps to Murder Row, on the upper street among its shadier trades.', 0, 0, 1, 0),
(932181, 'Lorthiel Brightward stands just inside the city gate, on the Walk of Elders.', 'Lorthiel Brightward stands just inside the city gate, on the Walk of Elders.', 0, 0, 1, 0),
(932182, 'Kaeleth Dawnbrand trains the Templars in the Blood Knights'' hall in Farstriders'' Square. Be respectful while there if you value your head.', 'Kaeleth Dawnbrand trains the Templars in the Blood Knights'' hall in Farstriders'' Square. Be respectful while there if you value your head.', 0, 0, 1, 0),
(932183, 'Velanna Redthorn waits on the magisters'' square in the Bazaar.', 'Velanna Redthorn waits on the magisters'' square in the Bazaar.', 0, 0, 1, 0),
(932184, 'Nyssa Swiftbough trains at the archery range in Farstriders'' Square, with the Silvermoon rangers.', 'Nyssa Swiftbough trains at the archery range in Farstriders'' Square, with the Silvermoon rangers.', 0, 0, 1, 0),
(932185, 'Aeduin Hourward stands at the crossroads of the Walk of Elders, where the avenue meets the ways to the Bazaar and Murder Row.', 'Aeduin Hourward stands at the crossroads of the Walk of Elders, where the avenue meets the ways to the Bazaar and Murder Row.', 0, 0, 1, 0),
(932186, 'Velrith Scarwatch stands before the sealed gate of the Dead Scar, at the west end of the Bazaar.', 'Velrith Scarwatch stands before the sealed gate of the Dead Scar, at the west end of the Bazaar.', 0, 0, 1, 0),
(932187, 'Ilsara Flamecrest stands on the pool walk of the Royal Exchange, below the corner brazier.', 'Ilsara Flamecrest stands on the pool walk of the Royal Exchange, below the corner brazier.', 0, 0, 1, 0),
(932188, 'Nerethil Voidwhisper lurks in the courtyard below Murder Row, near the inn.', 'Nerethil Voidwhisper lurks in the courtyard below Murder Row, near the inn.', 0, 0, 1, 0),
(932189, 'Go up to the Court of the Sun. Caleste Nightglow teaches the Starcallers on the open upper plaza, and Ithrien Glyphwarden the Runemasters before the enchanting and inscription shop.', 'Go up to the Court of the Sun. Caleste Nightglow teaches the Starcallers on the open upper plaza, and Ithrien Glyphwarden the Runemasters before the enchanting and inscription shop.', 0, 0, 1, 0),
(932190, 'Liraen Dawnlight teaches within the Sunfury Spire, in the priests'' chamber.', 'Liraen Dawnlight teaches within the Sunfury Spire, in the priests'' chamber.', 0, 0, 1, 0),
(932191, 'Keldan Sparkwright works on the engineering terrace with Danwe, near the Court of the Sun on the path to Farstriders'' Square.', 'Keldan Sparkwright works on the engineering terrace with Danwe, near the Court of the Sun on the path to Farstriders'' Square.', 0, 0, 1, 0),
(932192, 'Dathren Duskmourn keeps vigil at the memorial stones on the Walk of Elders.', 'Dathren Duskmourn keeps vigil at the memorial stones on the Walk of Elders.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932107, 932178, 932179, 932180, 932181, 932182, 932183, 932184, 932185, 932186, 932187, 932188, 932189,
    932190, 932191, 932192);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932107, 932107),
(932178, 932178),
(932179, 932179),
(932180, 932180),
(932181, 932181),
(932182, 932182),
(932183, 932183),
(932184, 932184),
(932185, 932185),
(932186, 932186),
(932187, 932187),
(932188, 932188),
(932189, 932189),
(932190, 932190),
(932191, 932191),
(932192, 932192);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932107;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932107;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932107, 0, 0, 'Bloodmage', 0, 1, 1, 932183, 9321145, 0, 0, '', 0, 0),
(932107, 1, 0, 'Chronomancer', 0, 1, 1, 932185, 9321147, 0, 0, '', 0, 0),
(932107, 2, 0, 'Cultist', 0, 1, 1, 932188, 9321150, 0, 0, '', 0, 0),
(932107, 3, 0, 'Felsworn', 0, 1, 1, 932178, 9321140, 0, 0, '', 0, 0),
(932107, 4, 0, 'Guardian', 0, 1, 1, 932181, 9321143, 0, 0, '', 0, 0),
(932107, 5, 0, 'Knight of Xoroth', 0, 1, 1, 932180, 9321142, 0, 0, '', 0, 0),
(932107, 6, 0, 'Necromancer', 0, 1, 1, 932186, 9321148, 0, 0, '', 0, 0),
(932107, 7, 0, 'Pyromancer', 0, 1, 1, 932187, 9321149, 0, 0, '', 0, 0),
(932107, 8, 0, 'Ranger', 0, 1, 1, 932184, 9321146, 0, 0, '', 0, 0),
(932107, 9, 0, 'Reaper', 0, 1, 1, 932192, 9321155, 0, 0, '', 0, 0),
(932107, 10, 0, 'Runemaster', 0, 1, 1, 932189, 9321152, 0, 0, '', 0, 0),
(932107, 11, 0, 'Starcaller', 0, 1, 1, 932189, 9321151, 0, 0, '', 0, 0),
(932107, 12, 0, 'Stormbringer', 0, 1, 1, 932179, 9321141, 0, 0, '', 0, 0),
(932107, 13, 0, 'Sun Cleric', 0, 1, 1, 932190, 9321153, 0, 0, '', 0, 0),
(932107, 14, 0, 'Templar', 0, 1, 1, 932182, 9321144, 0, 0, '', 0, 0),
(932107, 15, 0, 'Tinker', 0, 1, 1, 932191, 9321154, 0, 0, '', 0, 0);

-- Kharanos: submenu 932108 (text copied from stock npc_text 4292), 1 class options, reached from 3533/7 (Ironforge
--     Mountaineer 727).
--   leaf 932193: Reaper Zipak Cogweight guid 9003314 POI 9321160; checked at the spawn: grave scene on the knoll
--       east of the Thunderbrew Distillery (AreaTable 131 Kharanos; lampposts, candles and dirt mound 6-13 yd; z
--       452 against the inn at 400)
DELETE FROM `points_of_interest_locale` WHERE `ID` IN (
    9321160);
DELETE FROM `points_of_interest` WHERE `ID` IN (
    9321160);
INSERT INTO `points_of_interest` (`ID`, `PositionX`, `PositionY`, `Icon`, `Flags`, `Importance`, `Name`)
VALUES
(9321160, -5597.9, -607.87, 7, 99, 0, 'Kharanos Reaper Trainer');

DELETE FROM `npc_text_locale` WHERE `ID` IN (
    932108, 932193);
DELETE FROM `npc_text` WHERE `ID` IN (
    932108, 932193);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(932108, 'Which class trainer might ye be looking for?', 'Which class trainer might ye be looking for?', 7000, 0, 1, 0),
(932193, 'Zipak Cogweight, is it? The wee gnome keeps watch over a fresh grave on the knoll east of the Thunderbrew Distillery. Look for the lampposts and candles.', 'Zipak Cogweight, is it? The wee gnome keeps watch over a fresh grave on the knoll east of the Thunderbrew Distillery. Look for the lampposts and candles.', 0, 0, 1, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (
    932108, 932193);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932108, 932108),
(932193, 932193);

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 932108;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932108;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(932108, 0, 0, 'Reaper', 0, 1, 1, 932193, 9321160, 0, 0, '', 0, 0);

-- ---------------------------------------------------------------------------
-- 2. Class Trainer options and who sees them
-- ---------------------------------------------------------------------------
-- The CoA option of each root menu, after the stock ones and their locale rows.
DELETE FROM `gossip_menu_option` WHERE (`MenuID`, `OptionID`) IN (
    (435, 16), (2121, 14), (2352, 12), (10265, 12), (7777, 11), (1951, 15), (2849, 14), (10769, 14), (721, 13),
    (7633, 12), (3533, 7));
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(435, 16, 0, 'Class Trainer', 45378, 1, 1, 932100, 0, 0, 0, '', 0, 0),
(2121, 14, 0, 'Class Trainer', 45378, 1, 1, 932101, 0, 0, 0, '', 0, 0),
(2352, 12, 0, 'Class Trainer', 45378, 1, 1, 932102, 0, 0, 0, '', 0, 0),
(10265, 12, 0, 'Class Trainer', 45378, 1, 1, 932102, 0, 0, 0, '', 0, 0),
(7777, 11, 0, 'Class Trainer', 45378, 1, 1, 932103, 0, 0, 0, '', 0, 0),
(1951, 15, 0, 'A class trainer', 6792, 1, 1, 932104, 0, 0, 0, '', 0, 0),
(2849, 14, 0, 'A class trainer', 6792, 1, 1, 932105, 0, 0, 0, '', 0, 0),
(10769, 14, 0, 'A class trainer', 6792, 1, 1, 932105, 0, 0, 0, '', 0, 0),
(721, 13, 0, 'A class trainer', 6792, 1, 1, 932106, 0, 0, 0, '', 0, 0),
(7633, 12, 0, 'Class Trainer', 45378, 1, 1, 932107, 0, 0, 0, '', 0, 0),
(3533, 7, 0, 'Class Trainer', 45378, 1, 1, 932108, 0, 0, 0, '', 0, 0);

-- Stock root options for the stock classes, CoA root options for the CoA classes.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `ConditionTypeOrReference` = 15 AND
    (`SourceGroup`, `SourceEntry`) IN (
    (435, 14), (721, 9), (1951, 12), (2121, 11), (2352, 9), (10265, 9), (2849, 12), (10769, 12), (3285, 4),
    (3331, 4), (3356, 4), (3506, 5), (3533, 5), (3580, 5), (7633, 9), (7777, 9), (8129, 5), (8185, 4), (10082, 1),
    (435, 16), (2121, 14), (2352, 12), (10265, 12), (7777, 11), (1951, 15), (2849, 14), (10769, 14), (721, 13),
    (7633, 12), (3533, 7));
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 435, 14, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Stormwind - stock class trainer directions for the stock classes'),
(15, 721, 9, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Thunder Bluff - stock class trainer directions for the stock classes'),
(15, 1951, 12, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Orgrimmar - stock class trainer directions for the stock classes'),
(15, 2121, 11, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Ironforge - stock class trainer directions for the stock classes'),
(15, 2352, 9, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Darnassus - stock class trainer directions for the stock classes'),
(15, 10265, 9, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Darnassus - stock class trainer directions for the stock classes'),
(15, 2849, 12, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Undercity - stock class trainer directions for the stock classes'),
(15, 10769, 12, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Undercity - stock class trainer directions for the stock classes'),
(15, 3285, 4, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Razor Hill - stock class trainer directions for the stock classes'),
(15, 3331, 4, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Bloodhoof Village - stock class trainer directions for the stock classes'),
(15, 3356, 4, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Brill - stock class trainer directions for the stock classes'),
(15, 3506, 5, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Goldshire - stock class trainer directions for the stock classes'),
(15, 3533, 5, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Kharanos - stock class trainer directions for the stock classes'),
(15, 3580, 5, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Dolanaar - stock class trainer directions for the stock classes'),
(15, 7633, 9, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Silvermoon City - stock class trainer directions for the stock classes'),
(15, 7777, 9, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'The Exodar - stock class trainer directions for the stock classes'),
(15, 8129, 5, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Azure Watch - stock class trainer directions for the stock classes'),
(15, 8185, 4, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Falconwing Square - stock class trainer directions for the stock classes'),
(15, 10082, 1, 0, 0, 15, 0, 1535, 0, 0, 0, 0, 0, '', 'Dalaran - stock class trainer directions for the stock classes'),
(15, 435, 16, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Stormwind - CoA class trainer directions for the CoA classes'),
(15, 2121, 14, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Ironforge - CoA class trainer directions for the CoA classes'),
(15, 2352, 12, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Darnassus - CoA class trainer directions for the CoA classes'),
(15, 10265, 12, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Darnassus - CoA class trainer directions for the CoA classes'),
(15, 7777, 11, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'The Exodar - CoA class trainer directions for the CoA classes'),
(15, 1951, 15, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Orgrimmar - CoA class trainer directions for the CoA classes'),
(15, 2849, 14, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Undercity - CoA class trainer directions for the CoA classes'),
(15, 10769, 14, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Undercity - CoA class trainer directions for the CoA classes'),
(15, 721, 13, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Thunder Bluff - CoA class trainer directions for the CoA classes'),
(15, 7633, 12, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Silvermoon City - CoA class trainer directions for the CoA classes'),
(15, 3533, 7, 0, 0, 15, 0, 4294965248, 0, 0, 0, 0, 0, '', 'Kharanos - CoA class trainer directions for the CoA classes');
