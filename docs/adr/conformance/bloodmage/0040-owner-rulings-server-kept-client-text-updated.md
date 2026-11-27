# 0040. Owner rulings Q-bm-1, Q-bm-2, Q-bm-4, Q-bm-11, and Q-bm-12: server behaviour kept with updated client texts

- Status: accepted (owner rulings Bloodmage Q-bm-1, Q-bm-2, Q-bm-4, Q-bm-11, Q-bm-12 / O-10, 2026-11-26)
- Date: 2026-11-26

## Context

Five Bloodmage (class 20) conformance questions kept existing server mechanics unchanged and approved
updating client tooltip texts via `coa_client_spell_description` and candidate `Spell.dbc`:

1. **`Q-bm-1` (`500126` Lunge — `keep_edit_text`):**
   - Server keeps `109..113` Physical damage (`BasePoints 25, DieSides 5, BaseLevel=SpellLevel=8,
     RealPointsPerLevel 1.6`, `0` AP scaling).
   - Client removes stale `$804866` and `+$AP*0.2`: `"dealing ${$m2+$ppl2} Physical Damage"`.
2. **`Q-bm-2` (`800781, 501623, 501624, 503611, 503612, 572575` Dark Liturgy — `keep_edit_text`):**
   - Server keeps `10–11` unique friendly targets (`TargetA 21 + TargetB 31 MaxAffectedTargets=10`) with
     `0%` per-bounce healing decay (`Spell::EffectHeal` ignores `EffectDamageMultiplier[0]`).
   - Client removes `", healing for less for each target struck"`.
3. **`Q-bm-4` (`803392` Hematoma embedded in `524865` Final Embrace — `keep_zero_edit_text`):**
   - Server keeps `0` Rage generated from Hematoma ticks (`9,036` live ticks in archived logs).
   - Client removes `" Generates Rage based on damage dealt."`.
4. **`Q-bm-11` (`681792` Cursed Blood — `keep_120_edit_text`):**
   - Server keeps `1.20x` total damage dealt on Bloodbolt, Bloodmoon Blast, and Crimson Tide without
     double-dipping SP scaling (`+20%` flat via `SPELLMOD_DAMAGE` / `SPELLMOD_DOT`).
   - Client removes `" and spell power scaling"`.
5. **`Q-bm-12` (`704115` Clotting — `keep_60_edit_704115`):**
   - Server keeps `+0.6 * AP` (`rev_20261010_91_bloodmage_coefficients.sql`) matching Aortic Assault
     (`806212, 807780..807785`).
   - Client updates `+$AP*0.5` to `+$AP*0.6`.

## Options

- Stream all affected ranks through `data/sql/updates/pending_db_world/rev_20261127_04_bloodmage_client_texts.sql`,
  mirror them into `apps/coa-spells/bloodmage_tooltips.py`, add opt-in `[at_least, at_most]` cap bounds in
  `kinds/heal_sum.py` for Dark Liturgy `572575 bounce_cap` (`[180, 198]`), and align `classes/bloodmage.json`
  and `classes/bloodmage_clauses.json` (`basis: "owner_ruling"` with preserved `dbc_clause`). Chosen.
- Alter server mechanics to add unlogged Lunge AP scaling, bounce decay, Hematoma Rage, SP double-dipping,
  or lower Clotting AP scaling. Rejected by `O-10`.

## Decision

Keep server mechanics as implemented for `Q-bm-1`, `Q-bm-2`, `Q-bm-4`, `Q-bm-11`, and `Q-bm-12`; ship the
streamed SQL text updates in `rev_20261127_04_bloodmage_client_texts.sql` and update conformance
expectations in `classes/bloodmage.json` and `classes/bloodmage_clauses.json`.

## Consequences

- `500126`, `572575`, `524865` (Hematoma), `681792`, and `704115` runtime checks prove exact conformance
  to the approved server behaviour and updated client texts.
- Finished classes (`templar`, `necromancer`) remain untouched because `heal_sum.py`'s `at_least`/`at_most`
  cap range is strictly opt-in.
