# 0044. Solar Eclipse and Sunlight follow the displayed points, without the per-level term

- Status: accepted (owner ruling O-37, mentor D-305 option a: both halves applied, 2026-11-23)
- Date: 2026-11-23

## Context

Two Sun Cleric tooltips borrow the points of a foreign spell with a `$<id>m<n>` token and no `ppl` token:

- 704929 Solar Eclipse: "dealing ${$704931m2+$sph*0.125+$AP*0.1} Holy damage to nearby enemies."
- 92136 Sunlight: "Fulfilling your Vow now unleashes Sunlight restoring ${$704911m1+$BH*0.15} health to up to
  $704911i allies within $704911a1 yds"; 500209 Sunlight carries the same `${$704911m1+$BH*0.15}`.

Server DBC set (`coa-dbc-viewer`):

- 704931 Effect[1] SCHOOL_DAMAGE, EffectBasePoints 21, EffectDieSides 2, EffectRealPointsPerLevel 1.0, SpellLevel and
  BaseLevel 27, MaxLevel 0. Effect[0] (aura 54, the Heat Death debuff) has EffectRealPointsPerLevel 0.
- 704911 Effect[0] HEAL, EffectBasePoints 24, EffectDieSides 7, EffectRealPointsPerLevel 1.0, SpellLevel and BaseLevel
  10, MaxLevel 0.

The client displays a foreign spell's points at that spell's own skill rank
([ADR 0014](../../0014-level-scaled-tooltip-values-use-the-skill-rank.md)). Neither spell has an ability row, so the
rank is 0 and the display has no per-level term: 22..23 for `$704931m2` and 25..31 for `$704911m1`. The owner read
Solar Eclipse on the level-60 client: 52 = 22 + 0.125 x 96 + 0.1 x 182 (O-37).

The server added the per-level term. The class code casts 704931 (`AscensionSunClericAuras.cpp`, expiry of 704930)
and 704911 (`AscensionSunCleric.cpp`, `Fulfill`) with the player as caster, so stock `SpellEffectInfo::CalcValue`
(`SpellInfo.cpp:479-497`) adds `(60 - 27) x 1.0 = 33` and `(60 - 10) x 1.0 = 50`. Ledger readings before the fix:
Solar Eclipse 55..56 + 7 = [62, 63] at the reference attack power (pair 20261120-221023 / 20261120-221237, held for
the owner as D-292), Sunlight (75..81) x 0.8 = 60..64 (held as D-293).

Owner ruling O-37: when a tooltip borrows a `$m` token without `ppl`, the server follows the displayed value.

## Options

1. Clear EffectRealPointsPerLevel on 704931 Effect[1] and 704911 Effect[0] in the class contracts, as the
   Chronomancer does for Oblivion and Rapid Acceleration (`AscensionChronomancerTime.cpp`) and the Felsworn for 803715
   (`AscensionFelswornContracts.cpp`).
2. Cast the two spells without the player as caster. Rejected: the spell power, attack power and healing power
   terms of both tooltips come from the caster.
3. Keep the per-level term and correct the client text. Rejected by O-37.

## Decision

Option 1, in `AscensionSunCleric::ApplyContracts`, keyed to the two Sun Cleric spell ids (SpellFamilyName 33). The
engine is untouched. 704931 Effect[0] is not touched, so Heat Death 704932 (`$704931s1%`) keeps its reading.

## Consequences

- Solar Eclipse deals 22..23 + 0.125 x Holy spell power + 0.1 x attack power: [29, 30] at the reference attack power
  70, [2029, 2030] with 20000 more attack power, [1279, 1280] with 10000 spell power.
- Sunlight heals (25..31 + 0.15 x healing power) x 0.8, truncated: [20, 24] at healing power 0, [2420, 2424] with
  20000 more spell power. The x 0.8 is the general class heal tuning 887015 "CoA Aura - Sun Cleric Class"
  (`AscensionClassTuning.h:36`, `{ 887015, 27, 0 }`, Effect[2] aura 136 -20% at level 60), accepted for the class in
  [Sun Cleric ADR 0028](0028-lights-of-absolution-restores-on-solar-flare-damage.md) and
  [ADR 1243](../../1243-a-listed-heal-pct-term-adds-the-read-percent-of-maximum-health.md), like the Templar twin
  887007. Whether the client applies aura 136 to the displayed Sunlight value is not verified: no client reading of
  Sunlight exists.
- Class file entries updated to the rule: 704929 `damage`, `damage_ap`, `damage_sp`; 92136 `sunlight_heal`,
  `sunlight_bh`; 704562 `control_fulfilled`. Their control arm is the phase before the learn (0). Ledger rows of
  92136 (Sunlight heal) and 704929 (Solar Eclipse damage) count after the fix. The hit_ratio entries that read
  Sunlight heals at 20000 spell power are ratios and keep their expectations.
- 500209 has no ledger row and no class file entry; it follows the same rule through 704911.
