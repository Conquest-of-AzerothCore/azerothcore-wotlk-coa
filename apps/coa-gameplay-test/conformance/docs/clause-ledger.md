# Clause ledger and clause coverage

A clause ledger (`classes/<name>_clauses.json`) is the per-class list every tooltip clause reduces to, used to
report how many are actually proven by the current measurements rather than how many spells have *some*
verdict.

## File format

A JSON array. Each entry is one clause:

```json
{"spell": 92111, "clause": "dealing an additional $801832s2% Weapon damage", "labels": ["92111 effect_value 801832e1 #0"],
 "kind": "claim"}
```

- `spell`: the spell id the clause's tooltip belongs to.
- `clause`: the exact clause text, as split out by the class's clause audit (so it can be traced back to that
  audit and to the tooltip itself).
- `labels`: the `Verdict.label` values (from `verdicts.json`, e.g. `write_verdicts`'s output) whose status
  proves this clause. Empty until a workstream's fragment (below) supplies them. A label may be a passive
  effect's own "checked by ..." label rather than the verdict it points at: `compare.resolve_linked_statuses`
  (ADR 0052) gives that label the same live `ok`/`tolerated`/`closed`/`alert` status as the thing it is
  checked by, so either label proves the clause equally.
- `kind`: `"claim"` for a clause with a gameplay meaning to prove, or `"no_claim"` for a line that carries no
  mechanic (a level-gate label, an empty tooltip, flavour/acquisition text). A `"no_claim"` entry also carries
  `"reason"`, the audit's note explaining why.

## How a workstream contributes

A workstream other than the one that owns and merges the ledger never edits `classes/<name>_clauses.json`
directly. It writes its own fragment, an array of:

```json
{"spell": 92111, "clause": "<exact clause text from the clause audit>", "labels": ["<verdict label>", "..."],
 "kind": "claim"}
```

The integrator merges these fragments into the ledger by matching on `(spell, clause)` and replacing that
entry's `labels` (a `kind: "no_claim"` entry is never produced by a fragment; only the ledger's initial
generation from the clause audit sets it).

An owner ruling is the one other source of `no_claim`: when the owner rules that a tooltip text does not govern
(it loses to another text the player sees), the commit applying the ruling sets that clause's `kind` to
`"no_claim"`, empties its `labels` and cites the ruling in `reason`. Example: Righteous Tempest's tick spell
805410, whose `$SP*.15` loses to the spellbook's `$SP*0.3` (ADR 0104 D1). A ruling that keeps a clause as a claim
but leaves it without a proving test empties its `labels`, so the clause counts as unproven until that test exists.

## Coverage

`coverage.clause_coverage(clauses, verdicts, build)` returns a `ClauseCoverage`:

- `total` counts only `kind: "claim"` entries (`no_claim` entries are never part of the denominator).
- A claim is **proven** when it has at least one label and every one of its labels' live verdict status (from
  the `verdicts` list passed in — always the same compare run being reported on) is `ok`, `tolerated` or
  `closed` (`compare.CONFORMANT`). A claim with no labels yet, or any label whose live status is anything else
  (including a label that is simply absent from this run's verdicts), is unproven.
- A label may omit the trailing `" #<ordinal>"` that `values.py` appends when a spell has several tokens of
  the same effect/spell/kind (`92111 effect_value 801832e1`, not `92111 effect_value 801832e1 #1`) — the audit
  (`claims-merged.json`) writes labels this way since it cannot predict the ordinal a future generate run will
  assign. `resolved_labels(label, statuses)` expands such a label to every verdict label in this run that
  starts with `"<label> #"` followed by digits; the clause needs every one of those matches present and
  conformant (not just one), since each is a distinct occurrence of the same clause in the tooltip. A label
  that already ends in `" #<ordinal>"` is matched exactly, never expanded.
- `unproven` is the list of clause entries that did not qualify, for printing with their tooltip words.

### Two proof statuses

`ClauseCoverage` holds `proven`, `behaviour`, `data` (`proven - behaviour`), `total`, `unproven`, the per-claim
`evidence` and the `not_measured` labels. A proven claim is **behaviour proven** when at least one of its matched
verdicts is behaviour evidence, otherwise **data conformant**. The figure reported to the owner is `behaviour`;
`data` is reported beside it.

`build` is the build being judged, the verdict set's header `build` (a worldserver sha256). Every verdict carries its
own `build`, `server_commit` and `runs` ([Verdicts](generate-and-compare.md#verdicts)); a set holding a verdict of
another build, or a verdict without one, is refused with `EvidenceError`, alerts as well as proofs (ADR 0120), and so
is a non-empty set for which no single build is named. `not_measured` verdicts are not conformant, so a claim citing
one is unproven; `ClauseCoverage.not_measured` lists their labels and the coverage output prints them.

Each verdict's evidence comes from its `check` through the closed table `coverage.EVIDENCE`; a verdict whose check is
not in the table fails the whole run (`EvidenceError`, no default):

- `data`: readbacks of computed values (`values.CHECKS`: `effect_value`, `aura_amount`, `aura_duration_ms`,
  `max_stacks`, `spell_duration`, `power_cost`, `cooldown_ms`, `known_aura`, `effect_radius`, `aura_amplitude_ms`),
  the trigger cooldown and duration deltas (they read `cooldown_ms` and `aura_duration_ms`), and the behaviour kinds
  that read a live aura's duration or amount (`behaviour_duration`, `behaviour_duration_ratio`,
  `behaviour_duration_refresh`, `behaviour_amount_delta`).
- `behaviour`: observed outcomes: hit, melee and periodic means, proc rates and deltas, trigger counts, magnitude
  ratios, self triggers and gate absences, stack DPS, and the behaviour kinds that count hits, casts or auras on units
  (`behaviour_count`, `behaviour_trigger`, `behaviour_crit_guarantee`, `behaviour_aura_grant`,
  `behaviour_oath_consumption_removal`, `behaviour_internal_cooldown_gate`, `behaviour_exclusivity`,
  `behaviour_single_target`, `behaviour_fixed_count`, `behaviour_internal_cooldown`, `behaviour_heal_block`,
  `behaviour_cast_applies_aura`), cast allowed or refused (`behaviour_cast_gate`, `behaviour_cast_condition`,
  `behaviour_cast_combat`, `behaviour_charge_recharge`: the over-cast refusal and the charge count after real casts),
  units changed by a cast (`behaviour_mount_grant`, `behaviour_aggro_redirect` the creature's victim,
  `gap_closer_distance` the caster's distance after a charge), damage against a live shield
  (`behaviour_absorb_pierce_ratio`) and threat after a periodic tick has acted (`behaviour_metric_ratio_delta`).
- by metric: `passive_delta`, `behaviour_metric_delta`, `behaviour_ratio`, `behaviour_oath_consumption`,
  `behaviour_group_stack_cap`, `behaviour_crit_magnitude`, `behaviour_party_stat_ratio` take the class of their
  observed metric, which `compare`
  stamps into the verdict's `detail.metric` from the expectation model. `coverage.METRIC_EVIDENCE` is closed too:
  `event` (hits, heals, energizes, casts, procs, auras on a unit including `water_walk`, which reads
  `HasAuraType(SPELL_AURA_WATER_WALK)`, owned creatures, timeline events, the event times of ADR 0119) is behaviour;
  `readback` (spell definitions, live aura values, cooldowns and the in-process damage, healing and crit probes such
  as `spell_damage_done` or `aoe_damage_taken`) is data; `state` (stat fields: `stat`, `armor`, ratings, hit, crit,
  dodge and parry chances, power, speed, attack time) is data, except that a state read counts as behaviour when it
  is the stat the clause promises, read in a learned/unlearned contrast: the check is `passive_delta`,
  `behaviour_party_stat_ratio` (an ally's stat before and after the caster learns the spell), or
  `behaviour_metric_delta` with `detail.contrast` `learned` (not the `setup_only_after` condition contrast), and the
  clause text names the stat (`coverage.STATE_PROMISES`, for example `armor` needs "armor"). A stat read as a proxy
  for another effect stays data.
- linked: a `checked by` label (`unmodelled` check closed by the labels it names) is behaviour when one of the
  referenced verdicts is.
- A `closed` verdict closed by its rule, without a measurement, is data whatever its check.

A ledger fragment (`coverage --fragment`, `fragment_entries`) lists every claim with its computed `evidence` and the
`Spell.dbc` sha256 of the verdicts; `fragment_entries` and `read_fragment` refuse another or a missing sha (ADR 0117).
The status is computed from these tables, never typed (ADR 0120).

Run it from the command line together with the ordinary before/after coverage report:

```
python conformance.py coverage --before <dir> --after <dir> --clauses classes/templar_clauses.json
```

This prints `clauses proven: N of M (P%)`, `behaviour proven`, `data conformant` and the `not_measured` count,
followed by every unproven clause's spell id, text and current labels, read from `--after`'s `verdicts.json`, so the
number always matches the run being reported on, never a cached or hand-recorded count. An unknown check or metric,
verdicts of another build, or a fragment request on verdicts of another `Spell.dbc` end the command with exit code 3
and no clause count; `--fragment <path>` writes the fragment to a new file.
