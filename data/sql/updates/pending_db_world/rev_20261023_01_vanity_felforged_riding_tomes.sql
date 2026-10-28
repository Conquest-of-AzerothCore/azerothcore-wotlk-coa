-- Follow-up to rev_20261023_00_bazaar_vanity_prices.sql (#8554): the Felforged riding tomes are no longer
-- sold in the Vanity Store either (rows removed; a realm without these rows is unchanged).
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  3001007,  -- Felforged Tome: Journeyman Riding
  3001008   -- Felforged Tome: Apprentice Riding
);
