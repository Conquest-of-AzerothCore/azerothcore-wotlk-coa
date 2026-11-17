# 0057. An `oath_consumption` behaviour kind proves "Consumes your Oaths" Breaker-damage clauses

- Status: accepted
- Date: 2026-11-10

## Context

Six Templar Breaker abilities' tooltips state "Consumes your Oaths, dealing additional damage/healing for each
consumed.": Righteous Upheaval 572027, Chastise 503141, Benediction 578276 (healing), Blade of Faith 803872,
Righteous Tempest 805409 and Reckoning 805421. `claims-merged.json` marked all six `missing`,
`needs_new_metric`: "no measurement here controls for the Oath stack held before casting."

Reading `AscensionTemplarAbilities.cpp`'s `OnSpellCast` (`Breaker(info)` branch, `AscensionTemplar.h`'s
`Family(info, 2, 128) || Named(info, 805409)`) shows `ClearOaths(player)` runs unconditionally on a Breaker
cast, but no CoA script code anywhere adds a damage/healing bonus scaled by the Oath count for five of the six
spells. The actual mechanism is a native engine one, not CoA code: every Oath aura
(804903/804904/804922/804924/805332) carries `ADD_FLAT_MODIFIER`/`ADD_PCT_MODIFIER` effects
(`SpellAuraEffects.cpp:777-795`, `AuraEffect::CalculateSpellMod`) whose `EffectSpellClassMask` overlaps the
target Breaker spell's own `SpellFamilyFlags`. Holding the aura registers a `SpellModifier` in
`Player::m_spellMods[op]`; `Unit::SpellDamageBonusDone`/`SpellHealingBonusDone` (`Unit.cpp:9920`/`10868`) apply
every matching modifier through `Player::ApplySpellMod` (`Player.cpp:10539`) when the Breaker's own
damage/healing formula is computed — before the same cast's `Breaker(info)` branch clears the Oath ("consumed,
dealing additional damage for each consumed"). Confirmed by DBC record and cross-checked live with the
harness's own `spell_modifier` metric (base 1000): 804904 ("Oath: Righteous Lunge") carries two
`SPELLMOD_DAMAGE`-keyed `ADD_PCT_MODIFIER` effects matching every Breaker's `SpellFamilyFlags[2]` bit 128
(`Family(info, 2, 128)`), ground-truthed at ratio 1.365 (not the 1.29 a naive `Spell.dbc` `EffectBasePoints`
read of `4`/`29` gives — `SpellEffectInfo::CalcValue`'s `DieSides == 1` roll adds `+1`, not `+0`, to each,
giving the registered values `5`/`30`); 803872 is a periodic-damage spell, so its formula reads
`SPELLMOD_DOT` instead, which only 804903 ("Oath: Holy Cleave") carries (a flat modifier, ground-truthed at
`+25`, matching 803872's `SpellFamilyFlags[1]` bit 2048). Righteous Tempest 805409 uses a *different*,
already-scripted mechanism (`AscensionTemplarAuras.cpp`'s `aura_ascension_templar_lifecycle::Calculate`,
summing four Oaths' own effect amounts into a custom script value read in `OnSpellCalculatedTarget`'s
`RighteousTempest()` factor) and consumes on aura removal, not on cast — a distinct scenario shape, left for
the next capability; this entry covers the other five.

No existing kind fits a "read a deterministic formula, fixture one Oath aura with no cast, read the same
formula again, then cast once to confirm consumption" shape: every existing metric-delta-style kind compares a
"without the gating passive" phase against a "with it learned" phase (a permanent toggle), not a temporary
combat fixture applied and then expected to be consumed by the very cast being measured.

## Considered options

1. Hand-derive the expected ratio/flat delta from raw `Spell.dbc` `EffectBasePoints` alone. Rejected after a
   first attempt measured a live ratio of 1.36375 against a hand-derived 1.29 and a flat delta of 25 against a
   hand-derived 24: `SpellEffectInfo::CalcValue`'s die-roll convention (`DieSides == 1` still rolls `+1`, not
   `+0`) and a second, previously-overlooked `ADD_PCT_MODIFIER` effect on 804904 (effect 0, mask also
   overlapping every Breaker's family flags) both contribute. Ground-truthing with the harness's own
   `spell_modifier` metric (base 1000, the same mechanism `passives.py`'s `modifier_plans`/`SPELL_MODIFIER_BASE`
   already use for ordinary learnable passives) removes both failure modes at once.
2. A new `behaviours.py` kind, `oath_consumption`: fixture the Oath with the existing `set_aura` action (no
   `CoAGameplayTest.cpp` change), read the already-generic `spell_damage_done`/`spell_healing_done` metric
   (which already supports a `periodic` flag selecting `SPELLMOD_DOT` vs `SPELLMOD_DAMAGE`) before and after,
   then cast once and confirm the Oath's `aura_stacks` reads 0. Chosen.

## Decision

- `behaviours.py` gains `BEHAVIOUR_OATH_CONSUMPTION`, `OathConsumptionSpec` (`spell`, `name`, `quote`,
  `trigger_spell`, `oath_spell`, `relation` — `"ratio"` or `"flat"` — `expected`, `metric`, `effect` default 0,
  `periodic` default `false`, `target` default `"dummy"`), `oath_consumption_scenario` and
  `oath_consumption_spec`, wired into `behaviour_scenario`'s dispatch under `kind: "oath_consumption"`.
- The scenario learns `trigger_spell`, reads `metric` (the "before" formula reading), fixtures `oath_spell` to
  1 stack with `set_aura` (no cast), reads `metric` again ("after"), then sets power/resets cooldown/applies
  `required_aura_steps`, casts `trigger_spell` once, waits 500 ms, and reads `oath_spell`'s own `aura_stacks`
  (must be 0). No `CoAGameplayTest.cpp` change was needed: `spell_damage_done`/`spell_healing_done`/`set_aura`/
  `aura_stacks` already exist with every field this kind needs.
- `compare.behaviour_oath_consumption_verdict` computes `delta = after - before`, the expected delta from
  `relation`/`expected` (`before * (expected - 1.0)` for `"ratio"`, `expected` for `"flat"`), and bands it
  through the existing `deterministic()`/`banded_status` tolerated mechanism (ADR 0051): `ok` within the usual
  tolerance, `tolerated` within 5%, `alert` otherwise; a nonzero post-cast `aura_stacks` reading always
  downgrades an otherwise-passing verdict to `alert`.
- `passives.py`'s `BEHAVIOUR_LABELS` P5-link table gains the `oath_consumption` entry proactively (the defect
  shape step5 found and fixed for `crit_guarantee`, and step6 guarded against for `aura_grant`).
- `classes/templar.json` gains five `behaviours` entries (572027, 503141, 578276, 803872, 805421), each citing
  the matching Oath's own `EffectSpellClassMask`/`ApplyAuraName`/`MiscValue` and the live `spell_modifier`
  diagnostic that ground-truthed its `expected` value.

## Consequences

- Five of the six "Consumes your Oaths" clauses are proven end to end (two independent gameplay runs, both all
  `ok`); `classes/templar_clauses.json`'s labels now point at live verdicts instead of an empty, unproven list.
- The `oath_consumption` kind generalises to any class's "consuming a resource/buff scales a *different*,
  already-deterministic formula's output via the engine's own `SpellMod` system" clause: a new class-file
  entry naming the trigger spell, the fixtured aura and the ratio/flat delta, no further tool code.
- Righteous Tempest 805409's own "Consumes your Oaths" clause uses a different, already-scripted mechanism
  (summed-then-single-factor, consumed on aura removal rather than on cast) and remains unproven; it needs its
  own scenario shape and is left for the next capability, together with the 85-claim unlabelled backlog and
  the open dot-overshoot/`tolerated` ambiguity (`round10/questions-judging.md`).
