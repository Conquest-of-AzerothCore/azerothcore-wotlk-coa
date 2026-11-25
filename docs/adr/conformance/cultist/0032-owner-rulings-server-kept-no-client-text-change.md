# 0032. Owner rulings Q-cu-5, Q-cu-8, Q-cu-17, Q-cu-35: server behaviour kept without client text changes

- Status: accepted (owner rulings O-12 2026-11-24, O-15 2026-11-25, O-17 2026-11-25)
- Date: 2026-11-25

## Context

During the Cultist (class 25) conformance pass, five owner questions resulted in keeping existing server behaviour
without changing client tooltip text. One of them (`Q-cu-12` / `O-17`, Void-Touched `300286` re-applying 1 stack after
Gaze of C'Thun) is recorded in [Cultist ADR 0031](0031-void-touched-keeps-one-stack-after-gaze-of-cthun.md). This ADR
records the remaining four server-kept, no-client-text-change rulings together with the archived live evidence
(`ev1.md`, `ev2.md`) and their conformance consequences.

### 1. `Q-cu-5` (`O-12`, 2026-11-24) — Void Augmentation (`680575`, ledger row 245)

- **Tooltip (`Spell.dbc`, matching `rev_20261007_58_void_augmentation_tooltip.sql`):**
  `"While Dreadnought is active, your Twilight Shieldtoss has a $/1000;s1 sec reduced cooldown. In addition, your Eldritch Shock now strikes 2 additional enemies near the primary target."`
- **Issue:** The 2026-09-01 tooltip archive video (`q742IyqxrV0.csv` `t=12:46`) displayed `"Twilight Shock"` instead of
  `"Eldritch Shock"`.
- **Live evidence (`ev2.md`, strength: none):** `NO LIVE EVIDENCE` — `Twilight Shock` has 0 events across 186 combat
  logs; `Eldritch Shock` (`808036`–`808052`) has 218 damage and 17 heal hits in 12 logs, but 0 casts overlapped with
  Dreadnought (`567524`/`567548`–`567552`).
- **Owner's choice (`O-12`):** `keep` `"Eldritch Shock"`; the archive video reading is recorded as an observation only.

### 2. `Q-cu-8` (`O-12`, 2026-11-24) — Protection From Light (`704434`, ledger row 278)

- **Tooltip (`Spell.dbc`):**
  `"Reduces all damage taken by party and raid members by $s1%.\r\n\r\nIn addition, your Holy damage taken is reduced by $s2%."`
  (`$s1 = 3`, `$s2 = 10`).
- **Issue:** `704434` carries `Effect[0] = APPLY_AREA_AURA_RAID` (`aura 87`, `-3%` all schools) and
  `Effect[1] = APPLY_AURA` (`aura 87`, `-10%` Holy) in SQL `spell_group 2000185` (`stack_rule = 3`), so a Holy hit on
  the caster (`41394`, 1100 Holy) took `-10.0%` (`990/1100 = 0.90`) rather than multiplicative `-3%` and `-10%`
  (`0.97 * 0.90 = 0.873`).
- **Live evidence (strength: none / tooltip-punctuation ruling):** `NO LIVE EVIDENCE` — `coa-history` recorded 0 events
  (passive) across 186 combat logs; settled from the tooltip sentence structure and the direct server measurement
  (`-3.07%` Physical, `-10.0%` Holy).
- **Owner's choice (`O-12`):** `keep` `-10%` on Holy (`0.90`), no server change and no client text change. A new
  sentence beginning `"In addition"` states a distinct effect rather than numeric stacking onto the previous sentence.

### 3. `Q-cu-17` (`O-17`, 2026-11-25) — Eldritch Devastation (`803398`, ledger row 370 claim 3)

- **Tooltip (`Spell.dbc`):**
  `"Channel upon an enemy, chaining to nearby enemies, dealing ${($d*1000/$t1)*($m1+0+$sps*0.44)} Shadow damage over $d, dealing less damage with each enemy struck."`
- **Issue:** `803398` sets `EffectDamageMultiplier[0] = 0.90` on a periodic aura effect (`Effect[0] = APPLY_AURA`,
  `SPELL_AURA_PERIODIC_DAMAGE`), but shared core `Spell.cpp:1934-1940,8655-8659` applies `m_damageMultipliers` only to
  direct `m_damage`, never periodic aura ticks. Chained targets therefore take `1.00x` full damage rather than `0.90x`.
- **Live evidence (`ev1.md`, strength: strong):** `LIVE SHOWS` no chain damage decay — across 4 non-duplicate logs
  (`99, 103, 104, 141`) and 3 players (`Xarathun`, `Nastylol`, `Devzou`), 594 clean non-crit adjacent-target ratios in
  the same tick show median `0.9830` and mode `1.00` (`356/594`, `59.9%`), agreeing with the server.
- **Owner's choice (`O-17`):** `leave` ("on colle au live") — keep full periodic damage on every chained target, no
  server change and no client text change (kept deviation from literal `"dealing less damage with each enemy struck"`).

### 4. `Q-cu-35` (`O-15`, 2026-11-25) — Hallucination (`560301`, ledger row 179 claim 3)

- **Tooltip (`Spell.dbc`):**
  `"Create 3 copies of yourself that run in a random direction for $706932d and may briefly trick enemies into ignoring you. Significantly reduces your threat and removes all movement impairing effects from you."`
- **Issue:** Hallucination spawns 3 wandering copies (`840025`, `AscensionCultistSummons.cpp:278-283`) and clears the
  caster's threat (`player->GetThreatMgr().RemoveMeFromThreatLists()`, `AscensionCultistAbilities.cpp:448`), without a
  separate taunt/distraction mechanic on the copies themselves.
- **Live evidence (`ev2.md`, strength: none for separate copy distraction):** `NO LIVE EVIDENCE` for a separate copy
  taunt/distraction — 36 casts across 11 logs and 11 players confirm the 1 s buff, snare removal, and incoming hits
  dropping to 0 on 7 of 8 attacked casts, with 0 `SPELL_SUMMON` or copy events logged.
- **Owner's choice (`O-15`):** `covered_by_threat` — the server's threat wipe covers
  `"and may briefly trick enemies into ignoring you."`, with no server change and no client text change.

## Options

- Keep the current server behaviour and existing client tooltip texts for all four spells, recording each kept
  deviation/interpretation as Status 2 (*Conformant by a recorded rule or owner ruling*, `docs/coa/class-conformance.md`
  §2) and guarding each measurable server behaviour in `classes/cultist.json`. Chosen per owner rulings `O-12`, `O-15`,
  and `O-17`.
- Alter server code or client tooltip text to enforce literal stacking (`704434`), periodic chain falloff (`803398`),
  copy taunt (`560301`), or `"Twilight Shock"` (`680575`). Rejected by owner rulings `O-12`, `O-15`, and `O-17`.

## Decision

No server C++, SQL, or client DBC text changes are made for `Q-cu-5`, `Q-cu-8`, `Q-cu-17`, or `Q-cu-35`. All four are
recorded as Status 2 (*Conformant by a recorded rule or owner ruling*) and guarded by runtime behaviour proofs matching
the accepted server behaviour.

## Consequences

- `apps/coa-gameplay-test/conformance/classes/cultist.json`:
  - `704434 taken_hit holy_taken`: expects `0.9` (`-10%` Holy damage taken) instead of `0.873`, citing `O-12` `Q-cu-8`
    and Cultist ADR 0032.
  - `803398 metric_delta chain_falloff`: expects `same_arm_ratio` `1.0 +- 0.03` (excluding `0.90`) for `area1 / dummy`,
    citing `O-17` `Q-cu-17` and Cultist ADR 0032.
  - `680575 shock_cleave` and `560301 threat_reduce` / `threat_reduce_control` already prove the kept server behaviours
    for `Q-cu-5` and `Q-cu-35`.
- `apps/coa-gameplay-test/conformance/classes/cultist_clauses.json`:
  - Rows `245` (`680575`), `278` (`704434`), `370` (`803398` claim 3), and `179` (`560301` claim 3) record Status 2
    (*Conformant by a recorded rule or owner ruling*) with their card ids, ruling dates, live-evidence summaries, and
    reference to Cultist ADR 0032.
- All four behaviours remain verified by counted gameplay pairs (`704434 holy_taken` and `803398 chain_falloff` re-proved
  in `cu-b4`; `680575 shock_cleave` and `560301 threat_reduce`/`threat_reduce_control` already proved and re-verified at
  class end).
