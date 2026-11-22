# 1052. Aura fed effect judges an earned aura's duration on both sides of it

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Spears of Glory 804629 (ledger row 364, claim 1): "Your next Dawnsear within $d is instant cast"
(807299, 10000 ms). The `instant` variant proves the instant cast; "within $d" rested on the DBC duration only. The
proc cannot be forced: `Chance()` rolls the raw DBC ProcChance (`AscensionSunCleric.cpp:196-205`), so the aura must be
earned for real (owner ruling O-17) and its grant time known. Mentor rulings D-216, D-227, D-234; controller go after
the calibration reads.

## Options

- Design 1 (design note): feed every 1600 ms for one tick per cast and stop the channel with `set_moving`. Refuted by
  calibration: a 1600 ms feed gives two ticks per cast, and `set_moving` does not stop the channel.
- Design 2a: date the granting tick with `event_first_ms` since the grant's cast. Refuted by calibration: 807299
  sends no SPELL_GO, so `since_spell 807299` is never set.
- Design 2b: the clock is the `cast_until_aura` stop (the step reads the aura on every world update, so the grant is
  0 to 25 ms old; calibration read 9981 ms left in 6 of 6 trials), and the talent is unlearned at the stop so no later
  tick refreshes the aura, then relearned once the channel is over so the talent is known at cast time.

## Decision

Design 2b as an opt-in `variant: "window"` of `aura_fed_effect`: the judged read is the effect cast itself, instant
at `held_ms` (age inside 0.9 to 0.965 of the duration) and a normal cast at `gone_ms` (1.04 to 1.1), with void
preconditions per trial, a fixed `min_judged` per side, and an out-of-window age that leaves its side unmeasured.

## Consequences

- Absent by default: the variant is chosen by `variant`; the finished classes regenerate byte-identical.
- Seeded tests (`kinds/test_aura_fed_effect.py`): the unlearn, relearn and cast timing; pass and both mutants
  (not instant inside, instant past); voids down to unmeasured; out-of-window ages unmeasured; refusals.
- If the unlearn removed the aura, every trial would void (unmeasured): the controller's stop condition.
