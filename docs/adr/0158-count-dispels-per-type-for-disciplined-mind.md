# 0158. Count dispels per type for Disciplined Mind

- Status: accepted
- Date: 2026-11-11

## Context

Disciplined Mind rank 1 680399 reads "causes it to dispel $525052s2 poison and disease effect" and rank 2 681483
"causes it to dispel 2 poison and disease effects". The owner ruled on 2026-11-11 that rank 2 dispels 2 poison and
2 disease effects per Benediction and rank 1 one of each (`method-study/owner-rulings-2026-11-10.md`, "Disciplined
Mind"), and asked for a tool step that measures both ranks before any fix. The existing checks only counted the
casts of 525052 (`trigger_count`) or saw a named debuff disappear (`dispel_removal`); neither counts removals.

## Decision

A behaviour kind `dispel_count`: an ally (second level 60 player) carries fixtures of each stated dispel type; every
arm, one of them a control without auras, casts the trigger spell at it several times; each fixture is read before
and after every cast, and the verdict per arm and type compares the removals of each cast exactly with the stated
count. The fixtures' dispel types are checked against Spell.dbc.

## Consequences

- Templar entries for 680399 (control, rank 1: 1 disease, 1 poison) and 681483 (control, rank 2: 2 and 2), with two
  diseases (55095, 55078) and two poisons (2818, 25810) on the ally and Benediction 578276 as the cast.
- Measured on worldserver aff5042089fe, two runs (20261111-213735, -213819): control 0 + 0, rank 1 1 + 1 (ok), rank
  2 1 + 1 (alert: the confirmed defect). No server change in this step.
- A type cannot show more removals than its fixtures: two of each cannot reveal a third removal.
