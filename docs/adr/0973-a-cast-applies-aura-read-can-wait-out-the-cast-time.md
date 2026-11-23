# 0973. A cast applies aura read can wait out the cast time

- Status: accepted
- Date: 2026-11-16

## Context

Heartseeking Bolt 807284 "and reduces their healing received by $807316s1% for $807316d." (Witch Hunter part 382.0)
has a 3000 ms cast (`CastingTimeIndex` 14): its debuff 807316 (`DurationIndex` 1, 10000 ms) is triggered by
Effect[2] (`SPELL_EFFECT_TRIGGER_SPELL`, set in `AscensionWitchHunterCompletion.cpp`), which runs at launch
(`SpellEffects.cpp`, `EffectTriggerSpell`), so it lands at the end of the cast (measured about 2950 ms after the cast
step on the 25 ms simulated clock). The harness cast step returns before a cast-time spell finishes, and
`cast_applies_aura` accepted `read_after_ms` only below the 500 ms band (ADR 0880), so the after read came before
the Bolt landed (Witch Hunter author f-m18: first run read 0 ms). Mentor D-358 item 4 asked for the bound below.

## Options

- Make the cast step wait for every cast to finish: it changes every generated scenario that casts a spell with a
  cast time and moves finished-class digests.
- Add the cast time to the wait automatically: it changes the scenarios of existing entries that set the field.
- Raise only the validation bound of the opt-in `read_after_ms` to the cast spell's cast time plus the band.

## Decision

`read_after_ms` is a whole number of ms above 0 and below the cast time of the entry's `cast_spell` (or of its own
spell) plus the 500 ms `CAST_MARGIN_MS` band. The spec checks the type and the lower bound
(`behaviours.cast_applies_aura_read_after`); the scenario checks the upper bound against the DBC
(`behaviours.cast_applies_aura_read_after_bound`). The judge and its band are unchanged. For an instant cast the
bound stays 500 ms and the contract text is unchanged; with a cast time the contract states it.
With `read_after_ms` set, the single-arm expiry's applied poll (`expiry.applied_within_ms`) waits the 2000 ms
`APPLY_WITHIN_MS` plus the same cast time (mentor go, category A); the shift, the anchor error and the judge are
unchanged, and an instant cast keeps 2000 ms.

## Consequences

- Tests: `CastAppliesAuraReadAfterTests` (`test_behaviours.py`): 807284 accepts 3499 ms and refuses 3500 and 4000 ms;
  an instant spell still refuses 500 ms; a debuff read absent, at 9000 or 9400 ms, or at 11000 ms alerts, 9800 ms
  passes.
- `CastTimeAuraExpiryTest` (`test_expiry.py`): the Bolt's applied poll is 5000 ms, Chains of Darkness keeps 2000 ms;
  landings at 2950, 3000 and 3350 ms with a 10000 ms end pass, ends at 9000 and 11000 ms alert.
- Witch Hunter scenarios generated before and after the change are byte-identical except the two new 807284 ones
  (Chains of Darkness 680521, the only earlier `read_after_ms` entry, included; mentor D-364).
- Finished-class digests (Templar, Necromancer) are unchanged. First user: Witch Hunter 807284 `debuff_duration`.
- Number provisional (guide 14.4).
