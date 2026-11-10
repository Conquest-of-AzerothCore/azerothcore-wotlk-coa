# 0061. An `exclusivity` behaviour kind for mutual-exclusion chains

- Status: accepted
- Date: 2026-11-09

## Context

`round10/workstreams/oath-stacks-exclusivity.md` lists five Templar Libram spells (801441/803893 Libram of
Consecration, 801461 Libram of Tenacity, 801463 Libram of Grace, 801466 Libram of Zeal, 805423 Libram of
Fervor), each carrying the identical ext-note clause "Only 1 Libram spell can be active at a time.". No
existing behaviour kind measures a mutual-exclusion group: `duration_refresh` and `amount_delta` both compare
a single target aura's own magnitude/duration across a without/with-passive pair, not whether casting one
spell removes another spell's aura. `data/sql/updates/pending_db_world/rev_20260907_02_exclusive_self_buffs.sql`
confirms this is pure stock-engine behaviour (`spell_group` 1128, `stack_rule` 2), not CoA-specific code, so the
gap is purely in the harness's measurement vocabulary.

## Considered options

1. Model each of the five clauses as a separate two-cast scenario (cast A, then B, assert A's aura is gone).
   Rejected: five near-identical scenarios/entries for one mechanism, and each only proves one directional pair
   rather than the whole group.
2. A single `exclusivity` behaviour kind taking an ordered `chain` of spell ids, casting each member in turn and
   wrapping back to the first member, asserting after every cast that the just-cast member's own aura is present
   (1) and the previous member's aura is gone (0). One scenario, one class-file entry, N expectations for an
   N-member chain, each one proving one member's "removed by the next" half of the clause and the wrap-around
   proving the last member's clause too. Chosen.

## Decision

Added `BEHAVIOUR_EXCLUSIVITY` / kind `'exclusivity'` to `behaviours.py`, with `ExclusivityChainSpec` (`spell`,
`name`, `quote`, `chain: tuple[int, ...]`, `wait_ms`) and `exclusivity_chain_scenario`/`exclusivity_chain_spec`
following the existing `duration_refresh`/`amount_delta` spec-and-scenario-builder pair. The scenario casts each
chain member in sequence (reusing `required_aura_steps`/mana-cost fixtures per cast, resetting each member's own
cooldown immediately before its cast), appending `sequence[0]` to close the loop, and measures the `aura` metric
(boolean presence) on both the newly cast member and the member it should have replaced. `compare.py` gained
`behaviour_exclusivity_verdict`: `ok` only when the previous member's aura reads 0 and the new member's reads 1;
any other combination (both present, or the new one absent) is always an `alert`, since the clause requires
exactly one member active at a time.

`classes/templar.json` carries one `exclusivity` entry (`chain: [801441, 801461, 801463, 801466, 805423]`)
covering all five Libram clauses: the five pairwise labels prove, respectively, that casting Tenacity removes
Consecration, Grace removes Tenacity, Zeal removes Grace, Fervor removes Zeal, and (the wrap-around) Consecration
removes Fervor.

## Consequences

Any future mutual-exclusion clause (a different `spell_group` chain, for any class) can reuse the same kind by
listing its own `chain` in a class file, with no tool code change. The kind only proves pairwise replacement
around the chain as built; it does not prove that two *non-adjacent* members can coexist (not a real possibility
once every member shares one `stack_rule: 2` group, which the SQL source already establishes) or that a member
re-grants itself without being replaced (already covered by each existing Libram's own `aura_duration_ms`/
`effect_value` entries).
