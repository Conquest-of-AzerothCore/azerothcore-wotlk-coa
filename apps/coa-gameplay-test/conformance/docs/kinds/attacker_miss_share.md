# Attacker miss share (`behaviour_metric_delta`, `kind: "attacker_miss_share"`, ADR 1019)

A debuff that lowers an enemy's chance to hit ("reduces the target's chance to hit by 3%") is read on the swings the
enemies aim at the caster, never on the aura's amount or the unit's hit modifier. `attackers` (1 to 8, default 8)
aggressive, stationary attackers of `attacker_entry` (default the dummy entry, at the class level, 1M health, 3 yd)
melee the caster after one engaging swing each. Two arms of `arm_ms`, in whole cycles of `cycle_ms`, count
`melee_attacks_taken` (every swing) and `melee_attacks_taken` with `victim_state` 0 (a miss, `VICTIMSTATE_INTACT`):

- **control** first: no cast; the caster's health is set every cycle and `aura` is read on every attacker at each
  cycle end, where it must be absent;
- **treatment**: every cycle the caster's power is set (`base_mana` for a cost in percent of base mana), the cooldown
  of `cast_spell` is reset (a named precondition fixture, G-21 point 6, stated in the verdict) and `cast_spell` is
  cast at the first attacker. Counting starts `settle_ms` after the first cast, once `aura` from the caster is read on
  every attacker; the aura is read on every attacker again at each cycle end, where it must be held.

The aura is never set by the harness. Expected: the miss share rises by minus the amount of `aura` effect
`aura_effect`, which must be `SPELL_AURA_MOD_HIT_CHANCE` (54); `expected` must equal it. The judge sums swings and
misses per arm over every part and takes the difference of the shares in points against `expected`, with the
taken-outcome 99% normal interval and `bonus_status`: the band is the larger of 5% and 2 points, and a verdict needs
a half-width of at most half the band. Unmeasured: a missing part, fewer than 100 swings in an arm, a treatment aura
read 0 or a control aura read 1 on any attacker (the failing part is named), or a control share within `expected`
points of the 0 to 60% miss clamp (`Unit::MeleeSpellMissChance`).

`quote_spell` names the spell whose tooltip holds `quote` when the claim's tooltip embeds it (`@s:<id>:N@`); an
entry whose tooltip does not embed it is refused.

Refused: more than 8 attackers, arms that are not whole positive cycles, a cycle at or above the aura's duration, a
settle shorter than the cast, an aura effect that is not aura 54 or a stated value that differs from the DBC, a
percent-of-base-mana cost without `base_mana`, more than 10000 steps, or a wait over the accelerated cap.

The verdict stamps the metric `melee_attacks_taken`, already an event read in `coverage.METRIC_EVIDENCE`.

Sun Cleric: Sun Down 572752 (Solar Flare 807175 from the 572754 ground, claim "reduces the target's chance to hit by
$s1%"), label `572752 behaviour_metric_delta attacker_miss`.
