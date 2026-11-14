-- The Realm Bank (1180097) is sold again in the Vanity Store for 3500 Bazaar Tokens (taken out by rev_20261023_00 and
-- kept at price 0 by rev_20261024_01). A reapply changes nothing. Like rev_20261024_01 it only acts on a realm that
-- fills the Vanity Store price table.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 3500
FROM (VALUES ROW(1180097)) n (`ItemID`)  -- Realm Bank
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 3500;
