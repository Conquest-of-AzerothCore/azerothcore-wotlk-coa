UPDATE `coa_client_vanity_collection`
SET `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 5000
WHERE `ItemID` = 1180097  -- Realm Bank
  AND EXISTS (SELECT 1 FROM (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0) AS `g`);
