# Portal single cast and post-cast despawn (`behaviour_metric_delta`, `kind: "portal_single_cast"`, ADR 1296, provisional)

ADR 1296 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a summoned creature (such as Cultist's Void Portal `533030`) casts **exactly one** direct spell from an
allowed set and then **disappears after that cast**, strictly before its full summon lifetime would end.

## Harness primitives

- Read `owned_creature_total_cast_count` (`actor`, `entry`, optional `spell`, optional boolean `triggered`, default
  `true`): counts casts recorded by `ProcCounter` for the living owned creature of `entry`. With `triggered: false`,
  counts only non-triggered casts (`!spell->IsTriggered()`) so triggered sub-effects (for example Gaze of C'Thun
  `500110 -> 520334 -> 520332` or Obliteration Beam `805572 -> 805573`) do not inflate the cast count of one spell.
  Returns `-1` when no living owned creature of `entry` is present. Classified as `event` evidence in the kind's
  `METRIC_EVIDENCE` row.
- Action `cast_until_owned_creature` (`actor`, `spell`, `entry`, `every_ms`, `max_casts`; optional `target`,
  `cast_power`, `power`, `reset_cooldown`): mirrors `cast_until_aura` for a rolled summon proc whose roll cannot be
  forced, stopping on the first world update where `GetOwnedCreature(player, entry) != nullptr`.

## Scenario and arms

- `control`: runs before `gate_spell` is learned (one deterministic trigger cycle, or `cast_until_owned_creature` in
  `feed` mode) and reads `owned_creature_count` and `owned_creature_summon_count` of `entry`. Any spawn alerts.
- `treatment`: learns `gate_spell` and runs `portals` independent trials per part across `parts` pooled parts
  (minimum `6` portals per run; a one-portal anecdote is refused at generation time):
  1. Reads `owned_creature_count == 0` before triggering (nonzero is `unmeasured`).
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

## Refusals

Refuses fewer than `6` total portals per run, `cast_read_ms >= direct_despawn_check_ms`, any despawn check within
`500 ms` of `lifetime_ms` or below its documented despawn delay, channeled spells in `allowed_spells` without a
`channeled_despawn_check_ms` branch, `gate_spell` in `learn`, `feed` combined with `setup_casts`, `feed` with a gate
spell whose `ProcChance` is not strictly in `(0, 100)`, unknown spells, and a `quote_spell` not embedded in `spell`'s
tooltip.
