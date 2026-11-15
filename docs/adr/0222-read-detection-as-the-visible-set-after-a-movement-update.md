# 0222. Read detection as the client-visible set after a movement-driven visibility update

- Status: accepted
- Date: 2026-11-12

## Context

Crusader's Brand 300513: "While marked enemies can always be seen by the Crusader even while stealthed or
invisible." ADR 0197 reads `can_detect`, the harness calling `Unit::CanSeeOrDetect`. The mentor (ext2 item 4 calls,
point 4, 2026-11-12) counts that call as a readback, so claim 19 stayed data conformant. Behaviour is the server's own
decision after a real update: the unit is in the observer's visible set, or a hostile creature engages it only with
the brand. A second route agent made this attempt.

A stationary dummy's aura change does not refresh any visible set. `HandleAuraModStalked` forces the update only
for a player target. `HandleModStealth` and `HandleModInvisibility` force it only for a player, a player-owned unit
or an instanced map. Otherwise `Unit::UpdateObjectVisibility` only queues `NOTIFY_VISIBILITY_CHANGED`, and
`Unit::ExecuteDelayedUnitRelocationEvent` returns early unless the unit moved by the `requiredMoveDistanceSq` of
`DynamicVisibility.h` (1 yd below 500 sessions) since its last notify. This matches the static client read of
ADR 0197, which did not refresh.

## Considered options

1. Lead (a): the observer's client-visible set (`Player::HaveAtClient`, read by `nearby_creature_at_client`) after
   the observer moves 3 yd aside and back, 1000 ms apart. Each move goes through `Map::PlayerRelocation` and the
   delayed relocation event, which runs a `PlayerRelocationNotifier`. `Player::UpdateVisibilityOf` then creates or
   destroys the dummy at the client with `CanSeeOrDetect(target, false, true)`. Both moves exceed the 1 yd threshold,
   and the wait between them lets the first event run before the caster steps back.
2. Lead (b): a hostile creature with the brand cast by it, engaging a stealthed player through
   `CreatureUnitRelocationWorker` and `MoveInLineOfSight`. This would make a creature the brand's caster, one step
   further from the tooltip's Crusader, and the creature would need an aggressive reaction. Not needed once option 1
   passed.
3. Keep the predicate only, which leaves the claim with "no behaviour route" (status 3).

## Decision

- The `detection` kind takes `read` (`predicate` by default, as in ADR 0197, or `client`), `step_yd` (3) and
  `step_wait_ms` (1000). A `client` read relocates the caster by `+step_yd` then `-step_yd` on y, waiting
  `step_wait_ms` after each move, before every `nearby_creature_at_client` read of the dummy's entry. Its labels are
  `<spell> behaviour_detection client <hide> <moment>`, and its scenario key has the `client` variant.
- The arms are unchanged: shown, hidden by each hide aura (the control: no brand), revealed (the brand set by the
  caster), and unrevealed (the brand removed). The hidden, revealed and unrevealed reads are each compared exactly.
- `nearby_creature_at_client` is an event-class metric in `coverage.METRIC_EVIDENCE`. The visible set is what the
  server's own update decided and sent to the client, so a `behaviour_metric_delta` on it counts as behaviour.
- The harness is not changed. `relocate` and `nearby_creature_at_client` already exist.

## Consequences

- Claim 19 rests on the client read. The counted pair and its readings are recorded in the clause ledger.
- The predicate entry and its scenario are unchanged. 1474 generated scenarios regenerate byte-identical, plus one
  new one.
- A stationary aura change still refreshes nothing. A route that needs a visibility decision has to move a unit past
  the threshold.
- Tests: `test_behaviours.DetectionTests` (client steps, seeded alerts, refused read) and
  `test_coverage` (the client set acts, the predicate does not).
