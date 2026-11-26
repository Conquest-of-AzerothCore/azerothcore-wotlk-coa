# 1258. An opted-in script count read proves a stated count driven by real casts

- Status: proposed
- Date: 2026-11-23
- Related: [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (the closed evidence tables),
  [ADR 0616](0616-a-contrast-gated-read-is-behaviour-evidence-only-with-its-contrast.md) (`evidence_metric`),
  [ADR 1194](1194-an-opted-in-use-time-read-proves-its-claim-with-its-named-arms.md) (an opt-in evidence rule),
  [ADR 1241](1241-aura-fed-effect-instant-casting-carries-its-aura-fed-contrast.md) (an opt-in state metric of a
  module).
- Decided by: mentor D-70 (B-6), controller go of 2026-11-23.

## Context

Felsworn Annihilation 803904 keeps its remaining attacks in the aura script value (`AscensionFelswornAuras.cpp:68-72`:
5, the DBC ProcCharges, plus the SPELLMOD_CHARGES mods); `Aura::GetCharges` stays 0, so `aura_charges` cannot read the
"$n attacks" of its tooltip, nor the "$s1 additional attack" of Pit Lord's Strength 802076 and 802110 (SPELLMOD_CHARGES
on 803904). A measured pair read 5, 6 and 7 through `aura_script_value` (fw-b3g4), but that metric has no row in
`coverage.METRIC_EVIDENCE`, so coverage stopped with EvidenceError. A script value is any number a script stores; a row
on the metric would let every such read count.

## Options

- Register `aura_script_value` in `METRIC_EVIDENCE` as a class that can reach behaviour. Rejected by the mentor
  (D-70): it applies to every script value.
- Keep the reads out of coverage. The three tooltip counts could then never be measured.
- An opt-in the entry asks for, refused at generation unless the read is the count the sentence states, real play
  drives it, and a contrast arm reads another value when the driving event is absent or different.

## Decision

The third option, as the option module `metric_delta_options/script_count.py` (no change to `behaviours.py`,
`coverage.py` or `compare.py`).

- Entry field `script_count: {"noun": "attack" | "charge" | "stack"}`. The read stays `aura_script_value`; the model
  stamps `evidence_metric: "aura_script_count"`, a STATE metric of the module with the promise words
  `attacks?|charges?|stacks?`. Coverage then counts it as behaviour through the existing state path: a conformant
  verdict with the learned contrast whose claim or row names the counted word.
- The generator refuses the opted entry unless: (1) the quote holds a `$` token followed by the noun (at most one word
  between) and the read aura is the entry spell or named in the quote; (2) the scenario is the plain with/without
  layout with a real cast of the trigger between the readings, no `set_aura` step, and no step on the read aura other
  than `cast`, `learn`, `assert` or `reset_cooldown`; (3) the before arm lacks the driving cast (`cast_in_before`
  false, no trigger cast before the before reading) or casts it under another gate than the trigger, and the two
  expected readings differ by more than twice the tolerance; the read is judged exactly (no ratio, floor, ceiling or
  own `evidence_metric`).
- An entry naming `evidence_metric: "aura_script_count"` without the option is refused.
- The module classes `aura_script_value` itself as READBACK, with no `CONTRAST_PROOF` row: a read without the option is
  data, never behaviour (D-70: "without the opt-in the evidence stays data"). The cross-class guards of
  `test_coverage.py` need a row for every raw `metric` a class file uses, so a metric without any row cannot stay in a
  class file; the controller chose this row over pulling the entries (2026-11-23).

## Consequences

- Tests: `metric_delta_options/test_script_count.py`: the stamp and driver, unchanged steps without the option, the
  option's shape, the refused unopted stamp, each refusal rule with its case and a mutant per rule (the rule removed
  lets its case through), seeded scenarios for the step and cast rules, behaviour for a right count, an alert for a
  wrong one, data for a claim without the counted word, data without the option, and a mutant that classes the plain
  read as state with the count words (it then counts as behaviour).
- Finished classes use no entry with the field and no class file other than Felsworn names `aura_script_value`; the
  Templar `oath_consumption_removal` kind reads it but carries its own BEHAVIOUR check class, which coverage settles
  before any metric class. Their generated scenarios regenerate byte-identical.
- The read is the server's stored count at the first reading after the cast, not the number of attacks the aura
  actually lasts; a claim about consumption per attack needs another read.
- Number provisional: shared ADRs are numbered at merge.
