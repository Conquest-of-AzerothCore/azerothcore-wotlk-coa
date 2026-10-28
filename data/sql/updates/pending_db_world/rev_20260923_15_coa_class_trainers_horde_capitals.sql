-- Conquest of Azeroth class trainers in the Horde capitals: the Orgrimmar (15), Undercity (18) and Thunder
-- Bluff (7) twins of the starting-zone trainers. Each trainer is a core class trainer (trainer 900000 +
-- class and its menu 930000 + class from migration 05) with a look, weapons and a hand-checked post.
--
-- WHERE EACH VALUE COMES FROM
--   entries, names and titles  SOURCED-CACHE creaturecache; which capital a twin serves is INFERRED from the
--     6-prefix twin pattern and the cache capture counts (research/class-trainers/trainers.md). The
--     Undercity Barbarian 602951 is only in the coa-alpha capture of the union cache (2026-02-22), also in
--     the stock-client creature list and the Exiles export; undead may be Barbarians in CharBaseInfo.dbc.
--   posts  INFERRED: no source gives a capital trainer position. Every post was hand-picked in the stock
--     hall of a related class or at a landmark that suits the class, checked with surface.check on the
--     server floor, and kept at least 2.5 yd from every stock NPC (the stock class trainers keep their
--     posts). No stock spawn is deleted or moved here.
--   facings  toward where players stand or come in (reason per post below). Rays at 0.3, 0.7, 1.0 and
--     1.6 yd find no wall or prop within 5 yd straight ahead; the only low hits are the fire-pit rim, ramp
--     or rising floor a trainer faces. No post is in a kept NPC's front space (within 8 yd and 30 deg of
--     its facing): a trainer that joins a stock NPC stands beside it, not in its line.
--   looks  stand-ins: no SMSG_MIRRORIMAGE_DATA capture of any trainer exists and the cache display ids
--     do not resolve. Each look copies a stock NPC of the right race, sex and theme
--     (CreatureDisplayInfoExtra), restyled within the player ranges, with one or two armor pieces
--     swapped. Race and sex are INFERRED from the name, title, text and city.
--   weapons  Item.dbc items of an inventory type the core accepts in that hand.
--   gossip  the class menu from migration 05, except Zulaka'jin and Zerin'dai, whose own cached
--     greetings (npccache 687578, 205872) get their own menus with a troll-voiced class refusal (npccache
--     287574 for Zulaka'jin; the class refusal 175441 already is) and the training option.
--
-- Blocks: creature guids 9004650-9004799, gossip menus 930650-930699.

-- ---------------------------------------------------------------------------
-- 1. Trainer templates (level 60, the city faction, gossip + trainer + class trainer)
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(503925, 'Deathmagus Gorat', 'Necromancer Trainer', 930023, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503930, 'Kobidus the Lich', 'Necromancer Trainer', 930023, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(600242, 'Sunwalker Modae', 'Sun Cleric Trainer', 930027, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602760, 'Xantis the Slayer', 'Felsworn Trainer', 930014, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602773, 'Harold Garett', 'Stormbringer Trainer', 930016, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602781, 'Galgrimorth', 'Knight of Xoroth Trainer', 930017, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602790, 'Gohok Bighoof', 'Guardian Trainer', 930018, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602791, 'Grunt Korthaka', 'Guardian Trainer', 930018, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602803, 'Benjamin the Sinless', 'Templar Trainer', 930019, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602810, 'Grok-gar', 'Ranger Trainer', 930021, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602822, 'Nyrmedormi', 'Chronomancer Trainer', 930022, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602832, 'Rokia Lohka', 'Cultist Trainer', 930025, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602833, 'Vytalas the Dreamer', 'Cultist Trainer', 930025, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602834, 'Wuyi Thunderhoof', 'Cultist Trainer', 930025, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602850, 'Fal''ador Yanille', 'Starcaller Trainer', 930026, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602872, 'Engineer Rothakk', 'Tinker Trainer', 930028, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602873, 'Ol'' Jimbles', 'Tinker Trainer', 930028, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602891, 'Sidus the Soul-Collector', 'Reaper Trainer', 930030, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602900, 'Ear-he Stonehoof', 'Primalist Trainer', 930031, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602912, 'Washu Zebuljin', 'Runemaster Trainer', 930032, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602913, 'Thalen Mackenzie', 'Runemaster Trainer', 930032, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602921, 'Sul''natu Hearteater', 'Bloodmage Trainer', 930020, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602922, 'Belinaros Cicero', 'Bloodmage Trainer', 930020, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602950, 'Thokor Galanthoof', 'Barbarian Trainer', 930012, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602951, 'Ray''chelle Greenhill', 'Barbarian Trainer', 930012, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602953, 'Zulaka''jin', 'Barbarian Trainer', 930650, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(603402, 'Murthakk Krulk', 'Pyromancer Trainer', 930024, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(612912, 'Kodor the Seer', 'Runemaster Trainer', 930032, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650275, 'Phineas the Fervent', 'Witch Hunter Trainer', 930015, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650276, 'Thimakria Dilanore', 'Felsworn Trainer', 930014, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650277, 'Darakka Stormsworn', 'Stormbringer Trainer', 930016, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650278, 'Xevaroth', 'Knight of Xoroth Trainer', 930017, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650279, 'Deathguard Solor', 'Guardian Trainer', 930018, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650281, 'Sigi Mikayla', 'Ranger Trainer', 930021, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650285, 'Zoona', 'Starcaller Trainer', 930026, 60, 60, 0, 104, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650288, 'Wun''zujek', 'Venomancer Trainer', 930029, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650290, 'Thako Maz', 'Primalist Trainer', 930031, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650293, 'Ridley of Lordaeron', 'Pyromancer Trainer', 930024, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650296, 'Zerin''dai', 'Witch Doctor Trainer', 930651, 60, 60, 0, 29, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650327, 'Lightspeaker Shaylan', 'Sun Cleric Trainer', 930027, 60, 60, 0, 68, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

-- ---------------------------------------------------------------------------
-- 2. Looks, weapons and class trainer links
-- ---------------------------------------------------------------------------
-- 602953 Zulaka'jin, Barbarian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: troll
--   male from Horde Berserker (26799) (display 24358), changed skin 2, face 3, hair 4, haircolor 2, facialhair 5;
--   shoulders of the Darkspear Warrior (40241); race INFERRED from his own cached text speaks of the jungles and
--   his tribe (npccache 687578); weapons 30848
-- 602791 Grunt Korthaka, Guardian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   orc male from Orgrimmar Elite Shieldguard (15852) (display 15821), changed skin 2, face 7, hair 3, haircolor
--   3, facialhair 1; bare-headed, with the Horde tabard of Blood Guard Gulmok (21359); race INFERRED from "Grunt"
--   is the orc army rank; weapons 10612/21549
-- 602810 Grok-gar, Ranger: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: orc male
--   from Warsong Scout (25439) (display 23195), changed skin 3, face 8, hair 4, haircolor 6, facialhair 8; cloak
--   of the Spirit Hunter (21332), no tabard; race INFERRED from orc name; weapons 12348/5260
-- 602872 Engineer Rothakk, Tinker: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   orc male from Mukdrak (11025) (display 10570), changed skin 2, face 1, hair 2, haircolor 3, facialhair 0;
--   engineering goggles on the head; race INFERRED from orc name, among the orc engineers of the shop; weapons
--   1911
-- 650278 Xevaroth, Knight of Xoroth: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   orc male from Cabal Deathsworn (18635) (display 18590), changed skin 1, face 5, hair 5, haircolor 0,
--   facialhair 2; chest and gloves of the Death Knight (16146); race INFERRED from the Orgrimmar twin pattern
--   (Valley of Trials start); weapons 14535
-- 503925 Deathmagus Gorat, Necromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: orc male from Orc Necrolyte (21747) (display 16267), changed skin 7, face 3, hair 0, haircolor 7,
--   facialhair 10; shoulders of the Orc Warlock (21750); race INFERRED from orc name; weapons 11365
-- 602760 Xantis the Slayer, Felsworn: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   orc male from Burning Blade Crusher (12320) (display 4199), changed skin 4, face 6, hair 2, haircolor 1,
--   facialhair 3; helm and shoulders of the Fel Corrupter (21300); race INFERRED from the Orgrimmar twin pattern
--   (Valley of Trials start); weapons 12482/12502
-- 602832 Rokia Lohka, Cultist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: orc
--   female from Twilight Apostle (30179) (display 27371), changed skin 5, face 6, hair 3, haircolor 6, facialhair
--   2; no hood and no Twilight's Hammer tabard; race INFERRED from orc name; weapons 2559
-- 650296 Zerin'dai, Witch Doctor: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   troll male from Horde Witch Doctor (17935) (display 17336), changed skin 3, face 4, hair 5, haircolor 6,
--   facialhair 8; leggings of T'chali the Witch Doctor (21349); race INFERRED from his cached text is in troll
--   dialect (npccache 205872); weapons 19214
-- 650288 Wun'zujek, Venomancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: troll
--   male from Shadow Hunter Denjai (18013) (display 17416), changed skin 5, face 1, hair 4, haircolor 3,
--   facialhair 6; helm of Najak Hexxen (14185); race INFERRED from troll name (the -jek ending); weapons
--   12991/10617
-- 650277 Darakka Stormsworn, Stormbringer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: orc female from Warsong Shaman (11683) (display 11865), changed skin 6, face 4, hair 6, haircolor 2,
--   facialhair 3; helm of the Frostwolf Shaman (13284); race INFERRED from orc name; weapons 5303
-- 650290 Thako Maz, Primalist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: troll
--   male from Darkspear Shaman (15863) (display 15840), changed skin 0, face 2, hair 2, haircolor 5, facialhair 3;
--   bare-headed; race INFERRED from troll name; weapons 2810/13628
-- 603402 Murthakk Krulk, Pyromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   orc male from Searing Blade Warlock (11324) (display 11438), changed skin 5, face 2, hair 6, haircolor 4,
--   facialhair 4; shoulders and cloak of the Twilight Flameguard (25866); race INFERRED from orc name; weapons
--   12937
-- 602921 Sul'natu Hearteater, Bloodmage: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: troll female from Hakkari Blood Priest (11340) (display 11223), changed skin 4, face 5, hair 3,
--   haircolor 7, facialhair 2; hood of the Hakkari Shadowcaster (11338); race INFERRED from troll name
--   ("Hearteater"); weapons 13336
-- 602912 Washu Zebuljin, Runemaster: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   troll female from Seer Janidi (18017) (display 17420), changed skin 2, face 1, hair 4, haircolor 3, facialhair
--   3; shoulders and bracers of Priestess Kara'van (11411); race INFERRED from the cached name Zebuljin has the
--   troll -jin ending (Vol'jin, Sen'jin); kept although trolls lacked Runemaster as players (RACE-CLASS.md binds
--   player pairs, the name is this NPC's own evidence); weapons 13723
-- 650276 Thimakria Dilanore, Felsworn: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf female from Sunblade Warlock (24686) (display 23100), changed skin 4, face 6, hair 10,
--   haircolor 7, facialhair 3; bare-headed, shoulders of the Fel Corrupter (21300); race INFERRED from Felsworn is
--   a blood elf class, not an undead one (RACE-CLASS.md), as ct-deathknell made her Deathknell twin Dar'danis;
--   weapons 5597/10296
-- 503930 Kobidus the Lich, Necromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead male from Grand Necrolord Antiok (28006) (display 25006), changed skin 5, face 9, hair 0,
--   haircolor 0, facialhair 15; shoulders of the Death Knight (16146); race INFERRED from "the Lich"; weapons
--   39743
-- 602913 Thalen Mackenzie, Runemaster: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead male from Undercity Mage (18971) (display 18454), changed skin 4, face 0, hair 9, haircolor 2,
--   facialhair 11; no shoulders; race INFERRED from human name, Undercity; weapons 13050
-- 602822 Nyrmedormi, Chronomancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   blood elf female from Alurmi, Keepers of Time (21643) (display 20384), changed skin 5, face 3, hair 11,
--   haircolor 6, facialhair 4; leggings of Magistrix Elosai (17093); race INFERRED from the -dormi name is a
--   bronze dragon, and the Keepers of Time wear blood elf visages; weapons 43093
-- 602922 Belinaros Cicero, Bloodmage: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   blood elf male from Bloodmage (19258) (display 18675), changed skin 2, face 6, hair 3, haircolor 8, facialhair
--   4; red robe mantle 2178 (Magister Astalor Bloodsworn's texture); race INFERRED from elf-style name
--   (trainers.md); weapons 28739
-- 650293 Ridley of Lordaeron, Pyromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead male from Cain Firesong (2128) (display 1600), changed skin 3, face 1, hair 2, haircolor 5,
--   facialhair 4; helm of the Twilight Flameguard (25866); race INFERRED from "of Lordaeron"; weapons 5277
-- 650279 Deathguard Solor, Guardian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   undead male from Vengeance Landing Deathguard (23779) (display 21749), changed skin 0, face 3, hair 6,
--   haircolor 5, facialhair 1; helm of the Vengeance Landing Deathguard (21748); race INFERRED from "Deathguard";
--   weapons 18167/18166
-- 602781 Galgrimorth, Knight of Xoroth: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf male from Dread Commander Thalanor (29587) (display 25496), changed skin 7, face 4, hair 5,
--   haircolor 0, facialhair 2; helm of the Champion Reaver (13531); race INFERRED from Knight of Xoroth is a blood
--   elf class, not an undead one (RACE-CLASS.md), as ct-deathknell made the Deathknell Knight Brallmular; weapons
--   41259
-- 602803 Benjamin the Sinless, Templar: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead male from Royal Dreadguard (13839) (display 13807), changed skin 2, face 8, hair 7, haircolor
--   4, facialhair 14; bare-headed, shoulders of the Vengeance Landing Deathguard (21748); race INFERRED from human
--   name, Undercity; weapons 25160
-- 602850 Fal'ador Yanille, Starcaller: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf male from Sunseeker Astromage (19168) (display 17918), changed skin 6, face 2, hair 8,
--   haircolor 1, facialhair 0; bare-headed; race INFERRED from elf-style name (trainers.md); weapons 43617
-- 602833 Vytalas the Dreamer, Cultist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead female from Shadow Priestess Vandis (11055) (display 10550), changed skin 1, face 4, hair 5,
--   haircolor 0, facialhair 2; hood of Willow (13656); race INFERRED from the Undercity twin pattern (Deathknell
--   start); weapons 19924
-- 650327 Lightspeaker Shaylan, Sun Cleric: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: blood elf female from Solarium Priest (18806) (display 19050), changed skin 1, face 7, hair 12,
--   haircolor 4, facialhair 7; bare-headed; race INFERRED from "Lightspeaker" and an elf-style name (trainers.md);
--   weapons 28738
-- 650281 Sigi Mikayla, Ranger: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: undead
--   female from Tranquillien Scout (16242) (display 16092), changed skin 4, face 1, hair 8, haircolor 6,
--   facialhair 5; gloves and bracers of Deathstalker Faerleia (2058); race INFERRED from the Undercity twin
--   pattern (Deathknell start); weapons 1896/14118
-- 650275 Phineas the Fervent, Witch Hunter: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead male from Deathstalker Hayward (24768) (display 22632), changed skin 1, face 2, hair 3,
--   haircolor 7, facialhair 12; chest of Deathstalker Razael (23998); race INFERRED from human name, Undercity;
--   weapons 46957/15809
-- 602773 Harold Garett, Stormbringer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   undead male from Deathguard Fowles, The Thundercaller (25079) (display 1647), changed skin 2, face 4, hair 5,
--   haircolor 3, facialhair 9; bare-headed, without the source's rifle; race INFERRED from human name, Undercity;
--   weapons 810
-- 602873 Ol' Jimbles, Tinker: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: undead
--   male from Engineer Burke (27379) (display 24598), changed skin 5, face 6, hair 1, haircolor 9, facialhair 7;
--   goggles, no tabard; race INFERRED from "Ol'", an old man; weapons 5324
-- 602891 Sidus the Soul-Collector, Reaper: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead male from Shadowstalker Getry (25729) (display 23335), changed skin 1, face 6, hair 0,
--   haircolor 3, facialhair 8; shoulders of Deathstalker Razael (23998); race INFERRED from the Undercity twin
--   pattern (Deathknell start); weapons 25236
-- 602951 Ray'chelle Greenhill, Barbarian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: undead female from Angela Curthas (4594) (display 2658), changed skin 4, face 3, hair 7, haircolor 2,
--   facialhair 1; bare hands, spiked Horde leather shoulders (8316); race INFERRED from the Undercity twin pattern
--   (602951 is the one capital Barbarian twin left beside 602950, 602952, 602953 and 650295, and Undercity the
--   only Barbarian-race capital without one, RACE-CLASS.md) and the human family name Greenhill; female by her
--   first name; weapons 3198
-- 602950 Thokor Galanthoof, Barbarian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: tauren male from Tauren Warrior (17933) (display 17332), changed skin 5, face 1, hair 6, haircolor 2,
--   facialhair 2; shoulders of the Tauren Warrior (19601); race INFERRED from "-hoof" family name; weapons 14084
-- 602790 Gohok Bighoof, Guardian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   tauren male from Champion Guardian (13421) (display 13364), changed skin 9, face 4, hair 1, haircolor 0,
--   facialhair 4; bare-headed; race INFERRED from "-hoof" family name; weapons 10614/11589
-- 602900 Ear-he Stonehoof, Primalist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   tauren female from Tauren Primalist (15856) (display 15830), changed skin 4, face 3, hair 6, haircolor 1,
--   facialhair 4; gloves of the Might of Kalimdor Druid (15849); race INFERRED from "Stonehoof" family name;
--   weapons 13337
-- 650285 Zoona, Starcaller: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: tauren
--   female from Moorah Stormhoof (1409) (display 4375), changed skin 6, face 2, hair 2, haircolor 2, facialhair 1;
--   leggings of the Might of Kalimdor Druid (15849); race INFERRED from the Thunder Bluff twin pattern (Camp
--   Narache start); weapons 1908
-- 600242 Sunwalker Modae, Sun Cleric: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   tauren female from Champion Warrior (13428) (display 13368), changed skin 1, face 3, hair 5, haircolor 0,
--   facialhair 2; bare-headed; race INFERRED from "Sunwalker" is the tauren sun order; weapons 2079/13319
-- 612912 Kodor the Seer, Runemaster: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   tauren male from Seer Wiserunner (2984) (display 3815), changed skin 12, face 0, hair 3, haircolor 1,
--   facialhair 0; leggings and boots of Elder Skyseer (15584); race INFERRED from "the Seer", a tauren title;
--   weapons 11542
-- 602834 Wuyi Thunderhoof, Cultist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   tauren female from Fallen Druid (18490) (display 17850), changed skin 3, face 2, hair 4, haircolor 1,
--   facialhair 3; shoulders of the Twilight Apostle (30179); race INFERRED from "Thunderhoof" family name; weapons
--   12943
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (503925, 503930, 600242, 602760, 602773, 602781, 602790, 602791, 602803, 602810, 602822, 602832, 602833, 602834, 602850, 602872, 602873, 602891, 602900, 602912, 602913, 602921, 602922, 602950, 602951, 602953, 603402, 612912, 650275, 650276, 650277, 650278, 650279, 650281, 650285, 650288, 650290, 650293, 650296, 650327);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(503925, 0, 51, 1, 1),
(503930, 0, 57, 1, 1),
(600242, 0, 60, 1, 1),
(602760, 0, 51, 1, 1),
(602773, 0, 57, 1, 1),
(602781, 0, 15476, 1, 1),
(602790, 0, 59, 1, 1),
(602791, 0, 51, 1, 1),
(602803, 0, 57, 1, 1),
(602810, 0, 51, 1, 1),
(602822, 0, 15475, 1, 1),
(602832, 0, 52, 1, 1),
(602833, 0, 58, 1, 1),
(602834, 0, 60, 1, 1),
(602850, 0, 15476, 1, 1),
(602872, 0, 51, 1, 1),
(602873, 0, 57, 1, 1),
(602891, 0, 57, 1, 1),
(602900, 0, 60, 1, 1),
(602912, 0, 1479, 1, 1),
(602913, 0, 57, 1, 1),
(602921, 0, 1479, 1, 1),
(602922, 0, 15476, 1, 1),
(602950, 0, 59, 1, 1),
(602951, 0, 58, 1, 1),
(602953, 0, 1478, 1, 1),
(603402, 0, 51, 1, 1),
(612912, 0, 59, 1, 1),
(650275, 0, 57, 1, 1),
(650276, 0, 15475, 1, 1),
(650277, 0, 52, 1, 1),
(650278, 0, 51, 1, 1),
(650279, 0, 57, 1, 1),
(650281, 0, 58, 1, 1),
(650285, 0, 60, 1, 1),
(650288, 0, 1478, 1, 1),
(650290, 0, 1478, 1, 1),
(650293, 0, 57, 1, 1),
(650296, 0, 1478, 1, 1),
(650327, 0, 15475, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (503925, 503930, 600242, 602760, 602773, 602781, 602790, 602791, 602803, 602810, 602822, 602832, 602833, 602834, 602850, 602872, 602873, 602891, 602900, 602912, 602913, 602921, 602922, 602950, 602951, 602953, 603402, 612912, 650275, 650276, 650277, 650278, 650279, 650281, 650285, 650288, 650290, 650293, 650296, 650327);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(503925, 51, 2, 0, 1, 7, 3, 0, 7, 10, 0, 11971, 27305, 0, 8471, 8565, 8472, 6214, 28642, 5628, 0, 0),
(503930, 57, 5, 0, 1, 5, 9, 0, 0, 15, 0, 164307, 146874, 0, 164306, 164309, 164310, 164311, 0, 164312, 0, 0),
(600242, 60, 6, 1, 1, 1, 3, 5, 0, 2, 0, 0, 164039, 164037, 164036, 164935, 164041, 164042, 164043, 164044, 0, 0),
(602760, 51, 2, 0, 1, 4, 6, 2, 1, 3, 0, 145537, 146607, 0, 147337, 150407, 152371, 154571, 0, 157026, 0, 0),
(602773, 57, 5, 0, 1, 2, 4, 5, 3, 9, 0, 0, 0, 0, 3522, 3523, 3524, 3616, 3526, 3527, 0, 0),
(602781, 15476, 10, 0, 1, 7, 4, 5, 0, 2, 0, 164094, 43880, 0, 43881, 43882, 43883, 43884, 0, 43885, 41450, 0),
(602790, 59, 6, 0, 1, 9, 4, 1, 0, 4, 0, 0, 163640, 0, 163638, 163641, 163642, 163643, 163644, 163645, 0, 0),
(602791, 51, 2, 0, 1, 2, 7, 3, 3, 1, 0, 0, 24098, 8079, 20025, 24099, 20027, 24100, 0, 24101, 0, 29110),
(602803, 57, 5, 0, 1, 2, 8, 7, 4, 14, 0, 0, 146685, 24067, 0, 24068, 24069, 24070, 0, 24071, 0, 0),
(602810, 51, 2, 0, 1, 3, 8, 4, 6, 8, 0, 0, 41139, 0, 40465, 40466, 40467, 41140, 0, 40469, 27521, 0),
(602822, 15475, 10, 1, 1, 5, 3, 11, 6, 4, 0, 0, 17734, 0, 35478, 0, 29555, 1045, 0, 0, 0, 36122),
(602832, 52, 2, 1, 1, 5, 6, 3, 6, 2, 0, 0, 146933, 148391, 149983, 151866, 154060, 156066, 156693, 158214, 0, 0),
(602833, 58, 5, 1, 1, 1, 4, 5, 0, 2, 0, 16516, 18653, 18644, 3262, 5155, 6772, 16666, 0, 18652, 0, 0),
(602834, 60, 6, 1, 1, 3, 2, 4, 1, 3, 0, 0, 146933, 0, 23488, 25104, 23489, 0, 25107, 0, 0, 0),
(602850, 15476, 10, 0, 1, 6, 2, 8, 1, 0, 0, 0, 6705, 0, 149316, 151212, 153292, 155392, 0, 0, 0, 0),
(602872, 51, 2, 0, 1, 2, 1, 2, 3, 0, 0, 2378, 0, 3836, 5459, 0, 3439, 9143, 0, 4941, 0, 0),
(602873, 57, 5, 0, 1, 5, 6, 1, 9, 7, 0, 8997, 0, 41911, 23162, 3408, 19809, 5585, 0, 0, 0, 0),
(602891, 57, 5, 0, 1, 1, 6, 0, 3, 8, 0, 35413, 146707, 0, 35412, 36357, 35414, 36358, 0, 36359, 0, 0),
(602900, 60, 6, 1, 1, 4, 3, 6, 1, 4, 0, 232, 0, 7106, 0, 6277, 6278, 6279, 0, 12567, 0, 0),
(602912, 1479, 8, 1, 1, 2, 1, 4, 3, 3, 0, 0, 12073, 0, 17632, 23998, 23995, 0, 19181, 23999, 0, 0),
(602913, 57, 5, 0, 1, 4, 0, 9, 2, 11, 0, 0, 0, 0, 25792, 25793, 25794, 25795, 0, 24543, 0, 0),
(602921, 1479, 8, 1, 1, 4, 5, 3, 7, 2, 0, 145320, 146277, 147863, 149047, 150925, 152967, 0, 0, 157502, 0, 0),
(602922, 15476, 10, 0, 1, 2, 6, 3, 8, 4, 0, 0, 2178, 0, 16572, 6076, 6199, 31655, 0, 0, 0, 0),
(602950, 59, 6, 0, 1, 5, 1, 6, 2, 2, 0, 0, 27527, 5533, 0, 5338, 5475, 0, 0, 0, 0, 0),
(602951, 58, 5, 1, 1, 4, 3, 7, 2, 1, 0, 0, 8316, 6237, 0, 6238, 2038, 4237, 0, 0, 0, 0),
(602953, 1478, 8, 0, 1, 2, 3, 4, 2, 5, 0, 164265, 46411, 0, 164264, 164935, 164268, 164303, 0, 164304, 0, 0),
(603402, 51, 2, 0, 1, 5, 2, 6, 4, 4, 0, 145327, 146769, 0, 148789, 150938, 152982, 155139, 0, 157516, 158736, 0),
(612912, 59, 6, 0, 1, 12, 0, 3, 1, 0, 0, 0, 0, 5503, 0, 8066, 26794, 26793, 0, 7176, 0, 0),
(650275, 57, 5, 0, 1, 1, 2, 3, 7, 12, 0, 0, 40388, 0, 6748, 5091, 679, 38953, 0, 5094, 0, 0),
(650276, 15475, 10, 1, 1, 4, 6, 10, 7, 3, 0, 0, 146607, 0, 149738, 151624, 153764, 155804, 0, 158008, 0, 0),
(650277, 52, 2, 1, 1, 6, 4, 6, 2, 3, 0, 145349, 146307, 0, 147895, 150960, 153007, 155162, 0, 157536, 0, 0),
(650278, 51, 2, 0, 1, 1, 5, 5, 0, 2, 0, 145486, 146529, 0, 149897, 0, 31578, 155452, 0, 158146, 0, 0),
(650279, 57, 5, 0, 1, 0, 3, 6, 5, 1, 0, 145591, 146685, 0, 149626, 151480, 153611, 155665, 0, 157914, 0, 0),
(650281, 58, 5, 1, 1, 4, 1, 8, 6, 5, 0, 0, 0, 0, 9467, 13258, 6656, 14051, 3679, 3680, 0, 0),
(650285, 60, 6, 1, 1, 6, 2, 2, 2, 1, 0, 0, 0, 9134, 8079, 6442, 9112, 0, 0, 6514, 0, 0),
(650288, 1478, 8, 0, 1, 5, 1, 4, 3, 6, 0, 145378, 25465, 0, 30214, 28692, 25487, 0, 0, 30215, 0, 0),
(650290, 1478, 8, 0, 1, 0, 2, 2, 5, 3, 0, 0, 5224, 20707, 7106, 8776, 20705, 0, 0, 19623, 0, 0),
(650293, 57, 5, 0, 1, 3, 1, 2, 5, 4, 0, 145648, 0, 2913, 5490, 3246, 5289, 18150, 3118, 17322, 0, 0),
(650296, 1478, 8, 0, 1, 3, 4, 5, 6, 8, 0, 145082, 0, 147400, 148721, 150467, 24988, 0, 156256, 6411, 0, 0),
(650327, 15475, 10, 1, 1, 1, 7, 12, 4, 7, 0, 0, 146557, 0, 25813, 0, 25815, 155482, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (503925, 503930, 600242, 602760, 602773, 602781, 602790, 602791, 602803, 602810, 602822, 602832, 602833, 602834, 602850, 602872, 602873, 602891, 602900, 602912, 602913, 602921, 602922, 602950, 602951, 602953, 603402, 612912, 650275, 650276, 650277, 650278, 650279, 650281, 650285, 650288, 650290, 650293, 650296, 650327);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(503925, 1, 11365, 0, 0),
(503930, 1, 39743, 0, 0),
(600242, 1, 2079, 13319, 0),
(602760, 1, 12482, 12502, 0),
(602773, 1, 810, 0, 0),
(602781, 1, 41259, 0, 0),
(602790, 1, 10614, 11589, 0),
(602791, 1, 10612, 21549, 0),
(602803, 1, 25160, 0, 0),
(602810, 1, 12348, 0, 5260),
(602822, 1, 43093, 0, 0),
(602832, 1, 2559, 0, 0),
(602833, 1, 19924, 0, 0),
(602834, 1, 12943, 0, 0),
(602850, 1, 43617, 0, 0),
(602872, 1, 1911, 0, 0),
(602873, 1, 5324, 0, 0),
(602891, 1, 25236, 0, 0),
(602900, 1, 13337, 0, 0),
(602912, 1, 13723, 0, 0),
(602913, 1, 13050, 0, 0),
(602921, 1, 13336, 0, 0),
(602922, 1, 28739, 0, 0),
(602950, 1, 14084, 0, 0),
(602951, 1, 3198, 0, 0),
(602953, 1, 30848, 0, 0),
(603402, 1, 12937, 0, 0),
(612912, 1, 11542, 0, 0),
(650275, 1, 46957, 0, 15809),
(650276, 1, 5597, 10296, 0),
(650277, 1, 5303, 0, 0),
(650278, 1, 14535, 0, 0),
(650279, 1, 18167, 18166, 0),
(650281, 1, 1896, 0, 14118),
(650285, 1, 1908, 0, 0),
(650288, 1, 12991, 10617, 0),
(650290, 1, 2810, 13628, 0),
(650293, 1, 5277, 0, 0),
(650296, 1, 19214, 0, 0),
(650327, 1, 28738, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (503925, 503930, 600242, 602760, 602773, 602781, 602790, 602791, 602803, 602810, 602822, 602832, 602833, 602834, 602850, 602872, 602873, 602891, 602900, 602912, 602913, 602921, 602922, 602950, 602951, 602953, 603402, 612912, 650275, 650276, 650277, 650278, 650279, 650281, 650285, 650288, 650290, 650293, 650296, 650327);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(503925, 900023),
(503930, 900023),
(600242, 900027),
(602760, 900014),
(602773, 900016),
(602781, 900017),
(602790, 900018),
(602791, 900018),
(602803, 900019),
(602810, 900021),
(602822, 900022),
(602832, 900025),
(602833, 900025),
(602834, 900025),
(602850, 900026),
(602872, 900028),
(602873, 900028),
(602891, 900030),
(602900, 900031),
(602912, 900032),
(602913, 900032),
(602921, 900020),
(602922, 900020),
(602950, 900012),
(602951, 900012),
(602953, 900012),
(603402, 900024),
(612912, 900032),
(650275, 900015),
(650276, 900014),
(650277, 900016),
(650278, 900017),
(650279, 900018),
(650281, 900021),
(650285, 900026),
(650288, 900029),
(650290, 900031),
(650293, 900024),
(650296, 900013),
(650327, 900027);

-- ---------------------------------------------------------------------------
-- 3. Zulaka'jin and Zerin'dai speak their own cached greetings and a troll-voiced refusal
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` IN (205872, 687578);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(205872, '<As you approach Zerin''dai, you can see him meticulously trying to place a cauldron filled with a disgusting liquid in just the right spot.> Ayyy mon! Don''t be botherin'' me ya hear?! Da spirits won''t be listenin'' to me if dey gotta be hearin'' you babble about whateva'' it be you wantin''! Oh, you be lookin'' for trainin'' in da ways of da voodoo mon? You be givin'' me some mojo and I be givin'' you some knowledge!', '<As you approach Zerin''dai, you can see him meticulously trying to place a cauldron filled with a disgusting liquid in just the right spot.> Ayyy mon! Don''t be botherin'' me ya hear?! Da spirits won''t be listenin'' to me if dey gotta be hearin'' you babble about whateva'' it be you wantin''! Oh, you be lookin'' for trainin'' in da ways of da voodoo mon? You be givin'' me some mojo and I be givin'' you some knowledge!', 0, 0, 1, 4, 4, 0, 0, 0, 0),
(687578, 'Mon, you be seekin'' the path of da Barbarian? Zulaka''jin knows dis way well. In da deep jungles where da tigers prowl and da serpents strike without warnin'', I learned dat only da strongest survive. My tribe taught me to fight with da fury of da storm and da patience of da ancient trees. You got da savage heart needed for dis trainin'', or you just another soft-skin city dweller?', 'Mon, you be seekin'' the path of da Barbarian? Zulaka''jin knows dis way well. In da deep jungles where da tigers prowl and da serpents strike without warnin'', I learned dat only da strongest survive. My tribe taught me to fight with da fury of da storm and da patience of da ancient trees. You got da savage heart needed for dis trainin'', or you just another soft-skin city dweller?', 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930650, 930651);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930650, 687578),
(930650, 287574),
(930651, 205872),
(930651, 175441);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (930650, 930651);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930650, 0, 3, 'I seek training as a Barbarian.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930651, 0, 3, 'I seek training as a Witch Doctor.', 0, 5, 16, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (930650, 930651) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930650, 687578, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Barbarian'),
(14, 930650, 287574, 0, 0, 15, 0, 2048, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Barbarian'),
(15, 930650, 0, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Barbarian'),
(14, 930651, 205872, 0, 0, 15, 0, 4096, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Witch Doctor'),
(14, 930651, 175441, 0, 0, 15, 0, 4096, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Witch Doctor'),
(15, 930651, 0, 0, 0, 15, 0, 4096, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Witch Doctor');

-- ---------------------------------------------------------------------------
-- 4. Posts
-- ---------------------------------------------------------------------------
-- Each post was chosen from a floor and wall map of its hall (surface.floor, surface.wall; inspect_area
-- shows only the city WMO overhead here) and passes surface.check. The one flag is the known Undercity
-- false 'underwater' of the Rogues' Quarter: the .map lake at 32.9 lies 95 yd above the floor at -62.3.
-- Orgrimmar:
-- 9004650 Barbarian: hand-placed (INFERRED) Hall of the Brave in the Valley of Honor, south-east side of the
--   sparring pit, 3.5 yd beside Grezz Ragefist and 4.1 yd from the battlemasters' post, clear of the lines of the
--   battlemaster ring that faces the pit centre; faces 1.990 toward across the pit to the hall entrance in the
--   west-south-west, where players come in
-- 9004651 Guardian: hand-placed (INFERRED) Hall of the Brave in the Valley of Honor, on the raised south rim of
--   the sparring pit, by the shield display behind him; faces 0.000 toward the sparring pit
-- 9004652 Ranger: hand-placed (INFERRED) Hunter's Hall courtyard in the Valley of Honor, north end, 16 yd from
--   Ormak Grimshot and Sian'dur; faces 3.260 toward the courtyard centre and its open south to south-east side,
--   where players come in
-- 9004653 Tinker: hand-placed (INFERRED) Nogg's Machine Shop in the Valley of Honor, south-east corner, 7 yd from
--   Nogg and Roxxik; faces 0.785 toward the shop floor and its door
-- 9004654 Knight of Xoroth: hand-placed (INFERRED) Darkfire Enclave in the Cleft of Shadow, antechamber inside the
--   entrance, 8 yd from Kurgul; faces 1.680 toward the entry corridor players come down
-- 9004655 Necromancer: hand-placed (INFERRED) Darkfire Enclave in the Cleft of Shadow, against the east wall of
--   the main room, 5 yd behind Zevrost's shoulder and out of the lines of the warlocks, who face the entry and
--   their brazier; faces 2.000 toward across the room to the south-west entry, with no prop ahead
-- 9004656 Felsworn: hand-placed (INFERRED) Cleft of Shadow, Neeru Fireblade's den between Neeru and the Burning
--   Blade summoning circle, 4.5 yd beside Neeru and 56 deg off his line; faces 4.570 toward east across the den,
--   the way Neeru faces
-- 9004657 Cultist: hand-placed (INFERRED) Cleft of Shadow, head of the passage down to Ragefire Chasm, where the
--   Searing Blade cult gathers; faces 2.960 toward the den and the ramp players come down
-- 9004658 Witch Doctor: hand-placed (INFERRED) Cleft of Shadow, Rekkul's poison shop beside the cauldron, 7 yd
--   from Rekkul; his cached text has him setting up a cauldron (npccache 205872); faces 3.940 toward the shop
--   door, as Rekkul does
-- 9004659 Venomancer: hand-placed (INFERRED) Cleft of Shadow, Shadowswift Brotherhood ledge, 5.9 yd from Gest;
--   faces 4.710 toward the Cleft path below, as Gest does
-- 9004660 Stormbringer: hand-placed (INFERRED) shaman hall of the Valley of Wisdom, north side of the fire pit,
--   6.6 yd from Sian'tsu and out of her line; faces 3.100 toward the fire pit at the heart of the hall
-- 9004661 Primalist: hand-placed (INFERRED) shaman hall of the Valley of Wisdom, south side of the fire pit, 4.9
--   yd from Zor Lonetree; faces 1.050 toward the fire pit at the heart of the hall, with the jar (Jarorc02) beside
--   the pit to his right
-- 9004662 Pyromancer: hand-placed (INFERRED) Darkbriar Lodge in the Valley of Spirits, ground floor, north-east
--   corner beside the north door, 5.7 yd behind Enyo's shoulder and out of the mages' lines; faces 0.700 toward
--   the north door players come in by
-- 9004663 Bloodmage: hand-placed (INFERRED) Darkbriar Lodge in the Valley of Spirits, ground floor by the south
--   door, 8.5 yd from Uthel'nay; faces 0.290 toward the centre of the lodge
-- 9004664 Runemaster: hand-placed (INFERRED) Darkbriar Lodge in the Valley of Spirits, upper floor, east side, 6.4
--   yd from the portal trainer Thuul and 42 deg off his line, clear of the path from the stair head to him; faces
--   2.530 toward the stair head at the south end, the upper floor's only way in
-- Undercity:
-- 9004665 Felsworn: hand-placed (INFERRED) Magic Quarter, trainers' pit, beside the foot of the east ramp on its
--   north-west side, 3.5 yd off the ramp's descent line and 3.8 yd from Pierce Shackleton; faces 4.710 toward the
--   ramp foot where players step down into the pit
-- 9004666 Necromancer: hand-placed (INFERRED) Magic Quarter, outer edge of the ring walkway where the slope drops
--   into the trainers' pit, 2 yd from the outer wall; the pit itself has no free spot outside the stock trainers'
--   lines; faces 5.500 toward down the slope into the pit
-- 9004667 Runemaster: hand-placed (INFERRED) Magic Quarter, Anastasia Hartwell's study on the upper level, 3.8 yd
--   beside her and 66 deg off her line; CoA's cache has a copy of her titled Runemaster (45468); faces 3.140
--   toward the mouth of the study, as Anastasia does
-- 9004668 Chronomancer: hand-placed (INFERRED) Magic Quarter, portal room, 6.9 yd from the portal trainer
--   Lexington Mortaim; faces 1.890 toward the portal room floor
-- 9004669 Bloodmage: hand-placed (INFERRED) Magic Quarter, portal room, by the west wall between its two doors,
--   5.1 yd from Bethor Iceshard, 8.7 yd from Lexington Mortaim and 5.2 yd off the Dark Ranger Cyndia's walk
--   through the room; faces 5.280 toward the middle of the portal room, between its two doors
-- 9004670 Pyromancer: hand-placed (INFERRED) Trade Quarter forge, beside the forge fire, 6.1 yd from Samuel Van
--   Brunt; faces 0.610 toward out of the forge through its opening to the Trade Quarter ring, with the waist-high
--   forge block to his left
-- 9004671 Guardian: hand-placed (INFERRED) War Quarter, outer ring of the round hall, by the north entrance; faces
--   5.470 toward the north entrance players come in by
-- 9004672 Knight of Xoroth: hand-placed (INFERRED) War Quarter, outer ring of the round hall, north-east side,
--   12.3 yd from Father Lankester; faces 2.620 toward the middle of the hall
-- 9004673 Templar: hand-placed (INFERRED) War Quarter, outer ring of the round hall, west side, 18 yd from
--   Christoph Walker; faces 3.300 toward along the ring toward the south entrance
-- 9004674 Starcaller: hand-placed (INFERRED) War Quarter, outer ring of the round hall, south-west side; faces
--   5.020 toward the middle of the hall
-- 9004675 Cultist: hand-placed (INFERRED) War Quarter, outer ring of the round hall, south side, 8.2 yd from the
--   shadow priest Father Lazarus; faces 6.020 toward the middle of the hall
-- 9004676 Sun Cleric: hand-placed (INFERRED) War Quarter, outer ring of the round hall, east corridor at the pit
--   rim, 7.9 yd from the priestess Aelthalyste and 3.4 yd off the Dark Ranger Clea's walk along the corridor;
--   faces 5.100 toward Aelthalyste and the north-east door up the east corridor, the way players come down it
-- 9004677 Ranger: hand-placed (INFERRED) Rogues' Quarter, south of the main walk, 9.3 yd from Carolyn Ward and 4.3
--   yd off the Dark Ranger Anya's walk; faces 5.000 toward the middle of the quarter, where the rogue trainers
--   face
-- 9004678 Witch Hunter: hand-placed (INFERRED) Rogues' Quarter, 6.7 yd from Gregory Charles; faces 6.010 toward
--   the middle of the quarter, where the rogue trainers face
-- 9004679 Stormbringer: hand-placed (INFERRED) Rogues' Quarter, north side, 10 yd from Miles Dexter; the city has
--   no shaman hall or storm landmark, so he stands in the open quarter with the Ranger and the Witch Hunter; faces
--   2.900 toward the middle of the quarter, where the rogue trainers face
-- 9004680 Tinker: hand-placed (INFERRED) engineers' corner of the Rogues' Quarter, 10 yd from Franklin Lloyd and
--   Graham Van Talen; faces 2.630 toward the engineers' stalls
-- 9004681 Reaper: hand-placed (INFERRED) training ground behind the dummies on the ring below the War Quarter, 5.3
--   yd behind the Heroic Training Dummy and 11 yd off the ring road that Theresa and the Dark Rangers walk; faces
--   4.800 toward the ring road between the two training dummies
-- 9004689 Barbarian: hand-placed (INFERRED) War Quarter, island in the middle of the round hall, west side of the
--   ring of stock warrior trainer posts (removed) around the sunken centre, 5.8 yd from Christoph Walker's and 11
--   yd from Baltus Fowler's former posts, 5.0 yd off the Dark Ranger Clea's walk across the island (path 2033940);
--   faces 4.710 toward the sunken centre, as the warrior trainers did, between the two bridges players cross by
-- Thunder Bluff:
-- 9004682 Barbarian: hand-placed (INFERRED) Hunter Rise lodge tent, north side of the ring of warrior and hunter
--   trainers, 4.1 yd beside Ker Ragetotem and out of his line; faces 4.100 toward the centre of the tent, as Ker
--   does
-- 9004683 Guardian: hand-placed (INFERRED) Hunter Rise lodge tent, south side of the ring against the tent wall,
--   3.6 yd beside Kary Thunderhorn and out of her line; faces 0.790 toward the centre of the tent, as Kary does
-- 9004684 Primalist: hand-placed (INFERRED) Elder Rise, open ground of the druids, north side, 10.6 yd from Turak
--   Runetotem; faces 4.470 toward the druids gathered in the middle of the rise
-- 9004685 Starcaller: hand-placed (INFERRED) Elder Rise, open ground of the druids, west side, where the moon
--   sets, 10.8 yd from Kym Wildmane; faces 5.590 toward the druids gathered in the middle of the rise
-- 9004686 Sun Cleric: hand-placed (INFERRED) Elder Rise, open ground of the druids, east side, where the sun
--   rises, 9 yd from Kym Wildmane; faces 0.620 toward the druids gathered in the middle of the rise
-- 9004687 Runemaster: hand-placed (INFERRED) Spirit Rise top among the totems, 12.5 yd from the Skychaser shamans;
--   faces 1.040 toward the middle of the rise
-- 9004688 Cultist: hand-placed (INFERRED) Pools of Vision under Spirit Rise, north-west end of the chamber, 11 yd
--   from the shadow priest Miles Welsh and out of his and Ursyn Ghull's lines; faces 3.790 toward the foot of the
--   ramp from Spirit Rise, the chamber's only way in
DELETE FROM `creature` WHERE `guid` IN (9004650, 9004651, 9004652, 9004653, 9004654, 9004655, 9004656, 9004657, 9004658, 9004659, 9004660, 9004661, 9004662, 9004663, 9004664, 9004665, 9004666, 9004667, 9004668, 9004669, 9004670, 9004671, 9004672, 9004673, 9004674, 9004675, 9004676, 9004677, 9004678, 9004679, 9004680, 9004681, 9004682, 9004683, 9004684, 9004685, 9004686, 9004687, 9004688, 9004689) OR `guid` BETWEEN 9004650 AND 9004799;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004650, 602953, 1, 0, 0, 1, 1, 1, 1983, -4801.5, 56.039, 1.99, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Barbarian trainer: Hall of the Brave in the Valley of Honor, south-east side of the sparring pit, 3.5 yd beside Grezz Ragefist and 4.1 yd from the battlemasters'' post, clear of the lines of the battlemaster ring that faces the pit centre; faces across the pit to the hall entrance in the west-south-west, where players come in'),
(9004651, 602791, 1, 0, 0, 1, 1, 1, 1972, -4790, 56.983, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Guardian trainer: Hall of the Brave in the Valley of Honor, on the raised south rim of the sparring pit, by the shield display behind him; faces the sparring pit'),
(9004652, 602810, 1, 0, 0, 1, 1, 1, 2112, -4618, 58.623, 3.26, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Ranger trainer: Hunter''s Hall courtyard in the Valley of Honor, north end, 16 yd from Ormak Grimshot and Sian''dur; faces the courtyard centre and its open south to south-east side, where players come in'),
(9004653, 602872, 1, 0, 0, 1, 1, 1, 2032, -4752, 29.387, 0.785, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Tinker trainer: Nogg''s Machine Shop in the Valley of Honor, south-east corner, 7 yd from Nogg and Roxxik; faces the shop floor and its door'),
(9004654, 650278, 1, 0, 0, 1, 1, 1, 1831, -4353, -14.639, 1.68, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Knight of Xoroth trainer: Darkfire Enclave in the Cleft of Shadow, antechamber inside the entrance, 8 yd from Kurgul; faces the entry corridor players come down'),
(9004655, 503925, 1, 0, 0, 1, 1, 1, 1846, -4364.5, -14.627, 2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Necromancer trainer: Darkfire Enclave in the Cleft of Shadow, against the east wall of the main room, 5 yd behind Zevrost''s shoulder and out of the lines of the warlocks, who face the entry and their brazier; faces across the room to the south-west entry, with no prop ahead'),
(9004656, 602760, 1, 0, 0, 1, 1, 1, 1804, -4377.5, -17.434, 4.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Felsworn trainer: Cleft of Shadow, Neeru Fireblade''s den between Neeru and the Burning Blade summoning circle, 4.5 yd beside Neeru and 56 deg off his line; faces east across the den, the way Neeru faces'),
(9004657, 602832, 1, 0, 0, 1, 1, 1, 1804, -4392, -17.96, 2.96, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Cultist trainer: Cleft of Shadow, head of the passage down to Ragefire Chasm, where the Searing Blade cult gathers; faces the den and the ramp players come down'),
(9004658, 650296, 1, 0, 0, 1, 1, 1, 1817, -4274.5, 7.478, 3.94, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Witch Doctor trainer: Cleft of Shadow, Rekkul''s poison shop beside the cauldron, 7 yd from Rekkul; his cached text has him setting up a cauldron (npccache 205872); faces the shop door, as Rekkul does'),
(9004659, 650288, 1, 0, 0, 1, 1, 1, 1789, -4274.5, 7.742, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Venomancer trainer: Cleft of Shadow, Shadowswift Brotherhood ledge, 5.9 yd from Gest; faces the Cleft path below, as Gest does'),
(9004660, 650277, 1, 0, 0, 1, 1, 1, 1938, -4215.5, 42.321, 3.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Stormbringer trainer: shaman hall of the Valley of Wisdom, north side of the fire pit, 6.6 yd from Sian''tsu and out of her line; faces the fire pit at the heart of the hall'),
(9004661, 650290, 1, 0, 0, 1, 1, 1, 1919.5, -4227, 42.322, 1.05, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Primalist trainer: shaman hall of the Valley of Wisdom, south side of the fire pit, 4.9 yd from Zor Lonetree; faces the fire pit at the heart of the hall, with the jar (Jarorc02) beside the pit to his right'),
(9004662, 603402, 1, 0, 0, 1, 1, 1, 1477, -4228, 43.186, 0.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Pyromancer trainer: Darkbriar Lodge in the Valley of Spirits, ground floor, north-east corner beside the north door, 5.7 yd behind Enyo''s shoulder and out of the mages'' lines; faces the north door players come in by'),
(9004663, 602921, 1, 0, 0, 1, 1, 1, 1460, -4225, 43.186, 0.29, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Bloodmage trainer: Darkbriar Lodge in the Valley of Spirits, ground floor by the south door, 8.5 yd from Uthel''nay; faces the centre of the lodge'),
(9004664, 602912, 1, 0, 0, 1, 1, 1, 1469.5, -4226.5, 59.221, 2.53, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Runemaster trainer: Darkbriar Lodge in the Valley of Spirits, upper floor, east side, 6.4 yd from the portal trainer Thuul and 42 deg off his line, clear of the path from the stair head to him; faces the stair head at the south end, the upper floor''s only way in'),
(9004665, 650276, 0, 0, 0, 1, 1, 1, 1788.5, 51, -61.493, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Felsworn trainer: Magic Quarter, trainers'' pit, beside the foot of the east ramp on its north-west side, 3.5 yd off the ramp''s descent line and 3.8 yd from Pierce Shackleton; faces the ramp foot where players step down into the pit'),
(9004666, 503930, 0, 0, 0, 1, 1, 1, 1762.5, 73.5, -59.3, 5.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Necromancer trainer: Magic Quarter, outer edge of the ring walkway where the slope drops into the trainers'' pit, 2 yd from the outer wall; the pit itself has no free spot outside the stock trainers'' lines; faces down the slope into the pit'),
(9004667, 602913, 0, 0, 0, 1, 1, 1, 1812.5, 60, -47.391, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Runemaster trainer: Magic Quarter, Anastasia Hartwell''s study on the upper level, 3.8 yd beside her and 66 deg off her line; CoA''s cache has a copy of her titled Runemaster (45468); faces the mouth of the study, as Anastasia does'),
(9004668, 602822, 0, 0, 0, 1, 1, 1, 1774, 60, -46.321, 1.89, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Chronomancer trainer: Magic Quarter, portal room, 6.9 yd from the portal trainer Lexington Mortaim; faces the portal room floor'),
(9004669, 602922, 0, 0, 0, 1, 1, 1, 1770.5, 69.5, -46.321, 5.28, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Bloodmage trainer: Magic Quarter, portal room, by the west wall between its two doors, 5.1 yd from Bethor Iceshard, 8.7 yd from Lexington Mortaim and 5.2 yd off the Dark Ranger Cyndia''s walk through the room; faces the middle of the portal room, between its two doors'),
(9004670, 650293, 0, 0, 0, 1, 1, 1, 1688, 278.5, -62.138, 0.61, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Pyromancer trainer: Trade Quarter forge, beside the forge fire, 6.1 yd from Samuel Van Brunt; faces out of the forge through its opening to the Trade Quarter ring, with the waist-high forge block to his left'),
(9004671, 650279, 0, 0, 0, 1, 1, 1, 1797, 428, -57.215, 5.47, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Guardian trainer: War Quarter, outer ring of the round hall, by the north entrance; faces the north entrance players come in by'),
(9004672, 602781, 0, 0, 0, 1, 1, 1, 1796.5, 404, -57.215, 2.62, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Knight of Xoroth trainer: War Quarter, outer ring of the round hall, north-east side, 12.3 yd from Father Lankester; faces the middle of the hall'),
(9004673, 602803, 0, 0, 0, 1, 1, 1, 1783, 441, -57.215, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Templar trainer: War Quarter, outer ring of the round hall, west side, 18 yd from Christoph Walker; faces along the ring toward the south entrance'),
(9004674, 602850, 0, 0, 0, 1, 1, 1, 1766, 441.5, -57.215, 5.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Starcaller trainer: War Quarter, outer ring of the round hall, south-west side; faces the middle of the hall'),
(9004675, 602833, 0, 0, 0, 1, 1, 1, 1751.5, 423, -57.215, 6.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Cultist trainer: War Quarter, outer ring of the round hall, south side, 8.2 yd from the shadow priest Father Lazarus; faces the middle of the hall'),
(9004676, 650327, 0, 0, 0, 1, 1, 1, 1761, 403.5, -57.215, 5.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Sun Cleric trainer: War Quarter, outer ring of the round hall, east corridor at the pit rim, 7.9 yd from the priestess Aelthalyste and 3.4 yd off the Dark Ranger Clea''s walk along the corridor; faces Aelthalyste and the north-east door up the east corridor, the way players come down it'),
(9004677, 650281, 0, 0, 0, 1, 1, 1, 1408, 72, -62.279, 5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Ranger trainer: Rogues'' Quarter, south of the main walk, 9.3 yd from Carolyn Ward and 4.3 yd off the Dark Ranger Anya''s walk; faces the middle of the quarter, where the rogue trainers face'),
(9004678, 650275, 0, 0, 0, 1, 1, 1, 1403, 64, -62.279, 6.01, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Witch Hunter trainer: Rogues'' Quarter, 6.7 yd from Gregory Charles; faces the middle of the quarter, where the rogue trainers face'),
(9004679, 602773, 0, 0, 0, 1, 1, 1, 1430, 57, -62.279, 2.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Stormbringer trainer: Rogues'' Quarter, north side, 10 yd from Miles Dexter; the city has no shaman hall or storm landmark, so he stands in the open quarter with the Ranger and the Witch Hunter; faces the middle of the quarter, where the rogue trainers face'),
(9004680, 602873, 0, 0, 0, 1, 1, 1, 1414, 142, -62.293, 2.63, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Tinker trainer: engineers'' corner of the Rogues'' Quarter, 10 yd from Franklin Lloyd and Graham Van Talen; faces the engineers'' stalls'),
(9004681, 602891, 0, 0, 0, 1, 1, 1, 1767, 356, -61.87, 4.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Reaper trainer: training ground behind the dummies on the ring below the War Quarter, 5.3 yd behind the Heroic Training Dummy and 11 yd off the ring road that Theresa and the Dark Rangers walk; faces the ring road between the two training dummies'),
(9004689, 602951, 0, 0, 0, 1, 1, 1, 1775.5, 426, -57.198, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Barbarian trainer: War Quarter, island in the middle of the round hall, west side of the ring of stock warrior trainer posts (removed) around the sunken centre, 5.8 yd from Christoph Walker''s and 11 yd from Baltus Fowler''s former posts, 5.0 yd off the Dark Ranger Clea''s walk across the island (path 2033940); faces the sunken centre, as the warrior trainers did, between the two bridges players cross by'),
(9004682, 602950, 1, 0, 0, 1, 1, 1, -1446.5, -80.5, 159.018, 4.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Barbarian trainer: Hunter Rise lodge tent, north side of the ring of warrior and hunter trainers, 4.1 yd beside Ker Ragetotem and out of his line; faces the centre of the tent, as Ker does'),
(9004683, 602790, 1, 0, 0, 1, 1, 1, -1463, -97, 159.018, 0.79, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Guardian trainer: Hunter Rise lodge tent, south side of the ring against the tent wall, 3.6 yd beside Kary Thunderhorn and out of her line; faces the centre of the tent, as Kary does'),
(9004684, 602900, 1, 0, 0, 1, 1, 1, -1044, -272, 159.03, 4.47, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Primalist trainer: Elder Rise, open ground of the druids, north side, 10.6 yd from Turak Runetotem; faces the druids gathered in the middle of the rise'),
(9004685, 650285, 1, 0, 0, 1, 1, 1, -1060, -278, 159.03, 5.59, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Starcaller trainer: Elder Rise, open ground of the druids, west side, where the moon sets, 10.8 yd from Kym Wildmane; faces the druids gathered in the middle of the rise'),
(9004686, 600242, 1, 0, 0, 1, 1, 1, -1060.5, -297, 159.03, 0.62, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Sun Cleric trainer: Elder Rise, open ground of the druids, east side, where the sun rises, 9 yd from Kym Wildmane; faces the druids gathered in the middle of the rise'),
(9004687, 612912, 1, 0, 0, 1, 1, 1, -993, 266.5, 137.59, 1.04, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Runemaster trainer: Spirit Rise top among the totems, 12.5 yd from the Skychaser shamans; faces the middle of the rise'),
(9004688, 602834, 1, 0, 0, 1, 1, 1, -945.5, 255.5, 97.095, 3.79, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Cultist trainer: Pools of Vision under Spirit Rise, north-west end of the chamber, 11 yd from the shadow priest Miles Welsh and out of his and Ursyn Ghull''s lines; faces the foot of the ramp from Spirit Rise, the chamber''s only way in');
