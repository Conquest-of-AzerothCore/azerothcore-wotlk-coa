# 0529. A player's display and active power types are read

- Status: accepted
- Date: 2026-11-13

## Context

The Banshee's channel 572211 (power burn 572212, mana leech) drains an enemy Orc Mage and every other CoA mana class
tested, but not an enemy Necromancer, whose mana pool (2803) stays full while the channel aura runs its 12 s.
Spell::EffectPowerBurn and AuraEffect::HandlePeriodicManaLeechAuraTick both return early unless
`HasActivePowerType(POWER_MANA)`. No harness metric read a player's power type.

## Decision

- Read-only harness metrics (G-39, reads): `power_type` (`getPowerType()`) and `active_power` (`HasActivePowerType(power)`,
  `power` 0..6, script hooks included). Runner validation requires `power` for `active_power`.

## Consequences

- Run 20261113-114501: the enemy Necromancer reads power type 6 (Runic Power), active mana 0, active Runic Power 1;
  the Orc Mage reads 0 / 1 / 0. This explains the channel's silence on Necromancer targets (fix note to the
  controller, nothing built).
- No gameplay path changes.
