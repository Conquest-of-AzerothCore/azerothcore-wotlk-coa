# 0288. Absolution taunts every enemy within its radius

- Status: accepted
- Date: 2026-11-12

## Context

Absolution 800424 reads "Taunt all enemies within 8 yds for $d and increase your movement speed by $520659s1%".
Its effect 0 is aura 11 `SPELL_AURA_MOD_TAUNT` on TARGET_SRC_CASTER / TARGET_UNIT_SRC_AREA_ENEMY, SpellRadius 14
(8 yd), and the DBC gives MaxAffectedTargets 5. `Spell` copies that cap from SpellInfo at construction
(`Spell.cpp:568`) and `Spell::SelectImplicitAreaTargets` trims the found targets to it at random when it is not 0
(`Spell.cpp:1405-1411`). Six engaged dummies inside the radius read five taunted and one not.

The owner ruled on 2026-11-12:
- Q-rad-2 (claim 279, option b): "all" sets no count cap, and the radius stays the limit;
- Q-rad-1 (option a): the engine's effective radius is known engine behaviour. For this spell that edge is 8 yd plus
  the caster's leeway (2.66 yd in run mode) plus the target's combat reach, about 11.935 yd for a training dummy
  (ADR 0253).

Reference search: the coabuildhub and sidekick snapshots carry the same "Taunt all enemies within 8 yds" text;
nothing found on a target cap.

## Options

- Clear MaxAffectedTargets in the Templar SpellInfo contracts. The Starcaller contracts do the same for 680774.
- Raise the cap to a large number. Rejected: it states a limit the ruling says does not exist.

## Decision

`AscensionTemplar::ApplyContracts` (`AscensionTemplarContracts.cpp`) sets 800424's MaxAffectedTargets to 0. Templar
code only; the engine is unchanged. The radius and its engine edge are unchanged.

## Consequences

- Catalog scenario `templar-absolution-taunts-every-enemy`: six rooted, engaged dummies at 2 to 7 yd all carry the
  taunt and turn to the Templar after one cast; the control dummy at 14 yd keeps attacking the ally.
- Conformance on the counted pair 20261112-080539 / 20261112-080809 (worldserver c2a0ba1b…), all ok in both runs:
  - `cap`: all six dummies at 2 to 7 yd taunted;
  - `edge`, now expected by the Q-rad-1 ruling: taunted at 11.5996 and 11.8496 yd, not at 12.0996 and 12.3496 yd,
    caster run speed rate 1;
  - `range`: 7.5 and 8.5 yd both taunted;
  - the 3 / 6 / 20 yd entry: 20 yd not taunted.
- The ledger row of 800424 carries the cap labels under "Taunt all enemies" and the edge labels under
  "within 8 yds".
- An Absolution in a large pull now taunts every enemy within the edge, not five of them.
