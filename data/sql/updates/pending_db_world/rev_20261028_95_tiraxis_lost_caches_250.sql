-- Tiraxis' Lost Caches (vendor 900009) cost 250 Bazaar Tokens instead of 100. ItemExtendedCost 2990 charges exactly
-- 250 Bazaar Tokens (975001). The rows are deleted and re-inserted, because npc_vendor's key includes ExtendedCost;
-- a reapply leaves one row per cache at 2990. The Lost Toy and Lost Convenience Caches stay unsold (#8882).
-- Like rev_20261024_01 it only acts on a realm that fills the Vanity Store price table.
DELETE FROM `npc_vendor`
WHERE `entry` = 900009 AND `item` IN (8950001, 8950002, 8950003, 8950004, 8950005, 8950006, 8950008)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
SELECT 900009, 0, `c`.`item`, 0, 0, 2990
FROM (VALUES
  ROW(8950001),  -- Lost Weapon Cache
  ROW(8950002),  -- Lost Armor Cache
  ROW(8950003),  -- Lost Mount Cache
  ROW(8950004),  -- Lost Spell Cache
  ROW(8950005),  -- Lost Pet Cache
  ROW(8950006),  -- Lost Beast Cache
  ROW(8950008)   -- Lost Curio Cache
) `c` (`item`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);
