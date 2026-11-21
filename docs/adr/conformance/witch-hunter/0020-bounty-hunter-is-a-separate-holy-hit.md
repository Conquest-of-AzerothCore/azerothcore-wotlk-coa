# 0020. Bounty Hunter is a separate Holy hit

- Status: accepted
- Date: 2026-11-16

## Context

Bounty Hunter 805773 reads (server Spell.dbc Description, no `coa_client_spell_description` row): "Casting Darkslayer
or Witchbane now applies a stack of Bounty Hunter to you for $504478d, which can be consumed by casting Heartseeking
Bolt to deal an additional ${$504478m1+$504478ppl1+$SP*.45+$RAP*.3} Physical damage, stacking $504478u times."
Clause 393.0. The coefficients come from that text: 0.45 x spell power ($SP*.45) and 0.3 x ranged attack power
($RAP*.3) per stack, and a base per stack of $504478m1 + $504478ppl1. The token pair reads 299 + 3 = 302 at level 60;
the DBC chain (504478 Effect[0] EffectBasePoints 298 + EffectDieSides 1 + EffectRealPointsPerLevel 3 x (60 - 58))
gives 305, 1% higher and inside the band. Expected base per stack: the tooltip's 302, with 305 in band. Up to two
stacks (StackAmount 2).

The data chain: 504478 Collect Bounty is aura 231 PROC_TRIGGER_SPELL_WITH_VALUE with EffectTriggerSpell 504687;
504687 Collect Bounty is one SCHOOL_DAMAGE effect, BasePoints 0, SchoolMask 2 (Holy), DmgClass 3, family 21 flags
(0x4000000, 0, 0), EffectBonusMultiplier 0 and no `spell_bonus_data` row. The class code turned 504478 into a dummy
aura (`AscensionWitchHunterCompletion.cpp`) and folded the bounty into the bolt's own Physical hit in
`witch_hunter_casts::OnSpellCalculatedTarget`, with Shadow spell power and the bolt's damage bonuses. No 504687 event
existed; the bounty was extra Physical bolt damage.

Owner ruling O-30 (Q-wh-21, answer a): the bonus is a separate Holy hit, as on live. The archived live log 143
(2026-08-15) holds 15 SPELL_DAMAGE events of 504687 with school 2, each 0.15-0.7 s before a separate 807284 hit with
school 1, with their own crit flags and resists. The word "Physical" in the text is overridden by the ruling for the
school. Mentor D-354: (a) the $SP term reads the spell power of the hit's own school, Holy; (b) Silver Bolts 804026 no
longer shares the bounty (its class masks do not cover 504687).

## Options

- Cast 504687 with the bounty as its base points when Heartseeking Bolt consumes 504478, and drop the fold.
- Restore the stock PROC_TRIGGER_SPELL_WITH_VALUE route: it passes only the aura amount, without the RAP and SP terms,
  and needs a proc on the bolt's hit that the class code removed on purpose.
- Keep the fold and change its school: a Physical bolt event cannot carry a Holy school, crit roll or resist.

## Decision

The first option. The fold in `OnSpellCalculatedTarget` is removed. In `spell_ascension_witch_hunter_ability::After`,
the Heartseeking Bolt branch that already removes 504478 first casts Collect Bounty 504687 (triggered) on the explicit
target when it is alive, with bp0 = the 504478 amount (base x stacks, `SpellAuraEffects.cpp:659`) + (0.3 x ranged
attack power + 0.45 x Holy spell power) x stacks. No manual `SpellDamageBonusDone`: the engine applies 504687's own
done and taken modifiers once, with a spell power coefficient of 0. 504687 is not Heartseeking (word 1), so it gives
no rage and grants no stack. Witch Hunter code only; no engine, DBC or SQL change.

The cast sits in `After` (AfterCast), where the existing consume is: the fix note named `Hit`, but the 504478 removal
lives in `After`, and `After` reads the stacks before the removal. One consume per bolt, as before.

## Consequences

- Heartseeking Bolt 807284 is back to its O-15 hit, 926 + 1.1 x RAP + 0.3 x SP, with no bounty part. The rage the bolt
  gives (`RewardRage` on its own damage) drops with that damage. The order of the two hits is not asserted (the cast at
  AfterCast lands 504687 before the travelling bolt, as live).
- Silver Bolts 804026 no longer doubles a bounty part (ADR 0010, amended).
- Regressions in `classes/witch_hunter.json`: `805773 script_hit 504687 bounty_one`, `bounty_base`, `bounty_rap`
  (+1000 ranged attack power, QA Test 10031) and `bounty_sp` (+1000 spell power, ten stacks of QA Test 10062), the
  non-critical Holy hit against the tooltip at one and two stacks, partial resists removed (823764), no armor in the
  model (a Physical hit would read 8% low against the dummy's 528 armor); `805773 behaviour_hit_ratio bounty_bolt`
  (the bolt equals its control without 805773, 1.0; the fold read 1.56); `805773 behaviour_metric_delta
  bounty_one_event` (two stacks, one bolt, one 504687 event) and `bounty_consumed` (two bolts, still one event);
  `804026 behaviour_hit_ratio bounty_hit_undead` (504687 on an Undead target, 1.0 with and without Silver Bolts).

## Amendment (2026-11-16, mentor D-358, D-359): the bounty lands with the bolt's hit

The archived live logs hold no SPELL_MISSED row of Heartseeking Bolt 807284 (88 cast starts, 82 damage events;
log 143: 16 starts, 15 bolt damage events, 15 Collect Bounty 504687 damage events), so live gives no evidence of a
bounty on a missed bolt, and the text ties the bonus to the bolt's damage. The cast of 504687 moves from `After`
(AfterCast) to the bolt's hit:

- `Before` (BeforeCast) captures bp0 = the 504478 amount + (0.3 x ranged attack power + 0.45 x Holy spell power) x
  stacks, for a Heartseeking Bolt that is not triggered, as `After` did (same terms, same gate).
- A new `BeforeHit` handler casts 504687 (triggered) with that bp0 on the hit unit when the hit's miss info is
  `SPELL_MISS_NONE` and the unit is alive, once per cast. `BeforeHit` runs before the bolt's damage, so 504687 still
  lands before the bolt's own hit (as live, and as the AfterCast cast), and a bolt that kills still collects.
- The consume is unchanged: `After` removes 504478 whenever the cast consumed it, hit or miss.

Heartseeking Bolt has Speed 50, so its hit is always delayed past AfterCast; capturing at BeforeCast keeps the amount
read at the cast whatever the hit timing. A bolt that misses, is dodged, parried, evaded or immune by school (a miss
info other than `SPELL_MISS_NONE`) consumes the bounty without a 504687 hit. Damage immunity (aura 40) is resolved
after `BeforeHit` (`Spell.cpp` damage immunity check), so such a target receives the 504687 cast like any other hit.

The missed-bolt case is UNMEASURED: no existing fixture forces a miss of the bolt (class ratings hold hit at 10000;
partial school immunity is dropped on NPCs by design, owner ruling Q-c7-1; damage immunity is not a miss at
`BeforeHit`). The hit case is measured by the regressions listed above, unchanged.
