# 1241. The aura-fed instant casting read carries its aura-fed contrast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor D-295 (lr1 tool note TN-1), design approved by the controller on 2026-11-23
- Related: ADR 1195 (aura_fed_effect), ADR 1221 (window variant and its evidence rows)

## Context

Spears of Glory 804629: "Your next Dawnsear within $d is instant cast". The `aura_fed_effect` instant variant
(`fed_instant`) already judges both arms at the same read: Dawnsear 554406 is still casting (1) 300 ms after the
cast in the control arm (807299 cancelled) and is not casting (0) in the fed arm (807299 earned from Radiant Flame).
Its verdict carried the plain `casting` metric, a state metric, and no contrast, so `coverage.promised_state`
returned False and the claim "Your next Dawnsear is instant cast" stayed data. An `evidence_metric` of `casting`
would change nothing (`compare.observed` already reports it); `spell_go_count` is read after the full cast time, so
it does not show "instant".

## Considered options

1. `evidence_metric: "casting"` as named in the note: a no-op for coverage.
2. `evidence_metric: "spell_go_count"` (lr1 note): names a read that cannot tell an instant cast from a 3.5 s one.
3. A kind-specific evidence metric with its contrast, as ADR 1221 did for the window variant. Chosen.

## Decision

- Opt-in `evidence_metric: "aura_fed_instant_casting"`, accepted only on the instant variant (`cast_failure` stays
  the cooldown variant's only option). The model then carries `evidence_metric` and `contrast: "aura_fed"`.
- The kind's closed evidence rows: `METRIC_EVIDENCE` state, `CONTRAST_PROOF` `aura_fed`, `STATE_PROMISES`
  `instant`. An ok verdict is behaviour on a clause that says "instant" and data otherwise.
- Judging and ok are unchanged: the control arm must read casting 1 (else unmeasured), the fed arm casting 0 and
  both judged casts must go off.

## Consequences

- Only the opted entry changes (Sun Cleric `fed_instant`: its model gains two keys). Finished classes 15, 19,
  19 --stack and 23 regenerate byte-identical and their archived audits are unchanged (lr3 report).
- Tests (`kinds/test_aura_fed_effect.py`): the opted verdict is behaviour on the instant clause and data on
  "within $d"; without the stamp or without the option it is data; mutants: the control arm's read missing or not
  casting is unmeasured, hence unproven, and a fed arm still casting alerts; the option is refused off the instant
  variant.
