# 0236. A resurrection answered in a cast-combat entry

- Status: accepted
- Date: 2026-11-12

## Context

Spiritual Ascension 500688, claim 59: "Call an ally's spirit back to their body, bringing them back to life." The
`cast_combat` entry cast it at a dead ally in combat and read only that the cast was not refused. A player resurrection
is an offer (SMSG_RESURRECT_REQUEST); the dead player comes back only when it answers with CMSG_RESURRECT_RESPONSE
(348), as the bloodmage-vampyr-bite-resurrect-3994 scenario does with the harness `client_packet` action.

## Decision

`cast_combat` reads `cast_spell` (a rank to cast, default the entry's spell), `label_suffix` and `resurrect: true`. With
`resurrect`, the dead ally sends the accept response before the cast and its `alive` is read (the control, 0), and again
after the cast and the cast-failure read (1). Entries without these fields regenerate byte-identical.

## Consequences

- On build 2a99d5b855eb, both runs (20261112-031521 / -031601): Spiritual Ascension 500758 (level 60 rank), cast in
  combat at the dead ally: not refused; the ally stays dead after an unprompted answer and is alive after the cast.
- Seeded tests: the answers bracket the cast; an ally still dead after the cast alerts, and an ally alive in the control
  alerts; the base entry's labels are unchanged.
