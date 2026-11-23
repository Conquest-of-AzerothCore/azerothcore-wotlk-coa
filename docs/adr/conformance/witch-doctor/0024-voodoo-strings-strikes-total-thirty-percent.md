# 0024. Voodoo Strings strikes total 30% over 3 sec

- Status: accepted
- Date: 2026-11-21

## Context

Voodoo Strings 705910: "strikes an additional time every $706898T1 sec for 30% of the damage dealt over
$706898d". The script gave each of the three strikes 30% of the Juju damage, 90% in all: the cycle 11 sweep
20261121-231523 read 0.863 of the Juju damage against 0.30. "X over D" is the stock form for a total, and a live
Details aggregate shows about 10% per strike (a 2068 critical Juju gave strikes up to 206).

## Decision

- Each strike copies 10% of the Juju damage, 30% over the three strikes.

## Consequences

- Regression: the class entry `705910 strike_share`. Decision M-70.
