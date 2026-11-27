# Summon ritual (`behaviour_metric_delta`, `kind: "summon_ritual"`, ADR 1326 / ADR 1329, provisional)

ADR 1326 and ADR 1329 have provisional numbers and are renumbered at merge (guide 14.4).

Proves a multi-player summoning ritual end to end in either **2-stage stone-and-portal mode** (when `stone_entry` and
`portal_entry` are both set) or **1-stage direct summon mode** (when both `stone_entry` and `portal_entry` are omitted
or `null`). Supplying only one of `stone_entry` or `portal_entry` is refused with `ValueError`. Zero harness C++
changes: reuses `group`, `teleport`, `use_nearby_gameobject`, `select`, `owned_gameobject_count`, `cast_failure`, and
`summon_pending`.

## 2-stage stone-and-portal mode (`stone_entry` and `portal_entry` set)

- **Players:** Four same-class grouped party members (`caster`, `first`, `second`, `faraway`) at `location`, with
  `faraway` teleported to `faraway_location` (at least `50 yd` away on the same map).
- **Pre-cast control:** Reads `owned_gameobject_count` of `ritual_entry`, `stone_entry`, `portal_entry` (all `0`) and
  `summon_pending` on `faraway` (`0`). Non-zero baseline returns `unmeasured`.
- **Stage 1 (ritual):** `caster` casts `spell`; `cast_failure == 0` and `owned_gameobject_count(ritual_entry) == 1`.
- **Stage 2 (stone):** `first` and `second` click `ritual_entry` (`owner: caster`); waits `stone_wait_ms`, then reads
  `owned_gameobject_count(stone_entry) == 1` and intermediate control `summon_pending` on `faraway` (`== 0`).
- **Stage 3 (portal):** `first` selects `faraway` and clicks `stone_entry` (`owner: caster`); waits `portal_wait_ms`,
  then reads `owned_gameobject_count(portal_entry, actor: first) == 1` and intermediate control `summon_pending` on
  `faraway` (`== 0`).
- **Stage 4 (summon):** `second` clicks `portal_entry` (`owner: first`); waits `summon_wait_ms`, then reads
  `summon_pending` on `faraway` (`== 1`).

## 1-stage direct summon mode (`stone_entry` and `portal_entry` both omitted / `null`)

- **Players:** Three same-class grouped party members (`caster`, `first`, `faraway`) at `location`, with `faraway`
  teleported to `faraway_location` (at least `50 yd` away on the same map).
- **Pre-cast control:** Reads `owned_gameobject_count(ritual_entry)` on `caster` (`0`) and `summon_pending` on
  `faraway` (`0`). Non-zero baseline returns `unmeasured`.
- **Stage 1 (select + ritual):** `caster` selects `faraway`, sets optional `cast_power`, and casts `spell`;
  `cast_failure == 0`, waits `ritual_wait_ms`, then reads `owned_gameobject_count(ritual_entry) == 1` and intermediate
  control `summon_pending` on `faraway` (`== 0`).
- **Stage 2 (summon):** `first` clicks `ritual_entry` (`owner: caster`); waits `summon_wait_ms`, then reads
  `summon_pending` on `faraway` (`== 1`).

## Judgement and evidence

- **Chronological milestone judging:** Each stage is checked before requiring later measurements, so a broken ritual
  that aborts a subsequent `use_nearby_gameobject` step alerts on the failing stage rather than falling back to
  `unmeasured`.
- **Evidence class:** `metric: "summon_pending"`, registered as `EVENT` in `coverage.METRIC_EVIDENCE` (counted as
  `behaviour`).

Examples:

- Bloodmage (2-stage): Blood Covenant `1200012` (`ritual_entry: 194111`, `stone_entry: 194114`, `portal_entry: 179944`).
- Cultist (1-stage direct): Summoning Obelisk `1200011` (`ritual_entry: 194110`).
