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
duration - 1 s and gone by duration + 1 s for the duration. Review I-1 of the first version showed that reads
anchored to the quieting relocation prove only D in (9000, 11600] ms for a 10 s aura, because the last dodge falls an
unknown 0 to 600 ms before the relocation, so a duration 10% longer passed. Mentor ruling D-102 (2026-11-24)
approved anchoring the reads to a recorded game time of the last dodge, the void conditions below and a harness
recording of that time.

Options considered: an entry field `contrast` (refused: an entry would set an evidence stamp by hand); stamping every
`stat_delta` model (moves existing scenarios and has no not-learned zero-delta arm); an opt-in baseline read from which
the stamp is derived (chosen). For the duration: reading the remaining duration at the relocation (still a readback);
anchoring the expiry reads to the quieting relocation with dodge counts that bound the last dodge (first version,
refused by review I-1: it cannot exclude +10%); fixed reads closer to the duration with the relocation anchor
(narrows the band but still depends on the unknown position of the dodge in its window); a recorded game time of the
last dodge with game time reads around each aura read (chosen).

## Decision

- Opt-in `baseline_read: true` on a `stat_delta` entry adds the ally's stat read after the engage and before the
  control windows. The judge alerts when the control read (after the dodges, the passive not learned) differs from it
  by more than the existing 0.01 tolerance. `learned_contrast` sets the model's `contrast: learned` only when the
  generated step list holds, in order, the baseline read, dodge windows, the control read, the single learn of the
  passive, dodge windows and the treatment read.
- New read `expiry_edge`, metric `aura` (already an event metric in `coverage.METRIC_EVIDENCE`): dodged-swing counts
  before the last treatment window, after the quieting relocation and at the end. The harness records, per player
  actor and victim state, the game time at which it receives each melee combat packet whose victim it is; the new
  read metric `melee_attack_taken_last_ms` (`victim_state` optional, missing before the first packet) returns it
  (recording and reading only; `coverage.METRIC_EVIDENCE` row `event`). After the relocation the kind reads the last
  dodge's stamp t, then `game_time_ms` before and after each of the ally's two aura reads, placed about 0.9 D and
  D after t (waits 8950 ms and 1000 ms for D = 10000 ms and 500 ms windows). With h = game time before the held read
  - t and g = game time after the gone read - t: void unless 0.9 D <= h, h + 100 < D <= g' (game time before the gone
  read - t) and g + 100 < 1.1 D; `ok` when the aura is held and then gone. A dodge packet is stamped no earlier than
  the server's dodge, at most the lag allowance later, so held proves D > h and gone proves D <= g + 100: `ok`
  places D in (h, g + 100] ms, inside (0.9 D, 1.1 D), and the verdict records h and g + 100 as its low and high.
  Also void when the last window holds no dodge or a dodge follows the relocation. Generation refuses
  `swing_ms + 200 >= 0.1 D`.
- No change to `coverage` tables, judges of other kinds, tolerances or closing keys.

## Consequences

- Entries without `baseline_read` or `expiry_edge` generate byte-identical scenarios; no finished class uses the
  kind, and classes 15, 19, 19 --stack, 23 and 27 regenerate byte-identical.
- Tests in `kinds/test_avoided_swing_reads.py`: the stamp derived from the step list and absent from a step list that
  learns before the control read or holds no dodges; the stamped ok verdict counts as behaviour and the unstamped one
  as data; control-arm drift, a shorter duration (not held) and a longer one (not gone) alert; no dodge in the last
  window and a dodge after the relocation are void.
- For a 10 s aura every non-void `ok` places the duration strictly between 9 s and 11 s of the last dodge, so a
  duration 10% shorter (9 s, not held) or 10% longer (11 s, still held at the gone read) fails in every run; seeded
  tests simulate 200 runs per duration with the dodge 0 to 600 ms before the relocation and a 0 to 100 ms packet lag.
- Lag basis: the kind reads the ally's remaining duration right after the stamp read; the stamp read's game time
  less (D - remaining) is the server's last application of the aura. In both runs of the counted pair on Betrayer
  300476 (2026-11-24) the dodge stamp was 3 ms after that application (+3 ms; where the 3 ms come from is not
  established). The 100 ms allowance is not a measured figure: it is one server update tick, the step the kind
  already allows for a window's read, chosen as a bound above the measured +3 ms. The estimate is printed in each
  verdict's explanation so a later run that exceeds it is visible (review fw-rbab2 I-1; mentor D-102 asked for a
  measured basis, so the choice is reported to the mentor).
- Felsworn Betrayer 300476 `party_crit` opts in to `baseline_read`; `party_crit_duration` moves from `duration_max`
  to `expiry_edge` with the same label.
