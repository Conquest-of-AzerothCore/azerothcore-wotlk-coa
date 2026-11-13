# 0186. Fixed count reads a pull

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0124 (exact target counts) and ADR 0153 (caster-centred fixed counts)

## Context

Templar Rituals 520534: "...and upon dealing damage, you pull enemies within 15 yds towards you." The script casts
a pull (520695, `SPELL_EFFECT_PULL_TOWARDS`) and a 15 s marker (520694) on every valid enemy within 15 yd when a
Righteous Tempest hit lands (`AscensionTemplarAbilities.cpp:352-362`). A `fixed_count` entry reading the marker per
dummy shows which enemies were chosen, but not that they moved.

## Options

1. Read the marker only. It proves the selection, not the pull.
2. A new kind with its own dummies and distance reads. It repeats the fixed-count placement.
3. An optional `pull_reads` on `fixed_count`: read every dummy's distance to the caster before and after the casts.

## Decision

Option 3. Each dummy inside the radius must end at least 1 yd closer; the one beyond the radius must move less than
0.5 yd; otherwise the verdict is an `alert`. Without the field nothing is read, and existing scenarios regenerate
byte-identical.

## Consequences

- Templar Rituals reads 3.75, 7.5 and 11.25 yd to 0, 0 and 1.23 yd, and 20 yd to 20 yd.
- The stationary fixture flag does not stop the pull.
