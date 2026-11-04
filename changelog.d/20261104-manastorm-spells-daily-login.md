# CoA daily login rewards, Manastorm improvements and Ascension spell restoration

## Account-wide daily login rewards

- Award 200 Bazaar Tokens by mail on an eligible CoA login, with one shared account cooldown of 24 hours in the character database.
- Wait for world entry and teleport/loading readiness before processing the claim.
- Commit the account cooldown and reward mail together, with database guards against stale or duplicate claims.
- Show Daily Login Reward using the existing client toast, actual item icon and awarded quantity through the server Lua bridge.
- Configure additional item rewards in the world database. Retain last claim time and lifetime claim count for future streak rewards.
- Exclude bot sessions and Wildcard characters. Preserve account cooldowns across character changes, character deletion and restarts.

## Manastorm rewards and balance

- Add an opt-in CoA loot mode replacing regular caches with Bazaar Tokens.
- Default to 25 tokens for first clears and 10 for repeats. Track first clears per character, depth, party mode and normal/endgame track.
- Share a 1000-token allowance across a character's personal 24-hour reward window, with persistent accounting and partial capped payouts.
- Display token amounts, allowance and countdown in the native reward panel. Keep bonus-cache accounting separate.
- Reduce selected scarce material probabilities by 75% and selected late-game material probabilities by 50%, using DB-tunable retention percentages.
- Halve the supplied difficulty-1 health curve across depths 1–2000 through a replay-guarded SQL migration.

## Manastorm advancement and safety

- Reset player and active-pet cooldowns once per advancement destination.
- Preserve eligible pets and guardians for first arrivals, followers and automatic transfers.
- Revive dead advancing members, clear debuffs, restore eligible lost buffs, refresh eligible buff durations and fill health/mana on arrival.
- Protect players from objective completion until their individual next-stage arrival, including environmental damage.
- Apply and extend each preparing player's Safety Bubble aura to the remaining preparation window, retaining the eight-yard activation distance.
- Keep the entrance visual for its existing two-minute lifetime and protect advancement portals against player, NPC and affix damage.
- Exclude loading, teleporting, taxi-flight, dead and previous-instance members from entrance-distance activation.
- Preserve the remaining party's run when one member leaves, including ownership handoff and private-map roster updates.
- Require valid minions for Necromancer commands.
- Sort starting depths highest-first and preserve valid manual selections during refresh.

## Ascension spell and aura mechanics

- Restore effect 167 validated movie playback, effect 182 nearest qualifying player facing and effect 198 family DoT duration refresh/extension.
- Restore aura 326 complete avoidance suppression, aura 348 defensive avoidance during casting/channeling against NPCs and aura 365 resource/school percentage power-cost modifiers.

## Achievement data

- Restore normal/heroic Culling of Stratholme Mal'Ganis criteria from sibling difficulty filters.
- Populate missing item-set display names from the verified 10934-item fallback allowlist.
- Add ordinary kill-criteria data for 343 qualifying current-season Hunting Rares criteria using absence, rare-rank and static-spawn guards.

## Verification status

Focused daily-login SQL-model/wiring tests and incremental source checks passed. The draft retains three unresolved earlier combined-candidate source-suite failures. Compilation, C++ harness execution, native worldserver regressions, effective MySQL migration results and client presentation require verification. Reconstructed Mode 1 external-addon token display remains pending. Streak reward policies remain future work.
