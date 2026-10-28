-- Every Vanity tab item binds to the account, like an heirloom: bonding 1 plus ITEM_FLAG_IS_BOUND_TO_ACCOUNT
-- (0x08000000). Copies can be mailed between characters of the same account (MailHandler checks the account),
-- but not traded, auctioned or sent to another account.
-- #9425 made 8685 Vanity items Bind on Pickup and binds Vanity deliveries in the core; realms that do not run that
-- core yet could still deliver the other Vanity items unbound and sell them. This closes it in data: every item
-- in coa_client_vanity_collection, including the ones that also drop or are sold elsewhere, is now account bound.
-- Only Vanity items are touched, and like rev_20261024_01 only on a realm that fills the price table.
-- A reapply leaves the result unchanged.
UPDATE `item_template` `it`
JOIN `coa_client_vanity_collection` `v` ON `v`.`ItemID` = `it`.`entry`
SET `it`.`bonding` = 1, `it`.`Flags` = `it`.`Flags` | 0x08000000
WHERE (`it`.`bonding` <> 1 OR (`it`.`Flags` & 0x08000000) = 0)
  AND EXISTS (SELECT 1 FROM (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0 LIMIT 1) `priced`);
