# 0663. An internal cooldown is bracketed by stamped output intervals

- Status: proposed (shared ADR draft; the number is provisional, assigned at merge)
- Date: 2026-11-15
- Class half: [Witch Doctor ADR 0002][class-half]

## Context

Proc tooltips end in "Can only occur once every N sec." The built-in `internal_cooldown_gate` kind casts the trigger
three times at fixed wall waits (half the window, then the rest plus 500 ms) and counts `spell_cast_count`. It does not
fit procs whose trigger is not the cast itself: a periodic tick (Hexfire Mass 807450 rolls on Hex of Malice ticks), or
the damage of a buff's owner (the Bloodthistle potion 802975 leeches on every hit the owner deals). It has no setup
casts for the cause, no forcing fixture for a rolled proc, and its waits are not read in game time.

The harness already stamps every event stream and the encounter timeline with the server's game clock and reports
the shortest and the longest interval of a filtered stream (`event_interval_min_ms` / `max` since a spell's latest
cast, `timeline_interval_min_ms` / `max`). No harness change is needed.

## Options

1. Extend `internal_cooldown_gate` (owner-owned `behaviours.py`) with setup casts, a forcing fixture and periodic
   triggers.
2. Poll the trigger and output counts every 25 ms with game-time stamps and rebuild each event's time from the polls.
3. A contributor kind module that reads, per window, the shortest and the longest output interval and the longest
   trigger gap, and brackets the gate between two bounds. Chosen.

## Decision

The contributor-owned kind `proc_gate_interval` (`CONF/kinds/proc_gate_interval.py`, ADR 0581;
[kind page](../../apps/coa-gameplay-test/conformance/docs/kinds/proc_gate_interval.md)):
- Bounds: in a window with two outputs or more, the shortest output interval is an upper bound of the gate (an output
  came that soon); the longest output interval less the longest trigger gap is a lower bound (the trigger before that
  output was refused). Both are exact game-time stamps, with no poll error.
- Judge with the G-19 band b of the stated gate: a shortest interval below `gate - b` alerts (a proc inside the
  window); a lower bound above `gate + b` alerts (a trigger refused after the window). A longest trigger gap below
  `gate - b` in every judged window (so a trigger falls inside every window and its refusal is shown), at least two
  output intervals and at least one refused trigger are required, else `unmeasured`. The gate then lies in the bracket
  (largest lower bound, smallest shortest interval]; `ok` needs that whole bracket inside `gate +- b` (lower bound at
  least `gate - b`, shortest interval at most `gate + b`). A bracket that reaches outside the band is `unmeasured`, and
  the report states the bracket, the interval actually excluded (G-19).
- Missing reads: a missing count or release read is a missing measurement, never an alert.
- Control: the same trigger round before the cause (a learned talent, real setup casts, or both); any output alerts,
  no trigger is `unmeasured`. A rolled proc takes the ADR 0482 forcing fixture (SPELLMOD_CHANCE_OF_SUCCESS +1000%),
  removed and read gone at the end; it is never a rate proof.
- Windows: each window reads its intervals since the latest cast of `since_spell`, so a window holds one trigger
  round. A timeline output has one window only, since timeline intervals span the encounter. A window without casts
  must read before the trigger aura ends, and a cause applied by a setup cast names its aura (`cause_auras`), which
  must outlast the last window read by 1000 ms.
- Amount floor: for a proc whose amount is a share of the trigger (a leech), a trigger amount whose share is below 1
  is `unmeasured`: a proc that rounds to nothing starts the gate yet sends no event, which would read as a refusal.
- Resolution, two-sided: on a regular trigger grid of gap g, windows that all answer alike leave a bracket g wide, so
  a gate shorter or longer than stated by less than one gap is not separated and reads `unmeasured`. The bracket
  closes on the stated gate only when it sits on the grid and edge timing splits the windows (a trigger on the edge
  refused in one window, accepted in another), or when triggers fall at most 2b apart. A gate off by more than one
  gap alerts.

## Consequences

- Gates on periodic or owner-damage triggers are measured in game time without harness C++.
- The judge separates the stated gate from one shorter or longer by less than one trigger gap only when the edge
  splits as above; otherwise the entry reads `unmeasured` with its bracket and the clause stays data conformant
  (G-19, ADR 0135). An `ok` always means a bracket inside the band.
- A run whose server timing never splits the edge (ticks exactly on the gate end every time) stays `unmeasured`.
- `docs/behaviour-scenarios.md` (owner-owned) does not yet list the kind in its index of module kinds; a tool note asks
  for the line.

[class-half]: conformance/witch-doctor/0002-gates-and-heal-cuts-run-on-dense-real-triggers.md
