# 0055. A `crit_guarantee` behaviour kind proves forced-crit-vs-creature-type clauses

- Status: accepted
- Date: 2026-11-10

## Context

Scourgebane 92111's tooltip ends "This is guaranteed to critically strike against Undead enemies." —
`claims-merged.json` marked it `missing`, `labels: []`, with `needs_new_metric: "a per-hit crit flag readable
on the Scourgebane extra-damage effect, filterable by target creature type (Undead)"`. The mechanism
(`AscensionTemplarAbilities.cpp:120`, `OnSpellCalculatedTarget`) is `if (info->Id == 801832 &&
(target->GetCreatureType() == CREATURE_TYPE_UNDEAD || ...)) hit.crit = true;` — a hard override of the hit's
own `TargetInfo.crit` at damage-calculation time, not a `SPELL_AURA_MOD_ATTACKER_SPELL_AND_WEAPON_CRIT_CHANCE`-
style stat change. The existing `spell_taken_crit_chance` metric (`player->SpellDoneCritChance` /
`target->SpellTakenCritChance`), already used for this exact clause shape on another class (the hand-written
`scenarios/chronomancer-wand-of-time-crits-undead-demons-10851.json`), reads the caster/target crit-chance
stat pipeline and is structurally blind to this hook: it would read the player's ordinary crit chance
regardless of the target's creature type. A real per-hit, per-target-type measurement was needed.

The existing `procs.py`/`PROC_CHECK` pipeline (Scourgebane's own `92111 proc_rate` entry) could not host this
without changing it: `add_proc`/`proc_label`'s disambiguation (`shares_aura`, `shares_proc_spell`,
`trigger_key`) keys only on `(aura, proc_spell, trigger)`, all identical between the existing entry and a
second one measuring the same `801832` trigger against a different target — adding a second `procs` entry
for aura 92111 would flip `shares_aura(CLASS_FILE, entry)` to `True` for both entries (one `test_procs.py`
test already pins this `False` for Scourgebane) and silently rename the already-proven `"92111 proc_rate"`
label to `"92111 proc_rate 801832 attack"`, breaking the clause ledger's existing reference to the old label.

## Considered options

1. Add a `variant` field to proc entries and thread it through `trigger_key`/`proc_label` so a second proc
   entry can share an aura without colliding. Rejected: still reuses `judge_proc`'s Wilson-interval machinery,
   which judges a *rate* against the tooltip's chance token — the wrong shape for "is every triggered hit a
   crit", and only incidentally provable by requiring the critical-only rate to equal the overall proc rate; a
   direct crit/non-crit count comparison is simpler, more direct, and does not depend on the tooltip chance
   token matching between the aura's own proc entry and this one.
2. A new `behaviours.py` kind, `crit_guarantee`: its own key namespace (`spell` + `kind`, already how
   `behaviour_entries`/`add_behaviour` disambiguate) cannot collide with the `procs` list at all. Chosen.

## Decision

- `behaviours.py` gains `BEHAVIOUR_CRIT_GUARANTEE`, `CritGuaranteeSpec` (`spell`, `name`, `quote`,
  `trial_spell`, `target_entry`, `target_type`, `target_type_name`, `attempts` default 100,
  `minimum_events` default 5), `crit_guarantee_scenario` and `crit_guarantee_spec`, wired into
  `behaviour_scenario`'s dispatch under `kind: "crit_guarantee"`.
- The scenario overrides `creature_fixture`'s shared `DUMMY_ENTRY` (Harvest Golem, `creature_template.type` 9,
  Mechanical) with the class file's declared `target_entry` and forces `reaction: 0` (the dummy's usual
  implicit friendliness does not carry over to an arbitrary creature template), then attacks it for `attempts`
  auto-attack swings and measures `spell_damage_count` of `trial_spell` against it twice: once
  `critical=True`, once `critical=False`. No `CoAGameplayTest.cpp` change was needed — `spell_damage_count`
  already supports both the `target` and `critical` filters (the same metric `hits.py`'s existing
  `critical_hits`/`blocked_hits` measurements use), proven class-agnostic already.
- `compare.behaviour_crit_guarantee_verdict` sums `crit + noncrit`; below `minimum_events` it reports
  `insufficient_trials` (the scenario did not generate enough triggers to judge, e.g. a `proc_rate` regression
  elsewhere); otherwise it bands `ratio = crit / total` against `1.0` through the existing `banded_status` (the
  round 10 `tolerated` mechanism): `ok` at exactly 1.0, `tolerated` within 5%, `alert` otherwise. The label is
  `f'{spell} behaviour_crit_guarantee {trial_spell}'`.
- `classes/templar.json` gains one `behaviours` entry for Scourgebane 92111, `target_entry: 1501` (Mindless
  Zombie, `creature_template.type` 6, `CREATURE_TYPE_UNDEAD`; `data/sql/base/db_world/creature_template.sql`),
  citing the `OnSpellCalculatedTarget` line and DUMMY_ENTRY's own, different type.

## Consequences

- Scourgebane's crit-guarantee-vs-Undead clause is proven end to end (two independent gameplay runs, both
  `ok`, 28/28 and 22/22 critical): the existing server mechanism already satisfies its own tooltip, and
  `classes/templar_clauses.json`'s label now reflects it instead of an empty, unproven list.
- The `crit_guarantee` kind generalises to any class's "this always crits against creature type X" clause: a
  new class-file entry naming the trigger spell and an in-type creature fixture, no further tool code.
- The existing `92111 proc_rate` entry, its label and `shares_aura`/`shares_proc_spell` disambiguation are
  untouched; nothing already proven through the `procs` pipeline changed shape.
