DELETE FROM `npc_vendor`
WHERE `entry` = 900010 AND `item` IN (1880045, 1880046)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
