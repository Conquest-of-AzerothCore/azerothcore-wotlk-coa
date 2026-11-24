# Proc gate interval (`behaviour_metric_delta`, `kind: "proc_gate_interval"`, ADR 0663)

ADR 0663 is a shared draft whose number is provisional and assigned at merge; its class half is Witch Doctor ADR 0002.

An internal cooldown on a proc ("Can only occur once every 0.5 sec."), measured in game time on both sides: a trigger
inside the window gives nothing, the first trigger after it gives the proc. Triggers are events of a harness event
stream (`trigger`: `stream`, `spell`, optional `target`; `spell_damage`, `spell_heal` or `spell_energize`); outputs
are events of an event stream (`output` with `stream`) or of the encounter timeline (`output`: `event` `spawn`,
`cast` or `aura_applied` with `source_entry`). All are stamped by the server's game clock.

Order of one scenario:
- the spells of `learn` and of the casts are learned; a timeline output starts the encounter timeline;
  `forced_talent` gets the forcing fixture of SPELLMOD_CHANCE_OF_SUCCESS +1000% (removed and read gone at the end);
- control: one round of `trigger_casts` (`[spell, target]`, `cast_wait_ms` apart), `control_ms`, and the trigger
  and output counts at its start and end;
- the cause: `talent` learned, then the real `setup_casts`. With setup casts, `cause_auras` (`[aura, cast]`, `[]` for
  a cause that does not lapse) is required: generation refuses a window read later than the aura's DBC duration less
  1000 ms after the latest cast of that spell. `cause_every` n (optional) casts the `cause_auras` spells again, with
  the same fixtures as the first cast, before windows n + 1, 2n + 1, ..., so a long series of windows stays inside a
  short cause aura;
- `windows` windows, each with its own round when `window_casts` (default true), `window_ms`, then the counts and
  three game-time reads since the latest cast of `since_spell`: the longest trigger gap, the shortest and the longest
  output interval (`event_interval_min_ms` / `max`, or `timeline_interval_min_ms` / `max` for one window only).

Before every trigger cast, `cast_auras` (`[aura, stacks]`) are set by harness `set_aura` (a precondition fixture for
the trigger, never the subject), `cast_power` sets the power and the cooldown is reset. `fixture` adds player stats.
`dummies` (1 to 11) stand `dummy_step_yd` apart from 3 yd, named `dummy`, `dummy2`, ... A window without casts must
read before the shortest trigger aura ends.

`lead_targets` (optional, distinct dummies; the trigger stream then names no `target`, the output is a timeline
event, the window has no casts, and the latest `since_spell` cast reaches a dummy that takes that spell once and is
not a lead target) reads at the window end, for each lead target, its first event (`event_first_ms`) and its shortest
and longest interval since the latest `since_spell` cast, and on the encounter timeline the first output and that
cast (`timeline_first_ms`, `cast` of `since_spell` at that dummy). They give the lead bound below.

The judge, with the G-19 band b of `gate_ms`:
- a missing count or release read is a missing measurement; the forcing fixture still held, or an output in the
  control, alerts; a control without a trigger is `unmeasured`;
- a window with two outputs or more is judged. Its shortest output interval is an upper bound of the gate; its
  longest output interval less its longest trigger gap is a lower bound, since the trigger before that output was
  refused;
- the shortest output interval below `gate_ms - b` alerts (a proc inside the window); the lower bound above
  `gate_ms + b` alerts (a trigger refused after the window);
- otherwise every judged window's longest trigger gap must lie below `gate_ms - b` (a trigger inside every window),
  with at least two output intervals and at least one refused trigger, else `unmeasured`;
- the gate then lies in the bracket (largest lower bound, smallest shortest interval]. `ok` needs the whole bracket
  inside `gate_ms` +- b: lower bound at least `gate_ms - b` and shortest interval at most `gate_ms + b`. A bracket that
  reaches outside the band is `unmeasured`, and the explanation states it.
- `amount_pct` (a leech share of the trigger amount): a mean trigger amount whose share is below 1 is `unmeasured`,
  since a proc that rounds to nothing still starts the gate and reads as a refused trigger.
- Lead bound (with `lead_targets`), in a judged window. The first output O lies `output first - cast first` after
  the latest `since_spell` cast, on the game clock that also stamps the event streams. For a lead target with first
  event f and intervals between `low` and `high` since that cast: when O < f < O + shortest output interval, its first
  event is a trigger after O and before the next output, so it was refused `f - O` after O; when f <= O < f + low and
  f + high < O + shortest, its second event is that trigger, refused at least `f + low - O` after O. No other cycle is
  extrapolated. The largest such offset over the lead targets is the lead bound; a target that meets neither condition,
  or a missing first output, adds none. The window's lower bound is the larger of this and the interval bound, and a
  window with a lead bound skips the longest-trigger-gap requirement. The dummy of the latest cast is not a lead
  target, since its first event since that cast is the cast's own hit.

Resolution, on both sides. An event is stamped at the first world update at or after it is due: up to one simulated
step late (25 ms in a wait, verification.md, Fidelity limits). After an output, the accepted trigger and the latest
refused one bracket the gate, and `ok` needs both inside `gate_ms` +- b:
- Interval bound alone: on a regular trigger grid of gap g, every window alike gives a bracket g wide, so a gate
  shorter or longer than stated by less than one gap reads the same and is `unmeasured`, not `ok`. A narrower bracket
  needs edge timing to split the windows (a trigger on the edge refused in one, accepted in another). A deterministic
  close needs triggers that land at most b apart, a grid gap plus the step lateness of at most b (2b apart is not
  enough: the trigger before the gate can then lie b to 2b below it).
- Lead bound: periodic triggers whose phases put a lead target's tick d before each tick of the dummy that gives the
  first output, with the cause applied in that d-wide gap and the latest `since_spell` cast less than one period
  before it. The lead tick then lies `period - d` after O, measured from the first output, give or
  take the stamp lateness of O and of the lead tick and the spread of the lead target's intervals (each below one
  simulated step, 25 ms in a wait). `ok` is deterministic under the documented step model when `period - d` less two
  steps stays at or above `gate_ms - b`. The upper side is the first output's source ticking again on the edge: it is
  answered while its stamp lateness does not drop between two outputs (constant within one wait on one lane); when it
  drops, the next output comes from another dummy, the shortest interval leaves the band and the entry reads
  `unmeasured`, never a false `ok`.
- With interval reads only, when the band b is no wider than one simulated step, triggers would have to land at most
  b apart on both sides of the gate after every output, and a trigger on the gate edge is answered or refused by its
  lateness. Such an entry cannot close by design; schedule it so that it cannot close by chance either (a flip between
  `ok` and `unmeasured` across runs is the coin flip that verification.md forbids). Use exact edges instead.

## Exact edges

`edge_streams` (event streams on named units) with `edge_hits` (2 or 3) switch a window to exact reads. The entry
needs an event output on a named unit, one `since_spell` cast per window and no `lead_targets`. At each window end,
for every edge stream: its count at the window start and end, and its first event (`event_first_ms`) and shortest and
longest interval since the window's cast; for the output: its first event and shortest and longest interval. Every
read is defined while each stream draws its hits and the output fires twice, so no read is `nan` under the stated
gate. `relocate_yd` `[first, step]` (optional) relocates the caster along x by `first` before the first window cast and
by `step` before each later one: for a missile trigger it sweeps the flight time, and so the trigger offsets, across
the gate (a positioning fixture; the dummies are stationary). A missile flies floor(d / speed) after its launch, where d
is the distance less the caster's combat reach but at least 5 yd (`Spell.cpp:2468-2476`), so a sweep below that floor
moves nothing.

Placement: with three hits the first and the last are exact (first, first + shortest + longest) and the middle one
lies between first + shortest and first + longest; with two hits both are exact. The proc cooldown and the stamps read
the same simulated point inside one world update (`GameTime::SteadyNow` and `GameTime::Now`; `TakeStep` runs before
`World::Update`), so a trigger t ms after an output is answered exactly when t >= the gate.

The judge (after the control checks above), per window:
- every edge stream must draw `edge_hits` events, the output at least two; the first output must be the earliest
  placed trigger (an exact one at the same stamp, none earlier); with two outputs both intervals must agree and the
  second output must fall inside a placed trigger. Otherwise the window does not pair and the entry is `unmeasured`;
- upper bound: the second output's offset (the shortest output interval with more outputs);
- lower bound: with two outputs, the offset after the first output of every trigger placed wholly between the two
  outputs (its earliest stamp), and the offset after the second output of every trigger placed wholly after it.

Over the windows, the gate lies in (largest lower bound, smallest upper bound]. An upper bound below `gate_ms - b` or a
lower bound above `gate_ms + b` alerts; bounds that cross (a contradiction of the shared clock) are `unmeasured`; `ok`
needs the whole bracket inside `gate_ms` +- b, else `unmeasured`. A gate 10% off can never read `ok`: refused offsets
lie below it and answered ones at or above it.

Resolution. A middle hit is placed at first + shortest, which is earlier than its true offset whenever the later
interval is the shorter one, so a probe that is a middle hit gives a lower bound that depends on its neighbours.
Schedule the probe as an exactly placed event (a first or last event of its stream). On a regular 25 ms grid the
offsets relative to the first output are multiples of 25 ms, so a swept exact probe is refused at `gate_ms - 25` and the
edge trigger answered at `gate_ms`: the close is deterministic. On an irregular grid (lanes take the smallest step
need, 3 to 25 ms) it is statistical: the probe lands closer below the gate when it closes, and the entry states its
residual miss probability from a sized seed count of the step models (0 failures in N seeds bound it below 3/N per
run, rule of three, so the flip risk per pair below 6/N). A miss reads `unmeasured`, never a false `ok`: every bound is
exact or conservative.

## Witch Doctor entries

Ingredient: Bloodthistle 801664 (Potion leech 803287, 500 ms, b 25 ms; exact edges: three-Spirit Spirit
Eclipse 811117 at `dummy2`, whose splash 802712 on `dummy` lands at each tick, so the first splash is the first output
and the third splash, the last event of its stream, comes 500 ms later; the first missile hit 802717, the first event
of its stream, lands one flight time after the first splash and is the probe. The caster steps back 6.6 then 0.18 yd
per window over 21 windows, so `dummy2` is 11.6 to 15.2 yd away and the flight time sweeps about 404 to 548 ms for a
1.5 yd combat reach, 7.2 ms per window, above the 5 yd floor. On the regular grid the bracket is (475, 500]; the
kind test asserts `ok` in 1000 lanes-model seeds per update order (miss rate below 3/1000 per run, flip risk per pair
below 6/1000); Potion Toss is renewed every 7 windows), Hexfire Mass 807450 (Serpent
Ward 50587 spawns on Hex of Malice ticks, 3000 ms, b 150 ms: four dummies hexed 2029 ms apart, so `dummy` ticks
87 ms before `dummy4`, the dummy of the latest cast; 807450 is learned in that gap and the `dummy` tick about 2900 ms
after the first spawn is the lead tick).
