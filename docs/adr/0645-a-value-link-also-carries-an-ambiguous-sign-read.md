# 0645. A value link also carries an ambiguous-sign read

- Status: accepted
- Date: 2026-11-14

## Context

ADR 0610 lets a class file's `value_links` close an unmodelled or not_measured value label through the behaviour label
that measures it. Necromancer claim 288.0, Unholy Erosion 807700: "Increases your spell penetration by ${-($m1+0)},
scaling with your level." Its `807700 effect_value e0 #0` reads the aura amount -51 against the token's 51 and is
judged ambiguous_tooltip ("the measured value has the opposite sign"), while `807700 behaviour_hit_ratio penetration`
measures the effect of 51 points of penetration on the dummy's resistance and passes in both runs of the cycle 11 pair.
The mentor ruled on 2026-11-14 that the effect_value label is linked to the hit_ratio label. An ambiguous_tooltip
verdict was outside the statuses a link rewrites, so the link had no effect.

## Options

1. Add ambiguous_tooltip to the statuses a listed value label follows its link from.
2. Drop the effect_value label from the claim (the 6.1 reading): loses the data read of the amount from the claim.
3. A sign-specific reading for aura 123: a new judge for one label.

## Decision

Option 1. `VALUE_LINK_STATUSES` (compare.py) holds ambiguous_tooltip. A link stays opt-in per label: only a label
listed in `value_links` follows its measuring label; every other ambiguous_tooltip verdict keeps its status and its
question. The link's `arithmetic` must state how the measuring label's expectation settles the ambiguity.

## Consequences

- An ambiguous-sign value label closes only through a conformant measuring label in the same comparison, and alerts
  with it.
- Generated scenarios do not change; Templar has no `value_links`.
- Seeded tests: test_compare.py `ApplyValueLinksTest` (`test_an_ambiguous_sign_value_label_follows_its_link`,
  `test_an_unlinked_ambiguous_value_label_keeps_its_status`).
