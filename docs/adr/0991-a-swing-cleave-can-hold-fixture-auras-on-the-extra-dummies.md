# 0991. A swing cleave can hold fixture auras on the extra dummies

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Rampaging Hounds 570726 ("melee attacks now cleave 1 additional nearby enemy.") is judged per landed hound swing by
`fixed_count` `swing_cleave` (ADR 0950). The cleave 567570 is a melee spell: its hit roll can miss, or be dodged,
parried or blocked, on the extra dummy, so an avoided cleave reads as a missing one (the earlier 25 of 28 gaps). The
f-m14 entries added an opt-in `dummy_auras` field without documentation or an ADR (review13 I1).

## Options

- Fixture auras on the extra dummies that turn avoidance and the miss chance off, each read back every phase.
- A tolerance for avoided cleaves: it would weaken an exact count and hide a partial cleave.
- Reading SMSG_SPELLLOGMISS per cleave: no such read exists; harness C++ (G-39).

## Decision

`swing_cleave` takes an optional `dummy_auras`, a list of objects with exactly `spell`, `effect` and `amount`. Each is
set by `set_aura` with that effect amount on every extra dummy only (never the primary or the far dummy) before the
attack, and its `aura_amount` is read at every phase moment. A read off its amount makes the check unmeasured, never
ok; the count judgement is otherwise unchanged. The fixtures are preconditions (guide 3.4, G-21 point 6): the subject,
the 570726 proc on each landed hound swing, is not set by the harness.

## Consequences

- Absent by default: entries without the field generate the same steps and model; Templar 19 and Necromancer 23
  regenerate byte-identical.
- Seeded tests in `test_behaviours.py` (`SwingCleaveTests`): the fixtures are set on the extra dummies only and before
  the attack; held fixtures keep the exact count; mutant: a fixture lost in the arm phase is unmeasured; unknown fields
  are refused.
- Witch Hunter: 570726 `rampaging_cleave` holds 984584 effect 0 at -500 (SPELL_AURA_ASCENSION_SUPPRESS_AVOIDANCE) and
  530014 effect 1 at 100 (SPELL_AURA_MOD_ATTACKER_MELEE_HIT_CHANCE). A fully blocked swing that carries no damage is
  still not seen (ADR 0950).
- The verdict names these fixtures (ADR 0992).
