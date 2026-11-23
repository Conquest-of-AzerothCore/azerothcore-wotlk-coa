# 1244. An ally arm sets each ally's power ahead of the trigger

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: owner ruling O-30 (mentor D-303), approved in the o30 dispatch on the condition that the harness
  `set_power` step already takes an actor other than the caster
- Related: ADR 1186 (ally arm), ADR 1209 (`ally_class`), Sun Cleric ADR 0041

## Context

Lights of Absolution 807343 (O-30, Sun Cleric ADR 0041): 807525 and 807526 restore 2% of the missing Energy, Focus,
Runic Power and Rage, and no mana. The harness fills every power of every actor at setup
(`CoAGameplayTest.cpp:3053-3054`), so an ally only ever showed a full pool: 0 restored, which a server that restores
nothing also reads. `ally_arm` could
set an ally's health (`ally_health`) but not its power; `ally_attacks` sets the ally's mana only. The harness
`set_power` step already resolves its `actor` to any scenario player (`CoAGameplayTest.cpp:7714`, `:9073-9085`) and
refuses a value above the maximum, so no harness change is needed.

## Decision

- `ally_arm` key `ally_power`: a non-empty list of `[power, value]`, a power index 0 to 6 once each and a value of at
  least 0, refused without an ally. Each phase sets every ally's listed power to its value with `set_power`, right
  after `ally_health` and ahead of the trigger; the contract states it, and the expectation model carries
  `ally_power`.
- Python only, opt-in: without the key no step, contract text or model key is written, so every existing scenario
  regenerates byte-identical.
- The pool is read by a judged `power` arm on the ally after landing: the set value in the uncast phase, the set value
  plus the restore in the after phase. It is not a precondition, so a pool that did not move alerts.

## Consequences

- Sun Cleric gains five partial-pool entries of 807343 (`restore_*_partial`): rage and runic power at 500 of 1000
  (gain 10, stock 20), energy and focus at 50 of 100 (gain 1, stock 2), mana at 1400 of 2868 (gain 0, stock 57).
- Tests (`test_ally_arm.py`): the steps land on every ally in both phases after the health and ahead of the trigger;
  no key writes nothing; malformed values and an option without an ally are refused; a restore of nothing or of the
  maximum-power base alerts on the pool arm (mutants).
- The value is fixed per scenario; a pool that depends on another actor's state is not expressed.
