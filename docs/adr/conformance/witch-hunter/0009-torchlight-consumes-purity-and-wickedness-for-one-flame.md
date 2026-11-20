# 0009. Torchlight consumes Purity and Wickedness for one flame

- Status: accepted
- Date: 2026-11-15

## Context

Purity & Wickedness 680544 ends: "Torchlight can now consume these stacks to deal
${$681415m1+$681415ppl1+$sph*.25+$AP*.45} Holyflame or Shadowstrike damage to the target." Main-hand attacks apply
Purity 681413 and off-hand attacks Wickedness 681523, up to six stacks each; both are aura 271
(SPELL_AURA_MOD_DAMAGE_FROM_CASTER) at 2% per stack, Purity for Holy and Fire (MiscValue 6), Wickedness for Physical
and Shadow (MiscValue 33). The helpers are Holyflame 681415 (school 6) and Shadowstrike 681524 (school 32, rewritten
to 33 at load); all four spells are SpellFamilyName 21 with an empty class mask, so each aura amplifies the helper of
its own school only.

The Torchlight 503662 hit script cast one helper per stack type present, chosen by the type, with the amount
multiplied by the stack count, and removed each aura before casting, so the consumed stacks never amplified their own
hit. The custom amount also rolled the helper's 13 die sides once before the engine rolled them again.

Owner ruling O-24 (Q-wh-17): a Torchlight hit on a target with at least one Purity or Wickedness stack consumes all
stacks of both types and deals the tooltip amount once, as Holyflame or Shadowstrike chosen 50/50, amplified by the
stacks' own damage bonus. Mentor D-159: the roll ignores which types are present, and the hit is dealt before the
stacks are removed. Mentor D-160 approves the build.

## Options

- One helper cast, chosen by `roll_chance_i(50)`, with the unmultiplied amount, cast before both auras are removed;
  the base is `BasePoints + 1` so the engine's roll on the custom value is the only one.
- The same, keeping `CalcValue(player)`: the amount spreads over two rolls (mean +6).
- Restore the helpers' DBC remove-aura effect: it removes only its own type, at impact, after the amount is fixed.

## Decision

The first option, in `AscensionWitchHunterAbilities.cpp`. The helper's amount is fixed at launch
(`TRIGGERED_CAST_DIRECTLY`, `EffectSchoolDMG` in `SPELL_EFFECT_HANDLE_LAUNCH_TARGET`), so the 2% per stack of the
matching aura applies before the removal that follows in the same hit. No text change.

## Consequences

- One flame per Torchlight on a target with any Purity or Wickedness stack, 1028 + spell power x 0.25 + attack power
  x 0.45 plus a 0..12 roll, times 1 + 0.02 x the stacks of the matching type; both stack types are gone after the hit.
- Before the change, six stacks of each type gave two helpers of about six amounts each; after it, one amount at most
  12% higher.
- A target with only one stack type takes the other school's flame half of the time, without a bonus.
- Counted pair 20261115-204336 / 20261115-204420 (worldserver dc1a94859cc0): `witch-hunter-purity-flame-amount-o24`
  reads every plain helper mean ratio within 0.002 of its expectation (matching school over the other arm 1.02, 1.06,
  1.12; non-matching 1.000 at 1, 3 and 6 stacks), twenty Torchlights on 6 + 6 stacks remove both types and cast twenty
  helpers; `witch-hunter-purity-flame-split-o24` reads 510 / 472 Holyflame of 1000 and 1000 helpers in all; the
  reworded 3934 scenario reads one helper of 1089 / 1105.
