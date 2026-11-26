# Portal single cast and post-cast despawn (`kind: "portal_single_cast"`, ADR 1296)

ADR 1296 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a summoned creature (such as Cultist's Void Portal `533030`) casts **exactly one** direct spell from an
allowed set across its entire lifetime and then **disappears after that cast**, strictly before its full summon
lifetime would end.

## Harness primitives

- Read `owned_creature_total_cast_count` (`actor`, `entry`, optional `spell`, optional boolean `triggered`, default
  `true`, optional boolean `cumulative`, default `false`):
  - With `cumulative: false` (default), counts casts recorded by `ProcCounter` for the living owned creature of `entry`
    and returns `-1` when no living owned creature of `entry` is present.
  - With `cumulative: true`, reads the cumulative entry-scoped count across all summons of `entry` owned by `actor`,
    remaining readable after the creature despawns so whole-lifetime trial deltas (`post - pre`) leave `0 ms` of the
    creature's lifetime unobserved.
  - With `triggered: false`, counts only non-triggered casts (`!spell->IsTriggered()`) so triggered sub-effects (for
    example Gaze of C'Thun `500110 -> 520334 -> 520332` or Obliteration Beam `805572 -> 805573`) do not inflate the
    cast count of one spell.
  - Classified as `event` evidence in the kind's `METRIC_EVIDENCE` row.
- Action `cast_until_owned_creature` (`actor`, `spell`, `entry`, `every_ms`, `max_casts`; optional `target`,
  `cast_power`, `power`, `reset_cooldown`): mirrors `cast_until_aura` for a rolled summon proc whose roll cannot be
  forced, stopping on the first world update where `GetOwnedCreature(player, entry) != nullptr`.

## Scenario and arms

- `control`: runs before `gate_spell` is learned (one deterministic trigger cycle, or `cast_until_owned_creature` in
  `feed` mode) and reads `owned_creature_count` and `owned_creature_summon_count` of `entry`. Any spawn alerts.
- `treatment`: learns `gate_spell` and runs `portals` independent trials per part across `parts` pooled parts
  (minimum `6` portals per run; a one-portal anecdote is refused at generation time):
  1. Reads `owned_creature_count == 0` before triggering (nonzero is `unmeasured`) plus the pre-trigger cumulative
     baseline `owned_creature_total_cast_count(triggered=false, cumulative=true)` (total and per spell in
     `allowed_spells`).
  2. Triggers one spawn (deterministic `setup_casts` + `trigger_spell`, or `cast_until_owned_creature` when `feed` is
     set, sized so the union-bound cap-hit risk across the 2-run pair is at most `residual`, default `1e-3`).
  3. Reads `owned_creature_count == 1` on spawn (`0` is `unmeasured` in `feed` mode and `alert` in deterministic mode;
     `> 1` alerts).
  4. Waits `cast_read_ms` (after cast completion and before post-cast despawn), then reads `owned_creature_count == 1`,
     `owned_creature_total_cast_count(triggered=false) == 1`, and `owned_creature_total_cast_count(spell=s,
     triggered=false)` for each `s` in `allowed_spells` (sum must equal `1`).
  5. Waits to `direct_despawn_check_ms` (and to `channeled_despawn_check_ms` when any spell in `allowed_spells` carries
     `SPELL_ATTR1_IS_CHANNELED | SPELL_ATTR1_IS_SELF_CHANNELED` in `Spell.dbc`), both required to be at least `500 ms`
     below `lifetime_ms`. The judge branches on whether the chosen spell is channeled and alerts if the creature is
     still alive at its despawn check.
  6. After confirming the creature is gone (`owned_creature_count == 0`), reads the post-despawn cumulative
     `owned_creature_total_cast_count(triggered=false, cumulative=true)` (total and per spell in `allowed_spells`) and
     checks `post - pre == 1` for total, allowed sum, and the chosen spell, covering the entire `[pre_trigger, despawn]`
     lifetime with `0 ms` unobserved.

## `triggered = false` boundary

`owned_creature_total_cast_count(triggered=false)` intentionally excludes `spell->IsTriggered()` casts so triggered
sub-effects of a single spell do not inflate the cast count. As a consequence, an extra spell cast via
`CastSpell(..., true)` is not observed by `_directCasts` alone; pair `portal_single_cast` with a damage/healing
spell-set check (such as `portal_only_three` on `301068` and `301200`) when full coverage of triggered output spells is
needed.

## Refusals

Refuses fewer than `6` total portals per run, `cast_read_ms >= direct_despawn_check_ms`, any despawn check within
`500 ms` of `lifetime_ms` or below its documented despawn delay, channeled spells in `allowed_spells` without a
`channeled_despawn_check_ms` branch, `gate_spell` in `learn`, `feed` combined with `setup_casts`, `feed` with a gate
spell whose `ProcChance` is not strictly in `(0, 100)`, unknown spells, and a `quote_spell` not embedded in `spell`'s
tooltip.
