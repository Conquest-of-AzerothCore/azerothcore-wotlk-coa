# 0012. Check passive effects by measuring with and without the passive

- Status: accepted
- Date: 2026-11-06

## Context

ADR 0011 checks the numbers of a class's spells against their client tooltips. A passive is never cast, so phase 1
gave each of the 145 Templar passives a `hit_mean` placeholder (`unmodelled: passive spell is never cast`) and read
its tooltip tokens against `spell_effect_value` only. That shows the record holds the number the tooltip shows, not
that the server applies it: a stat, a spell modifier or a damage bonus the server ignores, misreads or applies to
other spells passes unseen.

A naked level-60 reference character knows no class spell (ADR 0011), so learning one passive changes that
passive's quantities and nothing else. The 234 effects of the Templar passives fall into a few families by
`(Effect, EffectApplyAuraName)`; the harness already reads every quantity they change without combat
(`spell_modifier`, `stat`, `combat_rating`, `spell_damage_done`, ...).

## Considered options

1. Keep reading the record values only. Rejected: it cannot see what the server does with them.
2. Measure each passive against a second character that never learns it. Rejected: two characters differ in more
   than the passive (spawn, phase, fixtures), and every comparison would need both runs.
3. One no-combat scenario per passive: measure, `learn` the passive, measure again; judge the delta. Chosen.

## Decision

- D1. A passive is checked by the delta of its quantities in one no-combat scenario: the base steps, the "before"
  measurements, `learn` the passive, `aura` of the passive (`<passive> aura_present`, diagnostic), the same
  measurements again as "after". No `unlearn`: the reference character knows no class spell before the learn.
- D2. The family of an effect follows `(Effect, EffectApplyAuraName)` (P1 spell modifier, P2 stat sheet, P3 done /
  received, P4 taken, P5 proc / trigger, P6 scripted / crowd control, P7 power). An aura outside the table is
  `unmodelled: aura <n> has no passive measurement`, never an error.
- D3. The delta is deterministic: integer metrics take `max(1, 0.5% of |expected delta|)`, percentage-point metrics
  (crit, hit, parry and dodge chances) `max(0.01, 0.5% of |expected delta|)`, since a 1-point floor would accept 2 to
  4 for a 3-point bonus (owner answer Q1).
- D4. The expected value is the effect's own tooltip token, signed by the effect's own points. An effect without
  one takes a sibling effect's plain token when their displayed points are equal (owner answer Q2); otherwise it is
  `unmodelled`.
- D5. A spell modifier is measured on the spells the tooltip names (longest names first, resolved to their rank at
  the class level), else on the class mask's spells when the tooltip names their category, else a class file
  `passive_targets` entry decides; otherwise `unmodelled`. Mask spells that are not named are measured too, so a
  tooltip naming one spell while the modifier hits another is never `ok`.
- D6. A class-agnostic phrase vocabulary checks that the tooltip states the quantity the family measures; the
  source of a "% of your <stat>" effect is the stat the tooltip names. A generic "critical strike chance" judges
  melee crit and only reports spell crit.
- D7. Where the tooltip allows two readings (crit damage on the whole hit or on the bonus, a done percentage that
  multiplies or adds to the known modifiers), both are computed; disagreeing readings are `ambiguous_tooltip`.
  Haste has one reading, `divides` (owner answer Q5).
- D8. Passives no longer get the `hit_mean` placeholder; each passive effect gets its own expectations (check
  `passive_delta`, or `unmodelled` with the reason). Coverage comparisons leave the 145 phase-1 placeholders out of
  the "before" counts.
- A metric that needs a spell and has no target of its own (damage, critical damage, healing, a school cost) is
  measured on a reference spell: the first active class spell, at its rank for the class level, whose `SchoolMask`
  meets the effect's school mask and that has a school damage effect, a heal effect or a plain cost. Without one,
  the effect is `unmodelled` with that reason. A step the harness would refuse (a spell modifier op of 32 or more,
  an effect value of an effect the target lacks) is never generated: that pair is `unmodelled`.

## Consequences

- Every passive effect is either measured with and without its passive or `unmodelled` with a stated reason.
- The probe of 2026-11-06 (six Templar passives) showed the passive's aura on the character in the step right after
  `learn` and the stats updated by the next step, so the scenario needs no wait between them.
- A passive whose aura is absent after `learn` (weapon class, stance or caster aura requirement) is reported as
  `unmeasured` with those record fields, never as `ok` or `alert`.
- Healing passives of a class without a heal spell (Templar) stay `unmodelled` until a reference heal is chosen.
- Phase-2 decisions D9 to D19 (trigger entries, tooltip reader extensions, skill-scaled values) get their own
  records where they are structural; ADR 0011 stays as written.
