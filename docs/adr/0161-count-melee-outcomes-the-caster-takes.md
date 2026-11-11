# 0161. Count the outcomes of the melee attacks the caster takes

- Status: accepted
- Date: 2026-11-11

## Context

Parry Dance 804912 states "your chance to parry is now increased by $560651s1%" (3 per stack of 560651, 5 stacks).
`parry_chance` is a state read, and a learned contrast does not isolate the claim: learning 804912 also grants parry
rating from Agility (its Effect[0], aura 220) and its parries add stacks. The harness counted the melee packets the
player receives (`melee_attacks_taken`) but parsed `SMSG_ATTACKERSTATEUPDATE` only up to the damage, not the
victim state that says whether the swing was parried.

## Considered options

1. Read `parry_chance` before and after a learned contrast. Rejected: the agility rating and the trigger mix in.
2. Ask the owner whether a state read contrasted by the real trigger may count as behaviour. Kept as the fallback.
3. Record each received melee packet's victim state and compare the parried share of incoming swings without and
   with the aura. Chosen.

## Decision

- The harness reads the packet on to its `VictimState` (Unit.cpp `SendAttackStateUpdate`: overkill, the
  sub-damages, absorbs and resists when flagged) and counts it per attacker and state. `melee_attacks_taken` takes
  `victim_state` (0 to 8). Reading and recording only; nothing the server does changes.
- The `taken_outcome` behaviour kind sets up to eight aggressive, stationary attackers in front of the caster, engages
  each with one swing, then runs a control arm and an arm with the aura set at its stacks every `refresh_ms`, reading
  the swings taken and the swings with the victim state at each arm's start and end.
- The judge compares the difference of the two rates, in points, with its 99% normal interval, to the stated points
  under the percent bonus band (the larger of 5% of it and 2 points; `bonus.bonus_status`), so a reading needs a
  half-width of at most half the band.

## Consequences

- Claim 376 gets an event route. The aura is set by the fixture; the trigger that grants it is proven by clauses
  377 to 379.
- Without the attackers' haste fixtures, eight attackers at 2.0 s swing about 14,000 times an hour, short of the
  half-width the band needs; Molten 62531 and Enrage 2116852 make them swing four times as often.
- `stationary` does not keep engaged attackers in place: they spread around the caster, and a swing from behind is
  never parried, so the parried share fell by a third in some runs. A root aura (42716) holds them in front.
- `set_aura` keeps the remaining duration of an aura it finds, so the kind removes the aura before setting it again.
- Any outcome rate of incoming melee (dodge, block, miss, parry) can use the kind.
- Tests: `test_runner.test_melee_attacks_taken_keeps_one_victim_state`, `test_behaviours.TakenOutcomeTests`.
