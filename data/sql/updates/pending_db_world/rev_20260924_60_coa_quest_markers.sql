-- Conquest of Azeroth: quest map markers follow the NPCs and objects CoA moved.
--
-- Markers move only where a CoA source places the quest target with confidence.
--
-- WHERE EACH VALUE COMES FROM
--   what the player sees  SOURCED-CORE + SOURCED-CLIENT: the world-map and tracker markers are the server
--     quest_poi / quest_poi_points rows (ObjectMgr.cpp:8492-8575 loads them; QueryHandler.cpp:411-477 sends them
--     for quests in the log; points are world X/Y; ObjectiveIndex -1 is the turn-in, 0-3 a creature/object
--     objective, 4 + slot an item objective). The CoA UI (patch-B.MPQ WorldMapFrame.lua 1865-2085) draws them with
--     the stock API. The in-world arrow and minimap pin come from CoA's QuestSuperTrack.dbc on the client and are
--     not affected by this file.
--   research  research/trainers-guards-markers/quest-markers.md (+ .json), re-checked on coa_poi.
--   turn-in moves (50 markers of 24 enders)  SOURCED-CLIENT: each new point is the quest's QuestSuperTrack turn-in
--     point (tools/supertrack.py), and the ender's spawn after every other pending file stands within 1 yd of it;
--     the old marker lies 3-130 yd away at the stock spot, where the ender stood before a sourced move onto that
--     point (files 20260923_02, 20260923_03, 20260924_11, 20260925_11, 20260925_12); Sten Stoutarm did not move,
--     his 179 marker was 22 yd off in stock data. Every moved marker has a single point; the row keeps its map and
--     WorldMapAreaId (same zone map).
--   objective moves (2)  SOURCED-CLIENT: QuestSuperTrack objective point; DERIVED: the only source of the item (a
--     chest or a vendor) moved with a verified building transform.
--   turn-in adds (155 quests)  SOURCED-CLIENT: CoA quests with no quest_poi row at all get one turn-in marker at
--     the QuestSuperTrack turn-in point, where their ender's spawn stands (0.0-1.6 yd). The new row is
--     (ObjectiveIndex -1, Floor 0, Priority 0, Flags 1), the most common stock turn-in pattern; poi id 0 because
--     the quest has no other POI.
--   WorldMapAreaId  INFERRED: the stock convention of the area (the parent zone map), like the 301 existing rows
--     in CoA's starting zones. CoA also has its own starting-zone maps (WorldMapArea 1237-1244); whether the
--     client shows parent-zone markers on them is open (research Q1).
--   turn-ins at the ender (10 quests)  DERIVED: quests with no QuestSuperTrack turn-in whose ender is far from the
--     giver, hand-placed or out of sight: the same row pattern at the ender's spawn (within 1 yd). 254108's
--     objective: its QuestSuperTrack point carried through the inn transform (DERIVED, D6), poi id 0 with the
--     turn-in as poi id 1 (the stock order).
--   quest_template POIx/POIy  SOURCED-CORE: only copied into the quest query (QuestDef.cpp:486-489) and read by no
--     CoA interface file. Of the quests here only 135 has a value (-8752, 384), which is not the old marker point,
--     so none is stale and none is changed.
--
-- LEFT AS THEY ARE (not confident; research report sections C and D)
--   - Stormwind enders the stormwind scope moved while their QuestSuperTrack turn-in stayed at the stock spot (the
--     CoA arrow and the map would disagree): Milton Sheaf 1440 (337, 343, 542) and Donyal Tovald 2504 (579),
--     DERIVED Royal Library translation; Alliance Brigadier General 15351 (24427), DERIVED war room translation;
--     King Varian Wrynn 29611 (396, 6186, 6187, 7781, 12774, 13347, 13370, 13377, 24597), INFERRED throne spot;
--     INFERRED moves of Wilder Thistlenettle 656 (167, 168), Brohann Caskbelly 5384 (1448, 1469, 1475), Lord
--     Baurles K. Wishock 1439 (336), Count Remington Ridgewell 2285 (543, 4765), Major Samuelson 2439 (563),
--     Bishop DeLavey 4960 (1274) and Tyrion 7766 (2745, 2746).
--   - Goldshire candy bucket 189303 (12286): DERIVED inn transform, but its QuestSuperTrack 1163 is still the
--     stock spot.
--   - Dolanaar Noblegarden (13480, 13484, 13502): QuestSuperTrack 8906/8907 are CoA points, but Spring Collector
--     32799 and Noblegarden Merchant 32836 were not moved there (75-105 yd); a placement gap for the Teldrassil
--     scope.
--   - 1660036 Oracular Idol (QuestSuperTrack 8696 is 26.6 yd from Moroi; the text says "someone at the Abbey"),
--     17001 Extravagant Order (its turn-in point is Remy's spot, D23), 254108 Final Dig (stale objective point,
--     D23), 487 The Road to Darnassus (Amara patrols; the marker is on her path), 3861 CLUCK! (generic chicken
--     ender), 13369 and Pilgrim's Bounty 14024/14030/14035 (CoA did not move their enders, so their marker offsets
--     are stock data).
--   - Objective markers whose QuestSuperTrack point has no source spawn near it or would only add a second blob
--     (167, 168, 176, 387, 434, 489, 543, 932, 2746, 17001, 254108).
--   - CoA quests with no sourced turn-in point and a nearby ender (the capital class-trainer quests, the Ammen
--     Vale and other Sunstrider Isle letters; Kuroth in the Sacred Grove stays unmarked on purpose), and 45
--     sourced objective markers for CoA quests that have none (research table B2): this file adds turn-in markers
--     only.
--
-- Counts: 50 turn-in markers and 2 objective markers moved; 166 quest_poi rows and as many quest_poi_points rows added.
-- Exact-key updates and deletes only; re-applying the file is a no-op. It runs after every other pending file.

-- ---------------------------------------------------------------------------
-- 1. Turn-in markers of moved quest enders
-- ---------------------------------------------------------------------------
-- Marshal McBride 197 (guid 79970): -8903, -163 -> -8909, -131 = QuestSuperTrack 421. 7 Kobold Camp Cleanup, 15
--     Investigate Echo Ridge, 21 Skirmish at Echo Ridge, 783 A Threat Within.
UPDATE `quest_poi_points` SET `X` = -8909, `Y` = -131 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (7, 1, 0), (15, 1, 0), (21, 1, 0), (783, 0, 0));

-- Brother Neals 952 (guid 79968): -8902, -182 -> -8893, -173 = QuestSuperTrack 1078. 3905 Grape Manifest.
UPDATE `quest_poi_points` SET `X` = -8893, `Y` = -173 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (3905, 0, 0));

-- Marshal Dughan 240 (guid 80334): -9466, 74 -> -9462, 44 = QuestSuperTrack 409. 39 Deliver Thomas' Report, 40 A
--     Fishy Peril, 54 Report to Goldshire, 62 The Fargodeep Mine, 76 The Jasperlode Mine, 123 The Collector, 147
--     Manhunt, 176 Wanted: "Hogger".
UPDATE `quest_poi_points` SET `X` = -9462, `Y` = 44 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (39, 0, 0), (40, 0, 0), (54, 0, 0), (62, 1, 0), (76, 1, 0), (123, 0, 0), (147, 1, 0), (176, 1, 0));

-- William Pestle 253 (guid 80350): -9460, 32 -> -9480, -2 = QuestSuperTrack 1079. 60 Kobold Candles, 107 Note to
--     William, 112 Collecting Kelp.
UPDATE `quest_poi_points` SET `X` = -9480, `Y` = -2 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (60, 2, 0), (107, 0, 0), (112, 1, 0));

-- Innkeeper Farley 295 (guid 80346): -9463, 16 -> -9481, -18 = QuestSuperTrack 600. 69 The Legend of Stalvan, 2158
--     Rest and Relaxation.
UPDATE `quest_poi_points` SET `X` = -9481, `Y` = -18 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (69, 0, 0), (2158, 0, 0));

-- Master Mathias Shaw 332 (guid 79785): -8815, 362 -> -8732, 310 = QuestSuperTrack 361. 135 The Defias
--     Brotherhood, 393 Shadow of the Past, 394 The Head of the Beast, 6182 The First and the Last, 6183 Honor the
--     Dead.
UPDATE `quest_poi_points` SET `X` = -8732, `Y` = 310 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (135, 0, 0), (393, 0, 0), (394, 0, 0), (6182, 0, 0), (6183, 0, 0));

-- Warden Thelwater 1719 (guid 89325): -8792, 817 -> -8767, 844 = QuestSuperTrack 529. 387 Quell The Uprising, 389
--     Bazil Thredd, 391 The Stockade Riots.
UPDATE `quest_poi_points` SET `X` = -8767, `Y` = 844 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (387, 1, 0), (389, 0, 0), (391, 0, 0));

-- Argent Emissary 16285 (guid 12864): -8831, 641 -> -8832, 638 = QuestSuperTrack 811. 12616 Chamber of Secrets.
UPDATE `quest_poi_points` SET `X` = -8832, `Y` = 638 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (12616, 0, 0));

-- Gregory Tabor 34675 (guid 240460): -9130, 352 -> -9125, 353 = QuestSuperTrack 589. 14022 Pilgrim's Bounty, 14033
--     Candied Sweet Potatoes.
UPDATE `quest_poi_points` SET `X` = -9125, `Y` = 353 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (14022, 0, 0), (14033, 0, 0));

-- Ellen Moore 34710 (guid 240456): -9111, 365 -> -9118, 359 = QuestSuperTrack 3268. 14053 We're Out of Cranberry
--     Chutney Again?.
UPDATE `quest_poi_points` SET `X` = -9118, `Y` = 359 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (14053, 0, 0));

-- Jasper Moore 34744 (guid 240458): -9115, 359 -> -9128, 351 = QuestSuperTrack 3261. 14023 Spice Bread Stuffing,
--     14028 Cranberry Chutney, 14055 She Says Potato.
UPDATE `quest_poi_points` SET `X` = -9128, `Y` = 351 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (14023, 0, 0), (14028, 0, 0), (14055, 0, 0));

-- Athridas Bearmantle 2078 (guid 46204): 9888, 966 -> 9928, 892 = QuestSuperTrack 1147. 476 Gnarlpine Corruption,
--     483 The Relics of Wakening, 486 Ursal the Mauler.
UPDATE `quest_poi_points` SET `X` = 9928, `Y` = 892 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (476, 0, 0), (483, 4, 0), (486, 1, 0));

-- Tallonkai Swiftroot 3567 (guid 49559): 9899, 985 -> 9950, 894 = QuestSuperTrack 1074. 932 Twisted Hatred, 2438
--     The Emerald Dreamcatcher, 2459 Ferocitas the Dream Eater.
UPDATE `quest_poi_points` SET `X` = 9950, `Y` = 894 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (932, 1, 0), (2438, 1, 0), (2459, 2, 0));

-- Syral Bladeleaf 2083 (guid 46211): 9872, 959 -> 9904, 902 = QuestSuperTrack 1467. 1581 Elixirs for the
--     Bladeleafs.
UPDATE `quest_poi_points` SET `X` = 9904, `Y` = 902 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (1581, 0, 0));

-- Innkeeper Keldamyr 6736 (guid 46343): 9802, 983 -> 9794, 898 = QuestSuperTrack 1475. 2159 Dolanaar Delivery.
UPDATE `quest_poi_points` SET `X` = 9794, `Y` = 898 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (2159, 0, 0));

-- Zarrin 6286 (guid 46718): 9751, 906 -> 9880, 909 = QuestSuperTrack 1600. 4161 Recipe of the Kaldorei.
UPDATE `quest_poi_points` SET `X` = 9880, `Y` = 909 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (4161, 7, 0));

-- Merissa Stilwell 11940 (guid 79949): -9479, 53 -> -9496, 15 = QuestSuperTrack 1714. 5805 Welcome!.
UPDATE `quest_poi_points` SET `X` = -9496, `Y` = 15 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (5805, 0, 0));

-- Orenthil Whisperwind 11942 (guid 46827): 9840, 946 -> 9843, 895 = QuestSuperTrack 1716. 5842 Welcome!.
UPDATE `quest_poi_points` SET `X` = 9843, `Y` = 895 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (5842, 0, 0));

-- Morja 14871 (guid 56324): -9566, 31 -> -9594, 48 = QuestSuperTrack 8902. 7946 Spawn of Jubjub.
UPDATE `quest_poi_points` SET `X` = -9594, `Y` = 48 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (7946, 0, 0));

-- Elder Stormbrow 15565 (guid 70557): -9413, 154 -> -9391, 142 = QuestSuperTrack 723. 8649 Stormbrow the Elder.
UPDATE `quest_poi_points` SET `X` = -9391, `Y` = 142 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (8649, 0, 0));

-- Elwynn Forest Flame Warden 25898 (guid 245655): -9389, 27 -> -9449, 52 = QuestSuperTrack 386. 11816 Honor the
--     Flame.
UPDATE `quest_poi_points` SET `X` = -9449, `Y` = 52 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (11816, 0, 0));

-- Yori Crackhelm 11941 (guid 348): -5581, -541 -> -5593, -530 = QuestSuperTrack 3811. 5841 Welcome!.
UPDATE `quest_poi_points` SET `X` = -5593, `Y` = -530 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (5841, 0, 0));

-- Mountaineer Thalos 1965 (guid 331): -6236, 153 -> -6240, 137 = QuestSuperTrack 2264. 282 Senir's Observations.
UPDATE `quest_poi_points` SET `X` = -6240, `Y` = 137 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (282, 0, 0));

-- Sten Stoutarm 658 (guid 351): -6215, 328 -> -6237, 331 = QuestSuperTrack 46. 179 Dwarven Outfitters.
UPDATE `quest_poi_points` SET `X` = -6237, `Y` = 331 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (179, 1, 0));

-- ---------------------------------------------------------------------------
-- 2. Objective markers of moved objects
-- ---------------------------------------------------------------------------
-- 70 The Legend of Stalvan, ObjectiveIndex 4 (item 910): -9463, -2 -> -9479, -38 = QuestSuperTrack 3900; the item
--     lies in Farley's inn chest (gameobject 1560, guid 26242), which moved with the Lion's Pride Inn rigid
--     transform (DISCOVERIES D6).
UPDATE `quest_poi_points` SET `X` = -9479, `Y` = -38 WHERE `QuestID` = 70 AND `Idx1` = 0 AND `Idx2` = 0;

-- 116 Dry Times, ObjectiveIndex 7 (item 1939 Skin of Sweet Rum): -9460, 8 -> -9478, -26 = QuestSuperTrack 4766;
--     the only source of the item is the vendor Barkeep Dobbins (creature 465, guid 79647, the one npc_vendor
--     row), who moved with the Lion's Pride Inn rigid transform (DISCOVERIES D6).
UPDATE `quest_poi_points` SET `X` = -9478, `Y` = -26 WHERE `QuestID` = 116 AND `Idx1` = 2 AND `Idx2` = 0;

-- ---------------------------------------------------------------------------
-- 3. Turn-in markers for CoA quests that have none
-- ---------------------------------------------------------------------------
-- Durotar (WorldMapAreaId 4):
--   52000 Warrior's Fury: Mu'kaka 502953, QuestSuperTrack 9022
--   52001 Crimson Arts: Fleshweaver Chella 502921, QuestSuperTrack 9031
--   52002 Whispers of the Void: Rug'ra Witherhand 502832, QuestSuperTrack 9029
--   52003 Fel Binding: Grillok Morzog 502760, QuestSuperTrack 9033
--   52004 Shield of Honor: Den Sergeant Gormuk 502791, QuestSuperTrack 9034
--   52005 Dark Oath: Spi'ro 50278, QuestSuperTrack 9028
--   52006 Communion of Souls: Kragar the Reanimator 502925, QuestSuperTrack 9023
--   52007 Elemental Fury: Krull Rocksmash 50290, QuestSuperTrack 9021
--   52008 Path of Flames: Grishnakh Searscar 503402, QuestSuperTrack 9030
--   52009 Call of the Wild: Wolfrider Yara 502810, QuestSuperTrack 9032
--   52010 Ancient Glyphs: Zina Glyphreader 502912, QuestSuperTrack 9027
--   52011 Thunder's Voice: Zim'chein 50277, QuestSuperTrack 9025
--   52012 Solar Blessing: Pangajo Sunseer 9300201, QuestSuperTrack 9026
--   52013 Sacred Oaths: Omogulg the Truthbearer 9300200, QuestSuperTrack 9020
--   52014 Mechanical Innovation: Mekboy Parod 502872, QuestSuperTrack 9024
--   52015 Toxic Arts: Qwi'spe the Wise 50288, QuestSuperTrack 9036
--   52016 Ancestral Wisdom: Rol'joku 50296, QuestSuperTrack 9035
--   200107 Welcome to the Warband: Mu'kaka 502953, QuestSuperTrack 8524
-- Mulgore (WorldMapAreaId 9):
--   55101 Void Manuscript: Ultha Dreamharrow 502834, QuestSuperTrack 9056
--   55102 Celestial Chart: Oko'une, Chosen of Lo'sho 50285, QuestSuperTrack 9061
--   55103 Sun Prayer: Sunwalker Thunderhorn 100242, QuestSuperTrack 9062
--   55104 Tauren Rune Stone: Go'hro 512912, QuestSuperTrack 9057
--   55105 Elemental Totem: Amuwate Eagledream 502900, QuestSuperTrack 9063
--   55106 Earth Shield Tablet: Motah Stonebreaker 502790, QuestSuperTrack 9059
--   55107 Thunder Call: Tooantuh Cloudtail 502774, QuestSuperTrack 9058
--   55108 Ancestral War Tablet: Galak Twoclubs 502950, QuestSuperTrack 9060
-- Tirisfal Glades (WorldMapAreaId 20):
--   53000 Fury Tablet: Undertaker Chite 502891, QuestSuperTrack 9014
--   53001 Crimson Scroll: Irina Valreed 502922, QuestSuperTrack 9007
--   53002 Void Manuscript: Thaddeus Voidseeker 502833, QuestSuperTrack 9010
--   53003 Fel Contract: Dar'danis 50276, QuestSuperTrack 9003
--   53004 Guardian Oath: Deathguard Bradforth 50279, QuestSuperTrack 9017
--   53005 Shadow Decree: Brallmular 9300250, QuestSuperTrack 9016
--   53006 Death Codex: Dornall Plagueweaver 502930, QuestSuperTrack 9018
--   53007 Temporal Scroll: Quardormi 502822, QuestSuperTrack 9012
--   53008 Seared Tome: Cadmus Emberblaze 50293, QuestSuperTrack 9011
--   53009 Hunter's Guide: Gustaf Blightflight 50281, QuestSuperTrack 9019
--   53010 Runic Tablet: Wilhelm Balthier 502913, QuestSuperTrack 9005
--   53011 Storm Manuscript: Dabbert Staze 502773, QuestSuperTrack 9009
--   53012 Solar Scripture: Sunspeaker Talethia 50327, QuestSuperTrack 9002
--   53013 Sacred Vow: Vaelion Grandbell 502803, QuestSuperTrack 9013
--   53014 Mechanical Schematic: Riley Jett 502873, QuestSuperTrack 9004
--   53015 Venom Formula: Apothecary Kelan 650688, QuestSuperTrack 9015
--   53017 Inquisitor's Letter: Bailey Horrorhate 50275, QuestSuperTrack 9006
--   53201 Stellar Chart: Landralanis 502850, QuestSuperTrack 9008
-- Dun Morogh (WorldMapAreaId 27):
--   51000 Storm Codex: Freja Stormbelch 502771, QuestSuperTrack 8996
--   51001 Guardian's Oath: Kharzon the Hammer 503241, QuestSuperTrack 8994
--   51002 Templar's Vow: Thiduis Pride 502800, QuestSuperTrack 8997
--   51003 Ranger's Guide: Baruhr Mightmane 503411, QuestSuperTrack 8989
--   51004 Temporal Manuscript: Bieko 502820, QuestSuperTrack 9000
--   51005 Necromantic Journal: Ophana Gloom 502924, QuestSuperTrack 8990
--   51006 Flame Codex: Debbie Whirlyflame 503400, QuestSuperTrack 8995
--   51007 Forbidden Treatise: Clippo Doomwhistle 502830, QuestSuperTrack 8987
--   51008 Solar Scripture: Cleric Stonelight 503271, QuestSuperTrack 8999
--   51009 Engineering Manual: Binkle Coldbolt 502870, QuestSuperTrack 8992
--   51010 Runic Inscription: Murmon Fuseforge 502910, QuestSuperTrack 8993
--   51011 Ancient Tablet: Grelin Ironbeard 502952, QuestSuperTrack 8998
--   51012 Hunter's Mandate: Yiro the Vanquisher 9300150, QuestSuperTrack 8991
--   51013 Primal Codex: Katho Hammerfist 50342, QuestSuperTrack 8988
--   51014 Death Manual: Zipak Cogweight 9300151, QuestSuperTrack 9001
--   254000 A Small Mistake: Efry Cogspark 254000, QuestSuperTrack 51
--   254001 We Found Her!: Efry Cogspark 254000, QuestSuperTrack 50
--   254002 The Scout's Favor: Mountaineer Tagnur 254002, QuestSuperTrack 53
--   254003 Old Mirsinth: Mirsinth the Exile 254003, QuestSuperTrack 314
--   254004 A Brother's Betrayal: Mirsinth the Exile 254003, QuestSuperTrack 98
--   500005 Timber for the Coldhewn: Brunna Ironhew 765556, QuestSuperTrack 32495
--   500006 Icehide the Unbroken: Old Kargan Stouthew 764536, QuestSuperTrack 32494
--   1660006 Smoke on the Wind: Dead Crewman 161719, QuestSuperTrack 32525
--   1660007 A Promising Path: Arathror 161720, QuestSuperTrack 32526
--   1660008 A Fitting Disguise: Arathror 161720, QuestSuperTrack 32527
--   1660009 His Radiant Majesty: Groldha 161718, QuestSuperTrack 32528
--   1660010 Deciphering Radiation: Redna 161820, QuestSuperTrack 32550
--   1660011 Soaking the Masses: Lahud 161839, QuestSuperTrack 32551
--   1660039 Sever the Right Hand: Redna 161820, QuestSuperTrack 32560
--   1660076 A Growing Business: Eyma Thunderbrew 162883, QuestSuperTrack 32576
--   1660077 Thunderbrew's Hop: Eyma Thunderbrew 162883, QuestSuperTrack 32577
--   1660078 Bots on Strike: Ikoras 162884, QuestSuperTrack 32578
--   1660079 Live-Fire Demo: Gornarn 162891, QuestSuperTrack 32579
-- Elwynn Forest (WorldMapAreaId 30):
--   17000 Stolen Supplies: Pa Maclure 250, QuestSuperTrack 3303
--   17002 The Master's Orders: Esyra 900017, QuestSuperTrack 3304
--   17003 Slimy Solution: Esyra 900017, QuestSuperTrack 3304
--   17004 Disarming the Gnolls: Guard Thomas 261, QuestSuperTrack 308
--   17005 Last Memento: Imelda 11916, QuestSuperTrack 3305
--   17006 King's Justice: Guard Jacob 157000, QuestSuperTrack 3306
--   17008 Reclaim the Harvest: Sergeant De Vries 955, QuestSuperTrack 3307
--   49976 Storm Codex: Niki Thesla 502770, QuestSuperTrack 8982
--   49977 Guardian's Oath: Vanguard Gus 50324, QuestSuperTrack 8980
--   49978 Templar's Vow: Brother William 50280, QuestSuperTrack 8979
--   49979 Blood Grimoire: Whisp the Silent 50292, QuestSuperTrack 8973
--   49980 Ranger's Guide: Owen of Moonbrook 503410, QuestSuperTrack 8984
--   49981 Temporal Manuscript: Soridormi 50282, QuestSuperTrack 8986
--   49982 Necromantic Journal: Halbert the Scoundrel 502923, QuestSuperTrack 8975
--   49983 Flame Codex: Koby the Incinerator 50340, QuestSuperTrack 8971
--   49984 Forbidden Treatise: Patal the Mad 50283, QuestSuperTrack 8976
--   49985 Engineering Manual: Norman Goldshire 50287, QuestSuperTrack 8981
--   49986 Solar Scripture: Chaplain Nysoni 50286, QuestSuperTrack 8985
--   49987 Death Manual: Troes the Remover 50289, QuestSuperTrack 8974
--   49988 Runic Inscription: Wanda Belezin 50291, QuestSuperTrack 8978
--   49990 Ancient Tablet: Amanda the Reaver 50295, QuestSuperTrack 8977
--   49991 Tribal Scroll: Doctor Yara 502960, QuestSuperTrack 8983
--   49992 Sacred Letter: Deacon Frost 50325, QuestSuperTrack 8972
--   100071 Defias Disruption: Melika Isenstrider 6778, QuestSuperTrack 1139
--   100073 Supply Run: Remy "Two Times" 241, QuestSuperTrack 8548
--   100074 A Betrayal Within: Marshal Dughan 240, QuestSuperTrack 8549
--   254038 Start Digging: Agent Serina Vale 996115, QuestSuperTrack 8463
--   254095 Arcane Insight: Theocritus 313, QuestSuperTrack 8489
--   254098 Mixed Reagents: Dawn Brightstar 958, QuestSuperTrack 8501
--   254099 Test the Mix: Theocritus 313, QuestSuperTrack 8502
--   254106 Enchant the Mineral: Kitta Firewind 11072, QuestSuperTrack 8506
--   254107 Unexpected Results: Agent Serina Vale 996114, QuestSuperTrack 8513
--   1660000 Bookworm: Moroi Spada 161701, QuestSuperTrack 8641
--   1660001 Knowledge Corrupts: Moroi Spada 161701, QuestSuperTrack 8641
--   1660002 The Ruins of Northshire: Sister Alma 161702, QuestSuperTrack 8648
--   1660003 Accursed Sisterhood: Sister Alma 161702, QuestSuperTrack 8648
--   1660004 Words that Shepherd Madness: Moroi Spada 161701, QuestSuperTrack 8641
--   1660005 The Threat Swept Downstream: Injured Northshire Guard 161705, QuestSuperTrack 8694
--   1660038 The Saddest Among Us: Sister Alma 161702, QuestSuperTrack 8648
--   1660055 The Maid I Left Behind: Dulcinea 162800, QuestSuperTrack 8725
--   1660056 Agria's Medicine: Aldia Crayon 162802, QuestSuperTrack 8726
--   1660057 Seven Years of Bad Luck: Aldia Crayon 162802, QuestSuperTrack 8726
--   1660058 Worm-Eaten Apple: Clara the Mad 162805, QuestSuperTrack 8841
--   1660059 Goldshire's Generosity: Eldor Hammer 162801, QuestSuperTrack 8730
--   1660060 Stay a While: Aliscar Lend 162806, QuestSuperTrack 8842
-- Loch Modan (WorldMapAreaId 35):
--   254051 Save The Crocs: Sinter Wive 764542, QuestSuperTrack 8586
-- Redridge Mountains (WorldMapAreaId 36):
--   17007 Delivery to Lakeshire: Magistrate Solomon 344, QuestSuperTrack 1200
-- Teldrassil (WorldMapAreaId 41):
--   650141 Warrior's Letter: Amanda the Reaver 50295, QuestSuperTrack 9042
--   650142 Blood Mage Letter: Aramadus 502920, QuestSuperTrack 9053
--   650143 Temporal Letter: Kaleidormu 502821, QuestSuperTrack 9047
--   650144 Whispered Tome: Saelina Shedana 502831, QuestSuperTrack 9054
--   650145 Demonic Pact: Flowzie the Fel-Touched 50344, QuestSuperTrack 9037
--   650146 Sacred Warding: Nerdris Darkstrike 503240, QuestSuperTrack 9041
--   650147 Dark Chivalry: Aheravara 502780, QuestSuperTrack 9038
--   650148 Deathbound Codex: Baarelam of the Auchenai 50294, QuestSuperTrack 9039
--   650149 Elemental Calling: Prim'ula 503420, QuestSuperTrack 9051
--   650150 Warden's Call: Hydriel Featherflight 50341, QuestSuperTrack 9043
--   650151 Soul Harvest: Canni the Shade 502890, QuestSuperTrack 9046
--   650152 Inscribed Tablet: Raethere Daltrall 502911, QuestSuperTrack 9049
--   650153 Celestial Guidance: Huntress Naalia 50326, QuestSuperTrack 9055
--   650154 Thunder's Call: Q'ru 502772, QuestSuperTrack 9044
--   650155 Solar Benediction: Exodite Telusaara 9300350, QuestSuperTrack 9048
--   650156 Sacred Vow: Elleora 502801, QuestSuperTrack 9050
--   650157 Mechanical Schematics: Joro Rapidspyre 502871, QuestSuperTrack 9052
--   650158 Toxic Formulae: Ko'rahl Fangshifter 50343, QuestSuperTrack 9040
--   650159 Inquisitor's Mandate: Darkslayer Harrendor 503250, QuestSuperTrack 9045
--   1660012 The Carrion Road: Aryandel 161726, QuestSuperTrack 8667
--   1660013 The Sister Who Never Returned: Lady Aegya 161727, QuestSuperTrack 8668
--   1660014 Finding the Good Meat: Lady Aegya 161727, QuestSuperTrack 8668
--   1660015 Transsubstantiating the Flesh: Gilgaen 161728, QuestSuperTrack 8670
--   1660016 Communion Banquet: Lady Aegya 161727, QuestSuperTrack 8668
--   1660017 A Trail of Petals: Eldya 161848, QuestSuperTrack 8693
--   1660040 Restless Entrails: Sheelem 161916, QuestSuperTrack 8716
--   1660071 A Dark Warning: Tallonkai Swiftroot 3567, QuestSuperTrack 8782
--   1660072 The Aid of Theren-Dion: Adrilia Soultemper 162880, QuestSuperTrack 8783
--   1660073 No Place for Scavengers: Adrilia Soultemper 162880, QuestSuperTrack 8783
--   1660074 Termites in Teldrassil: Kaladir 162879, QuestSuperTrack 8785
--   1660085 Elydna's Heirloom: Thariel Wingstroke 161725, QuestSuperTrack 8840
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (17000, 0), (17002, 0), (17003, 0), (17004, 0), (17005, 0), (17006, 0), (17007, 0), (17008, 0), (49976, 0),
    (49977, 0), (49978, 0), (49979, 0), (49980, 0), (49981, 0), (49982, 0), (49983, 0), (49984, 0), (49985, 0),
    (49986, 0), (49987, 0), (49988, 0), (49990, 0), (49991, 0), (49992, 0), (51000, 0), (51001, 0), (51002, 0),
    (51003, 0), (51004, 0), (51005, 0), (51006, 0), (51007, 0), (51008, 0), (51009, 0), (51010, 0), (51011, 0),
    (51012, 0), (51013, 0), (51014, 0), (52000, 0), (52001, 0), (52002, 0), (52003, 0), (52004, 0), (52005, 0),
    (52006, 0), (52007, 0), (52008, 0), (52009, 0), (52010, 0), (52011, 0), (52012, 0), (52013, 0), (52014, 0),
    (52015, 0), (52016, 0), (53000, 0), (53001, 0), (53002, 0), (53003, 0), (53004, 0), (53005, 0), (53006, 0),
    (53007, 0), (53008, 0), (53009, 0), (53010, 0), (53011, 0), (53012, 0), (53013, 0), (53014, 0), (53015, 0),
    (53017, 0), (53201, 0), (55101, 0), (55102, 0), (55103, 0), (55104, 0), (55105, 0), (55106, 0), (55107, 0),
    (55108, 0), (100071, 0), (100073, 0), (100074, 0), (200107, 0), (254000, 0), (254001, 0), (254002, 0),
    (254003, 0), (254004, 0), (254038, 0), (254051, 0), (254095, 0), (254098, 0), (254099, 0), (254106, 0),
    (254107, 0), (500005, 0), (500006, 0), (650141, 0), (650142, 0), (650143, 0), (650144, 0), (650145, 0),
    (650146, 0), (650147, 0), (650148, 0), (650149, 0), (650150, 0), (650151, 0), (650152, 0), (650153, 0),
    (650154, 0), (650155, 0), (650156, 0), (650157, 0), (650158, 0), (650159, 0), (1660000, 0), (1660001, 0),
    (1660002, 0), (1660003, 0), (1660004, 0), (1660005, 0), (1660006, 0), (1660007, 0), (1660008, 0), (1660009,
    0), (1660010, 0), (1660011, 0), (1660012, 0), (1660013, 0), (1660014, 0), (1660015, 0), (1660016, 0),
    (1660017, 0), (1660038, 0), (1660039, 0), (1660040, 0), (1660055, 0), (1660056, 0), (1660057, 0), (1660058,
    0), (1660059, 0), (1660060, 0), (1660071, 0), (1660072, 0), (1660073, 0), (1660074, 0), (1660076, 0),
    (1660077, 0), (1660078, 0), (1660079, 0), (1660085, 0));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(17000, 0, -1, 0, 30, 0, 0, 1),
(17002, 0, -1, 0, 30, 0, 0, 1),
(17003, 0, -1, 0, 30, 0, 0, 1),
(17004, 0, -1, 0, 30, 0, 0, 1),
(17005, 0, -1, 0, 30, 0, 0, 1),
(17006, 0, -1, 0, 30, 0, 0, 1),
(17007, 0, -1, 0, 36, 0, 0, 1),
(17008, 0, -1, 0, 30, 0, 0, 1),
(49976, 0, -1, 0, 30, 0, 0, 1),
(49977, 0, -1, 0, 30, 0, 0, 1),
(49978, 0, -1, 0, 30, 0, 0, 1),
(49979, 0, -1, 0, 30, 0, 0, 1),
(49980, 0, -1, 0, 30, 0, 0, 1),
(49981, 0, -1, 0, 30, 0, 0, 1),
(49982, 0, -1, 0, 30, 0, 0, 1),
(49983, 0, -1, 0, 30, 0, 0, 1),
(49984, 0, -1, 0, 30, 0, 0, 1),
(49985, 0, -1, 0, 30, 0, 0, 1),
(49986, 0, -1, 0, 30, 0, 0, 1),
(49987, 0, -1, 0, 30, 0, 0, 1),
(49988, 0, -1, 0, 30, 0, 0, 1),
(49990, 0, -1, 0, 30, 0, 0, 1),
(49991, 0, -1, 0, 30, 0, 0, 1),
(49992, 0, -1, 0, 30, 0, 0, 1),
(51000, 0, -1, 0, 27, 0, 0, 1),
(51001, 0, -1, 0, 27, 0, 0, 1),
(51002, 0, -1, 0, 27, 0, 0, 1),
(51003, 0, -1, 0, 27, 0, 0, 1),
(51004, 0, -1, 0, 27, 0, 0, 1),
(51005, 0, -1, 0, 27, 0, 0, 1),
(51006, 0, -1, 0, 27, 0, 0, 1),
(51007, 0, -1, 0, 27, 0, 0, 1),
(51008, 0, -1, 0, 27, 0, 0, 1),
(51009, 0, -1, 0, 27, 0, 0, 1),
(51010, 0, -1, 0, 27, 0, 0, 1),
(51011, 0, -1, 0, 27, 0, 0, 1),
(51012, 0, -1, 0, 27, 0, 0, 1),
(51013, 0, -1, 0, 27, 0, 0, 1),
(51014, 0, -1, 0, 27, 0, 0, 1),
(52000, 0, -1, 1, 4, 0, 0, 1),
(52001, 0, -1, 1, 4, 0, 0, 1),
(52002, 0, -1, 1, 4, 0, 0, 1),
(52003, 0, -1, 1, 4, 0, 0, 1),
(52004, 0, -1, 1, 4, 0, 0, 1),
(52005, 0, -1, 1, 4, 0, 0, 1),
(52006, 0, -1, 1, 4, 0, 0, 1),
(52007, 0, -1, 1, 4, 0, 0, 1),
(52008, 0, -1, 1, 4, 0, 0, 1),
(52009, 0, -1, 1, 4, 0, 0, 1),
(52010, 0, -1, 1, 4, 0, 0, 1),
(52011, 0, -1, 1, 4, 0, 0, 1),
(52012, 0, -1, 1, 4, 0, 0, 1),
(52013, 0, -1, 1, 4, 0, 0, 1),
(52014, 0, -1, 1, 4, 0, 0, 1),
(52015, 0, -1, 1, 4, 0, 0, 1),
(52016, 0, -1, 1, 4, 0, 0, 1),
(53000, 0, -1, 0, 20, 0, 0, 1),
(53001, 0, -1, 0, 20, 0, 0, 1),
(53002, 0, -1, 0, 20, 0, 0, 1),
(53003, 0, -1, 0, 20, 0, 0, 1),
(53004, 0, -1, 0, 20, 0, 0, 1),
(53005, 0, -1, 0, 20, 0, 0, 1),
(53006, 0, -1, 0, 20, 0, 0, 1),
(53007, 0, -1, 0, 20, 0, 0, 1),
(53008, 0, -1, 0, 20, 0, 0, 1),
(53009, 0, -1, 0, 20, 0, 0, 1),
(53010, 0, -1, 0, 20, 0, 0, 1),
(53011, 0, -1, 0, 20, 0, 0, 1),
(53012, 0, -1, 0, 20, 0, 0, 1),
(53013, 0, -1, 0, 20, 0, 0, 1),
(53014, 0, -1, 0, 20, 0, 0, 1),
(53015, 0, -1, 0, 20, 0, 0, 1),
(53017, 0, -1, 0, 20, 0, 0, 1),
(53201, 0, -1, 0, 20, 0, 0, 1),
(55101, 0, -1, 1, 9, 0, 0, 1),
(55102, 0, -1, 1, 9, 0, 0, 1),
(55103, 0, -1, 1, 9, 0, 0, 1),
(55104, 0, -1, 1, 9, 0, 0, 1),
(55105, 0, -1, 1, 9, 0, 0, 1),
(55106, 0, -1, 1, 9, 0, 0, 1),
(55107, 0, -1, 1, 9, 0, 0, 1),
(55108, 0, -1, 1, 9, 0, 0, 1),
(100071, 0, -1, 0, 30, 0, 0, 1),
(100073, 0, -1, 0, 30, 0, 0, 1),
(100074, 0, -1, 0, 30, 0, 0, 1),
(200107, 0, -1, 1, 4, 0, 0, 1),
(254000, 0, -1, 0, 27, 0, 0, 1),
(254001, 0, -1, 0, 27, 0, 0, 1),
(254002, 0, -1, 0, 27, 0, 0, 1),
(254003, 0, -1, 0, 27, 0, 0, 1),
(254004, 0, -1, 0, 27, 0, 0, 1),
(254038, 0, -1, 0, 30, 0, 0, 1),
(254051, 0, -1, 0, 35, 0, 0, 1),
(254095, 0, -1, 0, 30, 0, 0, 1),
(254098, 0, -1, 0, 30, 0, 0, 1),
(254099, 0, -1, 0, 30, 0, 0, 1),
(254106, 0, -1, 0, 30, 0, 0, 1),
(254107, 0, -1, 0, 30, 0, 0, 1),
(500005, 0, -1, 0, 27, 0, 0, 1),
(500006, 0, -1, 0, 27, 0, 0, 1),
(650141, 0, -1, 1, 41, 0, 0, 1),
(650142, 0, -1, 1, 41, 0, 0, 1),
(650143, 0, -1, 1, 41, 0, 0, 1),
(650144, 0, -1, 1, 41, 0, 0, 1),
(650145, 0, -1, 1, 41, 0, 0, 1),
(650146, 0, -1, 1, 41, 0, 0, 1),
(650147, 0, -1, 1, 41, 0, 0, 1),
(650148, 0, -1, 1, 41, 0, 0, 1),
(650149, 0, -1, 1, 41, 0, 0, 1),
(650150, 0, -1, 1, 41, 0, 0, 1),
(650151, 0, -1, 1, 41, 0, 0, 1),
(650152, 0, -1, 1, 41, 0, 0, 1),
(650153, 0, -1, 1, 41, 0, 0, 1),
(650154, 0, -1, 1, 41, 0, 0, 1),
(650155, 0, -1, 1, 41, 0, 0, 1),
(650156, 0, -1, 1, 41, 0, 0, 1),
(650157, 0, -1, 1, 41, 0, 0, 1),
(650158, 0, -1, 1, 41, 0, 0, 1),
(650159, 0, -1, 1, 41, 0, 0, 1),
(1660000, 0, -1, 0, 30, 0, 0, 1),
(1660001, 0, -1, 0, 30, 0, 0, 1),
(1660002, 0, -1, 0, 30, 0, 0, 1),
(1660003, 0, -1, 0, 30, 0, 0, 1),
(1660004, 0, -1, 0, 30, 0, 0, 1),
(1660005, 0, -1, 0, 30, 0, 0, 1),
(1660006, 0, -1, 0, 27, 0, 0, 1),
(1660007, 0, -1, 0, 27, 0, 0, 1),
(1660008, 0, -1, 0, 27, 0, 0, 1),
(1660009, 0, -1, 0, 27, 0, 0, 1),
(1660010, 0, -1, 0, 27, 0, 0, 1),
(1660011, 0, -1, 0, 27, 0, 0, 1),
(1660012, 0, -1, 1, 41, 0, 0, 1),
(1660013, 0, -1, 1, 41, 0, 0, 1),
(1660014, 0, -1, 1, 41, 0, 0, 1),
(1660015, 0, -1, 1, 41, 0, 0, 1),
(1660016, 0, -1, 1, 41, 0, 0, 1),
(1660017, 0, -1, 1, 41, 0, 0, 1),
(1660038, 0, -1, 0, 30, 0, 0, 1),
(1660039, 0, -1, 0, 27, 0, 0, 1),
(1660040, 0, -1, 1, 41, 0, 0, 1),
(1660055, 0, -1, 0, 30, 0, 0, 1),
(1660056, 0, -1, 0, 30, 0, 0, 1),
(1660057, 0, -1, 0, 30, 0, 0, 1),
(1660058, 0, -1, 0, 30, 0, 0, 1),
(1660059, 0, -1, 0, 30, 0, 0, 1),
(1660060, 0, -1, 0, 30, 0, 0, 1),
(1660071, 0, -1, 1, 41, 0, 0, 1),
(1660072, 0, -1, 1, 41, 0, 0, 1),
(1660073, 0, -1, 1, 41, 0, 0, 1),
(1660074, 0, -1, 1, 41, 0, 0, 1),
(1660076, 0, -1, 0, 27, 0, 0, 1),
(1660077, 0, -1, 0, 27, 0, 0, 1),
(1660078, 0, -1, 0, 27, 0, 0, 1),
(1660079, 0, -1, 0, 27, 0, 0, 1),
(1660085, 0, -1, 1, 41, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (17000, 0), (17002, 0), (17003, 0), (17004, 0), (17005, 0), (17006, 0), (17007, 0), (17008, 0), (49976, 0),
    (49977, 0), (49978, 0), (49979, 0), (49980, 0), (49981, 0), (49982, 0), (49983, 0), (49984, 0), (49985, 0),
    (49986, 0), (49987, 0), (49988, 0), (49990, 0), (49991, 0), (49992, 0), (51000, 0), (51001, 0), (51002, 0),
    (51003, 0), (51004, 0), (51005, 0), (51006, 0), (51007, 0), (51008, 0), (51009, 0), (51010, 0), (51011, 0),
    (51012, 0), (51013, 0), (51014, 0), (52000, 0), (52001, 0), (52002, 0), (52003, 0), (52004, 0), (52005, 0),
    (52006, 0), (52007, 0), (52008, 0), (52009, 0), (52010, 0), (52011, 0), (52012, 0), (52013, 0), (52014, 0),
    (52015, 0), (52016, 0), (53000, 0), (53001, 0), (53002, 0), (53003, 0), (53004, 0), (53005, 0), (53006, 0),
    (53007, 0), (53008, 0), (53009, 0), (53010, 0), (53011, 0), (53012, 0), (53013, 0), (53014, 0), (53015, 0),
    (53017, 0), (53201, 0), (55101, 0), (55102, 0), (55103, 0), (55104, 0), (55105, 0), (55106, 0), (55107, 0),
    (55108, 0), (100071, 0), (100073, 0), (100074, 0), (200107, 0), (254000, 0), (254001, 0), (254002, 0),
    (254003, 0), (254004, 0), (254038, 0), (254051, 0), (254095, 0), (254098, 0), (254099, 0), (254106, 0),
    (254107, 0), (500005, 0), (500006, 0), (650141, 0), (650142, 0), (650143, 0), (650144, 0), (650145, 0),
    (650146, 0), (650147, 0), (650148, 0), (650149, 0), (650150, 0), (650151, 0), (650152, 0), (650153, 0),
    (650154, 0), (650155, 0), (650156, 0), (650157, 0), (650158, 0), (650159, 0), (1660000, 0), (1660001, 0),
    (1660002, 0), (1660003, 0), (1660004, 0), (1660005, 0), (1660006, 0), (1660007, 0), (1660008, 0), (1660009,
    0), (1660010, 0), (1660011, 0), (1660012, 0), (1660013, 0), (1660014, 0), (1660015, 0), (1660016, 0),
    (1660017, 0), (1660038, 0), (1660039, 0), (1660040, 0), (1660055, 0), (1660056, 0), (1660057, 0), (1660058,
    0), (1660059, 0), (1660060, 0), (1660071, 0), (1660072, 0), (1660073, 0), (1660074, 0), (1660076, 0),
    (1660077, 0), (1660078, 0), (1660079, 0), (1660085, 0));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(17000, 0, 0, -10005, 53),
(17002, 0, 0, -9562, -723),
(17003, 0, 0, -9562, -723),
(17004, 0, 0, -9610, -1032),
(17005, 0, 0, -8721, 1137),
(17006, 0, 0, -9770, -1380),
(17007, 0, 0, -9219, -2222),
(17008, 0, 0, -9634, 699),
(49976, 0, 0, -8878, -183),
(49977, 0, 0, -8906, -208),
(49978, 0, 0, -8907, -211),
(49979, 0, 0, -8939, -176),
(49980, 0, 0, -8873, -160),
(49981, 0, 0, -8852, -191),
(49982, 0, 0, -8920, -178),
(49983, 0, 0, -8950, -211),
(49984, 0, 0, -8917, -165),
(49985, 0, 0, -8905, -105),
(49986, 0, 0, -8854, -193),
(49987, 0, 0, -8926, -200),
(49988, 0, 0, -8910, -217),
(49990, 0, 0, -8914, -99),
(49991, 0, 0, -8875, -208),
(49992, 0, 0, -8949, -174),
(51000, 0, 0, -6099, 405),
(51001, 0, 0, -6104, 389),
(51002, 0, 0, -6056, 375),
(51003, 0, 0, -6186, 338),
(51004, 0, 0, -6054, 390),
(51005, 0, 0, -6168, 346),
(51006, 0, 0, -6101, 377),
(51007, 0, 0, -6232, 393),
(51008, 0, 0, -6054, 382),
(51009, 0, 0, -6116, 397),
(51010, 0, 0, -6115, 384),
(51011, 0, 0, -6056, 388),
(51012, 0, 0, -6127, 384),
(51013, 0, 0, -6218, 385),
(51014, 0, 0, -5598, -608),
(52000, 0, 0, -638, -4234),
(52001, 0, 0, -598, -4107),
(52002, 0, 0, -603, -4113),
(52003, 0, 0, -585, -4126),
(52004, 0, 0, -569, -4275),
(52005, 0, 0, -606, -4249),
(52006, 0, 0, -633, -4287),
(52007, 0, 0, -639, -4226),
(52008, 0, 0, -601, -4246),
(52009, 0, 0, -591, -4211),
(52010, 0, 0, -620, -4204),
(52011, 0, 0, -625, -4207),
(52012, 0, 0, -620, -4314),
(52013, 0, 0, -641, -4229),
(52014, 0, 0, -629, -4222),
(52015, 0, 0, -559, -4195),
(52016, 0, 0, -559, -4220),
(53000, 0, 0, 1870, 1636),
(53001, 0, 0, 1850, 1631),
(53002, 0, 0, 1861, 1626),
(53003, 0, 0, 1840, 1645),
(53004, 0, 0, 1882, 1588),
(53005, 0, 0, 1876, 1612),
(53006, 0, 0, 1885, 1621),
(53007, 0, 0, 1864, 1568),
(53008, 0, 0, 1863, 1563),
(53009, 0, 0, 1887, 1646),
(53010, 0, 0, 1848, 1641),
(53011, 0, 0, 1860, 1557),
(53012, 0, 0, 1837, 1628),
(53013, 0, 0, 1864, 1614),
(53014, 0, 0, 1843, 1574),
(53015, 0, 0, 1876, 1570),
(53017, 0, 0, 1850, 1563),
(53201, 0, 0, 1856, 1569),
(55101, 0, 0, -2938, -215),
(55102, 0, 0, -2882, -242),
(55103, 0, 0, -2874, -269),
(55104, 0, 0, -2906, -287),
(55105, 0, 0, -2862, -230),
(55106, 0, 0, -2887, -207),
(55107, 0, 0, -2900, -230),
(55108, 0, 0, -2883, -282),
(100071, 0, 0, -9491, -8),
(100073, 0, 0, -9496, 73),
(100074, 0, 0, -9462, 44),
(200107, 0, 0, -638, -4234),
(254000, 0, 0, -6111, 370),
(254001, 0, 0, -6111, 370),
(254002, 0, 0, -5924, 18),
(254003, 0, 0, -5584, -8),
(254004, 0, 0, -5584, -8),
(254038, 0, 0, -9784, -405),
(254051, 0, 0, -5201, -3522),
(254095, 0, 0, -9553, -728),
(254098, 0, 0, -9541, -717),
(254099, 0, 0, -9553, -728),
(254106, 0, 0, -9576, -718),
(254107, 0, 0, -9451, 80),
(500005, 0, 0, -5765, -1275),
(500006, 0, 0, -5773, -1246),
(650141, 0, 0, 10412, 783),
(650142, 0, 0, 10485, 817),
(650143, 0, 0, 10445, 784),
(650144, 0, 0, 10518, 778),
(650145, 0, 0, 10345, 757),
(650146, 0, 0, 10410, 876),
(650147, 0, 0, 10347, 762),
(650148, 0, 0, 10387, 812),
(650149, 0, 0, 10477, 816),
(650150, 0, 0, 10425, 836),
(650151, 0, 0, 10440, 775),
(650152, 0, 0, 10461, 830),
(650153, 0, 0, 10528, 777),
(650154, 0, 0, 10433, 770),
(650155, 0, 0, 10458, 808),
(650156, 0, 0, 10464, 799),
(650157, 0, 0, 10482, 806),
(650158, 0, 0, 10405, 718),
(650159, 0, 0, 10434, 796),
(1660000, 0, 0, -8901, -197),
(1660001, 0, 0, -8901, -197),
(1660002, 0, 0, -8749, -283),
(1660003, 0, 0, -8749, -283),
(1660004, 0, 0, -8901, -197),
(1660005, 0, 0, -8852, -369),
(1660006, 0, 0, -6169, 772),
(1660007, 0, 0, -6011, 681),
(1660008, 0, 0, -6011, 681),
(1660009, 0, 0, -6094, 405),
(1660010, 0, 0, -5997, 752),
(1660011, 0, 0, -5897, 499),
(1660012, 0, 0, 10695, 594),
(1660013, 0, 0, 10797, 481),
(1660014, 0, 0, 10797, 481),
(1660015, 0, 0, 10824, 493),
(1660016, 0, 0, 10797, 481),
(1660017, 0, 0, 10690, 528),
(1660038, 0, 0, -8749, -283),
(1660039, 0, 0, -5997, 752),
(1660040, 0, 0, 10712, 447),
(1660055, 0, 0, -9464, 39),
(1660056, 0, 0, -9275, 469),
(1660057, 0, 0, -9275, 469),
(1660058, 0, 0, -9578, 35),
(1660059, 0, 0, -9565, 10),
(1660060, 0, 0, -9397, -12),
(1660071, 0, 0, 9950, 894),
(1660072, 0, 0, 10056, 911),
(1660073, 0, 0, 10056, 911),
(1660074, 0, 0, 9804, 939),
(1660076, 0, 0, -5607, -530),
(1660077, 0, 0, -5607, -530),
(1660078, 0, 0, -5712, -604),
(1660079, 0, 0, -5641, -622),
(1660085, 0, 0, 10376, 745);

-- ---------------------------------------------------------------------------
-- 4. Markers at the ender or the moved objective (no current QuestSuperTrack point)
-- ---------------------------------------------------------------------------
--   53016 Spirit Fetish: turn-in at Shadow-Walker Voss 9300251 (Tirisfal Glades, hand-placed trainer)
--   55100 Seared Tome: turn-in at Apprentice Yahk Loregrain 503403 (Mulgore, hand-placed trainer)
--   55109 Sacred Oath: turn-in at Jax Dawnsoar 9300300 (Mulgore, hand-placed trainer)
--   55110 Plains Hunter Guide: turn-in at Nawat Windhorn 9300301 (Mulgore, hand-placed trainer)
--   254041 Report To The General: turn-in at General Marcus Jonathan 466 (Stormwind City, Stormwind Keep)
--   254108 Final Dig: turn-in at Agent Serina Vale 996114 (Elwynn Forest, Goldshire)
--   1660075 Stay a While: turn-in at Alenna Whisperbough 162881 (Teldrassil, Dolanaar)
--   1660080 Stay a While: turn-in at Gravedigger Nonuid 162901 (Dun Morogh, Kharanos)
--   9302123 Bone-Bound Codex: turn-in at Morthalis Gravewhisper 9300473 (Eversong Woods, 305 yd from the start)
--   9302125 Whispering Parchment: turn-in at Zaelith Shadowmoor 9300475 (Eversong Woods, 283 yd from the start)
--   254108 objective 0: Find the Mole in the Lion's Pride Inn: QuestSuperTrack 8514 (-9467.77, 14.56, r 25) is
--     the stock inn spot; through the inn transform (DISCOVERIES D6) it is (-9485.7, -20.3), 5 yd from Innkeeper
--     Farley
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (53016, 0), (55100, 0), (55109, 0), (55110, 0), (254041, 0), (254108, 0), (254108, 1), (1660075, 0),
    (1660080, 0), (9302123, 0), (9302125, 0));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(53016, 0, -1, 0, 20, 0, 0, 1),
(55100, 0, -1, 1, 9, 0, 0, 1),
(55109, 0, -1, 1, 9, 0, 0, 1),
(55110, 0, -1, 1, 9, 0, 0, 1),
(254041, 0, -1, 0, 301, 0, 0, 1),
(254108, 0, 0, 0, 30, 0, 0, 1),
(254108, 1, -1, 0, 30, 0, 0, 1),
(1660075, 0, -1, 1, 41, 0, 0, 1),
(1660080, 0, -1, 0, 27, 0, 0, 1),
(9302123, 0, -1, 530, 462, 0, 0, 1),
(9302125, 0, -1, 530, 462, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (53016, 0), (55100, 0), (55109, 0), (55110, 0), (254041, 0), (254108, 0), (254108, 1), (1660075, 0),
    (1660080, 0), (9302123, 0), (9302125, 0));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(53016, 0, 0, 1836, 1599),
(55100, 0, 0, -2903, -260),
(55109, 0, 0, -2921, -279),
(55110, 0, 0, -2905, -204),
(254041, 0, 0, -8954, 521),
(254108, 0, 0, -9486, -20),
(254108, 1, 0, -9451, 80),
(1660075, 0, 0, 9831, 792),
(1660080, 0, 0, -5603, -605),
(9302123, 0, 0, 10046, -6325),
(9302125, 0, 0, 10213, -6110);
