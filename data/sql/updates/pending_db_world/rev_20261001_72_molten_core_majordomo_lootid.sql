-- Majordomo Executus (12018) carries lootid = 0 on every difficulty: Unit::Kill's
-- "if (uint32 lootid = creature->GetCreatureTemplate()->lootid) loot->FillLoot(...)" skips him
-- entirely on death, so FlexItems.cpp's MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS hook (added by
-- rev_20261001_70, meant to give him a random-item roll from the common pool, §7.3) never fires -
-- confirmed live: a GM kill never opens a loot window for him at all. This is unrelated to §7.2's
-- Cache of the Firelord gameobject (his real, intended loot source, still untouched) and to §7.1's
-- guaranteed-token mechanism (he was never part of it). Self-referencing lootid is this core's
-- standard idiom for "this creature has a (possibly empty) creature_loot_template row".
--
-- A non-zero lootid alone is not enough: Loot::FillLoot looks the id up via
-- LootStore::GetLootFor(lootId), which only returns a LootTemplate for ids LootMgr actually loaded
-- from creature_loot_template - with none, FillLoot bails out before ever calling
-- LootTemplate::Process or ScriptMgr::OnAfterLootTemplateProcess, so the hook still never fires.
-- confirmed live (second round): the lootid alone did not open a loot window either. A
-- Chance = 0, GroupId = 0 row does not work either: LootMgr's loader treats Chance 0 on an
-- ungrouped row as its "equal-chance within group" marker, which requires a real group id, so it
-- logs "equal-chanced grouped entry, but group not defined - skipped" and still creates no
-- LootTemplate at all (this is also why the pre-existing Stoneclad Libram/Tome of Burning Passion
-- Normal rows, §7, never drop anything - same skip, not a true "never rolls" row). A small but
-- non-zero chance avoids that code path while staying statistically irrelevant. Rune of
-- Descension (375250) is reused rather than inventing a new filler item, since it is already a
-- guaranteed row on every other scheduled boss's own table; 0.01% here is for engine bookkeeping
-- only, not a real intended drop.
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (12018, 112018, 212018, 312018);

DELETE FROM `creature_loot_template` WHERE `Entry` IN (12018, 112018, 212018, 312018) AND `Item` = 375250;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(12018, 375250, 0, 0.01, 0, 1, 0, 1, 1, ''),
(112018, 375250, 0, 0.01, 0, 1, 0, 1, 1, ''),
(212018, 375250, 0, 0.01, 0, 1, 0, 1, 1, ''),
(312018, 375250, 0, 0.01, 0, 1, 0, 1, 1, '');
