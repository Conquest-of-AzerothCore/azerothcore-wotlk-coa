# 1311. Summon random direction proves multi-copy running displacement and angular spread

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-38, D-39; G-39 harness note

## Context

Cultist Hallucination `560301` (`Spell.dbc`, row 179) states `"Create 3 copies of yourself that run in a random
direction for $706932d and may briefly trick enemies into ignoring you."` (`$706932d = 3000 ms`). Claims `[0]`
(`for $706932d`) and `[1]` (`Create 3 copies of yourself`) are proved by `copies_duration`, and claim `[3]`
(`may briefly trick enemies into ignoring you`) is settled by owner ruling `O-15 Q-cu-35` (`threat_reduce` /
`threat_reduce_control`). Claim `[2]` (`"that run in a random direction"`) remained a tool gap because
`owned_creature_position_x`/`y` and `owned_creature_distance_2d` call `GetOwnedCreature(player, entry)` and can only
observe a single copy of `840025` (`AscensionCultistAbilities.cpp:495-497`, `AscensionCultistSummons.cpp:29-33,58-59`).

## Options

- Modify `owned_creature_position_x`/`y` to take an optional `index`. Rejected: adding distinct opt-in metrics keeps
  existing metrics untouched and minimizes merge surface with parallel harness work.
- Add opt-in read-only metrics `owned_creature_copy_x` and `owned_creature_copy_y` over GUID-sorted living summons
  and a dedicated opt-in kind `summon_random_direction` (`ORDER = 60`). Chosen.

## Decision

1. **Opt-in harness reads `owned_creature_copy_x` and `owned_creature_copy_y`** (`CoAGameplayTest.cpp`, `run.py`):
   - `GetOwnedCreaturesSorted(player, entry)` enumerates living summons (`IsLivingSummonOf`) sorted ascending by raw
     GUID so index `i` refers to the same creature across start and end reads of a cast.
   - `owned_creature_copy_x` / `owned_creature_copy_y` take `actor`, `entry`, and `index` (`0..31`), returning the
     coordinate or `NaN` when `index >= creatures.size()`. Pure read-only; zero gameplay effect.
2. **Opt-in behaviour kind `summon_random_direction`** (`kinds/summon_random_direction.py`, `ORDER = 60`):
   - Registers `METRIC_EVIDENCE = {'owned_creature_copy_x': 'event', 'owned_creature_copy_y': 'event'}` inside the
     kind module (zero edits to `coverage.py`).
   - Checks uncast control (`owned_creature_count == 0`), then across repeated casts observing `M >= 24` total copies
     (`8` casts x `3` copies for `560301`), reads GUID-sorted `(x, y)` at `+50 ms` and `+1550 ms` (`< 3000 ms`
     duration), waiting `2000 ms` between casts for clean despawn.
   - Alerts if any copy displaces `< min_run_yd` (`5.0 yd` in `1500 ms`, excluding stationary `0 yd` and walk
     `~3.75 yd` against run `~10.5 yd`), if mean resultant length `R > 0.65` (catching single-direction and narrow-cone
     mutants), or if fewer than `5` of `8` 45-degree sectors are occupied (catching deterministic 1/2/3/4-way fans).
   - Uniform-direction false-fail upper bound at `M = 24`: `4.4e-5`/run (`8.8e-5` per 2-run pair `<= 0.1%`). Complies
     with D-38 (asserts no unstated numeric speed or distribution parameter beyond running displacement and
     non-fixed direction spread).

## Consequences

- Strictly opt-in: finished classes regenerate byte-identical (`coverage.py` and `behaviours.py` untouched).
- Unlocks Cultist Hallucination `560301` row 179 claim `[2]` (`"that run in a random direction"`) as behaviour
  evidence.
