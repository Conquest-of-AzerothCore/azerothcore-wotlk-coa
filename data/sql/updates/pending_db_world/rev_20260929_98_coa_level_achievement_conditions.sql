-- Ascension names the class, race and game mode of its reach-level achievements ("Level 60 Barbarian",
-- "Realm First! Level 60 Human", "WildCard Level 60") but Achievement_Criteria.dbc only asks for the level,
-- so every character reaching a level earned all of them. Class and race become S_PLAYER_CLASS_RACE data like
-- the stock realm-first rows; game modes a scripted check of the character's game mode mask.
-- Generated from Achievement.dbc and Achievement_Criteria.dbc by apps/coa-wildcard/level_achievement_conditions.py.
DELETE FROM `achievement_criteria_data` WHERE `type` = 21 AND `criteria_id` IN (
15449, 15455, 15461, 15467, 15473, 15479, 15485, 15491, 15497, 15503, 21449, 21455, 21461, 21467,
21473, 21479, 21485, 21491, 21497, 21503, 26338, 26339, 26340, 26341, 26342, 26343, 26344, 26345,
26346, 26347, 28338, 28339, 28340, 28341, 28342, 28343, 28344, 28345, 28346, 28347, 29449, 29455,
29461, 29467, 29473, 29479, 29485, 29491, 29497, 29503, 86000, 86001, 86002, 86003, 86004, 86005,
86006, 86007, 86008, 86009, 86010, 86011, 86012, 86013, 86014, 86015, 86016, 86017, 86018, 86019,
86020, 86021, 86022, 86023, 86024, 86025, 86026, 86027, 86028, 86029, 86030, 86031, 86032, 86033,
86034, 86035, 86036, 86037, 86038, 86039, 86040, 86041, 86042, 86043, 86044, 86045, 86046, 86047,
86048, 86049, 86050, 86051, 86052, 86053, 86054, 86055, 86056, 86057, 86058, 86059, 86060, 86061,
86062, 86063, 86064, 86065, 86066, 86067, 86068, 86069, 86070, 86071, 86072, 86073, 86074, 86075,
86076, 86077, 86078, 86079, 86080, 86081, 86082, 86083, 86084, 86085, 86086, 86087, 86088, 86089,
86090, 86091, 86092, 86093, 86094, 86095, 86096, 86097, 86098, 86099, 86100, 86101, 86102, 86103,
86104, 86105, 86106, 86107, 86108, 86109, 86110, 86111, 86112, 86113, 86114, 86115, 86116, 86117,
86118, 86119, 86120, 86121, 86122, 86123, 86124, 86125, 86126, 86127, 86128, 86129, 86130, 86131,
86132, 86133, 86134, 86135, 86136, 86137, 86138, 86139, 86140, 86141, 86142, 86143, 86144, 86145,
86146, 86147, 86148, 86149, 86150, 86151, 86152, 86153, 86154, 86155, 86156, 86157, 86158, 86159,
86160, 86161, 86162, 86163, 86164, 86165, 86166, 86167, 86168, 86169, 86170, 86171, 86172, 86173,
86174, 86175, 86176, 86177, 86178, 86179, 86180, 86181, 86182, 86183, 86184, 86185, 86186, 86187,
86188, 86189, 86190, 86191, 86192, 86193, 86194, 86195, 86196, 86197, 86198, 86199, 86200, 86201,
86202, 86203, 86204, 86205, 86206, 86207, 86208, 86209, 86210, 86211, 86212, 86213, 86214, 86215,
86216, 86217, 86218, 86219, 86220, 86221, 86222, 86223, 86224, 86225, 86226, 86227, 86228, 86229,
86230, 86500, 86501, 86502, 86503, 86504, 86505, 86506, 86507, 86508, 86509, 86510, 86511, 86512,
86513, 86514, 86515, 86516, 86517, 86518, 86519, 86520, 149991, 149992, 149993, 149994, 149995, 149996,
149997, 149998, 149999, 150000, 150001, 150002, 150003, 150004, 150005, 150006, 150007, 150008, 150009, 150010,
150106, 150112, 150118, 150124, 150130, 150136, 150142, 150148, 150154, 150160, 150161, 150162, 150163, 150164,
150165, 150166, 150167, 150168, 150169, 150170, 150306, 150312, 150318, 150324, 150330, 150336, 150342, 150348,
150354, 150360, 150361, 150362, 150363, 150364, 150365, 150366, 150367, 150368, 150369, 150370, 150506, 150512,
150518, 150524, 150530, 150536, 150542, 150548, 150554, 150560, 150561, 150562, 150563, 150564, 150565, 150566,
150567, 150568, 150569, 150570, 150706, 150712, 150718, 150724, 150730, 150736, 150742, 150748, 150754, 150760,
150761, 150762, 150763, 150764, 150765, 150766, 150767, 150768, 150769, 150770, 150906, 150912, 150918, 150924,
150930, 150936, 150942, 150948, 150954, 150960, 150961, 150962, 150963, 150964, 150965, 150966, 150967, 150968,
150969, 150970, 151106, 151112, 151118, 151124, 151130, 151136, 151142, 151148, 151154, 151160, 151161, 151162,
151163, 151164, 151165, 151166, 151167, 151168, 151169, 151170, 151306, 151312, 151318, 151324, 151330, 151336,
151342, 151348, 151354, 151360, 151361, 151362, 151363, 151364, 151365, 151366, 151367, 151368, 151369, 151370,
151506, 151512, 151518, 151524, 151530, 151536, 151542, 151548, 151554, 151560, 151561, 151562, 151563, 151564,
151565, 151566, 151567, 151568, 151569, 151570, 151706, 151712, 151718, 151724, 151730, 151736, 151742, 151748,
151754, 151760, 151761, 151762, 151763, 151764, 151765, 151766, 151767, 151768, 151769, 151770, 151906, 151912,
151918, 151924, 151930, 151936, 151942, 151948, 151954, 151960, 151961, 151962, 151963, 151964, 151965, 151966,
151967, 151968, 151969, 151970, 312828, 312829, 312830, 312831, 312832, 312833, 312834, 312835, 312836, 312837,
312838, 312839, 312840, 312841, 312842, 312843, 312844, 312845, 312846, 312847, 312848, 312849, 312850, 312851,
312852, 312853, 312854, 312855, 312856, 312857, 312858, 312859, 312860, 312861, 312862, 312863, 312864, 312865,
312866, 312867, 312868, 312869, 312870, 312871, 312872, 312873, 312874, 312875, 312876, 312877, 312878, 312879,
312880);
DELETE FROM `achievement_criteria_data` WHERE `type` = 11 AND `criteria_id` IN (
15443, 15449, 15455, 15461, 15467, 15473, 15479, 15485, 15491, 15497, 15503, 15551, 15552, 15553,
15554, 15555, 15556, 17328, 17329, 17330, 17331, 18000, 18001, 18551, 18552, 18553, 18554, 18555,
18556, 20320, 20321, 20322, 20325, 21551, 21552, 21553, 21554, 21555, 21556, 23323, 23324, 23325,
23326, 23327, 26348, 26349, 26350, 26351, 26352, 26353, 26354, 28337, 28338, 28339, 28340, 28341,
28342, 28343, 28344, 28345, 28346, 28347, 28348, 28349, 28350, 28351, 28352, 28353, 28354, 28800,
29443, 29449, 29455, 29461, 29467, 29473, 29479, 29485, 29491, 29497, 29503, 31658);
INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`) VALUES
(15443, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60
(15449, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Gnome
(15449, 21, 0, 7, ''), -- Realm First! WildCard Level 60 Gnome
(15455, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Dwarf
(15455, 21, 0, 3, ''), -- Realm First! WildCard Level 60 Dwarf
(15461, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Human
(15461, 21, 0, 1, ''), -- Realm First! WildCard Level 60 Human
(15467, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Night Elf
(15467, 21, 0, 4, ''), -- Realm First! WildCard Level 60 Night Elf
(15473, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Orc
(15473, 21, 0, 2, ''), -- Realm First! WildCard Level 60 Orc
(15479, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Tauren
(15479, 21, 0, 6, ''), -- Realm First! WildCard Level 60 Tauren
(15485, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Troll
(15485, 21, 0, 8, ''), -- Realm First! WildCard Level 60 Troll
(15491, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Forsaken
(15491, 21, 0, 5, ''), -- Realm First! WildCard Level 60 Forsaken
(15497, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Blood Elf
(15497, 21, 0, 10, ''), -- Realm First! WildCard Level 60 Blood Elf
(15503, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Realm First! WildCard Level 60 Draenei
(15503, 21, 0, 11, ''), -- Realm First! WildCard Level 60 Draenei
(15551, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- WildCard Level 10
(15552, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- WildCard Level 20
(15553, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- WildCard Level 30
(15554, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- WildCard Level 40
(15555, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- WildCard Level 50
(15556, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- WildCard Level 60
(17328, 11, 0, 0, 'achievement_coa_game_mode_resolute'), -- Realm First! Absolute Resolve
(17329, 11, 0, 0, 'achievement_coa_game_mode_ironman'), -- Realm First! Ironman Level 60
(17330, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute'), -- Realm First! Resolute Ironman Level 60
(17331, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute'), -- Resolute Ironman Level 60
(18000, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Nightmare Mode: Level 60
(18001, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute_nightmare'), -- Nightmare Mode: Resolute Ironman Level 60
(18551, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 10
(18552, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 20
(18553, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 30
(18554, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 40
(18555, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 50
(18556, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 60
(20320, 11, 0, 0, 'achievement_coa_game_mode_ironman'), -- Ironman Level 60
(20321, 11, 0, 0, 'achievement_coa_game_mode_survivalist'), -- Survivalist Level 60
(20322, 11, 0, 0, 'achievement_coa_game_mode_ironman'), -- [High Risk] Ironman Level 60
(20325, 11, 0, 0, 'achievement_coa_game_mode_resolute'), -- Absolute Resolve
(21449, 21, 0, 7, ''), -- Realm First! Level 60 Gnome
(21455, 21, 0, 3, ''), -- Realm First! Level 60 Dwarf
(21461, 21, 0, 1, ''), -- Realm First! Level 60 Human
(21467, 21, 0, 4, ''), -- Realm First! Level 60 Night Elf
(21473, 21, 0, 2, ''), -- Realm First! Level 60 Orc
(21479, 21, 0, 6, ''), -- Realm First! Level 60 Tauren
(21485, 21, 0, 8, ''), -- Realm First! Level 60 Troll
(21491, 21, 0, 5, ''), -- Realm First! Level 60 Forsaken
(21497, 21, 0, 10, ''), -- Realm First! Level 60 Blood Elf
(21503, 21, 0, 11, ''), -- Realm First! Level 60 Draenei
(21551, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 10
(21552, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 20
(21553, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 30
(21554, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 40
(21555, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 50
(21556, 11, 0, 0, 'achievement_coa_game_mode_draft'), -- Draft Level 60
(23323, 11, 0, 0, 'achievement_coa_game_mode_felforged'), -- Entered Felforged
(23324, 11, 0, 0, 'achievement_coa_game_mode_felforged'), -- Felforged Level 30
(23325, 11, 0, 0, 'achievement_coa_game_mode_felforged'), -- Felforged Level 40
(23326, 11, 0, 0, 'achievement_coa_game_mode_felforged'), -- Felforged Level 50
(23327, 11, 0, 0, 'achievement_coa_game_mode_felforged'), -- Felforged Level 60
(26338, 21, 0, 7, ''), -- Realm First! Level 70 Gnome
(26339, 21, 0, 3, ''), -- Realm First! Level 70 Dwarf
(26340, 21, 0, 1, ''), -- Realm First! Level 70 Human
(26341, 21, 0, 4, ''), -- Realm First! Level 70 Night Elf
(26342, 21, 0, 2, ''), -- Realm First! Level 70 Orc
(26343, 21, 0, 6, ''), -- Realm First! Level 70 Tauren
(26344, 21, 0, 8, ''), -- Realm First! Level 70 Troll
(26345, 21, 0, 5, ''), -- Realm First! Level 70 Forsaken
(26346, 21, 0, 10, ''), -- Realm First! Level 70 Blood Elf
(26347, 21, 0, 11, ''), -- Realm First! Level 70 Draenei
(26348, 11, 0, 0, 'achievement_coa_game_mode_ironman'), -- Ironman Level 70
(26349, 11, 0, 0, 'achievement_coa_game_mode_survivalist'), -- Survivalist Level 70
(26350, 11, 0, 0, 'achievement_coa_game_mode_ironman'), -- [High Risk] Ironman Level 70
(26351, 11, 0, 0, 'achievement_coa_game_mode_resolute'), -- Absolute Resolve
(26352, 11, 0, 0, 'achievement_coa_game_mode_ironman'), -- Realm First! Ironman Level 70
(26353, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute'), -- Realm First! Resolute Ironman Level 70
(26354, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute'), -- Resolute Ironman Max Level
(28337, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70
(28338, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Gnome
(28338, 21, 0, 7, ''), -- Realm First! Nightmare Mode: Level 70 Gnome
(28339, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Dwarf
(28339, 21, 0, 3, ''), -- Realm First! Nightmare Mode: Level 70 Dwarf
(28340, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Human
(28340, 21, 0, 1, ''), -- Realm First! Nightmare Mode: Level 70 Human
(28341, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Night Elf
(28341, 21, 0, 4, ''), -- Realm First! Nightmare Mode: Level 70 Night Elf
(28342, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Orc
(28342, 21, 0, 2, ''), -- Realm First! Nightmare Mode: Level 70 Orc
(28343, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Tauren
(28343, 21, 0, 6, ''), -- Realm First! Nightmare Mode: Level 70 Tauren
(28344, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Troll
(28344, 21, 0, 8, ''), -- Realm First! Nightmare Mode: Level 70 Troll
(28345, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Forsaken
(28345, 21, 0, 5, ''), -- Realm First! Nightmare Mode: Level 70 Forsaken
(28346, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Blood Elf
(28346, 21, 0, 10, ''), -- Realm First! Nightmare Mode: Level 70 Blood Elf
(28347, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 70 Draenei
(28347, 21, 0, 11, ''), -- Realm First! Nightmare Mode: Level 70 Draenei
(28348, 11, 0, 0, 'achievement_coa_game_mode_ironman_nightmare'), -- Nightmare Mode: Ironman Max Level
(28349, 11, 0, 0, 'achievement_coa_game_mode_survivalist_nightmare'), -- Nightmare Mode: Survivalist Max Level
(28350, 11, 0, 0, 'achievement_coa_game_mode_ironman_nightmare'), -- Nightmare Mode: [High Risk] Ironman Level 70
(28351, 11, 0, 0, 'achievement_coa_game_mode_resolute_nightmare'), -- Nightmare Mode: Absolute Resolve
(28352, 11, 0, 0, 'achievement_coa_game_mode_ironman_nightmare'), -- Realm First! Nightmare Mode: Ironman Level 70
(28353, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute_nightmare'), -- Realm First! Nightmare Mode: Resolute I...
(28354, 11, 0, 0, 'achievement_coa_game_mode_ironman_resolute_nightmare'), -- Nightmare Mode: Resolute Ironman Level 70
(28800, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Nightmare Mode: Level 70
(29443, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60
(29449, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Gnome
(29449, 21, 0, 7, ''), -- Realm First! Nightmare Mode: Level 60 Gnome
(29455, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Dwarf
(29455, 21, 0, 3, ''), -- Realm First! Nightmare Mode: Level 60 Dwarf
(29461, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Human
(29461, 21, 0, 1, ''), -- Realm First! Nightmare Mode: Level 60 Human
(29467, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Night Elf
(29467, 21, 0, 4, ''), -- Realm First! Nightmare Mode: Level 60 Night Elf
(29473, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Orc
(29473, 21, 0, 2, ''), -- Realm First! Nightmare Mode: Level 60 Orc
(29479, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Tauren
(29479, 21, 0, 6, ''), -- Realm First! Nightmare Mode: Level 60 Tauren
(29485, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Troll
(29485, 21, 0, 8, ''), -- Realm First! Nightmare Mode: Level 60 Troll
(29491, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Forsaken
(29491, 21, 0, 5, ''), -- Realm First! Nightmare Mode: Level 60 Forsaken
(29497, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Blood Elf
(29497, 21, 0, 10, ''), -- Realm First! Nightmare Mode: Level 60 Blood Elf
(29503, 11, 0, 0, 'achievement_coa_game_mode_nightmare'), -- Realm First! Nightmare Mode: Level 60 Draenei
(29503, 21, 0, 11, ''), -- Realm First! Nightmare Mode: Level 60 Draenei
(31658, 11, 0, 0, 'achievement_coa_game_mode_wildcard'), -- Wildcard: Preparing to Choose
(86000, 21, 12, 0, ''), -- Level 60 Barbarian
(86001, 21, 13, 0, ''), -- Level 60 Witch Doctor
(86002, 21, 14, 0, ''), -- Level 60 Felsworn
(86003, 21, 15, 0, ''), -- Level 60 Witch Hunter
(86004, 21, 16, 0, ''), -- Level 60 Stormbringer
(86005, 21, 17, 0, ''), -- Level 60 Knight of Xoroth
(86006, 21, 18, 0, ''), -- Level 60 Guardian
(86007, 21, 19, 0, ''), -- Level 60 Templar
(86008, 21, 20, 0, ''), -- Level 60 Son of Arugal
(86009, 21, 21, 0, ''), -- Level 60 Ranger
(86010, 21, 22, 0, ''), -- Level 60 Chronomancer
(86011, 21, 23, 0, ''), -- Level 60 Necromancer
(86012, 21, 24, 0, ''), -- Level 60 Pyromancer
(86013, 21, 25, 0, ''), -- Level 60 Cultist
(86014, 21, 26, 0, ''), -- Level 60 Starcaller
(86015, 21, 27, 0, ''), -- Level 60 Sun Cleric
(86016, 21, 28, 0, ''), -- Level 60 Tinker
(86017, 21, 29, 0, ''), -- Level 60 Venomancer
(86018, 21, 30, 0, ''), -- Level 60 Reaper
(86019, 21, 31, 0, ''), -- Level 60 Primalist
(86020, 21, 32, 0, ''), -- Level 60 Runemaster
(86021, 21, 12, 11, ''), -- Realm First! Level 60 Draenei Barbarian
(86022, 21, 12, 10, ''), -- Realm First! Level 60 Blood Elf Barbarian
(86023, 21, 12, 8, ''), -- Realm First! Level 60 Troll Barbarian
(86024, 21, 12, 7, ''), -- Realm First! Level 60 Gnome Barbarian
(86025, 21, 12, 6, ''), -- Realm First! Level 60 Tauren Barbarian
(86026, 21, 12, 5, ''), -- Realm First! Level 60 Undead Barbarian
(86027, 21, 12, 4, ''), -- Realm First! Level 60 Night Elf Barbarian
(86028, 21, 12, 3, ''), -- Realm First! Level 60 Dwarf Barbarian
(86029, 21, 12, 2, ''), -- Realm First! Level 60 Orc Barbarian
(86030, 21, 12, 1, ''), -- Realm First! Level 60 Human Barbarian
(86031, 21, 13, 11, ''), -- Realm First! Level 60 Draenei Witch Doctor
(86032, 21, 13, 10, ''), -- Realm First! Level 60 Blood Elf Witch Doctor
(86033, 21, 13, 8, ''), -- Realm First! Level 60 Troll Witch Doctor
(86034, 21, 13, 7, ''), -- Realm First! Level 60 Gnome Witch Doctor
(86035, 21, 13, 6, ''), -- Realm First! Level 60 Tauren Witch Doctor
(86036, 21, 13, 5, ''), -- Realm First! Level 60 Undead Witch Doctor
(86037, 21, 13, 4, ''), -- Realm First! Level 60 Night Elf Witch Doctor
(86038, 21, 13, 3, ''), -- Realm First! Level 60 Dwarf Witch Doctor
(86039, 21, 13, 2, ''), -- Realm First! Level 60 Orc Witch Doctor
(86040, 21, 13, 1, ''), -- Realm First! Level 60 Human Witch Doctor
(86041, 21, 14, 11, ''), -- Realm First! Level 60 Draenei Felsworn
(86042, 21, 14, 10, ''), -- Realm First! Level 60 Blood Elf Felsworn
(86043, 21, 14, 8, ''), -- Realm First! Level 60 Troll Felsworn
(86044, 21, 14, 7, ''), -- Realm First! Level 60 Gnome Felsworn
(86045, 21, 14, 6, ''), -- Realm First! Level 60 Tauren Felsworn
(86046, 21, 14, 5, ''), -- Realm First! Level 60 Undead Felsworn
(86047, 21, 14, 4, ''), -- Realm First! Level 60 Night Elf Felsworn
(86048, 21, 14, 3, ''), -- Realm First! Level 60 Dwarf Felsworn
(86049, 21, 14, 2, ''), -- Realm First! Level 60 Orc Felsworn
(86050, 21, 14, 1, ''), -- Realm First! Level 60 Human Felsworn
(86051, 21, 15, 11, ''), -- Realm First! Level 60 Draenei Witch Hunter
(86052, 21, 15, 10, ''), -- Realm First! Level 60 Blood Elf Witch Hunter
(86053, 21, 15, 8, ''), -- Realm First! Level 60 Troll Witch Hunter
(86054, 21, 15, 7, ''), -- Realm First! Level 60 Gnome Witch Hunter
(86055, 21, 15, 6, ''), -- Realm First! Level 60 Tauren Witch Hunter
(86056, 21, 15, 5, ''), -- Realm First! Level 60 Undead Witch Hunter
(86057, 21, 15, 4, ''), -- Realm First! Level 60 Night Elf Witch Hunter
(86058, 21, 15, 3, ''), -- Realm First! Level 60 Dwarf Witch Hunter
(86059, 21, 15, 2, ''), -- Realm First! Level 60 Orc Witch Hunter
(86060, 21, 15, 1, ''), -- Realm First! Level 60 Human Witch Hunter
(86061, 21, 16, 11, ''), -- Realm First! Level 60 Draenei Stormbringer
(86062, 21, 16, 10, ''), -- Realm First! Level 60 Blood Elf Stormbringer
(86063, 21, 16, 8, ''), -- Realm First! Level 60 Troll Stormbringer
(86064, 21, 16, 7, ''), -- Realm First! Level 60 Gnome Stormbringer
(86065, 21, 16, 6, ''), -- Realm First! Level 60 Tauren Stormbringer
(86066, 21, 16, 5, ''), -- Realm First! Level 60 Undead Stormbringer
(86067, 21, 16, 4, ''), -- Realm First! Level 60 Night Elf Stormbringer
(86068, 21, 16, 3, ''), -- Realm First! Level 60 Dwarf Stormbringer
(86069, 21, 16, 2, ''), -- Realm First! Level 60 Orc Stormbringer
(86070, 21, 16, 1, ''), -- Realm First! Level 60 Human Stormbringer
(86071, 21, 17, 11, ''), -- Realm First! Level 60 Draenei Knight of Xoroth
(86072, 21, 17, 10, ''), -- Realm First! Level 60 Blood Elf Knight of Xoroth
(86073, 21, 17, 8, ''), -- Realm First! Level 60 Troll Knight of Xoroth
(86074, 21, 17, 7, ''), -- Realm First! Level 60 Gnome Knight of Xoroth
(86075, 21, 17, 6, ''), -- Realm First! Level 60 Tauren Knight of Xoroth
(86076, 21, 17, 5, ''), -- Realm First! Level 60 Undead Knight of Xoroth
(86077, 21, 17, 4, ''), -- Realm First! Level 60 Night Elf Knight of Xoroth
(86078, 21, 17, 3, ''), -- Realm First! Level 60 Dwarf Knight of Xoroth
(86079, 21, 17, 2, ''), -- Realm First! Level 60 Orc Knight of Xoroth
(86080, 21, 17, 1, ''), -- Realm First! Level 60 Human Knight of Xoroth
(86081, 21, 18, 11, ''), -- Realm First! Level 60 Draenei Guardian
(86082, 21, 18, 10, ''), -- Realm First! Level 60 Blood Elf Guardian
(86083, 21, 18, 8, ''), -- Realm First! Level 60 Troll Guardian
(86084, 21, 18, 7, ''), -- Realm First! Level 60 Gnome Guardian
(86085, 21, 18, 6, ''), -- Realm First! Level 60 Tauren Guardian
(86086, 21, 18, 5, ''), -- Realm First! Level 60 Undead Guardian
(86087, 21, 18, 4, ''), -- Realm First! Level 60 Night Elf Guardian
(86088, 21, 18, 3, ''), -- Realm First! Level 60 Dwarf Guardian
(86089, 21, 18, 2, ''), -- Realm First! Level 60 Orc Guardian
(86090, 21, 18, 1, ''), -- Realm First! Level 60 Human Guardian
(86091, 21, 19, 11, ''), -- Realm First! Level 60 Draenei Templar
(86092, 21, 19, 10, ''), -- Realm First! Level 60 Blood Elf Templar
(86093, 21, 19, 8, ''), -- Realm First! Level 60 Troll Templar
(86094, 21, 19, 7, ''), -- Realm First! Level 60 Gnome Templar
(86095, 21, 19, 6, ''), -- Realm First! Level 60 Tauren Templar
(86096, 21, 19, 5, ''), -- Realm First! Level 60 Undead Templar
(86097, 21, 19, 4, ''), -- Realm First! Level 60 Night Elf Templar
(86098, 21, 19, 3, ''), -- Realm First! Level 60 Dwarf Templar
(86099, 21, 19, 2, ''), -- Realm First! Level 60 Orc Templar
(86100, 21, 19, 1, ''), -- Realm First! Level 60 Human Templar
(86101, 21, 20, 11, ''), -- Realm First! Level 60 Draenei Son of Arugal
(86102, 21, 20, 10, ''), -- Realm First! Level 60 Blood Elf Son of Arugal
(86103, 21, 20, 8, ''), -- Realm First! Level 60 Troll Son of Arugal
(86104, 21, 20, 7, ''), -- Realm First! Level 60 Gnome Son of Arugal
(86105, 21, 20, 6, ''), -- Realm First! Level 60 Tauren Son of Arugal
(86106, 21, 20, 5, ''), -- Realm First! Level 60 Undead Son of Arugal
(86107, 21, 20, 4, ''), -- Realm First! Level 60 Night Elf Son of Arugal
(86108, 21, 20, 3, ''), -- Realm First! Level 60 Dwarf Son of Arugal
(86109, 21, 20, 2, ''), -- Realm First! Level 60 Orc Son of Arugal
(86110, 21, 20, 1, ''), -- Realm First! Level 60 Human Son of Arugal
(86111, 21, 21, 11, ''), -- Realm First! Level 60 Draenei Ranger
(86112, 21, 21, 10, ''), -- Realm First! Level 60 Blood Elf Ranger
(86113, 21, 21, 8, ''), -- Realm First! Level 60 Troll Ranger
(86114, 21, 21, 7, ''), -- Realm First! Level 60 Gnome Ranger
(86115, 21, 21, 6, ''), -- Realm First! Level 60 Tauren Ranger
(86116, 21, 21, 5, ''), -- Realm First! Level 60 Undead Ranger
(86117, 21, 21, 4, ''), -- Realm First! Level 60 Night Elf Ranger
(86118, 21, 21, 3, ''), -- Realm First! Level 60 Dwarf Ranger
(86119, 21, 21, 2, ''), -- Realm First! Level 60 Orc Ranger
(86120, 21, 21, 1, ''), -- Realm First! Level 60 Human Ranger
(86121, 21, 22, 11, ''), -- Realm First! Level 60 Draenei Chronomancer
(86122, 21, 22, 10, ''), -- Realm First! Level 60 Blood Elf Chronomancer
(86123, 21, 22, 8, ''), -- Realm First! Level 60 Troll Chronomancer
(86124, 21, 22, 7, ''), -- Realm First! Level 60 Gnome Chronomancer
(86125, 21, 22, 6, ''), -- Realm First! Level 60 Tauren Chronomancer
(86126, 21, 22, 5, ''), -- Realm First! Level 60 Undead Chronomancer
(86127, 21, 22, 4, ''), -- Realm First! Level 60 Night Elf Chronomancer
(86128, 21, 22, 3, ''), -- Realm First! Level 60 Dwarf Chronomancer
(86129, 21, 22, 2, ''), -- Realm First! Level 60 Orc Chronomancer
(86130, 21, 22, 1, ''), -- Realm First! Level 60 Human Chronomancer
(86131, 21, 23, 11, ''), -- Realm First! Level 60 Draenei Necromancer
(86132, 21, 23, 10, ''), -- Realm First! Level 60 Blood Elf Necromancer
(86133, 21, 23, 8, ''), -- Realm First! Level 60 Troll Necromancer
(86134, 21, 23, 7, ''), -- Realm First! Level 60 Gnome Necromancer
(86135, 21, 23, 6, ''), -- Realm First! Level 60 Tauren Necromancer
(86136, 21, 23, 5, ''), -- Realm First! Level 60 Undead Necromancer
(86137, 21, 23, 4, ''), -- Realm First! Level 60 Night Elf Necromancer
(86138, 21, 23, 3, ''), -- Realm First! Level 60 Dwarf Necromancer
(86139, 21, 23, 2, ''), -- Realm First! Level 60 Orc Necromancer
(86140, 21, 23, 1, ''), -- Realm First! Level 60 Human Necromancer
(86141, 21, 24, 11, ''), -- Realm First! Level 60 Draenei Pyromancer
(86142, 21, 24, 10, ''), -- Realm First! Level 60 Blood Elf Pyromancer
(86143, 21, 24, 8, ''), -- Realm First! Level 60 Troll Pyromancer
(86144, 21, 24, 7, ''), -- Realm First! Level 60 Gnome Pyromancer
(86145, 21, 24, 6, ''), -- Realm First! Level 60 Tauren Pyromancer
(86146, 21, 24, 5, ''), -- Realm First! Level 60 Undead Pyromancer
(86147, 21, 24, 4, ''), -- Realm First! Level 60 Night Elf Pyromancer
(86148, 21, 24, 3, ''), -- Realm First! Level 60 Dwarf Pyromancer
(86149, 21, 24, 2, ''), -- Realm First! Level 60 Orc Pyromancer
(86150, 21, 24, 1, ''), -- Realm First! Level 60 Human Pyromancer
(86151, 21, 25, 11, ''), -- Realm First! Level 60 Draenei Cultist
(86152, 21, 25, 10, ''), -- Realm First! Level 60 Blood Elf Cultist
(86153, 21, 25, 8, ''), -- Realm First! Level 60 Troll Cultist
(86154, 21, 25, 7, ''), -- Realm First! Level 60 Gnome Cultist
(86155, 21, 25, 6, ''), -- Realm First! Level 60 Tauren Cultist
(86156, 21, 25, 5, ''), -- Realm First! Level 60 Undead Cultist
(86157, 21, 25, 4, ''), -- Realm First! Level 60 Night Elf Cultist
(86158, 21, 25, 3, ''), -- Realm First! Level 60 Dwarf Cultist
(86159, 21, 25, 2, ''), -- Realm First! Level 60 Orc Cultist
(86160, 21, 25, 1, ''), -- Realm First! Level 60 Human Cultist
(86161, 21, 26, 11, ''), -- Realm First! Level 60 Draenei Starcaller
(86162, 21, 26, 10, ''), -- Realm First! Level 60 Blood Elf Starcaller
(86163, 21, 26, 8, ''), -- Realm First! Level 60 Troll Starcaller
(86164, 21, 26, 7, ''), -- Realm First! Level 60 Gnome Starcaller
(86165, 21, 26, 6, ''), -- Realm First! Level 60 Tauren Starcaller
(86166, 21, 26, 5, ''), -- Realm First! Level 60 Undead Starcaller
(86167, 21, 26, 4, ''), -- Realm First! Level 60 Night Elf Starcaller
(86168, 21, 26, 3, ''), -- Realm First! Level 60 Dwarf Starcaller
(86169, 21, 26, 2, ''), -- Realm First! Level 60 Orc Starcaller
(86170, 21, 26, 1, ''), -- Realm First! Level 60 Human Starcaller
(86171, 21, 27, 11, ''), -- Realm First! Level 60 Draenei Sun Cleric
(86172, 21, 27, 10, ''), -- Realm First! Level 60 Blood Elf Sun Cleric
(86173, 21, 27, 8, ''), -- Realm First! Level 60 Troll Sun Cleric
(86174, 21, 27, 7, ''), -- Realm First! Level 60 Gnome Sun Cleric
(86175, 21, 27, 6, ''), -- Realm First! Level 60 Tauren Sun Cleric
(86176, 21, 27, 5, ''), -- Realm First! Level 60 Undead Sun Cleric
(86177, 21, 27, 4, ''), -- Realm First! Level 60 Night Elf Sun Cleric
(86178, 21, 27, 3, ''), -- Realm First! Level 60 Dwarf Sun Cleric
(86179, 21, 27, 2, ''), -- Realm First! Level 60 Orc Sun Cleric
(86180, 21, 27, 1, ''), -- Realm First! Level 60 Human Sun Cleric
(86181, 21, 28, 11, ''), -- Realm First! Level 60 Draenei Tinker
(86182, 21, 28, 10, ''), -- Realm First! Level 60 Blood Elf Tinker
(86183, 21, 28, 8, ''), -- Realm First! Level 60 Troll Tinker
(86184, 21, 28, 7, ''), -- Realm First! Level 60 Gnome Tinker
(86185, 21, 28, 6, ''), -- Realm First! Level 60 Tauren Tinker
(86186, 21, 28, 5, ''), -- Realm First! Level 60 Undead Tinker
(86187, 21, 28, 4, ''), -- Realm First! Level 60 Night Elf Tinker
(86188, 21, 28, 3, ''), -- Realm First! Level 60 Dwarf Tinker
(86189, 21, 28, 2, ''), -- Realm First! Level 60 Orc Tinker
(86190, 21, 28, 1, ''), -- Realm First! Level 60 Human Tinker
(86191, 21, 29, 11, ''), -- Realm First! Level 60 Draenei Venomancer
(86192, 21, 29, 10, ''), -- Realm First! Level 60 Blood Elf Venomancer
(86193, 21, 29, 8, ''), -- Realm First! Level 60 Troll Venomancer
(86194, 21, 29, 7, ''), -- Realm First! Level 60 Gnome Venomancer
(86195, 21, 29, 6, ''), -- Realm First! Level 60 Tauren Venomancer
(86196, 21, 29, 5, ''), -- Realm First! Level 60 Undead Venomancer
(86197, 21, 29, 4, ''), -- Realm First! Level 60 Night Elf Venomancer
(86198, 21, 29, 3, ''), -- Realm First! Level 60 Dwarf Venomancer
(86199, 21, 29, 2, ''), -- Realm First! Level 60 Orc Venomancer
(86200, 21, 29, 1, ''), -- Realm First! Level 60 Human Venomancer
(86201, 21, 30, 11, ''), -- Realm First! Level 60 Draenei Reaper
(86202, 21, 30, 10, ''), -- Realm First! Level 60 Blood Elf Reaper
(86203, 21, 30, 8, ''), -- Realm First! Level 60 Troll Reaper
(86204, 21, 30, 7, ''), -- Realm First! Level 60 Gnome Reaper
(86205, 21, 30, 6, ''), -- Realm First! Level 60 Tauren Reaper
(86206, 21, 30, 5, ''), -- Realm First! Level 60 Undead Reaper
(86207, 21, 30, 4, ''), -- Realm First! Level 60 Night Elf Reaper
(86208, 21, 30, 3, ''), -- Realm First! Level 60 Dwarf Reaper
(86209, 21, 30, 2, ''), -- Realm First! Level 60 Orc Reaper
(86210, 21, 30, 1, ''), -- Realm First! Level 60 Human Reaper
(86211, 21, 31, 11, ''), -- Realm First! Level 60 Draenei Primalist
(86212, 21, 31, 10, ''), -- Realm First! Level 60 Blood Elf Primalist
(86213, 21, 31, 8, ''), -- Realm First! Level 60 Troll Primalist
(86214, 21, 31, 7, ''), -- Realm First! Level 60 Gnome Primalist
(86215, 21, 31, 6, ''), -- Realm First! Level 60 Tauren Primalist
(86216, 21, 31, 5, ''), -- Realm First! Level 60 Undead Primalist
(86217, 21, 31, 4, ''), -- Realm First! Level 60 Night Elf Primalist
(86218, 21, 31, 3, ''), -- Realm First! Level 60 Dwarf Primalist
(86219, 21, 31, 2, ''), -- Realm First! Level 60 Orc Primalist
(86220, 21, 31, 1, ''), -- Realm First! Level 60 Human Primalist
(86221, 21, 32, 11, ''), -- Realm First! Level 60 Draenei Runemaster
(86222, 21, 32, 10, ''), -- Realm First! Level 60 Blood Elf Runemaster
(86223, 21, 32, 8, ''), -- Realm First! Level 60 Troll Runemaster
(86224, 21, 32, 7, ''), -- Realm First! Level 60 Gnome Runemaster
(86225, 21, 32, 6, ''), -- Realm First! Level 60 Tauren Runemaster
(86226, 21, 32, 5, ''), -- Realm First! Level 60 Undead Runemaster
(86227, 21, 32, 4, ''), -- Realm First! Level 60 Night Elf Runemaster
(86228, 21, 32, 3, ''), -- Realm First! Level 60 Dwarf Runemaster
(86229, 21, 32, 2, ''), -- Realm First! Level 60 Orc Runemaster
(86230, 21, 32, 1, ''), -- Realm First! Level 60 Human Runemaster
(86500, 21, 12, 0, ''), -- Realm First! Level 60 Barbarian
(86501, 21, 13, 0, ''), -- Realm First! Level 60 Witch Doctor
(86502, 21, 14, 0, ''), -- Realm First! Level 60 Felsworn
(86503, 21, 15, 0, ''), -- Realm First! Level 60 Witch Hunter
(86504, 21, 16, 0, ''), -- Realm First! Level 60 Stormbringer
(86505, 21, 17, 0, ''), -- Realm First! Level 60 Knight of Xoroth
(86506, 21, 18, 0, ''), -- Realm First! Level 60 Guardian
(86507, 21, 19, 0, ''), -- Realm First! Level 60 Templar
(86508, 21, 20, 0, ''), -- Realm First! Level 60 Son of Arugal
(86509, 21, 21, 0, ''), -- Realm First! Level 60 Ranger
(86510, 21, 22, 0, ''), -- Realm First! Level 60 Chronomancer
(86511, 21, 23, 0, ''), -- Realm First! Level 60 Necromancer
(86512, 21, 24, 0, ''), -- Realm First! Level 60 Pyromancer
(86513, 21, 25, 0, ''), -- Realm First! Level 60 Cultist
(86514, 21, 26, 0, ''), -- Realm First! Level 60 Starcaller
(86515, 21, 27, 0, ''), -- Realm First! Level 60 Sun Cleric
(86516, 21, 28, 0, ''), -- Realm First! Level 60 Tinker
(86517, 21, 29, 0, ''), -- Realm First! Level 60 Venomancer
(86518, 21, 30, 0, ''), -- Realm First! Level 60 Reaper
(86519, 21, 31, 0, ''), -- Realm First! Level 60 Primalist
(86520, 21, 32, 0, ''), -- Realm First! Level 60 Runemaster
(149991, 21, 4, 0, ''), -- Level 60 Rogue
(149992, 21, 1, 0, ''), -- Level 60 Warrior
(149993, 21, 8, 0, ''), -- Level 60 Mage
(149994, 21, 6, 0, ''), -- Level 60 Death Knight
(149995, 21, 3, 0, ''), -- Level 60 Hunter
(149996, 21, 9, 0, ''), -- Level 60 Warlock
(149997, 21, 5, 0, ''), -- Level 60 Priest
(149998, 21, 2, 0, ''), -- Level 60 Paladin
(149999, 21, 11, 0, ''), -- Level 60 Druid
(150000, 21, 7, 0, ''), -- Level 60 Shaman
(150001, 21, 4, 0, ''), -- Realm First! Level 60 Rogue
(150002, 21, 1, 0, ''), -- Realm First! Level 60 Warrior
(150003, 21, 8, 0, ''), -- Realm First! Level 60 Mage
(150004, 21, 6, 0, ''), -- Realm First! Level 60 Death Knight
(150005, 21, 3, 0, ''), -- Realm First! Level 60 Hunter
(150006, 21, 9, 0, ''), -- Realm First! Level 60 Warlock
(150007, 21, 5, 0, ''), -- Realm First! Level 60 Priest
(150008, 21, 2, 0, ''), -- Realm First! Level 60 Paladin
(150009, 21, 11, 0, ''), -- Realm First! Level 60 Druid
(150010, 21, 7, 0, ''), -- Realm First! Level 60 Shaman
(150106, 21, 4, 7, ''), -- Realm First! Level 60 Gnome Rogue
(150112, 21, 4, 3, ''), -- Realm First! Level 60 Dwarf Rogue
(150118, 21, 4, 1, ''), -- Realm First! Level 60 Human Rogue
(150124, 21, 4, 4, ''), -- Realm First! Level 60 Night Elf Rogue
(150130, 21, 4, 2, ''), -- Realm First! Level 60 Orc Rogue
(150136, 21, 4, 6, ''), -- Realm First! Level 60 Tauren Rogue
(150142, 21, 4, 8, ''), -- Realm First! Level 60 Troll Rogue
(150148, 21, 4, 5, ''), -- Realm First! Level 60 Forsaken Rogue
(150154, 21, 4, 10, ''), -- Realm First! Level 60 Blood Elf Rogue
(150160, 21, 4, 11, ''), -- Realm First! Level 60 Draenei Rogue
(150161, 21, 4, 7, ''), -- Realm First! Level 70 Gnome Rogue
(150162, 21, 4, 3, ''), -- Realm First! Level 70 Dwarf Rogue
(150163, 21, 4, 1, ''), -- Realm First! Level 70 Human Rogue
(150164, 21, 4, 4, ''), -- Realm First! Level 70 Night Elf Rogue
(150165, 21, 4, 2, ''), -- Realm First! Level 70 Orc Rogue
(150166, 21, 4, 6, ''), -- Realm First! Level 70 Tauren Rogue
(150167, 21, 4, 8, ''), -- Realm First! Level 70 Troll Rogue
(150168, 21, 4, 5, ''), -- Realm First! Level 70 Forsaken Rogue
(150169, 21, 4, 10, ''), -- Realm First! Level 70 Blood Elf Rogue
(150170, 21, 4, 11, ''), -- Realm First! Level 70 Draenei Rogue
(150306, 21, 1, 7, ''), -- Realm First! Level 60 Gnome Warrior
(150312, 21, 1, 3, ''), -- Realm First! Level 60 Dwarf Warrior
(150318, 21, 1, 1, ''), -- Realm First! Level 60 Human Warrior
(150324, 21, 1, 4, ''), -- Realm First! Level 60 Night Elf Warrior
(150330, 21, 1, 2, ''), -- Realm First! Level 60 Orc Warrior
(150336, 21, 1, 6, ''), -- Realm First! Level 60 Tauren Warrior
(150342, 21, 1, 8, ''), -- Realm First! Level 60 Troll Warrior
(150348, 21, 1, 5, ''), -- Realm First! Level 60 Forsaken Warrior
(150354, 21, 1, 10, ''), -- Realm First! Level 60 Blood Elf Warrior
(150360, 21, 1, 11, ''), -- Realm First! Level 60 Draenei Warrior
(150361, 21, 1, 7, ''), -- Realm First! Level 70 Gnome Warrior
(150362, 21, 1, 3, ''), -- Realm First! Level 70 Dwarf Warrior
(150363, 21, 1, 1, ''), -- Realm First! Level 70 Human Warrior
(150364, 21, 1, 4, ''), -- Realm First! Level 70 Night Elf Warrior
(150365, 21, 1, 2, ''), -- Realm First! Level 70 Orc Warrior
(150366, 21, 1, 6, ''), -- Realm First! Level 70 Tauren Warrior
(150367, 21, 1, 8, ''), -- Realm First! Level 70 Troll Warrior
(150368, 21, 1, 5, ''), -- Realm First! Level 70 Forsaken Warrior
(150369, 21, 1, 10, ''), -- Realm First! Level 70 Blood Elf Warrior
(150370, 21, 1, 11, ''), -- Realm First! Level 70 Draenei Warrior
(150506, 21, 2, 7, ''), -- Realm First! Level 60 Gnome Paladin
(150512, 21, 2, 3, ''), -- Realm First! Level 60 Dwarf Paladin
(150518, 21, 2, 1, ''), -- Realm First! Level 60 Human Paladin
(150524, 21, 2, 4, ''), -- Realm First! Level 60 Night Elf Paladin
(150530, 21, 2, 2, ''), -- Realm First! Level 60 Orc Paladin
(150536, 21, 2, 6, ''), -- Realm First! Level 60 Tauren Paladin
(150542, 21, 2, 8, ''), -- Realm First! Level 60 Troll Paladin
(150548, 21, 2, 5, ''), -- Realm First! Level 60 Forsaken Paladin
(150554, 21, 2, 10, ''), -- Realm First! Level 60 Blood Elf Paladin
(150560, 21, 2, 11, ''), -- Realm First! Level 60 Draenei Paladin
(150561, 21, 2, 7, ''), -- Realm First! Level 70 Gnome Paladin
(150562, 21, 2, 3, ''), -- Realm First! Level 70 Dwarf Paladin
(150563, 21, 2, 1, ''), -- Realm First! Level 70 Human Paladin
(150564, 21, 2, 4, ''), -- Realm First! Level 70 Night Elf Paladin
(150565, 21, 2, 2, ''), -- Realm First! Level 70 Orc Paladin
(150566, 21, 2, 6, ''), -- Realm First! Level 70 Tauren Paladin
(150567, 21, 2, 8, ''), -- Realm First! Level 70 Troll Paladin
(150568, 21, 2, 5, ''), -- Realm First! Level 70 Forsaken Paladin
(150569, 21, 2, 10, ''), -- Realm First! Level 70 Blood Elf Paladin
(150570, 21, 2, 11, ''), -- Realm First! Level 70 Draenei Paladin
(150706, 21, 3, 7, ''), -- Realm First! Level 60 Gnome Hunter
(150712, 21, 3, 3, ''), -- Realm First! Level 60 Dwarf Hunter
(150718, 21, 3, 1, ''), -- Realm First! Level 60 Human Hunter
(150724, 21, 3, 4, ''), -- Realm First! Level 60 Night Elf Hunter
(150730, 21, 3, 2, ''), -- Realm First! Level 60 Orc Hunter
(150736, 21, 3, 6, ''), -- Realm First! Level 60 Tauren Hunter
(150742, 21, 3, 8, ''), -- Realm First! Level 60 Troll Hunter
(150748, 21, 3, 5, ''), -- Realm First! Level 60 Forsaken Hunter
(150754, 21, 3, 10, ''), -- Realm First! Level 60 Blood Elf Hunter
(150760, 21, 3, 11, ''), -- Realm First! Level 60 Draenei Hunter
(150761, 21, 3, 7, ''), -- Realm First! Level 70 Gnome Hunter
(150762, 21, 3, 3, ''), -- Realm First! Level 70 Dwarf Hunter
(150763, 21, 3, 1, ''), -- Realm First! Level 70 Human Hunter
(150764, 21, 3, 4, ''), -- Realm First! Level 70 Night Elf Hunter
(150765, 21, 3, 2, ''), -- Realm First! Level 70 Orc Hunter
(150766, 21, 3, 6, ''), -- Realm First! Level 70 Tauren Hunter
(150767, 21, 3, 8, ''), -- Realm First! Level 70 Troll Hunter
(150768, 21, 3, 5, ''), -- Realm First! Level 70 Forsaken Hunter
(150769, 21, 3, 10, ''), -- Realm First! Level 70 Blood Elf Hunter
(150770, 21, 3, 11, ''), -- Realm First! Level 70 Draenei Hunter
(150906, 21, 5, 7, ''), -- Realm First! Level 60 Gnome Priest
(150912, 21, 5, 3, ''), -- Realm First! Level 60 Dwarf Priest
(150918, 21, 5, 1, ''), -- Realm First! Level 60 Human Priest
(150924, 21, 5, 4, ''), -- Realm First! Level 60 Night Elf Priest
(150930, 21, 5, 2, ''), -- Realm First! Level 60 Orc Priest
(150936, 21, 5, 6, ''), -- Realm First! Level 60 Tauren Priest
(150942, 21, 5, 8, ''), -- Realm First! Level 60 Troll Priest
(150948, 21, 5, 5, ''), -- Realm First! Level 60 Forsaken Priest
(150954, 21, 5, 10, ''), -- Realm First! Level 60 Blood Elf Priest
(150960, 21, 5, 11, ''), -- Realm First! Level 60 Draenei Priest
(150961, 21, 5, 7, ''), -- Realm First! Level 70 Gnome Priest
(150962, 21, 5, 3, ''), -- Realm First! Level 70 Dwarf Priest
(150963, 21, 5, 1, ''), -- Realm First! Level 70 Human Priest
(150964, 21, 5, 4, ''), -- Realm First! Level 70 Night Elf Priest
(150965, 21, 5, 2, ''), -- Realm First! Level 70 Orc Priest
(150966, 21, 5, 6, ''), -- Realm First! Level 70 Tauren Priest
(150967, 21, 5, 8, ''), -- Realm First! Level 70 Troll Priest
(150968, 21, 5, 5, ''), -- Realm First! Level 70 Forsaken Priest
(150969, 21, 5, 10, ''), -- Realm First! Level 70 Blood Elf Priest
(150970, 21, 5, 11, ''), -- Realm First! Level 70 Draenei Priest
(151106, 21, 6, 7, ''), -- Realm First! Level 60 Gnome Death Knight
(151112, 21, 6, 3, ''), -- Realm First! Level 60 Dwarf Death Knight
(151118, 21, 6, 1, ''), -- Realm First! Level 60 Human Death Knight
(151124, 21, 6, 4, ''), -- Realm First! Level 60 Night Elf Death Knight
(151130, 21, 6, 2, ''), -- Realm First! Level 60 Orc Death Knight
(151136, 21, 6, 6, ''), -- Realm First! Level 60 Tauren Death Knight
(151142, 21, 6, 8, ''), -- Realm First! Level 60 Troll Death Knight
(151148, 21, 6, 5, ''), -- Realm First! Level 60 Forsaken Death Knight
(151154, 21, 6, 10, ''), -- Realm First! Level 60 Blood Elf Death Knight
(151160, 21, 6, 11, ''), -- Realm First! Level 60 Draenei Death Knight
(151161, 21, 6, 7, ''), -- Realm First! Level 70 Gnome Death Knight
(151162, 21, 6, 3, ''), -- Realm First! Level 70 Dwarf Death Knight
(151163, 21, 6, 1, ''), -- Realm First! Level 70 Human Death Knight
(151164, 21, 6, 4, ''), -- Realm First! Level 70 Night Elf Death Knight
(151165, 21, 6, 2, ''), -- Realm First! Level 70 Orc Death Knight
(151166, 21, 6, 6, ''), -- Realm First! Level 70 Tauren Death Knight
(151167, 21, 6, 8, ''), -- Realm First! Level 70 Troll Death Knight
(151168, 21, 6, 5, ''), -- Realm First! Level 70 Forsaken Death Knight
(151169, 21, 6, 10, ''), -- Realm First! Level 70 Blood Elf Death Knight
(151170, 21, 6, 11, ''), -- Realm First! Level 70 Draenei Death Knight
(151306, 21, 7, 7, ''), -- Realm First! Level 60 Gnome Shaman
(151312, 21, 7, 3, ''), -- Realm First! Level 60 Dwarf Shaman
(151318, 21, 7, 1, ''), -- Realm First! Level 60 Human Shaman
(151324, 21, 7, 4, ''), -- Realm First! Level 60 Night Elf Shaman
(151330, 21, 7, 2, ''), -- Realm First! Level 60 Orc Shaman
(151336, 21, 7, 6, ''), -- Realm First! Level 60 Tauren Shaman
(151342, 21, 7, 8, ''), -- Realm First! Level 60 Troll Shaman
(151348, 21, 7, 5, ''), -- Realm First! Level 60 Forsaken Shaman
(151354, 21, 7, 10, ''), -- Realm First! Level 60 Blood Elf Shaman
(151360, 21, 7, 11, ''), -- Realm First! Level 60 Draenei Shaman
(151361, 21, 7, 7, ''), -- Realm First! Level 70 Gnome Shaman
(151362, 21, 7, 3, ''), -- Realm First! Level 70 Dwarf Shaman
(151363, 21, 7, 1, ''), -- Realm First! Level 70 Human Shaman
(151364, 21, 7, 4, ''), -- Realm First! Level 70 Night Elf Shaman
(151365, 21, 7, 2, ''), -- Realm First! Level 70 Orc Shaman
(151366, 21, 7, 6, ''), -- Realm First! Level 70 Tauren Shaman
(151367, 21, 7, 8, ''), -- Realm First! Level 70 Troll Shaman
(151368, 21, 7, 5, ''), -- Realm First! Level 70 Forsaken Shaman
(151369, 21, 7, 10, ''), -- Realm First! Level 70 Blood Elf Shaman
(151370, 21, 7, 11, ''), -- Realm First! Level 70 Draenei Shaman
(151506, 21, 8, 7, ''), -- Realm First! Level 60 Gnome Mage
(151512, 21, 8, 3, ''), -- Realm First! Level 60 Dwarf Mage
(151518, 21, 8, 1, ''), -- Realm First! Level 60 Human Mage
(151524, 21, 8, 4, ''), -- Realm First! Level 60 Night Elf Mage
(151530, 21, 8, 2, ''), -- Realm First! Level 60 Orc Mage
(151536, 21, 8, 6, ''), -- Realm First! Level 60 Tauren Mage
(151542, 21, 8, 8, ''), -- Realm First! Level 60 Troll Mage
(151548, 21, 8, 5, ''), -- Realm First! Level 60 Forsaken Mage
(151554, 21, 8, 10, ''), -- Realm First! Level 60 Blood Elf Mage
(151560, 21, 8, 11, ''), -- Realm First! Level 60 Draenei Mage
(151561, 21, 8, 7, ''), -- Realm First! Level 70 Gnome Mage
(151562, 21, 8, 3, ''), -- Realm First! Level 70 Dwarf Mage
(151563, 21, 8, 1, ''), -- Realm First! Level 70 Human Mage
(151564, 21, 8, 4, ''), -- Realm First! Level 70 Night Elf Mage
(151565, 21, 8, 2, ''), -- Realm First! Level 70 Orc Mage
(151566, 21, 8, 6, ''), -- Realm First! Level 70 Tauren Mage
(151567, 21, 8, 8, ''), -- Realm First! Level 70 Troll Mage
(151568, 21, 8, 5, ''), -- Realm First! Level 70 Forsaken Mage
(151569, 21, 8, 10, ''), -- Realm First! Level 70 Blood Elf Mage
(151570, 21, 8, 11, ''), -- Realm First! Level 70 Draenei Mage
(151706, 21, 9, 7, ''), -- Realm First! Level 60 Gnome Warlock
(151712, 21, 9, 3, ''), -- Realm First! Level 60 Dwarf Warlock
(151718, 21, 9, 1, ''), -- Realm First! Level 60 Human Warlock
(151724, 21, 9, 4, ''), -- Realm First! Level 60 Night Elf Warlock
(151730, 21, 9, 2, ''), -- Realm First! Level 60 Orc Warlock
(151736, 21, 9, 6, ''), -- Realm First! Level 60 Tauren Warlock
(151742, 21, 9, 8, ''), -- Realm First! Level 60 Troll Warlock
(151748, 21, 9, 5, ''), -- Realm First! Level 60 Forsaken Warlock
(151754, 21, 9, 10, ''), -- Realm First! Level 60 Blood Elf Warlock
(151760, 21, 9, 11, ''), -- Realm First! Level 60 Draenei Warlock
(151761, 21, 9, 7, ''), -- Realm First! Level 70 Gnome Warlock
(151762, 21, 9, 3, ''), -- Realm First! Level 70 Dwarf Warlock
(151763, 21, 9, 1, ''), -- Realm First! Level 70 Human Warlock
(151764, 21, 9, 4, ''), -- Realm First! Level 70 Night Elf Warlock
(151765, 21, 9, 2, ''), -- Realm First! Level 70 Orc Warlock
(151766, 21, 9, 6, ''), -- Realm First! Level 70 Tauren Warlock
(151767, 21, 9, 8, ''), -- Realm First! Level 70 Troll Warlock
(151768, 21, 9, 5, ''), -- Realm First! Level 70 Forsaken Warlock
(151769, 21, 9, 10, ''), -- Realm First! Level 70 Blood Elf Warlock
(151770, 21, 9, 11, ''), -- Realm First! Level 70 Draenei Warlock
(151906, 21, 11, 7, ''), -- Realm First! Level 60 Gnome Druid
(151912, 21, 11, 3, ''), -- Realm First! Level 60 Dwarf Druid
(151918, 21, 11, 1, ''), -- Realm First! Level 60 Human Druid
(151924, 21, 11, 4, ''), -- Realm First! Level 60 Night Elf Druid
(151930, 21, 11, 2, ''), -- Realm First! Level 60 Orc Druid
(151936, 21, 11, 6, ''), -- Realm First! Level 60 Tauren Druid
(151942, 21, 11, 8, ''), -- Realm First! Level 60 Troll Druid
(151948, 21, 11, 5, ''), -- Realm First! Level 60 Forsaken Druid
(151954, 21, 11, 10, ''), -- Realm First! Level 60 Blood Elf Druid
(151960, 21, 11, 11, ''), -- Realm First! Level 60 Draenei Druid
(151961, 21, 11, 7, ''), -- Realm First! Level 70 Gnome Druid
(151962, 21, 11, 3, ''), -- Realm First! Level 70 Dwarf Druid
(151963, 21, 11, 1, ''), -- Realm First! Level 70 Human Druid
(151964, 21, 11, 4, ''), -- Realm First! Level 70 Night Elf Druid
(151965, 21, 11, 2, ''), -- Realm First! Level 70 Orc Druid
(151966, 21, 11, 6, ''), -- Realm First! Level 70 Tauren Druid
(151967, 21, 11, 8, ''), -- Realm First! Level 70 Troll Druid
(151968, 21, 11, 5, ''), -- Realm First! Level 70 Forsaken Druid
(151969, 21, 11, 10, ''), -- Realm First! Level 70 Blood Elf Druid
(151970, 21, 11, 11, ''), -- Realm First! Level 70 Draenei Druid
(312828, 21, 1, 0, ''), -- Realm First! Level 70 Warrior
(312829, 21, 2, 0, ''), -- Realm First! Level 70 Paladin
(312830, 21, 3, 0, ''), -- Realm First! Level 70 Hunter
(312831, 21, 4, 0, ''), -- Realm First! Level 70 Rogue
(312832, 21, 5, 0, ''), -- Realm First! Level 70 Priest
(312833, 21, 7, 0, ''), -- Realm First! Level 70 Shaman
(312834, 21, 8, 0, ''), -- Realm First! Level 70 Mage
(312835, 21, 9, 0, ''), -- Realm First! Level 70 Warlock
(312836, 21, 11, 0, ''), -- Realm First! Level 70 Druid
(312837, 21, 12, 0, ''), -- Realm First! Level 70 Barbarian
(312838, 21, 13, 0, ''), -- Realm First! Level 70 Witch Doctor
(312839, 21, 14, 0, ''), -- Realm First! Level 70 Felsworn
(312840, 21, 15, 0, ''), -- Realm First! Level 70 Witch Hunter
(312841, 21, 16, 0, ''), -- Realm First! Level 70 Stormbringer
(312842, 21, 17, 0, ''), -- Realm First! Level 70 Knight of Xoroth
(312843, 21, 18, 0, ''), -- Realm First! Level 70 Guardian
(312844, 21, 19, 0, ''), -- Realm First! Level 70 Templar
(312845, 21, 20, 0, ''), -- Realm First! Level 70 Bloodmage
(312846, 21, 21, 0, ''), -- Realm First! Level 70 Ranger
(312847, 21, 22, 0, ''), -- Realm First! Level 70 Chronomancer
(312848, 21, 23, 0, ''), -- Realm First! Level 70 Necromancer
(312849, 21, 24, 0, ''), -- Realm First! Level 70 Pyromancer
(312850, 21, 25, 0, ''), -- Realm First! Level 70 Cultist
(312851, 21, 26, 0, ''), -- Realm First! Level 70 Starcaller
(312852, 21, 27, 0, ''), -- Realm First! Level 70 Sun Cleric
(312853, 21, 28, 0, ''), -- Realm First! Level 70 Tinker
(312854, 21, 29, 0, ''), -- Realm First! Level 70 Venomancer
(312855, 21, 30, 0, ''), -- Realm First! Level 70 Reaper
(312856, 21, 31, 0, ''), -- Realm First! Level 70 Primalist
(312857, 21, 32, 0, ''), -- Realm First! Level 70 Runemaster
(312858, 21, 12, 0, ''), -- Realm First! Level 80 Barbarian
(312859, 21, 13, 0, ''), -- Realm First! Level 80 Witch Doctor
(312860, 21, 14, 0, ''), -- Realm First! Level 80 Felsworn
(312861, 21, 15, 0, ''), -- Realm First! Level 80 Witch Hunter
(312862, 21, 16, 0, ''), -- Realm First! Level 80 Stormbringer
(312863, 21, 17, 0, ''), -- Realm First! Level 80 Knight of Xoroth
(312864, 21, 18, 0, ''), -- Realm First! Level 80 Guardian
(312865, 21, 19, 0, ''), -- Realm First! Level 80 Templar
(312866, 21, 20, 0, ''), -- Realm First! Level 80 Bloodmage
(312867, 21, 21, 0, ''), -- Realm First! Level 80 Ranger
(312868, 21, 22, 0, ''), -- Realm First! Level 80 Chronomancer
(312869, 21, 23, 0, ''), -- Realm First! Level 80 Necromancer
(312870, 21, 24, 0, ''), -- Realm First! Level 80 Pyromancer
(312871, 21, 25, 0, ''), -- Realm First! Level 80 Cultist
(312872, 21, 26, 0, ''), -- Realm First! Level 80 Starcaller
(312873, 21, 27, 0, ''), -- Realm First! Level 80 Sun Cleric
(312874, 21, 28, 0, ''), -- Realm First! Level 80 Tinker
(312875, 21, 29, 0, ''), -- Realm First! Level 80 Venomancer
(312876, 21, 30, 0, ''), -- Realm First! Level 80 Reaper
(312877, 21, 31, 0, ''), -- Realm First! Level 80 Primalist
(312878, 21, 32, 0, ''), -- Realm First! Level 80 Runemaster
(312879, 21, 6, 0, ''), -- Realm First! Level 70 Death Knight
(312880, 21, 10, 0, ''); -- Realm First! Level 70 Hero
