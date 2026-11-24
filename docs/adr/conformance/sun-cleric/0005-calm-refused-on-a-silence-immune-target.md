# 0005. Calm is refused on a silence-immune target

- Status: accepted
- Date: 2026-11-22

## Context

Calm 804057, Spell.dbc text: "Calm an enemy, disarming their melee and ranged weapons for $d. If your target is an
Undead or Demon, they are also unable to attack or move for $807778d. Enemies that are immune to silence effects
cannot be affected by this."

Spell.dbc 804057 has Mechanic 0; its aura effects 67 `SPELL_AURA_MOD_DISARM` and 254
`SPELL_AURA_MOD_DISARM_OFFHAND` carry EffectMechanic 3 (DISARM). Only the trigger 807778 (pacify and root) carries
Mechanic 9 (SILENCE). The engine's mechanic immunity therefore refused 807778 and let the disarm land. Measured on the
counted pair verify-all 20261120-220240 / -220327 (server 6b19c29902): on Bloodmage Thalnos 4543, silence immune by
its creature template, the disarm aura 804057 was present after the cast (1, expected 0) and 807778 was refused.

## Options

- Read the sentence as covering the silence-mechanic part only: no change.
- Refuse the whole cast on a silence-immune target, through the Sun Cleric cast check.
- Change the Mechanic of 804057 in the DBC: client data.

## Decision

The whole cast is refused (owner ruling O-6, 2026-11-21: "Calm 804057: the whole cast is refused on a silence-immune
target. A Sun Cleric cast check in src/server/coa, no client data change. The ranged-disarm part stays unproven, not
asked."). The class's `OnSpellCheckCast` answers `SPELL_FAILED_IMMUNE` for 804057 when its unit target holds a native
SILENCE mechanic immunity, from a creature template or an aura.

## Consequences

- Nothing of Calm reaches a silence-immune target: no disarm, no pacify, no root, and Calm does not go on cooldown.
- The check is keyed to 804057 only. No other class lists 804057 or 807778, and no other code reads them.
- The ranged-disarm clause ("melee and ranged weapons", no `SPELL_AURA_MOD_DISARM_RANGED` effect) stays an unproven
  claim.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-calm-silence-immune.json`. Control: Brittlebones Skeleton
  201 is disarmed and pacified; Bloodmage Thalnos 4543, silence immune by its creature template (native effect-immunity
  query against 807778 effect 0), refuses the cast with `SPELL_FAILED_IMMUNE` and carries neither aura.
