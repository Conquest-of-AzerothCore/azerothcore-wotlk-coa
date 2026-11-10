-- ----------------------------------------------------------------------------
-- Darkmoon Harlequin's Bells (Soulbound): wire the set cache fixup it missed (#9444)
-- ----------------------------------------------------------------------------
-- Item 2977352 is an `ethereal_bazaar_set_cache` cache_item (06_ethereal_bazaar_set_caches.sql),
-- but its item_template row was created later, by rev_20260922_30_vanity_item_templates.sql, after
-- that one-shot base install already ran. It never got the same three fixups its sibling cache
-- items carry, so right-clicking it does nothing: no ScriptName, no use spell, and (moot here, but
-- matched for parity) no stray ITEM_FLAG_HAS_LOOT to clear.
UPDATE `item_template` SET `ScriptName` = 'item_ethereal_set_cache' WHERE `entry` = 2977352;
UPDATE `item_template` SET `spellid_1` = 60034, `spelltrigger_1` = 0, `spellcooldown_1` = 30000
 WHERE `entry` = 2977352 AND `spellid_1` = 0;
UPDATE `item_template` SET `Flags` = `Flags` & ~4 WHERE `entry` = 2977352 AND `Flags` & 4;
