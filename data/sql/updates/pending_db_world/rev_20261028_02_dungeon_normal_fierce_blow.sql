-- Fierce Blow (975011, SPELL_EFFECT_WEAPON_PERCENT_DAMAGE) is cast by many restored Ascension boss
-- kits (rev_20261001_10_boss_kits_scripted.sql and others) but is absent from
-- coa_dungeon_normal_spell_damage, so CoADungeonNormal::TunesSpell() never recognizes it: on Normal
-- it lands raw, with no Normal-rank reduction and no CoA.DungeonNormal.TargetHitCapPct cap, able to
-- one-shot a low-level party (#9297 Aku'mai/Blackfathom Deeps, #9344 Lord Serpentis/Wailing Caverns).
-- 975011 has no own low-level rank with a matching effect structure (975010 "Fierce Blow" is a plain
-- SPELL_EFFECT_WEAPON_DAMAGE rank, not comparable), so this follows the same table's existing pattern
-- for spells without one (normal_spell_id = 0, high = Heroic damage / 1.66 * 0.85, e.g. 15232 Shadow
-- Bolt, 22689 Mangle, 391369 Rend): CoADungeonNormal::Factor() returns `high` unconditionally when
-- normal_spell_id is 0, then the existing single-target 40% max-health cap (TargetCapPct) applies.

DELETE FROM `coa_dungeon_normal_spell_damage` WHERE `spell_id` = 975011;
INSERT INTO `coa_dungeon_normal_spell_damage` (`spell_id`, `normal_spell_id`, `high`, `comment`) VALUES
(975011, 0, 0.512, 'Fierce Blow: Heroic / 1.66 * 0.85, matches Normal dungeon kit softening (#9297, #9344)');
