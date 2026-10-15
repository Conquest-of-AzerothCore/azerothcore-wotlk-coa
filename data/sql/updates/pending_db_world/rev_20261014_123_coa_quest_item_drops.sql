-- Quest items that nothing dropped, now dropped by the mobs the quests name ("Defeat Warlock Ketheric... obtain his Oath
-- Ring", "Collect yak meat", "Obtain a Scadeald Fox heart", "bear teeth from the bears of Oldmist Forest"...). Bulk
-- collections (boar and goat meat, bear teeth) drop several at a time; the druids' orders start their quest.
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (164249, 164424, 164944) AND `lootid` = 0;
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((164066, 559881), (164267, 559926), (164033, 559888), (164081, 559888), (164078, 559890), (164249, 559897), (164424, 559932), (164441, 559928), (164474, 559935), (164083, 560337), (164039, 560338), (164944, 560339), (164061, 560344), (164073, 560344), (164087, 560347), (164091, 560347), (164557, 560354));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164066, 559881, 0, 100, 1, 1, 0, 1, 1, 'Emissary Agramor - Agramor''s Head (War''s True Ambition)'),
(164267, 559926, 0, 100, 1, 1, 0, 1, 1, 'Blackrock Champion Kurgan - Blackrock Battle Plans (Kerebor''s Glue)'),
(164033, 559888, 0, 30, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Handwritten Orders of the Druids (Three Sisters Cry)'),
(164081, 559888, 0, 30, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Handwritten Orders of the Druids (Three Sisters Cry)'),
(164078, 559890, 0, 100, 1, 1, 0, 3, 6, 'Daumor Boar - Daumor Boar Meat (Gryphon Appetizer)'),
(164249, 559897, 0, 60, 1, 1, 0, 1, 1, 'Tilted Yak - Yak Meat (Yak Hunt)'),
(164424, 559932, 0, 100, 1, 1, 0, 2, 4, 'Ealdfrost Goat - Ealdfrost Goat Meat (A Hundred Mouths To Feed)'),
(164441, 559928, 0, 100, 1, 1, 0, 1, 1, 'Frostmane Taskmaster Migbala - Migbala''s Head (Hold the Head High)'),
(164474, 559935, 0, 100, 1, 1, 0, 1, 1, 'Warlock Ketheric - Ketheric''s Oath Ring (Ketheric, the Cruel)'),
(164083, 560337, 0, 50, 1, 1, 0, 1, 1, 'Scadeald Fox - Fox Heart (Change of Heart)'),
(164039, 560338, 0, 100, 1, 1, 0, 1, 3, 'Scadeald Bear - Bear Teeth (A Tooth for a Song)'),
(164944, 560339, 0, 50, 1, 1, 0, 1, 1, 'Possessed Crow - Possessed Crow Eye (Blinding the Black Rook)'),
(164061, 560344, 0, 50, 1, 1, 0, 1, 1, 'Frostmane Ambusher - Enchanted Trinket (Enchanted Trinkets)'),
(164073, 560344, 0, 50, 1, 1, 0, 1, 1, 'Frostmane Ambusher - Enchanted Trinket (Enchanted Trinkets)'),
(164087, 560347, 0, 60, 1, 1, 0, 1, 1, 'Scadeald Stag - Venison (The Price of Welcome)'),
(164091, 560347, 0, 60, 1, 1, 0, 1, 1, 'Scadeald Doe - Venison (The Price of Welcome)'),
(164557, 560354, 0, 50, 1, 1, 0, 1, 1, 'Blackrock Worg - Black Warg Pelt (A Rug, Most Likely)');
