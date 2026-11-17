# Before auras (`metric_delta` `before_auras`, ADR 0690)

`before_auras` is a non-empty list of `[spell, stacks, on, by]`, the form of `phase_auras`. Each aura is set in the
control phase only, before the before reading and so before the gate learn, and is not set again in the treatment
phase: the treatment reads the aura as it was applied without the gate. An aura of this list may not also be a phase
or after aura, and the option needs the default gate timing, no `setup_only_after` and no attack swings.

Named point: `phase_steps`, as `phase_aura_amounts`, returning the steps for the control phase only.

Witch Hunter: Night King 707067 `brand_before_learn` and `brand_before_learn_held` (Shadow Brand 680517 set on the
dummy before 707067 is learned: its Effect[0] amount is read after the learn).
