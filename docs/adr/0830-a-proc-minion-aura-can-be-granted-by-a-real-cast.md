# 0830. A proc minion aura can be granted by a real cast

- Status: proposed (provisional number, guide 14.4)
- Date: 2026-11-16

## Context

Shadow Rage 238.0 (talent 705455): "Casting Shadowblast now grants Shadow Rage to your Shadow Hound", and Shadow Rage
804192 on the hound gives its auto attacks a 50% chance (DBC ProcChance 50) to strike 567570. The 804192 proc_rate
entry held the aura on the Shadowhound 50124 with a harness set_aura fixture (`minion_auras`, `"caster": "owner"`,
ADR 0780); the grant itself was proven only by a separate label (`705455 behaviour_metric_delta hound_grant`). A
fixture is a precondition, never the claim's subject (G-21 point 6), and the c16-a1 author stopped on the missing real
grant. `aura_recast_ms` recasts the entry's own aura and serves magnitude-ratio triggers only.

## Options

- Keep the set_aura fixture and cite the hound_grant label: the proc rate is then measured on a state the server did
  not produce.
- A new kind for granted minion procs: duplicates the proc_rate sizing, parts and judge.
- An optional `grant_cast` spell on a proc_rate `minion_auras` fixture (mentor D-267, owner delegation O-12).

## Decision

`grant_cast` on a fixture of a proc_rate entry with a minion trigger. Before every refresh window,
`minion_aura_steps` emits the entry's `caster_power`, a `reset_cooldown` and a real cast of that spell at the dummy,
a 500 ms wait (the wait of the counted hound_grant label) and a read of the owned creatures of the trigger's entry
carrying the aura cast by the caster, in place of the set_aura pair. The read waits are taken out of the window so
the scheduled swing time does not move. The proc model lists the reads (`grants`); `judge_proc` fails the verdict
(`alert`) when any read of any part is 0, and a missing read leaves that part unmeasured. A passing verdict names the
real grant ("granted by a real 804191 cast: present after each of the N grants"). The validator refuses `amount`, a
second fixture (minion or dummy) of the same aura, a refresh interval of 500 ms or less, and `grant_cast` in the
trigger kinds, which do not read it. The option is opt-in: no finished-class scenario changes.

## Consequences

- The 804192 entry measures the chance on an aura the server applied through the Shadowblast script
  (`GrantShadowRageToHounds`, `AscensionWitchHunterAbilities.cpp:52-59`), each window.
- Shadowblast 804191 deals its own damage to the dummy; it is a caster spell, not a hound auto attack, so it adds no
  trial (`owned_creature_damage_count` of 50124) and no 567570 event unless the server is wrong.
- No harness or engine change; the read uses the existing `owned_creature_count` metric with `spell` and `caster`.
