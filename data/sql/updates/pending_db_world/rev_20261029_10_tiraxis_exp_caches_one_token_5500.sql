-- The seven Experience Heirloom Caches (1339051-1339057) hold one Heirloom Weapon Token (414010) again, after
-- rev_20261028_94 took their three out, and cost 5500 Bazaar Tokens on Tiraxis' heirloom list (900011) instead of
-- 4500 (ItemExtendedCost 10384 charges exactly 5500 Bazaar Tokens). The Heirloom Caches without the experience bonus
-- stay at 4500. A reapply leaves the result unchanged. Like rev_20261024_01 it only acts on a realm that fills the
-- Vanity Store price table.

-- One token per cache, first in the cache like before
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
SELECT `c`.`cache_item`, 414010, 0, 1  -- Heirloom Weapon Token
FROM (VALUES ROW(1339051), ROW(1339052), ROW(1339053), ROW(1339054), ROW(1339055), ROW(1339056), ROW(1339057)) `c` (`cache_item`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `idx` = 0, `count` = 1;

-- The description lists it again, right after the first line
UPDATE `item_template`
SET `description` = REPLACE(`description`, 'Experience Boost to you.\n', 'Experience Boost to you.\nContains x1 Heirloom Weapon Token\n')
WHERE `entry` BETWEEN 1339051 AND 1339057
  AND `description` NOT LIKE '%Heirloom Weapon Token%'
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

-- 5500 Bazaar Tokens; npc_vendor's key includes ExtendedCost, so the rows are deleted and re-inserted in their slots
DELETE FROM `npc_vendor`
WHERE `entry` = 900011 AND `item` BETWEEN 1339051 AND 1339057
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
SELECT 900011, `c`.`slot`, `c`.`item`, 0, 0, 10384
FROM (VALUES
  ROW(0, 1339051),   -- Tattered Dreadmist Raiment - Experience Heirloom Cache
  ROW(2, 1339052),   -- Preened Ironfeather Armor - Experience Heirloom Cache
  ROW(4, 1339053),   -- Stained Shadowcraft Armor - Experience Heirloom Cache
  ROW(6, 1339054),   -- Champion's Battlegear - Experience Heirloom Cache
  ROW(8, 1339055),   -- Polished Battlegear of Valor - Experience Heirloom Cache
  ROW(10, 1339056),  -- Armor of Might - Experience Heirloom Cache
  ROW(12, 1339057)   -- The Mystical Elements - Experience Heirloom Cache
) `c` (`slot`, `item`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
