-- The Callboard Caches and the generic Prestigious Caches are opened by their own item
-- scripts, and an item script only runs when the item's template names it: without these
-- bindings `item_ascension_callboard_cache` is registered at startup and never called, and
-- every Callboard Cache keeps doing nothing at all.
--
-- The generic Prestigious Caches (1287330 "grants the most recent Prestigious Cache
-- available", plus the later-era 1297304 and 1297305) share the handler with the named
-- caches, which is what resolves them to a released tier.

UPDATE `item_template` SET `ScriptName` = 'item_ascension_callboard_cache'
WHERE `entry` IN (978050, 1378050, 1478050, 1615000, 1615001, 1615002, 1615003, 1615004,
                  1615005, 1615006, 1615007, 1615008, 1615009);

UPDATE `item_template` SET `ScriptName` = 'item_ascension_prestigious_cache'
WHERE `entry` IN (1287330, 1297304, 1297305);
