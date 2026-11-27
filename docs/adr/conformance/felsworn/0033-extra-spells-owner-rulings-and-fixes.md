# 0033. Extra-spells owner rulings (`Q-fs-ex-1..5`) and confirmed server fixes

- Status: accepted (owner rulings `Q-fs-ex-1..5`, 2026-11-27)
- Date: 2026-11-27

## Context

Phase 1 triage of Felsworn's 43 server-granted `extra_spells` (class 14, L60) confirmed 9 server defects (`D-1..D-9`)
and 5 owner-decision ambiguities (`Q-fs-ex-1..5`) against the installed server DBC set (`/srv/coa/server-data/dbc`) and
archived Ascension live combat logs.

## Owner Rulings (`Q-fs-ex-1..5`)

- **`Q-fs-ex-1 : fixed_285`**: Normalize `EffectDieSides[0] = 1` on `523479..523483` (*Man'ari Intuition* R2–R6) and
  `523495` (*Greater Man'ari Intuition*) so applied armor is deterministic (`285` at L60, matching `${$m1+0}`), instead
  of inheriting vanilla Druid Mark/Gift of the Wild `DieSides = 11` (`285..295`).
- **`Q-fs-ex-2 : keep_energy_per_sec`**: Keep DBC `ManaPerSecond = 15..30` on `552210..552213` (*Manafeed*) untouched
  in C++.
- **`Q-fs-ex-3 : stone_of_retreat_coords`**: Wire `535602` (*Fel Rift: Stonard*) with Stone of Retreat `1777027`
  coordinates (`Map 0, -10446.9, -3261.91, 21.0848, O = 0.00`, display `4398`, matching
  `rev_20260916_00_stone_of_retreat_destinations.sql:340`).
- **`Q-fs-ex-4 : keep_chaos_176_copy`**: Keep the `176 * count` Chaos copy (`807554`) on `712483` (*Bane of
  Betrayal*) expiry untouched, fixing only the visual stack off-by-one.
- **`Q-fs-ex-5 : one_per_caster`**: Keep 1 Pact per Felsworn caster across all 4 Pacts (`800029`/`803885`, `800031`,
  `803343`, `804764`) untouched in C++.

## Decision

Apply the 9 confirmed server fixes across `src/server/coa/`, `src/server/game/Spells/SpellMgr.cpp`, and pending world
migration `data/sql/updates/pending_db_world/rev_20261127_05_felsworn_extra_spells.sql`:

1. **D-1 & `Q-fs-ex-3` (`535602` *Fel Rift: Stonard*)**: Add `{535602, 40}` to `FelswornHordeCapitalRifts` in
   `AscensionCompat.cpp`, add `{535602, 9000150, 0, -10446.900000f, -3261.910000f, 21.084800f, 0.000000f, 4398}` to
   `FelswornRifts[]` in `AscensionFelswornData.h`, and insert `gameobject_template` `9000150`
   (`go_ascension_felsworn_rift`) in `rev_20261127_05_felsworn_extra_spells.sql`.
2. **D-2 (`704371` *Cripple* periodic decay)**: Bind `(704371, 'aura_ascension_felsworn_lifecycle')` in
   `spell_script_names` and handle `EFFECT_2` (`SPELL_AURA_PERIODIC_DUMMY`, `+8` every `2000 ms`) in
   `aura_ascension_felsworn_lifecycle::Tick` (`AscensionFelswornAuras.cpp`) to step `EFFECT_0`
   (`SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK`) and `EFFECT_1` (`SPELL_AURA_MOD_DECREASE_SPEED`) toward `0` on each 2 s
   tick (`-40% -> -32% -> -24% -> -16% -> -8% -> 0%`), even if the caster dies.
3. **D-3 (`803477` *Sunder* ATK Reducer duration)**: In `AscensionFelswornContracts.cpp`, assign `SpellDuration.dbc`
   row `18` (`20000 ms`, matching `$807428s3 = 20000`) when `!info->DurationEntry` so `803477` does not expire
   immediately at `0 ms`.
4. **D-4 (`500028`/`500422`/`500423` *Chaos Rush* dash while rooted)**: In `felsworn_casts::OnSpellBeforeEffects`
   (`AscensionFelswornAbilities.cpp`), remove `MECHANIC_ROOT` auras before `E1` triggers `802028`
   (`SPELL_EFFECT_JUMP_DEST`), so `802028` passes `Spell::CheckCast(true)` (`Spell.cpp:6814`) when cast while rooted.
5. **D-5 (`804758` *Betrayer's Inclinations* proc flags & guard)**: Widen `804758` `ProcFlags` in
   `AscensionFelswornContracts.cpp` to include ranged, negative magic spells, and periodic ticks, and guard
   `aura_ascension_felsworn_betrayers_inclinations::CheckProc` (`AscensionFelswornAuras.cpp`) against `804766`
   self-procs and non-damaging magic/periodic events.
6. **D-6 (Illidari vs Man'ari Intuition per-caster exclusivity)**: Add `(1154, 523478)` and `(1154, 523495)` to
   `spell_group` `1154` (`stack_rule = 2` `EXCLUSIVE_FROM_SAME_CASTER`) in `rev_20261127_05_felsworn_extra_spells.sql`,
   preserving cross-class groups `1078`/`1089`, `2110001`, and `2110004`.
7. **D-7 (`954534` *Enslave Elemental* 8 s PvP cap)**: Add `spellproto->SpellFamilyName == 20 && spellproto->Id == 954534`
   returning `8 * IN_MILLISECONDS` to `GetDiminishingReturnsLimitDuration` in `src/server/game/Spells/SpellMgr.cpp`.
8. **D-8 (`804052` *Eye of Archimonde* target cap) & `Q-fs-ex-1` (`523479..523483`, `523495`)**: Clamp
   `Effects[EFFECT_0].DieSides` to `1` for `523479..523483` and `523495`, and set `MaxAffectedTargets = 0` for both
   `523495` (uncapped raid buff matching `680308`) and `804052` (uncapped AoE reveal) in
   `AscensionFelswornContracts.cpp`.
9. **D-9 & `Q-fs-ex-4` (`712483` *Bane of Betrayal* visual stack off-by-one)**: In `felsworn_casts::OnSpellCast`
   (`AscensionFelswornAbilities.cpp`), set visual stack amount to
   `std::min<uint64>(aura->GetSpellInfo()->StackAmount, count + 1)` while keeping expiry damage `count * CalcValue`
   (`176 * count`).

## Consequences

- All 9 confirmed server defects are fixed with minimal scope, zero explanatory comments in `src/server/coa/`, and a
  single idempotent SQL migration (`rev_20261127_05_felsworn_extra_spells.sql`).
- `Q-fs-ex-2` (`552210..552213` `ManaPerSecond`), `Q-fs-ex-4` (`807554` Chaos copy), and `Q-fs-ex-5` (1 Pact per
  caster) remain untouched as ruled.
- Live runtime verification of these fixes against `coa-test-mysql` runs in Stage 2 after Sun Cleric finishes using the
  in-RAM MySQL instance.
