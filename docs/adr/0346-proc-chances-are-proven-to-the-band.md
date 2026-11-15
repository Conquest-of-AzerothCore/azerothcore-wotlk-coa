# 0346. Proc chances are proven to the band

- Status: accepted
- Date: 2026-11-13

## Context

The proc judge passes a rate when the Wilson 99% interval holds the stated chance. The B1 review (I-1) found the
minion proc intervals wider than the band of G-19 (the larger of 5% of the chance and 2 points): Overwhelming Force
[3.71, 7.98]% against [3, 7]%, which by ADR 0195's precedent is G-20 step 1 ("effect present, interval stated"), not
a proof.

## Decision

- A proc entry with `band: true` sizes its trials so the 99% half-width is half the band
  (`ceil(z^2 p (1 - p) / (band / 2)^2)`, then the usual 1.5 margin), in parts.
- Its judge requires the Wilson 99% interval inside the band around the stated chance: `ok` inside, `alert` when the
  interval excludes the chance, `measured` ("effect present, interval stated, not final") otherwise.

## Consequences

- Overwhelming Force (5%: 4728 trials), Putricide's Formula (10%: 8958; 20%: 15925), Depravity (50%) and Plague Horde
  (10%) run in parts on the accelerated clock. Entries without `band` are unchanged (Templar byte-identical).
