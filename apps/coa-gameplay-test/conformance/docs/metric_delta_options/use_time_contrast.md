# Use-time contrast (`metric_delta` `use_time_contrast`, ADR 1194)

`use_time_contrast: ["<suffix>", ...]` is for a `spell_cast_time_ms` or `spell_power_cost` entry with the learned
contrast (no `setup_only_after`). It lists the `label_suffix` of every arm, on the same spell, that together prove the
clause: the entry's own suffix, and for a conditional clause the zero-gain arm (for "your next X", the read after the
modifier is consumed). The entry needs an `expected_gain` (judged on the measured `after - before`) and no
`after_at_least`, `after_at_most` or `expected_ratio`; a non-zero arm's tolerance stays below half its gain. The
verdict detail carries the arm labels and the declared gain (`expected_gain`).

Coverage (`coverage.use_time_partners_hold`) then counts a conformant learned verdict of the entry as behaviour only
when every named arm is among the ledger row's verdicts as a conformant, learned, opted-in verdict of the same metric,
judged on a gain equal to its declared one, measured inside its band, with a half-band below half the smallest
non-zero gain;
one of them has a non-zero gain; one has a zero gain unless the sentence is a plain "Reduces the cast time of <Name>
by $s1%."; and the clause or row carries a promise word (cast time: `cast time|instant|casting time`; cost:
`cost|mana|free`). Absent, the entry keeps its READBACK data evidence.

Sun Cleric: Sunbeams 807874 `cast_time` (Radiant Cascade 2500 ms before the learn, 2125 ms after).
