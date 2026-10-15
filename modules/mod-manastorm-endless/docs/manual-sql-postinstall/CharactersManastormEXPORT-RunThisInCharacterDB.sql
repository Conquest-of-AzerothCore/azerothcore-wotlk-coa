/*
 Navicat Premium Dump SQL

 Source Server         : Acension
 Source Server Type    : MySQL
 Source Server Version : 80409 (8.4.9)
 Source Host           : localhost:3307
 Source Schema         : acore_characters

 Target Server Type    : MySQL
 Target Server Version : 80409 (8.4.9)
 File Encoding         : 65001

 Date: 15/10/2026 17:44:55
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for character_manastorm_completed_depth
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_completed_depth`;
CREATE TABLE `character_manastorm_completed_depth`  (
  `guid` int UNSIGNED NOT NULL,
  `mode` tinyint UNSIGNED NOT NULL,
  `track` tinyint UNSIGNED NOT NULL,
  `depth` int UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`, `mode`, `track`, `depth`) USING BTREE,
  INDEX `idx_guid_track`(`guid` ASC, `track` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_completed_depth
-- ----------------------------
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 2);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 3);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 4);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 5);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 6);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 7);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 8);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 9);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 10);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 11);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 12);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 13);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 14);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 15);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 16);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 17);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 18);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 19);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 20);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 21);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 1, 22);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 2, 1, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 2, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 2, 2);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 1, 2, 6);
INSERT INTO `character_manastorm_completed_depth` VALUES (3, 2, 2, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (4, 2, 1, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (4, 2, 2, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 2);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 3);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 4);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 5);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 6);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 7);
INSERT INTO `character_manastorm_completed_depth` VALUES (6, 1, 1, 8);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 1);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 2);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 3);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 4);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 5);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 6);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 7);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 8);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 9);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 10);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 11);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 12);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 13);
INSERT INTO `character_manastorm_completed_depth` VALUES (7, 1, 1, 14);
INSERT INTO `character_manastorm_completed_depth` VALUES (36, 1, 1, 6);
INSERT INTO `character_manastorm_completed_depth` VALUES (36, 1, 2, 6);
INSERT INTO `character_manastorm_completed_depth` VALUES (106, 1, 1, 8);
INSERT INTO `character_manastorm_completed_depth` VALUES (106, 1, 2, 8);
INSERT INTO `character_manastorm_completed_depth` VALUES (108, 1, 1, 11);
INSERT INTO `character_manastorm_completed_depth` VALUES (108, 1, 2, 11);

-- ----------------------------
-- Table structure for character_manastorm_completion_reward_state
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_completion_reward_state`;
CREATE TABLE `character_manastorm_completion_reward_state`  (
  `guid` int UNSIGNED NOT NULL,
  `mode` tinyint UNSIGNED NOT NULL,
  `track` tinyint UNSIGNED NOT NULL,
  `reward_key` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `remainder_bp` int UNSIGNED NOT NULL DEFAULT 0,
  `earned` bigint UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `mode`, `track`, `reward_key`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_completion_reward_state
-- ----------------------------
INSERT INTO `character_manastorm_completion_reward_state` VALUES (3, 1, 1, 'MARKS', 0, 7700);
INSERT INTO `character_manastorm_completion_reward_state` VALUES (3, 1, 1, 'MARKS_FIRST', 0, 100);
INSERT INTO `character_manastorm_completion_reward_state` VALUES (7, 1, 1, 'BONUS_CACHE_OTHER', 0, 14);
INSERT INTO `character_manastorm_completion_reward_state` VALUES (7, 1, 1, 'MARKS', 0, 2800);
INSERT INTO `character_manastorm_completion_reward_state` VALUES (7, 1, 1, 'MARKS_FIRST', 0, 1400);

-- ----------------------------
-- Table structure for character_manastorm_pending_currency
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_pending_currency`;
CREATE TABLE `character_manastorm_pending_currency`  (
  `guid` int UNSIGNED NOT NULL,
  `item_entry` int UNSIGNED NOT NULL,
  `quantity` bigint UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `item_entry`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_pending_currency
-- ----------------------------

-- ----------------------------
-- Table structure for character_manastorm_pending_experience
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_pending_experience`;
CREATE TABLE `character_manastorm_pending_experience`  (
  `guid` int UNSIGNED NOT NULL,
  `base_xp` bigint UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_pending_experience
-- ----------------------------
INSERT INTO `character_manastorm_pending_experience` VALUES (3, 0);

-- ----------------------------
-- Table structure for character_manastorm_pending_unlock
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_pending_unlock`;
CREATE TABLE `character_manastorm_pending_unlock`  (
  `guid` int UNSIGNED NOT NULL,
  `mode` tinyint UNSIGNED NOT NULL COMMENT '1=SOLO, 2=DUO, 3=TRIO, 4=GROUP',
  `track` tinyint UNSIGNED NOT NULL DEFAULT 1,
  `unlock_id` int UNSIGNED NOT NULL,
  `queued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `mode`, `track`) USING BTREE,
  INDEX `idx_character_manastorm_pending_unlock`(`unlock_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Manastorm content waiting for next-run introduction' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_pending_unlock
-- ----------------------------

-- ----------------------------
-- Table structure for character_manastorm_progress
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_progress`;
CREATE TABLE `character_manastorm_progress`  (
  `guid` int UNSIGNED NOT NULL,
  `mode` tinyint UNSIGNED NOT NULL COMMENT '1=SOLO, 2=DUO, 3=TRIO, 4=GROUP',
  `track` tinyint UNSIGNED NOT NULL DEFAULT 1,
  `best_completed_depth` int UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `mode`, `track`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Shared Manastorm best completed depth per character/mode' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_progress
-- ----------------------------
INSERT INTO `character_manastorm_progress` VALUES (3, 1, 1, 22, '2026-10-13 16:33:23');
INSERT INTO `character_manastorm_progress` VALUES (3, 1, 2, 6, '2026-10-02 15:12:50');
INSERT INTO `character_manastorm_progress` VALUES (3, 2, 1, 1, '2026-09-21 15:20:41');
INSERT INTO `character_manastorm_progress` VALUES (3, 2, 2, 1, '2026-09-21 15:20:41');
INSERT INTO `character_manastorm_progress` VALUES (4, 2, 1, 1, '2026-09-21 15:20:41');
INSERT INTO `character_manastorm_progress` VALUES (4, 2, 2, 1, '2026-09-21 15:20:41');
INSERT INTO `character_manastorm_progress` VALUES (6, 1, 1, 8, '2026-09-24 16:49:06');
INSERT INTO `character_manastorm_progress` VALUES (7, 1, 1, 14, '2026-10-06 18:45:52');
INSERT INTO `character_manastorm_progress` VALUES (36, 1, 1, 6, '2026-09-08 12:54:59');
INSERT INTO `character_manastorm_progress` VALUES (36, 1, 2, 6, '2026-09-08 12:54:59');
INSERT INTO `character_manastorm_progress` VALUES (106, 1, 1, 8, '2026-09-08 16:49:20');
INSERT INTO `character_manastorm_progress` VALUES (106, 1, 2, 8, '2026-09-08 16:49:20');
INSERT INTO `character_manastorm_progress` VALUES (108, 1, 1, 11, '2026-09-11 16:10:47');
INSERT INTO `character_manastorm_progress` VALUES (108, 1, 2, 11, '2026-09-11 16:10:47');

-- ----------------------------
-- Table structure for character_manastorm_reward_state
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_reward_state`;
CREATE TABLE `character_manastorm_reward_state`  (
  `guid` int UNSIGNED NOT NULL,
  `mode` tinyint UNSIGNED NOT NULL,
  `track` tinyint UNSIGNED NOT NULL,
  `cache_chance_pct` tinyint UNSIGNED NOT NULL DEFAULT 0,
  `bedlam_remainder_bp` smallint UNSIGNED NOT NULL DEFAULT 0,
  `bonzo_remainder_bp` smallint UNSIGNED NOT NULL DEFAULT 0,
  `caches_earned` int UNSIGNED NOT NULL DEFAULT 0,
  `bedlam_earned` bigint UNSIGNED NOT NULL DEFAULT 0,
  `bonzo_earned` bigint UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `mode`, `track`) USING BTREE,
  INDEX `idx_character_manastorm_reward_guid`(`guid` ASC) USING BTREE,
  CONSTRAINT `chk_character_manastorm_reward_bedlam_remainder` CHECK (`bedlam_remainder_bp` < 10000),
  CONSTRAINT `chk_character_manastorm_reward_bonzo_remainder` CHECK (`bonzo_remainder_bp` < 10000),
  CONSTRAINT `chk_character_manastorm_reward_cache_pct` CHECK (`cache_chance_pct` <= 100),
  CONSTRAINT `chk_character_manastorm_reward_mode` CHECK (`mode` between 1 and 4),
  CONSTRAINT `chk_character_manastorm_reward_track` CHECK (`track` in (1,2))
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_reward_state
-- ----------------------------
INSERT INTO `character_manastorm_reward_state` VALUES (3, 1, 1, 26, 0, 0, 19, 15, 12497, '2026-10-13 16:33:23');
INSERT INTO `character_manastorm_reward_state` VALUES (3, 1, 2, 13, 0, 0, 2, 2, 170, '2026-10-02 15:12:50');
INSERT INTO `character_manastorm_reward_state` VALUES (6, 1, 1, 13, 0, 0, 2, 8, 50, '2026-09-24 16:49:06');
INSERT INTO `character_manastorm_reward_state` VALUES (7, 1, 1, 0, 0, 0, 4, 14, 78, '2026-10-06 18:45:52');

-- ----------------------------
-- Table structure for character_manastorm_unlock
-- ----------------------------
DROP TABLE IF EXISTS `character_manastorm_unlock`;
CREATE TABLE `character_manastorm_unlock`  (
  `guid` int UNSIGNED NOT NULL,
  `unlock_id` int UNSIGNED NOT NULL,
  `unlocked_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `unlock_id`) USING BTREE,
  INDEX `idx_character_manastorm_unlock_id`(`unlock_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'Permanent shared Manastorm unlocks owned by a character' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of character_manastorm_unlock
-- ----------------------------
INSERT INTO `character_manastorm_unlock` VALUES (3, 900021, '2026-10-09 17:39:29');
INSERT INTO `character_manastorm_unlock` VALUES (3, 1000005, '2026-10-08 19:09:09');

SET FOREIGN_KEY_CHECKS = 1;
