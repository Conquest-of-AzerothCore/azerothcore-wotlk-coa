-- The row is kept and set to 0, never deleted: without a row the server streams the VanityCollection.dbc price.
UPDATE `coa_client_vanity_collection`
SET `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0
WHERE `ItemID` = 1777039;
INSERT IGNORE INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT `n`.`ItemID`, 0, 0, 0
FROM (VALUES ROW(1777039)) `n` (`ItemID`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
