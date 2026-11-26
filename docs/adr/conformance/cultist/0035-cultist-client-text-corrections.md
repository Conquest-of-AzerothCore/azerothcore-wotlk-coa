# 0035. Cultist client tooltip corrections approved under owner ruling O-18

- Status: accepted (owner ruling Cultist O-18, 2026-11-25, "go global")
- Date: 2026-11-25

## Context

During the Cultist (class 25) conformance pass, ten client tooltip discrepancies were established against server
behaviour and archived live evidence (`ev1.md`, `ev2.md`): nine server-kept rulings recorded in
[Cultist ADR 0033](0033-owner-rulings-server-kept-client-text-updated.md) (`Q-cu-3`, `Q-cu-4`, `Q-cu-9`, `Q-cu-15`,
`Q-cu-20`, `Q-cu-21`, `Q-cu-22`, `Q-cu-25`, `Q-cu-26`) plus the buff tooltip alignment for Twisted Seal `525065`
whose Cultist-scoped melee-deflect fix is recorded in
[Cultist ADR 0020](0020-twisted-seal-deflects-melee-abilities.md) (`Q-cu-16`). Four other server-kept rulings kept
their existing client texts without change ([Cultist ADR 0031](0031-void-touched-keeps-one-stack-after-gaze-of-cthun.md),
[Cultist ADR 0032](0032-owner-rulings-server-kept-no-client-text-change.md)).

On 2026-11-25, the project owner approved all ten proposed client text updates under ruling `O-18` ("go global"). Each
current string was re-verified verbatim against `/srv/coa/server-data/dbc/Spell.dbc` (sha256
`4e4ed9ba1c2e10089b543182da6836b2298fdeafd61f8602dc25f79fe5facfa7`) and against existing `coa_client_spell_description`
SQL updates (none of the 18 target spell IDs had a prior override).

## Decision

Apply all ten owner-approved client text corrections (18 rows: 9 single-rank spells plus all 9 player ranks of
Darkwither) in `data/sql/updates/pending_db_world/rev_20261125_01_cultist_client_texts.sql` (commit `81bd2567f2`),
using an idempotent `DELETE` + `INSERT` on `coa_client_spell_description` (`ID`, `Description`, `ToolTip`). SQL changes
are explicitly authorized by owner ruling `O-18` strictly for these rows.

- For the nine `Description`-only updates, `ToolTip` is `NULL` so `AscensionCompat::BuildSpellPatchRows()`,
  `conformance/streamed.py`, and `apps/coa-dbc/client_dbc.py drift` preserve the client's existing `ToolTip[enUS]`.
- For Twisted Seal `525065` (`ToolTip`-only update on a spell with a non-empty `Description`), `Description` carries
  the exact verbatim `Spell.dbc` string so `BuildSpellPatchRows()` does not blank the spellbook description, matching
  the Templar precedent ([ADR 0105](../../0105-templar-client-texts-restated-from-the-server.md)).

### The ten approved changes

1. **`Q-cu-15` — Dark Matter (`806382`, `Description[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: `$807219d` (`10 sec`) -> `$804275d` (`6 sec`, Satiate `DurationIndex = 32 = 6000 ms`).
   - Server fact & live evidence: `AscensionCultistAuras.cpp:195-198,233-241` removes driver aura `807124` as soon as
     the 6 s Satiate `804275` channel ends. Live logs (`ev1.md`, strong): 9 logs, 3 players, 32 sessions, max
     `6.009 s` / 6 ticks, 0 sessions `> 6.01 s`.
2. **`Q-cu-20` — Horrific Revelation (`704473`, `Description[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: drop `", scaling with |cffcfa6ffInsanity|r,"` (`for ${$m1+0+$SP*0.678496} and increases...`). Embedded
     automatically via `@s:704473:0@` in Horrific Revelations `524877` and Hand of Yogg-Saron `704476`.
   - Server fact & live evidence: `AscensionCultistAuras.cpp:230` casts `704473` with `0.678496 * SP` only and 0%
     Insanity scaling (`cultist.json` `524877 no_insanity_scaling` ratio `1.00 +- 0.02` between 0 and 80 Insanity).
     Live logs (`ev1.md`, suggestive): 2 logs, 1 player, flat non-crit heals (`698-702` and `829-834`) across 60-100
     Insanity.
3. **`Q-cu-21` — Embrace the Void (`300307`, `Description[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: `"your damage dealt"` -> `"your Magic damage dealt"`.
   - Server fact & live evidence: `573285` `Effect[0]` (`aura 79`, `bp = 9 + 1 = +10%`, `EffectMiscValue[0] = 126`)
     boosts Magic schools only and excludes Physical melee (`cultist.json` `shadow_damage` `+10%`, `melee_damage`
     `+0%`). Live logs (`ev1.md`, suggestive): 1 log, 1 player, Shadow `1.095-1.106x` vs Physical melee `1.020x`.
4. **`Q-cu-22` — Psychic Suppression (`800432`, `Description[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: `"more spell damage"` -> `"more damage"`.
   - Server fact & live evidence: `803746` `Effect[0]` (`aura 87`, `bp = 14 + 1 = +15%`, `EffectMiscValue[0] = 127`)
     amplifies all schools including Physical (`cultist.json` `spell_amp` `+15%`, `phys_control` `+15%`). Live logs
     (`ev1.md`, strong): 2 logs, 9 boss windows, Physical hits `1.142-1.164x`.
5. **`Q-cu-25` — Madness (`804369`, `Description[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: remove `$?s805606[...][]` conditional guard so `" or |cFFFFFFFFObliteration Beam|r"` always shows. Embedded
     automatically via `@s:804369:0@` in Glimpse of Madness `500719` (R1), `500767` (R2), and unused Vision of Doom
     `500732`.
   - Server fact & live evidence: `804369` `Effect[0]` (`EffectSpellClassMask[0] = 131072`) boosts Obliteration Beam
     `805573` unconditionally by `+3%`/stack without `805606`. Live logs (`ev2.md`, strong): 4 logs, 3 players, 16
     same-cast checks `+2.82%` to `+3.11%`/stack with 0 `805606`/`706725` events in 186 logs.
6. **`Q-cu-26` — Darkwither (`800446`, `502213`-`502220`, all 9 ranks, `Description[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: `$?s301317[8][$706913u]` -> `$?s301317[7][$706913u]` on all 9 player ranks (`SkillLine 89`).
   - Server fact & live evidence: Withered `706913` (`StackAmount = 4`) + Call of C'Thun `301317`
     (`SPELLMOD_MAX_AURA_STACKS = +3`) caps at 7 stacks. Live logs (`ev2.md`, strong): 5 logs, 4 players, 740 doses:
     11 at stack 7, 30 refreshes at stack 7, 0 at stack 8.
7. **`Q-cu-4` — Malignant Armor (`680569`, `Description[enUS]`, approved 2026-11-25, `O-12` / `O-18`):**
   - Change: `"${($m1*$m2)*2}"` -> `"100"` (`"Increases your attack power by 2 for every 100 armor value you have."`).
   - Server fact & live evidence: `680569` `Effect[0]` (`aura 285`, `bp = 49 + 1 = 50`, `StatSystem.cpp:660-663`)
     grants `int32(GetArmor() / 50)` = 1 AP per 50 armor = 2 AP per 100 armor (`+3` AP at 182 armor, `+103` AP at 5182
     armor). `Effect[1]` is empty so `$m2` rendered `0` in-client; live archive video (`ev2.md`, `t=12:08`) displayed
     `"2 for every 100 armor value you have"`.
8. **`Q-cu-9` — Void Strength (`805121`, `Description[enUS]`, approved 2026-11-25, `O-12` / `O-18`):**
   - Change: `"spell hit chance"` -> `"spell hit rating"`. Also embedded via `@s:805121:0@` in `806943`.
   - Server fact & live evidence: `805121` `Effect[0]` (`aura 220`, `MiscValue = 128` `CR_HIT_SPELL`, `bp = 4 + 1 = 5%`)
     adds spell hit rating (`+20` rating at 408 Strength). Live logs (`ev2.md`): 0 events (passive); `spell.csv.gz`
     carries the same `aura = 220, misc_value = 128`.
9. **`Q-cu-16` — Twisted Seal (`525065`, `ToolTip[enUS]`, approved 2026-11-25, `O-15` / `O-18`):**
   - Change: `"Deflecting spells."` -> `"Deflecting spells and abilities."` (`Description[enUS]` kept verbatim).
   - Server fact & live evidence: Aligns the buff tooltip with `525065`'s own spellbook description (`"deflecting all
     spells and abilities"`) and the Cultist melee-deflect fix ([Cultist ADR 0020](0020-twisted-seal-deflects-melee-abilities.md)).
     Live logs (`ev1.md`): 0 events; archive video matches `"all spells and abilities"`.
10. **`Q-cu-3` — Mind Rot (`300300`, `Description[enUS]`, approved 2026-11-25, `O-12` / `O-18`):**
    - Change: `"to curse your target, applying |cffffffffMind Rot|r."` -> `"to afflict your target with |cffffffffMind Rot|r."`
      (preserving `@s:560714:0@`).
    - Server fact & live evidence: Mind Rot debuff `560943` has `Dispel = 1` (`Magic`) in `Spell.dbc` and `spell.csv.gz`
      (`ev2.md`: 0 live events/dispels), proven Magic-dispellable by `300300 dispel_crit` (Dispel Magic `988`).

## Consequences

- `apps/coa-gameplay-test/conformance/streamed.py` reads the eighteen rows from `rev_20261125_01_cultist_client_texts.sql`,
  so `conformance.py generate --class 25` now derives expectations from the O-18 texts (`806382` `$804275d = 6000 ms`,
  `680569` literal `100`, embedded `704473` and `804369` expanded cleanly).
- `apps/coa-gameplay-test/conformance/classes/cultist.json` updates quotes and `observe_source` notes for the affected
  entries to match the delivered streamed texts.
- `apps/coa-gameplay-test/conformance/classes/cultist_clauses.json` records `text_source` (`basis: "owner_ruling"`,
  commit `81bd2567f2`) on every row of the streamed and embedded spells and preserves the original DBC words in
  `dbc_clause` on every changed clause ([ADR 0192](../../0192-the-tooltip-reader-prefers-the-streamed-client-text.md),
  [ADR 0198](../../0198-guard-streamed-text-provenance-and-integer-share-readings.md)).
  - Void Strength `805121` row 399 (`"and your spell hit rating by $s1% of your Strength."`) now matches
    `STATE_PROMISES['combat_rating']` and promoted from `data` to `behaviour` on counted pair `20261125-125441` /
    `20261125-125523` (build `8226f75b3bae`, `62` scenarios, `66/66 ok/ok`, `0` flips, `0` alerts, `24/25` rows
    `behaviour`, `680569` row 239 `claims[0]` staying `data` due to `STATE_PROMISES['attack_power']` matching `claims[1]`).
  - Horrific Revelations `524877` row 152 drops the removed `"scaling with Insanity"` sub-claim while keeping
    `524877 behaviour_metric_delta no_insanity_scaling` linked alongside `crit_buff`.
- `apps/coa-gameplay-test/scenarios/cultist-ruling-client-texts.json` verified (run `20261125-125207`, build
  `8226f75b3bae`, 43/43 steps passed) that the worldserver updater applies
  `rev_20261125_01_cultist_client_texts.sql` and streams all eighteen updated rows (and none of the replaced phrases)
  while preserving `525065` `Description` and untouched DBC `ToolTip` fields.
- Static client data ([docs/coa/client-data.md](../../../coa/client-data.md),
  [ADR 1012](../../1012-static-client-data-ships-in-the-client-mpqs.md)): the same eighteen strings must be baked into
  `patch-ZG.MPQ` (`Spell.dbc`), verified with `apps/coa-dbc/client_dbc.py drift`, and visually verified in the real
  game client ("client lab") as a separate deployment/client-lab step outside this worktree.
