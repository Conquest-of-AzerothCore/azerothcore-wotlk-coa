# 0192. The tooltip reader prefers the streamed client text

- Status: accepted
- Date: 2026-11-12
- Supersedes: the last consequence of ADR 0105 ("The conformance tool still reads the server `Spell.dbc` texts, not
  the streamed rows; the clause ledger's entries for these spells are unchanged") and the "Known divergence" note of
  `apps/coa-gameplay-test/conformance/docs/tooltip-reading.md`.

## Context

The server streams a spell's `Description`, and its `ToolTip` when that is non-empty, from
`coa_client_spell_description` in place of the client DBC's (`AscensionCompat.cpp`, `BuildSpellPatchRows`): an
empty `Description` blanks the text, an empty or NULL `ToolTip` keeps the client's. The player therefore reads the
streamed text. The mentor ruled on 2026-11-11 that a spell with a streamed description is judged against that text,
that the ledger names the text used and keeps the DBC text beside it, and that a claim resting on an override whose
only justification is "align the text with the server" has no independent expectation.

Rows are written only by `data/sql/updates/*/` SQL; 4,433 rows are live after 56 files, 22 of them on Templar
spells (`lean/streamed-texts-reading.md`).

## Considered options

1. Query the world database. Rejected: the tool is standard library only and runs without a server.
2. Copy the 22 Templar texts into the class file. Rejected: a second copy to keep in step with the SQL.
3. Replay the table's `DELETE` and `INSERT` statements from `data/sql/updates/db_world` and `pending_db_world` in
   file order, and overlay them in `Records.field`. Chosen.

## Decision

- `streamed.py` replays the rows (quoted strings with MySQL escapes, doubled quotes, `CONCAT`, `NULL`).
- `Records.field('Spell', id, 'Description[enUS]' | 'ToolTip[enUS]')` returns the streamed value under the server's
  rule; `Records.dbc_field` returns the DBC value. Every reader of those fields goes through `Records.field`.
- The clause ledger: each claim of a spell with a streamed row carries `text_source` (row, file, commit, PR,
  basis, ruling, what differs); a clause the streamed text changes keeps the DBC words in `dbc_clause`.

### Provenance of the 22 Templar overrides

- `rev_20261110_02_templar_client_texts.sql`, commit 615f478756 (local branch, no PR yet). Basis: the owner
  rulings of 2026-11-10 (ADR 0104, ADR 0105).
  - 500694 Force of Golganneth (class spell): ToolTip.
  - 805409 Righteous Tempest (class spell) and its ranks 807269-807274: ToolTip.
  - 805410 and 570200-570205, the tick and its ranks: Description, $SP*.15 to $SP*0.3.
  - 801832 Scourgebane's strike (triggered): Description, $AP*0.15 to $AP*0.25, no "over $d".
  - 803160 Chakra of Light's heal (triggered): Description, the rank's base plus 35% SP.
- `rev_20261029_240_templar_untainted_tooltip.sql`, commit 53feaa3c63, PR #10006 (issue #9895). The file aligned the
  text with the server; its basis is now the owner ruling of 2026-11-11 (Untainted: 10 plus 10% of Stamina).
  - 705298 Untainted (class spell): Description, ${$705299m1+$STA*0.1} to ${-$705299m1+$STA*0.1}.
  - 705299 Untainted's buff (triggered): ToolTip.
- `rev_20261024_46_templar_disciplined_blows_tooltip.sql`, commit a5fe7aaa16, PR #8988. Basis: a text correction,
  no value changed.
  - 680397 Disciplined Blows (class spell): Description, "Cnly occur" spelled "Only occurs", line breaks.
- `rev_20261021_21_templar_divine_strikes_debuff_tooltip.sql`, commit 53ed4176d5, PR #8438 (issue #8362). Basis:
  aligned with the server, after a player issue showed 0%.
  - 803372 Divine Strikes' debuff (triggered): Description restated, ToolTip $w1 to $w2.
- `rev_20261021_13_coa_mount_text_trim.sql`, commit 3a5fdddbfa, PR #8381 (issue #8281). Basis: aligned with the
  mount-wide text shape.
  - 527272 Divine Charge's trample (foreign): Description trimmed, ToolTip.

No override rests on a live source.

## Consequences

- Re-extracting the 37 claims of the affected spells (16 on 500694, 680397, 705298 and 805409; 21 on spells whose
  tokens name 801832, 803160, 803372 or 527272) changes two clause texts: 147, Disciplined Blows, "Only occurs once
  every 0.5 sec." (DBC "Cnly occur ..."), and 215, Untainted, "by ${-$705299m1+$STA*0.1}" (DBC
  "by ${$705299m1+$STA*0.1}"). The 21 indirect claims read their own DBC description; a streamed description of a
  spell they name changes no token value. The no_claim tick entry 805410 now reads $SP*0.3 and stays no_claim.
- No scenario file changes: the 1,418 and 40 stack scenarios regenerate byte-identical. Manifest expectations
  change for value-705298 (its displayed token), value-805410 and value-570200 to 570205 ($SP*0.3) and the two
  Disciplined Blows cooldown quotes. Re-judged on one counted pair, every verdict keeps its status and value (the
  fixture has no spell power, so $SP*.15 and $SP*0.3 read alike).
- No Templar claim is judged against an align-to-server text that differs from the DBC: the claims judged against
  streamed text rest on owner rulings (500694, 705298, 805409) or on a spelling fix whose stated 0.5 sec is in the
  DBC text too (680397). The overrides with no ruling (803372, 527272) describe spells with no ledger clause of their
  own.
- The class file's Disciplined Blows and Untainted quotes and tooltips follow the streamed wording.
- A change to the SQL rows changes what the tool reads; the source stage's conformance suite does not select on
  `data/sql` paths, so such a change is caught by the next generation, not by the suite.
- Tests: `test_tooltip.StreamedTextTests`, `ClientDbcTooltipTest.test_foreign_level_scaled_spell_reads_its_own_rank`.
