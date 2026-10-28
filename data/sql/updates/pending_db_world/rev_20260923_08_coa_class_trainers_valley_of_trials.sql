-- Conquest of Azeroth class trainers in the Valley of Trials: the eighteen CoA class trainers on their
-- own posts, the eighteen "seek your trainer" letters that Gornek hands out after Cutting Teeth, and the
-- first class chains with every target, helper, object and drop they need.
--
-- WHERE EACH VALUE COMES FROM
--   trainer posts  SOURCED-CLIENT: the QuestSuperTrack turn-in point of each letter (52000-52016); z is
--     the server floor (surface.floor). Facings are INFERRED from each post (reason in the spawn comment).
--   trainers  names and titles from the realm creature cache; Omogulg the Truthbearer and Pangajo Sunseer
--     are named by their letters and have no cache record (new entries). Class kits, menus and texts come
--     from the class trainer core (rev_20260923_05); Mu'kaka, Zim'chein and Wolfrider Yara speak their own
--     cached greeting and refusal (npccache 87574/287574, 502155/602155, 25007/125007).
--   looks  stand-ins (no SMSG_MIRRORIMAGE_DATA capture of any CoA trainer exists): a stock NPC of the
--     inferred race, sex and trade, copied from CreatureDisplayInfoExtra and restyled; race and sex are
--     INFERRED from the names and the voice of their texts. Weapons from the stock NPCs' own equipment.
--   quests  the realm quest cache. Letters: Gornek after Cutting Teeth (788), the stock letter pattern
--     (INFERRED); the ender is the trainer the letter names. Chains start at the letter's trainer and link
--     by PrevQuestID; RewardNextQuest from the cache inside this file.
--   chain places  hand-placed where the texts send the player (the den, the hill above it, the imp
--     cave, the canyon before it, the eastern desert, the southern mountains), each point checked on the
--     server floor, headroom and navmesh; drop chances SOURCED-EXILES.
--   stock trainers  every one keeps its post and role. Frang (guid 7651) stands 2.0 yd from Omogulg's
--     turn-in point; Ken'jai (guid 4912) is hidden while the Cultist kill copy stands at his post
--     (rev_20260924_13).
--   Reaper  Zul’raja the Harvester is CoA's unspawned trainer record 501296; CoA shipped no Valley Reaper
--     letter or chain, so his post, letter 9302430, page and "Call of the Shadowlands" copy 9302431 are INFERRED.
--
-- Blocks: creature guid 9003500-9003699, gameobject guid 7912300-7912399, creature
-- entries 9300200-9300206, gameobject entries 9301200-9301204, menus 930300-930304,
-- quest and item 9302430-9302431, page_text 931430.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
-- Mu'kaka: name and subname from creaturecache 502953 (SOURCED-CACHE)
--   look: troll male: his own greeting speaks troll dialect ("old Mu'kaka"); Bloodscalp Berserker 4579, hair, colour and beard changed; two-handed axe of the berserker
-- Rol'joku: name and subname from creaturecache 50296 (SOURCED-CACHE)
--   look: troll male: the chain text is troll dialect; Bloodscalp Witch Doctor 4581 with its troll mask, hair and colour changed; staff
-- Grillok Morzog: name and subname from creaturecache 502760 (SOURCED-CACHE)
--   look: orc male (orcish name); Burning Blade Shadowmage 4705, a demon-sworn orc, hair, colour and beard changed; two curved green blades
-- Zim'chein: name and subname from creaturecache 50277 (SOURCED-CACHE)
--   look: troll male (troll name); Darkspear Shaman 15840 with its mail helm, hair and colour changed; serpent mace and shield
-- Spi'ro: name and subname from creaturecache 50278 (SOURCED-CACHE)
--   look: troll male (troll name); Blood Guard Tor'zin 23807 in dark plate, tabard removed, hair and colour changed; two-handed mace
-- Den Sergeant Gormuk: name and subname from creaturecache 502791 (SOURCED-CACHE)
--   look: orc female: the letter says "dedicated herself"; Corporal Teeka Bloodsnarl 13851 in plate with a circlet, hair and colour changed; sword and shield
-- new NPC Omogulg the Truthbearer, named as the 52013 letter ("Seek out Omogulg the Truthbearer") (INFERRED: no cache record)
--   look: orc male (orcish name); Champion Guardian 13361 in Horde plate, hair, colour and beard changed; two-handed warhammer with a white flame for the Light
-- Fleshweaver Chella: name and subname from creaturecache 502921 (SOURCED-CACHE)
--   look: troll female: female per her letter page 8001 ("Seek her", SOURCED-CACHE), troll per the dialect of her chain text ("da cave"); Hakkari Blood Priest 11223, hair and colour changed; hooked dark dagger
-- Wolfrider Yara: name and subname from creaturecache 502810 (SOURCED-CACHE)
--   look: orc female: an orc wolfrider; Breka Wolfsister 24258 (wolf clan stable master) with mail helm and cloak, tabard removed, hair and colour changed; axe and short bow
-- Kragar the Reanimator: name and subname from creaturecache 502925 (SOURCED-CACHE)
--   look: orc male (orcish name); En'kilah Necrolord 23359 in dark robes, hair, colour and beard changed; staff
-- Grishnakh Searscar: name and subname from creaturecache 503402 (SOURCED-CACHE)
--   look: orc male (orcish name); Arathi Flame Keeper 16341 in fire-festival robes, hair, colour and beard changed; red staff
-- Rug'ra Witherhand: name and subname from creaturecache 502832 (SOURCED-CACHE)
--   look: orc female: female per her letter page 8002 ("Find her", SOURCED-CACHE), orc per her chain text's opening "Zug, zug"; Deathspeaker Attendant 30327 in cult robes and hood, hair and colour changed; one-handed mace
-- new NPC Pangajo Sunseer, named as the 52012 letter ("Seek out Pangajo Sunseer") (INFERRED: no cache record)
--   look: tauren male: Sun Cleric was a tauren class among the Horde races and the Venomancer text sees "citizens of every shade"; Elder Skyseer 15635, horns and colour changed; gold feathered staff
-- Mekboy Parod: name and subname from creaturecache 502872 (SOURCED-CACHE)
--   look: orc male ("Mekboy"); Frostwolf Explosives Expert 13793, hair, colour and beard changed; wooden hammer
-- Qwi'spe the Wise: name and subname from creaturecache 50288 (SOURCED-CACHE)
--   look: troll female: troll per the dialect of her chain text ("Dis fine, yes?"); female is an INFERRED design choice for variety, no source gives her sex; Arin'sor 11665 (raptor trainer), hair and colour changed; two daggers
-- Krull Rocksmash: name and subname from creaturecache 50290 (SOURCED-CACHE)
--   look: orc male (orcish name); Durkot Wolfbrother 23502 in hides, hair and colour changed; axe
-- Zina Glyphreader: name and subname from creaturecache 502912 (SOURCED-CACHE)
--   look: orc female: orc per her other name "Mog'or" and her chain text's "Zug zug"; female is an INFERRED design choice for variety, no source gives her sex; Frostwolf Shaman 13410 in robes and hood, hair and colour changed; runed staff
-- Zul’raja the Harvester: name and subname from creaturecache 501296 (SOURCED-CACHE)
--   look: troll male (troll name); Uzo Deathcaller 26222 in Zul'Aman plate, hair and colour changed, Horde war helm added for "looking at my helmet" (200037); Zulian Scythe and Deepscythe
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(502953, 'Mu''kaka', 'Barbarian Trainer', 930302, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50296, 'Rol''joku', 'Witch Doctor Trainer', 930013, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502760, 'Grillok Morzog', 'Felsworn Trainer', 930014, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50277, 'Zim''chein', 'Stormbringer Trainer', 930300, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50278, 'Spi''ro', 'Knight of Xoroth Trainer', 930017, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502791, 'Den Sergeant Gormuk', 'Guardian Trainer', 930018, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300200, 'Omogulg the Truthbearer', 'Templar Trainer', 930019, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502921, 'Fleshweaver Chella', 'Bloodmage Trainer', 930020, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502810, 'Wolfrider Yara', 'Ranger Trainer', 930301, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502925, 'Kragar the Reanimator', 'Necromancer Trainer', 930023, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(503402, 'Grishnakh Searscar', 'Pyromancer Trainer', 930024, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502832, 'Rug''ra Witherhand', 'Cultist Trainer', 930025, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300201, 'Pangajo Sunseer', 'Sun Cleric Trainer', 930027, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502872, 'Mekboy Parod', 'Tinker Trainer', 930028, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50288, 'Qwi''spe the Wise', 'Venomancer Trainer', 930029, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50290, 'Krull Rocksmash', 'Primalist Trainer', 930031, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502912, 'Zina Glyphreader', 'Runemaster Trainer', 930032, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(501296, 'Zul’raja the Harvester', 'Reaper Trainer', 930030, 10, 10, 0, 29, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50277, 50278, 50288, 50290, 50296, 501296, 502760, 502791, 502810, 502832, 502872, 502912, 502921, 502925, 502953, 503402, 9300200, 9300201);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(502953, 0, 1478, 1, 1),
(50296, 0, 1478, 1, 1),
(502760, 0, 51, 1, 1),
(50277, 0, 1478, 1, 1),
(50278, 0, 1478, 1, 1),
(502791, 0, 52, 1, 1),
(9300200, 0, 51, 1, 1),
(502921, 0, 1479, 1, 1),
(502810, 0, 52, 1, 1),
(502925, 0, 51, 1, 1),
(503402, 0, 51, 1, 1),
(502832, 0, 52, 1, 1),
(9300201, 0, 59, 1, 1),
(502872, 0, 51, 1, 1),
(50288, 0, 1479, 1, 1),
(50290, 0, 51, 1, 1),
(502912, 0, 52, 1, 1),
(501296, 0, 1478, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (50277, 50278, 50288, 50290, 50296, 501296, 502760, 502791, 502810, 502832, 502872, 502912, 502921, 502925, 502953, 503402, 9300200, 9300201);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(502953, 1478, 8, 0, 1, 1, 0, 4, 5, 6, 0, 0, 0, 0, 147398, 0, 152436, 154636, 156255, 0, 0, 0),
(50296, 1478, 8, 0, 1, 1, 0, 2, 7, 10, 0, 145082, 0, 147400, 148721, 150467, 152438, 0, 156256, 6411, 0, 0),
(502760, 51, 2, 0, 1, 3, 7, 3, 2, 5, 0, 0, 0, 147432, 148743, 150502, 152473, 154663, 0, 9854, 0, 0),
(50277, 1478, 8, 0, 1, 4, 3, 5, 1, 1, 0, 27386, 5224, 20707, 7106, 8776, 20705, 0, 0, 19623, 0, 0),
(50278, 1478, 8, 0, 1, 3, 2, 1, 6, 3, 0, 5417, 41890, 0, 41891, 41892, 41893, 41894, 0, 41895, 0, 0),
(502791, 52, 2, 1, 1, 5, 6, 2, 4, 5, 0, 145374, 146357, 147950, 22099, 151020, 153072, 155224, 0, 157594, 0, 0),
(9300200, 51, 2, 0, 1, 8, 7, 2, 6, 4, 0, 163639, 163640, 0, 163638, 163641, 163642, 163643, 163644, 163645, 0, 0),
(502921, 1479, 8, 1, 1, 1, 3, 3, 4, 4, 0, 0, 146277, 147863, 149047, 150925, 152967, 0, 0, 157502, 0, 0),
(502810, 52, 2, 1, 1, 0, 0, 4, 3, 0, 0, 41920, 0, 42269, 6426, 0, 41645, 42270, 0, 41159, 36859, 0),
(502925, 51, 2, 0, 1, 8, 8, 0, 1, 3, 0, 41352, 28347, 20755, 28332, 37890, 28334, 37892, 0, 0, 0, 0),
(503402, 51, 2, 0, 1, 4, 4, 6, 3, 8, 0, 0, 34743, 0, 28765, 13937, 28766, 28767, 21139, 26952, 0, 0),
(502832, 52, 2, 1, 1, 13, 0, 5, 6, 0, 0, 145819, 146990, 0, 47038, 50683, 46284, 156136, 0, 158281, 0, 0),
(9300201, 59, 6, 0, 1, 7, 0, 5, 1, 6, 0, 0, 0, 0, 26803, 0, 26794, 26793, 0, 0, 0, 0),
(502872, 51, 2, 0, 1, 4, 4, 1, 0, 1, 0, 145369, 146352, 147945, 149129, 151015, 153067, 1554, 0, 157589, 0, 0),
(50288, 1479, 8, 1, 1, 5, 1, 6, 5, 2, 0, 0, 0, 3836, 5512, 9017, 8114, 8115, 0, 8386, 0, 0),
(50290, 51, 2, 0, 1, 3, 1, 2, 5, 2, 0, 0, 27525, 0, 7101, 0, 13319, 41595, 0, 0, 0, 0),
(502912, 52, 2, 1, 1, 6, 1, 8, 1, 3, 0, 145349, 146326, 23429, 23430, 150989, 153039, 155191, 156430, 157562, 0, 0),
(501296, 1478, 8, 0, 1, 17, 1, 4, 3, 7, 0, 25493, 40115, 43881, 7106, 45358, 45359, 0, 45360, 0, 0, 49860);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (50277, 50278, 50288, 50290, 50296, 501296, 502760, 502791, 502810, 502832, 502872, 502912, 502921, 502925, 502953, 503402, 9300200, 9300201);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(502953, 1, 5289, 0, 0),
(50296, 1, 1908, 0, 0),
(502760, 1, 12991, 12991, 0),
(50277, 1, 2810, 13628, 0),
(50278, 1, 18062, 0, 0),
(502791, 1, 10614, 11589, 0),
(9300200, 1, 29410, 0, 0),
(502921, 1, 19924, 0, 0),
(502810, 1, 10612, 0, 2550),
(502925, 1, 13622, 0, 0),
(503402, 1, 12943, 0, 0),
(502832, 1, 52015, 0, 0),
(9300201, 1, 13337, 0, 0),
(502872, 1, 1902, 0, 0),
(50288, 1, 2184, 5283, 0),
(50290, 1, 27850, 0, 0),
(502912, 1, 39743, 0, 0),
(501296, 1, 41764, 42933, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (50277, 50278, 50288, 50290, 50296, 501296, 502760, 502791, 502810, 502832, 502872, 502912, 502921, 502925, 502953, 503402, 9300200, 9300201);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(502953, 900012),
(50296, 900013),
(502760, 900014),
(50277, 900016),
(50278, 900017),
(502791, 900018),
(9300200, 900019),
(502921, 900020),
(502810, 900021),
(502925, 900023),
(503402, 900024),
(502832, 900025),
(9300201, 900027),
(502872, 900028),
(50288, 900029),
(50290, 900031),
(502912, 900032),
(501296, 900030);

-- ---------------------------------------------------------------------------
-- 2. Named trainer menus
-- ---------------------------------------------------------------------------
-- 930302 Mu'kaka: greeting 87574, refusal 287574 (npccache, the trainer's own voice)
-- 930300 Zim'chein: greeting 502155, refusal 602155 (npccache, the trainer's own voice)
-- 930301 Wolfrider Yara: greeting 25007, refusal 125007 (npccache, the trainer's own voice)
-- 930303 Old Brokthar: his words and the reply to the Reaper (INFERRED), the option only while 9302431 is taken
DELETE FROM `npc_text` WHERE `ID` IN (25007, 87574, 125007, 287574, 502155, 602155, 930303, 930304);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(25007, 'Greetings, fellow ranger. I am Yara, tracker of the deep wilds and master hunter.$B$BFor years I have walked silent paths through ancient forests, learning the secrets of beast and blade.$B$BThe wilderness speaks to those who know how to listen - I can hear your ranger''s heart in the way you move through these lands.$B$BCome, let me teach you the ways of fang and claw, bow and blade.', 'Greetings, fellow ranger. I am Yara, tracker of the deep wilds and master hunter.$B$BFor years I have walked silent paths through ancient forests, learning the secrets of beast and blade.$B$BThe wilderness speaks to those who know how to listen - I can hear your ranger''s heart in the way you move through these lands.$B$BCome, let me teach you the ways of fang and claw, bow and blade.', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(87574, 'Ay mon, you be comin'' to old Mu''kaka for some trainin''?$B$BI like da look of you mon, you got a fire in ya eyes that be remindin'' me of when I be young.$B$BLet me be showin'' ya how to harness that strength, and you be becomin'' just as strong as me!', 'Ay mon, you be comin'' to old Mu''kaka for some trainin''?$B$BI like da look of you mon, you got a fire in ya eyes that be remindin'' me of when I be young.$B$BLet me be showin'' ya how to harness that strength, and you be becomin'' just as strong as me!', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(125007, 'The wilds speak only to Rangers, $C. Your footsteps are too heavy for the forest paths I teach.', 'The wilds speak only to Rangers, $C. Your footsteps are too heavy for the forest paths I teach.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(287574, 'Ay mon, you be lackin'' da brutal personality of da Barbarian. Come back when you got some fight in ya bones, $C.', 'Ay mon, you be lackin'' da brutal personality of da Barbarian. Come back when you got some fight in ya bones, $C.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(502155, 'The storms have brought you to me, $C. I am Zim''chein, and I have learned to speak with thunder itself.$B$BWhen lightning splits the sky and winds howl with ancient fury, that is when a Stormbringer''s power reaches its peak.$B$BI have walked through tempests that would scatter lesser beings and called down bolts that crack mountains.$B$BThe elements recognize your potential... let me teach you to command the very forces of nature.', 'The storms have brought you to me, $C. I am Zim''chein, and I have learned to speak with thunder itself.$B$BWhen lightning splits the sky and winds howl with ancient fury, that is when a Stormbringer''s power reaches its peak.$B$BI have walked through tempests that would scatter lesser beings and called down bolts that crack mountains.$B$BThe elements recognize your potential... let me teach you to command the very forces of nature.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(602155, 'The storms ignore your call, $C. You lack the necessary connection to the tempest.', 'The storms ignore your call, $C. You lack the necessary connection to the tempest.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930303, '<Old Brokthar sits apart from the camp, watching the troll dead.>$B$BI stood at Hyjal and in a dozen fights before it, $c. No blade ever finished me. Now my own breath will. Tell me... what waits for an old warrior when it does?', '<Old Brokthar sits apart from the camp, watching the troll dead.>$B$BI stood at Hyjal and in a dozen fights before it, $c. No blade ever finished me. Now my own breath will. Tell me... what waits for an old warrior when it does?', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930304, 'The Shadowlands... so there is somewhere to go. Good. I was afraid it would only be dark.$B$BTell the Harvester I will not keep him waiting long.', 'The Shadowlands... so there is somewhere to go. Good. I was afraid it would only be dark.$B$BTell the Harvester I will not keep him waiting long.', 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930300, 930301, 930302);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930302, 87574),
(930302, 287574),
(930300, 502155),
(930300, 602155),
(930301, 25007),
(930301, 125007);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (930300, 930301, 930302);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930302, 0, 3, 'I seek training as a Barbarian.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930300, 0, 3, 'I seek training as a Stormbringer.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930301, 0, 3, 'I seek training as a Ranger.', 0, 5, 16, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (930300, 930301, 930302) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930302, 87574, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Barbarian'),
(14, 930302, 287574, 0, 0, 15, 0, 2048, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Barbarian'),
(15, 930302, 0, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Barbarian'),
(14, 930300, 502155, 0, 0, 15, 0, 32768, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Stormbringer'),
(14, 930300, 602155, 0, 0, 15, 0, 32768, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Stormbringer'),
(15, 930300, 0, 0, 0, 15, 0, 32768, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Stormbringer'),
(14, 930301, 25007, 0, 0, 15, 0, 1048576, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Ranger'),
(14, 930301, 125007, 0, 0, 15, 0, 1048576, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Ranger'),
(15, 930301, 0, 0, 0, 15, 0, 1048576, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Ranger');

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930303, 930304);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930303, 930303),
(930304, 930304);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 930303;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930303, 0, 0, 'Zul’raja the Harvester sent me. I can tell you what lies beyond.', 0, 1, 1, 930304, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` = 930303 AND `SourceTypeOrReferenceId` = 15;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 930303, 0, 0, 0, 9, 0, 9302431, 0, 0, 0, 0, 0, '', 'Old Brokthar - Show gossip option only while Call of the Shadowlands is taken');

-- ---------------------------------------------------------------------------
-- 3. Chain creatures
-- ---------------------------------------------------------------------------
-- 299328: Barbarian "Welcome to the Warband" (200107): the rookie the Warband refused; name from the quest text, orc look Ukor 5729 (stand-in); neutral faction 7 so he fights back but never ambushes newcomers, immune to NPCs so the den folk leave him alone
-- 299225: Knight of Xoroth "The Demon Inside" (200034): name from the objective ("Kill the unfathomably lazy peon"), the Lazy Peon look 10038; neutral 7 and immune to NPCs, asleep away from the camp
-- 299239: Cultist "Going MAD!" (200074): the kill copy of the stock priest Ken'jai 3707 at his post; his own look 4068 and mace; neutral 7 and immune to NPCs
-- 299224: Witch Doctor "Who Called For Da Docta?" (200030): name and level 3 SOURCED-EXILES creature 299224; Armored Scorpid look 2487; hostile, it comes back "to finish da job"
-- 9300202: Ranger "The Ranger's Path" (200008-200010): the trainer's falcon, name from the quest text; hawk look 4877 (no falcon display resolves); friendly quest giver
-- 9300203: Witch Doctor "The Doctor Is In!" (200029-200030): the injured friend "out in da desert", name from the objective; troll look Vel'rin Fang 4074 (stand-in); can-assist type flag so a player may heal him (Unit.cpp:11529-11537), no regeneration so he stays wounded until healed
-- 9300204: Bloodmage "Blood Is Power" (200020): the "odd Troll" in the imp cave who carries the Tome of Blood; name from the objective, Hexed Troll look 4079 (stand-in); neutral like the cave's imps
-- 9300205: Pyromancer "The Way of the Pyromancer" (200144): the fire elemental bound to a campfire near the Burning Blade Coven; name from the text, Minor Manifestation of Fire look 2172; hostile
-- 9300206: Reaper "Call of the Shadowlands" (9302431): the dying veteran of the valley copy (name INFERRED, as the other copies' Old Man Jenkins, Dalin Soft and Gyrothor Turbospark); Old Orok look 18909 (grey-haired orc, a stand-in); friendly and immune
-- 685018 [KC] Splash Pangajo Sunseer: Poisoning the World (200026) credit, given when the concoction hits the trainer
-- 685019 [KC] Splash Nekai the Reanimator: Poisoning the World (200026) credit, given when the concoction hits the trainer
-- 685020 [KC] Splash Omogulg the Truthbearer: Poisoning the World (200026) credit, given when the concoction hits the trainer
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(299328, 'Gok', NULL, 0, 4, 4, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 512, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299225, 'Unfathomably Lazy Peon', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 512, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299239, 'Ken''jai', NULL, 0, 5, 5, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 512, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299224, 'Scorpid Stalker', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 20, 1, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(9300202, 'Beaky', NULL, 0, 3, 3, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 1, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(9300203, 'Hi''bi Ja''min', NULL, 0, 5, 5, 0, 29, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 4096, 0, 'SmartAI', 0, 1, 1, 1, 0, 0, ''),
(9300204, 'Mysterious Troll', NULL, 0, 4, 4, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 9300204, '', 0, 1, 1, 1, 1, 0, ''),
(9300205, 'Scorch', NULL, 0, 5, 5, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 0, 4, 0, 9300205, '', 0, 1, 1, 1, 1, 0, ''),
(9300206, 'Old Brokthar', NULL, 930303, 5, 5, 0, 29, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 0, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(685018, '[KC] Splash Pangajo Sunseer', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 130, ''),
(685019, '[KC] Splash Nekai the Reanimator', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 130, ''),
(685020, '[KC] Splash Omogulg the Truthbearer', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 0, 10, 0, 0, '', 0, 1, 1, 1, 1, 130, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (299224, 299225, 299239, 299328, 685018, 685019, 685020, 9300202, 9300203, 9300204, 9300205, 9300206);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(299328, 0, 5729, 1, 1),
(299225, 0, 10038, 1, 1),
(299239, 0, 4068, 1, 1),
(299224, 0, 2487, 1, 1),
(9300202, 0, 4877, 1, 1),
(9300203, 0, 4074, 1, 1),
(9300204, 0, 4079, 1, 1),
(9300205, 0, 2172, 1, 1),
(9300206, 0, 18909, 1, 1),
(685018, 0, 11686, 1, 1),
(685019, 0, 11686, 1, 1),
(685020, 0, 11686, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (299239, 299328);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(299328, 1, 12348, 0, 0),
(299239, 1, 2558, 0, 0);

-- ---------------------------------------------------------------------------
-- 4. Chain objects
-- ---------------------------------------------------------------------------
-- 9301200: Necromancer "Call of Death" chain (200049-200051): the circle is a quest giver; green ground rune 674
-- 9301201: Felsworn "Coming into Demonhood" (200022): the demon skull placed in the area round the den; skull 226
-- 9301202: Runemaster "Runes of Power" (200112): the riddle's answer "within the den"; the floating eye 621
-- 9301203: Tinker "Ingenuity At It's Finest!" (200068): scrap in the imp cave; junk pile 7114
-- 9301204: Templar "A Quiet Life" (200080): the paladin statue the order raised after the Third War; Uther statue 6815
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`)
VALUES
(9301200, 2, 674, 'Ritual Circle', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI'),
(9301201, 3, 226, 'Skull of Kaz', '', '', 1, 1689, 9301201, 0, 1, 0, 0, 0, 0, 200022, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301202, 3, 621, 'Eye of the Beholder', '', '', 1, 1689, 9301202, 0, 1, 0, 0, 0, 0, 200112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301203, 3, 7114, 'Scrap Metal', '', '', 1, 1689, 9301203, 0, 1, 0, 0, 0, 0, 200068, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301204, 5, 6815, 'Hidden Statue', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`);

-- ---------------------------------------------------------------------------
-- 5. Letter and runestone pages
-- ---------------------------------------------------------------------------
-- Pages of the letter items 54000-54016 and 9302430 and of the Riddlestone; the world database has none of them.
-- 8000: SOURCED-CACHE pagetextcache
-- 8001: SOURCED-CACHE pagetextcache
-- 8002: SOURCED-CACHE pagetextcache
-- 8003: SOURCED-CACHE pagetextcache
-- 8004: SOURCED-CACHE pagetextcache
-- 8006: SOURCED-CACHE pagetextcache
-- 8007: SOURCED-CACHE pagetextcache
-- 8011: SOURCED-CACHE pagetextcache
-- 8016: SOURCED-CACHE pagetextcache
-- 8005: paragraphs 1-2 from the Shadowglen Knight of Xoroth letter, page 7007 (SOURCED-CACHE); closing INFERRED
-- 8008: INFERRED in the three-part voice of the cached Valley letters
-- 8009: paragraphs 1-2 from the Shadowglen Ranger letter, page 7010 (SOURCED-CACHE); closing INFERRED
-- 8010: paragraphs 1-2 from the Shadowglen Runemaster letter, page 7012 (SOURCED-CACHE, lower-case "carved" kept); closing INFERRED
-- 8012: INFERRED: no Sun Cleric letter page exists in any cache
-- 8013: INFERRED: the cached Templar pages (5003, 6003) are signed by other trainers
-- 8014: INFERRED: the only cached Tinker page (15014) is written for the undead
-- 8015: INFERRED: the only cached Venomancer page (15015) is written for the undead
-- 931430: INFERRED: CoA shipped no Valley Reaper letter; its Reaper letter pages (6015, 7011, 15000) are not cached
-- 27577: the Riddlestone 661332 of Runes of Power (200112), which only the Valley uses; INFERRED: no source has the page; the riddle of ct-deathknell's page 27575 (its answer, the Eye of the Beholder, is this quest's objective), closed with Zina's hint "within the den. Not without."
DELETE FROM `page_text` WHERE `ID` IN (8000, 8001, 8002, 8003, 8004, 8005, 8006, 8007, 8008, 8009, 8010, 8011, 8012, 8013, 8014, 8015, 8016, 27577, 931430);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(8000, 'Lok''tar! The ancient rage flows through your veins, young warrior. The path of the barbarian calls to those who embrace the fury of battle over the discipline of traditional combat.$B$BAs a barbarian, you will learn to channel your inner beast, letting primal rage guide your strikes while the spirits of the wild lend you strength. Your enemies will flee before your berserker fury.$B$BSeek out Mu''kaka in the Valley of Trials. He will teach you to harness the savage power that burns within your soul.', 0),
(8001, 'Blood calls to blood, warrior. The crimson arts are not for the weak-hearted, but those who master them wield power beyond mortal comprehension.$B$BAs a blood mage, you will learn to sacrifice vitality for raw magical force, turning life itself into devastating spells. Every drop spilled fuels greater power.$B$BFleshweaver Chella practices these forbidden techniques in the Valley of Trials.$B$BSeek her if you dare walk the path of blood and sacrifice.', 0),
(8002, 'The whispers grow stronger now... can you hear them? The Old Ones speak to those willing to listen to truths that mortal minds fear to acknowledge.$B$BAs a cultist, you will commune with ancient entities, gaining forbidden knowledge through dangerous pacts. Power comes to those who serve beings beyond mortal understanding.$B$BRug''ra Witherhand has heard these whispers in the Valley of Trials. Find her if you would learn the secrets that lurk in shadow.', 0),
(8003, 'Your soul burns. Do you feel it?$B$BWas it worth it?$B$BSoon, it will be. For you, $N, are Felsworn. You are coming closer to bridging the gap between mortal and immortal, demon and $r.$B$BYou will learn to bind demonic essence to your will and to harness powerful fel fire magic in protest of this world.$B$BTyrant Gros teaches others to master these powers in the Valley of Trials.$B$BSeek him out.', 0),
(8004, 'Honor demands sacrifice, and the greatest sacrifice is placing others'' safety above your own. The guardian''s path is one of selfless protection.$B$BYou will become a living fortress, your body and magic forming barriers that no enemy can breach. Your allies will find safety behind your steadfast defense.$B$BDen Sergeant Gormuk has dedicated her life to this calling in the Valley of Trials. Seek her to learn the sacred duty of protection.', 0),
(8005, 'Honor and shadow need not be opposites. The Knights of Xoroth embrace darkness in service of a greater good, wielding void magic for righteous purposes.$B$BYou will learn to channel shadow energy while maintaining your moral compass, becoming a dark paladin who protects the innocent through unconventional means.$B$BSpi''ro walks this dangerous path between shadow and honor in the Valley of Trials. Seek him out if you would join this unique order of dark knights.', 0),
(8006, 'Death is not the end - it is merely a passage between worlds. The necromancer serves as shepherd of souls, ensuring the dead find proper rest.$B$BYou will command undead servants and manipulate the essence of life and death, but always with respect for the natural order and the dignity of the departed.$B$BKragar the Reanimator practices these arts with wisdom in the Valley of Trials. Seek him to learn the sacred balance between life and death.', 0),
(8007, 'The elements themselves acknowledge your strength! Earth, air, fire, and water will bend to your will as you master the primordial forces of creation.$B$BAs a primalist, you will channel raw elemental power with devastating effect. Earthquakes, hurricanes, volcanic eruptions - all become weapons in your hands.$B$BKrull Rocksmash communes with the elemental spirits in the Valley of Trials. Find him to begin your education in primal magic.', 0),
(8008, 'The fire in your blood has awakened, young one. Few feel its call so clearly.$B$BAs a pyromancer, you will learn to kindle flame from nothing, to shape it, and to master the inferno before it masters you.$B$BGrishnakh Searscar tends these flames in the Valley of Trials. Seek him out before the fire within you burns too hot to hold.', 0),
(8009, 'The wilds of Azeroth need protectors who understand both nature''s beauty and its fierce protective instincts. The Ranger serves as guardian of the natural world.$B$BYou will master woodland skills, commune with wild beasts, and become one with the forests, plains, and mountains you protect.$B$BWolfrider Yara watches over the wilds of the Valley of Trials. Find her to learn the ways of nature''s guardian.', 0),
(8010, 'The ancient runes hold power that transcends mortal magic. carved into stone and metal, these symbols channel forces older than civilization itself.$B$BAs a Runemaster, you will inscribe power into the very world around you, creating lasting enchantments that endure long after other magic fades.$B$BZina Glyphreader reads the old glyphs in the Valley of Trials. Seek her guidance there.', 0),
(8011, 'Thunder acknowledges your strength! The storm spirits recognize a kindred fury in your soul, one worthy of commanding wind and lightning.$B$BAs a stormbringer, you will summon tempests from clear skies, call down lightning that splits mountains, and ride the wind itself into battle.$B$BZim''chein masters these powers in the Valley of Trials. His command over storm and tempest is legendary among our people.', 0),
(8012, 'The sun rises for all who stand beneath it, and it has chosen to shine through you.$B$BAs a sun cleric, you will carry its warmth to the wounded and its searing light to those who would harm them.$B$BPangajo Sunseer brings the sun''s blessing to the Valley of Trials. Seek him out and let the light guide your first steps.', 0),
(8013, 'Honor binds the strong, and faith gives that honor purpose.$B$BAs a templar, you will stand at the front of every battle, a shield of conviction for your people and a hammer against those who would break them.$B$BOmogulg the Truthbearer keeps these sacred oaths in the Valley of Trials. Seek him out and swear your own.', 0),
(8014, 'Gears turn, pistons pump, and something always explodes. Welcome to the good part!$B$BAs a tinker, you will build your own weapons, patch together contraptions from scrap, and prove that a clever mind hits as hard as any axe.$B$BMekboy Parod works his inventions in the Valley of Trials. Find him, and bring your own spare parts.', 0),
(8015, 'Every sting, every fang, every bitter root holds a lesson for those patient enough to learn it.$B$BAs a venomancer, you will brew toxins that wither your foes and remedies that turn death away, for poison and cure are two sides of one blade.$B$BQwi''spe the Wise studies venoms and antidotes in the Valley of Trials. Learn from her, carefully.', 0),
(8016, 'The loa whisper your name! The ancestral spirits recognize one worthy of serving as bridge between the world of the living and the realm of the dead.$B$BAs a witch doctor, you will master both healing and hexing, blessing and cursing, always in service of your tribal community and the greater good.$B$BRol''joku practices these ancient arts in the Valley of Trials. His connection to the loa and ancestral spirits runs deeper than most can comprehend.', 0),
(27577, 'I have no lid, yet I never sleep.$BI judge what is fair without a word.$BBeauty, they say, was never in the thing at all, but always in me.$B$BWhat am I? Seek me within the den, not without.', 0),
(931430, 'Every life is a season, and every season ends. Some fear the harvest; the reaper tends it.$B$BAs a reaper, you will cut through your foes with blade and scythe and gather the strength of the fallen to carry you through the fight.$B$BZul’raja the Harvester keeps watch over the troll dead in the Valley of Trials. Seek him at the burial ground east of the camp.', 0);

-- 9302430 Soul Harvest: the Reaper letter item, with the name, look and description of CoA's Reaper letter 650151 and the item fields of the Valley letter 54016 (SOURCED-CACHE itemcache).
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `ItemLevel`, `maxcount`, `stackable`, `bonding`, `description`, `PageText`, `Material`)
VALUES
(9302430, 12, 0, 'Soul Harvest', 142197, 1, 0, 0, 1, 1, 1, 'A grim letter bound in black leather that seems to drain light from its surroundings and carries the scent of autumn''s end.', 931430, 0)
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `ItemLevel` = VALUES(`ItemLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`), `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `PageText` = VALUES(`PageText`), `Material` = VALUES(`Material`);

-- ---------------------------------------------------------------------------
-- 6. Quests
-- ---------------------------------------------------------------------------
-- The Ranger's Path (200008) carries the Northshire copy's map point (-8799.29, -412.93) in the cache;
-- it points at Beaky's post here, the quest's own target (DERIVED). The Stolen Power Core (200096):
-- ObjectiveText1 is '0' in the cache (a CoA data quirk on its seven copies only); left blank.
-- RewardNextQuest (the next step is offered at turn-in): questcache NextQuestInChain where the next quest is in
--   this file: 200134->200135, 200135->200136, 200049->200050, 200050->200051, 200008->200009, 200009->200010,
--   200095->200096, 200096->200097, 200029->200030.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(52000, 2, 2, 2, -526, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warrior''s Fury', 'Seek out Mu''kaka in the Valley of Trials.', 'I was asked to bring this to your attention, young barbarian. It appears to be a primal tablet carved with orcish war-runes that pulse with barely contained fury. The stone radiates wild strength, and it seems to be from Mu''kaka, who teaches the barbarian''s way in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Mu''kaka in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52001, 2, 2, 2, -516, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Crimson Arts', 'Seek out Fleshweaver Chella in the Valley of Trials.', 'I was asked to bring this to your attention, young blood mage. It appears to be a blood-stained scroll that pulses with dark magic, reeking of iron and forbidden power. It seems to be from Fleshweaver Chella, who practices these crimson arts in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Fleshweaver Chella in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54001, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52002, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54002, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Whispers of the Void', 'Seek out Rug''ra Witherhand in the Valley of Trials.', 'I was asked to bring this to your attention, young cultist. It appears to be a writhing scroll covered in symbols that shift and change when not directly observed. Strange whispers echo from within, and it seems to be from Rug''ra Witherhand, who communes with forbidden powers in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Rug''ra Witherhand in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54002, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52003, 2, 2, 2, -517, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54003, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Fel Binding', 'Seek out Tyrant Gros in the Valley of Trials.', 'I was asked to bring this to your attention, young felsworn. It appears to be a demonic pact wreathed in green flames, its infernal script burning the eyes of those who read it. It seems to be from Tyrant Gros, who teaches others to bind demonic power in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Grillok Morzog in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54003, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52004, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54004, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Shield of Honor', 'Seek out Den Sergeant Gormuk in the Valley of Trials.', 'I was asked to bring this to your attention, young guardian. It appears to be a polished steel tablet inscribed with protective vows, radiating an aura of unbreakable defense. It seems to be from Den Sergeant Gormuk, who has dedicated herself to protecting others in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Den Sergeant Gormuk in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54004, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52005, 2, 2, 2, -518, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54005, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Oath', 'Seek out Spi''ro in the Valley of Trials.', 'I was asked to bring this to your attention, young knight of xoroth. It appears to be a shadow-wreathed document bearing the seal of Xoroth, radiating cold darkness. It seems to be from Xagok, who walks this dangerous path between shadow and honor in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Spi''ro in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54005, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52006, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54006, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Communion of Souls', 'Seek out Kragar the Reanimator in the Valley of Trials.', 'I was asked to bring this to your attention, young necromancer. It appears to be an ancient tablet carved from giant bone, inscribed with necromantic symbols that whisper of undeath. It seems to be from Kragar the Reanimator, who practices these arts in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Kragar the Reanimator in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54006, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52007, 2, 2, 2, -531, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54007, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Elemental Fury', 'Seek out Krull Rocksmash in the Valley of Trials.', 'I was asked to bring this to your attention, young primalist. It appears to be a scroll that crackles with raw elemental energy, swirling with miniature tempests and flames. It seems to be from Krull Rocksmash, who communes with elemental spirits in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Krull Rocksmash in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54007, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52008, 2, 2, 2, -528, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54008, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Path of Flames', 'Seek out Grishnakh Searscar in the Valley of Trials.', 'I was asked to bring this to your attention, young pyromancer. It appears to be a smoldering manuscript that radiates intense heat, with flames dancing across its scorched surface. It seems to be from Grishnakh Searscar, who masters the art of fire in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Grishnakh Searscar in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54008, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52009, 2, 2, 2, -505, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54009, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Wild', 'Seek out Wolfrider Yara in the Valley of Trials.', 'I was asked to bring this to your attention, young ranger. It appears to be a leather-bound guide that smells of the wild, stained with mud and marked by animal tracks. It seems to be from Wolfrider Yara, the ranger who protects the wilds in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Wolfrider Yara in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54009, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52010, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54010, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Glyphs', 'Seek out Zina Glyphreader in the Valley of Trials.', 'I was asked to bring this to your attention, young runemaster. It appears to be a heavy stone slab etched with glowing runes that pulse with ancient magical power. It seems to be from Zina Glyphreader, the runemaster who dwells in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Mog''or the Glyphreader in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54010, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52011, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54011, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Thunder''s Voice', 'Seek out Zim''chein in the Valley of Trials.', 'I was asked to bring this to your attention, young stormbringer. It appears to be a manuscript that crackles with electrical energy, thunder rumbling softly from within its pages. It seems to be from Zim''chein, the stormbringer who commands tempests in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Zim''chein in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54011, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52012, 2, 2, 2, -507, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54012, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Solar Blessing', 'Seek out Pangajo Sunseer in the Valley of Trials.', 'I was asked to bring this to your attention, young sun cleric. It appears to be a golden scripture that glows with warm sunlight, radiating divine healing energy. It seems to be from Pangajo Sunseer, the sun cleric who brings light to the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Pangajo Sunseer in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54012, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52013, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54013, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sacred Oaths', 'Seek out Omogulg the Truthbearer in the Valley of Trials.', 'I was asked to bring this to your attention, young templar. It appears to be a blessed document that emanates holy light, inscribed with vows of divine service. It seems to be from Omogulg the Truthbearer, who serves as a templar in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Omogulg the Truthbearer in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54013, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52014, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54014, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mechanical Innovation', 'Seek out Mekboy Parod in the Valley of Trials.', 'I was asked to bring this to your attention, young tinker. It appears to be technical blueprints filled with mechanical designs, accompanied by the sound of ticking gears. It seems to be from Mekboy Parod, the tinker who works in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Mekboy Parod in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54014, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52015, 2, 2, 2, -515, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54015, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Toxic Arts', 'Seek out Qwi''spe the Wise in the Valley of Trials.', 'I was asked to bring this to your attention, young venomancer. It appears to be a dangerous tome reeking of exotic toxins, with green vapors seeping from between its pages. It seems to be from Qwi''spe the Wise, who studies venoms and antidotes in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Qwi''spe the Wise in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54015, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(52016, 2, 2, 2, -523, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 54016, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancestral Wisdom', 'Seek out Rol''joku in the Valley of Trials.', 'I was asked to bring this to your attention, young witch doctor. It appears to be an ancient scroll decorated with tribal fetishes, humming with ancestral power and loa magic. It seems to be from Rol''joku, who practices these ancient arts in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Rol''joku in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 54016, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(9302430, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302430, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Soul Harvest', 'Seek out Zul’raja the Harvester in the Valley of Trials.', 'I was asked to bring this to your attention, young reaper. It appears to be a grim letter bound in black leather that seems to drain light from its surroundings. It seems to be from Zul’raja the Harvester, who teaches the reaper''s way in the Valley of Trials. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Zul’raja the Harvester in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 9302430, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200107, 2, 3, 3, -526, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 532805, 1, 532806, 1, 395861, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Welcome to the Warband', 'Kill Gok and return back to your trainer.', 'Aye, $N. Good to see you could join da Warband.  What is da Warband, you might be wonderin''? Considering your arrival, I would have assumed you''d already know. Well, little $c, this is about to be a rude awakening.  Da Warband is where all barbarians, brutes, and strongmen alike come together to compete to see who is the strongest, most brutal, and most powerful individual of them all.  That''s the only way we can TRULY test our mettle. THIS IS IT! You may be new to this, but absolutely nobody will go easy on you.  Your first test will be the same as all the other rookies. There''s an individual who has been mucking things up and spreading rumors just because they couldn''t cut it and were denied access to da Warband.  They''re known as Gok. Kill him, hahaha! I will reward you with a weapon well-suited for a noob like yourself if you are capable of such a task.  Come back to me alive, or die.', '', 'Return to your trainer.', 299328, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200020, 2, 3, 3, -516, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 661317, 1, 1505015, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Is Power', 'Collect the Tome of Blood from the mysterious Troll.', 'Ahh, $C. Your day has finally come.  Blood. Something you should be well acquainted with at this point, in some way or another. Blood is life. But blood, as you will soon learn, is also power.  I want you to imagine what you can be capable of in a world in which you can control the very life essence of another beings body. To simply crush their insides with the flick of a wrist...  Intoxicating.  In due time, you will learn more. For now, I require your assistance in pursuing my own studies and through this I will also be able to help you learn.   Nearby is a tome, in da cave where the imps roam, held by an odd Troll, and one of which I require for my studies. Collect it for me, I''m sure one of them has it on them.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661316, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200074, 2, 3, 3, -522, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532803, 1, 532804, 1, 532881, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Going MAD!', 'Kill Ken''jai.', 'Zug, zug, you have arrived at the most opportune time, $N.  I have heard the whispers of the great beyond. It tells me of a particularly dangerous individual to our cause. I need you to destroy them, swiftly.  If you do this I will reward you with a weapon fit for a follower of the Old Gods themselves.  The individual you''re looking for lays outside the den. Somewhere near the witch doctor. They go by the name of "Ken''jai". End him.', '', 'Return to your trainer.', 299239, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200022, 2, 3, 3, -517, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 727003, 1, 727001, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Coming into Demonhood', 'Retrieve the skull of Kaz.', 'And so it begins.  Greetings, $N. I can already tell that you have begun to feel the residual fel power that burns within your veins. I envy you, there was once a time where I was not so used to it as I am now.  You are Felsworn, and as such, you are at the border of mortality and the likes of demons. However, unlike some, you and I will not fall to the traps of power that fel magic provides, and that so many other practitioners fall too, often unbeknownstly. Perhaps you will even become powerful enough to take on a demonic form someday, but for now, your Fel Empowerment will do you wonders at bringing out your true potential.  Let me make myself clear, the Horde and Alliance are of no use to us, but they must believe we are their allies in order for our greater goals to become achievable. Do not forget this. When it all comes to a head, do not forget where your true allegiance lays.  And now, a test. A skull of a powerful demon known as Kaz has been placed in the surrounding area. Find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661320, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200134, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200135, 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Peace Through Strength', 'Find Foreman Thazz''ril in the Valley of Trials.', 'Lok''tar ogar, $N. We have much work to accomplish together and you, my friend, have much to learn!  We are Guardians, and as such we are tasked with, quite literally, guarding Azeroth. From the occasional ne''er-do-well that robs a man, to far more threatening monsters who pose a threat to our people. We are the ones who heed the call.  And, as my example preludes, I have such a task for you today. If you can do this, you are more than ready to proceed further into your training.  There is an old foreman nearby who could use a new weapon. He has a particular bone to pick with the imps nearby...  Visit him and see what he needs.', '', 'Find Foreman Thazz''ril in the Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200135, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200136, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Prioritizing Defense', 'Kill Vile Familiars until you find a weapon for Foreman Thazz''ril.', 'Zug zug, $N. I can see you''re here to help, that''s great!  I''m in need of a weapon and if you could help me acquire one I would be inclined to reward you.  The VIle Familiars nearby... I hate them. They have caused so many problems here in the Valley that I would find any excuse to destroy them!  ... and I have found a great one. Occasionally, I do see an imp with a blade. I want it. The highest quality one you can find. No matter how many must die for you to get it.', '', 'Return to Foreman Thazz''ril.', 0, 0, 0, 0, 0, 0, 0, 0, 662330, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200136, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 0, 2, 25, 0, 0, 0, 0, 0, 0, 0, 0, 245712, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Helping A Friend', 'Return to your trainer with news of your success.', 'The weapon? Good enough. I will keep it as a reminder of all the dead demons that were slain in order to acquire it.', '', 'Return to your trainer with news of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200034, 2, 3, 3, -518, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 2000124, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Demon Inside', 'Kill the unfathomably lazy peon.', 'Aha, $N, welcome, do you like your mortal visage? The time has come for us to unleash hell upon Azeroth, one step at a time.  As you well know, there are only so many of us, but our numbers will grow with time. I need not remind you, I assume, that the plight of the Horde is not your primary concern. They are but a tool, a shield, so that we may further our own goals.  At every step, at every moment, we must wreck havoc on this world, yet we must not give up our secret - that we are demons - and as such, I have a little task for you.  There is a peon, one of which is so unfathomably lazy that he could not be made to do work no matter how hard you tried.   I have been tasked by my superiors here to deal with him. We could give him a pay raise, we could beat him with a stick until he listens, we could even try to simply convince him to work. But...  Kill him, we''ll make up an excuse for how he died. Scorpid attack, probably.', '', 'Return to your trainer.', 299225, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200049, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200050, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of Death', 'Find and interact with the ritual circle.', 'Zug zug, $C. Glad you could join me in the graveyard today.  Weather is good today, isn''t it?  It seems you''ve already been acquainted with undeath, I am impressed by your ability to raise the dead.   Perhaps you could be used to my benefit, which I''m sure you would not mind. I have a particularly powerful Undead that I wish to summon, but I dare not attempt it myself - I am far too important.  You, however, could learn quite a lot by succeeding here. And if you are to fail? I will simply raise you as my own.  Do not overthink it. Let me mark your map to the location of where my ritual must be had. You must collect specific items in order to complete the ritual.  Now, be gone.', '', 'Interact with the ritual circle.', 685121, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the ritual circle', '', '', ''),
(200050, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200051, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Calls', 'Kill Vile Familiars and loot their bones, flesh, and skull.', 'In order to summon the Undead monstrosity, I must bring the following ingredients to the ritual circle.  - Bones - Fresh Flesh - Skull  The nearby Vile Familiars have just what is needed.', '', 'Return to the ritual circle.', 0, 0, 0, 0, 0, 0, 0, 0, 458421, 458422, 458423, 0, 0, 0, 1, 1, 1, 0, 0, 0, '', '', '', ''),
(200051, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 660053, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Dead', 'Kill the Undead Monstrocity.', '<The materials dissipate into the ritual circle into a puff of smoke>  ...something seems off.  The summon has failed, inspect the ritual circle again. But be careful, it is unstable.', '', 'Return to your trainer.', 299232, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200162, 2, 3, 3, -531, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 296200, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Way of the Bear', 'Kill 4 Felstalkers.', 'Zug zug, $C. I have awaited your arrival here in the Valley of Trials.  You come to me for wisdom, and as such, I will deliver.  The first step to becoming a master $C is mastering the way of the bear. With each successive mastery will come yet another challenge, but for now, let''s focus on what it means to unlock your inner savage instincts.  Bears are large, ferocious creatures. They know only what they must to survive, and that is to kill. There is little one can do to escape from a bear who wishes to end their life.  Through the bear we gain savagery, viciousness, and strength, without mercy.   Show me that you understand this by ending the lives of the Felstalkers north of here and I will reward you.', '', 'Return to your trainer.', 3102, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200144, 2, 3, 3, -528, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 293203, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Way of the Pyromancer', 'Defeat Scorch and acquire his heart.', 'The fire rises, $N.  As a Pyromancer, you must make sure it does not rise to engulf you, or you will burn in it.  I have a task for you, a task that should aid you in controlling the raging inferno in your heart.  A group of desperate Pyromancers have unleashed a force they could not control, they bound him to a campfire near the Burning Blade Coven.   The elemental''s name is Scorch, I will mark his location on your map. Kill him, and bring me his heart.  Lok''tar ogar!', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 662331, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200008, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200009, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -493.5, -4296, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Ranger''s Path', 'Find your Tar''dun''s falcon in Valley of Trials.', 'Bein'' a Ranger is more than just pickin'' up a bow, or fightin'' from the cover of the trees, $n.  Bein'' a Ranger, ultimately, means that you have a deep connection to the wilds. You are its guardian.  I sent my falcon, Beaky, to scout the surrounding areas, but he has not returned.   Please, find him and direct him to return back to me.', '', 'Find your Tar''dun''s falcon in Valley of Trials.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200009, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200010, 3, 0, 0, 0, 0, 0, 0, 662316, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Surprise Attack!', 'Slay the suspicious creature.', 'Something is rustling in the nearby bushes.  You''re under attack! ', '', 'Tend to the falcon.', 299222, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200010, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 0, 2, 70, 0, 0, 0, 0, 0, 662317, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 818000, 1, 727000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Falcons Are Friends', 'Use the Red Vial on the falcon.', 'You find a note attached to the falcon that reads:  <If you are reading this, you have found my friend. Attached to this note is a small red vial. Give it to him if he is injured, and he will know what to do next.>', '', 'Return to your trainer.', 685011, 0, 0, 0, 1, 0, 0, 0, 662317, 662316, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 'Tend to Beaky''s wounds', '', '', ''),
(200112, 2, 3, 3, -527, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 661332, 0, 0, 293202, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runes of Power', 'Figure out the riddle etched on the runestone.', 'Zug zug, $N. I''m glad you could finally join me, I have awaited your arrival.  Today, a simple lesson in problem solving for an aspiring Runemaster such as yourself. Perhaps you will succeed, perhaps you will not.  Here, I have a rune. Etched on the rune is a riddle. Figure the riddle out and return to me.   A hint? The best I can do is tell you that the answer to this riddle lays within the den. Not without.  I will know when you return if you have figured it out or not, do not worry. Succeed, and I will reward you.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661330, 661332, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, '', '', '', ''),
(200095, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 200096, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Useful In Your Own Right', 'Assist Mekboy Parod with his tinkering shenanigans.', 'Greetings, $N, I am glad to make your acquaintance and I have heard much about you before your arrival.  You have come to me to learn and as a $C you have already shown yourself to be a dutiful student of the arcane. But there is so much more to the power that we call forth than just lightning and electricity.  In time, you will learn just how deep your potential lays. But for now... I do have a bit of a task for you.  There''s an individual nearby known as "Mekboy Parod" and he always calls on my aid for his... tinkering shenanigans... He needs some lightning, $N, but I am busy. Can you go and assist him?', '', 'Assist Mekboy Parod with his tinkering shenanigans.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200096, 2, 3, 0, -520, 0, 0, 0, 0, 0, 0, 200097, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Stolen Power Core', 'Kill Vile Familiars until one of them drops the power core.', 'Howdy, $N! Glad your trainer got around to sendin'' some help my way.  This is a very simple task, I just need some POWER! But unfortunately my power core has been stolen by one of the nearby Vile Familiars. Can you return it for me?', '', 'Return to Mekboy Parod.', 0, 0, 0, 0, 0, 0, 0, 0, 661417, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200097, 2, 3, 0, -525, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 663317, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Job For A Stormcaller', 'Tell your trainer of your success.', 'I appreciate you retrieving this power core! You can return to your trainer now and let him know what you''ve done for me.', '', 'Tell your trainer of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200080, 2, 3, 3, -524, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 52855, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Quiet Life', 'Visit the hidden statue in the southern mountains of the Valley of Trials.', 'Zug, zug, $N. I have awaited your arrival.  As Templars, we have ascended to the highest order of the holy faith, and as such we have quite a lot of responsibility on our shoulders.  Paladins and Priests work alongside us to maintain peace through the Holy Light in this world and each of us, though different in our own subtle ways, hope to bring the light to Azeroth once more. Despite it''s perils.  Our path may be different but some may argue that it is far more rigorous. To be a templar means to maintain extremely precise control of your emotions, your combat flow, and your mind.  In order to keep myself healthy, I enjoy meditating near a statue of a powerful Paladin that was secretly erected here by our order after the third war, in his honor. To reach it, you will need to use your agile movements.  Please, visit the area yourself. Tell me what you experience when you return.', '', 'Visit the hidden statue in the southern mountains of the Valley of Trials.', 685037, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Visit the hidden statue', '', '', ''),
(200068, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 415000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ingenuity At It''s Finest!', 'Collect 3 Scrap Metal.', 'Zug, zug, $N.  Today, I will prove the ingenuity of the Orcs. Lok''tar ogar! I will create a gun for me, and if you help me, for you!  There is some metal out there in the imp cave that could be used to create a gun for you and me. Collect me some and I build gun.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663320, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, '', '', '', ''),
(200026, 2, 3, 3, -515, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 662217, 0, 0, 292200, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Poisoning the World', 'Splash the mysterious concoction on nearby citizens.', 'Welcome, $C. Have you come to poison da well, so to speak?  I am always willing to teach new and aspiring masters of the venomous arts, but in return, I sometimes require a favor. Dis fine, yes?  Look around you. There are citizens of every shade. But they are pure, which is good, they are untainted. Here I have a concoction that I have made. What it does, should not be of concern to you.  What I need is for you to splash it on three people in particular; first, Pangajo Sunseer, second, Omogulg the Truthbearerr, and third, Nekai the Reanimator.  Return to me when you have done this and I will make it worth your time.', '', 'Return to your trainer.', 685018, 685019, 685020, 0, 1, 1, 1, 0, 662217, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Pangajo Sunseer', 'Nekai the Reanimator', 'Omogulg the Truthbearer', ''),
(200029, 2, 3, 3, -523, 0, 0, 0, 0, 0, 0, 200030, 1, 0, 0, 0, 0, 0, 0, 0, 16, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Doctor Is In!', 'Heal the injured friend of your trainer with rank 1 Loa''s Brew.', 'Zug zug, $C. I can see you''ve already become well acquainted with the powers of Sseratus.  Let me guide you, mon. I have a task, a critical one at that. I have a friend out in da desert who, according to our scouts, has been injured by the scorpids. I only just got word of it and would have been on my way, but I believe this is a task that would be perfect for one such as yourself.  He''s a strong troll. A troll''s troll. And in all honesty, many be gettin'' injured by those damn scorpids. But regardless, stay diligent.  Find my friend, heal him with the power of your Loa''s Brew, and then return to me.', '', 'Return to your trainer.', 685021, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Save Hi''bi Ja''min', '', '', ''),
(200030, 2, 3, 3, -523, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 292202, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Who Called For Da Docta?', 'Slay the Scorpid Stalker.', 'My brethren be out here tryin'' to deal wit da scorpid situation. It be more dangerous than it look.  I am not da first one to be injured. I can only pray to da Loa that I was not poisoned. But I did get hurt. Thank you for healing me, mon.  Oh, no! Look behind you, mon! One of da scorpids be comin'' back to finish da job!', '', 'Return to your trainer.', 299224, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(9302431, 2, 3, 3, -508, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 540070, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Shadowlands', 'Visit Old Brokthar in the Valley of Trials.', 'Keep grinnin'' at me helmet like dat, and dese blades gonna find ya chest, $N.    ...ya be bold, mon. I can feel ya come here to learn. I got a simple task for ya today, young $C.    In the valley is an old orc who is nearing his end. In his prime, he was a behemoth on the battlefield and took many lives. But now, he sits out his days by the burial ground east of the camp.    He will die and the Shadowlands will claim him. But today is not his day. Yet, I can feel his yearning to leave this plane, but he is unaware of what lays before him once he is gone.    You may not have expected such a task, but I would humbly ask you to pay him a visit and have a chat.', '', 'Return to your trainer.', 685022, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chat with Old Brokthar', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (52000, 52001, 52002, 52003, 52004, 52005, 52006, 52007, 52008, 52009, 52010, 52011, 52012, 52013, 52014, 52015, 52016, 200008, 200009, 200010, 200020, 200022, 200026, 200029, 200030, 200034, 200049, 200050, 200051, 200068, 200074, 200080, 200095, 200096, 200097, 200107, 200112, 200134, 200135, 200136, 200144, 200162, 9302430, 9302431);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(52000, 0, 2048, 788, 1, 0),
(52001, 0, 524288, 788, 1, 0),
(52002, 0, 16777216, 788, 1, 0),
(52003, 0, 8192, 788, 1, 0),
(52004, 0, 131072, 788, 1, 0),
(52005, 0, 65536, 788, 1, 0),
(52006, 0, 4194304, 788, 1, 0),
(52007, 0, 1073741824, 788, 1, 0),
(52008, 0, 8388608, 788, 1, 0),
(52009, 0, 1048576, 788, 1, 0),
(52010, 0, 2147483648, 788, 1, 0),
(52011, 0, 32768, 788, 1, 0),
(52012, 0, 67108864, 788, 1, 0),
(52013, 0, 262144, 788, 1, 0),
(52014, 0, 134217728, 788, 1, 0),
(52015, 0, 268435456, 788, 1, 0),
(52016, 0, 4096, 788, 1, 0),
(9302430, 0, 536870912, 788, 1, 0),
(200107, 0, 2048, 52000, 0, 0),
(200020, 0, 524288, 52001, 0, 0),
(200074, 0, 16777216, 52002, 0, 0),
(200022, 0, 8192, 52003, 0, 0),
(200134, 0, 131072, 52004, 0, 0),
(200135, 0, 131072, 200134, 0, 0),
(200136, 0, 131072, 200135, 0, 0),
(200034, 0, 65536, 52005, 0, 0),
(200049, 0, 4194304, 52006, 0, 0),
(200050, 0, 4194304, 200049, 0, 0),
(200051, 0, 4194304, 200050, 0, 0),
(200162, 0, 1073741824, 52007, 0, 0),
(200144, 0, 8388608, 52008, 0, 0),
(200008, 0, 1048576, 52009, 0, 0),
(200009, 0, 1048576, 200008, 1, 0),
(200010, 0, 1048576, 200009, 1, 0),
(200112, 0, 2147483648, 52010, 1, 0),
(200095, 0, 32768, 52011, 0, 0),
(200096, 0, 32768, 200095, 0, 0),
(200097, 0, 32768, 200096, 0, 0),
(200080, 0, 262144, 52013, 0, 0),
(200068, 0, 134217728, 52014, 0, 0),
(200026, 0, 268435456, 52015, 1, 0),
(200029, 0, 4096, 52016, 0, 0),
(200030, 0, 4096, 200029, 0, 0),
(9302431, 0, 536870912, 9302430, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (52000, 52001, 52002, 52003, 52004, 52005, 52006, 52007, 52008, 52009, 52010, 52011, 52012, 52013, 52014, 52015, 52016, 200008, 200009, 200010, 200020, 200022, 200026, 200029, 200030, 200034, 200049, 200050, 200051, 200068, 200074, 200080, 200095, 200096, 200097, 200107, 200112, 200134, 200135, 200136, 200144, 200162, 9302430, 9302431);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(52000, 'Lok''tar, young warrior! The fire of battle burns in your eyes, and I can sense the primal rage that courses through your blood. You have chosen the ancient path of the barbarian.$B$BAs a Barbarian, you will learn to channel your innermost fury into crushing blows that shatter armor and bone alike. Your berserker rage will make you nearly unstoppable in combat, while the spirits of the wild guide your strikes with deadly precision.$B$BThis path requires you to embrace the beast within while maintaining enough control to distinguish friend from foe. Your rage will be your greatest weapon, but it must never consume your honor. Train hard, fight harder, and let your enemies taste the fury of the Horde.$B$BWelcome to the brotherhood of berserkers, warrior. May your rage burn eternal!'),
(52001, 'Blood calls to blood, and yours answers with power beyond mortal understanding. You have chosen to walk the crimson path, to master the forbidden art of blood magic.$B$BAs a Blood Mage, you will learn to sacrifice vitality for raw magical force, turning life essence into devastating spells that can drain enemies dry or empower allies beyond their natural limits. Every drop spilled becomes a weapon in your arsenal.$B$BThis magic demands constant sacrifice - your own blood, your enemies'' blood, the blood of willing allies when necessity demands it. But for those brave enough to pay this price, the rewards transcend ordinary spellcasting.$B$BRemember always that power without wisdom leads only to destruction. Use these gifts to serve the Horde, and may your enemies'' blood fuel our victory.'),
(52002, 'The whispers grow stronger now that you have joined our number. The Old Ones welcome another devoted servant, one whose mind can comprehend truths that lesser beings fear to acknowledge.$B$BAs a Cultist, you will learn to commune with ancient entities that existed before the first dawn, gaining power through dangerous pacts and eldritch wisdom. Your magic will tap into forces that predate civilization itself.$B$BThis knowledge comes with great risk - the whispers can drive weak minds to madness, and the beings you contact care nothing for mortal concerns. But for those with sufficient mental fortitude, the secrets of the universe itself lie within reach.$B$BListen carefully to what I teach you, for the Old Ones are always watching. Serve them well, and they will grant you power beyond imagination.'),
(52003, 'The fel flames burn within you now and they hunger. You have chosen to become Felsworn, to claim the Legion’s power not in defiance of it, but in mastery. What once sought to enslave you now bends to your will.$B$BAs one of the Felsworn, you will bind demonic essence through domination and pact, tearing infernal allies from the Twisting Nether and chaining them to your command. Every demon you wield is proof of your ascendancy, a weapon forged from corruption itself.$B$BThis path does not balance salvation and damnation. It abandons such illusions entirely. The fel whispers are not temptations, they are truths, offering strength to those ruthless enough to accept it. The weak fall to corruption; the worthy shape it.$B$BRemember why you embraced this power: not for redemption, not for restraint, but for supremacy. Let the fel consume hesitation, mercy, and doubt. May your flames scorch the world until only those strong enough to endure remain.'),
(52004, 'The spirits of protection recognize you as their chosen champion. You have accepted the most noble of callings - to serve as an eternal guardian, placing others'' safety above your own.$B$BAs a Guardian, you will learn to become a living fortress, your defensive techniques creating barriers that no enemy can breach. Your protective magic will shield entire groups from harm while your stalwart presence inspires courage in allied hearts.$B$BThis path demands selfless sacrifice - you will endure pain so others need not, face death so others may live. Glory often passes by those who prevent disaster rather than cause it, but there is no higher honor than preserving innocent lives.$B$BThe Horde has great need of your protection, guardian. Stand ready to defend what matters most.'),
(52005, 'Shadow embraces you while honor guides you. You have chosen the most paradoxical of paths - to wield darkness in service of the light, to become a Knight of Xoroth.$B$BAs a Knight of Xoroth, you will learn to channel void energy and shadow magic while maintaining your moral principles. Your dark techniques will confound enemies expecting holy magic, while your righteous purpose justifies methods others would consider forbidden.$B$BThis path requires absolute moral clarity - you must never let the darkness consume your purpose, even as you draw power from shadow itself. Your oath binds you to protect the innocent through whatever means necessary.$B$BWelcome to the Order, shadow knight. May your dark light guide others through the deepest night.'),
(52006, 'Death recognizes you as its faithful servant, one who understands that endings are merely new beginnings. You have chosen to become a shepherd between worlds.$B$BAs a Necromancer, you will learn to speak with the dead, raise skeletal servants, and manipulate the very essence of life and death. But remember always that this power exists to preserve the natural order, not to mock it.$B$BThe ignorant fear necromancy, seeing only corruption and evil. But true necromancers serve as guardians of the boundary between life and death, ensuring that the dead rest peacefully while their wisdom aids the living when needed.$B$BThe ancestors whisper their approval of your choice. Honor the dead, serve the living, and remember that death is not an enemy to be feared, but a teacher to be respected.'),
(52007, 'The raw elements surge through you with primordial fury! You have chosen to embrace the most fundamental forces of creation itself, becoming a conduit for earth, air, fire, and water in their purest forms.$B$BAs a Primalist, you will learn to command elemental magic with unprecedented power. Your spells will call forth volcanic eruptions, devastating earthquakes, hurricane-force winds, and torrential floods. The very building blocks of reality will answer your call.$B$BThis power comes from the world''s foundation itself, older and more dangerous than any magic devised by mortals. The elements care nothing for civilization - they respond only to strength and respect. Show weakness, and they will consume you.$B$BThe primal forces have accepted you as their champion. May you prove worthy of wielding the fundamental powers that shaped Azeroth itself.'),
(52008, 'Fire dances in recognition of its new master! You have embraced the path of pure destruction and renewal, choosing to become a wielder of elemental flame in its most devastating form.$B$BAs a Pyromancer, you will learn to conjure infernos that burn hotter than dragon''s breath, to rain fire from the heavens that turns battlefields to glass, and to reduce your enemies to ash with but a thought. Flame will be your faithful and terrible servant.$B$BRemember always that fire is both destroyer and creator - it clears dead growth so new life can flourish, purifies corruption, and provides warmth and light to those who need it. Respect its dual nature, and it will serve you well.$B$BThe flames welcome their new master. May your fires burn bright and your enemies burn brighter!'),
(52009, 'The wilderness recognizes one of its own! I can see the wild''s calling in your eyes, the deep connection to nature that marks true Rangers. You have chosen to become a guardian of the untamed lands.$B$BAs a Ranger, you will learn to move unseen through any terrain, to communicate with wild beasts as brothers, and to strike from the shadows with deadly precision. The forests will hide you, the mountains will shelter you, and the animals will aid you.$B$BThis path requires deep respect for the natural world and all its creatures. You will learn to live in harmony with nature while protecting it from those who would exploit or destroy it for selfish gain.$B$BThe spirits of the wild welcome their new protector. May your arrows fly true and your path remain hidden from those who would do harm.'),
(52010, 'Ancient power recognizes your worth! You have chosen to master the oldest form of magic known to thinking beings - the art of runic inscription that binds power into stone and steel.$B$BAs a Runemaster, you will learn to carve magical formulae that outlast the civilizations that created them. Your enchantments will be written into the very fabric of reality, creating effects that endure long after other magic has faded to nothing.$B$BThis art demands absolute precision and patience - a single misplaced line can turn a ward into a weapon, while perfect execution creates wonders that seem impossible. Your tools are simple, but your knowledge must be vast.$B$BThe primordial forces that gave birth to runic magic acknowledge you as worthy. May your inscriptions be flawless and your enchantments eternal.'),
(52011, 'Thunder rolls in recognition of its new champion! The storm spirits have chosen you to wield their fury, to become a master of wind and lightning itself.$B$BAs a Stormbringer, you will learn to summon tempests from clear skies, to call down lightning that can shatter mountains, and to ride the wind itself into battle. The very atmosphere will become your weapon.$B$BStorm magic is raw and untamed, like the tempests themselves. You must learn to harness its fury without being consumed by it, to direct its power without losing yourself in its chaotic nature. Respect the storm, and it will serve you faithfully.$B$BThe tempest spirits welcome their new master. May your lightning never miss its target and your winds carry you swift to victory!'),
(52012, 'The Light embraces you with radiant warmth! You have chosen to become a vessel for divine healing, a beacon of hope in a world too often darkened by conflict and despair.$B$BAs a Sun Cleric, you will learn to channel the pure power of dawn itself, healing wounds that others consider fatal, purifying corruption that has taken root in mortal souls, and calling down cleansing fire that burns only evil.$B$BThis calling demands unwavering compassion and absolute dedication to preserving life. You will exhaust yourself healing strangers, risk your life protecting the innocent, and face darkness that would make lesser souls flee in terror.$B$BThe eternal sun blesses your sacred calling. May your light never dim, and may you always bring hope to those lost in the deepest night.'),
(52013, 'Divine justice flows through you like molten steel! You have sworn the sacred oaths of the Templar, choosing to become a holy warrior in service to righteousness itself.$B$BAs a Templar, you will learn to channel divine power into crushing blows against evil, to heal your allies with blessed magic, and to stand as an unshakeable pillar of faith when darkness threatens to overwhelm the world.$B$BThis calling demands absolute moral clarity and unwavering dedication to justice. You must be judge and executioner, healer and protector, all guided by divine wisdom that transcends mortal understanding.$B$BThe Light itself has chosen you as its champion among the Horde. May your faith be your strength, your conviction your weapon, and your righteousness your eternal guide.'),
(52014, 'Brilliant innovation sparks in your mind! You have chosen to walk the path that bridges magic and machinery, creating wonders that neither art alone could achieve.$B$BAs a Tinker, you will learn to construct devices that aid allies, confound enemies, and demonstrate the power of creative thinking applied to practical problems. Your inventions will show that progress and tradition can work together.$B$BThis path requires both technical knowledge and creative inspiration. You must understand how things work before you can make them work better, but true innovation comes from seeing possibilities that others miss.$B$BThe spirits of invention smile upon your choice. May your devices never malfunction when you need them most, and may your innovations serve the Horde well.'),
(52015, 'The deadly balance flows through your understanding! You have chosen to master the dual nature of toxins - their power to harm and their equal power to heal when properly applied.$B$BAs a Venomancer, you will learn to brew poisons that can fell the mightiest enemies, but also to create antidotes and cures that can save lives others consider beyond hope. Every toxin has its remedy if one understands the principles involved.$B$BThis knowledge carries tremendous responsibility - the same compound that kills a corrupted beast might save a poisoned child. Your wisdom must guide when to unleash death and when to preserve life.$B$BThe natural balance recognizes your understanding. May your venoms strike true against our enemies, and your cures bring healing to our allies.'),
(52016, 'The loa welcome their new voice in the mortal world! You have chosen to serve as vessel for ancestral wisdom, bridging the realm of spirits with the land of the living.$B$BAs a Witch Doctor, you will learn to channel the power of the loa through ritual and sacrifice, to heal with spirit magic and hex your enemies with curses that transcend death itself. The ancestors will guide your hands in both blessing and judgment.$B$BThis sacred calling demands respect for the old ways while adapting to modern needs. You must serve as healer, advisor, and spiritual guide to your people, interpreting the will of the loa for those who cannot hear their voices.$B$BYour magic serves not just individual needs, but the spiritual health of the entire community.$B$BThe ancestral wisdom welcomes its new guardian. May the loa guide your steps, and may your magic serve both the living and the dead with equal reverence.'),
(9302430, 'So Gornek be sendin'' you to Zul’raja. Good.$B$BEvery soul be a crop, mon, and every crop got its season. A reaper learns when to cut and when to let it grow. You gonna swing da scythe for da Horde, and da spirits of da fallen gonna whisper where to strike.$B$BStay close. Da first lesson be waitin'' for you.'),
(200107, ''),
(200020, 'A Blood Wizard?$B$BInteresting...$B$BWell, upon further inspection, this tome is worthless. You can have it.$B$BReturn to me in the future when you are stronger. Maybe we can work together again.'),
(200074, ''),
(200022, 'You may be wondering why I had you retrieve this skull.$B$BDemon skulls are often vessels of immense fel power. Today, I give this to you.$B$BHowever, if you prefer, I can infuse the power of this skull into a powerful sword.$B$BThe choice is yours, whatever it may be, it will serve you well.'),
(200134, ''),
(200135, ''),
(200136, ''),
(200034, 'Good, good. You may be noticing that some would attempt to convince a peon to simply work. Some may even use force, but never lethal.$B$BThese are not options for us, $C. He deserved death, and there will be many more who do as well.$B$BAs a token of your bloody success, I present to you a powerful piece of equipment, forged in helfire. Lok''tar ogar, or something. Aha!'),
(200049, '<The ritual circle pulsates with necromantic energy>'),
(200050, '<The ritual circle begins to erupt. The monster is being summoned>'),
(200051, 'Well, that''s exactly what I thought would happen.$B$BBut, hey, you didn''t die. You''re a better Necromancer already!$B$BHere, I sent my other apprentices to gather the scraps from your battle, they made this.$B$BTake it and get out of my sight.'),
(200162, 'Aha! You have shown me that you are truly powerful. For this, I reward you with a symbol of the Bear itself. May it guide you on your journeys and give you strength over your foes.'),
(200144, ''),
(200008, 'This seems to be the falcon in question, and it seems injured.'),
(200009, 'The falcon seems distraught. It must have been the suspicious creature who attacked it!'),
(200010, 'Thank you for finding Beaky. He has already returned to me, healthy as ever.$B$BI''ve already sent him on yet another scouting mission.$B$B... you''re saying a strange creature was seen near Beaky and that it attacked you? That must have been the creature that injured my boy.$B$BI''ll have to look into this more. Based on your description, whatever this is, it''s not native to Durotar.'),
(200112, ''),
(200095, ''),
(200096, ''),
(200097, ''),
(200080, ''),
(200068, 'Well, this is perfect!$B$BI was able to use this metal to finish a new gun for me and, guess what, I made you one too!$B$BTake it and have a great day!'),
(200026, 'I know you''re wondering why I had you do this.$B$BIn due time, you will learn.$B$BThere is nothing else to worry about now. I''ve made you a similar concoction, take it with you, and use it wisely.$B$BFarewell, $N.'),
(200029, 'Thank you! I feel better now. I can feel da Loa.'),
(200030, 'Hi''bi told me what you did.$B$BI''m proud of you, mon.$B$BTake this.'),
(9302431, 'You may not have expected such a task, $N. But it is important to understand that the Shadowlands call for those who are ready, and knowing when to claim a soul can be just as important as the reclamation of the soul itself.$B$BFor helping our friend out here, I will reward you with these boots. May they serve you well, as they are enchanted to allow you to walk on the surface of water itself.');

DELETE FROM `quest_request_items` WHERE `ID` IN (52000, 52001, 52002, 52003, 52004, 52005, 52006, 52007, 52008, 52009, 52010, 52011, 52012, 52013, 52014, 52015, 52016, 200008, 200009, 200010, 200020, 200022, 200026, 200029, 200030, 200034, 200049, 200050, 200051, 200068, 200074, 200080, 200095, 200096, 200097, 200107, 200112, 200134, 200135, 200136, 200144, 200162, 9302430, 9302431);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(52000, 'I sense the primal fury awakening within you, warrior. So you wish to learn the barbarian''s path of rage and wilderness combat?'),
(52001, 'The crimson arts have called to you, I see. So you wish to master blood magic, to wield life itself as your weapon?'),
(52002, 'The whispers grow stronger in your presence. So you wish to serve the Old Ones and learn the cultist''s forbidden arts?'),
(52003, 'Fel energy radiates from your soul, warrior. So you wish to become Felsworn, to command demonic power?'),
(52004, 'Your protective aura shines brightly, young one. So you wish to become a Guardian, to shield others from all harm?'),
(52005, 'Shadow and honor both call to you, I sense. So you wish to join the Knights of Xoroth, to wield darkness in service of light?'),
(52006, 'The spirits of the dead whisper around you. So you wish to become a Necromancer, to shepherd souls between worlds?'),
(52007, 'The elements respond to your presence, warrior. So you wish to become a Primalist, to command the raw forces of nature?'),
(52008, 'Fire recognizes a kindred spirit in you. So you wish to become a Pyromancer, to master the art of destruction and renewal?'),
(52009, 'The wilderness calls to your heart, wanderer. So you wish to become a Ranger, to protect the wild places of Azeroth?'),
(52010, 'Ancient power stirs in your presence. So you wish to become a Runemaster, to carve magic into stone and steel?'),
(52011, 'Thunder rumbles at your approach, stormcaller. So you wish to become a Stormbringer, to command wind and lightning?'),
(52012, 'Holy light radiates from your being. So you wish to become a Sun Cleric, to heal with the power of dawn?'),
(52013, 'Divine justice burns within you, champion. So you wish to become a Templar, to serve as a holy warrior?'),
(52014, 'Innovation sparks in your mind, builder. So you wish to become a Tinker, to blend magic and machinery?'),
(52015, 'The balance of toxin and antidote calls to you. So you wish to become a Venomancer, to master poison and cure?'),
(52016, 'The loa whisper your name, spirit-walker. So you wish to become a Witch Doctor, to serve as bridge between worlds?'),
(9302430, 'Da harvest be callin'' you, $N. You bring me da letter?'),
(200107, ''),
(200020, 'You be doin'' good, mon. Who did you say had this tome again?'),
(200074, ''),
(200022, 'You have done well, $N.'),
(200134, ''),
(200135, ''),
(200136, ''),
(200034, ''),
(200049, ''),
(200050, '<You place the ingredients on the ritual circle>'),
(200051, ''),
(200162, ''),
(200144, ''),
(200008, ''),
(200009, ''),
(200010, 'Lok''tar, $N. You have done well.'),
(200112, ''),
(200095, ''),
(200096, ''),
(200097, ''),
(200080, ''),
(200068, 'Have you found the scrap yet?'),
(200026, 'Welcome back. Have you done what I asked?'),
(200029, ''),
(200030, ''),
(9302431, '');

-- Map markers the texts promise ("Let me mark your map", "I will mark his location"): the target spawn;
-- the heart of Scorch is item objective 4.
DELETE FROM `quest_poi` WHERE `QuestID` IN (200049, 200144);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200049, 0, 0, 1, 4, 0, 0, 1),
(200144, 0, 4, 1, 4, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` IN (200049, 200144);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200049, 0, 0, -232, -4330),
(200144, 0, 0, -205, -4401);

-- ---------------------------------------------------------------------------
-- 7. Who offers and who takes them back
-- ---------------------------------------------------------------------------
DELETE FROM `creature_queststarter` WHERE `quest` IN (52000, 52001, 52002, 52003, 52004, 52005, 52006, 52007, 52008, 52009, 52010, 52011, 52012, 52013, 52014, 52015, 52016, 200008, 200009, 200010, 200020, 200022, 200026, 200029, 200030, 200034, 200049, 200050, 200051, 200068, 200074, 200080, 200095, 200096, 200097, 200107, 200112, 200134, 200135, 200136, 200144, 200162, 9302430, 9302431);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(3143, 52000),
(3143, 52001),
(3143, 52002),
(3143, 52003),
(3143, 52004),
(3143, 52005),
(3143, 52006),
(3143, 52007),
(3143, 52008),
(3143, 52009),
(3143, 52010),
(3143, 52011),
(3143, 52012),
(3143, 52013),
(3143, 52014),
(3143, 52015),
(3143, 52016),
(502810, 200008),
(9300202, 200009),
(9300202, 200010),
(502921, 200020),
(502760, 200022),
(50288, 200026),
(50296, 200029),
(9300203, 200030),
(50278, 200034),
(502925, 200049),
(502872, 200068),
(502832, 200074),
(9300200, 200080),
(50277, 200095),
(502872, 200096),
(502872, 200097),
(502953, 200107),
(502912, 200112),
(502791, 200134),
(11378, 200135),
(11378, 200136),
(503402, 200144),
(50290, 200162),
(3143, 9302430),
(501296, 9302431);

DELETE FROM `creature_questender` WHERE `quest` IN (52000, 52001, 52002, 52003, 52004, 52005, 52006, 52007, 52008, 52009, 52010, 52011, 52012, 52013, 52014, 52015, 52016, 200008, 200009, 200010, 200020, 200022, 200026, 200029, 200030, 200034, 200049, 200050, 200051, 200068, 200074, 200080, 200095, 200096, 200097, 200107, 200112, 200134, 200135, 200136, 200144, 200162, 9302430, 9302431);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(502953, 52000),
(502921, 52001),
(502832, 52002),
(502760, 52003),
(502791, 52004),
(50278, 52005),
(502925, 52006),
(50290, 52007),
(503402, 52008),
(502810, 52009),
(502912, 52010),
(50277, 52011),
(9300201, 52012),
(9300200, 52013),
(502872, 52014),
(50288, 52015),
(50296, 52016),
(9300202, 200008),
(9300202, 200009),
(502810, 200010),
(502921, 200020),
(502760, 200022),
(50288, 200026),
(9300203, 200029),
(50296, 200030),
(50278, 200034),
(502925, 200051),
(502872, 200068),
(502832, 200074),
(9300200, 200080),
(502872, 200095),
(502872, 200096),
(50277, 200097),
(502953, 200107),
(502912, 200112),
(11378, 200134),
(11378, 200135),
(502791, 200136),
(503402, 200144),
(50290, 200162),
(501296, 9302430),
(501296, 9302431);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (200050, 200051);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(9301200, 200050),
(9301200, 200051);

DELETE FROM `gameobject_questender` WHERE `quest` IN (200049, 200050);
INSERT INTO `gameobject_questender` (`id`, `quest`)
VALUES
(9301200, 200049),
(9301200, 200050);

-- ---------------------------------------------------------------------------
-- 8. Loot
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((3101, 662330), (3101, 458421), (3101, 458422), (3101, 458423), (3101, 661417), (9300204, 661316), (9300205, 662331));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(3101, 662330, 0, 33, 1, 1, 0, 1, 1, 'Vile Familiar - Small Sword (Prioritizing Defense 200135; SOURCED-EXILES 33%)'),
(3101, 458421, 0, 45, 1, 1, 0, 1, 1, 'Vile Familiar - Bones (Death Calls 200050; SOURCED-EXILES 45%)'),
(3101, 458422, 0, 55, 1, 1, 0, 1, 1, 'Vile Familiar - Fresh Flesh (Death Calls 200050; SOURCED-EXILES 55%)'),
(3101, 458423, 0, 55, 1, 1, 0, 1, 1, 'Vile Familiar - Skull (Death Calls 200050; SOURCED-EXILES 55%)'),
(3101, 661417, 0, 33, 1, 1, 0, 1, 1, 'Vile Familiar - Power Core (The Stolen Power Core 200096; SOURCED-EXILES 33%)'),
(9300204, 661316, 0, 100, 1, 1, 0, 1, 1, 'Mysterious Troll - Tome of Blood (Blood Is Power 200020; unique holder)'),
(9300205, 662331, 0, 100, 1, 1, 0, 1, 1, 'Scorch - Heart of Scorch (The Way of the Pyromancer 200144; unique holder)');

DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((3101, 1), (3101, 2), (3101, 3), (3101, 4), (3101, 5), (9300204, 0), (9300205, 0));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(3101, 1, 662330),
(3101, 2, 458421),
(3101, 3, 458422),
(3101, 4, 458423),
(3101, 5, 661417),
(9300204, 0, 661316),
(9300205, 0, 662331);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (9301201, 9301202, 9301203);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9301201, 661320, 0, 100, 1, 1, 0, 1, 1, 'CoA Valley of Trials: quest item from Skull of Kaz'),
(9301202, 661330, 0, 100, 1, 1, 0, 1, 1, 'CoA Valley of Trials: quest item from Eye of the Beholder'),
(9301203, 663320, 0, 100, 1, 1, 0, 1, 1, 'CoA Valley of Trials: quest item from Scrap Metal');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (9301201, 9301202, 9301203);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(9301201, 0, 661320),
(9301202, 0, 661330),
(9301203, 0, 663320);

-- ---------------------------------------------------------------------------
-- 9. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature_addon` WHERE `guid` IN (9003500, 9003501, 9003502, 9003503, 9003504, 9003505, 9003506, 9003507, 9003508, 9003509, 9003510, 9003511, 9003512, 9003513, 9003514, 9003515, 9003516, 9003517, 9003520, 9003521, 9003522, 9003523, 9003524, 9003525, 9003526, 9003527, 9003528, 9003529, 9003530) OR `guid` BETWEEN 9003500 AND 9003699;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(9003522, 0, 0, 3, 0, 0, 0, NULL),
(9003524, 0, 0, 8, 0, 0, 0, NULL),
(9003530, 0, 0, 1, 0, 0, 0, NULL);

DELETE FROM `creature` WHERE `guid` IN (9003500, 9003501, 9003502, 9003503, 9003504, 9003505, 9003506, 9003507, 9003508, 9003509, 9003510, 9003511, 9003512, 9003513, 9003514, 9003515, 9003516, 9003517, 9003520, 9003521, 9003522, 9003523, 9003524, 9003525, 9003526, 9003527, 9003528, 9003529, 9003530) OR `guid` BETWEEN 9003500 AND 9003699;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9003500, 502953, 1, 0, 0, 1, 1, 1, -638.09, -4234.09, 38.135, 5.585, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Barbarian trainer at the SOURCED-CLIENT turn-in point; under the south pavilion, whose west side is closed by Parod''s wagon and the cliffs, so players come in through its open north and north-east sides; the shield rack behind him; faces out of the north-east side straight toward the start, with Tav''vin 93 deg off his left and nothing ahead within 12 yd'),
(9003501, 50296, 1, 0, 0, 1, 1, 1, -559.49, -4220.23, 41.704, 3.05, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Witch Doctor trainer at the SOURCED-CLIENT turn-in point; in the cooking tent between Zlagk, Galgar and the bubbling cauldron; faces south out of the tent and down the slope into the camp, between the path from Gornek and the start, the Cooking Table 32 deg off his right'),
(9003502, 502760, 1, 0, 0, 1, 1, 1, -584.87, -4125.95, 43.846, 4.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Felsworn trainer at the SOURCED-CLIENT turn-in point; inside the den at the mouth of the corridor to the west chamber, the north wall 2 yd behind him; faces the corridor players come through'),
(9003503, 50277, 1, 0, 0, 1, 1, 1, -625.03, -4207.28, 38.135, 0.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Stormbringer trainer at the SOURCED-CLIENT turn-in point; west row of the camp, Mai''ah (kept stock NPC) 2.9 yd to his side; faces the path from Gornek at the den mouth, where the letters are handed out'),
(9003504, 50278, 1, 0, 0, 1, 1, 1, -605.86, -4248.62, 38.956, 1.48, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Knight of Xoroth trainer at the SOURCED-CLIENT turn-in point; by the camp fire north of the start, open ground all round; faces the path from Gornek at the den mouth, where the letters are handed out'),
(9003505, 502791, 1, 0, 0, 1, 1, 1, -569.42, -4274.63, 37.858, 3.05, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Guardian trainer at the SOURCED-CLIENT turn-in point; under the south edge of the tent of the CoA-built Guardian station, the wagon and tool rack behind her and her baskets to her left; faces out of the open south side toward the start, the torch 23 deg off her right'),
(9003506, 9300200, 1, 0, 0, 1, 1, 1, -641.03, -4229.15, 38.135, 5.67, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Templar trainer at the SOURCED-CLIENT turn-in point; under the south pavilion, whose west side is closed by Parod''s wagon and the cliffs, so players come in through its open north and north-east sides; where Frang stood (deleted, 2.03 yd away), near Frang''s stock facing 5.725; looks out of the north-east side toward the start through the gap between Tav''vin and Mu''kaka, each 24 deg off his axis'),
(9003507, 502921, 1, 0, 0, 1, 1, 1, -597.81, -4107.1, 43.847, 5.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Bloodmage trainer at the SOURCED-CLIENT turn-in point; west end of the den''s west chamber, the wall 0.7 yd behind her; faces the chamber and the corridor players enter from'),
(9003508, 502810, 1, 0, 0, 1, 1, 1, -591.5, -4209.8, 39.011, 1.93, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Ranger trainer at the SOURCED-CLIENT turn-in point; 1.8 yd off it under the tree east of the den mouth, clear of the bush; faces the path from Gornek at the den mouth, where the letters are handed out'),
(9003509, 502925, 1, 0, 0, 1, 1, 1, -633.42, -4287.44, 39.825, 1.22, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Necromancer trainer at the SOURCED-CLIENT turn-in point; by the spirit healer''s graveyard ("join me in the graveyard"); faces the camp and the start players come from'),
(9003510, 503402, 1, 0, 0, 1, 1, 1, -601.02, -4246.28, 38.956, 1.56, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Pyromancer trainer at the SOURCED-CLIENT turn-in point; by the camp fire north of the start, 5.4 yd from Spi''ro; faces the path from Gornek at the den mouth, where the letters are handed out'),
(9003511, 502832, 1, 0, 0, 1, 1, 1, -602.88, -4113.34, 43.965, 0.45, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Cultist trainer at the SOURCED-CLIENT turn-in point; south lobe of the den''s west chamber, a pillar 1.1 yd behind her; faces the middle of the chamber where players come in'),
(9003512, 9300201, 1, 0, 0, 1, 1, 1, -619.9, -4313.76, 40.291, 1.48, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Sun Cleric trainer at the SOURCED-CLIENT turn-in point; on the rise 60 yd east of the start, the slope climbing 3 yd behind him; faces the camp and the start'),
(9003513, 502872, 1, 0, 0, 1, 1, 1, -628.63, -4221.71, 38.135, 0.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Tinker trainer at the SOURCED-CLIENT turn-in point; beside his wagon, which stands behind him and to his left; faces the den path toward Gornek, just clear of the wagon shaft (0.89, straight at Gornek, meets it at 5 yd)'),
(9003514, 50288, 1, 0, 0, 1, 1, 1, -558.66, -4195.2, 46.396, 3.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Venomancer trainer at the SOURCED-CLIENT turn-in point; on the slope above the cooking camp, the rock mound south of her; faces the path that runs past the mound down to the camp and Gornek'),
(9003515, 50290, 1, 0, 0, 1, 1, 1, -638.57, -4226.43, 38.137, 0.26, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Primalist trainer at the SOURCED-CLIENT turn-in point; under the south pavilion, whose west side is closed by Parod''s wagon and the cliffs, so players come in through its open north and north-east sides; barrels 1-2 yd behind him; faces north out of the open side, past the east end of Parod''s wagon where the path from Gornek comes in, with Jen''shan more than 30 deg off his right'),
(9003516, 502912, 1, 0, 0, 1, 1, 1, -619.78, -4204.3, 38.135, 0.09, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Runemaster trainer at the SOURCED-CLIENT turn-in point; west row by the jar table; faces north toward the den-mouth side of the camp, where players come down from Gornek, with Ken''jai''s post 3 yd away 33 deg off her left shoulder'),
(9003517, 501296, 1, 0, 0, 1, 1, 1, -627, -4301.5, 40.685, 1.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Reaper trainer at an INFERRED post, the troll burial ground east of the camp, beside the mummified dead and the skull pile, the torches 8 yd off his right; faces the camp and the start players come from'),
(9003520, 299239, 1, 0, 0, 1, 1, 1, -617.39, -4202.4, 38.135, 4.87, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Ken''jai''s stock post outside the den "near the witch doctor" (the quest text), with his stock facing; the stock spawn 4912 is deleted'),
(9003521, 299328, 1, 0, 0, 1, 1, 1, -588.83, -4137.63, 41.57, 4.1, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: the Den, SOURCED-CLIENT 200107 objective point in the corridor; faces the passage from the den mouth'),
(9003522, 299225, 1, 0, 0, 1, 1, 0, -691, -4144, 29.986, 1.22, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: asleep against the rock outcrop in the quiet south-west corner of the valley, far from the lumber piles, scorpids 12 yd away ("Scorpid attack, probably")'),
(9003523, 9300202, 1, 0, 0, 1, 1, 0, -493.5, -4297.5, 42.381, 2.42, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: open ground 3 yd east of the bush cluster in the middle of the valley, scouting; faces back toward Wolfrider Yara'),
(9003524, 9300203, 1, 0, 0, 1, 1, 0, -400, -4450, 51.595, 2.31, 300, 0, 0, 35, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: eastern desert among the scorpids, kneeling by the cactus patch; faces the camp players come from'),
(9003525, 299224, 1, 0, 0, 1, 1, 0, -442, -4466, 51.099, 0.36, 60, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: eastern desert, by the Scorpid Worker 9 yd to the west, facing north-east toward Hi''bi: a standing stalker for anyone whose summoned one is lost, 45 yd from Hi''bi and 42 yd from the summon point, beyond its 20 yd detection, so accepting the quest pulls only the summoned one'),
(9003526, 9300204, 1, 0, 0, 1, 1, 0, -85.55, -4206.95, 49.77, 3.93, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Burning Blade Coven (the imp cave), lower west hall among the Felstalkers, 3.4 yd off the Vile Familiar''s walk through the hall (path 47050); faces the way in from the south-east'),
(9003527, 9300204, 1, 0, 0, 1, 1, 0, -126.08, -4333.2, 64.431, 3.89, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: Burning Blade Coven (the imp cave), east gallery inside the entrance passage, 3.5 yd off the Vile Familiar''s walk along the gallery (path 130620); faces the entrance'),
(9003528, 9300205, 1, 0, 0, 1, 1, 0, -205, -4401, 64.781, 2.39, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: canyon before the Burning Blade Coven, east end, beside the campfire he is bound to, 3.2 yd away; faces the canyon mouth players come through'),
(9003529, 685037, 1, 0, 0, 1, 1, 0, -839, -4250, 88.447, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: southern mountains, on the sheltered shelf 7 yd east of the hidden statue, in sight of anyone who reaches it: the walk-in credit for 200080'),
(9003530, 9300206, 1, 0, 0, 1, 1, 0, -640.5, -4288, 40.066, 5.63, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Valley of Trials: sitting on the open ground at the south-west edge of the troll burial ground, facing the skull pile; 7 yd from Kragar and 10 yd from the spirit healer');

DELETE FROM `gameobject` WHERE `guid` IN (7912300, 7912301, 7912302, 7912303, 7912304, 7912305, 7912306, 7912307, 7912308, 7912309, 7912310, 7912311, 7912312, 7912313, 7912314, 7912315, 7912316, 7912317, 7912318, 7912319, 7912320, 7912321, 7912322, 7912323, 7912324, 7912325, 7912326, 7912327, 7912328) OR `guid` BETWEEN 7912300 AND 7912399;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7912300, 9301200, 1, 0, 0, 1, 1, -232, -4330, 65.055, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Valley of Trials: canyon before the Burning Blade Coven, open flat ground in the middle of the canyon, the Vile Familiars 18-30 yd round it ("the nearby Vile Familiars")'),
(7912301, 1798, 1, 0, 0, 1, 1, -208, -4400, 64.007, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Valley of Trials: canyon before the Burning Blade Coven, east end: the campfire Scorch is bound to ("a campfire near the Burning Blade Coven")'),
(7912302, 9301201, 1, 0, 0, 1, 1, -596, -4128, 73.631, 1.1, 0, 0, 0.522687, 0.852525, 60, 100, 1, '', 'CoA Valley of Trials: hilltop over the den, above the west chamber'),
(7912303, 9301201, 1, 0, 0, 1, 1, -600, -4150, 76.168, 2.6, 0, 0, 0.963558, 0.267499, 60, 100, 1, '', 'CoA Valley of Trials: hilltop over the den, above the exit passage'),
(7912304, 9301202, 1, 0, 0, 1, 1, -603, -4149, 43.336, 0.8, 0, 0, 0.389418, 0.921061, 60, 100, 1, '', 'CoA Valley of Trials: the Den, south passage toward the exit'),
(7912305, 9301202, 1, 0, 0, 1, 1, -610.5, -4104, 42.413, 5.5, 0, 0, 0.381661, -0.924302, 60, 100, 1, '', 'CoA Valley of Trials: the Den, alcove at the south end of the west chamber'),
(7912306, 9301203, 1, 0, 0, 1, 1, -27, -4240, 68.196, 0.4, 0, 0, 0.198669, 0.980067, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), north-west gallery by the far wall'),
(7912307, 9301203, 1, 0, 0, 1, 1, -45, -4318, 68.22, 2.1, 0, 0, 0.867423, 0.497571, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), north-east gallery, on the slope below the wall'),
(7912308, 9301203, 1, 0, 0, 1, 1, -45, -4270, 68.527, 3.3, 0, 0, 0.996865, -0.079121, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), north gallery beside the passage west'),
(7912309, 9301203, 1, 0, 0, 1, 1, -61, -4232, 62.229, 1.6, 0, 0, 0.717356, 0.696707, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), ledge below Yarrog Baneshadow''s alcove'),
(7912310, 9301203, 1, 0, 0, 1, 1, -75, -4210, 50.458, 4.4, 0, 0, 0.808496, -0.588501, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), lower west hall, west wall'),
(7912311, 9301203, 1, 0, 0, 1, 1, -91, -4206, 50.465, 0.9, 0, 0, 0.434966, 0.900447, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), lower west hall, south of the pit'),
(7912312, 9301203, 1, 0, 0, 1, 1, -109, -4246, 53.845, 5.2, 0, 0, 0.515501, -0.856889, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), foot of the ramp from the lower hall'),
(7912313, 9301203, 1, 0, 0, 1, 1, -149, -4256, 60.321, 2.8, 0, 0, 0.98545, 0.169967, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), south-west passage'),
(7912314, 9301203, 1, 0, 0, 1, 1, -129, -4230, 57.409, 3.9, 0, 0, 0.92896, -0.370181, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), south-west chamber by the west wall'),
(7912315, 9301203, 1, 0, 0, 1, 1, -99, -4300, 61.365, 1.2, 0, 0, 0.564642, 0.825336, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), middle hall, near Thazz''ril''s pick'),
(7912316, 9301203, 1, 0, 0, 1, 1, -85, -4326, 65.953, 4.7, 0, 0, 0.711473, -0.702713, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), east hall'),
(7912317, 9301203, 1, 0, 0, 1, 1, -125, -4318, 66.079, 0.3, 0, 0, 0.149438, 0.988771, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), east gallery by the Felstalker den'),
(7912318, 9301203, 1, 0, 0, 1, 1, -145, -4366, 67.602, 5.9, 0, 0, 0.190423, -0.981702, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), just inside the entrance passage'),
(7912319, 9301203, 1, 0, 0, 1, 1, -137, -4300, 65.378, 2.5, 0, 0, 0.948985, 0.315322, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), south gallery above the entrance'),
(7912321, 9301203, 1, 0, 0, 1, 1, -155, -4352, 65.991, 1.4, 0, 0, 0.644218, 0.764842, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), entrance passage, south side'),
(7912322, 9301203, 1, 0, 0, 1, 1, -60, -4335, 68.095, 3.6, 0, 0, 0.973848, -0.227202, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), east gallery by the Felstalker den'),
(7912323, 9301203, 1, 0, 0, 1, 1, -74, -4330, 67.582, 0.7, 0, 0, 0.342898, 0.939373, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), east hall, dry ledge on the south-east shore of the pool, between the east-hall piles'),
(7912324, 9301203, 1, 0, 0, 1, 1, -29, -4262, 66.719, 5, 0, 0, 0.598472, -0.801144, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), north gallery by the passage east'),
(7912325, 9301203, 1, 0, 0, 1, 1, -105, -4210, 54.341, 2.2, 0, 0, 0.891207, 0.453596, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), lower west hall, south part'),
(7912326, 9301203, 1, 0, 0, 1, 1, -121, -4222, 54.671, 4.1, 0, 0, 0.887362, -0.461073, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), south-west chamber, north end'),
(7912327, 9301203, 1, 0, 0, 1, 1, -111, -4300, 62.42, 1.9, 0, 0, 0.813416, 0.581683, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), middle hall, south side'),
(7912328, 9301203, 1, 0, 0, 1, 1, -79, -4272, 50.869, 5.6, 0, 0, 0.334988, -0.942222, 120, 100, 1, '', 'CoA Valley of Trials: Burning Blade Coven (the imp cave), lower hall, east end below the ramp'),
(7912320, 9301204, 1, 0, 0, 1, 1, -840.5, -4243, 88.341, 1.75, 0, 0, 0.767544, 0.640997, 300, 100, 1, '', 'CoA Valley of Trials: southern mountains: a flat shelf 45 yd above the valley floor, walled off from the valley by the ridge to its north ("use your agile movements"); faces west along the shelf, the way the ledge path from the valley comes in');

-- ---------------------------------------------------------------------------
-- 10. Scripts
-- ---------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-9003529, 502925, 9300200, 9300201, 9300202, 9300203, 9300206) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-9003529, 0, 0, 0, 10, 0, 100, 0, 1, 12, 1000, 1000, 1, 0, 33, 685037, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '[KC] Visit - Player in sight within 12 yd - Quest Credit ''A Quiet Life'' at the hidden statue'),
(502925, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685019, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Kragar the Reanimator - On Spellhit ''Poison the World'' - Quest Credit ''Poisoning the World'' (the text''s Nekai the Reanimator)'),
(9300200, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685020, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Omogulg the Truthbearer - On Spellhit ''Poison the World'' - Quest Credit ''Poisoning the World'''),
(9300201, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685018, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Pangajo Sunseer - On Spellhit ''Poison the World'' - Quest Credit ''Poisoning the World'''),
(9300202, 0, 0, 0, 8, 0, 100, 0, 684328, 0, 0, 0, 0, 0, 33, 685011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Beaky - On Spellhit ''Tend Jo''s Wounds'' (Red Vial) - Quest Credit ''Falcons Are Friends'''),
(9300202, 0, 1, 0, 19, 0, 100, 0, 200009, 0, 0, 0, 0, 0, 12, 299222, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -488.5, -4296.5, 43.11, 2.42, 'Beaky - On Quest ''A Surprise Attack!'' Accepted - Summon Suspicious Creature from the bushes, attacking the invoker'),
(9300203, 0, 0, 0, 8, 0, 100, 0, 801670, 0, 0, 0, 0, 0, 33, 685021, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hi''bi Ja''min - On Spellhit ''Loa''s Brew'' Rank 1 - Quest Credit ''The Doctor Is In!'''),
(9300203, 0, 1, 0, 19, 0, 100, 0, 200030, 0, 0, 0, 0, 0, 12, 299224, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -406, -4444, 50.46, 0.35, 'Hi''bi Ja''min - On Quest ''Who Called For Da Docta?'' Accepted - Summon Scorpid Stalker behind the player, attacking the invoker'),
(9300206, 0, 0, 0, 62, 0, 100, 0, 930303, 0, 0, 0, 0, 0, 33, 685022, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Brokthar - On Gossip Option 0 Selected - Quest Credit ''Call of the Shadowlands''');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9301200 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(9301200, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 685121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Gossip Hello - Quest Credit ''Call of Death'''),
(9301200, 1, 1, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -228.5, -4334.5, 64.69, 2.24, 'Ritual Circle - On Gossip Hello - Summon the Undead Monstrosity, attacking the invoker');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 9301200 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 1, 9301200, 1, 0, 9, 0, 200049, 0, 0, 0, 0, 0, '', 'Ritual Circle - credit only while ''Call of Death'' is taken'),
(22, 2, 9301200, 1, 0, 9, 0, 200051, 0, 0, 0, 0, 0, '', 'Ritual Circle - summon only while ''Call of the Dead'' is taken'),
(22, 2, 9301200, 1, 0, 29, 1, 299232, 30, 0, 1, 0, 0, '', 'Ritual Circle - summon only when no living Undead Monstrosity is within 30 yd');
