# Heal cooldown cut (`behaviour_metric_delta`, `kind: "heal_cooldown_cut"`, ADR 0664)

ADR 0664 is a shared draft whose number is provisional and assigned at merge; its class half is Witch Doctor ADR 0002.

A fixed cooldown cut per heal event of a channel ("Effective healing done by Mojo Beam now reduces the cooldown of
Potion Toss and Splash Potion by 1 sec."), read through casts, as `cooldown_clear_time` does for minion events.
The spells of `learn`, `gated_spell` and `heal_spell` are learned and `setup_casts` are cast for real. Each arm:
- `gated_spell` is cast at the caster (its `cooldown_ms` must equal the DBC recovery), with its result, the game time
  and the heal reads;
- after the global cooldown, the caster's health is set to `health_pct` of a fixture maximum (a precondition fixture
  that keeps every heal effective), `heal_spell` is cast at the caster and cancelled after `heal_ms`;
- from `first_attempt_ms` to `last_attempt_ms` after the first cast, `gated_spell` is attempted every
  `attempt_step_ms` ms, each attempt with its result, the game time and the heal count.

The control arm runs before `talent` (default `spell`) is learned, the treatment after it; `cast_power` is set before
every cast. With `effective_only` (default true, for "Effective healing ..."), an ineffective arm follows, with the
talent kept: the caster's health is set to the full fixture maximum, so every heal is overhealing, and the attempts run
every 500 ms (or `attempt_step_ms` if larger). Generation refuses attempts that cannot hold the recast the stated cut
predicts from the heal ticks.

The judge, with the G-19 band b of `expected_cut_ms`:
- a refused priming cast, fewer than two heals, any overheal in the control or treatment arm, or any effective
  healing in the ineffective arm is `unmeasured`;
- a control or ineffective attempt that goes through alerts; one refused with anything but 67 (not ready) is
  `unmeasured`, since that refusal does not show the cooldown;
- in the treatment, the last refusal (which must read 67, not ready) and the first cast bracket the cut per heal,
  (cooldown - elapsed) / heals. Inside `expected_cut_ms` +- b is `ok`, wholly outside alerts, across an edge is
  `unmeasured`. With no cast, the last refusal bounds the cut from above; with the first attempt already cast, it
  bounds it from below; either alerts when that bound lies outside the band, else `unmeasured`.

Witch Doctor: Splash On 'Em 802219, Mojo Beam 500950 heals cutting Potion Toss 801661 and Splash Potion 802710.
