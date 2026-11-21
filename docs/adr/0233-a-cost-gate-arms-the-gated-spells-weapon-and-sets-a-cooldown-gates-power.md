# 0233. A cost gate arms the gated spell's weapon and sets a cooldown gate's power

- Status: accepted
- Date: 2026-11-12

## Context

Radiance 706318, claim 230: "Reduces the Energy cost of Vindication by $s1." Vindication 573324 needs a one-hand weapon
(EquippedItemSubClassMask 41105), and the cost gate equipped the reference two-hand staff, so every arm read
SPELL_FAILED_EQUIPPED_ITEM_CLASS (29) and judged nothing. Other kinds already arm the spell they cast
(`values.armed_for`). Two Oath Breaker gates of Blessed Strikes 704180 (Blade Tempest 8054099, Righteous Tempest
807274) cast a 3-5 s self aura, and the next arm's attempt read SPELL_FAILED_SPELL_IN_PROGRESS (105). Justicar of the
Light 707663's cooldown removal is tested on Benediction 578276, whose cost the same talent raises from 20 to 30, so
the plain-cost power fixture of a cooldown gate refused the talent arm for power (85).

## Decision

- `cost_gate_scenario` arms the class file for `gated_spell` (`armed_for`): an alternate weapon replaces the reference
  one only when the reference does not fit the spell's equip requirement.
- `arm_wait_ms` (default 0) lengthens the global-cooldown wait before every arm.
- `cast_power` (cooldown gates only) sets the caster's power to that value before each cast in place of the plain cost.

Entries without them regenerate byte-identical (1666 of 1666 scenarios at the time).

## Consequences

- Radiance on build 2a99d5b855eb: Vindication with the one-hand mace 2259: refused at 30 Energy without the talent
  (85), through with it (0), refused at 29 (85), both runs (20261112-031521 / -031601).
- Blade Tempest and Righteous Tempest with `arm_wait_ms` 5500: refused, through, refused one point below.
- Seeded tests: Radiance's scenario equips the alternate weapon and a 29 reading alerts; a gate the reference weapon
  fits keeps it; the arm wait reaches every arm; `cast_power` on a power gate is refused.
