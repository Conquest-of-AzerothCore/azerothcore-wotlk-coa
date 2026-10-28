-- Take the Feather of Ancients: Azeroth and the Conquest of Azeroth Travel Guide off sale.
-- Like rev_20261024_01 every statement only acts on a realm that fills the Vanity Store price table;
-- every statement writes fixed values, so a reapply leaves the result unchanged.

-- 1) Feather of Ancients: Azeroth (old and current id): Vanity Store price 0 instead of 1000 (rev_20261023_03).
--    Kept as rows at 0 so the server does not fall back to the VanityCollection.dbc price (#8788).
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES
  ROW(134989),  -- Feather of Ancients: Azeroth
  ROW(977025)   -- Feather of Ancients: Azeroth
) `n` (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;

-- 2) ... and out of the Lost Convenience Cache.
DELETE FROM `ethereal_bazaar_cache_pool`
WHERE `cache_item` = 8950007 AND `reward_item` IN (134989, 977025)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

-- 3) The Conquest of Azeroth Travel Guide is no longer sold by Tiraxis (Convenience Items, rev_20261013_10).
DELETE FROM `npc_vendor`
WHERE `entry` = 900008 AND `item` = 97318
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
