# 1135. An extension row adds no stated value to an effectiveness subject

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0268 (effectiveness_of)

## Context

Loa Empowerment 706368 "increases the effectiveness of Power Wuju by $s2%" names Power Wuju 707676. The subject's
"@ext:Can only have 1 Wuju active on a target at a time.:ext@" row carries the literal 1, so the subject stated two
values and the subject words were dropped (tool note T-b18-2): the attack-power read `706368 ap_effect` counted as
data.

## Decision

`coverage.subject_claims` leaves out a subject entry whose whole clause is one `@ext:...:ext@` extension text, from
both the value count and the added words.

## Consequences

Audit only; generation is untouched. The only other effectiveness subject (Templar Gift of Zeal 300923) has no
extension row, so Templar coverage is unchanged.
