# 0561. Mana drains and burns reach a Necromancer's mana pool

- Status: accepted
- Date: 2026-11-13

## Context

The Banshee's channel 572211 (power burn 572212, mana leech) did nothing to an enemy Necromancer, whose mana pool
(2803) stayed full: a Necromancer's active power is Runic Power (`power_type` 6, ADR 0529), and every mana drain and
burn path requires mana as the target's active power (`HasActivePowerType`). The owner ruled (Q-c3-1, relayed by the
mentor, 2026-11-13) that every mana drain and burn of every class must work against a Necromancer. Class check (run
20261113-120413, `max_power` / `power_type` / `active_power` on every class 12-32 at level 60): only the Necromancer has
a mana pool with a non-mana active power; the other mana classes have mana active, the rest have no mana pool.

## Decision

- `Unit::HasNecromancerManaPool(power)` (a player Necromancer and POWER_MANA) is the one Necromancer mana predicate;
  `Unit::CanReceivePowerFromSpell` (restoration) uses it in place of its own copy, and the new
  `Unit::CanLosePowerToSpell(power)` (`HasActivePowerType(power)` or that predicate) replaces `HasActivePowerType` at
  the six drain / burn gates: Spell::EffectPowerDrain, Spell::EffectPowerBurn,
  AuraEffect::HandlePeriodicManaLeechAuraTick, AuraEffect::HandlePeriodicPowerBurnAuraTick, and Spell::CheckCast for
  power burn / drain effects and for the periodic mana leech aura (player casters).
- Scoped to the Necromancer (the class check above); no other unit gains a drainable pool.
- The regression's controls need an enemy player of another class: `metric_delta` takes `enemy_player_class`
  (requires `enemy_player_race`; omitted, the enemy keeps the class file's class and the scenario is unchanged).

## Consequences

- Regression (class file, spell 504861): the Banshee channel and Mana Burn 8129 at an enemy Necromancer hit (its
  pool drops); controls: the channel at a mana creature and at an enemy Mage, Mana Burn at an enemy Mage (unchanged),
  Mana Burn at an enemy of class 17 (no mana pool) still refused.
- Seeded tests (EnemyPlayerClassTests): the class is set on the enemy, kept without the field, refused without a race.
- No Templar entry crosses the six gates (no Templar spell has Effect 8 / 62 or aura 62 / 64); the restoration
  predicate is unchanged in behaviour.
