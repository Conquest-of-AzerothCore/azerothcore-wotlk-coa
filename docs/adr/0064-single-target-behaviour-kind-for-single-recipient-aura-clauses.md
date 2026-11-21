# 0064. A `single_target` behaviour kind for "only 1 target at a time" clauses

- Status: accepted
- Date: 2026-11-10

## Context

`round10/workstreams/oath-stacks-exclusivity.md` lists Righteous Custodian (572808), whose tooltip reads
"Can only be placed on 1 target at a time." No existing behaviour kind measures a single-target aura's own
replacement across two different recipients: `exclusivity` proves that casting a *different* spell removes
another spell's aura on the *same* caster, not that recasting the *same* spell on a *different* target removes
it from the first. `Spell.dbc`'s `AttributesEx5` for 572808 is `0x20` (`SPELL_ATTR5_LIMIT_N`, "Single-target
aura: remove previous application to another unit if applied", confirmed against `SharedDefines.h:647`), and
`SpellInfo::IsSingleTarget`/`Unit::_AddAura`'s single-cast-aura bookkeeping (`Unit.cpp:5440-5456`, `6072-6089`)
already enforces exactly this for any spell carrying that flag; `grep` of `src/server/coa/` for 572808 finds
only its class-list registration and this harness's own prior entries, confirming no CoA script implements or
overrides the mechanism. The gap is purely in the harness's measurement vocabulary, matching the audit-gap shape
ADR 0051 already documented for the Libram exclusivity clauses.

## Considered options

1. Extend `exclusivity`'s `chain` field to allow a chain of length 1 cast at two different targets. Rejected:
   `exclusivity_chain_scenario` casts every chain member at the caster itself and measures the caster's own aura
   set; reusing it for a cross-target check would overload its one existing, already-tested cast/measure shape
   with a second, incompatible meaning (same spell, different targets, rather than different spells, same
   caster), for one clause.
2. A dedicated `single_target` behaviour kind: cast the spell on a first grouped ally, read that ally's own aura
   (expected present), cast it again on a second grouped ally, then read both allies' auras (first expected
   removed, second expected present). Chosen.

## Decision

Added `BEHAVIOUR_SINGLE_TARGET` / kind `'single_target'` to `behaviours.py`, with `SingleTargetSpec` (`spell`,
`name`, `quote`, `wait_ms`) and `single_target_scenario`/`single_target_spec` following the existing
`aura_grant`/`exclusivity` spec-and-scenario-builder pair. The scenario fixtures the caster plus two additional
grouped players (`ally`, `ally2`; `Unit::IsInRaidWith` requires either the same unit or the same group, so the
harness's existing `group` action step joins both allies to the caster's fixture group to satisfy 572808's own
`TARGET_UNIT_TARGET_RAID` cast-target check), casts the spell at the first ally, measures that ally's own aura
(expected 1), casts the spell again at the second ally, then measures the first ally's aura again (expected 0,
removed) and the second ally's aura (expected 1, newly applied). `compare.py` gained
`behaviour_single_target_verdict`: `ok` only when all three readings match their expected value; any other
combination is always an `alert`.

`classes/templar.json` carries one `single_target` entry for 572808, citing the DBC attribute and the stock
engine functions that enforce it, with no CoA script change.

## Consequences

Any future "only 1 target at a time"/single-cast-aura clause (for any class, any spell carrying
`SPELL_ATTR5_LIMIT_N` or an equivalent engine-enforced single-target rule) can reuse the same kind by listing a
`single_target` entry in its own class file, with no tool code change. The kind proves only that the *first*
recipient's aura is replaced by a *second* cast at a different target; it does not prove the DBC attribute is
itself the only mechanism (already established by code reading, not a gameplay measurement) or exercise more
than two recipients, which the engine's own single-cast-aura list handles identically regardless of count.
