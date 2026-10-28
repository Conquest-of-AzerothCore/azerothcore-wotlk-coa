# Wildcard card repairs: batch007

## 277485 — Clean Pass

Before: Glaive Toss had no route to consume its caster-owned Piercing Shots bleed.

Written change: Landed Glaive Toss damage consumes only the caster's remaining Piercing Shots ticks and casts native277486 with the stored remaining amount increased by the card's native125%. Zero helper coefficients and resolved-amount handling prevent a second scaling/mitigation pass. Another caster's bleed is preserved.

## 280055 — Malignant Jinx

Before: The curse had no event route from its victim's next spell cast to the native silence.

Written change: A shared cast-reaction handler silences the cursed unit with native280056 on its next non-triggered spell cast; one native proc charge consumes the curse. It does not silence that unit's spell target.

## 281110 — Destabilize Time

Before: The curse did not apply or grow its native stacking casting-speed slow.

Written change: Apply native281111 on the victim; each non-triggered spell cast increases that caster-owned slow up to its native cap. Restore the curse's remaining duration after stacking so it does not extend the debuff; removal cleans up only that caster's child aura.

## 281687 — Fleeting Shadow

Before: The opening-attack trigger had no functional Ambush permission route.

Written change: Snapshot actual stealth during the opening Garrote/Cheap Shot/Ambush cast check, then grant native281690 after a successful cast. Its installed aura275 grants only Ambush permission for2500ms. An Ambush used outside stealth does not refresh the window. The unrelated500ms281688 marker is not treated as the permission buff.

## 272989 — Renewed Through Absolution

Before: The card was unbound; its native heal helper was not reached, and its BaseLevel30 offset conflicted with the tooltip's12-per-player-level formula.

Written change: Reuse the registered Renew-consumption script with the card-specific272993 helper. Consume only the caster's Renew on a Penance healing target; retain the helper's Penance family flags, add authored0.2SP/0.04AP coefficients and correct the guarded level offset. The Mystic version keeps its original helper/Weakened Soul behavior; the card does not inherit that unrelated reduction.

## Delivery and verification

Requires the updated source and pending world migration `rev_20261027_06_wildcard_skillcard_batch007.sql`. Four roots receive proc/script bindings; Fleeting Shadow uses existing registered global cast hooks and its native permission aura. The migration also records two explicit coefficient rows. All earlier repairs/migrations remain intended for the same future new PR.

Changed-file C++/SQL codestyle passed. No compilation, gameplay tests, SQL application or deployment. All five implementations remain FIXED_UNVERIFIED. Native cast timing, cross-caster cleanup, rolling-bleed consumption, opener permissions and Penance modifier behavior require later runtime testing.
