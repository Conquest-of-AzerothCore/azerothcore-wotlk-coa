UPDATE `coa_client_vanity_collection`
SET `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0
WHERE `ItemID` = 213347;

DELETE FROM `ethereal_bazaar_pool` WHERE `item` = 213347;

DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 213347 AND `member_item` BETWEEN 213348 AND 213355;
