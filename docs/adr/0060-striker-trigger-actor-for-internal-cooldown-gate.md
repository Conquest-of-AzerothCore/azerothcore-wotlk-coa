# 0060. A `trigger_actor` option extends `internal_cooldown_gate` to striker-driven ("taken hit") triggers

- Status: accepted
- Date: 2026-11-10

## Context

ADR 0059 built `internal_cooldown_gate` for three Templar "Can only occur ..." clauses, all triggered by a
*cast* from the caster, and deliberately left Sacred Defense 705306's own "Can only occur once per sec." (and
its sibling trigger_count clause, "strike back at enemies") out of scope: its trigger is incoming Physical
damage, not a cast, and the only `taken_hit` fixture `triggers.py` ever offered (16827, Claw (Pet)) was already
proven (round8, carried on this class file's own prior `status`/`reason` note) to deal exactly 6, 7 or 8 damage
against the reference Templar's armor. `AscensionTemplarEvents.cpp:128-137`'s `Proc()` computes
`Copy(player, event.GetActor(), 707720, uint64(damage) * 15 / 100)`, and `AscensionTemplar.cpp`'s `Copy()` only
casts `if (... amount)`; 15% of 6 truncates to 0, so roughly a third of attempts would silently read "no event"
regardless of the gate's own correctness.

`icd_gate_scenario` as written always has the *caster* cast `trigger_spell` at a target/ally/dummy via
`hits.cast_steps`, which assumes `trigger_spell` is one of the caster's own learnable abilities. Sacred
Defense's trigger is the reverse: a striker creature hits the caster.

## Considered options

1. Keep using the existing Claw (Pet) `taken_hit` shape from `triggers.py` and raise its damage by inflating the
   striker's level or gear. Rejected without even building it: `triggers.py`'s own fixture already proved (round8)
   that Claw's damage comes from a `SPELL_EFFECT_WEAPON_PERCENT_DAMAGE`-style effect scaled by the creature's own
   weapon stats, which this class file already sets to the class level (80) with no effect — the creature
   entry's intrinsic stats, not its level field, are the limiting factor, and there is no fixture field to raise
   them further.
2. A DBC-searched striker spell with `SPELL_EFFECT_SCHOOL_DAMAGE`, `SchoolMask` Normal (physical) and a large
   flat `EffectBasePoints`, cast directly by the striker via `CoAGameplayTest.cpp`'s non-player `cast` action
   (`Creature::CastSpell(target, spell, TRIGGERED_FULL_MASK)`, which does not require the striker's own spellbook
   to know the spell). First attempt: 18944 ("Smash"), `EffectBasePoints` 299/`EffectDieSides` 51 — large enough
   to clear the 15% truncation, but `DmgClass` RANGED, meaning each cast carries an ordinary spell-hit roll. Two
   otherwise-identical gameplay runs (`round10/judging-work/step10/diag1` stamp `20261110-023934`, `run1` stamp
   `20261110-024059`) measured the three-cast gate sequence as `1/1/2` (correct) and `1/1/1` (the third attempt's
   own counter-strike never registered) respectively — a stochastic miss on that specific trigger spell, not a
   margin or gate defect, confirmed by widening `reopen_margin_ms` to 1500 ms first (still `1/1/1` on the next
   run) before concluding the spell itself was the problem. Rejected: a flaky trigger spell reintroduces exactly
   the "needs a retry loop" shape ADR 0053 replaced with a deterministic lever for a different clause.
3. Scan `Spell.dbc` directly (not just by name) for a `SPELL_EFFECT_SCHOOL_DAMAGE`/`SchoolMask` Normal spell that
   also carries `SPELL_ATTR3_ALWAYS_HIT` ("Spell cannot miss, or be dodged/parried/blocked"). Found 32247
   ("Karazhan - Chess NPC Action: Melee Attack: DAMAGE (Footman)"): `EffectBasePoints` 999/`EffectDieSides` 1 (a
   flat 1000), `DmgClass` NONE (no weapon/level scaling), `AttributesEx3` exactly `SPELL_ATTR3_ALWAYS_HIT`, no
   proc-suppression attribute set. Chosen: deterministic magnitude, deterministic hit result, 150 of which (15%)
   never truncates to 0, and no CoA code or data needs to exist for it since it is a stock, already-shipped
   engine utility spell.

## Decision

- `behaviours.py`'s `IcdGateSpec` gains two optional fields: `trigger_actor` (default `CASTER`, the only value
  ADR 0059 modelled) and `striker_entry` (required, and validated `> 0`, only when `trigger_actor == STRIKER`).
- `icd_gate_scenario` branches on `trigger_actor`: the `STRIKER` path skips `armed_for`/`facts_of` entirely (the
  trigger spell is not one of the caster's own abilities) and skips learning `trigger_spell` onto the caster;
  each of the three attempts is `{'action': 'cast', 'actor': STRIKER, 'spell': trigger_spell, 'target': CASTER}`
  followed by the usual wait, and the scenario's `creatures` list carries the striker fixture (`id`, `owner`,
  `entry`, `level`, `health`, `distance`, `reaction: 0`, `stationary: True`) in the same shape `triggers.py`'s own
  `TAKEN_HIT` action already uses. The `CASTER` path is unchanged byte-for-byte from ADR 0059.
- `icd_gate_spec` reads both new fields from the class-file entry (`entry.get('trigger_actor', CASTER)`,
  `entry.get('striker_entry')`).
- `classes/templar.json` gains a fourth `internal_cooldown_gate` entry (705306, trigger_spell 32247,
  `trigger_actor: "striker"`, `striker_entry: 36`, observe_spell 707720, `internal_cooldown_ms: 1000`), citing
  the DBC fields above and the rejected 18944 attempt's own two divergent run stamps as the reason a second
  candidate spell was needed.
- The pre-existing `triggers.py`-shaped entry for 705306 (status `unmodelled`) is kept and its `reason` text
  updated to point at this new entry rather than claiming the clause is unprovable: the `trigger_count`/`trigger`
  *scenario shape* genuinely still has no taken_hit fixture strong enough for its own `TAKEN_HIT_TRIAL_METRICS`
  rate check, but the clause itself is proven by a different kind.

## Consequences

- Both of Sacred Defense 705306's remaining clauses ("When you take Physical damage you now strike back...",
  "Can only occur once per sec.") are proven on two independent gameplay runs, bit-identical (`ok`, measured
  1.0 against expected 1.0 both times).
- `trigger_actor: "striker"` generalises to any class's "when you take damage" reactive-proc gate: a class-file
  entry names a striker creature and a deterministic always-hit trigger spell, no further tool code.
- 32247 is a stock engine utility spell with no CoA ownership; using it as a fixture creates no cross-class
  coupling and needs no SQL.
