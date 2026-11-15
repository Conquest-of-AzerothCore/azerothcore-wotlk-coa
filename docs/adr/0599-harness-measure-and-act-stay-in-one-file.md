# 0599. The harness Measure() and Act() stay in one file; class reads go to per-class helpers

- Status: accepted
- Date: 2026-11-13

## Context

`src/server/coa/CoAGameplayTest.cpp` holds `Measure()` (about 570 `metric ==` comparisons) and `Act()` (130
`action ==`), and `run.py` holds the matching `METRICS`, `METRIC_FIELDS` and `ACTIONS` tables. Every class that
adds a read edits the same functions, so parallel classes conflict there. One conflict is recorded so far, with
main. Files already split out of the harness exist (`CoAGameplayPlacement.cpp`, `CoAGameplayTimeline.cpp`,
`CoAGameplayIsolation.cpp`). The mentor ruled option B (open decision 8, 2026-11-13).

## Considered options

- A. Move metric and action families into registration files, with the `run.py` tables split the same way. Cost: a
  build and the full gameplay catalog rerun, since every catalog scenario goes through `Measure()`.
- B. Keep the files; a contributor puts new reads in a per-class helper in a new file, called from one branch line
  each. Chosen.

## Decision

Option B. G-39 already limits contributor harness additions to reads and recording; anything more needs a note
first. Option A comes back when a second class works in parallel with another and the conflicts at
`Measure()`/`Act()` exceed what B absorbs.

## Consequences

- Residual risk, named in the guide (section 14): two classes still edit the same branch lists and `run.py` tables;
  each conflict is resolved by hand at merge.
- No build or gameplay rerun now.
