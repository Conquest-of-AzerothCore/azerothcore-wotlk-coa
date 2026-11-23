# 1123. A strike miss share reads that no strike lands on the caster

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0153 (`taken_hit`), ADR 0997 (`attacker_attempts`)

## Context

Slither 500947 says the caster's "chance to be hit by ranged attacks and spells is reduced by 100%" (806295, aura 186
misc 126 and aura 185, -100) and that it cannot attack or cast. `taken_hit` judges landed strikes and needs half its
trials landed; its `resist_rate` judges a difference of points, and no judge reads an absolute share of zero (tool
note P-T3). The metric_delta striker carries `spell_hit_bonus` 100, which would offset the aura.

## Decision

A contributor kind module `strike_miss_share`: a passive striker without a hit bonus casts a strike at the caster in
bursts; control bursts without the trigger must land at least a stated share, treatment bursts right after a real
trigger cast (its aura read on after each burst) must land none; sent strikes are SPELL_GO counts, landed ones damage
logs. An optional `refused` part reads a spell attempt (refused with a stated code) and an auto-attack (no swing) under
the trigger against the same attempt allowed in the control. The metrics are event class.

## Consequences

- A new kind: no other entry changes; classes 19 (with and without `--stack`) and 23 generate byte-identical
  scenarios.
- Witch Doctor 500947 `slither_spell_miss` (696 treatment strikes of Light of the Naaru 41394, sized against the
  engine's 1% least magic hit chance) and `slither_ranged_miss` (Cannon Shot 92522, which reproduces the 60% ranged
  miss cap of `MeleeSpellMissChance`, candidate defect lead L-c11-c1).
