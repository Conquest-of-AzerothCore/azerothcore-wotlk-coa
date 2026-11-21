# 0551. A channel aura's duration is judged from stamped polls

- Status: accepted
- Date: 2026-11-13

## Context

Deathly Chill 805424: "Reduces the channel and cast time of Ice Barrage by $s1%" (claim 267.1). Design 1 bracketed the
end of Ice Barrage 501997's aura on the dummy with held / ends metric_delta reads in 10 ms windows. It read 726-731 ms
against 750 in single-spell pairs but flipped under load, because the aura's start and end move by more than 10 ms.
The ledger row's design 2 (stamped polls) was approved by the mentor.

## Decision

- Behaviour kind `aura_window` (module `cast_period.py`, with the same hooks as ADR 0550): the trigger is cast at the
  dummy without the talent (control), then again with it learned. In each phase, the aura on the dummy and the game time
  are read every `poll_ms` of wait over a start and an end window, both given in game time; each wait step's measured
  9 ms overhead is allowed for. The duration runs from the first read with the aura to the first read without it, and
  is judged against the stated value +- the G-19 band in both phases.
- Regeneration is off for the scenario: Runic Power decays during the 2000 ms control cast and the cast failed
  otherwise.

## Consequences

- 805424 `channel`: pair c2-chill-4 read the control at 994-1014 ms (1000 stated) and the talent at 734-754 ms
  (1000 x 0.75 = 750), in both runs. The eight design 1 entries were withdrawn.
- Tests: `AuraWindowTests` (test_cast_period.py), with an unshortened channel that must alert and a missed start that
  is unmeasured. Templar `generate --class 19` and `--stack` byte-identical.
