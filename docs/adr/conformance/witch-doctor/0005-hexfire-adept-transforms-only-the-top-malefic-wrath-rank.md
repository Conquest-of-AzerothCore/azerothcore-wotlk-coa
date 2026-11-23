# 0005. Hexfire Adept transforms only the top Malefic Wrath rank

- Status: accepted
- Date: 2026-11-16

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Report #12539: after Hexfire Wrath ends, Malefic Wrath on the action bar is replaced by a lower rank. Malefic Wrath
ranks are mana spells, so every learned rank stays active. The Wrath and Arrow branches of `SyncReplacements` stood
Hexfire Wrath 807480 (and Arrow) in for every known rank, and when Hexfire Ready 503626 ended the client got one
SMSG_SUPERCEDED_SPELL per rank in hash order, so a lower rank could land on the button. The Volley and Hex branches
already required the top rank. The mentor classed it a confirmed defect (M-36).

## Decision

- Both branches require `id == KnownRank(player, id)` before they pick a replacement. Hexfire Adept 704500 transforms
  the top rank 808876 only; the lower rank 807037 is never replaced, so it gets no supersede when the transform ends.

## Consequences

- Regression: catalog `witch-doctor-hexfire-adept-top-rank-12539`. It passed in verify_all 20261117-075337.
