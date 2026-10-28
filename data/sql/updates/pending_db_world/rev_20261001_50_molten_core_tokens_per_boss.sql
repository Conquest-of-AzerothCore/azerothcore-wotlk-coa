-- Correction to rev_20261001_40_molten_core_real_tier_tokens.sql: that migration repointed
-- reference_loot_template 4090012-4090057 (the guaranteed Tier 1/2 token pool FlexLoot.cpp
-- reads through coa_mc_token_loot) at the full 8-item "Molten <Slot>" set for every one of the
-- nine scheduled bosses, so any boss's guaranteed pick could resolve to any of the 8 slots
-- (e.g. Lucifron's guaranteed pick landing on Molten Boots). The exiles-db export's own
-- creature_loot_template rows show each boss already carries exactly one boss-specific
-- "Molten <Slot>" (or, for Ragnaros, "Chromatic <Slot>") row, matching Classic Molten Core's
-- own one-slot-per-boss token design:
--   Lucifron -> Molten Wristguards, Magmadar -> Molten Legguards, Gehennas -> Molten Girdle,
--   Garr -> Molten Headpiece, Shazzrah -> Molten Handguards, Baron Geddon -> Molten Spaulders,
--   Sulfuron Harbinger -> Molten Boots, Golemagg -> Molten Tunic (all at the export's own 2-4%
--   bonus chance, group-exclusive with that boss's other rare rolls - left unchanged here),
--   Ragnaros -> Chromatic Legguards (Tier 2, 4%, also left unchanged).
-- This migration repoints each of those 32 reference_loot_template entries (8 bosses x 4
-- difficulties) at that boss's own single tier-matched item instead of the shared 8-item set,
-- so the guaranteed 2 (3 at 20+ players, FlexLoot.cpp) pool picks resolve to 2-3 copies of the
-- boss's own token, per the maintainer's "if a boss has exactly one specific token, the count
-- means copies of that token" direction.
--
-- Ragnaros has no boss-specific row in this guaranteed-pool family anywhere in the export: his
-- only Molten-Core-token row is the existing low-chance (4%) Chromatic Legguards group, which
-- is not part of the guaranteed-pool mechanism on any other boss either (every boss's own
-- export token row sits in its own low-chance group, separate from the guaranteed pick). Giving
-- him a guaranteed 2-3 extra Chromatic Legguards per kill on top of that existing roll would be
-- inventing a drop count the export does not support, so this migration removes Ragnaros from
-- the guaranteed-pool mechanism entirely: his reference_loot_template entries (4090030-4090033),
-- the matching creature_loot_template guarantee row on each difficulty and his coa_mc_token_loot
-- rows are deleted outright. His 4% Chromatic Legguards row is untouched.
--
-- Majordomo Executus was already outside the nine scheduled bosses' guaranteed-pool mechanism
-- (he was never added to coa_mc_token_loot) and stays that way: his own "loot" is the Cache of
-- the Firelord gameobject (179703, instance_molten_core.cpp's SetBossState hook), whose export
-- gameobject_loot row (16719) and its Heroic/Mythic/Ascended counterparts (279703/379703/
-- 479703) carry no Molten/Chromatic token data at all on any difficulty - only stock classic
-- quest/trash loot (Limb Cleaver, Eye of Divinity, Ancient Petrified Leaf). This matches
-- Classic's own design (Majordomo does not drop tier loot himself when spared for the Ragnaros
-- fight); no token content is added here for lack of evidence.

DELETE FROM `reference_loot_template` WHERE `Entry` IN
    (4090012, 4090013, 4090014, 4090015, 4090026, 4090027, 4090028, 4090029,
     4090034, 4090035, 4090036, 4090037, 4090038, 4090039, 4090040, 4090041,
     4090042, 4090043, 4090044, 4090045, 4090046, 4090047, 4090048, 4090049,
     4090050, 4090051, 4090052, 4090053, 4090054, 4090055, 4090056, 4090057,
     4090030, 4090031, 4090032, 4090033);
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(4090012, 2522362, 0, 0, 0, 1, 1, 1, 1, ''),
(4090049, 2622362, 0, 0, 0, 1, 1, 1, 1, ''),
(4090050, 2722362, 0, 0, 0, 1, 1, 1, 1, ''),
(4090051, 3722362, 0, 0, 0, 1, 1, 1, 1, ''),
(4090013, 2522359, 0, 0, 0, 1, 1, 1, 1, ''),
(4090034, 2622359, 0, 0, 0, 1, 1, 1, 1, ''),
(4090035, 2722359, 0, 0, 0, 1, 1, 1, 1, ''),
(4090036, 3722359, 0, 0, 0, 1, 1, 1, 1, ''),
(4090014, 2522363, 0, 0, 0, 1, 1, 1, 1, ''),
(4090052, 2622363, 0, 0, 0, 1, 1, 1, 1, ''),
(4090053, 2722363, 0, 0, 0, 1, 1, 1, 1, ''),
(4090054, 3722363, 0, 0, 0, 1, 1, 1, 1, ''),
(4090015, 2522360, 0, 0, 0, 1, 1, 1, 1, ''),
(4090043, 2622360, 0, 0, 0, 1, 1, 1, 1, ''),
(4090044, 2722360, 0, 0, 0, 1, 1, 1, 1, ''),
(4090045, 3722360, 0, 0, 0, 1, 1, 1, 1, ''),
(4090026, 2522364, 0, 0, 0, 1, 1, 1, 1, ''),
(4090055, 2622364, 0, 0, 0, 1, 1, 1, 1, ''),
(4090056, 2722364, 0, 0, 0, 1, 1, 1, 1, ''),
(4090057, 3722364, 0, 0, 0, 1, 1, 1, 1, ''),
(4090027, 2522361, 0, 0, 0, 1, 1, 1, 1, ''),
(4090040, 2622361, 0, 0, 0, 1, 1, 1, 1, ''),
(4090041, 2722361, 0, 0, 0, 1, 1, 1, 1, ''),
(4090042, 3722361, 0, 0, 0, 1, 1, 1, 1, ''),
(4090029, 2522365, 0, 0, 0, 1, 1, 1, 1, ''),
(4090046, 2622365, 0, 0, 0, 1, 1, 1, 1, ''),
(4090047, 2722365, 0, 0, 0, 1, 1, 1, 1, ''),
(4090048, 3722365, 0, 0, 0, 1, 1, 1, 1, ''),
(4090028, 2522350, 0, 0, 0, 1, 1, 1, 1, ''),
(4090037, 2622350, 0, 0, 0, 1, 1, 1, 1, ''),
(4090038, 2722350, 0, 0, 0, 1, 1, 1, 1, ''),
(4090039, 3722350, 0, 0, 0, 1, 1, 1, 1, '');

DELETE FROM `creature_loot_template` WHERE `entry` IN (11502, 111502, 211502, 311502)
    AND `Item` IN (4090030, 4090031, 4090032, 4090033);

DELETE FROM `coa_mc_token_loot` WHERE `creature_entry` IN (11502, 111502, 211502, 311502);
