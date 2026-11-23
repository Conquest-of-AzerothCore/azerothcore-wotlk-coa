# 1009. A party pulse near member can stand beyond the radius, up to a stated limit

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-17
- Builds on: ADR 1001

## Context

Owner ruling O-47 (mentor D-482, card Q-wh-47, answer a) keeps the Witching Idol 804051 reach at 22.5 yd: the 20 yd
radius of 853203 plus the idol's 1.0 and the player's 1.5 combat reaches. ADR 1001 requires `near_distance` inside the
radius, so a member at 21 yd, inside the ruled reach, is refused. Mentor D-484 approved the change (category A:
judging unchanged).

## Options

- Optional `party_pulse` fields `near_limit` (upper bound of `near_distance`, default the radius) and `note` (text
  appended to the contract).
- Relax the check for every entry: changes what other entries accept.

## Decision

The first option. `near_limit` must be at least the radius; `near_distance` must lie below it; the far member
(radius + `far_margin`) must lie beyond it. Labels, model and judge are unchanged.

## Consequences

- Absent by default: the generated scenario is unchanged; Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: members at 21 and 24 yd, a 22.5 yd pulse is ok, 20 and 25 yd pulses alert; an unordered bracket is
  refused; `near_limit: null` equals the field absent.
- Witch Hunter 804051 uses near_distance 21, far_margin 4, near_limit 22.5.
