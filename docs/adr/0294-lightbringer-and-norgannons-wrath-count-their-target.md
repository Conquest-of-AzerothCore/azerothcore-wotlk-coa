# 0294. Lightbringer and Norgannon's Wrath count their target among their N enemies

- Status: accepted
- Date: 2026-11-12
- Decision by: the owner, status-5 question Q-ext2-2, option (a), "N in all", the target counts
  (method-study/owner-rulings-2026-11-10.md, "Owner rulings on the Templar status-5 questions")

## Context

Lightkeeper 560835's burst Lightbringer 561277 ("to up to $561277i1 enemies", MaxAffectedTargets 5) and Norgannon's
Wrath 524739's blast 524740 ("to up to $524740i enemies", MaxAffectedTargets 10) both strike TARGET_UNIT_TARGET_ENEMY
with TARGET_UNIT_DEST_AREA_ENEMY around it. The engine caps the area list at MaxAffectedTargets
(`Spell::SelectImplicitAreaTargets`, `RandomResize` after the script hook) and adds the explicit target on top. When
the random cap left the target out, a cast struck N others plus the target, N + 1 in all; otherwise N. The count was
5 or 6 (Lightbringer), 10 or 11 (Norgannon's Wrath) from cast to cast. 524740's Effect[1] (the 520842 debuff) shares
Effect[0]'s targets through its contract, so the debuff followed the same count.

## Options

1. Change the engine so the explicit target always takes a capped slot. Rejected: a shared engine edit for every spell.
2. A Templar `OnObjectAreaTargetSelect` hook on 561277 and 524740, which runs before the engine's cap: take the
   explicit target out of the area list and cap the rest at N - 1 plus the caster's
   SPELL_AURA_MOD_MAX_AFFECTED_TARGETS term, the term the engine adds. Chosen.

## Decision

Option 2. `spell_ascension_templar_ability::CountPrimary`, bound with `EFFECT_ALL` so that 524740's two effects keep
one selection (`Spell::CheckScriptEffectImplicitTargets` would split a hook that covers one effect and not the other).
The engine's later cap to N is then a no-op, and the total is the target plus N - 1 others: exactly N whenever N or
more enemies stand in range. Below the cap nothing changes. Bound by `spell_script_names`
(`rev_20261112_51_templar_area_counts_include_target.sql`).

## Consequences

- Regressions, each asserting every cast on its own (a snapshot before it, the count after it):
  - `templar-area-counts-include-target`: Lightbringer with 8 more dummies in range strikes exactly 5 enemies on each
    of 10 casts, the target once per cast; the control, a target with 2 more, strikes exactly 3 on each of 10 casts.
  - `templar-norgannons-wrath-counts-include-target`: 11 more dummies in range, exactly 10 enemies on each of 16
    blasts, the target once per blast. The harness admits twelve creatures, so its below-cap control is conformance
    entry 524739 `cap_control`.
  - The old code keeps the target in the random cap with probability 5/9 (Lightbringer) and 10/12 (Norgannon's Wrath)
    per cast, so a single run of it would pass with probability 0.3% and 5.4%.
- Conformance entries 560835 `fixed_count` `burst` (4 extras) and 524739 `cap`, `cap_cluster` (9 extras, per cast)
  read the stated count on every cast; `cap_control` stays 9.
- Gameplay change: the 520842 debuff of Norgannon's Wrath lands on 10 enemies in all, no longer up to 11.
