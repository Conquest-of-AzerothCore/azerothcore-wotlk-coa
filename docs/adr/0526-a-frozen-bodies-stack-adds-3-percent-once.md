# 0526. A Frozen Bodies stack adds 3% once

- Status: accepted
- Date: 2026-11-13

## Context

Frozen Bodies 712434 (Spell.dbc): Effect[0] aura 108 SPELLMOD_DAMAGE +3% on Glacial Impact 707592's mask (word 2
268435456) and Effect[1] aura 108 SPELLMOD_EFFECT1 +3%. Both applied: one stack raised Glacial Impact from 855 to
905. The owner ruled (Q-ma-2, option (b)) a single +3% per stack, as the tooltip says; the mentor approved fix note
FN-own-11.

## Decision

- The Necromancer contract removes 712434 Effect[1]. The stack count read keeps working on Effect[0]'s aura.

## Consequences

- Regression (class file): `Frozen Bodies (one stack: Glacial Impact damage)`: before 855 (one impact without a
  stack), gain 880 = 855 x 1.03 = 880.65 truncated (SPELLMOD_DAMAGE applied once in SpellDamageBonusDone), tolerance
  1; the before phase is the control.
- Ten stacks drop from about x1.69 to x1.30 before the separate x1.5. Live agreed with the two-effect server; the
  owner may buff later (balance is out of scope, G-43).
