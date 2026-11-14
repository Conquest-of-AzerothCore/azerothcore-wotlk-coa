# 0046. The Study of Death cut is bracketed by repeated casts

- Status: accepted
- Date: 2026-11-13

## Context

Claim 179.1, Study of Death 704721 "reduces the cooldown of Unholy Frenzy by $/1000;302597S1 sec" (500 ms per
Frost or Physical minion damage event, at most once per second; AscensionNecromancerEvents.cpp:200-205). The
per-event cut was read as 505.7 and 506.1 ms through `cooldown_ms`, a readback (ADR 0342): data evidence. A single
cast gate brackets the cut only to about 0.40 to 0.61 s, wider than the G-19 band.

## Options

- A "with refused" arm in the central gate judge (compare.py): a central change, and the bracket stays wide.
- A kind module that attempts the spell every second near its clear time and reads the minion's events at each
  attempt: the last refusal and the first cast bracket the cut per event to one second of elapsed time.

## Decision

Kind `cooldown_clear_time` (kinds/cooldown_clear_time.py). Unholy Frenzy is cast before 704721 is learned, so no
Greater Zombies are animated and only the Ghoul's hits (2000 ms swings, above the 1 s gate) cut. Attempts run from
100 s to 175 s after the learn, every 1000 ms; the judge uses the DBC recovery time, 180000 ms, and `cast_failure`, an
event.

## Consequences

- Pilot 20261113-175042: refused at 142774 ms and cast at 143792 ms after 73 events: 496.0 to 509.9 ms per event
  against 500 +- 25.
- The elapsed time is counted from the learn, a few milliseconds after the priming cast; over 73 events that shifts
  the bracket by well under 1 ms.
