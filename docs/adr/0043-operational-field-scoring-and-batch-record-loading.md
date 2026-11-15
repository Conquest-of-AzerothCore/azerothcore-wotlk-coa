# 0043. Operational-field scoring, batch record loading and the talent catalog scan

- Status: accepted
- Date: 2026-11-09
- Follows: 0042 (does not supersede it; narrows several of its explicitly stated gaps after the first validation
  round measured them)

## Context

The first Templar validation round of ADR 0042's pipeline (`.agents/plans/class-conformance-3/scale-out/
reader-score.md`) scored 29.0%/15.4% merged precision/recall, far below any usable bar, and traced most of the
gap to the scoring tool itself rather than reader quality: `records.load_records` could not read the round's own
batch files at all without a hand-written flattener; `records.traceability_errors` crashed on a list-valued
source; `score.py`'s literal field-for-field match matched 1 of 274 candidate keys because every entry kind
carries at least one free-text field two independent authors phrase differently; `unmodelled_effects` and
`effect_notes` share identical required fields and were used interchangeably for the same finding; and
`talent_modifiers` had zero records from either reader despite its five ground-truth spells being in the read
set, because nothing told a reader a spell was a talent rank rather than an ordinary ability.

## Decision

1. **One record shape, three accepted batch encodings.** `records.py`'s canonical record is unchanged (ADR
   0042); `extract_batch_records`/`extract_batch_residuals` turn a dict-wrapped batch, a bare list mixing record
   and residual dicts, or a residual wrapped as `{"entry_kind": "residual", "residual": {...}}` into that shape,
   and `load_records`/`load_residuals` apply this to every file in a directory, so `score.py` runs on a round's
   own `records/<class>/<side>/` directory unmodified.
2. **`traceability_errors` tokenises a source's value** (`records.value_tokens`) instead of hashing it directly,
   so a list-valued citation (a multi-target claim) no longer crashes; every element is still required to appear
   verbatim in the sheet, so the gate keeps failing a genuinely absent number.
3. **`unmodelled_effects` scores as `effect_notes`.** `score.KIND_MERGES` pools both kinds' ground-truth and
   generated entries under one row; `unmodelled_effects` is not a separate line in `score()`'s output.
   `classes/templar.json` is not changed; this is a scoring-time merge only.
4. **Operational-field matching by default, `--strict` for the original rule.** `score.OPERATIONAL_FIELDS` lists
   each kind's measurable fields (`aura`+`observe_spell` for `triggers`, `spell`+`effect`+`targets` for
   `passive_targets`, `spell`+`kind`+`values`-family fields for `behaviours`, per `reader-score.md` §1's own
   worked examples; the remaining kinds are this decision's own choice, not lifted from that document).
   `entries_match` restricts comparison to a kind's operational fields (still with `compare.py`'s tolerance) by
   default; `--strict` keeps ADR 0042's literal full-field equality. `--records-b` (`score.merge_sides`) scores
   only the records both sides agree on at the chosen strictness, replacing the hand-written merge script the
   first round's scorer wrote outside the repo.
5. **`sheets.talent_catalog_entry`** scans `CharacterAdvancement.dbc` (CoA's own talent catalog; the stock
   `Talent` table covers only 1 of Templar's 5 hand-written `talent_modifiers` ids) for every `RankSpell[0..4]`
   and attaches the owning entry, rank index and sibling ranks to a sheet when the spell is one. This is
   class-agnostic (reads the DBC table generically; no class or spell id is hardcoded) and resolves the key-space
   gap `reader-score.md` §5 item 6 raised: a reader can now tell a talent rank apart from an ordinary ability
   from the sheet alone.
6. **`record_schema()` carries a `guidance` block**: a number a reader cannot bind to an effect index belongs in
   a residual, never a `literal_tokens` hedge, and `unmodelled_effects`/`effect_notes` are one claim — written
   once in the one schema artifact this pipeline persists, since no separate reader-prompt file survived the
   first round.

## Considered options

1. **Keep the literal field-for-field match as the only mode.** Rejected: measured at 1/274 keys on real data;
   it answers "did two authors use identical prose", not "did they find the same fact".
2. **A whitelist of required schema fields, instead of a hand-picked `OPERATIONAL_FIELDS` table, as the
   operational scope.** Tried first; rejected after measuring it against Templar's real `classes/templar.json`:
   the ground truth carries fields not in the kind's own `REQUIRED_ENTRY_FIELDS` (`trigger`, `trial_metric`,
   `question`, `status`, …, investigation detail beyond the schema's minimum) and some real field names differ
   from the schema's documented name (`proc_spell` used throughout the data, `spell_proc` the schema lists), so a
   schema-derived whitelist silently dropped fields that matter (`observe_spell`) or never found fields that do
   appear on both sides. A direct, reviewable per-kind list, grounded in `reader-score.md` §1 where that document
   already proposed one, measured correctly on first try.
3. **Fix the reader protocol first, re-run readers, then re-score.** Rejected for this task: the task is scoped
   to the existing round's records and the tooling, not a reader re-run; `reader-rescore.md` states explicitly
   which remaining gaps (the citation-value convention, the residual-vs-`literal_tokens` instruction) only a
   reader re-run could move.

## Consequences

- Re-scoring the same Templar round's records with these fixes moved merged operational precision/recall from
  29.0%/15.4% to 34.3%/19.7%, and the `triggers` kind reproduces `reader-score.md`'s own hand-computed numbers
  exactly (85.7%/25.5%), corroborating both the manual process and this code. Most other kinds
  (`behaviours`, `procs`, `effect_overrides`, `literal_tokens`, `talent_modifiers`) are effectively unchanged:
  their gap is real reader miss/false-claim, not a scoring artifact these fixes touch. See
  `.agents/plans/class-conformance-3/scale-out/reader-rescore.md`.
- `OPERATIONAL_FIELDS` is a second source of truth about each kind's "real" fields, alongside
  `REQUIRED_ENTRY_FIELDS`; the two can drift (as the `proc_spell`/`spell_proc` naming already has). A future class
  should re-check `OPERATIONAL_FIELDS` against its own entries' actual field names, the same way ADR 0042 flagged
  `REQUIRED_ENTRY_FIELDS` as read from Templar's file and not yet confirmed against a second class.
- `score.merge_sides`'s conflict/one-sided counts are diagnostic, not a promotion of either side's claim; a
  conflict still needs a human (or a third reading) to resolve, same as the first round's residual list.
- The talent catalog scan adds one more `table_rows` pass over `CharacterAdvancement.dbc` per sheet batch,
  cached per `DataSet` instance (`lru_cache` on `talent_catalog_ranks`); not measured at full 21-class scale, the
  same caveat ADR 0042 already noted for the scripted-hook `grep` scan.
