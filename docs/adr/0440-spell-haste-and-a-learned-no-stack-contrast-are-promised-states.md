# 0440. Spell haste and a learned no-stack contrast are promised state reads

- Status: accepted
- Date: 2026-11-13

## Context

Apothecary's Cauldron 560537 (Necromancer B4, chunk c4): "Increases the spell haste of all party and raid members by
$s1%. Does not stack with similar effects." Effect[0] is an area raid aura 216 SPELL_AURA_HASTE_SPELLS; the stock
handler divides UNIT_MOD_CAST_SPEED by 1.03. Its `party_stat_ratio` entry reads a grouped ally's cast speed
multiplier 1 -> 0.970874 on the counted pair 20261113-024648 / -024728 (build 812e6ea890fc), yet coverage counted the
clause as data: `STATE_PROMISES['cast_speed_multiplier']` names "casting speed" and "cast speed", not "spell haste".

The no-stack clause is read as the mentor ruled for a state read (G-21 point 2, ADR 0424): the consumed value after
one real application and after a second, similar one. `group_stack_cap` cannot judge a cast speed multiplier yet (its
inverse relation is set only for swing intervals), so the entry is a `metric_delta` with 560537 learned up front and
the similar Dark Prophecy 800517 (spell_group 2000182, +2%) as the learned gate: 0.970874 before and after, against
0.951837 summed. ADR 0424 promises a no-stack clause only to `behaviour_group_stack_cap`.

## Decision

- `STATE_PROMISES['cast_speed_multiplier']` also names "spell haste".
- `coverage.promised_state` lets a learned-contrast `behaviour_metric_delta` state read promise a clause with the
  no-stack words (`NO_STACK_WORDS`) as well as its stat words. A contrast that is not a learn stays data.

## Consequences

- A cast speed state read proves a spell haste clause; a learned metric_delta state read proves "does not stack" when
  its gate is the similar effect. Choosing that gate (not the spell itself) remains the author's and the reviewer's
  check: the entry's `observe_source` names the second application.
- Tests: `SpellHasteAndNoStackPromiseTest` (test_coverage.py): the haste clause and an attack power proxy, the
  no-stack clause and a stacking proxy, a no-stack clause without a learned contrast (data), and a seeded mutant
  that drops the no-stack words and must read data.
