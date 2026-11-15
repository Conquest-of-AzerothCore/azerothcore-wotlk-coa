# 0156. Light's Chosen's spell penetration lowers the target's resistance

- Status: accepted
- Date: 2026-11-11

## Context

Light's Chosen 301310 reads "Increases your spell power by $s1% of your Agility, your critical strike rating by $s2%
of your Intellect, and your spell penetration by $s3% of your Intellect." ($s3 = 10, EffectBasePoints[2] 9). Its
effect 2 (aura 23, every 5000 ms) triggers 301369, aura 123 `SPELL_AURA_MOD_TARGET_RESISTANCE` on misc 126 (the
magic schools), whose amount the Templar's aura script sets to 10% of Intellect. `Unit::GetEffectiveResistChance`
adds the owner's total of that aura to the victim's resistance (`Unit.cpp:2615`), so penetration needs a negative
amount, as beeg spellpen 823764 (-9999) and the Bloodmage's Forbidden Power (`AscensionBloodmageTalents.cpp`) carry.
301369's amount was positive: the trial measured Zealotry -6.0% and -6.6% at a level 60 dummy against the +7.5% that
33 penetration gives, and resist-free arms read the dummy's 60 Holy resistance raised to 93. The mentor decided on
2026-11-11 that this is a confirmed defect, with the tooltip as evidence, and approved the fix
(`method-study/owner-rulings-2026-11-10.md`).

## Options

- Read $s3 from 301310's effect 2 and negate the result. The line already reads $s3 from that aura effect, as its
  neighbours read their own DBC amounts; only the sign changes.
- Rewrite 301369's points in the Templar contracts. Rejected: the amount depends on the caster's Intellect, which only
  the aura script sees.

## Decision

`aura_ascension_templar_lifecycle::Calculate` (`AscensionTemplarAuras.cpp`) sets 301369's amount to
`-int32($s3 x Intellect / 100)`. Templar code only. `Unit::GetEffectiveResistChance` then clamps the resistance at
0 (`victimResistance = std::max(victimResistance, 0.0f)`, `Unit.cpp:2622`), so penetration above the target's
resistance gives no negative resist. The amount does not reach armor: `Unit::CalcArmorReducedDamage` reads the same
aura on the physical bit only (`Unit.cpp:2461`), outside misc 126.

## Consequences

- With Intellect 332 the penetration is 33: a level 60 dummy's 60 Holy resistance reads 27, a 5.4% average resist,
  instead of 93 and 18.6%.
- Regression, layer 1 (readback): catalog scenario `templar-lights-chosen-penetration-readback`, through the
  `spell_resist_chance` metric of ADR 0154: 12% without the talent, 5.4% with it on Holy and Shadow, 12% again after
  it. Layer 2 (behaviour): the conformance entry `301310` `spell_penetration` (Zealotry hit ratio, +7.5% expected);
  at about 160 trials per arm it cannot yet resolve the 5%-or-2-point tolerance, which needs about 1,100 trials per
  arm, so clause 47 stays "fixed, data conformant, behaviour pending" until pooled trials exist.
- No other aura in `src/server/coa` sets a positive amount on `SPELL_AURA_MOD_TARGET_RESISTANCE`.
