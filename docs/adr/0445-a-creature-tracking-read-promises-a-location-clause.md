# 0445. A creature tracking read promises a location clause

- Status: accepted
- Date: 2026-11-13

## Context

Sense Undead 562028: "Shows the location of all nearby Undead on the minimap". Its Effect[0] is aura 44
SPELL_AURA_TRACK_CREATURES with MiscValue 6 (Undead). `AuraEffect::HandleAuraTrackCreatures`
(SpellAuraEffects.cpp:3432-3446) sets the bit `1 << (MiscValue - 1)` of the player's PLAYER_TRACK_CREATURES field,
and the client draws the tracked creatures on the minimap from that field. The claim was a status 4 candidate as a
whole; the mentor ruled on 2026-11-13 that the server part is observable through the field, and that only the
minimap rendering is client-only. The harness had no read of the field.

## Decision

- The harness metric `track_creature_type` reads whether a player's PLAYER_TRACK_CREATURES field holds the bit of
  creature type `id` (1 to 32). It is a read only (G-39).
- `METRIC_EVIDENCE` classes it as a STATE read, and `STATE_PROMISES['track_creature_type']` names "location" and
  "track": a cast contrast of the read proves a clause that shows creature locations or tracks them.

## Consequences

- Sense Undead's entries read the Undead bit (0 before, 1 after a real cast) and the Humanoid bit as a contrast (0
  after the same cast). The minimap rendering stays status 4: a lab client check with the aura on and an Undead in
  range.
- Tests: `TrackCreaturePromiseTest` (test_coverage.py), the location clause and a damage proxy clause (data).
