---
area: game
type: fixed
audience: players
title: Wildcard Skillcard batch003 repair attempts
---

Source/SQL changes only: not compiled, tested, applied live or published. These are repair attempts pending verification.

## Per-card before / after

## Saved repair attempts

| ID | Card | Before / missing path | Written change |
| ---: | --- | --- | --- |
| 12857 | Commanding Presence | Missing active card proc/script route in the inspected world metadata. | Bind the existing Commanding Presence handler to the card and the two verified Shout masks; retain native level-scaled Strength/Stamina helpers. |
| 13048 | Enrage | Missing active card proc/script route in the inspected world metadata. | Bind the existing Enrage handler; restore Warrior activation / incoming-damage events and the documented five-second cooldown. |
| 16580 | Lightning Mastery | Missing active card proc/script route in the inspected world metadata. | Lightning Bolt, Chain Lightning and Thunderstorm critical damage can roll the native 15% chance and grant its timed spell-critical-damage helper. |
| 17933 | Improved Shadowburn | Missing active card proc/script route in the inspected world metadata. | Direct Shadow spells/abilities can roll the native 30% chance; the existing cooldown/no-reagent helper receives used-spell-mod charge consumption. |
| 35102 | Concussive Barrage | Missing active card proc/script route in the inspected world metadata. | Chimera Shot and Multi-Shot direct damage apply the native Daze helper to the enemy. |
| 51687 | Prey on the Weak | Missing active card proc/script route in the inspected world metadata. | Bind the existing Rogue health-percentage periodic handler; restore its two-second periodic-dummy shape when the installed broken proc shape is present. |
| 281352 | Skull Crusher | Missing active card proc/script route in the inspected world metadata. | Slam damage can dispatch the native Death Wish cooldown helper; remove its unused enemy-target dummy so the self-targeted cooldown effect can execute. |
| 281543 | Waning Moon | Missing active card proc/script route in the inspected world metadata. | Periodic Moonfire damage grants the native cast-time stack at most once per second; route the modifier to both Arcane Blast and Starfire and consume its used charge. |
| 281782 | Quick Burn | Missing active card proc/script route in the inspected world metadata. | Direct melee strikes roll the native 10% chance; the next affected Mana Burn consumes the cast-time modifier. |
| 282279 | Judge, Jury, Executioner | Missing active card proc/script route in the inspected world metadata. | Completed Paladin Judgements grant the native rage/armor-penetration helper; the affected Execute consumes its modifier. |
| 286217 | Momentum | Missing active card proc/script route in the inspected world metadata. | Completed Grappling Hook casts grant the native movement-speed/Rogue-damage buff. |
| 964993 | Renewed Energy | Missing active card proc/script route in the inspected world metadata. | XP/honor kills restore 20% base mana with a ten-second cooldown; correct the helper from flat Energize to native base-mana-percent restoration. |

## Remaining / already-supported cards

| ID | Card | Result |
| ---: | --- | --- |
| 48545 | Revitalize | Mixed heal proc chances, target power restoration and full-health mana-cost refund require a dedicated handler. |
| 270526 | Words of Healing | Borrowed Time application/removal and direct-heal crit lifecycle need source integration. |
| 271400 | Maledictive Assault | Bear-form casting permissions, cleave targets and reduced damage require dedicated source work. |
| 272989 | Renewed Through Absolution | Hero Penance/Renew consumption and heal scaling need adaptation; the existing Mystic version uses different helper IDs. |
| 275965 | Master's Meatshield | Pet ownership/type selection and Drain Life healing transfer require a dedicated handler. |
| 276963 | Vampire Lord | Vampiric Essence generation, spending and five-ally selection require the full secondary chain. |
| 277450 | Unseen Assassin | Stealth exit / Shadow Dance lifecycle, GCD and PvP modifiers require dedicated handling. |
| 277460 | Physics in Practice | Existing PhysicsInPractice damage hook checks this aura and Sprint; no direct proc row is required. |
| 277485 | Clean Pass | Must consume the caster-owned Piercing Shots remaining damage, not simply reapply a helper. |
| 277588 | Thousand Cuts | Rogue-family periodic modifier requires review for cross-class bleed/poison coverage. |
| 277609 | Critical Serration | Needs Piercing Shots eligibility integration for the two additional Rogue attacks. |
| 277938 | Voidblade | Two-way synergy, proc chance, stacks and no-refresh-at-cap require a dedicated chain. |
| 278113 | Servant of the Old Gods | Tentacle ownership, target-direction command and summon AI need inspection. |
| 278226 | Thunderburst | No spell_threat row was found; the promised high-threat multiplier is unverified. |
| 278420 | Maelstrom | One/two-stack generation and subsequent Maelstrom consumers require dedicated handling. |
| 280040 | Envenomed Weapons | Party-area distribution, recipient ownership and poison payload need integration. |
| 280055 | Malignant Jinx | Must listen to the cursed victim casting and silence that victim, not the ordinary caster-owned proc route. |
| 280200 | From Life Comes Death | Mushroom summon/template readiness and kill-position behavior need review. |
| 280210 | Judgement of The Three Hammers | Three-hammer timing/target distribution and self-proc prevention require a dedicated chain. |
| 281110 | Destabilize Time | Victim-cast stacking must preserve duration and avoid refresh. |
| 281341 | Duelist | Dueling flag mapping, area ownership and leaving-area slow require source work. |
| 281542 | New Moon | Its helper uses effect198, which has no core implementation; needs an authored duration-extension handler. |
| 281687 | Fleeting Shadow | Temporary out-of-stealth Ambush access requires cast-permission / lifecycle integration. |
| 281983 | Coward's Bane | Behind-target eligibility and an independently confirmed proc-chance contract remain to be resolved. |
| 283090 | Corrupting Shadows | Needs caster-owned Corruption rank/variant resolution from Shadowburn rather than a zero-trigger proc row. |
| 283317 | Lightning Discharge | Lightning Shield damage, channel lifecycle, AoE stun and20second cooldown need a coordinated handler. |
| 284041 | Waking Nightmare | Haunt marker, external-healer attribution and Phantom Nightmare fear interaction require dedicated source work. |
| 284460 | Tribal Rage | Additional native helper/event contract review required; no speculative change made. |

## Required world migration

`data/sql/updates/pending_db_world/rev_20261027_02_wildcard_skillcard_batch003.sql`. No live SQL application or runtime verification has been performed.
