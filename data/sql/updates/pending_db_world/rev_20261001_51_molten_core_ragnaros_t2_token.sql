-- Correction to rev_20261001_50_molten_core_tokens_per_boss.sql: that migration read the
-- export's absence of a boss-specific guaranteed-pool row for Ragnaros as meaning his
-- Chromatic Legguards (Tier 2 Leg token, 2522459 Normal/2622459 Heroic/2722459 Mythic/
-- 3722459 Ascended, tier ids corrected in rev_20261001_40) stays a plain 4% roll and removed
-- him from the guaranteed-token mechanism entirely. The player's own measured Ragnaros kills
-- override that reading: Chromatic Legguards drops every kill, not 4% of them. This migration
-- re-adds Ragnaros to the same guaranteed-token mechanism every other scheduled boss uses for
-- its own token (2 copies per kill below 20 players, 3 at 20+, via FlexLoot.cpp's existing
-- flex-size bonus roll) and removes the now-redundant separate 4% roll on the same item so a
-- single kill cannot drop Chromatic Legguards twice.
--
-- New single-item reference_loot_template pools (4090058-4090061, the next free MC-specific
-- ids after 4090011-4090057) hold the tier-matched Chromatic Legguards id for each
-- difficulty, mirroring the per-boss single-item pools rev_20261001_50 built for the other
-- eight bosses.

DELETE FROM `reference_loot_template` WHERE `Entry` IN (4090058, 4090059, 4090060, 4090061);
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(4090058, 2522459, 0, 0, 0, 1, 1, 1, 1, ''),
(4090059, 2622459, 0, 0, 0, 1, 1, 1, 1, ''),
(4090060, 2722459, 0, 0, 0, 1, 1, 1, 1, ''),
(4090061, 3722459, 0, 0, 0, 1, 1, 1, 1, '');

DELETE FROM `creature_loot_template` WHERE `Entry` IN (11502, 111502, 211502, 311502)
    AND `Item` IN (4090058, 4090059, 4090060, 4090061, 2522459, 2622459, 2722459, 3722459);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(11502, 4090058, 4090058, 100, 0, 1, 0, 2, 2, ''),
(111502, 4090059, 4090059, 100, 0, 1, 0, 2, 2, ''),
(211502, 4090060, 4090060, 100, 0, 1, 0, 2, 2, ''),
(311502, 4090061, 4090061, 100, 0, 1, 0, 2, 2, '');

DELETE FROM `coa_mc_token_loot` WHERE `creature_entry` IN (11502, 111502, 211502, 311502);
INSERT INTO `coa_mc_token_loot` (`creature_entry`, `reference_id`) VALUES
(11502, 4090058),
(111502, 4090059),
(211502, 4090060),
(311502, 4090061);
