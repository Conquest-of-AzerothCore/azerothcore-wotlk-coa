# 0880. A travelling aura is read after it lands

- Status: accepted
- Date: 2026-11-16

## Context

Chains of Darkness 680521 "and taunting them for $680522d." (claim 170.0) triggers 680522, whose taunt aura
(`DurationIndex` 27, 3000 ms) has `Speed` 100: the hit, and the aura, reach the target `dist / Speed * 1000` ms after
the cast (`Spell.cpp:2476`). `cast_applies_aura` read the aura right after the cast step and saw it absent (Witch
Hunter archive `authors/f-s2`). Its expiry was unmodelled: a 3000 ms end at the 5% shift (150 ms) leaves no reading
pair timed from an applied poll, and the act-anchored arm (ADR 0143) needs an aura that lands inside its cast step.

## Options

- Derive a flight wait from the dummy distance and `Speed` for every entry: it changes generated scenarios of
  existing entries and moves finished-class digests.
- Anchor the expiry on the cast plus the computed flight: the landing tick is not known to the step, so the judged
  interval would be wrong by up to one tick on one side.
- An opt-in `read_after_ms` field, with the expiry timed from the applied poll that first sees the aura.

## Decision

`cast_applies_aura` takes `read_after_ms` (a whole number of ms above 0 and below the 500 ms `CAST_MARGIN_MS` band):
a wait between the cast and the after read, judged in the same band. With the field, the single-arm expiry
(`expiry.single_cast_arm`) is an `expiry_arm` with the applied poll right after the cast, a 10% shift (the D-200
floor; mentor D-310) and an `anchor_error_ms` of one poll period (25 ms) stated in the arm model. The judge
(`expiry.arm_reading`) subtracts that error from both lower bounds and adds it to both upper bounds, so the pair is
`ok` only if the end is still bracketed inside the shift with the error included, otherwise `unmeasured`. Entries
without the field generate unchanged scenarios and models; arms without `anchor_error_ms` are judged as before.

## Consequences

- Tests: `CastAppliesAuraReadAfterTests` (`test_behaviours.py`) and `TravellingAuraExpiryTest` (`test_expiry.py`):
  landings 0 to 400 ms after the cast pass at 3000 ms; ends at 2700 and 3300 ms alert; a 200 ms anchor error reads
  `unmeasured`.
- For 3000 ms the pair reads 126 ms before and 99 ms after the end, so ends 10% off are excluded but 5% off is not.
- The Templar and Necromancer digests are unchanged. First user: Witch Hunter 680521 `taunt`.
- Number provisional (guide 14.4).
