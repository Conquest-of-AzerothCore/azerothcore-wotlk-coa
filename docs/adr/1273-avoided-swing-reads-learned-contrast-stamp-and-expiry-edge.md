# 1273. Avoided swing reads: learned contrast stamp and expiry edge

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-24

## Context

`avoided_swing_reads` ([ADR 1259](1259-a-dodged-swing-effect-is-read-on-the-caster-or-a-grouped-ally.md)) judges
Betrayer 300476 on a grouped ally. Two of its verdicts count only as data in the audit:

- `stat_delta` reads `melee_crit_chance_refreshed`, a state metric. `coverage.promised_state` counts a state read of
  `behaviour_metric_delta` as behaviour only with a `learned` or `own_cast` contrast stamp, and the kind set none,
  although its arms are in substance a learned contrast.
- `duration_max` reads `aura_duration_ms`, a readback of the remaining duration, not an observed expiry.

Mentor ruling D-91 (2026-11-24) approved a learned stamp on conditions: the tool derives it from the arm structure and
no entry sets it; the arm learns the talent and the buff comes from a real avoided swing; a not-learned control arm
reads zero delta; a seeded test and a mutant; finished-class digests unmoved. It accepted an expiry edge held at
duration - 1 s and gone by duration + 1 s for the duration.

Options considered: an entry field `contrast` (refused: an entry would set an evidence stamp by hand); stamping every
`stat_delta` model (moves existing scenarios and has no not-learned zero-delta arm); an opt-in baseline read from which
the stamp is derived (chosen). For the duration: reading the remaining duration at the relocation (still a readback);
anchoring the expiry reads to the quieting relocation with dodge counts that bound the last dodge (chosen).

## Decision

- Opt-in `baseline_read: true` on a `stat_delta` entry adds the ally's stat read after the engage and before the
  control windows. The judge alerts when the control read (after the dodges, the passive not learned) differs from it
  by more than the existing 0.01 tolerance. `learned_contrast` sets the model's `contrast: learned` only when the
  generated step list holds, in order, the baseline read, dodge windows, the control read, the single learn of the
  passive, dodge windows and the treatment read.
- New read `expiry_edge`, metric `aura` (already an event metric in `coverage.METRIC_EVIDENCE`): dodged-swing counts
  before the last treatment window, after the quieting relocation and at the end; the ally's aura read at
  relocation + duration - 1000 ms (must hold) and + duration + 1000 ms (must be gone). Void when the last window holds
  no dodge or a dodge follows the relocation. `ok` places the duration within
  [duration - 1000 + swing_ms + 100, duration + 1000] ms of the last dodge.
- No change to `coverage` tables, judges of other kinds, tolerances or closing keys.

## Consequences

- Entries without `baseline_read` or `expiry_edge` generate byte-identical scenarios; no finished class uses the
  kind, and classes 15, 19, 19 --stack, 23 and 27 regenerate byte-identical.
- Tests in `kinds/test_avoided_swing_reads.py`: the stamp derived from the step list and absent from a step list that
  learns before the control read or holds no dodges; the stamped ok verdict counts as behaviour and the unstamped one
  as data; control-arm drift, a shorter duration (not held) and a longer one (not gone) alert; no dodge in the last
  window and a dodge after the relocation are void.
- The expiry edge accepts a duration from about 9.6 s to 11 s for a 10 s aura; a duration 10% longer can pass, one
  20% longer or 4% shorter cannot.
- Felsworn Betrayer 300476 `party_crit` opts in to `baseline_read`; `party_crit_duration` moves from `duration_max`
  to `expiry_edge` with the same label.
