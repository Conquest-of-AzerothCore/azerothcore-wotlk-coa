# 1051. An ally can interact with a creature the trigger leaves

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Sun Gate 802161 (ledger rows 327 claim 2 and 328): "This leaves behind a Sun Gate for $d that allies can
interact with to blink themselves the same distance forward. Allies can only use Sun Gate every $802148d." The gate
50331 answers a gossip hello (`npc_ascension_sun_gate::sGossipHello`, `AscensionSunClericSummons.cpp:106-117`): a
grouped, friendly player within the interaction distance and without 802148 casts 802145 (the 25 yd blink) and
802148 (the 90 s lockout) on itself. The `metric_delta` frame could not make an ally interact. Mentor ruling D-216.

## Options

- A harness action for the interaction: not needed, `gossip_hello` with `entry` exists.
- A new kind: duplicates the with/without frame and the ally fixtures.
- An opt-in `metric_delta` option that emits existing steps (`gossip_hello`, `relocate`, `reset_cooldown`,
  `set_power`) at the phase and after-trigger points, and judges the ally's displacement like the `displacement`
  option.

## Decision

The option `ally_interact` (`metric_delta_options/ally_interact.py`, ORDER 27, after `ally_arm` and `ally_offsets`).
The blink form reads the ally's position around the interaction and replaces the judged readings with the 2D
displacement (`run_values`), with an optional bearing. The lockout form places three tries from the DBC duration of
the lockout aura (0.9 and 1.1 times it after the first), moving the caster and the ally back after each blink so
every gate stands 3 yd from the ally. A calibration read (throwaway probe, never counted) confirmed that a
`gossip_hello` within 5 yd does not walk the player.

## Consequences

- Absent by default: no finished-class entry writes it; the finished classes regenerate byte-identical.
- Seeded tests (`metric_delta_options/test_ally_interact.py`): parse, the read placement, the try times at 81 s and
  99 s, the refused `expire_ms`, refusals, a 25 yd forward blink passing and short, backward or missing blink
  mutants alerting, and shorter and longer lockout mutants alerting.
- The ally's `aura_apply_count` of 802145 is a judged arm (the interaction landed); `spell_go_count` on an ally is
  refused by `ally_arm`.
