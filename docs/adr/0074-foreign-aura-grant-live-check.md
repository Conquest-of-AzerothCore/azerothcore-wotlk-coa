# 0074. Live aura-presence check for a data-listed foreign-duration grant

- Status: accepted
- Date: 2026-11-10

## Context

A tooltip clause of the shape "Applies X for `$<spell>d`." or "...@s:<spell>:0@" is already read by
`foreign_duration` and measured with `spell_duration_ms` on the caster: this proves the DBC-computed
`SpellDuration` of the named aura matches the tooltip token, but never that casting the rank actually grants
that aura to anyone. Testament of Resolve (804228), Testament of Hope (1397742) and Tome of Light (805422) all
carry this gap for their own "Applies Sacred Restraint"/"grants an additional effect" clauses; round9's verdicts
judged only the computed duration as `ok`, with no live check behind it. For 804228 the grant is a DBC
`SPELL_EFFECT_TRIGGER_SPELL` effect that targets `TARGET_UNIT_TARGET_ALLY`; for 1397742 and 805422 it is a
scripted cast in `AscensionTemplarAbilities.cpp`/`AscensionTemplarAuras.cpp` with no DBC trace at all, so only a
live cast can prove either.

`foreign_duration` fires for roughly fifty (rank, foreign spell) pairs across the class, most of them unrelated
to this item and owned by other round-10 workstreams; a blanket "always add a live check" change would alert or
pass on spells no one has investigated yet and risks silently moving an already-`ok` clause's measured actor
(see the 804228 own-duration clause below).

## Considered options

1. Always add the live check wherever `foreign_duration` matches. Rejected: changes the scenario of every
   spell carrying this token pattern in one step, far outside this item's three spells, and several of those
   spells target a hostile or ally unit for reasons unrelated to the foreign-duration token, so a blanket
   `targets_ally` cast-target override risks moving what an already-judged clause measures.
2. Make the existing cast step itself target the ally whenever the rank's effects target `TARGET_UNIT_TARGET_ALLY`
   (`targets_ally`). Tried and reverted: 804228's own aura (effect 0/2, also target A `TARGET_UNIT_TARGET_ALLY`)
   is read on the caster by an existing, already-`ok` `aura_duration_ms #0` expectation; redirecting the one
   shared cast to the ally would move that effect onto the ally too and silently regress a clause this item does
   not own.
3. A class-file-listed allow-list (`foreign_aura_grants`: `{spell, target}` pairs, with a `reason` citing the DBC
   effect or the script) gates the new check per pair, and a second, independent cast-reset-cast sequence proves
   the ally case without touching the first cast or its existing expectations. Chosen.

## Decision

- `values.py` gains `foreign_aura_grants(class_file)`, reading a new `foreign_aura_grants` class-file array
  (mirroring `disabled_foreign_effects`'s `{spell, effect/target, reason}` shape).
- In `value_scenario`, a `foreign_duration` match additionally checks `(rank_id, duration_spell) in aura_grants`.
  When present, it adds a live `aura_duration_ms` expectation on the spell that is confirmed (by DBC or script)
  to receive the grant: on `CASTER` when `targets_ally(facts)` is false (1397742, 805422 — self-targeted), or,
  when true (804228), on a newly-introduced `ALLY` test player reached by its own `reset_cooldown` +
  `set_power` + `cast ... target: ally` + `cast_failure` sequence appended strictly after every other step
  (`ally_grant_proofs`, assembled after `after_cast`), so the rank's original single cast, its `cooldown_ms` and
  its own `aura_duration_ms #0` expectation keep measuring exactly what they measured before.
- `templar.json` lists the four grant pairs this item proves: `804228->102208`, `1397742->102208`,
  `805422->806354`, `805422->807004`, each with the DBC effect or script line that establishes the grant.
- `scaffold.py`'s `EMPTY_LIST_FIELDS` and the round-trip schema test gain the new key.

## Consequences

- The three spells' `spell_duration` expectations keep proving the DBC-computed duration token; a new sibling
  `aura_duration_ms` expectation per grant now proves the aura is actually present, on the correct unit, after a
  live cast — closing the "fails_if: the ally never receives aura X" gap the workstream file described for all
  three.
- No other spell's scenario changes: the gate is the explicit `foreign_aura_grants` list, not a blanket
  `targets_ally`/`foreign_duration` match, so the other ~45 `foreign_duration` pairs in the class (owned by other
  items or already closed) are untouched.
- A future grant (another scripted or DBC-triggered foreign aura) is enabled the same way: one class-file entry,
  no tool-code change, following the same "ally" vs "self" rule already generalised by `targets_ally`.
