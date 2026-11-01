-- The Heirloom Weapon Token (414010), which the Experience Heirloom Caches hold, is Realm Bound like the heirlooms
-- it buys: bonding 1 plus ITEM_FLAG_IS_BOUND_TO_ACCOUNT (0x08000000), shown as "Realm Bound" by the Ascension client.
-- It was Bind on Use, so an unused token could be traded or auctioned. A reapply leaves the result unchanged.
-- Like rev_20261024_01 it only acts on a realm that fills the Vanity Store price table.
UPDATE `item_template`
SET `bonding` = 1, `Flags` = `Flags` | 0x08000000
WHERE `entry` = 414010  -- Heirloom Weapon Token
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
