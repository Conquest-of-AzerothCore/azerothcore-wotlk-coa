-- Items taken out of the Vanity Store must keep a row with price 0. Without a row the server falls back to the
-- Bazaar Token price in the client's VanityCollection.dbc, and these items have one there, so deleting their row
-- (#8554, #8686) left them buyable. A price of 0 is refused ("That item cannot be bought with Bazaar Tokens").
-- Only on a realm that fills the table: on an empty one, rows here would be the whole store.
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
SELECT n.`ItemID`, 0, 0, 0
FROM (
        SELECT 461563 AS `ItemID`  -- Aura of Fel Power
  UNION ALL SELECT 818061  -- Aura of Reputation
  UNION ALL SELECT 461566  -- Aura of Souls
  UNION ALL SELECT 3001006  -- Riding Tome: Apprentice Riding
  UNION ALL SELECT 3001005  -- Riding Tome: Journeyman Riding
  UNION ALL SELECT 2200034  -- Soulbound Riding Tome: Apprentice Riding
  UNION ALL SELECT 2200033  -- Soulbound Riding Tome: Journeyman Riding
  UNION ALL SELECT 106955  -- Tome of Specialization II
  UNION ALL SELECT 106956  -- Tome of Specialization III
  UNION ALL SELECT 134980  -- Tome of Specialization III
  UNION ALL SELECT 106957  -- Tome of Specialization IV
  UNION ALL SELECT 134981  -- Tome of Specialization IV
  UNION ALL SELECT 106958  -- Tome of Specialization V
  UNION ALL SELECT 134982  -- Tome of Specialization V
  UNION ALL SELECT 777998  -- Tradesman's Scroll
  UNION ALL SELECT 97398  -- Seasonal Achievements Unlock
  UNION ALL SELECT 190190  -- Loot-Transfigurator 5000
  UNION ALL SELECT 190191  -- The Skin-Peeler 9000
) n
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `DonationPointCost` = 0, `SeasonalPointCost` = 0, `BazaarTokenCost` = 0;
