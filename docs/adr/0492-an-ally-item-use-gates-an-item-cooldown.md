# 0492. An ally's item use gates an item cooldown

- Status: accepted
- Date: 2026-11-13

## Context

Create Bone Reliquary 803771 and Create Frozen Reliquary 803777 create items that the Necromancer hands to allies:
"Allies may only use a Bone Reliquary once per minute." and the same for the Frozen Reliquary, plus "Shares a
cooldown with similar effects." for the Bone Reliquary. The items 11521 and 555555 carry spellcategory 1153 with a
60000 ms category cooldown in item_template. No behaviour kind had an ally use an item: `metric_delta`'s
`trigger_item` uses an item on the caster in the treatment phase only (ADR 0431). The harness `use_item` action
already drives the real item-use handler (HandleUseItemOpcode) for any player actor and records its cast failure,
so no harness change is needed (G-39 holds).

## Decision

- A new behaviour kind `item_cooldown_gate`: a grouped ally (a second player) holds `item` and uses it with
  `item_spell` first (accepted), `cooldown_ms - margin_ms` after the first use (refused with 67
  SPELL_FAILED_NOT_READY) and `cooldown_ms + margin_ms` after it (accepted); `margin_ms` defaults to the cost gate's
  500 ms. Each attempt reads the ally's `cast_failure` and completed `spell_go_count`, judged exactly as
  `behaviour_cast_condition` (behaviour). With `shared_item`/`shared_spell`, the other item is used right after the
  second accepted use and must be refused.

## Consequences

- Both "once per minute" clauses get bracketed behaviour reads with a control (the first use).
- The shared arm reads whether the second item is refused; the first pilot accepted it (an alert, recorded as a lead).
- Templar `generate --class 19` and `--stack` are byte-identical before and after.
- Tests: `ItemCooldownGateTests` (test_behaviours.py): the arms, actors and waits; an early use that goes through
  alerts; a shared item without its spell is refused.
