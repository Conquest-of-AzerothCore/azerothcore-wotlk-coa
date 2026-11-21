# 0137. Group-target and cost-gate behaviour kinds, hit-ratio heals, tick counts

- Status: accepted
- Date: 2026-11-11

## Context

Lean Templar batch 1, chunk 2 (`lean/batch1-c2-brief.md`) drew clauses that only a data readback covered:

- energy cost and cooldown reductions: Grace of Aman'thul 301059, Battle Hardened 706309, Guardian of the Light
  707364;
- a target restriction: Righteous Custodian 572808 "Place a blessing on a party or raid member";
- a period: Righteous Custodian "every $t1 sec";
- healing done and received: Sacred Style 705278;
- a per-stack gain: Holy Upheaval 572547.

A spell modifier read back with `spell_power_cost` or `cooldown_ms` is data; the clause promises that the cast goes
through, or does not, at the reduced cost or time.

The control-arm gate of the chunk 2 tool step was dropped, so each new check carries its control arm by
construction.

## Considered options

1. Read the reduced cost or cooldown after the learn (`metric_delta` on `power` or `cooldown_ms`). Rejected:
   `cooldown_ms` is a readback, and a `power` read shows the cost paid, not whether a cast at that level is refused
   without the talent.
2. Extend `cast_gate`, whose arms are fixed to a target aura state. Rejected: its arms and reason code are specific
   to the health gate.
3. New kinds `cost_gate` and `group_target`, judged exactly on `cast_failure` and `aura` readings (check
   `behaviour_cast_condition`). Extend `hit_ratio` to heals and other actors, and `threat_tick_ratio` to a tick
   count. Chosen.

## Decision

- `cost_gate`:
  - arms `without` (talent unknown, refused: the control), `with` (goes through) and `beyond` (one power point, or
    `margin_ms`, past the stated reduction, refused);
  - optional `next` (a second cast without the setup cast, refused) and `held`/`expired` (the attempt before and
    after the end of the aura a setup cast grants);
  - power gates turn regeneration off.
- `group_target`: the same cast at an ungrouped player (refused, `SPELL_FAILED_BAD_TARGETS`, no aura: the control),
  at the same player grouped, and at the member that converts the group to a raid.
- `hit_ratio`:
  - `metric: "heal"` reads `spell_heal_total`/`spell_heal_count`;
  - `caster` and `target` name the healing player and its target (the harness reads a player's own heals);
  - the caster is armed for the observed rank.
- `threat_tick_ratio`: `ticks` and `label_suffix`, so one spell can hold a 0-tick control and several tick counts.

## Consequences

- Seven chunk 2 clauses are behaviour proven by these checks on two runs of one build:
  - 39 and 40 (301059);
  - 228 (706309);
  - 249 to 252 (707364).
  Three more use the two extensions: 138 and 140 (572808) and 186 (705278).
- A deterministic heal or a low-variance rank keeps a hit ratio within one scenario's trial limit. Holy Upheaval is
  observed on Righteous Upheaval rank 501562 at 30 stacks. Sacred Style is observed on Chakra of Light 803845.
  Chastise's per-hit spread (about 9%) keeps Pious Sweep 520034 out of reach: about 2000 trials per arm would be
  needed against 166.
- `cost_gate` resolves a fractional reduced cost by allowing the next whole point and refusing two points below it,
  so a 50% reduction of 15 Energy is proven between 7 and 8, not to the half point.
