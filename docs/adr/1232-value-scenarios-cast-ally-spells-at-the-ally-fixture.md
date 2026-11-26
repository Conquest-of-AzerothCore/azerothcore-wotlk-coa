# 1232. Value scenarios cast ally-only spells at the ally fixture

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-256 (Sun Cleric 27, end-of-class round C)

## Context

The value scenario of a rank has one cast step. `values.py` gave it a target only for hostile spells and resurrections.
An ally-target spell (TargetA 21) was cast without a target and the server refused it: 12 `BAD_TARGETS` (503498..503508,
804249, 804253) and 2 `TARGET_AURASTATE` (804250, 804254); a first run with the ally target alone still refused
13 of them with `BAD_TARGETS` because the target must be Blessed by the caster. The cast exists to produce the
`cast_failure`, `cooldown_ms` and aura reads, so those reads followed a cast that did not happen.

## Options

- Leave the refusal: the comparison already marks the cast-dependent reads `unmeasured` after a refused cast, but the
  data of 15 spells is never read.
- Remove the 15 scenarios with a skip option: loses their `effect_value` and aura data labels.
- An opt-in class-file list that casts the rank at the existing ALLY fixture, after real setup casts.

## Decision

The class-file list `value_ally_casts` (`[{spell, setup_casts?}]`, default absent) makes the value scenario of a listed
rank cast it with `target: ally` on the ALLY player fixture the scenario already uses, after `setup_casts`: each is
learned, cast at the ally with its mana set, and followed by a 2000 ms settle (past the GCD). No listed spell leaves
the generated scenarios unchanged; finished classes 15, 19 (and `--stack`) and 23 were generated before and after and
the outputs compared. Sun Cleric lists the 15 ranks, each with a real Bless 804247 cast at the ally (the server refuses
804249, 804250, 804253, 804254 and their ranks unless the target carries the caster's Bless,
AscensionSunClericAbilities.cpp:154-159), the same fixture as the 804250 `duration` entry.

## Consequences

A refused cast still voids the cast-dependent reads (`unmeasured`); the counted pair must show no refused setup cast in
these 15 scenarios. The tool is Python only; unit tests: `ValueAllyCastTest` in `test_values.py`.
