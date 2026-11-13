# Player observations and readings

## Player observations

A class file's `player_observations` entry is `{"spell", "name", "date", "citation", "claim", "corroborates"}`: a
player's report of how a spell behaves on the CoA production server (this fork's own code, possibly a different
commit; never Ascension's own, closed live realm). `citation` is always `"player report <date>"`, with no
character or player name ([no raw log lines or names rule](../../../AGENTS.md)), and `date` must match it;
`checked_observation` (`observations.py`) raises otherwise. `claim` is the player's own observation in prose.
`corroborates` names the `label` of the verdict it bears on — a `report.md`/`verdicts.json` label such as
`"706325 proc_rate"` or `"520608 e1"`, not a spell id alone, since several labels can share a spell.

This mechanism is generic and class-agnostic: `compare.py`'s `observation_lines` reads the array from whatever
class file `report.md` is built from and prints each entry beside the *current* status of the verdict it names,
without knowing anything about Templar or any other class's spells. A player observation never sets an expected
value, never settles a verdict and never picks a tooltip reading on its own ([ADR
0025](../../../docs/adr/0025-player-observations-corroborate-never-settle-a-verdict.md)): it is prose evidence
that a verdict's `ambiguous_tooltip`/`unmodelled` status, or its chosen reading, holds (or does not hold) on the
production server, read beside the DBC-derived expectation the run already judges. When `corroborates` names a
label the current run does not carry — because the scenario that would measure it has not been written yet, or
its name changed — the row says so (`label not in this run`) instead of silently matching nothing, so a stale
citation is visible rather than hidden.

## Player tooltip readings

A class file's `player_tooltip_readings` entry is `{"spell", "token", "value", "ap", "sp", "citation", "note"?}`:
a tooltip *number* the client showed a player at a stated attack power and one or two candidate spell powers
(`sp` a list; empty when the formula has no spell-power term). It is a different mechanism from "Player
observations" above (behaviour, never a number): `citation` is validated the same way
(`tooltip_readings.checked_tooltip_reading`), but `spell`+`token` (not `corroborates`) is the key, matched against
the exact `$`-token text of a now-readable `${...}` expression ([ADR
0031](../../../docs/adr/0031-ppl-tokens-scale-by-actual-level-not-skill-rank.md)). It is read-only evidence from
production, never an expected value: the no-combat `effect_value`/`hit_mean` check already judges the token
against the DBC formula evaluated at the harness's own reference caster, unaffected by which spec or gear the
player's screenshot was taken under.

Two generic, class-agnostic uses, both read-only:

- `compare.py`'s `unreadable_question` looks up `(rank_id, entry_token)` in the class file's
  `player_tooltip_readings` before building a `tooltip_value`/`data_issue` question for a still-unreadable entry;
  a match stops that question from being asked again (the citation already answers it), without changing the
  verdict's `unreadable` status.
- `report.md`'s "Player tooltip readings" section (`tooltip_reading_lines`) re-evaluates the *same* token against
  the reading's own `ap`/`sp` (one value per `sp` candidate, re-reading `tooltips.read` with a synthetic
  level-60 `CasterStats` at that `ap`/`sp`) and reports the resulting band next to the run's measured value for
  that label: `ok` when the measured value falls in the band (± the existing flat tolerance), `alert` otherwise,
  `label not in this run` when the scenario that would measure it has not been generated. This is corroboration
  only: it never feeds `judge_expectation`, and a `band unreadable` row means the token could not be re-evaluated
  (not a verdict).

Templar's 7 entries (`classes/templar.json`) cite the 2026-11-07 player report for Force of Golganneth,
Norgannon's Wrath, Divine Charge, Eternal Blessing, Libram of Consecration, Silverhand Incantation and Armor of
Faith; each `note` states which candidate spell power the reading fits, or that it fits neither exactly. Argent
Blade/Scourgebane's `scalingbp` reading (report of 280 Holy) is deliberately **not** cited here: evaluated at
either candidate spell power it comes out 260-330 points higher than reported, so citing it would read as model
confirmation it is not; it stays an open conformance check instead (`questions-round3.md`).
