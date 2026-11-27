# 0041. Bloodmage client text overrides, candidate MPQ tooling, and ledger alignment

- Status: accepted (owner rulings Bloodmage O-10, 2026-11-26)
- Date: 2026-11-26

## Context

Completing the Bloodmage (class 20) conformance wave requires updating `53` player-facing
`coa_client_spell_description` rows across ten `O-10` owner rulings (`Q-bm-1, 2, 3, 4, 6, 11, 12, 13, 23, 24`)
while leaving `Q-bm-7` (`803581..803585` Vampyr Bite, `'leave'`) unchanged, packaging a non-destructive
candidate `patch-ZG.MPQ` without touching the user's installed client archive, verifying opcode `2346`
wire delivery, and aligning `classes/bloodmage.json` and `classes/bloodmage_clauses.json`.

Specifically for `Q-bm-23` and `Q-bm-24`:
- `801076` Transgression: fixes `$s1%` -> `$560073s2%` of Spirit (also inherited by `504728`).
- `524907` Hemoglobe: fixes Description `$/10;t3` -> `$/10;s3` and ToolTip `$/10;s2` -> `$/10;s3`.
- `804602` Crimson Feast: fixes `Every $/1000;T1 second` -> `Every $t1 seconds` (`5 sec`).
- `500125, 501607..501614, 572332` Bloodmoon Blast (10 ranks) and `800774, 802456..802461, 572907` Sanguine
  Rupture (8 ranks): replaces broken `$?s500107` / `$?s807489` conditionals with obtainable `$?s92112` / `$?s92113`.
- `573299, 573356, 573357` Animated Blood (3 ranks): replaces `$?s560259` and `570744s1` with `$?s561196` and `561196s1`.

## Options

- Write `data/sql/updates/pending_db_world/rev_20261127_04_bloodmage_client_texts.sql` with all `53` rows,
  mirror them into `apps/coa-spells/bloodmage_tooltips.py` to build a candidate MPQ in `/tmp/bm-mpq-stage/patch-ZG.MPQ`
  from the installed client's `Spell.dbc` (preserving Cultist `O-18` and earlier patches), verify wire streaming
  via `apps/coa-gameplay-test/scenarios/bloodmage-ruling-client-texts.json`, and align `classes/bloodmage.json`
  and `classes/bloodmage_clauses.json` (adding `572907 thirst_92112`, `578120 dodge_scaling_*`, swapping Reave
  `802883 <-> 805612`, updating Aortic Aegis to rank `572279`, promoting alert probes `504627`, `707624`,
  `801961`, tightening `800785`/`524865`, and recording `text_source` + `dbc_clause`). Chosen.
- Overwrite `/mnt/steam/Games/CoA/Data/patch-ZG.MPQ` in place or omit wire/ledger alignment. Rejected:
  in-place client mutation is unsafe and unaligned ledgers fail `coverage.require_text_sources`.

## Decision

Implement the `53`-row SQL override, non-destructive `bloodmage_tooltips.py` MPQ patcher, wire parity test
`bloodmage-ruling-client-texts.json`, and full `bloodmage.json` / `bloodmage_clauses.json` alignment.

## Consequences

- `AscensionCompat::BuildSpellPatchRows` streams all `53` updated texts at login while preserving `803585`.
- A ready-to-inspect candidate `/tmp/bm-mpq-stage/patch-ZG.MPQ` differs from the client baseline solely on
  fields `170` and `187` of those `53` Bloodmage spell rows.
- Every clause of a streamed spell in `classes/bloodmage_clauses.json` carries `text_source` (`basis: "owner_ruling"`)
  and preserves `dbc_clause` where changed.
