# 0073. `metric_delta`'s `setup_only_after` isolates a target-condition gate from the passive gate

- Status: accepted
- Date: 2026-11-10

## Context

Transcending Strikes (804897): "Your Divine Force will now trigger a 30 sec reduced cooldown when used on
enemies affected by Blade of Faith." The existing `metric_delta` entry for 804897 already proves the passive
half of this AND condition (`before_expected` 116994 with 804897 unknown, `expected` 86994 once it is learned),
but that entry's own `setup_casts: [803872]` applies Blade of Faith identically in both of `metric_delta`'s
phases, so its "before" reading already carries the target debuff too; it isolates "passive known vs unknown",
never "debuff present vs withheld" with the passive held constant. `AscensionTemplarAbilities.cpp:327-333`
requires both `player->HasAura(804897)` and the target carrying a `803872` aura cast by the player; no existing
verdict runs a trial with the passive known throughout and only the target's debuff toggled, so the clause's
own "when used on enemies affected by Blade of Faith" gating condition was unproven.

`metric_delta_scenario`'s two phases are built from the same `cast_steps()` closure, called identically before
and after a single `learn` step (of `spec.spell`/`spec.gate_spell`) placed between them; `setup_casts` are
always cast inside `cast_steps()`, so there was no way to make a `setup_casts` spell present in only one phase
while the gate spell is known in both.

## Decision

Add `setup_only_after: bool = False` to `MetricDeltaSpec`/the `metric_delta` entry schema (`behaviours.py`).
When set: `cast_steps()` takes an `apply_setup_casts` flag (default `True`, unchanged for every existing entry);
the scenario learns the gate spell (`gate_spell` or `spell`) and every `setup_casts` spell at the very start,
runs the first phase with `apply_setup_casts=False` (the setup spells are known but never cast), waits
`expire_ms` the same as before, then runs the second phase with `apply_setup_casts=True` (unchanged shape). The
existing (`setup_only_after` absent/`False`) path is untouched byte-for-byte: `cast_steps()`'s new parameter
defaults to the old unconditional `True`, and the `learn gate between phases` branch still runs exactly as
before. `metric_delta_scenario` rejects `setup_only_after=True` with an empty `setup_casts` (nothing to
withhold then apply, so the two phases would be identical). `behaviour_metric_delta_verdict` (`compare.py`)
needs no change: it already judges a before/after pair against `before_expected`/`expected` with no assumption
about *why* the two phases differ, so the same judge proves either kind of gate.

Transcending Strikes gets a second `metric_delta` entry (`"variant": "target_gate"`, `"label_suffix":
"target_gate"` for `scenario_key`/`Expectation`-label disambiguation from the first entry, matching the
`Whirling Tempest`/`Scourge-Defense Training` precedent for two entries sharing one spell): `setup_casts:
[803872]`, `setup_only_after: true`, same `trigger_spell`/`metric`/`fields`/`target` as the first entry. Because
the underlying mechanism is a strict AND of the same two conditions, the readings are the exact mirror of the
first entry's own numbers: `before_expected: 116994` (804897 known, no Blade of Faith on the dummy — no
reduction) and `expected: 86994` (804897 known, Blade of Faith cast on the dummy first — the full 30000 ms
reduction), reusing the base CD/wait_ms/clock-delta arithmetic the first entry's own `observe_source` already
derives.

## Consequences

- An AND-gated passive clause ("X now does Y when used on Z carrying W") is provable on both of its axes with
  the same `metric_delta` kind: one entry isolates the caster's own passive (gate the learn, hold the target
  condition constant), a second isolates the target condition (hold the passive known throughout, gate the
  setup cast). Future AND-gated `metric_delta` clauses reuse `setup_only_after` directly.
- Two `metric_delta` entries sharing a spell must set `variant`/`label_suffix` (or a differing `metric`, as the
  pre-existing Scourge-Defense Training pair does) or their `Expectation` labels and generated scenario keys
  collide; `metric_delta_scenario` does not itself guard against this (no cross-entry check exists for
  `metric_delta`, unlike `triggers.py`'s `checked_trigger_set`), so this remains the entry author's
  responsibility, same as before this change.
- `setup_only_after` only varies whether the *same* `setup_casts` list runs before the first phase vs before the
  second; it cannot yet express a *different* set of setup spells per phase. A clause needing that shape would
  need a further field.
