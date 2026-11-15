-- Chromie's Experience Items (990782), Bazaar Token prices matching Tiraxis' Convenience Items (900008), with the same
-- ItemExtendedCost ids (ItemExtendedCost.dbc, item 975001 x count):
--   * Potion of Experience 818046: 100 -> 300 tokens (ExtendedCost 2983 -> 3014).
--   * Aura of Experience 818059: 350 -> 1000 tokens (ExtendedCost 3015 -> 10339).
UPDATE `npc_vendor` SET `ExtendedCost` = 3014 WHERE `entry` = 990782 AND `item` = 818046;
UPDATE `npc_vendor` SET `ExtendedCost` = 10339 WHERE `entry` = 990782 AND `item` = 818059;
