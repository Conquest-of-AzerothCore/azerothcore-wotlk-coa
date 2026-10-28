-- K1: knockback/pull immunity (flags_extra 0x40000000) on every Molten Core (map 409) creature,
-- base and difficulty variant, plus the summon-only entries that have no static map-409 spawn row
-- (Shadow of Lucifron, the Son of Flame merge chain, Sacrificial Chains, Flame of Ragnaros,
-- Reflection of Shazzrah, Magmadar's heads, Sulfuron's disciples, Core Hounds).
-- Late-sorting on purpose (see docs/coa/molten-core.md SQL-ordering note): earlier pending files
-- that already set this flag on a subset of these entries (rev_20260930_93/_95,
-- rev_20261001_04/_05) get re-applied on a fresh slot and must not leave any entry below this one
-- unset. This file is idempotent (`|=` on a flag already set is a no-op) and is the final word on
-- this flag for every Molten Core entry. Base ids below are every distinct `creature.id % 100000`
-- spawned on `map = 409` in this repo's own data (base + pending), plus the summon-only ids that
-- have no static spawn row to derive from.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000
WHERE `entry` % 100000 IN (
    11658,11659,11661,11662,11665,11666,11667,11668,11669,11671,11672,11673,
    11982,11988,12056,12057,12076,12098,12099,12100,12101,12118,12119,12259,12264,
    12268,12143,92026,92027,92028,92030,13148,11504,80642,80643,92031,92032,92033
);
