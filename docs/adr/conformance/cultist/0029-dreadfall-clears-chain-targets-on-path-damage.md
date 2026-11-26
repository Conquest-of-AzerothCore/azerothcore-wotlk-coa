# 0029. Owner ruling Q-cu-33: Dreadfall clears chain targets on path damage

- Status: accepted (owner ruling Cultist Q-cu-33 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Dreadfall `806175`: "Raise your shield and charge towards an enemy, dealing ${$AP*0.5} Shadow damage to enemies you pass through, generating additional threat."

`AscensionCultist::UpdateDash` (`src/server/coa/AscensionCultistSummons.cpp:86-107`) iterates valid enemies within 2 yd of the dash segment, deduplicates via `state.dashHits`, and casts path damage spell `807815` once per passed-through enemy. In `Spell.dbc`, however, `807815` has `EffectChainTarget[0] = 20` on `Effect[0]` (`SPELL_EFFECT_SCHOOL_DAMAGE`). `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:19-20`) cleared `SPELL_ATTR1_NO_THREAT` on `807815` but left `Effects[0].ChainTarget = 20` intact, causing `Spell::SearchChainTargets` to chain each cast onto nearby targets within 10 yd.

Pre-fix conformance pair `cu-t2` `batch-b2` (`20261125-055332` / `20261125-055401`, commit `13e1fbfd4a`) measured:
- `806175 behaviour_metric_delta pass_through`: charging to `dummy` (15 yd) through `area1` (7.5 yd) with off-path `area2` (25 yd) dealt `2` hits to `area1` (expected `1`), `2` hits to `dummy` (expected `1`), and `1` hit to `area2` (expected `0`) — alert/alert.

The owner ruled (Cultist `Q-cu-33`, `O-15`, 2026-11-25): `clear_chain` — clear the chain target count so passed-through enemies are each hit once and off-path enemies are not hit.

## Options

- Clear `info->Effects[0].ChainTarget = 0;` on `id == 807815` in `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:19-23`). Chosen.
- Keep `ChainTarget = 20` and rely on `UpdateDash` alone. Rejected by owner ruling `Q-cu-33`.

## Decision

In `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:19-23`), set `info->Effects[0].ChainTarget = 0;` alongside clearing `SPELL_ATTR1_NO_THREAT` when `id == 807815`. No shared engine, SQL, DBC, or other-class changes.

## Consequences

- Each `807815` cast from `UpdateDash` hits only its passed-through target once and never chains to other enemies on or off the path.
- No other spell or class is reached (`807815` is cast exclusively by `UpdateDash` for Dreadfall `806175`).
- Counted pair (`20261125-091944` / `20261125-092016`, build `4a8bbbe6a005`, 5/5 ok, 0 flips):
  - `806175 behaviour_metric_delta pass_through`: `area1` (7.5 yd) `1` / `1`, `dummy` (15 yd) `1` / `1`, off-path `area2` (25 yd) `0` / `0` (control `0` on all) — ok/ok.
  - Sibling checks unchanged (`damage_ref` `211` / `211`, `damage_ap` `11411` / `11411`, `threat_above_control` `1.305` / `1.263` > `1.105` / `1.104`, `charge_displacement` `15.0` / `15.0`).
