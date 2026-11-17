# 0591. A shared engine change prints the gameplay rerun of every finished class

- Status: accepted
- Date: 2026-11-13

## Context

Generation reads the class files, the DBC set and three headers, not the engine sources, so the snapshot digests
(ADR 0590) cannot see a change to `Unit.cpp`, `Spell.cpp` or `StatSystem.cpp`, which can still move every finished
class's measurements. `.agents/rules/verification.md` already says a shared core file reruns the affected suite, but
no mechanism names that suite for conformance, and verify_all selects gameplay only by `--scenario`, `--spell`,
`--quest` or `--query`. The mentor ruled (open decision 7, 2026-11-13): the source stage detects a changed shared
engine file from a fixed list and prints the required gameplay selection for every finished class, and fails until a
report records it passed; or prints only, if failing is too heavy, saying which was built.

## Considered options

1. Rule only, in the guide. Rejected: easy to miss on a diff that touches many files.
2. Print the selection, never fail. Chosen.
3. Print and fail until a report records the selection as passed. Not built: a `verify_all.py` report records neither
   the scenario paths it ran nor the tree it ran on; a conformance run ends `INCOMPLETE` by design (its verdicts come
   from `compare`); and the pass criterion is `conformance.py diff` against the class's count of record, whose verdicts
   are not committed (ADR 0590 adds the archive). A gate would need all three first.

## Decision

- `tools/check_source.py` names the shared engine files in `ENGINE_FILES`: `Unit.cpp`, `Unit.h`, `StatSystem.cpp`,
  `Spell.cpp`, `Spell.h`, `SpellEffects.cpp`, `SpellInfo.cpp`, `SpellInfo.h`, `SpellInfoCorrections.cpp`,
  `SpellMgr.cpp`, `SpellMgr.h`, `SpellScript.cpp`, `SpellAuraEffects.cpp` and `SpellAuras.cpp`.
- When the diff touches one, its JSON result carries `conformance_reruns` (`enforced: false`): the engine files and,
  per finished class and generation (read from the digest files of ADR 0590), the four commands: `generate` into
  `.cache/conformance/rerun-<class>-<generation>`, `verify_all.py --stages build,gameplay --scenario` on those
  scenarios, `compare`, and `diff` against the count of record. The same text goes to stderr, so `source.log` shows
  it, and `verify_all.py` keeps the field in the source stage summary of `report.json`.
- The stage status does not change.

## Consequences

- The contributor sees the required rerun without reading the guide; whether it ran is checked at review, not by the
  tool.
- Engine files outside the list (for example `Player.cpp`) print nothing; the guide's rule still applies to them.
- Building option 3 later needs a verify_all report that records its scenarios and tree, and committed or archived
  count-of-record verdicts; it would supersede this ADR.
