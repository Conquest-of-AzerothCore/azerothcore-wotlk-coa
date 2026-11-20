# Cast periods (`behaviour_metric_delta`, `kind: "cast_period"`, ADR 0535)

A real `setup_spell` cast raises creature `entry`; uncommanded for `control_ms` it must cast no `cast_spell`. Then
`trigger_spell` at the dummy and, every `poll_ms` over `window_ms`, the game time and the creature's casts are read. The
first and the last cast are bracketed between stamped reads, and (last - first) / (n - 1) must lie inside `expected_ms`
+- the G-19 band (Animate: Plaguefather 805048: Bone Toss 704706 every 1000 ms).

Options (ADR 0743), absent by default: `pet_attack: true` commands the caster's pet to attack the dummy right after
the trigger; `casts_per_event` (default 1) counts that many casts as one event (a landing that casts twice);
`gaps_ms: [ms, ...]` judges the gaps between the first `len(gaps_ms) + 1` events, each bracketed between polls and
inside its own G-19 band, instead of the mean period (the counts must step by one event between polls); and
`minion_auras: [[spell, owned entry, ms after the trigger], ...]` sets an aura on the owned creature at that point of
the window (a `gaps_ms` entry only). Its first user, Scent of Magic 706260 `leap_gaps`, moved to the two arms
below.

`force_crit: "melee" | "spell" | "ranged"` sets that school's forced crit rating on the caster, and `learn: [spell,
...]` has the caster learn those spells at the start (ADR 0764); absent, the scenario is unchanged.

Two arms (ADR 0840), absent by default: `caster_auras: [[spell, stacks], ...]` sets those auras on the caster right
before the trigger as named precondition fixtures and reads them back. `arm: "treatment" | "control"` makes the entry
one arm of a pair that shares its `label_suffix`, window and poll: each arm reads the trigger's critical and
non-critical hits on the dummy, and the pair is judged together (pooled, two parts). `gap_reduction_ms` judges the
control's first gap minus the treatment's first gap against that reduction and the treatment's second gap against the
control's first (G-19 bands, 10% off excluded, D-200); `owned_aura: [spell, entry, ms]` with `aura_quote` counts the
owned creatures holding that aura `ms` after the trigger, before the pet attack command (needs `pet_attack`): at
least 1 in the treatment, 0 in the control. A crit in the control alerts; a treatment that did not crit, a missing arm
or read is unmeasured. Witch Hunter: Scent of Magic 706260 `leap_arms` (treatment forced melee crit of Dawn Blade
802024; control Reduce Critical Strike Chance -100% 64481, no forced rating).

`aura_expiry: {"expected_ms": ms, "gone_after_ms": ms}` (ADR 0862, with `owned_aura`) reads the owned aura again
`gone_after_ms` after the first read. The game time is stamped before the trigger, right after it and at both reads; the
aura is present at an age of at least `expected_ms` minus the G-19 band and gone at an age of at most `expected_ms` plus
it (a 10%-off duration is excluded on both sides, D-200); the control holds none at either read. A treatment still
holding it past the band is an alert, reads outside the band are unmeasured. Witch Hunter: Scent of Magic 706260
`scent_duration` (800528, 15000 ms). Absent, the entry is unchanged.
