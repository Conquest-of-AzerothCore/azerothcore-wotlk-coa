-- Light of Ascension (505001) is sold in the Vanity Store again, for 1000 Bazaar Tokens.
-- rev_20261024_01_vanity_unsold_zero_price set its price to 0, which the store refuses. As with the other price
-- files, only a realm that fills coa_client_vanity_collection has the row; on an empty table this changes nothing.
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = 1000 WHERE `ItemID` = 505001;
