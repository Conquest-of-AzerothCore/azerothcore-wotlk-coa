# Start a class from files alone

The ordered checklist for a fresh session that takes the next class through conformance. The guide is
[class-conformance.md](class-conformance.md); section numbers below are its own. `CONF` is
`apps/coa-gameplay-test/conformance/`; `conformance.py --help` lists every command.

1. Get the owner's go for the class and for a worktree and branch of your own, created from freshly fetched
   `origin/main` (guide 9.0, `.agents/rules/git-safety.md`). Ask the developer whether a mentor session exists (guide
   12).
2. Read the guide: sections 1 to 3 (what counts as proof), 7 (what you may fix), 8 (owner questions), 9 (the workflow),
   11.1 (standing rulings) and 14 (ownership, ADR numbers, guards).
3. Read [conformance-dispatch-rules.md](conformance-dispatch-rules.md): every agent brief and the controller follow it
   (rule 00 on top of each brief; model and effort per task; the cadence).
4. Read [class-conformance-rulings.md](class-conformance-rulings.md) by grep for the G-n a task cites, never whole.
5. Scaffold the class file: `conformance.py scaffold --class N --out FILE --config WORLDSERVER_CONF --mysql MYSQL`
   (`CONF/docs/scaffolding.md`).
6. Class map and aura 354 check: guide 9.1 and 9.2 (`conformance.py aura354 --class-map OUT/class-map.json --class N`).
7. Write the first ledger: `conformance.py ledger` (guide 9.4, `CONF/docs/clause-ledger.md`); review its output before
   the first batch.
8. Generate, run, compare: `conformance.py generate --class N --out DIR`, then the runs through `tools/verify_all.py`
   or `coa-verify` selections only (guide 9.5).
9. Work in batches and cycles (guide 9.6): write each cycle's plan (claims taken, target count) first; fresh agents
   only; no clock.
10. After each merged pair, write `cycle.json` and run `python3 -B conformance.py cycle --config cycle.json` (guide
    9.8, ADR 0655). Agents are needed only where it stops.
11. At each checkpoint record the cost: `python3 -B conformance.py cost --transcripts DIR --since ISO --out cost.json`
    (ADR 0656; without transcripts the checkpoint reads "not recorded"). Compact the controller's context and send the
    checkpoint to the mentor.
12. Before a PR: `python -B tools/verify_all.py --stages source --base origin/main`, the codestyle linters on changed
    C++ and SQL, class ADRs under `docs/adr/conformance/<class>/` (guide 14.4).

## What the owner decides

Server fixes outside the four criteria of guide section 7, text changes to client descriptions, engine-behaviour
rulings that no G-n covers, a G-39 harness C++ change, and the go to push or open a PR. Ask these as owner questions
(guide section 8); do not decide them alone.
