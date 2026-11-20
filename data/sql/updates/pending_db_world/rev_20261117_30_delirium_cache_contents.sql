-- Delirium Cache (421527), the reward of the Nightmare - Duo Delirium trials 613 and 614, used spell 60034 with no
-- ScriptName and no contents, so opening it only started its cooldown (#12515). It holds the Tailored Purple Tabard,
-- the Wanderer's Plum Scarf and the Wanderer's Plum Cloak, given at once like the other set caches. The name also
-- loses its "Delerium" misspelling. A reapply leaves the result unchanged.
UPDATE `item_template` SET `name` = 'Delirium Cache', `ScriptName` = 'item_ethereal_set_cache' WHERE `entry` = 421527;
UPDATE `item_template` SET `Flags` = `Flags` & ~4 WHERE `entry` = 421527 AND `Flags` & 4;

DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 421527;
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`) VALUES
(421527, 460464, 0, 1),  -- Tailored Purple Tabard
(421527, 509167, 1, 1),  -- Wanderer's Plum Scarf
(421527, 509168, 2, 1);  -- Wanderer's Plum Cloak
