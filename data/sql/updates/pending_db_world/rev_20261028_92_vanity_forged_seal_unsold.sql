-- 212219 Forged Seal of Ascension, the key to Upper Blackrock Spire, leaves the Vanity Store (it was sold at 1500).
-- It stays the reward of quest 4743, the normal way to earn it. Kept as a row at price 0 rather than deleted, so the
-- server does not fall back to the VanityCollection.dbc price (#8788). Like rev_20261024_01 it only acts on a realm
-- that fills the price table; a reapply leaves the result unchanged.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES ROW(212219)) `n` (`ItemID`)  -- Forged Seal of Ascension
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;
