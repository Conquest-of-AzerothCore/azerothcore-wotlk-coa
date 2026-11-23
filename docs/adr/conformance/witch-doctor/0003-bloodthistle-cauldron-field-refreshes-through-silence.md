# 0003. The Bloodthistle Cauldron field refreshes through silence

- Status: accepted
- Date: 2026-11-16

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Report #10643: the Bloodthistle buff falls off. Cauldron (Ingredient 801664) triggers the field 802771 every 1500 ms,
a raid area aura of +8% healing taken with a 2000 ms duration; the tooltip states no exception: "Allies within
$802771a1 yds receive 8% increased healing" while brewed. 802771 is the only ingredient field with PreventionType 1
(silence): the Fish Oil and Frog Bones fields (803269, 803697) and the Jungle Shrooms pulse (802703) have 0. The
triggered refresh runs `CheckCasterAuras(preventionOnly)` (`Spell.cpp:6240-6243`) and is refused while the caster is
silenced (`Spell.cpp:7157-7160`), so the buff lapsed within 2 s of a Spell Lock while Fish Oil stayed. The class entry
`801664 cauldron_silenced` reproduced it (cycle 5, alert) and the mentor classed it a confirmed defect (M-36).

## Decision

- `ApplyContracts` sets PreventionType none on 802771 only, the pattern stock uses for Unstable Affliction
  (`SpellInfoCorrections.cpp:1118-1122`). Brewing Bloodthistle itself is still blocked by silence.
- Cursed Effigy, Big Bad Voodoo and Voodoo Ward have the same pattern; that stays an observation.

## Consequences

- Regression: the class entry `conformance-witch-doctor-behaviour-801664-metric-delta-cauldron-silenced` (the buff
  holds through a Spell Lock). It moved from alert to ok in both final05 runs (20261120-202734 and 20261120-204917).
