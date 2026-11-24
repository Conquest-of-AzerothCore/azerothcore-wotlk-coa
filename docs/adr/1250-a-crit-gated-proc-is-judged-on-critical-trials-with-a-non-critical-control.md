# 1250. A crit-gated proc is judged on critical trials with a non-critical control

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-18 (Felsworn 14, Malice of Gul'dan 800214 "Direct critical strikes now have a $h% chance",
  Cursed Flames 300478), controller go 2026-11-23

## Context

A proc that rolls only on a critical hit (AscensionFelswornEvents.cpp:97-98, `crit && !periodic && Chance`) is
judged by the `procs` kind as procs per landed hit. With natural crits the rate is the chance times the crit share, so
the tooltip chance cannot be read; with every hit forced critical the rate is right, but a handler that ignores the
crit condition passes as well.

## Options

- Forced crits alone: proves the chance among crits, not the condition.
- Per-attempt reads of crit and proc counts with natural crits: exact attribution, but a new per-trigger reading for
  cast triggers and many more attempts at a low crit share.
- Forced crits for the trials plus a control arm in which no hit can crit: the harness already filters landed-hit
  counts by `critical` (CoAGameplayTest.cpp:5306), and `set_aura` changes an effect amount.

## Decision

The opt-in `procs` key `critical_trials` (`{rating, source}`, `cast` triggers only) counts the trials as critical
landed hits (`critical: true` on the trial reads), forces crits with the rating fixture, and adds a control arm to
part 1 after the passive is learned and before the measured attempts: each control cast runs under Wilting Touch 34640
with its crit chance effects 0 and 1 set to -100000, `ceil(log 0.0005 / log(1 - chance))` casts, then reads the
events, the critical hits and the non-critical hits. The verdict alerts on any control event, and is `unmeasured` when
the control holds a critical hit, too few non-critical hits or a missing read. The rate judgement is unchanged.

## Consequences

- Tests: `CriticalTrialsScenarioTest` and `CriticalControlVerdictTest` (test_procs.py); the seeded mutant is a
  crit-blind handler, seen as a control event, which alerts.
- Shared core files touched: `procs.py` (the trial reads and the control arm hook) and `compare.py` (the verdict
  hook); the rest lives in `proc_critical.py`. Entries without the key generate unchanged scenarios, so the
  finished-class digests do not move.
- The control relies on the suppression read, not on the clamp: a control critical hit voids it.
- Documented in `apps/coa-gameplay-test/conformance/docs/proc-rates.md`.
