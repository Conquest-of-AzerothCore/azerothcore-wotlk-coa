# 0287. Duty Calls raises Physical damage too

- Status: accepted
- Date: 2026-11-12

## Context

Duty Calls 705286 reads "Casting abilities that grant an Oath now increases your damage dealt and movement speed by
$560834s1% for $560834d, stacking $560834u times." (2% per stack, 5 stacks). Its buff 560834 has effect 0 aura 79
`SPELL_AURA_MOD_DAMAGE_PERCENT_DONE` with EffectMiscValue 126, the magic schools only. Weapon damage reads that aura
only when its mask holds the Physical bit (`Unit::UpdateDamagePctDoneMods`, `Unit.cpp:13535-13540`), and
`AuraEffect::HandleModDamagePercentDone` refreshes weapon damage only then. So white swings and weapon abilities such
as Righteous Lunge gained nothing: a counted pair read a main-hand swing at +0.4% / -0.3% at 5 stacks, against +10.0%
for a Holy Scourgebane hit.

The owner ruled on 2026-11-12 (question Q-r2a-1, claim 193, option b): "tout inclus", everything is included,
Physical too. Reference search: the coabuildhub and sidekick snapshots carry the same "damage dealt" text, with no
school named; nothing found on a school restriction.

## Options

- Give 560834's effect 0 all schools (`SPELL_SCHOOL_MASK_ALL`, 127) in the Templar SpellInfo contracts. One field;
  the amount, stacks and duration stay those of the DBC.
- Add a second Physical-only aura effect. Rejected: 560834 has a free effect slot, but two auras would stack as two
  multipliers per school and need their own amount handling.

## Decision

`AscensionTemplar::ApplyContracts` (`AscensionTemplarContracts.cpp`) sets 560834's effect 0 MiscValue to
`SPELL_SCHOOL_MASK_ALL`. Templar code only; the engine is unchanged. The same mask is already used in this file for
Keeping the Oath's absorb.

## Consequences

- At 5 stacks the Templar's main-hand weapon damage reads x1.10 (minimum 62.455 to 68.701 with item 2495 at level
  60), and Scourgebane's Holy damage x1.10 (800 to 880 of a 1000 base) as before (catalog scenario
  `templar-duty-calls-physical-damage`).
- Conformance: `705286 behaviour_hit_ratio damage_physical` reads +9.48% / +9.72% (ok, three pooled parts of 100
  swings, 99% half-width about 0.7 points) on the counted pair 20261112-080132 / 20261112-080209; `damage_holy`
  (+10.00%) and `speed` (1.02) are the unchanged-part controls.
- After review (rule 4 amendment point 6), the stacks come from the talent itself. The damage arms learn 705286 in
  the treatment arm only (the hit-ratio arm `learn` field). Both arms cast five Oath-granting Righteous Lunges before
  their first read and one before every read; the physical arm is five parts of 60 swings. The catalog scenario
  reads the five-Lunge control without the talent, then 5 stacks with it.
- On the counted pair 20261112-084520 / 20261112-084607 (worldserver 4d20e7ca…, commit 21e6485e36):
  `damage_physical` +10.08% / +9.97% (99% half-width 0.53), `damage_holy` +10.00% / +10.00%, both ok.
- Physical abilities and white swings gain up to 10% while Duty Calls is stacked.
