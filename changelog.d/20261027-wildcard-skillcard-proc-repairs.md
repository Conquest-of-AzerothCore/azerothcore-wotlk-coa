---
area: game
type: fixed
audience: players
title: Restore 35 Freepick and Wildcard Skillcard mechanics
---

Thirty-five Skillcard passives had no valid proc activation route in the shared world data. This change adds explicit event filters, required source handlers, native helper consumption and an idempotent world migration. It does not change the card catalogue, collection/drop rules, acquisition costs or other realms' world-DB routing.

## Per-spell changes

| Spell ID | Skillcard | Before | After this change |
| ---: | --- | --- | --- |
| 299986 | Arcane Reprisal | Arcane Barrage could not activate the Crusader Strike / Divine Storm cooldown reductions. | Arcane Barrage damage now dispatches the native family-cooldown helper; unrelated spells and periodic events are excluded. |
| 285930 | Arugal's Blink | Blink never activated the arrival Shadow Bolt volley. | A completed Blink activates the native delayed volley aura. Its damage helper receives the documented 0.10 SP / 0.065 AP coefficients. |
| 282040 | Blind Rage | Missed attacks did not grant the additional rage. | Actual missed melee/ranged attacks activate the native rage helper; hits, dodges, parries and unrelated spell misses do not. |
| 282105 | Bloodstained Recklessness | Kills during Recklessness could not extend its duration. | Kills while Recklessness is active activate its native three-second extension, with the documented one-second internal cooldown and XP/honor target requirement. |
| 285537 | Celestial Fury | Wrath critical strikes could not generate Celestial Fury, and the secondary Arcane discharge had no proc route. | Wrath criticals while the active Nature's Grace buff is present grant stacks. The next direct Arcane damage event discharges the native AoE, applies the per-stack damage bonus and consumes the stacks; the discharge cannot trigger itself. |
| 285240 | Charged Tides | Lightning Bolt / Chain Lightning / Lightning Rod could not grant Charged Tides. | Completed Lightning Bolt / Chain Lightning casts and Lightning Rod damage grant the native healing/cast-time stacks. Native spell-mod charge tracking consumes the benefit on the affected heal. |
| 282029 | Collective Conscious | Tranquility heals did not trigger the additional mana restoration. | Tranquility healing events invoke the native base-mana restoration helper on the healed target. |
| 283949 | Combat Medic | Bandage healing never built the promised healing increase. | Each bandage heal builds the caster-owned target marker up to its native eight-stack limit. Subsequent bandage heals gain the per-stack bonus; a new bandage resets that caster's marker. The obsolete spell-mod marker is converted to a dummy so the bonus is applied once. |
| 283251 | Consecrated Zeal | Consecration damage did not generate Consecrated Zeal stacks. | Actual Consecration damage grants the native capped stack buff; unrelated spells do not activate it. |
| 276808 | Dark Arrows | Shadow Bolt / Seed of Corruption did not grant usable Dark Arrow charges or their Black Arrow reduction. | Those damage events grant the native five-charge buff. Ranged auto hits fire the Shadow weapon attack and native one-second Black Arrow cooldown reduction; each hit consumes one charge and the unused duplicate effect is disabled. |
| 281471 | Dark Reclamation | Drain Soul / Life Tap could not build Dark Reclamation. | Drain Soul damage and completed Life Tap casts grant the native stacking modifier. A used spell-mod charge consumes it on the affected spell rather than leaving a permanent free modifier. |
| 277185 | Destructive Bargain | Incinerate / Soul Fire could not build Destructive Bargain, and its separate GCD modifier was disconnected. | Completed Incinerate / Soul Fire casts apply both native stacking helpers, restoring the authored PvE damage, cast-time, mana-cost and GCD modifiers. |
| 283175 | Energizing Prayer | Desperate Prayer restoring full health did not grant the additional mana. | An effective Desperate Prayer heal that leaves its caster at full health invokes the native max-mana helper. Partial heals and pure overhealing do not activate it. |
| 283700 | Faith Rekindled | Renew did not grant Faith; Faith's Renew-specific bonus was encoded as a damage aura instead of healing. | Renew healing grants Faith stacks. Guarded helper corrections route the Renew-specific bonus through caster-specific healing and the general bonus through the native all-healing-received aura. |
| 283634 | Fired Up | Direct Fire damage could not grant Fired Up. | Direct Fire damage rolls the native 12% chance. The guaranteed-critical buff has an explicit Fire-school-only, one-charge consumption row so unrelated casts cannot spend it. |
| 285749 | Fury of the Wind | Windfury attacks did not activate the additional nearby-enemy attack. | Windfury damage invokes the native weapon-damage helper and retains its five-target cap. The triggering school/event filters exclude unrelated attacks. |
| 285865 | Glacial Light | Holy/Frost damage against an enemy affected by the caster's Holy Fire did not reduce Icy Veins cooldown. | Qualifying damage invokes the existing cooldown helper only when that same caster owns the target's Holy Fire aura. |
| 283238 | Grasping Curse | Shadow Bolt did not apply Grasping Curse. | Direct Shadow Bolt damage applies the native slow to the damaged enemy, with the documented five-second internal cooldown. |
| 273595 | Ambidextrous | Single-Minded Fury off-hand attacks did not activate Dominant Strike or Dominant. | Direct off-hand damage while Single-Minded Fury is active invokes the native main-hand strike / Dominant chain. Southpaw blocks activation, and the proc respects its 16-second internal cooldown. |
| 283465 | Demonic Burst | Demonic Leap did not create the Blast Wave / Bursting Power sequence. | The native player event queue schedules the wave at the movement endpoint, using an appropriate level rank and the 40% damage increase, then grants Bursting Power. GUID/map/instance/alive/talent checks discard stale callbacks. |
| 293200 | Eternal Inferno | Direct Fire / Shadow damage could not reduce Reign of Dread / Unending Resolve cooldowns. | The two native cooldown helpers are dispatched independently: Fire uses a one-second internal cooldown and Shadow a three-second cooldown. Periodic damage is excluded. |
| 270424 | Heat Burst | Magic damage against the caster's Conflagrate target could not activate Heat Burst. | Qualifying magic damage invokes the Fire helper on that enemy with a one-second internal cooldown and the documented 0.18 SP / 0.117 AP coefficients. Another caster's Conflagrate does not qualify. |
| 285100 | Hellish Pursuit | Hellfire damage did not reduce Burning Rush cooldown. | Actual Hellfire damage invokes the native Burning Rush cooldown helper; unrelated spells do not. |
| 283927 | Holy Chains | Holy Fire could not apply Holy Chains. | The direct Holy Fire hit applies the native movement slow to its victim; later periodic ticks do not repeatedly refresh it. |
| 285739 | Holy Hammer Nova | Holy Nova did not reduce Light's Hammer cooldown. | One completed Holy Nova cast invokes the native two-second reduction once, rather than once for every damage/healing target. |
| 274125 | Howl of Winter | Cone of Cold did not grant Howl of Winter. | A completed Cone of Cold grants the native stacking buff. Native used-spell-mod charge tracking consumes it on the affected Deep Freeze. |
| 277505 | Inner Hunt | Qualifying non-hunter melee abilities did not grant Inner Hunt. | Completed melee abilities outside the Hunter family and using the global cooldown grant both PvE / PvP native damage helpers, at most once every four seconds. Guarded correction removes duplicate armor/cooldown fields from the PvP helper; used-spell-mod charges consume the benefit. |
| 270327 | Kindles for Holy Fire | Direct Fire damage did not build Kindles for Holy Fire. | Qualifying damage grants the native capped stack buff; native charge tracking consumes the used damage modifier on Holy Fire. |
| 283471 | Molten Outburst | A non-instant Fire hit on an enemy in the caster's Earthquake could not produce the eruption. | The handler checks the caster's actual Earthquake dynamic-object radius and dispatches the AoE with a ten-second internal cooldown. The helper has its documented 0.20 SP / 0.13 AP coefficients, and its knockback effect rejects non-player targets. |
| 273121 | Righteous Zealot | Direct damage could not roll Righteous Zealot's Smite/heal proc. | Qualifying direct damage rolls the native chance with a 4.5-second internal cooldown. The native party-heal / Smite helper has its 0.1275 SP / 0.1275 AP coefficients and uses the documented 80% damage/healing result against player targets. |
| 281712 | Shapeshifter's Aim | Mangle could not grant Shapeshifter's Aim. | Completed Cat/Bear Mangle casts grant the native Hunter-shot damage modifier; unrelated casts do not activate it. |
| 281710 | Shapeshifter's Fangs | Hunter shots did not grant usable Shapeshifter's Fangs charges. | Completed ranged Hunter abilities grant / replenish the native Cat modifier up to three charges. Auto Shot is excluded, and native used-spell-mod tracking spends charges. |
| 285780 | Shrouded in Shrapnel | Colossus Smash did not grant the armor buff, and Stagger damage could not reduce its cooldown. | Colossus Smash damage grants the native armor buff. Taken Stagger periodic damage reduces existing named Colossus Smash cooldowns using the helper's authored amount; the owner's done/taken self-damage events cannot double-trigger the reduction. |
| 277143 | Soul Void | Drain Soul could not build Soul Void or transition to Withered Soul. | Drain Soul damage adds caster-owned stacks to the victim. At the native threshold, stacks are replaced by Withered Soul; a target already bearing that caster's Withered Soul cannot rebuild stacks. |
| 274268 | Spartan Smash | Javelin / Shield Slam did not maintain Skewered, and consuming it with Siegebreaker did not reset Javelin. | Javelin damage applies Skewered; Shield Slam adds stacks only to an already-marked target. Siegebreaker damage consumes the caster-owned mark and clears existing Javelin cooldowns, including variant spell IDs. |

## Five explicitly deferred spells

The following cards remain unchanged pending native data, at the user's explicit request. They are not claimed fixed:

- **281681** â€” Cursed Arrows: the death-to-summon mapping is unrecovered; matching native Skeletal Guardian helpers reference absent creature template 375036. No replacement creature or stats authored.
- **284943** â€” Doppelganger: native summon helper points to absent creature template 350002. No unrelated NPC was substituted.
- **278510** â€” Brilliance of Faith: visible extra-cast promise and helper charge/target data conflict. No guessed targeting/charge reconstruction enabled.
- **284057** â€” Inescapable Roots: verified data does not specify the stronger damage-break behavior and complete escape rules. No guessed immunity or break multiplier enabled.
- **277818** â€” Molten Ammo: helper carries an amount but the base used to compute its extra Fire damage is not verified. No guessed weapon/hit-damage scaling enabled.

## Administration and verification

- Required migration: `data/sql/updates/pending_db_world/rev_20261027_01_wildcard_skillcard_proc_repairs.sql`. It supplies the proc rows, script bindings and five coefficient rows in one transaction; repeated application preserves unrelated spell/script data.
- Rebuild with the new source, then let the normal world updater apply this migration. No live DB was changed while implementing this patch.
- Focused regression: actual 35-spell filter code, negative events, charge caps, full-health boundaries, guarded helper corrections, SQL repeatability and installed DBC binding validation passed. Both changed translation units passed real-header MSVC syntax checks; scoped C++/SQL lint passed.
- The broader build was cancelled at the user's direction; no combined build pass is claimed. Native gameplay, visual/timing behavior, live migration application and acceptance remain pending. Do not treat the focused harness as proof of all 35 complete in-game tooltips.
