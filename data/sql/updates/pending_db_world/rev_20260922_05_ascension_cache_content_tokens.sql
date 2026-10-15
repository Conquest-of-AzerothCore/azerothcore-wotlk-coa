-- The tier tokens each Prestigious Cache may pay.
--
-- A Prestigious Cache promises a chance of one or more tier tokens. The token is not global:
-- it belongs to the content its reward comes from, so a Molten Core Cache pays the Molten
-- tokens and a Zul'Gurub or Heroic Dungeon Cache pays none, because no token of those
-- contents exists. Placement was decided from real evidence, strongest first - the map the
-- token itself drops on, then the items it buys through the vendor cost table in
-- ItemExtendedCost.dbc, then the content of its own tier whose loot covers the slot its text
-- names, which is what separates the Ruins of Ahn'Qiraj accessory tokens from the Temple of
-- Ahn'Qiraj set tokens. Every row also sits inside its own tier's content, so a stale item
-- tag can never drag a Tier 5 or Tier 6 token into a vanilla raid. Evidence names what
-- placed the row, which is how a reviewer can tell a confirmed row from an inferred one.
--
-- TokenStage is the token's tier doubled so the half tiers fit a whole number (Tier 2.5 is
-- 5); a tier the realm has not released yet is still held back by the release stage.

DROP TABLE IF EXISTS `ascension_cache_content_token`;
CREATE TABLE `ascension_cache_content_token` (
  `CacheItemId` INT UNSIGNED NOT NULL,
  `RewardItemId` INT UNSIGNED NOT NULL,
  `RewardItemLevel` SMALLINT UNSIGNED NOT NULL,
  `TokenStage` TINYINT UNSIGNED NOT NULL,
  `Evidence` VARCHAR(16) NOT NULL DEFAULT '',
  PRIMARY KEY (`CacheItemId`, `RewardItemId`),
  KEY `RewardItemId` (`RewardItemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Superseded by `ascension_cache_content_token`: one global ladder let every cache pay every
-- released tier, which is how a Zul'Gurub Cache handed out a Tier 6 token.
DROP TABLE IF EXISTS `ascension_cache_global_token`;

DELETE FROM `ascension_cache_content_token`;
INSERT INTO `ascension_cache_content_token` VALUES
(1287306, 2522350, 60, 2, 'coverage'),
(1287306, 2522359, 60, 2, 'coverage'),
(1287306, 2522360, 60, 2, 'coverage'),
(1287306, 2522361, 60, 2, 'coverage'),
(1287306, 2522362, 60, 2, 'coverage'),
(1287306, 2522363, 60, 2, 'coverage'),
(1287306, 2522364, 60, 2, 'coverage'),
(1287306, 2522365, 60, 2, 'coverage'),
(1287307, 2522460, 60, 4, 'coverage'),
(1287308, 2522450, 60, 4, 'coverage'),
(1287308, 2522459, 60, 4, 'coverage'),
(1287308, 2522461, 60, 4, 'coverage'),
(1287308, 2522462, 60, 4, 'coverage'),
(1287308, 2522463, 60, 4, 'coverage'),
(1287308, 2522464, 60, 4, 'coverage'),
(1287308, 2522465, 60, 4, 'coverage'),
(1287309, 1506051, 60, 5, 'coverage'),
(1287309, 1506052, 60, 5, 'coverage'),
(1287309, 1506053, 60, 5, 'coverage'),
(1287310, 20928, 60, 5, 'drop'),
(1287310, 20930, 60, 5, 'drop'),
(1287310, 20931, 60, 5, 'sibling'),
(1287310, 20932, 60, 5, 'drop'),
(1287310, 20933, 60, 5, 'drop'),
(1287310, 1506051, 60, 5, 'coverage'),
(1287310, 1506052, 60, 5, 'coverage'),
(1287310, 1506053, 60, 5, 'coverage'),
(1287311, 22349, 60, 6, 'coverage'),
(1287311, 22352, 60, 6, 'coverage'),
(1287311, 22353, 60, 6, 'coverage'),
(1287311, 22354, 60, 6, 'coverage'),
(1287311, 22355, 60, 6, 'coverage'),
(1287311, 22356, 60, 6, 'coverage'),
(1287311, 22357, 60, 6, 'coverage'),
(1287311, 22358, 60, 6, 'coverage'),
(1287311, 1510496, 67, 6, 'coverage'),
(1297310, 29758, 115, 8, 'drop'),
(1297310, 29761, 115, 8, 'drop'),
(1297311, 29764, 115, 8, 'drop'),
(1297311, 29767, 115, 8, 'drop'),
(1297312, 29753, 115, 8, 'drop'),
(1297313, 30240, 124, 10, 'drop'),
(1297313, 30243, 124, 10, 'drop'),
(1297313, 30246, 124, 10, 'drop'),
(1297314, 30237, 124, 10, 'drop'),
(1297314, 30249, 124, 10, 'drop'),
(1297316, 31097, 134, 12, 'drop'),
(1297317, 31089, 134, 12, 'drop'),
(1297317, 31098, 134, 12, 'drop'),
(1297317, 31101, 134, 12, 'drop'),
(1297318, 31092, 134, 12, 'sibling'),
(1297318, 34848, 145, 12, 'drop'),
(1297318, 34853, 145, 12, 'drop'),
(1297318, 34856, 145, 12, 'drop');
