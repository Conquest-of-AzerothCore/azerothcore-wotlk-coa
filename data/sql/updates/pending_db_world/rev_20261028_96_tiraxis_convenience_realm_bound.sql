-- Tiraxis' Convenience Items (900008) are Realm Bound like the Vanity items next to them: bonding 1 plus
-- ITEM_FLAG_IS_BOUND_TO_ACCOUNT (0x08000000), which the Ascension client shows as "Realm Bound". These seven are not in
-- coa_client_vanity_collection, so the Vanity account-bound change (#9623) does not reach them. A reapply leaves the
-- result unchanged. Like rev_20261024_01 it only acts on a realm that fills the Vanity Store price table.
UPDATE `item_template`
SET `bonding` = 1, `Flags` = `Flags` | 0x08000000
WHERE `entry` IN (
  818047,   -- Potion of Reputation
  200001,   -- Race Change Potion
  910200,   -- Faction Change Potion
  910201,   -- Customization Potion
  1179288,  -- Unlock Talent Loadout
  1806961,  -- Mystic Enchanting: Specialization
  97332     -- Master's Tome Of Specialization (8-20)
)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
