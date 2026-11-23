---
name: coa-profession-rescale
description: >-
  Plan or implement expansion-scoped level-60 profession conversions, mapping original crafted equipment
  item levels into an owner-supplied band and rebudgeting stats, effects and recipe access. Covers TBC or
  WotLK professions; gems and non-equipment outputs require an explicit scope policy.
---

# CoA profession rescale

Follow the checkout's AGENTS.md and coa-development skill. Creating or editing this skill does not rescale
items, activate migrations, install a server or authorize live changes.

When changing gear or item requirements, also read
[fixed item rescaling](../../docs/systems/fixed-item-rescaling.md) for runtime ownership, existing-copy
persistence, cache delivery and client-patch boundaries. Keep this skill's specific scope and effect policies.

## Inputs and policy decisions

Required inputs are **profession**, **expansion** (`tbc` or `wotlk`) and **target item-level band** `[L, H]`.
Resolve profession IDs, recipes and crafted outputs from effective data. Validate positive integral endpoints,
`L <= H`, and support in the installed item-budget system. Item level is distinct from character level and
profession skill rank. The character-level cap is 60, not the target item level or profession skill cap.

Configurable conversion inputs:

| Input | Values and behavior |
|---|---|
| `non_equipment_categories` | Explicit category list; default empty. Select gems, enchants, consumables, scopes, armor kits, enhancements, bags, mounts, containers, materials or cosmetics individually. |
| `proc_policy` | Choose `preserve` or `proportional` for numeric proc magnitudes. |
| `on_use_policy` | Independently choose `preserve` or `proportional` for numeric on-use magnitudes. |
| `effect_overrides` | Optional per-item/spell flat-magnitude multipliers or targets, taking precedence over the selected policy; validate finite values and effect semantics. |

An invocation may set a common effect policy for both proc and on-use effects; explicit individual inputs
win. Resolve omitted effect policies before a conversion instead of assuming the owner approved numeric
changes. Preserve previously supplied choices. `proportional` means original flat magnitude multiplied by
mapped target item level divided by original item level. `preserve` keeps the original magnitude. Neither
mode changes percentages, proc rates, durations, cooldowns, stack caps or utility by default.

Non-equipment categories do not set the equipment band's anchors. Including a category covers its character
level gates, but does not invent a numeric budget for it. Where equipment mapping does not define a meaningful
target (gems, enchants, consumables or guardian outputs), obtain an explicit category target/range or effect
multiplier before scaling its strength. Gates-only conversion is valid and leaves category strength intact.
Bag slot counts, material quantities and mount speeds are not equipment stats. Preserve the owner's existing
TBC gems decision: keep their stats/effects unchanged and cap level gates; do not silently extend it to Wrath.

Confirmed policies:

- Modify original crafted item templates in place: existing and future copies receive the same approved
  budgets. Outputs also obtained from drops, quests or vendors change at those sources too; disclose that
  impact without re-requesting permission already given for in-place edits. Resolve conflicts with existing
  zone/dungeon/raid budget ownership before applying contradictory conversions.
- Preserve item quality, role, sockets/colors, identity, binding and unique restrictions; rebudget stats and
  socket bonuses at the mapped item level using the appropriate quality and slot budgets.
- Cap profession-training, specialization, recipe-learning and required acquisition-quest character gates at
  60 while retaining skill ranks, specialization choices, reputation, quest objectives and material costs.
  Do not bypass acquisition objectives or unlock unrelated content. Report a chain that remains unavailable.
- Preserve recipe reagents, costs and all non-level acquisition/crafting restrictions unless separately
  authorized. Character-level caps do not reduce profession skill caps or recipe skill requirements.
- Prefer existing client-known IDs and server-delivered item/spell changes. Do not introduce a required
  downloadable client patch without the owner's explicit agreement. Identify client-local restrictions or
  stale descriptions, and distinguish artifact checks from actual client acceptance.

The owner's settled requirement is that all in-scope crafted items and recipes have character-level
requirements at most 60. Preserve valid lower requirements. Cover recipe books, recipe-learning spells,
crafted equipment use/equip gates and enchantment application gates. This does not lower profession skill
requirements such as 375 or 450 to 60. A gate that cannot be changed within the approved category/access
policy remains an explicit unresolved exception rather than being reported as completed.

## Discover and pin the baseline

Inventory trainer, discovery, specialization, reputation/vendor, quest, research and recipe-book acquisition
paths, with taught spells, triggered crafting spells and every output. Include upgraded crafts and alternate
recipes for one output. Deduplicate by output identity before deriving anchors. Exclude obsolete test/debug
items, unused prototypes and non-player crafts; report exclusions such as test gems explicitly.

Determine expansion ownership from recipe provenance, skill rank, acquisition, original templates and authored
expansion data together. Item-ID ranges or character-level requirements alone are insufficient. An expansion
profession includes recipes for older content; training an old recipe during TBC does not make its output TBC
gear. Do not treat ordinary Wrath crafts as TBC because an existing conversion lowered their requirements.

Pin original templates, effective DBC plus SQL effects, acquisition gates and current scaling ownership before
editing. Store inputs, original expansion identity, source revision and transformation mappings in the eventual
implementation's maintained data. Reuse that baseline for retunes; never treat already scaled live values as
originals. Keep recipe-book item levels out of equipment budget anchors.

For TBC Jewelcrafting, reuse the pinned cohort and regeneration instructions in
`apps/coa-world-content/professions/README.md`. The installed run uses equipment 60–77, requirement-only
non-equipment changes and preserved procs/on-use effects. These are that run's inputs, not defaults for every
profession or expansion. The helper does not discover arbitrary new cohorts. Keep test gems excluded.

## Map equipment item levels

For approved equipment outputs belonging to the requested expansion with **original ItemLevel > 60**, let
`A` be the lowest original item level and `B` the highest. Map linearly using integer arithmetic:

```text
new_item_level = L + round_half_up((old_item_level - A) * (H - L) / (B - A))
```

This preserves original ordering, maps `A` exactly to `L` and `B` exactly to `H`, and assigns equal originals
the same target. Integer rounding can collapse adjacent tiers; show those collisions rather than inventing
extra levels outside the band. Items originally at or below 60 keep their budgets unless separately requested,
although approved character-level gate changes still apply. Show any progression inversion this produces.

If the selection is empty, report it. If `A == B` and `L != H`, ask for a single target rather than dividing by
zero or arbitrarily choosing an endpoint. If `L == H`, assign that item level to all selected equipment.
For a downscale, flag any target above its corresponding original and resolve it before changing data; do not
silently clamp individual targets and violate the endpoint mapping. This mapping is recommended interpolation
for the owner's endpoint rule; confirm a different requested interpolation before generating the migration.

## Rebudget and preserve progression

Use the installed quality/slot/role budgets at each mapped level to recalculate primary stats, ratings, armor,
shield block, resistances and weapon DPS. Apply
[Classic PvE Power by slot](../../docs/systems/fixed-item-rescaling.md#pve-power-by-slot) to converted
equipment and verify its equipped rating and tooltip. Preserve quality, role, binding, unique restrictions,
profession/specialization requirements, weapon speed and damage spread. Preserve socket count and colors,
include their contributions in the total budget, and scale socket bonuses without counting
inserted gem stats twice. Flag items whose sockets or utility alone exceed their target budget.

Trace random properties/suffix factors, crafted variants, enchant effects, proc/on-use spells, triggered
children, periodic amounts, level formulas and guardian stats. Apply the selected proc/on-use policies and
explicit overrides independently. Under `proportional`, scale flat damage, healing, absorbs, resource
restoration and temporary stat grants from original values, rounding once;
preserve percentage effects and utility unless their mechanics require a disclosed exception.
Static equip stats and permanent stat-grant spells follow the equipment budget, not the configurable
proc/on-use policies. A spell-based passive stat is not a proc merely because it is implemented by a spell.
Avoid applying both a rebudgeted weapon DPS change and a second multiplier to the same weapon-based effect. Isolate spells
shared with outside content without losing script/proc bindings or requiring unknown client records.

Do not rebudget recipe books, materials, containers or gems as armor merely because they have ItemLevel.
Preserve recipe reagents, counts, skill gains, cooldowns, discovery chances, output quantities, loot/vendor
probabilities, gold costs and non-level acquisition restrictions unless separately authorized. Enchanting and
other professions without eligible equipment need a separate output-budget policy, not fictitious anchors.

Trace native item ladders, cached stat captures, acquisition hooks, query previews and existing conversion
paths so they cannot overwrite the fixed target or compound scaling. Existing copies in equipment, bags,
bank, mail and auction paths must agree with newly crafted copies under the approved existing-item policy.
Do not infer item provenance from the character's current location.

## Proposal, implementation and verification

Before applying a conversion, show categories and counts, exclusions, original anchors, mapping formula and
representative low/middle/high outputs. Include original/new item level, character requirement, quality,
stats, sockets, Power and numeric effects, with the selected policies and every override. Include the full
changed-item list, excluded test/debug items, upgrade-chain ordering and rounded tier collisions. Compare the resulting crafts with this realm's raid/dungeon
progression, including whether purchasable materials allow skipping a tier. Identify affected shared sources,
trainer/recipe gates, client limitations and unresolved policy choices. Do not require a profession target
band merely to finish drafting this skill.

Implement only the approved scope, using repository SQL/C++ conventions and repeatable pending migrations.
Verify through focused verify_all stages: endpoint/ordering/rounding invariants, quality/slot budgets, unchanged
outside categories, recipe acquisition and crafting at 60, preserved skill ranks/material costs, effects,
existing copies, query previews, restart persistence and migration replay. Validate actual runtime budgets,
not only raw ItemLevel fields. Run build checks when sources change. Resource-bound isolated verification;
do not start another real worldserver alongside the live realm on this host.

Report exact changed items, original/new stats, access changes, preserved restrictions, verification evidence
and remaining client/gameplay acceptance. Skill validation proves the instructions' structure only; it does
not prove a conversion or authorize deployment, commits or publication.
