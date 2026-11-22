# 0009. Tiki Splash joins the target A ally list of dynamic object auras

- Status: accepted (contributor decision 2026-11-22); engine file `SpellAuras.cpp`, gated on Witch Doctor ids
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

The contributor decided this change on 2026-11-22. Guide section 7 criteria 3 and 4 do not
hold: the cause is in a shared core function, and the change is in `src/server/game/Spells/Auras/SpellAuras.cpp`
(`DynObjAura::FillTargetMap`), an `ENGINE_FILES` entry, not in the class's own code.

Tiki Splash 500478 (the Spirit in a Bottle replacement while Tiki Splash 500053 is known and a Base is active) is a
persistent area aura with EffectImplicitTargetA 31 TARGET_UNIT_DEST_AREA_ALLY and no TargetB. `FillTargetMap` took the
friendly search only for an ally TargetB or for the CoA TargetA list (560322, 707591, 804978, Deathwind's Spirit
Realm trigger), so the waters used the enemy searcher and healed nobody: 0 heals in both final05 runs (cycle 8 lead
R4-1).

## Decision

- Add 500478 to the existing `coaTargetAAlly` list in `DynObjAura::FillTargetMap`, next to the entries
  that already encode the ally selector in TargetA, still scoped to TARGET_UNIT_DEST_AREA_ALLY.

## Consequences

- Regression: catalog `witch-doctor-tiki-splash-heals-allies`: after Crystal Water 500962 the doctor and a grouped
  ally 3 yd away are healed and a grouped ally 20 yd away is not (the waters have EffectRadiusIndex 14, 8 yd). It
  passed in sweep 20261121-011354. The verdict moved from alert to ok in both final06 runs (20261121-021022 and
  20261121-023852).
- The edit touches an engine file, so the source stage prints the finished-class rerun of guide section 14.5
  (ADR 0591).
