-- Conquest of Azeroth class trainers in Silvermoon City: one new blood elf trainer for each of CoA's
-- 16 blood elf classes, spread through the city. No quests; every trainer serves its class kit from
-- migration 05.
--
-- WHERE EACH VALUE COMES FROM
--   classes  the blood elf classes of CoA (RACE-CLASS.md: CharBaseInfo.dbc race 10): Felsworn,
--     Stormbringer, Knight of Xoroth, Guardian, Templar, Bloodmage, Ranger, Chronomancer, Necromancer,
--     Pyromancer, Cultist, Starcaller, Sun Cleric, Tinker, Reaper, Runemaster. SOURCED-CLIENT.
--   positions  INFERRED: CoA had no trainer in Silvermoon, so every spot is hand-chosen for its class
--     in the district or landmark that suits it: the gate, the Walk of Elders crossroads and memorial
--     stones, the Bazaar's magisters and its sealed Dead Scar gate, Murder Row, its courtyard and The
--     Sanctum, the Royal Exchange garden and pool, Farstriders' Square's range and Blood Knight hall,
--     the engineering terrace, the Court of the Sun plaza and the Sunfury Spire. Surveyed with
--     floor-relative surface.py maps (inspect_area cannot see under the city WMO) and the WMOAreaTable
--     district of each floor. z is the surface.floor height on the CoA vmaps. Every spot passes
--     surface.check (no floating, sinking, enclosure, low headroom or steep floor) and lies on a
--     ground polygon of the server navmesh connected to Gatewatcher Aendor at the city gate. Clearance,
--     event spawns included: 6.9 yd or more from every creature and 5.4 yd or more from every object
--     except two Lunar Festival objects beside the Guardian (a lantern 3.3 yd and a cluster launcher
--     5.1 yd away); 11 yd or more from every kept stock
--     class trainer; the trainers stand 39 yd or more apart. No patrol passes a trainer: every
--     waypoint_data and SmartAI waypoint leg, each formation escort at its own offset and every
--     wanderer keeps 2 yd or more (walker radius + trainer radius + 1 yd for large walkers) at the
--     same level; the brooms, Champion Vranesh, Ambassador Kelemar and his escort, the Arcane Guardians
--     and the Call to Arms envoys (game events 18-21, 53, 54) walk the streets (--check DB).
--   facing  toward the way players arrive: the navmesh route from the city gate, named per trainer; no
--     wall within 3 yd in that direction.
--   looks  stand-ins: no SMSG_MIRRORIMAGE_DATA capture of these new characters exists. Each copies the
--     CreatureDisplayInfoExtra look of a stock blood elf NPC that fits the class and changes hair,
--     face or armour so that no two trainers look alike; creature_display_preset carries race 10,
--     the sex, the customization and 11 ItemDisplayInfo ids, and creature_template_model the plain
--     blood elf display (15476 male, 15475 female). Every look passes ct_common.check_look.
--   weapons  Item.dbc items the core accepts in each hand (ct_common.equip_row).
--   template  ct_common.trainer_template: level 60, Silvermoon faction 1604, npcflag 49 (gossip,
--     trainer, class trainer; no quests), the class menu 930000 + class and trainer 900000 + class.
--   names  new blood elf characters (INFERRED), unique in creature_template and the CoA creature cache.
-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------

-- 9300564 Veyrin Felshroud, Felsworn Trainer (guid 9004914): The Sanctum, the warlocks' hall under Murder Row:
--   the east study among the spiral bookshelf and the smoking vials, 11 yd or more from the warlocks around the
--   summoning pit. Faces 5.750 toward the hall's north-east way in at (9806, -7321), the navmesh route from the
--   city gate. new NPC Veyrin Felshroud, named as a new blood elf character (lore-fitting, unique) (INFERRED: no
--   cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male
--   from Sunfury Captain 19453, display 19489, changed hair 4 to 9, colour 8 to 1, face 7 to 3, facial hair 8 to
--   2; the Blood Knight tabard removed from the red Sunfury plate of Kael'thas's fel-sworn host. Weapons: Talon
--   of the Phoenix and Claw of the Phoenix.

-- 9300566 Ilythara Skyrender, Stormbringer Trainer (guid 9004916): the east part of the garden plaza of the
--   Royal Exchange, before the auction house, the widest open square under the sky, 3.4 yd clear of the Arcane
--   Guardian patrolling across it. Faces 2.800 toward the plaza entrance from the Walk of Elders side at (9666,
--   -7457). new NPC Ilythara Skyrender, named as a new blood elf character (lore-fitting, unique) (INFERRED: no
--   cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf female
--   from Astromancer Lord 20046, display 19424, changed hair 7 to 12, colour 0 to 8, face 4 to 2; the gloves
--   removed from the blue astromancer robe, bare hands to call the lightning. Weapons: Stormstrike Mace and
--   Stormbound Tome.

-- 9300567 Tarenar Blackflame, Knight of Xoroth Trainer (guid 9004917): Murder Row, the upper street above The
--   Sanctum, among the city's shadier trades: its west edge beside the wagon, off the middle of the street that
--   the broom sweeps and the ambassador's party walks. Faces 3.900 toward the street running up from the
--   courtyard stairs at (9749, -7307). new NPC Tarenar Blackflame, named as a new blood elf character (lore-
--   fitting, unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf male from Baron Sliver 29804, display 28099, changed hair 11 to 15, colour 6 to 0,
--   face 2 to 7; the black cape swapped for a crimson one over the black Northrend plate, a knight of the fire
--   world Xoroth. Weapons: Felsteel Reaper.

-- 9300568 Lorthiel Brightward, Guardian Trainer (guid 9004918): just inside the city gate on the Walk of Elders,
--   across the passage from Gatewatcher Aendor, the city's defender at its door. Faces 2.900 toward the gate and
--   the bridge from Eversong Woods at (9440, -7279). new NPC Lorthiel Brightward, named as a new blood elf
--   character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA
--   capture of this trainer exists: blood elf female from Sunhawk Defender 17607, display 17366, changed hair 3
--   to 9, colour 2 to 4, face 5 to 1; plate pauldrons and a cape added to the red Sunhawk plate, a shield-
--   bearing defender. Weapons: Sunwell Blade and Silvermoon Crest Shield.

-- 9300569 Kaeleth Dawnbrand, Templar Trainer (guid 9004919): the Blood Knights' hall off Farstriders' Square,
--   beside the aisle before the south bench, 5 yd clear of Champion Vranesh's walk up the aisle and 14 yd or
--   more from the knights, initiates and door guards. Faces 1.200 toward the hall door at (9851, -7477) where
--   the two guardians stand. new NPC Kaeleth Dawnbrand, named as a new blood elf character (lore-fitting,
--   unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf male from Blood Knight Honor Guard 23131, display 23003, changed hair 10 to 3, colour 0 to
--   2, face 8 to 1, facial hair 9 to 0; the Blood Knight helm removed from the bright plate, tabard and cape
--   kept. Weapons: Blood Knight Maul.

-- 9300570 Velanna Redthorn, Bloodmage Trainer (guid 9004920): the magisters' square in the Bazaar, 12 yd or more
--   from the magisters and citizens gathered for the summoning ritual. Faces 4.750 toward the square entrance
--   from the Bazaar at (9541, -7125). new NPC Velanna Redthorn, named as a new blood elf character (lore-
--   fitting, unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf female from Bloodmage 19258, display 18677, changed hair 3 to 16, colour 3 to 5,
--   face 4 to 6; the magic hat removed and black bracers added to the red and black bloodmage robe. Weapons:
--   Scryer's Blade of Focus and Sanguine Star.

-- 9300571 Nyssa Swiftbough, Ranger Trainer (guid 9004921): the archery range of Farstriders' Square, inside the
--   gap in the range fence, 7 yd from the practising Silvermoon Rangers. Faces 4.930 toward the gap in the range
--   fence at (9847, -7411), where players come in from the square's west walk. new NPC Nyssa Swiftbough, named
--   as a new blood elf character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf female from Eversong Ranger 15938, display
--   17266, changed hair 6 to 2, colour 5 to 7, face 1 to 3; a Farstrider cloak added to the green ranger
--   leathers. Weapons: Dawnblade and Golden Bow of Quel'Thalas.

-- 9300572 Aeduin Hourward, Chronomancer Trainer (guid 9004922): the crossroads of the Walk of Elders, where the
--   elders' avenue meets the ways to the Bazaar and Murder Row. Faces 3.150 toward the avenue coming up from the
--   gate at (9655, -7262). new NPC Aeduin Hourward, named as a new blood elf character (lore-fitting, unique)
--   (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   blood elf male from Magister Sylastor 16237, display 16083, changed hair 2 to 8, colour 6 to 3, face 0 to 4;
--   a gold mantle (5872) added to the gold magister robe, sand and gold tones for a keeper of time. Weapons:
--   Staff of Infinite Mysteries.

-- 9300573 Velrith Scarwatch, Necromancer Trainer (guid 9004923): the sealed Dead Scar gate at the west end of
--   the Bazaar, between the two gate guardians, the Scar the Scourge cut through the city behind him. Faces
--   3.780 toward the Bazaar plaza in front of the gate at (9684, -7075). new NPC Velrith Scarwatch, named as a
--   new blood elf character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male from Tel'athion the Impure 17359,
--   display 16983, changed skin 1 to 16 (ashen), face 1 to 4, hair 5 to 13, colour 1 to 9; a black warlock hood
--   over the black robe, a stern student of the Scourge. Weapons: The Undeath Carrier.

-- 9300574 Ilsara Flamecrest, Pyromancer Trainer (guid 9004924): the south-east end of the Royal Exchange pool
--   walk, below the corner brazier, the pool and its golden statues ahead of her, at the walk's south edge off
--   the way the guards and envoys patrol. Faces 1.000 toward the pool walk from the Royal Exchange street, the
--   navmesh route passing (9766.5, -7428). new NPC Ilsara Flamecrest, named as a new blood elf character (lore-
--   fitting, unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf female from Astromancer 20033, display 19391, changed hair 10 to 4, colour 6 to 7,
--   face 7 to 2; a flame-licked circlet over the orange astromancer robe. Weapons: Bloodfire Greatstaff.

-- 9300575 Nerethil Voidwhisper, Cultist Trainer (guid 9004925): the south-west corner of the courtyard below
--   Murder Row by the inn, between the raised west walk and the south platform, out of sight of the street above
--   and off the broom's sweep. Faces 0.020 toward the navmesh route down the steps of the raised west walk,
--   reaching the courtyard floor at (9673.3, -7332.8). new NPC Nerethil Voidwhisper, named as a new blood elf
--   character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA
--   capture of this trainer exists: blood elf male from Sunfury Summoner 21505, display 20339, changed face 0 to
--   6, hair 4 to 12, colour 2 to 0, facial hair 7 to 3; a crimson hood and a black sash added to the dark
--   summoner robe. Weapons: Ritualistic Athame and Demon-Skull Orb.

-- 9300576 Caleste Nightglow, Starcaller Trainer (guid 9004926): the open upper plaza of the Court of the Sun, by
--   the west planters under the open sky. Faces 3.700 toward the plaza coming up from its south-west end at
--   (9970, -7196). new NPC Caleste Nightglow, named as a new blood elf character (lore-fitting, unique)
--   (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   blood elf female from Star Scryer 20034, display 19393, changed hair 13 to 17, colour 5 to 2, face 2 to 8; a
--   silver circlet in place of the cape over the purple star scryer robe. Weapons: Dagger of the Rising Moon and
--   Book of Stars.

-- 9300577 Liraen Dawnlight, Sun Cleric Trainer (guid 9004927): the priests' room of the Sunfury Spire, north of
--   the golden statue, 16 yd or more from the three priests. Faces 5.120 toward the Spire ring's north arc at
--   (9951, -7070), coming round from the ramp. new NPC Liraen Dawnlight, named as a new blood elf character
--   (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of
--   this trainer exists: blood elf female from Solarium Priest 18806, display 19050, changed hair 8 to 5, colour
--   2 to 9, face 4 to 1; a gold circlet in place of the raid priest's helm over the cream solarium vestments.
--   Weapons: Rod of the Sun King and Talisman of the Sun King.

-- 9300578 Keldan Sparkwright, Tinker Trainer (guid 9004928): the engineering terrace, 10-13 yd from Danwe,
--   Gloresse and Yatheon and their anvil. Faces 0.500 toward the terrace gap from the Court of the Sun lower
--   plaza at (9845, -7317). new NPC Keldan Sparkwright, named as a new blood elf character (lore-fitting,
--   unique) (INFERRED: no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf male from Sunfury Technician 20218, display 19515, changed hair 6 to 1, colour 5 to 6,
--   face 5 to 2, facial hair 5 to 1; black work gloves added under the goggles and black technician cloth.
--   Weapons: Hammer of Wrenching Change, Tork Wrench and Bloodwarder's Rifle.

-- 9300580 Dathren Duskmourn, Reaper Trainer (guid 9004930): the memorial stones of the Walk of Elders, before
--   the monument to the fallen. Faces 1.850 toward the gate plaza at (9504, -7381). new NPC Dathren Duskmourn,
--   named as a new blood elf character (lore-fitting, unique) (INFERRED: no cache record). look is a stand-in,
--   no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male from Ebon Blade Reaper 31316,
--   display 27564, changed hair 13 to 3, colour 11 to 2, face 7 to 4; a black hood in place of the cape over the
--   violet death plate, a hooded reaper. Weapons: Grim Scythe.

-- 9300582 Ithrien Glyphwarden, Runemaster Trainer (guid 9004932): in front of the enchanting and inscription
--   shop on the upper plaza of the Court of the Sun. Faces 3.220 toward the plaza from the south-west at (9925,
--   -7217.5). new NPC Ithrien Glyphwarden, named as a new blood elf character (lore-fitting, unique) (INFERRED:
--   no cache record). look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf
--   female from Solarium Agent 18925, display 19048, changed skin 0 to 2, face 0 to 5, hair 0 to 14, colour 9 to
--   3; the leather helm removed and crimson mail pauldrons added to the black leathers. Weapons: Rune-Etched
--   Nightblade and Rune Stone.

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9300564, 'Veyrin Felshroud', 'Felsworn Trainer', 930014, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300566, 'Ilythara Skyrender', 'Stormbringer Trainer', 930016, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300567, 'Tarenar Blackflame', 'Knight of Xoroth Trainer', 930017, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300568, 'Lorthiel Brightward', 'Guardian Trainer', 930018, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300569, 'Kaeleth Dawnbrand', 'Templar Trainer', 930019, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300570, 'Velanna Redthorn', 'Bloodmage Trainer', 930020, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300571, 'Nyssa Swiftbough', 'Ranger Trainer', 930021, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300572, 'Aeduin Hourward', 'Chronomancer Trainer', 930022, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300573, 'Velrith Scarwatch', 'Necromancer Trainer', 930023, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300574, 'Ilsara Flamecrest', 'Pyromancer Trainer', 930024, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300575, 'Nerethil Voidwhisper', 'Cultist Trainer', 930025, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300576, 'Caleste Nightglow', 'Starcaller Trainer', 930026, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300577, 'Liraen Dawnlight', 'Sun Cleric Trainer', 930027, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300578, 'Keldan Sparkwright', 'Tinker Trainer', 930028, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300580, 'Dathren Duskmourn', 'Reaper Trainer', 930030, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300582, 'Ithrien Glyphwarden', 'Runemaster Trainer', 930032, 60, 60, 0, 1604, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9300564, 9300566, 9300567, 9300568, 9300569, 9300570, 9300571, 9300572, 9300573, 9300574, 9300575, 9300576, 9300577, 9300578, 9300580, 9300582);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(9300564, 0, 15476, 1, 1),
(9300566, 0, 15475, 1, 1),
(9300567, 0, 15476, 1, 1),
(9300568, 0, 15475, 1, 1),
(9300569, 0, 15476, 1, 1),
(9300570, 0, 15475, 1, 1),
(9300571, 0, 15475, 1, 1),
(9300572, 0, 15476, 1, 1),
(9300573, 0, 15476, 1, 1),
(9300574, 0, 15475, 1, 1),
(9300575, 0, 15476, 1, 1),
(9300576, 0, 15475, 1, 1),
(9300577, 0, 15475, 1, 1),
(9300578, 0, 15476, 1, 1),
(9300580, 0, 15476, 1, 1),
(9300582, 0, 15475, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (9300564, 9300566, 9300567, 9300568, 9300569, 9300570, 9300571, 9300572, 9300573, 9300574, 9300575, 9300576, 9300577, 9300578, 9300580, 9300582);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(9300564, 15476, 10, 0, 1, 2, 3, 9, 1, 2, 0, 0, 146593, 148098, 149499, 151349, 153458, 24288, 156541, 24289, 158669, 0),
(9300566, 15475, 10, 1, 1, 0, 2, 12, 8, 8, 0, 0, 146581, 0, 37384, 151329, 153439, 155516, 0, 0, 0, 0),
(9300567, 15476, 10, 0, 1, 18, 7, 15, 0, 0, 0, 0, 42664, 0, 42048, 41405, 44380, 41448, 0, 41449, 158669, 0),
(9300568, 15475, 10, 1, 1, 3, 1, 9, 4, 0, 0, 0, 146593, 148033, 149259, 151158, 153238, 155364, 0, 157681, 33619, 0),
(9300569, 15476, 10, 0, 1, 0, 1, 3, 2, 0, 0, 0, 33294, 33295, 33296, 16664, 34260, 33298, 0, 33299, 33619, 30597),
(9300570, 15475, 10, 1, 1, 4, 6, 16, 5, 4, 0, 0, 6079, 0, 16572, 6076, 6199, 31655, 156541, 0, 0, 0),
(9300571, 15475, 10, 1, 1, 1, 3, 2, 7, 0, 0, 0, 0, 0, 26653, 26661, 26652, 26651, 0, 26679, 27021, 0),
(9300572, 15476, 10, 0, 1, 5, 4, 8, 3, 0, 0, 0, 5872, 0, 30009, 26689, 29559, 12558, 0, 0, 0, 0),
(9300573, 15476, 10, 0, 1, 16, 4, 13, 9, 0, 0, 61247, 0, 0, 164970, 164971, 29684, 164973, 0, 0, 0, 0),
(9300574, 15475, 10, 1, 1, 6, 2, 4, 7, 3, 0, 17094, 146580, 0, 37367, 151327, 153437, 155514, 0, 0, 0, 0),
(9300575, 15476, 10, 0, 1, 5, 6, 12, 0, 3, 0, 12532, 0, 0, 149443, 29683, 19934, 155494, 0, 0, 0, 0),
(9300576, 15475, 10, 1, 1, 1, 8, 17, 2, 5, 0, 62885, 146582, 0, 37371, 151331, 153441, 155518, 0, 0, 0, 0),
(9300577, 15475, 10, 1, 1, 7, 1, 5, 9, 2, 0, 24533, 146557, 0, 25813, 0, 25815, 155482, 0, 0, 0, 0),
(9300578, 15476, 10, 0, 1, 8, 2, 1, 6, 1, 0, 17399, 0, 0, 33478, 29663, 31556, 30155, 31381, 30737, 0, 0),
(9300580, 15476, 10, 0, 1, 17, 4, 3, 2, 0, 0, 28636, 47714, 47715, 47716, 47717, 47718, 47719, 47720, 47721, 0, 0),
(9300582, 15475, 10, 1, 1, 2, 5, 14, 3, 0, 0, 0, 29661, 32607, 30888, 31225, 31555, 30738, 0, 30737, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (9300564, 9300566, 9300567, 9300568, 9300569, 9300570, 9300571, 9300572, 9300573, 9300574, 9300575, 9300576, 9300577, 9300578, 9300580, 9300582);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(9300564, 1, 32944, 29948, 0),
(9300566, 1, 43407, 43663, 0),
(9300567, 1, 23543, 0, 0),
(9300568, 1, 22783, 27910, 0),
(9300569, 1, 25138, 0, 0),
(9300570, 1, 34895, 15947, 0),
(9300571, 1, 22984, 0, 34196),
(9300572, 1, 28633, 0, 0),
(9300573, 1, 40233, 0, 0),
(9300574, 1, 28188, 0, 0),
(9300575, 1, 37037, 36461, 0),
(9300576, 1, 45077, 43661, 0),
(9300577, 1, 29996, 29923, 0),
(9300578, 1, 44747, 11855, 31000),
(9300580, 1, 25236, 0, 0),
(9300582, 1, 45331, 26569, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (9300564, 9300566, 9300567, 9300568, 9300569, 9300570, 9300571, 9300572, 9300573, 9300574, 9300575, 9300576, 9300577, 9300578, 9300580, 9300582);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(9300564, 900014),
(9300566, 900016),
(9300567, 900017),
(9300568, 900018),
(9300569, 900019),
(9300570, 900020),
(9300571, 900021),
(9300572, 900022),
(9300573, 900023),
(9300574, 900024),
(9300575, 900025),
(9300576, 900026),
(9300577, 900027),
(9300578, 900028),
(9300580, 900030),
(9300582, 900032);

-- ---------------------------------------------------------------------------
-- 2. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9004914, 9004916, 9004917, 9004918, 9004919, 9004920, 9004921, 9004922, 9004923, 9004924, 9004925, 9004926, 9004927, 9004928, 9004930, 9004932) OR `guid` BETWEEN 9004900 AND 9004999;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004914, 9300564, 530, 0, 0, 1, 1, 1, 9795.5, -7315, 14.693, 5.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Felsworn trainer (INFERRED hand spot): The Sanctum, the warlocks'' hall under Murder Row: the east study among the spiral bookshelf and the smoking vials, 11 yd or more from the warlocks around the summoning pit'),
(9004916, 9300566, 530, 0, 0, 1, 1, 1, 9685, -7463.5, 13.565, 2.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Stormbringer trainer (INFERRED hand spot): the east part of the garden plaza of the Royal Exchange, before the auction house, the widest open square under the sky, 3.4 yd clear of the Arcane Guardian patrolling across it'),
(9004917, 9300567, 530, 0, 0, 1, 1, 1, 9769, -7288, 24.773, 3.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Knight of Xoroth trainer (INFERRED hand spot): Murder Row, the upper street above The Sanctum, among the city''s shadier trades: its west edge beside the wagon, off the middle of the street that the broom sweeps and the ambassador''s party walks'),
(9004918, 9300568, 530, 0, 0, 1, 1, 1, 9473.5, -7285.5, 14.235, 2.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Guardian trainer (INFERRED hand spot): just inside the city gate on the Walk of Elders, across the passage from Gatewatcher Aendor, the city''s defender at its door'),
(9004919, 9300569, 530, 0, 0, 1, 1, 1, 9846, -7490, 14.927, 1.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Templar trainer (INFERRED hand spot): the Blood Knights'' hall off Farstriders'' Square, beside the aisle before the south bench, 5 yd clear of Champion Vranesh''s walk up the aisle and 14 yd or more from the knights, initiates and door guards'),
(9004920, 9300570, 530, 0, 0, 1, 1, 1, 9540, -7102, 14.409, 4.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Bloodmage trainer (INFERRED hand spot): the magisters'' square in the Bazaar, 12 yd or more from the magisters and citizens gathered for the summoning ritual'),
(9004921, 9300571, 530, 0, 0, 1, 1, 1, 9846, -7406.5, 13.631, 4.93, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ranger trainer (INFERRED hand spot): the archery range of Farstriders'' Square, inside the gap in the range fence, 7 yd from the practising Silvermoon Rangers'),
(9004922, 9300572, 530, 0, 0, 1, 1, 1, 9672, -7262, 13.894, 3.15, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Chronomancer trainer (INFERRED hand spot): the crossroads of the Walk of Elders, where the elders'' avenue meets the ways to the Bazaar and Murder Row'),
(9004923, 9300573, 530, 0, 0, 1, 1, 1, 9702, -7061.5, 14.038, 3.78, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Necromancer trainer (INFERRED hand spot): the sealed Dead Scar gate at the west end of the Bazaar, between the two gate guardians, the Scar the Scourge cut through the city behind him'),
(9004924, 9300574, 530, 0, 0, 1, 1, 1, 9762.8, -7434, 13.386, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Pyromancer trainer (INFERRED hand spot): the south-east end of the Royal Exchange pool walk, below the corner brazier, the pool and its golden statues ahead of her, at the walk''s south edge off the way the guards and envoys patrol'),
(9004925, 9300575, 530, 0, 0, 1, 1, 1, 9662.5, -7333, 11.757, 0.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cultist trainer (INFERRED hand spot): the south-west corner of the courtyard below Murder Row by the inn, between the raised west walk and the south platform, out of sight of the street above and off the broom''s sweep'),
(9004926, 9300576, 530, 0, 0, 1, 1, 1, 9980, -7190, 30.878, 3.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Starcaller trainer (INFERRED hand spot): the open upper plaza of the Court of the Sun, by the west planters under the open sky'),
(9004927, 9300577, 530, 0, 0, 1, 1, 1, 9946, -7058, 47.715, 5.12, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sun Cleric trainer (INFERRED hand spot): the priests'' room of the Sunfury Spire, north of the golden statue, 16 yd or more from the three priests'),
(9004928, 9300578, 530, 0, 0, 1, 1, 1, 9832, -7324, 26.282, 0.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tinker trainer (INFERRED hand spot): the engineering terrace, 10-13 yd from Danwe, Gloresse and Yatheon and their anvil'),
(9004930, 9300580, 530, 0, 0, 1, 1, 1, 9510, -7397, 14.317, 1.85, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Reaper trainer (INFERRED hand spot): the memorial stones of the Walk of Elders, before the monument to the fallen'),
(9004932, 9300582, 530, 0, 0, 1, 1, 1, 9950, -7215.5, 30.867, 3.22, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Runemaster trainer (INFERRED hand spot): in front of the enchanting and inscription shop on the upper plaza of the Court of the Sun');
