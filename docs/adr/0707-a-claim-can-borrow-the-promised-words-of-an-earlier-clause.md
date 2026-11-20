# 0707. A claim can borrow the promised words of an earlier clause

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Slayer's Mark 804068 (Witch Hunter) reads "and your critical strike chance against them by $s1%, increasing by $s1%
every $804073t1 sec". The ledger splits the sentence: the ramp claims ("increasing by $s1%", "every $804073t1 sec")
have passing `melee_crit_chance_against` metric-delta labels, but their own words do not name the state, so
`verdict_evidence` classes them as data (keys 353.0 and 353.1). Mentor decision D-158 (design D-3).

## Options

- A ledger field `promise_of` naming an earlier clause of the same spell, whose words join the claim's words for the
  state-promise match only, as `effectiveness_of` lends a buff's words (ADR 0268).
- Rewrite the ledger clause to repeat the subject: the ledger keeps the tooltip's own words.

## Decision

`promise_of`, the exact text of an earlier claim-entry clause of the same spell. Its words feed `promised_state` and
the contrast rows only; event promises and the claim's own words are untouched. A source that is not an earlier
clause of the spell, a non-text value or a non-claim entry is refused (`require_promise_sources`).

## Consequences

- Digests identical (coverage runs after compare). Necromancer final16 re-audit (20261114-084514 and -090752)
  identical to the archived coverage apart from the input paths; no Templar or Necromancer ledger entry names the
  field.
- Witch Hunter: pair 20261115-205112 / -205142, the ramp claims read behaviour, behaviour, behaviour; the same audit
  without the field reads data, data, behaviour.
