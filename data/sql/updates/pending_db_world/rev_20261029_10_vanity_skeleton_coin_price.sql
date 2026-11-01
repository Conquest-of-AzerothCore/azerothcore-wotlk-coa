-- The Skeleton Coin (818060) is sold again in the Vanity Store for 1500 Bazaar Tokens, the price of the other toys
-- (Dealer's Draft Deck, Loaded Starter Dice, Eye of N'zoth). A reapply changes nothing. Like rev_20261024_01 it only
-- acts on a realm that fills the Vanity Store price table.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 1500
FROM (VALUES ROW(818060)) n (`ItemID`)  -- The Skeleton Coin
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `BazaarTokenCost` = 1500;
