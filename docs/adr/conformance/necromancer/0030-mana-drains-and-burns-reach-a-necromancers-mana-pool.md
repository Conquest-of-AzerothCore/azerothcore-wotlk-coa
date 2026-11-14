# 0030. Mana drains and burns reach a Necromancer's mana pool

- Status: accepted
- Date: 2026-11-13
- Split from ADR 0561 before publication (mentor ruling, 2026-11-13, local 14:26): this ADR keeps the drain ruling
  and its engine fix; the `metric_delta` field `enemy_player_class` its regression uses is
  [ADR 0561](../../0561-metric-delta-may-set-the-enemy-player-class.md) (shared).

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
- The fix is Necromancer-scoped gameplay in shared engine files: `src/server/game/Entities/Unit/Unit.h`,
  `Unit.cpp`, `src/server/game/Spells/Spell.cpp`, `SpellEffects.cpp` and `Spells/Auras/SpellAuraEffects.cpp`
  (commit a1e7beb358).

## Consequences

- Regression (class file, spell 504861): the Banshee channel and Mana Burn 8129 at an enemy Necromancer hit (its
  pool drops); controls: the channel at a mana creature and at an enemy Mage, Mana Burn at an enemy Mage (unchanged),
  Mana Burn at an enemy of class 17 (no mana pool) still refused. The controls set the enemy's class through
  `enemy_player_class` (ADR 0561).
- No Templar entry crosses the six gates (no Templar spell has Effect 8 / 62 or aura 62 / 64); the restoration
  predicate's behaviour is unchanged: the Templar restoration scenarios (energize, mana leech received, regen
  auras) passed 30/30 on the integrated build (run 20261113-125332; `c3-templar-restore-verdicts.txt` in the
  Necromancer conformance plan folder).
- A change to one of the shared engine files above reruns the gameplay selection of every finished class, not only
  the Necromancer's.
