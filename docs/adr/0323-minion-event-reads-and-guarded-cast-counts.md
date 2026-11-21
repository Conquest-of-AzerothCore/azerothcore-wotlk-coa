# 0323. Minion event reads and guarded cast counts in clause coverage

- Status: accepted
- Date: 2026-11-13

## Context

The Necromancer batch reads minion behaviour through harness metrics that the closed evidence tables of
`coverage.py` did not list (ADR 0120): cast counts (`spell_go_count`), a pet's or creature entry's melee outcomes
(`pet_melee_crits`, `pet_melee_plain_count`, `pet_melee_hits`, `pet_melee_blocked`), a minion's maximum health
(`owned_creature_max_health`) and the mana a cast costs (`power`). A review found that a cast count listed as an event
read closed any clause, including a damage clause, though a cast is not an applied hit (G-21, point 1).

## Considered options

1. Leave `spell_go_count` a plain event read. Rejected: a cast count would prove a damage clause.
2. Class it as a readback. Rejected: a cast the server sent is the behaviour a clause like "Command: Unleash a
   powerful attack" states.
3. Keep it an event read, guarded by the clause's words, as state reads are guarded (`STATE_PROMISES`). Chosen.

## Decision

- `spell_go_count` stays in `EVENT`, and `EVENT_PROMISES` limits it to a clause that states a cast ("unleash",
  "cast"); any other clause gets data evidence from it.
- `pet_melee_crits`, `pet_melee_plain_count`, `pet_melee_hits` and `pet_melee_blocked` are event reads: they count the
  `SMSG_ATTACKERSTATEUPDATE` packets the server sent for the minion's swings.
- `owned_creature_max_health` is a state read, behaviour only for a clause that states maximum health.
- A `power` read is behaviour for a clause that states a cost (`\bcost` added to its promise words): the mana a real
  cast spent.

## Consequences

- A cast count cannot close a damage or healing clause; the clause needs a hit read.
- Each new metric has a row before any verdict on it counts.
