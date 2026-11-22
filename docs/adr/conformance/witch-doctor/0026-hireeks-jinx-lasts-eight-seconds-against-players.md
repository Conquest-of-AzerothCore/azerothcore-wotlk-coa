# 0026. Hir'eek's Jinx lasts eight seconds against players

- Status: accepted (contributor decision 2026-11-22); engine file `SpellMgr.cpp`, gated on Witch Doctor ids
- Date: 2026-11-21

## Context

Hir'eek's Jinx 803325 says "(8 sec vs players)". `GetDiminishingReturnsLimitDuration` returned the fear default of
10 s; only named spells such as Amphibimorph get 8 s. The cycle 11 sweep 20261121-235946 read the Jinx still on an
enemy player at 8617 ms (`803325 jinx_player_lasts`).

## Decision

- 803325 joins the CoA cases that return 8 s against players, next to Amphibimorph 500952.

## Consequences

- Regression: `803325 jinx_player_lasts`; `jinx_lasts` on a creature is unchanged. An engine-file edit gated on the
  spell id: the finished-class reruns run in the final pass.
