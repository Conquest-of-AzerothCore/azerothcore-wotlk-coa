-- CoA "Realm First! Level 60/70 <Race> [<Class>]" achievements advertise their race's CharTitles title in
-- Achievement.dbc ("Title Reward: ...") but only two of them had an `achievement_reward` row, so completing the rest
-- granted no title. Each race maps to one title for both factions; the achievement's own criterion
-- (S_PLAYER_CLASS_RACE) already restricts it to that race. The Night Elf Reaper and Undead Witch Hunter rows are
-- in rev_20261028_10_coa_realm_first_race_class_titles.sql.
-- Titles: 110 Quel'Thalas, 111 Argus, 112 Khaz Modan, 113 Gnomeregan, 114 Lion Hearted, 115 Champion of Elune,
-- 116 Hero of Orgrimmar, 117 Plainsrunner, 118 Darkspear, 119 the Forsaken.
DELETE FROM `achievement_reward` WHERE `ID` IN (
5654, 5660, 5666, 5672, 5678, 5684, 5690, 5696, 5702, 5708, 13024, 13025, 13026, 13027, 13028, 13029, 13030,
13031, 13032, 13033, 86021, 86022, 86023, 86024, 86025, 86026, 86027, 86028, 86029, 86030, 86031, 86032,
86033, 86034, 86035, 86036, 86037, 86038, 86039, 86040, 86041, 86042, 86043, 86044, 86045, 86046, 86047,
86048, 86049, 86050, 86051, 86052, 86053, 86054, 86055, 86057, 86058, 86059, 86060, 86061, 86062, 86063,
86064, 86065, 86066, 86067, 86068, 86069, 86070, 86071, 86072, 86073, 86074, 86075, 86076, 86077, 86078,
86079, 86080, 86081, 86082, 86083, 86084, 86085, 86086, 86087, 86088, 86089, 86090, 86091, 86092, 86093,
86094, 86095, 86096, 86097, 86098, 86099, 86100, 86101, 86102, 86103, 86104, 86105, 86106, 86107, 86108,
86109, 86110, 86111, 86112, 86113, 86114, 86115, 86116, 86117, 86118, 86119, 86120, 86121, 86122, 86123,
86124, 86125, 86126, 86127, 86128, 86129, 86130, 86131, 86132, 86133, 86134, 86135, 86136, 86137, 86138,
86139, 86140, 86141, 86142, 86143, 86144, 86145, 86146, 86147, 86148, 86149, 86150, 86151, 86152, 86153,
86154, 86155, 86156, 86157, 86158, 86159, 86160, 86161, 86162, 86163, 86164, 86165, 86166, 86167, 86168,
86169, 86170, 86171, 86172, 86173, 86174, 86175, 86176, 86177, 86178, 86179, 86180, 86181, 86182, 86183,
86184, 86185, 86186, 86187, 86188, 86189, 86190, 86191, 86192, 86193, 86194, 86195, 86196, 86197, 86198,
86199, 86200, 86201, 86202, 86203, 86204, 86205, 86206, 86208, 86209, 86210, 86211, 86212, 86213, 86214,
86215, 86216, 86217, 86218, 86219, 86220, 86221, 86222, 86223, 86224, 86225, 86226, 86227, 86228, 86229,
86230, 150106, 150112, 150118, 150124, 150130, 150136, 150142, 150148, 150154, 150160, 150161, 150162,
150163, 150164, 150165, 150166, 150167, 150168, 150169, 150170, 150306, 150312, 150318, 150324, 150330,
150336, 150342, 150348, 150354, 150360, 150361, 150362, 150363, 150364, 150365, 150366, 150367, 150368,
150369, 150370, 150506, 150512, 150518, 150524, 150530, 150536, 150542, 150548, 150554, 150560, 150561,
150562, 150563, 150564, 150565, 150566, 150567, 150568, 150569, 150570, 150706, 150712, 150718, 150724,
150730, 150736, 150742, 150748, 150754, 150760, 150761, 150762, 150763, 150764, 150765, 150766, 150767,
150768, 150769, 150770, 150906, 150912, 150918, 150924, 150930, 150936, 150942, 150948, 150954, 150960,
150961, 150962, 150963, 150964, 150965, 150966, 150967, 150968, 150969, 150970, 151106, 151112, 151118,
151124, 151130, 151136, 151142, 151148, 151154, 151160, 151161, 151162, 151163, 151164, 151165, 151166,
151167, 151168, 151169, 151170, 151306, 151312, 151318, 151324, 151330, 151336, 151342, 151348, 151354,
151360, 151361, 151362, 151363, 151364, 151365, 151366, 151367, 151368, 151369, 151370, 151506, 151512,
151518, 151524, 151530, 151536, 151542, 151548, 151554, 151560, 151561, 151562, 151563, 151564, 151565,
151566, 151567, 151568, 151569, 151570, 151706, 151712, 151718, 151724, 151730, 151736, 151742, 151748,
151754, 151760, 151761, 151762, 151763, 151764, 151765, 151766, 151767, 151768, 151769, 151770, 151906,
151912, 151918, 151924, 151930, 151936, 151942, 151948, 151954, 151960, 151961, 151962, 151963, 151964,
151965, 151966, 151967, 151968, 151969, 151970);
INSERT INTO `achievement_reward` (`ID`, `TitleA`, `TitleH`, `ItemID`, `Sender`, `Subject`, `Body`,
    `MailTemplateID`) VALUES
(5654, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome
(5660, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf
(5666, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human
(5672, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf
(5678, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc
(5684, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren
(5690, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll
(5696, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken
(5702, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf
(5708, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei
(13024, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome
(13025, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf
(13026, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human
(13027, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf
(13028, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc
(13029, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren
(13030, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll
(13031, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken
(13032, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf
(13033, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei
(86021, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Barbarian
(86022, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Barbarian
(86023, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Barbarian
(86024, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Barbarian
(86025, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Barbarian
(86026, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Barbarian
(86027, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Barbarian
(86028, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Barbarian
(86029, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Barbarian
(86030, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Barbarian
(86031, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Witch Doctor
(86032, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Witch Doctor
(86033, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Witch Doctor
(86034, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Witch Doctor
(86035, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Witch Doctor
(86036, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Witch Doctor
(86037, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Witch Doctor
(86038, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Witch Doctor
(86039, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Witch Doctor
(86040, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Witch Doctor
(86041, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Felsworn
(86042, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Felsworn
(86043, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Felsworn
(86044, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Felsworn
(86045, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Felsworn
(86046, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Felsworn
(86047, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Felsworn
(86048, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Felsworn
(86049, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Felsworn
(86050, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Felsworn
(86051, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Witch Hunter
(86052, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Witch Hunter
(86053, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Witch Hunter
(86054, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Witch Hunter
(86055, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Witch Hunter
(86057, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Witch Hunter
(86058, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Witch Hunter
(86059, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Witch Hunter
(86060, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Witch Hunter
(86061, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Stormbringer
(86062, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Stormbringer
(86063, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Stormbringer
(86064, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Stormbringer
(86065, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Stormbringer
(86066, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Stormbringer
(86067, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Stormbringer
(86068, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Stormbringer
(86069, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Stormbringer
(86070, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Stormbringer
(86071, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Knight of Xoroth
(86072, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Knight of Xoroth
(86073, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Knight of Xoroth
(86074, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Knight of Xoroth
(86075, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Knight of Xoroth
(86076, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Knight of Xoroth
(86077, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Knight of Xoroth
(86078, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Knight of Xoroth
(86079, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Knight of Xoroth
(86080, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Knight of Xoroth
(86081, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Guardian
(86082, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Guardian
(86083, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Guardian
(86084, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Guardian
(86085, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Guardian
(86086, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Guardian
(86087, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Guardian
(86088, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Guardian
(86089, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Guardian
(86090, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Guardian
(86091, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Templar
(86092, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Templar
(86093, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Templar
(86094, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Templar
(86095, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Templar
(86096, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Templar
(86097, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Templar
(86098, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Templar
(86099, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Templar
(86100, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Templar
(86101, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Son of Arugal
(86102, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Son of Arugal
(86103, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Son of Arugal
(86104, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Son of Arugal
(86105, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Son of Arugal
(86106, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Son of Arugal
(86107, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Son of Arugal
(86108, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Son of Arugal
(86109, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Son of Arugal
(86110, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Son of Arugal
(86111, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Ranger
(86112, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Ranger
(86113, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Ranger
(86114, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Ranger
(86115, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Ranger
(86116, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Ranger
(86117, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Ranger
(86118, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Ranger
(86119, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Ranger
(86120, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Ranger
(86121, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Chronomancer
(86122, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Chronomancer
(86123, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Chronomancer
(86124, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Chronomancer
(86125, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Chronomancer
(86126, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Chronomancer
(86127, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Chronomancer
(86128, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Chronomancer
(86129, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Chronomancer
(86130, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Chronomancer
(86131, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Necromancer
(86132, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Necromancer
(86133, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Necromancer
(86134, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Necromancer
(86135, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Necromancer
(86136, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Necromancer
(86137, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Necromancer
(86138, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Necromancer
(86139, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Necromancer
(86140, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Necromancer
(86141, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Pyromancer
(86142, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Pyromancer
(86143, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Pyromancer
(86144, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Pyromancer
(86145, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Pyromancer
(86146, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Pyromancer
(86147, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Pyromancer
(86148, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Pyromancer
(86149, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Pyromancer
(86150, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Pyromancer
(86151, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Cultist
(86152, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Cultist
(86153, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Cultist
(86154, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Cultist
(86155, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Cultist
(86156, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Cultist
(86157, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Cultist
(86158, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Cultist
(86159, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Cultist
(86160, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Cultist
(86161, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Starcaller
(86162, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Starcaller
(86163, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Starcaller
(86164, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Starcaller
(86165, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Starcaller
(86166, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Starcaller
(86167, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Starcaller
(86168, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Starcaller
(86169, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Starcaller
(86170, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Starcaller
(86171, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Sun Cleric
(86172, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Sun Cleric
(86173, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Sun Cleric
(86174, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Sun Cleric
(86175, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Sun Cleric
(86176, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Sun Cleric
(86177, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Sun Cleric
(86178, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Sun Cleric
(86179, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Sun Cleric
(86180, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Sun Cleric
(86181, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Tinker
(86182, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Tinker
(86183, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Tinker
(86184, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Tinker
(86185, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Tinker
(86186, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Tinker
(86187, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Tinker
(86188, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Tinker
(86189, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Tinker
(86190, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Tinker
(86191, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Venomancer
(86192, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Venomancer
(86193, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Venomancer
(86194, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Venomancer
(86195, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Venomancer
(86196, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Venomancer
(86197, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Venomancer
(86198, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Venomancer
(86199, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Venomancer
(86200, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Venomancer
(86201, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Reaper
(86202, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Reaper
(86203, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Reaper
(86204, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Reaper
(86205, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Reaper
(86206, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Reaper
(86208, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Reaper
(86209, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Reaper
(86210, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Reaper
(86211, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Primalist
(86212, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Primalist
(86213, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Primalist
(86214, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Primalist
(86215, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Primalist
(86216, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Primalist
(86217, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Primalist
(86218, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Primalist
(86219, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Primalist
(86220, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Primalist
(86221, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Runemaster
(86222, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Runemaster
(86223, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Runemaster
(86224, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Runemaster
(86225, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Runemaster
(86226, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Undead Runemaster
(86227, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Runemaster
(86228, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Runemaster
(86229, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Runemaster
(86230, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Runemaster
(150106, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Rogue
(150112, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Rogue
(150118, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Rogue
(150124, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Rogue
(150130, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Rogue
(150136, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Rogue
(150142, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Rogue
(150148, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Rogue
(150154, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Rogue
(150160, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Rogue
(150161, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Rogue
(150162, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Rogue
(150163, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Rogue
(150164, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Rogue
(150165, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Rogue
(150166, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Rogue
(150167, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Rogue
(150168, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Rogue
(150169, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Rogue
(150170, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Rogue
(150306, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Warrior
(150312, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Warrior
(150318, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Warrior
(150324, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Warrior
(150330, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Warrior
(150336, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Warrior
(150342, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Warrior
(150348, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Warrior
(150354, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Warrior
(150360, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Warrior
(150361, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Warrior
(150362, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Warrior
(150363, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Warrior
(150364, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Warrior
(150365, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Warrior
(150366, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Warrior
(150367, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Warrior
(150368, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Warrior
(150369, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Warrior
(150370, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Warrior
(150506, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Paladin
(150512, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Paladin
(150518, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Paladin
(150524, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Paladin
(150530, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Paladin
(150536, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Paladin
(150542, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Paladin
(150548, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Paladin
(150554, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Paladin
(150560, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Paladin
(150561, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Paladin
(150562, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Paladin
(150563, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Paladin
(150564, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Paladin
(150565, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Paladin
(150566, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Paladin
(150567, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Paladin
(150568, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Paladin
(150569, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Paladin
(150570, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Paladin
(150706, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Hunter
(150712, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Hunter
(150718, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Hunter
(150724, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Hunter
(150730, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Hunter
(150736, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Hunter
(150742, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Hunter
(150748, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Hunter
(150754, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Hunter
(150760, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Hunter
(150761, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Hunter
(150762, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Hunter
(150763, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Hunter
(150764, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Hunter
(150765, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Hunter
(150766, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Hunter
(150767, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Hunter
(150768, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Hunter
(150769, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Hunter
(150770, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Hunter
(150906, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Priest
(150912, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Priest
(150918, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Priest
(150924, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Priest
(150930, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Priest
(150936, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Priest
(150942, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Priest
(150948, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Priest
(150954, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Priest
(150960, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Priest
(150961, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Priest
(150962, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Priest
(150963, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Priest
(150964, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Priest
(150965, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Priest
(150966, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Priest
(150967, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Priest
(150968, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Priest
(150969, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Priest
(150970, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Priest
(151106, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Death Knight
(151112, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Death Knight
(151118, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Death Knight
(151124, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Death Knight
(151130, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Death Knight
(151136, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Death Knight
(151142, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Death Knight
(151148, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Death Knight
(151154, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Death Knight
(151160, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Death Knight
(151161, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Death Knight
(151162, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Death Knight
(151163, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Death Knight
(151164, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Death Knight
(151165, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Death Knight
(151166, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Death Knight
(151167, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Death Knight
(151168, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Death Knight
(151169, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Death Knight
(151170, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Death Knight
(151306, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Shaman
(151312, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Shaman
(151318, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Shaman
(151324, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Shaman
(151330, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Shaman
(151336, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Shaman
(151342, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Shaman
(151348, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Shaman
(151354, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Shaman
(151360, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Shaman
(151361, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Shaman
(151362, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Shaman
(151363, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Shaman
(151364, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Shaman
(151365, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Shaman
(151366, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Shaman
(151367, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Shaman
(151368, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Shaman
(151369, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Shaman
(151370, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Shaman
(151506, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Mage
(151512, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Mage
(151518, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Mage
(151524, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Mage
(151530, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Mage
(151536, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Mage
(151542, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Mage
(151548, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Mage
(151554, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Mage
(151560, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Mage
(151561, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Mage
(151562, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Mage
(151563, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Mage
(151564, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Mage
(151565, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Mage
(151566, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Mage
(151567, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Mage
(151568, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Mage
(151569, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Mage
(151570, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Mage
(151706, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Warlock
(151712, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Warlock
(151718, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Warlock
(151724, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Warlock
(151730, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Warlock
(151736, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Warlock
(151742, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Warlock
(151748, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Warlock
(151754, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Warlock
(151760, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Warlock
(151761, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Warlock
(151762, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Warlock
(151763, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Warlock
(151764, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Warlock
(151765, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Warlock
(151766, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Warlock
(151767, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Warlock
(151768, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Warlock
(151769, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Warlock
(151770, 111, 111, 0, 0, NULL, NULL, 0), -- Level 70 Draenei Warlock
(151906, 113, 113, 0, 0, NULL, NULL, 0), -- Level 60 Gnome Druid
(151912, 112, 112, 0, 0, NULL, NULL, 0), -- Level 60 Dwarf Druid
(151918, 114, 114, 0, 0, NULL, NULL, 0), -- Level 60 Human Druid
(151924, 115, 115, 0, 0, NULL, NULL, 0), -- Level 60 Night Elf Druid
(151930, 116, 116, 0, 0, NULL, NULL, 0), -- Level 60 Orc Druid
(151936, 117, 117, 0, 0, NULL, NULL, 0), -- Level 60 Tauren Druid
(151942, 118, 118, 0, 0, NULL, NULL, 0), -- Level 60 Troll Druid
(151948, 119, 119, 0, 0, NULL, NULL, 0), -- Level 60 Forsaken Druid
(151954, 110, 110, 0, 0, NULL, NULL, 0), -- Level 60 Blood Elf Druid
(151960, 111, 111, 0, 0, NULL, NULL, 0), -- Level 60 Draenei Druid
(151961, 113, 113, 0, 0, NULL, NULL, 0), -- Level 70 Gnome Druid
(151962, 112, 112, 0, 0, NULL, NULL, 0), -- Level 70 Dwarf Druid
(151963, 114, 114, 0, 0, NULL, NULL, 0), -- Level 70 Human Druid
(151964, 115, 115, 0, 0, NULL, NULL, 0), -- Level 70 Night Elf Druid
(151965, 116, 116, 0, 0, NULL, NULL, 0), -- Level 70 Orc Druid
(151966, 117, 117, 0, 0, NULL, NULL, 0), -- Level 70 Tauren Druid
(151967, 118, 118, 0, 0, NULL, NULL, 0), -- Level 70 Troll Druid
(151968, 119, 119, 0, 0, NULL, NULL, 0), -- Level 70 Forsaken Druid
(151969, 110, 110, 0, 0, NULL, NULL, 0), -- Level 70 Blood Elf Druid
(151970, 111, 111, 0, 0, NULL, NULL, 0); -- Level 70 Draenei Druid
