# 0029. Graven Effigy lengthens crowd control

- Status: accepted (contributor decision 2026-11-22); engine file `Unit.cpp`, gated on Witch Doctor ids
- Date: 2026-11-21

## Context

Graven Effigy 506635: "Enemies within $504761s1 yds have the duration of crowd control effects on them increased by
$504767s1%" (25). The field 504767 carries aura 232 on mechanics 7, 11 and 2 at +25, but `Unit::ModSpellDuration`
keeps only a negative total of that aura, so the increase never applied: the cycle 11 sweep 20261121-231523 read a
Lethargy Jinx of at most 12089 ms inside the field against 12500 (`506635 graven_cc`).

## Decision

- `ModSpellDuration` adds a raised term: the largest positive aura 232 amount for the spell's mechanic from a Witch
  Doctor aura (SpellFamilyName 19), applied with its own `AddPct`. Positive aura 232 values of other families
  (Supernova, Crushing Pressure, Darnell's Blade) keep today's behaviour.

## Consequences

- Regression: `506635 graven_cc`. An engine-file edit: the finished-class reruns run in the final pass.
