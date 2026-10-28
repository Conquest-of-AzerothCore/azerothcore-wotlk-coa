-- The Prestige achievements count kill credit of creature 888101, which mod-coa-prestige grants once per
-- activation. AzerothCore counts a kill-creature criterion only when achievement_criteria_data holds a row for
-- it, so Prestige 1-10 never completed. Plain criteria get a NONE row; the race and class realm firsts get
-- S_PLAYER_CLASS_RACE like the level realm firsts.
-- Generated from Achievement.dbc and Achievement_Criteria.dbc by apps/coa-wildcard/prestige_achievements.py.
DELETE FROM `achievement_criteria_data` WHERE `type` IN (0, 21) AND `criteria_id` IN (
30100, 30101, 30102, 30103, 30104, 30105, 30106, 30107, 30108, 30109, 30110, 30111, 30112, 30113,
30114, 30115, 30116, 30117, 30118, 30119, 30120, 30121, 30122, 30123, 30124, 30125, 30126, 30127,
30128, 30129, 30130, 30131, 30132, 30133, 30134, 30135, 30136, 30137, 30138, 30139, 30140, 30141,
30142, 30143, 30144, 30145, 30146, 30147, 30148, 30149, 30150, 30151, 30152, 30153, 30154, 30155,
30156, 30157, 30158, 30159, 30160, 30161, 30162, 30163, 30164, 30165, 30166, 30167, 30168, 30169,
30170, 30171, 30172, 30173, 30174, 30175, 30176, 30177, 30178, 30179, 30180, 30181, 30182, 30183,
30184, 30185, 30186, 30187, 30188, 30189, 30190, 30191, 30192, 30193, 30194, 30195, 30196, 30197,
30198, 30199, 30200, 30201, 30202, 30203, 30204, 30205, 30206, 30207, 30208, 30209, 30210, 30211,
30212, 30213, 30214, 30215, 30216, 30217, 30218, 30219, 150171, 150172, 150173, 150174, 150175, 150176,
150177, 150178, 150179, 150180, 150181, 150182, 150183, 150184, 150185, 150186, 150187, 150188, 150189, 150190,
150191, 150192, 150193, 150194, 150195, 150196, 150197, 150198, 150199, 150200, 150201, 150202, 150203, 150204,
150205, 150206, 150207, 150208, 150209, 150210, 150211, 150212, 150213, 150214, 150215, 150216, 150217, 150218,
150219, 150220, 150221, 150222, 150223, 150224, 150225, 150226, 150227, 150228, 150229, 150230, 150231, 150232,
150233, 150234, 150235, 150236, 150237, 150238, 150239, 150240, 150241, 150242, 150243, 150244, 150245, 150246,
150247, 150248, 150249, 150250, 150251, 150252, 150253, 150254, 150255, 150256, 150257, 150258, 150259, 150260,
150261, 150262, 150263, 150264, 150265, 150266, 150267, 150268, 150269, 150270, 150371, 150372, 150373, 150374,
150375, 150376, 150377, 150378, 150379, 150380, 150381, 150382, 150383, 150384, 150385, 150386, 150387, 150388,
150389, 150390, 150391, 150392, 150393, 150394, 150395, 150396, 150397, 150398, 150399, 150400, 150401, 150402,
150403, 150404, 150405, 150406, 150407, 150408, 150409, 150410, 150411, 150412, 150413, 150414, 150415, 150416,
150417, 150418, 150419, 150420, 150421, 150422, 150423, 150424, 150425, 150426, 150427, 150428, 150429, 150430,
150431, 150432, 150433, 150434, 150435, 150436, 150437, 150438, 150439, 150440, 150441, 150442, 150443, 150444,
150445, 150446, 150447, 150448, 150449, 150450, 150451, 150452, 150453, 150454, 150455, 150456, 150457, 150458,
150459, 150460, 150461, 150462, 150463, 150464, 150465, 150466, 150467, 150468, 150469, 150470, 150571, 150572,
150573, 150574, 150575, 150576, 150577, 150578, 150579, 150580, 150581, 150582, 150583, 150584, 150585, 150586,
150587, 150588, 150589, 150590, 150591, 150592, 150593, 150594, 150595, 150596, 150597, 150598, 150599, 150600,
150601, 150602, 150603, 150604, 150605, 150606, 150607, 150608, 150609, 150610, 150611, 150612, 150613, 150614,
150615, 150616, 150617, 150618, 150619, 150620, 150621, 150622, 150623, 150624, 150625, 150626, 150627, 150628,
150629, 150630, 150631, 150632, 150633, 150634, 150635, 150636, 150637, 150638, 150639, 150640, 150641, 150642,
150643, 150644, 150645, 150646, 150647, 150648, 150649, 150650, 150651, 150652, 150653, 150654, 150655, 150656,
150657, 150658, 150659, 150660, 150661, 150662, 150663, 150664, 150665, 150666, 150667, 150668, 150669, 150670,
150771, 150772, 150773, 150774, 150775, 150776, 150777, 150778, 150779, 150780, 150781, 150782, 150783, 150784,
150785, 150786, 150787, 150788, 150789, 150790, 150791, 150792, 150793, 150794, 150795, 150796, 150797, 150798,
150799, 150800, 150801, 150802, 150803, 150804, 150805, 150806, 150807, 150808, 150809, 150810, 150811, 150812,
150813, 150814, 150815, 150816, 150817, 150818, 150819, 150820, 150821, 150822, 150823, 150824, 150825, 150826,
150827, 150828, 150829, 150830, 150831, 150832, 150833, 150834, 150835, 150836, 150837, 150838, 150839, 150840,
150841, 150842, 150843, 150844, 150845, 150846, 150847, 150848, 150849, 150850, 150851, 150852, 150853, 150854,
150855, 150856, 150857, 150858, 150859, 150860, 150861, 150862, 150863, 150864, 150865, 150866, 150867, 150868,
150869, 150870, 150971, 150972, 150973, 150974, 150975, 150976, 150977, 150978, 150979, 150980, 150981, 150982,
150983, 150984, 150985, 150986, 150987, 150988, 150989, 150990, 150991, 150992, 150993, 150994, 150995, 150996,
150997, 150998, 150999, 151000, 151001, 151002, 151003, 151004, 151005, 151006, 151007, 151008, 151009, 151010,
151011, 151012, 151013, 151014, 151015, 151016, 151017, 151018, 151019, 151020, 151021, 151022, 151023, 151024,
151025, 151026, 151027, 151028, 151029, 151030, 151031, 151032, 151033, 151034, 151035, 151036, 151037, 151038,
151039, 151040, 151041, 151042, 151043, 151044, 151045, 151046, 151047, 151048, 151049, 151050, 151051, 151052,
151053, 151054, 151055, 151056, 151057, 151058, 151059, 151060, 151061, 151062, 151063, 151064, 151065, 151066,
151067, 151068, 151069, 151070, 151171, 151172, 151173, 151174, 151175, 151176, 151177, 151178, 151179, 151180,
151181, 151182, 151183, 151184, 151185, 151186, 151187, 151188, 151189, 151190, 151191, 151192, 151193, 151194,
151195, 151196, 151197, 151198, 151199, 151200, 151201, 151202, 151203, 151204, 151205, 151206, 151207, 151208,
151209, 151210, 151211, 151212, 151213, 151214, 151215, 151216, 151217, 151218, 151219, 151220, 151221, 151222,
151223, 151224, 151225, 151226, 151227, 151228, 151229, 151230, 151231, 151232, 151233, 151234, 151235, 151236,
151237, 151238, 151239, 151240, 151241, 151242, 151243, 151244, 151245, 151246, 151247, 151248, 151249, 151250,
151251, 151252, 151253, 151254, 151255, 151256, 151257, 151258, 151259, 151260, 151261, 151262, 151263, 151264,
151265, 151266, 151267, 151268, 151269, 151270, 151371, 151372, 151373, 151374, 151375, 151376, 151377, 151378,
151379, 151380, 151381, 151382, 151383, 151384, 151385, 151386, 151387, 151388, 151389, 151390, 151391, 151392,
151393, 151394, 151395, 151396, 151397, 151398, 151399, 151400, 151401, 151402, 151403, 151404, 151405, 151406,
151407, 151408, 151409, 151410, 151411, 151412, 151413, 151414, 151415, 151416, 151417, 151418, 151419, 151420,
151421, 151422, 151423, 151424, 151425, 151426, 151427, 151428, 151429, 151430, 151431, 151432, 151433, 151434,
151435, 151436, 151437, 151438, 151439, 151440, 151441, 151442, 151443, 151444, 151445, 151446, 151447, 151448,
151449, 151450, 151451, 151452, 151453, 151454, 151455, 151456, 151457, 151458, 151459, 151460, 151461, 151462,
151463, 151464, 151465, 151466, 151467, 151468, 151469, 151470, 151571, 151572, 151573, 151574, 151575, 151576,
151577, 151578, 151579, 151580, 151581, 151582, 151583, 151584, 151585, 151586, 151587, 151588, 151589, 151590,
151591, 151592, 151593, 151594, 151595, 151596, 151597, 151598, 151599, 151600, 151601, 151602, 151603, 151604,
151605, 151606, 151607, 151608, 151609, 151610, 151611, 151612, 151613, 151614, 151615, 151616, 151617, 151618,
151619, 151620, 151621, 151622, 151623, 151624, 151625, 151626, 151627, 151628, 151629, 151630, 151631, 151632,
151633, 151634, 151635, 151636, 151637, 151638, 151639, 151640, 151641, 151642, 151643, 151644, 151645, 151646,
151647, 151648, 151649, 151650, 151651, 151652, 151653, 151654, 151655, 151656, 151657, 151658, 151659, 151660,
151661, 151662, 151663, 151664, 151665, 151666, 151667, 151668, 151669, 151670, 151771, 151772, 151773, 151774,
151775, 151776, 151777, 151778, 151779, 151780, 151781, 151782, 151783, 151784, 151785, 151786, 151787, 151788,
151789, 151790, 151791, 151792, 151793, 151794, 151795, 151796, 151797, 151798, 151799, 151800, 151801, 151802,
151803, 151804, 151805, 151806, 151807, 151808, 151809, 151810, 151811, 151812, 151813, 151814, 151815, 151816,
151817, 151818, 151819, 151820, 151821, 151822, 151823, 151824, 151825, 151826, 151827, 151828, 151829, 151830,
151831, 151832, 151833, 151834, 151835, 151836, 151837, 151838, 151839, 151840, 151841, 151842, 151843, 151844,
151845, 151846, 151847, 151848, 151849, 151850, 151851, 151852, 151853, 151854, 151855, 151856, 151857, 151858,
151859, 151860, 151861, 151862, 151863, 151864, 151865, 151866, 151867, 151868, 151869, 151870, 151971, 151972,
151973, 151974, 151975, 151976, 151977, 151978, 151979, 151980, 151981, 151982, 151983, 151984, 151985, 151986,
151987, 151988, 151989, 151990, 151991, 151992, 151993, 151994, 151995, 151996, 151997, 151998, 151999, 152000,
152001, 152002, 152003, 152004, 152005, 152006, 152007, 152008, 152009, 152010, 152011, 152012, 152013, 152014,
152015, 152016, 152017, 152018, 152019, 152020, 152021, 152022, 152023, 152024, 152025, 152026, 152027, 152028,
152029, 152030, 152031, 152032, 152033, 152034, 152035, 152036, 152037, 152038, 152039, 152040, 152041, 152042,
152043, 152044, 152045, 152046, 152047, 152048, 152049, 152050, 152051, 152052, 152053, 152054, 152055, 152056,
152057, 152058, 152059, 152060, 152061, 152062, 152063, 152064, 152065, 152066, 152067, 152068, 152069, 152070);
INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`) VALUES
(30100, 0, 0, 0, ''), -- Prestige 1
(30101, 0, 0, 0, ''), -- Prestige 2
(30102, 0, 0, 0, ''), -- Prestige 3
(30103, 0, 0, 0, ''), -- Prestige 4
(30104, 0, 0, 0, ''), -- Prestige 5
(30105, 0, 0, 0, ''), -- Prestige 6
(30106, 0, 0, 0, ''), -- Prestige 7
(30107, 0, 0, 0, ''), -- Prestige 8
(30108, 0, 0, 0, ''), -- Prestige 9
(30109, 0, 0, 0, ''), -- Prestige 10
(30110, 0, 0, 0, ''), -- Realm First! Prestige 1
(30111, 0, 0, 0, ''), -- Realm First! Prestige 2
(30112, 0, 0, 0, ''), -- Realm First! Prestige 3
(30113, 0, 0, 0, ''), -- Realm First! Prestige 4
(30114, 0, 0, 0, ''), -- Realm First! Prestige 5
(30115, 0, 0, 0, ''), -- Realm First! Prestige 6
(30116, 0, 0, 0, ''), -- Realm First! Prestige 7
(30117, 0, 0, 0, ''), -- Realm First! Prestige 8
(30118, 0, 0, 0, ''), -- Realm First! Prestige 9
(30119, 0, 0, 0, ''), -- Realm First! Prestige 10
(30120, 21, 0, 1, ''), -- Realm First! Prestige 1 Human
(30121, 21, 0, 1, ''), -- Realm First! Prestige 2 Human
(30122, 21, 0, 1, ''), -- Realm First! Prestige 3 Human
(30123, 21, 0, 1, ''), -- Realm First! Prestige 4 Human
(30124, 21, 0, 1, ''), -- Realm First! Prestige 5 Human
(30125, 21, 0, 1, ''), -- Realm First! Prestige 6 Human
(30126, 21, 0, 1, ''), -- Realm First! Prestige 7 Human
(30127, 21, 0, 1, ''), -- Realm First! Prestige 8 Human
(30128, 21, 0, 1, ''), -- Realm First! Prestige 9 Human
(30129, 21, 0, 1, ''), -- Realm First! Prestige 10 Human
(30130, 21, 0, 3, ''), -- Realm First! Prestige 1 Dwarf
(30131, 21, 0, 3, ''), -- Realm First! Prestige 2 Dwarf
(30132, 21, 0, 3, ''), -- Realm First! Prestige 3 Dwarf
(30133, 21, 0, 3, ''), -- Realm First! Prestige 4 Dwarf
(30134, 21, 0, 3, ''), -- Realm First! Prestige 5 Dwarf
(30135, 21, 0, 3, ''), -- Realm First! Prestige 6 Dwarf
(30136, 21, 0, 3, ''), -- Realm First! Prestige 7 Dwarf
(30137, 21, 0, 3, ''), -- Realm First! Prestige 8 Dwarf
(30138, 21, 0, 3, ''), -- Realm First! Prestige 9 Dwarf
(30139, 21, 0, 3, ''), -- Realm First! Prestige 10 Dwarf
(30140, 21, 0, 4, ''), -- Realm First! Prestige 1 Night Elf
(30141, 21, 0, 4, ''), -- Realm First! Prestige 2 Night Elf
(30142, 21, 0, 4, ''), -- Realm First! Prestige 3 Night Elf
(30143, 21, 0, 4, ''), -- Realm First! Prestige 4 Night Elf
(30144, 21, 0, 4, ''), -- Realm First! Prestige 5 Night Elf
(30145, 21, 0, 4, ''), -- Realm First! Prestige 6 Night Elf
(30146, 21, 0, 4, ''), -- Realm First! Prestige 7 Night Elf
(30147, 21, 0, 4, ''), -- Realm First! Prestige 8 Night Elf
(30148, 21, 0, 4, ''), -- Realm First! Prestige 9 Night Elf
(30149, 21, 0, 4, ''), -- Realm First! Prestige 10 Night Elf
(30150, 21, 0, 7, ''), -- Realm First! Prestige 1 Gnome
(30151, 21, 0, 7, ''), -- Realm First! Prestige 2 Gnome
(30152, 21, 0, 7, ''), -- Realm First! Prestige 3 Gnome
(30153, 21, 0, 7, ''), -- Realm First! Prestige 4 Gnome
(30154, 21, 0, 7, ''), -- Realm First! Prestige 5 Gnome
(30155, 21, 0, 7, ''), -- Realm First! Prestige 6 Gnome
(30156, 21, 0, 7, ''), -- Realm First! Prestige 7 Gnome
(30157, 21, 0, 7, ''), -- Realm First! Prestige 8 Gnome
(30158, 21, 0, 7, ''), -- Realm First! Prestige 9 Gnome
(30159, 21, 0, 7, ''), -- Realm First! Prestige 10 Gnome
(30160, 21, 0, 11, ''), -- Realm First! Prestige 1 Draenei
(30161, 21, 0, 11, ''), -- Realm First! Prestige 2 Draenei
(30162, 21, 0, 11, ''), -- Realm First! Prestige 3 Draenei
(30163, 21, 0, 11, ''), -- Realm First! Prestige 4 Draenei
(30164, 21, 0, 11, ''), -- Realm First! Prestige 5 Draenei
(30165, 21, 0, 11, ''), -- Realm First! Prestige 6 Draenei
(30166, 21, 0, 11, ''), -- Realm First! Prestige 7 Draenei
(30167, 21, 0, 11, ''), -- Realm First! Prestige 8 Draenei
(30168, 21, 0, 11, ''), -- Realm First! Prestige 9 Draenei
(30169, 21, 0, 11, ''), -- Realm First! Prestige 10 Draenei
(30170, 21, 0, 2, ''), -- Realm First! Prestige 1 Orc
(30171, 21, 0, 2, ''), -- Realm First! Prestige 2 Orc
(30172, 21, 0, 2, ''), -- Realm First! Prestige 3 Orc
(30173, 21, 0, 2, ''), -- Realm First! Prestige 4 Orc
(30174, 21, 0, 2, ''), -- Realm First! Prestige 5 Orc
(30175, 21, 0, 2, ''), -- Realm First! Prestige 6 Orc
(30176, 21, 0, 2, ''), -- Realm First! Prestige 7 Orc
(30177, 21, 0, 2, ''), -- Realm First! Prestige 8 Orc
(30178, 21, 0, 2, ''), -- Realm First! Prestige 9 Orc
(30179, 21, 0, 2, ''), -- Realm First! Prestige 10 Orc
(30180, 21, 0, 5, ''), -- Realm First! Prestige 1 Undead
(30181, 21, 0, 5, ''), -- Realm First! Prestige 2 Undead
(30182, 21, 0, 5, ''), -- Realm First! Prestige 3 Undead
(30183, 21, 0, 5, ''), -- Realm First! Prestige 4 Undead
(30184, 21, 0, 5, ''), -- Realm First! Prestige 5 Undead
(30185, 21, 0, 5, ''), -- Realm First! Prestige 6 Undead
(30186, 21, 0, 5, ''), -- Realm First! Prestige 7 Undead
(30187, 21, 0, 5, ''), -- Realm First! Prestige 8 Undead
(30188, 21, 0, 5, ''), -- Realm First! Prestige 9 Undead
(30189, 21, 0, 5, ''), -- Realm First! Prestige 10 Undead
(30190, 21, 0, 6, ''), -- Realm First! Prestige 1 Tauren
(30191, 21, 0, 6, ''), -- Realm First! Prestige 2 Tauren
(30192, 21, 0, 6, ''), -- Realm First! Prestige 3 Tauren
(30193, 21, 0, 6, ''), -- Realm First! Prestige 4 Tauren
(30194, 21, 0, 6, ''), -- Realm First! Prestige 5 Tauren
(30195, 21, 0, 6, ''), -- Realm First! Prestige 6 Tauren
(30196, 21, 0, 6, ''), -- Realm First! Prestige 7 Tauren
(30197, 21, 0, 6, ''), -- Realm First! Prestige 8 Tauren
(30198, 21, 0, 6, ''), -- Realm First! Prestige 9 Tauren
(30199, 21, 0, 6, ''), -- Realm First! Prestige 10 Tauren
(30200, 21, 0, 8, ''), -- Realm First! Prestige 1 Troll
(30201, 21, 0, 8, ''), -- Realm First! Prestige 2 Troll
(30202, 21, 0, 8, ''), -- Realm First! Prestige 3 Troll
(30203, 21, 0, 8, ''), -- Realm First! Prestige 4 Troll
(30204, 21, 0, 8, ''), -- Realm First! Prestige 5 Troll
(30205, 21, 0, 8, ''), -- Realm First! Prestige 6 Troll
(30206, 21, 0, 8, ''), -- Realm First! Prestige 7 Troll
(30207, 21, 0, 8, ''), -- Realm First! Prestige 8 Troll
(30208, 21, 0, 8, ''), -- Realm First! Prestige 9 Troll
(30209, 21, 0, 8, ''), -- Realm First! Prestige 10 Troll
(30210, 21, 0, 10, ''), -- Realm First! Prestige 1 Blood Elf
(30211, 21, 0, 10, ''), -- Realm First! Prestige 2 Blood Elf
(30212, 21, 0, 10, ''), -- Realm First! Prestige 3 Blood Elf
(30213, 21, 0, 10, ''), -- Realm First! Prestige 4 Blood Elf
(30214, 21, 0, 10, ''), -- Realm First! Prestige 5 Blood Elf
(30215, 21, 0, 10, ''), -- Realm First! Prestige 6 Blood Elf
(30216, 21, 0, 10, ''), -- Realm First! Prestige 7 Blood Elf
(30217, 21, 0, 10, ''), -- Realm First! Prestige 8 Blood Elf
(30218, 21, 0, 10, ''), -- Realm First! Prestige 9 Blood Elf
(30219, 21, 0, 10, ''), -- Realm First! Prestige 10 Blood Elf
(150171, 21, 4, 1, ''), -- Realm First! Prestige 1 Human Rogue
(150172, 21, 4, 1, ''), -- Realm First! Prestige 2 Human Rogue
(150173, 21, 4, 1, ''), -- Realm First! Prestige 3 Human Rogue
(150174, 21, 4, 1, ''), -- Realm First! Prestige 4 Human Rogue
(150175, 21, 4, 1, ''), -- Realm First! Prestige 5 Human Rogue
(150176, 21, 4, 1, ''), -- Realm First! Prestige 6 Human Rogue
(150177, 21, 4, 1, ''), -- Realm First! Prestige 7 Human Rogue
(150178, 21, 4, 1, ''), -- Realm First! Prestige 8 Human Rogue
(150179, 21, 4, 1, ''), -- Realm First! Prestige 9 Human Rogue
(150180, 21, 4, 1, ''), -- Realm First! Prestige 10 Human Rogue
(150181, 21, 4, 3, ''), -- Realm First! Prestige 1 Dwarf Rogue
(150182, 21, 4, 3, ''), -- Realm First! Prestige 2 Dwarf Rogue
(150183, 21, 4, 3, ''), -- Realm First! Prestige 3 Dwarf Rogue
(150184, 21, 4, 3, ''), -- Realm First! Prestige 4 Dwarf Rogue
(150185, 21, 4, 3, ''), -- Realm First! Prestige 5 Dwarf Rogue
(150186, 21, 4, 3, ''), -- Realm First! Prestige 6 Dwarf Rogue
(150187, 21, 4, 3, ''), -- Realm First! Prestige 7 Dwarf Rogue
(150188, 21, 4, 3, ''), -- Realm First! Prestige 8 Dwarf Rogue
(150189, 21, 4, 3, ''), -- Realm First! Prestige 9 Dwarf Rogue
(150190, 21, 4, 3, ''), -- Realm First! Prestige 10 Dwarf Rogue
(150191, 21, 4, 4, ''), -- Realm First! Prestige 1 Night Elf Rogue
(150192, 21, 4, 4, ''), -- Realm First! Prestige 2 Night Elf Rogue
(150193, 21, 4, 4, ''), -- Realm First! Prestige 3 Night Elf Rogue
(150194, 21, 4, 4, ''), -- Realm First! Prestige 4 Night Elf Rogue
(150195, 21, 4, 4, ''), -- Realm First! Prestige 5 Night Elf Rogue
(150196, 21, 4, 4, ''), -- Realm First! Prestige 6 Night Elf Rogue
(150197, 21, 4, 4, ''), -- Realm First! Prestige 7 Night Elf Rogue
(150198, 21, 4, 4, ''), -- Realm First! Prestige 8 Night Elf Rogue
(150199, 21, 4, 4, ''), -- Realm First! Prestige 9 Night Elf Rogue
(150200, 21, 4, 4, ''), -- Realm First! Prestige 10 Night Elf Rogue
(150201, 21, 4, 7, ''), -- Realm First! Prestige 1 Gnome Rogue
(150202, 21, 4, 7, ''), -- Realm First! Prestige 2 Gnome Rogue
(150203, 21, 4, 7, ''), -- Realm First! Prestige 3 Gnome Rogue
(150204, 21, 4, 7, ''), -- Realm First! Prestige 4 Gnome Rogue
(150205, 21, 4, 7, ''), -- Realm First! Prestige 5 Gnome Rogue
(150206, 21, 4, 7, ''), -- Realm First! Prestige 6 Gnome Rogue
(150207, 21, 4, 7, ''), -- Realm First! Prestige 7 Gnome Rogue
(150208, 21, 4, 7, ''), -- Realm First! Prestige 8 Gnome Rogue
(150209, 21, 4, 7, ''), -- Realm First! Prestige 9 Gnome Rogue
(150210, 21, 4, 7, ''), -- Realm First! Prestige 10 Gnome Rogue
(150211, 21, 4, 11, ''), -- Realm First! Prestige 1 Draenei Rogue
(150212, 21, 4, 11, ''), -- Realm First! Prestige 2 Draenei Rogue
(150213, 21, 4, 11, ''), -- Realm First! Prestige 3 Draenei Rogue
(150214, 21, 4, 11, ''), -- Realm First! Prestige 4 Draenei Rogue
(150215, 21, 4, 11, ''), -- Realm First! Prestige 5 Draenei Rogue
(150216, 21, 4, 11, ''), -- Realm First! Prestige 6 Draenei Rogue
(150217, 21, 4, 11, ''), -- Realm First! Prestige 7 Draenei Rogue
(150218, 21, 4, 11, ''), -- Realm First! Prestige 8 Draenei Rogue
(150219, 21, 4, 11, ''), -- Realm First! Prestige 9 Draenei Rogue
(150220, 21, 4, 11, ''), -- Realm First! Prestige 10 Draenei Rogue
(150221, 21, 4, 2, ''), -- Realm First! Prestige 1 Orc Rogue
(150222, 21, 4, 2, ''), -- Realm First! Prestige 2 Orc Rogue
(150223, 21, 4, 2, ''), -- Realm First! Prestige 3 Orc Rogue
(150224, 21, 4, 2, ''), -- Realm First! Prestige 4 Orc Rogue
(150225, 21, 4, 2, ''), -- Realm First! Prestige 5 Orc Rogue
(150226, 21, 4, 2, ''), -- Realm First! Prestige 6 Orc Rogue
(150227, 21, 4, 2, ''), -- Realm First! Prestige 7 Orc Rogue
(150228, 21, 4, 2, ''), -- Realm First! Prestige 8 Orc Rogue
(150229, 21, 4, 2, ''), -- Realm First! Prestige 9 Orc Rogue
(150230, 21, 4, 2, ''), -- Realm First! Prestige 10 Orc Rogue
(150231, 21, 4, 5, ''), -- Realm First! Prestige 1 Undead Rogue
(150232, 21, 4, 5, ''), -- Realm First! Prestige 2 Undead Rogue
(150233, 21, 4, 5, ''), -- Realm First! Prestige 3 Undead Rogue
(150234, 21, 4, 5, ''), -- Realm First! Prestige 4 Undead Rogue
(150235, 21, 4, 5, ''), -- Realm First! Prestige 5 Undead Rogue
(150236, 21, 4, 5, ''), -- Realm First! Prestige 6 Undead Rogue
(150237, 21, 4, 5, ''), -- Realm First! Prestige 7 Undead Rogue
(150238, 21, 4, 5, ''), -- Realm First! Prestige 8 Undead Rogue
(150239, 21, 4, 5, ''), -- Realm First! Prestige 9 Undead Rogue
(150240, 21, 4, 5, ''), -- Realm First! Prestige 10 Undead Rogue
(150241, 21, 4, 6, ''), -- Realm First! Prestige 1 Tauren Rogue
(150242, 21, 4, 6, ''), -- Realm First! Prestige 2 Tauren Rogue
(150243, 21, 4, 6, ''), -- Realm First! Prestige 3 Tauren Rogue
(150244, 21, 4, 6, ''), -- Realm First! Prestige 4 Tauren Rogue
(150245, 21, 4, 6, ''), -- Realm First! Prestige 5 Tauren Rogue
(150246, 21, 4, 6, ''), -- Realm First! Prestige 6 Tauren Rogue
(150247, 21, 4, 6, ''), -- Realm First! Prestige 7 Tauren Rogue
(150248, 21, 4, 6, ''), -- Realm First! Prestige 8 Tauren Rogue
(150249, 21, 4, 6, ''), -- Realm First! Prestige 9 Tauren Rogue
(150250, 21, 4, 6, ''), -- Realm First! Prestige 10 Tauren Rogue
(150251, 21, 4, 8, ''), -- Realm First! Prestige 1 Troll Rogue
(150252, 21, 4, 8, ''), -- Realm First! Prestige 2 Troll Rogue
(150253, 21, 4, 8, ''), -- Realm First! Prestige 3 Troll Rogue
(150254, 21, 4, 8, ''), -- Realm First! Prestige 4 Troll Rogue
(150255, 21, 4, 8, ''), -- Realm First! Prestige 5 Troll Rogue
(150256, 21, 4, 8, ''), -- Realm First! Prestige 6 Troll Rogue
(150257, 21, 4, 8, ''), -- Realm First! Prestige 7 Troll Rogue
(150258, 21, 4, 8, ''), -- Realm First! Prestige 8 Troll Rogue
(150259, 21, 4, 8, ''), -- Realm First! Prestige 9 Troll Rogue
(150260, 21, 4, 8, ''), -- Realm First! Prestige 10 Troll Rogue
(150261, 21, 4, 10, ''), -- Realm First! Prestige 1 Blood Elf Rogue
(150262, 21, 4, 10, ''), -- Realm First! Prestige 2 Blood Elf Rogue
(150263, 21, 4, 10, ''), -- Realm First! Prestige 3 Blood Elf Rogue
(150264, 21, 4, 10, ''), -- Realm First! Prestige 4 Blood Elf Rogue
(150265, 21, 4, 10, ''), -- Realm First! Prestige 5 Blood Elf Rogue
(150266, 21, 4, 10, ''), -- Realm First! Prestige 6 Blood Elf Rogue
(150267, 21, 4, 10, ''), -- Realm First! Prestige 7 Blood Elf Rogue
(150268, 21, 4, 10, ''), -- Realm First! Prestige 8 Blood Elf Rogue
(150269, 21, 4, 10, ''), -- Realm First! Prestige 9 Blood Elf Rogue
(150270, 21, 4, 10, ''), -- Realm First! Prestige 10 Blood Elf Rogue
(150371, 21, 1, 1, ''), -- Realm First! Prestige 1 Human Warrior
(150372, 21, 1, 1, ''), -- Realm First! Prestige 2 Human Warrior
(150373, 21, 1, 1, ''), -- Realm First! Prestige 3 Human Warrior
(150374, 21, 1, 1, ''), -- Realm First! Prestige 4 Human Warrior
(150375, 21, 1, 1, ''), -- Realm First! Prestige 5 Human Warrior
(150376, 21, 1, 1, ''), -- Realm First! Prestige 6 Human Warrior
(150377, 21, 1, 1, ''), -- Realm First! Prestige 7 Human Warrior
(150378, 21, 1, 1, ''), -- Realm First! Prestige 8 Human Warrior
(150379, 21, 1, 1, ''), -- Realm First! Prestige 9 Human Warrior
(150380, 21, 1, 1, ''), -- Realm First! Prestige 10 Human Warrior
(150381, 21, 1, 3, ''), -- Realm First! Prestige 1 Dwarf Warrior
(150382, 21, 1, 3, ''), -- Realm First! Prestige 2 Dwarf Warrior
(150383, 21, 1, 3, ''), -- Realm First! Prestige 3 Dwarf Warrior
(150384, 21, 1, 3, ''), -- Realm First! Prestige 4 Dwarf Warrior
(150385, 21, 1, 3, ''), -- Realm First! Prestige 5 Dwarf Warrior
(150386, 21, 1, 3, ''), -- Realm First! Prestige 6 Dwarf Warrior
(150387, 21, 1, 3, ''), -- Realm First! Prestige 7 Dwarf Warrior
(150388, 21, 1, 3, ''), -- Realm First! Prestige 8 Dwarf Warrior
(150389, 21, 1, 3, ''), -- Realm First! Prestige 9 Dwarf Warrior
(150390, 21, 1, 3, ''), -- Realm First! Prestige 10 Dwarf Warrior
(150391, 21, 1, 4, ''), -- Realm First! Prestige 1 Night Elf Warrior
(150392, 21, 1, 4, ''), -- Realm First! Prestige 2 Night Elf Warrior
(150393, 21, 1, 4, ''), -- Realm First! Prestige 3 Night Elf Warrior
(150394, 21, 1, 4, ''), -- Realm First! Prestige 4 Night Elf Warrior
(150395, 21, 1, 4, ''), -- Realm First! Prestige 5 Night Elf Warrior
(150396, 21, 1, 4, ''), -- Realm First! Prestige 6 Night Elf Warrior
(150397, 21, 1, 4, ''), -- Realm First! Prestige 7 Night Elf Warrior
(150398, 21, 1, 4, ''), -- Realm First! Prestige 8 Night Elf Warrior
(150399, 21, 1, 4, ''), -- Realm First! Prestige 9 Night Elf Warrior
(150400, 21, 1, 4, ''), -- Realm First! Prestige 10 Night Elf Warrior
(150401, 21, 1, 7, ''), -- Realm First! Prestige 1 Gnome Warrior
(150402, 21, 1, 7, ''), -- Realm First! Prestige 2 Gnome Warrior
(150403, 21, 1, 7, ''), -- Realm First! Prestige 3 Gnome Warrior
(150404, 21, 1, 7, ''), -- Realm First! Prestige 4 Gnome Warrior
(150405, 21, 1, 7, ''), -- Realm First! Prestige 5 Gnome Warrior
(150406, 21, 1, 7, ''), -- Realm First! Prestige 6 Gnome Warrior
(150407, 21, 1, 7, ''), -- Realm First! Prestige 7 Gnome Warrior
(150408, 21, 1, 7, ''), -- Realm First! Prestige 8 Gnome Warrior
(150409, 21, 1, 7, ''), -- Realm First! Prestige 9 Gnome Warrior
(150410, 21, 1, 7, ''), -- Realm First! Prestige 10 Gnome Warrior
(150411, 21, 1, 11, ''), -- Realm First! Prestige 1 Draenei Warrior
(150412, 21, 1, 11, ''), -- Realm First! Prestige 2 Draenei Warrior
(150413, 21, 1, 11, ''), -- Realm First! Prestige 3 Draenei Warrior
(150414, 21, 1, 11, ''), -- Realm First! Prestige 4 Draenei Warrior
(150415, 21, 1, 11, ''), -- Realm First! Prestige 5 Draenei Warrior
(150416, 21, 1, 11, ''), -- Realm First! Prestige 6 Draenei Warrior
(150417, 21, 1, 11, ''), -- Realm First! Prestige 7 Draenei Warrior
(150418, 21, 1, 11, ''), -- Realm First! Prestige 8 Draenei Warrior
(150419, 21, 1, 11, ''), -- Realm First! Prestige 9 Draenei Warrior
(150420, 21, 1, 11, ''), -- Realm First! Prestige 10 Draenei Warrior
(150421, 21, 1, 2, ''), -- Realm First! Prestige 1 Orc Warrior
(150422, 21, 1, 2, ''), -- Realm First! Prestige 2 Orc Warrior
(150423, 21, 1, 2, ''), -- Realm First! Prestige 3 Orc Warrior
(150424, 21, 1, 2, ''), -- Realm First! Prestige 4 Orc Warrior
(150425, 21, 1, 2, ''), -- Realm First! Prestige 5 Orc Warrior
(150426, 21, 1, 2, ''), -- Realm First! Prestige 6 Orc Warrior
(150427, 21, 1, 2, ''), -- Realm First! Prestige 7 Orc Warrior
(150428, 21, 1, 2, ''), -- Realm First! Prestige 8 Orc Warrior
(150429, 21, 1, 2, ''), -- Realm First! Prestige 9 Orc Warrior
(150430, 21, 1, 2, ''), -- Realm First! Prestige 10 Orc Warrior
(150431, 21, 1, 5, ''), -- Realm First! Prestige 1 Undead Warrior
(150432, 21, 1, 5, ''), -- Realm First! Prestige 2 Undead Warrior
(150433, 21, 1, 5, ''), -- Realm First! Prestige 3 Undead Warrior
(150434, 21, 1, 5, ''), -- Realm First! Prestige 4 Undead Warrior
(150435, 21, 1, 5, ''), -- Realm First! Prestige 5 Undead Warrior
(150436, 21, 1, 5, ''), -- Realm First! Prestige 6 Undead Warrior
(150437, 21, 1, 5, ''), -- Realm First! Prestige 7 Undead Warrior
(150438, 21, 1, 5, ''), -- Realm First! Prestige 8 Undead Warrior
(150439, 21, 1, 5, ''), -- Realm First! Prestige 9 Undead Warrior
(150440, 21, 1, 5, ''), -- Realm First! Prestige 10 Undead Warrior
(150441, 21, 1, 6, ''), -- Realm First! Prestige 1 Tauren Warrior
(150442, 21, 1, 6, ''), -- Realm First! Prestige 2 Tauren Warrior
(150443, 21, 1, 6, ''), -- Realm First! Prestige 3 Tauren Warrior
(150444, 21, 1, 6, ''), -- Realm First! Prestige 4 Tauren Warrior
(150445, 21, 1, 6, ''), -- Realm First! Prestige 5 Tauren Warrior
(150446, 21, 1, 6, ''), -- Realm First! Prestige 6 Tauren Warrior
(150447, 21, 1, 6, ''), -- Realm First! Prestige 7 Tauren Warrior
(150448, 21, 1, 6, ''), -- Realm First! Prestige 8 Tauren Warrior
(150449, 21, 1, 6, ''), -- Realm First! Prestige 9 Tauren Warrior
(150450, 21, 1, 6, ''), -- Realm First! Prestige 10 Tauren Warrior
(150451, 21, 1, 8, ''), -- Realm First! Prestige 1 Troll Warrior
(150452, 21, 1, 8, ''), -- Realm First! Prestige 2 Troll Warrior
(150453, 21, 1, 8, ''), -- Realm First! Prestige 3 Troll Warrior
(150454, 21, 1, 8, ''), -- Realm First! Prestige 4 Troll Warrior
(150455, 21, 1, 8, ''), -- Realm First! Prestige 5 Troll Warrior
(150456, 21, 1, 8, ''), -- Realm First! Prestige 6 Troll Warrior
(150457, 21, 1, 8, ''), -- Realm First! Prestige 7 Troll Warrior
(150458, 21, 1, 8, ''), -- Realm First! Prestige 8 Troll Warrior
(150459, 21, 1, 8, ''), -- Realm First! Prestige 9 Troll Warrior
(150460, 21, 1, 8, ''), -- Realm First! Prestige 10 Troll Warrior
(150461, 21, 1, 10, ''), -- Realm First! Prestige 1 Blood Elf Warrior
(150462, 21, 1, 10, ''), -- Realm First! Prestige 2 Blood Elf Warrior
(150463, 21, 1, 10, ''), -- Realm First! Prestige 3 Blood Elf Warrior
(150464, 21, 1, 10, ''), -- Realm First! Prestige 4 Blood Elf Warrior
(150465, 21, 1, 10, ''), -- Realm First! Prestige 5 Blood Elf Warrior
(150466, 21, 1, 10, ''), -- Realm First! Prestige 6 Blood Elf Warrior
(150467, 21, 1, 10, ''), -- Realm First! Prestige 7 Blood Elf Warrior
(150468, 21, 1, 10, ''), -- Realm First! Prestige 8 Blood Elf Warrior
(150469, 21, 1, 10, ''), -- Realm First! Prestige 9 Blood Elf Warrior
(150470, 21, 1, 10, ''), -- Realm First! Prestige 10 Blood Elf Warrior
(150571, 21, 2, 1, ''), -- Realm First! Prestige 1 Human Paladin
(150572, 21, 2, 1, ''), -- Realm First! Prestige 2 Human Paladin
(150573, 21, 2, 1, ''), -- Realm First! Prestige 3 Human Paladin
(150574, 21, 2, 1, ''), -- Realm First! Prestige 4 Human Paladin
(150575, 21, 2, 1, ''), -- Realm First! Prestige 5 Human Paladin
(150576, 21, 2, 1, ''), -- Realm First! Prestige 6 Human Paladin
(150577, 21, 2, 1, ''), -- Realm First! Prestige 7 Human Paladin
(150578, 21, 2, 1, ''), -- Realm First! Prestige 8 Human Paladin
(150579, 21, 2, 1, ''), -- Realm First! Prestige 9 Human Paladin
(150580, 21, 2, 1, ''), -- Realm First! Prestige 10 Human Paladin
(150581, 21, 2, 3, ''), -- Realm First! Prestige 1 Dwarf Paladin
(150582, 21, 2, 3, ''), -- Realm First! Prestige 2 Dwarf Paladin
(150583, 21, 2, 3, ''), -- Realm First! Prestige 3 Dwarf Paladin
(150584, 21, 2, 3, ''), -- Realm First! Prestige 4 Dwarf Paladin
(150585, 21, 2, 3, ''), -- Realm First! Prestige 5 Dwarf Paladin
(150586, 21, 2, 3, ''), -- Realm First! Prestige 6 Dwarf Paladin
(150587, 21, 2, 3, ''), -- Realm First! Prestige 7 Dwarf Paladin
(150588, 21, 2, 3, ''), -- Realm First! Prestige 8 Dwarf Paladin
(150589, 21, 2, 3, ''), -- Realm First! Prestige 9 Dwarf Paladin
(150590, 21, 2, 3, ''), -- Realm First! Prestige 10 Dwarf Paladin
(150591, 21, 2, 4, ''), -- Realm First! Prestige 1 Night Elf Paladin
(150592, 21, 2, 4, ''), -- Realm First! Prestige 2 Night Elf Paladin
(150593, 21, 2, 4, ''), -- Realm First! Prestige 3 Night Elf Paladin
(150594, 21, 2, 4, ''), -- Realm First! Prestige 4 Night Elf Paladin
(150595, 21, 2, 4, ''), -- Realm First! Prestige 5 Night Elf Paladin
(150596, 21, 2, 4, ''), -- Realm First! Prestige 6 Night Elf Paladin
(150597, 21, 2, 4, ''), -- Realm First! Prestige 7 Night Elf Paladin
(150598, 21, 2, 4, ''), -- Realm First! Prestige 8 Night Elf Paladin
(150599, 21, 2, 4, ''), -- Realm First! Prestige 9 Night Elf Paladin
(150600, 21, 2, 4, ''), -- Realm First! Prestige 10 Night Elf Paladin
(150601, 21, 2, 7, ''), -- Realm First! Prestige 1 Gnome Paladin
(150602, 21, 2, 7, ''), -- Realm First! Prestige 2 Gnome Paladin
(150603, 21, 2, 7, ''), -- Realm First! Prestige 3 Gnome Paladin
(150604, 21, 2, 7, ''), -- Realm First! Prestige 4 Gnome Paladin
(150605, 21, 2, 7, ''), -- Realm First! Prestige 5 Gnome Paladin
(150606, 21, 2, 7, ''), -- Realm First! Prestige 6 Gnome Paladin
(150607, 21, 2, 7, ''), -- Realm First! Prestige 7 Gnome Paladin
(150608, 21, 2, 7, ''), -- Realm First! Prestige 8 Gnome Paladin
(150609, 21, 2, 7, ''), -- Realm First! Prestige 9 Gnome Paladin
(150610, 21, 2, 7, ''), -- Realm First! Prestige 10 Gnome Paladin
(150611, 21, 2, 11, ''), -- Realm First! Prestige 1 Draenei Paladin
(150612, 21, 2, 11, ''), -- Realm First! Prestige 2 Draenei Paladin
(150613, 21, 2, 11, ''), -- Realm First! Prestige 3 Draenei Paladin
(150614, 21, 2, 11, ''), -- Realm First! Prestige 4 Draenei Paladin
(150615, 21, 2, 11, ''), -- Realm First! Prestige 5 Draenei Paladin
(150616, 21, 2, 11, ''), -- Realm First! Prestige 6 Draenei Paladin
(150617, 21, 2, 11, ''), -- Realm First! Prestige 7 Draenei Paladin
(150618, 21, 2, 11, ''), -- Realm First! Prestige 8 Draenei Paladin
(150619, 21, 2, 11, ''), -- Realm First! Prestige 9 Draenei Paladin
(150620, 21, 2, 11, ''), -- Realm First! Prestige 10 Draenei Paladin
(150621, 21, 2, 2, ''), -- Realm First! Prestige 1 Orc Paladin
(150622, 21, 2, 2, ''), -- Realm First! Prestige 2 Orc Paladin
(150623, 21, 2, 2, ''), -- Realm First! Prestige 3 Orc Paladin
(150624, 21, 2, 2, ''), -- Realm First! Prestige 4 Orc Paladin
(150625, 21, 2, 2, ''), -- Realm First! Prestige 5 Orc Paladin
(150626, 21, 2, 2, ''), -- Realm First! Prestige 6 Orc Paladin
(150627, 21, 2, 2, ''), -- Realm First! Prestige 7 Orc Paladin
(150628, 21, 2, 2, ''), -- Realm First! Prestige 8 Orc Paladin
(150629, 21, 2, 2, ''), -- Realm First! Prestige 9 Orc Paladin
(150630, 21, 2, 2, ''), -- Realm First! Prestige 10 Orc Paladin
(150631, 21, 2, 5, ''), -- Realm First! Prestige 1 Undead Paladin
(150632, 21, 2, 5, ''), -- Realm First! Prestige 2 Undead Paladin
(150633, 21, 2, 5, ''), -- Realm First! Prestige 3 Undead Paladin
(150634, 21, 2, 5, ''), -- Realm First! Prestige 4 Undead Paladin
(150635, 21, 2, 5, ''), -- Realm First! Prestige 5 Undead Paladin
(150636, 21, 2, 5, ''), -- Realm First! Prestige 6 Undead Paladin
(150637, 21, 2, 5, ''), -- Realm First! Prestige 7 Undead Paladin
(150638, 21, 2, 5, ''), -- Realm First! Prestige 8 Undead Paladin
(150639, 21, 2, 5, ''), -- Realm First! Prestige 9 Undead Paladin
(150640, 21, 2, 5, ''), -- Realm First! Prestige 10 Undead Paladin
(150641, 21, 2, 6, ''), -- Realm First! Prestige 1 Tauren Paladin
(150642, 21, 2, 6, ''), -- Realm First! Prestige 2 Tauren Paladin
(150643, 21, 2, 6, ''), -- Realm First! Prestige 3 Tauren Paladin
(150644, 21, 2, 6, ''), -- Realm First! Prestige 4 Tauren Paladin
(150645, 21, 2, 6, ''), -- Realm First! Prestige 5 Tauren Paladin
(150646, 21, 2, 6, ''), -- Realm First! Prestige 6 Tauren Paladin
(150647, 21, 2, 6, ''), -- Realm First! Prestige 7 Tauren Paladin
(150648, 21, 2, 6, ''), -- Realm First! Prestige 8 Tauren Paladin
(150649, 21, 2, 6, ''), -- Realm First! Prestige 9 Tauren Paladin
(150650, 21, 2, 6, ''), -- Realm First! Prestige 10 Tauren Paladin
(150651, 21, 2, 8, ''), -- Realm First! Prestige 1 Troll Paladin
(150652, 21, 2, 8, ''), -- Realm First! Prestige 2 Troll Paladin
(150653, 21, 2, 8, ''), -- Realm First! Prestige 3 Troll Paladin
(150654, 21, 2, 8, ''), -- Realm First! Prestige 4 Troll Paladin
(150655, 21, 2, 8, ''), -- Realm First! Prestige 5 Troll Paladin
(150656, 21, 2, 8, ''), -- Realm First! Prestige 6 Troll Paladin
(150657, 21, 2, 8, ''), -- Realm First! Prestige 7 Troll Paladin
(150658, 21, 2, 8, ''), -- Realm First! Prestige 8 Troll Paladin
(150659, 21, 2, 8, ''), -- Realm First! Prestige 9 Troll Paladin
(150660, 21, 2, 8, ''), -- Realm First! Prestige 10 Troll Paladin
(150661, 21, 2, 10, ''), -- Realm First! Prestige 1 Blood Elf Paladin
(150662, 21, 2, 10, ''), -- Realm First! Prestige 2 Blood Elf Paladin
(150663, 21, 2, 10, ''), -- Realm First! Prestige 3 Blood Elf Paladin
(150664, 21, 2, 10, ''), -- Realm First! Prestige 4 Blood Elf Paladin
(150665, 21, 2, 10, ''), -- Realm First! Prestige 5 Blood Elf Paladin
(150666, 21, 2, 10, ''), -- Realm First! Prestige 6 Blood Elf Paladin
(150667, 21, 2, 10, ''), -- Realm First! Prestige 7 Blood Elf Paladin
(150668, 21, 2, 10, ''), -- Realm First! Prestige 8 Blood Elf Paladin
(150669, 21, 2, 10, ''), -- Realm First! Prestige 9 Blood Elf Paladin
(150670, 21, 2, 10, ''), -- Realm First! Prestige 10 Blood Elf Paladin
(150771, 21, 3, 1, ''), -- Realm First! Prestige 1 Human Hunter
(150772, 21, 3, 1, ''), -- Realm First! Prestige 2 Human Hunter
(150773, 21, 3, 1, ''), -- Realm First! Prestige 3 Human Hunter
(150774, 21, 3, 1, ''), -- Realm First! Prestige 4 Human Hunter
(150775, 21, 3, 1, ''), -- Realm First! Prestige 5 Human Hunter
(150776, 21, 3, 1, ''), -- Realm First! Prestige 6 Human Hunter
(150777, 21, 3, 1, ''), -- Realm First! Prestige 7 Human Hunter
(150778, 21, 3, 1, ''), -- Realm First! Prestige 8 Human Hunter
(150779, 21, 3, 1, ''), -- Realm First! Prestige 9 Human Hunter
(150780, 21, 3, 1, ''), -- Realm First! Prestige 10 Human Hunter
(150781, 21, 3, 3, ''), -- Realm First! Prestige 1 Dwarf Hunter
(150782, 21, 3, 3, ''), -- Realm First! Prestige 2 Dwarf Hunter
(150783, 21, 3, 3, ''), -- Realm First! Prestige 3 Dwarf Hunter
(150784, 21, 3, 3, ''), -- Realm First! Prestige 4 Dwarf Hunter
(150785, 21, 3, 3, ''), -- Realm First! Prestige 5 Dwarf Hunter
(150786, 21, 3, 3, ''), -- Realm First! Prestige 6 Dwarf Hunter
(150787, 21, 3, 3, ''), -- Realm First! Prestige 7 Dwarf Hunter
(150788, 21, 3, 3, ''), -- Realm First! Prestige 8 Dwarf Hunter
(150789, 21, 3, 3, ''), -- Realm First! Prestige 9 Dwarf Hunter
(150790, 21, 3, 3, ''), -- Realm First! Prestige 10 Dwarf Hunter
(150791, 21, 3, 4, ''), -- Realm First! Prestige 1 Night Elf Hunter
(150792, 21, 3, 4, ''), -- Realm First! Prestige 2 Night Elf Hunter
(150793, 21, 3, 4, ''), -- Realm First! Prestige 3 Night Elf Hunter
(150794, 21, 3, 4, ''), -- Realm First! Prestige 4 Night Elf Hunter
(150795, 21, 3, 4, ''), -- Realm First! Prestige 5 Night Elf Hunter
(150796, 21, 3, 4, ''), -- Realm First! Prestige 6 Night Elf Hunter
(150797, 21, 3, 4, ''), -- Realm First! Prestige 7 Night Elf Hunter
(150798, 21, 3, 4, ''), -- Realm First! Prestige 8 Night Elf Hunter
(150799, 21, 3, 4, ''), -- Realm First! Prestige 9 Night Elf Hunter
(150800, 21, 3, 4, ''), -- Realm First! Prestige 10 Night Elf Hunter
(150801, 21, 3, 7, ''), -- Realm First! Prestige 1 Gnome Hunter
(150802, 21, 3, 7, ''), -- Realm First! Prestige 2 Gnome Hunter
(150803, 21, 3, 7, ''), -- Realm First! Prestige 3 Gnome Hunter
(150804, 21, 3, 7, ''), -- Realm First! Prestige 4 Gnome Hunter
(150805, 21, 3, 7, ''), -- Realm First! Prestige 5 Gnome Hunter
(150806, 21, 3, 7, ''), -- Realm First! Prestige 6 Gnome Hunter
(150807, 21, 3, 7, ''), -- Realm First! Prestige 7 Gnome Hunter
(150808, 21, 3, 7, ''), -- Realm First! Prestige 8 Gnome Hunter
(150809, 21, 3, 7, ''), -- Realm First! Prestige 9 Gnome Hunter
(150810, 21, 3, 7, ''), -- Realm First! Prestige 10 Gnome Hunter
(150811, 21, 3, 11, ''), -- Realm First! Prestige 1 Draenei Hunter
(150812, 21, 3, 11, ''), -- Realm First! Prestige 2 Draenei Hunter
(150813, 21, 3, 11, ''), -- Realm First! Prestige 3 Draenei Hunter
(150814, 21, 3, 11, ''), -- Realm First! Prestige 4 Draenei Hunter
(150815, 21, 3, 11, ''), -- Realm First! Prestige 5 Draenei Hunter
(150816, 21, 3, 11, ''), -- Realm First! Prestige 6 Draenei Hunter
(150817, 21, 3, 11, ''), -- Realm First! Prestige 7 Draenei Hunter
(150818, 21, 3, 11, ''), -- Realm First! Prestige 8 Draenei Hunter
(150819, 21, 3, 11, ''), -- Realm First! Prestige 9 Draenei Hunter
(150820, 21, 3, 11, ''), -- Realm First! Prestige 10 Draenei Hunter
(150821, 21, 3, 2, ''), -- Realm First! Prestige 1 Orc Hunter
(150822, 21, 3, 2, ''), -- Realm First! Prestige 2 Orc Hunter
(150823, 21, 3, 2, ''), -- Realm First! Prestige 3 Orc Hunter
(150824, 21, 3, 2, ''), -- Realm First! Prestige 4 Orc Hunter
(150825, 21, 3, 2, ''), -- Realm First! Prestige 5 Orc Hunter
(150826, 21, 3, 2, ''), -- Realm First! Prestige 6 Orc Hunter
(150827, 21, 3, 2, ''), -- Realm First! Prestige 7 Orc Hunter
(150828, 21, 3, 2, ''), -- Realm First! Prestige 8 Orc Hunter
(150829, 21, 3, 2, ''), -- Realm First! Prestige 9 Orc Hunter
(150830, 21, 3, 2, ''), -- Realm First! Prestige 10 Orc Hunter
(150831, 21, 3, 5, ''), -- Realm First! Prestige 1 Undead Hunter
(150832, 21, 3, 5, ''), -- Realm First! Prestige 2 Undead Hunter
(150833, 21, 3, 5, ''), -- Realm First! Prestige 3 Undead Hunter
(150834, 21, 3, 5, ''), -- Realm First! Prestige 4 Undead Hunter
(150835, 21, 3, 5, ''), -- Realm First! Prestige 5 Undead Hunter
(150836, 21, 3, 5, ''), -- Realm First! Prestige 6 Undead Hunter
(150837, 21, 3, 5, ''), -- Realm First! Prestige 7 Undead Hunter
(150838, 21, 3, 5, ''), -- Realm First! Prestige 8 Undead Hunter
(150839, 21, 3, 5, ''), -- Realm First! Prestige 9 Undead Hunter
(150840, 21, 3, 5, ''), -- Realm First! Prestige 10 Undead Hunter
(150841, 21, 3, 6, ''), -- Realm First! Prestige 1 Tauren Hunter
(150842, 21, 3, 6, ''), -- Realm First! Prestige 2 Tauren Hunter
(150843, 21, 3, 6, ''), -- Realm First! Prestige 3 Tauren Hunter
(150844, 21, 3, 6, ''), -- Realm First! Prestige 4 Tauren Hunter
(150845, 21, 3, 6, ''), -- Realm First! Prestige 5 Tauren Hunter
(150846, 21, 3, 6, ''), -- Realm First! Prestige 6 Tauren Hunter
(150847, 21, 3, 6, ''), -- Realm First! Prestige 7 Tauren Hunter
(150848, 21, 3, 6, ''), -- Realm First! Prestige 8 Tauren Hunter
(150849, 21, 3, 6, ''), -- Realm First! Prestige 9 Tauren Hunter
(150850, 21, 3, 6, ''), -- Realm First! Prestige 10 Tauren Hunter
(150851, 21, 3, 8, ''), -- Realm First! Prestige 1 Troll Hunter
(150852, 21, 3, 8, ''), -- Realm First! Prestige 2 Troll Hunter
(150853, 21, 3, 8, ''), -- Realm First! Prestige 3 Troll Hunter
(150854, 21, 3, 8, ''), -- Realm First! Prestige 4 Troll Hunter
(150855, 21, 3, 8, ''), -- Realm First! Prestige 5 Troll Hunter
(150856, 21, 3, 8, ''), -- Realm First! Prestige 6 Troll Hunter
(150857, 21, 3, 8, ''), -- Realm First! Prestige 7 Troll Hunter
(150858, 21, 3, 8, ''), -- Realm First! Prestige 8 Troll Hunter
(150859, 21, 3, 8, ''), -- Realm First! Prestige 9 Troll Hunter
(150860, 21, 3, 8, ''), -- Realm First! Prestige 10 Troll Hunter
(150861, 21, 3, 10, ''), -- Realm First! Prestige 1 Blood Elf Hunter
(150862, 21, 3, 10, ''), -- Realm First! Prestige 2 Blood Elf Hunter
(150863, 21, 3, 10, ''), -- Realm First! Prestige 3 Blood Elf Hunter
(150864, 21, 3, 10, ''), -- Realm First! Prestige 4 Blood Elf Hunter
(150865, 21, 3, 10, ''), -- Realm First! Prestige 5 Blood Elf Hunter
(150866, 21, 3, 10, ''), -- Realm First! Prestige 6 Blood Elf Hunter
(150867, 21, 3, 10, ''), -- Realm First! Prestige 7 Blood Elf Hunter
(150868, 21, 3, 10, ''), -- Realm First! Prestige 8 Blood Elf Hunter
(150869, 21, 3, 10, ''), -- Realm First! Prestige 9 Blood Elf Hunter
(150870, 21, 3, 10, ''), -- Realm First! Prestige 10 Blood Elf Hunter
(150971, 21, 5, 1, ''), -- Realm First! Prestige 1 Human Priest
(150972, 21, 5, 1, ''), -- Realm First! Prestige 2 Human Priest
(150973, 21, 5, 1, ''), -- Realm First! Prestige 3 Human Priest
(150974, 21, 5, 1, ''), -- Realm First! Prestige 4 Human Priest
(150975, 21, 5, 1, ''), -- Realm First! Prestige 5 Human Priest
(150976, 21, 5, 1, ''), -- Realm First! Prestige 6 Human Priest
(150977, 21, 5, 1, ''), -- Realm First! Prestige 7 Human Priest
(150978, 21, 5, 1, ''), -- Realm First! Prestige 8 Human Priest
(150979, 21, 5, 1, ''), -- Realm First! Prestige 9 Human Priest
(150980, 21, 5, 1, ''), -- Realm First! Prestige 10 Human Priest
(150981, 21, 5, 3, ''), -- Realm First! Prestige 1 Dwarf Priest
(150982, 21, 5, 3, ''), -- Realm First! Prestige 2 Dwarf Priest
(150983, 21, 5, 3, ''), -- Realm First! Prestige 3 Dwarf Priest
(150984, 21, 5, 3, ''), -- Realm First! Prestige 4 Dwarf Priest
(150985, 21, 5, 3, ''), -- Realm First! Prestige 5 Dwarf Priest
(150986, 21, 5, 3, ''), -- Realm First! Prestige 6 Dwarf Priest
(150987, 21, 5, 3, ''), -- Realm First! Prestige 7 Dwarf Priest
(150988, 21, 5, 3, ''), -- Realm First! Prestige 8 Dwarf Priest
(150989, 21, 5, 3, ''), -- Realm First! Prestige 9 Dwarf Priest
(150990, 21, 5, 3, ''), -- Realm First! Prestige 10 Dwarf Priest
(150991, 21, 5, 4, ''), -- Realm First! Prestige 1 Night Elf Priest
(150992, 21, 5, 4, ''), -- Realm First! Prestige 2 Night Elf Priest
(150993, 21, 5, 4, ''), -- Realm First! Prestige 3 Night Elf Priest
(150994, 21, 5, 4, ''), -- Realm First! Prestige 4 Night Elf Priest
(150995, 21, 5, 4, ''), -- Realm First! Prestige 5 Night Elf Priest
(150996, 21, 5, 4, ''), -- Realm First! Prestige 6 Night Elf Priest
(150997, 21, 5, 4, ''), -- Realm First! Prestige 7 Night Elf Priest
(150998, 21, 5, 4, ''), -- Realm First! Prestige 8 Night Elf Priest
(150999, 21, 5, 4, ''), -- Realm First! Prestige 9 Night Elf Priest
(151000, 21, 5, 4, ''), -- Realm First! Prestige 10 Night Elf Priest
(151001, 21, 5, 7, ''), -- Realm First! Prestige 1 Gnome Priest
(151002, 21, 5, 7, ''), -- Realm First! Prestige 2 Gnome Priest
(151003, 21, 5, 7, ''), -- Realm First! Prestige 3 Gnome Priest
(151004, 21, 5, 7, ''), -- Realm First! Prestige 4 Gnome Priest
(151005, 21, 5, 7, ''), -- Realm First! Prestige 5 Gnome Priest
(151006, 21, 5, 7, ''), -- Realm First! Prestige 6 Gnome Priest
(151007, 21, 5, 7, ''), -- Realm First! Prestige 7 Gnome Priest
(151008, 21, 5, 7, ''), -- Realm First! Prestige 8 Gnome Priest
(151009, 21, 5, 7, ''), -- Realm First! Prestige 9 Gnome Priest
(151010, 21, 5, 7, ''), -- Realm First! Prestige 10 Gnome Priest
(151011, 21, 5, 11, ''), -- Realm First! Prestige 1 Draenei Priest
(151012, 21, 5, 11, ''), -- Realm First! Prestige 2 Draenei Priest
(151013, 21, 5, 11, ''), -- Realm First! Prestige 3 Draenei Priest
(151014, 21, 5, 11, ''), -- Realm First! Prestige 4 Draenei Priest
(151015, 21, 5, 11, ''), -- Realm First! Prestige 5 Draenei Priest
(151016, 21, 5, 11, ''), -- Realm First! Prestige 6 Draenei Priest
(151017, 21, 5, 11, ''), -- Realm First! Prestige 7 Draenei Priest
(151018, 21, 5, 11, ''), -- Realm First! Prestige 8 Draenei Priest
(151019, 21, 5, 11, ''), -- Realm First! Prestige 9 Draenei Priest
(151020, 21, 5, 11, ''), -- Realm First! Prestige 10 Draenei Priest
(151021, 21, 5, 2, ''), -- Realm First! Prestige 1 Orc Priest
(151022, 21, 5, 2, ''), -- Realm First! Prestige 2 Orc Priest
(151023, 21, 5, 2, ''), -- Realm First! Prestige 3 Orc Priest
(151024, 21, 5, 2, ''), -- Realm First! Prestige 4 Orc Priest
(151025, 21, 5, 2, ''), -- Realm First! Prestige 5 Orc Priest
(151026, 21, 5, 2, ''), -- Realm First! Prestige 6 Orc Priest
(151027, 21, 5, 2, ''), -- Realm First! Prestige 7 Orc Priest
(151028, 21, 5, 2, ''), -- Realm First! Prestige 8 Orc Priest
(151029, 21, 5, 2, ''), -- Realm First! Prestige 9 Orc Priest
(151030, 21, 5, 2, ''), -- Realm First! Prestige 10 Orc Priest
(151031, 21, 5, 5, ''), -- Realm First! Prestige 1 Undead Priest
(151032, 21, 5, 5, ''), -- Realm First! Prestige 2 Undead Priest
(151033, 21, 5, 5, ''), -- Realm First! Prestige 3 Undead Priest
(151034, 21, 5, 5, ''), -- Realm First! Prestige 4 Undead Priest
(151035, 21, 5, 5, ''), -- Realm First! Prestige 5 Undead Priest
(151036, 21, 5, 5, ''), -- Realm First! Prestige 6 Undead Priest
(151037, 21, 5, 5, ''), -- Realm First! Prestige 7 Undead Priest
(151038, 21, 5, 5, ''), -- Realm First! Prestige 8 Undead Priest
(151039, 21, 5, 5, ''), -- Realm First! Prestige 9 Undead Priest
(151040, 21, 5, 5, ''), -- Realm First! Prestige 10 Undead Priest
(151041, 21, 5, 6, ''), -- Realm First! Prestige 1 Tauren Priest
(151042, 21, 5, 6, ''), -- Realm First! Prestige 2 Tauren Priest
(151043, 21, 5, 6, ''), -- Realm First! Prestige 3 Tauren Priest
(151044, 21, 5, 6, ''), -- Realm First! Prestige 4 Tauren Priest
(151045, 21, 5, 6, ''), -- Realm First! Prestige 5 Tauren Priest
(151046, 21, 5, 6, ''), -- Realm First! Prestige 6 Tauren Priest
(151047, 21, 5, 6, ''), -- Realm First! Prestige 7 Tauren Priest
(151048, 21, 5, 6, ''), -- Realm First! Prestige 8 Tauren Priest
(151049, 21, 5, 6, ''), -- Realm First! Prestige 9 Tauren Priest
(151050, 21, 5, 6, ''), -- Realm First! Prestige 10 Tauren Priest
(151051, 21, 5, 8, ''), -- Realm First! Prestige 1 Troll Priest
(151052, 21, 5, 8, ''), -- Realm First! Prestige 2 Troll Priest
(151053, 21, 5, 8, ''), -- Realm First! Prestige 3 Troll Priest
(151054, 21, 5, 8, ''), -- Realm First! Prestige 4 Troll Priest
(151055, 21, 5, 8, ''), -- Realm First! Prestige 5 Troll Priest
(151056, 21, 5, 8, ''), -- Realm First! Prestige 6 Troll Priest
(151057, 21, 5, 8, ''), -- Realm First! Prestige 7 Troll Priest
(151058, 21, 5, 8, ''), -- Realm First! Prestige 8 Troll Priest
(151059, 21, 5, 8, ''), -- Realm First! Prestige 9 Troll Priest
(151060, 21, 5, 8, ''), -- Realm First! Prestige 10 Troll Priest
(151061, 21, 5, 10, ''), -- Realm First! Prestige 1 Blood Elf Priest
(151062, 21, 5, 10, ''), -- Realm First! Prestige 2 Blood Elf Priest
(151063, 21, 5, 10, ''), -- Realm First! Prestige 3 Blood Elf Priest
(151064, 21, 5, 10, ''), -- Realm First! Prestige 4 Blood Elf Priest
(151065, 21, 5, 10, ''), -- Realm First! Prestige 5 Blood Elf Priest
(151066, 21, 5, 10, ''), -- Realm First! Prestige 6 Blood Elf Priest
(151067, 21, 5, 10, ''), -- Realm First! Prestige 7 Blood Elf Priest
(151068, 21, 5, 10, ''), -- Realm First! Prestige 8 Blood Elf Priest
(151069, 21, 5, 10, ''), -- Realm First! Prestige 9 Blood Elf Priest
(151070, 21, 5, 10, ''), -- Realm First! Prestige 10 Blood Elf Priest
(151171, 21, 6, 1, ''), -- Realm First! Prestige 1 Human Death Knight
(151172, 21, 6, 1, ''), -- Realm First! Prestige 2 Human Death Knight
(151173, 21, 6, 1, ''), -- Realm First! Prestige 3 Human Death Knight
(151174, 21, 6, 1, ''), -- Realm First! Prestige 4 Human Death Knight
(151175, 21, 6, 1, ''), -- Realm First! Prestige 5 Human Death Knight
(151176, 21, 6, 1, ''), -- Realm First! Prestige 6 Human Death Knight
(151177, 21, 6, 1, ''), -- Realm First! Prestige 7 Human Death Knight
(151178, 21, 6, 1, ''), -- Realm First! Prestige 8 Human Death Knight
(151179, 21, 6, 1, ''), -- Realm First! Prestige 9 Human Death Knight
(151180, 21, 6, 1, ''), -- Realm First! Prestige 10 Human Death Knight
(151181, 21, 6, 3, ''), -- Realm First! Prestige 1 Dwarf Death Knight
(151182, 21, 6, 3, ''), -- Realm First! Prestige 2 Dwarf Death Knight
(151183, 21, 6, 3, ''), -- Realm First! Prestige 3 Dwarf Death Knight
(151184, 21, 6, 3, ''), -- Realm First! Prestige 4 Dwarf Death Knight
(151185, 21, 6, 3, ''), -- Realm First! Prestige 5 Dwarf Death Knight
(151186, 21, 6, 3, ''), -- Realm First! Prestige 6 Dwarf Death Knight
(151187, 21, 6, 3, ''), -- Realm First! Prestige 7 Dwarf Death Knight
(151188, 21, 6, 3, ''), -- Realm First! Prestige 8 Dwarf Death Knight
(151189, 21, 6, 3, ''), -- Realm First! Prestige 9 Dwarf Death Knight
(151190, 21, 6, 3, ''), -- Realm First! Prestige 10 Dwarf Death Knight
(151191, 21, 6, 4, ''), -- Realm First! Prestige 1 Night Elf Death Knight
(151192, 21, 6, 4, ''), -- Realm First! Prestige 2 Night Elf Death Knight
(151193, 21, 6, 4, ''), -- Realm First! Prestige 3 Night Elf Death Knight
(151194, 21, 6, 4, ''), -- Realm First! Prestige 4 Night Elf Death Knight
(151195, 21, 6, 4, ''), -- Realm First! Prestige 5 Night Elf Death Knight
(151196, 21, 6, 4, ''), -- Realm First! Prestige 6 Night Elf Death Knight
(151197, 21, 6, 4, ''), -- Realm First! Prestige 7 Night Elf Death Knight
(151198, 21, 6, 4, ''), -- Realm First! Prestige 8 Night Elf Death Knight
(151199, 21, 6, 4, ''), -- Realm First! Prestige 9 Night Elf Death Knight
(151200, 21, 6, 4, ''), -- Realm First! Prestige 10 Night Elf Death Knight
(151201, 21, 6, 7, ''), -- Realm First! Prestige 1 Gnome Death Knight
(151202, 21, 6, 7, ''), -- Realm First! Prestige 2 Gnome Death Knight
(151203, 21, 6, 7, ''), -- Realm First! Prestige 3 Gnome Death Knight
(151204, 21, 6, 7, ''), -- Realm First! Prestige 4 Gnome Death Knight
(151205, 21, 6, 7, ''), -- Realm First! Prestige 5 Gnome Death Knight
(151206, 21, 6, 7, ''), -- Realm First! Prestige 6 Gnome Death Knight
(151207, 21, 6, 7, ''), -- Realm First! Prestige 7 Gnome Death Knight
(151208, 21, 6, 7, ''), -- Realm First! Prestige 8 Gnome Death Knight
(151209, 21, 6, 7, ''), -- Realm First! Prestige 9 Gnome Death Knight
(151210, 21, 6, 7, ''), -- Realm First! Prestige 10 Gnome Death Knight
(151211, 21, 6, 11, ''), -- Realm First! Prestige 1 Draenei Death Knight
(151212, 21, 6, 11, ''), -- Realm First! Prestige 2 Draenei Death Knight
(151213, 21, 6, 11, ''), -- Realm First! Prestige 3 Draenei Death Knight
(151214, 21, 6, 11, ''), -- Realm First! Prestige 4 Draenei Death Knight
(151215, 21, 6, 11, ''), -- Realm First! Prestige 5 Draenei Death Knight
(151216, 21, 6, 11, ''), -- Realm First! Prestige 6 Draenei Death Knight
(151217, 21, 6, 11, ''), -- Realm First! Prestige 7 Draenei Death Knight
(151218, 21, 6, 11, ''), -- Realm First! Prestige 8 Draenei Death Knight
(151219, 21, 6, 11, ''), -- Realm First! Prestige 9 Draenei Death Knight
(151220, 21, 6, 11, ''), -- Realm First! Prestige 10 Draenei Death Knight
(151221, 21, 6, 2, ''), -- Realm First! Prestige 1 Orc Death Knight
(151222, 21, 6, 2, ''), -- Realm First! Prestige 2 Orc Death Knight
(151223, 21, 6, 2, ''), -- Realm First! Prestige 3 Orc Death Knight
(151224, 21, 6, 2, ''), -- Realm First! Prestige 4 Orc Death Knight
(151225, 21, 6, 2, ''), -- Realm First! Prestige 5 Orc Death Knight
(151226, 21, 6, 2, ''), -- Realm First! Prestige 6 Orc Death Knight
(151227, 21, 6, 2, ''), -- Realm First! Prestige 7 Orc Death Knight
(151228, 21, 6, 2, ''), -- Realm First! Prestige 8 Orc Death Knight
(151229, 21, 6, 2, ''), -- Realm First! Prestige 9 Orc Death Knight
(151230, 21, 6, 2, ''), -- Realm First! Prestige 10 Orc Death Knight
(151231, 21, 6, 5, ''), -- Realm First! Prestige 1 Undead Death Knight
(151232, 21, 6, 5, ''), -- Realm First! Prestige 2 Undead Death Knight
(151233, 21, 6, 5, ''), -- Realm First! Prestige 3 Undead Death Knight
(151234, 21, 6, 5, ''), -- Realm First! Prestige 4 Undead Death Knight
(151235, 21, 6, 5, ''), -- Realm First! Prestige 5 Undead Death Knight
(151236, 21, 6, 5, ''), -- Realm First! Prestige 6 Undead Death Knight
(151237, 21, 6, 5, ''), -- Realm First! Prestige 7 Undead Death Knight
(151238, 21, 6, 5, ''), -- Realm First! Prestige 8 Undead Death Knight
(151239, 21, 6, 5, ''), -- Realm First! Prestige 9 Undead Death Knight
(151240, 21, 6, 5, ''), -- Realm First! Prestige 10 Undead Death Knight
(151241, 21, 6, 6, ''), -- Realm First! Prestige 1 Tauren Death Knight
(151242, 21, 6, 6, ''), -- Realm First! Prestige 2 Tauren Death Knight
(151243, 21, 6, 6, ''), -- Realm First! Prestige 3 Tauren Death Knight
(151244, 21, 6, 6, ''), -- Realm First! Prestige 4 Tauren Death Knight
(151245, 21, 6, 6, ''), -- Realm First! Prestige 5 Tauren Death Knight
(151246, 21, 6, 6, ''), -- Realm First! Prestige 6 Tauren Death Knight
(151247, 21, 6, 6, ''), -- Realm First! Prestige 7 Tauren Death Knight
(151248, 21, 6, 6, ''), -- Realm First! Prestige 8 Tauren Death Knight
(151249, 21, 6, 6, ''), -- Realm First! Prestige 9 Tauren Death Knight
(151250, 21, 6, 6, ''), -- Realm First! Prestige 10 Tauren Death Knight
(151251, 21, 6, 8, ''), -- Realm First! Prestige 1 Troll Death Knight
(151252, 21, 6, 8, ''), -- Realm First! Prestige 2 Troll Death Knight
(151253, 21, 6, 8, ''), -- Realm First! Prestige 3 Troll Death Knight
(151254, 21, 6, 8, ''), -- Realm First! Prestige 4 Troll Death Knight
(151255, 21, 6, 8, ''), -- Realm First! Prestige 5 Troll Death Knight
(151256, 21, 6, 8, ''), -- Realm First! Prestige 6 Troll Death Knight
(151257, 21, 6, 8, ''), -- Realm First! Prestige 7 Troll Death Knight
(151258, 21, 6, 8, ''), -- Realm First! Prestige 8 Troll Death Knight
(151259, 21, 6, 8, ''), -- Realm First! Prestige 9 Troll Death Knight
(151260, 21, 6, 8, ''), -- Realm First! Prestige 10 Troll Death Knight
(151261, 21, 6, 10, ''), -- Realm First! Prestige 1 Blood Elf Death Knight
(151262, 21, 6, 10, ''), -- Realm First! Prestige 2 Blood Elf Death Knight
(151263, 21, 6, 10, ''), -- Realm First! Prestige 3 Blood Elf Death Knight
(151264, 21, 6, 10, ''), -- Realm First! Prestige 4 Blood Elf Death Knight
(151265, 21, 6, 10, ''), -- Realm First! Prestige 5 Blood Elf Death Knight
(151266, 21, 6, 10, ''), -- Realm First! Prestige 6 Blood Elf Death Knight
(151267, 21, 6, 10, ''), -- Realm First! Prestige 7 Blood Elf Death Knight
(151268, 21, 6, 10, ''), -- Realm First! Prestige 8 Blood Elf Death Knight
(151269, 21, 6, 10, ''), -- Realm First! Prestige 9 Blood Elf Death Knight
(151270, 21, 6, 10, ''), -- Realm First! Prestige 10 Blood Elf Death Knight
(151371, 21, 7, 1, ''), -- Realm First! Prestige 1 Human Shaman
(151372, 21, 7, 1, ''), -- Realm First! Prestige 2 Human Shaman
(151373, 21, 7, 1, ''), -- Realm First! Prestige 3 Human Shaman
(151374, 21, 7, 1, ''), -- Realm First! Prestige 4 Human Shaman
(151375, 21, 7, 1, ''), -- Realm First! Prestige 5 Human Shaman
(151376, 21, 7, 1, ''), -- Realm First! Prestige 6 Human Shaman
(151377, 21, 7, 1, ''), -- Realm First! Prestige 7 Human Shaman
(151378, 21, 7, 1, ''), -- Realm First! Prestige 8 Human Shaman
(151379, 21, 7, 1, ''), -- Realm First! Prestige 9 Human Shaman
(151380, 21, 7, 1, ''), -- Realm First! Prestige 10 Human Shaman
(151381, 21, 7, 3, ''), -- Realm First! Prestige 1 Dwarf Shaman
(151382, 21, 7, 3, ''), -- Realm First! Prestige 2 Dwarf Shaman
(151383, 21, 7, 3, ''), -- Realm First! Prestige 3 Dwarf Shaman
(151384, 21, 7, 3, ''), -- Realm First! Prestige 4 Dwarf Shaman
(151385, 21, 7, 3, ''), -- Realm First! Prestige 5 Dwarf Shaman
(151386, 21, 7, 3, ''), -- Realm First! Prestige 6 Dwarf Shaman
(151387, 21, 7, 3, ''), -- Realm First! Prestige 7 Dwarf Shaman
(151388, 21, 7, 3, ''), -- Realm First! Prestige 8 Dwarf Shaman
(151389, 21, 7, 3, ''), -- Realm First! Prestige 9 Dwarf Shaman
(151390, 21, 7, 3, ''), -- Realm First! Prestige 10 Dwarf Shaman
(151391, 21, 7, 4, ''), -- Realm First! Prestige 1 Night Elf Shaman
(151392, 21, 7, 4, ''), -- Realm First! Prestige 2 Night Elf Shaman
(151393, 21, 7, 4, ''), -- Realm First! Prestige 3 Night Elf Shaman
(151394, 21, 7, 4, ''), -- Realm First! Prestige 4 Night Elf Shaman
(151395, 21, 7, 4, ''), -- Realm First! Prestige 5 Night Elf Shaman
(151396, 21, 7, 4, ''), -- Realm First! Prestige 6 Night Elf Shaman
(151397, 21, 7, 4, ''), -- Realm First! Prestige 7 Night Elf Shaman
(151398, 21, 7, 4, ''), -- Realm First! Prestige 8 Night Elf Shaman
(151399, 21, 7, 4, ''), -- Realm First! Prestige 9 Night Elf Shaman
(151400, 21, 7, 4, ''), -- Realm First! Prestige 10 Night Elf Shaman
(151401, 21, 7, 7, ''), -- Realm First! Prestige 1 Gnome Shaman
(151402, 21, 7, 7, ''), -- Realm First! Prestige 2 Gnome Shaman
(151403, 21, 7, 7, ''), -- Realm First! Prestige 3 Gnome Shaman
(151404, 21, 7, 7, ''), -- Realm First! Prestige 4 Gnome Shaman
(151405, 21, 7, 7, ''), -- Realm First! Prestige 5 Gnome Shaman
(151406, 21, 7, 7, ''), -- Realm First! Prestige 6 Gnome Shaman
(151407, 21, 7, 7, ''), -- Realm First! Prestige 7 Gnome Shaman
(151408, 21, 7, 7, ''), -- Realm First! Prestige 8 Gnome Shaman
(151409, 21, 7, 7, ''), -- Realm First! Prestige 9 Gnome Shaman
(151410, 21, 7, 7, ''), -- Realm First! Prestige 10 Gnome Shaman
(151411, 21, 7, 11, ''), -- Realm First! Prestige 1 Draenei Shaman
(151412, 21, 7, 11, ''), -- Realm First! Prestige 2 Draenei Shaman
(151413, 21, 7, 11, ''), -- Realm First! Prestige 3 Draenei Shaman
(151414, 21, 7, 11, ''), -- Realm First! Prestige 4 Draenei Shaman
(151415, 21, 7, 11, ''), -- Realm First! Prestige 5 Draenei Shaman
(151416, 21, 7, 11, ''), -- Realm First! Prestige 6 Draenei Shaman
(151417, 21, 7, 11, ''), -- Realm First! Prestige 7 Draenei Shaman
(151418, 21, 7, 11, ''), -- Realm First! Prestige 8 Draenei Shaman
(151419, 21, 7, 11, ''), -- Realm First! Prestige 9 Draenei Shaman
(151420, 21, 7, 11, ''), -- Realm First! Prestige 10 Draenei Shaman
(151421, 21, 7, 2, ''), -- Realm First! Prestige 1 Orc Shaman
(151422, 21, 7, 2, ''), -- Realm First! Prestige 2 Orc Shaman
(151423, 21, 7, 2, ''), -- Realm First! Prestige 3 Orc Shaman
(151424, 21, 7, 2, ''), -- Realm First! Prestige 4 Orc Shaman
(151425, 21, 7, 2, ''), -- Realm First! Prestige 5 Orc Shaman
(151426, 21, 7, 2, ''), -- Realm First! Prestige 6 Orc Shaman
(151427, 21, 7, 2, ''), -- Realm First! Prestige 7 Orc Shaman
(151428, 21, 7, 2, ''), -- Realm First! Prestige 8 Orc Shaman
(151429, 21, 7, 2, ''), -- Realm First! Prestige 9 Orc Shaman
(151430, 21, 7, 2, ''), -- Realm First! Prestige 10 Orc Shaman
(151431, 21, 7, 5, ''), -- Realm First! Prestige 1 Undead Shaman
(151432, 21, 7, 5, ''), -- Realm First! Prestige 2 Undead Shaman
(151433, 21, 7, 5, ''), -- Realm First! Prestige 3 Undead Shaman
(151434, 21, 7, 5, ''), -- Realm First! Prestige 4 Undead Shaman
(151435, 21, 7, 5, ''), -- Realm First! Prestige 5 Undead Shaman
(151436, 21, 7, 5, ''), -- Realm First! Prestige 6 Undead Shaman
(151437, 21, 7, 5, ''), -- Realm First! Prestige 7 Undead Shaman
(151438, 21, 7, 5, ''), -- Realm First! Prestige 8 Undead Shaman
(151439, 21, 7, 5, ''), -- Realm First! Prestige 9 Undead Shaman
(151440, 21, 7, 5, ''), -- Realm First! Prestige 10 Undead Shaman
(151441, 21, 7, 6, ''), -- Realm First! Prestige 1 Tauren Shaman
(151442, 21, 7, 6, ''), -- Realm First! Prestige 2 Tauren Shaman
(151443, 21, 7, 6, ''), -- Realm First! Prestige 3 Tauren Shaman
(151444, 21, 7, 6, ''), -- Realm First! Prestige 4 Tauren Shaman
(151445, 21, 7, 6, ''), -- Realm First! Prestige 5 Tauren Shaman
(151446, 21, 7, 6, ''), -- Realm First! Prestige 6 Tauren Shaman
(151447, 21, 7, 6, ''), -- Realm First! Prestige 7 Tauren Shaman
(151448, 21, 7, 6, ''), -- Realm First! Prestige 8 Tauren Shaman
(151449, 21, 7, 6, ''), -- Realm First! Prestige 9 Tauren Shaman
(151450, 21, 7, 6, ''), -- Realm First! Prestige 10 Tauren Shaman
(151451, 21, 7, 8, ''), -- Realm First! Prestige 1 Troll Shaman
(151452, 21, 7, 8, ''), -- Realm First! Prestige 2 Troll Shaman
(151453, 21, 7, 8, ''), -- Realm First! Prestige 3 Troll Shaman
(151454, 21, 7, 8, ''), -- Realm First! Prestige 4 Troll Shaman
(151455, 21, 7, 8, ''), -- Realm First! Prestige 5 Troll Shaman
(151456, 21, 7, 8, ''), -- Realm First! Prestige 6 Troll Shaman
(151457, 21, 7, 8, ''), -- Realm First! Prestige 7 Troll Shaman
(151458, 21, 7, 8, ''), -- Realm First! Prestige 8 Troll Shaman
(151459, 21, 7, 8, ''), -- Realm First! Prestige 9 Troll Shaman
(151460, 21, 7, 8, ''), -- Realm First! Prestige 10 Troll Shaman
(151461, 21, 7, 10, ''), -- Realm First! Prestige 1 Blood Elf Shaman
(151462, 21, 7, 10, ''), -- Realm First! Prestige 2 Blood Elf Shaman
(151463, 21, 7, 10, ''), -- Realm First! Prestige 3 Blood Elf Shaman
(151464, 21, 7, 10, ''), -- Realm First! Prestige 4 Blood Elf Shaman
(151465, 21, 7, 10, ''), -- Realm First! Prestige 5 Blood Elf Shaman
(151466, 21, 7, 10, ''), -- Realm First! Prestige 6 Blood Elf Shaman
(151467, 21, 7, 10, ''), -- Realm First! Prestige 7 Blood Elf Shaman
(151468, 21, 7, 10, ''), -- Realm First! Prestige 8 Blood Elf Shaman
(151469, 21, 7, 10, ''), -- Realm First! Prestige 9 Blood Elf Shaman
(151470, 21, 7, 10, ''), -- Realm First! Prestige 10 Blood Elf Shaman
(151571, 21, 8, 1, ''), -- Realm First! Prestige 1 Human Mage
(151572, 21, 8, 1, ''), -- Realm First! Prestige 2 Human Mage
(151573, 21, 8, 1, ''), -- Realm First! Prestige 3 Human Mage
(151574, 21, 8, 1, ''), -- Realm First! Prestige 4 Human Mage
(151575, 21, 8, 1, ''), -- Realm First! Prestige 5 Human Mage
(151576, 21, 8, 1, ''), -- Realm First! Prestige 6 Human Mage
(151577, 21, 8, 1, ''), -- Realm First! Prestige 7 Human Mage
(151578, 21, 8, 1, ''), -- Realm First! Prestige 8 Human Mage
(151579, 21, 8, 1, ''), -- Realm First! Prestige 9 Human Mage
(151580, 21, 8, 1, ''), -- Realm First! Prestige 10 Human Mage
(151581, 21, 8, 3, ''), -- Realm First! Prestige 1 Dwarf Mage
(151582, 21, 8, 3, ''), -- Realm First! Prestige 2 Dwarf Mage
(151583, 21, 8, 3, ''), -- Realm First! Prestige 3 Dwarf Mage
(151584, 21, 8, 3, ''), -- Realm First! Prestige 4 Dwarf Mage
(151585, 21, 8, 3, ''), -- Realm First! Prestige 5 Dwarf Mage
(151586, 21, 8, 3, ''), -- Realm First! Prestige 6 Dwarf Mage
(151587, 21, 8, 3, ''), -- Realm First! Prestige 7 Dwarf Mage
(151588, 21, 8, 3, ''), -- Realm First! Prestige 8 Dwarf Mage
(151589, 21, 8, 3, ''), -- Realm First! Prestige 9 Dwarf Mage
(151590, 21, 8, 3, ''), -- Realm First! Prestige 10 Dwarf Mage
(151591, 21, 8, 4, ''), -- Realm First! Prestige 1 Night Elf Mage
(151592, 21, 8, 4, ''), -- Realm First! Prestige 2 Night Elf Mage
(151593, 21, 8, 4, ''), -- Realm First! Prestige 3 Night Elf Mage
(151594, 21, 8, 4, ''), -- Realm First! Prestige 4 Night Elf Mage
(151595, 21, 8, 4, ''), -- Realm First! Prestige 5 Night Elf Mage
(151596, 21, 8, 4, ''), -- Realm First! Prestige 6 Night Elf Mage
(151597, 21, 8, 4, ''), -- Realm First! Prestige 7 Night Elf Mage
(151598, 21, 8, 4, ''), -- Realm First! Prestige 8 Night Elf Mage
(151599, 21, 8, 4, ''), -- Realm First! Prestige 9 Night Elf Mage
(151600, 21, 8, 4, ''), -- Realm First! Prestige 10 Night Elf Mage
(151601, 21, 8, 7, ''), -- Realm First! Prestige 1 Gnome Mage
(151602, 21, 8, 7, ''), -- Realm First! Prestige 2 Gnome Mage
(151603, 21, 8, 7, ''), -- Realm First! Prestige 3 Gnome Mage
(151604, 21, 8, 7, ''), -- Realm First! Prestige 4 Gnome Mage
(151605, 21, 8, 7, ''), -- Realm First! Prestige 5 Gnome Mage
(151606, 21, 8, 7, ''), -- Realm First! Prestige 6 Gnome Mage
(151607, 21, 8, 7, ''), -- Realm First! Prestige 7 Gnome Mage
(151608, 21, 8, 7, ''), -- Realm First! Prestige 8 Gnome Mage
(151609, 21, 8, 7, ''), -- Realm First! Prestige 9 Gnome Mage
(151610, 21, 8, 7, ''), -- Realm First! Prestige 10 Gnome Mage
(151611, 21, 8, 11, ''), -- Realm First! Prestige 1 Draenei Mage
(151612, 21, 8, 11, ''), -- Realm First! Prestige 2 Draenei Mage
(151613, 21, 8, 11, ''), -- Realm First! Prestige 3 Draenei Mage
(151614, 21, 8, 11, ''), -- Realm First! Prestige 4 Draenei Mage
(151615, 21, 8, 11, ''), -- Realm First! Prestige 5 Draenei Mage
(151616, 21, 8, 11, ''), -- Realm First! Prestige 6 Draenei Mage
(151617, 21, 8, 11, ''), -- Realm First! Prestige 7 Draenei Mage
(151618, 21, 8, 11, ''), -- Realm First! Prestige 8 Draenei Mage
(151619, 21, 8, 11, ''), -- Realm First! Prestige 9 Draenei Mage
(151620, 21, 8, 11, ''), -- Realm First! Prestige 10 Draenei Mage
(151621, 21, 8, 2, ''), -- Realm First! Prestige 1 Orc Mage
(151622, 21, 8, 2, ''), -- Realm First! Prestige 2 Orc Mage
(151623, 21, 8, 2, ''), -- Realm First! Prestige 3 Orc Mage
(151624, 21, 8, 2, ''), -- Realm First! Prestige 4 Orc Mage
(151625, 21, 8, 2, ''), -- Realm First! Prestige 5 Orc Mage
(151626, 21, 8, 2, ''), -- Realm First! Prestige 6 Orc Mage
(151627, 21, 8, 2, ''), -- Realm First! Prestige 7 Orc Mage
(151628, 21, 8, 2, ''), -- Realm First! Prestige 8 Orc Mage
(151629, 21, 8, 2, ''), -- Realm First! Prestige 9 Orc Mage
(151630, 21, 8, 2, ''), -- Realm First! Prestige 10 Orc Mage
(151631, 21, 8, 5, ''), -- Realm First! Prestige 1 Undead Mage
(151632, 21, 8, 5, ''), -- Realm First! Prestige 2 Undead Mage
(151633, 21, 8, 5, ''), -- Realm First! Prestige 3 Undead Mage
(151634, 21, 8, 5, ''), -- Realm First! Prestige 4 Undead Mage
(151635, 21, 8, 5, ''), -- Realm First! Prestige 5 Undead Mage
(151636, 21, 8, 5, ''), -- Realm First! Prestige 6 Undead Mage
(151637, 21, 8, 5, ''), -- Realm First! Prestige 7 Undead Mage
(151638, 21, 8, 5, ''), -- Realm First! Prestige 8 Undead Mage
(151639, 21, 8, 5, ''), -- Realm First! Prestige 9 Undead Mage
(151640, 21, 8, 5, ''), -- Realm First! Prestige 10 Undead Mage
(151641, 21, 8, 6, ''), -- Realm First! Prestige 1 Tauren Mage
(151642, 21, 8, 6, ''), -- Realm First! Prestige 2 Tauren Mage
(151643, 21, 8, 6, ''), -- Realm First! Prestige 3 Tauren Mage
(151644, 21, 8, 6, ''), -- Realm First! Prestige 4 Tauren Mage
(151645, 21, 8, 6, ''), -- Realm First! Prestige 5 Tauren Mage
(151646, 21, 8, 6, ''), -- Realm First! Prestige 6 Tauren Mage
(151647, 21, 8, 6, ''), -- Realm First! Prestige 7 Tauren Mage
(151648, 21, 8, 6, ''), -- Realm First! Prestige 8 Tauren Mage
(151649, 21, 8, 6, ''), -- Realm First! Prestige 9 Tauren Mage
(151650, 21, 8, 6, ''), -- Realm First! Prestige 10 Tauren Mage
(151651, 21, 8, 8, ''), -- Realm First! Prestige 1 Troll Mage
(151652, 21, 8, 8, ''), -- Realm First! Prestige 2 Troll Mage
(151653, 21, 8, 8, ''), -- Realm First! Prestige 3 Troll Mage
(151654, 21, 8, 8, ''), -- Realm First! Prestige 4 Troll Mage
(151655, 21, 8, 8, ''), -- Realm First! Prestige 5 Troll Mage
(151656, 21, 8, 8, ''), -- Realm First! Prestige 6 Troll Mage
(151657, 21, 8, 8, ''), -- Realm First! Prestige 7 Troll Mage
(151658, 21, 8, 8, ''), -- Realm First! Prestige 8 Troll Mage
(151659, 21, 8, 8, ''), -- Realm First! Prestige 9 Troll Mage
(151660, 21, 8, 8, ''), -- Realm First! Prestige 10 Troll Mage
(151661, 21, 8, 10, ''), -- Realm First! Prestige 1 Blood Elf Mage
(151662, 21, 8, 10, ''), -- Realm First! Prestige 2 Blood Elf Mage
(151663, 21, 8, 10, ''), -- Realm First! Prestige 3 Blood Elf Mage
(151664, 21, 8, 10, ''), -- Realm First! Prestige 4 Blood Elf Mage
(151665, 21, 8, 10, ''), -- Realm First! Prestige 5 Blood Elf Mage
(151666, 21, 8, 10, ''), -- Realm First! Prestige 6 Blood Elf Mage
(151667, 21, 8, 10, ''), -- Realm First! Prestige 7 Blood Elf Mage
(151668, 21, 8, 10, ''), -- Realm First! Prestige 8 Blood Elf Mage
(151669, 21, 8, 10, ''), -- Realm First! Prestige 9 Blood Elf Mage
(151670, 21, 8, 10, ''), -- Realm First! Prestige 10 Blood Elf Mage
(151771, 21, 9, 1, ''), -- Realm First! Prestige 1 Human Warlock
(151772, 21, 9, 1, ''), -- Realm First! Prestige 2 Human Warlock
(151773, 21, 9, 1, ''), -- Realm First! Prestige 3 Human Warlock
(151774, 21, 9, 1, ''), -- Realm First! Prestige 4 Human Warlock
(151775, 21, 9, 1, ''), -- Realm First! Prestige 5 Human Warlock
(151776, 21, 9, 1, ''), -- Realm First! Prestige 6 Human Warlock
(151777, 21, 9, 1, ''), -- Realm First! Prestige 7 Human Warlock
(151778, 21, 9, 1, ''), -- Realm First! Prestige 8 Human Warlock
(151779, 21, 9, 1, ''), -- Realm First! Prestige 9 Human Warlock
(151780, 21, 9, 1, ''), -- Realm First! Prestige 10 Human Warlock
(151781, 21, 9, 3, ''), -- Realm First! Prestige 1 Dwarf Warlock
(151782, 21, 9, 3, ''), -- Realm First! Prestige 2 Dwarf Warlock
(151783, 21, 9, 3, ''), -- Realm First! Prestige 3 Dwarf Warlock
(151784, 21, 9, 3, ''), -- Realm First! Prestige 4 Dwarf Warlock
(151785, 21, 9, 3, ''), -- Realm First! Prestige 5 Dwarf Warlock
(151786, 21, 9, 3, ''), -- Realm First! Prestige 6 Dwarf Warlock
(151787, 21, 9, 3, ''), -- Realm First! Prestige 7 Dwarf Warlock
(151788, 21, 9, 3, ''), -- Realm First! Prestige 8 Dwarf Warlock
(151789, 21, 9, 3, ''), -- Realm First! Prestige 9 Dwarf Warlock
(151790, 21, 9, 3, ''), -- Realm First! Prestige 10 Dwarf Warlock
(151791, 21, 9, 4, ''), -- Realm First! Prestige 1 Night Elf Warlock
(151792, 21, 9, 4, ''), -- Realm First! Prestige 2 Night Elf Warlock
(151793, 21, 9, 4, ''), -- Realm First! Prestige 3 Night Elf Warlock
(151794, 21, 9, 4, ''), -- Realm First! Prestige 4 Night Elf Warlock
(151795, 21, 9, 4, ''), -- Realm First! Prestige 5 Night Elf Warlock
(151796, 21, 9, 4, ''), -- Realm First! Prestige 6 Night Elf Warlock
(151797, 21, 9, 4, ''), -- Realm First! Prestige 7 Night Elf Warlock
(151798, 21, 9, 4, ''), -- Realm First! Prestige 8 Night Elf Warlock
(151799, 21, 9, 4, ''), -- Realm First! Prestige 9 Night Elf Warlock
(151800, 21, 9, 4, ''), -- Realm First! Prestige 10 Night Elf Warlock
(151801, 21, 9, 7, ''), -- Realm First! Prestige 1 Gnome Warlock
(151802, 21, 9, 7, ''), -- Realm First! Prestige 2 Gnome Warlock
(151803, 21, 9, 7, ''), -- Realm First! Prestige 3 Gnome Warlock
(151804, 21, 9, 7, ''), -- Realm First! Prestige 4 Gnome Warlock
(151805, 21, 9, 7, ''), -- Realm First! Prestige 5 Gnome Warlock
(151806, 21, 9, 7, ''), -- Realm First! Prestige 6 Gnome Warlock
(151807, 21, 9, 7, ''), -- Realm First! Prestige 7 Gnome Warlock
(151808, 21, 9, 7, ''), -- Realm First! Prestige 8 Gnome Warlock
(151809, 21, 9, 7, ''), -- Realm First! Prestige 9 Gnome Warlock
(151810, 21, 9, 7, ''), -- Realm First! Prestige 10 Gnome Warlock
(151811, 21, 9, 11, ''), -- Realm First! Prestige 1 Draenei Warlock
(151812, 21, 9, 11, ''), -- Realm First! Prestige 2 Draenei Warlock
(151813, 21, 9, 11, ''), -- Realm First! Prestige 3 Draenei Warlock
(151814, 21, 9, 11, ''), -- Realm First! Prestige 4 Draenei Warlock
(151815, 21, 9, 11, ''), -- Realm First! Prestige 5 Draenei Warlock
(151816, 21, 9, 11, ''), -- Realm First! Prestige 6 Draenei Warlock
(151817, 21, 9, 11, ''), -- Realm First! Prestige 7 Draenei Warlock
(151818, 21, 9, 11, ''), -- Realm First! Prestige 8 Draenei Warlock
(151819, 21, 9, 11, ''), -- Realm First! Prestige 9 Draenei Warlock
(151820, 21, 9, 11, ''), -- Realm First! Prestige 10 Draenei Warlock
(151821, 21, 9, 2, ''), -- Realm First! Prestige 1 Orc Warlock
(151822, 21, 9, 2, ''), -- Realm First! Prestige 2 Orc Warlock
(151823, 21, 9, 2, ''), -- Realm First! Prestige 3 Orc Warlock
(151824, 21, 9, 2, ''), -- Realm First! Prestige 4 Orc Warlock
(151825, 21, 9, 2, ''), -- Realm First! Prestige 5 Orc Warlock
(151826, 21, 9, 2, ''), -- Realm First! Prestige 6 Orc Warlock
(151827, 21, 9, 2, ''), -- Realm First! Prestige 7 Orc Warlock
(151828, 21, 9, 2, ''), -- Realm First! Prestige 8 Orc Warlock
(151829, 21, 9, 2, ''), -- Realm First! Prestige 9 Orc Warlock
(151830, 21, 9, 2, ''), -- Realm First! Prestige 10 Orc Warlock
(151831, 21, 9, 5, ''), -- Realm First! Prestige 1 Undead Warlock
(151832, 21, 9, 5, ''), -- Realm First! Prestige 2 Undead Warlock
(151833, 21, 9, 5, ''), -- Realm First! Prestige 3 Undead Warlock
(151834, 21, 9, 5, ''), -- Realm First! Prestige 4 Undead Warlock
(151835, 21, 9, 5, ''), -- Realm First! Prestige 5 Undead Warlock
(151836, 21, 9, 5, ''), -- Realm First! Prestige 6 Undead Warlock
(151837, 21, 9, 5, ''), -- Realm First! Prestige 7 Undead Warlock
(151838, 21, 9, 5, ''), -- Realm First! Prestige 8 Undead Warlock
(151839, 21, 9, 5, ''), -- Realm First! Prestige 9 Undead Warlock
(151840, 21, 9, 5, ''), -- Realm First! Prestige 10 Undead Warlock
(151841, 21, 9, 6, ''), -- Realm First! Prestige 1 Tauren Warlock
(151842, 21, 9, 6, ''), -- Realm First! Prestige 2 Tauren Warlock
(151843, 21, 9, 6, ''), -- Realm First! Prestige 3 Tauren Warlock
(151844, 21, 9, 6, ''), -- Realm First! Prestige 4 Tauren Warlock
(151845, 21, 9, 6, ''), -- Realm First! Prestige 5 Tauren Warlock
(151846, 21, 9, 6, ''), -- Realm First! Prestige 6 Tauren Warlock
(151847, 21, 9, 6, ''), -- Realm First! Prestige 7 Tauren Warlock
(151848, 21, 9, 6, ''), -- Realm First! Prestige 8 Tauren Warlock
(151849, 21, 9, 6, ''), -- Realm First! Prestige 9 Tauren Warlock
(151850, 21, 9, 6, ''), -- Realm First! Prestige 10 Tauren Warlock
(151851, 21, 9, 8, ''), -- Realm First! Prestige 1 Troll Warlock
(151852, 21, 9, 8, ''), -- Realm First! Prestige 2 Troll Warlock
(151853, 21, 9, 8, ''), -- Realm First! Prestige 3 Troll Warlock
(151854, 21, 9, 8, ''), -- Realm First! Prestige 4 Troll Warlock
(151855, 21, 9, 8, ''), -- Realm First! Prestige 5 Troll Warlock
(151856, 21, 9, 8, ''), -- Realm First! Prestige 6 Troll Warlock
(151857, 21, 9, 8, ''), -- Realm First! Prestige 7 Troll Warlock
(151858, 21, 9, 8, ''), -- Realm First! Prestige 8 Troll Warlock
(151859, 21, 9, 8, ''), -- Realm First! Prestige 9 Troll Warlock
(151860, 21, 9, 8, ''), -- Realm First! Prestige 10 Troll Warlock
(151861, 21, 9, 10, ''), -- Realm First! Prestige 1 Blood Elf Warlock
(151862, 21, 9, 10, ''), -- Realm First! Prestige 2 Blood Elf Warlock
(151863, 21, 9, 10, ''), -- Realm First! Prestige 3 Blood Elf Warlock
(151864, 21, 9, 10, ''), -- Realm First! Prestige 4 Blood Elf Warlock
(151865, 21, 9, 10, ''), -- Realm First! Prestige 5 Blood Elf Warlock
(151866, 21, 9, 10, ''), -- Realm First! Prestige 6 Blood Elf Warlock
(151867, 21, 9, 10, ''), -- Realm First! Prestige 7 Blood Elf Warlock
(151868, 21, 9, 10, ''), -- Realm First! Prestige 8 Blood Elf Warlock
(151869, 21, 9, 10, ''), -- Realm First! Prestige 9 Blood Elf Warlock
(151870, 21, 9, 10, ''), -- Realm First! Prestige 10 Blood Elf Warlock
(151971, 21, 11, 1, ''), -- Realm First! Prestige 1 Human Druid
(151972, 21, 11, 1, ''), -- Realm First! Prestige 2 Human Druid
(151973, 21, 11, 1, ''), -- Realm First! Prestige 3 Human Druid
(151974, 21, 11, 1, ''), -- Realm First! Prestige 4 Human Druid
(151975, 21, 11, 1, ''), -- Realm First! Prestige 5 Human Druid
(151976, 21, 11, 1, ''), -- Realm First! Prestige 6 Human Druid
(151977, 21, 11, 1, ''), -- Realm First! Prestige 7 Human Druid
(151978, 21, 11, 1, ''), -- Realm First! Prestige 8 Human Druid
(151979, 21, 11, 1, ''), -- Realm First! Prestige 9 Human Druid
(151980, 21, 11, 1, ''), -- Realm First! Prestige 10 Human Druid
(151981, 21, 11, 3, ''), -- Realm First! Prestige 1 Dwarf Druid
(151982, 21, 11, 3, ''), -- Realm First! Prestige 2 Dwarf Druid
(151983, 21, 11, 3, ''), -- Realm First! Prestige 3 Dwarf Druid
(151984, 21, 11, 3, ''), -- Realm First! Prestige 4 Dwarf Druid
(151985, 21, 11, 3, ''), -- Realm First! Prestige 5 Dwarf Druid
(151986, 21, 11, 3, ''), -- Realm First! Prestige 6 Dwarf Druid
(151987, 21, 11, 3, ''), -- Realm First! Prestige 7 Dwarf Druid
(151988, 21, 11, 3, ''), -- Realm First! Prestige 8 Dwarf Druid
(151989, 21, 11, 3, ''), -- Realm First! Prestige 9 Dwarf Druid
(151990, 21, 11, 3, ''), -- Realm First! Prestige 10 Dwarf Druid
(151991, 21, 11, 4, ''), -- Realm First! Prestige 1 Night Elf Druid
(151992, 21, 11, 4, ''), -- Realm First! Prestige 2 Night Elf Druid
(151993, 21, 11, 4, ''), -- Realm First! Prestige 3 Night Elf Druid
(151994, 21, 11, 4, ''), -- Realm First! Prestige 4 Night Elf Druid
(151995, 21, 11, 4, ''), -- Realm First! Prestige 5 Night Elf Druid
(151996, 21, 11, 4, ''), -- Realm First! Prestige 6 Night Elf Druid
(151997, 21, 11, 4, ''), -- Realm First! Prestige 7 Night Elf Druid
(151998, 21, 11, 4, ''), -- Realm First! Prestige 8 Night Elf Druid
(151999, 21, 11, 4, ''), -- Realm First! Prestige 9 Night Elf Druid
(152000, 21, 11, 4, ''), -- Realm First! Prestige 10 Night Elf Druid
(152001, 21, 11, 7, ''), -- Realm First! Prestige 1 Gnome Druid
(152002, 21, 11, 7, ''), -- Realm First! Prestige 2 Gnome Druid
(152003, 21, 11, 7, ''), -- Realm First! Prestige 3 Gnome Druid
(152004, 21, 11, 7, ''), -- Realm First! Prestige 4 Gnome Druid
(152005, 21, 11, 7, ''), -- Realm First! Prestige 5 Gnome Druid
(152006, 21, 11, 7, ''), -- Realm First! Prestige 6 Gnome Druid
(152007, 21, 11, 7, ''), -- Realm First! Prestige 7 Gnome Druid
(152008, 21, 11, 7, ''), -- Realm First! Prestige 8 Gnome Druid
(152009, 21, 11, 7, ''), -- Realm First! Prestige 9 Gnome Druid
(152010, 21, 11, 7, ''), -- Realm First! Prestige 10 Gnome Druid
(152011, 21, 11, 11, ''), -- Realm First! Prestige 1 Draenei Druid
(152012, 21, 11, 11, ''), -- Realm First! Prestige 2 Draenei Druid
(152013, 21, 11, 11, ''), -- Realm First! Prestige 3 Draenei Druid
(152014, 21, 11, 11, ''), -- Realm First! Prestige 4 Draenei Druid
(152015, 21, 11, 11, ''), -- Realm First! Prestige 5 Draenei Druid
(152016, 21, 11, 11, ''), -- Realm First! Prestige 6 Draenei Druid
(152017, 21, 11, 11, ''), -- Realm First! Prestige 7 Draenei Druid
(152018, 21, 11, 11, ''), -- Realm First! Prestige 8 Draenei Druid
(152019, 21, 11, 11, ''), -- Realm First! Prestige 9 Draenei Druid
(152020, 21, 11, 11, ''), -- Realm First! Prestige 10 Draenei Druid
(152021, 21, 11, 2, ''), -- Realm First! Prestige 1 Orc Druid
(152022, 21, 11, 2, ''), -- Realm First! Prestige 2 Orc Druid
(152023, 21, 11, 2, ''), -- Realm First! Prestige 3 Orc Druid
(152024, 21, 11, 2, ''), -- Realm First! Prestige 4 Orc Druid
(152025, 21, 11, 2, ''), -- Realm First! Prestige 5 Orc Druid
(152026, 21, 11, 2, ''), -- Realm First! Prestige 6 Orc Druid
(152027, 21, 11, 2, ''), -- Realm First! Prestige 7 Orc Druid
(152028, 21, 11, 2, ''), -- Realm First! Prestige 8 Orc Druid
(152029, 21, 11, 2, ''), -- Realm First! Prestige 9 Orc Druid
(152030, 21, 11, 2, ''), -- Realm First! Prestige 10 Orc Druid
(152031, 21, 11, 5, ''), -- Realm First! Prestige 1 Undead Druid
(152032, 21, 11, 5, ''), -- Realm First! Prestige 2 Undead Druid
(152033, 21, 11, 5, ''), -- Realm First! Prestige 3 Undead Druid
(152034, 21, 11, 5, ''), -- Realm First! Prestige 4 Undead Druid
(152035, 21, 11, 5, ''), -- Realm First! Prestige 5 Undead Druid
(152036, 21, 11, 5, ''), -- Realm First! Prestige 6 Undead Druid
(152037, 21, 11, 5, ''), -- Realm First! Prestige 7 Undead Druid
(152038, 21, 11, 5, ''), -- Realm First! Prestige 8 Undead Druid
(152039, 21, 11, 5, ''), -- Realm First! Prestige 9 Undead Druid
(152040, 21, 11, 5, ''), -- Realm First! Prestige 10 Undead Druid
(152041, 21, 11, 6, ''), -- Realm First! Prestige 1 Tauren Druid
(152042, 21, 11, 6, ''), -- Realm First! Prestige 2 Tauren Druid
(152043, 21, 11, 6, ''), -- Realm First! Prestige 3 Tauren Druid
(152044, 21, 11, 6, ''), -- Realm First! Prestige 4 Tauren Druid
(152045, 21, 11, 6, ''), -- Realm First! Prestige 5 Tauren Druid
(152046, 21, 11, 6, ''), -- Realm First! Prestige 6 Tauren Druid
(152047, 21, 11, 6, ''), -- Realm First! Prestige 7 Tauren Druid
(152048, 21, 11, 6, ''), -- Realm First! Prestige 8 Tauren Druid
(152049, 21, 11, 6, ''), -- Realm First! Prestige 9 Tauren Druid
(152050, 21, 11, 6, ''), -- Realm First! Prestige 10 Tauren Druid
(152051, 21, 11, 8, ''), -- Realm First! Prestige 1 Troll Druid
(152052, 21, 11, 8, ''), -- Realm First! Prestige 2 Troll Druid
(152053, 21, 11, 8, ''), -- Realm First! Prestige 3 Troll Druid
(152054, 21, 11, 8, ''), -- Realm First! Prestige 4 Troll Druid
(152055, 21, 11, 8, ''), -- Realm First! Prestige 5 Troll Druid
(152056, 21, 11, 8, ''), -- Realm First! Prestige 6 Troll Druid
(152057, 21, 11, 8, ''), -- Realm First! Prestige 7 Troll Druid
(152058, 21, 11, 8, ''), -- Realm First! Prestige 8 Troll Druid
(152059, 21, 11, 8, ''), -- Realm First! Prestige 9 Troll Druid
(152060, 21, 11, 8, ''), -- Realm First! Prestige 10 Troll Druid
(152061, 21, 11, 10, ''), -- Realm First! Prestige 1 Blood Elf Druid
(152062, 21, 11, 10, ''), -- Realm First! Prestige 2 Blood Elf Druid
(152063, 21, 11, 10, ''), -- Realm First! Prestige 3 Blood Elf Druid
(152064, 21, 11, 10, ''), -- Realm First! Prestige 4 Blood Elf Druid
(152065, 21, 11, 10, ''), -- Realm First! Prestige 5 Blood Elf Druid
(152066, 21, 11, 10, ''), -- Realm First! Prestige 6 Blood Elf Druid
(152067, 21, 11, 10, ''), -- Realm First! Prestige 7 Blood Elf Druid
(152068, 21, 11, 10, ''), -- Realm First! Prestige 8 Blood Elf Druid
(152069, 21, 11, 10, ''), -- Realm First! Prestige 9 Blood Elf Druid
(152070, 21, 11, 10, ''); -- Realm First! Prestige 10 Blood Elf Druid

-- Each Prestige level earns its title: Prestige 1-9 (13100-13108) award CharTitles 200-208 ("%s I" to
-- "%s IX") and Prestige 10 (13109) awards 209 ("The Prestigious %s").
DELETE FROM `achievement_reward` WHERE `ID` BETWEEN 13100 AND 13109;
INSERT INTO `achievement_reward` (`ID`, `TitleA`, `TitleH`, `ItemID`, `Sender`, `Subject`, `Body`,
    `MailTemplateID`) VALUES
(13100, 200, 200, 0, 0, NULL, NULL, 0),
(13101, 201, 201, 0, 0, NULL, NULL, 0),
(13102, 202, 202, 0, 0, NULL, NULL, 0),
(13103, 203, 203, 0, 0, NULL, NULL, 0),
(13104, 204, 204, 0, 0, NULL, NULL, 0),
(13105, 205, 205, 0, 0, NULL, NULL, 0),
(13106, 206, 206, 0, 0, NULL, NULL, 0),
(13107, 207, 207, 0, 0, NULL, NULL, 0),
(13108, 208, 208, 0, 0, NULL, NULL, 0),
(13109, 209, 209, 0, 0, NULL, NULL, 0);
