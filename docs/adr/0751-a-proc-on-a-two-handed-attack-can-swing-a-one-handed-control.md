# 0751. A proc on a two-handed attack can swing a one-handed control

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 284.0 (Grasp of the Undying 707064, "Auto attacks while wielding a two-handed weapon now have a
$707860h% chance to unleash Grasp of the Undying") is judged by `707064 proc_rate`, whose trials are the main-hand hits
of the Black Knight two-hander 2529. The c11 review (I-5) held the part: nothing shows that the proc needs the
two-handed weapon, since the proc tool offers a baseline arm only to `cast`, `minion` and `taken_hit` triggers, and the
c14 baseline fix (ADR 0728) refuses an attack trigger. The handler (AscensionWitchHunterEvents.cpp, Check case 707064)
passes a swing only while a two-handed weapon is wielded. Mentor decision D-209 (c14 tool batch item 15).

## Options

- A `control_weapon` entry option naming a class-file weapon set with a one-handed main hand: part 1 swings that main
  hand with the aura learned before the treatment swings and counts the same events, which must stay 0.
- A baseline before the learn, as for a cast trigger: it shows only that the aura causes the procs, not the weapon
  condition the claim states.
- A separate metric_delta entry: one swing window cannot tell a 25% roll from none without the proc sizing.

## Decision

The first option. The control main hand comes from the class file's existing per-spec weapon sets (Witch Hunter:
Inquisition, 2027 Scimitar), never a scaffold default; the entry's own set must hold a two-handed main hand
(InventoryType 17) and the control set a one-handed one (13 or 21). Part 1 learns the aura, equips the control main
hand, swings `ceil(baseline_attempts x 3/2)` times (30 at 25%), drains, reads the landed main-hand hits and the events
as the baseline labels, and re-equips the own main hand before its treatment swings; those control counts are taken
out of the treatment totals as a baseline's are. The judge alerts on any control event, and returns
`insufficient_trials` when the control holds fewer landed hits than `baseline_attempts` (20 at 25%) or when the part
holding it was not counted. The option is refused with a cast, minion or taken-hit trigger, an off-hand or per-trigger
count, a baseline, extra event terms, trial readings or charges. The control time is held in every part, as a
baseline's is, so the part count grows (707064: 99 to 114 parts).

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); neither class
  file sets the option (a seeded test checks it).
- False alert: 0 on a server that keeps the two-handed condition (no roll at all on the one-hander). False pass (a server
  that ignores the condition at 25%): 0.75^20 = 0.32% per run at the minimum of 20 landed hits, 1e-5 per pair.
- Seeded tests: the control arm order (learn, one-hander, control reads, two-hander, treatment), its model and rule; no
  control in later parts or without the option; the refusals; the judge takes a silent control out of the trials,
  alerts on seeded control procs (the mutant of a server that ignores the weapon), and does not judge too few control
  hits or an uncounted control part.
- Witch Hunter: `707064` sets `"control_weapon": "Inquisition"`.
