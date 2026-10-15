-- The Rune of Ascension pouches are opened by their own item script, and an item script only runs
-- when the item's template names it: without this binding `item_ascension_rune_pouch` is registered
-- at startup and never called, and a pouch keeps doing nothing but its dummy trigger spell.
--
-- Every pouch shares the one dummy on-use spell (18282), so the amount each one pays lives in the
-- handler's own table. The items carry ITEM_FLAG_HAS_LOOT, so the click arrives as CMSG_OPEN_ITEM
-- and the handler answers that, as well as the plain use of any future row without the flag.

UPDATE `item_template` SET `ScriptName` = 'item_ascension_rune_pouch'
WHERE `entry` IN (509872, 509873, 509874, 509875, 509876, 509886, 509893, 509894, 509895,
                  509896, 509897, 518448, 518449, 518450, 800902, 2509893);
