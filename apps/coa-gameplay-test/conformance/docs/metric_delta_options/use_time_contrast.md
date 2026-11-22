# Use-time contrast (`metric_delta` `use_time_contrast`, ADR 1024)

`use_time_contrast: ["<suffix>", ...]` is for a `spell_cast_time_ms` or `spell_power_cost` entry with the learned
contrast (no `setup_only_after`). It lists the `label_suffix` of every arm, on the same spell, that together prove the
clause: the entry's own suffix, and for a conditional clause the zero-gain arm (for "your next X", the read after the
modifier is consumed). The judge is unchanged; the verdict detail carries the arm labels and the declared gain
(`expected_gain`, or `expected - before_expected`).

Coverage (`coverage.use_time_partners_hold`) then counts a conformant learned verdict of the entry as behaviour only
when every named arm is among the ledger row's verdicts as a conformant, learned, opted-in verdict of the same metric;
one of them has a non-zero gain; one has a zero gain unless the sentence is a plain "Reduces the cast time of <Name>
by $s1%."; and the clause or row carries a promise word (cast time: `cast time|instant|casting time`; cost:
`cost|mana|free`). Absent, the entry keeps its READBACK data evidence.

Sun Cleric: Sunbeams 807874 `cast_time` (Radiant Cascade 2500 ms before the learn, 2125 ms after).
