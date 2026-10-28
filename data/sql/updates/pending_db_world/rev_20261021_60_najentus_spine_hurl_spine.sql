-- Naj'entus Spine (32408) came with no on-use spell, so it could never hurl Hurl Spine (39948) and break High Warlord
-- Naj'entus' Tidal Shield (spell_najentus_hurl_spine). Restore the stock on-use spell and the 5-spine stack that
-- spell_najentus_remove_spines clears.
UPDATE `item_template` SET `spellid_1` = 39948, `spelltrigger_1` = 0, `spellcharges_1` = -1, `maxcount` = 5, `stackable` = 5
WHERE `entry` = 32408 AND `spellid_1` = 0;
