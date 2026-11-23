# 0383. Strike bursts read a minion's hits around its scripted strike

- Status: accepted
- Date: 2026-11-13
- Split before publication (mentor ruling 2, 2026-11-13): this ADR keeps the tool rule; the Skeletal Rogue fix it was
  written for is [Necromancer ADR
  0007](conformance/necromancer/0007-the-skeletal-rogue-command-strikes-two-to-five-times.md).

## Context

A minion command that strikes a rolled number of times (the Skeletal Rogue's Command, Necromancer ADR 0007: 2 to 5
strikes above 35% target health, 5 below) cannot be judged by a single hit count: the count varies per Command, and a
minion's own auto attacks fall between Commands. No existing kind read the hits of one scripted strike tick.

## Decision

- The conformance kind `strike_bursts` reads a minion's hits just before and just after its scripted strike tick, per
  Command, with a stance cycle (Pacify, then another stance) that stops the minion between Commands, a control
  Command with no minion raised, and arms of falling target health. Its judge (a `behaviour_metric_delta` verdict)
  requires every count inside the arm's range and both ends seen.

## Consequences

- An arm's trial count sets the chance that a correct server misses an end of the range; the entry states it (the
  Skeletal Rogue entry's figures are in Necromancer ADR 0007).
