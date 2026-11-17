# 0750. A spell replacement read can count as a promised state

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 150.2 ("based on the last Tonic consumed", Secret of Raven Hill 680513) is the stand-in the server
keeps for Dawn Blade 802024 after a Tonic: `temporary_spell_replacement` reads `Player::GetTemporarySpellReplacement`
(CoAGameplayTest.cpp), the spell the action bar shows. The c13 Black Knight author measured it in a counted pair
(Witchblood Fever 684330 when Witchblood Tonic is drunk last, Surging Blade 681788 when Surging Tonic is, 802024 without
the talent) and then removed both entries: the metric had no row in `coverage.METRIC_EVIDENCE`, so `metric_class`
raised and the cross-class guard tests of the source stage refused the class file. Mentor decision D-209 (c14 tool
batch item 14).

## Options

- A `STATE` row with a `STATE_PROMISES` row: the read is the live result of the Tonic talents, like `can_detect` (ADR
  0723), and counts as behaviour only under a learned or own-cast contrast whose claim words name the replacement.
- An `EVENT` row, as for `cast_failure`: every conformant verdict would count as behaviour whatever its contrast and
  claim, although the read is a value held between casts, not an event the cast produced.
- A `READBACK` row: the stand-in is not a stored DBC or spell-modifier value, so a contrast on it would never count.

## Decision

The first option. `temporary_spell_replacement` is a `STATE` metric, promised by `transform\w*|replac\w*|last \w+
consumed`. A `metric_delta` on it counts as behaviour under a learned or own-cast contrast with the promise in the
claim words; a condition contrast or a verdict without a contrast stays data.

## Consequences

- No finished class reads the metric: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
  `metric_delta_contrast` reads the row only for `setup_only_after` entries, which neither class has on this metric.
- Necromancer final15 re-audit (both runs, 20261114-071744 and -074148) is byte-identical before and after the row.
  Templar: neither class file nor any of 37 archived Templar verdict sets names the metric.
- Seeded test: a learned-contrast verdict is behaviour under "based on the last Tonic consumed" and "transform your
  Dawn Blade", data under a claim without those words or without a contrast, unproven when it alerts; with the row
  removed (the pre-change table) the audit raises `EvidenceError`.
- Witch Hunter: the entries `680513 last_witchblood` and `last_surging` return (c13 Black Knight readings), and the
  ledger part "based on the last Tonic consumed" names both labels.
