# 1225. A metric delta can destroy an equipped item before its second cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Shield Radiance 504580 ("from your shield"): the DBC requires an equipped shield (EquippedItemClass 4,
EquippedItemSubClassMask 64) and no entry showed the cast refused without one. Mentor ruling D-223: allowed only
through an existing harness means; `destroy_item` and `reset_cooldown` exist.

## Options

- A `cost_gate` arm: its arms are reduction arms (resource or cooldown), which do not fit an equipment requirement.
- An opt-in `metric_delta` option using the existing harness steps. Python only (mentor confirmation, 2026-11-22).

## Decision

`without_item` (`{"item", "source"}`) on a `metric_delta` that reads `cast_failure` of its own trigger cast in both
phases: the first cast, with the item equipped, is the control; right before the second, the option adds a
`reset_cooldown` of the trigger spell (the first cast's cooldown would refuse with 67 first) and a `destroy_item` of the
equipped item. The entry states the expected failure code with the DBC requirement and the code line that returns it
in `source` (Spell.cpp:7539-7541, SPELL_FAILED_EQUIPPED_ITEM_CLASS 29). The option refuses an item the scenario never
equips and anything but two casts.

## Consequences

- Opt-in; finished classes regenerate byte-identical.
- Seeded tests: step order, refusals, `ok` for 0 then 29, `alert` for 0 then 0, 29 then 29 and 0 then 31.
- The entry waits 2000 ms after the first cast (Sun Cleric 504580), past the 1500 ms global cooldown, which would also
  refuse the second cast with 67; the first counted pair read 67 instead of 29 before the wait and the reset were in place.
- `void_on_cast_failure` stays refused for a `cast_failure` entry, which judges the cast itself.
