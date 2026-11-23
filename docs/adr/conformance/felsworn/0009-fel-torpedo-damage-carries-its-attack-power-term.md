# 0009. Fel Torpedo's damage carries its attack power term

- Status: accepted (mentor D-56, 2026-11-23)
- Date: 2026-11-23

## Context

Fel Torpedo 500610 (server Spell.dbc, Description[enUS], shown in the spellbook and through `@s:500610:0` on the talent
card of 520853): "Torpedo forward in the direction you're running and deal ${$500761m1+$500761ppl1+$AP*.35}
Shadowflame Damage to enemies in your path." The lab client renders 304 at level 60 and attack power 312
(194.6 + 109.20). The helper texts of 500761 and 500762 carry the same `$AP*.35`, and the bindmysoul talents snapshot
reads "deal 195 + 35% AP Shadowflame Damage".

Server DBC set:

- 500610 Fel Torpedo, Effect[2]: aura 23 `SPELL_AURA_PERIODIC_TRIGGER_SPELL`, amplitude 250 ms, trigger 500761,
  duration 500 ms.
- 500761 Fel Torpedo, Effect[0]: `SPELL_EFFECT_SCHOOL_DAMAGE`, BasePoints 74, DieSides 5, RealPointsPerLevel 4.6,
  BaseLevel 34, radius 3 yd, SchoolMask 36, EffectBonusMultiplier 0.

At level 60 the engine's `SpellEffectInfo::CalcValue` gives 74 + int(26 x 4.6) + 1..5 = 194-198. No path added an
attack power term: 500761 had no `FelswornCoefficients` row, no `spell_bonus_data` row, and no class spell modifier
of `SPELLMOD_AP_COEFFICIENT` (32, 42) reaches its family mask (SpellFamilyName 20, SpellFamilyFlags[2] 0x2000000;
the only modifiers on that mask are Doomstride 706818 `SPELLMOD_ALL_EFFECTS` and Legion March 805244
`SPELLMOD_CRITICAL_CHANCE`).

Measured on the pre-fix server (fw-t4, runs 20261123-185607 and 20261123-185756), caster level 60, resistance remover
823764 on the caster, the caster returned to the same spot before every trial: 196.17 per hit at attack power 312 and
196.42 at 1312. The damage is flat in attack power.

## Options

- Add a row for 500761 effect 0 to `FelswornCoefficients` with attack power coefficient 0.35. The table is read by the
  class's `felsworn_scaling::ModifySpellEffectBaseValue` hook, which adds `ap x GetTotalAttackPowerValue(BASE_ATTACK)`
  to the effect's base value before the engine truncates it, as the class's other attack power rows do.
- A `spell_bonus_data` row with `ap_bonus` 0.35. Rejected: the class carries its coefficients in its own table, and a
  second channel invites a double application.

## Decision

Add `{500761, 0, 0.35f, 0, 0, 0, 36}` to `FelswornCoefficients` (effect 0, attack power 0.35, no spell power,
stamina or agility term). The last field is the school mask the hook reads for a spell power term; 36 (Fire and
Shadow, Shadowflame) matches 500761's SchoolMask and the class's other Shadowflame rows, and it has no effect while
the spell power coefficient is 0.

## Consequences

- Each Fel Torpedo hit deals 194-198 + 0.35 x attack power at level 60 (303-307 at attack power 312), the sum
  truncated once. Doomstride's `SPELLMOD_ALL_EFFECTS` and other effect modifiers now scale the attack power term too,
  as they scale the rest of the value.
- Only 500761 effect 0 is keyed. No other class reads 500761: no other source, data or class file in the repository
  names it (the only other mention is its `spell_threat` row), and its family flags match none of the class's `Named`,
  `Twin` or `Rush` predicates. No engine file changes; no SQL, DBC or client text change.
- Regressions: the `script_hit` entries `500610 script_hit 500761 torpedo_hit` (attack power 312) and
  `torpedo_hit_ap` (the same with attack power fixture 10031, +1000), both with a control arm that makes no cast and
  must count no 500761 hit. The pair of arms moves by 0.35 x 1000 = 350 per hit, which a flat damage cannot meet.
- One cast lands two hits on one dummy (the initial tick and one 250 ms tick before the dash leaves the 3 yd radius).
  The tooltip states no hit count, and 500761's Debuff Dummy 500762 has no server handler. This is recorded as an
  open lead, not changed here.
