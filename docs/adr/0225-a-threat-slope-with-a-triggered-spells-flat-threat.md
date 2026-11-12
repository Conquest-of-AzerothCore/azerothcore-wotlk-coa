# 0225. A threat slope with a triggered spell's flat threat

- Status: accepted
- Date: 2026-11-12

## Context

Sacred Swing 572769, claim 206: "dealing $s2% High Threat Weapon Damage". `threat_slope` (Faith Guard) takes the
flat part from the hit spell's own SPELL_EFFECT_THREAT effects. Sacred Swing has none; its slow 301061, triggered on
each enemy struck, carries a flat 50. Its cast also needs its CasterAuraSpell 681170, which the threat-slope scenario
did not set, so the cast would fail.

## Decision

`threat_slope` takes `flat_spells`: the SPELL_EFFECT_THREAT points of each join the flat part. The scenario sets the
hit spell's required caster aura before the cast (`required_aura_steps`, empty for a spell without one). Faith Guard
generates byte-identical.

## Consequences

- Sacred Swing's slope is read with a flat of 50 against the Faith Guard convention of x2; it reads 2.25 (server data:
  spell_threat pctMod 2.25). The mentor set the claim part to status 5, owner question Q-r3a-1.
- Seeded tests: the flat includes 301061's 50 and the caster aura precedes the cast; a slope off the stated factor
  alerts.
