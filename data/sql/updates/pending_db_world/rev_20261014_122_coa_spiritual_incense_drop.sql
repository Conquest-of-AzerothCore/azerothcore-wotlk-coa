-- "A Near-Forgotten Altar" needs 4 Spiritual Incense "from the trolls at the Frostmane camp on the Winter's Path", but
-- nothing dropped it: the Frostmane Soldiers and the Frostmane Mystic of that camp now drop it while the quest is taken.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (164447, 164567) AND `Item` = 559929;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164447, 559929, 0, 40, 1, 1, 0, 1, 1, 'Frostmane Soldier - Spiritual Incense'),
(164567, 559929, 0, 40, 1, 1, 0, 1, 1, 'Frostmane Mystic - Spiritual Incense');
