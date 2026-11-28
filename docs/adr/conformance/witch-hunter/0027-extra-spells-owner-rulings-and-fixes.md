# 0027. Witch Hunter extra-spell defects and owner rulings

- Status: accepted
- Date: 2026-11-27
- Rulings: Witch Hunter extra-spell catch-up (`Q-wh-ex-1` through `Q-wh-ex-8`)

## Context

Phase 1 triage of Witch Hunter's 37 unaccounted baseline/taught `extra_spells` (class 15, level 60) confirmed five
server defects and resolved eight owner rulings (`Q-wh-ex-1..8`):

1. **`680230` *Saber Slash (Fire)* (`Q-wh-ex-1`, Defect D-1)**: `Spell.dbc` retained two unlisted triggers (`Effect[1]`
   -> `802842` *Fiery Judgement* Fire damage, `Effect[2]` -> `802007` *Wrangler's Net* 5-second root) and a flat
   bonus (`Effect[0]` `BasePoints = 1`, `DieSides = 1`, `RealPointsPerLevel = 0.2f` -> `+13` flat Fire damage at L60),
   contradicting the tooltip `"Slashes an enemy for Weapon Damage and generates 10 Rage"`. Owner ruling `Q-wh-ex-1`:
   keep `680230` as Inquisition's L10 generator, disable `E1`/`E2`, and zero `E0` so it deals pure Weapon Damage and
   grants `10` Rage via `500179`.
2. **`523510` *Greater Knight's Edict* (Settled Defect D-2)**: `Spell.dbc` carried `MaxAffectedTargets = 10` (copied
   from single-target `523485`), truncating 20/40-player raids despite `"all party and raid members"`.
3. **`680303` *Greater Inquisitor's Edict* and `681442` *Greater Witching Edict* (`Q-wh-ex-3`, Defect D-3)**: Unlike
   sibling `523510` (`rev_20261023_10_greater_knights_edict_players_only.sql`, `#4733`), neither `680303` nor `681442`
   was bound to `spell_ascension_witch_hunter_greater_knights_edict`, so their `TARGET_UNIT_CASTER_AREA_RAID` auras
   still landed on pets/Shadowhounds. Owner ruling `Q-wh-ex-3`: bind both to the player-only filter.
4. **`807733` *Night's Watch* (Settled Defect)**: `Effect[0]` (`+210%` threat, `MiscValue = 127` all schools)
   overlapped a stale `Effect[2]` (`SPELL_AURA_MOD_THREAT`, `BasePoints = 74`, `RealPointsPerLevel = 0.5f`,
   `MiscValue = 125` all schools except Holy), multiplying non-Holy threat to `3.10 * 1.98 = 6.138x` (`12.276x` with
   the `2.0x` tank stance factor) instead of `3.10x` (`6.20x`).
5. **`802281` *Infiltrate* (Settled Defect)**: `witch_hunter_state::IfNormalReaction`
   (`src/server/coa/AscensionWitchHunterDefenses.cpp:430-443`) unconditionally forced `REP_NEUTRAL` for every
   non-player-controlled creature, downgrading friendly NPCs (vendors, quest givers, guards) to neutral instead of
   affecting only aggressive/hostile creatures.
6. **`807683` *Brand of the Damned* (`Q-wh-ex-7`)**: `807683` is a Twilight (`SchoolMask = 34 = Holy | Shadow`) spell,
   but `AscensionWitchHunterCoefficients.h:134` read `school = 32` (Shadow SP only) instead of `34`
   (`max(Holy, Shadow)`). The client tooltip and server both compute `1046..1048 + AP + SP` on `807710`, so
   `807682..807710` are NOT added to `WitchUnscaledByLevelEffects`.
7. **`523485` *Knight's Edict* (R1–R4) and `523510` *Greater Knight's Edict* (Live-verification Defect)**: Live gameplay
   verification (`523488`/`523510` `no_stack_motw`) proved both stacked with *Mark of the Wild* (`9885`, armor
   `582 -> 891`, Strength `67 -> 79`), contradicting *"Does not stack with Mark of the Wild"*. Mark of the Wild R1
   (`1126`) belongs to subgroup `1078` under group `1089` (`stack_rule = 4`, `SPELL_GROUP_STACK_RULE_EXCLUSIVE_HIGHEST`),
   whereas `523485` and `523510` were omitted from group `1089` (and placing them inside `1078` would cause
   `SpellMgr::CheckSpellGroupStackRules` to skip parent group `1089`).
8. **Confirmed no-code rulings**: `Q-wh-ex-2` (`503679` Caltrops single owner `504447` hit), `Q-wh-ex-4` (`802308`
   melee+ranged haste), `Q-wh-ex-5` (`802826` stun + `-200%` healing), `Q-wh-ex-6` (`681457` Undead/Demon filter), and
   `Q-wh-ex-8` (`804191`/`680269` obsolete `$?s500056` conditional) match the intended server behaviour with no C++
   changes.

## Decision

1. **`src/server/coa/AscensionWitchHunterCompletion.cpp` (`ApplyContracts`)**:
   - On `680230`: set `Effects[EFFECT_0].BasePoints = 0`, `DieSides = 0`, `RealPointsPerLevel = 0.0f` (`CalcValue() ==
     0`), disable `Effects[EFFECT_1]` when `TriggerSpell == 802842`, and disable `Effects[EFFECT_2]` when
     `TriggerSpell == 802007`.
   - On `523510`: set `MaxAffectedTargets = 0`.
   - On `807733`: disable `Effects[EFFECT_2]` when `ApplyAuraName == SPELL_AURA_MOD_THREAT`, `BasePoints == 74`,
     `RealPointsPerLevel == 0.5f`, and `MiscValue == 125`, leaving `EFFECT_0` (`+210%` threat all schools) and
     `EFFECT_1` (25% physical stagger) intact.
2. **`src/server/coa/AscensionWitchHunterDefenses.cpp` (`IfNormalReaction`)**:
   - Gate the `REP_NEUTRAL` override on `unit->GetFactionReactionTo(unit->GetFactionTemplateEntry(), target) <
     REP_NEUTRAL` (which does not recurse into `IfNormalReaction`), leaving friendly and neutral NPCs untouched.
3. **`src/server/coa/AscensionWitchHunterCoefficients.h`**:
   - Change `807683` `school` from `32` to `34` so `witch_hunter_scaling::ModifySpellEffectBaseValue` applies
     `max(Holy, Shadow)` spell power.
4. **`data/sql/updates/pending_db_world/rev_20261127_06_witch_hunter_extra_spells.sql`**:
   - Bind `spell_ascension_witch_hunter_greater_knights_edict` to `680303` and `681442` (`DELETE` + `INSERT` in
     `spell_script_names`).
   - Add `523485` and `523510` directly to `spell_group 1089` (`DELETE` + `INSERT`) so *Knight's Edict* (all ranks via
     `spell_ranks`) and *Greater Knight's Edict* obey `SPELL_GROUP_STACK_RULE_EXCLUSIVE_HIGHEST (4)` against *Mark of
     the Wild* (`1126` in subgroup `1078` of `1089`).
5. **`src/test/server/coa/WitchHunterExtraContractsTest.cpp`**:
   - Add offline Google Test regressions verifying `ApplyContracts` for `680230`, `523510`, and `807733` (including a
     guard test for unexpected `E2`), plus the `807683` twilight school mask in `WitchCoefficients`.

## Consequences

- `680230` deals pure normalized Weapon Damage and grants `10` Rage via `500179` without unlisted Fire procs or 5s
  roots; `#7194`/`#8923` remains intact.
- `523510`, `680303`, and `681442` all buff players raid-wide without target caps or pet bleed.
- `807733` produces `3.10x` (`6.20x` with tank stance) threat across every spell school while preserving 25% Physical
  monster stagger.
- `802281` neutralizes hostile/unfriendly creatures without downgrading friendly NPCs.
- `807683` scales with `max(Holy, Shadow)` spell power.
- Pending SQL requires maintainer `sql-change-authorized` review when the branch is opened as a PR.
