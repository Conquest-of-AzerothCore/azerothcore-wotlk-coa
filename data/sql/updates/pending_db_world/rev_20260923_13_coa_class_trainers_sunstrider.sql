-- Conquest of Azeroth class trainers on Sunstrider Isle (blood elf start): 16 new trainers, one for each
-- class CoA offered blood elves (CharBaseInfo.dbc; research/class-trainers/RACE-CLASS.md), and their
-- intro letters from Magistrix Erona. CoA had no class trainer or class quest on the isle, so every
-- name, spot, look and letter here is INFERRED; the trainer kits (spells, menus, texts) are the class
-- kits of migration 05.
--
-- WHERE EACH VALUE COMES FROM
--   spots  hand-placed after inspect_area.py, surface.check and a wall-ray survey of each spot, z from
--     surface.floor (map 530 CoA data equals stock here). Every spot is at least 15 yd from the next
--     trainer, no trainer has more than two others within 30 yd, and none stands within 12 yd of a
--     hostile spawn. The stock class trainers of the Sunspire keep their posts, so the three hall
--     trainers take free spots in the hall. The
--     never-running Arena Tournament (game_event 31) pedestals are kept 1.5 yd clear.
--   facings  toward the way players arrive (the landing, the hall door, the ramp top, the road).
--   looks  creature_display_preset stand-ins (no SMSG_MIRRORIMAGE_DATA capture of any CoA trainer
--     exists): the CreatureDisplayInfoExtra look of a stock blood elf NPC of the right sex and theme
--     (research/class-trainers/plan/newzone_picks.csv), with face, hair, colour and one or two pieces
--     changed so that no two trainers look alike; NPC-only skins are replaced with player skins so the
--     mirror image composes (ct_common.check_look). The model is the plain blood elf display 15476/15475.
--   weapons  creature_equip_template from the same csv (Item.dbc inventory types checked).
--   letters  one per class, modelled on that class's CoA Deathknell letter (53000-53014, 53201): the
--     same quest sort, level 2, XP difficulty, letter display, flags and binding; the text is adapted to
--     the trainer, the landmark and Quel'Thalas. Erona 15278 offers them after Reclaiming Sunstrider
--     Isle (8325), as she does the stock "<Class> Training" quests; AllowableRaces 512 (blood elf) and
--     the class bit; the letter is the provided start item and the only required item. The trainer
--     ends the quest. Page texts and turn-in texts are written in the trainer's voice.
--
-- Id blocks: creature guid 9004400 + class (block 9004400-9004499), creature_template 9300450 + class,
-- quest and letter item 9302100 + class, page_text 931100 + class.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
-- 9300464 Seldrath Duskblind, Felsworn Trainer: new NPC Seldrath Duskblind, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf male from Varedis 21178 (display 20130, blindfolded Illidari), changed face 9 to
--   5, hair colour 0 to 7; the blindfold stays (Duskblind); weapons 30208/30209/0.
-- 9300466 Aerisa Stormlace, Stormbringer Trainer: new NPC Aerisa Stormlace, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf female from Aurora Skycaller 10304 (display 18910, cyan robes), changed NPC-only
--   skin 14 to 2, face 0 to 6, hair colour 0 to 3, a cyan mage cape (11508) added; weapons 43220/0/0.
-- 9300467 Dravinor Ashbrand, Knight of Xoroth Trainer: new NPC Dravinor Ashbrand, named as a new blood elf
--   character for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of
--   this trainer exists: blood elf male from Illidari Soldier 22075 (display 20778, dark plate), changed face 2
--   to 4, hair 10 to 12, hair colour 3 to 8; weapons 38707/0/0.
-- 9300468 Therandis Sunshield, Guardian Trainer: new NPC Therandis Sunshield, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf male from Horde Halaani Guard 18192 (display 18258, Blood Knight plate), changed
--   skin 2 to 6, face 3 to 7 (the helm keeps the hair hidden); weapons 27405/27406/0.
-- 9300469 Aeloris Lightbrand, Templar Trainer: new NPC Aeloris Lightbrand, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf male from Champion Lightrend 17810 (display 17259, holy plate), changed hair 6 to
--   3, hair colour 4 to 1; weapons 24034/24038/0.
-- 9300470 Sanreia Crimsonvein, Bloodmage Trainer: new NPC Sanreia Crimsonvein, named as a new blood elf
--   character for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of
--   this trainer exists: blood elf female from Bloodmage Laurith 25381 (display 23169, Sunwell robes), changed
--   skin 0 to 5, hair 2 to 9, hair colour 4 to 7; weapons 31609/19366/0.
-- 9300471 Lyssia Leafstride, Ranger Trainer: new NPC Lyssia Leafstride, named as a new blood elf character for
--   the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf female from Ranger Valanna 16219 (display 16069, Farstrider leathers), changed skin 5 to
--   3, face 9 to 3, hair 0 to 5; weapons 12993/0/30390.
-- 9300472 Taelenna Sandweaver, Chronomancer Trainer: new NPC Taelenna Sandweaver, named as a new blood elf
--   character for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of
--   this trainer exists: blood elf female from Custodian of Time 19950 (display 19282, white robes), changed
--   NPC-only skin 14 to 7, hair colour 1 to 4, a gold robe belt (8507) and a golden cape (17876) for the bronze
--   dragonflight; weapons 30424/0/0.
-- 9300473 Morthalis Gravewhisper, Necromancer Trainer: new NPC Morthalis Gravewhisper, named as a new blood elf
--   character for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of
--   this trainer exists: blood elf male from Shadowy Summoner 17088 (display 17988, hooded Shadow Council
--   robes), changed skin 5 to 8, face 7 to 1, hair colour 3 to 6, a black mage cape (11726) added; weapons
--   41342/0/0.
-- 9300474 Caelor Emberhand, Pyromancer Trainer: new NPC Caelor Emberhand, named as a new blood elf character for
--   the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf male from Magister Jaronis 15418 (display 15912, red robes), changed skin 0 to 1, face 0
--   to 3, hair 0 to 4, hair colour 0 to 2, a red mage cape (10721) added, the source's model-less mantle 26659
--   swapped for 2178 (same red robe texture on its model); weapons 11343/0/0.
-- 9300475 Zaelith Shadowmoor, Cultist Trainer: new NPC Zaelith Shadowmoor, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf male from Twilight Firesworn 25863 (display 23450, Twilight's Hammer robes),
--   changed face 6 to 2, hair 0 to 9, hair colour 3 to 5, Twilight's Hammer robe legs (10390) instead of the red
--   pair Caelor wears; weapons 34880/34881/0.
-- 9300476 Isolen Starweaver, Starcaller Trainer: new NPC Isolen Starweaver, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf female from Magistrix Fyalenn 18531 (display 17878, magister hat and robes),
--   changed hair 7 to 11, hair colour 9 to 5, a yellow robe belt (5218) instead of the black one Brelan wears;
--   weapons 31608/0/0.
-- 9300477 Saleria Sunvow, Sun Cleric Trainer: new NPC Saleria Sunvow, named as a new blood elf character for the
--   isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf female from Viera Sunwhisper 17226 (display 16926, red dress and gold circlet), changed
--   face 1 to 5, hair 2 to 13, hair colour 0 to 1, earrings 0 to 1, a gold belt (5922) instead of the purple one
--   Quelnar wears; weapons 28738/0/0.
-- 9300478 Brelan Arcspindle, Tinker Trainer: new NPC Brelan Arcspindle, named as a new blood elf character for
--   the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf female from Engineer Sinbei 33634 (display 28791, goggles and work leathers), changed skin
--   2 to 0, face 1 to 7, hair 6 to 14, hair colour 5 to 2; weapons 1911/0/24244.
-- 9300480 Solwyn Ashenveil, Reaper Trainer: new NPC Solwyn Ashenveil, named as a new blood elf character for the
--   isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf female from DK (Blood Elf Female) 28434 (display 25432, Acherus plate), changed NPC-only
--   skin 15 to 8, face 0 to 4, hair colour 0 to 9 (the helm hides the hair); weapons 36611/0/0.
-- 9300482 Quelnar Runescribe, Runemaster Trainer: new NPC Quelnar Runescribe, named as a new blood elf character
--   for the isle (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: blood elf male from Ley-Keeper Caidanis 15405 (display 15909, purple blood robes), changed
--   skin 0 to 2, face 2 to 8, hair 1 to 5, hair colour 2 to 6, earrings 0 to 3; weapons 5304/0/0.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9300464, 'Seldrath Duskblind', 'Felsworn Trainer', 930014, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300466, 'Aerisa Stormlace', 'Stormbringer Trainer', 930016, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300467, 'Dravinor Ashbrand', 'Knight of Xoroth Trainer', 930017, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300468, 'Therandis Sunshield', 'Guardian Trainer', 930018, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300469, 'Aeloris Lightbrand', 'Templar Trainer', 930019, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300470, 'Sanreia Crimsonvein', 'Bloodmage Trainer', 930020, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300471, 'Lyssia Leafstride', 'Ranger Trainer', 930021, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300472, 'Taelenna Sandweaver', 'Chronomancer Trainer', 930022, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300473, 'Morthalis Gravewhisper', 'Necromancer Trainer', 930023, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300474, 'Caelor Emberhand', 'Pyromancer Trainer', 930024, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300475, 'Zaelith Shadowmoor', 'Cultist Trainer', 930025, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300476, 'Isolen Starweaver', 'Starcaller Trainer', 930026, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300477, 'Saleria Sunvow', 'Sun Cleric Trainer', 930027, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300478, 'Brelan Arcspindle', 'Tinker Trainer', 930028, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300480, 'Solwyn Ashenveil', 'Reaper Trainer', 930030, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300482, 'Quelnar Runescribe', 'Runemaster Trainer', 930032, 10, 10, 0, 1604, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9300464, 9300466, 9300467, 9300468, 9300469, 9300470, 9300471, 9300472, 9300473, 9300474, 9300475, 9300476, 9300477, 9300478, 9300480, 9300482);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(9300464, 0, 15476, 1, 1),
(9300466, 0, 15475, 1, 1),
(9300467, 0, 15476, 1, 1),
(9300468, 0, 15476, 1, 1),
(9300469, 0, 15476, 1, 1),
(9300470, 0, 15475, 1, 1),
(9300471, 0, 15475, 1, 1),
(9300472, 0, 15475, 1, 1),
(9300473, 0, 15476, 1, 1),
(9300474, 0, 15476, 1, 1),
(9300475, 0, 15476, 1, 1),
(9300476, 0, 15475, 1, 1),
(9300477, 0, 15475, 1, 1),
(9300478, 0, 15475, 1, 1),
(9300480, 0, 15475, 1, 1),
(9300482, 0, 15476, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (9300464, 9300466, 9300467, 9300468, 9300469, 9300470, 9300471, 9300472, 9300473, 9300474, 9300475, 9300476, 9300477, 9300478, 9300480, 9300482);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(9300464, 15476, 10, 0, 1, 3, 5, 8, 7, 2, 0, 145536, 0, 0, 149528, 151378, 153490, 155569, 156555, 0, 0, 0),
(9300466, 15475, 10, 1, 1, 2, 6, 7, 3, 5, 0, 0, 0, 0, 14266, 0, 14267, 13165, 0, 0, 11508, 0),
(9300467, 15476, 10, 0, 1, 4, 4, 12, 8, 1, 0, 0, 35458, 35345, 36862, 36863, 36864, 36865, 0, 36866, 0, 36786),
(9300468, 15476, 10, 0, 1, 6, 7, 10, 2, 0, 0, 31310, 164733, 164732, 164731, 164734, 31216, 164736, 0, 164737, 164739, 30597),
(9300469, 15476, 10, 0, 1, 9, 8, 3, 1, 0, 0, 0, 12364, 0, 29512, 16664, 24753, 12367, 0, 18629, 0, 30537),
(9300470, 15475, 10, 1, 1, 5, 2, 9, 7, 2, 0, 0, 0, 0, 41111, 41112, 41113, 41114, 0, 0, 20585, 40869),
(9300471, 15475, 10, 1, 1, 3, 3, 5, 2, 0, 0, 0, 0, 29172, 29173, 26678, 26652, 26650, 0, 6204, 0, 0),
(9300472, 15475, 10, 1, 1, 7, 1, 3, 4, 2, 0, 0, 0, 29704, 0, 8507, 20046, 5566, 0, 0, 17876, 0),
(9300473, 15476, 10, 0, 1, 8, 1, 0, 6, 0, 0, 13168, 146475, 0, 13566, 0, 153311, 155409, 156497, 0, 11726, 0),
(9300474, 15476, 10, 0, 1, 1, 3, 4, 2, 0, 0, 0, 2178, 3272, 0, 0, 3274, 5385, 0, 0, 10721, 0),
(9300475, 15476, 10, 0, 1, 5, 2, 9, 5, 6, 0, 145649, 0, 148262, 149762, 151647, 10390, 155828, 0, 158029, 0, 0),
(9300476, 15475, 10, 1, 1, 0, 4, 11, 5, 0, 0, 24853, 26403, 30867, 0, 5218, 30747, 30748, 0, 0, 0, 0),
(9300477, 15475, 10, 1, 1, 1, 5, 13, 1, 1, 0, 5409, 0, 0, 27290, 5922, 7229, 7042, 0, 0, 0, 0),
(9300478, 15475, 10, 1, 1, 0, 7, 14, 2, 6, 0, 37925, 0, 0, 30843, 29683, 31555, 30738, 0, 30900, 0, 36119),
(9300480, 15475, 10, 1, 1, 8, 4, 0, 9, 0, 0, 44238, 44227, 0, 44247, 44236, 44230, 44231, 0, 44232, 0, 0),
(9300482, 15476, 10, 0, 1, 2, 8, 5, 6, 3, 0, 0, 0, 0, 26684, 26685, 26686, 26687, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (9300464, 9300466, 9300467, 9300468, 9300469, 9300470, 9300471, 9300472, 9300473, 9300474, 9300475, 9300476, 9300477, 9300478, 9300480, 9300482);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(9300464, 1, 30208, 30209, 0),
(9300466, 1, 43220, 0, 0),
(9300467, 1, 38707, 0, 0),
(9300468, 1, 27405, 27406, 0),
(9300469, 1, 24034, 24038, 0),
(9300470, 1, 31609, 19366, 0),
(9300471, 1, 12993, 0, 30390),
(9300472, 1, 30424, 0, 0),
(9300473, 1, 41342, 0, 0),
(9300474, 1, 11343, 0, 0),
(9300475, 1, 34880, 34881, 0),
(9300476, 1, 31608, 0, 0),
(9300477, 1, 28738, 0, 0),
(9300478, 1, 1911, 0, 24244),
(9300480, 1, 36611, 0, 0),
(9300482, 1, 5304, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (9300464, 9300466, 9300467, 9300468, 9300469, 9300470, 9300471, 9300472, 9300473, 9300474, 9300475, 9300476, 9300477, 9300478, 9300480, 9300482);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(9300464, 900014),
(9300466, 900016),
(9300467, 900017),
(9300468, 900018),
(9300469, 900019),
(9300470, 900020),
(9300471, 900021),
(9300472, 900022),
(9300473, 900023),
(9300474, 900024),
(9300475, 900025),
(9300476, 900026),
(9300477, 900027),
(9300478, 900028),
(9300480, 900030),
(9300482, 900032);

-- ---------------------------------------------------------------------------
-- 2. Intro letters
-- ---------------------------------------------------------------------------
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `Material`, `RequiredDisenchantSkill`)
VALUES
(9302114, 12, 0, -1, 'Fel-Seared Pact', 167798, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'A pact sealed in green wax, its script still smoldering.', 931114, 0, 0, 0, 0, 0),
(9302116, 12, 0, -1, 'Storm-Touched Missive', 222, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'The parchment crackles with static and will not lie flat.', 931116, 0, 0, 0, 0, 0),
(9302117, 12, 0, -1, 'Oath of Xoroth', 167798, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Black ink on parchment as cold as frost, sealed with the mark of Xoroth.', 931117, 0, 0, 0, 0, 0),
(9302118, 15, 0, -1, 'Warden''s Vow', 17419, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'A steel-bound tablet of vows, its edge shimmering like a ward.', 931118, 0, 0, 0, 0, 0),
(9302119, 12, 0, -1, 'Vow of Radiance', 167798, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Blessed parchment, warm to the touch and faintly glowing.', 931119, 0, 0, 0, 0, 0),
(9302120, 12, 0, -1, 'Sanguine Scroll', 222, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'A crimson-stained scroll whose ink pulses like a heartbeat.', 931120, 0, 0, 0, 0, 0),
(9302121, 12, 0, -1, 'Farstrider''s Call', 241, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'A letter folded around a green fletching, smelling of pine.', 931121, 0, 0, 0, 0, 0),
(9302122, 12, 0, -1, 'Timeworn Scroll', 222, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Parchment that looks centuries old, though it arrived this morning.', 931122, 0, 0, 0, 0, 0),
(9302123, 12, 0, -1, 'Bone-Bound Codex', 3108, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'A codex bound in bone that chills the hands that hold it.', 931123, 0, 0, 0, 0, 0),
(9302124, 12, 0, -1, 'Ember-Scorched Tome', 241, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Embers crawl along its edges without burning the pages.', 931124, 0, 0, 0, 0, 0),
(9302125, 12, 0, -1, 'Whispering Parchment', 222, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Its symbols shift when you look away.', 931125, 0, 0, 0, 0, 0),
(9302126, 12, 0, -1, 'Star Chart', 222, 1, 1, 1, 0, -1, -1, 1, 1, 1, 1, 1, 'The stars drawn on it glimmer, even in daylight.', 931126, 0, 4, 0, -1, -1),
(9302127, 12, 0, -1, 'Sunlit Scripture', 167798, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Golden ink that glows like morning light.', 931127, 0, 0, 0, 0, 0),
(9302128, 12, 0, -1, 'Arcane Schematic', 4995, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Gears, springs and arcane runes; something inside the fold is ticking.', 931128, 0, 0, 0, 0, 0),
(9302130, 12, 0, -1, 'Ashen Tablet', 3108, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Grey stone dusted with ash that does not rub off.', 931130, 0, 0, 0, 0, 0),
(9302132, 12, 0, -1, 'Runed Tablet', 3108, 1, 0, 1, 0, -1, -1, 0, 0, 1, 1, 1, 'Runes older than any script the magisters teach glow faintly violet.', 931132, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `SoundOverrideSubclass` = VALUES(`SoundOverrideSubclass`), `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `BuyCount` = VALUES(`BuyCount`), `InventoryType` = VALUES(`InventoryType`), `AllowableClass` = VALUES(`AllowableClass`), `AllowableRace` = VALUES(`AllowableRace`), `ItemLevel` = VALUES(`ItemLevel`), `RequiredLevel` = VALUES(`RequiredLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`), `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `PageText` = VALUES(`PageText`), `LanguageID` = VALUES(`LanguageID`), `PageMaterial` = VALUES(`PageMaterial`), `startquest` = VALUES(`startquest`), `Material` = VALUES(`Material`), `RequiredDisenchantSkill` = VALUES(`RequiredDisenchantSkill`);

DELETE FROM `page_text` WHERE `ID` IN (931114, 931116, 931117, 931118, 931119, 931120, 931121, 931122, 931123, 931124, 931125, 931126, 931127, 931128, 931130, 931132);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(931114, 'The magisters speak of fel as a hunger. They are right. Hunger can be bound, and hunger can be made to serve.$B$BAs a Felsworn you will take demonic essence into yourself and turn its fire on our enemies, and you will learn to master that hunger before it masters you.$B$BI wait in the yard of the merchants'' house north of the Sunspire, beside the weapon racks. Come armed.$B$B- Seldrath Duskblind, Felsworn Trainer', 0),
(931116, 'The wind off the sea has been restless since the day you arrived. I do not believe that is a coincidence.$B$BA Stormbringer does not command the storm. A Stormbringer gives it a direction. Lightning, gale and thunder will answer you, if you are bold enough to call.$B$BFind me on the overlook east of the Sunspire, above the cliffs, where the wind is strongest.$B$B- Aerisa Stormlace, Stormbringer Trainer', 0),
(931117, 'Quel''Thalas burned while its protectors kept their hands clean. I will not ask you to keep yours clean.$B$BThe Knights of Xoroth wield shadow as other knights wield the Light, and they answer for every life they spend. Darkness is the weapon; honor decides where it falls.$B$BI stand by the fences where the road to Falthrien Academy leaves the Sunspire grounds. Come when you are ready to swear.$B$B- Dravinor Ashbrand, Knight of Xoroth Trainer', 0),
(931118, 'When the Scourge came, our wards failed and our people died behind them. A ward is only as strong as the one who holds it.$B$BA Guardian does not strike first. A Guardian stands between the blade and the one it was meant for, and does not move.$B$BI keep watch on the slope just west of the landing, over the lawn below.$B$B- Therandis Sunshield, Guardian Trainer', 0),
(931119, 'The Light did not abandon Quel''Thalas. We turned from it. A templar turns back.$B$BYou will carry holy fire in one hand and a blade in the other, and you will judge the wicked by both. Justice without mercy is cruelty; mercy without justice is weakness.$B$BYou will find me on the terrace north of the Sunspire, between the tower and the merchants'' house.$B$B- Aeloris Lightbrand, Templar Trainer', 0),
(931120, 'Every magister draws power from somewhere: the ley lines, the mana wells, the crystals our people now covet.$B$BWe draw it from the one well that never runs dry. Blood is life, and life is power. A Bloodmage spends a little of her own to take a great deal of her enemy''s.$B$BI wait on the plaza before the Sunspire door, beside the banners.$B$B- Sanreia Crimsonvein, Bloodmage Trainer', 0),
(931121, 'The Farstriders held the forests of Quel''Thalas for generations. We will hold them again.$B$BA ranger reads the wild the way a magister reads a tome: the tracks, the wind, the quiet before an ambush. A bow, a blade and a patient eye are all you need.$B$BFind me at Lanthan Perilon''s camp, west of the Sunspire, down the stairs from the landing.$B$B- Lyssia Leafstride, Ranger Trainer', 0),
(931122, 'You will read this later than I wrote it and sooner than you expect. Time is like that.$B$BA Chronomancer does not stop the sands; she moves them. Haste for a friend, a heartbeat stolen from a foe, a wound undone before it is struck.$B$BI am inside the Sunspire on the lower level, beside the arcane device on the side table. I have been expecting you for some time.$B$B- Taelenna Sandweaver, Chronomancer Trainer', 0),
(931123, 'The Scourge taught our people what the dead can do. It did not teach us that the dead can be commanded by the living.$B$BA Necromancer raises the fallen, drains the life from the enemy and turns the grave into a weapon. It is not a gentle art. It was never meant to be.$B$BI keep vigil at the lone fenced grave in the meadow to the south, where the road runs down to the bridge.$B$B- Morthalis Gravewhisper, Necromancer Trainer', 0),
(931124, 'The magisters teach fire as one school among many. I teach it as the only one worth knowing.$B$BA Pyromancer lets the flame build, layer on layer, until it can no longer be contained. Then you let it go.$B$BI am inside the Sunspire on the lower level, at the foot of the ramp. Bring nothing you would mind losing to a stray spark.$B$B- Caelor Emberhand, Pyromancer Trainer', 0),
(931125, 'Felendren was banished for listening to the wrong voices. He was not wrong to listen. He was wrong to listen alone.$B$BA Cultist opens the mind to what lies beyond the stars and brings back what it finds: madness for the enemy, insight for the faithful.$B$BI wait outside the doors of Falthrien Academy, west along the road past Lanthan Perilon''s camp.$B$B- Zaelith Shadowmoor, Cultist Trainer', 0),
(931126, 'The Well Watcher studies the sun. I study everything that shines beyond it.$B$BThe stars are older than Quel''Thalas and far more patient. A Starcaller borrows their light: a falling star for the enemy, a steady glow for an ally.$B$BClimb the ramp inside the Sunspire. I am on the open gallery at the top, below the Well Watcher.$B$B- Isolen Starweaver, Starcaller Trainer', 0),
(931127, 'Our people named themselves for the sun and then forgot to look at it.$B$BA Sun Cleric carries the dawn: warmth to mend the wounded and a searing light for those who would harm them. The sun does not choose whom it shines upon, but we choose where to stand.$B$BI tend to the faithful inside the Sunspire on the lower level, beside the east bench.$B$B- Saleria Sunvow, Sun Cleric Trainer', 0),
(931128, 'The magisters build with spells. The gnomes build with gears. I build with both, and my devices do not care which of them is offended.$B$BA Tinker brings turrets, bombs and a wrench to every fight, and the good ones bring a spare.$B$BI am in the yard of the merchants'' house north of the Sunspire, beside the supply crates. Mind the spring on the left.$B$B- Brelan Arcspindle, Tinker Trainer', 0),
(931130, 'Every soul in Quel''Thalas has a harvest coming. The Scourge only came early.$B$BA Reaper walks between the living and the dead with a scythe in hand, and takes from each what they owe. Grief is a whetstone. Use it.$B$BI wait beside the memorial stone on the rise north of the merchants'' house, where the spirit healer keeps watch.$B$B- Solwyn Ashenveil, Reaper Trainer', 0),
(931132, 'Spells fade. A rune carved true endures. Our ancestors knew this; the stones of Quel''Thalas still remember what they wrote.$B$BA Runemaster inscribes power into weapon, armor and earth, and calls on it long after the carving is done.$B$BI work under the small tree on the slope just west of the landing. Bring a steady hand.$B$B- Quelnar Runescribe, Runemaster Trainer', 0);

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `AllowableRaces`)
VALUES
(9302114, 2, 2, 2, -517, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302114, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Fel-Seared Pact', 'Read the Fel-Seared Pact and seek out Seldrath Duskblind by the weapon racks north of the Sunspire.', 'You handled those mana wyrms well, $N, and a courier left this for you while you were busy. It appears to be a pact sealed in green wax, its script still smoldering with fel fire. Our magisters have tasted fel power before; few of them mastered it. It seems to be from Seldrath Duskblind, who teaches the bound arts in the yard of the merchants'' house just north of the Sunspire, by the weapon racks. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Seldrath Duskblind north of the Sunspire on Sunstrider Isle.', 0, 0, 0, 0, 0, 0, 0, 0, 9302114, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302116, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302116, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Storm-Touched Missive', 'Read the Storm-Touched Missive and seek out Aerisa Stormlace on the overlook east of the Sunspire.', 'I was asked to bring this to your attention, $N. It appears to be a missive that crackles with static; the parchment lifts from my hand as if a wind were blowing through it. It seems to be from Aerisa Stormlace, who calls the sea storms from the overlook east of the Sunspire, above the cliffs. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Aerisa Stormlace on the overlook east of the Sunspire.', 0, 0, 0, 0, 0, 0, 0, 0, 9302116, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302117, 2, 2, 2, -518, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Oath of Xoroth', 'Read the Oath of Xoroth and seek out Dravinor Ashbrand by the fences on the road to Falthrien Academy.', 'I was asked to bring this to your attention, $N. It appears to be an oath written in black ink on parchment as cold as frost, bearing the seal of Xoroth. It seems to be from Dravinor Ashbrand, who keeps apart from the magisters, by the fences where the road to Falthrien Academy leaves the Sunspire grounds. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Dravinor Ashbrand on the road to Falthrien Academy.', 0, 0, 0, 0, 0, 0, 0, 0, 9302117, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302118, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302118, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warden''s Vow', 'Read the Warden''s Vow and seek out Therandis Sunshield on the slope west of the Sunspire''s landing.', 'I was asked to bring this to your attention, $N. It appears to be a steel-bound tablet inscribed with vows of protection; the runes along its edge shimmer like a ward. It seems to be from Therandis Sunshield, who stands watch on the slope just west of the landing, looking over the lawn below. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Therandis Sunshield west of the Sunspire''s landing.', 0, 0, 0, 0, 0, 0, 0, 0, 9302118, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302119, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302119, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Vow of Radiance', 'Read the Vow of Radiance and seek out Aeloris Lightbrand on the terrace north of the Sunspire.', 'I was asked to bring this to your attention, $N. It appears to be a vow written on blessed parchment, warm to the touch and faintly glowing. It seems to be from Aeloris Lightbrand, a templar who keeps his post on the terrace between the Sunspire and the merchants'' house to its north. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Aeloris Lightbrand on the terrace north of the Sunspire.', 0, 0, 0, 0, 0, 0, 0, 0, 9302119, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302120, 2, 2, 2, -516, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sanguine Scroll', 'Read the Sanguine Scroll and seek out Sanreia Crimsonvein beside the banners before the Sunspire door.', 'I was asked to bring this to your attention, $N. It appears to be a scroll stained a deep crimson, and the ink seems to pulse like a heartbeat. It seems to be from Sanreia Crimsonvein, who practices the blood arts on the plaza before the Sunspire door, beside the banners. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Sanreia Crimsonvein before the Sunspire door.', 0, 0, 0, 0, 0, 0, 0, 0, 9302120, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302121, 2, 2, 2, -505, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302121, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Farstrider''s Call', 'Read the Farstrider''s Call and seek out Lyssia Leafstride at Lanthan Perilon''s camp.', 'I was asked to bring this to your attention, $N. It appears to be a letter folded around a green fletching, smelling of pine and bowstring wax. It seems to be from Lyssia Leafstride, a ranger who keeps company with Lanthan Perilon at his camp west of the Sunspire, down the stairs from the landing. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Lyssia Leafstride at Lanthan Perilon''s camp.', 0, 0, 0, 0, 0, 0, 0, 0, 9302121, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302122, 2, 2, 2, -530, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302122, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Timeworn Scroll', 'Read the Timeworn Scroll and seek out Taelenna Sandweaver inside the Sunspire.', 'Most peculiar, $N. I could have sworn this scroll was blank when it arrived, yet the writing is plainly there now, and the parchment looks centuries old. It seems to be from Taelenna Sandweaver, who studies inside the Sunspire on the lower level, beside the arcane device on the side table. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Taelenna Sandweaver inside the Sunspire on Sunstrider Isle.', 0, 0, 0, 0, 0, 0, 0, 0, 9302122, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302123, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302123, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Bone-Bound Codex', 'Read the Bone-Bound Codex and seek out Morthalis Gravewhisper at the fenced grave on the road south to the bridge.', 'I''ll be honest with you, $N: this codex chills my hands. Its covers are bound in bone, and I hear faint whispers when I hold it. It seems to be from Morthalis Gravewhisper, who keeps vigil at the lone fenced grave in the meadow to the south, where the road runs down to the bridge. It is a long walk, but the road is plain. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Morthalis Gravewhisper at the fenced grave on the road south to the bridge.', 0, 0, 0, 0, 0, 0, 0, 0, 9302123, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302124, 2, 2, 2, -528, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302124, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ember-Scorched Tome', 'Read the Ember-Scorched Tome and seek out Caelor Emberhand inside the Sunspire.', 'Careful, $N! This tome is almost too hot to hold. Embers crawl along its edges without ever burning through the pages. It seems to be from Caelor Emberhand, who works inside the Sunspire on the lower level, at the foot of the ramp. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Caelor Emberhand inside the Sunspire on Sunstrider Isle.', 0, 0, 0, 0, 0, 0, 0, 0, 9302124, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302125, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302125, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Whispering Parchment', 'Read the Whispering Parchment and seek out Zaelith Shadowmoor outside Falthrien Academy.', 'I was asked to bring this to your attention, $N. I confess I would rather not have touched it. The symbols on this parchment shift when I look away, and I keep hearing whispers I cannot make out. It seems to be from Zaelith Shadowmoor, who waits outside the doors of Falthrien Academy, west along the road past Lanthan Perilon''s camp. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Zaelith Shadowmoor outside Falthrien Academy.', 0, 0, 0, 0, 0, 0, 0, 0, 9302125, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302126, 2, 2, 2, -506, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 9302126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Star Chart', 'Read the Star Chart and seek out Isolen Starweaver on the gallery at the top of the Sunspire''s ramp.', 'I was asked to bring this to your attention, $N. It appears to be a chart of the night sky, and the stars drawn on it actually glimmer, even here in daylight. It seems to be from Isolen Starweaver, who watches the sky from the open gallery at the top of the ramp inside the Sunspire, below Well Watcher Solanian. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Isolen Starweaver on the Sunspire''s upper gallery.', 0, 0, 0, 0, 0, 0, 0, 0, 9302126, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302127, 2, 2, 2, -507, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302127, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sunlit Scripture', 'Read the Sunlit Scripture and seek out Saleria Sunvow inside the Sunspire.', 'I was asked to bring this to your attention, $N. It appears to be a scripture written in golden ink that glows like morning light. It seems to be from Saleria Sunvow, a sun cleric who tends to the faithful inside the Sunspire on the lower level, beside the east bench. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Saleria Sunvow inside the Sunspire on Sunstrider Isle.', 0, 0, 0, 0, 0, 0, 0, 0, 9302127, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302128, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Arcane Schematic', 'Read the Arcane Schematic and seek out Brelan Arcspindle in the yard north of the Sunspire.', 'I was asked to bring this to your attention, $N. It appears to be a schematic covered in gears, springs and arcane runes, and I swear something inside the fold is ticking. It seems to be from Brelan Arcspindle, who tinkers in the yard of the merchants'' house just north of the Sunspire, beside the supply crates. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Brelan Arcspindle in the yard north of the Sunspire.', 0, 0, 0, 0, 0, 0, 0, 0, 9302128, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302130, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302130, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashen Tablet', 'Read the Ashen Tablet and seek out Solwyn Ashenveil by the spirit healer north of the Sunspire.', 'I was asked to bring this to your attention, $N. It appears to be a tablet of grey stone, dusted with ash that does not rub off and carved with the image of a scythe. It seems to be from Solwyn Ashenveil, who keeps company with the spirit healer on the rise north of the merchants'' house, beside the memorial stone. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Solwyn Ashenveil by the spirit healer north of the Sunspire.', 0, 0, 0, 0, 0, 0, 0, 0, 9302130, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512),
(9302132, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302132, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runed Tablet', 'Read the Runed Tablet and seek out Quelnar Runescribe on the slope west of the Sunspire''s landing.', 'I was asked to bring this to your attention, $N. It appears to be a small tablet carved with runes that glow faintly violet, older than any script I was taught. It seems to be from Quelnar Runescribe, who carves his runes under the small tree on the slope just west of the landing. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Quelnar Runescribe west of the Sunspire''s landing.', 0, 0, 0, 0, 0, 0, 0, 0, 9302132, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '', 512)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `AllowableRaces` = VALUES(`AllowableRaces`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (9302114, 9302116, 9302117, 9302118, 9302119, 9302120, 9302121, 9302122, 9302123, 9302124, 9302125, 9302126, 9302127, 9302128, 9302130, 9302132);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(9302114, 0, 8192, 8325, 1, 0),
(9302116, 0, 32768, 8325, 1, 0),
(9302117, 0, 65536, 8325, 1, 0),
(9302118, 0, 131072, 8325, 1, 0),
(9302119, 0, 262144, 8325, 1, 0),
(9302120, 0, 524288, 8325, 1, 0),
(9302121, 0, 1048576, 8325, 1, 0),
(9302122, 0, 2097152, 8325, 1, 0),
(9302123, 0, 4194304, 8325, 1, 0),
(9302124, 0, 8388608, 8325, 1, 0),
(9302125, 0, 16777216, 8325, 1, 0),
(9302126, 0, 33554432, 8325, 1, 0),
(9302127, 0, 67108864, 8325, 1, 0),
(9302128, 0, 134217728, 8325, 1, 0),
(9302130, 0, 536870912, 8325, 1, 0),
(9302132, 0, 2147483648, 8325, 1, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (9302114, 9302116, 9302117, 9302118, 9302119, 9302120, 9302121, 9302122, 9302123, 9302124, 9302125, 9302126, 9302127, 9302128, 9302130, 9302132);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(9302114, 'So the pact found you. Good. The hunger in you is small yet, $N; we will make it obey before we make it grow.'),
(9302116, 'You felt it too, didn''t you? The air changes when the storm takes notice of someone. Let us see what it makes of you, $N.'),
(9302117, 'You read the oath and came anyway. Then you already understand the price, $N. We begin now.'),
(9302118, 'Stand here beside me a moment, $N, and look down at the lawn. Everything you can see is worth holding. That is where we start.'),
(9302119, 'Welcome, $N. The Light has waited long enough for our people to return to it. We will not keep it waiting any longer.'),
(9302120, 'Your pulse is quick, $N. Good. Fear makes the blood run faster, and fast blood is eager to be spent.'),
(9302121, 'You found the camp without getting lost. That is a better start than most, $N. Sit, and we will see about that aim.'),
(9302122, 'Ah, $N. Right on time. Well, one of the times. Let us begin.'),
(9302123, 'You came all this way to stand beside a grave. Most of the living avoid them. That is the first thing we will change about you, $N.'),
(9302124, 'There is heat in you already, $N. I can feel it from here. Let us teach it where to go.'),
(9302125, 'Can you hear them yet, $N? No? You will. Stay close, and do not be afraid of what they say.'),
(9302126, 'Look up, $N. Even in daylight they are there. Once you learn to feel them, you never stop.'),
(9302127, 'Welcome, $N. You have the look of someone who has been waiting for the sun to rise. It has.'),
(9302128, 'You made it without blowing anything up. That makes one of us today, $N. Come, take a look at this.'),
(9302130, 'The spirit healer sends the dead back. I send them onward. Stand here with me a while, $N, and you will learn the difference.'),
(9302132, 'A steady hand and a quick eye. Good, $N. The runes are patient, but they are not forgiving. Watch closely.');

DELETE FROM `quest_request_items` WHERE `ID` IN (9302114, 9302116, 9302117, 9302118, 9302119, 9302120, 9302121, 9302122, 9302123, 9302124, 9302125, 9302126, 9302127, 9302128, 9302130, 9302132);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(9302114, ''),
(9302116, ''),
(9302117, ''),
(9302118, ''),
(9302119, ''),
(9302120, ''),
(9302121, ''),
(9302122, ''),
(9302123, ''),
(9302124, ''),
(9302125, ''),
(9302126, ''),
(9302127, ''),
(9302128, ''),
(9302130, ''),
(9302132, '');

DELETE FROM `creature_queststarter` WHERE `quest` IN (9302114, 9302116, 9302117, 9302118, 9302119, 9302120, 9302121, 9302122, 9302123, 9302124, 9302125, 9302126, 9302127, 9302128, 9302130, 9302132);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(15278, 9302114),
(15278, 9302116),
(15278, 9302117),
(15278, 9302118),
(15278, 9302119),
(15278, 9302120),
(15278, 9302121),
(15278, 9302122),
(15278, 9302123),
(15278, 9302124),
(15278, 9302125),
(15278, 9302126),
(15278, 9302127),
(15278, 9302128),
(15278, 9302130),
(15278, 9302132);

DELETE FROM `creature_questender` WHERE `quest` IN (9302114, 9302116, 9302117, 9302118, 9302119, 9302120, 9302121, 9302122, 9302123, 9302124, 9302125, 9302126, 9302127, 9302128, 9302130, 9302132);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(9300464, 9302114),
(9300466, 9302116),
(9300467, 9302117),
(9300468, 9302118),
(9300469, 9302119),
(9300470, 9302120),
(9300471, 9302121),
(9300472, 9302122),
(9300473, 9302123),
(9300474, 9302124),
(9300475, 9302125),
(9300476, 9302126),
(9300477, 9302127),
(9300478, 9302128),
(9300480, 9302130),
(9300482, 9302132);

-- ---------------------------------------------------------------------------
-- 3. Spawns
-- ---------------------------------------------------------------------------
-- 9004414 Seldrath Duskblind (Felsworn): Sunstrider Isle: hand-placed (INFERRED) the yard of the merchants'
--   house north of the Sunspire, in front of the weapon racks (Be_Weaponrack 10403.6,-6349.9 and
--   10408.6,-6356.4), 11 yd from Raelis Dawnstar, inspected with inspect_area and passing surface.check; faces
--   3.088 toward the start landing (10349.6, -6357.3), where players come up the terrace, the way players arrive
-- 9004416 Aerisa Stormlace (Stormbringer): Sunstrider Isle: hand-placed (INFERRED) the overlook east of the
--   Sunspire above the sea cliffs, north of the great Silvermoon tree, inspected with inspect_area and passing
--   surface.check; faces 2.251 toward the Sunspire up the garden, the way players come (rising ground ahead, no
--   wall at chest height), the way players arrive
-- 9004417 Dravinor Ashbrand (Knight of Xoroth): Sunstrider Isle: hand-placed (INFERRED) the mob-free lawn east
--   of the fences where the road to Falthrien Academy leaves the Sunspire grounds, kept apart from the
--   magisters, inspected with inspect_area and passing surface.check; faces 5.131 toward the foot of the stairs
--   down from the terrace (10346.6, -6264.3), where the road comes down, the way players arrive
-- 9004418 Therandis Sunshield (Guardian): Sunstrider Isle: hand-placed (INFERRED) the grass slope west of the
--   start landing, north of the fenced flower bed, watching over the lawn below, inspected with inspect_area and
--   passing surface.check; faces 4.185 toward the start landing (10349.6, -6357.3), the way players arrive
-- 9004419 Aeloris Lightbrand (Templar): Sunstrider Isle: hand-placed (INFERRED) the terrace between the Sunspire
--   and the merchants' house, a Blood Knight post; moved 4.5 yd from the planned (10374, -6368) so that no
--   trainer has more than two others within 30 yd, inspected with inspect_area and passing surface.check; faces
--   2.893 toward the start landing (10349.6, -6357.3), the way players arrive
-- 9004420 Sanreia Crimsonvein (Bloodmage): Sunstrider Isle: hand-placed (INFERRED) the plaza south-west of the
--   Sunspire door, beside the Be_Banner01 (10339.6, -6380.1) and the barrels, where arrivals from the landing
--   pass, inspected with inspect_area and passing surface.check; faces 0.913 toward the gap between Magistrix
--   Erona and the start landing, where players come to the door, the way players arrive
-- 9004421 Lyssia Leafstride (Ranger): Sunstrider Isle: hand-placed (INFERRED) the north side of Lanthan
--   Perilon's Farstrider camp, 8 yd from Lanthan; moved from the planned (10312, -6238), 9 yd from Springpaw Cub
--   55140, to 24.8 yd from it and 5.8 yd off the Springpaw Lynx 55184 patrol, on the camp side opposite the cub,
--   inspected with inspect_area and passing surface.check; faces 0.150 toward the junction where the Sunspire
--   road passes the camp (10333.7, -6217.8), the way players arrive
-- 9004422 Taelenna Sandweaver (Chronomancer): Sunstrider Isle: hand-placed (INFERRED) the north side of the
--   Sunspire hall beside the arcane device on the side table (Be_Magicalknickknack04 10377,-6393) and the weapon
--   racks; a free spot: Kariel 9.5 yd, Shara Sunwing 7.4 yd, the never-running Arena Tournament pedestals 2.0
--   yd, inspected with inspect_area and passing surface.check; faces 2.644 toward the hall door (10355,
--   -6385.5), where players enter, the way players arrive
-- 9004423 Morthalis Gravewhisper (Necromancer): Sunstrider Isle: hand-placed (INFERRED) the lone fenced
--   gravestone (Be_Gravestone01 10044.5,-6318) in the meadow on the road south to the bridge, 305 yd from the
--   start; nearest Tender 42.6 yd, inspected with inspect_area and passing surface.check; faces 5.806 toward the
--   road from the north (the grave behind him), the way players arrive
-- 9004424 Caelor Emberhand (Pyromancer): Sunstrider Isle: hand-placed (INFERRED) the south-east side of the
--   Sunspire hall at the foot of the gallery ramp, the magisters' side near Julia Sunstriker's reagent crates; a
--   free spot: Julia 15.3 yd, Jesthenis 16.8 yd, broom paths 3.0-3.6 yd, inspected with inspect_area and passing
--   surface.check; faces 1.463 toward the hall door (10355, -6385.5) across the hall, the way players arrive
-- 9004425 Zaelith Shadowmoor (Cultist): Sunstrider Isle: hand-placed (INFERRED) outside Falthrien Academy, 19 yd
--   from its walkable entrance (10204, -6093), where Lanthan Perilon sends players after Felendren; 283 yd from
--   the start; nearest Feral Tender 21.9 yd, inspected with inspect_area and passing surface.check; faces 5.228
--   toward the signpost road up the slope, where players come down, the way players arrive
-- 9004426 Isolen Starweaver (Starcaller): Sunstrider Isle: hand-placed (INFERRED) the open-sky gallery at the
--   top of the Sunspire ramp, the middle of its north lobe below Well Watcher Solanian (14 yd); moved 4 yd from
--   the planned (10394, -6398), which lies on the loop of Broom 61728 (now 4 yd), inspected with inspect_area
--   and passing surface.check; faces 4.197 toward the top of the ramp (10385, -6417), the way players arrive
-- 9004427 Saleria Sunvow (Sun Cleric): Sunstrider Isle: hand-placed (INFERRED) the north-east side of the
--   Sunspire hall between the jars and the east bench, the side where the priestess Matron Arena stands (14.1
--   yd); a free spot: Sallina 8.6 yd, the never-running Arena Tournament pedestal 1.9 yd, broom path 4.4 yd,
--   inspected with inspect_area and passing surface.check; faces 2.258 toward the hall door (10355, -6385.5),
--   where players enter, the way players arrive
-- 9004428 Brelan Arcspindle (Tinker): Sunstrider Isle: hand-placed (INFERRED) the west end of the merchants'
--   house yard by the supply crates, 17.6 yd from Jainthess Thelryn, inspected with inspect_area and passing
--   surface.check; faces 4.650 toward the yard entrance along the yard, the way players arrive
-- 9004430 Solwyn Ashenveil (Reaper): Sunstrider Isle: hand-placed (INFERRED) the spirit healer's rise north of
--   the merchants' house, 11.7 yd from the Spirit Healer and 13 yd from the fenced memorial stone
--   (Be_Gravestone01 10468.1,-6374.8), inspected with inspect_area and passing surface.check; faces 2.611 toward
--   the top of the stairs up to the rise, the way players arrive
-- 9004432 Quelnar Runescribe (Runemaster): Sunstrider Isle: hand-placed (INFERRED) the grass slope west of the
--   start landing under the small Silvermoon tree (10344, -6331), 18 yd from Therandis, inspected with
--   inspect_area and passing surface.check; faces 4.880 toward the start landing (10349.6, -6357.3), the way
--   players arrive
DELETE FROM `creature` WHERE `guid` IN (9004414, 9004416, 9004417, 9004418, 9004419, 9004420, 9004421, 9004422, 9004423, 9004424, 9004425, 9004426, 9004427, 9004428, 9004430, 9004432) OR `guid` BETWEEN 9004400 AND 9004499;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004414, 9300464, 530, 0, 0, 1, 1, 1, 10400, -6360, 36.111, 3.088, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Seldrath Duskblind, Felsworn Trainer'),
(9004416, 9300466, 530, 0, 0, 1, 1, 1, 10412, -6466, 37.861, 2.251, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Aerisa Stormlace, Stormbringer Trainer'),
(9004417, 9300467, 530, 0, 0, 1, 1, 1, 10338, -6245, 26.522, 5.131, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Dravinor Ashbrand, Knight of Xoroth Trainer'),
(9004418, 9300468, 530, 0, 0, 1, 1, 1, 10362, -6336, 31.166, 4.185, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Therandis Sunshield, Guardian Trainer'),
(9004419, 9300469, 530, 0, 0, 1, 1, 1, 10376, -6364, 35.81, 2.893, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Aeloris Lightbrand, Templar Trainer'),
(9004420, 9300470, 530, 0, 0, 1, 1, 1, 10338, -6375, 35.331, 0.913, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Sanreia Crimsonvein, Bloodmage Trainer'),
(9004421, 9300471, 530, 0, 0, 1, 1, 1, 10306, -6222, 27.365, 0.15, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Lyssia Leafstride, Ranger Trainer'),
(9004422, 9300472, 530, 0, 0, 1, 1, 1, 10378, -6398, 38.532, 2.644, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Taelenna Sandweaver, Chronomancer Trainer'),
(9004423, 9300473, 530, 0, 0, 1, 1, 1, 10046, -6325, 4.233, 5.806, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Morthalis Gravewhisper, Necromancer Trainer'),
(9004424, 9300474, 530, 0, 0, 1, 1, 1, 10350.5, -6427, 38.532, 1.463, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Caelor Emberhand, Pyromancer Trainer'),
(9004425, 9300475, 530, 0, 0, 1, 1, 1, 10213, -6110, 16.946, 5.228, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Zaelith Shadowmoor, Cultist Trainer'),
(9004426, 9300476, 530, 0, 0, 1, 1, 1, 10393.5, -6402, 49.721, 4.197, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Isolen Starweaver, Starcaller Trainer'),
(9004427, 9300477, 530, 0, 0, 1, 1, 1, 10382.5, -6419, 38.532, 2.258, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Saleria Sunvow, Sun Cleric Trainer'),
(9004428, 9300478, 530, 0, 0, 1, 1, 1, 10400, -6322, 35.658, 4.65, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Brelan Arcspindle, Tinker Trainer'),
(9004430, 9300480, 530, 0, 0, 1, 1, 1, 10466.5, -6358.5, 39.893, 2.611, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Solwyn Ashenveil, Reaper Trainer'),
(9004432, 9300482, 530, 0, 0, 1, 1, 1, 10345, -6330, 29.991, 4.88, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sunstrider Isle: Quelnar Runescribe, Runemaster Trainer');
