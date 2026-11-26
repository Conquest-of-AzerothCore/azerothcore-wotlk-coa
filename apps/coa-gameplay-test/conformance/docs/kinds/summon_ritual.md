# Summon ritual (`behaviour_metric_delta`, `kind: "summon_ritual"`, ADR 1326, provisional)

ADR 1326 has a provisional number and is renumbered at merge (guide 14.4).

Proves a multi-player summoning ritual end to end: casting `spell` places a summoning ritual gameobject (`ritual_entry`),
two grouped party members click it to carve the summoning stone (`stone_entry`), an ally selects a distant party member
(`faraway`) and clicks the stone to open the summoning portal (`portal_entry`), and a second ally clicks the portal to
leave `faraway` with a pending summon (`summon_pending == 1`). Zero harness C++ changes: reuses `group`, `teleport`,
`use_nearby_gameobject`, `select`, `owned_gameobject_count`, `cast_failure`, and `summon_pending`.

## Scenario and judgement

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
- **Chronological milestone judging:** Each stage is checked before requiring later measurements, so a broken ritual
  that aborts a subsequent `use_nearby_gameobject` step alerts on the failing stage rather than falling back to
  `unmeasured`.
- **Evidence class:** `metric: "summon_pending"`, registered as `EVENT` in `coverage.METRIC_EVIDENCE` (counted as
  `behaviour`).

Bloodmage: Blood Covenant `1200012` (`ritual_entry: 194111`, `stone_entry: 194114`, `portal_entry: 179944`).
