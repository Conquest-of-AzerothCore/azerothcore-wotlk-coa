# 0039. Owner rulings Q-bm-7 and Q-bm-18: server behaviour kept without client text changes

- Status: accepted (owner rulings Bloodmage Q-bm-7 / O-10, Q-bm-18 / O-10, 2026-11-26)
- Date: 2026-11-26

## Context

During the Bloodmage (class 20) conformance pass, two owner questions resolved to keeping current server
behaviour and leaving existing client tooltip text untouched:

1. **`Q-bm-7` (`801563, 801564, 803581..803585` Vampyr Bite, ledger row 420):**
   - Tooltip (`Spell.dbc`): `"Brings a dead player back to life with $s1% health and mana."` (`$s1 = 820` on
     `803585`).
   - `Spell::EffectResurrect` (`SpellEffects.cpp:5735-5736`) passes `820%` and `Player::ResurrectPlayer`
     clamps restored health and mana to `100%` of maximum pools. Meanwhile `803585` `Effect[2]` (healing-taken
     buff) separately received `AURA_INTERRUPT_FLAG_TAKE_DAMAGE` ([Bloodmage ADR 0022](0022-blood-trails-clotting-vampyr-bite-acuity-and-animated-blood.md)).
   - Owner choice (`Q-bm-7` / `O-10`): **`leave`** — keep `100%` pool clamping on the server and keep
     `"$s1%"` (`"820%"`) in `Spell.dbc` and the streamed client text (explicitly excluded from
     `rev_20261127_04_bloodmage_client_texts.sql` and `apps/coa-spells/bloodmage_tooltips.py`).
2. **`Q-bm-18` (`704646` Swarm of Flies):**
   - Keeps the already-merged `#13799` fix (`SpellEffects.cpp` `EffectAscensionRefreshAura` walking
     `spell_ranks` so Bloodbolt `578305` refreshes level-60 Taldaram's Torment `802580` from rank-1
     `MiscValue = 800772`) without altering tooltip text.

## Options

- Leave client text untouched (`803581..803585` excluded from `coa_client_spell_description` and candidate
  `patch-ZG.MPQ`), add opt-in `clamp_percent: true` to `kinds/peaceful_resurrect.py` (default `False` so
  finished-class scenarios remain byte-identical), and record `Q-bm-7 = 'leave'` as Status 2 on
  `bloodmage_clauses.json` row 420. Chosen: honours the owner ruling directly while proving exact `100%`
  clamped restoration and zero side effects on finished classes.
- Leave `803585 peaceful` alerting on unclamped `820%`, or rewrite `Spell.dbc` / SQL text. Rejected: either
  leaves an approved Status 2 check permanently alerting or overrides the owner's explicit `leave` ruling.

## Decision

1. Do not add `803581..803585` to `rev_20261127_04_bloodmage_client_texts.sql` or `bloodmage_tooltips.py`
   (guarded explicitly in `apps/coa-gameplay-test/scenarios/bloodmage-ruling-client-texts.json` and
   `apps/coa-spells/bloodmage_tooltips.py`).
2. Add opt-in `clamp_percent: bool = False` in `apps/coa-gameplay-test/conformance/kinds/peaceful_resurrect.py`
   and set `"clamp_percent": true` on `803585 peaceful` in `classes/bloodmage.json`, recording Status 2 on
   `classes/bloodmage_clauses.json` row 420.

## Consequences

- `803585 peaceful` passes when `health_peaceful == max_health_peaceful` and
  `mana_peaceful == max_power_peaceful` while still asserting out-of-combat refusal.
- `templar (19)` and `necromancer (23)` scenario digests remain byte-identical (`snapshots.py check` passes).
- Swarm of Flies `704646` keeps `#13799` rank-walking behaviour and passes `704646 refresh`.
