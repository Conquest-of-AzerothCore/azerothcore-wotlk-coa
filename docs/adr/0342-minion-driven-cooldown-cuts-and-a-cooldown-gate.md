# 0342. Minion-driven cooldown cuts and a cooldown gate

- Status: accepted
- Date: 2026-11-12

## Context

Pandemic, Dominion of Frost and Study of Death cut a cooldown for each minion hit. The `cooldown_delta` kind casts
one trigger spell between two cooldown reads, a fixed cut per cast; a minion's hits are neither cast by the caster
nor countable one at a time. A `cooldown_ms` read is a readback (`coverage.EVIDENCE`: data), so a cut read alone
stays data conformant.

## Decision

- `kind: "cooldown_delta"` with the minion action: per window the observed spell is reset and cast, then its
  cooldown and the minion's counted events (`trial_metric`) are read before and after `window_ms`. The judge sums,
  over at least `TRIGGER_TRIALS` windows, the drop less the elapsed time (bounded by the wait and by
  `elapsed_between`), per counted event, against `expected_delta_ms` within 5%, and requires 0 per event within the
  same band over the 20 baseline windows without the passive.
- `kind: "cooldown_gate"` (check `trigger_cooldown_gate`, behaviour): the observed spell is primed, the minion attacks
  for `gate_wait_ms`, and the spell is attempted again: `SPELL_FAILED_NOT_READY` without the passive (the control),
  cast with it. `cast_failure` is an event, so the gate is the behaviour proof of the cut.
- `observe_cleared_auras` and `observe_target_auras` are precondition fixtures before each observed cast (Virulency
  needs a disease on its target and leaves its cooldown unset while Infestation 803782 is open).

## Consequences

- Counted pairs: Pandemic 956-1006 ms per Ghoul hit (stated 1000), Dominion of Frost 2977-3016 ms per Ghoul crit
  (stated 3000), and gates for both and for Study of Death (a Ghoul at 160 s, an Abomination at 110 s, which only a
  cut of at least 1.12 s per event explains).
- Study of Death's stated 0.5 s per event cannot be read per event yet: each Unholy Frenzy cast raises five Greater
  Zombies whose hits share the 1 s internal cooldown.
