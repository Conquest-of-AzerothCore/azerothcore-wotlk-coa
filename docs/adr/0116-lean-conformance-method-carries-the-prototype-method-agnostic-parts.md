# 0116. The lean conformance method carries the clause-spec prototype's method-agnostic parts

- Status: accepted
- Date: 2026-11-11

## Context

From 2026-11-10 the clause-spec prototype (branch `proto/clause-spec`, 27 commits on `b73cb464a5` and a merge of the
round 10 end `801527e9aa`) tested a second way to write conformance checks on the Templar: one data entry per
ledger clause in a closed operator set, a fixture library and a template drafter. Its score (G6) failed the cost
rule set before the runs: a clause check cost about 1.25 times an entry of the current method, against a bar of
0.4. Its build also produced tool parts that do not depend on the clause format: a deterministic runner for the
gameplay passes, two proof statuses, a build and a `Spell.dbc` stamp on every verdict, a `not_measured` status for
reads a CalcAmount hook overrides, and game-time stamps on recorded combat events.

On 2026-11-11 the owner ruled: the lean current method plus those carried-over parts; clause specs are not adopted
and the drafter stays in history only. The tool defects the review found (I3, I2, I8 with I6, I5) are fixed after
the port, before the next coverage figure.

## Considered options

1. Merge `proto/clause-spec` and leave the clause modules unused. Rejected: 8,658 lines of clause operators,
   fixtures, drafter and value dump with their tests and `docs/clause-checks.md` (3,955 of them module code) would
   stay in the conformance package for a format that is not used.
2. Cherry-pick the prototype commits that hold the parts. Rejected as the main route: the parts are spread over
   commits that also change clause modules, and the cherry-picks conflict with the feat branch's later commits (the
   event-time commit alone conflicts in four files).
3. Re-apply the method-agnostic parts on `feat/coa-class-conformance` from the prototype's final file state, one
   commit per part, and leave the rest in the prototype's history. Chosen.

## Decision

Carried over, each in its own commit with its own ADR: the server `Spell.dbc` guard (ADR 0117), `not_measured`
CalcAmount reads and per-verdict builds (ADR 0118), game-time stamps on recorded combat events (ADR 0119), the two
proof statuses in `coverage.py` (ADR 0120) and the prove runner with its flip rule and pilot hook (ADR 0121).

Left in the prototype's history: the clause operators, fixtures and format additions, the template drafter, the
value dump, the `templar_checks/` clause files and the translation arms, the consumption rows (K1/K2/K3, no writer
without the uncommitted server mutant), the `@s:` sentence lister, the C arm's three behaviour kinds and options
with its Templar entries, and the decrease form, which the current kinds do not need (they take a hand-written
expected value, and `passive_delta` reads signed DBC points).

## Consequences

- The class files are unchanged; the port changes generated scenarios only by the manifest's `Spell.dbc` sha and the
  CalcAmount hook reads beside each `spell_effect_value` read.
- The proof gate of the clause operators (power, negative arm, positive control) is not code the current judges can
  reuse; porting it into `hit_mean`-type judges, the count judge and `passive_delta` is new work (I8 with I6).
- The prove runner has no pilot provider: the prototype's only provider sized MAGNITUDE clause entries.
