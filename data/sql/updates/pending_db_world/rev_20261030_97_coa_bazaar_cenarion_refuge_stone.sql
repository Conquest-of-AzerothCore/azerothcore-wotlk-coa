-- Tiraxis' Stones of Retreat list (900010): the second Outland Cenarion Refuge stone (1175643), missed by
-- rev_20261024_10, which retired 102180. Same realm scope as that file.
DELETE FROM `npc_vendor`
WHERE `entry` = 900010 AND `item` = 1175643
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
