-- The Ethereal Tool Dispenser (8263501-8263504) and the crate it arrives in (8263511).
--
-- The crate carried no script and only the inert spell 60034, so right-clicking it did nothing and
-- never consumed it (#6627, #6362, #6105, #5512); the Dispenser the crate is meant to pay out had
-- no source anywhere in the world either.
--
-- The crate is a cache holding exactly one thing, so the module's generic cache script serves it:
-- 'item_ethereal_lost_cache' reads ethereal_bazaar_cache_pool and hands out the only row it finds.
-- The two rows below are the ones 05_ethereal_bazaar_caches.sql does not know about - that file
-- replaces the whole pool, and it is a base file, so it has already run by the time an update does.
--
-- The four Dispensers share the on-use spell 8263501, "Upgrade your Dispenser!". The module's item
-- script reads it: using one takes up the trade of the highest Runed Rod the player carries and
-- replaces the item with the variant whose TotemCategory mask covers that rod
-- (modules/mod-ethereal-bazaar/src/EtherealBazaarDispenser.cpp).
--
-- Only ScriptName is set on these rows. The rows themselves, including the TotemCategory that makes
-- the item work at all, stay Ascension's.

UPDATE `item_template`
   SET `ScriptName` = 'item_ethereal_lost_cache'
 WHERE `entry` IN (8263510, 8263511);

UPDATE `item_template`
   SET `ScriptName` = 'item_ethereal_tool_dispenser'
 WHERE `entry` IN (8263501, 8263502, 8263503, 8263504);

DELETE FROM `ethereal_bazaar_cache_pool`
 WHERE `cache_item` IN (8263510, 8263511);

INSERT INTO `ethereal_bazaar_cache_pool` (`cache_item`, `reward_item`) VALUES
(8263510, 8263501),
(8263511, 8263501);
