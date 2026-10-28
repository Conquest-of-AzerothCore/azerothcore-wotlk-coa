-- 121815 Voidtalon of the Dark Star leaves the Vanity Store (rev_20261023_03 priced it at 3800 with the other mounts).
-- The store row is its only source: no vendor, cache pool, loot table or quest gives it.
-- Kept as a row at price 0 rather than deleted, so the server does not fall back to the VanityCollection.dbc price (#8788).
-- Like rev_20261024_01 it only acts on a realm that fills the price table; a reapply leaves the result unchanged.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES ROW(121815)) `n` (`ItemID`)  -- Voidtalon of the Dark Star
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;
