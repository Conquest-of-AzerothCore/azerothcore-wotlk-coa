# 0023. Generic hit scenarios place a friendly target for ally-targeted actives

- Status: accepted
- Date: 2026-11-07

## Context

Temple Guardian 803792 (Templar) charges to and heals a friendly unit (`Effect[1] = 10` heal,
`EffectImplicitTargetA[1] = 21` friend). `hits.py`'s generic hit-scenario builder never places a target for an
ally-targeted active: the scripted cast had no legal unit to charge to, so the probe failed
`SPELL_FAILED_BAD_TARGETS` and the check stayed `unmeasured` (round-2 item "Temple Guardian 803792 hit model
unmeasured", `round2/temple-guardian-spec.md`).

The same ally-casting mechanism already existed, proven in-game, in `procs.py`'s proc scenario for aura 804571
("Transcendent Guardian"), which casts the very same spell 803792 at an ally player fixture: an `ally`-tagged
`players` entry, a per-cast `relocate` fixture (`CHARGE_OFFSET_YD = 10` yd, inside `SpellRange` 54's `[5, 30]`
window) that keeps the caster in range after the previous charge closed the distance, and `cast['target'] =
'ally'`. It was private to `procs.py` (`ALLY`, `ALLY_TARGET`, `CHARGE_OFFSET_YD`, `targets_ally`), not shared with
`hits.py`.

Temple Guardian's tooltip also shares one expression token across its two heal effects (ally and self,
`design.md` Ruling P3-R7): the model's `tooltip_mean` already counts both. `hit_measurements`'s heal metrics
always filtered to one `target` (`TARGET` for damage, `CASTER` for heal), so even once a cast could reach the
ally, the measured total would still only capture the self-heal - half the modelled mean.

## Considered options

1. Add a Temple-Guardian-specific branch inside `hits.py`, keyed on the spell id. Rejected: violates "tool code
   stays class-agnostic"; the next ally-targeted active in any class would need its own copy.
2. Generalize the ally-casting primitives (`ALLY`, `FRIEND_TARGETS`/`targets_ally`, `CHARGE_OFFSET_YD`) into the
   shared `values.py`, used by both `procs.py` (deleting its private copies) and `hits.py`; extend `hits.py`'s
   scenario/measurement builders to detect an ally-targeted highest rank and reuse the same three ingredients
   (ally fixture, per-cast relocate, `target: 'ally'`) already proven by the 804571 proc scenario, and drop the
   heal metric's `target` filter for that case so the total sums both receivers. Chosen.

## Decision

- `values.py` gains `FRIEND_TARGETS = frozenset({21})`, `ALLY = 'ally'`, `CHARGE_OFFSET_YD = 10` and
  `targets_ally(facts)`, mirroring the existing `HOSTILE_TARGETS`/`is_hostile` pair. `procs.py` imports these
  instead of redefining them; no behaviour change there.
- `hits.py::cast_steps`'s `hostile: bool` parameter becomes `target: str | None` (`None`, `TARGET`, or `ALLY`),
  so a cast step can be aimed at any of the three; `procs.py` and `triggers.py`, the only other callers, pass the
  resolved target value directly instead of a hostile-ness boolean.
- `hit_parts` computes `ally = not hostile and targets_ally(hit.facts)`. When true, it appends an `ally` player
  fixture (built from the same `armed_file` used for the caster), passes a per-cast `relocate` fixture and
  `target='ally'` into `cast_steps`, and calls `hit_measurements` with `ally=True`.
- `hit_measurements` drops the `target` filter on the `total`/`count`/`critical_hits` heal metrics when `ally` is
  set, so the measured total sums both the ally's and the caster's own heal from the same cast. The hostile branch
  (damage, `blocked_hits`) is unchanged: a stray hit on an unexpected target must still not silently inflate a
  damage check.
- `compare.py::judge_hit` needs no change: it only ever reads the `total`/`count` labels `hit_measurements`
  produces and compares their ratio against the model's already-doubled `mean` (Ruling P3-R7); the fix is entirely
  in what the measurement step counts, not in how it is judged.

## Consequences

- Temple Guardian 803792's `hit_mean` check moves from `unmeasured` to a real reading: the exploratory scenario
  run this round (`conformance-templar-hit-803792`) shows 2 casts, 4 heal events (ally + self per cast), no
  `SPELL_FAILED_BAD_TARGETS`.
- Any future ally-targeted active (any class) that reaches `hit_parts` gets this scenario shape automatically,
  with no class-specific code: `targets_ally` reads the same DBC target-type field `is_hostile` already does, and
  classes data is untouched.
- `procs.py`'s own ally-casting path (804571 proc scenario) is unchanged in behaviour; its private constants are
  now re-exports of `values.py`'s, removing the duplicate `ALLY_TARGET = 21`.
