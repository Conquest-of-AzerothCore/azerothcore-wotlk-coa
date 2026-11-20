# 0782. A hit ratio can judge creature-type attack power on swings

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 296.2 (Unbroken 707407, "Increased further against Demons and Undead": the additional attack power
added to the player's hits against Demons and Undead) was unproven: 296.1 (ADR 0771) reads the 707487 Effect[1]
amount, not its effect on a hit. The stock melee rule adds `int(APbonus / 14 x attack time)` to a swing when the
victim's creature type is in the mask of a SPELL_AURA_MOD_MELEE_ATTACK_POWER_VERSUS (102) effect
(Unit::MeleeDamageBonusDone, Unit.cpp:11435 and :11447). The store behind the amount decays 5% every 2 s in combat.
Mentor decisions D-250 / D-251 (item T10, design B2 of the c15-tool2 report), owner delegation O-12.

## Options

- A `versus_creature_type` option of the `hit_ratio` swing mode: two dummies that differ only in creature type,
  the same strikes before every swing of both arms, per-swing reads of the attack power and the aura amount, a
  modelled difference judged with the existing flat-difference judge.
- A `script_hit` option: script_hit judges a script-cast spell against its tooltip, and its control arm is the same
  cast without the talent, not a second target.
- Fixing the aura amount by a `set_aura` fixture: makes the subject of the claim a fixture (G-21 point 6).

## Decision

The `hit_ratio` option, in `hit_ratio_versus.py`. Generate checks the aura effect is aura 102, reads its mask from
the DBC and refuses a treatment type outside it or a control type inside it; it spawns `dummy` (control entry),
`versus_dummy` (treatment entry) and the striker, adds the warm-up strikes, one strike (caster health set to 10000 of
10000) and the two reads before every swing, and the dummies' armor, level and magic resistance reads. The judge
refuses unequal dummy reads, shifts both arms' hits to their common mean attack power (attack power / 14 x weapon
speed x armor factor) and judges the per-hit difference against the count-weighted float32 `int(amount / 14 x weapon
speed)` of the counted treatment swings, times `1 - armor reduction` (mitigation.py) of the read armor.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the arms swing at their own dummy, 8 + 2 x trials strikes, the three creatures and every read are in
  the scenario, mask 36 and speed 2.8 s in the model; a control type in the mask, a treatment type outside it and a
  non-102 effect are refused, and malformed options are refused. Judge: the modelled difference is ok and an attack
  power drift between the arms is shifted out; mutants adding no or half the versus attack power alert; dummies that
  differ in armor are not judged.
- Assumptions stated in the contract: the drift shift takes the attack power share of a swing as `AP / 14 x speed`
  (no base or total damage percent on it), and the flat benefit is multiplied by no damage-done percent (no tuning
  or versus-percent aura on the caster); both are first-order terms of the small drift or would also scale the
  control arm.
- Witch Hunter: `707407 behaviour_hit_ratio versus_hits`, dummies 36 Harvest Golem (type 9) and 6133 Shade of Elura
  (type 6), both minlevel 11 with unit_class 1 and ArmorModifier 1, striker 418 Lesser Voidwalker, 2 pooled parts of 70 swings per arm (the dummy reads must also agree between parts).
