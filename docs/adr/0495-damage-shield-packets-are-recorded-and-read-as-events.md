# 0495. Damage shield packets are recorded and read as events

- Status: accepted
- Date: 2026-11-13

## Context

Razorice 501965 and Greater Razorice 572214: "causing ${$m1+0} Frost damage to attackers when hit."
`Unit::DealDamageShieldDamage` (Unit.cpp:2360-2410) damages the attacker of a landed melee hit and sends
SMSG_SPELLDAMAGESHIELD (0x24F) to the units around it: attacker GUID, shield owner GUID, spell, damage, overkill,
school. The harness did not record that packet (tool gap "SMSG_SPELLDAMAGESHIELD not recorded", 2 claims), so the
only read was the attacker's health loss, which needs a landed-hit count. The harness already records a list of core
packets for the generic `server_packets` and `server_packet_u32` metrics, which the coverage tool did not class.

## Decision

- The harness adds SMSG_SPELLDAMAGESHIELD to its recorded core packets (a read only, G-39; no packet is sent or
  changed). `server_packets` with `opcode: 591` counts the damage shield hits a player received, and
  `server_packet_u32` with `index: 4` and `5` reads the spell and damage of the last one.
- `coverage.METRIC_EVIDENCE` classes `server_packets` and `server_packet_u32` as EVENT reads.

## Consequences

- The Razorice entries read 0 packets without the shield and 1 to 8 with it over 8 Strikes, the last carrying the
  shield spell and 21 damage ($m1 at spell power 0).
- Tests: `ServerPacketEvidenceTest` (test_coverage.py).
