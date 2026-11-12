# 0298. Judge Crusader's Brand fleeing on a low-health creature

- Status: accepted
- Date: 2026-11-12

## Context

Crusader's Brand 300513 reads "Brand an enemy for $d, preventing them from ... fleeing". `AscensionTemplarContracts.cpp`
sets its Effect[2] to `SPELL_AURA_PREVENTS_FLEEING`. Since 3.0.2 that aura ignores fear and players and only stops
a creature fleeing at low health: `Creature::DoFleeToGetAssistance` returns when `HasPreventsFleeingAura()` holds
(`Creature.cpp:1124`), and SmartAI `SMART_ACTION_FLEE_FOR_ASSIST` calls it (`SmartScript.cpp:1101-1107`). The
conformance entry `behaviours[72]` read one `moving` value of a feared caster, so it measured a case the aura never
covers. The owner ruled on 2026-11-12 (`method-study/owner-rulings-2026-11-10.md`, status-5 section): option (a),
"fleeing" is low-health creature fleeing, and the check is replaced, with several reads.

## Options

- A `metric_delta` variant with several reads. That kind's phases are built around one dummy and one trigger cast, and
  it has no creature entry, no health step and no summed reads.
- A new `flee_block` kind with its own two creatures, judged by the existing summed `cast_condition` verdict. Chosen.

## Decision

`kind: "flee_block"` takes `creature_entry`, `flee_health_pct`, `reads` and `read_interval_ms`. It spawns two
defensive creatures of that entry with 1,000,000 health. The defensive reaction makes them take the caster as victim,
which `DoFleeToGetAssistance` needs, and the health keeps the brand's retaliation from killing the branded creature
during the reads. The caster casts the brand at the first creature, which is a real application. Each arm attacks for
1000 ms, stops, brings the creature to `flee_health_pct` with `set_health_pct` and reads `moving` `reads` times.
`behaviour_cast_gate_verdict` gains `at_least` for `sum_labels`: the control's sum must be at least 1, while the
branded sum stays exact at 0.

Templar's entry uses Zulian Cub 11360 (level 60). Its only SmartAI row is health 0-15%, flee for assist, no repeat
(`acore_world.smart_scripts`). The entry sets 10% health and 5 reads, 250 ms apart. The feared-caster entry is removed.
Its phase-aura tests keep the same entry inline.

## Consequences

- On the counted pair 20261112-081541 / -081619 (build c1316db6cb1a), the branded cub read 0 of 5 and the control 5 of
  5 in both runs. Ledger row 19 now names the five `flee_block` labels.
- The kind relies on a creature entry with a low-health flee row in the test world. A world without that row leaves
  the control at 0, which alerts instead of passing.
