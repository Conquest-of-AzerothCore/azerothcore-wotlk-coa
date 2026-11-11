# 0125. A percent bonus is judged on the bonus, with power and the interval it excludes

- Status: accepted
- Date: 2026-11-11

## Context

The prototype review (prototype `score.md` §7, I1) found that a MAGNITUDE verdict judged a ratio within 5% of
itself: a "+20%" bonus was conformant from +14% to +26%. The C arm's `hit_ratio` judge (prototype
`behaviour_contrasts.py`, ADR 0111 there) had the same fixed band and no interval or power check (I8); the lean
branch did not carry it. The owner ruled on 2026-11-11: the bonus must lie within the larger of 5% of its value and
2 points ("+20%" passes from +18% to +22%), each report states the interval actually excluded, and trials are
sized for that band through the pilot sizing the prototype carried.

## Considered options

1. Keep the 5% band on the ratio and add an interval. Rejected: against the owner's ruling.
2. Apply the band only where a test failed. Rejected: every percent-bonus judge would keep a different rule.
3. One band rule in `bonus.py` for the statistical percent-bonus judges (`behaviour_hit_ratio`, `talent_delta`),
   with power and a negative arm, and an excluded range printed by every ratio and magnitude verdict. Chosen.

## Decision

- `bonus.bonus_band(b) = max(5% of |b|, 2 points)`. `bonus.bonus_status`: `alert` when the 99% interval of the
  measured bonus lies outside the band; `insufficient_trials` when its half-width is above half the band (power), or
  when the interval holds 0 against a nonzero bonus (negative arm); otherwise `ok` inside the band, `alert` outside.
  The verdict states the bonus range it excludes, `stated -+ (band + half-width)`.
- `behaviour_hit_ratio` (kind `hit_ratio`): control and treatment arms of one observed spell, the cumulative damage
  and hit count read after every trial; per-arm means per hit and their variance (`bonus.per_event_sample`), the
  bonus and its Welch half-width (`bonus.bonus_of`). `detail.sized_trials` targets 0.8 of the power limit.
- `prove` runs a pilot when a chosen behaviour entry is a hit ratio (`pilot.hit_ratio_pilot`): 20 trials, then the
  judged runs at the sized count, capped at what one scenario holds (`model.trial_limit`).
- `talent_delta` uses the same band and power rule; its verdict keeps the Welch interval in `low`/`high` for
  `levers.md`.
- The other ratio checks and `trigger_magnitude_ratio` keep their bands and state the range they exclude
  (`detail.excluded`): one reading without a sampling interval, or for a magnitude ratio the band widened by the
  half-width of the per-part ratios when two parts or more were usable.
- Templar: Pious Sweep 520034 gains a hit-ratio entry for its Tranquil Circle half; the clause ledger cites it only
  once it is proven.

## Consequences

- A band of 2 points on a 25% bonus asks for many more trials than a 5% ratio band; a hit ratio that needs more
  trials than one scenario holds stays `insufficient_trials` with the count it needs.
- `passive_delta` is a delta judge on a state read and keeps its tolerance (ADR 0124); whether the owner's band also
  applies to a stat percent passive is open.
