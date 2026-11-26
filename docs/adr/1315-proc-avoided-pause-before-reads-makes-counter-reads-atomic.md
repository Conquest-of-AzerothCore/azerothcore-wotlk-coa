# 1315. Avoided-swing proc `pause_before_reads` makes counter reads atomic

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`800463` Void Reaver row 356)

## Context

In Cultist (class 25), Void Reaver `800463` (`trigger.action: "avoided"`, `strikers: 10`, `count_misses: true`,
`miss_exclusion: {"min_share": 0.04}`) experienced intermittent `unmeasured` voids in class-end pair 2 (`8037`
`melee_attacks_taken` vs `8029` `dodged + parried + missed`, `0` landed, `0` blocked) and in the 5-run rerun
(`7793` vs `7788` in Run 5 part 3).

`CoAGameplayTest::Progress` executes at most one step per world tick (`max_step_ms = 25 ms`). In `procs.py`,
`guard_steps`, `trial_steps` (`dodged`, `parried`, `missed`, `melee_attacks_taken`), and `event_steps` ran while
all 10 hasted strikers (`62531` + `2116852`, ~500 ms swing cadence) were still actively swinging. Whenever a volley
straddled the 3–4 ticks between reading `dodged` and reading total `melee_attacks_taken` (or `spell_cast_count`),
the reads were torn across different swing sets and triggered the ADR 1210 attack-balance void rule.

The ADR 1210 void rule itself is correct and must not be weakened: a torn read also biases `event_steps` against
`dodged`, and any genuine uncounted combat outcome must still void the part.

## Options

- Weaken the attack-balance void rule to tolerate small differences: rejected, because it would mask genuine
  uncounted swing outcomes and allow biased proc denominators.
- Pause all strikers unconditionally in `proc_avoided.py` / `procs.py`: rejected, because finished classes 14, 15,
  and 27 contain `avoided` proc entries whose generated scenarios must remain byte-identical.
- Add an opt-in boolean `pause_before_reads` to `proc_avoided.TRIGGER_FIELDS` using the existing ADR 1303
  `PAUSE_AURA = 56` (Stun, 3000 ms) pattern, freezing strikers before baseline counter reads, holding the pause
  across learning the passive, unpausing at the start of the main swing window, and pausing again after `drain`
  before guard, trial, attempt, and event reads. Chosen.

## Decision

Extend `proc_avoided.py` and `procs.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/proc-rates.md)):

- Add `'pause_before_reads'` (optional boolean, default `False`) to `proc_avoided.TRIGGER_FIELDS`, rejecting
  non-boolean values and rejecting `pause_before_reads: true` combined with `event_metric: "aura_stacks"`
  (`counts_stacks`, whose stack drain reads run before the pause and would tear against post-pause trial reads).
- Require instant/synchronous proc events when `pause_before_reads` is enabled (pausing runs after `drain`, so any
  swing during the striker pause rollout has no post-pause drain for missile or delayed procs; safe for Cultist
  `800463` whose proc `502133` is an instant `Speed = 0` self-buff counted by `spell_cast_count`).
- Add `PAUSE_AURA = 56`, `pauses_before_reads(entry)`, and `pause_steps(entry, on)` emitting
  `{'action': 'set_aura', 'actor': CASTER, 'target': striker, 'caster': striker, 'spell': 56, 'stacks': 1|0}`
  for each striker in `striker_ids(entry)`.
- In `proc_avoided.baseline_steps`, emit `pause_steps(entry, True)` immediately before the baseline counter reads
  (keeping strikers paused across `aura_steps` so no swing slips between baseline reads and learning the passive).
- In `procs.attempt_steps` (`is_avoided(entry)`), emit `pause_steps(entry, False)` at the start of the swing window
  and `pause_steps(entry, True)` immediately after `drain` before `guard_steps`, `trial_steps`, and the subsequent
  `event_steps`.
- Keep the ADR 1210 attack-balance void rule (`attack_imbalance`) untouched.
- When `pause_before_reads` is omitted or `false`, generated scenarios and rules are byte-identical.

## Consequences

- Opt-in per `avoided` trigger; zero C++ changes and zero diff on finished classes 13, 14, 15, 19, 23, and 27.
- All counter reads in an opted-in `avoided` proc (baseline and final guards/trials/attempts/events) execute while
  every striker is stunned for 3000 ms (well above the <= 200 ms read sequence), making `attacks_taken == dodged +
  parried + missed` deterministic.
- Cultist `800463` Void Reaver enables `"pause_before_reads": true`.
- Unit tests in `test_proc_avoided.py` verify pause/unpause step placement, byte-identical default output,
  boolean validation, and generate-time rejection with `event_metric: "aura_stacks"` (`counts_stacks`).
