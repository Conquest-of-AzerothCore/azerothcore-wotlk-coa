-- Audit triggered by `impl-T-flex-items.md`'s note that Magmadar's own 2% bonus row (311982)
-- looked tier-mismatched. Re-checked against item_template's own embedded tooltip tags (decoded
-- WDB captures: "@Heroic Raid@"/"@Mythic Raid@"/"@Ascended Raid@" prefixes), the only direct,
-- non-inferred evidence of which numeric id serves which difficulty for this item family -
-- corroborated by buy_price scaling strictly with difficulty (1.0M/1.5M/2.0M/2.5M) matching the
-- health-scaling order (hp_d0..d3 strictly increasing, Ascended highest, per docs/coa/molten-core.md).
-- That evidence shows docs/coa/molten-core.md's stated "25/26/27/37 = Normal/Heroic/Mythic/Ascended"
-- prefix convention is backwards for the last pair: for every Molten-<Slot>/Chromatic Legguards
-- token id, prefix 27 is the Ascended-tier item and prefix 37 is the Mythic-tier item.
--
-- Under the correct mapping, creature_loot_template's own direct 2-4% "boss token" row on every
-- Mythic/Ascended boss entry (e.g. 311982's 2722359) is already correct - Magmadar's flagged row
-- was not a bug. The real swap is in the guaranteed-pool `reference_loot_template` entries that
-- `coa_mc_token_loot`/FlexLoot.cpp's raid-size bonus roll actually reads (2-3 guaranteed pieces
-- per kill, the primary drop vector): rev_20261001_50 and rev_20261001_51 built the Mythic entry
-- of each pair with the 27-prefixed (Ascended) item and the Ascended entry with the 37-prefixed
-- (Mythic) item, for all 8 Tier-1 bosses and for Ragnaros's Tier-2 Chromatic Legguards. This
-- migration swaps the Item id of each Mythic/Ascended reference_loot_template pair back to the
-- tier it actually serves; Normal and Heroic entries are already correct and untouched.
--
-- coa_mc_item_pool and coa_mc_fire_lord_cache_pool were checked and hold none of these Molten/
-- Chromatic token item ids (they draw from the separate non-set-epic gear family using the
-- existing +200000/+300000/+1300000 additive scaling, confirmed correct) - no rebuild needed.

DELETE FROM `reference_loot_template` WHERE `Entry` IN
    (4090035, 4090036, 4090038, 4090039, 4090041, 4090042, 4090044, 4090045,
     4090047, 4090048, 4090050, 4090051, 4090053, 4090054, 4090056, 4090057,
     4090060, 4090061);
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
-- Magmadar (Molten Legguards)
(4090035, 3722359, 0, 0, 0, 1, 1, 1, 1, ''),
(4090036, 2722359, 0, 0, 0, 1, 1, 1, 1, ''),
-- Golemagg (Molten Tunic)
(4090038, 3722350, 0, 0, 0, 1, 1, 1, 1, ''),
(4090039, 2722350, 0, 0, 0, 1, 1, 1, 1, ''),
-- Baron Geddon (Molten Spaulders)
(4090041, 3722361, 0, 0, 0, 1, 1, 1, 1, ''),
(4090042, 2722361, 0, 0, 0, 1, 1, 1, 1, ''),
-- Garr (Molten Headpiece)
(4090044, 3722360, 0, 0, 0, 1, 1, 1, 1, ''),
(4090045, 2722360, 0, 0, 0, 1, 1, 1, 1, ''),
-- Sulfuron Harbinger (Molten Boots)
(4090047, 3722365, 0, 0, 0, 1, 1, 1, 1, ''),
(4090048, 2722365, 0, 0, 0, 1, 1, 1, 1, ''),
-- Lucifron (Molten Wristguards)
(4090050, 3722362, 0, 0, 0, 1, 1, 1, 1, ''),
(4090051, 2722362, 0, 0, 0, 1, 1, 1, 1, ''),
-- Gehennas (Molten Girdle)
(4090053, 3722363, 0, 0, 0, 1, 1, 1, 1, ''),
(4090054, 2722363, 0, 0, 0, 1, 1, 1, 1, ''),
-- Shazzrah (Molten Handguards)
(4090056, 3722364, 0, 0, 0, 1, 1, 1, 1, ''),
(4090057, 2722364, 0, 0, 0, 1, 1, 1, 1, ''),
-- Ragnaros (Chromatic Legguards, Tier 2)
(4090060, 3722459, 0, 0, 0, 1, 1, 1, 1, ''),
(4090061, 2722459, 0, 0, 0, 1, 1, 1, 1, '');
