-- Conquest of Azeroth rebuilt Stormwind City in the Cataclysm style: new district models for the keep, Old
-- Town, the Trade, Cathedral, Dwarven and Mage districts, the Park and the harbour, raised ground under the
-- streets, canals and a lake where the keep's east wing stood, the Kul Tiras docks and a cemetery. The
-- stock spawns stayed in the stock city: NPCs, chairs and holiday decorations float, sit in walls or under
-- floors, or stand where a building is gone. This moves them into the CoA city.
--
-- WHERE EACH POSITION COMES FROM
--   Eight district reviews checked every displaced stock row against the CoA and the stock server collision
--   data and decided it by hand. Each group of rows below carries the reason for its decision.
--   QuestSuperTrack  CoA turn-in points in the client: Mathias Shaw, Warden Thelwater, the Argent
--     Emissary, the Pilgrim's Bounty cooks, and Samuel Hawke, whom AC spawns only at Refuge Pointe and whose
--     care-package quests CoA ends at the Champions' Hall map table. The throne spot is CoA quest 255096's
--     turn-in point; King Varian stands there for the ruler, since AC gives him Bolvar's quests.
--   rigid rooms  CoA kept some rooms whole and moved them: the war room, the Hall of Petitioners (turned
--     half a circle), the Royal Library, the Pig and Whistle, the barracks, the Cathedral rooms and the main
--     gate. Their furniture matches the stock pieces to 0.01 yd after the move, and the rows move with it.
--   same place  the same street, room or wall, with z on the CoA floor.
--   reasoned  the equivalent place in the CoA layout for the row: a guard at his post, a banker at his
--     counter, Tyrion in the keep's roof garden, a candle on its wall, a signpost arm on its new post.
--     Candles on the new fountain sit on its visible bowls, which lie below its collision hull.
--   paths  patrols, walkers, the spots SmartAI followers walk to and the quest 434 escort follow their
--     NPCs; the Deeprun Tram trigger 2173 takes its CoA AreaTrigger.dbc position.
--   landings  the Deeprun Tram exit, the Lunar Festival teleport, the Forlorn Spirit that quest 74
--     summons and Lady Jaina's Portal to Orgrimmar after quest 13369 land on the CoA floor.
--   deleted  chairs, benches, plaques, signpost arms and holiday decorations whose room, table, statue,
--     arch, post or wall CoA removed, with their game event, pool and addon rows. No NPC and no functional
--     object is deleted.
--
-- 195 creatures and 753 objects move, 212 objects are deleted, 1 creature is added, and 73 reviewed rows stay.
-- Each UPDATE matches guid and entry, so a row something else has changed is left alone.

-- ---------------------------------------------------------------------------
-- 1. Stormwind Keep: throne hall, war room, Hall of Petitioners, House of Nobles
-- ---------------------------------------------------------------------------
-- King Varian Wrynn: ruler on the CoA throne: the turn-in point of CoA quest 255096 beside Stormwindthrone.m2 is the
--   throne NPC spot (its ender is unnamed; CoA's own roster has Bolvar as Lord Regent, so Varian stands in for the
--   ruler because AC gives him Bolvar's quests); stock throne room is inside the CoA keep substructure
UPDATE `creature` SET `position_x` = -8364.7, `position_y` = 230.9, `position_z` = 156.99, `orientation` = 2.243 WHERE `guid` = 10495 AND `id` = 29611;
-- Anduin Wrynn: prince at the king's side: CoA throne dais, mirroring Varian across the throne, facing the hall
UPDATE `creature` SET `position_x` = -8361.48, `position_y` = 233.47, `position_z` = 156.99, `orientation` = 2.243 WHERE `guid` = 10494 AND `id` = 1747;
-- Lady Jaina Proudmoore: stood beside Varian on the stock dais; CoA throne dais beyond Varian, facing the hall
UPDATE `creature` SET `position_x` = -8366.56, `position_y` = 229.49, `position_z` = 156.99, `orientation` = 2.243 WHERE `guid` = 1976212 AND `id` = 32346;
-- Emissary Taluun: draenei envoy stood by the stock throne; CoA throne hall at the foot of the dais steps, facing the
--   aisle
UPDATE `creature` SET `position_x` = -8357.93, `position_y` = 246.58, `position_z` = 155.35, `orientation` = 3.814 WHERE `guid` = 49590 AND `id` = 17103;
-- Peddlefeet: Love is in the Air cherub stood in the stock throne room; CoA throne hall beside the aisle, facing it
UPDATE `creature` SET `position_x` = -8366.81, `position_y` = 256.13, `position_z` = 155.35, `orientation` = 3.814 WHERE `guid` = 244514 AND `id` = 16085;
-- Portal to Undercity: functional portal stood by Jaina in the stock throne room; CoA throne hall on her side of the
--   dais, facing across the hall
UPDATE `gameobject` SET `position_x` = -8379.68, `position_y` = 230.55, `position_z` = 155.35, `orientation` = 0.672, `rotation2` = 0.329713, `rotation3` = 0.944081 WHERE `guid` = 2133395 AND `id` = 193955;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: flanks the dais steps (left), facing the hall
UPDATE `creature` SET `position_x` = -8374.83, `position_y` = 232.49, `position_z` = 155.32, `orientation` = 2.243 WHERE `guid` = 10513 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: flanks the dais steps (right), facing the hall
UPDATE `creature` SET `position_x` = -8360.75, `position_y` = 243.7, `position_z` = 155.32, `orientation` = 2.243 WHERE `guid` = 10514 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: aisle post, left, facing the aisle
UPDATE `creature` SET `position_x` = -8376.07, `position_y` = 237.26, `position_z` = 155.34, `orientation` = 0.672 WHERE `guid` = 10515 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: aisle post, right, facing the aisle
UPDATE `creature` SET `position_x` = -8365.11, `position_y` = 245.98, `position_z` = 155.34, `orientation` = 3.814 WHERE `guid` = 10516 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: aisle post between the side doors, left
UPDATE `creature` SET `position_x` = -8380.43, `position_y` = 242.73, `position_z` = 155.35, `orientation` = 0.672 WHERE `guid` = 10517 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: aisle post between the side doors, right
UPDATE `creature` SET `position_x` = -8369.47, `position_y` = 251.45, `position_z` = 155.35, `orientation` = 3.814 WHERE `guid` = 10518 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: aisle post, left
UPDATE `creature` SET `position_x` = -8384.79, `position_y` = 248.21, `position_z` = 155.35, `orientation` = 0.672 WHERE `guid` = 10519 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: aisle post, right
UPDATE `creature` SET `position_x` = -8373.83, `position_y` = 256.93, `position_z` = 155.35, `orientation` = 3.814 WHERE `guid` = 10520 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: flanks the hall end at the bridge to the grand
--   stair, left
UPDATE `creature` SET `position_x` = -8390.24, `position_y` = 253.46, `position_z` = 155.35, `orientation` = 0.672 WHERE `guid` = 10521 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: flanks the hall end at the bridge to the grand
--   stair, right
UPDATE `creature` SET `position_x` = -8377.72, `position_y` = 263.42, `position_z` = 155.35, `orientation` = 3.814 WHERE `guid` = 10522 AND `id` = 1756;
-- Stormwind Royal Guard: stock throne-room guard; CoA throne hall: duplicate of 10520 (0.3 yd apart in stock), posted
--   at the gallery side door
UPDATE `creature` SET `position_x` = -8358.61, `position_y` = 253.07, `position_z` = 155.35, `orientation` = 3.814 WHERE `guid` = 51984 AND `id` = 1756;
-- Stormwind Royal Guard: stock stair-top guard on the way to the throne; CoA equivalent is the foot of the grand stair
--   to the throne room (vestibule 147), left, facing visitors
UPDATE `creature` SET `position_x` = -8415.13, `position_y` = 291.16, `position_z` = 147.01, `orientation` = 2.243 WHERE `guid` = 10511 AND `id` = 1756;
-- Stormwind Royal Guard: reviewed fits row: stood on the CoA fountain rim (116.56) in the lower courtyard; pair of
--   10511 at the grand stair foot, right
UPDATE `creature` SET `position_x` = -8408.87, `position_y` = 296.14, `position_z` = 147.01, `orientation` = 2.243 WHERE `guid` = 10512 AND `id` = 1756;
-- Alliance Brigadier General: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall
--   match to 0.01 yd); same spot in the room (Call to Arms quest ender)
UPDATE `creature` SET `position_x` = -8401.53, `position_y` = 207.91, `position_z` = 155.35, `orientation` = 2.201 WHERE `guid` = 14740 AND `id` = 15351;
-- Beka Zipwhistle: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01
--   yd); same spot in the room (arena battlemaster)
UPDATE `creature` SET `position_x` = -8417.81, `position_y` = 199.75, `position_z` = 155.35, `orientation` = 0.933 WHERE `guid` = 68938 AND `id` = 19911;
-- Devin Fardale: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01
--   yd); same spot in the room (battlemaster, flanks the door lane)
UPDATE `creature` SET `position_x` = -8400.31, `position_y` = 217.64, `position_z` = 155.35, `orientation` = 3.929 WHERE `guid` = 88242 AND `id` = 34997;
-- Arcanist Paharin: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to
--   0.01 yd); same spot in the room (Wintergrasp battle-mage beside the corner table)
UPDATE `creature` SET `position_x` = -8398.9, `position_y` = 211.12, `position_z` = 155.35, `orientation` = 2.445 WHERE `guid` = 88243 AND `id` = 35598;
-- Alison Devay: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01
--   yd); same spot in the room (battlemaster, flanks the door lane)
UPDATE `creature` SET `position_x` = -8407.7, `position_y` = 227.04, `position_z` = 155.35, `orientation` = 3.886 WHERE `guid` = 88244 AND `id` = 34998;
-- Grand Admiral Jes-Tereth: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall
--   match to 0.01 yd); mapped spot is under CoA's new 8Sw_Wartable01, so he stands at the war table facing Mithras
--   across it
UPDATE `creature` SET `position_x` = -8413.38, `position_y` = 220.04, `position_z` = 155.35, `orientation` = 4.723 WHERE `guid` = 10498 AND `id` = 1750;
-- Mithras Ironhill: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to
--   0.01 yd); mapped spot touches the new war table, so he stands at its far side facing Jes-Tereth
UPDATE `creature` SET `position_x` = -8413.26, `position_y` = 208.64, `position_z` = 155.35, `orientation` = 1.581 WHERE `guid` = 10499 AND `id` = 1751;
-- Behsten: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01 yd);
--   mapped corner is inside a CoA wall and dwarven table, so he stands on the open floor between the corner table and
--   the rifle table
UPDATE `creature` SET `position_x` = -8427.99, `position_y` = 219.92, `position_z` = 155.35, `orientation` = 5.92 WHERE `guid` = 88241 AND `id` = 35365;
-- 6 rows: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01 yd);
--   Call to Arms trio keeps its stock arrangement round the banner, moved off the new door lane to the open floor by
--   the cannons (spot A)
UPDATE `creature` SET `position_x` = -8421.85, `position_y` = 209.51, `position_z` = 155.35, `orientation` = 2.304 WHERE `guid` = 208108 AND `id` = 34948;
UPDATE `creature` SET `position_x` = -8421.85, `position_y` = 209.51, `position_z` = 155.35, `orientation` = 2.304 WHERE `guid` = 208121 AND `id` = 30566;
UPDATE `creature` SET `position_x` = -8421.85, `position_y` = 209.51, `position_z` = 155.35, `orientation` = 2.304 WHERE `guid` = 208134 AND `id` = 15103;
UPDATE `creature` SET `position_x` = -8421.85, `position_y` = 209.51, `position_z` = 155.35, `orientation` = 2.304 WHERE `guid` = 208147 AND `id` = 14991;
UPDATE `creature` SET `position_x` = -8421.85, `position_y` = 209.51, `position_z` = 155.35, `orientation` = 2.304 WHERE `guid` = 208160 AND `id` = 22013;
UPDATE `creature` SET `position_x` = -8421.85, `position_y` = 209.51, `position_z` = 155.35, `orientation` = 2.304 WHERE `guid` = 208173 AND `id` = 15102;
-- 6 rows: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01 yd);
--   Call to Arms trio keeps its stock arrangement round the banner, moved off the new door lane to the open floor by
--   the cannons (spot B)
UPDATE `creature` SET `position_x` = -8423.65, `position_y` = 211.84, `position_z` = 155.35, `orientation` = 5.533 WHERE `guid` = 208114 AND `id` = 34950;
UPDATE `creature` SET `position_x` = -8423.65, `position_y` = 211.84, `position_z` = 155.35, `orientation` = 5.533 WHERE `guid` = 208127 AND `id` = 30566;
UPDATE `creature` SET `position_x` = -8423.65, `position_y` = 211.84, `position_z` = 155.35, `orientation` = 5.533 WHERE `guid` = 208140 AND `id` = 15103;
UPDATE `creature` SET `position_x` = -8423.65, `position_y` = 211.84, `position_z` = 155.35, `orientation` = 5.533 WHERE `guid` = 208153 AND `id` = 14991;
UPDATE `creature` SET `position_x` = -8423.65, `position_y` = 211.84, `position_z` = 155.35, `orientation` = 5.533 WHERE `guid` = 208166 AND `id` = 22013;
UPDATE `creature` SET `position_x` = -8423.65, `position_y` = 211.84, `position_z` = 155.35, `orientation` = 5.533 WHERE `guid` = 208179 AND `id` = 15102;
-- 6 rows: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01 yd);
--   Call to Arms trio keeps its stock arrangement round the banner, moved off the new door lane to the open floor by
--   the cannons (spot C)
UPDATE `creature` SET `position_x` = -8420.56, `position_y` = 212.35, `position_z` = 155.35, `orientation` = 0.646 WHERE `guid` = 208120 AND `id` = 35024;
UPDATE `creature` SET `position_x` = -8420.56, `position_y` = 212.35, `position_z` = 155.35, `orientation` = 0.646 WHERE `guid` = 208133 AND `id` = 30578;
UPDATE `creature` SET `position_x` = -8420.56, `position_y` = 212.35, `position_z` = 155.35, `orientation` = 0.646 WHERE `guid` = 208146 AND `id` = 7410;
UPDATE `creature` SET `position_x` = -8420.56, `position_y` = 212.35, `position_z` = 155.35, `orientation` = 0.646 WHERE `guid` = 208159 AND `id` = 15008;
UPDATE `creature` SET `position_x` = -8420.56, `position_y` = 212.35, `position_z` = 155.35, `orientation` = 0.646 WHERE `guid` = 208172 AND `id` = 20381;
UPDATE `creature` SET `position_x` = -8420.56, `position_y` = 212.35, `position_z` = 155.35, `orientation` = 0.646 WHERE `guid` = 208185 AND `id` = 14981;
-- 6 rows: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01 yd);
--   Call to Arms banner stays with its emissaries off the new door lane, facing into the room
UPDATE `gameobject` SET `position_x` = -8424.19, `position_y` = 209.53, `position_z` = 155.35, `orientation` = 0.681, `rotation2` = 0.333958, `rotation3` = 0.942588 WHERE `guid` = 151600 AND `id` = 195532;
UPDATE `gameobject` SET `position_x` = -8424.19, `position_y` = 209.53, `position_z` = 155.35, `orientation` = 0.681, `rotation2` = 0.333958, `rotation3` = 0.942588 WHERE `guid` = 151605 AND `id` = 192686;
UPDATE `gameobject` SET `position_x` = -8424.19, `position_y` = 209.53, `position_z` = 155.35, `orientation` = 0.681, `rotation2` = 0.333958, `rotation3` = 0.942588 WHERE `guid` = 151610 AND `id` = 180399;
UPDATE `gameobject` SET `position_x` = -8424.19, `position_y` = 209.53, `position_z` = 155.35, `orientation` = 0.681, `rotation2` = 0.333958, `rotation3` = 0.942588 WHERE `guid` = 151615 AND `id` = 180398;
UPDATE `gameobject` SET `position_x` = -8424.19, `position_y` = 209.53, `position_z` = 155.35, `orientation` = 0.681, `rotation2` = 0.333958, `rotation3` = 0.942588 WHERE `guid` = 151620 AND `id` = 185107;
UPDATE `gameobject` SET `position_x` = -8424.19, `position_y` = 209.53, `position_z` = 155.35, `orientation` = 0.681, `rotation2` = 0.333958, `rotation3` = 0.942588 WHERE `guid` = 151625 AND `id` = 180400;
-- PVP HOLIDAY GENERIC SIGNPOST: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall
--   match to 0.01 yd); signpost beside the Call to Arms banner as in stock
UPDATE `gameobject` SET `position_x` = -8424.52, `position_y` = 209.22, `position_z` = 155.35, `orientation` = 0.672, `rotation2` = 0.329713, `rotation3` = 0.944081 WHERE `guid` = 6616 AND `id` = 180397;
-- Highback Chair: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01
--   yd); chair at its own small table
UPDATE `gameobject` SET `position_x` = -8411.13, `position_y` = 230.33, `position_z` = 155.35, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 13881 AND `id` = 24583;
UPDATE `gameobject` SET `position_x` = -8413.13, `position_y` = 233.02, `position_z` = 155.35, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 13883 AND `id` = 24585;
UPDATE `gameobject` SET `position_x` = -8397.78, `position_y` = 213.72, `position_z` = 155.35, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 13884 AND `id` = 24586;
UPDATE `gameobject` SET `position_x` = -8395.55, `position_y` = 213.43, `position_z` = 155.35, `orientation` = 3.814, `rotation2` = 0.944014, `rotation3` = -0.329906 WHERE `guid` = 13885 AND `id` = 24590;
UPDATE `gameobject` SET `position_x` = -8395.77, `position_y` = 211.03, `position_z` = 155.35, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 13886 AND `id` = 24591;
UPDATE `gameobject` SET `position_x` = -8415.28, `position_y` = 195.7, `position_z` = 155.35, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 13887 AND `id` = 24592;
UPDATE `gameobject` SET `position_x` = -8414.98, `position_y` = 197.94, `position_z` = 155.35, `orientation` = 3.814, `rotation2` = 0.944014, `rotation3` = -0.329906 WHERE `guid` = 13888 AND `id` = 24593;
UPDATE `gameobject` SET `position_x` = -8417.68, `position_y` = 195.93, `position_z` = 155.35, `orientation` = 0.672 WHERE `guid` = 13889 AND `id` = 24594;
UPDATE `gameobject` SET `position_x` = -8430.34, `position_y` = 217.24, `position_z` = 155.35, `orientation` = 3.814, `rotation2` = 0.944014, `rotation3` = -0.329906 WHERE `guid` = 13890 AND `id` = 24595;
UPDATE `gameobject` SET `position_x` = -8430.63, `position_y` = 215, `position_z` = 155.35, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 13891 AND `id` = 24596;
-- Highback Chair: stock war room -> CoA war room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01
--   yd); mapped seat is taken by a new CoA dwarven table, so the chair takes the free side of the same small table
UPDATE `gameobject` SET `position_x` = -8413.59, `position_y` = 230.58, `position_z` = 155.35, `orientation` = 0.672, `rotation2` = 0.329713, `rotation3` = 0.944081 WHERE `guid` = 13882 AND `id` = 24584;
UPDATE `gameobject` SET `position_x` = -8432.82, `position_y` = 217.62, `position_z` = 155.35, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 13892 AND `id` = 24390;
-- War of the Spider, The Battle of Grim Batol, The Dark Portal and the Fall of Stormwind: stock war room -> CoA war
--   room (translation -15.86,-64.70,+34.46; its 4 Inntablesmall match to 0.01 yd); readable book on the same small
--   table, in the free corner beside CoA's book stacks and candelabra
UPDATE `gameobject` SET `position_x` = -8396.59, `position_y` = 213.05, `position_z` = 156.48, `orientation` = 0.454 WHERE `guid` = 18597 AND `id` = 175753;
UPDATE `gameobject` SET `position_x` = -8417.16, `position_y` = 197.25, `position_z` = 156.48, `orientation` = 3.283, `rotation2` = 0.997502, `rotation3` = -0.070645 WHERE `guid` = 18590 AND `id` = 175750;
UPDATE `gameobject` SET `position_x` = -8432.51, `position_y` = 216.55, `position_z` = 156.48, `orientation` = 3.84, `rotation2` = 0.939645, `rotation3` = -0.34215 WHERE `guid` = 18578 AND `id` = 175745;
-- Caledra Dawnbreeze: stock Hall of Petitioners -> CoA hall at 147 (rotation pi about the Inntable: x'=-16940.40-x,
--   y'=692.02-y, z+38.63; 7 candelabras and the Inntable match to 0.01 yd); petitioner in the hall
UPDATE `creature` SET `position_x` = -8406.4, `position_y` = 324.89, `position_z` = 147.01, `orientation` = 5.428 WHERE `guid` = 10500 AND `id` = 1752;
-- Stormwind Royal Guard: stock Hall of Petitioners -> CoA hall at 147 (rotation pi about the Inntable: x'=-16940.40-x,
--   y'=692.02-y, z+38.63; 7 candelabras and the Inntable match to 0.01 yd); door guard on the vestibule side of the
--   hall door
UPDATE `creature` SET `position_x` = -8408.4, `position_y` = 299.95, `position_z` = 147.01, `orientation` = 3.816 WHERE `guid` = 10507 AND `id` = 1756;
UPDATE `creature` SET `position_x` = -8414.4, `position_y` = 306.64, `position_z` = 147.01, `orientation` = 3.871 WHERE `guid` = 10509 AND `id` = 1756;
-- Highback Chair: stock Hall of Petitioners -> CoA hall at 147 (rotation pi about the Inntable: x'=-16940.40-x,
--   y'=692.02-y, z+38.63; 7 candelabras and the Inntable match to 0.01 yd); chair at the hall table
UPDATE `gameobject` SET `position_x` = -8389.29, `position_y` = 320.79, `position_z` = 147.01, `orientation` = 3.665, `rotation2` = 0.965951, `rotation3` = -0.258727 WHERE `guid` = 26481 AND `id` = 24562;
UPDATE `gameobject` SET `position_x` = -8389.25, `position_y` = 317.11, `position_z` = 147.01, `orientation` = 1.998, `rotation2` = 0.84093, `rotation3` = 0.541144 WHERE `guid` = 26482 AND `id` = 24563;
UPDATE `gameobject` SET `position_x` = -8392.63, `position_y` = 318.24, `position_z` = 147.01, `orientation` = 0.628, `rotation2` = 0.308866, `rotation3` = 0.951106 WHERE `guid` = 26483 AND `id` = 24564;
UPDATE `gameobject` SET `position_x` = -8392.55, `position_y` = 321.19, `position_z` = 147.01, `orientation` = 5.463, `rotation2` = 0.398694, `rotation3` = -0.917084 WHERE `guid` = 26503 AND `id` = 24566;
-- Wooden Bench: stock Hall of Petitioners -> CoA hall at 147 (rotation pi about the Inntable: x'=-16940.40-x,
--   y'=692.02-y, z+38.63; 7 candelabras and the Inntable match to 0.01 yd); petitioners' bench along the hall wall
UPDATE `gameobject` SET `position_x` = -8412.61, `position_y` = 326.17, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 13936 AND `id` = 24540;
UPDATE `gameobject` SET `position_x` = -8413.69, `position_y` = 316.9, `position_z` = 147.01, `orientation` = 0.672, `rotation2` = 0.329713, `rotation3` = 0.944081 WHERE `guid` = 13943 AND `id` = 24549;
UPDATE `gameobject` SET `position_x` = -8407.94, `position_y` = 320.1, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 13945 AND `id` = 24553;
UPDATE `gameobject` SET `position_x` = -8409.61, `position_y` = 322.2, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 13946 AND `id` = 24554;
UPDATE `gameobject` SET `position_x` = -8390.02, `position_y` = 337.78, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 26479 AND `id` = 24548;
UPDATE `gameobject` SET `position_x` = -8398.22, `position_y` = 297.44, `position_z` = 147.01, `orientation` = 0.672, `rotation2` = 0.329713, `rotation3` = 0.944081 WHERE `guid` = 26480 AND `id` = 24551;
UPDATE `gameobject` SET `position_x` = -8388.36, `position_y` = 335.69, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 26484 AND `id` = 24547;
UPDATE `gameobject` SET `position_x` = -8389.12, `position_y` = 296.58, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26487 AND `id` = 24546;
UPDATE `gameobject` SET `position_x` = -8372.82, `position_y` = 316.1, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26488 AND `id` = 24544;
UPDATE `gameobject` SET `position_x` = -8374.48, `position_y` = 318.19, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26489 AND `id` = 24545;
UPDATE `gameobject` SET `position_x` = -8392.4, `position_y` = 300.52, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26490 AND `id` = 24538;
UPDATE `gameobject` SET `position_x` = -8402.95, `position_y` = 333.85, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 26491 AND `id` = 24539;
UPDATE `gameobject` SET `position_x` = -8394.07, `position_y` = 302.61, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26492 AND `id` = 24542;
UPDATE `gameobject` SET `position_x` = -8379.46, `position_y` = 304.27, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26495 AND `id` = 24552;
UPDATE `gameobject` SET `position_x` = -8376.42, `position_y` = 330.73, `position_z` = 147.01, `orientation` = 3.814, `rotation2` = 0.944014, `rotation3` = -0.329906 WHERE `guid` = 26501 AND `id` = 24541;
UPDATE `gameobject` SET `position_x` = -8369.66, `position_y` = 312.06, `position_z` = 147.01, `orientation` = 2.243, `rotation2` = 0.900753, `rotation3` = 0.434332 WHERE `guid` = 26502 AND `id` = 24550;
UPDATE `gameobject` SET `position_x` = -8368.63, `position_y` = 320.93, `position_z` = 147.01, `orientation` = 3.814, `rotation2` = 0.944014, `rotation3` = -0.329906 WHERE `guid` = 26509 AND `id` = 24555;
UPDATE `gameobject` SET `position_x` = -8384.11, `position_y` = 340.39, `position_z` = 147.01, `orientation` = 3.814, `rotation2` = 0.944014, `rotation3` = -0.329906 WHERE `guid` = 26510 AND `id` = 24556;
UPDATE `gameobject` SET `position_x` = -8393.15, `position_y` = 341.65, `position_z` = 147.01, `orientation` = 5.384, `rotation2` = 0.434599, `rotation3` = -0.900624 WHERE `guid` = 26511 AND `id` = 24543;
-- Stormwind Royal Guard: stock Hall of Petitioners -> CoA hall at 147 (rotation pi about the Inntable: x'=-16940.40-x,
--   y'=692.02-y, z+38.63; 7 candelabras and the Inntable match to 0.01 yd); patrol start at the hall door; path 105280
--   rewritten (waypoint rows)
UPDATE `creature` SET `position_x` = -8408.2, `position_y` = 305.62, `position_z` = 147.01, `orientation` = 0.637 WHERE `guid` = 10528 AND `id` = 1756;
-- Bishop DeLavey: his stock west room is gone (CoA terrain); nearest surviving public room of the keep is the moved
--   Hall of Petitioners: at its reading table (Inntable with books)
UPDATE `creature` SET `position_x` = -8391.48, `position_y` = 313.57, `position_z` = 147.01, `orientation` = 1.457 WHERE `guid` = 33821 AND `id` = 4960;
-- Count Remington Ridgewell: CoA House of Nobles / Petitioner's Chamber (floor 126.93; CoA quests 175000/175001); NPC
--   subname <House of Nobles>; quest 336 sends players to the Hall of Petitioners; stands off the council table's near
--   end facing it, clear of its six seats
UPDATE `creature` SET `position_x` = -8313.42, `position_y` = 285.6, `position_z` = 126.93, `orientation` = 2.685 WHERE `guid` = 79748 AND `id` = 2285;
-- Lord Baurles K. Wishock: CoA House of Nobles / Petitioner's Chamber (floor 126.93; CoA quests 175000/175001); NPC
--   subname <House of Nobles>; quest 336 sends players to the Hall of Petitioners; stands off the council table's far
--   end facing it, clear of Darengar's seat (175000 turn-in)
UPDATE `creature` SET `position_x` = -8321.13, `position_y` = 296.09, `position_z` = 126.93, `orientation` = 4.822 WHERE `guid` = 79749 AND `id` = 1439;
-- Stormwind Royal Guard: keep bridge guard post still exists; CoA bridge floor (A01Sw_Oldtown) is 1.8 yd higher
UPDATE `creature` SET `position_x` = -8531, `position_y` = 438.99, `position_z` = 106.98, `orientation` = 0.496 WHERE `guid` = 10508 AND `id` = 1756;
UPDATE `creature` SET `position_x` = -8524, `position_y` = 444.52, `position_z` = 106.99, `orientation` = 3.863 WHERE `guid` = 10510 AND `id` = 1756;
UPDATE `creature` SET `position_x` = -8527.76, `position_y` = 441.73, `position_z` = 106.95, `orientation` = 2.237 WHERE `guid` = 10527 AND `id` = 1756;
-- Fire Festival Fury Trap: Midsummer walk-through trap on the keep bridge; same place, CoA bridge floor 0.76 yd higher
UPDATE `gameobject` SET `position_x` = -8532.75, `position_y` = 448.79, `position_z` = 105.67, `orientation` = 1.606, `rotation2` = 0.719443, `rotation3` = 0.694552 WHERE `guid` = 54653 AND `id` = 181431;
-- Mailbox: mailbox was sunk 0.9 yd into CoA's Stormwindplanter03; beside the planter on the street, clear of the lamp
--   post
UPDATE `gameobject` SET `position_x` = -8556.3, `position_y` = 461.8, `position_z` = 104.6, `orientation` = 1.946 WHERE `guid` = 932 AND `id` = 195605;
-- Warm Fire: keep kitchen cooking fire (spell focus Cooking Fire, functional, kept): CoA's keep has no kitchen and the
--   stock one is now Lake Landen water; set on the dry lakeside boat landing north of the keep, between its two
--   Innbench seats by the fish barrels and dock, pair offset and facings as in stock
UPDATE `gameobject` SET `position_x` = -8240.6, `position_y` = 398.6, `position_z` = 117.26, `orientation` = 4.6164 WHERE `guid` = 30831 AND `id` = 24761;
UPDATE `gameobject` SET `position_x` = -8240.34, `position_y` = 399.26, `position_z` = 117.26, `orientation` = 1.4399 WHERE `guid` = 30832 AND `id` = 24762;
-- Stormwind Royal Guard 10527 path: same approach from the keep bridge to the lower courtyard; re-z to the CoA floor
UPDATE `waypoint_data` SET `position_x` = -8527.76, `position_y` = 441.73, `position_z` = 106.95 WHERE `id` = 105270 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8515.37, `position_y` = 426.32, `position_z` = 106.86 WHERE `id` = 105270 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8508.34, `position_y` = 417.43, `position_z` = 112.23 WHERE `id` = 105270 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8497.15, `position_y` = 403.56, `position_z` = 115.72 WHERE `id` = 105270 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -8487.69, `position_y` = 391.55, `position_z` = 115.84 WHERE `id` = 105270 AND `point` = 5;
-- Stormwind Royal Guard 10527 path: it turned around inside the fountain at the top of the keep steps (playtest);
--   it now turns on the keep terrace before the grass bed and the fountain
UPDATE `waypoint_data` SET `position_x` = -8482.5, `position_y` = 385, `position_z` = 115.86 WHERE `id` = 105270 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = -8481.9, `position_y` = 384.3, `position_z` = 115.86 WHERE `id` = 105270 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -8482.5, `position_y` = 385, `position_z` = 115.86 WHERE `id` = 105270 AND `point` = 8;
-- Stormwind Royal Guard 10527 path: same approach from the keep bridge to the lower courtyard; re-z to the CoA floor
UPDATE `waypoint_data` SET `position_x` = -8487.69, `position_y` = 391.55, `position_z` = 115.84 WHERE `id` = 105270 AND `point` = 9;
UPDATE `waypoint_data` SET `position_x` = -8497.15, `position_y` = 403.56, `position_z` = 115.72 WHERE `id` = 105270 AND `point` = 10;
UPDATE `waypoint_data` SET `position_x` = -8508.34, `position_y` = 417.43, `position_z` = 112.23 WHERE `id` = 105270 AND `point` = 11;
UPDATE `waypoint_data` SET `position_x` = -8515.37, `position_y` = 426.32, `position_z` = 106.86 WHERE `id` = 105270 AND `point` = 12;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: hall door (its spawn)
UPDATE `waypoint_data` SET `position_x` = -8408.2, `position_y` = 305.62, `position_z` = 147.01 WHERE `id` = 105280 AND `point` = 1;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: vestibule, left of the central plinth
UPDATE `waypoint_data` SET `position_x` = -8414.96, `position_y` = 295.77, `position_z` = 147.01 WHERE `id` = 105280 AND `point` = 2;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: grand stair, lower flight
UPDATE `waypoint_data` SET `position_x` = -8405.62, `position_y` = 284.03, `position_z` = 149.55 WHERE `id` = 105280 AND `point` = 3;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: grand stair, upper flight
UPDATE `waypoint_data` SET `position_x` = -8398.15, `position_y` = 274.64, `position_z` = 152.55 WHERE `id` = 105280 AND `point` = 4;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: bridge to the throne hall
UPDATE `waypoint_data` SET `position_x` = -8389.89, `position_y` = 265.87, `position_z` = 155.35 WHERE `id` = 105280 AND `point` = 5;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: grand stair, upper flight
UPDATE `waypoint_data` SET `position_x` = -8398.15, `position_y` = 274.64, `position_z` = 152.55 WHERE `id` = 105280 AND `point` = 6;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: grand stair, lower flight
UPDATE `waypoint_data` SET `position_x` = -8405.62, `position_y` = 284.03, `position_z` = 149.55 WHERE `id` = 105280 AND `point` = 7;
-- Stormwind Royal Guard 10528 path: stock patrol: keep hall -> corridor -> ramp to the throne level; CoA equivalent:
--   hall door -> grand stair -> throne hall bridge: vestibule
UPDATE `waypoint_data` SET `position_x` = -8414.96, `position_y` = 295.77, `position_z` = 147.01 WHERE `id` = 105280 AND `point` = 8;
-- Lady Jaina Proudmoore - Script9 - Summon GO Portal to Orgrimmar: quest 13369's reward portal (Jaina's gossip 10189
--   needs 13369 complete; the summon uses target_x/y/z verbatim): Jaina moved to the CoA throne dais but the portal
--   still appeared in the stock throne room, 131 yd from her and under the CoA keep floor; now on the A01Sw_Keep hall
--   floor at the foot of the dais on her side, 8 yd from her and 5.6 yd from her Portal to Undercity 2133395, flat
--   (slope 0.5, headroom 46), the 3.1 yd disc clear of the east wall by 1.2 yd and of guard 10513 by 2.4 yd; the dais
--   in front of her holds the throne party and its steps; stock facing kept
DELETE FROM `smart_scripts` WHERE `entryorguid` = 3234600 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(3234600, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Script9 - Set Npc Flags'),
(3234600, 9, 1, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 21, 20, 0, 0, 0, 0, 0, 0, 0, 'Script9 - Talk'),
(3234600, 9, 2, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 11, 60904, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Script9 - Cast Spell'),
(3234600, 9, 3, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Script9 - Talk'),
(3234600, 9, 4, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 50, 193948, 20, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8374.5, 228.5, 155.323, 0, 'Script9 - Summon GO'),
(3234600, 9, 5, 0, 0, 0, 100, 0, 10000, 10000, 0, 0, 0, 0, 81, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Script9 - Set Npc Flags');
-- Highback Chair: deleted; decorative; its stock west room (4 Inntablesmall round (-8505.8,339.2), floor 120.9) is
--   gone: CoA terrain and keep grounds there; CoA's only 4-table room (war room) takes the war-room chairs
DELETE FROM `gameobject` WHERE `guid` IN (13877, 13878, 13879, 13880, 13898, 13899, 13900, 13901, 13902, 13903, 13908, 13913);
-- Highback Chair: deleted; decorative; its stock east-room table ((-8445.7,386.2), (-8421.2,383.4) or (-8442.7,410.8),
--   floor 120.9) is gone: CoA terrain 115-121 with trees and lamps, no table within 30 yd
DELETE FROM `gameobject` WHERE `guid` IN (13893, 13904, 13905, 13906, 13907, 13911, 13916, 13953);
-- Highback Chair: deleted; reviewed fits row: last chair of the same gone east-room table, alone on open CoA terrain
DELETE FROM `gameobject` WHERE `guid` IN (13917);
-- Wreath: deleted; Winter Veil wreath hung under the stock keep-gate arch (125.6); no CoA surface above it within 8
--   yd, floats 17.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (71497);
-- Banner: deleted; reviewed fits row: Lunar Festival banner hung 6.4 yd under the same stock gate arch (120.0); CoA
--   has nothing above it, floats 8.6 yd over the bridge
DELETE FROM `gameobject` WHERE `guid` IN (29482);
-- Stormwind Royal Guard 10528 path: deleted; stock path had 20 nodes through the buried keep hall; the rewritten path
--   has 8
DELETE FROM `waypoint_data` WHERE `id` = 105280 AND `point` IN (9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);

-- ---------------------------------------------------------------------------
-- 2. The keep's lost east wing: Royal Library, Tyrion's roof garden, Dwarven District
-- ---------------------------------------------------------------------------
-- Tyrion: Tyrion hides in the castle garden (quest 434 "Remain in the garden"); stock garden is now the Northern
--   Elwynn lake 35 yd below; CoA keep roof garden (open-air garden at 156.83 beside the library), SE side facing the
--   library steps, 14 yd from where Lescovar meets Marzon
UPDATE `creature` SET `position_x` = -8330, `position_y` = 279.5, `position_z` = 156.833, `orientation` = 5.864 WHERE `guid` = 43667 AND `id` = 7766;
-- Tyrion's Spybot: Spybot beside Tyrion (npc_tyrion looks for it within 5 yd; 1.6 yd here), same garden spot and
--   facing
UPDATE `creature` SET `position_x` = -8328.6, `position_y` = 280.3, `position_z` = 156.833, `orientation` = 5.864 WHERE `guid` = 45707 AND `id` = 8856;
-- Alicia: Alicia (child, wanders 3 yd) moves with the rest of the stock garden to the CoA keep roof garden (open-air
--   garden at 156.83 beside the library), open north lawn 6 yd inside the rim, clear of trees
UPDATE `creature` SET `position_x` = -8304.5, `position_y` = 290, `position_z` = 156.833, `orientation` = 2.33 WHERE `guid` = 49591 AND `id` = 24729;
-- Stormwind Royal Guard: garden-door royal guard: north side of the steps from the library landing into the CoA roof
--   garden, facing 10524 (quest 434 guard lines fire within 8-10 yd of escort points 5 and 14)
UPDATE `creature` SET `position_x` = -8302.5, `position_y` = 266, `position_z` = 155.347, `orientation` = 3.57 WHERE `guid` = 10523 AND `id` = 1756;
-- Stormwind Royal Guard: garden-door royal guard: south side of the same steps, facing 10523 across the approach lane
UPDATE `creature` SET `position_x` = -8307.3, `position_y` = 263.8, `position_z` = 155.347, `orientation` = 0.43 WHERE `guid` = 10524 AND `id` = 1756;
-- Major Samuelson: Major Samuelson, captain of the guard "in Stormwind Keep" (quest 563 log text); his stock office is
--   under CoA terrain; CoA keep war room (war table 8Sw_Wartable01 at (-8413, 214), floor 155.35), north side of the
--   war table facing it
UPDATE `creature` SET `position_x` = -8407.6, `position_y` = 214.4, `position_z` = 155.347, `orientation` = 3.1416 WHERE `guid` = 16182 AND `id` = 2439;
-- Wilder Thistlenettle: Wilder Thistlenettle: his stock hall is now canal water (CoA terrain 92, water 95.46); nearest
--   dry place is the grassy canal-side knoll of the Dwarven District, 46 yd WNW of his stock spot and the quest
--   167/168 arrow, facing Brohann
UPDATE `creature` SET `position_x` = -8452, `position_y` = 544, `position_z` = 98.854, `orientation` = 5.588 WHERE `guid` = 2435 AND `id` = 656;
-- Brohann Caskbelly: Brohann Caskbelly: same gone hall (canal); stands with Wilder on the canal-side knoll 3.9 yd from
--   him, 29 yd NW of his stock spot and the quest 1448/1469/1475 arrow, facing Wilder
UPDATE `creature` SET `position_x` = -8449, `position_y` = 541.5, `position_z` = 98.854, `orientation` = 2.447 WHERE `guid` = 35221 AND `id` = 5384;
-- 6 rows: stationary battleground emissary stood inside CoA Westfallwagon01.m2; moved 5 yd NE, just clear of the east
--   side of the wagon on open street, 4 yd from its event banner (-8404.05, 577.2) and 5.5 yd from its partner
--   emissary (208109 set)
UPDATE `creature` SET `position_x` = -8406.5, `position_y` = 574, `position_z` = 91.764, `orientation` = 3.9968 WHERE `guid` = 208115 AND `id` = 34950;
UPDATE `creature` SET `position_x` = -8406.5, `position_y` = 574, `position_z` = 91.764, `orientation` = 3.9968 WHERE `guid` = 208128 AND `id` = 30566;
UPDATE `creature` SET `position_x` = -8406.5, `position_y` = 574, `position_z` = 91.764, `orientation` = 3.9968 WHERE `guid` = 208141 AND `id` = 15103;
UPDATE `creature` SET `position_x` = -8406.5, `position_y` = 574, `position_z` = 91.764, `orientation` = 3.9968 WHERE `guid` = 208154 AND `id` = 14991;
UPDATE `creature` SET `position_x` = -8406.5, `position_y` = 574, `position_z` = 91.764, `orientation` = 3.9968 WHERE `guid` = 208167 AND `id` = 22013;
UPDATE `creature` SET `position_x` = -8406.5, `position_y` = 574, `position_z` = 91.764, `orientation` = 3.9968 WHERE `guid` = 208180 AND `id` = 15102;
-- Sewer Beast: Sewer Beast (aquatic canal rare, pool 86300): stock canal bed 85.89; the CoA canal is shallower (bed
--   92.71, water 95.46); same spot on the CoA canal bed
UPDATE `creature` SET `position_x` = -8560.69, `position_y` = 486.619, `position_z` = 92.708, `orientation` = 2.294 WHERE `guid` = 86300 AND `id` = 3581;
-- Sewer Beast: Sewer Beast (pool 86300): same canal, CoA bed 92.48 under water 95.46
UPDATE `creature` SET `position_x` = -8479.08, `position_y` = 709.373, `position_z` = 92.478, `orientation` = 3.7941 WHERE `guid` = 300492 AND `id` = 3581;
-- Mailbox: mailbox (functional) was sunk into a beam of CoA Logmachine02.m2; moved 3.2 yd NE to the open street corner
--   just east of the log machine, same facing
UPDATE `gameobject` SET `position_x` = -8422, `position_y` = 597, `position_z` = 94.184, `orientation` = 3.1416 WHERE `guid` = 150738 AND `id` = 195607;
-- Food Crate: lootable Food Crate: CoA put Westfallwagon01.m2 on its spot; set on the wagon bed (93.04) at the same
--   x,y
UPDATE `gameobject` SET `position_x` = -8407, `position_y` = 580.736, `position_z` = 93.037, `orientation` = -2 WHERE `guid` = 12686 AND `id` = 3662;
-- Barrel of Milk: lootable Barrel of Milk was inside the wagon rim; moved 2.5 yd onto the open part of the
--   Westfallwagon01 bed beside the Food Crate
UPDATE `gameobject` SET `position_x` = -8407.2, `position_y` = 579.4, `position_z` = 93.037, `orientation` = -1.7977 WHERE `guid` = 33834 AND `id` = 3705;
-- Barrel of Milk: lootable Barrel of Milk: same street spot, the CoA Dwarven District floor is 0.94 yd lower (92.23)
UPDATE `gameobject` SET `position_x` = -8403, `position_y` = 583.113, `position_z` = 92.225, `orientation` = -2 WHERE `guid` = 12828 AND `id` = 3705;
-- Old Town: pointer arm "Old Town"; CoA replaced the stock Woodsignpostnice01 at (-8507.625, 658.824, top 106.859,
--   scale 1.34) with Humansignpost03 at (-8508.170, 663.804, top 105.784); the arm set moves by the post offset in x,y
--   and by the post-top difference in z, orientation kept (same method as stormwind-mage-park)
UPDATE `gameobject` SET `position_x` = -8509.175, `position_y` = 662.995, `position_z` = 99.09, `orientation` = 2.2874 WHERE `guid` = 10693 AND `id` = 2112;
-- Cathedral Square: pointer arm "Cathedral Square"; CoA replaced the stock Woodsignpostnice01 at (-8507.625, 658.824,
--   top 106.859, scale 1.34) with Humansignpost03 at (-8508.170, 663.804, top 105.784); the arm set moves by the post
--   offset in x,y and by the post-top difference in z, orientation kept (same method as stormwind-mage-park)
UPDATE `gameobject` SET `position_x` = -8508.905, `position_y` = 664.876, `position_z` = 98.889, `orientation` = 0.6021 WHERE `guid` = 10674 AND `id` = 2131;
-- Dwarven District: pointer arm "Dwarven District" (fits-class row added so the whole arm set moves together); CoA
--   replaced the stock Woodsignpostnice01 at (-8507.625, 658.824, top 106.859, scale 1.34) with Humansignpost03 at
--   (-8508.170, 663.804, top 105.784); the arm set moves by the post offset in x,y and by the post-top difference in
--   z, orientation kept (same method as stormwind-mage-park)
UPDATE `gameobject` SET `position_x` = -8507.435, `position_y` = 662.73, `position_z` = 98.99, `orientation` = -2.5394 WHERE `guid` = 30834 AND `id` = 28030;
-- Floating, Medium - MFF: Midsummer floating wreath: CoA moved the canal bank; the stock spot is planter/terrain 3.4
--   yd above it; moved 6 yd to the nearest open canal water, at the stock float height (water 95.46)
UPDATE `gameobject` SET `position_x` = -8523.5, `position_y` = 659.5, `position_z` = 95.474, `orientation` = 2.3562 WHERE `guid` = 51096 AND `id` = 181354;
-- Floating, Medium - MFF: Midsummer floating wreath: the stock spot is now dry ground (terrain 100.3); moved 4.7 yd to
--   the nearest open canal water at the stock float height
UPDATE `gameobject` SET `position_x` = -8510.5, `position_y` = 670, `position_z` = 95.474, `orientation` = 1.9548 WHERE `guid` = 51139 AND `id` = 181354;
-- Milton Sheaf: Milton Sheaf, head librarian of "the Royal Library, within Stormwind Keep" (quest 343); same spot in
--   the room: CoA Royal Library = stock library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall,
--   6 Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `creature` SET `position_x` = -8279.309, `position_y` = 226.965, `position_z` = 155.447, `orientation` = 2.242 WHERE `guid` = 8704 AND `id` = 1440;
-- Donyal Tovald: Donyal Tovald, librarian; same spot in the room: CoA Royal Library = stock library room translated by
--   (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01
--   match to 0.01 yd with unchanged rotations
UPDATE `creature` SET `position_x` = -8280.309, `position_y` = 261.237, `position_z` = 155.447, `orientation` = 0.634 WHERE `guid` = 16365 AND `id` = 2504;
-- Lord Gregor Lescovar: Lord Gregor Lescovar waits in the library for the spybot (quest 434); start of his re-authored
--   escort; same spot in the room: CoA Royal Library = stock library room translated by (+66.691, -156.963, +33.073):
--   its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged
--   rotations
UPDATE `creature` SET `position_x` = -8267.309, `position_y` = 237.759, `position_z` = 155.447, `orientation` = 2.596 WHERE `guid` = 10502 AND `id` = 1754;
-- Stormwind Royal Guard: royal guard at the library door; same spot in the room: CoA Royal Library = stock library
--   room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and 8
--   Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `creature` SET `position_x` = -8296.309, `position_y` = 250.959, `position_z` = 155.447, `orientation` = 5.43 WHERE `guid` = 10525 AND `id` = 1756;
UPDATE `creature` SET `position_x` = -8288.309, `position_y` = 257.383, `position_z` = 155.447, `orientation` = 5.35 WHERE `guid` = 10526 AND `id` = 1756;
-- Civil War in the Plaguelands: readable book (floor by the SW table); same spot in the room: CoA Royal Library =
--   stock library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11
--   Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8304.309, `position_y` = 238.352, `position_z` = 155.347, `orientation` = 1.187 WHERE `guid` = 18610 AND `id` = 175761;
-- The Guardians of Tirisfal, The Alliance of Lordaeron, Aftermath of the Second War: readable book on the SW reading
--   table; same spot in the room: CoA Royal Library = stock library room translated by (+66.691, -156.963, +33.073):
--   its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged
--   rotations
UPDATE `gameobject` SET `position_x` = -8300.309, `position_y` = 244.922, `position_z` = 156.5, `orientation` = 2.286 WHERE `guid` = 18556 AND `id` = 175735;
UPDATE `gameobject` SET `position_x` = -8300.309, `position_y` = 243.569, `position_z` = 156.465, `orientation` = -1 WHERE `guid` = 18582 AND `id` = 175746;
UPDATE `gameobject` SET `position_x` = -8299.309, `position_y` = 244.016, `position_z` = 156.479, `orientation` = 0.209 WHERE `guid` = 13676 AND `id` = 21581;
-- The New Horde: readable book on the WMO ledge by the south door; same spot in the room: CoA Royal Library = stock
--   library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and
--   8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8299.309, `position_y` = 250.852, `position_z` = 157.552, `orientation` = -2 WHERE `guid` = 18594 AND `id` = 175752;
-- The Kaldorei and the Well of Eternity: readable book on the WMO ledge by the north shelves; same spot in the room:
--   CoA Royal Library = stock library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6
--   Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8274.839, `position_y` = 258.235, `position_z` = 157.552, `orientation` = -1.7802 WHERE `guid` = 13680 AND `id` = 21583;
-- Legends of the Earth: questgiver-type book on the inner Abbeyshelf02 shelf; same spot in the room: CoA Royal Library
--   = stock library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11
--   Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8274.309, `position_y` = 241.589, `position_z` = 157.403, `orientation` = -3 WHERE `guid` = 12007 AND `id` = 2657;
-- Draconic for Dummies: questgiver-type book stack on the WMO ledge by the north shelves; same spot in the room: CoA
--   Royal Library = stock library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6
--   Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8273.509, `position_y` = 256.787, `position_z` = 157.563, `orientation` = 2.8274 WHERE `guid` = 268645 AND `id` = 180665;
-- Beyond the Dark Portal: readable book on the NE reading table; same spot in the room: CoA Royal Library = stock
--   library room translated by (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and
--   8 Candelabratallwall01 match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8265.309, `position_y` = 240.589, `position_z` = 156.514, `orientation` = -1 WHERE `guid` = 13678 AND `id` = 21582;
-- Highback Chair: library reading chair; same spot in the room: CoA Royal Library = stock library room translated by
--   (+66.691, -156.963, +33.073): its 2 Inntablesmall, 6 Abbeyshelf02, 11 Abbeyshelf01 and 8 Candelabratallwall01
--   match to 0.01 yd with unchanged rotations
UPDATE `gameobject` SET `position_x` = -8300.989, `position_y` = 245.407, `position_z` = 155.5, `orientation` = 5.3843 WHERE `guid` = 13868 AND `id` = 24522;
UPDATE `gameobject` SET `position_x` = -8265.169, `position_y` = 241.756, `position_z` = 155.5, `orientation` = 3.8136 WHERE `guid` = 13869 AND `id` = 24523;
UPDATE `gameobject` SET `position_x` = -8267.399, `position_y` = 242.051, `position_z` = 155.5, `orientation` = 5.3843 WHERE `guid` = 13870 AND `id` = 24524;
UPDATE `gameobject` SET `position_x` = -8272.029, `position_y` = 244.086, `position_z` = 155.476, `orientation` = 0.672 WHERE `guid` = 13871 AND `id` = 24527;
UPDATE `gameobject` SET `position_x` = -8279.109, `position_y` = 252.936, `position_z` = 155.476, `orientation` = 0.672 WHERE `guid` = 13872 AND `id` = 24558;
UPDATE `gameobject` SET `position_x` = -8287.299, `position_y` = 231.814, `position_z` = 155.476, `orientation` = 3.8136 WHERE `guid` = 13873 AND `id` = 24559;
UPDATE `gameobject` SET `position_x` = -8294.369, `position_y` = 240.763, `position_z` = 155.476, `orientation` = 3.8136 WHERE `guid` = 13874 AND `id` = 24560;
UPDATE `gameobject` SET `position_x` = -8300.999, `position_y` = 243.212, `position_z` = 155.5, `orientation` = 0.672 WHERE `guid` = 13875 AND `id` = 24561;
UPDATE `gameobject` SET `position_x` = -8265.399, `position_y` = 239.36, `position_z` = 155.5, `orientation` = 2.2428 WHERE `guid` = 13876 AND `id` = 24526;
-- War of the Three Hammers: readable dwarven history book from the gone dwarven hall (now canal); its natural home is
--   the library: free east corner of the NE reading table (CoA Royal Library)
UPDATE `gameobject` SET `position_x` = -8266, `position_y` = 239.8, `position_z` = 156.5, `orientation` = 0 WHERE `guid` = 18564 AND `id` = 175739;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; start beside Tyrion in the CoA roof garden (pause: disguise; Tyrion within
--   10 yd)
UPDATE `script_waypoint` SET `location_x` = -8328.2, `location_y` = 279.2, `location_z` = 156.833 WHERE `entry` = 8856 AND `pointid` = 1;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; garden lawn
UPDATE `script_waypoint` SET `location_x` = -8323, `location_y` = 279.8, `location_z` = 156.833 WHERE `entry` = 8856 AND `pointid` = 2;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; garden lawn, north of the canopy04 bush
UPDATE `script_waypoint` SET `location_x` = -8316, `location_y` = 278.5, `location_z` = 156.833 WHERE `entry` = 8856 AND `pointid` = 3;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; top of the garden steps
UPDATE `script_waypoint` SET `location_x` = -8305.5, `location_y` = 270.2, `location_z` = 157.014 WHERE `entry` = 8856 AND `pointid` = 4;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; between the garden-door guards (pause: guard answers)
UPDATE `script_waypoint` SET `location_x` = -8305, `location_y` = 265.3, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 5;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; landing between the garden steps and the library door
UPDATE `script_waypoint` SET `location_x` = -8303.5, `location_y` = 264, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 6;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; landing
UPDATE `script_waypoint` SET `location_x` = -8302, `location_y` = 262.8, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 7;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; landing, north of the stairwell
UPDATE `script_waypoint` SET `location_x` = -8300.5, `location_y` = 261.7, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 8;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; landing
UPDATE `script_waypoint` SET `location_x` = -8299, `location_y` = 260.6, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 9;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; landing, before the library door
UPDATE `script_waypoint` SET `location_x` = -8297.6, `location_y` = 259.5, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 10;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; library door: stock point 11 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8296.149, `location_y` = 258.446, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 11;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; library: stock point 12 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8293.249, `location_y` = 253.957, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 12;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; library: stock point 13 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8295.059, `location_y` = 245.889, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 13;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; library: stock point 14 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8297.599, `location_y` = 238.354, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 14;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; library: stock point 15 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8289.959, `location_y` = 228.284, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 15;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; library: stock point 16 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8286.299, `location_y` = 222.969, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 16;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; before Lescovar (pause: talks, Lescovar within 10 yd): stock point 17
--   through the library translation
UPDATE `script_waypoint` SET `location_x` = -8268.889, `location_y` = 236.556, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 17;
-- Tyrion's Spybot escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids kept
--   for the zone_stormwind_city.cpp pauses; at Lescovar: stock point 18 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8268.199, `location_y` = 237.167, `location_z` = 155.347 WHERE `entry` = 8856 AND `pointid` = 18;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; beside his spawn: stock point 1 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8268.199, `location_y` = 237.167, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 1;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library: stock point 2 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8268.889, `location_y` = 236.556, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 2;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library: stock point 3 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8286.299, `location_y` = 222.969, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 3;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library: stock point 4 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8289.959, `location_y` = 228.284, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 4;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library: stock point 5 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8297.599, `location_y` = 238.354, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 5;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library: stock point 6 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8295.059, `location_y` = 245.889, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 6;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library: stock point 7 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8293.249, `location_y` = 253.957, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 7;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; library door: stock point 8 through the library translation
UPDATE `script_waypoint` SET `location_x` = -8296.149, `location_y` = 258.446, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 8;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; landing between the library door and the garden steps
UPDATE `script_waypoint` SET `location_x` = -8297.6, `location_y` = 259.5, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 9;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; landing
UPDATE `script_waypoint` SET `location_x` = -8299, `location_y` = 260.6, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 10;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; landing, north of the stairwell
UPDATE `script_waypoint` SET `location_x` = -8300.5, `location_y` = 261.7, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 11;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; landing
UPDATE `script_waypoint` SET `location_x` = -8302, `location_y` = 262.8, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 12;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; approach to the garden steps
UPDATE `script_waypoint` SET `location_x` = -8303.5, `location_y` = 264, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 13;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; between the garden-door guards (pause: dismisses them, 8 yd)
UPDATE `script_waypoint` SET `location_x` = -8305, `location_y` = 265.3, `location_z` = 155.347 WHERE `entry` = 1754 AND `pointid` = 14;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; top of the garden steps
UPDATE `script_waypoint` SET `location_x` = -8305.5, `location_y` = 270.2, `location_z` = 157.014 WHERE `entry` = 1754 AND `pointid` = 15;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; garden lawn (pause: Marzon summoned)
UPDATE `script_waypoint` SET `location_x` = -8311.5, `location_y` = 277, `location_z` = 156.833 WHERE `entry` = 1754 AND `pointid` = 16;
-- Lord Gregor Lescovar escort point: quest 434 escort re-authored for the CoA keep (library to roof garden); point ids
--   kept for the zone_stormwind_city.cpp pauses; meeting point on the garden lawn, 14 yd from Tyrion
UPDATE `script_waypoint` SET `location_x` = -8316.5, `location_y` = 283.5, `location_z` = 156.833 WHERE `entry` = 1754 AND `pointid` = 17;
-- 6 rows: turnaround node was inside CoA Human_Wagon02_Open.m2 (surface 96.78 over it); moved 4.7 yd south onto open
--   street between that wagon and the Stormwindplanter03, reachable around the CoA gypsy wagon
UPDATE `waypoint_data` SET `position_x` = -8356.5, `position_y` = 626.5, `position_z` = 95.286 WHERE `id` = 2081100 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8356.5, `position_y` = 626.5, `position_z` = 95.286 WHERE `id` = 2081230 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8356.5, `position_y` = 626.5, `position_z` = 95.286 WHERE `id` = 2081360 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8356.5, `position_y` = 626.5, `position_z` = 95.286 WHERE `id` = 2081490 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8356.5, `position_y` = 626.5, `position_z` = 95.286 WHERE `id` = 2081620 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8356.5, `position_y` = 626.5, `position_z` = 95.286 WHERE `id` = 2081750 AND `point` = 14;
-- Deeprun Tram - Stormwind Instance: CoA AreaTrigger.dbc 2173 is at (-8354.28, 511.262, 88.1225) r 10 in the rebuilt
--   tram stairwell; the DB row is 8.8 yd off and 8.5 yd higher, so the client trigger fails the server check
UPDATE `areatrigger` SET `x` = -8354.28, `y` = 511.262, `z` = 88.1225 WHERE `entry` = 2173;
-- PVP HOLIDAY GENERIC SIGNPOST: Call to Arms signpost in the Dwarven District: same spot on the street, CoA terrain
--   91.50 replaced the stock floor 91.98; z keeps its stock 0.09 yd offset
UPDATE `gameobject` SET `position_x` = -8404.29, `position_y` = 577.574, `position_z` = 91.594, `orientation` = 5.28835 WHERE `guid` = 6618 AND `id` = 180397;
-- 4 rows: Call to Arms banner at the signpost 6618 in the Dwarven District: same spot, z on the CoA terrain 91.57
--   (stock floor 91.98)
UPDATE `gameobject` SET `position_x` = -8404.05, `position_y` = 577.197, `position_z` = 91.567, `orientation` = -0.994837 WHERE `guid` = 151601 AND `id` = 195532;
UPDATE `gameobject` SET `position_x` = -8404.05, `position_y` = 577.197, `position_z` = 91.567, `orientation` = -0.994837 WHERE `guid` = 151606 AND `id` = 192686;
UPDATE `gameobject` SET `position_x` = -8404.05, `position_y` = 577.197, `position_z` = 91.567, `orientation` = -0.994837 WHERE `guid` = 151616 AND `id` = 180398;
UPDATE `gameobject` SET `position_x` = -8404.05, `position_y` = 577.197, `position_z` = 91.567, `orientation` = -0.994837 WHERE `guid` = 151626 AND `id` = 180400;
-- Deeprun Tram - Stormwind Instance (Inside): Deeprun Tram exit: the stock landing is the old walkway, now 0.3 yd
--   under the roof of CoA's tram tunnel (floor 84.41, roof 92.1) beside its side wall; the stock landing projected
--   onto the tunnel centre line, on the A01Sw_Dwarvendistrict floor 84.409 with walls 4.8-7.6 yd each side and
--   headroom 9.5, 26 yd from the entrance trigger 2173 (radius 10) straight behind, facing out along the tunnel as in
--   stock
UPDATE `areatrigger_teleport` SET `target_position_x` = -8370.3, `target_position_y` = 531.4, `target_position_z` = 84.409 WHERE `ID` = 2171;
-- PVP HOLIDAY ALLIANCE AV, Draenei Banner: Call to Arms banner at the signpost 6618 in the Dwarven District: same
--   spot, z on the CoA terrain 91.57 (stock floor 91.98)
UPDATE `gameobject` SET `position_x` = -8404.05, `position_y` = 577.197, `position_z` = 91.567, `orientation` = -0.994837 WHERE `guid` = 151611 AND `id` = 180399;
UPDATE `gameobject` SET `position_x` = -8404.05, `position_y` = 577.197, `position_z` = 91.567, `orientation` = -0.994837 WHERE `guid` = 151621 AND `id` = 185107;
-- Sprite Jumpsprocket: same spot, z on the corrected CoA terrain with the stock 0.08 offset (floated 0.38)
UPDATE `creature` SET `position_x` = -8350, `position_y` = 647.613, `position_z` = 95.581, `orientation` = 4.276 WHERE `guid` = 48358 AND `id` = 11026;
-- Highback Chair: deleted; decorative chair of Major Samuelson's stock office, buried 2.5 yd under CoA terrain; the
--   office is gone and the CoA war room has no seating table
DELETE FROM `gameobject` WHERE `guid` IN (13909, 13910, 13912);
-- Stone Bench: deleted; decorative stone bench of Tyrion's stock garden: the garden floor (123.76) is gone, now lake
--   and rocks 4-37 yd below; the CoA roof garden is a planted design without bench spots
DELETE FROM `gameobject` WHERE `guid` IN (13851, 13857, 13858, 13859, 13860, 13861, 13862, 13863, 13866, 13867);
-- Wooden Chair: deleted; decorative chair of the gone dwarven hall at (-8460, 495) (floors 99.8/107.0); CoA replaced
--   the hall with canal water (terrain 92, water 95.46), no model left within 10 yd; no NPC sits on it
DELETE FROM `gameobject` WHERE `guid` IN (11100, 11101, 11102, 11103, 11104, 11105, 11106, 11107, 11108, 11109, 11110, 11111, 11112, 11113, 11114, 11115, 11116, 11117, 11118, 11119, 11127, 11128, 11129, 11130, 11131);
-- 16 rows: deleted; holiday decoration inside the gone dwarven hall (tree, stockings, light strings, hero portrait at
--   99.8-111.5); the hall is canal water in CoA, nothing to stand on or hang from
DELETE FROM `gameobject` WHERE `guid` IN (297, 3162, 3163, 3170, 3175, 1878, 1879, 1880, 1881, 1882, 29472, 29479, 29517, 31165, 31172, 907);
-- Highback Chair, Stone Bench, Wooden Chair: deleted; decorative seat of the stock raised terrace at (-8320, 565)
--   (floor 99.6); CoA replaced it with the sloping Northern Elwynn wood (terrain 95-106); the seats float up to 2.7 yd
--   or are buried up to 3 yd; no NPC sits on it
DELETE FROM `gameobject` WHERE `guid` IN (13918, 13919, 13922, 13924, 13925, 13930, 13931, 13932, 13933, 13955, 13956, 13957, 13959, 13960, 13961);
-- Hanging, Square, Medium - MFF: deleted; Midsummer hanging ribbon: its stock support (surface 111.53, 0.8 yd above)
--   is gone and at its height it is enclosed 8/8 by CoA A01Sw_Dwarvendistrict geometry (walls 0.01 yd)
DELETE FROM `gameobject` WHERE `guid` IN (53011);
-- King Llane I of the House of Wrynn, Lady Mara Fordragon, Grand Admiral Daelin Proudmoore: deleted; readable plaque
--   (PlaqueBronze02) at the base of a stock hall statue (King Llane / Lady Mara / Daelin); CoA moved that hall rigidly
--   to the House of Nobles (its 8 Candelabratallwall01 match at translation +15.50, -232.56, +4.65) but removed the
--   three statues (no Statuehm* model anywhere in CoA Stormwind), so the plaques would name nothing
DELETE FROM `gameobject` WHERE `guid` IN (20458, 20459, 31619);
-- Stone Bench: deleted; decorative seat of the stock raised terrace at (-8320, 565) (floor 99.6); CoA replaced it with
--   the sloping Northern Elwynn wood (terrain 95-106); the seats float up to 2.7 yd or are buried up to 3 yd; no NPC
--   sits on it (left undecided by the pre-fix survey; floats 1.02 yd over the corrected CoA terrain)
DELETE FROM `gameobject` WHERE `guid` IN (13929);
-- Stone Bench: deleted; decorative seat of the stock raised terrace at (-8320, 565) (floor 99.6); CoA replaced it with
--   the sloping Northern Elwynn wood (terrain 95-106); the seats float up to 2.7 yd or are buried up to 3 yd; no NPC
--   sits on it (left undecided by the pre-fix survey; floats 0.56 yd over the corrected CoA terrain)
DELETE FROM `gameobject` WHERE `guid` IN (13926);
-- Wooden Chair: deleted; decorative seat of the stock raised terrace at (-8320, 565) (floor 99.6); CoA replaced it
--   with the sloping Northern Elwynn wood (terrain 95-106); the seats float up to 2.7 yd or are buried up to 3 yd; no
--   NPC sits on it (left undecided by the pre-fix survey; floats 0.49 yd over the corrected CoA terrain)
DELETE FROM `gameobject` WHERE `guid` IN (13962);

-- ---------------------------------------------------------------------------
-- 3. Old Town: SI:7, Command Center, Pig and Whistle, barracks, Cathedral
-- ---------------------------------------------------------------------------
-- 10 rows: Pig and Whistle moved as a rigid piece in CoA: translation (-1.744, +15.053, 0) fitted on 41 matched
--   furniture doodads, residual 0.002 yd; same floor
UPDATE `creature` SET `position_x` = -8606.21, `position_y` = 404.15, `position_z` = 103.025, `orientation` = 5.6723 WHERE `guid` = 79750 AND `id` = 6090;
UPDATE `creature` SET `position_x` = -8607.74, `position_y` = 398.98, `position_z` = 102.924, `orientation` = 3.7917 WHERE `guid` = 79751 AND `id` = 1327;
UPDATE `creature` SET `position_x` = -8607.71, `position_y` = 403.46, `position_z` = 103.025, `orientation` = 5.4105 WHERE `guid` = 79752 AND `id` = 1478;
UPDATE `creature` SET `position_x` = -8609.23, `position_y` = 402.38, `position_z` = 102.926, `orientation` = 5.3931 WHERE `guid` = 79753 AND `id` = 1477;
UPDATE `creature` SET `position_x` = -8607.89, `position_y` = 391.97, `position_z` = 110.28, `orientation` = 4.5553 WHERE `guid` = 79754 AND `id` = 340;
UPDATE `creature` SET `position_x` = -8612.64, `position_y` = 379.69, `position_z` = 99.706, `orientation` = 0.7854 WHERE `guid` = 79755 AND `id` = 5482;
UPDATE `creature` SET `position_x` = -8610.1, `position_y` = 373.55, `position_z` = 99.706, `orientation` = 0.0698 WHERE `guid` = 79756 AND `id` = 5483;
UPDATE `creature` SET `position_x` = -8614.49, `position_y` = 397.82, `position_z` = 103.011, `orientation` = 1.2217 WHERE `guid` = 79773 AND `id` = 6089;
UPDATE `creature` SET `position_x` = -8612.52, `position_y` = 395.19, `position_z` = 103.013, `orientation` = 2.234 WHERE `guid` = 79775 AND `id` = 3629;
UPDATE `creature` SET `position_x` = -8626.58, `position_y` = 409.19, `position_z` = 102.925, `orientation` = 2.1625 WHERE `guid` = 79776 AND `id` = 1328;
-- Rat: Pig and Whistle moved as a rigid piece in CoA: translation (-1.744, +15.053, 0) fitted on 41 matched furniture
--   doodads, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `creature` SET `position_x` = -8613.56, `position_y` = 382.85, `position_z` = 92.136, `orientation` = 4.6836 WHERE `guid` = 79777 AND `id` = 4075;
UPDATE `creature` SET `position_x` = -8608.96, `position_y` = 379.11, `position_z` = 92.136, `orientation` = 1.5 WHERE `guid` = 79757 AND `id` = 4075;
-- 23 rows: Pig and Whistle moved as a rigid piece in CoA: translation (-1.744, +15.053, 0) fitted on 41 matched
--   furniture doodads, residual 0.002 yd; same floor
UPDATE `gameobject` SET `position_x` = -8610.49, `position_y` = 397.68, `position_z` = 113.878, `orientation` = 2.2166 WHERE `guid` = 1884 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -8610.49, `position_y` = 397.68, `position_z` = 113.878, `orientation` = 2.2166 WHERE `guid` = 19689 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8606.68, `position_y` = 401.76, `position_z` = 109.104, `orientation` = 2.1642 WHERE `guid` = 3164 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -8611.55, `position_y` = 397.89, `position_z` = 109.131, `orientation` = 2.1467 WHERE `guid` = 3165 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -8607.68, `position_y` = 400.97, `position_z` = 109.113, `orientation` = 2.234 WHERE `guid` = 3171 AND `id` = 178435;
UPDATE `gameobject` SET `position_x` = -8613.99, `position_y` = 395.95, `position_z` = 109.1, `orientation` = 2.1293 WHERE `guid` = 3172 AND `id` = 178435;
UPDATE `gameobject` SET `position_x` = -8612.73, `position_y` = 396.95, `position_z` = 109.13, `orientation` = 2.1642 WHERE `guid` = 3176 AND `id` = 178436;
UPDATE `gameobject` SET `position_x` = -8603.32, `position_y` = 407.4, `position_z` = 102.929, `orientation` = 2.2253 WHERE `guid` = 26493 AND `id` = 103802;
UPDATE `gameobject` SET `position_x` = -8601.27, `position_y` = 395.36, `position_z` = 110.184, `orientation` = 3.7612 WHERE `guid` = 26494 AND `id` = 10223;
UPDATE `gameobject` SET `position_x` = -8605.21, `position_y` = 410.01, `position_z` = 102.929, `orientation` = 5.3669 WHERE `guid` = 26497 AND `id` = 10201;
UPDATE `gameobject` SET `position_x` = -8605.72, `position_y` = 407.63, `position_z` = 102.929, `orientation` = 0.6196 WHERE `guid` = 26498 AND `id` = 10209;
UPDATE `gameobject` SET `position_x` = -8598.37, `position_y` = 398.55, `position_z` = 110.184, `orientation` = 0.6196 WHERE `guid` = 26499 AND `id` = 17258;
UPDATE `gameobject` SET `position_x` = -8615.73, `position_y` = 404.74, `position_z` = 102.929, `orientation` = 2.1904 WHERE `guid` = 26504 AND `id` = 17281;
UPDATE `gameobject` SET `position_x` = -8598.2, `position_y` = 401.42, `position_z` = 110.184, `orientation` = 5.3669 WHERE `guid` = 26505 AND `id` = 10218;
UPDATE `gameobject` SET `position_x` = -8604.3, `position_y` = 393.06, `position_z` = 110.184, `orientation` = 0.6196 WHERE `guid` = 26506 AND `id` = 10194;
UPDATE `gameobject` SET `position_x` = -8603.79, `position_y` = 395.62, `position_z` = 110.184, `orientation` = 5.3669 WHERE `guid` = 26507 AND `id` = 10216;
UPDATE `gameobject` SET `position_x` = -8610.15, `position_y` = 388.22, `position_z` = 110.184, `orientation` = 0.6196 WHERE `guid` = 26514 AND `id` = 17276;
UPDATE `gameobject` SET `position_x` = -8607.33, `position_y` = 390.45, `position_z` = 110.184, `orientation` = 3.7612 WHERE `guid` = 26515 AND `id` = 17274;
UPDATE `gameobject` SET `position_x` = -8614.13, `position_y` = 386.37, `position_z` = 110.184, `orientation` = 3.7612 WHERE `guid` = 26555 AND `id` = 17266;
UPDATE `gameobject` SET `position_x` = -8616.59, `position_y` = 386.65, `position_z` = 110.184, `orientation` = 5.3669 WHERE `guid` = 26556 AND `id` = 17275;
UPDATE `gameobject` SET `position_x` = -8609.91, `position_y` = 390.86, `position_z` = 110.184, `orientation` = 5.3669 WHERE `guid` = 26557 AND `id` = 17249;
UPDATE `gameobject` SET `position_x` = -8606.28, `position_y` = 372.77, `position_z` = 100.129, `orientation` = 4.6164 WHERE `guid` = 26512 AND `id` = 24763;
UPDATE `gameobject` SET `position_x` = -8606.02, `position_y` = 373.44, `position_z` = 100.129, `orientation` = 1.4399 WHERE `guid` = 26516 AND `id` = 24764;
-- Wooden Chair: Pig and Whistle moved as a rigid piece in CoA: translation (-1.744, +15.053, 0) fitted on 41 matched
--   furniture doodads, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `gameobject` SET `position_x` = -8616.52, `position_y` = 409.22, `position_z` = 102.929, `orientation` = 3.8136 WHERE `guid` = 26485 AND `id` = 24479;
UPDATE `gameobject` SET `position_x` = -8618.66, `position_y` = 405.03, `position_z` = 102.929, `orientation` = 0.672 WHERE `guid` = 26486 AND `id` = 24627;
UPDATE `gameobject` SET `position_x` = -8619.83, `position_y` = 406.64, `position_z` = 102.929, `orientation` = 0.672 WHERE `guid` = 26496 AND `id` = 17255;
UPDATE `gameobject` SET `position_x` = -8619.36, `position_y` = 409.31, `position_z` = 102.929, `orientation` = 5.3494 WHERE `guid` = 26500 AND `id` = 17252;
UPDATE `gameobject` SET `position_x` = -8615.34, `position_y` = 407.76, `position_z` = 102.929, `orientation` = 3.8136 WHERE `guid` = 26508 AND `id` = 24600;
-- 19 rows: stock SI:7 rebuilt as A01Sw_Oldtown_Si7: rigid transform rot +104.8 deg fitted on 38 matched doodads (mean
--   residual 0.06 yd), floors 1.15 yd lower
UPDATE `creature` SET `position_x` = -8710.52, `position_y` = 326.12, `position_z` = 94.058, `orientation` = 4.4664 WHERE `guid` = 79781 AND `id` = 7208;
UPDATE `creature` SET `position_x` = -8704.83, `position_y` = 326.9, `position_z` = 94.058, `orientation` = 4.9882 WHERE `guid` = 79782 AND `id` = 7207;
UPDATE `creature` SET `position_x` = -8730.71, `position_y` = 305.21, `position_z` = 108.463, `orientation` = 0.8169 WHERE `guid` = 79783 AND `id` = 6946;
UPDATE `creature` SET `position_x` = -8725.95, `position_y` = 309.93, `position_z` = 99.529, `orientation` = 0.1711 WHERE `guid` = 79784 AND `id` = 1326;
UPDATE `creature` SET `position_x` = -8700.67, `position_y` = 325.93, `position_z` = 101.195, `orientation` = 3.3127 WHERE `guid` = 79786 AND `id` = 1325;
UPDATE `creature` SET `position_x` = -8704.95, `position_y` = 342.76, `position_z` = 102.029, `orientation` = 4.8486 WHERE `guid` = 79787 AND `id` = 13283;
UPDATE `gameobject` SET `position_x` = -8724.63, `position_y` = 314.69, `position_z` = 99.57, `orientation` = 4.8224, `rotation2` = 0.667162, `rotation3` = -0.744912 WHERE `guid` = 26569 AND `id` = 176242;
UPDATE `gameobject` SET `position_x` = -8723.74, `position_y` = 306.48, `position_z` = 99.57, `orientation` = 1.7245, `rotation2` = 0.759309, `rotation3` = 0.650731 WHERE `guid` = 26570 AND `id` = 176243;
UPDATE `gameobject` SET `position_x` = -8712.45, `position_y` = 325.1, `position_z` = 93.958, `orientation` = 0.1362, `rotation2` = 0.068047, `rotation3` = 0.997682 WHERE `guid` = 26571 AND `id` = 124374;
UPDATE `gameobject` SET `position_x` = -8705.71, `position_y` = 338.12, `position_z` = 108.332, `orientation` = 0.1624, `rotation2` = 0.081111, `rotation3` = 0.996705 WHERE `guid` = 26574 AND `id` = 176232;
UPDATE `gameobject` SET `position_x` = -8703.57, `position_y` = 336.71, `position_z` = 108.332, `orientation` = 1.7856, `rotation2` = 0.778831, `rotation3` = 0.627234 WHERE `guid` = 26576 AND `id` = 176233;
UPDATE `gameobject` SET `position_x` = -8704.28, `position_y` = 340.4, `position_z` = 108.332, `orientation` = 4.9271, `rotation2` = 0.62727, `rotation3` = -0.778802 WHERE `guid` = 26577 AND `id` = 176234;
UPDATE `gameobject` SET `position_x` = -8702.26, `position_y` = 340.65, `position_z` = 108.332, `orientation` = 4.9271, `rotation2` = 0.62727, `rotation3` = -0.778802 WHERE `guid` = 26578 AND `id` = 176235;
UPDATE `gameobject` SET `position_x` = -8700.27, `position_y` = 339.1, `position_z` = 108.332, `orientation` = 2.4226, `rotation2` = 0.936074, `rotation3` = 0.351803 WHERE `guid` = 26579 AND `id` = 176237;
UPDATE `gameobject` SET `position_x` = -8707.04, `position_y` = 338.13, `position_z` = 101.949, `orientation` = 0.5115, `rotation2` = 0.252971, `rotation3` = 0.967474 WHERE `guid` = 26580 AND `id` = 176238;
UPDATE `gameobject` SET `position_x` = -8705.1, `position_y` = 336.47, `position_z` = 101.949, `orientation` = 1.5761, `rotation2` = 0.708979, `rotation3` = 0.705229 WHERE `guid` = 26581 AND `id` = 176239;
UPDATE `gameobject` SET `position_x` = -8702.62, `position_y` = 336.65, `position_z` = 101.949, `orientation` = 2.0648, `rotation2` = 0.858532, `rotation3` = 0.51276 WHERE `guid` = 26584 AND `id` = 176240;
UPDATE `gameobject` SET `position_x` = -8701.53, `position_y` = 338.93, `position_z` = 101.949, `orientation` = 3.1033, `rotation2` = 0.999817, `rotation3` = 0.019145 WHERE `guid` = 26586 AND `id` = 176241;
UPDATE `gameobject` SET `position_x` = -8701.55, `position_y` = 337.19, `position_z` = 108.332, `orientation` = 1.7856, `rotation2` = 0.778831, `rotation3` = 0.627234 WHERE `guid` = 26587 AND `id` = 176236;
-- Master Mathias Shaw: QuestSuperTrack turn-in of his 8 quests (135 393 394 2205 2206 2359 6182 6183) inside
--   A01Sw_Oldtown_Si7, CoA floor 108.38; the SI:7 rigid transform puts him 0.49 yd from it
UPDATE `creature` SET `position_x` = -8732.1, `position_y` = 309.53, `position_z` = 108.463, `orientation` = 0.1013 WHERE `guid` = 79785 AND `id` = 332;
-- 12 rows: stock warrior barracks rebuilt as A01Sw_Oldtown_Commandcenter: rigid transform rot -119.3 deg fitted on 60
--   matched doodads (mean residual 0.014 yd), floors 6.03 yd higher
UPDATE `creature` SET `position_x` = -8802.14, `position_y` = 330.79, `position_z` = 115.549, `orientation` = 2.3504 WHERE `guid` = 79778 AND `id` = 5480;
UPDATE `creature` SET `position_x` = -8803.98, `position_y` = 332.69, `position_z` = 115.549, `orientation` = 5.492 WHERE `guid` = 79779 AND `id` = 5479;
UPDATE `creature` SET `position_x` = -8790.56, `position_y` = 343.61, `position_z` = 118.119, `orientation` = 3.7991 WHERE `guid` = 79780 AND `id` = 914;
UPDATE `creature` SET `position_x` = -8801.39, `position_y` = 350.51, `position_z` = 109.218, `orientation` = 3.8689 WHERE `guid` = 79789 AND `id` = 8383;
UPDATE `gameobject` SET `position_x` = -8787.02, `position_y` = 342.51, `position_z` = 117.641, `orientation` = 2.8479, `rotation2` = 0.989237, `rotation3` = 0.146319 WHERE `guid` = 26560 AND `id` = 160439;
UPDATE `gameobject` SET `position_x` = -8788.36, `position_y` = 339.73, `position_z` = 117.64, `orientation` = 2.3417, `rotation2` = 0.921082, `rotation3` = 0.389369 WHERE `guid` = 26561 AND `id` = 160440;
UPDATE `gameobject` SET `position_x` = -8787.22, `position_y` = 345.51, `position_z` = 117.641, `orientation` = 3.5198, `rotation2` = 0.982173, `rotation3` = -0.187979 WHERE `guid` = 26566 AND `id` = 160438;
UPDATE `gameobject` SET `position_x` = -8789.25, `position_y` = 347.37, `position_z` = 117.641, `orientation` = 4.2703, `rotation2` = 0.844934, `rotation3` = -0.53487 WHERE `guid` = 26575 AND `id` = 160437;
UPDATE `gameobject` SET `position_x` = -8798.46, `position_y` = 348.19, `position_z` = 109.126, `orientation` = 2.2806, `rotation2` = 0.908759, `rotation3` = 0.417322 WHERE `guid` = 26582 AND `id` = 24480;
UPDATE `gameobject` SET `position_x` = -8793.89, `position_y` = 345.89, `position_z` = 117.643, `orientation` = 5.4571, `rotation2` = 0.401398, `rotation3` = -0.915904 WHERE `guid` = 26585 AND `id` = 160441;
UPDATE `gameobject` SET `position_x` = -8791.65, `position_y` = 347.41, `position_z` = 117.641, `orientation` = 4.855, `rotation2` = 0.654932, `rotation3` = -0.755688 WHERE `guid` = 26588 AND `id` = 160436;
UPDATE `gameobject` SET `position_x` = -8803.26, `position_y` = 353.73, `position_z` = 109.126, `orientation` = 5.4309, `rotation2` = 0.413362, `rotation3` = -0.910567 WHERE `guid` = 26589 AND `id` = 112907;
-- Wooden Chair: stock warrior barracks rebuilt as A01Sw_Oldtown_Commandcenter: rigid transform rot -119.3 deg fitted
--   on 60 matched doodads (mean residual 0.014 yd), floors 6.03 yd higher; survey class fits, moved with its room
UPDATE `gameobject` SET `position_x` = -8815.48, `position_y` = 344.29, `position_z` = 107.057, `orientation` = 0.7098, `rotation2` = 0.347497, `rotation3` = 0.937681 WHERE `guid` = 26562 AND `id` = 112901;
UPDATE `gameobject` SET `position_x` = -8811.61, `position_y` = 342.46, `position_z` = 107.057, `orientation` = 2.2283, `rotation2` = 0.897536, `rotation3` = 0.440941 WHERE `guid` = 26563 AND `id` = 112902;
UPDATE `gameobject` SET `position_x` = -8814.29, `position_y` = 342.64, `position_z` = 107.057, `orientation` = 0.7098, `rotation2` = 0.347497, `rotation3` = 0.937681 WHERE `guid` = 26564 AND `id` = 112903;
UPDATE `gameobject` SET `position_x` = -8811.39, `position_y` = 345.01, `position_z` = 107.057, `orientation` = 3.8514, `rotation2` = 0.93768, `rotation3` = -0.3475 WHERE `guid` = 26565 AND `id` = 112904;
UPDATE `gameobject` SET `position_x` = -8812.77, `position_y` = 346.56, `position_z` = 107.057, `orientation` = 3.8514, `rotation2` = 0.93768, `rotation3` = -0.3475 WHERE `guid` = 26572 AND `id` = 112905;
UPDATE `gameobject` SET `position_x` = -8815.05, `position_y` = 346.78, `position_z` = 107.057, `orientation` = 4.4885, `rotation2` = 0.781672, `rotation3` = -0.623689 WHERE `guid` = 26573 AND `id` = 112906;
-- Brother Cassius, Shaina Fuller, Wooden Chair: Cathedral east room moved in CoA: translation (-5.856, +7.366) fitted
--   on 29 matched tables/candelabras/bookstacks, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `creature` SET `position_x` = -8524.86, `position_y` = 805.16, `position_z` = 106.519, `orientation` = 0.74 WHERE `guid` = 7629 AND `id` = 1351;
UPDATE `creature` SET `position_x` = -8518.86, `position_y` = 809.17, `position_z` = 106.519, `orientation` = 2.164 WHERE `guid` = 15216 AND `id` = 2327;
UPDATE `gameobject` SET `position_x` = -8533.89, `position_y` = 809.86, `position_z` = 106.523, `orientation` = 0.672 WHERE `guid` = 11045 AND `id` = 24682;
-- Wooden Chair: Cathedral east room moved in CoA: translation (-5.856, +7.366) fitted on 29 matched
--   tables/candelabras/bookstacks, residual 0.002 yd; same floor
UPDATE `gameobject` SET `position_x` = -8522.6, `position_y` = 795.67, `position_z` = 106.523, `orientation` = 0.672 WHERE `guid` = 11046 AND `id` = 24683;
-- Wooden Chair: Cathedral east room moved in CoA: translation (-5.856, +7.366) fitted on 29 matched
--   tables/candelabras/bookstacks, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `gameobject` SET `position_x` = -8520.3, `position_y` = 822.83, `position_z` = 106.523, `orientation` = 5.3843 WHERE `guid` = 11047 AND `id` = 24684;
-- Wooden Chair: Cathedral east room moved in CoA: translation (-5.856, +7.366) fitted on 29 matched
--   tables/candelabras/bookstacks, residual 0.002 yd; same floor
UPDATE `gameobject` SET `position_x` = -8520.3, `position_y` = 795.42, `position_z` = 106.523, `orientation` = 2.2428 WHERE `guid` = 11048 AND `id` = 24685;
-- Wooden Chair: Cathedral east room moved in CoA: translation (-5.856, +7.366) fitted on 29 matched
--   tables/candelabras/bookstacks, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `gameobject` SET `position_x` = -8507.01, `position_y` = 806.04, `position_z` = 106.523, `orientation` = 2.2428 WHERE `guid` = 11049 AND `id` = 24689;
UPDATE `gameobject` SET `position_x` = -8506.58, `position_y` = 808.42, `position_z` = 106.523, `orientation` = 3.8136 WHERE `guid` = 11050 AND `id` = 24690;
UPDATE `gameobject` SET `position_x` = -8533.6, `position_y` = 812.24, `position_z` = 106.523, `orientation` = 5.3843 WHERE `guid` = 11051 AND `id` = 24691;
UPDATE `gameobject` SET `position_x` = -8517.93, `position_y` = 822.6, `position_z` = 106.523, `orientation` = 3.8136 WHERE `guid` = 11052 AND `id` = 24693;
-- Brother Crowley, Wooden Chair: Cathedral lower library and crypt moved in CoA: translation (+3.314, -4.169) fitted
--   on 42 matched tables/coffins/iron maidens, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `creature` SET `position_x` = -8494.69, `position_y` = 805.1, `position_z` = 96.774, `orientation` = 2.26 WHERE `guid` = 52472 AND `id` = 12336;
UPDATE `gameobject` SET `position_x` = -8492.72, `position_y` = 817.96, `position_z` = 96.679, `orientation` = 3.8136 WHERE `guid` = 11053 AND `id` = 24695;
UPDATE `gameobject` SET `position_x` = -8482.02, `position_y` = 804.5, `position_z` = 96.679, `orientation` = 3.8136 WHERE `guid` = 11054 AND `id` = 24696;
UPDATE `gameobject` SET `position_x` = -8482.26, `position_y` = 802.01, `position_z` = 96.68, `orientation` = 2.2428 WHERE `guid` = 11055 AND `id` = 24697;
-- Wooden Chair: Cathedral lower library and crypt moved in CoA: translation (+3.314, -4.169) fitted on 42 matched
--   tables/coffins/iron maidens, residual 0.002 yd; same floor
UPDATE `gameobject` SET `position_x` = -8507.47, `position_y` = 808.32, `position_z` = 96.679, `orientation` = 5.3843 WHERE `guid` = 11056 AND `id` = 24698;
-- Wooden Chair: Cathedral lower library and crypt moved in CoA: translation (+3.314, -4.169) fitted on 42 matched
--   tables/coffins/iron maidens, residual 0.002 yd; same floor; survey class fits, moved with its room
UPDATE `gameobject` SET `position_x` = -8507.68, `position_y` = 806.04, `position_z` = 96.679, `orientation` = 0.672 WHERE `guid` = 11057 AND `id` = 24699;
-- Wooden Chair: Cathedral lower library and crypt moved in CoA: translation (+3.314, -4.169) fitted on 42 matched
--   tables/coffins/iron maidens, residual 0.002 yd; same floor
UPDATE `gameobject` SET `position_x` = -8495.06, `position_y` = 818.24, `position_z` = 96.679, `orientation` = 5.3843 WHERE `guid` = 11132 AND `id` = 24694;
-- Grandmaster's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; grass edge
--   against the house wall, beside the dummy by the SI:7 wall
UPDATE `creature` SET `position_x` = -8702, `position_y` = 346, `position_z` = 100.69, `orientation` = 3.095 WHERE `guid` = 201241 AND `id` = 31144;
UPDATE `creature` SET `position_x` = -8709, `position_y` = 348, `position_z` = 100.79, `orientation` = 3.142 WHERE `guid` = 201239 AND `id` = 31144;
-- Heroic Training Dummy: playtest: out of the Old Town square onto the edge of the training field; grass edge along
--   the fence by the houses
UPDATE `creature` SET `position_x` = -8711, `position_y` = 343, `position_z` = 100.8, `orientation` = 2.996 WHERE `guid` = 201242 AND `id` = 31146;
-- Grandmaster's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; its stock
--   spot on the grass edge by the houses, set on the ground
UPDATE `creature` SET `position_x` = -8724.87, `position_y` = 333.107, `position_z` = 99.975, `orientation` = 2.505 WHERE `guid` = 201236 AND `id` = 31144;
-- Grandmaster's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; its stock
--   spot at the west edge of the grass, set on the ground
UPDATE `creature` SET `position_x` = -8772.87, `position_y` = 358.009, `position_z` = 102.132, `orientation` = 5.938 WHERE `guid` = 201237 AND `id` = 31144;
-- Expert's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; grass edge along
--   the fence by the houses
UPDATE `creature` SET `position_x` = -8714, `position_y` = 338, `position_z` = 100.43, `orientation` = 2.83 WHERE `guid` = 202727 AND `id` = 32666;
-- Expert's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; grass edge
--   against the house wall at the east end of the row
UPDATE `creature` SET `position_x` = -8698, `position_y` = 347, `position_z` = 99.91, `orientation` = 3.12 WHERE `guid` = 202726 AND `id` = 32666;
-- Master's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; grass edge by the
--   houses at the east corner of the field
UPDATE `creature` SET `position_x` = -8722, `position_y` = 326, `position_z` = 99.89, `orientation` = 2.378 WHERE `guid` = 202731 AND `id` = 32667;
-- Master's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; grass edge along
--   the fence by the houses
UPDATE `creature` SET `position_x` = -8715, `position_y` = 334, `position_z` = 100.19, `orientation` = 2.705 WHERE `guid` = 202730 AND `id` = 32667;
-- Lord Grayson Shadowbreaker: the Cathedral west side room is gone (open ground at 97-99); the nearest interior on
--   that side is the vaulted west chapel off the crossing (floor 106.52, stone bench 13848): back of the chapel,
--   facing the crossing
UPDATE `creature` SET `position_x` = -8531, `position_y` = 870.5, `position_z` = 106.52, `orientation` = 4.7124 WHERE `guid` = 5000 AND `id` = 928;
-- Katherine the Pure: the Cathedral west side room is gone (open ground at 97-99); the nearest interior on that side
--   is the vaulted west chapel off the crossing (floor 106.52, stone bench 13848): south side of the chapel, facing
--   the entrance
UPDATE `creature` SET `position_x` = -8535, `position_y` = 866.5, `position_z` = 106.52, `orientation` = 5.341 WHERE `guid` = 37586 AND `id` = 5492;
-- Arthur the Faithful: the Cathedral west side room is gone (open ground at 97-99); the nearest interior on that side
--   is the vaulted west chapel off the crossing (floor 106.52, stone bench 13848): north side of the chapel by its
--   entrance, facing the entrance
UPDATE `creature` SET `position_x` = -8527.5, `position_y` = 866, `position_z` = 106.52, `orientation` = 4.101 WHERE `guid` = 37585 AND `id` = 5491;
-- Rat: stock spot is inside the trunk of CoA Alteractree06 in the planter at (-8784.0,462.2); set on the paving south
--   of the planter, wander 5 kept
UPDATE `creature` SET `position_x` = -8789, `position_y` = 462.5, `position_z` = 97.708, `orientation` = 1.46606 WHERE `guid` = 133923 AND `id` = 4075;
-- Sewer Beast: stock canal bed 85.89 is now the CoA canal bed 92.64 (water 95.46); same aquatic spot; its pool 86300
--   partner guid 86300 is in package eastwing
UPDATE `creature` SET `position_x` = -8783.6, `position_y` = 487.416, `position_z` = 92.736, `orientation` = 0.528863 WHERE `guid` = 86301 AND `id` = 3581;
-- Stormwind City Guard: canal guard pair with 79732: the stock island post is now an isolated 9 yd pier top (98.9)
--   with canal water on every side, not a bridge; on the south quay promenade 3.4 yd from his partner 79732, facing
--   the Trade District as before (trade's request)
UPDATE `creature` SET `position_x` = -8697.2, `position_y` = 640.4, `position_z` = 100.379, `orientation` = 2.23402 WHERE `guid` = 79730 AND `id` = 68;
-- OLDWorld Trigger (DO NOT DELETE): invisible trigger sat on the stock 59.46 placeholder terrain under the Stockade
--   approach; CoA terrain there is 86.34
UPDATE `creature` SET `position_x` = -8764.96, `position_y` = 834.588, `position_z` = 86.422, `orientation` = 0.226893 WHERE `guid` = 120648 AND `id` = 15384;
-- Jenn Langston: walker spawn point sunk 0.62 into CoA terrain 101.99 on her Old Town street path; path 797460 is on
--   the CoA floor
UPDATE `creature` SET `position_x` = -8692.72, `position_y` = 397.438, `position_z` = 102.007, `orientation` = 5.51888 WHERE `guid` = 79746 AND `id` = 3626;
-- Lil Timmy: same street spot west of Cathedral Square; CoA terrain 98.80 replaces the stock 99.36 paving
UPDATE `creature` SET `position_x` = -8634.51, `position_y` = 918.961, `position_z` = 98.797, `orientation` = 3.83299 WHERE `guid` = 45501 AND `id` = 8666;
-- Stormwind City Patroller: patrol spawn point sunk 0.79 into CoA terrain 97.44 in Cathedral Square; path 798140 is on
--   the CoA floor
UPDATE `creature` SET `position_x` = -8563.95, `position_y` = 751.397, `position_z` = 97.44, `orientation` = 0.70585 WHERE `guid` = 79814 AND `id` = 1976;
-- Mailbox: same square by the lion fountain; CoA paving 97.29 replaces the stock 95.82 floor
UPDATE `gameobject` SET `position_x` = -8797.54, `position_y` = 463.519, `position_z` = 97.287, `orientation` = 4.31969 WHERE `guid` = 150739 AND `id` = 195608;
-- Fire Festival Fury Trap: stock spot is on the rim of CoA Stormwindlionfountain (-8806.5,471.7); moved 1.6 yd north
--   onto the paving (96.72)
UPDATE `gameobject` SET `position_x` = -8798.4, `position_y` = 475.3, `position_z` = 96.721, `orientation` = 2.04204 WHERE `guid` = 26269 AND `id` = 181431;
UPDATE `gameobject` SET `position_x` = -8798.4, `position_y` = 475.3, `position_z` = 96.721, `orientation` = 2.04204 WHERE `guid` = 54664 AND `id` = 181431;
-- Spool of Light Chartreuse Silk Thread: quest lootable (item 8431); its stock shop table at 99.73 is gone, the spot
--   is now the CoA ethereal stall; set on top of the Et_Crate01 crate at (-8693.4,840.0) next to Evert Sorisam
UPDATE `gameobject` SET `position_x` = -8693.4, `position_y` = 840, `position_z` = 99.274, `orientation` = 3.142 WHERE `guid` = 42899 AND `id` = 140911;
-- Lights x3, Lights: hanging lights under the same Old Town beam, which is 0.6-0.7 yd lower in CoA; lowered by the
--   same amount to keep the stock 1.2-1.3 yd gap
UPDATE `gameobject` SET `position_x` = -8647.99, `position_y` = 443.477, `position_z` = 108.366, `orientation` = 2.25147 WHERE `guid` = 1885 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -8647.99, `position_y` = 443.477, `position_z` = 108.366, `orientation` = 2.25147 WHERE `guid` = 29476 AND `id` = 180770;
-- Lights x3, Lights: hanging lights under the same Cathedral Square canal beam, which is 0.6-0.7 yd lower in CoA;
--   lowered by the same amount to keep the stock 1.2-1.3 yd gap
UPDATE `gameobject` SET `position_x` = -8705.73, `position_y` = 851.331, `position_z` = 102.887, `orientation` = 5.39307 WHERE `guid` = 1887 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -8705.73, `position_y` = 851.331, `position_z` = 102.887, `orientation` = 5.39307 WHERE `guid` = 19692 AND `id` = 180770;
-- Lights, Lights x3: hanging lights under the same Cathedral Square beam, which is 0.6-0.7 yd lower in CoA; lowered by
--   the same amount to keep the stock 1.2-1.3 yd gap
UPDATE `gameobject` SET `position_x` = -8655.18, `position_y` = 670.121, `position_z` = 105.845, `orientation` = 0.663223 WHERE `guid` = 19690 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8655.18, `position_y` = 670.121, `position_z` = 105.845, `orientation` = 0.663223 WHERE `guid` = 40948 AND `id` = 178645;
-- Hanging, Square, Medium - MFF: Cathedral Square wall lantern: its ledge rose from 108.14 to 109.19; raised 1.05 yd,
--   wall clearance 0.43 yd as in stock (0.5)
UPDATE `gameobject` SET `position_x` = -8588.41, `position_y` = 706.812, `position_z` = 110.041, `orientation` = 2.18166 WHERE `guid` = 53012 AND `id` = 181390;
-- Hanging, Square, Medium - MFF: Cathedral Square wall lantern: its ledge rose from 108.18 to 109.49; raised 1.30 yd,
--   wall clearance 0.31 yd as in stock (0.31)
UPDATE `gameobject` SET `position_x` = -8665.59, `position_y` = 741.219, `position_z` = 110.103, `orientation` = 0.733038 WHERE `guid` = 53033 AND `id` = 181390;
-- Banner, Wreath: wall-mounted in stock (0.01 yd); the CoA facade is 1.0-1.2 yd further back along 125 deg; moved onto
--   the CoA wall face (0.0 yd)
UPDATE `gameobject` SET `position_x` = -8713.43, `position_y` = 466.33, `position_z` = 107.831, `orientation` = 5.32326 WHERE `guid` = 19706 AND `id` = 180773;
UPDATE `gameobject` SET `position_x` = -8713.34, `position_y` = 466.2, `position_z` = 111.004, `orientation` = 5.32326 WHERE `guid` = 71498 AND `id` = 178437;
-- Old Town: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is 0.1-0.9 yd
--   behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock bracket distance:
--   Old Town canal gate, 1.42 yd
UPDATE `gameobject` SET `position_x` = -8730.44, `position_y` = 500.49, `position_z` = 107.884, `orientation` = 5.38434, `rotation2` = 0.434446, `rotation3` = -0.900698 WHERE `guid` = 26419 AND `id` = 25346;
-- Old Town: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is 0.1-0.9 yd
--   behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock bracket distance:
--   Old Town canal gate, 1.43 yd
UPDATE `gameobject` SET `position_x` = -8709.8, `position_y` = 516.93, `position_z` = 107.884, `orientation` = 5.38434, `rotation2` = 0.434446, `rotation3` = -0.900698 WHERE `guid` = 26423 AND `id` = 25347;
-- Old Town: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is 0.1-0.9 yd
--   behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock bracket distance:
--   Old Town keep-side gate, 1.61 yd
UPDATE `gameobject` SET `position_x` = -8619.83, `position_y` = 515.62, `position_z` = 115.383, `orientation` = 3.81354, `rotation2` = 0.94409, `rotation3` = -0.329689 WHERE `guid` = 26440 AND `id` = 25336;
UPDATE `gameobject` SET `position_x` = -8603.4, `position_y` = 494.97, `position_z` = 115.383, `orientation` = 3.81354, `rotation2` = 0.94409, `rotation3` = -0.329689 WHERE `guid` = 26454 AND `id` = 25337;
-- Cathedral Square: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is
--   0.1-0.9 yd behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock
--   bracket distance: Cathedral Square gate, 1.54 yd
UPDATE `gameobject` SET `position_x` = -8576.53, `position_y` = 671.21, `position_z` = 109.566, `orientation` = 2.24275, `rotation2` = 0.900699, `rotation3` = 0.434444 WHERE `guid` = 26545 AND `id` = 25339;
-- Cathedral Square: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is
--   0.1-0.9 yd behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock
--   bracket distance: Cathedral Square gate, 1.78 yd
UPDATE `gameobject` SET `position_x` = -8685.4, `position_y` = 709.11, `position_z` = 109.421, `orientation` = 0.67196, `rotation2` = 0.329695, `rotation3` = 0.944088 WHERE `guid` = 26601 AND `id` = 25340;
-- Cathedral Square: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is
--   0.1-0.9 yd behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock
--   bracket distance: Cathedral Square gate, 1.56 yd
UPDATE `gameobject` SET `position_x` = -8701.32, `position_y` = 729.65, `position_z` = 109.421, `orientation` = 0.67196, `rotation2` = 0.329695, `rotation3` = 0.944088 WHERE `guid` = 26603 AND `id` = 63198;
-- Cathedral Square: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is
--   0.1-0.9 yd behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock
--   bracket distance: Cathedral Square gate, 0.97 yd
UPDATE `gameobject` SET `position_x` = -8555.7, `position_y` = 665.95, `position_z` = 103.701, `orientation` = 2.24275, `rotation2` = 0.900699, `rotation3` = 0.434444 WHERE `guid` = 26522 AND `id` = 25338;
-- Cathedral Square: bracket sign: its stock mount wall 1.4-1.8 yd in +o is gone and the rebuilt CoA gate pier is
--   0.1-0.9 yd behind it (sign half inside the pier); turned 180 deg and set off the CoA pier face at the stock
--   bracket distance: Cathedral Square gate, 1.09 yd
UPDATE `gameobject` SET `position_x` = -8706.69, `position_y` = 708.73, `position_z` = 103.556, `orientation` = 0.67196, `rotation2` = 0.329695, `rotation3` = 0.944088 WHERE `guid` = 26602 AND `id` = 63197;
-- Champions' Hall: pointer arm "Champions' Hall" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8723.854, `position_y` = 517.324, `position_z` = 93.436, `orientation` = -2.50455 WHERE `guid` = 26420 AND `id` = 179725;
-- 26 rows: path node moved with the Pig and Whistle (translation -1.744, +15.053); same floor
UPDATE `waypoint_data` SET `position_x` = -8605.76, `position_y` = 404.87, `position_z` = 102.924 WHERE `id` = 797500 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8615.34, `position_y` = 407.75, `position_z` = 103.43 WHERE `id` = 797500 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8611.94, `position_y` = 399.86, `position_z` = 102.926 WHERE `id` = 797500 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8617.45, `position_y` = 403.49, `position_z` = 102.975 WHERE `id` = 797500 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -8618.55, `position_y` = 404.99, `position_z` = 103.432 WHERE `id` = 797500 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -8612.01, `position_y` = 399.79, `position_z` = 102.926 WHERE `id` = 797500 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = -8611.85, `position_y` = 403.38, `position_z` = 102.925 WHERE `id` = 797500 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -8609.55, `position_y` = 406.15, `position_z` = 102.925 WHERE `id` = 797500 AND `point` = 8;
UPDATE `waypoint_data` SET `position_x` = -8605.68, `position_y` = 404.45, `position_z` = 102.925 WHERE `id` = 797500 AND `point` = 9;
UPDATE `waypoint_data` SET `position_x` = -8611.64, `position_y` = 403.01, `position_z` = 102.926 WHERE `id` = 797760 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8616.72, `position_y` = 399.13, `position_z` = 102.927 WHERE `id` = 797760 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8621.11, `position_y` = 401.09, `position_z` = 102.927 WHERE `id` = 797760 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8626.51, `position_y` = 409.74, `position_z` = 102.925 WHERE `id` = 797760 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -8629.3, `position_y` = 409.16, `position_z` = 102.925 WHERE `id` = 797760 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -8629.55, `position_y` = 405.16, `position_z` = 102.925 WHERE `id` = 797760 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = -8624.37, `position_y` = 398.8, `position_z` = 106.44 WHERE `id` = 797760 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -8619.04, `position_y` = 392.08, `position_z` = 110.172 WHERE `id` = 797760 AND `point` = 8;
UPDATE `waypoint_data` SET `position_x` = -8617.38, `position_y` = 389.95, `position_z` = 110.172 WHERE `id` = 797760 AND `point` = 9;
UPDATE `waypoint_data` SET `position_x` = -8613.04, `position_y` = 390.62, `position_z` = 110.172 WHERE `id` = 797760 AND `point` = 10;
UPDATE `waypoint_data` SET `position_x` = -8601.71, `position_y` = 402.24, `position_z` = 110.172 WHERE `id` = 797760 AND `point` = 11;
UPDATE `waypoint_data` SET `position_x` = -8601.43, `position_y` = 404.46, `position_z` = 110.172 WHERE `id` = 797760 AND `point` = 12;
UPDATE `waypoint_data` SET `position_x` = -8606.21, `position_y` = 410.55, `position_z` = 107.399 WHERE `id` = 797760 AND `point` = 13;
UPDATE `waypoint_data` SET `position_x` = -8612.78, `position_y` = 417.87, `position_z` = 102.946 WHERE `id` = 797760 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8617.06, `position_y` = 418.58, `position_z` = 102.924 WHERE `id` = 797760 AND `point` = 15;
UPDATE `waypoint_data` SET `position_x` = -8617.42, `position_y` = 415.59, `position_z` = 102.924 WHERE `id` = 797760 AND `point` = 16;
UPDATE `waypoint_data` SET `position_x` = -8610.71, `position_y` = 406.89, `position_z` = 102.924 WHERE `id` = 797760 AND `point` = 17;
-- Stormwind City Patroller 12093 path node 12: patrol turnaround ran into the CoA Stormwind_Stonegate at
--   (-8554.1,766.9); node set on the slope in front of the gate: approach
UPDATE `waypoint_data` SET `position_x` = -8566, `position_y` = 764, `position_z` = 98.208 WHERE `id` = 120930 AND `point` = 12;
-- Stormwind City Patroller 12093 path node 13: patrol turnaround ran into the CoA Stormwind_Stonegate at
--   (-8554.1,766.9); node set on the slope in front of the gate: turn
UPDATE `waypoint_data` SET `position_x` = -8562.5, `position_y` = 761.5, `position_z` = 98.408 WHERE `id` = 120930 AND `point` = 13;
-- Stormwind City Patroller 12093 path node 14: patrol turnaround ran into the CoA Stormwind_Stonegate at
--   (-8554.1,766.9); node set on the slope in front of the gate: return
UPDATE `waypoint_data` SET `position_x` = -8556, `position_y` = 756, `position_z` = 98.328 WHERE `id` = 120930 AND `point` = 14;
-- Stormwind City Patroller 79807 path node 32: patrol turnaround ran into the CoA Stormwind_Stonegate at
--   (-8554.1,766.9); node set on the slope in front of the gate: approach
UPDATE `waypoint_data` SET `position_x` = -8558, `position_y` = 754, `position_z` = 97.948 WHERE `id` = 798070 AND `point` = 32;
-- Stormwind City Patroller 79807 path node 33, Stormwind City Patroller 79807 path node 1: patrol turnaround ran into
--   the CoA Stormwind_Stonegate at (-8554.1,766.9); node set on the slope in front of the gate: turn
UPDATE `waypoint_data` SET `position_x` = -8558.5, `position_y` = 758.5, `position_z` = 98.443 WHERE `id` = 798070 AND `point` = 33;
UPDATE `waypoint_data` SET `position_x` = -8561.5, `position_y` = 764, `position_z` = 98.7 WHERE `id` = 798070 AND `point` = 1;
-- Stormwind City Patroller 79807 path node 2: patrol turnaround ran into the CoA Stormwind_Stonegate at
--   (-8554.1,766.9); node set on the slope in front of the gate: return
UPDATE `waypoint_data` SET `position_x` = -8563, `position_y` = 767, `position_z` = 98.732 WHERE `id` = 798070 AND `point` = 2;
-- Stormwind City Patroller 79807 path node 3: terrain in front of the gate rose 1.2 yd
UPDATE `waypoint_data` SET `position_x` = -8570.28, `position_y` = 762.691, `position_z` = 97.815 WHERE `id` = 798070 AND `point` = 3;
-- Officer Brady 79768 path node 20: Dwarven District step at 93.35 replaces the stock 91.78 floor (inside the eastwing
--   area)
UPDATE `waypoint_data` SET `position_x` = -8386.85, `position_y` = 587.318, `position_z` = 93.349 WHERE `id` = 797680 AND `point` = 20;
-- Old Town: pointer arm "Old Town" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8723.924, `position_y` = 517.413, `position_z` = 95.738, `orientation` = -2.50455 WHERE `guid` = 26415 AND `id` = 2136;
-- Trade District: pointer arm "Trade District" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8725.464, `position_y` = 519.493, `position_z` = 95.541, `orientation` = 0.637046 WHERE `guid` = 26416 AND `id` = 2115;
-- Stormwind Gate: pointer arm "Stormwind Gate" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8725.494, `position_y` = 519.524, `position_z` = 94.362, `orientation` = 0.637046 WHERE `guid` = 26417 AND `id` = 28041;
-- Dwarven District: pointer arm "Dwarven District" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced
--   its stock Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8723.644, `position_y` = 519.221, `position_z` = 95.748, `orientation` = -0.933752 WHERE `guid` = 26418 AND `id` = 28027;
-- SI:7: pointer arm "SI:7" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8723.864, `position_y` = 517.337, `position_z` = 94.202, `orientation` = -2.50455 WHERE `guid` = 26421 AND `id` = 179744;
-- Command Center: pointer arm "Command Center" at the Old Town canal-bridge crossing (-8723, 516): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 2.5 yd south-west; arm moved with the post, same offset, 0.99 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8723.894, `position_y` = 517.375, `position_z` = 94.97, `orientation` = -2.50455 WHERE `guid` = 26422 AND `id` = 179743;
-- Trade District: pointer arm "Trade District" at the Cathedral canal crossing (-8712, 725): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 2.4 yd south-east; arm moved with the post, same offset, 0.88 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8715.524, `position_y` = 723.176, `position_z` = 96.809, `orientation` = 2.2602 WHERE `guid` = 26600 AND `id` = 2187;
-- Stormwind Gate: pointer arm "Stormwind Gate" at the Cathedral canal crossing (-8712, 725): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 2.4 yd south-east; arm moved with the post, same offset, 0.88 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8715.554, `position_y` = 723.156, `position_z` = 95.746, `orientation` = 2.2602 WHERE `guid` = 26604 AND `id` = 28040;
-- Cathedral Square: pointer arm "Cathedral Square" at the Cathedral canal crossing (-8712, 725): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 2.4 yd south-east; arm moved with the post, same offset, 0.88 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8713.514, `position_y` = 724.832, `position_z` = 96.809, `orientation` = 5.4018 WHERE `guid` = 26607 AND `id` = 2175;
-- Dwarven District: pointer arm "Dwarven District" at the Cathedral canal crossing (-8712, 725): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 2.4 yd south-east; arm moved with the post, same offset, 0.88 yd
--   lower to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new
--   post otherwise)
UPDATE `gameobject` SET `position_x` = -8713.694, `position_y` = 723, `position_z` = 96.209, `orientation` = -2.45219 WHERE `guid` = 26609 AND `id` = 28032;
-- The Park: pointer arm "The Park" at the Cathedral canal crossing (-8712, 725): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 2.4 yd south-east; arm moved with the post, same offset, 0.88 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8715.344, `position_y` = 725.009, `position_z` = 96.209, `orientation` = 0.689404 WHERE `guid` = 26610 AND `id` = 24717;
-- Cathedral Square: pointer arm "Cathedral Square" at the Cathedral Square west crossing (-8706, 867): CoA replaced
--   its stock Woodsignpostnice01 with Humansignpost03 3.3 yd west; arm moved with the post, same offset, 0.87 yd lower
--   to keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8705.793, `position_y` = 868.962, `position_z` = 95.891, `orientation` = 3.831 WHERE `guid` = 61923 AND `id` = 2179;
-- Stormwind Gate: pointer arm "Stormwind Gate" at the Cathedral Square west crossing (-8706, 867): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 3.3 yd west; arm moved with the post, same offset, 0.87 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8707.683, `position_y` = 869.089, `position_z` = 95.294, `orientation` = 2.2602 WHERE `guid` = 61928 AND `id` = 28039;
-- The Park: pointer arm "The Park" at the Cathedral Square west crossing (-8706, 867): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.3 yd west; arm moved with the post, same offset, 0.87 yd lower to keep
--   its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post otherwise)
UPDATE `gameobject` SET `position_x` = -8707.453, `position_y` = 870.971, `position_z` = 95.891, `orientation` = 0.689404 WHERE `guid` = 61934 AND `id` = 24718;
-- Trade District: pointer arm "Trade District" at the Cathedral Square west crossing (-8706, 867): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 3.3 yd west; arm moved with the post, same offset, 0.87 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8707.623, `position_y` = 869.139, `position_z` = 96.491, `orientation` = 2.2602 WHERE `guid` = 61938 AND `id` = 2191;
-- Old Town: pointer arm "Old Town" at the Old Town upper street (-8617, 521): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.4 yd north-west; arm moved with the post, same offset, 1.02 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8615.465, `position_y` = 522.539, `position_z` = 102.061, `orientation` = 2.34747 WHERE `guid` = 26437 AND `id` = 2143;
-- Trade District: pointer arm "Trade District" at the Old Town upper street (-8617, 521): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.4 yd north-west; arm moved with the post, same offset, 1.02 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8615.445, `position_y` = 524.381, `position_z` = 101.461, `orientation` = 0.776672 WHERE `guid` = 26438 AND `id` = 2125;
-- Dwarven District: pointer arm "Dwarven District" at the Old Town upper street (-8617, 521): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.4 yd north-west; arm moved with the post, same offset, 1.02 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8613.605, `position_y` = 524.365, `position_z` = 102.061, `orientation` = -0.794124 WHERE `guid` = 26441 AND `id` = 28028;
-- Stormwind Keep: pointer arm "Stormwind Keep" at the Old Town upper street (-8617, 521): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.4 yd north-west; arm moved with the post, same offset, 1.02 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8613.615, `position_y` = 522.523, `position_z` = 101.461, `orientation` = -2.36492 WHERE `guid` = 26443 AND `id` = 2117;
-- Stormwind Gate: pointer arm "Stormwind Gate" at the Dwarven District crossing (-8538, 682): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.6 yd east; arm moved with the post, same offset, 0.61 yd lower to keep
--   its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post otherwise)
UPDATE `gameobject` SET `position_x` = -8539.105, `position_y` = 677.515, `position_z` = 96.059, `orientation` = 2.2602 WHERE `guid` = 26518 AND `id` = 28038;
-- Dwarven District: pointer arm "Dwarven District" at the Dwarven District crossing (-8538, 682): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 3.6 yd east; arm moved with the post, same offset, 0.61 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8537.225, `position_y` = 677.378, `position_z` = 96.587, `orientation` = -2.45219 WHERE `guid` = 26519 AND `id` = 28031;
-- Trade District: pointer arm "Trade District" at the Dwarven District crossing (-8538, 682): CoA replaced its stock
--   Woodsignpostnice01 with Humansignpost03 3.6 yd east; arm moved with the post, same offset, 0.61 yd lower to keep
--   its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post otherwise)
UPDATE `gameobject` SET `position_x` = -8539.055, `position_y` = 677.555, `position_z` = 97.187, `orientation` = 2.2602 WHERE `guid` = 26520 AND `id` = 2133;
-- Cathedral Square: pointer arm "Cathedral Square" at the Dwarven District crossing (-8538, 682): CoA replaced its
--   stock Woodsignpostnice01 with Humansignpost03 3.6 yd east; arm moved with the post, same offset, 0.61 yd lower to
--   keep its gap under the shorter post top (set left undecided by the survey; floats 2-5 yd from the new post
--   otherwise)
UPDATE `gameobject` SET `position_x` = -8538.875, `position_y` = 679.387, `position_z` = 96.587, `orientation` = 0.689404 WHERE `guid` = 26521 AND `id` = 2140;
-- Firework Launcher, Cluster Launcher: Lunar Festival launcher on the Old Town canal-gate deck: same spot, the CoA
--   plank deck (A01Sw_Oldtown top 96.75) replaced the stock platform 96.34, so it sat 0.41 yd inside the planks
UPDATE `gameobject` SET `position_x` = -8748.35, `position_y` = 523.169, `position_z` = 96.748, `orientation` = -2.18166 WHERE `guid` = 30804 AND `id` = 180771;
UPDATE `gameobject` SET `position_x` = -8747.45, `position_y` = 524.756, `position_z` = 96.748, `orientation` = -2.16421 WHERE `guid` = 29481 AND `id` = 180772;
UPDATE `gameobject` SET `position_x` = -8746.53, `position_y` = 526.208, `position_z` = 96.748, `orientation` = -2.16421 WHERE `guid` = 29449 AND `id` = 180772;
-- Firework Launcher: Lunar Festival launcher on the Old Town canal-gate deck: its stock spot is inside a raised deck
--   block (98.6) at the CoA deck edge, walled 8/8; moved 2.4 yd onto open planks (top 96.74) behind 30804, keeping the
--   four launchers together on the deck
UPDATE `gameobject` SET `position_x` = -8750.2, `position_y` = 524, `position_z` = 96.739, `orientation` = -2.16421 WHERE `guid` = 29441 AND `id` = 180771;
-- Officer Brady 79768 path node 87: stock bank node is outside the CoA vault hall (terrain behind the vault door or
--   beside it); moved to the hall entry gap beside Stormwind_Vault_Door (the point Officer Pomeroy's path 904840
--   uses), the only way from the entrance hall (99.52) into the raised hall (100.23)
UPDATE `waypoint_data` SET `position_x` = -8919, `position_y` = 622, `position_z` = 100.225 WHERE `id` = 797680 AND `point` = 87;
-- Officer Brady 79768 path node 88: same vault hall corner, 1 yd west so the leg from the entry gap clears the hall
--   pillar; z on the CoA hall floor 100.23
UPDATE `waypoint_data` SET `position_x` = -8922.2, `position_y` = 610, `position_z` = 100.226 WHERE `id` = 797680 AND `point` = 88;
-- Officer Brady 79768 path node 89, Officer Brady 79768 path node 90, Officer Brady 79768 path node 91: same bank hall
--   spot; the CoA raised vault hall floor is 100.23 (stock bank floor 99.52)
UPDATE `waypoint_data` SET `position_x` = -8923.15, `position_y` = 610.629, `position_z` = 100.226 WHERE `id` = 797680 AND `point` = 89;
UPDATE `waypoint_data` SET `position_x` = -8930.54, `position_y` = 624.345, `position_z` = 100.226 WHERE `id` = 797680 AND `point` = 90;
UPDATE `waypoint_data` SET `position_x` = -8929.51, `position_y` = 625.844, `position_z` = 100.226 WHERE `id` = 797680 AND `point` = 91;
-- Officer Brady 79768 path node 92: stock bank node is behind the CoA vault door (terrain 98.4, unreachable); moved to
--   the hall exit at the gap (Pomeroy's point), so the patrol leaves the hall the way it came
UPDATE `waypoint_data` SET `position_x` = -8921, `position_y` = 623, `position_z` = 100.226 WHERE `id` = 797680 AND `point` = 92;
-- Officer Brady 79768 path node 93: leg from the hall exit ran through the CoA vault door model; node moved to the
--   entrance-hall side of the gap (Pomeroy's point)
UPDATE `waypoint_data` SET `position_x` = -8911, `position_y` = 624, `position_z` = 99.525 WHERE `id` = 797680 AND `point` = 93;
-- Lil Timmy SmartAI path node 57: same spot on the Old Town canal bridge deck; CoA bridge surface 101.767 (the arched
--   CoA bridge replaced the stock deck at 101.11)
UPDATE `waypoints` SET `position_x` = -8729.84, `position_y` = 539.87, `position_z` = 101.767 WHERE `entry` = 8666 AND `pointid` = 57;
-- Lil Timmy SmartAI path node 58: same spot on the Old Town canal bridge deck; CoA bridge surface 101.479 (the arched
--   CoA bridge replaced the stock deck at 100.84)
UPDATE `waypoints` SET `position_x` = -8735.95, `position_y` = 547.101, `position_z` = 101.479 WHERE `entry` = 8666 AND `pointid` = 58;
-- Lil Timmy SmartAI path node 59: same spot on the bridge foot at the Old Town canal; CoA bridge surface 98.322 (the
--   arched CoA bridge replaced the stock deck at 97.71)
UPDATE `waypoints` SET `position_x` = -8745.79, `position_y` = 557.737, `position_z` = 98.322 WHERE `entry` = 8666 AND `pointid` = 59;
-- Lil Timmy SmartAI path node 74: same spot on the Trade District canal bridge deck; CoA bridge surface 100.749 (the
--   arched CoA bridge replaced the stock deck at 101.65)
UPDATE `waypoints` SET `position_x` = -8734.46, `position_y` = 720.119, `position_z` = 100.749 WHERE `entry` = 8666 AND `pointid` = 74;
-- Grandmaster's Training Dummy: playtest: out of the Old Town square onto the edge of the training field; its stock
--   spot on the grass edge by the SI:7 wall, set on the ground
UPDATE `creature` SET `position_x` = -8705.84, `position_y` = 350.535, `position_z` = 100.522, `orientation` = 3.206 WHERE `guid` = 201235 AND `id` = 31144;
-- Mailbox: Cathedral Square canal mailbox; same spot, CoA floor 99.82 (sat 0.30 yd sunk)
UPDATE `gameobject` SET `position_x` = -8620.95, `position_y` = 929.647, `position_z` = 99.822, `orientation` = 3.86591 WHERE `guid` = 150742 AND `id` = 195612;
-- Stormwind City Guard: Cathedral canal guard; same post, z on the corrected CoA terrain (sat 0.37 yd sunk)
UPDATE `creature` SET `position_x` = -8643.52, `position_y` = 808.983, `position_z` = 97.027, `orientation` = 5.3478 WHERE `guid` = 190 AND `id` = 68;
-- White Kitten: Lil Timmy's white kitten; same spot, z on the corrected CoA terrain with its stock 0.1 yd offset
--   (floated 0.56)
UPDATE `creature` SET `position_x` = -8632.05, `position_y` = 921.279, `position_z` = 99.024, `orientation` = 3.8978 WHERE `guid` = 23427 AND `id` = 7386;
-- Billy: Billy at the Old Town canal-gate deck; same spot, CoA plank deck top 96.74 with his stock 0.1 yd offset (sat
--   0.3 yd in the planks)
UPDATE `creature` SET `position_x` = -8745.93, `position_y` = 534.749, `position_z` = 96.839, `orientation` = 0.994838 WHERE `guid` = 79700 AND `id` = 1367;
-- Doc Mixilpixil SmartAI path node 1, Doc Mixilpixil SmartAI path node 2, Doc Mixilpixil SmartAI path node 3: quest
--   2608: Doc Mixilpixil's walk (actionlist 720700 starts path 7207 on quest taken; node 3 credits the closest player
--   within 5 yd) stayed in the stock SI:7 room, 12 yd under CoA's Command Center floor; moved with him by the SI:7
--   rigid transform (rot +104.8 deg, translation fitted on the 19 SI:7 rows, spread 0.007 yd) onto the
--   A01Sw_Oldtown_Si7 floor 93.958: node 1 by Horatio Montgomery's portrait, node 3 on his spawn; legs clear at +0.5
--   and +1.5 yd, room open 5 yd round node 3
UPDATE `waypoints` SET `position_x` = -8711.21, `position_y` = 325.49, `position_z` = 93.958 WHERE `entry` = 7207 AND `pointid` = 1;
UPDATE `waypoints` SET `position_x` = -8699.01, `position_y` = 329.9, `position_z` = 93.958 WHERE `entry` = 7207 AND `pointid` = 2;
UPDATE `waypoints` SET `position_x` = -8704.82, `position_y` = 326.9, `position_z` = 93.958 WHERE `entry` = 7207 AND `pointid` = 3;
-- Food Crate: lootable food crate that now stands inside CoA's SI:7; same spot, z on the A01Sw_Oldtown_Si7 floor
--   101.945 (floated 0.34)
UPDATE `gameobject` SET `position_x` = -8699, `position_y` = 341.685, `position_z` = 101.945, `orientation` = -3.07178 WHERE `guid` = 26554 AND `id` = 3662;
-- Hanging, Square, Medium - MFF: deleted; Midsummer lantern hung over the stock Old Town canal bridge; CoA filled that
--   canal and built a larger gate arch there, the lantern point is 0.2 yd inside the arch on 7 of 16 rays; decorative
DELETE FROM `gameobject` WHERE `guid` IN (53045);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room upper floor 106.52
DELETE FROM `gameobject` WHERE `guid` IN (61890, 61889, 61891, 61887);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room doorway; now 4.4 yd above the CoA outside stair
DELETE FROM `gameobject` WHERE `guid` IN (11043);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room doorway; now 4.2 yd above the CoA outside stair
DELETE FROM `gameobject` WHERE `guid` IN (11040);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room lower library 96.69; now 4.9 yd under CoA terrain
DELETE FROM `gameobject` WHERE `guid` IN (11062);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room lower library 96.69; now 5.2 yd under CoA terrain
DELETE FROM `gameobject` WHERE `guid` IN (11063);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room lower library 96.69; now 3.2 yd under CoA terrain
DELETE FROM `gameobject` WHERE `guid` IN (61915);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room lower library 96.69; now 3.7 yd under CoA terrain
DELETE FROM `gameobject` WHERE `guid` IN (61917);
-- Wooden Chair: deleted; decorative chair (type 7, no NPC sits on it) of the Cathedral west side room, which CoA
--   removed (its doodads are gone, open ground 97-99): west room lower library 96.69; now 5.3 yd under CoA terrain
DELETE FROM `gameobject` WHERE `guid` IN (11061, 11060);
-- Command Center, Champions' Hall, SI:7: deleted; decorative pointer arms of the stock Woodsignpostnice01 at (-8729.6,
--   406.2) by the SI:7 and Command Center yard: CoA removed that post and has no signpost within 60 yd, so the arms
--   hang in open air
DELETE FROM `gameobject` WHERE `guid` IN (26549, 26551, 26552);

-- ---------------------------------------------------------------------------
-- 4. Trade District: bank, shops, canal quays, street lamps
-- ---------------------------------------------------------------------------
-- John Burnside: banker: stock counter end is open courtyard in CoA (no WMO face); placed in CoA bank hall's west
--   teller aisle between counter and desks, facing the counter
UPDATE `creature` SET `position_x` = -8908, `position_y` = 640.5, `position_z` = 99.559, `orientation` = 5.13 WHERE `guid` = 79853 AND `id` = 2457;
-- Stormwind City Guard: Trade District south entrance, same arch pier at his back; CoA street 0.81 higher
UPDATE `creature` SET `position_x` = -8888.17, `position_y` = 566.202, `position_z` = 93.347, `orientation` = 2.23402 WHERE `guid` = 79669 AND `id` = 68;
-- Event Generator 001: invisible trigger (no AI, scripts or links) left on stock placeholder terrain 20.8 under the
--   CoA street; same x,y on the street
UPDATE `creature` SET `position_x` = -8834.14, `position_y` = 552.277, `position_z` = 95.957, `orientation` = 0.33161 WHERE `guid` = 79667 AND `id` = 2334;
-- Argent Recruiter: Scourge Invasion recruiter beside the Emissary; square 0.40 higher (corrected terrain)
UPDATE `creature` SET `position_x` = -8832.87, `position_y` = 642.782, `position_z` = 95.209, `orientation` = 4.45059 WHERE `guid` = 12863 AND `id` = 16241;
-- Argent Emissary: QuestSuperTrack 12616 turn-in point (stock spot 3.1 yd off); z on the CoA square
UPDATE `creature` SET `position_x` = -8831.79, `position_y` = 637.85, `position_z` = 94.9, `orientation` = 4.2237 WHERE `guid` = 12864 AND `id` = 16285;
-- [DND] TAR Pedestal - Arena Organizer: Arena Tournament pedestal on the square; street 0.47 higher
UPDATE `creature` SET `position_x` = -8822.71, `position_y` = 626.831, `position_z` = 94.356, `orientation` = 3.38594 WHERE `guid` = 96058 AND `id` = 26747;
-- Catherine Leland: fishing-supply vendor: CoA's canal fishing pier sits 2-4 yd further west and her stock spot is
--   water; on the pier tip beside Arnold Leland (fits, 2.2 yd)
UPDATE `creature` SET `position_x` = -8803.2, `position_y` = 769.6, `position_z` = 96.338, `orientation` = 3.1765 WHERE `guid` = 79835 AND `id` = 5494;
-- Rat: rat wandering the square; street 0.42 higher
UPDATE `creature` SET `position_x` = -8798.09, `position_y` = 659.555, `position_z` = 96.669, `orientation` = 4.25555 WHERE `guid` = 120819 AND `id` = 4075;
-- [DND] Love Boat Summoner: invisible Love Boat summoner: CoA's longer pier arm (96.34) now covers its spot; moved 4
--   yd west to open canal water beyond the pier tip, same height
UPDATE `creature` SET `position_x` = -8796.02, `position_y` = 779, `position_z` = 95.223, `orientation` = 0.01745 WHERE `guid` = 52032 AND `id` = 36817;
-- Donna: follows William (formation) on the Old Town canal bridge; floor 0.73 higher
UPDATE `creature` SET `position_x` = -8744.68, `position_y` = 556.069, `position_z` = 98.778, `orientation` = 5.45979 WHERE `guid` = 79721 AND `id` = 2532;
-- William: walks path 797200 (no node off the CoA floor); bridge floor 0.55 higher
UPDATE `creature` SET `position_x` = -8739.04, `position_y` = 549.987, `position_z` = 100.821, `orientation` = 5.45979 WHERE `guid` = 79720 AND `id` = 2533;
-- Stormwind City Guard: stock post on the canal island platform is open water in CoA (level 95.5); on the south quay
--   corner looking down the channel toward Old Town as before
UPDATE `creature` SET `position_x` = -8699.3, `position_y` = 600.7, `position_z` = 99.31, `orientation` = 3.80482 WHERE `guid` = 79733 AND `id` = 68;
-- Stormwind City Guard: partner of 79733 on the south quay corner, side by side 4 yd apart, same facing
UPDATE `creature` SET `position_x` = -8697.5, `position_y` = 604.3, `position_z` = 99.426, `orientation` = 3.80482 WHERE `guid` = 79731 AND `id` = 68;
-- Stormwind City Guard: stock post at the island's west corner is open water; on the south quay promenade facing the
--   Trade District as before (oldtown 79730 was his partner)
UPDATE `creature` SET `position_x` = -8695.5, `position_y` = 637.5, `position_z` = 100.36, `orientation` = 2.19912 WHERE `guid` = 79732 AND `id` = 68;
-- Olivia Burnside: fits-class, optional (accept together with 79853): Olivia Burnside stands in the open courtyard;
--   beside John in the hall teller aisle
UPDATE `creature` SET `position_x` = -8904.2, `position_y` = 642.3, `position_z` = 99.541, `orientation` = 5.13 WHERE `guid` = 79684 AND `id` = 2455;
-- Newton Burnside: fits-class, optional (accept together with 79853): Newton Burnside stands in the open courtyard;
--   beside John in the hall teller aisle
UPDATE `creature` SET `position_x` = -8911, `position_y` = 639, `position_z` = 99.557, `orientation` = 5.13 WHERE `guid` = 79678 AND `id` = 2456;
-- Stone Bench: vault wing north arm floor 100.23 (0.7 above stock); nudged 1.3 yd so the backrest no longer hangs off
--   the arm's edge
UPDATE `gameobject` SET `position_x` = -8935.4, `position_y` = 626.6, `position_z` = 100.226, `orientation` = 5.21854 WHERE `guid` = 26678 AND `id` = 24532;
-- Stone Bench: vault wing north arm, same spot; floor 0.66 higher
UPDATE `gameobject` SET `position_x` = -8930.02, `position_y` = 631.193, `position_z` = 100.226, `orientation` = 5.21854 WHERE `guid` = 26680 AND `id` = 24533;
-- Wooden Chair: vault wing north arm, same spot; floor 0.70 higher
UPDATE `gameobject` SET `position_x` = -8933.21, `position_y` = 627.349, `position_z` = 100.226, `orientation` = 1.69297 WHERE `guid` = 26681 AND `id` = 17267;
UPDATE `gameobject` SET `position_x` = -8931.5, `position_y` = 628.361, `position_z` = 100.226, `orientation` = 2.61799 WHERE `guid` = 26682 AND `id` = 17265;
-- Wooden Chair: CoA's Laughlin room floor ends at y 617 (terrain crack under the hall wall); moved 2.8 yd along its
--   facing onto the room floor by its table
UPDATE `gameobject` SET `position_x` = -8887.9, `position_y` = 616.4, `position_z` = 95.258, `orientation` = 5.20981 WHERE `guid` = 26315 AND `id` = 24490;
-- Wooden Chair: upper floor of the same building, 0.75 lower in CoA
UPDATE `gameobject` SET `position_x` = -8885.36, `position_y` = 613.676, `position_z` = 101.558, `orientation` = 3.63901 WHERE `guid` = 26311 AND `id` = 24492;
-- Guild Vault: guild bank: stock spot is inside CoA's west teller counter; on the customer floor, back to the counter
UPDATE `gameobject` SET `position_x` = -8909.89, `position_y` = 633.63, `position_z` = 99.611, `orientation` = 5.13, `rotation2` = 0.545171, `rotation3` = -0.838325 WHERE `guid` = 41912 AND `id` = 187329;
-- Guild Vault: guild bank: stock spot is inside CoA's east teller counter; on the customer floor, back to the counter
UPDATE `gameobject` SET `position_x` = -8902.52, `position_y` = 624.78, `position_z` = 99.527, `orientation` = 1.737, `rotation2` = 0.763361, `rotation3` = 0.645972 WHERE `guid` = 41914 AND `id` = 187329;
-- Guild Vault: guild bank: stock banker end is open courtyard; into CoA's bank hall along the west counter
UPDATE `gameobject` SET `position_x` = -8904.59, `position_y` = 636.29, `position_z` = 99.599, `orientation` = 5.13, `rotation2` = 0.545171, `rotation3` = -0.838325 WHERE `guid` = 41911 AND `id` = 187329;
-- Guild Vault: guild bank: stock banker end is open courtyard; into CoA's bank hall along the east counter
UPDATE `gameobject` SET `position_x` = -8910, `position_y` = 621.5, `position_z` = 99.525, `orientation` = 1.737, `rotation2` = 0.763361, `rotation3` = 0.645972 WHERE `guid` = 41913 AND `id` = 187329;
-- Human Hero Portrait: hung on the wall behind the stock bankers (gone, now open courtyard); re-hung on CoA's hall
--   back wall behind the relocated bankers, 3.2 above the floor as before
UPDATE `gameobject` SET `position_x` = -8910.29, `position_y` = 645.65, `position_z` = 102.75, `orientation` = 5.13, `rotation2` = 0.545171, `rotation3` = -0.838325 WHERE `guid` = 29475 AND `id` = 180757;
-- Christmas Tree (Medium): Winter Veil tree on the Laughlin building's upper floor: floor 0.75 lower and its edge
--   moved; tree group moved rigidly (+4.02,-5.43) to mid-floor
UPDATE `gameobject` SET `position_x` = -8889.5, `position_y` = 612, `position_z` = 101.558, `orientation` = 0.38397 WHERE `guid` = 40917 AND `id` = 178667;
-- 6 rows: gift of the upstairs tree group, same rigid move (+4.02,-5.43)
UPDATE `gameobject` SET `position_x` = -8890.72, `position_y` = 611.57, `position_z` = 101.558, `orientation` = 1.36136 WHERE `guid` = 40913 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -8890.46, `position_y` = 612.5, `position_z` = 101.558, `orientation` = 5.46288 WHERE `guid` = 40915 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -8890.18, `position_y` = 610.56, `position_z` = 101.558, `orientation` = 4.36332 WHERE `guid` = 40911 AND `id` = 178428;
UPDATE `gameobject` SET `position_x` = -8889.46, `position_y` = 613.07, `position_z` = 101.558, `orientation` = 1.36136 WHERE `guid` = 41517 AND `id` = 178429;
UPDATE `gameobject` SET `position_x` = -8888.84, `position_y` = 611.11, `position_z` = 101.558, `orientation` = 5.49779 WHERE `guid` = 41516 AND `id` = 178430;
UPDATE `gameobject` SET `position_x` = -8888.67, `position_y` = 612.35, `position_z` = 101.558, `orientation` = 3.21142 WHERE `guid` = 40920 AND `id` = 178431;
-- Banner: standing Lunar banner against the same canal-side wall; ground 0.92 higher
UPDATE `gameobject` SET `position_x` = -8852.96, `position_y` = 722.764, `position_z` = 97.974, `orientation` = 5.23599 WHERE `guid` = 19759 AND `id` = 180777;
-- Standing, Exterior, Medium - MFF: stood on the Mage Quarter bridge parapet end; CoA's parapet is 1.5 higher and 2 yd
--   east; on its top
UPDATE `gameobject` SET `position_x` = -8861.2, `position_y` = 737.9, `position_z` = 102.944, `orientation` = 0.97738 WHERE `guid` = 51674 AND `id` = 181355;
-- Standing, Exterior, Medium - MFF: other parapet end of the same bridge; CoA's parapet 1.4 higher and 1 yd west; on
--   its top
UPDATE `gameobject` SET `position_x` = -8852.6, `position_y` = 745.8, `position_z` = 103.12, `orientation` = 1.74533 WHERE `guid` = 51905 AND `id` = 181355;
-- Lights, Lights x3: hangs under the canal arch; CoA soffit 0.60 lower, keeps the stock 1.34 gap
UPDATE `gameobject` SET `position_x` = -8764.17, `position_y` = 724.286, `position_z` = 103.615, `orientation` = 3.89209 WHERE `guid` = 29443 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8764.17, `position_y` = 724.286, `position_z` = 103.615, `orientation` = 3.89209 WHERE `guid` = 40946 AND `id` = 178645;
-- Banner: hanging Lunar banner on the canal arch face; CoA's face is 0.69 south-east of the stock point; moved onto it
UPDATE `gameobject` SET `position_x` = -8763.75, `position_y` = 724.51, `position_z` = 104.229, `orientation` = 0.68068 WHERE `guid` = 19707 AND `id` = 180773;
-- Wreath scale 0.75: wreath on the canal arch face; CoA's face is 0.69 south-east of the stock point; moved onto it
UPDATE `gameobject` SET `position_x` = -8763.75, `position_y` = 724.51, `position_z` = 107, `orientation` = 0.68068 WHERE `guid` = 41668 AND `id` = 178649;
-- Hanging, Square, Medium - MFF, Hanging, Square, Medium - Brewfest, Hanging, Square, Medium - Val: ribbon standing
--   4.5 up from its base; CoA's facade leans over it (111.7 at the base, clear from +1.0); moved 1.3 out
UPDATE `gameobject` SET `position_x` = -8744.28, `position_y` = 694.46, `position_z` = 110.7, `orientation` = 0.62832 WHERE `guid` = 53031 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -8744.28, `position_y` = 694.46, `position_z` = 110.7, `orientation` = 0.62832 WHERE `guid` = 80615 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -8744.28, `position_y` = 694.46, `position_z` = 110.7, `orientation` = 0.62832 WHERE `guid` = 241169 AND `id` = 181020;
-- Hanging, Square, Medium - MFF, Hanging, Square, Medium - Brewfest, Hanging, Square, Medium - Val: ribbon standing
--   4.5 up from its base; CoA's facade leans over it (110.7 at the base, clear from +0.5); moved 1.2 out
UPDATE `gameobject` SET `position_x` = -8741.65, `position_y` = 579.87, `position_z` = 109.82, `orientation` = 5.49779 WHERE `guid` = 52969 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -8741.65, `position_y` = 579.87, `position_z` = 109.82, `orientation` = -0.7854 WHERE `guid` = 80632 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -8741.65, `position_y` = 579.87, `position_z` = 109.82, `orientation` = -0.7854 WHERE `guid` = 241170 AND `id` = 181020;
-- Hanging, Square, Medium - MFF, Hanging, Square, Medium - Brewfest, Hanging, Square, Medium - Val: ribbon standing
--   4.5 up from its base; CoA's facade leans over it (110.8 at the base, clear from +0.5); moved 1.2 out
UPDATE `gameobject` SET `position_x` = -8841.97, `position_y` = 715.41, `position_z` = 109.501, `orientation` = 2.02458 WHERE `guid` = 53010 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -8841.97, `position_y` = 715.41, `position_z` = 109.501, `orientation` = 2.02458 WHERE `guid` = 80637 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -8841.97, `position_y` = 715.41, `position_z` = 109.501, `orientation` = 2.02458 WHERE `guid` = 241168 AND `id` = 181020;
-- Lights x3, Lights: hangs under the Dwarven District arch; CoA soffit 0.60 lower, keeps the stock 1.26 gap
UPDATE `gameobject` SET `position_x` = -8563.6, `position_y` = 604.25, `position_z` = 108.757, `orientation` = 5.37562 WHERE `guid` = 1883 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -8563.6, `position_y` = 604.25, `position_z` = 108.757, `orientation` = 5.37562 WHERE `guid` = 30356 AND `id` = 180770;
-- Smokywood Pastures: Smokywood Pastures post sign on the square; ground 0.34 higher
UPDATE `gameobject` SET `position_x` = -8809.42, `position_y` = 640.168, `position_z` = 94.568, `orientation` = 2.89725 WHERE `guid` = 41666 AND `id` = 178746;
-- XMasGift03: Winter Veil gift among the others (fits) at the stall; ground 0.36 higher
UPDATE `gameobject` SET `position_x` = -8806.37, `position_y` = 643.382, `position_z` = 94.588, `orientation` = 2.1293 WHERE `guid` = 41521 AND `id` = 178430;
-- Lights, Lights x3: hangs under an arch on the square; CoA soffit 0.60 lower, keeps the stock 1.34 gap
UPDATE `gameobject` SET `position_x` = -8802.43, `position_y` = 620.403, `position_z` = 100.854, `orientation` = 2.25147 WHERE `guid` = 29477 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8802.43, `position_y` = 620.403, `position_z` = 100.854, `orientation` = 2.25147 WHERE `guid` = 40933 AND `id` = 178645;
-- Lights, Lights x3: hangs under an arch on the square; CoA soffit 0.60 lower, keeps the stock 1.41 gap
UPDATE `gameobject` SET `position_x` = -8854.35, `position_y` = 617.13, `position_z` = 99.996, `orientation` = 5.09636 WHERE `guid` = 29516 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8854.35, `position_y` = 617.13, `position_z` = 99.996, `orientation` = 5.09636 WHERE `guid` = 40914 AND `id` = 178645;
-- Lights: flush on the facade in stock; CoA's facade stands 0.4 further into the street and encloses it; onto its
--   street face
UPDATE `gameobject` SET `position_x` = -8852.48, `position_y` = 667.6, `position_z` = 100.272, `orientation` = 5.35816 WHERE `guid` = 29486 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -8852.48, `position_y` = 667.6, `position_z` = 100.272, `orientation` = 5.35816 WHERE `guid` = 40942 AND `id` = 178438;
-- Lights: flush on the facade in stock; CoA's facade stands 0.35 further into the street and encloses it; onto its
--   street face
UPDATE `gameobject` SET `position_x` = -8855.96, `position_y` = 665.08, `position_z` = 100.26, `orientation` = 5.2709 WHERE `guid` = 31171 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -8855.96, `position_y` = 665.08, `position_z` = 100.26, `orientation` = 5.2709 WHERE `guid` = 40934 AND `id` = 178438;
-- Lights: flush on the square's NW facade in stock; CoA's facade is 1.1 further back (under its cornice); onto it
UPDATE `gameobject` SET `position_x` = -8837.19, `position_y` = 654.3, `position_z` = 100.943, `orientation` = 3.64774 WHERE `guid` = 29439 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -8837.19, `position_y` = 654.3, `position_z` = 100.943, `orientation` = 3.64774 WHERE `guid` = 40907 AND `id` = 178438;
-- Lights: flush on the square's NW facade in stock; CoA's facade is 1.2 further back (under its cornice); onto it
UPDATE `gameobject` SET `position_x` = -8834.49, `position_y` = 649.83, `position_z` = 100.795, `orientation` = 3.71755 WHERE `guid` = 31177 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -8834.49, `position_y` = 649.83, `position_z` = 100.795, `orientation` = 3.71755 WHERE `guid` = 40918 AND `id` = 178438;
-- Wreath: wreath flush on the square's NW facade in stock; CoA's facade is 1.0 further back; onto it
UPDATE `gameobject` SET `position_x` = -8837.83, `position_y` = 655.18, `position_z` = 110.863, `orientation` = 3.73501 WHERE `guid` = 41667 AND `id` = 178437;
-- Lights: flush on the square's south building corner in stock; CoA's corner is 0.9 back (under its ledge); onto it
UPDATE `gameobject` SET `position_x` = -8837.84, `position_y` = 599.98, `position_z` = 98.274, `orientation` = 2.44346 WHERE `guid` = 31202 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -8837.84, `position_y` = 599.98, `position_z` = 98.274, `orientation` = 2.44346 WHERE `guid` = 40908 AND `id` = 178438;
-- Lights: flush on the square's south facade in stock; CoA's facade is 0.85 back (under its ledge); onto it
UPDATE `gameobject` SET `position_x` = -8834.93, `position_y` = 603.53, `position_z` = 98.397, `orientation` = 2.53072 WHERE `guid` = 29480 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -8834.93, `position_y` = 603.53, `position_z` = 98.397, `orientation` = 2.53072 WHERE `guid` = 40909 AND `id` = 178438;
-- Wreath: wreath flush on the facade east of the bank in stock; CoA's facade line is 1.1 further west; onto it
UPDATE `gameobject` SET `position_x` = -8882.92, `position_y` = 602.35, `position_z` = 107.546, `orientation` = 5.21854 WHERE `guid` = 41663 AND `id` = 178437;
-- Wreath: wreath hung 1.81 off the square's south arch; CoA's arch is 2.3 thicker and swallows it; kept 1.81 off its
--   face
UPDATE `gameobject` SET `position_x` = -8863.65, `position_y` = 577.47, `position_z` = 109.647, `orientation` = 2.35619 WHERE `guid` = 41660 AND `id` = 178437;
-- Lights, Lights x3: hung 0.87 off the south arch; CoA's arch face reaches it; kept 0.87 off
UPDATE `gameobject` SET `position_x` = -8861.14, `position_y` = 576.6, `position_z` = 103.94, `orientation` = 2.33874 WHERE `guid` = 29489 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8861.14, `position_y` = 576.6, `position_z` = 103.94, `orientation` = 2.33874 WHERE `guid` = 40905 AND `id` = 178645;
-- Lights, Lights x3: hung 0.90 off the south arch; CoA's arch encloses it by 0.25; kept 0.90 off its face
UPDATE `gameobject` SET `position_x` = -8869.14, `position_y` = 565.94, `position_z` = 107.274, `orientation` = 2.26893 WHERE `guid` = 29451 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -8869.14, `position_y` = 565.94, `position_z` = 107.274, `orientation` = 2.26893 WHERE `guid` = 40906 AND `id` = 178645;
-- Firecrackers: firecracker string flush on the south arch; CoA's face is 0.3 further out; onto it
UPDATE `gameobject` SET `position_x` = -8865.58, `position_y` = 570.5, `position_z` = 100.54, `orientation` = -1.01229 WHERE `guid` = 31237 AND `id` = 180763;
-- Firecrackers: hung from a stock street lamp that CoA replaced with Stormwind_Streetlamp_02 4 yd north; hangs at the
--   new lamp, string bottom 0.1 above the street
UPDATE `gameobject` SET `position_x` = -8842.55, `position_y` = 621.6, `position_z` = 93.61, `orientation` = -1.3439 WHERE `guid` = 31234 AND `id` = 180764;
UPDATE `gameobject` SET `position_x` = -8842.55, `position_y` = 621.6, `position_z` = 93.61, `orientation` = -1.3439 WHERE `guid` = 31243 AND `id` = 180763;
-- Firecrackers: hung from a stock fixture that CoA replaced with Stormwind_Streetlamp_02 3.5 yd south-west; hangs at
--   the new lamp, string bottom 0.1 above the street
UPDATE `gameobject` SET `position_x` = -8812.1, `position_y` = 616.95, `position_z` = 94.97, `orientation` = 2.32129 WHERE `guid` = 31238 AND `id` = 180763;
-- G_Pumpkin_01: in the same planter; soil 0.08 higher
UPDATE `gameobject` SET `position_x` = -8836.54, `position_y` = 602.794, `position_z` = 95.869, `orientation` = 4.41568 WHERE `guid` = 36177 AND `id` = 180405;
-- G_Pumpkin_01: sat in a stock lamp-base planter that CoA removed; a CoA step now runs through its spot and the new
--   Stormwind_Streetlamp_02 stands 3 yd south; on the paving just south-east of the new lamp, clear of the Fireworks
--   tables
UPDATE `gameobject` SET `position_x` = -8858.2, `position_y` = 581.4, `position_z` = 94.468, `orientation` = 4.32842 WHERE `guid` = 36178 AND `id` = 180405;
-- G_Pumpkin_02: sat in a stock planter that CoA removed; its spot is now a street ramp (slope 21, corrected terrain);
--   moved 6 yd to flat ground at the foot of the ramp
UPDATE `gameobject` SET `position_x` = -8798.5, `position_y` = 648.6, `position_z` = 94.621, `orientation` = 0.08727 WHERE `guid` = 36620 AND `id` = 180406;
-- Collision PC Size: invisible collision box of TAR pedestal 96058; follows it
UPDATE `gameobject` SET `position_x` = -8822.71, `position_y` = 626.831, `position_z` = 94.356, `orientation` = -2.89725 WHERE `guid` = 31398 AND `id` = 188215;
-- 5 rows: fits-class arm (mage-park request): pointer arm of the Trade District square signpost; CoA replaced
--   Woodsignpostnice01 (top 100.457) with Humansignpost03 (top 98.968) at (-8829.842,615.514); arm set moved with the
--   post by (-0.168,-0.504), z -1.489, orientation kept
UPDATE `gameobject` SET `position_x` = -8830.648, `position_y` = 616.532, `position_z` = 92.073, `orientation` = 0.67195 WHERE `guid` = 26297 AND `id` = 2124;
UPDATE `gameobject` SET `position_x` = -8828.828, `position_y` = 616.324, `position_z` = 92.673, `orientation` = 5.38434 WHERE `guid` = 26299 AND `id` = 2110;
UPDATE `gameobject` SET `position_x` = -8830.908, `position_y` = 614.668, `position_z` = 91.549, `orientation` = 2.24275 WHERE `guid` = 26309 AND `id` = 28035;
UPDATE `gameobject` SET `position_x` = -8829.028, `position_y` = 614.494, `position_z` = 92.073, `orientation` = -2.46964 WHERE `guid` = 26312 AND `id` = 2112;
UPDATE `gameobject` SET `position_x` = -8830.858, `position_y` = 614.703, `position_z` = 92.673, `orientation` = 2.24275 WHERE `guid` = 26313 AND `id` = 2142;
-- 4 rows: fits-class arm (mage-park request): pointer arm of the Old Town canal bridge signpost; CoA replaced
--   Woodsignpostnice01 (top 103.889) with Humansignpost03 (top 102.771) at (-8750.42,549.172); arm set moved with the
--   post by (+0.998,-1.943), z -1.118, orientation kept
UPDATE `gameobject` SET `position_x` = -8751.452, `position_y` = 549.965, `position_z` = 95.875, `orientation` = 0.9163 WHERE `guid` = 26335 AND `id` = 2111;
UPDATE `gameobject` SET `position_x` = -8749.382, `position_y` = 548.379, `position_z` = 95.875, `orientation` = -2.2253 WHERE `guid` = 26336 AND `id` = 2119;
UPDATE `gameobject` SET `position_x` = -8751.452, `position_y` = 549.965, `position_z` = 94.666, `orientation` = 0.9163 WHERE `guid` = 26338 AND `id` = 28036;
UPDATE `gameobject` SET `position_x` = -8749.622, `position_y` = 550.205, `position_z` = 96.475, `orientation` = 5.62869 WHERE `guid` = 26339 AND `id` = 2116;
-- 4 rows: fits-class arm (mage-park request): pointer arm of the Cathedral canal crossing signpost; CoA replaced
--   Woodsignpostnice01 (top 108.133) with Humansignpost03 (top 107.107) at (-8579.469,531.641); arm set moved with the
--   post by (-1.565,-4.269), z -1.026, orientation kept
UPDATE `gameobject` SET `position_x` = -8578.855, `position_y` = 530.491, `position_z` = 100.211, `orientation` = -2.6529 WHERE `guid` = 26455 AND `id` = 2120;
UPDATE `gameobject` SET `position_x` = -8580.075, `position_y` = 532.79, `position_z` = 100.211, `orientation` = 0.48869 WHERE `guid` = 26456 AND `id` = 2129;
UPDATE `gameobject` SET `position_x` = -8580.615, `position_y` = 531.03, `position_z` = 100.811, `orientation` = 2.05949 WHERE `guid` = 26457 AND `id` = 2189;
UPDATE `gameobject` SET `position_x` = -8578.315, `position_y` = 532.252, `position_z` = 100.811, `orientation` = -1.0821 WHERE `guid` = 26458 AND `id` = 28029;
-- 5 rows: fits-class arm (mage-park request): pointer arm of the Cathedral road signpost; CoA replaced
--   Woodsignpostnice01 (top 104.99) with Humansignpost03 (top 103.673) at (-8733.682,707.957); arm set moved with the
--   post by (+2.867,+2.196), z -1.317, orientation kept
UPDATE `gameobject` SET `position_x` = -8734.683, `position_y` = 707.129, `position_z` = 97.378, `orientation` = 2.2602 WHERE `guid` = 26598 AND `id` = 2182;
UPDATE `gameobject` SET `position_x` = -8732.673, `position_y` = 708.785, `position_z` = 97.378, `orientation` = 5.4018 WHERE `guid` = 26599 AND `id` = 2173;
UPDATE `gameobject` SET `position_x` = -8732.853, `position_y` = 706.953, `position_z` = 96.778, `orientation` = -2.45219 WHERE `guid` = 26605 AND `id` = 2113;
UPDATE `gameobject` SET `position_x` = -8734.513, `position_y` = 708.962, `position_z` = 96.778, `orientation` = 0.68941 WHERE `guid` = 26608 AND `id` = 2127;
UPDATE `gameobject` SET `position_x` = -8734.733, `position_y` = 707.095, `position_z` = 96.346, `orientation` = 2.2602 WHERE `guid` = 26611 AND `id` = 28037;
-- Stormwind Gate: fits-class arm (mage-park request): pointer arm of the Mage Quarter bridge signpost; CoA replaced
--   Woodsignpostnice01 (top 103.58) with Humansignpost03 (top 102.515) at (-8841.119,731.96); arm set moved with the
--   post by (-0.744,+2.228), z -1.065, orientation kept
UPDATE `gameobject` SET `position_x` = -8840.474, `position_y` = 730.827, `position_z` = 94.855, `orientation` = -2.62672 WHERE `guid` = 26648 AND `id` = 28043;
-- Mage Quarter: pointer arm of the Mage Quarter bridge signpost; CoA replaced Woodsignpostnice01 (top 103.58) with
--   Humansignpost03 (top 102.515) at (-8841.119,731.96); arm set moved with the post by (-0.744,+2.228), z -1.065,
--   orientation kept
UPDATE `gameobject` SET `position_x` = -8841.764, `position_y` = 733.093, `position_z` = 95.62, `orientation` = 0.51487 WHERE `guid` = 26649 AND `id` = 103793;
-- Cathedral Square, Trade District: fits-class arm (mage-park request): pointer arm of the Mage Quarter bridge
--   signpost; CoA replaced Woodsignpostnice01 (top 103.58) with Humansignpost03 (top 102.515) at (-8841.119,731.96);
--   arm set moved with the post by (-0.744,+2.228), z -1.065, orientation kept
UPDATE `gameobject` SET `position_x` = -8839.984, `position_y` = 732.601, `position_z` = 96.22, `orientation` = 5.22726 WHERE `guid` = 26652 AND `id` = 2134;
UPDATE `gameobject` SET `position_x` = -8840.474, `position_y` = 730.827, `position_z` = 95.942, `orientation` = -2.62672 WHERE `guid` = 26658 AND `id` = 2122;
-- Officer Jaxon path node 107: stock stair node (102.95) now hangs between the street (97.0) and the bank-side deck;
--   the CoA stair here climbs 97.1-106.0 along the same leg, so the node goes on its step at 105.48
UPDATE `waypoint_data` SET `position_x` = -8844.47, `position_y` = 532.401, `position_z` = 105.48 WHERE `id` = 798180 AND `point` = 107;
-- Officer Jaxon path node 132: stock stair node (102.87) now hangs between the street (97.1) and the bank-side deck;
--   on the CoA stair step under it at 105.38
UPDATE `waypoint_data` SET `position_x` = -8843.86, `position_y` = 532.134, `position_z` = 105.375 WHERE `id` = 798180 AND `point` = 132;
-- Officer Jaxon path node 69: stock bank node is outside the CoA vault hall (terrain behind the vault door or beside
--   it); moved to the hall entry gap beside Stormwind_Vault_Door (the point Officer Pomeroy's path 904840 uses), the
--   only way from the entrance hall (99.52) into the raised hall (100.23)
UPDATE `waypoint_data` SET `position_x` = -8919, `position_y` = 622, `position_z` = 100.225 WHERE `id` = 798180 AND `point` = 69;
-- Officer Jaxon path node 70: stock node is on terrain behind the vault hall's north wall; moved into the hall between
--   the entry gap and node 71, clear of the hall pillar
UPDATE `waypoint_data` SET `position_x` = -8924.5, `position_y` = 622.5, `position_z` = 100.226 WHERE `id` = 798180 AND `point` = 70;
-- 4 rows: same bank hall spot; the CoA raised vault hall floor is 100.23 (stock bank floor 99.52)
UPDATE `waypoint_data` SET `position_x` = -8929.66, `position_y` = 625.909, `position_z` = 100.226 WHERE `id` = 798180 AND `point` = 71;
UPDATE `waypoint_data` SET `position_x` = -8930.6, `position_y` = 623.277, `position_z` = 100.226 WHERE `id` = 798180 AND `point` = 72;
UPDATE `waypoint_data` SET `position_x` = -8923.92, `position_y` = 611.298, `position_z` = 100.226 WHERE `id` = 798180 AND `point` = 73;
UPDATE `waypoint_data` SET `position_x` = -8921.12, `position_y` = 610.442, `position_z` = 100.226 WHERE `id` = 798180 AND `point` = 74;
-- Officer Jaxon path node 75: stock bank node is on terrain outside the CoA vault hall; moved to the hall exit at the
--   gap (Pomeroy's point)
UPDATE `waypoint_data` SET `position_x` = -8921, `position_y` = 623, `position_z` = 100.226 WHERE `id` = 798180 AND `point` = 75;
-- Stormwind City Patroller path node 14: stock bank node is outside the CoA vault hall (terrain behind the vault door
--   or beside it); moved to the hall entry gap beside Stormwind_Vault_Door (the point Officer Pomeroy's path 904840
--   uses), the only way from the entrance hall (99.52) into the raised hall (100.23)
UPDATE `waypoint_data` SET `position_x` = -8919, `position_y` = 622, `position_z` = 100.225 WHERE `id` = 797920 AND `point` = 14;
-- Stormwind City Patroller path node 15: same bank hall spot; the CoA raised vault hall floor is 100.23 (stock bank
--   floor 99.52)
UPDATE `waypoint_data` SET `position_x` = -8924.92, `position_y` = 608.284, `position_z` = 100.226 WHERE `id` = 797920 AND `point` = 15;
-- Stormwind City Patroller path node 16: the stock node sits on a 0.44 yd raised plinth edge (100.66) at the west end
--   of the CoA vault hall; moved 1.3 yd onto the hall floor
UPDATE `waypoint_data` SET `position_x` = -8932, `position_y` = 623.6, `position_z` = 100.226 WHERE `id` = 797920 AND `point` = 16;
-- Stormwind City Patroller path node 17: stock bank node is behind the CoA vault door (terrain 98.4, unreachable);
--   moved to the hall exit at the gap (Pomeroy's point), so the patrol leaves the hall the way it came
UPDATE `waypoint_data` SET `position_x` = -8921, `position_y` = 623, `position_z` = 100.226 WHERE `id` = 797920 AND `point` = 17;
-- Stormwind City Patroller path node 45: stock bank node is outside the CoA vault hall (terrain behind the vault door
--   or beside it); moved to the hall entry gap beside Stormwind_Vault_Door (the point Officer Pomeroy's path 904840
--   uses), the only way from the entrance hall (99.52) into the raised hall (100.23)
UPDATE `waypoint_data` SET `position_x` = -8919, `position_y` = 622, `position_z` = 100.225 WHERE `id` = 797920 AND `point` = 45;
-- Stormwind City Patroller path node 46: the stock node sits on a 0.44 yd raised plinth edge (100.66) at the west end
--   of the CoA vault hall; moved 1.3 yd onto the hall floor
UPDATE `waypoint_data` SET `position_x` = -8931.8, `position_y` = 624.2, `position_z` = 100.226 WHERE `id` = 797920 AND `point` = 46;
-- Stormwind City Patroller path node 47: same bank hall spot; the CoA raised vault hall floor is 100.23 (stock bank
--   floor 99.52)
UPDATE `waypoint_data` SET `position_x` = -8924.92, `position_y` = 608.142, `position_z` = 100.226 WHERE `id` = 797920 AND `point` = 47;
-- Stormwind City Patroller path node 48: stock bank node is on terrain outside the CoA vault hall; moved to the hall
--   exit at the gap (Pomeroy's point)
UPDATE `waypoint_data` SET `position_x` = -8921, `position_y` = 623, `position_z` = 100.226 WHERE `id` = 797920 AND `point` = 48;
-- 5 rows: Winter Veil gift in the pile by the gypsy wagon; same spot, z on the CoA street terrain like its pile-mate
--   41521 (it sat 0.4 yd sunk)
UPDATE `gameobject` SET `position_x` = -8807.29, `position_y` = 644.759, `position_z` = 94.621, `orientation` = 3.56047 WHERE `guid` = 40925 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -8807, `position_y` = 646.121, `position_z` = 94.639, `orientation` = 3.64774 WHERE `guid` = 40926 AND `id` = 178428;
UPDATE `gameobject` SET `position_x` = -8808.33, `position_y` = 646.38, `position_z` = 94.663, `orientation` = 3.87463 WHERE `guid` = 40927 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = -8807.76, `position_y` = 645.652, `position_z` = 94.64, `orientation` = 4.03171 WHERE `guid` = 40928 AND `id` = 178428;
UPDATE `gameobject` SET `position_x` = -8806.59, `position_y` = 645.342, `position_z` = 94.621, `orientation` = 3.73501 WHERE `guid` = 41522 AND `id` = 178429;
-- Standing, Large - MFF, Standing, Large - Brewfest, Standing, Large - Val: holiday crate at the Trade District south
--   entrance; same spot on the street, CoA terrain 93.29 (stock floor 92.83; sat 0.46 yd sunk)
UPDATE `gameobject` SET `position_x` = -8884.23, `position_y` = 566.347, `position_z` = 93.292, `orientation` = 0.715585 WHERE `guid` = 42275 AND `id` = 181300;
UPDATE `gameobject` SET `position_x` = -8884.23, `position_y` = 566.347, `position_z` = 93.292, `orientation` = 0.715585 WHERE `guid` = 80799 AND `id` = 195265;
UPDATE `gameobject` SET `position_x` = -8884.23, `position_y` = 566.347, `position_z` = 93.292, `orientation` = 0.715585 WHERE `guid` = 241184 AND `id` = 181015;
-- Argent Dawn Banner: Argent Dawn standing banner in the Trade District square; same spot, CoA terrain 94.77 (sat 0.39
--   yd sunk)
UPDATE `gameobject` SET `position_x` = -8829.5, `position_y` = 640.266, `position_z` = 94.772, `orientation` = 3.71755 WHERE `guid` = 2173 AND `id` = 181256;
-- Banner: Lunar Festival standing banner by the Mage Quarter bridge; same spot, CoA terrain 97.54 (sat 0.45 yd sunk)
UPDATE `gameobject` SET `position_x` = -8842.26, `position_y` = 726.894, `position_z` = 97.537, `orientation` = 2.1293 WHERE `guid` = 19756 AND `id` = 180777;
-- Mailbox: Trade District mailbox by the canal steps; same spot, z on the CoA floor 96.35 with its stock 0.05 yd set-
--   in (sat 0.35 yd sunk)
UPDATE `gameobject` SET `position_x` = -8876.98, `position_y` = 652.007, `position_z` = 96.295, `orientation` = 5.07018 WHERE `guid` = 26387 AND `id` = 144131;
-- Apple Bob: Hallow's End apple bob on the square's bearskin rug; same spot, CoA rug top 98.11 plus its stock 0.38 yd
--   offset (floated 0.52)
UPDATE `gameobject` SET `position_x` = -8860.01, `position_y` = 674.45, `position_z` = 98.488, `orientation` = 4.13643 WHERE `guid` = 39850 AND `id` = 180523;
-- Festive Keg: Fireworks Spectacular keg in the Trade District square; same spot, CoA terrain 94.59 (sat 0.35 yd sunk)
UPDATE `gameobject` SET `position_x` = -8825.6, `position_y` = 636.709, `position_z` = 94.592, `orientation` = 3.75246 WHERE `guid` = 420158 AND `id` = 180699;
-- Lillian Singh: Lillian Singh by the square; same spot, z on the corrected CoA terrain with the stock offset (sat
--   0.3-0.45 yd sunk)
UPDATE `creature` SET `position_x` = -8807.99, `position_y` = 639.385, `position_z` = 94.548, `orientation` = 3.81468 WHERE `guid` = 12526 AND `id` = 8118;
-- Melris Malagan: Melris Malagan by the square; same spot, z on the corrected CoA terrain with the stock offset (sat
--   0.3-0.45 yd sunk)
UPDATE `creature` SET `position_x` = -8823.78, `position_y` = 630.43, `position_z` = 94.495, `orientation` = 4.03171 WHERE `guid` = 79694 AND `id` = 12480;
-- Rat: rat in the square; same spot, z on the corrected CoA terrain with the stock offset (sat 0.3-0.45 yd sunk)
UPDATE `creature` SET `position_x` = -8799.87, `position_y` = 651.868, `position_z` = 95.117, `orientation` = 4.48025 WHERE `guid` = 79793 AND `id` = 4075;
-- [DND] TAR Pedestal - Trainer, Druid, [DND] TAR Pedestal - Trainer, Mage: trade-in pedestal trigger; same spot, z on
--   the corrected CoA terrain with the stock offset (sat 0.3-0.45 yd sunk)
UPDATE `creature` SET `position_x` = -8832.04, `position_y` = 642.686, `position_z` = 95.181, `orientation` = 5.0091 WHERE `guid` = 96031 AND `id` = 26751;
UPDATE `creature` SET `position_x` = -8818.5, `position_y` = 643.579, `position_z` = 94.725, `orientation` = 4.17134 WHERE `guid` = 96037 AND `id` = 26753;
-- Stormwind Reveler: Fireworks Spectacular reveller in the square; same spot, z on the corrected CoA terrain with the
--   stock offset (sat 0.3-0.45 yd sunk)
UPDATE `creature` SET `position_x` = -8828.93, `position_y` = 636.658, `position_z` = 94.719, `orientation` = 4.54215 WHERE `guid` = 420000 AND `id` = 15694;
-- Stone Bench: same spot, z on the corrected CoA terrain 99.19 with the stock 0.05 offset (floated 0.38); terrain
--   under the 3-yd seat 99.03-99.34
UPDATE `gameobject` SET `position_x` = -8913.85, `position_y` = 609.636, `position_z` = 99.237, `orientation` = 2.07694 WHERE `guid` = 26294 AND `id` = 24529;
-- 5 rows: Winter Veil gift in the Trade District square; same spot, z on the corrected CoA terrain (sat 0.30-0.36 yd
--   sunk)
UPDATE `gameobject` SET `position_x` = -8805.25, `position_y` = 641.694, `position_z` = 94.55, `orientation` = 4.11898 WHERE `guid` = 40922 AND `id` = 178428;
UPDATE `gameobject` SET `position_x` = -8804.64, `position_y` = 640.854, `position_z` = 94.532, `orientation` = 3.12412 WHERE `guid` = 40924 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = -8807.59, `position_y` = 646.776, `position_z` = 94.661, `orientation` = 2.07694 WHERE `guid` = 40930 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -8804.11, `position_y` = 641.649, `position_z` = 94.537, `orientation` = 2.89725 WHERE `guid` = 40937 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -8805.98, `position_y` = 640.937, `position_z` = 94.548, `orientation` = 0.575957 WHERE `guid` = 40938 AND `id` = 178431;
-- Human Commoner: event commoner by the fountain; same spot, z on the corrected CoA terrain with the stock 0.08 offset
--   (floated 0.41-0.45)
UPDATE `creature` SET `position_x` = -8854.78, `position_y` = 649.83, `position_z` = 96.373, `orientation` = 1.43117 WHERE `guid` = 10998 AND `id` = 18927;
UPDATE `creature` SET `position_x` = -8855.71, `position_y` = 651.847, `position_z` = 96.367, `orientation` = 5.72468 WHERE `guid` = 10999 AND `id` = 18927;
-- [DND] TAR Pedestal - Accessories: trade-in pedestal trigger; same spot, z on the corrected CoA terrain with the
--   stock 0.08 offset (floated 0.41)
UPDATE `creature` SET `position_x` = -8844.97, `position_y` = 653.237, `position_z` = 96.697, `orientation` = 3.7001 WHERE `guid` = 96054 AND `id` = 26738;
-- Stone Bench: deleted; stock lobby corner is CoA's gold vault: footprint overlaps Stormwind_Bank_Gold_01
--   (-8922.9,602.8) and runs off the vault floor (99.3)
DELETE FROM `gameobject` WHERE `guid` IN (26310);
-- Stone Bench: deleted; footprint overlaps Stormwind_Bank_Gold_01 (-8916.4,608.4) in CoA's gold vault
DELETE FROM `gameobject` WHERE `guid` IN (26316);
-- Wooden Chair: deleted; stock table seat in what is CoA's gold vault (3 gold piles 1.5-4 yd, Stormwind_Vault_Door 3
--   yd); its table and benches are gone
DELETE FROM `gameobject` WHERE `guid` IN (26306);
-- Wooden Chair: deleted; stock table seat in CoA's gold vault (gold pile 1.5 yd, vault door 3 yd); its table and
--   benches are gone
DELETE FROM `gameobject` WHERE `guid` IN (26305);
-- Stone Bench: deleted; stock lobby wall gone: open courtyard outside CoA's bank hall; ground under the 3-yd bench
--   98.0-98.3, 1.3 below the stock seat
DELETE FROM `gameobject` WHERE `guid` IN (26668);
-- Stone Bench: deleted; open courtyard outside CoA's bank hall, ground 97.8-98.3, 1.5 below the stock seat; no wall to
--   line
DELETE FROM `gameobject` WHERE `guid` IN (26672);
-- Stone Bench: deleted; open courtyard between CoA's hall and vault wing; ground under the bench 98.45-99.15
DELETE FROM `gameobject` WHERE `guid` IN (26295);
-- Wooden Chair: deleted; seat of a stock inn table that CoA's hall wall cuts through; now over courtyard terrain
--   97.65-97.93
DELETE FROM `gameobject` WHERE `guid` IN (26669);
-- Wooden Chair: deleted; seat of the second stock inn table (gone); over courtyard terrain 98.4-98.8
DELETE FROM `gameobject` WHERE `guid` IN (26308);
-- Wooden Chair: deleted; stands on the sloped top of CoA's hall wall (100.05-100.67) where the stock table was
DELETE FROM `gameobject` WHERE `guid` IN (26671);
-- Wooden Chair: deleted; overlaps CoA's hall wall top and Fancydesk01 (98.2-100.7 under its footprint)
DELETE FROM `gameobject` WHERE `guid` IN (26307);
-- Christmas Tree (Medium): deleted; stock lobby spot is the hall/vault junction on Officer Pomeroy's patrol (mage-park
--   path 904840 nodes 76-77) and in the gap mage-park asked to keep clear; CoA's hall floor between the counters is
--   the patrol corridor, no 5-yd clear spot for the 4.7-yd tree; the building keeps its upstairs tree 40917
DELETE FROM `gameobject` WHERE `guid` IN (40919);
-- 13 rows: deleted; stood on a stock Inntablesmall (gone: CoA's hall wall runs through the table spot); 2.4-2.7 above
--   courtyard terrain
DELETE FROM `gameobject` WHERE `guid` IN (53437, 80525, 241113, 52663, 80668, 241105, 36180, 53207, 80443, 241172, 52718, 241236, 36621);
-- Hanging, Tall/Thin, Medium - MFF, Hanging, Tall/Thin, Medium - Brewfest: deleted; hung on a stock bank pillar CoA's
--   hall lacks; 2.1 above the floor in open air (no face within 2.8)
DELETE FROM `gameobject` WHERE `guid` IN (53991, 81038);
-- Hanging, Tall/Thin, Medium - Val: deleted; stock pillar replaced by CoA's west teller counter, which encloses it
--   (0.35 all round)
DELETE FROM `gameobject` WHERE `guid` IN (241176);
-- Hanging, Tall/Thin, Medium - Val: deleted; stock pillar replaced by CoA's east teller counter, which encloses it
--   (0.26 all round)
DELETE FROM `gameobject` WHERE `guid` IN (241109);
-- Hanging, Tall/Thin, Medium - MFF, Hanging, Tall/Thin, Medium - Brewfest: deleted; inside Duskwoodbookshelf01
--   standing against CoA hall wall where the stock pillar was
DELETE FROM `gameobject` WHERE `guid` IN (53858, 81039);
-- Hanging, Streamer - MFF, Hanging, Streamer - Brewfest, Hanging, Streamer - Val: deleted; streamer hung on a stock
--   lobby pillar; CoA's hall is open there (no face within 3 yd), 2.3 below the ceiling
DELETE FROM `gameobject` WHERE `guid` IN (53593, 80833, 241222);
-- Lights: deleted; hung on the stock Smokywood Pastures wagon (Stormwindgypsywagon01.m2), which CoA removed; now 2.2
--   above bare terrain
DELETE FROM `gameobject` WHERE `guid` IN (40921);
-- Lights: deleted; hung on the stock Smokywood Pastures wagon (Stormwindgypsywagon01.m2), which CoA removed; now 2.9
--   above bare terrain
DELETE FROM `gameobject` WHERE `guid` IN (40923);
-- Lights: deleted; hung on the stock Smokywood Pastures wagon (Stormwindgypsywagon01.m2), which CoA removed; now 2.6
--   above bare terrain
DELETE FROM `gameobject` WHERE `guid` IN (40935);
-- Wreath scale 0.75: deleted; hung on the stock Smokywood Pastures wagon (Stormwindgypsywagon01.m2), which CoA
--   removed; now 3.8 above bare terrain
DELETE FROM `gameobject` WHERE `guid` IN (41665);
-- Firecrackers: deleted; hung from a stock fixture 2.3 above it that CoA removed; nearest CoA lamp 14 yd away; now 2.4
--   above the street in open air
DELETE FROM `gameobject` WHERE `guid` IN (31236);
-- Stormwind, Goldshire: deleted; decorative pointer arms of the stock Woodsignpostnice01 at the Trade District south
--   entrance (-8881.0, 566.3): CoA removed that post and has no signpost within 70 yd, so the boards hang in open air
--   where the post stood (the nearest CoA post, (-8829.8, 615.5), already carries its own five arms)
DELETE FROM `gameobject` WHERE `guid` IN (26277, 26278);
-- 10 rows: deleted; holiday table decoration on the stock bank Inntablesmall at (-8920.6, 606.0) (table top 100.645);
--   CoA's bank hall has no table there (its floor is A01Sw_Tradedistrict 100.23 with no table or desk within 2 yd), so
--   it would float 0.3-0.4 yd over the floor; the table's chairs were already deleted (26305-26308, 26669, 26671)
DELETE FROM `gameobject` WHERE `guid` IN (53398, 80447, 241261, 36179, 52784, 80692, 241258, 53201, 80505, 241235);
-- 10 rows: deleted; holiday table decoration on the stock bank Inntablesmall at (-8933.2, 629.2) (table top 100.645);
--   CoA's bank hall has no table there (its floor is A01Sw_Tradedistrict 100.23 with no table or desk within 2 yd), so
--   it would float 0.3-0.4 yd over the floor; the table's chairs were already deleted (26305-26308, 26669, 26671)
DELETE FROM `gameobject` WHERE `guid` IN (53396, 80446, 241175, 52750, 80688, 241223, 37044, 53432, 80506, 241257);
-- Standing, Interior, Small - MFF, Standing, Interior, Small - Brewfest, Standing, Interior, Small - Val: deleted;
--   stood on a stock Inntablesmall (gone: CoA's hall wall runs through the table spot); rests on the sloped base ledge
--   of the hall wall (100.675) with the wall face 0.03-0.1 yd away, so it cuts into the wall, like its deleted
--   siblings
DELETE FROM `gameobject` WHERE `guid` IN (53110, 80517, 241234, 53330, 80524, 241231);

-- ---------------------------------------------------------------------------
-- 5. Trade District fountain
-- ---------------------------------------------------------------------------
-- Inspector Snip Snagglebolt: Love is in the Air ender of 13 quests stood on the edge of the stock Stormwindplanter.m2
--   (97.01), which CoA removed; same plaza spot beside CoA's Stormwindplanter03 and Aristan Mottar, z to the CoA
--   terrain 96.07; SuperTrack turn-in (-8867.86, 652.65, 97.01) of 24655 ff. stays 0.94 yd off (z only)
UPDATE `creature` SET `position_x` = -8867.86, `position_y` = 652.647, `position_z` = 96.07, `orientation` = 4.84704 WHERE `guid` = 244555 AND `id` = 38066;
-- CandleBlack01: Hallow's End black candle hovered 0.59 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.66 yd out along bearing 256 deg onto the lower basin rim (r 4.01, top 97.14)
UPDATE `gameobject` SET `position_x` = -8860.32, `position_y` = 644.78, `position_z` = 97.14, `orientation` = 5.02655 WHERE `guid` = 34341 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.61 yd out along bearing 309 deg onto the lower basin rim (r 3.92, top 97.14)
UPDATE `gameobject` SET `position_x` = -8856.88, `position_y` = 645.64, `position_z` = 97.14, `orientation` = 5.93412 WHERE `guid` = 34342 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.59 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.24 yd out along bearing 166 deg onto the lower basin rim (r 3.99, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.23, `position_y` = 649.65, `position_z` = 97.15, `orientation` = 0.0523589 WHERE `guid` = 34344 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.24 yd out along bearing 106 deg onto the lower basin rim (r 4.03, top 97.15)
UPDATE `gameobject` SET `position_x` = -8860.49, `position_y` = 652.55, `position_z` = 97.15, `orientation` = 3.90954 WHERE `guid` = 34346 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.12 yd out along bearing 144 deg onto the lower basin rim (r 3.91, top 97.15)
UPDATE `gameobject` SET `position_x` = -8862.51, `position_y` = 651, `position_z` = 97.15, `orientation` = 1.8675 WHERE `guid` = 34348 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.77 yd out along bearing 285 deg onto the lower basin rim (r 4.03, top 97.13)
UPDATE `gameobject` SET `position_x` = -8858.35, `position_y` = 644.78, `position_z` = 97.13, `orientation` = 0.698131 WHERE `guid` = 34349 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.33 yd out along bearing 190 deg onto the lower basin rim (r 3.93, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.23, `position_y` = 647.96, `position_z` = 97.15, `orientation` = 5.88176 WHERE `guid` = 34350 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.44 yd over the Trade District fountain's Stormwindfountain_03
--   lower basin rim midline (r 3.88); z to the lip top 97.14
UPDATE `gameobject` SET `position_x` = -8861.75, `position_y` = 651.735, `position_z` = 97.14, `orientation` = 2.58308 WHERE `guid` = 34358 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.59 yd out along bearing 353 deg onto the lower basin rim (r 3.91, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.48, `position_y` = 648.18, `position_z` = 97.15, `orientation` = 0.279252 WHERE `guid` = 34360 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.68 yd out along bearing 20 deg onto the lower basin rim (r 4.12, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.48, `position_y` = 650.06, `position_z` = 97.15, `orientation` = 4.41568 WHERE `guid` = 34361 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.7 yd out along bearing 328 deg onto the lower basin rim (r 3.99, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.98, `position_y` = 646.57, `position_z` = 97.15, `orientation` = 2.87979 WHERE `guid` = 34362 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.2 yd out along bearing 82 deg onto the lower basin rim (r 3.91, top 97.15)
UPDATE `gameobject` SET `position_x` = -8858.81, `position_y` = 652.55, `position_z` = 97.15, `orientation` = 0.453785 WHERE `guid` = 34363 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.42 yd out along bearing 214 deg onto the lower basin rim (r 3.95, top 97.15)
UPDATE `gameobject` SET `position_x` = -8862.65, `position_y` = 646.49, `position_z` = 97.15, `orientation` = 2.79252 WHERE `guid` = 34364 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.43 yd out along bearing 232 deg onto the lower basin rim (r 3.9, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.79, `position_y` = 645.63, `position_z` = 97.15, `orientation` = 5.81195 WHERE `guid` = 34367 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.27 yd out along bearing 42 deg onto the lower basin rim (r 3.87, top 97.15)
UPDATE `gameobject` SET `position_x` = -8856.5, `position_y` = 651.29, `position_z` = 97.15, `orientation` = 2.77507 WHERE `guid` = 34369 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.31 yd out along bearing 60 deg onto the lower basin rim (r 4.01, top 97.15)
UPDATE `gameobject` SET `position_x` = -8857.34, `position_y` = 652.14, `position_z` = 97.15, `orientation` = 2.23402 WHERE `guid` = 34371 AND `id` = 180415;
-- SkullCandle01: Hallow's End skull candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.65 yd out along bearing 203 deg onto the lower basin rim (r 4.18, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.21, `position_y` = 647.05, `position_z` = 97.15, `orientation` = 3.61284 WHERE `guid` = 37766 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.33 yd out along bearing 6 deg onto the lower basin rim (r 3.9, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.48, `position_y` = 649.1, `position_z` = 97.15, `orientation` = 0.0349062 WHERE `guid` = 37772 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.53 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.12 yd out along bearing 51 deg onto the lower basin rim (r 3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8856.92, `position_y` = 651.71, `position_z` = 97.15, `orientation` = 0.837757 WHERE `guid` = 37773 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.47 yd out along bearing 318 deg onto the lower basin rim (r 3.9, top 97.14)
UPDATE `gameobject` SET `position_x` = -8856.44, `position_y` = 646.09, `position_z` = 97.14, `orientation` = 5.49779 WHERE `guid` = 37775 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.24 yd out along bearing 223 deg onto the lower basin rim (r 3.87, top 97.15)
UPDATE `gameobject` SET `position_x` = -8862.2, `position_y` = 646.05, `position_z` = 97.15, `orientation` = 3.94445 WHERE `guid` = 37777 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.5 yd over the Trade District fountain's Stormwindfountain_03
--   lower basin rim midline (r 3.94); z to the lip top 97.11
UPDATE `gameobject` SET `position_x` = -8862.2, `position_y` = 651.415, `position_z` = 97.11, `orientation` = 2.35619 WHERE `guid` = 37779 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.48 yd out along bearing 71 deg onto the lower basin rim (r 4.1, top 97.15)
UPDATE `gameobject` SET `position_x` = -8858, `position_y` = 652.55, `position_z` = 97.15, `orientation` = 1.23918 WHERE `guid` = 37781 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.59 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.73 yd out along bearing 243 deg onto the lower basin rim (r 4.09, top 97.14)
UPDATE `gameobject` SET `position_x` = -8861.2, `position_y` = 645.02, `position_z` = 97.14, `orientation` = 4.34587 WHERE `guid` = 37782 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.31 yd out along bearing 117 deg onto the lower basin rim (r 4.05, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.22, `position_y` = 652.28, `position_z` = 97.15, `orientation` = 2.04204 WHERE `guid` = 37784 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.87 yd out along bearing 340 deg onto the lower basin rim (r 4.12, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 647.28, `position_z` = 97.15, `orientation` = 5.91667 WHERE `guid` = 37785 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.43 yd out along bearing 270 deg onto the lower basin rim (r 3.9, top 97.14)
UPDATE `gameobject` SET `position_x` = -8859.38, `position_y` = 644.78, `position_z` = 97.14, `orientation` = 4.72984 WHERE `guid` = 37786 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.48 yd over the Trade District fountain's Stormwindfountain_03
--   lower basin rim midline (r 3.92); z to the lip top 97.13
UPDATE `gameobject` SET `position_x` = -8859.63, `position_y` = 652.589, `position_z` = 97.13, `orientation` = 1.5708 WHERE `guid` = 37789 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.45 yd over the Trade District fountain's Stormwindfountain_03
--   lower basin rim midline (r 3.85); z to the lip top 97.14
UPDATE `gameobject` SET `position_x` = -8863.21, `position_y` = 648.778, `position_z` = 97.14, `orientation` = 3.194 WHERE `guid` = 37791 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.61 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.52 yd out along bearing 32 deg onto the lower basin rim (r 3.97, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.99, `position_y` = 650.77, `position_z` = 97.15, `orientation` = 0.453785 WHERE `guid` = 37793 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.9 yd out along bearing 297 deg onto the lower basin rim (r 4.09, top 97.12)
UPDATE `gameobject` SET `position_x` = -8857.49, `position_y` = 645.04, `position_z` = 97.12, `orientation` = 5.18363 WHERE `guid` = 37794 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.6 yd over the new lower basin of the Trade District fountain
--   (Stormwindfountain_03); moved 0.38 yd out along bearing 155 deg onto the lower basin rim (r 4.1, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.06, `position_y` = 650.44, `position_z` = 97.15, `orientation` = 2.79252 WHERE `guid` = 37796 AND `id` = 180425;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.56 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.17 yd out along bearing 174 deg onto the lower basin rim (r
--   3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.23, `position_y` = 649.11, `position_z` = 97.15, `orientation` = 1.23918 WHERE `guid` = 241106 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.36 yd out along bearing 57 deg onto the lower basin rim (r 3.95,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8857.21, `position_y` = 651.99, `position_z` = 97.15, `orientation` = -0.802851 WHERE `guid` = 241108 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.85 yd out along bearing 300 deg onto the lower basin rim (r
--   4.03, top 97.13)
UPDATE `gameobject` SET `position_x` = -8857.33, `position_y` = 645.2, `position_z` = 97.13, `orientation` = -3.00197 WHERE `guid` = 241111 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.61 yd out along bearing 354 deg onto the lower basin rim (r
--   3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 648.3, `position_z` = 97.15, `orientation` = 0.610865 WHERE `guid` = 241112 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.46 yd over the Trade District fountain's
--   Stormwindfountain_03 lower basin rim midline (r 3.88); z to the lip top 97.15
UPDATE `gameobject` SET `position_x` = -8859.7, `position_y` = 652.545, `position_z` = 97.15, `orientation` = 1.62316 WHERE `guid` = 241171 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.47 yd out along bearing 154 deg onto the lower basin rim (r
--   4.08, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.03, `position_y` = 650.47, `position_z` = 97.15, `orientation` = -3.12414 WHERE `guid` = 241177 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.54 yd out along bearing 234 deg onto the lower basin rim (r
--   3.92, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.68, `position_y` = 645.52, `position_z` = 97.15, `orientation` = -1.0821 WHERE `guid` = 241179 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.49 yd out along bearing 10 deg onto the lower basin rim (r 3.93,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 649.36, `position_z` = 97.15, `orientation` = 1.06465 WHERE `guid` = 241180 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.29 yd out along bearing 46 deg onto the lower basin rim (r 3.87,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8856.66, `position_y` = 651.45, `position_z` = 97.15, `orientation` = -0.959931 WHERE `guid` = 241224 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.48 yd out along bearing 74 deg onto the lower basin rim (r 4.03,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8858.25, `position_y` = 652.55, `position_z` = 97.15, `orientation` = -0.453786 WHERE `guid` = 241226 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.49 yd out along bearing 212 deg onto the lower basin rim (r
--   3.97, top 97.15)
UPDATE `gameobject` SET `position_x` = -8862.74, `position_y` = 646.59, `position_z` = 97.15, `orientation` = 2.82743 WHERE `guid` = 241228 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.99 yd out along bearing 336 deg onto the lower basin rim (r
--   4.16, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.55, `position_y` = 647.02, `position_z` = 97.15, `orientation` = 2.42601 WHERE `guid` = 241230 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.74 yd out along bearing 255 deg onto the lower basin rim (r
--   4.02, top 97.14)
UPDATE `gameobject` SET `position_x` = -8860.38, `position_y` = 644.79, `position_z` = 97.14, `orientation` = -2.6529 WHERE `guid` = 241233 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.47 yd over the Trade District fountain's
--   Stormwindfountain_03 lower basin rim midline (r 3.85); z to the lip top 97.14
UPDATE `gameobject` SET `position_x` = -8862.29, `position_y` = 651.178, `position_z` = 97.14, `orientation` = -2.1293 WHERE `guid` = 241241 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.3 yd out along bearing 189 deg onto the lower basin rim (r 3.91,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.22, `position_y` = 648.07, `position_z` = 97.15, `orientation` = 3.08923 WHERE `guid` = 241245 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.65 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.64 yd out along bearing 318 deg onto the lower basin rim (r
--   3.89, top 97.14)
UPDATE `gameobject` SET `position_x` = -8856.47, `position_y` = 646.08, `position_z` = 97.14, `orientation` = 0.890118 WHERE `guid` = 241246 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.57 yd out along bearing 30 deg onto the lower basin rim (r 4.0,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.91, `position_y` = 650.71, `position_z` = 97.15, `orientation` = 1.85005 WHERE `guid` = 241247 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.6 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.39 yd out along bearing 111 deg onto the lower basin rim (r
--   4.13, top 97.15)
UPDATE `gameobject` SET `position_x` = -8860.82, `position_y` = 652.55, `position_z` = 97.15, `orientation` = -2.80998 WHERE `guid` = 241252 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.8 yd out along bearing 280 deg onto the lower basin rim (r 3.95,
--   top 97.13)
UPDATE `gameobject` SET `position_x` = -8858.68, `position_y` = 644.79, `position_z` = 97.13, `orientation` = -1.09956 WHERE `guid` = 241253 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.28 yd out along bearing 122 deg onto the lower basin rim (r
--   3.95, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.48, `position_y` = 652.02, `position_z` = 97.15, `orientation` = 2.72271 WHERE `guid` = 241255 AND `id` = 181060;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.54 yd out along bearing 234 deg onto the lower basin rim (r
--   3.92, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.68, `position_y` = 645.52, `position_z` = 97.15, `orientation` = 5.20108 WHERE `guid` = 53105 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.29 yd out along bearing 46 deg onto the lower basin rim (r 3.87,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8856.66, `position_y` = 651.45, `position_z` = 97.15, `orientation` = 5.32326 WHERE `guid` = 53107 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.8 yd out along bearing 280 deg onto the lower basin rim (r 3.95,
--   top 97.13)
UPDATE `gameobject` SET `position_x` = -8858.68, `position_y` = 644.79, `position_z` = 97.13, `orientation` = 5.18363 WHERE `guid` = 53109 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.57 yd out along bearing 30 deg onto the lower basin rim (r 4.0,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.91, `position_y` = 650.71, `position_z` = 97.15, `orientation` = 1.85005 WHERE `guid` = 53111 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.3 yd out along bearing 189 deg onto the lower basin rim (r 3.91,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.22, `position_y` = 648.07, `position_z` = 97.15, `orientation` = 3.08918 WHERE `guid` = 53202 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.49 yd out along bearing 212 deg onto the lower basin rim (r
--   3.97, top 97.15)
UPDATE `gameobject` SET `position_x` = -8862.74, `position_y` = 646.59, `position_z` = 97.15, `orientation` = 2.82743 WHERE `guid` = 53205 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.6 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.39 yd out along bearing 111 deg onto the lower basin rim (r
--   4.13, top 97.15)
UPDATE `gameobject` SET `position_x` = -8860.82, `position_y` = 652.55, `position_z` = 97.15, `orientation` = 3.47321 WHERE `guid` = 53206 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.49 yd out along bearing 10 deg onto the lower basin rim (r 3.93,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 649.36, `position_z` = 97.15, `orientation` = 1.06465 WHERE `guid` = 53328 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.61 yd out along bearing 354 deg onto the lower basin rim (r
--   3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 648.3, `position_z` = 97.15, `orientation` = 0.610863 WHERE `guid` = 53329 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.74 yd out along bearing 255 deg onto the lower basin rim (r
--   4.02, top 97.14)
UPDATE `gameobject` SET `position_x` = -8860.38, `position_y` = 644.79, `position_z` = 97.14, `orientation` = 3.63029 WHERE `guid` = 53331 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.47 yd over the Trade District fountain's
--   Stormwindfountain_03 lower basin rim midline (r 3.85); z to the lip top 97.14
UPDATE `gameobject` SET `position_x` = -8862.29, `position_y` = 651.178, `position_z` = 97.14, `orientation` = 4.15388 WHERE `guid` = 53332 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.28 yd out along bearing 122 deg onto the lower basin rim (r
--   3.95, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.48, `position_y` = 652.02, `position_z` = 97.15, `orientation` = 2.72271 WHERE `guid` = 53392 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.65 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.64 yd out along bearing 318 deg onto the lower basin rim (r
--   3.89, top 97.14)
UPDATE `gameobject` SET `position_x` = -8856.47, `position_y` = 646.08, `position_z` = 97.14, `orientation` = 0.890117 WHERE `guid` = 53393 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.46 yd over the Trade District fountain's
--   Stormwindfountain_03 lower basin rim midline (r 3.88); z to the lip top 97.15
UPDATE `gameobject` SET `position_x` = -8859.7, `position_y` = 652.545, `position_z` = 97.15, `orientation` = 1.62316 WHERE `guid` = 53394 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.36 yd out along bearing 57 deg onto the lower basin rim (r 3.95,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8857.21, `position_y` = 651.99, `position_z` = 97.15, `orientation` = 5.48033 WHERE `guid` = 53430 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.99 yd out along bearing 336 deg onto the lower basin rim (r
--   4.16, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.55, `position_y` = 647.02, `position_z` = 97.15, `orientation` = 2.42601 WHERE `guid` = 53433 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.48 yd out along bearing 74 deg onto the lower basin rim (r 4.03,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8858.25, `position_y` = 652.55, `position_z` = 97.15, `orientation` = 5.8294 WHERE `guid` = 53434 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.47 yd out along bearing 154 deg onto the lower basin rim (r
--   4.08, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.03, `position_y` = 650.47, `position_z` = 97.15, `orientation` = 3.15906 WHERE `guid` = 53435 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.85 yd out along bearing 300 deg onto the lower basin rim (r
--   4.03, top 97.13)
UPDATE `gameobject` SET `position_x` = -8857.33, `position_y` = 645.2, `position_z` = 97.13, `orientation` = 3.28124 WHERE `guid` = 53436 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.56 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.17 yd out along bearing 174 deg onto the lower basin rim (r
--   3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.23, `position_y` = 649.11, `position_z` = 97.15, `orientation` = 1.23918 WHERE `guid` = 53458 AND `id` = 181391;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.49 yd out along bearing 10 deg onto the lower basin rim (r 3.93,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 649.36, `position_z` = 97.15, `orientation` = 1.06465 WHERE `guid` = 80445 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.85 yd out along bearing 300 deg onto the lower basin rim (r
--   4.03, top 97.13)
UPDATE `gameobject` SET `position_x` = -8857.33, `position_y` = 645.2, `position_z` = 97.13, `orientation` = -3.00195 WHERE `guid` = 80448 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.29 yd out along bearing 46 deg onto the lower basin rim (r 3.87,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8856.66, `position_y` = 651.45, `position_z` = 97.15, `orientation` = -0.95993 WHERE `guid` = 80452 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.8 yd out along bearing 280 deg onto the lower basin rim (r 3.95,
--   top 97.13)
UPDATE `gameobject` SET `position_x` = -8858.68, `position_y` = 644.79, `position_z` = 97.13, `orientation` = -1.09956 WHERE `guid` = 80476 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.49 yd out along bearing 212 deg onto the lower basin rim (r
--   3.97, top 97.15)
UPDATE `gameobject` SET `position_x` = -8862.74, `position_y` = 646.59, `position_z` = 97.15, `orientation` = 2.82743 WHERE `guid` = 80477 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.74 yd out along bearing 255 deg onto the lower basin rim (r
--   4.02, top 97.14)
UPDATE `gameobject` SET `position_x` = -8860.38, `position_y` = 644.79, `position_z` = 97.14, `orientation` = -2.65289 WHERE `guid` = 80478 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.6 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.39 yd out along bearing 111 deg onto the lower basin rim (r
--   4.13, top 97.15)
UPDATE `gameobject` SET `position_x` = -8860.82, `position_y` = 652.55, `position_z` = 97.15, `orientation` = -2.80997 WHERE `guid` = 80479 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.54 yd out along bearing 234 deg onto the lower basin rim (r
--   3.92, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.68, `position_y` = 645.52, `position_z` = 97.15, `orientation` = -1.0821 WHERE `guid` = 80480 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.99 yd out along bearing 336 deg onto the lower basin rim (r
--   4.16, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.55, `position_y` = 647.02, `position_z` = 97.15, `orientation` = 2.42601 WHERE `guid` = 80482 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.57 yd out along bearing 30 deg onto the lower basin rim (r 4.0,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.91, `position_y` = 650.71, `position_z` = 97.15, `orientation` = 1.85005 WHERE `guid` = 80483 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.47 yd out along bearing 154 deg onto the lower basin rim (r
--   4.08, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.03, `position_y` = 650.47, `position_z` = 97.15, `orientation` = -3.12412 WHERE `guid` = 80498 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.36 yd out along bearing 57 deg onto the lower basin rim (r 3.95,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8857.21, `position_y` = 651.99, `position_z` = 97.15, `orientation` = -0.802851 WHERE `guid` = 80499 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.61 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.3 yd out along bearing 189 deg onto the lower basin rim (r 3.91,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.22, `position_y` = 648.07, `position_z` = 97.15, `orientation` = 3.08918 WHERE `guid` = 80501 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.56 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.17 yd out along bearing 174 deg onto the lower basin rim (r
--   3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8863.23, `position_y` = 649.11, `position_z` = 97.15, `orientation` = 1.23918 WHERE `guid` = 80503 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.65 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.64 yd out along bearing 318 deg onto the lower basin rim (r
--   3.89, top 97.14)
UPDATE `gameobject` SET `position_x` = -8856.47, `position_y` = 646.08, `position_z` = 97.14, `orientation` = 0.890117 WHERE `guid` = 80513 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.46 yd over the Trade District fountain's
--   Stormwindfountain_03 lower basin rim midline (r 3.88); z to the lip top 97.15
UPDATE `gameobject` SET `position_x` = -8859.7, `position_y` = 652.545, `position_z` = 97.15, `orientation` = 1.62316 WHERE `guid` = 80515 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.61 yd out along bearing 354 deg onto the lower basin rim (r
--   3.89, top 97.15)
UPDATE `gameobject` SET `position_x` = -8855.49, `position_y` = 648.3, `position_z` = 97.15, `orientation` = 0.610864 WHERE `guid` = 80516 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.47 yd over the Trade District fountain's
--   Stormwindfountain_03 lower basin rim midline (r 3.85); z to the lip top 97.14
UPDATE `gameobject` SET `position_x` = -8862.29, `position_y` = 651.178, `position_z` = 97.14, `orientation` = -2.1293 WHERE `guid` = 80528 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.62 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.28 yd out along bearing 122 deg onto the lower basin rim (r
--   3.95, top 97.15)
UPDATE `gameobject` SET `position_x` = -8861.48, `position_y` = 652.02, `position_z` = 97.15, `orientation` = 2.72271 WHERE `guid` = 80531 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.63 yd over the new lower basin of the Trade
--   District fountain (Stormwindfountain_03); moved 0.48 yd out along bearing 74 deg onto the lower basin rim (r 4.03,
--   top 97.15)
UPDATE `gameobject` SET `position_x` = -8858.25, `position_y` = 652.55, `position_z` = 97.15, `orientation` = -0.453785 WHERE `guid` = 80537 AND `id` = 195260;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.76 yd out along bearing 344 deg onto the middle bowl lip (r 2.4, top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.05, `position_y` = 648.02, `position_z` = 99.12, `orientation` = 2.05949 WHERE `guid` = 34343 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.28 yd out along bearing 74 deg onto the middle bowl lip (r 2.31, top 99.14)
UPDATE `gameobject` SET `position_x` = -8858.72, `position_y` = 650.9, `position_z` = 99.14, `orientation` = 2.02458 WHERE `guid` = 34347 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.34 yd out along bearing 155 deg onto the middle bowl lip (r 2.43, top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.56, `position_y` = 649.71, `position_z` = 99.12, `orientation` = 3.54302 WHERE `guid` = 34351 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.7 yd out along bearing 242 deg onto the middle bowl lip (r 2.38, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.48, `position_y` = 646.58, `position_z` = 99.12, `orientation` = 4.95674 WHERE `guid` = 34352 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.46 yd out along bearing 197 deg onto the middle bowl lip (r 2.35, top 99.13)
UPDATE `gameobject` SET `position_x` = -8861.61, `position_y` = 648, `position_z` = 99.13, `orientation` = 5.84685 WHERE `guid` = 34356 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.27 yd out along bearing 116 deg onto the middle bowl lip (r 2.41, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.4, `position_y` = 650.85, `position_z` = 99.12, `orientation` = 2.79252 WHERE `guid` = 34359 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.86 yd out along bearing 293 deg onto the middle bowl lip (r 2.45, top 99.10)
UPDATE `gameobject` SET `position_x` = -8858.4, `position_y` = 646.43, `position_z` = 99.1, `orientation` = 2.72271 WHERE `guid` = 34365 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.5 yd out along bearing 33 deg onto the middle bowl lip (r 2.33, top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.41, `position_y` = 649.96, `position_z` = 99.12, `orientation` = 1.27409 WHERE `guid` = 34370 AND `id` = 180415;
-- SkullCandle01: Hallow's End skull candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.57 yd out along bearing 319 deg onto the middle bowl lip (r 2.28, top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.64, `position_y` = 647.18, `position_z` = 99.12, `orientation` = 5.53269 WHERE `guid` = 37764 AND `id` = 180425;
-- SkullCandle01: fits-class row of the same ring: Hallow's End skull candle hovered 0.51 yd over the new middle bowl
--   of the Trade District fountain (Stormwindfountain_03); moved 0.22 yd out along bearing 54 deg onto the middle bowl
--   lip (r 2.3, top 99.12)
UPDATE `gameobject` SET `position_x` = -8858.01, `position_y` = 650.54, `position_z` = 99.12, `orientation` = 0.750491 WHERE `guid` = 37768 AND `id` = 180425;
-- SkullCandle01: fits-class row of the same ring: Hallow's End skull candle hovered 0.43 yd over the Trade District
--   fountain's Stormwindfountain_03 middle bowl lip midline (r 2.22); z to the lip top 99.12
UPDATE `gameobject` SET `position_x` = -8860.92, `position_y` = 650.26, `position_z` = 99.12, `orientation` = 2.54818 WHERE `guid` = 37769 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.5 yd out along bearing 10 deg onto the middle bowl lip (r 2.35, top 99.17)
UPDATE `gameobject` SET `position_x` = -8857.04, `position_y` = 649.07, `position_z` = 99.17, `orientation` = 6.23083 WHERE `guid` = 37783 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.42 yd out along bearing 218 deg onto the middle bowl lip (r 2.3, top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.17, `position_y` = 647.26, `position_z` = 99.12, `orientation` = 4.06662 WHERE `guid` = 37787 AND `id` = 180425;
-- SkullCandle01: fits-class row of the same ring: Hallow's End skull candle hovered 0.39 yd over the new middle bowl
--   of the Trade District fountain (Stormwindfountain_03); moved 0.15 yd out along bearing 175 deg onto the middle
--   bowl lip (r 2.25, top 99.17)
UPDATE `gameobject` SET `position_x` = -8861.6, `position_y` = 648.86, `position_z` = 99.17, `orientation` = 3.24635 WHERE `guid` = 37788 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.51 yd over the new middle bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.58 yd out along bearing 267 deg onto the middle bowl lip (r 2.29, top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.48, `position_y` = 646.39, `position_z` = 99.17, `orientation` = 4.81711 WHERE `guid` = 37792 AND `id` = 180425;
-- SkullCandle01: fits-class row of the same ring: Hallow's End skull candle hovered 0.38 yd over the Trade District
--   fountain's Stormwindfountain_03 middle bowl lip midline (r 2.21); z to the lip top 99.17
UPDATE `gameobject` SET `position_x` = -8859.55, `position_y` = 650.882, `position_z` = 99.17, `orientation` = 1.6057 WHERE `guid` = 37795 AND `id` = 180425;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.7 yd out along bearing 326 deg onto the middle bowl lip (r 2.32,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.43, `position_y` = 647.4, `position_z` = 99.12, `orientation` = 2.58309 WHERE `guid` = 241173 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.56 yd out along bearing 2 deg onto the middle bowl lip (r 2.32,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8857.04, `position_y` = 648.74, `position_z` = 99.17, `orientation` = -1.65806 WHERE `guid` = 241174 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.2 yd out along bearing 146 deg onto the middle bowl lip (r 2.32,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.29, `position_y` = 649.97, `position_z` = 99.12, `orientation` = -2.1293 WHERE `guid` = 241225 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.29 yd out along bearing 115 deg onto the middle bowl lip (r
--   2.41, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.39, `position_y` = 650.86, `position_z` = 99.12, `orientation` = 2.30383 WHERE `guid` = 241227 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.61 yd out along bearing 236 deg onto the middle bowl lip (r
--   2.32, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.66, `position_y` = 646.75, `position_z` = 99.12, `orientation` = -1.16937 WHERE `guid` = 241238 AND `id` = 181060;
-- Standing, Interior, Small - Val: fits-class row of the same ring: Love is in the Air candle hovered 0.39 yd over the
--   new middle bowl of the Trade District fountain (Stormwindfountain_03); moved 0.13 yd out along bearing 176 deg
--   onto the middle bowl lip (r 2.25, top 99.17)
UPDATE `gameobject` SET `position_x` = -8861.6, `position_y` = 648.85, `position_z` = 99.17, `orientation` = -2.79253 WHERE `guid` = 241239 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.85 yd out along bearing 295 deg onto the middle bowl lip (r
--   2.43, top 99.10)
UPDATE `gameobject` SET `position_x` = -8858.33, `position_y` = 646.48, `position_z` = 99.1, `orientation` = -2.53073 WHERE `guid` = 241242 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.39 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.18 yd out along bearing 84 deg onto the middle bowl lip (r 2.25,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.11, `position_y` = 650.92, `position_z` = 99.17, `orientation` = 1.46608 WHERE `guid` = 241249 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.37 yd out along bearing 61 deg onto the middle bowl lip (r 2.37,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8858.2, `position_y` = 650.74, `position_z` = 99.12, `orientation` = -1.13446 WHERE `guid` = 241251 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.55 yd out along bearing 203 deg onto the middle bowl lip (r
--   2.45, top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.62, `position_y` = 647.72, `position_z` = 99.12, `orientation` = 2.14675 WHERE `guid` = 241254 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.53 yd out along bearing 32 deg onto the middle bowl lip (r 2.34,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.38, `position_y` = 649.92, `position_z` = 99.12, `orientation` = -0.925024 WHERE `guid` = 241259 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.6 yd out along bearing 266 deg onto the middle bowl lip (r 2.3,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.51, `position_y` = 646.38, `position_z` = 99.17, `orientation` = -1.76278 WHERE `guid` = 241260 AND `id` = 181060;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.85 yd out along bearing 295 deg onto the middle bowl lip (r
--   2.43, top 99.10)
UPDATE `gameobject` SET `position_x` = -8858.33, `position_y` = 646.48, `position_z` = 99.1, `orientation` = 3.75246 WHERE `guid` = 53108 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.61 yd out along bearing 236 deg onto the middle bowl lip (r
--   2.32, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.66, `position_y` = 646.75, `position_z` = 99.12, `orientation` = 5.11382 WHERE `guid` = 53112 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.55 yd out along bearing 203 deg onto the middle bowl lip (r
--   2.45, top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.62, `position_y` = 647.72, `position_z` = 99.12, `orientation` = 2.14675 WHERE `guid` = 53113 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.39 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.18 yd out along bearing 84 deg onto the middle bowl lip (r 2.25,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.11, `position_y` = 650.92, `position_z` = 99.17, `orientation` = 1.46608 WHERE `guid` = 53204 AND `id` = 181391;
-- Standing, Interior, Small - MFF: fits-class row of the same ring: Midsummer brazier candle hovered 0.39 yd over the
--   new middle bowl of the Trade District fountain (Stormwindfountain_03); moved 0.13 yd out along bearing 176 deg
--   onto the middle bowl lip (r 2.25, top 99.17)
UPDATE `gameobject` SET `position_x` = -8861.6, `position_y` = 648.85, `position_z` = 99.17, `orientation` = 3.49067 WHERE `guid` = 53324 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.29 yd out along bearing 115 deg onto the middle bowl lip (r
--   2.41, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.39, `position_y` = 650.86, `position_z` = 99.12, `orientation` = 2.30383 WHERE `guid` = 53325 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.2 yd out along bearing 146 deg onto the middle bowl lip (r 2.32,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.29, `position_y` = 649.97, `position_z` = 99.12, `orientation` = 4.15388 WHERE `guid` = 53327 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.6 yd out along bearing 266 deg onto the middle bowl lip (r 2.3,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.51, `position_y` = 646.38, `position_z` = 99.17, `orientation` = 4.5204 WHERE `guid` = 53395 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.7 yd out along bearing 326 deg onto the middle bowl lip (r 2.32,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.43, `position_y` = 647.4, `position_z` = 99.12, `orientation` = 2.58308 WHERE `guid` = 53397 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.56 yd out along bearing 2 deg onto the middle bowl lip (r 2.32,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8857.04, `position_y` = 648.74, `position_z` = 99.17, `orientation` = 4.62512 WHERE `guid` = 53455 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.37 yd out along bearing 61 deg onto the middle bowl lip (r 2.37,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8858.2, `position_y` = 650.74, `position_z` = 99.12, `orientation` = 5.14872 WHERE `guid` = 53456 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.53 yd out along bearing 32 deg onto the middle bowl lip (r 2.34,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.38, `position_y` = 649.92, `position_z` = 99.12, `orientation` = 5.35816 WHERE `guid` = 53457 AND `id` = 181391;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.37 yd out along bearing 61 deg onto the middle bowl lip (r 2.37,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8858.2, `position_y` = 650.74, `position_z` = 99.12, `orientation` = -1.13446 WHERE `guid` = 80444 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.2 yd out along bearing 146 deg onto the middle bowl lip (r 2.32,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.29, `position_y` = 649.97, `position_z` = 99.12, `orientation` = -2.1293 WHERE `guid` = 80449 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.55 yd out along bearing 203 deg onto the middle bowl lip (r
--   2.45, top 99.12)
UPDATE `gameobject` SET `position_x` = -8861.62, `position_y` = 647.72, `position_z` = 99.12, `orientation` = 2.14675 WHERE `guid` = 80450 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.29 yd out along bearing 115 deg onto the middle bowl lip (r
--   2.41, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.39, `position_y` = 650.86, `position_z` = 99.12, `orientation` = 2.30383 WHERE `guid` = 80451 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.53 yd out along bearing 32 deg onto the middle bowl lip (r 2.34,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.38, `position_y` = 649.92, `position_z` = 99.12, `orientation` = -0.925024 WHERE `guid` = 80481 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.61 yd out along bearing 236 deg onto the middle bowl lip (r
--   2.32, top 99.12)
UPDATE `gameobject` SET `position_x` = -8860.66, `position_y` = 646.75, `position_z` = 99.12, `orientation` = -1.16937 WHERE `guid` = 80500 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: fits-class row of the same ring: Brewfest brazier candle hovered 0.39 yd over
--   the new middle bowl of the Trade District fountain (Stormwindfountain_03); moved 0.13 yd out along bearing 176 deg
--   onto the middle bowl lip (r 2.25, top 99.17)
UPDATE `gameobject` SET `position_x` = -8861.6, `position_y` = 648.85, `position_z` = 99.17, `orientation` = -2.79252 WHERE `guid` = 80504 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.6 yd out along bearing 266 deg onto the middle bowl lip (r 2.3,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.51, `position_y` = 646.38, `position_z` = 99.17, `orientation` = -1.76278 WHERE `guid` = 80512 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.56 yd out along bearing 2 deg onto the middle bowl lip (r 2.32,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8857.04, `position_y` = 648.74, `position_z` = 99.17, `orientation` = -1.65806 WHERE `guid` = 80518 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.7 yd out along bearing 326 deg onto the middle bowl lip (r 2.32,
--   top 99.12)
UPDATE `gameobject` SET `position_x` = -8857.43, `position_y` = 647.4, `position_z` = 99.12, `orientation` = 2.58308 WHERE `guid` = 80530 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.51 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.85 yd out along bearing 295 deg onto the middle bowl lip (r
--   2.43, top 99.10)
UPDATE `gameobject` SET `position_x` = -8858.33, `position_y` = 646.48, `position_z` = 99.1, `orientation` = -2.53072 WHERE `guid` = 80532 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.39 yd over the new middle bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.18 yd out along bearing 84 deg onto the middle bowl lip (r 2.25,
--   top 99.17)
UPDATE `gameobject` SET `position_x` = -8859.11, `position_y` = 650.92, `position_z` = 99.17, `orientation` = 1.46608 WHERE `guid` = 80539 AND `id` = 195260;
-- CandleBlack01: Hallow's End black candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.61 yd out along bearing 233 deg onto the upper bowl lip (r 1.55, top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.29, `position_y` = 647.44, `position_z` = 100.73, `orientation` = 5.11382 WHERE `guid` = 34345 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.33 yd out along bearing 79 deg onto the upper bowl lip (r 1.61, top 100.73)
UPDATE `gameobject` SET `position_x` = -8859.06, `position_y` = 650.26, `position_z` = 100.73, `orientation` = 3.03684 WHERE `guid` = 34353 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.23 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.92 yd out along bearing 290 deg onto the upper bowl lip (r 1.7, top 100.73)
UPDATE `gameobject` SET `position_x` = -8858.77, `position_y` = 647.08, `position_z` = 100.73, `orientation` = 5.84685 WHERE `guid` = 34354 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.26 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.65 yd out along bearing 351 deg onto the upper bowl lip (r 1.51, top 100.73)
UPDATE `gameobject` SET `position_x` = -8857.87, `position_y` = 648.43, `position_z` = 100.73, `orientation` = 5.25344 WHERE `guid` = 34355 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.5 yd out along bearing 40 deg onto the upper bowl lip (r 1.57, top 100.72)
UPDATE `gameobject` SET `position_x` = -8858.16, `position_y` = 649.69, `position_z` = 100.72, `orientation` = 2.40855 WHERE `guid` = 34357 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.29 yd out along bearing 152 deg onto the upper bowl lip (r 1.63, top 100.67)
UPDATE `gameobject` SET `position_x` = -8860.79, `position_y` = 649.46, `position_z` = 100.67, `orientation` = 5.16618 WHERE `guid` = 34366 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.45 yd out along bearing 189 deg onto the upper bowl lip (r 1.61, top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.95, `position_y` = 648.42, `position_z` = 100.73, `orientation` = 6.07375 WHERE `guid` = 34368 AND `id` = 180415;
-- CandleBlack01: Hallow's End black candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.29 yd out along bearing 115 deg onto the upper bowl lip (r 1.67, top 100.67)
UPDATE `gameobject` SET `position_x` = -8860.07, `position_y` = 650.19, `position_z` = 100.67, `orientation` = 5.02655 WHERE `guid` = 34372 AND `id` = 180415;
-- SkullCandle01: Hallow's End skull candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.56 yd out along bearing 211 deg onto the upper bowl lip (r 1.63, top 100.67)
UPDATE `gameobject` SET `position_x` = -8860.76, `position_y` = 647.84, `position_z` = 100.67, `orientation` = 4.01426 WHERE `guid` = 37765 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.69 yd out along bearing 17 deg onto the upper bowl lip (r 1.67, top 100.73)
UPDATE `gameobject` SET `position_x` = -8857.76, `position_y` = 649.16, `position_z` = 100.73, `orientation` = 0.104719 WHERE `guid` = 37767 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.23 yd out along bearing 98 deg onto the upper bowl lip (r 1.61, top 100.73)
UPDATE `gameobject` SET `position_x` = -8859.58, `position_y` = 650.27, `position_z` = 100.73, `orientation` = 1.65806 WHERE `guid` = 37770 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.26 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.77 yd out along bearing 261 deg onto the upper bowl lip (r 1.63, top 100.73)
UPDATE `gameobject` SET `position_x` = -8859.62, `position_y` = 647.07, `position_z` = 100.73, `orientation` = 4.7822 WHERE `guid` = 37771 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.19 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.13 yd out along bearing 134 deg onto the upper bowl lip (r 1.53, top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.42, `position_y` = 649.79, `position_z` = 100.73, `orientation` = 2.30383 WHERE `guid` = 37776 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.32 yd out along bearing 170 deg onto the upper bowl lip (r 1.61, top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.95, `position_y` = 648.95, `position_z` = 100.73, `orientation` = 3.26377 WHERE `guid` = 37778 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.25 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.73 yd out along bearing 321 deg onto the upper bowl lip (r 1.57, top 100.73)
UPDATE `gameobject` SET `position_x` = -8858.13, `position_y` = 647.7, `position_z` = 100.73, `orientation` = 5.55015 WHERE `guid` = 37780 AND `id` = 180425;
-- SkullCandle01: Hallow's End skull candle hovered 0.28 yd over the new upper bowl of the Trade District fountain
--   (Stormwindfountain_03); moved 0.41 yd out along bearing 60 deg onto the upper bowl lip (r 1.63, top 100.67)
UPDATE `gameobject` SET `position_x` = -8858.54, `position_y` = 650.09, `position_z` = 100.67, `orientation` = 0.837757 WHERE `guid` = 37790 AND `id` = 180425;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.25 yd out along bearing 116 deg onto the upper bowl lip (r 1.66,
--   top 100.67)
UPDATE `gameobject` SET `position_x` = -8860.09, `position_y` = 650.17, `position_z` = 100.67, `orientation` = 1.58825 WHERE `guid` = 241104 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.24 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.82 yd out along bearing 346 deg onto the upper bowl lip (r 1.65,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8857.76, `position_y` = 648.28, `position_z` = 100.73, `orientation` = -3.00197 WHERE `guid` = 241110 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.23 yd out along bearing 148 deg onto the upper bowl lip (r 1.56,
--   top 100.69)
UPDATE `gameobject` SET `position_x` = -8860.68, `position_y` = 649.51, `position_z` = 100.69, `orientation` = 0.017453 WHERE `guid` = 241178 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.27 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.65 yd out along bearing 236 deg onto the upper bowl lip (r 1.55,
--   top 100.72)
UPDATE `gameobject` SET `position_x` = -8860.22, `position_y` = 647.39, `position_z` = 100.72, `orientation` = 0.977384 WHERE `guid` = 241229 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.45 yd out along bearing 190 deg onto the upper bowl lip (r 1.61,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.95, `position_y` = 648.41, `position_z` = 100.73, `orientation` = 0.226893 WHERE `guid` = 241237 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.21 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.94 yd out along bearing 293 deg onto the upper bowl lip (r 1.72,
--   top 100.67)
UPDATE `gameobject` SET `position_x` = -8858.7, `position_y` = 647.09, `position_z` = 100.67, `orientation` = -2.25148 WHERE `guid` = 241240 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.47 yd out along bearing 39 deg onto the upper bowl lip (r 1.57,
--   top 100.72)
UPDATE `gameobject` SET `position_x` = -8858.15, `position_y` = 649.68, `position_z` = 100.72, `orientation` = -0.837758 WHERE `guid` = 241248 AND `id` = 181060;
-- Standing, Interior, Small - Val: Love is in the Air candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.32 yd out along bearing 79 deg onto the upper bowl lip (r 1.61,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8859.05, `position_y` = 650.26, `position_z` = 100.73, `orientation` = 1.44862 WHERE `guid` = 241256 AND `id` = 181060;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.25 yd out along bearing 116 deg onto the upper bowl lip (r 1.66,
--   top 100.67)
UPDATE `gameobject` SET `position_x` = -8860.09, `position_y` = 650.17, `position_z` = 100.67, `orientation` = 1.58825 WHERE `guid` = 53106 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.21 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.94 yd out along bearing 293 deg onto the upper bowl lip (r 1.72,
--   top 100.67)
UPDATE `gameobject` SET `position_x` = -8858.7, `position_y` = 647.09, `position_z` = 100.67, `orientation` = 4.03171 WHERE `guid` = 53203 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.23 yd out along bearing 148 deg onto the upper bowl lip (r 1.56,
--   top 100.69)
UPDATE `gameobject` SET `position_x` = -8860.68, `position_y` = 649.51, `position_z` = 100.69, `orientation` = 0.0174525 WHERE `guid` = 53208 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.45 yd out along bearing 190 deg onto the upper bowl lip (r 1.61,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.95, `position_y` = 648.41, `position_z` = 100.73, `orientation` = 0.226892 WHERE `guid` = 53326 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.47 yd out along bearing 39 deg onto the upper bowl lip (r 1.57,
--   top 100.72)
UPDATE `gameobject` SET `position_x` = -8858.15, `position_y` = 649.68, `position_z` = 100.72, `orientation` = 5.44543 WHERE `guid` = 53391 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.24 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.82 yd out along bearing 346 deg onto the upper bowl lip (r 1.65,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8857.76, `position_y` = 648.28, `position_z` = 100.73, `orientation` = 3.28124 WHERE `guid` = 53429 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.32 yd out along bearing 79 deg onto the upper bowl lip (r 1.61,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8859.05, `position_y` = 650.26, `position_z` = 100.73, `orientation` = 1.44862 WHERE `guid` = 53431 AND `id` = 181391;
-- Standing, Interior, Small - MFF: Midsummer brazier candle hovered 0.27 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.65 yd out along bearing 236 deg onto the upper bowl lip (r 1.55,
--   top 100.72)
UPDATE `gameobject` SET `position_x` = -8860.22, `position_y` = 647.39, `position_z` = 100.72, `orientation` = 0.977383 WHERE `guid` = 53459 AND `id` = 181391;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.24 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.82 yd out along bearing 346 deg onto the upper bowl lip (r 1.65,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8857.76, `position_y` = 648.28, `position_z` = 100.73, `orientation` = -3.00195 WHERE `guid` = 80502 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.45 yd out along bearing 190 deg onto the upper bowl lip (r 1.61,
--   top 100.73)
UPDATE `gameobject` SET `position_x` = -8860.95, `position_y` = 648.41, `position_z` = 100.73, `orientation` = 0.226892 WHERE `guid` = 80514 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.23 yd out along bearing 148 deg onto the upper bowl lip (r 1.56,
--   top 100.69)
UPDATE `gameobject` SET `position_x` = -8860.68, `position_y` = 649.51, `position_z` = 100.69, `orientation` = 0.017452 WHERE `guid` = 80523 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.27 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.65 yd out along bearing 236 deg onto the upper bowl lip (r 1.55,
--   top 100.72)
UPDATE `gameobject` SET `position_x` = -8860.22, `position_y` = 647.39, `position_z` = 100.72, `orientation` = 0.977383 WHERE `guid` = 80529 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.47 yd out along bearing 39 deg onto the upper bowl lip (r 1.57,
--   top 100.72)
UPDATE `gameobject` SET `position_x` = -8858.15, `position_y` = 649.68, `position_z` = 100.72, `orientation` = -0.837757 WHERE `guid` = 80536 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.21 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.94 yd out along bearing 293 deg onto the upper bowl lip (r 1.72,
--   top 100.67)
UPDATE `gameobject` SET `position_x` = -8858.7, `position_y` = 647.09, `position_z` = 100.67, `orientation` = -2.25147 WHERE `guid` = 80538 AND `id` = 195260;
-- Standing, Interior, Small - Brewfest: Brewfest brazier candle hovered 0.28 yd over the new upper bowl of the Trade
--   District fountain (Stormwindfountain_03); moved 0.25 yd out along bearing 116 deg onto the upper bowl lip (r 1.66,
--   top 100.67)
UPDATE `gameobject` SET `position_x` = -8860.09, `position_y` = 650.17, `position_z` = 100.67, `orientation` = 1.58825 WHERE `guid` = 80540 AND `id` = 195260;
-- Emmithue Smails: Emmithue Smails at the Trade District fountain plaza; same spot, CoA plaza floor 96.88 (sat 0.37 yd
--   sunk)
UPDATE `creature` SET `position_x` = -8864.46, `position_y` = 658.466, `position_z` = 96.878, `orientation` = 5.47143 WHERE `guid` = 86292 AND `id` = 14481;
-- G_Pumpkin_02: Hallow's End pumpkin; same spot, z on the A01Sw_Tradedistrict floor 96.944 (sat 0.42 yd sunk)
UPDATE `gameobject` SET `position_x` = -8864.63, `position_y` = 659.09, `position_z` = 96.944, `orientation` = 1.06465 WHERE `guid` = 36616 AND `id` = 180406;

-- ---------------------------------------------------------------------------
-- 6. Mage Quarter and the Park
-- ---------------------------------------------------------------------------
-- Sewer Beast: Sewer Beast pool 86300 spawn in the same canal; CoA canal bed is terrain 92.64 under water 95.46 (stock
--   WMO bed 85.89)
UPDATE `creature` SET `position_x` = -8906.12, `position_y` = 709.376, `position_z` = 92.637, `orientation` = 0.7132 WHERE `guid` = 300495 AND `id` = 3581;
-- Sewer Beast: Sewer Beast pool 86300 spawn; stock point is on the CoA canal bank (0.8 yd water), moved 8.6 yd west
--   into the 2 yd deep channel of the same canal
UPDATE `creature` SET `position_x` = -8859, `position_y` = 974, `position_z` = 93.055, `orientation` = 5.484 WHERE `guid` = 300494 AND `id` = 3581;
-- Rat: canal-side rat by the Park bridge; same spot, CoA terrain 1.4 yd above the stock floor
UPDATE `creature` SET `position_x` = -8842, `position_y` = 983.172, `position_z` = 99.952, `orientation` = 5.702 WHERE `guid` = 90450 AND `id` = 4075;
UPDATE `creature` SET `position_x` = -8839.89, `position_y` = 983.06, `position_z` = 99.768, `orientation` = 0.290615 WHERE `guid` = 120813 AND `id` = 4075;
-- Warden Thelwater: QuestSuperTrack turn-in 387/389/391 (id 529, r 5.5) on the Stockade entrance ramp, floor 88.58 on
--   both datasets; stock row 36 yd away in the courtyard
UPDATE `creature` SET `position_x` = -8767.15, `position_y` = 844.32, `position_z` = 88.576, `orientation` = 0.968697 WHERE `guid` = 89325 AND `id` = 1719;
-- Stormwind City Guard: guard post beside guard 19273 on the Mage Quarter canal street; stock spot is 0.22 yd from a
--   CoA railing (walled 3/8), moved 0.8 yd off it on the same side, same facing
UPDATE `creature` SET `position_x` = -8799.8, `position_y` = 864.8, `position_z` = 98.772, `orientation` = 2.381 WHERE `guid` = 26833 AND `id` = 68;
-- Argos Nightwhisper: druid trainer on the grass west of the CoA moonwell (A01Sw_Parkmoonwell); same spot, terrain
--   0.44 yd higher
UPDATE `creature` SET `position_x` = -8779, `position_y` = 1093.35, `position_z` = 93.271, `orientation` = 4.817 WHERE `guid` = 90452 AND `id` = 4984;
-- Sheldras Moontree: druid trainer on the grass west of the CoA moonwell; same spot, terrain 0.76 yd higher
UPDATE `creature` SET `position_x` = -8776, `position_y` = 1100.09, `position_z` = 93.385, `orientation` = 4.904 WHERE `guid` = 90465 AND `id` = 5504;
-- Shailiea: Park walker spawn = path 904770 node 1 by the south-entrance elm; terrain 1.0 yd above the stock floor
UPDATE `creature` SET `position_x` = -8756.84, `position_y` = 972.561, `position_z` = 99.594, `orientation` = 1.06461 WHERE `guid` = 90477 AND `id` = 7295;
-- Officer Pomeroy: Park patrol spawn = path 904840 node 1 at the south entrance; terrain 0.6 yd above the stock floor
UPDATE `creature` SET `position_x` = -8752.66, `position_y` = 984.545, `position_z` = 98.636, `orientation` = 0.523878 WHERE `guid` = 90484 AND `id` = 14438;
-- Maldryn: druid trainer by the CoA elven picnic table north of the moonwell; same spot, terrain 0.64 yd higher
UPDATE `creature` SET `position_x` = -8751, `position_y` = 1124.52, `position_z` = 93.276, `orientation` = 1.536 WHERE `guid` = 90467 AND `id` = 5506;
-- Kelly Grant, Kimberly Grant: child spawn on the Lunar stage lawn; stock stage floor is 2.2 yd under CoA terrain
UPDATE `creature` SET `position_x` = -8745.13, `position_y` = 1063.95, `position_z` = 92.142, `orientation` = 3.15163 WHERE `guid` = 90482 AND `id` = 11828;
UPDATE `creature` SET `position_x` = -8744.17, `position_y` = 1060.43, `position_z` = 92.149, `orientation` = 3.14535 WHERE `guid` = 90481 AND `id` = 11827;
-- Theridran: druid trainer: stock spot is on the rim of the CoA moonwell basin (walled 4/8); moved 1.4 yd onto the
--   grass beside it, same facing
UPDATE `creature` SET `position_x` = -8741, `position_y` = 1094, `position_z` = 92.542, `orientation` = 5.353 WHERE `guid` = 90466 AND `id` = 5505;
-- Sylista: stable master at the Park south entrance; stock platform gone, same spot on CoA terrain 1.2 yd lower
UPDATE `creature` SET `position_x` = -8738, `position_y` = 983.207, `position_z` = 96.356, `orientation` = 0.611 WHERE `guid` = 90479 AND `id` = 9977;
-- Nara Meideros: priest trainer on the grass east of the moonwell; same spot, terrain 0.93 yd higher
UPDATE `creature` SET `position_x` = -8728, `position_y` = 1102.96, `position_z` = 93.686, `orientation` = 3.875 WHERE `guid` = 90480 AND `id` = 11397;
-- Imelda: Imelda on the Park lawn by the north-east benches; same spot, terrain 1.8 yd higher (npcflag stays with
--   elwynn)
UPDATE `creature` SET `position_x` = -8721, `position_y` = 1137.16, `position_z` = 92.558, `orientation` = 3.481 WHERE `guid` = 90483 AND `id` = 11916;
-- Sewer Beast: Sewer Beast pool 86300 spawn in the same canal; CoA canal bed is terrain 91.92 under water 95.46 (3.5
--   yd deep)
UPDATE `creature` SET `position_x` = -8649, `position_y` = 927.668, `position_z` = 91.917, `orientation` = 3.854 WHERE `guid` = 300493 AND `id` = 3581;
-- Lunar Festival Harbinger: Lunar Festival stage on the Park lawn south of the CoA elf tents; same spot, terrain 1.6
--   yd higher
UPDATE `creature` SET `position_x` = -8756.05, `position_y` = 1068.8, `position_z` = 92.203, `orientation` = 5.53269 WHERE `guid` = 91632 AND `id` = 15895;
-- Lunar Festival Emissary: Lunar Festival stage, 2 yd east of CoA tent 02; same spot, terrain 2.0 yd higher
UPDATE `creature` SET `position_x` = -8752.71, `position_y` = 1077.18, `position_z` = 92.969, `orientation` = 5.65487 WHERE `guid` = 91637 AND `id` = 15892;
-- Large Spotlight: Lunar stage spotlight beside the moonlight focus; same spot, terrain 2.1 yd higher
UPDATE `creature` SET `position_x` = -8748.48, `position_y` = 1074.25, `position_z` = 92.721, `orientation` = 0.471239 WHERE `guid` = 91635 AND `id` = 15897;
-- Lunar Festival Emissary: Lunar Festival stage; same spot, terrain 2.0 yd higher
UPDATE `creature` SET `position_x` = -8747.97, `position_y` = 1069.06, `position_z` = 92.181, `orientation` = 1.6057 WHERE `guid` = 91633 AND `id` = 15892;
-- Lunar Festival Emissary: Lunar Festival stage; same spot, terrain 1.7 yd higher
UPDATE `creature` SET `position_x` = -8745.4, `position_y` = 1078.03, `position_z` = 92.554, `orientation` = 4.06662 WHERE `guid` = 91622 AND `id` = 15892;
-- Lunar Festival Vendor: Lunar vendor stall moved 1.5 yd south with its table and barrels to clear the CoA Sholazar
--   small rocks at (-8736.5, 1077)
UPDATE `creature` SET `position_x` = -8739.17, `position_y` = 1074.78, `position_z` = 92.321, `orientation` = 4.66003 WHERE `guid` = 91625 AND `id` = 15898;
-- Mage Quarter: Mage Quarter banner on the CoA canal-bridge arch (wall 0.8-1.0 yd behind); lowered 0.45 yd so its 8.9
--   yd cloth stays under the arch soffit at 113.97
UPDATE `gameobject` SET `position_x` = -8893.7, `position_y` = 749.804, `position_z` = 105.03, `orientation` = -0.898844 WHERE `guid` = 26650 AND `id` = 25348;
-- Mage Quarter: Mage Quarter banner on the CoA canal-bridge arch (wall 0.8-1.0 yd behind); lowered 0.45 yd so its
--   cloth stays under the arch soffit at 113.96
UPDATE `gameobject` SET `position_x` = -8873.05, `position_y` = 766.226, `position_z` = 105.03, `orientation` = -0.898844 WHERE `guid` = 26642 AND `id` = 25349;
-- The Park: The Park banner on the Park gate arch (wall 0.75-1.0 yd behind); lowered 0.44 yd so its top clears the CoA
--   arch soffit at 121.92
UPDATE `gameobject` SET `position_x` = -8806.95, `position_y` = 956.346, `position_z` = 112.55, `orientation` = 3.81355 WHERE `guid` = 42874 AND `id` = 25341;
-- The Park: The Park banner on the Park gate arch (wall 0.9-1.0 yd behind); lowered 0.44 yd so its top clears the CoA
--   arch soffit at 121.93
UPDATE `gameobject` SET `position_x` = -8790.71, `position_y` = 935.931, `position_z` = 112.55, `orientation` = 3.81355 WHERE `guid` = 61853 AND `id` = 25354;
-- Mage Quarter: pointer arm "Mage Quarter": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 2.3 yd
--   south-east; arm moved with the post, same offset, 0.87 yd lower to keep its gap under the shorter post top (same
--   post; not flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8875.144, `position_y` = 752.046, `position_z` = 94.997, `orientation` = 0.750492 WHERE `guid` = 26640 AND `id` = 2181;
-- The Park: pointer arm "The Park": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 2.3 yd south-east;
--   arm moved with the post, same offset, 0.87 yd lower to keep its gap under the shorter post top
UPDATE `gameobject` SET `position_x` = -8873.304, `position_y` = 751.982, `position_z` = 95.597, `orientation` = 5.46288 WHERE `guid` = 26643 AND `id` = 24715;
-- Trade District: pointer arm "Trade District": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 2.3 yd
--   south-east; arm moved with the post, same offset, 0.87 yd lower to keep its gap under the shorter post top (same
--   post; not flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8873.374, `position_y` = 750.141, `position_z` = 95.279, `orientation` = -2.3911 WHERE `guid` = 26651 AND `id` = 2176;
-- Stormwind Gate: pointer arm "Stormwind Gate": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 2.3 yd
--   south-east; arm moved with the post, same offset, 0.87 yd lower to keep its gap under the shorter post top (same
--   post; not flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8873.324, `position_y` = 750.076, `position_z` = 94.265, `orientation` = -2.3911 WHERE `guid` = 26659 AND `id` = 28042;
-- Trade District: pointer arm "Trade District": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 4.5 yd
--   north-west; arm moved with the post, same offset, 1.09 yd lower to keep its gap under the shorter post top (same
--   post; not flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8841.006, `position_y` = 926.093, `position_z` = 100.093, `orientation` = -2.64417 WHERE `guid` = 61878 AND `id` = 2128;
-- Mage Quarter: pointer arm "Mage Quarter": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 4.5 yd
--   north-west; arm moved with the post, same offset, 1.09 yd lower to keep its gap under the shorter post top
UPDATE `gameobject` SET `position_x` = -8842.766, `position_y` = 926.616, `position_z` = 100.693, `orientation` = 2.06821 WHERE `guid` = 61921 AND `id` = 2178;
-- The Park: pointer arm "The Park": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 4.5 yd north-west;
--   arm moved with the post, same offset, 1.09 yd lower to keep its gap under the shorter post top (same post; not
--   flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8840.486, `position_y` = 927.858, `position_z` = 100.693, `orientation` = 5.20981 WHERE `guid` = 61943 AND `id` = 24721;
-- The Park: pointer arm "The Park": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 4.9 yd south-west;
--   arm moved with the post, same offset, 0.53 yd lower to keep its gap under the shorter post top
UPDATE `gameobject` SET `position_x` = -8829.882, `position_y` = 960.704, `position_z` = 99.317, `orientation` = 5.4018 WHERE `guid` = 42866 AND `id` = 24720;
-- Cathedral Square: pointer arm "Cathedral Square": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 4.9
--   yd south-west; arm moved with the post, same offset, 0.53 yd lower to keep its gap under the shorter post top
--   (same post; not flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8830.062, `position_y` = 958.871, `position_z` = 98.717, `orientation` = 3.831 WHERE `guid` = 61907 AND `id` = 103794;
-- Mage Quarter: pointer arm "Mage Quarter": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 4.9 yd
--   south-west; arm moved with the post, same offset, 0.53 yd lower to keep its gap under the shorter post top
UPDATE `gameobject` SET `position_x` = -8831.892, `position_y` = 959.047, `position_z` = 99.317, `orientation` = 2.2602 WHERE `guid` = 61914 AND `id` = 2171;
-- Mage Quarter: pointer arm "Mage Quarter": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 3.9 yd
--   north-east; arm moved with the post, same offset, 1.27 yd lower to keep its gap under the shorter post top
UPDATE `gameobject` SET `position_x` = -8724.4, `position_y` = 891.478, `position_z` = 99.894, `orientation` = 2.2602 WHERE `guid` = 42934 AND `id` = 2141;
-- Cathedral Square: pointer arm "Cathedral Square": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 3.9
--   yd north-east; arm moved with the post, same offset, 1.27 yd lower to keep its gap under the shorter post top
--   (same post; not flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8722.56, `position_y` = 891.302, `position_z` = 99.293, `orientation` = 3.831 WHERE `guid` = 61930 AND `id` = 2186;
-- The Park: pointer arm "The Park": CoA replaced its stock Woodsignpostnice01 with Humansignpost03 3.9 yd north-east;
--   arm moved with the post, same offset, 1.27 yd lower to keep its gap under the shorter post top (same post; not
--   flagged by the survey)
UPDATE `gameobject` SET `position_x` = -8724.22, `position_y` = 893.311, `position_z` = 99.293, `orientation` = 0.689404 WHERE `guid` = 61939 AND `id` = 24719;
-- Moonwell: Moonwell spell focus (type 8, focus 883, invisible) inside the CoA A01Sw_Parkmoonwell basin that replaced
--   the stock park moonwell; z on the basin surface
UPDATE `gameobject` SET `position_x` = -8760.01, `position_y` = 1106.03, `position_z` = 93.811, `orientation` = 3.34736 WHERE `guid` = 42908 AND `id` = 177272;
UPDATE `gameobject` SET `position_x` = -8759.24, `position_y` = 1111.3, `position_z` = 93.838, `orientation` = 2.2321 WHERE `guid` = 42909 AND `id` = 177272;
UPDATE `gameobject` SET `position_x` = -8755.33, `position_y` = 1103.32, `position_z` = 93.612, `orientation` = 5.13337 WHERE `guid` = 42910 AND `id` = 177272;
UPDATE `gameobject` SET `position_x` = -8753.33, `position_y` = 1106.74, `position_z` = 94.029, `orientation` = 5.7876 WHERE `guid` = 42907 AND `id` = 177272;
-- The World Tree and the Emerald Dream: readable druid book: its stock Elvenstonetable01 is gone; laid on the CoA
--   Elvenwoodentable01 top (94.66) by druid trainer Maldryn north of the moonwell
UPDATE `gameobject` SET `position_x` = -8750.8, `position_y` = 1130.9, `position_z` = 94.662, `orientation` = -1 WHERE `guid` = 42903 AND `id` = 175730;
-- Mailbox: mailbox on the Park east lawn; same spot, CoA terrain 1.6 yd below the stock terrace floor, nothing in the
--   way
UPDATE `gameobject` SET `position_x` = -8712.93, `position_y` = 1013.34, `position_z` = 94.724, `orientation` = 3.87464 WHERE `guid` = 150741 AND `id` = 195611;
-- Food Crate: lootable Food Crate on the Park east lawn by the mailbox; fits stock (0.01 yd) but floats 0.53 yd on CoA
--   terrain (survey class fits came from the surface.py triangle-3 terrain bug)
UPDATE `gameobject` SET `position_x` = -8712, `position_y` = 1004.73, `position_z` = 96.29, `orientation` = 1.363 WHERE `guid` = 42855 AND `id` = 3662;
-- Mailbox: Mage Quarter mailbox; fits stock (0.0 yd) but floats 0.56 yd on CoA terrain 105.32 (survey class fits came
--   from the surface.py triangle-3 terrain bug)
UPDATE `gameobject` SET `position_x` = -9003.5, `position_y` = 860.55, `position_z` = 105.318, `orientation` = 5.07018 WHERE `guid` = 100506 AND `id` = 195610;
-- Barrel of Milk: lootable Barrel of Milk (chest loot 2579) from the gone picnic terrace (now a statue and elm trunk);
--   moved to the CoA Park picnic table, 1.5 yd off its south-west garden bench
UPDATE `gameobject` SET `position_x` = -8753.5, `position_y` = 1133.2, `position_z` = 92.925, `orientation` = -3 WHERE `guid` = 42856 AND `id` = 3705;
-- Camp Banner: Midsummer camp banner on the Mage Quarter-Park canal bridge; same bridge, CoA deck 1.6 yd lower
UPDATE `gameobject` SET `position_x` = -8838.21, `position_y` = 944.027, `position_z` = 104.276, `orientation` = 3.75246 WHERE `guid` = 81328 AND `id` = 188020;
-- Camp Banner: Midsummer camp banner: the CoA canal bridge runs 3.6 yd further west and its stock spot is over water;
--   moved onto the CoA deck by the south-east parapet
UPDATE `gameobject` SET `position_x` = -8834, `position_y` = 939.5, `position_z` = 104.641, `orientation` = 0.733038 WHERE `guid` = 81327 AND `id` = 188020;
-- Lights x3: Winter Veil lights under the eave of the building south of the Mage Quarter; CoA raised that eave and
--   beam by 1.92 yd (122.1/123.26 vs 120.18/121.34), lights follow it
UPDATE `gameobject` SET `position_x` = -9085.32, `position_y` = 827.946, `position_z` = 121.288, `orientation` = 0.383971 WHERE `guid` = 1889 AND `id` = 178645;
-- Lights x3, Lights: Winter Veil lights under the eave of the building south of the Mage Quarter; CoA raised that eave
--   and beam by 1.91 yd (122.1/123.26 vs 120.18/121.34), lights follow it
UPDATE `gameobject` SET `position_x` = -9060.05, `position_y` = 841.657, `position_z` = 121.262, `orientation` = 3.54302 WHERE `guid` = 1888 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9057.16, `position_y` = 835.097, `position_z` = 121.322, `orientation` = 3.49067 WHERE `guid` = 1877 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9055.89, `position_y` = 831.778, `position_z` = 121.182, `orientation` = 3.50812 WHERE `guid` = 1876 AND `id` = 178438;
-- Lights: Winter Veil lights under a Mage Quarter roof lip: CoA lip 122.02 vs stock 122.56, lowered 0.55 yd to keep
--   the stock 0.35 yd gap; wall 0.06 yd behind
UPDATE `gameobject` SET `position_x` = -9004.31, `position_y` = 940.953, `position_z` = 121.67, `orientation` = 2.74016 WHERE `guid` = 1891 AND `id` = 178924;
-- Lights: Winter Veil lights under a Mage Quarter roof lip: CoA lip 122.27 vs stock 122.57, lowered 0.30 yd to keep
--   the stock 0.43 yd gap; wall 0.05 yd behind
UPDATE `gameobject` SET `position_x` = -9003.21, `position_y` = 943.705, `position_z` = 121.84, `orientation` = 2.70526 WHERE `guid` = 1890 AND `id` = 178924;
-- Lights x3: Winter Veil lights under a Mage Quarter canal arch: CoA soffit 101.75 vs stock 102.36, lowered 0.61 yd to
--   keep the stock 1.26 yd gap; wall 0.8 yd
UPDATE `gameobject` SET `position_x` = -8844.86, `position_y` = 792.295, `position_z` = 100.49, `orientation` = 2.16421 WHERE `guid` = 40952 AND `id` = 178645;
-- Christmas Tree (Large): Winter Veil tree on the Park stage lawn: CoA tent 02 stands inside the 5.9 yd crown; tree
--   and presents moved 1.4 yd north-east together
UPDATE `gameobject` SET `position_x` = -8746.58, `position_y` = 1074.01, `position_z` = 92.549, `orientation` = 4.95674 WHERE `guid` = 293 AND `id` = 178425;
-- 16 rows: Winter Veil present around the tree on the Park stage lawn: CoA tent 02 stands inside the 5.9 yd crown;
--   tree and presents moved 1.4 yd north-east together
UPDATE `gameobject` SET `position_x` = -8745.23, `position_y` = 1072.4, `position_z` = 92.313, `orientation` = 1.36136 WHERE `guid` = 3112 AND `id` = 178428;
UPDATE `gameobject` SET `position_x` = -8747.77, `position_y` = 1074.06, `position_z` = 92.649, `orientation` = 2.07694 WHERE `guid` = 3113 AND `id` = 178428;
UPDATE `gameobject` SET `position_x` = -8744.95, `position_y` = 1074.42, `position_z` = 92.481, `orientation` = 5.34071 WHERE `guid` = 3122 AND `id` = 178429;
UPDATE `gameobject` SET `position_x` = -8746.26, `position_y` = 1072.27, `position_z` = 92.368, `orientation` = 0.017452 WHERE `guid` = 3123 AND `id` = 178429;
UPDATE `gameobject` SET `position_x` = -8748.29, `position_y` = 1074.9, `position_z` = 92.761, `orientation` = 5.3058 WHERE `guid` = 3124 AND `id` = 178429;
UPDATE `gameobject` SET `position_x` = -8745.57, `position_y` = 1075.75, `position_z` = 92.567, `orientation` = 4.29351 WHERE `guid` = 3130 AND `id` = 178430;
UPDATE `gameobject` SET `position_x` = -8747.49, `position_y` = 1072.93, `position_z` = 92.53, `orientation` = 0.645772 WHERE `guid` = 3131 AND `id` = 178430;
UPDATE `gameobject` SET `position_x` = -8744.3, `position_y` = 1073.13, `position_z` = 92.33, `orientation` = 1.36136 WHERE `guid` = 3137 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = -8746.01, `position_y` = 1074.65, `position_z` = 92.558, `orientation` = 5.67232 WHERE `guid` = 3138 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = -8748.71, `position_y` = 1073.41, `position_z` = 92.658, `orientation` = 3.6652 WHERE `guid` = 3139 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = -8745.39, `position_y` = 1073.22, `position_z` = 92.394, `orientation` = 0.191985 WHERE `guid` = 3143 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -8746.97, `position_y` = 1075.02, `position_z` = 92.665, `orientation` = 0.890117 WHERE `guid` = 3144 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -8748.36, `position_y` = 1072.35, `position_z` = 92.514, `orientation` = 5.02655 WHERE `guid` = 3145 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -8744, `position_y` = 1073.98, `position_z` = 92.399, `orientation` = 4.20625 WHERE `guid` = 3153 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -8746.76, `position_y` = 1076.12, `position_z` = 92.664, `orientation` = 3.75246 WHERE `guid` = 3154 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -8747, `position_y` = 1071.67, `position_z` = 92.365, `orientation` = 3.21142 WHERE `guid` = 3155 AND `id` = 178433;
-- Lights: Lunar Festival lights under the eave of the building south of the Mage Quarter; CoA raised that eave by 1.92
--   yd, lights follow it
UPDATE `gameobject` SET `position_x` = -9085.32, `position_y` = 827.946, `position_z` = 121.288, `orientation` = 0.383971 WHERE `guid` = 30802 AND `id` = 180770;
-- Lights: Lunar Festival lights under the eave of the building south of the Mage Quarter; CoA raised that eave by 1.91
--   yd, lights follow it
UPDATE `gameobject` SET `position_x` = -9060.05, `position_y` = 841.657, `position_z` = 121.262, `orientation` = 3.54302 WHERE `guid` = 29522 AND `id` = 180770;
UPDATE `gameobject` SET `position_x` = -9057.16, `position_y` = 835.097, `position_z` = 121.322, `orientation` = 3.49067 WHERE `guid` = 31175 AND `id` = 180769;
UPDATE `gameobject` SET `position_x` = -9055.89, `position_y` = 831.778, `position_z` = 121.182, `orientation` = 3.50812 WHERE `guid` = 29445 AND `id` = 180769;
-- Lights: Lunar Festival lights under a Mage Quarter canal arch: lowered 0.61 yd to keep the stock 1.26 yd gap under
--   the CoA soffit
UPDATE `gameobject` SET `position_x` = -8844.86, `position_y` = 792.295, `position_z` = 100.49, `orientation` = 2.16421 WHERE `guid` = 29487 AND `id` = 180770;
-- Firework Launcher, Cluster Launcher: Lunar firework launcher (spell focus): its stock canal platform (96.34) is open
--   CoA canal water; moved, same order, onto the CoA canal-side plaza 1.5 yd inside the railing west of the bridge
--   landing
UPDATE `gameobject` SET `position_x` = -8856.5, `position_y` = 947, `position_z` = 102.791, `orientation` = -0.890118 WHERE `guid` = 30805 AND `id` = 180771;
UPDATE `gameobject` SET `position_x` = -8858, `position_y` = 949, `position_z` = 102.799, `orientation` = -0.890118 WHERE `guid` = 29440 AND `id` = 180771;
UPDATE `gameobject` SET `position_x` = -8859.5, `position_y` = 951, `position_z` = 102.824, `orientation` = -0.872665 WHERE `guid` = 31155 AND `id` = 180772;
UPDATE `gameobject` SET `position_x` = -8861, `position_y` = 953, `position_z` = 102.797, `orientation` = -0.872665 WHERE `guid` = 29514 AND `id` = 180771;
-- Banner: Lunar standing banner at the Mage Quarter end of the canal bridge; same spot, CoA landing 0.5 yd higher
UPDATE `gameobject` SET `position_x` = -8851.84, `position_y` = 934.48, `position_z` = 102.79, `orientation` = 3.73501 WHERE `guid` = 19758 AND `id` = 180777;
-- Lantern: Lunar lantern post at the west of the Park stage; same spot, CoA terrain 1.2-1.8 yd higher
UPDATE `gameobject` SET `position_x` = -8769.56, `position_y` = 1069.19, `position_z` = 92.105, `orientation` = 6.26573 WHERE `guid` = 29488 AND `id` = 180766;
-- Lantern: Lunar lantern post at the south-west of the Park stage; same spot, CoA terrain 1.2-1.8 yd higher
UPDATE `gameobject` SET `position_x` = -8760.67, `position_y` = 1068.52, `position_z` = 92.161, `orientation` = 0 WHERE `guid` = 29523 AND `id` = 180766;
-- Lantern: Lunar lantern post at the south-east of the Park stage; same spot, CoA terrain 1.2-1.8 yd higher
UPDATE `gameobject` SET `position_x` = -8735.34, `position_y` = 1066.71, `position_z` = 92.176, `orientation` = 5.18363 WHERE `guid` = 30806 AND `id` = 180766;
-- Lantern: Lunar lantern post at the east of the Park stage; same spot, CoA terrain 1.2-1.8 yd higher
UPDATE `gameobject` SET `position_x` = -8731.94, `position_y` = 1060.68, `position_z` = 92.205, `orientation` = 5.18363 WHERE `guid` = 29524 AND `id` = 180766;
-- Lantern: Lunar lantern post at the north-east of the Park stage; same spot, CoA terrain 1.2-1.8 yd higher
UPDATE `gameobject` SET `position_x` = -8727.39, `position_y` = 1079.93, `position_z` = 92.509, `orientation` = 0.610863 WHERE `guid` = 29447 AND `id` = 180766;
-- Firecrackers: Lunar firecracker string hung on lantern 29488; keeps its stock 1.5625 yd height on the post (not
--   flagged by the survey; raised with its lantern)
UPDATE `gameobject` SET `position_x` = -8769.58, `position_y` = 1069.28, `position_z` = 93.668, `orientation` = 0 WHERE `guid` = 31224 AND `id` = 180871;
-- Firecrackers: Lunar firecracker string hung on lantern 29523; keeps its stock 1.6111 yd height on the post (not
--   flagged by the survey; raised with its lantern)
UPDATE `gameobject` SET `position_x` = -8760.69, `position_y` = 1068.68, `position_z` = 93.772, `orientation` = 3.07178 WHERE `guid` = 31226 AND `id` = 180763;
UPDATE `gameobject` SET `position_x` = -8760.69, `position_y` = 1068.68, `position_z` = 93.772, `orientation` = 3.07178 WHERE `guid` = 31244 AND `id` = 180764;
-- Firecrackers: Lunar firecracker string hung on lantern 30806; keeps its stock 1.6278 yd height on the post
UPDATE `gameobject` SET `position_x` = -8735.24, `position_y` = 1066.74, `position_z` = 93.804, `orientation` = -1.06465 WHERE `guid` = 31225 AND `id` = 180764;
UPDATE `gameobject` SET `position_x` = -8735.24, `position_y` = 1066.74, `position_z` = 93.804, `orientation` = -1.06465 WHERE `guid` = 31245 AND `id` = 180763;
UPDATE `gameobject` SET `position_x` = -8735.24, `position_y` = 1066.74, `position_z` = 93.804, `orientation` = -1.06465 WHERE `guid` = 31249 AND `id` = 180764;
-- Firecrackers: Lunar firecracker string hung on lantern 29524; keeps its stock 1.5654 yd height on the post (not
--   flagged by the survey; raised with its lantern)
UPDATE `gameobject` SET `position_x` = -8731.79, `position_y` = 1060.77, `position_z` = 93.77, `orientation` = 2.05949 WHERE `guid` = 31247 AND `id` = 180763;
-- Firecrackers: Lunar firecracker string hung on lantern 29447; keeps its stock 1.5555 yd height on the post
UPDATE `gameobject` SET `position_x` = -8727.5, `position_y` = 1080.04, `position_z` = 94.064, `orientation` = -2.53073 WHERE `guid` = 31223 AND `id` = 180872;
UPDATE `gameobject` SET `position_x` = -8727.5, `position_y` = 1080.04, `position_z` = 94.064, `orientation` = -2.53073 WHERE `guid` = 31248 AND `id` = 180872;
-- Banner: Lunar standing banner at the Park stage south-west corner; same spot, CoA terrain 1.3 yd higher
UPDATE `gameobject` SET `position_x` = -8758.12, `position_y` = 1068.52, `position_z` = 92.252, `orientation` = 2.74016 WHERE `guid` = 19747 AND `id` = 180777;
-- Firework Launcher, Cluster Launcher: Lunar firework launcher (spell focus) in the ring around the Park stage; same
--   spot on the CoA lawn, terrain 1.6-2.3 yd higher
UPDATE `gameobject` SET `position_x` = -8755.55, `position_y` = 1075.59, `position_z` = 93.033, `orientation` = -0.174533 WHERE `guid` = 30801 AND `id` = 180868;
UPDATE `gameobject` SET `position_x` = -8752.74, `position_y` = 1071.68, `position_z` = 92.626, `orientation` = 0.541052 WHERE `guid` = 29521 AND `id` = 180868;
UPDATE `gameobject` SET `position_x` = -8749.15, `position_y` = 1079.22, `position_z` = 92.82, `orientation` = -1.44862 WHERE `guid` = 29485 AND `id` = 180868;
UPDATE `gameobject` SET `position_x` = -8748.12, `position_y` = 1083.28, `position_z` = 92.893, `orientation` = -1.62316 WHERE `guid` = 29478 AND `id` = 180868;
UPDATE `gameobject` SET `position_x` = -8746.18, `position_y` = 1081.48, `position_z` = 92.707, `orientation` = -1.90241 WHERE `guid` = 31166 AND `id` = 180869;
UPDATE `gameobject` SET `position_x` = -8744.15, `position_y` = 1072.4, `position_z` = 92.262, `orientation` = 2.75762 WHERE `guid` = 30800 AND `id` = 180868;
UPDATE `gameobject` SET `position_x` = -8742, `position_y` = 1077.54, `position_z` = 92.434, `orientation` = -2.68781 WHERE `guid` = 31201 AND `id` = 180868;
-- Cluster Launcher: Lunar cluster launcher: stock spot is inside CoA tent 02; moved 2.5 yd east of the tent, still on
--   the stage ring
UPDATE `gameobject` SET `position_x` = -8751.5, `position_y` = 1078.5, `position_z` = 92.939, `orientation` = -0.959931 WHERE `guid` = 31173 AND `id` = 180869;
-- Firework Launcher: Lunar firework launcher: stock spot is inside CoA tent 02; moved 4.6 yd north-east of the tent
--   onto the stage lawn
UPDATE `gameobject` SET `position_x` = -8747, `position_y` = 1085, `position_z` = 92.853, `orientation` = -1.22173 WHERE `guid` = 31170 AND `id` = 180868;
-- Greater Moonlight Spell Focus: Greater Moonlight Spell Focus at the Park stage centre; same spot, CoA terrain 2.2 yd
--   higher
UPDATE `gameobject` SET `position_x` = -8748.9, `position_y` = 1074.2, `position_z` = 92.75, `orientation` = 4.97556 WHERE `guid` = 241006 AND `id` = 180867;
-- ElvenWoodenTable: Lunar vendor stall table moved 1.5 yd south with the stall to clear the CoA Sholazar small rocks
--   at (-8736.5, 1077)
UPDATE `gameobject` SET `position_x` = -8740.23, `position_y` = 1076.04, `position_z` = 92.402, `orientation` = 2.75761 WHERE `guid` = 19782 AND `id` = 180879;
-- 5 rows: ammo box on the Lunar stall table; moved with the table, same height on its top
UPDATE `gameobject` SET `position_x` = -8740.66, `position_y` = 1075.77, `position_z` = 94.223, `orientation` = 5.55015 WHERE `guid` = 19815 AND `id` = 180882;
UPDATE `gameobject` SET `position_x` = -8740.33, `position_y` = 1076.39, `position_z` = 94.214, `orientation` = 4.5204 WHERE `guid` = 19828 AND `id` = 180883;
UPDATE `gameobject` SET `position_x` = -8740.27, `position_y` = 1075.69, `position_z` = 94.229, `orientation` = 3.24635 WHERE `guid` = 19789 AND `id` = 180880;
UPDATE `gameobject` SET `position_x` = -8739.89, `position_y` = 1075.74, `position_z` = 94.218, `orientation` = 0.209439 WHERE `guid` = 19814 AND `id` = 180882;
UPDATE `gameobject` SET `position_x` = -8739.77, `position_y` = 1076.3, `position_z` = 94.226, `orientation` = 1.43117 WHERE `guid` = 19802 AND `id` = 180881;
-- GunShopFireworksBarrel: fireworks barrel of the Lunar vendor stall; moved 1.5 yd south with the stall (the stock
--   cluster overlaps the CoA small rocks at y 1076-1078)
UPDATE `gameobject` SET `position_x` = -8741.39, `position_y` = 1075.47, `position_z` = 92.411, `orientation` = 4.11898 WHERE `guid` = 31193 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8741.2, `position_y` = 1076.34, `position_z` = 92.413, `orientation` = 2.11185 WHERE `guid` = 29446 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8740.83, `position_y` = 1077.06, `position_z` = 92.416, `orientation` = 5.60251 WHERE `guid` = 31168 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8740.44, `position_y` = 1074.94, `position_z` = 92.368, `orientation` = 5.74214 WHERE `guid` = 30803 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8739.49, `position_y` = 1077.35, `position_z` = 92.451, `orientation` = 0.645772 WHERE `guid` = 31152 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8739.26, `position_y` = 1076.57, `position_z` = 92.391, `orientation` = 0.087266 WHERE `guid` = 31190 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8738.72, `position_y` = 1077.33, `position_z` = 92.5, `orientation` = 4.27606 WHERE `guid` = 29444 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8738.53, `position_y` = 1076.28, `position_z` = 92.381, `orientation` = 3.42085 WHERE `guid` = 29448 AND `id` = 180878;
UPDATE `gameobject` SET `position_x` = -8738.02, `position_y` = 1074.73, `position_z` = 92.283, `orientation` = 3.07177 WHERE `guid` = 31191 AND `id` = 180878;
-- Banner: Lunar standing banner beside the stall table; moved 1.5 yd south with the stall
UPDATE `gameobject` SET `position_x` = -8738.42, `position_y` = 1075.33, `position_z` = 92.322, `orientation` = 4.45059 WHERE `guid` = 19745 AND `id` = 180777;
-- Lantern: Lunar lantern post at the stall corner, its stock spot on a CoA small rock; moved south with the stall and
--   1.2 yd east off the rock
UPDATE `gameobject` SET `position_x` = -8736.5, `position_y` = 1075, `position_z` = 92.264, `orientation` = 0.575957 WHERE `guid` = 29526 AND `id` = 180766;
-- Firecrackers: Lunar firecracker string on stall lantern 29526; moved with it, same offset and stock 1.56 yd height
--   on the post
UPDATE `gameobject` SET `position_x` = -8736.55, `position_y` = 1075.08, `position_z` = 93.823, `orientation` = 0.541052 WHERE `guid` = 31246 AND `id` = 180871;
-- Alliance Bell: Hourly bell (sound object) on the Mage Quarter bell tower top; CoA tower top 124.09 vs stock 126.44
UPDATE `gameobject` SET `position_x` = -8812, `position_y` = 808.697, `position_z` = 124.085, `orientation` = 1.16937 WHERE `guid` = 42924 AND `id` = 176573;
-- Alliance Bell: Hourly bell sound object: the stock park structure it stood on (110.9) is gone; kept x,y and set on
--   the top of the CoA moonwell structure (98.09)
UPDATE `gameobject` SET `position_x` = -8760, `position_y` = 1117.5, `position_z` = 98.086, `orientation` = 2.478 WHERE `guid` = 42905 AND `id` = 176573;
-- Shailiea path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8756.84, `position_y` = 972.561, `position_z` = 99.594 WHERE `id` = 904770 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8753.84, `position_y` = 982.002, `position_z` = 98.606 WHERE `id` = 904770 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8736.16, `position_y` = 1006.67, `position_z` = 95.109 WHERE `id` = 904770 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -8732.54, `position_y` = 1013.69, `position_z` = 94.296 WHERE `id` = 904770 AND `point` = 6;
-- Shailiea path node: stock node sits on the CoA Sholazar_Rockd south of the Lunar stage; moved 5 yd east so the walk
--   passes east of the rock cluster
UPDATE `waypoint_data` SET `position_x` = -8729.5, `position_y` = 1049.5, `position_z` = 92.908 WHERE `id` = 904770 AND `point` = 9;
-- Shailiea path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8738.25, `position_y` = 1058.23, `position_z` = 92.206 WHERE `id` = 904770 AND `point` = 10;
UPDATE `waypoint_data` SET `position_x` = -8745.21, `position_y` = 1065.53, `position_z` = 92.142 WHERE `id` = 904770 AND `point` = 11;
UPDATE `waypoint_data` SET `position_x` = -8761.38, `position_y` = 1061.86, `position_z` = 92.125 WHERE `id` = 904770 AND `point` = 12;
UPDATE `waypoint_data` SET `position_x` = -8775.92, `position_y` = 1066.53, `position_z` = 92.079 WHERE `id` = 904770 AND `point` = 13;
UPDATE `waypoint_data` SET `position_x` = -8788.38, `position_y` = 1079.55, `position_z` = 92.156 WHERE `id` = 904770 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8794.83, `position_y` = 1090.96, `position_z` = 92.63 WHERE `id` = 904770 AND `point` = 15;
UPDATE `waypoint_data` SET `position_x` = -8796.58, `position_y` = 1109.54, `position_z` = 92.381 WHERE `id` = 904770 AND `point` = 16;
UPDATE `waypoint_data` SET `position_x` = -8794.6, `position_y` = 1126.23, `position_z` = 92.537 WHERE `id` = 904770 AND `point` = 17;
UPDATE `waypoint_data` SET `position_x` = -8790.06, `position_y` = 1135.35, `position_z` = 92.738 WHERE `id` = 904770 AND `point` = 18;
UPDATE `waypoint_data` SET `position_x` = -8781.22, `position_y` = 1144.03, `position_z` = 92.062 WHERE `id` = 904770 AND `point` = 19;
UPDATE `waypoint_data` SET `position_x` = -8761.02, `position_y` = 1148.73, `position_z` = 91.793 WHERE `id` = 904770 AND `point` = 20;
UPDATE `waypoint_data` SET `position_x` = -8747.48, `position_y` = 1147.88, `position_z` = 91.757 WHERE `id` = 904770 AND `point` = 21;
UPDATE `waypoint_data` SET `position_x` = -8746, `position_y` = 1147.37, `position_z` = 91.755 WHERE `id` = 904770 AND `point` = 22;
UPDATE `waypoint_data` SET `position_x` = -8733.29, `position_y` = 1140.57, `position_z` = 91.885 WHERE `id` = 904770 AND `point` = 23;
UPDATE `waypoint_data` SET `position_x` = -8722.54, `position_y` = 1131.25, `position_z` = 92.66 WHERE `id` = 904770 AND `point` = 24;
UPDATE `waypoint_data` SET `position_x` = -8716.62, `position_y` = 1115.2, `position_z` = 93.212 WHERE `id` = 904770 AND `point` = 25;
UPDATE `waypoint_data` SET `position_x` = -8718.66, `position_y` = 1097.44, `position_z` = 92.86 WHERE `id` = 904770 AND `point` = 26;
-- Shailiea path node: spline grazed the big CoA Sholazar_Rockd east of the moonwell; node moved 2.7 yd north-east
--   clear of it
UPDATE `waypoint_data` SET `position_x` = -8721, `position_y` = 1084, `position_z` = 92.51 WHERE `id` = 904770 AND `point` = 27;
-- Shailiea path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8727.99, `position_y` = 1077.14, `position_z` = 92.384 WHERE `id` = 904770 AND `point` = 28;
UPDATE `waypoint_data` SET `position_x` = -8740.12, `position_y` = 1070.97, `position_z` = 92.161 WHERE `id` = 904770 AND `point` = 29;
-- Shailiea path node: return leg crossed the same CoA rock cluster; node moved east of it, beside node 9
UPDATE `waypoint_data` SET `position_x` = -8729.5, `position_y` = 1052, `position_z` = 92.734 WHERE `id` = 904770 AND `point` = 30;
-- Shailiea path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8724.25, `position_y` = 1015.33, `position_z` = 94.099 WHERE `id` = 904770 AND `point` = 33;
-- Shailiea path node: leg ran through the CoA Sholazar_Rocka at (-8721,996); node moved 3.8 yd west onto open lawn
UPDATE `waypoint_data` SET `position_x` = -8727, `position_y` = 1001, `position_z` = 95.362 WHERE `id` = 904770 AND `point` = 34;
-- Shailiea path node: same rock; node moved 3.9 yd west so the leg passes west of it
UPDATE `waypoint_data` SET `position_x` = -8727, `position_y` = 989, `position_z` = 97.168 WHERE `id` = 904770 AND `point` = 35;
-- Shailiea path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8728.48, `position_y` = 973.112, `position_z` = 99.403 WHERE `id` = 904770 AND `point` = 37;
-- Shailiea path node: leg ran into the Elwynntreemid01 trunk at (-8733,963); node moved 4.5 yd north so the walk
--   passes it
UPDATE `waypoint_data` SET `position_x` = -8740, `position_y` = 966, `position_z` = 99.277 WHERE `id` = 904770 AND `point` = 38;
-- Shailiea path node: leg to node 1 crossed the roots of the Elwynntreecanopy04 by the south entrance; node moved 5.3
--   yd west so the walk passes south of the trunk
UPDATE `waypoint_data` SET `position_x` = -8757, `position_y` = 962.5, `position_z` = 101.585 WHERE `id` = 904770 AND `point` = 39;
-- Kimberly Grant path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8761.37, `position_y` = 1061.09, `position_z` = 92.136 WHERE `id` = 904810 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8779.77, `position_y` = 1068.92, `position_z` = 91.956 WHERE `id` = 904810 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8791.31, `position_y` = 1081.45, `position_z` = 92.368 WHERE `id` = 904810 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8797.06, `position_y` = 1099.97, `position_z` = 92.528 WHERE `id` = 904810 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -8790.39, `position_y` = 1133.75, `position_z` = 92.723 WHERE `id` = 904810 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -8780.95, `position_y` = 1133.62, `position_z` = 92.111 WHERE `id` = 904810 AND `point` = 6;
-- Kimberly Grant path node: stock node is on the CoA garden benches of the elven picnic table; moved 3 yd north of the
--   table
UPDATE `waypoint_data` SET `position_x` = -8748, `position_y` = 1135, `position_z` = 92.619 WHERE `id` = 904810 AND `point` = 8;
-- Kimberly Grant path node: the stock leg down the moonwell east side crosses the CoA moonwell platform and the
--   Sholazar rocks north of it; child now walks east along the north lawn to the park east edge
UPDATE `waypoint_data` SET `position_x` = -8722, `position_y` = 1131, `position_z` = 92.695 WHERE `id` = 904810 AND `point` = 9;
-- Kimberly Grant path node: down the park east edge, 4.5 yd east of the big CoA Sholazar_Rockd, instead of through the
--   moonwell platform
UPDATE `waypoint_data` SET `position_x` = -8717.5, `position_y` = 1090, `position_z` = 92.739 WHERE `id` = 904810 AND `point` = 10;
-- Kimberly Grant path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8729.51, `position_y` = 1078.65, `position_z` = 92.619 WHERE `id` = 904810 AND `point` = 11;
-- Kimberly Grant path node: leg to node 13 cut the north edge of the big CoA Sholazar_Rockd; node moved 4.7 yd north-
--   east
UPDATE `waypoint_data` SET `position_x` = -8721, `position_y` = 1080.5, `position_z` = 92.589 WHERE `id` = 904810 AND `point` = 12;
-- Kimberly Grant path node, Kelly Grant path node: node x,y kept; z set to the CoA floor under it (the stock
--   park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8718.23, `position_y` = 1102.08, `position_z` = 93.071 WHERE `id` = 904810 AND `point` = 13;
UPDATE `waypoint_data` SET `position_x` = -8721.48, `position_y` = 1127.58, `position_z` = 92.89 WHERE `id` = 904810 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8751.3, `position_y` = 1143.5, `position_z` = 91.828 WHERE `id` = 904810 AND `point` = 15;
UPDATE `waypoint_data` SET `position_x` = -8778.54, `position_y` = 1143.47, `position_z` = 91.971 WHERE `id` = 904810 AND `point` = 16;
UPDATE `waypoint_data` SET `position_x` = -8791.24, `position_y` = 1128.12, `position_z` = 92.471 WHERE `id` = 904810 AND `point` = 17;
UPDATE `waypoint_data` SET `position_x` = -8795.24, `position_y` = 1097.78, `position_z` = 92.467 WHERE `id` = 904810 AND `point` = 18;
UPDATE `waypoint_data` SET `position_x` = -8779.99, `position_y` = 1072.65, `position_z` = 91.901 WHERE `id` = 904810 AND `point` = 19;
UPDATE `waypoint_data` SET `position_x` = -8764.08, `position_y` = 1065.76, `position_z` = 92.121 WHERE `id` = 904810 AND `point` = 20;
UPDATE `waypoint_data` SET `position_x` = -8761.27, `position_y` = 1062.22, `position_z` = 92.123 WHERE `id` = 904820 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8778.38, `position_y` = 1070.87, `position_z` = 91.932 WHERE `id` = 904820 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8789.21, `position_y` = 1082.85, `position_z` = 92.343 WHERE `id` = 904820 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -8794.05, `position_y` = 1099.71, `position_z` = 92.365 WHERE `id` = 904820 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -8787.64, `position_y` = 1132.91, `position_z` = 92.219 WHERE `id` = 904820 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -8783.06, `position_y` = 1132.02, `position_z` = 92.146 WHERE `id` = 904820 AND `point` = 6;
-- Kelly Grant path node: stock leg from here crossed the CoA picnic table, benches and Kalidarstreetlamp02; node moved
--   4 yd north of the table
UPDATE `waypoint_data` SET `position_x` = -8747, `position_y` = 1136.5, `position_z` = 92.361 WHERE `id` = 904820 AND `point` = 8;
-- Kelly Grant path node: the stock leg down the moonwell east side crosses the CoA moonwell platform; child now walks
--   along the north lawn to the park east edge
UPDATE `waypoint_data` SET `position_x` = -8723, `position_y` = 1132.5, `position_z` = 92.567 WHERE `id` = 904820 AND `point` = 9;
-- Kelly Grant path node: down the park east edge, 5 yd east of the big CoA Sholazar_Rockd, instead of through the
--   moonwell
UPDATE `waypoint_data` SET `position_x` = -8716.5, `position_y` = 1091, `position_z` = 92.802 WHERE `id` = 904820 AND `point` = 10;
-- Kelly Grant path node, Officer Pomeroy path node: node x,y kept; z set to the CoA floor under it (the stock
--   park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8730.16, `position_y` = 1075.13, `position_z` = 92.226 WHERE `id` = 904820 AND `point` = 11;
UPDATE `waypoint_data` SET `position_x` = -8725.81, `position_y` = 1077.14, `position_z` = 92.438 WHERE `id` = 904820 AND `point` = 12;
UPDATE `waypoint_data` SET `position_x` = -8715.35, `position_y` = 1101.82, `position_z` = 93.008 WHERE `id` = 904820 AND `point` = 13;
UPDATE `waypoint_data` SET `position_x` = -8717.51, `position_y` = 1128.35, `position_z` = 92.997 WHERE `id` = 904820 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8751.02, `position_y` = 1147.41, `position_z` = 91.778 WHERE `id` = 904820 AND `point` = 15;
UPDATE `waypoint_data` SET `position_x` = -8778.51, `position_y` = 1146.38, `position_z` = 92.009 WHERE `id` = 904820 AND `point` = 16;
UPDATE `waypoint_data` SET `position_x` = -8795.87, `position_y` = 1127.45, `position_z` = 92.651 WHERE `id` = 904820 AND `point` = 17;
UPDATE `waypoint_data` SET `position_x` = -8799.38, `position_y` = 1097.38, `position_z` = 92.837 WHERE `id` = 904820 AND `point` = 18;
UPDATE `waypoint_data` SET `position_x` = -8783.24, `position_y` = 1067.4, `position_z` = 91.949 WHERE `id` = 904820 AND `point` = 19;
UPDATE `waypoint_data` SET `position_x` = -8764.99, `position_y` = 1061.95, `position_z` = 92.125 WHERE `id` = 904820 AND `point` = 20;
UPDATE `waypoint_data` SET `position_x` = -8752.66, `position_y` = 984.545, `position_z` = 98.636 WHERE `id` = 904840 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -8741.39, `position_y` = 994.762, `position_z` = 96.113 WHERE `id` = 904840 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -8735.94, `position_y` = 1002.67, `position_z` = 95.172 WHERE `id` = 904840 AND `point` = 3;
-- Officer Pomeroy path node: leg to node 6 crossed the CoA Sholazar_Rockd south of the Lunar stage; node moved 6 yd
--   east of the rock cluster
UPDATE `waypoint_data` SET `position_x` = -8729.2, `position_y` = 1034.5, `position_z` = 93.697 WHERE `id` = 904840 AND `point` = 5;
-- Officer Pomeroy path node: same rock cluster; node moved 8.9 yd east so the patrol passes east of it
UPDATE `waypoint_data` SET `position_x` = -8729.5, `position_y` = 1052, `position_z` = 92.734 WHERE `id` = 904840 AND `point` = 6;
-- Officer Pomeroy path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8739.43, `position_y` = 1058, `position_z` = 92.249 WHERE `id` = 904840 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -8744.14, `position_y` = 1061.82, `position_z` = 92.144 WHERE `id` = 904840 AND `point` = 8;
UPDATE `waypoint_data` SET `position_x` = -8764.37, `position_y` = 1064.67, `position_z` = 92.121 WHERE `id` = 904840 AND `point` = 9;
UPDATE `waypoint_data` SET `position_x` = -8781.69, `position_y` = 1076.98, `position_z` = 91.921 WHERE `id` = 904840 AND `point` = 10;
UPDATE `waypoint_data` SET `position_x` = -8796.28, `position_y` = 1092.95, `position_z` = 92.74 WHERE `id` = 904840 AND `point` = 11;
UPDATE `waypoint_data` SET `position_x` = -8795.5, `position_y` = 1119.57, `position_z` = 92.491 WHERE `id` = 904840 AND `point` = 12;
UPDATE `waypoint_data` SET `position_x` = -8793.8, `position_y` = 1130.77, `position_z` = 92.88 WHERE `id` = 904840 AND `point` = 13;
UPDATE `waypoint_data` SET `position_x` = -8782.68, `position_y` = 1143.68, `position_z` = 92.164 WHERE `id` = 904840 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -8759.2, `position_y` = 1146.64, `position_z` = 91.809 WHERE `id` = 904840 AND `point` = 15;
UPDATE `waypoint_data` SET `position_x` = -8748.11, `position_y` = 1147.71, `position_z` = 91.761 WHERE `id` = 904840 AND `point` = 16;
UPDATE `waypoint_data` SET `position_x` = -8733.45, `position_y` = 1142.43, `position_z` = 91.867 WHERE `id` = 904840 AND `point` = 17;
UPDATE `waypoint_data` SET `position_x` = -8721.39, `position_y` = 1127.38, `position_z` = 92.903 WHERE `id` = 904840 AND `point` = 18;
UPDATE `waypoint_data` SET `position_x` = -8718.16, `position_y` = 1123.04, `position_z` = 93.147 WHERE `id` = 904840 AND `point` = 19;
UPDATE `waypoint_data` SET `position_x` = -8718.36, `position_y` = 1096.83, `position_z` = 92.885 WHERE `id` = 904840 AND `point` = 20;
UPDATE `waypoint_data` SET `position_x` = -8724.41, `position_y` = 1080.53, `position_z` = 92.441 WHERE `id` = 904840 AND `point` = 21;
UPDATE `waypoint_data` SET `position_x` = -8736.32, `position_y` = 1072.91, `position_z` = 92.189 WHERE `id` = 904840 AND `point` = 22;
UPDATE `waypoint_data` SET `position_x` = -8738.35, `position_y` = 1069.65, `position_z` = 92.157 WHERE `id` = 904840 AND `point` = 23;
-- Officer Pomeroy path node: stock node is buried in the same rock cluster; moved 3.7 yd east beside node 6
UPDATE `waypoint_data` SET `position_x` = -8729, `position_y` = 1048, `position_z` = 92.981 WHERE `id` = 904840 AND `point` = 24;
-- Officer Pomeroy path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8730.01, `position_y` = 1006.36, `position_z` = 94.531 WHERE `id` = 904840 AND `point` = 26;
UPDATE `waypoint_data` SET `position_x` = -8731.84, `position_y` = 984.735, `position_z` = 96.591 WHERE `id` = 904840 AND `point` = 27;
-- Officer Pomeroy path node: leg to node 29 brushed the Elwynntreemid01 trunk at the Park south entrance (box x
--   -8735.4..-8730.9, y 962.4..966.4); node moved 1.6 yd west of it
UPDATE `waypoint_data` SET `position_x` = -8735.8, `position_y` = 967, `position_z` = 100.015 WHERE `id` = 904840 AND `point` = 28;
-- Officer Pomeroy path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8736.23, `position_y` = 951.668, `position_z` = 101.206 WHERE `id` = 904840 AND `point` = 29;
UPDATE `waypoint_data` SET `position_x` = -8722.11, `position_y` = 928.124, `position_z` = 101.288 WHERE `id` = 904840 AND `point` = 32;
UPDATE `waypoint_data` SET `position_x` = -8722.26, `position_y` = 874.55, `position_z` = 103.189 WHERE `id` = 904840 AND `point` = 39;
UPDATE `waypoint_data` SET `position_x` = -8712.04, `position_y` = 860.936, `position_z` = 98.145 WHERE `id` = 904840 AND `point` = 41;
UPDATE `waypoint_data` SET `position_x` = -8731.62, `position_y` = 723.097, `position_z` = 100.846 WHERE `id` = 904840 AND `point` = 57;
UPDATE `waypoint_data` SET `position_x` = -8741.27, `position_y` = 712.251, `position_z` = 99.257 WHERE `id` = 904840 AND `point` = 58;
-- Officer Pomeroy path node: CoA bank: the entrance hall meets the raised main hall (100.23) only through the gap y
--   622-625 beside the new Stormwind_Vault_Door.m2; node moved into the main hall through that gap
UPDATE `waypoint_data` SET `position_x` = -8919, `position_y` = 622, `position_z` = 100.225 WHERE `id` = 904840 AND `point` = 77;
-- Officer Pomeroy path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8922.34, `position_y` = 609.779, `position_z` = 100.226 WHERE `id` = 904840 AND `point` = 78;
UPDATE `waypoint_data` SET `position_x` = -8925.15, `position_y` = 610.6, `position_z` = 100.226 WHERE `id` = 904840 AND `point` = 79;
UPDATE `waypoint_data` SET `position_x` = -8931.44, `position_y` = 623.484, `position_z` = 100.226 WHERE `id` = 904840 AND `point` = 80;
UPDATE `waypoint_data` SET `position_x` = -8930.31, `position_y` = 626.043, `position_z` = 100.226 WHERE `id` = 904840 AND `point` = 81;
-- Officer Pomeroy path node: stock node is outside the CoA main-hall floor (terrain 98.66 behind the vault door);
--   moved into the main hall at the gap
UPDATE `waypoint_data` SET `position_x` = -8921, `position_y` = 623, `position_z` = 100.226 WHERE `id` = 904840 AND `point` = 82;
-- Officer Pomeroy path node: leg from node 82 ran through the CoA vault door model; node moved 4.2 yd to the entrance-
--   hall side of the gap
UPDATE `waypoint_data` SET `position_x` = -8911, `position_y` = 624, `position_z` = 99.525 WHERE `id` = 904840 AND `point` = 83;
-- Officer Pomeroy path node: node x,y kept; z set to the CoA floor under it (the stock park/street floor moved)
UPDATE `waypoint_data` SET `position_x` = -8868.77, `position_y` = 758.386, `position_z` = 97.796 WHERE `id` = 904840 AND `point` = 95;
UPDATE `waypoint_data` SET `position_x` = -8848.92, `position_y` = 931.486, `position_z` = 103.058 WHERE `id` = 904840 AND `point` = 144;
UPDATE `waypoint_data` SET `position_x` = -8835.17, `position_y` = 940.071, `position_z` = 104.416 WHERE `id` = 904840 AND `point` = 145;
UPDATE `waypoint_data` SET `position_x` = -8789.35, `position_y` = 953.595, `position_z` = 101.532 WHERE `id` = 904840 AND `point` = 151;
UPDATE `waypoint_data` SET `position_x` = -8772.84, `position_y` = 966.926, `position_z` = 101.637 WHERE `id` = 904840 AND `point` = 152;
UPDATE `waypoint_data` SET `position_x` = -8765.21, `position_y` = 973.437, `position_z` = 100.813 WHERE `id` = 904840 AND `point` = 153;
UPDATE `waypoint_data` SET `position_x` = -8757.27, `position_y` = 979.708, `position_z` = 99.213 WHERE `id` = 904840 AND `point` = 154;
-- Adam SmartAI path node 37, Adam SmartAI path node 41: same spot at the Park quay edge; CoA quay floor 99.71 (stock
--   node 97.85 lies 1.9 yd under it)
UPDATE `waypoints` SET `position_x` = -8838.33, `position_y` = 972.23, `position_z` = 99.706 WHERE `entry` = 1366 AND `pointid` = 37;
UPDATE `waypoints` SET `position_x` = -8838.33, `position_y` = 972.23, `position_z` = 99.706 WHERE `entry` = 1366 AND `pointid` = 41;
-- Adam SmartAI path node 38, Adam SmartAI path node 40: CoA removed the stock canal fishing platform (96.34) at the
--   Park; Adam's detour to it (pause node 39, 30 min facing 5.41 along the canal) would end over canal water (95.46);
--   the detour now runs onto the Park quay walkway (A01Sw_Parkdistrict 99.7-99.8) behind its coping, and he pauses at
--   the canal edge looking along the canal; turnaround on the walkway
UPDATE `waypoints` SET `position_x` = -8839.01, `position_y` = 971.23, `position_z` = 99.724 WHERE `entry` = 1366 AND `pointid` = 38;
UPDATE `waypoints` SET `position_x` = -8839.01, `position_y` = 971.23, `position_z` = 99.724 WHERE `entry` = 1366 AND `pointid` = 40;
-- Adam SmartAI path node 39: CoA removed the stock canal fishing platform (96.34) at the Park; Adam's detour to it
--   (pause node 39, 30 min facing 5.41 along the canal) would end over canal water (95.46); the detour now runs onto
--   the Park quay walkway (A01Sw_Parkdistrict 99.7-99.8) behind its coping, and he pauses at the canal edge looking
--   along the canal; the pause spot
UPDATE `waypoints` SET `position_x` = -8839.1, `position_y` = 968.26, `position_z` = 99.773 WHERE `entry` = 1366 AND `pointid` = 39;
-- Billy - On Data Set 1 6 - Move to POS: Billy joins Adam at his canal pause (Adam 1366 node 39); the stock point was
--   on the removed fishing platform, now canal water; beside Adam on the Park quay walkway, 1.8 yd inland of him, same
--   facing
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1367 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1367, 0, 0, 0, 38, 0, 100, 512, 1, 0, 0, 0, 0, 0, 29, 0, 330, 0, 0, 0, 0, 10, 79702, 1366, 0, 0, 0, 0, 0, 0, 'Billy - On Data Set 1 0 - Set Follow'),
(1367, 0, 1, 0, 38, 0, 100, 0, 1, 2, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8746.15, 534.447, 96.338, 0.942478, 'Billy - On Data Set 1 2 - Move to POS'),
(1367, 0, 2, 0, 38, 0, 100, 512, 1, 4, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0.942478, 'Billy - On Data Set 1 4 - Set Orientation'),
(1367, 0, 3, 0, 38, 0, 100, 0, 1, 3, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8793.93, 771.825, 96.338, 1.6493, 'Billy - On Data Set 1 3 - Move to POS'),
(1367, 0, 4, 0, 38, 0, 100, 512, 1, 5, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 1.6493, 'Billy - On Data Set 1 5 - Set Orientation'),
(1367, 0, 5, 0, 38, 0, 100, 0, 1, 6, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8837.93, 969.66, 99.726, 5.40947, 'Billy - On Data Set 1 6 - Move to POS'),
(1367, 0, 6, 0, 38, 0, 100, 512, 1, 7, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 5.40947, 'Billy - On Data Set 1 7 - Set Orientation'),
(1367, 0, 7, 0, 38, 0, 100, 512, 1, 8, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Billy - On Data Set 1 8 - Set Phase 1'),
(1367, 0, 8, 0, 38, 0, 100, 512, 1, 9, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Billy - On Data Set 1 9 - Set Phase 0'),
(1367, 0, 9, 0, 38, 0, 100, 0, 1, 10, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Billy - On Data Set 1 10 - Say Line 1'),
(1367, 0, 10, 0, 1, 0, 100, 512, 30000, 30000, 90000, 160000, 0, 0, 80, 136700, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Billy - OOC - Run Script'),
(1367, 0, 11, 0, 1, 1, 20, 512, 8000, 8000, 90000, 150000, 0, 0, 80, 136701, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Billy - OOC - Run Script (Phase 1)');
-- Brandon SmartAI path node 30, Brandon SmartAI path node 34: same spot on the Cathedral-side quay; CoA quay floor
--   97.99 (stock node 96.96 lies 1.0 yd under it)
UPDATE `waypoints` SET `position_x` = -8663.31, `position_y` = 909.1, `position_z` = 97.992 WHERE `entry` = 1370 AND `pointid` = 30;
UPDATE `waypoints` SET `position_x` = -8663.31, `position_y` = 909.1, `position_z` = 97.992 WHERE `entry` = 1370 AND `pointid` = 34;
-- Brandon SmartAI path node 31, Brandon SmartAI path node 33: CoA removed the stock canal fishing platform (96.34) by
--   the Cathedral; Brandon's detour to it (pause node 32, 60 min facing 2.28) would end over canal water (95.46); the
--   detour now runs along the Cathedral-side quay walkway (A01Sw_Cathedraldistrict 98.0) behind its parapet, and he
--   pauses at the edge facing the canal; turnaround on the walkway
UPDATE `waypoints` SET `position_x` = -8664.46, `position_y` = 906.15, `position_z` = 97.998 WHERE `entry` = 1370 AND `pointid` = 31;
UPDATE `waypoints` SET `position_x` = -8664.46, `position_y` = 906.15, `position_z` = 97.998 WHERE `entry` = 1370 AND `pointid` = 33;
-- Brandon SmartAI path node 32: CoA removed the stock canal fishing platform (96.34) by the Cathedral; Brandon's
--   detour to it (pause node 32, 60 min facing 2.28) would end over canal water (95.46); the detour now runs along the
--   Cathedral-side quay walkway (A01Sw_Cathedraldistrict 98.0) behind its parapet, and he pauses at the edge facing
--   the canal; the pause spot
UPDATE `waypoints` SET `position_x` = -8666.25, `position_y` = 906.34, `position_z` = 97.984 WHERE `entry` = 1370 AND `pointid` = 32;
-- Justin - On Data Set 1 3 - Move to POS: Justin joins Brandon at his canal pause (Brandon 1370 node 32); the stock
--   point was on the removed fishing platform, now canal water; on the Cathedral quay walkway 2 yd north-west of
--   Brandon, facing along the quay toward him as before
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1368 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1368, 0, 0, 0, 38, 0, 100, 512, 1, 0, 0, 0, 0, 0, 29, 0, 75, 0, 0, 0, 0, 10, 79817, 1370, 0, 0, 0, 0, 0, 0, 'Justin - On Data Set 1 0 - Set Follow'),
(1368, 0, 1, 0, 38, 0, 100, 0, 1, 2, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8582.03, 633.634, 96.3386, 5.0381, 'Justin - On Data Set 1 2 - Move to POS'),
(1368, 0, 2, 0, 38, 0, 100, 512, 1, 4, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 5.0381, 'Justin - On Data Set 1 4 - Set Orientation'),
(1368, 0, 3, 0, 38, 0, 100, 0, 1, 3, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8664.82, 907.75, 98.013, 3.768, 'Justin - On Data Set 1 3 - Move to POS'),
(1368, 0, 4, 0, 38, 0, 100, 512, 1, 5, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 3.768, 'Justin - On Data Set 1 5 - Set Orientation'),
(1368, 0, 5, 0, 1, 0, 100, 512, 30000, 30000, 80000, 160000, 0, 0, 80, 136800, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Justin - OOC - Run Script');
-- Roman - On Data Set 1 3 - Move to POS: Roman joins Brandon at his canal pause (Brandon 1370 node 32); the stock
--   point was on the removed fishing platform, now canal water; on the Cathedral quay walkway 1.8 yd south-east of
--   Brandon, facing the canal as before
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1371 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1371, 0, 0, 0, 38, 0, 100, 512, 1, 0, 0, 0, 0, 0, 29, 0, 285, 0, 0, 0, 0, 10, 79817, 1370, 0, 0, 0, 0, 0, 0, 'Roman - On Data Set 1 0 - Set Follow'),
(1371, 0, 1, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Roman - On Data Set 1 1 - Say Random 0'),
(1371, 0, 2, 0, 38, 0, 100, 0, 1, 2, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8583.88, 633.127, 96.3386, 5.0381, 'Roman - On Data Set 1 2 - Move to POS'),
(1371, 0, 3, 0, 38, 0, 100, 512, 1, 4, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 5.0381, 'Roman - On Data Set 1 4 - Set Orientation'),
(1371, 0, 4, 0, 38, 0, 100, 0, 1, 3, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -8667.48, 905.02, 97.957, 2.282, 'Roman - On Data Set 1 3 - Move to POS'),
(1371, 0, 5, 0, 38, 0, 100, 512, 1, 5, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 2.282, 'Roman - On Data Set 1 5 - Set Orientation');
-- Christmas Tree (Medium): Winter Veil tree at the Mage Quarter; same spot, CoA terrain 117.60 (sat 0.36 yd sunk)
UPDATE `gameobject` SET `position_x` = -8934.1, `position_y` = 972.866, `position_z` = 117.599, `orientation` = 5.02655 WHERE `guid` = 298 AND `id` = 178667;
-- Banner: Lunar Festival standing banner in the Park; same spot, CoA terrain 96.53 (sat 0.37 yd sunk)
UPDATE `gameobject` SET `position_x` = -8744.13, `position_y` = 1009.64, `position_z` = 96.534, `orientation` = 4.2237 WHERE `guid` = 19746 AND `id` = 180777;
-- Meeting Stone: Stormwind meeting stone by the Mage Quarter canal; same spot, z on the CoA terrain 98.52 with its
--   stock 0.25 yd set-in
UPDATE `gameobject` SET `position_x` = -8810.5, `position_y` = 798.038, `position_z` = 98.267, `orientation` = -3.0456 WHERE `guid` = 26635 AND `id` = 179595;
-- Standing, Exterior, Medium - MFF: Midsummer brazier by the Mage Quarter; same spot, CoA terrain 96.19 (sat 0.34 yd
--   sunk)
UPDATE `gameobject` SET `position_x` = -8839.8, `position_y` = 772.621, `position_z` = 96.186, `orientation` = 3.08918 WHERE `guid` = 51672 AND `id` = 181355;
-- Camp Banner: Midsummer camp banner by the Mage Quarter; same spot, CoA terrain 96.45 (sat 0.47 yd sunk)
UPDATE `gameobject` SET `position_x` = -8826.6, `position_y` = 782.687, `position_z` = 96.452, `orientation` = 3.927 WHERE `guid` = 52461 AND `id` = 188020;
-- Firework Launcher: Lunar Festival launcher that stood inside CoA's night elf tent (Nightelfsingletent01, walled 5/8)
--   in the Park camp; moved 1.9 yd east onto open grass just outside the tent, 3.5 yd from its neighbour 30801
UPDATE `gameobject` SET `position_x` = -8759, `position_y` = 1075.8, `position_z` = 93.121, `orientation` = -0.10472 WHERE `guid` = 30799 AND `id` = 180868;
-- Elder Hammershout: Elder Hammershout (Lunar Festival, quest 8646) stood 0.35 yd inside the edge of the moonwell rock
--   (Sholazar_Rockb) CoA placed at his Park spot; nudged 0.5 yd onto the rock's flat top by the moonwell (slope 14,
--   headroom 3.9)
UPDATE `creature` SET `position_x` = -8762.24, `position_y` = 1093.14, `position_z` = 95.063, `orientation` = 5.13127 WHERE `guid` = 91630 AND `id` = 15562;
-- Holiday - Lunar Teleport: Stormwind: Lunar Festival teleport from Moonglade landed on the stock Stormwind.wmo floor,
--   2.2 yd under the CoA Park terrain with nothing below; same spot, z on the terrain 92.667 (open, slope 6.7)
UPDATE `spell_target_position` SET `PositionX` = -8748.48, `PositionY` = 1073.61, `PositionZ` = 92.667 WHERE `ID` = 26454 AND `EffectIndex` = 0;
-- Sealed Crate - On Quest 'The Legend of Stalvan' Taken - Summon Creature 'Forlorn Spirit': quest 74: the Forlorn
--   Spirit that must be killed for item 916 was summoned 1.3 yd under the CoA Park terrain (summons use target_z
--   verbatim); same spot, z on the terrain 100.008 (open, slope 5.5), 11.6 yd from the Sealed Crate
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1561 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(1561, 1, 0, 0, 19, 0, 100, 0, 74, 0, 0, 0, 0, 0, 12, 2044, 1, 30000, 0, 0, 0, 8, 0, 0, 0, 0, -8841.93, 985.171, 100.008, 6.00926, 'Sealed Crate - On Quest ''The Legend of Stalvan'' Taken - Summon Creature ''Forlorn Spirit''');
-- Stormwind Harbor Guard: canal guard; same spot, z on the corrected CoA terrain with the stock 0.08 offset (floated
--   0.46)
UPDATE `creature` SET `position_x` = -8642.95, `position_y` = 956.384, `position_z` = 99.298, `orientation` = 5.23599 WHERE `guid` = 120637 AND `id` = 29712;
-- Mailbox: Park mailbox beside the street lamp; same spot, CoA grass 2.6 yd above the buried stock floor it stood on
UPDATE `gameobject` SET `position_x` = -8797.43, `position_y` = 1083.48, `position_z` = 92.813, `orientation` = 5.4367 WHERE `guid` = 42900 AND `id` = 144130;
-- Wooden Chair: deleted; decorative chair of the stock picnic terrace (floor 96.05, table with Jar02/Jar03/candelabra
--   at -8718.8,1051.7); CoA removed terrace and table (terrain 92.7, no model within 10 yd); no NPC sits on it, no
--   script refers to it
DELETE FROM `gameobject` WHERE `guid` IN (42800, 42801, 42794, 42802, 42793, 42803);
-- Wooden Chair: deleted; decorative chair of the stock Inntablesmall at (-8703.6,1048.6); CoA put an Elwynntreemid01
--   trunk and Kalidarwoodstatue02 there and removed the terrace; no NPC sits on it, no script refers to it
DELETE FROM `gameobject` WHERE `guid` IN (42795, 42798, 42796, 42797);
-- Wreath scale 0.75: deleted; Winter Veil wreath: the stock vertical wall above this Mage Quarter doorway is a sloped
--   CoA roof (roof 0.75-1.9 yd in front of it at 111.5-113.5, cornice 109.96 through its drape)
DELETE FROM `gameobject` WHERE `guid` IN (71527);
-- Banner: deleted; Lunar hanging banner: the stock vertical wall above this Mage Quarter doorway is a sloped CoA roof
--   with a cornice at 109.96 through its cloth (roof 0.75-1.9 yd in front above 111.5)
DELETE FROM `gameobject` WHERE `guid` IN (29473);

-- ---------------------------------------------------------------------------
-- 7. Harbour
-- ---------------------------------------------------------------------------
-- Steam Tank Engineer: stood inside the hull of CoA's 10Dw_Ironforgesteamtank2 (it replaced the stock tank drag); now
--   1.5 yd west of the hull, facing it and working (emote 69) as in stock
UPDATE `creature` SET `position_x` = -8432.2, `position_y` = 1110, `position_z` = 19.05, `orientation` = 4.62512 WHERE `guid` = 120712 AND `id` = 29016;
-- Invisible Stalker: same harbour-district walkway; the CoA A01Sw_Harbordistrict floor is 0.43 yd higher here
UPDATE `creature` SET `position_x` = -8323.81, `position_y` = 1058.91, `position_z` = 57.773, `orientation` = 1.72788 WHERE `guid` = 120735 AND `id` = 15214;
-- Invisible Stalker: was inside CoA's Hellfiresupplies_05 crate stack on the lower quay; moved 4.6 yd north onto flat
--   open quay beside the stack
UPDATE `creature` SET `position_x` = -8318.5, `position_y` = 1184.5, `position_z` = 6.412, `orientation` = 0 WHERE `guid` = 120740 AND `id` = 15214;
-- Rat: spawn point was inside CoA's A01_Ballistamissle01 bolt; moved to open ground between the bolt and the harbour
--   wall post, keeps its 5 yd wander
UPDATE `creature` SET `position_x` = -8378.5, `position_y` = 1106.5, `position_z` = 18.921, `orientation` = 4.65156 WHERE `guid` = 120811 AND `id` = 4075;
-- G_WitchHat_01: CoA replaced the stock Statuelion with 7Sw_Stormwind_Lion01 about 2.5 yd further west; hat moved by
--   that offset onto the new lion's head
UPDATE `gameobject` SET `position_x` = -8510.45, `position_y` = 1041.6, `position_z` = 79.192, `orientation` = 3.05433 WHERE `guid` = 2262 AND `id` = 180408;
-- HangingSkullLight01: hangs from the lower-harbour arcade beam; CoA's Sw_Harbor_Docks_Expansion beam (9.1) sits 0.25
--   yd east of the stock Sw_Harbor_Lowstair beam; shifted 0.5 yd east to hang under it again
UPDATE `gameobject` SET `position_x` = -8354.25, `position_y` = 1193.99, `position_z` = 7.715, `orientation` = 2.91469 WHERE `guid` = 8003 AND `id` = 180471;
-- HangingSkullLight01: hangs from the lower-harbour arcade beam; CoA's Sw_Harbor_Docks_Expansion beam (8.9) sits 0.25
--   yd east of the stock Sw_Harbor_Lowmain beam; shifted 0.5 yd east to hang under it again
UPDATE `gameobject` SET `position_x` = -8568.32, `position_y` = 1194.02, `position_z` = 7.609, `orientation` = 2.79252 WHERE `guid` = 8009 AND `id` = 180471;
-- HangingSkullLight01: hangs from the lower-harbour arcade beam; CoA's Sw_Harbor_Docks_Expansion beam (9.0) sits 0.25
--   yd east of the stock Sw_Harbor_Lowmain beam; shifted 0.5 yd east to hang under it again
UPDATE `gameobject` SET `position_x` = -8582.05, `position_y` = 1193.92, `position_z` = 7.693, `orientation` = 3.42085 WHERE `guid` = 8010 AND `id` = 180471;
-- G_Pumpkin_01: back on top of the Hellfiresupplies_04 crate it sat on in stock; the crate's CoA collision is 0.5 yd
--   further west
UPDATE `gameobject` SET `position_x` = -8230.4, `position_y` = 1244, `position_z` = 6.518, `orientation` = 4.93928 WHERE `guid` = 68009 AND `id` = 180405;
-- G_Pumpkin_01: stock Deadminecargonetboxes pile it sat on is gone; set on flat lower-quay floor where the pile stood
--   (0.5 yd south, off a terrain crease), clear of CoA's brick piles
UPDATE `gameobject` SET `position_x` = -8438, `position_y` = 1188.87, `position_z` = 5.623, `orientation` = 3.38594 WHERE `guid` = 68013 AND `id` = 180405;
-- G_Pumpkin_01: stock cargo pile gone; onto the 21.8 crate of CoA's Hellfiresupplies stack that replaced it 3 yd
--   south-west, by the upper harbour road
UPDATE `gameobject` SET `position_x` = -8528, `position_y` = 1151.5, `position_z` = 21.766, `orientation` = 1.74533 WHERE `guid` = 68017 AND `id` = 180405;
-- G_Pumpkin_01: stock cargo pile gone; onto the 21.0 crate of CoA's Hellfiresupplies_06 stack standing on the same
--   spot
UPDATE `gameobject` SET `position_x` = -8552.4, `position_y` = 1152.8, `position_z` = 21.027, `orientation` = 3.50812 WHERE `guid` = 68022 AND `id` = 180405;
-- G_Pumpkin_01: stock cargo pile gone; onto the low crate of CoA's Hellfiresupplies_04 stack 1 yd east
UPDATE `gameobject` SET `position_x` = -8567.35, `position_y` = 1076.95, `position_z` = 20.636, `orientation` = 2.80998 WHERE `guid` = 68023 AND `id` = 180405;
-- G_Pumpkin_01: CoA parked a Nightelfcart on this ground pumpkin; set on the ground at the cart's south end, clear of
--   the elm and barrels
UPDATE `gameobject` SET `position_x` = -8589.8, `position_y` = 1192.2, `position_z` = 5.363, `orientation` = 4.34587 WHERE `guid` = 68024 AND `id` = 180405;
-- G_Pumpkin_02: stock cargo pile gone; onto the 8.5 crate of CoA's Hellfiresupplies_05 stack 3 yd north-east on the
--   lower quay
UPDATE `gameobject` SET `position_x` = -8312.75, `position_y` = 1189.9, `position_z` = 8.545, `orientation` = 3.56047 WHERE `guid` = 68322 AND `id` = 180406;
-- G_Pumpkin_02: stock cargo pile gone; onto the 22.3 top crate of CoA's Hellfiresupplies_05 stack 0.8 yd north, same
--   height as in stock
UPDATE `gameobject` SET `position_x` = -8534.85, `position_y` = 1153.1, `position_z` = 22.252, `orientation` = 4.06662 WHERE `guid` = 68332 AND `id` = 180406;
-- G_Pumpkin_02: stock cargo pile gone; on the upper harbour road where the pile stood, now under CoA's harbour ramp
--   (12 yd clearance)
UPDATE `gameobject` SET `position_x` = -8598.14, `position_y` = 1142.29, `position_z` = 18.623, `orientation` = 1.5708 WHERE `guid` = 68335 AND `id` = 180406;
-- G_Pumpkin_03: same raised ledge beside the harbour-district walkway; CoA's ledge top is 59.1 and its edge slopes, so
--   0.7 yd west onto the flat top
UPDATE `gameobject` SET `position_x` = -8353.9, `position_y` = 1079.6, `position_z` = 59.09, `orientation` = 0.994837 WHERE `guid` = 68631 AND `id` = 180407;
-- G_Pumpkin_03: stock Deadminecargonetboxes pile it sat on is gone; set on the lower-quay floor where the pile stood
UPDATE `gameobject` SET `position_x` = -8451.46, `position_y` = 1193.61, `position_z` = 5.491, `orientation` = 3.52557 WHERE `guid` = 68633 AND `id` = 180407;
-- G_Pumpkin_03: stock cargo pile gone; onto the 22.1 crate of CoA's Hellfiresupplies_04 stack on the same spot
UPDATE `gameobject` SET `position_x` = -8543.1, `position_y` = 1153.03, `position_z` = 22.099, `orientation` = 6.16101 WHERE `guid` = 68637 AND `id` = 180407;
-- G_Pumpkin_03: stock cargo pile gone; onto the flat 22.0 crate of CoA's Hellfiresupplies_05 stack 2 yd south-west
UPDATE `gameobject` SET `position_x` = -8574.85, `position_y` = 1090.35, `position_z` = 22.027, `orientation` = 2.02458 WHERE `guid` = 68641 AND `id` = 180407;
-- G_Pumpkin_03: stock cargo pile gone and CoA's harbour ramp wall now stands on it; set on the road at the ramp's foot
--   1.3 yd north
UPDATE `gameobject` SET `position_x` = -8595.3, `position_y` = 1153.3, `position_z` = 18.873, `orientation` = 1.50098 WHERE `guid` = 68642 AND `id` = 180407;
-- G_Pumpkin_01 scale 4.0: same small tower platform of the gryphon hangar; Stormwindhangar_Update puts it at 54.48,
--   19.7 yd lower than stock
UPDATE `gameobject` SET `position_x` = -8206.78, `position_y` = 1112.76, `position_z` = 54.477, `orientation` = 4.01426 WHERE `guid` = 68900 AND `id` = 180431;
-- G_Pumpkin_01 scale 4.0: same spot on the east docks; CoA terrain is 1.2 yd higher
UPDATE `gameobject` SET `position_x` = -8215.14, `position_y` = 1245.48, `position_z` = 18.559, `orientation` = 5.09636 WHERE `guid` = 68901 AND `id` = 180431;
-- G_Pumpkin_01 scale 4.0: same place above the harbour; CoA cut the stock hillside (88.1) into a terrace at 60.8 with
--   curbs and trees; 1 yd north off a terrain seam
UPDATE `gameobject` SET `position_x` = -8623.1, `position_y` = 1121.7, `position_z` = 60.765, `orientation` = 2.1293 WHERE `guid` = 68907 AND `id` = 180431;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1.3 yd west; onto its end post
UPDATE `gameobject` SET `position_x` = -8287.5, `position_y` = 1159.2, `position_z` = 20.502, `orientation` = 0.209439 WHERE `guid` = 69002 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1.3 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8287.7, `position_y` = 1157.62, `position_z` = 19.706, `orientation` = 0.558504 WHERE `guid` = 69003 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8287.7, `position_y` = 1153.36, `position_z` = 19.706, `orientation` = 2.74016 WHERE `guid` = 69004 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1.3 yd west; onto its post
UPDATE `gameobject` SET `position_x` = -8287.4, `position_y` = 1154.9, `position_z` = 20.503, `orientation` = 5.44543 WHERE `guid` = 69005 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1.3 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8287.7, `position_y` = 1151.5, `position_z` = 19.706, `orientation` = 1.39626 WHERE `guid` = 69006 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.6 yd north; onto its top
UPDATE `gameobject` SET `position_x` = -8295.4, `position_y` = 1124.65, `position_z` = 19.831, `orientation` = 2.93214 WHERE `guid` = 69007 AND `id` = 180415;
-- CandleBlack01: a stone wall post (Stormwind_Gravestone_12) now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8303.19, `position_y` = 1126.97, `position_z` = 20.632, `orientation` = 1.50098 WHERE `guid` = 69011 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8307.45, `position_y` = 1127.19, `position_z` = 20.632, `orientation` = 0.558504 WHERE `guid` = 69013 AND `id` = 180415;
-- CandleBlack01: stone harbour wall ends 0.75 yd short of the old wooden end post; onto the stone end post
UPDATE `gameobject` SET `position_x` = -8307.85, `position_y` = 1149.72, `position_z` = 20.13, `orientation` = 0.994837 WHERE `guid` = 69015 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8307.99, `position_y` = 1159.03, `position_z` = 20.13, `orientation` = 1.20428 WHERE `guid` = 69019 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8346.29, `position_y` = 1129.85, `position_z` = 19.806, `orientation` = 6.00393 WHERE `guid` = 69022 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall; onto its top
UPDATE `gameobject` SET `position_x` = -8348.57, `position_y` = 1129.65, `position_z` = 19.806, `orientation` = 4.13643 WHERE `guid` = 69023 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd south; onto its top
UPDATE `gameobject` SET `position_x` = -8352.64, `position_y` = 1148.96, `position_z` = 20.01, `orientation` = 2.79252 WHERE `guid` = 69026 AND `id` = 180415;
-- CandleBlack01: old wall corner; the stone harbour wall now ends at this post 1.3 yd away
UPDATE `gameobject` SET `position_x` = -8352.2, `position_y` = 1143.15, `position_z` = 20.687, `orientation` = 4.04917 WHERE `guid` = 69027 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd south; onto its top
UPDATE `gameobject` SET `position_x` = -8352.6, `position_y` = 1153.15, `position_z` = 20.01, `orientation` = 0.750491 WHERE `guid` = 69028 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.8 yd south; onto its top (the kept Dustwallowwall03
--   rail under the old spot is too narrow)
UPDATE `gameobject` SET `position_x` = -8352.65, `position_y` = 1144.9, `position_z` = 20.01, `orientation` = 1.62316 WHERE `guid` = 69029 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd south; onto its post
UPDATE `gameobject` SET `position_x` = -8352.42, `position_y` = 1151.55, `position_z` = 20.69, `orientation` = 6.14356 WHERE `guid` = 69030 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd south; onto its top
UPDATE `gameobject` SET `position_x` = -8352.74, `position_y` = 1157.35, `position_z` = 20.01, `orientation` = 1.46608 WHERE `guid` = 69031 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd south; onto its post
UPDATE `gameobject` SET `position_x` = -8352.53, `position_y` = 1159.63, `position_z` = 20.69, `orientation` = 3.83973 WHERE `guid` = 69032 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8352.56, `position_y` = 1155.38, `position_z` = 20.69, `orientation` = 3.4383 WHERE `guid` = 69033 AND `id` = 180415;
-- CandleBlack01: stone harbour wall ends here; onto its end post 0.5 yd north
UPDATE `gameobject` SET `position_x` = -8352.31, `position_y` = 1129.62, `position_z` = 20.666, `orientation` = 6.10865 WHERE `guid` = 69034 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd south; onto its top
UPDATE `gameobject` SET `position_x` = -8378.59, `position_y` = 1127.86, `position_z` = 19.842, `orientation` = 5.95157 WHERE `guid` = 69038 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands here; onto the flat of its top 0.25 yd east
UPDATE `gameobject` SET `position_x` = -8379, `position_y` = 1115.52, `position_z` = 20.506, `orientation` = 2.75761 WHERE `guid` = 69039 AND `id` = 180415;
-- CandleBlack01: old wall corner; onto the corner post of the stone harbour wall 0.9 yd north-west
UPDATE `gameobject` SET `position_x` = -8413.14, `position_y` = 1089.68, `position_z` = 20.667, `orientation` = 3.29869 WHERE `guid` = 69046 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its top
UPDATE `gameobject` SET `position_x` = -8413.29, `position_y` = 1092.43, `position_z` = 19.948, `orientation` = 3.89209 WHERE `guid` = 69047 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall; onto its top 0.25 yd west
UPDATE `gameobject` SET `position_x` = -8414.78, `position_y` = 1129.34, `position_z` = 19.948, `orientation` = 5.02655 WHERE `guid` = 69048 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall; onto its top 0.25 yd west (the kept Dustwallowwall03
--   rail under the old spot is too narrow)
UPDATE `gameobject` SET `position_x` = -8416.18, `position_y` = 1089.69, `position_z` = 19.948, `orientation` = 5.49779 WHERE `guid` = 69049 AND `id` = 180415;
-- CandleBlack01: end of the old wooden run; onto the stone harbour wall post 1 yd south
UPDATE `gameobject` SET `position_x` = -8422.4, `position_y` = 1089.5, `position_z` = 21.124, `orientation` = 4.32842 WHERE `guid` = 69050 AND `id` = 180415;
-- CandleBlack01: old diagonal wooden wall replaced by a stone harbour wall along x -8426; onto its post
UPDATE `gameobject` SET `position_x` = -8426.53, `position_y` = 1146.62, `position_z` = 20.195, `orientation` = 3.29869 WHERE `guid` = 69053 AND `id` = 180415;
-- CandleBlack01: old diagonal wooden wall replaced by a stone harbour wall along x -8426; onto its top 1.7 yd north
UPDATE `gameobject` SET `position_x` = -8426.3, `position_y` = 1144.6, `position_z` = 19.367, `orientation` = 5.67232 WHERE `guid` = 69055 AND `id` = 180415;
-- CandleBlack01: CoA kept the stock Dustwallowwall03 rail 1 yd south; its wooden post is gone, so onto the rail top
UPDATE `gameobject` SET `position_x` = -8431.6, `position_y` = 1143.7, `position_z` = 19.709, `orientation` = 2.93214 WHERE `guid` = 69058 AND `id` = 180415;
-- CandleBlack01: stone harbour wall resumes here; onto its end post 0.5 yd south
UPDATE `gameobject` SET `position_x` = -8433.12, `position_y` = 1129.36, `position_z` = 20.666, `orientation` = 2.65289 WHERE `guid` = 69060 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8441.1, `position_y` = 1141.9, `position_z` = 20.721, `orientation` = 4.50295 WHERE `guid` = 69063 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8445.5, `position_y` = 1142.21, `position_z` = 20.721, `orientation` = 2.46091 WHERE `guid` = 69065 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1.25 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8445.88, `position_y` = 1089.41, `position_z` = 20.325, `orientation` = 2.09439 WHERE `guid` = 69066 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its post
UPDATE `gameobject` SET `position_x` = -8447.87, `position_y` = 1089.11, `position_z` = 21.064, `orientation` = 4.90438 WHERE `guid` = 69068 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands here; onto the flat of its top 0.25 yd north
UPDATE `gameobject` SET `position_x` = -8449.84, `position_y` = 1142.33, `position_z` = 20.721, `orientation` = 0.331611 WHERE `guid` = 69070 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8450.1, `position_y` = 1089.32, `position_z` = 20.325, `orientation` = 2.56563 WHERE `guid` = 69071 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd west; onto its post
UPDATE `gameobject` SET `position_x` = -8450.39, `position_y` = 1129.27, `position_z` = 20.721, `orientation` = 5.48033 WHERE `guid` = 69072 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its post
UPDATE `gameobject` SET `position_x` = -8451.91, `position_y` = 1089.06, `position_z` = 21.064, `orientation` = 2.32129 WHERE `guid` = 69073 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8452.52, `position_y` = 1129.44, `position_z` = 19.999, `orientation` = 1.0472 WHERE `guid` = 69074 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 1 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8454.42, `position_y` = 1089.39, `position_z` = 20.325, `orientation` = 1.95477 WHERE `guid` = 69075 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd west; onto its post
UPDATE `gameobject` SET `position_x` = -8454.78, `position_y` = 1129.44, `position_z` = 20.721, `orientation` = 5.84685 WHERE `guid` = 69076 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8456.36, `position_y` = 1142, `position_z` = 20.721, `orientation` = 3.83973 WHERE `guid` = 69077 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its end post
UPDATE `gameobject` SET `position_x` = -8456.41, `position_y` = 1089.04, `position_z` = 21.061, `orientation` = 2.68781 WHERE `guid` = 69078 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8456.6, `position_y` = 1129.5, `position_z` = 19.999, `orientation` = 0.349065 WHERE `guid` = 69079 AND `id` = 180415;
-- CandleBlack01: CoA kept this stock Dustwallowwall03 rail; the wooden post on it is gone, so onto the rail's crown
--   0.4 yd north
UPDATE `gameobject` SET `position_x` = -8459, `position_y` = 1091, `position_z` = 19.749, `orientation` = 1.309 WHERE `guid` = 69082 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands here; onto the flat of its top 0.25 yd west
UPDATE `gameobject` SET `position_x` = -8460.61, `position_y` = 1142.07, `position_z` = 20.721, `orientation` = 5.95157 WHERE `guid` = 69083 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall; onto its top 0.35 yd east
UPDATE `gameobject` SET `position_x` = -8464.41, `position_y` = 1142.1, `position_z` = 19.999, `orientation` = 5.06146 WHERE `guid` = 69086 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands here; onto the flat of its top 0.25 yd west
UPDATE `gameobject` SET `position_x` = -8468.02, `position_y` = 1145.54, `position_z` = 20.502, `orientation` = 0.174532 WHERE `guid` = 69092 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8480.44, `position_y` = 1129.34, `position_z` = 20.72, `orientation` = 5.67232 WHERE `guid` = 69096 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8484.65, `position_y` = 1129.16, `position_z` = 20.721, `orientation` = 3.63029 WHERE `guid` = 69098 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its top
UPDATE `gameobject` SET `position_x` = -8486.96, `position_y` = 1121.25, `position_z` = 19.784, `orientation` = 1.36136 WHERE `guid` = 69100 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its post
UPDATE `gameobject` SET `position_x` = -8487.1, `position_y` = 1119.21, `position_z` = 20.506, `orientation` = 5.2709 WHERE `guid` = 69101 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its top
UPDATE `gameobject` SET `position_x` = -8487.11, `position_y` = 1116.9, `position_z` = 19.784, `orientation` = 0.610863 WHERE `guid` = 69102 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its post
UPDATE `gameobject` SET `position_x` = -8487.22, `position_y` = 1114.82, `position_z` = 20.506, `orientation` = 2.82743 WHERE `guid` = 69103 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd east; onto its end post
UPDATE `gameobject` SET `position_x` = -8500.6, `position_y` = 1140.73, `position_z` = 20.72, `orientation` = 5.044 WHERE `guid` = 69110 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd east; onto its top
UPDATE `gameobject` SET `position_x` = -8502.35, `position_y` = 1140.49, `position_z` = 19.999, `orientation` = 2.04204 WHERE `guid` = 69111 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.5 yd east; onto its post
UPDATE `gameobject` SET `position_x` = -8505.05, `position_y` = 1140.83, `position_z` = 20.721, `orientation` = 0.575957 WHERE `guid` = 69112 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its end post
UPDATE `gameobject` SET `position_x` = -8514.08, `position_y` = 1114.61, `position_z` = 19.812, `orientation` = 0.244346 WHERE `guid` = 69113 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its top, 1.6 yd from the end-post
--   candle
UPDATE `gameobject` SET `position_x` = -8513.86, `position_y` = 1116.2, `position_z` = 19.09, `orientation` = 1.44862 WHERE `guid` = 69114 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd north; onto its top
UPDATE `gameobject` SET `position_x` = -8513.91, `position_y` = 1118.08, `position_z` = 19.09, `orientation` = 3.07177 WHERE `guid` = 69115 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8513.94, `position_y` = 1120.44, `position_z` = 19.09, `orientation` = 3.33359 WHERE `guid` = 69116 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall; onto its post 0.5 yd north (the kept Dustwallowwall03
--   rail under the old spot is too narrow)
UPDATE `gameobject` SET `position_x` = -8514.39, `position_y` = 1123.81, `position_z` = 19.812, `orientation` = 3.97935 WHERE `guid` = 69117 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its end post
UPDATE `gameobject` SET `position_x` = -8527.33, `position_y` = 1127.05, `position_z` = 20.315, `orientation` = 0.436332 WHERE `guid` = 69120 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8529.81, `position_y` = 1127.22, `position_z` = 19.593, `orientation` = 3.59538 WHERE `guid` = 69121 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its post
UPDATE `gameobject` SET `position_x` = -8531.71, `position_y` = 1127.09, `position_z` = 20.314, `orientation` = 3.71755 WHERE `guid` = 69122 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its top
UPDATE `gameobject` SET `position_x` = -8534.06, `position_y` = 1127.09, `position_z` = 19.593, `orientation` = 0.331611 WHERE `guid` = 69123 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall 0.75 yd west; onto its end post
UPDATE `gameobject` SET `position_x` = -8535.85, `position_y` = 1127.03, `position_z` = 20.315, `orientation` = 2.14675 WHERE `guid` = 69124 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8556.63, `position_y` = 1143.1, `position_z` = 20.315, `orientation` = 1.39626 WHERE `guid` = 69138 AND `id` = 180415;
-- CandleBlack01: stone harbour wall replaced the wooden wall; onto its top 0.35 yd south-west
UPDATE `gameobject` SET `position_x` = -8559.48, `position_y` = 1125.54, `position_z` = 19.617, `orientation` = 1.309 WHERE `guid` = 69140 AND `id` = 180415;
-- CandleBlack01: stone harbour wall ends 0.75 yd short of the old wooden end post; onto the stone end post
UPDATE `gameobject` SET `position_x` = -8559.98, `position_y` = 1146.95, `position_z` = 20.362, `orientation` = 2.61799 WHERE `guid` = 69141 AND `id` = 180415;
-- CandleBlack01: a stone wall post now stands where the wooden post was; onto its top
UPDATE `gameobject` SET `position_x` = -8561.27, `position_y` = 1124.26, `position_z` = 20.335, `orientation` = 3.33359 WHERE `guid` = 69145 AND `id` = 180415;
-- Steam Tank Engineer path (creature 120715): work stop was inside CoA's 10Dw_Ironforgesteamtank2 hull; moved 1.9 yd
--   north to the hull's end, facing it (o pi) instead of the path heading
UPDATE `waypoint_data` SET `position_x` = -8440, `position_y` = 1122.8, `position_z` = 19.05, `orientation` = 3.1416 WHERE `id` = 1207150 AND `point` = 4;
-- Steam Tank Engineer path (creature 120715): same work stop (15 s pause), facing the hull
UPDATE `waypoint_data` SET `position_x` = -8440, `position_y` = 1122.8, `position_z` = 19.05, `orientation` = 3.1416 WHERE `id` = 1207150 AND `point` = 5;
-- Steam Tank Engineer path (creature 120715): same work stop (5 s pause), facing the hull
UPDATE `waypoint_data` SET `position_x` = -8440, `position_y` = 1122.8, `position_z` = 19.05, `orientation` = 3.1416 WHERE `id` = 1207150 AND `point` = 6;
-- CandleBlack01: stone harbour wall replaced the wooden wall post it stood on (stock post top 19.86; CoA terrain 18.81
--   there, so it floated 1.04 yd); onto the Stormwind_Lowwall top 0.64 yd south, mid-wall, beside 69140
UPDATE `gameobject` SET `position_x` = -8558.1, `position_y` = 1126.2, `position_z` = 19.617, `orientation` = 4.85202 WHERE `guid` = 69139 AND `id` = 180415;
-- G_Pumpkin_01: Hallow's End pumpkin on the harbour walkway; same spot, CoA A01Sw_Harbordistrict floor 58.17 (sat 0.47
--   yd sunk)
UPDATE `gameobject` SET `position_x` = -8350.92, `position_y` = 1063.76, `position_z` = 58.172, `orientation` = 4.04917 WHERE `guid` = 68011 AND `id` = 180405;
-- CandleBlack01: Hallow's End candle on the harbour wall; the stone wall replaced the wooden one at the same spot, so
--   it goes on the Stormwind_Lowwall_Long top 19.409
UPDATE `gameobject` SET `position_x` = -8307.83, `position_y` = 1151.41, `position_z` = 19.409, `orientation` = 5.88176 WHERE `guid` = 69014 AND `id` = 180415;
-- CandleBlack01: Hallow's End candle on the harbour wall; the stone wall replaced the wooden one at the same spot, so
--   it goes on the Stormwind_Lowwall_Long_X2 top 19.810
UPDATE `gameobject` SET `position_x` = -8309.4, `position_y` = 1127.39, `position_z` = 19.81, `orientation` = 4.60767 WHERE `guid` = 69020 AND `id` = 180415;
-- CandleBlack01: Hallow's End candle on the harbour wall; the stone wall replaced the wooden one at the same spot, so
--   it goes on the Stormwind_Lowwall_Long top 19.593
UPDATE `gameobject` SET `position_x` = -8550.17, `position_y` = 1142.99, `position_z` = 19.593, `orientation` = 1.48353 WHERE `guid` = 69130 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8554.34, `position_y` = 1143.06, `position_z` = 19.593, `orientation` = 3.927 WHERE `guid` = 69137 AND `id` = 180415;
-- CandleBlack01: Hallow's End candle on the harbour wall; the stone wall replaced the wooden one at the same spot, so
--   it goes on the Stormwind_Gravestone_12 post top 20.506
UPDATE `gameobject` SET `position_x` = -8379.01, `position_y` = 1119.91, `position_z` = 20.506, `orientation` = 1.64061 WHERE `guid` = 69040 AND `id` = 180415;
-- CandleBlack01: Hallow's End candle on the harbour wall; the stone wall replaced the wooden one at the same spot, so
--   it goes on the Stormwind_Gravestone_12 post top 20.314
UPDATE `gameobject` SET `position_x` = -8552.32, `position_y` = 1142.93, `position_z` = 20.314, `orientation` = 4.15388 WHERE `guid` = 69133 AND `id` = 180415;
-- G_Pumpkin_02: the stock Stormwind.wmo ledge it sat on 1.2 yd up is gone and it floated 1.2 yd over the open harbour-
--   district floor; onto the low crate (top 98.61-98.64) of CoA's Hellfiresupplies_05 stack 7 yd south-west, like
--   68017
UPDATE `gameobject` SET `position_x` = -8509.6, `position_y` = 932.1, `position_z` = 98.62, `orientation` = 3.47321 WHERE `guid` = 68329 AND `id` = 180406;
-- G_Pumpkin_01, G_Pumpkin_02: Hallow's End pumpkin; same spot, z on the A01Sw_Harbordistrict floor 60.70 (floated
--   0.35)
UPDATE `gameobject` SET `position_x` = -8545.96, `position_y` = 1045.23, `position_z` = 60.702, `orientation` = 0.890117 WHERE `guid` = 68020 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -8464.57, `position_y` = 1041.8, `position_z` = 60.702, `orientation` = 0.401425 WHERE `guid` = 68328 AND `id` = 180406;
-- CandleBlack01: Hallow's End candle on the CoA Stormwind_Lowwall that replaced its wooden post; same spot, z on the
--   wall top
UPDATE `gameobject` SET `position_x` = -8296.2, `position_y` = 1126.87, `position_z` = 19.81, `orientation` = 3.47321 WHERE `guid` = 69008 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8298.4, `position_y` = 1126.91, `position_z` = 19.81, `orientation` = 6.23083 WHERE `guid` = 69009 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8307.86, `position_y` = 1153.22, `position_z` = 19.409, `orientation` = 3.12412 WHERE `guid` = 69016 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8379.06, `position_y` = 1117.96, `position_z` = 19.785, `orientation` = 5.98648 WHERE `guid` = 69041 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -8425.74, `position_y` = 1089.36, `position_z` = 20.402, `orientation` = 2.87979 WHERE `guid` = 69052 AND `id` = 180415;
-- Standing, Large - Val: Love is in the Air stand whose base cut 0.45 yd into CoA's A01_Ballistamissle01 lying on the
--   dock; moved 0.9-1.0 yd north off the missile onto the open dock 5.23, 1.0-1.2 yd from its sibling stands
--   242294/242297
UPDATE `gameobject` SET `position_x` = -8400.55, `position_y` = 1242, `position_z` = 5.23, `orientation` = 5.8378 WHERE `guid` = 242230 AND `id` = 181015;
UPDATE `gameobject` SET `position_x` = -8400.9, `position_y` = 1244.2, `position_z` = 5.23, `orientation` = 6.18337 WHERE `guid` = 242231 AND `id` = 181015;
-- Stormwind Harbor Guard: harbour guard; same spot, z on the CoA floor with the stock 0.1 offset (floated 0.32-0.33)
UPDATE `creature` SET `position_x` = -8583.41, `position_y` = 1071.97, `position_z` = 36.826, `orientation` = 5.36266 WHERE `guid` = 120618 AND `id` = 29712;
UPDATE `creature` SET `position_x` = -8590.59, `position_y` = 1126.81, `position_z` = 18.348, `orientation` = 0.92 WHERE `guid` = 203478 AND `id` = 29712;
-- G_Pumpkin_03: deleted; sat on the stock ramp landing at 41.25 by the harbour road; CoA filled it with terrain (59.44
--   above) and left only a 2-4 yd corridor at 41, so there is no place for it
DELETE FROM `gameobject` WHERE `guid` IN (68644);
-- CandleBlack01: deleted; the wooden stub wall along y 1142 (x -8347.5..-8351.5) it stood on is gone; CoA put a
--   streetlamp there and has no wall within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69024);
-- CandleBlack01: deleted; the wooden wall ran on to x -8355; CoA's stone wall ends at -8353 (post taken by 69034),
--   nothing within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69035);
-- CandleBlack01: deleted; CoA opened the harbour wall along y 1129 between x -8419 and -8432.5 (walkway to the steam
--   tanks); no wall within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69056, 69059);
-- CandleBlack01: deleted; CoA opened the harbour wall along y 1129 between x -8443 and -8449.5; no wall within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69069);
-- CandleBlack01: deleted; the wooden corner post and the south half of its rail are gone; CoA's stone wall ends 2 yd
--   away at the post taken by 69078
DELETE FROM `gameobject` WHERE `guid` IN (69081);
-- CandleBlack01: deleted; CoA opened the harbour wall along y 1129 between x -8460.5 and -8474.5 (14 yd walkway); no
--   wall within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69085, 69087, 69088, 69093, 69094);
-- CandleBlack01: deleted; CoA left a walkway gap in the harbour wall between the corner post at x -8496.5 and the post
--   at -8500.5 (taken by 69110); no wall within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69109);
-- CandleBlack01: deleted; the wooden wall along y 1126 (x -8515..-8519) is gone; CoA put a streetlamp at its corner
--   and has no wall within 1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69118);
-- CandleBlack01: deleted; the wooden wall along y 1126 (x -8515..-8519) is gone; open street in CoA, no wall within
--   1.5 yd
DELETE FROM `gameobject` WHERE `guid` IN (69119);

-- ---------------------------------------------------------------------------
-- 8. Main gate and Valley of Heroes
-- ---------------------------------------------------------------------------
-- Stormwind City Guard: gate guard at the inner mouth of the gate passage, moved with the CoA gate (stock gate
--   +10.60,+8.50; passage floor 93.30 on both); north side
UPDATE `creature` SET `position_x` = -9067.86, `position_y` = 449.01, `position_z` = 93.295, `orientation` = 5.37561 WHERE `guid` = 79861 AND `id` = 68;
-- Stormwind City Guard: gate guard at the inner mouth of the gate passage, moved with the CoA gate (stock gate
--   +10.60,+8.50; passage floor 93.30 on both); south side
UPDATE `creature` SET `position_x` = -9051.58, `position_y` = 428.58, `position_z` = 93.295, `orientation` = 2.25148 WHERE `guid` = 79863 AND `id` = 68;
-- Standing, Large - MFF: Midsummer standing banner, south side of the inner gate mouth, moved with the CoA gate
--   (+10.60,+8.50)
UPDATE `gameobject` SET `position_x` = -9050.07, `position_y` = 426.2, `position_z` = 93.295, `orientation` = 2.28638 WHERE `guid` = 42282 AND `id` = 181300;
-- Standing, Large - Brewfest: Brewfest standing banner, south side of the inner gate mouth, moved with the CoA gate
--   (+10.60,+8.50)
UPDATE `gameobject` SET `position_x` = -9050.07, `position_y` = 426.2, `position_z` = 93.295, `orientation` = 2.28638 WHERE `guid` = 80798 AND `id` = 195265;
-- Standing, Large - Val: Love is in the Air standing banner, south side of the inner gate mouth, moved with the CoA
--   gate (+10.60,+8.50)
UPDATE `gameobject` SET `position_x` = -9052.09, `position_y` = 424.29, `position_z` = 93.295, `orientation` = 2.21282 WHERE `guid` = 241120 AND `id` = 181015;
-- Standing, Large - MFF: Midsummer standing banner, north side of the inner gate mouth, moved with the CoA gate
--   (+10.60,+8.50)
UPDATE `gameobject` SET `position_x` = -9068.63, `position_y` = 451.41, `position_z` = 93.295, `orientation` = 5.37562 WHERE `guid` = 42284 AND `id` = 181300;
-- Standing, Large - Brewfest: Brewfest standing banner, north side of the inner gate mouth, moved with the CoA gate
--   (+10.60,+8.50)
UPDATE `gameobject` SET `position_x` = -9068.63, `position_y` = 451.41, `position_z` = 93.295, `orientation` = -0.90757 WHERE `guid` = 80802 AND `id` = 195265;
-- Hanging, Square, Large - MFF: Midsummer wreath on the south buttress of the gate passage, moved with the CoA gate
--   (+10.60,+8.50); flush on the CoA face within 0.1 yd over its 23 yd height
UPDATE `gameobject` SET `position_x` = -9066.13, `position_y` = 414.63, `position_z` = 98.62, `orientation` = 2.25147 WHERE `guid` = 52225 AND `id` = 181358;
-- Hanging, Square, Large - Brewfest: Brewfest wreath on the south buttress of the gate passage, moved with the CoA
--   gate (+10.60,+8.50); flush within 0.1 yd
UPDATE `gameobject` SET `position_x` = -9066.13, `position_y` = 414.63, `position_z` = 98.62, `orientation` = 2.25147 WHERE `guid` = 67076 AND `id` = 195254;
-- Hanging, Square, Large - Val: Love is in the Air wreath on the south buttress of the gate passage, moved with the
--   CoA gate (+10.60,+8.50); flush within 0.1 yd
UPDATE `gameobject` SET `position_x` = -9064.77, `position_y` = 415.52, `position_z` = 98.62, `orientation` = 2.25148 WHERE `guid` = 241187 AND `id` = 181014;
-- Hanging, Square, Large - MFF: Midsummer wreath on the north buttress of the gate passage, moved with the CoA gate
--   (+10.60,+8.50); flush within 0.2 yd
UPDATE `gameobject` SET `position_x` = -9084.06, `position_y` = 437.59, `position_z` = 99.09, `orientation` = 5.46288 WHERE `guid` = 52228 AND `id` = 181358;
-- Hanging, Square, Large - Brewfest: Brewfest wreath on the north buttress of the gate passage, moved with the CoA
--   gate (+10.60,+8.50); flush within 0.2 yd
UPDATE `gameobject` SET `position_x` = -9084.06, `position_y` = 437.59, `position_z` = 99.09, `orientation` = -0.820303 WHERE `guid` = 67075 AND `id` = 195254;
-- Hanging, Square, Large - Val: Love is in the Air wreath on the north buttress of the gate passage, moved with the
--   CoA gate (+10.60,+8.50); flush within 0.2 yd
UPDATE `gameobject` SET `position_x` = -9083.89, `position_y` = 437.72, `position_z` = 99.09, `orientation` = -0.820305 WHERE `guid` = 241115 AND `id` = 181014;
-- Hanging, Square, Large - MFF: Midsummer wreath on the Valley face of the inner arch; the CoA wall face is 1.34 yd
--   further out, so moved 1.34 yd along its facing to hang flush
UPDATE `gameobject` SET `position_x` = -8936.12, `position_y` = 521.24, `position_z` = 109.389, `orientation` = 3.80482 WHERE `guid` = 52226 AND `id` = 181358;
-- Hanging, Square, Large - Brewfest: Brewfest wreath on the Valley face of the inner arch; moved 1.34 yd along its
--   facing onto the thicker CoA wall
UPDATE `gameobject` SET `position_x` = -8936.12, `position_y` = 521.24, `position_z` = 109.389, `orientation` = -2.47837 WHERE `guid` = 67077 AND `id` = 195254;
-- Hanging, Square, Large - Val: Love is in the Air wreath on the Valley face of the inner arch; moved 1.35 yd along
--   its facing onto the thicker CoA wall
UPDATE `gameobject` SET `position_x` = -8936.2, `position_y` = 521.7, `position_z` = 109.389, `orientation` = -2.47837 WHERE `guid` = 241185 AND `id` = 181014;
-- Hanging, Square, Large - MFF: Midsummer wreath on the Valley face of the inner arch; moved 1.35 yd along its facing
--   onto the thicker CoA wall
UPDATE `gameobject` SET `position_x` = -8949.89, `position_y` = 538.18, `position_z` = 109.32, `orientation` = 3.80482 WHERE `guid` = 52227 AND `id` = 181358;
-- Hanging, Square, Large - Brewfest: Brewfest wreath on the Valley face of the inner arch; moved 1.35 yd along its
--   facing onto the thicker CoA wall
UPDATE `gameobject` SET `position_x` = -8949.89, `position_y` = 538.18, `position_z` = 109.32, `orientation` = -2.47837 WHERE `guid` = 67078 AND `id` = 195254;
-- Hanging, Square, Large - Val: Love is in the Air wreath on the Valley face of the inner arch; moved 1.36 yd along
--   its facing onto the thicker CoA wall
UPDATE `gameobject` SET `position_x` = -8949.52, `position_y` = 538.43, `position_z` = 109.32, `orientation` = -2.47837 WHERE `guid` = 241183 AND `id` = 181014;
-- Hanging, Streamer x3 - MFF: Midsummer streamers on the Valley-to-Old-Town arch face; CoA face 0.02-0.28 yd further
--   out, moved 0.25 yd along the facing to hang flush
UPDATE `gameobject` SET `position_x` = -8846.12, `position_y` = 468.77, `position_z` = 122.352, `orientation` = 3.80482 WHERE `guid` = 54079 AND `id` = 181401;
-- Hanging, Streamer x3 - Brewfest: Brewfest streamers on the Valley-to-Old-Town arch face; moved 0.25 yd along the
--   facing to hang flush
UPDATE `gameobject` SET `position_x` = -8846.12, `position_y` = 468.77, `position_z` = 122.352, `orientation` = -2.47837 WHERE `guid` = 66988 AND `id` = 195253;
-- Gregory Tabor: Gregory Tabor: SuperTrack turn-in 589 of 14022 and 14033; facing from Wild Turkey 244347, which
--   copies the source spawn at this point
UPDATE `creature` SET `position_x` = -9125.02, `position_y` = 352.824, `position_z` = 93.528, `orientation` = 2.1217 WHERE `guid` = 240460 AND `id` = 34675;
-- Jasper Moore: Jasper Moore: SuperTrack turn-in 3261 of 14023, 14028 and 14055; facing from Wild Turkey 244345, which
--   copies the source spawn at this point
UPDATE `creature` SET `position_x` = -9127.56, `position_y` = 351.404, `position_z` = 93.528, `orientation` = 2.13741 WHERE `guid` = 240458 AND `id` = 34744;
-- Ellen Moore: Ellen Moore: SuperTrack turn-in 3268 of 14053; facing from Wild Turkey 244343, which copies the source
--   spawn at this point
UPDATE `creature` SET `position_x` = -9118.18, `position_y` = 359.164, `position_z` = 93.269, `orientation` = 1.90179 WHERE `guid` = 240456 AND `id` = 34710;
-- Jorgen: Jorgen: same spot below the bridge (q1241 SuperTrack x,y; CoA area Valley of Heroes as the quest text says);
--   ground 3.9 yd lower, now the edge of the Azzar Faire
UPDATE `creature` SET `position_x` = -8981.78, `position_y` = 397.36, `position_z` = 72.025, `orientation` = 0.785398 WHERE `guid` = 79654 AND `id` = 4959;
-- Stormwind Reveler: Fireworks reveller on the open ground south of the Faire tree stump; ground 2.1 yd lower; turned
--   to face the stump
UPDATE `creature` SET `position_x` = -8979.47, `position_y` = 390.627, `position_z` = 72.054, `orientation` = 0.12 WHERE `guid` = 420007 AND `id` = 15694;
-- Stormwind Reveler: Fireworks reveller stood on the rim of the CoA tree stump (Elwynntreestump02); moved to the open
--   ground on its north side, facing the stump and the other reveller
UPDATE `creature` SET `position_x` = -8973.9, `position_y` = 391, `position_z` = 72.018, `orientation` = 3.23 WHERE `guid` = 420006 AND `id` = 15694;
-- Festive Keg: Festive keg floated 1.5 yd against the Faire wagon side; set 1 yd off it on the open ground between the
--   tree stump and the wagon, beside the revellers
UPDATE `gameobject` SET `position_x` = -8978.3, `position_y` = 388.4, `position_z` = 72.105, `orientation` = 2.91469 WHERE `guid` = 420167 AND `id` = 180699;
-- Hay Bale 1: Hay-bale bench: its stock spot runs into the stall tent crates; laid north-south along the west side of
--   the tree stump, facing the revellers
UPDATE `gameobject` SET `position_x` = -8977, `position_y` = 394.8, `position_z` = 71.988, `orientation` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 420327 AND `id` = 180700;
-- Hay Bale 1: Hay-bale bench was inside the Faire wagon (A01_Azzarfaire_Wagon01); laid north-south on the open ground
--   east of the tree stump, north of the wagon
UPDATE `gameobject` SET `position_x` = -8972.4, `position_y` = 386.6, `position_z` = 72.169, `orientation` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 420326 AND `id` = 180700;
-- Festive Keg: Festive keg on the open ground at the south-east corner of the stall tent; set on the CoA ground
UPDATE `gameobject` SET `position_x` = -8986, `position_y` = 385.665, `position_z` = 72.615, `orientation` = 1.67551 WHERE `guid` = 420168 AND `id` = 180699;
-- Stormwind Reveler: Fireworks reveller between the stall tent and the west Faire wagon; ground 0.4 yd lower
UPDATE `creature` SET `position_x` = -8991.48, `position_y` = 395.316, `position_z` = 72.371, `orientation` = 3.5581 WHERE `guid` = 420009 AND `id` = 15694;
-- Stormwind Reveler: Fireworks reveller stood within 0.6 yd of the west Faire wagon (A01_Azzarfaire_Wagon06) and 0.4
--   yd above the lowered ground; set 1.1 yd off the wagon, beside revellers 420009 and 420008
UPDATE `creature` SET `position_x` = -8992.6, `position_y` = 393.6, `position_z` = 72.402, `orientation` = 0.416506 WHERE `guid` = 420010 AND `id` = 15694;
-- Stormwind Reveler: Fireworks reveller stood inside a stall tent crate (6Hu_Garrison_Crate_Empty); moved 3 yd to the
--   open ground beside revellers 420009 and 420010, facing them
UPDATE `creature` SET `position_x` = -8989.8, `position_y` = 395.6, `position_z` = 72.326, `orientation` = 3.38 WHERE `guid` = 420008 AND `id` = 15694;
-- Hay Bale 1: Hay-bale bench was under the stall tent against its crates; laid north-south on the open grass west of
--   the west Faire wagon, by the moat
UPDATE `gameobject` SET `position_x` = -8994.8, `position_y` = 401.8, `position_z` = 72.43, `orientation` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 420328 AND `id` = 180700;
-- Hay Bale 1: Hay-bale bench was inside the west Faire wagon (A01_Azzarfaire_Wagon06); laid east-west beside the other
--   bench on the open grass by the moat, forming an L
UPDATE `gameobject` SET `position_x` = -8999.6, `position_y` = 400.6, `position_z` = 72.878, `orientation` = 1.5708, `rotation2` = 0.707108, `rotation3` = 0.707105 WHERE `guid` = 420329 AND `id` = 180700;
-- Standing, Large - Val: Love is in the Air standing crate at the north side of the inner gate mouth, partner of
--   banners 42284/80802; moved with the CoA gate (+10.60,+8.50) onto the passage floor 93.30 (its stock spot is now
--   open ground outside the gate)
UPDATE `gameobject` SET `position_x` = -9070.99, `position_y` = 449.323, `position_z` = 93.295, `orientation` = 5.35912 WHERE `guid` = 241119 AND `id` = 181015;
-- Hanging, Tall/Thin, Large - MFF, Hanging, Tall/Thin, Large - Brewfest, Hanging, Tall/Thin, Large - Val: deleted;
--   holiday ribbon (14 yd tall) that hung from the stock gate's upper arch (walkway 125.7-134.1 between the towers);
--   CoA's gate is open to the sky between its two towers, with no surface from 95 to 260 yd at the stock or the gate-
--   shifted (+10.60, +8.50) point, and the tower faces carry CoA's own Magetower banners, so the ribbon has nothing to
--   hang on
DELETE FROM `gameobject` WHERE `guid` IN (52846, 67089, 241114);

-- ---------------------------------------------------------------------------
-- 9. New spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` = 9002760;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9002760, 15127, 0, 0, 0, 1, 1, 1, -8783.88, 423.42, 105.28, 0.74, 650, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Stormwind: QuestSuperTrack turn-in and objective of 8260 8261 8262 (Arathor care packages) at the Champions'' Hall map table; AC spawns him only at Refuge Pointe (guid 11241); atlas sees him here too');

DELETE FROM `creature_addon` WHERE `guid` = 9002760;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(9002760, 0, 0, 0, 1, 0, 0, NULL);

-- ---------------------------------------------------------------------------
-- 10. Event, pool and addon rows of the deleted objects
-- ---------------------------------------------------------------------------
DELETE FROM `game_event_gameobject` WHERE `guid` IN (13877, 13878, 13879, 13880, 13898, 13899, 13900, 13901, 13902, 13903, 13908, 13913, 13893, 13904, 13905, 13906, 13907, 13911, 13916, 13953, 13917, 71497, 29482, 13909, 13910, 13912, 13851, 13857, 13858, 13859, 13860, 13861, 13862, 13863, 13866, 13867, 11100, 11101, 11102, 11103, 11104, 11105, 11106, 11107, 11108, 11109, 11110, 11111, 11112, 11113, 11114, 11115, 11116, 11117, 11118, 11119, 11127, 11128, 11129, 11130, 11131, 297, 3162, 3163, 3170, 3175, 1878, 1879, 1880, 1881, 1882, 29472, 29479, 29517, 31165, 31172, 907, 13918, 13919, 13922, 13924, 13925, 13930, 13931, 13932, 13933, 13955, 13956, 13957, 13959, 13960, 13961, 53011, 20458, 20459, 31619, 13929, 13926, 13962, 53045, 61890, 61889, 61891, 61887, 11043, 11040, 11062, 11063, 61915, 61917, 11061, 11060, 26549, 26551, 26552, 26310, 26316, 26306, 26305, 26668, 26672, 26295, 26669, 26308, 26671, 26307, 40919, 53437, 80525, 241113, 52663, 80668, 241105, 36180, 53207, 80443, 241172, 52718, 241236, 36621, 53991, 81038, 241176, 241109, 53858, 81039, 53593, 80833, 241222, 40921, 40923, 40935, 41665, 31236, 26277, 26278, 53398, 80447, 241261, 36179, 52784, 80692, 241258, 53201, 80505, 241235, 53396, 80446, 241175, 52750, 80688, 241223, 37044, 53432, 80506, 241257, 53110, 80517, 241234, 53330, 80524, 241231, 42800, 42801, 42794, 42802, 42793, 42803, 42795, 42798, 42796, 42797, 71527, 29473, 68644, 69024, 69035, 69056, 69059, 69069, 69081, 69085, 69087, 69088, 69093, 69094, 69109, 69118, 69119, 52846, 67089, 241114);
DELETE FROM `pool_gameobject` WHERE `guid` IN (13877, 13878, 13879, 13880, 13898, 13899, 13900, 13901, 13902, 13903, 13908, 13913, 13893, 13904, 13905, 13906, 13907, 13911, 13916, 13953, 13917, 71497, 29482, 13909, 13910, 13912, 13851, 13857, 13858, 13859, 13860, 13861, 13862, 13863, 13866, 13867, 11100, 11101, 11102, 11103, 11104, 11105, 11106, 11107, 11108, 11109, 11110, 11111, 11112, 11113, 11114, 11115, 11116, 11117, 11118, 11119, 11127, 11128, 11129, 11130, 11131, 297, 3162, 3163, 3170, 3175, 1878, 1879, 1880, 1881, 1882, 29472, 29479, 29517, 31165, 31172, 907, 13918, 13919, 13922, 13924, 13925, 13930, 13931, 13932, 13933, 13955, 13956, 13957, 13959, 13960, 13961, 53011, 20458, 20459, 31619, 13929, 13926, 13962, 53045, 61890, 61889, 61891, 61887, 11043, 11040, 11062, 11063, 61915, 61917, 11061, 11060, 26549, 26551, 26552, 26310, 26316, 26306, 26305, 26668, 26672, 26295, 26669, 26308, 26671, 26307, 40919, 53437, 80525, 241113, 52663, 80668, 241105, 36180, 53207, 80443, 241172, 52718, 241236, 36621, 53991, 81038, 241176, 241109, 53858, 81039, 53593, 80833, 241222, 40921, 40923, 40935, 41665, 31236, 26277, 26278, 53398, 80447, 241261, 36179, 52784, 80692, 241258, 53201, 80505, 241235, 53396, 80446, 241175, 52750, 80688, 241223, 37044, 53432, 80506, 241257, 53110, 80517, 241234, 53330, 80524, 241231, 42800, 42801, 42794, 42802, 42793, 42803, 42795, 42798, 42796, 42797, 71527, 29473, 68644, 69024, 69035, 69056, 69059, 69069, 69081, 69085, 69087, 69088, 69093, 69094, 69109, 69118, 69119, 52846, 67089, 241114);
DELETE FROM `gameobject_addon` WHERE `guid` IN (13877, 13878, 13879, 13880, 13898, 13899, 13900, 13901, 13902, 13903, 13908, 13913, 13893, 13904, 13905, 13906, 13907, 13911, 13916, 13953, 13917, 71497, 29482, 13909, 13910, 13912, 13851, 13857, 13858, 13859, 13860, 13861, 13862, 13863, 13866, 13867, 11100, 11101, 11102, 11103, 11104, 11105, 11106, 11107, 11108, 11109, 11110, 11111, 11112, 11113, 11114, 11115, 11116, 11117, 11118, 11119, 11127, 11128, 11129, 11130, 11131, 297, 3162, 3163, 3170, 3175, 1878, 1879, 1880, 1881, 1882, 29472, 29479, 29517, 31165, 31172, 907, 13918, 13919, 13922, 13924, 13925, 13930, 13931, 13932, 13933, 13955, 13956, 13957, 13959, 13960, 13961, 53011, 20458, 20459, 31619, 13929, 13926, 13962, 53045, 61890, 61889, 61891, 61887, 11043, 11040, 11062, 11063, 61915, 61917, 11061, 11060, 26549, 26551, 26552, 26310, 26316, 26306, 26305, 26668, 26672, 26295, 26669, 26308, 26671, 26307, 40919, 53437, 80525, 241113, 52663, 80668, 241105, 36180, 53207, 80443, 241172, 52718, 241236, 36621, 53991, 81038, 241176, 241109, 53858, 81039, 53593, 80833, 241222, 40921, 40923, 40935, 41665, 31236, 26277, 26278, 53398, 80447, 241261, 36179, 52784, 80692, 241258, 53201, 80505, 241235, 53396, 80446, 241175, 52750, 80688, 241223, 37044, 53432, 80506, 241257, 53110, 80517, 241234, 53330, 80524, 241231, 42800, 42801, 42794, 42802, 42793, 42803, 42795, 42798, 42796, 42797, 71527, 29473, 68644, 69024, 69035, 69056, 69059, 69069, 69081, 69085, 69087, 69088, 69093, 69094, 69109, 69118, 69119, 52846, 67089, 241114);
