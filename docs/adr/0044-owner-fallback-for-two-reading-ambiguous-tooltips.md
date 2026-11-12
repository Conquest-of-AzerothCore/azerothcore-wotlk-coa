# 0044. Owner fallback for a two-reading ambiguous tooltip

- Status: accepted
- Date: 2026-11-09

## Context

`compare.py` has two sites that compute several candidate readings of a tooltip's claimed bonus and judge each
one against the measured value: `judge_talent_delta` (a talent stack's composition against known modifiers and
earlier talents, "Talent stack (lever map)") and `judge_readings` (a passive delta whose metric has a
`composition`, "Passive effects"). When the readings disagree — one matches the server's measurement, another
does not — both sites return `ambiguous_tooltip` unconditionally and hand the disagreement to a player question.

Round5-round7's owner rulings (`.agents/plans/class-conformance-3/round5/owner-rulings-2026-11-09.md`) settled
several of these by hand, case by case, after consulting the Ascension combat log history
(`~/Projects/coa-log-history`, private, never committed): "the server is conformant when it applies a reading
the tooltip allows" once the logs were checked and said nothing. Round 7 generalizes that ruling into the tool
itself, so the next ambiguous case does not need its own one-off fix once the logs have been consulted for it.

## Considered options

1. Keep resolving each `ambiguous_tooltip` case by hand in `classes/<name>.json`'s free-text `reason`/`question`
   fields, as round5-round7 did for Transcending Strikes, Scourge-Defense Training, Whirling Tempest, Blade
   Sermon and Light's Echo. Rejected for the generic case: every one of those was actually a real behavioural
   difference (the owner changed the server or the check), not a case of "the logs say nothing, either reading
   is fine" — the fallback this item adds has no live case to anchor a hand-written example on, but the rule
   itself is already decided and class-agnostic, so coding it once is strictly better than waiting for the next
   occurrence to improvise the same decision again.
2. Record the log query as free text inside the expectation's `rule` string (the same mechanism `AMBIGUOUS_TOOLTIP`
   already uses for a *static*, unmeasured ambiguity). Rejected: `judge_talent_delta`/`judge_readings` build their
   `model` dict from DBC-derived facts, not from a single author-edited JSON entry per label in every case
   (`judge_readings`'s `composition` models are derived from `passives.py`'s effect classification, not hand-authored
   per spell) — threading a new field through every such model's construction site is more invasive than reading
   one shared, label-keyed lookup.
3. A new top-level `log_queries` dict on the class file, keyed by the verdict's `label`, holding the query that was
   run and found nothing; one shared `owner_fallback(statuses, log_query)` function in `compare.py`, called from
   both sites right after they compute their `judged` readings and find them disagreeing. Chosen: one lookup key
   (the label, already unique and already used by `alerts.tsv`/`verdicts.json`), one decision function, no change
   to how either site builds its candidate readings.

## Decision

- `compare.py` gains `owner_fallback(statuses: set[str], log_query: str | None) -> str`: a single status passes
  through unchanged; several statuses without a recorded `log_query` stay `ambiguous_tooltip`; several statuses
  with a recorded `log_query` resolve to `ok` when one of the readings is `ok`, or to `alert` when none is (kept
  explicit even though today's binary `ok`/`alert` reading domain makes "several statuses, no `ok` among them"
  unreachable from two-reading sites — `len(statuses) == 1` already short-circuits that case before the fallback
  runs — so the branch is future-proofing for a check with three or more candidate readings, not dead code removed
  on review).
- `log_query_of(manifest, label)` reads `manifest['class_file'].get('log_queries', {}).get(label)`; an absent dict
  or an absent label both give `None`, the same as today's unconditional `ambiguous_tooltip`.
- `judge_talent_delta` calls `owner_fallback` instead of its own `len(statuses) > 1` check; when the fallback
  settles on `ok`, the explanation is led by `owner fallback: logs queried (<log_query>) say nothing; the server
  applies <reading> (<why>), a reading the tooltip permits;` and `expected`/`low`/`high` come from that reading,
  not `judged[0]`; the player `question` detail is attached only when the status is still `ambiguous_tooltip`.
- `judge_readings` calls `owner_fallback` the same way; on `ok` it reuses `interval_verdict` with the single
  matching reading (so the formatted interval and tolerance text stay identical to an unambiguous `ok`) and
  prepends the same fallback explanation; on `alert` it builds the `alert` verdict directly, listing every
  reading and its status, without a player question (the owner's ruling has already settled the case).
- `classes/templar.json` adds no `log_queries` entries: every currently-ambiguous verdict in that file (Light's
  Echo, Serendipity, Paladin Training) is either settled in prose by a specific owner ruling already (Light's
  Echo: "no self-chain, current behaviour") or still genuinely open, so the mechanism ships unused by live data,
  proven only by `test_compare.py`'s `OwnerFallbackTest` and `test_stack.py`'s two new `StackCompareTest` cases.

## Consequences

- A future ambiguous tooltip whose logs are checked and say nothing is closed by adding one `log_queries` entry
  to the class file, naming the query, instead of writing a new judging branch or a one-off text fix.
- `ambiguous_tooltip`'s player-facing question still appears exactly when it did before this item, for every
  class and every existing fixture (`test_compare.py`'s and `test_stack.py`'s pre-existing ambiguous-tooltip
  tests pass unchanged) — the fallback only changes behaviour once a `log_queries` entry exists.
- The "alert when the server applies neither reading" branch of `owner_fallback` is unreachable from either of
  today's two call sites given their binary reading domain; a future check that judges three or more readings of
  the same tooltip reuses it as-is instead of needing its own fallback logic.
