-- Vanity Store: every mount sold at 3800 (rev_20261023_03) now costs 6000, as set on the Rexxar realm.
-- Mounts taken out of the store keep their price-0 rows (#8788, #8882): only rows at 3800 change, so a reapply
-- leaves the result unchanged; mounts with no price (0) are not touched. Like rev_20261024_01 it only acts on a realm that
-- fills the price table.
UPDATE `coa_client_vanity_collection` `v`
JOIN `item_template` `it` ON `it`.`entry` = `v`.`ItemID`
SET `v`.`BazaarTokenCost` = 6000
WHERE `it`.`class` = 15 AND `it`.`subclass` = 5 AND `v`.`BazaarTokenCost` = 3800
  AND EXISTS (SELECT 1 FROM (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0 LIMIT 1) `priced`);
