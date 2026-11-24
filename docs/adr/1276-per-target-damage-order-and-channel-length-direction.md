# 1276. Per-target damage order and channel-length direction judges

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-24
- Builds on: ADR 0712 (`monotone`, a direction judge across power levels), ADR 0995 (`area_dummies`)

## Context

Two Felsworn clauses state a direction without a figure. Hellfire Carver 707444 and Carve 800206 say "dealing less
damage with each target struck"; Carve also says "dealing increased Weapon Damage with both weapons based on how long
you channel". No kind compared the damage of one cast across its targets (`ratio_to_metric` refuses a summed reading),
and no option ended a channel at a set time (triage rows 185.1 and 204.0, tool group B-DIR). Mentor rulings D-100 and
D-101 approved two judges: strictly falling damage over 9 targets ranked by their measured distance, crits excluded;
strictly rising end damage over at least three channel lengths, crits excluded. Review fw-rbdir I-1 then showed that a
strict rise of three means passes a length-independent slash, or a cancel that did not end the channel, with
probability 1/6 per run; mentor D-106 approved a rise without overlap and D-100 a void read of the channel aura.

## Options

- Rank the targets by the server's hit sequence, read by a new harness metric (`spell_damage_sequence`: the rank of a
  target's first damage event after a cast, in recorded order). Not built (D-101): a harness change for a key the
  geometry already fixes.
- Rank the targets by their measured distance from the spell's search centre (the primary for Fel Fireball, the caster
  for the Carve slash), read in the same arm. Chosen; the code that adds and scales targets nearest first is cited
  only as the reason for the key.
- Judge the channel length with `monotone`. Not possible: it varies a power fixture, not the channel's end.

## Decision

Two opt-in `metric_delta` option modules:

- `target_order` (`metric_delta_options/target_order.py`): `{"spell", "events", "centre", "casts"}` on an entry with a
  plain `area_dummies` list. The treatment phase is cast `casts` times; after each cast every target's damage of
  `spell` is read without critical, resisted or blocked hits, with its plain and total hit counts and every position.
  A cast whose distances from the centre lie within 0.01 yd of each other is void. Each target must be struck
  `events` times per cast (else alert). The mean plain damage per distance rank, over the casts where that target took
  only plain hits, must fall strictly from the nearest to the farthest; a rank with no plain cast is unmeasured.
- `channel_lengths` (`metric_delta_options/channel_lengths.py`): `{"spell", "events", "cancel_ms", "repeats"}`, at
  least two rising cancel times below the entry's `wait_ms`. The treatment phase is cast `repeats` times as the full
  channel and `repeats` times per cancel time, the channel ended by the native `cancel_aura` that many ms after the
  cast, and the channel aura (the trigger spell on the caster) read right after each cancel: a cast whose channel
  aura is still up is void. Each cast must land `spell` `events` times on the dummy (else alert); every kept plain
  damage of a length must lie below every kept plain damage of the next length (a rise without overlap; with `n` casts
  per length and a length-independent damage, the reads fall in ordered blocks with probability `n!^k / (k n)!` for
  `k` lengths, 1.3e-6 for 5 casts and 3 lengths); a length that keeps fewer than `m` casts is unmeasured, `m`
  the smallest integer with `m!^k / (k m)! <= 5e-4` per run, so at most 1e-3 per pair (voids and critical hits
  shrink the kept count; `k = 3` gives `m = 4`, 13824/479001600 = 2.9e-5, where 3 kept casts would pass a
  length-independent damage with 6.0e-4 per run, 1.2e-3 per pair).

Both keep the plain before/after judge: an entry's own reading (the hit count) is judged first and the option's
result is added to its explanation. Neither adds a metric, evidence class, tolerance or closing key; both read
existing harness metrics (`spell_damage_total`, `spell_damage_count` with `critical`, `resisted`, `blocked` filters,
`position_x/y/z`).

## Consequences

- An entry without either field generates byte-identical scenarios; finished classes 15, 19, 19 `--stack`, 23 and 27
  regenerate byte-identical.
- Seeded tests in `test_target_order.py` and `test_channel_lengths.py`; mutants: a reversed, flat or partly rising
  falloff, close distances (void), a missing strike, a flat or falling series across lengths, a missing read, a cancel
  that leaves the channel up (void, and every cancel failing reads unmeasured), length-independent damage with rising
  means (alert; a mean-only judge would pass it), 2 kept casts per length in ordered blocks (unmeasured).
- Felsworn: `707444 behaviour_metric_delta target_order` (Fel Fireball on 9 targets, 16 casts),
  `800206 behaviour_metric_delta target_order` (Carve end slash on 9 targets, 8 casts) and
  `800206 behaviour_metric_delta channel_lengths` (650 ms, 1400 ms and the full channel, 5 casts each).
- The server factor `max(0.2, 1 - 0.1 x rank)` (AscensionFelswornAbilities.cpp:238, AscensionFelswornAuras.cpp:237)
  reaches 0.2 at the 9th target, so its floor binds only from the 10th target struck, outside the 9 judged targets;
  the tooltip states no floor (owner question N-12, settled by Felsworn O-37 (2026-11-24) in Felsworn ADR 0031).
