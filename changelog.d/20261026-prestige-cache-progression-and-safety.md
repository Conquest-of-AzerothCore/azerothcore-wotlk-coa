---
area: modules
type: fixed
audience: admins
title: Prevent Prestige rewards from bypassing progressive content locks
---
Prestige can no longer bypass the realm's Classic progressive release. With only Mythic Dungeons
released, generic caches cannot select locked raid/Naxx gear, owned locked raid caches cannot open,
and locked Classic tier tokens cannot drop. Blocked caches remain unconsumed. At that stage the
existing Heroic Prestige pool qualifies; no separate Mythic pool is invented.

Classic Prestigious Caches and their content tokens now respect the shared Callboard release stage.
Unreleased owned caches remain unopened; missing known pools do not fall through to legacy loot.
Existing configured pool limits remain additional restrictions. TBC generic caches no longer fall
back to Classic gear, and unrecovered WotLK caches remain unconsumed. Pool data and valid drop chances
are preserved. Pool ownership survives config reload; invalid probabilities and tier counts are bounded.

Prestige history now preserves account eligibility for affected heirlooms and experience items after
the only level60 resets. Existing Prestige progress is reused without a new account table or backfill.
Fresh accounts still require a qualifying character. Guardian heirloom access uses the same rule;
a new guarded migration restores its missing vendor flag without changing vendor inventory.

Prestige sends all equipped gear through the existing mail transaction while preserving bags and
contents. Main activation rewards, currencies, seasonal reset rules and achievement timing are retained.

Overflow cache rewards are all prepared before any mail is posted, preventing a later item-creation
failure from leaving a partial mailed payout and a redeemable cache. Full database/crash transaction
recovery is not changed. The live Prestige multiplier remains unchanged pending version-specific evidence.

Automatic daily grants preserve an older held Prestige daily across rotation and reject a second
daily after any sibling was completed in the same daily reset. Dungeon objectives credit only newly
updated final encounters. The three daily quest IDs, rotation, XP percentages and rewards are retained.

Additional world migration: rev_20261025_101_guardian_vendor_flag.sql. Local repack level-cap settings,
private tools and personal changes are not part of this release change.
