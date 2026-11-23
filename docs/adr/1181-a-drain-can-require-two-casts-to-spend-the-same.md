# 1181. A drain can require two casts to spend the same

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-23
- Builds on: the `ally_heal_reach` `drain` judge

## Context

The `drain` judge of `ally_heal_reach` passes when `high_cast` spends more power over its watch than `low_cast`. The
Mojo Beam 501117 `beam_drain` entry used it for "For every sprouted the branch, you consume more and more mana": a
beam on a lone ally against a beam that grows branches. The contributor decided on 2026-11-23 (class ADR
witch-doctor/0033) that the beam's drain no longer scales with its branches, so the claim to prove is that the two
beams spend the same mana, which the judge cannot express.

## Decision

A `drain` check takes an optional `relation`: `more` (the default, unchanged) or `equal`. With `equal` the two casts
must spend the same power within the check's `tolerance`; the verdict shows the band. Only an `equal` check adds
`relation` and `tolerance` to the expectation model.

## Consequences

Classes 19 (with and without `--stack`) and 23 generate byte-identical scenarios (no `equal` drain). Class 13 changes
the expectation model of `501117 beam_drain`; its scenario file changes only its name.
