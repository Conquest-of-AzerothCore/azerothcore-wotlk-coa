# 0697. A value scenario reads a summons-only aura on a named summon

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

`SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS` (190) creates the aura on the caster but applies it to the caster's
summons only: `UnitAura::FillTargetMap` (`SpellAuras.cpp:2952-2969`) lists the owner's `m_Controlled` summons and
never the owner. `values.aura_carrier` read every self-target aura on the caster, so Decimate 804194 (Witch Hunter,
three effect-190 auras, 20 s) read `aura_duration_ms` and `aura_amount` 0 on the caster in final07 (alerts) although
nothing showed a defect (`GetAura` finds applications only). The value scenario also summoned nothing. Approved by the
mentor under O-12 (D-103..D-105).

## Options

- Read the aura on a summon named by the class file, summoned before the cast.
- Mark every effect-190 read unmeasurable: loses the duration proof.
- Add an owned-creature aura amount metric to the harness: a harness change, not approved here.

## Decision

The first option, opt-in per rank. A class file's `summon_aura_carriers` entry (`spell`, `entry`, `summon`, `learn`,
`reason`) makes `value_scenario` learn `learn` and `summon`, cast `summon` (at the dummy when it is hostile, which then
places the dummy at the summon spell's cast distance), require one owned `entry` creature within 8000 ms (a `SETUP:`
assert), cast the rank, and read its effect-190 auras on that creature: presence as `owned_creature_count` with the
spell and caster, the duration as `owned_creature_aura_max_duration_ms` (the maximum duration, judged as the
duration token). An amount or amplitude has no owned-creature metric: those expectations are unmeasurable with that
reason, and a behaviour entry on the summon's damage judges the amount. Ranks without an entry keep the caster read.

## Consequences

- Witch Hunter: Decimate reads on a Lesser Shadow Hound 50224 summoned by Houndmaster's Call 802273 with 705450.
  Counted pair 20261115-163258 / 20261115-163350 (worldserver 7cbb6fe9bc40): `804194 aura_duration_ms #0` ok 20000 /
  20000 (final07 alert 0); `804194 aura_amount e0 #1` unmeasurable. The damage part is judged by
  `705450 script_hit 706332 one_leap_decimate` (Decimate cast first, the hound summoned after it picks the aura up at
  the 500 ms target map update before it lands 20 yd away): 218 / 218 per strike against the text figure x 1.3 = 218.4,
  tolerated (truncation).
- Finished classes 19 (Templar) and 23 (Necromancer) generate byte-identical scenarios and manifests; the Necromancer
  effect-190 ranks have no entry and keep the caster read.
- Tests: `test_values.SummonAuraCarrierTest` (the reads on the summon, the summon before the cast, the unmeasurable
  amount); mutant: without the class-file entry the duration is read on the caster again, the read that measured 0.
