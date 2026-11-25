# Naxxramas level-60 conversion

These are historical conversion decisions and measurements, not a statement of current deployment status.
Recheck effective source, data, and verification before applying them to another raid.

## Approved inputs

- Convert the existing Naxxramas raid on map 533. Keep it at phase 8, after AQ40 and before Karazhan.
- Use the original level-60 Argent Dawn attunement with Archmage Angela Dosantos at Light's Hope Chapel. Honor the existing quest rewards and use the realm's playerbot exemption for personal attunement.
- Reuse 10–25 effective-player flex, the live bot weight of 0.7 and all four difficulties.
- Benchmark early loot against AQ40. Make late comparable rewards upgrades and Normal Tier 3 slightly stronger than Heroic Tier 2.5. Rebudget stats, weapon DPS, armor, sockets, procs and sets together.
- Audit Argent Dawn as the launch-scope faction. Reuse the Tier 3 token vendor and its pages and verify Registrar resets.
- Tune for ten characters in mostly Normal AQ40 gear. Use Anub’Rekhan as the representative opener because the four wings can be entered in different orders. Build toward Kel’Thuzad as the most demanding fight.

## Live baseline

| Area | Finding |
|---|---|
| Phase and maps | Phase 8 and Naxxramas cache mappings already exist. Map 533 is the populated Wrath instance. It was absent from the raid-entry release table. |
| Classic quest | Honored quest 9121 costs 60g, five Arcane Crystals, two Nexus Crystals and one Righteous Orb. Revered quest 9122 costs 30g, two Arcane Crystals and one Nexus Crystal. Exalted quest 9123 is free. All three are already level-60 quests and share an exclusive group. |
| Raid entry and modes | Installed map data has four modes capped at 25 characters each. SQL admission still specifies level 80 for modes 0 and 1. The live map has 856 spawns in both lower modes, two Normal-only Obedience Crystals and 101 gameobjects in both lower modes. Modes 2 and 3 lack native spawn bits. |
| Combat | Native major bosses are level 83; existing patrol and summon templates use a mix of levels and expansion budgets. The checked bosses have no CoA flex rows. Rebudget hostile trash and actual encounter summons, then audit ability damage and hard-coded values independently of max HP. |
| Loot | The [native gear inventory](evidence/naxxramas-native-gear-baseline.tsv) covers 341 distinct equippable Wrath pieces above level 60 from creature loot and its first-level references. Include chest loot and nested references in the final inventory. Keep distinct native 10- and 25-layout drops where they add value and isolate shared references before changing them. |
| Tier 3 | Four 144-offer armor pages and a 72-offer rings page already exist. The armor pages use ilvls 86/90/95/99; Heroic AQ40 tier reaches 86. Start the new budget review at 88/92/97/101 and compare matching slots and roles against AQ40 and Karazhan before fixing the values. Keep each vendor list under the 150-offer client limit. Map each encounter’s token to the matching [installed extended cost](evidence/naxxramas-tier3-token-costs.tsv). |
| Argent Dawn | A direct item scan found 789 templates with an Argent Dawn reputation requirement and none with a character requirement above 60. Continue tracing recipes, crafted outputs, quest rewards and separate effect requirements before closing the launch-scope audit. |
| Live branch differences | Production’s Registrar selects saved raid maps generically and production flex counts bots at weight 0.7. Fork main currently lacks both live customizations. Validate the eventual release candidate on the live branch base and retain the existing Registrar, bot weighting and vendor pagination. |

## Initial combat benchmarks

Use Normal AQ40 as the current lower reference and the approved Normal Karazhan health values as the upper reference. At ten effective players, Skeram is about 7.8M HP, C’Thun has a configured 20.3M HP pool, Karazhan's Midnight is 14M per form, and Prince is 66.1M. Consider about 10–12M for Anub’Rekhan, 18–24M for wing finishers, 26–30M for Sapphiron and 36–40M for Kel’Thuzad. Those are starting estimates for flex budgets. Preserve encounter phase and add behavior and cross-check tank damage, attack speed, ability damage and hard timers against AQ40 and Karazhan. Benchmark the owner's bot-heavy roster separately.

The four-mode audit includes Razuvious's control crystals and underlings, Gothik’s split room, the Horsemen’s marks and chest, Patchwerk’s Hateful Strike, Thaddius’s platform pair, Loatheb’s healing windows, Sapphiron’s frost pressure, and Kel’Thuzad’s waves, tank pressure, and Karazhan quest credit. Keep layout-specific rules where they remain playable with ten characters.

## Set bonus review

The [baseline inventory](evidence/naxxramas-tier3-bonus-baseline.tsv) contains 18 vendor sets and 72 bonus spells from the installed client data. Confirm server hooks and upstream fixes before deciding whether each still needs a change. Initial candidates include Defensive Stance on Dreadnaught Battlegear, shapeshift on Dreamwalker Raiment, Life Tap on Plagueheart, Feign Death and Black Arrow on Cryptstalker, and Tactical Mastery’s Stagger clearing on Dreadnaught Plate. Keep role and gameplay purpose when choosing a replacement. Record finalized changes, amounts, and affected set variants with the final item comparison.

## Implemented in the feature branch

- Added a phase 8 Naxxramas admission gate and accepted any of the three original rewarded attunement quests. Bot exemption applies after the phase check.
- Lowered access rows to 60 and added explicit Mythic and Ascended rows.
- Mirrored each original layout’s creature and gameobject spawn bits into its paired higher mode. Enabled both Obedience Crystals on all four.
- Updated the raid-release harness for the new gate and the earlier Karazhan gate. The harness and C++/SQL linters passed. Reapplying both migrations to a private copy gave identical access and spawn results.

- Rebudgeted 93 base combat and helper templates and their native difficulty variants to levels 60–63. Shared critters and templates referenced by spawns outside Naxxramas retain their values.
- Set flex budgets for 20 boss or phase units and fixed budgets for 68 trash or encounter add units. The difficulty ratios follow the existing AQ40 C’Thun curve. Private MySQL produced identical template and flex rows on reapplication.

## First combat pass

The [health comparison](evidence/naxxramas-combat-health-proposal.tsv) records the old estimated Normal pool and the new pools by difficulty. The values below assume the live baseline health rates and show the effective roster after bot weighting.

| Normal creature | 10 effective | 18 effective | 25 effective |
|---|---:|---:|---:|
| Anub’Rekhan | 11.0M | 19.8M | 27.5M |
| Thaddius, main phase | 22.5M | 40.5M | 56.25M |
| Sapphiron | 28.5M | 51.3M | 71.25M |
| Kel’Thuzad | 38.0M | 68.4M | 95.0M |
| Dread Creeper | 303.5k | 303.5k | 303.5k |
| Stitched Giant | 597.2k | 597.2k | 597.2k |
| Crypt Guard | 480k | 480k | 480k |
| Web Wrap | 85k | 85k | 85k |

Stalagg and Feugen each add 2.4M HP at the flex floor before Thaddius. Each of the Four Horsemen has 5.3M there. Scripted roles, native variant spell selection, and attack timers are preserved. The new creature levels and expansion stat tables change base melee. Review ability-specific damage independently of the HP pass. In particular, compare Patchwerk’s Hateful Strike with AQ40-geared off-tank effective health, and verify the tank and raid pressure from Kel’Thuzad’s Frostbolts and Frost Blast. Sapphiron’s Frost Explosion and Kel’Thuzad’s Void Blast retain their avoid-or-die behavior. Use actual spell rank and effect data for each mode when tuning damage.

The Horsemen use dynamically created chests 181366 and 193426 with loot IDs 25192 and 25193. Include both in the Tier 3 token and normal gear routing. The creature-loot inventory alone excludes those chest rewards.

## Ability tuning and Tier 3 armor

Four spell families use explicit mode budgets in the level-63 Naxxramas encounter path. Hateful Strike retains targeting, the one-second cadence and threat. Kel’Thuzad keeps the interruptible single Frostbolt, raid Frostbolt slow and native rank selection. Frost Aura sets sustained frost pressure while the ice-block mechanic keeps Frost Explosion lethal. The numbers below are the approximate flat spell budgets before player mitigation, configured rates and other modifiers.

| Ability | Normal | Heroic | Mythic | Ascended |
|---|---:|---:|---:|---:|
| Patchwerk Hateful Strike | 18.9–21.9k | 21.1–24.5k | 23.9–27.7k | 27.8–32.3k |
| Kel’Thuzad Frostbolt | 7.0–8.4k | 8.2–9.8k | 10.1–12.5k | 11.7–14.4k |
| Kel’Thuzad Frostbolt Volley | 2.4–2.9k | 3.0–3.5k | 3.6–4.4k | 4.3–5.3k |
| Sapphiron Frost Aura | 125 per tick | 175 per tick | 225 per tick | 275 per tick |

The Creature Scaling and raid-release harnesses passed. Actual damage and healing pressure await a full worldserver build and playtest.

The existing four Tier 3 armor pages now target ilvls **88 / 92 / 97 / 101**. The Normal target is two points above the highest observed Heroic AQ40 Tier 2.5 item. All 576 vendor armor pieces preserve their stat distribution, with ratings, armor, block and resistance scaled to the new budget. The 288 existing Normal and Heroic Bloodforged copies follow the same change. The [armor comparison](evidence/naxxramas-tier3-armor-before-after.tsv) records every field changed. The migration produced identical rows on reapplication in private MySQL.

## Tier 3 drops and redemption

The [token drop matrix](evidence/naxxramas-tier3-token-routing.tsv) covers each token source and mode. Wrist tokens come from Anub’Rekhan and Faerlina, hand tokens from Maexxna, waist tokens from Noth and Heigan, leg tokens from Loatheb, feet tokens from Razuvious and Gothik, shoulder tokens from Patchwerk and Grobbulus, the helm token from Thaddius, and chest tokens from the Horsemen chest. Gluth drops one random chest, legs, or shoulders token. Kel’Thuzad drops the ring token. Armor sources have one token in the base 10-layout or two in the base 25-layout, with Gluth retaining one random roll. Kel’Thuzad drops one ring token per kill.

The existing pages redeem the exact token issued for the selected difficulty. The rings already require level 60 and have separate item level bands of 90/95/99/104. They retain their current budgets. The shared Wrath tier references remain intact, and the migration disconnects only the Naxxramas root links. Private MySQL checks verified 30 creature token rows, both chest rows, and identical results on reapplication. The 36 route IDs match the installed vendor cost DBC. A full build and live corpse, chest and redemption checks are pending.

## Ordinary boss and chest gear

The [native gear audit](evidence/naxxramas-native-gear-audit.tsv) identified 341 unique equippable items at ilvls 200, 213 and 226. Both Horsemen chests are included. The normal chest's five items also appear in Gluth’s creature-loot pool. There are 81 socketed items and 23 items with an effect beyond the existing CoA item-rank markers.

The candidate creates 1,364 level-60 variants with a dedicated block at item ID 8,000,000 plus the original item ID and 100,000 per difficulty step. The block was checked in the installed Item.dbc and both live item tables. Scope the conversion to the ordinary loot of map 533's boss corpses and both Horsemen chests. The original Wrath item templates and shared loot references keep their values.

| Difficulty | Early through late bosses |
|---|---:|
| Normal | 84 / 87 / 90 |
| Heroic | 88 / 91 / 94 |
| Mythic | 93 / 96 / 99 |
| Ascended | 97 / 100 / 103 |

Stats and resistances use installed Epic property points by slot. Armor, block and Normal weapon DPS use nearby AQ40, Classic Naxxramas and Karazhan items by slot, weapon type and caster or physical role. Preserve the original weapon speeds and damage spreads. Higher difficulties use a steady increase from each Normal weapon budget. Socket colors remain and their bonuses use level-60 enchantments of the same effect type.

The [before-and-after item comparison](evidence/naxxramas-native-gear-before-after.tsv) records every changed item field. A private MySQL validation verified 341 variants at each mode, matching server Item.dbc registrations, unchanged Wrath rows, and no declining armor, block or primary damage range as the difficulty increases. Reapplication produced identical data.

## Item effects and Tier 3 bonuses

All 12 native trinkets have level-60 effects for the four gear modes with explicit proc cooldowns. They retain the original durations and display their tuned budgets in the item description. Ten relics use class-neutral role stats in place of ability-specific effects. Their relic-slot eligibility remains. Maexxna’s Femur carries explicit 15/16/17/18 armor penetration rating by mode. The [item effects table](evidence/naxxramas-item-effect-mappings.tsv) lists every budget.

The live Tier 3 vendor carries 18 sets with 72 bonus spells. The [changed set bonuses](evidence/naxxramas-tier3-bonus-changes.tsv) lists seven selective changes. Existing generic bonuses, including Redemption Battleplate's four bonuses, retain their effects. The Dreadnaught Plate proc keeps the defense benefit without Tactical Mastery. Cryptstalker’s offensive trigger accepts melee and ranged specials and can benefit the wearer without a pet. Spot-check the installed client’s set tooltip against the observed effects.

Both migrations reapplied identically in private MySQL. Actual spell loading, proc behavior, corpse loot, vendor redemption and equipping still need full server verification.

## Argent Dawn launch scope

Direct reputation items, the three quartermaster inventories, and quests granting Argent Dawn reputation had no character-level requirements above 60. Crafted outputs topped out at 59. The three enchantments require levels 58, 58 and 60. Existing profession and reputation requirements remain in force.

## Remaining acceptance

Build and verify against the release base with the Registrar and bot weighting. Exercise the full migration sequence, original attunement paths and bot exemption, instance mode selection, representative damage, item procs and Tier 3 bonuses, corpse and chest loot, and the Registrar. Preserve the existing phase-8 cache policies. Record the manual 10-player Normal AQ40-geared playtest and the owner's client checks separately.


## Isolated release verification

- The release candidate built successfully using the incremental Karazhan cache.
- The first private startup exposed a slow creature-template query. The combat migration now collects shared template IDs in one indexed temporary table before updating Naxxramas templates.
- The next private startup applied all eight Naxxramas migrations and reached world loading. The host-memory guard stopped the run when available memory fell to about 1 GiB. No gameplay scenario ran.
- Pending runtime checks include phase 8 admission, bot exemption, Anub’Rekhan health and corpse loot across four difficulties, Loatheb’s Shadow, and the Kel’Thuzad prerequisite for Karazhan. Client checks and the AQ40-geared 10-player playtest are also pending.

The maintenance-window runtime verification passed all seven targeted scenarios across two runs. The first completed batch passed phase 8 admission and the playerbot exemption, all four Anub’Rekhan health and corpse loot checks, and the Kel’Thuzad unlock for Karazhan. Its Loatheb’s Shadow fixture stopped before equipping because it had not granted the item. The corrected fixture passed using the real item and verified the 250 attack-power aura. The two `verify_all.py` reports are `20261121-112652` and `20261121-113250` in the isolated release checkout.
