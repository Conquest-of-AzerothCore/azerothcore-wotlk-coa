# 0960. A summon proc can subtract a measured own-summon baseline

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claims 283.0 and 306.0 (Kennel Master 706365 and 707891, "Casting Unleash The Hounds now has a $h%
chance to summon an additional Lesser Shadow Hound for $707890d.") are a 25% and a 50% chance. The extra hound is
the same creature, Lesser Shadow Hound 50224, that Unleash the Hounds 807933 summons twice by itself (Effect[0] 28,
EffectBasePoints 1 + 1), and the script rolls the chance on the cast (AscensionWitchHunterAbilities.cpp:491-497). The
summon count of ADR 0351 (`owned_creature_summon_count`) cannot tell the extra hound from the two of the cast, and
its baseline arm treats any summon before the learn as an alert. 807933 also targets the caster, which the cast
trigger refused as "not cast at an enemy".

## Options

- A harness read that tells the summoning spell apart: harness C++ (G-39), not needed for a fixed count.
- Subtracting a count written in the class file: unmeasured, so a server summoning another base count would shift
  the rate unseen.
- Subtracting a per-cast count that the baseline arm measures in the same run.

## Decision

An opt-in procs field `events_baseline_per_attempt: N` (mentor D-332), on summon entries with `baseline: true` and
`trial_casts: true`. Each part's events lose N per completed cast of the trigger. The baseline arm (before the
passive is learned) must read exactly N per completed cast: an arm that was not counted or held no completed cast
leaves the rate `unmeasured`; any other count alerts; a part with fewer than N per cast after the learn alerts. Such
an entry may use a non-hostile, non-passive cast trigger, cast with the dummy selected (mentor D-335); every other
entry keeps the refusal. Entries without the field generate and judge as before.

Sizing for the two Witch Hunter entries follows D-261 as completed by D-335: residual_target 0.001 per pair,
min_detectable the larger of 10% of the stated rate and the band edge + 2 points, so 4 points for 25% (21% and 29%
excluded) and 5 points for 50%.

## Consequences

- Seeded tests in `test_minions.py` (`OwnSummonsPlanTest`, `OwnSummonsJudgeTest`): the subtraction is ok at the
  chance; an entry baseline of 1, an extra summon in the arm and too few summons with the passive alert; an empty arm
  is `unmeasured`; a self-cast trigger is refused without the field.
- A treatment cast that summoned one base hound fewer and one extra hound reads as no proc; only the arm and the
  per-part floor see a base-count change.
