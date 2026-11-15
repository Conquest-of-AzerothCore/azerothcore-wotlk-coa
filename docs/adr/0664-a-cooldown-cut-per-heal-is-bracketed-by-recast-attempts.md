# 0664. A cooldown cut per heal is bracketed by recast attempts

- Status: proposed (shared ADR draft; the number is provisional, assigned at merge)
- Date: 2026-11-15
- Class half: [Witch Doctor ADR 0002][class-half]

## Context

"Effective healing done by Mojo Beam now reduces the cooldown of Potion Toss and Splash Potion by 1 sec." states a
fixed cut per heal event. `cooldown_clear_time` (Necromancer ADR 0046) brackets a cut per event with recast attempts,
but its events are a raised minion's damage (`raise_spell`, `owned_creature_damage_count`). `cost_gate` with
`after_casts` tests one fixed reduction at fixed levels, while here the cut grows with the number of heals, which
depends on the channel's ticks. A `cooldown_ms` read is a readback (`coverage.METRIC_EVIDENCE`), not behaviour.

## Options

1. Generalise `cooldown_clear_time`'s event source (another contributor's module; editing it changes the Necromancer's
   generated output).
2. `metric_delta` on `cooldown_ms` with an expected gain of 1000 ms per tick: a readback, and the tick count varies.
3. A contributor kind module that stops the channel after a fixed time, so the heal count is fixed, and brackets the
   cut per heal from the last refused and the first accepted recast. Chosen.

## Decision

The contributor-owned kind `heal_cooldown_cut` (`CONF/kinds/heal_cooldown_cut.py`, ADR 0581;
[kind page](../../apps/coa-gameplay-test/conformance/docs/kinds/heal_cooldown_cut.md)):
- Arms: a control before the talent is learned and a treatment after it, each priming `gated_spell` with a real cast,
  then channelling `heal_spell` at the caster for `heal_ms` and cancelling it (`cancel_aura`), then attempting
  `gated_spell` every `attempt_step_ms`; each attempt reads `cast_failure`, `game_time_ms` and `spell_heal_count`.
  With `effective_only` (default), a third, ineffective arm keeps the talent and sets the caster to full health, so
  every heal is overhealing; its attempts (every 500 ms) must all be refused.
- Judge: the cut per heal lies between `(cooldown - elapsed) / heals` of the first accepted attempt and of the last
  refusal (which must read 67, not ready). Inside the G-19 band of the stated cut is `ok`, wholly outside alerts,
  across an edge is `unmeasured`. A control or ineffective attempt accepted inside the cooldown alerts; one refused
  with anything but 67 is `unmeasured`. The evidence is `cast_failure`, an event: the recast is consumed.
- Effective heals: in the control and treatment the healed unit's health is set low against a fixture maximum (a
  precondition fixture), and an arm whose heal total differs from its effective total is `unmeasured`. The
  ineffective arm tests the qualifier itself: an arm with any effective healing is `unmeasured`, and a recast inside
  the cooldown alerts, so a server that cuts on every heal fails.
- Generation refuses a stated cooldown other than the DBC recovery and an attempt window that cannot hold the recast
  the stated cut predicts from the heal ticks.

## Consequences

- A per-heal cut is proven through a consumed recast, without harness C++.
- A server that never stops the channel on `cancel_aura` reads more heals and an early recast: `unmeasured` (the
  first attempt already cast), not a false `ok`.
- `docs/behaviour-scenarios.md` (owner-owned) does not yet list the kind in its index; a tool note asks for the line.

[class-half]: conformance/witch-doctor/0002-gates-and-heal-cuts-run-on-dense-real-triggers.md
