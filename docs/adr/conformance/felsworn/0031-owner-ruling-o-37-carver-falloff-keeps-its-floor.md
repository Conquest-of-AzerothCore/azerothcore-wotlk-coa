# 0031. Owner ruling Felsworn O-37: the Hellfire Carver and Carve falloff keeps its 20% floor

- Status: accepted (owner ruling Felsworn O-37 (2026-11-24), question N-12)
- Date: 2026-11-24

## Context

Hellfire Carver 707444: "causes it to strike 1 additional enemy near the primary target based on how long you
channeled, up to a maximum of 10 enemies, dealing less damage with each target struck." Carve 800206: "slash in front
of you, ... dealing less damage with each target struck." Neither tooltip gives a figure. The server scales the
damage by target rank with `max(0.2, 1 - 0.1 x rank)`: Fel Fireball 801312 in `AscensionFelswornAbilities.cpp:228-238`
(extras picked nearest the primary first, `AscensionFelswornAbilities.cpp:148-160` with `Nearby`,
`AscensionFelsworn.cpp:174-186`), the Carve end slash 803715 in `AscensionFelswornAuras.cpp:228-248` (no target cap,
the loop stops at 25). The factor reaches 0.2 at the 9th target, so the floor binds from the 10th target struck:
damage stops falling there, which "less damage with each target struck" does not state, and "up to a maximum of
10 enemies" allows 11 Fel Fireball targets.

The conformance proof (shared ADR 1276, `target_order`) judges 9 targets per cast, strictly falling, for both spells;
it cannot see targets 10 and 11, so claim 185.1 (707444) went to the owner as question N-12.

## Options

- Keep the floor: targets 10 and on take the floored 20%, no server change.
- Remove the floor (keep falling, or stop at zero): a server change with no tooltip figure behind it.

## Decision

The owner ruled (Felsworn O-37 (2026-11-24)): keep the 20% floor, no server change. Targets 9 to 11 of Fel Fireball
and every Carve slash target from the 10th are conformant by the ruling.

## Consequences

- 185.1 (707444 "dealing less damage with each target struck.") counts by ruling, with the 9-target proof
  `707444 behaviour_metric_delta target_order` attached; the controller records the ruling in its decisions file.
- 204.0 (800206 end slash) keeps its two labels; the same floor applies to Carve from the 10th enemy, covered by the
  same ruling.
- No server, DBC, SQL or client text change.
