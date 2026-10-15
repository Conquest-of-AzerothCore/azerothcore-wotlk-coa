-- Conquest of Azeroth class trainers in the Exodar: one new draenei trainer for each of CoA's 14
-- draenei classes, spread through the city. No quests; every trainer serves its class kit from
-- migration 05.
--
-- WHERE EACH VALUE COMES FROM
--   classes  the draenei classes of CoA (RACE-CLASS.md: CharBaseInfo.dbc race 11): Felsworn,
--     Stormbringer, Knight of Xoroth, Guardian, Templar, Chronomancer, Necromancer, Pyromancer,
--     Cultist, Starcaller, Tinker, Reaper, Primalist, Runemaster. SOURCED-CLIENT.
--   positions  INFERRED: CoA had no trainer in the Exodar, so every spot is hand-chosen for its class
--     in the hall or landmark that suits it, surveyed with surface.py floor maps and inspect_area
--     model lists. z is the surface.floor height on the CoA vmaps (the Exodar WMO is unchanged from
--     stock: 305 interior stock spawns sit on its floors with a median offset of 0.08 yd). Every spot
--     passes surface.check (no floating, sinking, enclosure, low headroom or steep floor) and lies on
--     a ground polygon of the server navmesh connected to the city hub, Prophet Velen and the
--     entrance outside. Clearance, event spawns included: 10 yd or more from every creature, 4 yd or
--     more from every object (4.1 yd is the Pyromancer beside her brazier, on purpose), 12 yd or more
--     from every kept stock class trainer; the trainers stand 55-146 yd apart.
--   facing  toward the way players arrive, named per trainer; no wall within 6 yd in that direction.
--     The approaches follow the city ring road that the Peacekeeper and Emissary patrols walk.
--   looks  stand-ins: no SMSG_MIRRORIMAGE_DATA capture of these new characters exists. Each copies the
--     CreatureDisplayInfoExtra look of a stock draenei NPC that fits the class and changes hair,
--     face or armour so that no two trainers look alike; creature_display_preset carries race 11,
--     the sex, the customization and 11 ItemDisplayInfo ids, and creature_template_model the plain
--     draenei display (16125 male, 16126 female). Every look passes ct_common.check_look.
--   weapons  Item.dbc items the core accepts in each hand (ct_common.equip_row).
--   template  ct_common.trainer_template: level 60, Exodar faction 1638, npcflag 49 (gossip,
--     trainer, class trainer; no quests), the class menu 930000 + class and trainer 900000 + class.
--   names  new draenei characters (INFERRED), unique in creature_template and the CoA creature cache.
-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------

-- 9300514 Haraaz Felscar, Felsworn Trainer (guid 9004814): the Hunters' Sanctum terrace, 8.7 yd from the sanctum
--   sign: the demon hunter keeps to the hunters' hall. Faces 4.750 toward the head of the ramp up from the forge
--   hall at (-4211.6, -11607), 24 yd ahead, where every route onto the terrace arrives (Peacekeeper path 577320
--   climbs it; the terrace corner above the ring road has no way up). new NPC Haraaz Felscar, named as a new
--   draenei character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from Hunter of the Hand, entry 17875,
--   display 17281, changed hair 2 to 5, face 2 to 4; the spiked black plate mantle of Vindicator Aesom of the
--   Hand (display 17276) over the green Hand of Argus mail, for a fel-marked hunter of demons. Weapons: Glaive
--   of the First Demon Hunter in both hands.

-- 9300516 Kuraax Stormspeaker, Stormbringer Trainer (guid 9004816): the Crystal Hall, beside the brazier and the
--   Silvermyst crystal at the east rim of the shaman stones' pit, the draenei hall of the elements. Faces 3.514
--   toward the ring road coming down from the platform into the Crystal Hall at (-3820, -11479). new NPC Kuraax
--   Stormspeaker, named as a new draenei character (lore-fitting, unique) (INFERRED: no cache record). look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from Elementalist Avuun,
--   entry 32900, display 28368, changed hair 0 to 6, facial hair 4 to 2; the purple cape of Cleric of Karabor
--   (display 20551) over the purple storm mail and crown. Weapons: Lightning Giant Staff.

-- 9300517 Vorathaan Ashmantle, Knight of Xoroth Trainer (guid 9004817): the Trader's Tier forge hall, on the
--   open floor between the forges and the Engineering benches. Faces 0.927 toward the ramp down from the
--   Hunters' Sanctum terrace at (-4215.6, -11645.5), the hall's way in from the north. new NPC Vorathaan
--   Ashmantle, named as a new draenei character (lore-fitting, unique) (INFERRED: no cache record). look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from Ebon Knight, entry
--   32309, display 26000, changed face 0 to 5, facial hair 3 to 6; the silver cape swapped for the Blackflame
--   Cape under the black plate and helm, a knight of the fire world Xoroth. Weapons: a violet two-handed
--   runeblade.

-- 9300518 Warden Iruvaa, Guardian Trainer (guid 9004818): the rim of the Ring of Arms, the warriors' sparring
--   ring on the upper tier. Faces 0.709 toward the top of the ramp into the Ring at (-4160, -11636), where the
--   Peacekeeper stands. new NPC Warden Iruvaa, named as a new draenei character (lore-fitting, unique)
--   (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei female from Defender Adrielle, entry 18020, display 17424, changed hair 10 to 3; the blue plate helm
--   of the draenei Shattered Sun Warrior (display 22918) and the draenei guard pauldrons of Vengeful Draenei
--   (display 20289) over the silver draenei mail, a shield-bearing defender. Weapons: a draenei mace and the
--   Draenei Honor Guard Shield.

-- 9300519 Lightwarden Moraala, Templar Trainer (guid 9004819): the Vindicators' Sanctum, beside the hammer table
--   among the armour stands. Faces 0.448 toward the sanctum door at (-4163, -11475). new NPC Lightwarden
--   Moraala, named as a new draenei character (lore-fitting, unique) (INFERRED: no cache record). look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female from Lightsworn
--   Vindicator, entry 22861, display 21128, changed hair 1 to 7, colour 3 to 0; the Aldor tabard removed from
--   the bright vindicator plate. Weapons: Hammer of the Naaru.

-- 9300522 Archivist Tolaara, Chronomancer Trainer (guid 9004822): the Vault of Lights, among the holographic
--   emitters that replay the draenei past, 5.9 yd off Audrid's tour (SmartAI waypoints 18903) and 6.6 yd from
--   its 60 s stop at the emitter. Faces 5.800 toward the ring road entering the Vault at (-4018, -11465). new
--   NPC Archivist Tolaara, named as a new draenei character (lore-fitting, unique) (INFERRED: no cache record).
--   look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female from Custodian
--   of Time, entry 19950, display 19280, changed hair 4 to 6; the sand-yellow draenei robe and mantle of
--   Recorder Lidio (display 28804) over the white robe, bronze and sand tones for a keeper of time. Weapons: Key
--   of Time.

-- 9300523 Soulbinder Kaarun, Necromancer Trainer (guid 9004823): outside the Anchorites' Sanctum, his back to
--   its wall: an Auchenai kept apart from the anchorites. Faces 5.799 toward the path from the Seat of the Naaru
--   at (-3964, -11530). new NPC Soulbinder Kaarun, named as a new draenei character (lore-fitting, unique)
--   (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei male from Auchenai Necromancer, entry 18702, display 18078, changed hair 5 to 2, facial hair 5 to 7;
--   a black cape under the dark robe and bone mantle of the Auchenai. Weapons: The Bringer of Death.

-- 9300524 Ilaara Cindervow, Pyromancer Trainer (guid 9004824): the brazier at the Crystal Hall's south gate,
--   where the ring road passes between two braziers. Faces 3.888 toward the ring road from the Seat of the Naaru
--   at (-3846.5, -11539.5). new NPC Ilaara Cindervow, named as a new draenei character (lore-fitting, unique)
--   (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei female from Exodar Firebreather, entry 22802, display 21084, changed hair colour 6 to 2; the orange
--   robe of the male Exodar Firebreather (display 21083) in place of the brown cloth and purple belt. Weapons:
--   Staff of Hale Magefire.

-- 9300525 Nyrosha the Veiled, Cultist Trainer (guid 9004825): the crystal mine, where the Broken miners cut the
--   whispering crystals, far from the halls. Faces 3.059 toward the mine mouth from the jewelcrafters at (-3760,
--   -11535). new NPC Nyrosha the Veiled, named as a new draenei character (lore-fitting, unique) (INFERRED: no
--   cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female
--   from Wyrmcult Zealot, entry 21382, display 20253, changed hair 9 to 6; a purple hood over the black cultist
--   leathers. Weapons: Ritual Blade and Skull of Impending Doom.

-- 9300526 Starseer Naliima, Starcaller Trainer (guid 9004826): the rim of the Seat of the Naaru, above the shaft
--   where O'ros, the heart of the ship that crossed the stars, hovers far below. Faces 2.324 toward the hub road
--   at (-3905, -11615), between the bank and the Crystal Hall sign. new NPC Starseer Naliima, named as a new
--   draenei character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei female from Cleric of Karabor, entry 21815,
--   display 20553, changed hair 4 to 10, colour 6 to 3; the blue hood removed from the deep blue draenei robe.
--   Weapons: Starshine Staff.

-- 9300528 Technician Draalon, Tinker Trainer (guid 9004828): at the Exodar's power crystals, a dozen yards in
--   front of Artificers Andren and Drenin. Faces 1.438 toward the Trader's Tier at (-3950, -11700). new NPC
--   Technician Draalon, named as a new draenei character (lore-fitting, unique) (INFERRED: no cache record).
--   look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from Senior
--   Demolitionist Legoso, entry 31109, display 17384, changed hair 4 to 7; Technician Dyvuun's (display 16260)
--   orange work leathers and grey gloves under the goggles and blue mail. Weapons: Tinker's Wrench and Megashot
--   Rifle.

-- 9300530 Morvaal the Grim, Reaper Trainer (guid 9004830): the Trader's Tier armoury, by the blade shop's weapon
--   racks. Faces 0.833 toward the armoury corridor at (-4202, -11772). new NPC Morvaal the Grim, named as a new
--   draenei character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from Ebon Blade Vindicator, entry 32488,
--   display 27996, changed the death knight helm swapped for a black hood and the Ebon Blade tabard removed from
--   the charcoal plate, a hooded reaper; skin 15 (a death knight skin, CharSections flags 6) to the player skin
--   13. Weapons: Frostscythe of Lord Ahune.

-- 9300531 Wildkeeper Oraana, Primalist Trainer (guid 9004831): the moth keeper's platform in the Crystal Hall,
--   with Sixx the Moth Keeper and the moths 11-14 yd behind her. Faces 4.332 toward the ring road crossing the
--   platform at (-3870, -11440). new NPC Wildkeeper Oraana, named as a new draenei character (lore-fitting,
--   unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: draenei female from Huntress Kima, entry 18416, display 17770, changed hair 5 to 2; a Moongraze fur
--   cloak over the brown hunting mail. Weapons: Exodar Life-Staff.

-- 9300532 Runecarver Iskaar, Runemaster Trainer (guid 9004832): the Enchanting corner by the Lexicon of Power,
--   where runes and inscriptions are taught. Faces 5.391 toward the ring road at (-3862, -11545). new NPC
--   Runecarver Iskaar, named as a new draenei character (lore-fitting, unique) (INFERRED: no cache record). look
--   is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: draenei male from Draenei
--   Cartographer, entry 17600, display 17119, changed hair 1 to 3, facial hair 2 to 4; a ritual amice over the
--   red and white scholar cloth. Weapons: Blessed Axe of the Naaru and a Rune Stone.

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9300514, 'Haraaz Felscar', 'Felsworn Trainer', 930014, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300516, 'Kuraax Stormspeaker', 'Stormbringer Trainer', 930016, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300517, 'Vorathaan Ashmantle', 'Knight of Xoroth Trainer', 930017, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300518, 'Warden Iruvaa', 'Guardian Trainer', 930018, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300519, 'Lightwarden Moraala', 'Templar Trainer', 930019, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300522, 'Archivist Tolaara', 'Chronomancer Trainer', 930022, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300523, 'Soulbinder Kaarun', 'Necromancer Trainer', 930023, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300524, 'Ilaara Cindervow', 'Pyromancer Trainer', 930024, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300525, 'Nyrosha the Veiled', 'Cultist Trainer', 930025, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300526, 'Starseer Naliima', 'Starcaller Trainer', 930026, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300528, 'Technician Draalon', 'Tinker Trainer', 930028, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300530, 'Morvaal the Grim', 'Reaper Trainer', 930030, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300531, 'Wildkeeper Oraana', 'Primalist Trainer', 930031, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300532, 'Runecarver Iskaar', 'Runemaster Trainer', 930032, 60, 60, 0, 1638, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9300514, 9300516, 9300517, 9300518, 9300519, 9300522, 9300523, 9300524, 9300525, 9300526, 9300528, 9300530, 9300531, 9300532);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(9300514, 0, 16125, 1, 1),
(9300516, 0, 16125, 1, 1),
(9300517, 0, 16125, 1, 1),
(9300518, 0, 16126, 1, 1),
(9300519, 0, 16126, 1, 1),
(9300522, 0, 16126, 1, 1),
(9300523, 0, 16125, 1, 1),
(9300524, 0, 16126, 1, 1),
(9300525, 0, 16126, 1, 1),
(9300526, 0, 16126, 1, 1),
(9300528, 0, 16125, 1, 1),
(9300530, 0, 16125, 1, 1),
(9300531, 0, 16126, 1, 1),
(9300532, 0, 16125, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (9300514, 9300516, 9300517, 9300518, 9300519, 9300522, 9300523, 9300524, 9300525, 9300526, 9300528, 9300530, 9300531, 9300532);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(9300514, 16125, 11, 0, 1, 0, 4, 5, 6, 1, 0, 0, 30084, 30080, 0, 30081, 24683, 30082, 0, 24686, 0, 0),
(9300516, 16125, 11, 0, 1, 8, 2, 6, 3, 2, 0, 50217, 49553, 50218, 49536, 50219, 50220, 50221, 49556, 49550, 158684, 0),
(9300517, 16125, 11, 0, 1, 4, 5, 7, 2, 6, 0, 41446, 44725, 0, 44726, 44727, 42304, 41407, 0, 41408, 22808, 0),
(9300518, 16126, 11, 1, 1, 4, 7, 3, 5, 4, 0, 34854, 146450, 30188, 29966, 29967, 29968, 0, 30189, 30190, 0, 0),
(9300519, 16126, 11, 1, 1, 5, 0, 7, 0, 0, 0, 6071, 35241, 37652, 37653, 37654, 35247, 37655, 0, 37656, 0, 0),
(9300522, 16126, 11, 1, 1, 0, 1, 6, 3, 2, 0, 0, 42918, 29704, 42919, 0, 33589, 5566, 0, 0, 0, 0),
(9300523, 16125, 11, 0, 1, 4, 9, 2, 1, 7, 0, 0, 146485, 0, 149343, 151234, 153325, 0, 0, 0, 10717, 0),
(9300524, 16126, 11, 1, 1, 7, 2, 8, 2, 4, 0, 0, 0, 0, 8206, 0, 8064, 28734, 0, 0, 0, 0),
(9300525, 16126, 11, 1, 1, 4, 9, 6, 1, 5, 0, 5861, 146614, 0, 149537, 151386, 153499, 155578, 0, 1752, 0, 0),
(9300526, 16126, 11, 1, 1, 8, 3, 10, 3, 0, 0, 0, 0, 0, 149558, 0, 153527, 0, 0, 0, 0, 0),
(9300528, 16125, 11, 0, 1, 11, 2, 7, 2, 1, 0, 24907, 0, 30184, 0, 30185, 29993, 0, 0, 30231, 0, 0),
(9300530, 16125, 11, 0, 1, 13, 4, 0, 2, 4, 0, 6807, 44256, 0, 44391, 44252, 44254, 44392, 44393, 44253, 49524, 0),
(9300531, 16126, 11, 1, 1, 8, 4, 2, 4, 6, 0, 0, 28673, 27894, 0, 27895, 27901, 0, 0, 27899, 17909, 0),
(9300532, 16125, 11, 0, 1, 1, 0, 3, 2, 4, 0, 0, 2945, 29813, 0, 3531, 8352, 29044, 199, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (9300514, 9300516, 9300517, 9300518, 9300519, 9300522, 9300523, 9300524, 9300525, 9300526, 9300528, 9300530, 9300531, 9300532);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(9300514, 1, 12482, 12482, 0),
(9300516, 1, 37848, 0, 0),
(9300517, 1, 41259, 0, 0),
(9300518, 1, 59043, 31287, 0),
(9300519, 1, 28800, 0, 0),
(9300522, 1, 15041, 0, 0),
(9300523, 1, 31308, 0, 0),
(9300524, 1, 13000, 0, 0),
(9300525, 1, 5112, 4984, 0),
(9300526, 1, 25330, 0, 0),
(9300528, 1, 1911, 0, 17717),
(9300530, 1, 35514, 0, 0),
(9300531, 1, 30732, 0, 0),
(9300532, 1, 34524, 26571, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (9300514, 9300516, 9300517, 9300518, 9300519, 9300522, 9300523, 9300524, 9300525, 9300526, 9300528, 9300530, 9300531, 9300532);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(9300514, 900014),
(9300516, 900016),
(9300517, 900017),
(9300518, 900018),
(9300519, 900019),
(9300522, 900022),
(9300523, 900023),
(9300524, 900024),
(9300525, 900025),
(9300526, 900026),
(9300528, 900028),
(9300530, 900030),
(9300531, 900031),
(9300532, 900032);

-- ---------------------------------------------------------------------------
-- 2. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9004814, 9004816, 9004817, 9004818, 9004819, 9004822, 9004823, 9004824, 9004825, 9004826, 9004828, 9004830, 9004831, 9004832) OR `guid` BETWEEN 9004800 AND 9004899;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004814, 9300514, 530, 0, 0, 1, 1, 1, -4212, -11583, -125.97, 4.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Felsworn trainer (INFERRED hand spot): the Hunters'' Sanctum terrace, 8.7 yd from the sanctum sign: the demon hunter keeps to the hunters'' hall'),
(9004816, 9300516, 530, 0, 0, 1, 1, 1, -3797, -11470, -138.194, 3.514, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Stormbringer trainer (INFERRED hand spot): the Crystal Hall, beside the brazier and the Silvermyst crystal at the east rim of the shaman stones'' pit, the draenei hall of the elements'),
(9004817, 9300517, 530, 0, 0, 1, 1, 1, -4246, -11686, -143.717, 0.927, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Knight of Xoroth trainer (INFERRED hand spot): the Trader''s Tier forge hall, on the open floor between the forges and the Engineering benches'),
(9004818, 9300518, 530, 0, 0, 1, 1, 1, -4174, -11648, -98.496, 0.709, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Guardian trainer (INFERRED hand spot): the rim of the Ring of Arms, the warriors'' sparring ring on the upper tier'),
(9004819, 9300519, 530, 0, 0, 1, 1, 1, -4176.5, -11481.5, -131.298, 0.448, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Templar trainer (INFERRED hand spot): the Vindicators'' Sanctum, beside the hammer table among the armour stands'),
(9004822, 9300522, 530, 0, 0, 1, 1, 1, -4078.5, -11433.5, -141.512, 5.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Chronomancer trainer (INFERRED hand spot): the Vault of Lights, among the holographic emitters that replay the draenei past, 5.9 yd off Audrid''s tour (SmartAI waypoints 18903) and 6.6 yd from its 60 s stop at the emitter'),
(9004823, 9300523, 530, 0, 0, 1, 1, 1, -4002, -11510, -137.377, 5.799, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Necromancer trainer (INFERRED hand spot): outside the Anchorites'' Sanctum, his back to its wall: an Auchenai kept apart from the anchorites'),
(9004824, 9300524, 530, 0, 0, 1, 1, 1, -3833, -11527, -138.833, 3.888, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Pyromancer trainer (INFERRED hand spot): the brazier at the Crystal Hall''s south gate, where the ring road passes between two braziers'),
(9004825, 9300525, 530, 0, 0, 1, 1, 1, -3700, -11540, -130.054, 3.059, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cultist trainer (INFERRED hand spot): the crystal mine, where the Broken miners cut the whispering crystals, far from the halls'),
(9004826, 9300526, 530, 0, 0, 1, 1, 1, -3890, -11631, -137.825, 2.324, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Starcaller trainer (INFERRED hand spot): the rim of the Seat of the Naaru, above the shaft where O''ros, the heart of the ship that crossed the stars, hovers far below'),
(9004828, 9300528, 530, 0, 0, 1, 1, 1, -3958, -11760, -134.53, 1.438, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tinker trainer (INFERRED hand spot): at the Exodar''s power crystals, a dozen yards in front of Artificers Andren and Drenin'),
(9004830, 9300530, 530, 0, 0, 1, 1, 1, -4232, -11805, -132.997, 0.833, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Reaper trainer (INFERRED hand spot): the Trader''s Tier armoury, by the blade shop''s weapon racks'),
(9004831, 9300531, 530, 0, 0, 1, 1, 1, -3852, -11395, -127, 4.332, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Primalist trainer (INFERRED hand spot): the moth keeper''s platform in the Crystal Hall, with Sixx the Moth Keeper and the moths 11-14 yd behind her'),
(9004832, 9300532, 530, 0, 0, 1, 1, 1, -3887, -11514, -136.249, 5.391, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Runemaster trainer (INFERRED hand spot): the Enchanting corner by the Lexicon of Power, where runes and inscriptions are taught');
