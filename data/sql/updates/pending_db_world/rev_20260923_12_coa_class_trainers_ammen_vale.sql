-- Conquest of Azeroth class trainers in Ammen Vale: fourteen new trainers for the classes the draenei
-- had in CoA (RACE-CLASS.md: CharBaseInfo.dbc), each dressed and named, and an intro letter for each
-- class that Proenitus hands out once the moth blood (9280) is in. Needs the class kits of
-- rev_20260923_05_coa_class_trainer_core.sql.
--
-- WHERE EACH VALUE COMES FROM
--   trainers  new characters (INFERRED): CoA left no trainer, quest or point in Ammen Vale. Names and
--     looks are ct-newzones' picks (plan/newzone_picks.csv), checked unique against every creature name in
--     the world database and the CoA creature cache. Level 10, faction 1638 (the stock Ammen Vale
--     trainers' own), trainer 900000 + class, class menu 930000 + class, all from the core kit.
--   places  hand-placed on the surveyed spots (plan/newzone_picks.csv), each walked again: the floor from
--     surface.floor, surface.check clean, on the navmesh component that joins the start, Proenitus and
--     Aldar, at least 2.5 yd from every NPC, 13 yd from any hostile spawn, 17 yd from the next trainer,
--     never more than two other trainers within 30 yd. The stock trainers Kore, Aurelon and Valaatu keep
--     their deck posts, so the Guardian, Templar and Chronomancer stand beside them on the same deck
--     instead. Each spawn's comment gives its reason and what it faces.
--   looks  stand-ins (no SMSG_MIRRORIMAGE_DATA capture of any trainer exists): each copies a stock draenei
--     NPC's CreatureDisplayInfoExtra look and changes it (listed per trainer in the preset comment), shown
--     through creature_display_preset on the plain draenei player display. Weapons from the same picks.
--   letters  INFERRED, modelled on each class's CoA letter (the Shadowglen one; the Pyromancer has none
--     there, so the Northshire one, 49983): same item look and flags, same quest sort, level, XP and money,
--     (the item cache lacks the Shadowglen letters 650143, 650156 and 650157; their live rows carry the same
--     look and flags as the cached Shadowglen letter 650148, which stands in for them),
--     rewritten for the new trainer, the landmark where the trainer stands, and draenei culture. Giver
--     Proenitus after 9280, as the stock Ammen Vale training quests follow 9280; draenei only
--     (AllowableRaces 1024) and one class each. The turn-in lines are authored (INFERRED).
--
-- Id blocks: creature 9300414-9300432, spawn guids 9004300-9004399, quest
-- and letter item 9302214-9302232, page_text 931214-931232.
-- No stock spawn is moved or deleted.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9300414, 'Seraath', 'Felsworn Trainer', 930014, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300416, 'Asheer Skyvoice', 'Stormbringer Trainer', 930016, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300417, 'Kuroth the Oathless', 'Knight of Xoroth Trainer', 930017, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300418, 'Defender Taroon', 'Guardian Trainer', 930018, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300419, 'Vindicator Oroshar', 'Templar Trainer', 930019, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300422, 'Seer Ohraan', 'Chronomancer Trainer', 930022, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300423, 'Ossiruun of the Auchenai', 'Necromancer Trainer', 930023, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300424, 'Pyraal', 'Pyromancer Trainer', 930024, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300425, 'Mazhaara', 'Cultist Trainer', 930025, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300426, 'Astraan', 'Starcaller Trainer', 930026, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300428, 'Artificer Bolaan', 'Tinker Trainer', 930028, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300430, 'Sorashii the Silent', 'Reaper Trainer', 930030, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300431, 'Elduur', 'Primalist Trainer', 930031, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300432, 'Scribe Taalan', 'Runemaster Trainer', 930032, 10, 10, 0, 1638, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9300414, 9300416, 9300417, 9300418, 9300419, 9300422, 9300423, 9300424, 9300425, 9300426, 9300428, 9300430, 9300431, 9300432);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(9300414, 0, 16126, 1, 1),
(9300416, 0, 16125, 1, 1),
(9300417, 0, 16125, 1, 1),
(9300418, 0, 16125, 1, 1),
(9300419, 0, 16125, 1, 1),
(9300422, 0, 16125, 1, 1),
(9300423, 0, 16125, 1, 1),
(9300424, 0, 16126, 1, 1),
(9300425, 0, 16126, 1, 1),
(9300426, 0, 16125, 1, 1),
(9300428, 0, 16125, 1, 1),
(9300430, 0, 16126, 1, 1),
(9300431, 0, 16125, 1, 1),
(9300432, 0, 16126, 1, 1);

-- 9300414 Seraath: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female
--   from Scout Vanura 16797 (display 16726), changed skin (dark), face, hair, hair colour and tendrils; the green
--   demon hunter class set (67449-67456) and the Warglaives of Azzinoth
-- 9300416 Asheer Skyvoice: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei
--   male from Thoralius the Wise 23975 (display 21947), changed skin, face, hair, hair colour and tendrils; keeps
--   the storm-touched mail
-- 9300417 Kuroth the Oathless: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei male from DK (Draenei Male) 28428 (display 25420), changed skin (fel red, 18), face, hair, hair colour
--   and tendrils; the red Deadly Gladiator's Dreadplate (48364, 48447, 47008, 48459, 47010), bare head and hands
-- 9300418 Defender Taroon: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei
--   male from Shield of Velen 20674 (display 20105), changed skin, face, hair, hair colour and tendrils; a draenei
--   guard cape (display 34407, from the Shattered Sun Warrior look 22918)
-- 9300419 Vindicator Oroshar: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei
--   male from Draenei Vindicator 16996 (display 16602), changed skin, face, hair, hair colour and tendrils; the
--   vindicator circlet (display 6071) and Aldor tabard (display 36117) of the Aldor Vindicator look 17905
-- 9300422 Seer Ohraan: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male
--   from Anchorite Truuen 17238 (display 16930), changed skin, face, hair colour and tendrils; keeps the anchorite
--   robes
-- 9300423 Ossiruun of the Auchenai: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei male from Auchenai Doomsayer 21285 (display 20187), changed the teal-blue Auchenai robe, frost mantle
--   and black cape with the black Death-Speaker hood (145457), ashen skin
-- 9300424 Pyraal: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female from
--   Shattered Sun Magi 25153 (display 22958), changed gender (female instead of male, for variety), face, hair,
--   hair colour and facial features; the Shattered Sun tabard (display 40734) removed, which belongs to the
--   Sunwell and not to Ammen Vale
-- 9300425 Mazhaara: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female
--   from Soulguard Animator 36516 (display 30169), changed face, hair, hair colour and tendrils; keeps the pale
--   skin; a plain dark cowl (26315), the Shadowsworn Cultist's Shadow Council robe and belt (148789, 150651), a
--   black skirt (153286) and a ritual blade
-- 9300426 Astraan: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from
--   Warp-Scryer Kryv 16839 (display 16384), changed skin, face, hair, hair colour and tendrils; keeps the scryer's
--   robes
-- 9300428 Artificer Bolaan: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei
--   male from Technician Halmaha 27711 (display 24761), changed skin, face, hair, hair colour and a clean chin;
--   keeps the monocle and brown gloves; work leathers instead of the yellow Draenei robe Seer Ohraan wears: the
--   leather jerkin 29843 and cream leather trousers 29844 of the Tracker Lyceon look 17141, the grey leather belt
--   29992 and boots 29994 of the Technician Dyvuun look 16260, and no shoulders
-- 9300430 Sorashii the Silent: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei female from Auchenai Initiate 21284 (display 20183), changed gender (female), skin (pale), face and
--   tendrils; the black Deathmantle hood and mantle (37992, 37994), a black robe (38304), a black cloak (11839)
--   and a scythe
-- 9300431 Elduur: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from
--   Berem 16737 (display 17244), changed skin and face; the Earthen Ring feathered headdress, gloves and boots
--   (20013, 18156, 23766), the Evergrove druids' forest-green leathers (35465, 34544, 34545, 34546) and a furbolg
--   totem
-- 9300432 Scribe Taalan: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei
--   female from Scribe Saalyn 20807 (display 19794), changed skin, face, hair, hair colour and tendrils; keeps the
--   Aldor scribe's robes and cloak
DELETE FROM `creature_display_preset` WHERE `entry` IN (9300414, 9300416, 9300417, 9300418, 9300419, 9300422, 9300423, 9300424, 9300425, 9300426, 9300428, 9300430, 9300431, 9300432);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(9300414, 16126, 11, 1, 1, 4, 7, 6, 4, 2, 0, 67449, 67450, 0, 67451, 67455, 67453, 67454, 67456, 67452, 0, 0),
(9300416, 16125, 11, 0, 1, 2, 6, 5, 2, 3, 0, 0, 39324, 0, 39325, 39326, 39327, 0, 39328, 0, 39329, 0),
(9300417, 16125, 11, 0, 1, 18, 8, 2, 10, 5, 0, 0, 48364, 0, 48447, 47008, 48459, 47010, 0, 0, 0, 0),
(9300418, 16125, 11, 0, 1, 5, 3, 7, 1, 6, 0, 968, 34411, 0, 34525, 34668, 34526, 34417, 0, 34669, 34407, 0),
(9300419, 16125, 11, 0, 1, 1, 4, 4, 3, 1, 0, 6071, 17564, 0, 17555, 28805, 18462, 29055, 0, 29056, 0, 36117),
(9300422, 16125, 11, 0, 1, 7, 1, 2, 5, 4, 0, 0, 0, 0, 30513, 24129, 29987, 0, 5728, 0, 0, 0),
(9300423, 16125, 11, 0, 1, 13, 9, 6, 1, 5, 0, 145457, 146448, 0, 149290, 151194, 153276, 0, 0, 157703, 158645, 0),
(9300424, 16126, 11, 1, 1, 3, 2, 8, 2, 3, 0, 40785, 40786, 0, 40788, 40789, 40790, 40791, 0, 40792, 0, 0),
(9300425, 16126, 11, 1, 1, 14, 4, 3, 6, 4, 0, 26315, 0, 0, 148789, 150651, 153286, 0, 0, 0, 0, 0),
(9300426, 16125, 11, 0, 1, 8, 5, 3, 4, 2, 0, 0, 0, 0, 28901, 28902, 28903, 0, 0, 0, 0, 0),
(9300428, 16125, 11, 0, 1, 6, 0, 1, 3, 0, 0, 14052, 0, 0, 29843, 29992, 29844, 29994, 0, 6970, 0, 0),
(9300430, 16126, 11, 1, 1, 5, 6, 4, 1, 3, 0, 37992, 37994, 0, 38304, 0, 0, 0, 0, 0, 11839, 0),
(9300431, 16125, 11, 0, 1, 4, 9, 3, 3, 2, 0, 20013, 35465, 0, 34544, 34545, 34546, 23766, 0, 18156, 0, 0),
(9300432, 16126, 11, 1, 1, 2, 8, 10, 0, 5, 0, 0, 0, 0, 32018, 31542, 30421, 0, 0, 0, 11820, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (9300414, 9300416, 9300417, 9300418, 9300419, 9300422, 9300423, 9300424, 9300425, 9300426, 9300428, 9300430, 9300431, 9300432);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(9300414, 1, 32837, 32838, 0),
(9300416, 1, 29683, 0, 0),
(9300417, 1, 37108, 0, 0),
(9300418, 1, 27407, 24331, 0),
(9300419, 1, 29124, 24331, 0),
(9300422, 1, 12591, 0, 0),
(9300423, 1, 13698, 0, 0),
(9300424, 1, 11343, 0, 0),
(9300425, 1, 5112, 0, 0),
(9300426, 1, 29676, 0, 0),
(9300428, 1, 1911, 0, 30758),
(9300430, 1, 36611, 0, 0),
(9300431, 1, 16769, 0, 0),
(9300432, 1, 24014, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (9300414, 9300416, 9300417, 9300418, 9300419, 9300422, 9300423, 9300424, 9300425, 9300426, 9300428, 9300430, 9300431, 9300432);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(9300414, 900014),
(9300416, 900016),
(9300417, 900017),
(9300418, 900018),
(9300419, 900019),
(9300422, 900022),
(9300423, 900023),
(9300424, 900024),
(9300425, 900025),
(9300426, 900026),
(9300428, 900028),
(9300430, 900030),
(9300431, 900031),
(9300432, 900032);

DELETE FROM `creature_template_addon` WHERE `entry` = 9300414;

-- ---------------------------------------------------------------------------
-- 2. Letters
-- ---------------------------------------------------------------------------
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `ItemLevel`, `maxcount`, `stackable`, `bonding`, `description`, `PageText`, `Material`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `RequiredDisenchantSkill`)
VALUES
(9302214, 0, 8, 'Fel-Scorched Pact', 142197, 1, 64, 0, 0, 1, 0, 'A pact sealed in green fire, written in the tongue of the man''ari.', 931214, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302216, 0, 8, 'Skyvoice Manuscript', 142197, 1, 64, 0, 0, 1, 0, 'A manuscript that crackles with the energy of a gathering storm.', 931216, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302217, 0, 8, 'Shadow-Sealed Proclamation', 142197, 1, 64, 0, 0, 1, 0, 'A proclamation bearing the seal of Xoroth, wreathed in cold shadow.', 931217, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302218, 0, 8, 'Vow of the Shield', 142197, 1, 64, 0, 0, 1, 0, 'A polished steel tablet inscribed with the vows of the Shield of Velen.', 931218, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302219, 0, 8, 'Light-Blessed Vow', 142197, 1, 64, 0, 0, 1, 0, 'A vow on blessed parchment, warm to the touch.', 931219, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302222, 0, 8, 'Shifting Scroll', 142197, 1, 64, 0, 0, 1, 0, 'A scroll whose text shows moments past and moments yet to come.', 931222, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302223, 0, 8, 'Auchenai Codex', 142197, 1, 64, 0, 0, 1, 0, 'A codex bound in bone; the air grows cold around it.', 931223, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302224, 12, 0, 'Scorched Manuscript', 142197, 1, 0, 1, 1, 1, 1, 'A manuscript scorched at the edges, still warm.', 931224, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(9302225, 0, 8, 'Writhing Parchment', 142197, 1, 64, 0, 0, 1, 0, 'A parchment whose symbols shift when you look away.', 931225, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302226, 0, 8, 'Star Chart of the Great Dark', 142197, 1, 64, 0, 0, 1, 0, 'A chart of the stars the Exodar crossed, twinkling with starlight.', 931226, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302228, 0, 8, 'Artificer''s Schematics', 142197, 1, 64, 0, 0, 1, 0, 'Schematics for crystal-powered devices, ticking faintly.', 931228, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302230, 0, 8, 'Black-Bound Letter', 142197, 1, 64, 0, 0, 1, 0, 'A letter bound in black leather that draws the light from the air.', 931230, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302231, 0, 8, 'Primal Scroll', 142197, 1, 64, 0, 0, 1, 0, 'A scroll swirling with tiny storms, flames and tremors.', 931231, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9302232, 0, 8, 'Tablet of Glowing Runes', 3108, 1, 64, 0, 0, 1, 0, 'A tablet carved with runes that glow with their own light.', 931232, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `ItemLevel` = VALUES(`ItemLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`), `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `PageText` = VALUES(`PageText`), `Material` = VALUES(`Material`), `holy_res` = VALUES(`holy_res`), `fire_res` = VALUES(`fire_res`), `nature_res` = VALUES(`nature_res`), `frost_res` = VALUES(`frost_res`), `shadow_res` = VALUES(`shadow_res`), `arcane_res` = VALUES(`arcane_res`), `delay` = VALUES(`delay`), `RequiredDisenchantSkill` = VALUES(`RequiredDisenchantSkill`);

DELETE FROM `page_text` WHERE `ID` IN (931214, 931216, 931217, 931218, 931219, 931222, 931223, 931224, 931225, 931226, 931228, 931230, 931231, 931232);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(931214, 'We fled Argus so that the Legion would never own us. Yet its fire is only a weapon, and a weapon can be taken from the hand that wields it.$B$BAs a Felsworn you will bind demonic essence to your will and burn the Legion''s servants with their own fel flame. Such power hungers; master it every day, or it will master you.$B$BI keep my distance from the camp, on the lower meadow beside the crystal on the way to Silverline Lake. Come to me there.$B$B- Seraath', 0),
(931216, 'The skies of Azeroth are wild and young, $N. They have not yet learned to fear us, nor we to fear them.$B$BAs a Stormbringer you will call lightning down from the clouds and bend the wind to your purpose. The storm will become your blade and your shield.$B$BI keep watch on the road from the escape pods, where it bends above the stream and the sky is widest. Find me there.$B$B- Asheer Skyvoice', 0),
(931217, 'Oaths bind. I broke mine, and I am freer for it - but not free of duty. Darkness is a weapon too, $N, and in the right hands it protects as surely as the Light.$B$BAs a Knight of Xoroth you will wear shadow like armor and strike with the cold fire of Xoroth, standing between the innocent and those who would harm them.$B$BThe vindicators must not learn of me. Come alone to the Sacred Grove, the hollow in the north-west cliffs, behind the tall silvermyst tree.$B$B- Kuroth the Oathless', 0),
(931218, 'We carried the Prophet across the stars because others stood between him and the Legion. That is the whole of our calling.$B$BAs a Guardian you will learn to take the blow meant for another, to hold your ground when every instinct tells you to yield, and to make of your shield a wall no enemy can pass.$B$BYou will find me on the deck of the Crash Site, among the wounded. Come to me there.$B$B- Defender Taroon', 0),
(931219, 'The naaru taught us that the Light is not a comfort to be hoarded, but a fire to be carried into the dark.$B$BAs a Templar you will fight with the Light in your blade and in your heart, judging the wicked and shielding the faithful. Your devotion will be your armor.$B$BI serve on the deck of the Crash Site, near Aurelon. Come to me when you are ready to take up the vow.$B$B- Vindicator Oroshar', 0),
(931222, 'The Prophet saw our future and led us away from ruin. Seeing is only the beginning, $N. Time can be bent, slowed and turned back upon itself by those who learn its currents.$B$BAs a Chronomancer you will hasten your allies, hold your enemies still in a single moment and unmake wounds before they are dealt.$B$BYou will find me on the deck of the Crash Site, near Valaatu. I have already seen you arrive.$B$B- Seer Ohraan', 0),
(931223, 'The Auchenai taught that death is not an ending but a door, and that those who understand the door may command what passes through it.$B$BAs a Necromancer you will raise the dead to serve you, drain the life of your foes and wield the power that lingers where life has fled. Our dead from the crash deserve rest; our enemies deserve no such mercy.$B$BI keep vigil at the graveyard west of the Crash Site, beside the tomb. Come to me there.$B$B- Ossiruun of the Auchenai', 0),
(931224, 'The Exodar fell burning from the sky, $N. I watched the fire and understood: flame is not only destruction. It is warmth, light and will made visible.$B$BAs a Pyromancer you will call fire into your hands and set your enemies ablaze, feeding the flame until it roars.$B$BYou will find me at the cook fire in Proenitus'' camp. Do not keep the fire waiting.$B$B- Pyraal', 0),
(931225, 'Not every voice in the dark belongs to the Legion. Some are older than the Legion, older than the naaru, and they have much to teach those brave enough to listen.$B$BAs a Cultist you will commune with powers beyond mortal understanding and bend their whispers into weapons. Knowledge has a price; pay it carefully.$B$BI wait in the field beyond the fallen silvermyst tree, south-east of Vindicator Aldar''s camp, where the whispers are clearest. Come alone.$B$B- Mazhaara', 0),
(931226, 'We crossed the Great Dark between the stars, $N. Every one of them sang to us along the way, and I have not stopped listening.$B$BAs a Starcaller you will draw power from distant suns and call their light down upon your enemies. The heavens will answer you as they answer me.$B$BYou will find me on the open knoll north of the graveyard, where the sky is clearest. Come at any hour; the stars do not sleep.$B$B- Astraan', 0),
(931228, 'Our ship did not fall. It landed badly. Everything that broke can be mended, and everything mended can be improved.$B$BAs a Tinker you will build devices, turrets and contraptions from whatever the world leaves lying about, and you will find that a clever mind is the finest weapon.$B$BYou will find me among the salvage crates inside the Crash Site, near Aurok. Bring your hands; the tools are mine.$B$B- Artificer Bolaan', 0),
(931230, 'Not every one of us survived the fall, $N. I stood beside those who did not, and I learned that death is not cruel. It is a harvest, and someone must bring it in.$B$BAs a Reaper you will wield the scythe and reap the souls of your enemies, turning their final moments into your strength.$B$BI keep watch beside the wrecked escape pod west of Botanist Taerix''s tent. I will not speak much. I will teach.$B$B- Sorashii the Silent', 0),
(931231, 'The shaman ask the elements for their aid. I do not ask.$B$BAs a Primalist you will command earth, air, fire and water in their purest forms, and they will obey you whether they wish to or not. The elements of this world are wild; they need a firm hand.$B$BI am beneath the silvermyst trees in the meadow north-west of Proenitus'' camp. Come and learn what it means to rule the elements.$B$B- Elduur', 0),
(931232, 'Our scribes have always known that a word carved true outlasts the hand that carved it. The runes of this world are older still, and they hold power.$B$BAs a Runemaster you will inscribe runes of power into weapon, armor and the very ground, and your wards will endure long after other magic fades.$B$BYou will find me at the foot of the great silvermyst crystal, west of Proenitus'' camp. Bring patience; the runes reward it.$B$B- Scribe Taalan', 0);

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `AllowableRaces`)
VALUES
(9302214, 2, 2, 2, -517, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302214, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Pact of Green Fire', 'Seek out Seraath on the lower meadow west of Vindicator Aldar''s camp in Ammen Vale.', 'This was left in my keeping for you, $N, though I confess I did not want to hold it. It is a pact written in green fire, and its script is the tongue of the man''ari - the eredar who gave themselves to the Legion.$B$BIt comes from Seraath, who turns the Legion''s own fire against it. She keeps apart from our camp, on the lower meadow west of Vindicator Aldar''s camp, beside the crystal on the way to Silverline Lake. Read it before you return to your duties here.', '', 'Seek out Seraath on the lower meadow west of Vindicator Aldar''s camp in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302214, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Seraath on the lower meadow west of Vindicator Aldar''s camp in Ammen Vale', '', '', '', 1024),
(9302216, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302216, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Storm''s Voice', 'Seek out Asheer Skyvoice where the road from the escape pods bends above the stream in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a manuscript that crackles with a storm''s energy; the air tingled when I first touched it.$B$BIt comes from Asheer Skyvoice, who hears the storms of this new world. You will find him on the road you came down, where it bends above the stream. Read it before you return to your duties here.', '', 'Seek out Asheer Skyvoice where the road from the escape pods bends above the stream in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302216, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Asheer Skyvoice where the road from the escape pods bends above the stream in Ammen Vale', '', '', '', 1024),
(9302217, 2, 2, 2, -518, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302217, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Oath of Shadow', 'Seek out Kuroth the Oathless in the Sacred Grove, in the north-west cliffs of Ammen Vale.', 'This was left among my things for you, $N, and I cannot say who left it. It appears to be a proclamation bearing the seal of Xoroth, wreathed in cold shadow.$B$BThe seal names Kuroth the Oathless, a knight I have never met. If he is in the vale, he has hidden himself well. The letter bids you seek him in the Sacred Grove, the hollow in the north-west cliffs. Read it before you return to your duties here.', '', 'Seek out Kuroth the Oathless in the Sacred Grove, in the north-west cliffs of Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302217, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Kuroth the Oathless in the Sacred Grove, in the north-west cliffs of Ammen Vale', '', '', '', 1024),
(9302218, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302218, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Shield''s Vow', 'Seek out Defender Taroon on the deck of the Crash Site in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a polished steel tablet inscribed with vows of protection, the kind the Shield of Velen swears.$B$BIt comes from Defender Taroon, who stands watch over our wounded on the deck of the Crash Site, beside Kore. Read it before you return to your duties here.', '', 'Seek out Defender Taroon on the deck of the Crash Site in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302218, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Defender Taroon on the deck of the Crash Site in Ammen Vale', '', '', '', 1024),
(9302219, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302219, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Light-Blessed Vow', 'Seek out Vindicator Oroshar on the deck of the Crash Site in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a vow written on blessed parchment; it is warm in the hand and fills the heart with courage.$B$BIt comes from Vindicator Oroshar, a templar of the Light who serves on the deck of the Crash Site, near Aurelon. Read it before you return to your duties here.', '', 'Seek out Vindicator Oroshar on the deck of the Crash Site in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302219, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Vindicator Oroshar on the deck of the Crash Site in Ammen Vale', '', '', '', 1024),
(9302222, 2, 2, 2, -530, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302222, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Glimpse of What Will Be', 'Seek out Seer Ohraan on the deck of the Crash Site in Ammen Vale.', 'This was left in my keeping for you, $N - or perhaps it was always going to be here. The text shifts as I read it, showing moments that have passed and moments yet to come.$B$BIt comes from Seer Ohraan, who studies the currents of time as the Prophet studies the paths of fate. He is on the deck of the Crash Site, near Valaatu. Read it before you return to your duties here.', '', 'Seek out Seer Ohraan on the deck of the Crash Site in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302222, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Seer Ohraan on the deck of the Crash Site in Ammen Vale', '', '', '', 1024),
(9302223, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302223, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Auchenai Codex', 'Seek out Ossiruun of the Auchenai at the graveyard west of the Crash Site in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a codex bound in bone; the air grows cold around it, and I hear faint whispers of the departed from its pages.$B$BIt comes from Ossiruun of the Auchenai, who keeps vigil over our dead at the graveyard west of the Crash Site, beside the tomb. Read it before you return to your duties here.', '', 'Seek out Ossiruun of the Auchenai at the graveyard west of the Crash Site in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302223, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Ossiruun of the Auchenai at the graveyard west of the Crash Site in Ammen Vale', '', '', '', 1024),
(9302224, 2, 2, 2, -528, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302224, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Embers of the Exodar', 'Seek out Pyraal at the cook fire in Proenitus'' camp in Ammen Vale.', 'This was left in my keeping for you, $N. Careful - it is still warm. The pages are scorched at the edges, and flames dance across them without burning them away.$B$BIt comes from Pyraal, who tends the cook fire right here in my camp, and I suspect tends a great deal more fire than that. Read it before you return to your duties here.', '', 'Seek out Pyraal at the cook fire in Proenitus'' camp in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302224, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Pyraal at the cook fire in Proenitus'' camp in Ammen Vale', '', '', '', 1024),
(9302225, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302225, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Whispers in the Wreckage', 'Seek out Mazhaara beyond the fallen silvermyst tree south-east of Vindicator Aldar''s camp in Ammen Vale.', 'This was left in my keeping for you, $N, and I will be glad to be rid of it. The symbols on it shift when I look away, and I hear whispers I cannot make out.$B$BIt comes from Mazhaara, who listens to voices the rest of us would rather not hear. She waits in the field beyond the fallen silvermyst tree, south-east of Vindicator Aldar''s camp. Read it before you return to your duties here.', '', 'Seek out Mazhaara beyond the fallen silvermyst tree south-east of Vindicator Aldar''s camp in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302225, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Mazhaara beyond the fallen silvermyst tree south-east of Vindicator Aldar''s camp in Ammen Vale', '', '', '', 1024),
(9302226, 2, 2, 2, -506, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302226, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Charts of the Great Dark', 'Seek out Astraan on the open knoll north of the graveyard in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a chart of the stars, and they twinkle on the page with real starlight - the very stars we crossed aboard the Exodar.$B$BIt comes from Astraan, who reads the heavens from the open knoll north of the graveyard. Read it before you return to your duties here.', '', 'Seek out Astraan on the open knoll north of the graveyard in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302226, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Astraan on the open knoll north of the graveyard in Ammen Vale', '', '', '', 1024),
(9302228, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302228, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Salvage and Schematics', 'Seek out Artificer Bolaan among the salvage crates inside the Crash Site in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a set of schematics covered in designs for crystal-powered devices; I can hear a faint ticking from between its pages.$B$BIt comes from Artificer Bolaan, who is sorting salvage from the wreck inside the Crash Site, near Aurok. Read it before you return to your duties here.', '', 'Seek out Artificer Bolaan among the salvage crates inside the Crash Site in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302228, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Artificer Bolaan among the salvage crates inside the Crash Site in Ammen Vale', '', '', '', 1024),
(9302230, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302230, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Silent Harvest', 'Seek out Sorashii the Silent by the wrecked escape pod west of Botanist Taerix''s tent in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a letter bound in black leather that seems to draw the light out of the air around it.$B$BIt comes from Sorashii the Silent, who watches over the wrecked escape pod west of Botanist Taerix''s tent, where some of our people did not survive the fall. Read it before you return to your duties here.', '', 'Seek out Sorashii the Silent by the wrecked escape pod west of Botanist Taerix''s tent in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302230, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Sorashii the Silent by the wrecked escape pod west of Botanist Taerix''s tent in Ammen Vale', '', '', '', 1024),
(9302231, 2, 2, 2, -531, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302231, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Elements Obey', 'Seek out Elduur beneath the silvermyst trees in the meadow north-west of Proenitus'' camp in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a scroll that crackles with raw elemental power; tiny storms, flames and tremors swirl across it.$B$BIt comes from Elduur, who commands the elements beneath the silvermyst trees in the meadow north-west of this camp. Read it before you return to your duties here.', '', 'Seek out Elduur beneath the silvermyst trees in the meadow north-west of Proenitus'' camp in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302231, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Elduur beneath the silvermyst trees in the meadow north-west of Proenitus'' camp in Ammen Vale', '', '', '', 1024),
(9302232, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302232, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runes Older Than Argus', 'Seek out Scribe Taalan at the foot of the great silvermyst crystal west of Proenitus'' camp in Ammen Vale.', 'This was left in my keeping for you, $N. It appears to be a tablet carved with runes that glow with their own light; the symbols are older than any I learned on Argus.$B$BIt comes from Scribe Taalan, who studies them at the foot of the great silvermyst crystal, west of this camp. Read it before you return to your duties here.', '', 'Seek out Scribe Taalan at the foot of the great silvermyst crystal west of Proenitus'' camp in Ammen Vale.', 0, 0, 0, 0, 0, 0, 0, 0, 9302232, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Scribe Taalan at the foot of the great silvermyst crystal west of Proenitus'' camp in Ammen Vale', '', '', '', 1024)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `AllowableRaces` = VALUES(`AllowableRaces`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (9302214, 9302216, 9302217, 9302218, 9302219, 9302222, 9302223, 9302224, 9302225, 9302226, 9302228, 9302230, 9302231, 9302232);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(9302214, 0, 8192, 9280, 1, 0),
(9302216, 0, 32768, 9280, 1, 0),
(9302217, 0, 65536, 9280, 1, 0),
(9302218, 0, 131072, 9280, 1, 0),
(9302219, 0, 262144, 9280, 1, 0),
(9302222, 0, 2097152, 9280, 1, 0),
(9302223, 0, 4194304, 9280, 1, 0),
(9302224, 0, 8388608, 9280, 1, 0),
(9302225, 0, 16777216, 9280, 1, 0),
(9302226, 0, 33554432, 9280, 1, 0),
(9302228, 0, 134217728, 9280, 1, 0),
(9302230, 0, 536870912, 9280, 1, 0),
(9302231, 0, 1073741824, 9280, 1, 0),
(9302232, 0, 2147483648, 9280, 1, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (9302214, 9302216, 9302217, 9302218, 9302219, 9302222, 9302223, 9302224, 9302225, 9302226, 9302228, 9302230, 9302231, 9302232);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`)
VALUES
(9302214, 1, 'You came, and you did not flinch at the pact. Good. The others watch me as though the Legion walks beside me. Perhaps it does - but it walks on a leash, $N. Let me show you how to hold it.'),
(9302216, 1, 'The storm told me you would come; it has been restless all morning. Stand with me, $N, and listen. There is thunder in you, waiting to be called.'),
(9302217, 1, 'So you found me, and you came alone. Aldar would call that foolish, if he knew I was here. I call it resolve. We will see which of us is right, $N.'),
(9302218, 1, 'Good. Our people have need of every shield. Stand beside me a while, $N; I will show you how a Guardian stands.'),
(9302219, 1, 'The Light guided this vow to you, $N, and you to me. That is no small thing. Let us begin your service.'),
(9302222, 1, 'There you are - exactly when I saw you coming. Do not look so surprised, $N. Surprise is a luxury my students soon outgrow.'),
(9302223, 1, 'The dead told me you would come. They are rarely wrong, $N. Stand here with me, among them, and let us see whether you have the will for this path.'),
(9302224, 1, 'Ah, you felt it too - the heat in those pages. Good. Come closer to the fire, $N. We will start small.'),
(9302225, 1, 'You heard them too, didn''t you? When you read the parchment. Do not be afraid, $N. They only whisper to those they have chosen.'),
(9302226, 1, 'Look up, $N. Those stars carried us here. Now let me show you how to make them answer.'),
(9302228, 1, 'Ah, the schematics found you. Mind the third page; the diagram is upside down. Deliberately, of course. Now then, $N - let us see what you can build.'),
(9302230, 1, '... You read it. Good. Take up the scythe, $N. The rest will come.'),
(9302231, 1, 'Good. Feel the ground beneath you, $N - the life in it, the fire deep below. All of it is waiting to be told what to do. Let us begin.'),
(9302232, 1, 'You read the tablet. Did you notice the runes shift as you did? They were reading you, $N. They seem to approve. Sit; we have much to carve.');

DELETE FROM `quest_request_items` WHERE `ID` IN (9302214, 9302216, 9302217, 9302218, 9302219, 9302222, 9302223, 9302224, 9302225, 9302226, 9302228, 9302230, 9302231, 9302232);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(9302214, ''),
(9302216, ''),
(9302217, ''),
(9302218, ''),
(9302219, ''),
(9302222, ''),
(9302223, ''),
(9302224, ''),
(9302225, ''),
(9302226, ''),
(9302228, ''),
(9302230, ''),
(9302231, ''),
(9302232, '');

DELETE FROM `creature_queststarter` WHERE `quest` IN (9302214, 9302216, 9302217, 9302218, 9302219, 9302222, 9302223, 9302224, 9302225, 9302226, 9302228, 9302230, 9302231, 9302232);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(16477, 9302214),
(16477, 9302216),
(16477, 9302217),
(16477, 9302218),
(16477, 9302219),
(16477, 9302222),
(16477, 9302223),
(16477, 9302224),
(16477, 9302225),
(16477, 9302226),
(16477, 9302228),
(16477, 9302230),
(16477, 9302231),
(16477, 9302232);

DELETE FROM `creature_questender` WHERE `quest` IN (9302214, 9302216, 9302217, 9302218, 9302219, 9302222, 9302223, 9302224, 9302225, 9302226, 9302228, 9302230, 9302231, 9302232);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(9300414, 9302214),
(9300416, 9302216),
(9300417, 9302217),
(9300418, 9302218),
(9300419, 9302219),
(9300422, 9302222),
(9300423, 9302223),
(9300424, 9302224),
(9300425, 9302225),
(9300426, 9302226),
(9300428, 9302228),
(9300430, 9302230),
(9300431, 9302231),
(9300432, 9302232);

-- ---------------------------------------------------------------------------
-- 3. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9004314, 9004316, 9004317, 9004318, 9004319, 9004322, 9004323, 9004324, 9004325, 9004326, 9004328, 9004330, 9004331, 9004332) OR `guid` BETWEEN 9004300 AND 9004399;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004314, 9300414, 530, 0, 0, 1, 1, 1, -4231, -13646, 53.692, 5.093, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Felsworn trainer: Ammen Vale: hand-placed (INFERRED) on the lower meadow west of Vindicator Aldar''s camp, 7 yd from the crystal on the way to Silverline Lake (Silvermystcrystalbig03, -4245, -13633; the letters call only Scribe Taalan''s crystal by Proenitus'' camp the great silvermyst crystal); a Felsworn keeps apart from the camp. Moved 5.7 yd north-east of the planned point so the nearest Volatile Mutation (guid 57247, wander 5) is 17.4 yd away instead of 13.6, inspected with inspect_area and passing surface.check; faces 5.093 toward Vindicator Aldar''s camp, the way players come down to the meadow, the way players arrive'),
(9004316, 9300416, 530, 0, 0, 1, 1, 1, -4010, -13812, 78.156, 5.162, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Stormbringer trainer: Ammen Vale: hand-placed (INFERRED) on the road down from the escape pods, where it bends above the stream under the open sky; the first trainer players pass on their way into the vale, inspected with inspect_area and passing surface.check; faces 5.162 toward up the road toward the escape pods (-3983, -13868), the way players come down; the ground rises 13 degrees with the road, the way players arrive'),
(9004317, 9300417, 530, 0, 0, 1, 1, 1, -3903, -13432, 73.528, 4.391, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Knight of Xoroth trainer: Ammen Vale: hand-placed (INFERRED) hidden in the Sacred Grove, the hollow in the north-west cliffs, 6.7 yd north of the tall silvermyst tree whose trunk screens him from the vale, inspected with inspect_area and passing surface.check; faces 4.391 toward the grove mouth (-3908, -13447), the one open way into the hollow, the way players arrive'),
(9004318, 9300418, 530, 0, 0, 1, 1, 1, -4138.2, -13742.5, 74.562, 5.895, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Guardian trainer: Ammen Vale: hand-placed (INFERRED) on the Crash Site deck, 3.5 yd to the right of Kore (guid 84574), who keeps his post (BUILD-PLAN s0 forbids his post); a deliberate pair of warriors, following CoA''s own habit of standing its trainers beside the stock ones, inspected with inspect_area and passing surface.check; faces 5.895 toward the deck centre (-4115, -13752), which every stock deck trainer faces (Kore 5.60, Valaatu 4.92, Aurelon 3.75), the way players arrive'),
(9004319, 9300419, 530, 0, 0, 1, 1, 1, -4101.2, -13747.1, 74.629, 3.483, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Templar trainer: Ammen Vale: hand-placed (INFERRED) on the Crash Site deck, 3.5 yd beside Aurelon (guid 57212), who keeps his post; two servants of the Light side by side, inspected with inspect_area and passing surface.check; faces 3.483 toward the deck centre (-4115, -13752), which every stock deck trainer faces, the way players arrive'),
(9004322, 9300422, 530, 0, 0, 1, 1, 1, -4121.8, -13737.5, 74.636, 5.151, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Chronomancer trainer: Ammen Vale: hand-placed (INFERRED) on the Crash Site deck, 4.8 yd from Valaatu (guid 84581), who keeps his post; the seer keeps to the arcane side of the deck, inspected with inspect_area and passing surface.check; faces 5.151 toward the deck centre (-4115, -13752), which every stock deck trainer faces, the way players arrive'),
(9004323, 9300423, 530, 0, 0, 1, 1, 1, -4110, -13672, 74.831, 5.537, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Necromancer trainer: Ammen Vale: hand-placed (INFERRED) in the draenei graveyard west of the Crash Site, his back to the tomb (Dr_Tomb, -4115, -13666), 12.6 yd from the Spirit Healer; the Auchenai keep vigil over the dead, inspected with inspect_area and passing surface.check; faces 5.537 toward the path from Botanist Taerix''s tent (-4057, -13721), the way players reach the graveyard, the way players arrive'),
(9004324, 9300424, 530, 0, 0, 1, 1, 1, -4034, -13763, 75.956, 5.168, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Pyromancer trainer: Ammen Vale: hand-placed (INFERRED) in Proenitus'' camp, between the two halves of a burst escape pod and 6.7 yd from the camp''s only fire (the Cookpot, guid 24929); 12 yd from Proenitus, inspected with inspect_area and passing surface.check; faces 5.168 toward the road down from the escape pods (-4010, -13812), the way players arrive at the camp, the way players arrive'),
(9004325, 9300425, 530, 0, 0, 1, 1, 1, -4206, -13762, 74.43, 1.176, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Cultist trainer: Ammen Vale: hand-placed (INFERRED) in the field in the lee of the fallen silvermyst tree by the stream crossing, south-east of Vindicator Aldar''s camp; the planned nook between the hull plates (-4096, -13786) is a sealed navmesh pocket players cannot reach, so she listens to her whispers out here, away from the vindicators, inspected with inspect_area and passing surface.check; faces 1.176 toward Vindicator Aldar''s camp (-4195.1, -13735.8), the way players come around the fallen tree, the way players arrive'),
(9004326, 9300426, 530, 0, 0, 1, 1, 1, -4078, -13660, 77.888, 4.33, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Starcaller trainer: Ammen Vale: hand-placed (INFERRED) on top of the open knoll north of the graveyard, under the clearest sky in the vale, inspected with inspect_area and passing surface.check; faces 4.330 toward the Crash Site deck (-4115, -13752) over the open south-east slope, where players climb the knoll after coming round the south side of the torn silvermyst tree (Silvermysttreetorn04), whose trunk fills bearings 290-320 degrees 4.5 yd away and hides the straight line to Botanist Taerix''s tent, the way players arrive'),
(9004328, 9300428, 530, 0, 0, 1, 1, 1, -4068, -13762, 74.759, 6.099, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Tinker trainer: Ammen Vale: hand-placed (INFERRED) inside the Crash Site on the merchant floor, by the salvage crates and 7.6 yd from Aurok, 7.5 yd inside the hull''s north doorway, inspected with inspect_area and passing surface.check; faces 6.099 toward the hull''s north doorway (-4060.5, -13763.4), where players come in from Proenitus'' camp, the way players arrive'),
(9004330, 9300430, 530, 0, 0, 1, 1, 1, -4060, -13666, 71.046, 4.767, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Reaper trainer: Ammen Vale: hand-placed (INFERRED) at the north-east corner of the wrecked escape pod (Dr_Cryopod_Wrecked, -4063, -13663.5) west of Botanist Taerix''s tent, where some of the crash''s dead lay. The planned point (-4058, -13668) had a Vale Moth (guid 57400, wander 5) 11.9 yd away and the pod''s north side is a 40 degree slope, so she stands here: slope 18, moth 14.3 yd, 19 yd from the Starcaller, inspected with inspect_area and passing surface.check; faces 4.767 toward the path from Botanist Taerix''s tent (-4057, -13721), the way players come, the way players arrive'),
(9004331, 9300431, 530, 0, 0, 1, 1, 1, -3998.3, -13738.3, 68.828, 3.852, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Primalist trainer: Ammen Vale: hand-placed (INFERRED) in the northern meadow under the silvermyst trees, his back 2 yd from the trunk of Silvermysttree01, north-west of Proenitus'' camp. Moved 4.8 yd north-east of the planned point (-4003, -13735) so the two nearest Vale Moths of the moth-blood field (guids 57364 and 57362, wander 5) are 17.3 yd away instead of 13.4 and 17.8, and stay beyond 12 yd at the end of their wander; slope 3.4 instead of 6.4, inspected with inspect_area and passing surface.check; faces 3.852 toward Proenitus'' camp (-4039.4, -13773.7), the way players come up to the meadow, the way players arrive'),
(9004332, 9300432, 530, 0, 0, 1, 1, 1, -4040, -13734, 74.559, 4.728, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ammen Vale Runemaster trainer: Ammen Vale: hand-placed (INFERRED) at the east foot of the great silvermyst crystal (Silvermystcrystalbig03, -4035, -13717), west of Proenitus'' camp, inspected with inspect_area and passing surface.check; faces 4.728 toward Proenitus'' camp (-4039.4, -13773.7), the way players come, the way players arrive');
