---
name: coa-reputation-rescale
description: >-
  Plan or implement level-60 conversions of CoA faction reputation rewards by expansion, with equipment
  item-level budgets, non-equipment access gates, and independent proc and on-use policies.
---

# CoA reputation rescale

Follow AGENTS.md, the [CoA development skill](../coa-development/SKILL.md), and
[fixed item rescaling](../../docs/systems/fixed-item-rescaling.md) for equipment ownership,
affixes, PvE Power and client validation. An input example describes a conversion, and running it requires
a separate implementation request.

## Inputs

| Input | Interpretation |
| --- | --- |
| Reputation | Faction name or ID. Resolve it in effective data and verify expansion ownership. |
| Expansion | Expansion the reward sources belong to. |
| Equipment item-level band | Inclusive positive integral endpoints, supported by the realm budget tables. Character requirements cap at 60 regardless of this band. |
| Equipment-only | Yes limits item changes to equipment. No also includes faction-owned non-equipment rewards. |
| Non-equipment budget | Gates-only caps character-level requirements and preserves item level, stats and effect strength. A different budget needs an explicit category policy. |
| Procs | Preserve or proportionally rebudget eligible flat magnitudes. |
| On-use effects | Preserve or proportionally rebudget eligible flat magnitudes independently of procs. |

Worked invocation for review

- Reputation — Cenarion Expedition
- Expansion — TBC
- Equipment item-level band — 60–77 inclusive
- Equipment-only — No
- Non-equipment budget — Gates-only
- Procs — Preserve
- On-use effects — Preserve

## Inventory rewards and access

- Resolve the faction and standing gates using effective DBC and DB records. Enumerate quartermasters,
  vendor offers and extended costs, reputation-gated quest rewards and faction reward containers. Trace
  conditions, item requirements and acquisition or use spells. Include offers whose reputation gate lives
  on the vendor or quest even if the item has no explicit faction field. Exclude normal quest rewards
  that merely award reputation and generic merchandise sold by a quartermaster.
- Preserve required faction and standing, reputation gain and progression, currencies, prices, profession
  and riding skill ranks, and quest objectives. Cap reward-specific character-level purchase, equip,
  learning and application gates at 60. Preserve valid lower gates, and report shared or client-local
  gates that require separate changes.
- Trace alternate acquisition across outdoor, dungeon, raid, profession and PvP systems before editing.
  Pin original templates and original item levels alongside current effective budgets and the checkout
  revision. Retain an existing conversion if it matches the new budget. If this run would overwrite a
  conflicting budget or affect another reward source, present the affected items and ask whether to keep
  the current values, retune all sources, or create faction-specific variants. Preserve existing copies
  and item IDs where an in-place edit has a single authorized owner.

## Rebudget and verify

- Map original equipment item levels monotonically into the approved band. Keep equal source item levels
  together and preserve ordering across comparable equipment. Use the band endpoints for the lowest and
  highest distinct source levels, with nearest-integer rounding. Use the midpoint for a single source
  level unless the owner provides an anchor. Always derive targets from the pinned source data on reruns.
- Preserve quality, equipment role, identity, sockets/colors and restrictions. Use matching slot and
  quality budgets for stats, weapon damage, armor, block, resistances, socket bonuses and affixes.
  Apply the established CoA PvE Power policy. Review set and passive equipment effects as part of the
  budget and flag those that require a new effect policy.
- Preserve proc and on-use mechanics and strength when their respective policy is Preserve. For
  proportional mode, multiply eligible flat magnitudes by target item level divided by original item level.
  Preserve rates, percentages, durations, cooldowns and utility unless specifically approved. Scope any
  spell edits to the converted source and keep shared spell behavior intact.
- Present sample before/after rewards across standings and categories, ownership conflicts, level gates,
  and client validation needs. For implementation, use repeatable pending migrations. Verify reapplication
  in an isolated database and use focused CoA verification for purchase or quest rewards, use at level 60,
  standing and currency enforcement, equipped stats, effects and an unrelated reward source. Report runtime
  and client checks actually completed. Live database changes and deployment require separate authorization.
