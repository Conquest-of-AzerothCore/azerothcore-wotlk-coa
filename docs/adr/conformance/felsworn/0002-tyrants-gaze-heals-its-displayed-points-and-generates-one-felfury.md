# 0002. Tyrant's Gaze heals its displayed points and generates one Felfury per damaged enemy

- Status: accepted (mentor D-17, option A for Felfury, 2026-11-23; heal under owner ruling Sun Cleric O-37 (2026-11-23, Sun Cleric ADR 0044))
- Date: 2026-11-23

## Context

Tyrant's Gaze 805240 (server Spell.dbc, Description[enUS]): "Damaging an enemy in this way heals you for
${$805241m1+$AP*.5} and generates 1 Felfury."

Server DBC set: 805241 Effect[0] HEAL, EffectBasePoints 145, EffectDieSides 1, EffectRealPointsPerLevel 3.0,
BaseLevel and SpellLevel 1, MaxLevel 0; Effect[1] TRIGGER_SPELL 800058 (Felfury), both on the caster. 805241 has no
ability row. The class code casts 805241 on the caster for every 805240 hit with damage
(`AscensionClassMechanics12To17.cpp`), so heal and Felfury come from the same spell, as the tooltip sentence says.

Class file pairs `prove/q2` and `prove/q3` (build 9f09b161bd0b) read, in four of four runs, Felfury 2 for one damaged
enemy and a 479-point heal at attack power 312 (10479 at 20312).

- Felfury: a second source, the resource rule `{14, 805240, 805240, 800058, 1, AuraStacks, EachSuccessfulDamagingHit}`
  in `AscensionCustomResourceData.h`, added one more stack on top of the 805241 trigger. Its only test was the table
  harness `resource_generation`, which drives `OnSpellHitResult` alone and never casts 805241. The Ascension live logs
  show +1 Felfury per single-target cast.
- Heal: stock `SpellEffectInfo::CalcValue` adds (60 - 1) x 3.0 = 177 because the player is the caster. The client
  shows a borrowed spell's points at its own skill rank
  ([ADR 0014](../../0014-level-scaled-tooltip-values-use-the-skill-rank.md)); without an ability row that is 146.
  Owner ruling Sun Cleric O-37 (2026-11-23, Sun Cleric ADR 0044): when a tooltip borrows a `$m` token without `ppl`, the server follows the displayed value.

## Options

- Felfury A: delete the resource rule; Felfury then comes only from 805241 Effect[1].
- Felfury B: clear 805241 Effect[1] in the class contracts and keep the rule. Rejected by the mentor: the rule also
  fires on a fully absorbed hit, where the heal does not, so heal and Felfury could separate.
- Heal: clear 805241 Effect[0] EffectRealPointsPerLevel in `AscensionFelsworn::ApplyContracts`, as for 803715 and as
  [Sun Cleric ADR 0044](../sun-cleric/0044-solar-eclipse-and-sunlight-follow-the-displayed-points.md) did.

## Decision

Felfury option A and the heal correction, both keyed to Felsworn spells (805240's own rule row, class 14; 805241,
SpellFamilyName 20). The engine is untouched. The `resource_generation` harness case of 805240 is deleted with the
rule.

## Consequences

- One damaged enemy: one heal of 146 + int(0.5 x AP) (302 at attack power 312, 10302 at 20312) and 1 Felfury.
  Each further enemy the chain damages adds one heal and 1 Felfury.
- A fully absorbed hit (damage 0) gives neither Felfury nor heal: the 805241 cast requires damage above 0. Before
  this change the rule still gave 1 Felfury there. No absorb fixture exists, so this is not tested.
- The `Generated()` consumers (706425 counter, 807438 extension, Felspill 706267) receive one generated point per
  damaged enemy instead of two.
- The harness `resource_generation` keeps its 805240-free cases; none of its remaining cases uses the
  `EachSuccessfulDamagingHit` branch. The behaviour is covered by the gameplay regressions
  `felsworn-tyrants-gaze-heal-and-felfury`, `felsworn-tyrants-gaze-heal-attack-power` and
  `felsworn-tyrants-gaze-two-enemies`.
- No client text change: the tooltip already shows the corrected values.
