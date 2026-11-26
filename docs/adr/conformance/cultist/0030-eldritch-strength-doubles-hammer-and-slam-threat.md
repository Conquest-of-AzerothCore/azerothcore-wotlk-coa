# 0030. Owner ruling Q-cu-34: Eldritch Strength doubles Hammer of Twilight and Entropic Slam threat

- Status: accepted (owner ruling Cultist Q-cu-34 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Eldritch Strength `680600`: "Increases the damage of |cffffffffHammer of Twilight|r and |cffffffffEntropic Slam|r by $s1% and they now generates a large amount of threat."

In `Spell.dbc`, `680600` has:
- `Effect[0]`: `SPELL_AURA_ADD_PCT_MODIFIER (108)`, `MiscValue = 0` (`SPELLMOD_DAMAGE`), `BasePoints = 24`, `DieSides = 1` (`+25%`).
- `Effect[1]`: `SPELL_AURA_ADD_PCT_MODIFIER (108)`, `MiscValue = 2` (`SPELLMOD_THREAT`), `BasePoints = 14`, `DieSides = 1` (`+15%`).

`SpellInfo::IsAffectedBySpellMod` (`src/server/game/Spells/SpellInfo.cpp:1616`) routes `680600` to Hammer of Twilight (`805116` chain) and Entropic Slam (`804152` chain). In `CharacterAdvancement.dbc` record `29273`, `680600` belongs to `Tab = 88` (Bulwark / Dreadnought tank specialization, `TalentEssenceCost = 1`) and has no additional runtime specialization or `680750` aura check in `src/server/coa/`.

Before this change, `ThreatManager::CalculateModifiedThreat` (`src/server/game/Combat/ThreatManager.cpp:712-713`) applied `680600`'s `+15%` `SPELLMOD_THREAT` (`apps/coa-gameplay-test/scenarios/tank-threat-audit-cultist.json:5,92-112` measured `115000` on a `100000` base).

The owner ruled (Cultist `Q-cu-34`, `O-15`, 2026-11-25): `threat_x2` — multiply threat by 2 instead of +15%, noting that the threat increase only applies to the tank specialization anyway.

## Options

- Set `info->Effects[1].BasePoints = 99;` (`99 + DieSides(1) = +100%`, so `Player::ApplySpellMod` at `Player.cpp:10624,10687` multiplies threat by `2.0f`) on `id == 680600` in `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), preserving `680600`'s existing Bulwark Tab 88 talent-tree gate without adding an unrequested runtime `680750` aura check. Chosen.
- Add a runtime `HasAura(680750)` gate in an `AuraScript` / `Refresh`. Rejected because `680600` is already gated exclusively to the tank specialization by `CharacterAdvancement` `29273` (`Tab = 88`), and an extra runtime `680750` check would change the existing gate semantics.

## Decision

In `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:269-270`), set `info->Effects[1].BasePoints = 99;` when `id == 680600`. Add learned/control `threat_per_damage` regression entries (`hammer_threat`, `hammer_threat_control`, `slam_threat`, `slam_threat_control`) in `apps/coa-gameplay-test/conformance/classes/cultist.json` and update `cultist_clauses.json` Row 249. No shared engine, SQL, DBC, or other-class changes.

## Consequences

- Eldritch Strength `680600` multiplies threat of Hammer of Twilight (`805116..806830`) and Entropic Slam (`804152..572846`) by `2.0x` (`+100%`), keeping its `+25%` damage bonus and existing Bulwark Tab 88 acquisition gate intact.
- No other spell or class is reached. Existing catalog scenarios `apps/coa-gameplay-test/scenarios/cultist-eldritch-strength.json` (`1999..2001` on `base: 1000`) and `apps/coa-gameplay-test/scenarios/tank-threat-audit-cultist.json` (`199500..200500` on `base: 100000`) are updated to match the `x2` threat ruling and both pass.
- Counted pair (`20261125-092328` / `20261125-092359`, build `3744367126f6`, 18/18 ok, 0 flips):
  - `680600 behaviour_metric_delta hammer_threat`: `2.00844` / `2.00849` vs `hammer_threat_control`: `1.01057` / `1.01058` (expected `2.01` vs `1.01` +- `0.02`, accounting for 60 flat `SpellLevel` initial threat).
  - `680600 behaviour_metric_delta slam_threat`: `2.01105` / `2.01103` vs `slam_threat_control`: `1.01384` / `1.01379` (expected `2.01` vs `1.01` +- `0.02`, accounting for 52 flat `SpellLevel` initial threat).
  - Sibling and reached checks unchanged: `680600` `hammer_damage` (`+25.07%` / `+24.97%`), `slam_damage` (`+24.94%` / `+25.05%`), all 7 `806830` entries, and all 5 `572846` entries passed ok/ok.
