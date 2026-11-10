-- The Wondrous Wisdomball (101169) is no longer sold or found anywhere: it becomes the reward of a custom questline
-- (Khadgar, "The Answer Is No") that follows separately. Removed: the pet vendors Donni Anthania 6367, Xan'tish 8404,
-- Dealer Rashaad 20980 and Breanni 28951, Tiraxis' Convenience list 900008 (800 tokens, rev_20261013_10), the Lost
-- Convenience Cache 8950007 pool (its "One of N possible items" line is recounted), and the Vanity Store: a price-0 row,
-- only on a realm that prices its store (an empty table falls back to the DBC price, 0 for this item).
-- A reapply changes nothing.
DELETE FROM `npc_vendor` WHERE `item` = 101169;

DELETE FROM `ethereal_bazaar_cache_pool` WHERE `reward_item` = 101169;

UPDATE `item_template`
SET `description` = REGEXP_REPLACE(`description`, 'One of [0-9]+ possible items',
    CONCAT('One of ', (SELECT COUNT(*) FROM `ethereal_bazaar_cache_pool` WHERE `cache_item` = 8950007), ' possible items'))
WHERE `entry` = 8950007;

INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 0
FROM (VALUES ROW(101169)) n (`ItemID`)  -- Wondrous Wisdomball
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;
