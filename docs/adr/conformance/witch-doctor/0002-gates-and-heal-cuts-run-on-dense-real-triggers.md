# 0002. Gates and heal cuts run on dense real triggers

- Status: proposed
- Date: 2026-11-15
- Tool halves (shared drafts, numbers assigned at merge):
  [ADR 0663](../../0663-an-internal-cooldown-is-bracketed-by-stamped-output-intervals.md), the `proc_gate_interval`
  kind; [ADR 0664](../../0664-a-cooldown-cut-per-heal-is-bracketed-by-recast-attempts.md), the `heal_cooldown_cut`
  kind.

## Context

Cycle 3 item (c) took three Witch Doctor claims with no label:
- Ingredient: Bloodthistle 801664, "Can only occur once every 0.5 sec.": the Potion's leech 802975 (spell_proc
  Cooldown 500) heals the owner by 5% of each hit it deals (`AscensionWitchDoctorEvents.cpp:68-69, 199-205`).
- Hexfire Mass 807450, "Can only occur once every 3 sec.": a 30% roll on Hex of Malice ticks summons a Serpent Ward
  50587 (spell_proc Cooldown 3000, `Events.cpp:86-88, 231-233`).
- Splash On 'Em 802219, "Effective healing done by Mojo Beam now reduces the cooldown of Potion Toss and Splash Potion
  by 1 sec.": each effective Mojo Beam heal calls `Reduce(player, Potion, 1000)` and `Reduce(player, Splash, 1000)`
  (`AscensionWitchDoctorBrewing.cpp:148-152`).
- Dark Loa's Incantation 525377, "Dealing damage with Shadowflare now applies Hex of Malice if it strikes at least 3
  enemies." (`AscensionWitchDoctorAbilities.cpp:392-421`).

Existing kinds checked first: `internal_cooldown_gate` (cast-only triggers at fixed wall waits, no setup casts, no
forcing), `cooldown_clear_time` (minion damage events only), `cost_gate` (one fixed reduction), `item_cooldown_gate`
(item use), `cooldown_reset_rate` (a reset chance), `pulse_targets` / `hit_period` / `cast_period` (minion pulses and
periods), `aura_window` (an aura's duration). None measures a gate on periodic or owner-damage triggers or a cut per
heal. `fixed_count` with `metric: "aura"` expresses the Hex threshold.

## Decision

- 801664 (`proc_gate_interval`): the cause is real (Brewer 92085 learned, Ingredient: Bloodthistle 801664 cast, Potion
  Toss 801661 at the caster); the control is one Spirit Eclipse before the Potion. Triggers are Spirit Eclipse rank 7
  811117 hits 802717 (one every 250 ms from the lifecycle Tick, at most one per Spirit, five per cast with five
  Spirits). The stated 500 ms gate sits on that grid: `ok` needs windows split by the edge (hit 3 answered in one, hit 4
  in another), which pins the bracket at 500 ms; windows all alike leave 250 to 500 or 500 to 750 ms and read
  `unmeasured`, so a 300 ms or 700 ms gate is never `ok`. A gate of 751 to 1000 ms alerts (outputs 1000 ms apart); a
  longer one leaves one output per window and reads `unmeasured`. 802717 is a ranged spell (DmgClass 3), so the entry
  adds `ranged_hit_rating` 10000 to the player fixture: the base 5% miss would leave about 64% of runs with a missing
  hit in the 20 window hits. The Potion 802975 (15000 ms) is named in `cause_auras`, so generation refuses a last window
  later than 14000 ms after Potion Toss. Rank 7 is the level-60 rank (`AscensionSpellProgressionData.h:199`, base 75 per
  hit), so the 5% leech is 3; rank 1's 15 would round the leech to 0 (`Copy` casts nothing for 0) and start the gate
  unseen. Spirits 561136 are set by harness `set_aura` before every Eclipse: a precondition fixture for the trigger, as
  Witch Doctor ADR 0001 rules for Spirits, never the subject. Four windows inside the Potion's 15 s.
  Cycle 4 revision: no schedule closes this gate by design: the band is 25 ms, one simulated wait step; five Spirits
  (StackAmount 5) give 1250 ms of hits, under the 1500 ms global cooldown, so only one 250 ms stream runs at a time,
  hit 3 of a window lands 475 to 525 ms after hit 1 and its lateness decides whether it is answered, and a Hex of
  Malice tick near the edge would be decided the same way. In final01 that split made the pair flip (`ok` in one run,
  `unmeasured` in the other). The entry now sets three Spirits, so each window has three hits: hit 3 answered gives a
  bracket of 250 to about 500 ms, hit 3 refused gives one output, and neither can close, so the expected verdict is
  `unmeasured` in every run (data conformant, G-19). A gate of 250 ms or less still alerts (outputs 250 ms apart).
  Seven windows of one Eclipse each, read 1700 ms after the cast, inside the Potion's 15 s less 1000 ms. Closing it
  needs a harness read of each event stamp or of the proc cooldown left on 802975 (tool note).
  Cycle 5 revision (ADR 0663 revision, exact edges; mentor ruling M-21 took the cycle 4 entry out of final02 because a
  window that refused hit 3 read its output interval as `nan` and failed the scenario): three Spirits on Spirit Eclipse
  at `dummy2`. Each tick casts the missile hit 802717 at `dummy2` (Speed 25) and the splash 802712 (Speed 0) at
  `dummy` (2 yd from `dummy2`, inside its 10 yd), so per window the first splash S1 is the first output and the third
  splash S3, the last event of its stream, comes 500 ms after it; the first missile hit A1, the first event of its
  stream, lands one flight time after S1 and is the probe. Both are placed exactly; no middle hit enters the bound
  (the first draft probed with the second missile hit, a middle hit placed at first + shortest interval, so its bound
  depended on the neighbouring intervals). The caster is relocated 6.6 yd back before window 1 and 0.18 yd before each
  later window, so `dummy2` is 11.6 to 15.2 yd away and the flight time, floor(d / 25 yd/s) with d the distance less
  the caster's combat reach and at least 5 yd (`Spell.cpp:2468-2476`), sweeps about 404 to 548 ms for a 1.5 yd reach
  (384 to 528 for 2.0, 448 to 592 for 0.389), 7.2 ms per window. Every window reads both streams' counts, first events
  and intervals and the output's first event and intervals since its cast. With the stated gate, every window has two
  or three outputs (S1, then S3 or a late A1), so no read is `nan`. On a regular 25 ms grid S3 is answered at 500 ms
  and the windows whose flight is 451 to 475 ms (476 to 500 ms when the hit fires from the update before) refuse A1 at
  exactly 475 ms: the bracket (475, 500] is deterministic. On irregular grids the close is statistical. The kind test
  `test_the_stated_leech_gate_closes_in_a_thousand_lane_seeds_per_update_order` asserts `ok` in 1000 seeds of the
  lanes step model (random 3 to 25 ms steps) per update order: 0 failures bound the miss probability below 3/1000 per
  run (rule of three, 95%), so the flip risk per pair below 6/1000. Timing-only arithmetic (the kind's step models,
  no judge) over 10000 seeds per combat reach (0.389, 1.5, 2.0 yd) and update order, for the lanes model and for a
  model that holds a random 1 to 25 ms step for up to 80 updates, placed the refused exact probe at 484 to 499 ms and
  the answered output at 500 to 509 ms in all 120000 runs (below 3/120000 per run under those models). A miss reads
  `unmeasured`, never a false `ok`: the bounds are exact or conservative. 21 windows; Potion Toss is cast again before
  windows 8 and 15 (`cause_every` 7), so each window ends within 13.5 s of waits after the latest Potion.
  `spell_hit_rating` 10000 joins `ranged_hit_rating`, since the splash is a magic spell hit.
- 807450 (`proc_gate_interval`): four dummies take Hex of Malice 801693 2250 ms apart, so the 3000 ms ticks fall
  750 ms apart; the control is those ticks before 807450 is learned; one window of 12.5 s ends before the first Hex
  (24 s). The 30% roll is forced (ADR 0482): the subject is the gate, not the chance. Ward spawns are read on the
  encounter timeline. The same dummy's tick lands on the 3000 ms edge: `ok` needs spawns both 3000 and 3750 ms
  apart; all 3000 or all 3750 reads `unmeasured`; a gate of 1800 or 4200 ms alerts.
  Cycle 4 revision (ADR 0663 revision): four dummies hexed 2020 ms apart (2029 ms with the three 3 ms steps before
  each cast), so three spacings make 6087 ms and `dummy` ticks 87 ms before `dummy4`, the dummy of the latest cast;
  `dummy3` and `dummy2` tick about 975 and 1950 ms after `dummy4`. 807450 is learned 935 ms after the round's last
  wait, 2964 ms after the `dummy4` cast: after the `dummy` tick (2913 ms, stamped at most 25 ms late) and before the
  first `dummy4` tick (3000 ms) and the window's start reads. The window of 6150 ms holds three spawns on `dummy4`
  ticks, 3000 ms apart; the `dummy` tick about 2900 ms after the first spawn is refused. `lead_targets` (`dummy`,
  `dummy2`, `dummy3`) and the timeline reads of the first spawn and the `dummy4` cast measure that offset with one
  extrapolated interval: under the documented step model it reads 2900 ms (2875 ms or more with 3 ms database steps);
  the worst stamp lateness (24 ms) and a full 25 ms interval spread leave 2913 - 24 - 25 = 2864 ms, so the bracket
  lies inside 2850 to 3150 ms. A gate of 2700 ms answers that tick (spawns about 2900 ms apart, a lead bound of about
  1925 ms); one of 3300 ms leaves one spawn interval; neither reads `ok`.
- 802219 (`heal_cooldown_cut`): one entry per gated spell (Potion Toss 801661, Splash Potion 802710), Mojo Beam
  500950 at the caster for 3000 ms (about six heals) then cancelled, caster health at 1% of the 10000 fixture maximum
  so every heal is effective. Expected recast near 9000 ms after the priming cast; attempts every 100 ms from 6500 to
  12000 ms bracket the cut per heal within about 17 ms. A third arm, the talent kept, sets the caster to full health:
  every heal overheals, and every attempt (one per 500 ms) must read 67, so "Effective" is tested. Control and
  ineffective refusals must read 67.
- 525377 (`fixed_count`, aura reads of Hex 801693): `hex_three` (three dummies inside Shadowflare's 8 yd, one beyond;
  the two additional ones hexed), `hex_control` (the same layout without the talent: none), `hex_two` (two dummies
  inside: none, the threshold). All three labels form the claim. Limit: the primary's Hex is not read
  (`count_primary` would count every struck dummy of the uncapped layout, one more than the stated count), so a server
  that hexes only the additional enemies passes; the claim is proved for the additional enemies, the ledger row says
  so.

## Consequences

- Four claims gain behaviour entries: 801664 and 807450 (one label each), 802219 (two labels), 525377 (three labels).
- Risks stated in the report: Spirit Eclipse ranks 1 to 7 all run the lifecycle script
  (`rev_20260909_00_witch_doctor_completion.sql:232-233, 312-323`), whose Tick casts one hit per Spirit
  (`AscensionWitchDoctorAuras.cpp:285-295`); a ranged spell hit can miss (not be dodged), which the
  `ranged_hit_rating` fixture removes, and a missed hit would widen a trigger gap (then `unmeasured`, never a false
  `ok`); 801664 (cycle 5) needs every splash and missile hit to land (both hit ratings) and the splash to reach
  `dummy`, which the Eclipse caps at five other enemies (two dummies leave one); 807450 closes by its lead bound while
  the `dummy4` tick
  on the 3000 ms edge is answered, which needs its stamp lateness not to drop between spawns (final01 read every
  spawn interval as 3000 ms); a dropped edge moves the next spawn to `dummy3`, about 975 ms later, and reads
  `unmeasured`;
  `cancel_aura`
  must stop the Beam channel, else the recast comes early and reads `unmeasured`.
- Observation (not a claim, not fixed): the leech heal 803287 targets the caster (`TARGET_UNIT_CASTER`,
  `AscensionWitchDoctorCompletion.cpp:365-371`) with the Witch Doctor as caster, so a Potion tossed on another ally
  heals the Witch Doctor, not the ally the tooltip names ("Causes target ally to leech"). Candidate defect lead for the
  801664 Potion clause; the gate entry tosses the Potion on the caster and does not depend on it.
