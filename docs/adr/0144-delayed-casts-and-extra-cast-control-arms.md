# 0144. Delayed casts, extra-cast control arms and setup waits

- Status: accepted
- Date: 2026-11-11

## Context

The Templar custom-mechanics batch (`lean/mech-batch-brief.md`, proposal `lean/custom-mechanics-proposal.md`) needs
one behaviour test with a control arm for each custom mechanic a Templar spell reaches. Three of the four tests did
not fit an existing check:

- Norgannon's Wrath 524739 "After a short delay, you blast them with immense holy force": its `Effect[1]` 183
  (`SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED`) casts 524740 1500 ms after the cast. No check read the time
  between two events; the harness metric `event_first_ms` existed but no conformance check used it.
- Titanstrike 806521 "extending the duration of your Oath Chain by $/1000;707896s1 sec.": the lengthening comes from
  a cast, not from a learn. The `cast_applies_aura` control arm of ADR 0142 switches on a learn.
- Tyr's Blessing 705285 "Condemn now stacks $s1 additional time.": five Condemn casts in a row are refused by the
  global cooldown, and `metric_delta` setup casts follow each other with no wait.

## Decision

- New behaviour kind `event_delay`, check `behaviour_event_delay`, behaviour evidence. Each of `trials` casts of the
  entry's spell is followed by two `event_first_ms` reads of the `spell_damage` stream of `observe_spell`: since the
  cast packet of the spell, and since the cast packet of `observe_spell` itself. Their difference is the time from
  the cast to the delayed cast, judged against `expected_ms` within `max(5%, 50 ms)`. A cast with no stamped hit
  alerts. The second read is the in-trial control: the first design, which compared the hit with the cast alone and
  took a Chastise 503141 direct hit as the control, read 1628-1636 ms, because 524740 is a missile (`Speed` 30,
  125 ms of flight in that scenario).
- `cast_applies_aura` `control` takes `extra_cast: {"spell", "target", "after_ms"}`. Both arms learn the entry's
  spell first; the `with` arm casts the extra spell `after_ms` after the `cast_spell` cast, inside the arm, so the
  expiry margins count its steps. The readback scenario makes the same cast and expects `expected_ms - after_ms`.
  `after_ms` must differ from the extension, so that a refresh of the aura to its maximum gives another end
  (Titanstrike: 5000 ms, 18000 ms against 20000 ms for a refresh; review of the batch, I1).
- `metric_delta` takes `setup_wait_ms` (default 0, no step): a wait after each setup cast.

## Consequences

- A delayed cast is judged by its own timing, not by the landing of a hit whose flight time the server adds.
- An aura lengthened by a cast is judged by two expiry arms that differ by that cast only.
- Repeated casts of one spell can build a stack count in a `metric_delta` phase.
- Entries without the new fields generate the same scenarios as before.
