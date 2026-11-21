# 0058. An `oath_consumption_removal` behaviour kind proves Righteous Tempest's "Consumes your Oaths" clause

- Status: accepted
- Date: 2026-11-10

## Context

ADR 0057 proved five of the six "Consumes your Oaths, dealing additional damage/healing for each consumed."
Breaker clauses with the `oath_consumption` kind, but explicitly left Righteous Tempest 805409 out: it uses a
different, already-scripted mechanism and consumes the Oaths on aura *removal*, not on cast.

Reading `AscensionTemplarAuras.cpp`'s `aura_ascension_templar_lifecycle`: when 805409's own aura applies
(`Calculate`, `index == 0`), it sums `max(0, GetAuraEffect(oath, EFFECT_2)->GetAmount())` over the four Oaths
`{804904, 804922, 804924, 805332}` and stores the total with `SetScriptValue(805409, bonus)`.
`AscensionTemplarAbilities.cpp`'s `OnSpellCalculatedTarget` multiplies every `RighteousTempest()` spell's
(805410, 570200-570205) hit damage by `1.0 + scriptValue / 100.0`. The Oaths are *not* cleared on cast:
`OnSpellCast`'s `Breaker(info)` branch explicitly exempts `Named(info, 805409)` from its unconditional
`ClearOaths(player)`. They are cleared only in `aura_ascension_templar_lifecycle::Remove`'s own
`Named(GetSpellInfo(), 805409)` branch, which runs on every removal of 805409's aura (natural expiry included,
since `AfterEffectRemove` is registered for `AURA_EFFECT_HANDLE_REAL` with no remove-mode filter).

Confirmed by DBC record: all four summed Oaths' own `EFFECT_2` is `SPELL_AURA_ADD_PCT_MODIFIER`,
`EffectBasePoints[2] == 29` for every one of them (`coa-dbc-viewer record`), so each contributes the same
raw amount once `SpellEffectInfo::CalcValue`'s `DieSides == 1` roll is applied — ground-truthed live, not
hand-derived, by reading each oath's own `aura_amount` (effect 2) after fixturing it, the same convention ADR
0057 used.

`CoAGameplayTest.cpp` already exposes `aura_script_value` (`metric == "aura_script_value"`,
`aura->GetScriptValue(step.get<uint32>("key"))`), added for an earlier, unrelated check; no C++ change is
needed here. No existing `behaviours.py` kind proves "the bonus baked into a *different* aura's own script
value, read deterministically right after a cast with no combat roll, equals the sum of several fixtured
auras' own effect amounts, and those fixtured auras are consumed only once this aura is later removed, not by
the cast that reads the bonus."

## Considered options

1. Extend `oath_consumption` with a `consume_on: "removal"` flag. Rejected: `oath_consumption`'s shape reads a
   deterministic formula *before* the oath is fixtured and *after*, with no cast in between, then casts once
   to force consumption. Here the oath must be fixtured *before* the cast (the cast's own `Calculate` hook
   bakes the bonus from the already-held oaths), the formula read is a different metric
   (`aura_script_value`, not `spell_damage_done`/`spell_healing_done`), and proving "not yet consumed" requires
   an extra mid-duration stacks read that `oath_consumption` has no slot for. Forcing both shapes into one
   dataclass would need as many optional fields as a dedicated one.
2. A new kind, `oath_consumption_removal`: fixture every oath in a list to 1 stack, read each one's own
   `aura_amount` (effect 2), cast the trigger spell once, read the trigger's own aura's `aura_script_value`
   shortly after (well inside its duration) and expect it to equal the summed `aura_amount` readings, read
   every oath's `aura_stacks` at that same moment (must still be 1), then wait out the rest of the aura's own
   duration plus a margin so it expires naturally, and read every oath's `aura_stacks` again (must now be 0).
   Chosen; proves both the summed-bonus amount and the on-removal-not-on-cast timing in one scenario, and
   generalises to any class whose script stores a derived value on its own aura via `SetScriptValue`.

## Decision

- `behaviours.py` gains `BEHAVIOUR_OATH_CONSUMPTION_REMOVAL`, `OathConsumptionRemovalSpec` (`spell`, `name`,
  `quote`, `trigger_spell`, `oath_spells` — a tuple, so "for each consumed" is proven with more than one Oath
  at once — `oath_effect` default 2, `settle_ms` default 500, `expire_margin_ms` default 1500),
  `oath_consumption_removal_scenario` and `oath_consumption_removal_spec`, wired into `behaviour_scenario`'s
  dispatch under `kind: "oath_consumption_removal"`.
- The scenario fixtures every `oath_spells` entry to 1 stack with `set_aura` (no cast) and reads each one's own
  `aura_amount` (effect `oath_effect`); casts `trigger_spell` once at the caster; waits `settle_ms` (well
  inside the trigger's own DBC duration, read via `Records.duration_ms`); reads the trigger's own aura's
  `aura_script_value` (`key: trigger_spell`) and every oath's `aura_stacks` (expected 1, not yet consumed);
  waits out the remainder of the duration plus `expire_margin_ms` so the aura expires naturally; reads every
  oath's `aura_stacks` again (expected 0, consumed only on removal). No `CoAGameplayTest.cpp` change: `set_aura`,
  `aura_amount`, `aura_script_value` and `aura_stacks` already exist with every field this kind needs.
- `compare.behaviour_oath_consumption_removal_verdict` sums the measured `aura_amount` readings as the expected
  value, bands the measured `aura_script_value` against it through the existing `deterministic()`/
  `banded_status` tolerated mechanism (ADR 0051: `ok`/`tolerated`/`alert`), and downgrades an otherwise-passing
  verdict to `alert` if any oath's stacks reading is wrong at either checkpoint (not 1 while held, not 0 after
  removal).
- `passives.py`'s `BEHAVIOUR_LABELS` P5-link table gains the `oath_consumption_removal` entry proactively
  (the same defect shape step5/step6/step7 guarded against for the other behaviour kinds).
- `classes/templar.json` gains one `behaviours` entry (805409, `oath_spells: [804904, 804922]`, two different
  Oath types held at once, proving the "for each" summation is not special-cased to a single Oath id), citing
  the DBC fields and the live `aura_amount` ground-truthing.

## Consequences

- Righteous Tempest 805409's own "Consumes your Oaths, dealing additional damage for each consumed." clause is
  proven end to end (two independent gameplay runs, both all `ok`), the sixth and last of ADR 0057's starting
  group of six; `classes/templar_clauses.json`'s label for it now points at a live verdict.
- The `oath_consumption_removal` kind generalises to any class's "a cast bakes a derived bonus from currently
  held resource auras into its own `SetScriptValue`, and consumes those resources only when its own aura is
  later removed" clause: a new class-file entry naming the trigger spell and the list of resource auras, no
  further tool code.
- The 85-claim unlabelled backlog, the open dot-overshoot/`tolerated` ambiguity
  (`round10/questions-judging.md`) and a full class-wide `conformance.py coverage --clauses` re-run remain open,
  untouched by this step.
