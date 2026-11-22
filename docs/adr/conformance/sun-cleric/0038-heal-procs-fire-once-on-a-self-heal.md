# 0038. Eight heal and critical-strike procs fire once on a self-heal, from the actor-side event

- Status: accepted (mentor D-255/D-258, confirmed defect under the tooltips, 2026-11-23)
- Date: 2026-11-23

## Context

A heal by the caster on the caster doubled eight procs of the class, while the same heal on an ally fired them once
(rc4 counted pair, verify stamps 20261122-230622 and 20261122-230702, self / ally):

| Spell | Tooltip trigger | Read | Self | Ally |
|---|---|---|---|---|
| 300943 Pious | "your critical strikes grant allies Replenishment" | casts of 1257670 | 2 | 1 |
| 704928 Bastion of Hope | "Critical strikes now bless you" | energize 704926 (tooltip 40.5) | 80 | 40 |
| 300336 Light The Way | "Healing done by Shine or Illumination" | casts of 300337 | 2 | 1 |
| 300339 The Redeemer | "When you critically heal your target" | casts of 301005 | 2 | 1 |
| 704563 Warmth | "Direct healing now increases the target's health" | casts of 704564 | 2 | 1 |
| 707077 | "Direct healing done now increases the target's Armor" | casts of 804405 | 2 | 1 |
| 534267 Heat Wave | "Healing with Illumination, Shine, and Daybreak" | heals of 801215 | 4 | 2 |
| 704936 | "Your Illumination now shields you" | casts of 802598 | 2 | 1 |

Every trigger names the healer's side: a heal or critical strike the Sun Cleric deals.

Cause, from the code (the same mechanism as [Sun Cleric ADR 0037](0037-blessing-of-kings-cuts-once-per-critical-strike.md)):

- `Unit::TriggerAurasProcOnEvent` builds one event for the actor's auras and one for the action target's auras. On a
  self-heal both lists are the caster's, so each aura is offered the heal twice, with the DONE flags and then with the
  TAKEN flags.
- The spell_proc rows of the eight auras (`rev_20260909_13_sun_cleric_completion.sql`, ProcFlags 1048575) accept
  both sides, and their cases in the class check (`AscensionSunClericEvents.cpp`, from e36bc50aad) asked only for an
  own heal or critical hit, true on both events. On a damage hit the target's auras belong to the enemy, so damage
  procs were single.

Hope 300349 ("Your critical heals now reduce the cooldown of Solar Invocation spells by 1 sec ... once per sec") reads
once on a self-heal (26885 / 26887 ms against 26888 ms on an ally): its case calls `Chance(player, id, 1000)`, which
schedules a 1000 ms timer on the first accepted event, and the second event of the same heal finds the timer running
(`AscensionSunCleric.cpp`, `Chance`).

## Options

1. In the class check, accept the eight cases only on the actor-side event (`DONE_HIT_PROC_FLAG_MASK`), as 561327
   does since ADR 0037.
2. Remove the TAKEN flags from the eight spell_proc rows. Equivalent in effect, but a new SQL file for eight script
   rules.
3. One filter for every case of the check. Rejected: the received-side cases (301005, 680646, 680888, 807547, 560095,
   92137, 680663, 560492, 300355, 704941, 707629) need the TAKEN event.
4. Deduplicate proc events in `Unit::TriggerAurasProcOnEvent`. Rejected: a shared engine path for every class.

## Decision

Option 1. The check computes `done = event.GetTypeMask() & DONE_HIT_PROC_FLAG_MASK` once, and the cases of 300943,
704928, 300336, 300339, 704563, 707077, 534267 and 704936 require it. For The Redeemer only the trigger 300339 is
filtered: its return aura 301005 keeps its own case on the received side. 561327 keeps its ADR 0037 line, 300349 is
untouched, and no SQL row changes.

## Consequences

- A heal by the caster on the caster fires each of the eight procs once, as a heal on an ally; damage routes are
  unchanged (one actor-side event each).
- Readers of the changed lines: only these eight auras, all Sun Cleric spells. No other class code names them;
  `AscensionStockCoefficientData.h` lists 300943 and 301005 in coefficient tables that the check does not read, and
  `mod-spellbook` lists them in its spellbook data only.
- Regression: the class file's d245_self/d245_ally (300943, 704928) and d255_self/d255_ally (300336, 300339, 704563,
  707077, 534267, 704936) metric_delta entries, the ally arm being the control, with `void_on_cast_failure`.
- Client text unchanged.
