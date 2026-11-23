# 0020. Graven Effigy reaches enemies within 20 yd

- Status: accepted
- Date: 2026-11-21

## Context

Graven Effigy 506635: "Enemies within $504761s1 yds have the duration of crowd control effects on them increased by
$504767s1%." `$504761s1` renders as 20. The effigy scanned a literal 10 yd, which matches neither the tooltip nor any
data radius (field 504767 has 15 and 30 yd). The token reads the Shadow Effigy slow value as a radius and may be a
copy slip for `$504767a1` (15 yd); the client shows 20, and the tooltip decides.

## Decision

- The scan reads `abs(Amount(ShadowField))`, the value the tooltip shows, instead of 10.

## Consequences

- Regression: catalog `witch-doctor-graven-effigy-20-yd-field` (inside dummy at about 20.1 yd gets 504767; the one at
  about 26 yd does not; a 15 yd or 30 yd scan fails it).
- If the owner reads the token as 15 yd, the scan becomes `Radius(GravenField)` with a streamed tooltip fix.
