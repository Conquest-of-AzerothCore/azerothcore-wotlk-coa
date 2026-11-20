-- Binds every existing copy of the Bazaar Token vendor items made Realm Bound in
-- rev_20261120_02_token_vendor_items_realm_bound (world), so copies bought before the change cannot be traded either.
-- Runs at worldserver start, when no player holds them in memory. A reapply leaves the result unchanged.
UPDATE `item_instance`
SET `flags` = `flags` | 1
WHERE `itemEntry` IN (97388, 246194, 246199, 969029, 102130, 102131, 110002, 1180485, 1203466, 1203467, 1203468,
                      1203469, 1880045, 1880046, 8950001, 8950002, 8950003, 8950004, 8950005, 8950006, 8950008)
  AND (`flags` & 1) = 0;
