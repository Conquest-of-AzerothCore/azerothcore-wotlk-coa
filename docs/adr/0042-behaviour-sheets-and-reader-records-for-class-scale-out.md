# 0042. Behaviour sheets and reader records to scale class conformance past Templar

- Status: accepted
- Date: 2026-11-09

## Context

Templar (class 19, `classes/templar.json`) needed ~150 hand-written entries (`procs`, `triggers`, `behaviours`,
`passive_targets`, `talent_modifiers`, `effect_overrides`, `unmodelled_effects`, `literal_tokens`, `effect_notes`)
to close most of its `unmodelled`/`unreadable` verdicts, and that investigation took days
(`.agents/plans/class-conformance-3/scale-out-sweep.md`). 20 more CoA classes follow; re-deriving each one from
raw DBC dumps by hand does not scale. The owner's premise: a player (and a reader given the same material) can
deduce almost every effect from the tooltip plus the client data, so the deduction step should move from "an agent
re-reads raw DBC for a spell with no entry" to "a cheap reader turns an already-resolved document into a candidate
class-file entry", following the design in `.agents/plans/class-conformance-3/scale-out-sheets.md`.

## Decision

Split the pipeline into three pieces, each independently testable:

1. **`sheets.py`**: a deterministic `sheet(dbc_dir, class_file, spell_id, verdicts_dir=None)` that assembles a
   per-spell document from code this package already runs — `tooltip.read_tooltip` at two `CasterStats` bounds,
   `passives.classify` called generically (`spell_id == rank_id`, so it works on any spell id, not only a class's
   declared passive ranks), the raw `ProcFlags`/`ProcChance`/`ProcCharges`/`EffectTriggerSpell[n]` fields, duration/
   cooldown/aura-state facts (`values.facts_of`), a `grep -rn -w <spell_id>` scan of `src/server/coa` for scripted
   hooks DBC alone cannot show, and that spell's existing verdicts when `--verdicts` is given. A sheet carries no
   `classes/<name>.json` entry and no verdict judgement beyond the raw rows, so a reader given only the sheet
   cannot see what the class file already claims. `conformance.py sheets` writes one JSON and one text sheet per
   `--spell` into `--out`.
2. **`records.py`**: the reader record shape (`spell_id`, `entry_kind`, `entry`, `sources`, `reader`, `confidence`,
   `rationale`), a validator (`validate_record`) against `REQUIRED_ENTRY_FIELDS`/`KEY_FIELDS` derived from the
   fields every existing Templar entry of each kind actually has in common, a deterministic traceability gate
   (`traceability_errors`) that rejects a record whose `entry` claims a number with no matching `sources` value
   that itself appears verbatim in the sheet, and `convert_records` to merge a batch of records into the
   `{kind: [entry, ...]}` shape a class file expects.
3. **`score.py`**: compares a directory of records against an existing class file's hand-written entries, per
   kind and keyed by that kind's identity field(s), as match / miss / false_claim / wrong_value, then reports
   precision and recall — the validation protocol of `scale-out-sheets.md` part 3, run against Templar first since
   it is the one class with hand-written ground truth.

## Considered options

1. **Keep re-deriving each class's entries by hand, from raw DBC, as Templar's was derived.** Rejected: the
   Templar investigation already took days per the owner's own account; 20 more classes at that rate does not fit
   any reasonable schedule, and nothing about the next classes' tooltips is simpler than Templar's.
2. **Have a reader read raw DBC and Spell.dbc directly instead of a pre-digested sheet.** Rejected for the first
   pass: the point of the sheet is that the expensive part (resolving tokens, classifying effects, finding scripted
   hooks) is already code this package runs correctly and deterministically; asking every reader invocation to
   re-derive it from raw tables duplicates that cost without adding reliability, and makes two readers' answers
   harder to compare since they might resolve the same raw data two different ways.
3. **Skip the traceability gate and trust reader output directly.** Rejected: a reader given five similarly-worded
   tooltips can pattern-complete a `entry` shape without re-deriving it (Risk 2 of `scale-out-sheets.md`); a
   mechanical "every number must trace to something the sheet actually said" check is cheap and catches the
   specific failure mode of a fabricated DBC-looking citation (Risk 3 of the same document).

## Consequences

- The sheet generator, the record validator and the scorer are all read/format/compare code with no new judgement
  logic of their own; a wrong candidate entry is still caught by the existing `generate`/`compare` loop
  (`compare.py`'s per-kind judges), which a generated record enters exactly like a hand-written one.
- `REQUIRED_ENTRY_FIELDS` is the common field set observed on Templar's own entries, not a transcription of
  `README.md`'s per-`behaviour_kind` prose tables (`behaviours` in particular has many sub-kinds with different
  optional fields: `expected`, `expected_ms`, `levels`, `expected_ratio`, …). The validator only enforces the
  fields every kind's entries share (`kind`, `name`, `quote`, `spell` for `behaviours`); a sub-kind's own extra
  required fields are not separately enforced here. This is read directly from `classes/templar.json`, not
  invented, but it is a known gap for a future pass once a second class's entries exist to confirm the common set
  still holds.
- The scorer's "false_claim" bucket is any generated key absent from the ground truth, regardless of whether the
  hand investigation found the effect genuinely unmodelled/closed or simply never looked at that spell for that
  kind; it does not yet distinguish those two cases (`scale-out-sheets.md` part 3 step 2's three-way split). A
  closer match to that document would also inspect `unmodelled_effects`/`effect_notes` entries for the same
  spell/effect before calling a generated entry a false claim.
- `sheets.py`'s scripted-hook scan shells out to `grep` per spell; this is fast enough for a few hundred spells per
  class but was not measured at the full 21-class scale.
- A `KEY_FIELDS` key is not guaranteed unique even on Templar's own file (two `aura=560835` procs, two
  `aura=803163` procs, a duplicate `aura=804927` trigger, a duplicate `spell=300504` behaviour all exist today).
  `score.py` groups both ground-truth and generated entries into a list per key and claims within that list by
  field match rather than overwriting one entry with another, so no entry is silently dropped before scoring; a
  future class whose entries legitimately share a key is covered the same way.
- `score.py`'s numeric match tolerance reuses `compare.py`'s own `ABSOLUTE_TOLERANCE`/`RELATIVE_TOLERANCE` floor
  (`max(1, 0.5% of expected)`) instead of an independent constant, so "close enough" means the same thing in a
  score run as it means in `alerts.tsv`, matching `scale-out-sheets.md` part 3 step 2's explicit instruction.
