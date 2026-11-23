DELETE FROM `npc_vendor`
WHERE `entry` = 900010 AND `item` IN (1203466, 1203467, 1203468, 1203469)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
