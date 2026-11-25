# 1242. Block grant trials judge the granted duration around the DBC figure

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor D-295 (lr1 tool note TN-3)
- Related: ADR 1216 (block_extension_trials and its grant mode), ADR 1221 (window shares)

## Context

Sunflare Aegis 707629: "Blocking attacks now has a $h% chance to grant you Hammer of Kings for
$/1000;712448s1 sec." The script rolls the 30% itself (`Chance()`, AscensionSunCleric.cpp:197) and grants through
`Extend(player, 804751, 4000)` (AscensionSunClericEvents.cpp:309, AscensionSunCleric.cpp:219-231), so the ADR 0588
spell-modifier forcing cannot make the grant certain. The grant mode read the aura once per trial with no game-time
stamps, so the "4 sec" claim had only the data label `707629 effect_value 712448e0 #1`.

## Decision

- Opt-in keys on `mode: "grant"`: `duration_spell`, `duration_effect`, `min_granted`, `residual_target`; only at
  block 100, without `chance_pct`, `control_trials` or `parts`.
- Expected duration: `duration_spell` Effect[`duration_effect`] from the DBC (712448 Effect[0], 4000 ms).
- Each trial reads `game_time_ms` right before and right after the strike, then the aura with stamps at 0.93 and 1.07
  times the duration after the strike. A granted trial is judged when both read ages, bounded by the strike stamps,
  lie in 0.9..0.965 and 1.035..1.1 times the duration (ADR 1221's shares, inside +-10%); it must read the aura on, then
  gone, else alert. A trial with no grant, a strike not blocked once, or an age outside its window is void.
- Fewer than `min_granted` judged trials is unmeasured. The kind refuses a `trials` below the smallest count at which
  fewer than `min_granted` grants come with probability at most `residual_target` per pair (two runs) at the
  talent's `ProcChance`: 47 trials for 5 grants at 30% and 0.1% (7.9e-4).

## Consequences

- Grant entries without the keys keep their scenario, model and verdict (`grant_tally` is untouched; the duration
  path has its own tally and verdict). Finished classes regenerate byte-identical (lr3 report).
- Tests (`kinds/test_block_extension_trials.py`): the scenario brackets the strike and reads at 3720 and 4280 ms; a
  grant on then gone is ok; mutants of the aura's own 12000 ms (still on) and of an early expiry alert; too few
  grants, read ages outside the windows or a wide strike bracket are unmeasured, never alert; the entry is refused
  below 47 trials, at block 0, with `chance_pct`, with control trials, or without its keys.

Addendum (lr4, mentor D-295 TN-3 condition 'windows excluding +-10%'): the shares are 0.905..0.965 and 1.035..1.095, so
the held window starts and the gone window ends strictly inside 0.9 and 1.1 times the duration (4000 ms: ages
3620..3860 and 4140..4380). A read age exactly at 3600 or 4400 ms is void, never judged. Test
`test_the_windows_exclude_a_duration_exactly_ten_percent_off`.
