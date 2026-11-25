# 0028. Owner ruling Q-cu-27: Dreadnought minimum-speed aura matches 20-second form

- Status: accepted (owner ruling Cultist Q-cu-27 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Dreadnought `567524` (inherited by specialization passive `680750` via `@s:567524:0@`, ranks `567524, 567548..567552`):
  "Absorbs ${$m2+0+$STA*3+$INT*3} damage, scaling with Intellect and Stamina. Protects movement speed from going below $567525s2% of normal speed. Lasts $d." (`80%`, `Lasts 20 sec.`).

All six ranks of Dreadnought (`567524, 567548..567552`) have `DurationIndex = 18` (`SpellDuration.dbc` id `18` = `20000 ms`) and `Effect[2] = 64` (`SPELL_EFFECT_TRIGGER_SPELL`) triggering companion aura `567525`. In `Spell.dbc`, `567525` (`Effect[1]` aura `305` `SPELL_AURA_MOD_MINIMUM_SPEED`, `bp = 79 + die = 1` = `80%`) has `DurationIndex = 8` (`SpellDuration.dbc` id `8` = `15000 ms`) with no SQL or C++ override, so the minimum-speed protection dropped 5 s before the Dreadnought form expired.

Pre-fix conformance pair `cu-t1b` `prove2` (`20261125-064041` / `20261125-064119`, build `ed20e7787648`) measured:
- `680750 behaviour_metric_delta min_speed` (at 14.2 s): ok (`run_speed_rate 0.70 -> 0.80`, `567525 == 1`).
- `680750 behaviour_metric_delta min_speed_late` (at 19.2 s and 20.8 s): alert/alert (`run_speed_rate 0.70` at `19209 ms` against expected `0.80`, `567524 == 1`, `567525 == 0` against expected `1`).

The owner ruled (Cultist `Q-cu-27`, `O-15`, 2026-11-25): `extend_20s` — extend the minimum-speed companion aura to 20 s to match Dreadnought's duration.

## Options

- Set `info->DurationEntry = sSpellDurationStore.LookupEntry(18);` (`20000 ms`) on `id == 567525` in `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), matching the existing duration contract pattern in `ApplyContracts` (`id == 807883 || id == 681476 || id == 567529`). Chosen.
- Leave `567525` at 15 s and alter the tooltip text. Rejected by owner ruling `Q-cu-27`.

## Decision

In `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:264-265`), set `info->DurationEntry = sSpellDurationStore.LookupEntry(18);` when `id == 567525`. No shared engine, SQL, DBC, or other-class changes.

## Consequences

- Companion aura `567525` lasts 20 s, matching Dreadnought (`567524, 567548..567552`). Its other two effects (`Effect[0]` aura `87`, `Effect[2]` aura `107`) both have value `0`.
- No other spell or class is reached (`567525` is triggered exclusively by Dreadnought).
- Counted pair (`20261125-091709` / `20261125-091744`, build `0189984a6fb8`, 12/12 ok, 0 flips):
  - `680750 behaviour_metric_delta min_speed_late`: control `0.70` (`567525 == 0`), treatment `0.80` at 19.2 s (`567524 == 1`, `567525 == 1`), `0.70` after 20.8 s expiry — ok/ok.
  - `680750 behaviour_metric_delta min_speed` (`0.70 -> 0.80`), `duration`, `absorb_base/sta/int`, `madness_suppressed`, `insanity_zero`, `teaches_dreadnought`, and `680557` (`transform`, `damage_taken`, `damage_taken_control`) all passed ok/ok with no movement.
