# 0994. A tooltip expression can end with one stray closing parenthesis

- Status: proposed (provisional number, numbered at merge); no consumer at HEAD
- Date: 2026-11-17

## Context

Witch Hunter Shadow Rage 680275 (cast by Unleash the Hounds 705463) states "Ranged auto attacks deal an additional
`${$m3+$AP*0.15)}` Shadow Damage." The expression holds one `)` without its `(`. The reader refused it, so the value had
no expected reading. The running client renders the same text as "72 Shadow Damage" (client check of the Witch Hunter
`fu` round), so the client drops the stray parenthesis instead of refusing the expression. Mentor decision D-396.
The pattern occurs in no Templar or Necromancer clause.

## Options

- Drop exactly one unmatched `)` that is the last character before `}`; every other unbalanced parenthesis stays
  unreadable.
- Ignore every unmatched `)`: no tooltip needs it, and a `)` inside the expression changes the grouping the author
  meant.
- Keep the expression unreadable and state the value in the ledger by hand: the value carries an AP term the reader
  computes from the caster, which a hand-written value would freeze.

## Decision

`Tooltip.evaluate` accepts the expression when the parser stops on a final `)` token that ends the expression text,
with nothing after it, not even whitespace. A second stray `)`, a stray `)` before other tokens, an unclosed `(`
and a trailing space after the `)` are unreadable, as before.

## Consequences

- Seeded tests: the stray-parenthesis expression reads the same value as its balanced form, alone and inside a
  tooltip; the other unbalanced shapes stay unreadable.
- Templar 19 and Necromancer 23 regenerate byte-identical (snapshot check of the source stage).
- Witch Hunter: when this ADR was written, 705463's Shadow Rage clause read `705463 effect_value 680275e2 #1` through
  this tolerance. Since aaef0332dc (`rev_20261117_02_witch_hunter_shadow_rage_rap_text.sql`, O-39) streams 680275 as
  `${$m3+$RAP*0.15}`, no clause at HEAD uses it: the tolerance stays, harmless and tested, with no consumer. A value with
  an AP or RAP term proves its base points only (D-57).
