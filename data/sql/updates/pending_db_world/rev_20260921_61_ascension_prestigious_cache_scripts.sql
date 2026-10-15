-- A Prestigious Cache is opened by its own item script, and an item script only runs when the
-- item's template names it: without this binding `item_ascension_prestigious_cache` is registered
-- at startup and never called, and every named Prestigious Cache keeps doing nothing but its dummy
-- trigger spell. The caches share the one server-side container trigger (93461) and take their
-- rewards from `ascension_prestigious_cache_reward`.
--
-- The generic caches are bound by `rev_20260922_04_ascension_callboard_cache_scripts.sql`, which is
-- where the handler that resolves them to a released tier lives.
--
-- The Rune of Ascension Pouch binding already exists in
-- `rev_20260921_22_ascension_rune_pouch_scripts.sql` and is not repeated here.

UPDATE `item_template` SET `ScriptName` = 'item_ascension_prestigious_cache'
WHERE `entry` IN (1287304, 1287305, 1287306, 1287307, 1287308, 1287309, 1287310, 1287311,
                  1297310, 1297311, 1297312, 1297313, 1297314, 1297315, 1297316, 1297317, 1297318);
