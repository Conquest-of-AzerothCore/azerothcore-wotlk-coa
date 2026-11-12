# 0237. A harness-simulated landing for fall damage

- Status: accepted
- Date: 2026-11-12

## Context

Harmonic Disposition 560653, claim 117: "You radiate a harmonic disposition to nearby party and raid members, causing
fall damage to be reduced". Its Effect[0] is SPELL_EFFECT_APPLY_AREA_AURA_RAID with SPELL_AURA_SAFE_FALL (144), 10.
The harness had no way to make a player land: `relocate` and `teleport` move without a fall, and `client_packet`
writes no floats. The mentor approved a harness action that calls the server's landing function (owner-rulings,
"Claim 117, simulated landing", 2026-11-12).

The server path of a client landing:
- `WorldSession::HandleMovementOpcodes` (src/server/game/Handlers/MovementHandler.cpp:357) reads the MovementInfo and
  calls `ProcessMovementInfo` (:396);
- `ProcessMovementInfo` (:609) calls `plrMover->HandleFall(movementInfo)` for `MSG_MOVE_FALL_LAND` (:628-630), and for
  every movement packet `UpdateFallInformationIfNeed` (:668);
- `Player::UpdateFallInformationIfNeed` (src/server/game/Entities/Player/PlayerUpdates.cpp:2329-2335) stores the fall
  start (`m_lastFallTime`, `m_lastFallZ`) when the packet's fall time is not above the stored one or its z is not
  below the stored z, or on landing;
- `Player::HandleFall` (src/server/game/Entities/Player/Player.cpp:15046-15089) reads only the height: `z_diff =
  m_lastFallZ - movementInfo.pos.z`. `fallTime` is only logged. Hover, feather fall, fly, GM, god mode, death and
  physical immunity skip the damage; SAFE_FALL is subtracted from `z_diff`; the damage is `0.018 x (z_diff - safe
  fall) - 0.2426` of maximum health times `Rate.Damage.Fall`, applied through `EnvironmentalDamage(DAMAGE_FALL)`.

## Decision

The harness action `fall` (player `actor`, `height` 1 to 60 yd) does what the two packets of a real fall do, and no
damage arithmetic of its own:
- it refuses a dead, GM, god-mode, hovering, feather-falling, flying, in-flight, swimming or physically immune player;
- `UpdateFallInformationIfNeed` with a MovementInfo `height` yards above the player, fall time 0 and the falling flag
  (a client's first falling packet), which stores the fall start;
- `HandleFall` with a landing MovementInfo at the player's position, its fall time the free-fall time of that height
  (sqrt(2h / 19.29) s, logged only), then `UpdateFallInformationIfNeed` for the landing, as `ProcessMovementInfo` does;
- it records the height, fall time, the SAFE_FALL total, `Rate.Damage.Fall` and the health lost.

The conformance kind `fall_damage` lands the grouped ally from one height at 10000 maximum health before and after a
real cast of the aura spell, reads its health before and right after each landing, and the aura on it. The judge
(`behaviour_fall_damage`) wants a loss above 0 without the aura and a loss of at least 0 and below it with the aura:
the tooltip names no amount, so there is no third height. Existing scenarios regenerate byte-identical.

## Consequences

- The landing is harness-simulated: no client movement packet is sent, and the anticheat hook of the real path
  (`AnticheatSetJumpingbyOpcode`, MovementHandler.cpp:632) is not called.
- Harmonic Disposition on build f8370be27d42, both runs (20261112-034627 / -034659): from 30 yd the ally lost 2973
  health without the aura (safe fall 0) and 1173 with it (safe fall 10), at Rate.Damage.Fall 1 as the action recorded
  it (the test worldserver.ram.conf:2163 sets 1; WorldConfig.cpp:175 defaults to 1.0). The aura was on the ally
  1500 ms after the cast.
- A validation test checks the action's fields; seeded tests check the arms, and that equal, absent or larger losses
  alert.
