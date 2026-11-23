# 1022. A peaceful-only resurrection is read out of combat and refused in combat

- Status: proposed (draft, Witch Doctor cycle 10 task T; provisional number, renumbered at merge, guide 14.4)
- Date: 2026-11-21
- Builds on: ADR 0537 (cast_combat resurrect amounts), ADR 0581 (kind modules)

## Context

Reclaim Soul 803624 reads "Brings a dead ally back to life with $s1 health and $q1 mana. Cannot be cast when in
combat." It carries `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL`, so `Spell::CheckCast` refuses it in combat with
`SPELL_FAILED_AFFECTING_COMBAT` (`SpellInfo::CanBeUsedInCombat`). `cast_combat` always attacks the dummy first and
expects the cast to go through (ADR 0537), so its resurrect amounts cannot be read for this spell and the refusal
cannot be stated (tool notes of clauses 459, 460 and 461: "an out-of-combat resurrect amounts read" and "a
cast_combat expect_refused result code with the out-of-combat control arm").

## Options

1. Add `in_combat: false` and `expect_refused` to `cast_combat` (`behaviours.py`, owner-owned).
2. A kind module with both arms in one scenario.

## Decision

Option 2, kind `peaceful_resurrect` (`kinds/peaceful_resurrect.py`, page `docs/kinds/peaceful_resurrect.md`), check
`behaviour_cast_combat` (behaviour class). The dead ally answers once with no offer (stays dead); out of combat the
cast completes, the ally accepts and is read alive with the effect's health and mana (regeneration off); the ally
dies again, the caster attacks the dummy and the same cast is refused with 1; the ally's answer finds no offer. The
out-of-combat arm runs first because the harness keeps a spell's last refusal reason. One label per claim
(`health`, `mana`, `refusal`), each judged exactly on its own readings. A spell without the attribute or without a
resurrect effect is refused at generation.

## Consequences

- Generated scenarios of classes 13, 15, 19 and 23 are byte-identical with the module and without its entry; the
  Witch Doctor class file gains one entry (one scenario, three labels).
- The `refusal` label needs both arms, so a server that allows the cast in combat and one that refuses it everywhere
  both alert.
- Seeded tests in `kinds/test_peaceful_resurrect.py`.
