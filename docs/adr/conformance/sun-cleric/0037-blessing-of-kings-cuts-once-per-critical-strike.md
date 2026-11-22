# 0037. Blessing of Kings cuts the cooldowns once per critical strike, a self-heal included

- Status: accepted (mentor D-220, confirmed defect under the tooltip, 2026-11-22)
- Date: 2026-11-22

## Context

Blessing of Kings 561327: "Critical strikes now reduce the cooldown of Hammer of Kings and Solar Prayer by
$/1000;680671s1." 680671 Effect[0] and Effect[1] are effect 165 (ASCENSION_MODIFY_COOLDOWN), BasePoints -1001, so
1 s per critical strike.

A critical Daybreak 503624 heal on the caster cut Hammer of Kings 804751 and Solar Prayer 806479 by 2000 ms
(diagnostic run 20261122-215740: 15885 and 85885 ms read 2115 ms after the priming cast), while the same cast logged
exactly one critical heal event. A critical Gavel of Wrath on a dummy cut them by 1000 ms (cost_gate cd_hammer and
cd_prayer).

Cause, from the code:

- The PROC_TRIGGER_SPELL 680671 of 561327 Effect[1] does not run: the class script's OnProc calls
  `PreventDefaultAction` (`AscensionSunClericEvents.cpp:150`), and `Aura::TriggerProcOnEvent` then skips every
  effect's `HandleProc` (`SpellAuras.cpp:2398-2412`). Only the script's `Reduce` calls act.
- `Unit::TriggerAurasProcOnEvent` builds one event for the actor's auras and one for the action target's auras
  (`Unit.cpp:14429-14438`). On a self-heal both lists are the caster's, so 561327 is offered the heal twice: with the
  DONE flags, then with the TAKEN flags. Its spell_proc row (ProcFlags 1048575) accepts both, and the check
  (`AscensionSunClericEvents.cpp:117` before this change) asked only for an own critical damage or heal, true on both
  events. On a damage hit the target's auras belong to the enemy, so the cut was single.

## Options

1. In the class check, accept 561327 only on the actor-side event (`DONE_HIT_PROC_FLAG_MASK`), as the Templar
   heal checks do (`AscensionTemplarEvents.cpp:75`).
2. Remove the TAKEN flags from 561327's spell_proc row. Equivalent, but a new SQL file for a one-line script rule.
3. Deduplicate proc events in `Unit::TriggerAurasProcOnEvent`. Rejected: a shared engine path for every class.

## Decision

Option 1. `case 561327` leaves the shared line of 300943 and 704928 and adds
`event.GetTypeMask() & DONE_HIT_PROC_FLAG_MASK` (`AscensionSunClericEvents.cpp:118`). The `Reduce` amounts and the
damage route are unchanged.

## Consequences

- A critical self-heal cuts both cooldowns by 1 s; a critical heal on an ally and a critical damage hit still cut 1 s
  (one actor-side event each).
- Readers of the changed line: only 561327. 300943 and 704928 keep their check; the same self-heal double event
  reaches them and is recorded as an observation, not changed. No other class lists 561327, 680671, 804751 or 806479,
  and no other class code names them; `AscensionStockCoefficientData.h` lists 561327 in a coefficient table that this
  change does not read.
- Regression: class file entries cost_gate cd_hammer_heal and cd_prayer_heal (Daybreak under fixture 10043, with,
  without and beyond arms), metric_delta heal_crit_hammer and heal_crit_prayer (one forced critical self-heal: 1000 ms)
  and heal_plain_hammer and heal_plain_prayer (984954 stops the crit: 0 ms, the control), with
  `void_on_cast_failure`; cost_gate cd_hammer and cd_prayer keep the damage route at 1000 ms.
- Client text unchanged.
