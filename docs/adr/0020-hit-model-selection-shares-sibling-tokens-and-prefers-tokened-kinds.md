# 0020. Hit-model selection shares a sibling's token and prefers the token-bearing kind

- Status: accepted
- Date: 2026-11-07

## Context

Phase 2's `passives.py` already applies two rules to a passive's modifier effects (ruling R2): an effect without
its own tooltip token takes a sibling effect's token when their displayed points are equal, and when several
candidate kinds are found for one effect, the reader needs a way to prefer a real one over raising. `hits.py`,
which reads an *active*'s own hit-shaped effects, never applied either rule, and the phase-3 Templar probe run
found two live cases this leaves unmodelled that are not Templar-specific:

- **801165/803792 Temple Guardian**: `Effect[1] = 10 (HEAL)` (the charged ally) and `Effect[2] = 10 (HEAL)`
  (self) share identical `EffectBasePoints`/`EffectDieSides`; `Description[enUS]` carries one `$m2` token, on
  effect 1 only. `hit_kind` already resolves both effects to `kind='heal'`; `shown_values` then finds no
  `Displayed` entry for effect 2 and raises `unmodelled: effect 2 has no readable tooltip value` — the model is
  right, the value is readable, only the lookup is too narrow.
- **503141 Chastise**: `Effect[0] = 2 (SCHOOL_DAMAGE)` carries a readable token; `Effect[2] = 31
  (WEAPON_PERCENT_DAMAGE)`'s only mention is inside an unparsed `$?s806525[...]` conditional, so it has no
  `Displayed` entry at all. `hit_kind` finds two candidate kinds (`school`, `weapon`) and raises `effects of
  several hit models` before checking which one has a usable number.

## Considered options

1. Leave both unmodelled. Rejected: both effects have a real, DBC-readable expected value; refusing to model
   them is a tool limit, not an honest `unmodelled` about the game.
2. Hardcode the two spells' indexes. Rejected: the shape (a sibling sharing a token; several hit-shaped effects
   with only one tokened) recurs in other classes' tooltips, and phase 2 already solved the identical shape for
   passives — a Templar-only fix would have to be re-derived per class.
3. Generalize the two existing passive rules (R2) to a hit-shaped active's own effects, class-agnostically.
   Chosen.

## Decision

- **Shared sibling token** (`matching_sibling`, `effect_hit`): when an index in a hit kind's `indexes` has no own
  `Displayed` entry, and the kind is in `SHARED_TOKEN_KINDS` (`{'heal'}` only this round), search the rank's other
  effect slots for one whose `Effect`/`EffectBasePoints`/`EffectDieSides` all match exactly; if found, read that
  sibling's token and roll in its place. Kept to `heal`: every other path through `effect_hit`/`value_range`/
  `fixed_value` stays a pure function of its own effect, including the rolled-value and periodic-tick paths that
  must not start sharing tokens phase 2 did not intend. `passives.shared_token` was considered and rejected as the
  mechanism itself: its `single_value` call requires `EffectDieSides == 1`, and Temple Guardian's heal effects have
  `EffectDieSides == 7`, so the literal phase-2 function does not apply here; `matching_sibling` is the same rule,
  reimplemented for a rolled effect.
- **Token-presence tie-break** (`hit_kind`'s new `readout` parameter): `rank_hit` now reads the tooltip
  (`read_tooltip`) before calling `hit_kind`, so `hit_kind` can take the readout and, when more than one kind is
  found, filter to the kinds that have at least one own-token entry (`value.effect_index in indexes`) at one of
  their indexes. If exactly one kind survives, it is used; otherwise `hit_kind` raises exactly as before, naming
  every original candidate kind — so two real, both-tokened candidates still raise, never silently guessed
  between. `readout` is optional (default `None`, filter skipped) to keep every existing call site unchanged in
  behaviour: `expected_hit`'s call now threads the already-available `readout` through; `triggered_hit`'s call
  (hits.py:247, `trigger.effects`/`trigger.aura_names` for an `EffectTriggerSpell` target, not the casting rank's
  own effects) was checked and left without a `readout` — it has no tokened readout of its own to pass, and an
  unresolved multi-kind case there still raises exactly as before (fails safe, never a false `ok`).

## Consequences

- Temple Guardian's `hit_mean` and Chastise's `hit_mean` both produce a model instead of raising `unmodelled`,
  confirmed against the probe run's `conformance.py compare` output (Chastise `ok`, 348.138 against the
  mitigated tooltip mean; Temple Guardian builds, gameplay measurement separately blocked by a targeting gap
  outside this task).
- `SHARED_TOKEN_KINDS` and the tie-break filter are both class-agnostic: any class whose active repeats this
  tooltip shape (a shared heal token between siblings; several hit-shaped effects with only one tokened) is
  covered without a further code change.
- A tie between two genuinely tokened kinds still raises `effects of several hit models`, so this rule cannot by
  itself turn an ambiguous active into a false `ok`.
