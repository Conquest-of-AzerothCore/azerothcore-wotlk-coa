# 0070. `self_trigger` kind for a clause whose own cast is the trigger, with no baseline

- Status: accepted
- Date: 2026-11-10

## Context

`trigger_scenario` (the default `trigger_count` kind) always splits each part into a baseline phase (the
trigger spell cast with the aura unlearned) and a measured phase (the same cast with the aura learned), and
`judge_trigger` (`compare.py`) forces `unmeasured` whenever no part ever carried a baseline (`baseline is None
or baseline[0] <= 0`): a deliberate guard against a `trigger_count` verdict reading `ok` from presence alone,
with nothing tying the events to the passive.

Two clauses have no separate passive to gate that baseline against at all: Testament of Fortitude (500678,
"Applies Sacred Restraint for $102208d") and Vindication (573324, "triggering Zealotry") are each proven by
casting the spell itself — the tooltip's own cast *is* the trigger, `aura == trigger.spell`. round10
`proc-chains`' earlier step (`proc-chains-step4`) tried both as plain `trigger_count` entries and found the
baseline phase measures the effect too: `trigger_scenario` always learns `trigger.spell` before the baseline
(needed to cast it at all), so when `aura == trigger.spell` that `learn` already teaches the "aura" before the
baseline/measured split exists, and `judge_trigger`'s own guard then forces `unmeasured` by design, as
reproduced in that step. Closing these needs a kind with no baseline phase at all, not a workaround on the
existing one.

## Decision

Add `kind: "self_trigger"` (`SELF_TRIGGER_KIND`/`SELF_TRIGGER_CHECK = "self_trigger_count"`, `triggers.py`):
`checked_self_trigger_entry` requires `trigger.action == "cast"` and `trigger.spell == aura` (enforcing the
shape this kind exists for), plus the same `trial_metric`/`observe_metric`/`observe_actor`/`per_trigger`/
`co_learn`/`force_crit`/`trial_attempts_factor` validation the default kind already runs. `self_trigger_scenario`
reuses `trigger_plan`/`attempt_interval`/`attempt_steps`/`counts` (so `attempt_auras`, `co_learn` and
`force_crit` fixtures all carry over for free) but learns only the aura once, with no baseline steps, no
`learn`-before-baseline duplication, and no "aura applied" measurement (an active ability learned into the
spellbook is not itself an aura to check presence of — the 500678 entry, below, confirmed this empirically: the
measurement read 0 even though 273/273 trials and events were both present). `judge_self_trigger` (`compare.py`)
sums `trials`/`events` across parts and judges `events` against `trials x per_trigger` exactly like
`judge_trigger`'s measured phase, with no baseline branch and no "aura absent" branch: a part with neither
`trials` nor `events` measured is `unmeasured`'s sibling `alert` (there being no "the passive was absent, as
expected" case left to carve out), fewer than `TRIGGER_TRIALS` is `insufficient_trials`, otherwise `ok`/`alert`
by the same `EVENT_TOLERANCE` window. `SELF_TRIGGER_CHECK` joins `CLASS_ENTRIES` (`compare.py`) since, unlike
`magnitude_ratio`, a `self_trigger` entry never coexists with a plain `trigger_count` entry on the same aura.

Testament of Fortitude (500678): `EffectTriggerSpell[2]` of 500678 is 102208 (Effect[2] `SPELL_EFFECT_TRIGGER_SPELL`,
read via `inspect_dbc.py`), cast unconditionally on every cast of 500678 itself; `observe_metric: "aura_apply_count"`
of 102208. Two independent gameplay runs (stamps `20261110-020351` and `20261110-020504`) both measured 273
events in 273 trials, `self_trigger_count` `ok`.

Vindication (573324): `AscensionTemplarAbilities.cpp:305-307` (`OnSpellHitResult`) casts Zealotry (801450)
unconditionally on every landed hit of the Vindication chain (`Named(info, 801446)`, chain root 801446, rank
573324 per `rev_20260831_01_local_spell_progression.sql:1112`). The first measured run (stamp `20261110-015153`,
before the fixture below existed) read 501 events over 273 trials — far above the `per_trigger: 1` this clause
alone predicts — reproduced, not a measurement artifact: `AscensionTemplarAbilities.cpp:155-162` (`OnSpellCast`)
unconditionally grants/stacks Oath: Vindication (805332) via `GrantOath()` on *every* Vindication cast (not a
separate passive the entry opts into), and that aura's own roll at `AscensionTemplarAbilities.cpp:311-313`
(`if (AuraEffect* oath = player->GetAuraEffect(805332, EFFECT_0)) if (roll_chance_i(oath->GetAmount()))
Zealotry(...)`) then adds a second, cumulative Zealotry trigger as the stack grows across repeated casts of the
same ability — the tooltip's own second clause ("Oath: Your damaging abilities have a 20% chance to trigger
Zealotry"), not a defect, but a different clause than the one this entry proves. The existing `attempt_auras`
fixture (`set_aura` with `stacks: 0`, which `Unit::RemoveAurasDueToSpell` already treats as "remove regardless
of caster" for an empty caster guid) clears 805332 before every attempt, isolating the unconditional half; two
independent runs after that fix (stamps `20261110-020351` and `20261110-020504`) both measured 273 events in
273 trials, `self_trigger_count` `ok`. The Oath's own chance clause remains unproven by this entry (recorded in
the workstream file as a separate, still-open clause).

## Consequences

- A clause whose own cast is unconditionally its own trigger (no co-learned passive) is provable without
  inventing a fake baseline.
- `judge_self_trigger`'s only "no evidence" outcome is `alert`, deliberately: there is no longer an "absent
  passive, as expected" condition to distinguish from a broken run.
- `TriggerCountLabelDisambiguationTest`'s `checked_trigger_set` collision guard already skips any entry with a
  `kind` set, so a `self_trigger` entry never needs the trigger-spell disambiguation ADR 0053 added.
