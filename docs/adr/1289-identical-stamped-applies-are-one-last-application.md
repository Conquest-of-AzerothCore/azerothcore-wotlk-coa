# 1289. Identical stamped applies are one last application

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-24

## Context

Felsworn part 233.1, Legionfall 801899: "within $801902d". The `last_application_expiry` entry
`legionfall_duration` feeds Annihilan Strike 801903 until 801902 is on the caster and times the aura from the stamped
first apply. Its judge voids any run whose stamped apply count is not one (mentor D-21), because a refresh or a second
apply would leave the last application unstamped.

Annihilan Strike has two `SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE` effects (801913, 801914); each landed strike rolls the
15% chance, so a grant applies 801902 twice in about 8.1% of runs (0.15^2 / (1 - 0.85^2)). In the final pair fw-pair4,
run R2 read two applies at game ms 12 and 12, flips4 reruns 2 and 6 at 3412 and 3412, each removed 15001 ms after the
shared stamp, the same as the single-apply runs (`final/flips4/report.md`). The guard turned those runs into
unmeasured ones; no server defect.

Mentor ruling D-116 (2026-11-24) approved accepting two or more stamped applies only with the same aura, the same
target and an identical `at_ms`; any other multiple stays unmeasured. The first design read the largest stamp gap
(`timeline_interval_max_ms`) in the scenario, but that read is NaN with a single apply and a non-finite assert fails
the step and ends the scenario (`CoAGameplayTest.cpp`, `Require(passed)`), so every normal run would have failed. A
new harness read was refused (D-115: no harness C++ after the pair of record). D-117 approved reading the timeline the
run already records.

## Decision

- `compare.Run` gains an optional `timeline`, the `result.json` `timeline` list (`at_ms`, `event`, `spell`,
  `target`, ...), empty by default. No other judge reads it.
- `last_application_expiry` takes an opt-in `same_stamp_applies: true`, only with `feed`. Its model names the aura and
  the holder. When the stamped count is two or more, the judge accepts it only if the recorded timeline holds exactly
  that many `aura_applied` events of that aura on that holder, all with one `at_ms`; the age check then uses the
  shared first stamp as before. A differing count, different stamps or an empty timeline leave the arm `unmeasured`
  with the reason. One apply is judged as without the option. The judge names no class or spell.
- No scenario step changes (only the contract text of the opted-in entry); no evidence row changes.

## Consequences

- Legionfall runs whose grant applies 801902 twice at one game time are measured instead of void; a refresh at a
  later game time still voids the arm.
- Finished classes regenerate byte-identical: no other entry sets the option, and `Run.timeline` changes no verdict
  without it.
- The verdicts of this entry after the change come from focused reruns, not from the pair of record (D-116).
