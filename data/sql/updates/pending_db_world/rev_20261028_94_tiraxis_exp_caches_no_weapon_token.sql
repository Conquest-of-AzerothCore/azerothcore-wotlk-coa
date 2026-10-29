-- The seven Experience Heirloom Caches (1339051-1339057) no longer hold the 3 Heirloom Weapon Tokens (414010);
-- the caches keep their shoulders, chest and two trinkets. Their descriptions stop listing the tokens.
-- A reapply changes nothing (the rows and the line are already gone). Like rev_20261024_01 it only acts on a realm
-- that fills the Vanity Store price table.
DELETE FROM `ethereal_bazaar_set_cache`
WHERE `cache_item` BETWEEN 1339051 AND 1339057 AND `member_item` = 414010  -- Heirloom Weapon Token
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

UPDATE `item_template`
SET `description` = REPLACE(`description`, '\nContains x3 Heirloom Weapon Token', '')
WHERE `entry` BETWEEN 1339051 AND 1339057
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
