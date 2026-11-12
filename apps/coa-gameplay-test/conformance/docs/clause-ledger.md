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
- `claims` (optional, a `"claim"` entry only): the stated claims of a clause whose labels would otherwise prove only
  part of it, each `{"claim": "<the tooltip words of that claim>", "labels": [...]}`, at least two, in place of the
  entry's `labels` (an entry carrying both is refused). Without `claims` the entry's `labels` are its one claim.
- `tool_gap` (optional, a `"claim"` entry only): a clause an agent could not prove because the tool lacks a metric,
  step or setup, `{"reason": "<what the tool lacks>", "attempts": [{"agent": "<who tried>", "report": "<where>"}],
  "owner_acceptance": {"ruling": "<file#section>"}}` (`owner_acceptance` optional). See [Tool gaps](#tool-gaps).
- `text_source` (optional): the `coa_client_spell_description` row the spell's text is read from (ADR 0192):
  `spell`, `file`, `commit`, `pr`, `basis` (`owner_ruling`, `live_source`, `text_correction` or `align_to_server`),
  `ruling` and `dbc_differs`. Coverage refuses a ledger entry whose spell has a streamed row and no `text_source`
  (ADR 0198). `dbc_clause` keeps the client DBC's words of a clause the streamed text changed; such a claim counts only
  when its basis is `owner_ruling` or `live_source`, or `text_correction` with every number, `$` token and colour-named
  spell the same in both (`streamed.figures`). Otherwise it is counted unproven and listed as judged against a
  project-written text.
- `no_behaviour_route` (optional, a `"claim"` entry only, never beside `tool_gap`): a data conformant clause no
  behaviour check can reach, `{"reason": "<why no route exists>", "attempts": [{"agent": "<who tried>", "report":
  "<where>"}]}`. See [No behaviour route](#no-behaviour-route).
- `effectiveness_of` (optional, a `"claim"` entry without `claims`, ADR 0268): the spell id of the buff X in a clause
  that increases "the effectiveness of X". When X's entries, of any `kind`, state exactly one value in all (a `${...}`
  formula, a `$` token other than a duration, radius or range, or a literal number), the entries carrying it are added
  to the claim's words for the state-promise match; with two or more values, or none, nothing changes. Templar:
  Martyr 300530 names Gift of Zeal 300923.

### Stated claims

A clause states one claim per value it gives (a magnitude, a duration, a stack count, a radius, a period, a chance,
a target count, a literal number such as "40%" or "8 yds") and per quantity one value moves through a separate
effect ("damage dealt and movement speed by $560834s1%": Duty Calls 560834 holds them in e0, aura 79, and e1, aura
31). A clause is closed only when every stated claim is proven (ADR 0123). An entry declares `claims` when its labels
measure only some of them; an entry whose labels already cover every stated claim, or whose other claims have their
own entries, needs none. Example:

```json
{"spell": 524739, "clause": "and reduces their damage and healing done by $520842s1% for $520842d.",
 "claims": [{"claim": "and reduces their damage done by $520842s1%", "labels": ["524739 effect_value 520842e0 #3"]},
            {"claim": "and healing done by $520842s1%", "labels": []},
            {"claim": "for $520842d", "labels": ["524739 spell_duration 520842 #4"]}],
 "kind": "claim"}
```

Templar: 30 entries declare claims, over 28 spells (92109, 300504, 300520, 520034, 524620, 524739, 524765, 560835,
572769, 573324, 680399, 681483, 705278, 705284, 705286, 705290 twice, 705306, 706320, 800424, 801480, 801481 twice,
804228, 804781, 805417, 805422, 806522, 807814, 1397742). The first 12 (92109, 300504, 524739, 560835 burst, 680399,
681483, 705286, 705306, 800424, 805417, 806522, 807814) came 11 from the audit of the clauses counted proven on round
10 (`templar-run2`); 8 of those then had a claim no label measured. Barrier of Light 805417 splits its 40% (behaviour) from its "for $d"
(a duration readback), so the clause stays data conformant.

## How a workstream contributes

A workstream other than the one that owns and merges the ledger never edits `classes/<name>_clauses.json`
directly. It writes its own fragment, an array of:

```json
{"spell": 92111, "clause": "<exact clause text from the clause audit>", "labels": ["<verdict label>", "..."],
 "kind": "claim"}
```

The integrator merges these fragments into the ledger by matching on `(spell, clause)` and replacing that
entry's `labels` (a `kind: "no_claim"` entry is never produced by a fragment; only the ledger's initial
generation from the clause audit sets it). A row carrying `claim` (one claim of a clause with declared `claims`)
matches on `(spell, clause, claim)` and replaces only that claim's `labels`: it never closes the clause.

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
  (including a label that is simply absent from this run's verdicts), is unproven. An entry with declared
  `claims` is proven only when every one of its claims is; `ClauseCoverage.claim_evidence` holds the status of each
  claim, in the order of `evidence`.
- A label may omit the trailing `" #<ordinal>"` that `values.py` appends when a spell has several tokens of
  the same effect/spell/kind (`92111 effect_value 801832e1`, not `92111 effect_value 801832e1 #1`) — the audit
  (`claims-merged.json`) writes labels this way since it cannot predict the ordinal a future generate run will
  assign. `resolved_labels(label, statuses)` expands such a label to every verdict label in this run that
  starts with `"<label> #"` followed by digits; the clause needs every one of those matches present and
  conformant (not just one), since each is a distinct occurrence of the same clause in the tooltip. A label
  that already ends in `" #<ordinal>"` is matched exactly, never expanded.
- `unproven` is the list of clause entries that did not qualify, for printing with their tooltip words.

### Tool gaps

A tool gap is never proof: the clause stays unproven and in the coverage denominator. It counts as **resolved**
(`tool_gap_state` `accepted`) only after a second attempt by another agent, two `attempts` with different `agent`
values, or an explicit owner acceptance (`owner_acceptance.ruling`, the ruling that accepts it); one agent's
attempt, or several by the same agent, is `pending` and counts unresolved (ADR 0127; prototype review I4: two tool
gaps one arm declared were disproved by another arm). The second attempt is a fresh try to prove the clause, not a
review of the first report; an agent that proves it removes the `tool_gap` and cites its labels. `clause_coverage`
refuses a malformed `tool_gap` (no reason, no attempt, an attempt without agent or report, a non-claim entry) and
ignores the gap of a clause that is proven. `ClauseCoverage.tool_gaps` lists the unproven clauses with a gap and
their state; `accepted_tool_gaps`, `pending_tool_gaps` and `resolved` (`proven + accepted_tool_gaps`) are printed by
`coverage --clauses` and written per run by `prove` (`summary.json` `coverage`). A fragment row of an unproven
clause carries the clause's `tool_gap` and its `tool_gap_state`; the integrator appends a fragment's attempts to the
ledger entry's `attempts`, never replaces them.

Example of the shape (one attempt, so `pending`; a second entry in `attempts` by another agent, or an
`owner_acceptance`, would make it `accepted`):

```json
{"spell": 92108, "clause": "Your off-hand auto attacks now trigger Zealotry.", "labels": ["92108 trigger_count"],
 "kind": "claim", "tool_gap": {"reason": "the harness cannot produce an off-hand swing for this class",
 "attempts": [{"agent": "round10/proc-chains", "report": "round10/workstreams/proc-chains.md"}]}}
```

No Templar ledger entry declares a `tool_gap`. Zealotry 92108 "Your off-hand auto attacks now trigger Zealotry."
is proven on the Templar as created, which already dual wields: the trigger equips an off hand without granting Dual
Wield 674; its entry carries a `reason` citing the evidence and the owner ruling (a claim entry may carry `reason`
for the ruling or evidence its proof relies on). Two clauses wait for tool work, without
a declaration: Pulverizing 524620's damage claim needs a hit model for a proc spell, and Parry Dance 804912 "your
chance to parry is now increased by $560651s1%" needs a parried-attacks-taken metric.

### No behaviour route

The owner's terminal status of 2026-11-11 (ADR 0136): a clause that only a data check can verify, because no
behaviour route exists, is **data conformant, no behaviour route** once it states the reason and two agents have
tried to build a route (two `attempts` with different `agent` values, the I4 rule of tool gaps; no owner acceptance
replaces the second attempt). `no_route_state` is `terminal` for a data conformant clause with two agents, `pending`
with one, and `not_data` for a clause that is unproven or behaviour proven (the declaration then closes nothing).
A terminal clause stays data conformant and in the denominator; it counts as closed, not resolved, and leaves the
remaining work. `ClauseCoverage.no_routes` lists the declaring clauses with their state; `terminal_no_route` and
`open_data` (`data - terminal_no_route`) are printed by `coverage --clauses` as their own lines, and a fragment row
carries the declaration and its `no_behaviour_route_state`. `clause_coverage` refuses a malformed declaration (no
reason, no attempt, an attempt without agent or report, a non-claim entry, a clause that also declares a
`tool_gap`).

No Templar ledger entry declares it.

### Two proof statuses

`ClauseCoverage` holds `proven`, `behaviour`, `data` (`proven - behaviour`), `total`, `unproven`, the per-claim
`evidence` and the `not_measured` labels. A proven claim is **behaviour proven** when at least one of its matched
verdicts is behaviour evidence, otherwise **data conformant**; a state read is judged against the claim's own
words. A proven entry with declared claims is behaviour proven only when every one of its claims is, otherwise
data conformant (owner ruling 2026-11-11, ADR 0131). The figure reported to the owner is `behaviour`; `data` is
reported beside it.

`build` is the build being judged, the verdict set's header `build` (a worldserver sha256). Every verdict carries its
own `build`, `server_commit` and `runs` ([Verdicts](generate-and-compare.md#verdicts)); a set holding a verdict of
another build, or a verdict without one, is refused with `EvidenceError`, alerts as well as proofs (ADR 0120), and so
is a non-empty set for which no single build is named. `not_measured` verdicts are not conformant, so a claim citing
one is unproven; `ClauseCoverage.not_measured` lists their labels and the coverage output prints them.

A K3 consumption row (`classes/<class>_consumption.json`, written by `conformance.py k3`, see
[Server mutants and K3 consumption](generate-and-compare.md#server-mutants-and-k3-consumption)) of the judged build
turns a conformant readback label into behaviour evidence when its result is `consumed`: a server mutant of the
value moved an acting observation in every run. A `not_consumed` row keeps the label data;
`ClauseCoverage.promoted` and `ClauseCoverage.not_consumed` list them and the coverage output prints both. Rows of
another build count for nothing (ADR 0129).

Each verdict's evidence comes from its `check` through the closed table `coverage.EVIDENCE`; a verdict whose check is
not in the table fails the whole run (`EvidenceError`, no default):

- `data`: readbacks of computed values (`values.CHECKS`: `effect_value`, `aura_amount`, `aura_duration_ms`,
  `max_stacks`, `spell_duration`, `power_cost`, `cooldown_ms`, `known_aura`, `effect_radius`, `aura_amplitude_ms`),
  the trigger cooldown and duration deltas (they read `cooldown_ms` and `aura_duration_ms`), and the behaviour kinds
  that read a live aura's duration or amount (`behaviour_duration`, `behaviour_duration_ratio`,
  `behaviour_duration_refresh`, `behaviour_amount_delta`, `behaviour_cast_applies_aura`: remaining-time readbacks,
  ADR 0126).
- `behaviour`: observed outcomes: hit, melee and periodic means, proc rates and deltas, trigger counts, magnitude
  ratios, self triggers and gate absences, stack DPS, and the behaviour kinds that count hits, casts or auras on units
  (`behaviour_count`, `behaviour_trigger`, `behaviour_crit_guarantee`, `behaviour_aura_grant`,
  `behaviour_oath_consumption_removal`, `behaviour_internal_cooldown_gate`, `behaviour_exclusivity`,
  `behaviour_single_target`, `behaviour_fixed_count`, `behaviour_internal_cooldown`, `behaviour_heal_block`), a
  stated duration's expiry pair (`behaviour_expiry`, ADR 0126), cast allowed or refused (`behaviour_cast_gate`,
  `behaviour_cast_condition`,
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
  as `spell_damage_done`, `aoe_damage_taken`, `spell_damage_taken` or `melee_damage_taken`) is data. An internal
  damage read is behaviour only when its value comes from a damage event applied in the run (the amount a unit lost,
  or the log the server emitted for that hit, such as the `taken_hit` reads); it is a readback when the harness calls
  a calculation function or reads a stored modifier with no hit applied (trial question 4, 2026-11-11): the two
  `*_damage_taken` metrics return `SpellDamageBonusTaken` and `MeleeDamageBonusTaken` of a fixed 1000
  (`CoAGameplayTest.cpp`, the `spell_damage_taken || melee_damage_taken` branch); `state` (stat fields: `stat`,
  `armor`, ratings, hit, crit, dodge and parry chances, power, speed, attack time) is data, except that a state read
  counts as behaviour when it is the stat the clause promises, read in a learned/unlearned contrast: the check is
  `passive_delta`, `behaviour_party_stat_ratio` (an ally's stat before and after the caster learns the spell), or
  `behaviour_metric_delta` with `detail.contrast` `learned` (not the `setup_only_after` condition contrast; a
  `stat_gain` verdict gets it from its judge under attribution reads and names its read, ADR 0258), and the clause
  text names the stat (`coverage.STATE_PROMISES`, for example `armor` needs "armor", `spell_power` "spell power" or
  "spell damage"; `max_power` takes the power names of `passives.POWER_NAMES` and `combat_rating` "rating" or a
  `passives.RATING_NAMES` phrase such as "armor penetration", ADR 0190). A stat read as a proxy for another effect
  stays data. A conformant verdict with `detail['data_only']` (a `passive_delta` the integer floor alone accepted, or
  whose integer stat did not move; ADR 0124) is data whatever its metric.
- linked: a `checked by` label (`unmodelled` check closed by the labels it names) is behaviour when one of the
  referenced verdicts is.
- A `closed` verdict closed by its rule, without a measurement, is data whatever its check.

A ledger fragment (`coverage --fragment`, `fragment_entries`) lists every claim with its computed `evidence` and the
`Spell.dbc` sha256 of the verdicts. An entry with declared claims gives one row with its `claims` (each with its
`evidence`) when every claim is proven, otherwise one row per claim (`claim`, `labels`, `evidence`), which never
closes the clause; `fragment_entries` and `read_fragment` refuse another or a missing sha (ADR 0117).
The status is computed from these tables, never typed (ADR 0120).

Run it from the command line together with the ordinary before/after coverage report:

```
python conformance.py coverage --before <dir> --after <dir> --clauses classes/templar_clauses.json
```

This prints `clauses proven: N of M (P%)`, `behaviour proven`, `data conformant`, the accepted and pending tool gaps,
`clauses resolved` and the `not_measured` count, followed by every unproven clause's spell id, text and current
labels and the tool gaps with their state, read from `--after`'s `verdicts.json`, so the
number always matches the run being reported on, never a cached or hand-recorded count. An unknown check or metric,
verdicts of another build, or a fragment request on verdicts of another `Spell.dbc` end the command with exit code 3
and no clause count; `--fragment <path>` writes the fragment to a new file.
