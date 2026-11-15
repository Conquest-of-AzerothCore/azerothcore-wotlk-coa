# CoA daily login rewards, Manastorm improvements and Ascension spell restoration

## Recruit-a-Friend abuse prevention

- Reject same-IP account links at invitation and acceptance, including equivalent IPv4 and IPv4-mapped IPv6 addresses.
- Cancel existing links with matching recorded login IPs through an auth migration. Clear the affected recruit's qualification progress and preserve existing reward receipts.

## Bazaar Token payout performance

- Batch and stagger ordinary kill payouts per character across one to two seconds. Flush pending tokens before quest and boss payouts and on logout.
- Keep reward rates, eligibility and the hourly cap. Store tokens in bags and send only overflow through in-game mail.
- Cache payout settings on config load, skip creature scaling checks for zero-token rolls and prefetch cold account cap state asynchronously at login when the cap is enabled.
- Fix the player-owned batch state declaration and reuse its lookup key.

## Realm performance and inventory reliability

- Read daily-login eligibility asynchronously and publish committed reward mail through a world-owned callback, retaining atomic claim/mail writes and cleanup across logout or failure.
- Compare native token reward fields independently of the clock; send a small periodic clock refresh instead of repeating the full reward UI Lua.
- Preserve the petless Command: Undead exemption used by Crypt Explosion while retaining the other minion and aura safety checks.

- Stagger RAF reward checks and poll unlinked accounts roughly every 15 minutes after login. Retain periodic recovery of rewards queued before unlinking and normal progress checkpoints for recruits.
- Move XP Hotspot timers to player-owned state so ordinary updates skip the shared lock until the next refresh. Retain the pre-reward location check for kills.
- Persist Bloodforging through the normal inventory save path so the converted item and jar use can be saved together. Remove the synchronous spell-handler save that terminated the server on failure.
- Requeue failed Worldforged pickup saves with the inventory transaction while retaining the in-session claim guard. Keep the immediate transaction on the normal path.

## Account-wide daily login rewards

- Award 200 Bazaar Tokens by mail on an eligible login across all realm game modes, with one shared account cooldown of 24 hours in the character database.
- Wait for world entry and teleport/loading readiness before processing the claim.
- Commit the account cooldown and reward mail together, with database guards against stale or duplicate claims.
- Show Daily Login Reward using the existing client toast, actual item icon and awarded quantity through the server Lua bridge.
- Configure additional item rewards in the world database. Retain last claim time and lifetime claim count for future streak rewards.
- Exclude bot sessions. Support CoA, Wildcard, Freepick and WCR characters. Preserve account cooldowns across character changes, character deletion and restarts.

## Manastorm rewards and balance

- In CoA loot mode, replace Greedy Demon gear with 25/50/100 Bazaar Tokens for uncommon/rare/epic loot, preserving its 28/92/93-gold payouts.
- Convert Treasure Keeper gear-cache bonuses to 50 tokens per cache by default. Preserve cache 1478051 when assigned its material-cache script.
- Share the existing 1000-token personal allowance across stage completions and encounter rewards. Continue awarding Greedy gold when the token allowance is exhausted.
- Add DB-configurable encounter token rewards and durable Greedy loot receipts. Use existing inventory delivery with mail overflow for tokens, and include direct gold persistence in the guarded transaction.

- Add an opt-in CoA loot mode replacing regular caches with Bazaar Tokens.
- Default to 25 tokens for first clears and 10 for repeats. Track first clears per character, depth, party mode and normal/endgame track.
- Share a 1000-token allowance across a character's personal 24-hour reward window, with persistent accounting and partial capped payouts.
- Display token amounts, allowance and countdown in the native reward panel. Keep bonus-cache accounting separate.
- Reduce selected scarce material probabilities by 75% and selected late-game material probabilities by 50%, using DB-tunable retention percentages.
- Halve the supplied difficulty-1 health curve across depths 1-2000 through a replay-guarded SQL migration.

## Manastorm advancement and safety

- Add per-member creature views for grouped Manastorm through Destiny Weaver. Members fight their own level while sharing one server health pool with the existing depth and group multipliers.
- Keep Solo on its existing scaling path. Retain grouped-run views through individual departures, and limit the integration to registered Manastorm instances and their members.
- Extend existing personal health, armor, damage, combat-level, pet-owner, threat and cross-player healing paths to grouped stages, including private raid-map segments and objective bosses.
- Normalize direct and periodic percentage-health damage against the personal view, compensating incoming health-percentage attacks for the ordinary level conversion.

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

Grouped personal scaling passed six source/model tests and four incremental source checks. It requires Destiny Weaver scaling enabled and retains existing challenge restrictions. Mixed-level native combat, percentage-damage interactions and client rendering still require verification.

The RAF work passed 34 offline SQL-model and source checks in Integration. The Worldforged persistence harness passed rollback, retry and inventory save wiring checks. Bazaar payout and realm changes passed C++ style and whitespace checks. The auth migration, updated C++ build, native behavior and high-population performance remain unverified.
