# 0025. Player observations are a generic, class-agnostic citation array, never an expected value

- Status: accepted
- Date: 2026-11-08

## Context

`player-answers-2026-11-07.md` collects reports of how several Templar spells behave on the CoA production
server (this fork's own code, possibly a different commit; Ascension's own live realm is closed). The task's
hard rules are explicit: a player's report of *behaviour* describes our own production server, so it may
corroborate or contradict what the test server measures, but it never sets an expected value, never settles
intended behaviour and never picks a tooltip reading. `round3/player-behaviours-spec.md` asked for "a generic
class-file mechanism for cited player observations": generic harness code reads and prints an array next to a
verdict without knowing anything about Templar spells, keeping the "tool code is class-agnostic" rule intact.

## Considered options

1. Fold the citation into each `procs`/`triggers`/`passives` entry's own fields (e.g. an extra `player_note` key
   next to `trial_readings`). Rejected: ties the mechanism to each entry kind's own schema (`procs.py`,
   `triggers.py`, `passives.py` each have their own entry shape), so a citation about a `passive_delta` verdict
   (520608 effect `e1`) would need a different field than one about a `proc_rate` verdict (706325), and the
   report code would need to know every entry kind to print them together.
2. A separate, flat `player_observations` array on the class file, keyed by the verdict `label` it corroborates
   rather than by entry kind. Chosen: one shape for every kind of verdict (`proc_rate`, `passive_delta`,
   `trigger_count`, ...), read by one small generic module (`observations.py`) and printed by one function in
   `compare.py` (`observation_lines`) that takes the class file and the run's verdicts and needs no per-kind
   knowledge. A label absent from the current run's verdicts (a scenario not yet written, or renamed) shows
   `label not in this run` instead of silently matching nothing or crashing, so a stale citation stays visible.

## Decision

Add `player_observations: [{spell, name, date, citation, claim, corroborates}]` to the class file schema.
`citation` must read `"player report <date>"` (never a player or character name) and `date` must match it;
`observations.py`'s `checked_observation` raises otherwise, so a malformed entry fails loudly rather than being
silently dropped. `corroborates` names a verdict `label`, not a spell id, since one spell can carry several
verdicts. `compare.py`'s `report.md` gets a "Player observations" section, generic over any class file.

## Consequences

- A player report becomes a durable citation next to the verdict it bears on, visible in every future run of
  `report.md`, without changing what that verdict's own `status` means or how it is computed: the hard rule
  that a player report never sets an expected value is enforced structurally (the mechanism only ever reads and
  prints; it never feeds into `compare.py`'s judging functions).
- Adding a new kind of verdict in the future (a new `check` string) needs no change to this mechanism: any
  label the class file's `player_observations` names is looked up the same way.
- A citation whose `corroborates` label does not yet exist (the scenario is from a different, not-yet-landed
  item, such as a new negative trigger check) is reported as `label not in this run` rather than hidden; the
  implementer of that other item adds the scenario and the existing citation then starts showing its real
  status without any change to `player_observations` itself.
