# ADR 1327: Audit server-granted `extra_spells` before conformance ledger generation

Date: 2026-11-27
Status: Accepted

## Context

`apps/coa-gameplay-test/conformance/classes.py` starts a class's spell set from
`CharacterAdvancement.dbc` and only appends base spells listed in the class file's manual
`extra_spells` array (ADR 0016). `scaffold` initializes `extra_spells: []` and
`excluded_extra_spells` did not exist. On four of the seven conformance-checked classes,
class-granted starting spells, class-trainer spells, or taught abilities outside
`CharacterAdvancement.dbc` were missed or left undocumented because `class_map.base_candidates`
only read `AscensionCompatData::ClassSpells` and no pre-ledger check enforced coverage.

## Decision

1. Add `apps/coa-gameplay-test/conformance/extra_spells.py` to collect server-granted
   class spells at `class_file['level']` across all five server grant sources:
   - `src/server/coa/AscensionCustomClassData.h` (`AscensionCompatData::ClassSpells`),
   - `src/server/coa/AscensionLiveBaselineData.h` (`AscensionLiveBaseline::Spells` with `RaceId == 0`),
   - `src/server/coa/AscensionTaughtAbilityData.h` (`AscensionCompatData::TaughtAbilities`),
   - `src/server/coa/AscensionCompat.cpp` (`FelswornHordeCapitalRifts` for Felsworn, class 14),
   - `trainer_spell` SQL replayed across `data/sql/base/db_world/trainer_spell.sql`,
     `data/sql/updates/db_world/`, and `data/sql/updates/pending_db_world/` for class trainers
     `900012..900032` with `ReqLevel <= level`.
2. Collapse candidate spell ids via `progression_chains`, mark spells covered by
   `CharacterAdvancement.dbc`, `extra_spells`, or transitive `@s:<id>:` tooltip links from
   covered spells, allow documented omissions in `excluded_extra_spells`
   (`{"spell", "name", "reason"}`), filter generic non-class spells in `STOCK_GENERIC_SPELLS`
   (deliberately excluding `552011` *Resilient Constitution* so every class decides it
   explicitly), and separate same-name unchained rank candidates into `unchained_ranks`.
3. Expose `conformance.py audit-extra [--strict]` and expand `class_map.base_candidates`
   to share the C++ grant parsers and log reader cleanly.
4. Add a pre-ledger gate in `conformance.py ledger`: refuse with exit status `2` when
   `unaccounted` is non-empty unless `--allow-unaccounted-extra` is passed, and print an
   advisory line after `conformance.py scaffold` without altering scaffolded JSON keys.

## Consequences

- New and refreshed class conformance runs must resolve every server-granted spell into
  `extra_spells` or `excluded_extra_spells` before `ledger` starts, eliminating silent blind
  spots on starting, trainer, and taught spells.
- Existing frozen fixtures and checked classes remain untouched by this tooling commit; each
  class's missing base/trainer spells are addressed in follow-up per-class updates.
