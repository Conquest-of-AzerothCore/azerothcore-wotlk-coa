# 0603. A cooldown reset is counted from its clear-cooldown packet

- Status: accepted
- Date: 2026-11-13

## Context

Claim 137.0, Unholy Runes 561353 "damage dealt by Blight now has a $h% chance to reset the cooldown of Corpse
Explosion": the reset itself was behaviour (`cost_gate`), the $h rate was a tool gap ("a proc event for a cooldown
reset has no event metric"). The reset is `Reduce(player, 533236, INT32_MAX)`, which calls
`Player::RemoveSpellCooldown(id, true)` for each known rank; that sends `SMSG_CLEAR_COOLDOWN` with the spell id as its
first field whether a cooldown ran or not (Player.cpp:3949-3955, 15935-15940). The harness already counts the packets
of a selected opcode and first field (`server_packets` with `row`, an event read).

## Options

- A new event metric in the central `procs.EVENT_METRICS`: a central-list edit and a proc plan for a 5% rate.
- A kind module that casts the cost-free trigger enough times in one scenario and counts the packets.

## Decision

Kind `cooldown_reset_rate` (kinds/cooldown_reset_rate.py): the trigger cast `control_casts` times before the talent
(control, no packet) and `casts` times after; resets per damaging trigger hit judged by `compare.rate_judgement` and
`banded_rate` (Wilson 99%, G-20 band). `casts` must reach `procs.band_trials_needed`; at most 10000 steps.

## Consequences

- 137.0 rate: the pilot (stamp 20261113-171400) read 153 resets in 3300 Blight hits, 0.0464, interval
  [0.0378, 0.0567] inside [0.03, 0.07]; 0 in the 200 control hits.
- Only a cost-free trigger fits one scenario (Blight 500237 has no cost and no global cooldown).
- Templar has no entry of this kind; the shared tables are unchanged.
