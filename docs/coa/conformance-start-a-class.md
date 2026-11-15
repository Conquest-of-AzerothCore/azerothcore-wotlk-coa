# Start a class from files alone

The ordered checklist for a fresh session that takes the next class through conformance. The guide is
[class-conformance.md](class-conformance.md); section numbers below are its own. `CONF` is
`apps/coa-gameplay-test/conformance/`; `conformance.py --help` lists every command.

## Environment

`tools/verify_all.py` alone is enough: it runs the source stage, the build and the gameplay runs this checklist needs
(`docs/coa/verification.md`), and `git worktree remove` cleans up. `coa-verify`, its in-RAM MySQL route, `coa-slot`
and `coa-worktree-cleanup` are optional local helpers from the separate coa-server-guide project, outside this
repository (guide 9). Where a step names `coa-verify`, the matching `verify_all.py` selection does the same work; a
cycle file then keeps the default `gameplay_runner` and drops the in-RAM MySQL disk check. `conformance.py cost` reads
Claude Code transcripts (session `.jsonl` files and their subagent `agent-*.jsonl` files) and sorts agents into roles
by keywords of their description and first prompt, the rules of the Necromancer retrospective (ADR 0656). It expects
that layout; without such transcripts the checkpoint reads "not recorded".

## Steps

1. Get the owner's go for the class and for a worktree and branch of your own, created from freshly fetched
   `origin/main` (guide 9.0, `.agents/rules/git-safety.md`). Ask the developer whether a mentor session exists (guide
   12). The mentor is optional: the guide's rules and the standing rulings (guide 11.1) decide alone, and without a
   mentor a case they do not decide goes to the owner as a question (guide 9.0).
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
10. After each merged pair, record the cost first: `python3 -B conformance.py cost --transcripts DIR --since ISO --out
    cost.json` (ADR 0656), and name that file in the `cost` field of `cycle.json`; the cycle copies it into the
    checkpoint it writes (without transcripts, leave `cost` out: the checkpoint reads "not recorded").
11. Then run `python3 -B conformance.py cycle --config cycle.json` (guide 9.8, ADR 0655). Agents are needed only where
    it stops. Compact the controller's context and send the checkpoint to the mentor.
12. Before a PR: `python -B tools/verify_all.py --stages source --base origin/main`, the codestyle linters on changed
    C++ and SQL, class ADRs under `docs/adr/conformance/<class>/` (guide 14.4).

## What the owner decides

Server fixes outside the four criteria of guide section 7, text changes to client descriptions, engine-behaviour
rulings that no G-n covers, a G-39 harness C++ change, and the go to push or open a PR. Ask these as owner questions
(guide section 8); do not decide them alone.
