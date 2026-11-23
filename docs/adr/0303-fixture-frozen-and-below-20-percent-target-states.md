# 0303. Fixture the frozen and below-20% target aura states in generated scenarios

- Status: accepted
- Date: 2026-11-12

## Context

`conformance.py generate --class 23` stopped on two Necromancer ranks whose `TargetAuraState` had no fixture:
Glacial Impact 704355 (state 4, `AURA_STATE_FROZEN`) and Death's Due 808016 (state 2,
`AURA_STATE_HEALTHLESS_20_PERCENT`). The only fixture was the below-35% health one (Titanstrike). Its reference melee
scenario also stopped the run: at the scaffolded weapon and the naked level-60 attack power (34), the swing count it
needs exceeds one scenario's wait.

## Considered options

1. Leave both states unmodelled. Rejected: it stops generation for the whole class.
2. Freeze the target with a Necromancer spell. Rejected as the generic fixture: a value scenario's subject is the
   rank's own effect, and the fixture must not depend on the class.
3. A stock Frost-school root, Frost Nova 122, set on the target by the harness, and a 15% health fixture for state 2.
   Chosen.

## Decision

- State 4: `set_aura` of Frost Nova 122 on the target. `SpellInfo::GetAuraState` gives `AURA_STATE_FROZEN` to a
  Frost-school spell with a stun or root aura (`SpellInfo.cpp:2342-2346`); 122 is Frost (school mask 16) with
  aura 26 (root). The Necromancer code tests that same state: `AscensionNecromancerAbilities.cpp:169-171` (Glacial
  Impact's cast check) and `AscensionNecromancerEvents.cpp:42` (Soulfreeze).
- State 2: `set_health_pct` 15, then the same 1000 ms wait as the 35% fixture.
- A melee scenario that cannot be scheduled is written as an `unmodelled` entry. This is a generation fallback, not a
  claim status.
- Mentor conditions (2026-11-12): the fixtures are precondition fixtures under rule 4 point 6. The frozen fixture is
  never used for a claim whose subject is a Necromancer freeze, and the health fixture never for a claim about health;
  verdicts name the fixture. Melee or weapon claims the fallback skips get a `tool_gap` and a route.

## Consequences

- Class 23 generates 255 scenarios. Templar generation (`--class 19`, with and without `--stack`) is byte-identical,
  manifest included apart from `dbc_dir`.
- The Necromancer reference melee scenario needs a route (a weapon and gear that bring it to a normal length, or a
  sized hit scenario) before any melee claim can be proven.
