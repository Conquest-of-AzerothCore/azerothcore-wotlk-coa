-- Extend creature health parity to the captured CoA templates still differing in the workspace database.
-- Source: hertigservices/ascension-data, data-cache-3761f8c7276d7ee2745e.
-- cachedata/by-mode/conquest-of-azeroth/creaturecache.tsv.gz
-- SHA256: 80db1cc82be2653074592a42a2dc644d88b01cfce858bf4cf7af06091baf59bf.
-- 6111 captured entries; only creature_template.HealthModifier is updated.
-- Nonpositive values and rank-zero sentinel multipliers are omitted.
-- Reimplemented raid NPCs, summons, visual forms and difficulty variants are omitted.
-- Raids: Molten Core, Onyxia's Lair, Blackwing Lair, Zul'Gurub, Ruins and Temple of Ahn'Qiraj.
-- Scope: PRs #5120, #6015, #5750 and #6259, including the restored world bosses and Basalthane.
-- The update excludes missing base-stat rows and health products that exceed uint32.
DROP TEMPORARY TABLE IF EXISTS `_coa_captured_creature_health`;
CREATE TEMPORARY TABLE `_coa_captured_creature_health` (
    `entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `HealthModifier` FLOAT NOT NULL
) ENGINE = InnoDB;

DELETE FROM `_coa_captured_creature_health`;
INSERT INTO `_coa_captured_creature_health` (`entry`, `HealthModifier`) VALUES
(19, 0.928625), -- Benny Questgiver
(25, 0.928625), -- Mithril Mechanical Dragonling
(49, 0.9), -- Lesser Succubus
(90, 1.5), -- Sea Giant
(106, 1.25), -- Kodo Beast
(149, 0.5), -- [UNUSED] Small Black Dragon Whelp
(262, 1.485), -- Half-eaten body
(280, 1.485), -- Placeholder - Jasperlode Mine
(287, 1.485), -- Placeholder - Darkhollow Mine
(290, 1.485), -- Placeholder - Fargodeep Mine
(303, 4.05), -- Placeholder Interactive Doodad - jk
(418, 1.1), -- Lesser Voidwalker
(537, 0.89559), -- Defias Trainee
(575, 1.0), -- Summoned Fire Guardian
(603, 2.0), -- Grimtooth
(936, 2.032), -- Guard Adams
(1001, 8.0), -- Watcher Hutchins
(1055, 1.5625), -- Dreamhunter
(1056, 1.5), -- Emerald Sentinel
(1100, 8.0), -- Watcher Selkin
(1233, 7.5), -- [UNUSED] Shaethis Darkoak
(1409, 1.2075), -- Moorah Stormhoof
(1494, 6.0), -- Negolash
(1604, 1.1), -- Druid 1
(1607, 1.1), -- Druid 5
(1608, 1.1), -- Druid 10
(1609, 1.1), -- Druid 15
(1616, 1.1), -- Druid 20
(1617, 1.155), -- Druid 30
(1619, 1.265), -- Druid 40
(1635, 1.1), -- Warrior 1
(1636, 1.1), -- Warrior 5
(1637, 1.1), -- Warrior 10
(1638, 1.1), -- Warrior 15
(1639, 1.1), -- Warrior 20
(1640, 1.155), -- Warrior 30
(1641, 1.265), -- Warrior 40
(1798, 1.215), -- Tortured Soul
(1800, 1.17), -- Cold Wraith
(1801, 1.215), -- Blood Wraith
(1843, 6.75), -- Foreman Jerris
(1861, 1.155), -- Greater Voidwalker
(1862, 1.3), -- Lesser Netherwalker
(1864, 0.945), -- Greater Succubus
(1925, 1.1), -- Heat Miser
(1926, 1.1), -- Snow Miser
(1927, 1.1), -- Good Miser
(1928, 1.1), -- Bad Miser
(1929, 1.1), -- Earth Miser
(1945, 1.5), -- Tree Form 0.33
(1964, 0.22), -- Treant
(2138, 1.122), -- Warrior 25
(2213, 1.1), -- Deth'ryll Shadowstalker
(2225, 14.6), -- Zora Guthrek
(2472, 6.25), -- Flamescale Drake
(2689, 1.875), -- Hill Giant
(2690, 1.875), -- Hill Giant Warden
(2746, 4.5), -- Stonevault Warden
(2794, 1.15), -- Summoned Guardian
(2833, 7.5), -- DEBUG - Gossip Gryphon Master
(2862, 1.122), -- Warrior 21
(2863, 1.122), -- Warrior 22
(2864, 1.122), -- Warrior 23
(2865, 1.122), -- Warrior 24
(2866, 1.155), -- Warrior 26
(2867, 1.155), -- Warrior 27
(2868, 1.155), -- Warrior 28
(2869, 1.155), -- Warrior 29
(2935, 1.375), -- [PH] Demon Master
(2943, 1.032), -- Ransin Donner
(3070, 1.05), -- [UNUSED] [PH] Mulgore Alchemy Trainer
(3071, 1.05), -- [UNUSED] [PH] Mulgore Herbalism Trainer
(3082, 2.1), -- [UNUSED] Narache Guard
(3302, 1.155), -- [UNUSED] Korl
(3303, 1.155), -- [UNUSED] Marna
(3343, 14.68), -- Grelkor
(3420, 1.05), -- [UNUSED] Ancestral Watcher
(3427, 1.05), -- [UNUSED] Kendur
(3440, 1.05), -- [UNUSED] Ancestral Sage
(3469, 102.0), -- Ancient of War
(3575, 7.5), -- Praenus Raxxeus
(3625, 14.6), -- Rarck
(3794, 16.9), -- Druid of the Talon
(3795, 16.9), -- Druid of the Claw
(3839, 3.3), -- Voidlasher
(3878, 1.1), -- Magthrull's Doomguard
(4255, 7.35), -- Brogus Thunderbrew
(4257, 29.25), -- Lana Thunderbrew
(4313, 1.1025), -- [UNUSED] [PH] Ambassador Saylaton Gravehoof
(4315, 1.1025), -- [UNUSED] Guthrin Gravehoof
(4487, 1.1025), -- Kodiak
(4683, 1.265), -- Doomwarder Lord
(4703, 1.5625), -- Raging Kodo
(4958, 1.0), -- Haunting Spirit
(5051, 1.071), -- [UNUSED] Frewa
(5134, 14.69), -- Jonivera Farmountain
(5135, 29.299999), -- Svalbrad Farmountain
(5139, 14.69), -- Kurdrum Barleybeard
(5315, 3.3), -- Jademir Dragonspawn
(5407, 1.25), -- Nightmare
(5436, 1.125), -- Tamed Bird
(5437, 1.375), -- Tamed Boar
(5442, 1.5625), -- Tamed Gorilla
(5448, 1.375), -- Tamed Turtle
(5468, 4.5), -- Wandering Dune Smasher
(5676, 1.1), -- Summoned Voidwalker
(5677, 0.9), -- Summoned Succubus
(5890, 0.93), -- Redrock Earth Spirit
(5954, 0.9), -- Shade (Deprecated)
(5963, 1.05), -- World Tauren Male Druid Trainer
(5972, 1.05), -- World Tauren Female Druid Trainer
(6092, 0.9), -- Minor Phantasm
(6106, 0.9), -- Lesser Phantasm
(6107, 0.027), -- Shade
(6108, 1.035), -- Greater Phantasm
(6268, 0.945), -- Summoned Felhunter
(6269, 1.1), -- Azgalaril
(6270, 0.9), -- Asjorah
(6326, 3.0), -- Horde Wargryphoner
(6327, 3.0), -- Alliance Wargryphoner
(6549, 3.3), -- Demon of the Orb
(7091, 1.0), -- Shadowforge Ambusher
(7127, 0.9), -- Jaedenar Stalker
(7128, 0.9), -- Jaedenar Mana Leech
(7129, 1.1), -- Enslaved Voidwalker
(7130, 1.1), -- Voidwalker Servant
(7131, 1.1), -- Voidwalker Guardian
(7150, 1.5), -- Withered Guardian
(7151, 1.5), -- Withered Watcher
(7152, 1.5), -- Withered Forest Walker
(7227, 3.3), -- Cobaltine Dragonspawn
(7293, 1.155), -- [UNUSED] Drayl
(7374, 1.08), -- Vengeful Wraith
(7375, 1.08), -- Spirit of Wrath
(7527, 0.75), -- Goblin Land Mine
(7739, 0.75), -- Red Mechanostrider
(7749, 0.75), -- Blue Mechanostrider
(8138, 1.0), -- Sul'lithuz Broodling
(8387, 1.256), -- Horizon Scout First Mate
(8388, 1.256), -- Horizon Scout Cook
(8407, 1.43), -- Makron the Corrupt
(8499, 0.9), -- TEST Uber Succubus
(8500, 12.5), -- TEST Uber Abomination
(8537, 1.17), -- Interloper
(8580, 21.92), -- Atal'alarion
(8599, 1.485), -- Plaguehound Mastiff
(8608, 1.69), -- Angered Infernal
(8680, 65.0), -- Massive Infernal
(8880, 0.75), -- Mechastrider
(9398, 4.0), -- Twilight's Hammer Executioner
(9417, 15.6), -- Sleeping Dragon
(9441, 16.0), -- Dark Keeper Zimrel
(9557, 3.15), -- [UNUSED] dun garok test
(9581, 1.3125), -- Thunder Bluff Talent Master
(9599, 2.025), -- Arei Transformed
(9686, 1.05), -- [PH] TESTTAUREN
(9705, 1.485), -- Illusionary Dreamwatcher
(10084, 0.5), -- Rage Talon Whelp
(10178, 0.75), -- Fluorescent Green Mechanostrider
(10179, 0.75), -- White Mechanostrider Mod B
(10203, 32.5), -- Berylgos
(10258, 11.55), -- Rookery Guardian
(10364, 22.5), -- Yaelika Farclaw
(10367, 14.5), -- Shrye Ragefist
(10401, 2.0), -- [UNUSED] Thuzadin Shadow Lord
(10403, 1.25), -- [UNUSED] Devouring Wight
(10404, 62.5), -- Pustulating Horror
(10538, 39.0), -- Vaelastrasz
(10683, 9.9), -- Rookery Hatcher
(10785, 2.1), -- Orb of Deception (Tauren, Male)
(10786, 2.1), -- Orb of Deception (Tauren, Female)
(10800, 1.0), -- Warosh the Redeemed
(10820, 3.75), -- Duke Ragereaver
(10981, 1.3), -- Frostwolf
(10982, 1.5), -- Whitewhisker Vermin
(10985, 12.0), -- Ice Giant
(10986, 7.6), -- Snowblind Harpy
(10987, 1.0), -- Irondeep Trogg
(10988, 1.6875), -- Kodo Spirit
(10991, 4.38), -- Wildpaw Gnoll
(11147, 0.75), -- Green Mechanostrider
(11148, 0.75), -- Purple Mechanostrider
(11149, 0.75), -- Red and Blue Mechanostrider
(11150, 0.75), -- Icy Blue Mechanostrider Mod A
(11151, 0.75), -- Riding MechaStrider (Yellow/Green)
(11258, 2.0), -- Frail Skeleton
(11263, 1.0), -- Spectral Projection
(11292, 1.625), -- Mossflayer Berserker
(11437, 1.365), -- Minor Infernal
(11474, 1.17), -- Eldreth Wraith
(11538, 1.05), -- TEST GEAR WARRIOR
(11547, 3.0), -- Skeletal Scholomance Student
(11597, 1.6875), -- Cheveyo
(11598, 1.0), -- Risen Guardian
(11600, 1.45), -- Irondeep Shaman
(11602, 1.75), -- Irondeep Skullthumper
(11603, 1.0), -- Whitewhisker Digger
(11604, 1.45), -- Whitewhisker Geomancer
(11605, 1.75), -- Whitewhisker Overseer
(11657, 2.43), -- Morloch
(11660, 75.0), -- [UNUSED] Molten Colossus
(11675, 7.8), -- Snowblind Windcaller
(11676, 37.5), -- Fjordune the Greater
(11677, 2.43), -- Taskmaster Snivvle
(11678, 7.66), -- Snowblind Ambusher
(11719, 1.155), -- Navi Quickdraw
(11837, 4.4), -- Wildpaw Shaman
(11838, 7.86), -- Wildpaw Mystic
(11839, 4.65), -- Wildpaw Brute
(11840, 8.1), -- Wildpaw Alpha
(11859, 1.1), -- Doomguard
(11946, 300.0), -- Drek'Thar
(11947, 140.0), -- Captain Galvangar
(11948, 300.0), -- Vanndar Stormpike
(11949, 140.0), -- Captain Balinda Stonehearth
(11959, 1.6875), -- [UNUSED] Obsidian Watcher
(11980, 30.0), -- Zuluhed the Whacked
(11997, 20.0), -- Stormpike Herald
(11998, 20.0), -- Frostwolf Herald
(12044, 1.155), -- Sun Rock Blacksmithing Supplies
(12048, 1.25), -- Alliance Sentinel
(12050, 0.6), -- Stormpike Defender
(12051, 0.88), -- Frostwolf Legionnaire
(12052, 1.25), -- Frostwolf Warrior
(12053, 0.6), -- Frostwolf Guardian
(12096, 14.7), -- Stormpike Quartermaster
(12097, 14.7), -- Frostwolf Quartermaster
(12121, 9.0), -- Draka
(12122, 9.0), -- Duros
(12127, 0.88), -- Stormpike Guardsman
(12200, 3.3), -- Cobaltine Wyrmkin
(12257, 0.9375), -- Mechanical Yeti
(12260, 37.5), -- Onyxian Drake
(12417, 1.5), -- [NOT USED] Death Talon Whelp
(12426, 2.0), -- Masterwork Target Dummy
(12469, 3.3), -- [NOT USED] Death Talon Earthshaker
(12739, 11.0), -- Onyxia's Elite Guard
(12741, 1.265), -- Warrior 40 (More Leash)
(12756, 325.0), -- Lady Onyxia
(12793, 2.1), -- Brave Stonehide
(12898, 25.0), -- Phantim Illusion
(13078, 2.9), -- Umi Thorson
(13079, 2.9), -- Keetar
(13080, 1.75), -- Irondeep Guard
(13081, 1.75), -- Irondeep Raider
(13083, 1.485), -- Echo of Archimonde
(13086, 2.9), -- Aggi Rumblestomp
(13087, 1.75), -- Coldmine Invader
(13088, 2.9), -- Masha Swiftcut
(13089, 1.75), -- Coldmine Guard
(13097, 1.45), -- Coldmine Surveyor
(13098, 1.45), -- Irondeep Surveyor
(13099, 1.45), -- Irondeep Explorer
(13138, 5.9), -- Lieutenant Spencer
(13139, 9.5), -- Commander Randolph
(13140, 9.5), -- Commander Dardosh
(13143, 5.9), -- Lieutenant Stronghoof
(13152, 5.6), -- Commander Malgor
(13153, 5.6), -- Commander Mulfort
(13154, 9.5), -- Commander Louis Philips
(13176, 29.25), -- Smith Regzar
(13179, 56.200001), -- Wing Commander Guse
(13180, 56.200001), -- Wing Commander Jeztor
(13181, 56.200001), -- Wing Commander Mulverick
(13236, 35.5), -- Primalist Thurloga
(13256, 319.0), -- Lokholar the Ice Lord
(13257, 28.0), -- Murgot Deepforge
(13281, 1.6875), -- Furis
(13284, 12.0), -- Frostwolf Shaman
(13316, 1.0), -- Coldmine Peon
(13317, 1.0), -- Coldmine Miner
(13318, 8.0), -- Commander Mortimer
(13319, 5.6), -- Commander Duffy
(13320, 9.5), -- Commander Karl Philips
(13324, 1.0), -- Seasoned Guardsman
(13325, 1.6), -- Seasoned Mountaineer
(13326, 0.75), -- Seasoned Defender
(13327, 1.4), -- Seasoned Sentinel
(13328, 0.75), -- Seasoned Guardian
(13329, 1.0), -- Seasoned Legionnaire
(13330, 1.4), -- Seasoned Warrior
(13331, 0.85), -- Veteran Defender
(13332, 0.85), -- Veteran Guardian
(13333, 1.1), -- Veteran Guardsman
(13334, 1.1), -- Veteran Legionnaire
(13335, 1.7), -- Veteran Mountaineer
(13336, 1.6), -- Veteran Sentinel
(13337, 1.6), -- Veteran Warrior
(13339, 1.485), -- Warrior 60
(13358, 1.3), -- Stormpike Bowman
(13359, 1.3), -- Frostwolf Bowman
(13396, 1.0), -- Irondeep Miner
(13397, 1.0), -- Irondeep Peon
(13419, 319.0), -- Ivus the Forest Lord
(13421, 1.0), -- Champion Guardian
(13422, 1.0), -- Champion Defender
(13424, 1.2), -- Champion Guardsman
(13425, 1.2), -- Champion Legionnaire
(13426, 1.8), -- Champion Mountaineer
(13427, 1.7), -- Champion Sentinel
(13428, 1.7), -- Champion Warrior
(13437, 56.200001), -- Wing Commander Ichman
(13438, 56.200001), -- Wing Commander Slidore
(13439, 56.200001), -- Wing Commander Vipore
(13440, 6.5), -- Frostwolf Wolf Rider
(13441, 23.5), -- Frostwolf Wolf Rider Commander
(13442, 35.5), -- Arch Druid Renferal
(13443, 12.0), -- Druid of the Grove
(13446, 15.5), -- Field Marshal Teravaine
(13447, 4.45), -- Corporal Noreg Stormpike
(13448, 12.0), -- Sergeant Yazra Bloodsnarl
(13449, 15.5), -- Warmaster Garrick
(13516, 3.885), -- Frostwolf Outrunner
(13517, 3.885), -- Seasoned Outrunner
(13518, 3.885), -- Veteran Outrunner
(13519, 3.885), -- Champion Outrunner
(13524, 4.25), -- Stormpike Commando
(13525, 4.75), -- Seasoned Commando
(13526, 5.25), -- Veteran Commando
(13527, 5.75), -- Champion Commando
(13528, 4.25), -- Frostwolf Reaver
(13529, 4.75), -- Seasoned Reaver
(13530, 5.25), -- Veteran Reaver
(13531, 5.75), -- Champion Reaver
(13576, 6.5), -- Stormpike Ram Rider
(13577, 23.5), -- Stormpike Ram Rider Commander
(13602, 3.8), -- The Abominable Greench
(13616, 22.0), -- Frostwolf Stable Master
(13617, 22.0), -- Stormpike Stable Master
(13676, 2.66), -- Stabled Alterac Ram
(13741, 3.75), -- Gelk
(13797, 5.6), -- Mountaineer Boombellow
(13798, 5.6), -- Jotek
(13916, 2.5), -- Dire Maul Crystal Totem
(13959, 12.0), -- Alterac Yeti
(14143, 20.299999), -- Azshara Huntress
(14185, 5.88), -- Najak Hexxen
(14186, 1.48), -- Ravak Grimtotem
(14187, 5.9), -- Athramanis
(14188, 7.07), -- Dirk Swindle
(14242, 7.875), -- [UNUSED] Sulhasa
(14282, 0.8), -- Frostwolf Bloodhound
(14283, 0.8), -- Stormpike Owl
(14346, 3.3), -- Captain Greshkil
(14385, 1.65), -- Doomguard Minion
(14388, 4.8), -- Rogue Black Drake
(14393, 3.04), -- Expeditionary Priest
(14406, 1.6875), -- Roving Kodo
(14435, 562.5), -- Prince Thunderaan
(14449, 1.35), -- Spirit Guide
(14452, 22.0), -- Enslaved Doomguard Commander
(14454, 6.75), -- The Windreaver
(14457, 6.75), -- Princess Tempestria
(14461, 6.75), -- Baron Charr
(14464, 6.75), -- Avalanchion
(14473, 5.0), -- Lapress
(14482, 0.75), -- Xorothian Imp
(14483, 16.5), -- Dread Guard
(14500, 0.75), -- J'eevee
(14501, 1.69), -- Warlock Mount Ritual Mob Type 3, Infernal (DND)
(14502, 12.5), -- Xorothian Dreadsteed
(14503, 220.0), -- The Cleaner
(14504, 5.0), -- Dreadsteed Spirit
(14511, 2.0), -- Shadowed Spirit
(14512, 2.0), -- Corrupted Spirit
(14513, 2.0), -- Malicious Spirit
(14514, 2.0), -- Banal Spirit
(14516, 40.0), -- Death Knight Darkreaver
(14518, 8.0), -- Aspect of Banality
(14519, 8.0), -- Aspect of Corruption
(14520, 8.0), -- Aspect of Malice
(14521, 8.0), -- Aspect of Shadow
(14533, 4.5), -- Simone the Seductress
(14538, 2.7), -- Precious the Devourer
(14554, 0.75), -- Swift Stripped Mechanostrider
(14562, 0.75), -- Swift Blue Mechanostrider
(14563, 0.75), -- Swift Red Mechanostrider
(14581, 2.1), -- Sergeant Thunderhorn
(14684, 15.0), -- Balzaphon
(14685, 7.5), -- Morbus
(14687, 4.5), -- Soulless
(14692, 12.5), -- Wollstonecraft
(14695, 25.0), -- Lord Blackwood
(14696, 1.875), -- Stitched Behemoth
(14697, 3.375), -- Lumbering Horror
(14698, 1.215), -- Silent Stalker
(14701, 4.5), -- Doom Wraith
(14762, 60.0), -- Dun Baldar North Marshal
(14763, 60.0), -- Dun Baldar South Marshal
(14764, 60.0), -- Icewing Marshal
(14765, 60.0), -- Stonehearth Marshal
(14772, 60.0), -- East Frostwolf Warmaster
(14773, 60.0), -- Iceblood Warmaster
(14776, 60.0), -- Tower Point Warmaster
(14777, 60.0), -- West Frostwolf Warmaster
(14823, 1.25), -- Silas Darkmoon
(14943, 35.799999), -- Guse's War Rider
(14944, 35.799999), -- Jeztor's War Rider
(14945, 35.799999), -- Mulverick's War Rider
(14946, 35.799999), -- Slidore's Gryphon
(14947, 35.799999), -- Ichman's Gryphon
(14948, 35.799999), -- Vipore's Gryphon
(15135, 1.25), -- Chromatic Drake Mount
(15203, 1248.670044), -- Prince Skaldrenox
(15204, 936.5), -- High Marshal Whirlaxis
(15205, 1248.670044), -- Baron Kazum
(15228, 5.07), -- Vekniss Tunneler
(15232, 10.14), -- Vekniss Marauder
(15237, 5.07), -- Vekniss Wrathstinger
(15241, 5.0), -- Gryphon Rider Guard
(15242, 2.5), -- Bat Rider Guard
(15305, 1248.670044), -- Lord Skwol
(15342, 1.6875), -- [UNUSED] Sphinx
(15349, 0.5), -- RC Blimp <PH>
(15359, 10.0), -- Alliance Companion
(15360, 10.0), -- Horde Companion
(15398, 1.08), -- Larianna Riverwind
(15399, 1.08), -- Lieutenant Dawnrunner
(15402, 2.05), -- Apprentice Mirveda
(15466, 33.0), -- Minion of Omen
(15467, 410.0), -- Omen
(15477, 5.25), -- Herbalist Proudfeather
(15495, 6.615), -- Nighthaven Defender

(15528, 5.25), -- Healer Longrunner
(15532, 5.25), -- Stoneguard Clayhoof
(15535, 5.25), -- Chief Sharpclaw
(15547, 10.0), -- Spectral Charger
(15549, 1.0), -- Elder Morndeep
(15550, 200.0), -- Attumen the Huntsman
(15551, 10.0), -- Spectral Stable Hand
(15556, 1.68), -- Elder Splitrock
(15558, 1.304), -- Elder Silvervein
(15559, 1.304), -- Elder Highpeak
(15560, 3.6), -- Elder Stonefort
(15561, 1.304), -- Elder Obsidian
(15562, 1.304), -- Elder Hammershout
(15563, 1.304), -- Elder Bellowrage
(15564, 1.304), -- Elder Darkcore
(15565, 1.304), -- Elder Stormbrow
(15566, 1.304), -- Elder Snowcrown
(15567, 1.304), -- Elder Ironband
(15568, 1.304), -- Elder Graveborn
(15569, 1.304), -- Elder Goldwell
(15570, 1.304), -- Elder Primestone
(15572, 1.3692), -- Elder Runetotem
(15573, 1.3692), -- Elder Ragetotem
(15574, 1.3692), -- Elder Stonespire
(15575, 1.3692), -- Elder Bloodhoof
(15576, 1.3692), -- Elder Winterhoof
(15577, 1.3692), -- Elder Skychaser
(15578, 1.764), -- Elder Wildmane
(15579, 1.3692), -- Elder Darkhorn
(15580, 1.3692), -- Elder Ezra Wheathoof
(15582, 1.3692), -- Elder Windtotem
(15583, 1.3692), -- Elder Thunderhorn
(15584, 1.3692), -- Elder Skyseer
(15585, 1.3692), -- Elder Dawnstrider
(15586, 1.3692), -- Elder Dreamseer
(15587, 1.3692), -- Elder Mistwalker
(15588, 1.3692), -- Elder High Mountain
(15592, 1.304), -- Elder Windrun
(15594, 1.304), -- Elder Moonstrike
(15595, 1.304), -- Elder Bladeleaf
(15597, 1.304), -- Elder Moonwarden
(15599, 1.304), -- Elder Bladesing
(15600, 1.304), -- Elder Skygleam
(15601, 1.304), -- Elder Starweave
(15602, 1.304), -- Elder Meadowrun
(15603, 1.304), -- Elder Nightwind
(15605, 1.304), -- Elder Riversong
(15607, 1.0), -- Elder Farwhisper
(15608, 1000.0), -- Medivh
(15668, 1.1), -- Grimscale Murloc
(15669, 1.1), -- Grimscale Oracle
(15670, 1.1), -- Grimscale Forager
(15702, 5.25), -- Senior Sergeant Taiga
(15721, 0.9375), -- Mechanical Greench
(15730, 1.40625), -- Pat's Snowcloud Guy
(15739, 1.05), -- Thunder Bluff Commendation Officer
(15740, 16700.0), -- Colossus of Zora
(15741, 16700.0), -- Colossus of Regal
(15742, 16700.0), -- Colossus of Ashi
(15743, 1622.400024), -- Colossal Anubisath Warbringer
(15758, 811.200012), -- Supreme Anubisath Warbringer
(15789, 1.05), -- Tauren Female Winter Reveler
(15792, 1.05), -- Troll Male Winter Reveler
(15793, 1.05), -- Tauren Male Winter Reveler
(15847, 1.05), -- Might of Kalimdor Shaman
(15849, 1.05), -- Might of Kalimdor Druid
(15855, 21.0), -- Tauren Rifleman
(15856, 26.25), -- Tauren Primalist
(15869, 157.5), -- Malagav the Tactician
(15895, 1.05), -- Lunar Festival Harbinger
(15898, 1.05), -- Lunar Festival Vendor
(15907, 0.93), -- Undercity Reveler
(15909, 1.304), -- Fariel Starsong
(15917, 1.05), -- Lunar Festival Reveler
(15924, 1.1), -- Apprentice Loralthalis
(15929, 109.849998), -- Stalagg
(15930, 109.849998), -- Feugen
(15950, 1.1), -- Grimscale Seer
(15974, 27.4625), -- Dread Creeper
(15975, 27.4625), -- Carrion Spinner
(15976, 54.924999), -- Venom Stalker
(15977, 13.7312), -- Poisonous Skitterer
(15978, 54.924999), -- Crypt Reaver
(15979, 54.924999), -- Tomb Horror
(15980, 13.7312), -- Naxxramas Cultist
(15981, 13.7312), -- Naxxramas Acolyte
(15991, 3.104), -- Lady Dena Kennedy
(16008, 1.05), -- Temma of the Wells
(16017, 54.924999), -- Patchwork Golem
(16018, 54.924999), -- Bile Retcher
(16019, 1.05), -- Boorana Thunderhoof
(16020, 27.4625), -- Mad Scientist
(16021, 54.924999), -- Living Monstrosity
(16022, 5.4925), -- Surgical Assistant
(16024, 13.7312), -- Embalming Slime
(16025, 109.849998), -- Stitched Giant
(16027, 1000.0), -- Living Poison
(16029, 54.924999), -- Sludge Belcher
(16034, 54.924999), -- Plague Beast
(16036, 13.7312), -- Frenzied Bat
(16037, 13.7312), -- Plagued Bat
(16042, 62.5), -- Lord Valthalak
(16049, 16.0), -- Lefty
(16050, 16.0), -- Rotfang
(16051, 16.0), -- Snokh Blackspine
(16052, 16.0), -- Malgen Longspear
(16053, 16.799999), -- Korv
(16054, 16.0), -- Rezznik
(16055, 16.0), -- Va'jashni
(16056, 1.37312), -- Diseased Maggot
(16057, 13.7312), -- Rotting Maggot
(16058, 16.0), -- Volida
(16059, 16.0), -- Theldren
(16062, 274.625), -- Highlord Mograine
(16063, 274.625), -- Sir Zeliek
(16064, 274.625), -- Thane Korth'azz
(16065, 274.625), -- Lady Blaumeux
(16066, 1.0), -- Spectral Assassin
(16067, 54.924999), -- Deathcharger Steed
(16068, 0.72), -- Larva
(16070, 1.032), -- Garel Redrock
(16077, 550.0), -- [PH] Alex's Test DPS Mob
(16079, 3.0375), -- Theldren Trigger
(16080, 35.700001), -- Mor Grayhoof
(16082, 1000.0), -- Naxxramas Trigger
(16097, 40.0), -- Isalien
(16098, 8.0), -- Empyrean
(16100, 3.375), -- Ysida's Trigger
(16101, 16.0), -- Jarien
(16102, 16.0), -- Sothos
(16118, 40.0), -- Kormok
(16119, 2.0), -- Bone Minion
(16124, 13.7312), -- Unrelenting Trainee
(16125, 21.969999), -- Unrelenting Death Knight
(16126, 43.939999), -- Unrelenting Rider
(16127, 13.7312), -- Spectral Trainee
(16137, 1000.0), -- Gothik Soul Anchor
(16138, 1000.0), -- Gothik Soul Receiver
(16140, 400.0), -- Necropolis Crystal
(16143, 18.0), -- Shadow of Doom
(16145, 54.924999), -- Death Knight Captain
(16146, 27.4625), -- Death Knight
(16148, 21.969999), -- Spectral Death Knight
(16149, 12.0835), -- Spectral Charger
(16150, 43.939999), -- Spectral Rider
(16151, 200.0), -- Midnight
(16153, 5.0), -- Berthold
(16154, 27.4625), -- Risen Squire
(16156, 27.4625), -- Dark Touched Warrior
(16159, 5.0), -- Calliard
(16163, 54.924999), -- Death Knight Cavalier
(16164, 27.4625), -- Wandering Shade
(16165, 27.4625), -- Necro Knight
(16167, 27.4625), -- Skeletal Archer
(16168, 54.924999), -- Stoneskin Gargoyle
(16169, 5.0), -- Hastings
(16170, 5.0), -- Coldmist Stalker
(16171, 10.0), -- Coldmist Widow
(16173, 4.5), -- Shadowbat
(16174, 9.0), -- Greater Shadowbat
(16175, 9.0), -- Vampiric Shadowbat
(16176, 11.0), -- Shadowbeast
(16177, 11.0), -- Dreadbeast
(16178, 5.5), -- Phase Hound
(16179, 100.0), -- Hyakiss the Lurker
(16180, 100.0), -- Shadikith the Glider
(16181, 100.0), -- Rokad the Ravager
(16189, 28.125), -- Skymaster Sunwing
(16191, 1.08), -- Sathren Azuredawn
(16193, 27.4625), -- Skeletal Blacksmith
(16194, 27.4625), -- Unholy Axe
(16211, 1000.0), -- Naxxramas Combat Dummy
(16215, 27.4625), -- Unholy Staff
(16216, 27.4625), -- Unholy Sword and Board
(16218, 1000.0), -- Feugen's Tesla Coil
(16236, 13.7312), -- Eye Stalk
(16243, 54.924999), -- Plague Slime
(16244, 27.4625), -- Infectious Ghoul
(16245, 5.0), -- Luzran
(16246, 5.0), -- Knucklerot
(16247, 1.625), -- Borgoth the Bloodletter
(16248, 1.08), -- Jurion the Deceiver
(16286, 1.37312), -- Energizing Spore
(16290, 13.7312), -- Fallout Slime
(16297, 27.4625), -- Mutated Grub
(16311, 0.9), -- Phantasmal Watcher
(16320, 0.9), -- Eye of Dar'Khan
(16323, 0.9), -- Phantasmal Seeker
(16339, 1.25), -- Arcane Reaver
(16355, 0.9), -- Lesser Scourgebat
(16360, 109.849998), -- Zombie Chow
(16362, 1.08), -- Runewarden Deryan
(16363, 4000.0), -- Disease Cloud
(16365, 13.7312), -- Master Craftsman Omarion
(16375, 27.4625), -- Sewage Slime
(16379, 2.25), -- Spirit of the Damned
(16381, 5.4925), -- Archmage Tarsis Kir-Moldir
(16382, 37.5), -- Patchwork Terror
(16385, 1.0), -- Lightning Totem
(16387, 200.0), -- Atiesh
(16388, 5.0), -- Koren
(16389, 10.0), -- Spectral Apprentice
(16390, 13.7312), -- Deathchill Servant
(16393, 1.17), -- Cold Wraith [FILMING]
(16394, 37.5), -- Pallid Horror
(16400, 1000.0), -- Toxic Tunnel
(16402, 0.9), -- Zombified Grimscale
(16404, 0.5), -- Yellowgill Frenzy
(16405, 0.5), -- Whitetail Frenzy
(16406, 5.0), -- Phantom Attendant
(16407, 10.0), -- Spectral Servant
(16408, 10.0), -- Phantom Valet
(16409, 5.0), -- Phantom Guest
(16410, 10.0), -- Spectral Retainer
(16411, 10.0), -- Spectral Chef
(16412, 10.0), -- Ghostly Baker
(16414, 10.0), -- Ghostly Steward
(16415, 10.0), -- Skeletal Waiter
(16419, 13.7312), -- Haunt
(16420, 1000.0), -- Dark Passage
(16424, 10.0), -- Spectral Sentry
(16425, 10.0), -- Phantom Guardsman
(16426, 5.0), -- Bennett
(16427, 13.7312), -- Soldier of the Frozen Wastes
(16428, 54.924999), -- Unstoppable Abomination
(16429, 27.4625), -- Soul Weaver
(16432, 3.75), -- Undercity Elite Guardian
(16433, 81.479401), -- Argent Dawn Crusader
(16434, 81.479401), -- Argent Dawn Champion
(16435, 81.479401), -- Argent Dawn Cleric
(16436, 81.479401), -- Argent Dawn Priest
(16441, 549.25), -- Guardian of Icecrown
(16446, 50.0), -- Plagued Gargoyle
(16447, 27.4625), -- Plagued Ghoul
(16448, 54.924999), -- Plagued Deathhound
(16449, 31.5), -- Spirit of Naxxramas
(16459, 10.0), -- Wanton Hostess
(16460, 10.0), -- Night Mistress
(16461, 9.0), -- Concubine
(16465, 1.62), -- Raw Meat Rack Trigger
(16466, 1.448), -- Smoked Meat Rack Trigger
(16468, 5.0), -- Spectral Patron
(16470, 10.0), -- Ghostly Philanthropist
(16471, 20.0), -- Skeletal Usher
(16472, 10.0), -- Phantom Stagehand
(16473, 10.0), -- Spectral Performer
(16474, 1000.0), -- Sapphiron
(16475, 1.1), -- Megelon
(16476, 1.1), -- Jaeleil
(16477, 1.1), -- Proenitus
(16481, 10.0), -- Ghastly Haunt
(16482, 10.0), -- Trapped Soul
(16485, 22.0), -- Arcane Watchman
(16486, 13.7312), -- Web Wrap
(16488, 10.0), -- Arcane Anomaly
(16489, 10.0), -- Chaotic Sentience
(16491, 5.0), -- Mana Feeder
(16492, 5.0), -- Syphoner
(16499, 1.32), -- Keilnei
(16500, 1.1), -- Valaatu
(16501, 1.1), -- Aurelon
(16502, 1.1), -- Zalduun
(16503, 1.1), -- Kore
(16504, 22.0), -- Arcane Protector
(16505, 43.939999), -- Naxxramas Follower
(16506, 21.969999), -- Naxxramas Worshipper
(16507, 2.67703), -- Shattered Hand Sentry
(16512, 1.25), -- Argent Deathsteed
(16513, 1.25), -- Argent Deathcharger
(16514, 1.1), -- Botanist Taerix
(16516, 0.9), -- Volatile Mutation
(16518, 1.1), -- Nestlewood Owlkin
(16521, 1.1), -- Blood Elf Scout
(16522, 1.32), -- Surveyor Candress
(16523, 2.67703), -- Shattered Hand Savage
(16525, 4.5), -- Spell Shade
(16526, 18.0), -- Sorcerous Shade
(16529, 10.0), -- Magical Horror
(16530, 5.0), -- Mana Warp
(16535, 1.1), -- Vindicator Aldar
(16537, 1.1), -- Mutated Owlkin
(16539, 4.5), -- Homunculus
(16540, 10.0), -- Shadow Pillager
(16541, 2.01), -- Ghostlands Guardian
(16544, 20.0), -- Ethereal Thief
(16545, 20.0), -- Ethereal Spellfilcher
(16546, 1.1), -- Tolaan
(16553, 1.08), -- Caregiver Chellan
(16554, 1.1), -- Aeun
(16562, 12.5967), -- Summoned Daemon UNUSED
(16573, 87.879997), -- Crypt Guard
(16574, 3.2592), -- Far Seer Regulkut
(16575, 3.104), -- Shadow Hunter Ty'jin
(16578, 1.12), -- Blood Elf Pilgrim
(16579, 2.096), -- Falcon Watch Sentinel
(16580, 3.104), -- Thrallmar Grunt
(16582, 3.104), -- Thrallmar Marksman
(16583, 3.104), -- Rohok
(16584, 3.096), -- Watch Commander Krunk
(16585, 3.096), -- Cookie One-Eye
(16586, 3.2508), -- Huntsman Torf Angerhoof
(16587, 29.5312), -- Barley
(16588, 3.104), -- Apothecary Antonivich
(16589, 3.104), -- Guard Captain Cragtar
(16590, 3.12), -- Injured Thrallmar Grunt
(16591, 1.09), -- Thrallmar Peon
(16593, 2.67703), -- Shattered Hand Brawler
(16594, 2.67703), -- Shadowmoon Acolyte
(16595, 10.0), -- Fleshbeast
(16596, 40.0), -- Greater Fleshbeast
(16597, 1.25), -- Riding Nether Drake
(16598, 1.09), -- Eye of Thrallmar
(16599, 3.104), -- Thrallmar Wolf Rider
(16600, 1.11), -- Thrallmar Riding Wolf
(16602, 3.104), -- Floyd Pinkus
(16611, 1.03), -- Zalle
(16615, 1.03), -- Novia
(16616, 1.03), -- Periel
(16617, 1.03), -- Daenice
(16619, 1.03), -- Celana
(16620, 1.03), -- Mathaleron
(16621, 1.03), -- Ileda
(16624, 1.03), -- Gelanthis
(16627, 1.03), -- Ithillan
(16628, 1.03), -- Caidori
(16629, 1.03), -- Tandron
(16632, 1.03), -- Oss
(16637, 1.03), -- Welethelon
(16638, 1.03), -- Deynna
(16639, 1.03), -- Galana
(16640, 1.03), -- Keelen Sheets
(16642, 1.03), -- Camberon
(16643, 1.03), -- Razia
(16644, 1.03), -- Botanist Nathera
(16656, 1.03), -- Shalenn
(16657, 1.03), -- Feera
(16666, 1.03), -- Feledis
(16672, 1.06), -- Tana
(16673, 1.09), -- Oninath
(16674, 1.104), -- Zandine
(16675, 1.03), -- Halthenis
(16678, 1.03), -- Rahein
(16681, 1.104), -- Champion Bachi
(16687, 1.03), -- Talmar
(16688, 1.03), -- Lynalis
(16689, 1.03), -- Zaralda
(16691, 1.03), -- Noraelath
(16692, 1.03), -- Tyn
(16697, 1000.0), -- Thane Kortha'zz
(16698, 1.37312), -- Corpse Scarab
(16699, 2.67703), -- Shattered Hand Reaver
(16700, 5.35406), -- Shattered Hand Legionnaire
(16703, 1.03), -- Amin
(16704, 2.67703), -- Shattered Hand Sharpshooter
(16705, 1.03), -- Altaa
(16706, 1.03), -- Musal
(16707, 1.03), -- Eoch
(16708, 1.03), -- Dekin
(16709, 1.03), -- Cuzi
(16710, 1.03), -- Kellag
(16712, 1.03), -- Ganaar
(16713, 2.08), -- Arras
(16714, 1.03), -- Ven
(16715, 1.04), -- Avelii
(16716, 1.03), -- Gornii
(16718, 1.03), -- Phea
(16719, 1.03), -- Mumman
(16721, 1.104), -- Shalannius
(16722, 1.03), -- Egomis
(16723, 1.03), -- Lucc
(16724, 1.03), -- Miall
(16725, 1.03), -- Nahogg
(16726, 1.03), -- Ockil
(16727, 1.03), -- Padaar
(16728, 1.03), -- Akham
(16729, 1.03), -- Refik
(16731, 1.03), -- Nus
(16732, 1.03), -- Onnis
(16733, 42.5), -- Exodar Peacekeeper
(16734, 2.11), -- Funaam
(16735, 1.03), -- Muhaa
(16736, 1.03), -- Cemmorhan
(16738, 1.09), -- Deremiis
(16739, 1.03), -- Caregiver Breel
(16740, 1.03), -- Edrem
(16741, 1.03), -- Deriz
(16742, 1.03), -- Kudrii
(16743, 1.03), -- Ghermas
(16745, 1.03), -- Feruul
(16746, 1.03), -- Kayaart
(16747, 1.03), -- Mahri
(16748, 1.03), -- Haferet
(16749, 1.104), -- Edirah
(16750, 1.03), -- Yil
(16751, 1.03), -- Merran
(16752, 1.03), -- Muaat
(16753, 1.03), -- Gotaan
(16755, 1.03), -- Lunaraa
(16756, 1.104), -- Caedmos
(16757, 1.03), -- Bildine
(16761, 1.104), -- Baatun
(16762, 1.03), -- Treall
(16763, 1.03), -- Remere
(16764, 1.03), -- Arthaid
(16765, 1.03), -- Ellomin
(16766, 1.03), -- Issca
(16767, 1.03), -- Neii
(16768, 1.03), -- Nurguni
(16771, 1.06), -- Ahonan
(16773, 1.03), -- Handiir
(16774, 1.03), -- Erett
(16775, 1000.0), -- Spirit of Highlord Mograine
(16776, 1000.0), -- Spirit of Lady Blaumeux
(16777, 1000.0), -- Spirit of Sir Zeliek
(16778, 1000.0), -- Spirit of Thane Korth'azz
(16788, 1.05), -- Festival Flamekeeper
(16795, 1.104), -- Draenei Prisoner
(16797, 1.104), -- Scout Vanura
(16798, 1.104), -- Provisioner Anir
(16803, 13.7312), -- Death Knight Understudy
(16806, 5.0), -- Ebonlocke
(16807, 39.099998), -- Grand Warlock Nethekurse
(16808, 46.0), -- Warchief Kargath Bladefist
(16809, 46.0), -- Warbringer O'mrogg
(16811, 150.0), -- Sebastian
(16812, 3.0), -- Barnes
(16813, 5.0), -- Wravien
(16814, 5.0), -- Gradav
(16815, 5.0), -- Kamsis
(16816, 500.0), -- Echo of Medivh
(16818, 1.12667), -- Festival Talespinner
(16820, 1.104), -- Lieutenant Amadi
(16821, 1.104), -- Magus Filinthus
(16822, 28.125), -- Flightmaster Krill Bitterhue
(16823, 1.104), -- Humphry
(16824, 1.096), -- Master Sergeant Lorin Thalmerok
(16826, 1.11), -- Sid Limbardi
(16827, 1.104), -- Honor Guard Wesilow
(16828, 1.104), -- Honor Guard Greyn
(16829, 1.104), -- Magus Zabraxis
(16831, 1.096), -- Nethergarde Infantry
(16835, 1.11), -- Explorers' League Archaeologist
(16836, 1.392), -- Escaped Dreghood
(16838, 1.096), -- Honor Hold Miner
(16842, 2.096), -- Honor Hold Defender
(16843, 2.104), -- Honor Hold Cavalryman
(16844, 1.096), -- Crust Burster
(16847, 1.096), -- Debilitated Mag'har Grunt
(16854, 3.0), -- Eldinarcus
(16855, 3.0), -- Tregla
(16857, 1.096), -- Marauding Crust Burster
(16858, 1.1), -- Grelag
(16863, 1.38), -- Deranged Helboar
(16864, 1.12), -- Stormwind Infantry
(16865, 1.12), -- Injured Stormwind Infantry
(16866, 1.096), -- Injured Nethergarde Infantry
(16871, 1.104), -- Bleeding Hollow Grunt
(16873, 1.104), -- Bleeding Hollow Dark Shaman
(16876, 1.096), -- Bonechewer Mutant
(16879, 1.37), -- Starving Helboar
(16880, 1.25), -- Hulking Helboar
(16884, 1.11), -- War Horse
(16887, 1.09), -- Eye of Honor Hold
(16888, 1.05), -- Mahuram Stouthoof
(16894, 1.05), -- Thunder Bluff Celebrant
(16896, 2.096), -- Honor Hold Archer
(16897, 1.09), -- Honor Hold Target Dummy Middle
(16899, 1.09), -- Honor Hold Target Dummy Left
(16904, 1.096), -- Unyielding Footman
(16905, 1.096), -- Unyielding Sorcerer
(16906, 1.096), -- Unyielding Knight
(16907, 1.096), -- Bleeding Hollow Peon
(16915, 1.104), -- Foreman Razelcraz
(16917, 1.1), -- Aurok
(16918, 1.1), -- Jel

(16919, 1.1), -- Mura
(16920, 1.1), -- Ryosh
(16922, 1.448), -- Red Radiation Trigger
(16925, 1.096), -- Bonechewer Raider
(16927, 1.104), -- Stonescythe Whelp
(16930, 1.25), -- Raging Clefthoof
(16931, 1.25), -- Enraged Clefthoof
(16932, 1.096), -- Razorfang Hatchling
(16937, 1.11), -- Dreghood Geomancer
(16938, 1.11), -- Dreghood Brute
(16942, 1.25), -- Infernal Crafter
(16943, 1.25), -- Cyber-Rage Forgelord
(16944, 1.25), -- Mo'arg Doomsmith
(16945, 3.75), -- Mo'arg Engineer
(16946, 1.25), -- Mo'arg Forgefiend
(16947, 1.104), -- Gan'arg Servant
(16950, 0.372), -- Netherhound
(16951, 1.25), -- Terrorfiend
(16952, 1.1), -- Anger Guard
(16953, 1.1), -- Forge Camp Patroller
(16954, 1.2144), -- Forge Camp Legionnaire
(16955, 0.75), -- Chained Trickster
(16956, 0.75), -- Dust Hopper
(16957, 0.75), -- Nether Imp
(16958, 1.1), -- Dread Interrogator
(16959, 5.5), -- Dread Tactician
(16960, 0.8568), -- Sister of Grief
(16961, 3.6), -- Maiden of Grief UNUSED
(16962, 0.9), -- Griefbringer
(16963, 5.2), -- Infernal Destroyer
(16970, 1.25), -- Bristlehide Clefthoof
(16971, 1.1), -- Injured Draenei
(16974, 1.104), -- Rogue Voidwalker
(16975, 1.104), -- Uncontrolled Voidwalker
(16976, 1.096), -- Ghostly Denizen
(16981, 27.4625), -- Plagued Guardian
(16982, 43.939999), -- Dr. Bones the Breaker
(16983, 54.924999), -- Plagued Champion
(16984, 27.4625), -- Plagued Warrior
(16987, 1.05), -- Festival Flamekeeper Costume: Tauren
(16991, 1.1592), -- Thiah Redmane
(16992, 2.5), -- Dreadtusk
(16998, 1.0985), -- Mr. Bigglesworth
(17000, 2.2), -- Aggonis
(17002, 1.12), -- Angela "The Claw" Kestrel
(17004, 0.999), -- Jir'see
(17006, 1.096), -- Elsaana
(17007, 62.5), -- Lady Keira Berrybuck
(17015, 1.096), -- Taleris Dawngazer
(17046, 1.096), -- Pilgrim Gal'ressa
(17053, 1.104), -- Kaliri Swooper
(17055, 13.7312), -- Maexxna's Spiderling
(17056, 1.155), -- Eversong Partygoer
(17059, 1.06), -- Hellfire Combat Dummy
(17060, 1.06), -- Hellfire Combat Dummy Small
(17062, 1.104), -- Fel Orc Corpse
(17065, 3.78), -- Concubine Transform Visual
(17067, 4.5), -- Phantom Hound
(17071, 1.1), -- Technician Zhanaa
(17083, 1.33852), -- Fel Orc Convert
(17086, 0.315), -- Enraged Wraith
(17089, 1.1), -- Firmanvaar
(17096, 5.0), -- Astral Flare
(17117, 1.1), -- Injured Night Elf Priestess
(17120, 1.104), -- Behomat
(17121, 1.06), -- Kavaan
(17122, 1.104), -- Vord
(17144, 27.5), -- Goretooth
(17152, 5.5), -- Felguard Legionnaire
(17161, 1000.0), -- Raging Blizzard
(17167, 10.0), -- Aran's Water Elemental
(17179, 1.375), -- Restless Spirit of Earth
(17180, 0.825), -- Spirit of Air
(17181, 0.825), -- Spirit of Water
(17182, 0.825), -- Spirit of Fire
(17183, 1.1), -- Bristlelimb Furbolg
(17184, 1.1), -- Bristlelimb Windcaller
(17193, 1.1), -- Wrathscale Naga
(17194, 1.1), -- Wrathscale Myrmidon
(17195, 1.1), -- Wrathscale Siren
(17196, 1.1), -- Root Trapper
(17197, 1.1), -- Root Thresher
(17200, 1.1), -- Moongraze Stag
(17201, 1.1), -- Moongraze Buck
(17208, 1000.0), -- Karazhan Chess - Chess Square, WHITE (DND)
(17211, 5.0), -- Human Footman
(17217, 1.1), -- Barbed Crawler
(17219, 1.34), -- Sulaa
(17228, 1.1), -- Draenei Artificer
(17229, 45.0), -- Kil'rek
(17231, 1000.0), -- Gas Vent
(17240, 1.104), -- Admiral Odesyus
(17248, 5.0), -- Demon Chains
(17256, 26.0), -- Hellfire Channeler
(17259, 2.67703), -- Bonechewer Hungerer
(17260, 1000.0), -- Nightbane Helper Target
(17261, 5.0), -- Smoldering Skeleton
(17263, 1.12), -- Recovering Pilgrim
(17264, 2.67703), -- Bonechewer Ravener
(17265, 1000.0), -- Fiendish Portal
(17267, 4.5), -- Fiendish Imp
(17269, 2.67703), -- Bleeding Hollow Darkcaster
(17270, 2.67703), -- Bleeding Hollow Archer
(17271, 2.67703), -- Bonechewer Destroyer
(17274, 1.448), -- Temper's Target
(17276, 1.04), -- Watery Aspect
(17278, 1.1), -- Venture Co. Saboteur
(17279, 1.1), -- Venture Co. Gemologist
(17281, 5.35406), -- Bonechewer Ripper
(17283, 5.0), -- Astral Spark
(17285, 2.585), -- Ragnarose
(17295, 2.1), -- Korag Proudmane
(17301, 4.73629), -- Shattered Hand Executioner
(17305, 1000.0), -- Karazhan Chess - Chess Square, BLACK (DND)
(17306, 26.450001), -- Watchkeeper Gargolmar
(17307, 9.47256), -- Vazruden the Herald
(17308, 36.799999), -- Omor the Unscarred
(17309, 6.5), -- Hellfire Watcher
(17316, 1000.0), -- Karazhan Chess - Chess Square, OUTSIDE BLACK (DND)
(17317, 1000.0), -- Karazhan Chess - Chess Square, OUSIDE WHITE (DND)
(17337, 1.1), -- Nazzivus Satyr
(17338, 1.1), -- Nazzivus Rogue
(17339, 1.1), -- Nazzivus Felsworn
(17340, 1.1), -- Axxarien Shadowstalker
(17341, 1.1), -- Axxarien Trickster
(17342, 1.1), -- Axxarien Hellcaller
(17356, 2.67703), -- Creeping Ooze
(17357, 1.33852), -- Creeping Oozeling
(17370, 2.67703), -- Laughing Skull Enforcer
(17371, 2.67703), -- Shadowmoon Warlock
(17372, 1.1), -- Timberstrider Fledgling
(17373, 1.1), -- Timberstrider
(17374, 1.1), -- Greater Timberstrider
(17375, 1.1), -- Stillpine Captive
(17377, 31.049999), -- Keli'dan the Breaker
(17378, 1.104), -- Swamp Gas
(17380, 27.6), -- Broggok
(17381, 27.6), -- The Maker
(17395, 2.67703), -- Shadowmoon Summoner
(17397, 2.67703), -- Shadowmoon Adept
(17398, 1.33852), -- Nascent Fel Orc
(17399, 1.125), -- Seductress
(17400, 5.88947), -- Felguard Annihilator
(17401, 1.125), -- Felhound Manastalker
(17402, 1.104), -- Yaluu
(17405, 1.104), -- Krun Spinebreaker
(17407, 1.104), -- Felmist
(17408, 1.104), -- Arcane Vortex
(17414, 2.67703), -- Shadowmoon Technician
(17416, 1.33852), -- Orc Captive
(17417, 0.25), -- Mag'har Escort
(17420, 2.67703), -- Shattered Hand Heathen
(17425, 1.32), -- Vale Hunter
(17427, 1.33852), -- Shattered Hand Archer
(17429, 1.33852), -- Fel Orc Neophyte
(17431, 1.11), -- Velaada
(17436, 1.07), -- Aspect of Air
(17454, 16.9), -- Burning Abyssal
(17455, 5.35406), -- Bonechewer Beastmaster
(17459, 1000.0), -- Karazhan Chess - Chess Waiting Room (DND)
(17460, 1000.0), -- Karazhan Chess - Chess Ready Room
(17462, 1.33852), -- Shattered Hand Zealot
(17464, 2.67703), -- Shattered Hand Gladiator
(17465, 5.35406), -- Shattered Hand Centurion
(17467, 0.24), -- Skunk
(17468, 2000.0), -- Prophet Velen
(17469, 5.0), -- Orc Grunt
(17478, 2.67703), -- Bleeding Hollow Scryer
(17482, 1.1), -- Guvan
(17491, 2.67703), -- Laughing Skull Rogue
(17494, 1.1), -- Zevrax
(17504, 1.09), -- Kazi
(17505, 1.048), -- Killac
(17509, 1.09), -- Jol
(17510, 1.06), -- Izmir
(17511, 1.09), -- Fallat
(17512, 1.09), -- Arred
(17513, 1.09), -- Harnan
(17514, 1.06), -- Bati
(17517, 2.67703), -- Hellfire Sentry
(17518, 5.0), -- Ythyar
(17519, 1.352), -- Hobahken
(17520, 1.31), -- Gurrag
(17521, 400.0), -- The Big Bad Wolf
(17524, 1.1), -- Nazzivus Summoner
(17528, 1.32), -- Tzerak
(17533, 100.0), -- Romulo
(17534, 125.0), -- Julianne
(17535, 166.660004), -- Dorothee
(17536, 23.0), -- Nazan
(17537, 23.0), -- Vazruden the Herald
(17540, 1.20467), -- Fiendish Hound
(17543, 44.439999), -- Strawman
(17546, 44.439999), -- Roar
(17547, 44.439999), -- Tinhead
(17548, 10.0), -- Tito
(17549, 2.03), -- Blood Watch Peacekeeper
(17551, 1.1), -- Tavara
(17554, 28.125), -- Laando
(17555, 28.125), -- Stephanos
(17568, 2.3125), -- Outland Doomguard (Default)
(17569, 2.3125), -- Outland Doomguard (Black)
(17570, 2.3125), -- Outland Doomguard (Blue)
(17571, 2.3125), -- Outland Doomguard (Green)
(17572, 2.3125), -- Outland Doomguard (Purple)
(17573, 2.3125), -- Outland Doomguard (Yellow)
(17575, 1.5), -- Eric Maloof Test Critter
(17577, 1.5), -- Outland Mountain Giant (Netherstorm)
(17588, 0.75), -- Veridian Whelp
(17589, 0.75), -- Veridian Broodling
(17591, 0.825), -- Blood Elf Bandit
(17592, 2.5), -- Razormaw
(17603, 5.0), -- Grandmother
(17621, 1.33852), -- Heathen Guard
(17622, 2.67703), -- Sharpshooter Guard
(17623, 1.33852), -- Reaver Guard
(17624, 5.35406), -- Laughing Skull Warden
(17626, 2.67703), -- Laughing Skull Legionnaire
(17627, 1.03), -- Jenath
(17628, 1.03), -- Vynna
(17629, 1.03), -- Feynna
(17636, 1.12), -- Kalynna Lathred
(17644, 1000.0), -- Infernal Target
(17645, 1000.0), -- Infernal Relay
(17646, 1250.0), -- Netherspite Infernal
(17648, 0.9), -- Felhunter Minion
(17650, 1000.0), -- Prince Malchezaar's Axes
(17652, 91.0), -- Image of Arcanagos
(17653, 3.25), -- Shadowmoon Channeler
(17660, 10.0), -- Skeletal Gryphon
(17664, 3.0), -- Matis the Cruel
(17670, 2.67703), -- Shattered Hand Houndmaster
(17671, 2.67703), -- Shattered Hand Champion
(17673, 0.5), -- Stinkhorn Striker
(17693, 1.33852), -- Shattered Hand Scout
(17694, 2.67703), -- Shadowmoon Darkcaster
(17695, 2.67703), -- Shattered Hand Assassin
(17711, 2154.600098), -- Doomwalker
(17718, 1.104), -- Magister Astalor Bloodsworn
(17721, 2.67703), -- Coilfang Engineer
(17722, 2.67703), -- Coilfang Sorceress
(17723, 8.03109), -- Bog Giant
(17724, 2.67703), -- Underbat
(17725, 2.67703), -- Underbog Lurker
(17726, 2.67703), -- Wrathfin Myrmidon
(17727, 2.67703), -- Wrathfin Sentry
(17728, 2.67703), -- Murkblood Tribesman
(17729, 2.67703), -- Murkblood Spearman
(17730, 2.67703), -- Murkblood Healer
(17732, 1.20467), -- Lykul Wasp
(17734, 8.03109), -- Underbog Lord
(17735, 2.67703), -- Wrathfin Warrior
(17746, 1.25), -- Outland Doomguard, Black
(17747, 1.25), -- Outland Doomguard, Blue
(17748, 1.25), -- Outland Doomguard, Orange
(17749, 1.25), -- Outland Doomguard, Green
(17750, 1.25), -- Outland Doomguard, Purple
(17751, 1.25), -- Outland Doomguard, Yellow
(17752, 1.25), -- Outland Mtn. Giant, Zangarmarsh
(17755, 1.3), -- Pit Lord
(17770, 29.9), -- Hungarfen
(17771, 2.67703), -- Murkblood Oracle
(17772, 67.599998), -- Lady Jaina Proudmoore
(17773, 1.03), -- Ossco
(17779, 0.9), -- Outland Imp, Gray
(17780, 0.9), -- Outland Imp, Orange
(17781, 0.9), -- Outland Imp, Purple
(17782, 0.9), -- Outland Imp, Yellow
(17796, 31.049999), -- Mekgineer Steamrigger
(17797, 2.3), -- Hydromancer Thespia
(17798, 46.0), -- Warlord Kalithresh
(17799, 1.33852), -- Dreghood Slave
(17800, 2.67703), -- Coilfang Myrmidon
(17801, 2.67703), -- Coilfang Siren
(17802, 2.67703), -- Coilfang Warrior
(17803, 2.67703), -- Coilfang Oracle
(17805, 2.67703), -- Coilfang Slavemaster
(17807, 1.03), -- Master Kelerun Bloodmourn
(17816, 1.33852), -- Bogstrok
(17817, 2.67703), -- Greater Bogstrok
(17818, 219.699997), -- Volatile Infernal
(17819, 3.0), -- Durnholde Sentry
(17820, 3.0), -- Durnholde Rifleman
(17826, 29.9), -- Swamplord Musel'ek
(17827, 5.35406), -- Claw
(17833, 3.9), -- Durnholde Warden
(17835, 1.144), -- Infinite Assassin
(17838, 1000.0), -- Time Rift
(17840, 2.1), -- Durnholde Tracking Hound
(17845, 1.09), -- Blood Elf Magister
(17846, 3.0), -- Pit Spectator
(17848, 46.0), -- Lieutenant Drake
(17852, 67.599998), -- Thrall
(17854, 8.45), -- Dire Wolf
(17855, 3.15), -- Expedition Warden
(17858, 1.1655), -- Warden Hamoot
(17860, 3.9), -- Durnholde Veteran
(17862, 46.0), -- Captain Skarloc
(17864, 18.59), -- Lesser Doomguard
(17871, 2.67703), -- Underbog Shambler
(17876, 19.5), -- Thrall
(17879, 46.0), -- Chrono Lord Deja
(17880, 46.0), -- Temporus
(17881, 57.5), -- Aeonus
(17882, 37.950001), -- The Black Stalker
(17887, 0.011), -- Void Critter
(17890, 1.05), -- Weeder Greenthumb
(17892, 1.144), -- Infinite Chronomancer
(17893, 2.67703), -- Naturalist Bite
(17894, 8.4), -- Windcaller Claw
(17895, 16.9), -- Ghoul
(17896, 1.1655), -- Kameel Longstride
(17897, 16.9), -- Crypt Fiend
(17898, 42.25), -- Abomination
(17899, 16.9), -- Necromancer
(17902, 8.45), -- Skeleton Warrior
(17903, 8.45), -- Skeleton Mage
(17905, 16.9), -- Banshee
(17906, 16.9), -- Gargoyle
(17907, 84.5), -- Frost Wyrm
(17908, 43.939999), -- Infernal
(17915, 2.5), -- [PH] Invis Paladin Quest Credit
(17916, 15.21), -- Fel Stalker
(17917, 3.34629), -- Coilfang Water Elemental
(17918, 5.85), -- Time Keeper
(17919, 16.9), -- Footman
(17920, 16.9), -- Knight
(17921, 16.9), -- Rifleman
(17922, 16.9), -- Sorceress
(17928, 16.9), -- Priest
(17931, 1.69), -- Peasant
(17932, 16.9), -- Grunt
(17933, 17.745001), -- Tauren Warrior
(17934, 16.9), -- Headhunter
(17935, 16.9), -- Witch Doctor
(17936, 16.9), -- Shaman
(17937, 1.69), -- Peon
(17938, 2.67703), -- Coilfang Observer
(17940, 2.67703), -- Coilfang Technician
(17941, 39.099998), -- Mennu the Betrayer
(17942, 46.0), -- Quagmirran
(17943, 16.9), -- Archer
(17944, 16.9), -- Dryad
(17945, 16.9), -- Huntress
(17946, 1.69), -- Ancient Wisp
(17947, 1.448), -- Red Crystal Bunny
(17948, 67.599998), -- Tyrande Whisperwind
(17949, 1098.5), -- Malfurion Stormrage
(17951, 1.33852), -- Steamrigger Mechanic
(17954, 1.33852), -- Naga Distiller
(17957, 2.67703), -- Coilfang Champion
(17958, 2.67703), -- Coilfang Defender
(17959, 2.67703), -- Coilfang Slavehandler
(17960, 2.67703), -- Coilfang Soothsayer
(17961, 2.67703), -- Coilfang Enchantress
(17962, 1.33852), -- Coilfang Collaborator
(17963, 1.33852), -- Wastewalker Slave
(17964, 1.33852), -- Wastewalker Worker
(17969, 1.3692), -- Kayra Longmane
(17975, 37.950001), -- High Botanist Freywinn
(17976, 32.200001), -- Commander Sarannis
(17977, 46.0), -- Warp Splinter
(17978, 35.650002), -- Thorngrin the Tender
(17980, 32.200001), -- Laj
(17984, 1.62), -- Power Source Invisible Bunny
(17985, 1.448), -- As the Crow Flies Credit Marker
(17991, 46.0), -- Rokmar the Crackler
(17993, 2.67703), -- Bloodwarder Protector
(17994, 2.67703), -- Bloodwarder Falconer
(17998, 1.448), -- Umbrafen Steam Pump Credit Marker
(17999, 1.448), -- Lagoon Steam Pump Credit Marker
(18000, 1.448), -- Serpent Steam Pump Credit Marker
(18001, 8.45), -- Water Elemental
(18002, 1.448), -- Marshlight Steam Pump Credit Marker
(18045, 6.0), -- Rajah Kaz'sith
(18047, 6.0), -- Rajah Vethag
(18048, 8.0), -- Bleeding Hollow Archer (1)
(18049, 8.0), -- Bleeding Hollow Darkcaster (1)
(18050, 8.0), -- Bleeding Hollow Scryer (1)
(18051, 16.0), -- Bonechewer Beastmaster (1)
(18052, 8.0), -- Bonechewer Destroyer (1)
(18053, 8.0), -- Bonechewer Hungerer (1)
(18054, 8.0), -- Bonechewer Ravener (1)
(18055, 16.0), -- Bonechewer Ripper (1)
(18056, 3.6), -- Fiendish Hound (1)
(18057, 8.0), -- Hellfire Sentry (1)
(18058, 16.0), -- Hellfire Watcher (1)
(18059, 4.0), -- Shattered Hand Warhound (1)
(18061, 1.1), -- Felguard Netherstorm
(18070, 1.1655), -- Windcaller Blackhoof
(18077, 1.104), -- Umbrafen Oracle
(18079, 1.104), -- Umbrafen Seer
(18095, 1000.0), -- Doomfire
(18096, 57.5), -- Epoch Hunter
(18099, 750.0), -- Gordawg
(18104, 1000.0), -- Archimonde
(18105, 28.75), -- Ghaz'an
(18124, 1.5), -- Withered Giant
(18125, 1.5), -- Starving Fungal Giant
(18126, 1.365), -- Expedition Scout
(18127, 1.5), -- Bog Lord
(18130, 1.104), -- Marshfang Ripper
(18132, 0.9936), -- Umbraglow Stinger
(18133, 0.9), -- Marshlight Bleeder
(18134, 1.25), -- Fen Strider
(18135, 1.25), -- Marsh Walker
(18138, 1.104), -- Umbrafen Eel
(18146, 1.104), -- Champion Vranesh
(18147, 1.16), -- Silvermoon Ranger
(18148, 1.25), -- Outland Wrathguard PH Test Size/Model/NoAnim
(18149, 0.9), -- Outland Shivan
(18155, 1.33852), -- Bloodfalcon
(18168, 166.660004), -- The Crone
(18170, 4.29), -- Infinite Slayer
(18171, 4.29), -- Infinite Defiler
(18182, 5.0), -- Gurok the Usurper
(18184, 1.25), -- Mo'arg Engineer Transform (Magnetic Mode)
(18194, 1.365), -- Expedition Preserver
(18200, 2.1), -- Shado 'Fitz' Farstrider
(18206, 1.33852), -- Wastewalker Captive
(18212, 0.125), -- Mudfin Frenzy
(18213, 1.2), -- Mire Hydra
(18240, 1.1), -- Sunspring Villager
(18243, 1.104), -- Lorti
(18244, 1.104), -- Khalan
(18245, 1.104), -- Merajit
(18246, 1.104), -- Tayemba
(18247, 1.104), -- Farbosi
(18249, 1.104), -- Mokasa
(18254, 1000.0), -- Shadow of Aran
(18263, 1.448), -- Nagrand Spawn Trigger
(18264, 1.448), -- Nagrand Spawn Timer
(18281, 3.75), -- Boglash
(18283, 0.9), -- Blacksting
(18292, 1.07), -- Bleeding Hollow Refugee
(18293, 1.04), -- Sunspring Post Refugee
(18295, 1.104), -- Prospector Conall
(18305, 1.02), -- Burning Blade Pyre (01)
(18309, 2.67703), -- Ethereal Scavenger
(18311, 2.67703), -- Ethereal Crypt Raider
(18312, 2.67703), -- Ethereal Spellbinder
(18313, 2.67703), -- Ethereal Sorcerer
(18314, 2.67703), -- Nexus Stalker
(18315, 2.67703), -- Ethereal Theurgist
(18317, 2.67703), -- Ethereal Priest
(18318, 2.67703), -- Sethekk Initiate
(18319, 2.67703), -- Time-Lost Scryer
(18320, 2.67703), -- Time-Lost Shadowmage
(18321, 2.67703), -- Sethekk Talon Lord
(18322, 2.67703), -- Sethekk Ravenguard
(18323, 2.67703), -- Sethekk Guard
(18325, 2.67703), -- Sethekk Prophet
(18326, 2.67703), -- Sethekk Shaman
(18327, 2.67703), -- Time-Lost Controller
(18328, 2.67703), -- Sethekk Oracle
(18331, 2.67703), -- Ethereal Darkcaster
(18332, 2.5), -- Talut
(18341, 35.650002), -- Pandemonius
(18343, 32.200001), -- Tavarok
(18344, 39.099998), -- Nexus-Prince Shaffar
(18348, 1.03), -- Fanin
(18349, 1.03), -- Iressa
(18350, 1.03), -- Jaela
(18357, 1.104), -- Ebon Gryphon
(18358, 1.104), -- Sporeggar Spawn
(18359, 1.104), -- Snowy Gryphon
(18363, 1.104), -- Tawny Wind Rider
(18364, 1.104), -- Blue Wind Rider
(18365, 1.104), -- Green Wind Rider
(18371, 37.950001), -- Shirrak the Dead Watcher
(18372, 0.125), -- Rough Stone Statue
(18373, 37.950001), -- Exarch Maladaar
(18385, 1.104), -- Rakoria
(18394, 1.33852), -- Ethereal Wraith
(18404, 2.67703), -- Bloodwarder Steward
(18405, 5.88947), -- Tempest-Forge Peacekeeper
(18418, 625.0), -- Nethrandamus
(18419, 2.67703), -- Bloodwarder Greenkeeper
(18420, 2.67703), -- Sunseeker Geomancer
(18421, 2.67703), -- Sunseeker Researcher
(18422, 2.67703), -- Sunseeker Botanist
(18428, 1.104), -- Mag'har Prisoner
(18429, 1.33852), -- Arcane Fiend
(18430, 2.67703), -- Ethereal Apprentice
(18431, 1.33852), -- Ethereal Beacon
(18432, 40.0), -- Nazan (1)
(18433, 100.0), -- Omor the Unscarred (1)
(18434, 40.0), -- Vazruden (1)
(18435, 80.0), -- Vazruden the Herald (1)
(18436, 80.0), -- Watchkeeper Gargolmar (1)
(18441, 1.07081), -- Stolen Soul
(18446, 1.05), -- Earthbinder Tavgren
(18472, 39.099998), -- Darkweaver Syth
(18473, 39.099998), -- Talon King Ikiss
(18480, 1.104), -- Broken Corpse
(18483, 1.25), -- Empoor's Bodyguard
(18485, 50.700001), -- Ancient of War
(18486, 50.700001), -- Ancient of Lore
(18487, 50.700001), -- Ancient Protector
(18492, 1.38), -- Tavgren's Kodo

(18493, 2.67703), -- Auchenai Soulpriest
(18495, 2.67703), -- Auchenai Vindicator
(18497, 2.67703), -- Auchenai Monk
(18498, 1.33852), -- Phasing Soldier
(18499, 1.33852), -- Phasing Sorcerer
(18500, 1.33852), -- Phasing Cleric
(18501, 1.33852), -- Phasing Stalker
(18502, 1.69), -- Wisp
(18503, 1.33852), -- Phantasmal Possessor
(18504, 1.09), -- Silvermoon Practice Dummy
(18506, 1.33852), -- Raging Soul
(18507, 1.16), -- Silvermoon Farstrider
(18521, 2.67703), -- Raging Skeleton
(18524, 2.67703), -- Angered Skeleton
(18534, 1.25), -- Soldier of Hate
(18535, 13.0), -- Demos, Overseer of Hate
(18536, 13.0), -- Xirkos, Overseer of Fear
(18543, 625.0), -- Nethrandamus Taxi
(18544, 3.9), -- Veraku
(18556, 2.67703), -- Unliving Soldier
(18557, 2.67703), -- Unliving Cleric
(18558, 2.67703), -- Unliving Sorcerer
(18559, 2.67703), -- Unliving Stalker
(18567, 5.0), -- Mo'arg Master Planner
(18568, 1.25), -- Scryer Arcane Guardian
(18584, 6.25), -- Sal'salabim
(18587, 1.33852), -- Frayer
(18598, 182.0), -- Orc Prisoner
(18601, 112.0), -- Broggok (1)
(18603, 4.0), -- Fel Orc Neophyte (1)
(18604, 17.6), -- Felguard Annihilator (1)
(18605, 3.6), -- Felhound Manastalker (1)
(18606, 3.6), -- Hellfire Imp (1)
(18607, 112.0), -- Keli'dan the Breaker (1)
(18608, 8.0), -- Laughing Skull Enforcer (1)
(18609, 8.0), -- Laughing Skull Legionnaire (1)
(18610, 8.0), -- Laughing Skull Rogue (1)
(18611, 16.0), -- Laughing Skull Warden (1)
(18612, 4.0), -- Nascent Fel Orc (1)
(18614, 3.6), -- Seductress (1)
(18615, 8.0), -- Shadowmoon Adept (1)
(18617, 8.0), -- Shadowmoon Summoner (1)
(18618, 8.0), -- Shadowmoon Technician (1)
(18619, 8.0), -- Shadowmoon Warlock (1)
(18620, 8.0), -- Shadowmoon Channeler (1)
(18621, 80.0), -- The Maker (1)
(18628, 1.104), -- Trainee Sinthar
(18631, 2.67703), -- Cabal Cultist
(18632, 2.67703), -- Cabal Executioner
(18633, 2.67703), -- Cabal Acolyte
(18634, 2.67703), -- Cabal Summoner
(18635, 2.67703), -- Cabal Deathsworn
(18636, 2.67703), -- Cabal Assassin
(18637, 2.67703), -- Cabal Shadow Priest
(18638, 2.67703), -- Cabal Zealot
(18639, 2.67703), -- Cabal Spellbinder
(18640, 2.67703), -- Cabal Warlock
(18641, 1.20467), -- Cabal Familiar
(18642, 1.20467), -- Fel Guardhound
(18659, 1.3), -- Voidwraith
(18660, 0.9), -- Subjugator Vaz'shir
(18661, 1.25), -- Terrorguard
(18663, 1.20467), -- Maiden of Discipline
(18667, 46.0), -- Blackheart the Inciter
(18673, 3.0), -- Pit Announcer
(18676, 0.75), -- Keb'ezil
(18677, 18.75), -- Mekthorg the Wild
(18678, 25.0), -- Fulgorge
(18679, 26.5625), -- Vorakem Doomspeaker
(18680, 34.375), -- Marticar
(18681, 27.5), -- Coilfang Emissary
(18682, 25.0), -- Bog Lurker
(18683, 25.0), -- Voidhunter Yar
(18684, 25.0), -- Bro'Gaz the Clanless
(18685, 31.25), -- Okrek
(18686, 31.25), -- Doomsayer Jurim
(18689, 25.0), -- Crippler
(18690, 46.875), -- Morcrush
(18693, 25.0), -- Speaker Mar'grom
(18694, 33.75), -- Collidus the Warp-Watcher
(18695, 41.25), -- Ambassador Jerrikar
(18696, 54.6875), -- Kraator
(18697, 31.25), -- Chief Engineer Lorthander
(18698, 46.875), -- Ever-Core the Punisher
(18700, 1.33852), -- Reanimated Bones
(18702, 5.35406), -- Auchenai Necromancer
(18703, 26.7703), -- Sethekk Spirit
(18708, 126.5), -- Murmur
(18717, 1.104), -- Shadowy Laborer
(18725, 1.25), -- Brazen
(18728, 2154.600098), -- Doom Lord Kazzak
(18730, 0.9936), -- Sirigna'no
(18731, 46.0), -- Ambassador Hellmaw
(18732, 39.099998), -- Grandmaster Vorpil
(18733, 19.5), -- Fel Reaver
(18734, 0.125), -- Coarse Stone Statue
(18735, 0.125), -- Heavy Stone Statue
(18736, 0.125), -- Solid Stone Statue
(18737, 0.125), -- Dense Stone Statue
(18738, 0.125), -- Primal Stone Statue
(18742, 7.0), -- Worgen
(18748, 1.155), -- Ruak Stronghorn
(18749, 1.104), -- Dalinna
(18751, 1.104), -- Kalaen
(18752, 1.4), -- Zebig
(18753, 1.104), -- Felannia
(18754, 1.176), -- Barim Spilthoof
(18755, 1.26), -- Moorutu
(18757, 1.448), -- Zangarmarsh PvP Beam (Red)
(18758, 2.096), -- Telhamat Protector
(18759, 1.448), -- Zangarmarsh PvP Beam (Blue)
(18761, 1.03), -- Darise
(18764, 1.3), -- Durnholde Armorer
(18770, 1.25), -- Soldier of Terror
(18771, 1.12), -- Brumman
(18772, 1.104), -- Hama
(18773, 1.104), -- Johan Barnes
(18774, 1.104), -- Tatiana
(18775, 1.4), -- Lebowski
(18776, 1.2), -- Rorelien
(18777, 1.2), -- Jelena Nightsky
(18779, 1.2), -- Hurnak Grimmord
(18785, 28.125), -- Kuma
(18788, 28.125), -- Munci
(18789, 28.125), -- Furgu
(18791, 28.125), -- Du'ga
(18794, 2.67703), -- Cabal Ritualist
(18796, 5.88947), -- Fel Overseer
(18797, 1.33852), -- Tortured Skeleton
(18802, 3.104), -- Alchemist Gribble
(18804, 1.28), -- Prospector Nachlan
(18807, 28.125), -- Kerna
(18808, 28.125), -- Gursha
(18809, 28.125), -- Furnan Skysoar
(18812, 1.03), -- Ereuso
(18813, 1.03), -- Duumehi
(18815, 1.03), -- Exodar Proselyte
(18827, 1.096), -- Gan'arg Sapper
(18829, 13.0), -- Hellfire Warder
(18830, 2.67703), -- Cabal Fanatic
(18832, 81.25), -- Krosh Firehand
(18834, 81.25), -- Olm the Summoner
(18835, 81.25), -- Kiggler the Crazed
(18836, 81.25), -- Blindeye the Seer
(18838, 9.9), -- Nightlord Malphas
(18840, 1.104), -- Sunspring Post Credit Marker
(18841, 1.104), -- Laughing Skull Clan Ruins Credit Marker
(18842, 1.104), -- Garadar Credit Marker
(18843, 1.104), -- Bleeding Hollow Clan Ruins Credit Marker
(18847, 11.7), -- Wild Fel Stalker
(18848, 4.81866), -- Malicious Instructor
(18856, 5.0), -- Arcane Annihilator
(18858, 1.25), -- Wrathbringer
(18859, 0.9), -- Wrath Priestess
(18861, 1.3), -- Eredar Tactician
(18862, 1.1), -- Dread Overlord
(18876, 0.5), -- Phase Hatchling
(18877, 1.25), -- Nether Drake
(18885, 6.0), -- Farahlon Giant
(18886, 6.0), -- Farahlon Breaker
(18892, 1.03), -- Broken Miner
(18894, 2.94473), -- Felguard Brute
(18911, 1.304), -- Juno Dufrain
(18917, 1.104), -- Chakaa
(18930, 28.125), -- Vlagga Freyfeather
(18931, 28.125), -- Amish Wildhammer
(18934, 3.0), -- Durnholde Mage
(18937, 28.125), -- Amerun Leafshade
(18938, 46.75), -- Krexcil
(18939, 28.125), -- Brubeck Stormfoot
(18940, 46.75), -- Nutral
(18942, 28.125), -- Innalia
(18944, 5.5), -- Fel Soldier
(18945, 52.0), -- Pit Commander
(18946, 9.1), -- Infernal Siegebreaker
(18952, 1.096), -- Bonechewer Scavenger
(18953, 29.5312), -- Unoke Tenderhoof
(18958, 0.9), -- Giselda Transform
(18959, 1.104), -- Dod'ss
(18960, 1.352), -- Rungor
(18962, 1.352), -- Bar Talet
(18969, 21.0), -- Melgromm Highmountain
(18974, 1.25), -- Z'kral
(18976, 1.25), -- Urga'zz
(18977, 2.3144), -- Felguard Destroyer
(18978, 0.3744), -- Heckling Fel Sprite
(18981, 0.9864), -- Doomwhisperer
(18984, 1.352), -- Trag
(18985, 1.104), -- Seer Skaltesh
(18987, 1.12), -- Gaston
(18988, 1.12), -- Baxter
(18990, 1.12), -- Burko
(18991, 1.12), -- Aresella
(18992, 3.75), -- Captain Krosh
(18993, 1.176), -- Naka
(18994, 1.43), -- Infinite Executioner
(18995, 1.43), -- Infinite Vanquisher
(19003, 2.104), -- Allerian Horseman
(19005, 25.0), -- Wrath Master
(19011, 1.104), -- Osrok the Immovable
(19012, 1.104), -- Sparik
(19013, 1.104), -- Vanteg
(19014, 1.104), -- Ogir
(19015, 1.104), -- Mathar G'ochar
(19016, 1.20467), -- Hellfire Familiar
(19017, 1.104), -- Borto
(19018, 1.104), -- Wilda Bearmane
(19019, 1.104), -- Luftasia
(19020, 1.104), -- Matron Qualia
(19021, 1.104), -- Nancila
(19026, 1.2), -- Stabled Raptor
(19027, 1.2), -- Stabled Kurenai Lion
(19030, 1.2), -- Stabled Kurenai Panther
(19033, 1.152), -- Nicole Bartlett
(19038, 2.104), -- Supply Officer Mills
(19042, 2.104), -- Leeli Longhaggle
(19045, 1.104), -- Oloraak
(19047, 1.104), -- Lissaf
(19048, 1.09), -- Stonebreaker Peon
(19049, 1.104), -- Karokka
(19051, 1.104), -- Araac
(19053, 2.104), -- Fabian Lanzonelli
(19056, 2.104), -- Cecil Meyers
(19064, 1.09), -- Leatei
(19066, 3.75), -- Crystalhide Colossus
(19073, 1.104), -- Nibblet
(19074, 1.104), -- Skreah
(19075, 1.104), -- Skettis Outcast
(19076, 1.304), -- High Elf Refugee
(19077, 1.304), -- Dwarf Refugee
(19088, 1.05), -- [PH] Gossip NPC Tauren Female, Christmas
(19089, 1.05), -- [PH] Gossip NPC Tauren Male, Christmas
(19097, 1.05), -- [PH] Gossip NPC Tauren Female, Lunar Festival
(19104, 1.05), -- [PH] Gossip NPC Tauren Male, Lunar Festival
(19111, 1.05), -- [PH] Gossip NPC, Tauren Female
(19118, 1.05), -- [PH] Gossip NPC, Tauren Male
(19120, 1.304), -- Broken Refugee
(19133, 2.1), -- Ohlorn Farstrider
(19136, 0.372), -- Flamewaker Imp
(19139, 1.06), -- Nagrand Target Dummy
(19144, 1.304), -- Mag'har Refugee
(19147, 2.11), -- Allerian Peasant
(19150, 1.304), -- Orc Refugee
(19154, 1.104), -- Soot
(19155, 1.304), -- Sporeling Refugee
(19159, 2.11), -- Allerian Peasant Cosmetic
(19160, 1.25), -- Wrathguard Defender
(19162, 1.304), -- Lost One Refugee
(19166, 5.88947), -- Tempest-Forge Patroller
(19167, 2.67703), -- Bloodwarder Slayer
(19168, 2.67703), -- Sunseeker Astromage
(19170, 1.304), -- Peasant Refugee
(19180, 1.152), -- Seymour
(19181, 9.375), -- Lemla Hopewing
(19182, 1.104), -- Shaarubo
(19186, 1.104), -- Kylene
(19188, 5.0), -- Raging Colossus
(19189, 1.104), -- Quillfang Skitterer
(19190, 0.9856), -- Fel Handler
(19191, 32.5), -- Arazzius the Cruel
(19192, 0.9), -- Mistress of Doom
(19195, 1.248), -- Jim Saltit
(19197, 1.104), -- Eral
(19199, 5.5), -- Dread Overseer
(19200, 1.8125), -- Shape of the Beast
(19203, 1.33852), -- Syth Fire Elemental
(19204, 1.33852), -- Syth Frost Elemental
(19205, 1.33852), -- Syth Arcane Elemental
(19206, 1.33852), -- Syth Shadow Elemental
(19208, 1.33852), -- Summoned Cabal Acolyte
(19209, 1.33852), -- Summoned Cabal Deathsworn
(19213, 2.1), -- Eiin
(19214, 65.0), -- Hand of the Highlord
(19218, 23.0), -- Gatewatcher Gyro-Kill
(19219, 32.200001), -- Mechano-Lord Capacitus
(19220, 39.099998), -- Pathaleon the Calculator
(19221, 37.950001), -- Nethermancer Sepethrea
(19226, 1.33852), -- Void Traveler
(19227, 1.104), -- Griftah
(19231, 3.34628), -- Mechanar Crusher
(19232, 1.104), -- Innkeeper Haelthol
(19234, 1.104), -- Yurial Soulwater
(19235, 1.104), -- Amshesha Stilldark
(19236, 1.104), -- Quelama Lightblade
(19238, 1.104), -- Urumir Stavebright
(19243, 1.104), -- Nalama the Merchant
(19244, 1.104), -- Trader Endernor
(19245, 1.104), -- Vinemaster Alamaro
(19246, 1.104), -- Berudan Keysworn
(19248, 1.104), -- Enchanter Salias
(19249, 1.104), -- Enchantress Metura
(19259, 1.3), -- Infernal Invader
(19260, 19.5), -- Destroyed Fel Reaver
(19262, 1.1), -- Dreadcaller Ebuch'nizor
(19263, 6.0), -- Warboss Nekrogg
(19264, 12.5), -- Force-Commander Gorax
(19270, 1.304), -- Shattrath Saul
(19271, 1.304), -- Albert Quarksprocket
(19276, 1.104), -- Legion Antenna: Spite
(19277, 1.104), -- Legion Antenna: Rage
(19278, 1.104), -- Legion Antenna: Hate
(19279, 1.104), -- Legion Antenna: Fear
(19282, 0.9), -- Subjugator Shi'aziv
(19283, 1.304), -- Vagrant
(19285, 1.3), -- Invading Infernal
(19286, 1.215), -- Invading Fel Stalker
(19287, 1.485), -- Invading Voidwalker
(19288, 22.0), -- Dreadknight
(19289, 1.304), -- Vagabond
(19290, 0.9), -- Invading Anguisher
(19291, 1.104), -- Legion Transporter: Alpha
(19292, 1.104), -- Legion Transporter: Beta
(19296, 2.104), -- Innkeeper Biribi
(19298, 1.5), -- Warbringer Arix'Amal
(19299, 4.5), -- Deathwhisperer
(19305, 6.0), -- Goliathon
(19306, 1.33852), -- Mana Leech
(19307, 6.96028), -- Nexus Terror
(19311, 2.0), -- Portal Hound
(19312, 4.66667), -- Drillmaster Zurok
(19317, 28.125), -- Drek'Gol
(19326, 1.104), -- Legion Antenna: Oblivion
(19328, 1.104), -- Legion Antenna: Gehenna
(19329, 1.104), -- Legion Antenna: Mageddon
(19332, 1.05), -- Stone Guard Ambelan
(19334, 1.1), -- Dreadcaller Xaldonus
(19335, 3.375), -- Subjugator Yalqiz
(19336, 1.104), -- Void Spawner XL
(19338, 1.104), -- L'lura Goldspun
(19354, 8.75), -- Arzeth the Merciless
(19355, 1.104), -- Shadowmoon Peon
(19357, 1.3), -- Dimming Voidwraith
(19358, 1.104), -- Legion Transporter: Alpha (Alliance)
(19359, 1.104), -- Legion Transporter: Beta (Alliance)
(19363, 1.104), -- Sergeant Dalton
(19379, 3.125), -- Sky'ree
(19387, 1.09), -- Wildhammer Stronghold Target Dummy Left
(19388, 1.09), -- Wildhammer Stronghold Target Dummy Right
(19389, 52.0), -- Lair Brute
(19391, 5.5), -- Felguard Lieutenant
(19392, 2.104), -- Watch Commander Leonus
(19394, 1.104), -- Barimoke Wildbeard
(19395, 1.104), -- Bron Goldhammer
(19397, 6.25), -- Mo'arg Overseer
(19400, 260.0), -- Fel Reaver Sentry
(19402, 1.5), -- Withered Bog Lord
(19406, 1.05), -- Thunder Bluff Huntsman
(19408, 0.9), -- Maiden of Pain
(19418, 1.5), -- Crystalhide Shardling
(19419, 0.75), -- Raging Shardling
(19420, 0.75), -- Goliathon Shardling
(19422, 1.104), -- Bleeding Hollow Necrolyte
(19424, 1.104), -- Bleeding Hollow Tormentor
(19425, 1.09), -- Orgrimmar Peon
(19426, 1.11), -- Peon Overseer
(19428, 5.35406), -- Cobalt Serpent
(19429, 2.67703), -- Avian Darkhawk
(19432, 3.12), -- Injured Grunt
(19434, 1.2056), -- Dreadcaller
(19440, 0.19), -- Eye of Grillok
(19442, 0.848), -- Worg Master Kruush
(19444, 2.11), -- Peasant Worker
(19445, 2.11), -- Wounded Soldier
(19446, 2.11), -- Operations Officer
(19447, 1.31), -- Brother Daniels
(19450, 1.4196), -- Pol Snowhoof
(19451, 1.104), -- Quartermaster Gorman
(19458, 0.592), -- Ripp
(19470, 1.352), -- Gholah
(19471, 1.352), -- Old Orok
(19472, 1.352), -- Threlc
(19473, 1.352), -- Raiza
(19474, 1.352), -- Karnaze
(19476, 1.352), -- Lor
(19478, 1.4196), -- Fera Palerunner
(19479, 1.352), -- Orgatha
(19486, 2.67703), -- Sunseeker Chemist
(19493, 0.9), -- Ekkorash the Inquisitor
(19494, 1.5), -- Ar'kelos
(19503, 3.75), -- Cabal Agent
(19505, 2.67703), -- Sunseeker Channeler
(19507, 2.67703), -- Sunseeker Gene-Splicer
(19508, 2.67703), -- Sunseeker Herbalist
(19509, 2.67703), -- Sunseeker Harvester
(19510, 2.67703), -- Bloodwarder Centurion
(19511, 2.94473), -- Nethervine Inciter
(19512, 2.94473), -- Nethervine Reaper
(19513, 1.33852), -- Mutate Fear-Shrieker
(19519, 1.5), -- Starving Bog Lord
(19523, 500.0), -- O'mrogg's Left Head
(19524, 500.0), -- O'mrogg's Right Head
(19531, 1.352), -- Eyonix
(19533, 1.352), -- Dealer Aljaan
(19534, 1.352), -- Dealer Digriz
(19535, 1.352), -- Dealer Zijaad
(19536, 1.352), -- Dealer Jadyan
(19537, 1.352), -- Dealer Malij
(19538, 1.352), -- Dealer Senzik
(19539, 1.352), -- Jazdalaad
(19540, 1.352), -- Asarnan
(19551, 6.5), -- Ember of Al'ar
(19552, 0.5), -- Goblin Zeppelin
(19557, 1.33852), -- Greater Frayer
(19558, 29.5312), -- Amilya Airheart
(19559, 1.104), -- Mondul
(19560, 1.104), -- Lukra
(19561, 1.104), -- Hagash the Blind
(19562, 1.1), -- Peon Bolgar
(19568, 1.3), -- Unending Voidwraith
(19573, 1.12), -- Dash
(19581, 46.75), -- Maddix
(19583, 46.75), -- Grennik
(19598, 1.33852), -- Mutate Fleshlasher
(19599, 0.33), -- Void Servant
(19601, 1050.0), -- Tauren Warrior
(19603, 1050.0), -- Tauren Shaman
(19609, 1.25), -- Mo'arg Engineer Transform (Drill)
(19610, 1.104), -- Irradiated Worker
(19618, 1.448), -- Warpmaster Lyssendra Credit
(19619, 1.448), -- Commander Dawnforge Credit
(19620, 1.448), -- Arcanist Ardonis Credit
(19624, 1.12), -- Wounded Stormwind Infantry
(19626, 1.304), -- Belanna
(19628, 1.304), -- Furan
(19629, 1.304), -- Denath
(19631, 1.304), -- Harram
(19632, 2.40932), -- Lykul Stinger
(19633, 2.67703), -- Bloodwarder Mender
(19648, 1.304), -- Maranem
(19649, 1.304), -- Dorni
(19652, 1.448), -- Disrupt the Communications Quest Credit Marker North
(19653, 1.25), -- Glacius
(19654, 1.448), -- Area 52 Analyzer Bunny
(19655, 1.448), -- Area 52 Ethereal Technology Bunny
(19658, 1.06), -- Brown Elekk
(19662, 2.104), -- Aaron Hollman
(19663, 1.352), -- Madame Ruby
(19665, 0.22), -- Ewe
(19666, 26.7703), -- Shadow Lord Xiraxis
(19680, 1.448), -- Aldor Spawn Controller
(19681, 1.104), -- Void Spawner L
(19682, 1.096), -- Emissary Mordiba
(19683, 1.104), -- Ogath the Mad
(19688, 1.25), -- Scryer Vault Guardian
(19689, 1.104), -- Draenei Pilgrim
(19692, 0.75), -- Boom Bot
(19701, 1.096), -- Bonechewer Evoker
(19710, 23.0), -- Gatewatcher Iron-Hand
(19711, 3.75), -- Mechanar Ripper (UNUSED)
(19712, 3.34628), -- Mechanar Driller
(19713, 3.34628), -- Mechanar Wrecker
(19714, 3.75), -- Mechanar Pulverizer (UNUSED)
(19716, 1.33852), -- Mechanar Tinkerer
(19717, 1.448), -- Disrupt the Communications Quest Credit Marker South
(19734, 1.5), -- Fungal Giant
(19735, 5.88947), -- Tempest-Forge Destroyer
(19736, 1.096), -- Althen the Historian
(19737, 1.104), -- Engineering Crewmember
(19738, 1.625), -- Doomclaw
(19739, 1.25), -- Wrathflayer
(19740, 1.25), -- Wrathwalker
(19741, 0.9), -- Hatescreamer
(19742, 0.9), -- Merciless Inciter
(19743, 1.1), -- Nathrezim Councilor
(19744, 1.1), -- Dreadwarden
(19745, 1.3), -- Pit Obliterator
(19746, 1.3), -- Pit Breaker
(19747, 6.5), -- Baelmon the Hound-Master
(19748, 1.25), -- Legionlord
(19752, 1.3), -- Marauding Infernal
(19755, 1.25), -- Mo'arg Weaponsmith
(19756, 1.25), -- Deathforge Smith
(19757, 0.99), -- Infernal Soul
(19759, 1.3), -- Newly Crafted Infernal
(19760, 1.3), -- Cooling Infernal
(19761, 1.3), -- Felspark Infernal
(19763, 1.09), -- Manni
(19764, 1.09), -- Moh
(19766, 1.09), -- Jakk
(19775, 1.03), -- Kalinda
(19776, 1.104), -- Experimental Pilot
(19778, 1.03), -- Farii
(19799, 1.1), -- Illidari Dreadbringer
(19800, 0.675), -- Illidari Painlasher
(19801, 0.27), -- Illidari Agonizer
(19802, 1.1), -- Illidari Shocktrooper
(19803, 1.1), -- Illidari Destroyer
(19804, 0.9), -- Hound of the Betrayer
(19812, 0.9), -- Illidari Informant
(19819, 1.25), -- [PH] Illidari Overseer
(19820, 1.25), -- Illidari Executioner
(19821, 1.1), -- Illidari Peacekeer
(19822, 1.1), -- Illidari Brute
(19823, 12.0), -- Crazed Colossus
(19824, 6.0), -- Son of Corok
(19836, 1.1), -- Mixie Farshot
(19837, 1.352), -- Daga Ramba
(19845, 1.448), -- Area 52 Fireworks Controller
(19847, 15.6), -- Levixus
(19849, 13.0), -- Scrap Reaver X6000

(19851, 26.0), -- Negatron
(19852, 0.9), -- Artifact Seeker
(19853, 1.1), -- Felblade Doomguard
(19854, 1.1), -- Nathrezim Surveyor
(19865, 1.33852), -- Mutate Horror
(19872, 62.5), -- Lady Catriona Von'Indi
(19873, 50.0), -- Lord Crispin Ference
(19874, 62.5), -- Baron Rafe Dreuger
(19875, 62.5), -- Baroness Dorothea Millstipe
(19876, 50.0), -- Lord Robin Daris
(19884, 4.0), -- Bogstrok (1)
(19885, 8.0), -- Coilfang Champion (1)
(19886, 8.0), -- Coilfang Defender (1)
(19887, 8.0), -- Coilfang Enchantress (1)
(19888, 8.0), -- Coilfang Observer (1)
(19889, 8.0), -- Coilfang Slavehandler (1)
(19890, 8.0), -- Coilfang Soothsayer (1)
(19891, 8.0), -- Coilfang Technician (1)
(19892, 8.0), -- Greater Bogstrok (1)
(19893, 100.0), -- Mennu the Betrayer (1)
(19894, 80.0), -- Quagmirran (1)
(19895, 80.0), -- Rokmar the Crackler (1)
(19902, 4.0), -- Wastewalker Slave (1)
(19903, 4.0), -- Coilfang Collaborator (1)
(19904, 4.0), -- Wastewalker Worker (1)
(19919, 1.33852), -- Thorn Lasher
(19920, 1.33852), -- Thorn Flayer
(19923, 1.104), -- Bipp Glizzitor
(19927, 1.3), -- Time Watcher Transform
(19937, 1.096), -- Commander Hogarth
(19940, 6.0), -- Apex
(19942, 2.088), -- Agent Proudwell
(19949, 1.07081), -- Sapling
(19953, 1.33852), -- Frayer Protector
(19958, 1.33852), -- White Seedling
(19960, 1.25), -- Doomforge Engineer
(19962, 1.33852), -- Blue Seedling
(19963, 3.6), -- Doomcryer
(19964, 1.33852), -- Red Seedling
(19965, 1.25), -- Doomforge Constructor
(19967, 1.25), -- Terror Sentry
(19968, 0.9), -- Maiden of Nightmares
(19969, 1.33852), -- Green Seedling
(19970, 1.25), -- Dreadforge Steam-Smith
(19972, 1.1), -- Night Walker
(19973, 1.25), -- Abyssal Flamebringer
(19974, 1.25), -- Dreadforge Machinist
(19976, 1.25), -- Terrorslayer
(19978, 1.25), -- Deathforge Over-Smith
(19980, 1.25), -- Void Terror
(19981, 1.25), -- Eredar Fel-Lord
(19988, 0.833333), -- Grishna Falconwing
(20021, 0.5), -- Nether Whelp
(20031, 13.0), -- Bloodwarder Legionnaire
(20032, 13.0), -- Bloodwarder Vindicator
(20033, 13.0), -- Astromancer
(20034, 13.0), -- Star Scryer
(20035, 26.0), -- Bloodwarder Marshal
(20036, 6.5), -- Bloodwarder Squire
(20037, 13.0), -- Tempest Falconer
(20038, 6.5), -- Phoenix-Hawk Hatchling
(20039, 52.0), -- Phoenix-Hawk
(20040, 57.200001), -- Crystalcore Devastator
(20041, 28.6), -- Crystalcore Sentinel
(20042, 13.0), -- Tempest-Smith
(20043, 6.5), -- Apprentice Star Scryer
(20044, 6.5), -- Novice Astromancer
(20045, 26.0), -- Nether Scryer
(20046, 26.0), -- Astromancer Lord
(20047, 13.0), -- Crimson Hand Battle Mage
(20048, 13.0), -- Crimson Hand Centurion
(20049, 13.0), -- Crimson Hand Blood Knight
(20050, 26.0), -- Crimson Hand Inquisitor
(20051, 16.25), -- UNUSED Golem Crafter
(20052, 16.25), -- Crystalcore Mechanic
(20059, 2.67703), -- Sunseeker Netherbinder
(20060, 84.5), -- Lord Sanguinar
(20062, 84.5), -- Grand Astromancer Capernian
(20063, 84.5), -- Master Engineer Telonicus
(20064, 84.5), -- Thaladred the Darkener
(20078, 1.33852), -- Summoned Bloodwarder Reservist
(20083, 1.33852), -- Summoned Bloodwarder Mender
(20086, 1.448), -- Netherstorm Triangulation Point One Trigger
(20114, 1.448), -- Netherstorm Triangulation Point Two Trigger
(20115, 1.104), -- Umbrafen Witchdoctor
(20121, 1.03), -- Fingin
(20123, 1.12), -- Farmer Griffith
(20126, 3.0), -- Sylvanaar Ancient Protector
(20127, 1.104), -- Tame Kaliri
(20132, 78.0), -- Socrethar
(20133, 1.25), -- Image of Socrethar
(20138, 4.4), -- Culuthas
(20141, 1.25), -- Hound of Culuthas
(20148, 1.1), -- Dead Doomguard
(20160, 2.08), -- Infernal Defender
(20164, 24.0), -- Bog Giant (1)
(20165, 40.0), -- Claw (1)
(20168, 80.0), -- Ghaz'an (1)
(20169, 80.0), -- Hungarfen (1)
(20173, 8.0), -- Fen Ray (1)
(20174, 8.0), -- Lykul Stinger (1)
(20175, 4.0), -- Lykul Wasp (1)
(20177, 8.0), -- Murkblood Healer (1)
(20179, 8.0), -- Murkblood Oracle (1)
(20180, 8.0), -- Murkblood Spearman (1)
(20181, 8.0), -- Murkblood Tribesman (1)
(20183, 50.0), -- Swamplord Musel'ek (1)
(20184, 100.0), -- The Black Stalker (1)
(20185, 8.0), -- Underbat (1)
(20187, 48.0), -- Underbog Lord (1)
(20188, 8.0), -- Underbog Lurker (1)
(20189, 4.0), -- Underbog Mushroom (1)
(20190, 8.0), -- Underbog Shambler (1)
(20191, 8.0), -- Wrathfin Myrmidon (1)
(20192, 8.0), -- Wrathfin Sentry (1)
(20193, 8.0), -- Wrathfin Warrior (1)
(20195, 0.9936), -- Dagz
(20197, 0.9), -- Bogflare Needler
(20198, 0.9), -- Fenglow Stinger
(20202, 6.0), -- Cragskaar
(20214, 0.25), -- Arakkoa Egg
(20215, 1.43), -- Pentatharon
(20226, 1.448), -- Manaforge Visual Trigger
(20227, 1.1), -- Apprentice Tedon
(20230, 1.448), -- Blade's Edge - Bladespire Trigger 01
(20232, 2.104), -- Wing Commander Gryphongar
(20233, 1.1), -- Apprentice Vishael
(20234, 28.125), -- Runetog Wildhammer
(20243, 9.75), -- Scrapped Fel Reaver
(20250, 1.05), -- Rashere Pridehoof
(20251, 1.448), -- Honor Hold Scout Archery Target
(20252, 4.0), -- Arcane Fiend (1)
(20253, 4.0), -- Ethereal Apprentice (1)
(20254, 2.0), -- Ethereal Beacon (1)
(20255, 8.0), -- Ethereal Crypt Raider (1)
(20256, 8.0), -- Ethereal Darkcaster (1)
(20257, 8.0), -- Ethereal Priest (1)
(20258, 8.0), -- Ethereal Scavenger (1)
(20259, 8.0), -- Ethereal Sorcerer (1)
(20260, 8.0), -- Ethereal Spellbinder (1)
(20261, 16.0), -- Ethereal Theurgist (1)
(20262, 4.0), -- Ethereal Wraith (1)
(20263, 4.0), -- Mana Leech (1)
(20264, 8.0), -- Nexus Stalker (1)
(20265, 20.799999), -- Nexus Terror (1)
(20266, 100.0), -- Nexus-Prince Shaffar (1)
(20267, 80.0), -- Pandemonius (1)
(20268, 80.0), -- Tavarok (1)
(20292, 3.75), -- Marsh Baron Brok
(20296, 1.448), -- Teleporter Explosion Trigger
(20298, 8.0), -- Angered Skeleton (1)
(20299, 8.0), -- Auchenai Monk (1)
(20300, 16.0), -- Auchenai Necromancer (1)
(20301, 8.0), -- Auchenai Soulpriest (1)
(20302, 8.0), -- Auchenai Vindicator (1)
(20303, 80.0), -- Avatar of the Martyred (1)
(20305, 4.0), -- Stolen Soul (1)
(20306, 100.0), -- Exarch Maladaar (1)
(20309, 4.0), -- Phantasmal Possessor (1)
(20310, 4.0), -- Phasing Cleric (1)
(20311, 4.0), -- Phasing Soldier (1)
(20312, 4.0), -- Phasing Sorcerer (1)
(20313, 4.0), -- Phasing Stalker (1)
(20315, 8.0), -- Raging Skeleton (1)
(20316, 4.0), -- Raging Soul (1)
(20317, 2.0), -- Reanimated Bones (1)
(20318, 100.0), -- Shirrak the Dead Watcher (1)
(20320, 4.0), -- Unliving Cleric (1)
(20321, 4.0), -- Unliving Soldier (1)
(20322, 4.0), -- Unliving Sorcerer (1)
(20323, 4.0), -- Unliving Stalker (1)
(20326, 1.25), -- Mo'arg Warp-Master
(20329, 3.75), -- Grishna Matriarch
(20333, 1.448), -- Northern Pipe Credit Marker
(20336, 1.448), -- Eastern Pipe Credit Marker
(20337, 1.448), -- Southern Pipe Credit Marker
(20338, 1.448), -- Western Pipe Credit Marker
(20343, 0.267702), -- Charming Totem
(20392, 1.05), -- Boom Bot Target
(20394, 0.9), -- Eye of Culuthas
(20399, 0.675), -- Terror Imp
(20402, 1.375), -- Legion Shocktrooper
(20403, 2.5), -- Legion Destroyer
(20411, 0.011), -- Spectral Bovine
(20417, 1.448), -- Coruu Control Console
(20418, 1.62), -- Duro Control Console
(20427, 3.6), -- Veneratus the Many
(20439, 1.25), -- Ara Engineer
(20442, 3.75), -- Captain Bo'kar
(20445, 3.33333), -- Mal'druk the Soulrender
(20460, 3.75), -- Chief Engineer Gork'lonn
(20465, 1.33852), -- Underbog Frenzy
(20473, 1.448), -- Surveying Marker One
(20475, 1.448), -- Surveying Marker Two
(20476, 1.448), -- Surveying Marker Three
(20479, 1.0), -- Unstable Shroom
(20481, 1.33852), -- Raging Flames
(20486, 1.104), -- Blue Wind Rider
(20488, 1.104), -- Tawny Wind Rider
(20494, 3.15), -- Dama Wildmane
(20503, 1.104), -- Ebon Gryphon
(20504, 1.104), -- Golden Gryphon
(20505, 1.104), -- Snowy Gryphon Mount
(20510, 4.0625), -- Brunn Flamebeard
(20513, 2.096), -- Honor Hold Defender
(20515, 46.75), -- Harpax
(20519, 0.75), -- Boom Bot Xtreme
(20521, 115.0), -- Captain Skarloc (1)
(20523, 5.2), -- Durnholde Armorer (1)
(20525, 8.0), -- Durnholde Mage (1)
(20526, 8.0), -- Durnholde Rifleman (1)
(20527, 8.0), -- Durnholde Sentry (1)
(20528, 4.0), -- Durnholde Tracking Hound (1)
(20529, 10.4), -- Durnholde Veteran (1)
(20530, 10.4), -- Durnholde Warden (1)
(20531, 92.0), -- Epoch Hunter (1)
(20532, 5.72), -- Infinite Defiler (1)
(20533, 5.72), -- Infinite Saboteur (1)
(20534, 5.72), -- Infinite Slayer (1)
(20535, 92.0), -- Lieutenant Drake (1)
(20537, 8.0), -- Lordaeron Sentry (1)
(20538, 8.0), -- Lordaeron Watchman (1)
(20541, 1.755), -- Orc Prisoner (1)
(20542, 4.0), -- Pit Announcer (1)
(20543, 4.0), -- Pit Spectator (1)
(20545, 8.0), -- Tarren Mill Guardsman (1)
(20546, 8.0), -- Tarren Mill Lookout (1)
(20547, 8.0), -- Tarren Mill Protector (1)
(20548, 26.0), -- Thrall (1)
(20556, 2.02), -- Stormwind Marine
(20557, 1.25), -- Wrath Hound
(20558, 1.25), -- Forge Hound
(20562, 0.77), -- Invisible Stalker (Scale x5)
(20565, 8.0), -- Creeping Ooze (1)
(20566, 4.0), -- Creeping Oozeling (1)
(20567, 4.0), -- Fel Orc Convert (1)
(20568, 100.0), -- Grand Warlock Nethekurse (1)
(20569, 4.0), -- Heathen Guard (1)
(20574, 4.0), -- Rabid Warhound (1)
(20575, 4.0), -- Reaver Guard (1)
(20576, 8.0), -- Shadowmoon Acolyte (1)
(20577, 8.0), -- Shadowmoon Darkcaster (1)
(20578, 4.0), -- Sharpshooter Guard (1)
(20579, 4.0), -- Shattered Hand Archer (1)
(20580, 8.0), -- Shattered Hand Assassin (1)
(20582, 8.0), -- Shattered Hand Brawler (1)
(20583, 16.0), -- Shattered Hand Centurion (1)
(20584, 8.0), -- Shattered Hand Champion (1)
(20585, 16.0), -- Shattered Hand Executioner (1)
(20586, 8.0), -- Shattered Hand Gladiator (1)
(20587, 8.0), -- Shattered Hand Heathen (1)
(20588, 8.0), -- Shattered Hand Houndmaster (1)
(20589, 16.0), -- Shattered Hand Legionnaire (1)
(20590, 8.0), -- Shattered Hand Reaver (1)
(20591, 8.0), -- Shattered Hand Savage (1)
(20592, 4.0), -- Shattered Hand Scout (1)
(20593, 8.0), -- Shattered Hand Sentry (1)
(20594, 8.0), -- Shattered Hand Sharpshooter (1)
(20595, 4.0), -- Shattered Hand Zealot (1)
(20596, 80.0), -- Warbringer O'mrogg (1)
(20597, 80.0), -- Warchief Kargath Bladefist (1)
(20599, 4.5), -- Lured Colossus
(20604, 1.04), -- Dugiru
(20612, 1.04), -- Sorim Lightsong
(20620, 8.0), -- Coilfang Engineer (1)
(20621, 8.0), -- Coilfang Myrmidon (1)
(20622, 8.0), -- Coilfang Oracle (1)
(20623, 8.0), -- Coilfang Siren (1)
(20624, 8.0), -- Coilfang Slavemaster (1)
(20625, 8.0), -- Coilfang Sorceress (1)
(20626, 8.0), -- Coilfang Warrior (1)
(20627, 8.0), -- Coilfang Water Elemental (1)
(20628, 4.0), -- Dreghood Slave (1)
(20629, 100.0), -- Hydromancer Thespia (1)
(20630, 80.0), -- Mekgineer Steamrigger (1)
(20631, 4.0), -- Naga Distiller (1)
(20632, 4.0), -- Steamrigger Mechanic (1)
(20633, 80.0), -- Warlord Kalithresh (1)
(20636, 100.0), -- Ambassador Hellmaw (1)
(20637, 80.0), -- Blackheart the Inciter (1)
(20638, 8.0), -- Cabal Acolyte (1)
(20639, 8.0), -- Cabal Assassin (1)
(20640, 8.0), -- Cabal Cultist (1)
(20641, 8.0), -- Cabal Deathsworn (1)
(20642, 8.0), -- Cabal Executioner (1)
(20643, 3.6), -- Cabal Familiar (1)
(20644, 8.0), -- Cabal Fanatic (1)
(20645, 8.0), -- Cabal Ritualist (1)
(20646, 8.0), -- Cabal Shadow Priest (1)
(20647, 8.0), -- Cabal Spellbinder (1)
(20648, 8.0), -- Cabal Summoner (1)
(20649, 8.0), -- Cabal Warlock (1)
(20650, 8.0), -- Cabal Zealot (1)
(20651, 3.6), -- Fel Guardhound (1)
(20652, 17.6), -- Fel Overseer (1)
(20653, 100.0), -- Grandmaster Vorpil (1)
(20655, 3.6), -- Maiden of Discipline (1)
(20656, 14.4), -- Malicious Instructor (1)
(20657, 200.0), -- Murmur (1)
(20658, 2.44688), -- Shape of the Beast (1)
(20660, 8.0), -- Summoned Cabal Acolyte (1)
(20661, 8.0), -- Summoned Cabal Deathsworn (1)
(20662, 2.0), -- Tortured Skeleton (1)
(20664, 4.0), -- Void Traveler (1)
(20666, 1.448), -- Blade's Edge - Orb Trigger 01
(20667, 0.125), -- Sporewind Frenzy
(20670, 1.448), -- Blade's Edge - Flesh Beast Zap Trigger
(20674, 50.0), -- Shield of Velen
(20680, 1.25), -- Arzeth the Powerless
(20683, 1.08), -- Prophetess Cavrylin
(20684, 5.0), -- Lady Shav'rar
(20686, 4.0), -- Avian Darkhawk (1)
(20687, 2.0), -- Charming Totem (1)
(20688, 16.0), -- Cobalt Serpent (1)
(20689, 4.0), -- Dark Vortex (1)
(20690, 112.0), -- Darkweaver Syth (1)
(20691, 8.0), -- Time-Lost Controller (1)
(20692, 8.0), -- Sethekk Guard (1)
(20693, 8.0), -- Sethekk Initiate (1)
(20694, 8.0), -- Sethekk Oracle (1)
(20695, 8.0), -- Sethekk Prophet (1)
(20696, 8.0), -- Sethekk Ravenguard (1)
(20697, 8.0), -- Time-Lost Scryer (1)
(20698, 8.0), -- Time-Lost Shadowmage (1)
(20699, 8.0), -- Sethekk Shaman (1)
(20700, 100.0), -- Sethekk Spirit (1)
(20701, 8.0), -- Sethekk Talon Lord (1)
(20702, 4.0), -- Syth Arcane Elemental (1)
(20703, 4.0), -- Syth Fire Elemental (1)
(20704, 4.0), -- Syth Frost Elemental (1)
(20705, 4.0), -- Syth Shadow Elemental (1)
(20706, 112.0), -- Talon King Ikiss (1)
(20713, 0.5), -- Fey Drake
(20722, 1.09), -- Herald Bran'daan
(20724, 1.09), -- Herald Amorlin
(20737, 92.0), -- Aeonus (1)
(20738, 115.0), -- Chrono Lord Deja (1)
(20739, 1.1), -- Imprisoned Infinite Dragonspawn (1)
(20740, 5.72), -- Infinite Assassin (1)
(20741, 5.72), -- Infinite Chronomancer (1)
(20742, 11.44), -- Infinite Executioner (1)
(20743, 11.44), -- Infinite Vanquisher (1)
(20744, 20.799999), -- Rift Lord (1)
(20745, 92.0), -- Temporus (1)
(20746, 162.5), -- Time Keeper (1)
(20762, 28.125), -- Gur'zil
(20763, 1.1), -- Captured Protectorate Vanguard
(20772, 6.0), -- Netherock
(20784, 1.25), -- Armbreaker Huffaz
(20789, 1.25), -- Wrathbringer Laz-tarash
(20796, 1.448), -- Netherstorm Target
(20798, 1.25), -- Razorsaw
(20800, 5.625), -- Forgemaster Morug
(20801, 5.85), -- Silroth
(20803, 1.25), -- Overmaster Grindgarr
(20847, 1.06), -- Purple Elekk
(20848, 1.104), -- Great Blue Elekk
(20849, 1.104), -- Great Green Elekk
(20850, 1.104), -- Great Purple Elekk
(20851, 1.448), -- Blade's Edge - Deadsoul Orb Flight 01
(20852, 1.448), -- Blade's Edge - Deadsoul Orb Flight 02
(20853, 1.448), -- Blade's Edge - Deadsoul Orb Flight 03
(20855, 1.448), -- Blade's Edge - Deadsoul Orb Flight 04
(20856, 1.448), -- Blade's Edge - Deadsoul Orb Flight 05
(20857, 2.67703), -- Arcatraz Defender
(20859, 2.67703), -- Arcatraz Warder
(20864, 5.35406), -- Protean Nightmare
(20865, 1.33852), -- Protean Horror
(20866, 6.69258), -- Soul Devourer
(20867, 4.81866), -- Death Watcher
(20868, 4.81866), -- Entropic Eye
(20869, 14.1347), -- Arcatraz Sentinel
(20870, 40.25), -- Zereketh the Unbound
(20873, 5.35406), -- Negaton Warp-Master
(20874, 1.104), -- Skettis Refugee
(20875, 5.35406), -- Negaton Screamer
(20876, 1.304), -- Human Refugee
(20877, 1.304), -- Shattrath Refugee
(20879, 6.96028), -- Eredar Soul-Eater
(20881, 5.88947), -- Unbound Devastator
(20882, 4.81866), -- Skulking Witch
(20883, 4.81866), -- Spiteful Temptress
(20885, 46.0), -- Dalliah the Doomsayer
(20886, 46.0), -- Wrath-Scryer Soccothrates
(20887, 0.27), -- Deathforge Imp
(20888, 11.7), -- Solus the Eternal
(20890, 2.104), -- Siflaed Coldhammer
(20891, 2.104), -- Skraa
(20892, 2.104), -- Ruogo
(20893, 2.104), -- Morula
(20896, 2.67703), -- Ethereum Slayer
(20897, 2.67703), -- Ethereum Wave-Caster
(20898, 6.69258), -- Gargantuan Abyssal
(20900, 5.88947), -- Unchained Doombringer
(20901, 2.94473), -- Sargeron Archer
(20902, 2.94473), -- Sargeron Hellcaller
(20903, 1.25), -- Protectorate Nether Drake
(20904, 5.35406), -- Warden Mellichar
(20905, 6.02331), -- Blazing Trickster
(20906, 6.69257), -- Phase-Hunter
(20908, 6.69257), -- Akkiris Lightning-Waker
(20909, 6.69257), -- Sulfuron Magma-Thrower
(20910, 8.36571), -- Twilight Drakonaar
(20911, 7.36183), -- Blackwing Drakonaar
(20912, 57.5), -- Harbinger Skyriss
(20917, 1.05), -- Zinyen Swiftstrider
(20918, 0.54), -- Deathforge Felstalker
(20919, 1.25), -- Deathforge Doomguard
(20923, 23.0), -- Blood Guard Porung
(20928, 1.25), -- Ironspine Forgelord
(20929, 1.375), -- Wrath Lord
(20930, 1.08), -- Hatecryer
(20932, 32.5), -- Nuramoc
(20977, 6.69257), -- Millhouse Manastorm
(20980, 1.352), -- Dealer Rashaad
(20981, 1.352), -- Dealer Najeeb
(20986, 1.352), -- Dealer Tariq
(20988, 2.67703), -- Sunseeker Engineer
(20989, 1.352), -- Dealer Sadaqat
(20990, 2.67703), -- Bloodwarder Physician
(20993, 80.0), -- Blood Guard Porung (1)
(20995, 1.104), -- Shadowmoon Villager
(21004, 1.25), -- Lesser Nether Drake
(21019, 1.03), -- Sixx
(21021, 0.9), -- Scorch Imp
(21023, 2.1), -- Stronglimb Deeproot
(21029, 1.104), -- Captured Water Spirit
(21032, 1.625), -- Dreadwing
(21035, 26.0), -- Dimensius the All-Devouring 000
(21049, 1.104), -- Spirit of the Past
(21053, 1.448), -- Blade's Edge - Orb Trigger 03
(21062, 1.33852), -- Nether Wraith
(21067, 1.25), -- Outland Wrathguard Black
(21068, 1.25), -- Outland Wrathguard Green
(21069, 1.25), -- Outland Wrathguard Red
(21070, 1.25), -- Outland Wrathguard Pink
(21077, 1.8), -- Farahlon Crumbler
(21078, 0.9), -- Farahlon Shardling
(21079, 1.5), -- Cragskaar Shardling
(21082, 1.352), -- Krugash
(21083, 1.352), -- Erool
(21084, 1.352), -- Braagor
(21085, 1.352), -- Ragar
(21086, 1.352), -- Ruka
(21087, 1.352), -- Grikka
(21088, 1.352), -- Matron Varah
(21107, 28.125), -- Rip Pedalslam
(21126, 2.67703), -- Coilfang Scale-Healer
(21127, 5.35406), -- Coilfang Tempest
(21128, 1.33852), -- Coilfang Ray
(21135, 0.324), -- Fel Imp
(21136, 1.144), -- Infinite Chronomancer
(21137, 1.144), -- Infinite Assassin
(21138, 1.43), -- Infinite Executioner
(21139, 1.43), -- Infinite Vanquisher
(21140, 5.85), -- Rift Lord
(21146, 1.25), -- Legion Prototype Cannon 2 & 3 Felguard
(21148, 12.87), -- Rift Keeper
(21160, 10.0), -- Conjured Water Elemental
(21162, 0.9), -- Deathforge Escort
(21166, 5.5), -- Illidari Dreadlord
(21169, 82.5), -- Netharel - Metamorphosis
(21172, 1.12), -- Sarinei Whitestar
(21187, 19.5), -- Designer Island Fel Reaver [PH]
(21195, 1.25), -- Domesticated Felboar
(21209, 1.104), -- Dumphry
(21218, 26.0), -- Vashj'ir Honor Guard
(21220, 13.0), -- Coilfang Priestess
(21221, 26.0), -- Coilfang Beast-Tamer
(21224, 13.0), -- Tidewalker Depth-Seer
(21225, 13.0), -- Tidewalker Warrior
(21226, 13.0), -- Tidewalker Shaman
(21227, 13.0), -- Tidewalker Harpooner
(21228, 13.0), -- Tidewalker Hydromancer
(21229, 13.0), -- Greyheart Tidecaller
(21230, 13.0), -- Greyheart Nether-Mage
(21231, 13.0), -- Greyheart Shield-Bearer
(21232, 13.0), -- Greyheart Skulker
(21246, 6.5), -- Serpentshrine Sporebat
(21249, 5.0), -- Wrathstalker
(21250, 1.1), -- Pink Elekk
(21251, 78.0), -- Underbog Colossus
(21253, 1.0), -- Tainted Water Elemental
(21260, 1.0), -- Purified Water Elemental
(21261, 1.448), -- Big Wagon Full of Explosives Trigger
(21262, 1.448), -- Goblin Equipment Trigger
(21263, 6.5), -- Greyheart Technician
(21268, 12.0714), -- Netherstrand Longbow
(21269, 12.0714), -- Devastation
(21270, 12.0714), -- Cosmic Infuser
(21271, 12.0714), -- Infinity Blades
(21272, 12.0714), -- Warp Slicer
(21273, 12.0714), -- Phaseshift Bulwark
(21274, 12.0714), -- Staff of Disintegration
(21287, 1.56), -- Warbringer Razuun
(21289, 0.65), -- Inactive Infernal
(21298, 13.0), -- Coilfang Serpentguard
(21299, 13.0), -- Coilfang Fathom-Witch
(21301, 13.0), -- Coilfang Shatterer
(21303, 2.67703), -- Defender Corpse

(21304, 2.67703), -- Warder Corpse
(21309, 0.9), -- Painmistress Gabrissa
(21314, 1.25), -- Terrormaster
(21316, 1.3), -- Deathforged Infernal
(21323, 1.5), -- Netherock Crumbler
(21325, 6.0), -- Raven's Wood Stonebark
(21326, 1.5), -- Raven's Wood Leafbeard
(21328, 1.5), -- Apex Crumbler
(21329, 37.5), -- JAB Nether Serpent
(21336, 1.104), -- Gedrah
(21337, 1.1), -- Illidari Shadowstalker
(21338, 1.33852), -- Coilfang Leper
(21339, 13.0), -- Coilfang Hate-Screamer
(21340, 1.104), -- Detrafila
(21346, 0.441711), -- Sightless Eye
(21348, 1.448), -- Shadowmoon Trigger
(21350, 52.0), -- Gronn-Priest
(21358, 12.6), -- Designer Island Tauren Herder [PH]
(21362, 26.0), -- Phoenix
(21364, 26.0), -- Phoenix Egg
(21369, 1000.0), -- Kael'thas Sunstrider
(21378, 0.5), -- [UNUSED]Test Nether Whelp
(21387, 0.4), -- Wyrmcult Blackwhelp
(21389, 1.87), -- Maxnar the Ashmaw
(21395, 1.33852), -- Protean Spawn
(21404, 5.2), -- Legion Hold Fel Reaver
(21406, 1.25), -- Netherwing Drake
(21407, 1.3), -- Netherwing Dragon
(21419, 1.3), -- Infernal Attacker
(21429, 1.448), -- Bone Wastes - Sealed Coffin Trigger 01
(21443, 1.448), -- Bone Wastes - Orb Waypoint 01
(21450, 0.75), -- Skethyl Owl
(21451, 1.448), -- Bone Wastes - Event Trigger A
(21463, 1.448), -- Bone Wastes - Portal Trigger
(21466, 26.7703), -- Harbinger Skyriss
(21469, 1.104), -- Daranelle
(21489, 1.448), -- Bone Wastes - Event Trigger B
(21492, 1.1), -- Wyrmcult Blessed
(21497, 6.5), -- Blackscale
(21499, 1.25), -- Overseer Ripsaw
(21500, 5.2), -- Morgroron
(21501, 5.2), -- Makazradon
(21502, 1.25), -- Image of Warbringer Razuun
(21506, 6.5), -- Azaloth
(21508, 6.5), -- Coilfang Frenzy
(21517, 1.104), -- Ilthuril
(21518, 1.104), -- Oruhe
(21519, 1.1), -- Death's Might
(21520, 1.1), -- Illidari Jailor
(21521, 2.0), -- Arcane Servant (1)
(21522, 8.0), -- Bloodwarder Centurion (1)
(21523, 8.0), -- Bloodwarder Physician (1)
(21524, 8.0), -- Bloodwarder Slayer (1)
(21525, 40.0), -- Gatewatcher Gyro-Kill (1)
(21526, 40.0), -- Gatewatcher Iron-Hand (1)
(21527, 10.0), -- Mechanar Crusher (1)
(21528, 10.0), -- Mechanar Driller (1)
(21529, 3.75), -- Mechanar Pulverizer (UNUSED) (1)
(21530, 3.75), -- Mechanar Ripper (UNUSED) (1)
(21531, 4.0), -- Mechanar Tinkerer (1)
(21532, 10.0), -- Mechanar Wrecker (1)
(21533, 80.0), -- Mechano-Lord Capacitus (1)
(21534, 1.06667), -- Nether Charge (1)
(21535, 2.0), -- Nether Wraith (1)
(21536, 100.0), -- Nethermancer Sepethrea (1)
(21537, 100.0), -- Pathaleon the Calculator (1)
(21538, 4.0), -- Raging Flames (1)
(21539, 8.0), -- Sunseeker Astromage (1)
(21540, 8.0), -- Sunseeker Engineer (1)
(21541, 8.0), -- Sunseeker Netherbinder (1)
(21542, 17.6), -- Tempest-Forge Destroyer (1)
(21543, 17.6), -- Tempest-Forge Patroller (1)
(21544, 4.0), -- Bloodfalcon (1)
(21545, 8.0), -- Bloodwarder Falconer (1)
(21546, 8.0), -- Bloodwarder Greenkeeper (1)
(21547, 8.0), -- Bloodwarder Mender (1)
(21548, 8.0), -- Bloodwarder Protector (1)
(21549, 8.0), -- Bloodwarder Steward (1)
(21550, 2.0), -- Blue Seedling (1)
(21551, 80.0), -- Commander Sarannis (1)
(21552, 1.33333), -- Frayer (1)
(21553, 4.0), -- Frayer Protector (1)
(21554, 2.0), -- Frayer Wildling (1)
(21555, 4.0), -- Greater Frayer (1)
(21557, 2.0), -- Green Seedling (1)
(21558, 100.0), -- High Botanist Freywinn (1)
(21559, 80.0), -- Laj (1)
(21560, 4.0), -- Mutate Fear-Shrieker (1)
(21561, 4.0), -- Mutate Fleshlasher (1)
(21562, 4.0), -- Mutate Horror (1)
(21563, 8.8), -- Nethervine Inciter (1)
(21564, 8.8), -- Nethervine Reaper (1)
(21565, 8.8), -- Nethervine Trickster (1)
(21566, 2.0), -- Red Seedling (1)
(21567, 4.0), -- Sapling (1)
(21568, 4.0), -- Summoned Bloodwarder Mender (1)
(21569, 4.0), -- Summoned Bloodwarder Reservist (1)
(21570, 8.0), -- Sunseeker Botanist (1)
(21571, 8.0), -- Sunseeker Channeler (1)
(21572, 8.0), -- Sunseeker Chemist (1)
(21573, 8.0), -- Sunseeker Gene-Splicer (1)
(21574, 8.0), -- Sunseeker Geomancer (1)
(21575, 8.0), -- Sunseeker Harvester (1)
(21576, 8.0), -- Sunseeker Herbalist (1)
(21577, 8.0), -- Sunseeker Researcher (1)
(21578, 17.6), -- Tempest-Forge Peacekeeper (1)
(21579, 4.0), -- Thorn Flayer (1)
(21580, 4.0), -- Thorn Lasher (1)
(21581, 100.0), -- Thorngrin the Tender (1)
(21582, 80.0), -- Warp Splinter (1)
(21583, 2.0), -- White Seedling (1)
(21585, 8.0), -- Arcatraz Defender (1)
(21586, 17.6), -- Arcatraz Sentinel (1)
(21587, 5.4), -- Arcatraz Warder (1)
(21588, 35.200001), -- Blackwing Drakonaar (1)
(21589, 28.799999), -- Blazing Trickster (1)
(21590, 80.0), -- Dalliah the Doomsayer (1)
(21591, 14.4), -- Death Watcher (1)
(21592, 4.0), -- Defender Corpse (1)
(21593, 14.4), -- Entropic Eye (1)
(21594, 20.799999), -- Eredar Deathbringer (1)
(21595, 20.799999), -- Eredar Soul-Eater (1)
(21596, 8.0), -- Ethereum Slayer (1)
(21597, 8.0), -- Ethereum Wave-Caster (1)
(21598, 20.0), -- Gargantuan Abyssal (1)
(21599, 100.0), -- Harbinger Skyriss (1)
(21600, 100.0), -- Harbinger Skyriss (1)
(21601, 100.0), -- Harbinger Skyriss (1)
(21602, 8.0), -- Millhouse Manastorm (1)
(21604, 16.0), -- Negaton Screamer (1)
(21605, 16.0), -- Negaton Warp-Master (1)
(21606, 32.0), -- Phase-Hunter (1)
(21607, 4.0), -- Protean Horror (1)
(21608, 16.0), -- Protean Nightmare (1)
(21609, 4.0), -- Protean Spawn (1)
(21610, 8.8), -- Sargeron Archer (1)
(21611, 8.8), -- Sargeron Hellcaller (1)
(21613, 14.4), -- Skulking Witch (1)
(21614, 20.0), -- Soul Devourer (1)
(21615, 14.4), -- Spiteful Temptress (1)
(21616, 32.0), -- Sulfuron Magma-Thrower (1)
(21617, 32.0), -- Akkiris Lightning-Waker (1)
(21618, 40.0), -- Twilight Drakonaar (1)
(21619, 17.6), -- Unbound Devastator (1)
(21621, 17.6), -- Unchained Doombringer (1)
(21624, 80.0), -- Wrath-Scryer Soccothrates (1)
(21626, 100.0), -- Zereketh the Unbound (1)
(21633, 1.3), -- Deathbringer Jovaan
(21645, 8.8), -- Felguard Brute (1)
(21646, 3.6), -- Hellfire Familiar (1)
(21648, 5.0), -- Mature Netherwing Drake
(21654, 1.104), -- Skettis Followers Spawner
(21656, 1.1), -- Illidari Satyr
(21657, 18.75), -- Neltharaku
(21658, 5.5), -- [UNUSED]Death's Deliverer
(21664, 10.0), -- Human Charger
(21682, 10.0), -- Human Cleric
(21683, 20.0), -- Human Conjurer
(21684, 40.0), -- King Llane
(21690, 0.9), -- R-3D0
(21694, 8.03109), -- Bog Overlord
(21695, 5.35406), -- Tidal Surger
(21696, 1.33852), -- Steam Surger
(21697, 22.424999), -- Infinite Chrono-Lord
(21698, 21.5625), -- Infinite Timereaver
(21702, 2.67703), -- Ethereum Life-Binder
(21712, 149.5), -- Infinite Chrono-Lord (1)
(21721, 0.5), -- Enslaved Netherwing Whelp
(21722, 0.75), -- Enslaved Netherwing Drake
(21726, 10.0), -- Summoned Demon
(21747, 10.0), -- Orc Necrolyte
(21748, 10.0), -- Orc Wolf
(21750, 20.0), -- Orc Warlock
(21752, 40.0), -- Warchief Blackhand
(21762, 0.9), -- Illidari Tormentor
(21766, 46.75), -- Alieshor
(21768, 22.0), -- Vagath
(21776, 0.9), -- Illidari Temptress
(21785, 47.25), -- Underbog Quaker (UNUSED)
(21786, 1.3), -- Infernal Attacker (1)
(21801, 18.75), -- Vhel'kur
(21806, 13.0), -- Greyheart Spellbinder
(21808, 1.1), -- Illidari Overseer
(21811, 0.15), -- Wyrmcult Broodling
(21812, 1.1), -- Phantom Leotheras
(21817, 1.25), -- Adolescent Nether Drake
(21818, 0.4275), -- Infinite Whelp
(21820, 1.25), -- Mature Nether Drake
(21821, 1.25), -- Proto-Nether Drake
(21823, 1.3), -- Nihil the Banished
(21827, 1.21), -- Zandras
(21830, 0.9), -- Beholder (beige)
(21831, 0.9), -- Beholder (blue)
(21832, 0.9), -- Beholder (black)
(21833, 0.9), -- Beholder (gray)
(21835, 0.9), -- Beholder (red)
(21836, 0.9), -- Beholder (spittle)
(21841, 4.0), -- Coilfang Ray (1)
(21842, 8.0), -- Coilfang Scale-Healer (1)
(21843, 16.0), -- Coilfang Tempest (1)
(21844, 7.5), -- Mountain Colossus
(21847, 0.9936), -- Fel Guard Hound
(21857, 7.15), -- Inner Demon
(21863, 26.0), -- Serpentshrine Lurker
(21865, 13.0), -- Coilfang Ambusher
(21867, 9.0), -- Teron Gorefiend
(21873, 13.0), -- Coilfang Guardian
(21875, 650.0), -- Shadow of Leotheras
(21878, 1.25), -- Felboar
(21887, 1.05), -- Tauren Female Illusion
(21888, 1.05), -- Tauren Male Illusion
(21892, 1.448), -- Azaloth Credit Marker
(21894, 0.9), -- Xeleth
(21904, 2.67703), -- Avian Warhawk
(21908, 1.25), -- Spellbound Terrorguard
(21913, 1000.0), -- Water Globule
(21914, 48.0), -- Bog Overlord (1)
(21915, 4.0), -- Coilfang Leper (1)
(21916, 4.0), -- Steam Surger (1)
(21917, 16.0), -- Tidal Surger (1)
(21918, 9.0), -- Coilfang Guardian (1)
(21920, 6.5), -- Tidewalker Lurker
(21921, 1000.0), -- Karazhan Chess - Sound Bunny
(21923, 1.25), -- Terrorguard Protector
(21925, 0.99), -- Avatar of Sathal
(21928, 1.1), -- Lothros
(21932, 650.0), -- Hydross the Unstable
(21936, 1.5), -- Crazed Shardling
(21938, 1.05), -- Earthmender Splinthoof
(21941, 0.9), -- Accursed Apparition
(21943, 4.0), -- Underbog Frenzy (1)
(21949, 13.0), -- Fel Reaver Sentinel
(21958, 2.6), -- Enchanted Elemental
(21959, 13.0), -- Fel Reaver Sentinel Credit
(21961, 12.5), -- Cataclysm Overseer
(21963, 1.1), -- Enslaved Doomguard
(21964, 162.5), -- Fathom-Guard Caribdis
(21965, 162.5), -- Fathom-Guard Tidalvess
(21966, 162.5), -- Fathom-Guard Sharkkis
(21970, 1.11), -- Officer Dawning
(21971, 1.11), -- Officer Khaluun
(21976, 1.5), -- Area 52 Death Machine
(21978, 1.25), -- Shadowmoon Valley Wildlife
(21989, 4.0), -- Avian Ripper (1)
(21990, 8.0), -- Avian Warhawk (1)
(22000, 1.0), -- Dragonmaw Nether Drake
(22007, 1.05), -- Tree Warden Chawn
(22009, 2.6), -- Tainted Elemental
(22011, 6.0), -- Corok the Mighty
(22014, 1.1), -- Silvermoon Citizen
(22027, 5.2), -- Nether Drakonid (Black)
(22028, 5.2), -- Nether Drakonid Boss (Purple)
(22029, 5.2), -- Nether Drakonid (Purple)
(22030, 5.2), -- Nether Drakonid (Blue)
(22031, 5.2), -- Nether Drakonid (Green)
(22032, 5.2), -- Nether Drakonid Boss (Green)
(22033, 5.2), -- Nether Drakonid Boss (Blue)
(22034, 5.2), -- Nether Drakonid Boss (Black)
(22035, 6.5), -- Pure Spawn of Hydross
(22036, 6.5), -- Tainted Spawn of Hydross
(22041, 1.215), -- Corrupted Spectre[PH]
(22051, 6.0), -- Crazed Colossus Kill Credit
(22053, 1.5), -- Mosswood the Ancient
(22055, 26.0), -- Coilfang Elite
(22056, 1250.0), -- Coilfang Strider
(22058, 1.448), -- Heart of Fury Visual Trigger
(22060, 2.0), -- Fenissa the Assassin
(22062, 4.0), -- Dr. Whitherlimb
(22064, 3.75), -- Stormspire Drake
(22067, 3.0), -- Scryer Dragonhawk
(22074, 3.6), -- Illidari Mind Breaker
(22077, 3.0), -- Aldor Gryphon Guard
(22085, 3.0), -- Sporeggar Sporebat
(22089, 3.0), -- Toshley Flying Machine
(22091, 1.0), -- Spitfire Totem
(22096, 1.448), -- Shadowlord Deathwail Visual Trigger
(22108, 0.5), -- Blackwhelp
(22112, 18.75), -- Karynaku
(22119, 52.0), -- Fathom Lurker
(22120, 13.0), -- Fathom Sporebat
(22122, 3.0), -- Cenarion Storm Crow
(22130, 0.5), -- Baron Sablemane's Blackwhelp
(22135, 1.104), -- Tame Clefthoof
(22136, 1.104), -- Dubu
(22140, 2.6), -- Toxic Sporebat
(22141, 1.104), -- Quilbeast
(22142, 1.104), -- Zakk
(22145, 1.625), -- Barrier Hills Felboar [PH] not used
(22162, 4.0), -- Blackfang Tarantula (1)
(22163, 4.0), -- Darkwater Crocolisk (1)
(22164, 5.72), -- Infinite Assassin (1)
(22165, 5.72), -- Infinite Chronomancer (1)
(22166, 11.44), -- Infinite Executioner (1)
(22167, 115.0), -- Infinite Timereaver (1)
(22168, 11.44), -- Infinite Vanquisher (1)
(22169, 1.3), -- Infinite Whelp (1)
(22170, 45.759998), -- Rift Keeper (1)
(22171, 45.759998), -- Rift Keeper (1)
(22172, 20.799999), -- Rift Lord (1)
(22173, 4.0), -- Sable Jaguar (1)
(22180, 1.25), -- Shard-Hide Boar
(22190, 3.75), -- Black Blade Drake [PH]
(22192, 3.75), -- Giant Black Blade Drake [PH]
(22195, 0.9), -- Wrath Speaker
(22196, 10.4), -- Wrath Reaver
(22201, 0.9), -- Fear Whisperer
(22202, 0.75), -- Nightmare Imp
(22203, 1.82), -- Infernal
(22204, 1.25), -- Fear Fiend
(22207, 1000.0), -- Toxic Spores
(22215, 1.5), -- Treebole
(22216, 46.75), -- Fhyn Leafshadow
(22218, 0.36), -- Insidious Familiar
(22219, 0.45), -- Felstorm Motivator
(22220, 0.54), -- Legion War-Hound
(22221, 1.1), -- Felstorm Overseer
(22225, 1.104), -- Reagan Mancuso
(22227, 1.104), -- Markus Scylan
(22229, 1.03), -- Druman Shadowgrove
(22230, 1.448), -- Shadowmoon Fel Orc Attack Trigger
(22233, 1.5), -- Unsuspecting Leafbeard
(22234, 1.03), -- Sinnea Starsong
(22236, 1.0), -- Water Elemental Totem
(22237, 1.0815), -- Loirea Galerunner
(22238, 13.0), -- Serpentshrine Tidecaller
(22250, 1000.0), -- Rancid Mushroom
(22253, 19.5), -- Dragonmaw Ascendant
(22258, 2.5), -- Demoniac Scryer
(22259, 0.54), -- Hellfire Wardling
(22275, 30.0), -- Apexis Guardian
(22276, 8.75), -- Terror Steed [PH]
(22278, 2.104), -- High Priest Orglum
(22279, 1.62), -- Nadja
(22280, 1.62), -- Soren
(22281, 26.0), -- Galvanoth
(22283, 10.4), -- Eredar Stormbringer
(22285, 0.011), -- Draenei Tomb Guardian
(22289, 1.3), -- Darkflame Infernal
(22291, 1.1), -- Furnace Guard
(22293, 1.3), -- Inactive Fel Reaver
(22295, 14.3), -- Deathforge Automaton
(22297, 14.3), -- Throne-Guard Highlord
(22299, 1.11432), -- Spore Strider
(22300, 4.0), -- Spore Strider (1)
(22301, 13.75), -- Throne-Guard Sentinel
(22302, 14.3), -- Throne-Guard Champion
(22303, 11.25), -- Throne Hound
(22304, 1.25), -- Mo'arg Extractor
(22307, 1.5), -- Rotting Forest-Rager
(22315, 0.075), -- Deathforge Mine
(22316, 1.25), -- Enslaved Netherwing Drake Kill Credit
(22320, 1.448), -- Kil'Jaeden Target
(22325, 3.9), -- Nightmare Weaver
(22327, 1.1), -- Terror-Fire Guardian
(22332, 5.0), -- Brood of Neltharaku
(22338, 13.0), -- Arcubus Destroyer
(22344, 1.5), -- Morcrush Shardling
(22345, 6.6), -- Twilight Ridge Drakonid [PH]
(22346, 8.0), -- Ethereum Life-Binder (1)
(22347, 26.0), -- Colossus Lurker
(22348, 1.448), -- Western Gehenna Teleporter Credit
(22350, 1.448), -- Central Gehenna Teleporter Credit
(22351, 1.448), -- Eastern Gehenna Teleporter Credit
(22352, 13.0), -- Colossus Rager
(22355, 0.25), -- Netherweb Victim
(22357, 32.5), -- Reth'hedron the Subduer
(22358, 1.448), -- Nether Gas Visual Trigger
(22360, 18.75), -- Karynaku Taxi
(22362, 0.315), -- Deathshadow Imp
(22364, 1.104), -- Scout Navrin
(22374, 15.0), -- Hand of Kargath
(22379, 0.13), -- Serpentshrine Parasite
(22381, 1.08), -- Hathyss the Wicked
(22385, 5.2), -- Terrordar the Tormentor
(22389, 14.3), -- Kil'Jaeden Reaver (non-interactable)
(22390, 1.5), -- Mountain Shardling
(22391, 1.5), -- Vortex Shardling
(22392, 1.25), -- Wrath Fiend
(22394, 0.55), -- Deathshadow Hound
(22400, 1.448), -- Twilight Ridge Target
(22420, 1.05), -- Lakotae
(22436, 1.448), -- Blade's Legion Target
(22455, 46.75), -- Sky-Master Maxxor
(22458, 6.0), -- Chief Archaeologist Letoll
(22461, 0.8), -- Fel Cannon MKI
(22464, 6.0), -- Explorers' League Researcher
(22465, 1.1), -- Natasha
(22468, 1.352), -- Ogrin
(22474, 0.063), -- Unstable Fel-Imp
(22475, 0.9), -- Unstable Fel-Imp Transform
(22478, 2.25), -- Evergrove Ancient
(22480, 0.24), -- Brown Marmot
(22485, 28.125), -- Halu
(22486, 1.0), -- Greater Earthbind Totem
(22487, 1.0), -- Greater Resistance Totem
(22490, 11.0), -- Huffer
(22496, 19.5), -- Sabellian
(22499, 0.625), -- Lesser Wrath Hound
(22500, 0.625), -- Void Hound
(22501, 1.25), -- Void Hound Transform
(22502, 1.448), -- Death's Door Warp-Gate Explosion Bunny
(22509, 7.8), -- Scrapped Fel Reaver Transform
(22515, 1000.0), -- World Trigger
(22517, 1000.0), -- World Trigger (Large AOI)
(22519, 1000.0), -- Karazhan Chess - Karazhan Invisible Stalker
(22520, 1000.0), -- Karazhan Chess - Chess Piece: Status Bar
(22521, 1000.0), -- Karazhan Chess - Karazhan - Chess, Medivh CHEAT: Fury of Medivh Visual (DND)
(22523, 1000.0), -- Karazhan Chess - Karazhan - Chess, Victory Dummy Tool
(22524, 1000.0), -- Karazhan Chess - Karazhan - Chess, Victory Controller
(22527, 35.5), -- Arch Druid Renferal
(22528, 5.9), -- Athramanis
(22533, 1.2), -- Champion Guardsman
(22538, 1.2), -- Champion Legionnaire
(22541, 12.0), -- Druid of the Grove
(22542, 60.0), -- Dun Baldar North Marshal
(22544, 60.0), -- Dun Baldar South Marshal
(22548, 60.0), -- East Frostwolf Warmaster
(22549, 20.0), -- Frostwolf Herald
(22551, 22.0), -- Frostwolf Stable Master
(22552, 23.5), -- Frostwolf Wolf Rider Commander
(22553, 1.6875), -- Furis (1)
(22555, 2.0), -- Grimtooth
(22556, 35.799999), -- Guse's War Rider
(22558, 10.5), -- Horde Spirit Guide (1)
(22560, 60.0), -- Iceblood Warmaster
(22561, 60.0), -- Icewing Marshal
(22563, 35.799999), -- Ichman's Gryphon
(22564, 35.799999), -- Jeztor's War Rider
(22566, 35.799999), -- Mulverick's War Rider
(22567, 28.0), -- Murgot Deepforge
(22568, 35.5), -- Primalist Thurloga
(22569, 1.48), -- Ravak Grimtotem
(22570, 35.799999), -- Slidore's Gryphon
(22571, 29.25), -- Smith Regzar
(22572, 60.0), -- Stonehearth Marshal
(22574, 20.0), -- Stormpike Herald
(22575, 23.5), -- Stormpike Ram Rider Commander
(22577, 22.0), -- Stormpike Stable Master
(22580, 60.0), -- Tower Point Warmaster
(22587, 5.25), -- Veteran Commando
(22588, 0.85), -- Veteran Defender
(22589, 0.85), -- Veteran Guardian
(22590, 3.885), -- Veteran Outrunner (1)
(22592, 5.25), -- Veteran Reaver
(22593, 35.799999), -- Vipore's Gryphon
(22596, 60.0), -- West Frostwolf Warmaster
(22597, 56.200001), -- Wing Commander Ichman
(22598, 56.200001), -- Wing Commander Mulverick
(22604, 12.0), -- Alterac Yeti
(22605, 140.0), -- Captain Balinda Stonehearth
(22606, 140.0), -- Captain Galvangar
(22607, 5.75), -- Champion Commando
(22608, 1.0), -- Champion Defender
(22609, 1.0), -- Champion Guardian
(22610, 3.885), -- Champion Outrunner (1)
(22612, 5.75), -- Champion Reaver
(22613, 9.5), -- Commander Dardosh
(22614, 5.6), -- Commander Duffy
(22615, 9.5), -- Commander Karl Philips
(22616, 9.5), -- Commander Louis Philips
(22617, 5.6), -- Commander Malgor
(22618, 8.0), -- Commander Mortimer
(22619, 5.6), -- Commander Mulfort
(22620, 9.5), -- Commander Randolph
(22621, 15.5), -- Field Marshal Teravaine
(22622, 9.0), -- Frostwolf Battleguard
(22626, 12.0), -- Ice Giant (1)
(22627, 319.0), -- Ivus the Forest Lord
(22629, 319.0), -- Lokholar the Ice Lord
(22630, 5.85), -- Prospector Stonehewer
(22633, 9.0), -- Stormpike Battleguard
(22638, 2.05), -- Voggah Deathgrip
(22639, 15.5), -- Warmaster Garrick
(22641, 300.0), -- Drek'Thar
(22642, 37.5), -- Fjordune the Greater (1)
(22643, 12.0), -- Korrak the Bloodrager
(22644, 300.0), -- Vanndar Stormpike
(22645, 1.25), -- Alliance Sentinel
(22646, 7.35), -- Brogus Thunderbrew
(22648, 14.7), -- Frostwolf Quartermaster
(22649, 1.25), -- Frostwolf Warrior
(22650, 14.68), -- Grelkor
(22651, 14.69), -- Jonivera Farmountain
(22652, 14.69), -- Kurdrum Barleybeard
(22653, 29.25), -- Lana Thunderbrew
(22654, 14.6), -- Rarck
(22655, 14.5), -- Shrye Ragefist
(22657, 1.48), -- Stormpike Mountaineer
(22658, 14.7), -- Stormpike Quartermaster
(22659, 29.299999), -- Svalbrad Farmountain
(22660, 22.5), -- Yaelika Farclaw
(22661, 14.6), -- Zora Guthrek
(22662, 1.6), -- Seasoned Mountaineer
(22663, 1.4), -- Seasoned Sentinel
(22664, 1.4), -- Seasoned Warrior
(22665, 0.88), -- Frostwolf Legionnaire
(22666, 0.88), -- Stormpike Guardsman
(22667, 1.7), -- Veteran Mountaineer
(22668, 1.6), -- Veteran Sentinel
(22669, 1.6), -- Veteran Warrior

(22670, 2.9), -- Aggi Rumblestomp
(22671, 1.8), -- Champion Mountaineer
(22672, 1.7), -- Champion Sentinel
(22673, 1.7), -- Champion Warrior
(22674, 0.6), -- Frostwolf Guardian
(22675, 3.885), -- Frostwolf Outrunner (1)
(22676, 4.25), -- Frostwolf Reaver
(22678, 12.0), -- Frostwolf Shaman
(22679, 6.5), -- Frostwolf Wolf Rider
(22683, 2.9), -- Keetar
(22684, 2.9), -- Masha Swiftcut
(22685, 2.43), -- Morloch
(22687, 1.0), -- Seasoned Guardsman
(22688, 1.0), -- Seasoned Legionnaire
(22689, 4.25), -- Stormpike Commando
(22690, 0.6), -- Stormpike Defender
(22691, 6.5), -- Stormpike Ram Rider
(22694, 2.43), -- Taskmaster Snivvle
(22696, 2.9), -- Umi Thorson
(22697, 56.200001), -- Wing Commander Jeztor
(22698, 56.200001), -- Wing Commander Slidore
(22699, 7.07), -- Dirk Swindle
(22708, 5.9), -- Lieutenant Spencer
(22710, 5.9), -- Lieutenant Stronghoof
(22712, 5.88), -- Najak Hexxen
(22713, 4.75), -- Seasoned Commando
(22714, 0.75), -- Seasoned Defender
(22715, 0.75), -- Seasoned Guardian
(22716, 3.885), -- Seasoned Outrunner (1)
(22718, 4.75), -- Seasoned Reaver
(22719, 1.1), -- Veteran Guardsman
(22720, 1.1), -- Veteran Legionnaire
(22721, 56.200001), -- Wing Commander Guse
(22722, 56.200001), -- Wing Commander Vipore
(22723, 5.6), -- Jotek
(22724, 5.6), -- Mountaineer Boombellow
(22729, 1.45), -- Coldmine Explorer
(22730, 1.75), -- Coldmine Guard
(22731, 1.75), -- Coldmine Invader
(22732, 1.0), -- Coldmine Miner
(22733, 1.0), -- Coldmine Peon
(22734, 1.45), -- Coldmine Surveyor
(22735, 4.45), -- Corporal Noreg Stormpike
(22737, 1.3), -- Frostwolf
(22738, 0.8), -- Frostwolf Bloodhound
(22739, 1.3), -- Frostwolf Bowman
(22741, 1.45), -- Irondeep Explorer
(22743, 1.75), -- Irondeep Guard
(22744, 1.0), -- Irondeep Miner
(22745, 1.0), -- Irondeep Peon
(22746, 1.75), -- Irondeep Raider
(22747, 1.45), -- Irondeep Shaman
(22748, 1.75), -- Irondeep Skullthumper
(22749, 1.45), -- Irondeep Surveyor
(22750, 1.0), -- Irondeep Trogg
(22760, 12.0), -- Sergeant Yazra Bloodsnarl
(22761, 7.66), -- Snowblind Ambusher
(22762, 7.6), -- Snowblind Harpy
(22763, 7.8), -- Snowblind Windcaller
(22764, 2.66), -- Stabled Alterac Ram
(22766, 1.3), -- Stormpike Bowman
(22767, 0.8), -- Stormpike Owl
(22778, 1.0), -- Whitewhisker Digger
(22779, 1.45), -- Whitewhisker Geomancer
(22780, 1.75), -- Whitewhisker Overseer
(22782, 1.5), -- Whitewhisker Vermin
(22783, 8.1), -- Wildpaw Alpha
(22784, 4.65), -- Wildpaw Brute
(22785, 4.38), -- Wildpaw Gnoll
(22786, 7.86), -- Wildpaw Mystic
(22787, 4.4), -- Wildpaw Shaman
(22810, 1.05), -- Rescued Cenarion Expedition Druid
(22820, 6.5), -- Seer Olum
(22825, 10.8), -- Matron Li-sahar
(22827, 7.2), -- Gorgolon the All-seeing
(22828, 15.6), -- Trelopades
(22844, 16.9), -- Ashtongue Battlelord
(22845, 16.9), -- Ashtongue Mystic
(22846, 16.9), -- Ashtongue Stormcaller
(22847, 16.9), -- Ashtongue Primalist
(22848, 8.45), -- Storm Fury
(22849, 7.605), -- Ashtongue Feral Spirit
(22852, 44.0), -- [UNUSED] Dread Lord
(22853, 18.59), -- Illidari Defiler
(22854, 36.0), -- [UNUSED] Illidari Felstalker
(22855, 74.360001), -- Illidari Nightlord
(22857, 3.3), -- Illidari Ravager
(22858, 1.1), -- Shadowhoof Assassin
(22859, 1.1), -- Shadowhoof Summoner
(22860, 0.9), -- Illidari Succubus
(22869, 18.59), -- Illidari Boneslicer
(22873, 33.799999), -- Coilskar General
(22874, 16.9), -- Coilskar Harpooner
(22875, 16.9), -- Coilskar Sea-Caller
(22876, 16.9), -- Coilskar Sewer Beast
(22877, 16.9), -- Coilskar Wrangler
(22878, 67.599998), -- Aqueous Lord
(22879, 16.9), -- Shadowmoon Reaver
(22880, 16.9), -- Shadowmoon Champion
(22881, 16.9), -- Aqueous Surger
(22882, 16.9), -- Shadowmoon Deathshaper
(22883, 8.45), -- Filth
(22884, 67.599998), -- Leviathan
(22885, 18.59), -- Dragon Turtle
(22886, 8.45), -- Black Temple Captive
(22896, 1.0), -- Ashtongue Searing Totem
(22904, 0.9), -- Eye of Illidan
(22927, 0.823701), -- Ethereum Prisoner (Dungeon Energy Ball)
(22930, 57.5), -- Yor
(22936, 2.5), -- Auhula
(22937, 7.5), -- Noorab
(22939, 8.45), -- Temple Concubine
(22944, 1.625), -- [UNUSED] Illidari Hound [PH]
(22945, 16.9), -- Shadowmoon Blood Mage
(22946, 16.9), -- Shadowmoon War Hound
(22950, 211.25), -- High Nethermancer Zerevor
(22951, 211.25), -- Lady Malande
(22952, 211.25), -- Veras Darkshadow
(22953, 33.799999), -- Wrathbone Flayer
(22954, 84.5), -- Illidari Fearbringer
(22955, 8.45), -- Charming Courtesan
(22956, 15.21), -- Sister of Pain
(22957, 30.42), -- Priestess of Dementia
(22959, 16.9), -- Spellbound Attendant
(22960, 16.9), -- Dragonmaw Wyrmcaller
(22962, 30.42), -- Priestess of Delight
(22963, 8.45), -- Bonechewer Worker
(22964, 15.21), -- Sister of Pleasure
(22965, 16.9), -- Enslaved Servant
(22968, 0.75), -- Light-Armored Elekk
(22981, 1.05), -- Watcher Elaira
(22984, 1000.0), -- Black Temple Trigger
(22988, 11.0), -- Illidari Shadowlord
(22991, 1.448), -- Monstrous Kaliri Egg Trigger
(22996, 1000.0), -- Warglaive of Azzinoth
(22997, 109.849998), -- Flame of Azzinoth
(23009, 1.08), -- Bessbi Jinglepocket
(23010, 1.08), -- Wolgren Jinglepocket
(23011, 1.08), -- Morshelz Copperpinch
(23012, 1.08), -- Hotoppik Copperpinch
(23018, 16.9), -- Shadowmoon Houndmaster
(23028, 16.9), -- Bonechewer Taskmaster
(23029, 6.0), -- Talonsworn Forest-Rager
(23030, 16.9), -- Dragonmaw Sky Stalker
(23035, 57.5), -- Anzu
(23044, 2.08), -- Karabor Infernal
(23047, 16.9), -- Shadowmoon Soldier
(23049, 67.599998), -- Shadowmoon Weapon Master
(23055, 16.5), -- Felguard Degrader
(23059, 1.104), -- Flame dummy
(23060, 0.5), -- Netherwing Whelp
(23061, 32.5), -- Rivendark
(23062, 1.3), -- Obsidian Consort
(23064, 1.08), -- Eebee Jinglepocket
(23065, 1.08), -- Olnayvi Copperpinch
(23069, 1000.0), -- Demon Fire
(23070, 1000.0), -- Eye Beam
(23075, 1.69), -- Legion Ring Infernal
(23078, 2.025), -- Fel Imp Defender
(23084, 1000.0), -- Black Temple Invis Stalker
(23085, 1000.0), -- Supremus Volcano
(23089, 67.599998), -- Akama
(23095, 1000.0), -- Supremus Stalker
(23102, 1.448), -- Terokkar Trigger
(23105, 0.324), -- Fel Imp Minion Transform
(23109, 100.0), -- Vengeful Spirit
(23111, 1000.0), -- Shadowy Construct
(23113, 31.25), -- Doomguard Punisher
(23123, 1000.0), -- Doom Blossom
(23132, 1.33852), -- Brood of Anzu
(23134, 1.33852), -- Hawk Spirit
(23135, 1.33852), -- Falcon Spirit
(23136, 1.33852), -- Eagle Spirit
(23137, 1.17), -- Fel Gorehound Transform
(23147, 8.45), -- Shadowmoon Grunt
(23152, 22.0), -- Vagath
(23157, 16.9), -- Aluyen
(23158, 16.9), -- Seer Kanai
(23159, 16.9), -- Okuno
(23164, 6.5), -- Toranaku
(23165, 15.0), -- Karrog
(23169, 0.9), -- Nethermine Flayer
(23172, 67.599998), -- Hand of Gorefiend
(23173, 1.215), -- Felhound Defender
(23175, 3.77), -- Tarren Mill Guardsman
(23179, 3.77), -- Tarren Mill Protector
(23182, 5.0895), -- Tarren Mill Guardsman (1)
(23186, 5.0895), -- Tarren Mill Protector (1)
(23187, 1.25), -- Enslaved Netherwing Drake
(23191, 67.599998), -- Akama
(23192, 1.1), -- Ember of Azzinoth
(23196, 67.599998), -- Bonechewer Behemoth
(23197, 67.599998), -- Maiev Shadowsong
(23205, 1.5), -- Karrog Shardling
(23210, 1000.0), -- Akama Follow Dummy
(23212, 16.25), -- Mo'arg Tormenter
(23214, 1.25), -- Mo'arg Tormenter Transform
(23215, 16.9), -- Ashtongue Sorcerer
(23216, 16.9), -- Ashtongue Defender
(23220, 81.0), -- Shivan Assassin
(23222, 33.799999), -- Bonechewer Brawler
(23223, 8.45), -- Bonechewer Spectator
(23226, 43.939999), -- Shadowmoon Warlord
(23227, 0.9), -- Eye of Shartuul Transform
(23230, 1300.0), -- Shartuul
(23232, 16.9), -- Mutant War Hound
(23235, 16.9), -- Bonechewer Blade Fury
(23236, 16.9), -- Bonechewer Shield Disciple
(23237, 16.9), -- Bonechewer Blood Prophet
(23239, 33.799999), -- Bonechewer Combatant
(23254, 1000.0), -- Gurtogg Bloodboil
(23261, 32.5), -- Furywing
(23263, 2.1), -- Brendan Turner
(23264, 0.9), -- Overmine Flayer
(23267, 4.5), -- Arvoar the Rapacious
(23269, 3.6), -- Barash the Den Mother
(23273, 1.104), -- Arcanist Raestan
(23275, 225.0), -- Dreadmaw
(23276, 1.25), -- [PH]Wrath Hound Transform
(23281, 32.5), -- Insidion
(23282, 32.5), -- Obsidia
(23283, 26.0), -- Lady Sinestra
(23288, 1000.0), -- Containment Beacon
(23292, 1000.0), -- Cage Trap Beam Trigger
(23304, 1000.0), -- Maiev Cage Trap Trigger
(23310, 5.0625), -- Fel Portal Alarm
(23318, 16.9), -- Ashtongue Rogue
(23319, 16.9), -- Ashtongue Broken
(23320, 0.5), -- Netherwing Ally
(23329, 1.5), -- Fel Eye Stalk
(23330, 33.799999), -- Dragonmaw Drake
(23336, 109.849998), -- Betrayer's Spire Guard
(23337, 37.18), -- Illidari Centurion
(23339, 18.59), -- Illidari Heartseeker
(23353, 25.0), -- Braxxus
(23354, 25.0), -- Mo'arg Incinerator
(23355, 25.0), -- Zarcsin
(23364, 0.5), -- Black Dragon Whelpling
(23369, 1000.0), -- Whirling Blade
(23374, 16.9), -- Ashtongue Stalker
(23375, 19.773001), -- Shadow Demon
(23381, 16.9), -- Tydormu
(23394, 74.360001), -- Promenade Sentinel
(23397, 16.9), -- Illidari Blood Lord
(23398, 8.45), -- Angered Soul Fragment
(23399, 16.9), -- Suffering Soul Fragment
(23400, 16.9), -- Illidari Archon
(23401, 16.9), -- Hungering Soul Fragment
(23402, 16.9), -- Illidari Battle-mage
(23403, 16.9), -- Illidari Assassin
(23404, 0.63), -- Imp Retainer
(23405, 1.05), -- Flaskataur
(23410, 16.9), -- Spirit of Udalo
(23411, 16.9), -- Spirit of Olum
(23412, 1000.0), -- Illidan Door Trigger
(23413, 3.75), -- Skyguard Handler Irena
(23415, 3.75), -- Skyguard Handler Deesak
(23418, 281.665985), -- Essence of Suffering
(23419, 281.665985), -- Essence of Desire
(23420, 281.665985), -- Essence of Anger
(23421, 46.944), -- Ashtongue Channeler
(23426, 1000.0), -- The Illidari Council
(23427, 1.3), -- Illidari Lord Balthas
(23437, 16.9), -- Indormi
(23448, 1000.0), -- Glaive Target
(23451, 211.25), -- Veras Darkshadow
(23461, 1.25), -- Suraku
(23462, 1.25), -- Jorus
(23463, 1.25), -- Onyxien
(23464, 1.25), -- Malfas
(23465, 1.25), -- Zoya
(23466, 1.25), -- Voranaku
(23468, 18.75), -- Yarzill Dragon Form
(23469, 3.38), -- Enslaved Soul
(23474, 81.0), -- Shivan Assassin (Red)
(23475, 81.0), -- Shivan Assassin (Blue)
(23476, 81.0), -- Shivan Assassin (Black)
(23481, 1.072), -- Keiran Donoghue
(23496, 1.448), -- Akama Event Trigger
(23498, 4.394), -- Parasitic Shadowfiend
(23499, 1000.0), -- Blood Elf Council Voice Trigger
(23520, 1.05), -- Jimmy Two-Canoes
(23521, 1.072), -- Anne Summers
(23522, 1.072), -- Arlen Lochlan
(23523, 16.9), -- Ashtongue Elementalist
(23524, 16.9), -- Ashtongue Spiritbinder
(23526, 31.25), -- BurkeTest01
(23528, 1.1), -- Azuremyst Pink Elekk
(23531, 1.1), -- Eversong Pink Elekk
(23533, 1.072), -- T'chali's Voodoo Brewery Apprentice
(23538, 1.3), -- Northrend Red Dragon
(23539, 1.25), -- Northrend Red Drake
(23542, 13.0), -- Amani'shi Axe Thrower
(23545, 4.0), -- Pumpkin Fiend
(23556, 1.25), -- Vrykul Proto-dragon Mount
(23562, 45.0), -- Shade of Naxxramas
(23563, 109.849998), -- Reanimated Lich
(23575, 6.25), -- Mindless Abomination
(23580, 26.0), -- Amani'shi Warbringer
(23581, 13.0), -- Amani'shi Medicine Man
(23582, 13.0), -- Amani'shi Tribesman
(23584, 26.0), -- Amani War Bear
(23586, 6.5), -- Amani'shi Scout
(23587, 6.5), -- Amani'shi Reinforcement
(23596, 13.0), -- Amani'shi Flame Caster
(23597, 13.0), -- Amani'shi Guardian
(23598, 6.5), -- Amani Dragonhawk Hatchling
(23603, 1.072), -- Uta Roughdough
(23604, 1.1256), -- Agnes Farwithers
(23608, 1.05), -- [PH] Brewfest Tauren Reveler
(23628, 1.072), -- Daran Thunderbrew
(23643, 0.9), -- Unstable Mur'ghoul
(23644, 0.9), -- Mur'ghoul Flesheater
(23645, 0.9), -- Mur'ghoul Corrupter
(23678, 3.0), -- Chill Nymph
(23680, 1.25), -- Plagued Proto-Dragon
(23682, 40.0), -- Headless Horseman
(23683, 1.072), -- Maeve Barleybrew
(23684, 1.072), -- Ita Thunderbrew
(23685, 1.072), -- Gordok Brew Barker
(23686, 1.04167), -- Flame Bunny
(23688, 1.25), -- Proto-Whelp
(23689, 1.25), -- Proto-Drake
(23694, 2.0), -- Pulsing Pumpkin
(23696, 1.072), -- Gordok Brew Chief
(23698, 1.072), -- Drunken Brewfest Reveler
(23700, 3.0), -- Barleybrew Festive Keg
(23702, 3.0), -- Thunderbrew Festive Keg
(23706, 3.0), -- Gordok Festive Keg
(23707, 0.9), -- Grimbooze's Alarm System
(23725, 4.5), -- Stone Giant
(23726, 4.5), -- Stone Lord
(23736, 22.5), -- Pricilla Winterwind
(23757, 1.0), -- Amani Healing Ward
(23774, 13.0), -- Amani'shi Trainer
(23775, 40.0), -- Head of the Horseman
(23787, 0.875), -- Mister Manny
(23790, 4.0), -- Tanzar
(23795, 4.0), -- Dark Iron Antagonist
(23800, 35.0), -- Headless Horseman, Unhorsed
(23816, 22.5), -- Bat Handler Camille
(23817, 6.5), -- Dragonhawk Egg
(23818, 6.5), -- Amani'shi Hatcher
(23830, 1.25), -- [DNT] L70ETC FX Controller
(23834, 6.5), -- Amani Dragonhawk
(23845, 1.0), -- [DNT] L70ETC Bergrisst Controller
(23850, 1.0), -- [DNT] L70ETC Concert Controller
(23852, 1.0), -- [DNT] L70ETC Mai'Kyl Controller
(23853, 1.0), -- [DNT] L70ETC Samuro Controller
(23854, 1.0), -- [DNT] L70ETC Sig Controller
(23855, 1.0), -- [DNT] L70ETC Chief Thunder-Skins Controller
(23859, 22.5), -- Greer Orehammer
(23870, 6.0), -- Ember Clutch Ancient
(23872, 80.0), -- Coren Direbrew
(23876, 1.5), -- Spore
(23877, 162.5), -- Amani Lynx Spirit
(23878, 162.5), -- Amani Bear Spirit
(23879, 162.5), -- Amani Dragonhawk Spirit
(23880, 162.5), -- Amani Eagle Spirit
(23882, 0.375), -- Tamed Proto-Whelp
(23889, 6.5), -- Amani'shi Savage
(23897, 6.5), -- Zungam
(23930, 1.485), -- Trained Plaguehound
(23935, 1.1), -- Val'kyr Watcher
(23939, 1.485), -- Fiend
(23943, 1.1), -- Hungry Plaguehound
(23953, 25.0), -- Prince Keleseth
(23954, 18.75), -- Ingvar the Plunderer
(23956, 6.25), -- Dragonflayer Strategist
(23960, 6.25), -- Dragonflayer Runecaster
(23961, 6.25), -- Dragonflayer Ironhelm
(23965, 3.125), -- Frost Tomb
(23970, 3.125), -- Risen Vrykul Skeleton
(23980, 18.75), -- Ingvar the Plunderer
(23992, 1.25), -- Putrid Wight
(23996, 1000.0), -- Ingvar's Dummy
(23997, 18.75), -- Ingvar's Axe
(23999, 4.0), -- Harkor
(24001, 4.0), -- Ashli
(24019, 3.75), -- Glacion
(24020, 1.25), -- Riding Horse (Gjalerbron Felsteed) (scale x2)
(24024, 4.0), -- Kraz
(24027, 3.75), -- Sergeant Gorth
(24032, 22.5), -- Celea Frozenmane
(24035, 1.05), -- Gjalerbron Prisoner
(24043, 6.5), -- Amani Lynx
(24059, 13.0), -- Amani'shi Beast Tamer
(24061, 22.5), -- James Ormsby
(24064, 6.5), -- Amani Lynx Cub
(24065, 13.0), -- Amani'shi Handler
(24067, 1.3125), -- Mahana Frosthoof
(24068, 18.75), -- Annhylde the Caller
(24069, 6.25), -- Dragonflayer Bonecrusher
(24071, 6.25), -- Dragonflayer Heartsplitter
(24072, 1.25), -- Proto-Drake Broodmother
(24073, 1.25), -- Fearsome Horror
(24078, 6.25), -- Dragonflayer Metalworker
(24079, 6.25), -- Dragonflayer Forge Master
(24080, 6.25), -- Dragonflayer Weaponsmith
(24082, 6.25), -- Proto-Drake Handler
(24083, 12.5), -- Enslaved Proto-Drake
(24084, 3.125), -- Tunneling Ghoul
(24085, 6.25), -- Dragonflayer Overseer
(24105, 10.0), -- Proto-Drake Skyguard
(24108, 1.072), -- Self-Turning and Oscillating Utility Target
(24118, 1.1), -- Val'kyr Observer
(24138, 13.0), -- Tamed Amani Crocolisk
(24143, 325.0), -- Spirit of the Lynx
(24155, 22.5), -- Tobias Sarkhoff
(24156, 1.1), -- Plaguehound Tracker
(24159, 6.5), -- Amani Eagle
(24160, 1.25), -- Plagued Proto-Whelp
(24175, 6.5), -- Amani'shi Lookout
(24179, 13.0), -- Amani'shi Wind Walker
(24180, 13.0), -- Amani'shi Protector
(24200, 12.5), -- Skarvald the Constructor
(24201, 12.5), -- Dalronn the Controller
(24217, 26.0), -- Amani War Bear
(24222, 1.104), -- Windy Cloud
(24224, 1.0), -- Lightning Capacitor Totem
(24225, 13.0), -- Amani'shi Warrior
(24236, 1.05), -- Wind Tamer
(24237, 1.25), -- Vrykul Proto-dragon Mount (White)
(24240, 52.0), -- Alyson Antille
(24241, 52.0), -- Thurg
(24242, 52.0), -- Slither
(24243, 57.200001), -- Lord Raadan
(24244, 46.799999), -- Gazakroth
(24245, 52.0), -- Fenstalker
(24246, 52.0), -- Darkheart
(24247, 65.0), -- Koragg
(24258, 1.1), -- Val'kyr Overseer
(24271, 1.25), -- Iron Rune Golem
(24272, 1.1), -- Val'kyr Watcher
(24310, 1.05), -- [PH] Gossip NPC Tauren Female, Halloween
(24311, 1.05), -- [PH] Gossip NPC Tauren Male, Halloween
(24312, 6.5), -- Dragonhawk Egg
(24316, 1.25), -- Iron Rune Sentinel
(24327, 1.1), -- Val'kyr Soulclaimer
(24329, 4.5), -- Runed Stone Giant
(24345, 4.5), -- Captive Stone Giant
(24346, 2.25), -- Enthralled Stone Giant
(24358, 6.5), -- Harrison Jones
(24371, 4.5), -- Megalith
(24372, 3.0), -- Drohn's Distillery Festive Keg
(24373, 3.0), -- T'chali's Voodoo Brew Festive Keg
(24374, 52.0), -- Amani'shi Berserker
(24381, 4.5), -- Image of Megalith
(24385, 4.5), -- Image of Stone Giant
(24387, 1.25), -- Iron Rune Servant
(24396, 6.5), -- Forest Frog
(24397, 0.84525), -- Mannuth
(24441, 6.5), -- Ashli's Corpse
(24442, 6.5), -- Tanzar's Corpse
(24443, 6.5), -- Harkor's Corpse
(24444, 6.5), -- Kraz's Corpse
(24447, 56.25), -- Frostwyrm (Dragonblight)
(24462, 0.93), -- Racing Ram
(24485, 0.9), -- Servitor Shade
(24492, 1.072), -- Drohn's Distillery Barker
(24493, 1.072), -- T'chali's Voodoo Brewery Barker
(24498, 1.072), -- Cort Gorestein
(24499, 1.072), -- Ja'ron
(24501, 1.072), -- Drohn's Distillery Apprentice
(24530, 13.0), -- Amani Elder Lynx
(24545, 1.09), -- Thunderbrew "Apprentice"
(24546, 0.9), -- Rotgill
(24549, 26.0), -- Amani'shi Tempest
(24552, 8.45), -- Sliver
(24553, 16.25), -- Apoko
(24554, 16.25), -- Eramas Brightblaze
(24555, 17.875), -- Garaxxas
(24556, 16.25), -- Zelfan
(24557, 16.25), -- Kagani Nightstrike
(24558, 16.25), -- Ellrys Duskhallow
(24559, 16.25), -- Warlord Salaris
(24560, 9.2), -- Priestess Delrissa
(24561, 16.25), -- Yazzai
(24562, 0.9), -- Nerub'ar Invader
(24563, 0.9), -- Nerub'ar Venomspitter
(24566, 0.9), -- Nerub'ar Skitterer
(24656, 6.09375), -- Fizzle
(24663, 1.5), -- Tidelord
(24664, 71.875), -- Kael'thas Sunstrider
(24666, 1000.0), -- Kael'thas Sunstrider
(24667, 2.1), -- Sergeant Thunderhorn
(24674, 13.0), -- Phoenix
(24675, 13.0), -- Phoenix Egg
(24683, 6.5), -- Sunblade Mage Guard
(24684, 6.5), -- Sunblade Blood Knight
(24685, 6.5), -- Sunblade Magister
(24686, 6.5), -- Sunblade Warlock
(24687, 6.5), -- Sunblade Physician
(24688, 6.5), -- Wretched Skulker
(24689, 6.5), -- Wretched Bruiser
(24690, 6.5), -- Wretched Husk
(24696, 6.5), -- Coilskar Witch
(24697, 5.85), -- Sister of Torment
(24698, 6.5), -- Ethereum Smuggler
(24699, 3.3), -- [UNUSED] Sargeron Trickster

(24708, 1000.0), -- Arcane Sphere
(24715, 6.09375), -- Definitely NOT a Remote-Controlled High Explosive Sheep
(24721, 32.5), -- Flying Blue Drake
(24722, 5.0), -- Fel Crystal
(24723, 71.875), -- Selin Fireheart
(24744, 50.599998), -- Vexallus
(24745, 1.3), -- Pure Energy
(24761, 1.3), -- Brightscale Wyrm
(24762, 6.5), -- Sunblade Keeper
(24769, 1.3), -- Red Dragon Soldier
(24770, 8.125), -- Nexus Watcher
(24775, 0.5), -- Coldarra Red Whelp
(24777, 13.0), -- Sunblade Sentinel
(24789, 0.9), -- Forlorn Soul
(24795, 46.799999), -- Surristrasz
(24798, 0.9), -- Grell (Pink)
(24799, 0.9), -- Grell (Blue)
(24800, 0.9), -- Grell (Blanca)
(24801, 0.9), -- Grell (Red)
(24802, 0.9), -- Grell (Orange)
(24803, 0.9), -- Grell (White)
(24808, 13.0), -- Broken Sentinel
(24809, 6.5), -- Nether Energy Cube
(24812, 22.5), -- Storm Giant
(24813, 3.75), -- Exarch Larethor
(24815, 0.975), -- Sunblade Imp
(24822, 1.3), -- Tyrith
(24830, 2.0), -- Stonevault Pillager
(24844, 1.69), -- Kalecgos
(24849, 6.25), -- Proto-Drake Rider
(24850, 1098.5), -- Kalecgos
(24851, 46.75), -- Kiz Coilspanner
(24858, 2.0), -- Soaring Eagle
(24864, 1000.0), -- Dragonflayer Worker
(24871, 1.25), -- Risen Vrykul Ancestor
(24872, 0.9), -- Blood Shade
(24875, 1.1), -- Windan of the Kvaldir
(24878, 0.9), -- Rig Sentry
(24880, 1.3), -- Korf
(24895, 2197.0), -- Madrigosa
(24905, 1.152), -- Leassian
(24914, 15.0), -- Sorlof
(24933, 1.25), -- Suspended Terrorguard
(24938, 3.75), -- Shattered Sun Marksman
(24960, 3.75), -- Wretched Devourer
(24965, 3.75), -- Vindicator Xayann
(24966, 3.75), -- Wretched Fiend
(24967, 3.75), -- Captain Theris Dawnhearth
(24972, 4.125), -- Erratic Sentry
(24974, 1.152), -- Liza Cutlerflix
(24975, 3.75), -- Mar'nah
(24976, 3.75), -- Dawnblade Blood Knight
(24978, 3.75), -- Dawnblade Summoner
(24979, 3.75), -- Dawnblade Marksman
(24980, 5.0625), -- Crystal Ward
(24981, 1.65), -- Converted Sentry
(24982, 0.735), -- Mrs. Flaskataur
(24991, 1.62), -- Converted Sentry Credit
(24994, 96.667999), -- Shattered Sun Sentry
(24999, 3.375), -- Irespeaker
(25000, 1.25), -- Abyss Creature
(25001, 4.6875), -- Abyssal Flamewalker
(25002, 4.6875), -- Unleashed Hellion
(25003, 4.5), -- Emissary of Hate
(25004, 1.25), -- Emissary of Despair
(25005, 1.25), -- Emissary of Dread
(25008, 1.25), -- Abyssal Flamewalker (Display)
(25027, 3.75), -- Frenzied Ghoul
(25028, 3.75), -- Skeletal Ravager
(25030, 12.5), -- Wrath Enforcer
(25031, 26.0), -- Pit Overlord
(25032, 3.75), -- Eldara Dawnrunner
(25033, 12.5), -- Eredar Sorcerer
(25034, 3.75), -- Tradesman Portanuus
(25035, 3.75), -- Tyrael Flamekissed
(25036, 3.75), -- Caregiver Inaara
(25037, 3.75), -- Seraphina Bloodheart
(25039, 3.75), -- Kaalif
(25040, 60.0), -- Greater Water Elemental
(25043, 3.75), -- Sereth Duskbringer
(25045, 3.75), -- Sentinel
(25046, 3.75), -- Smith Hauthaa
(25049, 3.75), -- Dawnstar Charger
(25057, 3.75), -- Battlemage Arynna
(25059, 37.5), -- Ayren Cloudbreaker
(25060, 3.75), -- Darkspine Myrmidon
(25061, 41.25), -- Harbinger Inuuro
(25063, 3.75), -- Dawnblade Hawkrider
(25069, 3.75), -- Magister Ilastar
(25073, 3.75), -- Darkspine Siren
(25084, 1.06), -- Greengill Slave
(25087, 3.75), -- Dawnblade Reservist
(25088, 3.75), -- Captain Valindria
(25090, 5.0625), -- Sin'Loren Credit
(25091, 5.0625), -- Bloodoath Credit
(25092, 5.0625), -- Dawnchaser Credit
(25108, 41.25), -- Vindicator Kaalan
(25112, 3.75), -- Anchorite Ayuri
(25114, 3.75), -- Hauthaa's Anvil Bunny
(25115, 5.625), -- Shattered Sun Warrior
(25132, 3.75), -- Sunblade Lookout
(25133, 3.75), -- Astromancer Darnarian
(25144, 3.75), -- Shattered Sun Bombardier
(25154, 3.88), -- Sunwell - Quest Bunny - Shrine
(25156, 3.88), -- Sunwell - Quest Bunny - Portal
(25157, 3.88), -- Sunwell - Quest Bunny - Sunwell
(25158, 1098.5), -- Brutallus
(25160, 1098.5), -- Madrigosa
(25162, 13.125), -- Drill Sergeant Bahduum
(25163, 3.75), -- Anchorite Kairthos
(25164, 3.75), -- Shattered Sun Recruit
(25166, 1098.5), -- Grand Warlock Alythess
(25169, 3.0), -- Archmage Ne'thul
(25170, 3.75), -- Shattered Sun Archmage
(25174, 3.0), -- K'iru
(25175, 11.25), -- Shattered Sun Dragonhawk
(25182, 1.25), -- Corlok's Enslaved Netherwing Drake
(25192, 3.75), -- Bridge Marksman Target Bunny
(25213, 1000.0), -- Karazhan Chess - Chest Bunny
(25214, 1.30375), -- Shadow Image
(25225, 9.0), -- Practice Dummy
(25236, 7.5), -- Unrestrained Dragonhawk
(25242, 42.5), -- Warsong Battleguard
(25253, 42.5), -- Valiance Keep Footman
(25268, 10.985), -- Unyielding Dead
(25288, 22.5), -- Turida Coldwind
(25296, 0.75), -- Nerub'ar Larva
(25313, 0.666667), -- Valiance Keep Footman
(25332, 1.25), -- Stitched Warsong Horror
(25334, 6.0), -- Horde Siege Tank
(25355, 1.1), -- Beryl Hound
(25357, 1000.0), -- Felmyst Flight Target - Left
(25358, 1000.0), -- Felmyst Flight Target - Right
(25363, 21.969999), -- Sunblade Cabalist
(25364, 1.25), -- Red Guardian Drake
(25367, 21.969999), -- Sunblade Arch Mage
(25368, 21.969999), -- Sunblade Slayer
(25369, 21.969999), -- Sunblade Vindicator
(25370, 21.969999), -- Sunblade Dusk Priest
(25371, 21.969999), -- Sunblade Dawn Priest
(25372, 10.985), -- Sunblade Scout
(25373, 10.985), -- Shadowsword Soulbinder
(25375, 0.5), -- Giant Scarab
(25383, 1.25), -- En'kilah Abomination
(25389, 0.04), -- En'kilah Hatchling (2)
(25401, 0.75), -- Seaforium Depth Charge
(25445, 0.9), -- Nerub'ar Corpse Harvester
(25448, 1.25), -- Curator Insivius
(25451, 0.675), -- Nerub'ar Sky Darkener
(25452, 1.3), -- Scourged Mammoth
(25453, 9.0), -- Ith'rix the Harvester
(25483, 21.969999), -- Shadowsword Manafiend
(25484, 21.969999), -- Shadowsword Assassin
(25485, 43.939999), -- Shadowsword Deathbringer
(25486, 21.969999), -- Shadowsword Vanquisher
(25502, 14.2805), -- Shield Orb
(25506, 21.969999), -- Shadowsword Lifeshaper
(25507, 96.667999), -- Sunwell Protector
(25508, 228.488007), -- Shadowsword Guardian
(25509, 39.546001), -- Priestess of Torment
(25535, 1.49333), -- [DNT] Torch Tossing Target Bunny
(25536, 1.49333), -- [DNT] Torch Tossing Target Bunny Controller
(25553, 0.27), -- Fizzle (1)
(25555, 5.775), -- Garaxxas (1)
(25561, 3.3), -- [UNUSED] Sargeron Trickster (1)
(25563, 3.6), -- Sister of Torment (1)
(25566, 0.675), -- Sunblade Imp (1)
(25582, 0.9), -- Scourged Flamespitter
(25583, 0.15), -- Warsong Land Mine
(25588, 185.645996), -- Apolyon
(25591, 54.924999), -- Painbringer
(25592, 109.849998), -- Doomfire Destroyer
(25593, 54.924999), -- Apocalypse Guard
(25595, 87.879997), -- Chaos Gazer
(25597, 57.122002), -- Oblivion Mage
(25598, 0.1638), -- Wild Volatile Imp
(25599, 109.849998), -- Cataclysm Hound
(25600, 1.1), -- Unliving Swine
(25608, 1000.0), -- The Sunwell
(25611, 1.25), -- Warsong Aberration
(25622, 0.9), -- Nerub'ar Tunneler
(25625, 1.25), -- Warsong Aberration
(25632, 21.969999), -- Vindicator Moorba
(25638, 21.969999), -- Captain Selana
(25639, 21.969999), -- Anchorite Elbadon
(25640, 1000.0), -- Dragon Orb Target
(25644, 21.969999), -- Neophyte Narama
(25652, 0.5), -- Nerub'ar Scarab
(25653, 125.0), -- Essence of the Blue Flight
(25655, 4.375), -- Bane
(25661, 10.985), -- Shattered Sun Soldier
(25684, 1.25), -- Talramas Abomination
(25695, 1.5625), -- Red Drake (Speed Mount)
(25697, 1.05), -- Luma Skymother
(25703, 1000.0), -- Brutallus Death Cloud
(25707, 1.5), -- Magic-bound Ancient
(25709, 1.5), -- Glacial Ancient
(25710, 1.05), -- Numa Cloudsister
(25711, 0.75), -- Spirit of the North
(25712, 1.3), -- Warbringer Goredrak
(25713, 1.1), -- Blue Drakonid Supplicant
(25716, 1.25), -- General Cerulean
(25718, 0.55), -- Coldarra Mage Slayer
(25721, 0.75), -- Arcane Serpent
(25722, 1.1), -- Coldarra Spellweaver
(25723, 13.0), -- [ph] Coldarra Blue Dragon Patroller
(25740, 80.0), -- Ahune
(25741, 2197.0), -- M'uru
(25743, 1.33333), -- Wooly Mammoth Bull
(25744, 5.712), -- Dark Fiend
(25753, 0.9), -- Sentry-bot 57-K
(25755, 18.799999), -- Ahunite Hailstone
(25756, 3.538), -- Ahunite Coldwave
(25770, 1000.0), -- Void Portal
(25772, 114.244003), -- Void Sentinel
(25777, 1.26), -- Refugee Father
(25795, 1000.0), -- Normal Realm
(25796, 1000.0), -- Sathrovarr the Corruptor
(25798, 21.969999), -- Shadowsword Berserker
(25799, 21.969999), -- Shadowsword Fury Mage
(25814, 0.9), -- Fizzcrank Mechagnome
(25824, 10.985), -- Void Spawn
(25832, 0.9), -- Max Blasto
(25833, 1.25), -- The Grinder
(25834, 0.9), -- Gearmaster Mechazod
(25837, 1098.5), -- High Commander Arynyes
(25851, 9.8865), -- Volatile Fiend
(25855, 1000.0), -- Singularity
(25860, 57.122002), -- Blazing Infernal
(25864, 24.167), -- Felguard Slayer
(25865, 80.0), -- Frozen Core
(25867, 10.985), -- Sunblade Dragonhawk
(25876, 1.05), -- Midsummer Celebrant Costume: Tauren
(25881, 10.0), -- Moria
(25883, 1.048), -- Ashenvale Flame Warden
(25884, 1.048), -- Ashenvale Flame Keeper
(25887, 1.064), -- Arathi Flame Warden
(25888, 1.01), -- Azuremyst Isle Flame Warden
(25890, 1.072), -- Blasted Lands Flame Warden
(25893, 1.048), -- Darkshore Flame Warden
(25894, 1.064), -- Desolace Flame Warden
(25896, 1.048), -- Duskwood Flame Warden
(25897, 1.088), -- Dustwallow Marsh Flame Warden
(25900, 1.104), -- Hellfire Peninsula Flame Warden
(25908, 1.064), -- The Hinterlands Flame Warden
(25911, 1.048), -- Wetlands Flame Warden
(25923, 1.064), -- Arathi Flame Keeper
(25927, 1.072), -- Burning Steppes Flame Keeper
(25931, 1.01), -- Eversong Woods Flame Keeper
(25932, 1.05), -- Feralas Flame Keeper
(25933, 1.03), -- Ghostlands Flame Keeper
(25934, 1.104), -- Hellfire Peninsula Flame Keeper
(25935, 1.064), -- Hillsbrad Flame Keeper
(25938, 1.06), -- Shadowmoon Valley Flame Keeper
(25940, 1.1004), -- Stonetalon Flame Keeper
(25943, 1.048), -- The Barrens Flame Keeper
(25945, 1.1172), -- Thousand Needles Flame Keeper
(25948, 10.985), -- Doomfire Shard
(25950, 3.75), -- Shaani
(25953, 1000.0), -- Fel Crystal Spell Target
(25954, 16.9), -- Shadowsword Guardian Sunwell
(25955, 16.25), -- Hand of the Deceiver Sunwell
(25956, 1.3), -- Chaos Gazer Sunwell
(25957, 1.625), -- Cataclysm Hound Sunwell
(25958, 1.17), -- Volatile Felfire Fiend Sunwell
(25959, 1.625), -- Apocalypse Guard Sunwell
(25960, 1428.050049), -- M'uru Sunwell
(25975, 1.04167), -- Master Fire Eater
(25976, 3.75), -- Theremis
(25977, 3.75), -- Yrma
(26046, 1098.5), -- Anveena
(26088, 1.5625), -- Red Drake Courier
(26089, 3.75), -- ONLY GM CAN SEE ME - I'AM NOT SPAWNED BECAUSE I FRICK PVP PROGRESSION - Kayri
(26090, 4.6875), -- ONLY GM CAN SEE ME - I'AM NOT SPAWNED BECAUSE I FRICK PVP PROGRESSION - Karynna
(26091, 3.75), -- ONLY GM CAN SEE ME - I'AM NOT SPAWNED BECAUSE I FRICK PVP PROGRESSION - Olus
(26092, 3.75), -- ONLY GM CAN SEE ME - I'AM NOT SPAWNED BECAUSE I FRICK PVP PROGRESSION - Soryn
(26101, 9.8865), -- Volatile Imp
(26113, 1.04167), -- Master Flame Eater
(26184, 1.05), -- Taunka'le Refugee
(26202, 1.25), -- Ziggurat Defender
(26214, 1.32), -- Frigid Lieutenant
(26215, 1.5), -- Glacial Lieutenant
(26216, 1.5625), -- Glacial Templar
(26225, 0.9), -- Phylactery Guardian
(26231, 1.261), -- Saragosa
(26237, 15.6), -- Keristrasza
(26250, 0.975), -- Scourged Burrower
(26253, 37.5), -- Shattered Sun Peacekeeper
(26254, 1000.0), -- Inert Portal
(26259, 10.985), -- Shattered Sun Soldier
(26260, 4.5), -- Kurun
(26261, 4.5), -- Grizzly Hills Giant
(26262, 1000.0), -- The Core of Entropius
(26263, 1.625), -- Red Dragon Mount
(26274, 1.5), -- [PH] Dragonblight Ancient
(26275, 1.3), -- [PH] Dragonblight Black Dragon
(26276, 7.8), -- Nexus Guardian
(26277, 5.525), -- Bronze Shrine Warden
(26278, 1.3), -- [PH] Dragonblight Green Dragon
(26279, 1.3), -- Dragonblight Red Dragon
(26281, 1.1), -- Moonrest Stalker
(26284, 1.25), -- Runic Battle Golem
(26286, 12.5), -- Emberwyrm
(26287, 12.5), -- Icestorm
(26289, 10.985), -- Shattered Sun Riftwaker
(26290, 15.0), -- Jotun
(26291, 4.5), -- Crystalline Ice Giant
(26294, 1.25), -- [PH] Dragonblight Magma Wyrm
(26307, 1.04167), -- Beastmaster
(26321, 5.25), -- Lothalor Ancient
(26322, 0.75), -- Arcane Wyrm
(26323, 1.3125), -- Goblin Pack Kodo
(26333, 4.5), -- Corrupted Lothalor Ancient
(26338, 160.0), -- Ahune (1)
(26339, 160.0), -- Frozen Core (1)
(26347, 1.25), -- Runic War Golem
(26355, 0.93), -- [DND] Midsummer Bonfire Faction Bunny - H
(26396, 2.1), -- Sergeant Thunderhorn
(26402, 0.9), -- Anub'ar Ambusher
(26406, 6.25), -- The Anvil
(26417, 4.5), -- Runed Giant
(26420, 4.5), -- Gavrock
(26457, 1.1), -- Diseased Drakkari
(26458, 3.75), -- Drakkari Plaguebringer
(26473, 3.0), -- Ko'char the Unbreakable
(26475, 12.5), -- Magmawyrm
(26497, 12.5), -- Lady Jaina Proudmoore
(26499, 12.5), -- Arthas
(26509, 1.25), -- Lucid Test Subject
(26518, 1.25), -- Carrion Abomination
(26527, 25.0), -- Chromie
(26528, 12.5), -- Uther the Lightbringer
(26533, 37.5), -- Mal'Ganis
(26536, 3.125), -- Mindless Servant
(26550, 6.25), -- Dragonflayer Deathseeker
(26553, 6.25), -- Dragonflayer Fanatic
(26554, 6.25), -- Dragonflayer Seer
(26555, 12.5), -- Scourge Hulk
(26560, 84.375), -- Ohura
(26566, 22.5), -- Narzun Skybreaker
(26579, 13.0), -- Anveena Replica
(26601, 42.5), -- Fizzcrank Airman
(26602, 3.0), -- Kara Thricestar
(26603, 42.5), -- Kor'kron Windrager
(26607, 0.9), -- Anub'ar Blightbeast
(26620, 6.25), -- Drakkari Guardian
(26621, 6.25), -- Ghoul Tormentor
(26622, 6.25), -- Drakkari Bat
(26623, 6.25), -- Scourge Brute
(26624, 12.5), -- Wretched Belcher
(26625, 6.25), -- Darkweb Recluse
(26626, 6.25), -- Scourge Reanimator
(26627, 6.25), -- Crystal Handler
(26628, 6.25), -- Drakkari Scytheclaw
(26630, 25.0), -- Trollgore
(26631, 12.5), -- Novos the Summoner
(26632, 37.5), -- The Prophet Tharon'ja
(26635, 6.25), -- Risen Drakkari Warrior
(26636, 6.25), -- Risen Drakkari Soulmage
(26637, 6.25), -- Risen Drakkari Handler
(26638, 6.25), -- Risen Drakkari Bat Rider
(26639, 6.25), -- Drakkari Shaman
(26641, 6.25), -- Drakkari Gutripper
(26667, 6.25), -- Dragonflayer Spectator
(26669, 6.25), -- Ymirjar Savage
(26670, 6.25), -- Ymirjar Flesh Hunter
(26672, 6.25), -- Bloodthirsty Tundra Wolf
(26674, 3.125), -- Darkweb Hatchling
(26675, 1000.0), -- Spider Summon Target
(26676, 0.315), -- Anub'ar Invader
(26683, 12.5), -- Frenzied Worgen
(26684, 12.5), -- Ravenous Furbolg
(26685, 12.5), -- Massive Jormungar
(26686, 12.5), -- Ferocious Rhino
(26687, 25.0), -- Gortok Palehoof
(26690, 3.125), -- Ymirjar Warrior
(26691, 3.125), -- Ymirjar Witch Doctor
(26692, 3.125), -- Ymirjar Harpooner
(26693, 25.0), -- Skadi the Ruthless
(26694, 6.25), -- Ymirjar Dusk Shaman
(26696, 6.25), -- Ymirjar Berserker
(26712, 1000.0), -- Crystal Channel Target
(26716, 12.5), -- Azure Warder
(26719, 2.0), -- Brewfest Spy
(26722, 12.5), -- Azure Magus
(26723, 37.5), -- Keristrasza
(26724, 1.04167), -- [DND] TAR Pedestal - Armor, Cloth & Leather
(26727, 6.25), -- Mage Hunter Ascendant
(26728, 6.25), -- Mage Hunter Initiate
(26729, 6.25), -- Steward
(26730, 6.25), -- Mage Slayer
(26731, 25.0), -- Grand Magus Telestra
(26734, 6.25), -- Azure Enforcer
(26735, 6.25), -- Azure Scale-Binder
(26736, 12.5), -- Azure Skyrazor
(26737, 6.25), -- Crazed Mana-Surge
(26738, 1.04167), -- [DND] TAR Pedestal - Accessories
(26739, 1.04167), -- [DND] TAR Pedestal - Enchantments
(26740, 1.04167), -- [DND] TAR Pedestal - Gems
(26741, 1.04167), -- [DND] TAR Pedestal - General Goods
(26742, 1.04167), -- [DND] TAR Pedestal - Armor, Mail & Plate
(26743, 1.04167), -- [DND] TAR Pedestal - Glyph, Cloth & Leather
(26744, 1.04167), -- [DND] TAR Pedestal - Glyph, Mail & Plate
(26745, 1.04167), -- [DND] TAR Pedestal - Weapons
(26746, 3.125), -- Crazed Mana-Wraith
(26747, 1.04167), -- [DND] TAR Pedestal - Arena Organizer
(26748, 1.04167), -- [DND] TAR Pedestal - Beastmaster
(26749, 1.04167), -- [DND] TAR Pedestal - Paymaster
(26751, 1.04167), -- [DND] TAR Pedestal - Trainer, Druid
(26752, 1.04167), -- [DND] TAR Pedestal - Trainer, Hunter
(26753, 1.04167), -- [DND] TAR Pedestal - Trainer, Mage
(26754, 1.04167), -- [DND] TAR Pedestal - Trainer, Paladin
(26755, 1.04167), -- [DND] TAR Pedestal - Trainer, Priest
(26756, 1.04167), -- [DND] TAR Pedestal - Trainer, Rogue
(26757, 1.04167), -- [DND] TAR Pedestal - Trainer, Shaman
(26758, 1.04167), -- [DND] TAR Pedestal - Trainer, Warlock
(26759, 1.04167), -- [DND] TAR Pedestal - Trainer, Warrior
(26761, 6.25), -- Crazed Mana-Wyrm
(26763, 25.0), -- Anomalus
(26764, 8.0), -- Ilsa Direbrew
(26765, 1.04167), -- [DND] TAR Pedestal - Fight Promoter
(26776, 4.0), -- Direbrew Minion
(26782, 6.25), -- Crystalline Keeper
(26783, 4.5), -- Freed Giant
(26792, 12.5), -- Crystalline Protector
(26793, 3.125), -- Crystalline Frayer
(26794, 25.0), -- Ormorok the Tree-Shaper
(26799, 6.25), -- Warsong Berserker
(26800, 6.25), -- Valiance Berserker
(26801, 6.25), -- Warsong Ranger
(26802, 6.25), -- Valiance Ranger
(26803, 6.25), -- Warsong Cleric
(26805, 6.25), -- Valiance Cleric
(26809, 1.5), -- Ravaged Crystalline Ice Giant
(26822, 8.0), -- Ursula Direbrew
(26829, 1000.0), -- Trophy Orb
(26830, 12.5), -- Risen Drakkari Death Knight
(26840, 12.5), -- [PH] Dragonblight Named Frost Wyrm Horde
(26841, 3.125), -- Reanimated Frost Wyrm
(26842, 22.5), -- Windrider groluka
(26844, 22.5), -- Lilleth Radescu
(26845, 22.5), -- Junter Weiss
(26846, 22.5), -- Kareg
(26847, 22.5), -- Omu Spiritbreeze
(26848, 22.5), -- Kimbiza
(26850, 22.5), -- Numo Spiritbreeze
(26851, 37.400002), -- Nethestrasz
(26852, 22.5), -- Kragh
(26853, 23.625), -- Makki Wintergale
(26858, 31.25), -- Sarathstra
(26861, 37.5), -- King Ymiron
(26872, 1.8), -- Weakened Giant
(26876, 22.5), -- Samuel Clearbook
(26877, 22.5), -- Derek Rammel
(26878, 22.5), -- Rodney Wells
(26879, 22.5), -- Tomas Riverwell
(26880, 22.5), -- Vana Grey
(26881, 22.5), -- Palena Silvercloud
(26897, 0.9), -- Gnome, Clockwork (Northrend)
(26918, 6.25), -- Chaotic Rift
(26919, 5.0), -- Drak'aguul
(26925, 3.75), -- Wyrmrest Temple Drake
(26928, 25.0), -- Grand Magus Telestra
(26929, 25.0), -- Grand Magus Telestra
(26930, 25.0), -- Grand Magus Telestra
(26933, 7.8), -- Wyrmrest Guardian
(26946, 1.1), -- Reanimated Drakkari Tribesman
(26948, 1.25), -- Hulking Atrocity
(26949, 13.0), -- Torastrasza
(26966, 0.9), -- Shadowy Tormentor
(27035, 42.5), -- Venomspite Deathguard
(27036, 44.0), -- Dreadlord - Metamorphosis (Warlock)
(27046, 37.400002), -- Warmage Adami
(27048, 1000.0), -- Keristrasza - Breath Dummy - Telestra
(27073, 42.5), -- Bor'gorok Battleguard
(27105, 19.5), -- Kreug Oathbreaker
(27228, 3.125), -- Jormungar Worm
(27262, 1.05), -- Windseer Grayhorn
(27270, 12.0), -- Rotting Storm Giant
(27273, 1000.0), -- Flame Brazier
(27281, 3.125), -- Ritual Channeler
(27285, 10.0), -- Reconstructed Frost Wyrm
(27287, 1.25), -- Mindless Wight
(27292, 6.25), -- Flamebringer
(27303, 1000.0), -- King Bjorn Dummy
(27304, 1000.0), -- King Bjorn
(27307, 1000.0), -- King Haldor Dummy
(27308, 1000.0), -- King Ranulf Dummy
(27309, 1000.0), -- King Tor Dummy
(27310, 1000.0), -- King Haldor
(27311, 1000.0), -- King Ranulf
(27312, 1000.0), -- King Tor
(27313, 1.5), -- Ice Giant, Northrend
(27327, 1000.0), -- Ritual Target
(27335, 0.9), -- Hungering Dead
(27339, 1000.0), -- Bjorn's Blade
(27344, 22.5), -- Bat Handler Adeline
(27363, 0.9), -- Smoldering Geist
(27370, 0.9), -- Vengeful Geist
(27374, 1.1), -- Unholy Archon

(27386, 3.125), -- Avenging Spirit
(27389, 12.5), -- Dalronn the Controller
(27390, 12.5), -- Skarvald the Constructor
(27431, 12.5), -- Drakkari Commander
(27435, 0.75), -- Wintergarde Mine Bomb
(27483, 25.0), -- King Dred
(27490, 1000.0), -- Cosmetic Drakkari Bat
(27513, 0.9), -- Covetous Geist
(27530, 13.0), -- Ruby Keeper
(27531, 6.25), -- Frigid Abomination Attacker
(27533, 0.9), -- Frigid Geist
(27542, 6.25), -- Ruby Watcher
(27551, 0.9), -- Enraged Apparition
(27574, 1.25), -- War Kodo
(27597, 1.25), -- Hulking Corpse
(27598, 0.3125), -- Fetid Troll Corpse
(27600, 0.625), -- Risen Pyromancer
(27605, 93.75), -- Colossal Abomination
(27608, 11.7), -- Azure Dragon
(27611, 6.25), -- Plague Eruptor
(27629, 39.0), -- Wyrmrest Defender
(27633, 6.25), -- Azure Inquisitor
(27635, 6.25), -- Azure Spellbinder
(27636, 3.125), -- Azure Ley-Whelp
(27638, 12.5), -- Azure Ring Guardian
(27639, 6.25), -- Ring-Lord Sorceress
(27640, 6.25), -- Ring-Lord Conjurer
(27641, 12.5), -- Centrifuge Construct
(27642, 6.25), -- Phantasmal Mammoth
(27644, 6.25), -- Phantasmal Wolf
(27645, 6.25), -- Phantasmal Cloudscraper
(27647, 6.25), -- Phantasmal Ogre
(27648, 6.25), -- Phantasmal Naga
(27649, 6.25), -- Phantasmal Murloc
(27650, 6.25), -- Phantasmal Air
(27651, 6.25), -- Phantasmal Fire
(27653, 6.25), -- Phantasmal Water
(27656, 37.5), -- Ley-Guardian Eregos
(27657, 6.25), -- Verdisa
(27658, 6.25), -- Belgaristrasz
(27659, 6.25), -- Eternos
(27667, 1.04167), -- Anwehu
(27668, 1.05), -- Ontok Shatterhorn
(27686, 0.9), -- Frigid Geist Attacker
(27692, 1000.0), -- Emerald Skytalon
(27693, 56.25), -- Reconstructed Wyrm
(27694, 14.0), -- Haunting Spirit
(27696, 37.5), -- The Prophet Tharon'ja
(27704, 1.328), -- Horace Alder
(27709, 0.3125), -- Drakkari Invader
(27729, 6.25), -- Enraging Ghoul
(27731, 3.125), -- Acolyte
(27733, 6.25), -- Ghoul Minion
(27734, 6.25), -- Crypt Fiend
(27736, 12.5), -- Patchwork Construct
(27737, 0.3125), -- Risen Zombie
(27742, 6.25), -- Infinite Adversary
(27743, 6.25), -- Infinite Hunter
(27744, 6.25), -- Infinite Agent
(27745, 3.125), -- Lordaeron Footman
(27746, 3.125), -- Lordaeron Knight
(27747, 3.125), -- High Elf Mage-Priest
(27752, 3.125), -- High Elf Sorceress
(27754, 3.125), -- Invading Drakkari Bat
(27755, 1000.0), -- Amber Skytalon
(27756, 1000.0), -- Ruby Skytalon
(27788, 1.0), -- Injured 7th Legion Soldier
(27797, 1.25), -- Tattered Abomination
(27801, 15.0), -- Avatar of Freya
(27808, 3.75), -- Turgid the Vile
(27809, 1.25), -- Weakened Turgid the Vile
(27810, 1.072), -- Brew Vendor
(27811, 1.072), -- Brew Vendor
(27812, 1.072), -- Brew Vendor
(27814, 1.072), -- Brew Vendor
(27818, 1.072), -- Brew Vendor
(27819, 1.072), -- Brew Vendor
(27820, 1.072), -- Brew Vendor
(27821, 1.25), -- Weakened Reanimated Frost Wyrm
(27824, 0.9), -- Naxxramas Shade
(27825, 0.9), -- Mausoleum Scourge Proxy
(27834, 0.25), -- Shadowfiend Guardian
(27837, 1000.0), -- Nexus 70 - Buying Time Bunny
(27842, 2.5), -- Fenrick Barlowe
(27854, 1.25), -- Plague Zombie Vehicle - TEST
(27877, 3.125), -- Sergeant Morigan
(27886, 1.1), -- Valgarde Gryphon
(27896, 0.88), -- Infinite Assailant
(27897, 1.0), -- Infinite Destroyer
(27898, 0.88), -- Infinite Chrono-Magus
(27900, 3.75), -- Infinite Timerender
(27909, 6.25), -- Darkweb Victim
(27913, 3.125), -- Lordaeron Crier
(27935, 1.1), -- Ferithos
(27936, 0.25), -- Pumpkin Soldier
(27941, 1.25), -- Drakkari Plague Spreader
(27947, 25.0), -- Warsong Commander Kolurg
(27949, 25.0), -- Valiance Commander Stoutbeared
(27952, 1.1), -- Wyrmrest Protector Visual (Red)
(27953, 5.5), -- Wyrmrest Protector
(27954, 1.1), -- Wyrmrest Protector Visual (Green)
(27957, 0.9), -- Angrathar Geist
(27960, 6.25), -- Dark Rune Warrior
(27961, 6.25), -- Dark Rune Worker
(27962, 6.25), -- Dark Rune Elementalist
(27963, 6.25), -- Dark Rune Theurgist
(27964, 6.25), -- Dark Rune Scholar
(27965, 6.25), -- Dark Rune Shaper
(27966, 6.25), -- Dark Rune Controller
(27969, 25.0), -- Dark Rune Giant
(27970, 12.5), -- Raging Construct
(27971, 12.5), -- Unrelenting Construct
(27972, 12.5), -- Lightning Construct
(27973, 3.125), -- Crystalline Shardling
(27974, 1.5), -- Eroded Shardling
(27975, 25.0), -- Maiden of Grief
(27977, 25.0), -- Krystallus
(27978, 37.5), -- Sjonnir The Ironshaper
(27979, 0.3125), -- Forged Iron Trogg
(27980, 0.3125), -- Earthen Dwarf
(27981, 0.3125), -- Malformed Ooze
(27982, 0.3125), -- Forged Iron Dwarf
(27983, 3.125), -- Dark Rune Protector
(27984, 3.125), -- Dark Rune Stormcaller
(27985, 6.25), -- Iron Golem Custodian
(27996, 4.55), -- Wyrmrest Vanquisher
(28007, 12.5), -- Antiok's Mount
(28012, 6.25), -- Image of Belgaristrasz
(28018, 9.0), -- Thiassi the Lightning Bringer
(28023, 1.25), -- Rotting Abomination
(28026, 0.9), -- Rampaging Geist
(28037, 37.400002), -- The Spirit of Gnomeregan
(28049, 1.05), -- First Mate Hapana
(28052, 1.104), -- Dread Crew
(28058, 0.824), -- Dread Cannon
(28060, 1.376), -- Nyuni
(28069, 1.25), -- Sholazar Guardian
(28101, 1.25), -- Blighted Corpse
(28149, 6.25), -- Earthen Protector
(28153, 3.125), -- Snowflake
(28159, 2.5), -- Scourgeheart Drakkari
(28165, 6.25), -- Iron Sludge
(28166, 1000.0), -- Containment Sphere
(28167, 0.3125), -- Stratholme Citizen
(28168, 24.0), -- Guerrero (1)
(28169, 0.3125), -- Stratholme Resident
(28170, 0.9), -- Frosthowl Screecher
(28171, 80.0), -- Don Carlos (1)
(28189, 30.0), -- Prince Valanar
(28195, 37.400002), -- Bilko Driftspark
(28196, 37.400002), -- Cid Flounderfix
(28197, 37.400002), -- Kip Trawlskip
(28199, 6.25), -- Tomb Stalker
(28200, 6.25), -- Dark Necromancer
(28201, 12.5), -- Bile Golem
(28207, 6.25), -- Cerberon
(28211, 6.25), -- Glonn
(28222, 22.5), -- The Etymidian
(28231, 6.25), -- Crystalline Tender
(28234, 1000.0), -- Tribunal of the Ages
(28235, 1000.0), -- Dark Matter
(28236, 12.5), -- Azure Ring Captain
(28243, 75.0), -- Thrym
(28249, 6.25), -- Devouring Ghoul
(28250, 1.1), -- Wyrmrest Protector Visual (Black)
(28251, 1.1), -- Wyrmrest Protector Visual (Blue)
(28252, 1.3), -- Wyrmrest Protector Visual (Nether)
(28258, 0.9), -- Hath'ar Skimmer
(28270, 1.25), -- Jintha'kalar Scourge (PROXY DO NOT SPAWN)
(28271, 1.25), -- Glacial Breach Scourge Credit
(28276, 6.25), -- Greater Ley-Whelp
(28278, 0.9), -- Ravenous Plaguehound
(28340, 0.3125), -- Stratholme Citizen
(28341, 0.3125), -- Stratholme Resident
(28351, 1000.0), -- Flame Breath Trigger Left (Skadi)
(28368, 6.25), -- Ymirjar Necromancer
(28369, 0.9), -- Burning Skimmer
(28378, 1.25), -- Primordial Drake
(28389, 1.25), -- Primordial Hatchling
(28410, 6.25), -- Dragonflayer Spiritualist
(28419, 3.125), -- Frenzied Geist
(28446, 11.0), -- Fury
(28450, 11.0), -- Unbound Charger
(28467, 3.75), -- Broodmother Slivina
(28487, 11.0), -- Val'kyr Battle-maiden
(28512, 1.25), -- Quartermaster Ozorg
(28519, 1.1), -- Withered Troll
(28534, 11.0), -- Val'kyr Battle-maiden
(28535, 0.75), -- Wants Orange
(28536, 0.75), -- Wants Papaya
(28537, 0.75), -- Wants Banana
(28539, 0.75), -- Steaming Valve
(28540, 0.75), -- Wants Fire
(28547, 6.25), -- Storming Vortex
(28564, 1.25), -- Putrid Abomination
(28574, 37.400002), -- Marvin Wobblesprocket
(28578, 6.25), -- Hardened Steel Reaver
(28579, 6.25), -- Hardened Steel Berserker
(28580, 6.25), -- Hardened Steel Skycaller
(28581, 6.25), -- Stormforged Tactician
(28582, 6.25), -- Stormforged Mender
(28583, 6.25), -- Blistering Steamrager
(28584, 6.25), -- Unbound Firestorm
(28585, 3.125), -- Slag
(28586, 25.0), -- General Bjarngrim
(28587, 25.0), -- Volkhan
(28589, 1.6875), -- Gristlegut
(28597, 3.75), -- Guardian of Zim'Rhuk
(28599, 0.1), -- Plagueroach
(28603, 0.9), -- Blightguard
(28612, 3.125), -- Knight of the Silver Hand
(28613, 20.0), -- Kor'Kron Wolfrider
(28615, 37.400002), -- Baneflight
(28618, 37.400002), -- Danica Saint
(28621, 37.400002), -- Grayson Ironwing
(28623, 37.400002), -- Gurric
(28624, 37.400002), -- Maaka
(28641, 1.25), -- Blighted Corpse
(28650, 1.064), -- Nayura
(28651, 2.5), -- Abominable Messenger
(28656, 1000.0), -- Chromie's Hourglass
(28657, 0.9), -- Caged Geist
(28666, 0.9), -- Gorebag
(28670, 31.25), -- Frostbrood Vanquisher
(28674, 37.400002), -- Aludane Whitecloud
(28681, 1.25), -- Brittle Golem
(28684, 25.0), -- Krik'thir the Gatewatcher
(28695, 12.5), -- Molten Golem
(28711, 0.75), -- Undead Eagle
(28729, 12.5), -- Watcher Narjil
(28730, 12.5), -- Watcher Gashra
(28731, 12.5), -- Watcher Silthik
(28732, 6.25), -- Anub'ar Warrior
(28733, 6.25), -- Anub'ar Shadowcaster
(28734, 6.25), -- Anub'ar Skirmisher
(28735, 0.3125), -- Skittering Swarmer
(28736, 3.125), -- Skittering Infector
(28745, 0.9), -- Alarmed Blightguard
(28748, 1.25), -- Serpent-Touched Berserker
(28750, 0.9), -- Blight Geist
(28756, 1.25), -- High Priest Hawinni
(28760, 0.9), -- Hargus the Gimp
(28769, 0.9), -- Shadowy Tormentor
(28793, 6.25), -- Darmuk
(28802, 1.1), -- Servant of Drakuru
(28803, 1.1), -- Drakuru's Guard
(28805, 5.5), -- Hand of Drakuru
(28823, 1000.0), -- Volkhan's Anvil
(28825, 3.125), -- Cyclone
(28826, 6.25), -- Stormfury Revenant
(28835, 12.5), -- Stormforged Construct
(28836, 6.25), -- Stormforged Runeshaper
(28837, 6.25), -- Stormforged Sentinel
(28838, 12.5), -- Titanium Vanguard
(28840, 6.25), -- Overlook Sentry
(28843, 1.25), -- Bloated Abomination
(28866, 0.9), -- Corrosion
(28868, 0.9), -- Mulch
(28869, 0.9), -- Deathdrip
(28872, 0.9), -- Squirmworm
(28878, 3.125), -- Risen Minion
(28903, 1.125), -- Scourge Plaguehound
(28904, 1.448), -- Mold Rune Trigger
(28905, 0.9), -- Gluttonous Geist
(28920, 25.0), -- Stormforged Giant
(28921, 25.0), -- Hadronox
(28922, 12.5), -- Anub'ar Crusher
(28923, 37.5), -- Loken
(28924, 0.9), -- Anub'ar Champion
(28926, 6.25), -- Spark of Ionar
(28931, 21.970301), -- Blightblood Troll
(28937, 0.9), -- Crypt Guardian
(28943, 0.9), -- Fineous
(28947, 1000.0), -- Ionar Invis Stalker
(28961, 6.25), -- Titanium Siegebreaker
(28965, 6.25), -- Titanium Thunderer
(28987, 8.0), -- Watcher Blomberg
(29013, 1.25), -- Perch Guardian
(29032, 0.0042), -- Malar Bravehorn
(29047, 11.0), -- Olrun the Battlecaller
(29048, 1000.0), -- Ulduar Monitor
(29062, 6.25), -- Anub'ar Champion
(29063, 6.25), -- Anub'ar Crypt Fiend
(29064, 6.25), -- Anub'ar Necromancer
(29093, 1.032), -- Ian Drake
(29096, 3.6), -- Anub'ar Champion
(29111, 22.0), -- Val'kyr Battle-maiden
(29115, 31.25), -- Rampaging Abomination
(29117, 6.25), -- Anub'ar Champion
(29118, 6.25), -- Anub'ar Crypt Fiend
(29119, 6.25), -- Anub'ar Necromancer
(29120, 37.5), -- Anub'arak
(29123, 1.25), -- Monstrous Wight
(29128, 12.5), -- Anub'ar Prime Guard
(29137, 37.400002), -- Sergeant Riannah
(29153, 3.125), -- Animated Bones
(29172, 0.9), -- Frozen Shade
(29186, 31.25), -- Rampaging Abomination
(29187, 31.25), -- Plague Eruptor
(29189, 13.5), -- Howling Geist
(29190, 30.0), -- Flesh Behemoth
(29197, 0.9), -- Frozen Shade, Climax
(29198, 11.0), -- Mograine's Mount
(29201, 11.0), -- Death Knight Mount
(29209, 0.3125), -- Carrion Beetle
(29213, 0.3125), -- Anub'ar Darter
(29214, 0.3125), -- Anub'ar Assassin
(29216, 6.25), -- Anub'ar Guardian
(29229, 75.0), -- Poisonous Skitterer (1)
(29238, 0.9), -- Scourge Haunt
(29240, 6.25), -- Stormforged Lieutenant
(29241, 157.5), -- Carrion Spinner (1)
(29242, 135.0), -- Dread Creeper (1)
(29243, 270.0), -- Venom Stalker (1)
(29247, 1000.0), -- Flesh Giant Parts
(29249, 3610.0), -- Anub'Rekhan (1)
(29256, 190.0), -- Crypt Fiend
(29257, 500.0), -- Omar the Test Dragon Gen2
(29263, 0.9), -- PattyMacks Hovering Dummy
(29266, 25.0), -- Xevozz
(29267, 1000.0), -- Shadow Trap
(29268, 4631.25), -- Grand Widow Faerlina (1)
(29271, 1000.0), -- Ethereal Sphere
(29274, 1000.0), -- Grobbulus
(29276, 1000.0), -- Violet Hold Containment System
(29278, 1000.0), -- Maexxna Roof Clipper
(29279, 1000.0), -- Egg of Maexxna
(29280, 2197.0), -- The Lich King
(29281, 25.0), -- Svala
(29286, 315.0), -- Tomb Horror (1)
(29304, 25.0), -- Slad'ran
(29305, 25.0), -- Moorabi
(29306, 37.5), -- Gal'darah
(29307, 25.0), -- Da Colossus
(29308, 25.0), -- Prince Taldaram
(29309, 25.0), -- Elder Nadox
(29310, 25.0), -- Jedoga Shadowseeker
(29311, 37.5), -- Herald Volazj
(29312, 25.0), -- Lavanthor
(29313, 25.0), -- Ichoron
(29314, 25.0), -- Zuramat the Obliterator
(29315, 12.5), -- Erekem
(29316, 25.0), -- Moragg
(29317, 37.5), -- Cyanigosa (Dragon)
(29321, 1000.0), -- Ichor Globule
(29324, 7474.0), -- Patchwerk (1)
(29326, 1000.0), -- Mythic Accelerator
(29335, 6.25), -- Anub'ar Webspinner
(29340, 0.3125), -- Anub'ar Brood Keeper
(29347, 312.5), -- Patchwork Golem (1)
(29349, 0.090544), -- Anub'ar Darter
(29350, 15.0), -- Torseg the Exiled
(29353, 504.687988), -- Bile Retcher (1)
(29354, 60.0), -- Sewage Slime (1)
(29355, 50.0), -- Embalming Slime (1)
(29356, 546.875), -- Sludge Belcher (1)
(29359, 525.0), -- Living Monstrosity (1)
(29362, 225.0), -- Mad Scientist (1)
(29363, 93.75), -- Surgical Assistant (1)
(29364, 3.125), -- Void Sentry
(29365, 3.125), -- Void Sentry
(29371, 641.25), -- Stitched Giant (1)
(29372, 1.25), -- Twilight Drake
(29373, 4735.75), -- Grobbulus (1)
(29380, 1.1), -- Stormforged War Golem
(29382, 1.1), -- Stormforged Reaver
(29384, 0.9), -- Captive Mechagnome
(29388, 1000.0), -- Naxxramas Multi Task Dummy
(29389, 0.9), -- Mechagnome Laborer
(29395, 6.25), -- Guard Hugin
(29417, 4132.5), -- Gluth (1)
(29425, 1000.0), -- Erekem Controller
(29446, 1000.0), -- Thaddius
(29447, 427.5), -- Feugen (1)
(29448, 14149.299805), -- Thaddius (1)
(29453, 0.75), -- Vargul Plaguetalon
(29460, 1.25), -- Frigid Proto-Drake
(29485, 4.5), -- Dolomite Giant
(29522, 56.25), -- Frost Wyrm Raptor
(29545, 1.25), -- Proto-Drake Corpse
(29561, 2.7), -- Scrapbot
(29570, 1.1), -- Nascent Val'kyr
(29573, 25.0), -- Da Mojo
(29574, 225.0), -- Infectious Ghoul (1)
(29575, 230.0), -- Plague Slime (1)
(29576, 440.0), -- Stoneskin Gargoyle (1)
(29601, 85.0), -- Mutated Grub (1)
(29603, 75.0), -- Plagued Bat (1)
(29608, 80.0), -- Frenzied Bat (1)
(29609, 281.25), -- Plague Beast (1)
(29612, 45.0), -- Diseased Maggot (1)
(29613, 30.0), -- Eye Stalk (1)
(29615, 2922.199951), -- Noth the Plaguebringer (1)
(29620, 28.6), -- Dreadlord Mal'Ganis
(29632, 313.5), -- Plagued Warrior (1)
(29633, 166.725006), -- Plagued Champion (1)
(29634, 313.5), -- Plagued Guardian (1)
(29647, 1.5), -- Gymer
(29654, 1.1), -- Drakuru Blood Drinker
(29656, 1.25), -- Drakuru Berserker
(29680, 3.125), -- Slad'ran Viper
(29681, 37.5), -- Gal'darah
(29682, 1000.0), -- Slad'ran Summon Target
(29684, 1000.0), -- Ticking Bomb
(29697, 1.1), -- Drakuru Prophet
(29701, 3519.75), -- Heigan the Unclean (1)
(29704, 11.25), -- Towering Horror
(29708, 1.25), -- Captive Proto-Drake
(29709, 1.25), -- Freed Proto-Drake
(29713, 0.3125), -- Slad'ran Constrictor
(29718, 5977.399902), -- Loatheb (1)
(29719, 1.25), -- Morbid Carcass
(29720, 0.9), -- Vault Geist
(29721, 37.400002), -- Skizzle Slickslide
(29735, 6.25), -- Savage Worg
(29738, 1.1), -- Death Knight Master
(29741, 25.0), -- Moorabi
(29742, 3.125), -- Snake Wrap
(29748, 1000.0), -- Phantom Mammoth
(29749, 37.400002), -- Morgana Dayblaze
(29750, 37.400002), -- Faldorf Bitterchill
(29753, 1.25), -- Stormpeak Wyrm
(29755, 0.3125), -- Stormpeak Hatchling
(29756, 62.5), -- Veranus
(29757, 37.400002), -- Kabarg Windtamer
(29762, 22.5), -- Hyeyoung Parka
(29768, 6.25), -- Unyielding Constrictor
(29769, 1.25), -- Vile
(29774, 6.25), -- Spitting Cobra
(29775, 0.9), -- Archivist Mechaton
(29806, 2.7), -- SCRAP-E
(29818, 54.924999), -- Deathcharger Steed
(29819, 6.25), -- Drakkari Lancer
(29820, 6.25), -- Drakkari God Hunter
(29822, 6.25), -- Drakkari Fire Weaver
(29823, 225.0), -- Death Knight (1)
(29824, 375.0), -- Death Knight Captain (1)
(29825, 135.0), -- Shade of Naxxramas (1)
(29826, 6.25), -- Drakkari Medicine Man
(29827, 80.0), -- Ghost of Naxxramas (1)
(29828, 150.0), -- Necro Knight (1)
(29829, 12.5), -- Drakkari Earthshaker
(29830, 6.25), -- Living Mojo
(29831, 225.0), -- Risen Squire (1)
(29832, 12.5), -- Drakkari Golem
(29833, 125.0), -- Dark Touched Warrior (1)
(29834, 3.125), -- Drakkari Frenzy
(29835, 200.0), -- Skeletal Archer (1)
(29836, 6.25), -- Drakkari Battle Rider
(29837, 225.0), -- Skeletal Smith (1)
(29838, 12.5), -- Drakkari Rhino
(29840, 0.9), -- The Leaper
(29842, 270.0), -- Death Knight Cavalier (1)
(29852, 148.5), -- Deathcharger Steed (1)
(29853, 148.5), -- Deathcharger Steed (1)
(29856, 1.1), -- Gooey Ghoul Drool
(29858, 150.0), -- Lady Nightswood
(29859, 135.0), -- The Leaper
(29860, 187.5), -- Vile
(29861, 1.1), -- Stormforged Eradicator
(29863, 1.25), -- Persistence
(29872, 16.5), -- Algar the Chosen
(29874, 6.25), -- Drakkari Inciter
(29884, 45.0), -- Gymer
(29894, 0.75), -- Vargul Plaguetalon
(29895, 22.5), -- Thrym
(29896, 22.5), -- Brothers of the Storm
(29898, 315.0), -- Unholy Axe (1)
(29899, 270.0), -- Unholy Staff (1)
(29900, 270.0), -- Unholy Swords (1)
(29901, 125.0), -- Deathchill Servant (1)
(29912, 1000.0), -- Instructor's Obedience Crystal
(29920, 6.25), -- Ruins Dweller
(29931, 12.5), -- Drakkari Rhino
(29932, 25.0), -- Eck the Ferocious
(29940, 5001.75), -- Instructor Razuvious (1)
(29941, 170.0), -- The Unholy Blade
(29949, 1.05), -- Orgrimmar Defender
(29950, 37.400002), -- Breck Rockbrow
(29951, 37.400002), -- Shavalius THE Fancy
(29952, 37.400002), -- [UNUSED] [ph] Ulduar Camp (H) Flight Master
(29955, 2488.050049), -- Gothik the Harvester (1)
(29974, 1.56), -- Niffelem Forefather
(29982, 6.25), -- Drakkari Raider
(29984, 6.0), -- Iron Sentinel
(29985, 35.625), -- Unrelenting Death Knight (1)
(29986, 39.875), -- Unrelenting Rider (1)
(29987, 1000.0), -- Harvester's Way Gate Controller
(29988, 49.875), -- Spectral Rider (1)
(29989, 41.25), -- Spectral Horse (1)
(29990, 35.625), -- Spectral Death Knight (1)
(29991, 7800.0), -- Sapphiron (1)
(30015, 22.0), -- Soldier of the Frozen Wastes (1)
(30016, 22.0), -- Soldier of the Frozen Wastes (1)
(30018, 61.25), -- Soul Weaver (1)
(30047, 61.25), -- Soul Weaver (1)
(30048, 171.875), -- Unstoppable Abomination (1)
(30049, 171.875), -- Unstoppable Abomination (1)
(30055, 1.25), -- Stormpeak Wyrm
(30057, 1098.5), -- The Lich King

(30058, 1.3), -- Warden of the Chamber
(30061, 6350.0), -- Kel'Thuzad (1)
(30063, 6.6), -- Stormforged Decimator
(30068, 0.2), -- Spore (1)
(30071, 109.849998), -- Stitched Colossus
(30072, 1.1), -- Wyrmrest Warden Visual (Red)
(30073, 1.1), -- Wyrmrest Warden Visual (Green)
(30074, 2.7), -- The Leaper
(30075, 1125.0), -- Stitched Colossus (1)
(30076, 1.1), -- Wyrmrest Warden Visual (Blue)
(30077, 1.1), -- Wyrmrest Warden Visual (Black)
(30083, 13.7312), -- Marauding Geist
(30084, 6.25), -- Power Spark
(30085, 109.849998), -- Vigilant Shade
(30087, 270.0), -- Vigilant Shade (1)
(30090, 1000.0), -- Vortex
(30097, 180.0), -- Plagued Ghoul (1)
(30111, 6.25), -- Twilight Worshipper
(30114, 0.3125), -- Twilight Initiate
(30118, 1000.0), -- Malygos Portal Target
(30150, 18.75), -- Frostbrood Destroyer
(30157, 1.1), -- Nikita
(30158, 1.1), -- Billie
(30161, 1000.0), -- Wyrmrest Skytalon
(30170, 0.9), -- Mechagnome Attendant
(30172, 3.125), -- Ahn'kahar Swarm Egg
(30173, 6.25), -- Ahn'kahar Guardian Egg
(30176, 6.25), -- Ahn'kahar Guardian
(30178, 0.3125), -- Ahn'kahar Swarmer
(30179, 6.25), -- Twilight Apostle
(30181, 1000.0), -- Jedoga Controller
(30183, 1000.0), -- Maexxna Wall Clipper
(30190, 0.9), -- Attendant Tock
(30216, 3.75), -- Vile
(30227, 21.0), -- Penumbrius
(30228, 3.75), -- Argent Skytalon
(30234, 1000.0), -- Nexus Lord's Hover Disk
(30245, 65.0), -- Nexus Lord
(30248, 1000.0), -- Scion of Eternitie's Hover Disk
(30249, 32.5), -- Scion of Eternity
(30258, 25.0), -- Amanitar
(30264, 1000.0), -- Spirit Portal
(30269, 22.5), -- Skymaster Baeric
(30271, 22.5), -- Galendror Whitewing
(30275, 9.92064), -- Wild Wyrm
(30276, 6.25), -- Ahn'kahar Web Winder
(30277, 6.25), -- Ahn'kahar Slasher
(30278, 6.25), -- Ahn'kahar Spell Flinger
(30279, 6.25), -- Deep Crawler
(30283, 6.25), -- Plague Walker
(30284, 12.5), -- Bonegrinder
(30285, 6.25), -- Eye of Taldaram
(30286, 6.25), -- Frostbringer
(30287, 3.125), -- Plundering Geist
(30296, 6.0), -- Iron Sentinel Credit
(30300, 37.5), -- Iron Colossus
(30303, 109.849998), -- Juicy Zombie Chow
(30309, 1.25), -- Shambles
(30314, 37.400002), -- Morlia Doomwing
(30319, 6.25), -- Twilight Darkcaster
(30329, 12.5), -- Savage Cave Beast
(30331, 5.0), -- King Jokkum
(30334, 1000.0), -- Malygos Surge of Power
(30338, 0.3125), -- Ahn'kahar Swarmer
(30341, 6.0), -- Eisenfaust
(30353, 4.4), -- Duronn the Runewrought
(30378, 110.0), -- Iydallus
(30385, 6.25), -- Twilight Volunteer
(30388, 20.0), -- Stormhoof
(30389, 405.0), -- Crypt Reaver (1)
(30391, 0.3125), -- Healthy Mushroom
(30393, 62.5), -- Veranus
(30403, 7.5), -- Nergeld
(30406, 1.5), -- Bethod Feigr
(30413, 1000.0), -- Channel Image Target
(30414, 12.5), -- Forgotten One
(30416, 6.25), -- Bound Fire Elemental
(30418, 6.25), -- Bound Air Elemental
(30419, 6.25), -- Bound Water Elemental
(30420, 62.5), -- Veranus
(30424, 13.7312), -- Marauding Leader
(30429, 4.4), -- Runeforged Servant
(30432, 2.0), -- Grimmr Hound
(30433, 37.400002), -- Aedan Moran
(30435, 0.3125), -- Poisonous Mushroom
(30449, 433.0), -- Vesperon
(30451, 433.0), -- Shadron
(30452, 433.0), -- Tenebron
(30453, 130.0), -- Onyx Sanctum Guardian
(30457, 11.0), -- Azure Magus (1)
(30461, 62.5), -- Veranus
(30465, 0.032956), -- Dan's Test Void Sentry
(30470, 1.0), -- Skybreaker Cloudbuster
(30473, 5.5), -- Mage Slayer (1)
(30478, 1000.0), -- Fallen Azure Enforcer
(30486, 12.5), -- Frostbrood Destroyer
(30491, 0.63), -- Ritssyn
(30494, 1000.0), -- Twilight Realm
(30500, 1.25), -- Argent Skytalon
(30501, 1.1), -- Val'kyr Arbiter
(30503, 6.6), -- Stormforged Decimator
(30512, 25.0), -- Grand Magus Telestra
(30516, 1000.0), -- Azure Skyrazor - Landing Dummy
(30517, 1000.0), -- Nexus Rift Portal Operator
(30518, 1000.0), -- Fallen Azure Skyrazor
(30519, 1000.0), -- Fallen Crazed Mana-Surge
(30520, 3.125), -- Chaotic Mana-Wraith
(30521, 1000.0), -- Fallen Crazed Mana-Wyrm
(30522, 6.25), -- Chaotic Rift
(30524, 1000.0), -- Nexus Rift Portal Sender
(30525, 1000.0), -- Nexus Rift Portal Receiver
(30526, 3.125), -- Frayer Seedling
(30528, 3.125), -- Crystalline Seedling
(30531, 6.25), -- Elder Jarten
(30536, 6.25), -- Elder Igasho
(30538, 6.25), -- Elder Chogan'gada
(30549, 274.625), -- NOT SPAWNED - Baron Rivendare
(30553, 3.125), -- Footman James
(30554, 3.125), -- Footman Maxwell
(30561, 3.125), -- Gryan Stoutmantle
(30569, 37.400002), -- Rafae
(30575, 31.25), -- Frostbrood Destroyer
(30585, 1.0), -- Hammerhead
(30590, 52.5), -- Godo Cloudcleaver
(30592, 1000.0), -- Malygos Arcane Field
(30600, 3150.0), -- Highlord Mograine (1)
(30601, 2250.0), -- Lady Blaumeux (1)
(30602, 2520.0), -- Sir Zeliek (1)
(30603, 3780.0), -- Thane Korth'azz (1)
(30609, 56.25), -- Frost Drake
(30616, 1000.0), -- Lava Tsunami
(30617, 7.5), -- Nightmare Aberration
(30625, 1.0), -- Twisted Visage
(30641, 1000.0), -- Twilight Fissure
(30643, 6.25), -- Lava Blaze
(30648, 1000.0), -- Fire Cyclone
(30658, 25.0), -- Lieutenant Sinclari
(30659, 6.25), -- Violet Hold Guard
(30660, 12.5), -- Portal Guardian
(30661, 3.125), -- Azure Invader
(30662, 6.25), -- Azure Spellbreaker
(30663, 3.125), -- Azure Binder
(30664, 6.25), -- Azure Mage Slayer
(30665, 3.125), -- Veteran Mage Hunter
(30666, 12.5), -- Azure Captain
(30667, 6.25), -- Azure Sorceror
(30668, 6.25), -- Azure Raider
(30679, 1000.0), -- Teleportation Portal
(30680, 65.0), -- Onyx Brood General
(30681, 65.0), -- Onyx Blaze Mistress
(30682, 65.0), -- Onyx Flight Captain
(30684, 6.25), -- Yrmirjar Harpoon
(30688, 11.0), -- Disciple of Shadron
(30689, 1.25), -- Chained Abomination
(30695, 12.5), -- Portal Keeper
(30696, 1.25), -- Corpulent Horror
(30697, 4.5), -- Putrid Colossus
(30698, 12.0), -- Morbidus
(30701, 0.9), -- Vile Creeper
(30702, 1000.0), -- Flame Orb
(30723, 1.032), -- Xantili
(30724, 1.032), -- Mertle Murkpen
(30727, 1.04), -- Lelorian
(30729, 1.032), -- Ickabod Pimlen
(30730, 1.032), -- Stanly McCormick
(30731, 1.032), -- Illianna Moonscribe
(30732, 1.04), -- Sessoh
(30733, 1.032), -- Thargen Heavyquill
(30734, 1.104), -- Jezebel Bican
(30735, 1.104), -- Kul Inkspiller
(30743, 0.63), -- Succubus Transform 01
(30775, 156.25), -- Grauf (1)
(30779, 1.0), -- Jormungar Worm (1)
(30782, 1000.0), -- Rocky Cliffs Spirit
(30783, 1000.0), -- King Haldor Spirit Dummy
(30784, 1000.0), -- Spirit of the Abyss
(30785, 1000.0), -- Spirit Burst
(30786, 1000.0), -- Tor's Dragon Boat
(30787, 1000.0), -- Tor's Raiders
(30789, 1.1025), -- Lakota Windsong (1)
(30793, 1.25), -- Mo'arg Extractor (1)
(30804, 1000.0), -- Svala Sorrowgrave
(30806, 12.5), -- Scourge Hulk (1)
(30814, 1.5), -- Vortex Shardling (1)
(30819, 5.0), -- Ymirjar Harpooner (1)
(30822, 1000.0), -- Flame Breath Trigger Right (Skadi)
(30823, 3.125), -- Harpoon Launcher
(30836, 1.1), -- Image of Vardmadra
(30837, 1000.0), -- Violet Hold Containment System
(30838, 800.0), -- Highlord Darion Mograine
(30857, 6.25), -- Defense Dummy Target
(30858, 11.0), -- Disciple of Vesperon
(30861, 4.5), -- Unbound Ancient
(30869, 37.400002), -- Arzo Safeflight
(30870, 37.400002), -- Herzo Safeflight
(30871, 6.25), -- Brigg Smallshanks
(30879, 1000.0), -- Planar Anomaly
(30882, 6.25), -- Twilight Egg
(30890, 6.25), -- Twilight Whelp
(30892, 15.0), -- Portal Guardian
(30893, 13.2), -- Portal Keeper
(30894, 0.9), -- Lithe Stalker
(30895, 0.9), -- Lithe Stalker
(30896, 1000.0), -- Violet Seal
(30897, 1000.0), -- Marnak
(30898, 1000.0), -- Kaddrak
(30899, 1000.0), -- Abedneum
(30901, 1000.0), -- Oculus Power Core
(30902, 1000.0), -- Massive Azure Beam
(30903, 1000.0), -- Oculus Portal
(30904, 12.5), -- Azure Subjugator
(30905, 1000.0), -- Oculus Operator
(30906, 3.125), -- Arcane Residue
(30907, 1000.0), -- Urom Menagery
(30915, 1.0), -- Ring-Lord's Hover Disk
(30916, 1.0), -- Oculus Hover Disk
(30918, 0.88), -- IMPOSTER Azure Binder
(30920, 1.25), -- Lumbering Atrocity
(30930, 9.625), -- Drakkari Golem (1)
(30938, 6.25), -- Living Mojo
(30943, 3.125), -- Coil of Serpents
(30945, 3.3), -- Vardmadra
(30947, 0.9), -- Eidolon Watcher
(30952, 0.9), -- Hungering Plaguehound
(30953, 11.0), -- Baelok
(30962, 1.1), -- IMPOSTER Azure Spellbreaker
(30965, 1000.0), -- Loken
(30967, 4.88), -- Hardened Steel Reaver (1)
(30969, 1000.0), -- Ball Lightning
(30970, 1000.0), -- Molten Anvil Golem
(30971, 11.0), -- Stormforged Construct (1)
(30972, 15.0), -- Stormforged Giant (1)
(30973, 1000.0), -- Lightning Charger
(30987, 3.125), -- Hideous Plaguebringer
(30988, 0.75), -- Scourgebeak Fleshripper
(30989, 11.0), -- Halof the Deathbringer
(30991, 3.125), -- Greater Ley-Whelp
(30997, 1.755), -- UNUSED Chromie
(30998, 66.0), -- Onyx Blaze Mistress (1)
(30999, 70.0), -- Onyx Brood General (1)
(31000, 60.0), -- Onyx Flight Captain (1)
(31001, 132.0), -- Onyx Sanctum Guardian (1)
(31007, 1000.0), -- Eye of Moragg
(31008, 1000.0), -- Eye of Moragg
(31009, 1000.0), -- Eye of Moragg
(31010, 1000.0), -- Eye of Moragg
(31011, 25.0), -- Violet Hold Boss 1
(31029, 3.3), -- Possessed Vardmadra
(31053, 10.5), -- Primalist Mulfort
(31069, 37.400002), -- Penumbrius
(31078, 37.400002), -- Dreadwind
(31079, 6.25), -- Azure Saboteur
(31090, 0.9), -- Cowardly Acherus Geist
(31095, 6.6), -- Val'kyr Battle-maiden
(31098, 3.87), -- Terrifying Abomination
(31100, 0.9), -- Acherus Scourge Proxy
(31103, 1000.0), -- Twilight Egg (Cosmetic)
(31104, 6.25), -- Ahn'kahar Watcher
(31107, 10.0), -- Lieutenant Murp
(31110, 0.9), -- Eidolon Watcher
(31123, 0.9), -- Shandaral Spirit Wolf
(31126, 0.3125), -- Agitated Stratholme Citizen
(31127, 0.3125), -- Agitated Stratholme Resident
(31134, 37.5), -- Cyanigosa
(31135, 1.1), -- Geirrvif
(31137, 1.25), -- Frostbrood Skytalon
(31139, 7.5), -- Pustulent Horror
(31140, 1.25), -- Hulking Abomination
(31141, 1.25), -- Decaying Wight
(31144, 100.0), -- Grandmaster's Training Dummy
(31147, 0.9), -- Vicious Geist
(31150, 1.25), -- Plagued Fiend
(31154, 1.1), -- Gjonner the Merciless
(31159, 11.0), -- Baelok
(31163, 5.5), -- Icefury
(31178, 6.25), -- Captain Falric
(31179, 6.25), -- Captain Marwyn
(31184, 6.25), -- Captain Luc Valonforth
(31187, 6.25), -- Lady Lylia
(31188, 6.25), -- Eris Havenfire
(31198, 10.0), -- Coprous the Defiled
(31199, 3.125), -- Footman John
(31200, 3.125), -- Footman Wayne
(31201, 1.0), -- Melissa Bridenbecker
(31202, 0.3125), -- Lucas
(31203, 0.3125), -- Captured Citizen
(31204, 1000.0), -- Twilight Ghost
(31206, 0.3125), -- Converted Cizizen
(31207, 1000.0), -- Mal'Ganis
(31208, 12.5), -- Infernal
(31210, 0.3125), -- Phillipp
(31211, 0.3125), -- Anja
(31212, 0.3125), -- Kyra
(31214, 1000.0), -- Twilight Portal
(31218, 32.5), -- Acolyte of Shadron
(31219, 32.5), -- Acolyte of Vesperon
(31220, 5.5), -- Plaguehoof
(31221, 5.5), -- Bloodsunder
(31223, 5.5), -- Bloodsunder
(31224, 5.5), -- Icefury
(31225, 5.5), -- Plaguehoof
(31226, 1.25), -- Lumbering Atrocity
(31229, 4.5), -- Ancient Watcher
(31251, 0.09), -- Shadow Vault Skirmisher
(31253, 1000.0), -- Alexstrasza the Life-Binder
(31255, 7.5), -- Saronite Shaper
(31263, 0.1875), -- Carrion Hunter
(31266, 1.1), -- Shadow Vault Assaulter
(31271, 24.0), -- Carnage
(31311, 1100.0), -- Sartharion (1)
(31317, 12.456), -- Lava Blaze (1)
(31322, 7.5), -- Saronite Shaper
(31323, 0.9), -- Lithe Stalker
(31340, 3.125), -- Juvenil Drakkari Gutripper
(31342, 5.5), -- Risen Drakkari Handler (1)
(31343, 3.125), -- Juvenil Drakkari Scytheclaw
(31344, 1000.0), -- Eye Beam
(31348, 2.5), -- Hulking Corpse (1)
(31351, 5.5), -- Risen Drakkari Bat Rider (1)
(31352, 8.8), -- Risen Drakkari Death Knight (1)
(31354, 5.5), -- Risen Drakkari Soulmage (1)
(31355, 5.5), -- Risen Drakkari Warrior (1)
(31363, 12.5), -- Wretched Belcher (1)
(31369, 1000.0), -- Krystallus
(31371, 1000.0), -- Marnak
(31372, 1000.0), -- Kaddrak
(31373, 1000.0), -- Abedneum
(31379, 3.0), -- Eroded Shardling (1)
(31380, 5.5), -- Iron Golem Custodian (1)
(31383, 11.0), -- Lightning Construct (1)
(31385, 11.0), -- Raging Construct (1)
(31387, 12.5), -- Dark Rune Gate Guardian
(31388, 1.0), -- Malformed Ooze (1)
(31390, 0.75), -- Forged Iron Trogg (1)
(31393, 7.8), -- Crystal Wyrm
(31396, 1.1), -- Val'kyr Taskmistress
(31403, 1.1), -- Azure Spellweaver
(31404, 0.55), -- Azure Manabeast
(31411, 1.25), -- Hulking Horror
(31413, 1.25), -- Hulking Horror
(31423, 1.1256), -- Kaja
(31424, 1.05), -- Gamon
(31425, 1.328), -- Olvia
(31426, 7.5), -- Doras
(31427, 1.072), -- Felika
(31429, 1.072), -- Sana
(31431, 56.0), -- Overlord Runthak
(31433, 1.072), -- Innkeeper Gryshka
(31434, 0.93), -- Orc Commoner
(31437, 0.93), -- Forsaken Refugee
(31438, 2.5), -- Shadow Vault Abomination
(31441, 4.5), -- Ahn'kahar Guardian (1)
(31447, 0.017857), -- Ahn'kahar Swarmer (1)
(31448, 0.017857), -- Ahn'kahar Swarmer  (1)
(31450, 4.5), -- Ahn'kahar Web Winder (1)
(31451, 15.0), -- Bonegrinder (1)
(31457, 4.5), -- Eye of Taldaram (1)
(31466, 6.25), -- Plague Walker (1)
(31467, 0.93), -- Forsaken Refugee
(31468, 3.6), -- Plundering Geist (1)
(31474, 5.0), -- Twilight Volunteer (1)
(31480, 1000.0), -- Herald Volazj
(31483, 1.1), -- Azure Binder (1)
(31484, 1.1), -- Azure Binder (1)
(31485, 1000.0), -- Cyanigosa
(31486, 1000.0), -- Arcane Vacuum
(31492, 1.375), -- Azure Saboteur (1)
(31493, 5.5), -- Azure Sorceror (1)
(31494, 1.375), -- Azure Spellbreaker (1)
(31495, 1.375), -- Azure Spellbreaker (1)
(31496, 1.375), -- Azure Spellbreaker (1)
(31501, 13.75), -- Portal Guardian (1)
(31502, 15.625), -- Portal Guardian (1)
(31503, 13.75), -- Portal Keeper (1)
(31504, 13.75), -- Portal Keeper (1)
(31505, 1000.0), -- Violet Hold Mythic Plus
(31518, 0.206349), -- Void Sentry (1)
(31520, 320.0), -- Shadron (1)
(31527, 13.2), -- Felguard Marauder
(31528, 1.1), -- Plagued Felbeast
(31529, 0.9), -- Ravishing Betrayer
(31532, 12.5), -- Treacherous Guardian
(31534, 320.0), -- Tenebron (1)
(31535, 320.0), -- Vesperon (1)
(31539, 4.152), -- Twilight Egg (1)
(31540, 4.152), -- Twilight Whelp (1)
(31541, 1000.0), -- Twilight Portal
(31542, 45.0), -- Rotting Maggot (1)
(31543, 1000.0), -- Twilight Portal
(31544, 33.0), -- Disciple of Shadron (1)
(31546, 33.0), -- Disciple of Vesperon (1)
(31547, 4.152), -- Sartharion Twilight Egg (1)
(31548, 4.152), -- Sartharion Twilight Whelp (1)
(31556, 0.9), -- Hungering Plaguehound
(31558, 30.0), -- Drakos the Interrogator (1)
(31560, 1000.0), -- Mage-Lord Urom Vehicle
(31561, 140.0), -- Ley-Guardian Eregos (1)
(31564, 10.5), -- Warsong Battleguard
(31583, 1.25), -- Frostbrood Skytalon
(31585, 1000.0), -- Azjol'Nerub Sinkhole
(31586, 1000.0), -- Web Door
(31587, 1000.0), -- Pound Vehicle
(31588, 1.8), -- Anub'ar Champion (1)
(31589, 4.5), -- Anub'ar Champion (1)
(31590, 4.5), -- Anub'ar Champion (1)
(31591, 4.5), -- Anub'ar Champion (1)
(31592, 5.0), -- Anub'ar Crusher (1)
(31596, 5.0), -- Anub'ar Crypt Fiend (1)
(31597, 0.207167), -- Anub'ar Darter (1)
(31598, 0.207167), -- Anub'ar Darter (1)
(31601, 5.0), -- Anub'ar Necromancer (1)
(31603, 5.0), -- Anub'ar Necromancer (1)
(31604, 5.0), -- Anub'ar Prime Guard (1)
(31606, 4.5), -- Anub'ar Skirmisher (1)
(31608, 4.5), -- Anub'ar Warrior (1)
(31609, 4.5), -- Anub'ar Webspinner (1)
(31613, 0.260145), -- Skittering Infector (1)
(31614, 0.023413), -- Skittering Swarmer (1)
(31616, 9.0), -- Watcher Narjil (1)
(31647, 1000.0), -- Strange Portal
(31655, 1.375), -- Annhylde the Caller (1)
(31668, 6.25), -- Proto-Drake Rider
(31669, 12.5), -- Enslaved Proto-Drake
(31671, 0.45), -- Frenzied Geist (1)
(31672, 1000.0), -- Dark Nucleus
(31675, 6.25), -- Proto-Drake Rider
(31676, 12.5), -- Enslaved Proto-Drake
(31677, 12.5), -- Proto-Drake Skyguard (1)
(31678, 3.0), -- Savage Worg (1)
(31692, 1.25), -- Reanimated Abomination
(31693, 2.42), -- Stormforged Saboteur
(31694, 5.0), -- Azure Drake Mount
(31695, 31.25), -- Blue Drake Mount
(31696, 7.44048), -- Bronze Drake
(31697, 1.5625), -- Red Drake
(31698, 1.25), -- Twilight Drake Mount
(31702, 1.25), -- Frostbrood Spawn
(31717, 7.44048), -- Bronze Drake Mount
(31718, 0.75), -- Frostbrood Whelp
(31721, 2.5), -- Frostbrood Sentry
(31734, 2800.0), -- Malygos Loot Dummy
(31736, 0.9), -- Geargrinder's Jumpbot
(31748, 1000.0), -- Nexus Hover Disk
(31750, 90.0), -- Nexus Lord (1)
(31751, 60.0), -- Scion of Eternity (1)
(31752, 16.0), -- Wyrmrest Skytalon (1)
(31770, 0.9), -- Thunderbomb's Jumpbot
(31778, 1.5625), -- Black Drake Mount
(31784, 0.9), -- Geargrinder's Jumpbot
(31785, 0.9), -- Thunderbomb's Jumpbot
(31797, 1.1352), -- Ancient Sentinel
(31798, 1.1), -- Athan
(31813, 0.9), -- Frostskull Magus
(31815, 5.2), -- Bone Giant
(31847, 0.9), -- Scavenging Geist
(31881, 6.66667), -- Kor'kron Troop Transport
(31906, 5.0505), -- Veteran Outrunner (2)
(31941, 5.0505), -- Champion Outrunner (2)
(31958, 13.65), -- Commander Mulfort (2)
(31974, 48.75), -- Fjordune the Greater (2)
(31979, 6.5), -- Warmaster Garrick (2)
(31985, 5.0505), -- Frostwolf Outrunner (2)
(31995, 2.19375), -- Furis (2)
(32004, 13.65), -- Horde Spirit Guide (2)
(32005, 15.6), -- Ice Giant (2)
(32027, 105.0), -- Korrak the Bloodrager (2)
(32031, 13.0), -- Lieutenant Grummus (2)
(32037, 13.0), -- Lieutenant Murp <old> (2)
(32041, 10.92), -- Lieutenant Stronghoof (2)
(32050, 16.379999), -- Primalist Thurloga (2)
(32053, 1.365), -- Ravak Grimtotem (2)
(32071, 5.0505), -- Seasoned Outrunner (2)
(32092, 26.0), -- Warmaster Laggrond (2)
(32159, 6.6), -- Doomguard Pillager
(32163, 2.7), -- Grimkor's Hound
(32165, 1.25), -- Twilight Drake Mount (Red)
(32166, 1.25), -- Twilight Drake Mount (Purple)
(32174, 25.0), -- Violet Hold Boss 2
(32179, 5.0), -- Stitched Brute
(32180, 2.5), -- Tempus Wyrm
(32181, 3.3), -- Living Plague
(32185, 2.5), -- Infinite Eradicator
(32186, 6.5), -- Infinite Timebreaker
(32187, 1000.0), -- Malygos Dummy
(32191, 6.25), -- Azure Stalker
(32192, 5.5), -- Azure Stalker (1)
(32218, 1000.0), -- Gundrak Altar Dummy
(32225, 6.66667), -- Skybreaker Troop Transport
(32228, 6.25), -- Guard Munin
(32230, 25.0), -- Void Lord
(32235, 18.0), -- Chaos Watcher
(32260, 0.55), -- Enslaved Minion
(32269, 7.5), -- Legion Invader
(32270, 3.6), -- Legion Dreadwhisperer
(32271, 52.0), -- Legion Overlord
(32280, 8.75), -- Corp'rethar Guardian
(32281, 1.1), -- Guardian of Time
(32295, 1300.0), -- Alexstrasza the Life-Binder
(32299, 7.8), -- Bone Sentinel
(32306, 1.1), -- Infinite Dragonspawn

(32313, 15.5), -- Infinite Corruptor (1)
(32316, 0.55), -- Dark Messenger
(32326, 60.0), -- Prince Arthas Menethil
(32352, 4.375), -- Infinite Timerender
(32353, 100.0), -- Archavon Warder
(32357, 2.25), -- Old Crystalbark
(32368, 130.0), -- Tempest Warder
(32383, 2.1), -- Sergeant Thunderhorn
(32390, 12.5), -- Treacherous Guardian
(32392, 1.1), -- Plagued Felbeast
(32393, 13.2), -- Felguard Marauder
(32394, 0.9), -- Ravishing Betrayer
(32422, 6.0), -- Grocklar
(32432, 1.3), -- Iragos
(32433, 1.3), -- Selagosa
(32434, 1.3), -- Anygos
(32436, 1.3), -- Theragos
(32437, 1.3), -- Myragosa
(32439, 1.3), -- Zyndragosa
(32440, 1.3), -- Corthegos
(32447, 5.0), -- Zul'drak Sentinel
(32448, 1000.0), -- Alexstrasza's Gift
(32467, 6.25), -- Skeletal Reaver
(32471, 1.875), -- Griegen
(32479, 7.8), -- Bone Guard
(32482, 9.0), -- Pustulent Colossus
(32490, 2.2), -- Scourge Deathcharger
(32491, 1.875), -- Time-Lost Proto Drake
(32492, 6.25), -- Frostbrood Matriarch
(32495, 1.65), -- Hildana Deathstealer
(32499, 1.25528), -- Shambling Zombie
(32500, 3.6), -- Dirkee
(32501, 1.65), -- High Thane Jorfus
(32503, 1.25528), -- Shambling Zombie
(32510, 600.0), -- Warsong Battleguard
(32534, 4.96031), -- Scalesworn Elite
(32541, 0.000234), -- BAD DUMMY DONT USE Initiate's Training Dummy
(32542, 0.000234), -- BAD DUMMY DONT USE Disciple's Training Dummy
(32543, 0.000234), -- BAD DUMMY DONT USE Veteran's Training Dummy
(32545, 0.000234), -- BAD DUMMY DONT USE Initiate's Training Dummy
(32551, 22.5), -- Chaos Watcher (1)
(32563, 1.5625), -- Red Drake Mount
(32571, 37.400002), -- Halvdan
(32588, 40.0), -- Illidan Stormrage
(32593, 0.3125), -- Skittering Swarmer
(32630, 1.875), -- Vyragosa
(32665, 3.125), -- Crystalline Tangler
(32667, 100.0), -- Master's Training Dummy
(32749, 1.05), -- Tuff Gorehoof
(32767, 2.5), -- Frostbrood Sentry
(32771, 5.0), -- Stitched Brute
(32780, 1000.0), -- Multi Used - Invisible Stalker (All Phases)
(32813, 1.05), -- Grizzly Hills Flame Keeper
(32823, 0.93), -- Bountiful Table
(32846, 1200.0), -- Hodir (1)
(32857, 720.0), -- Stormcaller Brundir
(32867, 720.0), -- Steelbreaker
(32872, 66.0), -- Runic Colossus
(32873, 60.0), -- Ancient Rune Giant
(32874, 10.0), -- Iron Ring Guard
(32875, 13.0), -- Iron Honor Guard
(32876, 22.0), -- Dark Rune Champion
(32877, 14.0), -- Dark Rune Warbringer
(32878, 12.0), -- Dark Rune Evoker
(32882, 60.0), -- Jormungar Behemoth
(32883, 33.0), -- Captured Mercenary Soldier
(32885, 33.0), -- Captured Mercenary Soldier
(32886, 10.0), -- Dark Rune Acolyte
(32893, 30.0), -- Missy Flamecuffs
(32897, 30.0), -- Field Medic Penny
(32900, 30.0), -- Elementalist Avuun
(32901, 30.0), -- Ellie Nightfeather
(32904, 2.0), -- Dark Rune Commoner
(32908, 45.0), -- Captured Mercenary Captain
(32913, 320.0), -- Elder Ironbranch
(32914, 320.0), -- Elder Stonebark
(32915, 420.0), -- Elder Brightleaf
(32916, 75.0), -- Snaplasher
(32918, 18.0), -- Detonating Lasher
(32919, 60.0), -- Storm Lasher
(32927, 720.0), -- Runemaster Molgeim
(32933, 165.0), -- Left Arm
(32934, 165.0), -- Right Arm
(32941, 30.0), -- Tor Greycloud
(32946, 30.0), -- Veesha Blazeweaver
(32948, 30.0), -- Battle-Priest Eliza
(32950, 30.0), -- Spiritwalker Yona
(32955, 14.0), -- Collapsing Star
(32958, 2.0), -- Lightning Elemental
(33052, 40.0), -- Living Constellation
(33070, 5000.0), -- Algalon the Observer (1)
(33088, 2.5), -- Iron Roots
(33089, 3.0), -- Dark Matter
(33110, 10.0), -- Dark Rune Acolyte
(33116, 80.0), -- Living Constellation (1)
(33121, 330.0), -- Iron Construct
(33136, 70.0), -- Guardian of Yogg-Saron
(33147, 3000.0), -- Thorim (1)
(33148, 120.0), -- Ancient Rune Giant (1)
(33149, 132.0), -- Runic Colossus (1)
(33150, 90.0), -- Captured Mercenary Captain (1)
(33151, 90.0), -- Captured Mercenary Captain (1)
(33152, 66.0), -- Captured Mercenary Soldier (1)
(33153, 66.0), -- Captured Mercenary Soldier (1)
(33154, 120.0), -- Jormungar Behemoth (1)
(33155, 28.0), -- Dark Rune Warbringer (1)
(33156, 24.0), -- Dark Rune Evoker (1)
(33157, 4.0), -- Dark Rune Commoner (1)
(33158, 44.0), -- Dark Rune Champion (1)
(33159, 20.0), -- Dark Rune Acolyte (1)
(33161, 20.0), -- Dark Rune Acolyte (1)
(33162, 20.0), -- Iron Ring Guard (1)
(33163, 26.0), -- Iron Honor Guard (1)
(33167, 1.0), -- Salvaged Demolisher Mechanic Seat
(33168, 2.7), -- Strengthened Iron Roots
(33190, 2800.0), -- Ignis the Furnace Master (1)
(33191, 660.0), -- Iron Construct (1)
(33202, 50.0), -- Ancient Water Spirit
(33203, 255.0), -- Ancient Conservator
(33216, 0.9), -- Mechagnome Pilot
(33228, 5.0), -- Eonar's Gift
(33234, 700.0), -- Sif (1)
(33237, 187.5), -- Ulduar Colossus
(33300, 1.25), -- Thunder Bluff Kodo
(33325, 30.0), -- Eivi Nightfeather
(33326, 30.0), -- Field Medic Jessi
(33327, 30.0), -- Sissy Flamecuffs
(33328, 30.0), -- Elementalist Mahfuun
(33329, 500.0), -- Heart of the Deconstructor
(33330, 30.0), -- Battle-Priest Gina
(33331, 30.0), -- Amira Blazeweaver
(33332, 30.0), -- Spiritwalker Tara
(33333, 30.0), -- Kar Greycloud
(33343, 10.0), -- XS-013 Scrapbot
(33344, 22.0), -- XM-024 Pummeller
(33346, 7.5), -- XE-321 Boombot
(33354, 112.5), -- Corrupted Servitor
(33355, 70.0), -- Misguided Nymph
(33360, 600.0), -- Freya (1)
(33376, 510.0), -- Ancient Conservator (1)
(33385, 10.0), -- Eonar's Gift (1)
(33388, 31.0), -- Dark Rune Guardian
(33391, 840.0), -- Elder Brightleaf (1)
(33392, 640.0), -- Elder Ironbranch (1)
(33393, 640.0), -- Elder Stonebark (1)
(33396, 5.0), -- Iron Roots (1)
(33397, 5.4), -- Strengthened Iron Roots (1)
(33398, 100.0), -- Ancient Water Spirit (1)
(33399, 36.0), -- Detonating Lasher (1)
(33400, 150.0), -- Snaplasher (1)
(33401, 120.0), -- Storm Lasher (1)
(33429, 5.95238), -- Boneguard Lieutenant
(33430, 40.0), -- Guardian Lasher
(33431, 17.0), -- Forest Swarmer
(33432, 1200.0), -- Leviathan Mk II
(33438, 3.0), -- Boneguard Footman
(33449, 3300.0), -- General Vezax (1)
(33450, 1.25), -- [ph] Tournament War Kodo - NPC Only
(33453, 22.0), -- Dark Rune Watcher
(33488, 2.0), -- Saronite Vapors
(33505, 1.3), -- Tamable Devilsaur
(33524, 675.0), -- Saronite Animus
(33525, 40.0), -- Mangrove Ent
(33526, 45.0), -- Ironroot Lasher
(33527, 40.0), -- Nature's Blade
(33528, 43.75), -- Guardian of Life
(33595, 1.05), -- Mera Mistrunner
(33608, 3.104), -- Alchemy
(33609, 3.104), -- Blacksmithing
(33610, 3.104), -- Enchanting
(33611, 3.104), -- Engineering
(33612, 3.104), -- Leatherworking
(33613, 3.104), -- Tailoring
(33614, 3.104), -- Jewelcrafting
(33615, 3.104), -- Inscription
(33616, 3.104), -- Herbalism
(33617, 3.104), -- Mining
(33618, 3.104), -- Skinning
(33619, 3.104), -- Cooking
(33621, 3.104), -- First Aid
(33623, 3.104), -- Fishing
(33651, 1200.0), -- VX-001
(33670, 800.0), -- Aerial Command Unit
(33687, 10.0), -- Chillmaw
(33689, 4.0), -- Lightning Elemental (1)
(33692, 1440.0), -- Runemaster Molgeim (1)
(33693, 1440.0), -- Steelbreaker (1)
(33694, 1440.0), -- Stormcaller Brundir (1)
(33699, 185.0), -- Storm Tempered Keeper
(33700, 370.0), -- Storm Tempered Keeper (1)
(33704, 1.25), -- Frigid Abomination
(33705, 0.77), -- Rune of Power
(33712, 1.1), -- Golden Crawler
(33715, 12.0), -- Charged Sphere
(33716, 13.0), -- Ruby Consort
(33717, 13.0), -- Azure Consort
(33718, 13.0), -- Bronze Consort
(33719, 13.0), -- Emerald Consort
(33720, 13.0), -- Obsidian Consort
(33722, 185.0), -- Storm Tempered Keeper
(33723, 370.0), -- Storm Tempered Keeper (1)
(33724, 1800.0), -- Razorscale (1)
(33729, 225.0), -- Corrupted Servitor (1)
(33731, 34.0), -- Forest Swarmer (1)
(33732, 80.0), -- Guardian Lasher (1)
(33733, 87.5), -- Guardian of Life (1)
(33734, 90.0), -- Ironroot Lasher (1)
(33735, 80.0), -- Mangrove Ent (1)
(33737, 140.0), -- Misguided Nymph (1)
(33741, 80.0), -- Nature's Blade (1)
(33754, 175.0), -- Dark Rune Thunderer
(33755, 175.0), -- Dark Rune Ravager
(33756, 24.0), -- Charged Sphere (1)
(33757, 350.0), -- Dark Rune Thunderer (1)
(33758, 350.0), -- Dark Rune Ravager (1)
(33761, 1.5), -- Elder Brightleaf Image
(33768, 10.0), -- Rubble
(33772, 175.0), -- Faceless Horror
(33773, 350.0), -- Faceless Horror (1)
(33789, 4.0), -- Saronite Vapors (1)
(33793, 2.97619), -- Stabled Gnomeregan Mechanostrider
(33806, 50.0), -- Void Beast
(33815, 100.0), -- Void Beast (1)
(33818, 45.0), -- Twilight Adherent
(33819, 45.0), -- Twilight Frost Mage
(33820, 45.0), -- Twilight Pyromancer
(33822, 70.0), -- Twilight Guardian
(33823, 65.0), -- Twilight Slayer
(33824, 60.0), -- Twilight Shadowblade
(33827, 90.0), -- Twilight Adherent (1)
(33828, 140.0), -- Twilight Guardian (1)
(33829, 90.0), -- Twilight Frost Mage (1)
(33830, 90.0), -- Twilight Pyromancer (1)
(33831, 120.0), -- Twilight Shadowblade (1)
(33832, 130.0), -- Twilight Slayer (1)
(33836, 3.0), -- Bomb Bot
(33838, 60.0), -- Enslaved Fire Elemental
(33839, 120.0), -- Enslaved Fire Elemental (1)
(33846, 22.0), -- Dark Rune Sentinel
(33849, 37.400002), -- Helidan Lightwing
(33850, 62.0), -- Dark Rune Guardian (1)
(33851, 44.0), -- Dark Rune Watcher (1)
(33852, 44.0), -- Dark Rune Sentinel (1)
(33855, 15.0), -- Junk Bot
(33861, 1.5), -- Elder Ironbranch Image
(33876, 1.5), -- Freya Image
(33878, 1.3), -- Thorim Image
(33879, 1.5), -- Hodir Image
(33885, 2800.0), -- XT-002 Deconstructor (1)
(33886, 15.0), -- XE-321 Boombot (1)
(33887, 20.0), -- XS-013 Scrapbot (1)
(33888, 44.0), -- XM-024 Pummeller (1)
(33890, 492.0), -- Brain of Yogg-Saron
(33908, 20.0), -- Rubble (1)
(33909, 2200.0), -- Kologarn (1)
(33910, 330.0), -- Left Arm (1)
(33911, 330.0), -- Right Arm (1)
(33942, 4.0), -- Rubble Stalker Kologarn  (1)
(33954, 984.0), -- Brain of Yogg-Saron (1)
(33955, 6310.0), -- Yogg-Saron (1)
(33959, 1.18686), -- Influence Tentacle (1)
(33966, 150.0), -- Crusher Tentacle
(33967, 300.0), -- Crusher Tentacle (1)
(33968, 140.0), -- Guardian of Yogg-Saron (1)
(33983, 8.0), -- Constrictor Tentacle
(33984, 16.0), -- Constrictor Tentacle (1)
(33986, 17.802799), -- Corruptor Tentacle (1)
(33989, 22.253599), -- Immortal Guardian (1)
(33995, 1000.0), -- Heart of the Deconstructor (1)
(33998, 130.0), -- Tempest Minion
(34003, 10000.0), -- Flame Leviathan (1)
(34004, 22.0), -- Life Spark
(34005, 44.0), -- Life Spark (1)
(34014, 40.0), -- Sanctum Sentry
(34016, 100.0), -- Tempest Warder (1)
(34034, 4.0), -- Swarming Guardian
(34035, 50.0), -- Feral Defender
(34036, 2.1), -- Sergeant Thunderhorn
(34037, 2.1), -- Sergeant Thunderhorn
(34045, 80.0), -- Salvaged Chopper (1)
(34057, 50.0), -- Assault Bot
(34068, 0.9), -- Magnetic Core
(34069, 232.5), -- Molten Colossus
(34085, 132.0), -- Forge Construct
(34086, 120.0), -- Magma Rager
(34097, 10.0), -- Unleashed Dark Matter
(34105, 375.0), -- Ulduar Colossus (1)
(34106, 2400.0), -- Leviathan Mk II (1)
(34108, 2400.0), -- VX-001 (1)
(34109, 1600.0), -- Aerial Command Unit (1)
(34113, 2.0), -- Steelforged Defender (1)
(34114, 30.0), -- Junk Bot (1)
(34115, 100.0), -- Assault Bot (1)
(34133, 210.0), -- Champion of Hodir
(34134, 30.0), -- Winter Revenant
(34135, 30.0), -- Winter Rumbler
(34137, 40.0), -- Winter Jormungar
(34139, 420.0), -- Champion of Hodir (1)
(34140, 80.0), -- Winter Jormungar (1)
(34141, 60.0), -- Winter Revenant (1)
(34142, 60.0), -- Winter Rumbler (1)
(34147, 3.6), -- Emergency Fire Bot
(34148, 7.2), -- Emergency Fire Bot (1)
(34152, 1350.0), -- Saronite Animus (1)
(34164, 162.5), -- Mechagnome Battletank
(34165, 325.0), -- Mechagnome Battletank (1)
(34166, 80.0), -- Sanctum Sentry (1)
(34169, 8.0), -- Swarming Guardian (1)
(34171, 100.0), -- Feral Defender (1)
(34175, 2400.0), -- Auriaya (1)
(34183, 70.0), -- Arachnopod Destroyer
(34184, 36.0), -- Clockwork Mechanic
(34185, 465.0), -- Molten Colossus (1)
(34186, 264.0), -- Forge Construct (1)
(34190, 93.75), -- Hardened Iron Golem
(34191, 17.0), -- Trash
(34192, 3.0), -- Boomer XP-500
(34193, 49.5), -- Clockwork Sapper
(34196, 137.5), -- Rune Etched Sentry
(34197, 143.75), -- Chamber Overseer
(34199, 55.0), -- Lightning Charged Iron Dwarf
(34201, 240.0), -- Magma Rager (1)
(34214, 140.0), -- Arachnopod Destroyer (1)
(34215, 28.0), -- Collapsing Star (1)
(34216, 6.0), -- Boomer XP-500 (1)
(34217, 34.0), -- Trash (1)
(34218, 6.0), -- Bomb Bot (1)
(34219, 72.0), -- Clockwork Mechanic (1)
(34220, 99.0), -- Clockwork Sapper (1)
(34221, 6.0), -- Dark Matter (1)
(34222, 20.0), -- Unleashed Dark Matter (1)
(34226, 287.5), -- Chamber Overseer (1)
(34229, 187.5), -- Hardened Iron Golem (1)
(34230, 1000.0), -- REUSE ME - Emalon Controller
(34234, 25.0), -- Runeforged Sentry
(34235, 50.0), -- Runeforged Sentry (1)
(34236, 50.0), -- Iron Mender (1)
(34237, 110.0), -- Lightning Charged Iron Dwarf (1)
(34245, 275.0), -- Rune Etched Sentry (1)
(34255, 50.0), -- Expedition Defender (1)
(34267, 27.0), -- Parts Recovery Technician
(34268, 54.0), -- Parts Recovery Technician (1)
(34269, 30.0), -- XR-949 Salvagebot
(34270, 60.0), -- XR-949 Salvagebot (1)
(34271, 30.0), -- XD-175 Compactobot
(34272, 60.0), -- XD-175 Compactobot (1)
(34273, 30.0), -- XB-488 Disposalbot
(34274, 60.0), -- XB-488 Disposalbot (1)
(34310, 15.6), -- Keristrasza
(34332, 28.684), -- Sara (1)
(34362, 0.75), -- Proximity Mine
(34382, 1.04167), -- Chapman
(34383, 1.04167), -- Catrina
(34428, 1.21951), -- MiniZep
(34435, 1.104), -- Cheerful Human Spirit
(34441, 192.0), -- Vivienne Blackwhisper
(34442, 384.0), -- Vivienne Blackwhisper (1)
(34443, 576.0), -- Vivienne Blackwhisper (2)
(34444, 192.0), -- Thrakgar
(34445, 192.0), -- Liandra Suncaller
(34447, 192.0), -- Caiphus the Stern
(34448, 192.0), -- Ruj'kah
(34449, 192.0), -- Ginselle Blightslinger
(34450, 192.0), -- Harkzog
(34451, 192.0), -- Birana Stormhoof
(34453, 192.0), -- Narrhok Steelbreaker
(34454, 192.0), -- Maz'dinah
(34455, 192.0), -- Broln Stouthorn
(34456, 192.0), -- Malithas Brightblade
(34458, 192.0), -- Gorgrim Shadowcleave
(34459, 192.0), -- Erin Misthoof
(34460, 192.0), -- Kavina Grovesong
(34461, 192.0), -- Tyrius Duskblade
(34463, 192.0), -- Shaabad
(34465, 192.0), -- Velanaa
(34466, 192.0), -- Anthar Forgemender
(34467, 192.0), -- Alyssia Moonstalker
(34468, 192.0), -- Noozle Whizzlestick
(34469, 192.0), -- Melador Valestrider
(34470, 192.0), -- Saamul
(34471, 192.0), -- Baelnor Lightbearer
(34472, 192.0), -- Irieth Shadowstep
(34473, 192.0), -- Brienna Nightfell
(34474, 192.0), -- Serissa Grimdabbler
(34475, 192.0), -- Shocuul
(34476, 1.104), -- Cheerful Forsaken Spirit
(34478, 1.104), -- Cheerful Dwarf Spirit
(34479, 1.104), -- Cheerful Night Elf Spirit
(34480, 1.1592), -- Cheerful Tauren Spirit
(34481, 1.104), -- Cheerful Gnome Spirit
(34482, 1.104), -- Cheerful Troll Spirit
(34497, 2000.0), -- Fjola Lightbane
(34558, 1.25), -- Great Golden Kodo
(34562, 0.93), -- [DND] Stink Bomb Target
(34565, 0.93), -- Innocuous Townsman
(34566, 3000.0), -- Anub'arak (1)
(34605, 4.5), -- Swarm Scarab
(34607, 48.599998), -- Nerubian Burrower
(34612, 1.575), -- Danowe Thunderhorn
(34644, 1.048), -- Edward Winslow
(34645, 1.048), -- Elizabeth Barker Winslow
(34648, 97.199997), -- Nerubian Burrower (1)
(34653, 1.04167), -- Bountiful Table Hostess
(34679, 1.048), -- Francis Eaton
(34681, 1.048), -- Ikaneba Summerset
(34682, 1.048), -- Wilmina Holbeck
(34684, 1.1004), -- Laha Farplain
(34685, 1.1004), -- Dalni Tallgrass
(34708, 1.048), -- Caitrin Ironkettle
(34710, 1.048), -- Ellen Moore
(34711, 1.048), -- Mary Allerton
(34712, 1.048), -- Roberta Carter
(34713, 1.1004), -- Ondani Greatmill
(34714, 1.1004), -- Mahara Goldwheat
(34744, 1.048), -- Jasper Moore
(34783, 1.06), -- Ranisa Whitebough
(34785, 1.06), -- Alnar Whitebough
(34786, 1.06), -- Alice Rigsdale
(34787, 1.06), -- John Rigsdale
(34796, 640.0), -- Gormok the Impaler
(34799, 360.0), -- Dreadscale
(34800, 40.0), -- Snobold Vassal
(34815, 20.799999), -- Felflame Infernal
(34826, 63.0), -- Mistress of Pain
(35038, 37.700001), -- Memory of Malchezaar
(35041, 37.700001), -- Memory of Archimonde
(35042, 31.9), -- Memory of Illidan
(35046, 37.700001), -- Memory of Cyanigosa
(35048, 37.700001), -- Memory of Onyxia
(35050, 43.5), -- Memory of Ignis
(35052, 36.25), -- Memory of Algalon
(35093, 3.104), -- Wind Rider Jahubo
(35099, 3.2592), -- Bana Wildmane
(35100, 1.4), -- Hargen Bronzewing
(35101, 4.19), -- Grunda Bronzewing
(35131, 3.25), -- Durgan Thunderbeak
(35143, 169.0), -- Flame Warder
(35144, 360.0), -- Acidmaw
(35216, 2900.0), -- Lord Jaraxxus (1)
(35247, 0.93), -- Ghostly Dwarf Celebrant
(35255, 0.009), -- Death Shade
(35262, 41.599998), -- Felflame Infernal (1)
(35263, 62.400002), -- Felflame Infernal (2)
(35264, 83.199997), -- Felflame Infernal (3)
(35265, 2.0), -- Infernal Volcano (1)
(35266, 3.0), -- Infernal Volcano (2)
(35267, 4.0), -- Infernal Volcano (3)
(35268, 4350.0), -- Lord Jaraxxus (2)
(35269, 5800.0), -- Lord Jaraxxus (3)
(35270, 126.0), -- Mistress of Pain (1)
(35271, 189.0), -- Mistress of Pain (2)
(35272, 252.0), -- Mistress of Pain (3)
(35278, 2.0), -- Nether Portal (1)
(35279, 3.0), -- Nether Portal (2)
(35280, 4.0), -- Nether Portal (3)
(35290, 1.05), -- Steen Horngrass
(35337, 1.048), -- Bountiful Barrel
(35340, 1.048), -- Bountiful Barrel
(35343, 1.048), -- Bountiful Barrel
(35347, 4000.0), -- Eydis Darkbane (1)
(35348, 6000.0), -- Eydis Darkbane (2)
(35349, 8000.0), -- Eydis Darkbane (3)
(35350, 4000.0), -- Fjola Lightbane (1)
(35351, 6000.0), -- Fjola Lightbane (2)
(35352, 8000.0), -- Fjola Lightbane (3)
(35353, 60.0), -- Concentrated Darkness (1)
(35354, 90.0), -- Concentrated Darkness (2)
(35355, 120.0), -- Concentrated Darkness (3)
(35356, 60.0), -- Concentrated Light (1)
(35357, 90.0), -- Concentrated Light (2)
(35358, 120.0), -- Concentrated Light (3)
(35359, 100.0), -- Flame Warder (1)
(35438, 1280.0), -- Gormok the Impaler (1)
(35439, 1920.0), -- Gormok the Impaler (2)
(35440, 2560.0), -- Gormok the Impaler (3)
(35441, 80.0), -- Snobold Vassal (1)
(35442, 120.0), -- Snobold Vassal (2)
(35443, 160.0), -- Snobold Vassal (3)
(35447, 1900.0), -- Icehowl (1)
(35448, 2850.0), -- Icehowl (2)
(35449, 3800.0), -- Icehowl (3)
(35465, 31.5), -- Zhaagrym
(35471, 1.575), -- Sorn Proudmane
(35474, 33.0), -- Vengeful Val'kyr
(35511, 720.0), -- Acidmaw (1)
(35512, 1080.0), -- Acidmaw (2)
(35513, 1440.0), -- Acidmaw (3)
(35514, 720.0), -- Dreadscale (1)
(35515, 1080.0), -- Dreadscale (2)
(35516, 1440.0), -- Dreadscale (3)
(35519, 45.0), -- Memory of Algalon (1)
(35520, 46.799999), -- Memory of Archimonde (1)
(35522, 46.799999), -- Memory of Cyanigosa (1)
(35532, 54.0), -- Memory of Ignis (1)
(35533, 39.599998), -- Memory of Illidan (1)
(35537, 46.799999), -- Memory of Malchezaar (1)
(35539, 46.799999), -- Memory of Onyxia (1)
(35594, 0.9), -- Brassbolt Mechawrench
(35607, 0.9), -- Reginald Arcfire
(35610, 35.0), -- Cat

(35615, 4500.0), -- Anub'arak (2)
(35616, 6000.0), -- Anub'arak (3)
(35642, 2.7), -- Jeeves
(35655, 145.800003), -- Nerubian Burrower (2)
(35656, 194.399994), -- Nerubian Burrower (3)
(35658, 13.5), -- Swarm Scarab (2)
(35659, 18.0), -- Swarm Scarab (3)
(35662, 384.0), -- Alyssia Moonstalker (1)
(35663, 576.0), -- Alyssia Moonstalker (2)
(35664, 768.0), -- Alyssia Moonstalker (3)
(35665, 384.0), -- Anthar Forgemender (1)
(35666, 576.0), -- Anthar Forgemender (2)
(35667, 768.0), -- Anthar Forgemender (3)
(35668, 384.0), -- Baelnor Lightbearer (1)
(35669, 576.0), -- Baelnor Lightbearer (2)
(35670, 768.0), -- Baelnor Lightbearer (3)
(35671, 384.0), -- Birana Stormhoof (1)
(35672, 576.0), -- Birana Stormhoof (2)
(35673, 768.0), -- Birana Stormhoof (3)
(35674, 384.0), -- Brienna Nightfell (1)
(35675, 576.0), -- Brienna Nightfell (2)
(35676, 768.0), -- Brienna Nightfell (3)
(35680, 384.0), -- Broln Stouthorn (1)
(35681, 576.0), -- Broln Stouthorn (2)
(35682, 768.0), -- Broln Stouthorn (3)
(35683, 384.0), -- Caiphus the Stern (1)
(35684, 576.0), -- Caiphus the Stern (2)
(35685, 768.0), -- Caiphus the Stern (3)
(35686, 384.0), -- Erin Misthoof (1)
(35687, 576.0), -- Erin Misthoof (2)
(35688, 768.0), -- Erin Misthoof (3)
(35689, 384.0), -- Ginselle Blightslinger (1)
(35690, 576.0), -- Ginselle Blightslinger (2)
(35691, 768.0), -- Ginselle Blightslinger (3)
(35692, 384.0), -- Gorgrim Shadowcleave (1)
(35693, 576.0), -- Gorgrim Shadowcleave (2)
(35694, 768.0), -- Gorgrim Shadowcleave (3)
(35695, 384.0), -- Harkzog (1)
(35696, 576.0), -- Harkzog (2)
(35697, 768.0), -- Harkzog (3)
(35699, 384.0), -- Irieth Shadowstep (1)
(35700, 576.0), -- Irieth Shadowstep (2)
(35701, 768.0), -- Irieth Shadowstep (3)
(35702, 384.0), -- Kavina Grovesong (1)
(35703, 576.0), -- Kavina Grovesong (2)
(35704, 768.0), -- Kavina Grovesong (3)
(35705, 384.0), -- Liandra Suncaller (1)
(35706, 576.0), -- Liandra Suncaller (2)
(35707, 768.0), -- Liandra Suncaller (3)
(35708, 384.0), -- Malithas Brightblade (1)
(35709, 576.0), -- Malithas Brightblade (2)
(35710, 768.0), -- Malithas Brightblade (3)
(35711, 384.0), -- Maz'dinah (1)
(35712, 576.0), -- Maz'dinah (2)
(35713, 768.0), -- Maz'dinah (3)
(35714, 384.0), -- Melador Valestrider (1)
(35715, 576.0), -- Melador Valestrider (2)
(35716, 768.0), -- Melador Valestrider (3)
(35718, 384.0), -- Narrhok Steelbreaker (1)
(35719, 576.0), -- Narrhok Steelbreaker (2)
(35720, 768.0), -- Narrhok Steelbreaker (3)
(35721, 384.0), -- Noozle Whizzlestick (1)
(35722, 576.0), -- Noozle Whizzlestick (2)
(35723, 768.0), -- Noozle Whizzlestick (3)
(35724, 384.0), -- Ruj'kah (1)
(35725, 576.0), -- Ruj'kah (2)
(35726, 768.0), -- Ruj'kah (3)
(35728, 384.0), -- Saamul (1)
(35729, 576.0), -- Saamul (2)
(35730, 768.0), -- Saamul (3)
(35731, 384.0), -- Serissa Grimdabbler (1)
(35732, 576.0), -- Serissa Grimdabbler (2)
(35733, 768.0), -- Serissa Grimdabbler (3)
(35734, 384.0), -- Shaabad (1)
(35735, 576.0), -- Shaabad (2)
(35736, 768.0), -- Shaabad (3)
(35737, 384.0), -- Shocuul (1)
(35738, 576.0), -- Shocuul (2)
(35739, 768.0), -- Shocuul (3)
(35740, 384.0), -- Thrakgar (1)
(35741, 576.0), -- Thrakgar (2)
(35742, 768.0), -- Thrakgar (3)
(35743, 384.0), -- Tyrius Duskblade (1)
(35744, 576.0), -- Tyrius Duskblade (2)
(35745, 768.0), -- Tyrius Duskblade (3)
(35746, 384.0), -- Velanaa (1)
(35747, 576.0), -- Velanaa (2)
(35748, 768.0), -- Velanaa (3)
(35749, 768.0), -- Vivienne Blackwhisper (3)
(35763, 1.5), -- Skittering Scarab
(35766, 30.0), -- Barrett Ramsey
(35774, 70.0), -- Cat (1)
(35775, 105.0), -- Cat (2)
(35776, 140.0), -- Cat (3)
(36067, 22.253599), -- Marked Immortal Guardian (1)
(36070, 3.0), -- Treant
(36168, 187.5), -- Dan's Test Colossus
(36173, 1.5), -- Innocuous Scarab
(36272, 15.0), -- Apothecary Frye
(36296, 15.0), -- Apothecary Hummel
(36301, 63.0), -- Zhaagrym (1)
(36302, 94.5), -- Zhaagrym (2)
(36303, 126.0), -- Zhaagrym (3)
(36522, 5.4), -- Soul Horror
(36565, 15.0), -- Apothecary Baxter
(36568, 1.0), -- Crazed Apothecary
(36609, 55.0), -- Val'kyr Shadowguard
(36619, 5.1), -- Bone Spike
(36633, 1.42857), -- Ice Sphere
(36644, 1.05), -- Ahmo Thunderhorn
(36648, 420.0), -- Baine Bloodhoof (Leader)
(36661, 300.0), -- Rimefang
(36701, 190.477005), -- Raging Spirit
(36723, 32.5), -- Frostsworn General
(36791, 18.0), -- Blazing Skeleton
(36796, 0.2), -- Corrupted Champion
(36830, 16.25), -- Wrathbone Laborer
(36838, 100.518997), -- Alliance Gunship Cannon
(36839, 100.518997), -- Horde Gunship Cannon
(36879, 18.75), -- Plagueborn Horror
(36880, 187.5), -- Decaying Colossus
(36886, 5.85), -- Geist Ambusher
(36888, 4.0), -- Rescued Alliance Slave
(36889, 4.0), -- Rescued Horde Slave
(36939, 350.0), -- High Overlord Saurfang
(36948, 350.0), -- Muradin Bronzebeard
(36950, 16.0), -- Skybreaker Marine
(36957, 16.0), -- Kor'kron Reaver
(36960, 40.0), -- Kor'kron Sergeant
(36961, 40.0), -- Skybreaker Sergeant
(36968, 16.0), -- Kor'kron Axethrower
(36969, 16.0), -- Skybreaker Rifleman
(36978, 7.0), -- Skybreaker Mortar Soldier
(36980, 36.0), -- Ice Tomb
(36982, 7.0), -- Kor'kron Rocketeer
(36991, 2.2), -- Sunwell Guardian
(37007, 162.5), -- Deathbound Ward
(37014, 1.72125), -- Ice Wall Target
(37016, 31.875), -- Skybreaker Luminary
(37022, 93.75), -- Blighted Abomination
(37025, 312.5), -- Stinky
(37037, 1.0), -- Spawn Book Dummy
(37038, 11.25), -- Vengeful Fleshreaper
(37069, 12.5), -- Lumbering Abomination
(37098, 88.0), -- Val'kyr Herald
(37116, 60.0), -- Skybreaker Sorcerer
(37117, 60.0), -- Kor'kron Battle-Mage
(37126, 550.0), -- Sister Svalna
(37128, 45.0), -- [PH] Icecrown Shade
(37215, 98.960197), -- Orgrim's Hammer
(37217, 312.5), -- Precious
(37230, 100.0), -- Spire Frostwyrm
(37259, 5.0505), -- Champion Outrunner (3)
(37276, 13.65), -- Commander Mulfort (3)
(37293, 48.75), -- Fjordune the Greater (3)
(37304, 5.0505), -- Frostwolf Outrunner (3)
(37314, 2.19375), -- Furis (3)
(37324, 15.6), -- Ice Giant (3)
(37347, 140.0), -- Korrak the Bloodrager (3)
(37351, 13.0), -- Lieutenant Grummus (3)
(37357, 13.0), -- Lieutenant Murp <old> (3)
(37361, 10.92), -- Lieutenant Stronghoof (3)
(37392, 5.0505), -- Seasoned Outrunner (3)
(37459, 5.0505), -- Veteran Outrunner (3)
(37504, 5800.0), -- Festergut (1)
(37505, 8700.0), -- Festergut (2)
(37506, 11600.0), -- Festergut (3)
(37509, 41.25), -- Shattered Sun Sentry
(37510, 3.75), -- Shattered Sun Archmage
(37512, 3.75), -- Shattered Sun Warrior
(37523, 3.0), -- Warden of the Sunwell
(37527, 375.0), -- Halduron Brightwing
(37532, 7.5), -- Frostwing Whelp
(37533, 300.0), -- Rimefang
(37534, 300.0), -- Spinestalker
(37540, 98.960197), -- The Skybreaker
(37546, 62.5), -- Frenzied Abomination
(37549, 18.75), -- Lumbering Abomination (1)
(37550, 5.0), -- Raging Ghoul (1)
(37552, 9.0), -- Thalorien Dawnseeker's Remains
(37562, 280.0), -- Gas Cloud
(37565, 6.75), -- Soul Horror (1)
(37572, 4.0), -- Freed Alliance Slave
(37578, 4.0), -- Freed Horde Slave
(37586, 11.0), -- Fury
(37616, 5.0), -- Freed Alliance Slave (1)
(37617, 8.0), -- Freed Alliance Slave (1)
(37619, 8.0), -- Freed Horde Slave (1)
(37620, 8.0), -- Freed Horde Slave (1)
(37621, 5.0), -- Freed Horde Slave (1)
(37622, 7.2), -- Geist Ambusher (1)
(37623, 8.0), -- Coliseum Champion (1)
(37624, 8.0), -- Coliseum Champion (1)
(37625, 8.0), -- Coliseum Champion (1)
(37629, 30.0), -- Krick (1)
(37635, 25.0), -- Plagueborn Horror (1)
(37638, 26.25), -- Wrathbone Laborer (1)
(37654, 4.0), -- Rescued Horde Slave (1)
(37655, 375.0), -- Decaying Colossus (1)
(37672, 75.0), -- Mutated Abomination
(37695, 40.0), -- Drudge Ghoul
(37697, 280.0), -- Volatile Ooze
(37698, 286.841003), -- Shambling Horror
(37707, 3.75), -- Silvermoon Builder
(37720, 45.5), -- Frostsworn General (1)
(37799, 15.873), -- Vile Spirit
(37860, 1.575), -- Bluffwatcher
(37862, 1.3), -- Lord Jaraxxus Image
(37863, 9.0), -- Suppresser
(37868, 25.0), -- Risen Archmage
(37886, 81.25), -- Gluttonous Abomination
(37890, 15.0), -- Cult Fanatic
(37906, 0.75), -- Imprisoned Soul
(37907, 5.0), -- Rot Worm
(37934, 25.0), -- Blistering Zombie
(37949, 15.0), -- Cult Adherent
(37957, 3400.0), -- Lord Marrowgar (1)
(37958, 5100.0), -- Lord Marrowgar (2)
(37959, 6800.0), -- Lord Marrowgar (3)
(37970, 1620.0), -- Prince Valanar
(37972, 1620.0), -- Prince Keleseth
(37973, 1620.0), -- Prince Taldaram
(37984, 1.008), -- Crown Duster
(38000, 40.0), -- Crok Scourgebane (1)
(38008, 1620.0), -- Blood Orb Controller
(38009, 15.0), -- Reanimated Fanatic
(38010, 15.0), -- Reanimated Adherent
(38016, 1.056), -- Crown Agent
(38017, 867.099976), -- Kalecgos
(38031, 325.0), -- Deathbound Ward (1)
(38035, 0.93), -- Chemical Wagon
(38057, 60.0), -- Servant of the Throne (1)
(38058, 50.0), -- Nerub'ar Broodkeeper (1)
(38059, 50.0), -- Ancient Skeletal Soldier (1)
(38061, 76.0), -- The Damned (1)
(38062, 70.0), -- Plague Scientist (1)
(38063, 22.5), -- Vengeful Fleshreaper (1)
(38064, 625.0), -- Stinky (1)
(38072, 50.0), -- Deathspeaker Attendant (1)
(38073, 50.0), -- Deathspeaker Disciple (1)
(38074, 150.0), -- Deathspeaker High Priest (1)
(38075, 40.0), -- Deathspeaker Servant (1)
(38076, 60.0), -- Deathspeaker Zealot (1)
(38078, 60.0), -- Skybreaker Assassin (1)
(38079, 60.0), -- Skybreaker Dreadblade (1)
(38080, 50.0), -- Skybreaker Hierophant (1)
(38082, 70.0), -- Skybreaker Protector (1)
(38083, 50.0), -- Skybreaker Sorcerer (1)
(38084, 50.0), -- Skybreaker Summoner (1)
(38085, 50.0), -- Skybreaker Vicar (1)
(38086, 70.0), -- Skybreaker Vindicator (1)
(38087, 70.0), -- Kor'kron Defender (1)
(38088, 50.0), -- Kor'kron Invoker (1)
(38090, 50.0), -- Kor'kron Oracle (1)
(38091, 50.0), -- Kor'kron Primalist (1)
(38094, 60.0), -- Kor'kron Stalker (1)
(38096, 70.0), -- Kor'kron Vanquisher (1)
(38097, 60.0), -- Skybreaker Marksman (1)
(38098, 100.0), -- Darkfallen Advisor (1)
(38099, 80.0), -- Darkfallen Archmage (1)
(38100, 80.0), -- Darkfallen Blood Knight (1)
(38101, 120.0), -- Darkfallen Lieutenant (1)
(38102, 120.0), -- Darkfallen Commander (1)
(38103, 625.0), -- Precious (1)
(38106, 3000.0), -- Lady Deathwhisper (1)
(38108, 187.5), -- Blighted Abomination (1)
(38110, 125.0), -- Pustulating Horror (1)
(38126, 90.0), -- Ymirjar Frostbinder (1)
(38128, 197.919998), -- The Skybreaker (1)
(38129, 197.919998), -- Orgrim's Hammer (1)
(38130, 90.0), -- Ymirjar Deathbringer (1)
(38131, 70.0), -- Ymirjar Huntress (1)
(38132, 90.0), -- Ymirjar Battle-Maiden (1)
(38133, 100.0), -- Ymirjar Warlord (1)
(38135, 18.75), -- Deformed Fanatic
(38136, 15.0), -- Empowered Adherent
(38139, 180.0), -- Frostwarden Handler (1)
(38151, 15.0), -- Frostwing Whelp (1)
(38156, 700.0), -- High Overlord Saurfang (1)
(38157, 700.0), -- Muradin Bronzebeard (1)
(38166, 162.5), -- Gluttonous Abomination (1)
(38167, 50.0), -- Risen Archmage (1)
(38168, 10.0), -- Rot Worm (1)
(38169, 50.0), -- Blazing Skeleton (1)
(38170, 50.0), -- Blistering Zombie (1)
(38171, 18.0), -- Suppresser (1)
(38219, 600.0), -- Spinestalker (1)
(38220, 600.0), -- Rimefang (1)
(38233, 10.2), -- Bone Spike (1)
(38256, 120.0), -- Skybreaker Sorcerer (1)
(38257, 120.0), -- Kor'kron Battle-Mage (1)
(38258, 1100.0), -- Sister Svalna (1)
(38261, 80.0), -- Skybreaker Sergeant (1)
(38262, 80.0), -- Kor'kron Sergeant (1)
(38264, 12.0), -- Dark Rune Giant Transform
(38265, 6875.0), -- Sindragosa (1)
(38266, 10312.5), -- Sindragosa (2)
(38267, 13750.0), -- Sindragosa (3)
(38285, 93.75), -- Mutated Abomination
(38288, 0.93), -- Love Guard Perfume Bunny
(38296, 5000.0), -- Lady Deathwhisper (2)
(38297, 6000.0), -- Lady Deathwhisper (3)
(38298, 20.0), -- Captain Arnath (1)
(38299, 20.0), -- Captain Brandon (1)
(38303, 20.0), -- Captain Grondel (1)
(38304, 20.0), -- Captain Rupert (1)
(38320, 72.0), -- Ice Tomb (1)
(38321, 108.0), -- Ice Tomb (2)
(38322, 144.0), -- Ice Tomb (3)
(38390, 5200.0), -- Rotface (1)
(38391, 1.1), -- Val'kyr Guardian
(38392, 1.1), -- Val'kyr Protector
(38393, 30.0), -- Cult Fanatic (1)
(38394, 30.0), -- Cult Adherent (1)
(38395, 37.5), -- Deformed Fanatic (1)
(38396, 30.0), -- Empowered Adherent (1)
(38397, 30.0), -- Reanimated Adherent (1)
(38398, 30.0), -- Reanimated Fanatic (1)
(38399, 3240.0), -- Prince Keleseth (1)
(38400, 3240.0), -- Prince Taldaram (1)
(38401, 3240.0), -- Prince Valanar (1)
(38402, 4500.0), -- Deathbringer Saurfang (1)
(38403, 32.0), -- Kor'kron Axethrower (1)
(38404, 32.0), -- Kor'kron Reaver (1)
(38405, 14.0), -- Kor'kron Rocketeer (1)
(38406, 32.0), -- Skybreaker Marine (1)
(38407, 14.0), -- Skybreaker Mortar Soldier (1)
(38408, 32.0), -- Skybreaker Rifleman (1)
(38418, 176.0), -- Val'kyr Herald (1)
(38431, 6000.0), -- Professor Putricide (1)
(38434, 8522.0), -- Blood-Queen Lana'thel (1)
(38435, 12783.0), -- Blood-Queen Lana'thel (2)
(38436, 17044.0), -- Blood-Queen Lana'thel (3)
(38439, 1000.0), -- REUSE ME - Toravon Stalker
(38444, 200.0), -- Spire Frostwyrm (1)
(38445, 50.0), -- Spire Minion (1)
(38446, 125.0), -- Frenzied Abomination (1)
(38456, 21.969999), -- Frozen Orb
(38459, 15.3), -- Bone Spike (2)
(38460, 20.4), -- Bone Spike (3)
(38479, 120.0), -- Darkfallen Tactician (1)
(38480, 80.0), -- Darkfallen Noble (1)
(38481, 50.0), -- Spire Gargoyle (1)
(38482, 219.699997), -- Frost Warder
(38486, 150.0), -- Infiltrator Minchar (1)
(38490, 675.0), -- Rotting Frost Giant
(38494, 2475.0), -- Rotting Frost Giant
(38508, 6.75), -- Blood Beast
(38549, 7800.0), -- Rotface (2)
(38550, 10400.0), -- Rotface (3)
(38552, 150.0), -- Alrin the Agile (1)
(38582, 6750.0), -- Deathbringer Saurfang (2)
(38583, 9000.0), -- Deathbringer Saurfang (3)
(38585, 9000.0), -- Professor Putricide (2)
(38586, 12000.0), -- Professor Putricide (3)
(38596, 13.5), -- Blood Beast (1)
(38597, 20.25), -- Blood Beast (2)
(38598, 27.0), -- Blood Beast (3)
(38605, 150.0), -- Mutated Abomination (1)
(38625, 45.0), -- Cult Adherent (2)
(38626, 60.0), -- Cult Adherent (3)
(38628, 45.0), -- Cult Fanatic (2)
(38629, 60.0), -- Cult Fanatic (3)
(38630, 45.0), -- Reanimated Fanatic (2)
(38631, 60.0), -- Reanimated Fanatic (3)
(38632, 45.0), -- Empowered Adherent (2)
(38633, 60.0), -- Empowered Adherent (3)
(38634, 56.25), -- Deformed Fanatic (2)
(38635, 75.0), -- Deformed Fanatic (3)
(38637, 1050.0), -- High Overlord Saurfang (2)
(38638, 1400.0), -- High Overlord Saurfang (3)
(38639, 1050.0), -- Muradin Bronzebeard (2)
(38640, 1400.0), -- Muradin Bronzebeard (3)
(38641, 3240.0), -- Blood Orb Controller (1)
(38675, 48.0), -- Kor'kron Axethrower (2)
(38676, 64.0), -- Kor'kron Axethrower (3)
(38677, 180.0), -- Kor'kron Battle-Mage (2)
(38678, 240.0), -- Kor'kron Battle-Mage (3)
(38679, 48.0), -- Kor'kron Reaver (2)
(38680, 64.0), -- Kor'kron Reaver (3)
(38681, 21.0), -- Kor'kron Rocketeer (2)
(38682, 28.0), -- Kor'kron Rocketeer (3)
(38683, 120.0), -- Kor'kron Sergeant (2)
(38684, 160.0), -- Kor'kron Sergeant (3)
(38685, 48.0), -- Skybreaker Marine (2)
(38686, 64.0), -- Skybreaker Marine (3)
(38687, 21.0), -- Skybreaker Mortar Soldier (2)
(38688, 28.0), -- Skybreaker Mortar Soldier (3)
(38689, 48.0), -- Skybreaker Rifleman (2)
(38690, 64.0), -- Skybreaker Rifleman (3)
(38691, 120.0), -- Skybreaker Sergeant (2)
(38692, 160.0), -- Skybreaker Sergeant (3)
(38693, 180.0), -- Skybreaker Sorcerer (2)
(38694, 240.0), -- Skybreaker Sorcerer (3)
(38699, 296.881012), -- The Skybreaker (2)
(38700, 395.841003), -- The Skybreaker (3)
(38701, 296.881012), -- Orgrim's Hammer (2)
(38702, 395.841003), -- Orgrim's Hammer (3)
(38711, 5.0), -- Bone Spike
(38712, 5.0), -- Bone Spike
(38717, 10.0), -- Alchemist Adrianna (1)
(38721, 100.0), -- Blazing Skeleton (2)
(38722, 150.0), -- Blazing Skeleton (3)
(38723, 75.0), -- Blistering Zombie (2)
(38724, 243.75), -- Gluttonous Abomination (2)
(38725, 75.0), -- Risen Archmage (2)
(38726, 15.0), -- Rot Worm (2)
(38727, 27.0), -- Suppresser (2)
(38733, 100.0), -- Blistering Zombie (3)
(38734, 325.0), -- Gluttonous Abomination (3)
(38735, 100.0), -- Risen Archmage (3)
(38736, 20.0), -- Rot Worm (3)
(38737, 36.0), -- Suppresser (3)
(38763, 1.25), -- Summoned Cadaver
(38769, 4860.0), -- Prince Keleseth (2)
(38770, 6480.0), -- Prince Keleseth (3)
(38771, 4860.0), -- Prince Taldaram (2)
(38772, 6480.0), -- Prince Taldaram (3)
(38773, 4860.0), -- Blood Orb Controller (2)
(38774, 6480.0), -- Blood Orb Controller (3)
(38775, 0.148358), -- Kinetic Bomb (1)
(38776, 0.222537), -- Kinetic Bomb (2)
(38777, 0.296716), -- Kinetic Bomb (3)
(38784, 4860.0), -- Prince Valanar (2)
(38785, 6480.0), -- Prince Valanar (3)
(38786, 225.0), -- Mutated Abomination (2)
(38787, 300.0), -- Mutated Abomination (3)
(38788, 187.5), -- Mutated Abomination (1)
(38789, 281.25), -- Mutated Abomination (2)
(38790, 375.0), -- Mutated Abomination (3)
(38831, 1.575), -- Slain Bluffwatcher
(38900, 1.05), -- Auctioneer Kavarn
(38905, 1.05), -- [PH] Grimtotem Vendor
(38906, 1.05), -- Auctioneer Sarnkin
(38919, 1.05), -- [PH] Grimtotem Banker
(38920, 1.05), -- [PH] Grimtotem Banker 2
(38921, 1.05), -- [PH] Grimtotem Banker 3
(38970, 10.0), -- Bone Spike (1)
(38971, 15.0), -- Bone Spike (2)
(38972, 20.0), -- Bone Spike (3)
(38973, 10.0), -- Bone Spike (1)
(38974, 15.0), -- Bone Spike (2)
(38975, 20.0), -- Bone Spike (3)
(39000, 45.0), -- Reanimated Adherent (2)
(39001, 60.0), -- Reanimated Adherent (3)
(39011, 0.0002), -- Martyr Stalker (Reputation) (1)
(39012, 0.0003), -- Martyr Stalker (Reputation) (2)
(39013, 0.0004), -- Martyr Stalker (Reputation) (3)
(39120, 110.0), -- Val'kyr Shadowguard (1)
(39121, 165.0), -- Val'kyr Shadowguard (2)
(39122, 220.0), -- Val'kyr Shadowguard (3)
(39158, 1.875), -- Phalanx 2.0
(39166, 8750.0), -- The Lich King (1)
(39167, 13125.0), -- The Lich King (2)
(39168, 17500.0), -- The Lich King (3)
(39190, 0.47619), -- Wicked Spirit
(39232, 4000.0), -- The Lich King (Temp) (1)
(39233, 6000.0), -- The Lich King (Temp) (2)
(39234, 8000.0), -- The Lich King (Temp) (3)
(39284, 31.746), -- Vile Spirit (1)
(39285, 47.618999), -- Vile Spirit (2)
(39286, 63.492001), -- Vile Spirit (3)
(39287, 0.95238), -- Wicked Spirit (1)
(39288, 1.42857), -- Wicked Spirit (2)
(39289, 1.90476), -- Wicked Spirit (3)
(39299, 573.682007), -- Shambling Horror (1)
(39300, 860.52301), -- Shambling Horror (2)
(39301, 1147.359985), -- Shambling Horror (3)
(39302, 380.95401), -- Raging Spirit (1)
(39303, 571.43103), -- Raging Spirit (2)
(39304, 761.90802), -- Raging Spirit (3)
(39305, 2.85714), -- Ice Sphere (1)
(39306, 4.28571), -- Ice Sphere (2)
(39307, 5.71428), -- Ice Sphere (3)
(39309, 80.0), -- Drudge Ghoul (1)
(39310, 120.0), -- Drudge Ghoul (2)
(39311, 160.0), -- Drudge Ghoul (3)
(39714, 10.0), -- Gnomish War-Walker
(39805, 594.0), -- General Zarithrian (1)
(39814, 16.5), -- Onyx Flamecaller
(39815, 60.5), -- Onyx Flamecaller (1)
(39823, 600.0), -- Saviana Ragefire (1)
(39864, 7540.0), -- Halion (1)
(39901, 10.8), -- Mekgineer Thermaplugg's Brag-Bot
(39920, 500.0), -- Baltharus the Warborn (1)
(39938, 1.5625), -- Twilight Seeker's Mount
(39944, 11310.0), -- Halion (2)
(39945, 15080.0), -- Halion (3)
(39973, 0.75), -- Swift Orange Mechanostrider
(40057, 0.75), -- Mekkatorque's Swift Blue Mechanostrider
(40142, 3770.0), -- Halion
(40143, 7540.0), -- Halion (1)
(40144, 11310.0), -- Halion (2)
(40145, 15080.0), -- Halion (3)
(40218, 0.93), -- Spy Frog Credit
(40257, 0.93), -- Troll Citizen
(40301, 0.93), -- Tiger Matriarch Credit
(40305, 10.0), -- Spirit of the Tiger

(40417, 55.0), -- Charscale Invoker
(40418, 110.0), -- Charscale Invoker (1)
(40419, 62.5), -- Charscale Assaulter
(40420, 125.0), -- Charscale Assaulter (1)
(40422, 160.0), -- Charscale Elite (1)
(40424, 160.0), -- Charscale Commander (1)
(40441, 1.072), -- Battered Brewmaster
(40470, 2.0), -- Orb Carrier
(40471, 3.0), -- Orb Carrier
(40472, 4.0), -- Orb Carrier
(40626, 187.5), -- Ruby Drakonid
(40627, 187.5), -- Ruby Drake
(40670, 2.7), -- Combustion (1)
(40671, 4.05), -- Combustion (2)
(40672, 5.4), -- Combustion (3)
(40673, 2.7), -- Consumption (1)
(40674, 4.05), -- Consumption (2)
(40675, 5.4), -- Consumption (3)
(40704, 1.25), -- Vrykul Proto-dragon Mount
(40842, 187.5), -- Ruby Drake
(40870, 195.0), -- Ruby Dragon
(41839, 0.93), -- [DND] Controller
(50074, 0.5), -- Thunder Orb
(50173, 2.0), -- Frenzied Ghoul
(50275, 1.5), -- Bailey Horrorhate
(50276, 1.5), -- Dar'danis
(50277, 1.5), -- Zim'chein
(50278, 1.5), -- Spi'ro
(50279, 1.5), -- Deathguard Bradforth
(50280, 1.5), -- Brother William
(50281, 1.5), -- Gustaf Blightflight
(50282, 1.5), -- Soridormi
(50283, 1.5), -- Patal the Mad
(50285, 1.575), -- Oko'une, Chosen of Lo'sho
(50286, 1.5), -- Chaplain Nysoni
(50287, 1.5), -- Norman Goldshire
(50288, 1.5), -- Qwi'spe the Wise
(50289, 1.5), -- Troes the Remover
(50290, 1.5), -- Krull Rocksmash
(50291, 1.5), -- Wanda Belezin
(50292, 1.5), -- Whisp the Silent
(50293, 1.5), -- Cadmus Emberblaze
(50294, 1.5), -- Baarelam of the Auchenai
(50295, 1.5), -- Amanda the Reaver
(50296, 1.5), -- Rol'joku
(50324, 1.5), -- Vanguard Gus
(50325, 1.5), -- Deacon Frost
(50326, 1.5), -- Huntress Naalia
(50327, 1.5), -- Sunspeaker Talethia
(50340, 1.5), -- Koby the Incinerator
(50341, 1.5), -- Hydriel Featherflight
(50342, 1.5), -- Katho Hammerfist
(50343, 1.5), -- Ko'rahl Fangshifter
(50344, 1.5), -- Flowzie the Fel-Touched
(55332, 0.5), -- Accursed Form
(56036, 0.0001), -- Shield Beacon
(56332, 0.5), -- Tank Worgen Form
(60063, 0.25), -- Standard of Valiance
(60064, 0.25), -- Standard of Valiance
(75133, 1.34), -- Gorn Axefist
(80061, 0.8375), -- Ameer Greatluck
(80420, 0.945), -- Talk to Ameer Greatluck Credit
(80421, 0.945), -- Talk to Tiraxis Credit
(80652, 0.945), -- LFG Mythic Dungeon Completed Credit
(81041, 0.945), -- LFG Heroic Dungeon Completed Credit
(81042, 0.945), -- LFG Normal Dungeon Completed Credit
(100242, 1.008), -- Sunwalker Thunderhorn
(178081, 800.0), -- Chromie
(310603, 0.0819), -- Electrified Water Elemental
(416000, 1.5625), -- Edrim Skysong
(421493, 1.5), -- Incarnation: Unleashed Golden Saberon
(499656, 200.0), -- Voidtalon of the Dark Star
(500589, 250.0), -- Defias Pillager
(501296, 1.5), -- Zul’raja the Harvester
(502760, 1.5), -- Grillok Morzog
(502770, 1.5), -- Niki Thesla
(502771, 1.5), -- Freja Stormbelch
(502772, 1.5), -- Q'ru
(502773, 1.5), -- Dabbert Staze
(502774, 1.575), -- Tooantuh Cloudtail
(502780, 1.5), -- Aheravara
(502790, 1.575), -- Motah Stonebreaker
(502791, 1.5), -- Den Sergeant Gormuk
(502800, 1.5), -- Thiduis Pride
(502801, 1.5), -- Elleora
(502803, 1.5), -- Vaelion Grandbell
(502810, 1.5), -- Wolfrider Yara
(502820, 1.5), -- Bieko
(502821, 1.5), -- Kaleidormu
(502822, 1.5), -- Quardormi
(502830, 1.5), -- Clippo Doomwhistle
(502831, 1.5), -- Saelina Shedana
(502832, 1.5), -- Rug'ra Witherhand
(502833, 1.5), -- Thaddeus Voidseeker
(502834, 1.575), -- Ultha Dreamharrow
(502850, 1.5), -- Landralanis
(502870, 1.5), -- Binkle Coldbolt
(502871, 1.5), -- Joro Rapidspyre
(502872, 1.5), -- Mekboy Parod
(502873, 1.5), -- Riley Jett
(502890, 1.5), -- Canni the Shade
(502891, 1.5), -- Undertaker Chite
(502900, 1.575), -- Amuwate Eagledream
(502910, 1.5), -- Murmon Fuseforge
(502911, 1.5), -- Raethere Daltrall
(502912, 1.5), -- Zina Glyphreader
(502913, 1.5), -- Wilhelm Balthier
(502920, 1.5), -- Aramadus
(502921, 1.5), -- Fleshweaver Chella
(502922, 1.5), -- Irina Valreed
(502923, 1.5), -- Halbert the Scoundrel
(502924, 1.5), -- Ophana Gloom
(502925, 1.5), -- Kragar the Reanimator
(502930, 1.5), -- Dornall Plagueweaver
(502950, 1.575), -- Galak Twoclubs
(502952, 1.5), -- Grelin Ironbeard
(502953, 1.5), -- Mu'kaka
(502960, 1.5), -- Doctor Yara
(503240, 1.5), -- Nerdris Darkstrike
(503241, 1.5), -- Kharzon the Hammer
(503250, 1.69), -- Darkslayer Harrendor
(503271, 1.5), -- Cleric Stonelight
(503400, 1.5), -- Debbie Whirlyflame
(503402, 1.5), -- Grishnakh Searscar
(503403, 1.64062), -- Apprentice Yahk Loregrain
(503410, 1.5), -- Owen of Moonbrook
(503411, 1.5), -- Baruhr Mightmane
(503420, 1.5), -- Prim'ula
(503923, 1.5), -- Jefferson Lively
(503924, 1.5), -- Baralor Oathbreaker
(503925, 1.5), -- Deathmagus Gorat
(503930, 1.5), -- Kobidus the Lich
(512912, 1.5), -- Go'hro
(557911, 0.26), -- Soulstone Lure
(600242, 0.96), -- Sunwalker Modae
(600292, 1.5), -- Sofiya Taylor
(600344, 1.5), -- Pelinor Felsight
(602760, 1.5), -- Xantis the Slayer
(602770, 1.5), -- Viktor Thunder-Eye
(602771, 1.5), -- Kharaz Dak
(602772, 1.5), -- Pak Thunderhoof
(602773, 1.5), -- Harold Garett
(602780, 1.5), -- Zeltur'atha the Exile
(602781, 1.5), -- Galgrimorth
(602790, 1.5), -- Gohok Bighoof
(602791, 1.5), -- Grunt Korthaka
(602800, 1.5), -- Yelya Flinthammer
(602801, 1.5), -- Corinthia the Templar
(602803, 1.5), -- Benjamin the Sinless
(602810, 1.5), -- Grok-gar
(602821, 1.5), -- Belladormi
(602822, 1.5), -- Nyrmedormi
(602830, 1.5), -- Dippo the Doomer
(602831, 1.5), -- Soliras Darkwoven
(602832, 1.5), -- Rokia Lohka
(602833, 1.5), -- Vytalas the Dreamer
(602834, 1.5), -- Wuyi Thunderhoof
(602835, 1.5), -- Gerald the Demented
(602850, 1.5), -- Fal'ador Yanille
(602870, 1.5), -- Zipgear Zoombang
(602871, 1.5), -- Baarus the Tinker
(602872, 1.5), -- Engineer Rothakk
(602873, 1.5), -- Ol' Jimbles
(602890, 1.5), -- Turalen Darkwhisper
(602891, 1.5), -- Sidus the Soul-Collector
(602900, 1.5), -- Ear-he Stonehoof
(602910, 1.5), -- Beelo Blitzcog
(602911, 1.5), -- Shayla Runewander
(602912, 1.5), -- Washu Zebuljin
(602913, 1.5), -- Thalen Mackenzie
(602920, 1.5), -- Lokirus Veinspiller
(602921, 1.5), -- Sul'natu Hearteater
(602922, 1.5), -- Belinaros Cicero
(602950, 1.5), -- Thokor Galanthoof
(602952, 1.5), -- Modor Tarmund
(602953, 1.5), -- Zulaka'jin
(602960, 1.5), -- The Great Yumbabo
(603241, 1.5), -- Dagnan the Blade
(603271, 1.5), -- Sunbeard the Pious
(603400, 1.5), -- Penny Pyrewhistle
(603402, 1.5), -- Murthakk Krulk
(603410, 1.5), -- Phoebe Lakewander
(612912, 1.5), -- Kodor the Seer
(650275, 1.5), -- Phineas the Fervent
(650276, 1.5), -- Thimakria Dilanore
(650277, 1.5), -- Darakka Stormsworn
(650278, 1.5), -- Xevaroth
(650279, 1.5), -- Deathguard Solor
(650280, 1.5), -- Brother Faren
(650281, 1.5), -- Sigi Mikayla
(650282, 1.5), -- Yisdormi
(650285, 1.5), -- Zoona
(650286, 1.5), -- Crusader Natalie
(650287, 1.5), -- James Randal
(650288, 1.5), -- Wun'zujek
(650289, 1.5), -- Wilfred Soulcatcher
(650290, 1.5), -- Thako Maz
(650291, 1.5), -- Balthazar Marone
(650293, 1.5), -- Ridley of Lordaeron
(650295, 1.5), -- Connor the Barbarian
(650296, 1.5), -- Zerin'dai
(650324, 1.5), -- Kalanaros the Bard
(650325, 1.5), -- Talvin
(650326, 1.5), -- Moonpriest Ty'lera
(650327, 1.5), -- Lightspeaker Shaylan
(650340, 1.5), -- Michael Pietrus
(650341, 1.5), -- Surellion Trueshot
(650342, 1.5), -- Threllin the Bearded
(650688, 1.5625), -- Apothecary Kelan
(685032, 0.93), -- Invisible Dummy (Starcaller1)
(685033, 0.93), -- Invisible Dummy (Starcaller2)
(840002, 0.5), -- Spirit of Life
(9780012, 6.98119), -- Guardian of Time
(9990001, 1.25), -- Teri Glozilk
(10157257, 1.05); -- Stony Tark

UPDATE `creature_template` AS `template`
INNER JOIN `_coa_captured_creature_health` AS `captured` ON `captured`.`entry` = `template`.`entry`
INNER JOIN `creature_classlevelstats` AS `stats`
    ON `stats`.`level` = `template`.`maxlevel` AND `stats`.`class` = `template`.`unit_class`
SET `template`.`HealthModifier` = `captured`.`HealthModifier`
WHERE `template`.`HealthModifier` <> `captured`.`HealthModifier`
    AND `template`.`exp` IN (0, 1, 2)
    AND CEIL(`captured`.`HealthModifier` * CASE `template`.`exp`
        WHEN 0 THEN `stats`.`basehp0`
        WHEN 1 THEN GREATEST(`stats`.`basehp0`, `stats`.`basehp1`)
        WHEN 2 THEN GREATEST(`stats`.`basehp0`, `stats`.`basehp1`, `stats`.`basehp2`)
        ELSE 4294967296
    END) BETWEEN 1 AND 4294967295;

-- PR #6477 copies these six Normal templates for its provisional Heroic/Mythic fallback.
-- Sync only variants still using the copied old modifier, regardless of migration application order.
UPDATE `creature_template` AS `variant`
INNER JOIN `creature_template` AS `template`
    ON `variant`.`entry` IN (`template`.`difficulty_entry_1`, `template`.`difficulty_entry_2`)
INNER JOIN `_coa_captured_creature_health` AS `captured` ON `captured`.`entry` = `template`.`entry`
INNER JOIN `creature_classlevelstats` AS `stats`
    ON `stats`.`level` = `variant`.`maxlevel` AND `stats`.`class` = `variant`.`unit_class`
SET `variant`.`HealthModifier` = `captured`.`HealthModifier`
WHERE `template`.`entry` IN (8580, 14516, 16042, 16080, 16097, 16118)
    AND `variant`.`entry` IN (`template`.`entry` + 100000, `template`.`entry` + 200000)
    AND `variant`.`HealthModifier` = CASE `template`.`entry`
        WHEN 8580 THEN 7.5
        WHEN 14516 THEN 15
        WHEN 16042 THEN 45
        WHEN 16080 THEN 19
        WHEN 16097 THEN 10
        WHEN 16118 THEN 15
    END
    AND `variant`.`exp` IN (0, 1, 2)
    AND CEIL(`captured`.`HealthModifier` * CASE `variant`.`exp`
        WHEN 0 THEN `stats`.`basehp0`
        WHEN 1 THEN GREATEST(`stats`.`basehp0`, `stats`.`basehp1`)
        WHEN 2 THEN GREATEST(`stats`.`basehp0`, `stats`.`basehp1`, `stats`.`basehp2`)
        ELSE 4294967296
    END) BETWEEN 1 AND 4294967295;

DROP TEMPORARY TABLE `_coa_captured_creature_health`;
