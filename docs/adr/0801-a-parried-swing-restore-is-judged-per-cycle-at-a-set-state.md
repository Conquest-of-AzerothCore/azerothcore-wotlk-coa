# 0801. A parried swing restore is judged per cycle at a set state

- Status: proposed (amended by ADR 0820 and ADR 0850)
- Date: 2026-11-16

## Context

Dark Riposte 503659: "Parrying enemy attacks now restores $504475s1% of your missing health and Rage." ($504475s1 =
5). Its aura script (`AscensionWitchHunterEvents.cpp:158`, `:313-319`, default action prevented at `:224`) heals
through 574335 and energizes Rage under 503659 for a twentieth of the missing value; 504475 itself is never cast.
A parried spell carries no damage and does not trigger it (c14-tool2 H4, pilot 20261116-061937), so only a parried
melee auto attack can. The harness `attack` step is player-only, so a creature's swings are not timed by the
scenario, and the missing health and Rage cannot be read just before each swing.

## Options

- A `taken_outcome` option: the kind judges outcome shares between two aura arms; the restore needs per-swing
  amounts and event counts, a different judge in an owner file.
- A harness step that makes a creature swing once (G-39 note `g39-h4-50.md`): harness C++ beyond reading.
- A new kind module (mentor D-258): the taken_outcome attacker, cycles shorter than the attacker's swing so each
  cycle holds at most one swing, the state set and read at each cycle's start, and the gain judged per cycle.

## Decision

`kinds/parried_restore.py`, `kind: "parried_restore"`, check `behaviour_metric_delta`, two labels (`_health`,
`_rage`). In each treatment cycle the heal (energize) events must number its parried swings and total its parried
swings times `missing * s1 // 100` of the missing value read at its start; the control arm must have none. A
treatment cycle whose health (Rage) at its end is not its start plus its events took a foreign change and is left
out and counted; a missed swing is not judged. Two swings in a cycle, a moved maximum health, nothing missing, or
fewer than `min_parried` judged parried swings leave the verdict unmeasured. The metric `parried_restore_gain` is an
event read, a row of the module's own `METRIC_EVIDENCE`; `coverage.py` is not edited. No harness or shared tool file
changes.

## Consequences

- Exact integer amounts: a 4.5% or 5.5% restore fails every cycle that parried (600000 missing health: 27000 or
  33000 against 30000; 800 missing raw Rage: 36 or 44 against 40).
- 574335 cannot crit (DBC AttributesEx2 `SPELL_ATTR2_CANT_CRIT`, forced again at
  `AscensionWitchHunterCompletion.cpp:389`); its hit heal is set to its base points by
  `spell_ascension_witch_hunter_copy` (`AscensionWitchHunterCompletion.cpp:543-549`) after EffectHeal's done and taken
  modifiers (code reading), so no crit fixture is needed.
- The one-swing-per-cycle bound rests on creature 36's BaseAttackTime 2000 (creature_template) and no haste on the
  attacker; the judge checks it per cycle rather than assuming it.
- The first run (20261116-113712) read a missed swing and a foreign loss of about 18 health and 1 to 2 Rage every 6
  to 9 s with no swing (source not identified); hence the reconciliation, rather than an assumed clean cycle.
- Tests: `kinds/test_parried_restore.py` (scenario order, pass, 10%-off amounts, mutant with s1 off, control restore,
  a missed swing, a foreign change left out, unmeasured cases, coverage behaviour without a coverage edit, refusal
  without the kind row).
- Generation of other classes is untouched: the Templar and Necromancer digests are unchanged.
- Number provisional: shared ADRs are numbered at merge.
