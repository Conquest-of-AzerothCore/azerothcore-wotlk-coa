-- The Portable Call Boards (Alliance, Horde, Outlaw) cost 10000 Bazaar Tokens in the Vanity Store (was 600 since
-- rev_20261023_03), Bazaar Tokens only, and leave the Lost Convenience Cache 8950007 pool (250 tokens), whose
-- "One of N possible items" line is recounted. A reapply changes nothing. Like rev_20261024_01 it only acts on a
-- realm that fills the Vanity Store price table.
UPDATE `coa_client_vanity_collection`
SET `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 10000
WHERE `ItemID` IN (1913515, 1913516, 1913517)  -- Portable Call Board (Alliance, Horde, Outlaw)
  AND EXISTS (SELECT 1 FROM (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0) AS `g`);

DELETE FROM `ethereal_bazaar_cache_pool`
WHERE `cache_item` = 8950007 AND `reward_item` IN (1913515, 1913516, 1913517)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

UPDATE `item_template`
SET `description` = REGEXP_REPLACE(`description`, 'One of [0-9]+ possible items',
    CONCAT('One of ', (SELECT COUNT(*) FROM `ethereal_bazaar_cache_pool` WHERE `cache_item` = 8950007), ' possible items'))
WHERE `entry` = 8950007;
