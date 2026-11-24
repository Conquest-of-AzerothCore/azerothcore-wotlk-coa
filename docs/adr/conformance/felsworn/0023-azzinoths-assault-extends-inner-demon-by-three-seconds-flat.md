# 0023. Azzinoth's Assault extends Inner Demon by three seconds flat

- Status: accepted (owner ruling Felsworn O-30 (2026-11-24, Felsworn ADR 0023))
- Date: 2026-11-24

## Context

Azzinoth's Assault 803475 (server Spell.dbc, Description[enUS]): "Inner Demon: Extends the duration of Inner Demon by
$/1000;803089s1 sec." 803089 Effect[0] is SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION on Inner Demon 804216 with
BasePoints 2999 + 1, so the tooltip reads 3 sec. The spell also carries EffectBonusMultiplier[0] 0.4, a stock column
that the repository's parity guide does not treat as a CoA coefficient.

The Felsworn coefficient table held a row `{803089, 0, 0.4 AP}` (added with #5647), so
`felsworn_scaling::ModifySpellEffectBaseValue` raised the extension to 3000 + 0.4 x attack power ms: about 3124 ms at
the reference attack power 312 and 11124 ms at +20000. Nothing in the tooltip, the references or the logs states an
attack power term (owner question N-3, fix-250 note section 5).

## Options

- (a) The tooltip governs: remove the 803089 row; every Assault extends Inner Demon by 3 sec.
- (b) Keep the attack power term and correct the displayed text.

## Decision

Owner ruling Felsworn O-30 (2026-11-24): (a). The row `{803089, 0, 0.4 AP}` is removed from `AscensionFelswornData.h`. `ExtendInnerDemon`
still passes `GetEffectValue()` of 803089 to `Extend`, which is now the DBC 3000 ms. No other file, SQL, DBC or client
text changes; the tooltip already reads 3 sec.

## Consequences

- Inner Demon gains 3000 ms per Assault whatever the attack power; geared players get shorter windows than before
  (1.2 s less per Assault at 3000 attack power).
- Regression: the Felsworn class file entries `803475 extend_held` and `extend_gone` read Inner Demon (10000 ms at
  the fixtures) present 12835 ms and absent 13145 ms after one Assault; `extend_ap_gone` reads it absent at +20000
  attack power, where the removed row held it to about 21124 ms. `extend` and `extend_ap` read the remaining
  duration before the Assault and 100 ms after it: a gain of 2900 ms (3000 less the wait) at both attack powers.
  The control arms are the uncast before reading, `extend_absent` (no Inner Demon, nothing extended) and
  `extend_casts` (one 803089 per Assault).
- Readers: 803089 is cast only by the Felsworn caster code (`AscensionFelswornAbilities.cpp`) and read only by its
  `ExtendInnerDemon` handler. No other class lists it.
