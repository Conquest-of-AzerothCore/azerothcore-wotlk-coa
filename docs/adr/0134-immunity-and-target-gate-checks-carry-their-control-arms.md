# 0134. Immunity and target-gate checks carry their control arms

- Status: accepted; amends ADR 0132 (the `immunity` kind) and ADR 0133 (the gate's proof of its condition)
- Date: 2026-11-11

## Context

The review of lean Templar batch 1, chunk 1 found three proofs that did not exclude the alternative their clause
has to exclude.

- Testament of Resolve 804228 "granting immunity to fear, charm, and horrify effects": the `immunity` scenario
  applied each fixture with `set_aura`, but read the immunity after the dummy *cast* the fixture at the caster
  (`creature->CastSpell(target, spell, TRIGGERED_FULL_MASK)`). An accepted cast that never lands reads the same 0 as
  an immune caster, and nothing showed that this route lands Fear 12096 or Psychic Horror 64044 on the player.
- Templar's Might 705291 "on enemies affected by your Condemn": the gated `503141 hit_mean condemn_gate` learns
  705291 and sets Condemn; the unscaled `503141 hit_mean` learns neither. The contrast changed the talent and the
  debuff at once, so "talent held, no Condemn, no bonus" was not measured. ADR 0133 said the gated hit "differs from
  the unscaled check only by the target's debuff"; that is not so.
- Templar's Might "per stack": the gate was measured at the stack cap only (3 stacks, +18%), which a flat +18% also
  passes.

## Considered options

1. Immunity control before the cast (the dummy casts each fixture, it must land, then it is removed). Rejected: a
   creature's fear on a player raises the player's diminishing-returns level (`Spell.cpp:3181-3187`, fear is
   `DRTYPE_PLAYER`), so later fears land shorter or not at all for a reason unrelated to the immunity.
2. Immunity control after the immune window: wait out the spell's DBC duration, read the spell's aura gone, then the
   same dummy casts each fixture the same way and it must land. Chosen; it is the shape of the catalog's
   `runemaster-hurricane-fear-immunity-7716` ("which is also the control that the fear can land at all").
3. Cite the triage diagnostic (705291 learned, plain dummy 356.4 over 36 hits) for the gate-off half. Rejected: one
   uncommitted run, not part of the ledger.
4. Gate arms below the cap, declared per entry: `stack_arms` lists stack counts below the cap; each arm learns the
   enabling talent, sets the gate at that count and is judged at `percent * n / cap`. Chosen.

## Decision

- `behaviours.immunity_scenario`, after the `with` readings: a wait of the spell's `duration_ms` plus
  `CAST_MARGIN_MS` less the time the `with` arm took, `<spell> immunity <spell> expired` (0), then per effect the
  same `IMMUNITY_CASTS` dummy casts, `<spell> immunity <effect> control` (1), and the control aura removed. A spell
  without a finite duration is refused (`ValueError`).
- `conformance.target_gate_arms(entry, cap)`: the cap arm keeps its label; each `stack_arms` entry `n` (0 to cap - 1)
  adds `<label> stacks <n>` at `percent * n / cap`. `hits.hit_parts(gate_held=n)` sets the gate at `n` stacks (at 0
  it only removes it) and asserts `aura_stacks` equal to `n`.
- Templar: `target_aura_gates` 705291 declares `stack_arms` [0, 1]. The ledger cites `stacks 0` for "on enemies
  affected by your Condemn", `stacks 1` for "increased by $s1%", and both with the cap for "per stack"; the immunity
  claims cite `expired` and their `control`.

## Consequences

- An immunity proof now fails when the fixture route cannot land, instead of passing.
- Arm 0 separates the talent from the debuff; arms 0, 1 and the cap (expected +0%, +6%, +18%) put a flat bonus, or
  one granted by the talent alone, outside the judged band.
- A Templar's Might gate run is three times as long (three arms of 881 hits each, 12 scenario parts).
