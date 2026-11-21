# 0072. `gate_absence` trigger kind proves a withheld condition suppresses a trigger

- Status: accepted
- Date: 2026-11-10

## Context

Several Templar tooltips state a conditional trigger: "**While a Libram is active**, your Chastise will now
unleash..." (Faith Guard 705259). The existing `trigger_count` entry for 705259 already proves the "fires when
the condition holds" half (it sets the Libram active via `attempt_auras` before every attempt, both in its
baseline and its measured phase), but nothing in the batch ever runs a trial with the passive *known* and the
named condition *withheld*. `judge_trigger`'s own baseline phase cannot stand in for this: that baseline learns
neither the passive nor the Libram, so a 0-event baseline there only proves "705259 unknown => no effect", not
"705259 known, Libram absent => no effect" — the actual gating the tooltip's "While..." clause claims. No
existing kind expresses "run the measured phase, but with a named condition held back": `trigger_count`'s
baseline always pairs "no passive" with every other fixture also absent, and `self_trigger`'s single phase has
no absence state to compare against at all.

## Decision

Add `kind: "gate_absence"` (`GATE_ABSENCE_KIND`/`GATE_ABSENCE_CHECK = "gate_absence_count"`, `triggers.py`), a
second entry alongside the class file's existing plain `trigger_count` entry for the same `aura` (same shape as
`magnitude_ratio`'s own "added alongside, not instead of" precedent): `trigger` (`action: "cast"` only),
`trial_metric`, `observe_spell`/`observe_source`/`observe_metric`/`observe_actor`, `trigger_text` and a new
`gate_text` (the tooltip words naming the withheld condition) in place of `per_trigger`/`per_trigger_text`.
`checked_gate_absence_entry` additionally requires the entry carry no `attempt_auras` of its own: the entry's
whole point is to run with every optional fixture at its *default* (absent) state, so a `gate_text` entry that
also sets `attempt_auras` would silently reintroduce the very condition it claims to withhold.

`gate_absence_scenario` reuses `trigger_plan`/`attempt_interval`/`attempt_steps`/`counts` unchanged (so cast
spacing and part-splitting are identical to every other `cast`-trigger kind): it learns the trigger spell *and*
the aura (the passive must be known, since this checks the gate, not the passive), runs every scheduled attempt
as a single measured phase with no baseline, and reads `trials`/`events` once at the end, the same shape
`self_trigger_scenario` already established for a single-phase trigger kind. `judge_gate_absence` (`compare.py`)
sums `trials`/`events` across parts and requires `events == 0` (strictly, `<= FLOAT_EPSILON`) over at least
`TRIGGER_TRIALS` trials: any nonzero count is `alert`, mirroring `judge_trigger`'s own "a baseline event is
always an alert" rule but for the opposite phase. Fewer than `TRIGGER_TRIALS` trials is `insufficient_trials`;
no trial at all is `unmeasured`/`alert` the same way `judge_self_trigger` already distinguishes those two.
`GATE_ABSENCE_CHECK` joins `CLASS_ENTRIES` and `conformance.py`'s `add_trigger` gets a `(aura, 'gate')` key
branch (mirroring `COOLDOWN_DELTA_KIND`'s own `shares_cooldown_effect` disambiguation) so the new entry's
scenario key never collides with the plain `trigger_count` entry sharing the same `aura`.

Faith Guard (705259): "While a Libram is active, your Chastise will now unleash a line of holy power..." The
reference Templar carries no Libram by default (confirmed by the existing entry needing `attempt_auras` to set
one), so the new entry needs no extra fixture at all to withhold the condition — it is the harness's own default
state. Two independent gameplay runs (stamps `20261110-024138` and `20261110-024246`) each measured 0 events of
706466 over 273 trials of Chastise 503141, `gate_absence_count` `ok`; the sibling `trigger_count` entry stayed
`ok` (273/273) in both runs too.

## Consequences

- A tooltip's conditional trigger clause ("While X is active, Y now Z") is provable on both sides: the existing
  `trigger_count` entry proves Z fires when X holds, and the new `gate_absence` entry proves it does not fire
  when X is withheld, closing the clause completely rather than only proving presence.
- `judge_gate_absence` has no "absent passive" branch to distinguish, matching `judge_self_trigger`'s own design:
  a part with no measurement at all is `alert`, since there is no second "as-expected absence" case left to
  carve out from it.
- A `gate_absence` entry's `checked_gate_absence_entry` guard against `attempt_auras` keeps a future entry from
  silently defeating its own purpose; an entry that legitimately needs some *other*, unrelated fixture active
  (not the one it is withholding) is not yet supported and would need that guard revisited.
