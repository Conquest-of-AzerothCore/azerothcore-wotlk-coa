-- "Mutant Murloc Quill": the Murloc Spike that starts it drops from the Quillscale murlocs of the Fading Shore.
-- "Fire's Unwitting Bounty": the Guild's enslaved elementals (Bound Fire Elemental) drop Elemental Embers on the quest.
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` = 164470 AND `lootid` = 0;
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((164429, 559920), (164430, 559920), (164470, 559958));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164429, 559920, 0, 8, 0, 1, 0, 1, 1, 'Quillscale Murloc - Murloc Spike (starts Mutant Murloc Quill)'),
(164430, 559920, 0, 8, 0, 1, 0, 1, 1, 'Whimsical Quillscale Murloc - Murloc Spike (starts Mutant Murloc Quill)'),
(164470, 559958, 0, 60, 1, 1, 0, 1, 1, 'Bound Fire Elemental - Elemental Ember (Fire''s Unwitting Bounty)');
