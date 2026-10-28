-- Two attunement items leave the Vanity Store (both were sold at 1500) and are earned the normal way again:
--   212219 Forged Seal of Ascension (Upper Blackrock Spire key) - reward of quest 4743
--   719220 Medallion of Karabor (Black Temple)                  - reward of quests 10985 and 13429
-- Kept as rows at price 0 rather than deleted, so the server does not fall back to the VanityCollection.dbc price
-- (#8788). Like rev_20261024_01 it only acts on a realm that fills the price table; a reapply leaves the result unchanged.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES
  ROW(212219),  -- Forged Seal of Ascension
  ROW(719220)   -- Medallion of Karabor
) `n` (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;
