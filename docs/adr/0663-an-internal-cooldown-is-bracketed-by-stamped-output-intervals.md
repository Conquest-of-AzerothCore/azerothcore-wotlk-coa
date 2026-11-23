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
  refused in one window, accepted in another), or when triggers land at most b apart. A gate off by more than one
  gap alerts.

### Revision (cycle 4): a lead bound from per-dummy reads

In the Witch Doctor count of record final01, 801664 read `ok` in one run and `unmeasured` in the other (brackets 484 to
500 and 250 to 500 ms), and 807450 read `unmeasured` in both (2222 to 3000 ms). Both relied on edge timing. An event
is stamped at the first world update at or after it is due, up to one simulated step late (25 ms in a wait), and the
gate is compared in the same game time, so lateness decides the edge trigger's side.

Options: (1) a uniform grid with triggers at most b apart: 807450 would need 20 Hex dummies (b 150 ms of a 3000 ms
period), more than the 11 dummies and the 24 s Hex allow at a 1.5 s global cooldown; (2) a harness read of each event
stamp or of the proc cooldown left (owner-owned C++, a tool note); (3) a source dummy identified by counts and the
other dummies' ticks placed over every cycle of the window, widened by the interval spreads (the first cycle 4 draft:
a 25 ms spread over the 5 cycles of a 14300 ms span took the lead tick below the band); (4) a lower bound anchored on
the first output, chosen.

Decision: the optional `lead_targets` reads, at the window end and with existing harness metrics, each lead dummy's
first event and its shortest and longest interval since the latest `since_spell` cast, and on the encounter timeline
the first output and that cast (`timeline_first_ms`; the same game clock stamps the event streams). With O the first
output's offset after the cast and f, low, high the reads of a lead dummy, the dummy's first event refused at f - O
after O when it falls between O and O plus the shortest output interval, or its second event refused at least
f + low - O after O when f <= O < f + low and f + high < O + shortest. Either trigger lies after the first output and
before the next one, so it was refused; at most one interval is extrapolated. The largest such offset is the lead
bound, a window with one skips the longest-trigger-gap requirement, and a dummy that meets neither condition adds
nothing. The dummy of the latest cast is not a lead target (its first event since that cast is the cast's own hit).
The bound is deterministic under the documented step model (verification.md: 3 ms non-wait steps, wait steps of at
most 25 ms) when a lead dummy ticks d before the source of the first output, the cause is learned in that gap, the
latest cast lies less than one period before it, and the period less d less two steps (the lateness of the first
output and of the lead tick, and the lead dummy's interval spread across the wait boundary) stays at or above
`gate - b`.

Limit: with b no wider than one simulated step (801664: b 25 ms), triggers would have to land at most b apart on both
sides of the gate after every output. Spirit Eclipse gives one 250 ms stream at a time, and a second phased stream
(Hex of Malice ticks on dummies, which Bloodthistle's check also takes as owner damage) only adds a trigger whose side
of the edge its own lateness decides; option (2) would close it. Such an entry is scheduled so that it cannot read
`ok` by chance either, since an `ok` in one run and `unmeasured` in the other is a flip.

## Revision (cycle 5): exact edges

Context: the three-Spirit 801664 entry failed as a scenario in final02 (a window that refused hit 3 had one output,
and its output interval read `nan`), so it was taken out of the pair (Witch Doctor mentor ruling M-21). The cycle 4
limit was also stated too strongly. Lateness decides on which side of the edge a trigger lands, but not what the stamps
show: the proc cooldown (`GameTime::SteadyNow`) and the event stamps (`GameTime::Now`) read the same simulated point
inside one world update, because `TakeStep` advances the clock only before `World::Update`. A trigger t ms after an
output is therefore answered exactly when t >= the gate, whatever its lateness. What the interval reads lacked was the
stamp of the refused trigger: with one stream, its offset after the output is not readable.

Options: (1) the harness read of each stamp or of the cooldown left (option 2 above, owner-owned C++); (2) many
windows of one stream with jittered edges, closing with a sized probability: on a regular step grid the edge hit lands
exactly on the gate every time and never closes; (3) exact edges from existing reads, chosen.

Decision: `edge_streams` with `edge_hits` 2 or 3 read, per window, each stream's count, first event and shortest and
longest interval since the window's single cast, and the output's first event and intervals. With three hits the first
and last are exact and the middle one lies between two stamps. The first output must be the earliest trigger; the
second output's offset is the upper bound; every trigger placed wholly between the two outputs (and after the second)
is a refused offset, so the lower bound. A middle hit is placed at first + shortest interval, below its true offset
whenever the later interval is the shorter, so the probe must be an exactly placed event: the first or last event of
its stream. Two streams with a fixed offset per tick (a splash at the tick and a missile hit a flight time later) put
such a probe near the gate: the first missile hit, one flight time after the first splash; `relocate_yd` moves the
caster between windows to sweep the flight time across the gate (above the 5 yd floor of the missile distance), and
`cause_every` renews a short cause aura. All reads are defined while every stream draws its hits and the output fires
twice, so the scenario cannot fail on a `nan` read under the stated gate.

Consequences: on a regular 25 ms grid every offset after the first output is a multiple of 25 ms, so the swept probe
is refused at gate - 25 and the tick-timed trigger answered at the gate, the band's edge: a deterministic close. On an
irregular grid (lanes take the smallest step need, 3 to 25 ms) the close is statistical, and an entry states its
residual miss probability from a sized seed count (0 failures in N seeds bound it below 3/N per run, rule of three,
and the flip risk per pair below 6/N); a miss reads `unmeasured`, never a false `ok`, since every bound is exact or
conservative. A gate 10% off never reads `ok` (refused offsets lie below the gate, answered ones at
or above it), and crossing bounds are `unmeasured`. It needs two trigger streams from one cast with different arrival
times; a single-stream gate still needs option (1).

## Consequences

- Gates on periodic or owner-damage triggers are measured in game time without harness C++.
- The judge separates the stated gate from one shorter or longer by less than one trigger gap only when the edge
  splits as above; otherwise the entry reads `unmeasured` with its bracket and the clause stays data conformant
  (G-19, ADR 0135). An `ok` always means a bracket inside the band.
- A run whose server timing never splits the edge (ticks exactly on the gate end every time) stays `unmeasured`,
  unless `lead_targets` gives a lead bound.
- The lead bound adds 3 reads per lead dummy and 2 timeline reads; it rests only on the first output, the measured
  stamps of one or two events per dummy and the shortest output interval, so it gives no bound, never a false one,
  when the schedule drifts (a refused edge, a cause learned outside its gap).
- `docs/behaviour-scenarios.md` (owner-owned) does not yet list the kind in its index of module kinds; a tool note asks
  for the line.

[class-half]: conformance/witch-doctor/0002-gates-and-heal-cuts-run-on-dense-real-triggers.md
