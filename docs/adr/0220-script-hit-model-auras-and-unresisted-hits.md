# 0220. Script-hit model auras and unresisted hits

- Status: accepted
- Date: 2026-11-12

## Context

The `script_hit` model counts the class file's `known_auras` as modifiers, and only of aura types 341 and 136. Three
claims of R2 side b hit under an aura the treatment cast itself applies, or ignore resistances:
- Eternal Blessing 705300, claim 219: 707111 strikes while 705300's +15% Holy damage done (aura 79) is up;
- Libram of Grace 801463, claim 324: Grace 804150 heals the Templar under the Libram's +20% healing received (aura 118);
- Norgannon's Wrath 524739, claim 89: 524740 ignores resistances (AscensionIgnoreAbsorbAndResistance).

A first run read 163.5 against a model of 125.7 (705300, with beeg spellpen), 58.9 against 49.5 (801463) and 1455.0
against 1280.65 (524740): each the tooltip value times the auras held, which the model left out.

## Decision

- `model_auras`: aura ids the entry's casts apply to the caster; the hit model adds them to its auras, at generation
  and when judging. An aura no cast of the entry applies is refused.
- `unresisted: true`: the model takes no resistance mitigation.
- The model reads SPELL_AURA_MOD_DAMAGE_PERCENT_DONE (79, by school) and SPELL_AURA_MOD_HEALING_PCT (118) besides 341
  and 136. No existing model holds an aura of those types, and every existing scenario and manifest regenerates
  byte-identical.

## Consequences

- On build 861e0e1e6bee: 707111 mean 143.7 inside the model with 887007 -20% and 705300 +15% (144.3); Grace 58.8
  inside the engine model with 887007 -20% and 801463 +20% (58.5); 524740 1455.0, the model's 1819 x 0.8 exactly.
- Seeded tests: the Libram is among the heal model's modifiers; Eternal Blessing's aura 79 +15% is among the strike
  model's; the unresisted strike has no spread; a model aura no cast applies is refused.
