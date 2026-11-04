-- The Portable Call Boards (Alliance, Horde, Outlaw) cost 10000 Bazaar Tokens in the Vanity Store (was 600 since
-- rev_20261023_03). A reapply changes nothing. Like rev_20261024_01 it only acts on a realm that fills the Vanity
-- Store price table.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 10000
FROM (VALUES ROW(1913515), ROW(1913516), ROW(1913517)) n (`ItemID`)  -- Portable Call Board (Alliance, Horde, Outlaw)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `BazaarTokenCost` = 10000;
