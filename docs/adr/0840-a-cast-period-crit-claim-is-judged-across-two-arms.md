# 0840. A cast-period crit claim is judged across two arms

- Status: proposed (provisional number, guide 14.4)
- Date: 2026-11-16

## Context

Scent of Magic 706260: "Critical strikes now apply Scent of Magic for $800528d, causing your Shadow Hound's next Shadow
Leap to incur a $/1000;800528s1 sec reduced cooldown." The 282.0 entry (`leap_gaps`, ADR 0743) set 800528 on the
Shadowhound with a harness set_aura, and the 281.0 entry cast 800528 on the player: neither involved a critical strike
(c15 review I-1, I-2). The crit can be forced (`force_crit`, ADR 0764), but a no-crit control cannot share the forced
rating: at level 60, 100000 melee crit rating outweighs Reduce Critical Strike Chance -100% 64481, so the control arm
needs its own scenario. A difference between the two arms' gaps cannot be judged inside one scenario.

## Options

- Keep the fixture and name it in the verdict: the aura under test stays harness-made (G-21 point 6).
- Judge each arm against absolute gaps: the 20 s base comes from code reading only (`AscensionWitchHunterSummons.cpp`).
- A treatment and a control entry of the same `cast_period` label, judged together by the kind's pooled judge
  (mentor D-272, D-273, D-277).

## Decision

`cast_period` takes optional `caster_auras: [[spell, stacks], ...]` (set on the caster right before the trigger,
labelled `precondition fixture <spell>` and read back with `aura`), and `arm: "treatment" | "control"`. An arm entry
reads the trigger's critical and non-critical hits on the dummy (`spell_damage_count`) at the end of the window, and
emits pooled labels (`parts: 2`, `POOLED_JUDGE`) whose model lists both arms' reads:

- `gap_reduction_ms`: the control's first gap minus the treatment's first gap must lie inside the stated reduction +-
  the G-19 band, and the treatment's second gap minus the control's first inside 0 +- the G-19 band of that gap, both
  as bracket intervals that also exclude the values 10% off (D-200).
- `owned_aura: [spell, entry, ms]` with `aura_quote`: that many ms after the trigger, before the pet attack command
  (the Shadowhound has no victim and cannot leap, so the leap cannot remove the aura first), the owned creatures
  holding the aura are counted: 1 or more in the treatment, 0 in the control.

A crit in the control arm, the aura in the control, a 9000 or 11000 ms reduction or a second gap that is shortened
alert; a treatment trigger that did not crit, a control without a non-critical hit, a missing arm or a missing read
leave the label unmeasured, never ok. Without `arm` the kind is unchanged; finished-class digests do not move.

## Consequences

- 281.0 and 282.0 are measured on an 800528 the server applied through the 706260 proc (spell_proc HitMask 2,
  `AscensionWitchHunterEvents.cpp:384-385`), against a control that differs only by the crit.
- The two arm entries must share `label_suffix`, window and poll; otherwise their labels differ and the pooled label
  reads unmeasured.
- No harness or engine change: `spell_damage_count` with `critical`, `owned_creature_count` with `spell` and `aura`
  already have evidence rows.
