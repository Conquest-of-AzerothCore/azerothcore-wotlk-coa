# 0763. A taken hit can strike an ally and read the transfer

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 324.0 (Gaze of the Black Knight 802138, "and then gaze upon your party members, causing $s1% of
the damage they take to be transferred to you") is about a hit on a party member. Every `taken_hit` read took the
caster as the struck unit. The transfer is the engine's split damage (802138 Effect[0] aura 81
SPELL_AURA_SPLIT_DAMAGE_PCT): `Unit::CalcAbsorbResist` absorbs CalculatePct(damage, 25) from the member's hit and
deals it to the aura's caster under 802138 from the attacker (`Unit.cpp:2946-3014`). Design O4 of c14-tool2; mentor
D-240.

## Options

- `struck: ally` with a `transfer_spell` and per-arm `transfer_pct`.
- Reading the caster's health loss: the caster's own 802138 shield absorbs the transfer.

## Decision

`taken_hit` takes `struck: "ally"` (absorb judge, creature striker, no debt, returned hit or caster health): the
striker's strikes land on the ally grouped with the caster and the logs of `strike_spell` on the ally are read.
`transfer_spell` with each arm's `transfer_pct` adds reads of that spell's damage, absorbed amount and log count on
the caster from the striker; per landed trial they must be one log adding up to floor(`transfer_pct`% of the strike's
damage plus absorbed amount), or no log at 0.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: a 25% share on the ally with the same amount on the caster passes; mutants that must alert: no
  transfer log, a transfer of the wrong amount, a transfer in the control arm, no share on the ally.
- Witch Hunter: 802138 `gaze_transfer`, striker 41394 at the ally, 8 trials per arm (the 12 s aura covers them),
  control without Gaze.
