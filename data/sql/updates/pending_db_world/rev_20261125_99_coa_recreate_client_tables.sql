-- Recreate and repopulate the five coa_client_* tables dropped by
-- zzzz_rev_20261118_20_coa_drop_baked_client_tables.sql (PR #12775) and read again since PR #13604.
-- Statements are taken verbatim in filename order from the 36 earlier pending_db_world migrations
-- (with rev_20261031_00_skinpeeler_full_parity.sql's five consecutive super_track INSERTs folded
-- into one multi-row INSERT and `ID` backtick-quoted for SQL codestyle compliance).

-- Source: rev_1791558178309625533.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 89485;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(89485, 59);

-- Source: rev_20261005_30_coa_mulgore_hyena_spirit_super_track.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` = 8705;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(8705, 1, -3619.49, -959.45, 205.057, 5.5, 0, 0);

-- Source: rev_20261006_40_coa_guardian_formations_keep_main_bar.sql
CREATE TABLE IF NOT EXISTS `coa_client_shapeshift_form` (
  `ID` INT UNSIGNED NOT NULL,
  `BonusActionBar` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` IN (35, 36, 37);
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(35, 0),
(36, 0),
(37, 0);

-- Source: rev_20261008_60_coa_teldrassil_termites_super_track.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` = 8786;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(8786, 1, 9794.24, 996.63, 1243.08, 4.0, 0, 0);

-- Source: rev_20261011_92_coa_quest_2745_tyrion_super_track.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` = 164;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(164, 0, -8330, 279.5, 156.833, 5.5, 0, 0);

-- Source: rev_20261014_03_coa_xaitoth_coven_position.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` = 3456;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(3456, 1, -94.136, -4290.211, 61.294, 5.5, 0, 0);

-- Source: rev_20261014_95_coa_quest_6444_old_history_book.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` = 607;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(607, 0, -8279.309, 226.965, 155.447, 5.5, 0, 0);

-- Source: rev_20261015_02_quest_1195_sacred_flame_moonwell_marker.sql
DELETE FROM `coa_client_super_track` WHERE `ID` = 4599;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(4599, 1, 1870.43, -1771.57, 61.328, 5.5, 0, 0);

-- Source: rev_20261015_06_runemaster_runeshroud_action_bar.sql
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` = 30;
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(30, 0);

-- Source: rev_20261016_03_pyromancer_fired_up_tab_and_tooltip.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 90281;
INSERT INTO `coa_client_skill_line_ability` (`ID`,`SkillLine`) VALUES
(90281,85);

-- Source: rev_20261017_04_elude_stealth_action_bar.sql
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` = 30;
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(30, 1);

-- Source: rev_20261018_71_coa_poisoning_the_world_super_track.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 21083 AND 21090;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21083, 1, 10458.2, 807.65, 1346.75, 5.5, 0, 0),
(21084, 1, 10434.3, 795.62, 1322.7, 5.5, 0, 0),
(21085, 1, 10386.7, 811.88, 1317.53, 5.5, 0, 0),
(21086, 1, 10405.4, 717.75, 1321.65, 5.5, 0, 0),
(21087, 1, -619.9, -4313.76, 40.291, 5.5, 0, 0),
(21088, 1, -633.42, -4287.44, 39.825, 5.5, 0, 0),
(21089, 1, -641.03, -4229.15, 38.135, 5.5, 0, 0),
(21090, 1, -558.66, -4195.2, 46.396, 5.5, 0, 0);

-- Source: rev_20261018_80_return_to_jahan_super_track.sql
DELETE FROM `coa_client_super_track` WHERE `ID` = 1751;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(1751, 1, -363.5, -2576.2, 96.01, 5.5, 0, 0);

-- Source: rev_20261020_18_coa_half_detailed_report_supertrack.sql
DELETE FROM `coa_client_super_track` WHERE `ID` = 21335;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21335, 0, -10679.3, 957.9, 38.47, 5.5, 0, 0);

-- Source: rev_20261020_83_coa_primal_weapons_skill_line.sql
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 1323;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(1323, 110);

-- Source: rev_20261020_92_coa_quest_6465_extravagant_order_super_track.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` = 21098;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21098, 0, -9494.13, 83.9096, 56.6586, 5.5, 0, 0);

-- Source: rev_20261023_51_goblin_salvage_project_markers.sql
CREATE TABLE IF NOT EXISTS `coa_client_super_track` (
  `ID` INT UNSIGNED NOT NULL,
  `MapID` INT UNSIGNED NOT NULL DEFAULT 0,
  `PositionX` FLOAT NOT NULL DEFAULT 0,
  `PositionY` FLOAT NOT NULL DEFAULT 0,
  `PositionZ` FLOAT NOT NULL DEFAULT 0,
  `Radius` FLOAT NOT NULL DEFAULT 0,
  `NextID` INT UNSIGNED NOT NULL DEFAULT 0,
  `Flags` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 20900 AND 20911;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(20900, 0, -11307.4, -191.2, 75.35, 5.5, 0, 0),
(20901, 0, -12341.85, 165.85, 3.12, 5.5, 0, 0),
(20902, 0, -11985.0, -536.0, 12.06, 5.5, 0, 0),
(20903, 0, -12023.4, -601.3, 14.5, 5.5, 0, 0),
(20904, 0, -11491.9, 393.7, 62.37, 5.5, 0, 0),
(20905, 0, -12121.8, -559.5, 13.43, 5.5, 0, 0),
(20906, 0, -12137.4, -588.1, 14.01, 5.5, 0, 0),
(20907, 0, -12096.5, -700.8, 15.68, 5.5, 0, 0),
(20908, 0, -12014.1, -742.0, 15.64, 5.5, 0, 0),
(20909, 0, -12132.7, -638.5, 13.6, 5.5, 0, 0),
(20910, 0, -12110.3, -629.76, 15.61, 5.5, 0, 0),
(20911, 0, -12079.1, -733.46, 14.28, 5.5, 0, 0);

-- Source: rev_20261027_62_coa_xoroth_annihilation_skill_line.sql
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 777;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(777, 64);

-- Source: rev_20261028_04_coa_demonhood_skull_super_track.sql
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 18632 AND 18637;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(18632, 1, -594, -4135, 46.26, 5.5, 0, 0),
(18633, 1, -596, -4145, 47.26, 5.5, 0, 0),
(18634, 1, -584.87, -4125.95, 43.85, 5.5, 0, 0),
(18635, 1, 10362, 749.5, 1321.84, 5.5, 0, 0),
(18636, 1, 10371, 737, 1323.46, 5.5, 0, 0),
(18637, 1, 10345.4, 757.2, 1326.45, 5.5, 0, 0);

-- Source: rev_20261028_103_deciphering_the_code_thargas_super_track.sql
DELETE FROM `coa_client_super_track` WHERE `ID` IN (21552, 21553);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21552, 0, -6443.07, -319.93, 576.763, 0, 0, 0),
(21553, 0, -6443.07, -319.93, 576.763, 0, 0, 0);

-- Source: rev_20261028_10_coa_guardian_formation_action_bars.sql
CREATE TABLE IF NOT EXISTS `coa_client_shapeshift_form` (
  `ID` INT UNSIGNED NOT NULL,
  `BonusActionBar` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` IN (35, 36, 37);
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(35, 2),
(36, 3),
(37, 1);

-- Source: rev_20261028_17_apex_poi_track.sql
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 9930001 AND 9930032;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(9930001, 1, 2267.21, -6787.11, 125.24, 25, 0, 0),
(9930002, 1, 2310.67, -6875.93, 121.74, 25, 0, 0),
(9930003, 1, 2353.55, -6880.87, 121.21, 25, 0, 0),
-- Hinterlands, the Stormfang patrol.
(9930011, 0, 138.558, -4523.49, 126.401, 25, 0, 0),
(9930012, 0, 201.369, -4492.76, 119.737, 25, 0, 0),
(9930013, 0, 156.261, -4482.47, 125.652, 25, 0, 0),
(9930014, 0, 194.693, -4465.27, 110.869, 25, 0, 0),
-- Feralas, the Vaelthara patrol.
(9930021, 1, -3887.07, 1958.59, 75.3706, 25, 0, 0),
(9930022, 1, -3815.15, 2018.34, 69.0198, 25, 0, 0),
(9930023, 1, -3836.58, 1913.61, 81.4929, 25, 0, 0),
(9930024, 1, -3870.56, 1991.62, 72.962, 25, 0, 0),
-- Turn-in points.
(9930031, 0, -9168.72, 768.735, 154.275, 15, 0, 0),
(9930032, 1, 2003.64, -4645.85, 25.9132, 15, 0, 0);

-- Source: rev_20261028_18_apex_client_ids.sql
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 9259 AND 9271;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(9259, 1, 2267.21, -6787.11, 125.24, 25, 0, 0),
(9260, 1, 2310.67, -6875.93, 121.74, 25, 0, 0),
(9261, 1, 2353.55, -6880.87, 121.21, 25, 0, 0),
(9262, 0, 138.558, -4523.49, 126.401, 25, 0, 0),
(9263, 0, 201.369, -4492.76, 119.737, 25, 0, 0),
(9264, 0, 156.261, -4482.47, 125.652, 25, 0, 0),
(9265, 0, 194.693, -4465.27, 110.869, 25, 0, 0),
(9266, 1, -3887.07, 1958.59, 75.3706, 25, 0, 0),
(9267, 1, -3815.15, 2018.34, 69.0198, 25, 0, 0),
(9268, 1, -3836.58, 1913.61, 81.4929, 25, 0, 0),
(9269, 1, -3870.56, 1991.62, 72.962, 25, 0, 0),
(9270, 0, -9168.72, 768.735, 154.275, 15, 0, 0),
(9271, 1, 2003.64, -4645.85, 25.9132, 15, 0, 0);
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 9930001 AND 9930032;

-- Source: rev_20261028_24_apex_track_reuse_ids.sql
DELETE FROM `coa_client_super_track` WHERE `ID` IN (2, 3, 27, 53, 78, 107, 108, 109, 110, 111, 116, 146, 202);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(2,   1, 2267.21, -6787.11, 125.24, 5.5, 0, 0),
(3,   1, 2310.67, -6875.93, 121.74, 5.5, 0, 0),
(27,  1, 2353.55, -6880.87, 121.21, 5.5, 0, 0),
(53,  0, 138.558, -4523.49, 126.401, 5.5, 0, 0),
(78,  0, 201.369, -4492.76, 119.737, 5.5, 0, 0),
(107, 0, 156.261, -4482.47, 125.652, 5.5, 0, 0),
(108, 0, 194.693, -4465.27, 110.869, 5.5, 0, 0),
(109, 1, -3887.07, 1958.59, 75.3706, 5.5, 0, 0),
(110, 1, -3815.15, 2018.34, 69.0198, 5.5, 0, 0),
(111, 1, -3836.58, 1913.61, 81.4929, 5.5, 0, 0),
(116, 1, -3870.56, 1991.62, 72.962, 5.5, 0, 0),
(146, 0, -9168.72, 768.735, 154.275, 5.5, 0, 0),
(202, 1, 2003.64, -4645.85, 25.9132, 5.5, 0, 0);

-- Source: rev_20261028_26_apex_track_marker_band.sql
DELETE FROM `coa_client_super_track` WHERE `ID` IN (2, 3, 27, 53, 78, 107, 108, 109, 110, 111, 116, 146, 202);
DELETE FROM `coa_client_super_track` WHERE `ID` IN (21505, 21506, 21507, 21508, 21509, 21510, 21513, 21523, 21529, 21551, 21588, 21589, 21603);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21505, 1, 2267.21, -6787.11, 125.24, 5.5, 0, 0),
(21506, 1, 2310.67, -6875.93, 121.74, 5.5, 0, 0),
(21507, 1, 2353.55, -6880.87, 121.21, 5.5, 0, 0),
(21508, 0, 138.558, -4523.49, 126.401, 5.5, 0, 0),
(21509, 0, 201.369, -4492.76, 119.737, 5.5, 0, 0),
(21510, 0, 156.261, -4482.47, 125.652, 5.5, 0, 0),
(21513, 0, 194.693, -4465.27, 110.869, 5.5, 0, 0),
(21523, 1, -3887.07, 1958.59, 75.3706, 5.5, 0, 0),
(21529, 1, -3815.15, 2018.34, 69.0198, 5.5, 0, 0),
(21551, 1, -3836.58, 1913.61, 81.4929, 5.5, 0, 0),
(21588, 1, -3870.56, 1991.62, 72.962, 5.5, 0, 0),
(21589, 0, -9168.72, 768.735, 154.275, 5.5, 0, 0),
(21603, 1, 2003.64, -4645.85, 25.9132, 5.5, 0, 0);

-- Source: rev_20261028_27_apex_track_shipped_ids.sql
DELETE FROM `coa_client_super_track` WHERE `ID` IN (7301, 7302, 7303, 7309, 7310, 7311);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(7301, 1, 2267.21, -6787.11, 125.24, 5.5, 0, 0),
(7302, 0, 138.558, -4523.49, 126.401, 5.5, 0, 0),
(7303, 1, -3887.07, 1958.59, 75.3706, 5.5, 0, 0),
(7309, 1, 2267.21, -6787.11, 125.24, 5.5, 0, 0),
(7310, 0, 138.558, -4523.49, 126.401, 5.5, 0, 0),
(7311, 1, -3887.07, 1958.59, 75.3706, 5.5, 0, 0);

-- Source: rev_20261031_00_skinpeeler_full_parity.sql
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 9259 AND 9271 OR `ID` BETWEEN 9930001 AND 9930032;
DELETE FROM `coa_client_super_track` WHERE `ID` IN (21505,21508,21523,21589,21603);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21505,1,2267.21,-6787.11,125.24,5.5,0,0),
(21508,0,138.558,-4523.49,126.401,5.5,0,0),
(21523,1,-3887.07,1958.59,75.3706,5.5,0,0),
(21589,0,-9168.72,768.735,154.275,5.5,0,0),
(21603,1,2003.64,-4645.85,25.9132,5.5,0,0);

-- Source: rev_20261102_01_unphased_infernal_skill_line.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 86011;
INSERT INTO `coa_client_skill_line_ability` (`ID`,`SkillLine`) VALUES
(86011,53);

-- Source: rev_20261108_761_cultist_blade_of_yogg_saron_skill_line_11676.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
  `ID` INT UNSIGNED NOT NULL,
  `SkillLine` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 842;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(842, 90);

-- Source: rev_20261111_01_cultist_shadow_pennant_skill_line_11505.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 843;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(843, 90);

-- Source: rev_20261113_11956_coa_dunshire_egg_super_track.sql
DELETE FROM `coa_client_super_track` WHERE `ID` = 21064;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21064, 0, -7815.85, 545.566, 136.357, 4, 0, 0);

-- Source: rev_20261113_70_venomancer_locust_swarm_skill_line_11934.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 22250;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(22250, 105);

-- Source: rev_20261113_71_venomancer_impale_skill_line_11935.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 22251;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(22251, 105);

-- Source: rev_20261113_72_venomancer_chrysalis_skill_line_11936.sql
CREATE TABLE IF NOT EXISTS `coa_client_skill_line_ability` (
    `ID` INT UNSIGNED NOT NULL,
    `SkillLine` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 844;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(844, 499);

-- Source: rev_20261114_12166_coa_reassignment_samuelson_marker.sql
DELETE FROM `coa_client_super_track` WHERE `ID` = 1318;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(1318, 0, -8407.6, 214.4, 155.347, 5.5, 0, 0);

-- Source: rev_20261118_10_coa_world_map_alterac_4418.sql
CREATE TABLE IF NOT EXISTS `coa_client_world_map_area` (
  `ID` INT NOT NULL,
  `MapID` INT NOT NULL DEFAULT 0,
  `AreaID` INT NOT NULL DEFAULT 0,
  `AreaName` VARCHAR(100) NOT NULL DEFAULT '',
  `LocLeft` FLOAT NOT NULL DEFAULT 0,
  `LocRight` FLOAT NOT NULL DEFAULT 0,
  `LocTop` FLOAT NOT NULL DEFAULT 0,
  `LocBottom` FLOAT NOT NULL DEFAULT 0,
  `DisplayMapID` INT NOT NULL DEFAULT -1,
  `DefaultDungeonFloor` INT NOT NULL DEFAULT 0,
  `ParentWorldMapID` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `coa_client_world_map_overlay` (
  `ID` INT NOT NULL,
  `MapAreaID` INT NOT NULL DEFAULT 0,
  `AreaID_1` INT NOT NULL DEFAULT 0,
  `AreaID_2` INT NOT NULL DEFAULT 0,
  `AreaID_3` INT NOT NULL DEFAULT 0,
  `AreaID_4` INT NOT NULL DEFAULT 0,
  `MapPointX` INT NOT NULL DEFAULT 0,
  `MapPointY` INT NOT NULL DEFAULT 0,
  `TextureName` VARCHAR(100) NOT NULL DEFAULT '',
  `TextureWidth` INT NOT NULL DEFAULT 0,
  `TextureHeight` INT NOT NULL DEFAULT 0,
  `OffsetX` INT NOT NULL DEFAULT 0,
  `OffsetY` INT NOT NULL DEFAULT 0,
  `HitRectTop` INT NOT NULL DEFAULT 0,
  `HitRectLeft` INT NOT NULL DEFAULT 0,
  `HitRectBottom` INT NOT NULL DEFAULT 0,
  `HitRectRight` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_client_world_map_area` WHERE `ID` IN (3044);
INSERT INTO `coa_client_world_map_area` (`ID`, `MapID`, `AreaID`, `AreaName`, `LocLeft`, `LocRight`, `LocTop`, `LocBottom`, `DisplayMapID`, `DefaultDungeonFloor`, `ParentWorldMapID`) VALUES
(3044, 4418, 36, 'Alterac', 783, -2016, 1500, -366, -1, 0, 0);
DELETE FROM `coa_client_world_map_overlay` WHERE `ID` IN (2964, 2965, 2966, 2967, 2968, 2969, 2970, 2971, 2972, 2973, 2974, 2975, 2976, 2977, 2978);
INSERT INTO `coa_client_world_map_overlay` (`ID`, `MapAreaID`, `AreaID_1`, `AreaID_2`, `AreaID_3`, `AreaID_4`, `MapPointX`, `MapPointY`, `TextureName`, `TextureWidth`, `TextureHeight`, `OffsetX`, `OffsetY`, `HitRectTop`, `HitRectLeft`, `HitRectBottom`, `HitRectRight`) VALUES
(2964, 3044, 1684, 3486, 0, 0, 0, 0, 'CHILLWINDPOINT', 350, 370, 626, 253, 330, 730, 560, 915),
(2965, 3044, 1679, 0, 0, 0, 0, 0, 'CORRAHNSDAGGER', 195, 288, 399, 380, 495, 435, 625, 530),
(2966, 3044, 282, 283, 0, 0, 0, 0, 'CRUSHRIDGEHOLD', 280, 240, 334, 162, 215, 435, 345, 535),
(2967, 3044, 279, 0, 0, 0, 0, 0, 'DALARAN', 300, 300, 26, 262, 360, 75, 520, 230),
(2968, 3044, 1682, 0, 0, 0, 0, 0, 'DANDREDSFOLD', 285, 230, 276, 0, 70, 370, 160, 440),
(2969, 3044, 1357, 0, 0, 0, 0, 0, 'GALLOWSCORNER', 200, 200, 406, 279, 355, 460, 430, 545),
(2970, 3044, 1677, 0, 0, 0, 0, 0, 'GAVINSNAZE', 160, 175, 225, 478, 525, 270, 620, 345),
(2971, 3044, 1683, 0, 0, 0, 0, 0, 'GROWLESSCAVE', 190, 170, 317, 372, 420, 345, 505, 450),
(2972, 3044, 278, 0, 0, 0, 0, 0, 'LORDAMEREINTERNMENTCAMP', 330, 265, 44, 403, 525, 160, 610, 250),
(2973, 3044, 1681, 0, 0, 0, 0, 0, 'MISTYSHORE', 220, 280, 196, 131, 190, 220, 315, 345),
(2974, 3044, 281, 0, 0, 0, 0, 0, 'RUINSOFALTERAC', 255, 255, 270, 197, 295, 330, 420, 470),
(2975, 3044, 1678, 0, 0, 0, 0, 0, 'SOFERASNAZE', 255, 320, 462, 307, 415, 540, 505, 630),
(2976, 3044, 280, 0, 0, 0, 0, 0, 'STRAHNBRAD', 370, 300, 549, 105, 255, 570, 350, 700),
(2977, 3044, 1680, 0, 0, 0, 0, 0, 'THEHEADLAND', 165, 197, 314, 471, 545, 345, 660, 435),
(2978, 3044, 284, 0, 0, 0, 0, 0, 'THEUPLANDS', 235, 200, 462, 77, 120, 500, 245, 630);
