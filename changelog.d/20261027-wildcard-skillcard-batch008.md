# Wildcard card repairs: batch008

## 48545 — Revitalize

Before: No proc route implemented its mixed healing-event chances, active-resource restoration or full-health Healing Touch refund.

Written change: Rejuvenation/Wild Growth/Efflorescence healing rolls15%; Healing Touch/Regrowth healing uses100%. Restore the target's active Energy/Rage/Mana from the native helper amounts (8Energy/40internalRage/1%maximumMana), without firing the mana helper's unrelated resource slots. A Healing Touch that effectively heals a target to full refunds30%of its actual positive mana cost.

## 277450 — Unseen Assassin

Before: Stealth exit/Shadow Dance did not grant the native window; two obsolete GCD modifiers and unsupported modifier operation38 could not deliver the tooltip. Core clamped authored half-second GCDs to one second.

Written change: Grant native277451 for its native3-second duration when leaving the last real stealth aura or gaining Shadow Dance. Reuse a new post-clamp global GCD callback to give only Glaive Toss/Deadly Throw/Shuriken Toss a500msGCD. Apply the native60%monster damage bonus; Deadly Throw/Shuriken Toss instead deal30%less damage to players. Old modifier slots become metadata consumed by this implementation; other spells keep the existing GCD clamp.

## 280210 — Judgement of The Three Hammers

Before: No activation proc or authored coefficient row reached the existing timed hammer helpers.

Written change: Restore the native20%proc on direct spell/ability damage, excluding auto attacks, periodic damage and the hammer child. Reuse the existing initial tick and999msperiodic driver over2000ms, producing its native three hits. The damage child receives the tooltip-authored0.325SP/0.278AP coefficient row; no new scheduler or damage formula is invented.

## 284041 — Waking Nightmare

Before: Haunt did not apply the healing marker or retaliate against the healer. The retaliation helper had ally targeting, a nonfunctional Fear-duration dummy and a generic Shadow vulnerability.

Written change: Landed Haunt damage applies the native marker. Healing that target makes the original curse caster afflict the healer with Phantom Nightmare. Correct the scoped helper to enemy targeting and native caster-only Shadow damage vulnerability; a duration hook reads its150%Fear metadata as50%additional Fear duration. Other casters' Shadow damage does not receive the bonus.

## 283317 — Lightning Discharge

Before: No casting-window lifecycle applied Supercharged or delivered its stun; the stun helper removed the separate Mystic version's aura954036.

Written change: Activate native283318 only during non-instant Lightning Bolt/Chain Lightning casts with Lightning Shield active and no native20-secondICD. Native Shield modifiers double its damage. Incoming direct damage dispatches the native area stun/ICD; correct its cleanup to remove283318. Finish/cancel, Shield/talent removal and the existing100msperiodic callback clean up the window.

## Delivery and verification

Includes pending world migration `rev_20261027_07_wildcard_skillcard_batch008.sql` with five proc rows/five bindings/one coefficient row and the shared GCD hook/source. Previous source repairs and migrations01–06 remain part of the same future new PR.

Changed-file C++/SQL formatting passed. No compilation, gameplay tests, SQL application, deployment or Git operations. All five roots remain FIXED_UNVERIFIED. Runtime acceptance must cover resource/overheal/refund timing, stealth/Shadow Dance and500msGCD behavior, overlap of native hammer bursts, healer attribution/Fear duration interactions, and Lightning Shield cast/ICD cleanup.
