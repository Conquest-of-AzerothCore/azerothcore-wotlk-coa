-- Ferocitas the Dream Eater (7234) never drops quest 2459's own objective item, Tallonkai's Jewel (8050);
-- quest_template row 2459 requires RequiredItemId3 = 8050, RequiredItemCount3 = 1, but the base
-- creature_loot_template.sql only ever gave entry 7234 the Gnarlpine Necklace (8049, QuestRequired, 100%
-- chance) and never a row for 8050 (git log -S over data/sql finds no commit adding or removing it for this
-- entry), so quest 2459 could never be completed from this loot. Restored at the same 100% quest-required
-- chance as the necklace, the neighbouring quest drop on the same creature (#5260).
DELETE FROM `creature_loot_template` WHERE `Entry` = 7234 AND `Item` = 8050;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(7234, 8050, 0, 100, 1, 1, 0, 1, 1, 'Ferocitas the Dream Eater - Tallonkai\'s Jewel (quest 2459 objective)');
