# 1187. A cooldown reset rate can be counted from auto-attack hits

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Supplements [ADR 0603](0603-a-cooldown-reset-is-counted-from-its-clear-cooldown-packet.md) and
  [ADR 0720](0720-a-cooldown-reset-rate-can-pool-identical-cases.md)

## Context

Odyn's Vanguard 806699: "Melee attacks now have a $h% chance to reset the cooldown of Glorious Execution." DBC
ProcChance 20, aura 42, trigger 806700. The Sun Cleric handler rolls it on `damage && automatic && Chance(player, id)`
(`AscensionSunClericEvents.cpp:124`, `automatic` = `PROC_FLAG_DONE_MELEE_AUTO_ATTACK`) and its only effect is
`Reduce(player, 800626, INT32_MAX)` (`AscensionSunClericEvents.cpp:285`), a `RemoveSpellCooldown` that sends
`SMSG_CLEAR_COOLDOWN` of Glorious Execution 800626. Three designs failed: 806700 is never cast, `proc_reset` is
NotModelled, and `cooldown_reset_rate` rolls on a spell cast, not on a swing. Design: Sun Cleric designs-3 section 1;
mentor D-52.

## Options

- A `cooldown_reset_rate` option that swaps its casts for an auto-attack window: changes a shared kind and its step
  shape for every entry.
- A new kind module, the swing twin of `cooldown_reset_rate`, that reuses its packet read and pooled judge.

## Decision

The second option: `kinds/swing_reset_rate.py`. The scenario learns `reset_spell`, auto-attacks the dummy for
`control_ms`, stops, settles 1000 ms and reads the control marks, learns `talent`, attacks for `attack_ms`, stops,
settles and reads the treatment marks. Trials are `melee_damage_count` (damaging hits of both hands, as the handler's
`damage` requires); resets are `server_packets` opcode 0x1DE with `row` `reset_spell`. The judge and the pooled judge are
`cooldown_reset_rate_pooled_verdict`, unchanged. An entry whose swing bound (`parts` x the sum of
`attack_ms // speed_ms` over the equipped melee weapons) is below `band_trials_needed(chance)` is refused.

## Consequences

- No shared file, judge, tolerance or evidence row changes: both metrics already have their `EVENT` rows in
  `METRIC_EVIDENCE`, and the module carries none. Templar 19 (with `--stack`), Necromancer 23 and Witch Hunter 15
  regenerate byte-identical.
- Seeded tests: 2124 resets in 10618 landed hits pass, 1062 alert, a control reset alerts, fewer hits than the band
  are insufficient, a missing pooled part leaves the claim unmeasured, and a mutant that counts swing attempts
  (`melee_attack_count`) instead of landed hits alerts.
- Server mutants through `conformance.py mutate` cannot reach this roll: `Chance` reads the raw DBC ProcChance
  (`AscensionSunCleric.cpp:196`), so a `chance_of_success` spell modifier leaves it unchanged (code reading).
- The kind proves the auto-attack rate only. Whether melee abilities should roll too ("Melee attacks") stays an owner
  question (Q-4).
