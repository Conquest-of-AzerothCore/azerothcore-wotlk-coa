-- CoA class buffs from different classes that grant the same statistic stacked on one target: Aura::CanStackWith
-- lets auras of different SpellFamilyName coexist unless a spell_group joins them, and every existing group was
-- limited to one class. Ascension combat logs from 2026-05 to 2026-08 show the newest buff of a
-- category replacing the previous one whoever cast it, even when it is weaker (8/11 18:05:36.867: Man'ari
-- Intuition 523482 replaced Greater Beetle Pheromones 803657), so each category is one group with
-- SPELL_GROUP_STACK_RULE_EXCLUSIVE (1). Greater Man'ari Intuition 523495 is left out: the same logs keep it next to
-- Greater Beetle Pheromones and Greater Footpad's Adaptation.
--
-- SpellMgr::CheckSpellGroupStackRules uses the first ruled group in id order, so these ids sort above every
-- existing class group and leave the rules within a class (1039-1210, 103955, 2100001-2106088) unchanged.
-- Rows hold the first rank of each spell_ranks chain plus the higher ranks that have no chain.
DELETE FROM `spell_group` WHERE `id` BETWEEN 2110001 AND 2110006;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
-- Agility: Brutal Shout, Inquisitor's Edict, Spider Pheromones, Illidari Intuition
(2110001, 300857),
(2110001, 300887),
(2110001, 706741),
(2110001, 707678),
(2110001, 680303),
(2110001, 803177),
(2110001, 680312),
(2110001, 800212),
(2110001, 501330),
(2110001, 501331),
(2110001, 501332),
(2110001, 501333),
(2110001, 680308),
-- Stamina: Enduring Shout, Foul Mandate, Mark of Rivendare, Rite of Resolve, Sanguinary Offering
(2110002, 680302),
(2110002, 800199),
(2110002, 680286),
(2110002, 803667),
(2110002, 803730),
(2110002, 800198),
(2110002, 680298),
(2110002, 706630),
(2110002, 707340),
(2110002, 680299),
-- Attack power: Devotion of Dawn, Power Module, Power Wuju, Primal Instinct, Woodsman's Adaptation
(2110003, 572384),
(2110003, 572390),
(2110003, 706742),
(2110003, 680315),
(2110003, 707671),
(2110003, 707677),
(2110003, 712458),
(2110003, 800197),
(2110003, 680310),
(2110003, 800266),
(2110003, 680294),
-- Armor and all attributes: Beetle Pheromones, Footpad's Adaptation, Knight's Edict, Man'ari Intuition,
-- Earthen Endurance
(2110004, 803651),
(2110004, 803656),
(2110004, 803657),
(2110004, 523489),
(2110004, 523494),
(2110004, 523513),
(2110004, 523485),
(2110004, 523510),
(2110004, 523478),
(2110004, 523484),
(2110004, 570752),
(2110004, 570756),
-- Spirit: Chromie's Wisdom, Spirit Wuju, Bloodsoaked Offering
(2110005, 801523),
(2110005, 802830),
(2110005, 802831),
(2110005, 802832),
(2110005, 802833),
(2110005, 802834),
(2110005, 680307),
(2110005, 560294),
(2110005, 561143),
(2110005, 680872),
(2110005, 572400),
(2110005, 572404),
-- All attributes percent: Whispers of N'Zoth, Etching of the Leylines
(2110006, 561386),
(2110006, 561387),
(2110006, 561236),
(2110006, 561242);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` BETWEEN 2110001 AND 2110006;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110001, 1, 'CoA class buffs: agility'),
(2110002, 1, 'CoA class buffs: stamina'),
(2110003, 1, 'CoA class buffs: attack power'),
(2110004, 1, 'CoA class buffs: armor and all attributes'),
(2110005, 1, 'CoA class buffs: spirit'),
(2110006, 1, 'CoA class buffs: all attributes percent');
