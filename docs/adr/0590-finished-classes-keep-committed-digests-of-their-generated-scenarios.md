# 0590. Finished classes keep committed digests of their generated scenarios

- Status: accepted
- Date: 2026-11-13

## Context

A finished class (Templar, Necromancer) has a count of record: a counted pair of runs judged on the scenarios its
generator wrote. A later change to the shared tool (`behaviours.py`, `compare.py`, a kind module), to the DBC tools or
to a class file can change those scenarios without anyone noticing, and the count of record then no longer describes
what the tool generates. Until now the only guard was a manual regeneration identity check at integration
(`docs/coa/class-conformance.md` 9.7, 9.8). Generation needs the server DBC set, which every contributor has (G-42)
and GitHub CI does not. A full Templar generation is 2461 files (396 MB on disk), the Necromancer 3284 (214 MB).

The mentor's ruling on the contributor-structure plan (open decision 6, 2026-11-13): a committed digest list, one hash
per generated scenario per finished class, checked in the local source stage, mandatory before a PR; a mismatch names
the scenarios and tells the contributor to regenerate and diff locally; the guide says plainly that GitHub CI does not
run it. A later note: no single-build Templar verdict set exists that the coverage audit accepts, so an audit-rule
change cannot be re-audited on the Templar.

## Considered options

1. Commit the full generated scenarios. Rejected: about 610 MB for two classes, and every regeneration rewrites
   thousands of files.
2. Commit one SHA-256 per generated file and regenerate in the check. Chosen (mentor ruling).
3. Keep the manual identity check only. Rejected: it runs only at integration, and only when someone remembers it.

## Decision

- `apps/coa-gameplay-test/conformance/snapshots/<class>.json` holds, per generation (`all` for `generate --class N`,
  and `stack` for the Templar's `--stack`), the SHA-256 of every file the generator writes, the manifest included.
  `snapshots.py` names the finished classes (`FINISHED_CLASSES`) and their generations; `snapshots.py write --class N`
  rewrites a digest file, `snapshots.py check --class N` regenerates into a temporary directory and compares.
- The `conformance` suite of `tools/check_source.py` runs `snapshots.py check` once per digest file found in
  `snapshots/`, and `test_snapshots.py` (seeded tests and a one-byte mutant on the real Templar stack generation). Any
  change that selects the suite (every file of the tool, `run.py`, the DBC tools, the three headers) runs the check.
- A mismatch lists the changed, added and removed files of each generation (20 per list) and prints the two
  `generate` commands to run at the base commit and on the tree, then `diff -r`; when every difference is intended,
  the contributor runs `snapshots.py write` and commits the digest file with the change, so the diff is review
  evidence.
- Without the DBC set the check prints `skipped` and passes. GitHub CI has no DBC set, so it never runs the check; the
  local source stage (`verify_all.py --stages source --base <ref>`) is mandatory before a PR.
- `snapshots/` is outside the scenario catalog (`catalog.py` reads `scenarios/` only); the digests never run.
- A finished class also keeps a re-auditable verdict set: the compare outputs of both runs of its final merged pair,
  with their build id, archived in the location its class ADR folder's README names. An audit-rule or coverage-rule
  change is re-audited on that archive (`conformance.py audit --results ... --build ...`).

## Consequences

- The digest files are 368 KB (Templar) and 500 KB (Necromancer). Each source-stage run that selects the
  `conformance` suite regenerates both classes: about 26 s, 2 s and 16 s on this workstation.
- A digest names a file, not a value: a mismatch says what changed, the local diff says how.
- The digests depend on the server DBC set (the manifest records its `Spell.dbc` SHA-256); a new DBC set changes them,
  and the generator refuses a set that is not the server's.
- A new finished class adds its name to `FINISHED_CLASSES` and `GENERATIONS`, and writes its digest file in the
  commit that records its count of record.
- The Templar has no archived single-build verdict set today; its re-audit waits for its next counted pair.
