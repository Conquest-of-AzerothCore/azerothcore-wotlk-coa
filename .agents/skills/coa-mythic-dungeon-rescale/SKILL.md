---
name: coa-mythic-dungeon-rescale
description: >-
  Plan or implement CoA level-60 five-player dungeon rebalances for Mythic Keystone progression,
  including base difficulty rewards, combat parity, keystone caches, and item upgrades.
---

# CoA Mythic dungeon rescale

Follow the checkout's AGENTS.md and [CoA development](../coa-development/SKILL.md). Use this skill
to integrate or rebalance a dungeon for Mythic Keystone progression. For an initial level-60 conversion
or fixed-mode data work, reuse the relevant sections of [CoA dungeon rescale](../coa-dungeon-rescale/SKILL.md).
Use [fixed item rescaling](../../docs/systems/fixed-item-rescaling.md) for item budgets, owned copies,
PvE Power, and client delivery.

## Resolve inputs

Obtain the target dungeon or wings, a comparable existing keystone dungeon and party benchmark, and the
desired Normal, Heroic, base Mythic, and keystone reward progression. An instruction to match the existing
ladder authorizes deriving the levels from installed data and presenting them for review.
Record what earns the higher rarity, the desired low- and high-key comparison levels, and whether the
request covers analysis, implementation, or rotation activation. Ask only about unresolved choices that
materially affect progression, reward ownership, or encounter tuning.

## Compare effective combat and loot

- Read installed realm configuration, effective world data, and DBCs. Trace fixed dungeon overrides,
  native difficulty templates and spell ranks, and the general creature scaler to effective base Mythic
  HP and damage. Apply the installed keystone health and damage curves once. Include affixes as a separate
  contribution. Label model results and measurements explicitly.
- Compare the same five-player gear and composition at base Mythic, an entry key, and a higher key.
  Sample trash pack sizes, pulls and enemy forces, boss HP, swing burst, major spells and overlap,
  healer pressure, and time relative to the timer. Preserve encounter identity. Tune the source of
  the gap locally, especially boss-specific overrides, before changing shared scaling or reducing all HP.
- Trace drops through boss summons and forms, nested references, final chests, trash, quests, and
  completion rewards. Compare analogous items by role, slot, and quality, showing actual armor,
  weapon DPS, stats and relevant effects alongside item levels. Check Normal and Heroic for reward
  inversion when lowering base Mythic.

## Implement and verify within authorization

- Use follow-up pending migrations with pinned original budgets. Retain owned dungeon-specific item
  IDs where safe, and route shared drops to dungeon- and difficulty-scoped variants. Preserve chances,
  quest items and mechanics. Apply rarity changes to the agreed reward sources and rebudget for the
  new quality together with the item level. Take care when boss and trash share a source item.
- Trace timed-dungeon and keystone data, LFG mode, enemy forces, encounter credit, timer, and realm
  rotation filters. Existing key records can be available in the data while the realm excludes their
  expansion from random keys. Prefer scoped activation when piloting a single dungeon.
- Check the actual loot path during keys. With creature/chest loot suppression enabled, gear comes
  through completion caches and upgrades. Inspect the installed MythicPlus module. Its legacy pools
  and upgrade chains can derive from `coa_dungeon_loot_variant` and item name/slot, while fixed dungeons
  route through `coa_dungeon_rescale_loot`. Use unambiguous item-family mappings for new fixed
  dungeon rewards. Integrate both cache selection and coin upgrades, checking the expansion currency,
  depth eligibility, duplicate names, full upgrade ladder, and absence of reward leaks.
- Reuse existing item delivery and fixed-query paths. Verify original and new copies, item levels,
  rarity, equipped PvE Power, effects, previews and relog. Check base Mythic source loot, cache pools,
  and coin upgrades independently. Check migration replay, unaffected wings, scoped activation, reset
  and keystone completion. Compare gameplay on the same roster across chosen dungeons and key levels.
  Report unverified gameplay or client checks. Skill creation, live SQL, installation and rotation
  activation are separate actions.

## Worked example: Hellfire Ramparts

Use Stratholme as the level-60 comparison. The agreed Ramparts reward targets are Normal 60,
Heroic 62, base Mythic 64, and +10 72. All Mythic boss and Nazan/Vazruden final-chest equipment
receives epic budgets. Trash keeps its original rarity. Use the existing Classic ladder for intermediate
depths. Representative comparisons include Hellreaver vs. Demonshear, Cloak of the Everliving vs.
Cape of the Black Baron, and Life Bearer's Gauntlets vs. a suitable epic plate benchmark.

The previous comparison put Ramparts boss health in the Stratholme range once both effective HP
paths were accounted for. Start by reviewing Ramparts' historical 6× Normal-relative Mythic boss
spell override against the 2× fixed-dungeon reference and assess melee separately. Compare +1 and
+10 with the same roster before widening the rotation. Recheck these baselines on the target checkout.
