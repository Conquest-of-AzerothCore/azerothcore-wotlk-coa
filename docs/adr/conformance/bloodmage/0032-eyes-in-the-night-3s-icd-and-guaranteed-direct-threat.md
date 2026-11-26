# 0032. Owner ruling Q-bm-14: Eyes In The Night uses a 3 sec ICD and generates direct threat

- Status: accepted (owner ruling Bloodmage Q-bm-14 / O-10, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Eyes In The Night `801959` (confirmed matching 2026-09-01 client archive `q742IyqxrV0.csv` `t=11:22`): "Allies within $806723a1 yds are protected by |cffffffffShadow Colony|r, giving them a $801959h% chance to trigger a |cffffffffCall of the Darkwing|r when they take direct damage. Can only occur once every 3 sec. If allies have less health than you when this occurs, generate a large amount of threat against the enemy that triggered it."

Two defects existed:
1. `data/sql/updates/pending_db_world/rev_20261025_03_coa_eyes_in_the_night_proc.sql` set `spell_proc.Cooldown = 5000` on `806723` (matching legacy 5 sec text on hidden buff `806723`), causing conformance check `801959 icd_3s_alert` to alert (`1` proc at `3506 ms` vs expected `2`).
2. `aura_ascension_bloodmage_shadow_colony::RedirectThreat` (`src/server/coa/AscensionBloodmageSecondary.cpp`) only transferred `50%` of `enemy->GetThreatMgr().GetThreat(ally)` and returned early when `amount <= 0.0f`. When an injured ally had `0` threat on `enemy`, `0` threat was generated on the Bloodmage, causing `801959 threat_zero_ally_alert` (`bloodmage.json [1060]`) to alert.

The owner ruled (`Q-bm-14` / `O-10`, 2026-11-26): `fix_3s_direct_threat` — align the internal cooldown to `3000 ms` and generate guaranteed direct threat even when the low-HP ally has `0` threat.

## Options

- Supersede `806723`'s `spell_proc` row in `data/sql/updates/pending_db_world/rev_20261127_03_bloodmage_secondary_procs.sql` keeping every field from `rev_20261025_03_coa_eyes_in_the_night_proc.sql` except `Cooldown = 3000`, and update `RedirectThreat` in `AscensionBloodmageSecondary.cpp` to always compute baseline direct threat `float(bloodmage->GetLevel()) * 10.0f` (`600.0f` at level 60) plus `50%` of any positive ally threat (also applying `-50%` to the ally). Chosen: satisfies the tooltip's direct threat generation when ally threat is `0` while preserving threat redirection when ally threat is positive.
- Replace threat redirection entirely with a fixed flat value. Rejected: loses existing threat relief for injured allies who already hold threat.

## Decision

1. In `src/server/coa/AscensionBloodmageSecondary.cpp` (`aura_ascension_bloodmage_shadow_colony::RedirectThreat`), compute `float threat = float(bloodmage->GetLevel()) * 10.0f;`, add `allyThreat * 0.5f` and call `enemy->GetThreatMgr().ModifyThreatByPercent(ally, -50)` when `allyThreat > 0.0f`, then always call `enemy->GetThreatMgr().AddThreat(bloodmage, threat, GetSpellInfo(), true, true);`.
2. In `data/sql/updates/pending_db_world/rev_20261127_03_bloodmage_secondary_procs.sql`, replace `spell_proc` for `SpellId = 806723` with `Cooldown = 3000` (all other columns identical to `rev_20261025_03_coa_eyes_in_the_night_proc.sql`).

## Consequences

- `806723` Shadow Colony reopens after `3000 ms` (still blocked at `2500 ms`) and generates at least `10 * level` direct threat (`600.0f` at level 60) on the attacking enemy whenever an ally with lower health percentage triggers it, plus `50%` threat transfer when the ally holds positive threat.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `801959 icd_3s_alert`, `801959 icd_2500ms_blocked` (`[1059]`), `801959 icd_5s_confirm`, and `801959 threat_zero_ally_alert` (`[1060]`).
