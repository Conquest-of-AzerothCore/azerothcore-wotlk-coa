-- Conquest of Azeroth class trainers in the Alliance capitals: the Stormwind (16), Ironforge (11) and
-- Darnassus (12) twins of the starting-zone trainers. Each trainer is a core class trainer (trainer
-- 900000 + class and its menu 930000 + class from migration 05) with a look, weapons and a hand-checked
-- post. The Darnassus Primalist is the stock Mathrengyl Bearwalker (4217), retitled by migration 05.
--
-- WHERE EACH VALUE COMES FROM
--   entries, names and titles  SOURCED-CACHE creaturecache; which capital a twin serves is INFERRED from
--     the 6-prefix twin pattern and the cache capture counts (research/class-trainers/trainers.md).
--   posts  INFERRED: no source gives a capital trainer position. Every post was hand-picked in the hall
--     of a related stock class or at a landmark that suits the class, checked with surface.check on the
--     server floor, and kept at least 2.5 yd from every stock NPC (the stock class trainers keep their
--     posts) and from every walking NPC's waypoint path and wander
--     radius. No stock spawn is deleted or moved here. Stormwind posts are checked against the
--     positions migration 03 gives the stock spawns.
--   facings  toward where players stand or come in, with no wall within 3 yd ahead (reason per post).
--   looks  stand-ins: no SMSG_MIRRORIMAGE_DATA capture of any trainer exists and the cache display ids
--     do not resolve. Each look copies a stock NPC of the chosen race, sex and theme
--     (CreatureDisplayInfoExtra), restyled within the player ranges, some with armor pieces swapped.
--     Race and sex are INFERRED from the name, title, cached text and city.
--   weapons  Item.dbc items of an inventory type the core accepts in that hand.
--   gossip  the class menu from migration 05, except Surellion Trueshot, whose own cached text
--     (npccache 205914) gets its own menu with the class refusal and training option.
--
-- Blocks: creature guids 9004500-9004649, gossip menus 930600-930649.

-- ---------------------------------------------------------------------------
-- 1. Trainer templates (level 60, the city faction, gossip + trainer + class trainer)
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(503923, 'Jefferson Lively', 'Necromancer Trainer', 930023, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503924, 'Baralor Oathbreaker', 'Necromancer Trainer', 930023, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(600292, 'Sofiya Taylor', 'Bloodmage Trainer', 930020, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(600344, 'Pelinor Felsight', 'Felsworn Trainer', 930014, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602770, 'Viktor Thunder-Eye', 'Stormbringer Trainer', 930016, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602771, 'Kharaz Dak', 'Stormbringer Trainer', 930016, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602772, 'Pak Thunderhoof', 'Stormbringer Trainer', 930016, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602780, 'Zeltur''atha the Exile', 'Knight of Xoroth Trainer', 930017, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602800, 'Yelya Flinthammer', 'Templar Trainer', 930019, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602801, 'Corinthia the Templar', 'Templar Trainer', 930019, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602821, 'Belladormi', 'Chronomancer Trainer', 930022, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602830, 'Dippo the Doomer', 'Cultist Trainer', 930025, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602831, 'Soliras Darkwoven', 'Cultist Trainer', 930025, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602835, 'Gerald the Demented', 'Cultist Trainer', 930025, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602870, 'Zipgear Zoombang', 'Tinker Trainer', 930028, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602871, 'Baarus the Tinker', 'Tinker Trainer', 930028, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602890, 'Turalen Darkwhisper', 'Reaper Trainer', 930030, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602910, 'Beelo Blitzcog', 'Runemaster Trainer', 930032, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602911, 'Shayla Runewander', 'Runemaster Trainer', 930032, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602920, 'Lokirus Veinspiller', 'Bloodmage Trainer', 930020, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602952, 'Modor Tarmund', 'Barbarian Trainer', 930012, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(602960, 'The Great Yumbabo', 'Witch Doctor Trainer', 930013, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(603241, 'Dagnan the Blade', 'Guardian Trainer', 930018, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(603271, 'Sunbeard the Pious', 'Sun Cleric Trainer', 930027, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(603400, 'Penny Pyrewhistle', 'Pyromancer Trainer', 930024, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(603410, 'Phoebe Lakewander', 'Ranger Trainer', 930021, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650280, 'Brother Faren', 'Templar Trainer', 930019, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650282, 'Yisdormi', 'Chronomancer Trainer', 930022, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650286, 'Crusader Natalie', 'Sun Cleric Trainer', 930027, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650287, 'James Randal', 'Tinker Trainer', 930028, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650289, 'Wilfred Soulcatcher', 'Reaper Trainer', 930030, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650291, 'Balthazar Marone', 'Runemaster Trainer', 930032, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650295, 'Connor the Barbarian', 'Barbarian Trainer', 930012, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650324, 'Kalanaros the Bard', 'Guardian Trainer', 930018, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650325, 'Talvin', 'Witch Hunter Trainer', 930015, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650326, 'Moonpriest Ty''lera', 'Starcaller Trainer', 930026, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650340, 'Michael Pietrus', 'Pyromancer Trainer', 930024, 60, 60, 0, 12, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650341, 'Surellion Trueshot', 'Ranger Trainer', 930600, 60, 60, 0, 80, 49, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650342, 'Threllin the Bearded', 'Primalist Trainer', 930031, 60, 60, 0, 55, 49, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

-- ---------------------------------------------------------------------------
-- 2. Looks, weapons and class trainer links
-- ---------------------------------------------------------------------------
-- 650295 Connor the Barbarian, Barbarian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human male from Northsea Mercenary (25839) (display 22578), changed skin 3, face 5, hair 5, haircolor
--   4, facialhair 4; raider kit without the head piece; race and sex INFERRED from his human name; Stormwind twin
--   of Amanda the Reaver (Northshire); weapons 7717
-- 650324 Kalanaros the Bard, Guardian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: night elf male from Nighthaven Defender (15495) (display 11776), changed skin 2, face 4, hair 5,
--   haircolor 6, facialhair 2; Bard's Cloak (item 6555) and Stylin' Purple Hat (item 25680); race and sex INFERRED
--   from his elven name and his title "the Bard"; weapons 9380/12602
-- 650280 Brother Faren, Templar: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   human male from Korfax, Champion of the Light (16112) (display 16012), changed skin 1, face 6, hair 3,
--   haircolor 2, facialhair 6; Stormwind tabard of General Marcus Jonathan (466); race and sex INFERRED from his
--   title "Brother" of the Stormwind church; twin of Brother William (Northshire); weapons 7721/7188
-- 650286 Crusader Natalie, Sun Cleric: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human female from Scarlet Paladin (1834) (display 10327), changed skin 2, face 4, hair 7, haircolor 3;
--   no helm, the Stormwind tabard (display 3734) instead of the Scarlet one; race and sex INFERRED from her human
--   name; twin of Chaplain Nysoni (Northshire); weapons 18717
-- 602960 The Great Yumbabo, Witch Doctor: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: troll male from Witch Doctor Unbagwa (1449) (display 4661), changed skin 2, face 1, hair 4, haircolor
--   6, facialhair 3; voodoo mask kept, leggings of the Bloodscalp Witch Doctor (660); race and sex INFERRED from
--   his troll name; weapons 9482
-- 650325 Talvin, Witch Hunter: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human
--   male from Grand Inquisitor Isillien (1840) (display 10339), changed skin 4, face 3, hair 6, haircolor 1,
--   facialhair 3; Don Rigoberto's wide-brimmed hat (item 21615), no tabard; race and sex INFERRED from his human
--   name; twin of Deacon Frost (Northshire); weapons 6802/15809
-- 602770 Viktor Thunder-Eye, Stormbringer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human male from Kul Tiras Marine (3129) (display 1860), changed skin 5, face 2, hair 9, haircolor 7,
--   facialhair 5; bare-headed; race and sex INFERRED from his human name; twin of Niki Thesla (Northshire);
--   weapons 21398
-- 600292 Sofiya Taylor, Bloodmage: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   human female from Bloodsail Mage (1562) (display 2562), changed skin 1, face 6, hair 4, haircolor 1; no
--   mantle; race and sex INFERRED from her human name; twin of Whisp the Silent (Northshire); weapons 17071/19309
-- 603410 Phoebe Lakewander, Ranger: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   human female from Scout Riell (820) (display 2374), changed skin 3, face 5, hair 10, haircolor 4; Traveler's
--   Cloak (item 8297); race and sex INFERRED from her human name; twin of Owen of Moonbrook (Northshire); weapons
--   21520/17069
-- 650282 Yisdormi, Chronomancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   human female from Charys Yserian (1307) (display 1480), changed skin 2, face 3, hair 5, haircolor 7; bronze
--   and gold in place of her green robes: Robe of Solomon (display 12994), Talbar Mantle (15606), Girdle of
--   Prophecy (24129), Acolyte's Shoes (1246), Cloak of Eternity (32030); race and sex INFERRED from her -dormi
--   bronze dragon name, like her Northshire twin Soridormi; human guise; weapons 21715/19366
-- 503923 Jefferson Lively, Necromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human male from Dark Strand Enforcer (3727) (display 4226), changed skin 0, face 8, hair 2, haircolor
--   0, facialhair 2; pale, with the hood of the Twilight Acolyte (4809); race and sex INFERRED from his human
--   name; twin of Halbert the Scoundrel (Northshire); weapons 2549
-- 650340 Michael Pietrus, Pyromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   human male from Scarlet Mage (1826) (display 10286), changed skin 2, face 4, hair 3, haircolor 5, facialhair
--   6; ember robes kept, no Scarlet tabard; race and sex INFERRED from his human name; twin of Koby the
--   Incinerator (Northshire); weapons 13000
-- 602835 Gerald the Demented, Cultist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human male from Twilight Reaver (4810) (display 2899), changed skin 6, face 9, hair 8, haircolor 9,
--   facialhair 7; no mantle; race and sex INFERRED from his human name; twin of Patal the Mad (Northshire);
--   weapons 21416
-- 650287 James Randal, Tinker: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human
--   male from Horizon Scout Engineer (8389) (display 7609), changed skin 4, face 7, hair 6, haircolor 2,
--   facialhair 1; engineering goggles (Primal Stalker Goggles, item 10927); race and sex INFERRED from his human
--   name; twin of Norman Goldshire (Northshire); weapons 6219/15995
-- 650289 Wilfred Soulcatcher, Reaper: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   human male from Syndicate Shadow Mage (2244) (display 3621), changed skin 7, face 2, hair 0, haircolor 0,
--   facialhair 0; hooded robe kept, grey skin; race and sex INFERRED from his human name; twin of Troes the
--   Remover (Northshire); weapons 2000005
-- 650291 Balthazar Marone, Runemaster: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human male from Archmage Ansirem Runeweaver (2543) (display 1595), changed skin 3, face 4, hair 7,
--   haircolor 8, facialhair 4; no circlet, the Kirin Tor scribe tabard (display 158400); race and sex INFERRED
--   from his human name; twin of Wanda Belezin (Northshire); weapons 21521/21471
-- 602952 Modor Tarmund, Barbarian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   dwarf male from Mountaineer Wallbang (1090) (display 1629), changed skin 4, face 6, hair 4, haircolor 7,
--   facialhair 9; helm and jerkin off; race and sex INFERRED from his dwarf name; twin of Grelin Ironbeard
--   (Coldridge); weapons 6830
-- 603241 Dagnan the Blade, Guardian: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   dwarf male from Jern Hornhelm (1105) (display 1572), changed skin 2, face 3, hair 2, haircolor 4, facialhair
--   6; Ironforge plate helm kept; race and sex INFERRED from his dwarf name; twin of Kharzon the Hammer
--   (Coldridge); weapons 21395/6254
-- 602800 Yelya Flinthammer, Templar: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   dwarf female from Ironforge Paladin (18986) (display 18458), changed skin 3, face 5, hair 4, haircolor 2;
--   Lightforge plate kept; race and sex INFERRED from her dwarf name; twin of Thiduis Pride (Coldridge); weapons
--   22808/20688
-- 603271 Sunbeard the Pious, Sun Cleric: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: dwarf male from Maxan Anvol (1226) (display 3429), changed skin 1, face 2, hair 3, haircolor 6,
--   facialhair 8; Robe of Eternal Light (item 34365); race and sex INFERRED from his dwarf name ("Sunbeard"); twin
--   of Cleric Stonelight (Coldridge); weapons 21703
-- 602870 Zipgear Zoombang, Tinker: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   gnome male from Namdo Bizzfizzle (2683) (display 4953), changed skin 1, face 5, hair 3, haircolor 4,
--   facialhair 5; engineering helm kept; race and sex INFERRED from his gnome name; twin of Binkle Coldbolt
--   (Coldridge); weapons 23221/19368
-- 603400 Penny Pyrewhistle, Pyromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: gnome female from Dalaran Mage (1914) (display 3562), changed skin 3, face 2, hair 4, haircolor 6; no
--   Dalaran tabard, Embercloth Robe (item 12597); race and sex INFERRED from her gnome name; twin of Debbie
--   Whirlyflame (Coldridge); weapons 5201
-- 602910 Beelo Blitzcog, Runemaster: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   gnome male from Arcanist Nozzlespring (15444) (display 5377), changed skin 2, face 3, hair 5, haircolor 7,
--   facialhair 3; monocle kept; race and sex INFERRED from his gnome name; twin of Murmon Fuseforge (Coldridge);
--   weapons 15216
-- 650342 Threllin the Bearded, Primalist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: dwarf male from Grif Wildheart (1231) (display 3558), changed skin 5, face 7, hair 7, haircolor 5,
--   facialhair 10; long beard; race and sex INFERRED from his title "the Bearded"; twin of Katho Hammerfist
--   (Coldridge); weapons 20556
-- 602771 Kharaz Dak, Stormbringer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   dwarf male from Thorgrum Borrelson (1572) (display 5037), changed skin 6, face 4, hair 5, haircolor 3,
--   facialhair 7; Wildhammer riding leathers kept; race and sex INFERRED from his Khaz Modan name; twin of Freja
--   Stormbelch (Coldridge); weapons 19104
-- 503924 Baralor Oathbreaker, Necromancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human male from Scourge Necromancer (1897) (display 2582), changed skin 0, face 9, hair 5, haircolor
--   0, facialhair 3; pale, in the hood and dark robes of the Twilight Acolyte (4809): displays 144978, 147150,
--   148598, 150212, 10349, 154354, 156852; race and sex INFERRED from his name and title; Necromancer was never a
--   dwarf class in CoA (RACE-CLASS.md), of its races only humans and gnomes live in Ironforge, and Baralor is no
--   gnome name; twin of Ophana Gloom (Coldridge); weapons 18842
-- 602830 Dippo the Doomer, Cultist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   gnome male from Shadowy Summoner (17088) (display 18130), changed skin 2, face 4, hair 2, haircolor 5,
--   facialhair 6; embalmed shroud kept; race and sex INFERRED from his gnome name; twin of Clippo Doomwhistle
--   (Coldridge); weapons 21404
-- 600344 Pelinor Felsight, Felsworn: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   night elf male from Balthule Shadowstrike (3661) (display 2530), changed skin 4, face 3, hair 6, haircolor 5,
--   facialhair 4; bare-chested; race and sex INFERRED from his elven name; twin of Flowzie the Fel-Touched
--   (Shadowglen); weapons 12482/12482
-- 602780 Zeltur'atha the Exile, Knight of Xoroth: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this
--   trainer exists: draenei female from Miall (16724) (display 17493), changed skin 10, face 3, hair 5, haircolor
--   0, facialhair 2; heavy dark plate in place of her smith's leathers: Doomplate shoulders, chest, girdle and
--   legs (displays 36030, 35662, 36038, 36033), Boots of the Decimator (36039), Grips of Wrath (27267); race and
--   sex INFERRED from her title "the Exile" (draenei means the exiled ones); Knight of Xoroth was a draenei class
--   and never a night elf one (RACE-CLASS.md); twin of Aheravara (Shadowglen), whom ct-shadowglen made a draenei
--   woman; weapons 14541
-- 602772 Pak Thunderhoof, Stormbringer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: draenei male from Exodar Peacekeeper (16733) (display 17373), changed skin 3, face 5, hair 3,
--   haircolor 2, facialhair 4; Peacekeeper leathers kept; race and sex INFERRED from his name "Thunderhoof"
--   (hooves); draenei are the shamans of the Alliance; weapons 810/17106
-- 602801 Corinthia the Templar, Templar: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: human female from Argent Officer Pureheart (10840) (display 10211), changed skin 2, face 7, hair 10,
--   haircolor 3, facialhair 0; bright gold plate in place of the white Argent plate: Lawbringer epaulets, chest,
--   girdle, greaves, treads, bands and gloves (displays 24923, 24918, 24785, 24784, 24786, 24922, 24920); silver
--   circlet kept, no Argent Dawn tabard; race and sex INFERRED from her human name; Templar was a human, dwarf,
--   undead, blood elf and draenei class in CoA and never a night elf one (RACE-CLASS.md); twin of Elleora
--   (Shadowglen); weapons 21407/19349
-- 602920 Lokirus Veinspiller, Bloodmage: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: night elf male from Highborne Summoner (11466) (display 11207), changed skin 5, face 1, hair 1,
--   haircolor 2, facialhair 1; House of Shen'dral robes kept; race and sex INFERRED from his elven name; twin of
--   Aramadus (Shadowglen); weapons 12795
-- 650341 Surellion Trueshot, Ranger: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   night elf female from Huntress Nhemai (10604) (display 9937), changed skin 4, face 3, hair 5, haircolor 3,
--   facialhair 2; huntress mail kept; race and sex INFERRED from her cached text ("she"); twin of Hydriel
--   Featherflight (Shadowglen); weapons 17368/11271
-- 602821 Belladormi, Chronomancer: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   night elf female from Alanna Raveneye (3606) (display 1717), changed skin 6, face 4, hair 2, haircolor 1; sand
--   and gold in place of her blue dress: Stonecloth Robe and its tan girdle (displays 20505, 18859), Hann Ibal's
--   Epaulettes (23567), Elegant Cloak (11887), Sun-Baked Boots (546); race and sex INFERRED from her -dormi bronze
--   dragon name, like her Shadowglen twin Kaleidormu; a dragon's mortal guise is no player race/class pair, so she
--   keeps the elven guise of her Darnassus post, as ct-shadowglen gave Kaleidormu; weapons 15041
-- 602831 Soliras Darkwoven, Cultist: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   night elf female from Druid of the Fang (3840) (display 4233), changed skin 3, face 5, hair 6, haircolor 4,
--   facialhair 6; serpent coif kept; race and sex INFERRED from her elven name; twin of Saelina Shedana
--   (Shadowglen); weapons 17780
-- 650326 Moonpriest Ty'lera, Starcaller: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: night elf female from Moon Priestess Amara (2151) (display 1681), changed skin 0, face 2, hair 6,
--   haircolor 7, facialhair 3; priestess circlet kept; race and sex INFERRED from her title "Moonpriest" of Elune;
--   twin of Huntress Naalia (Shadowglen); weapons 6505
-- 602871 Baarus the Tinker, Tinker: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   draenei male from Artificer Daelo (17222) (display 16912), changed skin 5, face 3, hair 4, haircolor 4,
--   facialhair 3; goggles (Moon Spirit Goggles, item 10884); race and sex INFERRED from his draenei name
--   (trainers.md: draenei-style name); weapons 24384/18573
-- 602890 Turalen Darkwhisper, Reaper: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   night elf male from Arantir's Shadow (7229) (display 6301), changed skin 6, face 5, hair 4, haircolor 1,
--   facialhair 3; shadowcraft cap kept; race and sex INFERRED from his elven name and his Darnassus post; CoA
--   never paired night elf with Reaper (RACE-CLASS.md), but of its Reaper races only the blood elf has an elven
--   name and Darnassus hosts none, so he stays a night elf like his Shadowglen twin Canni the Shade (ct-
--   shadowglen); weapons 21392/21401
-- 602911 Shayla Runewander, Runemaster: look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: night elf female from Cenarion Druid (4052) (display 4250), changed skin 2, face 7, hair 3, haircolor
--   5, facialhair 5; Cenarion leathers kept; race and sex INFERRED from her elven name; twin of Raethere Daltrall
--   (Shadowglen); weapons 21413/21471
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (503923, 503924, 600292, 600344, 602770, 602771, 602772, 602780, 602800, 602801, 602821, 602830, 602831, 602835, 602870, 602871, 602890, 602910, 602911, 602920, 602952, 602960, 603241, 603271, 603400, 603410, 650280, 650282, 650286, 650287, 650289, 650291, 650295, 650324, 650325, 650326, 650340, 650341, 650342);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(503923, 0, 49, 1, 1),
(503924, 0, 49, 1, 1),
(600292, 0, 50, 1, 1),
(600344, 0, 55, 1, 1),
(602770, 0, 49, 1, 1),
(602771, 0, 53, 1, 1),
(602772, 0, 16125, 1, 1),
(602780, 0, 16126, 1, 1),
(602800, 0, 54, 1, 1),
(602801, 0, 50, 1, 1),
(602821, 0, 56, 1, 1),
(602830, 0, 1563, 1, 1),
(602831, 0, 56, 1, 1),
(602835, 0, 49, 1, 1),
(602870, 0, 1563, 1, 1),
(602871, 0, 16125, 1, 1),
(602890, 0, 55, 1, 1),
(602910, 0, 1563, 1, 1),
(602911, 0, 56, 1, 1),
(602920, 0, 55, 1, 1),
(602952, 0, 53, 1, 1),
(602960, 0, 1478, 1, 1),
(603241, 0, 53, 1, 1),
(603271, 0, 53, 1, 1),
(603400, 0, 1564, 1, 1),
(603410, 0, 50, 1, 1),
(650280, 0, 49, 1, 1),
(650282, 0, 50, 1, 1),
(650286, 0, 50, 1, 1),
(650287, 0, 49, 1, 1),
(650289, 0, 49, 1, 1),
(650291, 0, 49, 1, 1),
(650295, 0, 49, 1, 1),
(650324, 0, 55, 1, 1),
(650325, 0, 49, 1, 1),
(650326, 0, 56, 1, 1),
(650340, 0, 49, 1, 1),
(650341, 0, 56, 1, 1),
(650342, 0, 53, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (503923, 503924, 600292, 600344, 602770, 602771, 602772, 602780, 602800, 602801, 602821, 602830, 602831, 602835, 602870, 602871, 602890, 602910, 602911, 602920, 602952, 602960, 603241, 603271, 603400, 603410, 650280, 650282, 650286, 650287, 650289, 650291, 650295, 650324, 650325, 650326, 650340, 650341, 650342);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(503923, 49, 1, 0, 1, 0, 8, 2, 0, 2, 0, 144978, 0, 147347, 148691, 150415, 553, 154582, 0, 157035, 0, 0),
(503924, 49, 1, 0, 1, 0, 9, 5, 0, 3, 0, 144978, 0, 147150, 148598, 150212, 10349, 154354, 0, 156852, 0, 0),
(600292, 50, 1, 1, 1, 1, 6, 4, 1, 0, 0, 0, 0, 147140, 148590, 150204, 3147, 154344, 0, 0, 0, 0),
(600344, 55, 4, 0, 1, 4, 3, 6, 5, 4, 0, 0, 145925, 0, 0, 150202, 593, 154338, 156233, 0, 0, 0),
(602770, 49, 1, 0, 1, 5, 2, 9, 7, 5, 0, 0, 145899, 147067, 148546, 150128, 5045, 154255, 0, 156787, 0, 158361),
(602771, 53, 3, 0, 1, 6, 4, 5, 3, 7, 0, 0, 6691, 6692, 0, 6295, 1971, 5718, 0, 5719, 0, 0),
(602772, 16125, 11, 0, 1, 3, 5, 3, 2, 4, 0, 0, 30175, 0, 30176, 29967, 30174, 0, 0, 30177, 0, 0),
(602780, 16126, 11, 1, 1, 10, 3, 5, 0, 2, 0, 0, 36030, 0, 35662, 36038, 36033, 36039, 0, 27267, 0, 0),
(602800, 54, 3, 1, 1, 3, 5, 4, 2, 0, 0, 0, 23811, 0, 23809, 23806, 23812, 23807, 0, 23810, 0, 0),
(602801, 50, 1, 1, 1, 2, 7, 10, 3, 0, 0, 18163, 24923, 0, 24918, 24785, 24784, 24786, 24922, 24920, 0, 0),
(602821, 56, 4, 1, 1, 6, 4, 2, 1, 8, 0, 0, 23567, 0, 20505, 18859, 0, 546, 0, 0, 11887, 0),
(602830, 1563, 7, 0, 1, 2, 4, 2, 5, 6, 0, 13168, 146475, 0, 13566, 0, 153311, 155409, 156497, 0, 0, 0),
(602831, 56, 4, 1, 1, 3, 5, 6, 4, 6, 0, 145062, 0, 0, 147338, 150408, 8867, 154572, 0, 0, 0, 0),
(602835, 49, 1, 0, 1, 6, 9, 8, 9, 7, 0, 0, 0, 147156, 148603, 150217, 3293, 154359, 0, 156857, 0, 0),
(602870, 1563, 7, 0, 1, 1, 5, 3, 4, 5, 0, 12043, 0, 10380, 10381, 10382, 2059, 2505, 0, 2992, 0, 0),
(602871, 16125, 11, 0, 1, 5, 3, 4, 4, 3, 0, 167118, 0, 29625, 27549, 18441, 18442, 22475, 0, 0, 0, 0),
(602890, 55, 4, 0, 1, 6, 5, 4, 1, 3, 0, 12569, 0, 3564, 7557, 12555, 1174, 12570, 0, 12571, 0, 0),
(602910, 1563, 7, 0, 1, 2, 3, 5, 7, 3, 0, 11548, 0, 11541, 10381, 5637, 6224, 4701, 0, 8347, 0, 0),
(602911, 56, 4, 1, 1, 2, 7, 3, 5, 5, 0, 0, 0, 0, 147352, 150419, 152386, 154587, 156248, 157038, 0, 0),
(602920, 55, 4, 0, 1, 5, 1, 1, 2, 1, 0, 0, 12046, 19078, 5210, 0, 5212, 19079, 0, 12546, 0, 0),
(602952, 53, 3, 0, 1, 4, 6, 4, 7, 9, 0, 0, 0, 0, 0, 3517, 3609, 3519, 3520, 3521, 0, 0),
(602960, 1478, 8, 0, 1, 2, 1, 4, 6, 3, 0, 5072, 8316, 9795, 5512, 9017, 152438, 0, 0, 9005, 0, 0),
(603241, 53, 3, 0, 1, 2, 3, 2, 4, 6, 0, 12033, 0, 11641, 9812, 3369, 642, 3542, 3560, 1214, 0, 0),
(603271, 53, 3, 0, 1, 1, 2, 3, 6, 8, 0, 0, 0, 7323, 41797, 2446, 7324, 6346, 0, 0, 0, 0),
(603400, 1564, 7, 1, 1, 3, 2, 4, 6, 0, 0, 0, 0, 0, 13029, 150266, 152208, 154412, 0, 0, 0, 0),
(603410, 50, 1, 1, 1, 3, 5, 10, 4, 0, 0, 0, 5923, 5921, 0, 5922, 5747, 5675, 0, 5924, 17925, 0),
(650280, 49, 1, 0, 1, 1, 6, 3, 2, 6, 0, 0, 26965, 0, 27948, 26918, 26916, 26980, 26913, 26915, 0, 3734),
(650282, 50, 1, 1, 1, 2, 3, 5, 7, 1, 0, 0, 15606, 0, 12994, 24129, 0, 1246, 0, 0, 32030, 0),
(650286, 50, 1, 1, 1, 2, 4, 7, 3, 0, 0, 0, 146200, 147781, 148969, 3634, 152862, 155023, 0, 157420, 0, 3734),
(650287, 49, 1, 0, 1, 4, 7, 6, 2, 1, 0, 167120, 0, 0, 4966, 1542, 2130, 762, 0, 1458, 0, 0),
(650289, 49, 1, 0, 1, 7, 2, 0, 0, 0, 0, 12044, 0, 0, 147218, 150284, 152226, 154430, 0, 0, 0, 0),
(650291, 49, 1, 0, 1, 3, 4, 7, 8, 4, 0, 0, 0, 7850, 7851, 0, 7852, 2921, 0, 5628, 0, 158400),
(650295, 49, 1, 0, 1, 3, 5, 5, 4, 4, 0, 0, 0, 0, 0, 151593, 153736, 155777, 0, 0, 0, 0),
(650324, 55, 4, 0, 1, 2, 4, 5, 6, 2, 0, 30727, 19612, 19610, 6886, 9055, 9843, 19611, 9847, 7738, 17865, 0),
(650325, 49, 1, 0, 1, 4, 3, 6, 1, 3, 0, 24176, 163670, 163668, 164247, 164706, 163672, 18294, 13359, 18295, 0, 0),
(650326, 56, 4, 1, 1, 0, 2, 6, 7, 3, 0, 6071, 19164, 14268, 6751, 0, 5663, 19165, 0, 5626, 0, 0),
(650340, 49, 1, 0, 1, 2, 4, 3, 5, 6, 0, 0, 146193, 147774, 148962, 150825, 152852, 155012, 0, 157411, 0, 0),
(650341, 56, 4, 1, 1, 4, 3, 5, 3, 2, 0, 1913, 17631, 17632, 5673, 7493, 1044, 2905, 0, 7573, 0, 0),
(650342, 53, 3, 0, 1, 5, 7, 7, 5, 10, 0, 0, 0, 548, 0, 2286, 7510, 7511, 0, 7512, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (503923, 503924, 600292, 600344, 602770, 602771, 602772, 602780, 602800, 602801, 602821, 602830, 602831, 602835, 602870, 602871, 602890, 602910, 602911, 602920, 602952, 602960, 603241, 603271, 603400, 603410, 650280, 650282, 650286, 650287, 650289, 650291, 650295, 650324, 650325, 650326, 650340, 650341, 650342);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(503923, 1, 2549, 0, 0),
(503924, 1, 18842, 0, 0),
(600292, 1, 17071, 19309, 0),
(600344, 1, 12482, 12482, 0),
(602770, 1, 21398, 0, 0),
(602771, 1, 19104, 0, 0),
(602772, 1, 810, 17106, 0),
(602780, 1, 14541, 0, 0),
(602800, 1, 22808, 20688, 0),
(602801, 1, 21407, 19349, 0),
(602821, 1, 15041, 0, 0),
(602830, 1, 21404, 0, 0),
(602831, 1, 17780, 0, 0),
(602835, 1, 21416, 0, 0),
(602870, 1, 23221, 0, 19368),
(602871, 1, 24384, 0, 18573),
(602890, 1, 21392, 21401, 0),
(602910, 1, 15216, 0, 0),
(602911, 1, 21413, 21471, 0),
(602920, 1, 12795, 0, 0),
(602952, 1, 6830, 0, 0),
(602960, 1, 9482, 0, 0),
(603241, 1, 21395, 6254, 0),
(603271, 1, 21703, 0, 0),
(603400, 1, 5201, 0, 0),
(603410, 1, 21520, 0, 17069),
(650280, 1, 7721, 7188, 0),
(650282, 1, 21715, 19366, 0),
(650286, 1, 18717, 0, 0),
(650287, 1, 6219, 0, 15995),
(650289, 1, 2000005, 0, 0),
(650291, 1, 21521, 21471, 0),
(650295, 1, 7717, 0, 0),
(650324, 1, 9380, 12602, 0),
(650325, 1, 6802, 0, 15809),
(650326, 1, 6505, 0, 0),
(650340, 1, 13000, 0, 0),
(650341, 1, 17368, 0, 11271),
(650342, 1, 20556, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (503923, 503924, 600292, 600344, 602770, 602771, 602772, 602780, 602800, 602801, 602821, 602830, 602831, 602835, 602870, 602871, 602890, 602910, 602911, 602920, 602952, 602960, 603241, 603271, 603400, 603410, 650280, 650282, 650286, 650287, 650289, 650291, 650295, 650324, 650325, 650326, 650340, 650341, 650342);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(503923, 900023),
(503924, 900023),
(600292, 900020),
(600344, 900014),
(602770, 900016),
(602771, 900016),
(602772, 900016),
(602780, 900017),
(602800, 900019),
(602801, 900019),
(602821, 900022),
(602830, 900025),
(602831, 900025),
(602835, 900025),
(602870, 900028),
(602871, 900028),
(602890, 900030),
(602910, 900032),
(602911, 900032),
(602920, 900020),
(602952, 900012),
(602960, 900013),
(603241, 900018),
(603271, 900027),
(603400, 900024),
(603410, 900021),
(650280, 900019),
(650282, 900022),
(650286, 900027),
(650287, 900028),
(650289, 900030),
(650291, 900032),
(650295, 900012),
(650324, 900018),
(650325, 900015),
(650326, 900026),
(650340, 900024),
(650341, 900021),
(650342, 900031);

-- ---------------------------------------------------------------------------
-- 3. Surellion Trueshot speaks her own cached text (npccache 205914)
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` = 205914;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(205914, 'WILD STRIKE! WILD STRIKE! <Surellion seems so focused on training she doesn''t notice you.> HMPH! TOO SLOW! WILD STRIKE! FLANK! WILD STRIKE! <It looks like she''s not going to ever notice you.> <Perhaps it would be wise to observe her as she trains instead.>', 'WILD STRIKE! WILD STRIKE! <Surellion seems so focused on training she doesn''t notice you.> HMPH! TOO SLOW! WILD STRIKE! FLANK! WILD STRIKE! <It looks like she''s not going to ever notice you.> <Perhaps it would be wise to observe her as she trains instead.>', 0, 0, 1, 1, 1, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` = 930600;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930600, 205914),
(930600, 102056);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 930600;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930600, 0, 3, 'I seek training as a Ranger.', 0, 5, 16, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` = 930600 AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930600, 205914, 0, 0, 15, 0, 1048576, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Ranger'),
(14, 930600, 102056, 0, 0, 15, 0, 1048576, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Ranger'),
(15, 930600, 0, 0, 0, 15, 0, 1048576, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Ranger');

-- ---------------------------------------------------------------------------
-- 4. Posts
-- ---------------------------------------------------------------------------
-- Each post was chosen from floor maps of its hall (surface.surfaces rendered at the hall floor;
-- inspect_area only shows the city WMO overhead in Stormwind), then passes surface.check with no wall
-- within 3 yd ahead and no creature within 2.5 yd, game event spawns included. No walking NPC comes
-- within 2.5 yd either: waypoint_data paths of creature_addon and creature_template_addon, SmartAI
-- waypoints, the loop back to the first node, the splines of smooth paths and every wander radius.
-- Stormwind:
-- 9004500 Barbarian: hand-placed (INFERRED) Command Center in Old Town (the stock warrior barracks CoA rebuilt),
--   south-east end of the lower hall, 8.3 yd from Wu Shen and 8.7 yd from Ilsa Corbin; faces 0.742 toward the west
--   corner of the hall, where the stair from the porch comes in
-- 9004501 Guardian: hand-placed (INFERRED) Pig and Whistle Tavern in Old Town, west end of the taproom beyond the
--   round table, 3.6 yd from the nearest chair, 4.7 yd clear of Elly Langston's rounds; faces 3.800 toward the
--   taproom between its two ways in: the east door 60 degrees to his left and the step down from the south-west
--   porch 90 degrees to his right
-- 9004502 Templar: hand-placed (INFERRED) Cathedral of Light nave, west side by the paladin chapel, 8.1 yd from
--   Katherine the Pure; faces 4.182 toward the nave door players come in through (south-east)
-- 9004503 Sun Cleric: hand-placed (INFERRED) Cathedral of Light nave, east half near the door end, between the
--   east arcade and Thomas' walk down the nave (4.5 yd) and 10.4 yd from Brother Benjamin's walk along the east
--   aisle; faces 3.600 toward the main door at the south end of the nave, the way players come in
-- 9004504 Witch Doctor: hand-placed (INFERRED) The Park, on the lawn east of the elven picnic table, 6.7 yd from
--   Maldryn and 5.6 yd clear of the Grant sisters' walk; faces 4.310 toward the lawn and the moonwell ring players
--   cross, the picnic table at his right
-- 9004505 Witch Hunter: hand-placed (INFERRED) Cathedral Square, open paving 29 yd south of the cathedral; faces
--   3.961 toward the square and the road from the orphanage
-- 9004506 Stormbringer: hand-placed (INFERRED) lakeshore knoll below the Valley of Heroes, 5.4 yd from Farseer
--   Umbrua at the shaman trainer's post; faces 0.771 toward the shore path from the city side (north-west)
-- 9004507 Bloodmage: hand-placed (INFERRED) Slaughtered Lamb taproom in the Mage Quarter, 7.3 yd from the
--   bartender Jarel Moor; faces 5.007 toward the tavern door under the Slaughtered Lamb sign
-- 9004508 Ranger: hand-placed (INFERRED) Dwarven District, plaza in front of the hunters' lodge, 11.7 yd from the
--   stable master Jenova Stoneshield; faces 3.546 toward the plaza below the lodge
-- 9004509 Chronomancer: hand-placed (INFERRED) Wizard's Sanctum under the Mage Quarter tower, middle of the hall,
--   7.3 yd from Elsharin; faces 2.671 toward the arrival point of the tower portal (areatrigger_teleport 704) at
--   the south-west end
-- 9004510 Necromancer: hand-placed (INFERRED) Slaughtered Lamb cellar in the Mage Quarter, west side by the west
--   stair, 5.6 yd from Sandahl; faces 5.587 toward the fire pit at the centre of the cellar and the north-east
--   stair
-- 9004511 Pyromancer: hand-placed (INFERRED) Dwarven District, beside the dwarven brazier west of the forge
--   pavilion; faces 0.371 toward the forge pavilion and the street in front of it
-- 9004512 Cultist: hand-placed (INFERRED) Slaughtered Lamb cellar in the Mage Quarter, east side near the north-
--   east stair, 4.7 yd from Ursula Deline; faces 2.394 toward the fire pit at the centre of the cellar and the
--   west stair
-- 9004513 Tinker: hand-placed (INFERRED) Dwarven District, engineering yard by the salvage crates, 6.7 yd from
--   Sprite Jumpsprocket; faces 5.498 toward the engineers Lilliam Sparkspindle and Billibub Cogspinner
-- 9004514 Reaper: hand-placed (INFERRED) Stormwind City Cemetery (CoA area 10276), at the foot of the stair down
--   from the cathedral; faces 3.824 toward the stair players come down
-- 9004515 Runemaster: hand-placed (INFERRED) Wizard's Sanctum under the Mage Quarter tower, north-east half of the
--   hall, 8.8 yd from Jennea Cannon; faces 2.342 toward the arrival point of the tower portal
--   (areatrigger_teleport 704) at the south-west end
-- Ironforge:
-- 9004516 Barbarian: hand-placed (INFERRED) Hall of Arms in the Military Ward, warriors' hall, south-east end by
--   the brazier, 12.1 yd from Kelstrum Stonebreaker; faces 6.012 toward the opening of the hall onto the Military
--   Ward square
-- 9004517 Guardian: hand-placed (INFERRED) Hall of Arms in the Military Ward, warriors' hall, north-west end, 7.6
--   yd from Bilban Tosslespanner; faces 4.359 toward the opening of the hall onto the Military Ward square
-- 9004518 Templar: hand-placed (INFERRED) Hall of Mysteries in the Mystic Ward, north-west dais by the paladins,
--   11.0 yd from Braenna Flintcrag; faces 4.429 toward the south-east door of the hall
-- 9004519 Sun Cleric: hand-placed (INFERRED) Hall of Mysteries in the Mystic Ward, upper gallery, 8.9 yd from
--   Valgar Highforge; faces 3.827 toward the gallery ring and the open hall below
-- 9004520 Tinker: hand-placed (INFERRED) Tinker Town, cavern floor 6 yd east of the main walkway, below the sunken
--   bay east of the tunnel mouth, clear of Courier Hammerfall's walk; faces 0.340 toward the tunnel mouth from the
--   Commons at the north end of Tinker Town, where players come in
-- 9004521 Pyromancer: hand-placed (INFERRED) The Great Forge, forge floor beside the great bellows; faces 5.681
--   toward the blacksmiths' floor
-- 9004522 Runemaster: hand-placed (INFERRED) Hall of Explorers, beside the titan vase on the gallery's east side;
--   faces 3.737 toward the gallery under the hanging dragon skeleton
-- 9004523 Primalist: hand-placed (INFERRED) Military Ward square between the Hall of Arms and the hunters' hall,
--   by the brazier; faces 2.678 toward the square
-- 9004524 Stormbringer: hand-placed (INFERRED) ring road in front of Farseer Javad's shaman alcove, 17.8 yd from
--   Javad; faces 2.595 toward the road from the Great Forge
-- 9004525 Necromancer: hand-placed (INFERRED) The Forlorn Cavern, east floor by the brazier near Jubahl
--   Corpseseeker; faces 2.061 toward the cavern floor
-- 9004526 Cultist: hand-placed (INFERRED) The Forlorn Cavern, north-west floor, 11.8 yd from Ransin Donner; faces
--   5.034 toward the cavern floor
-- Darnassus:
-- 9004527 Felsworn: hand-placed (INFERRED) Warrior's Terrace, upper walk, east side by the balcony edge, 8.7 yd
--   from Thyn'tel Bladeweaver, 3.7 yd clear of the huntresses' patrol and away from the herald's crossing; faces
--   2.210 toward the head of the west stair where players and the herald come up onto the walk
-- 9004528 Knight of Xoroth: hand-placed (INFERRED) Warrior's Terrace, upper walk, north end, 12.1 yd from Thyn'tel
--   Bladeweaver; faces 3.039 toward the north stair head of the walk
-- 9004529 Stormbringer: hand-placed (INFERRED) Temple Gardens islet, by the street lamp 1.8 yd inside the north-
--   east rim, 5.2 yd from Alaindia's herb stop and 12.6 yd from Firodren Mooncaller; faces 2.387 toward the garden
--   path onto the islet, its only way in
-- 9004530 Templar: hand-placed (INFERRED) Temple of the Moon, lower ring, south-east side, 16.5 yd from Lariia;
--   faces 0.315 toward the temple door
-- 9004531 Bloodmage: hand-placed (INFERRED) Craftsmen's Terrace, at the open mouth of the covered alchemy hall,
--   8.0 yd from Milla Fairancora and 11.5 yd from Ainethil; faces 5.500 toward the foot of the raised walkway,
--   where players step down onto the terrace; the alchemy hall is behind him
-- 9004532 Ranger: hand-placed (INFERRED) training dummies north of the Warrior's Terrace, 4.7 yd from the Heroic
--   Training Dummy (her cached text has her drilling "WILD STRIKE! FLANK!", npccache 205914), 3.2 yd clear of the
--   wander of the Brewfest elekk 207085; faces 5.380 toward the Heroic Training Dummy she drills on, with the open
--   lawn beyond it
-- 9004533 Chronomancer: hand-placed (INFERRED) west colonnade of the Temple of the Moon grounds, 9.7 yd from Chief
--   Archaeologist Greywhisker; faces 4.766 toward the Temple of the Moon
-- 9004534 Cultist: hand-placed (INFERRED) lower Cenarion Enclave cave, 17-31 yd from the rogue trainers' posts;
--   faces 0.111 toward the cave passage up to Syurna and Anishar
-- 9004535 Starcaller: hand-placed (INFERRED) Temple of the Moon, lower ring, west side, 25.3 yd from Sentinel
--   Dalia Sunblade; faces 5.867 toward the temple door
-- 9004536 Tinker: hand-placed (INFERRED) Craftsmen's Terrace, outside Mythrin'dir's trade supplies shop; faces
--   2.336 toward the terrace path
-- 9004537 Reaper: hand-placed (INFERRED) lower Cenarion Enclave cave, 9.8 yd from Erion Shadewhisper; faces 5.543
--   toward the cave passage up to the rogues
-- 9004538 Runemaster: hand-placed (INFERRED) Craftsmen's Terrace, enchanting hall, 8 yd from Taladan; faces 4.467
--   toward the hall floor and its door
DELETE FROM `creature` WHERE `guid` IN (9004500, 9004501, 9004502, 9004503, 9004504, 9004505, 9004506, 9004507, 9004508, 9004509, 9004510, 9004511, 9004512, 9004513, 9004514, 9004515, 9004516, 9004517, 9004518, 9004519, 9004520, 9004521, 9004522, 9004523, 9004524, 9004525, 9004526, 9004527, 9004528, 9004529, 9004530, 9004531, 9004532, 9004533, 9004534, 9004535, 9004536, 9004537, 9004538) OR `guid` BETWEEN 9004500 AND 9004649;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004500, 650295, 0, 0, 0, 1, 1, 1, -8810, 327, 115.466, 0.742, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Barbarian trainer: Command Center in Old Town (the stock warrior barracks CoA rebuilt), south-east end of the lower hall, 8.3 yd from Wu Shen and 8.7 yd from Ilsa Corbin; faces the west corner of the hall, where the stair from the porch comes in'),
(9004501, 650324, 0, 0, 0, 1, 1, 1, -8621, 412.5, 102.924, 3.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Guardian trainer: Pig and Whistle Tavern in Old Town, west end of the taproom beyond the round table, 3.6 yd from the nearest chair, 4.7 yd clear of Elly Langston''s rounds; faces the taproom between its two ways in: the east door 60 degrees to his left and the step down from the south-west porch 90 degrees to his right'),
(9004502, 650280, 0, 0, 0, 1, 1, 1, -8541, 861, 106.518, 4.182, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Templar trainer: Cathedral of Light nave, west side by the paladin chapel, 8.1 yd from Katherine the Pure; faces the nave door players come in through (south-east)'),
(9004503, 650286, 0, 0, 0, 1, 1, 1, -8547.5, 828, 106.519, 3.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Sun Cleric trainer: Cathedral of Light nave, east half near the door end, between the east arcade and Thomas'' walk down the nave (4.5 yd) and 10.4 yd from Brother Benjamin''s walk along the east aisle; faces the main door at the south end of the nave, the way players come in'),
(9004504, 602960, 0, 0, 0, 1, 1, 1, -8746, 1129, 93.24, 4.31, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Witch Doctor trainer: The Park, on the lawn east of the elven picnic table, 6.7 yd from Maldryn and 5.6 yd clear of the Grant sisters'' walk; faces the lawn and the moonwell ring players cross, the picnic table at his right'),
(9004505, 650325, 0, 0, 0, 1, 1, 1, -8598, 815, 96.903, 3.961, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Witch Hunter trainer: Cathedral Square, open paving 29 yd south of the cathedral; faces the square and the road from the orphanage'),
(9004506, 602770, 0, 0, 0, 1, 1, 1, -9037, 549.5, 73.83, 0.771, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Stormbringer trainer: lakeshore knoll below the Valley of Heroes, 5.4 yd from Farseer Umbrua at the shaman trainer''s post; faces the shore path from the city side (north-west)'),
(9004507, 600292, 0, 0, 0, 1, 1, 1, -8948.5, 998.5, 122.026, 5.007, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Bloodmage trainer: Slaughtered Lamb taproom in the Mage Quarter, 7.3 yd from the bartender Jarel Moor; faces the tavern door under the Slaughtered Lamb sign'),
(9004508, 603410, 0, 0, 0, 1, 1, 1, -8436, 566, 95.243, 3.546, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Ranger trainer: Dwarven District, plaza in front of the hunters'' lodge, 11.7 yd from the stable master Jenova Stoneshield; faces the plaza below the lodge'),
(9004509, 650282, 0, 0, 0, 1, 1, 1, -9002.5, 879.5, 29.621, 2.671, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Chronomancer trainer: Wizard''s Sanctum under the Mage Quarter tower, middle of the hall, 7.3 yd from Elsharin; faces the arrival point of the tower portal (areatrigger_teleport 704) at the south-west end'),
(9004510, 503923, 0, 0, 0, 1, 1, 1, -8988.5, 1039.5, 101.404, 5.587, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Necromancer trainer: Slaughtered Lamb cellar in the Mage Quarter, west side by the west stair, 5.6 yd from Sandahl; faces the fire pit at the centre of the cellar and the north-east stair'),
(9004511, 650340, 0, 0, 0, 1, 1, 1, -8440.5, 609, 94.841, 0.371, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Pyromancer trainer: Dwarven District, beside the dwarven brazier west of the forge pavilion; faces the forge pavilion and the street in front of it'),
(9004512, 602835, 0, 0, 0, 1, 1, 1, -8972.5, 1025.5, 101.404, 2.394, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Cultist trainer: Slaughtered Lamb cellar in the Mage Quarter, east side near the north-east stair, 4.7 yd from Ursula Deline; faces the fire pit at the centre of the cellar and the west stair'),
(9004513, 650287, 0, 0, 0, 1, 1, 1, -8355, 652, 95.551, 5.498, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Tinker trainer: Dwarven District, engineering yard by the salvage crates, 6.7 yd from Sprite Jumpsprocket; faces the engineers Lilliam Sparkspindle and Billibub Cogspinner'),
(9004514, 650289, 0, 0, 0, 1, 1, 1, -8470, 903.5, 99.038, 3.824, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Reaper trainer: Stormwind City Cemetery (CoA area 10276), at the foot of the stair down from the cathedral; faces the stair players come down'),
(9004515, 650291, 0, 0, 0, 1, 1, 1, -8998, 866.5, 29.621, 2.342, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Runemaster trainer: Wizard''s Sanctum under the Mage Quarter tower, north-east half of the hall, 8.8 yd from Jennea Cannon; faces the arrival point of the tower portal (areatrigger_teleport 704) at the south-west end'),
(9004516, 602952, 0, 0, 0, 1, 1, 1, -5054, -1251, 507.755, 6.012, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Barbarian trainer: Hall of Arms in the Military Ward, warriors'' hall, south-east end by the brazier, 12.1 yd from Kelstrum Stonebreaker; faces the opening of the hall onto the Military Ward square'),
(9004517, 603241, 0, 0, 0, 1, 1, 1, -5029, -1231, 507.754, 4.359, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Guardian trainer: Hall of Arms in the Military Ward, warriors'' hall, north-west end, 7.6 yd from Bilban Tosslespanner; faces the opening of the hall onto the Military Ward square'),
(9004518, 602800, 0, 0, 0, 1, 1, 1, -4620.5, -896.5, 504.248, 4.429, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Templar trainer: Hall of Mysteries in the Mystic Ward, north-west dais by the paladins, 11.0 yd from Braenna Flintcrag; faces the south-east door of the hall'),
(9004519, 603271, 0, 0, 0, 1, 1, 1, -4588.5, -896.5, 524.695, 3.827, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Sun Cleric trainer: Hall of Mysteries in the Mystic Ward, upper gallery, 8.9 yd from Valgar Highforge; faces the gallery ring and the open hall below'),
(9004520, 602870, 0, 0, 0, 1, 1, 1, -4817, -1281, 501.868, 0.34, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Tinker trainer: Tinker Town, cavern floor 6 yd east of the main walkway, below the sunken bay east of the tunnel mouth, clear of Courier Hammerfall''s walk; faces the tunnel mouth from the Commons at the north end of Tinker Town, where players come in'),
(9004521, 603400, 0, 0, 0, 1, 1, 1, -4806, -1101, 498.807, 5.681, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Pyromancer trainer: The Great Forge, forge floor beside the great bellows; faces the blacksmiths'' floor'),
(9004522, 602910, 0, 0, 0, 1, 1, 1, -4609, -1254, 503.382, 3.737, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Runemaster trainer: Hall of Explorers, beside the titan vase on the gallery''s east side; faces the gallery under the hanging dragon skeleton'),
(9004523, 650342, 0, 0, 0, 1, 1, 1, -5026, -1262, 505.3, 2.678, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Primalist trainer: Military Ward square between the Hall of Arms and the hunters'' hall, by the brazier; faces the square'),
(9004524, 602771, 0, 0, 0, 1, 1, 1, -4737, -1144, 502.212, 2.595, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Stormbringer trainer: ring road in front of Farseer Javad''s shaman alcove, 17.8 yd from Javad; faces the road from the Great Forge'),
(9004525, 503924, 0, 0, 0, 1, 1, 1, -4617, -1130, 501.327, 2.061, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Necromancer trainer: The Forlorn Cavern, east floor by the brazier near Jubahl Corpseseeker; faces the cavern floor'),
(9004526, 602830, 0, 0, 0, 1, 1, 1, -4630, -1100, 501.294, 5.034, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Cultist trainer: The Forlorn Cavern, north-west floor, 11.8 yd from Ransin Donner; faces the cavern floor'),
(9004527, 600344, 1, 0, 0, 1, 1, 1, 9963, 2276, 1341.394, 2.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Felsworn trainer: Warrior''s Terrace, upper walk, east side by the balcony edge, 8.7 yd from Thyn''tel Bladeweaver, 3.7 yd clear of the huntresses'' patrol and away from the herald''s crossing; faces the head of the west stair where players and the herald come up onto the walk'),
(9004528, 602780, 1, 0, 0, 1, 1, 1, 9973, 2289, 1341.394, 3.039, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Knight of Xoroth trainer: Warrior''s Terrace, upper walk, north end, 12.1 yd from Thyn''tel Bladeweaver; faces the north stair head of the walk'),
(9004529, 602772, 1, 0, 0, 1, 1, 1, 9760.5, 2418.5, 1334.48, 2.387, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Stormbringer trainer: Temple Gardens islet, by the street lamp 1.8 yd inside the north-east rim, 5.2 yd from Alaindia''s herb stop and 12.6 yd from Firodren Mooncaller; faces the garden path onto the islet, its only way in'),
(9004530, 602801, 1, 0, 0, 1, 1, 1, 9626, 2502, 1331.892, 0.315, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Templar trainer: Temple of the Moon, lower ring, south-east side, 16.5 yd from Lariia; faces the temple door'),
(9004531, 602920, 1, 0, 0, 1, 1, 1, 10080, 2360, 1321.584, 5.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Bloodmage trainer: Craftsmen''s Terrace, at the open mouth of the covered alchemy hall, 8.0 yd from Milla Fairancora and 11.5 yd from Ainethil; faces the foot of the raised walkway, where players step down onto the terrace; the alchemy hall is behind him'),
(9004532, 650341, 1, 0, 0, 1, 1, 1, 9996.5, 2256.5, 1330.011, 5.38, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Ranger trainer: training dummies north of the Warrior''s Terrace, 4.7 yd from the Heroic Training Dummy (her cached text has her drilling "WILD STRIKE! FLANK!", npccache 205914), 3.2 yd clear of the wander of the Brewfest elekk 207085; faces the Heroic Training Dummy she drills on, with the open lawn beyond it'),
(9004533, 602821, 1, 0, 0, 1, 1, 1, 9636, 2600, 1337.293, 4.766, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Chronomancer trainer: west colonnade of the Temple of the Moon grounds, 9.7 yd from Chief Archaeologist Greywhisker; faces the Temple of the Moon'),
(9004534, 602831, 1, 0, 0, 1, 1, 1, 10067, 2543, 1284.507, 0.111, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Cultist trainer: lower Cenarion Enclave cave, 17-31 yd from the rogue trainers'' posts; faces the cave passage up to Syurna and Anishar'),
(9004535, 650326, 1, 0, 0, 1, 1, 1, 9620, 2540, 1331.558, 5.867, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Starcaller trainer: Temple of the Moon, lower ring, west side, 25.3 yd from Sentinel Dalia Sunblade; faces the temple door'),
(9004536, 602871, 1, 0, 0, 1, 1, 1, 10112, 2307.5, 1329.142, 2.336, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Tinker trainer: Craftsmen''s Terrace, outside Mythrin''dir''s trade supplies shop; faces the terrace path'),
(9004537, 602890, 1, 0, 0, 1, 1, 1, 10062, 2566, 1283.756, 5.543, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Reaper trainer: lower Cenarion Enclave cave, 9.8 yd from Erion Shadewhisper; faces the cave passage up to the rogues'),
(9004538, 602911, 1, 0, 0, 1, 1, 1, 10140, 2326, 1333, 4.467, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Runemaster trainer: Craftsmen''s Terrace, enchanting hall, 8 yd from Taladan; faces the hall floor and its door');
